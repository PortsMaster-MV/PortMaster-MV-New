local M = {isMenu = true, open = false, cursor = 0, WINDOW = {left = 16, top = 7, width = 13, height = 6}}
local Stack = require("src.ui.game3.stack")
local Font = require("src.ui.game3.frlg_font")
local Window = require("src.ui.game3.window")
local RomText = require("src.core.game3.rom_text")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local function se() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_SELECT) end
function M.isOpen() return M.open end
function M.rows(dc)
  local D, P = require("src.core.game3.daycare"), require("src.core.game3.pokemon")
  local out = {}
  for i = 1, 2 do
    local mon = D.mon(dc, i)
    local name = D.nickname(mon)
    local gender = P.gender(D.speciesOf(mon), mon and mon.personality or 0)
    local already = (gender == "M" and name:find("♂", 1, true) and not name:find("♀", 1, true))
      or (gender == "F" and name:find("♀", 1, true) and not name:find("♂", 1, true))
    local key = not already and (gender == "M" and "gOtherText_MaleSymbol3" or gender == "F" and "gOtherText_FemaleSymbol3")
      or "gOtherText_GenderlessSymbol"
    out[i] = {text = name .. RomText.plain(key), level = D.levelAfterSteps(mon, dc.steps[i])}
  end
  out[3] = {text = RomText.plain("gOtherText_CancelAndLv")}
  return out
end
function M.show(dc, done)
  M.rowList, M.cursor, M._done, M.open = M.rows(dc), 0, done, true
  Stack.push("rs_daycare_level", M, {drawUnder = true, hideBelow = false})
  return true
end
function M.close(value)
  local done = M._done; M._done, M.open = nil, false
  Stack.pop("rs_daycare_level")
  if done then done(value) end
end
function M.reset() M._done = nil; M.close(); M.rowList = nil end
-- daycare.c:1021
function M.handleInput(input)
  if not M.open then return end
  if input:wasPressed("up") then if M.cursor > 0 then M.cursor = M.cursor - 1; se() end
  elseif input:wasPressed("down") then if M.cursor < 2 then M.cursor = M.cursor + 1; se() end
  elseif input:wasPressed("a") then se(); M.close(M.cursor)
  elseif input:wasPressed("b") then M.close(2) end
end
function M.draw()
  if not M.open then return end
  Window.stdFrame(Window.template(16, 7, 13, 6))
  for i, row in ipairs(M.rowList) do
    local y = 56 + (i - 1) * 16
    Font.draw(row.text, 128, y, {colors = Font.COLOR.NORMAL})
    if row.level then
      Font.drawGlyph(0x34, 206, y, {colors = Font.COLOR.NORMAL, font = "native_3"})
      Font.draw(string.char(252, 20, 6) .. string.format("%3d", row.level) .. string.char(252, 20, 0),
        206 + Font.advance(0x34, {font = "native_3"}), y, {colors = Font.COLOR.NORMAL, font = "native_3"})
    end
  end
  Cursor.draw(128, 56 + M.cursor * 16, 13 * 8)
end
return M
