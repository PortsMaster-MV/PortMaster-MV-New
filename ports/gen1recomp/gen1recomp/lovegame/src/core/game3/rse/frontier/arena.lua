local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")
local Data = require("src.core.game3.rse.frontier.f2_data")

local bit = rawget(_G, "bit") or require("bit")

local Arena = {}

-- pokeemerald/include/constants/battle_arena.h:4
Arena.FUNC = { INIT = 0, GET_DATA = 1, SET_DATA = 2, SAVE = 3, SET_PRIZE = 4, GIVE_PRIZE = 5, GET_TRAINER_NAME = 6 }
-- pokeemerald/include/constants/battle_arena.h:12
Arena.DATA = { PRIZE = 0, WIN_STREAK = 1, WIN_STREAK_ACTIVE = 2 }

local function lvl(sess)
  return tonumber(Util.frontier(sess).lvlMode) or 0
end

local function streakFlag(sess)
  return lvl(sess) ~= D.LVL.L50 and Util.STREAK.ARENA_OPEN or Util.STREAK.ARENA_50
end

local function u32(v)
  if v < 0 then v = v + 4294967296 end
  return v
end

-- pokeemerald/src/battle_arena.c:655
function Arena.init(sess)
  local f = Util.frontier(sess)
  f.challengeStatus = 0
  f.curChallengeBattleNum = 0
  f.challengePaused = 0
  f.disableRecordBattle = 0
  if bit.band(tonumber(f.winStreakActiveFlags) or 0, streakFlag(sess)) == 0 then
    Util.set1(f.arenaWinStreaks, lvl(sess), 0)
  end
  sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = sess.x, y = sess.y }
  sess.frontierOpponentA = 0
end

-- pokeemerald/src/battle_arena.c:677
function Arena.getData(ctx, sess)
  local f = Util.frontier(sess)
  local which = Rse.specialVar(ctx, Util.VAR_0x8005)
  if which == Arena.DATA.PRIZE then
    Util.setResult(ctx, tonumber(f.arenaPrize) or 0)
  elseif which == Arena.DATA.WIN_STREAK then
    Util.setResult(ctx, Util.get1(f.arenaWinStreaks, lvl(sess)))
  elseif which == Arena.DATA.WIN_STREAK_ACTIVE then
    Util.setResult(ctx, bit.band(tonumber(f.winStreakActiveFlags) or 0, streakFlag(sess)))
  end
end

-- pokeemerald/src/battle_arena.c:698
function Arena.setData(ctx, sess)
  local f = Util.frontier(sess)
  local which = Rse.specialVar(ctx, Util.VAR_0x8005)
  local v = Rse.specialVar(ctx, Util.VAR_0x8006)
  if which == Arena.DATA.PRIZE then
    f.arenaPrize = v
  elseif which == Arena.DATA.WIN_STREAK then
    Util.set1(f.arenaWinStreaks, lvl(sess), v)
  elseif which == Arena.DATA.WIN_STREAK_ACTIVE then
    local flags = tonumber(f.winStreakActiveFlags) or 0
    if v ~= 0 then
      f.winStreakActiveFlags = u32(bit.bor(flags, streakFlag(sess)))
    else
      f.winStreakActiveFlags = u32(bit.band(flags, bit.bnot(streakFlag(sess))))
    end
  end
end

-- pokeemerald/src/battle_arena.c:731
function Arena.save(ctx, sess)
  local f = Util.frontier(sess)
  return Util.saveChallenge(sess, "VAR_TEMP_CHALLENGE_STATUS", function()
    f.challengeStatus = Rse.specialVar(ctx, Util.VAR_0x8005)
    Rse.setVar("VAR_TEMP_CHALLENGE_STATUS", 0, sess)
    f.challengePaused = 1
  end)
end

-- pokeemerald/src/battle_arena.c:739
function Arena.setPrize(sess)
  local f = Util.frontier(sess)
  local A = Data.arena()
  local list = Util.get1(f.arenaWinStreaks, lvl(sess)) > 41 and A.longPrizes or A.shortPrizes
  f.arenaPrize = list[(D.rng().Random() % #list) + 1]
end

-- pokeemerald/src/battle_arena.c:749
function Arena.givePrize(ctx, adapters, sess)
  local f = Util.frontier(sess)
  local item = tonumber(f.arenaPrize) or 0
  local Bag = require("src.core.game3.bag")
  if item ~= 0 and Bag.add(sess.bag, item, 1) then
    Util.setStringVar(ctx, adapters, 1, require("src.core.game3.items_data").displayName(item) or "")
    f.arenaPrize = 0
    Util.setResult(ctx, 1)
  else
    Util.setResult(ctx, 0)
  end
end

-- pokeemerald/src/battle_arena.c:763
function Arena.bufferOpponentName(ctx, adapters, sess)
  Util.setStringVar(ctx, adapters, 1, D.trainerName(sess, tonumber(sess.frontierOpponentA) or 0, D.FACILITY.ARENA))
end

-- pokeemerald/src/battle_tower.c:2083
function Arena.doSpecialBattle(ctx, adapters, sess)
  local f = Util.frontier(sess)
  local tid = tonumber(sess.frontierOpponentA) or 0
  local party = {}
  if f.lvlMode == D.LVL.TENT then
    D.fillTentTrainerParty(sess, tid, 0, D.PARTY_SIZE, party, D.FACILITY.ARENA)
  else
    D.fillTrainerParty(sess, tid, 0, D.PARTY_SIZE, party)
  end
  local Fac = require("src.core.game3.battle.facility_arena")
  return require("src.core.game3.rse.frontier.palace").startFacilityBattle(ctx, adapters, sess, "arena", Fac.new(), {
    party = party,
    double = false,
    transitionId = D.specialTransition(sess, "B_ARENA", party),
  })
end

Rse.register("arena", Arena)

return Arena
