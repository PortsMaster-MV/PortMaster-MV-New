local Versions = require("src.import.gba.versions")

local RoamerExtract = {}

RoamerExtract.FORMAT_VERSION = 1
RoamerExtract.CACHE_FILE = "roamer/locations.lua"
RoamerExtract.REQUIRED = { RoamerExtract.CACHE_FILE }

-- pokeemerald/include/constants/maps.h:12
local MAP_NUM_UNDEFINED = 0xFF

-- pokeemerald/src/roamer.c:35
function RoamerExtract.extract(rom, cfg)
  local MapCatalog = require("src.import.gba.map_catalog")
  local sets = {}
  for i = 0, math.floor(cfg.size / cfg.stride) - 1 do
    local row = {}
    for j = 0, cfg.stride - 1 do
      local num = rom:get(cfg.off + i * cfg.stride + j)
      local id = false
      if num ~= MAP_NUM_UNDEFINED then
        id = MapCatalog.mapIdFor(cfg.mapGroup, num)
        if not id then error(string.format("roamer_extract: no map for group %d num %d", cfg.mapGroup, num)) end
      end
      row[j + 1] = id
    end
    -- pokeemerald/src/roamer.c:58
    if not row[1] then break end
    sets[#sets + 1] = row
  end
  return { format = RoamerExtract.FORMAT_VERSION, mapGroup = cfg.mapGroup, sets = sets }
end

function RoamerExtract.ready(cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. RoamerExtract.CACHE_FILE
  return (cache and cache.exists and cache:exists(rel)) and true or false
end

function RoamerExtract.run(rom, cache, opts)
  opts = opts or {}
  local cfg = Versions.ROAMER_LOCATIONS
  if not cfg then error("roamer_extract: no ROAMER_LOCATIONS keys for this game") end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. RoamerExtract.CACHE_FILE
  local data = RoamerExtract.extract(rom, cfg)
  cache:write(rel, "return " .. serialize(data) .. "\n")
  return { path = rel, sets = #data.sets }
end

return RoamerExtract
