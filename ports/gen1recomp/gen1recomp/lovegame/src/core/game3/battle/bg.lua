-- FRLG battle background / terrain selection (pret battle_setup + battle_bg).
-- One place: map kind / opts → terrain id → baked RGBA. UI and bridge both use this.

local BattleChrome = require("src.ui.game3.battle_chrome")

local BattleBg = {}

local ENV_MODULES = {
  frlg = "src.core.game3.battle.env_frlg",
  rse = "src.core.game3.battle.env_rse",
}

function BattleBg.env(family)
  if family == nil then
    local bp = require("src.core.game3.battle.profile").get()
    if bp.environmentModule then return require(bp.environmentModule) end
  end
  family = family or require("src.core.game3.profile").family()
  local module = ENV_MODULES[family]
  if not module then error("battle bg: no environment module for family '" .. tostring(family) .. "'") end
  return require(module)
end

local ENV_FIELDS = { TERRAIN = true, MAP_TYPE = true, MAP_BATTLE_SCENE = true }

setmetatable(BattleBg, {
  __index = function(_, k)
    if ENV_FIELDS[k] then return BattleBg.env()[k] end
    return nil
  end,
})

BattleBg._terrainId = BattleBg.TERRAIN.BUILDING
BattleBg._sheets = nil

function BattleBg.resolveFromMapKind(kind)
  return BattleBg.env().resolveFromMapKind(kind)
end

function BattleBg.resolveFromBehavior(behavior, mapKind, mapType, ctx)
  return BattleBg.env().resolveFromBehavior(behavior, mapKind, mapType, ctx)
end

function BattleBg.resolveOverride(terrainId, opts)
  return BattleBg.env().resolveOverride(terrainId, opts)
end

function BattleBg.setTerrain(id)
  BattleBg._terrainId = tonumber(id) or BattleBg.TERRAIN.BUILDING
end

function BattleBg.terrainId()
  return BattleBg._terrainId
end

function BattleBg.availableSheets()
  if BattleBg._sheets then return BattleBg._sheets end
  local loaded = BattleChrome._terrains
  if type(loaded) == "table" and next(loaded) then return loaded end
  local m = BattleChrome._manifest
  local baked = type(m) == "table" and m.terrains
  if type(baked) == "table" and next(baked) then return baked end
  return nil
end

function BattleBg.setAvailableSheets(set)
  BattleBg._sheets = set
end

local function frlgSheetKey(env, id)
  local primary = env.TERRAIN_SHEET[id]
  if not primary then return "building" end
  local have = BattleBg.availableSheets()
  if not have then return primary end
  if have[primary] then return primary end
  for _, key in ipairs(env.SHEET_DEGRADE[id] or {}) do
    if have[key] then return key end
  end
  if have.building then return "building" end
  if have.grass then return "grass" end
  return primary
end

function BattleBg.resolveOpts(opts)
  local terrain = opts.terrain
  -- pokefirered/src/battle_main.c:689
  if terrain == nil and (opts.mapBehavior ~= nil or opts.mapType ~= nil) then
    terrain = BattleBg.resolveFromBehavior(opts.mapBehavior, opts.mapKind, opts.mapType)
  end
  if terrain == nil and opts.mapKind then
    terrain = BattleBg.resolveFromMapKind(opts.mapKind)
  end
  if terrain == nil then
    terrain = BattleBg.TERRAIN.BUILDING
  end
  return terrain
end

function BattleBg.sheetKey(id)
  id = tonumber(id) or BattleBg._terrainId
  local env = BattleBg.env()
  if not env.sheetFor then return frlgSheetKey(env, id) end
  local key = env.sheetFor(id, BattleChrome.manifest())
  if not key then error("battle bg: no background for terrain id " .. tostring(id)) end
  return key
end

function BattleBg.draw(id, enemyOx, playerOx, bgOx)
  local key = BattleBg.sheetKey(id)
  return BattleChrome.drawTerrain(key, enemyOx, playerOx, bgOx)
end

return BattleBg
