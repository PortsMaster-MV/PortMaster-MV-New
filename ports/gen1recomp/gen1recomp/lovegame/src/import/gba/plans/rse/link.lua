return {
  tasks = {
    {
      id = "rse_link",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = "src.import.gba.rse.link_extract", label = "Link Trade" },
        { name = "src.import.gba.rse.union_room_extract", label = "Wireless Union" },
        { name = "src.import.gba.rse.kanto_card_extract", label = "Kanto Trainer Card" },
      },
    },
  },
  sequential = { "rse_link" },
  dirs = { "/trade", "/union_room", "/wireless_status", "/trainers", "/trainer_card" },
}
