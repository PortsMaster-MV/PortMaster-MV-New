local Family = require("src.import.gba.family")

local Collision = {}

local impls = {}

function Collision.impl(familyName)
  local name = familyName or Family.active().name
  local m = impls[name]
  if not m then
    m = require("src.core.game3.scripting.collision_" .. name)
    impls[name] = m
  end
  return m
end

function Collision.classify(mid, mapColl, behavior, kind)
  return Collision.impl().classify(mid, mapColl, behavior, kind)
end

function Collision.seed(category, ledgeDir, kind)
  return Collision.impl().seed(category, ledgeDir, kind)
end

function Collision.fromCell(mid, mapColl, behavior, kind)
  return Collision.impl().fromCell(mid, mapColl, behavior, kind)
end

return Collision
