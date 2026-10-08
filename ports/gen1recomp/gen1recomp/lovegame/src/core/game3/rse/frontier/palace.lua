local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")
local Data = require("src.core.game3.rse.frontier.f2_data")

local bit = rawget(_G, "bit") or require("bit")

local Palace = {}

-- pokeemerald/include/constants/battle_palace.h:4
Palace.FUNC = {
  INIT = 0, GET_DATA = 1, SET_DATA = 2, GET_COMMENT_ID = 3, SET_OPPONENT = 4, GET_OPPONENT_INTRO = 5,
  INCREMENT_STREAK = 6, SAVE = 7, SET_PRIZE = 8, GIVE_PRIZE = 9,
}
-- pokeemerald/include/constants/battle_palace.h:15
Palace.DATA = { PRIZE = 0, WIN_STREAK = 1, WIN_STREAK_ACTIVE = 2 }

local S = Util.STREAK
-- pokeemerald/src/battle_palace.c:67
Palace.WIN_STREAK_FLAGS = {
  { S.PALACE_SINGLES_50, S.PALACE_SINGLES_OPEN },
  { S.PALACE_DOUBLES_50, S.PALACE_DOUBLES_OPEN },
}

local function modeLvl(sess)
  local f = Util.frontier(sess)
  return Rse.var("VAR_FRONTIER_BATTLE_MODE", sess), tonumber(f.lvlMode) or 0
end

local function streakFlag(mode, lvl)
  local row = Palace.WIN_STREAK_FLAGS[mode + 1] or Palace.WIN_STREAK_FLAGS[1]
  return row[lvl + 1] or 0
end

local function u32(v)
  if v < 0 then v = v + 4294967296 end
  return v
end

-- pokeemerald/src/battle_palace.c:84
function Palace.init(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  f.challengeStatus = 0
  f.curChallengeBattleNum = 0
  f.challengePaused = 0
  f.disableRecordBattle = 0
  if bit.band(tonumber(f.winStreakActiveFlags) or 0, streakFlag(mode, lvl)) == 0 then
    Util.set2(f.palaceWinStreaks, mode, lvl, 0)
  end
  sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = sess.x, y = sess.y }
  sess.frontierOpponentA = 0
end

-- pokeemerald/src/battle_palace.c:100
function Palace.getData(ctx, sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local which = Rse.specialVar(ctx, Util.VAR_0x8005)
  if which == Palace.DATA.PRIZE then
    Util.setResult(ctx, tonumber(f.palacePrize) or 0)
  elseif which == Palace.DATA.WIN_STREAK then
    Util.setResult(ctx, Util.get2(f.palaceWinStreaks, mode, lvl))
  elseif which == Palace.DATA.WIN_STREAK_ACTIVE then
    Util.setResult(ctx, bit.band(tonumber(f.winStreakActiveFlags) or 0, streakFlag(mode, lvl)) ~= 0 and 1 or 0)
  end
end

-- pokeemerald/src/battle_palace.c:119
function Palace.setData(ctx, sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local which = Rse.specialVar(ctx, Util.VAR_0x8005)
  local v = Rse.specialVar(ctx, Util.VAR_0x8006)
  if which == Palace.DATA.PRIZE then
    f.palacePrize = v
  elseif which == Palace.DATA.WIN_STREAK then
    Util.set2(f.palaceWinStreaks, mode, lvl, v)
  elseif which == Palace.DATA.WIN_STREAK_ACTIVE then
    local flags = tonumber(f.winStreakActiveFlags) or 0
    if v ~= 0 then
      f.winStreakActiveFlags = u32(bit.bor(flags, streakFlag(mode, lvl)))
    else
      f.winStreakActiveFlags = u32(bit.band(flags, bit.bnot(streakFlag(mode, lvl))))
    end
  end
end

-- pokeemerald/src/battle_palace.c:143
function Palace.commentId(ctx, sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local ws = Util.get2(f.palaceWinStreaks, mode, lvl)
  local r
  if ws < 50 then r = D.rng().Random() % 3
  elseif ws < 99 then r = 3
  else r = 4 end
  Util.setResult(ctx, r)
  return r
end

-- pokeemerald/src/battle_palace.c:156
function Palace.setOpponent(sess)
  sess.frontierOpponentA = math.floor(5 * (D.rng().Random() % 255) / 64)
  D.setGfxVar(sess, sess.frontierOpponentA, 0, D.FACILITY.PALACE)
end

-- pokeemerald/src/battle_palace.c:162
function Palace.opponentIntro(ctx, adapters, sess)
  local tid = tonumber(sess.frontierOpponentA) or 0
  if tid < D.TRAINERS_COUNT then
    Util.setStringVar(ctx, adapters, 4, D.trainerSpeech(sess, tid, 0, D.FACILITY.PALACE))
  end
end

-- pokeemerald/src/battle_palace.c:168
function Palace.incrementStreak(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local ws = Util.get2(f.palaceWinStreaks, mode, lvl)
  if ws < D.MAX_STREAK then
    ws = ws + 1
    Util.set2(f.palaceWinStreaks, mode, lvl, ws)
    local col = (lvl > Util.get2(f.palaceRecordWinStreaks, mode, lvl)) and 1 or 0
    if Util.get2(f.palaceWinStreaks, mode, col) ~= 0 then
      Util.set2(f.palaceRecordWinStreaks, mode, lvl, ws)
    end
  end
end

-- pokeemerald/src/battle_palace.c:182
function Palace.save(ctx, sess)
  local f = Util.frontier(sess)
  return Util.saveChallenge(sess, "VAR_TEMP_CHALLENGE_STATUS", function()
    f.challengeStatus = Rse.specialVar(ctx, Util.VAR_0x8005)
    Rse.setVar("VAR_TEMP_CHALLENGE_STATUS", 0, sess)
    f.challengePaused = 1
  end)
end

-- pokeemerald/src/battle_palace.c:190
function Palace.setPrize(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local P = Data.palace()
  local list = Util.get2(f.palaceWinStreaks, mode, lvl) > 41 and P.latePrizes or P.earlyPrizes
  f.palacePrize = list[(D.rng().Random() % #list) + 1]
end

-- pokeemerald/src/battle_palace.c:201
function Palace.givePrize(ctx, adapters, sess)
  local f = Util.frontier(sess)
  local item = tonumber(f.palacePrize) or 0
  local Bag = require("src.core.game3.bag")
  if item ~= 0 and Bag.add(sess.bag, item, 1) then
    Util.setStringVar(ctx, adapters, 1, require("src.core.game3.items_data").displayName(item) or "")
    f.palacePrize = 0
    Util.setResult(ctx, 1)
  else
    Util.setResult(ctx, 0)
  end
end

-- pokeemerald/src/battle_tower.c:2071
function Palace.doSpecialBattle(ctx, adapters, sess)
  local f = Util.frontier(sess)
  local tid = tonumber(sess.frontierOpponentA) or 0
  local mode = Rse.var("VAR_FRONTIER_BATTLE_MODE", sess)
  local party = {}
  if f.lvlMode == D.LVL.TENT then
    D.fillTentTrainerParty(sess, tid, 0, D.PARTY_SIZE, party, D.FACILITY.PALACE)
  else
    D.fillTrainerParty(sess, tid, 0, D.PARTY_SIZE, party)
  end
  local Fac = require("src.core.game3.battle.facility_palace")
  return Palace.startFacilityBattle(ctx, adapters, sess, "palace", Fac.new(), {
    party = party,
    double = mode == D.MODE.DOUBLES,
    transitionId = D.specialTransition(sess, "B_PALACE", party),
  })
end

-- pokeemerald/src/battle_tower.c:2007
function Palace.startFacilityBattle(ctx, adapters, sess, kind, facility, opts)
  local Battle = require("src.core.game3.battle")
  local Tower = require("src.core.game3.rse.frontier.tower")
  Battle._nextFacility = facility
  local r = Tower.startBattle(ctx, adapters, sess, kind, opts)
  if not r and Battle._nextFacility == facility then Battle._nextFacility = nil end
  return r
end

Rse.register("palace", Palace)

return Palace
