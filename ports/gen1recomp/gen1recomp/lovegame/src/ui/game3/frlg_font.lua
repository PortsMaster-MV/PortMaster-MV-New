-- FRLG Latin variable-width font (pret latin_normal + sFontNormalLatinGlyphWidths).
-- Field dialogue must use this — Gen2 Font.lua is fixed 8px and overflows the 208px box.

local TextIR = require("src.core.game3.scripting.text_ir")
local CacheBlob = require("src.import.CacheBlob")

local FrlgFont = {}

FrlgFont.CELL = 16
FrlgFont.MAX_LETTER_WIDTH = 10
FrlgFont.GLYPH_HEIGHT = 14
FrlgFont.LINE_PITCH = 15 -- maxLetterHeight(14) + lineSpacing(1)

-- 1:1 Standard Text Palettes from pokefirered/graphics/text_window/stdpal_0.pal
-- GBA 15-bit BGR555 -> 8-bit RGB888 / normalized 0.0-1.0
FrlgFont.STDPAL = {
  [0] = { 0, 0, 0, 0 },                          -- 0: Transparent / Window Fill
  [1] = { 255 / 255, 255 / 255, 255 / 255, 1 },    -- 1: WHITE (#FFFFFF)
  [2] = { 98 / 255, 98 / 255, 98 / 255, 1 },       -- 2: DARK_GRAY (#626262)
  [3] = { 213 / 255, 213 / 255, 205 / 255, 1 },    -- 3: LIGHT_GRAY (#D5D5CD)
  [4] = { 230 / 255, 8 / 255, 8 / 255, 1 },         -- 4: RED (#E60808)
  [5] = { 255 / 255, 189 / 255, 115 / 255, 1 },    -- 5: LIGHT_RED (#FFBD73)
  [6] = { 32 / 255, 156 / 255, 8 / 255, 1 },        -- 6: GREEN (#209C08)
  [7] = { 148 / 255, 246 / 255, 148 / 255, 1 },    -- 7: LIGHT_GREEN (#94F694)
  [8] = { 49 / 255, 82 / 255, 205 / 255, 1 },      -- 8: BLUE (#3152CD)
  [9] = { 164 / 255, 197 / 255, 246 / 255, 1 },    -- 9: LIGHT_BLUE (#A4C5F6)
  [10] = { 255 / 255, 255 / 255, 255 / 255, 1 },   -- 10: DYNAMIC_COLOR1
  [11] = { 213 / 255, 230 / 255, 246 / 255, 1 },   -- 11: DYNAMIC_COLOR2
  [12] = { 164 / 255, 213 / 255, 230 / 255, 1 },   -- 12: DYNAMIC_COLOR3
  [13] = { 230 / 255, 246 / 255, 255 / 255, 1 },   -- 13: DYNAMIC_COLOR4
  [14] = { 115 / 255, 164 / 255, 197 / 255, 1 },   -- 14: DYNAMIC_COLOR5
  [15] = { 74 / 255, 115 / 255, 164 / 255, 1 },    -- 15: DYNAMIC_COLOR6
}

FrlgFont.COLOR_IDS = {
  TRANSPARENT = 0,
  WHITE = 1,
  DARK_GRAY = 2,
  LIGHT_GRAY = 3,
  RED = 4,
  LIGHT_RED = 5,
  GREEN = 6,
  LIGHT_GREEN = 7,
  BLUE = 8,
  LIGHT_BLUE = 9,
}

-- 3-Slot Color Architecture (Foreground, Shadow, Background/Highlight)
FrlgFont.COLOR = {
  -- Standard NPC / Field Dialogue
  NORMAL = { fg = FrlgFont.STDPAL[2], shadow = FrlgFont.STDPAL[3], bg = FrlgFont.STDPAL[0] },
  -- Pokémon Gender Markers (Two tones: Light foreground + Dark shadow)
  MALE = { fg = FrlgFont.STDPAL[9], shadow = FrlgFont.STDPAL[8], bg = FrlgFont.STDPAL[0] },
  GENDER_MALE = { fg = FrlgFont.STDPAL[9], shadow = FrlgFont.STDPAL[8], bg = FrlgFont.STDPAL[0] },
  FEMALE = { fg = FrlgFont.STDPAL[5], shadow = FrlgFont.STDPAL[4], bg = FrlgFont.STDPAL[0] },
  GENDER_FEMALE = { fg = FrlgFont.STDPAL[5], shadow = FrlgFont.STDPAL[4], bg = FrlgFont.STDPAL[0] },
  -- Party Menu Specific Two-Tone Gender Markers (from gPartyMenuBg_Pal 59/60, 75/76)
  PARTY_MALE = {
    fg = { 65 / 255, 205 / 255, 255 / 255, 1 },
    shadow = { 0 / 255, 98 / 255, 148 / 255, 1 },
    bg = FrlgFont.STDPAL[0],
  },
  PARTY_FEMALE = {
    fg = { 255 / 255, 156 / 255, 148 / 255, 1 },
    shadow = { 156 / 255, 65 / 255, 57 / 255, 1 },
    bg = FrlgFont.STDPAL[0],
  },
  -- NPC Dialogue Text Colors (Dark Blue / Dark Red fg, Light Gray shadow)
  MALE_NPC = { fg = FrlgFont.STDPAL[8], shadow = FrlgFont.STDPAL[3], bg = FrlgFont.STDPAL[0] },
  FEMALE_NPC = { fg = FrlgFont.STDPAL[4], shadow = FrlgFont.STDPAL[3], bg = FrlgFont.STDPAL[0] },
  BLUE = { fg = FrlgFont.STDPAL[8], shadow = FrlgFont.STDPAL[3], bg = FrlgFont.STDPAL[0] },
  RED = { fg = FrlgFont.STDPAL[4], shadow = FrlgFont.STDPAL[5], bg = FrlgFont.STDPAL[0] },
  GREEN = { fg = FrlgFont.STDPAL[6], shadow = FrlgFont.STDPAL[7], bg = FrlgFont.STDPAL[0] },
  -- Party slot printers & Battle text (White fg, Dark Gray shadow)
  WHITE = { fg = FrlgFont.STDPAL[1], shadow = FrlgFont.STDPAL[2], bg = FrlgFont.STDPAL[0] },
  LIGHT = { fg = FrlgFont.STDPAL[1], shadow = FrlgFont.STDPAL[2], bg = FrlgFont.STDPAL[0] },
  PARTY = { fg = FrlgFont.STDPAL[1], shadow = FrlgFont.STDPAL[2], bg = FrlgFont.STDPAL[0] },
  STAT = { fg = FrlgFont.STDPAL[4], shadow = FrlgFont.STDPAL[5], bg = FrlgFont.STDPAL[0] },
  DARK_GRAY = { fg = FrlgFont.STDPAL[2], shadow = FrlgFont.STDPAL[3], bg = FrlgFont.STDPAL[0] },
  DARK = { fg = FrlgFont.STDPAL[2], shadow = FrlgFont.STDPAL[3], bg = FrlgFont.STDPAL[0] },
  -- src/option_menu.c:180
  OPTION_VALUE = { fg = FrlgFont.STDPAL[5], shadow = FrlgFont.STDPAL[4], bg = FrlgFont.STDPAL[0] },
}

local FRLG_COLOR_IDS = {}
for k, v in pairs(FrlgFont.COLOR_IDS) do FRLG_COLOR_IDS[k] = v end

-- pokeruby/charmap.txt:391
local RS_COLOR_IDS = {
  TRANSPARENT = 0, DARK_GRAY = 1, DARK_GREY = 1, RED = 2, LIGHT_RED = 2, GREEN = 3, LIGHT_GREEN = 3,
  BLUE = 4, YELLOW = 5, CYAN = 6, MAGENTA = 7, LIGHT_GRAY = 8, LIGHT_GREY = 8, BLACK = 9,
  WHITE = 12, SKY_BLUE = 13, LIGHT_BLUE = 14, WHITE2 = 15,
}

local FRLG_COLOR_SLOTS = {
  MALE = { 9, 8 }, GENDER_MALE = { 9, 8 }, FEMALE = { 5, 4 }, GENDER_FEMALE = { 5, 4 },
  MALE_NPC = { 8, 3 }, FEMALE_NPC = { 4, 3 }, BLUE = { 8, 3 }, RED = { 4, 5 }, GREEN = { 6, 7 },
  WHITE = { 1, 2 }, LIGHT = { 1, 2 }, PARTY = { 1, 2 }, STAT = { 4, 5 }, DARK_GRAY = { 2, 3 }, DARK = { 2, 3 },
  OPTION_VALUE = { 5, 4 },
}

-- pokeruby/src/text.c:247
local RS_COLOR_SLOTS = {
  MALE = { 4, 8 }, GENDER_MALE = { 4, 8 }, FEMALE = { 2, 8 }, GENDER_FEMALE = { 2, 8 },
  MALE_NPC = { 4, 8 }, FEMALE_NPC = { 2, 8 }, BLUE = { 4, 8 }, RED = { 2, 8 }, GREEN = { 3, 8 },
  WHITE = { 12, 1 }, LIGHT = { 12, 1 }, PARTY = { 12, 1 }, STAT = { 2, 8 }, DARK_GRAY = { 1, 8 }, DARK = { 1, 8 },
  OPTION_VALUE = { 2, 8 },
}

local function applyColorSlots(rs)
  local slots = rs and RS_COLOR_SLOTS or FRLG_COLOR_SLOTS
  for name, s in pairs(slots) do
    local c = FrlgFont.COLOR[name]
    c.fg, c.shadow = FrlgFont.STDPAL[s[1]], FrlgFont.STDPAL[s[2]]
  end
  local ids = rs and RS_COLOR_IDS or FRLG_COLOR_IDS
  for k in pairs(FrlgFont.COLOR_IDS) do FrlgFont.COLOR_IDS[k] = nil end
  for k, v in pairs(ids) do FrlgFont.COLOR_IDS[k] = v end
end

FrlgFont.applyColorSlots = applyColorSlots

-- include/constants/vars.h:340
FrlgFont.NPC_TEXT_COLOR = {
  MALE = 0,
  FEMALE = 1,
  MON = 2,
  NEUTRAL = 3,
  DEFAULT = 255,
}

-- 152-element sTextColorTable from pokefirered/src/dynamic_placeholder_text_util.c
-- Each byte holds 2 nybbles: (low_nybble | (high_nybble << 4))
local sTextColorTable = {
  [0]  = 0x00, -- OBJ_EVENT_GFX_RED_NORMAL / OBJ_EVENT_GFX_RED_BIKE
  [1]  = 0x00, -- OBJ_EVENT_GFX_RED_SURF / OBJ_EVENT_GFX_RED_FIELD_MOVE
  [2]  = 0x00, -- OBJ_EVENT_GFX_RED_FISH / OBJ_EVENT_GFX_RED_VS_SEEKER
  [3]  = 0x10, -- OBJ_EVENT_GFX_RED_VS_SEEKER_BIKE / OBJ_EVENT_GFX_GREEN_NORMAL
  [4]  = 0x11, -- OBJ_EVENT_GFX_GREEN_BIKE / OBJ_EVENT_GFX_GREEN_SURF
  [5]  = 0x11, -- OBJ_EVENT_GFX_GREEN_FIELD_MOVE / OBJ_EVENT_GFX_GREEN_FISH
  [6]  = 0x11, -- OBJ_EVENT_GFX_GREEN_VS_SEEKER / OBJ_EVENT_GFX_GREEN_VS_SEEKER_BIKE
  [7]  = 0x10, -- OBJ_EVENT_GFX_RS_BRENDAN / OBJ_EVENT_GFX_RS_MAY
  [8]  = 0x10, -- OBJ_EVENT_GFX_LITTLE_BOY / OBJ_EVENT_GFX_LITTLE_GIRL
  [9]  = 0x00, -- OBJ_EVENT_GFX_YOUNGSTER / OBJ_EVENT_GFX_BOY
  [10] = 0x00, -- OBJ_EVENT_GFX_BUG_CATCHER / OBJ_EVENT_GFX_SITTING_BOY
  [11] = 0x11, -- OBJ_EVENT_GFX_LASS / OBJ_EVENT_GFX_WOMAN_1
  [12] = 0x01, -- OBJ_EVENT_GFX_CRUSH_GIRL / OBJ_EVENT_GFX_MAN
  [13] = 0x00, -- OBJ_EVENT_GFX_ROCKER / OBJ_EVENT_GFX_FAT_MAN
  [14] = 0x11, -- OBJ_EVENT_GFX_WOMAN_2 / OBJ_EVENT_GFX_BEAUTY
  [15] = 0x10, -- OBJ_EVENT_GFX_BALDING_MAN / OBJ_EVENT_GFX_WOMAN_3
  [16] = 0x00, -- OBJ_EVENT_GFX_OLD_MAN_1 / OBJ_EVENT_GFX_OLD_MAN_2
  [17] = 0x10, -- OBJ_EVENT_GFX_OLD_MAN_LYING_DOWN / OBJ_EVENT_GFX_OLD_WOMAN
  [18] = 0x10, -- OBJ_EVENT_GFX_TUBER_M_WATER / OBJ_EVENT_GFX_TUBER_F
  [19] = 0x00, -- OBJ_EVENT_GFX_TUBER_M_LAND / OBJ_EVENT_GFX_CAMPER
  [20] = 0x01, -- OBJ_EVENT_GFX_PICNICKER / OBJ_EVENT_GFX_COOLTRAINER_M
  [21] = 0x01, -- OBJ_EVENT_GFX_COOLTRAINER_F / OBJ_EVENT_GFX_SWIMMER_M_WATER
  [22] = 0x01, -- OBJ_EVENT_GFX_SWIMMER_F_WATER / OBJ_EVENT_GFX_SWIMMER_M_LAND
  [23] = 0x01, -- OBJ_EVENT_GFX_SWIMMER_F_LAND / OBJ_EVENT_GFX_WORKER_M
  [24] = 0x01, -- OBJ_EVENT_GFX_WORKER_F / OBJ_EVENT_GFX_ROCKET_M
  [25] = 0x01, -- OBJ_EVENT_GFX_ROCKET_F / OBJ_EVENT_GFX_GBA_KID
  [26] = 0x00, -- OBJ_EVENT_GFX_POKE_MANIAC / OBJ_EVENT_GFX_BIKER
  [27] = 0x00, -- OBJ_EVENT_GFX_BLACK_BELT / OBJ_EVENT_GFX_SCIENTIST
  [28] = 0x00, -- OBJ_EVENT_GFX_HIKER / OBJ_EVENT_GFX_FISHER
  [29] = 0x01, -- OBJ_EVENT_GFX_CHANNELER / OBJ_EVENT_GFX_CHEF
  [30] = 0x00, -- OBJ_EVENT_GFX_POLICEMAN / OBJ_EVENT_GFX_GENTLEMAN
  [31] = 0x00, -- OBJ_EVENT_GFX_SAILOR / OBJ_EVENT_GFX_CAPTAIN
  [32] = 0x11, -- OBJ_EVENT_GFX_NURSE / OBJ_EVENT_GFX_CABLE_CLUB_RECEPTIONIST
  [33] = 0x01, -- OBJ_EVENT_GFX_UNION_ROOM_RECEPTIONIST / OBJ_EVENT_GFX_UNUSED_MALE_RECEPTIONIST
  [34] = 0x00, -- OBJ_EVENT_GFX_CLERK / OBJ_EVENT_GFX_MG_DELIVERYMAN
  [35] = 0x00, -- OBJ_EVENT_GFX_TRAINER_TOWER_DUDE / OBJ_EVENT_GFX_PROF_OAK
  [36] = 0x00, -- OBJ_EVENT_GFX_BLUE / OBJ_EVENT_GFX_BILL
  [37] = 0x10, -- OBJ_EVENT_GFX_LANCE / OBJ_EVENT_GFX_AGATHA
  [38] = 0x11, -- OBJ_EVENT_GFX_DAISY / OBJ_EVENT_GFX_LORELEI
  [39] = 0x00, -- OBJ_EVENT_GFX_MR_FUJI / OBJ_EVENT_GFX_BRUNO
  [40] = 0x10, -- OBJ_EVENT_GFX_BROCK / OBJ_EVENT_GFX_MISTY
  [41] = 0x10, -- OBJ_EVENT_GFX_LT_SURGE / OBJ_EVENT_GFX_ERIKA
  [42] = 0x10, -- OBJ_EVENT_GFX_KOGA / OBJ_EVENT_GFX_SABRINA
  [43] = 0x00, -- OBJ_EVENT_GFX_BLAINE / OBJ_EVENT_GFX_GIOVANNI
  [44] = 0x01, -- OBJ_EVENT_GFX_MOM / OBJ_EVENT_GFX_CELIO
  [45] = 0x00, -- OBJ_EVENT_GFX_TEACHY_TV_HOST / OBJ_EVENT_GFX_GYM_GUY
  [46] = 0x33, -- OBJ_EVENT_GFX_ITEM_BALL / OBJ_EVENT_GFX_TOWN_MAP
  [47] = 0x33, -- OBJ_EVENT_GFX_POKEDEX / OBJ_EVENT_GFX_CUT_TREE
  [48] = 0x33, -- OBJ_EVENT_GFX_ROCK_SMASH_ROCK / OBJ_EVENT_GFX_PUSHABLE_BOULDER
  [49] = 0x33, -- OBJ_EVENT_GFX_FOSSIL / OBJ_EVENT_GFX_RUBY
  [50] = 0x33, -- OBJ_EVENT_GFX_SAPPHIRE / OBJ_EVENT_GFX_OLD_AMBER
  [51] = 0x33, -- OBJ_EVENT_GFX_GYM_SIGN / OBJ_EVENT_GFX_SIGN
  [52] = 0x33, -- OBJ_EVENT_GFX_TRAINER_TIPS / OBJ_EVENT_GFX_CLIPBOARD
  [53] = 0x33, -- OBJ_EVENT_GFX_METEORITE / OBJ_EVENT_GFX_LAPRAS_DOLL
  [54] = 0x23, -- OBJ_EVENT_GFX_SEAGALLOP / OBJ_EVENT_GFX_SNORLAX
  [55] = 0x22, -- OBJ_EVENT_GFX_SPEAROW / OBJ_EVENT_GFX_CUBONE
  [56] = 0x22, -- OBJ_EVENT_GFX_POLIWRATH / OBJ_EVENT_GFX_CLEFAIRY
  [57] = 0x22, -- OBJ_EVENT_GFX_PIDGEOT / OBJ_EVENT_GFX_JIGGLYPUFF
  [58] = 0x22, -- OBJ_EVENT_GFX_PIDGEY / OBJ_EVENT_GFX_CHANSEY
  [59] = 0x22, -- OBJ_EVENT_GFX_OMANYTE / OBJ_EVENT_GFX_KANGASKHAN
  [60] = 0x22, -- OBJ_EVENT_GFX_PIKACHU / OBJ_EVENT_GFX_PSYDUCK
  [61] = 0x22, -- OBJ_EVENT_GFX_NIDORAN_F / OBJ_EVENT_GFX_NIDORAN_M
  [62] = 0x22, -- OBJ_EVENT_GFX_NIDORINO / OBJ_EVENT_GFX_MEOWTH
  [63] = 0x22, -- OBJ_EVENT_GFX_SEEL / OBJ_EVENT_GFX_VOLTORB
  [64] = 0x22, -- OBJ_EVENT_GFX_SLOWPOKE / OBJ_EVENT_GFX_SLOWBRO
  [65] = 0x22, -- OBJ_EVENT_GFX_MACHOP / OBJ_EVENT_GFX_WIGGLYTUFF
  [66] = 0x22, -- OBJ_EVENT_GFX_DODUO / OBJ_EVENT_GFX_FEAROW
  [67] = 0x22, -- OBJ_EVENT_GFX_MACHOKE / OBJ_EVENT_GFX_LAPRAS
  [68] = 0x22, -- OBJ_EVENT_GFX_ZAPDOS / OBJ_EVENT_GFX_MOLTRES
  [69] = 0x22, -- OBJ_EVENT_GFX_ARTICUNO / OBJ_EVENT_GFX_MEWTWO
  [70] = 0x22, -- OBJ_EVENT_GFX_MEW / OBJ_EVENT_GFX_ENTEI
  [71] = 0x22, -- OBJ_EVENT_GFX_SUICUNE / OBJ_EVENT_GFX_RAIKOU
  [72] = 0x22, -- OBJ_EVENT_GFX_LUGIA / OBJ_EVENT_GFX_HO_OH
  [73] = 0x22, -- OBJ_EVENT_GFX_CELEBI / OBJ_EVENT_GFX_KABUTO
  [74] = 0x22, -- OBJ_EVENT_GFX_DEOXYS_D / OBJ_EVENT_GFX_DEOXYS_A
  [75] = 0x32, -- OBJ_EVENT_GFX_DEOXYS_N / OBJ_EVENT_GFX_SS_ANNE
}

--- Lookup NPC text color enum from graphicsId (0=Male, 1=Female, 2=Mon, 3=Neutral).
function FrlgFont.getNpcTextColor(graphicId)
  if not graphicId then return FrlgFont.NPC_TEXT_COLOR.NEUTRAL end
  local spec = FrlgFont.sync and FrlgFont.sync()
  if spec and spec.npcTextColors == false then return FrlgFont.NPC_TEXT_COLOR.NEUTRAL end
  graphicId = tonumber(graphicId)
  if not graphicId or graphicId < 0 then return FrlgFont.NPC_TEXT_COLOR.NEUTRAL end
  local idx = math.floor(graphicId / 2)
  if idx > 75 or not sTextColorTable[idx] then
    return FrlgFont.NPC_TEXT_COLOR.NEUTRAL
  end
  local shift = (graphicId % 2) * 4
  local val = math.floor(sTextColorTable[idx] / (2 ^ shift)) % 16
  return val
end

--- Get 3-slot color table for an NPC graphicsId.
function FrlgFont.colorForNpc(graphicId)
  local c = FrlgFont.getNpcTextColor(graphicId)
  if c == FrlgFont.NPC_TEXT_COLOR.MALE then
    return FrlgFont.COLOR.MALE_NPC
  elseif c == FrlgFont.NPC_TEXT_COLOR.FEMALE then
    return FrlgFont.COLOR.FEMALE_NPC
  else
    return FrlgFont.COLOR.NORMAL
  end
end

-- pret DecompressGlyph_Small: height 13; widths ~4–8 (party nick/HP).
FrlgFont.SMALL_GLYPH_HEIGHT = 13
FrlgFont.SMALL_LINE_PITCH = 14

FrlgFont._fg = nil
FrlgFont._sh = nil
FrlgFont._quads = nil
FrlgFont._widths = nil
FrlgFont._small = nil -- { fg, sh, quads, widths }
FrlgFont._rev = nil -- UTF-8 char → glyph id
FrlgFont._logged = false

local FG_PATHS = {
  { path = "chrome/fonts/latin_normal_fg.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/latin_normal_fg.rgba", w = 256, h = 512 },
}
local SH_PATHS = {
  { path = "chrome/fonts/latin_normal_shadow.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/latin_normal_shadow.rgba", w = 256, h = 512 },
}
local SMALL_FG_PATHS = {
  { path = "chrome/fonts/latin_small_fg.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/latin_small_fg.rgba", w = 256, h = 512 },
}
local SMALL_SH_PATHS = {
  { path = "chrome/fonts/latin_small_shadow.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/latin_small_shadow.rgba", w = 256, h = 512 },
}

local function log(msg)
  print("[game3/frlg_font] " .. tostring(msg))
end

local function loadImage(candidates)
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  for _, item in ipairs(candidates) do
    local path = type(item) == "table" and item.path or item
    local w = type(item) == "table" and item.w or 256
    local h = type(item) == "table" and item.h or 512
    local data = nil
    if okC and CacheFs then
      if CacheFs.readActive then
        data = CacheFs.readActive(path)
      end
      if not data and CacheFs.read then
        data = CacheFs.read(path)
      end
    end
    if not data and love and love.filesystem and love.filesystem.read then
      data = CacheBlob.readFs(path)
      if not data then
        data = CacheBlob.readFs("data/generated/gba/" .. (path:gsub("^data/generated/gba/", "")))
      end
    end
    if not data then
      local f = io.open(path, "rb") or io.open("data/generated/gba/" .. (path:gsub("^data/generated/gba/", "")), "rb")
      if f then
        data = CacheBlob.decode(path, f:read("*a"))
        f:close()
      end
    end
    if data and type(data) == "string" and #data > 0 then
      if #data == w * h * 4 and love and love.image and love.graphics then
        local okId, id = pcall(love.image.newImageData, w, h, "rgba8", data)
        if okId and id then
          local img = love.graphics.newImage(id)
          if img and img.setFilter then img:setFilter("nearest", "nearest") end
          return img, path, id
        end
      elseif love and love.filesystem and love.image and love.graphics then
        local okFd, fd = pcall(love.filesystem.newFileData, data, path)
        if okFd and fd then
          local okId, id = pcall(love.image.newImageData, fd)
          if okId and id then
            local img = love.graphics.newImage(id)
            if img and img.setFilter then img:setFilter("nearest", "nearest") end
            return img, path, id
          end
        end
      end
    end
    if love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
      local ok, img = pcall(love.graphics.newImage, path)
      if ok and img then
        if img.setFilter then img:setFilter("nearest", "nearest") end
        return img, path
      end
    end
  end
  return nil, nil
end

-- Pack a sheet's fg and shadow images into one texture (fg on top, shadow
-- below a transparent gap) with matching quads.  Each glyph still draws its
-- shadow then its fg, but from the same texture, so LOVE's autobatcher keeps
-- a whole string in one draw call instead of flushing on every texture swap.
-- Pixels are copied verbatim, so the output is unchanged.  nil (draw from the
-- separate sheets) when either ImageData is missing or they do not match.
local ATLAS_GAP = 16
local function pack_atlas(fgData, shData, quads)
  if not (fgData and shData and quads and love and love.image and love.image.newImageData
      and love.graphics and love.graphics.newImage and love.graphics.newQuad) then
    return nil
  end
  local ok, atlas = pcall(function()
    local w, h = fgData:getDimensions()
    local sw, shh = shData:getDimensions()
    if sw ~= w or shh ~= h then return nil end
    if fgData.getFormat and shData.getFormat and fgData:getFormat() ~= shData:getFormat() then return nil end
    local off = h + ATLAS_GAP
    local fmt = fgData.getFormat and fgData:getFormat() or "rgba8"
    local data = love.image.newImageData(w, off + h, fmt)
    data:paste(fgData, 0, 0, 0, 0, w, h)
    data:paste(shData, 0, off, 0, 0, w, h)
    local img = love.graphics.newImage(data)
    if img.setFilter then img:setFilter("nearest", "nearest") end
    local aw, ah = img:getDimensions()
    local fq, sq = {}, {}
    for id, q in pairs(quads) do
      local qx, qy, qw, qh = q:getViewport()
      fq[id] = love.graphics.newQuad(qx, qy, qw, qh, aw, ah)
      sq[id] = love.graphics.newQuad(qx, qy + off, qw, qh, aw, ah)
    end
    return { image = img, fg = fq, sh = sq, src = quads }
  end)
  return ok and atlas or nil
end

local function loadTable(path)
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  if not (okC and CacheFs and CacheFs.readActive) then return nil end
  local src = CacheFs.readActive(path)
  if type(src) ~= "string" then return nil end
  local chunk = load(src, "@" .. path, "t", {})
  if not chunk then return nil end
  local ok, t = pcall(chunk)
  return ok and type(t) == "table" and t or nil
end

FrlgFont._syncVersion = nil
FrlgFont._spec = nil
FrlgFont._faces = {}
FrlgFont._stdpalSaved = nil

local function applyPalette(spec)
  local pal = spec and spec.palette and loadTable(spec.palette.file)
  if pal and spec.palette.key then pal = pal[spec.palette.key] end
  if type(pal) == "table" then
    if not FrlgFont._stdpalSaved then
      FrlgFont._stdpalSaved = {}
      for i = 1, 15 do
        local c = FrlgFont.STDPAL[i]
        FrlgFont._stdpalSaved[i] = { c[1], c[2], c[3], c[4] }
      end
    end
    for i = 1, 15 do
      local rgb, c = pal[i], FrlgFont.STDPAL[i]
      if type(rgb) == "table" then
        c[1], c[2], c[3], c[4] = rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1
      end
    end
  elseif FrlgFont._stdpalSaved then
    for i = 1, 15 do
      local s, c = FrlgFont._stdpalSaved[i], FrlgFont.STDPAL[i]
      c[1], c[2], c[3], c[4] = s[1], s[2], s[3], s[4]
    end
    FrlgFont._stdpalSaved = nil
  end
  local colors = spec and spec.defaultColors or { fg = 2, shadow = 3, bg = 0 }
  FrlgFont.COLOR.NORMAL.fg = FrlgFont.STDPAL[colors.fg]
  FrlgFont.COLOR.NORMAL.shadow = FrlgFont.STDPAL[colors.shadow]
  FrlgFont.COLOR.NORMAL.bg = FrlgFont.STDPAL[colors.bg]
  applyColorSlots(spec and spec.nativeLayout == "rs")
end

local function resolveSpec()
  local Profile = package.loaded["src.core.game3.profile"]
  if not Profile then
    local ok, P = pcall(require, "src.core.game3.profile")
    if not ok then return nil, nil end
    Profile = P
  end
  local ok, row = pcall(Profile.forSession)
  local font = ok and type(row) == "table" and row.font or nil
  if type(font) == "table" and type(font.faces) == "table" then return font, row.id end
  return nil, nil
end

local function sync()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.session
  local GV = package.loaded["src.core.GameVersion"]
  local v = (type(session) == "table" and session.version) or (GV and GV.current) or ""
  if v == FrlgFont._syncVersion then return FrlgFont._spec end
  FrlgFont._syncVersion = v
  local spec, id = resolveSpec()
  local key = spec and id or "frlg"
  if FrlgFont._specKey ~= key then
    if FrlgFont._specKey ~= nil then FrlgFont.invalidate() end
    FrlgFont._specKey = key
    applyPalette(spec)
  end
  FrlgFont._spec = spec
  return spec
end

FrlgFont.sync = sync

local function metricsFor(spec, fontId)
  if FrlgFont._metrics == nil then
    FrlgFont._metrics = spec.metrics and loadTable(spec.metrics) or false
  end
  for _, m in pairs(FrlgFont._metrics or {}) do
    if type(m) == "table" and m.name == fontId then return m end
  end
  return nil
end

local function faceName(opts)
  return (opts and opts.font) or ((opts and opts.small) and "small") or "normal"
end

local function loadFace(spec, name, language, textMode)
  local key = language and language .. ":" .. name or name
  if spec.nativeLayout == "rs" and textMode == 1 then key = key .. ":monospace" end
  local cached = FrlgFont._faces[key]
  if cached ~= nil then return cached or nil end
  if spec.palette and not FrlgFont._stdpalSaved then applyPalette(spec) end
  if spec.faceLoader then
    local face = require(spec.faceLoader).load(spec, name, language or "latin", loadImage, loadTable, FrlgFont.STDPAL, textMode)
    FrlgFont._faces[key] = face
    return face
  end
  local fs = spec.faces[name]
  if type(fs) ~= "table" then
    error("FrlgFont: the active profile has no font face '" .. tostring(name) .. "'", 0)
  end
  local dir = spec.dir or ""
  local fg, fgp, fgData = loadImage({ { path = dir .. fs.sheet .. "_fg.rgba", w = 256, h = 512 } })
  local sh, _, shData = loadImage({ { path = dir .. fs.sheet .. "_shadow.rgba", w = 256, h = 512 } })
  local widths = fs.widths and loadTable(dir .. fs.widths)
  local m = metricsFor(spec, fs.fontId)
  if not (fg and widths and m) then
    log(fs.sheet .. " missing from the cache")
    FrlgFont._faces[name] = false
    return nil
  end
  local iw, ih = fg:getDimensions()
  local quads = {}
  for id = 0, 511 do
    local gw = tonumber(widths[id] or widths[0]) or 16
    if gw <= 0 or gw > 16 then gw = 16 end
    -- pokeemerald/src/text.c:608
    quads[id] = love.graphics.newQuad((id % 16) * 16, math.floor(id / 16) * 16, gw, 16, iw, ih)
  end
  local face = {
    name = name, fg = fg, sh = sh, quads = quads, widths = widths,
    height = m.maxLetterHeight, pitch = m.maxLetterHeight + (m.lineSpacing or 0),
    letterSpacing = m.letterSpacing or 0,
    atlas = pack_atlas(fgData, shData, quads),
  }
  FrlgFont._faces[name] = face
  log(fs.sheet .. " ready " .. tostring(fgp))
  return face
end

local function faceFor(opts, glyphId)
  local spec = sync()
  if not spec then return nil end
  local language = spec.nativeLayout == "rs" and ((glyphId and glyphId >= FrlgFont.JAPANESE_BASE) or (opts and opts.japanese)) and "japanese" or nil
  return loadFace(spec, faceName(opts), language, opts and opts.textMode)
end

FrlgFont.face = faceFor

local function nativeQuad(face, glyphId, x)
  if face.boundaryQuads and x % 8 == 5 and face.boundaryQuads[glyphId] then
    return face.boundaryQuads[glyphId]
  end
  return face.quads[glyphId]
end

local function faceAdvance(face, glyphId)
  local w = face.widths[glyphId]
  if w == nil then w = face.widths[0] or 0 end
  return w
end

function FrlgFont.linePitch(opts)
  local face = faceFor(opts)
  if face then return face.pitch end
  return (opts and opts.small) and FrlgFont.SMALL_LINE_PITCH or FrlgFont.LINE_PITCH
end

local function ensure()
  if FrlgFont._fg and FrlgFont._widths and FrlgFont._quads then
    return true
  end
  local widths = FrlgFont._widths
  if not widths then
    local okC, CacheFs = pcall(require, "src.import.CacheFs")
    local src
    if okC and CacheFs then
      if CacheFs.readActive then
        src = CacheFs.readActive("data/generated/gba/chrome/fonts/latin_widths.lua")
      end
      if not src and CacheFs.read then
        src = CacheFs.read("data/generated/gba/chrome/fonts/latin_widths.lua")
      end
    end
    if not src and love and love.filesystem and love.filesystem.read then
      src = love.filesystem.read("data/generated/gba/chrome/fonts/latin_widths.lua")
        or love.filesystem.read("chrome/fonts/latin_widths.lua")
    end
    if src and type(src) == "string" then
      local chunk = load(src, "@latin_widths.lua", "t", {}) or load(src)
      if chunk then widths = chunk() end
    end
  end
  if not widths then
    local ok, w = pcall(require, "src.import.gba.chrome.fonts.latin_widths")
    if ok and type(w) == "table" then
      widths = w
    else
      local path = "sevii/gba/chrome/fonts/latin_widths.lua"
      local chunk = loadfile(path)
      if chunk then widths = chunk() end
    end
  end
  FrlgFont._widths = widths or {}

  local fg, fgp, fgData = loadImage(FG_PATHS)
  local sh, _, shData = loadImage(SH_PATHS)
  if not fg then
    if not FrlgFont._logged then
      log("latin_normal font missing")
      FrlgFont._logged = true
    end
    return false
  end
  FrlgFont._fg = fg
  FrlgFont._sh = sh
  local iw, ih = fg:getDimensions()
  local quads = {}
  for id = 0, 511 do
    local col = id % 16
    local row = math.floor(id / 16)
    quads[id] = love.graphics.newQuad(col * 16, row * 16, 16, 16, iw, ih)
  end
  FrlgFont._quads = quads
  FrlgFont._atlas = pack_atlas(fgData, shData, quads)
  if not FrlgFont._logged then
    log("latin_normal ready " .. tostring(fgp))
    FrlgFont._logged = true
  end
  return true
end

local function ensure_small()
  if FrlgFont._small and FrlgFont._small.fg and FrlgFont._small.quads then
    return true
  end
  local widths
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  local src
  if okC and CacheFs then
    if CacheFs.readActive then
      src = CacheFs.readActive("data/generated/gba/chrome/fonts/latin_small_widths.lua")
    end
    if not src and CacheFs.read then
      src = CacheFs.read("data/generated/gba/chrome/fonts/latin_small_widths.lua")
    end
  end
  if not src and love and love.filesystem and love.filesystem.read then
    src = love.filesystem.read("data/generated/gba/chrome/fonts/latin_small_widths.lua")
      or love.filesystem.read("chrome/fonts/latin_small_widths.lua")
  end
  if src and type(src) == "string" then
    local chunk = load(src, "@latin_small_widths.lua", "t", {}) or load(src)
    if chunk then widths = chunk() end
  end
  if not widths then
    local ok, w = pcall(require, "src.import.gba.chrome.fonts.latin_small_widths")
    if ok and type(w) == "table" then
      widths = w
    else
      local chunk = loadfile("sevii/gba/chrome/fonts/latin_small_widths.lua")
      if chunk then widths = chunk() end
    end
  end
  local fg, fgp, fgData = loadImage(SMALL_FG_PATHS)
  local sh, _, shData = loadImage(SMALL_SH_PATHS)
  if not fg then return false end
  local iw, ih = fg:getDimensions()
  local quads = {}
  local maxId = math.floor(iw / 16) * math.floor(ih / 16) - 1
  for id = 0, math.max(255, maxId) do
    local col = id % 16
    local row = math.floor(id / 16)
    if row * 16 + 16 <= ih then
      quads[id] = love.graphics.newQuad(col * 16, row * 16, 16, 16, iw, ih)
    end
  end
  -- Sheets from extract_latin_small.py (ROM hwlat @ 0x1EAF00), CHARMAP-ordered.
  FrlgFont._small = {
    fg = fg, sh = sh, quads = quads, widths = widths or {}, _romBaked = true,
    atlas = pack_atlas(fgData, shData, quads),
  }
  log("latin_small ready " .. tostring(fgp) .. " (ROM FONT_SMALL)")
  return true
end

-- The US cart's Japanese fonts (pokefirered/src/text.c:141, :227), which the
-- text printer draws for a string in Japanese mode.  Their glyphs are numbered
-- like the Latin ones, so a Japanese character's id is its byte in the
-- Japanese block of pokefirered/charmap.txt, offset by JAPANESE_BASE so it
-- never collides with a Latin glyph.  Only characters with no Latin glyph take
-- them: kana, and the full-width digits, letters and punctuation Japanese text
-- is written with.
FrlgFont.JAPANESE_BASE = 0x400

local JP_FG_PATHS = {
  { path = "chrome/fonts/japanese_normal_fg.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/japanese_normal_fg.rgba", w = 256, h = 512 },
}
local JP_SH_PATHS = {
  { path = "chrome/fonts/japanese_normal_shadow.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/japanese_normal_shadow.rgba", w = 256, h = 512 },
}
local JP_SMALL_FG_PATHS = {
  { path = "chrome/fonts/japanese_small_fg.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/japanese_small_fg.rgba", w = 256, h = 512 },
}
local JP_SMALL_SH_PATHS = {
  { path = "chrome/fonts/japanese_small_shadow.rgba", w = 256, h = 512 },
  { path = "data/generated/gba/chrome/fonts/japanese_small_shadow.rgba", w = 256, h = 512 },
}

-- pokefirered/charmap.txt: hiragana 01-50, katakana 51-A0, "　" 00, ！？。ー AB-AE,
-- ‥ B0.  The font continues with the same symbols as the Latin block at the
-- same codes (digits A1-AA, 『』「」 B1-B4, ♂♀ B5-B6, 円 B7, letters BB-EE, ▶ EF,
-- ： F0), which Japanese text writes in their full-width forms.
local HIRAGANA = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんぁぃぅぇぉゃゅょがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽっ"
local KATAKANA = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンァィゥェォャュョガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポッ"
local function japanese_glyphs()
  local t = {}
  local code = 0x01
  for ch in (HIRAGANA .. KATAKANA):gmatch("[\xE0-\xEF][\x80-\xBF][\x80-\xBF]") do
    t[ch] = code
    code = code + 1
  end
  local function run(first, from, n)
    local b1, b2, b3 = from:byte(1, 3)
    local cp = (b1 % 16) * 4096 + (b2 % 64) * 64 + (b3 % 64)
    for i = 0, n - 1 do
      local c = cp + i
      t[string.char(0xE0 + math.floor(c / 4096), 0x80 + math.floor(c / 64) % 64, 0x80 + c % 64)] = first + i
    end
  end
  run(0xA1, "０", 10)
  run(0xBB, "Ａ", 26)
  run(0xD5, "ａ", 26)
  local more = {
    ["　"] = 0x00, ["！"] = 0xAB, ["？"] = 0xAC, ["。"] = 0xAD, ["ー"] = 0xAE, ["・"] = 0xAF,
    ["‥"] = 0xB0, ["…"] = 0xB0, ["『"] = 0xB1, ["』"] = 0xB2, ["「"] = 0xB3, ["」"] = 0xB4,
    ["円"] = 0xB7, ["．"] = 0xB8, ["／"] = 0xBA, ["："] = 0xF0,
  }
  for ch, c in pairs(more) do t[ch] = c end
  return t
end
FrlgFont.JAPANESE_GLYPHS = japanese_glyphs()

local function load_japanese(key, fgPaths, shPaths)
  if FrlgFont[key] ~= nil then return FrlgFont[key] or nil end
  local fg, _, fgData = loadImage(fgPaths)
  if not fg then
    FrlgFont[key] = false
    return nil
  end
  local sh, _, shData = loadImage(shPaths)
  local iw, ih = fg:getDimensions()
  local quads = {}
  for code = 0, 511 do
    quads[code] = love.graphics.newQuad((code % 16) * 16, math.floor(code / 16) * 16, 16, 16, iw, ih)
  end
  FrlgFont[key] = { fg = fg, sh = sh, quads = quads, atlas = pack_atlas(fgData, shData, quads) }
  return FrlgFont[key]
end

local function japanese_widths()
  if FrlgFont._jpWidths then return FrlgFont._jpWidths end
  local widths
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  local path = "data/generated/gba/chrome/fonts/japanese_widths.lua"
  local src = okC and CacheFs and ((CacheFs.readActive and CacheFs.readActive(path)) or (CacheFs.read and CacheFs.read(path)))
  if not src and love and love.filesystem and love.filesystem.read then
    src = love.filesystem.read(path) or love.filesystem.read("chrome/fonts/japanese_widths.lua")
  end
  if type(src) == "string" then
    local chunk = load(src, "@japanese_widths.lua", "t", {})
    if chunk then widths = chunk() end
  end
  FrlgFont._jpWidths = widths or {}
  return FrlgFont._jpWidths
end

-- The Japanese sheet (small or normal) and the quad for a Japanese glyph id.
local function japanese_quad(glyphId, small)
  local sheet = small and load_japanese("_jpSmall", JP_SMALL_FG_PATHS, JP_SMALL_SH_PATHS)
    or load_japanese("_jpNormal", JP_FG_PATHS, JP_SH_PATHS)
  if not sheet then return nil end
  return sheet.fg, sheet.sh, sheet.quads[glyphId - FrlgFont.JAPANESE_BASE], sheet.atlas
end

-- The remaining single characters of the Latin block of pret
-- pokefirered/charmap.txt: glyphs the US ROM font draws (latin_normal and
-- latin_small, both charmap-ordered) that US text never prints, so
-- TextIR.CHARMAP (the decode table) leaves them out.  Named multi-glyph
-- entries (LV, POKEBLOCK, the SUPER_E/ER/RE superscripts) are not characters
-- and stay out.
-- Mod text in French, German, Spanish or Italian needs them; without an entry
-- glyphId falls back to 0x00 and the letter prints blank.  Render-only: the
-- ROM decode path is unchanged.
FrlgFont.LATIN_GLYPHS = {
  [0x01] = "À", [0x02] = "Á", [0x03] = "Â", [0x04] = "Ç", [0x05] = "È",
  [0x07] = "Ê", [0x08] = "Ë", [0x09] = "Ì", [0x0B] = "Î", [0x0C] = "Ï",
  [0x0D] = "Ò", [0x0E] = "Ó", [0x0F] = "Ô", [0x10] = "Œ", [0x11] = "Ù",
  [0x12] = "Ú", [0x13] = "Û", [0x14] = "Ñ", [0x15] = "ß", [0x16] = "à",
  [0x17] = "á", [0x19] = "ç", [0x1A] = "è", [0x1C] = "ê", [0x1D] = "ë",
  [0x1E] = "ì", [0x20] = "î", [0x21] = "ï", [0x22] = "ò", [0x23] = "ó",
  [0x24] = "ô", [0x25] = "œ", [0x26] = "ù", [0x27] = "ú", [0x28] = "û",
  [0x29] = "ñ", [0x2A] = "º", [0x2B] = "ª", [0x36] = ";", [0x51] = "¿",
  [0x52] = "¡", [0x5A] = "Í", [0x68] = "â", [0x6F] = "í",
  [0xEF] = "▶", [0xF1] = "Ä", [0xF2] = "Ö", [0xF3] = "Ü", [0xF4] = "ä",
  [0xF5] = "ö", [0xF6] = "ü",
}

local function buildRev()
  if FrlgFont._rev then return FrlgFont._rev end
  local rev = {
    [" "] = 0x00,
    ["\n"] = 0xFE,
    ["№"] = 0x108,
    ["↑"] = 0x100, ["↓"] = 0x101, ["←"] = 0x102, ["→"] = 0x103,
    ["①"] = 0x10A, ["②"] = 0x10B, ["③"] = 0x10C,
    ["④"] = 0x10D, ["⑤"] = 0x10E, ["⑥"] = 0x10F,
    ["⑦"] = 0x110, ["⑧"] = 0x111, ["⑨"] = 0x112,
    ["◎"] = 0x115, ["△"] = 0x116, ["✕"] = 0x117,
    ["No"] = 0x108,
    ["▶"] = 0xEF, -- gText_SelectorArrow2 / CHAR_SELECTOR_ARROW
    ["▲"] = 0x79, -- CHAR_UP_ARROW
    ["▼"] = 0x7A, -- CHAR_DOWN_ARROW
    ["◀"] = 0x7B, -- CHAR_LEFT_ARROW
    ["_"] = 0x109, -- CHAR_EXTRA_SYMBOL + CHAR_UNDERSCORE
    ['"'] = 0xB2,
    ["“"] = 0xB1,
    ["”"] = 0xB2,
    ["‘"] = 0xB3,
    ["’"] = 0xB4,
    ["'"] = 0xB4,
    ["$"] = 0xB7,
    ["¥"] = 0xB7,
    ["\xC2\xA5"] = 0xB7,
  }
  for code, ch in pairs(TextIR.CHARMAP or {}) do
    if type(ch) == "string" and #ch > 0 and not rev[ch] then
      rev[ch] = code
    end
  end
  for code, ch in pairs(FrlgFont.LATIN_GLYPHS) do
    if not rev[ch] then rev[ch] = code end
  end
  for ch, code in pairs(FrlgFont.JAPANESE_GLYPHS) do
    if not rev[ch] then rev[ch] = FrlgFont.JAPANESE_BASE + code end
  end
  -- ASCII digits/letters already via CHARMAP; ensure common punctuation.
  FrlgFont._rev = rev
  return rev
end

--- UTF-8 iterate: yield (char, byteFrom, byteTo)
local function utf8Chars(s)
  local i, n = 1, #s
  return function()
    if i > n then return nil end
    local b = s:byte(i)
    local len = 1
    if b >= 0xF0 then len = 4
    elseif b >= 0xE0 then len = 3
    elseif b >= 0xC0 then len = 2
    end
    if i + len - 1 > n then len = 1 end
    local ch = s:sub(i, i + len - 1)
    local from = i
    i = i + len
    return ch, from, i - 1
  end
end

-- charmap.txt:42-66
FrlgFont.GLYPH_TAGS = {
  PK = { 0x53 },
  MN = { 0x54 },
  PKMN = { 0x53, 0x54 },
  POKEBLOCK = { 0x55, 0x56, 0x57, 0x58, 0x59 },
  LV = { 0x34 },
  SUPER_ER = { 0x2C },
  SUPER_E = { 0x84 },
  SUPER_RE = { 0xA0 },
  UNK_SPACER = { 0x77 },
  UP_ARROW = { 0x79 },
  DOWN_ARROW = { 0x7A },
  LEFT_ARROW = { 0x7B },
  RIGHT_ARROW = { 0x7C },
}
for id, sym in pairs(TextIR.EXTRA_SYMBOL) do
  local name = sym:match("^{(.+)}$")
  if name then FrlgFont.GLYPH_TAGS[name] = { 0x100 + id } end
end

FrlgFont.KEYPAD_TAGS = {}
for id, name in pairs(TextIR.KEYGFX) do FrlgFont.KEYPAD_TAGS[name] = id end

-- src/text.c:81
FrlgFont.KEYPAD_ICONS = {
  [0x00] = { tile = 0x00, w = 8, h = 12 },
  [0x01] = { tile = 0x01, w = 8, h = 12 },
  [0x02] = { tile = 0x02, w = 16, h = 12 },
  [0x03] = { tile = 0x04, w = 16, h = 12 },
  [0x04] = { tile = 0x06, w = 24, h = 12 },
  [0x05] = { tile = 0x09, w = 24, h = 12 },
  [0x06] = { tile = 0x0C, w = 8, h = 12 },
  [0x07] = { tile = 0x0D, w = 8, h = 12 },
  [0x08] = { tile = 0x0E, w = 8, h = 12 },
  [0x09] = { tile = 0x0F, w = 8, h = 12 },
  [0x0A] = { tile = 0x20, w = 8, h = 12 },
  [0x0B] = { tile = 0x21, w = 8, h = 12 },
  [0x0C] = { tile = 0x22, w = 8, h = 12 },
}

local KEYPAD_PATHS = {
  { path = "chrome/fonts/keypad_icons.rgba", w = 128, h = 32 },
  { path = "data/generated/gba/chrome/fonts/keypad_icons.rgba", w = 128, h = 32 },
}

FrlgFont.KEYPAD_WORDS = {
  [0x00] = "A", [0x01] = "B", [0x02] = "L", [0x03] = "R", [0x04] = "START", [0x05] = "SELECT",
  [0x06] = "UP", [0x07] = "DOWN", [0x08] = "LEFT", [0x09] = "RIGHT", [0x0A] = "UP/DN",
  [0x0B] = "L/R", [0x0C] = "DPAD",
}

local keypadQuads = nil

local function keypadWord(iconId)
  return (FrlgFont.KEYPAD_WORDS[iconId] or "?") .. " "
end

local function keypadKnownMissing()
  local spec = FrlgFont.sync and FrlgFont.sync()
  if spec and spec.nativeLayout == "rs" then return true end
  return FrlgFont._keypad == false
end

function FrlgFont.hasKeypadIcons()
  if keypadKnownMissing() then return false end
  if not FrlgFont._keypad then
    FrlgFont._keypad = loadImage(KEYPAD_PATHS) or false
    keypadQuads = nil
  end
  return FrlgFont._keypad ~= false
end

local reportedTags = {}
local function unknownTag(tag)
  if os.getenv("POKEPORT_DEV") == "1" or _G.POKEPORT_DEV_MODE == true then
    error("FrlgFont: no glyph for text tag {" .. tostring(tag) .. "}", 0)
  end
  if not reportedTags[tag] then
    reportedTags[tag] = true
    log("no glyph for text tag {" .. tostring(tag) .. "}")
  end
end

local function resolveColorId(val)
  if not val then return nil end
  if type(val) == "number" then return FrlgFont.STDPAL[val] end
  local upper = tostring(val):upper()
  local id = FrlgFont.COLOR_IDS[upper]
  if id ~= nil then return FrlgFont.STDPAL[id] end
  local num = tonumber(val)
  if num ~= nil and FrlgFont.STDPAL[num] then return FrlgFont.STDPAL[num] end
  return nil
end

local colorScratchPool = {
  { fg = nil, shadow = nil, bg = nil },
  { fg = nil, shadow = nil, bg = nil },
  { fg = nil, shadow = nil, bg = nil },
  { fg = nil, shadow = nil, bg = nil },
}
local colorScratchIdx = 0

local function acquireColorScratch(c)
  colorScratchIdx = (colorScratchIdx % 4) + 1
  local cur = colorScratchPool[colorScratchIdx]
  local normal = FrlgFont.COLOR.NORMAL
  if not c then
    cur.fg = normal.fg
    cur.shadow = normal.shadow
    cur.bg = FrlgFont.STDPAL[0]
  else
    cur.fg = c.fg or normal.fg
    cur.shadow = c.shadow or normal.shadow
    cur.bg = c.bg or FrlgFont.STDPAL[0]
  end
  return cur
end

-- src/text.c:740-787
local PEN_CODES = {
  [0x0D] = "shiftx",
  [0x0E] = "shifty",
  [0x11] = "clear",
  [0x12] = "skip",
  [0x13] = "clearto",
  [0x14] = "minspacing",
}

--- Byte-by-byte token scanner for GBA FRLG text strings.
-- Handles \xFC bytecode sequences, {TAG} macros, and UTF-8 characters without choking on null bytes.
function FrlgFont.scanTokens(text, initialColors)
  local s = tostring(text or "")
  local curColors = acquireColorScratch(initialColors)
  local i, n = 1, #s
  local pending, pendingIdx = nil, 0

  return function()
    if pending then
      pendingIdx = pendingIdx + 1
      local id = pending[pendingIdx]
      if pendingIdx >= #pending then pending = nil end
      return "glyph", id, curColors
    end
    while i <= n do
      local b = s:byte(i)

      -- 1) 0xFC (EXT_CTRL_CODE)
      if b == 0xFC and i + 1 <= n then
        local cmd = s:byte(i + 1)
        if cmd == 0x01 and i + 2 <= n then -- EXT_CTRL_CODE_COLOR (3 bytes)
          local cid = s:byte(i + 2)
          curColors.fg = FrlgFont.STDPAL[cid] or curColors.fg
          i = i + 3
          return "ctrl", "COLOR", curColors
        elseif cmd == 0x02 and i + 2 <= n then -- EXT_CTRL_CODE_HIGHLIGHT (3 bytes)
          local cid = s:byte(i + 2)
          curColors.bg = FrlgFont.STDPAL[cid] or curColors.bg
          i = i + 3
          return "ctrl", "HIGHLIGHT", curColors
        elseif cmd == 0x03 and i + 2 <= n then -- EXT_CTRL_CODE_SHADOW (3 bytes)
          local cid = s:byte(i + 2)
          curColors.shadow = FrlgFont.STDPAL[cid] or curColors.shadow
          i = i + 3
          return "ctrl", "SHADOW", curColors
        elseif cmd == 0x04 and i + 4 <= n then -- EXT_CTRL_CODE_COLOR_HIGHLIGHT_SHADOW (5 bytes)
          local fgId = s:byte(i + 2)
          local bgId = s:byte(i + 3)
          local shId = s:byte(i + 4)
          curColors.fg = FrlgFont.STDPAL[fgId] or curColors.fg
          curColors.bg = FrlgFont.STDPAL[bgId] or curColors.bg
          curColors.shadow = FrlgFont.STDPAL[shId] or curColors.shadow
          i = i + 5
          return "ctrl", "COLOR_HIGHLIGHT_SHADOW", curColors
        elseif cmd == 0x06 and i + 2 <= n then -- EXT_CTRL_CODE_FONT (3 bytes)
          local fontId = s:byte(i + 2)
          if sync() and FrlgFont._spec.nativeLayout == "rs" then
            i = i + 3
            return "font", "native_" .. fontId, curColors
          end
          local fontName = TextIR.dialect().FONT_IDS[fontId]
          if fontName == "FONT_MALE" then
            curColors.fg = FrlgFont.STDPAL[8]
            curColors.shadow = FrlgFont.STDPAL[3]
            curColors.bg = FrlgFont.STDPAL[0]
          elseif fontName == "FONT_FEMALE" then
            curColors.fg = FrlgFont.STDPAL[4]
            curColors.shadow = FrlgFont.STDPAL[3]
            curColors.bg = FrlgFont.STDPAL[0]
          elseif fontName == "FONT_NORMAL" then
            curColors.fg = FrlgFont.STDPAL[2]
            curColors.shadow = FrlgFont.STDPAL[3]
            curColors.bg = FrlgFont.STDPAL[0]
          end
          i = i + 3
          return "ctrl", "FONT", curColors
        elseif cmd == 0x07 and sync() and FrlgFont._spec.nativeLayout == "rs" then
          i = i + 2
          return "font", false, curColors
        elseif PEN_CODES[cmd] and i + 2 <= n then
          local arg = s:byte(i + 2)
          i = i + 3
          return PEN_CODES[cmd], arg, curColors
        elseif cmd == 0x15 or cmd == 0x16 then
          i = i + 2
          return "jpn", cmd == 0x15, curColors
        else
          -- Skip variable length commands according to pret text.c
          local skip = 2
          if cmd == 0x05 or cmd == 0x08 or cmd == 0x0C then
            skip = 3
          elseif cmd == 0x0B or cmd == 0x10 then
            skip = 4
          end
          i = i + skip
          return "ctrl", "EXT", curColors
        end

      -- 2) Braced tag: {TAG}
      elseif b == 0x7B then -- '{'
        local closePos = s:find("}", i + 1, true)
        if closePos then
          local tag = s:sub(i + 1, closePos - 1)
          local upperTag = tag:upper()
          i = closePos + 1
          if upperTag == "FONT_MALE" then
            curColors.fg = FrlgFont.STDPAL[8]
            curColors.shadow = FrlgFont.STDPAL[3]
            curColors.bg = FrlgFont.STDPAL[0]
            return "ctrl", tag, curColors
          elseif upperTag == "FONT_FEMALE" then
            curColors.fg = FrlgFont.STDPAL[4]
            curColors.shadow = FrlgFont.STDPAL[3]
            curColors.bg = FrlgFont.STDPAL[0]
            return "ctrl", tag, curColors
          elseif upperTag == "FONT_NORMAL" then
            curColors.fg = FrlgFont.STDPAL[2]
            curColors.shadow = FrlgFont.STDPAL[3]
            curColors.bg = FrlgFont.STDPAL[0]
            return "ctrl", tag, curColors
          elseif upperTag:sub(1, 6) == "COLOR " then
            local val = tag:sub(7):match("^%s*(.-)%s*$")
            local col = resolveColorId(val)
            if col then curColors.fg = col end
            return "ctrl", tag, curColors
          elseif upperTag:sub(1, 7) == "SHADOW " then
            local val = tag:sub(8):match("^%s*(.-)%s*$")
            local col = resolveColorId(val)
            if col then curColors.shadow = col end
            return "ctrl", tag, curColors
          elseif upperTag:sub(1, 10) == "HIGHLIGHT " or upperTag:sub(1, 3) == "BG " then
            local val = tag:match("^%S+%s+(.-)%s*$")
            local col = resolveColorId(val)
            if col then curColors.bg = col end
            return "ctrl", tag, curColors
          elseif sync() and FrlgFont._spec.nativeLayout == "rs" and (upperTag:match("^FONT_RS_%d$") or upperTag == "FONT_BRAILLE") then
            return "font", "native_" .. (upperTag:match("%d$") or "6"), curColors
          elseif FrlgFont.GLYPH_TAGS[upperTag] then
            local ids = FrlgFont.GLYPH_TAGS[upperTag]
            if #ids > 1 then
              pending, pendingIdx = ids, 1
            end
            return "glyph", ids[1], curColors
          elseif FrlgFont.KEYPAD_TAGS[upperTag] then
            return "icon", FrlgFont.KEYPAD_TAGS[upperTag], curColors
          else
            unknownTag(tag)
            return "ctrl", tag, curColors
          end
        else
          i = i + 1
          return "char", "{", curColors
        end

      -- 3) Newline
      elseif b == 0x0A then -- '\n'
        i = i + 1
        return "nl", "\n", curColors
      elseif b == 0x0C then -- '\f'
        i = i + 1
        return "page", "\f", curColors
      elseif b == 0x0D then -- '\r'
        i = i + 1

      -- 4) Regular UTF-8 char
      else
        local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2
        end
        if i + len - 1 > n then len = 1 end
        local ch = s:sub(i, i + len - 1)
        i = i + len
        return "char", ch, curColors
      end
    end
    return nil
  end
end

function FrlgFont.glyphId(ch)
  if not ch or ch == "" then return 0x00 end
  local rev = buildRev()
  local id = rev[ch]
  if id then return id end
  local b = ch:byte(1)
  if b and b >= 0x20 and b < 0x7F and #ch == 1 then
    return 0x00
  end
  return 0x00
end

function FrlgFont.advance(glyphId, opts)
  opts = opts or {}
  local spec = sync()
  if spec and spec.nativeLayout == "rs" then
    local face = faceFor(opts, glyphId)
    local id = glyphId >= FrlgFont.JAPANESE_BASE and glyphId - FrlgFont.JAPANESE_BASE or glyphId
    return faceAdvance(face, id)
  end
  if glyphId >= FrlgFont.JAPANESE_BASE then
    -- pokefirered/src/text.c:1391 (small: 8px), :1492 (normal: its width table).
    -- The window's letter spacing is added by japanese_step, as the cart does.
    if opts.small then return 8 end
    return japanese_widths()[glyphId - FrlgFont.JAPANESE_BASE] or 10
  end
  local face = faceFor(opts)
  if face then return faceAdvance(face, glyphId) end
  if opts.small then
    ensure_small()
    local sw = FrlgFont._small and FrlgFont._small.widths
    local w = sw and sw[glyphId]
    if not w then
      if glyphId == 0x108 then return 8 end
      if glyphId == 0xB7 then return 6 end
      w = (sw and sw[0]) or 5
    end
    return w
  end
  ensure()
  local w = FrlgFont._widths[glyphId]
  if not w then
    if glyphId == 0x108 then return 9 end
    if glyphId == 0xB7 then return 7 end
    w = FrlgFont._widths[0] or 6
  end
  return w
end

-- src/text.c:841 / :1020 GetStringWidth
local function glyph_step(w, minW, jpn, ls)
  if minW > 0 then return minW > w and minW or w end
  if jpn then return w + ls end
  return w
end

-- A glyph drawn from a Japanese sheet is Japanese whether or not the string
-- carries the {JPN} control code a ROM-extracted one does, so it takes the
-- window's letter spacing either way (src/text.c:853).  Without one, the field
-- message printer's spacing applies: 1 for the normal font
-- (new_menu_helpers.c:413), 0 for the small one (gFontInfos, :65).
local function japanese_step(glyphId, w, minW, jpn, opts, small)
  local ls = opts.letterSpacing
  if FrlgFont._spec and FrlgFont._spec.nativeLayout == "rs" then return glyph_step(w, minW, jpn, ls or 0) end
  if glyphId < FrlgFont.JAPANESE_BASE then return glyph_step(w, minW, jpn, ls or 0) end
  return glyph_step(w, minW, true, ls or (small and 0 or 1))
end

function FrlgFont.measure(text, opts)
  opts = opts or {}
  local activeOpts = opts
  local ls = opts.letterSpacing or 0
  local minW, jpn = 0, false
  local line, maxLine = 0, 0
  for ttype, val in FrlgFont.scanTokens(text) do
    if ttype == "nl" or ttype == "page" then
      if line > maxLine then maxLine = line end
      line = 0
    elseif ttype == "char" then
      local id = FrlgFont.glyphId(val)
      line = line + japanese_step(id, FrlgFont.advance(id, activeOpts), minW, jpn, activeOpts, activeOpts.small)
    elseif ttype == "glyph" then
      line = line + japanese_step(val, FrlgFont.advance(val, activeOpts), minW, jpn, activeOpts, activeOpts.small)
    elseif ttype == "font" then
      activeOpts = { font = val or opts.font, small = opts.small, letterSpacing = opts.letterSpacing, japanese = opts.japanese, textMode = opts.textMode }
    elseif ttype == "icon" then
      line = line + FrlgFont.keypadIconWidth(val, activeOpts) + ls
    elseif ttype == "clear" then
      line = line + val
    elseif ttype == "skip" then
      line = val
    elseif ttype == "clearto" then
      if val > line then line = val end
    elseif ttype == "minspacing" then
      minW = val
    elseif ttype == "jpn" then
      jpn = val
    end
  end
  if line > maxLine then maxLine = line end
  return maxLine
end

function FrlgFont.keypadIconWidth(iconId, opts)
  if not FrlgFont.hasKeypadIcons() then return FrlgFont.measure(keypadWord(iconId), opts) end
  return FrlgFont.KEYPAD_ICONS[iconId].w
end

local WORD_OPTS = { colors = nil, font = nil, small = nil }

-- src/text.c:1335
function FrlgFont.drawKeypadIcon(iconId, x, y, opts)
  local icon = FrlgFont.KEYPAD_ICONS[iconId]
  if not FrlgFont.hasKeypadIcons() then
    local word = keypadWord(iconId)
    if opts then
      WORD_OPTS.colors, WORD_OPTS.font, WORD_OPTS.small = opts.colors, opts.font, opts.small
    else
      WORD_OPTS.colors, WORD_OPTS.font, WORD_OPTS.small = nil, nil, nil
    end
    FrlgFont.draw(word, x, y, WORD_OPTS)
    return FrlgFont.measure(word, WORD_OPTS)
  end
  if not keypadQuads then
    local iw, ih = FrlgFont._keypad:getDimensions()
    keypadQuads = {}
    for id, k in pairs(FrlgFont.KEYPAD_ICONS) do
      keypadQuads[id] = love.graphics.newQuad((k.tile % 16) * 8, math.floor(k.tile / 16) * 8, k.w, k.h, iw, ih)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(FrlgFont._keypad, keypadQuads[iconId], x, y)
  return icon.w
end

local restore_ext = TextIR.restoreExt

--- Word-wrap text to fit within maxWidth pixels.
function FrlgFont.wrap(text, maxWidth, opts)
  opts = opts or {}
  maxWidth = maxWidth or 200
  local spaceW = FrlgFont.measure(" ", opts)
  local outLines = {}
  local rawLines = {}
  local clean = TextIR.protectExt(text):gsub("\\n", "\n"):gsub("\\p", "\n"):gsub("\\l", "\n")
  for line in (clean .. "\n"):gmatch("(.-)\r?\n") do
    rawLines[#rawLines + 1] = line
  end
  for _, rawLine in ipairs(rawLines) do
    local words = {}
    for word in rawLine:gmatch("%S+") do
      words[#words + 1] = word
    end
    if #words == 0 then
      outLines[#outLines + 1] = ""
    else
      local curLine = words[1]
      local curW = FrlgFont.measure(restore_ext(curLine), opts)
      for i = 2, #words do
        local w = words[i]
        local wW = FrlgFont.measure(restore_ext(w), opts)
        if curW + spaceW + wW <= maxWidth then
          curLine = curLine .. " " .. w
          curW = curW + spaceW + wW
        else
          outLines[#outLines + 1] = curLine
          curLine = w
          curW = wW
        end
      end
      outLines[#outLines + 1] = curLine
    end
  end
  return restore_ext(table.concat(outLines, "\n"))
end

local ADVANCE_SMALL = { small = true }
local ADVANCE_NORMAL = {}
local ICON_COLORS = { fg = nil, shadow = nil, bg = nil }
local ICON_OPTS = { colors = ICON_COLORS, font = nil, small = nil }

local function set_col(c)
  if type(c) == "table" then
    love.graphics.setColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
end

--- Draw full string at pixel (x,y).
-- opts.maxWidth clips (CopyGlyphToWindow). opts.colors = COLOR.NORMAL etc.
-- opts.limitChars: only draw first N printable characters (typewriter).
-- opts.small: use FONT_SMALL (party menu).
function FrlgFont.draw(text, x, y, opts)
  opts = opts or {}
  local activeOpts = opts
  local face = faceFor(opts)
  local useSmall = false
  if face then
    useSmall = face.name == "small"
  else
    if opts.small then
      useSmall = ensure_small() and FrlgFont._small and FrlgFont._small._romBaked
    end
    if not useSmall and not ensure() then return 0 end
  end

  local baseColors = opts.colors
  if not baseColors then
    if opts.color then
      baseColors = {
        fg = opts.color,
        shadow = opts.shadow or (opts.color == FrlgFont.COLOR.WHITE.fg and FrlgFont.COLOR.WHITE.shadow or FrlgFont.COLOR.NORMAL.shadow),
        bg = opts.bg or FrlgFont.STDPAL[0],
      }
    elseif opts.gfxId then
      baseColors = FrlgFont.colorForNpc(opts.gfxId)
    elseif opts.npcColor then
      if opts.npcColor == FrlgFont.NPC_TEXT_COLOR.MALE then
        baseColors = FrlgFont.COLOR.MALE
      elseif opts.npcColor == FrlgFont.NPC_TEXT_COLOR.FEMALE then
        baseColors = FrlgFont.COLOR.FEMALE
      else
        baseColors = FrlgFont.COLOR.NORMAL
      end
    else
      baseColors = (useSmall and FrlgFont.COLOR.PARTY) or FrlgFont.COLOR.NORMAL
    end
  end

  local maxW = opts.maxWidth or 240
  local limit = opts.limitChars
  local ls = opts.letterSpacing or 0
  local minW, jpn = 0, false
  local penX, penY = 0, 0
  local drawn = 0
  local pitch = opts.linePitch or (face and face.pitch)
    or (useSmall and FrlgFont.SMALL_LINE_PITCH or FrlgFont.LINE_PITCH)
  local fg, sh, quads, atlas
  if face then
    fg, sh, quads, atlas = face.fg, face.sh, face.quads, face.atlas
  elseif useSmall then
    fg, sh, quads, atlas = FrlgFont._small.fg, FrlgFont._small.sh, FrlgFont._small.quads, FrlgFont._small.atlas
  else
    fg, sh, quads, atlas = FrlgFont._fg, FrlgFont._sh, FrlgFont._quads, FrlgFont._atlas
  end
  if atlas and (atlas.src ~= quads or not sh) then atlas = nil end

  for ttype, val, curCol in FrlgFont.scanTokens(text, baseColors) do
    if limit and drawn >= limit then break end
    if ttype == "nl" then
      penX = 0
      penY = penY + pitch
      drawn = drawn + 1
    elseif ttype == "icon" then
      local cfg, csh, cbg = curCol.fg, curCol.shadow, curCol.bg
      local w = FrlgFont.keypadIconWidth(val, activeOpts)
      if penX + w <= maxW or penX == 0 then
        ICON_COLORS.fg, ICON_COLORS.shadow, ICON_COLORS.bg = cfg, csh, cbg
        ICON_OPTS.font, ICON_OPTS.small = activeOpts.font, activeOpts.small
        FrlgFont.drawKeypadIcon(val, x + penX, y + penY, ICON_OPTS)
        penX = penX + w + ls
      end
      curCol.fg, curCol.shadow, curCol.bg = cfg, csh, cbg
      drawn = drawn + 1
    elseif ttype == "shiftx" or ttype == "skip" then
      penX = val
    elseif ttype == "shifty" then
      penY = val
    elseif ttype == "clear" then
      penX = penX + val
    elseif ttype == "clearto" then
      if val > penX then penX = val end
    elseif ttype == "minspacing" then
      minW = val
    elseif ttype == "jpn" then
      jpn = val
    elseif ttype == "font" then
      activeOpts = { font = val or opts.font, small = opts.small, letterSpacing = opts.letterSpacing, japanese = opts.japanese, textMode = opts.textMode }
      face = faceFor(activeOpts)
      fg, sh, quads, atlas = face.fg, face.sh, face.quads, face.atlas
    elseif ttype == "char" or ttype == "glyph" then
      local id = ttype == "glyph" and val or FrlgFont.glyphId(val)
      local nativeFace = face and face.nativeIndexed and faceFor(activeOpts, id)
      local nativeId = id >= FrlgFont.JAPANESE_BASE and id - FrlgFont.JAPANESE_BASE or id
      local adv
      if nativeFace then
        adv = faceAdvance(nativeFace, nativeId)
      elseif face and id < FrlgFont.JAPANESE_BASE then
        adv = faceAdvance(face, id)
      else
        adv = FrlgFont.advance(id, useSmall and ADVANCE_SMALL or ADVANCE_NORMAL)
      end
      if penX + adv <= maxW or penX == 0 then
        local dx, dy = x + penX, y + penY
        local gfg, gsh, q, gat = fg, sh, quads[id], atlas
        local aid = id
        if nativeFace then
          gfg, gsh, q, gat = nativeFace.fg, nativeFace.sh, nativeQuad(nativeFace, nativeId, dx), nil
        elseif id >= FrlgFont.JAPANESE_BASE then
          gfg, gsh, q, gat = japanese_quad(id, useSmall)
          aid = id - FrlgFont.JAPANESE_BASE
          if not gsh then gat = nil end
        end
        if q then
          -- Draw background / highlight fill if bg is not transparent
          if curCol.bg and curCol.bg[4] and curCol.bg[4] > 0 then
            set_col(curCol.bg)
            love.graphics.rectangle("fill", dx, dy, adv, pitch)
          end
          local aq = gat and gat.fg[aid]
          -- Draw shadow
          if gsh and curCol.shadow and (not curCol.shadow[4] or curCol.shadow[4] > 0) then
            set_col(curCol.shadow)
            if aq then
              love.graphics.draw(gat.image, gat.sh[aid], dx, dy)
            else
              love.graphics.draw(gsh, q, dx, dy)
            end
          end
          -- Draw foreground
          if curCol.fg and (not curCol.fg[4] or curCol.fg[4] > 0) then
            set_col(curCol.fg)
            if aq then
              love.graphics.draw(gat.image, aq, dx, dy)
            else
              love.graphics.draw(gfg, q, dx, dy)
            end
          end
          if nativeFace and nativeFace.fixed then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(nativeFace.fixed, q, dx, dy)
          end
        end
        penX = penX + japanese_step(id, adv, minW, jpn, activeOpts, useSmall)
      end
      drawn = drawn + 1
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  return drawn, x + penX, y + penY
end

--- Draw a single glyph by FRLG charset id (e.g. 0x7C = CHAR_RIGHT_ARROW).
-- opts.small: FONT_SMALL sheet (supports EXTRA ids like CHAR_LV_2 = 0x105).
function FrlgFont.drawGlyph(glyphId, x, y, opts)
  opts = opts or {}
  glyphId = tonumber(glyphId) or 0
  local face = faceFor(opts, glyphId)
  if face and face.nativeIndexed and glyphId >= FrlgFont.JAPANESE_BASE then glyphId = glyphId - FrlgFont.JAPANESE_BASE end
  local useSmall
  if face then
    useSmall = face.name == "small"
  else
    useSmall = opts.small and ensure_small() and FrlgFont._small and FrlgFont._small._romBaked
    if not useSmall and not ensure() then
      return 0
    end
  end
  local colors = opts.colors or (useSmall and FrlgFont.COLOR.PARTY) or FrlgFont.COLOR.NORMAL
  local fg, sh, quads
  if face then
    fg, sh, quads = face.fg, face.sh, face.quads
  elseif useSmall then
    fg, sh, quads = FrlgFont._small.fg, FrlgFont._small.sh, FrlgFont._small.quads
  else
    fg, sh, quads = FrlgFont._fg, FrlgFont._sh, FrlgFont._quads
  end
  local q = face and face.nativeIndexed and nativeQuad(face, glyphId, x) or quads[glyphId]
  if not q then return 0 end
  if colors.bg and colors.bg[4] and colors.bg[4] > 0 then
    love.graphics.setColor(colors.bg)
    love.graphics.rectangle("fill", x, y, face and faceAdvance(face, glyphId) or FrlgFont.advance(glyphId, useSmall and ADVANCE_SMALL or ADVANCE_NORMAL), face and face.pitch or (useSmall and FrlgFont.SMALL_LINE_PITCH or FrlgFont.LINE_PITCH))
  end
  if sh and colors.shadow and (not colors.shadow[4] or colors.shadow[4] > 0) then
    love.graphics.setColor(colors.shadow)
    love.graphics.draw(sh, q, x, y)
  end
  if colors.fg and (not colors.fg[4] or colors.fg[4] > 0) then
    love.graphics.setColor(colors.fg)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
  love.graphics.draw(fg, q, x, y)
  if face and face.fixed then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(face.fixed, q, x, y)
  end
  love.graphics.setColor(1, 1, 1, 1)
  if face then return faceAdvance(face, glyphId) end
  return FrlgFont.advance(glyphId, useSmall and ADVANCE_SMALL or ADVANCE_NORMAL)
end

-- pret CHAR_RIGHT_ARROW = 0x7C, but gText_SelectorArrow2 ("▶") is charmap 0xEF.
-- Menu_InitCursor / RedrawMenuCursor print SelectorArrow2 — use 0xEF for the pip.
FrlgFont.CHAR_RIGHT_ARROW = 0x7C
FrlgFont.CHAR_SELECTOR_ARROW = 0xEF -- gText_SelectorArrow2
FrlgFont.CHAR_LEFT_ARROW = 0x7B
FrlgFont.CHAR_UP_ARROW = 0x79
FrlgFont.CHAR_DOWN_ARROW = 0x7A
-- CHAR_EXTRA_SYMBOL|CHAR_LV_2 → glyph 0x105 in latin_small (UpdateLvlInHealthbox).
FrlgFont.CHAR_LV_2 = 0x105
FrlgFont.CHAR_MALE = 0xB5
FrlgFont.CHAR_FEMALE = 0xB6
FrlgFont.CHAR_SLASH = 0xBA

--- Count printable UTF-8 characters in text (including newlines, skipping control codes).
--- The first n characters of text (UTF-8 aware): a name limit counts
-- characters (pokefirered POKEMON_NAME_LENGTH, PLAYER_NAME_LENGTH), and a kana
-- is three bytes, so a byte cut would split it.
function FrlgFont.truncate(text, n)
  text = tostring(text or "")
  local out, count = {}, 0
  for ch in utf8Chars(text) do
    if count >= n then break end
    count = count + 1
    out[count] = ch
  end
  return table.concat(out)
end

function FrlgFont.countChars(text)
  local n = 0
  for ttype in FrlgFont.scanTokens(text) do
    if ttype == "char" or ttype == "nl" or ttype == "glyph" or ttype == "icon" then
      n = n + 1
    end
  end
  return n
end

function FrlgFont.invalidate()
  FrlgFont._faces = {}
  FrlgFont._metrics = nil
  FrlgFont._fg = nil
  FrlgFont._sh = nil
  FrlgFont._quads = nil
  FrlgFont._atlas = nil
  FrlgFont._small = nil
  FrlgFont._keypad = nil
  FrlgFont._jpNormal = nil
  FrlgFont._jpSmall = nil
  FrlgFont._jpWidths = nil
  FrlgFont._logged = false
end

FrlgFont.utf8Chars = utf8Chars

return FrlgFont
