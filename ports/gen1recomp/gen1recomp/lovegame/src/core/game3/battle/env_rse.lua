local MB = require("src.core.game3.mb")
local Constants = require("src.core.game3.constants")

local Env = {}

Env.family = "rse"

local function battleConst(name)
  local v = Constants.of("emerald").battle.byName[name]
  if v == nil then error("env_rse: unknown battle constant " .. name) end
  return v
end

-- pokeemerald/include/constants/battle.h:313
Env.ENVIRONMENT = {
  GRASS = battleConst("BATTLE_ENVIRONMENT_GRASS"),
  LONG_GRASS = battleConst("BATTLE_ENVIRONMENT_LONG_GRASS"),
  SAND = battleConst("BATTLE_ENVIRONMENT_SAND"),
  UNDERWATER = battleConst("BATTLE_ENVIRONMENT_UNDERWATER"),
  WATER = battleConst("BATTLE_ENVIRONMENT_WATER"),
  POND = battleConst("BATTLE_ENVIRONMENT_POND"),
  MOUNTAIN = battleConst("BATTLE_ENVIRONMENT_MOUNTAIN"),
  CAVE = battleConst("BATTLE_ENVIRONMENT_CAVE"),
  BUILDING = battleConst("BATTLE_ENVIRONMENT_BUILDING"),
  PLAIN = battleConst("BATTLE_ENVIRONMENT_PLAIN"),
}

-- pokeemerald/src/battle_bg.c:760
Env.SCENE = {
  FRONTIER = 10,
  GROUDON = 11,
  KYOGRE = 12,
  RAYQUAZA = 13,
  LEADER = 14,
  CHAMPION = 15,
  GYM = 16,
  MAGMA = 17,
  AQUA = 18,
  SIDNEY = 19,
  PHOEBE = 20,
  GLACIA = 21,
  DRAKE = 22,
}

Env.TERRAIN = {}
for k, v in pairs(Env.ENVIRONMENT) do Env.TERRAIN[k] = v end
for k, v in pairs(Env.SCENE) do Env.TERRAIN[k] = v end

-- pokeemerald/include/constants/map_types.h:4
Env.MAP_TYPE = {
  NONE = 0,
  TOWN = 1,
  CITY = 2,
  ROUTE = 3,
  UNDERGROUND = 4,
  UNDERWATER = 5,
  OCEAN_ROUTE = 6,
  UNKNOWN = 7,
  INDOOR = 8,
  SECRET_BASE = 9,
}

-- pokeemerald/include/constants/map_types.h:15
Env.MAP_BATTLE_SCENE = {
  NORMAL = 0,
  GYM = 1,
  MAGMA = 2,
  AQUA = 3,
  SIDNEY = 4,
  PHOEBE = 5,
  GLACIA = 6,
  DRAKE = 7,
  FRONTIER = 8,
}

-- pokeemerald/src/battle_bg.c:807
local MAP_SCENE = {
  [Env.MAP_BATTLE_SCENE.GYM] = Env.SCENE.GYM,
  [Env.MAP_BATTLE_SCENE.MAGMA] = Env.SCENE.MAGMA,
  [Env.MAP_BATTLE_SCENE.AQUA] = Env.SCENE.AQUA,
  [Env.MAP_BATTLE_SCENE.SIDNEY] = Env.SCENE.SIDNEY,
  [Env.MAP_BATTLE_SCENE.PHOEBE] = Env.SCENE.PHOEBE,
  [Env.MAP_BATTLE_SCENE.GLACIA] = Env.SCENE.GLACIA,
  [Env.MAP_BATTLE_SCENE.DRAKE] = Env.SCENE.DRAKE,
  [Env.MAP_BATTLE_SCENE.FRONTIER] = Env.SCENE.FRONTIER,
}

Env.SCENE_SHEET = {}
for k, v in pairs(Env.SCENE) do Env.SCENE_SHEET[v] = k:lower() end

-- pokeemerald/src/battle_bg.c:602
Env.ENVIRONMENT_SHEET = {
  [Env.ENVIRONMENT.GRASS] = "grass",
  [Env.ENVIRONMENT.LONG_GRASS] = "long_grass",
  [Env.ENVIRONMENT.SAND] = "sand",
  [Env.ENVIRONMENT.UNDERWATER] = "underwater",
  [Env.ENVIRONMENT.WATER] = "water",
  [Env.ENVIRONMENT.POND] = "pond",
  [Env.ENVIRONMENT.MOUNTAIN] = "mountain",
  [Env.ENVIRONMENT.CAVE] = "cave",
  [Env.ENVIRONMENT.BUILDING] = "building",
  [Env.ENVIRONMENT.PLAIN] = "plain",
}

Env.TERRAIN_SHEET = {}
for id, key in pairs(Env.ENVIRONMENT_SHEET) do Env.TERRAIN_SHEET[id] = key end
for id, key in pairs(Env.SCENE_SHEET) do Env.TERRAIN_SHEET[id] = key end

function Env.sheetFor(id, manifest)
  id = tonumber(id)
  if id == nil then return nil end
  local envs = type(manifest) == "table" and manifest.environments or nil
  if envs and envs[id] then return envs[id] end
  return Env.TERRAIN_SHEET[id]
end

function Env.isEnvironment(id)
  id = tonumber(id)
  return id ~= nil and Env.ENVIRONMENT_SHEET[id] ~= nil
end

local function mb(name) return MB.require(name) end

-- pokeemerald/src/metatile_behavior.c:729
local function isTallGrass(b) return b == mb("TALL_GRASS") end
-- pokeemerald/src/metatile_behavior.c:737
local function isLongGrass(b) return b == mb("LONG_GRASS") end
-- pokeemerald/src/metatile_behavior.c:183
local function isSandOrDeepSand(b) return b == mb("SAND") or b == mb("DEEP_SAND") end
-- pokeemerald/src/metatile_behavior.c:837
local function isIndoorEncounter(b) return b == mb("INDOOR_ENCOUNTER") end
-- pokeemerald/src/metatile_behavior.c:845
local function isMountain(b) return b == mb("MOUNTAIN_TOP") end

-- pokeemerald/src/metatile_behavior.c:905
local function isDeepOrOceanWater(b)
  return b == mb("OCEAN_WATER") or b == mb("INTERIOR_DEEP_WATER") or b == mb("DEEP_WATER")
end

-- pokeemerald/src/metatile_behavior.c:6
local TILE_FLAG_SURFABLE = 2

Env._tileBits = nil

function Env.setTileBits(bits)
  Env._tileBits = type(bits) == "table" and bits or nil
end

local function tileBits()
  if Env._tileBits then return Env._tileBits end
  local ok, Coll = pcall(require, "src.core.game3.scripting.collision_rse")
  return ok and Coll and Coll._tileBits or nil
end

-- pokeemerald/src/metatile_behavior.c:280
local function isSurfableWaterOrUnderwater(b)
  local bits = tileBits()
  local v = bits and bits[b]
  return v ~= nil and math.floor(v / TILE_FLAG_SURFABLE) % 2 == 1
end

Env.isSurfable = isSurfableWaterOrUnderwater

local BRIDGE_TYPE_OCEAN = 0
local BRIDGE_TYPE_POND_MED = 2
local BRIDGE_TYPE_POND_HIGH = 3

-- pokeemerald/src/metatile_behavior.c:788
local function bridgeType(b)
  local order = { "BRIDGE_OVER_OCEAN", "BRIDGE_OVER_POND_LOW", "BRIDGE_OVER_POND_MED", "BRIDGE_OVER_POND_HIGH" }
  for i, name in ipairs(order) do
    if b == mb(name) then return i - 1 end
  end
  if b == mb("BRIDGE_OVER_POND_MED_EDGE_1") or b == mb("BRIDGE_OVER_POND_MED_EDGE_2") then
    return BRIDGE_TYPE_POND_MED
  end
  if b == mb("BRIDGE_OVER_POND_HIGH_EDGE_1") or b == mb("BRIDGE_OVER_POND_HIGH_EDGE_2") then
    return BRIDGE_TYPE_POND_HIGH
  end
  return BRIDGE_TYPE_OCEAN
end

-- pokeemerald/src/metatile_behavior.c:773
local function isBridgeOverWater(b)
  for _, name in ipairs({ "BRIDGE_OVER_OCEAN", "BRIDGE_OVER_POND_LOW", "BRIDGE_OVER_POND_MED",
    "BRIDGE_OVER_POND_HIGH", "BRIDGE_OVER_POND_HIGH_EDGE_1", "BRIDGE_OVER_POND_HIGH_EDGE_2",
    "UNUSED_BRIDGE", "BIKE_BRIDGE_OVER_BARRIER" }) do
    if b == mb(name) then return true end
  end
  return false
end

local KIND_MAP_TYPE = {
  town = Env.MAP_TYPE.TOWN,
  city = Env.MAP_TYPE.CITY,
  route = Env.MAP_TYPE.ROUTE,
  cave = Env.MAP_TYPE.UNDERGROUND,
  underground = Env.MAP_TYPE.UNDERGROUND,
  water = Env.MAP_TYPE.OCEAN_ROUTE,
  ocean = Env.MAP_TYPE.OCEAN_ROUTE,
  indoor = Env.MAP_TYPE.INDOOR,
  building = Env.MAP_TYPE.INDOOR,
  secret_base = Env.MAP_TYPE.SECRET_BASE,
}

function Env.resolveFromMapKind(kind)
  local E = Env.ENVIRONMENT
  kind = kind or "town"
  if kind == "indoor" or kind == "building" or kind == "secret_base" then return E.BUILDING end
  if kind == "cave" or kind == "underground" then return E.CAVE end
  if kind == "water" or kind == "ocean" then return E.WATER end
  if kind == "route" or kind == "town" or kind == "city" then return E.GRASS end
  return E.BUILDING
end

local function fieldContext(ctx)
  if type(ctx) == "table" then return ctx end
  local out = {}
  local Player = package.loaded["src.core.game3.player"]
  if Player then out.surfing = Player.surfing and true or false end
  local Map = package.loaded["src.core.game3.map"]
  if Map then out.mapId = Map.current end
  local W = package.loaded["src.core.game3.weather"]
  if W then out.weather = tonumber(W.get and W.get() or W.current) end
  return out
end

-- pokeemerald/src/battle_setup.c:636
function Env.resolveFromBehavior(behavior, mapKind, mapType, ctx)
  local b = tonumber(behavior)
  if b == nil then return Env.resolveFromMapKind(mapKind) end
  local E = Env.ENVIRONMENT
  local M = Env.MAP_TYPE
  local mt = tonumber(mapType) or KIND_MAP_TYPE[mapKind or "town"] or M.TOWN
  if isTallGrass(b) then return E.GRASS end
  if isLongGrass(b) then return E.LONG_GRASS end
  if isSandOrDeepSand(b) then return E.SAND end
  if mt == M.UNDERGROUND then
    if isIndoorEncounter(b) then return E.BUILDING end
    if isSurfableWaterOrUnderwater(b) then return E.POND end
    return E.CAVE
  elseif mt == M.INDOOR or mt == M.SECRET_BASE then
    return E.BUILDING
  elseif mt == M.UNDERWATER then
    return E.UNDERWATER
  elseif mt == M.OCEAN_ROUTE then
    if isSurfableWaterOrUnderwater(b) then return E.WATER end
    return E.PLAIN
  end
  if isDeepOrOceanWater(b) then return E.WATER end
  if isSurfableWaterOrUnderwater(b) then return E.POND end
  if isMountain(b) then return E.MOUNTAIN end
  local fc = fieldContext(ctx)
  if fc.surfing then
    if bridgeType(b) ~= BRIDGE_TYPE_OCEAN then return E.POND end
    if isBridgeOverWater(b) then return E.WATER end
  end
  if fc.mapId ~= nil and fc.mapId == require("src.core.game3.map_ids").forConst("MAP_ROUTE113", "emerald") then
    return E.SAND
  end
  if tonumber(fc.weather) == Constants.of("emerald").weather.byName.WEATHER_SANDSTORM then
    return E.SAND
  end
  return E.PLAIN
end

local function trainerClassId(name)
  return Constants.of("emerald").trainer_classes.byName[name]
end

-- pokeemerald/src/battle_bg.c:760
function Env.resolveOverride(envId, opts)
  opts = opts or {}
  local S = Env.SCENE
  local base = tonumber(envId) or Env.ENVIRONMENT.PLAIN
  local kinds = type(opts.kinds) == "table" and opts.kinds or {}
  local function has(k) return opts[k] or kinds[k] end
  if has("link") or has("frontier") or has("battleTower") or has("eReader") or has("recordedLink") then
    return S.FRONTIER
  end
  if has("groudon") then return S.GROUDON end
  if has("kyogre") then return S.KYOGRE end
  if has("rayquaza") then return S.RAYQUAZA end
  if opts.trainer then
    local cls = tonumber(opts.trainerClass)
    if cls ~= nil and cls == trainerClassId("TRAINER_CLASS_LEADER") then return S.LEADER end
    if cls ~= nil and cls == trainerClassId("TRAINER_CLASS_CHAMPION") then return S.CHAMPION end
  end
  local scene = tonumber(opts.mapBattleScene) or Env.MAP_BATTLE_SCENE.NORMAL
  return MAP_SCENE[scene] or base
end

return Env
