local GameVersion = require("src.core.GameVersion")

local Profile = {}

Profile.FALLBACK_ID = "firered"

local cache = {}
local warned = {}

local function log(msg)
  print("[game3/profile] " .. tostring(msg))
end

local function load(id)
  local ok, row = pcall(require, "src.core.game3.profiles." .. id)
  if ok and type(row) == "table" and row.id == id then return row end
  return nil
end

function Profile.isGame3Version(id)
  local info = GameVersion.info(id)
  return info ~= nil and (info.generation or 1) == 3
end

local function loadGame3(id)
  local ok, row = pcall(require, "src.core.game3.profiles." .. id)
  if not ok then
    error("game3 profile '" .. id .. "' failed to load: " .. tostring(row), 0)
  end
  if type(row) ~= "table" or row.id ~= id then
    error("game3 profile '" .. id .. "' is missing or mislabeled", 0)
  end
  cache[id] = row
  return row
end

function Profile.of(id)
  if type(id) ~= "string" or id == "" then return Profile.active() end
  local row = cache[id]
  if row then return row end
  if Profile.isGame3Version(id) then return loadGame3(id) end
  row = load(id)
  if row then
    cache[id] = row
    return row
  end
  if id == Profile.FALLBACK_ID then
    error("game3 profile '" .. Profile.FALLBACK_ID .. "' is missing")
  end
  if not warned[id] then
    warned[id] = true
    log("no profile for '" .. id .. "'; using " .. Profile.active().id)
  end
  return Profile.active()
end

function Profile.resolveId(id)
  if type(id) ~= "string" or id == "" then id = GameVersion.get() end
  if Profile.isGame3Version(id) then return id end
  return Profile.FALLBACK_ID
end

function Profile.active()
  local id = Profile.resolveId(GameVersion.get())
  local row = cache[id]
  if row then return row end
  return loadGame3(id)
end

function Profile.sessionVersion(session)
  if type(session) == "table" and type(session.version) == "string" and session.version ~= "" then
    return session.version
  end
  if session == nil then
    local Runtime = package.loaded["src.core.game3.runtime"]
    local live = Runtime and type(Runtime.getSession) == "function" and Runtime.getSession() or nil
    if type(live) == "table" and type(live.version) == "string" and live.version ~= "" then
      return live.version
    end
  end
  return nil
end

function Profile.forSession(session)
  local id = Profile.sessionVersion(session)
  if id then return Profile.of(id) end
  return Profile.active()
end

function Profile.family(session)
  return Profile.forSession(session).family or "frlg"
end

function Profile.capabilitiesFor(session)
  local id = type(session) == "table" and session.version or nil
  return Profile.of(id).capabilities or {}
end

function Profile.has(session, capability)
  return Profile.capabilitiesFor(session)[capability] == true
end

function Profile.reset()
  cache = {}
  warned = {}
end

return Profile
