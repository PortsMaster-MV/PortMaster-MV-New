local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "field_specials"

M.FILES = {}

M.REQUIRED = K.required(M.SUB, M.FILES)

local MAP_UNDEFINED = 0xFFFF

-- pokeemerald/src/field_specials.c:3889
local function pokemonCenters(c)
  local MapCatalog = require("src.import.gba.map_catalog")
  local name = "field_specials.o:sPokemonCenters.562"
  local off, out = c:off(name), {}
  for i = 0, 63 do
    local v = c:u16(off + i * 2)
    if v == MAP_UNDEFINED then break end
    local id = MapCatalog.mapIdFor(math.floor(v / 256), v % 256)
    if not id then error("field_specials: sPokemonCenters entry " .. i .. " has no map id") end
    out[#out + 1] = id
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  return true, c:finish({
    screen = "field_specials",
    pokemonCenters = pokemonCenters(c),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
