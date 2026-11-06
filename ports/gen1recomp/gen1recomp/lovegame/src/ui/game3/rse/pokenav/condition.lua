local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")
local Graph = require("src.ui.game3.rse.pokenav.graph")
local MonInfo = require("src.ui.game3.rse.pokenav.mon_info")

local Screen = {}
Screen.__index = Screen

Screen.SUB = "rse/pokenav_cr"

-- pokeemerald/include/pokenav.h:253
Screen.FUNC = { NONE = 0, SLIDE_MON_IN = 1, RETURN = 2, NO_TRANSITION = 3, SLIDE_MON_OUT = 4, ADD_MARKINGS = 5,
  CLOSE_MARKINGS = 6 }
-- pokeemerald/include/pokenav.h:171
Screen.HELPBAR = { CONDITION_MON_STATUS = 4, CONDITION_MARKINGS = 5 }
-- pokeemerald/src/pokenav_conditions_gfx.c:801
Screen.MON_X = 38
Screen.MON_Y = 104
-- pokeemerald/src/mon_markings.c:13
Screen.NUM_MARKINGS = 4
Screen.SELECTION_OK = 4
Screen.SELECTION_CANCEL = 5

local FUNC = Screen.FUNC

local manifest
function Screen.manifest()
  if manifest then return manifest end
  local root = require("src.core.game3.cache_paths").CACHE_ROOT
  manifest = assert(Kit.loadLua(root .. "/" .. Screen.SUB .. "/manifest.lua"), "pokenav condition manifest missing from the cache")
  return manifest
end

function Screen.reset()
  manifest = nil
end

local function Pokenav() return require("src.ui.game3.rse.pokenav.init") end
local function pause() coroutine.yield() end
local function wait(pred) while pred() do coroutine.yield() end end

-- pokeemerald/src/pokenav_conditions.c:458
function Screen.partyList(session)
  local items = {}
  for i, mon in ipairs(session and session.party or {}) do
    if type(mon) == "table" and not require("src.core.game3.pokemon").isEgg(mon) then
      items[#items + 1] = { boxId = nil, monId = i, data = 0 }
    end
  end
  items[#items + 1] = { boxId = 0, monId = 0, data = 0, cancel = true }
  return { items = items, currIndex = 0, listCount = #items }
end

-- pokeemerald/src/pokenav_conditions.c:18
function Screen.new(shell, menuId)
  local P = Pokenav().MENU
  local man = Screen.manifest()
  local self = setmetatable({ shell = shell, session = shell.session, man = man, menuId = menuId,
    searchMode = menuId == P.CONDITION_GRAPH_SEARCH, graph = Graph.new(man), slots = {}, monX = -80,
    loadId = 0, nextLoadIdDown = 0, nextLoadIdUp = 0, toLoadId = 0, toLoadListIndex = 0 }, Screen)
  for i = 0, 2 do self.slots[i] = { name = nil, location = nil, sparkles = 0, marks = 0 } end
  if self.searchMode then
    self.list = assert(shell.monList, "condition graph search without a mon list")
  else
    self.list = Screen.partyList(self.session)
    shell.monList = self.list
  end
  shell:setKeyRepeat(20, nil)
  self.handler = "input"
  return self
end

function Screen:lastIndex()
  return self.searchMode and self.list.listCount or self.list.listCount - 1
end

function Screen:item(listId)
  return self.list.items[listId + 1]
end

function Screen:mon(listId)
  return MonInfo.mon(self.session, self:item(listId))
end

-- pokeemerald/src/pokenav_conditions.c:426
function Screen:copyNameGenderLocation(listId, loadId)
  local slot = self.slots[loadId]
  if listId ~= self:lastIndex() then
    local mon = self:mon(listId)
    slot.mon = mon
    slot.name = mon and MonInfo.nickname(mon) or ""
    slot.gender = mon and MonInfo.conditionGender(mon) or "U"
    slot.level = mon and MonInfo.level(mon) or 0
    slot.egg = mon and require("src.core.game3.pokemon").isEgg(mon) or false
    local it = self:item(listId)
    slot.location = (it and it.boxId == nil) and Gfx.plain("gText_InParty") or MonInfo.boxName(self.session, it and it.boxId)
  else
    slot.mon, slot.name, slot.location, slot.egg = nil, nil, nil, false
  end
end

-- pokeemerald/src/pokenav_conditions.c:491
function Screen:loadGraphData(listId, loadId)
  local slot = self.slots[loadId]
  local g = self.graph
  if listId ~= self:lastIndex() then
    local mon = self:mon(listId)
    local c = type(mon) == "table" and type(mon.contest) == "table" and mon.contest or {}
    local conds = {}
    for i = 0, 4 do conds[i] = math.floor(tonumber(c[Graph.CONDITION_KEYS[i]]) or 0) end
    g.conditions[loadId] = conds
    slot.sparkles = Graph.numSparkles(c.sheen)
    slot.marks = math.floor(tonumber(mon and mon.markings) or 0) % 16
    g.saved[loadId] = Graph.calcPositions(self.man, conds)
  else
    g.conditions[loadId] = { [0] = 0, 0, 0, 0, 0 }
    g.saved[loadId] = Graph.empty()
  end
end

-- pokeemerald/src/pokenav_conditions.c:522
function Screen:loadPic(listId, loadId)
  if listId == self:lastIndex() then return end
  self.slots[loadId].pic = self:mon(listId)
end

local function wrapUp(self, i)
  return (i + 1 >= self.list.listCount) and 0 or i + 1
end

local function wrapDown(self, i)
  return (i - 1 >= 0) and i - 1 or self.list.listCount - 1
end

-- pokeemerald/src/pokenav_conditions.c:235
function Screen:loadGfxStep(state)
  local cur = self.list.currIndex
  if state == 0 then self:copyNameGenderLocation(cur, 0)
  elseif state == 1 then self:loadGraphData(cur, 0)
  elseif state == 2 then self:loadPic(cur, 0)
  elseif state == 3 then
    self.loadId = 0
    if self.list.listCount == 1 then
      self.nextLoadIdDown, self.nextLoadIdUp = 0, 0
      return true
    end
    self.nextLoadIdDown, self.nextLoadIdUp = 1, 2
  elseif state == 4 then self:copyNameGenderLocation(wrapUp(self, cur), 1)
  elseif state == 5 then self:loadGraphData(wrapUp(self, cur), 1)
  elseif state == 6 then self:loadPic(wrapUp(self, cur), 1)
  elseif state == 7 then self:copyNameGenderLocation(wrapDown(self, cur), 2)
  elseif state == 8 then self:loadGraphData(wrapDown(self, cur), 2)
  elseif state == 9 then
    self:loadPic(wrapDown(self, cur), 2)
    return true
  end
  return false
end

-- pokeemerald/src/pokenav_conditions.c:303
function Screen:loadNext(mode)
  if mode == "info" then self:copyNameGenderLocation(self.toLoadListIndex, self.toLoadId)
  elseif mode == "graph" then self:loadGraphData(self.toLoadListIndex, self.toLoadId)
  else self:loadPic(self.toLoadListIndex, self.toLoadId) end
end

-- pokeemerald/src/pokenav_conditions.c:194
function Screen:switchIndex(moveUp)
  local list, g = self.list, self.graph
  local newLoadId = moveUp and self.nextLoadIdUp or self.nextLoadIdDown
  g:setNewPositions(g.saved[self.loadId], g.saved[newLoadId])
  local wasNotLast = list.currIndex ~= self:lastIndex()
  if moveUp then
    self.nextLoadIdUp = self.nextLoadIdDown
    self.nextLoadIdDown = self.loadId
    self.loadId = newLoadId
    self.toLoadId = self.nextLoadIdUp
    list.currIndex = (list.currIndex == 0) and list.listCount - 1 or list.currIndex - 1
    self.toLoadListIndex = (list.currIndex ~= 0) and list.currIndex - 1 or list.listCount - 1
  else
    self.nextLoadIdDown = self.nextLoadIdUp
    self.nextLoadIdUp = self.loadId
    self.loadId = newLoadId
    self.toLoadId = self.nextLoadIdDown
    list.currIndex = (list.currIndex < list.listCount - 1) and list.currIndex + 1 or 0
    self.toLoadListIndex = (list.currIndex < list.listCount - 1) and list.currIndex + 1 or 0
  end
  local isNotLast = list.currIndex ~= self:lastIndex()
  if not wasNotLast then return FUNC.NO_TRANSITION end
  if not isNotLast then return FUNC.SLIDE_MON_OUT end
  return FUNC.SLIDE_MON_IN
end

-- pokeemerald/src/pokenav_conditions.c:167
function Screen:dpad(inp)
  local held = inp.held or {}
  local list = self.list
  if held.up then
    if not self.searchMode or list.currIndex ~= 0 then
      Kit.playSe("SE_SELECT")
      return self:switchIndex(true)
    end
  elseif held.down then
    if not self.searchMode or list.currIndex < list.listCount - 1 then
      Kit.playSe("SE_SELECT")
      return self:switchIndex(false)
    end
  end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_conditions.c:85
function Screen:callback(inp)
  local P = Pokenav().MENU
  if self.handler == "return" then
    return self.searchMode and P.RETURN_CONDITION_SEARCH or P.CONDITION_MENU
  end
  local n = inp.new or {}
  if self.handler == "markings" then
    -- pokeemerald/src/pokenav_conditions.c:124
    if not self:markingsInput(inp) then
      self.slots[self.loadId].marks = self.marksMenu.markings
      local mon = self:mon(self.list.currIndex)
      if mon then mon.markings = self.marksMenu.markings end
      self.handler = "input"
      return FUNC.CLOSE_MARKINGS
    end
    return FUNC.NONE
  end
  local ret = self:dpad(inp)
  if ret == FUNC.NONE then
    if n.b then
      Kit.playSe("SE_SELECT")
      self.handler = "return"
      ret = FUNC.RETURN
    elseif n.a then
      if not self.searchMode then
        if self.list.currIndex == self.list.listCount - 1 then
          Kit.playSe("SE_SELECT")
          self.handler = "return"
          ret = FUNC.RETURN
        end
      else
        Kit.playSe("SE_SELECT")
        ret = FUNC.ADD_MARKINGS
        self.handler = "markings"
      end
    end
  end
  return ret
end

-- pokeemerald/src/mon_markings.c:348
function Screen:openMarkings(markings)
  local m = { cursorPos = 0, markings = markings, array = {} }
  for i = 0, Screen.NUM_MARKINGS - 1 do m.array[i] = math.floor(markings / 2 ^ i) % 2 == 1 end
  self.marksMenu = m
end

-- pokeemerald/src/mon_markings.c:393
function Screen:markingsInput(inp)
  local n = inp.new or {}
  local m = self.marksMenu
  if n.up then
    Kit.playSe("SE_SELECT")
    m.cursorPos = m.cursorPos - 1
    if m.cursorPos < 0 then m.cursorPos = Screen.SELECTION_CANCEL end
    return true
  end
  if n.down then
    Kit.playSe("SE_SELECT")
    m.cursorPos = m.cursorPos + 1
    if m.cursorPos > Screen.SELECTION_CANCEL then m.cursorPos = 0 end
    return true
  end
  if n.a then
    Kit.playSe("SE_SELECT")
    if m.cursorPos == Screen.SELECTION_OK then
      local v = 0
      for i = 0, Screen.NUM_MARKINGS - 1 do if m.array[i] then v = v + 2 ^ i end end
      m.markings = v
      return false
    elseif m.cursorPos == Screen.SELECTION_CANCEL then
      return false
    end
    m.array[m.cursorPos] = not m.array[m.cursorPos]
    return true
  end
  if n.b then
    Kit.playSe("SE_SELECT")
    return false
  end
  return true
end

function Screen:onCancel()
  return not self.searchMode and self.list.currIndex == self.list.listCount - 1
end

-- pokeemerald/src/pokenav_conditions_gfx.c:559
function Screen:updateWindows(loadId)
  local slot = self.slots[loadId]
  self.window = {
    name = (not self:onCancel()) and slot.name or nil,
    gender = slot.gender, level = slot.level, egg = slot.egg,
    location = self.searchMode and slot.location or nil,
    rank = self.searchMode and (self:item(self.list.currIndex) or {}).data or nil,
  }
end

-- pokeemerald/src/pokenav_conditions_gfx.c:804
function Screen:createMonPic(loadId)
  self.picMon = self.slots[loadId].pic
end

function Screen:resetSparkles()
  self.sparkles = nil
end

function Screen:createSparkles()
  self.sparkles = Graph.sparkles(self.man, self.slots[self.loadId].sparkles)
end

-- pokeemerald/src/pokenav_conditions_gfx.c:191
function Screen:open()
  local shell = self.shell
  local state = 0
  while not self:loadGfxStep(state) do
    state = state + 1
    pause()
  end
  pause()
  self.visible = true
  self.monX = -80
  for _ = 1, 9 do pause() end
  self:createMonPic(0)
  pause()
  pause()
  self:updateWindows(self.loadId)
  for _ = 1, 4 do pause() end
  self.showText = true
  if self.searchMode then shell:setHelpBar(Screen.HELPBAR.CONDITION_MON_STATUS) end
  pause()
  shell:fade("from_black")
  if not self.searchMode then
    shell.leftMain:show("condition", true, false)
    shell.leftSub:show("party", true, false, true)
  end
  pause()
  wait(function() return shell:fadeActive() or (not self.searchMode and shell:leftHeadersBusy()) end)
  pause()
  -- pokeemerald/src/pokenav_conditions_gfx.c:865
  local g = self.graph
  g:setNewPositions(g.saved[Graph.LOAD_MAX - 1], g.saved[self.loadId])
  g:tryUpdate()
  pause()
  pause()
  pause()
  self.graphVisible = true
  pause()
  while true do
    local x, busy = g:updateMonEnter(self.monX)
    self.monX = x
    if not busy then break end
    pause()
  end
  self:resetSparkles()
  self:createSparkles()
end

function Screen:loopTask(func)
  local shell = self.shell
  local g = self.graph
  if func == FUNC.SLIDE_MON_IN then
    -- pokeemerald/src/pokenav_conditions_gfx.c:374
    self:loadNext("info")
    self:loadNext("graph")
    self:loadNext("pic")
    self:resetSparkles()
    g:tryUpdate()
    while true do
      local x, busy = Graph.monOffscreen(self.monX)
      self.monX = x
      if not busy then break end
      pause()
    end
    self:createMonPic(self.loadId)
    self:updateWindows(self.loadId)
    while true do
      local x, busy = g:updateMonEnter(self.monX)
      self.monX = x
      if not busy then break end
      pause()
    end
    self:createSparkles()
  elseif func == FUNC.NO_TRANSITION then
    -- pokeemerald/src/pokenav_conditions_gfx.c:431
    self:loadNext("info")
    self:loadNext("graph")
    self:loadNext("pic")
    self:createMonPic(self.loadId)
    self:updateWindows(self.loadId)
    while true do
      local x, busy = g:updateMonEnter(self.monX)
      self.monX = x
      if not busy then break end
      pause()
    end
    self:createSparkles()
  elseif func == FUNC.SLIDE_MON_OUT then
    -- pokeemerald/src/pokenav_conditions_gfx.c:475
    self:loadNext("info")
    self:loadNext("graph")
    self:loadNext("pic")
    self:resetSparkles()
    while true do
      local x, busy = g:updateMonExit(self.monX)
      self.monX = x
      if not busy then break end
      pause()
    end
    self:updateWindows(self.loadId)
  elseif func == FUNC.RETURN then
    -- pokeemerald/src/pokenav_conditions_gfx.c:341
    if self.searchMode or self.list.currIndex ~= self.list.listCount - 1 then
      g:setNewPositions(g.saved[self.loadId], g.saved[Graph.LOAD_MAX - 1])
    end
    self:resetSparkles()
    while true do
      local x, busy = g:updateMonExit(self.monX)
      self.monX = x
      if not busy then break end
      pause()
    end
    self.graphVisible = false
    shell:fade("to_black")
    local slide
    if not self.searchMode then slide = shell:slideHeader(false) end
    pause()
    wait(function() return shell:fadeActive() or shell:busy(slide) end)
    self.visible = false
  elseif func == FUNC.ADD_MARKINGS then
    -- pokeemerald/src/pokenav_conditions_gfx.c:513
    self:openMarkings(self.slots[self.loadId].marks)
    shell:setHelpBar(Screen.HELPBAR.CONDITION_MARKINGS)
    pause()
  elseif func == FUNC.CLOSE_MARKINGS then
    -- pokeemerald/src/pokenav_conditions_gfx.c:532
    self.marksMenu = nil
    shell:setHelpBar(Screen.HELPBAR.CONDITION_MON_STATUS)
    pause()
  end
end

-- pokeemerald/src/pokenav_conditions_gfx.c:842
function Screen:frame()
  self.graph:draw()
  if self.sparkles then
    self.sparkles:frame(Screen.MON_X + self.monX, Screen.MON_Y)
  end
end

function Screen:free()
  if not self.searchMode then self.shell:hideLeftHeaders() end
  self.shell:setKeyRepeat(nil, nil)
end

function Screen:drawBalls()
  local sp = self.man.sprites
  local list = self.list
  local i = 0
  -- pokeemerald/src/pokenav_conditions_gfx.c:689
  while i < list.listCount - 1 do
    local frame = (i == list.currIndex) and 0 or 1
    Gfx.drawImage(sp.balls.png, 0, frame * 16, 16, 16, 226 - 8, i * 20 + 8 - 8)
    i = i + 1
  end
  while i < 6 do
    Gfx.drawImage(sp.ballPlaceholder.png, 0, 0, 8, 8, 230 - 4, i * 20 + 8 - 4)
    i = i + 1
  end
  -- pokeemerald/src/pokenav_conditions_gfx.c:644
  local lit = list.currIndex == list.listCount - 1
  Gfx.drawImage(lit and sp.cancel.lit or sp.cancel.png, 0, 0, 32, 16, 222 - 16, i * 20 + 8 - 8)
end

function Screen:drawWindows()
  local w = self.window
  if not (w and self.showText) then return end
  local pal = self.man.palettes.conditionText
  local T = Gfx.TEXT
  local function clear(fg, sh)
    local c = Gfx.colors(pal, T.TRANSPARENT, fg, sh)
    c.bg = { 0, 0, 0, 0 }
    return c
  end
  local base = clear(T.BLUE, T.LIGHT_BLUE)
  -- pokeemerald/src/pokenav_conditions.c:335
  local x0, y0 = 13 * 8, 1 * 8
  if w.name then
    Gfx.text(w.name, x0, y0 + 1, base)
    if not w.egg then
      local gx = x0 + 60
      local sym = MonInfo.genderSymbol(w.gender)
      local gc = base
      if w.gender == "M" then gc = clear(T.RED, T.LIGHT_RED) end
      if w.gender == "F" then gc = clear(T.GREEN, T.LIGHT_GREEN) end
      Gfx.text(w.gender == "U" and " " or sym, gx, y0 + 1, gc)
      local sw = Gfx.measure(w.gender == "U" and " " or sym)
      Gfx.text("/{LV_2}" .. tostring(w.level), gx + sw, y0 + 1, base)
    end
  end
  if w.location then
    Gfx.text(w.location, x0, y0 + 17, base)
  end
  if w.rank then
    -- pokeemerald/src/pokenav_conditions_gfx.c:584
    local lx, ly = 1 * 8, 6 * 8
    Gfx.text(Gfx.plain("gText_Number2"), lx + 4, ly + 1, base)
    Gfx.text(MonInfo.rightAlign(w.rank, 4), lx + 28, ly + 1, base)
  end
end

function Screen:drawMarkingsMenu()
  local m = self.marksMenu
  if not m then return end
  local sp = self.man.sprites.markingsMenu
  local x, y = 176, 32
  -- pokeemerald/src/mon_markings.c:295
  local frameType = require("src.core.game3.options").frameType(self.session)
  Kit.userFrame(x / 8 + 1, y / 8 + 1, 6, 12, frameType, Kit.messageColors("std_menu").bg)
  -- pokeemerald/src/mon_markings.c:494
  for i = 0, Screen.NUM_MARKINGS - 1 do
    local t = 2 * i + (m.array[i] and 1 or 0)
    Gfx.drawImage(sp.png, (t % 4) * 8, math.floor(t / 4) * 8, 8, 8, x + 32 - 4, y + 16 + 16 * i - 4)
  end
  Gfx.drawImage(sp.png, 0, 24, 32, 32, x + 32 - 16, y + 80 - 8)
  Gfx.drawImage(sp.png, 0, 16, 8, 8, x + 12 - 4, 16 * m.cursorPos + y + 16 - 4)
end

function Screen:draw()
  if not self.visible then return end
  local man = self.man
  local layer = man.layers.condition
  Gfx.drawImage(self.searchMode and layer.search or layer.png, 0, 0, 240, 160, 0, 0)
  if self.searchMode then
    -- pokeemerald/src/pokenav_conditions_gfx.c:675
    local marks = self.slots[self.loadId] and self.slots[self.loadId].marks or 0
    Gfx.drawImage(man.sprites.markings.png, 0, marks * 8, 32, 8, 192 - 16, 32 - 4)
  end
  if self.graphVisible then
    self.graph:drawFill(function(x, y, w, h)
      Gfx.drawImage(man.layers.graphFill.png, x, y, w, h, x, y)
    end)
  end
  if not self.searchMode then self:drawBalls() end
  self:drawWindows()
  if self.picMon then
    local front = require("src.core.game3.pokemon").monFrontPic(self.picMon)
    if front and front.image then
      Gfx.tint(1)
      love.graphics.draw(front.image, Screen.MON_X + self.monX - 32, Screen.MON_Y - 32)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
end

function Screen:drawTop()
  if not self.visible then return end
  if self.sparkles then
    local sp = self.man.sprites.sparkle
    self.sparkles:draw(function(frame, x, y)
      Gfx.drawImage(sp.png, 0, frame * 16, 16, 16, x, y)
    end)
  end
  self:drawMarkingsMenu()
end

return Screen
