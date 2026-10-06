local bit = require("bit")
local band, bor, bnot, lshift, rshift, arshift = bit.band, bit.bor, bit.bnot, bit.lshift, bit.rshift, bit.arshift

local Kit = require("src.ui.game3.rse.gc_kit")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local Machine = require("src.ui.game3.rse.gba_machine")
local R = require("src.core.game3.rse.roulette")

local F, trunc, s16 = R.f32, R.trunc, R.s16

local UI = {}
UI.__index = UI

local BPR = R.BALLS_PER_ROUND
local NUM_SLOTS = R.NUM_ROULETTE_SLOTS
local DEG = R.DEGREES_PER_SLOT
local NO_DELAY = 0xFFFF
local MAX_SPRITES = Sprites.MAX

-- pokeemerald/src/roulette.c:177
local SPR = {
  WHEEL_BALLS = 0, WHEEL_CENTER = 6, WHEEL_ICONS = 7, CREDIT = 20, CREDIT_DIGITS = 21, MULTIPLIER = 25,
  BALL_COUNTER = 26, GRID_ICONS = 29, POKE_HEADERS = 41, COLOR_HEADERS = 45, WIN_SLOT_CURSOR = 48,
  GRID_BALLS = 49, CLEAR_MON = 55, CLEAR_MON_SHADOW_1 = 56, CLEAR_MON_SHADOW_2 = 57,
}
UI.SPR = SPR

-- pokeemerald/src/roulette.c:168
local SELECT_STATE = { WAIT = 0, DRAW = 1, UPDATE = 2, ERASE = 0xFF }
local BALL_STATE = { ROLLING = 0, STUCK = 1, LANDED = 0xFF }

-- pokeemerald/src/roulette.c:116
local F_FLASH_ICON = lshift(1, 13)
local F_FLASH_OUTER_EDGES = lshift(1, 12)
local FLASH_ICON = 13
local FLASHUTIL_USE_EXISTING_COLOR = 0x8000

-- pokeemerald/include/constants/game_stat.h:33
local GAME_STAT_CONSECUTIVE_ROULETTE_WINS = 29

function UI.new(opts, class)
  opts = opts or {}
  local self = setmetatable({}, class or UI)
  self.opts = opts
  self.man = opts.manifest or R.loadTables(opts.cache)
  self.T = self.man.tables
  self.random = opts.random or function() return require("src.core.game3.rng").Random() end
  self.vblankRandom = opts.vblankRandom
  self.headless = opts.headless or Kit.headless()
  self.sound = opts.sound or Kit.sound({ muted = opts.headless })
  self.hours = opts.hours or 12
  self.m = Kit.newMachine()
  self.onDone = opts.onDone
  self.frames = 0
  self.done = false
  self.fn = {}
  self.m:setCb2(function() self:loadCb() end)
  return self
end

function UI:rand() return band(self.random(), 0xFFFF) end
function UI:joyNew(mask) return Kit.joyNew(self.m, mask) end
function UI:sprite(id) return self.m.ppu.sprites.sprites[id] end
function UI:spr(slot) return self:sprite(self.st.spriteIds[slot]) end
function UI:task(id) return self.m.tasks:get(id) end

function UI:func(name)
  local f = self.fn[name]
  if not f then
    f = function(tid) self[name](self, tid) end
    self.fn[name] = f
  end
  return f
end

function UI:setFunc(tid, name) self.m.tasks:setFunc(tid, self:func(name)) end

function UI:readTiles(rel)
  local data
  if self.opts.cache and self.opts.cache.read then data = self.opts.cache:read(rel) end
  if not data then
    local ok, Dataset = pcall(require, "src.core.game3.dataset")
    if ok and Dataset and Dataset.cache then data = Dataset.cache():read(rel) end
  end
  return assert(data, "roulette: missing " .. tostring(rel))
end

-- pokeemerald/src/roulette.c:1041
function UI:mainCb()
  self.m.tasks:run(self)
  self.m.ppu.sprites:animateAll()
  Kit.buildOam(self.m)
  if self.flash.enabled ~= 0 then self:flashRun() end
end

-- pokeemerald/src/roulette.c:1050
function UI:vblankCb()
  local p = self.m.ppu
  p:vblank()
  self:hwFadeTransfer()
  local st = self.st
  self:updateWheelPosition()
  p:set("BG1HOFS", band(0x200 - st.gridX, 0x1FF))
  if st.shroomishShadowTimer ~= 0 then p:set("BLDALPHA", st.shroomishShadowAlpha) end
  if st.updateGridHighlight then st.updateGridHighlight = false end
  local s = st.selectionRectDrawState
  if s == SELECT_STATE.DRAW then
    p:setBg(0, 0, self.bg0.layer)
    st.selectionRectDrawState = SELECT_STATE.UPDATE
  elseif s == SELECT_STATE.ERASE then
    p:setBg(0, 0, nil)
    for y = 7, 19 do for x = 0, 31 do self.bg0:put(x, y, 0) end end
    st.selectionRectDrawState = SELECT_STATE.WAIT
  end
  self.bg0:flush()
  self.bg1:flush()
end

-- pokeemerald/src/palette.c:728
function UI:beginHwFade(blendCnt, delay, y, targetY, reset)
  self.hw = { blendCnt = blendCnt, delay = delay, delayCounter = delay, y = y, targetY = targetY, active = true,
    reset = reset ~= 0, finishing = false, yDec = y >= targetY }
end

-- pokeemerald/src/palette.c:746
function UI:updatePaletteFade()
  local hw = self.hw
  if not hw then return self.m.ppu.palette:update() end
  if not hw.active then return 0 end
  if hw.delayCounter < hw.delay then
    hw.delayCounter = hw.delayCounter + 1
    return 2
  end
  hw.delayCounter = 0
  if not hw.yDec then
    hw.y = hw.y + 1
    if hw.y > hw.targetY then hw.finishing = true; hw.y = hw.y - 1 end
  else
    local y = hw.y
    hw.y = hw.y - 1
    if y - 1 < hw.targetY then hw.finishing = true; hw.y = hw.y + 1 end
  end
  if hw.finishing then
    if hw.reset then hw.blendCnt = 0; hw.y = 0 end
    hw.reset = false
  end
  return hw.active and 1 or 0
end

-- pokeemerald/src/palette.c:793
function UI:hwFadeTransfer()
  local hw = self.hw
  if not (hw and hw.active) then return end
  local p = self.m.ppu
  p:set("BLDCNT", band(hw.blendCnt, 0xFFFF))
  p:set("BLDY", hw.y)
  if hw.finishing then
    self.hw = nil
  end
end

function UI:fadeActive()
  return (self.hw ~= nil and self.hw.active) or self.m.ppu.palette:fadeActive()
end

-- pokeemerald/src/roulette.c:1170
function UI:loadCb()
  local m = self.m
  local p = m.ppu
  local st = m.state
  if st == 1 then
    self:initBgs()
    p:set("BLDCNT", Ppu.BLDCNT_TGT2_BG2 + Ppu.BLDCNT_TGT2_BD)
    p:set("BLDALPHA", Ppu.blendAlpha(10, 6))
  elseif st == 2 then
    p.palette:resetFade()
    p.sprites:resetData()
    m.tasks:reset()
  elseif st == 3 then
    p.palette:load(self.man.palettes.wheel, 0, 14 * 16)
  elseif st == 4 then
    self:initTableData()
  elseif st == 5 then
    local sp = p.sprites
    sp:freeAllPalettes()
    for _, pal in ipairs(self.man.palettes.sprites) do sp:loadPalette(pal.tag, pal.colors) end
    self:createWheelBallSprites()
    self:createWheelCenterSprite()
    self:createInterfaceSprites()
    self:createGridSprites()
    self:createGridBallSprites()
    self:createWheelIconSprites()
  elseif st == 6 then
    p.sprites:animateAll()
    Kit.buildOam(m)
    self:setCreditDigits(self.opts.coins or 0)
    self:setBallCounterNumLeft(BPR)
    self:setMultiplierSprite(0)
    self:drawGridBackground(0)
    self:showText("Roulette_Text_ControlsInstruction")
    m.coordOffsetX, m.coordOffsetY = -60, 0
  elseif st == 7 then
    p:set("DISPCNT", Ppu.DISPCNT_MODE_1 + Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_OBJ_ON + Ppu.DISPCNT_BG0_ON
      + Ppu.DISPCNT_BG1_ON + Ppu.DISPCNT_BG2_ON)
  elseif st == 8 then
    m:setVBlank(function() self:vblankCb() end)
    self:beginHwFade(0xFF, 0, 16, 0, 1)
    local tid = m.tasks:create(self:func("taskStartPlaying"), 0)
    self.st.playTaskId = tid
    local d = self:task(tid).data
    d[6] = BPR
    d[13] = self.opts.coins or 0
    self:tvHook("alertPlayedRoulette", self.opts.coins or 0)
    self.st.spinTaskId = m.tasks:create(self:func("taskSpinWheel"), 1)
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = st + 1
end

function UI:tvHook(fn, ...)
  if self.opts.headless then return end
  local ok, Rse = pcall(require, "src.core.game3.rse.init")
  local impl = ok and Rse.system("tv") or nil
  if impl and type(impl[fn]) == "function" then pcall(impl[fn], ...) end
end

-- pokeemerald/src/roulette.c:1087
function UI:initBgs()
  local menu = self:readTiles(self.man.menuTiles)
  self.bg0 = Kit.layer(menu, 32, 32, { headless = self.headless })
  self.bg1 = Kit.layer(menu, 64, 32, { headless = self.headless })
  local p = self.m.ppu
  p:setBg(0, 0, nil)
  p:setBg(1, 1, self.bg1.layer)
  if not self.headless then
    p:setBg(2, 2, Machine.layer({ index = self.man.wheel.index, w = self.man.wheel.w, h = self.man.wheel.h, bpp = 8 }), false)
  end
  self.gridBuffer = {}
  for i = 0, 0x7FF do self.gridBuffer[i] = 0 end
end

-- pokeemerald/src/roulette.c:1115
function UI:initTableData()
  local var = self.opts.var8004 or 0
  self.st = R.newState(self.T, var, self.opts.partyFlags or 0)
  local st = self.st
  st.spriteIds = {}
  st.selectionRectDrawState = SELECT_STATE.WAIT
  st.shroomishShadowTimer = 0
  st.shroomishShadowAlpha = 0
  st.wheelRotation = { a = 256, b = 0, c = 0, d = 256 }
  local pal = self.m.ppu.palette
  -- pokeemerald/src/roulette.c:1118
  local bgColors = { [0] = 0x7FFF, 0x7FFF }
  bgColors[0] = 24 + 4 * 32 + 10 * 1024
  bgColors[1] = 10 + 19 * 32 + 6 * 1024
  local col = st.minBet == 1 and bgColors[0] or bgColors[1]
  pal.unfaded[0], pal.unfaded[5 * 16 + 1], pal.faded[0], pal.faded[5 * 16 + 1] = col, col, col, col
  self:flashReset()
  for i = 0, NUM_SLOTS do self:flashAdd(i, self.T.flashColors[i]) end
end

-- pokeemerald/src/roulette.c:1256
function UI:taskSpinWheel()
  local st = self.st
  local t = st.wheelDelayTimer
  st.wheelDelayTimer = band(t + 1, 0xFF)
  if t == st.wheelDelay then
    st.wheelDelayTimer = 0
    st.wheelAngle = s16(st.wheelAngle - st.wheelSpeed)
    if st.wheelAngle < 0 then st.wheelAngle = 360 - st.wheelSpeed end
  end
  local sin = Kit.sin2(self.T, st.wheelAngle)
  local cos = Kit.cos2(self.T, st.wheelAngle)
  sin = Kit.cdiv(sin, 16)
  local c16 = Kit.cdiv(cos, 16)
  st.wheelRotation.a, st.wheelRotation.d = c16, c16
  st.wheelRotation.b = sin
  st.wheelRotation.c = -sin
end

-- pokeemerald/src/roulette.c:2307
function UI:updateWheelPosition()
  local st, m = self.st, self.m
  local w = st.wheelRotation
  local bx = 0x7400 - w.a * (m.coordOffsetX + 116) - w.b * (m.coordOffsetY + 80)
  local by = 0x5400 - w.c * (m.coordOffsetX + 116) - w.d * (m.coordOffsetY + 80)
  m.ppu:setAffine(2, { pa = w.a, pb = w.b, pc = w.c, pd = w.d, dx = bx, dy = by })
end

-- pokeemerald/src/roulette.c:1275
function UI:taskStartPlaying(tid)
  if self:updatePaletteFade() == 0 then
    local p = self.m.ppu
    p:set("BLDCNT", Ppu.BLDCNT_TGT2_BG2 + Ppu.BLDCNT_TGT2_BD)
    p:set("BLDALPHA", Ppu.blendAlpha(8, 8))
    local d = self:task(tid).data
    d[6] = 0
    self:resetBallDataForNewSpin(tid)
    self:resetHits()
    self:hideWheelBalls()
    self:drawGridBackground(0)
    self:setBallCounterNumLeft(BPR)
    self:startTaskAfterDelayOrInput(tid, "taskContinuePlaying", NO_DELAY, Kit.A + Kit.B)
  end
end

-- pokeemerald/src/roulette.c:1293
function UI:taskAskKeepPlaying(tid)
  self.yesNo = require("src.ui.game3.rse.scene_kit").yesNo(21, 9, { frameType = require("src.ui.game3.chrome")._frameType or 0 })
  self:showText("Roulette_Text_KeepPlaying")
  self.yesNoFuncs = { "taskContinuePlaying", "taskStopPlaying" }
  self:setFunc(tid, "taskCallYesOrNo")
end

-- pokeemerald/src/menu_helpers.c:163
function UI:taskCallYesOrNo(tid)
  local r = self:processYesNo()
  if r == 0 then
    self.sound:se("SE_SELECT")
    self.yesNo = nil
    local f = self.yesNoFuncs[1]
    self:setFunc(tid, f)
    self[f](self, tid)
  elseif r == 1 or r == -1 then
    self.sound:se("SE_SELECT")
    self.yesNo = nil
    local f = self.yesNoFuncs[2]
    self:setFunc(tid, f)
    self[f](self, tid)
  end
end

-- pokeemerald/src/menu.c:1013
function UI:processYesNo()
  local yn = self.yesNo
  if not yn then return -2 end
  if self:joyNew(Kit.A) then
    self.sound:se("SE_SELECT")
    return yn.cursor
  elseif self:joyNew(Kit.B) then
    return -1
  elseif self:joyNew(Kit.UP) then
    if yn.cursor > 0 then self.sound:se("SE_SELECT"); yn.cursor = yn.cursor - 1 end
  elseif self:joyNew(Kit.DOWN) then
    if yn.cursor < 1 then self.sound:se("SE_SELECT"); yn.cursor = yn.cursor + 1 end
  end
  return -2
end

-- pokeemerald/src/roulette.c:1302
function UI:taskContinuePlaying(tid)
  self:clearText()
  self:setFunc(tid, "taskSelectFirstEmptySquare")
end

function UI:taskStopPlaying(tid)
  self.m.tasks:destroy(self.st.spinTaskId)
  self:exitRoulette(tid)
end

-- pokeemerald/src/roulette.c:1314
function UI:updateGridSelectionRect(sel)
  local grid = self.man.gridTilemap
  local function fill(v, l, t, w, h)
    for y = t, t + h - 1 do for x = l, l + w - 1 do self.bg0:put(x, y, v) end end
  end
  local function set(src, l, t, w, h)
    local k = src
    for y = t, t + h - 1 do
      for x = l, l + w - 1 do
        self.bg0:put(x, y, grid[k] or 0)
        k = k + 1
      end
    end
  end
  fill(0, 14, 7, 16, 13)
  if sel == 0 then return end
  if sel >= 1 and sel <= 4 then
    set(281, sel * 3 + 14, 7, 3, 13)
  elseif sel == 5 or sel == 10 or sel == 15 then
    set(320, 14, math.floor((sel - 1) / 5) * 3 + 10, 16, 3)
  else
    set(272, R.getCol(sel) * 3 + 14, math.floor((sel - 1) / 5) * 3 + 7, 3, 3)
  end
end

function UI:updateGridSelection(tid)
  local sel = self:task(tid).data[4]
  self:setMultiplierSprite(sel)
  self:updateGridSelectionRect(sel)
end

-- pokeemerald/src/roulette.c:1353
function UI:taskStartHandleBetGridInput(tid)
  local st = self.st
  st.selectionRectDrawState = SELECT_STATE.DRAW
  self:updateGridSelectionRect(self:task(tid).data[4])
  st.wheelDelay = 2
  st.wheelDelayTimer = 0
  self:setFunc(tid, "taskHandleBetGridInput")
end

-- pokeemerald/src/roulette.c:1362
function UI:taskSelectFirstEmptySquare(tid)
  local d = self:task(tid).data
  d[4] = R.firstEmptySquare(self.T, self.st)
  self:resetBallDataForNewSpin(tid)
  self:drawGridBackground(d[4])
  self:setMultiplierSprite(d[4])
  self:flashSelectionOnWheel(d[4])
  d[1] = 0
  self:setFunc(tid, "taskStartHandleBetGridInput")
end

function UI:setHeaderTile(i, k)
  local s = self:spr(i + SPR.POKE_HEADERS)
  s.frame = s.anims[1][k + 1].frame
end

-- pokeemerald/src/roulette.c:1433
function UI:processBetGridInput(tid)
  local d = self:task(tid).data
  local dirPressed = false
  local passed = true
  local keys = { { Kit.UP, 0 }, { Kit.DOWN, 1 }, { Kit.LEFT, 2 }, { Kit.RIGHT, 3 } }
  for _, k in ipairs(keys) do
    if self:joyNew(k[1]) then
      dirPressed = true
      local moved, sel = R.canMoveSelectionInDir(d[4], k[2])
      d[4] = sel
      if not moved then
        passed = false
        break
      end
    end
  end
  if passed and dirPressed then
    self:drawGridBackground(d[4])
    self:updateGridSelection(tid)
    d[1] = 0
    self.sound:se("SE_SELECT")
    self:flashStop(0xFFFF)
    local pl = self.flash.palettes
    pl[FLASH_ICON].available, pl[FLASH_ICON + 1].available, pl[FLASH_ICON + 2].available = false, false, false
    self:flashSelectionOnWheel(d[4])
    for i = 0, 3 do self:setHeaderTile(i, 0) end
    if band(d[4] - 1, 0xFFFF) < 4 and band(self.st.hitFlags, self.T.grid[d[4]].flag) == 0 then
      self:setHeaderTile(d[4] - 1, 1)
    end
  end
end

-- pokeemerald/src/roulette.c:1470
function UI:taskStartSpin(tid)
  local st = self.st
  self:incrementDailyRouletteUses()
  st.selectionRectDrawState = SELECT_STATE.ERASE
  st.wheelDelay = st.minBet == 1 and 1 or 0
  st.wheelDelayTimer = 0
  self:task(tid).data[1] = 32
  self:setFunc(tid, "taskSlideGridOffscreen")
end

function UI:incrementDailyRouletteUses()
  self.dailyUses = (self.dailyUses or 0) + 1
  if self.opts.headless then return end
  local ok, Rse = pcall(require, "src.core.game3.rse.init")
  if not ok then return end
  -- pokeemerald/src/tv.c:2508
  pcall(function() Rse.setVar("VAR_DAILY_ROULETTE", band(Rse.var("VAR_DAILY_ROULETTE") + 1, 0xFFFF)) end)
end

-- pokeemerald/src/roulette.c:1483
function UI:taskPlaceBet(tid)
  local st = self.st
  local d = self:task(tid).data
  st.betSelection[st.curBallNum] = d[4]
  d[2] = R.getMultiplier(self.T, st, st.betSelection[st.curBallNum])
  self:setMultiplierSprite(st.betSelection[st.curBallNum])
  d[13] = s16(d[13] - st.minBet)
  if d[13] < 0 then d[13] = 0 end
  self:setCreditDigits(d[13])
  self:setFunc(tid, "taskStartSpin")
end

-- pokeemerald/src/roulette.c:1494
function UI:taskHandleBetGridInput(tid)
  self:processBetGridInput(tid)
  local d = self:task(tid).data
  if d[1] == 0 then
    self:updateGridSelectionRect(d[4])
    d[1] = d[1] + 1
  elseif d[1] == 30 then
    self:updateGridSelectionRect(0)
    d[1] = d[1] + 1
  elseif d[1] == 59 then
    d[1] = 0
  else
    d[1] = d[1] + 1
  end
  if self:joyNew(Kit.A) then
    if band(self.st.hitFlags, self.T.grid[d[4]].flag) ~= 0 then
      self.sound:se("SE_BOO")
    else
      self.sound:se("SE_SHOP")
      self:setFunc(tid, "taskPlaceBet")
    end
  end
end

-- pokeemerald/src/roulette.c:1531
function UI:taskSlideGridOffscreen(tid)
  local d = self:task(tid).data
  local st, m = self.st, self.m
  local t = d[1]
  d[1] = t - 1
  if t > 0 then
    if d[1] > 2 then m.coordOffsetX = m.coordOffsetX + 2 end
    st.gridX = st.gridX + 4
    if st.gridX == 104 then self:spr(SPR.MULTIPLIER).callback = nil end
  else
    self:showHideGridIcons(true, -1)
    self:showHideGridBalls(true, -1)
    self:setFunc(tid, "taskInitBallRoll")
    d[1] = 0
  end
end

-- pokeemerald/src/roulette.c:1630
function UI:taskInitBallRoll(tid)
  local d = self:task(tid).data
  local rand = self:rand()
  R.initBallRoll(self.T, self.st, d[6], d[8], self.hours, rand)
  self:setFunc(tid, "taskRollBall")
end

-- pokeemerald/src/roulette.c:1674
function UI:taskRollBall(tid)
  local st = self.st
  local d = self:task(tid).data
  st.ballRolling = true
  st.ball = self:spr(st.curBallSpriteId)
  st.ball.callback = self:sprCb("rollBallStart")
  d[6] = d[6] + 1
  d[8] = d[8] + 1
  self:setBallCounterNumLeft(BPR - d[6])
  self.sound:se("SE_ROULETTE_BALL")
  self:setFunc(tid, "taskRecordBallHit")
end

-- pokeemerald/src/roulette.c:1686
function UI:taskRecordBallHit(tid)
  local st = self.st
  local d = self:task(tid).data
  if st.ballState == BALL_STATE.ROLLING then return end
  if st.ballStuck then
    if st.ballUnstuck then
      st.ballUnstuck = false
      st.ballStuck = false
    end
    return
  end
  if d[1] == 0 then
    local hit = R.recordHit(self.T, st, d[6], st.hitSlot)
    if st.hitSlot < NUM_SLOTS then d[12] = st.winningSquare end
    local won = R.isHitInBetSelection(hit, st.betSelection[st.curBallNum])
    d[5] = won
    if won == 1 then self:flashEnable(F_FLASH_OUTER_EDGES) end
  end
  if d[1] <= 60 then
    if self:joyNew(Kit.A) then d[1] = 60 end
    d[1] = d[1] + 1
  else
    self:drawGridBackground(st.betSelection[st.curBallNum])
    self:showHideGridIcons(false, d[12])
    self:showHideGridBalls(false, d[6] - 1)
    d[1] = 32
    self:setFunc(tid, "taskSlideGridOnscreen")
  end
end

-- pokeemerald/src/roulette.c:1727
function UI:taskSlideGridOnscreen(tid)
  local d = self:task(tid).data
  local st, m = self.st, self.m
  local t = d[1]
  d[1] = t - 1
  if t > 0 then
    if d[1] > 2 then m.coordOffsetX = m.coordOffsetX - 2 end
    st.gridX = st.gridX - 4
    if st.gridX == 104 then self:spr(SPR.MULTIPLIER).callback = self:sprCb("gridSquare") end
  else
    self:showHideWinSlotCursor(d[12])
    d[1] = (d[5] == 1) and 121 or 61
    self:setFunc(tid, "taskFlashBallOnWinningSquare")
  end
end

-- pokeemerald/src/roulette.c:1750
function UI:taskFlashBallOnWinningSquare(tid)
  local d = self:task(tid).data
  local t = d[1]
  d[1] = t - 1
  if t > 1 then
    local r = math.fmod(d[1], 16)
    if r == 8 then
      self:showHideGridIcons(false, -1)
      self:showHideGridBalls(false, -1)
    elseif r == 0 then
      self:showHideGridIcons(false, d[12])
      self:showHideGridBalls(false, d[6] - 1)
    end
  else
    self:startTaskAfterDelayOrInput(tid, "taskPrintSpinResult", 30, 0)
  end
end

function UI:fanfare(name)
  self.sound:fanfare(name)
  local id = self.sound:id(name)
  Kit.fanfareTask(self.m, self.T.fanfares and self.T.fanfares[id] or 0)
end

-- pokeemerald/src/roulette.c:1774
function UI:taskTryIncrementWins(tid)
  local d = self:task(tid).data
  if d[5] == 1 or d[5] == 2 then
    if Kit.fanfareInactive(self.m) then
      d[11] = d[11] + 1
      self:setConsecutiveWins(d[11])
      self:startTaskAfterDelayOrInput(tid, "taskPrintPayout", NO_DELAY, Kit.A + Kit.B)
    end
  else
    if not self.sound:sePlaying() then
      d[11] = 0
      self:startTaskAfterDelayOrInput(tid, "taskEndTurn", NO_DELAY, Kit.A + Kit.B)
    end
  end
end

-- pokeemerald/src/roulette.c:1774
function UI:setConsecutiveWins(n)
  self.consecutiveWins = n
  local sess = self.opts.session
  if not sess then return end
  if type(sess.gameStats) ~= "table" then sess.gameStats = {} end
  local wins = tonumber(sess.gameStats[GAME_STAT_CONSECUTIVE_ROULETTE_WINS]) or 0
  if wins < n then sess.gameStats[GAME_STAT_CONSECUTIVE_ROULETTE_WINS] = n end
end

-- pokeemerald/src/roulette.c:1799
function UI:taskPrintSpinResult(tid)
  local d = self:task(tid).data
  if d[5] == 1 or d[5] == 2 then
    if d[2] == R.MAX_MULTIPLIER then
      self:fanfare("MUS_SLOTS_JACKPOT")
      self:showText("Roulette_Text_Jackpot")
    else
      self:fanfare("MUS_SLOTS_WIN")
      self:showText("Roulette_Text_ItsAHit")
    end
  else
    self.sound:se("SE_FAILURE")
    self:showText("Roulette_Text_NothingDoing")
  end
  d[1] = 0
  self:setFunc(tid, "taskTryIncrementWins")
end

-- pokeemerald/src/roulette.c:1834
function UI:taskGivePayout(tid)
  local d = self:task(tid).data
  if d[7] == 0 then
    d[13] = d[13] + 1
    self.sound:se("SE_PIN")
    self:setCreditDigits(d[13])
    if d[13] >= R.MAX_COINS then
      d[1] = 0
    else
      d[1] = d[1] - 1
      d[7] = d[7] + 1
    end
  elseif d[7] == 3 then
    self.sound:stopSe("SE_PIN")
    d[7] = 0
  else
    d[7] = d[7] + 1
  end
  if d[1] == 0 then self:startTaskAfterDelayOrInput(tid, "taskEndTurn", NO_DELAY, Kit.A + Kit.B) end
end

-- pokeemerald/src/roulette.c:1864
function UI:taskPrintPayout(tid)
  local d = self:task(tid).data
  local amount = self.st.minBet * d[2]
  self:showText("Roulette_Text_YouveWonXCoins", { tostring(amount) })
  d[1] = amount
  d[7] = 0
  self:setFunc(tid, "taskGivePayout")
end

-- pokeemerald/src/roulette.c:1878
function UI:taskEndTurn(tid)
  local d = self:task(tid).data
  self:flashStop(0xFFFF)
  local pl = self.flash.palettes
  pl[FLASH_ICON].available, pl[FLASH_ICON + 1].available, pl[FLASH_ICON + 2].available = false, false, false
  self:spr(SPR.WHEEL_ICONS + self.T.grid[d[12]].spriteIdOffset).invisible = true
  self:setFunc(tid, "taskTryPrintEndTurnMsg")
end

-- pokeemerald/src/roulette.c:1886
function UI:taskTryPrintEndTurnMsg(tid)
  local st = self.st
  local d = self:task(tid).data
  d[4] = 0
  st.betSelection[st.curBallNum] = 0
  self:drawGridBackground(0)
  self:spr(SPR.WIN_SLOT_CURSOR).invisible = true
  for i = 0, 3 do self:setHeaderTile(i, 0) end
  if d[13] >= st.minBet then
    if d[6] == BPR then
      self:showText("Roulette_Text_BoardWillBeCleared")
      self:startTaskAfterDelayOrInput(tid, "taskClearBoard", NO_DELAY, Kit.A + Kit.B)
    elseif d[13] == R.MAX_COINS then
      self:showText("Roulette_Text_CoinCaseIsFull")
      self:startTaskAfterDelayOrInput(tid, "taskAskKeepPlaying", NO_DELAY, Kit.A + Kit.B)
    else
      self:setFunc(tid, "taskAskKeepPlaying")
    end
  else
    self:showText("Roulette_Text_NoCoinsLeft")
    self:startTaskAfterDelayOrInput(tid, "taskStopPlaying", 60, Kit.A + Kit.B)
  end
end

-- pokeemerald/src/roulette.c:1933
function UI:taskClearBoard(tid)
  local d = self:task(tid).data
  d[6] = 0
  self:resetBallDataForNewSpin(tid)
  self:resetHits()
  self:hideWheelBalls()
  self:drawGridBackground(0)
  self:setBallCounterNumLeft(BPR)
  for i = 0, NUM_SLOTS - 1 do self:spr(i + SPR.WHEEL_ICONS).invisible = false end
  if d[13] == R.MAX_COINS then
    self:showText("Roulette_Text_CoinCaseIsFull")
    self:startTaskAfterDelayOrInput(tid, "taskAskKeepPlaying", NO_DELAY, Kit.A + Kit.B)
  else
    self:setFunc(tid, "taskAskKeepPlaying")
  end
end

-- pokeemerald/src/roulette.c:1962
function UI:exitRoulette(tid)
  local d = self:task(tid).data
  self:flashStop(0xFFFF)
  self:flashReset()
  self.finalCoins = d[13]
  if self.opts.setCoins then self.opts.setCoins(d[13]) end
  self.var8004Out = (d[13] < self.st.minBet) and 1 or 0
  if self.opts.setVar8004 then self.opts.setVar8004(self.var8004Out) end
  self:tvHook("tryPutFindThatGamerOnAir", d[13])
  self:beginHwFade(0xFF, 0, 0, 16, 0)
  self:setFunc(tid, "taskExitRoulette")
end

-- pokeemerald/src/roulette.c:1976
function UI:taskExitRoulette(tid)
  if self:updatePaletteFade() == 0 then
    self.m.tasks:destroy(tid)
    self.done = true
    if self.onDone then self.onDone(self) end
  end
end

-- pokeemerald/src/roulette.c:1997
function UI:taskWaitForNextTask(tid)
  local st = self.st
  if st.taskWaitDelay == 0 or self:joyNew(st.taskWaitKey) then
    self:setFunc(tid, st.nextTask)
    if st.taskWaitKey > 0 then self.sound:se("SE_SELECT") end
    st.nextTask = nil
    st.taskWaitKey = 0
    st.taskWaitDelay = 0
  end
  if st.taskWaitDelay ~= NO_DELAY then st.taskWaitDelay = band(st.taskWaitDelay - 1, 0xFFFF) end
end

-- pokeemerald/src/roulette.c:2012
function UI:startTaskAfterDelayOrInput(tid, nextName, delay, key)
  local st = self.st
  st.nextTask = nextName
  st.taskWaitDelay = delay
  if delay == NO_DELAY and key == 0 then st.taskWaitKey = 0xFFFF else st.taskWaitKey = key end
  self:setFunc(tid, "taskWaitForNextTask")
end

-- pokeemerald/src/roulette.c:2026
function UI:resetBallDataForNewSpin(tid)
  local st = self.st
  st.ballRolling, st.ballStuck, st.ballUnstuck, st.useTaillow = false, false, false, false
  for i = 0, BPR - 1 do st.betSelection[i] = 0 end
  st.curBallNum = 0
  self:task(tid).data[1] = 0
end

-- pokeemerald/src/roulette.c:2042
function UI:resetHits()
  R.resetHits(self.st)
  self:showHideGridBalls(true, -1)
end

-- pokeemerald/src/roulette.c:2133
function UI:flashSelectionOnWheel(sel)
  local st, T = self.st, self.T
  local flashFlags = 0
  if sel == 5 or sel == 10 or sel == 15 then
    for i = sel + 1, sel + 4 do
      if band(st.hitFlags, T.grid[i].flag) == 0 then flashFlags = bor(flashFlags, T.grid[i].flashFlags) end
    end
    flashFlags = band(flashFlags, bnot(F_FLASH_ICON))
    self:flashEnable(flashFlags)
    return
  end
  local iconFlash = {}
  for i = 0, 2 do
    local src = T.flashPokeIcons[i]
    iconFlash[i] = {}
    for k, v in pairs(src) do iconFlash[i][k] = v end
  end
  local numSelected = (sel >= 1 and sel <= 4) and 3 or 1
  local palOffset = R.getRowIdx(sel)
  local col = R.getCol(sel)
  local iconSlot = ({ [1] = 7, [2] = 8, [3] = 9, [4] = 10 })[col]
  if iconSlot then palOffset = self:spr(iconSlot).oam.paletteNum * 16 end
  if numSelected == 1 then
    if band(st.hitFlags, T.grid[sel].flag) == 0 then
      local ic = iconFlash[R.getRowIdx(sel)]
      ic.paletteOffset = ic.paletteOffset + palOffset
      self:flashAdd(NUM_SLOTS + 1, ic)
    else
      return
    end
  else
    for i = 0, 2 do
      local colSlot = i * 5 + sel + 5
      if band(st.hitFlags, T.grid[colSlot].flag) == 0 then
        local ic = iconFlash[R.getRowIdx(colSlot)]
        ic.paletteOffset = ic.paletteOffset + palOffset
        self:flashAdd(i + NUM_SLOTS + 1, ic)
        if numSelected == 3 then flashFlags = T.grid[colSlot].flashFlags end
        numSelected = numSelected - 1
      end
    end
    if numSelected ~= 2 then flashFlags = 0 end
  end
  flashFlags = bor(flashFlags, T.grid[sel].flashFlags)
  self:flashEnable(flashFlags)
end

-- pokeemerald/src/roulette.c:2223
function UI:drawGridBackground(sel)
  local st = self.st
  local grid = self.man.gridTilemap
  st.updateGridHighlight = true
  self:showHideGridIcons(false, 0)
  local k = 0
  for y = 7, 19 do
    for x = 14, 29 do
      self:gridPut(y * 32 + x, grid[k] or 0)
      k = k + 1
    end
  end
  if sel == 0 then return end
  local ids = {}
  if sel >= 1 and sel <= 4 then
    for i = 0, 3 do ids[#ids + 1] = i * 5 + sel end
  elseif sel == 5 or sel == 10 or sel == 15 then
    for i = 0, 4 do ids[#ids + 1] = i + sel end
  else
    ids[1] = sel
  end
  for _, id in ipairs(ids) do
    local g = self.T.grid[id]
    local off, x = g.tilemapOffset, g.x
    for j = 0, 2 do
      local y = (g.y + j) * 32
      for q = 0, 2 do self:gridPut(x + y + q, grid[(off + j) * 3 + 208 + q] or 0) end
    end
  end
end

function UI:gridPut(i, v)
  self.gridBuffer[i] = v
  self.bg1:putIndex(i, v)
end

-- pokeemerald/src/roulette.c:3504
function UI:createWheelIconSprite(def, r1, angle)
  local id, s = self:makeSprite(def, 116, 80, def.subpriority)
  s.data[0] = angle
  s.data[1] = r1
  s.coordOffsetEnabled = true
  s.animPaused = true
  s.affineAnimPaused = true
  local temp = angle
  angle = angle + DEG
  if angle >= 360 then angle = temp - (360 - DEG) end
  return id, angle
end

function UI:makeSprite(def, x, y, sub, extra)
  local d = {
    entry = def.sheet and { png = def.sheet, w = def.w, h = def.h } or nil,
    w = def.w, h = def.h, anims = def.anims, affineAnims = def.affineAnims, priority = def.priority,
    affineMode = def.affineMode, objMode = def.objMode, paletteTag = def.paletteTag,
  }
  for k, v in pairs(extra or {}) do d[k] = v end
  return Kit.createSprite(self.m, d, x, y, sub)
end

-- pokeemerald/src/roulette.c:3520
function UI:createGridSprites()
  local S = self.man.sprites
  for i = 0, 2 do
    local y = i * 24
    for j = 0, 3 do
      local id, s = self:makeSprite(S.gridIcons[j], j * 24 + 148, y + 92, 30, { callback = self:sprCb("gridSquare") })
      self.st.spriteIds[i * 4 + SPR.GRID_ICONS + j] = id
      s.animPaused = true
      y = y + 24
      if y >= 72 then y = 0 end
    end
  end
  for i = 0, 3 do
    local id, s = self:makeSprite(S.pokeHeaders[i], i * 24 + 148, 70, 30, { callback = self:sprCb("gridSquare") })
    self.st.spriteIds[i + SPR.POKE_HEADERS] = id
    s.animPaused = true
  end
  for i = 0, 2 do
    local id, s = self:makeSprite(S.colorHeaders[i], 126, i * 24 + 92, 30, { callback = self:sprCb("gridSquare") })
    self.st.spriteIds[i + SPR.COLOR_HEADERS] = id
    s.animPaused = true
  end
end

-- pokeemerald/src/roulette.c:3568
function UI:showHideGridIcons(hideAll, hideSquare)
  local st = self.st
  if hideAll then
    for i = 0, R.NUM_GRID_SELECTIONS - 1 do self:spr(i + SPR.GRID_ICONS).invisible = true end
    return
  end
  local i = 0
  while i < NUM_SLOTS do
    local s = self:spr(i + SPR.GRID_ICONS)
    local slot = self.T.slots[i]
    if band(st.hitFlags, slot.flag) == 0 then s.invisible = false
    elseif slot.gridSquare ~= hideSquare then s.invisible = true
    else s.invisible = false end
    i = i + 1
  end
  for k = i, R.NUM_GRID_SELECTIONS - 1 do self:spr(k + SPR.GRID_ICONS).invisible = false end
end

-- pokeemerald/src/roulette.c:3599
function UI:createGridBallSprites()
  for i = 0, BPR - 1 do
    local id, s = self:makeSprite(self.man.sprites.ball, 116, 20, 10, { callback = self:sprCb("gridSquare") })
    self.st.spriteIds[i + SPR.GRID_BALLS] = id
    s.invisible = true
    s.data[0] = 1
    s.oam.priority = 1
    Sprites.startAnim(s, 8)
  end
end

-- pokeemerald/src/roulette.c:3613
function UI:showHideGridBalls(hideAll, hideBall)
  local st = self.st
  for i = 0, BPR - 1 do
    local s = self:spr(i + SPR.GRID_BALLS)
    if hideAll or st.hitSquares[i] == 0 or i == hideBall then
      s.invisible = true
    else
      s.invisible = false
      local g = self.T.grid[st.hitSquares[i]]
      s.x = (g.x + 1) * 8 + 4
      s.y = (g.y + 1) * 8 + 3
    end
  end
end

-- pokeemerald/src/roulette.c:3641
function UI:showHideWinSlotCursor(sel)
  local s = self:spr(SPR.WIN_SLOT_CURSOR)
  if sel == 0 then
    s.invisible = true
  else
    s.invisible = false
    s.x = (self.T.grid[sel].x + 2) * 8
    s.y = (self.T.grid[sel].y + 2) * 8
  end
end

-- pokeemerald/src/roulette.c:3655
function UI:createWheelIconSprites()
  local angle = 15
  for i = 0, 2 do
    for j = 0, 3 do
      local def = self.man.sprites.wheelIcons[i * 4 + j]
      local id
      id, angle = self:createWheelIconSprite(def, 40, angle)
      local s = self:sprite(id)
      s.callback = self:sprCb("wheelIcon")
      s.animPaused = true
      s.affineAnimPaused = true
      self.st.spriteIds[i * 4 + SPR.WHEEL_ICONS + j] = id
    end
  end
end

-- pokeemerald/src/roulette.c:3700
function UI:createInterfaceSprites()
  local S = self.man.sprites
  local ids = self.st.spriteIds
  local id, s = self:makeSprite(S.credit, 208, 16, 4)
  ids[SPR.CREDIT] = id
  s.animPaused = true
  for i = 0, 3 do
    id, s = self:makeSprite(S.creditDigit, i * 8 + 196, 24, 0)
    ids[i + SPR.CREDIT_DIGITS] = id
    s.invisible = true
    s.animPaused = true
  end
  id, s = self:makeSprite(S.multiplier, 120, 68, 4, { callback = self:sprCb("gridSquare") })
  ids[SPR.MULTIPLIER] = id
  s.animPaused = true
  for i = 0, 2 do
    id, s = self:makeSprite(S.ballCounter, i * 16 + 192, 36, 4)
    ids[i + SPR.BALL_COUNTER] = id
    s.invisible = true
    s.animPaused = true
  end
  id, s = self:makeSprite(S.cursor, 152, 96, 9)
  ids[SPR.WIN_SLOT_CURSOR] = id
  s.oam.priority = 1
  s.animPaused = true
  s.invisible = true
end

-- pokeemerald/src/roulette.c:3735
function UI:setCreditDigits(num)
  local d = 1000
  local printZero = false
  for i = 0, 3 do
    local digit = math.floor(num / d)
    local s = self:spr(i + SPR.CREDIT_DIGITS)
    s.invisible = true
    if digit > 0 or printZero or i == 3 then
      s.invisible = false
      local cmd = s.anims[1][digit + 1]
      s.frame = cmd and cmd.frame or s.frame
      printZero = true
    end
    num = num % d
    d = math.floor(d / 10)
  end
end

-- pokeemerald/src/roulette.c:3785
function UI:setMultiplierSprite(sel)
  local s = self:spr(SPR.MULTIPLIER)
  s.animCmdIndex = R.multiplierAnimId(self.T, self.st, sel)
  s.frame = s.anims[1][s.animCmdIndex + 1].frame
end

-- pokeemerald/src/roulette.c:3792
function UI:setBallCounterNumLeft(n)
  local t = self.st.minBet == 1 and 2 or 0
  local function set(slot, k)
    local s = self:spr(slot)
    s.frame = s.anims[1][k + 1].frame
  end
  if n == 6 then
    for i = 0, 2 do
      self:spr(i + SPR.BALL_COUNTER).invisible = false
      set(i + SPR.BALL_COUNTER, 0)
    end
  elseif n == 5 then set(SPR.BALL_COUNTER + 2, t + 1)
  elseif n == 4 then set(SPR.BALL_COUNTER + 2, t + 2)
  elseif n == 3 then set(SPR.BALL_COUNTER + 1, t + 1)
  elseif n == 2 then set(SPR.BALL_COUNTER + 1, t + 2)
  elseif n == 1 then set(SPR.BALL_COUNTER, t + 1)
  else
    for i = 0, 2 do set(i + SPR.BALL_COUNTER, t + 2) end
  end
end

-- pokeemerald/src/roulette.c:3850
function UI:createWheelCenterSprite()
  local id, s = self:makeSprite(self.man.sprites.center, 116, 80, 81, { callback = self:sprCb("wheelCenter") })
  s.data[0] = self.st.wheelAngle
  s.data[1] = 0
  s.animPaused = true
  s.affineAnimPaused = true
  s.coordOffsetEnabled = true
  self.st.spriteIds[SPR.WHEEL_CENTER] = id
end

-- pokeemerald/src/roulette.c:3879
function UI:createWheelBallSprites()
  for i = 0, BPR - 1 do
    local id, s = self:makeSprite(self.man.sprites.ball, 116, 80, 57 - i)
    self.st.spriteIds[i] = id
    if id ~= MAX_SPRITES then
      s.invisible = true
      s.coordOffsetEnabled = true
    end
  end
end

-- pokeemerald/src/roulette.c:3893
function UI:hideWheelBalls()
  local base = self.st.spriteIds[SPR.WHEEL_BALLS]
  for i = 0, BPR - 1 do
    local s = self:sprite(base + i)
    s.invisible = true
    s.callback = nil
    Sprites.startAnim(s, 0)
    for j = 0, 7 do s.data[j] = 0 end
  end
end

local SCB = {}

function UI:sprCb(name)
  self.scb = self.scb or {}
  local f = self.scb[name]
  if not f then
    f = function(s) SCB[name](self, s) end
    self.scb[name] = f
  end
  return f
end

-- pokeemerald/src/roulette.c:3845
function SCB.gridSquare(self, s) s.x2 = self.st.gridX end

-- pokeemerald/src/roulette.c:3680
function SCB.wheelIcon(self, s)
  local angle = s16(self.st.wheelAngle + s.data[0])
  if angle >= 360 then angle = angle - 360 end
  local sin = Kit.sin2(self.T, angle)
  local cos = Kit.cos2(self.T, angle)
  s.x2 = s16(arshift(sin * s.data[1], 12))
  s.y2 = s16(arshift(-cos * s.data[1], 12))
  sin = Kit.cdiv(sin, 16)
  cos = Kit.cdiv(cos, 16)
  local m = self.m.ppu.sprites
  m:setMatrix(s.oam.matrixNum, cos, sin, -sin, cos)
end

-- pokeemerald/src/roulette.c:3869
function SCB.wheelCenter(self, s)
  local w = self.st.wheelRotation
  self.m.ppu.sprites:setMatrix(s.oam.matrixNum, w.a, w.b, w.c, w.a)
end

-- pokeemerald/src/roulette.c:3934
local function updateBallRelativeWheelAngle(self, s)
  local st = self.st
  if st.wheelAngle > s.data[3] then
    s.data[6] = 360 - st.wheelAngle + s.data[3]
    if s.data[6] >= 360 then s.data[6] = s.data[6] - 360 end
  else
    s.data[6] = s.data[3] - st.wheelAngle
  end
  return s.data[6]
end

-- pokeemerald/src/roulette.c:3950
local function updateSlotBelowBall(self, s)
  self.st.hitSlot = band(trunc(F(updateBallRelativeWheelAngle(self, s) / F(DEG))), 0xFF)
  return self.st.hitSlot
end

-- pokeemerald/src/roulette.c:3956
local function getBallDistanceToSlotMidpoint(self, s)
  local into = math.fmod(updateBallRelativeWheelAngle(self, s), DEG)
  local mid = R.SLOT_MIDPOINT
  if into == mid then
    s.data[2] = 0
  elseif into >= mid then
    s.data[2] = (DEG - 1) + mid - into
  else
    s.data[2] = mid - into
  end
  return s.data[2]
end

-- pokeemerald/src/roulette.c:3980
local function updateBallPos(self, s)
  local st = self.st
  st.ballAngleSpeed = F(st.ballAngleSpeed + st.ballAngleAccel)
  st.ballAngle = F(st.ballAngle + st.ballAngleSpeed)
  if st.ballAngle >= 360 then
    st.ballAngle = F(st.ballAngle - 360)
  elseif st.ballAngle < 0 then
    st.ballAngle = F(st.ballAngle + 360)
  end
  s.data[3] = s16(trunc(st.ballAngle))
  st.ballFallSpeed = F(st.ballFallSpeed + st.ballFallAccel)
  st.ballDistToCenter = F(st.ballDistToCenter + st.ballFallSpeed)
  s.data[4] = s16(trunc(st.ballDistToCenter))
  local sin = Kit.sin2(self.T, s.data[3])
  local cos = Kit.cos2(self.T, s.data[3])
  s.x2 = s16(arshift(sin * s.data[4], 12))
  s.y2 = s16(arshift(-cos * s.data[4], 12))
  if self.sound:sePlaying() then self.sound:setSePan(s.x2) end
end
UI.updateBallPos = updateBallPos

-- pokeemerald/src/roulette.c:3918
local function landBall(self, s)
  local st = self.st
  st.ballState = BALL_STATE.LANDED
  st.ballRolling = false
  Sprites.startAnim(s, s.animCmdIndex + 3)
  updateSlotBelowBall(self, s)
  s.data[4] = 30
  updateBallRelativeWheelAngle(self, s)
  s.data[6] = math.floor(s.data[6] / DEG) * DEG + 15
  s.callback = self:sprCb("ballLandInSlot")
  self.sound:se("SE_BRIDGE_WALK")
end

-- pokeemerald/src/roulette.c:4007
function SCB.ballLandInSlot(self, s)
  s.data[3] = s16(self.st.wheelAngle + s.data[6])
  if s.data[3] >= 360 then s.data[3] = s.data[3] - 360 end
  local sin = Kit.sin2(self.T, s.data[3])
  local cos = Kit.cos2(self.T, s.data[3])
  s.x2 = s16(arshift(sin * s.data[4], 12))
  s.y2 = s16(arshift(-cos * s.data[4], 12) + self.m.coordOffsetY)
end

-- pokeemerald/src/roulette.c:4020
function SCB.unstickShroomishBallFall(self, s)
  local st = self.st
  updateBallPos(self, s)
  s.data[2] = s.data[2] + 1
  s.invisible = s.data[4] < -132 or s.data[4] > 80
  if s.data[2] >= DEG then
    local land
    if s.data[0] == 0 then land = st.ballDistToCenter <= F(st.varA0 - 2)
    else land = st.ballDistToCenter >= F(st.varA0 - 2) end
    if land then
      landBall(self, s)
      st.ballFallAccel, st.ballFallSpeed = F(0), F(0)
      st.ballAngleSpeed = F(-1)
    end
  end
end

-- pokeemerald/src/roulette.c:4052
function SCB.unstickShroomish(self, s)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  updateBallPos(self, s)
  local slotOffset, dist, speed
  if s.data[3] == 0 then
    if s.data[0] == 1 then return end
    slotOffset = F(s.data[7])
    dist = F(F(slotOffset * tbl.randDistanceHigh) + (tbl.randDistanceLow - 1))
    speed = F(slotOffset / tbl.shroomish.fallSlowdown)
  elseif s.data[3] == 180 then
    if s.data[0] == 0 then return end
    slotOffset = F(s.data[7])
    dist = F(F(slotOffset * tbl.randDistanceHigh) + (tbl.randDistanceLow - 1))
    speed = F(-F(slotOffset / tbl.shroomish.fallSlowdown))
  else
    return
  end
  st.varA0 = st.ballDistToCenter
  st.ballFallSpeed = speed
  st.ballFallAccel = F(-F(F(F(speed * 2) / dist) + F(2 / F(dist * dist))))
  st.ballAngleSpeed = F(0)
  s.animPaused = false
  s.animNum = 0
  s.animBeginning = true
  s.animEnded = false
  s.callback = self:sprCb("unstickShroomishBallFall")
  s.data[2] = 0
end

-- pokeemerald/src/roulette.c:4098
function SCB.unstickTaillowDrop(self, s)
  s.y2 = s16(trunc(F(F(s.data[2] * F(0.05)) * s.data[2]))) - 45
  s.data[2] = s.data[2] + 1
  if s.data[2] >= DEG and s.y2 >= 0 then
    landBall(self, s)
    self.st.ballUnstuck = true
  end
end

-- pokeemerald/src/roulette.c:4109
function SCB.unstickTaillowPickUp(self, s)
  local mon = self:spr(SPR.CLEAR_MON)
  local t = s.data[2]
  s.data[2] = t + 1
  if t < 45 then
    s.y2 = s.y2 - 1
    if s.data[2] == 45 and mon.animCmdIndex == 1 then s.y2 = s.y2 + 1 end
  else
    if s.data[2] < s.data[7] then
      if mon.animDelayCounter == 0 then
        if mon.animCmdIndex == 1 then s.y2 = s.y2 + 1 else s.y2 = s.y2 - 1 end
      end
    else
      s.animPaused = false
      s.animNum = 1
      s.animBeginning = true
      s.animEnded = false
      s.data[2] = 0
      s.callback = self:sprCb("unstickTaillowDrop")
      self.sound:se("SE_BALL_THROW")
    end
  end
end

-- pokeemerald/src/roulette.c:4145
function SCB.unstickTaillow(self, s)
  updateBallPos(self, s)
  if s.data[3] == 90 then
    if s.data[0] ~= 1 then
      s.callback = self:sprCb("unstickTaillowPickUp")
      s.data[2] = 0
    end
  elseif s.data[3] == 270 then
    if s.data[0] ~= 0 then
      s.callback = self:sprCb("unstickTaillowPickUp")
      s.data[2] = 0
    end
  end
end

-- pokeemerald/src/roulette.c:4170
function SCB.unstickBall(self, s)
  updateBallPos(self, s)
  if not self.st.useTaillow then
    self:createShroomishSprite(s)
    s.callback = self:sprCb("unstickShroomish")
  else
    self:createTaillowSprite(s)
    s.callback = self:sprCb("unstickTaillow")
  end
end

-- pokeemerald/src/roulette.c:4189
function SCB.rollBallTryLandAdjacent(self, s)
  updateBallPos(self, s)
  local t = s.data[2]
  s.data[2] = t - 1
  if t == 16 then self.st.ballFallSpeed = F(self.st.ballFallSpeed * -1) end
  if s.data[2] == 0 then
    if s.data[0] == 0 then
      landBall(self, s)
    else
      s.animPaused = true
      self.sound:se("SE_BALL_BOUNCE_1")
      self:setBallStuck(s)
    end
  end
end

-- pokeemerald/src/roulette.c:4213
function SCB.rollBallTryLand(self, s)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  updateBallPos(self, s)
  s.data[2] = 0
  updateSlotBelowBall(self, s)
  if band(self.T.slots[st.hitSlot].flag, st.hitFlags) == 0 then
    landBall(self, s)
    return
  end
  self.sound:se("SE_BALL_BOUNCE_1")
  local fallRight = band(self:rand(), 1) ~= 0
  local slotId
  if fallRight then
    st.ballAngleSpeed = F(0)
    slotId = (st.hitSlot + 1) % NUM_SLOTS
    st.stuckHitSlot = slotId
  else
    st.ballAngleSpeed = F(tbl.var1C * 2)
    slotId = (st.hitSlot + NUM_SLOTS - 1) % NUM_SLOTS
    st.stuckHitSlot = st.hitSlot
  end
  if band(self.T.slots[slotId].flag, st.hitFlags) ~= 0 then
    s.data[0] = 1
    s.data[2] = tbl.randDistanceLow
  else
    s.data[0] = 0
    if st.tableId ~= 0 then
      s.data[2] = tbl.randDistanceHigh
    else
      s.data[2] = tbl.randDistanceLow
      st.ballAngleSpeed = fallRight and F(0.5) or F(-1.5)
    end
  end
  st.ballFallSpeed = F(0.085)
  s.callback = self:sprCb("rollBallTryLandAdjacent")
  s.data[1] = 5
end

-- pokeemerald/src/roulette.c:4272
function SCB.rollBallSlow(self, s)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  updateBallPos(self, s)
  if st.ballAngleSpeed > F(0.5) then return end
  updateSlotBelowBall(self, s)
  if getBallDistanceToSlotMidpoint(self, s) == 0 then
    st.ballAngleAccel = F(0)
    st.ballAngleSpeed = F(st.ballAngleSpeed - F(F(tbl.wheelSpeed) / (tbl.wheelDelay + 1)))
    s.data[1] = 4
    s.callback = self:sprCb("rollBallTryLand")
  elseif st.ballAngleAccel ~= 0 then
    if st.ballAngleSpeed < 0 then
      st.ballAngleAccel = F(0)
      st.ballAngleSpeed = F(0)
      st.ballFallSpeed = F(st.ballFallSpeed / 1.2)
    end
  end
end

-- pokeemerald/src/roulette.c:4302
function SCB.rollBallMedium(self, s)
  local st = self.st
  updateBallPos(self, s)
  if st.ballDistToCenter > F(40) then return end
  st.ballFallSpeed = F(-F(F(4) / F(st.ballTravelDistSlow)))
  st.ballAngleAccel = F(-F(st.ballAngleSpeed / F(st.ballTravelDistSlow)))
  s.animNum = 2
  s.animBeginning = true
  s.animEnded = false
  s.data[1] = 3
  s.callback = self:sprCb("rollBallSlow")
end

-- pokeemerald/src/roulette.c:4317
function SCB.rollBallFast(self, s)
  local st = self.st
  updateBallPos(self, s)
  if st.ballDistToCenter > F(60) then return end
  self.sound:se("SE_ROULETTE_BALL2")
  st.ballFallSpeed = F(-F(F(20) / F(st.ballTravelDistMed)))
  st.ballAngleAccel = F(F(F(1) - st.ballAngleSpeed) / F(st.ballTravelDistMed))
  s.animNum = 1
  s.animBeginning = true
  s.animEnded = false
  s.data[1] = 2
  s.callback = self:sprCb("rollBallMedium")
end

-- pokeemerald/src/roulette.c:4333
function SCB.rollBallStart(self, s)
  s.data[1] = 1
  s.data[2] = 0
  updateBallPos(self, s)
  s.invisible = false
  s.callback = self:sprCb("rollBallFast")
end

-- pokeemerald/src/roulette.c:4347
function UI:createShroomishSprite(ball)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  local S = self.man.sprites
  local coords = { [0] = { 116, 44 }, [1] = { 116, 112 } }
  local t = band(ball.data[7] - 2, 0xFFFF)
  local ids = st.spriteIds
  ids[SPR.CLEAR_MON] = self:makeSprite(S.shroomish, 36, -12, 50)
  ids[SPR.CLEAR_MON_SHADOW_1] = self:makeSprite(S.ballShadow, coords[ball.data[0]][1], coords[ball.data[0]][2], 59)
  ids[SPR.CLEAR_MON_SHADOW_2] = self:makeSprite(S.monShadow, 36, 140, 51, { callback = self:sprCb("shroomish") })
  self:spr(SPR.CLEAR_MON_SHADOW_2).oam.objMode = Sprites.OBJ_BLEND
  for i = 0, 2 do
    local s = self:spr(i + SPR.CLEAR_MON)
    s.coordOffsetEnabled = false
    s.invisible = true
    s.animPaused = true
    s.affineAnimPaused = true
    s.data[4] = ids[SPR.CLEAR_MON]
    s.data[5] = ids[SPR.CLEAR_MON_SHADOW_1]
    s.data[6] = ids[SPR.CLEAR_MON_SHADOW_2]
    s.data[2] = s16(t)
    s.data[3] = s16(ball.data[7] * tbl.randDistanceHigh + (tbl.randDistanceLow + 0xFFFF))
  end
  self:spr(SPR.CLEAR_MON_SHADOW_1).coordOffsetEnabled = true
  st.ball = ball
end

-- pokeemerald/src/roulette.c:4380
function UI:createTaillowSprite(ball)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  local S = self.man.sprites
  local coords = { [0] = { 256, 84 }, [1] = { -16, 84 } }
  local t = s16(ball.data[7] - 2)
  local ids = st.spriteIds
  local left = ball.data[0]
  ids[SPR.CLEAR_MON] = self:makeSprite(S.taillow, coords[left][1], coords[left][2], 50, { callback = self:sprCb("taillow") })
  Sprites.startAnim(self:spr(SPR.CLEAR_MON), left)
  ids[SPR.CLEAR_MON_SHADOW_1] = self:makeSprite(S.taillowShadow, coords[left][1], coords[left][2], 51,
    { callback = self:sprCb("taillow") })
  local sh = self:spr(SPR.CLEAR_MON_SHADOW_1)
  sh.affineAnimPaused = true
  sh.animPaused = true
  ball.data[7] = s16(t * tbl.randDistanceHigh + (tbl.taillow.baseDropDelay + 45))
  for i = 0, 1 do
    local s = self:spr(SPR.CLEAR_MON + i)
    s.data[4] = ids[SPR.CLEAR_MON]
    s.data[5] = ids[SPR.CLEAR_MON_SHADOW_1]
    s.data[6] = ids[SPR.CLEAR_MON_SHADOW_1]
    s.data[2] = t
    s.data[3] = s16(ball.data[7] - 45)
  end
  st.ball = ball
end

-- pokeemerald/src/roulette.c:4407
function UI:setBallStuck(s)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  local numCandidates, maxSlotToCheck, betSlotId = 0, 5, 0
  local candidates = {}
  local rand = self:rand()
  st.ballState = BALL_STATE.STUCK
  st.ballStuck = true
  st.ballUnstuck = false
  st.hitSlot = 0xFF
  st.ballAngle = F(s.data[3])
  st.ballFallSpeed = F(0)
  st.ballAngleSpeed = F(tbl.var1C)
  local angle = band((st.tableId * DEG + 33) + (1 - (st.useTaillow and 1 or 0)) * 15, 0xFFFF)
  for i = 0, 3 do
    if angle < s.data[3] and s.data[3] <= angle + 90 then
      s.data[0] = math.floor(i / 2)
      st.useTaillow = (i % 2) == 1
      break
    end
    if i == 3 then
      s.data[0] = 1
      st.useTaillow = true
      break
    end
    angle = angle + 90
  end
  local C = self.opts.constants or require("src.core.game3.constants").of("emerald")
  if st.useTaillow then
    self.sound:cry(C:require("species", "SPECIES_TAILLOW"), s.data[0] ~= 0 and -63 or 63)
  else
    self.sound:cry(C:require("species", "SPECIES_SHROOMISH"), -63)
  end
  local slotsToSkip = 2
  local slotId = (st.stuckHitSlot + 2) % NUM_SLOTS
  if st.useTaillow and st.tableId == 1 then maxSlotToCheck = maxSlotToCheck + 6
  else maxSlotToCheck = maxSlotToCheck + slotsToSkip end
  local bet = self.T.grid[st.betSelection[st.curBallNum]]
  for i = slotsToSkip, maxSlotToCheck - 1 do
    if band(st.hitFlags, self.T.slots[slotId].flag) == 0 then
      candidates[numCandidates] = i
      numCandidates = numCandidates + 1
      if betSlotId == 0 and band(self.T.slots[slotId].flag, bet.inSelectionFlags) ~= 0 then betSlotId = i end
    end
    slotId = (slotId + 1) % NUM_SLOTS
  end
  if band((st.useTaillow and 1 or 0) + 1, st.partySpeciesFlags) ~= 0 then
    if betSlotId ~= 0 and (rand % 256) < 192 then
      s.data[7] = betSlotId
    else
      s.data[7] = candidates[rand % numCandidates]
    end
  else
    s.data[7] = candidates[rand % numCandidates]
  end
  s.callback = self:sprCb("unstickBall")
end

-- pokeemerald/src/roulette.c:4513
function SCB.shroomishExit(self, s)
  local t = s.data[1]
  s.data[1] = t + 1
  if t >= s.data[3] then
    s.x = s.x - 2
    if s.x < -16 then
      if not self.st.ballUnstuck then self.st.ballUnstuck = true end
      Kit.destroySprite(self.m, s)
      self.st.shroomishShadowTimer = 0
      self.st.shroomishShadowAlpha = self.T.shroomishShadowAlphas[0]
    end
  end
end

-- pokeemerald/src/roulette.c:4531
function SCB.shroomishShakeScreen(self, s)
  local offsets = { [0] = { [0] = -1, 0, 1, 0 }, { [0] = -2, 0, 2, 0 }, { [0] = -3, 0, 3, 0 } }
  local t = s.data[1]
  s.data[1] = t + 1
  if t < s.data[3] then
    if band(s.data[1], 1) ~= 0 then
      local v = offsets[math.floor(s.data[2] / 2)][s.data[7]]
      self.m.coordOffsetY = s16(band(v, 0xFFFF))
      s.data[7] = (s.data[7] + 1) % 4
    end
    s.invisible = not s.invisible
  else
    self.m.coordOffsetY = 0
    self:spr(SPR.CLEAR_MON).animPaused = false
    Kit.destroySprite(self.m, s)
  end
end

-- pokeemerald/src/roulette.c:4560
function SCB.shroomishFall(self, s)
  local st = self.st
  s.data[1] = s.data[1] + 1
  local timer = F(s.data[1])
  s.y2 = s16(trunc(F(F(timer * F(0.039)) * timer)))
  st.shroomishShadowAlpha = self.T.shroomishShadowAlphas[math.floor((st.shroomishShadowTimer - 1) / 2)]
  if st.shroomishShadowTimer < 10 * 2 - 1 then st.shroomishShadowTimer = st.shroomishShadowTimer + 1 end
  if s.data[1] > 60 then
    s.data[1] = 0
    s.callback = self:sprCb("shroomishExit")
    local ms = self:sprite(s.data[6])
    ms.callback = self:sprCb("shroomishExit")
    ms.data[1] = -2
    local bs = self:sprite(s.data[5])
    bs.invisible = false
    bs.callback = self:sprCb("shroomishShakeScreen")
    self.sound:se("SE_M_STRENGTH")
  end
end

-- pokeemerald/src/roulette.c:4581
function SCB.shroomish(self, s)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  local ball = st.ball
  if s.data[7] == 0 then
    local want = tbl.shroomish.startAngle + (ball.data[0] ~= 0 and 180 or 0)
    if ball.data[3] ~= want then return end
    s.invisible = false
    s.data[7] = s.data[7] + 1
    self.sound:se("SE_FALL")
    st.shroomishShadowTimer = 1
    st.shroomishShadowAlpha = self.T.shroomishShadowAlphas[0]
  else
    st.shroomishShadowAlpha = self.T.shroomishShadowAlphas[math.floor((st.shroomishShadowTimer - 1) / 2)]
    if st.shroomishShadowTimer < 19 then st.shroomishShadowTimer = st.shroomishShadowTimer + 1 end
    local want = tbl.shroomish.dropAngle + (ball.data[0] ~= 0 and 180 or 0)
    if ball.data[3] ~= want then return end
    local mon = self:sprite(s.data[4])
    mon.callback = self:sprCb("shroomishFall")
    mon.invisible = false
    s.callback = nil
    s.data[7] = 0
  end
end

-- pokeemerald/src/roulette.c:4631
function SCB.taillowShadowFlash(self, s) s.invisible = not s.invisible end

-- pokeemerald/src/roulette.c:4636
function SCB.taillowFlyAway(self, s)
  if s.y > -16 then
    s.y = s.y - 1
  else
    s.callback = nil
    s.invisible = true
    s.animPaused = true
    self.sound:stopSe("SE_TAILLOW_WING_FLAP")
    Kit.destroySprite(self.m, s)
    Kit.destroySprite(self.m, self:spr(SPR.CLEAR_MON_SHADOW_1))
  end
end

-- pokeemerald/src/roulette.c:4654
function SCB.taillowPickUpBall(self, s)
  if s.data[1] >= 0 then
    s.data[1] = s.data[1] - 1
    s.y = s.y - 1
    if s.data[1] == 0 and s.animCmdIndex == 1 then s.y2 = s.y2 + 1 end
  elseif s.data[3] >= 0 then
    s.data[3] = s.data[3] - 1
    if s.animDelayCounter == 0 then
      if s.animCmdIndex == 1 then s.y2 = s.y2 + 1 else s.y2 = s.y2 - 1 end
    end
  else
    self.sound:se("SE_FALL")
    Sprites.startAnim(s, self.st.ball.data[0] + 4)
    s.callback = self:sprCb("taillowFlyAway")
    self:sprite(s.data[6]).affineAnimPaused = false
  end
end

-- pokeemerald/src/roulette.c:4686
function SCB.taillowFlyIn(self, s)
  local xMove = { [0] = -1, 1 }
  local yMove = { [0] = { 2, 0 }, { 2, 0 }, { 2, -1 }, { 2, -1 }, { 2, -1 }, { 2, -1 }, { 2, -2 }, { 2, -2 } }
  local left = self.st.ball.data[0]
  local t = s.data[1]
  s.data[1] = t - 1
  if t > 7 then
    s.x = s.x + xMove[left] * 2
    if self.sound:sePlaying() then self.sound:setSePan(-math.floor((116 - s.x) / 2)) end
  elseif s.data[1] >= 0 then
    local row = yMove[7 - s.data[1]]
    s.x = s.x + xMove[left] * row[1]
    s.y = s.y + row[2]
  else
    self.sound:se("SE_TAILLOW_WING_FLAP")
    local C = self.opts.constants or require("src.core.game3.constants").of("emerald")
    self.sound:cry(C:require("species", "SPECIES_TAILLOW"), left == 0 and 63 or -63)
    Sprites.startAnim(s, left + 2)
    s.data[1] = 45
    s.callback = self:sprCb("taillowPickUpBall")
  end
end

-- pokeemerald/src/roulette.c:4731
function SCB.taillowShadowFlyIn(self, s)
  local move = { [0] = -1, 1 }
  local t = s.data[1]
  s.data[1] = t - 1
  if t >= 0 then
    s.x = s.x + move[self.st.ball.data[0]] * 2
    local sh = self:sprite(s.data[6])
    sh.invisible = not sh.invisible
  else
    s.callback = self:sprCb("taillowShadowFlash")
  end
end

-- pokeemerald/src/roulette.c:4746
function SCB.taillow(self, s)
  local st = self.st
  local tbl = self.T.rouletteTables[st.tableId]
  local ball = st.ball
  local n
  if ball.data[0] == 0 then
    if ball.data[3] ~= tbl.taillow.rightStartAngle + 90 then return end
    n = 52
  else
    if ball.data[3] ~= tbl.taillow.leftStartAngle + 270 then return end
    n = 46
  end
  local sh, mon = self:sprite(s.data[6]), self:sprite(s.data[4])
  sh.data[1] = n
  mon.data[1] = n
  sh.callback = self:sprCb("taillowShadowFlyIn")
  mon.callback = self:sprCb("taillowFlyIn")
  self.sound:se("SE_FALL")
end

-- pokeemerald/src/palette_util.c:10
function UI:flashReset()
  self.flash = { enabled = 0, flags = 0, palettes = {} }
  for i = 0, 15 do self.flash.palettes[i] = { available = false, state = 0 } end
end

-- pokeemerald/src/palette_util.c:17
function UI:flashAdd(id, settings)
  local p = self.flash.palettes[id]
  if id >= 16 or p.available then return 0xFF end
  p.settings = {}
  for k, v in pairs(settings) do p.settings[k] = v end
  p.state = 0
  p.available = true
  p.fadeCycleCounter = 0
  p.delayCounter = 0
  p.colorDelta = (p.settings.colorDeltaDir < 0) and -1 or 1
  return id
end

-- pokeemerald/src/palette_util.c:53
function UI:flashFadePalette(p)
  local pal = self.m.ppu.palette
  local s = p.settings
  for i = 0, s.numColors - 1 do
    local o = s.paletteOffset + i
    local f, u = pal.faded[o], pal.unfaded[o]
    local fr, fg, fb = band(f, 31), band(rshift(f, 5), 31), band(rshift(f, 10), 31)
    local ur, ug, ub = band(u, 31), band(rshift(u, 5), 31), band(rshift(u, 10), 31)
    local dlt = p.colorDelta
    if p.state == 1 then
      if fr + dlt >= 0 and fr + dlt < 32 then fr = fr + dlt end
      if fg + dlt >= 0 and fg + dlt < 32 then fg = fg + dlt end
      if fb + dlt >= 0 and fb + dlt < 32 then fb = fb + dlt end
    elseif p.state == 2 then
      if dlt < 0 then
        if fr + dlt >= ur then fr = fr + dlt end
        if fg + dlt >= ug then fg = fg + dlt end
        if fb + dlt >= ub then fb = fb + dlt end
      else
        if fr + dlt <= ur then fr = fr + dlt end
        if fg + dlt <= ug then fg = fg + dlt end
        if fb + dlt <= ub then fb = fb + dlt end
      end
    end
    pal.faded[o] = bor(fr, lshift(fg, 5), lshift(fb, 10), band(f, 0x8000))
  end
  local c = p.fadeCycleCounter
  p.fadeCycleCounter = c + 1
  if band(c, 0xFFFFFFFF) ~= band(s.numFadeCycles, 0xFFFFFFFF) then return 0 end
  p.fadeCycleCounter = 0
  p.colorDelta = -p.colorDelta
  if p.state == 1 then p.state = 2 else p.state = 1 end
  return 1
end

-- pokeemerald/src/palette_util.c:114
function UI:flashFlashPalette(p)
  local pal = self.m.ppu.palette
  local s = p.settings
  if p.state == 1 then
    for i = 0, s.numColors - 1 do pal.faded[s.paletteOffset + i] = s.color end
    p.state = 2
  elseif p.state == 2 then
    for i = 0, s.numColors - 1 do pal.faded[s.paletteOffset + i] = pal.unfaded[s.paletteOffset + i] end
    p.state = 1
  end
  return 1
end

-- pokeemerald/src/palette_util.c:135
function UI:flashRun()
  local fl = self.flash
  for i = 0, 15 do
    if band(rshift(fl.flags, i), 1) ~= 0 then
      local p = fl.palettes[i]
      p.delayCounter = band(p.delayCounter - 1, 0xFF)
      if p.delayCounter == 0xFF then
        if band(p.settings.color, FLASHUTIL_USE_EXISTING_COLOR) ~= 0 then self:flashFadePalette(p)
        else self:flashFlashPalette(p) end
        p.delayCounter = p.settings.delay
      end
    end
  end
end

-- pokeemerald/src/palette_util.c:159
function UI:flashEnable(flags)
  local fl = self.flash
  fl.enabled = band(fl.enabled + 1, 0xFF)
  for i = 0, 15 do
    if band(rshift(flags, i), 1) ~= 0 and fl.palettes[i].available then
      fl.flags = bor(fl.flags, lshift(1, i))
      fl.palettes[i].state = 1
    end
  end
end

-- pokeemerald/src/palette_util.c:177
function UI:flashStop(flags)
  local fl = self.flash
  local pal = self.m.ppu.palette
  for i = 0, 15 do
    local p = fl.palettes[i]
    if band(rshift(fl.flags, i), 1) ~= 0 and p.available and band(rshift(flags, i), 1) ~= 0 then
      for k = 0, p.settings.numColors - 1 do
        pal.faded[p.settings.paletteOffset + k] = pal.unfaded[p.settings.paletteOffset + k]
      end
      p.state = 0
      p.fadeCycleCounter = 0
      p.delayCounter = 0
      p.colorDelta = (p.settings.colorDeltaDir < 0) and -1 or 1
    end
  end
  if flags == 0xFFFF then
    fl.enabled = 0
    fl.flags = 0
  else
    fl.flags = band(fl.flags, bnot(flags))
  end
end

function UI:showText(key, vars)
  self.text = { key = key, text = Kit.text(key, vars) }
end

function UI:clearText()
  self.text = nil
  self.yesNo = nil
end

function UI:frame(inp)
  if self.done then return end
  self.frames = self.frames + 1
  local m = self.m
  m.vblankCounter1 = m.vblankCounter1 + 1
  if m.vblankCb then m.vblankCb(m) end
  if self.vblankRandom then self.random() end
  Kit.readKeys(m, inp)
  if m.cb2 then m.cb2(m) end
end

function UI:draw()
  if self.headless then return end
  if self.hw then
    self.m.ppu:set("BLDCNT", band(self.hw.blendCnt, 0xFFFF))
    self.m.ppu:set("BLDY", self.hw.y)
  end
  self.m.ppu:draw(0, 0)
  local fade = self.hw and self.hw.active and self.hw.y or 0
  if self.text then
    local SceneKit = require("src.ui.game3.rse.scene_kit")
    local Chrome = require("src.ui.game3.chrome")
    local colors = SceneKit.messageColors("std_menu")
    SceneKit.userFrame(3, 15, 24, 4, Chrome._frameType or 0, colors.bg)
    Kit.drawText(self.text.text, 3 * 8, 15 * 8 + 1, colors, fade)
  end
  if self.yesNo then self.yesNo:draw() end
end

local Host = {}
UI.Host = Host

function UI.open(opts, constructor)
  local Stack = require("src.ui.game3.stack")
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  local screen = (constructor or UI.new)(opts)
  Host._screen = screen
  Host._step = SceneKit.stepper()
  local userDone = opts and opts.onDone
  screen.onDone = function()
    Host._screen = nil
    Stack.pop("rse_roulette")
    if userDone then userDone(screen) end
  end
  Stack.push("rse_roulette", Host, { hideBelow = true, fullscreen = true })
  return screen
end

function UI.active() return Host._screen end

function UI.reset()
  if Host._screen then
    Host._screen = nil
    require("src.ui.game3.stack").pop("rse_roulette")
  end
  Host._step = nil
  local E = UI.Entry
  if E and E._entry then
    E._entry = nil
    require("src.ui.game3.stack").pop("rse_roulette_entry")
  end
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local screen = Host._screen
  if not screen then return end
  Host._step:run(dt, function(inp)
    if screen.done then return true end
    screen:frame(inp)
    return screen.done or nil
  end)
end

function Host.draw()
  local screen = Host._screen
  if screen then screen:draw() else love.graphics.clear(0, 0, 0, 1) end
end

local Entry = {}
Entry.__index = Entry
UI.Entry = Entry

-- pokeemerald/src/roulette.c:3475
function Entry.new(opts)
  local self = setmetatable({ opts = opts, frames = 0, sound = opts.sound or Kit.sound({ muted = opts.headless }) }, Entry)
  self.m = { newKeys = 0, heldKeys = 0 }
  self.tCoins = opts.coins or 0
  self.minBet = self:tableMinBet()
  self.state = "print"
  self.coinsWindow = true
  return self
end

function Entry:tableMinBet()
  local T = self.opts.manifest and self.opts.manifest.tables or R.loadTables(self.opts.cache).tables
  return T.minBets[R.minBetId(self.opts.var8004 or 0)]
end

function Entry:joyNew(mask) return Kit.joyNew(self.m, mask) end

function Entry:showText(key, vars)
  self.text = Kit.text(key, vars)
end

-- pokeemerald/src/roulette.c:3435
function Entry:frame(inp)
  Kit.readKeys(self.m, inp)
  self.frames = self.frames + 1
  local st = self.state
  local var = self.opts.var8004 or 0
  if st == "print" then
    local minStr = tostring(self.minBet)
    if self.tCoins >= self.minBet then
      if band(var, R.ROULETTE_SPECIAL_RATE) ~= 0 and band(var, 1) ~= 0 then
        self:showText("Roulette_Text_SpecialRateTable")
        self.state = "printMinBet"
      else
        self:showText("Roulette_Text_PlayMinimumWagerIsX", { minStr })
        self.state = "showYesNo"
      end
    else
      self:showText("Roulette_Text_NotEnoughCoins")
      self.state = "notEnough"
      self.tCoins = 0
    end
  elseif st == "printMinBet" then
    if self:joyNew(Kit.A + Kit.B) then
      self:showText("Roulette_Text_PlayMinimumWagerIsX", { tostring(self.minBet) })
      self.state = "showYesNo"
    end
  elseif st == "showYesNo" then
    self.yesNo = require("src.ui.game3.rse.scene_kit").yesNo(21, 9, { frameType = require("src.ui.game3.chrome")._frameType or 0 })
    self.state = "yesNo"
  elseif st == "yesNo" then
    local r = UI.processYesNo(self)
    if r == 0 then
      self.sound:se("SE_SELECT")
      self.yesNo, self.text, self.coinsWindow = nil, nil, false
      self.state = "accepted"
      return "accept"
    elseif r == 1 or r == -1 then
      self.sound:se("SE_SELECT")
      self.yesNo, self.text, self.coinsWindow = nil, nil, false
      self.state = "declined"
      return "decline"
    end
  elseif st == "notEnough" then
    if self:joyNew(Kit.A + Kit.B) then
      if self.opts.setVar8004 then self.opts.setVar8004(1) end
      self.text, self.coinsWindow = nil, false
      self.state = "declined"
      return "decline"
    end
  end
end

function Entry:draw()
  if self.text then
    local SceneKit = require("src.ui.game3.rse.scene_kit")
    local Chrome = require("src.ui.game3.chrome")
    local colors = SceneKit.messageColors("std_menu")
    SceneKit.userFrame(2, 15, 27, 4, Chrome._frameType or 0, colors.bg)
    Kit.drawText(self.text, 2 * 8, 15 * 8 + 1, colors)
  end
  if self.yesNo then self.yesNo:draw() end
end

local EntryHost = {}

function EntryHost.handleInput(input)
  if Entry._step then Entry._step:collect(input) end
end

function EntryHost.update(dt)
  local e = Entry._entry
  if not e then return end
  Entry._step:run(dt, function(inp)
    local r = e:frame(inp)
    if r then
      e.result = r
      if e.onResult then e.onResult(r) end
      return true
    end
    return nil
  end)
end

function EntryHost.draw()
  local e = Entry._entry
  if e then e:draw() end
end

-- pokeemerald/src/roulette.c:3475
function UI.playEntry(opts)
  local Stack = require("src.ui.game3.stack")
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  local CoinsBox = require("src.ui.game3.coins_box")
  local e = (opts.entryConstructor or Entry.new)(opts)
  Entry._entry = e
  Entry._step = SceneKit.stepper()
  CoinsBox.show(1, 1, opts.coins or 0)
  if opts.onPhase then opts.onPhase("entry") end
  e.onResult = function(r)
    Entry._entry = nil
    Stack.pop("rse_roulette_entry")
    CoinsBox.hide()
    if r ~= "accept" then
      if opts.onDone then opts.onDone(nil) end
      return
    end
    local Fade = require("src.ui.game3.fade")
    if opts.onPhase then opts.onPhase("fade") end
    -- pokeemerald/src/roulette.c:3389
    Fade.begin(Fade.MODE.TO_BLACK, 1, function()
      Fade.clear()
      if opts.onPhase then opts.onPhase("roulette") end
      local party = opts.session and opts.session.party
      local okT, Rtc = pcall(require, "src.core.game3.rtc")
      local hours = 12
      if okT and Rtc and Rtc.calcLocalTime then
        local okH, t = pcall(Rtc.calcLocalTime, opts.session)
        if okH and type(t) == "table" then hours = tonumber(t.hours) or 12 end
      end
      local screen = (opts.openScreen or UI.open)({
        var8004 = opts.var8004, coins = opts.coins, session = opts.session, hours = hours,
        partyFlags = opts.partyFlagsFor and opts.partyFlagsFor(party) or R.partyFlags(party),
        manifest = opts.manifest, cache = opts.cache, constants = opts.constants,
        headless = opts.headless, random = opts.random, sound = opts.sound,
        setCoins = opts.setCoins, setVar8004 = opts.setVar8004,
        onDone = function(s)
          Fade.mode, Fade.t, Fade.active = Fade.MODE.TO_BLACK, 16, false
          Fade.begin(Fade.MODE.FROM_BLACK, 1)
          -- pokeemerald/src/field_screen_effect.c:142
          pcall(function() require("src.core.game3.audio").mapLoadMusic({}) end)
          if opts.onDone then opts.onDone(s) end
        end,
      })
      if opts.onScreen then opts.onScreen(screen) end
    end)
  end
  Stack.push("rse_roulette_entry", EntryHost, { hideBelow = false })
  return e
end

return UI
