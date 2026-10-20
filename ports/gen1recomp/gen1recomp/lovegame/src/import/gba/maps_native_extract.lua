local Versions = require("src.import.gba.versions")
local Family = require("src.import.gba.family")
local MapTree = require("src.import.gba.map_tree")
local MapCatalog = require("src.import.gba.map_catalog")
local Tileset = require("src.import.gba.tileset")
local Maps = require("src.import.gba.maps")
local NativePack = require("src.import.gba.native_pack")
local AltLayouts = require("src.import.gba.alt_layouts")
local AnimPack = require("src.import.gba.tileset_anim_pack")
local ObjectInteractions = require("src.import.gba.object_interactions_extract")
local ExtractMapEvents = require("src.import.gba.extract_map_events")
local Collision = require("src.core.game3.scripting.collision")
local MB = require("src.core.game3.mb")

local M = {}

M.SUMMARY = "native/summary.lua"

M.REQUIRED = {
  "native/manifest.lua",
  M.SUMMARY,
  "mid_index.lua",
  "warps.lua",
  "connections.lua",
  "objects/pack.lua",
  AnimPack.INDEX_FILE,
}

local function log(msg)
  print("[maps_native] " .. msg)
end

local function load_lua(cache, rel)
  local src = cache:read(rel)
  local chunk = src and load(src, "@" .. rel, "t", {})
  if not chunk then return nil end
  local ok, v = pcall(chunk)
  return ok and v or nil
end

function M.ready(cache, cacheRoot)
  cacheRoot = cacheRoot or "data/generated/gba"
  for _, rel in ipairs(M.REQUIRED) do
    if not cache:exists(cacheRoot .. "/" .. rel) then return false end
  end
  local s = load_lua(cache, cacheRoot .. "/" .. M.SUMMARY)
  return type(s) == "table" and s.native_version == (Versions.NATIVE_VERSION or 1)
end

local function pad_even(grid)
  return require("src.import.gba.extract_island1").padEven(grid)
end

local function serialize(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then return string.format("%q", v) end
  if t ~= "table" then return tostring(v) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) == "number"
  end)
  local inner = indent .. "  "
  local out = { "{\n" }
  for _, k in ipairs(keys) do
    local key = type(k) == "number" and ("[" .. k .. "]") or ("[" .. string.format("%q", k) .. "]")
    out[#out + 1] = inner .. key .. " = " .. serialize(v[k], inner) .. ",\n"
  end
  out[#out + 1] = indent .. "}"
  return table.concat(out)
end

-- pokeemerald/include/global.fieldmap.h:64
local function tileset_inits(rom, version)
  local F = Family.active()
  local S = Versions.SYMS or F:syms()
  local out = {}
  local base = (version and version.g_map_layouts) or Versions.G_MAP_LAYOUTS
  local seen = {}
  for id = 1, Versions.NUM_MAP_LAYOUTS or 0 do
    local layout = MapTree.parseLayout(rom, rom:ptrOffset(rom:u32(base + (id - 1) * 4)))
    for _, ptr in ipairs(layout and { layout.primaryTilesetPtr, layout.secondaryTilesetPtr } or {}) do
      if ptr ~= 0 and not seen[ptr] then
        seen[ptr] = true
        local name, ts = MapCatalog.tilesetNameForPtr(rom, ptr)
        if name and ts and ts.callbackPtr and ts.callbackPtr ~= 0 then
          out[name] = S.funcAt(ts.callbackPtr)
        end
      end
    end
  end
  return out
end

local function write_mid_index(cache, root, pairNames, midLists, midIndex)
  local lines = { "return {\n" }
  for _, pairName in ipairs(pairNames) do
    lines[#lines + 1] = ("  [%q] = {\n"):format(pairName)
    for _, mid in ipairs(midLists[pairName] or {}) do
      local r = midIndex[pairName][mid]
      lines[#lines + 1] = ("    [%d] = { tiles = {0,0,0,0}, coll = %d, behavior = %d, category = %q },\n"):format(
        mid, r.coll, r.behavior, r.category)
    end
    lines[#lines + 1] = "  },\n"
  end
  lines[#lines + 1] = "}\n"
  cache:write(root .. "/mid_index.lua", table.concat(lines))
end

local function write_warps(cache, root, mapOrder, warps)
  local wl = { "return {\n" }
  for _, mapId in ipairs(mapOrder) do
    wl[#wl + 1] = ("  %s = {\n"):format(mapId)
    for _, w in ipairs(warps[mapId] or {}) do
      local dest = MapCatalog.mapIdFor(w.mapGroup, w.mapNum)
      if dest then
        wl[#wl + 1] = ("    { x = %d, y = %d, destMap = %q, destWarp = %d },\n"):format(
          w.x, w.y, dest, w.destWarp or 1)
      else
        wl[#wl + 1] = ("    { x = %d, y = %d, destMap = nil, destWarp = %d, mapGroup = %d, mapNum = %d },\n"):format(
          w.x, w.y, w.destWarp or 1, w.mapGroup or 0, w.mapNum or 0)
      end
    end
    wl[#wl + 1] = "  },\n"
  end
  wl[#wl + 1] = "}\n"
  cache:write(root .. "/warps.lua", table.concat(wl))
end

local function write_connections(cache, root, mapOrder, conns)
  local cl = { "return {\n" }
  for _, mapId in ipairs(mapOrder) do
    cl[#cl + 1] = ("  %s = {\n"):format(mapId)
    for _, c in ipairs(conns[mapId] or {}) do
      local dest = c.map or (c.mapGroup and MapCatalog.mapIdFor(c.mapGroup, c.mapNum))
      if dest then
        cl[#cl + 1] = ("    { dir = %q, map = %q, offset = %d },\n"):format(c.dir, dest, tonumber(c.offset) or 0)
      end
    end
    cl[#cl + 1] = "  },\n"
  end
  cl[#cl + 1] = "}\n"
  cache:write(root .. "/connections.lua", table.concat(cl))
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local version = assert(Versions.lookup(rom.md5 or rom.sha1))
  local F = Family.active()
  local Mb = MB.translator(F.game)
  local t0 = os.clock()

  MapCatalog.rebuildIndex()
  local census = assert(MapTree.walk(rom, version))
  local order, byEngine = MapCatalog.allOrder(census)
  local registered = MapCatalog.registerOrder(rom, version, order, byEngine)
  local regSet, dropped = {}, {}
  for _, id in ipairs(registered) do regSet[id] = true end
  for _, id in ipairs(order) do
    if not regSet[id] then
      dropped[#dropped + 1] = id
      log("drop map " .. id .. ": no tileset pair")
    end
  end

  local grids, borders = {}, {}
  for _, mapId in ipairs(registered) do
    local spec = Versions.MAPS[mapId]
    local layoutSpec = spec and version.layouts and version.layouts[spec.layout]
    if layoutSpec then
      local ok, grid = pcall(Maps.loadGrid, rom, layoutSpec)
      if ok and grid then
        grid.map_id = mapId
        grid.kind = spec.kind
        grid.pair = spec.pair
        grid.environment = spec.environment
        grids[mapId] = pad_even(grid)
        borders[mapId] = Maps.loadBorder(rom, version, mapId)
      else
        dropped[#dropped + 1] = mapId
        log("drop map " .. mapId .. ": " .. tostring(grid))
      end
    else
      dropped[#dropped + 1] = mapId
      log("drop map " .. mapId .. ": missing layout spec")
    end
  end

  local altAdded, altSkipped = AltLayouts.buildUnreferenced(rom, version, grids, borders, pad_even, census)
  for _, key in ipairs(altSkipped) do log("skip layout " .. key .. ": no tileset pair") end

  local needed = {}
  for _, grid in pairs(grids) do needed[grid.pair] = true end
  local pairNames = {}
  for name in pairs(needed) do pairNames[#pairNames + 1] = name end
  table.sort(pairNames)

  local bundles = {}
  for _, pairName in ipairs(pairNames) do
    local ok, bundle = pcall(Tileset.loadPair, rom, version, pairName)
    if ok and bundle then
      bundles[pairName] = bundle
    else
      log("skip tileset pair " .. pairName .. ": " .. tostring(bundle))
    end
  end
  local kept = {}
  for _, pairName in ipairs(pairNames) do
    if bundles[pairName] then kept[#kept + 1] = pairName end
  end
  pairNames = kept
  for key, grid in pairs(grids) do
    if not bundles[grid.pair] then
      grids[key] = nil
      borders[key] = nil
      dropped[#dropped + 1] = key
      log("drop layout " .. key .. ": tileset pair " .. tostring(grid.pair) .. " failed")
    end
  end
  local mapOrder = {}
  for _, id in ipairs(registered) do
    if grids[id] then mapOrder[#mapOrder + 1] = id end
  end

  local tileBits = Mb.tileBits(rom)
  local Impl = Collision.impl(F.name)
  if Impl.setTileBits then Impl.setTileBits(tileBits) end
  local function behaviorOf(bundle, mid)
    return Mb.canon((Tileset.behaviorOf(bundle, mid)))
  end

  local policy = NativePack.atlasPolicy(F.game)
  local midLists, midIndex, totalMids = {}, {}, 0
  for _, pairName in ipairs(pairNames) do
    local bundle = bundles[pairName]
    local list
    if policy == "full" then
      list = NativePack.fullMidsForPair(bundle)
    else
      list = NativePack.collectMidsForPair(grids, borders, pairName, nil)
    end
    midLists[pairName] = list
    totalMids = totalMids + #list
    local rows = {}
    for _, mid in ipairs(list) do
      local beh = behaviorOf(bundle, mid)
      rows[mid] = { coll = (Collision.fromCell(mid, 0, beh, "outdoor")), behavior = beh, category = "misc" }
    end
    midIndex[pairName] = rows
  end
  write_mid_index(cache, root, pairNames, midLists, midIndex)

  local romWarps, romConns = ExtractMapEvents.extractWarpsAndConnections(rom, version)
  write_warps(cache, root, mapOrder, romWarps)
  write_connections(cache, root, mapOrder, romConns)
  local warpCells = {}
  for _, mapId in ipairs(mapOrder) do
    local set = {}
    for _, w in ipairs(romWarps[mapId] or {}) do
      local x, y = tonumber(w.x), tonumber(w.y)
      if x and y then set[NativePack.warpKey(x, y)] = true end
    end
    warpCells[mapId] = set
  end

  local manifest = NativePack.writeExtract(cache, root, bundles, grids, borders, pairNames, midIndex,
    behaviorOf, Collision.fromCell, nil, warpCells, { midLists = midLists })

  ObjectInteractions.writeExtract(rom, cache, root, version)

  local inits = tileset_inits(rom, version)
  local animIndex = AnimPack.writeExtract(rom, cache, root, bundles, midLists, version, { tilesetInits = inits })

  local layoutCount = 0
  for _ in pairs(manifest.layouts or {}) do layoutCount = layoutCount + 1 end
  local animPairs = 0
  for _ in pairs(animIndex and animIndex.pairs or {}) do animPairs = animPairs + 1 end
  table.sort(dropped)
  local summary = {
    native_version = Versions.NATIVE_VERSION or 1,
    game = F.game,
    policy = policy,
    maps = #mapOrder,
    layouts = layoutCount,
    altLayouts = altAdded,
    altSkipped = altSkipped,
    dropped = dropped,
    pairs = #pairNames,
    mids = totalMids,
    animPairs = animPairs,
    tilesetInits = inits,
  }
  cache:write(root .. "/" .. M.SUMMARY, "return " .. serialize(summary) .. "\n")
  log(string.format("%d maps, %d alt layouts, %d dropped, %d pairs, %d mids, %d anim pairs (%.1fs)",
    #mapOrder, #altAdded, #dropped, #pairNames, totalMids, animPairs, os.clock() - t0))
  return summary
end

return M
