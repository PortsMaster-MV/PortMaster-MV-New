local Constants = require("src.core.game3.constants")

local MB = {}

MB.RSE_BASE = 0x100

-- pokeemerald/src/metatile_behavior.c:220
MB.RENAMES = {
  NO_RUNNING = "RUNNING_DISALLOWED",
  NO_SURFACING = "UNDERWATER_BLOCKED_ABOVE",
  NON_ANIMATED_DOOR = "CAVE_DOOR",
  ANIMATED_DOOR = "WARP_DOOR",
}

local ids = {}
local names = {}
local rseRaw = {}

local function strip(name)
  if type(name) ~= "string" then return nil end
  return (name:gsub("^MB_", ""))
end

local function sortedNames(byName)
  local list = {}
  for name, v in pairs(byName) do
    if name:match("^MB_") and type(v) == "number" then list[#list + 1] = name end
  end
  table.sort(list, function(a, b)
    if byName[a] ~= byName[b] then return byName[a] < byName[b] end
    return a < b
  end)
  return list
end

do
  local fr = Constants.of("firered").metatile_behaviors
  for _, full in ipairs(sortedNames(fr.byName)) do
    local name = strip(full)
    local v = fr.byName[full]
    ids[name] = v
    if names[v] == nil then names[v] = name end
  end
  for _, id in pairs(fr.byId.MB_ or {}) do
    local name = strip(id)
    if name and ids[name] then names[ids[name]] = name end
  end
  local em = Constants.of("emerald").metatile_behaviors
  for _, full in ipairs(sortedNames(em.byName)) do
    local name = strip(full)
    local raw = em.byName[full]
    if ids[name] == nil then
      local alias = MB.RENAMES[name]
      if alias and ids[alias] ~= nil then
        ids[name] = ids[alias]
      else
        local v = MB.RSE_BASE + raw
        ids[name] = v
        rseRaw[v] = raw
        if names[v] == nil then names[v] = name end
      end
    end
  end
  for _, full in pairs(em.byId.MB_ or {}) do
    local name = strip(full)
    local v = ids[name]
    if v and v >= MB.RSE_BASE then names[v] = name end
  end
end

for name, v in pairs(ids) do MB[name] = v end

function MB.id(name)
  return ids[strip(name)]
end

function MB.require(name)
  local v = ids[strip(name)]
  if v == nil then error("mb: unknown metatile behavior '" .. tostring(name) .. "'", 2) end
  return v
end

function MB.nameOf(id)
  return names[tonumber(id) or -1]
end

function MB.isRseOnly(id)
  id = tonumber(id)
  return id ~= nil and id >= MB.RSE_BASE
end

function MB.all()
  local out = {}
  for name, v in pairs(ids) do out[name] = v end
  return out
end

local translators = {}

function MB.translator(game)
  local GameVersion = require("src.core.GameVersion")
  local layout = GameVersion.layout(game)
  if layout == nil or layout == "frlg" then return nil end
  local t = translators[game]
  if t == nil then
    t = require("src.import.gba.mb_" .. game)
    translators[game] = t
  end
  return t
end

function MB.fromRaw(game, raw)
  local t = MB.translator(game)
  if not t then return raw end
  return t.canon(raw)
end

return MB
