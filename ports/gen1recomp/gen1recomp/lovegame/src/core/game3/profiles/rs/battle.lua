local Battle = {}

function Battle.new(game)
  return {
    family = "rse", aiVariant = "rse",
    results = require("src.core.game3.battle.results_rs"),
    trainerParty = require("src.core.game3.battle.trainer_rs"),
    environmentModule = "src.core.game3.battle.env_rs",
    aiFlagBits = {
      CHECK_BAD_MOVE = 0, CHECK_VIABILITY = 1, TRY_TO_FAINT = 2,
      SETUP_FIRST_TURN = 3, RISKY = 4, PREFER_STRONGEST_MOVE = 5,
      PREFER_BATON_PASS = 6, HP_AWARE = 8, UNKNOWN = 9,
      ROAMING = 29, SAFARI = 30, FIRST_BATTLE = 31,
    },
    kinds = { firstBattle = "birch", tutorial = "wally", ghost = false,
      pokedude = false, twoOpponents = false },
    -- pokeruby/src/battle_controllers.c:82
    firstBattle = { species = "SPECIES_POOCHYENA", level = 2,
      transition = "B_TRANSITION_BLUR", cantRun = "BattleText_BirchDontLeaveMe" },
    rules = {
      faintFriendshipPolicy = require("src.core.game3.battle.faint_friendship_rs"),
      effectChanceOpcode = require("src.core.game3.battle.effect_chance_rs"),
      damageAdjustment = require("src.core.game3.battle.damage_adjustment_rs"),
      sequencingPolicy = require("src.core.game3.battle.sequencing_rs"),
      multiHitMoveEnd = require("src.core.game3.battle.move_end_rs"),
      partyStatusHealPolicy = require("src.core.game3.battle.party_status_rs"),
      -- pokeruby/src/battle_util.c:990
      shedSkinClearsNightmare = false,
      nightmareRequiresSleep = false,
      partyStatusHealClearsNightmare = false,
      -- pokeruby/src/battle_util.c:3488
      obedienceFocusPunchExempt = false,
      -- pokeruby/src/battle_script_commands.c:1401
      critExclusions = { firstBattle = true, wallyTutorial = true },
      -- pokeruby/src/battle_script_commands.c:3341
      noExp = { link = true, safari = true, battleTower = true, eReader = true },
      -- pokeruby/src/battle_script_commands.c:1005
      pickup = "rs_flat",
      pickupItems = {
        { "ITEM_SUPER_POTION", 30 }, { "ITEM_FULL_HEAL", 40 }, { "ITEM_ULTRA_BALL", 50 },
        { "ITEM_RARE_CANDY", 60 }, { "ITEM_FULL_RESTORE", 70 }, { "ITEM_REVIVE", 80 },
        { "ITEM_NUGGET", 90 }, { "ITEM_PROTEIN", 95 }, { "ITEM_PP_UP", 99 }, { "ITEM_KINGS_ROCK", 1 },
      },
      pickupGame = game,
      -- pokeruby/src/battle_script_commands.c:5456
      money = "rse", moneyMessageAlways = true, lostText = "rse", secretBasePrize = true,
      -- pokeruby/src/overworld.c:209
      whiteout = "half",
      -- pokeruby/src/battle_ai_script_commands.c:330
      legendaryAi = false, wildScriptedAi = false,
      -- pokeruby/src/battle_util.c:2696
      amuletCoinPlayerOnly = false,
      -- pokeruby/src/battle_script_commands.c:8559
      futureAttackSideStatus = false,
      -- pokeruby/src/battle_ai_script_commands.c:320
      aiDoubles = "single_target", aiDoublesFlag = false, aiMoveSelection = "rs",
      -- pokeruby/src/battle_ai_script_commands.c:440
      aiMoveHistory = "rs_position",
    },
    strings = { caught = "BattleText_BallCaught1", legendaryIntro = "BattleText_WildAppeared2",
      safariPrompt = "BattleText_PlayerMenu", safariBallsLeft = "BattleText_SafariBallsLeft",
      hmCantForget = "gOtherText_CantForgetHMs" },
    -- pokeruby/src/pokeball.c:825
    sounds = { caughtIntro = "MUS_EVOLVED", caught = "MUS_CAUGHT" },
    -- pokeruby/src/pokemon_3.c:1112
    music = {
      wild = "MUS_VS_WILD", trainer = "MUS_VS_TRAINER", link = "MUS_VS_TRAINER",
      kinds = { kyogreGroudon = "MUS_VS_KYOGRE_GROUDON", regi = "MUS_VS_REGI" },
      byClass = {
        { classes = { "TRAINER_CLASS_AQUA_LEADER", "TRAINER_CLASS_MAGMA_LEADER" }, song = "MUS_VS_AQUA_MAGMA_LEADER" },
        { classes = { "TRAINER_CLASS_TEAM_AQUA", "TRAINER_CLASS_TEAM_MAGMA", "TRAINER_CLASS_AQUA_ADMIN", "TRAINER_CLASS_MAGMA_ADMIN" }, song = "MUS_VS_AQUA_MAGMA" },
        { classes = { "TRAINER_CLASS_LEADER" }, song = "MUS_VS_GYM_LEADER" },
        { classes = { "TRAINER_CLASS_CHAMPION" }, song = "MUS_VS_CHAMPION" },
        { classes = { "TRAINER_CLASS_POKEMON_TRAINER_3" }, song = "MUS_VS_RIVAL" },
        { classes = { "TRAINER_CLASS_ELITE_FOUR" }, song = "MUS_VS_ELITE_FOUR" },
      },
      rivalClass = "TRAINER_CLASS_POKEMON_TRAINER_3", rivalWallyText = "BattleText_Wally",
      -- pokeruby/src/battle_main.c:4941
      victoryWild = "MUS_VICTORY_WILD", victoryTrainer = "MUS_VICTORY_TRAINER",
      victoryByClass = {
        { classes = { "TRAINER_CLASS_ELITE_FOUR", "TRAINER_CLASS_CHAMPION" }, song = "MUS_VICTORY_LEAGUE" },
        { classes = { "TRAINER_CLASS_TEAM_AQUA", "TRAINER_CLASS_TEAM_MAGMA", "TRAINER_CLASS_AQUA_ADMIN", "TRAINER_CLASS_AQUA_LEADER", "TRAINER_CLASS_MAGMA_ADMIN", "TRAINER_CLASS_MAGMA_LEADER" }, song = "MUS_VICTORY_AQUA_MAGMA" },
        { classes = { "TRAINER_CLASS_LEADER" }, song = "MUS_VICTORY_GYM_LEADER" },
      },
    },
    animCacheFallback = false,
    -- pokeruby/include/constants/trainers.h:193
    backPics = { wally = 2 },
    -- pokeruby/src/battle_setup.c:599
    legendary = { default = game == "sapphire" and "SPECIES_KYOGRE" or "SPECIES_GROUDON",
      SPECIES_GROUDON = { kind = "groudon", transition = "B_TRANSITION_SHARDS", song = "MUS_VS_KYOGRE_GROUDON" },
      SPECIES_KYOGRE = { kind = "kyogre", transition = "B_TRANSITION_RIPPLE", song = "MUS_VS_KYOGRE_GROUDON" },
      SPECIES_RAYQUAZA = { kind = "rayquaza", transition = "B_TRANSITION_BLUR", song = "MUS_VS_KYOGRE_GROUDON" },
    },
    -- pokeruby/src/battle_setup.c:612
    regi = { song = "MUS_VS_REGI", default = "B_TRANSITION_GRID_SQUARES" },
    kyogreGroudon = { transition = game == "sapphire" and "B_TRANSITION_RIPPLE" or "B_TRANSITION_SHARDS", song = "MUS_VS_KYOGRE_GROUDON" },
    -- pokeruby/include/constants/species.h:1282
    roamer = { fixedSpecies = game == "sapphire" and "SPECIES_LATIAS" or "SPECIES_LATIOS",
      level = 40, encounterOdds = 4, moveOdds = 16, locations = "data/generated/gba/roamer/locations.lua" },
    -- pokeruby/src/safari_zone.c:57
    safari = { kind = "pokeblock_gonear", actions = { "ball", "pokeblock", "go_near", "run" },
      balls = 30, steps = 500, flag = "FLAG_SYS_SAFARI_MODE", escapeFactor = 3,
      tables = "data/generated/gba/safari/rse_tables.lua",
      timesUp = "gUnknown_081C3448", outOfBalls = "gUnknown_081C3459",
      outOfBallsMidBattle = "gUnknown_081C340A", retire = "gUnknown_081C342D" },
  }
end

return Battle
