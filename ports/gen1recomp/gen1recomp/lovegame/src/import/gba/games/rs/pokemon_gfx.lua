return function(V)
  local C = require("src.core.game3.constants").of(V.GAME)
  local sym, count = V.sym, V.count
  V.SPECIES_UNOWN_B = C:require("species", "SPECIES_UNOWN_B")
  V.SPECIES_UNOWN_QMARK = C:require("species", "SPECIES_UNOWN_QMARK")
  V.MON_FRONT_PIC_ANIM = false
  V.MON_PIC_DUPLICATE_DEOXYS = false
  V.MON_ICON_COUNT = count("gMonIconTable", 4)
  V.MON_PIC_TABLE_COUNT = count("gMonFrontPicTable", 8)
  V.MON_PIC_COORDS_STRIDE = 4
  V.MON_PIC_COORDS_COUNT = count("gMonFrontPicCoords", 4)
  V.ENEMY_MON_ELEVATION_COUNT = count("gEnemyMonElevation", 1)
  V.MON_FOOTPRINT_TABLE = sym("pokedex.o:sMonFootprintTable")
  V.MON_FOOTPRINT_COUNT = count("pokedex.o:sMonFootprintTable", 4)
  V.MON_FOOTPRINT_COLOR_IDX = 2
  V.TYPE_NAME_LENGTH = 6
  V.TYPE_NAMES = sym("gTypeNames")
  V.TYPE_COUNT = 18 -- pokeruby/include/constants/pokemon.h:119
  V.EXPERIENCE_TABLES = sym("gExperienceTables")
  V.EXPERIENCE_LEVELS = 101 -- pokeruby/include/constants/pokemon.h:95 MAX_LEVEL + 1
  V.GROWTH_RATE_COUNT = count("gExperienceTables", V.EXPERIENCE_LEVELS * 4)
  V.EGG_PALETTE = sym("egg_hatch.o:sEggPalette")
  V.EGG_HATCH_GFX = sym("egg_hatch.o:sEggHatchTiles")
  V.EGG_SHARD_GFX = sym("egg_hatch.o:sEggShardTiles")
end
