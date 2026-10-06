-- Extract FRLG wild encounter tables from ROM (gWildMonHeaders).
-- FireRed USA 1.0: pret wild_encounter.h layout — not curated JSON.

local Versions = require("src.import.gba.versions")
local GameVersion = require("src.core.GameVersion")
local Profile = require("src.core.game3.profile")
local Family = require("src.import.gba.family")

local EncountersExtract = {}

EncountersExtract.FORMAT_VERSION = 2

local function log(msg)
  print("[gba/encounters] " .. tostring(msg))
end

local function gba_off(ptr)
  return Versions.gbaToFile(ptr)
end

local function read_info(rom, infoOff, slotCount)
  if not infoOff then return nil end
  local rate = rom:get(infoOff)
  local monsPtr = rom:u32(infoOff + 4)
  local monsOff = gba_off(monsPtr)
  if not monsOff then return nil end
  local slots = {}
  for i = 0, slotCount - 1 do
    local base = monsOff + i * 4
    local minLevel = rom:get(base)
    local maxLevel = rom:get(base + 1)
    local species = rom:u16(base + 2)
    slots[#slots + 1] = {
      species = species,
      minLevel = minLevel,
      maxLevel = maxLevel,
    }
  end
  return { rate = rate, slots = slots }
end

local function serialize_area(lines, name, area)
  if not area or not area.slots or #area.slots == 0 then return end
  lines[#lines + 1] = string.format("    %s = {\n", name)
  lines[#lines + 1] = string.format("      rate = %d,\n", area.rate or 0)
  lines[#lines + 1] = "      slots = {\n"
  for _, s in ipairs(area.slots) do
    lines[#lines + 1] = string.format(
      "        { species = %d, minLevel = %d, maxLevel = %d },\n",
      s.species or 0, s.minLevel or 1, s.maxLevel or s.minLevel or 1)
  end
  lines[#lines + 1] = "      },\n"
  lines[#lines + 1] = "    },\n"
end

local function serialize_areas(lines, entry)
  serialize_area(lines, "land", entry.land)
  serialize_area(lines, "water", entry.water)
  serialize_area(lines, "rocks", entry.rocks)
  serialize_area(lines, "fishing", entry.fishing)
end

local function serialize_entry(lines, key, entry)
  lines[#lines + 1] = string.format("  [%q] = {\n", key)
  lines[#lines + 1] = string.format("    mapGroup = %d,\n", entry.mapGroup or 0)
  lines[#lines + 1] = string.format("    mapNum = %d,\n", entry.mapNum or 0)
  serialize_areas(lines, entry)
  if entry.variants then
    lines[#lines + 1] = "    variants = {\n"
    for _, v in ipairs(entry.variants) do
      lines[#lines + 1] = "      {\n"
      serialize_areas(lines, v)
      lines[#lines + 1] = "      },\n"
    end
    lines[#lines + 1] = "    },\n"
  end
  lines[#lines + 1] = "  },\n"
end

--- Parse gWildMonHeaders from an open Rom handle.
-- @return list of { mapGroup, mapNum, land, water, rocks, fishing }
function EncountersExtract.parseRom(rom, version)
  version = version or {}
  local headersOff = version.wild_mon_headers or Versions.WILD_MON_HEADERS
  return EncountersExtract.parseHeaders(rom, headersOff, version, 512)
end

function EncountersExtract.parseHeaders(rom, headersOff, version, limit)
  version = version or {}
  local hdrSize = version.wild_mon_header_size or Versions.WILD_MON_HEADER_SIZE
  local landN = version.land_wild_count or Versions.LAND_WILD_COUNT
  local waterN = version.water_wild_count or Versions.WATER_WILD_COUNT
  local rockN = version.rock_wild_count or Versions.ROCK_WILD_COUNT
  local fishN = version.fish_wild_count or Versions.FISH_WILD_COUNT

  local out = {}
  local off = headersOff
  local guard = 0
  while guard < limit do
    guard = guard + 1
    local mapGroup = rom:get(off)
    local mapNum = rom:get(off + 1)
    if mapGroup == 0xFF and mapNum == 0xFF then
      break
    end
    local landPtr = rom:u32(off + 4)
    local waterPtr = rom:u32(off + 8)
    local rockPtr = rom:u32(off + 12)
    local fishPtr = rom:u32(off + 16)
    local entry = {
      mapGroup = mapGroup,
      mapNum = mapNum,
      land = read_info(rom, gba_off(landPtr), landN),
      water = read_info(rom, gba_off(waterPtr), waterN),
      rocks = read_info(rom, gba_off(rockPtr), rockN),
      fishing = read_info(rom, gba_off(fishPtr), fishN),
    }
    out[#out + 1] = entry
    off = off + hdrSize
  end
  return out
end

local function map_prefixes()
  local map = Profile.of(GameVersion.get()).map
  return map.prefixes or {}, map.enginePrefix
end

local function add_aliases(tables, alias, packed, prefixes, enginePrefix)
  tables[alias] = packed
  for _, prefix in ipairs(prefixes) do
    if alias:sub(1, #prefix) == prefix then
      local bare = alias:sub(#prefix + 1)
      tables[bare] = packed
      local routeNum = prefix == enginePrefix and bare:match("^ROUTE_(%d+)$")
      if routeNum then
        tables["ROUTE" .. routeNum] = packed
        tables[enginePrefix .. "ROUTE" .. routeNum] = packed
      end
      return
    end
  end
end

local function is_alias(key, prefixes)
  for _, prefix in ipairs(prefixes) do
    if key:sub(1, #prefix) == prefix then return true end
  end
  return false
end

local function build_tables(entries)
  local tables = {}
  local prefixes, enginePrefix = map_prefixes()
  for _, e in ipairs(entries) do
    local gn = string.format("%d:%d", e.mapGroup, e.mapNum)
    local packed = {
      mapGroup = e.mapGroup,
      mapNum = e.mapNum,
      land = e.land,
      water = e.water,
      rocks = e.rocks,
      fishing = e.fishing,
    }
    local first = tables[gn]
    if first then
      -- pokefirered/src/wild_encounter.c:189
      first.variants = first.variants or { {
        land = first.land, water = first.water, rocks = first.rocks, fishing = first.fishing,
      } }
      first.variants[#first.variants + 1] = packed
      goto continue
    end
    tables[gn] = packed
    local alias = Versions.mapIdFor(e.mapGroup, e.mapNum)
    if alias then
      add_aliases(tables, alias, packed, prefixes, enginePrefix)
    end
    ::continue::
  end
  return tables
end

local function source_label()
  local F = Family.active()
  if F.aliases then return "FireRed" end
  return Profile.of(F.game).label
end

local function encode_lua(tables, headerCount)
  local lines = {
    "-- Auto-extracted from ROM gWildMonHeaders (" .. source_label() .. ").\n",
    string.format("-- format_version=%d headers=%d\n", EncountersExtract.FORMAT_VERSION, headerCount),
    "return {\n",
  }
  local keys = {}
  for k in pairs(tables) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    -- Prefer FR_/SEVII_ aliases after numeric keys for stable diffs.
    local an, bn = a:match("^(%d+):"), b:match("^(%d+):")
    if an and not bn then return true end
    if bn and not an then return false end
    return a < b
  end)
  for _, k in ipairs(keys) do
    serialize_entry(lines, k, tables[k])
  end
  lines[#lines + 1] = "}\n"
  return table.concat(lines)
end

--- Write data/generated/gba/encounters.lua from ROM.
function EncountersExtract.writeExtract(rom, cache, root, version)
  root = root or "data/generated/gba"
  if not rom or not cache then
    return nil, "rom and cache required"
  end
  local entries = EncountersExtract.parseRom(rom, version)
  local tables = build_tables(entries)
  local blob = encode_lua(tables, #entries)
  cache:write(root .. "/encounters.lua", blob)

  local aliased = 0
  local prefixes = map_prefixes()
  for k in pairs(tables) do
    if is_alias(k, prefixes) then
      aliased = aliased + 1
    end
  end
  log(string.format("extracted %d headers → %s/encounters.lua (%d game3 aliases)",
    #entries, root, aliased))
  return {
    headers = #entries,
    aliases = aliased,
    path = root .. "/encounters.lua",
  }
end

EncountersExtract.EXTRA_REL = "wild_extra.lua"

local function hasExtra()
  return Versions.WILD_EXTRA_HEADERS ~= nil
end

function EncountersExtract.parseExtra(rom)
  local out = { headerSets = {} }
  local names = {}
  for name in pairs(Versions.WILD_EXTRA_HEADERS) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    local set = Versions.WILD_EXTRA_HEADERS[name]
    out.headerSets[name] = EncountersExtract.parseHeaders(rom, set.off, nil, set.count)
  end
  -- pokeemerald/src/wild_encounter.c:67
  local fo = Versions.FEEBAS_WILD_MON
  out.feebas = {
    mon = { minLevel = rom:get(fo), maxLevel = rom:get(fo + 1), species = rom:u16(fo + 2) },
    sections = {},
  }
  for i = 0, Versions.FEEBAS_TILE_DATA_COUNT - 1 do
    local o = Versions.FEEBAS_TILE_DATA + i * 6
    out.feebas.sections[i + 1] = { yMin = rom:u16(o), yMax = rom:u16(o + 2), spotBase = rom:u16(o + 4) }
  end
  -- pokeemerald/src/pokemon.c:2114
  out.alteringCaveHeldItems = {}
  for i = 0, Versions.ALTERING_CAVE_HELD_ITEM_COUNT - 1 do
    local o = Versions.ALTERING_CAVE_HELD_ITEMS + i * 4
    out.alteringCaveHeldItems[i + 1] = { species = rom:u16(o), item = rom:u16(o + 2) }
  end
  return out
end

local function encode_extra(extra)
  local lines = {
    string.format("-- format_version=%d\n", EncountersExtract.FORMAT_VERSION),
    "return {\n",
    "  headerSets = {\n",
  }
  local names = {}
  for name in pairs(extra.headerSets) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    lines[#lines + 1] = string.format("    %s = {\n", name)
    for _, e in ipairs(extra.headerSets[name]) do
      lines[#lines + 1] = "    {\n"
      lines[#lines + 1] = string.format("    mapGroup = %d,\n", e.mapGroup)
      lines[#lines + 1] = string.format("    mapNum = %d,\n", e.mapNum)
      serialize_areas(lines, e)
      lines[#lines + 1] = "    },\n"
    end
    lines[#lines + 1] = "    },\n"
  end
  lines[#lines + 1] = "  },\n"
  local m = extra.feebas.mon
  lines[#lines + 1] = "  feebas = {\n"
  lines[#lines + 1] = string.format("    mon = { species = %d, minLevel = %d, maxLevel = %d },\n",
    m.species, m.minLevel, m.maxLevel)
  lines[#lines + 1] = "    sections = {\n"
  for _, s in ipairs(extra.feebas.sections) do
    lines[#lines + 1] = string.format("      { yMin = %d, yMax = %d, spotBase = %d },\n",
      s.yMin, s.yMax, s.spotBase)
  end
  lines[#lines + 1] = "    },\n  },\n"
  lines[#lines + 1] = "  alteringCaveHeldItems = {\n"
  for _, r in ipairs(extra.alteringCaveHeldItems) do
    lines[#lines + 1] = string.format("    { species = %d, item = %d },\n", r.species, r.item)
  end
  lines[#lines + 1] = "  },\n}\n"
  return table.concat(lines)
end

function EncountersExtract.writeExtra(rom, cache, root)
  local extra = EncountersExtract.parseExtra(rom)
  cache:write(root .. "/" .. EncountersExtract.EXTRA_REL, encode_extra(extra))
  return extra
end

EncountersExtract.REQUIRED = { "encounters.lua", EncountersExtract.EXTRA_REL }

function EncountersExtract.ready(cache, cacheRoot)
  if not (cache and cache.exists) then return false end
  local root = cacheRoot or "data/generated/gba"
  if not cache:exists(root .. "/encounters.lua") then return false end
  return not hasExtra() or cache:exists(root .. "/" .. EncountersExtract.EXTRA_REL)
end

function EncountersExtract.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local detail, err = EncountersExtract.writeExtract(rom, cache, root, opts.version)
  if not detail then error("encounters: " .. tostring(err)) end
  if hasExtra() then
    local extra = EncountersExtract.writeExtra(rom, cache, root)
    local n = 0
    for _, set in pairs(extra.headerSets) do n = n + #set end
    detail.extraHeaders = n
  end
  return detail
end

return EncountersExtract
