local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")

local NativesArena = {}

local ArenaMod = require("src.core.game3.rse.frontier.arena")
local function Arena() return ArenaMod end

-- pokeemerald/src/battle_arena.c:385
function NativesArena.call(ctx, adapters)
  local s = Rse.session()
  local A = Arena()
  local F = A.FUNC
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  if not s then return false end
  if id == F.INIT then A.init(s)
  elseif id == F.GET_DATA then A.getData(ctx, s)
  elseif id == F.SET_DATA then A.setData(ctx, s)
  elseif id == F.SAVE then return Util.saveFromNative(ctx, adapters, s, A.save)
  elseif id == F.SET_PRIZE then A.setPrize(s)
  elseif id == F.GIVE_PRIZE then A.givePrize(ctx, adapters, s)
  elseif id == F.GET_TRAINER_NAME then A.bufferOpponentName(ctx, adapters, s)
  else
    Rse.missing("arena", "CallBattleArenaFunction " .. tostring(id), adapters and adapters.log)
  end
  return false
end

NativesArena.BY_NAME = {
  -- pokeemerald/src/battle_arena.c:385
  CallBattleArenaFunction = function(ctx, adapters) return NativesArena.call(ctx, adapters) end,
}

return NativesArena
