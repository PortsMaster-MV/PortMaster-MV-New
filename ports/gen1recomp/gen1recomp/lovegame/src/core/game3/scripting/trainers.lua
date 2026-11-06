-- Trainer party lookup + ROM-derived class/name/pic/party/dialog info for battles and overworld.

local Trainers = {}

-- pokefirered/include/constants/trainers.h:264, :272, :273
local TRAINER_CLASS_RIVAL_EARLY = 81
local TRAINER_CLASS_RIVAL_LATE = 89
local TRAINER_CLASS_CHAMPION = 90

Trainers._pack = nil

local function load_pack()
  if Trainers._pack then return Trainers._pack end
  local okD, Dataset = pcall(require, "src.core.game3.dataset")
  local cache = okD and Dataset and Dataset.cache and Dataset.cache()
  local src
  if cache and cache.read then
    src = cache:read("data/generated/gba/trainers.lua")
  end
  if not src then
    local ok, CacheFs = pcall(require, "src.import.CacheFs")
    if ok and CacheFs and CacheFs.readActive then
      src = CacheFs.readActive("data/generated/gba/trainers.lua")
    end
  end
  if type(src) == "string" and #src > 0 then
    local chunk = load(src, "@trainers.lua", "t", {})
    if chunk then
      local ok, pack = pcall(chunk)
      if ok and type(pack) == "table" then
        Trainers.mergeDialogs(pack, cache)
        Trainers._pack = pack
        return pack
      end
    end
  end
  Trainers._pack = false
  return nil
end

Trainers.DIALOGS_REL = "data/generated/gba/trainers/dialogs.lua"

local DIALOG_KEYS = { "scriptKey", "introTextKey", "defeatTextKey", "victoryTextKey", "notEnoughTextKey" }

function Trainers.mergeDialogs(pack, cache)
  if type(pack) ~= "table" or type(pack.trainers) ~= "table" then return 0 end
  local src = cache and cache.read and cache:read(Trainers.DIALOGS_REL)
  if type(src) ~= "string" or src == "" then return 0 end
  local chunk = load(src, "@" .. Trainers.DIALOGS_REL, "t", {})
  local ok, rows = false, nil
  if chunk then ok, rows = pcall(chunk) end
  if not ok or type(rows) ~= "table" then return 0 end
  local n = 0
  for id, d in pairs(rows) do
    local row = pack.trainers[id]
    if type(row) == "table" and type(d) == "table" and next(row.dialogs or {}) == nil then
      row.dialogs = d.dialogs or {}
      for _, k in ipairs(DIALOG_KEYS) do
        if row[k] == nil then row[k] = d[k] end
      end
      n = n + 1
    end
  end
  return n
end

local function decompose_ai_flags(flags)
  flags = tonumber(flags) or 0
  return {
    checkBadMove = (flags % 2 == 1),
    checkViability = (math.floor(flags / 2) % 2 == 1),
    tryToFaint = (math.floor(flags / 4) % 2 == 1),
    setupFirstTurn = (math.floor(flags / 8) % 2 == 1),
    risky = (math.floor(flags / 16) % 2 == 1),
    preferStrongestMove = (math.floor(flags / 32) % 2 == 1),
    preferBatonPass = (math.floor(flags / 64) % 2 == 1),
    doubleBattle = (math.floor(flags / 128) % 2 == 1),
    hpAware = (math.floor(flags / 256) % 2 == 1),
    roaming = (math.floor(flags / 0x20000000) % 2 == 1),
    safari = (math.floor(flags / 0x40000000) % 2 == 1),
    firstBattle = (flags >= 0x80000000),
  }
end

function Trainers.pack()
  return load_pack() or nil
end

--- Get full trainer definition record by trainerId.
function Trainers.get(trainerId)
  trainerId = tonumber(trainerId)
  if not trainerId then return nil end

  local pack = load_pack()
  local row = pack and pack.trainers and pack.trainers[trainerId]
  if row then
    local classNames = pack and pack.classNames
    local class = tonumber(row.class) or 0
    local dlgs = row.dialogs or {}
    return {
      id = trainerId,
      class = class,
      className = row.className or (classNames and classNames[class]) or "",
      pic = tonumber(row.pic) or 0,
      name = row.name or "",
      gender = tonumber(row.gender) or 0,
      encounterMusic = tonumber(row.encounterMusic) or 0,
      doubleBattle = row.doubleBattle and true or false,
      partySize = tonumber(row.partySize) or (row.party and #row.party) or 0,
      partyFlags = tonumber(row.partyFlags) or 0,
      lastLevel = tonumber(row.lastLevel) or 1,
      aiFlags = tonumber(row.aiFlags) or 0,
      ai = decompose_ai_flags(row.aiFlags),
      items = row.items or { 0, 0, 0, 0 },
      party = row.party or {},
      dialogs = dlgs,
      scriptKey = row.scriptKey,
      introTextKey = row.introTextKey,
      defeatTextKey = row.defeatTextKey,
      victoryTextKey = row.victoryTextKey,
      notEnoughTextKey = row.notEnoughTextKey,
    }
  end

  return nil
end

local GBA_CHAR = {
  [" "] = 0x00, ["é"] = 0x1B, ["&"] = 0x2D, ["+"] = 0x2E, ["!"] = 0xAB, ["?"] = 0xAC,
  ["."] = 0xAD, ["-"] = 0xAE, ["…"] = 0xB0, ["“"] = 0xB1, ["”"] = 0xB2, ["‘"] = 0xB3,
  ["’"] = 0xB4, ["'"] = 0xB4, ["♂"] = 0xB5, ["♀"] = 0xB6, [","] = 0xB8, ["/"] = 0xBA,
}

local function gba_char_sum(text)
  local sum = 0
  for ch in tostring(text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local b = ch:byte()
    local v = GBA_CHAR[ch]
    if not v then
      if #ch == 1 and b >= 48 and b <= 57 then v = 0xA1 + (b - 48)
      elseif #ch == 1 and b >= 65 and b <= 90 then v = 0xBB + (b - 65)
      elseif #ch == 1 and b >= 97 and b <= 122 then v = 0xD5 + (b - 97)
      else v = 0 end
    end
    sum = sum + v
  end
  return sum
end

-- pokefirered/src/battle_main.c:1555
local function double_personalities(t)
  local Pokemon = require("src.core.game3.pokemon")
  local nameHash = 0
  local out = {}
  for i, m in ipairs(t.party or {}) do
    nameHash = (nameHash + gba_char_sum(t.name)) % 0x100000000
    nameHash = (nameHash + gba_char_sum(Pokemon.name(tonumber(m.species) or 0))) % 0x100000000
    out[i] = (0x80 + (nameHash * 256) % 0x100000000) % 0x100000000
  end
  return out
end
Trainers._doublePersonalities = double_personalities

--- Resolve a foe battler struct + full party for battle runtime.
-- Guarantees:
-- 1. Uniform Flat IV scaling: actualIv = (rawIv * 31) / 255 across all 6 stats
-- 2. Explicit Zero EVs across all stats (no residual player data)
-- 3. Correct custom moves and held items
function Trainers.foeFromId(trainerId)
  trainerId = tonumber(trainerId)
  if not trainerId then return nil end

  local t = Trainers.get(trainerId)
  if not t or not t.party or #t.party == 0 then
    return nil
  end

  local foeParty = {}
  local bp = require("src.core.game3.battle.profile").get()
  local nativeParty = bp.trainerParty
  local pers = nativeParty and nativeParty.personalities(t, bp.gameId)
    or (t.doubleBattle and double_personalities(t) or {})
  for pi, m in ipairs(t.party) do
    local rawIv = tonumber(m.rawIv) or tonumber(m.iv) or 0
    local iv = tonumber(m.iv) or math.floor((rawIv * 31) / 255)
    local mon = {
      species = tonumber(m.species) or 1,
      level = tonumber(m.level) or 5,
      rawIv = rawIv,
      iv = iv,
      ivs = { hp = iv, atk = iv, def = iv, spa = iv, spd = iv, spe = iv },
      -- Trainer EVs are strictly zero
      evs = { hp = 0, atk = 0, def = 0, spa = 0, spd = 0, spe = 0 },
      heldItem = tonumber(m.heldItem) or nil,
      moves = m.moves,
      trainerId = trainerId,
      personality = pers[pi],
      nativeNpcTrainer = nativeParty and true or nil,
    }
    foeParty[#foeParty + 1] = mon
  end

  local lead = foeParty[1]
  return {
    species = lead.species,
    level = lead.level,
    rawIv = lead.rawIv,
    iv = lead.iv,
    ivs = lead.ivs,
    evs = lead.evs,
    heldItem = lead.heldItem,
    moves = lead.moves,
    personality = lead.personality,
    trainerId = trainerId,
    aiFlags = t.aiFlags,
    ai = t.ai,
    items = t.items,
    party = foeParty,
    trainerName = t.name,
    trainerClass = t.class,
    trainerClassName = t.className,
    trainerPic = t.pic,
    gender = t.gender,
    encounterMusic = t.encounterMusic,
    doubleBattle = t.doubleBattle,
    nativeNpcTrainer = nativeParty and true or nil,
  }
end

local DIALOG_TEXT_KEYS = {
  intro = "introTextKey", defeat = "defeatTextKey",
  victory = "victoryTextKey", notEnough = "notEnoughTextKey",
}

local function live_dialogs(t)
  local d = t.dialogs or {}
  local Sp = package.loaded["src.core.game3.scripting.space"]
  local vm = Sp and Sp.vm
  if not (vm and vm.getText) then return d end
  local out
  for field, keyName in pairs(DIALOG_TEXT_KEYS) do
    local key = t[keyName]
    local ir = key and vm:getText(key)
    if type(ir) == "table" then
      out = out or setmetatable({}, { __index = d })
      out[field] = ir
    end
  end
  return out or d
end

--- ROM-derived trainer presentation info (class / name / pic / partySize / dialogs).
-- opts.rivalName replaces the placeholder "TERRY" of the rival and champion
-- classes when provided.
function Trainers.info(trainerId, opts)
  opts = opts or {}
  trainerId = tonumber(trainerId)
  if not trainerId then return nil end

  local t = Trainers.get(trainerId)
  if not t then return nil end

  local info = {
    class = t.class,
    className = t.className,
    name = t.name,
    pic = t.pic,
    gender = t.gender,
    encounterMusic = t.encounterMusic,
    doubleBattle = t.doubleBattle,
    partySize = t.partySize or #t.party,
    lastLevel = t.lastLevel,
    aiFlags = t.aiFlags,
    ai = t.ai,
    items = t.items,
    party = t.party,
    dialogs = live_dialogs(t),
  }

  -- pokefirered/src/battle_message.c:2078 names these classes by the player's
  -- rival, recognised by class id: a mod may rename the class itself.
  local class = tonumber(info.class)
  if (class == TRAINER_CLASS_RIVAL_EARLY or class == TRAINER_CLASS_RIVAL_LATE
      or class == TRAINER_CLASS_CHAMPION) and opts.rivalName and opts.rivalName ~= "" then
    info.name = opts.rivalName
  end
  return info
end

--- Get dialog texts table: { intro, defeat, victory, notEnough }
function Trainers.dialogs(trainerId)
  local t = Trainers.get(trainerId)
  return t and live_dialogs(t) or {}
end

--- FRLG intro string pieces for a trainer battle.
-- pokefirered/src/battle_message.c:1569, :1622
function Trainers.introStrings(trainerId, monName, opts)
  local BattleText = require("src.core.game3.battle.battle_text")
  local info = Trainers.info(trainerId, opts)
  -- include/constants/opponents.h:4
  local shown = info or assert(Trainers.info(0, opts), "no trainer 0")
  local fill = {
    trainer = true,
    trainer1Class = shown.className or tonumber(shown.class),
    trainer1Name = shown.name,
    opponentMon1 = monName,
  }
  return {
    wants = BattleText.get("sText_Trainer1WantsToBattle", fill),
    sentOut = BattleText.get("sText_Trainer1SentOutPkmn", fill),
    info = info or {},
  }
end

--- Resolve encounter BGM song ID for a trainer (pret PlayTrainerEncounterMusic / include/constants/trainers.h & songs.h).
function Trainers.getEncounterMusic(trainerId)
  local perGame = require("src.core.game3.trainer_sight").encounterMusic(trainerId)
  if perGame then return perGame end
  local t = Trainers.get(trainerId)
  if not t then return 285 end -- MUS_ENCOUNTER_BOY
  local musicCode = (tonumber(t.encounterMusic) or 0) % 128
  -- TRAINER_ENCOUNTER_MUSIC_FEMALE (1), GIRL (2), TWINS (9) -> MUS_ENCOUNTER_GIRL (284)
  -- TRAINER_ENCOUNTER_MUSIC_MALE (0), INTENSE (4), COOL (5), SWIMMER (8), ELITE_FOUR (10), HIKER (11), INTERVIEWER (12), RICH (13) -> MUS_ENCOUNTER_BOY (285)
  -- Default (SUSPICIOUS 3, AQUA 6, MAGMA 7, etc.) -> MUS_ENCOUNTER_ROCKET (283)
  if musicCode == 1 or musicCode == 2 or musicCode == 9 then
    return 284 -- MUS_ENCOUNTER_GIRL
  elseif musicCode == 3 or musicCode == 6 or musicCode == 7 then
    return 283 -- MUS_ENCOUNTER_ROCKET
  else
    return 285 -- MUS_ENCOUNTER_BOY
  end
end

-- pokefirered/src/pokemon.c:5850
function Trainers.getBattleMusicRole(trainerId)
  local t = Trainers.get(trainerId)
  local class = t and tonumber(t.class)
  if class == 90 then
    return "battleChampion", 299
  elseif class == 84 or class == 87 then
    return "battleGymLeader", 296
  end
  return "battleTrainer", 297
end

-- pokefirered/src/battle_main.c:3746
function Trainers.getVictoryMusicRole(trainerId)
  local t = Trainers.get(trainerId)
  local class = t and tonumber(t.class)
  if class == 84 or class == 90 then
    return "victoryGymLeader", 312
  end
  return "victoryTrainer", 310
end

return Trainers
