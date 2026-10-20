local Constants = require("src.core.game3.constants")

local function build(game)
local Ids = {}

Ids.family = "rse"
Ids.GAME = game

local function C() return Constants.of(Ids.GAME) end

-- pokeemerald/include/battle_transition.h:23
local ID = {}
for name, v in pairs(C().battle.byName) do
  local short = name:match("^B_TRANSITION_(.+)$")
  if short and not short:match("^GROUP_") and short ~= "COUNT" then ID[short] = v end
end
Ids.ID = ID
local rs = game == "ruby" or game == "sapphire"
if rs then
  ID.CLOCKWISE_WIPE, ID.WHITE_BARS_FADE, ID.ANGLED_WIPES = ID.CLOCKWISE_BLACKFADE, ID.WHITEFADE, ID.SHARDS
  ID.SIDNEY, ID.CHAMPION = ID.SYDNEY, ID.STEVEN
end

-- pokeemerald/src/battle_setup.c:696
local TERRAIN = {
  NORMAL = 0,
  CAVE = 1,
  FLASH = 2,
  WATER = 3,
}
Ids.TERRAIN = TERRAIN

-- pokeemerald/src/battle_setup.c:114
local TABLE_WILD = {
  [TERRAIN.NORMAL] = { ID.SLICE, ID.WHITE_BARS_FADE },
  [TERRAIN.CAVE]   = { ID.CLOCKWISE_WIPE, ID.GRID_SQUARES },
  [TERRAIN.FLASH]  = { ID.BLUR, ID.GRID_SQUARES },
  [TERRAIN.WATER]  = { ID.WAVE, ID.RIPPLE },
}

-- pokeemerald/src/battle_setup.c:122
local TABLE_TRAINER = {
  [TERRAIN.NORMAL] = { ID.POKEBALLS_TRAIL, ID.ANGLED_WIPES },
  [TERRAIN.CAVE]   = { ID.SHUFFLE, ID.BIG_POKEBALL },
  [TERRAIN.FLASH]  = { ID.BLUR, ID.GRID_SQUARES },
  [TERRAIN.WATER]  = { ID.SWIRL, ID.RIPPLE },
}

-- pokeemerald/src/battle_setup.c:131
Ids.TABLE_FRONTIER = {
  ID.FRONTIER_LOGO_WIGGLE, ID.FRONTIER_LOGO_WAVE, ID.FRONTIER_SQUARES, ID.FRONTIER_SQUARES_SCROLL,
  ID.FRONTIER_CIRCLES_MEET, ID.FRONTIER_CIRCLES_CROSS, ID.FRONTIER_CIRCLES_ASYMMETRIC_SPIRAL,
  ID.FRONTIER_CIRCLES_SYMMETRIC_SPIRAL, ID.FRONTIER_CIRCLES_MEET_IN_SEQ, ID.FRONTIER_CIRCLES_CROSS_IN_SEQ,
  ID.FRONTIER_CIRCLES_ASYMMETRIC_SPIRAL_IN_SEQ, ID.FRONTIER_CIRCLES_SYMMETRIC_SPIRAL_IN_SEQ,
}
-- pokeemerald/src/battle_setup.c:147
Ids.TABLE_PYRAMID = { ID.FRONTIER_SQUARES, ID.FRONTIER_SQUARES_SCROLL, ID.FRONTIER_SQUARES_SPIRAL }
-- pokeemerald/src/battle_setup.c:154
Ids.TABLE_DOME = { ID.FRONTIER_LOGO_WIGGLE, ID.FRONTIER_SQUARES, ID.FRONTIER_SQUARES_SCROLL,
  ID.FRONTIER_SQUARES_SPIRAL }

-- pokeemerald/include/battle_transition.h:14
Ids.MUGSHOT_BY_ID = {
  [ID.SIDNEY] = "sidney",
  [ID.PHOEBE] = "phoebe",
  [ID.GLACIA] = "glacia",
  [ID.DRAKE] = "drake",
  [ID.CHAMPION] = "champion",
}
Ids.MUGSHOT_ORDER = { "sidney", "phoebe", "glacia", "drake", "champion" }

-- pokeemerald/src/battle_transition.c:2588
Ids.MUGSHOT_PLAYER_PIC = {
  male = C().trainer_classes.byName.TRAINER_PIC_BRENDAN,
  female = C().trainer_classes.byName.TRAINER_PIC_MAY,
}

function Ids.mugshotTables(manifest)
  local m = type(manifest) == "table" and manifest or {}
  local pics, coords, scales = {}, {}, {}
  for i, key in ipairs(Ids.MUGSHOT_ORDER) do
    pics[key] = m.mugshotTrainerPics and m.mugshotTrainerPics[i]
    coords[key] = m.mugshotCoords and m.mugshotCoords[i]
    scales[key] = m.mugshotRotationScales and m.mugshotRotationScales[i]
  end
  return pics, coords, scales
end

local function liveMapType()
  local Map = package.loaded["src.core.game3.map"]
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local def = Map and game and game.data and game.data.maps and game.data.maps[Map.current]
  return def and tonumber(def.mapType) or nil
end

local function liveBehavior()
  local Player = package.loaded["src.core.game3.player"]
  local Collision = package.loaded["src.core.game3.collision"]
  if not (Player and Collision and Collision.behavior) then return nil end
  local x, y = Player.cellX, Player.cellY
  if Player.moving then x, y = Player.targetX, Player.targetY end
  return Collision.behavior(x, y)
end

-- pokeemerald/include/constants/map_types.h:8
local MAP_TYPE_UNDERGROUND = 4
local MAP_TYPE_UNDERWATER = 5

-- pokeemerald/src/battle_setup.c:696
function Ids.getTerrainByMap(opts)
  opts = opts or {}
  if opts.flash or (tonumber(opts.flashLevel) or 0) > 0 then return TERRAIN.FLASH end
  local behavior = opts.mapBehavior
  if behavior == nil then behavior = liveBehavior() end
  local EnvRse = require("src.core.game3.battle.env_rse")
  if behavior ~= nil and EnvRse.isSurfable(behavior) then return TERRAIN.WATER end
  local mapType = tonumber(opts.mapType) or liveMapType()
  if mapType == MAP_TYPE_UNDERGROUND then return TERRAIN.CAVE end
  if mapType == MAP_TYPE_UNDERWATER then return TERRAIN.WATER end
  return TERRAIN.NORMAL
end

-- pokeemerald/src/battle_setup.c:790
function Ids.pickWild(opts)
  opts = opts or {}
  local playerLv = tonumber(opts.playerLevel) or 5
  local enemyLv = tonumber(opts.enemyLevel) or 3
  if opts.pyramid then
    return enemyLv < playerLv and ID.BLUR or ID.GRID_SQUARES
  end
  local terrain = opts.terrain or Ids.getTerrainByMap(opts)
  local row = TABLE_WILD[terrain] or TABLE_WILD[TERRAIN.NORMAL]
  if enemyLv < playerLv then return row[1] end
  return row[2]
end

local function classIn(cls, names)
  if cls == nil then return false end
  local byName = C().trainer_classes.byName
  for _, n in ipairs(names) do
    if byName[n] == cls then return true end
  end
  return false
end

-- pokeemerald/include/constants/trainers.h:14
Ids.TRAINER_SECRET_BASE = 1024

-- pokeemerald/src/battle_setup.c:812
function Ids.pickTrainer(opts)
  opts = opts or {}
  local trainers = C().trainers.byName
  local tid = tonumber(opts.trainerId)
  if tid == Ids.TRAINER_SECRET_BASE then return ID.CHAMPION end
  local cls = tonumber(opts.trainerClass)
  if classIn(cls, { "TRAINER_CLASS_ELITE_FOUR" }) then
    if tid == trainers.TRAINER_SIDNEY then return ID.SIDNEY end
    if tid == trainers.TRAINER_PHOEBE then return ID.PHOEBE end
    if tid == trainers.TRAINER_GLACIA then return ID.GLACIA end
    if tid == trainers.TRAINER_DRAKE then return ID.DRAKE end
    return ID.CHAMPION
  end
  if classIn(cls, { "TRAINER_CLASS_CHAMPION" }) then return ID.CHAMPION end
  if not rs and classIn(cls, { "TRAINER_CLASS_TEAM_MAGMA", "TRAINER_CLASS_MAGMA_LEADER", "TRAINER_CLASS_MAGMA_ADMIN" }) then
    return ID.MAGMA
  end
  if not rs and classIn(cls, { "TRAINER_CLASS_TEAM_AQUA", "TRAINER_CLASS_AQUA_LEADER", "TRAINER_CLASS_AQUA_ADMIN" }) then
    return ID.AQUA
  end
  local terrain = opts.terrain or Ids.getTerrainByMap(opts)
  local row = TABLE_TRAINER[terrain] or TABLE_TRAINER[TERRAIN.NORMAL]
  local playerLv = tonumber(opts.playerLevel) or 5
  local enemyLv = tonumber(opts.enemyLevel) or 3
  if enemyLv < playerLv then return row[1] end
  return row[2]
end

-- pokeemerald/src/battle_setup.c:864
function Ids.pickSpecial(group, opts)
  opts = opts or {}
  local rand = opts.random or math.random
  local function pickFrom(t) return t[(rand(#t * 65536) % #t) + 1] end
  local playerLv = tonumber(opts.playerLevel) or 5
  local enemyLv = tonumber(opts.enemyLevel) or 3
  if group == "trainer_hill" or group == "secret_base" or group == "e_reader" or group == "battle_tower" then
    return enemyLv < playerLv and ID.POKEBALLS_TRAIL or ID.BIG_POKEBALL
  end
  if rs then error("RS has no transition group " .. tostring(group)) end
  if group == "pyramid" then return pickFrom(Ids.TABLE_PYRAMID) end
  if group == "dome" then return pickFrom(Ids.TABLE_DOME) end
  return pickFrom(Ids.TABLE_FRONTIER)
end

-- pokeemerald/src/battle_transition.c:1121
Ids.TUNE = {
  introFades = 3,
  blurDelay = 4,
  wipeStepX = 16,
  wipeStepY = 8,
  rippleFadeAt = 81,
  rippleFadeDelay = -2,
}

return Ids
end

local cache = {}
local function forVersion(version)
  local game = require("src.core.game3.profile").resolveId(version)
  if game ~= "ruby" and game ~= "sapphire" then game = "emerald" end
  if not cache[game] then cache[game] = build(game) end
  return cache[game]
end
local Ids = build("emerald")
cache.emerald = Ids
Ids.forVersion = forVersion
return Ids
