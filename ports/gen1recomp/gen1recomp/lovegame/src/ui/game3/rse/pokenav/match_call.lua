local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")
local RomText = require("src.core.game3.rom_text")
local TextIR = require("src.core.game3.scripting.text_ir")

local Screen = {}
Screen.__index = Screen

-- pokeemerald/include/pokenav.h:273
Screen.FUNC = {
  NONE = 0, DOWN = 1, UP = 2, PG_DOWN = 3, PG_UP = 4, SELECT = 5, MOVE_OPTIONS_CURSOR = 6, CANCEL = 7, CALL_MSG = 8,
  NEARBY_MSG = 9, EXIT_CALL = 10, SHOW_CHECK_PAGE = 11, CHECK_PAGE_UP = 12, CHECK_PAGE_DOWN = 13,
  EXIT_CHECK_PAGE = 14, EXIT = 15,
}
-- pokeemerald/include/pokenav.h:214
Screen.OPTION = { CALL = 0, CHECK = 1, CANCEL = 2 }
-- pokeemerald/src/pokenav_match_call_list.c:41
Screen.OPTIONS_NO_CHECK = { 0, 2 }
Screen.OPTIONS_CHECK = { 0, 1, 2 }
-- pokeemerald/src/pokenav_match_call_gfx.c:872
Screen.LIST_X = 13
Screen.LIST_W = 16
Screen.LIST_TOP = 1
Screen.MAX_SHOWED = 8

local FUNC, OPTION = Screen.FUNC, Screen.OPTION

local function Pokenav() return require("src.ui.game3.rse.pokenav.init") end
local function MatchCall() return require("src.core.game3.rse.match_call") end
local function pause() coroutine.yield() end
local function wait(pred) while pred() do coroutine.yield() end end

function Screen.new(shell)
  local self = setmetatable({ shell = shell, session = shell.session, top = 0, sel = 0, scrollPx = 0,
    optionCursor = 0, cursorX2 = 0, cursorTimer = 0, sinIdx = 0, flashing = false, arrowTimer = 0, arrowOff = 0,
    picX2 = -80, picVisible = false }, Screen)
  self.handler = "list"
  -- pokeemerald/src/pokenav_match_call_list.c:205
  self.entries = MatchCall().buildList(self.session)
  return self
end

function Screen:selectedIndex()
  return self.top + self.sel
end

function Screen:entry(i)
  return self.entries[(i or self:selectedIndex()) + 1]
end

-- pokeemerald/src/pokenav_match_call_list.c:78
function Screen:callback(inp)
  if self.exitReady then return Pokenav().MENU.MAIN_MENU_CURSOR_ON_MATCH_CALL end
  local n, rep = inp.new or {}, inp.rep or inp.new or {}
  local h = self.handler
  local M = Pokenav().MODE
  if h == "list" then
    if rep.up then return FUNC.UP end
    if rep.down then return FUNC.DOWN end
    if rep.left then return FUNC.PG_UP end
    if rep.right then return FUNC.PG_DOWN end
    if n.a then
      self.handler = "options"
      self.optionCursor = 0
      local e = self:entry()
      if not e.isSpecialTrainer or MatchCall().headerHasCheckPage(e.headerId) then
        self.options = Screen.OPTIONS_CHECK
      else
        self.options = Screen.OPTIONS_NO_CHECK
      end
      return FUNC.SELECT
    end
    if n.b then
      if self.shell.mode ~= M.FORCE_CALL_READY then
        self.exitPending = true
        return FUNC.EXIT
      end
      Kit.playSe("SE_FAILURE")
    end
    return FUNC.NONE
  elseif h == "options" then
    -- pokeemerald/src/pokenav_match_call_list.c:133
    if n.up and self.optionCursor > 0 then
      self.optionCursor = self.optionCursor - 1
      return FUNC.MOVE_OPTIONS_CURSOR
    end
    if n.down and self.optionCursor < #self.options - 1 then
      self.optionCursor = self.optionCursor + 1
      return FUNC.MOVE_OPTIONS_CURSOR
    end
    if n.a then
      local o = self.options[self.optionCursor + 1]
      if o == OPTION.CANCEL then
        self.handler = "list"
        return FUNC.CANCEL
      elseif o == OPTION.CALL then
        if self.shell.mode == M.FORCE_CALL_READY then self.shell.mode = M.FORCE_CALL_EXIT end
        self.handler = "call"
        if MatchCall().shouldDoNearbyMessage(self.session, self:entry()) then return FUNC.NEARBY_MSG end
        return FUNC.CALL_MSG
      elseif o == OPTION.CHECK then
        self.handler = "check"
        return FUNC.SHOW_CHECK_PAGE
      end
    end
    if n.b then
      self.handler = "list"
      return FUNC.CANCEL
    end
    return FUNC.NONE
  elseif h == "check" then
    -- pokeemerald/src/pokenav_match_call_list.c:178
    if rep.up then return FUNC.CHECK_PAGE_UP end
    if rep.down then return FUNC.CHECK_PAGE_DOWN end
    if n.b then
      self.handler = "list"
      return FUNC.EXIT_CHECK_PAGE
    end
    return FUNC.NONE
  elseif h == "call" then
    -- pokeemerald/src/pokenav_match_call_list.c:194
    if self.printer and self.printer:isActive() then return FUNC.NONE end
    if n.a or n.b then
      self.handler = "list"
      return FUNC.EXIT_CALL
    end
    return FUNC.NONE
  end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_list.c:249
function Screen:showUp() return self.top ~= 0 end
function Screen:showDown() return self.top + Screen.MAX_SHOWED < #self.entries end

function Screen:moveWindow(delta)
  if delta < 0 and self.top + delta < 0 then delta = -self.top end
  if delta > 0 then
    local index = self.top + Screen.MAX_SHOWED
    if index + delta >= #self.entries then delta = #self.entries - index end
  end
  self.top = self.top + delta
  self.scrollPx = delta * 16
end

-- pokeemerald/src/pokenav_list.c:351
function Screen:cursorUp()
  if self.sel ~= 0 then self.sel = self.sel - 1 return 1 end
  if self:showUp() then self:moveWindow(-1) return 2 end
  return 0
end

function Screen:cursorDown()
  if self.top + self.sel >= #self.entries - 1 then return 0 end
  if self.sel < Screen.MAX_SHOWED - 1 then self.sel = self.sel + 1 return 1 end
  if self:showDown() then self:moveWindow(1) return 2 end
  return 0
end

-- pokeemerald/src/pokenav_list.c:387
function Screen:pageUp()
  if self:showUp() then
    local scroll = self.top >= Screen.MAX_SHOWED and Screen.MAX_SHOWED or self.top
    self:moveWindow(-scroll)
    return 2
  elseif self.sel ~= 0 then
    self.sel = 0
    return 1
  end
  return 0
end

-- pokeemerald/src/pokenav_list.c:409
function Screen:pageDown()
  local offscreen = math.max(0, #self.entries - Screen.MAX_SHOWED)
  if self:showDown() then
    local bottom = self.top + Screen.MAX_SHOWED
    local scroll = offscreen - self.top
    if bottom <= offscreen then scroll = Screen.MAX_SHOWED end
    self:moveWindow(scroll)
    return 2
  end
  local last = (#self.entries >= Screen.MAX_SHOWED and Screen.MAX_SHOWED or #self.entries) - 1
  if self.sel >= last then return 0 end
  self.sel = last
  return 1
end

-- pokeemerald/src/pokenav_match_call_gfx.c:323
function Screen:open()
  local shell = self.shell
  shell.spinVisible = true
  for _ = 1, 3 do pause() end
  shell.pal:blend(require("src.core.game3.pal_fade").mask({ 1 }), 16, { 0, 0, 0 })
  for _ = 1, 3 do pause() end
  self.visible = true
  shell.leftMain:show("match_call", true, false)
  shell:fade("from_black")
  pause()
  wait(function() return shell:fadeActive() or shell:leftHeadersBusy() end)
  self.flashing = true
end

local function moveTask(self, r)
  if r == 0 then return end
  Kit.playSe("SE_SELECT")
  pause()
  wait(function() return self.scrollPx ~= 0 end)
end

function Screen:loopTask(func)
  local shell = self.shell
  if func == FUNC.DOWN then
    moveTask(self, self:cursorDown())
  elseif func == FUNC.UP then
    moveTask(self, self:cursorUp())
  elseif func == FUNC.PG_DOWN then
    moveTask(self, self:pageDown())
  elseif func == FUNC.PG_UP then
    moveTask(self, self:pageUp())
  elseif func == FUNC.SELECT then
    -- pokeemerald/src/pokenav_match_call_gfx.c:544
    Kit.playSe("SE_SELECT")
    self.showOptions = true
    shell:setHelpBar(7)
    pause()
    self.cursorShown = true
  elseif func == FUNC.MOVE_OPTIONS_CURSOR then
    Kit.playSe("SE_SELECT")
  elseif func == FUNC.CANCEL then
    Kit.playSe("SE_SELECT")
    self.showOptions, self.cursorShown = false, false
    shell:setHelpBar(6)
    pause()
  elseif func == FUNC.CALL_MSG then
    -- pokeemerald/src/pokenav_match_call_gfx.c:594
    self.arrowsHidden = true
    self.callBox = "match_call"
    shell.spinX, shell.spinY, shell.spinFollowsHeader = 24, 112, false
    pause()
    local man = MatchCall().manifest()
    self.printer = Kit.printer(TextIR.decode(man.callingDots, { dialect = "rse" }), { speed = 2, canSpeedUp = false })
    Kit.playSe("SE_POKENAV_CALL")
    self.skipHangUpSE = false
    pause()
    wait(function() return self.printer:isActive() end)
    local msg, newReq = MatchCall().entryMessage(self.session, self:entry())
    self.newRematchRequest = newReq
    local speed = Kit.textSpeedDelay(require("src.core.game3.options").textSpeed(self.session))
    self.printer = Kit.printer(Screen.messageIr(msg), { ctx = msg.ctx, speed = speed })
    pause()
    wait(function() return self.printer:isActive() end)
  elseif func == FUNC.NEARBY_MSG then
    -- pokeemerald/src/pokenav_match_call_gfx.c:626
    Kit.playSe("SE_SELECT")
    self.callBox = "user"
    self.arrowsHidden = true
    self.skipHangUpSE = true
    pause()
    self.printer = Kit.printer("gText_TrainerCloseBy", { speed = 2 })
    pause()
    wait(function() return self.printer:isActive() end)
  elseif func == FUNC.EXIT_CALL then
    -- pokeemerald/src/pokenav_match_call_gfx.c:652
    if not self.skipHangUpSE then Kit.playSe("SE_POKENAV_HANG_UP") end
    Kit.playSe("SE_SELECT")
    pause()
    self.callBox, self.printer = nil, nil
    shell.spinX, shell.spinY, shell.spinFollowsHeader = nil, nil, nil
    pause()
    self.showOptions, self.cursorShown = false, false
    pause()
    shell:setHelpBar(6)
    pause()
    self.arrowsHidden = false
    self.newRematchRequest = nil
  elseif func == FUNC.SHOW_CHECK_PAGE then
    -- pokeemerald/src/pokenav_match_call_gfx.c:718
    Kit.playSe("SE_SELECT")
    self.showOptions, self.cursorShown = false, false
    self.arrowsHidden = true
    local offset = self.sel
    if offset ~= 0 then
      self.top = self.top + offset
      self.scrollPx = offset * 16
    end
    self.sel = 0
    self.checkPage = true
    pause()
    wait(function() return self.scrollPx ~= 0 end)
    shell:setHelpBar(8)
    pause()
    self:loadPic()
    wait(function() return self.picMoving end)
  elseif func == FUNC.CHECK_PAGE_UP or func == FUNC.CHECK_PAGE_DOWN then
    -- pokeemerald/src/pokenav_match_call_gfx.c:747
    local delta = func == FUNC.CHECK_PAGE_DOWN and self:nextCheckPageDelta(1) or self:nextCheckPageDelta(-1)
    if delta == 0 then return end
    Kit.playSe("SE_SELECT")
    self.picMoving, self.picSlide = true, "out"
    wait(function() return self.picMoving end)
    self.top = self.top + delta
    pause()
    pause()
    self:loadPic()
    wait(function() return self.picMoving end)
  elseif func == FUNC.EXIT_CHECK_PAGE then
    -- pokeemerald/src/pokenav_match_call_gfx.c:786
    Kit.playSe("SE_SELECT")
    self.picMoving, self.picSlide = true, "out"
    self:reshowList()
    wait(function() return self.picMoving or self.scrollPx ~= 0 end)
    shell:setHelpBar(6)
    self.checkPage = false
    self.arrowsHidden = false
    pause()
  elseif func == FUNC.EXIT then
    -- pokeemerald/src/pokenav_match_call_gfx.c:851
    Kit.playSe("SE_SELECT")
    self.flashing = false
    shell:fade("to_black")
    local slide = shell:slideHeader(false)
    pause()
    wait(function() return shell:fadeActive() or shell:busy(slide) end)
    shell:hideLeftHeaders()
    self.visible = false
    self.exitReady = true
  end
end

function Screen.messageIr(msg)
  if msg.parts then
    local out = {}
    for i, p in ipairs(msg.parts) do
      local ir = RomText.translate(RomText.ir(p.key), p.ctx, p.key)
      for _, seg in ipairs(ir) do
        if seg.t ~= "eos" then
          if seg.t == "strvar" and p.ctx.stringVars then
            out[#out + 1] = { t = "text", s = p.ctx.stringVars[seg.n] or "" }
          elseif seg.t == "ph" and p.ctx.stringVars and seg.code and seg.code >= 2 and seg.code <= 4 then
            out[#out + 1] = { t = "text", s = p.ctx.stringVars[seg.code - 1] or "" }
          else
            out[#out + 1] = seg
          end
        end
      end
      if i < #msg.parts then out[#out + 1] = { t = "para" } end
    end
    return out
  end
  return RomText.translate(RomText.ir(msg.key), msg.ctx, msg.key)
end

-- pokeemerald/src/pokenav_match_call_list.c:434
function Screen:nextCheckPageDelta(dir)
  local MC = MatchCall()
  local index, count = self.top, dir
  while true do
    index = index + dir
    if index < 0 or index >= #self.entries then return 0 end
    local e = self.entries[index + 1]
    if not e.isSpecialTrainer or MC.headerHasCheckPage(e.headerId) then return count end
    count = count + dir
  end
end

-- pokeemerald/src/pokenav_list.c:580
function Screen:reshowList()
  local n, max = #self.entries, Screen.MAX_SHOWED
  local index = self.top
  if n <= max then
    if self.top ~= 0 then
      self.sel = self.top
      self.top = 0
    end
  elseif self.top + max > n then
    local entries = self.top + max - n
    self.sel = entries
    self.top = self.top - entries
  end
  self.checkIndexReturn = index
end

-- pokeemerald/src/pokenav_match_call_gfx.c:1244
function Screen:loadPic()
  local e = self:entry(self.top)
  self.picId = MatchCall().entryTrainerPic(self.session, e)
  if self.picId and self.picId >= 0 then
    self.picX2 = -80
    self.picVisible = true
    self.picMoving, self.picSlide = true, "in"
  end
end

function Screen:frame()
  if self.scrollPx > 0 then
    self.scrollPx = math.max(0, self.scrollPx - 16)
  elseif self.scrollPx < 0 then
    self.scrollPx = math.min(0, self.scrollPx + 16)
  end
  if self.printer and self.printer:isActive() then self.printer:run(self.shell.inp or {}) end
  -- pokeemerald/src/pokenav_match_call_gfx.c:1229
  if self.cursorShown then
    self.cursorTimer = self.cursorTimer + 1
    if self.cursorTimer > 3 then
      self.cursorTimer = 0
      self.cursorX2 = (self.cursorX2 + 1) % 8
    end
  end
  -- pokeemerald/src/pokenav_match_call_gfx.c:908
  if self.flashing then self.sinIdx = (self.sinIdx + 4) % 128 end
  -- pokeemerald/src/pokenav_list.c:897
  self.arrowTimer = self.arrowTimer + 1
  if self.arrowTimer > 3 then
    self.arrowTimer = 0
    self.arrowOff = (self.arrowOff + 1) % 8
  end
  -- pokeemerald/src/pokenav_match_call_gfx.c:1270
  if self.picMoving then
    if self.picSlide == "in" then
      self.picX2 = self.picX2 + 8
      if self.picX2 >= 0 then self.picX2 = 0 self.picMoving = false end
    else
      self.picX2 = self.picX2 - 8
      if self.picX2 <= -80 then self.picVisible = false self.picMoving = false end
    end
  end
end

function Screen:free() end

local function narrow(s, x, y, colors) Gfx.text(s, x, y, colors, "narrow") end

-- pokeemerald/src/pokenav_match_call_list.c:399
function Screen:entryText(e)
  local desc, name = MatchCall().entryNameAndDesc(e)
  return desc, name
end

-- pokeemerald/src/pokenav_match_call_list.c:399
function Screen.drawNameAndDesc(desc, name, x, y, colors)
  narrow(desc, x, y, colors)
  narrow(name, x + math.max(69, Gfx.measure(desc, "narrow")), y, colors)
end

local function sineTable(i)
  return math.floor(256 * math.sin(i * math.pi / 128) + 0.5)
end

function Screen:drawList()
  local man = Gfx.manifest()
  local pal = man.palettes.listWindow
  local x0 = Screen.LIST_X * 8
  local y0 = Screen.LIST_TOP * 8
  local colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY)
  Gfx.fill(pal, 1, x0, y0, Screen.LIST_W * 8, Screen.MAX_SHOWED * 16)
  love.graphics.setScissor(x0, y0, 256 - x0, Screen.MAX_SHOWED * 16)
  local ballA = man.sprites.pokeball
  local lit = sineTable(self.sinIdx)
  lit = math.floor(math.max(0, lit) / 16)
  local rows = self.checkPage and 1 or Screen.MAX_SHOWED
  local extra = math.ceil(math.abs(self.scrollPx) / 16)
  for r = -extra, rows - 1 + extra do
    local i = self.top + r
    local e = self.entries[i + 1]
    local visibleRow = r >= 0 and r < rows
    if e and (visibleRow or self.scrollPx ~= 0) and not (self.checkPage and r ~= 0) then
      local y = y0 + r * 16 + self.scrollPx
      local desc, name = self:entryText(e)
      if self.checkPage and r == 0 then
        -- pokeemerald/src/pokenav_list.c:702
        Gfx.fill(pal, 4, x0, y, Screen.LIST_W * 8, 16)
        local c2 = Gfx.colors(pal, Gfx.TEXT.TRANSPARENT, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_RED)
        if desc and name then Screen.drawNameAndDesc(desc, name, x0 + 8, y + 1, c2) end
      elseif desc and name then
        Screen.drawNameAndDesc(desc, name, x0 + 8, y + 1, colors)
      end
      if MatchCall().showRematchIcon(self.session, e) then
        Gfx.drawImage(ballA.png, 0, 0, 8, 16, 0x1D * 8, y)
        if lit > 0 then Gfx.drawImage(ballA.lit, 0, 0, 8, 16, 0x1D * 8, y, lit / 16) end
      end
    end
  end
  if self.checkPage then self:drawCheckPage(x0, y0, pal) end
  love.graphics.setScissor()
end

-- pokeemerald/src/pokenav_list.c:724
function Screen:drawCheckPage(x0, y0, pal)
  local e = self:entry(self.top)
  local names = { "gText_PokenavMatchCall_Strategy", "gText_PokenavMatchCall_TrainerPokemon",
    "gText_PokenavMatchCall_SelfIntroduction" }
  local fieldColors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.RED, Gfx.TEXT.LIGHT_RED)
  local colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY)
  for i, key in ipairs(names) do
    narrow(Gfx.plain(key), x0 + 2, y0 + (1 + (i - 1) * 2) * 16 + 1, fieldColors)
  end
  local offsets = { 2, 4, 6, 7 }
  for entryIdx, row in ipairs(offsets) do
    local key = MatchCall().entryFlavorText(self.session, e, entryIdx)
    if key then narrow(Gfx.plain(key), x0 + 2, y0 + row * 16 + 1, colors) end
  end
end

function Screen:drawLeft()
  local man = Gfx.manifest()
  local pal = man.palettes.matchCallUi
  local colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY)
  -- pokeemerald/src/pokenav_match_call_gfx.c:1020
  local idx = self.checkPage and self.top or self:selectedIndex()
  local e = self:entry(idx)
  local none = MatchCall().mapsecNone()
  local name = (e and e.mapSec and e.mapSec ~= none) and MatchCall().mapName(e.mapSec) or Gfx.plain("gText_Unknown")
  Gfx.fill(pal, 1, 0, 5 * 8, 88, 16)
  narrow(name, math.floor((88 - Gfx.measure(name, "narrow")) / 2), 5 * 8 + 1, colors)
  Gfx.fill(pal, 1, 0, 9 * 8, 88, 64)
  if self.checkPage then return end
  if self.showOptions then
    -- pokeemerald/src/pokenav_match_call_gfx.c:1036
    for i, o in ipairs(self.options or {}) do
      narrow(Gfx.plain(man.optionTexts[o]), 16, 9 * 8 + (i - 1) * 16 + 1, colors)
    end
    if self.cursorShown then
      Gfx.drawImage(man.sprites.mcCursor, 0, 0, 8, 16, 4 - 4 + self.cursorX2, 80 - 8 + self.optionCursor * 16)
    end
    return
  end
  -- pokeemerald/src/pokenav_match_call_gfx.c:969
  local count = tostring(#self.entries)
  local battles = tostring(math.min(99999, require("src.core.game3.rse.rematch").gameStat(self.session, 9)))
  narrow(Gfx.plain("gText_NumberRegistered"), 2, 9 * 8 + 1, colors)
  narrow(count, 86 - Gfx.measure(count, "narrow"), 9 * 8 + 17, colors)
  narrow(Gfx.plain("gText_NumberOfBattles"), 2, 9 * 8 + 33, colors)
  narrow(battles, 86 - Gfx.measure(battles, "narrow"), 9 * 8 + 49, colors)
end

-- pokeemerald/src/match_call.c:1384
local function drawCallBorder(x, y, w, h)
  local win = MatchCall().manifest().window
  local cache = require("src.core.game3.cache_paths").CACHE_ROOT
  local entry = cache .. "/rse/match_call/window.png"
  local function t(n, tx, ty, tw, th)
    for yy = 0, th - 1 do
      for xx = 0, tw - 1 do
        Gfx.drawImage(entry, n * 8, 0, 8, 8, (tx + xx) * 8, (ty + yy) * 8)
      end
    end
  end
  t(0, x - 1, y - 1, 1, 1)
  t(1, x, y - 1, w, 1)
  t(2, x + w, y - 1, 1, 1)
  t(3, x - 1, y, 1, h)
  t(4, x + w, y, 1, h)
  t(5, x - 1, y + h, 1, 1)
  t(6, x, y + h, w, 1)
  t(7, x + w, y + h, 1, 1)
  return win
end
Screen.drawCallBorder = drawCallBorder

function Screen:drawCallBox()
  if not self.callBox then return end
  local man = Gfx.manifest()
  local pal = man.palettes.callWindow
  if self.callBox == "match_call" then
    drawCallBorder(1, 12, 28, 4)
  else
    local ok, v = pcall(function() return require("src.core.game3.scripting.natives_region_map_rse").frameType(self.session) end)
    Kit.userFrame(1, 12, 28, 4, ok and tonumber(v) or 0)
  end
  Gfx.fill(pal, 1, 8, 96, 224, 32)
  if self.printer then
    local x = self.callBox == "match_call" and 32 or 0
    self.printer:draw(8 + x, 96 + 1, { colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY),
      maxWidth = 224 - x })
  end
end

function Screen:draw()
  if not self.visible then return end
  local man = Gfx.manifest()
  local lpal = man.palettes.listWindow
  Gfx.fill(lpal, 1, 0, 0, 240, 160)
  self:drawList()
  Gfx.drawImage(man.layers.matchCall, 0, 0, 256, 160, 0, 0)
  self:drawLeft()
  -- pokeemerald/src/pokenav_list.c:839
  local arrows = man.sprites.arrows
  if not self.checkPage then
    local r = arrows.right
    Gfx.drawImage(arrows.png, r[1], r[2], r[3], r[4], Screen.LIST_X * 8 + 3 - 4, (Screen.LIST_TOP + 1) * 8 - 8 + self.sel * 16)
  end
  if not self.arrowsHidden then
    local ax = Screen.LIST_X * 8 + (Screen.LIST_W - 1) * 4 - 8
    if self:showDown() then
      local d = arrows.down
      Gfx.drawImage(arrows.png, d[1], d[2], d[3], d[4], ax, Screen.LIST_TOP * 8 + Screen.MAX_SHOWED * 16 - 4 + self.arrowOff)
    end
    if self:showUp() then
      local u = arrows.up
      Gfx.drawImage(arrows.png, u[1], u[2], u[3], u[4], ax, Screen.LIST_TOP * 8 - 4 - self.arrowOff)
    end
  end
  if self.picVisible and self.picId and self.picId >= 0 then
    local img = Kit.rgbaImage(require("src.core.game3.cache_paths").CACHE_ROOT .. "/trainers/front/" .. self.picId .. ".rgba", 64, 64)
    if img then
      local k = 1 - Gfx.dim
      love.graphics.setColor(k, k, k, 1)
      love.graphics.draw(img, 44 - 32 + self.picX2, 104 - 32)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
end

function Screen:drawTop()
  if self.visible then self:drawCallBox() end
end

return Screen
