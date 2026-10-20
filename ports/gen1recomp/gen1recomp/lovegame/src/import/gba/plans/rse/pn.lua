local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "pn_pokenav_condition",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "pokenav_condition_extract", label = "PokeNav Condition/Ribbons" },
      },
    },
  },
  sequential = { "pn_pokenav_condition" },
  dirs = { "/rse", "/rse/pokenav_cr" },
}
