local bit = require("bit")
local band, bor, bnot, rshift, lshift = bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift

local Slots = {}
Slots.__index = Slots

Slots.SUB = "rse_slot_machine"
Slots.MANIFEST = "data/generated/gba/rse_slot_machine/manifest.lua"

-- pokeemerald/src/slot_machine.c:32
Slots.MAX_BET = 3
Slots.SYMBOLS_PER_REEL = 21
Slots.REEL_SYMBOL_HEIGHT = 24
Slots.REEL_HEIGHT = 21 * 24
Slots.REELTIME_SYMBOLS = 6
Slots.REELTIME_SYMBOL_HEIGHT = 20
Slots.REELTIME_REEL_HEIGHT = 6 * 20
Slots.MAX_EXTRA_TURNS = 4
Slots.NUM_REELS = 3
-- pokeemerald/include/constants/coins.h:4
Slots.MAX_COINS = 9999

-- pokeemerald/src/slot_machine.c:55
Slots.BIAS = {
  REPLAY = 1, CHERRY = 2, LOTAD = 4, AZURILL = 8, POWER = 16, REELTIME = 32, MIXED_7 = 64, STRAIGHT_7 = 128,
}
local BIAS = Slots.BIAS
local BIAS_7 = BIAS.STRAIGHT_7 + BIAS.MIXED_7

-- pokeemerald/src/slot_machine.c:77
Slots.SYMBOL = { RED_7 = 0, BLUE_7 = 1, AZURILL = 2, LOTAD = 3, CHERRY = 4, POWER = 5, REPLAY = 6 }
local SYM = Slots.SYMBOL

-- pokeemerald/src/slot_machine.c:131
Slots.MATCH = {
  CHERRY = 0, TOPBOT_CHERRY = 1, REPLAY = 2, LOTAD = 3, AZURILL = 4, POWER = 5,
  MIXED_7 = 6, RED_7 = 7, BLUE_7 = 8, NONE = 9,
}
local MATCH = Slots.MATCH

-- pokeemerald/src/slot_machine.c:144
Slots.LINE = { MIDDLE_ROW = 0, TOP_ROW = 1, BOTTOM_ROW = 2, NWSE_DIAG = 3, NESW_DIAG = 4 }
local LINE = Slots.LINE

-- pokeemerald/src/slot_machine.c:115
Slots.REEL_NORMAL_SPEED = 8
Slots.REEL_HALF_SPEED = 4
Slots.REEL_QUARTER_SPEED = 2

local function s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end
Slots.s16 = s16

local function cmod(a, b)
  return math.fmod(a, b)
end

local function cdiv(a, b)
  local q = a / b
  if q >= 0 then return math.floor(q) end
  return math.ceil(q)
end

function Slots.loadTables(cache)
  local body
  if cache and cache.read then
    body = cache:read(Slots.MANIFEST)
  else
    local ok, Dataset = pcall(require, "src.core.game3.dataset")
    if ok and Dataset and Dataset.cache then body = Dataset.cache():read(Slots.MANIFEST) end
  end
  assert(type(body) == "string", "slot_machine: missing " .. Slots.MANIFEST)
  local chunk = assert(load(body, "@" .. Slots.MANIFEST, "t", {}))
  return chunk()
end

function Slots.new(tables, opts)
  opts = opts or {}
  local self = setmetatable({}, Slots)
  self.T = tables
  self.random = opts.random or function() return require("src.core.game3.rng").Random() end
  self.flashMatchLine = opts.flashMatchLine
  self.state = 0
  self.machineId = 0
  self.pikaPowerBolts = 0
  self.luckyGame = false
  self.machineBias = 0
  self.reelTimeDraw = 0
  self.didNotFailBias = false
  self.biasSymbol = 0
  self.matches = 0
  self.reelTimeSpinsLeft = 0
  self.reelTimeSpinsUsed = 0
  self.coins = 0
  self.payout = 0
  self.netCoinLoss = 0
  self.bet = 0
  self.reeltimePixelOffset = 0
  self.reeltimePosition = 0
  self.currentReel = 0
  self.reelSpeed = Slots.REEL_NORMAL_SPEED
  self.reelPixelOffsets = { [0] = 0, 0, 0 }
  self.reelShockOffsets = { [0] = 0, 0, 0 }
  self.reelPositions = { [0] = 0, 0, 0 }
  self.reelExtraTurns = { [0] = 0, 0, 0 }
  self.winnerRows = { [0] = 0, 0, 0 }
  return self
end

function Slots:rand()
  return band(self.random(), 0xFFFF)
end

-- pokeemerald/src/slot_machine.c:1191
function Slots:init(machineId, coins)
  self.machineId = machineId or 0
  self.state = 0
  self.pikaPowerBolts = 0
  self.luckyGame = band(self:rand(), 1) == 1
  self.machineBias = 0
  self.matches = 0
  self.reelTimeSpinsLeft = 0
  self.reelTimeSpinsUsed = 0
  self.coins = s16(coins or 0)
  self.payout = 0
  self.netCoinLoss = 0
  self.bet = 0
  self.currentReel = 0
  self.reelSpeed = Slots.REEL_NORMAL_SPEED
  local lucky = self.luckyGame and 1 or 0
  for i = 0, 2 do
    self.reelShockOffsets[i] = 0
    self.reelPositions[i] = cmod(self.T.initialReelPositions[i][lucky], Slots.SYMBOLS_PER_REEL)
    self.reelPixelOffsets[i] = cmod(Slots.REEL_HEIGHT - self.reelPositions[i] * Slots.REEL_SYMBOL_HEIGHT, Slots.REEL_HEIGHT)
  end
end

-- pokeemerald/src/slot_machine.c:1797
function Slots:drawMachineBias()
  if self.reelTimeSpinsLeft ~= 0 then return end
  if band(self.machineBias, BIAS_7) ~= 0 then return end
  if self:shouldTrySpecialBias() then
    local which = self:trySelectBiasSpecial()
    if which ~= 3 then
      self.machineBias = bor(self.machineBias, self.T.biasesSpecial[which])
      if which ~= 1 then return end
    end
  end
  local which = self:trySelectBiasRegular()
  if which ~= 5 then
    self.machineBias = bor(self.machineBias, self.T.biasesRegular[which])
  end
end

-- pokeemerald/src/slot_machine.c:1825
function Slots:resetBiasFailure()
  self.didNotFailBias = self.machineBias ~= 0
end

-- pokeemerald/src/slot_machine.c:1833
function Slots:getBiasSymbol(machineBias)
  for i = 0, 7 do
    if band(machineBias, 1) ~= 0 then return self.T.biasSymbols[i] end
    machineBias = rshift(machineBias, 1)
  end
  return 0
end

-- pokeemerald/src/slot_machine.c:1853
function Slots:shouldTrySpecialBias()
  local rval = band(self:rand(), 0xFF)
  return self.T.specialDrawOdds[self.machineId][self.bet - 1] > rval
end

-- pokeemerald/src/slot_machine.c:1866
function Slots:trySelectBiasSpecial()
  local which = 0
  while which < 3 do
    local rval = band(self:rand(), 0xFF)
    if self.T.biasProbSpecial[which][self.machineId] > rval then break end
    which = which + 1
  end
  return which
end

-- pokeemerald/src/slot_machine.c:1880
function Slots:trySelectBiasRegular()
  local which = 0
  while which < 5 do
    local rval = band(self:rand(), 0xFF)
    local value = self.T.biasProbRegular[which][self.machineId]
    if which == 0 and self.luckyGame then
      value = value + 10
      if value > 0x100 then value = 0x100 end
    elseif which == 4 and self.luckyGame then
      value = value - 10
      if value < 0 then value = 0 end
    end
    if value > rval then break end
    which = which + 1
  end
  return which
end

-- pokeemerald/src/slot_machine.c:1913
function Slots:getReelTimeSpinProbability(spins)
  if not self.luckyGame then return self.T.reelTimeProbNormal[spins][self.pikaPowerBolts] end
  return self.T.reelTimeProbLucky[spins][self.pikaPowerBolts]
end

-- pokeemerald/src/slot_machine.c:1930
function Slots:getReelTimeDraw()
  self.reelTimeDraw = 0
  local rval = band(self:rand(), 0xFF)
  if rval < self:getReelTimeSpinProbability(0) then return end
  local spins = 5
  while spins > 0 do
    rval = band(self:rand(), 0xFF)
    if rval < self:getReelTimeSpinProbability(spins) then break end
    spins = spins - 1
  end
  self.reelTimeDraw = spins
end

-- pokeemerald/src/slot_machine.c:1950
function Slots:shouldReelTimeMachineExplode(check)
  local rval = band(self:rand(), 0xFF)
  return rval < self.T.reelTimeExplodeProb[check]
end

-- pokeemerald/src/slot_machine.c:1959
function Slots:reelTimeSpeed()
  local i = 0
  local loss = self.netCoinLoss
  if loss >= 300 then i = 4
  elseif loss >= 250 then i = 3
  elseif loss >= 200 then i = 2
  elseif loss >= 150 then i = 1 end
  local rval = band(self:rand(), 0xFFFF) % 100
  local value = band(self.T.reelTimeSpeedProb[i][0], 0xFF)
  if rval < value then return Slots.REEL_HALF_SPEED end
  rval = band(self:rand(), 0xFFFF) % 100
  value = band(self.T.reelTimeSpeedProb[i][1] + self.T.quarterSpeedBoost[self.reelTimeSpinsUsed], 0xFF)
  if rval < value then return Slots.REEL_QUARTER_SPEED end
  return Slots.REEL_NORMAL_SPEED
end

-- pokeemerald/src/slot_machine.c:1986
function Slots:checkMatch()
  self.matches = 0
  self:checkMatchCenterRow()
  if self.bet > 1 then self:checkMatchTopAndBottom() end
  if self.bet > 2 then self:checkMatchDiagonals() end
end

function Slots:_flash(line)
  if self.flashMatchLine then self.flashMatchLine(line) end
end

function Slots:_award(match)
  self.payout = s16(self.payout + self.T.payouts[match])
  self.matches = bor(self.matches, self.T.matchFlags[match])
end

-- pokeemerald/src/slot_machine.c:1996
function Slots:checkMatchCenterRow()
  local m = self:getMatchFromSymbols(self:getSymbolAtRest(0, 2), self:getSymbolAtRest(1, 2), self:getSymbolAtRest(2, 2))
  if m ~= MATCH.NONE then
    self:_award(m)
    self:_flash(LINE.MIDDLE_ROW)
  end
end

-- pokeemerald/src/slot_machine.c:2012
function Slots:checkMatchTopAndBottom()
  for _, row in ipairs({ { 1, LINE.TOP_ROW }, { 3, LINE.BOTTOM_ROW } }) do
    local r = row[1]
    local m = self:getMatchFromSymbols(self:getSymbolAtRest(0, r), self:getSymbolAtRest(1, r), self:getSymbolAtRest(2, r))
    if m ~= MATCH.NONE then
      if m == MATCH.CHERRY then m = MATCH.TOPBOT_CHERRY end
      self:_award(m)
      self:_flash(row[2])
    end
  end
end

-- pokeemerald/src/slot_machine.c:2042
function Slots:checkMatchDiagonals()
  for _, d in ipairs({ { 1, 3, LINE.NWSE_DIAG }, { 3, 1, LINE.NESW_DIAG } }) do
    local m = self:getMatchFromSymbols(self:getSymbolAtRest(0, d[1]), self:getSymbolAtRest(1, 2), self:getSymbolAtRest(2, d[2]))
    if m ~= MATCH.NONE then
      if m ~= MATCH.CHERRY then self:_award(m) end
      self:_flash(d[3])
    end
  end
end

-- pokeemerald/src/slot_machine.c:2078
function Slots:getMatchFromSymbols(s1, s2, s3)
  if s1 == s2 and s1 == s3 then return self.T.symbolToMatch[s1] end
  if s1 == SYM.RED_7 and s2 == SYM.RED_7 and s3 == SYM.BLUE_7 then return MATCH.MIXED_7 end
  if s1 == SYM.BLUE_7 and s2 == SYM.BLUE_7 and s3 == SYM.RED_7 then return MATCH.MIXED_7 end
  if s1 == SYM.CHERRY then return MATCH.CHERRY end
  return MATCH.NONE
end

-- pokeemerald/src/slot_machine.c:2174
function Slots:getSymbolAtRest(reel, offset)
  local pos = s16(cmod(self.reelPositions[reel] + offset, Slots.SYMBOLS_PER_REEL))
  if pos < 0 then pos = pos + Slots.SYMBOLS_PER_REEL end
  return self.T.reelSymbols[reel][pos]
end

-- pokeemerald/src/slot_machine.c:2183
function Slots:getSymbol(reel, offset)
  local inc = 0
  if cmod(self.reelPixelOffsets[reel], Slots.REEL_SYMBOL_HEIGHT) ~= 0 then inc = -1 end
  return self:getSymbolAtRest(reel, offset + inc)
end

-- pokeemerald/src/slot_machine.c:2192
function Slots:getReelTimeSymbol(offset)
  local p = s16(cmod(self.reeltimePosition + offset, Slots.REELTIME_SYMBOLS))
  if p < 0 then p = p + Slots.REELTIME_SYMBOLS end
  return self.T.reelTimeSymbols[p]
end

-- pokeemerald/src/slot_machine.c:2200
function Slots:advanceSlotReel(reel, value)
  local v = s16(self.reelPixelOffsets[reel] + value)
  v = cmod(v, Slots.REEL_HEIGHT)
  self.reelPixelOffsets[reel] = v
  self.reelPositions[reel] = s16(Slots.SYMBOLS_PER_REEL - cdiv(v, Slots.REEL_SYMBOL_HEIGHT))
end

-- pokeemerald/src/slot_machine.c:2209
function Slots:advanceSlotReelToNextSymbol(reel, value)
  local offset = cmod(self.reelPixelOffsets[reel], Slots.REEL_SYMBOL_HEIGHT)
  if offset ~= 0 then
    if offset < value then value = offset end
    self:advanceSlotReel(reel, value)
    offset = cmod(self.reelPixelOffsets[reel], Slots.REEL_SYMBOL_HEIGHT)
  end
  return offset
end

-- pokeemerald/src/slot_machine.c:2222
function Slots:advanceReeltimeReel(value)
  local v = s16(self.reeltimePixelOffset + value)
  v = cmod(v, Slots.REELTIME_REEL_HEIGHT)
  self.reeltimePixelOffset = v
  self.reeltimePosition = s16(Slots.REELTIME_SYMBOLS - cdiv(v, Slots.REELTIME_SYMBOL_HEIGHT))
end

-- pokeemerald/src/slot_machine.c:2231
function Slots:advanceReeltimeReelToNextSymbol(value)
  local offset = cmod(self.reeltimePixelOffset, Slots.REELTIME_SYMBOL_HEIGHT)
  if offset ~= 0 then
    if offset < value then value = offset end
    self:advanceReeltimeReel(value)
    offset = cmod(self.reeltimePixelOffset, Slots.REELTIME_SYMBOL_HEIGHT)
  end
  return offset
end

-- pokeemerald/src/slot_machine.c:2305
function Slots:decideStop(reel)
  self.winnerRows[reel] = 0
  self.reelExtraTurns[reel] = 0
  if self.reelTimeSpinsLeft == 0 then
    local biasOk = false
    if self.machineBias ~= 0 and self.didNotFailBias then
      biasOk = self:decideStopBias(reel)
    end
    if not biasOk then
      self.didNotFailBias = false
      self:decideStopNoBias(reel)
    end
  end
  return self.reelExtraTurns[reel]
end

function Slots:decideStopBias(reel)
  if reel == 0 then return self:decideStopBiasReel1() end
  if reel == 1 then return self:decideStopBiasReel2() end
  return self:decideStopBiasReel3()
end

function Slots:decideStopNoBias(reel)
  if reel == 0 then return self:decideStopNoBiasReel1() end
  if reel == 1 then return self:decideStopNoBiasReel2() end
  return self:decideStopNoBiasReel3()
end

-- pokeemerald/src/slot_machine.c:2378
function Slots:decideStopBiasReel1()
  local sym2 = self:getBiasSymbol(self.machineBias)
  local sym1 = sym2
  if band(self.machineBias, BIAS_7) ~= 0 then
    sym1, sym2 = SYM.RED_7, SYM.BLUE_7
  end
  if self.bet == 1 then return self:decideStopBiasReel1Bet1(sym1, sym2) end
  return self:decideStopBiasReel1Bet2or3(sym1, sym2)
end

-- pokeemerald/src/slot_machine.c:2393
function Slots:eitherSymbolAtPosReel1(pos, sym1, sym2)
  local sym = self:getSymbol(0, pos)
  if sym == sym1 or sym == sym2 then
    self.biasSymbol = sym
    return true
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2406
function Slots:areCherriesOnScreenReel1(turns)
  return self:getSymbol(0, 1 - turns) == SYM.CHERRY or self:getSymbol(0, 2 - turns) == SYM.CHERRY
    or self:getSymbol(0, 3 - turns) == SYM.CHERRY
end

-- pokeemerald/src/slot_machine.c:2416
function Slots:biasedTowardCherryOr7s()
  return band(self.machineBias, BIAS_7 + BIAS.CHERRY) ~= 0
end

-- pokeemerald/src/slot_machine.c:2426
function Slots:decideStopBiasReel1Bet1(sym1, sym2)
  for i = 0, Slots.MAX_EXTRA_TURNS do
    if self:eitherSymbolAtPosReel1(2 - i, sym1, sym2) then
      self.winnerRows[0] = 2
      self.reelExtraTurns[0] = i
      return true
    end
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2465
function Slots:decideStopBiasReel1Bet2or3(sym1, sym2)
  local cherry7 = self:biasedTowardCherryOr7s()
  if cherry7 or not self:areCherriesOnScreenReel1(0) then
    for i = 1, 3 do
      if self:eitherSymbolAtPosReel1(i, sym1, sym2) then
        self.winnerRows[0] = i
        self.reelExtraTurns[0] = 0
        return true
      end
    end
  end
  for i = 1, Slots.MAX_EXTRA_TURNS do
    if cherry7 or not self:areCherriesOnScreenReel1(i) then
      if self:eitherSymbolAtPosReel1(1 - i, sym1, sym2) then
        if i == 1 and (cherry7 or not self:areCherriesOnScreenReel1(3)) then
          self.winnerRows[0] = 3
          self.reelExtraTurns[0] = 3
          return true
        end
        if i <= 3 and (cherry7 or not self:areCherriesOnScreenReel1(i + 1)) then
          self.winnerRows[0] = 2
          self.reelExtraTurns[0] = i + 1
          return true
        end
        self.winnerRows[0] = 1
        self.reelExtraTurns[0] = i
        return true
      end
    end
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2512
function Slots:decideStopBiasReel2()
  if self.bet == 3 then return self:decideStopBiasReel2Bet3() end
  return self:decideStopBiasReel2Bet1or2()
end

-- pokeemerald/src/slot_machine.c:2519
function Slots:decideStopBiasReel2Bet1or2()
  local row = self.winnerRows[0]
  for i = 0, Slots.MAX_EXTRA_TURNS do
    if self:getSymbol(1, row - i) == self.biasSymbol then
      self.winnerRows[1] = row
      self.reelExtraTurns[1] = i
      return true
    end
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2569
function Slots:decideStopBiasReel2Bet3()
  if self:decideStopBiasReel2Bet1or2() then
    if self.winnerRows[0] ~= 2 and self.reelExtraTurns[1] > 1 and self.reelExtraTurns[1] ~= 4 then
      for i = 0, Slots.MAX_EXTRA_TURNS do
        if self:getSymbol(1, 2 - i) == self.biasSymbol then
          self.winnerRows[1] = 2
          self.reelExtraTurns[1] = i
          break
        end
      end
    end
    return true
  end
  if self.winnerRows[0] ~= 2 then
    for i = 0, Slots.MAX_EXTRA_TURNS do
      if self:getSymbol(1, 2 - i) == self.biasSymbol then
        self.winnerRows[1] = 2
        self.reelExtraTurns[1] = i
        return true
      end
    end
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2616
function Slots:decideStopBiasReel3()
  local biasSymbol = self.biasSymbol
  if band(self.machineBias, BIAS.MIXED_7) ~= 0 then
    biasSymbol = SYM.RED_7
    if self.biasSymbol == SYM.RED_7 then biasSymbol = SYM.BLUE_7 end
  end
  if self.bet == 3 then return self:decideStopBiasReel3Bet3(biasSymbol) end
  return self:decideStopBiasReel3Bet1or2(biasSymbol)
end

-- pokeemerald/src/slot_machine.c:2632
function Slots:decideStopBiasReel3Bet1or2(biasSymbol)
  local row = self.winnerRows[1]
  for i = 0, Slots.MAX_EXTRA_TURNS do
    if self:getSymbol(2, row - i) == biasSymbol then
      self.winnerRows[2] = row
      self.reelExtraTurns[2] = i
      return true
    end
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2651
function Slots:decideStopBiasReel3Bet3(biasSymbol)
  if self.winnerRows[0] == self.winnerRows[1] then return self:decideStopBiasReel3Bet1or2(biasSymbol) end
  local row = (self.winnerRows[0] == 1) and 3 or 1
  for i = 0, Slots.MAX_EXTRA_TURNS do
    if self:getSymbol(2, row - i) == biasSymbol then
      self.reelExtraTurns[2] = i
      self.winnerRows[2] = row
      return true
    end
  end
  return false
end

-- pokeemerald/src/slot_machine.c:2682
function Slots:decideStopNoBiasReel1()
  local i = 0
  while self:areCherriesOnScreenReel1(i) do i = i + 1 end
  self.reelExtraTurns[0] = i
end

-- pokeemerald/src/slot_machine.c:2693
local function switch7(sym)
  if sym == SYM.RED_7 then return SYM.BLUE_7, true end
  if sym == SYM.BLUE_7 then return SYM.RED_7, true end
  return sym, false
end

-- pokeemerald/src/slot_machine.c:2716
function Slots:decideStopNoBiasReel2()
  if self.bet == 1 then return self:decideStopNoBiasReel2Bet1() end
  if self.bet == 2 then return self:decideStopNoBiasReel2Bet2() end
  return self:decideStopNoBiasReel2Bet3()
end

-- pokeemerald/src/slot_machine.c:2731
function Slots:decideStopNoBiasReel2Bet1()
  if self.winnerRows[0] ~= 0 and band(self.machineBias, BIAS.STRAIGHT_7) ~= 0 then
    local sym, is7 = switch7(self:getSymbol(0, 2 - self.reelExtraTurns[0]))
    if is7 then
      for i = 0, Slots.MAX_EXTRA_TURNS do
        if sym == self:getSymbol(1, 2 - i) then
          self.winnerRows[1] = 2
          self.reelExtraTurns[1] = i
          break
        end
      end
    end
  end
end

-- pokeemerald/src/slot_machine.c:2765
function Slots:decideStopNoBiasReel2Bet2()
  if self.winnerRows[0] ~= 0 and band(self.machineBias, BIAS.STRAIGHT_7) ~= 0 then
    local sym, is7 = switch7(self:getSymbol(0, self.winnerRows[0] - self.reelExtraTurns[0]))
    if is7 then
      for i = 0, Slots.MAX_EXTRA_TURNS do
        if sym == self:getSymbol(1, self.winnerRows[0] - i) then
          self.winnerRows[1] = self.winnerRows[0]
          self.reelExtraTurns[1] = i
          break
        end
      end
    end
  end
end

-- pokeemerald/src/slot_machine.c:2828
function Slots:decideStopNoBiasReel2Bet3()
  if self.winnerRows[0] ~= 0 and band(self.machineBias, BIAS.STRAIGHT_7) ~= 0 then
    if self.winnerRows[0] == 2 then
      self:decideStopNoBiasReel2Bet2()
      return
    end
    local sym, is7 = switch7(self:getSymbol(0, self.winnerRows[0] - self.reelExtraTurns[0]))
    if is7 then
      local j = (self.winnerRows[0] == 3) and 3 or 2
      for _ = 0, 1 do
        if sym == self:getSymbol(1, j) then
          self.winnerRows[1] = j
          self.reelExtraTurns[1] = 0
          return
        end
        j = j - 1
      end
      for jj = 1, Slots.MAX_EXTRA_TURNS do
        if sym == self:getSymbol(1, self.winnerRows[0] - jj) then
          if self.winnerRows[0] == 1 then
            if jj <= 2 then
              self.winnerRows[1] = 2
              self.reelExtraTurns[1] = jj + 1
            else
              self.winnerRows[1] = 1
              self.reelExtraTurns[1] = jj
            end
          else
            if jj <= 2 then
              self.winnerRows[1] = 3
              self.reelExtraTurns[1] = jj
            else
              self.winnerRows[1] = 2
              self.reelExtraTurns[1] = jj - 1
            end
          end
          return
        end
      end
    end
  end
end

-- pokeemerald/src/slot_machine.c:2906
local function mismatched77(a, b)
  return (a == SYM.RED_7 and b == SYM.BLUE_7) or (a == SYM.BLUE_7 and b == SYM.RED_7)
end

-- pokeemerald/src/slot_machine.c:2916
local function mismatched777(a, b, c)
  return (a == SYM.RED_7 and b == SYM.BLUE_7 and c == SYM.RED_7) or (a == SYM.BLUE_7 and b == SYM.RED_7 and c == SYM.BLUE_7)
end

-- pokeemerald/src/slot_machine.c:2930
local function neitherMatchNor7Mismatch(a, b, c)
  if (a == SYM.RED_7 and b == SYM.BLUE_7 and c == SYM.RED_7)
      or (a == SYM.BLUE_7 and b == SYM.RED_7 and c == SYM.BLUE_7)
      or (a == SYM.RED_7 and b == SYM.RED_7 and c == SYM.BLUE_7)
      or (a == SYM.BLUE_7 and b == SYM.BLUE_7 and c == SYM.RED_7)
      or (a == b and a == c) then
    return false
  end
  return true
end
Slots.neitherMatchNor7Mismatch = neitherMatchNor7Mismatch

-- pokeemerald/src/slot_machine.c:2945
function Slots:decideStopNoBiasReel3()
  if self.bet == 1 then return self:decideStopNoBiasReel3Bet1() end
  if self.bet == 2 then return self:decideStopNoBiasReel3Bet2() end
  return self:decideStopNoBiasReel3Bet3()
end

-- pokeemerald/src/slot_machine.c:2964
function Slots:decideStopNoBiasReel3Bet1()
  local i = 0
  local sym1 = self:getSymbol(0, 2 - self.reelExtraTurns[0])
  local sym2 = self:getSymbol(1, 2 - self.reelExtraTurns[1])
  if sym1 == sym2 then
    while true do
      local sym3 = self:getSymbol(2, 2 - i)
      if not (sym1 == sym3 or (sym1 == SYM.RED_7 and sym3 == SYM.BLUE_7) or (sym1 == SYM.BLUE_7 and sym3 == SYM.RED_7)) then
        break
      end
      i = i + 1
    end
  elseif mismatched77(sym1, sym2) then
    if band(self.machineBias, BIAS.STRAIGHT_7) ~= 0 then
      for k = 0, Slots.MAX_EXTRA_TURNS do
        if sym1 == self:getSymbol(2, 2 - k) then
          self.reelExtraTurns[2] = k
          return
        end
      end
    end
    i = 0
    while sym1 == self:getSymbol(2, 2 - i) do i = i + 1 end
  end
  self.reelExtraTurns[2] = i
end

-- pokeemerald/src/slot_machine.c:3029
function Slots:decideStopNoBiasReel3Bet2()
  local extraTurns = 0
  if self.winnerRows[1] ~= 0 and self.winnerRows[0] == self.winnerRows[1] and band(self.machineBias, BIAS.STRAIGHT_7) ~= 0 then
    local sym1 = self:getSymbol(0, self.winnerRows[0] - self.reelExtraTurns[0])
    local sym2 = self:getSymbol(1, self.winnerRows[1] - self.reelExtraTurns[1])
    if mismatched77(sym1, sym2) then
      for i = 0, Slots.MAX_EXTRA_TURNS do
        if sym1 == self:getSymbol(2, self.winnerRows[1] - i) then
          extraTurns = i
          break
        end
      end
    end
  end
  local straight7 = band(self.machineBias, BIAS.STRAIGHT_7) ~= 0
  while true do
    local numMatches = 0
    for i = 1, 3 do
      local a = self:getSymbol(0, i - self.reelExtraTurns[0])
      local b = self:getSymbol(1, i - self.reelExtraTurns[1])
      local c = self:getSymbol(2, i - extraTurns)
      if not neitherMatchNor7Mismatch(a, b, c) and not (mismatched777(a, b, c) and straight7) then
        numMatches = numMatches + 1
        break
      end
    end
    if numMatches == 0 then break end
    extraTurns = extraTurns + 1
  end
  self.reelExtraTurns[2] = extraTurns
end

-- pokeemerald/src/slot_machine.c:3123
function Slots:decideStopNoBiasReel3Bet3()
  self:decideStopNoBiasReel3Bet2()
  local straight7 = band(self.machineBias, BIAS.STRAIGHT_7) ~= 0
  if self.winnerRows[1] ~= 0 and self.winnerRows[0] ~= self.winnerRows[1] and straight7 then
    local sym1 = self:getSymbol(0, self.winnerRows[0] - self.reelExtraTurns[0])
    local sym2 = self:getSymbol(1, self.winnerRows[1] - self.reelExtraTurns[1])
    if mismatched77(sym1, sym2) then
      local row = (self.winnerRows[0] == 1) and 3 or 1
      for i = 0, Slots.MAX_EXTRA_TURNS do
        if sym1 == self:getSymbol(2, row - (self.reelExtraTurns[2] + i)) then
          self.reelExtraTurns[2] = self.reelExtraTurns[2] + i
          break
        end
      end
    end
  end
  for _, rows in ipairs({ { 1, 3 }, { 3, 1 } }) do
    while true do
      local a = self:getSymbol(0, rows[1] - self.reelExtraTurns[0])
      local b = self:getSymbol(1, 2 - self.reelExtraTurns[1])
      local c = self:getSymbol(2, rows[2] - self.reelExtraTurns[2])
      if neitherMatchNor7Mismatch(a, b, c) or (mismatched777(a, b, c) and straight7) then break end
      self.reelExtraTurns[2] = self.reelExtraTurns[2] + 1
    end
  end
end

-- pokeemerald/src/slot_machine.c:1506
function Slots:applyMatchResults()
  self.machineBias = band(self.machineBias, BIAS_7)
  self:checkMatch()
  if self.reelTimeSpinsLeft ~= 0 then
    self.reelTimeSpinsLeft = self.reelTimeSpinsLeft - 1
    self.reelTimeSpinsUsed = self.reelTimeSpinsUsed + 1
  end
  local out = { won = self.matches ~= 0 }
  if self.matches ~= 0 then
    self.netCoinLoss = s16(self.netCoinLoss - self.payout)
    if self.netCoinLoss < 0 then self.netCoinLoss = 0 end
    local m = self.matches
    local jackpot = lshift(1, MATCH.BLUE_7) + lshift(1, MATCH.RED_7)
    if band(m, jackpot) ~= 0 then out.scene = "big"
    elseif band(m, lshift(1, MATCH.MIXED_7)) ~= 0 then out.scene = "reg"
    else out.scene = "win" end
    if band(m, jackpot + lshift(1, MATCH.MIXED_7)) ~= 0 then
      self.machineBias = band(self.machineBias, bnot(BIAS_7))
      if band(m, jackpot) ~= 0 then
        self.reelTimeSpinsLeft = 0
        self.reelTimeSpinsUsed = 0
        self.luckyGame = band(m, lshift(1, MATCH.BLUE_7)) ~= 0
      end
    end
    if band(m, lshift(1, MATCH.POWER)) ~= 0 and self.pikaPowerBolts < 16 then
      self.pikaPowerBolts = self.pikaPowerBolts + 1
      out.addBolt = self.pikaPowerBolts
    end
  else
    self.netCoinLoss = s16(self.netCoinLoss + self.bet)
    if self.netCoinLoss > Slots.MAX_COINS then self.netCoinLoss = Slots.MAX_COINS end
  end
  return out
end

function Slots:hasMatch(match)
  return band(self.matches, lshift(1, match)) ~= 0
end

return Slots
