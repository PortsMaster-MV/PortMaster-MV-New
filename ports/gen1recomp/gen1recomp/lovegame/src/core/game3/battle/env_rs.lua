local MB = require("src.core.game3.mb")
local Profile = require("src.core.game3.profile")
local M = { family = "rse" }
local C = require("src.core.game3.constants").of("ruby")

M.ENVIRONMENT = {}
for _, name in ipairs({"GRASS", "LONG_GRASS", "SAND", "UNDERWATER", "WATER", "POND",
  "MOUNTAIN", "CAVE", "BUILDING", "PLAIN"}) do
  M.ENVIRONMENT[name] = assert(C.battle.byName["BATTLE_ENVIRONMENT_" .. name])
end
-- pokeruby/src/battle_bg.c:280
M.SCENE = { TOWER = 10, GROUDON = 11, KYOGRE = 12, LEADER = 14, CHAMPION = 15,
  GYM = 16, MAGMA = 17, AQUA = 18, SIDNEY = 19, PHOEBE = 20, GLACIA = 21, DRAKE = 22 }
M.TERRAIN, M.ENVIRONMENT_SHEET, M.SCENE_SHEET, M.TERRAIN_SHEET = {}, {}, {}, {}
for name, id in pairs(M.ENVIRONMENT) do
  M.TERRAIN[name], M.ENVIRONMENT_SHEET[id], M.TERRAIN_SHEET[id] = id, name:lower(), name:lower()
end
for name, id in pairs(M.SCENE) do
  M.TERRAIN[name], M.SCENE_SHEET[id], M.TERRAIN_SHEET[id] = id, name:lower(), name:lower()
end
M.MAP_TYPE = {NONE = 0, TOWN = 1, CITY = 2, ROUTE = 3, UNDERGROUND = 4,
  UNDERWATER = 5, OCEAN_ROUTE = 6, UNKNOWN = 7, INDOOR = 8, SECRET_BASE = 9}
M.MAP_BATTLE_SCENE = {NORMAL = 0, GYM = 1, MAGMA = 2, AQUA = 3, SIDNEY = 4,
  PHOEBE = 5, GLACIA = 6, DRAKE = 7, BATTLE_TOWER = 8}
local scenes = {[1] = M.SCENE.GYM, [2] = M.SCENE.MAGMA, [3] = M.SCENE.AQUA,
  [4] = M.SCENE.SIDNEY, [5] = M.SCENE.PHOEBE, [6] = M.SCENE.GLACIA,
  [7] = M.SCENE.DRAKE, [8] = M.SCENE.TOWER}
local kindTypes = {town = 1, city = 2, route = 3, cave = 4, underground = 4,
  water = 6, ocean = 6, indoor = 8, building = 8, secret_base = 9}

function M.sheetFor(id, manifest)
  id = tonumber(id)
  return manifest and manifest.environments and manifest.environments[id] or M.TERRAIN_SHEET[id]
end
function M.isEnvironment(id) return M.ENVIRONMENT_SHEET[tonumber(id)] ~= nil end
function M.setTileBits(bits) M._tileBits = bits end
function M.isSurfable(b)
  local Coll = package.loaded["src.core.game3.scripting.collision_rse"]
  local bits = M._tileBits or (Coll and Coll._tileBits)
  return bits and bits[b] ~= nil and math.floor(bits[b] / 2) % 2 == 1 or false
end
function M.resolveFromMapKind(kind)
  local t, E = kindTypes[kind], M.ENVIRONMENT
  if t == 8 or t == 9 then return E.BUILDING end
  if t == 4 then return E.CAVE end
  if t == 6 then return E.WATER end
  if t == 1 or t == 2 or t == 3 then return E.GRASS end
  return E.BUILDING
end

-- pokeruby/src/battle_setup.c:650
function M.resolveFromBehavior(behavior, mapKind, mapType, ctx)
  local b = tonumber(behavior)
  if b == nil then return M.resolveFromMapKind(mapKind) end
  local game = Profile.forSession().id
  local raw = MB.translator(game).raw(b)
  local E, mt = M.ENVIRONMENT, tonumber(mapType) or kindTypes[mapKind] or 1
  if raw == 0x02 then return E.GRASS end
  if raw == 0x03 then return E.LONG_GRASS end
  if raw == 0x21 or raw == 0x06 then return E.SAND end
  if mt == 4 then
    if raw == 0x0B then return E.BUILDING end
    return M.isSurfable(b) and E.POND or E.CAVE
  elseif mt == 8 or mt == 9 then return E.BUILDING
  elseif mt == 5 then return E.UNDERWATER
  elseif mt == 6 then return M.isSurfable(b) and E.WATER or E.PLAIN end
  if raw == 0x15 or raw == 0x11 or raw == 0x12 then return E.WATER end
  if M.isSurfable(b) then return E.POND end
  if raw == 0x0C then return E.MOUNTAIN end
  if ctx == nil then
    local Player = package.loaded["src.core.game3.player"]
    local Map = package.loaded["src.core.game3.map"]
    local Weather = package.loaded["src.core.game3.weather"]
    ctx = {surfing = Player and Player.surfing, mapId = Map and Map.current,
      weather = Weather and Weather.getSaved()}
  end
  if ctx.surfing and raw and raw >= 0x70 and raw <= 0x73 then
    return raw == 0x70 and E.WATER or E.POND
  end
  if ctx.mapId ~= nil and ctx.mapId == require("src.core.game3.map_ids").forConst("MAP_ROUTE113", game) then
    return E.SAND
  end
  if tonumber(ctx.weather) == 8 then return E.SAND end
  return E.PLAIN
end

function M.resolveOverride(environment, opts)
  opts = opts or {}
  local kinds, S = opts.kinds or {}, M.SCENE
  local function has(k) return opts[k] or kinds[k] end
  if has("link") or has("battleTower") or has("eReader") then return S.TOWER end
  if has("kyogreGroudon") or has("groudon") or has("kyogre") then
    return Profile.forSession().id == "sapphire" and S.KYOGRE or S.GROUDON
  end
  if opts.trainer then
    if tonumber(opts.trainerClass) == 25 then return S.LEADER end
    if tonumber(opts.trainerClass) == 32 then return S.CHAMPION end
  end
  return scenes[tonumber(opts.mapBattleScene) or 0] or tonumber(environment) or M.ENVIRONMENT.PLAIN
end

return M
