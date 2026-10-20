local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "uc_screens",
      run = "steps",
      weight = 0.02,
      steps = {
        { name = "storage_chrome_extract", label = "Storage Chrome" },
        { name = R .. "shop_chrome_extract", label = "Shop Chrome" },
        { name = R .. "hall_of_fame_extract", label = "Hall of Fame" },
        { name = R .. "diploma_extract", label = "Emerald Diploma" },
        { name = R .. "exchange_corner_extract", label = "Frontier Exchange Corner" },
        { name = "easy_chat_extract", label = "Easy Chat Words" },
        { name = R .. "mail_extract", label = "Mail" },
        { name = R .. "decorations_extract", label = "Decorations" },
        { name = R .. "credits_extract", label = "Credits" },
      },
    },
  },
  sequential = { "uc_screens" },
  dirs = { "/pokemon/storage", "/pokemon/storage/wallpapers", "/pokemon/storage/wallpapers/friends",
    "/items/shop", "/hall_of_fame", "/diploma", "/frontier_exchange_corner", "/easy_chat", "/mail", "/decorations", "/credits_rse" },
}
