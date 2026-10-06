local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")
local MonInfo = require("src.ui.game3.rse.pokenav.mon_info")
local Condition = require("src.ui.game3.rse.pokenav.condition")

local Screen = {}
Screen.__index = Screen

-- pokeemerald/src/pokenav_ribbons_summary.c:19
Screen.FUNC = { NONE = 0, SWITCH_MONS = 1, SELECT_RIBBON = 2, EXPANDED_CURSOR_MOVE = 3, EXPANDED_CANCEL = 4, EXIT = 5 }
-- pokeemerald/src/pokenav_ribbons_summary.c:35
Screen.RIBBONS_PER_ROW = 9
Screen.FIRST_GIFT_RIBBON = 25
Screen.GIFT_RIBBON_ROW = 1 + math.floor(25 / 9)
Screen.GIFT_RIBBON_START_POS = 9 * Screen.GIFT_RIBBON_ROW
Screen.MON_X_ON = 40
Screen.MON_X_OFF = -32
Screen.MON_Y = 104
-- pokeemerald/include/pokenav.h:171
Screen.HELPBAR_RIBBONS_LIST = 10
Screen.HELPBAR_RIBBONS_CHECK = 11

local FUNC = Screen.FUNC
local PER_ROW, FIRST_GIFT, GIFT_START = Screen.RIBBONS_PER_ROW, Screen.FIRST_GIFT_RIBBON, Screen.GIFT_RIBBON_START_POS

local function Pokenav() return require("src.ui.game3.rse.pokenav.init") end
local function Ribbons() return require("src.core.game3.rse.ribbons") end
local function pause() coroutine.yield() end
local function wait(pred) while pred() do coroutine.yield() end end

-- pokeemerald/src/pokenav_ribbons_summary.c:188
function Screen.new(shell)
  local self = setmetatable({ shell = shell, session = shell.session, man = Condition.manifest(), selectedPos = 0,
    monX = Screen.MON_X_ON, big = { invisible = true, scale = 256 } }, Screen)
  self.monList = assert(shell.monList, "ribbons summary without a mon list")
  self:getMonRibbons()
  shell:setKeyRepeat(10, 3)
  self.handler = "input"
  return self
end

function Screen:currentItem()
  return self.monList.items[self.monList.currIndex + 1]
end

function Screen:currentMon()
  return MonInfo.mon(self.session, self:currentItem())
end

-- pokeemerald/src/pokenav_ribbons_summary.c:440
function Screen:getMonRibbons()
  local normal, gift = Ribbons().monRibbonIds(self:currentMon(), self.man.ribbonData)
  self.normalIds, self.giftIds = normal, gift
  if #normal ~= 0 then
    self.normalLastRowStart = math.floor((#normal - 1) / PER_ROW) * PER_ROW
    self.selectedPos = 0
  else
    self.normalLastRowStart = 0
    self.selectedPos = GIFT_START
  end
end

-- pokeemerald/src/pokenav_ribbons_summary.c:277
function Screen:tryUp()
  if self.selectedPos < FIRST_GIFT then
    if self.selectedPos < PER_ROW then return false end
    self.selectedPos = self.selectedPos - PER_ROW
    return true
  end
  if #self.normalIds ~= 0 then
    self.selectedPos = (self.selectedPos - GIFT_START) + self.normalLastRowStart
    if self.selectedPos >= #self.normalIds then self.selectedPos = #self.normalIds - 1 end
    return true
  end
  return false
end

-- pokeemerald/src/pokenav_ribbons_summary.c:302
function Screen:tryDown()
  if self.selectedPos >= FIRST_GIFT then return false end
  if self.selectedPos < self.normalLastRowStart then
    self.selectedPos = self.selectedPos + PER_ROW
    if self.selectedPos >= #self.normalIds then self.selectedPos = #self.normalIds - 1 end
    return true
  end
  if #self.giftIds ~= 0 then
    local pos = self.selectedPos - self.normalLastRowStart
    if pos >= #self.giftIds then pos = #self.giftIds - 1 end
    self.selectedPos = pos + GIFT_START
    return true
  end
  return false
end

-- pokeemerald/src/pokenav_ribbons_summary.c:327
function Screen:tryLeft()
  if self.selectedPos % PER_ROW ~= 0 then
    self.selectedPos = self.selectedPos - 1
    return true
  end
  return false
end

-- pokeemerald/src/pokenav_ribbons_summary.c:339
function Screen:tryRight()
  local column = self.selectedPos % PER_ROW
  if column >= PER_ROW - 1 then return false end
  if self.selectedPos < GIFT_START then
    if self.selectedPos < #self.normalIds - 1 then
      self.selectedPos = self.selectedPos + 1
      return true
    end
  elseif column < #self.giftIds - 1 then
    self.selectedPos = self.selectedPos + 1
    return true
  end
  return false
end

-- pokeemerald/src/pokenav_ribbons_summary.c:505
function Screen:ribbonId()
  if self.selectedPos < FIRST_GIFT then return self.normalIds[self.selectedPos + 1] end
  return self.giftIds[self.selectedPos - GIFT_START + 1]
end

-- pokeemerald/src/pokenav_ribbons_summary.c:217
function Screen:callback(inp)
  local P = Pokenav().MENU
  if self.handler == "exit" then return P.RIBBONS_RETURN_TO_MON_LIST end
  local n, rep = inp.new or {}, inp.rep or inp.new or {}
  local list = self.monList
  if self.handler == "input" then
    if rep.up and list.currIndex ~= 0 then
      list.currIndex = list.currIndex - 1
      self.selectedPos = 0
      self:getMonRibbons()
      return FUNC.SWITCH_MONS
    end
    if rep.down and list.currIndex < list.listCount - 1 then
      list.currIndex = list.currIndex + 1
      self.selectedPos = 0
      self:getMonRibbons()
      return FUNC.SWITCH_MONS
    end
    if n.a then
      self.handler = "expanded"
      return FUNC.SELECT_RIBBON
    end
    if n.b then
      self.handler = "exit"
      return FUNC.EXIT
    end
    return FUNC.NONE
  end
  -- pokeemerald/src/pokenav_ribbons_summary.c:251
  if rep.up and self:tryUp() then return FUNC.EXPANDED_CURSOR_MOVE end
  if rep.down and self:tryDown() then return FUNC.EXPANDED_CURSOR_MOVE end
  if rep.left and self:tryLeft() then return FUNC.EXPANDED_CURSOR_MOVE end
  if rep.right and self:tryRight() then return FUNC.EXPANDED_CURSOR_MOVE end
  if n.b then
    self.handler = "input"
    return FUNC.EXPANDED_CANCEL
  end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_ribbons_summary.c:1229
function Screen:zoomIn()
  local pos = self.selectedPos
  local b = self.big
  b.x = (pos % PER_ROW) * 16 + 96
  b.y = math.floor(pos / PER_ROW) * 16 + 40
  b.gfx = self.man.ribbonGfx[self:ribbonId()]
  b.scale, b.delta, b.frames = 128, 32, 4
  b.invisible, b.invisibleWhenDone, b.animating = false, false, true
end

-- pokeemerald/src/pokenav_ribbons_summary.c:1252
function Screen:zoomOut()
  local b = self.big
  b.scale, b.delta, b.frames = 256, -32, 4
  b.invisibleWhenDone, b.animating = true, true
end

-- pokeemerald/src/pokenav_ribbons_summary.c:997
function Screen:startSlide(startX, destX, time)
  self.slide = { cur = startX * 16, incr = math.floor((destX - startX) * 16 / time), time = time, dest = destX }
  self.monX = startX
end

function Screen:printCount()
  self.textMode = "count"
  self.countText = Gfx.plain("gText_RibbonsF700", { dynamic = { [0] = tostring(Ribbons().count(self:currentMon())) } })
end

-- pokeemerald/src/pokenav_ribbons_summary.c:817
function Screen:printDescription()
  local id = self:ribbonId()
  self.textMode = "desc"
  self.desc = nil
  if not id then return end
  if id < FIRST_GIFT then
    self.desc = self.man.ribbonDescriptions[id]
  else
    local v = Ribbons().giftRibbonAt(self.session, id)
    if v == 0 then return end
    self.desc = self.man.giftRibbonDescriptions[v - 1]
  end
end

function Screen:printMonInfo()
  local mon = self:currentMon()
  self.info = mon and { name = MonInfo.nickname(mon), gender = MonInfo.gender(mon), level = MonInfo.level(mon) } or nil
  self.picMon = mon
end

-- pokeemerald/src/pokenav_ribbons_summary.c:566
function Screen:open()
  local shell = self.shell
  pause()
  pause()
  self:printCount()
  pause()
  self:printMonInfo()
  pause()
  pause()
  pause()
  self.visible = true
  self.showIcons = true
  shell:setHelpBar(Screen.HELPBAR_RIBBONS_LIST)
  pause()
  shell:fade("from_black")
  pause()
  wait(function() return shell:fadeActive() end)
end

function Screen:loopTask(func)
  local shell = self.shell
  if func == FUNC.SWITCH_MONS then
    -- pokeemerald/src/pokenav_ribbons_summary.c:669
    Kit.playSe("SE_SELECT")
    self:startSlide(Screen.MON_X_ON, Screen.MON_X_OFF, 6)
    pause()
    wait(function() return self.slide ~= nil end)
    self:printMonInfo()
    self:printCount()
    self:startSlide(Screen.MON_X_OFF, Screen.MON_X_ON, 6)
    pause()
    wait(function() return self.slide ~= nil end)
  elseif func == FUNC.SELECT_RIBBON then
    -- pokeemerald/src/pokenav_ribbons_summary.c:708
    Kit.playSe("SE_SELECT")
    self:zoomIn()
    pause()
    wait(function() return self.big.animating end)
    self:printDescription()
    shell:setHelpBar(Screen.HELPBAR_RIBBONS_CHECK)
    pause()
  elseif func == FUNC.EXPANDED_CURSOR_MOVE then
    -- pokeemerald/src/pokenav_ribbons_summary.c:732
    Kit.playSe("SE_SELECT")
    self:zoomOut()
    pause()
    wait(function() return self.big.animating end)
    self:zoomIn()
    pause()
    wait(function() return self.big.animating end)
    self:printDescription()
    pause()
  elseif func == FUNC.EXPANDED_CANCEL then
    -- pokeemerald/src/pokenav_ribbons_summary.c:762
    Kit.playSe("SE_SELECT")
    self:zoomOut()
    pause()
    wait(function() return self.big.animating end)
    self:printCount()
    shell:setHelpBar(Screen.HELPBAR_RIBBONS_LIST)
    pause()
  elseif func == FUNC.EXIT then
    -- pokeemerald/src/pokenav_ribbons_summary.c:653
    Kit.playSe("SE_SELECT")
    shell:fade("to_black")
    pause()
    wait(function() return shell:fadeActive() end)
    self.visible = false
  end
end

function Screen:frame()
  -- pokeemerald/src/pokenav_ribbons_summary.c:1010
  local s = self.slide
  if s then
    if s.time ~= 0 then
      s.time = s.time - 1
      s.cur = s.cur + s.incr
      self.monX = math.floor(s.cur / 16)
    else
      self.monX = s.dest
      self.slide = nil
    end
  end
  -- pokeemerald/src/pokenav_ribbons_summary.c:1264
  local b = self.big
  if b.animating then
    if b.frames > 0 then
      b.scale = b.scale + b.delta
      b.frames = b.frames - 1
    else
      b.invisible = b.invisibleWhenDone
      b.animating = false
    end
  end
end

function Screen:free()
  self.shell:setKeyRepeat(nil, nil)
end

function Screen:drawIcon(pos, id)
  local gfx = self.man.ribbonGfx[id]
  if not gfx then return end
  local sp = self.man.sprites.ribbonsSmall
  -- pokeemerald/src/pokenav_ribbons_summary.c:1057
  local x = ((pos % PER_ROW) * 2 + 11) * 8
  local y = (math.floor(pos / PER_ROW) * 2 + 4) * 8
  Gfx.drawImage(sp.png, gfx.pal * 16, gfx.tile * 16, 16, 16, x, y)
end

function Screen:draw()
  if not self.visible then return end
  local man = self.man
  Gfx.drawImage(man.layers.ribbonSummary.png, 0, 0, 240, 160, 0, 0)
  local pal = man.palettes.ribbonSummary
  local T = Gfx.TEXT
  -- pokeemerald/src/pokenav_ribbons_summary.c:804
  Gfx.fill(pal, 4, 12 * 8, 13 * 8, 16 * 8, 32)
  local colors = Gfx.colors(pal, T.RED, T.DARK_GRAY, T.LIGHT_GRAY)
  if self.textMode == "count" and self.countText then
    Gfx.text(self.countText, 12 * 8, 13 * 8 + 1, colors)
  elseif self.textMode == "desc" and self.desc then
    for i = 1, 2 do
      if self.desc[i] then Gfx.text(Gfx.plain(self.desc[i]), 12 * 8, 13 * 8 + (i - 1) * 16 + 1, colors) end
    end
  end
  -- pokeemerald/src/pokenav_ribbons_summary.c:872
  local info = self.info
  local ipal = man.palettes.monInfo
  Gfx.fill(ipal, 1, 14 * 8, 1 * 8, 13 * 8, 16)
  if info then
    local lc = MonInfo.listColors(ipal)
    Gfx.text(info.name, 14 * 8, 8 + 1, lc.normal)
    local sym = MonInfo.genderSymbol(info.gender)
    Gfx.text(sym, 14 * 8 + 60, 8 + 1, lc[info.gender] or lc.normal)
    Gfx.text("/{LV_2}" .. info.level, 14 * 8 + 60 + Gfx.measure(sym), 8 + 1, lc.normal)
  end
  -- pokeemerald/src/pokenav_ribbons_summary.c:926
  Gfx.fill(pal, 1, 1 * 8, 5 * 8, 7 * 8, 16)
  local idx = MonInfo.rightAlign(self.monList.currIndex + 1, 3) .. "/" .. MonInfo.rightAlign(self.monList.listCount, 3)
  Gfx.text(idx, 8 + math.floor((56 - Gfx.measure(idx)) / 2), 5 * 8 + 1, Gfx.colors(pal, T.WHITE, T.DARK_GRAY, T.LIGHT_GRAY))
  if self.showIcons then
    for i, id in ipairs(self.normalIds or {}) do self:drawIcon(i - 1, id) end
    for i, id in ipairs(self.giftIds or {}) do self:drawIcon(GIFT_START + i - 1, id) end
  end
  if self.picMon and self.monX > Screen.MON_X_OFF then
    local front = require("src.core.game3.pokemon").monFrontPic(self.picMon)
    if front and front.image then
      Gfx.tint(1)
      love.graphics.draw(front.image, self.monX - 32, Screen.MON_Y - 32)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
  local b = self.big
  if not b.invisible and b.gfx then
    local sp = man.sprites.ribbonsBig
    local img = Gfx.image(sp.png)
    if img then
      local s = b.scale / 256
      love.graphics.setScissor(b.x - 16, b.y - 16, 32, 32)
      Gfx.tint(1)
      love.graphics.draw(img, Gfx.quad(img, b.gfx.pal * 32, b.gfx.tile * 32, 32, 32), b.x, b.y, 0, s, s, 16, 16)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setScissor()
    end
  end
end

return Screen
