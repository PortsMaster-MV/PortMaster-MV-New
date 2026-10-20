local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_f4",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "pyramid_extract", label = "Battle Pyramid" },
        { name = R .. "trainer_hill_extract", label = "Trainer Hill" },
        { name = R .. "event_islands_extract", label = "Event islands" },
        { name = R .. "apprentice_extract", label = "Apprentice" },
      },
    },
  },
  sequential = { "rse_f4" },
  dirs = { "/rse", "/rse/pyramid", "/rse/trainer_hill", "/rse/event_islands", "/rse/apprentice" },
}
