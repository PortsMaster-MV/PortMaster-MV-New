return function(V)
  local sym, count, S = V.sym, V.count, V.SYMS
  -- pokeruby/src/event_object_movement.c:536
  V.OBJ_PALETTE_SLOT_TAGS = sym("gObjectPaletteTags0")
  V.OBJ_PALETTE_SLOT_COUNT = count("gObjectPaletteTags0", 2)
  V.OW_SPRITE_PALETTE_COUNT = count("sObjectEventSpritePalettes", 8)
  V.OW_REFLECTION = {
    palette_map = sym("gReflectionEffectPaletteMap"), palette_map_count = S.size("gReflectionEffectPaletteMap"),
    palette_tag_sets = sym("gObjectPaletteTagSets"), palette_set_count = count("gObjectPaletteTagSets", 4),
    palette_tag_slot_count = count("gObjectPaletteTags0", 2),
    player_palette_sets = sym("gPlayerReflectionPaletteSets"), special_palette_sets = sym("gSpecialObjectReflectionPaletteSets"),
    paired_palette_count = count("gPlayerReflectionPaletteTags", 2), paired_palette_stride = 8,
  }
  -- pokeruby/src/event_object_movement.c:443
  V.FC_REFLECTION = {
    map = sym("gReflectionEffectPaletteMap"),
    player = sym("gPlayerReflectionPaletteSets"), player_size = S.size("gPlayerReflectionPaletteSets"),
    special = sym("gSpecialObjectReflectionPaletteSets"), special_size = S.size("gSpecialObjectReflectionPaletteSets"),
    tag_none = 0x11FF,
  }
  -- pokeruby/src/field_player_avatar.c:199
  V.PLAYER_AVATAR_GFX = {
    genders = 2, stateNames = { "NORMAL", "MACH_BIKE", "ACRO_BIKE", "SURFING", "UNDERWATER", "FIELD_MOVE", "FISHING", "WATERING" },
    player = sym("sPlayerAvatarGfxIds"), player_states = count("sPlayerAvatarGfxIds", 2),
    rival = sym("sRivalAvatarGfxIds"), rival_states = count("sRivalAvatarGfxIds", 2),
    state_flags = sym("gUnknown_0830FC64"), state_flag_count = S.size("gUnknown_0830FC64") / 4,
  }
  -- pokeruby/src/data/field_effects/field_effect_object_template_pointers.h:45
  V.FIELD_EFFECT_OBJECTS = {
    templates = sym("gFieldEffectObjectTemplatePointers"), count = count("gFieldEffectObjectTemplatePointers", 4),
    scripts = sym("gFieldEffectScriptPointers"), script_count = count("gFieldEffectScriptPointers", 4),
    template_prefix = "gFieldEffectSpriteTemplate_",
    requiredFiles = {"pokeball_glow.idx", "pokeball_glow.pal", "pokecenter_monitor.rgba"},
    names = { [22] = "sparkle", [28] = "sand_disguise_placeholder", [35] = "small_sparkle" },
    extras = {
      { name = "exclamation_question_mark", template = sym("trainer_see.o:gSpriteTemplate_839B510") },
      { name = "heart_icon", template = sym("trainer_see.o:gSpriteTemplate_839B528") },
      { name = "pokeball_glow", template = sym("gSpriteTemplate_839F208") },
      { name = "pokecenter_monitor", template = sym("gSpriteTemplate_839F220"), frame = {24, 16} },
      { name = "hof_monitor_big", template = sym("gSpriteTemplate_839F238") },
      { name = "hof_monitor_small", template = sym("gSpriteTemplate_839F250") },
      { name = "cut_grass", template = sym("fldeff_cut.o:sSpriteTemplate_CutGrass") },
      { name = "secret_power_cave", template = sym("sSpriteTemplate_CaveEntrance") },
      { name = "secret_power_tree", template = sym("sSpriteTemplate_TreeEntrance") },
      { name = "secret_power_shrub", template = sym("sSpriteTemplate_ShrubEntrance") },
      { name = "record_mix_lights", template = sym("sSpriteTemplate_83D2894"), palette = sym("sUnknown_083D2878") },
    },
  }
  -- pokeruby/src/field_effect.c:46
  V.FIELD_MOVE_STREAKS = {}
  for _, row in ipairs({ {"outdoors", "gFieldMoveStreaks"}, {"indoors", "gDarknessFieldMoveStreaks"} }) do
    local p = row[2]
    V.FIELD_MOVE_STREAKS[row[1]] = { gfx = sym(p .. "Tiles"), pal = sym(p .. "Palette"),
      tilemap = sym(p .. "Tilemap"), tiles = count(p .. "Tiles", 32) }
  end
  -- pokeruby/src/field_door.c:355
  V.DOOR_GRAPHICS_TABLE = sym("field_door.o:gDoorAnimGraphicsTable")
  V.DOOR_GRAPHICS_COUNT = count("field_door.o:gDoorAnimGraphicsTable", 12)
  V.DOOR_ANIM_FRAMES = { open = sym("field_door.o:gDoorOpenAnimFrames"), close = sym("field_door.o:gDoorCloseAnimFrames") }
  -- pokeruby/src/fldeff_flash.c:67
  V.CAVE_TRANSITION = { white_pal = sym("gCaveTransitionPalette_White"), black_pal = sym("gCaveTransitionPalette_Black"),
    pal = sym("gUnknown_083F808C"), tilemap = sym("gCaveTransitionTilemap"), tiles = sym("gCaveTransitionTiles") }
  -- pokeruby/src/data/object_events/berry_tree_graphics_tables.h:432
  V.BERRY_TREE_GFX = { pics = sym("gBerryTreePicTablePointers"), count = count("gBerryTreePicTablePointers", 4),
    palette_slots = sym("gBerryTreePaletteSlotTablePointers"), gfx_ids = sym("gBerryTreeGraphicsIdTablePointers"), stages = 5 }
  -- pokeruby/src/rotating_gate.c:270
  V.ROTATING_GATE = { sheets = sym("sRotatingGatesGraphicsTable"), sheet_count = count("sRotatingGatesGraphicsTable", 8),
    templates = { sym("sSpriteTemplate_RotatingGateLarge"), sym("sSpriteTemplate_RotatingGateRegular") },
    puzzles = { fortree = { off = sym("sRotatingGate_FortreePuzzleConfig"), count = count("sRotatingGate_FortreePuzzleConfig", 8) },
      trick_house = { off = sym("sRotatingGate_TrickHousePuzzleConfig"), count = count("sRotatingGate_TrickHousePuzzleConfig", 8) } } }
  -- pokeruby/src/field_weather_effects.c:16
  local W = { palettes = { fog = sym("gUnknown_083970E8"), clouds = sym("gUnknown_08397108"), sandstorm = sym("gUnknown_08397128") },
    blobs = {}, color_map_types = sym("sBasePaletteGammaTypes"), color_map_types_size = S.size("sBasePaletteGammaTypes"),
    drought_compressed = {}, cycles = {} }
  for _, row in ipairs({
    {"fog_h", "fog_horizontal", "gWeatherFog1Tiles", "sFog1SpriteTemplate", "fog"},
    {"fog_d", "fog_diagonal", "gWeatherFog2Tiles", "sFog2SpriteTemplate", "fog"},
    {"cloud", "cloud", "gWeatherCloudTiles", "sCloudSpriteTemplate", "clouds"},
    {"rain", "rain", "gWeatherRainTiles", "sRainSpriteTemplate", "fog"},
    {"snow_1", "snow_1", "gWeatherSnow1Tiles", "sSnowflakeSpriteTemplate", "fog"},
    {"snow_2", "snow_2", "gWeatherSnow2Tiles", "sSnowflakeSpriteTemplate", "fog"},
    {"ash", "ash", "gWeatherAshTiles", "sAshSpriteTemplate", "fog"},
    {"sandstorm", "sandstorm", "gWeatherSandstormTiles", "sSandstormSpriteTemplate", "sandstorm"},
    {"bubble", "bubble", "gWeatherBubbleTiles", "gSpriteTemplate_839ACBC", "fog"},
  }) do W.blobs[#W.blobs + 1] = { key = row[1], file = row[2], tiles = sym(row[3]), size = S.size(row[3]), template = sym(row[4]), pal = row[5] } end
  for i = 0, 5 do W.drought_compressed[i + 1] = sym("DroughtPaletteData_" .. i) end
  for _, name in ipairs({"route119", "route123"}) do
    local key = "sWeatherCycleRoute" .. name:sub(6)
    W.cycles[name] = { off = sym(key), count = S.size(key) }
  end
  V.WEATHER_GFX = W
end
