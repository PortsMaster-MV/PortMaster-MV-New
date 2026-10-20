return {
  id = "rs",
  constantsGame = "ruby",
  -- pokeruby/include/pokedex.h:33
  pokedexEntry = {
    size = 36, category = 0, categoryLen = 12,
    height = 12, weight = 14, desc = 16, desc2 = 20,
    pokemonScale = 26, pokemonOffset = 28, trainerScale = 30, trainerOffset = 32,
  },
  regionalDex = { name = "hoenn", countConstant = "HOENN_DEX_COUNT" },
  -- pokeruby/include/battle.h:265
  trainerNameLen = 12,
  trainerBackPicCount = nil,
  trainerExtras = true,
  inlineTrainerDialogs = false,
  tutorLearnsetBytes = 0,
}
