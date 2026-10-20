return function(V)
  local sym, S = V.sym, V.SYMS
  local edition = V.GAME == "ruby" and "Ruby" or "Sapphire"
  -- pokeruby/src/data/wild_encounters.h:48
  V.LAND_WILD_COUNT = S.count("Route101_" .. edition .. "_LandMons", 4)
  V.WATER_WILD_COUNT = S.count("Route103_" .. edition .. "_WaterMons", 4)
  V.ROCK_WILD_COUNT = S.count("Route111_" .. edition .. "_RockSmashMons", 4)
  V.FISH_WILD_COUNT = S.count("Route103_" .. edition .. "_FishingMons", 4)
  -- pokeruby/src/region_map.c:1165
  V.MAP_HEAL_LOCATIONS = sym("sMapHealLocations")
  V.MAP_HEAL_LOCATION_COUNT = S.count("sMapHealLocations", 3)
  V.REGION_MAP_ENTRY_COUNT = S.count("gRegionMapEntries", 8)
  -- pokeruby/src/roamer.c:18
  V.ROAMER_LOCATIONS = {off = sym("sRoamerLocations"), size = S.size("sRoamerLocations"), stride = 6, mapGroup = 0}
end
