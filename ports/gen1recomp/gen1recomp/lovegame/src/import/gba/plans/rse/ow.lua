return {
  tasks = {
    {
      id = "ow_sprites",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = "ow_extract", opts = { all = true }, label = "Overworld Sprites" },
      },
    },
  },
  sequential = { "ow_sprites" },
  dirs = { "/ow" },
}
