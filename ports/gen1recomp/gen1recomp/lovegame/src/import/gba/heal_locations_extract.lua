-- pokefirered/src/heal_location.c:28, pokefirered/src/region_map.c:828

local Versions = require("src.import.gba.versions")
local MapCatalog = require("src.import.gba.map_catalog")
local MapSectionsExtract = require("src.import.gba.map_sections_extract")
local GameVersion = require("src.core.GameVersion")
local Constants = require("src.core.game3.constants")

local HealLocationsExtract = {}

HealLocationsExtract.CACHE_SUB = "region_map"
HealLocationsExtract.FORMAT_VERSION = 1

HealLocationsExtract.FILES = {
  "heal_locations.lua",
  "fly_destinations.lua",
}

HealLocationsExtract.REQUIRED = {
  "region_map/heal_locations.lua",
  "region_map/fly_destinations.lua",
}

HealLocationsExtract.HEAL_STRIDE = 8
HealLocationsExtract.RESPAWN_STRIDE = 4
HealLocationsExtract.FLY_STRIDE = 3

-- pokefirered/src/heal_location.c:89
local RESPAWN_TILE = {
  FR_PLAYERS_HOUSE_1F = { x = 8, y = 5 },
  FR_INDIGO_PLATEAU_POKEMON_CENTER_1F = { x = 13, y = 12 },
  SEVII_ONE_ISLAND_POKECENTER = { x = 5, y = 4 },
  FR_TRAINER_TOWER_LOBBY = { x = 4, y = 11 },
}

-- pokefirered/src/heal_location.c:110
local RESPAWN_TILE_DEFAULT = { x = 7, y = 4 }

HealLocationsExtract.RESPAWN_TILE = RESPAWN_TILE
HealLocationsExtract.RESPAWN_TILE_DEFAULT = RESPAWN_TILE_DEFAULT

local function default_cache_root()
  local ok, Extract = pcall(require, "src.import.gba.extract_island1")
  if ok and Extract and Extract.CACHE_ROOT then
    return Extract.CACHE_ROOT
  end
  return "data/generated/gba"
end

local function s16(v)
  v = v % 65536
  if v >= 32768 then return v - 65536 end
  return v
end

function HealLocationsExtract.build(rom, opts)
  opts = opts or {}
  if not (rom and rom.get) then return nil, "missing ROM handle" end
  MapCatalog.rebuildIndex()

  local healBase = opts.healBase or Versions.S_HEAL_LOCATIONS
  local respawnBase = opts.respawnBase or Versions.S_WHITEOUT_RESPAWN_MAP_IDXS
  local npcBase = opts.npcBase or Versions.S_WHITEOUT_RESPAWN_HEALER_NPC_IDS
  local flyBase = opts.flyBase or Versions.S_MAP_FLY_DESTINATIONS
  local healCount = opts.healCount or Versions.NUM_HEAL_LOCATIONS
  local flyCount = opts.flyCount or Versions.NUM_MAP_FLY_DESTINATIONS
  local firstSec = MapSectionsExtract.KANTO_MAPSEC_START
  if not (healBase and respawnBase and npcBase and flyBase and healCount and flyCount) then
    return nil, "heal location table addresses are not pinned for this ROM"
  end

  local heal, fly = {}, {}
  for i = 0, healCount - 1 do
    local o = healBase + i * HealLocationsExtract.HEAL_STRIDE
    local flyMap = MapCatalog.mapIdFor(rom:get(o), rom:get(o + 1))
    if not flyMap then
      return nil, ("sHealLocations[%d] map %d:%d is not a known map")
        :format(i, rom:get(o), rom:get(o + 1))
    end
    local ro = respawnBase + i * HealLocationsExtract.RESPAWN_STRIDE
    local respawnMap = MapCatalog.mapIdFor(rom:u16(ro), rom:u16(ro + 2))
    if not respawnMap then
      return nil, ("sWhiteoutRespawnHealCenterMapIdxs[%d] map %d:%d is not a known map")
        :format(i, rom:u16(ro), rom:u16(ro + 2))
    end
    local tile = RESPAWN_TILE[respawnMap] or RESPAWN_TILE_DEFAULT
    heal[i + 1] = {
      id = i + 1,
      map = respawnMap,
      x = tile.x,
      y = tile.y,
      healerLocalId = rom:get(npcBase + i),
      flyMap = flyMap,
      flyX = s16(rom:u16(o + 2)),
      flyY = s16(rom:u16(o + 4)),
    }
  end

  for i = 0, flyCount - 1 do
    local o = flyBase + i * HealLocationsExtract.FLY_STRIDE
    local healId = rom:get(o + 2)
    if healId ~= 0 then
      local row = heal[healId]
      if not row then
        return nil, ("sMapFlyDestinations[%d] names heal location %d"):format(i, healId)
      end
      local sec = firstSec + i
      local info = MapSectionsExtract.SECTIONS[sec]
      if not (info and info.id) then
        return nil, ("mapsec %d has no symbolic id"):format(sec)
      end
      local mapId = MapCatalog.mapIdFor(rom:get(o), rom:get(o + 1))
      if mapId ~= row.flyMap then
        return nil, ("mapsec %d flies to %s but heal location %d is %s")
          :format(sec, tostring(mapId), healId, tostring(row.flyMap))
      end
      fly[#fly + 1] = {
        mapsec = sec,
        id = info.id,
        map = row.flyMap,
        x = row.flyX,
        y = row.flyY,
        healLocation = healId,
      }
    end
  end

  if #fly == 0 then return nil, "no Fly destination names a heal location" end

  return { heal = heal, fly = fly }
end

local function constantName(kind, id, prefix)
  local C = Constants.of(GameVersion.get())
  if not C[kind] then return nil end
  return C:name(kind, id, prefix)
end

local function s8(v)
  if v >= 128 then return v - 256 end
  return v
end

-- pokeemerald/src/data/heal_locations.h:6, pokeemerald/src/region_map.c:1981
function HealLocationsExtract.buildHealRow(rom, opts)
  opts = opts or {}
  if not (rom and rom.get) then return nil, "missing ROM handle" end
  MapCatalog.rebuildIndex()
  local healBase = opts.healBase or Versions.S_HEAL_LOCATIONS
  local healCount = opts.healCount or Versions.NUM_HEAL_LOCATIONS
  local secBase = opts.mapHealBase or Versions.MAP_HEAL_LOCATIONS
  local secCount = opts.mapHealCount or Versions.MAP_HEAL_LOCATION_COUNT

  local heal = {}
  for i = 0, healCount - 1 do
    local o = healBase + i * HealLocationsExtract.HEAL_STRIDE
    local g, n = s8(rom:get(o)), s8(rom:get(o + 1))
    local map = MapCatalog.mapIdFor(g, n)
    if not map then
      return nil, ("sHealLocations[%d] map %d:%d is not a known map"):format(i, g, n)
    end
    heal[i + 1] = {
      id = i + 1,
      name = constantName("heal_locations", i + 1, "HEAL_LOCATION_"),
      map = map,
      x = rom:u16(o + 2),
      y = rom:u16(o + 4),
    }
  end

  local fly, warps = {}, {}
  for sec = 0, secCount - 1 do
    local o = secBase + sec * HealLocationsExtract.FLY_STRIDE
    local healId = rom:get(o + 2)
    local townMap = MapCatalog.mapIdFor(rom:get(o), rom:get(o + 1))
    if not townMap then
      return nil, ("sMapHealLocations[%d] map %d:%d is not a known map")
        :format(sec, rom:get(o), rom:get(o + 1))
    end
    local id = constantName("region_map_sections", sec, "MAPSEC_")
    if healId ~= 0 then
      local row = heal[healId]
      if not row then
        return nil, ("sMapHealLocations[%d] names heal location %d"):format(sec, healId)
      end
      fly[#fly + 1] = {
        mapsec = sec, id = id, map = row.map, x = row.x, y = row.y,
        healLocation = healId, townMap = townMap,
      }
    else
      warps[#warps + 1] = { mapsec = sec, id = id, map = townMap }
    end
  end
  if #fly == 0 then return nil, "no mapsec names a heal location" end

  return { model = "heal_row", heal = heal, fly = fly, mapWarps = warps }
end

local function formatHealRow(plan)
  local lines = {
    "-- Generated heal locations (sHealLocations). Sourced from pret/pokeemerald",
    "-- src/data/heal_locations.h.",
    "local heal = {",
  }
  for _, row in ipairs(plan.heal) do
    local name = row.name and (", name = %q"):format(row.name) or ""
    lines[#lines + 1] = ("  [%d] = { map = %q, x = %d, y = %d%s },")
      :format(row.id, row.map, row.x, row.y, name)
  end
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "return {"
  lines[#lines + 1] = ("  version = %d,"):format(HealLocationsExtract.FORMAT_VERSION)
  lines[#lines + 1] = ("  model = %q,"):format(plan.model)
  lines[#lines + 1] = "  whiteout = heal,"
  lines[#lines + 1] = "  heal_locations = heal,"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

local function secKey(row)
  if row.id then return row.id end
  return ("[%d]"):format(row.mapsec)
end

local function formatFlyHealRow(plan)
  local lines = {
    "-- Generated Fly destinations (sMapHealLocations resolved through",
    "-- sHealLocations). Sourced from pret/pokeemerald src/region_map.c.",
    "return {",
    ("  version = %d,"):format(HealLocationsExtract.FORMAT_VERSION),
    ("  model = %q,"):format(plan.model),
    "  fly_destinations = {",
  }
  for _, row in ipairs(plan.fly) do
    lines[#lines + 1] = ("    %s = { mapsec = %d, map = %q, x = %d, y = %d, healLocation = %d, townMap = %q },")
      :format(secKey(row), row.mapsec, row.map, row.x, row.y, row.healLocation, row.townMap)
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  map_warps = {"
  for _, row in ipairs(plan.mapWarps) do
    lines[#lines + 1] = ("    %s = { mapsec = %d, map = %q },"):format(secKey(row), row.mapsec, row.map)
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

HealLocationsExtract.formatHealRow = formatHealRow
HealLocationsExtract.formatFlyHealRow = formatFlyHealRow

local function formatHealLocations(plan)
  local lines = {
    "-- Generated whiteout respawn points (sWhiteoutRespawnHealCenterMapIdxs,",
    "-- sWhiteoutRespawnHealerNpcIds). Sourced from pret/pokefirered",
    "-- src/heal_location.c SetWhiteoutRespawnWarpAndHealerNpc.",
    "local whiteout = {",
  }
  for _, row in ipairs(plan.heal) do
    lines[#lines + 1] = ("  [%d] = { map = %q, x = %d, y = %d, healerLocalId = %d },")
      :format(row.id, row.map, row.x, row.y, row.healerLocalId)
  end
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  lines[#lines + 1] = "return {"
  lines[#lines + 1] = ("  version = %d,"):format(HealLocationsExtract.FORMAT_VERSION)
  lines[#lines + 1] = "  whiteout = whiteout,"
  lines[#lines + 1] = "  heal_locations = whiteout,"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

local function formatFlyDestinations(plan)
  local lines = {
    "-- Generated Fly destinations (sMapFlyDestinations resolved through",
    "-- sHealLocations). Sourced from pret/pokefirered src/region_map.c",
    "-- SetFlyWarpDestination and src/heal_location.c.",
    "return {",
    ("  version = %d,"):format(HealLocationsExtract.FORMAT_VERSION),
    "  fly_destinations = {",
  }
  for _, row in ipairs(plan.fly) do
    lines[#lines + 1] = ("    %s = { mapsec = %d, map = %q, x = %d, y = %d, healLocation = %d },")
      :format(row.id, row.mapsec, row.map, row.x, row.y, row.healLocation)
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

HealLocationsExtract.formatHealLocations = formatHealLocations
HealLocationsExtract.formatFlyDestinations = formatFlyDestinations

local function baked(cache, rel)
  if cache and cache.exists then return cache:exists(rel) and true or false end
  if cache and cache.read then
    local d = cache:read(rel)
    return (type(d) == "string" and #d > 8)
  end
  return false
end

function HealLocationsExtract.ready(cache, cacheRoot)
  local root = (cacheRoot or default_cache_root()) .. "/" .. HealLocationsExtract.CACHE_SUB
  for _, name in ipairs(HealLocationsExtract.FILES) do
    if not baked(cache, root .. "/" .. name) then return false end
  end
  return true
end

function HealLocationsExtract.run(rom, cache, opts)
  opts = opts or {}
  local cacheRoot = opts.cacheRoot or default_cache_root()
  local root = cacheRoot .. "/" .. HealLocationsExtract.CACHE_SUB
  if not (cache and cache.write) then return false, "missing cache handle" end
  if not opts.force and HealLocationsExtract.ready(cache, cacheRoot) then
    return true, { skipped = true }
  end

  local healRow = Versions.MAP_HEAL_LOCATIONS ~= nil
  local plan, err
  if healRow then
    plan, err = HealLocationsExtract.buildHealRow(rom, opts)
  else
    plan, err = HealLocationsExtract.build(rom, opts)
  end
  if not plan then
    if opts.strict then error("heal_locations: " .. tostring(err)) end
    return false, err
  end

  if healRow then
    cache:write(root .. "/heal_locations.lua", formatHealRow(plan))
    cache:write(root .. "/fly_destinations.lua", formatFlyHealRow(plan))
  else
    cache:write(root .. "/heal_locations.lua", formatHealLocations(plan))
    cache:write(root .. "/fly_destinations.lua", formatFlyDestinations(plan))
  end

  print(("[heal_locations] %d respawn points + %d Fly destinations -> %s")
    :format(#plan.heal, #plan.fly, root))

  return true, { healLocations = #plan.heal, flyDestinations = #plan.fly }
end

return HealLocationsExtract
