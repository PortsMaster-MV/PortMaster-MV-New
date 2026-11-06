return function(V)
  local A, sym, count = V.AUDIO, V.sym, V.count
  -- pokeruby/src/sound.c:38
  A.fanfares = sym("sound.o:sFanfares")
  A.fanfare_count = count("sound.o:sFanfares", 4)
  -- pokeruby/src/pokemon_3.c:463
  A.cry_id_table = sym("gSpeciesIdToCryId")
  A.cry_id_count = count("gSpeciesIdToCryId", 2)
  A.cry_table_reverse_count = count("gCryTable2", 12)
  A.cry_id_species_count = require("src.core.game3.constants").of(V.GAME):require("species", "SPECIES_EGG")
  A.roles = {
    underwater = "MUS_UNDERWATER", intro = "MUS_INTRO", introBattle = "MUS_INTRO_BATTLE",
    abnormalWeather = "MUS_ABNORMAL_WEATHER", battleRival = "MUS_VS_RIVAL",
    battleAquaMagma = "MUS_VS_AQUA_MAGMA", battleEliteFour = "MUS_VS_ELITE_FOUR",
  }
end
