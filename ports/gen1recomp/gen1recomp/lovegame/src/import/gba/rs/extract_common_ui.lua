local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/common_ui", FILES = {}}
for _, key in ipairs({"left", "middle", "right", "wide"}) do
  M.FILES[#M.FILES + 1] = "cursor_" .. key .. ".png"
  M.FILES[#M.FILES + 1] = "cursor_" .. key .. "_mask.png"
end
M.REQUIRED = K.required(M.SUB, M.FILES)
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- menu.c:721
  local cursor = {paletteIndex = 12, color = 11679, height = 16, widthUnit = 8, topLeft = true,
    source = "menu_cursor.c:sub_814A958", templates = {}, anims = c:readAnim(c:off("gSpriteAnim_842F134"))}
  local gfx, pal = c:raw("OutlineCursorTiles_12"), {[12] = 11679}
  assert(#gfx == 0x1C0, "native menu outline cursor graphics size")
  for _, p in ipairs({{"left", 0, 8}, {"middle", 2, 8}, {"right", 4, 8}, {"wide", 6, 32}}) do
    local idx = K.bakeSprite(gfx, p[3], 16, p[2], 4)
    cursor[p[1]] = {png = c:png("cursor_" .. p[1] .. ".png", p[3], 16, idx, pal, true),
      mask = c:mask("cursor_" .. p[1] .. "_mask.png", p[3], 16, idx, {[12] = true}), w = p[3], h = 16, tile = p[2]}
  end
  local to = c:off("gSpriteTemplate_842F250")
  for i = 0, 2 do
    local o = to + i * 24
    cursor.templates[i + 1] = {tileTag = c:u16(o), paletteTag = c:u16(o + 2),
      oam = c:readOam(assert(c:ptr(o + 4))), callback = c.S.funcAt(c:u32(o + 20))}
  end
  cursor.composition = {leftX = -1, initialAdvance = 1, wideThreshold = 31, overlapWidthThreshold = 39,
    overlapRemainderThreshold = 8, rightAdjustment = -7}
  cursor.objWindow = {dispcntMask = 0x8000, winoutObj = 0x10}
  return A.finish(c, {screen = "common_ui", menuCursor = cursor})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
