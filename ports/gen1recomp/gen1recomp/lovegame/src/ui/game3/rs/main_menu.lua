local bit = require("bit")
local Kit = require("src.ui.game3.rse.scene_kit")
local Rtc = require("src.core.game3.rtc")
local RomText = require("src.core.game3.rom_text")
local Font = require("src.ui.game3.frlg_font")
local Constants = require("src.core.game3.constants")
local Flags = require("src.core.game3.scripting.flags")
local Chrome = require("src.ui.game3.chrome")
local Pal = require("src.core.game3.pal_fade")
local Menu = {}
Menu.__index = Menu

-- pokeruby/src/main_menu.c:45
Menu.TYPE = { HAS_NO_SAVED_GAME = 0, HAS_SAVED_GAME = 1, HAS_MYSTERY_EVENT = 2 }
local T = Menu.TYPE
local LABEL = { CONTINUE = "gMainMenuString_Continue", NEW_GAME = "gMainMenuString_NewGame",
  OPTION = "gMainMenuString_Option", MYSTERY_EVENTS = "gMainMenuString_MysteryEvents", EXIT = "SystemText_Exit" }
local SCROLL_PX = 32
function Menu.items(kind)
  local rows
  if kind == T.HAS_MYSTERY_EVENT then rows = { "CONTINUE", "NEW_GAME", "MYSTERY_EVENTS", "OPTION" }
  elseif kind == T.HAS_SAVED_GAME then rows = { "CONTINUE", "NEW_GAME", "OPTION" }
  else rows = { "NEW_GAME", "OPTION" } end
  rows[#rows + 1] = "EXIT"
  return rows
end
function Menu.menuType(hasContinue, info, status)
  if not hasContinue or status == "invalid" or status == "empty" or status == "no_flash" then return T.HAS_NO_SAVED_GAME end
  return info and info.mysteryEvents and T.HAS_MYSTERY_EVENT or T.HAS_SAVED_GAME
end
function Menu.windowFor(kind, index)
  if kind == T.HAS_NO_SAVED_GAME then return { left = 2, top = 1 + (index - 1) * 4, width = 26, height = 2 } end
  return { left = 2, top = index == 1 and 1 or 9 + (index - 2) * 4, width = 26, height = index == 1 and 6 or 2 }
end
local function store(save)
  local s = type(save.store) == "table" and save.store or {}
  return { flags = save.flags or s.flags or {}, vars = save.vars or s.vars or {} }
end
local function flag(C, s, name) return Flags.getFlag(s, nil, C:require("flags", name)) == true end
-- pokeruby/src/event_data.c:69
function Menu.continueInfoFromSave(save, version)
  if type(save) ~= "table" then return nil end
  local C, s = Constants.of(version or save.version or "ruby"), store(save)
  local dex = save.dex or save.pokedex or {}
  local national = tonumber(dex.nationalMagic) == 0xDA
    and Flags.getVar(s, nil, C:require("vars", "VAR_NATIONAL_DEX")) == 0x302
    and flag(C, s, "FLAG_SYS_NATIONAL_DEX")
  local caught, count = dex.caught or dex.owned or {}, 0
  local hoenn = Kit.loadLua("data/generated/gba/pokemon/hoenn.lua")
  for species, on in pairs(caught) do
    local sp = tonumber(species)
    local h = hoenn and hoenn.toHoenn and hoenn.toHoenn[sp]
    if sp and on and on ~= 0 and (national or (h and h >= 1 and h <= 202)) then count = count + 1 end
  end
  local badges, first = 0, C:require("flags", "FLAG_BADGE01_GET")
  for i = 0, 7 do if Flags.getFlag(s, nil, first + i) then badges = badges + 1 end end
  local pt = save.playTime or save.playtime or {}
  local options = save.options and require("src.core.game3.options").block(save.options) or {}
  return { name = tostring(save.name or save.playerName or ""), gender = tonumber(save.gender) or 0,
    hours = tonumber(pt.hours) or 0, minutes = tonumber(pt.minutes) or 0, badges = badges, dexCount = count,
    mysteryEvents = flag(C, s, "FLAG_SYS_EXDATA_ENABLE"), frameType = options.frameType or 0 }
end
function Menu.new(opts, ctx)
  if Kit.isBootState(opts) then
    local state, raw = opts, opts.hasContinue and Kit.loadRawSave() or nil
    opts = { hasContinue = state.hasContinue, continueInfo = raw and Menu.continueInfoFromSave(raw, require("src.core.GameVersion").get()),
      saveStatus = state.saveStatus, textSpeed = state.textSpeed, game = ctx and ctx.game, bootState = state,
      returningFromOptions = state.custom and state.custom.returningFromOptions }
  end
  opts = opts or {}
  local self = setmetatable({ info = opts.continueInfo, game = opts.game, bootState = opts.bootState,
    textSpeed = tonumber(opts.textSpeed) or 1, saveStatus = opts.saveStatus or "ok", pal = Pal.new(),
    step = Kit.stepper(), state = "check_save", cursor = 1, scroll = 0, blink = 0,
    manifest = assert(Kit.manifest("birch"), "RS menu palette missing"),
    frameType = opts.continueInfo and opts.continueInfo.frameType or 0 }, Menu)
  self.menuType = opts.menuType or Menu.menuType(opts.hasContinue, self.info, self.saveStatus)
  self.items = Menu.items(self.menuType)
  self.pal:beginFade(Pal.ALL, 0, 16, 0, opts.returningFromOptions and Pal.BLACK or Pal.WHITE)
  return self
end
function Menu:_fixScroll()
  local w = Menu.windowFor(self.menuType, self.cursor)
  local bottom, topPx = (w.top + w.height + 1) * 8, (w.top - 1) * 8
  while bottom - self.scroll > 160 do self.scroll = self.scroll + SCROLL_PX end
  while topPx - self.scroll < 0 and self.scroll > 0 do self.scroll = self.scroll - SCROLL_PX end
end
function Menu:_message(key)
  self.printer = Kit.printer(key, { speed = 2, canSpeedUp = false, textSpeedOption = self.textSpeed })
end
function Menu:_openOptions()
  local Options = require("src.ui.game3.screens").get("option")
  Options.show({ game = self.game, session = nil })
  self.options, self.state = Options, "options"
end
function Menu:frame(inp)
  local state, result = self.state
  self.blink = self.blink + 1
  if state == "check_save" and not self.pal:fadeActive() then
    local key = self.saveStatus == "invalid" and "gSaveFileDeletedMessage"
      or self.saveStatus == "error" and "gSaveFileCorruptMessage"
      or self.saveStatus == "no_flash" and "gBoardNotInstalledMessage"
    if key then self:_message(key); self.state = "save_error" else self.state = "check_rtc" end
  elseif state == "save_error" or state == "rtc_error" then
    self.printer:run(inp)
    if not self.printer:isActive() and inp.new.a then
      self.printer = nil
      self.state = state == "save_error" and "check_rtc" or "draw_menu"
    end
  elseif state == "check_rtc" and not self.pal:fadeActive() then
    if bit.band(Rtc.errorStatus(), Rtc.ERR.FLAG_MASK) ~= 0 then
      self:_message("gBatteryDryMessage"); self.state = "rtc_error"
    else self.state = "draw_menu" end
  elseif state == "draw_menu" then
    self.state = "highlight"
  elseif state == "highlight" then
    self.state = "input"
  elseif state == "input" then
    if inp.new.a then
      Kit.playSe("SE_SELECT"); self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK); self.state = "pressed_a"
    elseif inp.new.b then
      Kit.playSe("SE_SELECT"); self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.WHITE); self.state = "pressed_b"
    elseif inp.new.up and self.cursor > 1 then self.cursor = self.cursor - 1; self:_fixScroll(); self.state = "highlight"
    elseif inp.new.down and self.cursor < #self.items then self.cursor = self.cursor + 1; self:_fixScroll(); self.state = "highlight" end
  elseif state == "pressed_a" and not self.pal:fadeActive() then
    local item = self.items[self.cursor]
    if item == "CONTINUE" then result = { action = "continue" }
    elseif item == "NEW_GAME" then result = "newGame"
    elseif item == "OPTION" then self:_openOptions()
    elseif item == "EXIT" then result = { action = "exit" }
    elseif item == "MYSTERY_EVENTS" then
      require("src.core.game3.audio").fadeOutBgm(0)
      self.printer = nil
      self.events = require("src.ui.game3.rs.mystery_events").new({game=self.game})
      self.state = "events"
    end
  elseif state == "pressed_b" and not self.pal:fadeActive() then result = "title"
  elseif state == "options" and not self.options.isOpen() then
    local opts = self.game and self.game.options
    if opts then self.textSpeed = require("src.core.game3.options").block(opts).textSpeed end
    if self.bootState then self.bootState.textSpeed = self.textSpeed end
    self.options, self.cursor, self.scroll, self.state, self.saveStatus = nil, 1, 0, "check_save", "ok"
    self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  end
  self.pal:updateFade()
  return result
end
function Menu:update(input, dt)
  if self.state == "events" and self.events then return self.events:update(input,dt) end
  if self.state == "options" and self.options then
    self.options.handleInput(input)
    if self.options.update then self.options.update() end
  end
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end
function Menu:colors()
  local normal = Kit.messageColors()
  local gender = self.info and self.info.gender == 1 and (31 + 3 * 32 + 21 * 1024) or (4 + 16 * 32 + 31 * 1024)
  return { headers = { bg = normal.bg, fg = Kit.color555(0), shadow = normal.shadow },
    info = { bg = normal.bg, fg = Kit.color555(gender), shadow = normal.shadow }, fill = normal.bg,
    backdrop = Kit.color555(self.manifest.mainMenuPalette[1]) }
end
function Menu:_drawContinue(c, dy)
  local i = self.info or {}
  local y1, y2 = 24 - dy, 40 - dy
  Font.draw(RomText.plain("gMainMenuString_Player"), 16, y1, { colors = c.info })
  Font.draw(i.name or "", 72, y1, { colors = c.info })
  Font.draw(RomText.plain("gMainMenuString_Time"), 128, y1, { colors = c.info })
  local time = string.format("%d:%02d", i.hours or 0, i.minutes or 0)
  Font.draw(time, 224 - Font.measure(time), y1, { colors = c.info })
  Font.draw(RomText.plain("gMainMenuString_Pokedex"), 16, y2, { colors = c.info })
  Font.draw(tostring(i.dexCount or 0), 72, y2, { colors = c.info })
  Font.draw(RomText.plain("gMainMenuString_Badges"), 128, y2, { colors = c.info })
  Font.draw(tostring(i.badges or 0), 205, y2, { colors = c.info })
end
local canvas
local function composite(img, rect)
  local W, H = 240, 160
  local function part(x, y, w, h, shade)
    if w <= 0 or h <= 0 then return end
    love.graphics.setColor(shade, shade, shade, 1)
    love.graphics.draw(img, love.graphics.newQuad(x, y, w, h, W, H), x, y)
  end
  local x, y, right, bottom = rect[1], rect[2], rect[3], rect[4]
  part(0, 0, W, y, 9 / 16); part(0, bottom, W, H - bottom, 9 / 16)
  part(0, y, x, bottom - y, 9 / 16); part(right, y, W - right, bottom - y, 9 / 16)
  part(x, y, right - x, bottom - y, 1)
  love.graphics.setColor(1, 1, 1, 1)
end
function Menu:draw()
  if self.state == "events" and self.events then return self.events:draw() end
  if self.state == "options" and self.options then return self.options.draw() end
  local c = self:colors()
  local shade = self.state == "pressed_b" and 1 or 9 / 16
  love.graphics.clear(c.backdrop[1] * shade, c.backdrop[2] * shade, c.backdrop[3] * shade, 1)
  local event = self.state:sub(1, 6) == "event_"
  local error = self.state == "save_error" or self.state == "rtc_error"
  local showMenu = self.state == "highlight" or self.state == "input" or self.state == "pressed_a" or self.state == "pressed_b" or self.state == "options"
  if showMenu then
    canvas = canvas or love.graphics.newCanvas(240, 160)
    canvas:setFilter("nearest", "nearest")
    love.graphics.push("all"); love.graphics.setCanvas(canvas); love.graphics.origin(); love.graphics.clear(0, 0, 0, 0)
    local dy = self.scroll or 0
    for index, item in ipairs(self.items) do
      local w = Menu.windowFor(self.menuType, index)
      Chrome.stdFrame(w.left, w.top - dy / 8, w.width, w.height)
      Font.draw(RomText.plain(LABEL[item]), w.left * 8, w.top * 8 - dy, { colors = c.headers })
      if item == "CONTINUE" then self:_drawContinue(c, dy) end
    end
    love.graphics.pop()
    local w = Menu.windowFor(self.menuType, self.cursor)
    local rect = { 9, (w.top - 1) * 8 + 1 - dy, 231, (w.top + w.height + 1) * 8 - 1 - dy }
    if self.state == "pressed_b" then rect = { 0, 0, 240, 160 } end
    composite(canvas, rect)
    local last = Menu.windowFor(self.menuType, #self.items)
    local Arrow = require("src.ui.game3.rs.scroll_arrow")
    if (last.top + last.height + 1) * 8 - dy > 160 then Arrow.draw("down", 0x78, 0x98, self.blink) end
    if dy > 0 then Arrow.draw("up", 0x78, 8, self.blink) end
  end
  if error then
    Chrome.stdFrame(3, 15, 24, 4)
    self.printer:draw(24, 120, { colors = Kit.messageColors() })
  elseif event then
    love.graphics.clear(0, 0, 0, 1)
    Chrome.stdFrame(1, 15, 28, 4)
    if self.printer then self.printer:draw(8, 120, { colors = Kit.messageColors() }) end
  end
  if self.state == "options" and self.options then self.options.draw() end
  Kit.drawFade(self.pal, 0)
end
function Menu:destroy()
  if self.events then self.events:destroy();self.events=nil end
end
return Menu
