-- pokeemerald/include/constants/item.h:6
return {
  pockets = { "ITEMS", "POKE_BALLS", "TM_CASE", "BERRY_POUCH", "KEY_ITEMS" },
  visible = { "ITEMS", "POKE_BALLS", "TM_CASE", "BERRY_POUCH", "KEY_ITEMS" },
  packPockets = {
    ITEMS = "ITEMS",
    POKE_BALLS = "POKE_BALLS",
    TM_HM = "TM_CASE",
    BERRIES = "BERRY_POUCH",
    KEY_ITEMS = "KEY_ITEMS",
  },
  -- pokeemerald/include/constants/global.h:51
  capacity = { ITEMS = 30, POKE_BALLS = 16, TM_CASE = 64, BERRY_POUCH = 46, KEY_ITEMS = 30 },
  -- pokeemerald/src/strings.c:288
  labels = {
    ITEMS = "gPocketNamesStringsTable[0]",
    POKE_BALLS = "gPocketNamesStringsTable[1]",
    TM_CASE = "gPocketNamesStringsTable[2]",
    BERRY_POUCH = "gPocketNamesStringsTable[3]",
    KEY_ITEMS = "gPocketNamesStringsTable[4]",
  },
  containers = {},
  -- pokeemerald/include/constants/items.h:453
  slotMax = { default = 99, BERRY_POUCH = 999 },
  -- pokeemerald/src/item.c:284
  splitSlots = { ITEMS = true, POKE_BALLS = true, KEY_ITEMS = true },
  sortHmsFirst = {},
  -- pokeemerald/src/item_menu.c:1108
  sortById = { TM_CASE = true, BERRY_POUCH = true },
  -- pokeemerald/include/constants/global.h:50
  pcItems = 50,
  -- pokeemerald/include/constants/items.h:454
  pcSlotMax = 999,
}
