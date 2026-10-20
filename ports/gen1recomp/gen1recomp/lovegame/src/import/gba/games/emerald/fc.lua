return function(V)
  local sym, count = V.sym, V.count

  -- pokeemerald/src/event_object_movement.c:182
  V.FC_REFLECTION = {
    map = sym("gReflectionEffectPaletteMap"),
    player = sym("event_object_movement.o:sPlayerReflectionPaletteSets"),
    player_size = V.SYMS.size("event_object_movement.o:sPlayerReflectionPaletteSets"),
    special = sym("event_object_movement.o:sSpecialObjectReflectionPaletteSets"),
    special_size = V.SYMS.size("event_object_movement.o:sSpecialObjectReflectionPaletteSets"),
    -- pokeemerald/src/event_object_movement.c:471
    tag_none = 0x11FF,
  }

  -- pokeemerald/src/field_screen_effect.c:53
  V.FC_FLASH_RADII = {
    off = sym("field_screen_effect.o:sFlashLevelToRadius"),
    count = count("field_screen_effect.o:sFlashLevelToRadius", 2),
  }

  -- pokeemerald/src/mirage_tower.c:79
  V.FC_MIRAGE_TOWER = {
    crumbles = sym("mirage_tower.o:sMirageTowerCrumbles_Gfx"),
    crumbles_size = V.SYMS.size("mirage_tower.o:sMirageTowerCrumbles_Gfx"),
    positions = sym("mirage_tower.o:sCeilingCrumblePositions"),
    positions_count = count("mirage_tower.o:sCeilingCrumblePositions", 6),
    metatiles = sym("mirage_tower.o:sInvisibleMirageTowerMetatiles"),
    metatiles_count = count("mirage_tower.o:sInvisibleMirageTowerMetatiles", 4),
  }
end
