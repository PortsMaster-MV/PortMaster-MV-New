local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")

local Tents = {}

-- pokeemerald/include/constants/battle_tent.h:10
Tents.VERDANTURF = { INIT = 0, GET_PRIZE = 1, SET_PRIZE = 2, SET_OPPONENT_GFX = 3, GET_OPPONENT_INTRO = 4, SAVE = 5,
  SET_RANDOM_PRIZE = 6, GIVE_PRIZE = 7 }
-- pokeemerald/include/constants/battle_tent.h:19
Tents.FALLARBOR = { INIT = 0, GET_PRIZE = 1, SET_PRIZE = 2, SAVE = 3, SET_RANDOM_PRIZE = 4, GIVE_PRIZE = 5,
  GET_OPPONENT_NAME = 6 }
-- pokeemerald/include/constants/battle_tent.h:27
Tents.SLATEPORT = { INIT = 0, GET_PRIZE = 1, SET_PRIZE = 2, SAVE = 3, SET_RANDOM_PRIZE = 4, GIVE_PRIZE = 5,
  SELECT_RENT_MONS = 6, SWAP_RENT_MONS = 7, GENERATE_OPPONENT_MONS = 8, GENERATE_RENTAL_MONS = 9 }

local F = D.FACILITY

Tents.PRIZE_FIELD = { verdanturf = "verdanturfTentPrize", fallarbor = "fallarborTentPrize",
  slateport = "slateportTentPrize" }

local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end

-- pokeemerald/src/battle_tent.c:110
function Tents.init(sess)
  local f = Util.frontier(sess)
  f.challengeStatus = 0
  f.curChallengeBattleNum = 0
  f.challengePaused = 0
  sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = sess.x, y = sess.y }
end

-- pokeemerald/src/battle_tent.c:118
function Tents.getPrize(ctx, sess, tent)
  Util.setResult(ctx, tonumber(Util.frontier(sess)[Tents.PRIZE_FIELD[tent]]) or 0)
end

-- pokeemerald/src/battle_tent.c:123
function Tents.setPrize(ctx, sess, tent)
  Util.frontier(sess)[Tents.PRIZE_FIELD[tent]] = specialVar(ctx, Util.VAR_0x8006)
end

-- pokeemerald/src/battle_tent.c:140
function Tents.save(ctx, sess)
  local f = Util.frontier(sess)
  return Util.saveChallenge(sess, "VAR_TEMP_0", function()
    f.challengeStatus = specialVar(ctx, Util.VAR_0x8005)
    Rse.setVar("VAR_TEMP_0", 0, sess)
    f.challengePaused = 1
  end)
end

-- pokeemerald/src/battle_tent.c:148
function Tents.setRandomPrize(sess, tent)
  local list = D.manifest().tentRewards[tent]
  Util.frontier(sess)[Tents.PRIZE_FIELD[tent]] = list[(D.rng().Random() % #list) + 1]
end

-- pokeemerald/src/battle_tent.c:153
function Tents.givePrize(ctx, adapters, sess, tent)
  local f = Util.frontier(sess)
  local field = Tents.PRIZE_FIELD[tent]
  local item = tonumber(f[field]) or 0
  local Bag = require("src.core.game3.bag")
  if item ~= 0 and Bag.add(sess.bag, item, 1) then
    Util.setStringVar(ctx, adapters, 1, require("src.core.game3.items_data").displayName(item) or "")
    f[field] = 0
    Util.setResult(ctx, 1)
  else
    Util.setResult(ctx, 0)
  end
end

-- pokeemerald/src/battle_tower.c:3312
function Tents.trainerId(facility)
  if facility == F.PALACE or facility == F.ARENA or facility == F.FACTORY then
    return D.rng().Random() % D.NUM_BATTLE_TENT_TRAINERS
  end
  return 0
end

-- pokeemerald/src/battle_tower.c:3361
function Tents.setNextOpponent(sess)
  local f = Util.frontier(sess)
  local facility = Rse.var("VAR_FRONTIER_FACILITY", sess)
  local n = tonumber(f.curChallengeBattleNum) or 0
  local tid
  while true do
    tid = Tents.trainerId(facility)
    local dup = false
    for i = 1, n do
      if tonumber(f.trainerIds[i]) == tid then dup = true break end
    end
    if not dup then break end
  end
  sess.frontierOpponentA = tid
  D.setGfxVar(sess, tid, 0, facility)
  if n + 1 < D.TENT_STAGES_PER_CHALLENGE then f.trainerIds[n + 1] = tid end
end

-- pokeemerald/src/battle_tent.c:128
function Tents.setVerdanturfGfx(sess)
  sess.frontierOpponentA = math.floor(((D.rng().Random() % 255) * 5) / 64)
  D.setGfxVar(sess, sess.frontierOpponentA, 0, F.PALACE)
end

-- pokeemerald/src/battle_tent.c:134
function Tents.opponentIntro(ctx, adapters, sess, facility)
  local tid = tonumber(sess.frontierOpponentA) or 0
  if tid < D.TRAINERS_COUNT then
    Util.setStringVar(ctx, adapters, 4, D.trainerSpeech(sess, tid, 0, facility))
  end
end

-- pokeemerald/src/battle_tent.c:203
function Tents.bufferFallarborName(ctx, adapters, sess)
  Util.setStringVar(ctx, adapters, 1, D.trainerName(sess, tonumber(sess.frontierOpponentA) or 0, F.ARENA))
end

-- pokeemerald/src/battle_tent.c:289
function Tents.generateRentalMons(sess)
  local f = Util.frontier(sess)
  local tent = D.tentPack(F.FACTORY)
  local mons = tent.mons
  local species, monIds, items = {}, {}, {}
  local curSpecies = 0
  local i = 0
  local Rng = D.rng()
  while i ~= 6 do
    local id = Rng.Random() % D.NUM_SLATEPORT_TENT_MONS
    local ok = true
    for j = 1, i do
      if monIds[j] == id then ok = false break end
      if species[j] == mons[id].species then
        if curSpecies == 0 then curSpecies = mons[id].species else ok = false break end
      end
    end
    if ok then
      local item = D.heldItem(mons[id].itemTableId)
      for j = 1, i do
        if items[j] ~= 0 and items[j] == item then
          if mons[id].species == curSpecies then curSpecies = 0 end
          ok = false
          break
        end
      end
      if ok then
        f.rentalMons[i + 1] = { monId = id, ivs = 0, personality = 0, abilityNum = 0 }
        species[i + 1] = mons[id].species
        items[i + 1] = item
        monIds[i + 1] = id
        i = i + 1
      end
    end
  end
end

-- pokeemerald/src/battle_tent.c:350
function Tents.generateOpponentMons(sess)
  local f = Util.frontier(sess)
  local tent = D.tentPack(F.FACTORY)
  local Rng = D.rng()
  local n = tonumber(f.curChallengeBattleNum) or 0
  local tid, monSet
  while true do
    repeat
      tid = Rng.Random() % D.NUM_BATTLE_TENT_TRAINERS
      local dup = false
      for i = 1, n do
        if tonumber(f.trainerIds[i]) == tid then dup = true break end
      end
    until not dup
    monSet = tent.trainers[tid].monSet
    if #monSet > 8 then break end
  end
  sess.frontierOpponentA = tid
  if n < D.TENT_STAGES_PER_CHALLENGE - 1 then f.trainerIds[n + 1] = tid end
  local temp, species, items = {}, {}, {}
  local i = 0
  while i ~= D.PARTY_SIZE do
    local id = monSet[(Rng.Random() % #monSet) + 1]
    local row = tent.mons[id]
    local ok = true
    for j = 1, 6 do
      local r = f.rentalMons[j]
      if r and r.monId and tent.mons[r.monId].species == row.species then ok = false break end
    end
    if ok then
      for k = 1, i do if species[k] == row.species then ok = false break end end
    end
    local item = D.heldItem(row.itemTableId)
    if ok then
      for k = 1, i do if items[k] ~= 0 and items[k] == item then ok = false break end end
    end
    if ok then
      species[i + 1] = row.species
      items[i + 1] = item
      temp[i + 1] = id
      i = i + 1
    end
  end
  sess.frontierTempParty = temp
end

-- pokeemerald/src/battle_tower.c:1887
function Tents.factoryTentParty(sess)
  local tent = D.tentPack(F.FACTORY)
  local otId = math.floor(tonumber(sess.trainerId or sess.playerId) or 0) + math.floor(tonumber(sess.secretId) or 0) * 65536
  local out = {}
  for i = 1, D.PARTY_SIZE do
    local id = sess.frontierTempParty and sess.frontierTempParty[i]
    local row = tent.mons[id]
    local mon = D.createMonEvSpread(row.species, D.TENT_MIN_LEVEL, row.nature, 0, row.evSpread, otId)
    D.setMoves(mon, row.moves)
    mon.friendship, mon.happiness = 0, 0
    D.setHeldItem(mon, D.heldItem(row.itemTableId))
    out[i] = mon
  end
  return out
end

-- pokeemerald/src/battle_factory.c:759
function Tents.rentalMon(sess, index)
  local f = Util.frontier(sess)
  local tent = D.tentPack(F.FACTORY)
  local r = f.rentalMons[index]
  local row = tent.mons[r.monId]
  local otId = math.floor(tonumber(sess.trainerId or sess.playerId) or 0) + math.floor(tonumber(sess.secretId) or 0) * 65536
  local mon = D.createMonEvSpread(row.species, D.TENT_MIN_LEVEL, row.nature, tonumber(r.ivs) or 0, row.evSpread, otId)
  D.setMoves(mon, row.moves)
  mon.friendship, mon.happiness = 0, 0
  D.setHeldItem(mon, D.heldItem(row.itemTableId))
  return mon
end

Rse.register("tents", Tents)

return Tents
