local Rse = require("src.core.game3.rse.init")
local R = require("src.core.game3.rs.rematch")
local M = {BY_NAME = {}}
local function opponent(ctx) return tonumber(ctx and ctx.trainerBattleOpponentA) or 0 end
M.BY_NAME.ShouldTryRematchBattle = function(ctx)
  return false, R.shouldTryRematchBattle(Rse.session(), opponent(ctx)) and 1 or 0
end
M.BY_NAME.IsTrainerReadyForRematch = function(ctx)
  return false, R.isTrainerReadyForRematch(Rse.session(), opponent(ctx)) and 1 or 0
end
-- pokeruby/src/battle_setup.c:1144
M.BY_NAME.BattleSetup_StartRematchBattle = function(ctx, adapters)
  local id, s = opponent(ctx), Rse.session()
  assert(adapters and adapters.startTrainerBattle, "RS rematch battle host missing")
  local Trainers, Natives = require("src.core.game3.scripting.trainers"), require("src.core.game3.scripting.natives")
  local foe = assert(Trainers.foeFromId(id), "RS rematch trainer missing")
  local dialogs = Trainers.dialogs(id)
  if ctx then ctx.trainerIntroShown = nil end
  return Natives.yieldHost(ctx, adapters, function(done)
    adapters.startTrainerBattle(foe, function(outcome)
      if ctx then ctx.lastBattleOutcome = Natives.outcome_to_code(outcome) end
      if not R.isPlayerDefeated(outcome) then R.onRematchBattleWon(s, id) end
      done()
    end, {trainerId = id, double = foe.doubleBattle == true or nil,
      defeatText = dialogs.defeat, victoryText = dialogs.victory})
  end)
end
return M
