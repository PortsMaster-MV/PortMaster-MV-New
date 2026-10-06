local bit = require("bit")
local band, rshift = bit.band, bit.rshift

local Vram = {}

function Vram.headless()
  return not (love and love.graphics and love.image)
end

local function readCache(path)
  if Vram.reader then return Vram.reader(path) end
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  local data = okC and CacheFs and CacheFs.read and CacheFs.read(path) or nil
  if not data then
    local okD, Dataset = pcall(require, "src.core.game3.dataset")
    if okD and Dataset and Dataset.cache then
      local okR, s = pcall(function() return Dataset.cache():read(path) end)
      if okR then data = s end
    end
  end
  return data
end
Vram.readCache = readCache

local manifests = {}

function Vram.manifest(sub)
  local hit = manifests[sub]
  if hit then return hit end
  local path = "data/generated/gba/" .. sub .. "/manifest.lua"
  local src = assert(readCache(path), sub .. " manifest is not in the cache")
  hit = assert(load(src, "@" .. path, "t", {}))()
  manifests[sub] = hit
  return hit
end

function Vram.reset()
  manifests = {}
end

function Vram.bytes(man, kind, key)
  local e = assert(man[kind][key], "contest gfx: no " .. kind .. " " .. tostring(key))
  return assert(readCache(e.path), "contest gfx: missing " .. e.path)
end

function Vram.u16s(s)
  local out = {}
  for i = 0, math.floor(#s / 2) - 1 do
    local lo, hi = s:byte(i * 2 + 1, i * 2 + 2)
    out[i] = lo + hi * 256
  end
  return out
end

-- pokeemerald/include/gba/defines.h:81
function Vram.decodeTiles(bytes, into, firstTile)
  into = into or {}
  firstTile = firstTile or 0
  for t = 0, math.floor(#bytes / 32) - 1 do
    local px = {}
    for y = 0, 7 do
      for xb = 0, 3 do
        local b = bytes:byte(t * 32 + y * 4 + xb + 1) or 0
        px[y * 8 + xb * 2] = b % 16
        px[y * 8 + xb * 2 + 1] = math.floor(b / 16)
      end
    end
    into[firstTile + t] = px
  end
  return into
end

local function newData(w, h)
  local data = love.image.newImageData(w, h)
  local ok, ptr = pcall(function() return data:getFFIPointer() end)
  if ok and ptr then return data, require("ffi").cast("uint8_t*", ptr) end
  return data, nil
end

local function setIdx(data, ptr, W, x, y, v)
  if ptr then
    local o = (y * W + x) * 4
    ptr[o], ptr[o + 1], ptr[o + 2], ptr[o + 3] = v, v, v, 255
  else
    data:setPixel(x, y, v / 255, v / 255, v / 255, 1)
  end
end

local Layer = {}
Layer.__index = Layer

-- pokeemerald/src/bg.c:874
function Vram.layer(tiles, wTiles, hTiles, headless)
  local self = setmetatable({ tiles = tiles, wt = wTiles, ht = hTiles, map = {}, headless = headless }, Layer)
  for i = 0, wTiles * hTiles - 1 do self.map[i] = 0 end
  if not headless then
    self.data, self.ptr = newData(wTiles * 8, hTiles * 8)
    for i = 0, wTiles * hTiles - 1 do self:_paint(i) end
    self.image = love.graphics.newImage(self.data)
    self.image:setFilter("nearest", "nearest")
    self.layer = { image = self.image, w = wTiles * 8, h = hTiles * 8, bpp = 4 }
  end
  return self
end

function Layer:_paint(cell)
  if self.headless then return end
  local e = self.map[cell]
  local tile = e % 1024
  local hf = math.floor(e / 1024) % 2 == 1
  local vf = math.floor(e / 2048) % 2 == 1
  local bank = math.floor(e / 4096) % 16
  local px = self.tiles[tile]
  local W = self.wt * 8
  local x0, y0 = (cell % self.wt) * 8, math.floor(cell / self.wt) * 8
  for y = 0, 7 do
    local sy = vf and (7 - y) or y
    for x = 0, 7 do
      local sx = hf and (7 - x) or x
      local v = px and px[sy * 8 + sx] or 0
      setIdx(self.data, self.ptr, W, x0 + x, y0 + y, v == 0 and 0 or bank * 16 + v)
    end
  end
  self.dirty = true
end

function Layer:cellOf(x, y)
  return (y % self.ht) * self.wt + (x % self.wt)
end

function Layer:get(x, y)
  return self.map[self:cellOf(x, y)]
end

function Layer:put(x, y, entry)
  local cell = self:cellOf(x, y)
  entry = band(tonumber(entry) or 0, 0xFFFF)
  if self.map[cell] == entry then return end
  self.map[cell] = entry
  self:_paint(cell)
end

function Layer:setIndex(i, entry)
  self:put(i % self.wt, math.floor(i / self.wt), entry)
end

function Layer:load(entries, count)
  for i = 0, (count or self.wt * self.ht) - 1 do self:setIndex(i, entries[i] or 0) end
end

function Layer:clear()
  for i = 0, self.wt * self.ht - 1 do self:setIndex(i, 0) end
end

function Layer:setTiles(tiles)
  self.tiles = tiles
  for i = 0, self.wt * self.ht - 1 do self:_paint(i) end
end

-- pokeemerald/src/bg.c:1033
function Layer:writeSequence(firstTileNum, x, y, width, height, paletteSlot, delta)
  delta = delta or 0
  for yy = y, y + height - 1 do
    for xx = x, x + width - 1 do
      local v
      if paletteSlot == 17 or paletteSlot == nil then
        v = firstTileNum
      elseif paletteSlot == 16 then
        v = band(self:get(xx, yy), 0xFC00) + band(firstTileNum, 0x3FF)
      else
        v = band(firstTileNum, 0xFFF) + paletteSlot * 4096
      end
      self:put(xx, yy, v)
      firstTileNum = band(firstTileNum, 0xFC00) + band(firstTileNum + delta, 0x3FF)
    end
  end
end

-- pokeemerald/src/bg.c:951
function Layer:copyRect(src, destX, destY, w, h, palette)
  local i = 0
  for y = destY, destY + h - 1 do
    for x = destX, destX + w - 1 do
      local v = src[i] or 0
      if palette then v = band(v, 0x0FFF) + palette * 4096 end
      self:put(x, y, v)
      i = i + 1
    end
  end
end

function Layer:flush()
  if self.dirty and self.image then self.image:replacePixels(self.data) end
  self.dirty = false
end

-- pokeemerald/src/sprite.c:1486
function Vram.sheet(tiles, frames, w, h, headless)
  local sheet = { w = w, h = h * #frames, frameW = w, frameH = h, frames = #frames }
  if headless then return sheet end
  local data, ptr = newData(w, h * #frames)
  local tw = w / 8
  for f, first in ipairs(frames) do
    local oy = (f - 1) * h
    for ty = 0, h / 8 - 1 do
      for tx = 0, tw - 1 do
        local px = tiles[first + ty * tw + tx]
        for y = 0, 7 do
          for x = 0, 7 do
            setIdx(data, ptr, w, tx * 8 + x, oy + ty * 8 + y, px and px[y * 8 + x] or 0)
          end
        end
      end
    end
  end
  sheet.image = love.graphics.newImage(data)
  sheet.image:setFilter("nearest", "nearest")
  return sheet
end

-- pokeemerald/src/util.c:157
function Vram.sheetFromTileList(tileList, w, h, headless)
  local sheet = { w = w, h = h, frameW = w, frameH = h, frames = 1 }
  if headless then return sheet end
  local data, ptr = newData(w, h)
  local tw = w / 8
  for i, px in pairs(tileList) do
    local tx, ty = i % tw, math.floor(i / tw)
    for y = 0, 7 do
      for x = 0, 7 do setIdx(data, ptr, w, tx * 8 + x, ty * 8 + y, px[y * 8 + x] or 0) end
    end
  end
  sheet.image = love.graphics.newImage(data)
  sheet.image:setFilter("nearest", "nearest")
  return sheet
end

function Vram.flipTile(px, hf, vf)
  if not (hf or vf) then return px end
  local out = {}
  for y = 0, 7 do
    for x = 0, 7 do
      out[y * 8 + x] = px[(vf and 7 - y or y) * 8 + (hf and 7 - x or x)]
    end
  end
  return out
end

-- pokeemerald/src/decompress.c:73
function Vram.indexedPic(rgba, headless)
  local colors, order = {}, { [0] = 0 }
  local idx = {}
  for i = 0, 64 * 64 - 1 do
    local r, g, b, a = 0, 0, 0, 0
    if rgba then r, g, b, a = rgba:byte(i * 4 + 1, i * 4 + 4) end
    if (a or 0) == 0 then
      idx[i] = 0
    else
      local c = math.floor(r * 31 / 255 + 0.5) + math.floor(g * 31 / 255 + 0.5) * 32
        + math.floor(b * 31 / 255 + 0.5) * 1024
      local n = colors[c]
      if not n then
        n = #order + 1
        if n > 15 then n = 15 end
        colors[c] = n
        order[n] = c
      end
      idx[i] = n
    end
  end
  local pal = {}
  for i = 0, 15 do pal[i + 1] = order[i] or 0 end
  local sheet = { w = 64, h = 64, frameW = 64, frameH = 64, frames = 1 }
  if not headless then
    local data, ptr = newData(64, 64)
    for i = 0, 64 * 64 - 1 do setIdx(data, ptr, 64, i % 64, math.floor(i / 64), idx[i]) end
    sheet.image = love.graphics.newImage(data)
    sheet.image:setFilter("nearest", "nearest")
  end
  return sheet, pal
end

Vram.rshift = rshift

return Vram
