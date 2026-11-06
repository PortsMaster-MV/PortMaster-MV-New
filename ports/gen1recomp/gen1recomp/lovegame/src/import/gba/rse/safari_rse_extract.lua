local Versions = require("src.import.gba.versions")

local SafariRseExtract = {}

SafariRseExtract.FORMAT_VERSION = 1
SafariRseExtract.CACHE_FILE = "safari/rse_tables.lua"
SafariRseExtract.REQUIRED = { SafariRseExtract.CACHE_FILE }

local function u8s(rom, off, n)
  local out = {}
  for i = 0, n - 1 do out[i + 1] = rom:get(off + i) end
  return out
end

local function s8(v)
  return v >= 0x80 and v - 0x100 or v
end

function SafariRseExtract.extract(rom, cfg)
  -- pokeemerald/src/battle_util.c:52
  local pkbl = {}
  local rows = math.floor(cfg.pkblToEscapeSize / 3)
  for r = 0, rows - 1 do pkbl[r] = u8s(rom, cfg.pkblToEscape + r * 3, 3) end
  -- pokeemerald/src/pokeblock.c:136
  local compat = {}
  for i = 0, cfg.flavorCompatSize - 1 do compat[i] = s8(rom:get(cfg.flavorCompat + i)) end
  return {
    format = SafariRseExtract.FORMAT_VERSION,
    pkblToEscapeFactor = pkbl,
    -- pokeemerald/src/battle_util.c:75
    goNearCounterToCatchFactor = u8s(rom, cfg.goNearCatch, cfg.goNearCatchSize),
    goNearCounterToEscapeFactor = u8s(rom, cfg.goNearEscape, cfg.goNearEscapeSize),
    flavorCompatibility = compat,
  }
end

function SafariRseExtract.ready(cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. SafariRseExtract.CACHE_FILE
  return (cache and cache.exists and cache:exists(rel)) and true or false
end

function SafariRseExtract.run(rom, cache, opts)
  opts = opts or {}
  local cfg = Versions.SAFARI_RSE
  if not cfg then error("safari_rse_extract: no SAFARI_RSE keys for this game") end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. SafariRseExtract.CACHE_FILE
  cache:write(rel, "return " .. serialize(SafariRseExtract.extract(rom, cfg)) .. "\n")
  return { path = rel }
end

return SafariRseExtract
