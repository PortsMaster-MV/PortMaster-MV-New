local OwSheet = {}

local cache = {}

local function to5(v)
  return math.floor(math.floor(v * 255 + 0.5) / 8)
end

function OwSheet.build(graphicsId)
  local hit = cache[graphicsId]
  if hit then return hit end
  local OwSprites = require("src.core.game3.ow_sprites")
  local spr = OwSprites.get(graphicsId)
  assert(spr and spr.imageData, "ow_sheet: no OW sheet for graphics id " .. tostring(graphicsId))
  local src = spr.imageData
  local w, h = src:getWidth(), src:getHeight()
  local colors, byKey = {}, {}
  local out = love.image.newImageData(w, h)
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local r, g, b, a = src:getPixel(x, y)
      local idx = 0
      if a > 0 then
        local c = to5(r) + to5(g) * 32 + to5(b) * 1024
        idx = byKey[c]
        if not idx then
          idx = #colors + 1
          if idx > 15 then error("ow_sheet: graphics id " .. tostring(graphicsId) .. " has more than 15 colours") end
          colors[idx] = c
          byKey[c] = idx
        end
      end
      out:setPixel(x, y, idx / 255, 0, 0, 1)
    end
  end
  local img = love.graphics.newImage(out)
  img:setFilter("nearest", "nearest")
  local palette = { 0 }
  for i = 1, 15 do palette[i + 1] = colors[i] or 0 end
  hit = {
    sheet = { image = img, w = w, h = h, frameW = spr.width, frameH = spr.height },
    palette = palette,
    w = spr.width,
    h = spr.height,
    paletteTag = OwSprites._manifest and OwSprites._manifest.sprites and OwSprites._manifest.sprites[graphicsId]
      and OwSprites._manifest.sprites[graphicsId].paletteTag or (0x1100 + graphicsId),
  }
  cache[graphicsId] = hit
  return hit
end

function OwSheet.reset()
  cache = {}
end

return OwSheet
