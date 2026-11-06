local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/frontier"
M.FILES = {}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function bytesAt(c, off, maxLen)
  local out = {}
  for i = 0, (maxLen or 1024) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

local function textIr(c, off)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.decode(bytesAt(c, off), { dialect = "rse" })
end

local function nameAt(c, off)
  local names = c.S.namesAt(off)
  for _, n in ipairs(names) do
    if not n:find(":", 1, true) then return n end
  end
  return names[1] and (names[1]:gsub("^.-:", "")) or nil
end

local function textRef(c, ptrOff)
  local p = c:ptr(ptrOff)
  if not p then return false end
  return { name = nameAt(c, p), key = string.format("g3:%08x", p + 0x08000000), ir = textIr(c, p) }
end

local function u8s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function u16s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 2 - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

local function texts(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = textRef(c, off + i * 4) end
  return out
end

-- pokeemerald/src/frontier_util.c:500
local function battlePointAwards(c, facilities, modes)
  local name = "sBattlePointAwards"
  local off = c:off(name)
  local stride = facilities * modes
  local out = {}
  for ch = 0, c.S.size(name) / stride - 1 do
    local row = {}
    for f = 0, facilities - 1 do
      local m = {}
      for mode = 0, modes - 1 do m[mode + 1] = c:u8(off + ch * stride + f * modes + mode) end
      row[f + 1] = m
    end
    out[ch + 1] = row
  end
  return out
end

-- pokeemerald/src/frontier_util.c:86
local function rows(c, name, width, reader, size)
  local off, out = c:off(name), {}
  local count = c.S.size(name) / (width * size)
  for i = 0, count - 1 do
    local r = {}
    for j = 0, width - 1 do r[j + 1] = reader(c, off + (i * width + j) * size) end
    out[i + 1] = r
  end
  return out
end

local function rd8(c, o) return c:u8(o) end
local function rd16(c, o) return c:u16(o) end
local function rd32(c, o) return c:u32(o) end

-- pokeemerald/src/battle_tower.c:686
local function partnerTexts(c)
  local name = "sPartnerTrainerTextTables"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 8 - 1 do
    local e = off + i * 8
    local list = c:ptr(e + 4)
    local strings = {}
    for j = 0, 4 do strings[j + 1] = textRef(c, list + j * 4) end
    out[i + 1] = { facilityClass = c:u32(e), strings = strings }
  end
  return out
end

-- pokeemerald/src/battle_tower.c:744
local function apprenticePartnerTexts(c)
  local name = "sPartnerApprenticeTextTables"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do
    local list = c:ptr(off + i * 4)
    local strings = {}
    for j = 0, 4 do strings[j + 1] = textRef(c, list + j * 4) end
    out[i + 1] = strings
  end
  return out
end

-- pokeemerald/src/frontier_util.c:685
local function recordsChallengeTexts(c)
  local name = "sRecordsWindowChallengeTexts"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 8 - 1 do
    out[i + 1] = { textRef(c, off + i * 8), textRef(c, off + i * 8 + 4) }
  end
  return out
end

-- pokeemerald/src/strings.c:1462
local function inlineTexts(c, name, stride)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / stride - 1 do out[i + 1] = textIr(c, off + i * stride) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local facilities = c.S.size("sFrontierBrainTrainerIds") / 2
  local modes = c.S.size("sBattleTowerPartySizes")
  return true, c:finish({
    screen = "frontier",
    facilities = facilities,
    modes = modes,
    battlePointAwards = battlePointAwards(c, facilities, modes),
    brainStreakAppearances = rows(c, "frontier_util.o:sFrontierBrainStreakAppearances", 4, rd8, 1),
    battledBrainBitFlags = rows(c, "sBattledBrainBitFlags", 2, rd16, 2),
    brainObjEventGfx = rows(c, "sFrontierBrainObjEventGfx", 2, rd8, 1),
    brainTrainerIds = u16s(c, "sFrontierBrainTrainerIds"),
    towerMaleGfx = u8s(c, "gTowerMaleTrainerGfxIds"),
    towerFemaleGfx = u8s(c, "gTowerFemaleTrainerGfxIds"),
    transitions = {
      frontier = u8s(c, "sBattleTransitionTable_BattleFrontier"),
      pyramid = u8s(c, "sBattleTransitionTable_BattlePyramid"),
      dome = u8s(c, "sBattleTransitionTable_BattleDome"),
    },
    apprenticeChallengeThreshold = u8s(c, "sApprenticeChallengeThreshold"),
    tentRewards = {
      verdanturf = u16s(c, "sVerdanturfTentRewards"),
      fallarbor = u16s(c, "sFallarborTentRewards"),
      slateport = u16s(c, "sSlateportTentRewards"),
    },
    towerPartySizes = u8s(c, "sBattleTowerPartySizes"),
    winStreakFlags = rows(c, "battle_tower.o:sWinStreakFlags", 2, rd32, 4),
    partnerTexts = partnerTexts(c),
    apprenticePartnerTexts = apprenticePartnerTexts(c),
    ssTidalDestinations = texts(c, "sLilycoveSSTidalDestinations"),
    recordsChallengeTexts = recordsChallengeTexts(c),
    levelModeText = texts(c, "sLevelModeText"),
    hallFacilityToRecordsText = texts(c, "sHallFacilityToRecordsText"),
    rankDots = inlineTexts(c, "gText_123Dot", 3),
    facilityNames = texts(c, "sBattleFrontierFacilityNames"),
    maniacMessages = texts(c, "sFrontierManiacMessages.342"),
    maniacThresholds = u8s(c, "sFrontierManiacStreakThresholds.343"),
    towerStreakThresholds = u16s(c, "sBattleTowerStreakThresholds.347"),
    natureGirlMessages = texts(c, "sNatureGirlMessages.391"),
    gamblerLookingMessages = texts(c, "sFrontierGamblerLookingMessages.398"),
    gamblerGoMessages = texts(c, "sFrontierGamblerGoMessages.402"),
    gamblerChallenges = u16s(c, "sFrontierChallenges.406"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
