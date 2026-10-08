-- GBA text → IR segments (glyphs + control codes FA/FB/FC/FD/FE/FF).

local TextIR = {}

-- FRLG English charmap (pret pokefirered/charmap.txt).
-- CRITICAL: Gen2 uses $F0 for ¥; FRLG uses $F0 for ':' and $B7 for ¥.
-- Mapping FRLG $F0 → "¥" produces BILL¥ / CELIO¥ in extracted text.
local CHARMAP = {
  [0x00] = " ",
  [0x1B] = "é", [0x06] = "É",
  [0x2D] = "&", [0x2E] = "+", [0x35] = "=", [0x36] = ";",
  [0x5B] = "%", [0x5C] = "(", [0x5D] = ")",
  [0x85] = "<", [0x86] = ">",
  [0xA1] = "0", [0xA2] = "1", [0xA3] = "2", [0xA4] = "3", [0xA5] = "4",
  [0xA6] = "5", [0xA7] = "6", [0xA8] = "7", [0xA9] = "8", [0xAA] = "9",
  [0xAB] = "!", [0xAC] = "?", [0xAD] = ".", [0xAE] = "-", [0xAF] = "·",
  [0xB0] = "…", [0xB1] = "“", [0xB2] = "”", [0xB3] = "‘", [0xB4] = "'",
  [0xB5] = "♂", [0xB6] = "♀", [0xB7] = "¥", [0xB8] = ",", [0xB9] = "×",
  [0xBA] = "/",
  [0xBB] = "A", [0xBC] = "B", [0xBD] = "C", [0xBE] = "D", [0xBF] = "E",
  [0xC0] = "F", [0xC1] = "G", [0xC2] = "H", [0xC3] = "I", [0xC4] = "J",
  [0xC5] = "K", [0xC6] = "L", [0xC7] = "M", [0xC8] = "N", [0xC9] = "O",
  [0xCA] = "P", [0xCB] = "Q", [0xCC] = "R", [0xCD] = "S", [0xCE] = "T",
  [0xCF] = "U", [0xD0] = "V", [0xD1] = "W", [0xD2] = "X", [0xD3] = "Y",
  [0xD4] = "Z",
  [0xD5] = "a", [0xD6] = "b", [0xD7] = "c", [0xD8] = "d", [0xD9] = "e",
  [0xDA] = "f", [0xDB] = "g", [0xDC] = "h", [0xDD] = "i", [0xDE] = "j",
  [0xDF] = "k", [0xE0] = "l", [0xE1] = "m", [0xE2] = "n", [0xE3] = "o",
  [0xE4] = "p", [0xE5] = "q", [0xE6] = "r", [0xE7] = "s", [0xE8] = "t",
  [0xE9] = "u", [0xEA] = "v", [0xEB] = "w", [0xEC] = "x", [0xED] = "y",
  [0xEE] = "z",
  [0xEF] = "▶",
  [0xF0] = ":", -- FRLG colon (NOT Gen2 yen)
}

TextIR.CHARMAP = CHARMAP
TextIR.CTRL = {
  SCROLL = 0xFA, -- \l
  PARA = 0xFB,   -- \p
  NL = 0xFE,     -- \n
  EOS = 0xFF,
  PLACEHOLDER = 0xFD,
  EXT = 0xFC,
}

-- FD nn placeholders (pret characters.h PLACEHOLDER_ID_*)
TextIR.PH = {
  [0x01] = "player",
  [0x02] = "strvar1",
  [0x03] = "strvar2",
  [0x04] = "strvar3",
  [0x06] = "rival",
}

-- charmap.txt:837-908
TextIR.EXTRA_SYMBOL = {
  [0x00] = "↑", [0x01] = "↓", [0x02] = "←", [0x03] = "→", [0x04] = "{PLUS}",
  [0x05] = "{LV_2}", [0x06] = "{PP}", [0x07] = "{ID}", [0x08] = "№", [0x09] = "_",
  [0x0A] = "①", [0x0B] = "②", [0x0C] = "③", [0x0D] = "④", [0x0E] = "⑤", [0x0F] = "⑥",
  [0x10] = "⑦", [0x11] = "⑧", [0x12] = "⑨", [0x13] = "{LEFT_PAREN}", [0x14] = "{RIGHT_PAREN}",
  [0x15] = "◎", [0x16] = "△", [0x17] = "✕",
  [0xD0] = "{EMOJI_UNDERSCORE}", [0xD1] = "{EMOJI_PIPE}", [0xD2] = "{EMOJI_HIGHBAR}",
  [0xD3] = "{EMOJI_TILDE}", [0xD4] = "{EMOJI_LEFT_PAREN}", [0xD5] = "{EMOJI_RIGHT_PAREN}",
  [0xD6] = "{EMOJI_UNION}", [0xD7] = "{EMOJI_GREATER_THAN}", [0xD8] = "{EMOJI_LEFT_EYE}",
  [0xD9] = "{EMOJI_RIGHT_EYE}", [0xDA] = "{EMOJI_AT}", [0xDB] = "{EMOJI_SEMICOLON}",
  [0xDC] = "{EMOJI_PLUS}", [0xDD] = "{EMOJI_MINUS}", [0xDE] = "{EMOJI_EQUALS}",
  [0xDF] = "{EMOJI_SPIRAL}", [0xE0] = "{EMOJI_TONGUE}", [0xE1] = "{EMOJI_TRIANGLE_OUTLINE}",
  [0xE2] = "{EMOJI_ACUTE}", [0xE3] = "{EMOJI_GRAVE}", [0xE4] = "{EMOJI_CIRCLE}",
  [0xE5] = "{EMOJI_TRIANGLE}", [0xE6] = "{EMOJI_SQUARE}", [0xE7] = "{EMOJI_HEART}",
  [0xE8] = "{EMOJI_MOON}", [0xE9] = "{EMOJI_NOTE}", [0xEA] = "{EMOJI_BALL}",
  [0xEB] = "{EMOJI_BOLT}", [0xEC] = "{EMOJI_LEAF}", [0xED] = "{EMOJI_FIRE}",
  [0xEE] = "{EMOJI_WATER}", [0xEF] = "{EMOJI_LEFT_FIST}", [0xF0] = "{EMOJI_RIGHT_FIST}",
  [0xF1] = "{EMOJI_BIGWHEEL}", [0xF2] = "{EMOJI_SMALLWHEEL}", [0xF3] = "{EMOJI_SPHERE}",
  [0xF4] = "{EMOJI_IRRITATED}", [0xF5] = "{EMOJI_MISCHIEVOUS}", [0xF6] = "{EMOJI_HAPPY}",
  [0xF7] = "{EMOJI_ANGRY}", [0xF8] = "{EMOJI_SURPRISED}", [0xF9] = "{EMOJI_BIGSMILE}",
  [0xFA] = "{EMOJI_EVIL}", [0xFB] = "{EMOJI_TIRED}", [0xFC] = "{EMOJI_NEUTRAL}",
  [0xFD] = "{EMOJI_SHOCKED}", [0xFE] = "{EMOJI_BIGANGER}",
}

-- include/battle_message.h:9
TextIR.B_TXT = {
  [0x00] = "B_BUFF1", [0x01] = "B_BUFF2", [0x02] = "B_COPY_VAR_1", [0x03] = "B_COPY_VAR_2",
  [0x04] = "B_COPY_VAR_3", [0x05] = "B_PLAYER_MON1_NAME", [0x06] = "B_OPPONENT_MON1_NAME",
  [0x07] = "B_PLAYER_MON2_NAME", [0x08] = "B_OPPONENT_MON2_NAME",
  [0x09] = "B_LINK_PLAYER_MON1_NAME", [0x0A] = "B_LINK_OPPONENT_MON1_NAME",
  [0x0B] = "B_LINK_PLAYER_MON2_NAME", [0x0C] = "B_LINK_OPPONENT_MON2_NAME",
  [0x0D] = "B_ATK_NAME_WITH_PREFIX_MON1", [0x0E] = "B_ATK_PARTNER_NAME",
  [0x0F] = "B_ATK_NAME_WITH_PREFIX", [0x10] = "B_DEF_NAME_WITH_PREFIX",
  [0x11] = "B_EFF_NAME_WITH_PREFIX", [0x12] = "B_ACTIVE_NAME_WITH_PREFIX",
  [0x13] = "B_SCR_ACTIVE_NAME_WITH_PREFIX", [0x14] = "B_CURRENT_MOVE", [0x15] = "B_LAST_MOVE",
  [0x16] = "B_LAST_ITEM", [0x17] = "B_LAST_ABILITY", [0x18] = "B_ATK_ABILITY",
  [0x19] = "B_DEF_ABILITY", [0x1A] = "B_SCR_ACTIVE_ABILITY", [0x1B] = "B_EFF_ABILITY",
  [0x1C] = "B_TRAINER1_CLASS", [0x1D] = "B_TRAINER1_NAME", [0x1E] = "B_LINK_PLAYER_NAME",
  [0x1F] = "B_LINK_PARTNER_NAME", [0x20] = "B_LINK_OPPONENT1_NAME",
  [0x21] = "B_LINK_OPPONENT2_NAME", [0x22] = "B_LINK_SCR_TRAINER_NAME",
  [0x23] = "B_PLAYER_NAME", [0x24] = "B_TRAINER1_LOSE_TEXT", [0x25] = "B_TRAINER1_WIN_TEXT",
  [0x26] = "B_26", [0x27] = "B_PC_CREATOR_NAME", [0x28] = "B_ATK_PREFIX1",
  [0x29] = "B_DEF_PREFIX1", [0x2A] = "B_ATK_PREFIX2", [0x2B] = "B_DEF_PREFIX2",
  [0x2C] = "B_ATK_PREFIX3", [0x2D] = "B_DEF_PREFIX3", [0x2E] = "B_TRAINER2_LOSE_TEXT",
  [0x2F] = "B_TRAINER2_WIN_TEXT", [0x30] = "B_BUFF3",
}
TextIR.B_TXT_CODE = {}
for code, name in pairs(TextIR.B_TXT) do TextIR.B_TXT_CODE[name] = code end

local function invert(t)
  local out = {}
  for k, v in pairs(t) do out[v] = k end
  return out
end

-- pokeemerald/include/battle_message.h:57
local B_TXT_RSE = {}
for code, name in pairs(TextIR.B_TXT) do
  if code < 0x2E then B_TXT_RSE[code] = name end
end
B_TXT_RSE[0x2E] = "B_TRAINER2_CLASS"
B_TXT_RSE[0x2F] = "B_TRAINER2_NAME"
B_TXT_RSE[0x30] = "B_TRAINER2_LOSE_TEXT"
B_TXT_RSE[0x31] = "B_TRAINER2_WIN_TEXT"
B_TXT_RSE[0x32] = "B_PARTNER_CLASS"
B_TXT_RSE[0x33] = "B_PARTNER_NAME"
B_TXT_RSE[0x34] = "B_BUFF3"

-- pokeruby/include/battle_message.h:21
local B_TXT_RS = { [0] = "B_BUFF1", [1] = "B_BUFF2" }
for code = 0x02, 0x21 do B_TXT_RS[code] = TextIR.B_TXT[code + 3] end
B_TXT_RS[0x22] = "B_26"
for code = 0x23, 0x29 do B_TXT_RS[code] = TextIR.B_TXT[code + 4] end
B_TXT_RS[0x2A] = "B_BUFF3"

TextIR.DIALECTS = {
  frlg = {
    name = "frlg",
    -- pokefirered/include/characters.h:267
    PH_NAMES = {
      [0x00] = "UNKNOWN", [0x01] = "PLAYER", [0x02] = "STR_VAR_1", [0x03] = "STR_VAR_2",
      [0x04] = "STR_VAR_3", [0x05] = "KUN", [0x06] = "RIVAL", [0x07] = "VERSION",
      [0x08] = "MAGMA", [0x09] = "AQUA", [0x0A] = "MAXIE", [0x0B] = "ARCHIE",
      [0x0C] = "GROUDON", [0x0D] = "KYOGRE",
    },
    B_TXT = TextIR.B_TXT,
    B_TXT_CODE = TextIR.B_TXT_CODE,
    -- pokefirered/include/text.h:16
    FONT_IDS = {
      [0] = "FONT_SMALL", [1] = "FONT_NORMAL_COPY_1", [2] = "FONT_NORMAL",
      [3] = "FONT_NORMAL_COPY_2", [4] = "FONT_MALE", [5] = "FONT_FEMALE",
      [6] = "FONT_BRAILLE", [7] = "FONT_BOLD",
    },
    -- pokefirered/src/string_util.c:386: the honorific after the player's
    -- name is the cart's gExpandedPlaceholder_Kun or _Chan string, by the
    -- player's gender (empty on the US cart).
    GENDERED_LABELS = { KUN = { male = "gExpandedPlaceholder_Kun", female = "gExpandedPlaceholder_Chan" } },
  },
  rse = {
    name = "rse",
    -- pokeemerald/include/constants/characters.h:251
    PH_NAMES = {
      [0x00] = "UNKNOWN", [0x01] = "PLAYER", [0x02] = "STR_VAR_1", [0x03] = "STR_VAR_2",
      [0x04] = "STR_VAR_3", [0x05] = "KUN", [0x06] = "RIVAL", [0x07] = "VERSION",
      [0x08] = "AQUA", [0x09] = "MAGMA", [0x0A] = "ARCHIE", [0x0B] = "MAXIE",
      [0x0C] = "KYOGRE", [0x0D] = "GROUDON",
    },
    B_TXT = B_TXT_RSE,
    B_TXT_CODE = invert(B_TXT_RSE),
    -- pokeemerald/include/text.h:12
    FONT_IDS = {
      [0] = "FONT_SMALL", [1] = "FONT_NORMAL", [2] = "FONT_SHORT", [3] = "FONT_SHORT_COPY_1",
      [4] = "FONT_SHORT_COPY_2", [5] = "FONT_SHORT_COPY_3", [6] = "FONT_BRAILLE",
      [7] = "FONT_NARROW", [8] = "FONT_SMALL_NARROW", [9] = "FONT_BOLD",
    },
    -- pokeemerald/charmap.txt:45
    CHARMAP_EXTRA = {
      [0x34] = "{LV}",
      [0x55] = "{POKEBLOCK}", [0x56] = "", [0x57] = "", [0x58] = "", [0x59] = "",
      [0x77] = "{UNK_SPACER}",
      [0x79] = "{UP_ARROW}", [0x7A] = "{DOWN_ARROW}", [0x7B] = "{LEFT_ARROW}", [0x7C] = "{RIGHT_ARROW}",
    },
    -- pokeemerald/charmap.txt:52
    CHARMAP_RUNS = {
      [0x55] = { bytes = { 0x55, 0x56, 0x57, 0x58, 0x59 }, tag = "{POKEBLOCK}" },
    },
    -- pokeemerald/src/string_util.c:456
    GENDERED_PH = { KUN = true, RIVAL = true },
    placeholders = "data/generated/gba/text/placeholders.lua",
  },
}
-- pokeruby/src/string_util.c:476
TextIR.DIALECTS.rs = {
  name = "rs",
  PH_NAMES = {
    [0] = "UNKNOWN", [1] = "PLAYER", [2] = "STR_VAR_1", [3] = "STR_VAR_2",
    [4] = "STR_VAR_3", [5] = "KUN", [6] = "RIVAL", [7] = "VERSION",
    [8] = "EVIL_TEAM", [9] = "GOOD_TEAM", [10] = "EVIL_LEADER", [11] = "GOOD_LEADER",
    [12] = "EVIL_LEGENDARY", [13] = "GOOD_LEGENDARY",
  },
  B_TXT = B_TXT_RS, B_TXT_CODE = invert(B_TXT_RS),
  -- pokeruby/src/text.c:419
  FONT_IDS = {
    [0] = "FONT_RS_0", [1] = "FONT_RS_1", [2] = "FONT_RS_2", [3] = "FONT_RS_3",
    [4] = "FONT_RS_4", [5] = "FONT_RS_5", [6] = "FONT_BRAILLE",
  },
  CHARMAP_EXTRA = TextIR.DIALECTS.rse.CHARMAP_EXTRA,
  CHARMAP_RUNS = TextIR.DIALECTS.rse.CHARMAP_RUNS,
  GENDERED_PH = TextIR.DIALECTS.rse.GENDERED_PH,
  placeholders = "data/generated/gba/text/placeholders.lua",
}
for _, d in pairs(TextIR.DIALECTS) do
  d.PH_CODE = invert(d.PH_NAMES)
  d.FONT_CODE = invert(d.FONT_IDS)
end

TextIR.DEFAULT_DIALECT = "frlg"

function TextIR.dialectOf(version)
  local GameVersion = require("src.core.GameVersion")
  local id = version or GameVersion.get()
  if id == "ruby" or id == "sapphire" then return "rs" end
  local family = GameVersion.layout and GameVersion.layout(id) or nil
  if not family then
    local Profile = package.loaded["src.core.game3.profile"]
    local ok, row = false, nil
    if Profile and Profile.isGame3Version and Profile.isGame3Version(id) then
      ok, row = pcall(Profile.of, id)
    end
    family = ok and type(row) == "table" and row.family or nil
  end
  return TextIR.DIALECTS[family] and family or TextIR.DEFAULT_DIALECT
end

function TextIR.dialect(which)
  if type(which) == "table" then return which end
  return TextIR.DIALECTS[which or TextIR.dialectOf()] or TextIR.DIALECTS[TextIR.DEFAULT_DIALECT]
end

TextIR.KEYGFX = {
  [0x00] = "A_BUTTON", [0x01] = "B_BUTTON", [0x02] = "L_BUTTON", [0x03] = "R_BUTTON",
  [0x04] = "START_BUTTON", [0x05] = "SELECT_BUTTON", [0x06] = "DPAD_UP", [0x07] = "DPAD_DOWN",
  [0x08] = "DPAD_LEFT", [0x09] = "DPAD_RIGHT", [0x0A] = "DPAD_UPDOWN", [0x0B] = "DPAD_LEFTRIGHT",
  [0x0C] = "DPAD_ANY",
}

-- charmap.txt:50
TextIR.LIGATURE = { [0x53] = "{PK}", [0x54] = "{MN}" }

-- src/text.c:948
TextIR.EXT_ARGS = {
  [0x01] = 1, [0x02] = 1, [0x03] = 1, [0x04] = 3, [0x05] = 1, [0x06] = 1, [0x08] = 1,
  [0x0B] = 2, [0x0C] = 1, [0x0D] = 1, [0x0E] = 1, [0x10] = 2, [0x11] = 1, [0x12] = 1,
  [0x13] = 1, [0x14] = 1,
}

local function ext_len(s, i)
  return 2 + (TextIR.EXT_ARGS[s:byte(i + 1)] or 0)
end

-- src/text.c:670
function TextIR.protectExt(s)
  s = tostring(s or "")
  if not s:find("\252", 1, true) then return s end
  local out, i, n = {}, 1, #s
  while i <= n do
    local b = s:byte(i)
    if b == 0xFC and i < n then
      local last = math.min(n, i + ext_len(s, i) - 1)
      local hex = {}
      for k = i + 1, last do hex[#hex + 1] = string.format("%02X", s:byte(k)) end
      out[#out + 1] = "\255" .. table.concat(hex) .. "\254"
      i = last + 1
    else
      out[#out + 1] = string.char(b)
      i = i + 1
    end
  end
  return table.concat(out)
end

function TextIR.restoreExt(s)
  return (tostring(s or ""):gsub("\255(%x+)\254", function(h)
    return "\252" .. h:gsub("%x%x", function(x) return string.char(tonumber(x, 16)) end)
  end))
end

-- src/text.c:670
function TextIR.splitPages(box, keepEmpty)
  local s = tostring(box or "")
  local pages, start, i, n = {}, 1, 1, #s
  while i <= n do
    local b = s:byte(i)
    if b == 0xFC and i < n then
      i = i + ext_len(s, i)
    elseif b == 0x0C then
      local page = s:sub(start, i - 1)
      if keepEmpty or page ~= "" then pages[#pages + 1] = page end
      i = i + 1
      start = i
    else
      i = i + 1
    end
  end
  local page = s:sub(start)
  if keepEmpty or page ~= "" then pages[#pages + 1] = page end
  return pages
end

TextIR.TAG_NAMES = { PK = true, MN = true, PKMN = true }
for _, name in pairs(TextIR.KEYGFX) do TextIR.TAG_NAMES[name] = true end
for _, sym in pairs(TextIR.EXTRA_SYMBOL) do
  local name = sym:match("^{(.+)}$")
  if name then TextIR.TAG_NAMES[name] = true end
end
for _, d in pairs(TextIR.DIALECTS) do
  for _, sym in pairs(d.CHARMAP_EXTRA or {}) do
    local name = sym:match("^{(.+)}$")
    if name then TextIR.TAG_NAMES[name] = true end
  end
end

TextIR._provider = nil

function TextIR.setContextProvider(fn)
  TextIR._provider = type(fn) == "function" and fn or nil
end

function TextIR.placeholdersFor(ctx)
  if ctx and ctx.placeholders then return ctx.placeholders end
  local provider = TextIR._provider
  if not provider then return nil end
  local d = TextIR.dialect(ctx and ctx.dialect)
  if not d.placeholders then return nil end
  return provider("placeholders", d, ctx)
end

local function is_female(g)
  return g == 1 or g == "female" or g == "F" or g == "girl"
end

local function player_female(d, ctx)
  local g = ctx and ctx.playerGender
  if g == nil and TextIR._provider then g = TextIR._provider("gender", d, ctx) end
  return is_female(g)
end

-- pokeemerald/src/string_util.c:456
local function gendered_ph(name, ctx)
  local d = TextIR.dialect(ctx and ctx.dialect)
  if not (d.GENDERED_PH and d.GENDERED_PH[name]) then return nil end
  local ph = TextIR.placeholdersFor(ctx)
  local by = ph and ph.byGender and ph.byGender[name]
  if type(by) ~= "table" then return nil end
  if player_female(d, ctx) then return by.female end
  return by.male
end

-- A dialect's gendered placeholder read from the cart strings the loaded
-- script cache holds under its labels, where a mod's text overrides land; ""
-- when the cache is not loaded or both strings are empty (the US cart). A
-- label whose own text holds the placeholder expands it to "" there.
local reading_label = false
local function gendered_label(d, name, ctx)
  local labels = d.GENDERED_LABELS and d.GENDERED_LABELS[name]
  if not labels then return nil end
  if reading_label then return "" end
  local Space = package.loaded["src.core.game3.scripting.space"]
  if not (Space and Space.bundle) then return "" end
  local RomText = require("src.core.game3.rom_text")
  local function read(label) return RomText.has(label) and RomText.plain(label) or "" end
  reading_label = true
  local ok, male, female = pcall(function() return read(labels.male), read(labels.female) end)
  reading_label = false
  if not ok then error(male, 0) end
  if male == "" and female == "" then return "" end
  if player_female(d, ctx) then return female end
  return male
end

-- pokeemerald/src/string_util.c:428
local function live(field, ctx)
  local v = ctx and ctx[field]
  if v ~= nil then return v end
  local provider = TextIR._provider
  if not provider then return nil end
  return provider(field, TextIR.dialect(ctx and ctx.dialect), ctx)
end

local function player_name(ctx)
  return live("playerName", ctx) or "PLAYER"
end

local function string_var(n, ctx)
  local sv = live("stringVars", ctx)
  return (type(sv) == "table" and sv[n]) or ""
end

local function rival_name(ctx)
  local v = gendered_ph("RIVAL", ctx)
  if v ~= nil then return v end
  return live("rivalName", ctx) or "RIVAL"
end

local function expand_seg(seg, ctx)
  local t = seg.t
  if t == "text" then
    return seg.s
  elseif t == "dynamic" then
    local dyn = ctx and ctx.dynamic
    return (dyn and dyn[seg.n]) or ""
  elseif t == "player" then
    return player_name(ctx)
  elseif t == "rival" then
    return rival_name(ctx)
  elseif t == "strvar" then
    return string_var(seg.n, ctx)
  elseif t == "tag" then
    return seg.tag
  elseif t == "bph" then
    local value = ctx and ctx.battle and ctx.battle[seg.code]
    if value == nil then
      local names = (ctx and ctx.dialect) and TextIR.dialect(ctx.dialect).B_TXT or TextIR.B_TXT
      error("battle text placeholder {" .. tostring(names[seg.code] or seg.code)
        .. "} has no value", 0)
    end
    return value
  elseif t == "ph" then
    -- Cached extracts may still store FD 06 as { t="ph", code=6 }.
    local code = tonumber(seg.code)
    local name = seg.name
    if code == 0x01 or name == "PLAYER" then
      return player_name(ctx)
    end
    if code == 0x06 or name == "RIVAL" then
      return rival_name(ctx)
    end
    if code and code >= 0x02 and code <= 0x04 then
      return string_var(code - 1, ctx)
    end
    if name == "STR_VAR_1" or name == "STR_VAR_2" or name == "STR_VAR_3" then
      return string_var(tonumber(name:sub(-1)) or 1, ctx)
    end
    if name and (name == "FONT_MALE" or name == "FONT_FEMALE" or name == "FONT_NORMAL"
        or name:find("^COLOR") or name:find("^SHADOW") or name:find("^HIGHLIGHT") or name:find("^BG")) then
      return "{" .. name .. "}"
    end
    -- pokeemerald/src/string_util.c:464
    local d = TextIR.dialect(ctx and ctx.dialect)
    local pname = name or (code and d.PH_NAMES[code])
    local fromLabel = pname and gendered_label(d, pname, ctx)
    if fromLabel ~= nil then return fromLabel end
    local placeholders = TextIR.placeholdersFor(ctx)
    if placeholders then
      local g = pname and gendered_ph(pname, ctx)
      if g ~= nil then return g end
      if pname and placeholders[pname] then return placeholders[pname] end
    end
    return ""
  end
  return nil
end

TextIR.expandSeg = expand_seg

local function flush_text(out, buf)
  if buf and #buf > 0 then
    out[#out + 1] = { t = "text", s = table.concat(buf) }
  end
end

--- Decode raw GBA string bytes (table of ints or string) into IR.
function TextIR.decode(bytes, opts)
  local battle = opts and opts.battle
  local dialect = TextIR.dialect(opts and opts.dialect)
  local named = dialect.name ~= TextIR.DEFAULT_DIALECT
  local extra, runs = dialect.CHARMAP_EXTRA, dialect.CHARMAP_RUNS
  local out, buf = {}, {}
  local i, n = 1, #bytes
  local function b(idx)
    if type(bytes) == "string" then return bytes:byte(idx) end
    return bytes[idx]
  end
  while i <= n do
    local c = b(i)
    if c == 0xFF then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "eos" }
      break
    elseif c == 0xFE then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "nl" }
      i = i + 1
    elseif c == 0xFA then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "scroll" }
      i = i + 1
    elseif c == 0xFB then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "para" }
      i = i + 1
    elseif c == 0xFD then
      flush_text(out, buf); buf = {}
      local nn = b(i + 1) or 0
      if battle then
        out[#out + 1] = { t = "bph", code = nn }
      elseif nn == 0x01 then
        out[#out + 1] = { t = "player" }
      elseif nn == 0x06 then
        out[#out + 1] = { t = "rival" }
      elseif nn >= 0x02 and nn <= 0x04 then
        out[#out + 1] = { t = "strvar", n = nn - 1 }
      elseif named then
        out[#out + 1] = { t = "ph", code = nn, name = dialect.PH_NAMES[nn] }
      else
        out[#out + 1] = { t = "ph", code = nn }
      end
      i = i + 2
    elseif c == 0xF7 then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "dynamic", n = b(i + 1) or 0 }
      i = i + 2
    elseif c == 0xF8 then
      flush_text(out, buf); buf = {}
      local key = TextIR.KEYGFX[b(i + 1) or -1]
      out[#out + 1] = { t = "tag", tag = key and ("{" .. key .. "}") or "" }
      i = i + 2
    elseif c == 0xF9 then
      local sym = TextIR.EXTRA_SYMBOL[b(i + 1) or -1]
      if sym and sym:sub(1, 1) == "{" then
        flush_text(out, buf); buf = {}
        out[#out + 1] = { t = "tag", tag = sym }
      else
        buf[#buf + 1] = sym or "?"
      end
      i = i + 2
    elseif c == 0xFC then
      flush_text(out, buf); buf = {}
      local cmd = b(i + 1) or 0
      local nargs = TextIR.EXT_ARGS[cmd] or 0
      local args = {}
      for k = 1, nargs do args[k] = b(i + 1 + k) or 0 end
      out[#out + 1] = { t = "ext", cmd = cmd, args = args }
      if named and cmd == 0x06 then out[#out].font = dialect.FONT_IDS[args[1]] end
      i = i + 2 + nargs
    else
      local g = CHARMAP[c]
      if g then
        buf[#buf + 1] = g
        i = i + 1
      elseif TextIR.LIGATURE[c] then
        flush_text(out, buf); buf = {}
        if c == 0x53 and b(i + 1) == 0x54 then
          out[#out + 1] = { t = "tag", tag = "{PKMN}" }
          i = i + 2
        else
          out[#out + 1] = { t = "tag", tag = TextIR.LIGATURE[c] }
          i = i + 1
        end
      elseif extra and extra[c] then
        local run = runs and runs[c]
        local len = 0
        if run then
          len = #run.bytes
          for k = 1, len do
            if b(i + k - 1) ~= run.bytes[k] then len = 0 break end
          end
        end
        local tag = len > 0 and run.tag or extra[c]
        if tag ~= "" then
          flush_text(out, buf); buf = {}
          out[#out + 1] = { t = "tag", tag = tag }
        end
        i = i + math.max(len, 1)
      else
        buf[#buf + 1] = "?"
        i = i + 1
      end
    end
  end
  flush_text(out, buf)
  return out
end

--- Build IR from pret-style ASCII with \n \p \l {PLAYER} {STR_VAR_1} …
function TextIR.fromAscii(s, opts)
  local bcodes = TextIR.dialect(opts and opts.dialect).B_TXT_CODE
  local out, buf = {}, {}
  local i = 1
  while i <= #s do
    local ch = s:sub(i, i)
    if ch == "\252" and i < #s then
      local len = ext_len(s, i)
      buf[#buf + 1] = s:sub(i, i + len - 1)
      i = i + len
    elseif ch == "\\" and i < #s then
      local n = s:sub(i + 1, i + 1)
      flush_text(out, buf); buf = {}
      if n == "n" then out[#out + 1] = { t = "nl" }
      elseif n == "p" then out[#out + 1] = { t = "para" }
      elseif n == "l" then out[#out + 1] = { t = "scroll" }
      elseif n == "f" then out[#out + 1] = { t = "para" }
      else buf[#buf + 1] = "\\" .. n end
      i = i + 2
    elseif ch == "\n" then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "nl" }
      i = i + 1
    elseif ch == "\f" then
      flush_text(out, buf); buf = {}
      out[#out + 1] = { t = "para" }
      i = i + 1
    elseif ch == "\r" then
      i = i + 1
    elseif ch == "{" then
      local j = s:find("}", i)
      if not j or s:find("\252", i, true) and s:find("\252", i, true) < j then
        buf[#buf + 1] = ch; i = i + 1
      else
        flush_text(out, buf); buf = {}
        local name = s:sub(i + 1, j - 1)
        if name == "PLAYER" then
          out[#out + 1] = { t = "player" }
        elseif name == "RIVAL" then
          out[#out + 1] = { t = "rival" }
        elseif name == "STR_VAR_1" then
          out[#out + 1] = { t = "strvar", n = 1 }
        elseif name == "STR_VAR_2" then
          out[#out + 1] = { t = "strvar", n = 2 }
        elseif name == "STR_VAR_3" then
          out[#out + 1] = { t = "strvar", n = 3 }
        elseif bcodes[name] then
          out[#out + 1] = { t = "bph", code = bcodes[name] }
        elseif TextIR.TAG_NAMES[name] then
          out[#out + 1] = { t = "tag", tag = "{" .. name .. "}" }
        elseif name == "FONT_MALE" or name == "FONT_FEMALE" or name == "FONT_NORMAL"
            or name:find("^COLOR") or name:find("^SHADOW") or name:find("^HIGHLIGHT") or name:find("^BG") then
          out[#out + 1] = { t = "tag", tag = "{" .. name .. "}" }
        else
          out[#out + 1] = { t = "ph", name = name }
        end
        i = j + 1
      end
    else
      buf[#buf + 1] = ch
      i = i + 1
    end
  end
  flush_text(out, buf)
  out[#out + 1] = { t = "eos" }
  return out
end

local NAMED = { player = "{PLAYER}", rival = "{RIVAL}" }

function TextIR.toSource(ir, ctx, opts)
  opts = opts or {}
  local para = opts.para or "\\p"
  local parts, args = {}, {}
  for _, seg in ipairs(ir or {}) do
    local t = seg.t
    if t == "eos" then
      break
    elseif t == "nl" then
      parts[#parts + 1] = opts.nl or "\n"
    elseif t == "scroll" then
      parts[#parts + 1] = opts.scroll or opts.nl or "\n"
    elseif t == "para" then
      parts[#parts + 1] = para
    elseif t == "text" or t == "tag" then
      parts[#parts + 1] = (expand_seg(seg, ctx):gsub("%%", "%%%%"))
    elseif opts.named and (NAMED[t] or t == "strvar") then
      parts[#parts + 1] = NAMED[t] or ("{STR_VAR_" .. seg.n .. "}")
    elseif t ~= "ext" then
      local value = expand_seg(seg, ctx)
      if value ~= nil then
        parts[#parts + 1] = (opts.digits and tostring(value):match("^%d+$")) and "%d" or "%s"
        args[#args + 1] = value
      end
    end
  end
  local suffix = ""
  if opts.trim then
    while #parts > 0 and (parts[#parts] == para or parts[#parts] == (opts.nl or "\n")
        or parts[#parts] == opts.scroll) do
      suffix = table.remove(parts) .. suffix
    end
  end
  return table.concat(parts), args, suffix
end

local ASCII_BREAK = { nl = "\n", scroll = "\\l", para = "\\p" }

function TextIR.toAscii(ir, ctx)
  local parts = {}
  for _, seg in ipairs(ir or {}) do
    local t = seg.t
    if t == "eos" then
      break
    elseif ASCII_BREAK[t] then
      parts[#parts + 1] = ASCII_BREAK[t]
    elseif t ~= "ext" then
      local value = expand_seg(seg, ctx)
      if value ~= nil then parts[#parts + 1] = value end
    end
  end
  return (table.concat(parts):gsub("\\p[\n]+$", "\\p"))
end

--- Expand IR to printable pages for host textbox (list of strings).
-- Yields on scroll/para; caller advances. stringVars/player/rival from ctx.
function TextIR.expandPage(ir, startIdx, ctx)
  local parts = {}
  local i = startIdx or 1
  while i <= #ir do
    local seg = ir[i]
    local t = seg.t
    if t == "nl" then
      parts[#parts + 1] = "\n"
    elseif t == "para" or t == "scroll" then
      return table.concat(parts), i + 1, t
    elseif t == "eos" then
      return table.concat(parts), i + 1, "eos"
    elseif t == "ext" then
      -- ignore for v1 printer
    else
      local s = expand_seg(seg, ctx)
      if s then parts[#parts + 1] = s end
    end
    i = i + 1
  end
  return table.concat(parts), i, "eos"
end

function TextIR.toPlain(ir, ctx)
  local pages, idx, kind = {}, 1, nil
  repeat
    local page
    page, idx, kind = TextIR.expandPage(ir, idx, ctx)
    if page and #page > 0 then pages[#pages + 1] = page end
  until kind == "eos" or not kind
  return table.concat(pages, "\n\n")
end

local function wrap_subline(lineStr, maxW)
  if not lineStr or lineStr == "" then return { "" } end
  maxW = maxW or 208
  local okF, FrlgFont = pcall(require, "src.ui.game3.frlg_font")
  if okF and FrlgFont and FrlgFont.measure then
    local function measure(str) return FrlgFont.measure(TextIR.restoreExt(str)) end
    local curW = measure(lineStr)
    if curW <= maxW then
      return { lineStr }
    end
    local spaceW = FrlgFont.measure(" ")
    local words = {}
    for word in lineStr:gmatch("%S+") do
      words[#words + 1] = word
    end
    if #words == 0 then return { "" } end
    local out = {}
    local cur = words[1]
    local curLineWidth = measure(cur)
    for i = 2, #words do
      local w = words[i]
      local wW = measure(w)
      if curLineWidth + spaceW + wW <= maxW then
        cur = cur .. " " .. w
        curLineWidth = curLineWidth + spaceW + wW
      else
        out[#out + 1] = cur
        cur = w
        curLineWidth = wW
      end
    end
    out[#out + 1] = cur
    return out
  else
    local maxChars = math.floor(maxW / 6)
    local function len(str) return #TextIR.restoreExt(str) end
    if len(lineStr) <= maxChars then return { lineStr } end
    local words = {}
    for word in lineStr:gmatch("%S+") do words[#words + 1] = word end
    if #words == 0 then return { "" } end
    local out = {}
    local cur = words[1]
    for i = 2, #words do
      local w = words[i]
      if len(cur) + 1 + len(w) <= maxChars then
        cur = cur .. " " .. w
      else
        out[#out + 1] = cur
        cur = w
      end
    end
    out[#out + 1] = cur
    return out
  end
end

--- Host TextBox string: always tap-per-page of at most two lines.
-- `\n` joins the pair inside a page; `\f` clears for the next pair (wait A).
-- Never emits `\v` CONT scroll — Gen1 column budgets make one-line scroll feel
-- too fast. GBA `\p` / `\l` both force a page boundary like a filled pair.
function TextIR.toTextBox(ir, ctx)
  local maxW = (type(ctx) == "table" and ctx.maxWidth) or 208
  local lines, buf = {}, {}
  local function flush(hard)
    lines[#lines + 1] = { s = table.concat(buf), hard = hard }
    buf = {}
  end
  for _, seg in ipairs(ir or {}) do
    local t = seg.t
    local expanded = expand_seg(seg, ctx)
    if expanded ~= nil then
      buf[#buf + 1] = expanded
    elseif t == "nl" then
      flush(false)
    elseif t == "para" or t == "scroll" then
      flush(true)
    elseif t == "eos" then
      if #buf > 0 then flush(false) end
    end
  end
  if #buf > 0 then flush(false) end

  local splitLines = {}
  for _, row in ipairs(lines) do
    local text = TextIR.protectExt(row.s)
    local hard = row.hard
    local sub = {}
    for line in (text .. "\n"):gmatch("(.-)\r?\n") do
      sub[#sub + 1] = line
    end
    if #sub == 0 then sub = { "" } end
    for si, lineStr in ipairs(sub) do
      local isLastSub = (si == #sub)
      local wrappedList = wrap_subline(lineStr, maxW)
      for wi, wLine in ipairs(wrappedList) do
        local isLastWrap = (wi == #wrappedList)
        splitLines[#splitLines + 1] = {
          s = wLine,
          hard = (isLastSub and isLastWrap) and hard or false,
        }
      end
    end
  end

  local parts = {}
  local onPage = 0
  for _, row in ipairs(splitLines) do
    if row.s ~= "" or row.hard then
      if onPage >= 2 then
        if #parts > 0 then parts[#parts + 1] = "\f" end
        onPage = 0
      elseif onPage > 0 then
        parts[#parts + 1] = "\n"
      end
      if row.s ~= "" then
        parts[#parts + 1] = row.s
        onPage = onPage + 1
      end
      if row.hard then
        onPage = 2 -- next line starts a fresh cleared page
      end
    end
  end
  local s = table.concat(parts):gsub("^\f+", ""):gsub("\f+$", "")
  return TextIR.restoreExt(s)
end

return TextIR
