local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_story",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "extract_starter_choose_rse", label = "Starter Choice" },
        { name = R .. "extract_field_specials_rse", label = "Field Specials" },
      },
    },
  },
  sequential = { "rse_story" },
  dirs = { "/starter_choose", "/field_specials" },
}
