local Constants = require("src.core.game3.constants")

return function(V)
  local sym, count = V.sym, V.count
  local C = Constants.of("emerald")

  V.SPECIES_UNOWN_B = C:require("species", "SPECIES_UNOWN_B")
  V.SPECIES_UNOWN_QMARK = C:require("species", "SPECIES_UNOWN_QMARK")

  -- pokeemerald/src/data/pokemon_graphics/front_pic_table.h:1
  V.MON_FRONT_PIC_ANIM = true
  -- pokeemerald/src/decompress.c:407
  V.MON_PIC_DUPLICATE_DEOXYS = true
  -- pokeemerald/src/pokemon_icon.c:1191
  V.MON_ICON_DEOXYS_OFFSET = V.MON_ICON_BYTES
  V.MON_ICON_COUNT = count("gMonIconTable", 4)
  V.MON_PIC_TABLE_COUNT = count("gMonFrontPicTable", 8)

  V.MON_PIC_COORDS_STRIDE = 4
  V.MON_PIC_COORDS_COUNT = count("gMonFrontPicCoords", V.MON_PIC_COORDS_STRIDE)
  V.ENEMY_MON_ELEVATION_COUNT = count("gEnemyMonElevation", 1)

  -- pokeemerald/src/pokedex.c:4583
  V.MON_FOOTPRINT_TABLE = sym("gMonFootprintTable")
  V.MON_FOOTPRINT_COUNT = count("gMonFootprintTable", 4)
  V.MON_FOOTPRINT_COLOR_IDX = 2

  -- pokeemerald/include/constants/global.h:107
  V.TYPE_NAME_LENGTH = 6
  V.TYPE_NAMES = sym("gTypeNames")
  V.TYPE_COUNT = count("gTypeNames", V.TYPE_NAME_LENGTH + 1)
  -- pokeemerald/src/data/pokemon/experience_tables.h:18
  V.EXPERIENCE_TABLES = sym("gExperienceTables")
  V.EXPERIENCE_LEVELS = 101
  V.GROWTH_RATE_COUNT = count("gExperienceTables", V.EXPERIENCE_LEVELS * 4)

  -- pokeemerald/src/data/pokemon_graphics/front_pic_anims.h:5255
  V.MON_FRONT_ANIMS_PTR_TABLE = sym("gMonFrontAnimsPtrTable")
  V.MON_FRONT_ANIMS_COUNT = count("gMonFrontAnimsPtrTable", 4)
  -- pokeemerald/src/data.c:320
  V.MON_FRONT_ANIMS_OBJ = "data.o"
  -- pokeemerald/src/pokemon.c:1405
  V.MON_FRONT_ANIM_IDS = sym("pokemon.o:sMonFrontAnimIdsTable")
  V.MON_FRONT_ANIM_IDS_COUNT = count("pokemon.o:sMonFrontAnimIdsTable", 1)
  -- pokeemerald/src/pokemon.c:1795
  V.MON_ANIMATION_DELAYS = sym("pokemon.o:sMonAnimationDelayTable")
  V.MON_ANIMATION_DELAYS_COUNT = count("pokemon.o:sMonAnimationDelayTable", 1)
  -- pokeemerald/src/pokemon_animation.c:213
  V.MON_BACK_ANIM_SETS = sym("pokemon_animation.o:sSpeciesToBackAnimSet")
  V.MON_BACK_ANIM_SETS_COUNT = count("pokemon_animation.o:sSpeciesToBackAnimSet", 1)
  -- pokeemerald/src/pokemon_animation.c:788
  V.MON_BACK_ANIM_IDS = sym("pokemon_animation.o:sBackAnimationIds")
  V.MON_BACK_ANIM_IDS_COUNT = count("pokemon_animation.o:sBackAnimationIds", 1)
  -- pokeemerald/src/pokemon_animation.c:817
  V.MON_BACK_NATURE_MODS = sym("pokemon_animation.o:sBackAnimNatureModTable")
  V.MON_BACK_NATURE_MODS_COUNT = count("pokemon_animation.o:sBackAnimNatureModTable", 1)
  -- pokeemerald/src/pokemon_animation.c:630
  V.MON_ANIM_FUNCTIONS = sym("pokemon_animation.o:sMonAnimFunctions")
  V.MON_ANIM_FUNCTIONS_COUNT = count("pokemon_animation.o:sMonAnimFunctions", 4)

  -- pokeemerald/src/egg_hatch.c:85
  V.EGG_PALETTE = sym("egg_hatch.o:sEggPalette")
  V.EGG_HATCH_GFX = sym("egg_hatch.o:sEggHatchTiles")
  V.EGG_SHARD_GFX = sym("egg_hatch.o:sEggShardTiles")
end
