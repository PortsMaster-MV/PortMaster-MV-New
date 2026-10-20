local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/apprentice"
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

-- pokeemerald/src/data/battle_frontier/apprentice.h:430
local function textGrid(c, name, cols)
  local off, out = c:off(name), {}
  local rows = c.S.size(name) / (4 * cols)
  for r = 0, rows - 1 do
    local row = {}
    for j = 0, cols - 1 do row[j + 1] = textRef(c, c:ptr(off + (r * cols + j) * 4)) end
    out[r + 1] = row
  end
  return out
end

local function u8s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local challenge = {}
  local co = c:off("sApprenticeChallengeTexts")
  for i = 0, c.S.size("sApprenticeChallengeTexts") / 4 - 1 do challenge[i + 1] = textRef(c, c:ptr(co + i * 4)) end
  return true, c:finish({
    screen = "apprentice",
    firstMeeting = textGrid(c, "sApprenticeFirstMeetingTexts", 4),
    whichMon = textGrid(c, "sApprenticeWhichMonTexts", 2),
    heldItem = textGrid(c, "sApprenticeHeldItemTexts", 5),
    whichMove = textGrid(c, "sApprenticeWhichMoveTexts", 2),
    whichMonFirst = textGrid(c, "sApprenticeWhichMonFirstTexts", 2),
    pickWinSpeech = textGrid(c, "sApprenticePickWinSpeechTexts", 2),
    challenge = challenge,
    validMoves = u8s(c, "sValidApprenticeMoves"),
    questionPossibilities = u8s(c, "sQuestionPossibilities"),
    initialIds = u8s(c, "sInitialApprenticeIds"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
