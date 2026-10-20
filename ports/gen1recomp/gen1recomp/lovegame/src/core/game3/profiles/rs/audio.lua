local Audio = {}

function Audio.new(game)
  return {
    -- pokeruby/src/overworld.c:899
    mapMusicPolicy = "rs",
    questLogGating = false,
    -- pokeruby/src/overworld.c:53
    legendaryWeatherSong = game == "sapphire" and "MUS_WEATHER_KYOGRE" or "MUS_WEATHER_GROUDON",
    rideSongs = { cycling = "MUS_CYCLING", surf = "MUS_SURF", underwater = "MUS_UNDERWATER" },
    -- pokeruby/src/sound.c:212
    fanfareFallback = "MUS_LEVEL_UP",
    -- pokeruby/src/sound.c:297
    cryDefaultVolume = 125,
    -- pokeruby/src/sound.c:347
    cryModeMax = 5,
    cryModeOverrides = {
      [0] = { length = 140, release = 0, pitch = 15360, chorus = 0, reverse = false, volume = false },
      [1] = { length = 20, release = 225, pitch = 15360, chorus = 0, reverse = false, volume = false },
      [2] = { length = 30, release = 225, pitch = 15600, chorus = 20, reverse = false, volume = 80 },
      [3] = { length = 50, release = 200, pitch = 14800, chorus = 0, reverse = false, volume = false },
      [4] = { length = 20, release = 220, pitch = 15800, chorus = 0, reverse = false, volume = false },
      [5] = { length = 140, release = 200, pitch = 14500, chorus = 0, reverse = false, volume = false },
    },
    -- pokeruby/src/battle_setup.c:589
    legendaryBattleSongs = {
      SPECIES_GROUDON = "MUS_VS_KYOGRE_GROUDON",
      SPECIES_KYOGRE = "MUS_VS_KYOGRE_GROUDON",
      SPECIES_RAYQUAZA = "MUS_VS_KYOGRE_GROUDON",
    },
  }
end

return Audio
