local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "ud_pokenav",
      run = "steps",
      weight = 0.02,
      steps = {
        { name = R .. "pokenav_extract", label = "PokeNav" },
        { name = R .. "match_call_extract", label = "Match Call" },
      },
    },
  },
  sequential = { "ud_pokenav" },
  dirs = { "/rse", "/rse/pokenav", "/rse/match_call" },
}
