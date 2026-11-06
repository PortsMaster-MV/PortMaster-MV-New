local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokeblock", FILES = {}, packVersion = 1}

local GFX = {
  menu = {"gMenuPokeblock_Gfx", true}, device = {"gMenuPokeblockDevice_Gfx", true},
  pokeblock = {"gPokeblock_Gfx", true}, feed_bg = {"gBattleEnvironmentTiles_Building", true},
  graph = {"gPokenavConditionView_Gfx", true}, mon_frame = {"gPokenavRibbonPokeView_Gfx", false},
  updown = {"ConditionUpDownTiles", false}, ball = {"gPokenavPokeballTiles", false},
  ball_placeholder = {"gUnknown_083E3780", false}, cancel = {"gPokenavConditionMenuCancel_Gfx", false},
  sparkle = {"gPokenavSparkle_Gfx", false},
}
local MAPS = {menu = {"gMenuPokeblock_Tilemap", true}, feed_bg = {"gUnknown_08E782FC", true},
  graph = {"gUnknown_08E9AC4C", true}, mon_frame = {"gUnknown_08E9FF58", true},
  graph_data = {"gUnknown_08E9FEB4", true}, nature_win = {"gUnknown_083E01F4", false}}
for key in pairs(GFX) do M.FILES[#M.FILES + 1] = key .. ".gfx" end
M.FILES[#M.FILES + 1] = "condition.gfx"
for key in pairs(MAPS) do M.FILES[#M.FILES + 1] = key .. ".map" end
local headerNames = {"cool", "beauty", "cute", "smart", "tough", "party", "search"}
for _, name in ipairs(headerNames) do M.FILES[#M.FILES + 1] = "header_" .. name .. ".png" end
for bank = 0, 2 do M.FILES[#M.FILES + 1] = "highlight_" .. bank .. ".png" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

local function numbers(c, name, unit, signed)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, unit) - 1 do
    out[i + 1] = unit == 1 and c:u8(off + i) or (signed and c:s16(off + i * 2) or c:u16(off + i * 2))
  end
  return out
end
local function pairs16(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 4) - 1 do out[i + 1] = {c:s16(off + i * 4), c:s16(off + i * 4 + 2)} end
  return out
end
local function affineTable(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 4) - 1 do
    local ptr, commands = assert(c:ptr(off + i * 4)), {}
    for j = 0, 63 do
      local b, x = ptr + j * 8, c:s16(ptr + j * 8)
      if x == 0x7FFF then commands[#commands + 1] = {op = "end"}; break end
      if x == 0x7FFE then commands[#commands + 1] = {op = "jump", target = c:u16(b + 2)}; break end
      if x == 0x7FFD then commands[#commands + 1] = {op = "loop", count = c:u16(b + 2)}
      else commands[#commands + 1] = {op = "frame", xScale = x, yScale = c:s16(b + 2), rotation = c:s8(b + 4), duration = c:u8(b + 5)} end
    end
    out[i + 1] = commands
  end
  return out
end
local function window(c, name)
  local out, off = {}, c:off(name)
  for i, key in ipairs({"bg", "charbase", "screenbase", "priority", "palette", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "left", "top", "width", "height"}) do
    out[key] = c:u8(off + i - 1)
  end
  return out
end
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local man = {screen = "pokeblock", packVersion = M.packVersion, gfx = {}, maps = {}, palettes = {}, headers = {}, strings = {}}
  local raw = {}
  for key, spec in pairs(GFX) do
    local bytes = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    raw[key] = bytes
    man.gfx[key] = {path = c:write(key .. ".gfx", bytes), bytes = #bytes}
  end
  local options = {c:lz("gPokenavConditionMenuOptions_Gfx"), c:lz("gPokenavConditionMenuOptions2_Gfx")}
  local condition = options[1] .. options[2]
  man.gfx.condition = {path = c:write("condition.gfx", condition), bytes = #condition}
  for key, spec in pairs(MAPS) do
    local bytes = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    man.maps[key] = {path = c:write(key .. ".map", bytes), entries = #bytes / 2}
  end
  for key, spec in pairs({menu = {"gMenuPokeblock_Pal", 96, true}, device = {"gMenuPokeblockDevice_Pal", 16, true},
    feed_bg = {"gBattleEnvironmentPalette_BattleTower", 48, true}, graph = {"gPokenavConditionMenu2_Pal", 16},
    mon_frame = {"gUnknown_083E0124", 16}, graph_data = {"gUnknown_083E0254", 16},
    updown = {"ConditionUpDownPalette", 16}, sparkle = {"gPokenavSparkle_Pal", 16},
    condition = {"gPokenavMenuOptions3_Pal", 16}}) do
    man.palettes[key] = K.palList(c:pal(spec[1], spec[2], nil, nil, spec[3]), 0, spec[2])
  end
  local cp, text = c:off("gPokenavConditionMenu2_Pal"), c:pal("gUnknownPalette_81E6692", 16)
  text[1], text[5], text[15] = c:u16(cp + 2 * 2), c:u16(cp + 16 * 2), c:u16(cp + 30 * 2)
  man.palettes.condition_text = K.palList(text, 0, 16)
  local selected, inactive = c:pal("gPokenavConditionPokeball_Pal", 16), c:pal("gPokenavCondition4_Pal", 16)
  man.palettes.cancel = {}; for i = 0, 15 do man.palettes.cancel[i + 1], man.palettes.cancel[i + 17] = selected[i], inactive[i] end
  local headerPals = {c:pal("gPokenavMenuOptions3_Pal", 16), c:pal("gPokenavCondition5_Pal", 16)}
  for i, name in ipairs(headerNames) do
    local group, chunk = i <= 4 and 1 or 2, i <= 4 and i - 1 or i - 5
    local pixels = K.blank(64, 16)
    for piece = 0, 1 do
      local part = K.bakeSprite(options[group], 32, 16, chunk * 16 + piece * 8, 4)
      for y = 0, 15 do for x = 0, 31 do pixels[y * 64 + piece * 32 + x + 1] = part[y * 32 + x + 1] end end
    end
    man.headers[name] = {png = c:png("header_" .. name .. ".png", 64, 16, pixels, headerPals[group], true), w = 64, h = 16}
  end
  man.highlight = {tile = 5, x = 120, y = 8, w = 112, h = 16, rowSpacing = 16, banks = {}}
  local tile = K.bakeSprite(raw.menu, 8, 8, 5, 4)
  local menuPal = c:pal("gMenuPokeblock_Pal", 96, nil, nil, true)
  for bank = 0, 2 do
    local pal = {}; for i = 0, 15 do pal[i] = menuPal[bank * 16 + i] end
    man.highlight.banks[bank] = c:png("highlight_" .. bank .. ".png", 8, 8, tile, pal, false)
  end
  man.colors = {}
  local po = c:off("pokeblock_feed.o:sPokeblocksPals")
  assert(c.S.count("pokeblock_feed.o:sPokeblocksPals", 4) == 14, "native Pokeblock color count")
  for i = 0, 13 do man.colors[i + 1] = K.palList(c:palFrom(c:lzAt(assert(c:ptr(po + i * 4))), 16), 0, 16) end
  man.favorites = {}
  local fo = c:off("gUnknown_083F7F9C")
  assert(c.S.size("gUnknown_083F7F9C") == 40, "native five8-byte favorite Pokeblocks")
  for i = 0, 4 do
    local row = {}; for j, key in ipairs({"color", "spicy", "dry", "sweet", "bitter", "sour", "feel"}) do row[key] = c:u8(fo + i * 8 + j - 1) end
    man.favorites[i + 1] = row
  end
  man.feedAnims = {}
  local ao = c:off("pokeblock_feed.o:sMonPokeblockAnims")
  for i = 0, c.S.count("pokeblock_feed.o:sMonPokeblockAnims", 20) - 1 do
    local row = {}; for j = 0, 9 do row[j + 1] = c:s16(ao + i * 20 + j * 2) end
    man.feedAnims[i + 1] = row
  end
  man.natureAnims = A.pairs(c, "pokeblock_feed.o:sNatureToMonPokeblockAnim")
  man.sparkleCoords, man.upDownCoords = pairs16(c, "gUnknown_083E4794"), pairs16(c, "use_pokeblock.o:gUnknown_08406158")
  man.lineLength, man.sine = numbers(c, "gUnknown_083E4890", 1), numbers(c, "gSineTable", 2, true)
  man.conditionToFlavor = numbers(c, "use_pokeblock.o:gUnknown_0840612C", 1)
  man.noFlip = {}; local so = c:off("gBaseStats")
  for sp = 0, c.S.count("gBaseStats", 28) - 1 do if c:u8(so + sp * 28 + 25) >= 128 then man.noFlip[sp] = true end end
  man.affine = {mon = affineTable(c, "pokeblock_feed.o:sSpriteAffineAnimTable_8412050"),
    monNoFlip = affineTable(c, "pokeblock_feed.o:sSpriteAffineAnimTable_84120EC"),
    caseStill = affineTable(c, "pokeblock_feed.o:sSpriteAffineAnimTable_84121A0"),
    caseThrow = affineTable(c, "pokeblock_feed.o:sSpriteAffineAnimTable_84121A4"),
    caseThrowOpposite = affineTable(c, "pokeblock_feed.o:sSpriteAffineAnimTable_84121A8"),
    pokeblock = affineTable(c, "pokeblock_feed.o:sThrownPokeblockAffineAnimTable")}
  man.graphTileBase, man.monFrameTileBase = 640, 256
  man.windows = {list = window(c, "gWindowTemplate_81E6E34"), actions = window(c, "gWindowTemplate_81E6E50"),
    condition = window(c, "gWindowTemplate_81E7080")}
  man.geometry = {device = {56, 64}, list = {120, 8, 16, 9}, graph = {155, 91}, graphRangeY = {56, 121},
    portrait = {38, 104}, naturePatch = {0, 13, 12, 4}, graphAlpha = {11, 4}, interpolationSteps = 10,
    headersHeight = 16, yesNo = {8, 7}, message = {8, 120}, feedingSetupStates = 9}
  for _, name in ipairs({"OtherText_Use", "OtherText_Toss", "gOtherText_CancelNoTerminator", "gContestStatsText_Spicy",
    "gContestStatsText_Dry", "gContestStatsText_Sweet", "gContestStatsText_Bitter", "gContestStatsText_Sour",
    "gContestStatsText_StowCase", "gContestStatsText_ThrowAwayPrompt", "gContestStatsText_WasThrownAway",
    "gOtherText_Nature2", "gOtherText_GetsAPokeBlock", "gOtherText_WontEat", "gOtherText_WasEnhanced", "gOtherText_NothingChanged",
    "OtherText_Coolness", "OtherText_Toughness", "OtherText_Smartness", "OtherText_Cuteness", "OtherText_Beauty",
    "gContestStatsText_NormallyAte", "gContestStatsText_HappilyAte", "gContestStatsText_DisdainfullyAte"}) do
    man.strings[name] = A.text(c, c:off(name))
  end
  man.natureNames = {}; local no = c:off("gNatureNames")
  for i = 0, c.S.count("gNatureNames", 4) - 1 do man.natureNames[i + 1] = A.text(c, assert(c:ptr(no + i * 4))) end
  return A.finish(c, man)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  local body = cache:read(base .. "manifest.lua")
  if not body:find("packVersion = " .. M.packVersion, 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(base .. file) then return false end end
  return true
end
return M
