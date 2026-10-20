local GameVersion = require("src.core.GameVersion")
local VersionsGame = require("src.import.gba.versions_game")

local Versions = {}

local DEFAULT = "firered"
local active = DEFAULT
local mt = {}

local function isGame3(id)
  local info = GameVersion.VERSIONS[id]
  return info ~= nil and (info.generation or 1) == 3
end

local function resolve(identity)
  if type(identity) ~= "string" or identity == "" then
    error("versions: select needs a gen 3 version id or ROM sha1, got " .. tostring(identity), 3)
  end
  if isGame3(identity) then return identity end
  local key = identity:lower():gsub("%s+", "")
  local id = GameVersion.forSha1(key)
  if not id then
    local frlg = VersionsGame.game(DEFAULT)
    local sha = frlg.identitySha1 and frlg.identitySha1(key)
    id = sha and GameVersion.forSha1(sha) or nil
  end
  if not id or not isGame3(id) then
    error("versions: unknown gen 3 identity " .. identity, 3)
  end
  return id
end

local function bind(id)
  local mod = VersionsGame.game(id)
  active = id
  mt.__index = mod
  return mod
end

function Versions.select(identity)
  local id = resolve(identity)
  local mod = bind(id)
  if type(rawget(mod, "select")) == "function" then
    mod.select(isGame3(identity) and id or identity)
  end
  return id
end

function Versions.forGame(id)
  if not isGame3(id) then
    error("versions: not a gen 3 version id: " .. tostring(id), 2)
  end
  return VersionsGame.game(id)
end

function Versions.selectCache(id, cache)
  if id ~= "ruby" and id ~= "sapphire" then return Versions.select(id) end
  local raw = cache and cache:read("data/generated/gba/meta.json")
  assert(type(raw) == "string", "versions: missing native " .. id .. " cache identity")
  local sha1 = raw:match('"romSha1"%s*:%s*"([%x]+)"')
  local legacy = raw:match('"md5"%s*:%s*"([%x]+)"')
  local stampedId = raw:match('"version"%s*:%s*"([%w_]+)"')
  if sha1 then sha1 = sha1:lower() end
  if legacy then legacy = legacy:lower() end
  assert(not (sha1 and legacy) or sha1 == legacy, "versions: conflicting native cache identities")
  assert(not stampedId or stampedId == id, "versions: native cache edition mismatch")
  sha1 = sha1 or legacy
  assert(sha1 and GameVersion.acceptsSha1(id, sha1), "versions: unsupported native " .. id .. " cache identity")
  return Versions.select(sha1)
end

Versions["for"] = Versions.forGame

function Versions.active()
  return active
end

function Versions.module()
  return mt.__index
end

mt.__newindex = function(_, k, v)
  mt.__index[k] = v
end

bind(DEFAULT)
setmetatable(Versions, mt)

return Versions
