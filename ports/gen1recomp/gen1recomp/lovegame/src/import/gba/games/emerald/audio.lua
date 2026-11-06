return function(V)
  local sym, count = V.sym, V.count
  local A = V.AUDIO
  -- pokeemerald/src/sound.c:37
  A.fanfares = sym("sFanfares")
  A.fanfare_count = count("sFanfares", 4)
  -- pokeemerald/src/pokemon.c:5701
  A.cry_id_table = sym("gSpeciesIdToCryId")
  A.cry_id_count = count("gSpeciesIdToCryId", 2)
  A.cry_table_reverse_count = count("gCryTable_Reverse", 12)
  A.roles = {
    underwater = "MUS_UNDERWATER",
    intro = "MUS_INTRO",
    introBattle = "MUS_INTRO_BATTLE",
    abnormalWeather = "MUS_ABNORMAL_WEATHER",
    battleRival = "MUS_VS_RIVAL",
    battleAquaMagma = "MUS_VS_AQUA_MAGMA",
    battleEliteFour = "MUS_VS_ELITE_FOUR",
  }
end
