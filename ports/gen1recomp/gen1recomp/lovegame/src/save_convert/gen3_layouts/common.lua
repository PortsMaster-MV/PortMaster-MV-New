local C = {}

-- include/save.h:8
C.SECTOR_DATA_SIZE = 0xF80
-- include/save.h:10
C.SECTOR_SIZE = 0x1000
-- include/save.h:63
C.FOOTER = { id = 0xFF4, checksum = 0xFF6, signature = 0xFF8, counter = 0xFFC }
-- include/save.h:15
C.SIGNATURE = 0x08012025
-- include/save.h:24
C.SECTORS_PER_SLOT = 14
C.NUM_SLOTS = 2
C.NUM_SECTORS = 32
-- include/save.h:26
C.SECTOR_ID_HOF_1 = 28
C.SECTOR_ID_HOF_2 = 29
C.FLASH_SIZE = 0x20000
C.HALF_FLASH_SIZE = 0x10000
C.MAX_TRAILER = 0x3F

-- include/global.h:338
C.OPTIONS_BITS = {
  { "textSpeed", 0, 3 },
  { "frameType", 3, 5 },
  { "sound", 8, 1 },
  { "battleStyle", 9, 1 },
  { "battleScene", 10, 1 },
  { "regionMapZoom", 11, 1 },
}

-- include/global.h:392
C.WARP = { group = { 0, "s8" }, num = { 1, "s8" }, warpId = { 2, "s8" }, x = { 4, "s16" }, y = { 6, "s16" } }

C.PARTY_SIZE = 6
C.PARTY_MON_SIZE = 100
-- include/pokemon.h:133
C.PARTY_MAIL = 85

-- include/global.h:400
C.ITEM_SLOT_SIZE = 4

-- include/global.fieldmap.h:212
C.OBJECT_EVENT = { flags = 0x00, isPlayerByte = 0x02, graphicsId = 0x05, currentX = 0x10, currentY = 0x12, facing = 0x18 }
-- include/fieldmap.h:21
C.MAP_OFFSET = 7

-- include/pokemon_storage_system.h:44
C.STORAGE = {
  currentBox = 0x0000,
  boxes = 0x0004,
  boxNames = 0x8344,
  boxNameLength = 9,
  wallpapers = 0x83C2,
  totalBoxes = 14,
  inBox = 30,
}

-- include/pokemon.h:105
C.BOX_MON_SIZE = 80
C.BOX_MON = {
  personality = 0x00,
  otId = 0x04,
  nickname = 0x08, nicknameLength = 10,
  language = 0x12,
  flags = 0x13,
  otName = 0x14, otNameLength = 7,
  markings = 0x1B,
  checksum = 0x1C,
  unknown = 0x1E,
  secure = 0x20, secureWords = 12,
}
-- include/pokemon.h:111
C.BOX_MON_FLAGS = { isBadEgg = 0, hasSpecies = 1, isEgg = 2 }

C.SUBSTRUCT_SIZE = 12
-- include/pokemon.h:8
C.SUBSTRUCT0 = {
  { "species", 0, "u16" },
  { "heldItem", 2, "u16" },
  { "exp", 4, "u32" },
  { "ppBonuses", 8, "u8" },
  { "friendship", 9, "u8" },
  { "growthFiller", 10, "u16" },
}
-- include/pokemon.h:18
C.SUBSTRUCT1 = { moves = 0, pp = 8 }
-- include/pokemon.h:24
C.EV_KEYS = { "hp", "atk", "def", "spe", "spa", "spd" }
C.CONTEST_KEYS = { "cool", "beauty", "cute", "smart", "tough", "sheen" }
-- include/pokemon.h:40
C.SUBSTRUCT3 = { pokerus = 0, metLocation = 1, origins = 2, ivWord = 4, ribbons = 8 }
-- include/pokemon.h:45
C.ORIGINS_BITS = { { "metLevel", 0, 7 }, { "metGame", 7, 4 }, { "pokeball", 11, 4 }, { "otGender", 15, 1 } }
-- include/pokemon.h:50
C.IV_KEYS = { "hp", "atk", "def", "spe", "spa", "spd" }
C.IV_EGG_BIT = 30
C.IV_ABILITY_BIT = 31
-- include/pokemon.h:64
C.RIBBON_CHAMPION_BIT = 15
-- include/pokemon.h:84
C.RIBBON_FATEFUL_BIT = 31

-- include/pokemon.h:128
C.PARTY_EXTRA = {
  { "status", 80, "u32" },
  { "level", 84, "u8" },
  { "mail", 85, "u8" },
  { "hp", 86, "u16" },
  { "maxHp", 88, "u16" },
  { "attack", 90, "u16" },
  { "defense", 92, "u16" },
  { "speed", 94, "u16" },
  { "spAtk", 96, "u16" },
  { "spDef", 98, "u16" },
}

-- src/pokemon.c:2863
C.SUBSTRUCT_ORDER = {
  [0] = { 0, 1, 2, 3 }, { 0, 1, 3, 2 }, { 0, 2, 1, 3 }, { 0, 3, 1, 2 }, { 0, 2, 3, 1 }, { 0, 3, 2, 1 },
  { 1, 0, 2, 3 }, { 1, 0, 3, 2 }, { 2, 0, 1, 3 }, { 3, 0, 1, 2 }, { 2, 0, 3, 1 }, { 3, 0, 2, 1 },
  { 1, 2, 0, 3 }, { 1, 3, 0, 2 }, { 2, 1, 0, 3 }, { 3, 1, 0, 2 }, { 2, 3, 0, 1 }, { 3, 2, 0, 1 },
  { 1, 2, 3, 0 }, { 1, 3, 2, 0 }, { 2, 1, 3, 0 }, { 3, 1, 2, 0 }, { 2, 3, 1, 0 }, { 3, 2, 1, 0 },
}

-- include/constants/battle.h:91
C.STATUS = { sleepMask = 0x7, PSN = 0x8, BRN = 0x10, FRZ = 0x20, PAR = 0x40, TOX = 0x80 }
C.STATUS_ORDER = { "PSN", "BRN", "FRZ", "PAR", "TOX" }

-- src/hall_of_fame.c:32
C.HOF = { teams = 50, monsPerTeam = 6, monSize = 20, tid = 0, personality = 4, speciesLevel = 8, nick = 10, nickLength = 10 }

-- include/constants/flags.h:44
C.TEMP_FLAGS_END = 0x1F
-- include/constants/pokedex.h:6
C.NATIONAL_DEX_SPECIES = 386
-- include/constants/game_stat.h:5
C.GAME_STAT_FIRST_HOF_PLAY_TIME = 1
-- include/save_location.h:5
C.CONTINUE_GAME_WARP = 0x01
-- include/constants/global.h:110
C.FACING = { [1] = "down", [2] = "up", [3] = "left", [4] = "right" }

-- src/pokemon_storage_system_menu.c:415
C.DEFAULT_BOX_NAME = "BOX%d"
-- src/pokemon_storage_system_menu.c:420
C.DEFAULT_WALLPAPER_MOD = 4
-- include/pokemon_storage_system.h:40
C.WALLPAPER_MAX = 15

-- charmap.txt:2
C.CHARMAP_LATIN = {
  [0x01] = "À", [0x02] = "Á", [0x03] = "Â", [0x04] = "Ç", [0x05] = "È", [0x06] = "É", [0x07] = "Ê", [0x08] = "Ë",
  [0x09] = "Ì", [0x0B] = "Î", [0x0C] = "Ï", [0x0D] = "Ò", [0x0E] = "Ó", [0x0F] = "Ô", [0x10] = "Œ", [0x11] = "Ù",
  [0x12] = "Ú", [0x13] = "Û", [0x14] = "Ñ", [0x15] = "ß", [0x16] = "à", [0x17] = "á", [0x19] = "ç", [0x1A] = "è",
  [0x1B] = "é", [0x1C] = "ê", [0x1D] = "ë", [0x1E] = "ì", [0x20] = "î", [0x21] = "ï", [0x22] = "ò", [0x23] = "ó",
  [0x24] = "ô", [0x25] = "œ", [0x26] = "ù", [0x27] = "ú", [0x28] = "û", [0x29] = "ñ", [0x2A] = "º", [0x2B] = "ª",
  [0x51] = "¿", [0x52] = "¡", [0x5A] = "Í", [0x68] = "â", [0x6F] = "í",
  -- charmap.txt:148
  [0xF1] = "Ä", [0xF2] = "Ö", [0xF3] = "Ü", [0xF4] = "ä", [0xF5] = "ö", [0xF6] = "ü",
}

C.EMPTY_WARP = { group = -1, num = -1, warpId = -1, x = -1, y = -1 }

-- include/constants/global.h:63
C.PLAYER_NAME_LENGTH = 7
C.POKEMON_NAME_LENGTH = 10
-- include/pokemon_storage_system.h:11
C.BOX_NAME_LENGTH = 8
-- include/constants/global.h:20
C.LANGUAGE_JAPANESE = 1
C.LANGUAGE_ENGLISH = 2
-- src/daycare.c:135
C.EGG_NICKNAME = "\x60\x6F\x8B"
-- include/constants/easy_chat.h:1091
C.EC_WORD_UNDEFINED = 0xFFFF
-- src/easy_chat.c:444
C.PORT_PROFILE_WORDS = 4
-- include/save.h:26
C.HOF_SECTORS = 2
-- include/constants/global.h:11
C.VERSION_FIRE_RED = 4
C.VERSION_LEAF_GREEN = 5
-- include/constants/heal_locations.h:11
C.HEAL_LOCATION_PALLET_TOWN = 1

-- include/constants/items.h:451
C.MAIL_NONE = 0xFF
-- src/mail_data.c:28
C.MAIL_CLEAR_SPECIES = 1
-- src/mail_data.c:167
C.MAIL_ITEM_FIRST, C.MAIL_ITEM_LAST = 121, 132
-- src/mail_data.c:41
C.MAIL_PARTY_SLOTS = 6
C.MAIL_NAME_PAD = 6
-- include/global.h:533
C.DAYCARE_MAIL = { off = 80, otName = 36, otNameLength = 8, monName = 44, monNameLength = 11 }

local function ecWord(group, index) return group * 512 + index end
-- src/easy_chat.c:73
C.DEFAULT_BATTLE_START_WORDS = {
  -- include/constants/easy_chat.h:507
  ecWord(0x8, 0xF),
  -- include/constants/easy_chat.h:290
  ecWord(0x5, 0x2),
  -- include/constants/easy_chat.h:467
  ecWord(0x7, 0x25),
  -- include/constants/easy_chat.h:368
  ecWord(0x6, 0x3),
  -- include/constants/easy_chat.h:247
  ecWord(0x4, 0x3),
  -- include/constants/easy_chat.h:365
  ecWord(0x6, 0x0),
}

function C.merge(into)
  for k, v in pairs(C) do
    if into[k] == nil and k ~= "merge" then into[k] = v end
  end
  return into
end

return C
