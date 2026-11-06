local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokedex_detail"}
local graphics = {
  {"area_glow", "gUnknown_083F8438", true}, {"area_unknown", "gAreaUnknownTiles", true},
  {"area_marker", "AreaMarkerTiles"}, {"cry_meter", "gCryMeter_Gfx", true},
  {"cry_needle", "CryMeterNeedleTiles"}, {"cry_bg", "sCryScreenBg_Gfx"},
}
M.FILES = {"area_map.png", "caught_ball.gfx", "number.gfx", "cry_meter.map"}
for _, g in ipairs(graphics) do M.FILES[#M.FILES + 1] = g[1] .. ".gfx" end
M.REQUIRED = K.required(M.SUB, M.FILES)

local function glowTile(v)
  local lo, hi = v % 16, math.floor(v / 16)
  if hi == 0 then return lo end
  if lo == 0 then return hi + 16 end
  if lo == 2 then return lo + hi + 30 end
  if lo == 1 then return lo + math.floor(hi / 4) + 32 end
  if lo == 8 then return lo + 32 + math.floor(hi / 8) % 2 + math.floor(hi / 2) % 2 * 2 end
  if lo == 4 then return lo + 33 + math.floor(hi / 4) % 2 + hi % 2 * 2 end
  if lo == 5 or lo == 6 then return lo + 39 end
  if lo == 9 or lo == 10 then return lo + 37 end
  return lo
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokedex_detail", gfx = {}, maps = {}, palettes = {},
    bodyColor = {}, speciesFirstChar = {}, speciesTypes = {}, sine = {}, strings = {}, windows = {},
    tenDashes = "----------", area = {feebas = {}, landmarks = {}, hiddenSpecies = {}, movingMapSecs = {}, glowMapping = {}}}
  for _, g in ipairs(graphics) do
    local data = g[3] and c:lz(g[2]) or c:raw(g[2])
    man.gfx[g[1]] = {path = c:write(g[1] .. ".gfx", data), bytes = #data}
  end
  local noBall = c:lz("pokedex.o:gUnknown_0839FA7C")
  assert(#noBall == 128, "RS number/caught-ball tiles must contain four native tiles")
  for i, key in ipairs({"number", "caught_ball"}) do
    man.gfx[key] = {path = c:write(key .. ".gfx", noBall:sub((i - 1) * 64 + 1, i * 64)), bytes = 64}
  end
  local cm = c:raw("gCryMeter_Tilemap")
  assert(#cm == 160, "RS cry meter map must be 10 by 8")
  man.maps.cry_meter = {path = c:write("cry_meter.map", cm), entries = 80}
  local palSymbols = {messageBox = "gFontDefaultPalette", areaMap = "sRegionMapBkgnd_Pal",
    areaGlow = "gUnknown_083F8418", areaMarker = "AreaMarkerPalette", areaUnknown = "gAreaUnknownPalette",
    cryMeter = "gCryMeter_Pal", cryNeedle = "CryMeterNeedlePalette", cryBg = "sCryScreenBg_Pal",
    silhouette = "pokedex.o:sSizeScreenSilhouette_Pal", registrationFlash = "gPokedexMenu2_Pal"}
  for key, symbol in pairs(palSymbols) do
    local n = key == "areaMap" and 48 or 16
    man.palettes[key] = K.palList(c:pal(symbol, n), 0, n)
  end
  local mapPal = c:pal("sRegionMapBkgnd_Pal", 48, {}, 112)
  local map, w, h = K.bakeAffine(c:lz("sRegionMapBkgnd_ImageLZ"), c:lz("sRegionMapBkgnd_TilemapLZ"), 64)
  man.areaMap = {png = c:png("area_map.png", w, h, map, mapPal, false), w = w, h = h}
  local base = (opts.cacheRoot or "data/generated/gba") .. "/rse/pokedex/"
  man.maps.search_hoenn, man.maps.search_national = {path = base .. "search.map", entries = 1024}, {path = base .. "search.map", entries = 1024}
  man.palettes.searchMenu = K.palList(c:pal("gPokedexMenuSearch_Pal", 64), 0, 64)
  local bo, no = c:off("gBaseStats"), c:off("gSpeciesNames")
  for sp = 0, c.S.count("gBaseStats", 28) - 1 do
    man.bodyColor[sp] = c:u8(bo + sp * 28 + 25) % 128
    man.speciesTypes[sp] = {c:u8(bo + sp * 28 + 6), c:u8(bo + sp * 28 + 7)}
    man.speciesFirstChar[sp] = c:u8(no + sp * 11)
  end
  local so = c:off("gSineTable")
  for i = 0, c.S.count("gSineTable", 2) - 1 do man.sine[i] = c:s16(so + i * 2) end
  for _, key in ipairs({"UnknownPoke", "UnknownHeight", "UnknownWeight", "CryOf", "SizeComparedTo", "RegisterComplete", "Searching", "SearchComplete", "NoMatching", "RightPointingTriangle"}) do
    man.strings[key] = A.text(c, c:off(key == "RightPointingTriangle" and "DexText_RightPointingTriangle" or "gDexText_" .. key))
  end
  man.strings.UnknownHeight = string.char(0xFC, 0x13, 12) .. man.strings.UnknownHeight
  man.strings.CryOf = string.char(0xFC, 0x13, 2) .. man.strings.CryOf
  for key, name in pairs({list = "gWindowTemplate_81E7048", info = "gWindowTemplate_81E7064", cry = "gWindowTemplate_81E702C"}) do
    local o, row = c:off(name), {}
    for i = 0, 27 do row[i + 1] = c:u8(o + i) end
    man.windows[key] = {nativeBytes = row, paletteNum = row[5], foreground = row[6], background = row[7], shadow = row[8], font = row[9]}
  end
  for name, stride in pairs({sFeebasData = 6, sLandmarkData = 4, sSpeciesHiddenFromAreaScreen = 2}) do
    local target = name == "sFeebasData" and man.area.feebas or name == "sLandmarkData" and man.area.landmarks or man.area.hiddenSpecies
    local o = c:off(name)
    for i = 0, c.S.count(name, stride) - 1 do
      if stride == 2 then target[#target + 1] = c:u16(o + i * stride)
      else
        local row = {}; for j = 0, stride / 2 - 1 do row[j + 1] = c:u16(o + i * stride + j * 2) end
        target[#target + 1] = row
      end
    end
  end
  for v = 0, 255 do man.area.glowMapping[v + 1] = glowTile(v) end
  man.area.roamerSpecies = require("src.core.game3.constants").of(rom.id):require("species", rom.id == "ruby" and "SPECIES_LATIOS" or "SPECIES_LATIAS")
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
