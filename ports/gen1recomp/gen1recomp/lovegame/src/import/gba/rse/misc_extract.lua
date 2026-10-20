local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/misc"
M.FILES = {}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function nameAt(c, ptr)
  if not ptr then return nil end
  local names = c.S.namesAt(ptr)
  for _, n in ipairs(names) do
    if not n:find(":", 1, true) then return n end
  end
  local n = names[1]
  if n then return (n:gsub("^.-:", "")) end
  error(string.format("misc_extract: no symbol names the data at 0x%X", ptr))
end

local function textAt(c, off)
  return nameAt(c, c:ptr(off))
end

local function u16s(c, off, count)
  local out = {}
  for i = 0, count - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

local function u16List(c, name)
  return u16s(c, c:off(name), c.S.size(name) / 2)
end

local function u16Terminated(c, off, limit)
  local out = {}
  for i = 0, limit - 1 do
    local v = c:u16(off + i * 2)
    if v == 0 then break end
    out[#out + 1] = v
  end
  return out
end

local function textList(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = textAt(c, off + i * 4) end
  return out
end

-- pokeemerald/include/bard_music.h:12
local TEMPLATE_SIZE = 8
local SOUNDS_PER_WORD = 6
local WORD_SIZE = TEMPLATE_SIZE * SOUNDS_PER_WORD

local function templates(c, off, words)
  local out = {}
  for w = 0, words - 1 do
    local base = off + w * WORD_SIZE
    for s = 0, SOUNDS_PER_WORD - 1 do
      local b = base + s * TEMPLATE_SIZE
      out[#out + 1] = c:u8(b)
      out[#out + 1] = c:s8(b + 1)
      out[#out + 1] = c:s16(b + 4)
    end
  end
  return out
end

-- pokeemerald/src/bard_music.c:33
local function bard(c)
  local tbl = c:off("sBardSoundTemplatesTable")
  local groups = {}
  for g = 0, c.S.size("sBardSoundTemplatesTable") / 4 - 1 do
    local p = c:ptr(tbl + g * 4)
    if p then
      local name = nameAt(c, p)
      local words = c.S.size(name) / WORD_SIZE
      groups[g] = { words = words, t = templates(c, p, words) }
    end
  end
  local pokemon = c.S.size("sBardSoundTemplates_Pokemon") / WORD_SIZE
  local moves = c.S.size("sBardSoundTemplates_Moves") / WORD_SIZE
  local pitchOff = c:off("sPitchTables")
  local pitch = {}
  for i = 0, c.S.size("sPitchTables") / 4 - 1 do
    local p = c:ptr(pitchOff + i * 4)
    local row = {}
    for j = 0, 15 do
      local v = c:s16(p + j * 2)
      if v == 0x1800 then break end
      row[j + 1] = v
    end
    pitch[i] = row
  end
  local lengthsOff = c:off("sPhonemeLengths")
  local lengths = {}
  for i = 0, c.S.size("sPhonemeLengths") / 4 - 1 do lengths[i] = c:u32(lengthsOff + i * 4) end
  return {
    groups = groups,
    pokemon = { words = pokemon, t = templates(c, c:off("sBardSoundTemplates_Pokemon"), pokemon) },
    moves = { words = moves, t = templates(c, c:off("sBardSoundTemplates_Moves"), moves) },
    pitchTables = pitch,
    phonemeLengths = lengths,
    defaultLyrics = u16List(c, "sDefaultBardSongLyrics"),
  }
end

-- pokeemerald/src/mauville_old_man.c:978
local function stories(c)
  local off, out = c:off("sStorytellerStories"), {}
  for i = 0, c.S.size("sStorytellerStories") / 16 - 1 do
    local b = off + i * 16
    out[i + 1] = {
      stat = c:u8(b),
      minVal = c:u8(b + 1),
      title = textAt(c, b + 4),
      action = textAt(c, b + 8),
      fullText = textAt(c, b + 12),
    }
  end
  return out
end

-- pokeemerald/src/data/lilycove_lady.h:230
local function lady(c)
  local qOff = c:off("sQuizLadyQuizQuestions")
  local questions = {}
  for i = 0, c.S.size("sQuizLadyQuizQuestions") / 4 - 1 do
    local p = c:ptr(qOff + i * 4)
    questions[i + 1] = u16s(c, p, c.S.size(nameAt(c, p)) / 2)
  end
  local lOff = c:off("sFavorLadyAcceptedItemLists")
  local accepted = {}
  for i = 0, c.S.size("sFavorLadyAcceptedItemLists") / 4 - 1 do
    local p = c:ptr(lOff + i * 4)
    accepted[i + 1] = u16Terminated(c, p, c.S.size(nameAt(c, p)) / 2)
  end
  return {
    gfx = u16List(c, "sLilycoveLadyGfxId"),
    contestMonGfx = u16List(c, "sContestLadyMonGfxId"),
    contestMonSpecies = u16List(c, "sContestLadyMonSpecies"),
    quizQuestions = questions,
    quizAnswers = u16List(c, "sQuizLadyQuizAnswers"),
    quizPrizes = u16List(c, "sQuizLadyPrizes"),
    favorRequests = textList(c, "sFavorLadyRequests"),
    favorAccepted = accepted,
    favorPrizes = u16List(c, "sFavorLadyPrizes"),
  }
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local traderDecor = {}
  local dOff = c:off("sDefaultTraderDecorations")
  for i = 0, c.S.size("sDefaultTraderDecorations") - 1 do traderDecor[i + 1] = c:u8(dOff + i) end
  return true, c:finish({
    screen = "misc",
    bard = bard(c),
    oldMan = {
      giddyAdjectives = textList(c, "sGiddyAdjectives"),
      giddyQuestions = textList(c, "sGiddyQuestions"),
      stories = stories(c),
      traderNames = textList(c, "sDefaultTraderNames"),
      traderDecorations = traderDecor,
    },
    lotteryPrizes = u16List(c, "sLotteryPrizes"),
    lady = lady(c),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
