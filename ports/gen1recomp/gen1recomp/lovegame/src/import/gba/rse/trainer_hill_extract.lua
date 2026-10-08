local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/trainer_hill"
M.FILES = { "records.gfx", "records.map" }
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/include/constants/trainer_hill.h:17
local NUM_FLOORS = 4
local TRAINERS_PER_FLOOR = 2
-- pokeemerald/include/trainer_hill.h:27
local FLOOR_SIZE = 952
local TRAINER_SIZE = 328
local MAP_OFF = 660
-- pokeemerald/include/global.h:282
local BTMON_SIZE = 44

local function bytesAt(c, off, maxLen)
  local out = {}
  for i = 0, (maxLen or 1024) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

local function plainAt(c, off, maxLen)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.toPlain(TextIR.decode(bytesAt(c, off, maxLen), { dialect = "rse" }), {})
end

local function nameAt(c, off)
  for _, n in ipairs(c.S.namesAt(off)) do
    if not n:find(":", 1, true) then return n end
  end
  return nil
end

local function textRef(c, p)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return { name = nameAt(c, p), key = string.format("g3:%08x", p + 0x08000000),
    ir = TextIR.decode(bytesAt(c, p), { dialect = "rse" }) }
end

local function words(c, off)
  local out = {}
  for i = 0, 5 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

-- pokeemerald/include/global.h:282
local function battleTowerMon(c, o)
  local ivs = c:u32(o + 24)
  local function bits(s, n) return math.floor(ivs / 2 ^ s) % 2 ^ n end
  return {
    species = c:u16(o), heldItem = c:u16(o + 2),
    moves = { c:u16(o + 4), c:u16(o + 6), c:u16(o + 8), c:u16(o + 10) },
    level = c:u8(o + 12), ppBonuses = c:u8(o + 13),
    hpEV = c:u8(o + 14), attackEV = c:u8(o + 15), defenseEV = c:u8(o + 16), speedEV = c:u8(o + 17),
    spAttackEV = c:u8(o + 18), spDefenseEV = c:u8(o + 19),
    otId = c:u32(o + 20),
    hpIV = bits(0, 5), attackIV = bits(5, 5), defenseIV = bits(10, 5), speedIV = bits(15, 5),
    spAttackIV = bits(20, 5), spDefenseIV = bits(25, 5), abilityNum = bits(31, 1),
    personality = c:u32(o + 28),
    nickname = plainAt(c, o + 32, 11),
    friendship = c:u8(o + 43),
  }
end

-- pokeemerald/include/trainer_hill.h:6
local function trainer(c, o)
  local mons = {}
  for i = 0, 5 do mons[i + 1] = battleTowerMon(c, o + 64 + i * BTMON_SIZE) end
  return {
    name = plainAt(c, o, 11),
    facilityClass = c:u8(o + 11),
    speechBefore = words(c, o + 16), speechWin = words(c, o + 28),
    speechLose = words(c, o + 40), speechAfter = words(c, o + 52),
    mons = mons,
  }
end

-- pokeemerald/include/trainer_hill.h:18
local function floorMap(c, o)
  local metatiles, collision = {}, {}
  for i = 0, 255 do metatiles[i + 1] = c:u8(o + i) end
  for i = 0, 15 do collision[i + 1] = c:u16(o + 256 + i * 2) end
  return {
    metatiles = metatiles, collision = collision,
    trainerCoords = { c:u8(o + 288), c:u8(o + 289) },
    trainerDirections = c:u8(o + 290), trainerRanges = c:u8(o + 291),
  }
end

-- pokeemerald/src/trainer_hill.c:203
local function challenges(c)
  local off, out = c:off("sChallengeData"), {}
  for m = 0, c.S.size("sChallengeData") / 4 - 1 do
    local p = c:ptr(off + m * 4)
    local floors = {}
    for f = 0, NUM_FLOORS - 1 do
      local fo = p + 8 + f * FLOOR_SIZE
      local trainers = {}
      for t = 0, TRAINERS_PER_FLOOR - 1 do trainers[t + 1] = trainer(c, fo + 4 + t * TRAINER_SIZE) end
      floors[f + 1] = {
        trainerNum1 = c:u8(fo), trainerNum2 = c:u8(fo + 1),
        trainers = trainers, map = floorMap(c, fo + MAP_OFF),
      }
    end
    out[m + 1] = {
      name = nameAt(c, p),
      numTrainers = c:u8(p), numFloors = c:u8(p + 2), checksum = c:u32(p + 4),
      floors = floors,
    }
  end
  return out
end

-- pokeemerald/src/trainer_hill.c:194
local function prizeSets(c)
  local off, out = c:off("sPrizeListSets"), {}
  for s = 0, c.S.size("sPrizeListSets") / 4 - 1 do
    local listsPtr = c:ptr(off + s * 4)
    local n = math.floor(assert(c:sizedAt(listsPtr, "trainer_hill.o"), "trainer_hill_extract: prize lists unsized") / 4)
    local lists = {}
    for l = 0, n - 1 do
      local lp = c:ptr(listsPtr + l * 4)
      local count = math.floor(assert(c:sizedAt(lp, "trainer_hill.o"), "trainer_hill_extract: prize list unsized") / 2)
      local items = {}
      for i = 0, count - 1 do items[i + 1] = c:u16(lp + i * 2) end
      lists[l + 1] = items
    end
    out[s + 1] = lists
  end
  return out
end

-- pokeemerald/include/global.fieldmap.h:92
local function objectTemplate(c, name)
  local o = c:off(name)
  local r = c:u16(o + 10)
  return {
    graphicsId = c:u8(o + 1), elevation = c:u8(o + 8), movementType = c:u8(o + 9),
    rangeX = r % 16, rangeY = math.floor(r / 16) % 16, trainerType = c:u16(o + 12),
  }
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local modes = {}
  local mo = c:off("sModeStrings")
  for i = 0, c.S.size("sModeStrings") / 4 - 1 do modes[i + 1] = textRef(c, c:ptr(mo + i * 4)) end
  local slots, so = {}, c:off("sTrainerPartySlots")
  for t = 0, TRAINERS_PER_FLOOR - 1 do
    local row = {}
    for i = 0, 2 do row[i + 1] = c:u8(so + t * 3 + i) end
    slots[t + 1] = row
  end
  local music = {}
  local mm = c:off("sTrainerClassesAndMusic")
  for i = 0, c.S.size("sTrainerClassesAndMusic") / 4 - 1 do music[i + 1] = { c:u8(mm + i * 4), c:u8(mm + i * 4 + 1) } end
  -- pokeemerald/src/battle_records.c:443
  local recTiles = c:raw("sTrainerHillWindowTileset")
  c:write("records.gfx", recTiles)
  local recMap = c:raw("sTrainerHillWindowTilemap")
  c:write("records.map", recMap)
  return true, c:finish({
    screen = "trainer_hill",
    gfx = { records = { path = c:path("records.gfx"), bytes = #recTiles } },
    maps = { records = { path = c:path("records.map"), entries = #recMap / 2 } },
    palettes = { records = K.palList(c:pal("sTrainerHillWindowPalette", 16), 0, 16) },
    challenges = challenges(c),
    prizeListSets = prizeSets(c),
    classMusic = music,
    modeStrings = modes,
    extraScripts = require("src.import.gba.rse.f4_scripts").closure(c, { "TrainerHill_EventScript_TrainerBattle" }),
    partySlots = slots,
    objectTemplate = objectTemplate(c, "sTrainerObjectEventTemplate"),
    recordWinColors = { c:u8(c:off("sRecordWinColors")), c:u8(c:off("sRecordWinColors") + 1),
      c:u8(c:off("sRecordWinColors") + 2) },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
