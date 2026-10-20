-- pokeruby/src/item_menu.c:152
local D = {}
D.POCKETS = { "ITEMS", "POKE_BALLS", "TM_CASE", "BERRY_POUCH", "KEY_ITEMS" }
D.GRIDS = {
  ITEMS = { "USE", "TOSS", "GIVE", "CANCEL" },
  POKE_BALLS = { "GIVE", "TOSS", false, "CANCEL" },
  TM_CASE = { "USE", false, "GIVE", "CANCEL" },
  BERRY_POUCH = { "CHECK_TAG", "USE", "TOSS", false, "GIVE", "CANCEL" },
  KEY_ITEMS = { "USE", false, "SET", "CANCEL" },
}
D.ACTION_TEXT = {
  USE = "OtherText_Use", TOSS = "OtherText_Toss", GIVE = "OtherText_Give2",
  SET = "OtherText_Register", CANCEL = "gOtherText_CancelNoTerminator",
  CHECK_TAG = "OtherText_CheckTag", CONFIRM = "OtherText_Confirm",
  WALK = "gOtherText_Walk", CHECK = "gOtherText_Check",
}
D.RETURN_TEXT = {
  field = "OtherText_TheField3", battle = "OtherText_TheBattle",
  party = "OtherText_ThePokeList", shop = "OtherText_TheShop",
  berry_tree = "OtherText_TheField", blender = "OtherText_TheField2",
  itempc = "OtherText_ThePC",
}
D.TEXT_ALIASES = {
  gText_CloseBag = "gOtherText_CloseBag", gText_ItemCantBeHeld = "gOtherText_CantBeHeld",
  gText_ThereIsNoPokemon = "gOtherText_NoPokemon", gText_NoRoomToStoreItems = "gOtherText_NoRoomForItems",
  gText_DepositHowManyStrVars1 = "gOtherText_HowManyToDeposit",
  gText_DepositedStrVar2StrVar1s = "gOtherText_DepositedItems",
  gText_Yes = "OtherText_Yes", gText_No = "OtherText_No",
}
return D
