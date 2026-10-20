-- pokefirered/src/overworld.c:490

local Versions = require("src.import.gba.versions")

local AltLayouts = {}

-- pokefirered/include/constants/layouts.h:253,267,268,308
AltLayouts.ROWS = {
  { id = 264, map = "SevenIsland_House_Room1", width = 11, height = 9 },
  { id = 278, map = "SeafoamIslands_B3F", width = 38, height = 24 },
  { id = 279, map = "SeafoamIslands_B4F", width = 38, height = 24 },
  { id = 319, map = "ThreeIsland_DunsparceTunnel", width = 30, height = 7 },
}

-- pokefirered/src/trainer_tower.c:554, include/constants/layouts.h:355, :363
AltLayouts.TOWER_ROWS = {}
for floor = 1, 8 do
  local map = "TrainerTower_" .. floor .. "F"
  AltLayouts.TOWER_ROWS[#AltLayouts.TOWER_ROWS + 1] =
    { id = 365 + floor, map = map, width = 18, height = 17 }
  AltLayouts.TOWER_ROWS[#AltLayouts.TOWER_ROWS + 1] =
    { id = 373 + floor, map = map, width = 18, height = 17 }
end

AltLayouts.KEY_PREFIX = "alt_"

function AltLayouts.key(id)
  return AltLayouts.KEY_PREFIX .. tostring(id)
end

function AltLayouts.layoutOffset(rom, version, id)
  local base = (version and version.g_map_layouts) or Versions.G_MAP_LAYOUTS
  if not base or not id or id < 1 then return nil end
  return rom:ptrOffset(rom:u32(base + (id - 1) * 4))
end

local function read_border(rom, layout)
  local bw = layout.borderWidth or 0
  local bh = layout.borderHeight or 0
  local off = rom:ptrOffset(layout.borderPtr)
  if not off or bw < 1 or bh < 1 or bw > 16 or bh > 16 then
    return { width = 1, height = 1, mids = { 0 } }
  end
  local mids = {}
  for i = 0, bw * bh - 1 do
    mids[i + 1] = rom:u16(off + i * 2) % 1024
  end
  return { width = bw, height = bh, mids = mids }
end

-- pokefirered/src/scrcmd.c:711
function AltLayouts.build(rom, version, grids, borders, padEven)
  local MapTree = require("src.import.gba.map_tree")
  local MapCatalog = require("src.import.gba.map_catalog")
  local Maps = require("src.import.gba.maps")
  local added = {}
  local rows = {}
  for _, row in ipairs(AltLayouts.ROWS) do rows[#rows + 1] = row end
  for _, row in ipairs(AltLayouts.TOWER_ROWS) do rows[#rows + 1] = row end
  for _, row in ipairs(rows) do
    local ownerId = MapCatalog.resolve(row.map)
    local owner = ownerId and grids and grids[ownerId]
    local layoutOff = AltLayouts.layoutOffset(rom, version, row.id)
    local layout = layoutOff and MapTree.parseLayout(rom, layoutOff)
    local mapOff = layout and rom:ptrOffset(layout.mapPtr)
    if owner and layout and mapOff
      and layout.width == row.width and layout.height == row.height then
      local grid = Maps.loadGrid(rom, {
        offset = mapOff, width = layout.width, height = layout.height,
      })
      grid.map_id = ownerId
      grid.kind = owner.kind
      grid.pair = owner.pair
      grid.environment = owner.environment
      if padEven then grid = padEven(grid) end
      grid.altLayoutId = row.id
      grid.altOwner = ownerId
      local key = AltLayouts.key(row.id)
      grids[key] = grid
      if borders then borders[key] = read_border(rom, layout) end
      added[#added + 1] = key
    end
  end
  return added
end

local function owner_for(name, byPret)
  local best, bestLen = nil, 0
  for pret, engineId in pairs(byPret) do
    local n = #pret
    if n > bestLen and name:sub(1, n) == pret then
      local nextCh = name:sub(n + 1, n + 1)
      if nextCh == "" or nextCh == "_" or nextCh:match("%u") then
        best, bestLen = engineId, n
      end
    end
  end
  return best
end

-- pokeemerald/src/overworld.c:993
function AltLayouts.buildUnreferenced(rom, version, grids, borders, padEven, census)
  local MapTree = require("src.import.gba.map_tree")
  local MapCatalog = require("src.import.gba.map_catalog")
  local Maps = require("src.import.gba.maps")
  local F = require("src.import.gba.family").active()
  local S = F:syms()
  local base = (version and version.g_map_layouts) or Versions.G_MAP_LAYOUTS
  local count = Versions.NUM_MAP_LAYOUTS or 0
  local referenced, byPret = {}, {}
  for _, entry in ipairs(census and census.maps or {}) do
    if entry.layout and entry.layout.layoutOff then referenced[entry.layout.layoutOff] = true end
    if entry.pretName and entry.engineId then byPret[entry.pretName] = entry.engineId end
  end
  local added, skipped = {}, {}
  for id = 1, count do
    local layoutOff = rom:ptrOffset(rom:u32(base + (id - 1) * 4))
    if layoutOff and not referenced[layoutOff] then
      local layout = MapTree.parseLayout(rom, layoutOff)
      local mapOff = layout and rom:ptrOffset(layout.mapPtr)
      local pair = layout and mapOff and MapCatalog.pairForLayout(rom, layout)
      local key = AltLayouts.key(id)
      if pair then
        local name
        for _, n in ipairs(S.namesAt(layoutOff)) do
          name = n:match("^(.+)_Layout$") or name
        end
        local ownerId = name and owner_for(name, byPret) or nil
        local owner = ownerId and grids and grids[ownerId]
        local grid = Maps.loadGrid(rom, { offset = mapOff, width = layout.width, height = layout.height })
        grid.map_id = key
        grid.pair = pair
        grid.kind = owner and owner.kind or nil
        grid.environment = owner and owner.environment or nil
        if padEven then grid = padEven(grid) end
        grid.altLayoutId = id
        grid.layoutName = name
        if owner and owner.width == grid.width and owner.height == grid.height then
          grid.altOwner = ownerId
        end
        grids[key] = grid
        if borders then borders[key] = read_border(rom, layout) end
        added[#added + 1] = key
      else
        skipped[#skipped + 1] = key
      end
    end
  end
  return added, skipped
end

return AltLayouts
