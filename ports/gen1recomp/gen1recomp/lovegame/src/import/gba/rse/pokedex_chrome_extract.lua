local K = require("src.import.gba.rse.boot_gfx")
local TextIR = require("src.core.game3.scripting.text_ir")

local M = {}

M.SUB = "rse/pokedex"

M.GFX = {
  menu = { "gPokedexMenu_Gfx", true },
  interface = { "gPokedexInterface_Gfx", true },
  search = { "gPokedexSearchMenu_Gfx", true },
  area_map = { "sPokedexAreaMap_Gfx", true },
  area_glow = { "sAreaGlow_Gfx", true },
  area_unknown = { "gPokedexAreaScreenAreaUnknown_Gfx", true },
  area_marker = { "sAreaMarkerTiles", false },
  cry_meter = { "sCryMeter_Gfx", true },
  cry_needle = { "sCryMeterNeedle_Gfx", false },
  cry_bg = { "sCryScreenBg_Gfx", false },
  caught_ball = { "sCaughtBall_Gfx", false },
}

M.MAPS = {
  list = "gPokedexList_Tilemap",
  list_underlay = "gPokedexListUnderlay_Tilemap",
  start_menu_main = "gPokedexStartMenuMain_Tilemap",
  start_menu_search = "gPokedexStartMenuSearchResults_Tilemap",
  info = "gPokedexInfoScreen_Tilemap",
  cry = "gPokedexCryScreen_Tilemap",
  size = "gPokedexSizeScreen_Tilemap",
  select_main = "gPokedexScreenSelectBarMain_Tilemap",
  select_sub = "gPokedexScreenSelectBarSubmenu_Tilemap",
  search_hoenn = "gPokedexSearchMenuHoenn_Tilemap",
  search_national = "gPokedexSearchMenuNational_Tilemap",
  area_map = "sPokedexAreaMap_Tilemap",
}

M.PALETTES = {
  hoenn = { "gPokedexBgHoenn_Pal", 96 },
  national = { "gPokedexBgNational_Pal", 96 },
  searchResults = { "gPokedexSearchResults_Pal", 96 },
  searchMenu = { "gPokedexSearchMenu_Pal", 64 },
  messageBox = { "gMessageBox_Pal", 16 },
  areaMap = { "sPokedexAreaMap_Pal", 48 },
  areaGlow = { "sAreaGlow_Pal", 16 },
  areaMarker = { "sAreaMarkerPalette", 16 },
  areaUnknown = { "gPokedexAreaScreenAreaUnknown_Pal", 16 },
  cryMeter = { "sCryMeter_Pal", 16 },
  cryNeedle = { "sCryMeterNeedle_Pal", 16 },
  cryBg = { "sCryScreenBg_Pal", 16 },
  silhouette = { "sSizeScreenSilhouette_Pal", 16 },
}

M.FILES = {}
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
for k in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
M.FILES[#M.FILES + 1] = "orders.lua"
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

local function readString(c, off, maxLen)
  if not off then return "" end
  local bytes = {}
  for i = 0, (maxLen or 256) - 1 do
    local b = c:u8(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = "rse" }), {})
end

local function bytes(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name)) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function u16s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name) / 2) - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

-- pokeemerald/src/pokedex.c:127
local function options(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 8 - 1 do
    local titlePtr = c:ptr(off + i * 8 + 4)
    if not titlePtr then break end
    out[#out + 1] = { description = readString(c, c:ptr(off + i * 8)), title = readString(c, titlePtr) }
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  local gfx = {}
  for key, spec in pairs(M.GFX) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    c:write(key .. ".gfx", data)
    gfx[key] = { path = c:path(key .. ".gfx"), bytes = #data }
  end
  local maps = {}
  for key, sym in pairs(M.MAPS) do
    local data = c:lz(sym)
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end
  local palettes = {}
  for key, spec in pairs(M.PALETTES) do
    palettes[key] = K.palList(c:palAt(c:off(spec[1]), spec[2]), 0, spec[2])
  end

  -- pokeemerald/src/pokedex.c:1330
  local search = {
    modes = options(c, "sDexModeOptions"),
    orders = options(c, "sDexOrderOptions"),
    names = options(c, "sDexSearchNameOptions"),
    colors = options(c, "sDexSearchColorOptions"),
    types = options(c, "sDexSearchTypeOptions"),
    typeIds = bytes(c, "sDexSearchTypeIds"),
    orderIds = bytes(c, "sOrderOptions"),
    modeIds = bytes(c, "sPokedexModes"),
    letterRanges = {},
    topBar = {},
    items = {},
    movement = {},
  }
  -- pokeemerald/src/pokedex.c:995
  local lo = c:off("sLetterSearchRanges")
  for i = 0, c.S.size("sLetterSearchRanges") / 4 - 1 do
    search.letterRanges[i] = { c:u8(lo + i * 4), c:u8(lo + i * 4 + 1), c:u8(lo + i * 4 + 2), c:u8(lo + i * 4 + 3) }
  end
  -- pokeemerald/src/pokedex.c:1017
  local to = c:off("sSearchMenuTopBarItems")
  for i = 0, c.S.size("sSearchMenuTopBarItems") / 8 - 1 do
    local o = to + i * 8
    search.topBar[i + 1] = { description = readString(c, c:ptr(o)), x = c:u8(o + 4), y = c:u8(o + 5), width = c:u8(o + 6) }
  end
  -- pokeemerald/src/pokedex.c:1042
  local io = c:off("sSearchMenuItems")
  for i = 0, c.S.size("sSearchMenuItems") / 12 - 1 do
    local o = io + i * 12
    search.items[i + 1] = {
      description = readString(c, c:ptr(o)),
      titleX = c:u8(o + 4), titleY = c:u8(o + 5), titleWidth = c:u8(o + 6),
      selX = c:u8(o + 7), selY = c:u8(o + 8), selWidth = c:u8(o + 9),
    }
  end
  -- pokeemerald/src/pokedex.c:1117
  for _, key in ipairs({ "SearchNatDex", "ShiftNatDex", "SearchHoennDex", "ShiftHoennDex" }) do
    local name = "sSearchMovementMap_" .. key
    local mo, rows = c:off(name), {}
    for i = 0, c.S.size(name) / 4 - 1 do
      rows[i + 1] = { c:u8(mo + i * 4), c:u8(mo + i * 4 + 1), c:u8(mo + i * 4 + 2), c:u8(mo + i * 4 + 3) }
    end
    search.movement[key] = rows
  end

  -- pokeemerald/src/pokedex_area_screen.c:122
  local feebas, fo = {}, c:off("sFeebasData")
  for i = 0, c.S.size("sFeebasData") / 6 - 1 do
    feebas[i + 1] = { c:u16(fo + i * 6), c:u16(fo + i * 6 + 2), c:u16(fo + i * 6 + 4) }
  end
  local landmarks, lmo = {}, c:off("sLandmarkData")
  for i = 0, c.S.size("sLandmarkData") / 4 - 1 do
    landmarks[i + 1] = { c:u16(lmo + i * 4), c:u16(lmo + i * 4 + 2) }
  end

  -- pokeemerald/include/pokemon.h:323
  local bodyColor, si = {}, c:off("gSpeciesInfo")
  for sp = 0, c.S.size("gSpeciesInfo") / 28 - 1 do
    bodyColor[sp] = c:u8(si + sp * 28 + 0x19) % 128
  end

  local sine = {}
  local so = c:off("gSineTable")
  for i = 0, c.S.size("gSineTable") / 2 - 1 do
    local v = c:u16(so + i * 2)
    if v >= 0x8000 then v = v - 0x10000 end
    sine[i] = v
  end

  -- pokeemerald/src/pokedex.c:2246
  require("src.import.gba.pokedex_chrome_extract").extractOrders(rom, cache, c.root)
  c.files[#c.files + 1] = "orders.lua"

  return true, c:finish({
    screen = "pokedex",
    gfx = gfx,
    maps = maps,
    palettes = palettes,
    sine = sine,
    scrollMonIncrements = bytes(c, "sScrollMonIncrements"),
    scrollTimers = bytes(c, "sScrollTimers"),
    bodyColor = bodyColor,
    tenDashes = readString(c, c:off("sText_TenDashes")),
    search = search,
    area = {
      glowMapping = bytes(c, "sAreaGlowTilemapMapping"),
      feebas = feebas,
      landmarks = landmarks,
      hiddenSpecies = u16s(c, "sSpeciesHiddenFromAreaScreen"),
      movingMapSecs = u16s(c, "sMovingRegionMapSections"),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
