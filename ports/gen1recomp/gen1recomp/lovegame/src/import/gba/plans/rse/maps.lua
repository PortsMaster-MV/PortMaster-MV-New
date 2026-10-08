return {
  tasks = {
    {
      id = "maps_tree",
      run = "steps",
      weight = 0.05,
      steps = {
        { name = "map_tree_extract", opts = { strict = true }, label = "Map Headers & Events" },
      },
    },
    {
      id = "maps_native",
      run = "steps",
      weight = 0.06,
      steps = {
        { name = "maps_native_extract", label = "World Maps: Tilesets & Layouts" },
      },
    },
  },
  sequential = { "maps_tree", "maps_native" },
  dirs = { "/map_tree", "/native", "/native/layouts", "/objects" },
}
