local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "tv_shows",
      run = "steps",
      weight = 0.005,
      steps = {
        { name = R .. "tv_extract", label = "TV Shows" },
      },
    },
  },
  sequential = { "tv_shows" },
  dirs = { "/tv" },
}
