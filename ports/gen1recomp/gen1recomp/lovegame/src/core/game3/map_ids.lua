-- Shared Game3 map-id helpers (Fire Red FR_* and legacy Sevii SEVII_*).

local Profile = require("src.core.game3.profile")

local MapIds = {}

function MapIds.isGame3Map(mapId, gameId)
  if type(mapId) ~= "string" then return false end
  for _, prefix in ipairs(Profile.of(gameId).map.prefixes) do
    if mapId:sub(1, #prefix) == prefix then return true end
  end
  local ok, MapCatalog = pcall(require, "src.import.gba.map_catalog")
  if ok and MapCatalog and MapCatalog.isKnown then
    return MapCatalog.isKnown(mapId)
  end
  return false
end

MapIds.NEW_GAME_START = {
  map = "FR_PLAYERS_HOUSE_2F",
  x = 6,
  y = 6,
  facing = "down",
  -- Whiteout / heal: pret HEAL_LOCATION_PALLET_TOWN → PlayersHouse_1F (8,5) by Mom.
  healMap = "FR_PLAYERS_HOUSE_1F",
  healX = 8,
  healY = 5,
}

MapIds.PALLET_TOWN = "FR_PALLET_TOWN"
MapIds.ROUTE_1 = "FR_ROUTE_1"

function MapIds.newGameStart(gameId)
  local map = Profile.of(gameId).map
  return map and map.newGameStart or MapIds.NEW_GAME_START
end

function MapIds.forConst(constName, gameId)
  if type(constName) ~= "string" then return nil end
  local GameVersion = require("src.core.GameVersion")
  gameId = gameId or GameVersion.get()
  local ok, C = pcall(function() return require("src.core.game3.constants").of(gameId) end)
  if not ok then return nil end
  local row = C.map_groups.byName[constName]
  if not row then return nil end
  if GameVersion.layout(gameId) == "rse" then
    return Profile.of(gameId).map.enginePrefix .. constName:gsub("^MAP_", "")
  end
  local okC, MapCatalog = pcall(require, "src.import.gba.map_catalog")
  return okC and MapCatalog.mapIdFor(row.group, row.num) or nil
end

return MapIds
