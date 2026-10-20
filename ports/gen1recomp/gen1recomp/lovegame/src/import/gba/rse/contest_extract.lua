local K = require("src.import.gba.rse.boot_gfx")
local Disasm = require("src.core.game3.rse.contest_ai_disasm")

local M = {}

M.SUB = "rse/contest"
M.FILES = {}
M.REQUIRED = K.required(M.SUB, M.FILES)

local ROM_BASE = 0x08000000

local function bytesAt(c, off, maxLen)
  local out = {}
  for i = 0, (maxLen or 512) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

local function fixed(c, off, len)
  local out = {}
  for i = 0, len - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function nameAt(c, off)
  local names = c.S.namesAt(off)
  for _, n in ipairs(names) do
    if not n:find(":", 1, true) then return n end
  end
  return names[1] and (names[1]:gsub("^.-:", "")) or nil
end

local function textTable(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do
    local p = c:ptr(off + i * 4)
    out[i] = p and { name = nameAt(c, p), bytes = bytesAt(c, p) } or false
  end
  return out
end

-- pokeemerald/include/contest.h:87
local function opponents(c)
  local off, out = c:off("gContestOpponents"), {}
  for i = 0, c.S.size("gContestOpponents") / 64 - 1 do
    local b = off + i * 64
    local pools = c:u8(b + 28)
    out[i] = {
      species = c:u16(b),
      nickname = fixed(c, b + 2, 11),
      trainerName = fixed(c, b + 13, 8),
      trainerGfxId = c:u8(b + 21),
      aiFlags = c:u32(b + 24),
      whichRank = pools % 4,
      aiPool = {
        cool = math.floor(pools / 4) % 2 == 1,
        beauty = math.floor(pools / 8) % 2 == 1,
        cute = math.floor(pools / 16) % 2 == 1,
        smart = math.floor(pools / 32) % 2 == 1,
        tough = math.floor(pools / 64) % 2 == 1,
      },
      moves = { c:u16(b + 30), c:u16(b + 32), c:u16(b + 34), c:u16(b + 36) },
      cool = c:u8(b + 38), beauty = c:u8(b + 39), cute = c:u8(b + 40),
      smart = c:u8(b + 41), tough = c:u8(b + 42), sheen = c:u8(b + 43),
      highestRank = c:u8(b + 44),
      gameCleared = c:u8(b + 45),
      personality = c:u32(b + 56),
      otId = c:u32(b + 60),
    }
  end
  return out
end

local function u8list(c, name, signed)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i] = signed and c:s8(off + i) or c:u8(off + i) end
  return out
end

-- pokeemerald/src/contest.c:957
local function excitementTable(c)
  local off, out = c:off("sContestExcitementTable"), {}
  for cat = 0, 4 do
    out[cat] = {}
    for moveCat = 0, 4 do out[cat][moveCat] = c:s8(off + cat * 5 + moveCat) end
  end
  return out
end

-- pokeemerald/include/global.h:752
local function winners(c)
  local off, out = c:off("gDefaultContestWinners"), {}
  for i = 0, c.S.size("gDefaultContestWinners") / 32 - 1 do
    local b = off + i * 32
    out[i] = {
      personality = c:u32(b),
      trainerId = c:u32(b + 4),
      species = c:u16(b + 8),
      contestCategory = c:u8(b + 10),
      monName = fixed(c, b + 11, 11),
      trainerName = fixed(c, b + 22, 8),
      contestRank = c:u8(b + 30),
    }
  end
  return out
end

-- pokeemerald/data/contest_ai_scripts.s:17
local function aiScripts(c)
  local off = c:off("gContestAI_ScriptsTable")
  local entries = {}
  for i = 0, 31 do
    local p = c:u32(off + i * 4)
    entries[i] = p
  end
  local list = {}
  for i = 0, 31 do list[#list + 1] = entries[i] end
  local rom = c.rom
  local function read(addr) return rom:get(addr - ROM_BASE) end
  local walk = Disasm.walk(read, list, function(a) return a >= ROM_BASE and a < ROM_BASE + 0x2000000 end)
  local hex = {}
  for a = walk.lo, walk.hi - 1 do hex[#hex + 1] = string.format("%02x", read(a)) end
  return {
    base = walk.lo,
    size = walk.hi - walk.lo,
    entries = entries,
    blob = table.concat(hex),
    instructions = #walk.order,
  }
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local ai = aiScripts(c)
  return true, c:finish({
    screen = "contest",
    opponents = opponents(c),
    opponentCount = c.S.size("gContestOpponents") / 64,
    postgameFilter = u8list(c, "gPostgameContestOpponentFilter"),
    comboStarterLookup = u8list(c, "gComboStarterLookupTable"),
    excitementTable = excitementTable(c),
    defaultWinners = winners(c),
    ai = ai,
    appealResultTexts = textTable(c, "sAppealResultTexts"),
    roundResultTexts = textTable(c, "sRoundResultTexts"),
    conditionTexts = textTable(c, "sContestConditions"),
    invalidMoveNames = textTable(c, "sInvalidContestMoveNames"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
