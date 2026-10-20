local L = {}

L.FAMILY = "emerald"
L.GAME = "emerald"
-- pokeemerald/include/global.h:532
L.KEY_OFF = 0x0AC
L.DAYCARE_SAVE_KEY = "emerald_daycare"
L.PORT = "src.save_convert.gen3_port.rse"
L.KEEP_RAW_NAMES = true
-- pokeemerald/include/constants/global.h:10
L.CART_VERSION = 3

-- pokeemerald/src/save.c:57
L.CHUNK_SIZES = {
  [0] = 0xF2C,
  0xF80, 0xF80, 0xF80, 0xF08,
  0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0x7D0,
}

L.BLOCKS = {
  { key = "sb2", first = 0, last = 0, size = 0xF2C },
  { key = "sb1", first = 1, last = 4, size = 0x3D88 },
  { key = "storage", first = 5, last = 13, size = 0x83D0 },
}

-- pokeemerald/include/save.h:28
L.SECTOR_ID_TRAINER_HILL = 30
L.SECTOR_ID_RECORDED_BATTLE = 31

-- pokeemerald/include/global.h:508
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
  -- pokeemerald/include/global.h:206
  { "dexOrder", 0x018, "u8" },
  { "dexMode", 0x019, "u8" },
  { "dexNationalMagic", 0x01A, "u8" },
  { "dexUnused", 0x01B, "u8" },
  { "unownPersonality", 0x01C, "u32" },
  { "spindaPersonality", 0x020, "u32" },
  { "dexOwned", 0x028, "bits", 52 },
  { "dexSeen", 0x05C, "bits", 52 },
  { "gcnLinkFlags", 0x0A8, "u32" },
  { "encryptionKey", 0x0AC, "u32" },
  -- pokeemerald/include/global.h:250
  { "berryPowder", 0x1F4, "u32", nil, "key32" },
}

-- pokeemerald/include/global.h:984
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
  { "weatherCycleStage", 0x002F, "u8" },
  { "flashLevel", 0x0030, "u8" },
  { "mapLayoutId", 0x0032, "u16" },
  { "partyCount", 0x0234, "u8" },
  { "money", 0x0490, "u32", nil, "key32" },
  { "coins", 0x0494, "u16", nil, "key16" },
  { "registeredItem", 0x0496, "u16" },
  { "dexSeen1", 0x0988, "bits", 52 },
  { "flags", 0x1270, "bits", 300 },
  { "dexSeen2", 0x3B24, "bits", 52 },
}

-- pokeemerald/include/global.h:998
L.MAP_VIEW = { block = "sb1", off = 0x0034, size = 0x200 }
-- pokeemerald/src/new_game.c:123
L.NEW_GAME_SB2 = { { 0xEE1, 0xFF }, { 0xEE9, 0xFF } }
-- pokeemerald/src/event_data.c:69
L.DEX_MODE_NATIONAL = 1
L.TRAINER_NAME_RECORDS = { off = 0x3B98, count = 20 }
L.GAME_CODES = { [3] = "emerald" }

L.PARTY_OFFSET = 0x0238

-- pokeemerald/include/constants/global.h:50
L.PC_ITEMS = { off = 0x0498, count = 50 }
L.POCKETS = {
  { key = "ITEMS", off = 0x0560, count = 30 },
  { key = "KEY_ITEMS", off = 0x05D8, count = 30 },
  { key = "POKE_BALLS", off = 0x0650, count = 16 },
  { key = "TM_CASE", off = 0x0690, count = 64 },
  { key = "BERRY_POUCH", off = 0x0790, count = 46 },
}

-- pokeemerald/include/global.h:1018
L.OBJECT_EVENTS = { off = 0x0A30, count = 16, size = 0x24 }

L.VARS = { off = 0x139C, count = 256, first = 0x4000 }
L.GAME_STATS = { off = 0x159C, count = 64 }
-- pokeemerald/include/global.h:1049
L.EASY_CHAT_PROFILE = { off = 0x2BB0, count = 6 }
L.EASY_CHAT_BATTLE = { start = 0x2BBC, won = 0x2BC8, lost = 0x2BD4, count = 6 }

-- pokeemerald/include/global.h:764
L.MAIL = { off = 0x2BE0, count = 16, size = 36, words = 0x00, wordCount = 9, playerName = 0x12,
  playerNameLength = 8, trainerId = 0x1A, species = 0x1E, itemId = 0x20 }

-- pokeemerald/include/global.h:789
L.DAYCARE = { off = 0x3030, monSize = 0x8C, stepsOff = 0x88, offspringPersonality = 0x118, stepCounter = 0x11C,
  offspringKind = "u32" }

-- pokeemerald/include/global.h:607
L.ROAMER = {
  { "ivs", 0x00, "u32" },
  { "personality", 0x04, "u32" },
  { "species", 0x08, "u16" },
  { "hp", 0x0A, "u16" },
  { "level", 0x0C, "u8" },
  { "status", 0x0D, "u8" },
  { "cool", 0x0E, "u8" },
  { "beauty", 0x0F, "u8" },
  { "cute", 0x10, "u8" },
  { "smart", 0x11, "u8" },
  { "tough", 0x12, "u8" },
  { "active", 0x13, "u8" },
}
L.ROAMER_OFFSET = 0x31DC

-- pokeemerald/include/global.h:1074
L.REGISTERED_TEXTS = { off = 0x3C88, count = 10, size = 21 }

-- pokeemerald/include/global.h:731
L.LINK_BATTLE_RECORDS = { block = "sb1", off = 0x3150, count = 5, size = 16, languages = 0x50 }

-- pokeemerald/src/event_data.c:66
L.NATIONAL_DEX = { magic = 0xDA, var = "VAR_NATIONAL_DEX", varValue = 0x302, flag = "FLAG_SYS_NATIONAL_DEX" }
-- pokeemerald/include/constants/flags.h:1354
L.FLAG_SYS_GAME_CLEAR = "FLAG_SYS_GAME_CLEAR"
-- pokeemerald/include/constants/flags.h:1572
L.FLAGS_COUNT = 0x960

-- pokeemerald/include/constants/heal_locations.h:11
L.HEAL_LOCATION_PALLET_TOWN = 1

-- pokeemerald/include/constants/easy_chat.h:1127
L.EC_MASK_BITS = 9
local P, V, E = "EC_GROUP_PEOPLE", "EC_GROUP_VOICES", "EC_GROUP_ENDINGS"
-- pokeemerald/src/easy_chat.c:1240
L.DEFAULT_EASY_CHAT = {
  profile = { { P, 41 }, { E, 32 }, { "EC_GROUP_TRAINER", 14 }, { P, 51 } },
  start = { { E, 15 }, { P, 2 }, { "EC_GROUP_SPEECH", 37 }, { V, 3 }, { "EC_GROUP_GREETINGS", 3 }, { V, 0 } },
  won = { { V, 58 }, { V, 58 }, { V, 1 }, { P, 42 }, { "EC_GROUP_BATTLE", 7 }, { V, 1 } },
  lost = { { E, 57 }, { "EC_GROUP_FEELINGS", 46 }, { V, 4 }, { P, 61 }, { "EC_GROUP_BATTLE", 48 }, { V, 4 } },
}

-- pokeemerald/include/global.h:984
L.RSE = {
  sb2 = {
    localTimeOffset = 0x098,
    lastBerryTreeUpdate = 0x0A0,
    -- pokeemerald/include/global.h:250
    berryCrush = 0x1EC,
    pokeJump = 0x1FC,
    berryPick = 0x20C,
    contestLinkResults = 0x624,
    frontier = 0x64C,
    -- pokeemerald/include/global.h:449
    battlePoints = 0x64C + 0x86C,
    cardBattlePoints = 0x64C + 0x86E,
  },
  sb1 = {
    pokeblocks = 0x0848, pokeblockCount = 40,
    berryBlenderRecords = 0x09BC,
    trainerRematchStepCounter = 0x09C8,
    trainerRematches = 0x09CA, trainerRematchCount = 100,
    berryTrees = 0x169C, berryTreeCount = 128,
    secretBases = 0x1A9C, secretBaseCount = 20, secretBaseSize = 160,
    playerRoomDecorations = 0x271C,
    playerRoomDecorationPositions = 0x2728,
    decorationInventory = 0x2734,
    tvShows = 0x27CC, tvShowCount = 25, tvShowSize = 36,
    pokeNews = 0x2B50, pokeNewsCount = 16,
    outbreak = 0x2B90,
    gabbyAndTy = 0x2BA4,
    unlockedTrendySayings = 0x2E20,
    oldMan = 0x2E28,
    dewfordTrends = 0x2E68, dewfordTrendCount = 5,
    contestWinners = 0x2E90, contestWinnerCount = 13,
    giftRibbons = 0x31A8, giftRibbonCount = 11,
    externalEventData = 0x31B3,
    externalEventFlags = 0x31C7,
    enigmaBerry = 0x31F8,
    mysteryGift = 0x322C,
    trainerHillTimes = 0x3718,
    ramScript = 0x3728,
    recordMixingGift = 0x3B14,
    lilycoveLady = 0x3B58,
    trainerNameRecords = 0x3B98, trainerNameRecordCount = 20,
    trainerHill = 0x3D64,
    waldaPhrase = 0x3D70,
  },
}

-- pokeemerald/src/data/wallpapers.h:18
L.WALLPAPER_MAX = 16

-- pokeemerald/include/global.h:1027
L.DECOR_CATEGORY_SIZES = { [0] = 10, [1] = 10, [2] = 10, [3] = 30, [4] = 30, [5] = 10, [6] = 40, [7] = 10 }
-- pokeemerald/include/constants/global.h:58
L.DECOR_MAX_PLAYERS_HOUSE = 12

return require("src.save_convert.gen3_layouts.common").merge(L)
