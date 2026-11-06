-- Per 8x8 cell tile id + GBC attributes, mirroring pret wSurroundingTiles +
-- wAttrmap as built by LoadOverworldAttrmapPals (engine/tilesets/map_palettes.asm).
--
-- Retail Crystal derives palette (+ VRAM bank in the palmap nybble) from the
-- tileset PalMap indexed by the metatile byte; bit 7 of the tile id is cleared
-- into the attr bank bit and the normalized id is what VRAM fetches.

local BorderFill = require("src.world.gen2.BorderFill")
local TileAttrs = require("src.world.gen2.TileAttrs")

local MapAttrGrid = {}

-- pret _LoadOverworldAttrmapPals: srl a / carry picks upper vs lower nybble;
-- res 7,[hl] clears tile bit 7 after the lookup.
function MapAttrGrid.normalizeTile(rawTileId, tileset)
  if not rawTileId then return nil, nil end
  local bankFromTile = (rawTileId >= 0x80) and 1 or 0
  local normId = rawTileId % 0x80

  local attrs = tileset and tileset.tileAttrs
  local attr
  if attrs then
    if bankFromTile == 1 then
      attr = attrs[0x80 + normId + 1] or attrs[normId + 1]
    else
      attr = attrs[normId + 1] or attrs[0x80 + normId + 1]
    end
  end
  if not attr then
    attr = TileAttrs.forTile(tileset, rawTileId)
  end

  local out = {
    palette = attr.palette,
    vramBank = (attr.vramBank ~= 0 and attr.vramBank or bankFromTile),
    priority = attr.priority,
    xFlip = attr.xFlip,
    yFlip = attr.yFlip,
  }
  return normId, out
end

function MapAttrGrid.tileAt(map, tileset, mx, my)
  local bx, by = math.floor(mx / 32), math.floor(my / 32)
  if bx < 0 or by < 0 or bx >= map.width or by >= map.height then return nil end
  local blockId = BorderFill.blockFor(
    map.blocks[by * map.width + bx + 1], map.borderBlock)
  local block = tileset.blocks and tileset.blocks[(blockId or 0) + 1]
  if not block then return nil end
  local i = math.floor((my % 32) / 8) * 4 + math.floor((mx % 32) / 8)
  return block[i + 1]
end

function MapAttrGrid.cellAt(map, tileset, mx, my)
  local raw = MapAttrGrid.tileAt(map, tileset, mx, my)
  if raw == nil then return nil end
  local tileId, attr = MapAttrGrid.normalizeTile(raw, tileset)
  return { tileId = tileId, rawTileId = raw, attr = attr }
end

-- Full map grid for fast lookup during overdraw: a flat array indexed by
-- 8x8 cell (row-major, `cols` cells to a row), so a lookup is two divides and
-- an index rather than a string key built per tile per entity per frame.
-- Cells with the same raw tile id share one read-only cell table: the
-- normalization depends only on (raw id, tileset).
function MapAttrGrid.build(map, tileset)
  local grid = { cols = 0, rows = 0, cells = {} }
  if not (map and tileset) then return grid end
  local cols, rows = map.width * 4, map.height * 4
  grid.cols, grid.rows = cols, rows
  local cells = grid.cells
  local byRaw = {}
  for cy = 0, rows - 1 do
    for cx = 0, cols - 1 do
      local raw = MapAttrGrid.tileAt(map, tileset, cx * 8, cy * 8)
      if raw ~= nil then
        local cell = byRaw[raw]
        if not cell then
          local tileId, attr = MapAttrGrid.normalizeTile(raw, tileset)
          cell = { tileId = tileId, rawTileId = raw, attr = attr }
          byRaw[raw] = cell
        end
        cells[cy * cols + cx + 1] = cell
      end
    end
  end
  return grid
end

function MapAttrGrid.lookup(grid, mx, my)
  if not grid then return nil end
  local cx = math.floor(mx / 8)
  local cy = math.floor(my / 8)
  local cols = grid.cols
  if not cols or cx < 0 or cy < 0 or cx >= cols or cy >= grid.rows then
    return nil
  end
  return grid.cells[cy * cols + cx + 1]
end

return MapAttrGrid
