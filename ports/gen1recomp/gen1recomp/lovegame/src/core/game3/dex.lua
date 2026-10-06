-- Pokédex quarantine (H9): host bits 1–251; species 252+ in national_dex sidecar.

local Dex = {}

Dex.HOST_MAX = 251
Dex.KANTO_MAX = 151
Dex.NATIONAL_MAX = 386

local function profile_of(version)
  return require("src.core.game3.profile").of(version)
end

local function dex_block(version)
  local row = profile_of(version)
  local block = row.dex
  if type(block) ~= "table" then
    error("game3 profile '" .. tostring(row.id) .. "' has no dex block", 0)
  end
  return block, row
end

local function version_of(session)
  if type(session) == "table" and type(session.version) == "string" then return session.version end
  return require("src.core.game3.profile").sessionVersion(session)
end

function Dex.packReader(version, rel)
  local GameVersion = require("src.core.GameVersion")
  local root = require("src.core.game3.cache_paths").CACHE_ROOT
  if version == nil or version == GameVersion.get() then
    local okD, Dataset = pcall(require, "src.core.game3.dataset")
    if okD and Dataset and Dataset.cache then
      local src = Dataset.cache():read(root .. "/" .. rel)
      if src then return src end
    end
  end
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  if not (okC and CacheFs and CacheFs.readAt) then return nil end
  local info = GameVersion.info(version)
  return CacheFs.readAt(((info and info.cachePrefix) or "") .. root .. "/" .. rel)
end

local packs = {}

local function load_pack(version, rel)
  local key = tostring(version) .. "|" .. rel
  local t = packs[key]
  if t ~= nil then return t or nil end
  local src = Dex.packReader(version, rel)
  if not src then error("dex pack " .. rel .. " is not in the " .. tostring(version) .. " cache", 0) end
  t = assert(load(src, "@" .. rel, "t", {}))()
  packs[key] = t
  return t
end

function Dex.resetPacks()
  packs = {}
end

function Dex.regionalMax(version)
  local block = dex_block(version)
  if block.regionalPrefix then return block.regionalPrefix end
  return load_pack(profile_of(version).id, block.orderPack).count
end

-- pokeemerald/src/pokemon.c:5685
function Dex.regionalNumber(species, version)
  species = tonumber(species)
  if not species then return nil end
  local block, row = dex_block(version)
  if block.regionalPrefix then
    if species >= 1 and species <= block.regionalPrefix then return species end
    return nil
  end
  local n = load_pack(row.id, block.regionalPack).toHoenn[species]
  if n and n <= Dex.regionalMax(row.id) then return n end
  return nil
end

function Dex.inRegional(species, version)
  return Dex.regionalNumber(species, version) ~= nil
end

-- pokeemerald/src/pokemon.c:5659
function Dex.nationalInRegional(nat, version)
  nat = tonumber(nat)
  if not nat then return false end
  local block, row = dex_block(version)
  if block.regionalPrefix then return nat >= 1 and nat <= block.regionalPrefix end
  local pack = load_pack(row.id, block.orderPack)
  for i = 1, pack.count do
    if pack.order[i] == nat then return true end
  end
  return false
end

function Dex.new()
  return {
    seen = {},   -- [species] = true
    caught = {}, -- [species] = true
    owned = {},  -- alias for caught
  }
end

local function resolve_species_id(species)
  if species == nil then return nil end
  local n = tonumber(species)
  if n and n >= 1 then return n end
  local okP, Pokemon = pcall(require, "src.core.game3.pokemon")
  if okP and Pokemon then
    if Pokemon.speciesFromName then
      local id = Pokemon.speciesFromName(tostring(species))
      if id and tonumber(id) then return tonumber(id) end
    elseif Pokemon.byName then
      local id = Pokemon.byName(tostring(species))
      if id and tonumber(id) then return tonumber(id) end
    end
  end
  return nil
end

local function bit_get(arr, species)
  if type(arr) ~= "table" then return false end
  local sp = resolve_species_id(species)
  if sp and arr[sp] == true then return true end
  if arr[species] == true then return true end
  local v = (sp and arr[sp]) or arr[species]
  if v and v ~= 0 and v ~= false then return true end
  return false
end

local function bit_set(arr, species, on)
  if not arr then return end
  local sp = resolve_species_id(species)
  if sp then
    arr[sp] = on and true or nil
  else
    arr[species] = on and true or nil
  end
end

--- Import host dex (1–251) into game3 dex.
function Dex.mergeFromHost(dex, hostSave)
  if not dex or not hostSave then return end
  dex.seen = dex.seen or {}
  dex.caught = dex.caught or {}
  dex.owned = dex.owned or dex.caught
  local pd = hostSave.pokedex or hostSave.pokeDex or {}
  local seen = pd.seen or hostSave.seen or {}
  local caught = pd.caught or pd.owned or hostSave.caught or {}
  for sp = 1, Dex.HOST_MAX do
    if bit_get(seen, sp) then
      bit_set(dex.seen, sp, true)
    end
    if bit_get(caught, sp) then
      bit_set(dex.caught, sp, true)
      bit_set(dex.owned, sp, true)
    end
  end
end

--- Restore National sidecar (252+) into game3 dex.
function Dex.restoreNational(dex, sidecar)
  if not dex or type(sidecar) ~= "table" then return end
  dex.seen = dex.seen or {}
  dex.caught = dex.caught or {}
  dex.owned = dex.owned or dex.caught
  local nd = sidecar.national_dex or sidecar
  local seen = nd.seen or {}
  local caught = nd.caught or {}
  for sp, on in pairs(seen) do
    local n = tonumber(sp)
    if n and n > Dex.HOST_MAX and on then bit_set(dex.seen, n, true) end
  end
  for sp, on in pairs(caught) do
    local n = tonumber(sp)
    if n and n > Dex.HOST_MAX and on then
      bit_set(dex.caught, n, true)
      bit_set(dex.owned, n, true)
    end
  end
end

function Dex.setSeen(dex, species)
  if not dex then return end
  dex.seen = dex.seen or {}
  local sp = resolve_species_id(species) or species
  if not sp then return end
  bit_set(dex.seen, sp, true)
end

function Dex.setCaught(dex, species)
  if not dex then return end
  dex.seen = dex.seen or {}
  dex.caught = dex.caught or {}
  dex.owned = dex.owned or dex.caught
  local sp = resolve_species_id(species) or species
  if not sp then return end
  bit_set(dex.seen, sp, true)
  bit_set(dex.caught, sp, true)
  bit_set(dex.owned, sp, true)
end

local SPECIES_UNOWN = 201
local SPECIES_SPINDA = 308

local function record_personality(dex, species, personality)
  local p = (tonumber(personality) or 0) % 4294967296
  if species == SPECIES_UNOWN then dex.unownPersonality = p end
  if species == SPECIES_SPINDA then dex.spindaPersonality = p end
end

-- pokefirered/src/pokemon.c:6233
function Dex.handleSetPokedexFlag(dex, species, caught, personality)
  if not dex then return end
  local sp = resolve_species_id(species)
  if not sp then return end
  if caught then
    if Dex.isCaught(dex, sp) then return end
    Dex.setCaught(dex, sp)
  else
    if Dex.isSeen(dex, sp) then return end
    Dex.setSeen(dex, sp)
  end
  record_personality(dex, sp, personality)
end

-- pokefirered/src/pokedex_screen.c:2197
function Dex.defaultPersonality(dex, species)
  species = tonumber(species)
  if not dex then return 0 end
  if species == SPECIES_SPINDA then return tonumber(dex.spindaPersonality) or 0 end
  if species == SPECIES_UNOWN then return tonumber(dex.unownPersonality) or 0 end
  return 0
end

function Dex.isSeen(dex, species)
  if not dex then return false end
  return bit_get(dex.seen, species)
end

function Dex.isCaught(dex, species)
  if not dex then return false end
  return bit_get(dex.caught, species) or bit_get(dex.owned, species)
end

function Dex.isOwned(dex, species)
  return Dex.isCaught(dex, species)
end

--- Register an encounter; returns whether it was already seen.
function Dex.registerEncounter(dex, species, session)
  if not dex or not species then return false end
  local sp = tonumber(species) or 1
  if dex_block(version_of(session)).registerGate and sp > (Dex.KANTO_MAX or 151) then
    local PokedexData = require("src.core.game3.pokedex_data")
    if not PokedexData.isNationalUnlocked(session, dex) then
      return true -- cannot register non-Kanto species before National Dex
    end
  end
  local wasSeen = Dex.isSeen(dex, species)
  Dex.setSeen(dex, species)
  return wasSeen
end

--- Register a capture; returns whether it was already caught.
function Dex.registerCapture(dex, species, session, personality)
  if not dex or not species then return false end
  local sp = tonumber(species) or 1
  if dex_block(version_of(session)).registerGate and sp > (Dex.KANTO_MAX or 151) then
    local PokedexData = require("src.core.game3.pokedex_data")
    if not PokedexData.isNationalUnlocked(session, dex) then
      return true -- cannot register non-Kanto species before National Dex
    end
  end
  local wasCaught = Dex.isCaught(dex, species)
  Dex.setCaught(dex, species)
  -- pokefirered/src/battle_script_commands.c:9657
  if not wasCaught then record_personality(dex, resolve_species_id(species), personality) end
  return wasCaught
end

--- Count seen Pokémon in Kanto (1..151) or National mode.
function Dex.countSeen(dex, mode)
  if not dex then return 0 end
  mode = (mode or "kanto"):lower()
  local maxSp = (mode == "national") and Dex.NATIONAL_MAX or Dex.KANTO_MAX
  local count = 0
  for sp = 1, maxSp do
    if Dex.isSeen(dex, sp) then
      count = count + 1
    end
  end
  -- Also count any seen above NATIONAL_MAX in national mode
  if mode == "national" and type(dex.seen) == "table" then
    for sp, on in pairs(dex.seen) do
      local n = tonumber(sp)
      if n and n > Dex.NATIONAL_MAX and on then
        count = count + 1
      end
    end
  end
  return count
end

--- Count caught Pokémon in Kanto (1..151) or National mode.
function Dex.countCaught(dex, mode)
  if not dex then return 0 end
  mode = (mode or "kanto"):lower()
  local maxSp = (mode == "national") and Dex.NATIONAL_MAX or Dex.KANTO_MAX
  local count = 0
  for sp = 1, maxSp do
    if Dex.isCaught(dex, sp) then
      count = count + 1
    end
  end
  if mode == "national" then
    local cTable = dex.caught or dex.owned or {}
    for sp, on in pairs(cTable) do
      local n = tonumber(sp)
      if n and n > Dex.NATIONAL_MAX and on then
        count = count + 1
      end
    end
  end
  return count
end

function Dex.countOwned(dex, mode)
  return Dex.countCaught(dex, mode)
end

local function keyed(t, id)
  if type(t) ~= "table" then return nil end
  local v = t[id]
  if v == nil then v = t[tostring(id)] end
  if v == nil then v = t[string.format("0x%X", id)] end
  return v
end

-- pokefirered/src/event_data.c:107
function Dex.nationalEnabled(save)
  if type(save) ~= "table" then return false end
  local block, row = dex_block(save.version)
  local nat = block.national
  local C = require("src.core.game3.constants").of(row.id)
  local dex = type(save.dex) == "table" and save.dex or {}
  local magic = dex.national == true or dex.nationalUnlocked == true or dex.isNationalUnlocked == true
    or save.national_dex_unlocked == true
    or (nat.magic ~= nil and tonumber(dex.nationalMagic) == nat.magic)
  local flag = keyed(save.flags, C:require("flags", nat.flag))
  local flagSet = flag == true or (type(save.flags) == "table" and save.flags[nat.flag] == true)
  local var = keyed(save.vars, C:require("vars", nat.var))
  if var == nil and type(save.vars) == "table" then var = save.vars[nat.var] end
  local varSet = tonumber(var) == nat.value
  if nat.requireAll then return magic and flagSet and varSet end
  return magic or flagSet or varSet
end

-- pokeemerald/src/event_data.c:63
function Dex.enableNational(session)
  if type(session) ~= "table" then return end
  local block, row = dex_block(session.version)
  local nat = block.national
  local C = require("src.core.game3.constants").of(row.id)
  session.dex = session.dex or {}
  session.dex.national = true
  if nat.magic then session.dex.nationalMagic = nat.magic end
  if row.family == "rse" then session.pokedex = { mode = 1, order = 0 } end
  session.flags = session.flags or {}
  session.vars = session.vars or {}
  local Flags = require("src.core.game3.scripting.flags")
  Flags.setVar(session, nil, C:require("vars", nat.var), nat.value)
  Flags.setFlag(session, nil, C:require("flags", nat.flag), true)
end

-- pokefirered/src/main_menu.c:643
function Dex.summaryCount(save)
  if type(save) ~= "table" then return 0 end
  local dex = type(save.dex) == "table" and save.dex
    or type(save.pokedex) == "table" and save.pokedex or {}
  local national = Dex.nationalEnabled(save)
  local block = dex_block(save.version)
  local counted, n = {}, 0
  for _, key in ipairs({ "caught", "owned" }) do
    for sp, on in pairs(type(dex[key]) == "table" and dex[key] or {}) do
      local id = tonumber(sp)
      if not id and type(sp) == "string" then
        local ok, res = pcall(resolve_species_id, sp)
        id = ok and tonumber(res) or nil
      end
      local regional = national or (block.regionalPrefix and id and id <= Dex.KANTO_MAX)
        or (not block.regionalPrefix and id and Dex.inRegional(id, save.version))
      if id and on and on ~= 0 and not counted[id]
          and id >= 1 and regional then
        counted[id] = true
        n = n + 1
      end
    end
  end
  local ci = type(save.modData) == "table" and type(save.modData.cartImport) == "table"
    and save.modData.cartImport
  local maxNat = national and Dex.NATIONAL_MAX or Dex.KANTO_MAX
  for _, nat in ipairs(ci and type(ci.dexOwned) == "table" and ci.dexOwned or {}) do
    nat = tonumber(nat)
    local inDex = nat and (national or block.regionalPrefix) and nat <= maxNat
      or (nat and not national and not block.regionalPrefix and Dex.nationalInRegional(nat, save.version))
    if nat and nat >= 1 and inDex and not (nat <= Dex.HOST_MAX and counted[nat]) then
      if nat <= Dex.HOST_MAX then counted[nat] = true end
      n = n + 1
    end
  end
  return n
end

--- Split for returnToHost: hostUpdates (1–251) + national sidecar (252+).
function Dex.splitForHost(dex)
  local hostSeen, hostCaught = {}, {}
  local natSeen, natCaught = {}, {}
  if not dex then
    return { seen = hostSeen, caught = hostCaught },
      { seen = natSeen, caught = natCaught }
  end
  for sp, on in pairs(dex.seen or {}) do
    local n = tonumber(sp)
    if n and on then
      if n <= Dex.HOST_MAX then hostSeen[n] = true
      else natSeen[n] = true end
    end
  end
  for sp, on in pairs(dex.caught or {}) do
    local n = tonumber(sp)
    if n and on then
      if n <= Dex.HOST_MAX then hostCaught[n] = true
      else natCaught[n] = true end
    end
  end
  return { seen = hostSeen, caught = hostCaught },
    { seen = natSeen, caught = natCaught }
end

--- Merge hostUpdates into save without touching indices > 251.
function Dex.applyHostUpdates(save, hostUpdates)
  if not save or not hostUpdates then return end
  save.pokedex = save.pokedex or {}
  save.pokedex.seen = save.pokedex.seen or {}
  save.pokedex.caught = save.pokedex.caught or {}
  for sp, on in pairs(hostUpdates.seen or {}) do
    local n = tonumber(sp)
    if n and n >= 1 and n <= Dex.HOST_MAX and on then
      save.pokedex.seen[n] = true
    end
  end
  for sp, on in pairs(hostUpdates.caught or {}) do
    local n = tonumber(sp)
    if n and n >= 1 and n <= Dex.HOST_MAX and on then
      save.pokedex.caught[n] = true
    end
  end
end

return Dex
