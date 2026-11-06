return {
  tasks = {
    {
      id = "ui_wild",
      run = "steps",
      weight = 0.02,
      steps = {
        { name = "encounters_extract", label = "Wild Encounters" },
      },
    },
    {
      id = "ui_places",
      run = "steps",
      weight = 0.02,
      steps = {
        { name = "src.import.gba.rse.map_sections_extract", label = "Map Sections" },
        { name = "heal_locations_extract", opts = { strict = true }, label = "Heal Locations" },
        { name = "multichoice_extract", label = "Dialog Menus" },
      },
    },
    {
      id = "ui_relearner",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = "move_relearner_rse_extract", label = "Move Relearner" },
      },
    },
  },
  sequential = { "ui_wild", "ui_places", "ui_relearner" },
  dirs = { "/region_map", "/scripts", "/chrome/map_popup", "/rse/move_relearner" },
}
