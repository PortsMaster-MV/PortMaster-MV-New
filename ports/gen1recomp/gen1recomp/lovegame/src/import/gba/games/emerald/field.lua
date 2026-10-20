return function(V)
  local sym, count = V.sym, V.count

  -- pokeemerald/src/event_object_movement.c:647
  V.OBJ_PALETTE_SLOT_TAGS = sym("event_object_movement.o:sObjectPaletteTags0")
  V.OBJ_PALETTE_SLOT_COUNT = count("event_object_movement.o:sObjectPaletteTags0", 2)
  V.OW_SPRITE_PALETTE_COUNT = count("event_object_movement.o:sObjectEventSpritePalettes", 8)

  -- pokeemerald/src/data/field_effects/field_effect_object_template_pointers.h:39
  V.FIELD_EFFECT_OBJECTS = {
    templates = sym("gFieldEffectObjectTemplatePointers"),
    count = count("gFieldEffectObjectTemplatePointers", 4),
    scripts = sym("gFieldEffectScriptPointers"),
    script_count = count("gFieldEffectScriptPointers", 4),
    extras = {
      { name = "exclamation_question_mark", template = sym("trainer_see.o:sSpriteTemplate_ExclamationQuestionMark") },
      { name = "heart_icon", template = sym("trainer_see.o:sSpriteTemplate_HeartIcon") },
      { name = "pokeball_glow", template = sym("field_effect.o:sSpriteTemplate_PokeballGlow") },
      -- pokeemerald/src/field_effect.c:413
      { name = "pokecenter_monitor", template = sym("field_effect.o:sSpriteTemplate_PokecenterMonitor"), frame = { 24, 16 } },
      { name = "hof_monitor_big", template = sym("field_effect.o:sSpriteTemplate_HofMonitorBig") },
      { name = "hof_monitor_small", template = sym("field_effect.o:sSpriteTemplate_HofMonitorSmall") },
      { name = "deoxys_rock_fragment", template = sym("field_effect.o:sSpriteTemplate_DeoxysRockFragment") },
      { name = "cut_grass", template = sym("fldeff_cut.o:sSpriteTemplate_CutGrass") },
      { name = "secret_power_cave", template = sym("fldeff_misc.o:sSpriteTemplate_SecretPowerCave") },
      { name = "secret_power_tree", template = sym("fldeff_misc.o:sSpriteTemplate_SecretPowerTree") },
      { name = "secret_power_shrub", template = sym("fldeff_misc.o:sSpriteTemplate_SecretPowerShrub") },
      { name = "sand_pillar", template = sym("fldeff_misc.o:sSpriteTemplate_SandPillar") },
      { name = "record_mix_lights", template = sym("fldeff_misc.o:sSpriteTemplate_RecordMixLights"),
        palette = sym("fldeff_misc.o:sSpritePalette_RecordMixLights") },
    },
    spotlight = {
      gfx = sym("field_effect.o:sSpotlight_Gfx"),
      gfx_size = V.SYMS.size("field_effect.o:sSpotlight_Gfx"),
      pal = sym("field_effect.o:sSpotlight_Pal"),
    },
  }

  -- pokeemerald/src/field_effect.c:258
  V.FIELD_MOVE_STREAKS = {
    outdoors = {
      gfx = sym("field_effect.o:sFieldMoveStreaksOutdoors_Gfx"),
      pal = sym("field_effect.o:sFieldMoveStreaksOutdoors_Pal"),
      tilemap = sym("field_effect.o:sFieldMoveStreaksOutdoors_Tilemap"),
      tiles = count("field_effect.o:sFieldMoveStreaksOutdoors_Gfx", 32),
    },
    indoors = {
      gfx = sym("field_effect.o:sFieldMoveStreaksIndoors_Gfx"),
      pal = sym("field_effect.o:sFieldMoveStreaksIndoors_Pal"),
      tilemap = sym("field_effect.o:sFieldMoveStreaksIndoors_Tilemap"),
      tiles = count("field_effect.o:sFieldMoveStreaksIndoors_Gfx", 32),
    },
  }

  -- pokeemerald/src/field_door.c:223
  V.DOOR_GRAPHICS_TABLE = sym("field_door.o:sDoorAnimGraphicsTable")
  V.DOOR_GRAPHICS_COUNT = count("field_door.o:sDoorAnimGraphicsTable", 12)
  -- pokeemerald/src/field_door.c:135
  V.DOOR_ANIM_FRAMES = {
    open = sym("field_door.o:sDoorOpenAnimFrames"),
    close = sym("field_door.o:sDoorCloseAnimFrames"),
    big_open = sym("field_door.o:sBigDoorOpenAnimFrames"),
    big_close = sym("field_door.o:sBigDoorCloseAnimFrames"),
  }

  -- pokeemerald/src/field_weather_effect.c:20
  V.WEATHER_GFX = {
    palettes = {
      fog = sym("gFogPalette"),
      clouds = sym("gCloudsWeatherPalette"),
      sandstorm = sym("gSandstormWeatherPalette"),
    },
    blobs = {
      { key = "fog_h", file = "fog_horizontal", tiles = sym("gWeatherFogHorizontalTiles"),
        size = V.SYMS.size("gWeatherFogHorizontalTiles"),
        template = sym("field_weather_effect.o:sFogHorizontalSpriteTemplate"), pal = "fog" },
      { key = "fog_d", file = "fog_diagonal", tiles = sym("gWeatherFogDiagonalTiles"),
        size = V.SYMS.size("gWeatherFogDiagonalTiles"),
        template = sym("field_weather_effect.o:sFogDiagonalSpriteTemplate"), pal = "fog" },
      { key = "cloud", file = "cloud", tiles = sym("gWeatherCloudTiles"),
        size = V.SYMS.size("gWeatherCloudTiles"),
        template = sym("field_weather_effect.o:sCloudSpriteTemplate"), pal = "clouds" },
      { key = "rain", file = "rain", tiles = sym("gWeatherRainTiles"),
        size = V.SYMS.size("gWeatherRainTiles"),
        template = sym("field_weather_effect.o:sRainSpriteTemplate"), pal = "fog" },
      { key = "snow_1", file = "snow_1", tiles = sym("gWeatherSnow1Tiles"),
        size = V.SYMS.size("gWeatherSnow1Tiles"),
        template = sym("field_weather_effect.o:sSnowflakeSpriteTemplate"), pal = "fog" },
      { key = "snow_2", file = "snow_2", tiles = sym("gWeatherSnow2Tiles"),
        size = V.SYMS.size("gWeatherSnow2Tiles"),
        template = sym("field_weather_effect.o:sSnowflakeSpriteTemplate"), pal = "fog" },
      { key = "ash", file = "ash", tiles = sym("gWeatherAshTiles"),
        size = V.SYMS.size("gWeatherAshTiles"),
        template = sym("field_weather_effect.o:sAshSpriteTemplate"), pal = "fog" },
      { key = "sandstorm", file = "sandstorm", tiles = sym("gWeatherSandstormTiles"),
        size = V.SYMS.size("gWeatherSandstormTiles"),
        template = sym("field_weather_effect.o:sSandstormSpriteTemplate"), pal = "sandstorm" },
      { key = "bubble", file = "bubble", tiles = sym("gWeatherBubbleTiles"),
        size = V.SYMS.size("gWeatherBubbleTiles"),
        template = sym("field_weather_effect.o:sBubbleSpriteTemplate"), pal = "fog" },
    },
    -- pokeemerald/src/field_weather.c:114
    color_map_types = sym("field_weather.o:sBasePaletteColorMapTypes"),
    color_map_types_size = V.SYMS.size("field_weather.o:sBasePaletteColorMapTypes"),
    -- pokeemerald/src/field_weather.c:70
    drought_colors = sym("field_weather.o:sDroughtWeatherColors"),
    drought_colors_size = V.SYMS.size("field_weather.o:sDroughtWeatherColors"),
    cycles = {
      route119 = { off = sym("field_weather_effect.o:sWeatherCycleRoute119"),
        count = V.SYMS.size("field_weather_effect.o:sWeatherCycleRoute119") },
      route123 = { off = sym("field_weather_effect.o:sWeatherCycleRoute123"),
        count = V.SYMS.size("field_weather_effect.o:sWeatherCycleRoute123") },
    },
  }

  -- pokeemerald/src/fldeff_flash.c:64
  V.CAVE_TRANSITION = {
    white_pal = sym("fldeff_flash.o:sCaveTransitionPalette_White"),
    black_pal = sym("fldeff_flash.o:sCaveTransitionPalette_Black"),
    pal = sym("fldeff_flash.o:sCaveTransitionPalette_Enter"),
    tilemap = sym("fldeff_flash.o:sCaveTransitionTilemap"),
    tiles = sym("fldeff_flash.o:sCaveTransitionTiles"),
  }

  -- pokeemerald/src/data/object_events/berry_tree_graphics_tables.h:425
  V.BERRY_TREE_GFX = {
    pics = sym("gBerryTreePicTablePointers"),
    count = count("gBerryTreePicTablePointers", 4),
    palette_slots = sym("gBerryTreePaletteSlotTablePointers"),
    gfx_ids = sym("gBerryTreeObjectEventGraphicsIdTablePointers"),
    stages = 5,
  }

  -- pokeemerald/src/rotating_gate.c:271
  V.ROTATING_GATE = {
    sheets = sym("rotating_gate.o:sRotatingGatesGraphicsTable"),
    sheet_count = count("rotating_gate.o:sRotatingGatesGraphicsTable", 8),
    templates = {
      sym("rotating_gate.o:sSpriteTemplate_RotatingGateLarge"),
      sym("rotating_gate.o:sSpriteTemplate_RotatingGateRegular"),
    },
    puzzles = {
      fortree = { off = sym("rotating_gate.o:sRotatingGate_FortreePuzzleConfig"),
        count = count("rotating_gate.o:sRotatingGate_FortreePuzzleConfig", 8) },
      trick_house = { off = sym("rotating_gate.o:sRotatingGate_TrickHousePuzzleConfig"),
        count = count("rotating_gate.o:sRotatingGate_TrickHousePuzzleConfig", 8) },
    },
  }
end
