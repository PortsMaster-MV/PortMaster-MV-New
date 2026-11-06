local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_misc",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "misc_extract", label = "Town NPC Tables" },
      },
    },
  },
  sequential = { "rse_misc" },
  dirs = { "/rse/misc" },
}
