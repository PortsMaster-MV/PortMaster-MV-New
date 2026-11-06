local Rse = require("src.core.game3.rse.init")
local Hill = require("src.core.game3.rse.trainer_hill")
require("src.core.game3.rse.frontier.pyramid")

local NativesTrainerHill = {}

local function natives() return require("src.core.game3.scripting.natives") end

local FUNCS = {}
local Fn = Hill.FUNC

-- pokeemerald/src/trainer_hill.c:220
FUNCS[Fn.START] = function(_, _, s) Hill.start(s) end
FUNCS[Fn.GET_OWNER_STATE] = function(ctx, _, s) Hill.getOwnerState(ctx, s) end
FUNCS[Fn.GIVE_PRIZE] = function(ctx, adapters, s) Hill.givePrize(ctx, adapters, s) end
FUNCS[Fn.CHECK_FINAL_TIME] = function(ctx, _, s) Hill.checkFinalTime(ctx, s) end
FUNCS[Fn.RESUME_TIMER] = function(_, _, s) Hill.resumeTimer(s) end
FUNCS[Fn.SET_LOST] = function(_, _, s) Hill.state(s).hasLost = 1 end
FUNCS[Fn.GET_CHALLENGE_STATUS] = function(ctx, _, s) Hill.getStatus(ctx, s) end
FUNCS[Fn.GET_CHALLENGE_TIME] = function(ctx, adapters, s) Hill.bufferTime(ctx, adapters, s) end
FUNCS[Fn.GET_ALL_FLOORS_USED] = function(ctx, adapters, s) Hill.allFloorsUsed(ctx, adapters, s) end
-- pokeemerald/src/trainer_hill.c:547
FUNCS[Fn.GET_IN_EREADER_MODE] = function(ctx) Rse.setSpecialVar(ctx, Hill.VAR_RESULT, 0) end
FUNCS[Fn.IN_CHALLENGE] = function(ctx, _, s) Rse.setSpecialVar(ctx, Hill.VAR_RESULT, Hill.inChallenge(s) and 1 or 0) end
FUNCS[Fn.POST_BATTLE_TEXT] = function(ctx, adapters, s) Hill.postBattleText(ctx, adapters, s) end
FUNCS[Fn.SET_ALL_TRAINER_FLAGS] = function(_, _, s) Hill.setAllTrainerFlags(s) end
-- pokeemerald/src/trainer_hill.c:957
FUNCS[Fn.GET_GAME_SAVED] = function(ctx, _, s)
  Rse.setSpecialVar(ctx, Hill.VAR_RESULT, tonumber(require("src.core.game3.rse.frontier.util").frontier(s).savedGame) or 0)
end
FUNCS[Fn.SET_GAME_SAVED] = function(_, _, s) require("src.core.game3.rse.frontier.util").frontier(s).savedGame = 1 end
FUNCS[Fn.CLEAR_GAME_SAVED] = function(_, _, s) require("src.core.game3.rse.frontier.util").frontier(s).savedGame = 0 end
-- pokeemerald/src/trainer_hill.c:985
FUNCS[Fn.GET_WON] = function(ctx, _, s)
  Rse.setSpecialVar(ctx, Hill.VAR_RESULT, (tonumber(Hill.state(s).hasLost) or 0) ~= 0 and 0 or 1)
end
FUNCS[Fn.SET_MODE] = function(ctx, _, s) Hill.setMode(ctx, s) end

NativesTrainerHill.FUNCS = FUNCS

NativesTrainerHill.BY_NAME = {
  -- pokeemerald/src/trainer_hill.c:273
  CallTrainerHillFunction = function(ctx, adapters)
    local s = Rse.session()
    local id = Rse.specialVar(ctx, Hill.VAR_0x8004)
    local fn = FUNCS[id]
    if not (s and fn) then
      Rse.missing("trainerHill", "CallTrainerHillFunction " .. tostring(id), adapters and adapters.log)
      return false
    end
    return fn(ctx, adapters, s) == true
  end,
  -- pokeemerald/src/battle_records.c:465
  ShowTrainerHillRecords = function(ctx)
    local done = false
    natives().awaitState(ctx, function() return done end)
    require("src.ui.game3.rse.trainer_hill_records").show({
      session = Rse.session(),
      onClose = function() done = true end,
    })
    return false
  end,
}

return NativesTrainerHill
