local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")

local MainMenu = {}
MainMenu.__index = MainMenu

-- pokeemerald/include/pokenav.h:138
MainMenu.TYPE = { DEFAULT = 0, UNLOCK_MC = 1, UNLOCK_MC_RIBBONS = 2, CONDITION = 3, CONDITION_SEARCH = 4 }
-- pokeemerald/include/pokenav.h:148
MainMenu.ITEM = {
  MAP = 0, CONDITION = 1, MATCH_CALL = 2, RIBBONS = 3, SWITCH_OFF = 4, CONDITION_PARTY = 5,
  CONDITION_SEARCH = 6, CONDITION_CANCEL = 7, SEARCH_COOL = 8, SEARCH_BEAUTY = 9, SEARCH_CUTE = 10,
  SEARCH_SMART = 11, SEARCH_TOUGH = 12, SEARCH_CANCEL = 13,
}
-- pokeemerald/include/pokenav.h:240
MainMenu.FUNC = {
  NONE = 0, MOVE_CURSOR = 1, OPEN_CONDITION = 2, RETURN_TO_MAIN = 3, OPEN_CONDITION_SEARCH = 4,
  RETURN_TO_CONDITION = 5, NO_RIBBON_WINNERS = 6, RESHOW_DESCRIPTION = 7, OPEN_FEATURE = 8,
}
-- pokeemerald/include/pokenav.h:171
MainMenu.HELPBAR = { NONE = 0, MAP_ZOOMED_OUT = 1, MAP_ZOOMED_IN = 2, CONDITION_MON_LIST = 3, MC_TRAINER_LIST = 6,
  MC_CALL_MENU = 7, MC_CHECK_PAGE = 8, RIBBONS_MON_LIST = 9 }

local TYPE, ITEM, FUNC, HELPBAR = MainMenu.TYPE, MainMenu.ITEM, MainMenu.FUNC, MainMenu.HELPBAR

-- pokeemerald/src/pokenav_menu_handler.c:35
MainMenu.LAST_CURSOR = { [0] = 2, 3, 4, 2, 5 }
-- pokeemerald/src/pokenav_menu_handler.c:44
MainMenu.ITEMS = {
  [TYPE.DEFAULT] = { ITEM.MAP, ITEM.CONDITION, ITEM.SWITCH_OFF },
  [TYPE.UNLOCK_MC] = { ITEM.MAP, ITEM.CONDITION, ITEM.MATCH_CALL, ITEM.SWITCH_OFF },
  [TYPE.UNLOCK_MC_RIBBONS] = { ITEM.MAP, ITEM.CONDITION, ITEM.MATCH_CALL, ITEM.RIBBONS, ITEM.SWITCH_OFF },
  [TYPE.CONDITION] = { ITEM.CONDITION_PARTY, ITEM.CONDITION_SEARCH, ITEM.CONDITION_CANCEL },
  [TYPE.CONDITION_SEARCH] = { ITEM.SEARCH_COOL, ITEM.SEARCH_BEAUTY, ITEM.SEARCH_CUTE, ITEM.SEARCH_SMART,
    ITEM.SEARCH_TOUGH, ITEM.SEARCH_CANCEL },
}

-- pokeemerald/src/pokenav_menu_handler_gfx.c:34
MainMenu.OPTION_DEFAULT_X = 140
MainMenu.OPTION_SELECTED_X = 130
MainMenu.OPTION_EXIT_X = 240 + 16

local function Pokenav()
  return require("src.ui.game3.rse.pokenav.init")
end

local function flag(session, name)
  return require("src.core.game3.rse.rematch").flag(session, name)
end

local function item(menuType, pos)
  local list = MainMenu.ITEMS[menuType]
  return list[pos + 1] or ITEM.SWITCH_OFF
end

-- pokeemerald/src/pokenav_menu_handler.c:85
function MainMenu.mainMenuType(session)
  local t = TYPE.DEFAULT
  if flag(session, "FLAG_ADDED_MATCH_CALL_TO_POKENAV") then
    t = TYPE.UNLOCK_MC
    if flag(session, "FLAG_SYS_RIBBON_GET") then t = TYPE.UNLOCK_MC_RIBBONS end
  end
  return t
end

-- pokeemerald/src/pokenav_menu_handler.c:100
function MainMenu.new(shell, menuId)
  local P = Pokenav().MENU
  local self = setmetatable({ shell = shell, session = shell.session, menuId = menuId, helpBarIndex = HELPBAR.NONE,
    dotsX = 0, glow = 0, glowOn = false, blink = 0, icons = {}, blending = 0 }, MainMenu)
  if menuId == P.CONDITION_MENU then
    self.menuType, self.cursorPos = TYPE.CONDITION, 0
  elseif menuId == P.CONDITION_SEARCH_MENU then
    self.menuType, self.cursorPos = TYPE.CONDITION_SEARCH, shell.conditionSearchId or 0
  else
    self.menuType = MainMenu.mainMenuType(self.session)
    self.cursorPos = ({ [P.MAIN_MENU_CURSOR_ON_MATCH_CALL] = ITEM.MATCH_CALL,
      [P.MAIN_MENU_CURSOR_ON_RIBBONS] = ITEM.RIBBONS })[menuId] or ITEM.MAP
    if self.menuType == TYPE.DEFAULT and shell.mode ~= Pokenav().MODE.NORMAL then shell.mode = Pokenav().MODE.NORMAL end
  end
  self.currMenuItem = item(self.menuType, self.cursorPos)
  self.alreadyOpen = menuId ~= P.MAIN_MENU
  self.nearbyRematch = require("src.core.game3.rse.match_call").anyRematchesNearby(self.session)
  self.blueLightVisible = self.nearbyRematch
  self.description = nil
  self:setInputHandler()
  return self
end

function MainMenu:setInputHandler()
  local M = Pokenav().MODE
  if self.menuType == TYPE.CONDITION then
    self.handler = "condition"
  elseif self.menuType == TYPE.CONDITION_SEARCH then
    self.handler = "search"
  elseif self.shell.mode == M.FORCE_CALL_READY then
    self.handler = "tutorial"
  elseif self.shell.mode == M.FORCE_CALL_EXIT then
    self.handler = "end_tutorial"
  else
    self.handler = "main"
  end
end

-- pokeemerald/src/pokenav_menu_handler.c:464
function MainMenu:updateCursor(inp)
  local n = inp.new or {}
  if n.up then
    self.cursorPos = self.cursorPos - 1
    if self.cursorPos < 0 then self.cursorPos = MainMenu.LAST_CURSOR[self.menuType] end
    self.currMenuItem = item(self.menuType, self.cursorPos)
    return true
  elseif n.down then
    self.cursorPos = self.cursorPos + 1
    if self.cursorPos > MainMenu.LAST_CURSOR[self.menuType] then self.cursorPos = 0 end
    self.currMenuItem = item(self.menuType, self.cursorPos)
    return true
  end
  return false
end

local function openFeature(self, menuId, helpBar)
  self.helpBarIndex = helpBar
  self.targetMenuId = menuId
  return FUNC.OPEN_FEATURE
end

-- pokeemerald/src/pokenav_menu_handler.c:214
function MainMenu:callback(inp)
  if self.targetMenuId and self.featureReady then return self.targetMenuId end
  if self.pendingReturn then
    local r = self.pendingReturn
    self.pendingReturn = nil
    return r
  end
  local P = Pokenav().MENU
  local n = inp.new or {}
  local h = self.handler
  if h == "cant_ribbons" then
    if self:updateCursor(inp) then self:setInputHandler() return FUNC.MOVE_CURSOR end
    if n.a or n.b then self:setInputHandler() return FUNC.RESHOW_DESCRIPTION end
    return FUNC.NONE
  end
  if self:updateCursor(inp) then return FUNC.MOVE_CURSOR end
  local it = self.currMenuItem
  if h == "main" then
    if n.a then
      if it == ITEM.MAP then
        local zoom = self.session and self.session.regionMapZoom
        return openFeature(self, P.REGION_MAP, zoom and HELPBAR.MAP_ZOOMED_IN or HELPBAR.MAP_ZOOMED_OUT)
      elseif it == ITEM.CONDITION then
        self.menuType, self.cursorPos = TYPE.CONDITION, 0
        self.currMenuItem = item(TYPE.CONDITION, 0)
        self.handler = "condition"
        return FUNC.OPEN_CONDITION
      elseif it == ITEM.MATCH_CALL then
        return openFeature(self, P.MATCH_CALL, HELPBAR.MC_TRAINER_LIST)
      elseif it == ITEM.RIBBONS then
        if self.shell.hasAnyRibbons then return openFeature(self, P.RIBBONS_MON_LIST, HELPBAR.RIBBONS_MON_LIST) end
        self.handler = "cant_ribbons"
        return FUNC.NO_RIBBON_WINNERS
      elseif it == ITEM.SWITCH_OFF then
        return Pokenav().EXIT
      end
    end
    if n.b then return Pokenav().EXIT end
    return FUNC.NONE
  elseif h == "tutorial" then
    -- pokeemerald/src/pokenav_menu_handler.c:261
    if n.a then
      if it == ITEM.MATCH_CALL then return openFeature(self, P.MATCH_CALL, HELPBAR.MC_TRAINER_LIST) end
      Kit.playSe("SE_FAILURE")
      return FUNC.NONE
    end
    if n.b then Kit.playSe("SE_FAILURE") end
    return FUNC.NONE
  elseif h == "end_tutorial" then
    -- pokeemerald/src/pokenav_menu_handler.c:291
    if n.a then
      if it ~= ITEM.MATCH_CALL and it ~= ITEM.SWITCH_OFF then
        Kit.playSe("SE_FAILURE")
        return FUNC.NONE
      elseif it == ITEM.MATCH_CALL then
        return openFeature(self, P.MATCH_CALL, HELPBAR.MC_TRAINER_LIST)
      end
      return Pokenav().EXIT
    end
    if n.b then return Pokenav().EXIT end
    return FUNC.NONE
  elseif h == "condition" then
    -- pokeemerald/src/pokenav_menu_handler.c:341
    if n.a then
      if it == ITEM.CONDITION_SEARCH then
        self.menuType, self.cursorPos = TYPE.CONDITION_SEARCH, 0
        self.currMenuItem = item(TYPE.CONDITION_SEARCH, 0)
        self.handler = "search"
        return FUNC.OPEN_CONDITION_SEARCH
      elseif it == ITEM.CONDITION_PARTY then
        return openFeature(self, P.CONDITION_GRAPH_PARTY, 0)
      elseif it == ITEM.CONDITION_CANCEL then
        Kit.playSe("SE_SELECT")
        self:returnToMain()
        return FUNC.RETURN_TO_MAIN
      end
    end
    if n.b then
      if self.cursorPos ~= MainMenu.LAST_CURSOR[self.menuType] then
        self.cursorPos = MainMenu.LAST_CURSOR[self.menuType]
        self.currMenuItem = item(self.menuType, self.cursorPos)
        self:queueReturn("main")
        return FUNC.MOVE_CURSOR
      end
      Kit.playSe("SE_SELECT")
      self:returnToMain()
      return FUNC.RETURN_TO_MAIN
    end
    return FUNC.NONE
  elseif h == "search" then
    -- pokeemerald/src/pokenav_menu_handler.c:385
    if n.a then
      if it ~= ITEM.SEARCH_CANCEL then
        self.shell.conditionSearchId = it - ITEM.SEARCH_COOL
        return openFeature(self, P.CONDITION_SEARCH_RESULTS, HELPBAR.CONDITION_MON_LIST)
      end
      Kit.playSe("SE_SELECT")
      self:returnToCondition()
      return FUNC.RETURN_TO_CONDITION
    end
    if n.b then
      if self.cursorPos ~= MainMenu.LAST_CURSOR[self.menuType] then
        self.cursorPos = MainMenu.LAST_CURSOR[self.menuType]
        self.currMenuItem = item(self.menuType, self.cursorPos)
        self:queueReturn("condition")
        return FUNC.MOVE_CURSOR
      end
      Kit.playSe("SE_SELECT")
      self:returnToCondition()
      return FUNC.RETURN_TO_CONDITION
    end
    return FUNC.NONE
  end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_menu_handler.c:425
function MainMenu:queueReturn(kind)
  if kind == "main" then
    self.pendingReturnFn = function() self:returnToMain() return FUNC.RETURN_TO_MAIN end
  else
    self.pendingReturnFn = function() self:returnToCondition() return FUNC.RETURN_TO_CONDITION end
  end
end

-- pokeemerald/src/pokenav_menu_handler.c:448
function MainMenu:returnToMain()
  self.menuType = MainMenu.mainMenuType(self.session)
  self.cursorPos = 1
  self.currMenuItem = item(self.menuType, 1)
  self.handler = "main"
end

-- pokeemerald/src/pokenav_menu_handler.c:456
function MainMenu:returnToCondition()
  self.menuType = TYPE.CONDITION
  self.cursorPos = 1
  self.currMenuItem = item(TYPE.CONDITION, 1)
  self.handler = "condition"
end

local function wait(pred)
  while pred() do coroutine.yield() end
end

local function pause() coroutine.yield() end

function MainMenu:labels()
  local man = Gfx.manifest()
  return man.menus[self.menuType]
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:854
function MainMenu:drawLabels()
  local m = self:labels()
  self.icons = {}
  local y = m.yStart
  for i = 1, 6 do
    local lab = m.items[i]
    if lab then
      self.icons[i] = { label = lab, x = MainMenu.OPTION_DEFAULT_X, y = y, visible = false, invisible = true }
    end
    y = y + m.deltaY
  end
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:990
local function slide(icon, startX, endX, time)
  icon.x = startX
  icon.slideTime = time
  icon.slideAccel = math.floor(16 * (endX - startX) / time)
  icon.slideSpeed = 16 * startX
  icon.slideEndX = endX
  icon.cb = "slide"
end

function MainMenu:iconIndexForCursor()
  local n = 0
  for i = 1, 6 do
    if self.icons[i] then
      if n == self.cursorPos then return i end
      n = n + 1
    end
  end
  return nil
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:887
function MainMenu:enterAnimations()
  local sel = self:iconIndexForCursor()
  for i = 1, 6 do
    local ic = self.icons[i]
    if ic then
      local x = (i == sel) and MainMenu.OPTION_SELECTED_X or MainMenu.OPTION_DEFAULT_X
      if i == sel then self.iconCursor = i end
      slide(ic, MainMenu.OPTION_EXIT_X, x, 12)
      ic.invisible = false
      ic.zoom = nil
      ic.alpha = 1
    end
  end
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:921
function MainMenu:cursorMovedAnimations()
  local newPos = self:iconIndexForCursor()
  if self.iconCursor and self.icons[self.iconCursor] then
    slide(self.icons[self.iconCursor], MainMenu.OPTION_SELECTED_X, MainMenu.OPTION_DEFAULT_X, 4)
  end
  if newPos then slide(self.icons[newPos], MainMenu.OPTION_DEFAULT_X, MainMenu.OPTION_SELECTED_X, 4) end
  self.iconCursor = newPos
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:949
function MainMenu:exitAnimations()
  for i = 1, 6 do
    local ic = self.icons[i]
    if ic then
      if self.iconCursor ~= i then
        slide(ic, MainMenu.OPTION_DEFAULT_X, MainMenu.OPTION_EXIT_X, 8)
      else
        ic.cb = "zoom"
        ic.zoomDelay = 8
        ic.zoomSet = false
        ic.zoomScale = 0x100
        ic.blend = { delay = 8, state = 0, t1 = 16, t2 = 0, counter = 0 }
        self.blending = self.blending + 1
      end
    end
  end
end

function MainMenu:spritesMoving()
  for i = 1, 6 do
    local ic = self.icons[i]
    if ic and ic.cb then return true end
  end
  return self.blending ~= 0
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:1055
local function iconFrame(self, ic)
  if ic.cb == "slide" then
    ic.slideTime = ic.slideTime - 1
    if ic.slideTime ~= -1 then
      ic.slideSpeed = ic.slideSpeed + ic.slideAccel
      ic.x = math.floor(ic.slideSpeed / 16)
    else
      ic.x = ic.slideEndX
      ic.cb = nil
    end
  elseif ic.cb == "zoom" then
    if ic.zoomDelay == 0 then
      if not ic.zoomSet then
        ic.zoomSet = true
        ic.zoomSpeed = 0x100
        ic.zoomFrames = 0
      else
        ic.zoomSpeed = ic.zoomSpeed + 16
        ic.zoomFrames = ic.zoomFrames + 1
        ic.spread = math.floor((math.floor(ic.zoomSpeed / 8) - 32) / 2)
        ic.zoomScale = 0x100 + 0x10 * math.min(ic.zoomFrames, 0x12)
        if ic.zoomFrames > 0x12 then
          ic.invisible = true
          ic.cb = nil
        end
      end
    else
      ic.zoomDelay = ic.zoomDelay - 1
    end
  end
  -- pokeemerald/src/pokenav_menu_handler_gfx.c:1134
  local b = ic.blend
  if b then
    if b.delay == 0 then
      if b.state == 0 then
        b.t1, b.t2, b.state = 16, 0, 1
      else
        if b.counter % 2 == 1 then b.t1 = math.max(0, b.t1 - 3) else b.t2 = math.min(16, b.t2 + 3) end
        b.counter = b.counter + 1
        if b.counter == 12 then
          self.blending = self.blending - 1
          b.t1, b.t2 = 0, 16
          ic.blend = nil
          ic.alpha = 0
          return
        end
      end
      ic.alpha = b.t1 / 16
    else
      b.delay = b.delay - 1
    end
  end
end

function MainMenu:descriptionKey()
  return Gfx.manifest().pageDescriptions[self.currMenuItem]
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:1223
function MainMenu:printDescription()
  self.description = self:descriptionKey()
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:1235
function MainMenu:printNoRibbonWinners()
  self.description = "gText_NoRibbonWinners"
end

function MainMenu:leftHeaderKeys()
  if self.menuType == TYPE.CONDITION_SEARCH then return "condition", "search" end
  if self.menuType == TYPE.CONDITION then return "condition", nil end
  return "main_menu", nil
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:448
function MainMenu:open()
  local shell = self.shell
  self.purple = self.menuType == TYPE.CONDITION or self.menuType == TYPE.CONDITION_SEARCH
  self.dotsPurple = self.purple and 1 or 0
  for _ = 1, 3 do pause() end
  self:printDescription()
  self:drawLabels()
  pause()
  self.visible = true
  if self.alreadyOpen then
    shell:fade("from_black")
  else
    Kit.playSe("SE_POKENAV_ON")
    shell:fade("from_black_all")
  end
  pause()
  wait(function() return shell:fadeActive() end)
  local mainKey, subKey = self:leftHeaderKeys()
  shell.leftMain:show(mainKey, false, false)
  if subKey then shell.leftSub:show(subKey, false, false, true) end
  self:enterAnimations()
  self.glowOn = true
  wait(function() return self:spritesMoving() or shell:leftHeadersBusy() end)
end

function MainMenu:loopTask(func)
  local shell = self.shell
  if func == FUNC.MOVE_CURSOR then
    -- pokeemerald/src/pokenav_menu_handler_gfx.c:557
    self:cursorMovedAnimations()
    self:printDescription()
    Kit.playSe("SE_SELECT")
    pause()
    wait(function() return self:spritesMoving() end)
    if self.pendingReturnFn then
      local fn = self.pendingReturnFn
      self.pendingReturnFn = nil
      self:loopTask(fn())
    end
  elseif func == FUNC.OPEN_CONDITION or func == FUNC.RETURN_TO_MAIN or func == FUNC.OPEN_CONDITION_SEARCH
      or func == FUNC.RETURN_TO_CONDITION then
    -- pokeemerald/src/pokenav_menu_handler_gfx.c:577
    self.glowOn = false
    self:exitAnimations()
    if func == FUNC.OPEN_CONDITION or func == FUNC.OPEN_CONDITION_SEARCH then Kit.playSe("SE_SELECT") end
    if func == FUNC.OPEN_CONDITION or func == FUNC.RETURN_TO_MAIN or func == FUNC.RETURN_TO_CONDITION then
      if func == FUNC.RETURN_TO_CONDITION then shell.leftSub:hide(false) else
        shell.leftMain:hide(false)
        if func == FUNC.RETURN_TO_MAIN then shell.leftSub:hide(false) end
      end
    end
    pause()
    wait(function() return self:spritesMoving() or shell:leftHeadersBusy() end)
    self:drawLabels()
    pause()
    self:enterAnimations()
    local mainKey, subKey = self:leftHeaderKeys()
    if func == FUNC.OPEN_CONDITION or func == FUNC.RETURN_TO_MAIN then shell.leftMain:show(mainKey, false, false) end
    if func == FUNC.OPEN_CONDITION_SEARCH then shell.leftSub:show(subKey, false, false, true) end
    if func == FUNC.OPEN_CONDITION then self:dotsTo(1) elseif func == FUNC.RETURN_TO_MAIN then self:dotsTo(0) end
    self:printDescription()
    pause()
    wait(function() return self:spritesMoving() or shell:leftHeadersBusy() or self.dotsTask end)
    self.glowOn = true
  elseif func == FUNC.NO_RIBBON_WINNERS then
    Kit.playSe("SE_FAILURE")
    self:printNoRibbonWinners()
    pause()
  elseif func == FUNC.RESHOW_DESCRIPTION then
    Kit.playSe("SE_SELECT")
    self:printDescription()
    pause()
  elseif func == FUNC.OPEN_FEATURE then
    -- pokeemerald/src/pokenav_menu_handler_gfx.c:752
    local path = require("src.ui.game3.rse.pokenav.init").SCREENS[self.targetMenuId]
    if not path then
      require("src.core.game3.rse.init").missing("pokenav", self.targetMenuId)
      Kit.playSe("SE_FAILURE")
      self.targetMenuId = nil
      return
    end
    shell:setHelpBar(self.helpBarIndex)
    pause()
    shell:slideHeader(true)
    self.glowOn = false
    self:exitAnimations()
    shell.leftMain:hide(false)
    if self.menuType == TYPE.CONDITION or self.menuType == TYPE.CONDITION_SEARCH then shell.leftSub:hide(false) end
    Kit.playSe("SE_SELECT")
    pause()
    wait(function() return self:spritesMoving() or shell:leftHeadersBusy() end)
    shell:fade("to_black")
    pause()
    wait(function() return shell:fadeActive() end)
    self.featureReady = true
  end
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:1290
function MainMenu:dotsTo(target)
  local from = self.dotsPurple
  self.dotsTask = true
  self.dotsStep = 0
  self.dotsFrom, self.dotsTarget = from, target
end

function MainMenu:frame()
  for i = 1, 6 do
    local ic = self.icons[i]
    if ic then iconFrame(self, ic) end
  end
  -- pokeemerald/src/pokenav_menu_handler_gfx.c:1261
  self.dotsX = (self.dotsX + 0.5) % 256
  if self.dotsTask then
    self.dotsStep = self.dotsStep + 1
    self.dotsPurple = self.dotsFrom + (self.dotsTarget - self.dotsFrom) * math.min(12, self.dotsStep) / 12
    if self.dotsStep >= 12 then self.dotsTask = false end
  end
  -- pokeemerald/src/pokenav_menu_handler_gfx.c:1366
  self.glow = (self.glow + 3) % 128
  -- pokeemerald/src/pokenav_menu_handler_gfx.c:1223
  if self.nearbyRematch then
    self.blink = self.blink + 1
    if self.blink > 8 then
      self.blink = 0
      self.blueLightVisible = not self.blueLightVisible
    end
  end
end

function MainMenu:free()
end

local function sine(i)
  return math.floor(256 * math.sin(i * math.pi / 128) + 0.5)
end

function MainMenu:draw()
  if not self.visible then return end
  local man = Gfx.manifest()
  local dots = man.layers.dots
  local dx = math.floor(self.dotsX)
  local function dotsLayer(entry, alpha)
    Gfx.drawImage(entry, 0, 0, 256, 160, -dx, 0, alpha)
    Gfx.drawImage(entry, 0, 0, 256, 160, 256 - dx, 0, alpha)
  end
  dotsLayer(dots.png, 1)
  if self.dotsPurple > 0 then dotsLayer(dots.purple, self.dotsPurple) end
  Gfx.drawImage(man.layers.device, 0, 0, 256, 160, 0, 0)
  local opt = man.sprites.options
  -- pokeemerald/src/pokenav_menu_handler_gfx.c:1366
  local bldy = self.glowOn and math.floor(math.max(0, sine(self.glow)) / 32) or 0
  for i = 1, 6 do
    local ic = self.icons[i]
    if ic and not ic.invisible then
      local qy = (ic.label - 1) * 16
      local alpha = ic.alpha or 1
      local selected = (i == self.iconCursor) and self.glowOn
      for j = 0, 3 do
        local x = ic.x + 32 * j - 16
        local scale = 1
        if ic.zoomSet then
          scale = (ic.zoomScale or 0x100) / 0x100
          local spread = ic.spread or 0
          local off = ({ [0] = -3, -1, 1, 3 })[j] * spread
          local cx = ic.x + 32 * j + off
          Gfx.drawImage(opt, j * 32, qy, 32, 16, cx, ic.y, alpha, scale, scale, 16, 8)
        else
          if selected and bldy > 0 then
            local img = Gfx.image(opt)
            if img then
              local k = 1 - Gfx.dim
              Kit.drawTinted(img, Gfx.quad(img, j * 32, qy, 32, 16), x, ic.y - 8, bldy / 16, { k, k, k }, alpha)
            end
          else
            Gfx.drawImage(opt, j * 32, qy, 32, 16, x, ic.y - 8, alpha)
          end
        end
      end
    end
  end
  if self.blueLightVisible then
    Gfx.drawImage(man.sprites.blueLight, 0, 0, 32, 16, 0x10 - 16, 0x60 - 8)
  end
  Gfx.drawImage(man.layers.message, 0, 0, 256, 160, 0, 0)
  local pal = man.palettes.message
  local key = self.description
  if key then
    local s = Gfx.plain(key)
    local w = Gfx.measure(s)
    Gfx.fill(pal, 6, 3 * 8, 17 * 8, 24 * 8, 16)
    Gfx.text(s, 3 * 8 + math.floor((192 - w) / 2), 17 * 8 + 1, Gfx.colors(pal, Gfx.TEXT.GREEN, Gfx.TEXT.BLUE, Gfx.TEXT.LIGHT_GREEN))
  end
end

return MainMenu
