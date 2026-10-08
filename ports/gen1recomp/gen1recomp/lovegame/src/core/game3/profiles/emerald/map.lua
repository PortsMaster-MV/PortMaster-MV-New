return {
  prefixes = { "EM_" },
  enginePrefix = "EM_",
  legacyPrefixes = {},
  kindsFromMapType = true,
  strictConnections = true,
  -- pokeemerald/src/fieldmap.c:603
  scriptConnections = true,
  -- pokeemerald/src/field_control_avatar.c:159
  scriptStepEvents = false,
  -- pokeemerald/src/field_screen_effect.c:317
  onFrameAfterWarpExit = true,
  fieldModules = { unionPlaza = true },
  -- pokeemerald/src/overworld.c:682
  escapeWarp = { delta = 1 },
  semantics = {
    -- pokeemerald/include/constants/vars.h:51
    vars = {
      happinessSteps = "VAR_FRIENDSHIP_STEP_COUNTER",
      poisonSteps = "VAR_POISON_STEP_COUNTER",
      repelSteps = "VAR_REPEL_STEP_COUNT",
    },
    -- pokeemerald/include/constants/flags.h:1398
    flags = {
      flashActive = "FLAG_SYS_USE_FLASH",
    },
  },
  -- pokeemerald/src/event_data.c:43
  tempFieldEventFlags = {
    "FLAG_SYS_ENC_UP_ITEM", "FLAG_SYS_ENC_DOWN_ITEM", "FLAG_SYS_USE_STRENGTH",
    "FLAG_SYS_CTRL_OBJ_DELETE", "FLAG_NURSE_UNION_ROOM_REMINDER",
  },
  -- pokeemerald/src/new_game.c:127 WarpToTruck, pokeemerald/src/overworld.c:621
  newGameStart = {
    map = "EM_INSIDE_OF_TRUCK",
    group = "MAP_INSIDE_OF_TRUCK",
    x = 2,
    y = 2,
    -- pokeemerald/src/overworld.c:879
    facing = "down",
  },
}
