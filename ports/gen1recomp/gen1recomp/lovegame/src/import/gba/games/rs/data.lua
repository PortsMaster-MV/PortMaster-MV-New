return function(V)
  local S, sym, count = V.SYMS, V.sym, V.count
  V.FIELD_USE_FUNCS = {}
  for name, stem in pairs({
    medicine = "Medicine", ether = "PPRecovery", pp_up = "PPUp", rare_candy = "RareCandy",
    evo_item = "EvolutionStone", sacred_ash = "SacredAsh", repel = "Repel",
    escape_rope = "EscapeRope", black_white_flute = "BlackWhiteFlute",
  }) do V.FIELD_USE_FUNCS[name] = S.funcOff("ItemUseOutOfBattle_" .. stem) end

  V.TRAINER_MONEY_TABLE = sym("gTrainerMoney")
  V.TRAINER_MONEY_STRIDE = 4
  V.TRAINER_MONEY_COUNT = count("gTrainerMoney", 4)
  -- pokeruby/src/battle_setup.c:163
  V.REMATCH_TABLE = sym("gTrainerEyeTrainers")
  V.REMATCH_STRIDE = 16
  V.REMATCH_COUNT = count("gTrainerEyeTrainers", 16)
  V.FACILITY_CLASS_TO_PIC = sym("gTrainerClassToPicIndex")
  V.FACILITY_CLASS_TO_TRAINER_CLASS = sym("gTrainerClassToNameIndex")
  V.FACILITY_CLASS_COUNT = count("gTrainerClassToPicIndex", 1)
  assert(V.FACILITY_CLASS_COUNT == count("gTrainerClassToNameIndex", 1))

  V.CONTEST_EFFECT_DESCRIPTIONS = sym("gContestEffectStrings")
  V.CONTEST_EFFECT_DESCRIPTION_COUNT = count("gContestEffectStrings", 4)
  V.CONTEST_CATEGORY_NAMES = sym("gContestCategoryNames")
  V.CONTEST_CATEGORY_COUNT = count("gContestCategoryNames", 4)
end
