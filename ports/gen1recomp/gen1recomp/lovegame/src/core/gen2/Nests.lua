-- Where does this species live?  engine/overworld/wildmons.asm FindNest, which
-- is the data behind the Pokedex's AREA page and the Pokegear MAP card's
-- "<MON>'S NEST" overlay.
--
-- FindNest takes a species and a region (e: 0 Johto, 1 Kanto) and fills the
-- tilemap with LANDMARK indices -- one per map whose wild data contains the
-- species.  It reads exactly three sources, in this order:
--
--   .FindGrass   JohtoGrassWildMons / KantoGrassWildMons, all NUM_GRASSMON * 3
--                slots, so morning, day AND night count
--   .FindWater   JohtoWaterWildMons / KantoWaterWildMons
--   .RoamMon1/2/3  the three roamers' CURRENT map, Johto only
--
-- and nothing else.  Headbutt trees, fishing groups, the Bug Contest and swarms
-- are all absent from it, so a HEADBUTT-only species legitimately has no nest
-- and the page stays blank -- that is the cart's answer, not a gap.
--
-- Region is decided here by LANDMARK INDEX rather than by which of the two
-- tables a map came from: the extractor emits one `grass`/`water` table keyed
-- by map, and Johto's landmarks are the run below LANDMARK_PALLET_TOWN with
-- Kanto's above it (constants/landmark_constants.asm).  Same split, different
-- spelling.
local Nests = {}

-- ../pokecrystal/constants/landmark_constants.asm:34
Nests.LANDMARK_PALLET_TOWN = 0x2e
Nests.LANDMARK_FAST_SHIP = 0x5e

local function landmarkIndexOf(data, id, fallback)
  local landmarks = data and data.gen2Landmarks
  local records = landmarks and landmarks.landmarks
  local record = records and records["LANDMARK_" .. id]
  local index = type(record) == "table" and tonumber(record.index)
  return index or fallback
end

function Nests.regionOf(landmark, data)
  if not landmark or landmark <= 0 then return nil end
  if landmark >= landmarkIndexOf(data, "FAST_SHIP", Nests.LANDMARK_FAST_SHIP) then
    return nil
  end
  local kanto = landmarkIndexOf(data, "PALLET_TOWN", Nests.LANDMARK_PALLET_TOWN)
  return (landmark < kanto) and "johto" or "kanto"
end

-- ---------------------------------------------------------- the landmarks
--
-- data/maps/landmarks.asm, which on Gold is one index space shared by every
-- map header's `landmark` byte, the Pokegear MAP card and the #DEX AREA page
-- this file feeds.  It is the `landmarks` registry (src/mods/Schemas.lua), one
-- of the Gen 2-only six: Red's town map is a different table with a different
-- id space, so the name is gated under Gen 1 and routed to
-- gen2Landmarks.landmarks under Gen 2 -- straight onto the cache's own table,
-- which means the merge lands in the very table the map card draws from and no
-- Builtins seeding is needed (the same arrangement gen2Maps has).
--
-- Two reads go through here rather than through landmarks.order, which is a
-- plain ordered list the extractor writes and a registered landmark is
-- therefore absent from: src/core/Game2.lua:currentLandmark and
-- src/ui/gen2/MapRadio.lua's region test.  `index` on a record is the byte the
-- map header carries, so the lookup is by that and the order list stays the
-- fallback for a dataset whose records predate it.

-- memoized per landmark table (weak keys, so a second dataset in one process
-- does not pin the first); built on first read, which is after the merge --
-- nothing asks for a landmark before the overworld exists
local byIndex = setmetatable({}, { __mode = "k" })

-- Two records may claim one index -- a mod that registers a landmark at a byte
-- the cart already uses -- and pairs() would decide which one answers per
-- process.  The cache's own row wins its own slot (landmarks.order is that
-- list), and between two newcomers the lower id wins, so the answer is the
-- same on every boot.  A mod that means to MOVE a vanilla landmark patches
-- that record rather than shadowing its index.
local function indexTable(landmarks)
  local hit = byIndex[landmarks]
  if hit then return hit end
  local map, order = {}, landmarks.order or {}
  for id, record in pairs(landmarks.landmarks or {}) do
    local index = type(record) == "table" and record.index
    if index then
      local held = map[index]
      if held == nil or order[index + 1] == id
          or (order[index + 1] ~= held and id < held) then
        map[index] = id
      end
    end
  end
  byIndex[landmarks] = map
  return map
end

-- The LANDMARK_* id at a map header's landmark byte, or nil.
function Nests.landmarkId(data, index)
  local landmarks = data and data.gen2Landmarks
  if not (landmarks and index) then return nil end
  local hit = indexTable(landmarks)[index]
  if hit then return hit end
  return landmarks.order and landmarks.order[index + 1] or nil
end

-- The record behind that byte: the two-line name and the map-card position.
function Nests.landmark(data, index)
  local landmarks = data and data.gen2Landmarks
  local id = Nests.landmarkId(data, index)
  return id and landmarks.landmarks and landmarks.landmarks[id] or nil
end

local function landmarkOfMap(data, mapId)
  local def = data and data.gen2Maps and data.gen2Maps[mapId]
  return def and def.landmark
end

-- Every slot of one encounter table entry, across all times of day: the cart
-- walks `NUM_GRASSMON * 3` bytes without caring which third it is in.
local function tableHasSpecies(entry, species)
  if type(entry) ~= "table" then return false end
  local slots = entry.slots
  if type(slots) ~= "table" then return false end
  for _, list in pairs(slots) do
    if type(list) == "table" then
      for _, slot in ipairs(list) do
        if slot and slot.species == species then return true end
      end
    end
  end
  return false
end

-- The landmark indices where `species` can be met, in ascending order.
--
-- `region` is "johto" or "kanto"; nil means both, which no cart screen asks
-- for but is the useful answer for a test.
function Nests.find(data, species, region, save)
  local out, seen = {}, {}
  local function add(landmark)
    if not landmark or landmark <= 0 or seen[landmark] then return end
    local where = Nests.regionOf(landmark, data)
    if not where then return end
    if region and where ~= region then return end
    seen[landmark] = true
    out[#out + 1] = landmark
  end

  local enc = data and data.gen2Encounters
  for _, key in ipairs({ "grass", "water" }) do
    for mapId, entry in pairs((enc and enc[key]) or {}) do
      if tableHasSpecies(entry, species) then
        add(landmarkOfMap(data, mapId))
      end
    end
  end

  -- .RoamMon1/2/3: the roamer's CURRENT map, and only while it is still out
  -- there -- a caught or defeated one keeps its slot but loses its species and
  -- map. Johto-only on the cart, which the region filter above enforces.
  --
  -- The test is Roamers.active, NOT "has HP": a roamer starts life at hp 0
  -- (`xor a ; generate new stats`) and only gets a real value once you have met
  -- it, so an HP test would hide all three until first contact -- exactly the
  -- ones the page is most useful for.
  local Roamers = require("src.core.gen2.Roamers")
  for _, slot in ipairs((save and save.roamers) or {}) do
    if Roamers.active(slot) and slot.species == species then
      add(landmarkOfMap(data, slot.map))
    end
  end

  table.sort(out)
  return out
end

return Nests
