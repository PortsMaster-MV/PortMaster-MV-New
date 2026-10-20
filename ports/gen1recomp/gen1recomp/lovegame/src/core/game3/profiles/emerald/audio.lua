return {
  -- pokeemerald/src/overworld.c:1142
  mapMusicPolicy = "rse",
  -- pokeemerald/src/sound.c:572
  questLogGating = false,
  -- pokeemerald/src/sound.c:422
  cryModeOverrides = { [6] = { volume = 70 } },
  rideSongs = { cycling = "MUS_CYCLING", surf = "MUS_SURF", underwater = "MUS_UNDERWATER" },
  -- pokeemerald/src/sound.c:226
  fanfareFallback = "MUS_LEVEL_UP",
  -- pokeemerald/src/battle_setup.c:519
  legendaryBattleSongs = {
    SPECIES_GROUDON = "MUS_VS_KYOGRE_GROUDON",
    SPECIES_KYOGRE = "MUS_VS_KYOGRE_GROUDON",
    SPECIES_RAYQUAZA = "MUS_VS_RAYQUAZA",
    SPECIES_DEOXYS = "MUS_RG_VS_DEOXYS",
    SPECIES_LUGIA = "MUS_RG_VS_LEGEND",
    SPECIES_HO_OH = "MUS_RG_VS_LEGEND",
    SPECIES_MEW = "MUS_VS_MEW",
  },
  -- pokeemerald/src/battle_setup.c:521
  legendaryBattleDefault = "MUS_VS_KYOGRE_GROUDON",
}
