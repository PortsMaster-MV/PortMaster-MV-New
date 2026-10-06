local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_f3",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "factory_extract", label = "Battle Factory" },
        { name = R .. "pike_extract", label = "Battle Pike" },
      },
    },
  },
  sequential = { "rse_f3" },
  dirs = { "/rse", "/rse/factory", "/rse/pike" },
}
