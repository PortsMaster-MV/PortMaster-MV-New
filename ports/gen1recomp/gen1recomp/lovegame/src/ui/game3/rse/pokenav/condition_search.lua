local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")
local List = require("src.ui.game3.rse.pokenav.mon_list")
local MonInfo = require("src.ui.game3.rse.pokenav.mon_info")
local Condition = require("src.ui.game3.rse.pokenav.condition")

local Screen = {}
Screen.__index = Screen

-- pokeemerald/src/pokenav_conditions_search_results.c:16
Screen.FUNC = { NONE = 0, MOVE_UP = 1, MOVE_DOWN = 2, PAGE_UP = 3, PAGE_DOWN = 4, EXIT = 5, SELECT_MON = 6 }
-- pokeemerald/src/pokenav_conditions_search_results.c:70
Screen.KEYS = { [0] = "cool", "beauty", "cute", "smart", "tough" }
-- pokeemerald/include/pokenav.h:171
Screen.HELPBAR_CONDITION_MON_LIST = 3
-- pokeemerald/include/pokenav.h:106
Screen.LEFT_HEADERS = { [0] = "cool", "beauty", "cute", "smart", "tough" }

local FUNC = Screen.FUNC

local function Pokenav() return require("src.ui.game3.rse.pokenav.init") end
local function Ribbons() return require("src.core.game3.rse.ribbons") end
local function pause() coroutine.yield() end
local function wait(pred) while pred() do coroutine.yield() end end

local function statOf(mon, key)
  local c = type(mon) == "table" and type(mon.contest) == "table" and mon.contest or {}
  return math.floor(tonumber(c[key]) or 0)
end

-- pokeemerald/src/pokenav_conditions_search_results.c:365
function Screen.insert(items, item)
  local left, right = 0, #items
  local idx = left + math.floor((right - left) / 2)
  while right ~= idx do
    if item.data > items[idx + 1].data then right = idx else left = idx + 1 end
    idx = left + math.floor((right - left) / 2)
  end
  table.insert(items, idx + 1, item)
end

-- pokeemerald/src/pokenav_conditions_search_results.c:270
function Screen.build(session, searchId)
  local key = Screen.KEYS[searchId or 0]
  local items = {}
  for i, mon in ipairs(session and session.party or {}) do
    if not (type(mon) == "table" and (tonumber(require("src.core.game3.pokemon").speciesOf(mon)) or 0) ~= 0) then break end
    if Ribbons().hasSpeciesNotEgg(mon) then Screen.insert(items, { boxId = nil, monId = i, data = statOf(mon, key) }) end
  end
  local boxes = session and session.storage and session.storage.boxes
  for b = 1, boxes and #boxes or 0 do
    local box = boxes[b]
    for slot = 1, 30 do
      local mon = box and type(box.mons) == "table" and box.mons[slot] or nil
      if mon and Ribbons().hasSpeciesNotEgg(mon) then
        Screen.insert(items, { boxId = b, monId = slot, data = statOf(mon, key) })
      end
    end
  end
  -- pokeemerald/src/pokenav_conditions_search_results.c:341
  if #items > 0 then
    local prev = items[1].data
    items[1].data = 1
    for i = 2, #items do
      if items[i].data == prev then
        items[i].data = items[i - 1].data
      else
        prev = items[i].data
        items[i].data = i
      end
    end
  end
  return { items = items, currIndex = 0, listCount = #items }
end

-- pokeemerald/src/pokenav_conditions_search_results.c:132
function Screen.new(shell, menuId)
  local P = Pokenav().MENU
  local self = setmetatable({ shell = shell, session = shell.session, menuId = menuId, man = Condition.manifest(),
    fromGraph = menuId == P.RETURN_CONDITION_SEARCH }, Screen)
  if self.fromGraph then
    self.monList = assert(shell.monList, "condition search return without a mon list")
  else
    self.monList = Screen.build(self.session, shell.conditionSearchId or 0)
    shell.monList = self.monList
  end
  self.handler = "input"
  return self
end

-- pokeemerald/src/pokenav_conditions_search_results.c:184
function Screen:callback(inp)
  local P = Pokenav().MENU
  if self.handler == "exit" then return P.CONDITION_SEARCH_MENU end
  if self.handler == "graph" then return P.CONDITION_GRAPH_SEARCH end
  if not self.list then return FUNC.NONE end
  local n, rep = inp.new or {}, inp.rep or inp.new or {}
  if rep.up then return FUNC.MOVE_UP end
  if rep.down then return FUNC.MOVE_DOWN end
  if n.left then return FUNC.PAGE_UP end
  if n.right then return FUNC.PAGE_DOWN end
  if n.b then
    self.saveList = false
    self.handler = "exit"
    return FUNC.EXIT
  end
  if n.a then
    self.monList.currIndex = self.list:selectedIndex()
    self.saveList = true
    self.handler = "graph"
    return FUNC.SELECT_MON
  end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_conditions_search_results.c:434
function Screen:open()
  local shell = self.shell
  self.visible = true
  pause()
  pause()
  self.list = List.new(self.monList.items, self.monList.currIndex)
  for _ = 1, 3 do pause() end
  shell:setHelpBar(Screen.HELPBAR_CONDITION_MON_LIST)
  pause()
  if not self.fromGraph then
    shell.leftMain:show("condition", true, false)
    shell.leftSub:show(Screen.LEFT_HEADERS[shell.conditionSearchId or 0], true, false, true)
  end
  shell:fade("from_black")
  pause()
  wait(function() return shell:fadeActive() or shell:leftHeadersBusy() end)
end

local function moveTask(self, r)
  if r == 0 then return end
  Kit.playSe("SE_SELECT")
  pause()
  wait(function() return self.list:scrolling() end)
end

function Screen:loopTask(func)
  local shell = self.shell
  if func == FUNC.MOVE_UP then moveTask(self, self.list:cursorUp())
  elseif func == FUNC.MOVE_DOWN then moveTask(self, self.list:cursorDown())
  elseif func == FUNC.PAGE_UP then moveTask(self, self.list:pageUp())
  elseif func == FUNC.PAGE_DOWN then moveTask(self, self.list:pageDown())
  elseif func == FUNC.EXIT then
    -- pokeemerald/src/pokenav_conditions_search_results.c:625
    Kit.playSe("SE_SELECT")
    shell:fade("to_black")
    local slide = shell:slideHeader(false)
    pause()
    wait(function() return shell:fadeActive() or shell:busy(slide) end)
    shell:hideLeftHeaders()
    self.visible = false
  elseif func == FUNC.SELECT_MON then
    -- pokeemerald/src/pokenav_conditions_search_results.c:645
    Kit.playSe("SE_SELECT")
    shell:fade("to_black")
    pause()
    wait(function() return shell:fadeActive() end)
    self.visible = false
  end
end

function Screen:frame()
  if self.list then self.list:frame() end
end

function Screen:free()
  if not self.saveList and self.shell.monList == self.monList then self.shell.monList = nil end
end

function Screen:draw()
  if not self.visible then return end
  local man = self.man
  local listPal = man.palettes.searchList
  Gfx.fill(listPal, 1, 0, 0, 240, 160)
  if self.list then
    local colors = MonInfo.listColors(listPal)
    self.list:drawItems(listPal, function(item) return MonInfo.listSegments(self.session, item, colors, false) end)
  end
  Gfx.drawImage(man.layers.search.png, 0, 0, 240, 160, 0, 0)
  if self.list then
    -- pokeemerald/src/pokenav_conditions_search_results.c:669
    local rank = (self.monList.items[self.list:selectedIndex() + 1] or {}).data or 0
    local pal = man.palettes.searchFrame
    local colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY)
    local s = Gfx.plain("gText_NumberIndex", { dynamic = { [0] = "" } })
    Gfx.text(s, 8 + 4, 48 + 1, colors)
    Gfx.text(MonInfo.rightAlign(rank, 3), 8 + 34, 48 + 1, colors)
    self.list:drawArrows()
  end
end

return Screen
