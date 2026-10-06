local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local M = {}
function M.draw(storage, boxId)
  local man = assert(Kit.manifest("pokemon/storage"))
  local center, sides = man.sprites.box_popup_center, man.sprites.box_popup_sides
  local centerImg, sideImg = assert(Kit.image(center.png)), assert(Kit.image(sides.png))
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(centerImg, man.boxPopup.center.x - 32, man.boxPopup.center.y - 32)
  for i, pos in ipairs(man.boxPopup.sides) do
    local rect = sides.rects[pos.frame + 1]
    local q = love.graphics.newQuad(rect.x, rect.y, rect.w, rect.h, sideImg:getDimensions())
    love.graphics.draw(sideImg, q, pos.x - rect.w / 2, pos.y - rect.h / 2)
  end
  local arrow = man.sprites.box_scroll_arrow
  local arrowImg = assert(Kit.image(arrow.png))
  for i = 0, 1 do
    local q = love.graphics.newQuad(0, i * arrow.h, arrow.w, arrow.h, arrowImg:getDimensions())
    love.graphics.draw(arrowImg, q, 120 + i * 72, 80)
  end
  local raw = assert(require("src.core.game3.dataset").cache():read("data/generated/gba/rs/assets/pokemon_storage__gBoxSelectionPopupPalette.rom"))
  local function color(index)
    local a, b = raw:byte(index * 2 + 1, index * 2 + 2)
    local r, g, blue = Kit.rgb555(a + b * 256); return {r, g, blue, 1}
  end
  local colors = {fg = color(15), shadow = color(14), bg = color(1)}
  love.graphics.setColor(colors.bg); love.graphics.rectangle("fill", 128, 72, 64, 32)
  love.graphics.setColor(1, 1, 1, 1)
  local box, count = assert(storage.boxes[boxId]), 0
  for i = 1, 30 do if box.mons[i] then count = count + 1 end end
  Font.draw(box.name, 128, 72, {colors = colors, maxWidth = 64})
  Font.draw(count .. "/30", 128 + (count < 10 and 40 or 34), 88, {colors = colors, maxWidth = 64})
end
return M
