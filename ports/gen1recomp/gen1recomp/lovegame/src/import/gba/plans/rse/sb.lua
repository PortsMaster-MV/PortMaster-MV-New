local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_sb",
      run = "steps",
      weight = 0.005,
      steps = {
        { name = R .. "secret_base_extract", label = "Secret Bases" },
      },
    },
  },
  sequential = { "rse_sb" },
  dirs = { "/secret_base" },
}
