local bit = require("bit")
local band, bor, bnot, rshift, lshift, bxor = bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor

local Kit = require("src.ui.game3.rse.gc_kit")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local Slots = require("src.core.game3.rse.slot_machine")

local s16 = Kit.s16

local UI = {}
UI.__index = UI

-- pokeemerald/src/slot_machine.c:160
local ST = {
  UNFADE = 0, WAIT_FADE = 1, READY_NEW_SPIN = 2, READY_NEW_RT_SPIN = 3, ASK_INSERT_BET = 4, BET_INPUT = 5,
  MSG_NEED_3_COINS = 6, WAIT_MSG_NEED_3_COINS = 7, WAIT_INFO_BOX = 8, START_SPIN = 9, START_RT_SPIN = 10,
  RESET_BIAS_FAILURE = 11, WAIT_REEL_STOP = 12, WAIT_ALL_REELS_STOP = 13, CHECK_MATCHES = 14, WAIT_PAYOUT = 15,
  END_PAYOUT = 16, MATCHED_POWER = 17, WAIT_RT_ANIM = 18, RESET_BET_TILES = 19, NO_MATCHES = 20, ASK_QUIT = 21,
  HANDLE_QUIT_INPUT = 22, MSG_MAX_COINS = 23, WAIT_MSG_MAX_COINS = 24, MSG_NO_MORE_COINS = 25,
  WAIT_MSG_NO_MORE_COINS = 26, END = 27, FREE = 28,
}
UI.STATE = ST

-- pokeemerald/src/slot_machine.c:120
local PALTAG = { REEL = 0, REEL_TIME_PIKACHU = 1, REEL_TIME_MISC = 2, REEL_TIME_MACHINE = 3, MISC = 4, EXPLOSION = 5,
  DIG_DISPLAY = 6, PIKA_AURA = 7 }

-- pokeemerald/src/slot_machine.c:308
local DIG = { INSERT_BET = 0, STOP_REEL = 1, WIN = 2, LOSE = 3, REEL_TIME = 4, BONUS_REG = 5, BONUS_BIG = 6 }
UI.DIG = DIG
local DIG_SPRITE_A_BUTTON = 5
local DIG_SPRITE_EMPTY = 25

-- pokeemerald/src/slot_machine.c:213
local RT = {
  INIT = 0, WINDOW_ENTER = 1, WAIT_START_PIKA = 2, PIKA_SPEEDUP1 = 3, PIKA_SPEEDUP2 = 4, WAIT_REEL = 5,
  CHECK_EXPLODE = 6, LAND = 7, PIKA_REACT = 8, WAIT_CLEAR_POWER = 9, CLOSE_WINDOW_SUCCESS = 10, DESTROY_SPRITES = 11,
  SET_REEL_SPEED = 12, END_SUCCESS = 13, EXPLODE = 14, WAIT_EXPLODE = 15, WAIT_SMOKE = 16, CLOSE_WINDOW_FAILURE = 17,
  END_FAILURE = 18,
}

local MAX_SPRITES = Sprites.MAX
local DISPLAY_WIDTH, DISPLAY_HEIGHT = 240, 160
local MATCH = Slots.MATCH
local BIAS = Slots.BIAS

-- pokeemerald/include/gba/io_reg.h:554
local WININ_WIN0_BG_ALL, WININ_WIN0_OBJ, WININ_WIN0_CLR = 0xF, 0x10, 0x20
local WINOUT_WIN01_BG_ALL, WINOUT_WIN01_OBJ, WINOUT_WIN01_CLR = 0xF, 0x10, 0x20

local function winRange(a, b) return a * 256 + b end

-- pokeemerald/include/constants/game_stat.h:32
local GAME_STAT_SLOT_JACKPOTS = 28

function UI.new(opts, class)
  opts = opts or {}
  local self = setmetatable({}, class or UI)
  self.opts = opts
  self.man = opts.manifest or Slots.loadTables(opts.cache)
  self.T = self.man.tables
  self.random = opts.random or function() return require("src.core.game3.rng").Random() end
  self.vblankRandom = opts.vblankRandom
  self.sound = opts.sound or Kit.sound({ muted = opts.headless })
  self.headless = opts.headless or Kit.headless()
  self.m = Kit.newMachine()
  self.onDone = opts.onDone
  self.frames = 0
  self.done = false
  self.core = Slots.new(self.T, {
    random = self.random,
    flashMatchLine = function(line) self:flashMatchLine(line) end,
  })
  self.machineId = opts.machineId or 0
  self.startCoins = opts.coins or 0
  self.m:setCb2(function() self:setupCb() end)
  return self
end

function UI:rand()
  return band(self.random(), 0xFFFF)
end

function UI:setGpu(name, v) self.m.ppu:set(name, v) end

-- pokeemerald/src/slot_machine.c:1098
function UI:mainCb()
  self.m.tasks:run(self)
  self.m.ppu.sprites:animateAll()
  Kit.buildOam(self.m)
  self.m.ppu.palette:update()
end

-- pokeemerald/src/slot_machine.c:1106
function UI:vblankCb()
  local p = self.m.ppu
  p:vblank()
  local sm = self.sm
  if sm then
    p:set("WIN0H", sm.win0h)
    p:set("WIN0V", sm.win0v)
    p:set("WININ", sm.winIn)
    p:set("WINOUT", sm.winOut)
  end
  for _, l in pairs(self.bg or {}) do l:flush() end
end

-- pokeemerald/src/slot_machine.c:1037
function UI:setupCb()
  local m = self.m
  local st = m.state
  if st == 0 then
    self:initBgs()
    self:initSlotMachine()
  elseif st == 2 then
    local p = m.ppu
    for _, r in ipairs({ "BG0HOFS", "BG0VOFS", "BG1HOFS", "BG1VOFS", "BG2HOFS", "BG2VOFS", "BG3HOFS", "BG3VOFS" }) do p:set(r, 0) end
    p:set("WININ", WININ_WIN0_BG_ALL + WININ_WIN0_OBJ + WININ_WIN0_CLR)
    p:set("WINOUT", WINOUT_WIN01_BG_ALL + WINOUT_WIN01_OBJ + WINOUT_WIN01_CLR)
    p:set("BLDCNT", Ppu.BLDCNT_TGT1_BG3 + Ppu.BLDCNT_EFFECT_BLEND + Ppu.BLDCNT_TGT2_OBJ)
    p:set("BLDALPHA", Ppu.blendAlpha(9, 8))
  elseif st == 3 then
    m.ppu.palette:resetFade()
    m.ppu.sprites:resetData()
    m.ppu.sprites.oamLimit = 0x80
    m.ppu.sprites:freeAllPalettes()
    m.tasks:reset()
  elseif st == 4 then
    self.reelButtonPress = { 0, 0, 0, 0 }
  elseif st == 5 then
    self:loadGfxAndTilemaps()
  elseif st == 6 then
    m:setVBlank(function() self:vblankCb() end)
    self:setGpu("DISPCNT", Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_OBJ_ON + Ppu.DISPCNT_WIN0_ON)
  elseif st == 7 then
    m.ppu.palette:beginFade(0xFFFFFFFF, 0, 16, 0, 0)
    self:setGpu("DISPCNT", bor(m.ppu:get("DISPCNT"), Ppu.DISPCNT_BG_ALL_ON))
  elseif st == 10 then
    self:createSlotMachineSprites()
    self:createGameplayTasks()
  elseif st == 11 then
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = st + 1
end

-- pokeemerald/src/slot_machine.c:1142
function UI:initBgs()
  local tiles = self:menuTiles()
  self.bg = {
    [1] = Kit.layer(tiles, 32, 32, { headless = self.headless }),
    [2] = Kit.layer(tiles, 32, 32, { headless = self.headless }),
    [3] = Kit.layer(tiles, 32, 32, { headless = self.headless }),
  }
  local p = self.m.ppu
  p:setBg(1, 1, self.bg[1].layer)
  p:setBg(2, 2, self.bg[2].layer)
  p:setBg(3, 1, self.bg[3].layer)
  self.hideBg3 = false
end

function UI:menuTiles()
  if self._menuTiles then return self._menuTiles end
  local rel = self.man.menuTiles
  local data
  if self.opts.cache and self.opts.cache.read then data = self.opts.cache:read(rel) end
  if not data then
    local ok, Dataset = pcall(require, "src.core.game3.dataset")
    if ok and Dataset and Dataset.cache then data = Dataset.cache():read(rel) end
  end
  self._menuTiles = assert(data, "slot_machine: missing " .. tostring(rel))
  return self._menuTiles
end

-- pokeemerald/src/slot_machine.c:1191
function UI:initSlotMachine()
  local c = self.core
  c:init(self.machineId, self.startCoins)
  self.sm = {
    win0h = DISPLAY_WIDTH, win0v = DISPLAY_HEIGHT,
    winIn = WININ_WIN0_BG_ALL + WININ_WIN0_OBJ + WININ_WIN0_CLR,
    winOut = WINOUT_WIN01_BG_ALL + WINOUT_WIN01_OBJ + WINOUT_WIN01_CLR,
    backupMapMusic = self.sound:mapMusic(),
    flashMatchLineSpriteIds = {},
    reelTimeMachineSpriteIds = {}, reelTimeNumberSpriteIds = {}, reelTimeShadowSpriteIds = {},
    reelTimeBoltSpriteIds = {}, reelTimePikachuAuraSpriteIds = {}, reelTimeDuckSpriteIds = {},
    slotReelTasks = {},
  }
  self:tvHook("alertPlayedSlotMachine", c.coins)
end

function UI:tvHook(fn, ...)
  if self.opts.headless then return end
  local ok, Rse = pcall(require, "src.core.game3.rse.init")
  local impl = ok and Rse.system("tv") or nil
  if impl and type(impl[fn]) == "function" then pcall(impl[fn], ...) end
end

function UI:bgPut(bg, offset, entry)
  local l = self.bg[bg]
  l:put(offset % 32, math.floor(offset / 32), entry)
end

-- pokeemerald/src/slot_machine.c:1250
function UI:loadGfxAndTilemaps()
  local pal = self.m.ppu.palette
  pal:load(self.man.palettes.menu, 0, 80)
  pal:load(self.man.palettes.unk, 13 * 16, 16)
  self:loadMenuTilemap()
  self:loadReelOverlay()
  local sp = self.m.ppu.sprites
  for _, p in ipairs(self.man.palettes.sprites) do sp:loadPalette(p.tag, p.colors) end
end

-- pokeemerald/src/slot_machine.c:5075
function UI:loadMenuTilemap()
  local map = self.man.tilemaps.menu
  for i = 1, #map do self:bgPut(2, i - 1, map[i]) end
end

-- pokeemerald/src/slot_machine.c:5080
function UI:loadReelOverlay()
  local ov = { [0] = 0x2051, 0x2851, 0x2061, 0x2861, 0x20BE, 0x28BE, 0x20BF }
  for x = 4, 17, 5 do
    for dx = 0, 3 do
      self:bgPut(3, x + dx + 5 * 32, ov[0])
      self:bgPut(3, x + dx + 13 * 32, ov[1])
      self:bgPut(3, x + dx + 6 * 32, ov[2])
      self:bgPut(3, x + dx + 12 * 32, ov[3])
    end
    self:bgPut(3, x + 6 * 32, ov[4])
    self:bgPut(3, x + 12 * 32, ov[5])
    for y = 7, 11 do self:bgPut(3, x + y * 32, ov[6]) end
  end
end

-- pokeemerald/src/slot_machine.c:5103
function UI:setReelButtonTilemap(offset, tl, tr, bl, br)
  self:bgPut(2, 15 * 32 + offset, tl)
  self:bgPut(2, 15 * 32 + 1 + offset, tr)
  self:bgPut(2, 16 * 32 + offset, bl)
  self:bgPut(2, 16 * 32 + 1 + offset, br)
end

-- pokeemerald/src/slot_machine.c:5116
function UI:loadInfoBoxTilemap()
  local map = self.man.tilemaps.infoBox
  for i = 1, #map do self:bgPut(2, i - 1, map[i]) end
  self:showBg3(false)
end

function UI:showBg3(on)
  local p = self.m.ppu
  if on then p:set("DISPCNT", bor(p:get("DISPCNT"), Ppu.DISPCNT_BG3_ON))
  else p:set("DISPCNT", band(p:get("DISPCNT"), bnot(Ppu.DISPCNT_BG3_ON))) end
end

-- pokeemerald/src/slot_machine.c:1260
function UI:createSlotMachineSprites()
  self:createReelSymbolSprites()
  self:createCreditPayoutNumberSprites()
  self:createInvisibleFlashMatchLineSprites()
  self:createReelBackgroundSprite()
end

-- pokeemerald/src/slot_machine.c:1268
function UI:createGameplayTasks()
  self:createPikaPowerBoltTask()
  self:createReelTasks()
  self:createDigitalDisplayTask()
  local id = self.m.tasks:create(function(tid) self:taskSlotMachine(tid) end, 0)
  self.mainTaskId = id
  self:taskSlotMachine(id)
end

local SLOT_TASKS

-- pokeemerald/src/slot_machine.c:1281
function UI:taskSlotMachine(tid)
  local task = self.m.tasks:get(tid)
  for _ = 1, 64 do
    local fn = SLOT_TASKS[self.core.state]
    if not fn or not fn(self, task) then break end
  end
end

local function joyNew(self, mask) return Kit.joyNew(self.m, mask) end
local function joyHeld(self, mask) return Kit.joyHeld(self.m, mask) end

SLOT_TASKS = {
  -- pokeemerald/src/slot_machine.c:1291
  [ST.UNFADE] = function(self)
    self.m.ppu.palette:beginFade(0xFFFFFFFF, 0, 16, 0, 0)
    self:loadPikaPowerMeter(self.core.pikaPowerBolts)
    self.core.state = self.core.state + 1
    return false
  end,
  [ST.WAIT_FADE] = function(self)
    if not self.m.ppu.palette:fadeActive() then self.core.state = self.core.state + 1 end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1308
  [ST.READY_NEW_SPIN] = function(self)
    local c = self.core
    c.payout = 0
    c.bet = 0
    c.currentReel = 0
    c.machineBias = band(c.machineBias, BIAS.STRAIGHT_7 + BIAS.MIXED_7)
    c.state = ST.ASK_INSERT_BET
    if c.coins <= 0 then
      c.state = ST.MSG_NO_MORE_COINS
    elseif c.reelTimeSpinsLeft ~= 0 then
      c.state = ST.READY_NEW_RT_SPIN
      self:createDigitalDisplayScene(DIG.REEL_TIME)
    end
    return true
  end,
  [ST.READY_NEW_RT_SPIN] = function(self)
    if self:isDigitalDisplayAnimFinished() then self.core.state = ST.ASK_INSERT_BET end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1336
  [ST.ASK_INSERT_BET] = function(self)
    self:createDigitalDisplayScene(DIG.INSERT_BET)
    self.core.state = ST.BET_INPUT
    if self.core.coins >= Slots.MAX_COINS then self.core.state = ST.MSG_MAX_COINS end
    return true
  end,
  -- pokeemerald/src/slot_machine.c:1346
  [ST.BET_INPUT] = function(self)
    local c = self.core
    if joyNew(self, Kit.SELECT) then
      self:openInfoBox(DIG.INSERT_BET)
      c.state = ST.WAIT_INFO_BOX
    elseif joyNew(self, Kit.R) then
      if c.coins - (Slots.MAX_BET - c.bet) >= 0 then
        for i = c.bet, Slots.MAX_BET - 1 do self:lightenBetTiles(i) end
        c.coins = s16(c.coins - (Slots.MAX_BET - c.bet))
        c.bet = Slots.MAX_BET
        c.state = ST.START_SPIN
        self.sound:se("SE_SHOP")
      else
        c.state = ST.MSG_NEED_3_COINS
      end
    else
      if joyNew(self, Kit.DOWN) and c.coins ~= 0 then
        self.sound:se("SE_SHOP")
        self:lightenBetTiles(c.bet)
        c.coins = s16(c.coins - 1)
        c.bet = c.bet + 1
      end
      if c.bet >= Slots.MAX_BET or (c.bet ~= 0 and joyNew(self, Kit.A)) then c.state = ST.START_SPIN end
      if joyNew(self, Kit.B) then c.state = ST.ASK_QUIT end
    end
    return false
  end,
  [ST.MSG_NEED_3_COINS] = function(self)
    self:showMessage("gText_YouDontHaveThreeCoins")
    self.core.state = ST.WAIT_MSG_NEED_3_COINS
    return false
  end,
  [ST.WAIT_MSG_NEED_3_COINS] = function(self)
    if joyNew(self, Kit.A + Kit.B) then
      self:clearMessage()
      self.core.state = ST.BET_INPUT
    end
    return false
  end,
  [ST.WAIT_INFO_BOX] = function(self)
    if self:isInfoBoxClosed() then self.core.state = ST.BET_INPUT end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1425
  [ST.START_SPIN] = function(self, task)
    local c = self.core
    c:drawMachineBias()
    self:destroyDigitalDisplayScene()
    for r = 0, 2 do self:spinSlotReel(r) end
    self:incrementDailySlotsUses()
    task.data[0] = 0
    if band(c.machineBias, BIAS.REELTIME) ~= 0 then
      self:beginReelTime()
      c.state = ST.START_RT_SPIN
    else
      self:createDigitalDisplayScene(DIG.STOP_REEL)
      c.state = ST.RESET_BIAS_FAILURE
    end
    c.reelSpeed = Slots.REEL_NORMAL_SPEED
    if c.reelTimeSpinsLeft ~= 0 then c.reelSpeed = c:reelTimeSpeed() end
    return false
  end,
  [ST.START_RT_SPIN] = function(self)
    if self:isReelTimeTaskDone() then
      self:createDigitalDisplayScene(DIG.STOP_REEL)
      self.core.machineBias = band(self.core.machineBias, bnot(BIAS.REELTIME))
      self.core.state = ST.RESET_BIAS_FAILURE
    end
    return false
  end,
  [ST.RESET_BIAS_FAILURE] = function(self, task)
    task.data[0] = task.data[0] + 1
    if task.data[0] >= 30 then
      self.core:resetBiasFailure()
      self.core.state = ST.WAIT_REEL_STOP
    end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1477
  [ST.WAIT_REEL_STOP] = function(self)
    if joyNew(self, Kit.A) then
      self.sound:se("SE_CONTEST_PLACE")
      self:stopSlotReel(self.core.currentReel)
      self:pressStopReelButton(self.core.currentReel)
      self.core.state = ST.WAIT_ALL_REELS_STOP
    end
    return false
  end,
  [ST.WAIT_ALL_REELS_STOP] = function(self)
    local c = self.core
    if not self:isSlotReelMoving(c.currentReel) then
      c.currentReel = c.currentReel + 1
      c.state = ST.WAIT_REEL_STOP
      if c.currentReel >= 3 then c.state = ST.CHECK_MATCHES end
      return true
    end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1506
  [ST.CHECK_MATCHES] = function(self)
    local c = self.core
    local out = c:applyMatchResults()
    if out.won then
      c.state = ST.WAIT_PAYOUT
      self:awardPayout()
      self:flashSlotMachineLights()
      if out.scene == "big" then
        self:fanfare("MUS_SLOTS_JACKPOT")
        self:createDigitalDisplayScene(DIG.BONUS_BIG)
      elseif out.scene == "reg" then
        self:fanfare("MUS_SLOTS_JACKPOT")
        self:createDigitalDisplayScene(DIG.BONUS_REG)
      else
        self:fanfare("MUS_SLOTS_WIN")
        self:createDigitalDisplayScene(DIG.WIN)
      end
      if out.addBolt then self:addPikaPowerBolt(out.addBolt) end
    else
      self:createDigitalDisplayScene(DIG.LOSE)
      c.state = ST.NO_MATCHES
    end
    return false
  end,
  [ST.WAIT_PAYOUT] = function(self)
    if self:isFinalTaskPayout() then self.core.state = ST.END_PAYOUT end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1579
  [ST.END_PAYOUT] = function(self)
    local c = self.core
    if self:tryStopSlotMachineLights() then
      c.state = ST.RESET_BET_TILES
      if c:hasMatch(MATCH.RED_7) or c:hasMatch(MATCH.BLUE_7) then self:incrementGameStat(GAME_STAT_SLOT_JACKPOTS) end
      if c:hasMatch(MATCH.REPLAY) then
        c.currentReel = 0
        c.state = ST.START_SPIN
      end
      if c:hasMatch(MATCH.POWER) then c.state = ST.MATCHED_POWER end
      if c.reelTimeSpinsLeft ~= 0 and c:hasMatch(MATCH.REPLAY) then
        self:createDigitalDisplayScene(DIG.REEL_TIME)
        c.state = ST.WAIT_RT_ANIM
      end
    end
    return false
  end,
  [ST.MATCHED_POWER] = function(self)
    local c = self.core
    if not self:isPikaPowerBoltAnimating() then
      c.state = ST.RESET_BET_TILES
      if c:hasMatch(MATCH.REPLAY) then
        c.state = ST.START_SPIN
        if c.reelTimeSpinsLeft ~= 0 then
          self:createDigitalDisplayScene(DIG.REEL_TIME)
          c.state = ST.WAIT_RT_ANIM
        end
      end
    end
    return false
  end,
  [ST.WAIT_RT_ANIM] = function(self)
    local c = self.core
    if self:isDigitalDisplayAnimFinished() then
      c.state = ST.RESET_BET_TILES
      if c:hasMatch(MATCH.REPLAY) then c.state = ST.START_SPIN end
    end
    return false
  end,
  [ST.RESET_BET_TILES] = function(self)
    self:darkenBetTiles(0)
    self:darkenBetTiles(1)
    self:darkenBetTiles(2)
    self.core.state = ST.READY_NEW_SPIN
    return false
  end,
  [ST.NO_MATCHES] = function(self, task)
    task.data[1] = task.data[1] + 1
    if task.data[1] > 64 then
      task.data[1] = 0
      self.core.state = ST.RESET_BET_TILES
    end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1661
  [ST.ASK_QUIT] = function(self)
    self:showMessage("gText_QuitTheGame")
    self.yesNo = require("src.ui.game3.rse.scene_kit").yesNo(21, 7, { frameType = require("src.ui.game3.chrome")._frameType or 0 })
    self.core.state = ST.HANDLE_QUIT_INPUT
    return false
  end,
  [ST.HANDLE_QUIT_INPUT] = function(self)
    local input = self:processYesNo()
    if input == 0 then
      self:clearMessage()
      self:darkenBetTiles(0)
      self:darkenBetTiles(1)
      self:darkenBetTiles(2)
      self.core.coins = s16(self.core.coins + self.core.bet)
      self.core.state = ST.END
    elseif input == 1 or input == -1 then
      self:clearMessage()
      self.core.state = ST.BET_INPUT
    end
    return false
  end,
  [ST.MSG_MAX_COINS] = function(self)
    self:showMessage("gText_YouveGot9999Coins")
    self.core.state = ST.WAIT_MSG_MAX_COINS
    return false
  end,
  [ST.WAIT_MSG_MAX_COINS] = function(self)
    if joyNew(self, Kit.A + Kit.B) then
      self:clearMessage()
      self.core.state = ST.BET_INPUT
    end
    return false
  end,
  [ST.MSG_NO_MORE_COINS] = function(self)
    self:showMessage("gText_YouveRunOutOfCoins")
    self.core.state = ST.WAIT_MSG_NO_MORE_COINS
    return false
  end,
  [ST.WAIT_MSG_NO_MORE_COINS] = function(self)
    if joyNew(self, Kit.A + Kit.B) then
      self:clearMessage()
      self.core.state = ST.END
    end
    return false
  end,
  -- pokeemerald/src/slot_machine.c:1735
  [ST.END] = function(self)
    self.finalCoins = self.core.coins
    if self.opts.setCoins then self.opts.setCoins(self.core.coins) end
    self:tvHook("tryPutFindThatGamerOnAir", self.core.coins)
    self.m.ppu.palette:beginFade(0xFFFFFFFF, 0, 0, 16, 0)
    self.core.state = self.core.state + 1
    return false
  end,
  [ST.FREE] = function(self)
    if not self.m.ppu.palette:fadeActive() then
      self.done = true
      self.core.state = ST.FREE + 1
      if self.onDone then self.onDone(self) end
    end
    return false
  end,
}

function UI:fanfare(name)
  self.sound:fanfare(name)
  local id = self.sound:id(name)
  local frames = self.T.fanfares and self.T.fanfares[id] or 0
  Kit.fanfareTask(self.m, frames)
end

function UI:incrementDailySlotsUses()
  if self.opts.headless then return end
  local ok, Rse = pcall(require, "src.core.game3.rse.init")
  if not ok then return end
  -- pokeemerald/src/tv.c:2503
  pcall(function() Rse.setVar("VAR_DAILY_SLOTS", band(Rse.var("VAR_DAILY_SLOTS") + 1, 0xFFFF)) end)
end

-- pokeemerald/src/overworld.c:433
function UI:incrementGameStat(stat)
  self.stats = self.stats or {}
  self.stats[stat] = (self.stats[stat] or 0) + 1
  local sess = self.opts.session
  if not sess then return end
  if type(sess.gameStats) ~= "table" then sess.gameStats = {} end
  local v = tonumber(sess.gameStats[stat]) or 0
  if v < 0xFFFFFF then v = v + 1 end
  sess.gameStats[stat] = v
end

-- pokeemerald/src/slot_machine.c:2091
function UI:awardPayout()
  self.payoutFn = self.payoutFn or function(tid) self:taskPayout(tid) end
  local id = self.m.tasks:create(self.payoutFn, 4)
  self:taskPayout(id)
end

function UI:isFinalTaskPayout()
  return not self.m.tasks:isActive(self.payoutFn)
end

-- pokeemerald/src/slot_machine.c:2104
function UI:taskPayout(tid)
  local task = self.m.tasks:get(tid)
  local c = self.core
  for _ = 1, 8 do
    local st = task.data[0]
    if st == 0 then
      if self:isMatchLineDoneFlashingBeforePayout() then
        task.data[0] = 1
        if c.payout == 0 then
          task.data[0] = 2
        else
          return
        end
      else
        return
      end
    elseif st == 1 then
      local t = task.data[1]
      task.data[1] = t - 1
      if t == 0 then
        if Kit.fanfareInactive(self.m) then self.sound:se("SE_PIN") end
        c.payout = s16(c.payout - 1)
        if c.coins < Slots.MAX_COINS then c.coins = s16(c.coins + 1) end
        task.data[1] = 8
        if joyHeld(self, Kit.A) then task.data[1] = 4 end
      end
      if Kit.fanfareInactive(self.m) and joyNew(self, Kit.START) then
        self.sound:se("SE_PIN")
        c.coins = s16(c.coins + c.payout)
        if c.coins > Slots.MAX_COINS then c.coins = Slots.MAX_COINS end
        c.payout = 0
      end
      if c.payout == 0 then task.data[0] = 2 end
      return
    else
      if self:tryStopMatchLinesFlashing() then
        self.m.tasks:destroy(tid)
      end
      return
    end
  end
end

-- pokeemerald/src/slot_machine.c:2251
function UI:createReelTasks()
  for i = 0, 2 do
    local id = self.m.tasks:create(function(tid) self:taskReel(tid) end, 2)
    self.m.tasks:get(id).data[15] = i
    self.sm.slotReelTasks[i] = id
    self:taskReel(id)
  end
end

function UI:spinSlotReel(i)
  local t = self.m.tasks:get(self.sm.slotReelTasks[i])
  t.data[0] = 1
  t.data[14] = 1
end

function UI:stopSlotReel(i)
  self.m.tasks:get(self.sm.slotReelTasks[i]).data[0] = 2
end

function UI:isSlotReelMoving(i)
  return self.m.tasks:get(self.sm.slotReelTasks[i]).data[14] ~= 0
end

-- pokeemerald/src/slot_machine.c:2279
function UI:taskReel(tid)
  local task = self.m.tasks:get(tid)
  local d = task.data
  local c = self.core
  local reel = d[15]
  for _ = 1, 8 do
    local st = d[0]
    if st == 0 then
      return
    elseif st == 1 then
      c:advanceSlotReel(reel, c.reelSpeed)
      return
    elseif st == 2 then
      d[0] = 3
      d[1] = c:decideStop(reel)
    elseif st == 3 then
      local shocks = self.T.reelStopShocks
      local pos = Kit.cmod(c.reelPixelOffsets[reel], Slots.REEL_SYMBOL_HEIGHT)
      if pos ~= 0 then
        pos = c:advanceSlotReelToNextSymbol(reel, c.reelSpeed)
      elseif c.reelExtraTurns[reel] ~= 0 then
        c.reelExtraTurns[reel] = c.reelExtraTurns[reel] - 1
        c:advanceSlotReel(reel, c.reelSpeed)
        pos = Kit.cmod(c.reelPixelOffsets[reel], Slots.REEL_SYMBOL_HEIGHT)
      end
      if pos == 0 and c.reelExtraTurns[reel] == 0 then
        d[0] = 4
        d[1] = shocks[d[1]] or 0
        d[2] = 0
      end
      return
    else
      c.reelShockOffsets[reel] = d[1]
      d[1] = s16(-d[1])
      d[2] = d[2] + 1
      if band(d[2], 3) == 0 then d[1] = bit.arshift(d[1], 1) end
      if d[1] == 0 then
        d[0] = 0
        d[14] = 0
        c.reelShockOffsets[reel] = 0
      end
      return
    end
  end
end

-- pokeemerald/src/slot_machine.c:3189
function UI:pressStopReelButton(reel)
  local id = self.m.tasks:create(function(tid) self:taskPressStopReelButton(tid) end, 5)
  self.m.tasks:get(id).data[15] = reel
  self:taskPressStopReelButton(id)
end

function UI:taskPressStopReelButton(tid)
  local task = self.m.tasks:get(tid)
  local d = task.data
  local off = self.T.reelButtonOffsets[d[15]]
  if d[0] == 0 then
    self:setReelButtonTilemap(off, 0x62, 0x63, 0x72, 0x73)
    d[0] = 1
  elseif d[0] == 1 then
    d[1] = d[1] + 1
    if d[1] > 11 then d[0] = 2 end
  else
    self:setReelButtonTilemap(off, 0x42, 0x43, 0x52, 0x53)
    self.m.tasks:destroy(tid)
  end
end

-- pokeemerald/src/slot_machine.c:3219
function UI:lightenMatchLine(id)
  self.m.ppu.palette:load({ self.man.palettes.litMatchLine[id] }, self.T.matchLinePalOffsets[id], 1)
end

function UI:darkenMatchLine(id)
  self.m.ppu.palette:load({ self.man.palettes.darkMatchLine[id] }, self.T.matchLinePalOffsets[id], 1)
end

function UI:lightenBetTiles(bet)
  for i = 0, self.T.matchLinesPerBet[bet] - 1 do self:lightenMatchLine(self.T.betToMatchLineIds[bet][i]) end
end

function UI:darkenBetTiles(bet)
  for i = 0, self.T.matchLinesPerBet[bet] - 1 do self:darkenMatchLine(self.T.betToMatchLineIds[bet][i]) end
end

-- pokeemerald/src/slot_machine.c:3254
function UI:createInvisibleFlashMatchLineSprites()
  for i = 0, 4 do
    local id, s = Kit.createSprite(self.m, { callback = function(sp) self:spriteFlashMatchingLines(sp) end }, 0, 0, 0)
    s.invisible = true
    s.data[0] = i
    self.sm.flashMatchLineSpriteIds[i] = id
  end
end

function UI:sprite(id) return self.m.ppu.sprites.sprites[id] end

-- pokeemerald/src/slot_machine.c:3265
function UI:flashMatchLine(line)
  local s = self:sprite(self.sm.flashMatchLineSpriteIds[line])
  s.data[1] = 1
  s.data[2] = 4
  s.data[3] = 0
  s.data[4] = 0
  s.data[5] = 2
  s.data[7] = 0
end

function UI:isMatchLineDoneFlashingBeforePayout()
  for i = 0, 4 do
    local s = self:sprite(self.sm.flashMatchLineSpriteIds[i])
    if s.data[1] ~= 0 and s.data[2] ~= 0 then return false end
  end
  return true
end

function UI:tryStopMatchLinesFlashing()
  for i = 0, 4 do
    local s = self:sprite(self.sm.flashMatchLineSpriteIds[i])
    if s.data[1] ~= 0 then
      if s.data[7] ~= 0 then s.data[1] = 0 end
      if s.data[7] == 0 then return false end
    end
  end
  return true
end

-- pokeemerald/src/slot_machine.c:3313
function UI:spriteFlashMatchingLines(s)
  local d = s.data
  if d[1] == 0 then return end
  local t = d[3]
  d[3] = t - 1
  if t == 0 then
    d[7] = 0
    d[3] = 1
    d[4] = d[4] + d[5]
    local maxChange = 4
    if d[2] ~= 0 then maxChange = 8 end
    if d[4] <= 0 then
      d[7] = 1
      d[5] = -d[5]
      if d[2] ~= 0 then d[2] = d[2] - 1 end
    elseif d[4] >= maxChange then
      d[5] = -d[5]
    end
    if d[2] ~= 0 then d[3] = lshift(d[3], 1) end
  end
  local off = self.T.matchLinePalOffsets[d[0]]
  Kit.multiplyPalette(self.m.ppu.palette, off, d[4], d[4], d[4])
end

-- pokeemerald/src/slot_machine.c:3358
function UI:flashSlotMachineLights()
  local id = self.m.tasks:create(function(tid) self:taskFlashLights(tid) end, 6)
  self.lightsTaskId = id
  self.m.tasks:get(id).data[3] = 1
  self:taskFlashLights(id)
end

function UI:tryStopSlotMachineLights()
  local id = self.lightsTaskId
  local t = self.m.tasks:get(id)
  if t.data[2] == 0 then
    self.m.tasks:destroy(id)
    self.m.ppu.palette:load(self.man.palettes.menuRow1, 16, 16)
    return true
  end
  return false
end

function UI:taskFlashLights(tid)
  local d = self.m.tasks:get(tid).data
  local t = d[1]
  d[1] = t - 1
  if t == 0 then
    d[1] = 4
    d[2] = d[2] + d[3]
    if d[2] == 0 or d[2] == 2 then d[3] = -d[3] end
  end
  self.m.ppu.palette:load(self.man.palettes.flashingLights[d[2]], 16, 16)
end

-- pokeemerald/src/slot_machine.c:3400
function UI:createPikaPowerBoltTask()
  self.sm.pikaPowerBoltTaskId = self.m.tasks:create(function(tid) self:taskPikaPowerBolt(tid) end, 8)
end

function UI:resetPikaPowerBoltTask(task)
  for i = 2, 15 do task.data[i] = 0 end
end

function UI:addPikaPowerBolt()
  local task = self.m.tasks:get(self.sm.pikaPowerBoltTaskId)
  self:resetPikaPowerBoltTask(task)
  task.data[0] = 1
  task.data[1] = task.data[1] + 1
  task.data[15] = 1
end

function UI:resetPikaPowerBolts()
  local task = self.m.tasks:get(self.sm.pikaPowerBoltTaskId)
  self:resetPikaPowerBoltTask(task)
  task.data[0] = 3
  task.data[15] = 1
end

function UI:isPikaPowerBoltAnimating()
  return self.m.tasks:get(self.sm.pikaPowerBoltTaskId).data[15] ~= 0
end

-- pokeemerald/src/slot_machine.c:3427
function UI:taskPikaPowerBolt(tid)
  local task = self.m.tasks:get(tid)
  local d = task.data
  local tiles = self.T.pikaPowerTiles
  if d[0] == 1 then
    d[2] = self:createPikaPowerBoltSprite(lshift(d[1], 3) + 20, 20)
    d[0] = 2
  elseif d[0] == 2 then
    local s = self:sprite(d[2])
    if s.data[7] ~= 0 then
      local r5, r3 = d[1] + 2, 0
      if d[1] == 1 then r3 = 1 elseif d[1] == 16 then r3 = 2 end
      self:bgPut(2, r5 + 0x40, tiles[r3][0])
      Kit.destroySprite(self.m, s)
      d[0] = 0
      d[15] = 0
    end
  elseif d[0] == 3 then
    local r5, r3 = d[1] + 2, 0
    if d[1] == 1 then r3 = 1 elseif d[1] == 16 then r3 = 2 end
    if d[2] == 0 then
      self:bgPut(2, r5 + 0x40, tiles[r3][1])
      d[1] = d[1] - 1
    end
    d[2] = d[2] + 1
    if d[2] >= 20 then d[2] = 0 end
    if d[1] == 0 then
      d[0] = 0
      d[15] = 0
    end
  end
end

-- pokeemerald/src/slot_machine.c:3495
function UI:loadPikaPowerMeter(bolts)
  local tiles = self.T.pikaPowerTiles
  local r4 = 3
  local i = 0
  while i < bolts do
    local r3 = 0
    if i == 0 then r3 = 1 elseif i == 15 then r3 = 2 end
    self:bgPut(2, r4 + 0x40, tiles[r3][0])
    i, r4 = i + 1, r4 + 1
  end
  while i < 16 do
    local r3 = 0
    if i == 0 then r3 = 1 elseif i == 15 then r3 = 2 end
    self:bgPut(2, r4 + 0x40, tiles[r3][1])
    i, r4 = i + 1, r4 + 1
  end
  self.m.tasks:get(self.sm.pikaPowerBoltTaskId).data[1] = bolts
end

-- pokeemerald/src/slot_machine.c:3537
function UI:beginReelTime()
  self.reelTimeFn = self.reelTimeFn or function(tid) self:taskReelTime(tid) end
  local id = self.m.tasks:create(self.reelTimeFn, 7)
  self.reelTimeTaskId = id
  self:taskReelTime(id)
end

function UI:isReelTimeTaskDone()
  return not self.m.tasks:isActive(self.reelTimeFn)
end

function UI:endReelTimeTask()
  self.m.tasks:destroy(self.reelTimeTaskId)
end

local RT_TASKS

function UI:taskReelTime(tid)
  local task = self.m.tasks:get(tid)
  RT_TASKS[task.data[0]](self, task)
end

function UI:loadReelTimeWindowTilemap(a0, a1)
  local map = self.man.tilemaps.reelTimeWindow
  for i = 4, 14 do
    self.bg[1]:put(a0 % 32, i, map[a1 + (i - 4) * 20 + 1] or 0)
  end
end

function UI:clearReelTimeWindowTilemap(a0)
  for i = 4, 14 do self.bg[1]:put(a0 % 32, i, 0) end
end

RT_TASKS = {
  -- pokeemerald/src/slot_machine.c:3555
  [RT.INIT] = function(self, task)
    local c, d = self.core, task.data
    c.reelTimeSpinsLeft = 0
    c.reeltimePixelOffset = 0
    c.reeltimePosition = 0
    d[0] = d[0] + 1
    d[1] = 0
    d[2] = 30
    d[4] = 1280
    self.m.coordOffsetX, self.m.coordOffsetY = 0, 0
    self:setGpu("BG1HOFS", 0)
    self:setGpu("BG1VOFS", 0)
    self:loadReelTimeWindowTilemap(0x1E, 0)
    self:createReelTimeMachineSprites()
    self:createReelTimePikachuSprite()
    self:createReelTimeNumberSprites()
    self:createReelTimeShadowSprites()
    self:createReelTimeNumberGapSprite()
    c:getReelTimeDraw()
    self.sound:stopMapMusic()
    self.sound:playMapMusic("MUS_ROULETTE")
  end,
  -- pokeemerald/src/slot_machine.c:3579
  [RT.WINDOW_ENTER] = function(self, task)
    local d = task.data
    self.m.coordOffsetX = s16(self.m.coordOffsetX - 8)
    d[1] = d[1] + 8
    local r3 = rshift(band(d[1] + 240, 0xFF), 3)
    self:setGpu("BG1HOFS", band(d[1], 0x1FF))
    if r3 ~= d[2] and d[3] <= 18 then
      d[2] = r3
      d[3] = bit.arshift(d[1], 3)
      self:loadReelTimeWindowTilemap(r3, d[3])
    end
    if d[1] >= 200 then
      d[0] = d[0] + 1
      d[3] = 0
    end
    self.core:advanceReeltimeReel(bit.arshift(d[4], 8))
  end,
  [RT.WAIT_START_PIKA] = function(self, task)
    local d = task.data
    self.core:advanceReeltimeReel(bit.arshift(d[4], 8))
    d[5] = d[5] + 1
    if d[5] >= 60 then
      d[0] = d[0] + 1
      self:createReelTimeBoltSprites()
      self:createReelTimePikachuAuraSprites()
    end
  end,
  -- pokeemerald/src/slot_machine.c:3611
  [RT.PIKA_SPEEDUP1] = function(self, task)
    local d = task.data
    self.core:advanceReeltimeReel(bit.arshift(d[4], 8))
    d[4] = s16(d[4] - 4)
    local i = 4 - bit.arshift(d[4], 8)
    self:setReelTimeBoltDelay(self.T.reelTimeBoltDelays[i])
    self:setReelTimePikachuAuraFlashDelay(self.T.pikachuAuraFlashDelays[i])
    Sprites.startAnimIfDifferent(self:sprite(self.sm.reelTimePikachuSpriteId), self.T.reelTimePikachuAnimIds[i])
    if d[4] <= 0x100 then
      d[0] = d[0] + 1
      d[4] = 0x100
      d[5] = 0
    end
  end,
  [RT.PIKA_SPEEDUP2] = function(self, task)
    local d = task.data
    self.core:advanceReeltimeReel(bit.arshift(d[4], 8))
    d[5] = d[5] + 1
    if d[5] >= 80 then
      d[0] = d[0] + 1
      d[5] = 0
      self:setReelTimePikachuAuraFlashDelay(2)
      Sprites.startAnimIfDifferent(self:sprite(self.sm.reelTimePikachuSpriteId), 3)
    end
  end,
  [RT.WAIT_REEL] = function(self, task)
    local d = task.data
    self.core:advanceReeltimeReel(bit.arshift(d[4], 8))
    d[4] = band(d[4], 0xFF) + 0x80
    d[5] = d[5] + 1
    if d[5] >= 80 then
      d[0] = d[0] + 1
      d[5] = 0
    end
  end,
  -- pokeemerald/src/slot_machine.c:3669
  [RT.CHECK_EXPLODE] = function(self, task)
    local d, c = task.data, self.core
    c:advanceReeltimeReel(bit.arshift(d[4], 8))
    d[4] = band(d[4], 0xFF) + 0x40
    d[5] = d[5] + 1
    if d[5] >= 40 then
      d[5] = 0
      if c.reelTimeDraw ~= 0 then
        if c.reelTimeSpinsLeft <= d[6] then d[0] = d[0] + 1 end
      elseif d[6] > 3 then
        d[0] = d[0] + 1
      elseif c:shouldReelTimeMachineExplode(d[6]) then
        d[0] = RT.EXPLODE
      end
      d[6] = d[6] + 1
    end
  end,
  -- pokeemerald/src/slot_machine.c:3694
  [RT.LAND] = function(self, task)
    local d, c = task.data, self.core
    local off = Kit.cmod(c.reeltimePixelOffset, 20)
    if off ~= 0 then
      off = c:advanceReeltimeReelToNextSymbol(bit.arshift(d[4], 8))
      d[4] = band(d[4], 0xFF) + 0x40
    elseif c:getReelTimeSymbol(1) ~= c.reelTimeDraw then
      c:advanceReeltimeReel(bit.arshift(d[4], 8))
      off = Kit.cmod(c.reeltimePixelOffset, 20)
      d[4] = band(d[4], 0xFF) + 0x40
    end
    if off == 0 and c:getReelTimeSymbol(1) == c.reelTimeDraw then
      d[4] = 0
      d[0] = d[0] + 1
    end
  end,
  -- pokeemerald/src/slot_machine.c:3717
  [RT.PIKA_REACT] = function(self, task)
    local d, c = task.data, self.core
    d[4] = d[4] + 1
    if d[4] >= 60 then
      self.sound:stopMapMusic()
      self:destroyReelTimeBoltSprites()
      self:destroyReelTimePikachuAuraSprites()
      d[0] = d[0] + 1
      local pika = self:sprite(self.sm.reelTimePikachuSpriteId)
      if c.reelTimeDraw == 0 then
        d[4] = 0xA0
        Sprites.startAnimIfDifferent(pika, 5)
        self:fanfare("MUS_TOO_BAD")
      else
        d[4] = 0xC0
        Sprites.startAnimIfDifferent(pika, 4)
        pika.animCmdIndex = 0
        if c.pikaPowerBolts ~= 0 then
          self:resetPikaPowerBolts()
          c.pikaPowerBolts = 0
        end
        self:fanfare("MUS_SLOTS_WIN")
      end
    end
  end,
  [RT.WAIT_CLEAR_POWER] = function(self, task)
    local d = task.data
    local zero = d[4] == 0
    if not zero then
      d[4] = d[4] - 1
      zero = d[4] == 0
    end
    if zero and not self:isPikaPowerBoltAnimating() then d[0] = d[0] + 1 end
  end,
  -- pokeemerald/src/slot_machine.c:3752
  [RT.CLOSE_WINDOW_SUCCESS] = function(self, task) self:reelTimeCloseWindow(task) end,
  [RT.DESTROY_SPRITES] = function(self, task)
    local d, c = task.data, self.core
    c.reelTimeSpinsUsed = 0
    c.reelTimeSpinsLeft = c.reelTimeDraw
    self.m.coordOffsetX = 0
    self:setGpu("BG1HOFS", 0)
    c.reelSpeed = Slots.REEL_NORMAL_SPEED
    self:destroyReelTimePikachuSprite()
    self:destroyReelTimeMachineSprites()
    self:destroyReelTimeShadowSprites()
    self.sound:playMapMusic(self.sm.backupMapMusic)
    if c.reelTimeSpinsLeft == 0 then
      self:endReelTimeTask()
    else
      self:createDigitalDisplayScene(DIG.REEL_TIME)
      d[1] = c:reelTimeSpeed()
      d[2] = 0
      d[3] = 0
      d[0] = d[0] + 1
    end
  end,
  -- pokeemerald/src/slot_machine.c:3796
  [RT.SET_REEL_SPEED] = function(self, task)
    local d, c = task.data, self.core
    if c.reelSpeed == d[1] then
      d[0] = d[0] + 1
    elseif Kit.cmod(c.reelPixelOffsets[0], Slots.REEL_SYMBOL_HEIGHT) == 0 then
      d[2] = d[2] + 1
      if band(d[2], 7) == 0 then c.reelSpeed = bit.arshift(c.reelSpeed, 1) end
    end
  end,
  [RT.END_SUCCESS] = function(self)
    if self:isDigitalDisplayAnimFinished() then self:endReelTimeTask() end
  end,
  -- pokeemerald/src/slot_machine.c:3810
  [RT.EXPLODE] = function(self, task)
    local d = task.data
    self:destroyReelTimeMachineSprites()
    self:destroyReelTimeBoltSprites()
    self:destroyReelTimePikachuAuraSprites()
    self:createReelTimeExplosionSprite()
    self:sprite(self.sm.reelTimeShadowSpriteIds[0]).invisible = true
    Sprites.startAnimIfDifferent(self:sprite(self.sm.reelTimePikachuSpriteId), 5)
    d[0] = d[0] + 1
    d[4] = 4
    d[5] = 0
    self.sound:stopMapMusic()
    self:fanfare("MUS_TOO_BAD")
    self.sound:se("SE_M_EXPLOSION")
  end,
  [RT.WAIT_EXPLODE] = function(self, task)
    local d = task.data
    self.m.coordOffsetY = d[4]
    self:setGpu("BG1VOFS", band(d[4], 0x1FF))
    if band(d[5], 1) ~= 0 then d[4] = -d[4] end
    d[5] = d[5] + 1
    if band(d[5], 0x1F) == 0 then d[4] = bit.arshift(d[4], 1) end
    if d[4] == 0 then
      self:destroyReelTimeExplosionSprite()
      self:createReelTimeDuckSprites()
      self:createBrokenReelTimeMachineSprite()
      self:createReelTimeSmokeSprite()
      self:sprite(self.sm.reelTimeShadowSpriteIds[0]).invisible = false
      d[0] = d[0] + 1
      d[5] = 0
    end
  end,
  [RT.WAIT_SMOKE] = function(self, task)
    self.m.coordOffsetY = 0
    self:setGpu("BG1VOFS", 0)
    if self:sprite(self.sm.reelTimeSmokeSpriteId).data[7] ~= 0 then
      task.data[0] = task.data[0] + 1
      self:destroyReelTimeSmokeSprite()
    end
  end,
  [RT.CLOSE_WINDOW_FAILURE] = function(self, task) self:reelTimeCloseWindow(task) end,
  -- pokeemerald/src/slot_machine.c:3857
  [RT.END_FAILURE] = function(self)
    self.m.coordOffsetX = 0
    self:setGpu("BG1HOFS", 0)
    self.sound:playMapMusic(self.sm.backupMapMusic)
    self:destroyReelTimePikachuSprite()
    self:destroyBrokenReelTimeMachineSprite()
    self:destroyReelTimeShadowSprites()
    self:destroyReelTimeDuckSprites()
    self:endReelTimeTask()
  end,
}

-- pokeemerald/src/slot_machine.c:3752
function UI:reelTimeCloseWindow(task)
  local d = task.data
  self.m.coordOffsetX = s16(self.m.coordOffsetX - 8)
  d[1] = d[1] + 8
  d[3] = d[3] + 8
  local r4 = rshift(band(d[1] - 8, 0xFF), 3)
  self:setGpu("BG1HOFS", band(d[1], 0x1FF))
  if bit.arshift(d[3], 3) <= 25 then
    self:clearReelTimeWindowTilemap(r4)
  else
    d[0] = d[0] + 1
  end
end

-- pokeemerald/src/slot_machine.c:3893
function UI:openInfoBox(digId)
  self.infoBoxFn = self.infoBoxFn or function(tid) self:taskInfoBox(tid) end
  local id = self.m.tasks:create(self.infoBoxFn, 1)
  self.m.tasks:get(id).data[1] = digId
  self:taskInfoBox(id)
end

function UI:isInfoBoxClosed()
  return not self.m.tasks:isActive(self.infoBoxFn)
end

-- pokeemerald/src/slot_machine.c:3908
function UI:taskInfoBox(tid)
  local task = self.m.tasks:get(tid)
  local d = task.data
  local pal = self.m.ppu.palette
  local st = d[0]
  if st == 0 then
    pal:beginFade(0xFFFFFFFF, 0, 0, 16, 0)
    d[0] = d[0] + 1
  elseif st == 1 or st == 3 or st == 5 or st == 7 or st == 9 or st == 11 or st == 13 then
    if not pal:fadeActive() then d[0] = d[0] + 1 end
  elseif st == 2 then
    self:destroyDigitalDisplayScene()
    self:loadInfoBoxTilemap()
    self.infoWindow = { text = false }
    d[0] = d[0] + 1
  elseif st == 4 then
    self.infoWindow = { text = true }
    pal:beginFade(0xFFFFFFFF, 0, 16, 0, 0)
    d[0] = d[0] + 1
  elseif st == 6 then
    if joyNew(self, Kit.B + Kit.SELECT) then
      self.infoWindow = nil
      pal:beginFade(0xFFFFFFFF, 0, 0, 16, 0)
      d[0] = d[0] + 1
    end
  elseif st == 8 then
    self:loadMenuTilemap()
    self:showBg3(true)
    d[0] = d[0] + 1
  elseif st == 10 then
    self:createDigitalDisplayScene(d[1])
    d[0] = d[0] + 1
  elseif st == 12 then
    self:loadPikaPowerMeter(self.core.pikaPowerBolts)
    pal:beginFade(0xFFFFFFFF, 0, 16, 0, 0)
    d[0] = d[0] + 1
  elseif st == 14 then
    self.m.tasks:destroy(tid)
  end
end

-- pokeemerald/src/slot_machine.c:3985
function UI:createDigitalDisplayTask()
  local id = self.m.tasks:create(function() end, 3)
  self.sm.digDisplayTaskId = id
  local t = self.m.tasks:get(id)
  t.data[1] = -1
  for i = 4, 15 do t.data[i] = MAX_SPRITES end
end

-- pokeemerald/src/slot_machine.c:3998
function UI:createDigitalDisplayScene(id)
  self:destroyDigitalDisplayScene()
  local t = self.m.tasks:get(self.sm.digDisplayTaskId)
  t.data[1] = id
  for i, row in ipairs(self.T.digitalScenes[id]) do
    t.data[4 + i - 1] = self:createStdDigitalDisplaySprite(row.tpl, row.info, row.id)
  end
end

function UI:addDigitalDisplaySprite(tpl, callback, x, y, internalId)
  local t = self.m.tasks:get(self.sm.digDisplayTaskId)
  for i = 4, 15 do
    if t.data[i] == MAX_SPRITES then
      t.data[i] = self:createDigitalDisplaySprite(tpl, callback, x, y, internalId)
      break
    end
  end
end

local SCENE_EXIT

function UI:destroyDigitalDisplayScene()
  local t = self.m.tasks:get(self.sm.digDisplayTaskId)
  if band(t.data[1], 0xFFFF) ~= 0xFFFF then
    local fn = SCENE_EXIT[t.data[1]]
    if fn then fn(self) end
  end
  for i = 4, 15 do
    if t.data[i] ~= MAX_SPRITES then
      Kit.destroySprite(self.m, self:sprite(t.data[i]))
      t.data[i] = MAX_SPRITES
    end
  end
end

function UI:isDigitalDisplayAnimFinished()
  local t = self.m.tasks:get(self.sm.digDisplayTaskId)
  for i = 4, 15 do
    if t.data[i] ~= MAX_SPRITES and self:sprite(t.data[i]).data[7] ~= 0 then return false end
  end
  return true
end

-- pokeemerald/src/slot_machine.c:4076
function UI:createReelSymbolSprites()
  local x = 0x30
  for i = 0, 2 do
    for j = 0, 119, 24 do
      local _, s = Kit.createSprite(self.m, {
        w = 32, h = 32, paletteTag = PALTAG.REEL,
        callback = function(sp) self:spriteReelSymbol(sp) end,
      }, x, 0, 14)
      s.oam.priority = 3
      s.data[0] = i
      s.data[1] = j
      s.data[3] = -1
    end
    x = x + 0x28
  end
end

-- pokeemerald/src/slot_machine.c:4094
function UI:spriteReelSymbol(s)
  local c = self.core
  local d = s.data
  d[2] = Kit.cmod(c.reelPixelOffsets[d[0]] + d[1], 120)
  s.y = c.reelShockOffsets[d[0]] + 28 + d[2]
  Kit.setFrameOverride(s, self.man.sprites.reelSymbols, c:getSymbolAtRest(d[0], Kit.cdiv(d[2], 24)))
end

-- pokeemerald/src/slot_machine.c:4103
function UI:createCreditPayoutNumberSprites()
  local i, x = 1, 203
  while i <= Slots.MAX_COINS do
    self:createCoinNumberSprite(x, 23, false, i)
    i, x = i * 10, x - 7
  end
  i, x = 1, 235
  while i <= Slots.MAX_COINS do
    self:createCoinNumberSprite(x, 23, true, i)
    i, x = i * 10, x - 7
  end
end

function UI:createCoinNumberSprite(x, y, isPayout, mult)
  local _, s = Kit.createSprite(self.m, {
    w = 8, h = 16, paletteTag = PALTAG.MISC,
    callback = function(sp) self:spriteCoinNumber(sp) end,
  }, x, y, 13)
  s.oam.priority = 2
  s.data[0] = isPayout and 1 or 0
  s.data[1] = mult
  s.data[2] = mult * 10
  s.data[3] = -1
end

-- pokeemerald/src/slot_machine.c:4132
function UI:spriteCoinNumber(s)
  local d = s.data
  local tag = band(self.core.coins, 0xFFFF)
  if d[0] ~= 0 then tag = band(self.core.payout, 0xFFFF) end
  if d[3] ~= tag then
    d[3] = tag
    local digit = math.floor((tag % band(d[2], 0xFFFF)) / band(d[1], 0xFFFF))
    Kit.setFrameOverride(s, self.man.sprites.numbers, digit)
  end
end

-- pokeemerald/src/slot_machine.c:4155
function UI:createReelBackgroundSprite()
  local _, s = Kit.createSprite(self.m, { entry = self.man.sprites.reelBackground, w = 64, h = 64, paletteTag = PALTAG.REEL }, 88, 72, 15)
  s.oam.priority = 3
end

-- pokeemerald/src/slot_machine.c:4162
function UI:createReelTimePikachuSprite()
  local e = self.man.sprites.reelTimePikachu
  local id, s = Kit.createSprite(self.m, {
    entry = e, w = 64, h = 64, anims = e.anims, paletteTag = PALTAG.REEL_TIME_PIKACHU,
    coordOffset = true, callback = function(sp) self:spriteReelTimePikachu(sp) end,
  }, 280, 80, 1)
  s.oam.priority = 1
  self.sm.reelTimePikachuSpriteId = id
end

function UI:destroyReelTimePikachuSprite()
  Kit.destroySprite(self.m, self:sprite(self.sm.reelTimePikachuSpriteId))
end

-- pokeemerald/src/slot_machine.c:4194
function UI:spriteReelTimePikachu(s)
  s.x2, s.y2 = 0, 0
  if s.animNum == 4 then
    s.x2, s.y2 = 8, 8
    if (s.animCmdIndex ~= 0 and s.animDelayCounter ~= 0) or (s.animCmdIndex == 0 and s.animDelayCounter == 0) then
      s.y2 = -8
    end
  end
end

function UI:compSprite(key, x, y, sub, tag, priority, extra)
  local def = { entry = self.man.sprites[key], w = 8, h = 16, paletteTag = tag, coordOffset = true }
  for k, v in pairs(extra or {}) do def[k] = v end
  local id, s = Kit.createSprite(self.m, def, x, y, sub)
  s.oam.priority = priority or 1
  return id, s
end

-- pokeemerald/src/slot_machine.c:4205
function UI:createReelTimeMachineSprites()
  self.sm.reelTimeMachineSpriteIds[0] = self:compSprite("reelTimeAntennae", 368, 52, 7, PALTAG.REEL_TIME_MISC)
  self.sm.reelTimeMachineSpriteIds[1] = self:compSprite("reelTimeMachine", 368, 84, 7, PALTAG.REEL_TIME_MACHINE)
end

-- pokeemerald/src/slot_machine.c:4240
function UI:createBrokenReelTimeMachineSprite()
  self.sm.reelTimeBrokenMachineSpriteId = self:compSprite("brokenReelTimeMachine", 168 - self.m.coordOffsetX, 80, 7,
    PALTAG.REEL_TIME_MACHINE)
end

-- pokeemerald/src/slot_machine.c:4261
function UI:createReelTimeNumberSprites()
  local r5 = 0
  local e = self.man.sprites.reelTimeNumbers
  for i = 0, 2 do
    local id, s = Kit.createSprite(self.m, {
      entry = e, w = 16, h = 16, anims = e.anims, paletteTag = PALTAG.MISC, coordOffset = true,
      callback = function(sp) self:spriteReelTimeNumbers(sp) end,
    }, 368, 0, 10)
    s.oam.priority = 1
    s.data[7] = r5
    self.sm.reelTimeNumberSpriteIds[i] = id
    r5 = r5 + 20
  end
end

-- pokeemerald/src/slot_machine.c:4276
function UI:spriteReelTimeNumbers(s)
  local r0 = s16(band(self.core.reeltimePixelOffset + s.data[7], 0xFFFF))
  r0 = Kit.cmod(r0, 40)
  s.y = r0 + 59
  Sprites.startAnimIfDifferent(s, self.core:getReelTimeSymbol(Kit.cdiv(r0, 20)))
end

-- pokeemerald/src/slot_machine.c:4284
function UI:createReelTimeShadowSprites()
  self.sm.reelTimeShadowSpriteIds[0] = self:compSprite("reelTimeShadow", 368, 100, 9, PALTAG.MISC)
  self.sm.reelTimeShadowSpriteIds[1] = self:compSprite("reelTimeShadow", 288, 104, 4, PALTAG.MISC)
end

-- pokeemerald/src/slot_machine.c:4302
function UI:createReelTimeNumberGapSprite()
  self.sm.reelTimeNumberGapSpriteId = self:compSprite("reelTimeNumberGap", 368, 76, 11, PALTAG.MISC)
end

function UI:destroyReelTimeMachineSprites()
  Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeNumberGapSpriteId))
  for i = 0, 1 do Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeMachineSpriteIds[i])) end
  for i = 0, 2 do Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeNumberSpriteIds[i])) end
end

function UI:destroyReelTimeShadowSprites()
  for i = 0, 1 do Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeShadowSpriteIds[i])) end
end

function UI:destroyBrokenReelTimeMachineSprite()
  Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeBrokenMachineSpriteId))
end

-- pokeemerald/src/slot_machine.c:4347
function UI:createReelTimeBoltSprites()
  local e = self.man.sprites.reelTimeBolt
  local def = { entry = e, w = 16, h = 32, anims = e.anims, paletteTag = PALTAG.MISC,
    callback = function(sp) self:spriteReelTimeBolt(sp) end }
  local id, s = Kit.createSprite(self.m, def, 152, 32, 5)
  s.oam.priority = 1
  s.hFlip = true
  self.sm.reelTimeBoltSpriteIds[0] = id
  s.data[0] = 8
  s.data[1] = -1
  s.data[2] = -1
  s.data[7] = 32
  id, s = Kit.createSprite(self.m, def, 184, 32, 5)
  s.oam.priority = 1
  self.sm.reelTimeBoltSpriteIds[1] = id
  s.data[1] = 1
  s.data[2] = -1
  s.data[7] = 32
end

-- pokeemerald/src/slot_machine.c:4368
function UI:spriteReelTimeBolt(s)
  local d = s.data
  if d[0] ~= 0 then
    d[0] = d[0] - 1
    s.x2, s.y2 = 0, 0
    s.invisible = true
  else
    s.invisible = false
    s.x2 = s.x2 + d[1]
    s.y2 = s.y2 + d[2]
    d[3] = d[3] + 1
    if d[3] >= 8 then
      d[0] = d[7]
      d[3] = 0
    end
  end
end

function UI:setReelTimeBoltDelay(delay)
  self:sprite(self.sm.reelTimeBoltSpriteIds[0]).data[7] = delay
  self:sprite(self.sm.reelTimeBoltSpriteIds[1]).data[7] = delay
end

function UI:destroyReelTimeBoltSprites()
  for i = 0, 1 do Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeBoltSpriteIds[i])) end
end

-- pokeemerald/src/slot_machine.c:4415
function UI:createReelTimePikachuAuraSprites()
  local e = self.man.sprites.reelTimePikaAura
  local def = { entry = e, w = 32, h = 64, paletteTag = PALTAG.PIKA_AURA,
    callback = function(sp) self:spriteReelTimePikachuAura(sp) end }
  local id, s = Kit.createSprite(self.m, def, 72, 80, 3)
  s.oam.priority = 1
  s.data[0] = 1
  s.data[5] = 0
  s.data[6] = 16
  s.data[7] = 8
  self.sm.reelTimePikachuAuraSpriteIds[0] = id
  id, s = Kit.createSprite(self.m, def, 104, 80, 3)
  s.oam.priority = 1
  s.hFlip = true
  self.sm.reelTimePikachuAuraSpriteIds[1] = id
end

function UI:auraPalIndex()
  return 256 + self.m.ppu.sprites:indexOfPaletteTag(PALTAG.PIKA_AURA) * 16 + 3
end

-- pokeemerald/src/slot_machine.c:4433
function UI:spriteReelTimePikachuAura(s)
  local d = s.data
  local colors = { [0] = 16, 0 }
  if d[0] ~= 0 then
    d[6] = d[6] - 1
    if d[6] <= 0 then
      local c = colors[d[5]]
      Kit.multiplyInvertedPalette(self.m.ppu.palette, self:auraPalIndex(), c, c, c)
      d[5] = band(d[5] + 1, 1)
      d[6] = d[7]
    end
  end
end

function UI:setReelTimePikachuAuraFlashDelay(delay)
  self:sprite(self.sm.reelTimePikachuAuraSpriteIds[0]).data[7] = delay
end

function UI:destroyReelTimePikachuAuraSprites()
  Kit.multiplyInvertedPalette(self.m.ppu.palette, self:auraPalIndex(), 0, 0, 0)
  for i = 0, 1 do Kit.destroySprite(self.m, self:sprite(self.sm.reelTimePikachuAuraSpriteIds[i])) end
end

-- pokeemerald/src/slot_machine.c:4463
function UI:createReelTimeExplosionSprite()
  local e = self.man.sprites.reelTimeExplosion
  local id, s = Kit.createSprite(self.m, {
    entry = e, w = 32, h = 32, anims = e.anims, paletteTag = PALTAG.EXPLOSION,
    callback = function(sp) sp.y2 = self.m.coordOffsetY end,
  }, 168, 80, 6)
  s.oam.priority = 1
  self.sm.reelTimeExplosionSpriteId = id
end

function UI:destroyReelTimeExplosionSprite()
  Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeExplosionSpriteId))
end

-- pokeemerald/src/slot_machine.c:4481
function UI:createReelTimeDuckSprites()
  local sp = { [0] = 0x0, 0x40, 0x80, 0xC0 }
  local e = self.man.sprites.reelTimeDuck
  for i = 0, 3 do
    local id, s = Kit.createSprite(self.m, {
      entry = e, w = 8, h = 8, paletteTag = PALTAG.MISC, coordOffset = true,
      anims = { { { op = "frame", frame = 0, duration = 1 }, { op = "jump", target = 0 } } },
      callback = function(spr) self:spriteReelTimeDuck(spr) end,
    }, 80 - self.m.coordOffsetX, 68, 0)
    s.oam.priority = 1
    s.data[0] = sp[i]
    self.sm.reelTimeDuckSpriteIds[i] = id
  end
end

-- pokeemerald/src/slot_machine.c:4496
function UI:spriteReelTimeDuck(s)
  local d = s.data
  d[0] = band(d[0] - 2, 0xFF)
  s.x2 = Kit.cos(self.T, d[0], 20)
  s.y2 = Kit.sin(self.T, d[0], 6)
  s.subpriority = 0
  if d[0] >= 0x80 then s.subpriority = 2 end
  d[1] = d[1] + 1
  if d[1] >= 16 then
    s.hFlip = not s.hFlip
    d[1] = 0
  end
end

function UI:destroyReelTimeDuckSprites()
  for i = 0, 3 do Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeDuckSpriteIds[i])) end
end

-- pokeemerald/src/slot_machine.c:4528
function UI:createReelTimeSmokeSprite()
  local e = self.man.sprites.reelTimeSmoke
  local id, s = Kit.createSprite(self.m, {
    entry = e, w = 16, h = 16, paletteTag = PALTAG.MISC, affineAnims = e.affineAnims,
    callback = function(sp) self:spriteReelTimeSmoke(sp) end,
  }, 168, 60, 8)
  s.oam.priority = 1
  s.oam.affineMode = Sprites.AFFINE_DOUBLE
  self.m.ppu.sprites:initAffineAnim(s)
  self.sm.reelTimeSmokeSpriteId = id
end

-- pokeemerald/src/slot_machine.c:4538
function UI:spriteReelTimeSmoke(s)
  local d = s.data
  if d[0] == 0 then
    if s.affineAnimEnded then d[0] = d[0] + 1 end
  elseif d[0] == 1 then
    s.invisible = not s.invisible
    d[2] = d[2] + 1
    if d[2] >= 24 then
      d[0] = d[0] + 1
      d[2] = 0
    end
  else
    s.invisible = true
    d[2] = d[2] + 1
    if d[2] >= 16 then d[7] = 1 end
  end
  d[1] = band(d[1], 0xFF)
  d[1] = d[1] + 16
  s.y2 = s.y2 - rshift(d[1], 8)
end

function UI:destroyReelTimeSmokeSprite()
  Kit.destroySprite(self.m, self:sprite(self.sm.reelTimeSmokeSpriteId))
end

-- pokeemerald/src/slot_machine.c:4582
function UI:createPikaPowerBoltSprite(x, y)
  local e = self.man.sprites.pikaPowerBolt
  local id, s = Kit.createSprite(self.m, {
    entry = e, w = 8, h = 8, paletteTag = PALTAG.MISC, affineAnims = e.affineAnims,
    callback = function(sp) if sp.affineAnimEnded then sp.data[7] = 1 end end,
  }, x, y, 12)
  s.oam.priority = 2
  s.oam.affineMode = Sprites.AFFINE_DOUBLE
  self.m.ppu.sprites:initAffineAnim(s)
  return id
end

local DIG_CALLBACKS

-- pokeemerald/src/slot_machine.c:4605
function UI:createStdDigitalDisplaySprite(tpl, info, internalId)
  local xy = self.T.digitalCoords[info]
  return self:createDigitalDisplaySprite(tpl, DIG_CALLBACKS[info], xy[0], xy[1], internalId)
end

-- pokeemerald/src/slot_machine.c:4614
function UI:createDigitalDisplaySprite(tpl, callback, x, y, internalId)
  local def
  if tpl == DIG_SPRITE_EMPTY then
    def = { w = 8, h = 8 }
  else
    local e = self.man.sprites.digital[tpl]
    def = { entry = e, w = e.w0, h = e.h0, anims = e.anims, paletteTag = PALTAG.DIG_DISPLAY }
  end
  def.callback = function(s) if callback then callback(self, s) end end
  local id, s = Kit.createSprite(self.m, def, x, y, 16)
  s.oam.priority = 3
  s.data[6] = internalId
  s.data[7] = 1
  return id
end

local function cbStatic(self, s) s.data[7] = 0 end

-- pokeemerald/src/slot_machine.c:4638
local function cbSmoke(self, s)
  local d = s.data
  local tx = { [0] = 4, -4, 4, -4 }
  local ty = { [0] = 4, 4, -4, -4 }
  local c = d[1]
  d[1] = c + 1
  if c >= 16 then
    s.subTable = bxor(s.subTable, 1)
    d[1] = 0
  end
  s.x2, s.y2 = 0, 0
  if s.subTable ~= 0 then
    s.x2 = tx[d[6]]
    s.y2 = ty[d[6]]
  end
end

local function cbSmokeNE(self, s) s.hFlip = true; cbSmoke(self, s) end
local function cbSmokeSW(self, s) s.vFlip = true; cbSmoke(self, s) end
local function cbSmokeSE(self, s) s.hFlip = true; s.vFlip = true; cbSmoke(self, s) end

-- pokeemerald/src/slot_machine.c:4677
local function cbReel(self, s)
  local d = s.data
  if d[0] == 0 then
    s.x = s.x + 4
    if s.x >= DISPLAY_WIDTH - 32 then
      s.x = DISPLAY_WIDTH - 32
      d[0] = d[0] + 1
    end
  elseif d[0] == 1 then
    d[1] = d[1] + 1
    if d[1] > 90 then d[0] = d[0] + 1 end
  elseif d[0] == 2 then
    s.x = s.x + 4
    if s.x >= DISPLAY_WIDTH + 32 then d[0] = d[0] + 1 end
  elseif d[0] == 3 then
    d[7] = 0
  end
end

-- pokeemerald/src/slot_machine.c:4705
local function cbTime(self, s)
  local d = s.data
  if d[0] == 0 then
    s.x = s.x - 4
    if s.x <= DISPLAY_WIDTH - 32 then
      s.x = DISPLAY_WIDTH - 32
      d[0] = d[0] + 1
    end
  elseif d[0] == 1 then
    d[1] = d[1] + 1
    if d[1] > 90 then d[0] = d[0] + 1 end
  elseif d[0] == 2 then
    s.x = s.x - 4
    if s.x <= 144 then d[0] = d[0] + 1 end
  elseif d[0] == 3 then
    d[7] = 0
  end
end

-- pokeemerald/src/slot_machine.c:4732
local function cbReelTimeNumber(self, s)
  local d = s.data
  if d[0] == 0 then
    Sprites.startAnim(s, self.core.reelTimeSpinsLeft - 1)
    d[0] = 1
  end
  if d[0] == 1 then
    d[1] = d[1] + 1
    if d[1] >= 4 then
      d[0] = d[0] + 1
      d[1] = 0
    end
  elseif d[0] == 2 then
    s.x = s.x + 4
    if s.x >= DISPLAY_WIDTH - 32 then
      s.x = DISPLAY_WIDTH - 32
      d[0] = d[0] + 1
    end
  elseif d[0] == 3 then
    d[1] = d[1] + 1
    if d[1] > 90 then d[0] = d[0] + 1 end
  elseif d[0] == 4 then
    s.x = s.x + 4
    if s.x >= DISPLAY_WIDTH + 8 then d[0] = d[0] + 1 end
  elseif d[0] == 5 then
    d[7] = 0
  end
end

-- pokeemerald/src/slot_machine.c:4770
local function cbPokeballRocking(self, s)
  local d = s.data
  if d[0] == 0 then
    s.animPaused = true
    d[0] = 1
  end
  if d[0] == 1 then
    s.y = s.y + 8
    if s.y >= 0x70 then
      s.y = 0x70
      d[1] = 16
      d[0] = d[0] + 1
    end
  elseif d[0] == 2 then
    if d[2] == 0 then
      s.y = s.y - d[1]
      d[1] = -d[1]
      d[3] = d[3] + 1
      if d[3] >= 2 then
        d[1] = bit.arshift(d[1], 2)
        d[3] = 0
        if d[1] == 0 then
          d[0] = d[0] + 1
          d[7] = 0
          s.animPaused = false
        end
      end
    end
    d[2] = band(d[2] + 1, 7)
  end
end

-- pokeemerald/src/slot_machine.c:4810
local function cbStop(self, s)
  local d = s.data
  if d[0] == 0 then
    d[1] = d[1] + 1
    if d[1] > 8 then d[0] = d[0] + 1 end
  elseif d[0] == 1 then
    s.y = s.y + 2
    if s.y >= 0x30 then
      s.y = 0x30
      d[0] = d[0] + 1
      d[7] = 0
    end
  end
end

-- pokeemerald/src/slot_machine.c:4830
local function cbAButtonStop(self, s)
  local d = s.data
  if d[0] == 0 then
    s.invisible = true
    d[1] = d[1] + 1
    if d[1] > 0x20 then
      d[0] = d[0] + 1
      d[1] = 5
      s.mosaic = true
      s.invisible = false
      Sprites.startAnim(s, 1)
      self.mosaic = d[1]
    end
  elseif d[0] == 1 then
    d[1] = d[1] - rshift(d[2], 8)
    if d[1] < 0 then d[1] = 0 end
    self.mosaic = d[1]
    d[2] = band(d[2], 0xFF)
    d[2] = d[2] + 0x80
    if d[1] == 0 then
      d[0] = d[0] + 1
      d[7] = 0
      s.mosaic = false
      Sprites.startAnim(s, 0)
    end
  end
end

-- pokeemerald/src/slot_machine.c:4864
local function cbPokeballShining(self, s)
  local d = s.data
  local idx = 256 + self.m.ppu.sprites:indexOfPaletteTag(PALTAG.DIG_DISPLAY) * 16
  self.m.ppu.palette:load(self.man.palettes.pokeballShining[d[1]], idx, 16)
  if d[1] < 3 then
    d[2] = d[2] + 1
    if d[2] >= 4 then
      d[1] = d[1] + 1
      d[2] = 0
    end
  else
    d[2] = d[2] + 1
    if d[2] >= 25 then
      d[1] = 0
      d[2] = 0
    end
  end
  Sprites.startAnimIfDifferent(s, 1)
  d[7] = 0
end

-- pokeemerald/src/slot_machine.c:4888
local function cbRegBonus(self, s)
  local d = s.data
  local xo = { [0] = 0, -40, 0, 0, 48, 0, 24, 0 }
  local yo = { [0] = -32, 0, -32, -48, 0, -48, 0, -48 }
  local dl = { [0] = 16, 12, 16, 0, 0, 4, 8, 8 }
  if d[0] == 0 then
    s.x2 = xo[d[6]]
    s.y2 = yo[d[6]]
    d[1] = dl[d[6]]
    d[0] = 1
  end
  if d[0] == 1 then
    local c = d[1]
    d[1] = c - 1
    if c == 0 then d[0] = d[0] + 1 end
  elseif d[0] == 2 then
    if s.x2 > 0 then s.x2 = s.x2 - 4 elseif s.x2 < 0 then s.x2 = s.x2 + 4 end
    if s.y2 > 0 then s.y2 = s.y2 - 4 elseif s.y2 < 0 then s.y2 = s.y2 + 4 end
    if s.x2 == 0 and s.y2 == 0 then d[0] = d[0] + 1 end
  end
end

-- pokeemerald/src/slot_machine.c:4924
local function cbBigBonus(self, s)
  local d = s.data
  local sp0 = { [0] = 160, 192, 224, 104, 80, 64, 48, 24 }
  if d[0] == 0 then
    d[0] = d[0] + 1
    d[1] = 12
  end
  s.x2 = Kit.cos(self.T, sp0[d[6]], d[1])
  s.y2 = Kit.sin(self.T, sp0[d[6]], d[1])
  if d[1] ~= 0 then d[1] = d[1] - 1 end
end

-- pokeemerald/src/slot_machine.c:4941
local function cbAButtonStart(self, s)
  local d = s.data
  local sm = self.sm
  if d[0] == 0 then
    sm.winIn = WININ_WIN0_BG_ALL + WININ_WIN0_CLR
    sm.winOut = WINOUT_WIN01_BG_ALL + WINOUT_WIN01_OBJ + WINOUT_WIN01_CLR
    sm.win0v = winRange(32, 136)
    s.invisible = true
    d[0] = 1
  end
  if d[0] == 1 then
    d[1] = d[1] + 2
    d[2] = d[1] + 176
    d[3] = DISPLAY_WIDTH - d[1]
    if d[2] > 208 then d[2] = 208 end
    if d[3] < 208 then d[3] = 208 end
    sm.win0h = lshift(d[2], 8) + d[3]
    if d[1] > 51 then
      d[0] = d[0] + 1
      sm.winIn = WININ_WIN0_BG_ALL + WININ_WIN0_OBJ + WININ_WIN0_CLR
    end
  elseif d[0] == 2 then
    if self.core.bet == 0 then return end
    self:addDigitalDisplaySprite(DIG_SPRITE_A_BUTTON, nil, 208, 116, 0)
    sm.win0h = winRange(192, 224)
    sm.win0v = winRange(104, 128)
    sm.winIn = WININ_WIN0_BG_ALL + WININ_WIN0_CLR
    d[0] = d[0] + 1
    d[1] = 0
    d[1] = d[1] + 2
    d[2] = d[1] + 192
    d[3] = DISPLAY_WIDTH - 16 - d[1]
    if d[2] > 208 then d[2] = 208 end
    if d[3] < 208 then d[3] = 208 end
    sm.win0h = lshift(d[2], 8) + d[3]
    if d[1] > 15 then
      d[0] = d[0] + 1
      sm.winIn = WININ_WIN0_BG_ALL + WININ_WIN0_OBJ + WININ_WIN0_CLR
    end
  elseif d[0] == 3 then
    d[1] = d[1] + 2
    d[2] = d[1] + 192
    d[3] = DISPLAY_WIDTH - 16 - d[1]
    if d[2] > 208 then d[2] = 208 end
    if d[3] < 208 then d[3] = 208 end
    sm.win0h = lshift(d[2], 8) + d[3]
    if d[1] > 15 then
      d[0] = d[0] + 1
      sm.winIn = WININ_WIN0_BG_ALL + WININ_WIN0_OBJ + WININ_WIN0_CLR
    end
  end
end

-- pokeemerald/src/slot_machine.c:5555
DIG_CALLBACKS = {
  [0] = cbStatic, cbStop, cbStop, cbStop, cbStop, cbAButtonStop, cbPokeballRocking, cbStatic, cbStatic,
  cbSmoke, cbSmokeNE, cbSmokeSW, cbSmokeSE, cbReel, cbTime, cbReelTimeNumber, cbStatic, cbPokeballShining,
  cbRegBonus, cbRegBonus, cbRegBonus, cbRegBonus, cbRegBonus, cbRegBonus, cbRegBonus, cbRegBonus,
  cbBigBonus, cbBigBonus, cbBigBonus, cbBigBonus, cbBigBonus, cbBigBonus, cbBigBonus, cbBigBonus,
  cbAButtonStart,
}

-- pokeemerald/src/slot_machine.c:5668
SCENE_EXIT = {
  [DIG.INSERT_BET] = function(self)
    local sm = self.sm
    sm.win0h = DISPLAY_WIDTH
    sm.win0v = DISPLAY_HEIGHT
    sm.winIn = WININ_WIN0_BG_ALL + WININ_WIN0_OBJ + WININ_WIN0_CLR
    sm.winOut = WINOUT_WIN01_BG_ALL + WINOUT_WIN01_OBJ + WINOUT_WIN01_CLR
  end,
  [DIG.STOP_REEL] = function(self) self.mosaic = 0 end,
  [DIG.WIN] = function(self) self:restoreDigitalDisplayPalette() end,
  [DIG.BONUS_REG] = function(self) self:restoreDigitalDisplayPalette() end,
  [DIG.BONUS_BIG] = function(self) self:restoreDigitalDisplayPalette() end,
}

function UI:restoreDigitalDisplayPalette()
  local idx = 256 + self.m.ppu.sprites:indexOfPaletteTag(PALTAG.DIG_DISPLAY) * 16
  self.m.ppu.palette:load(self.man.palettes.pokeballShining[3], idx, 16)
end

function UI:showMessage(key)
  self.message = { key = key, text = Kit.text(key) }
end

function UI:clearMessage()
  self.message = nil
  self.yesNo = nil
end

-- pokeemerald/src/menu.c:1013
function UI:processYesNo()
  local yn = self.yesNo
  if not yn then return -2 end
  if joyNew(self, Kit.A) then
    self.sound:se("SE_SELECT")
    return yn.cursor
  elseif joyNew(self, Kit.B) then
    return -1
  elseif joyNew(self, Kit.UP) then
    if yn.cursor > 0 then
      self.sound:se("SE_SELECT")
      yn.cursor = yn.cursor - 1
    end
  elseif joyNew(self, Kit.DOWN) then
    if yn.cursor < 1 then
      self.sound:se("SE_SELECT")
      yn.cursor = yn.cursor + 1
    end
  end
  return -2
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
  self.m.ppu:draw(0, 0)
  self:drawOverlay()
end

-- pokeemerald/src/slot_machine.c:3935
function UI:drawOverlay()
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  if self.infoWindow and self.infoWindow.text then
    local pal = self.m.ppu.palette
    local fade = pal.active and pal.y or 0
    local u = self.man.palettes.unk
    local colors = { fg = Kit.color555(u[2]), bg = Kit.color555(u[4]), shadow = Kit.color555(u[3]) }
    local text = Kit.text("gText_ReelTimeHelp")
    local pitch = Kit.linePitch()
    local y = 3 * 8 + 5
    for line in (text .. "\n"):gmatch("(.-)\n") do
      local w = Kit.measure(line)
      if w > 0 then
        local k = (16 - fade) / 16
        love.graphics.setColor(colors.bg[1] * k, colors.bg[2] * k, colors.bg[3] * k, 1)
        love.graphics.rectangle("fill", 8 + 2, y, w, pitch)
        love.graphics.setColor(1, 1, 1, 1)
      end
      Kit.drawText(line, 8 + 2, y, colors, fade)
      y = y + pitch
    end
  end
  if self.message then
    SceneKit.birchDialogueFrame(2, 15, 27, 4)
    Kit.drawText(self.message.text, 2 * 8, 15 * 8 + 1, SceneKit.messageColors())
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
    Stack.pop("rse_slot_machine")
    if userDone then userDone(screen) end
  end
  Stack.push("rse_slot_machine", Host, { hideBelow = true, fullscreen = true })
  return screen
end

function UI.active()
  return Host._screen
end

function UI.reset()
  if Host._screen then
    Host._screen = nil
    require("src.ui.game3.stack").pop("rse_slot_machine")
  end
  Host._step = nil
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

return UI
