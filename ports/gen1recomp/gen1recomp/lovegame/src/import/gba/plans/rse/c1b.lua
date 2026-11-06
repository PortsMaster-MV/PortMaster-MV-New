local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_c1b",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "contest_gfx_extract", label = "Contest Stage" },
        { name = R .. "contest_painting_extract", label = "Contest Painting" },
      },
    },
  },
  sequential = { "rse_c1b" },
  dirs = { "/rse/contest_gfx", "/rse/contest_painting" },
}
