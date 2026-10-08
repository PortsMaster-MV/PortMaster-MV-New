local L = {}

L.FAMILY = "frlg"
-- include/global.h:358
L.KEY_OFF = 0xF20
-- src/new_game.c:121
L.MARKER = { off = 0x0AC, value = 1 }
L.DEX_UNUSED_DEFAULT = 0xDA
L.DAYCARE_SAVE_KEY = "firered_daycare"

-- src/save.c:54
L.CHUNK_SIZES = {
  [0] = 0xF24,
  0xF80, 0xF80, 0xF80, 0xEE8,
  0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0x7D0,
}

-- src/save.c:56
L.BLOCKS = {
  { key = "sb2", first = 0, last = 0, size = 0xF24 },
  { key = "sb1", first = 1, last = 4, size = 0x3D68 },
  { key = "storage", first = 5, last = 13, size = 0x83D0 },
}

-- include/global.h:329
L.SB2 = {
  { "name", 0x000, "strFF", 8 },
  { "gender", 0x008, "u8" },
  { "specialSaveWarpFlags", 0x009, "u8" },
  { "trainerId", 0x00A, "u16" },
  { "secretId", 0x00C, "u16" },
  { "playHours", 0x00E, "u16" },
  { "playMinutes", 0x010, "u8" },
  { "playSeconds", 0x011, "u8" },
  { "playVBlanks", 0x012, "u8" },
  { "buttonMode", 0x013, "u8" },
  { "optionsWord", 0x014, "u16" },
  -- include/global.h:195
  { "dexOrder", 0x018, "u8" },
  { "dexMode", 0x019, "u8" },
  { "dexUnused", 0x01A, "u8" },
  { "dexNationalMagic", 0x01B, "u8" },
  { "unownPersonality", 0x01C, "u32" },
  { "spindaPersonality", 0x020, "u32" },
  { "dexOwned", 0x028, "bits", 52 },
  { "dexSeen", 0x05C, "bits", 52 },
  -- include/global.h:348
  { "gcnLinkFlags", 0x0A8, "u32" },
  { "frlgMarker", 0x0AC, "u32" },
  -- include/global.h:354
  { "berryPowder", 0xAF8, "u32", nil, "key32" },
  -- include/global.h:358
  { "encryptionKey", 0xF20, "u32" },
}

-- include/global.h:761
L.SB1 = {
  { "posX", 0x0000, "s16" },
  { "posY", 0x0002, "s16" },
  { "location", 0x0004, "warp" },
  { "continueGameWarp", 0x000C, "warp" },
  { "dynamicWarp", 0x0014, "warp" },
  { "lastHealLocation", 0x001C, "warp" },
  { "escapeWarp", 0x0024, "warp" },
  { "savedMusic", 0x002C, "u16" },
  { "weather", 0x002E, "u8" },
  { "flashLevel", 0x0030, "u8" },
  { "mapLayoutId", 0x0032, "u16" },
  { "partyCount", 0x0034, "u8" },
  { "money", 0x0290, "u32", nil, "key32" },
  { "coins", 0x0294, "u16", nil, "key16" },
  { "registeredItem", 0x0296, "u16" },
  { "dexSeen1", 0x05F8, "bits", 52 },
  { "flags", 0x0EE0, "bits", 0x120 },
  { "dexSeen2", 0x3A18, "bits", 52 },
  { "rivalName", 0x3A4C, "str", 8 },
}

-- include/global.h:773
L.PARTY_OFFSET = 0x0038

-- include/global.h:777
L.PC_ITEMS = { off = 0x0298, count = 30 }
-- include/global.h:778
L.POCKETS = {
  { key = "ITEMS", off = 0x0310, count = 42 },
  { key = "KEY_ITEMS", off = 0x03B8, count = 30 },
  { key = "POKE_BALLS", off = 0x0430, count = 13 },
  { key = "TM_CASE", off = 0x0464, count = 58 },
  { key = "BERRY_POUCH", off = 0x054C, count = 43 },
}

-- include/global.h:788
L.OBJECT_EVENTS = { off = 0x06A0, count = 16, size = 0x24 }

-- include/global.h:791
L.VARS = { off = 0x1000, count = 256, first = 0x4000 }
-- include/global.h:792
L.GAME_STATS = { off = 0x1200, count = 64 }
-- include/global.h:794
L.EASY_CHAT_PROFILE = { off = 0x2CA0, count = 6 }

-- include/global.h:549
L.DAYCARE = { off = 0x2F80, monSize = 0x8C, stepsOff = 0x88, offspringPersonality = 0x118, stepCounter = 0x11A }
-- include/global.h:818
L.ROUTE5_DAYCARE = 0x3C98

-- include/global.h:417
L.ROAMER = {
  { "ivs", 0x00, "u32" },
  { "personality", 0x04, "u32" },
  { "species", 0x08, "u16" },
  { "hp", 0x0A, "u16" },
  { "level", 0x0C, "u8" },
  { "status", 0x0D, "u8" },
  { "active", 0x13, "u8" },
}
L.ROAMER_OFFSET = 0x30D0

-- src/event_data.c:107
L.NATIONAL_DEX = { magic = 0xB9, var = 0x404E, varValue = 0x6258, flag = 0x840 }
-- include/constants/flags.h:1378
L.FLAG_SYS_GAME_CLEAR = 0x82C
-- include/global.h:790
L.FLAGS_COUNT = 0x900

-- include/global.h:524
L.MAIL = { off = 0x2CD0, count = 16, size = 36, words = 0x00, wordCount = 9, playerName = 0x12,
  playerNameLength = 8, trainerId = 0x1A, species = 0x1E, itemId = 0x20 }

-- include/global.h:795
L.EASY_CHAT_BATTLE = { start = 0x2CAC, won = 0x2CB8, lost = 0x2CC4, count = 6 }

-- include/global.h:814
L.FAME_CHECKER = { off = 0x3A54, count = 16, stride = 4, pickBits = 2, flavorShift = 2, flavorBits = 12, unkShift = 14 }
-- include/constants/fame_checker.h:4
L.FAMECHECKER_OAK = 0
-- include/constants/fame_checker.h:24
L.FCPICKSTATE_COLORED = 2

-- include/global.h:816
L.REGISTERED_TEXTS = { off = 0x3AD4, count = 10, size = 21 }

-- include/global.h:693
L.TRAINER_TOWER = { off = 0x3D38, count = 4, size = 12, bestTime = 4 }
-- include/constants/trainer_tower.h:61
L.TRAINER_TOWER_MAX_TIME = 215999

-- include/global.h:240
L.LINK_BATTLE_RECORDS = { block = "sb2", off = 0xA98, count = 5, size = 16 }
-- include/global.h:817
L.TRAINER_NAME_RECORDS = { off = 0x3BA8, count = 20 }
-- include/global.h:352
L.MAP_VIEW = { block = "sb2", off = 0x898, size = 0x200 }
-- include/global.h:793
L.QUEST_LOG = { off = 0x1300, size = 0x19A0 }

L.KEEP_RAW_NAMES = true
L.PORT = "src.save_convert.gen3_port.frlg"
L.GAME_CODES = { [4] = "firered", [5] = "leafgreen" }

-- src/event_data.c:71
L.RSE_NATIONAL_VAR, L.RSE_NATIONAL_VALUE, L.RSE_NATIONAL_FLAG = 0x403C, 0x0302, 0x838

return require("src.save_convert.gen3_layouts.common").merge(L)
