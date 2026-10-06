local Kit = require("src.ui.game3.rse.scene_kit")
local Fx = require("src.core.game3.gba_fx")
local M = {}

function M.segments(width)
  local out = {{part = "left", x = -1}}
  local advance = 1
  local remaining = width - advance
  while remaining >= 8 do
    if remaining > 31 then
      out[#out + 1] = {part = "wide", x = advance}
      advance = advance + 32
    elseif width > 39 and remaining > 8 then
      out[#out + 1] = {part = "wide", x = advance - 32 + math.floor(remaining / 8) * 8}
      advance = advance + math.floor((remaining % 32) / 8) * 8
    else
      out[#out + 1] = {part = "middle", x = advance}
      advance = advance + 8
    end
    remaining = width - advance
  end
  out[#out + 1] = {part = "right", x = advance - 7 + remaining}
  return out
end

function M.draw(x, y, width, fx)
  local man = assert(Kit.manifest("rse/common_ui"), "native RS common UI missing")
  assert(man.layout == "rs" and man.menuCursor, "native RS menu cursor missing")
  local cursor = man.menuCursor
  local parts = cursor.parts or cursor
  local segments = M.segments(width)
  for i = #segments, 1, -1 do
    local s = segments[i]
    local img = assert(Kit.image(assert(parts[s.part], "native RS cursor part missing").png), "native RS cursor image missing")
    love.graphics.setColor(1, 1, 1, 1)
    Fx.draw(function() love.graphics.draw(img, x + s.x, y) end, fx)
  end
end

return M
