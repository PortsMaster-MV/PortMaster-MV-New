local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local Rematch = {}

-- pokeemerald/include/constants/rematches.h:86
Rematch.SPECIAL_TRAINER_START = 64
-- pokeemerald/include/constants/rematches.h:87
Rematch.ELITE_FOUR_ENTRIES = 73
-- pokeemerald/include/constants/global.h:61
Rematch.MAX_REMATCH_ENTRIES = 100
-- pokeemerald/include/battle_setup.h:6
Rematch.REMATCHES_COUNT = 5
-- pokeemerald/src/battle_setup.c:1792
Rematch.STEP_COUNTER_MAX = 255
-- pokeemerald/include/constants/game_stat.h:11
Rematch.GAME_STAT_TOTAL_BATTLES = 7
Rematch.GAME_STAT_WILD_BATTLES = 8
Rematch.GAME_STAT_TRAINER_BATTLES = 9

local BADGES = {
  "FLAG_BADGE01_GET", "FLAG_BADGE02_GET", "FLAG_BADGE03_GET", "FLAG_BADGE04_GET",
  "FLAG_BADGE05_GET", "FLAG_BADGE06_GET", "FLAG_BADGE07_GET", "FLAG_BADGE08_GET",
}
Rematch.BADGE_FLAGS = BADGES

Rematch.rng = function() return require("src.core.game3.rng").Random() end

local function runtimeSession()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function Flags()
  return lazyReq("src.core.game3.scripting.flags")
end

local function constants(session)
  local C = lazyReq("src.core.game3.constants")
  return C.of(C.versionOf(session))
end

function Rematch.store(session)
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.store then return Space.store end
  session = session or runtimeSession()
  if session then
    session.flags = session.flags or {}
    session.vars = session.vars or {}
    return { flags = session.flags, vars = session.vars }
  end
  return nil
end

local function flagId(session, name)
  return assert(constants(session):flag(name), "rematch: unknown flag " .. tostring(name))
end

function Rematch.flag(session, nameOrId)
  local id = type(nameOrId) == "number" and nameOrId or flagId(session, nameOrId)
  return Flags().getFlag(Rematch.store(session), nil, id) == true
end

function Rematch.setFlag(session, nameOrId, on)
  local id = type(nameOrId) == "number" and nameOrId or flagId(session, nameOrId)
  local st = Rematch.store(session)
  if st then Flags().setFlag(st, nil, id, on ~= false) end
end

function Rematch.registeredFlagId(session, tableId)
  return flagId(session, "TRAINER_REGISTERED_FLAGS_START") + tableId
end

-- pokeemerald/src/battle_setup.c:1257
function Rematch.hasTrainerBeenFought(session, trainerId)
  return Rematch.flag(session, Flags().trainerFlagId(trainerId))
end

function Rematch.table()
  local pack = lazyReq("src.core.game3.scripting.trainers").pack()
  local t = pack and pack.rematches
  return type(t) == "table" and t or {}
end

function Rematch.count()
  local t, n = Rematch.table(), 0
  while t[n] do n = n + 1 end
  return n
end

function Rematch.entry(tableId)
  return Rematch.table()[tableId]
end

function Rematch.trainerIds(tableId)
  local e = Rematch.entry(tableId)
  return e and e.trainers or {}
end

function Rematch.state(session)
  session = session or runtimeSession()
  if not session then return { rematches = {}, steps = 0 } end
  if type(session.trainerRematches) ~= "table" then session.trainerRematches = {} end
  session.trainerRematchStepCounter = tonumber(session.trainerRematchStepCounter) or 0
  return { rematches = session.trainerRematches, steps = session.trainerRematchStepCounter }
end

function Rematch.get(session, tableId)
  Rematch.state(session)
  return tonumber(session.trainerRematches[tableId]) or 0
end

function Rematch.set(session, tableId, v)
  Rematch.state(session)
  v = tonumber(v) or 0
  session.trainerRematches[tableId] = v ~= 0 and v or nil
end

-- pokeemerald/src/battle_setup.c:1546
function Rematch.firstBattleTableId(trainerId)
  local t = Rematch.table()
  for i = 0, Rematch.count() - 1 do
    if t[i].trainers[1] == trainerId then return i end
  end
  return -1
end

-- pokeemerald/src/battle_setup.c:1559
function Rematch.tableIdOf(trainerId)
  local t = Rematch.table()
  for i = 0, Rematch.count() - 1 do
    for j = 1, Rematch.REMATCHES_COUNT do
      local id = t[i].trainers[j]
      if id == 0 then break end
      if id == trainerId then return i end
    end
  end
  return -1
end

-- pokeemerald/src/battle_setup.c:1578
function Rematch.isForbidden(session, tableId)
  if tableId >= Rematch.ELITE_FOUR_ENTRIES then return true end
  if tableId == Rematch.SPECIAL_TRAINER_START then
    return not Rematch.flag(session, "FLAG_DEFEATED_WALLY_VICTORY_ROAD")
  end
  return false
end

-- pokeemerald/src/battle_setup.c:1588
function Rematch.setRematchIdForTrainer(session, tableId)
  local ids = Rematch.trainerIds(tableId)
  local i = 2
  while i <= Rematch.REMATCHES_COUNT do
    local id = ids[i]
    if id == nil or id == 0 then break end
    if not Rematch.hasTrainerBeenFought(session, id) then break end
    i = i + 1
  end
  Rematch.set(session, tableId, i - 1)
end

-- pokeemerald/src/battle_setup.c:1605
local function updateRandomTrainerRematches(session, mapGroup, mapNum)
  local ret = false
  local t = Rematch.table()
  for i = 0, Rematch.SPECIAL_TRAINER_START do
    local e = t[i]
    if e and e.mapGroup == mapGroup and e.mapNum == mapNum and not Rematch.isForbidden(session, i) then
      if Rematch.get(session, i) ~= 0 then
        ret = true
      elseif Rematch.flag(session, Rematch.registeredFlagId(session, i)) and (Rematch.rng() % 100) <= 30 then
        Rematch.setRematchIdForTrainer(session, i)
        ret = true
      end
    end
  end
  return ret
end

-- pokeemerald/src/battle_setup.c:1631
function Rematch.updateIfDefeated(session, tableId)
  local ids = Rematch.trainerIds(tableId)
  if ids[1] and Rematch.hasTrainerBeenFought(session, ids[1]) then
    Rematch.setRematchIdForTrainer(session, tableId)
  end
end

-- pokeemerald/src/battle_setup.c:1637
function Rematch.doesSomeoneWantRematchIn(session, mapGroup, mapNum)
  local t = Rematch.table()
  for i = 0, Rematch.count() - 1 do
    if t[i].mapGroup == mapGroup and t[i].mapNum == mapNum and Rematch.get(session, i) ~= 0 then return true end
  end
  return false
end

-- pokeemerald/src/battle_setup.c:1650
function Rematch.isRematchTrainerIn(mapGroup, mapNum)
  local t = Rematch.table()
  for i = 0, Rematch.count() - 1 do
    if t[i].mapGroup == mapGroup and t[i].mapNum == mapNum then return true end
  end
  return false
end

-- pokeemerald/src/battle_setup.c:1663
function Rematch.isFirstTrainerIdReadyForRematch(session, trainerId)
  local id = Rematch.firstBattleTableId(trainerId)
  if id == -1 or id >= Rematch.MAX_REMATCH_ENTRIES then return false end
  return Rematch.get(session, id) ~= 0
end

-- pokeemerald/src/battle_setup.c:1677
function Rematch.isTrainerReadyForRematch(session, trainerId)
  session = session or runtimeSession()
  local id = Rematch.tableIdOf(trainerId)
  if id == -1 or id >= Rematch.MAX_REMATCH_ENTRIES then return false end
  return Rematch.get(session, id) ~= 0
end

-- pokeemerald/src/battle_setup.c:1691
function Rematch.rematchTrainerId(session, firstTrainerId)
  session = session or runtimeSession()
  local id = Rematch.firstBattleTableId(firstTrainerId)
  if id == -1 then return 0 end
  local ids = Rematch.trainerIds(id)
  for i = 2, Rematch.REMATCHES_COUNT do
    if ids[i] == 0 then return ids[i - 1] end
    if not Rematch.hasTrainerBeenFought(session, ids[i]) then return ids[i] end
  end
  return ids[Rematch.REMATCHES_COUNT]
end

-- pokeemerald/src/battle_setup.c:1712
function Rematch.lastBeatenRematchTrainerId(session, firstTrainerId)
  local id = Rematch.firstBattleTableId(firstTrainerId)
  if id == -1 then return 0 end
  local ids = Rematch.trainerIds(id)
  for i = 2, Rematch.REMATCHES_COUNT do
    if ids[i] == 0 then return ids[i - 1] end
    if not Rematch.hasTrainerBeenFought(session, ids[i]) then return ids[i - 1] end
  end
  return ids[Rematch.REMATCHES_COUNT]
end

-- pokeemerald/src/battle_setup.c:1733
function Rematch.clearWantRematchState(session, trainerId)
  local id = Rematch.tableIdOf(trainerId)
  if id ~= -1 then Rematch.set(session, id, 0) end
end

-- pokeemerald/src/battle_setup.c:1741
function Rematch.matchCallFlagOf(session, trainerId)
  local t = Rematch.table()
  for i = 0, Rematch.count() - 1 do
    if t[i].trainers[1] == trainerId then return Rematch.registeredFlagId(session, i) end
  end
  return nil
end

-- pokeemerald/src/battle_setup.c:1754
function Rematch.registerTrainerInMatchCall(session, trainerId)
  session = session or runtimeSession()
  if Rematch.flag(session, "FLAG_HAS_MATCH_CALL") then
    local f = Rematch.matchCallFlagOf(session, trainerId)
    if f then Rematch.setFlag(session, f, true) end
  end
end

-- pokeemerald/src/battle_setup.c:1764
function Rematch.wasSecondRematchWon(session, trainerId)
  local id = Rematch.firstBattleTableId(trainerId)
  if id == -1 then return false end
  local second = Rematch.trainerIds(id)[2]
  return second ~= nil and Rematch.hasTrainerBeenFought(session, second)
end

-- pokeemerald/src/battle_setup.c:1776
function Rematch.hasAtLeastFiveBadges(session)
  local n = 0
  for _, name in ipairs(BADGES) do
    if Rematch.flag(session, name) then
      n = n + 1
      if n >= 5 then return true end
    end
  end
  return false
end

-- pokeemerald/src/battle_setup.c:1794
function Rematch.incrementStepCounter(session)
  session = session or runtimeSession()
  if not session then return end
  Rematch.state(session)
  if Rematch.hasAtLeastFiveBadges(session) then
    if session.trainerRematchStepCounter >= Rematch.STEP_COUNTER_MAX then
      session.trainerRematchStepCounter = Rematch.STEP_COUNTER_MAX
    else
      session.trainerRematchStepCounter = session.trainerRematchStepCounter + 1
    end
  end
end

-- pokeemerald/src/battle_setup.c:1805
function Rematch.isStepCounterMaxed(session)
  Rematch.state(session)
  return Rematch.hasAtLeastFiveBadges(session) and session.trainerRematchStepCounter >= Rematch.STEP_COUNTER_MAX
end

-- pokeemerald/src/battle_setup.c:1813
function Rematch.tryUpdateRandomTrainerRematches(session, mapGroup, mapNum)
  session = session or runtimeSession()
  if not session then return false end
  if Rematch.isStepCounterMaxed(session) and updateRandomTrainerRematches(session, mapGroup, mapNum) then
    session.trainerRematchStepCounter = 0
    return true
  end
  return false
end

function Rematch.tryUpdateRandomTrainerRematchesForMap(session, mapId)
  local Rse = lazyReq("src.core.game3.rse.init")
  local g, n = Rse.mapGroupNum(mapId, session)
  if not g then return false end
  return Rematch.tryUpdateRandomTrainerRematches(session, g, n)
end

-- pokeemerald/src/battle_setup.c:1839
function Rematch.shouldTryRematchBattle(session, opponentA)
  session = session or runtimeSession()
  if Rematch.isFirstTrainerIdReadyForRematch(session, opponentA) then return true end
  return Rematch.wasSecondRematchWon(session, opponentA)
end

-- pokeemerald/src/battle_setup.c:1873
function Rematch.countBattledRematchTeams(session, tableId)
  local ids = Rematch.trainerIds(tableId)
  if not (ids[1] and Rematch.hasTrainerBeenFought(session, ids[1])) then return 0 end
  local i = 2
  while i <= Rematch.REMATCHES_COUNT do
    if ids[i] == 0 or ids[i] == nil then break end
    if not Rematch.hasTrainerBeenFought(session, ids[i]) then break end
    i = i + 1
  end
  return i - 1
end

-- pokeemerald/src/battle_setup.c:1245
local function setBattledTrainerFlags(session, opponentA, opponentB)
  if opponentB and opponentB ~= 0 then Rematch.setFlag(session, Flags().trainerFlagId(opponentB), true) end
  Rematch.setFlag(session, Flags().trainerFlagId(opponentA), true)
end

-- pokeemerald/src/battle_setup.c:1327
function Rematch.onTrainerBattleWon(session, opponentA, opponentB)
  session = session or runtimeSession()
  Rematch.registerTrainerInMatchCall(session, opponentA)
  setBattledTrainerFlags(session, opponentA, opponentB)
end

-- pokeemerald/src/battle_setup.c:1351
function Rematch.onRematchBattleWon(session, opponentA)
  session = session or runtimeSession()
  Rematch.registerTrainerInMatchCall(session, opponentA)
  setBattledTrainerFlags(session, opponentA)
  Rematch.clearWantRematchState(session, opponentA)
  setBattledTrainerFlags(session, opponentA)
end

local function gymLeaderLists()
  local Rse = lazyReq("src.core.game3.rse.init")
  local man = lazyReq("src.core.game3.rse.match_call").manifest()
  return man.gymLeaderRematchesAfterNewMauville or {}, man.gymLeaderRematchesBeforeNewMauville or {}
end

-- pokeemerald/src/gym_leader_rematch.c:94
local function rematchIndex(session, tableId)
  local ids = Rematch.trainerIds(tableId)
  for i = 1, 5 do
    if not Rematch.hasTrainerBeenFought(session, ids[i]) then return i - 1 end
  end
  return 5
end

-- pokeemerald/src/gym_leader_rematch.c:43
local function updateFromArray(session, data, maxRematch)
  local which, lowest = 0, 5
  for _, id in ipairs(data) do
    if Rematch.get(session, id) == 0 then
      local r = rematchIndex(session, id)
      if lowest > r then lowest = r end
      which = which + 1
    end
  end
  if which == 0 or lowest > maxRematch then return end
  which = 0
  for _, id in ipairs(data) do
    if Rematch.get(session, id) == 0 and rematchIndex(session, id) == lowest then which = which + 1 end
  end
  if which == 0 then return end
  which = Rematch.rng() % which
  for _, id in ipairs(data) do
    if Rematch.get(session, id) == 0 and rematchIndex(session, id) == lowest then
      if which == 0 then
        Rematch.set(session, id, lowest)
        return
      end
      which = which - 1
    end
  end
end

-- pokeemerald/src/gym_leader_rematch.c:32
function Rematch.updateGymLeaderRematch(session)
  session = session or runtimeSession()
  if Rematch.flag(session, "FLAG_SYS_GAME_CLEAR") and (Rematch.rng() % 100) <= 30 then
    local after, before = gymLeaderLists()
    if Rematch.flag(session, "FLAG_WATTSON_REMATCH_AVAILABLE") then
      updateFromArray(session, after, 5)
    else
      updateFromArray(session, before, 1)
    end
  end
end

local function bumpStat(session, id)
  if type(session.gameStats) ~= "table" then session.gameStats = {} end
  session.gameStats[id] = math.min(0xFFFFFF, math.floor(tonumber(session.gameStats[id]) or 0) + 1)
  return session.gameStats[id]
end

function Rematch.gameStat(session, id)
  return math.floor(tonumber(session and session.gameStats and session.gameStats[id]) or 0)
end

-- pokeemerald/src/battle_setup.c:459
function Rematch.onTrainerBattleStart(session)
  session = session or runtimeSession()
  if not session then return end
  bumpStat(session, Rematch.GAME_STAT_TOTAL_BATTLES)
  -- pokeemerald/src/battle_setup.c:962
  if bumpStat(session, Rematch.GAME_STAT_TRAINER_BATTLES) % 20 == 0 then Rematch.updateGymLeaderRematch(session) end
end

-- pokeemerald/src/battle_setup.c:402
function Rematch.onWildBattleStart(session)
  session = session or runtimeSession()
  if not session then return end
  bumpStat(session, Rematch.GAME_STAT_TOTAL_BATTLES)
  -- pokeemerald/src/battle_setup.c:956
  if bumpStat(session, Rematch.GAME_STAT_WILD_BATTLES) % 60 == 0 then Rematch.updateGymLeaderRematch(session) end
end

-- pokeemerald/include/global.h:1015
Rematch.SAVE_FIELDS = { "trainerRematchStepCounter", "trainerRematches", "regionMapZoom" }

local ok, SaveSections = pcall(require, "src.core.game3.save_sections")
if ok and SaveSections then
  SaveSections.register("matchCall", SaveSections.fields(Rematch.SAVE_FIELDS, function(session)
    session.trainerRematchStepCounter = 0
    session.trainerRematches = {}
    session.regionMapZoom = false
  end))
end

return Rematch
