local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/pike"
M.FILES = {}
M.REQUIRED = K.required(M.SUB, M.FILES)

local P = "battle_pike.o:"

local function u8s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function rows8(c, name, width)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / width - 1 do
    local r = {}
    for j = 0, width - 1 do r[j + 1] = c:u8(off + i * width + j) end
    out[i + 1] = r
  end
  return out
end

-- pokeemerald/src/battle_pike.c:35
local PIKE_WILD_MON_SIZE = 12

local function pikeWildList(c, off)
  local size = c:sizedAt(off, "battle_pike.o")
  if not size then error(string.format("pike_extract: no sized PikeWildMon list at 0x%X", off)) end
  local out = {}
  for i = 0, size / PIKE_WILD_MON_SIZE - 1 do
    local b = off + i * PIKE_WILD_MON_SIZE
    local moves = {}
    for m = 0, 3 do moves[m + 1] = c:u16(b + 4 + m * 2) end
    out[i + 1] = { species = c:u16(b), levelDelta = c:u8(b + 2), moves = moves }
  end
  return out
end

-- pokeemerald/src/battle_pike.c:261
local function wildMons(c)
  local name = P .. "sWildMons"
  local off, out = c:off(name), {}
  for lvl = 0, c.S.size(name) / 4 - 1 do
    local tbl = c:ptr(off + lvl * 4)
    local size = c:sizedAt(tbl, "battle_pike.o")
    local headers = {}
    for h = 0, size / 4 - 1 do headers[h + 1] = pikeWildList(c, c:ptr(tbl + h * 4)) end
    out[lvl + 1] = headers
  end
  return out
end

-- pokeemerald/include/wild_encounter.h:19
local HEADER_SIZE = 20
local MON_SIZE = 4
local LAND_SLOTS = 12

-- pokeemerald/src/data/wild_encounters.json:11939
local function wildHeaders(c)
  local name = "gBattlePikeWildMonHeaders"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / HEADER_SIZE - 1 do
    local b = off + i * HEADER_SIZE
    if c:u8(b) == 0xFF then break end
    local info = c:ptr(b + 4)
    local land = nil
    if info then
      local list = c:ptr(info + 4)
      local slots = {}
      for s = 0, LAND_SLOTS - 1 do
        local e = list + s * MON_SIZE
        slots[s + 1] = { minLevel = c:u8(e), maxLevel = c:u8(e + 1), species = c:u16(e + 2) }
      end
      land = { rate = c:u8(info), slots = slots }
    end
    out[i + 1] = { land = land }
  end
  return out
end

-- pokeemerald/src/battle_pike.c:27
local NPC_SIZE = 8

-- pokeemerald/src/battle_pike.c:267
local function npcTable(c)
  local name = P .. "sNPCTable"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / NPC_SIZE - 1 do
    local b = off + i * NPC_SIZE
    out[i + 1] = { graphicsId = c:u16(b), speech = { c:u8(b + 2), c:u8(b + 3), c:u8(b + 4) } }
  end
  return out
end

-- pokeemerald/include/constants/global.h:99
local EASY_CHAT_BATTLE_WORDS_COUNT = 6

-- pokeemerald/src/battle_pike.c:421
local function npcSpeeches(c)
  local name = P .. "sNPCSpeeches"
  local off, out = c:off(name), {}
  local stride = EASY_CHAT_BATTLE_WORDS_COUNT * 2
  for i = 0, c.S.size(name) / stride - 1 do
    local words = {}
    for w = 0, EASY_CHAT_BATTLE_WORDS_COUNT - 1 do words[w + 1] = c:u16(off + i * stride + w * 2) end
    out[i + 1] = words
  end
  return out
end

-- pokeemerald/src/battle_pike.c:539
local function winStreakFlags(c)
  local name = P .. "sWinStreakFlags"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = c:u32(off + i * 4) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  return true, c:finish({
    screen = "pike",
    wildMons = wildMons(c),
    wildHeaders = wildHeaders(c),
    npcTable = npcTable(c),
    npcSpeeches = npcSpeeches(c),
    roomTypeHints = u8s(c, P .. "sRoomTypeHints"),
    healBeforeQueen = rows8(c, P .. "sNumMonsToHealBeforePikeQueen", 3),
    brainStreakAppearances = rows8(c, P .. "sFrontierBrainStreakAppearances", 4),
    winStreakFlags = winStreakFlags(c),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
