return {
  tasks = {
    {
      id = "field_fx",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = "field_effect_extract", label = "Field Effects" },
        { name = "weather_extract", label = "Weather Graphics" },
        { name = "cave_transition_extract", label = "Cave Transition" },
      },
    },
    {
      id = "field_objects",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = "door_anim_extract", label = "Door Animations" },
        { name = "src.import.gba.rse.berry_tree_gfx_extract", label = "Berry Trees" },
        { name = "src.import.gba.rse.rotating_gate_gfx_extract", label = "Rotating Gates" },
      },
    },
  },
  sequential = { "field_fx", "field_objects" },
  dirs = { "/field_effects", "/doors", "/weather", "/cave_transition", "/berry_trees", "/rotating_gates" },
}
