return {
  -- pokeruby/src/new_game.c:197
  money = 3000,
  pcItems = { { item = "ITEM_POTION", qty = 1 } },
  rivalName = false,
  resetScript = "EventScript_ResetAllMapFlags",
  -- pokeruby/src/pokemon_size_record.c:158
  sizeRecordVars = { "VAR_SHROOMISH_SIZE_RECORD", "VAR_BARBOACH_SIZE_RECORD" },
  sizeRecordDefault = 0x8100,
  storage = { pcOwnerFlag = "FLAG_SYS_PC_LANETTE", transferText = "gOtherText_SentToPC" },
  sections = {
    "rtc", "berryTrees", "decorations",
    { name = "tv", module = "src.core.game3.rse.tv" },
    { name = "weather", module = "src.core.game3.weather" },
    { name = "giftRibbons", module = "src.core.game3.rse.ribbons" },
    { name = "secretBases", module = "src.core.game3.rse.secret_base" },
    { name = "pokeblocks", module = "src.core.game3.rse.pokeblock" },
    { name = "berryBlender", module = "src.core.game3.rse.berry_blender" },
    { name = "recordMixingGift", module = "src.core.game3.rse.record_mixing_gift" },
    { name = "rsState", module = "src.core.game3.profiles.rs.save_state" },
  },
}
