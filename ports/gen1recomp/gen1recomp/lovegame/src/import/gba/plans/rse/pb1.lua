return {
  tasks = {
    {
      id = "pokeblock_pb1",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = "src.import.gba.rse.pokeblock_extract", label = "Pokeblock Screens" },
        { name = "src.import.gba.rse.berry_tag_extract", label = "Berry Tag" },
      },
    },
  },
  sequential = { "pokeblock_pb1" },
  dirs = { "/rse/pokeblock", "/rse/berry_tag" },
}
