local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "ub_region_dex",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = R .. "region_map_extract", label = "Region Map" },
        { name = R .. "pokedex_chrome_extract", label = "Pokedex Screens" },
      },
    },
  },
  sequential = { "ub_region_dex" },
  dirs = { "/rse", "/rse/region_map", "/rse/pokedex" },
}
