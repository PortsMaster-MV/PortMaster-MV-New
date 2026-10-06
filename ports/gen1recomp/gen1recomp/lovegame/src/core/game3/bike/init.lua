local Bike = {}

-- pokeemerald/src/bike.c:127 MovePlayerOnBike
function Bike.rse(session)
  local Capabilities = package.loaded["src.core.game3.capabilities"] or require("src.core.game3.capabilities")
  if not Capabilities.has(session, "machAcroBike") then return nil end
  return package.loaded["src.core.game3.bike.rse"] or require("src.core.game3.bike.rse")
end

return Bike
