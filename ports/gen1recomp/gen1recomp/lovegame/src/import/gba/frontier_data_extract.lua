local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")

local FrontierDataExtract = {}

FrontierDataExtract.FORMAT_VERSION = 1
FrontierDataExtract.CACHE_SUB = "frontier"
FrontierDataExtract.FILES = {
  "mons.lua", "trainers.lua", "held_items.lua", "banned.lua", "brains.lua", "tents.lua",
  "apprentices.lua", "classes.lua",
}
FrontierDataExtract.REQUIRED = {}
for i, f in ipairs(FrontierDataExtract.FILES) do
  FrontierDataExtract.REQUIRED[i] = FrontierDataExtract.CACHE_SUB .. "/" .. f
end

local LIST_END = 0xFFFF
local SPEECH_WORDS = 6

local function name_at(rom, off, len)
  local bytes = {}
  for i = 0, len - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = TextIR.dialectOf() }), {})
end

local function u16_list(rom, off, count)
  local out = {}
  for i = 0, count - 1 do out[i + 1] = rom:u16(off + i * 2) end
  return out
end

local function u8_list(rom, off, count)
  local out = {}
  for i = 0, count - 1 do out[i + 1] = rom:get(off + i) end
  return out
end

local function terminated_u16(rom, off, max)
  local out = {}
  for i = 0, max - 1 do
    local v = rom:u16(off + i * 2)
    if v == LIST_END then break end
    out[#out + 1] = v
  end
  return out
end

-- pokeemerald/include/battle_tower.h:27
local function read_mon(rom, off)
  return {
    species = rom:u16(off),
    moves = u16_list(rom, off + 2, 4),
    itemTableId = rom:get(off + 10),
    evSpread = rom:get(off + 11),
    nature = rom:get(off + 12),
  }
end

local function read_mons(rom, t)
  local mons = {}
  for i = 0, t.count - 1 do mons[i] = read_mon(rom, t.off + i * t.stride) end
  return mons
end

-- pokeemerald/include/battle_tower.h:16
local function read_trainers(rom, t, monCap)
  local trainers = {}
  for i = 0, t.count - 1 do
    local off = t.off + i * t.stride
    local setOff = rom:ptrOffset(rom:u32(off + 48))
    trainers[i] = {
      facilityClass = rom:get(off),
      name = name_at(rom, off + 4, 8),
      speechBefore = u16_list(rom, off + 12, SPEECH_WORDS),
      speechWin = u16_list(rom, off + 24, SPEECH_WORDS),
      speechLose = u16_list(rom, off + 36, SPEECH_WORDS),
      monSet = setOff and terminated_u16(rom, setOff, monCap + 1) or {},
    }
  end
  return trainers
end

-- pokeemerald/src/frontier_util.c:41
local function read_brain_mon(rom, off)
  return {
    species = rom:u16(off),
    heldItem = rom:u16(off + 2),
    fixedIV = rom:get(off + 4),
    nature = rom:get(off + 5),
    evs = u8_list(rom, off + 6, 6),
    moves = u16_list(rom, off + 12, 4),
  }
end

-- pokeemerald/include/apprentice.h:6
local function read_apprentice(rom, off)
  local names = {}
  for lang = 0, 5 do
    if lang == 0 then
      names[lang + 1] = u8_list(rom, off, 8)
    else
      names[lang + 1] = name_at(rom, off + lang * 8, 8)
    end
  end
  return {
    names = names,
    name = names[2],
    otId = rom:u16(off + 48),
    facilityClass = rom:get(off + 50),
    species = u16_list(rom, off + 52, 10),
    id = rom:get(off + 72),
    speechLost = u16_list(rom, off + 74, SPEECH_WORDS),
  }
end

function FrontierDataExtract.available()
  return Versions.FRONTIER ~= nil
end

function FrontierDataExtract.extract(rom)
  local F = Versions.FRONTIER
  local out = {}

  out.mons = { count = F.mons.count, mons = read_mons(rom, F.mons) }
  out.trainers = { count = F.trainers.count, trainers = read_trainers(rom, F.trainers, F.mons.count) }
  out.held_items = { items = u16_list(rom, F.heldItems.off, F.heldItems.count) }
  out.banned = { species = terminated_u16(rom, F.banned.off, F.banned.count) }

  local facilities = F.brainTrainerIds.count
  local partySize = math.floor(F.brainMons.count / (facilities * 2))
  local brainMons = {}
  for fac = 0, facilities - 1 do
    local sets = {}
    for sym = 0, 1 do
      local party = {}
      for m = 0, partySize - 1 do
        local idx = (fac * 2 + sym) * partySize + m
        party[m + 1] = read_brain_mon(rom, F.brainMons.off + idx * F.brainMons.stride)
      end
      sets[sym + 1] = party
    end
    brainMons[fac] = sets
  end
  out.brains = {
    trainerIds = u16_list(rom, F.brainTrainerIds.off, facilities),
    mons = brainMons,
  }

  local tents = {}
  for _, tent in ipairs(F.tents) do
    tents[tent.name] = {
      mons = read_mons(rom, tent.mons),
      trainers = read_trainers(rom, tent.trainers, tent.mons.count),
    }
  end
  out.tents = tents

  local apprentices = {}
  for i = 0, F.apprentices.count - 1 do
    apprentices[i] = read_apprentice(rom, F.apprentices.off + i * F.apprentices.stride)
  end
  out.apprentices = { count = F.apprentices.count, apprentices = apprentices }

  local function ranges(t)
    local list = {}
    for i = 0, t.count - 1 do
      list[i + 1] = { rom:u16(t.off + i * t.stride), rom:u16(t.off + i * t.stride + 2) }
    end
    return list
  end
  out.classes = {
    towerMale = u8_list(rom, F.towerMaleClasses.off, F.towerMaleClasses.count),
    towerFemale = u8_list(rom, F.towerFemaleClasses.off, F.towerFemaleClasses.count),
    trainerIdRanges = ranges(F.trainerIdRanges),
    trainerIdRangesHard = ranges(F.trainerIdRangesHard),
  }
  return out
end

function FrontierDataExtract.run(rom, cache, opts)
  opts = opts or {}
  if not FrontierDataExtract.available() then return { skipped = true } end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local root = (opts.cacheRoot or "data/generated/gba") .. "/" .. FrontierDataExtract.CACHE_SUB
  local pack = FrontierDataExtract.extract(rom)
  for _, file in ipairs(FrontierDataExtract.FILES) do
    local key = file:gsub("%.lua$", "")
    local body = pack[key]
    body.version = FrontierDataExtract.FORMAT_VERSION
    cache:write(root .. "/" .. file, "return " .. serialize(body) .. "\n")
  end
  return { root = root, mons = pack.mons.count, trainers = pack.trainers.count }
end

function FrontierDataExtract.ready(cache, cacheRoot)
  if not (cache and cache.exists) then return false end
  local root = (cacheRoot or "data/generated/gba") .. "/"
  for _, rel in ipairs(FrontierDataExtract.REQUIRED) do
    if not cache:exists(root .. rel) then return false end
  end
  return true
end

return FrontierDataExtract
