local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")
local List = require("src.ui.game3.rse.pokenav.mon_list")
local MonInfo = require("src.ui.game3.rse.pokenav.mon_info")
local Condition = require("src.ui.game3.rse.pokenav.condition")

local Screen = {}
Screen.__index = Screen

-- pokeemerald/src/pokenav_ribbons_list.c:14
Screen.FUNC = { NONE = 0, MOVE_UP = 1, MOVE_DOWN = 2, PAGE_UP = 3, PAGE_DOWN = 4, EXIT = 5, OPEN_RIBBONS_SUMMARY = 6 }
-- pokeemerald/include/pokenav.h:171
Screen.HELPBAR_RIBBONS_MON_LIST = 9

local FUNC = Screen.FUNC

local function Pokenav() return require("src.ui.game3.rse.pokenav.init") end
local function Ribbons() return require("src.core.game3.rse.ribbons") end
local function pause() coroutine.yield() end
local function wait(pred) while pred() do coroutine.yield() end end

-- pokeemerald/src/pokenav_ribbons_list.c:325
Screen.insert = require("src.ui.game3.rse.pokenav.condition_search").insert

-- pokeemerald/src/pokenav_ribbons_list.c:248
function Screen.build(session)
  local R = Ribbons()
  local items = {}
  for i, mon in ipairs(session and session.party or {}) do
    if not (type(mon) == "table" and (tonumber(require("src.core.game3.pokemon").speciesOf(mon)) or 0) ~= 0) then break end
    if R.hasSpeciesNotEgg(mon) then
      local n = R.count(mon)
      if n ~= 0 then Screen.insert(items, { boxId = nil, monId = i, data = n }) end
    end
  end
  local boxes = session and session.storage and session.storage.boxes
  for b = 1, boxes and #boxes or 0 do
    local box = boxes[b]
    for slot = 1, 30 do
      local mon = box and type(box.mons) == "table" and box.mons[slot] or nil
      if mon and R.hasSpeciesNotEgg(mon) then
        local n = R.count(mon)
        if n ~= 0 then Screen.insert(items, { boxId = b, monId = slot, data = n }) end
      end
    end
  end
  return { items = items, currIndex = 0, listCount = #items }
end

-- pokeemerald/src/pokenav_ribbons_list.c:127
function Screen.new(shell, menuId)
  local P = Pokenav().MENU
  local self = setmetatable({ shell = shell, session = shell.session, man = Condition.manifest(),
    fromSummary = menuId == P.RIBBONS_RETURN_TO_MON_LIST }, Screen)
  if self.fromSummary then
    self.monList = assert(shell.monList, "ribbons list return without a mon list")
  else
    self.monList = Screen.build(self.session)
    shell.monList = self.monList
  end
  self.handler = "input"
  return self
end

-- pokeemerald/src/pokenav_ribbons_list.c:176
function Screen:callback(inp)
  local P = Pokenav().MENU
  if self.handler == "exit" then return P.MAIN_MENU_CURSOR_ON_RIBBONS end
  if self.handler == "summary" then return P.RIBBONS_SUMMARY_SCREEN end
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
    self.handler = "summary"
    return FUNC.OPEN_RIBBONS_SUMMARY
  end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_ribbons_list.c:423
function Screen:open()
  local shell = self.shell
  self.visible = true
  pause()
  self.list = List.new(self.monList.items, self.monList.currIndex)
  for _ = 1, 3 do pause() end
  shell:setHelpBar(Screen.HELPBAR_RIBBONS_MON_LIST)
  shell:fade("from_black")
  if not self.fromSummary then shell.leftMain:show("ribbons", true, false) end
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
    -- pokeemerald/src/pokenav_ribbons_list.c:611
    Kit.playSe("SE_SELECT")
    shell:fade("to_black")
    local slide = shell:slideHeader(false)
    pause()
    wait(function() return shell:fadeActive() or shell:busy(slide) end)
    shell:hideLeftHeaders()
    self.visible = false
  elseif func == FUNC.OPEN_RIBBONS_SUMMARY then
    -- pokeemerald/src/pokenav_ribbons_list.c:631
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

-- pokeemerald/src/pokenav_ribbons_list.c:666
function Screen.indexText(index, max)
  return MonInfo.rightAlign(index, 3) .. "/" .. MonInfo.rightAlign(max, 3)
end

function Screen:draw()
  if not self.visible then return end
  local man = self.man
  local listPal = man.palettes.ribbonListUi
  Gfx.fill(listPal, 1, 0, 0, 240, 160)
  if self.list then
    local colors = MonInfo.listColors(listPal)
    self.list:drawItems(listPal, function(item) return MonInfo.listSegments(self.session, item, colors, true) end)
  end
  Gfx.drawImage(man.layers.ribbonList.png, 0, 0, 240, 160, 0, 0)
  if self.list then
    local pal = man.palettes.ribbonListFrame
    local colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY)
    local s = Screen.indexText(self.list:selectedIndex() + 1, self.list:count())
    Gfx.text(s, 8 + math.floor((56 - Gfx.measure(s)) / 2), 48 + 1, colors)
    self.list:drawArrows()
  end
end

return Screen
