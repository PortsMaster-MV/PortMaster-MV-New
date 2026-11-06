-- pokeruby/src/item_menu.c:152
return {
  pockets = { "ITEMS", "POKE_BALLS", "TM_CASE", "BERRY_POUCH", "KEY_ITEMS" },
  visible = { "ITEMS", "POKE_BALLS", "TM_CASE", "BERRY_POUCH", "KEY_ITEMS" },
  packPockets = {
    ITEMS = "ITEMS", POKE_BALLS = "POKE_BALLS", TM_HM = "TM_CASE",
    BERRIES = "BERRY_POUCH", KEY_ITEMS = "KEY_ITEMS",
  },
  capacity = { ITEMS = 20, POKE_BALLS = 16, TM_CASE = 64, BERRY_POUCH = 46, KEY_ITEMS = 20 },
  containers = {},
  -- pokeruby/src/item.c:157
  slotMax = { default = 99, BERRY_POUCH = 999 },
  splitSlots = { ITEMS = true, POKE_BALLS = true, KEY_ITEMS = true },
  sortHmsFirst = {},
  -- pokeruby/src/item_menu.c:437
  sortById = { TM_CASE = true, BERRY_POUCH = true },
  pcItems = 50, pcSlotMax = 999,
}
