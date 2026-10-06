local Constants = require("src.core.game3.constants")

local MovementTypes = {}

MovementTypes.RSE_BASE = 0x100
MovementTypes.PREFIX = "MOVEMENT_TYPE_"
MovementTypes.CANON_GAME = "firered"

-- pokeemerald/src/event_object_movement.c:4442
-- pokefirered/src/event_object_movement.c:4521
MovementTypes.ALIASES = {
  MOVEMENT_TYPE_JOG_IN_PLACE_DOWN = "MOVEMENT_TYPE_WALK_IN_PLACE_FAST_DOWN",
  MOVEMENT_TYPE_JOG_IN_PLACE_UP = "MOVEMENT_TYPE_WALK_IN_PLACE_FAST_UP",
  MOVEMENT_TYPE_JOG_IN_PLACE_LEFT = "MOVEMENT_TYPE_WALK_IN_PLACE_FAST_LEFT",
  MOVEMENT_TYPE_JOG_IN_PLACE_RIGHT = "MOVEMENT_TYPE_WALK_IN_PLACE_FAST_RIGHT",
  -- pokeemerald/src/event_object_movement.c:4452
  -- pokefirered/src/event_object_movement.c:4531
  MOVEMENT_TYPE_RUN_IN_PLACE_DOWN = "MOVEMENT_TYPE_JOG_IN_PLACE_DOWN",
  MOVEMENT_TYPE_RUN_IN_PLACE_UP = "MOVEMENT_TYPE_JOG_IN_PLACE_UP",
  MOVEMENT_TYPE_RUN_IN_PLACE_LEFT = "MOVEMENT_TYPE_JOG_IN_PLACE_LEFT",
  MOVEMENT_TYPE_RUN_IN_PLACE_RIGHT = "MOVEMENT_TYPE_JOG_IN_PLACE_RIGHT",
}

local tables = {}

local function names(game)
  local t = Constants.of(game).movement
  return assert(t.byId and t.byId[MovementTypes.PREFIX], "movement constants have no types for " .. game)
end

local function build(game)
  local key = Constants.gameKey(game)
  local hit = tables[key]
  if hit then return hit end
  local fr = Constants.of(MovementTypes.CANON_GAME)
  local toCanon, nameOf = {}, {}
  for raw, name in pairs(names(key)) do
    local v
    if key == MovementTypes.CANON_GAME then
      v = raw
    else
      v = fr:id("movement", MovementTypes.ALIASES[name] or name)
      if v == nil then v = MovementTypes.RSE_BASE + raw end
    end
    toCanon[raw] = v
    nameOf[v] = name
  end
  hit = { game = key, toCanon = toCanon, nameOf = nameOf }
  tables[key] = hit
  return hit
end

function MovementTypes.canon(game, raw)
  raw = tonumber(raw)
  if raw == nil then return nil end
  if raw >= MovementTypes.RSE_BASE then return raw end
  local v = build(game).toCanon[raw]
  if v == nil then return raw end
  return v
end

function MovementTypes.nameOf(game, canonId)
  return build(game).nameOf[tonumber(canonId) or -1]
end

function MovementTypes.canonOf(game, name)
  local raw = Constants.of(game):id("movement", name)
  if raw == nil then return nil end
  return MovementTypes.canon(game, raw)
end

function MovementTypes.isRseOnly(id)
  id = tonumber(id)
  return id ~= nil and id >= MovementTypes.RSE_BASE
end

return MovementTypes
