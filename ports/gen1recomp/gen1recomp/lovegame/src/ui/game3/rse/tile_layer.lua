local TileLayer = {}
TileLayer.__index = TileLayer

TileLayer.SIZE = 32

local function decodeTiles(bytes)
  local tiles = {}
  local n = math.floor(#bytes / 32)
  for t = 0, n - 1 do
    local px = {}
    for y = 0, 7 do
      for xb = 0, 3 do
        local b = bytes:byte(t * 32 + y * 4 + xb + 1) or 0
        px[y * 8 + xb * 2] = b % 16
        px[y * 8 + xb * 2 + 1] = math.floor(b / 16)
      end
    end
    tiles[t] = px
  end
  return tiles, n
end
TileLayer.decodeTiles = decodeTiles

function TileLayer.new(tileBytes, opts)
  opts = opts or {}
  local self = setmetatable({}, TileLayer)
  self.tiles, self.tileCount = decodeTiles(tileBytes or "")
  self.map = {}
  for i = 0, TileLayer.SIZE * TileLayer.SIZE - 1 do self.map[i] = 0 end
  self.headless = opts.headless or not (love and love.image and love.graphics)
  if not self.headless then
    self.data = love.image.newImageData(256, 256)
    for cell = 0, TileLayer.SIZE * TileLayer.SIZE - 1 do self:_paint(cell) end
    self.image = love.graphics.newImage(self.data)
    self.image:setFilter("nearest", "nearest")
    self.layer = { image = self.image, w = 256, h = 256, bpp = 4 }
  end
  self.dirty = false
  return self
end

function TileLayer:_paint(cell)
  if self.headless then return end
  local e = self.map[cell]
  local tile = e % 1024
  local hf = math.floor(e / 1024) % 2 == 1
  local vf = math.floor(e / 2048) % 2 == 1
  local bank = math.floor(e / 4096) % 16
  local px = self.tiles[tile]
  local x0, y0 = (cell % 32) * 8, math.floor(cell / 32) * 8
  local d = self.data
  for y = 0, 7 do
    local sy = vf and (7 - y) or y
    for x = 0, 7 do
      local sx = hf and (7 - x) or x
      local v = px and px[sy * 8 + sx] or 0
      local idx = (v == 0) and 0 or (bank * 16 + v)
      d:setPixel(x0 + x, y0 + y, idx / 255, 0, 0, 1)
    end
  end
  self.dirty = true
end

-- pokeemerald/src/bg.c:1145
function TileLayer.cellOf(x, y)
  return (y % 32) * 32 + (x % 32)
end

function TileLayer:get(x, y)
  return self.map[TileLayer.cellOf(x, y)]
end

function TileLayer:put(x, y, entry)
  local cell = TileLayer.cellOf(x, y)
  entry = (tonumber(entry) or 0) % 0x10000
  if self.map[cell] == entry then return end
  self.map[cell] = entry
  self:_paint(cell)
end

-- pokeemerald/src/bg.c:951
function TileLayer:copyRect(src, srcOffset, destX, destY, w, h)
  local i = (srcOffset or 0) + 1
  for y = destY, destY + h - 1 do
    for x = destX, destX + w - 1 do
      self:put(x, y, src[i] or 0)
      i = i + 1
    end
  end
end

-- pokeemerald/src/bg.c:1033
function TileLayer:fill(entry, x, y, w, h)
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do self:put(xx, yy, entry) end
  end
end

function TileLayer:flush()
  if self.dirty and self.image then
    self.image:replacePixels(self.data)
  end
  self.dirty = false
end

return TileLayer
