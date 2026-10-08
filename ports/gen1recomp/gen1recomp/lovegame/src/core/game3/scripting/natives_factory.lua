local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")
local Factory = require("src.core.game3.rse.frontier.factory")

local NativesFactory = {}

local FN = Factory.FUNC
local FUNCS = {}

-- pokeemerald/src/battle_factory.c:124
FUNCS[FN.INIT] = function(_, _, s) Factory.init(s) end
FUNCS[FN.GET_DATA] = function(ctx, _, s) Factory.getData(ctx, s) end
FUNCS[FN.SET_DATA] = function(ctx, _, s) Factory.setData(ctx, s) end
FUNCS[FN.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Factory.save) end
FUNCS[FN.NULL] = function() end
FUNCS[FN.NULL2] = function() end
FUNCS[FN.SELECT_RENT_MONS] = function(ctx, adapters, s) return Factory.selectScreen(ctx, adapters, s) end
FUNCS[FN.SWAP_RENT_MONS] = function(ctx, adapters, s) return Factory.swapScreen(ctx, adapters, s) end
FUNCS[FN.SET_SWAPPED] = function(_, _, s) Factory.setPerformedSwap(s) end
FUNCS[FN.SET_OPPONENT_MONS] = function(_, _, s) Factory.setRentalsToOpponentParty(s) end
FUNCS[FN.SET_PARTIES] = function(ctx, _, s) Factory.setPlayerAndOpponentParties(ctx, s) end
FUNCS[FN.SET_OPPONENT_GFX] = function(_, _, s) Factory.setOpponentGfx(s) end
FUNCS[FN.GENERATE_OPPONENT_MONS] = function(_, _, s) Factory.generateOpponentMons(s) end
FUNCS[FN.GENERATE_RENTAL_MONS] = function(_, _, s) Factory.generateInitialRentalMons(s) end
FUNCS[FN.GET_OPPONENT_MON_TYPE] = function(ctx, _, s) Util.setResult(ctx, Factory.opponentMostCommonType(s)) end
FUNCS[FN.GET_OPPONENT_STYLE] = function(ctx, _, s) Util.setResult(ctx, Factory.opponentBattleStyle(s)) end
FUNCS[FN.RESET_HELD_ITEMS] = function(_, _, s) Factory.restorePlayerPartyHeldItems(s) end
NativesFactory.FUNCS = FUNCS

-- pokeemerald/src/battle_factory.c:193
function NativesFactory.call(ctx, adapters)
  local s = Rse.session()
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  local fn = FUNCS[id]
  if not (s and fn) then
    Rse.missing("factory", "CallBattleFactoryFunction " .. tostring(id), adapters and adapters.log)
    return false
  end
  return fn(ctx, adapters, s) == true
end

NativesFactory.BY_NAME = {
  CallBattleFactoryFunction = NativesFactory.call,
}

return NativesFactory
