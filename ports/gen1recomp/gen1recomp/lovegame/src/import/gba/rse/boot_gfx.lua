local Lz77 = require("src.import.gba.lz77")
local LuaWriter = require("src.import.LuaWriter")
local CacheBlob = require("src.import.CacheBlob")

local bit = rawget(_G, "bit") or require("bit")
local band, bxor, rshift = bit.band, bit.bxor, bit.rshift

local K = {}

K.FORMAT = 1

-- pokeemerald/include/gba/types.h:102
K.OBJ_DIMS = {
  [0] = { { 8, 8 }, { 16, 16 }, { 32, 32 }, { 64, 64 } },
  [1] = { { 16, 8 }, { 32, 8 }, { 32, 16 }, { 64, 32 } },
  [2] = { { 8, 16 }, { 8, 32 }, { 16, 32 }, { 32, 64 } },
}

function K.objDims(shape, size)
  local row = K.OBJ_DIMS[shape]
  local d = row and row[size + 1]
  if not d then error(string.format("boot_gfx: bad OBJ shape/size %s/%s", tostring(shape), tostring(size))) end
  return d[1], d[2]
end

local CRC = {}
for i = 0, 255 do
  local c = i
  for _ = 1, 8 do
    if band(c, 1) == 1 then c = bxor(rshift(c, 1), 0xEDB88320) else c = rshift(c, 1) end
  end
  CRC[i] = c
end

local function crc32(s)
  local c = 0xFFFFFFFF
  for i = 1, #s do
    c = bxor(CRC[band(bxor(c, s:byte(i)), 0xFF)], rshift(c, 8))
  end
  c = bxor(c, 0xFFFFFFFF)
  if c < 0 then c = c + 4294967296 end
  return c
end

local function be32(n)
  n = n % 4294967296
  return string.char(math.floor(n / 16777216) % 256, math.floor(n / 65536) % 256,
    math.floor(n / 256) % 256, n % 256)
end

local function chunk(kind, data)
  return be32(#data) .. kind .. data .. be32(crc32(kind .. data))
end

local function zlib(raw)
  return CacheBlob.deflate(raw, 9)
end

local function scanlines(w, h, idx)
  local rows = {}
  local char = string.char
  for y = 0, h - 1 do
    local base = y * w
    local parts = { "\0" }
    local x = 1
    while x <= w do
      local e = math.min(w, x + 255)
      parts[#parts + 1] = char(unpack(idx, base + x, base + e))
      x = e + 1
    end
    rows[#rows + 1] = table.concat(parts)
  end
  return table.concat(rows)
end

function K.rgb8(c)
  c = (tonumber(c) or 0) % 32768
  local r5 = c % 32
  local g5 = math.floor(c / 32) % 32
  local b5 = math.floor(c / 1024) % 32
  return math.floor(r5 * 255 / 31 + 0.5), math.floor(g5 * 255 / 31 + 0.5), math.floor(b5 * 255 / 31 + 0.5)
end

function K.encodeIndexed(w, h, idx, pal, transparent0)
  local count = 1
  for i = 1, w * h do
    local v = idx[i]
    if v + 1 > count then count = v + 1 end
  end
  local plte = {}
  for i = 0, count - 1 do
    local r, g, b = K.rgb8(pal[i] or 0)
    plte[#plte + 1] = string.char(r, g, b)
  end
  local out = {
    "\137PNG\r\n\26\n",
    chunk("IHDR", be32(w) .. be32(h) .. "\8\3\0\0\0"),
    chunk("PLTE", table.concat(plte)),
  }
  if transparent0 then out[#out + 1] = chunk("tRNS", "\0") end
  out[#out + 1] = chunk("IDAT", zlib(scanlines(w, h, idx)))
  out[#out + 1] = chunk("IEND", "")
  return table.concat(out)
end

function K.encodeGray(w, h, idx)
  return table.concat({
    "\137PNG\r\n\26\n",
    chunk("IHDR", be32(w) .. be32(h) .. "\8\0\0\0\0"),
    chunk("IDAT", zlib(scanlines(w, h, idx))),
    chunk("IEND", ""),
  })
end

function K.encodeMask(w, h, idx, keep)
  local rows = {}
  for y = 0, h - 1 do
    local parts = { "\0" }
    for x = 1, w do
      if keep[idx[y * w + x]] then parts[#parts + 1] = "\255\255\255\255" else parts[#parts + 1] = "\0\0\0\0" end
    end
    rows[#rows + 1] = table.concat(parts)
  end
  return table.concat({
    "\137PNG\r\n\26\n",
    chunk("IHDR", be32(w) .. be32(h) .. "\8\6\0\0\0"),
    chunk("IDAT", zlib(table.concat(rows))),
    chunk("IEND", ""),
  })
end

function K.pngSize(bytes)
  if type(bytes) ~= "string" or bytes:sub(1, 8) ~= "\137PNG\r\n\26\n" then return nil end
  local function u32(o)
    local a, b, c, d = bytes:byte(o, o + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return u32(17), u32(21)
end

local function nib(gfx, tile, x, y)
  local b = gfx:byte(tile * 32 + y * 4 + math.floor(x / 2) + 1)
  if not b then return 0 end
  if x % 2 == 0 then return b % 16 end
  return math.floor(b / 16)
end

local function byte8(gfx, tile, x, y)
  return gfx:byte(tile * 64 + y * 8 + x + 1) or 0
end

function K.blank(w, h, v)
  local t = {}
  for i = 1, w * h do t[i] = v or 0 end
  return t
end

local function mapEntry(map, i)
  local lo, hi = map:byte(i * 2 + 1, i * 2 + 2)
  if not lo then return 0 end
  return lo + (hi or 0) * 256
end

-- pokeemerald/include/gba/io_reg.h:540
function K.bakeText(gfx, map, wTiles, hTiles, opts)
  opts = opts or {}
  local W, H = wTiles * 8, hTiles * 8
  local out = K.blank(W, H)
  local tiles = math.floor(#gfx / 32)
  local mapBase = opts.mapOffset or 0
  local sbW = math.max(1, math.floor(wTiles / 32))
  local linear = opts.linear
  for ty = 0, hTiles - 1 do
    for tx = 0, wTiles - 1 do
      local i
      if linear then
        i = ty * (opts.mapWidth or wTiles) + tx
      else
        local sb = math.floor(ty / 32) * sbW + math.floor(tx / 32)
        i = sb * 1024 + (ty % 32) * 32 + (tx % 32)
      end
      local e = mapEntry(map, mapBase + i)
      local tile = e % 1024
      local hf = math.floor(e / 1024) % 2 == 1
      local vf = math.floor(e / 2048) % 2 == 1
      local bank = math.floor(e / 4096)
      if tile < tiles then
        for py = 0, 7 do
          local sy = vf and (7 - py) or py
          local row = (ty * 8 + py) * W + tx * 8
          for px = 0, 7 do
            local sx = hf and (7 - px) or px
            local v = nib(gfx, tile, sx, sy)
            if v ~= 0 then out[row + px + 1] = bank * 16 + v end
          end
        end
      end
    end
  end
  return out, W, H
end

function K.bakeText8(gfx, map, wTiles, hTiles)
  local W, H = wTiles * 8, hTiles * 8
  local out = K.blank(W, H)
  local tiles = math.floor(#gfx / 64)
  local sbW = math.max(1, math.floor(wTiles / 32))
  for ty = 0, hTiles - 1 do
    for tx = 0, wTiles - 1 do
      local sb = math.floor(ty / 32) * sbW + math.floor(tx / 32)
      local e = mapEntry(map, sb * 1024 + (ty % 32) * 32 + (tx % 32))
      local tile = e % 1024
      local hf = math.floor(e / 1024) % 2 == 1
      local vf = math.floor(e / 2048) % 2 == 1
      if tile < tiles then
        for py = 0, 7 do
          local sy = vf and (7 - py) or py
          local row = (ty * 8 + py) * W + tx * 8
          for px = 0, 7 do
            out[row + px + 1] = byte8(gfx, tile, hf and (7 - px) or px, sy)
          end
        end
      end
    end
  end
  return out, W, H
end

-- pokeemerald/include/gba/io_reg.h:544
function K.bakeAffine(gfx, map, sizeTiles)
  local W = sizeTiles * 8
  local out = K.blank(W, W)
  local tiles = math.floor(#gfx / 64)
  for ty = 0, sizeTiles - 1 do
    for tx = 0, sizeTiles - 1 do
      local tile = map:byte(ty * sizeTiles + tx + 1) or 0
      if tile < tiles then
        for py = 0, 7 do
          local row = (ty * 8 + py) * W + tx * 8
          for px = 0, 7 do
            out[row + px + 1] = byte8(gfx, tile, px, py)
          end
        end
      end
    end
  end
  return out, W, W
end

function K.bakeSprite(gfx, w, h, tileOffset, bpp)
  local out = K.blank(w, h)
  local tw, th = w / 8, h / 8
  local unit = (bpp == 8) and 2 or 1
  for ty = 0, th - 1 do
    for tx = 0, tw - 1 do
      local t = tileOffset + (ty * tw + tx) * unit
      for py = 0, 7 do
        local row = (ty * 8 + py) * w + tx * 8
        for px = 0, 7 do
          local v
          if bpp == 8 then
            v = gfx:byte(t * 32 + py * 8 + px + 1) or 0
          else
            v = nib(gfx, t, px, py)
          end
          out[row + px + 1] = v
        end
      end
    end
  end
  return out
end

function K.stack(frames, w, h)
  local out = {}
  local n = 0
  for _, f in ipairs(frames) do
    for i = 1, w * h do
      n = n + 1
      out[n] = f[i]
    end
  end
  return out, w, h * #frames
end

function K.crop(idx, W, x0, y0, w, h)
  local out = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      out[y * w + x + 1] = idx[(y0 + y) * W + x0 + x + 1] or 0
    end
  end
  return out
end

local function isRom(rom)
  return type(rom) == "table" and type(rom.readString) == "function"
end

local Ctx = {}
Ctx.__index = Ctx

function K.context(rom, cache, opts, sub)
  opts = opts or {}
  local game = opts.game or rom.id or "emerald"
  if game == "leafgreen" or game == "firered" then error("boot_gfx: rse extractor run for " .. game) end
  return K.contextWith(rom, cache, opts, sub, require("src.import.gba.syms").of(game), game)
end

function K.contextWith(rom, cache, opts, sub, S, game)
  assert(isRom(rom), "boot_gfx: rom needs readString")
  opts = opts or {}
  local root = (opts.cacheRoot or "data/generated/gba") .. "/" .. sub
  return setmetatable({
    rom = rom,
    cache = cache,
    opts = opts,
    game = game,
    S = S,
    sub = sub,
    root = root,
    files = {},
    lzCache = {},
  }, Ctx)
end

function Ctx:off(name) return self.S.off(name) end

function Ctx:raw(name, len)
  return self.rom:readString(self.S.off(name), len or self.S.size(name))
end

function Ctx:lzAt(off)
  local hit = self.lzCache[off]
  if hit then return hit end
  local rom = self.rom
  assert(rom:get(off) == 0x10, string.format("boot_gfx: no LZ77 header at 0x%X", off))
  local out = Lz77.decompress(function(i) return rom:get(i) end, off)
  local len = Lz77.len(out)
  local parts = {}
  local i = 1
  while i <= len do
    local e = math.min(len, i + 4095)
    local chunkT = {}
    for j = i, e do chunkT[#chunkT + 1] = out[j] or 0 end
    parts[#parts + 1] = string.char(unpack(chunkT))
    i = e + 1
  end
  local s = table.concat(parts)
  self.lzCache[off] = s
  return s
end

function Ctx:lz(name)
  return self:lzAt(self.S.off(name))
end

function Ctx:u8(off) return self.rom:get(off) end
function Ctx:u16(off) return self.rom:u16(off) end
function Ctx:s16(off)
  local v = self.rom:u16(off)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end
function Ctx:s8(off)
  local v = self.rom:get(off)
  if v >= 0x80 then v = v - 0x100 end
  return v
end
function Ctx:u32(off) return self.rom:u32(off) end

function Ctx:ptr(off)
  local p = self.rom:u32(off)
  if p < 0x08000000 or p >= 0x0A000000 then return nil end
  return p - 0x08000000
end

function Ctx:palFrom(bytes, count, into, base)
  into = into or {}
  base = base or 0
  count = count or math.floor(#bytes / 2)
  for i = 0, count - 1 do
    local lo, hi = bytes:byte(i * 2 + 1, i * 2 + 2)
    into[base + i] = (lo or 0) + (hi or 0) * 256
  end
  return into
end

function Ctx:pal(name, count, into, base, lz)
  return self:palFrom(lz and self:lz(name) or self:raw(name), count, into, base)
end

function Ctx:palAt(off, count, into, base)
  return self:palFrom(self.rom:readString(off, count * 2), count, into, base)
end

function K.palList(pal, first, count)
  local out = {}
  for i = 0, count - 1 do out[i + 1] = pal[first + i] or 0 end
  return out
end

function Ctx:sizedAt(off, obj)
  local names = self.S.namesAt(off)
  for _, n in ipairs(names) do
    for _, key in ipairs({ n, obj and (obj .. ":" .. n) or nil }) do
      local ok, size = pcall(self.S.size, key)
      if ok and size and size > 0 and self.S.off(key) == off then return size, key end
    end
  end
  return nil
end

-- pokeemerald/include/sprite.h:48
function Ctx:readAnim(off)
  local cmds = {}
  for i = 0, 63 do
    local lo = self:u16(off + i * 4)
    local hi = self:u16(off + i * 4 + 2)
    if lo == 0xFFFF then
      cmds[#cmds + 1] = { op = "end" }
      break
    elseif lo == 0xFFFE then
      cmds[#cmds + 1] = { op = "jump", target = hi % 64 }
      break
    elseif lo == 0xFFFD then
      cmds[#cmds + 1] = { op = "loop", count = hi % 64 }
    else
      cmds[#cmds + 1] = {
        op = "frame",
        tile = lo,
        duration = hi % 64,
        hFlip = math.floor(hi / 64) % 2 == 1 or nil,
        vFlip = math.floor(hi / 128) % 2 == 1 or nil,
      }
    end
  end
  return cmds
end

function Ctx:readAnimTable(off, count, obj)
  if not count then
    local size = self:sizedAt(off, obj)
    if not size then error(string.format("boot_gfx: no sized anim table symbol at 0x%X", off)) end
    count = math.floor(size / 4)
  end
  local anims = {}
  for i = 0, count - 1 do
    local p = self:ptr(off + i * 4)
    if p then anims[#anims + 1] = self:readAnim(p) end
  end
  return anims
end

-- pokeemerald/include/gba/types.h:55
function Ctx:readOam(off)
  local a0 = self:u16(off)
  local a1 = self:u16(off + 2)
  local a2 = self:u16(off + 4)
  local shape = math.floor(a0 / 16384) % 4
  local size = math.floor(a1 / 16384) % 4
  local w, h = K.objDims(shape, size)
  return {
    shape = shape,
    size = size,
    w = w,
    h = h,
    bpp = (math.floor(a0 / 8192) % 2 == 1) and 8 or 4,
    affineMode = math.floor(a0 / 256) % 4,
    objMode = math.floor(a0 / 1024) % 4,
    priority = math.floor(a2 / 1024) % 4,
    paletteNum = math.floor(a2 / 4096) % 16,
  }
end

-- pokeemerald/include/sprite.h:179
function Ctx:readTemplate(name)
  local off = self.S.off(name)
  local oamOff = self:ptr(off + 4)
  local animsOff = self:ptr(off + 8)
  local imagesOff = self:ptr(off + 12)
  local oam = oamOff and self:readOam(oamOff) or nil
  local obj = name:match("^(.-%.o):") or self.S.obj(name)
  return {
    tileTag = self:u16(off),
    paletteTag = self:u16(off + 2),
    oam = oam,
    anims = animsOff and self:readAnimTable(animsOff, nil, obj) or {},
    images = imagesOff,
    callback = self.S.funcAt(self:u32(off + 20)),
  }
end

function Ctx:path(name)
  return self.root .. "/" .. name
end

function Ctx:write(name, bytes)
  local rel = self:path(name)
  local ok, err = self.cache:write(rel, bytes)
  if ok == false then error("boot_gfx: could not write " .. rel .. ": " .. tostring(err)) end
  self.files[#self.files + 1] = name
  return rel
end

function Ctx:png(name, w, h, idx, pal, transparent0)
  return self:write(name, K.encodeIndexed(w, h, idx, pal, transparent0))
end

function Ctx:gray(name, w, h, idx)
  return self:write(name, K.encodeGray(w, h, idx))
end

function Ctx:mask(name, w, h, idx, keep)
  return self:write(name, K.encodeMask(w, h, idx, keep))
end

function Ctx:layer(spec, idx, W, H, pal)
  local entry = { w = W, h = H, opaque = spec.opaque or nil, variants = {} }
  local out = idx
  if spec.opaque then
    out = {}
    for i = 1, W * H do out[i] = idx[i] end
  end
  local variants = spec.variants or { { name = "", pal = pal } }
  for _, v in ipairs(variants) do
    local file = spec.key .. (v.name ~= "" and ("_" .. v.name) or "") .. ".png"
    local path = self:png(file, W, H, out, v.pal, not spec.opaque)
    if v.name == "" then entry.png = path else entry.variants[v.name] = path end
  end
  if next(entry.variants) == nil then entry.variants = nil end
  if spec.indexMap then entry.index = self:gray(spec.key .. "_idx.png", W, H, idx) end
  return entry
end

function Ctx:spriteFrames(key, gfx, tpl, pal, extra)
  local oam = tpl.oam
  local w, h, bpp = oam.w, oam.h, oam.bpp
  local offsets, seen = {}, {}
  local function add(t)
    if not seen[t] then seen[t] = true; offsets[#offsets + 1] = t end
  end
  for _, anim in ipairs(tpl.anims) do
    for _, c in ipairs(anim) do
      if c.op == "frame" then add(c.tile) end
    end
  end
  for _, t in ipairs(extra or {}) do add(t) end
  if #offsets == 0 then add(0) end
  table.sort(offsets)
  local frames, frameOf = {}, {}
  for i, t in ipairs(offsets) do
    frames[i] = K.bakeSprite(gfx, w, h, t, bpp)
    frameOf[t] = i - 1
  end
  local sheet, SW, SH = K.stack(frames, w, h)
  local anims = {}
  for ai, anim in ipairs(tpl.anims) do
    local list = {}
    for ci, c in ipairs(anim) do
      local row = {}
      for k, v in pairs(c) do row[k] = v end
      if c.op == "frame" then row.frame = frameOf[c.tile] end
      list[ci] = row
    end
    anims[ai] = list
  end
  local entry = {
    w = w, h = h, bpp = bpp, frames = #offsets, tiles = offsets, anims = anims,
    priority = oam.priority, affineMode = oam.affineMode, objMode = oam.objMode,
    callback = tpl.callback,
  }
  local pals = pal.variants or { { name = "", pal = pal } }
  for _, v in ipairs(pals) do
    local file = key .. (v.name ~= "" and ("_" .. v.name) or "") .. ".png"
    local path = self:png(file, SW, SH, sheet, v.pal, true)
    if v.name == "" then entry.png = path else entry.variants = entry.variants or {}; entry.variants[v.name] = path end
  end
  return entry
end

function Ctx:strip(key, gfx, w, h, count, pal, bpp, tileBase)
  local per = (w / 8) * (h / 8) * ((bpp == 8) and 2 or 1)
  local frames = {}
  for i = 0, count - 1 do
    frames[i + 1] = K.bakeSprite(gfx, w, h, (tileBase or 0) + i * per, bpp)
  end
  local sheet, SW, SH = K.stack(frames, w, h)
  local entry = { w = w, h = h, bpp = bpp or 4, frames = count, tilesPerFrame = per }
  local pals = pal.variants or { { name = "", pal = pal } }
  for _, v in ipairs(pals) do
    local file = key .. (v.name ~= "" and ("_" .. v.name) or "") .. ".png"
    local path = self:png(file, SW, SH, sheet, v.pal, true)
    if v.name == "" then entry.png = path else entry.variants = entry.variants or {}; entry.variants[v.name] = path end
  end
  return entry
end

function Ctx:atlas(key, gfx, list, pal)
  local W, H = 0, 0
  for _, fr in ipairs(list) do
    if fr.w > W then W = fr.w end
    H = H + fr.h
  end
  local out = K.blank(W, H)
  local rects, y = {}, 0
  for i, fr in ipairs(list) do
    local px = K.bakeSprite(gfx, fr.w, fr.h, fr.tile, fr.bpp or 4)
    for yy = 0, fr.h - 1 do
      for xx = 0, fr.w - 1 do
        out[(y + yy) * W + xx + 1] = px[yy * fr.w + xx + 1]
      end
    end
    rects[i] = { x = 0, y = y, w = fr.w, h = fr.h, tile = fr.tile }
    y = y + fr.h
  end
  local entry = { w = W, h = H, rects = rects }
  local pals = pal.variants or { { name = "", pal = pal } }
  for _, v in ipairs(pals) do
    local file = key .. (v.name ~= "" and ("_" .. v.name) or "") .. ".png"
    local path = self:png(file, W, H, out, v.pal, true)
    if v.name == "" then entry.png = path else entry.variants = entry.variants or {}; entry.variants[v.name] = path end
  end
  return entry
end

function Ctx:finish(manifest)
  manifest.format = K.FORMAT
  manifest.game = self.game
  manifest.files = {}
  for i, f in ipairs(self.files) do manifest.files[i] = self:path(f) end
  self:write("manifest.lua", LuaWriter.encode(manifest))
  return manifest
end

function K.variants(list)
  return { variants = list }
end

function K.ready(sub, cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. sub .. "/manifest.lua"
  if not (cache and cache.read) then return false end
  local body = cache:read(rel)
  if type(body) ~= "string" then return false end
  local fmt = body:match("\n%s*format = (%d+),")
  return tonumber(fmt) == K.FORMAT
end

function K.required(sub, files)
  local out = { sub .. "/manifest.lua" }
  for _, f in ipairs(files) do out[#out + 1] = sub .. "/" .. f end
  return out
end

K.Ctx = Ctx

return K
