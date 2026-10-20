local SpriteGfx = {}

local ROM_BASE, ROM_END = 0x08000000, 0x0A000000

-- pokeemerald/include/gba/types.h:102
local OAM_DIMS = {
  [0] = { { 8, 8 }, { 16, 16 }, { 32, 32 }, { 64, 64 } },
  [1] = { { 16, 8 }, { 32, 8 }, { 32, 16 }, { 64, 32 } },
  [2] = { { 8, 16 }, { 8, 32 }, { 16, 32 }, { 32, 64 } },
}

function SpriteGfx.ptr(rom, off)
  local p = rom:u32(off)
  if p >= ROM_BASE and p < ROM_END then return p - ROM_BASE end
  return nil
end

function SpriteGfx.snake(name)
  local s = name:gsub("(%l)(%u)", "%1_%2"):gsub("(%u)(%u%l)", "%1_%2"):gsub("(%a)(%d)", "%1_%2")
  return s:lower()
end

function SpriteGfx.symName(S, off, prefix)
  local best
  for _, n in ipairs(S.namesAt(off)) do
    if not prefix or n:sub(1, #prefix) == prefix then
      if not best or #n < #best then best = n end
    end
  end
  return best
end

function SpriteGfx.symSize(S, off)
  for _, n in ipairs(S.namesAt(off)) do
    local ok, size = pcall(S.size, n)
    if ok and type(size) == "number" and size > 0 then return size end
  end
  return nil
end

function SpriteGfx.readPalette(rom, off)
  local pal = {}
  for i = 0, 15 do pal[i] = rom:u16(off + i * 2) end
  return pal
end

function SpriteGfx.rgb8(c)
  local r5 = c % 32
  local g5 = math.floor(c / 32) % 32
  local b5 = math.floor(c / 1024) % 32
  return math.floor(r5 * 255 / 31 + 0.5), math.floor(g5 * 255 / 31 + 0.5), math.floor(b5 * 255 / 31 + 0.5)
end

function SpriteGfx.palBytes(pal)
  local out = {}
  for i = 0, 15 do
    local c = pal[i] or 0
    out[#out + 1] = string.char(c % 256, math.floor(c / 256) % 256)
  end
  return table.concat(out)
end

function SpriteGfx.decodeTiles(rom, off, fw, fh, out, oy, stride)
  local tw = fw / 8
  stride = stride or fw
  oy = oy or 0
  for t = 0, tw * (fh / 8) - 1 do
    local base = off + t * 32
    local tx, ty = (t % tw) * 8, math.floor(t / tw) * 8
    for y = 0, 7 do
      local row = (oy + ty + y) * stride + tx
      for x = 0, 3 do
        local b = rom:get(base + y * 4 + x)
        out[row + x * 2 + 1] = b % 16
        out[row + x * 2 + 2] = math.floor(b / 16)
      end
    end
  end
  return out
end

function SpriteGfx.idxString(pix, n)
  local parts = {}
  local chunk = {}
  for i = 1, n do
    chunk[#chunk + 1] = pix[i] or 0
    if #chunk == 4096 then
      parts[#parts + 1] = string.char(unpack(chunk))
      chunk = {}
    end
  end
  if #chunk > 0 then parts[#parts + 1] = string.char(unpack(chunk)) end
  return table.concat(parts)
end

function SpriteGfx.rgbaString(pix, n, pal)
  local lut = {}
  for i = 0, 15 do
    if i == 0 then
      lut[i] = "\0\0\0\0"
    else
      local r, g, b = SpriteGfx.rgb8(pal[i] or 0)
      lut[i] = string.char(r, g, b, 255)
    end
  end
  local out = {}
  for i = 1, n do out[i] = lut[pix[i] or 0] end
  return table.concat(out)
end

-- pokeemerald/include/gba/types.h:55
function SpriteGfx.readOam(rom, off)
  local b1, b3, b5 = rom:get(off + 1), rom:get(off + 3), rom:get(off + 5)
  local shape, size = math.floor(b1 / 64), math.floor(b3 / 64)
  local dims = OAM_DIMS[shape] and OAM_DIMS[shape][size + 1] or { 8, 8 }
  return {
    w = dims[1],
    h = dims[2],
    shape = shape,
    size = size,
    affineMode = b1 % 4,
    paletteNum = math.floor(b5 / 16),
    priority = math.floor(b5 / 4) % 4,
  }
end

-- pokeemerald/include/sprite.h:48
function SpriteGfx.readAnim(rom, off)
  local cmds = {}
  for i = 0, 63 do
    local v = rom:u32(off + i * 4)
    local kind = v % 65536
    local arg = math.floor(v / 65536) % 64
    if kind == 0xFFFF then
      cmds[#cmds + 1] = { "end" }
      break
    elseif kind == 0xFFFE then
      cmds[#cmds + 1] = { "jump", arg }
      break
    elseif kind == 0xFFFD then
      cmds[#cmds + 1] = { "loop", arg }
    else
      local flags = math.floor(v / 4194304) % 4
      cmds[#cmds + 1] = { "frame", kind, arg, flags % 2 == 1, flags >= 2 }
    end
  end
  return cmds
end

function SpriteGfx.readAnimTable(rom, S, off, limit)
  local n = SpriteGfx.symSize(S, off)
  n = n and math.floor(n / 4) or (limit or 1)
  local anims = {}
  for i = 0, n - 1 do
    local a = SpriteGfx.ptr(rom, off + i * 4)
    if not a then break end
    anims[#anims + 1] = SpriteGfx.readAnim(rom, a)
  end
  return anims
end

function SpriteGfx.maxFrame(anims)
  local m = -1
  for _, anim in ipairs(anims or {}) do
    for _, c in ipairs(anim) do
      if c[1] == "frame" and c[2] > m then m = c[2] end
    end
  end
  return m
end

-- pokeemerald/include/sprite.h:179
function SpriteGfx.readTemplate(rom, S, off)
  local t = {
    tileTag = rom:u16(off),
    paletteTag = rom:u16(off + 2),
  }
  local oamOff = SpriteGfx.ptr(rom, off + 4)
  t.oam = oamOff and SpriteGfx.readOam(rom, oamOff) or SpriteGfx.readOam(rom, off)
  local animsOff = SpriteGfx.ptr(rom, off + 8)
  t.anims = animsOff and SpriteGfx.readAnimTable(rom, S, animsOff, 1) or {}
  local imagesOff = SpriteGfx.ptr(rom, off + 12)
  t.affine = rom:u32(off + 16) ~= 0 and t.oam.affineMode ~= 0
  t.images = {}
  if imagesOff then
    local size = SpriteGfx.symSize(S, imagesOff)
    local n = size and math.floor(size / 8) or (SpriteGfx.maxFrame(t.anims) + 1)
    for i = 0, n - 1 do
      local d = SpriteGfx.ptr(rom, imagesOff + i * 8)
      if not d then break end
      t.images[#t.images + 1] = { off = d, size = rom:u16(imagesOff + i * 8 + 4) }
    end
  end
  return t
end

-- pokeemerald/src/event_object_movement.c:481
function SpriteGfx.objectEventPalettes(rom, off, count)
  local byTag = {}
  for i = 0, count - 1 do
    local base = off + i * 8
    local data = SpriteGfx.ptr(rom, base)
    local tag = rom:u16(base + 4)
    if not data then break end
    if byTag[tag] == nil then byTag[tag] = data end
  end
  return byTag
end

-- pokeemerald/src/field_effect.c:274
local FE_ARGS = { [0] = 1, [1] = 1, [2] = 1, [3] = 1, [4] = 0, [5] = 3, [6] = 2, [7] = 2 }
local FE_PAL_ARG = { [1] = 1, [2] = 1, [5] = 2, [7] = 1 }

function SpriteGfx.fieldEffectScriptPalettes(rom, off, count, byTag)
  byTag = byTag or {}
  for i = 0, count - 1 do
    local p = SpriteGfx.ptr(rom, off + i * 4)
    local steps = 0
    while p and steps < 64 do
      local cmd = rom:get(p)
      local nargs = FE_ARGS[cmd]
      if not nargs or nargs == 0 then break end
      local palArg = FE_PAL_ARG[cmd]
      if palArg then
        local sp = SpriteGfx.ptr(rom, p + 1 + (palArg - 1) * 4)
        if sp then
          local data = SpriteGfx.ptr(rom, sp)
          local tag = rom:u16(sp + 4)
          if data and byTag[tag] == nil then byTag[tag] = data end
        end
      end
      p = p + 1 + nargs * 4
      steps = steps + 1
    end
  end
  return byTag
end

return SpriteGfx
