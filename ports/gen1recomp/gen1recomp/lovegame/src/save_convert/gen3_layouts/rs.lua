local L = {}

-- pokeruby/include/global.h:668
L.FAMILY, L.GAME = "rs", "ruby"
L.UNENCRYPTED = true
L.DAYCARE_SAVE_KEY = "rs_daycare"
L.PORT = "src.save_convert.gen3_port.rs"
L.KEEP_RAW_NAMES = true
L.CART_VERSION = 2
L.GAME_CODES = { [1] = "sapphire", [2] = "ruby" }

-- pokeruby/src/save.c:110
L.CHUNK_SIZES = { [0] = 0x890, 0xF80, 0xF80, 0xF80, 0xC40,
  0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0x7D0 }
L.BLOCKS = {
  { key = "sb2", first = 0, last = 0, size = 0x890 },
  { key = "sb1", first = 1, last = 4, size = 0x3AC0 },
  { key = "storage", first = 5, last = 13, size = 0x83D0 },
}
L.SB2 = {
  { "name", 0, "strFF", 8 }, { "gender", 8, "u8" }, { "specialSaveWarpFlags", 9, "u8" },
  { "trainerId", 0xA, "u16" }, { "secretId", 0xC, "u16" }, { "playHours", 0xE, "u16" },
  { "playMinutes", 0x10, "u8" }, { "playSeconds", 0x11, "u8" }, { "playVBlanks", 0x12, "u8" },
  { "buttonMode", 0x13, "u8" }, { "optionsWord", 0x14, "u16" },
  { "dexOrder", 0x18, "u8" }, { "dexMode", 0x19, "u8" }, { "dexNationalMagic", 0x1A, "u8" },
  { "dexUnused", 0x1B, "u8" }, { "unownPersonality", 0x1C, "u32" }, { "spindaPersonality", 0x20, "u32" },
  { "dexOwned", 0x28, "bits", 52 }, { "dexSeen", 0x5C, "bits", 52 },
}
L.SB1 = {
  { "posX", 0, "s16" }, { "posY", 2, "s16" }, { "location", 4, "warp" },
  { "continueGameWarp", 0xC, "warp" }, { "dynamicWarp", 0x14, "warp" },
  { "lastHealLocation", 0x1C, "warp" }, { "escapeWarp", 0x24, "warp" },
  { "savedMusic", 0x2C, "u16" }, { "weather", 0x2E, "u8" }, { "weatherCycleStage", 0x2F, "u8" },
  { "flashLevel", 0x30, "u8" }, { "mapLayoutId", 0x32, "u16" }, { "partyCount", 0x234, "u8" },
  { "money", 0x490, "u32" }, { "coins", 0x494, "u16" }, { "registeredItem", 0x496, "u16" },
  { "dexSeen1", 0x938, "bits", 52 }, { "flags", 0x1220, "bits", 288 }, { "dexSeen2", 0x3A8C, "bits", 52 },
}
L.MAP_VIEW = { block = "sb1", off = 0x34, size = 0x200 }
L.PARTY_OFFSET = 0x238
L.PC_ITEMS = { off = 0x498, count = 50 }
L.POCKETS = {
  { key = "ITEMS", off = 0x560, count = 20 }, { key = "KEY_ITEMS", off = 0x5B0, count = 20 },
  { key = "POKE_BALLS", off = 0x600, count = 16 }, { key = "TM_CASE", off = 0x640, count = 64 },
  { key = "BERRY_POUCH", off = 0x740, count = 46 },
}
L.OBJECT_EVENTS = { off = 0x9E0, count = 16, size = 0x24 }
L.VARS = { off = 0x1340, count = 256, first = 0x4000 }
L.GAME_STATS = { off = 0x1540, count = 50 }
L.EASY_CHAT_PROFILE = { off = 0x2B1C, count = 6 }
L.EASY_CHAT_BATTLE = { start = 0x2B28, won = 0x2B34, lost = 0x2B40, count = 6 }
L.MAIL = { off = 0x2B4C, count = 16, size = 36, words = 0, wordCount = 9,
  playerName = 0x12, playerNameLength = 8, trainerId = 0x1A, species = 0x1E, itemId = 0x20 }
-- pokeruby/include/global.h:581
L.DAYCARE = { off = 0x2F9C, monSize = 80, mailOffset = 0xA0, mailSize = 56, stepsOffset = 0x110,
  offspringPersonality = 0x118, stepCounter = 0x11A, offspringKind = "u16" }
L.DAYCARE_MAIL = { off = 0, otName = 36, otNameLength = 8, monName = 44, monNameLength = 11 }
L.ROAMER = {
  { "ivs", 0, "u32" }, { "personality", 4, "u32" }, { "species", 8, "u16" }, { "hp", 10, "u16" },
  { "level", 12, "u8" }, { "status", 13, "u8" }, { "cool", 14, "u8" }, { "beauty", 15, "u8" },
  { "cute", 16, "u8" }, { "smart", 17, "u8" }, { "tough", 18, "u8" }, { "active", 19, "u8" },
}
L.ROAMER_OFFSET = 0x3144
L.LINK_BATTLE_RECORDS = { block = "sb1", off = 0x30B8, count = 5, size = 16 }
L.FLAGS_COUNT = 0x900
L.NATIONAL_DEX = { magic = 0xDA, var = "VAR_NATIONAL_DEX", varValue = 0x302, flag = "FLAG_SYS_NATIONAL_DEX" }
L.FLAG_SYS_GAME_CLEAR = "FLAG_SYS_GAME_CLEAR"
L.DEX_MODE_NATIONAL = 1
L.EC_MASK_BITS = 9
-- pokeruby/src/easy_chat_1.c:529
local P, V, E = "EC_GROUP_PEOPLE", "EC_GROUP_VOICES", "EC_GROUP_ENDINGS"
L.DEFAULT_EASY_CHAT = {
  profile = { { P, 41 }, { E, 32 }, { "EC_GROUP_TRAINER", 14 }, { "EC_GROUP_FEELINGS", 64 } },
  start = { { E, 15 }, { P, 2 }, { "EC_GROUP_SPEECH", 37 }, { V, 3 }, { "EC_GROUP_GREETINGS", 3 }, { V, 0 } },
  won = {}, lost = {},
}
L.RSE = {
  sb2 = { localTimeOffset = 0x98, lastBerryTreeUpdate = 0xA0, battleTower = 0xA8 },
  sb1 = {
    pokeblocks = 0x7F8, pokeblockCount = 40, berryBlenderRecords = 0x96C,
    trainerRematchStepCounter = 0x978, trainerRematches = 0x97A, trainerRematchCount = 100,
    berryTrees = 0x1608, berryTreeCount = 128, secretBases = 0x1A08, secretBaseCount = 20, secretBaseSize = 160,
    playerRoomDecorations = 0x2688, playerRoomDecorationPositions = 0x2694, decorationInventory = 0x26A0,
    tvShows = 0x2738, tvShowCount = 25, tvShowSize = 36, pokeNews = 0x2ABC, pokeNewsCount = 16,
    outbreak = 0x2AFC, gabbyAndTy = 0x2B10, oldMan = 0x2D94, dewfordTrends = 0x2DD4, dewfordTrendCount = 5,
    contestWinners = 0x2DFC, contestWinnerCount = 13, giftRibbons = 0x3110, giftRibbonCount = 11,
    externalEventData = 0x311B, externalEventFlags = 0x312F, enigmaBerry = 0x3160,
    ramScript = 0x3690, recordMixingGift = 0x3A7C,
  },
}
L.DECOR_CATEGORY_SIZES = { [0] = 10, 10, 10, 30, 30, 10, 40, 10 }
L.DECOR_MAX_PLAYERS_HOUSE = 12
require("src.save_convert.gen3_layouts.common").merge(L)
local sapphire
function L.forVersion(version)
  if version ~= "sapphire" then return L end
  if not sapphire then
    sapphire = {}
    for k, v in pairs(L) do sapphire[k] = v end
    sapphire.GAME, sapphire.CART_VERSION = "sapphire", 1
  end
  return sapphire
end
return L
