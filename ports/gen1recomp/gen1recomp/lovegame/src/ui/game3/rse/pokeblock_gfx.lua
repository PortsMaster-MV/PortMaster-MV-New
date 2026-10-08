local Kit = require("src.ui.game3.rse.scene_kit")
local CacheBlob = require("src.import.CacheBlob")

local Gfx = {}
Gfx.__index = Gfx

local instances = {}

local function readCache(path)
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  local data = okC and CacheFs and CacheFs.read and CacheFs.read(path) or nil
  if not data then
    local okD, Dataset = pcall(require, "src.core.game3.dataset")
    if okD and Dataset and Dataset.cache then
      local okR, s = pcall(function() return Dataset.cache():read(path) end)
      if okR then data = s end
    end
  end
  if not data and love and love.filesystem and love.filesystem.getInfo(path) then
    data = CacheBlob.readFs(path)
  end
  return data
end

local function loadLua(path)
  local src = readCache(path)
  if type(src) ~= "string" then return nil end
  local chunk = load(src, "@" .. path, "t", {})
  if not chunk then return nil end
  local ok, t = pcall(chunk)
  return ok and type(t) == "table" and t or nil
end

function Gfx.of(sub)
  local hit = instances[sub]
  if hit then return hit end
  hit = setmetatable({ sub = "data/generated/gba/" .. sub, bytesCache = {}, mapCache = {}, spriteCache = {}, mapImages = {} }, Gfx)
  instances[sub] = hit
  return hit
end

function Gfx.reset()
  instances = {}
end

function Gfx:manifest()
  if self.man then return self.man end
  self.man = assert(loadLua(self.sub .. "/manifest.lua"), self.sub .. "/manifest.lua is missing from the cache")
  return self.man
end

function Gfx:bytes(key)
  local hit = self.bytesCache[key]
  if hit then return hit end
  local entry = assert(self:manifest().gfx[key], self.sub .. ": no gfx " .. tostring(key))
  hit = assert(readCache(entry.path), self.sub .. ": missing " .. entry.path)
  self.bytesCache[key] = hit
  return hit
end

function Gfx:map(key)
  local hit = self.mapCache[key]
  if not hit then
    local entry = assert(self:manifest().maps[key], self.sub .. ": no tilemap " .. tostring(key))
    local data = assert(readCache(entry.path), self.sub .. ": missing " .. entry.path)
    hit = {}
    for i = 0, #data / 2 - 1 do
      local lo, hi = data:byte(i * 2 + 1, i * 2 + 2)
      hit[i] = lo + hi * 256
    end
    hit.n = #data / 2
    self.mapCache[key] = hit
  end
  local copy = { n = hit.n }
  for i = 0, hit.n - 1 do copy[i] = hit[i] end
  return copy
end

function Gfx.rgb8(c)
  c = (tonumber(c) or 0) % 32768
  return math.floor((c % 32) * 255 / 31 + 0.5),
    math.floor((math.floor(c / 32) % 32) * 255 / 31 + 0.5),
    math.floor((math.floor(c / 1024) % 32) * 255 / 31 + 0.5)
end

function Gfx.color(c, a)
  local r, g, b = Gfx.rgb8(c)
  return { r / 255, g / 255, b / 255, a or 1 }
end

function Gfx.palette(list, into, bank)
  into = into or {}
  for i = 1, #list do into[(bank or 0) * 16 + i - 1] = list[i] end
  return into
end

local function newData(w, h)
  local data = love.image.newImageData(w, h)
  local ok, ptr = pcall(function() return data:getFFIPointer() end)
  if ok and ptr then
    local ffi = require("ffi")
    return data, ffi.cast("uint8_t*", ptr)
  end
  return data, nil
end

local function toImage(data)
  local img = love.graphics.newImage(data)
  img:setFilter("nearest", "nearest")
  return img
end

local function put(data, ptr, W, x, y, c)
  if ptr then
    local o = (y * W + x) * 4
    ptr[o], ptr[o + 1], ptr[o + 2], ptr[o + 3] = c[1], c[2], c[3], 255
  else
    data:setPixel(x, y, c[1] / 255, c[2] / 255, c[3] / 255, 1)
  end
end

local function rgbTable(pal)
  local t = {}
  for i = 0, 255 do
    local c = pal[i]
    if c then t[i] = { Gfx.rgb8(c) } end
  end
  return t
end

-- pokeemerald/include/gba/io_reg.h:540
function Gfx:renderMap(entries, gfxKey, pal, opts)
  opts = opts or {}
  local width = opts.width or 32
  local rows = opts.rows or math.floor(entries.n / width)
  local gfx = self:bytes(gfxKey)
  local tiles = math.floor(#gfx / 32)
  local tileBase = opts.tileBase or 0
  local W, H = width * 8, rows * 8
  local data, ptr = newData(W, H)
  local rgb = rgbTable(pal)
  local backdrop = opts.backdrop and rgb[0]
  for ty = 0, rows - 1 do
    for tx = 0, width - 1 do
      local e = entries[ty * width + tx] or 0
      local tile = e % 1024 - tileBase
      local hf = math.floor(e / 1024) % 2 == 1
      local vf = math.floor(e / 2048) % 2 == 1
      local bank = math.floor(e / 4096) % 16
      for py = 0, 7 do
        local sy = vf and (7 - py) or py
        for px = 0, 7 do
          local sx = hf and (7 - px) or px
          local v = 0
          if tile >= 0 and tile < tiles then
            local b = gfx:byte(tile * 32 + sy * 4 + math.floor(sx / 2) + 1) or 0
            v = (sx % 2 == 0) and (b % 16) or math.floor(b / 16)
          end
          local c = (v ~= 0) and rgb[bank * 16 + v] or backdrop
          if c then put(data, ptr, W, tx * 8 + px, ty * 8 + py, c) end
        end
      end
    end
  end
  return toImage(data)
end

function Gfx:mapImage(key, gfxKey, pal, opts)
  local hit = self.mapImages[key]
  if hit then return hit end
  hit = self:renderMap(self:map(opts and opts.map or key), gfxKey, pal, opts)
  self.mapImages[key] = hit
  return hit
end

-- pokeemerald/include/gba/io_reg.h:512
function Gfx:sprite(gfxKey, tile, w, h, pal16, opts)
  opts = opts or {}
  local key = table.concat({ gfxKey, tile, w, h, table.concat(pal16, ",", 1, 16), opts.fill and 1 or 0,
    opts.tilesWide or 0 }, "|")
  local hit = self.spriteCache[key]
  if hit then return hit end
  local gfx = self:bytes(gfxKey)
  local data, ptr = newData(w, h)
  local tw = opts.tilesWide or (w / 8)
  local base = (opts.byteOffset or 0)
  for ty = 0, h / 8 - 1 do
    for tx = 0, w / 8 - 1 do
      local t = tile + ty * tw + tx
      for py = 0, 7 do
        for px = 0, 7 do
          local b = gfx:byte(base + t * 32 + py * 4 + math.floor(px / 2) + 1) or 0
          local v = (px % 2 == 0) and (b % 16) or math.floor(b / 16)
          if v ~= 0 or opts.fill then
            put(data, ptr, w, tx * 8 + px, ty * 8 + py, { Gfx.rgb8(pal16[v + 1]) })
          end
        end
      end
    end
  end
  hit = toImage(data)
  self.spriteCache[key] = hit
  return hit
end

Gfx.readCache = readCache
Gfx.loadLua = loadLua
Gfx.Kit = Kit

function Gfx.pokeblock()
  return Gfx.of("rse/pokeblock")
end

return Gfx
