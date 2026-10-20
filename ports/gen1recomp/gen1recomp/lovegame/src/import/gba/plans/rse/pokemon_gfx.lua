return {
  tasks = {
    { id = "em_pokemon_data", run = "steps", weight = 0.04, steps = {
      { name = "pokemon_extract", opts = { part = "data" }, label = "Pokémon Species Data" },
      { name = "pic_coords_extract", label = "Pokémon Pic Coordinates" },
      { name = "mon_anim_extract", label = "Pokémon Animation Data" },
    } },
    { id = "em_pokemon_gfx_a", run = "steps", weight = 0.06, steps = {
      { name = "pokemon_extract", opts = { part = "gfx", spMin = 0, spMax = 205 }, label = "Pokémon Sprites" },
    } },
    { id = "em_pokemon_gfx_b", run = "steps", weight = 0.06, steps = {
      { name = "pokemon_extract", opts = { part = "gfx", spMin = 206 }, label = "Pokémon Sprites" },
    } },
    { id = "em_pokemon_forms", run = "steps", weight = 0.03, steps = {
      { name = "pokemon_extract", opts = { part = "forms" }, label = "Pokémon Forms & Footprints" },
      { name = "egg_extract", label = "Egg & Hatching" },
    } },
  },
  sequential = { "em_pokemon_data", "em_pokemon_gfx_a", "em_pokemon_gfx_b", "em_pokemon_forms" },
  dirs = {
    "/pokemon",
    "/pokemon/front",
    "/pokemon/front_shiny",
    "/pokemon/front_anim",
    "/pokemon/front_anim_shiny",
    "/pokemon/front_still",
    "/pokemon/front_still_shiny",
    "/pokemon/back",
    "/pokemon/back_shiny",
    "/pokemon/icons",
    "/pokemon/footprints",
    "/pokemon/spinda",
    "/pokemon/egg",
  },
}
