local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local V = require("src.import.gba.versions")
local M = {SUB = "rse/region_map", FILES = {"map.png", "frame.png", "cursor_small.png", "cursor_large.png", "brendan_icon.png", "may_icon.png", "fly_icons.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)
M.REQUIRED[#M.REQUIRED + 1] = "region_map/map_sections.lua"
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/region_map.c:141
  local mapPal = c:pal("sRegionMapBkgnd_Pal", 48, {}, 112)
  local idx = K.bakeAffine(c:lz("sRegionMapBkgnd_ImageLZ"), c:lz("sRegionMapBkgnd_TilemapLZ"), 64)
  local map = c:png("map.png", 512, 512, idx, mapPal, false)
  local framePal = c:pal("sFlyRegionMapFrame_Pal", 16, {}, 16)
  local fi, fw, fh = K.bakeText(c:lz("sFlyRegionMapFrame_ImageLZ"), c:lz("sFlyRegionMapFrame_TilemapLZ"), 32, 32)
  local frame = c:png("frame.png", fw, fh, fi, framePal, true)
  local cursorPal = c:pal("sRegionMapCursor_Pal", 16)
  local cursors = {small = c:strip("cursor_small", c:lz("sRegionMapCursorSmall_ImageLZ"), 16, 16, 2, cursorPal),
    large = c:strip("cursor_large", c:lz("sRegionMapCursorLarge_ImageLZ"), 32, 32, 3, cursorPal)}
  local icons = {}
  for _, row in ipairs({{"brendan", "sRegionMapBrendanIcon"}, {"may", "sRegionMapMayIcon"}}) do
    icons[row[1]] = c:strip(row[1] .. "_icon", c:raw(row[2] .. "_Image"), 16, 16, 1, c:pal(row[2] .. "_Pal", 16))
  end
  local flyFrames = { {tile = 0, w = 8, h = 8}, {tile = 1, w = 16, h = 8}, {tile = 3, w = 8, h = 16},
    {tile = 5, w = 8, h = 8}, {tile = 6, w = 16, h = 8}, {tile = 8, w = 8, h = 16}, {tile = 10, w = 16, h = 16} }
  local fly = c:atlas("fly_icons", c:lz("sFlyTargetIcons_ImageLZ"), flyFrames, c:pal("sFlyTargetIcons_Pal", 16))
  local layout, lo = {}, c:off("sRegionMapLayout")
  for y = 0, 14 do
    layout[y + 1] = {}; for x = 0, 27 do layout[y + 1][x + 1] = c:u8(lo + y * 28 + x) end
  end
  local sections, C = {}, require("src.core.game3.constants").of(rom.id)
  for sec = 0, V.REGION_MAP_ENTRY_COUNT - 1 do
    local o = V.REGION_MAP_ENTRIES + sec * 8
    sections[sec] = { id = C:name("region_map_sections", sec, "MAPSEC_"), name = A.text(c, c:ptr(o + 4)),
      x = c:u8(o), y = c:u8(o + 1), width = c:u8(o + 2), height = c:u8(o + 3) }
  end
  local heal, ho = {}, c:off("sMapHealLocations")
  for i = 0, c.S.count("sMapHealLocations", 3) - 1 do
    local b = ho + i * 3
    heal[i + 1] = {mapGroup = c:u8(b), mapNum = c:u8(b + 1), healLocation = c:u8(b + 2)}
  end
  local special, so = {}, c:off("sUnderwaterMaps")
  for i = 0, c.S.count("sUnderwaterMaps", 4) - 1 do
    special[i + 1] = {c:u16(so + i * 4), c:u16(so + i * 4 + 2)}
  end
  local multi, mo = {}, c:off("sMultiPartMapSections")
  for i = 0, c.S.count("sMultiPartMapSections", 8) - 1 do
    local b, names = mo + i * 8, {}
    local p = c:ptr(b)
    for j = 0, 1 do names[j + 1] = A.text(c, c:ptr(p + j * 4)) end
    multi[i + 1] = {names = names, mapSecId = c:u16(b + 4), flag = c:u16(b + 6)}
  end
  local red, ro = {}, c:off("sSpecialFlyAreas")
  for i = 0, c.S.count("sSpecialFlyAreas", 4) - 1 do
    red[i + 1] = {flag = c:u16(ro + i * 4), mapSecId = c:u16(ro + i * 4 + 2)}
  end
  local mapsecs = {}
  for name, id in pairs(C.region_map_sections.byName) do
    if name:sub(1, 7) == "MAPSEC_" then mapsecs[name:sub(8)] = id end
  end
  local secPath = (opts and opts.cacheRoot or "data/generated/gba") .. "/region_map/map_sections.lua"
  assert(cache:write(secPath, require("src.import.LuaWriter").encode({format_version = 1, layout = "rs", build = V.BUILD,
    count = V.REGION_MAP_ENTRY_COUNT, sections = sections, popup = {frameStyle = 0, left = 0, top = 0, right = 13, bottom = 3}})))
  return A.finish(c, {screen = "region_map", map = map, frame = frame, cursor = cursors.small, cursors = cursors,
    icons = icons, flyIcons = fly, layout = layout, sections = sections, mapWidth = 28, mapHeight = 15,
    width = 28, height = 15, layers = {map = {png = map, w = 512, h = 512}, frame = {png = frame, w = 256, h = 256}},
    sprites = {cursor = cursors.small, cursorLarge = cursors.large, brendan = icons.brendan, may = icons.may, flyIcons = fly},
    heal = heal, specialPlaces = special, multiNameFlyDestinations = multi, redOutlineFlyDestinations = red,
    mapsecs = mapsecs,
    palettes = {map = K.palList(mapPal, 112, 48), frame = K.palList(framePal, 16, 16)}})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
