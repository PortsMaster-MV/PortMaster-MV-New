local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")

local NativesPalace = {}

local PalaceMod = require("src.core.game3.rse.frontier.palace")
local function Palace() return PalaceMod end

-- pokeemerald/src/battle_palace.c:79
function NativesPalace.call(ctx, adapters)
  local s = Rse.session()
  local P = Palace()
  local F = P.FUNC
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  if not s then return false end
  if id == F.INIT then P.init(s)
  elseif id == F.GET_DATA then P.getData(ctx, s)
  elseif id == F.SET_DATA then P.setData(ctx, s)
  elseif id == F.GET_COMMENT_ID then P.commentId(ctx, s)
  elseif id == F.SET_OPPONENT then P.setOpponent(s)
  elseif id == F.GET_OPPONENT_INTRO then P.opponentIntro(ctx, adapters, s)
  elseif id == F.INCREMENT_STREAK then P.incrementStreak(s)
  elseif id == F.SAVE then return Util.saveFromNative(ctx, adapters, s, P.save)
  elseif id == F.SET_PRIZE then P.setPrize(s)
  elseif id == F.GIVE_PRIZE then P.givePrize(ctx, adapters, s)
  else
    Rse.missing("palace", "CallBattlePalaceFunction " .. tostring(id), adapters and adapters.log)
  end
  return false
end

NativesPalace.BY_NAME = {
  -- pokeemerald/src/battle_palace.c:79
  CallBattlePalaceFunction = function(ctx, adapters) return NativesPalace.call(ctx, adapters) end,
}

return NativesPalace
