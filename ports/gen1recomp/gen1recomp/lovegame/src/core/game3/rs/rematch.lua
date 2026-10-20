local Rse = require("src.core.game3.rse.init")
local M = {COUNT = 56, STEP_MAX = 255, SECRET_BASE_OPPONENT = 0x400}
M.rng = function() return require("src.core.game3.rng").Random() end

function M.enabled(session)
  local id = require("src.core.game3.constants").versionOf(session)
  return id == "ruby" or id == "sapphire"
end
-- battle_setup.h:4
function M.table()
  local pack = require("src.core.game3.scripting.trainers").pack()
  local rows = assert(pack and pack.rematches, "native RS Trainer's Eyes table missing")
  assert(rows[0] and rows[55] and not rows[56], "native RS Trainer's Eyes table must contain 56 rows")
  return rows
end
local function flags() return require("src.core.game3.scripting.flags") end
local function store(session) return Rse.store() or session end
function M.hasTrainerBeenFought(session, id)
  return flags().getFlag(store(session), nil, 0x500 + id) == true
end
local function setFought(session, id)
  flags().setFlag(store(session), nil, 0x500 + id, true)
end
local function state(session)
  session.trainerRematches = session.trainerRematches or {}
  return session.trainerRematches
end
function M.get(session, index) return tonumber(state(session)[index]) or 0 end
function M.set(session, index, value) state(session)[index] = value ~= 0 and value or nil end

-- battle_setup.c:1266
function M.firstBattleTableId(id)
  local rows = M.table()
  for i = 0, 55 do if rows[i].trainers[1] == id then return i end end
  return -1
end
function M.tableIdOf(id)
  local rows = M.table()
  for i = 0, 55 do
    for j = 1, 5 do
      local n = rows[i].trainers[j]
      if n == 0 then break end
      if n == id then return i end
    end
  end
  return -1
end
-- battle_setup.c:1355
function M.isFirstTrainerIdReadyForRematch(session, id)
  local index = M.firstBattleTableId(id)
  return index ~= -1 and M.get(session, index) ~= 0
end
function M.isTrainerReadyForRematch(session, id)
  local index = M.tableIdOf(id)
  return index ~= -1 and M.get(session, index) ~= 0
end
function M.wasSecondRematchWon(session, id)
  local index = M.firstBattleTableId(id)
  return index ~= -1 and M.hasTrainerBeenFought(session, M.table()[index].trainers[2])
end
function M.shouldTryRematchBattle(session, id)
  return M.isFirstTrainerIdReadyForRematch(session, id) or M.wasSecondRematchWon(session, id)
end
-- battle_setup.c:1376
function M.rematchTrainerId(session, id)
  local index = M.firstBattleTableId(id)
  if index == -1 then return 0 end
  local ids = M.table()[index].trainers
  for j = 2, 5 do
    if ids[j] == 0 then return ids[j - 1] end
    if not M.hasTrainerBeenFought(session, ids[j]) then return ids[j] end
  end
  return ids[5]
end
function M.clearWantRematchState(session, id)
  local index = M.tableIdOf(id)
  if index ~= -1 then M.set(session, index, 0) end
end
-- battle_setup.c:928
function M.isPlayerDefeated(outcome)
  local code = require("src.core.game3.scripting.natives").outcome_to_code(outcome)
  return code == 2 or code == 3
end
function M.onTrainerBattleWon(session, id)
  if id ~= M.SECRET_BASE_OPPONENT then setFought(session, id) end
end
function M.onRematchBattleWon(session, id)
  if id == M.SECRET_BASE_OPPONENT then return end
  M.clearWantRematchState(session, id)
  setFought(session, id)
end

-- battle_setup.c:1415
function M.hasAtLeastFiveBadges(session)
  local C, count = require("src.core.game3.constants").active(session), 0
  for i = 1, 8 do
    local id = C:require("flags", string.format("FLAG_BADGE%02d_GET", i))
    if flags().getFlag(store(session), nil, id) == true then count = count + 1 end
    if count >= 5 then return true end
  end
  return false
end
function M.incrementStepCounter(session)
  if M.hasAtLeastFiveBadges(session) then
    local steps = tonumber(session.trainerRematchStepCounter) or 0
    session.trainerRematchStepCounter = steps >= 255 and 255 or steps + 1
  end
end
function M.isStepCounterMaxed(session)
  return M.hasAtLeastFiveBadges(session) and (tonumber(session.trainerRematchStepCounter) or 0) >= 255
end
-- battle_setup.c:1298
function M.updateRandomTrainerRematches(session, group, num)
  local changed, rows = false, M.table()
  for i = 0, 55 do
    local row = rows[i]
    if row.mapGroup == group and row.mapNum == num then
      if M.get(session, i) ~= 0 then changed = true
      elseif M.hasTrainerBeenFought(session, row.trainers[1]) and M.rng() % 100 <= 30 then
        local team = 2
        while team <= 5 and row.trainers[team] ~= 0 and M.hasTrainerBeenFought(session, row.trainers[team]) do team = team + 1 end
        M.set(session, i, team - 1)
        changed = true
      end
    end
  end
  return changed
end
function M.tryUpdateRandomTrainerRematches(session, group, num)
  if M.isStepCounterMaxed(session) and M.updateRandomTrainerRematches(session, group, num) then
    session.trainerRematchStepCounter = 0
    return true
  end
  return false
end
function M.tryUpdateRandomTrainerRematchesForMap(session, map)
  local group, num = Rse.mapGroupNum(map, session)
  if group ~= nil and num ~= nil then return M.tryUpdateRandomTrainerRematches(session, group, num) end
  return false
end
return M
