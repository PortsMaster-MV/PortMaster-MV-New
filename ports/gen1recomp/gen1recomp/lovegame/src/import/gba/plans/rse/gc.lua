local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_gc",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "slot_machine_extract", label = "Slot Machine" },
        { name = R .. "roulette_extract", label = "Roulette" },
      },
    },
  },
  sequential = { "rse_gc" },
  dirs = { "/rse_slot_machine", "/rse_roulette" },
}
