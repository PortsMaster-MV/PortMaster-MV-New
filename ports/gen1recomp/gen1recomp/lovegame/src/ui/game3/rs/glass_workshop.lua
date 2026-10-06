-- pokeruby/field_specials.c:1441
local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Text = require("src.core.game3.rom_text")
local Font = require("src.ui.game3.frlg_font")
local UI = {isMenu = true}
local Arrow = require("src.ui.game3.rs.scroll_arrow")
local state
local keys = {"OtherText_BlueFlute", "OtherText_YellowFlute", "OtherText_RedFlute", "OtherText_WhiteFlute",
  "OtherText_BlackFlute", "OtherText_PrettyChair", "OtherText_PrettyDesk", "gOtherText_CancelNoTerminator"}
local function finish(value)
  local s = state
  if not s then return end
  state = nil; Stack.pop("rs_glass_workshop")
  if s.done then s.done(value) end
end
function UI.show(done)
  state = {cursor = 0, scroll = 0, frame = 0, done = done, labels = {}}
  for i, key in ipairs(keys) do state.labels[i] = Text.plain(key) end
  Stack.push("rs_glass_workshop", UI, {hideBelow = false, fullscreen = false})
end
function UI.isOpen() return state ~= nil end
function UI.reset()
  state = nil
  Stack.pop("rs_glass_workshop")
end
function UI.handleInput(input)
  if not state then return end
  local s = state; s.frame = s.frame + 1
  local delta = input:wasPressed("up") and -1 or input:wasPressed("down") and 1 or 0
  local next = math.max(0, math.min(7, s.cursor + delta))
  if next ~= s.cursor then
    s.cursor = next; Kit.playSe("SE_SELECT")
    if s.cursor < s.scroll then s.scroll = s.cursor
    elseif s.cursor > s.scroll + 4 then s.scroll = s.cursor - 4 end
  end
  if input:wasPressed("a") then Kit.playSe("SE_SELECT"); finish(s.cursor)
  elseif input:wasPressed("b") then Kit.playSe("SE_SELECT"); finish(127) end
end
function UI.draw()
  if not state then return end
  local s = state
  require("src.ui.game3.chrome").stdFrame(1, 1, 9, 10)
  local opts = {font = "native_3", maxWidth = 72,
    colors = Kit.messageColors("std_menu", 2, 16, 9)}
  for row = 0, 4 do Font.draw(s.labels[s.scroll + row + 1], 8, 8 + row * 16, opts) end
  require("src.ui.game3.rs.menu_cursor").draw(8, 8 + (s.cursor - s.scroll) * 16, 72)
  if s.scroll > 0 then Arrow.draw("up", 44, 8, s.frame) end
  if s.scroll < 3 then Arrow.draw("down", 44, 88, s.frame) end
end
return UI
