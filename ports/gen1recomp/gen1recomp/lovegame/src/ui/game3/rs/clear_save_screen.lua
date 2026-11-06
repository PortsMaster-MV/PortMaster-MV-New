local Kit = require("src.ui.game3.rse.scene_kit")
local Chrome = require("src.ui.game3.chrome")
local Font = require("src.ui.game3.frlg_font")
local Text = require("src.core.game3.rom_text")
local Pal = require("src.core.game3.pal_fade")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local Screen = {}; Screen.__index = Screen
function Screen.new(opts)
  if Kit.isBootState(opts) then opts = {} end
  opts = opts or {}
  return setmetatable({ pal = Pal.new(), step = Kit.stepper(), state = "setup", cursor = 1,
    clear = opts.clearSave or function()
      local Save = require("src.core.SaveData"); local version = require("src.core.GameVersion").get()
      local cart = Save.getCart()
      if cart then return Save.deleteCartSlot(cart, Save.activeCartSlot(cart)) end
      return Save.deleteSlot(version, Save.activeSlot(version))
    end }, Screen)
end
function Screen:frame(inp)
  if self.state == "setup" then
    self.pal:blend(Pal.ALL, 16, Pal.WHITE); self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.WHITE); self.state = "fade_in"
  elseif self.state == "fade_in" then
    if not self.pal:fadeActive() then self.menuShown = true; self.state = "ask" end
  elseif self.state == "ask" then
    if inp.new.up then self.cursor = 0; Kit.playSe("SE_SELECT")
    elseif inp.new.down then self.cursor = 1; Kit.playSe("SE_SELECT") end
    if inp.new.b or (inp.new.a and self.cursor == 1) then self.state = "reset"; Kit.playSe("SE_SELECT")
    elseif inp.new.a then self.clearing = true; self.state = "clearing"; Kit.playSe("SE_SELECT") end
  elseif self.state == "clearing" then
    self.clear(); self.state = "reset"
  elseif self.state == "reset" then self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.WHITE); self.state = "exit"
  elseif self.state == "exit" and not self.pal:fadeActive() then return "intro" end
  self.pal:updateFade()
end
function Screen:update(input, dt) self.step:collect(input); return self.step:run(dt, function(i) return self:frame(i) end) end
function Screen:draw()
  -- clear_save_data_menu.c:124
  love.graphics.clear(Kit.rgb555(0x3945))
  local colors = Kit.messageColors("std_menu")
  if self.state ~= "setup" and self.state ~= "fade_in" then
    Chrome.stdFrame(3, 15, self.clearing and 25 or 24, 4)
    Font.draw(Text.plain(self.clearing and "gSystemText_ClearingData" or "gSystemText_ClearAllSaveDataPrompt"), 24, 120,
      { colors = colors, font = "native_3", textMode = 2 })
    if self.menuShown then
      Chrome.stdFrame(3, 2, 5, 4)
      Font.draw(Text.plain("OtherText_Yes"), 24, 16, { colors = colors, font = "native_3", textMode = 2 })
      Font.draw(Text.plain("OtherText_No"), 24, 32, { colors = colors, font = "native_3", textMode = 2 })
      Cursor.draw(24, 16 + self.cursor * 16, 40)
    end
  end
  Kit.drawFade(self.pal, 0)
end
return Screen
