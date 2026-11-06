local Kit = require("src.ui.game3.rse.scene_kit")
local M = {}

function M.draw(dir, x, y, frame)
  local man = assert(Kit.manifest("rse/bag"), "native RS bag arrows missing")
  local horizontal = dir == "left" or dir == "right"
  local a = assert(man.sprites[horizontal and "arrows_horizontal" or "arrows_vertical"])
  local index = (dir == "down" or dir == "right") and 1 or 0
  local sign = index == 0 and -1 or 1
  local offset = math.floor(((frame or 0) + 2) / 3) % 8 * sign
  local img = assert(Kit.image(a.png), "native RS arrow image missing")
  local w, h = img:getDimensions()
  local q = love.graphics.newQuad(0, index * a.h, a.w, a.h, w, h)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, q, x - a.w / 2 + (horizontal and offset or 0),
    y - a.h / 2 + (horizontal and 0 or offset))
end

return M
