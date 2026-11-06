return {
  tasks = {
    {
      id = "battle_b2",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = "roamer_extract", label = "Roamer Locations" },
        { name = "src.import.gba.rse.safari_rse_extract", label = "Safari Tables" },
      },
    },
  },
  sequential = { "battle_b2" },
  dirs = { "/roamer", "/safari" },
}
