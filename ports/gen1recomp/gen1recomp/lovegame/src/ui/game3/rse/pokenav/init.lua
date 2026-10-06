local Kit = require("src.ui.game3.rse.scene_kit")
local Pal = require("src.core.game3.pal_fade")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")

local Pokenav = {}

Pokenav.ID = "rse_pokenav"

-- pokeemerald/include/pokenav.h:119
Pokenav.MENU = {
  MAIN_MENU = "main_menu",
  MAIN_MENU_CURSOR_ON_MAP = "main_menu_cursor_on_map",
  CONDITION_MENU = "condition_menu",
  CONDITION_SEARCH_MENU = "condition_search_menu",
  MAIN_MENU_CURSOR_ON_MATCH_CALL = "main_menu_cursor_on_match_call",
  MAIN_MENU_CURSOR_ON_RIBBONS = "main_menu_cursor_on_ribbons",
  REGION_MAP = "region_map",
  CONDITION_GRAPH_PARTY = "condition_graph_party",
  CONDITION_SEARCH_RESULTS = "condition_search_results",
  CONDITION_GRAPH_SEARCH = "condition_graph_search",
  RETURN_CONDITION_SEARCH = "return_condition_search",
  MATCH_CALL = "match_call",
  RIBBONS_MON_LIST = "ribbons_mon_list",
  RIBBONS_SUMMARY_SCREEN = "ribbons_summary_screen",
  RIBBONS_RETURN_TO_MON_LIST = "ribbons_return_to_mon_list",
}
-- pokeemerald/include/pokenav.h:67
Pokenav.MODE = { NORMAL = 0, FORCE_CALL_READY = 1, FORCE_CALL_EXIT = 2 }
Pokenav.EXIT = -1

local SCREENS = {
  main_menu = "src.ui.game3.rse.pokenav.main_menu",
  main_menu_cursor_on_map = "src.ui.game3.rse.pokenav.main_menu",
  main_menu_cursor_on_match_call = "src.ui.game3.rse.pokenav.main_menu",
  main_menu_cursor_on_ribbons = "src.ui.game3.rse.pokenav.main_menu",
  condition_menu = "src.ui.game3.rse.pokenav.main_menu",
  condition_search_menu = "src.ui.game3.rse.pokenav.main_menu",
  region_map = "src.ui.game3.rse.pokenav.region_map",
  match_call = "src.ui.game3.rse.pokenav.match_call",
  condition_graph_party = "src.ui.game3.rse.pokenav.condition",
  condition_graph_search = "src.ui.game3.rse.pokenav.condition",
  condition_search_results = "src.ui.game3.rse.pokenav.condition_search",
  return_condition_search = "src.ui.game3.rse.pokenav.condition_search",
  ribbons_mon_list = "src.ui.game3.rse.pokenav.ribbons",
  ribbons_return_to_mon_list = "src.ui.game3.rse.pokenav.ribbons",
  ribbons_summary_screen = "src.ui.game3.rse.pokenav.ribbons_summary",
}
Pokenav.SCREENS = SCREENS

local Shell = {}
Shell.__index = Shell

local Host = { isMenu = true }
Pokenav.Host = Host

-- pokeemerald/src/pokenav.c:388
local function anyMonHasRibbon(session)
  return require("src.core.game3.rse.ribbons").anyMonHasRibbon(session)
end

local function newShell(opts)
  local s = setmetatable({
    session = opts.session,
    game = opts.game,
    onClose = opts.onClose,
    tutorial = opts.tutorial == true,
    mode = opts.tutorial and Pokenav.MODE.FORCE_CALL_READY or Pokenav.MODE.NORMAL,
    pal = Pal.new(),
    headerY = 0,
    helpBar = nil,
    spinFrame = 0,
    spinTimer = 0,
    spinVisible = true,
    frames = 0,
    phase = "field_fade",
    tasks = {},
  }, Shell)
  s.hasAnyRibbons = anyMonHasRibbon(s.session)
  -- pokeemerald/src/start_menu.c:623
  s.fieldPal = Pal.new()
  s.fieldPal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
  s.leftMain = Gfx.leftHeader()
  s.leftSub = Gfx.leftHeader()
  s.leftSub.sub = true
  return s
end

function Shell:run(fn)
  local co = coroutine.create(fn)
  self.tasks[#self.tasks + 1] = co
  return co
end

function Shell:busy(co)
  return co ~= nil and coroutine.status(co) ~= "dead"
end

function Shell:runTasks()
  local keep = {}
  for _, co in ipairs(self.tasks) do
    if coroutine.status(co) ~= "dead" then
      local ok, err = coroutine.resume(co)
      if not ok then error(err, 0) end
      if coroutine.status(co) ~= "dead" then keep[#keep + 1] = co end
    end
  end
  self.tasks = keep
end

-- pokeemerald/src/pokenav_main_menu.c:510
function Shell:fade(kind)
  local all = kind == "to_black_all" or kind == "from_black_all"
  local fromBlack = kind == "from_black" or kind == "from_black_all"
  self.fadeAll = all
  self.pal:resetFade()
  self.pal:beginFade(all and Pal.ALL or Pal.mask({ 1 }), -2, fromBlack and 16 or 0, fromBlack and 0 or 16, Pal.BLACK)
end

function Shell:fadeActive()
  return self.pal:fadeActive()
end

function Shell:primaryY()
  return self.pal.slots[0].y
end

function Shell:restY()
  return self.pal.slots[1].y
end

-- pokeemerald/src/pokenav_main_menu.c:413
function Shell:slideHeader(up)
  return self:run(function()
    if up then
      coroutine.yield()
      coroutine.yield()
      while true do
        self.headerY = self.headerY + 1.5
        if self.headerY >= 32 then self.headerY = 32 return end
        coroutine.yield()
      end
    else
      while true do
        self.headerY = self.headerY - 1.5
        if self.headerY <= 0 then self.headerY = 0 return end
        coroutine.yield()
      end
    end
  end)
end

function Shell:setHelpBar(index)
  local man = Gfx.manifest()
  self.helpBar = man.helpBarTexts[index or 0]
end

function Shell:leftHeadersBusy()
  return self.leftMain:busy() or self.leftSub:busy()
end

function Shell:hideLeftHeaders()
  self.leftMain.visible = false
  self.leftSub.visible = false
  self.leftMain.key = nil
  self.leftSub.key = nil
end

-- pokeemerald/src/main.c:250
function Shell:setKeyRepeat(start, continue)
  self.repeatStart = start
  self.repeatContinue = continue
end

local function stepRepeat(step, pressed)
  local shell = Host._s
  local held = step.held or {}
  local sig = {}
  for _, k in ipairs(Kit.KEYS) do if held[k] then sig[#sig + 1] = k end end
  sig = table.concat(sig, ",")
  local rep = {}
  for k in pairs(pressed) do rep[k] = true end
  local start = shell and shell.repeatStart or 40
  if sig ~= "" and sig == step.heldSig then
    step.repeatCounter = (step.repeatCounter or start) - 1
    if step.repeatCounter <= 0 then
      for k in pairs(held) do rep[k] = true end
      step.repeatCounter = shell and shell.repeatContinue or 5
    end
  else
    step.repeatCounter = start
  end
  step.heldSig = sig
  return rep
end

function Shell:setActiveMenu(menuId)
  local path = SCREENS[menuId]
  if not path then
    require("src.core.game3.rse.init").missing("pokenav", menuId)
    return false
  end
  local mod = require(path)
  self.menuId = menuId
  self:setKeyRepeat(nil, nil)
  self.screen = mod.new(self, menuId)
  self.screenTask = self:run(function() self.screen:open() end)
  return true
end

-- pokeemerald/src/pokenav.c:434
function Shell:frame(inp)
  self.frames = self.frames + 1
  self.inp = inp
  if self.phase == "field_fade" then
    self.fieldPal:updateFade()
    if not self.fieldPal:fadeActive() then
      self.phase = "init"
      self.initFrames = 0
    end
  elseif self.phase == "init" then
    self.initFrames = self.initFrames + 1
    self.pal:blend(Pal.ALL, 16, Pal.BLACK)
    if self.initFrames >= 3 then
      self:setActiveMenu(Pokenav.MENU.MAIN_MENU)
      self.phase = "menu"
    end
  elseif self.phase == "menu" then
    if not self:busy(self.screenTask) and not self:busy(self.loopTask) then
      local r = self.screen:callback(inp)
      if r == Pokenav.EXIT then
        self:shutdown()
      elseif type(r) == "string" then
        if self.screen.free then self.screen:free() end
        if not self:setActiveMenu(r) then self:shutdown() end
      elseif r ~= nil and r ~= 0 then
        self.loopTask = self:run(function() self.screen:loopTask(r) end)
      end
    end
  elseif self.phase == "shutdown" then
    if not self.pal:fadeActive() then
      self:close()
      return
    end
  end
  self:runTasks()
  self.pal:updateFade()
  self.leftMain:update()
  self.leftSub:update()
  -- pokeemerald/src/pokenav_main_menu.c:213
  self.spinTimer = self.spinTimer + 1
  if self.spinTimer >= 8 then
    self.spinTimer = 0
    self.spinFrame = (self.spinFrame + 1) % 8
  end
  if self.screen and self.screen.frame then self.screen:frame() end
end

-- pokeemerald/src/pokenav_main_menu.c:313
function Shell:shutdown()
  Kit.playSe("SE_POKENAV_OFF")
  self.pal:resetFade()
  self.pal:beginFade(Pal.ALL, -1, 0, 16, Pal.BLACK)
  self.fadeAll = true
  self.phase = "shutdown"
end

-- pokeemerald/src/pokenav.c:364
function Shell:close()
  local Stack = require("src.ui.game3.stack")
  if Host._s == self then Host._s = nil end
  Stack.pop(Pokenav.ID)
  if self.screen and self.screen.free then self.screen:free() end
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.begin then
    Fade.clear()
    Fade.begin(Fade.MODE.FROM_BLACK, 1)
  end
  if self.onClose then self.onClose() end
end

function Shell:draw()
  love.graphics.push("all")
  love.graphics.setColor(0, 0, 0, 1)
  if self.phase == "field_fade" then
    love.graphics.setColor(0, 0, 0, self.fieldPal.slots[0].y / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.pop()
    return
  end
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  if self.phase == "init" then love.graphics.pop() return end
  Gfx.setDim(self:restY())
  if self.screen and self.screen.draw then self.screen:draw() end
  self.leftMain:draw()
  self.leftSub:draw()
  Gfx.setDim(self:primaryY())
  Gfx.drawHeader(self.headerY)
  if self.helpBar and self.headerY > 0 then Gfx.drawHelpBar(self.helpBar, self.headerY) end
  if self.screen and self.screen.drawTop then
    Gfx.setDim(self:restY())
    self.screen:drawTop()
    Gfx.setDim(self:primaryY())
  end
  if self.spinVisible then
    Gfx.drawSpin(self.spinFrame, self.spinX or 220, (self.spinY or 12) - (self.spinFollowsHeader == false and 0 or self.headerY))
  end
  Gfx.setDim(0)
  love.graphics.pop()
end

function Pokenav.show(opts)
  opts = opts or {}
  local Stack = require("src.ui.game3.stack")
  local s = newShell(opts)
  Host._s = s
  Host._step = Kit.stepper()
  Host._step._repeat = stepRepeat
  Stack.push(Pokenav.ID, Host, {
    hideBelow = false,
    fullscreen = function() return Host._s ~= nil and Host._s.phase ~= "field_fade" end,
  })
  return s
end

function Pokenav.active()
  return Host._s
end

function Pokenav.isOpen()
  return Host._s ~= nil
end

function Pokenav.reset()
  if Host._s then
    Host._s = nil
    require("src.ui.game3.stack").pop(Pokenav.ID)
  end
  Host._step = nil
  Gfx.reset()
  require("src.ui.game3.rse.pokenav.condition").reset()
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local s = Host._s
  if not (s and Host._step) then return end
  Host._step:run(dt, function(inp)
    if Host._s ~= s then return true end
    s:frame(inp)
    if Host._s ~= s then return true end
    return nil
  end)
end

function Host.draw()
  if Host._s then Host._s:draw() end
end

return Pokenav
