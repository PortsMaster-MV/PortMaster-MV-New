local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_b3",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "extract_transition_b3", label = "Battle Transitions (RSE)" },
      },
    },
  },
  sequential = { "rse_b3" },
  dirs = { "/battle_transition_rse" },
}
