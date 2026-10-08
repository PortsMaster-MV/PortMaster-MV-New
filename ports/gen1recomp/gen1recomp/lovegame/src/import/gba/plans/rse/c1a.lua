local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_c1a",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "contest_extract", label = "Contests" },
      },
    },
  },
  sequential = { "rse_c1a" },
  dirs = { "/rse/contest" },
}
