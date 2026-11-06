local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")

local bit = rawget(_G, "bit") or require("bit")

local Factory = {}

Factory.MANIFEST = "data/generated/gba/rse/factory/manifest.lua"

-- pokeemerald/include/constants/battle_factory.h:15
Factory.FUNC = {
  INIT = 0, GET_DATA = 1, SET_DATA = 2, SAVE = 3, NULL = 4, NULL2 = 5, SELECT_RENT_MONS = 6, SWAP_RENT_MONS = 7,
  SET_SWAPPED = 8, SET_OPPONENT_MONS = 9, SET_PARTIES = 10, SET_OPPONENT_GFX = 11, GENERATE_OPPONENT_MONS = 12,
  GENERATE_RENTAL_MONS = 13, GET_OPPONENT_MON_TYPE = 14, GET_OPPONENT_STYLE = 15, RESET_HELD_ITEMS = 16,
}
-- pokeemerald/include/constants/battle_factory.h:33
Factory.DATA = { WIN_STREAK = 1, WIN_STREAK_ACTIVE = 2, WIN_STREAK_SWAPS = 3 }
-- pokeemerald/include/constants/battle_factory.h:4
Factory.STYLE = {
  NONE = 0, PREPARATION = 1, SLOW_STEADY = 2, ENDURANCE = 3, HIGH_RISK = 4, WEAKENING = 5, UNPREDICTABLE = 6,
  WEATHER = 7,
}
Factory.NUM_STYLES = 8
-- pokeemerald/include/constants/pokemon.h:24
Factory.NUMBER_OF_MON_TYPES = 18
-- pokeemerald/include/constants/pokemon.h:202
Factory.USE_RANDOM_IVS = 32
-- pokeemerald/include/constants/battle_frontier.h:53
Factory.FRONTIER_MAX_LEVEL_OPEN = 100
-- pokeemerald/src/battle_factory_screen.c:45
Factory.SELECTABLE_MONS_COUNT = 6
Factory.RENTAL_COUNT = 6
Factory.NO_MON = 0xFFFF

local F = D.FACILITY
local M = D.MODE

local cache = {}

function Factory.manifest()
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get())
  local hit = cache[key]
  if hit then return hit end
  local src = require("src.core.game3.dataset").cache():read(Factory.MANIFEST)
  if type(src) ~= "string" then error("factory: " .. Factory.MANIFEST .. " missing from the cache", 0) end
  local chunk = assert((loadstring or load)(src, "@" .. Factory.MANIFEST))
  if setfenv then setfenv(chunk, {}) end
  hit = chunk()
  cache[key] = hit
  return hit
end

function Factory.reset()
  cache = {}
end

local function rng() return D.rng() end
local function var(name, sess) return Rse.var(name, sess) end
local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end

local function modeLvl(sess)
  local f = Util.frontier(sess)
  return var("VAR_FRONTIER_BATTLE_MODE", sess), tonumber(f.lvlMode) or 0
end

local function frontierMons() return D.pack("mons").mons end

local function monsFor(sess)
  if Util.frontier(sess).lvlMode == D.LVL.TENT then return D.tentPack(F.FACTORY).mons end
  return frontierMons()
end
Factory.monsFor = monsFor

function Factory.playerOtId(sess)
  return math.floor(tonumber(sess.trainerId or sess.playerId) or 0) + math.floor(tonumber(sess.secretId) or 0) * 65536
end

local function speciesConst(name, sess) return D.constants(sess):require("species", name) end
local function moveConst(name, sess) return D.constants(sess):require("moves", name) end

local function rentals(sess)
  local f = Util.frontier(sess)
  for i = 1, Factory.RENTAL_COUNT do
    if type(f.rentalMons[i]) ~= "table" then f.rentalMons[i] = {} end
  end
  return f.rentalMons
end
Factory.rentals = rentals

local function winStreakFlag(mode, lvl)
  return Factory.manifest().winStreakFlags[mode + 1][lvl + 1]
end

-- pokeemerald/src/battle_factory.c:198
function Factory.init(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  f.challengeStatus = 0
  f.curChallengeBattleNum = 0
  f.challengePaused = 0
  f.disableRecordBattle = 0
  if bit.band(tonumber(f.winStreakActiveFlags) or 0, winStreakFlag(mode, lvl)) == 0 then
    Util.set2(f.factoryWinStreaks, mode, lvl, 0)
    Util.set2(f.factoryRentsCount, mode, lvl, 0)
  end
  sess.factoryPerformedSwap = false
  local r = rentals(sess)
  for i = 1, Factory.RENTAL_COUNT do r[i].monId = Factory.NO_MON end
  sess.frontierTempParty = { Factory.NO_MON, Factory.NO_MON, Factory.NO_MON }
  sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = sess.x, y = sess.y }
  sess.frontierOpponentA = 0
end

-- pokeemerald/src/battle_factory.c:224
function Factory.getData(ctx, sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  if which == Factory.DATA.WIN_STREAK then
    Util.setResult(ctx, Util.get2(f.factoryWinStreaks, mode, lvl))
  elseif which == Factory.DATA.WIN_STREAK_ACTIVE then
    Util.setResult(ctx, bit.band(tonumber(f.winStreakActiveFlags) or 0, winStreakFlag(mode, lvl)) ~= 0 and 1 or 0)
  elseif which == Factory.DATA.WIN_STREAK_SWAPS then
    Util.setResult(ctx, Util.get2(f.factoryRentsCount, mode, lvl))
  end
end

-- pokeemerald/src/battle_factory.c:243
function Factory.setData(ctx, sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  local v = specialVar(ctx, Util.VAR_0x8006)
  if which == Factory.DATA.WIN_STREAK then
    Util.set2(f.factoryWinStreaks, mode, lvl, v)
  elseif which == Factory.DATA.WIN_STREAK_ACTIVE then
    local flags = tonumber(f.winStreakActiveFlags) or 0
    if v ~= 0 then
      flags = bit.bor(flags, winStreakFlag(mode, lvl))
    else
      flags = bit.band(flags, bit.bnot(winStreakFlag(mode, lvl)))
    end
    if flags < 0 then flags = flags + 4294967296 end
    f.winStreakActiveFlags = flags
  elseif which == Factory.DATA.WIN_STREAK_SWAPS then
    if sess.factoryPerformedSwap == true then
      Util.set2(f.factoryRentsCount, mode, lvl, v)
      sess.factoryPerformedSwap = false
    end
  end
end

-- pokeemerald/src/battle_factory.c:269
function Factory.save(ctx, sess)
  local f = Util.frontier(sess)
  return Util.saveChallenge(sess, "VAR_TEMP_CHALLENGE_STATUS", function()
    f.challengeStatus = specialVar(ctx, Util.VAR_0x8005)
    Rse.setVar("VAR_TEMP_CHALLENGE_STATUS", 0, sess)
    f.challengePaused = 1
  end)
end

-- pokeemerald/src/battle_factory.c:298
function Factory.setPerformedSwap(sess)
  sess.factoryPerformedSwap = true
end

-- pokeemerald/src/battle_factory.c:739
function Factory.fixedIV(challengeNum, isLastBattle)
  local tbl = Factory.manifest().fixedIvTable
  local rows = #tbl - 1
  local ivSet = challengeNum
  -- pokeemerald/src/battle_factory.c:750
  if challengeNum > rows then ivSet = rows - 1 end
  return tbl[ivSet + 1][isLastBattle and 2 or 1]
end

-- pokeemerald/src/battle_factory.c:829
function Factory.monId(lvlMode, challengeNum, useBetterRange)
  local ranges = Factory.manifest().rentalRanges
  local adder = (lvlMode == D.LVL.L50) and 0 or 8
  local row
  if challengeNum < 7 then
    row = ranges[adder + challengeNum + (useBetterRange and 1 or 0) + 1]
  else
    row = ranges[adder + 7 + 1]
  end
  local numMons = row[2] - row[1] + 1
  return (rng().Random() % numMons) + row[1]
end

-- pokeemerald/src/battle_factory.c:868
function Factory.pastRentalsRank(sess, battleMode, lvlMode)
  local rents = Util.get2(Util.frontier(sess).factoryRentsCount, battleMode, lvlMode)
  if rents < 15 then return 0 end
  if rents < 22 then return 1 end
  if rents < 29 then return 2 end
  if rents < 36 then return 3 end
  if rents < 43 then return 4 end
  return 5
end

-- pokeemerald/src/battle_factory.c:913
function Factory.avoidReturn(moves, sess)
  local ret, frus = moveConst("MOVE_RETURN", sess), moveConst("MOVE_FRUSTRATION", sess)
  local out = {}
  for i = 1, 4 do
    local m = tonumber(moves[i]) or 0
    if m == ret then m = frus end
    out[i] = m
  end
  return out
end

local function setIvs(mon, ivs)
  local Pokemon = require("src.core.game3.pokemon")
  mon.ivs = ivs
  mon.hp = nil
  Pokemon.applyStats(mon)
  mon.hp = mon.maxHp
end

-- pokeemerald/src/pokemon.c:2274
local function randomIvs(mon)
  local Rng = rng()
  local a, b = Rng.Random(), Rng.Random()
  setIvs(mon, {
    hp = bit.band(a, 31), atk = bit.band(bit.rshift(a, 5), 31), def = bit.band(bit.rshift(a, 10), 31),
    spe = bit.band(b, 31), spa = bit.band(bit.rshift(b, 5), 31), spd = bit.band(bit.rshift(b, 10), 31),
  })
end

local function finishMon(mon, row, sess, opts)
  opts = opts or {}
  D.setMoves(mon, Factory.avoidReturn(row.moves, sess))
  mon.friendship, mon.happiness = 0, 0
  D.setHeldItem(mon, D.heldItem(row.itemTableId))
  if opts.player then
    mon.otName, mon.ot = tostring(sess.name or ""), tostring(sess.name or "")
    local female = sess.gender == "female" or sess.gender == "F" or sess.gender == 1
    mon.otGender = female and 1 or 0
  end
  return mon
end

-- pokeemerald/src/pokemon.c:2562
function Factory.createEvSpreadMon(row, level, fixedIV, otId, sess, opts)
  local iv = fixedIV
  if iv >= Factory.USE_RANDOM_IVS then iv = 0 end
  local mon = D.createMonEvSpread(row.species, level, row.nature, iv, row.evSpread, otId)
  if fixedIV >= Factory.USE_RANDOM_IVS then
    randomIvs(mon)
    D.setEvs(mon, Factory.evList(row.evSpread))
  end
  return finishMon(mon, row, sess, opts)
end

-- pokeemerald/src/battle_factory.c:442
function Factory.evList(evSpread)
  local count = 0
  for i = 0, 5 do
    if bit.band(evSpread, bit.lshift(1, i)) ~= 0 then count = count + 1 end
  end
  local out = {}
  local amount = count > 0 and math.floor(D.MAX_TOTAL_EVS / count) or 0
  for i = 0, 5 do out[i + 1] = (bit.band(evSpread, bit.lshift(1, i)) ~= 0) and amount or 0 end
  return out
end

local function applyAbilityNum(mon, abilityNum)
  local Pokemon = require("src.core.game3.pokemon")
  abilityNum = tonumber(abilityNum) or 0
  local pair = Pokemon.abilities(mon.species)
  if (pair[2] or 0) == 0 then abilityNum = 0 end
  mon.abilityNum = abilityNum
  local ab = pair[abilityNum + 1] or 0
  mon.ability, mon.abilityId = ab, ab
end
Factory.applyAbilityNum = applyAbilityNum

-- pokeemerald/src/battle_factory.c:435
function Factory.rentalMon(sess, rental, level, mons)
  mons = mons or monsFor(sess)
  local row = mons[rental.monId]
  local mon = D.createMon(row.species, level, tonumber(rental.ivs) or 0, tonumber(rental.personality) or 0,
    Factory.playerOtId(sess))
  D.setEvs(mon, Factory.evList(row.evSpread))
  finishMon(mon, row, sess, { player = true })
  applyAbilityNum(mon, rental.abilityNum)
  return mon
end

function Factory.partyLevel(sess)
  local f = Util.frontier(sess)
  if f.lvlMode == D.LVL.TENT then return D.TENT_MIN_LEVEL end
  if f.lvlMode ~= D.LVL.L50 then return Factory.FRONTIER_MAX_LEVEL_OPEN end
  return D.FRONTIER_MAX_LEVEL_50
end

local function heldOf(mons, monId) return D.heldItem(mons[monId].itemTableId) end

-- pokeemerald/src/battle_factory.c:303
function Factory.generateOpponentMons(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local ws = Util.get2(f.factoryWinStreaks, mode, lvl)
  local challengeNum = math.floor(ws / D.STAGES_PER_CHALLENGE)
  local n = tonumber(f.curChallengeBattleNum) or 0
  local Tower = require("src.core.game3.rse.frontier.tower")
  local tid
  repeat
    tid = Tower.randomScaledTrainerId(challengeNum, n)
    local dup = false
    for i = 1, n do
      if tonumber(f.trainerIds[i]) == tid then dup = true break end
    end
  until not dup
  sess.frontierOpponentA = tid
  if n < D.STAGES_PER_CHALLENGE - 1 then f.trainerIds[n + 1] = tid end
  local mons = frontierMons()
  local unown = speciesConst("SPECIES_UNOWN", sess)
  local r = rentals(sess)
  local species, items, temp = {}, {}, {}
  local i = 0
  while i ~= D.PARTY_SIZE do
    local monId = Factory.monId(lvl, challengeNum, false)
    local row = mons[monId]
    local ok = row.species ~= unown
    if ok then
      for j = 1, Factory.RENTAL_COUNT do
        local rid = r[j].monId
        if rid and mons[rid] and mons[rid].species == row.species then ok = false break end
      end
    end
    if ok and lvl == D.LVL.L50 and monId > D.FRONTIER_MONS_HIGH_TIER then ok = false end
    if ok then
      for k = 1, i do if species[k] == row.species then ok = false break end end
    end
    if ok then
      local item = heldOf(mons, monId)
      for k = 1, i do if items[k] ~= 0 and items[k] == item then ok = false break end end
    end
    if ok then
      species[i + 1] = row.species
      items[i + 1] = heldOf(mons, monId)
      temp[i + 1] = monId
      i = i + 1
    end
  end
  sess.frontierTempParty = temp
end

-- pokeemerald/src/battle_factory.c:379
function Factory.setOpponentGfx(sess)
  D.setGfxVar(sess, tonumber(sess.frontierOpponentA) or 0, 0, F.FACTORY)
end

-- pokeemerald/src/battle_factory.c:384
function Factory.setRentalsToOpponentParty(sess)
  local mons = monsFor(sess)
  local r = rentals(sess)
  local enemy = sess.frontierEnemyParty or {}
  for i = 1, D.PARTY_SIZE do
    local slot = r[i + D.PARTY_SIZE]
    local mon = enemy[i]
    slot.monId = sess.frontierTempParty and sess.frontierTempParty[i]
    slot.ivs = mon and mon.ivs and mon.ivs.atk or 0
    slot.personality = mon and tonumber(mon.personality) or 0
    slot.abilityNum = mon and tonumber(mon.abilityNum) or 0
    if mon and slot.monId and mons[slot.monId] then D.setHeldItem(mon, heldOf(mons, slot.monId)) end
  end
end

-- pokeemerald/src/battle_factory.c:403
function Factory.setPlayerAndOpponentParties(ctx, sess)
  local mons = monsFor(sess)
  local level = Factory.partyLevel(sess)
  local r = rentals(sess)
  local arg = specialVar(ctx, Util.VAR_0x8005)
  if arg < 2 then
    local party = {}
    for i = 1, D.PARTY_SIZE do party[i] = Factory.rentalMon(sess, r[i], level, mons) end
    sess.party = party
  end
  if arg == 0 or arg == 2 then
    local enemy = {}
    for i = 1, D.PARTY_SIZE do
      local slot = r[i + D.PARTY_SIZE]
      local row = mons[slot.monId]
      local mon = D.createMon(row.species, level, tonumber(slot.ivs) or 0, tonumber(slot.personality) or 0,
        Factory.playerOtId(sess))
      D.setEvs(mon, Factory.evList(row.evSpread))
      D.setMoves(mon, Factory.avoidReturn(row.moves, sess))
      D.setHeldItem(mon, heldOf(mons, slot.monId))
      applyAbilityNum(mon, slot.abilityNum)
      enemy[i] = mon
    end
    sess.frontierEnemyParty = enemy
  end
end

-- pokeemerald/src/battle_factory.c:509
function Factory.generateInitialRentalMons(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local challengeNum = math.floor(Util.get2(f.factoryWinStreaks, mode, lvl) / D.STAGES_PER_CHALLENGE)
  local factoryMode = (mode == M.DOUBLES) and M.DOUBLES or M.SINGLES
  local factoryLvl = (lvl ~= D.LVL.L50) and D.LVL.OPEN or D.LVL.L50
  local rank = Factory.pastRentalsRank(sess, factoryMode, factoryLvl)
  local mons = frontierMons()
  local unown = speciesConst("SPECIES_UNOWN", sess)
  local r = rentals(sess)
  local species, monIds, items = {}, {}, {}
  local curSpecies = 0
  local i = 0
  while i ~= 6 do
    local monId = Factory.monId(factoryLvl, challengeNum, i < rank)
    local row = mons[monId]
    local ok = row.species ~= unown
    if ok then
      for j = 1, i do
        if monIds[j] == monId then ok = false break end
        if species[j] == row.species then
          if curSpecies == 0 then curSpecies = row.species else ok = false break end
        end
      end
    end
    if ok then
      local item = heldOf(mons, monId)
      for j = 1, i do
        if items[j] ~= 0 and items[j] == item then
          if row.species == curSpecies then curSpecies = 0 end
          ok = false
          break
        end
      end
    end
    if ok then
      r[i + 1].monId = monId
      species[i + 1] = row.species
      items[i + 1] = heldOf(mons, monId)
      monIds[i + 1] = monId
      i = i + 1
    end
  end
end

-- pokeemerald/src/battle_factory.c:607
function Factory.opponentMostCommonType(sess)
  local Pokemon = require("src.core.game3.pokemon")
  local mons = frontierMons()
  local counts = {}
  for t = 0, Factory.NUMBER_OF_MON_TYPES - 1 do counts[t] = 0 end
  for i = 1, D.PARTY_SIZE do
    local row = mons[sess.frontierTempParty[i]]
    local ty = Pokemon.types(row.species)
    counts[ty[1]] = counts[ty[1]] + 1
    if ty[1] ~= ty[2] then counts[ty[2]] = counts[ty[2]] + 1 end
  end
  local first, second = 0, 0
  for t = 1, Factory.NUMBER_OF_MON_TYPES - 1 do
    if counts[first] < counts[t] then
      first = t
    elseif counts[first] == counts[t] then
      second = t
    end
  end
  if counts[first] ~= 0 then
    if counts[first] > counts[second] then return first end
    if first == second then return first end
  end
  return Factory.NUMBER_OF_MON_TYPES
end

-- pokeemerald/src/battle_factory.c:692
function Factory.moveBattleStyle(move)
  for i, list in ipairs(Factory.manifest().moveStyles) do
    for _, m in ipairs(list) do
      if m == move then return i end
    end
  end
  return Factory.STYLE.NONE
end

-- pokeemerald/src/battle_factory.c:657
function Factory.opponentBattleStyle(sess)
  local mons = frontierMons()
  local points = {}
  for s = 0, Factory.NUM_STYLES - 1 do points[s] = 0 end
  for i = 1, D.PARTY_SIZE do
    local row = mons[sess.frontierTempParty[i]]
    for j = 1, 4 do
      local s = Factory.moveBattleStyle(tonumber(row.moves[j]) or 0)
      points[s] = points[s] + 1
    end
  end
  local req = Factory.manifest().requiredMoveCounts
  local result, count = Factory.STYLE.NONE, 0
  for s = 1, Factory.NUM_STYLES - 1 do
    if points[s] >= req[s] then
      result = s
      count = count + 1
    end
  end
  if count > 2 then result = Factory.NUM_STYLES end
  return result
end

-- pokeemerald/src/battle_factory.c:714
function Factory.restorePlayerPartyHeldItems(sess)
  local mons = monsFor(sess)
  local r = rentals(sess)
  for i = 1, D.PARTY_SIZE do
    local mon = sess.party and sess.party[i]
    local rid = r[i].monId
    if mon and rid and mons[rid] then D.setHeldItem(mon, heldOf(mons, rid)) end
  end
end

-- pokeemerald/src/battle_factory.c:889
function Factory.aiFlags(sess)
  local f = Util.frontier(sess)
  if f.lvlMode == D.LVL.TENT then return 0 end
  local BP = require("src.core.game3.battle.profile")
  local p = BP.get(sess)
  local bad = BP.aiBit(p, "CHECK_BAD_MOVE")
  local all = bad + BP.aiBit(p, "TRY_TO_FAINT") + BP.aiBit(p, "CHECK_VIABILITY")
  local mode, lvl = modeLvl(sess)
  local challengeNum = math.floor(Util.get2(f.factoryWinStreaks, mode, lvl) / D.STAGES_PER_CHALLENGE)
  if tonumber(sess.frontierOpponentA) == D.TRAINER_FRONTIER_BRAIN then return all end
  if challengeNum < 2 then return 0 end
  if challengeNum < 4 then return bad end
  return all
end

-- pokeemerald/src/battle_factory.c:759
function Factory.fillBrainParty(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local challengeNum = math.floor(Util.get2(f.factoryWinStreaks, mode, lvl) / D.STAGES_PER_CHALLENGE)
  local fixedIV = Factory.fixedIV(challengeNum + 2, false)
  local _, level = D.facilityPtrs(sess, F.FACTORY)
  local otId = Factory.playerOtId(sess)
  local mons = frontierMons()
  local unown = speciesConst("SPECIES_UNOWN", sess)
  local r = rentals(sess)
  local species, items, party = {}, {}, {}
  local i = 0
  while i ~= D.PARTY_SIZE do
    local monId = Factory.monId(lvl, challengeNum, false)
    local row = mons[monId]
    local ok = row.species ~= unown
    if ok and level == D.FRONTIER_MAX_LEVEL_50 and monId > D.FRONTIER_MONS_HIGH_TIER then ok = false end
    if ok then
      for j = 1, Factory.RENTAL_COUNT do
        if r[j].monId == monId then ok = false break end
      end
    end
    if ok then
      for k = 1, i do if species[k] == row.species then ok = false break end end
    end
    if ok then
      local item = heldOf(mons, monId)
      for k = 1, i do if items[k] ~= 0 and items[k] == item then ok = false break end end
    end
    if ok then
      species[i + 1] = row.species
      items[i + 1] = heldOf(mons, monId)
      party[i + 1] = Factory.createEvSpreadMon(row, level, fixedIV, otId, sess)
      i = i + 1
    end
  end
  return party
end

-- pokeemerald/src/battle_tower.c:1824
function Factory.fillFrontierTrainerParty(sess, trainerId)
  local f = Util.frontier(sess)
  local fixedIV
  if trainerId < D.TRAINERS_COUNT then
    local mode = var("VAR_FRONTIER_BATTLE_MODE", sess)
    -- pokeemerald/src/battle_tower.c:1834
    local challengeNum = math.floor(Util.get2(f.towerWinStreaks, mode, D.LVL.L50) / D.STAGES_PER_CHALLENGE)
    local last = (tonumber(f.curChallengeBattleNum) or 0) >= D.STAGES_PER_CHALLENGE - 1
    fixedIV = Factory.fixedIV(challengeNum, last)
  elseif trainerId == D.TRAINER_EREADER then
    local out = {}
    local party = f.ereaderTrainer and f.ereaderTrainer.party or {}
    for i = 1, D.PARTY_SIZE do
      if party[i] then out[i] = D.battleTowerMon(party[i], false) end
    end
    return out
  elseif trainerId == D.TRAINER_FRONTIER_BRAIN then
    return Factory.fillBrainParty(sess)
  else
    fixedIV = D.MAX_PER_STAT_IVS
  end
  local _, level = D.facilityPtrs(sess, F.FACTORY)
  local otId = Factory.playerOtId(sess)
  local mons = frontierMons()
  local out = {}
  for i = 1, D.PARTY_SIZE do
    local row = mons[sess.frontierTempParty[i]]
    out[i] = Factory.createEvSpreadMon(row, level, fixedIV, otId, sess)
  end
  return out
end

-- pokeemerald/src/battle_tower.c:1887
function Factory.fillTentTrainerParty(sess)
  local mons = D.tentPack(F.FACTORY).mons
  local otId = Factory.playerOtId(sess)
  local frus = moveConst("MOVE_FRUSTRATION", sess)
  local out = {}
  for i = 1, D.PARTY_SIZE do
    local row = mons[sess.frontierTempParty[i]]
    local mon = Factory.createEvSpreadMon(row, D.TENT_MIN_LEVEL, 0, otId, sess)
    for _, m in ipairs(row.moves) do
      if tonumber(m) == frus then mon.friendship, mon.happiness = 0, 0 end
    end
    out[i] = mon
  end
  return out
end

-- pokeemerald/src/battle_tower.c:1815
function Factory.fillTrainerParty(sess)
  if Util.frontier(sess).lvlMode ~= D.LVL.TENT then
    return Factory.fillFrontierTrainerParty(sess, tonumber(sess.frontierOpponentA) or 0)
  end
  return Factory.fillTentTrainerParty(sess)
end

-- pokeemerald/src/battle_tower.c:2092
function Factory.doSpecialBattle(ctx, adapters, sess)
  local party = Factory.fillTrainerParty(sess)
  sess.frontierEnemyParty = party
  local battleParty = {}
  for i, mon in ipairs(party) do battleParty[i] = Util.deepCopy(mon) end
  local Tower = require("src.core.game3.rse.frontier.tower")
  return Tower.startBattle(ctx, adapters, sess, "factory", {
    party = battleParty,
    double = var("VAR_FRONTIER_BATTLE_MODE", sess) == M.DOUBLES,
    aiFlags = Factory.aiFlags(sess),
    transitionId = D.specialTransition(sess, "B_FACTORY", party),
  })
end

-- pokeemerald/src/battle_factory_screen.c:1736
function Factory.selectableMons(sess)
  local f = Util.frontier(sess)
  local r = rentals(sess)
  local otId = Factory.playerOtId(sess)
  local out = {}
  if f.lvlMode ~= D.LVL.TENT then
    local mode, lvl = modeLvl(sess)
    local challengeNum = math.floor(Util.get2(f.factoryWinStreaks, mode, lvl) / D.STAGES_PER_CHALLENGE)
    local level = (lvl ~= D.LVL.L50) and Factory.FRONTIER_MAX_LEVEL_OPEN or D.FRONTIER_MAX_LEVEL_50
    local rank = Factory.pastRentalsRank(sess, mode, lvl)
    local mons = frontierMons()
    for i = 1, Factory.SELECTABLE_MONS_COUNT do
      local monId = r[i].monId
      local ivs = Factory.fixedIV(challengeNum + ((i - 1) < rank and 1 or 0), false)
      out[i] = { monId = monId, mon = Factory.createEvSpreadMon(mons[monId], level, ivs, otId, sess, { player = true }) }
    end
  else
    -- pokeemerald/src/battle_factory_screen.c:1780
    local mons = D.tentPack(F.FACTORY).mons
    for i = 1, Factory.SELECTABLE_MONS_COUNT do
      local monId = r[i].monId
      out[i] = { monId = monId, mon = Factory.createEvSpreadMon(mons[monId], D.TENT_MIN_LEVEL, 0, otId, sess, { player = true }) }
    end
  end
  return out
end

-- pokeemerald/src/battle_factory_screen.c:2255
function Factory.speciesValid(sess, selectable, chosen, monId)
  local mons = monsFor(sess)
  local species = mons[monId].species
  for _, idx in ipairs(chosen) do
    if mons[selectable[idx].monId].species == species then return false end
  end
  return true
end

-- pokeemerald/src/battle_factory_screen.c:1810
function Factory.copyMonsToPlayerParty(sess, selectable, chosen)
  local r = rentals(sess)
  local party = {}
  for i = 1, D.PARTY_SIZE do
    local pick = selectable[chosen[i]]
    local mon = pick.mon
    party[i] = mon
    r[i].monId = pick.monId
    r[i].personality = tonumber(mon.personality) or 0
    r[i].abilityNum = tonumber(mon.abilityNum) or 0
    r[i].ivs = mon.ivs and mon.ivs.atk or 0
  end
  sess.party = party
  return party
end

-- pokeemerald/src/battle_factory_screen.c:2350
function Factory.copySwappedMonData(sess, playerMonId, enemyMonId)
  local r = rentals(sess)
  local enemy = sess.frontierEnemyParty or {}
  local mon = Util.deepCopy(enemy[enemyMonId])
  mon.friendship, mon.happiness = 0, 0
  mon.otName, mon.ot = tostring(sess.name or ""), tostring(sess.name or "")
  sess.party[playerMonId] = mon
  local src = r[enemyMonId + D.PARTY_SIZE]
  r[playerMonId].monId = src.monId
  r[playerMonId].ivs = src.ivs
  r[playerMonId].personality = tonumber(mon.personality) or 0
  r[playerMonId].abilityNum = tonumber(mon.abilityNum) or 0
end

-- pokeemerald/src/battle_factory_screen.c:4162
function Factory.alreadyHasSameSpecies(sess, enemyMonId, playerMonId)
  local enemy = sess.frontierEnemyParty or {}
  local species = tonumber(enemy[enemyMonId] and enemy[enemyMonId].species)
  for i = 1, D.PARTY_SIZE do
    local mon = sess.party and sess.party[i]
    if i ~= playerMonId and mon and tonumber(mon.species) == species then return true end
  end
  return false
end

local function fadeInField(done)
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.begin then
    Fade.begin(Fade.MODE.FROM_BLACK, 1, done)
  else
    done()
  end
end

-- pokeemerald/src/battle_factory_screen.c:1146
local function closeFieldMessage(ctx, adapters)
  if adapters and adapters.closeMessage then pcall(adapters.closeMessage) end
  local ok, Message = pcall(require, "src.ui.game3.message")
  if ok and Message and Message.close then pcall(Message.close) end
  if ctx then ctx.messageOpen = false end
end

-- pokeemerald/src/battle_factory.c:287
function Factory.selectScreen(ctx, adapters, sess)
  local Natives = require("src.core.game3.scripting.natives")
  sess.party = {}
  local selectable = Factory.selectableMons(sess)
  closeFieldMessage(ctx, adapters)
  return Natives.yieldHost(ctx, adapters, function(done)
    local Screen = require("src.ui.game3.screens").get("factory_select", sess)
    Screen.show({
      session = sess,
      mons = selectable,
      speciesValid = function(chosen, monId) return Factory.speciesValid(sess, selectable, chosen, monId) end,
      onDone = function(chosen)
        Factory.copyMonsToPlayerParty(sess, selectable, chosen)
        fadeInField(done)
      end,
    })
  end)
end

-- pokeemerald/src/battle_factory.c:293
function Factory.swapScreen(ctx, adapters, sess)
  local Natives = require("src.core.game3.scripting.natives")
  closeFieldMessage(ctx, adapters)
  return Natives.yieldHost(ctx, adapters, function(done)
    local Screen = require("src.ui.game3.screens").get("factory_swap", sess)
    Screen.show({
      session = sess,
      party = sess.party,
      enemy = sess.frontierEnemyParty or {},
      sameSpecies = function(enemyMonId, playerMonId) return Factory.alreadyHasSameSpecies(sess, enemyMonId, playerMonId) end,
      onDone = function(result)
        -- pokeemerald/src/battle_factory_screen.c:2414
        if result and result.swapped then
          Factory.copySwappedMonData(sess, result.playerMonId, result.enemyMonId)
          Util.setResult(ctx, 0)
        else
          Util.setResult(ctx, 1)
        end
        fadeInField(done)
      end,
    })
  end)
end

-- pokeemerald/src/battle_factory.c:708
function Factory.inBattleFactory(sess)
  local m = tostring(sess and sess.map or "")
  return m == "EM_BATTLE_FRONTIER_BATTLE_FACTORY_PRE_BATTLE_ROOM" or m == "EM_BATTLE_FRONTIER_BATTLE_FACTORY_BATTLE_ROOM"
end

Rse.register("factory", Factory)

return Factory
