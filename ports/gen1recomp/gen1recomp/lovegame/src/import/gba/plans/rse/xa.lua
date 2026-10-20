local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_xa",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "cable_car_extract", label = "Cable Car" },
        { name = R .. "rayquaza_scene_extract", label = "Rayquaza Scene" },
      },
    },
  },
  sequential = { "rse_xa" },
  dirs = { "/cable_car", "/rayquaza_scene" },
}
