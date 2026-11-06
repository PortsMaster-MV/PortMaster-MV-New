local bit = require("bit")
local band, bor, rshift = bit.band, bit.bor, bit.rshift

local ok, ffi = pcall(require, "ffi")
local fbuf = ok and ffi.new("float[1]") or nil

local Roulette = {}

Roulette.SUB = "rse_roulette"
Roulette.MANIFEST = "data/generated/gba/rse_roulette/manifest.lua"

-- pokeemerald/src/roulette.c:35
Roulette.BALLS_PER_ROUND = 6
Roulette.NUM_BOARD_COLORS = 3
Roulette.NUM_BOARD_POKES = 4
Roulette.NUM_ROULETTE_SLOTS = 12
Roulette.DEGREES_PER_SLOT = 30
Roulette.SLOT_MIDPOINT = 14
Roulette.MAX_MULTIPLIER = 12
Roulette.MAX_COINS = 9999

-- pokeemerald/src/roulette.c:49
Roulette.SELECTION_NONE = 0
Roulette.COL_WYNAUT, Roulette.COL_AZURILL, Roulette.COL_SKITTY, Roulette.COL_MAKUHITA = 1, 2, 3, 4
Roulette.ROW_ORANGE, Roulette.ROW_GREEN, Roulette.ROW_PURPLE = 5, 10, 15
Roulette.NUM_GRID_SELECTIONS = 19

-- pokeemerald/src/roulette.c:156
Roulette.HAS_SHROOMISH = 1
Roulette.HAS_TAILLOW = 2

-- pokeemerald/include/constants/roulette.h:5
Roulette.ROULETTE_SPECIAL_RATE = 0x80

function Roulette.f32(x)
  if not fbuf then return x end
  fbuf[0] = x
  return fbuf[0]
end
local F = Roulette.f32

function Roulette.trunc(x)
  if x >= 0 then return math.floor(x) end
  return math.ceil(x)
end

function Roulette.s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

-- pokeemerald/include/global.h:133
function Roulette.s16ToPosFloat(v)
  v = Roulette.s16(v)
  local f = F(v)
  if v < 0 then f = F(f + 65536) end
  return f
end

function Roulette.loadTables(cache)
  local body
  if cache and cache.read then
    body = cache:read(Roulette.MANIFEST)
  else
    local okD, Dataset = pcall(require, "src.core.game3.dataset")
    if okD and Dataset and Dataset.cache then body = Dataset.cache():read(Roulette.MANIFEST) end
  end
  assert(type(body) == "string", "roulette: missing " .. Roulette.MANIFEST)
  return assert(load(body, "@" .. Roulette.MANIFEST, "t", {}))()
end

-- pokeemerald/src/roulette.c:152
function Roulette.minBetId(var)
  return band(var, 1) + rshift(band(var, 0xFFFF), 7) * 2
end

function Roulette.getCol(sel) return sel % 5 end
function Roulette.getRow(sel) return math.floor(sel / 5) * 5 end
function Roulette.getRowIdx(sel) return math.floor(sel / 5) - 1 end

-- pokeemerald/src/roulette.c:1557
function Roulette.randomForBallTravelDistance(T, tableId, partyFlags, hours, ballNum, rand)
  local tbl = T.rouletteTables[tableId]
  local low, high = tbl.randDistanceLow, tbl.randDistanceHigh
  local BPR = Roulette.BALLS_PER_ROUND
  if partyFlags == Roulette.HAS_SHROOMISH or partyFlags == Roulette.HAS_TAILLOW then
    if hours > 3 and hours < 10 then
      if ballNum < BPR * 2 or band(rand, 1) ~= 0 then return math.floor(low / 2) end
      return 1
    elseif band(rand, 3) == 0 then
      return math.floor(low / 2)
    end
    return low
  elseif partyFlags == Roulette.HAS_SHROOMISH + Roulette.HAS_TAILLOW then
    if hours > 3 and hours < 11 then
      if ballNum < BPR or band(rand, 1) ~= 0 then return math.floor(low / 2) end
      return 1
    elseif band(rand, 1) ~= 0 and ballNum > BPR then
      return math.floor(low / 4)
    end
    return math.floor(low / 2)
  end
  if hours > 3 and hours < 10 then
    if band(rand, 3) == 0 then return 1 end
    return math.floor(low / 2)
  elseif band(rand, 3) == 0 then
    if ballNum > BPR * 2 then return math.floor(low / 2) end
    return low
  elseif band(rand, 0x8000) ~= 0 then
    if ballNum > BPR * 2 then return low end
    return high
  end
  return band(high * 2, 0xFF)
end

-- pokeemerald/src/roulette.c:1630
function Roulette.initBallRoll(T, st, ballNum, totalBallNum, hours, rand)
  local tbl = T.rouletteTables[st.tableId]
  local startAngles = { [0] = 0, 180, 90, 270 }
  local randmod = rand % 100
  st.curBallSpriteId = ballNum
  st.ballState, st.hitSlot, st.stuckHitSlot = 0, 0, 0
  local mod = Roulette.randomForBallTravelDistance(T, st.tableId, st.partySpeciesFlags, hours, totalBallNum, rand)
  local randTravelDist = (rand % mod) - math.floor(mod / 2)
  randTravelDist = band(randTravelDist, 0xFF)
  if randTravelDist >= 0x80 then randTravelDist = randTravelDist - 0x100 end
  local startAngleId = hours < 13 and 0 or 1
  if randmod < 80 then startAngleId = startAngleId * 2 else startAngleId = (1 - startAngleId) * 2 end
  local travelDist = band(tbl.baseTravelDist + randTravelDist, 0xFFFF)
  st.ballTravelDist = Roulette.s16(travelDist)
  travelDist = band(Roulette.trunc(F(Roulette.s16ToPosFloat(travelDist) / F(5.0))), 0xFFFF)
  st.ballTravelDistFast = Roulette.s16(travelDist * 3)
  st.ballTravelDistSlow = travelDist
  st.ballTravelDistMed = travelDist
  st.ballAngle = Roulette.s16ToPosFloat(startAngles[band(rand, 1) + startAngleId])
  st.ballAngleSpeed = Roulette.s16ToPosFloat(tbl.ballSpeed)
  st.ballAngleAccel = F(F(F(st.ballAngleSpeed * 0.5) - st.ballAngleSpeed) / Roulette.s16ToPosFloat(st.ballTravelDistFast))
  st.ballDistToCenter = F(68.0)
  st.ballFallAccel = F(0)
  st.ballFallSpeed = F(-F(F(8.0) / Roulette.s16ToPosFloat(st.ballTravelDistFast)))
  st.varA0 = F(36.0)
end

-- pokeemerald/src/roulette.c:2059
function Roulette.recordHit(T, st, ballNum, slotId)
  local colFlags, rowFlags = {}, {}
  local grid = T.grid
  for i = 0, 3 do
    local col = i + 1
    colFlags[i] = bor(grid[col].flag, grid[col + 5].flag, grid[col + 10].flag, grid[col + 15].flag)
  end
  for j = 0, 2 do
    local row = (j + 1) * 5
    rowFlags[j] = bor(grid[row].flag, grid[row + 1].flag, grid[row + 2].flag, grid[row + 3].flag, grid[row + 4].flag)
  end
  if slotId >= Roulette.NUM_ROULETTE_SLOTS then return 0 end
  local slot = T.slots[slotId]
  st.hitSquares[ballNum - 1] = slot.gridSquare
  st.winningSquare = slot.gridSquare
  st.hitFlags = bor(st.hitFlags, slot.flag)
  for i = 0, 3 do
    if band(slot.flag, colFlags[i]) ~= 0 then st.pokeHits[i] = st.pokeHits[i] + 1 end
    if st.pokeHits[i] >= 3 then st.hitFlags = bor(st.hitFlags, colFlags[i]) end
  end
  for j = 0, 2 do
    if band(slot.flag, rowFlags[j]) ~= 0 then st.colorHits[j] = st.colorHits[j] + 1 end
    if st.colorHits[j] >= 4 then st.hitFlags = bor(st.hitFlags, rowFlags[j]) end
  end
  return slot.gridSquare
end

-- pokeemerald/src/roulette.c:2099
function Roulette.isHitInBetSelection(gridSquare, betSelection)
  local hit = gridSquare
  if band(gridSquare - 1, 0xFF) < Roulette.NUM_GRID_SELECTIONS then
    if betSelection == 0 then return 3 end
    if betSelection >= 1 and betSelection <= 4 then
      if hit == betSelection + 5 or hit == betSelection + 10 or hit == betSelection + 15 then return 1 end
    elseif betSelection == 5 or betSelection == 10 or betSelection == 15 then
      if hit >= betSelection + 1 and hit <= betSelection + 4 then return 1 end
    elseif hit == betSelection then
      return 1
    end
  end
  return 0
end

-- pokeemerald/src/roulette.c:2277
function Roulette.getMultiplier(T, st, sel)
  local mult = { [0] = 0, 3, 4, 6, Roulette.MAX_MULTIPLIER }
  if sel > Roulette.NUM_GRID_SELECTIONS then sel = 0 end
  local base = T.grid[sel].baseMultiplier
  if base == Roulette.NUM_BOARD_COLORS then
    local r = Roulette.getRowIdx(sel)
    if st.colorHits[r] >= 4 then return 0 end
    return mult[st.colorHits[r] + 1]
  elseif base == Roulette.NUM_BOARD_POKES then
    local c = sel - 1
    if st.pokeHits[c] >= 3 then return 0 end
    return mult[st.pokeHits[c] + 2]
  elseif base == Roulette.NUM_ROULETTE_SLOTS then
    if band(st.hitFlags, T.grid[sel].flag) ~= 0 then return 0 end
    return mult[4]
  end
  return 0
end

-- pokeemerald/src/roulette.c:3758
function Roulette.multiplierAnimId(T, st, sel)
  if sel > Roulette.NUM_GRID_SELECTIONS then sel = 0 end
  local base = T.grid[sel].baseMultiplier
  if base == Roulette.NUM_BOARD_COLORS then
    local r = Roulette.getRowIdx(sel)
    if st.colorHits[r] > 3 then return 0 end
    return st.colorHits[r] + 1
  elseif base == Roulette.NUM_BOARD_POKES then
    local c = sel - 1
    if st.pokeHits[c] > 2 then return 0 end
    return st.pokeHits[c] + 2
  elseif base == Roulette.NUM_ROULETTE_SLOTS then
    if band(st.hitFlags, T.grid[sel].flag) ~= 0 then return 0 end
    return 4
  end
  return 0
end

-- pokeemerald/src/roulette.c:1394
function Roulette.canMoveSelectionInDir(sel, dir)
  local offsets = { [0] = -5, 5, -1, 1 }
  local temp1, temp
  local orig = sel
  if dir == 0 or dir == 1 then
    temp1 = sel % 5
    temp = temp1 + 15
    if temp1 == 0 then temp1 = 5 end
  else
    temp1 = math.floor(sel / 5) * 5
    temp = temp1 + 4
    if temp1 == 0 then temp1 = 1 end
  end
  sel = sel + offsets[dir]
  if sel < temp1 then sel = temp end
  if sel > temp then sel = temp1 end
  return sel ~= orig, sel
end

-- pokeemerald/src/roulette.c:1362
function Roulette.firstEmptySquare(T, st)
  local i
  if band(st.hitFlags, T.grid[Roulette.ROW_ORANGE].flag) ~= 0 then
    i = 11
    while i < 14 do
      if band(st.hitFlags, T.grid[i].flag) == 0 then break end
      i = i + 1
    end
  else
    i = 6
    while i <= 9 do
      if band(st.hitFlags, T.grid[i].flag) == 0 then break end
      i = i + 1
    end
  end
  return i
end

function Roulette.newState(T, var8004, partyFlags)
  local st = {
    tableId = band(var8004, 1),
    isSpecialRate = band(var8004, Roulette.ROULETTE_SPECIAL_RATE) ~= 0,
    partySpeciesFlags = partyFlags or 0,
    hitFlags = 0, hitSquares = {}, pokeHits = {}, colorHits = {}, betSelection = {},
    curBallNum = 0, wheelDelayTimer = 0, wheelAngle = 0, gridX = 0,
    ballStuck = false, ballUnstuck = false, ballRolling = false, useTaillow = false,
    ballState = 0, hitSlot = 0, stuckHitSlot = 0,
  }
  local tbl = T.rouletteTables[st.tableId]
  st.wheelSpeed = tbl.wheelSpeed
  st.wheelDelay = tbl.wheelDelay
  st.minBet = T.minBets[st.tableId + (st.isSpecialRate and 2 or 0)]
  for i = 0, 5 do st.hitSquares[i], st.betSelection[i] = 0, 0 end
  for i = 0, 3 do st.pokeHits[i] = 0 end
  for i = 0, 2 do st.colorHits[i] = 0 end
  return st
end

function Roulette.resetHits(st)
  st.hitFlags = 0
  for i = 0, 5 do st.hitSquares[i] = 0 end
  for i = 0, 3 do st.pokeHits[i] = 0 end
  for i = 0, 2 do st.colorHits[i] = 0 end
end

-- pokeemerald/src/roulette.c:1115
function Roulette.partyFlags(party, speciesOf, constants)
  local C = constants or require("src.core.game3.constants").of("emerald")
  local shroomish = C:require("species", "SPECIES_SHROOMISH")
  local taillow = C:require("species", "SPECIES_TAILLOW")
  local flags = 0
  for _, mon in ipairs(party or {}) do
    local sp = speciesOf and speciesOf(mon) or (mon.isEgg and 0x19C or tonumber(mon.species or mon.speciesId) or 0)
    if sp == shroomish then flags = bor(flags, Roulette.HAS_SHROOMISH) end
    if sp == taillow then flags = bor(flags, Roulette.HAS_TAILLOW) end
  end
  return flags
end

return Roulette
