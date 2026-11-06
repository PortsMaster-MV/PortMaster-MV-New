return function(V)
  local sym = V.sym

  -- pokeemerald/src/roamer.c:35
  V.ROAMER_LOCATIONS = {
    off = sym("sRoamerLocations"),
    size = V.SYMS.size("sRoamerLocations"),
    stride = 6,
    -- pokeemerald/src/roamer.c:9
    mapGroup = 0,
  }

  -- pokeemerald/src/battle_util.c:52
  V.SAFARI_RSE = {
    pkblToEscape = sym("sPkblToEscapeFactor"),
    pkblToEscapeSize = V.SYMS.size("sPkblToEscapeFactor"),
    goNearCatch = sym("sGoNearCounterToCatchFactor"),
    goNearCatchSize = V.SYMS.size("sGoNearCounterToCatchFactor"),
    goNearEscape = sym("sGoNearCounterToEscapeFactor"),
    goNearEscapeSize = V.SYMS.size("sGoNearCounterToEscapeFactor"),
    -- pokeemerald/src/pokeblock.c:136
    flavorCompat = sym("gPokeblockFlavorCompatibilityTable"),
    flavorCompatSize = V.SYMS.size("gPokeblockFlavorCompatibilityTable"),
  }
end
