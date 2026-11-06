local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")
local Data = require("src.core.game3.rse.frontier.f2_data")

local bit = rawget(_G, "bit") or require("bit")

local Dome = {}

-- pokeemerald/include/constants/battle_dome.h:21
Dome.FUNC = {
  INIT = 0, GET_DATA = 1, SET_DATA = 2, GET_ROUND_TEXT = 3, GET_OPPONENT_NAME = 4, INIT_OPPONENT_PARTY = 5,
  SHOW_OPPONENT_INFO = 6, SHOW_TOURNEY_TREE = 7, SHOW_PREV_TOURNEY_TREE = 8, SET_OPPONENT_ID = 9,
  SET_OPPONENT_GFX = 10, SHOW_STATIC_TOURNEY_TREE = 11, RESOLVE_WINNERS = 12, SAVE = 13, INCREMENT_STREAK = 14,
  SET_TRAINERS = 15, RESET_SKETCH = 16, RESTORE_HELD_ITEMS = 17, REDUCE_PARTY = 18, COMPARE_SEEDS = 19,
  GET_WINNER_NAME = 20, INIT_RESULTS_TREE = 21, INIT_TRAINERS = 22,
}
-- pokeemerald/include/constants/battle_dome.h:45
Dome.DATA = {
  WIN_STREAK = 0, WIN_STREAK_ACTIVE = 1, ATTEMPTED_SINGLES_50 = 2, ATTEMPTED_SINGLES_OPEN = 3,
  HAS_WON_SINGLES_50 = 4, HAS_WON_SINGLES_OPEN = 5, ATTEMPTED_CHALLENGE = 6, HAS_WON_CHALLENGE = 7,
  SELECTED_MONS = 8, PREV_TOURNEY_TYPE = 9,
}
-- pokeemerald/include/constants/battle_dome.h:4
Dome.ROUND1, Dome.ROUND2, Dome.SEMIFINAL, Dome.FINAL, Dome.ROUNDS_COUNT = 0, 1, 2, 3, 4
Dome.TRAINERS_COUNT = 16
Dome.MATCHES_COUNT = 15
Dome.BATTLE_PARTY_SIZE = 2
-- pokeemerald/include/constants/battle_dome.h:17
Dome.PLAYER_WON_MATCH, Dome.PLAYER_LOST_MATCH, Dome.PLAYER_RETIRED = 1, 2, 9
-- pokeemerald/include/constants/battle_dome.h:108
Dome.TEXT = { NO_WINNER_YET = 0, WON_USING_MOVE = 1, CHAMP_USING_MOVE = 2, WON_ON_FORFEIT = 3, CHAMP_ON_FORFEIT = 4,
  WON_NO_MOVES = 5, CHAMP_NO_MOVES = 6 }
Dome.STATS_TEXT = { TWO_GOOD = 0, ONE_GOOD = 15, TWO_BAD = 21, ONE_BAD = 36, WELL_BALANCED = 42 }
-- pokeemerald/src/battle_dome.c:78
Dome.EFFECTIVENESS = { GOOD = 0, BAD = 1, AI_VS_AI = 2 }
-- pokeemerald/src/battle_dome.c:84
Dome.WIN = { NAMES_LEFT = 0, NAMES_RIGHT = 1, TITLE = 2 }
-- pokeemerald/include/constants/battle_dome.h:156
Dome.NUM_MOVE_POINT_TYPES = 16
-- pokeemerald/include/constants/pokemon.h:212
local NUM_STATS = 6
local NUM_NATURE_STATS = 5
-- pokeemerald/include/constants/moves.h:9
local MOVE_NONE, MOVE_UNAVAILABLE, MOVE_STRUGGLE = 0, 0xFFFF, 165
local MOVE_SELF_DESTRUCT, MOVE_EXPLOSION = 120, 153
-- pokeemerald/include/constants/battle.h:220
local R = { MISSED = 1, SUPER = 2, NOT_VERY = 4, DOESNT_AFFECT = 8, FAILED = 32 }
R.NO_EFFECT = R.MISSED + R.DOESNT_AFFECT + R.FAILED
-- pokeemerald/include/constants/pokemon.h:55
local TYPE_GROUND = 4
local TYPE_FORESIGHT = 0xFE
local TYPE_MUL_NO_EFFECT, TYPE_MUL_NOT_EFFECTIVE, TYPE_MUL_SUPER_EFFECTIVE = 0, 5, 20
-- pokeemerald/src/battle_dome.c:2794
local TYPE_x0, TYPE_x0_25, TYPE_x0_50, TYPE_x1, TYPE_x2, TYPE_x4 = 0, 5, 10, 20, 40, 80

local F = D.FACILITY

local function rng() return D.rng() end
local function Random() return rng().Random() end

local function C(sess) return D.constants(sess) end

local function abilityId(sess, name)
  return C(sess):require("abilities", name)
end

local function speciesInfo(species)
  local Pokemon = require("src.core.game3.pokemon")
  local s = Pokemon.stats(species) or {}
  local base = { tonumber(s.hp) or 0, tonumber(s.atk) or 0, tonumber(s.def) or 0, tonumber(s.spe) or 0,
    tonumber(s.spa) or 0, tonumber(s.spd) or 0 }
  return base, Pokemon.types(species), Pokemon.abilities(species)
end

local function move(mv)
  mv = tonumber(mv) or 0
  if mv == 0 or mv == 0xFFFF then return { power = 0, type = 0 } end
  local Moves = require("src.core.game3.battle.moves")
  return Moves.get(mv) or {}
end

function Dome.frontier(sess)
  local f = Util.frontier(sess)
  if type(f.domeTrainers) ~= "table" then
    f.domeTrainers = {}
    for i = 1, Dome.TRAINERS_COUNT do
      f.domeTrainers[i] = { trainerId = 0, isEliminated = false, eliminatedAt = 0, forfeited = false }
    end
  end
  if type(f.domeMonIds) ~= "table" then
    f.domeMonIds = {}
    for i = 1, Dome.TRAINERS_COUNT do f.domeMonIds[i] = { 0, 0, 0 } end
  end
  if type(f.domeWinningMoves) ~= "table" then
    f.domeWinningMoves = {}
    for i = 1, Dome.TRAINERS_COUNT do f.domeWinningMoves[i] = 0 end
  end
  if type(f.domePlayerPartyData) ~= "table" then
    f.domePlayerPartyData = {}
    for i = 1, D.PARTY_SIZE do f.domePlayerPartyData[i] = { moves = { 0, 0, 0, 0 }, evs = { 0, 0, 0, 0, 0, 0 }, nature = 0 } end
  end
  f.domeLvlMode = tonumber(f.domeLvlMode) or 0
  f.domeBattleMode = tonumber(f.domeBattleMode) or 0
  return f
end

local function T(sess, tid) return Dome.frontier(sess).domeTrainers[tid + 1] end
local function MONS(sess, tid) return Dome.frontier(sess).domeMonIds[tid + 1] end
Dome.trainer = T
Dome.mons = MONS

local function modeLvl(sess)
  local f = Util.frontier(sess)
  return Rse.var("VAR_FRONTIER_BATTLE_MODE", sess), tonumber(f.lvlMode) or 0
end

-- pokeemerald/src/battle_dome.c:1164
local function streakFlag(mode, lvl)
  local S = Util.STREAK
  local rows = { { S.DOME_SINGLES_50, S.DOME_SINGLES_OPEN }, { S.DOME_DOUBLES_50, S.DOME_DOUBLES_OPEN } }
  local row = rows[mode + 1] or rows[1]
  return row[lvl + 1] or 0
end

local function u32(v)
  if v < 0 then v = v + 4294967296 end
  return v
end

local function monSet(sess)
  return D.facilityPtrs(sess, F.DOME)
end

local function facilityMon(sess, monId)
  return monSet(sess).mons[monId]
end
Dome.facilityMon = facilityMon

-- pokeemerald/src/battle_dome.c:2147
function Dome.init(sess)
  local f = Dome.frontier(sess)
  local mode, lvl = modeLvl(sess)
  f.challengeStatus = 0
  f.curChallengeBattleNum = 0
  f.challengePaused = 0
  f.disableRecordBattle = 0
  if bit.band(tonumber(f.winStreakActiveFlags) or 0, streakFlag(mode, lvl)) == 0 then
    Util.set2(f.domeWinStreaks, mode, lvl, 0)
  end
  sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = sess.x, y = sess.y }
  sess.frontierOpponentA = 0
end

local function attemptedField(mode, lvl, won)
  local kind = won and "HasWon" or "Attempted"
  return "dome" .. kind .. (mode == D.MODE.DOUBLES and "Doubles" or "Singles") .. (lvl ~= D.LVL.L50 and "Open" or "50")
end

-- pokeemerald/src/battle_dome.c:2163
function Dome.getData(ctx, sess)
  local f = Dome.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local which = Rse.specialVar(ctx, Util.VAR_0x8005)
  local Dd = Dome.DATA
  local function b(v) return (v == true or v == 1) and 1 or 0 end
  if which == Dd.WIN_STREAK then
    Util.setResult(ctx, Util.get2(f.domeWinStreaks, mode, lvl))
  elseif which == Dd.WIN_STREAK_ACTIVE then
    Util.setResult(ctx, bit.band(tonumber(f.winStreakActiveFlags) or 0, streakFlag(mode, lvl)) ~= 0 and 1 or 0)
  elseif which == Dd.ATTEMPTED_SINGLES_50 then Util.setResult(ctx, b(f.domeAttemptedSingles50))
  elseif which == Dd.ATTEMPTED_SINGLES_OPEN then Util.setResult(ctx, b(f.domeAttemptedSinglesOpen))
  elseif which == Dd.HAS_WON_SINGLES_50 then Util.setResult(ctx, b(f.domeHasWonSingles50))
  elseif which == Dd.HAS_WON_SINGLES_OPEN then Util.setResult(ctx, b(f.domeHasWonSinglesOpen))
  elseif which == Dd.ATTEMPTED_CHALLENGE then Util.setResult(ctx, b(f[attemptedField(mode, lvl, false)]))
  elseif which == Dd.HAS_WON_CHALLENGE then Util.setResult(ctx, b(f[attemptedField(mode, lvl, true)]))
  elseif which == Dd.SELECTED_MONS then
    local v = tonumber(f.selectedPartyMons[4]) or 0
    sess.selectedOrderFromParty = { v % 256, math.floor(v / 256) % 256, 0, 0 }
  elseif which == Dd.PREV_TOURNEY_TYPE then
    Util.setResult(ctx, (f.domeLvlMode * 2) - 3 + f.domeBattleMode)
  end
end

-- pokeemerald/src/battle_dome.c:2231
function Dome.setData(ctx, sess)
  local f = Dome.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local which = Rse.specialVar(ctx, Util.VAR_0x8005)
  local v = Rse.specialVar(ctx, Util.VAR_0x8006)
  local Dd = Dome.DATA
  if which == Dd.WIN_STREAK then
    Util.set2(f.domeWinStreaks, mode, lvl, v)
  elseif which == Dd.WIN_STREAK_ACTIVE then
    local flags = tonumber(f.winStreakActiveFlags) or 0
    if v ~= 0 then
      f.winStreakActiveFlags = u32(bit.bor(flags, streakFlag(mode, lvl)))
    else
      f.winStreakActiveFlags = u32(bit.band(flags, bit.bnot(streakFlag(mode, lvl))))
    end
  elseif which == Dd.ATTEMPTED_SINGLES_50 then f.domeAttemptedSingles50 = v % 2
  elseif which == Dd.ATTEMPTED_SINGLES_OPEN then f.domeAttemptedSinglesOpen = v % 2
  elseif which == Dd.HAS_WON_SINGLES_50 then f.domeHasWonSingles50 = v % 2
  elseif which == Dd.HAS_WON_SINGLES_OPEN then f.domeHasWonSinglesOpen = v % 2
  elseif which == Dd.ATTEMPTED_CHALLENGE then f[attemptedField(mode, lvl, false)] = v % 2
  elseif which == Dd.HAS_WON_CHALLENGE then f[attemptedField(mode, lvl, true)] = v % 2
  elseif which == Dd.SELECTED_MONS then
    local o = sess.selectedOrderFromParty or {}
    f.selectedPartyMons[4] = (tonumber(o[1]) or 0) + (tonumber(o[2]) or 0) * 256
  end
end

-- pokeemerald/src/pokemon.c:5693
local function modifyStatByNature(nature, stat, statIndex)
  if statIndex < 1 or statIndex > 5 then return stat end
  local d = Data.dome().natureStatTable[nature + 1][statIndex]
  if d == 1 then return math.floor(stat * 110 / 100) end
  if d == -1 then return math.floor(stat * 90 / 100) end
  return stat
end

-- pokeemerald/src/battle_dome.c:2513
function Dome.calcMonStats(species, level, ivs, evBits, nature)
  local base = speciesInfo(species)
  local count, bits = 0, evBits
  for _ = 0, NUM_STATS - 1 do
    if bit.band(bits, 1) ~= 0 then count = count + 1 end
    bits = bit.rshift(bits, 1)
  end
  local resulting = math.floor(D.MAX_TOTAL_EVS / math.max(1, count))
  local evs = {}
  -- pokeemerald/src/battle_dome.c:2531
  for i = 0, NUM_STATS - 1 do evs[i] = bit.band(evBits, bits) ~= 0 and resulting or 0 end
  local stats = {}
  -- pokeemerald/include/constants/species.h:303
  if species == C():require("species", "SPECIES_SHEDINJA") then
    stats[0] = 1
  else
    stats[0] = math.floor(((2 * base[1] + ivs + math.floor(evs[0] / 4)) * level) / 100) + level + 10
  end
  for statIndex = 1, 5 do
    local b = base[statIndex + 1]
    local v = math.floor(((2 * b + ivs + math.floor(evs[statIndex] / 4)) * level) / 100) + 5
    stats[statIndex] = modifyStatByNature(nature, v, statIndex) % 256
  end
  return stats
end

local function typeBits(species)
  local _, types = speciesInfo(species)
  return bit.bor(bit.lshift(1, types[1] or 0), bit.lshift(1, types[2] or 0))
end

local function popcount(v)
  local n = 0
  for _ = 0, 31 do
    if bit.band(v, 1) ~= 0 then n = n + 1 end
    v = bit.rshift(v, 1)
  end
  return n
end

local function swap(sess, scores, a, b)
  local f = Dome.frontier(sess)
  scores[a], scores[b] = scores[b], scores[a]
  f.domeTrainers[a + 1].trainerId, f.domeTrainers[b + 1].trainerId = f.domeTrainers[b + 1].trainerId, f.domeTrainers[a + 1].trainerId
  f.domeMonIds[a + 1], f.domeMonIds[b + 1] = f.domeMonIds[b + 1], f.domeMonIds[a + 1]
end

local function randomScaledTrainerId(challengeNum, battleNum)
  return require("src.core.game3.rse.frontier.tower").randomScaledTrainerId(challengeNum, battleNum)
end

local function randomMonFromSet(sess, trainerId)
  local set, level = monSet(sess)
  local ms = set.trainers[trainerId].monSet
  local monId
  repeat
    monId = ms[(Random() % #ms) + 1]
  until not ((level == D.FRONTIER_MAX_LEVEL_50 or level == 20) and monId > D.FRONTIER_MONS_HIGH_TIER)
  return monId
end

local function pickParty(sess, i, trainerId, species)
  local set = monSet(sess)
  local mons = MONS(sess, i)
  for j = 0, D.PARTY_SIZE - 1 do
    local monId
    while true do
      monId = randomMonFromSet(sess, trainerId)
      local k = 0
      while k < j do
        local already = mons[k + 1]
        if already == monId or species[1] == set.mons[monId].species or species[2] == set.mons[monId].species
            or set.mons[already].itemTableId == set.mons[monId].itemTableId then
          break
        end
        k = k + 1
      end
      if k == j then break end
    end
    mons[j + 1] = monId
    species[j + 1] = set.mons[monId].species
  end
end

local function monStat(mon, key)
  local Pokemon = require("src.core.game3.pokemon")
  if not mon.maxHp then Pokemon.applyStats(mon) end
  local map = { atk = mon.atk or mon.attack, def = mon.def or mon.defense, spa = mon.spa or mon.spAtk,
    spd = mon.spd or mon.spDef, spe = mon.spe or mon.speed, hp = mon.maxHp }
  return tonumber(map[key]) or 0
end

-- pokeemerald/src/battle_dome.c:2297
function Dome.initTrainers(sess)
  local f = Dome.frontier(sess)
  local species = { 0, 0, 0 }
  local scores = {}
  local mode = Rse.var("VAR_FRONTIER_BATTLE_MODE", sess)
  f.domeLvlMode = (tonumber(f.lvlMode) or 0) + 1
  f.domeBattleMode = mode + 1
  local t0 = f.domeTrainers[1]
  t0.trainerId, t0.isEliminated, t0.eliminatedAt, t0.forfeited = D.TRAINER_PLAYER, false, 0, false
  for i = 1, D.PARTY_SIZE do
    local mon = sess.party[(tonumber(f.selectedPartyMons[i]) or 1)] or {}
    f.domeMonIds[1][i] = tonumber(mon.species) or 0
    local pd = f.domePlayerPartyData[i]
    for j = 1, 4 do pd.moves[j] = tonumber(mon.moves and mon.moves[j]) or 0 end
    local evs = mon.evs or {}
    pd.evs = { evs.hp or 0, evs.atk or 0, evs.def or 0, evs.spe or 0, evs.spa or 0, evs.spd or 0 }
    pd.nature = (tonumber(mon.personality) or 0) % 25
  end
  local ws = Util.currentFacilityWinStreak(sess)
  for i = 1, Dome.TRAINERS_COUNT - 1 do
    local trainerId
    local streak = (i > 5) and ws or (ws + 1)
    while true do
      trainerId = randomScaledTrainerId(streak, 0)
      local j = 1
      while j < i do
        if f.domeTrainers[j + 1].trainerId == trainerId then break end
        j = j + 1
      end
      if j == i then break end
    end
    f.domeTrainers[i + 1].trainerId = trainerId
    pickParty(sess, i, trainerId, species)
    local t = f.domeTrainers[i + 1]
    t.isEliminated, t.eliminatedAt, t.forfeited = false, 0, false
  end
  local bits = 0
  scores[0] = 0
  for i = 1, D.PARTY_SIZE do
    local mon = sess.party[(tonumber(f.selectedPartyMons[i]) or 1)] or {}
    for _, k in ipairs({ "atk", "def", "spa", "spd", "spe", "hp" }) do scores[0] = scores[0] + monStat(mon, k) end
    bits = bit.bor(bits, typeBits(tonumber(mon.species) or 0))
  end
  local _, level = monSet(sess)
  scores[0] = (scores[0] + math.floor(popcount(bits) * level / 20)) % 65536
  for i = 1, Dome.TRAINERS_COUNT - 1 do
    bits = 0
    local s = 0
    local ivs = D.fixedIvs(f.domeTrainers[i + 1].trainerId)
    for j = 1, D.PARTY_SIZE do
      local row = facilityMon(sess, f.domeMonIds[i + 1][j])
      local st = Dome.calcMonStats(row.species, level, ivs, row.evSpread, row.nature)
      s = s + st[1] + st[2] + st[5] + st[4] + st[3] + st[0]
      bits = bit.bor(bits, typeBits(row.species))
    end
    scores[i] = (s + math.floor(popcount(bits) * level / 20)) % 65536
  end
  for i = 0, Dome.TRAINERS_COUNT - 2 do
    for j = i + 1, Dome.TRAINERS_COUNT - 1 do
      if scores[i] < scores[j] then
        swap(sess, scores, i, j)
      elseif scores[i] == scores[j] then
        if f.domeTrainers[j + 1].trainerId == D.TRAINER_PLAYER then
          swap(sess, scores, i, j)
        elseif f.domeTrainers[i + 1].trainerId > f.domeTrainers[j + 1].trainerId then
          swap(sess, scores, i, j)
        end
      end
    end
  end
  if Util.brainStatus(sess) ~= Util.BRAIN.NOT_READY then
    local pos = Dome.tournamentId(sess, D.TRAINER_PLAYER)
    local j = (Data.dome().namePositions[pos + 1][1] ~= Dome.WIN.NAMES_LEFT) and 0 or 1
    f.domeTrainers[j + 1].trainerId = D.TRAINER_FRONTIER_BRAIN
    for i = 1, D.PARTY_SIZE do f.domeMonIds[j + 1][i] = Dome.brainMon(sess, i - 1).species end
  end
  return scores
end

-- pokeemerald/src/frontier_util.c:2548
function Dome.brainMon(sess, i)
  local symbol = D.brainSymbol(sess, F.DOME)
  return D.pack("brains").mons[F.DOME][symbol + 1][i + 1]
end

function Dome.brainTrainer()
  local tid = D.pack("brains").trainerIds[F.DOME + 1]
  return require("src.core.game3.scripting.trainers").get(tid) or {}
end

-- pokeemerald/src/battle_dome.c:5982
function Dome.tournamentId(sess, trainerId)
  local f = Dome.frontier(sess)
  for i = 0, Dome.TRAINERS_COUNT - 1 do
    if f.domeTrainers[i + 1].trainerId == trainerId then return i end
  end
  return Dome.TRAINERS_COUNT
end

-- pokeemerald/src/battle_dome.c:2964
function Dome.opponentTournamentId(sess, roundId, trainerId)
  local f = Dome.frontier(sess)
  local M = Data.dome()
  local i = Dome.tournamentId(sess, trainerId)
  if roundId ~= Dome.ROUND1 then
    local base = M.idToOpponentId[i + 1][roundId + 1]
    local max = base + ((roundId == Dome.FINAL) and 8 or 4)
    local j = base
    while j < max do
      local o = M.trainerOpponentIds[j + 1]
      if o ~= i and not f.domeTrainers[o + 1].isEliminated then break end
      j = j + 1
    end
    if j ~= max then return M.trainerOpponentIds[j + 1] end
    return 0xFF
  end
  local o = M.idToOpponentId[i + 1][roundId + 1]
  if not f.domeTrainers[o + 1].isEliminated then return o end
  return 0xFF
end

-- pokeemerald/src/battle_dome.c:3010
function Dome.playerOpponentTrainerId(sess)
  local f = Dome.frontier(sess)
  local o = Dome.opponentTournamentId(sess, tonumber(f.curChallengeBattleNum) or 0, D.TRAINER_PLAYER)
  local t = f.domeTrainers[o + 1]
  return t and t.trainerId or 0
end

-- pokeemerald/src/battle_dome.c:2801
function Dome.typeEffectivenessPoints(mv, targetSpecies, mode, sess)
  local m = move(mv)
  if mv == MOVE_NONE or mv == MOVE_UNAVAILABLE or (tonumber(m.power) or 0) == 0 then return 0 end
  local _, types, abilities = speciesInfo(targetSpecies)
  local def1, def2, defAbility = types[1] or 0, types[2] or 0, abilities[1] or 0
  local moveType = tonumber(m.type) or 0
  local typePower = TYPE_x1
  if defAbility == abilityId(sess, "ABILITY_LEVITATE") and moveType == TYPE_GROUND then
    if mode == Dome.EFFECTIVENESS.BAD then typePower = 8 end
  else
    local wonder = defAbility == abilityId(sess, "ABILITY_WONDER_GUARD")
    for _, e in ipairs(Data.dome().typeEffectiveness) do
      local atk, def, mul = e[1], e[2], e[3]
      if atk ~= TYPE_FORESIGHT and atk == moveType then
        -- pokeemerald/src/battle_dome.c:2847
        if def == def1 and ((wonder and mul == TYPE_x2) or not wonder) then
          typePower = math.floor(typePower * mul / 10)
        end
        if def == def2 and def1 ~= def2 and ((wonder and mul == TYPE_x2) or not wonder) then
          typePower = math.floor(typePower * mul / 10)
        end
      end
    end
  end
  if mode == Dome.EFFECTIVENESS.GOOD then
    if typePower == TYPE_x1 then return 2 end
    if typePower == TYPE_x2 then return 4 end
    if typePower == TYPE_x4 then return 8 end
    return 0
  elseif mode == Dome.EFFECTIVENESS.BAD then
    if typePower == TYPE_x0 then return 8 end
    if typePower == TYPE_x0_25 then return 4 end
    if typePower == TYPE_x0_50 then return 2 end
    if typePower == TYPE_x2 then return -2 end
    if typePower == TYPE_x4 then return -4 end
    return 0
  end
  if typePower == TYPE_x0 then return -16 end
  if typePower == TYPE_x0_25 then return -8 end
  if typePower == TYPE_x1 then return 4 end
  if typePower == TYPE_x2 then return 12 end
  if typePower == TYPE_x4 then return 20 end
  return 0
end

local function monMove(sess, tid, i, j)
  local f = Dome.frontier(sess)
  if f.domeTrainers[tid + 1].trainerId == D.TRAINER_FRONTIER_BRAIN then
    return tonumber(Dome.brainMon(sess, i).moves[j + 1]) or 0
  end
  return tonumber(facilityMon(sess, f.domeMonIds[tid + 1][i + 1]).moves[j + 1]) or 0
end

-- pokeemerald/src/battle_dome.c:2736
local function selectFromParty(points, allowRandom)
  local bits = 0
  local pos = { [0] = 0, 1, 2 }
  local p = { [0] = points[0], points[1], points[2] }
  if p[0] == p[1] and p[0] == p[2] then
    if allowRandom then
      local i = 0
      while i ~= Dome.BATTLE_PARTY_SIZE do
        local r = bit.band(Random(), D.PARTY_SIZE)
        if r ~= D.PARTY_SIZE and bit.band(bits, bit.lshift(1, r)) == 0 then
          bits = bit.bor(bits, bit.lshift(1, r))
          i = i + 1
        end
      end
    end
  else
    for i = 0, Dome.BATTLE_PARTY_SIZE - 1 do
      for j = i + 1, D.PARTY_SIZE - 1 do
        if p[i] < p[j] then
          p[i], p[j] = p[j], p[i]
          pos[i], pos[j] = pos[j], pos[i]
        end
        if p[i] == p[j] and bit.band(Random(), 1) ~= 0 then
          p[i], p[j] = p[j], p[i]
          pos[i], pos[j] = pos[j], pos[i]
        end
      end
    end
    for i = 0, Dome.BATTLE_PARTY_SIZE - 1 do bits = bit.bor(bits, bit.lshift(1, pos[i])) end
  end
  return bits
end

local function selectMons(sess, tid, allowRandom, mode)
  local points = {}
  for i = 0, D.PARTY_SIZE - 1 do
    points[i] = 0
    for m = 0, 3 do
      for pm = 1, D.PARTY_SIZE do
        local mon = sess.party[pm]
        local sp = mon and (tonumber(mon.species) or 0) or 0
        points[i] = points[i] + Dome.typeEffectivenessPoints(monMove(sess, tid, i, m), sp, mode, sess)
      end
    end
  end
  return selectFromParty(points, allowRandom)
end

-- pokeemerald/src/battle_dome.c:2660
function Dome.selectedMons(sess, tid)
  local bits
  if bit.band(Random(), 1) ~= 0 then
    bits = selectMons(sess, tid, false, Dome.EFFECTIVENESS.GOOD)
    if bits == 0 then bits = selectMons(sess, tid, true, Dome.EFFECTIVENESS.BAD) end
  else
    bits = selectMons(sess, tid, false, Dome.EFFECTIVENESS.BAD)
    if bits == 0 then bits = selectMons(sess, tid, true, Dome.EFFECTIVENESS.GOOD) end
  end
  return bits
end

-- pokeemerald/src/battle_dome.c:2584
local function createOpponentMon(sess, tid, monIndex, otId)
  local row = facilityMon(sess, MONS(sess, tid)[monIndex + 1])
  local fixedIv = D.fixedIvs(tid)
  local _, level = monSet(sess)
  local mon = D.createMonEvSpread(row.species, level, row.nature, fixedIv, row.evSpread, otId)
  local friendship = D.MAX_FRIENDSHIP
  D.setMoves(mon, row.moves)
  for _, m in ipairs(row.moves) do
    if D.isMove(m, "MOVE_FRUSTRATION") then friendship = 0 end
  end
  mon.friendship, mon.happiness = friendship, friendship
  D.setHeldItem(mon, D.heldItem(row.itemTableId))
  return mon
end

-- pokeemerald/src/battle_dome.c:2615
function Dome.createOpponentMons(sess, tid)
  local party = {}
  local bits = Dome.selectedMons(sess, tid)
  local otId = rng().Random32()
  if Random() % 10 > 5 then
    for i = 0, D.PARTY_SIZE - 1 do
      if bit.band(bits, 1) ~= 0 then party[#party + 1] = createOpponentMon(sess, tid, i, otId) end
      bits = bit.rshift(bits, 1)
    end
  else
    for i = D.PARTY_SIZE - 1, 0, -1 do
      if bit.band(bits, bit.lshift(1, D.PARTY_SIZE - 1)) ~= 0 then
        party[#party + 1] = createOpponentMon(sess, tid, i, otId)
      end
      bits = bit.lshift(bits, 1)
    end
  end
  return party
end

-- pokeemerald/src/battle_dome.c:2575
function Dome.initOpponentParty(sess)
  local tid = Dome.tournamentId(sess, tonumber(sess.frontierOpponentA) or 0)
  sess.frontierDomeParty = Dome.createOpponentMons(sess, tid)
  return sess.frontierDomeParty
end

-- pokeemerald/src/battle_dome.c:5842
function Dome.trainerName(sess, trainerId)
  if trainerId == D.TRAINER_FRONTIER_BRAIN then return Dome.brainTrainer().name or "" end
  if trainerId == D.TRAINER_PLAYER then return tostring(sess.name or "") end
  if trainerId < D.TRAINERS_COUNT then
    local row = monSet(sess).trainers[trainerId]
    return row and row.name or ""
  end
  return ""
end

local function setStr(ctx, adapters, n, v)
  Util.setStringVar(ctx, adapters, n, v)
end

local function tableText(list, name, i)
  local RomText = require("src.core.game3.rom_text")
  return RomText.irOr(RomText.key(name, i - 1), list[i])
end
Dome.tableText = tableText

-- pokeemerald/src/battle_dome.c:2564
function Dome.roundText(sess)
  local f = Util.frontier(sess)
  return tableText(Data.dome().text.rounds, "gRoundsStringTable", (tonumber(f.curChallengeBattleNum) or 0) + 1)
end

-- pokeemerald/src/battle_dome.c:3028
function Dome.incrementStreaks(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local ws = Util.get2(f.domeWinStreaks, mode, lvl)
  if ws < 999 then Util.set2(f.domeWinStreaks, mode, lvl, ws + 1) end
  local tc = Util.get2(f.domeTotalChampionships, mode, lvl)
  if tc < 999 then Util.set2(f.domeTotalChampionships, mode, lvl, tc + 1) end
  if Util.get2(f.domeWinStreaks, mode, lvl) > Util.get2(f.domeRecordWinStreaks, mode, lvl) then
    Util.set2(f.domeRecordWinStreaks, mode, lvl, Util.get2(f.domeWinStreaks, mode, lvl))
  end
end

-- pokeemerald/src/battle_dome.c:3020
function Dome.save(ctx, sess)
  local f = Util.frontier(sess)
  return Util.saveChallenge(sess, "VAR_TEMP_CHALLENGE_STATUS", function()
    f.challengeStatus = Rse.specialVar(ctx, Util.VAR_0x8005)
    Rse.setVar("VAR_TEMP_CHALLENGE_STATUS", 0, sess)
    f.challengePaused = 1
  end)
end

-- pokeemerald/src/battle_dome.c:5415
local function opposingByRound(sess, tid, round)
  local M = Data.dome()
  local match = M.trainerAndRoundToLastMatchCardNum[math.floor(M.pairedTrainerIds[tid + 1] / 2) + 1][round + 1] - 16
  local ids = Dome.winString(sess, match)
  if tid == ids.tournamentIds[1] then return ids.tournamentIds[2] end
  return ids.tournamentIds[1]
end

-- pokeemerald/src/battle_dome.c:5221
function Dome.winningMove(sess, winner, loser, roundId)
  local f = Dome.frontier(sess)
  local scores, moves = {}, {}
  local bestScore, bestId = 0, 0
  local _ = monSet(sess)
  for i = 0, D.PARTY_SIZE - 1 do
    for j = 0, 3 do
      local k0 = i * 4 + j
      scores[k0] = 0
      moves[k0] = monMove(sess, winner, i, j)
      local power = tonumber(move(moves[k0]).power) or 0
      if power == 0 then power = 40
      elseif power == 1 then power = 60
      elseif moves[k0] == MOVE_SELF_DESTRUCT or moves[k0] == MOVE_EXPLOSION then power = math.floor(power / 2) end
      for k = 0, D.PARTY_SIZE - 1 do
        local row = facilityMon(sess, f.domeMonIds[loser + 1][k + 1])
        local personality
        repeat
          personality = rng().Random32()
        until row.nature == personality % 25
        local _, _, abil = speciesInfo(row.species)
        local ability = (personality % 2 == 1) and abil[2] or abil[1]
        local flags = Dome.aiTypeCalc(moves[k0], row.species, ability, sess)
        if bit.band(flags, R.NOT_VERY) ~= 0 and bit.band(flags, R.SUPER) ~= 0 then
          scores[k0] = scores[k0] + power
        elseif bit.band(flags, R.NO_EFFECT) ~= 0 then
          scores[k0] = scores[k0] + 0
        elseif bit.band(flags, R.SUPER) ~= 0 then
          scores[k0] = scores[k0] + power * 2
        elseif bit.band(flags, R.NOT_VERY) ~= 0 then
          scores[k0] = scores[k0] + math.floor(power / 2)
        else
          scores[k0] = scores[k0] + power
        end
      end
      if bestScore < scores[k0] then
        bestId, bestScore = k0, scores[k0] % 65536
      elseif bestScore == scores[k0] then
        if moves[bestId] < moves[k0] then bestId = k0 end
      end
    end
  end
  local j = bestId
  local count = D.PARTY_SIZE * 4
  local i
  repeat
    i = 0
    while i < roundId - 1 do
      if f.domeWinningMoves[opposingByRound(sess, winner, i) + 1] == moves[j] then break end
      i = i + 1
    end
    if i ~= roundId - 1 then
      scores[j] = 0
      bestScore = 0
      local sum = 0
      for k = 0, count - 1 do sum = sum + scores[k] end
      if sum == 0 then break end
      j = 0
      for k = 0, count - 1 do
        if bestScore < scores[k] then
          j, bestScore = k, scores[k]
        elseif bestScore == scores[k] and moves[j] < moves[k] then
          j, bestScore = k, scores[k]
        end
      end
    end
  until i == roundId - 1
  if scores[j] == 0 then j = bestId end
  return moves[j]
end

-- pokeemerald/src/battle_script_commands.c:1594
function Dome.aiTypeCalc(mv, targetSpecies, targetAbility, sess)
  if mv == MOVE_STRUGGLE then return 0 end
  local m = move(mv)
  local moveType = tonumber(m.type) or 0
  local power = tonumber(m.power) or 0
  local _, types = speciesInfo(targetSpecies)
  local t1, t2 = types[1] or 0, types[2] or 0
  local flags = 0
  local function mod(mul)
    if mul == TYPE_MUL_NO_EFFECT then
      flags = bit.band(bit.bor(flags, R.DOESNT_AFFECT), bit.bnot(R.NOT_VERY + R.SUPER))
    elseif mul == TYPE_MUL_NOT_EFFECTIVE then
      if power ~= 0 and bit.band(flags, R.NO_EFFECT) == 0 then
        if bit.band(flags, R.SUPER) ~= 0 then flags = bit.band(flags, bit.bnot(R.SUPER))
        else flags = bit.bor(flags, R.NOT_VERY) end
      end
    elseif mul == TYPE_MUL_SUPER_EFFECTIVE then
      if power ~= 0 and bit.band(flags, R.NO_EFFECT) == 0 then
        if bit.band(flags, R.NOT_VERY) ~= 0 then flags = bit.band(flags, bit.bnot(R.NOT_VERY))
        else flags = bit.bor(flags, R.SUPER) end
      end
    end
  end
  if targetAbility == abilityId(sess, "ABILITY_LEVITATE") and moveType == TYPE_GROUND then
    flags = R.MISSED + R.DOESNT_AFFECT
  else
    for _, e in ipairs(Data.dome().typeEffectiveness) do
      if e[1] ~= TYPE_FORESIGHT and e[1] == moveType then
        if e[2] == t1 then mod(e[3]) end
        if e[2] == t2 and t1 ~= t2 then mod(e[3]) end
      end
    end
  end
  if targetAbility == abilityId(sess, "ABILITY_WONDER_GUARD")
      and (bit.band(flags, R.SUPER) == 0 or bit.band(flags, R.SUPER + R.NOT_VERY) == R.SUPER + R.NOT_VERY)
      and power ~= 0 then
    flags = bit.bor(flags, R.DOESNT_AFFECT)
  end
  return flags
end

local function eliminate(sess, loser, winner, roundId)
  local f = Dome.frontier(sess)
  local t = f.domeTrainers[loser + 1]
  t.isEliminated, t.eliminatedAt = true, roundId
  f.domeWinningMoves[loser + 1] = Dome.winningMove(sess, winner, loser, roundId)
end

-- pokeemerald/src/battle_dome.c:6024
function Dome.decideRoundWinners(sess, roundId)
  local f = Dome.frontier(sess)
  local points1, points2 = 0, 0
  local function totalPoints(a, b, acc)
    for m1 = 0, D.PARTY_SIZE - 1 do
      for slot = 0, 3 do
        for m2 = 0, D.PARTY_SIZE - 1 do
          local mv = facilityMon(sess, f.domeMonIds[a + 1][m1 + 1]).moves[slot + 1]
          acc = acc + Dome.typeEffectivenessPoints(tonumber(mv) or 0,
            facilityMon(sess, f.domeMonIds[b + 1][m2 + 1]).species, Dome.EFFECTIVENESS.AI_VS_AI, sess)
        end
      end
      local base = speciesInfo(facilityMon(sess, f.domeMonIds[a + 1][m1 + 1]).species)
      acc = acc + math.floor((base[1] + base[2] + base[3] + base[4] + base[5] + base[6]) / 10)
    end
    acc = acc + bit.band(Random(), 0x1F)
    return acc + a
  end
  for i = 0, Dome.TRAINERS_COUNT - 1 do
    local t = f.domeTrainers[i + 1]
    if not t.isEliminated and t.trainerId ~= D.TRAINER_PLAYER then
      local id1 = i
      local id2 = Dome.opponentTournamentId(sess, roundId, t.trainerId)
      local t2 = id2 ~= 0xFF and f.domeTrainers[id2 + 1] or nil
      if t.trainerId == D.TRAINER_FRONTIER_BRAIN and id2 ~= 0xFF then
        eliminate(sess, id2, id1, roundId)
      elseif t2 and t2.trainerId == D.TRAINER_FRONTIER_BRAIN and id1 ~= 0xFF then
        eliminate(sess, id1, id2, roundId)
      elseif id2 ~= 0xFF then
        points1 = totalPoints(id1, id2, points1)
        points2 = totalPoints(id2, id1, points2)
        if points1 > points2 then
          eliminate(sess, id2, id1, roundId)
        elseif points1 < points2 then
          eliminate(sess, id1, id2, roundId)
        elseif id1 > id2 then
          eliminate(sess, id2, id1, roundId)
        else
          eliminate(sess, id1, id2, roundId)
        end
      end
    end
  end
end

-- pokeemerald/src/battle_dome.c:5191
function Dome.resolveWinners(ctx, sess, status)
  local f = Dome.frontier(sess)
  local cur = tonumber(f.curChallengeBattleNum) or 0
  local last = sess.frontierDomeLastMoves or {}
  if status == Dome.PLAYER_WON_MATCH then
    local o = Dome.tournamentId(sess, tonumber(sess.frontierOpponentA) or 0)
    f.domeTrainers[o + 1].isEliminated = true
    f.domeTrainers[o + 1].eliminatedAt = cur
    f.domeWinningMoves[o + 1] = tonumber(last.player) or 0
    if cur < Dome.FINAL then Dome.decideRoundWinners(sess, cur) end
  else
    local p = Dome.tournamentId(sess, D.TRAINER_PLAYER)
    f.domeTrainers[p + 1].isEliminated = true
    f.domeTrainers[p + 1].eliminatedAt = cur
    f.domeWinningMoves[p + 1] = tonumber(last.opponent) or 0
    -- pokeemerald/include/constants/battle.h:117
    if last.outcome == "forfeited" or status == Dome.PLAYER_RETIRED then
      f.domeTrainers[p + 1].forfeited = true
    end
    for i = cur, Dome.ROUNDS_COUNT - 1 do Dome.decideRoundWinners(sess, i) end
  end
end

-- pokeemerald/src/battle_dome.c:5782
function Dome.resetSketchedMoves(sess)
  local f = Util.frontier(sess)
  local saved = sess.savedPlayerParty or {}
  local order = sess.selectedOrderFromParty or {}
  local sketch = C(sess):require("moves", "MOVE_SKETCH")
  local Pokemon = require("src.core.game3.pokemon")
  for i = 1, Dome.BATTLE_PARTY_SIZE do
    local idx = tonumber(f.selectedPartyMons[(tonumber(order[i]) or 1)]) or 0
    local mon, orig = sess.party[i], saved[idx]
    if mon and orig then
      for slot = 1, 4 do
        local found = false
        for k = 1, 4 do
          if (tonumber(orig.moves and orig.moves[k]) or 0) == (tonumber(mon.moves and mon.moves[slot]) or 0) then
            found = true
            break
          end
        end
        if not found then
          mon.moves = mon.moves or {}
          mon.moves[slot] = sketch
          mon.maxPp = mon.maxPp or {}
          mon.pp = mon.pp or {}
          mon.maxPp[slot] = Pokemon.movePp(sketch)
          mon.pp[slot] = mon.maxPp[slot]
        end
      end
      saved[idx] = Util.deepCopy(mon)
    end
  end
end

-- pokeemerald/src/battle_dome.c:5808
function Dome.restoreHeldItems(sess)
  local f = Util.frontier(sess)
  local saved = sess.savedPlayerParty or {}
  local order = sess.selectedOrderFromParty or {}
  for i = 1, Dome.BATTLE_PARTY_SIZE do
    local idx = tonumber(f.selectedPartyMons[(tonumber(order[i]) or 1)]) or 0
    local mon, orig = sess.party[i], saved[idx]
    if mon and orig then
      local item = orig.heldItem or orig.item
      mon.heldItem, mon.item = item, item
    end
  end
end

-- pokeemerald/src/battle_dome.c:5825
function Dome.compareSeeds(ctx, sess)
  local r = Dome.tournamentId(sess, tonumber(sess.frontierOpponentA) or 0) > Dome.tournamentId(sess, D.TRAINER_PLAYER)
    and 1 or 2
  Util.setResult(ctx, r)
  return r
end

-- pokeemerald/src/battle_dome.c:5834
function Dome.lastWinnerName(sess)
  local f = Dome.frontier(sess)
  local i = 0
  while i < Dome.TRAINERS_COUNT and f.domeTrainers[i + 1].isEliminated do i = i + 1 end
  local t = f.domeTrainers[math.min(i, Dome.TRAINERS_COUNT - 1) + 1]
  return Dome.trainerName(sess, t.trainerId)
end

-- pokeemerald/src/battle_dome.c:5848
function Dome.initResultsTree(sess)
  local f = Dome.frontier(sess)
  if f.domeLvlMode ~= -f.domeBattleMode and f.challengeStatus ~= Util.CHALLENGE_STATUS.SAVING then return false end
  local species = { 0, 0, 0 }
  local scores = {}
  local lvlMode = f.lvlMode
  f.lvlMode = D.LVL.L50
  f.domeLvlMode, f.domeBattleMode = 1, 1
  for i = 0, Dome.TRAINERS_COUNT - 1 do
    local trainerId
    while true do
      if i < 5 then trainerId = Random() % 10
      elseif i < 15 then trainerId = Random() % 20 + 10
      else trainerId = Random() % 10 + 30 end
      local j = 0
      while j < i do
        if f.domeTrainers[j + 1].trainerId == trainerId then break end
        j = j + 1
      end
      if j == i then break end
    end
    f.domeTrainers[i + 1].trainerId = trainerId
    pickParty(sess, i, trainerId, species)
    local t = f.domeTrainers[i + 1]
    t.isEliminated, t.eliminatedAt, t.forfeited = false, 0, false
  end
  local level = D.FRONTIER_MAX_LEVEL_50
  for i = 0, Dome.TRAINERS_COUNT - 1 do
    local bits, s = 0, 0
    local ivs = D.fixedIvs(f.domeTrainers[i + 1].trainerId)
    for j = 1, D.PARTY_SIZE do
      local row = facilityMon(sess, f.domeMonIds[i + 1][j])
      local stt = Dome.calcMonStats(row.species, level, ivs, row.evSpread, row.nature)
      s = s + stt[1] + stt[2] + stt[5] + stt[4] + stt[3] + stt[0]
      bits = bit.bor(bits, typeBits(row.species))
    end
    scores[i] = (s + math.floor(popcount(bits) * level / 20)) % 65536
  end
  for i = 0, Dome.TRAINERS_COUNT - 2 do
    for j = i + 1, Dome.TRAINERS_COUNT - 1 do
      if scores[i] < scores[j] then
        swap(sess, scores, i, j)
      elseif scores[i] == scores[j] and f.domeTrainers[i + 1].trainerId > f.domeTrainers[j + 1].trainerId then
        swap(sess, scores, i, j)
      end
    end
  end
  for r = 0, Dome.ROUNDS_COUNT - 1 do Dome.decideRoundWinners(sess, r) end
  f.lvlMode = lvlMode
  return true
end

-- pokeemerald/src/battle_dome.c:4709
function Dome.winString(sess, matchNum)
  local f = Dome.frontier(sess)
  local M = Data.dome()
  local range = M.competitorRange[matchNum + 1]
  local ids, count = {}, 0
  local var1, var2 = "", ""
  local winStringId = 0
  local function nameOf(tid)
    return Dome.trainerName(sess, f.domeTrainers[tid + 1].trainerId)
  end
  for i = range[1], range[1] + range[2] - 1 do
    local tid = M.treeTrainerIds2[i + 1]
    if not f.domeTrainers[tid + 1].isEliminated then
      ids[count + 1] = tid
      var1 = nameOf(tid)
      count = count + 1
    end
  end
  if count == 2 then return { id = Dome.TEXT.NO_WINNER_YET, tournamentIds = ids, var1 = var1, var2 = var2 } end
  for i = range[1], range[1] + range[2] - 1 do
    local tid = M.treeTrainerIds2[i + 1]
    local t = f.domeTrainers[tid + 1]
    if t.isEliminated and t.eliminatedAt >= range[3] then
      ids[count + 1] = tid
      count = count + 1
      if t.eliminatedAt == range[3] then
        local mv = tonumber(f.domeWinningMoves[tid + 1]) or 0
        var2 = mv ~= MOVE_NONE and (require("src.core.game3.pokemon").moveName(mv) or "") or ""
        winStringId = (t.forfeited and 1 or 0) * 2
        if mv == MOVE_NONE and not t.forfeited then winStringId = Dome.TEXT.WON_NO_MOVES - 1 end
      else
        var1 = nameOf(tid)
      end
    end
    if count == 2 then break end
  end
  local id = (matchNum == Dome.MATCHES_COUNT - 1) and (winStringId + 2) or (winStringId + 1)
  return { id = id, tournamentIds = ids, var1 = var1, var2 = var2 }
end

local function trainerClassOf(sess, trainerId)
  if trainerId == D.TRAINER_PLAYER then
    local tp = require("src.core.game3.scripting.trainers").pack() or {}
    local brendan = C(sess):require("trainer_classes", "FACILITY_CLASS_BRENDAN")
    return (tp.facilityClassToTrainerClass or {})[brendan] or 0
  elseif trainerId == D.TRAINER_FRONTIER_BRAIN then
    return Dome.brainTrainer().class or 0
  end
  return D.opponentClass(sess, trainerId, F.DOME)
end
Dome.trainerClassOf = trainerClassOf

-- pokeemerald/src/battle_dome.c:4316
function Dome.trainerCard(sess, tid)
  local f = Dome.frontier(sess)
  local M = Data.dome()
  local trainerId = f.domeTrainers[tid + 1].trainerId
  local card = { trainerId = trainerId, tournamentId = tid, species = {} }
  local RomText = require("src.core.game3.rom_text")
  local className = RomText.plain(RomText.key("gTrainerClassNames", trainerClassOf(sess, trainerId)))
  card.title = className .. " " .. Dome.trainerName(sess, trainerId)
  for i = 1, D.PARTY_SIZE do
    if trainerId == D.TRAINER_PLAYER or trainerId == D.TRAINER_FRONTIER_BRAIN then
      card.species[i] = f.domeMonIds[tid + 1][i]
    else
      card.species[i] = facilityMon(sess, f.domeMonIds[tid + 1][i]).species
    end
  end
  card.potential = tableText(M.text.potential, "sBattleDomePotentialTexts",
    (trainerId == D.TRAINER_FRONTIER_BRAIN) and Dome.TRAINERS_COUNT + 1 or tid + 1)
  local pts = {}
  for k = 0, Dome.NUM_MOVE_POINT_TYPES - 1 do pts[k] = 0 end
  for i = 0, D.PARTY_SIZE - 1 do
    for j = 0, 3 do
      local mv
      if trainerId == D.TRAINER_FRONTIER_BRAIN then mv = tonumber(Dome.brainMon(sess, i).moves[j + 1]) or 0
      elseif trainerId == D.TRAINER_PLAYER then mv = tonumber(f.domePlayerPartyData[i + 1].moves[j + 1]) or 0
      else mv = tonumber(facilityMon(sess, f.domeMonIds[tid + 1][i + 1]).moves[j + 1]) or 0 end
      local row = M.styleMovePoints[mv + 1] or {}
      for k = 0, Dome.NUM_MOVE_POINT_TYPES - 1 do pts[k] = pts[k] + (row[k + 1] or 0) end
    end
  end
  card.movePoints = pts
  local style = 0
  while style < #M.styleThresholds do
    local th = M.styleThresholds[style + 1]
    local need, met = 0, 0
    for j = 0, Dome.NUM_MOVE_POINT_TYPES - 1 do
      if th[j + 1] ~= 0 then
        need = need + 1
        if pts[j] ~= 0 and pts[j] >= th[j + 1] then met = met + 1 end
      end
    end
    if need == met then break end
    style = style + 1
  end
  card.style = style
  card.styleText = tableText(M.text.styles, "sBattleDomeOpponentStyleTexts", style + 1)
  card.statText = tableText(M.text.stats, "sBattleDomeOpponentStatsTexts", Dome.statTextId(sess, tid) + 1)
  return card
end

-- pokeemerald/src/battle_dome.c:4555
function Dome.statTextId(sess, tid)
  local f = Dome.frontier(sess)
  local M = Data.dome()
  local trainerId = f.domeTrainers[tid + 1].trainerId
  local a = {}
  for i = 0, 19 do a[i] = 0 end
  local function natureRow(n) return M.natureStatTable[n + 1] end
  local function addMon(evs, nature)
    for j = 0, NUM_STATS - 1 do a[j] = evs[j] end
    a[NUM_STATS] = a[NUM_STATS] + a[0]
    local row = natureRow(nature)
    for j = 0, NUM_NATURE_STATS - 1 do
      if row[j + 1] > 0 then
        a[j + NUM_STATS + 1] = a[j + NUM_STATS + 1] + math.floor(a[j + 1] * 110 / 100)
      elseif row[j + 1] < 0 then
        a[j + NUM_STATS + 1] = a[j + NUM_STATS + 1] + math.floor(a[j + 1] * 90 / 100)
        a[j + NUM_STATS + NUM_NATURE_STATS + 2] = a[j + NUM_STATS + NUM_NATURE_STATS + 2] + 1
      else
        a[j + NUM_STATS + 1] = a[j + NUM_STATS + 1] + a[j + 1]
      end
    end
  end
  for i = 0, D.PARTY_SIZE - 1 do
    local evs, nature = {}, 0
    if trainerId == D.TRAINER_FRONTIER_BRAIN then
      local m = Dome.brainMon(sess, i)
      for j = 0, NUM_STATS - 1 do evs[j] = tonumber(m.evs[j + 1]) or 0 end
      nature = m.nature
    elseif trainerId == D.TRAINER_PLAYER then
      local pd = f.domePlayerPartyData[i + 1]
      for j = 0, NUM_STATS - 1 do evs[j] = tonumber(pd.evs[j + 1]) or 0 end
      nature = pd.nature
    else
      local row = facilityMon(sess, f.domeMonIds[tid + 1][i + 1])
      local k, bits = 0, row.evSpread
      for _ = 0, NUM_STATS - 1 do
        if bit.band(bits, 1) ~= 0 then k = k + 1 end
        bits = bit.rshift(bits, 1)
      end
      k = math.floor(D.MAX_TOTAL_EVS / k)
      bits = row.evSpread
      for j = 0, NUM_STATS - 1 do
        evs[j] = bit.band(bits, 1) ~= 0 and k or 0
        bits = bit.rshift(bits, 1)
      end
      nature = row.nature
    end
    addMon(evs, nature)
  end
  local sum = 0
  for i = 0, NUM_STATS - 1 do sum = sum + a[NUM_STATS + i] end
  for i = 0, NUM_STATS - 1 do a[i] = math.floor(a[NUM_STATS + i] * 100 / math.max(1, sum)) end
  local good, bad = 0, 0
  for k = 0, NUM_STATS - 1 do
    if a[k] > 29 then
      if good == 2 then
        if a[6] < a[k] then
          if a[7] < a[k] then
            if a[6] < a[7] then
              a[6] = a[7]
              a[7] = k
            else
              a[7] = k
            end
          else
            a[6] = a[7]
            a[7] = k
          end
        elseif a[7] < a[k] then
          a[7] = k
        end
      else
        a[good + 6] = k
        good = good + 1
      end
    end
    if a[k] == 0 then
      if bad == 2 then
        if a[k + 12] >= 2 or (a[k + 12] == 1 and a[12 + a[8]] == 0 and a[12 + a[9]] == 0) then
          a[8] = a[9]
          a[9] = k
        elseif a[k + 12] == 1 and a[12 + a[8]] == 0 then
          a[8] = a[9]
          a[9] = k
        elseif a[k + 12] == 1 and a[12 + a[9]] == 0 then
          a[9] = k
        end
      else
        a[bad + 8] = k
        bad = bad + 1
      end
    end
  end
  local off = M.statTextOffsets
  if good == 2 then return off[a[6] + 1] + (a[7] - (a[6] + 1)) + Dome.STATS_TEXT.TWO_GOOD end
  if good == 1 then return a[6] + Dome.STATS_TEXT.ONE_GOOD end
  if bad == 2 then return off[a[8] + 1] + (a[9] - (a[8] + 1)) + Dome.STATS_TEXT.TWO_BAD end
  if bad == 1 then return a[8] + Dome.STATS_TEXT.ONE_BAD end
  return Dome.STATS_TEXT.WELL_BALANCED
end

-- pokeemerald/src/battle_tower.c:2061
function Dome.doSpecialBattle(ctx, adapters, sess)
  local tid = tonumber(sess.frontierOpponentA) or 0
  local mode = Rse.var("VAR_FRONTIER_BATTLE_MODE", sess)
  local party
  if tid == D.TRAINER_FRONTIER_BRAIN then
    -- pokeemerald/src/frontier_util.c:2507
    local _, level = monSet(sess)
    local bits = Dome.selectedMons(sess, Dome.tournamentId(sess, D.TRAINER_FRONTIER_BRAIN))
    party = D.brainParty(sess, F.DOME, level, bits)
  else
    party = sess.frontierDomeParty or Dome.initOpponentParty(sess)
  end
  local Fac = require("src.core.game3.battle.facility_dome")
  return require("src.core.game3.rse.frontier.palace").startFacilityBattle(ctx, adapters, sess, "dome", Fac.new(), {
    party = party,
    double = mode == D.MODE.DOUBLES,
    transitionId = D.specialTransition(sess, "B_DOME", party),
  })
end

-- pokeemerald/src/battle_dome.c:2142
function Dome.call(ctx, adapters, sess, id)
  local FN = Dome.FUNC
  if id == FN.INIT then Dome.init(sess)
  elseif id == FN.GET_DATA then Dome.getData(ctx, sess)
  elseif id == FN.SET_DATA then Dome.setData(ctx, sess)
  elseif id == FN.GET_ROUND_TEXT then setStr(ctx, adapters, 1, Dome.roundText(sess))
  elseif id == FN.GET_OPPONENT_NAME then
    setStr(ctx, adapters, 1, Dome.roundText(sess))
    setStr(ctx, adapters, 2, Dome.trainerName(sess, tonumber(sess.frontierOpponentA) or 0))
  elseif id == FN.INIT_OPPONENT_PARTY then Dome.initOpponentParty(sess)
  elseif id == FN.SET_OPPONENT_ID then sess.frontierOpponentA = Dome.playerOpponentTrainerId(sess)
  elseif id == FN.SET_OPPONENT_GFX then D.setGfxVar(sess, tonumber(sess.frontierOpponentA) or 0, 0, F.DOME)
  elseif id == FN.RESOLVE_WINNERS then Dome.resolveWinners(ctx, sess, Rse.specialVar(ctx, Util.VAR_0x8005))
  elseif id == FN.SAVE then Dome.save(ctx, sess)
  elseif id == FN.INCREMENT_STREAK then Dome.incrementStreaks(sess)
  elseif id == FN.SET_TRAINERS then Dome.frontier(sess)
  elseif id == FN.RESET_SKETCH then Dome.resetSketchedMoves(sess)
  elseif id == FN.RESTORE_HELD_ITEMS then Dome.restoreHeldItems(sess)
  elseif id == FN.REDUCE_PARTY then
    require("src.core.game3.scripting.natives_frontier_story").reducePartyToSelected(sess)
  elseif id == FN.COMPARE_SEEDS then Dome.compareSeeds(ctx, sess)
  elseif id == FN.GET_WINNER_NAME then setStr(ctx, adapters, 1, Dome.lastWinnerName(sess))
  elseif id == FN.INIT_RESULTS_TREE then Dome.initResultsTree(sess)
  elseif id == FN.INIT_TRAINERS then Dome.initTrainers(sess)
  else
    return false, "unknown"
  end
  return true
end

Rse.register("dome", Dome)

return Dome
