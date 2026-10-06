local Versions = require("src.import.gba.versions")

local BattleRseDataExtract = {}

BattleRseDataExtract.FORMAT_VERSION = 1
BattleRseDataExtract.CACHE_FILE = "pokemon/battle/rse_data.lua"
BattleRseDataExtract.REQUIRED = { BattleRseDataExtract.CACHE_FILE }

local function names(version)
  local ok, Constants = pcall(require, "src.core.game3.constants")
  if not ok then return nil end
  local okC, C = pcall(Constants.of, version)
  return okC and C or nil
end

local function u16_list(rom, r)
  local out = {}
  for i = 0, math.floor(r.size / 2) - 1 do out[#out + 1] = rom:u16(r.off + i * 2) end
  return out
end

local function u8_list(rom, r)
  local out = {}
  for i = 0, r.size - 1 do out[#out + 1] = rom:get(r.off + i) end
  return out
end

local function windows(rom, off, n)
  local out = {}
  for w = 0, n - 1 do
    local b = off + w * 8
    if rom:get(b) == 0xFF then break end
    out[#out + 1] = {
      bg = rom:get(b), left = rom:get(b + 1), top = rom:get(b + 2), w = rom:get(b + 3), h = rom:get(b + 4),
      pal = rom:get(b + 5), baseBlock = rom:u16(b + 6),
    }
  end
  return out
end

function BattleRseDataExtract.extract(rom, cfg, version)
  local C = names(version)
  local function nm(kind, id, prefix)
    return C and C:name(kind, id, prefix) or nil
  end
  local function named(ids, kind, prefix)
    local out = {}
    for i, id in ipairs(ids) do out[i] = { id = id, name = nm(kind, id, prefix) } end
    return out
  end

  local data = {
    version = BattleRseDataExtract.FORMAT_VERSION,
    -- pokeemerald/src/battle_script_commands.c:784
    pickupItems = named(u16_list(rom, cfg.pickup_items), "items", "ITEM_"),
    rarePickupItems = named(u16_list(rom, cfg.rare_pickup_items), "items", "ITEM_"),
    pickupProbabilities = u8_list(rom, cfg.pickup_probabilities),
    -- pokeemerald/src/battle_script_commands.c:826
    environmentToType = u8_list(rom, cfg.environment_to_type),
    stevenMons = {},
    windows = {
      normal = windows(rom, cfg.window_templates.normal, cfg.window_template_counts.normal),
      arena = windows(rom, cfg.window_templates.arena, cfg.window_template_counts.arena),
    },
  }

  -- pokeemerald/src/battle_tower.c:764
  local size = cfg.steven_mon_size
  for i = 0, math.floor(cfg.steven_mons.size / size) - 1 do
    local b = cfg.steven_mons.off + i * size
    local evs, moves = {}, {}
    for s = 0, 5 do evs[s + 1] = rom:get(b + 5 + s) end
    for m = 0, 3 do
      local id = rom:u16(b + 12 + m * 2)
      moves[m + 1] = { id = id, name = nm("moves", id, "MOVE_") }
    end
    local species = rom:u16(b)
    data.stevenMons[i + 1] = {
      species = species,
      speciesName = nm("species", species, "SPECIES_"),
      fixedIV = rom:get(b + 2),
      level = rom:get(b + 3),
      nature = rom:get(b + 4),
      evs = evs,
      moves = moves,
    }
  end
  return data
end

function BattleRseDataExtract.ready(cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. BattleRseDataExtract.CACHE_FILE
  return (cache and cache.exists and cache:exists(rel)) and true or false
end

function BattleRseDataExtract.run(rom, cache, opts)
  opts = opts or {}
  local cfg = Versions.BATTLE_RSE_DATA
  if not cfg then error("battle_rse_data_extract: no BATTLE_RSE_DATA keys for this game") end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. BattleRseDataExtract.CACHE_FILE
  local data = BattleRseDataExtract.extract(rom, cfg, opts.version or Versions.GAME or require("src.core.GameVersion").get())
  cache:write(rel, "return " .. serialize(data) .. "\n")
  return { path = rel, stevenMons = #data.stevenMons, pickupItems = #data.pickupItems }
end

return BattleRseDataExtract
