-- engine/pokemon/learn.asm:135-166

local Chrome = require("src.ui.gen2.Chrome")

local ForgetMoveList = {
  x = 5, y = 2, interiorW = 13, interiorH = 8,
  cursorX = 6, nameX = 7, y0 = 4, step = 2, rows = 4,
}

function ForgetMoveList.rowY(slot)
  return ForgetMoveList.y0 + (slot - 1) * ForgetMoveList.step
end

function ForgetMoveList.label(entry, moveData)
  if not entry then return "-" end
  local def = moveData and moveData[entry.id]
  return (def and def.name) or entry.id
end

function ForgetMoveList.draw(moves, cursor, moveData, palette)
  Chrome.textbox(ForgetMoveList.x, ForgetMoveList.y,
    ForgetMoveList.interiorW, ForgetMoveList.interiorH)
  for slot = 1, ForgetMoveList.rows do
    local ty = ForgetMoveList.rowY(slot)
    local label = ForgetMoveList.label(moves and moves[slot], moveData)
    if palette then
      Chrome.printThrough(label, ForgetMoveList.nameX, ty, palette)
    else
      Chrome.print(label, ForgetMoveList.nameX, ty)
    end
    if slot == cursor then
      if palette then
        Chrome.cursorThrough(ForgetMoveList.cursorX, ty, palette)
      else
        Chrome.cursor(ForgetMoveList.cursorX, ty)
      end
    end
  end
end

return ForgetMoveList
