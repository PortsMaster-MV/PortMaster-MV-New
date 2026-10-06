return function(V)
  local sym, count = V.sym, V.count

  -- pokeemerald/src/diploma.c:41
  V.DIPLOMA = {
    gfx = sym("sDiplomaTiles"),
    tilemap = sym("sDiplomaTilemap"),
    palettes = sym("sDiplomaPalettes"),
    gfxSize = count("sDiplomaTiles", 1),
    tilemapSize = count("sDiplomaTilemap", 1),
    paletteSize = count("sDiplomaPalettes", 1),
  }

  -- pokeemerald/include/constants/wild_encounter.h:11
  V.LAND_WILD_COUNT = count("gRoute101_LandMons", 4)
  V.WATER_WILD_COUNT = count("gRoute103_WaterMons", 4)
  V.ROCK_WILD_COUNT = count("gRoute111_RockSmashMons", 4)
  V.FISH_WILD_COUNT = count("gRoute103_FishingMons", 4)
  -- pokeemerald/src/data/wild_encounters.h:4150
  V.WILD_EXTRA_HEADERS = {
    pyramid = { off = sym("gBattlePyramidWildMonHeaders"),
      count = count("gBattlePyramidWildMonHeaders", V.WILD_MON_HEADER_SIZE) },
    pike = { off = sym("gBattlePikeWildMonHeaders"),
      count = count("gBattlePikeWildMonHeaders", V.WILD_MON_HEADER_SIZE) },
  }
  -- pokeemerald/src/wild_encounter.c:67
  V.FEEBAS_WILD_MON = sym("wild_encounter.o:sWildFeebas")
  V.FEEBAS_TILE_DATA = sym("wild_encounter.o:sRoute119WaterTileData")
  V.FEEBAS_TILE_DATA_COUNT = count("wild_encounter.o:sRoute119WaterTileData", 6)
  -- pokeemerald/src/pokemon.c:2114
  V.ALTERING_CAVE_HELD_ITEMS = sym("pokemon.o:sAlteringCaveWildMonHeldItems")
  V.ALTERING_CAVE_HELD_ITEM_COUNT = count("pokemon.o:sAlteringCaveWildMonHeldItems", 4)

  -- pokeemerald/src/region_map.c:289
  V.MAP_HEAL_LOCATIONS = sym("region_map.o:sMapHealLocations")
  V.MAP_HEAL_LOCATION_COUNT = count("region_map.o:sMapHealLocations", 3)

  -- pokeemerald/include/constants/region_map_sections.h:231
  V.KANTO_MAPSEC_START = 88
  V.REGION_MAP_ENTRY_COUNT = count("gRegionMapEntries", 8)
  -- pokeemerald/src/map_name_popup.c:75
  V.MAPSEC_THEME_IDS = sym("map_name_popup.o:sMapSectionToThemeId")
  V.MAPSEC_THEME_COUNT = count("map_name_popup.o:sMapSectionToThemeId", 1)
  V.KANTO_MAPSEC_COUNT = V.REGION_MAP_ENTRY_COUNT - V.MAPSEC_THEME_COUNT
  -- pokeemerald/src/map_name_popup.c:40
  V.MAP_POPUP = {
    frames = sym("map_name_popup.o:sMapPopUp_Table"),
    outlines = sym("map_name_popup.o:sMapPopUp_OutlineTable"),
    palettes = sym("map_name_popup.o:sMapPopUp_PaletteTable"),
    underwaterPalette = sym("map_name_popup.o:sMapPopUp_Palette_Underwater"),
    themeCount = count("map_name_popup.o:sMapPopUp_PaletteTable", 32),
    frameBytes = 960,
  }
end
