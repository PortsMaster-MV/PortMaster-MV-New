local Constants = require("src.core.game3.constants")

local MovementEmerald = {}

MovementEmerald.RSE_BASE = 0x100
MovementEmerald.PREFIX = "MOVEMENT_ACTION_"
MovementEmerald.REFERENCE_GAME = "emerald"
MovementEmerald.CANON_GAME = "firered"

local canon

local function actions(game)
  local t = Constants.of(game).movement
  return assert(t.byId and t.byId[MovementEmerald.PREFIX], "movement constants have no actions for " .. game)
end

local function build_canon()
  if canon then return canon end
  local fr = Constants.of(MovementEmerald.CANON_GAME)
  local byName, byId = {}, {}
  for id, name in pairs(actions(MovementEmerald.CANON_GAME)) do
    local v = fr:id("movement", name)
    byName[name] = v
    byId[v] = name
  end
  local ref = actions(MovementEmerald.REFERENCE_GAME)
  local ids = {}
  for id in pairs(ref) do ids[#ids + 1] = id end
  table.sort(ids)
  local nextId = MovementEmerald.RSE_BASE
  for _, id in ipairs(ids) do
    local name = ref[id]
    if byName[name] == nil then
      byName[name] = nextId
      byId[nextId] = name
      nextId = nextId + 1
    end
  end
  canon = { byName = byName, byId = byId, rseCount = nextId - MovementEmerald.RSE_BASE }
  return canon
end

function MovementEmerald.canon()
  return build_canon()
end

function MovementEmerald.canonOf(name)
  return build_canon().byName[name]
end

function MovementEmerald.nameOf(canonId)
  return build_canon().byId[canonId]
end

local tables = {}

function MovementEmerald.forGame(game)
  game = game or MovementEmerald.REFERENCE_GAME
  local key = Constants.gameKey(game)
  local T = tables[key]
  if T then return T end
  local c = build_canon()
  local toCanon, names = {}, {}
  local count = 0
  for raw, name in pairs(actions(key)) do
    local canonicalName = name
    if key == "ruby" then
      canonicalName = name:gsub("^MOVEMENT_ACTION_WALK_IN_PLACE_FASTEST_", "MOVEMENT_ACTION_WALK_IN_PLACE_FASTER_")
        :gsub("^MOVEMENT_ACTION_WALK_FASTEST_", "MOVEMENT_ACTION_WALK_FASTER_")
        :gsub("^MOVEMENT_ACTION_WALK_DOWN_AFFINE_1$", "MOVEMENT_ACTION_WALK_DOWN_AFFINE")
    end
    local v = c.byName[canonicalName]
    if v ~= nil then
      toCanon[raw] = v
      names[raw] = name
      count = count + 1
    end
  end
  T = { game = key, toCanon = toCanon, names = names, count = count }
  T.stepEnd = Constants.of(key):require("movement", "MOVEMENT_ACTION_STEP_END")

  function T.translate(bytes)
    local out, unknown = {}, nil
    for i = 1, #bytes do
      local b = bytes[i]
      local v = toCanon[b]
      if v == nil then
        unknown = unknown or {}
        unknown[#unknown + 1] = b
        v = b
      end
      out[i] = v
    end
    return out, unknown
  end

  tables[key] = T
  return T
end

return MovementEmerald
