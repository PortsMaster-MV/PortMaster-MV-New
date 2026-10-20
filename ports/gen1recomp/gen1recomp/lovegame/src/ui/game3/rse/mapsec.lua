local MapSections = require("src.import.gba.rse.map_sections_extract")
local Strings = require("src.core.Strings")

local Mapsec = {}

local pack, packRoot

local function root()
  return require("src.core.game3.cache_paths").CACHE_ROOT
end

local function read(rel)
  local Dataset = require("src.core.game3.dataset")
  local cache = Dataset.cache()
  return cache and cache:read(root() .. "/" .. rel) or nil
end
Mapsec.read = read

function Mapsec.readLua(rel)
  local src = read(rel)
  if not src then return nil end
  return assert(load(src, "@" .. rel, "t", {}))()
end

function Mapsec.pack()
  if pack and packRoot == root() then return pack end
  local src = assert(read(MapSections.SECTIONS_REL), "rse map sections pack is not in the cache")
  pack = MapSections.load(src)
  packRoot = root()
  return pack
end

function Mapsec.reset()
  pack, packRoot = nil, nil
end

function Mapsec.count()
  return Mapsec.pack().count
end

function Mapsec.entry(sec)
  sec = tonumber(sec)
  return sec and Mapsec.pack().sections[sec] or nil
end

-- pokeemerald/src/region_map.c:1568
function Mapsec.name(sec)
  local e = Mapsec.entry(sec)
  return e and e.name and Strings(e.name) or ""
end

-- pokeemerald/src/map_name_popup.c:403
function Mapsec.theme(sec)
  sec = tonumber(sec)
  if not sec then return nil end
  return MapSections.themeOf(Mapsec.pack(), sec)
end

return Mapsec
