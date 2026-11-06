return {
  family = "rse",
  aiVariant = "rse",
  -- pokeemerald/include/constants/battle_ai.h:38
  aiFlagBits = {
    CHECK_BAD_MOVE = 0,
    TRY_TO_FAINT = 1,
    CHECK_VIABILITY = 2,
    SETUP_FIRST_TURN = 3,
    RISKY = 4,
    PREFER_POWER_EXTREMES = 5,
    PREFER_BATON_PASS = 6,
    DOUBLE_BATTLE = 7,
    HP_AWARE = 8,
    TRY_SUNNY_DAY_START = 9,
    ROAMING = 29,
    SAFARI = 30,
    FIRST_BATTLE = 31,
  },
  kinds = {
    firstBattle = "birch",
    tutorial = "wally",
    ghost = false,
    pokedude = false,
    -- pokeemerald/src/trainer_see.c:191
    twoOpponents = true,
  },
  -- pokeemerald/src/battle_controllers.c:67
  firstBattle = {
    species = "SPECIES_ZIGZAGOON",
    level = 2,
    -- pokeemerald/src/battle_setup.c:927
    transition = "B_TRANSITION_BLUR",
    -- pokeemerald/src/battle_main.c:4078
    cantRun = "STRINGID_DONTLEAVEBIRCH",
  },
  rules = {
    -- pokeemerald/src/battle_util.c:3909
    obedienceFocusPunchExempt = false,
    -- pokeemerald/src/battle_script_commands.c:1281
    critExclusions = { firstBattle = true, wallyTutorial = true },
    -- pokeemerald/src/battle_script_commands.c:3270
    noExp = {
      link = true, recordedLink = true, trainerHill = true, frontier = true,
      safari = true, battleTower = true, eReader = true,
    },
    -- pokeemerald/src/battle_script_commands.c:9654
    pickup = "level_bands",
    -- pokeemerald/src/battle_script_commands.c:5578
    money = "rse",
    -- pokeemerald/data/battle_scripts_1.s:2937
    moneyMessageAlways = true,
    -- pokeemerald/src/overworld.c:361
    whiteout = "half",
    -- pokeemerald/data/battle_scripts_1.s:2951
    lostText = "rse",
    -- pokeemerald/src/battle_ai_script_commands.c:361
    legendaryAi = false,
    wildScriptedAi = false,
    -- pokeemerald/src/battle_util.c:3294
    amuletCoinPlayerOnly = true,
    -- pokeemerald/src/battle_script_commands.c:6487
    teleportOutcome = "side",
    -- pokeemerald/src/battle_util.c:1815
    futureAttackSideStatus = true,
    -- pokeemerald/src/battle_ai_script_commands.c:448
    aiDoubles = "per_target",
    -- pokeemerald/src/battle_ai_script_commands.c:1846
    aiMoveHistory = "battler",
  },
  strings = {
    -- pokeemerald/data/battle_scripts_2.s:68
    caught = "STRINGID_GOTCHAPKMNCAUGHTPLAYER",
    -- pokeemerald/src/battle_message.c:2025
    legendaryIntro = "sText_LegendaryPkmnAppeared",
    -- pokeemerald/src/battle_controller_safari.c:460
    safariPrompt = "gText_WhatWillPkmnDo2",
    -- pokeemerald/src/battle_interface.c:2153
    safariBallsLeft = "gText_SafariBallLeft",
    -- pokeemerald/src/pokemon_summary_screen.c:3739
    hmCantForget = "gText_HMMovesCantBeForgotten2",
  },
  -- pokeemerald/src/battle_anim_throw.c:1332
  sounds = { caughtIntro = "MUS_RG_CAUGHT_INTRO" },
  -- pokeemerald/src/pokemon.c:6426
  music = {
    wild = "MUS_VS_WILD",
    trainer = "MUS_VS_TRAINER",
    link = "MUS_VS_TRAINER",
    kinds = {
      kyogreGroudon = "MUS_VS_KYOGRE_GROUDON",
      regi = "MUS_VS_REGI",
    },
    byClass = {
      { classes = { "TRAINER_CLASS_AQUA_LEADER", "TRAINER_CLASS_MAGMA_LEADER" }, song = "MUS_VS_AQUA_MAGMA_LEADER" },
      { classes = { "TRAINER_CLASS_TEAM_AQUA", "TRAINER_CLASS_TEAM_MAGMA", "TRAINER_CLASS_AQUA_ADMIN",
        "TRAINER_CLASS_MAGMA_ADMIN" }, song = "MUS_VS_AQUA_MAGMA" },
      { classes = { "TRAINER_CLASS_LEADER" }, song = "MUS_VS_GYM_LEADER" },
      { classes = { "TRAINER_CLASS_CHAMPION" }, song = "MUS_VS_CHAMPION" },
      { classes = { "TRAINER_CLASS_RIVAL" }, song = "MUS_VS_RIVAL" },
      { classes = { "TRAINER_CLASS_ELITE_FOUR" }, song = "MUS_VS_ELITE_FOUR" },
      { classes = { "TRAINER_CLASS_SALON_MAIDEN", "TRAINER_CLASS_DOME_ACE", "TRAINER_CLASS_PALACE_MAVEN",
        "TRAINER_CLASS_ARENA_TYCOON", "TRAINER_CLASS_FACTORY_HEAD", "TRAINER_CLASS_PIKE_QUEEN",
        "TRAINER_CLASS_PYRAMID_KING" }, song = "MUS_VS_FRONTIER_BRAIN" },
    },
    -- pokeemerald/src/pokemon.c:6468
    rivalClass = "TRAINER_CLASS_RIVAL",
    rivalWallyText = "gText_BattleWallyName",
    -- pokeemerald/src/battle_main.c:4988
    victoryWild = "MUS_VICTORY_WILD",
    victoryTrainer = "MUS_VICTORY_TRAINER",
    victoryByClass = {
      { classes = { "TRAINER_CLASS_ELITE_FOUR", "TRAINER_CLASS_CHAMPION" }, song = "MUS_VICTORY_LEAGUE" },
      { classes = { "TRAINER_CLASS_TEAM_AQUA", "TRAINER_CLASS_TEAM_MAGMA", "TRAINER_CLASS_AQUA_ADMIN",
        "TRAINER_CLASS_AQUA_LEADER", "TRAINER_CLASS_MAGMA_ADMIN", "TRAINER_CLASS_MAGMA_LEADER" },
        song = "MUS_VICTORY_AQUA_MAGMA" },
      { classes = { "TRAINER_CLASS_LEADER" }, song = "MUS_VICTORY_GYM_LEADER" },
    },
  },
  animCacheFallback = false,
  -- pokeemerald/include/constants/trainers.h:120
  backPics = { wally = 6, steven = 7 },
  -- pokeemerald/src/battle_setup.c:513
  legendary = {
    default = "SPECIES_GROUDON",
    SPECIES_GROUDON = { kind = "groudon", transition = "B_TRANSITION_GROUDON", song = "MUS_VS_KYOGRE_GROUDON" },
    SPECIES_KYOGRE = { kind = "kyogre", transition = "B_TRANSITION_KYOGRE", song = "MUS_VS_KYOGRE_GROUDON" },
    SPECIES_RAYQUAZA = { kind = "rayquaza", transition = "B_TRANSITION_RAYQUAZA", song = "MUS_VS_RAYQUAZA" },
    SPECIES_DEOXYS = { transition = "B_TRANSITION_BLUR", song = "MUS_RG_VS_DEOXYS" },
    SPECIES_LUGIA = { transition = "B_TRANSITION_BLUR", song = "MUS_RG_VS_LEGEND" },
    SPECIES_HO_OH = { transition = "B_TRANSITION_BLUR", song = "MUS_RG_VS_LEGEND" },
    SPECIES_MEW = { transition = "B_TRANSITION_GRID_SQUARES", song = "MUS_VS_MEW" },
  },
  -- pokeemerald/src/battle_setup.c:569
  regi = {
    song = "MUS_VS_REGI",
    default = "B_TRANSITION_GRID_SQUARES",
    SPECIES_REGIROCK = "B_TRANSITION_REGIROCK",
    SPECIES_REGICE = "B_TRANSITION_REGICE",
    SPECIES_REGISTEEL = "B_TRANSITION_REGISTEEL",
  },
  -- pokeemerald/src/battle_setup.c:561
  kyogreGroudon = { transition = "B_TRANSITION_RIPPLE", song = "MUS_VS_KYOGRE_GROUDON" },
  -- pokeemerald/src/battle_tower.c:2122
  steven = {
    partner = "TRAINER_STEVEN",
    opponentA = "TRAINER_MAXIE_MOSSDEEP",
    opponentB = "TRAINER_TABITHA_MOSSDEEP",
    transition = "B_TRANSITION_MAGMA",
    -- pokeemerald/src/battle_tower.c:2957
    otId = 61226,
  },
  -- pokeemerald/src/roamer.c:84
  roamer = {
    species = { [0] = "SPECIES_LATIAS", [1] = "SPECIES_LATIOS" },
    level = 40,
    -- pokeemerald/src/roamer.c:218
    encounterOdds = 4,
    -- pokeemerald/src/roamer.c:153
    moveOdds = 16,
    locations = "data/generated/gba/roamer/locations.lua",
  },
  -- pokeemerald/src/safari_zone.c:55
  safari = {
    kind = "pokeblock_gonear",
    -- pokeemerald/src/battle_controller_safari.c:170
    actions = { "ball", "pokeblock", "go_near", "run" },
    balls = 30,
    steps = 500,
    flag = "FLAG_SYS_SAFARI_MODE",
    -- pokeemerald/src/battle_main.c:3116
    escapeFactor = 3,
    tables = "data/generated/gba/safari/rse_tables.lua",
    timesUp = "SafariZone_EventScript_TimesUp",
    outOfBalls = "SafariZone_EventScript_OutOfBalls",
    outOfBallsMidBattle = "SafariZone_EventScript_OutOfBallsMidBattle",
    retire = "SafariZone_EventScript_RetirePrompt",
  },
}
