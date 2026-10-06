local K = require("src.import.gba.rse.boot_gfx")
local TextIR = require("src.core.game3.scripting.text_ir")

local M = {}

M.SUB = "rse/region_map"
M.FILES = {
  "map.png", "frame.png", "cursor_small.png", "brendan_icon.png", "may_icon.png", "fly_icons.png",
}
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/src/region_map.c:41
M.MAP_WIDTH = 28
M.MAP_HEIGHT = 15

-- pokeemerald/src/region_map.c:486
M.FLY_ICON_FRAMES = {
  { tile = 0, w = 8, h = 8 }, { tile = 1, w = 16, h = 8 }, { tile = 3, w = 8, h = 16 },
  { tile = 5, w = 8, h = 8 }, { tile = 6, w = 16, h = 8 }, { tile = 8, w = 8, h = 16 },
  { tile = 10, w = 16, h = 16 },
}

local function readString(c, off, maxLen)
  local bytes = {}
  for i = 0, (maxLen or 64) - 1 do
    local b = c:u8(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = "rse" }), {})
end

local function u8list(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

-- pokeemerald/include/global.fieldmap.h:171
local function mapsecOfMap(c, mapName)
  local C = require("src.core.game3.constants").of(c.game)
  local m = assert(C:map(mapName), "region map: no map constant " .. mapName)
  local groups = c:off("gMapGroups")
  local group = assert(c:ptr(groups + m.group * 4), "region map: bad map group pointer")
  local header = assert(c:ptr(group + m.num * 4), "region map: bad map header pointer")
  return c:u8(header + 0x14)
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/region_map.c:567
  local mapPal = c:palAt(c:off("sRegionMapBg_Pal"), 48, {}, 112)
  local mapIdx = K.bakeAffine(c:lz("sRegionMapBg_GfxLZ"), c:lz("sRegionMapBg_TilemapLZ"), 64)
  c:png("map.png", 512, 512, mapIdx, mapPal, false)

  -- pokeemerald/src/region_map.c:1702
  local framePal = c:pal("sRegionMapFramePal", 16, {}, 16)
  local frameIdx = K.bakeText(c:lz("sRegionMapFrameGfxLZ"), c:lz("sRegionMapFrameTilemapLZ"), 32, 32)
  c:png("frame.png", 256, 256, frameIdx, framePal, true)

  local cursorPal = c:pal("sRegionMapCursorPal", 16)
  local cursor = c:strip("cursor_small", c:lz("sRegionMapCursorSmallGfxLZ"), 16, 16, 2, cursorPal, 4)

  local icons = {}
  for _, who in ipairs({ { "brendan", "sRegionMapPlayerIcon_BrendanGfx", "sRegionMapPlayerIcon_BrendanPal" },
      { "may", "sRegionMapPlayerIcon_MayGfx", "sRegionMapPlayerIcon_MayPal" } }) do
    icons[who[1]] = c:strip(who[1] .. "_icon", c:raw(who[2]), 16, 16, 1, c:pal(who[3], 16), 4)
  end

  -- pokeemerald/src/region_map.c:1821
  local flyIcons = c:atlas("fly_icons", c:lz("sFlyTargetIcons_Gfx"), M.FLY_ICON_FRAMES, c:pal("sFlyTargetIcons_Pal", 16))

  -- pokeemerald/src/data/region_map/region_map_layout.h:1
  local layout, lo = {}, c:off("sRegionMap_MapSectionLayout")
  for y = 0, M.MAP_HEIGHT - 1 do
    local row = {}
    for x = 0, M.MAP_WIDTH - 1 do row[x + 1] = c:u8(lo + y * M.MAP_WIDTH + x) end
    layout[y + 1] = row
  end

  -- pokeemerald/src/region_map.c:289
  local heal, ho = {}, c:off("sMapHealLocations")
  for sec = 0, c.S.size("sMapHealLocations") / 3 - 1 do
    heal[sec + 1] = { mapGroup = c:u8(ho + sec * 3), mapNum = c:u8(ho + sec * 3 + 1), healLocation = c:u8(ho + sec * 3 + 2) }
  end

  -- pokeemerald/src/region_map.c:133
  local special, so = {}, c:off("sRegionMap_SpecialPlaceLocations")
  for i = 0, c.S.size("sRegionMap_SpecialPlaceLocations") / 4 - 1 do
    special[i + 1] = { c:u16(so + i * 4), c:u16(so + i * 4 + 2) }
  end

  -- pokeemerald/src/region_map.c:349
  local multi, mo = {}, c:off("sMultiNameFlyDestinations")
  for i = 0, c.S.size("sMultiNameFlyDestinations") / 8 - 1 do
    local namesOff = c:ptr(mo + i * 8)
    local names = {}
    for j = 0, 1 do names[j + 1] = readString(c, c:ptr(namesOff + j * 4)) end
    multi[i + 1] = { names = names, mapSecId = c:u16(mo + i * 8 + 4), flag = c:u16(mo + i * 8 + 6) }
  end

  -- pokeemerald/src/region_map.c:424
  local red, ro = {}, c:off("sRedOutlineFlyDestinations")
  for i = 0, c.S.size("sRedOutlineFlyDestinations") / 4 - 1 do
    red[i + 1] = { flag = c:u16(ro + i * 4), mapSecId = c:u16(ro + i * 4 + 2) }
  end

  -- pokeemerald/src/region_map.c:194
  local marine, mco = {}, c:off("sMarineCaveLocationCoords")
  for i = 0, c.S.size("sMarineCaveLocationCoords") / 4 - 1 do
    marine[i + 1] = { x = c:u16(mco + i * 4), y = c:u16(mco + i * 4 + 2) }
  end
  local function u16list(name)
    local off, out = c:off(name), {}
    for i = 0, c.S.size(name) / 2 - 1 do out[i + 1] = c:u16(off + i * 2) end
    return out
  end

  local entries = c.S.size("gRegionMapEntries") / 8
  return true, c:finish({
    screen = "region_map",
    width = M.MAP_WIDTH,
    height = M.MAP_HEIGHT,
    layers = {
      map = { png = c:path("map.png"), w = 512, h = 512 },
      frame = { png = c:path("frame.png"), w = 256, h = 256 },
    },
    sprites = { cursor = cursor, brendan = icons.brendan, may = icons.may, flyIcons = flyIcons },
    layout = layout,
    heal = heal,
    specialPlaces = special,
    multiNameFlyDestinations = multi,
    redOutlineFlyDestinations = red,
    offMap = u8list(c, "sMapSecIdsOffMap"),
    aquaHideoutOld = u8list(c, "sMapSecAquaHideoutOld"),
    marineCaveCoords = marine,
    marineCaveMapSecIds = u16list("sMarineCaveMapSecIds"),
    terraOrMarineCaveMapSecIds = u16list("sTerraOrMarineCaveMapSecIds"),
    mapsecs = {
      NONE = entries,
      LITTLEROOT_TOWN = mapsecOfMap(c, "MAP_LITTLEROOT_TOWN"),
      EVER_GRANDE_CITY = mapsecOfMap(c, "MAP_EVER_GRANDE_CITY"),
      BATTLE_FRONTIER = mapsecOfMap(c, "MAP_BATTLE_FRONTIER_OUTSIDE_EAST"),
      SOUTHERN_ISLAND = mapsecOfMap(c, "MAP_SOUTHERN_ISLAND_EXTERIOR"),
      ROUTE_114 = mapsecOfMap(c, "MAP_ROUTE114"),
      ROUTE_121 = mapsecOfMap(c, "MAP_ROUTE121"),
      ROUTE_126 = mapsecOfMap(c, "MAP_ROUTE126"),
      UNDERWATER_126 = mapsecOfMap(c, "MAP_UNDERWATER_ROUTE126"),
      SECRET_BASE = mapsecOfMap(c, "MAP_SECRET_BASE_RED_CAVE1"),
      DYNAMIC = mapsecOfMap(c, "MAP_BATTLE_COLOSSEUM_2P"),
      UNDERWATER_SEAFLOOR_CAVERN = mapsecOfMap(c, "MAP_UNDERWATER_SEAFLOOR_CAVERN"),
      UNDERWATER_MARINE_CAVE = mapsecOfMap(c, "MAP_UNDERWATER_MARINE_CAVE"),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
