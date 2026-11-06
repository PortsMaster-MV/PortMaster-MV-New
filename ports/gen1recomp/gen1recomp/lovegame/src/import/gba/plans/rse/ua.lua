local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "rse_ui_menus",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = R .. "bag_chrome_extract", label = "Bag" },
        { name = R .. "menus_extract", label = "Menus" },
        { name = "party_chrome_extract", label = "Party", opts = { game = "emerald" } },
        { name = R .. "summary_chrome_extract", label = "Summary" },
        { name = R .. "trainer_card_extract", label = "Trainer Card" },
      },
    },
  },
  sequential = { "rse_ui_menus" },
  dirs = { "/rse", "/rse/bag", "/rse/menus", "/pokemon/party", "/rse/summary", "/rse/trainer_card" },
}
