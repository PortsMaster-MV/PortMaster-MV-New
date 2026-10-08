return function(V, ROW)
  local sym, count = V.sym, V.count
  local S = V.SYMS
  local C = require("src.core.game3.constants").of(V.GAME)

  V.ITEM_EFFECT_TABLE = sym("gItemEffectTable")
  -- pokeemerald/src/data/pokemon/item_effects.h:385
  V.ITEM_EFFECT_FIRST = C:require("items", "ITEM_POTION")
  V.ITEM_EFFECT_LAST = V.ITEM_EFFECT_FIRST + count("gItemEffectTable", 4) - 1
  -- pokeemerald/src/item_use.c:742
  V.FIELD_USE_FUNCS = {
    medicine = S.funcOff("ItemUseOutOfBattle_Medicine"),
    ether = S.funcOff("ItemUseOutOfBattle_PPRecovery"),
    pp_up = S.funcOff("ItemUseOutOfBattle_PPUp"),
    rare_candy = S.funcOff("ItemUseOutOfBattle_RareCandy"),
    evo_item = S.funcOff("ItemUseOutOfBattle_EvolutionStone"),
    sacred_ash = S.funcOff("ItemUseOutOfBattle_SacredAsh"),
    repel = S.funcOff("ItemUseOutOfBattle_Repel"),
    escape_rope = S.funcOff("ItemUseOutOfBattle_EscapeRope"),
    black_white_flute = S.funcOff("ItemUseOutOfBattle_BlackWhiteFlute"),
    reduce_ev = S.funcOff("ItemUseOutOfBattle_ReduceEV"),
  }

  V.TRAINER_MONEY_TABLE = sym("gTrainerMoneyTable")
  V.TRAINER_MONEY_STRIDE = 4
  V.TRAINER_MONEY_COUNT = count("gTrainerMoneyTable", V.TRAINER_MONEY_STRIDE)
  V.REMATCH_TABLE = sym("gRematchTable")
  V.REMATCH_STRIDE = 16
  V.REMATCH_COUNT = count("gRematchTable", V.REMATCH_STRIDE)
  V.UNION_ROOM_FACILITY_CLASSES = sym("gUnionRoomFacilityClasses")
  V.UNION_ROOM_FACILITY_CLASS_COUNT = count("gUnionRoomFacilityClasses", 2)

  V.INGAME_TRADES = sym("trade.o:sIngameTrades")
  V.INGAME_TRADE_SIZE = 60
  V.INGAME_TRADE_COUNT = count("trade.o:sIngameTrades", V.INGAME_TRADE_SIZE)
  V.INGAME_TRADE_MAIL = sym("trade.o:sIngameTradeMail")
  V.INGAME_TRADE_MAIL_COUNT = count("trade.o:sIngameTradeMail", 20)

  V.BERRIES = sym("gBerries")
  V.BERRY_STRIDE = 28
  V.BERRY_COUNT = count("gBerries", V.BERRY_STRIDE)
  V.POKEBLOCK_NAMES = sym("gPokeblockNames")
  V.POKEBLOCK_NAME_COUNT = count("gPokeblockNames", 4)

  V.CONTEST_MOVES = sym("gContestMoves")
  V.CONTEST_MOVE_STRIDE = 8
  V.CONTEST_MOVES_COUNT = count("gContestMoves", V.CONTEST_MOVE_STRIDE)
  V.CONTEST_EFFECTS = sym("gContestEffects")
  V.CONTEST_EFFECT_STRIDE = 4
  V.CONTEST_EFFECTS_COUNT = count("gContestEffects", V.CONTEST_EFFECT_STRIDE)
  V.CONTEST_EFFECT_DESCRIPTIONS = sym("gContestEffectDescriptionPointers")
  V.CONTEST_EFFECT_DESCRIPTION_COUNT = count("gContestEffectDescriptionPointers", 4)
  V.CONTEST_CATEGORY_NAMES = sym("gContestMoveTypeTextPointers")
  V.CONTEST_CATEGORY_COUNT = count("gContestMoveTypeTextPointers", 4)

  local function tbl(name, stride)
    return { off = sym(name), count = count(name, stride), stride = stride }
  end
  V.FRONTIER = {
    mons = tbl("gBattleFrontierMons", 16),
    trainers = tbl("gBattleFrontierTrainers", 52),
    heldItems = tbl("gBattleFrontierHeldItems", 2),
    banned = tbl("gFrontierBannedSpecies", 2),
    brainMons = tbl("frontier_util.o:sFrontierBrainsMons", 20),
    brainTrainerIds = tbl("frontier_util.o:sFrontierBrainTrainerIds", 2),
    trainerIdRanges = tbl("battle_tower.o:sFrontierTrainerIdRanges", 4),
    trainerIdRangesHard = tbl("battle_tower.o:sFrontierTrainerIdRangesHard", 4),
    towerMaleClasses = tbl("gTowerMaleFacilityClasses", 1),
    towerFemaleClasses = tbl("gTowerFemaleFacilityClasses", 1),
    apprentices = tbl("gApprentices", 88),
    tents = {
      { name = "slateport", trainers = tbl("gSlateportBattleTentTrainers", 52),
        mons = tbl("gSlateportBattleTentMons", 16) },
      { name = "verdanturf", trainers = tbl("gVerdanturfBattleTentTrainers", 52),
        mons = tbl("gVerdanturfBattleTentMons", 16) },
      { name = "fallarbor", trainers = tbl("gFallarborBattleTentTrainers", 52),
        mons = tbl("gFallarborBattleTentMons", 16) },
    },
  }
end
