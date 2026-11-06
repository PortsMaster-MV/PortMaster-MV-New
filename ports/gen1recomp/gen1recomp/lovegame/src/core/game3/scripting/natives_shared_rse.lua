local Std = require("src.core.game3.scripting.stdscripts")

local Shared = {}

local function from(module, name)
  return function(...)
    local mod = require("src.core.game3.scripting." .. module)
    return mod.BY_NAME[name](...)
  end
end

local function moveAt(mon, slot)
  local mv = mon and mon.moves and mon.moves[slot + 1]
  return tonumber(type(mv) == "table" and (mv.id or mv.move) or mv) or 0
end

local function knows(mon, move)
  for j = 0, 3 do if moveAt(mon, j) == move then return true end end
  return false
end

-- pokeemerald/src/party_menu.c:6407
function Shared.isLastMonThatKnowsSurf(ctx)
  local Rse = require("src.core.game3.rse.init")
  local Ribbons = require("src.core.game3.rse.ribbons")
  local sess = Rse.session()
  local party = sess and sess.party or {}
  local idx = Rse.specialVar(ctx, 0x8004)
  local surf = require("src.core.game3.constants").of("emerald"):require("moves", "MOVE_SURF")
  if moveAt(party[idx + 1], Rse.specialVar(ctx, 0x8005)) ~= surf then return 0 end
  for i, mon in ipairs(party) do
    if i ~= idx + 1 and knows(mon, surf) then return 0 end
  end
  -- pokeemerald/src/pokemon_storage_system.c:9636
  local inBox = Ribbons.forEachMon(sess, function(mon, box) return box ~= nil and knows(mon, surf) end)
  return inBox and 0 or 1
end

Shared.BY_NAME = {
  -- pokeemerald/src/party_menu.c:6407
  IsLastMonThatKnowsSurf = function(ctx)
    local Rse = require("src.core.game3.rse.init")
    Rse.setSpecialVar(ctx, 0x800D, Shared.isLastMonThatKnowsSurf(ctx))
    return false
  end,
  -- pokeemerald/src/trade.c:4532
  GetInGameTradeSpeciesInfo = from("natives_trade", "GetInGameTradeSpeciesInfo"),
  -- pokeemerald/src/trade.c:4615
  GetTradeSpecies = from("natives_trade", "GetTradeSpecies"),
  -- pokeemerald/src/trade.c:4622
  CreateInGameTradePokemon = from("natives_trade", "CreateInGameTradePokemon"),
  -- pokeemerald/src/trade.c:4845
  DoInGameTradeScene = from("natives_trade", "DoInGameTradeScene"),
  -- pokeemerald/src/party_menu.c:6279
  ChooseMonForMoveRelearner = from("natives_moveteach", "ChooseMonForMoveRelearner"),
  -- pokeemerald/src/move_relearner.c:373
  TeachMoveRelearnerMove = from("natives_moveteach", "TeachMoveRelearnerMove"),
  -- pokeemerald/src/party_menu.c:6341
  MoveDeleterChooseMoveToForget = from("natives_moveteach", "SelectMoveDeleterMove"),
  -- pokeemerald/src/party_menu.c:6347
  GetNumMovesSelectedMonHas = from("natives_moveteach", "GetNumMovesSelectedMonHas"),
  -- pokeemerald/src/party_menu.c:6359
  BufferMoveDeleterNicknameAndMove = from("natives_moveteach", "BufferMoveDeleterNicknameAndMove"),
  -- pokeemerald/src/party_menu.c:6368
  MoveDeleterForgetMove = from("natives_moveteach", "MoveDeleterForgetMove"),
  -- pokeemerald/src/party_menu.c:6399
  IsSelectedMonEgg = from("natives_queries", "IsSelectedMonEgg"),
}

Std.legacyHandlers(Shared)

return Shared
