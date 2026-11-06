local Catalog = {}

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

-- Gen 2's generated tables carry provenance scalars (generation, source)
-- beside the id-keyed records, so a wheel built from every key would offer
-- them as pickable entries.  #1466
local function sortedRecordKeys(t)
  local keys = {}
  for k, v in pairs(t or {}) do
    if type(k) == "string" and type(v) == "table" then
      table.insert(keys, k)
    end
  end
  table.sort(keys)
  return keys
end

-- ROM registries expose both numeric ids and named aliases. Pick one stable
-- string key per native record so the picker never lists the same item twice.
local function nativeKeys(records, idField)
  local byId, other = {}, {}
  for key, def in pairs(records or {}) do
    if type(key) == "string" and type(def) == "table" then
      local id = tonumber(def[idField] or def.id)
      if id and id > 0 then
        local name = tostring(def.name or key)
        if name ~= "" and not name:match("^%?+$") then
          local prior = byId[id]
          if
            not prior
            or (tonumber(prior) and not tonumber(key))
            or ((tonumber(prior) ~= nil) == (tonumber(key) ~= nil) and key < prior)
          then
            byId[id] = key
          end
        end
      elseif id == nil then
        other[#other + 1] = key
      end
    end
  end
  for _, key in pairs(byId) do
    other[#other + 1] = key
  end
  table.sort(other, function(a, b)
    local an = tostring(records[a].name or a):lower()
    local bn = tostring(records[b].name or b):lower()
    return an ~= bn and an < bn or (an == bn and a < b)
  end)
  return other
end

function Catalog.build(data, save, version)
  if require("Gen").of(save, version) == 3 then
    return {
      species = nativeKeys(data.pokemon, "speciesId"),
      items = nativeKeys(data.items, "itemId"),
      moves = nativeKeys(data.moves, "moveId"),
    }
  end
  return {
    species = sortedRecordKeys(data.pokemon),
    items = sortedRecordKeys(data.items),
    moves = sortedRecordKeys(data.moves),
  }
end

-- Directory listing / file reading go through love.filesystem when it is
-- available, and only fall back to shelling out.  That is what makes the
-- Events tab work in a packaged build: data/scripts is inside the .love
-- archive, data/generated is mounted from the save directory, and mods live
-- under the save directory too -- none of which io.open can reach by relative
-- path.  The io.popen path stays for headless runs (tests/, plain lua) where
-- love.filesystem does not exist.
-- nil means "love.filesystem cannot see this directory", which is the signal
-- to fall through to the shell -- headless runs mount a stub filesystem that
-- knows nothing about the checkout, but their io.* can still read it.
local function loveListLua(dir)
  local fs = love and love.filesystem
  if not (fs and fs.getDirectoryItems and fs.getInfo) then
    return nil
  end
  if not fs.getInfo(dir) then
    return nil
  end
  local out = {}
  for _, name in ipairs(fs.getDirectoryItems(dir)) do
    if name:sub(-4) == ".lua" then
      out[#out + 1] = dir .. "/" .. name
    end
  end
  return out
end

local function shellListLua(dir)
  local out = {}
  if not (io and io.popen) then
    return out
  end
  if package.config:sub(1, 1) == "\\" then
    -- cmd has no ls; dir /b prints bare names, so re-attach the directory
    local ok, p = pcall(io.popen, string.format('dir /b "%s\\*.lua" 2>nul', dir))
    if ok and p then
      for line in p:lines() do
        if line ~= "" then
          table.insert(out, dir .. "/" .. line)
        end
      end
      p:close()
    end
    return out
  end
  local ok, p = pcall(io.popen, string.format('ls "%s"/*.lua 2>/dev/null', dir))
  if ok and p then
    for line in p:lines() do
      table.insert(out, line)
    end
    p:close()
  end
  return out
end

local function readText(path)
  local fs = love and love.filesystem
  if fs and fs.read and fs.getInfo and fs.getInfo(path) then
    local ok, body = pcall(fs.read, path)
    if ok and body then
      return body
    end
  end
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local body = f:read("*a")
  f:close()
  return body
end

-- extraDirs: loaded mods' roots, so MOD_-prefixed flags defined in mod
-- scripts show up beside the vanilla EVENT_ ones
function Catalog.scrapeEvents(scriptDir, headerPath, listFiles, extraDirs)
  listFiles = listFiles
    or function(dir)
      return loveListLua(dir) or shellListLua(dir) or {}
    end

  local found = {}
  local function eat(text)
    for name in text:gmatch("EVENT_[A-Z0-9_]+") do
      found[name] = true
    end
    for name in text:gmatch("MOD_[A-Z0-9_]+") do
      found[name] = true
    end
  end

  local dirs = {}
  if scriptDir then
    dirs[#dirs + 1] = scriptDir
  end
  for _, dir in ipairs(extraDirs or {}) do
    dirs[#dirs + 1] = dir
  end
  for _, dir in ipairs(dirs) do
    local files = listFiles(dir) or {}
    for _, path in ipairs(files) do
      local body = readText(path)
      if body then
        eat(body)
      end
    end
  end

  if headerPath then
    local body = readText(headerPath)
    if body then
      eat(body)
    end
  end

  return sortedKeys(found)
end

function Catalog.gen2EventList(engine, extraDirs)
  local names = require("Gen2Flags").names(engine)
  local modFlags = Catalog.scrapeEvents(nil, nil, nil, extraDirs)
  local seen = {}
  for _, name in ipairs(names) do
    seen[name] = true
  end
  for _, name in ipairs(modFlags) do
    if not seen[name] then
      names[#names + 1] = name
      seen[name] = true
    end
  end
  return names
end

function Catalog.goldEventList(extraDirs)
  return Catalog.gen2EventList("gs", extraDirs)
end

function Catalog.game3EventList(extraDirs)
  local okF, FlagsTable = pcall(require, "src.core.game3.scripting.flags_table")
  local GameVersion = require("src.core.GameVersion")
  local version = GameVersion.get()
  if GameVersion.layout(version) == "rse" then
    local byName = require("src.core.game3.constants").of(version).flags.byName
    okF, FlagsTable = true, { FLAGS = {} }
    for name, id in pairs(byName) do
      if name:find("^FLAG_") then
        FlagsTable.FLAGS[name] = id
      end
    end
  end
  local names = {}
  local seen = {}
  if okF and FlagsTable and FlagsTable.FLAGS then
    for name, id in pairs(FlagsTable.FLAGS) do
      if type(name) == "string" and not seen[name] then
        names[#names + 1] = name
        seen[name] = true
      end
    end
  end
  local modFlags = Catalog.scrapeEvents(nil, nil, nil, extraDirs)
  for _, name in ipairs(modFlags) do
    if not seen[name] then
      names[#names + 1] = name
      seen[name] = true
    end
  end
  table.sort(names)
  return names
end

function Catalog.game3Categories(extraDirs)
  local ok, Gen3Flags = pcall(require, "Gen3Flags")
  if ok and Gen3Flags and Gen3Flags.categories then
    return Gen3Flags.categories(extraDirs)
  end
  return {
    story = Catalog.game3EventList(extraDirs),
    trainers = {},
    items = {},
    toggles = {},
    system = {},
    vars = {},
  }
end

return Catalog
