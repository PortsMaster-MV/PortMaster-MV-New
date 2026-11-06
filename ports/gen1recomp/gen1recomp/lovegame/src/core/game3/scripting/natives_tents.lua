local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")

local NativesTents = {}

local function Tents() return require("src.core.game3.rse.frontier.tents") end
local function D() return require("src.core.game3.rse.frontier.trainers") end

local function dispatch(table_, name, ctx, adapters)
  local s = Rse.session()
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  local fn = table_[id]
  if not (s and fn) then
    Rse.missing("tents", name .. " " .. tostring(id), adapters and adapters.log)
    return false
  end
  return fn(ctx, adapters, s) == true
end

local VERDANTURF, FALLARBOR, SLATEPORT = {}, {}, {}

local function build()
  local V, Fa, S = Tents().VERDANTURF, Tents().FALLARBOR, Tents().SLATEPORT
  local F = D().FACILITY
  -- pokeemerald/src/battle_tent.c:110
  VERDANTURF[V.INIT] = function(_, _, s) Tents().init(s) end
  VERDANTURF[V.GET_PRIZE] = function(ctx, _, s) Tents().getPrize(ctx, s, "verdanturf") end
  VERDANTURF[V.SET_PRIZE] = function(ctx, _, s) Tents().setPrize(ctx, s, "verdanturf") end
  -- pokeemerald/src/battle_tent.c:128
  VERDANTURF[V.SET_OPPONENT_GFX] = function(_, _, s) Tents().setVerdanturfGfx(s) end
  -- pokeemerald/src/battle_tent.c:134
  VERDANTURF[V.GET_OPPONENT_INTRO] = function(ctx, adapters, s) Tents().opponentIntro(ctx, adapters, s, F.PALACE) end
  VERDANTURF[V.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Tents().save) end
  VERDANTURF[V.SET_RANDOM_PRIZE] = function(_, _, s) Tents().setRandomPrize(s, "verdanturf") end
  VERDANTURF[V.GIVE_PRIZE] = function(ctx, adapters, s) Tents().givePrize(ctx, adapters, s, "verdanturf") end
  -- pokeemerald/src/battle_tent.c:172
  FALLARBOR[Fa.INIT] = function(_, _, s) Tents().init(s) end
  FALLARBOR[Fa.GET_PRIZE] = function(ctx, _, s) Tents().getPrize(ctx, s, "fallarbor") end
  FALLARBOR[Fa.SET_PRIZE] = function(ctx, _, s) Tents().setPrize(ctx, s, "fallarbor") end
  FALLARBOR[Fa.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Tents().save) end
  FALLARBOR[Fa.SET_RANDOM_PRIZE] = function(_, _, s) Tents().setRandomPrize(s, "fallarbor") end
  FALLARBOR[Fa.GIVE_PRIZE] = function(ctx, adapters, s) Tents().givePrize(ctx, adapters, s, "fallarbor") end
  -- pokeemerald/src/battle_tent.c:203
  FALLARBOR[Fa.GET_OPPONENT_NAME] = function(ctx, adapters, s) Tents().bufferFallarborName(ctx, adapters, s) end
  -- pokeemerald/src/battle_tent.c:227
  SLATEPORT[S.INIT] = function(_, _, s) Tents().init(s) end
  SLATEPORT[S.GET_PRIZE] = function(ctx, _, s) Tents().getPrize(ctx, s, "slateport") end
  SLATEPORT[S.SET_PRIZE] = function(ctx, _, s) Tents().setPrize(ctx, s, "slateport") end
  SLATEPORT[S.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Tents().save) end
  SLATEPORT[S.SET_RANDOM_PRIZE] = function(_, _, s) Tents().setRandomPrize(s, "slateport") end
  SLATEPORT[S.GIVE_PRIZE] = function(ctx, adapters, s) Tents().givePrize(ctx, adapters, s, "slateport") end
  -- pokeemerald/src/battle_tent.c:272
  SLATEPORT[S.SELECT_RENT_MONS] = function(ctx, adapters, s)
    local impl = Rse.system("factory")
    if impl and type(impl.selectScreen) == "function" then return impl.selectScreen(ctx, adapters, s, true) end
    Rse.missing("factory", "DoBattleFactorySelectScreen", adapters and adapters.log)
  end
  -- pokeemerald/src/battle_tent.c:278
  SLATEPORT[S.SWAP_RENT_MONS] = function(ctx, adapters, s)
    local impl = Rse.system("factory")
    if impl and type(impl.swapScreen) == "function" then return impl.swapScreen(ctx, adapters, s, true) end
    Rse.missing("factory", "DoBattleFactorySwapScreen", adapters and adapters.log)
  end
  -- pokeemerald/src/battle_tent.c:350
  SLATEPORT[S.GENERATE_OPPONENT_MONS] = function(_, _, s) Tents().generateOpponentMons(s) end
  -- pokeemerald/src/battle_tent.c:289
  SLATEPORT[S.GENERATE_RENTAL_MONS] = function(_, _, s) Tents().generateRentalMons(s) end
end

local function ensure()
  if next(VERDANTURF) == nil then build() end
end

NativesTents.VERDANTURF, NativesTents.FALLARBOR, NativesTents.SLATEPORT = VERDANTURF, FALLARBOR, SLATEPORT

NativesTents.BY_NAME = {
  -- pokeemerald/src/battle_tent.c:105
  CallVerdanturfTentFunction = function(ctx, adapters)
    ensure()
    return dispatch(VERDANTURF, "CallVerdanturfTentFunction", ctx, adapters)
  end,
  -- pokeemerald/src/battle_tent.c:167
  CallFallarborTentFunction = function(ctx, adapters)
    ensure()
    return dispatch(FALLARBOR, "CallFallarborTentFunction", ctx, adapters)
  end,
  -- pokeemerald/src/battle_tent.c:222
  CallSlateportTentFunction = function(ctx, adapters)
    ensure()
    return dispatch(SLATEPORT, "CallSlateportTentFunction", ctx, adapters)
  end,
}

return NativesTents
