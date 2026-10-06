local BootModules = {}

BootModules.COMBO_PHASE = "title_combo"

local warned = {}

local function warnOnce(key, msg)
  if warned[key] then return end
  warned[key] = true
  print("[game3/boot] " .. msg)
end

function BootModules.resolve(profile)
  local b = type(profile) == "table" and profile.boot or nil
  if type(b) ~= "table" then
    return { custom = false }
  end
  return {
    custom = true,
    intro = b.intro,
    title = b.title,
    mainMenu = b.mainMenu,
    newGame = b.newGame,
    titleCombos = b.titleCombos or {},
    params = b,
  }
end

BootModules["for"] = BootModules.resolve

function BootModules.load(name)
  assert(type(name) == "string", "boot_modules: module path required")
  return require(name)
end

function BootModules.available(name)
  if type(name) ~= "string" then return false end
  if package.loaded[name] then return true end
  return package.searchpath(name, package.path) ~= nil
    or (love and love.filesystem and love.filesystem.getInfo(name:gsub("%.", "/") .. ".lua") ~= nil) or false
end

function BootModules.newState(Boot, mods, game)
  local Machine = require("src.ui.game3.rse.gba_machine")
  return {
    phase = Boot.PHASE.INTRO,
    timer = 0,
    blink = 0,
    menuIndex = 1,
    hasContinue = false,
    custom = {
      mods = mods,
      machine = Machine.new(),
      coldBoot = true,
      game = game,
    },
  }
end

local function ctxOf(Boot, state)
  local c = state.custom
  return { machine = c.machine, params = c.mods.params, boot = Boot, state = state, game = c.game }
end

local function destroy(obj)
  if obj and obj.destroy then obj:destroy() end
end

local function drop(c)
  destroy(c.intro)
  destroy(c.title)
  destroy(c.menu)
  destroy(c.newGame)
  destroy(c.combo)
  c.intro, c.title, c.menu, c.newGame, c.combo = nil, nil, nil, nil, nil
end

function BootModules.startIntro(Boot, state)
  local c = state.custom
  drop(c)
  local M = BootModules.load(c.mods.intro)
  c.intro = M.new(c.machine, { coldBoot = c.coldBoot, params = c.mods.params.introParams })
  c.coldBoot = false
  state.phase = Boot.PHASE.INTRO
  state.timer = 0
end

function BootModules.enterTitle(Boot, state)
  local c = state.custom
  drop(c)
  local M = BootModules.load(c.mods.title)
  c.title = M.new(c.machine, {
    params = c.mods.params.titleParams,
    canResetRtc = c.mods.params.canResetRtc and function()
      return BootModules.load(c.mods.params.canResetRtc).canResetRtc(state) == true
    end or nil,
  })
  state.phase = Boot.PHASE.TITLE
  state.timer = 0
end

function BootModules.startMenu(Boot, state)
  local c = state.custom
  drop(c)
  local M = BootModules.load(c.mods.mainMenu)
  c.menu = M.new(state, ctxOf(Boot, state))
  state.phase = Boot.PHASE.MENU
  state.timer = 0
end

function BootModules.startNewGame(Boot, state)
  local c = state.custom
  drop(c)
  local M = BootModules.load(c.mods.newGame)
  c.newGame = M.new(state, ctxOf(Boot, state))
  state.phase = Boot.PHASE.OAK
  state.timer = 0
end

function BootModules.startCombo(Boot, state, name)
  local c = state.custom
  local path = c.mods.titleCombos[name]
  if not BootModules.available(path) then
    warnOnce("combo:" .. tostring(name), "title combo " .. tostring(name) .. " has no screen module; back to title")
    BootModules.enterTitle(Boot, state)
    return
  end
  drop(c)
  c.combo = BootModules.load(path).new(state, ctxOf(Boot, state))
  state.phase = BootModules.COMBO_PHASE
  state.timer = 0
end

local function route(Boot, state, r)
  if r == nil then return nil end
  if r == "title" then
    BootModules.enterTitle(Boot, state)
  elseif r == "copyright" or r == "intro" then
    BootModules.startIntro(Boot, state)
  elseif r == "menu" then
    BootModules.startMenu(Boot, state)
  elseif r == "newGame" then
    BootModules.startNewGame(Boot, state)
  elseif type(r) == "table" and r.combo then
    BootModules.startCombo(Boot, state, r.combo)
  elseif type(r) == "table" then
    return r
  end
  return nil
end

function BootModules.update(Boot, state, input, dt)
  dt = dt or (1 / 60)
  state.timer = (state.timer or 0) + dt
  state.blink = (state.blink or 0) + dt
  local c = state.custom
  if state.phase == Boot.PHASE.INTRO then
    if not c.intro then BootModules.startIntro(Boot, state) end
    return route(Boot, state, c.intro:update(input, dt))
  elseif state.phase == Boot.PHASE.TITLE or state.phase == Boot.PHASE.TITLE_CRY
      or state.phase == Boot.PHASE.TITLE_RESTART then
    if not c.title then BootModules.enterTitle(Boot, state) end
    return route(Boot, state, c.title:update(input, dt))
  elseif state.phase == Boot.PHASE.MENU then
    if not c.menu then BootModules.startMenu(Boot, state) end
    return route(Boot, state, c.menu:update(input, dt))
  elseif state.phase == BootModules.COMBO_PHASE then
    return route(Boot, state, c.combo:update(input, dt))
  elseif c.newGame then
    return route(Boot, state, c.newGame:update(input, dt))
  end
  return nil
end

function BootModules.active(state)
  local c = state.custom
  return c.intro or c.title or c.menu or c.newGame or c.combo
end

function BootModules.draw(Boot, state)
  love.graphics.clear(0, 0, 0, 1)
  local obj = BootModules.active(state)
  if obj and obj.draw then obj:draw() end
end

return BootModules
