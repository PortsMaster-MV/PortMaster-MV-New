-- Generation-neutral minimap rasterization. WorldAPI arms own semantic
-- markers because object/event visibility differs; terrain and tile shading
-- share one output contract.

local Assets = require("src.render.Assets")

local MapOverview = {}
local overviewShades = {}

Assets.register(function() overviewShades = {} end)

local function shadeDigit(sum, pixelCount)
  return tostring(math.max(0, math.min(3,
    math.floor((1 - sum / pixelCount) * 3 + 0.5))))
end

local function tileRows(map)
  local tileset = map.tileset
  if not (tileset and tileset.image and tileset.tilesPerRow) then return nil end
  local cached = overviewShades[tileset.image]
  if not cached then
    local ok, pixels = pcall(Assets.imageData, tileset.image)
    if not ok then return nil end
    cached = { pixels = pixels, shades = {} }
    overviewShades[tileset.image] = cached
  end
  local rows, detailRows, perRow = {}, {}, tileset.tilesPerRow
  for ty = 0, map.heightCells * 2 - 1 do
    local row, detailTop, detailBottom = {}, {}, {}
    for tx = 0, map.widthCells * 2 - 1 do
      local tile = map:tileAt(tx, ty)
      local shades = cached.shades[tile]
      if shades == nil then
        local sums = { 0, 0, 0, 0 }
        local ox, oy = (tile % perRow) * 8, math.floor(tile / perRow) * 8
        for py = 0, 7 do
          for px = 0, 7 do
            local r, g, b = cached.pixels:getPixel(ox + px, oy + py)
            local quadrant = math.floor(py / 4) * 2 + math.floor(px / 4) + 1
            sums[quadrant] = sums[quadrant]
              + r * 0.2126 + g * 0.7152 + b * 0.0722
          end
        end
        shades = {
          shadeDigit(sums[1] + sums[2] + sums[3] + sums[4], 64),
          shadeDigit(sums[1], 16), shadeDigit(sums[2], 16),
          shadeDigit(sums[3], 16), shadeDigit(sums[4], 16),
        }
        cached.shades[tile] = shades
      end
      row[#row + 1] = shades[1]
      detailTop[#detailTop + 1] = shades[2] .. shades[3]
      detailBottom[#detailBottom + 1] = shades[4] .. shades[5]
    end
    rows[#rows + 1] = table.concat(row)
    detailRows[#detailRows + 1] = table.concat(detailTop)
    detailRows[#detailRows + 1] = table.concat(detailBottom)
  end
  return rows, detailRows
end

function MapOverview.build(map, markers)
  local rows = {}
  for y = 0, map.heightCells - 1 do
    local row = {}
    for x = 0, map.widthCells - 1 do
      row[#row + 1] = map:isWarpTileCell(x, y) and "+"
        or map:isWaterCell(x, y) and "~"
        or map:isWalkableCell(x, y) and "." or " "
    end
    rows[#rows + 1] = table.concat(row)
  end
  local tiles, detail = tileRows(map)
  return { mapId = map.id, width = map.widthCells,
           height = map.heightCells, rows = rows, markers = markers,
           tileRows = tiles,
           tileWidth = tiles and map.widthCells * 2,
           tileHeight = tiles and map.heightCells * 2,
           tileDetailRows = detail,
           tileDetailWidth = detail and map.widthCells * 4,
           tileDetailHeight = detail and map.heightCells * 4 }
end

return MapOverview
