-- Wild encounter tables + step rolls. Feeds battle_bridge.
-- Tables come from ROM extract (cache encounters.lua via gWildMonHeaders).
-- RNG: pret wild_encounter.c — Random() for gate/slot/level, WildEncounterRandom for rate.

local Rng = require("src.core.game3.rng")
local ModRuntime = require("src.mods.Runtime")
local Profile = require("src.core.game3.profile")

local Encounters = {}

Encounters._tables = {} -- mapId or "group:num" → { land = { rate, slots }, ... }
Encounters._pendingWild = nil
Encounters._prevGrass = false -- pret first-step-into-grass gate
Encounters._prevMetatileBehavior = 0 -- pokefirered/src/wild_encounter.c:27
Encounters._encounterTypes = nil -- pokefirered/src/fieldmap.c:68
Encounters._stepsSinceLastEncounter = 0 -- pret sWildEncounterData.stepsSinceLastEncounter
Encounters._encounterRateBuff = 0 -- pret sWildEncounterData.encounterRateBuff
Encounters._immunitySteps = 0 -- pokeemerald/src/field_control_avatar.c:38
Encounters._rsePrevBehavior = 0 -- pokeemerald/src/field_control_avatar.c:39
Encounters._logged = false
Encounters._loaded = false

-- pret ENCOUNTER_CHANCE_LAND_MONS_* cumulative weights (total 100).
local LAND_WEIGHTS = { 20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1 }
local WATER_WEIGHTS = { 60, 30, 5, 4, 1 }


-- pokefirered/include/global.fieldmap.h:40
local TILE_ENCOUNTER_NONE = 0
local TILE_ENCOUNTER_LAND = 1
local TILE_ENCOUNTER_WATER = 2

local function game_constants()
  return require("src.core.game3.constants").of(Profile.forSession(nil).id)
end

local function log(msg)
  print("[game3/encounters] " .. tostring(msg))
end

local function merge_tables(dst, src)
  if type(src) ~= "table" then return end
  for k, v in pairs(src) do
    dst[k] = v
  end
end

local function load_lua_blob(src, label)
  if not src or src == "" then return nil end
  local chunk = load(src, label or "@encounters", "t", {})
  if not chunk then return nil end
  local ok, data = pcall(chunk)
  if ok and type(data) == "table" then return data end
  return nil
end

--- Same cache path Dataset / NativeTileset use (firered/ + CacheFs.readActive).
local function load_from_cache(file)
  local Extract = package.loaded["src.import.gba.extract_island1"]
    or require("src.import.gba.extract_island1")
  local root = Extract.CACHE_ROOT or "data/generated/gba"
  local path = root .. "/" .. (file or "encounters.lua")

  local okD, Dataset = pcall(require, "src.core.game3.dataset")
  if okD and Dataset and Dataset.cache then
    local src = Dataset.cache():read(path)
    local data = load_lua_blob(src, "@" .. path)
    if data then return data end
  end

  -- Fallback: CacheFs directly (version prefix).
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  if okC and CacheFs and CacheFs.readActive then
    local src = CacheFs.readActive(path)
    local data = load_lua_blob(src, "@" .. path)
    if data then return data end
  end

  if love and love.filesystem and love.filesystem.read then
    local src = love.filesystem.read(path)
    return load_lua_blob(src, "@" .. path)
  end
  return nil
end

function Encounters.loadCacheFile(file)
  return load_from_cache(file)
end

function Encounters.loadFromMod(_mod)
  Encounters._tables = {}
  Encounters._loaded = false

  local data = load_from_cache()
  if data then
    merge_tables(Encounters._tables, data)
    Encounters._loaded = true
  end

  local okStub, stub = pcall(require, "src.core.game3.encounters_data_stub")
  if okStub and type(stub) == "table" then
    if stub.TABLES then merge_tables(Encounters._tables, stub.TABLES)
    else merge_tables(Encounters._tables, stub) end
  end

  local n = 0
  for _ in pairs(Encounters._tables) do n = n + 1 end
  if not Encounters._logged or n > 0 then
    log(string.format("loaded %d map tables%s",
      n, data and " (ROM extract)" or " (no extract — re-run gba extract)"))
    Encounters._logged = true
  end
end

--- Lazy reload if install ran before the firered cache was mounted.
function Encounters.ensureLoaded()
  if Encounters._loaded then
    local n = 0
    for _ in pairs(Encounters._tables) do n = n + 1 end
    if n > 0 then return true end
  end
  Encounters.loadFromMod(nil)
  return Encounters._loaded
end

-- pokefirered/src/fieldmap.c:68
function Encounters.installEncounterTypes(tbl)
  Encounters._encounterTypes = (type(tbl) == "table" and next(tbl) ~= nil) and tbl or nil
end

local function collision_mod()
  return package.loaded["src.core.game3.collision"]
end

-- pokefirered/src/fieldmap.c:385
function Encounters.encounterTypeAt(cx, cy)
  local types = Encounters._encounterTypes
  if not types then return nil end
  local Collision = collision_mod()
  local mapDef = Collision and Collision._mapDef
  local layout = mapDef and mapDef.midLayout
  if not layout then return nil end
  local pair = mapDef.pair or layout.pair
  local forPair = pair and types[pair]
  if not forPair then return nil end
  return forPair[layout:midAt(cx, cy)] or TILE_ENCOUNTER_NONE
end

local function fallback_encounter_type(cx, cy)
  local Collision = collision_mod()
  if not Collision then return TILE_ENCOUNTER_NONE end
  if Collision.isWater and Collision.isWater(cx, cy) then return TILE_ENCOUNTER_WATER end
  if Collision.isGrass and Collision.isGrass(cx, cy) then return TILE_ENCOUNTER_LAND end
  return TILE_ENCOUNTER_NONE
end

-- pokefirered/src/fieldmap.c:391
local function behavior_at(cx, cy)
  local Collision = collision_mod()
  if not (Collision and Collision.behavior) then return nil end
  return Collision.behavior(cx, cy) or 0
end

local TERRAIN_FOR_TYPE = {
  [TILE_ENCOUNTER_LAND] = "land",
  [TILE_ENCOUNTER_WATER] = "water",
}

-- pokefirered/src/wild_encounter.c:366,404
function Encounters.terrainAt(cx, cy)
  local t = Encounters.encounterTypeAt(cx, cy)
  if t == nil then t = fallback_encounter_type(cx, cy) end
  return TERRAIN_FOR_TYPE[t]
end

function Encounters.setWildBattle(species, level, item)
  Encounters._pendingWild = {
    species = species,
    level = level,
    item = item,
  }
end

function Encounters.takePendingWild()
  local p = Encounters._pendingWild
  Encounters._pendingWild = nil
  return p
end

--- pret ChooseWildMonIndex_Land / WaterRock: Random() % total, cumulative slots.
local function pick_slot_index(weights)
  local total = 0
  for i = 1, #weights do
    total = total + (weights[i] or 0)
  end
  if total < 1 then return 1 end
  local rand = Rng.Random() % total
  local acc = 0
  for i = 1, #weights do
    acc = acc + (weights[i] or 0)
    if rand < acc then return i end
  end
  return #weights
end

local function pick_slot(slots, weights)
  if type(slots) ~= "table" or #slots == 0 then return nil end
  local n = #slots
  local w = {}
  for i = 1, n do
    w[i] = weights[i] or 1
  end
  local idx = pick_slot_index(w)
  if idx < 1 then idx = 1 end
  if idx > n then idx = n end
  return slots[idx]
end

--- pret ChooseWildMonLevel: lo + Random() % (hi - lo + 1).
local function level_of(entry)
  if not entry then return 5 end
  local minLevel = tonumber(entry.minLevel or entry.level or entry[2]) or 5
  local maxLevel = tonumber(entry.maxLevel or entry.level or entry[2]) or minLevel
  local lo, hi = minLevel, maxLevel
  if maxLevel < minLevel then lo, hi = maxLevel, minLevel end
  local mod = hi - lo + 1
  return lo + (Rng.Random() % mod)
end

local function normalize_area(area, fallbackRate)
  if type(area) ~= "table" then return nil end
  if area.slots or area.mons then
    return {
      rate = area.rate or fallbackRate or 21,
      slots = area.slots or area.mons,
    }
  end
  if #area > 0 then
    return { rate = fallbackRate or 21, slots = area }
  end
  return nil
end

local function wild_set_var()
  local VAR_ALTERING_CAVE_WILD_SET = game_constants():require("vars", "VAR_ALTERING_CAVE_WILD_SET")
  local Sp = package.loaded["src.core.game3.scripting.space"]
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  if Sp and Sp.store and Flags and Flags.getVar then
    return tonumber(Flags.getVar(Sp.store, nil, VAR_ALTERING_CAVE_WILD_SET)) or 0
  end
  local ok, Runtime = pcall(require, "src.core.game3.runtime")
  local session = ok and Runtime and Runtime.getSession and Runtime.getSession()
  local vars = type(session) == "table" and session.vars
  return type(vars) == "table" and tonumber(vars[VAR_ALTERING_CAVE_WILD_SET]) or 0
end

-- pokefirered/src/wild_encounter.c:192
local function pick_variant(t)
  if type(t) ~= "table" or type(t.variants) ~= "table" then return t end
  local id = wild_set_var()
  if id >= #t.variants then id = 0 end
  return t.variants[id + 1] or t
end

local function resolve_table(mapId)
  if not mapId then return nil end
  local t = Encounters._tables[mapId]
  if t then return t end
  local s = tostring(mapId)
  t = Encounters._tables[s]
  if t then return t end

  -- MapCatalog resolution (e.g. pret name or group:num)
  local ok, MapCatalog = pcall(require, "src.import.gba.map_catalog")
  if ok and MapCatalog then
    local res = MapCatalog.resolve(s)
    if res and Encounters._tables[res] then
      return Encounters._tables[res]
    end
    local slot = MapCatalog.slotKeyFor(s)
    if slot then
      local colonSlot = slot:gsub("_", ":")
      if Encounters._tables[colonSlot] then return Encounters._tables[colonSlot] end
      if Encounters._tables[slot] then return Encounters._tables[slot] end
    end
  end

  -- Prefix stripping / addition
  if s:sub(1, 3) == "FR_" then
    t = Encounters._tables[s:sub(4)]
    if t then return t end
  else
    t = Encounters._tables["FR_" .. s]
    if t then return t end
  end

  -- Route underscore normalization (ROUTE_22 <-> ROUTE22)
  local routeNum = s:match("ROUTE_?(%d+)")
  if routeNum then
    t = Encounters._tables["FR_ROUTE_" .. routeNum]
      or Encounters._tables["FR_ROUTE" .. routeNum]
      or Encounters._tables["ROUTE_" .. routeNum]
      or Encounters._tables["ROUTE" .. routeNum]
    if t then return t end
  end

  return nil
end

local function table_for(mapId)
  return pick_variant(resolve_table(mapId))
end

function Encounters.tableFor(mapId)
  Encounters.ensureLoaded()
  return table_for(mapId)
end
Encounters.table_for = Encounters.tableFor

--- The area `terrain` rolls on, resolved the same way rollLand/rollWater do.
--- The cooldown needs the rate before the roll happens, and must not consume
--- RNG to get it.
local function area_for(mapId, terrain)
  local t = table_for(mapId)
  if terrain == "water" then
    return normalize_area(t and t.water, 15)
  end
  return normalize_area(t and t.land) or normalize_area(t and t.grass)
end

--- pret TestPlayerAvatarFlags(PLAYER_AVATAR_FLAG_MACH_BIKE | ..._ACRO_BIKE).
local function bike_active()
  local ok, Player = pcall(require, "src.core.game3.player")
  return (ok and Player and Player.biking) == true
end

--- pret VarGet(VAR_REPEL_STEP_COUNT) != 0.
local function repel_active()
  local ok, Runtime = pcall(require, "src.core.game3.runtime")
  local session = ok and Runtime and Runtime.getSession and Runtime.getSession()
  if type(session) ~= "table" then return false end
  local steps = tonumber(require("src.core.game3.field_semantics").getVar(session, "repelSteps")) or 0
  return steps > 0
end

-- pokefirered/src/wild_encounter.c:601
local function wild_level_allowed_by_repel(wildLevel)
  if not repel_active() then return true end
  local ok, Runtime = pcall(require, "src.core.game3.runtime")
  local session = ok and Runtime and Runtime.getSession and Runtime.getSession()
  local party = session and session.party
  if type(party) ~= "table" then return false end
  for i = 1, 6 do
    local mon = party[i]
    if type(mon) == "table" and (tonumber(mon.hp) or tonumber(mon.currentHp) or 1) > 0
      and not mon.isEgg and not mon.egg then
      return not ((tonumber(wildLevel) or 0) < (tonumber(mon.level) or 0))
    end
  end
  return false
end

local H = {
  LAND_WEIGHTS = LAND_WEIGHTS,
  WATER_WEIGHTS = WATER_WEIGHTS,
  TILE_ENCOUNTER_LAND = TILE_ENCOUNTER_LAND,
  TILE_ENCOUNTER_WATER = TILE_ENCOUNTER_WATER,
  normalize_area = normalize_area,
  table_for = table_for,
  area_for = area_for,
  pick_slot = pick_slot,
  pick_slot_index = pick_slot_index,
  level_of = level_of,
  bike_active = bike_active,
  repel_active = repel_active,
  wild_level_allowed_by_repel = wild_level_allowed_by_repel,
  constants = game_constants,
}
Encounters._h = H

local bound = {}

local function rules()
  local family = Profile.family()
  local profile = Profile.forSession(nil)
  local key = profile.encounters and profile.encounters.rules or family
  local r = bound[key]
  if not r then
    r = require("src.core.game3.encounter_rules." .. key).bind(Encounters, H)
    bound[key] = r
  end
  return r
end
Encounters.rules = rules

for _, name in ipairs({
  "mapBaseCooldown", "cooldownMinSteps", "handleCooldown", "resetRateModifiers",
  "encounterRate", "rollLand", "rollWater", "rollRocks", "rollSweetScent", "sweetScentFacility", "hasFishingMons", "rollFishing",
}) do
  Encounters[name] = function(...)
    local f = rules()[name]
    if not f then
      error("game3 encounters: " .. Profile.family() .. " rules have no " .. name, 2)
    end
    return f(...)
  end
end

local function vanilla_step(mapId, terrain, opts)
  return rules().step(mapId, terrain, opts)
end

local function mod_encounter(enc)
  if type(enc) ~= "table" then return enc end
  local Pokemon = require("src.core.game3.pokemon")
  local id = tonumber(enc.species)
  return {
    species = (id and Pokemon.keyName(id)) or enc.species,
    speciesId = id or Pokemon.speciesFromName(enc.species),
    level = enc.level,
    item = enc.item,
    roamer = enc.roamer,
    foe = enc.foe,
    personality = enc.personality,
    ivs = enc.ivs,
    moves = enc.moves,
  }
end

local function engine_encounter(enc)
  if type(enc) ~= "table" then return nil end
  local id = tonumber(enc.species)
  if not id and enc.species ~= nil then
    local Pokemon = require("src.core.game3.pokemon")
    id = Pokemon.speciesFromName(enc.species)
  end
  id = id or tonumber(enc.speciesId)
  if not id then return nil end
  return {
    species = id,
    level = tonumber(enc.level) or 5,
    item = enc.item,
    roamer = enc.roamer,
    foe = enc.foe,
    personality = enc.personality,
    ivs = enc.ivs,
    moves = enc.moves,
  }
end

local function same_encounter(enc) return enc end

-- pokefirered/src/wild_encounter.c:757
function Encounters.onStep(mapId, terrain, opts)
  opts = opts or {}
  local x, y = opts.x, opts.y
  local behavior = opts.behavior
  if behavior == nil and x and y then behavior = behavior_at(x, y) end
  if terrain == nil and x and y then terrain = Encounters.terrainAt(x, y) end

  local prevBehavior = Encounters._prevMetatileBehavior
  if behavior ~= nil then Encounters._prevMetatileBehavior = behavior end
  if rules().everyStep then
    opts = { x = x, y = y, behavior = behavior, terrain = terrain }
  else
    if x and y and terrain == nil then return nil end

    if opts.enterFromOther == nil and behavior ~= nil then
      opts = {
        enterFromOther = behavior ~= prevBehavior,
        x = x, y = y, behavior = behavior,
      }
    end
  end

  local wantsRoll = ModRuntime.wantsHook("encounter.roll")
  local wantsSpecies = ModRuntime.wantsHook("encounter.species")
  if not (wantsRoll or wantsSpecies) then
    return vanilla_step(mapId, terrain, opts)
  end
  Encounters.ensureLoaded()
  local ctx = { mapId = mapId, terrain = terrain, rng = Rng.Random, opts = opts }
  local enc
  if wantsRoll then
    enc = ModRuntime.call("encounter.roll", function()
      return mod_encounter(vanilla_step(mapId, terrain, opts))
    end, table_for(mapId), ctx)
  else
    enc = mod_encounter(vanilla_step(mapId, terrain, opts))
  end
  if enc and wantsSpecies then
    enc = ModRuntime.call("encounter.species", same_encounter, enc, ctx)
  end
  enc = engine_encounter(enc)
  if enc then Encounters.resetRateModifiers() end
  return enc
end

function Encounters.noteGrass(onGrass)
  Encounters._prevGrass = onGrass and true or false
end

return Encounters
