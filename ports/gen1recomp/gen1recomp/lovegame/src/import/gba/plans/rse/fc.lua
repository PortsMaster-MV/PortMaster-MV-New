return {
  tasks = {
    {
      id = "field_fc",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = "src.import.gba.rse.fc_field_extract", label = "Field Palettes" },
      },
    },
  },
  sequential = { "field_fc" },
  dirs = { "/field_fc" },
}
