local KIND_SIZE = { u8 = 1, s8 = 1, u16 = 2, s16 = 2, u32 = 4, warp = 8 }

local FIELD_IDS = {
  encryptionKey = "G3-01 G3-02", berryPowder = "G3-01 G3-02", frlgMarker = "G3-02",
  specialSaveWarpFlags = "G3-12", location = "G3-12", continueGameWarp = "G3-12",
  dexMode = "G3-14", mapLayoutId = "G3-07", name = "G3-11", rivalName = "G3-11",
}

local EXTRA = {
  rs = {
    { "sb2", 0x98, 8, "T1", "localTimeOffset" },
    { "sb2", 0xA0, 8, "T1", "lastBerryTreeUpdate" },
    { "sb2", 0xA8, 0x4D1, "T1", "battleTower" },
    { "sb1", 0x7F8, 0x140, "T1", "pokeblocks" },
    { "sb1", 0x96C, 6, "T1", "berryBlenderRecords" },
    { "sb1", 0x978, 0x66, "T1", "trainerRematches" },
    { "sb1", 0x1608, 0x400, "T1", "berryTrees" },
    { "sb1", 0x1A08, 0xC80, "T1", "secretBases" },
    { "sb1", 0x2688, 12, "T1", "playerRoomDecorations" },
    { "sb1", 0x2694, 12, "T1", "playerRoomDecorationPositions" },
    { "sb1", 0x26A0, 150, "T1", "decorationInventory" },
    { "sb1", 0x2738, 900, "T1", "tvShowsNativeBytes" },
    { "sb1", 0x2ABC, 64, "T1", "pokeNews" },
    { "sb1", 0x2AFC, 20, "T1", "outbreak" },
    { "sb1", 0x2B10, 12, "T1", "gabbyAndTyData" },
    { "sb1", 0x2B1C, 12, "T1", "easyChatProfile" },
    { "sb1", 0x2B28, 36, "T1", "easyChatBattle" },
    { "sb1", 0x2D8C, 4, "T1", "unlockedTrendySayings" },
    { "sb1", 0x2D94, 64, "T1", "oldMan" },
    { "sb1", 0x2DD4, 40, "T1", "dewfordTrends" },
    { "sb1", 0x2DFC, 416, "T1", "contestWinners" },
    { "sb1", 0x30B8, 80, "T1", "linkBattleRecords" },
    { "sb1", 0x3110, 11, "T1", "giftRibbons" },
    { "sb1", 0x311B, 20, "T1", "externalEventDataNativeBytes" },
    { "sb1", 0x312F, 21, "T1", "externalEventFlagsNativeBytes" },
    { "sb1", 0x3160, 1328, "T1", "enigmaBerryNativeBytes" },
    { "sb1", 0x3690, 1004, "T1", "ramScriptNativeBytes" },
    { "sb1", 0x3A7C, 16, "T1", "recordMixingGift" },
  },
  frlg = {
    { "sb2", 0x16, 0x2, "T2", "optionsPadding", "G3-05", { kind = "padding" } },
    { "sb2", 0x24, 0x4, "T2", "pokedexUnknown", "G3-05", { kind = "absent", patterns = { "unknown2" } } },
    { "sb2", 0x90, 0x8, "T2", "filler_90", "G3-05", { kind = "padding" } },
    { "sb2", 0x98, 0x10, "T2", "rtcFields", "G3-05", { kind = "capability", name = "rtc", set = "FRLG" } },
    { "sb2", 0xB0, 0x7E8, "T2", "battleTower", "G3-05", { kind = "capability", name = "battleTower", set = "FRLG" } },
    { "sb2", 0x898, 0x200, "T2", "mapView", "G3-05", { kind = "absent", patterns = { "session%.mapView", "sess%.mapView", "save%.mapView" } } },
    { "sb2", 0xA98, 0x58, "T1", "linkBattleRecords", nil },
    { "sb2", 0xAF0, 0x10, "T1", "berryCrush", nil },
    { "sb2", 0xB00, 0x10, "T1", "pokeJump", nil },
    { "sb2", 0xB10, 0x10, "T1", "berryPick", nil },
    { "sb2", 0xB20, 0x400, "T2", "filler_B20", "G3-05", { kind = "padding" } },
    { "sb1", 0x2F, 0x1, "T2", "weatherCycleStage", "G3-05", { kind = "runtime", patterns = { "savedWeather", "weatherCycleStage" } } },
    { "sb1", 0x31, 0x1, "T2", "weatherPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x35, 0x3, "T2", "partyCountPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x62C, 0xC, "T2", "berryBlenderRecords", "G3-05", { kind = "capability", name = "berryBlender", set = "FRLG" } },
    { "sb1", 0x638, 0x66, "T1", "vsSeeker", nil },
    { "sb1", 0x69E, 0x2, "T2", "trainerRematchesPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x6A0, 0x240, "T2", "objectEvents", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_quest_log_test.lua", why = "engine object model is its own" } },
    { "sb1", 0x8E0, 0x600, "T2", "objectEventTemplates", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_quest_log_test.lua", why = "engine object model is its own" } },
    { "sb1", 0x1300, 0x19A0, "T2", "questLog", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_quest_log_test.lua", why = "engine quest log is a sampled replay, cart log is an action script" } },
    { "sb1", 0x2CA0, 0xC, "T1", "easyChatProfile", nil },
    { "sb1", 0x2CAC, 0x24, "T1", "easyChatBattle", nil },
    { "sb1", 0x2F10, 0x5, "T2", "additionalPhrases", "G3-05", { kind = "absent", patterns = { "additionalPhrases" } } },
    { "sb1", 0x2F15, 0x3, "T2", "additionalPhrasesPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x2F18, 0x40, "T2", "oldMan", "G3-05", { kind = "capability", name = "mauvilleOldMan", set = "FRLG" } },
    { "sb1", 0x2F58, 0x28, "T2", "dewfordTrends", "G3-05", { kind = "capability", name = "dewfordTrend", set = "FRLG" } },
    { "sb1", 0x309C, 0xB, "T2", "giftRibbons", "G3-05", { kind = "capability", name = "ribbons", set = "FRLG" } },
    { "sb1", 0x30A7, 0x14, "T2", "externalEventData", "G3-05", { kind = "absent", patterns = { "externalEvent" } } },
    { "sb1", 0x30BB, 0x15, "T2", "externalEventFlags", "G3-05", { kind = "absent", patterns = { "externalEvent" } } },
    { "sb1", 0x30E4, 0x8, "T2", "roamerFiller", "G3-05", { kind = "padding" } },
    { "sb1", 0x30EC, 0x34, "T2", "enigmaBerry", "G3-05", { kind = "absent", patterns = { "enigmaBerry%s*=", "session%.enigma", "save%.enigma" } } },
    { "sb1", 0x3120, 0x36C, "T1", "mysteryGift", nil },
    { "sb1", 0x348C, 0x190, "T2", "unused_348C", "G3-05", { kind = "padding" } },
    { "sb1", 0x361C, 0x3EC, "T2", "ramScript", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_sec_frextra_test.lua", why = "gift script bytecode has no engine representation" } },
    { "sb1", 0x3A08, 0x10, "T2", "recordMixingGift", "G3-05", { kind = "capability", name = "recordMixing", set = "FRLG" } },
    { "sb1", 0x3A94, 0x40, "T2", "unused_3A94", "G3-05", { kind = "padding" } },
    { "sb1", 0x3BA6, 0x2, "T2", "trainerNameRecordsPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x3BA8, 0xF0, "T1", "trainerNameRecords", nil },
    { "sb1", 0x3C98, 0x8C, "T1", "route5DayCareMon", nil },
    { "sb1", 0x3D24, 0x10, "T2", "unused_3D24", "G3-05", { kind = "padding" } },
    { "sb1", 0x3D34, 0x4, "T1", "towerChallengeId", nil },
  },
  emerald = {
    { "sb2", 0x16, 0x2, "T2", "optionsPadding", "G3-05", { kind = "padding" } },
    { "sb2", 0x24, 0x4, "T2", "pokedexUnknown", "G3-05", { kind = "absent", patterns = { "unknown2" } } },
    { "sb2", 0x90, 0x8, "T2", "filler_90", "G3-05", { kind = "padding" } },
    { "sb2", 0x98, 0x8, "T1", "localTimeOffset", nil },
    { "sb2", 0xA0, 0x8, "T1", "lastBerryTreeUpdate", nil },
    { "sb2", 0xB0, 0x2C, "T1", "playerApprentice", nil },
    { "sb2", 0xDC, 0x110, "T1", "apprentices", nil },
    { "sb2", 0x1EC, 0x10, "T1", "berryCrush", nil },
    { "sb2", 0x1FC, 0x10, "T1", "pokeJump", nil },
    { "sb2", 0x20C, 0x10, "T1", "berryPick", nil },
    { "sb2", 0x21C, 0x360, "T1", "hallRecords1P", nil },
    { "sb2", 0x57C, 0xA8, "T1", "hallRecords2P", nil },
    { "sb2", 0x624, 0x28, "T1", "contestLinkResults", nil },
    { "sb2", 0x64C, 0x8E0, "T1", "frontier", nil },
    { "sb1", 0x31, 0x1, "T2", "weatherPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x34, 0x200, "T2", "mapView", "G3-05", { kind = "absent", patterns = { "session%.mapView", "sess%.mapView", "save%.mapView" } } },
    { "sb1", 0x235, 0x3, "T2", "partyCountPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x848, 0x140, "T1", "pokeblocks", nil },
    { "sb1", 0x9BC, 0x6, "T1", "berryBlenderRecords", nil },
    { "sb1", 0x9C2, 0x6, "T2", "unused_9C2", "G3-05", { kind = "padding" } },
    { "sb1", 0x9C8, 0x66, "T1", "trainerRematches", nil },
    { "sb1", 0xA2E, 0x2, "T2", "trainerRematchesPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0xA30, 0x240, "T2", "objectEvents", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_quest_log_test.lua", why = "engine object model is its own" } },
    { "sb1", 0xC70, 0x600, "T2", "objectEventTemplates", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_quest_log_test.lua", why = "engine object model is its own" } },
    { "sb1", 0x169C, 0x400, "T1", "berryTrees", nil },
    { "sb1", 0x1A9C, 0xC80, "T1", "secretBases", nil },
    { "sb1", 0x271C, 0xC, "T1", "playerRoomDecorations", nil },
    { "sb1", 0x2728, 0xC, "T1", "playerRoomDecorationPositions", nil },
    { "sb1", 0x2734, 0x96, "T1", "decorationInventory", nil },
    { "sb1", 0x27CA, 0x2, "T2", "decorationPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x27CC, 0x384, "T1", "tvShows", nil },
    { "sb1", 0x2B50, 0x40, "T1", "pokeNews", nil },
    { "sb1", 0x2B90, 0x14, "T1", "outbreak", nil },
    { "sb1", 0x2BA4, 0xC, "T1", "gabbyAndTyData", nil },
    { "sb1", 0x2BB0, 0xC, "T1", "easyChatProfile", nil },
    { "sb1", 0x2BBC, 0x24, "T1", "easyChatBattle", nil },
    { "sb1", 0x2E20, 0x5, "T1", "unlockedTrendySayings", nil },
    { "sb1", 0x2E25, 0x3, "T2", "unlockedTrendyPadding", "G3-05", { kind = "padding" } },
    { "sb1", 0x2E28, 0x40, "T1", "oldMan", nil },
    { "sb1", 0x2E68, 0x28, "T1", "dewfordTrends", nil },
    { "sb1", 0x2E90, 0x1A0, "T1", "contestWinners", nil },
    { "sb1", 0x3150, 0x58, "T1", "linkBattleRecords", nil },
    { "sb1", 0x31A8, 0xB, "T1", "giftRibbons", nil },
    { "sb1", 0x31B3, 0x14, "T2", "externalEventData", "G3-05", { kind = "absent", patterns = { "externalEvent" } } },
    { "sb1", 0x31C7, 0x15, "T2", "externalEventFlags", "G3-05", { kind = "absent", patterns = { "externalEvent" } } },
    { "sb1", 0x31F0, 0x8, "T2", "roamerFiller", "G3-05", { kind = "padding" } },
    { "sb1", 0x31F8, 0x34, "T2", "enigmaBerry", "G3-05", { kind = "absent", patterns = { "enigmaBerry%s*=", "session%.enigma", "save%.enigma" } } },
    { "sb1", 0x322C, 0x36C, "T1", "mysteryGift", nil },
    { "sb1", 0x3598, 0x180, "T2", "unused_3598", "G3-05", { kind = "padding" } },
    { "sb1", 0x3718, 0x10, "T1", "trainerHillTimes", nil },
    { "sb1", 0x3728, 0x3EC, "T2", "ramScript", "G3-05", { kind = "contract", test = "tests/save_compat/gen3_sec_frextra_test.lua", why = "gift script bytecode has no engine representation" } },
    { "sb1", 0x3B14, 0x10, "T1", "recordMixingGift", nil },
    { "sb1", 0x3B58, 0x40, "T1", "lilycoveLady", nil },
    { "sb1", 0x3B98, 0xF0, "T1", "trainerNameRecords", nil },
    { "sb1", 0x3D5A, 0xA, "T2", "unused_3D5A", "G3-05", { kind = "padding" } },
    { "sb1", 0x3D64, 0xC, "T1", "trainerHill", nil },
    { "sb1", 0x3D70, 0x18, "T1", "waldaPhrase", nil },
  },
}

local CARRIED_FIELDS = {
  rs = { savedMusic = { kind = "runtime", patterns = { "savedMusic" } } },
  frlg = {
    savedMusic = { kind = "runtime", patterns = { "savedMusic" } },
    weather = { kind = "runtime", patterns = { "savedWeather" } },
  },
  emerald = {
    savedMusic = { kind = "runtime", patterns = { "savedMusic" } },
  },
}

local function build(family)
  local L = require("src.save_convert.gen3_layouts." .. family)
  local regions = {}
  local function R(block, offset, size, tier, name, extra)
    local r = { block = block, offset = offset, size = size, tier = tier, name = name }
    for k, v in pairs(extra or {}) do r[k] = v end
    regions[#regions + 1] = r
  end
  for _, blk in ipairs(L.BLOCKS) do R(blk.key, 0, blk.size, "T2", blk.key) end
  local function fields(block, list)
    for _, f in ipairs(list) do
      local size = KIND_SIZE[f[3]] or f[4] or 1
      local carry = CARRIED_FIELDS[family][f[1]]
      R(block, f[2], size, carry and "T2" or "T1", block .. "." .. f[1], { ids = FIELD_IDS[f[1]], proof = carry })
    end
  end
  fields("sb2", L.SB2)
  fields("sb1", L.SB1)
  for i = 0, L.PARTY_SIZE - 1 do
    R("sb1", L.PARTY_OFFSET + i * L.PARTY_MON_SIZE, L.PARTY_MON_SIZE, "T1", ("sb1.party%d"):format(i + 1))
  end
  R("sb1", L.PC_ITEMS.off, L.PC_ITEMS.count * 4, "T1", "sb1.pcItems")
  for _, p in ipairs(L.POCKETS) do
    R("sb1", p.off, p.count * 4, "T1", "sb1.pocket." .. p.key)
  end
  R("sb1", L.VARS.off, L.VARS.count * 2, "T1", "sb1.vars")
  R("sb1", L.GAME_STATS.off, L.GAME_STATS.count * 4, "T1", "sb1.gameStats")
  R("sb1", L.MAIL.off, L.MAIL.count * L.MAIL.size, "T1", "sb1.mail")
  R("sb1", L.DAYCARE.off, family == "emerald" and 0x120 or 0x11C, "T1", "sb1.daycare")
  R("sb1", L.ROAMER_OFFSET, 0x14, "T1", "sb1.roamer", { ids = "G3-09" })
  if L.REGISTERED_TEXTS then R("sb1", L.REGISTERED_TEXTS.off, L.REGISTERED_TEXTS.count * L.REGISTERED_TEXTS.size, "T1", "sb1.registeredTexts") end
  if L.FAME_CHECKER then R("sb1", L.FAME_CHECKER.off, L.FAME_CHECKER.count * L.FAME_CHECKER.stride, "T1", "sb1.fameChecker") end
  if L.TRAINER_TOWER then
    R("sb1", L.TRAINER_TOWER.off, L.TRAINER_TOWER.count * L.TRAINER_TOWER.size, "T1", "sb1.trainerTower")
  end
  for _, row in ipairs(EXTRA[family]) do
    R(row[1], row[2], row[3], row[4], row[1] .. "." .. row[5], { ids = row[6], proof = row[7] })
  end
  local S = L.STORAGE
  R("storage", S.currentBox, 4, "T1", "storage.currentBox")
  for b = 0, S.totalBoxes - 1 do
    R("storage", S.boxes + b * S.inBox * L.BOX_MON_SIZE, S.inBox * L.BOX_MON_SIZE, "T1",
      ("storage.box%02d"):format(b + 1))
    for s = 0, S.inBox - 1 do
      R("storage", S.boxes + (b * S.inBox + s) * L.BOX_MON_SIZE, L.BOX_MON_SIZE, "T1",
        ("storage.box%02d.slot%02d"):format(b + 1, s + 1))
    end
  end
  R("storage", S.boxNames, S.totalBoxes * S.boxNameLength, "T1", "storage.boxNames", { ids = "G3-11" })
  R("storage", S.wallpapers, S.totalBoxes, "T1", "storage.wallpapers", { ids = "G3-10" })
  -- include/save.h:63
  for sector = 0, 31 do
    local base = sector * 0x1000
    R("flash", base + 0xFF4, 2, "T3", ("flash.sector%02d.id"):format(sector), { derived = sector < 28 })
    R("flash", base + 0xFF6, 2, "T3", ("flash.sector%02d.checksum"):format(sector), { derived = true })
    R("flash", base + 0xFF8, 4, "T3", ("flash.sector%02d.signature"):format(sector))
    R("flash", base + 0xFFC, 4, "T3", ("flash.sector%02d.counter"):format(sector), { derived = sector < 28 })
  end
  R("flash", 0x1C000, 0x2000, "T1", "flash.hallOfFame")
  R("flash", 0x1E000, 0x1000, "T2", "flash.sector30", { ids = "G3-16" })
  R("flash", 0x1F000, 0x1000, "T2", "flash.sector31", { ids = "G3-16" })
  return regions
end

local frlg, emerald, rs = build("frlg"), build("emerald"), build("rs")

return {
  generation = 3,
  size = 0x20000,
  blocks = { "sb2", "sb1", "storage" },
  layouts = { firered = frlg, leafgreen = frlg, emerald = emerald, ruby = rs, sapphire = rs, default = frlg },
  frlg = frlg,
  emerald = emerald,
  rs = rs,
}
