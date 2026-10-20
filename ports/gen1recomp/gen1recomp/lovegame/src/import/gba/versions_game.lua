local GameVersion = require("src.core.GameVersion")

local VersionsGame = {}

VersionsGame.GAMES = {
  firered = "src.import.gba.versions_frlg",
  leafgreen = "src.import.gba.versions_frlg",
  emerald = "src.import.gba.games.emerald",
  ruby = "src.import.gba.games.ruby",
  sapphire = "src.import.gba.games.sapphire",
}

VersionsGame.FALLBACK = "firered"

local cache = {}

local function load(id)
  local path = VersionsGame.GAMES[id]
  if type(path) ~= "string" or path == "" then
    return nil, "no version table registered for '" .. tostring(id) .. "'"
  end
  local ok, mod = pcall(require, path)
  if ok and type(mod) == "table" then return mod end
  return nil, "version table '" .. path .. "' for '" .. tostring(id) .. "' does not load: " .. tostring(mod)
end

function VersionsGame.game(id)
  if type(id) ~= "string" or id == "" then
    local active = GameVersion.get()
    local info = GameVersion.info(active)
    id = (info and (info.generation or 1) == 3) and active or VersionsGame.FALLBACK
  end
  local row = cache[id]
  if row then return row end
  local mod, err = load(id)
  if not mod then error("versions_game: " .. err, 2) end
  cache[id] = mod
  return mod
end

function VersionsGame.register(id, modulePath)
  if type(id) ~= "string" or id == "" then return false end
  if type(modulePath) ~= "string" or modulePath == "" then return false end
  VersionsGame.GAMES[id] = modulePath
  cache[id] = nil
  return true
end

function VersionsGame.reset()
  cache = {}
end

return VersionsGame
