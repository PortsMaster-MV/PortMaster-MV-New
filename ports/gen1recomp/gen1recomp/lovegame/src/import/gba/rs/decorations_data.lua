local A = require("src.import.gba.rs.assets")
local M = {SHAPE_CELLS = {[0] = 1, 2, 3, 8, 4, 2, 3, 8, 9, 6}}
function M.read(c)
  local out = {format_version = 1, count = c.S.count("gDecorations", 32), decorations = {}, categoryNames = {},
    categorySizes = {[0] = 10, 10, 10, 30, 30, 10, 40, 10}, decorTiles = {}, nativeIcons = false}
  assert(out.count == 121, "native RS decoration count including NONE")
  local off = c:off("gDecorations")
  for i = 0, out.count - 1 do
    local row, tiles = off + i * 32, {}
    assert(c:u8(row) == i, "native decoration ID/order")
    local perm, shape, ptr = c:u8(row + 17), c:u8(row + 18), assert(c:ptr(row + 28))
    for j = 0, (perm == 4 and 1 or assert(M.SHAPE_CELLS[shape])) - 1 do tiles[j + 1] = c:u16(ptr + j * 2) end
    out.decorations[i] = {id = i, name = A.text(c, row + 1), permission = perm, shape = shape,
      category = c:u8(row + 19), price = c:u16(row + 20), description = A.text(c, assert(c:ptr(row + 24))), tiles = tiles}
    out.decorTiles[i] = tiles
  end
  local co = c:off("gUnknown_083EC5E4")
  assert(c.S.count("gUnknown_083EC5E4", 4) == 8, "native eight decoration categories")
  for i = 0, 7 do out.categoryNames[i] = A.text(c, assert(c:ptr(co + i * 4))) end
  return out
end
return M
