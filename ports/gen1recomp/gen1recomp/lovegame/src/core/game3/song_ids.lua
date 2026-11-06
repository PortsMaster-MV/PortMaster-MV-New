local Constants = require("src.core.game3.constants")

local Song = {}

local byGame = {}

local function isSongName(k)
  return type(k) == "string" and (k:find("^MUS_") or k:find("^SE_") or k:find("^PH_")) ~= nil
end

function Song.forVersion(id)
  local game = Constants.gameKey(id)
  local t = byGame[game]
  if not t then
    t = {}
    for k, v in pairs(Constants.of(game).songs.byName) do
      if isSongName(k) then t[k] = v end
    end
    byGame[game] = t
  end
  return t
end

function Song.select(id)
  local t = Song.forVersion(id)
  for k in pairs(Song) do
    if isSongName(k) and t[k] == nil then Song[k] = nil end
  end
  for k, v in pairs(t) do Song[k] = v end
  Song.current = Constants.gameKey(id)
  return Song
end

function Song.resolve(id)
  if id == nil then return nil end
  if type(id) == "number" then return id end
  local s = tostring(id):gsub("^%s+", ""):gsub("%s+$", "")
  local n = tonumber(s)
  if n then return n end
  return Song[s] or Song[s:upper()]
end

function Song.nameOf(id, game)
  local rev = Constants.of(game or Song.current).songs.byId
  return (rev.MUS_ and rev.MUS_[id]) or (rev.SE_ and rev.SE_[id]) or (rev.PH_ and rev.PH_[id])
end

Song.byName = Song
Song.select("firered")

return Song
