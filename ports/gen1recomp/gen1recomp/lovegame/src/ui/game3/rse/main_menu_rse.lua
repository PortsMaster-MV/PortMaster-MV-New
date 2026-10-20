local bit = require("bit")
local Kit = require("src.ui.game3.rse.scene_kit")
local Rtc = require("src.core.game3.rtc")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local Constants = require("src.core.game3.constants")
local Pal = require("src.core.game3.pal_fade")

local MainMenu = {}
MainMenu.__index = MainMenu

-- pokeemerald/src/main_menu.c:512
MainMenu.TYPE = {
  HAS_NO_SAVED_GAME = 0,
  HAS_SAVED_GAME = 1,
  HAS_MYSTERY_GIFT = 2,
  HAS_MYSTERY_EVENTS = 3,
}
local T = MainMenu.TYPE

-- pokeemerald/src/main_menu.c:259
local MENU_LEFT, MENU_WIDTH = 2, 26
local TOPS = { [0] = 1, 5, 1, 9, 13, 17, 21 }
local HEIGHTS = { [0] = 2, 2, 6, 2, 2, 2, 2 }
local ERROR_WIN = { left = 2, top = 15, width = 26, height = 4 }
local SCROLL_PX = 32

local LABELS = {
  NEW_GAME = "gText_MainMenuNewGame",
  CONTINUE = "gText_MainMenuContinue",
  OPTION = "gText_MainMenuOption",
  MYSTERY_GIFT = "gText_MainMenuMysteryGift",
  MYSTERY_GIFT2 = "gText_MainMenuMysteryGift2",
  MYSTERY_EVENTS = "gText_MainMenuMysteryEvents",
  EXIT = "gText_MenuExit",
}

-- pokeemerald/src/main_menu.c:936
function MainMenu.items(menuType)
  local rows
  if menuType == T.HAS_SAVED_GAME then
    rows = { "CONTINUE", "NEW_GAME", "OPTION" }
  elseif menuType == T.HAS_MYSTERY_GIFT then
    rows = { "CONTINUE", "NEW_GAME", "MYSTERY_GIFT", "OPTION" }
  elseif menuType == T.HAS_MYSTERY_EVENTS then
    rows = { "CONTINUE", "NEW_GAME", "MYSTERY_GIFT2", "MYSTERY_EVENTS", "OPTION" }
  else
    rows = { "NEW_GAME", "OPTION" }
  end
  rows[#rows + 1] = "EXIT"
  return rows
end

local function windowFor(menuType, index)
  if menuType == T.HAS_NO_SAVED_GAME then
    local w = index - 1
    return { left = MENU_LEFT, top = w <= 1 and TOPS[w] or (TOPS[1] + 4 * (w - 1)), width = MENU_WIDTH, height = 2 }
  end
  local w = index + 1
  local top = TOPS[w] or (TOPS[6] + 4 * (w - 6))
  return { left = MENU_LEFT, top = top, width = MENU_WIDTH, height = HEIGHTS[w] or 2 }
end
MainMenu.windowFor = windowFor

local function store(save)
  save = type(save) == "table" and save or {}
  return {
    flags = type(save.flags) == "table" and save.flags or (type(save.store) == "table" and save.store.flags) or {},
    vars = type(save.vars) == "table" and save.vars or (type(save.store) == "table" and save.store.vars) or {},
  }
end

local function flagOn(C, st, name)
  local id = C:require("flags", name)
  return require("src.core.game3.scripting.flags").getFlag(st, nil, id) == true
end

-- pokeemerald/src/event_data.c:74
local function nationalEnabled(C, st, save)
  local Flags = require("src.core.game3.scripting.flags")
  local dex = type(save.dex) == "table" and save.dex or type(save.pokedex) == "table" and save.pokedex or {}
  local magicOk = dex.nationalMagic == nil or tonumber(dex.nationalMagic) == 0xDA
  return magicOk and Flags.getVar(st, nil, C:require("vars", "VAR_NATIONAL_DEX")) == 0x302
    and flagOn(C, st, "FLAG_SYS_NATIONAL_DEX")
end

-- pokeemerald/src/main_menu.c:2155
local function dexCount(C, st, save)
  local dex = type(save.dex) == "table" and save.dex or type(save.pokedex) == "table" and save.pokedex or {}
  local caught = type(dex.caught) == "table" and dex.caught or type(dex.owned) == "table" and dex.owned or {}
  local national = nationalEnabled(C, st, save)
  local hoenn = Kit.loadLua("data/generated/gba/pokemon/hoenn.lua")
  local regional = Kit.loadLua("data/generated/gba/pokemon/regional_dex.lua")
  local hoennMax = regional and tonumber(regional.count) or 0
  local n, seen = 0, {}
  for sp, on in pairs(caught) do
    local id = tonumber(sp)
    if id and on and on ~= 0 and not seen[id] then
      seen[id] = true
      if national then
        n = n + 1
      else
        local h = hoenn and hoenn.toHoenn and hoenn.toHoenn[id]
        if h and h >= 1 and h <= hoennMax then n = n + 1 end
      end
    end
  end
  return n
end

function MainMenu.continueInfoFromSave(save, version)
  if type(save) ~= "table" then return nil end
  local C = Constants.of(version or save.version or "emerald")
  local st = store(save)
  local Flags = require("src.core.game3.scripting.flags")
  local pt = type(save.playTime) == "table" and save.playTime
    or type(save.playtime) == "table" and save.playtime or {}
  local badges = 0
  local first = C:require("flags", "FLAG_BADGE01_GET")
  for i = 0, C:require("flags", "NUM_BADGES") - 1 do
    if Flags.getFlag(st, nil, first + i) then badges = badges + 1 end
  end
  local frameType = 0
  if type(save.options) == "table" then
    local ok, block = pcall(function() return require("src.core.game3.options").block(save.options) end)
    frameType = ok and type(block) == "table" and tonumber(block.frameType) or 0
  end
  return {
    name = tostring(save.name or save.playerName or ""),
    gender = tonumber(save.gender) or 0,
    hours = tonumber(pt.hours) or 0,
    minutes = tonumber(pt.minutes) or 0,
    hasDex = flagOn(C, st, "FLAG_SYS_POKEDEX_GET"),
    dexCount = dexCount(C, st, save),
    badges = badges,
    mysteryGift = flagOn(C, st, "FLAG_SYS_MYSTERY_GIFT_ENABLE"),
    mysteryEvents = flagOn(C, st, "FLAG_SYS_MYSTERY_EVENT_ENABLE"),
    frameType = frameType,
  }
end

-- pokeemerald/src/main_menu.c:643
function MainMenu.menuType(hasContinue, info, saveStatus)
  if saveStatus == "invalid" then return T.HAS_NO_SAVED_GAME end
  if not hasContinue then return T.HAS_NO_SAVED_GAME end
  local t = T.HAS_SAVED_GAME
  if info and info.mysteryGift then t = t + 1 end
  return t
end

function MainMenu.new(opts, ctx)
  if Kit.isBootState(opts) then
    local state = opts
    local raw = state.hasContinue and Kit.loadRawSave() or nil
    local GameVersion = require("src.core.GameVersion")
    opts = {
      hasContinue = state.hasContinue,
      continueInfo = raw and MainMenu.continueInfoFromSave(raw, GameVersion.get()) or nil,
      saveStatus = state.saveStatus,
      textSpeed = state.textSpeed,
      returningFromOptions = state.custom and state.custom.returningFromOptions,
      game = ctx and ctx.game,
      bootState = state,
    }
  end
  opts = opts or {}
  local info = opts.continueInfo
  local self = setmetatable({
    hasContinue = opts.hasContinue and true or false,
    info = info,
    saveStatus = opts.saveStatus or "ok",
    game = opts.game,
    bootState = opts.bootState,
    textSpeed = tonumber(opts.textSpeed) or 1,
    pal = Pal.new(),
    step = Kit.stepper(),
    state = "check_save",
    cursor = 1,
    scroll = 0,
    blink = 0,
    frameType = (info and info.frameType) or tonumber(opts.frameType) or 0,
    title = Kit.manifest("title"),
  }, MainMenu)
  self.menuType = opts.menuType or MainMenu.menuType(self.hasContinue, info, self.saveStatus)
  self.items = MainMenu.items(self.menuType)
  if opts.returningFromOptions then
    local optIdx
    for i, id in ipairs(self.items) do if id == "OPTION" then optIdx = i end end
    self.cursor = optIdx or 1
  end
  self:_fixScroll()
  -- pokeemerald/src/main_menu.c:583
  local fromColor = opts.returningFromOptions and Pal.BLACK or Pal.WHITE
  self.pal:beginFade(Pal.ALL, 0, 16, 0, fromColor)
  return self
end

function MainMenu:_fixScroll()
  local w = windowFor(self.menuType, self.cursor)
  local bottom = (w.top + w.height + 1) * 8
  local topPx = (w.top - 1) * 8
  while bottom - self.scroll > 160 do self.scroll = self.scroll + SCROLL_PX end
  while topPx - self.scroll < 0 and self.scroll > 0 do self.scroll = self.scroll - SCROLL_PX end
end

local function errorPrinter(self, key)
  -- pokeemerald/src/main_menu.c:2116
  self.errorKey = key
  self.errorPrinter = Kit.printer(key, { speed = 2, canSpeedUp = false, textSpeedOption = self.textSpeed })
end

function MainMenu:_selected()
  return self.items[self.cursor]
end

function MainMenu:frame(inp)
  local st = self.state
  self.blink = self.blink + 1
  local result
  if st == "check_save" then
    -- pokeemerald/src/main_menu.c:625
    if not self.pal:fadeActive() then
      if self.saveStatus == "invalid" then
        errorPrinter(self, "gText_SaveFileErased")
        self.state = "save_error"
      elseif self.saveStatus == "error" then
        errorPrinter(self, "gText_SaveFileCorrupted")
        self.state = "save_error"
      else
        self.state = "check_battery"
      end
    end
  elseif st == "save_error" or st == "battery_error" then
    -- pokeemerald/src/main_menu.c:694
    self.errorPrinter:run(inp)
    if not self.errorPrinter:isActive() and inp.new.a then
      self.errorPrinter = nil
      self.state = st == "save_error" and "check_battery" or "input"
    end
  elseif st == "check_battery" then
    -- pokeemerald/src/main_menu.c:705
    if not self.pal:fadeActive() then
      if bit.band(Rtc.errorStatus(), Rtc.ERR.FLAG_MASK) == 0 then
        self.state = "input"
      else
        errorPrinter(self, "gText_BatteryRunDry")
        self.state = "battery_error"
      end
    end
  elseif st == "input" then
    -- pokeemerald/src/main_menu.c:884
    if inp.new.a then
      Kit.playSe("SE_SELECT")
      self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
      self.state = "a_pressed"
    elseif inp.new.b then
      Kit.playSe("SE_SELECT")
      self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.WHITE)
      self.state = "b_pressed"
    elseif inp.new.up and self.cursor > 1 then
      self.cursor = self.cursor - 1
      self:_fixScroll()
    elseif inp.new.down and self.cursor < #self.items then
      self.cursor = self.cursor + 1
      self:_fixScroll()
    end
  elseif st == "a_pressed" then
    -- pokeemerald/src/main_menu.c:936
    if not self.pal:fadeActive() then
      local sel = self:_selected()
      if sel == "NEW_GAME" then
        result = "newGame"
      elseif sel == "CONTINUE" then
        result = { action = "continue" }
      elseif sel == "OPTION" then
        result = self:_openOptions()
      elseif sel == "EXIT" then
        result = { action = "exit" }
      elseif sel == "MYSTERY_GIFT" or sel == "MYSTERY_GIFT2" then
        -- pokeemerald/src/main_menu.c:1075
        self:_openMysteryGift()
      elseif sel == "MYSTERY_EVENTS" then
        -- pokeemerald/src/main_menu.c:1040
        self.cursor, self.scroll = 1, 0
        self.invalidKey = "gText_MysteryEventsCantUse"
        errorPrinter(self, self.invalidKey)
        self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
        self.state = "invalid_action"
      else
        -- pokeemerald/src/main_menu.c:1122
        self.cursor, self.scroll = 1, 0
        self.invalidKey = "gText_WirelessNotConnected"
        errorPrinter(self, self.invalidKey)
        self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
        self.state = "invalid_action"
      end
    end
  elseif st == "invalid_action" then
    if not self.pal:fadeActive() then
      self.errorPrinter:run(inp)
      if not self.errorPrinter:isActive() and (inp.new.a or inp.new.b) then
        Kit.playSe("SE_SELECT")
        self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
        self.state = "b_pressed"
      end
    end
  elseif st == "b_pressed" then
    -- pokeemerald/src/main_menu.c:1109
    if not self.pal:fadeActive() then result = "title" end
  elseif st == "options" then
    if not (self.optionMenu and self.optionMenu.isOpen()) then
      self.state = "check_save"
      self.optionMenu = nil
      self:_syncTextSpeed()
      self.saveStatus = "ok"
      self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
    end
  end
  self.pal:updateFade()
  return result
end

function MainMenu:destroy()
  if self.gift then self:_closeMysteryGift() end
end

function MainMenu:_syncTextSpeed()
  local opts = self.game and self.game.options
  if type(opts) ~= "table" then return end
  local speed = tonumber(require("src.core.game3.options").block(opts).textSpeed)
  if not speed then return end
  self.textSpeed = speed
  if type(self.bootState) == "table" then self.bootState.textSpeed = speed end
end

function MainMenu:_openOptions()
  -- pokeemerald/src/main_menu.c:1070
  local ok, OptionMenu = pcall(function() return require("src.ui.game3.screens").get("option") end)
  if not (ok and OptionMenu and OptionMenu.show) then return { action = "option" } end
  local okShow = pcall(OptionMenu.show, { game = self.game, session = nil })
  if not okShow then return { action = "option" } end
  self.optionMenu = OptionMenu
  self.pal = Pal.new()
  self.state = "options"
  return nil
end

-- pokeemerald/src/mystery_gift_menu.c:453 CB2_InitMysteryGift
function MainMenu:_openMysteryGift()
  local MysteryGift = require("src.core.game3.mystery_gift")
  local MysteryGiftUi = require("src.ui.game3.mystery_gift")
  local SaveData = require("src.core.SaveData")
  local okLoad, raw = false, nil
  if SaveData.load then okLoad, raw = pcall(SaveData.load) end
  local loaded = okLoad and type(raw) == "table"
  local save = loaded and raw or {}
  local session = MysteryGift.sessionFromSave(save)
  self.giftSave = save
  self.gift = MysteryGiftUi.new({
    session = session,
    fetch = { session = session },
    onSave = function(sess)
      if not loaded then return false end
      MysteryGift.applyToSave(sess, save)
      if not SaveData.save then return false end
      local okSave, written = pcall(SaveData.save, save)
      return okSave and written ~= false
    end,
  })
  self.state = "mystery_gift"
end

-- pokeemerald/src/mystery_gift_menu.c:474 MainCB_FreeAllBuffersAndReturnToInitTitleScreen
function MainMenu:_closeMysteryGift()
  if self.gift then require("src.ui.game3.mystery_gift").close(self.gift) end
  self.gift, self.giftSave = nil, nil
  self.state = "closed"
end

function MainMenu:update(input, dt)
  if self.state == "mystery_gift" and self.gift then
    local MysteryGiftUi = require("src.ui.game3.mystery_gift")
    local pressed = function(k) return input and input.wasPressed and input:wasPressed(k) end
    if MysteryGiftUi.update(self.gift, pressed, dt) == "exit" then
      self:_closeMysteryGift()
      return "title"
    end
    return nil
  end
  if self.state == "options" and self.optionMenu then
    self.optionMenu.handleInput(input)
    if self.optionMenu.update then self.optionMenu.update() end
  end
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end

function MainMenu:colors()
  local p = self.title and self.title.palettes
  local text = p and p.mainMenuText or {}
  local genderColor = (self.info and self.info.gender == 1) and Kit.color555(31 + 3 * 32 + 21 * 1024)
    or Kit.color555(4 + 16 * 32 + 31 * 1024)
  -- pokeemerald/src/main_menu.c:755
  local white = Kit.color555(0x7FFF)
  local gray = Kit.color555(12 + 12 * 32 + 12 * 1024)
  local light = Kit.color555(26 + 26 * 32 + 25 * 1024)
  return {
    headers = { bg = white, fg = gray, shadow = light },
    info = { bg = white, fg = genderColor, shadow = light },
    fill = white,
    error = { bg = Kit.color555(text[2] or 0x7FFF), fg = Kit.color555(text[3] or 0), shadow = Kit.color555(text[4] or 0) },
  }
end

local function drawWindow(w, frameType, fill, dy)
  Kit.userFrame(w.left, w.top - dy / 8, w.width, w.height, frameType, fill)
end

local layerCanvas

-- pokeemerald/src/main_menu.c:635
local function compositeDarkened(canvas, win)
  local W, H = canvas:getDimensions()
  local function part(x0, y0, x1, y1, shade)
    if x1 <= x0 or y1 <= y0 then return end
    love.graphics.setColor(shade, shade, shade, 1)
    love.graphics.draw(canvas, love.graphics.newQuad(x0, y0, x1 - x0, y1 - y0, W, H), x0, y0)
  end
  local dark = 9 / 16
  if not win then
    part(0, 0, W, H, dark)
  else
    local wx0, wy0, wx1, wy1 = math.max(0, win[1]), math.max(0, win[2]), math.min(W, win[3]), math.min(H, win[4])
    part(0, 0, W, wy0, dark)
    part(0, wy1, W, H, dark)
    part(0, wy0, wx0, wy1, dark)
    part(wx1, wy0, W, wy1, dark)
    part(wx0, wy0, wx1, wy1, 1)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function MainMenu:draw()
  if self.state == "mystery_gift" and self.gift then
    require("src.ui.game3.mystery_gift").draw(self.gift)
    return
  end
  local p = self.title and self.title.palettes
  local bgPal = p and p.mainMenuBg
  local bd = Kit.color555(bgPal and bgPal[1] or 0)
  love.graphics.clear(bd[1], bd[2], bd[3], 1)
  local c = self:colors()
  local dy = self.scroll
  local selWin
  for i = 1, #self.items do
    local w = windowFor(self.menuType, i)
    if i == self.cursor then
      -- pokeemerald/src/main_menu.c:283
      selWin = { (w.left - 1) * 8 + 1, (w.top - 1) * 8 - dy + 1, (w.left + w.width + 1) * 8 - 1, (w.top + w.height + 1) * 8 - dy - 1 }
    end
  end
  local darken = self.state == "input" or self.state == "a_pressed" or self.state == "b_pressed"
  local canvas
  if darken and love.graphics.newCanvas then
    layerCanvas = layerCanvas or love.graphics.newCanvas(240, 160)
    layerCanvas:setFilter("nearest", "nearest")
    canvas = layerCanvas
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
  end
  for i, id in ipairs(self.items) do
    local w = windowFor(self.menuType, i)
    drawWindow(w, self.frameType, c.fill, dy)
    local x, y = w.left * 8, w.top * 8 - dy
    FrlgFont.draw(RomText.plain(LABELS[id]), x, y + 1, { colors = c.headers })
    if id == "CONTINUE" then self:_drawContinue(x, y, c) end
  end
  if canvas then
    love.graphics.pop()
    compositeDarkened(canvas, selWin)
  end
  local lastW = windowFor(self.menuType, #self.items)
  if (lastW.top + lastW.height + 1) * 8 - dy > 160 then
    Kit.scrollArrow("down", 0x78, 0x98, self.blink)
  end
  if dy > 0 then Kit.scrollArrow("up", 0x78, 8, self.blink) end
  if self.errorPrinter then
    local e = ERROR_WIN
    if self.state == "invalid_action" then
      love.graphics.clear(bd[1], bd[2], bd[3], 1)
    end
    Kit.userFrame(e.left, e.top, e.width, e.height, self.frameType, c.fill)
    self.errorPrinter:draw(e.left * 8, e.top * 8 + 1, { colors = c.error })
  end
  if self.state == "options" and self.optionMenu then
    self.optionMenu.draw()
  end
  Kit.drawFade(self.pal, 0)
end

-- pokeemerald/src/main_menu.c:2135
function MainMenu:_drawContinue(x, y, c)
  local info = self.info or {}
  local function right(text, edge, yy)
    FrlgFont.draw(text, x + edge - FrlgFont.measure(text), y + yy, { colors = c.info })
  end
  FrlgFont.draw(RomText.plain("gText_ContinueMenuPlayer"), x, y + 17, { colors = c.info })
  right(info.name or "", 100, 17)
  FrlgFont.draw(RomText.plain("gText_ContinueMenuTime"), x + 0x6C, y + 17, { colors = c.info })
  right(string.format("%d:%02d", info.hours or 0, info.minutes or 0), 0xD0, 17)
  if info.hasDex then
    FrlgFont.draw(RomText.plain("gText_ContinueMenuPokedex"), x, y + 33, { colors = c.info })
    right(tostring(info.dexCount or 0), 100, 33)
  end
  FrlgFont.draw(RomText.plain("gText_ContinueMenuBadges"), x + 0x6C, y + 33, { colors = c.info })
  right(tostring(info.badges or 0), 0xD0, 33)
end

return MainMenu
