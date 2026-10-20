-- pokeruby/src/starter_choose.c:267
local Policy = {
  messageKey = "gOtherText_BirchInTrouble",
  confirmKey = "gOtherText_DoYouChoosePoke",
  categoryKey = "gOtherText_Poke",
  windows = {
    message = { tilemapLeft = 3, tilemapTop = 15, width = 24, height = 4 },
    confirm = { tilemapLeft = 22, tilemapTop = 8, width = 5, height = 4 },
  },
}

local shadow = { 26 / 31, 26 / 31, 25 / 31, 1 }
Policy.labelColors = { fg = { 1, 1, 1, 1 }, bg = { 0, 0, 0, 0 }, shadow = shadow }
Policy.messageColors = { fg = { 9 / 31, 9 / 31, 9 / 31, 1 },
  bg = { 1, 1, 1, 1 }, shadow = shadow }

function Policy.labelRect(man, selection)
  local c = man.labelCoords[selection + 1]
  return c[1] * 8 + 4, c[2] * 8, (c[1] + 13) * 8 + 4, (c[2] + 4) * 8
end

function Policy.categoryText(category, pokemon)
  return category:sub(1, 11) .. " " .. pokemon
end

function Policy.affineScale(matrix)
  return matrix ~= 0 and 256 / matrix or 0
end

function Policy.drawAffine(cx, cy, matrix, halfSize, draw)
  local G = love.graphics
  G.push("all")
  local x0, y0 = G.transformPoint(cx - halfSize, cy - halfSize)
  local x1, y1 = G.transformPoint(cx + halfSize, cy + halfSize)
  G.intersectScissor(math.floor(math.min(x0, x1)), math.floor(math.min(y0, y1)),
    math.ceil(math.abs(x1 - x0)), math.ceil(math.abs(y1 - y0)))
  draw(Policy.affineScale(matrix))
  G.pop()
end

function Policy.drawLabel(label, man)
  local Font = require("src.ui.game3.frlg_font")
  local c = man.labelCoords[label.selection + 1]
  local x, y = c[1] * 8, c[2] * 8
  Font.draw(label.category, x + 5, y, { colors = Policy.labelColors })
  local width = Font.measure(label.name)
  Font.draw(label.name, x + math.max(0, 107 - width), y + 16,
    { colors = Policy.labelColors })
end

local Confirm = {}
Confirm.__index = Confirm

function Policy.confirm(frameType)
  return setmetatable({ cursor = 0, frameType = frameType or 0 }, Confirm)
end

function Confirm:input(inp)
  local n = inp.new or {}
  local Kit = require("src.ui.game3.rse.scene_kit")
  if n.a then Kit.playSe("SE_SELECT"); return self.cursor end
  if n.b then Kit.playSe("SE_SELECT"); return -1 end
  local before = self.cursor
  if n.up then self.cursor = math.max(0, self.cursor - 1)
  elseif n.down then self.cursor = math.min(1, self.cursor + 1) end
  if self.cursor ~= before then Kit.playSe("SE_SELECT") end
  return nil
end

function Confirm:draw()
  local Kit = require("src.ui.game3.rse.scene_kit")
  local Text = require("src.core.game3.rom_text")
  local Font = require("src.ui.game3.frlg_font")
  local w = Policy.windows.confirm
  Kit.userFrame(w.tilemapLeft, w.tilemapTop, w.width, w.height, self.frameType, Policy.messageColors.bg)
  Font.draw(Text.plain("OtherText_Yes"), 176, 64, { colors = Policy.messageColors })
  Font.draw(Text.plain("OtherText_No"), 176, 80, { colors = Policy.messageColors })
  require("src.ui.game3.rs.menu_cursor").draw(176, 64 + self.cursor * 16, 40)
end

return Policy
