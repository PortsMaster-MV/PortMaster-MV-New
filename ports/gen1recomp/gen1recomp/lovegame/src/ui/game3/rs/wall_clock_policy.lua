-- pokeruby/src/wallclock.c:771
local Kit = require("src.ui.game3.rse.scene_kit")
local Chrome = require("src.ui.game3.chrome")
local Font = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local M = {}

function M.confirm(frameType)
  return Kit.yesNo(24, 9, {frameType = frameType, initial = 1})
end

function M.draw(clock)
  if not clock.confirm then return end
  Font.sync()
  local colors = {fg = Font.STDPAL[1], bg = Font.STDPAL[15], shadow = Font.STDPAL[8]}
  Chrome.userFrame(clock.frameType, 3, 17, 24, 2)
  Font.draw(RomText.plain("gOtherText_CorrectTimePrompt"), 24, 136,
    {font = "native_3", textMode = 2, colors = colors})
  Chrome.userFrame(clock.frameType, 24, 9, 5, 4)
  -- menu.c:584
  for i = 0, 1 do
    Font.draw(RomText.at("gMenuYesNoItems", i), 192, 72 + i * 16,
      {font = "native_3", textMode = 2, colors = colors})
  end
end

function M.drawCursor(clock)
  if not clock.confirm then return end
  local y, color = Kit.fadeY(clock.pal, 16)
  Cursor.draw(192, 72 + clock.confirm.cursor * 16, 40, {y = y, color = color})
end

return M
