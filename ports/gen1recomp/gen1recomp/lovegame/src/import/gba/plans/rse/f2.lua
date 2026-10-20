local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_f2",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "frontier_f2_extract", label = "Battle Dome, Palace, Arena" },
      },
    },
  },
  sequential = { "rse_f2" },
  dirs = { "/rse", "/rse/frontier_f2" },
}
