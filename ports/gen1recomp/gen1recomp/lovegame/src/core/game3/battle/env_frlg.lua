local Collision = require("src.core.game3.collision")

local Env = {}

Env.family = "frlg"

-- pret include/constants/battle.h
Env.TERRAIN = {
  GRASS = 0,
  LONG_GRASS = 1,
  SAND = 2,
  UNDERWATER = 3,
  WATER = 4,
  POND = 5,
  MOUNTAIN = 6,
  CAVE = 7,
  BUILDING = 8,
  PLAIN = 9,
  LINK = 10,
  GYM = 11,
  LEADER = 12,
  INDOOR_2 = 13,
  INDOOR_1 = 14,
  LORELEI = 15,
  BRUNO = 16,
  AGATHA = 17,
  LANCE = 18,
  CHAMPION = 19,
}

-- pret include/constants/map_types.h:4
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

-- pret include/constants/map_types.h:15
Env.MAP_BATTLE_SCENE = {
  NORMAL = 0,
  GYM = 1,
  INDOOR_1 = 2,
  INDOOR_2 = 3,
  LORELEI = 4,
  BRUNO = 5,
  AGATHA = 6,
  LANCE = 7,
  LINK = 8,
}

-- pret src/battle_bg.c:602 sMapBattleSceneMapping
local SCENE_TERRAIN = {
  [Env.MAP_BATTLE_SCENE.GYM] = Env.TERRAIN.GYM,
  [Env.MAP_BATTLE_SCENE.INDOOR_1] = Env.TERRAIN.INDOOR_1,
  [Env.MAP_BATTLE_SCENE.INDOOR_2] = Env.TERRAIN.INDOOR_2,
  [Env.MAP_BATTLE_SCENE.LORELEI] = Env.TERRAIN.LORELEI,
  [Env.MAP_BATTLE_SCENE.BRUNO] = Env.TERRAIN.BRUNO,
  [Env.MAP_BATTLE_SCENE.AGATHA] = Env.TERRAIN.AGATHA,
  [Env.MAP_BATTLE_SCENE.LANCE] = Env.TERRAIN.LANCE,
  [Env.MAP_BATTLE_SCENE.LINK] = Env.TERRAIN.LINK,
}

-- pret include/constants/trainers.h:267
local TRAINER_CLASS_LEADER = 84
local TRAINER_CLASS_CHAMPION = 90

-- pret src/battle_bg.c:439 sBattleTerrainTable
Env.TERRAIN_SHEET = {
  [Env.TERRAIN.GRASS] = "grass",
  [Env.TERRAIN.LONG_GRASS] = "long_grass",
  [Env.TERRAIN.SAND] = "sand",
  [Env.TERRAIN.UNDERWATER] = "underwater",
  [Env.TERRAIN.WATER] = "water",
  [Env.TERRAIN.POND] = "pond",
  [Env.TERRAIN.MOUNTAIN] = "mountain",
  [Env.TERRAIN.CAVE] = "cave",
  [Env.TERRAIN.BUILDING] = "building",
  [Env.TERRAIN.PLAIN] = "plain",
  [Env.TERRAIN.LINK] = "link",
  [Env.TERRAIN.GYM] = "gym",
  [Env.TERRAIN.LEADER] = "leader",
  [Env.TERRAIN.INDOOR_2] = "indoor_2",
  [Env.TERRAIN.INDOOR_1] = "indoor_1",
  [Env.TERRAIN.LORELEI] = "lorelei",
  [Env.TERRAIN.BRUNO] = "bruno",
  [Env.TERRAIN.AGATHA] = "agatha",
  [Env.TERRAIN.LANCE] = "lance",
  [Env.TERRAIN.CHAMPION] = "champion",
}

Env.SHEET_DEGRADE = {
  [Env.TERRAIN.GRASS] = { "plain" },
  [Env.TERRAIN.LONG_GRASS] = { "grass", "plain" },
  [Env.TERRAIN.SAND] = { "grass", "plain" },
  [Env.TERRAIN.UNDERWATER] = { "water", "pond" },
  [Env.TERRAIN.WATER] = { "pond", "grass" },
  [Env.TERRAIN.POND] = { "water", "grass" },
  [Env.TERRAIN.MOUNTAIN] = { "cave", "plain" },
  [Env.TERRAIN.CAVE] = { "mountain", "plain" },
  [Env.TERRAIN.BUILDING] = { "plain" },
  [Env.TERRAIN.PLAIN] = { "building" },
  [Env.TERRAIN.LINK] = { "building", "plain" },
  [Env.TERRAIN.GYM] = { "building", "plain" },
  [Env.TERRAIN.LEADER] = { "gym", "building" },
  [Env.TERRAIN.INDOOR_2] = { "indoor_1", "building" },
  [Env.TERRAIN.INDOOR_1] = { "indoor_2", "building" },
  [Env.TERRAIN.LORELEI] = { "indoor_1", "indoor_2", "building" },
  [Env.TERRAIN.BRUNO] = { "indoor_1", "indoor_2", "building" },
  [Env.TERRAIN.AGATHA] = { "indoor_1", "indoor_2", "building" },
  [Env.TERRAIN.LANCE] = { "indoor_1", "indoor_2", "building" },
  [Env.TERRAIN.CHAMPION] = { "leader", "indoor_1", "building" },
}

--- pret BattleSetup_GetTerrainId (simplified): indoor → BUILDING, else grass default outdoors.
function Env.resolveFromMapKind(kind)
  kind = kind or "town"
  if kind == "indoor" or kind == "building" or kind == "secret_base" then
    return Env.TERRAIN.BUILDING
  end
  if kind == "cave" or kind == "underground" then
    return Env.TERRAIN.CAVE
  end
  if kind == "water" or kind == "ocean" then
    return Env.TERRAIN.WATER
  end
  -- Routes / towns / field: tall grass battles use GRASS; default PLAIN→building tiles in pret.
  if kind == "route" or kind == "town" or kind == "city" then
    return Env.TERRAIN.GRASS
  end
  return Env.TERRAIN.BUILDING
end

-- pokefirered/include/constants/metatile_behaviors.h:4
local MB_TALL_GRASS = 0x02
local MB_INDOOR_ENCOUNTER = 0x0B
local MB_MOUNTAIN_TOP = 0x0C
local MB_FAST_WATER = 0x11
local MB_DEEP_WATER = 0x12
local MB_OCEAN_WATER = 0x15
local MB_SHALLOW_WATER = 0x17
local MB_SAND = 0x21
local MB_CYCLING_ROAD_PULL_DOWN_GRASS = 0xD1

-- pokefirered/src/metatile_behavior.c:432
local function is_tall_grass(beh)
  return beh == MB_TALL_GRASS or beh == MB_CYCLING_ROAD_PULL_DOWN_GRASS
end

-- pokefirered/src/metatile_behavior.c:80
local function is_sand_or_shallow_flowing_water(beh)
  return beh == MB_SAND or beh == MB_SHALLOW_WATER
end

-- pokefirered/src/metatile_behavior.c:518
local function is_deep_water_terrain(beh)
  return (beh >= MB_FAST_WATER and beh <= MB_DEEP_WATER) or beh == MB_OCEAN_WATER
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

--- pokefirered/src/battle_setup.c:466 BattleSetup_GetTerrainId
function Env.resolveFromBehavior(behavior, mapKind, mapType)
  local beh = tonumber(behavior)
  if beh == nil then return Env.resolveFromMapKind(mapKind) end
  local T = Env.TERRAIN
  local M = Env.MAP_TYPE
  local mt = tonumber(mapType) or KIND_MAP_TYPE[mapKind or "town"] or M.TOWN
  if is_tall_grass(beh) then return T.GRASS end
  if is_sand_or_shallow_flowing_water(beh) then return T.SAND end
  if mt == M.UNDERGROUND then
    if beh == MB_INDOOR_ENCOUNTER then return T.BUILDING end
    if Collision.isSurfable(beh) then return T.POND end
    return T.CAVE
  elseif mt == M.INDOOR or mt == M.SECRET_BASE then
    return T.BUILDING
  elseif mt == M.UNDERWATER then
    return T.UNDERWATER
  elseif mt == M.OCEAN_ROUTE then
    if Collision.isSurfable(beh) then return T.WATER end
    return T.PLAIN
  end
  if is_deep_water_terrain(beh) then return T.WATER end
  if Collision.isSurfable(beh) then return T.POND end
  if beh == MB_MOUNTAIN_TOP then return T.MOUNTAIN end
  return T.PLAIN
end

--- pokefirered/src/battle_bg.c:1048 GetBattleTerrainOverride
function Env.resolveOverride(terrainId, opts)
  opts = opts or {}
  local T = Env.TERRAIN
  local base = tonumber(terrainId) or T.PLAIN
  if opts.link or opts.trainerTower or opts.battleTower or opts.eReader then
    return T.LINK
  end
  if opts.pokedude then return T.GRASS end
  if opts.trainer then
    local cls = tonumber(opts.trainerClass)
    if cls == TRAINER_CLASS_LEADER then return T.LEADER end
    if cls == TRAINER_CLASS_CHAMPION then return T.CHAMPION end
  end
  local scene = tonumber(opts.mapBattleScene) or Env.MAP_BATTLE_SCENE.NORMAL
  if scene == Env.MAP_BATTLE_SCENE.NORMAL then return base end
  -- pokefirered/src/battle_bg.c:633 GetBattleTerrainByMapScene
  return SCENE_TERRAIN[scene] or T.PLAIN
end

return Env
