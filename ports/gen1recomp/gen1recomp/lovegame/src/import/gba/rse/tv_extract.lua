local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "tv"

M.FILES = {}

M.REQUIRED = K.required(M.SUB, M.FILES)

local function constants()
  return require("src.core.game3.constants").of("emerald")
end

-- pokeemerald/src/tv.c:192
local function outbreakSpecies(c)
  local name = "sPokeOutbreakSpeciesList"
  local off, stride = c:off(name), 12
  local out = {}
  for i = 0, math.floor(c.S.size(name) / stride) - 1 do
    local e = off + i * stride
    out[#out + 1] = {
      species = c:u16(e),
      moves = { c:u16(e + 2), c:u16(e + 4), c:u16(e + 6), c:u16(e + 8) },
      level = c:u8(e + 10),
      location = c:u8(e + 11),
    }
  end
  return out
end

-- pokeemerald/src/tv.c:250
local function numberOne(c)
  local name = "sNumberOneVarsAndThresholds"
  local off = c:off(name)
  local C = constants()
  local out = {}
  for i = 0, math.floor(c.S.size(name) / 4) - 1 do
    local id = c:u16(off + i * 4)
    local varName = C:name("vars", id)
    if not varName then error("tv: sNumberOneVarsAndThresholds var " .. id .. " has no name") end
    out[#out + 1] = { var = varName, id = id, threshold = c:u16(off + i * 4 + 2) }
  end
  return out
end

-- pokeemerald/src/tv.c:230
local function symbolFlags(c, name)
  local off = c:off(name)
  local C = constants()
  local out = {}
  for i = 0, math.floor(c.S.size(name) / 2) - 1 do
    local id = c:u16(off + i * 2)
    local flagName = C:name("flags", id)
    if not flagName then error("tv: " .. name .. " flag " .. id .. " has no name") end
    out[#out + 1] = flagName
  end
  return out
end

-- pokeemerald/src/tv.c:725
local function secretBaseSecretsActions(c)
  local name = "sTVSecretBaseSecretsActions"
  local off = c:off(name)
  local out = {}
  for i = 0, c.S.size(name) - 1 do out[#out + 1] = c:u8(off + i) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  return true, c:finish({
    screen = "tv",
    outbreakSpecies = outbreakSpecies(c),
    numberOne = numberOne(c),
    goldSymbolFlags = symbolFlags(c, "sGoldSymbolFlags"),
    silverSymbolFlags = symbolFlags(c, "sSilverSymbolFlags"),
    secretBaseSecretsActions = secretBaseSecretsActions(c),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
