local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_f1",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "frontier_extract", label = "Battle Frontier" },
        { name = R .. "frontier_pass_extract", label = "Frontier Pass" },
      },
    },
  },
  sequential = { "rse_f1" },
  dirs = { "/rse", "/rse/frontier", "/rse/frontier_pass" },
}
