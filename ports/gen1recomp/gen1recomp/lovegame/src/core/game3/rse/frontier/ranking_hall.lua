local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")
local MixUtil = require("src.core.game3.rse.record_mix_util")

local Hall = {}

local RH = Util.RANKING_HALL
local M = D.MODE
local COUNT = Util.HALL_RECORDS_COUNT

local function lvlModes()
  return D.LVL_MODE_COUNT
end

local function new1P()
  return { id = { 0, 0, 0, 0 }, name = "", language = 0, winStreak = 0 }
end

local function new2P()
  return { id1 = { 0, 0, 0, 0 }, id2 = { 0, 0, 0, 0 }, name1 = "", name2 = "", language = 0, winStreak = 0 }
end

function Hall.saved(sess)
  sess = sess or Rse.session()
  if type(sess.hallRecords1P) ~= "table" or type(sess.hallRecords2P) ~= "table" then
    Util.clearRankingHallRecords(sess)
  end
  for i = 1, Util.HALL_FACILITIES_COUNT do
    sess.hallRecords1P[i] = sess.hallRecords1P[i] or {}
    for j = 1, lvlModes() do
      sess.hallRecords1P[i][j] = sess.hallRecords1P[i][j] or {}
      for k = 1, COUNT do sess.hallRecords1P[i][j][k] = sess.hallRecords1P[i][j][k] or new1P() end
    end
  end
  for j = 1, lvlModes() do
    sess.hallRecords2P[j] = sess.hallRecords2P[j] or {}
    for k = 1, COUNT do sess.hallRecords2P[j][k] = sess.hallRecords2P[j][k] or new2P() end
  end
  return sess.hallRecords1P, sess.hallRecords2P
end

local function streak(r)
  return tonumber(type(r) == "table" and r.winStreak) or 0
end

-- pokeemerald/src/record_mixing.c:1116
function Hall.mixExport(sess)
  sess = sess or Rse.session()
  local f = Util.frontier(sess)
  local id = MixUtil.trainerIdBytes(sess)
  local name = tostring(sess.name or sess.playerName or "")
  local out = { onePlayer = {}, twoPlayers = {} }
  for i = 1, Util.HALL_FACILITIES_COUNT do
    out.onePlayer[i] = {}
    for j = 1, lvlModes() do
      out.onePlayer[i][j] = { id = MixUtil.deep(id), language = MixUtil.GAME_LANGUAGE, name = name, winStreak = 0 }
    end
  end
  for j = 1, lvlModes() do
    out.twoPlayers[j] = {
      language = MixUtil.GAME_LANGUAGE, id1 = MixUtil.deep(id),
      id2 = MixUtil.deep(f.opponentTrainerIds and f.opponentTrainerIds[j] or { 0, 0, 0, 0 }),
      name1 = name, name2 = tostring(f.opponentNames and f.opponentNames[j] or ""), winStreak = 0,
    }
  end
  for lvl = 0, lvlModes() - 1 do
    local one = function(hall) return out.onePlayer[hall + 1][lvl + 1] end
    one(RH.TOWER_SINGLES).winStreak = Util.get2(f.towerRecordWinStreaks, M.SINGLES, lvl)
    one(RH.TOWER_DOUBLES).winStreak = Util.get2(f.towerRecordWinStreaks, M.DOUBLES, lvl)
    one(RH.TOWER_MULTIS).winStreak = Util.get2(f.towerRecordWinStreaks, M.MULTIS, lvl)
    one(RH.DOME).winStreak = Util.get2(f.domeRecordWinStreaks, M.SINGLES, lvl)
    one(RH.PALACE).winStreak = Util.get2(f.palaceRecordWinStreaks, M.SINGLES, lvl)
    one(RH.ARENA).winStreak = Util.get1(f.arenaRecordStreaks, lvl)
    one(RH.FACTORY).winStreak = Util.get2(f.factoryRecordWinStreaks, M.SINGLES, lvl)
    one(RH.PIKE).winStreak = Util.get1(f.pikeRecordStreaks, lvl)
    one(RH.PYRAMID).winStreak = Util.get1(f.pyramidRecordStreaks, lvl)
    out.twoPlayers[lvl + 1].winStreak = Util.get2(f.towerRecordWinStreaks, M.LINK_MULTIS, lvl)
  end
  return out
end

local function tid(bytes)
  return MixUtil.getTrainerId(bytes)
end

-- pokeemerald/src/record_mixing.c:1207
local function getNewHallRecords(players, myIndex, sess)
  local saved1, saved2 = Hall.saved(sess)
  local partners = {}
  for i = 1, #players do
    if i ~= myIndex then
      local h = players[i] and players[i].hallRecords
      partners[#partners + 1] = type(h) == "table" and h or {}
    end
    if #partners == COUNT then break end
  end
  local n = #players - 1
  local mix1, mix2 = {}, {}
  for i = 1, Util.HALL_FACILITIES_COUNT do
    mix1[i] = {}
    for j = 1, lvlModes() do
      local dst = {}
      for k = 1, COUNT * 2 do dst[k] = new1P() end
      for k = 1, COUNT do dst[k] = MixUtil.deep(saved1[i][j][k]) end
      for k = 1, n do
        local rec = partners[k] and partners[k].onePlayer and partners[k].onePlayer[i] and partners[k].onePlayer[i][j]
        rec = type(rec) == "table" and rec or new1P()
        local repeats = 0
        for l = 1, COUNT do
          if tid(dst[l].id) == tid(rec.id) then
            repeats = repeats + 1
            if streak(dst[l]) < streak(rec) then dst[l] = MixUtil.deep(rec) end
          end
        end
        if repeats == 0 then dst[k + COUNT] = MixUtil.deep(rec) end
      end
      mix1[i][j] = dst
    end
  end
  for j = 1, lvlModes() do
    local dst = {}
    for k = 1, COUNT * 2 do dst[k] = new2P() end
    for k = 1, COUNT do dst[k] = MixUtil.deep(saved2[j][k]) end
    for k = 1, n do
      local rec = partners[k] and partners[k].twoPlayers and partners[k].twoPlayers[j]
      rec = type(rec) == "table" and rec or new2P()
      local repeats = 0
      for l = 1, COUNT do
        if tid(dst[l].id1) == tid(rec.id1) and tid(dst[l].id2) == tid(rec.id2) then
          repeats = repeats + 1
          if streak(dst[l]) < streak(rec) then dst[l] = MixUtil.deep(rec) end
        end
      end
      if repeats == 0 then dst[k + COUNT] = MixUtil.deep(rec) end
    end
    mix2[j] = dst
  end
  return mix1, mix2
end

-- pokeemerald/src/record_mixing.c:1286
local function fillWinStreakRecords(playerRecords, mixRecords)
  for i = 1, COUNT do
    local highest, highestId = 0, nil
    for j = 1, COUNT * 2 do
      if streak(mixRecords[j]) > highest then
        highestId, highest = j, streak(mixRecords[j])
      end
    end
    if highestId then
      playerRecords[i] = MixUtil.deep(mixRecords[highestId])
      mixRecords[highestId].winStreak = 0
    end
  end
end

-- pokeemerald/src/record_mixing.c:1355
function Hall.mixImport(players, sess, myIndex)
  sess = sess or Rse.session()
  players = players or {}
  local mix1, mix2 = getNewHallRecords(players, tonumber(myIndex) or 1, sess)
  -- pokeemerald/src/record_mixing.c:1342
  local saved1, saved2 = Hall.saved(sess)
  for i = 1, Util.HALL_FACILITIES_COUNT do
    for j = 1, lvlModes() do fillWinStreakRecords(saved1[i][j], mix1[i][j]) end
  end
  for j = 1, lvlModes() do fillWinStreakRecords(saved2[j], mix2[j]) end
  return true
end

Rse.register("rankingHall", Hall)

return Hall
