local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")

local bit = rawget(_G, "bit") or require("bit")

local Util = {}

Util.D = D

-- pokeemerald/include/constants/vars.h:287
Util.VAR_0x8004, Util.VAR_0x8005, Util.VAR_0x8006 = 0x8004, 0x8005, 0x8006
Util.VAR_RESULT = 0x800D
Util.VAR_LAST_TALKED = 0x800F

-- pokeemerald/include/constants/frontier_util.h:15
Util.FUNC = {
  GET_STATUS = 0, GET_DATA = 1, SET_DATA = 2, SET_PARTY_ORDER = 3, SOFT_RESET = 4, SET_TRAINERS = 5,
  SAVE_PARTY = 6, RESULTS_WINDOW = 7, CHECK_AIR_TV_SHOW = 8, GET_BRAIN_STATUS = 9, IS_BRAIN = 10,
  GIVE_BATTLE_POINTS = 11, GET_FACILITY_SYMBOLS = 12, GIVE_FACILITY_SYMBOL = 13, CHECK_BATTLE_TYPE = 14,
  CHECK_INELIGIBLE = 15, CHECK_VISIT_TRAINER = 16, INCREMENT_STREAK = 17, RESTORE_HELD_ITEMS = 18,
  SAVE_BATTLE = 19, BUFFER_TRAINER_NAME = 20, RESET_SKETCH_MOVES = 21, SET_BRAIN_OBJECT = 22,
}
-- pokeemerald/include/constants/frontier_util.h:40
Util.DATA = {
  CHALLENGE_STATUS = 0, LVL_MODE = 1, BATTLE_NUM = 2, PAUSED = 3, SELECTED_MON_ORDER = 4,
  BATTLE_OUTCOME = 5, RECORD_DISABLED = 6, HEARD_BRAIN_SPEECH = 7,
}
-- pokeemerald/include/constants/frontier_util.h:8
Util.BRAIN = { NOT_READY = 0, SILVER = 1, GOLD = 2, STREAK = 3, STREAK_LONG = 4 }
-- pokeemerald/include/constants/battle_frontier.h:30
Util.CHALLENGE_STATUS = { SAVING = 1, PAUSED = 2, WON = 3, LOST = 4 }
-- pokeemerald/include/constants/frontier_util.h:49
Util.STREAK = {
  TOWER_SINGLES_50 = 0x1, TOWER_SINGLES_OPEN = 0x2, DOME_SINGLES_50 = 0x4, DOME_SINGLES_OPEN = 0x8,
  PALACE_SINGLES_50 = 0x10, PALACE_SINGLES_OPEN = 0x20, ARENA_50 = 0x40, ARENA_OPEN = 0x80,
  FACTORY_SINGLES_50 = 0x100, FACTORY_SINGLES_OPEN = 0x200, PIKE_50 = 0x400, PIKE_OPEN = 0x800,
  PYRAMID_50 = 0x1000, PYRAMID_OPEN = 0x2000, TOWER_DOUBLES_50 = 0x4000, TOWER_DOUBLES_OPEN = 0x8000,
  TOWER_MULTIS_50 = 0x10000, TOWER_MULTIS_OPEN = 0x20000, TOWER_LINK_MULTIS_50 = 0x40000,
  TOWER_LINK_MULTIS_OPEN = 0x80000, DOME_DOUBLES_50 = 0x100000, DOME_DOUBLES_OPEN = 0x200000,
  PALACE_DOUBLES_50 = 0x400000, PALACE_DOUBLES_OPEN = 0x800000, FACTORY_DOUBLES_50 = 0x1000000,
  FACTORY_DOUBLES_OPEN = 0x2000000,
}
-- pokeemerald/include/constants/battle_frontier.h:66
Util.RANKING_HALL = {
  TOWER_SINGLES = 0, TOWER_DOUBLES = 1, TOWER_MULTIS = 2, DOME = 3, PALACE = 4, ARENA = 5, FACTORY = 6,
  PIKE = 7, PYRAMID = 8, TOWER_LINK = 9,
}
Util.HALL_FACILITIES_COUNT = 9
-- pokeemerald/include/constants/global.h:73
Util.HALL_RECORDS_COUNT = 3
-- pokeemerald/include/constants/battle_frontier.h:12
Util.FACILITY_LINK_CONTEST = 7
-- pokeemerald/include/constants/battle_frontier.h:94
Util.SHOW = {
  TOWER_SINGLES = 1, TOWER_DOUBLES = 2, TOWER_MULTIS = 3, TOWER_LINK_MULTIS = 4, DOME_SINGLES = 5,
  DOME_DOUBLES = 6, FACTORY_SINGLES = 7, FACTORY_DOUBLES = 8, PIKE = 9, ARENA = 10, PALACE_SINGLES = 11,
  PALACE_DOUBLES = 12, PYRAMID = 13,
}
-- pokeemerald/include/constants/battle_frontier.h:109
Util.GAMBLER = { WAITING = 0, PLACED_BET = 1, WON = 2, LOST = 3 }
-- pokeemerald/include/constants/battle_pike.h:4
Util.NUM_PIKE_ROOMS = 14
-- pokeemerald/include/constants/game_stat.h:36
Util.GAME_STAT_BATTLE_TOWER_SINGLES_STREAK = 32
Util.GAME_STAT_RECEIVED_RIBBONS = 42
-- pokeemerald/include/constants/global.h:65
Util.BATTLE_TOWER_RECORD_COUNT = 5
-- pokeemerald/include/constants/global.h:59
Util.APPRENTICE_COUNT = 4
-- pokeemerald/include/constants/battle.h:113
Util.B_OUTCOME_WON = 1

-- pokeemerald/src/string_util.c:6
Util.STRING_VAR_ADDR = { 0x02021cc4, 0x02021dc4, 0x02021ec4, 0x02021fc4 }

local F = D.FACILITY
local M = D.MODE
local LVL = D.LVL

local function zeros(n, v)
  local t = {}
  for i = 1, n do t[i] = v or 0 end
  return t
end

local function grid(a, b)
  local t = {}
  for i = 1, a do t[i] = zeros(b) end
  return t
end

-- pokeemerald/include/global.h:378
function Util.newFrontier()
  return {
    towerPlayer = {},
    towerRecords = { {}, {}, {}, {}, {} },
    towerInterview = { opponentName = "", opponentMonNickname = "", opponentSpecies = 0, playerSpecies = 0,
      opponentLanguage = 0 },
    ereaderTrainer = {},
    challengeStatus = 0,
    lvlMode = 0,
    challengePaused = 0,
    disableRecordBattle = 0,
    selectedPartyMons = zeros(D.MAX_PARTY_SIZE),
    curChallengeBattleNum = 0,
    trainerIds = zeros(20, 0xFFFF),
    winStreakActiveFlags = 0,
    towerWinStreaks = grid(4, 2),
    towerRecordWinStreaks = grid(4, 2),
    battledBrainFlags = 0,
    towerSinglesStreak = 0,
    towerNumWins = 0,
    towerBattleOutcome = 0,
    towerLvlMode = 0,
    domeWinStreaks = grid(2, 2),
    domeRecordWinStreaks = grid(2, 2),
    domeTotalChampionships = grid(2, 2),
    palacePrize = 0,
    palaceWinStreaks = grid(2, 2),
    palaceRecordWinStreaks = grid(2, 2),
    arenaPrize = 0,
    arenaWinStreaks = zeros(2),
    arenaRecordStreaks = zeros(2),
    factoryWinStreaks = grid(2, 2),
    factoryRecordWinStreaks = grid(2, 2),
    factoryRentsCount = grid(2, 2),
    factoryRecordRentsCount = grid(2, 2),
    pikePrize = 0,
    pikeWinStreaks = zeros(2),
    pikeRecordStreaks = zeros(2),
    pikeTotalStreaks = zeros(2),
    pyramidPrize = 0,
    pyramidWinStreaks = zeros(2),
    pyramidRecordStreaks = zeros(2),
    verdanturfTentPrize = 0,
    fallarborTentPrize = 0,
    slateportTentPrize = 0,
    rentalMons = { {}, {}, {}, {}, {}, {} },
    battlePoints = 0,
    cardBattlePoints = 0,
    battlesCount = 0,
    opponentNames = { "", "" },
    opponentTrainerIds = { zeros(4), zeros(4) },
    savedGame = 0,
  }
end

local function fill(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then
      dst[k] = v
    elseif type(v) == "table" and type(dst[k]) == "table" then
      fill(dst[k], v)
    end
  end
  return dst
end

function Util.frontier(sess)
  sess = sess or Rse.session()
  if type(sess.frontier) ~= "table" then sess.frontier = {} end
  local f = sess.frontier
  if not f._shaped then
    fill(f, Util.newFrontier())
    f._shaped = true
  end
  return f
end

-- pokeemerald/include/global.h:488
local function newHall1P()
  return { id = zeros(4), name = "", language = 0, winStreak = 0 }
end

-- pokeemerald/src/frontier_util.c:2383
function Util.clearRankingHallRecords(sess)
  sess.hallRecords1P = {}
  for i = 1, Util.HALL_FACILITIES_COUNT do
    sess.hallRecords1P[i] = {}
    for j = 1, D.LVL_MODE_COUNT do
      local list = {}
      for k = 1, Util.HALL_RECORDS_COUNT do list[k] = newHall1P() end
      sess.hallRecords1P[i][j] = list
    end
  end
  sess.hallRecords2P = {}
  for j = 1, D.LVL_MODE_COUNT do
    local list = {}
    for k = 1, Util.HALL_RECORDS_COUNT do
      list[k] = { id1 = zeros(4), id2 = zeros(4), name1 = "", name2 = "", language = 0, winStreak = 0 }
    end
    sess.hallRecords2P[j] = list
  end
end

-- pokeemerald/src/new_game.c:121
function Util.newGame(sess)
  sess.frontier = Util.newFrontier()
  sess.frontier._shaped = true
  Util.clearRankingHallRecords(sess)
end

Util.SAVE_FIELDS = { "frontier", "hallRecords1P", "hallRecords2P", "savedPlayerParty" }

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  SaveSections.register("frontier", SaveSections.fields(Util.SAVE_FIELDS, function(session)
    Util.newGame(session)
  end))
end

local function var(name, sess) return Rse.var(name, sess) end
local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end
local function setSpecialVar(ctx, id, v) Rse.setSpecialVar(ctx, id, v) end
local function setResult(ctx, v) setSpecialVar(ctx, Util.VAR_RESULT, v) end
Util.setResult = setResult

local function modeLvl(sess)
  local f = Util.frontier(sess)
  return var("VAR_FRONTIER_BATTLE_MODE", sess), f.lvlMode
end

function Util.get2(t, a, b)
  local row = t and t[a + 1]
  return row and tonumber(row[b + 1]) or 0
end

function Util.set2(t, a, b, v)
  t[a + 1] = t[a + 1] or {}
  t[a + 1][b + 1] = v
end

function Util.get1(t, a)
  return t and tonumber(t[a + 1]) or 0
end

function Util.set1(t, a, v)
  t[a + 1] = v
end

-- pokeemerald/src/frontier_util.c:1847
function Util.symbolCount(sess, facility)
  local silver = Rse.flagId("FLAG_SYS_TOWER_SILVER", sess)
  local gold = Rse.flagId("FLAG_SYS_TOWER_GOLD", sess)
  local Flags = require("src.core.game3.scripting.flags")
  local store = Rse.store()
  local n = 0
  if Flags.getFlag(store, nil, silver + facility * 2) == true then n = n + 1 end
  if Flags.getFlag(store, nil, gold + facility * 2) == true then n = n + 1 end
  return n
end

-- pokeemerald/src/frontier_util.c:1918
function Util.giveSymbol(sess, facility)
  local name = Util.symbolCount(sess, facility) == 0 and "FLAG_SYS_TOWER_SILVER" or "FLAG_SYS_TOWER_GOLD"
  local id = Rse.flagId(name, sess) + facility * 2
  require("src.core.game3.scripting.flags").setFlag(Rse.store(), nil, id, true)
end

-- pokeemerald/src/frontier_util.c:1804
function Util.currentFacilityWinStreak(sess)
  local f = Util.frontier(sess)
  local mode = var("VAR_FRONTIER_BATTLE_MODE", sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local lvl = f.lvlMode
  if facility == F.TOWER then return Util.get2(f.towerWinStreaks, mode, lvl) end
  if facility == F.DOME then return Util.get2(f.domeWinStreaks, mode, lvl) end
  if facility == F.PALACE then return Util.get2(f.palaceWinStreaks, mode, lvl) end
  if facility == F.ARENA then return Util.get1(f.arenaWinStreaks, lvl) end
  if facility == F.FACTORY then return Util.get2(f.factoryWinStreaks, mode, lvl) end
  if facility == F.PIKE then return Util.get1(f.pikeWinStreaks, lvl) end
  if facility == F.PYRAMID then return Util.get1(f.pyramidWinStreaks, lvl) end
  return 0
end

-- pokeemerald/src/frontier_util.c:1656
function Util.brainStatus(sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local mode = var("VAR_FRONTIER_BATTLE_MODE", sess)
  local ap = D.manifest().brainStreakAppearances[facility + 1]
  if not ap then return Util.BRAIN.NOT_READY end
  local streak = Util.currentFacilityWinStreak(sess) + ap[4]
  if mode ~= M.SINGLES then return Util.BRAIN.NOT_READY end
  local symbols = Util.symbolCount(sess, facility)
  if symbols == 0 or symbols == 1 then
    if streak == ap[symbols + 1] then return symbols + 1 end
    return Util.BRAIN.NOT_READY
  end
  if streak == ap[1] then return Util.BRAIN.STREAK end
  if streak == ap[2] then return Util.BRAIN.STREAK_LONG end
  if streak > ap[2] and (streak - ap[2]) % ap[3] == 0 then return Util.BRAIN.STREAK_LONG end
  return Util.BRAIN.NOT_READY
end

function Util.isWinStreakActive(sess, flag)
  return bit.band(Util.frontier(sess).winStreakActiveFlags or 0, flag) ~= 0
end

-- pokeemerald/src/frontier_util.c:1776
function Util.resetWinStreaks(sess)
  local f = Util.frontier(sess)
  f.winStreakActiveFlags = 0
  for mode = 0, D.MODE_COUNT - 1 do
    for lvl = 0, D.LVL_MODE_COUNT - 1 do
      Util.set2(f.towerWinStreaks, mode, lvl, 0)
      if mode < M.MULTIS then
        Util.set2(f.domeWinStreaks, mode, lvl, 0)
        Util.set2(f.palaceWinStreaks, mode, lvl, 0)
        Util.set2(f.factoryWinStreaks, mode, lvl, 0)
      end
      if mode == M.SINGLES then
        Util.set1(f.arenaWinStreaks, lvl, 0)
        Util.set1(f.pikeWinStreaks, lvl, 0)
        Util.set1(f.pyramidWinStreaks, lvl, 0)
      end
    end
  end
  if f.challengeStatus ~= 0 then f.challengeStatus = Util.CHALLENGE_STATUS.SAVING end
end

-- pokeemerald/src/frontier_util.c:1831
function Util.resetTrainerIds(sess)
  local f = Util.frontier(sess)
  for i = 1, 20 do f.trainerIds[i] = 0xFFFF end
end

local function gameStat(sess, id, value)
  sess.gameStats = sess.gameStats or {}
  if value ~= nil then sess.gameStats[id] = value end
  return tonumber(sess.gameStats[id]) or 0
end

-- pokeemerald/src/frontier_util.c:2111
function Util.incrementWinStreak(sess)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local function inc2(t)
    local v = Util.get2(t, mode, lvl)
    if v < D.MAX_STREAK then Util.set2(t, mode, lvl, v + 1) return true end
    return false
  end
  local function inc1(t)
    local v = Util.get1(t, lvl)
    if v < D.MAX_STREAK then Util.set1(t, lvl, v + 1) end
  end
  if facility == F.TOWER then
    if inc2(f.towerWinStreaks) and mode == M.SINGLES then
      local v = Util.get2(f.towerWinStreaks, mode, lvl)
      gameStat(sess, Util.GAME_STAT_BATTLE_TOWER_SINGLES_STREAK, v)
      f.towerSinglesStreak = v
    end
  elseif facility == F.DOME then
    inc2(f.domeWinStreaks)
    inc2(f.domeTotalChampionships)
  elseif facility == F.PALACE then
    inc2(f.palaceWinStreaks)
  elseif facility == F.ARENA then
    inc1(f.arenaWinStreaks)
  elseif facility == F.FACTORY then
    inc2(f.factoryWinStreaks)
  elseif facility == F.PIKE then
    inc1(f.pikeWinStreaks)
  elseif facility == F.PYRAMID then
    inc1(f.pyramidWinStreaks)
  end
end

-- pokeemerald/src/frontier_util.c:1853
function Util.giveBattlePoints(sess, isBrain)
  local f = Util.frontier(sess)
  local mode, lvl = modeLvl(sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local stages = D.STAGES_PER_CHALLENGE
  local challengeNum = 0
  if facility == F.TOWER then challengeNum = math.floor(Util.get2(f.towerWinStreaks, mode, lvl) / stages)
  elseif facility == F.DOME then challengeNum = Util.get2(f.domeWinStreaks, mode, lvl)
  elseif facility == F.PALACE then challengeNum = math.floor(Util.get2(f.palaceWinStreaks, mode, lvl) / stages)
  elseif facility == F.ARENA then challengeNum = math.floor(Util.get1(f.arenaWinStreaks, lvl) / stages)
  elseif facility == F.FACTORY then challengeNum = math.floor(Util.get2(f.factoryWinStreaks, mode, lvl) / stages)
  elseif facility == F.PIKE then challengeNum = math.floor(Util.get1(f.pikeWinStreaks, lvl) / Util.NUM_PIKE_ROOMS)
  elseif facility == F.PYRAMID then challengeNum = math.floor(Util.get1(f.pyramidWinStreaks, lvl) / stages)
  end
  if challengeNum ~= 0 then challengeNum = challengeNum - 1 end
  local awards = D.manifest().battlePointAwards
  if challengeNum >= #awards then challengeNum = #awards - 1 end
  local base = awards[challengeNum + 1][facility + 1][mode + 1]
  local points = base
  if isBrain then points = points + 10 end
  f.battlePoints = math.min(D.MAX_BATTLE_FRONTIER_POINTS, (tonumber(f.battlePoints) or 0) + points)
  local card = (tonumber(f.cardBattlePoints) or 0) + base
  Rse.call("tv", "incrementDailyBattlePoints", "IncrementDailyBattlePoints", nil, base)
  if isBrain then
    card = card + 10
    Rse.call("tv", "incrementDailyBattlePoints", "IncrementDailyBattlePoints", nil, 10)
  end
  f.cardBattlePoints = math.min(0xFFFF, card)
  return points
end

-- pokeemerald/src/field_specials.c:2944
function Util.addBattlePoints(sess, n)
  local f = Util.frontier(sess)
  f.battlePoints = math.min(D.MAX_BATTLE_FRONTIER_POINTS, (tonumber(f.battlePoints) or 0) + n)
end

-- pokeemerald/src/field_specials.c:2936
function Util.takeBattlePoints(sess, n)
  local f = Util.frontier(sess)
  local bp = tonumber(f.battlePoints) or 0
  f.battlePoints = bp < n and 0 or bp - n
end

local function speciesOrEgg(mon)
  if type(mon) ~= "table" then return 0 end
  if mon.isEgg or mon.egg then
    return require("src.core.game3.pokemon").SPECIES_EGG
  end
  return tonumber(mon.species or mon.speciesId) or 0
end
Util.speciesOrEgg = speciesOrEgg

function Util.isBanned(species)
  for _, s in ipairs(D.pack("banned").species) do
    if s == species then return true end
  end
  return false
end

-- pokeemerald/src/frontier_util.c:1974
local function appendIfValid(species, heldItem, lvlMode, level, list, items)
  local Pokemon = require("src.core.game3.pokemon")
  if species == Pokemon.SPECIES_EGG or species == 0 then return end
  if Util.isBanned(species) then return end
  if lvlMode == LVL.L50 and level > D.FRONTIER_MAX_LEVEL_50 then return end
  for i = 1, #list do if list[i] == species then return end end
  if heldItem ~= 0 then
    for i = 1, #list do if items[i] == heldItem then return end end
  end
  list[#list + 1] = species
  items[#items + 1] = heldItem
end

local function caughtNational(sess, species)
  local Dex = require("src.core.game3.dex")
  local ok, v = pcall(Dex.isCaught, sess.dex, species)
  if ok then return v == true end
  return type(sess.dex) == "table" and type(sess.dex.caught) == "table" and sess.dex.caught[species] == true
end

-- pokeemerald/src/frontier_util.c:2010
function Util.checkPartyIneligibility(sess, lvlMode)
  local mode = var("VAR_FRONTIER_BATTLE_MODE", sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local toChoose = D.PARTY_SIZE
  if mode == M.MULTIS or mode == M.LINK_MULTIS then
    toChoose = D.MULTI_PARTY_SIZE
  elseif mode == M.DOUBLES then
    toChoose = facility == F.TOWER and D.DOUBLES_PARTY_SIZE or D.PARTY_SIZE
  end
  local party = sess.party or {}
  local eligible = 0
  local looper = 0
  repeat
    local monId = looper
    local list, items = {}, {}
    repeat
      local mon = party[monId + 1]
      local species = speciesOrEgg(mon)
      local held = mon and (tonumber(mon.heldItem or mon.item) or 0) or 0
      local level = mon and (tonumber(mon.level) or 0) or 0
      if facility == F.PYRAMID then
        if held == 0 then appendIfValid(species, held, lvlMode, level, list, items) end
      else
        appendIfValid(species, held, lvlMode, level, list, items)
      end
      monId = (monId + 1) % 6
    until monId == looper
    eligible = #list
    looper = looper + 1
  until not (looper < 6 and eligible < toChoose)
  if eligible >= toChoose then
    Util.frontier(sess).lvlMode = lvlMode
    return false, nil
  end
  local Pokemon = require("src.core.game3.pokemon")
  local banned = D.pack("banned").species
  local caught = 0
  for _, s in ipairs(banned) do if caughtNational(sess, s) then caught = caught + 1 end end
  local RomText = require("src.core.game3.rom_text")
  local out, count = "", 0
  for _, s in ipairs(banned) do
    if caughtNational(sess, s) then
      count = count + 1
      if count == 1 or count == 3 or count == 5 or count == 7 or count == 9 or count == 11 then
        if caught == count then out = out .. RomText.plain("gText_SpaceAndSpace")
        elseif caught > count then out = out .. RomText.plain("gText_CommaSpace") end
      elseif count == 2 then
        out = out .. RomText.plain(count == caught and "gText_SpaceAndSpace" or "gText_CommaSpace") .. "\n"
      else
        out = out .. RomText.plain(count == caught and "gText_SpaceAndSpace" or "gText_CommaSpace") .. "\n"
      end
      out = out .. Pokemon.name(s)
    end
  end
  if count == 0 then
    out = out .. RomText.plain("gText_Space2") .. RomText.plain("gText_Are")
  elseif count % 2 == 1 then
    out = out .. "\n" .. RomText.plain("gText_Are2")
  else
    out = out .. RomText.plain("gText_Space2") .. RomText.plain("gText_Are2")
  end
  return true, out
end

-- pokeemerald/src/party_menu.c:5587
function Util.entryEligible(sess, mon)
  if type(mon) ~= "table" or mon.isEgg or mon.egg then return false end
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local f = Util.frontier(sess)
  local species = tonumber(mon.species or mon.speciesId) or 0
  if species == 0 then return false end
  if facility == F.PYRAMID and (tonumber(mon.heldItem or mon.item) or 0) ~= 0 then return false end
  if Util.isBanned(species) then return false end
  if f.lvlMode == LVL.L50 and (tonumber(mon.level) or 0) > D.FRONTIER_MAX_LEVEL_50 then return false end
  return true
end

-- pokeemerald/src/party_menu.c:5620
function Util.checkBattleEntries(sess, party, order, count)
  if #order < count then return "gText_NoPokemonForBattle" end
  for i = 1, count - 1 do
    local a = party[order[i]]
    for j = i + 1, count do
      local b = party[order[j]]
      if a and b then
        if tonumber(a.species) == tonumber(b.species) then return "gText_MonsCantBeSame" end
        local ia = tonumber(a.heldItem or a.item) or 0
        if ia ~= 0 and ia == (tonumber(b.heldItem or b.item) or 0) then return "gText_NoIdenticalHoldItems" end
      end
    end
  end
  return nil
end

local function deepCopy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = deepCopy(x) end
  return out
end
Util.deepCopy = deepCopy

local function story()
  return require("src.core.game3.scripting.natives_frontier_story")
end

-- pokeemerald/src/frontier_util.c:887
function Util.setSelectedPartyOrder(sess, count)
  local f = Util.frontier(sess)
  local picks = {}
  for i = 1, count do
    local slot = tonumber(f.selectedPartyMons[i]) or 0
    if slot ~= 0 then picks[#picks + 1] = slot end
  end
  local order = {}
  for i = 1, D.MAX_PARTY_SIZE do order[i] = 0 end
  for i = 1, count do order[i] = tonumber(f.selectedPartyMons[i]) or 0 end
  sess.selectedOrderFromParty = order
  story().reducePartyToSelected(sess)
end

-- pokeemerald/src/frontier_util.c:2159
function Util.restoreHeldItems(sess)
  local f = Util.frontier(sess)
  local saved = sess.savedPlayerParty or {}
  for i = 1, D.MAX_PARTY_SIZE do
    local slot = tonumber(f.selectedPartyMons[i]) or 0
    if slot ~= 0 and sess.party[i] and saved[slot] then
      local item = saved[slot].heldItem or saved[slot].item
      sess.party[i].heldItem, sess.party[i].item = item, item
    end
  end
end

-- pokeemerald/src/frontier_util.c:2192
function Util.resetSketchedMoves(sess)
  local f = Util.frontier(sess)
  local saved = sess.savedPlayerParty or {}
  local C = D.constants(sess)
  local sketch = C:require("moves", "MOVE_SKETCH")
  local Pokemon = require("src.core.game3.pokemon")
  for i = 1, D.MAX_PARTY_SIZE do
    local slot = tonumber(f.selectedPartyMons[i]) or 0
    local mon, orig = sess.party[i], saved[slot]
    if slot >= 1 and slot <= 6 and mon and orig then
      for j = 1, 4 do
        local m = mon.moves and mon.moves[j]
        if m then
          local found = false
          for k = 1, 4 do
            if orig.moves and orig.moves[k] == m then found = true break end
          end
          if not found then
            mon.moves[j] = sketch
            mon.maxPp = mon.maxPp or {}
            mon.pp = mon.pp or {}
            mon.maxPp[j] = Pokemon.movePp(sketch)
            mon.pp[j] = mon.maxPp[j]
          end
        end
      end
      saved[slot] = deepCopy(mon)
    end
  end
end

-- pokeemerald/src/frontier_util.c:1530
function Util.checkPutTvShowOnAir(sess)
  local f = Util.frontier(sess)
  local lvl = f.lvlMode
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local mode = var("VAR_FRONTIER_BATTLE_MODE", sess)
  local function tv(streak, show)
    local okShould = Rse.call("tv", "shouldAirFrontierTVShow", "ShouldAirFrontierTVShow", nil)
    if streak > 1 and okShould then
      Rse.call("tv", "tryPutFrontierTVShowOnAir", "TryPutFrontierTVShowOnAir", nil, streak, show,
        deepCopy(f.selectedPartyMons))
    end
  end
  local function rec2(cur, best, shows, extra)
    local c = Util.get2(cur, mode, lvl)
    if c > Util.get2(best, mode, lvl) then
      Util.set2(best, mode, lvl, c)
      if extra then extra() end
      tv(c, shows[mode + 1])
    end
  end
  local function rec1(cur, best, show)
    local c = Util.get1(cur, lvl)
    if c > Util.get1(best, lvl) then
      Util.set1(best, lvl, c)
      tv(c, show)
    end
  end
  local S = Util.SHOW
  if facility == F.TOWER then
    rec2(f.towerWinStreaks, f.towerRecordWinStreaks,
      { S.TOWER_SINGLES, S.TOWER_DOUBLES, S.TOWER_MULTIS, S.TOWER_LINK_MULTIS })
  elseif facility == F.DOME then
    rec2(f.domeWinStreaks, f.domeRecordWinStreaks, { S.DOME_SINGLES, S.DOME_DOUBLES })
  elseif facility == F.PALACE then
    rec2(f.palaceWinStreaks, f.palaceRecordWinStreaks, { S.PALACE_SINGLES, S.PALACE_DOUBLES })
  elseif facility == F.ARENA then
    rec1(f.arenaWinStreaks, f.arenaRecordStreaks, S.ARENA)
  elseif facility == F.FACTORY then
    rec2(f.factoryWinStreaks, f.factoryRecordWinStreaks, { S.FACTORY_SINGLES, S.FACTORY_DOUBLES }, function()
      Util.set2(f.factoryRecordRentsCount, mode, lvl, Util.get2(f.factoryRentsCount, mode, lvl))
    end)
  elseif facility == F.PIKE then
    rec1(f.pikeWinStreaks, f.pikeRecordStreaks, S.PIKE)
  elseif facility == F.PYRAMID then
    rec1(f.pyramidWinStreaks, f.pyramidRecordStreaks, S.PYRAMID)
  end
end

-- pokeemerald/src/field_specials.c:2868
function Util.gamblerSetWonOrLost(sess, won)
  local state = var("VAR_FRONTIER_GAMBLER_STATE", sess)
  if state ~= Util.GAMBLER.PLACED_BET then return end
  local challenge = var("VAR_FRONTIER_GAMBLER_SET_CHALLENGE", sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local mode = var("VAR_FRONTIER_BATTLE_MODE", sess)
  local want = D.manifest().gamblerChallenges[challenge + 1]
  if want == facility * 256 + mode then
    Rse.setVar("VAR_FRONTIER_GAMBLER_STATE", won and Util.GAMBLER.WON or Util.GAMBLER.LOST, sess)
  end
end

-- pokeemerald/src/frontier_util.c:793
function Util.getChallengeStatus(sess)
  local f = Util.frontier(sess)
  local status = tonumber(f.challengeStatus) or 0
  local S = Util.CHALLENGE_STATUS
  Rse.setVar("VAR_TEMP_0", 0xFF, sess)
  if status == S.SAVING or status == S.LOST then
    Util.gamblerSetWonOrLost(sess, false)
    Rse.setVar("VAR_TEMP_0", status, sess)
  elseif status == S.WON then
    Util.gamblerSetWonOrLost(sess, true)
    Rse.setVar("VAR_TEMP_0", status, sess)
  elseif status == S.PAUSED then
    Rse.setVar("VAR_TEMP_0", status, sess)
  end
end

local function brainBit(sess)
  local facility = var("VAR_FRONTIER_FACILITY", sess)
  local sym = Util.symbolCount(sess, facility)
  if sym == 2 then sym = 1 end
  local row = D.manifest().battledBrainBitFlags[facility + 1]
  return row and row[sym + 1] or 0
end

function Util.getData(ctx, sess)
  local f = Util.frontier(sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  local Dd = Util.DATA
  if which == Dd.CHALLENGE_STATUS then setResult(ctx, f.challengeStatus)
  elseif which == Dd.LVL_MODE then setResult(ctx, f.lvlMode)
  elseif which == Dd.BATTLE_NUM then setResult(ctx, f.curChallengeBattleNum)
  elseif which == Dd.PAUSED then setResult(ctx, f.challengePaused)
  elseif which == Dd.BATTLE_OUTCOME then
    setResult(ctx, tonumber(sess.battleOutcome) or 0)
    sess.battleOutcome = 0
  elseif which == Dd.RECORD_DISABLED then setResult(ctx, f.disableRecordBattle)
  elseif which == Dd.HEARD_BRAIN_SPEECH then
    setResult(ctx, bit.band(tonumber(f.battledBrainFlags) or 0, brainBit(sess)))
  end
end

function Util.setData(ctx, sess)
  local f = Util.frontier(sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  local v = specialVar(ctx, Util.VAR_0x8006)
  local Dd = Util.DATA
  if which == Dd.CHALLENGE_STATUS then f.challengeStatus = v
  elseif which == Dd.LVL_MODE then f.lvlMode = v % 4
  elseif which == Dd.BATTLE_NUM then f.curChallengeBattleNum = v
  elseif which == Dd.PAUSED then f.challengePaused = v % 2
  elseif which == Dd.SELECTED_MON_ORDER then
    local order = sess.selectedOrderFromParty or {}
    for i = 1, D.MAX_PARTY_SIZE do f.selectedPartyMons[i] = tonumber(order[i]) or 0 end
  elseif which == Dd.RECORD_DISABLED then f.disableRecordBattle = v % 2
  elseif which == Dd.HEARD_BRAIN_SPEECH then
    f.battledBrainFlags = bit.bor(tonumber(f.battledBrainFlags) or 0, brainBit(sess))
  end
end

function Util.textBox(ir, ctx)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local sess = Rse.session()
  return TextIR.toTextBox(ir, { stringVars = ctx and ctx.stringVars, playerName = sess and sess.name })
end

-- pokeemerald/src/string_util.c:335
function Util.setStringVar(ctx, adapters, n, value)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local ir = value
  if type(value) ~= "table" then ir = { { t = "text", s = tostring(value or "") }, { t = "eos" } } end
  local sess = Rse.session()
  local plain = TextIR.toPlain(ir, { stringVars = ctx and ctx.stringVars, playerName = sess and sess.name })
  local Town = require("src.core.game3.rse.town_common")
  Town.setString(ctx, adapters, n, plain)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local bundle = Space and Space.ensureBundle and Space.ensureBundle()
  if bundle and bundle.text then
    local key = string.format("g3:%08x", Util.STRING_VAR_ADDR[n])
    bundle.text[key] = ir
  end
  return plain
end

-- pokeemerald/src/field_message_box.c:62
function Util.showFieldMessage(ctx, adapters, ir)
  local body = Util.textBox(ir, ctx)
  if ctx then ctx.messageOpen = true end
  local open = adapters and (adapters.openMessageStay or adapters.openMessageAsync)
  if open then open(body, nil)
  elseif adapters and adapters.openMessage then adapters.openMessage(body) end
end

-- pokeemerald/src/start_menu.c:896
function Util.persist()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local mod = Runtime and Runtime._mod
  local okB, Bridge = pcall(require, "src.core.game3.bridge")
  if game and mod and okB and Bridge.persistSessionOnly then pcall(Bridge.persistSessionOnly, mod, game) end
  if game and type(game.saveGame) == "function" then
    local ok, written = pcall(game.saveGame, game)
    return ok and written ~= false
  end
  return false
end

-- pokeemerald/src/frontier_util.c:2421
function Util.saveGameFrontier(sess)
  local warp = sess.dynamicWarp
  if type(warp) ~= "table" or type(warp.map) ~= "string" or not tonumber(warp.x) or not tonumber(warp.y) then
    return false, "The saved Frontier entrance is incomplete. The challenge was not saved."
  end
  if type(sess.savedPlayerParty) ~= "table" then
    return false, "The original party is unavailable. The challenge was not saved."
  end
  local party = {}
  for i, mon in ipairs(sess.party or {}) do party[i] = deepCopy(mon) end
  story().loadPlayerParty(sess)
  sess.continueGameWarp = deepCopy(sess.dynamicWarp)
  sess.specialSaveWarpFlags = bit.bor(tonumber(sess.specialSaveWarpFlags) or 0, 1)
  local f = Util.frontier(sess)
  local savedGame = f.savedGame
  f.savedGame = 1
  local ok, written = pcall(Util.persist)
  sess.specialSaveWarpFlags = bit.band(tonumber(sess.specialSaveWarpFlags) or 0, bit.bnot(1))
  sess.party = party
  if not ok or written ~= true then
    f.savedGame = savedGame
    return false, "The challenge could not be saved."
  end
  return true
end

function Util.saveChallenge(sess, tempName, prepare, save)
  local f = Util.frontier(sess)
  local before = deepCopy(f)
  local id = assert(Rse.varId(tempName, sess))
  local store = Rse.store()
  local vars = store and store.vars
  local temp = vars and vars[id]
  prepare()
  local called, ok, err = pcall(save or Util.saveGameFrontier, sess)
  if not called then ok, err = false, "The challenge could not be saved." end
  if not ok then
    for k in pairs(f) do f[k] = nil end
    for k, v in pairs(before) do f[k] = v end
    if vars then vars[id] = temp end
    if sess.vars then sess.vars[id] = temp end
  end
  return ok, err
end

function Util.saveChallengeInPlace(sess, tempName, prepare)
  return Util.saveChallenge(sess, tempName, prepare, function()
    local ok, written = pcall(Util.persist)
    if not ok or written ~= true then return false, "The challenge could not be saved." end
    return true
  end)
end

function Util.saveFromNative(ctx, adapters, sess, save)
  local ok, err = save(ctx, sess)
  if ok then return false end
  local done = false
  if adapters and adapters.closeMessage then adapters.closeMessage() end
  ctx.messageOpen = true
  ctx.mode, ctx.status = "native", "waiting"
  ctx.nativePoll = function()
    if not done then return false end
    if adapters and adapters.closeMessage then adapters.closeMessage() end
    ctx.messageOpen = false
    ctx.pc, ctx.stack = nil, {}
    return true
  end
  if adapters and adapters.openMessageAsync then
    adapters.openMessageAsync(err, function() done = true end)
  else
    if adapters and adapters.openMessage then adapters.openMessage(err) end
    if adapters and adapters.waitButton then adapters.waitButton(function() done = true end)
    else done = true end
  end
  return true
end

-- pokeemerald/src/battle_tower.c:1956
function Util.onSpecialBattleEnd(sess, kind)
  local f = Util.frontier(sess)
  if kind == "frontier" then
    local n = tonumber(f.battlesCount) or 0
    if n < 0xFFFFFF then
      n = n + 1
      f.battlesCount = n
      if n % 20 == 0 then
        Rse.call("rematch", "updateGymLeaderRematch", "UpdateGymLeaderRematch", nil, sess)
      end
    else
      f.battlesCount = 0xFFFFFF
    end
  end
end

-- pokeemerald/src/record_mixing.c:1116
function Util.playerHallRecords(sess)
  local f = Util.frontier(sess)
  local R = Util.RANKING_HALL
  local name = tostring(sess.name or "")
  local one = {}
  local cols = {
    [R.TOWER_SINGLES] = function(l) return Util.get2(f.towerRecordWinStreaks, M.SINGLES, l) end,
    [R.TOWER_DOUBLES] = function(l) return Util.get2(f.towerRecordWinStreaks, M.DOUBLES, l) end,
    [R.TOWER_MULTIS] = function(l) return Util.get2(f.towerRecordWinStreaks, M.MULTIS, l) end,
    [R.DOME] = function(l) return Util.get2(f.domeRecordWinStreaks, M.SINGLES, l) end,
    [R.PALACE] = function(l) return Util.get2(f.palaceRecordWinStreaks, M.SINGLES, l) end,
    [R.ARENA] = function(l) return Util.get1(f.arenaRecordStreaks, l) end,
    [R.FACTORY] = function(l) return Util.get2(f.factoryRecordWinStreaks, M.SINGLES, l) end,
    [R.PIKE] = function(l) return Util.get1(f.pikeRecordStreaks, l) end,
    [R.PYRAMID] = function(l) return Util.get1(f.pyramidRecordStreaks, l) end,
  }
  for i = 0, Util.HALL_FACILITIES_COUNT - 1 do
    one[i + 1] = {}
    for l = 0, D.LVL_MODE_COUNT - 1 do
      one[i + 1][l + 1] = { name = name, language = 2, winStreak = cols[i](l) }
    end
  end
  local two = {}
  for l = 0, D.LVL_MODE_COUNT - 1 do
    two[l + 1] = { name1 = name, name2 = tostring(f.opponentNames[l + 1] or ""), language = 2,
      winStreak = Util.get2(f.towerRecordWinStreaks, M.LINK_MULTIS, l) }
  end
  return { onePlayer = one, twoPlayers = two }
end

-- pokeemerald/src/frontier_util.c:2270
function Util.rankingHall(sess, hallId, lvlMode)
  if not sess.hallRecords1P then Util.clearRankingHallRecords(sess) end
  local player = Util.playerHallRecords(sess)
  local list = {}
  if hallId == Util.RANKING_HALL.TOWER_LINK then
    for i = 1, Util.HALL_RECORDS_COUNT do list[i] = deepCopy(sess.hallRecords2P[lvlMode + 1][i]) end
    list[#list + 1] = player.twoPlayers[lvlMode + 1]
  else
    for i = 1, Util.HALL_RECORDS_COUNT do list[i] = deepCopy(sess.hallRecords1P[hallId + 1][lvlMode + 1][i]) end
    list[#list + 1] = player.onePlayer[hallId + 1][lvlMode + 1]
  end
  local n = Util.HALL_RECORDS_COUNT
  local out = {}
  for i = 1, n do
    local best, bestId = 0, 1
    local limit = (hallId == Util.RANKING_HALL.TOWER_LINK) and n or (n + 1)
    for j = 1, limit do
      local w = tonumber(list[j].winStreak) or 0
      if w > best then best, bestId = w, j end
    end
    if (tonumber(list[n + 1].winStreak) or 0) >= best then bestId = n + 1 end
    out[i] = deepCopy(list[bestId])
    list[bestId].winStreak = 0
  end
  return out
end

-- pokeemerald/src/tv.c:1479
function Util.towerInterviewTv(sess)
  local f = Util.frontier(sess)
  local ti = f.towerInterview or {}
  return {
    opponentName = ti.opponentName, playerSpecies = ti.playerSpecies, opponentSpecies = ti.opponentSpecies,
    opponentLanguage = ti.opponentLanguage, opponentMonNickname = ti.opponentMonNickname,
    numFights = Util.get2(f.towerWinStreaks, M.SINGLES, f.towerLvlMode or 0),
    wonTheChallenge = f.towerBattleOutcome == Util.B_OUTCOME_WON, lvlMode = f.towerLvlMode,
  }
end

-- pokeemerald/include/global.h:378
Util.CART_BASE = 1612
Util.CART_LAYOUT = {
  { "challengeStatus", 1628, "u8" },
  { "lvlMode", 1629, "bits", 0, 2 }, { "challengePaused", 1629, "bits", 2, 1 },
  { "disableRecordBattle", 1629, "bits", 3, 1 },
  { "selectedPartyMons", 1630, "u16", 4 }, { "curChallengeBattleNum", 1638, "u16" },
  { "trainerIds", 1640, "u16", 20 }, { "winStreakActiveFlags", 1680, "u32" },
  { "towerWinStreaks", 1684, "u16", 4, 2 }, { "towerRecordWinStreaks", 1700, "u16", 4, 2 },
  { "battledBrainFlags", 1716, "u16" }, { "towerSinglesStreak", 1718, "u16" }, { "towerNumWins", 1720, "u16" },
  { "towerBattleOutcome", 1722, "u8" }, { "towerLvlMode", 1723, "u8" },
  { "domeWinStreaks", 1728, "u16", 2, 2 }, { "domeRecordWinStreaks", 1736, "u16", 2, 2 },
  { "domeTotalChampionships", 1744, "u16", 2, 2 },
  { "palacePrize", 1914, "u16" }, { "palaceWinStreaks", 1916, "u16", 2, 2 },
  { "palaceRecordWinStreaks", 1924, "u16", 2, 2 },
  { "arenaPrize", 1932, "u16" }, { "arenaWinStreaks", 1934, "u16", 2 }, { "arenaRecordStreaks", 1938, "u16", 2 },
  { "factoryWinStreaks", 1942, "u16", 2, 2 }, { "factoryRecordWinStreaks", 1950, "u16", 2, 2 },
  { "factoryRentsCount", 1958, "u16", 2, 2 }, { "factoryRecordRentsCount", 1966, "u16", 2, 2 },
  { "pikePrize", 1974, "u16" }, { "pikeWinStreaks", 1976, "u16", 2 }, { "pikeRecordStreaks", 1980, "u16", 2 },
  { "pikeTotalStreaks", 1984, "u16", 2 },
  { "pyramidPrize", 1996, "u16" }, { "pyramidWinStreaks", 1998, "u16", 2 }, { "pyramidRecordStreaks", 2002, "u16", 2 },
  { "verdanturfTentPrize", 2078, "u16" }, { "fallarborTentPrize", 2080, "u16" }, { "slateportTentPrize", 2082, "u16" },
  { "battlePoints", 2156, "u16" }, { "cardBattlePoints", 2158, "u16" }, { "battlesCount", 2160, "u32" },
  { "savedGame", 2221, "bits", 7, 1 },
}

local SIZE = { u8 = 1, u16 = 2, u32 = 4 }

-- pokeemerald/include/global.h:378
function Util.fromCart(read, sess)
  local f = Util.newFrontier()
  for _, row in ipairs(Util.CART_LAYOUT) do
    local name, off, kind, a, b = row[1], row[2], row[3], row[4], row[5]
    if kind == "bits" then
      f[name] = math.floor(read(off, 1) / (2 ^ a)) % (2 ^ b)
    elseif a and b then
      for i = 0, a - 1 do
        for j = 0, b - 1 do Util.set2(f[name], i, j, read(off + (i * b + j) * SIZE[kind], SIZE[kind])) end
      end
    elseif a then
      for i = 0, a - 1 do f[name][i + 1] = read(off + i * SIZE[kind], SIZE[kind]) end
    else
      f[name] = read(off, SIZE[kind])
    end
  end
  f._shaped = true
  if sess then sess.frontier = f end
  return f
end

function Util.toCart(write, sess)
  local f = Util.frontier(sess)
  local bitsAt = {}
  for _, row in ipairs(Util.CART_LAYOUT) do
    local name, off, kind, a, b = row[1], row[2], row[3], row[4], row[5]
    if kind == "bits" then
      bitsAt[off] = (bitsAt[off] or 0) + ((tonumber(f[name]) or 0) % (2 ^ b)) * (2 ^ a)
    elseif a and b then
      for i = 0, a - 1 do
        for j = 0, b - 1 do write(off + (i * b + j) * SIZE[kind], SIZE[kind], Util.get2(f[name], i, j)) end
      end
    elseif a then
      for i = 0, a - 1 do write(off + i * SIZE[kind], SIZE[kind], tonumber(f[name][i + 1]) or 0) end
    else
      write(off, SIZE[kind], tonumber(f[name]) or 0)
    end
  end
  for off, v in pairs(bitsAt) do write(off, 1, v) end
end

Rse.register("frontier", Util)

return Util
