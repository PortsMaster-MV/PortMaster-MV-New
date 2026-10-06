local Disasm = require("src.core.game3.rse.contest_ai_disasm")

local Ai = {}

local MAX_MON_MOVES = 4
local CONTESTANT_COUNT = 4

-- pokeemerald/include/contest_ai.h:5
Ai.SETTING_UP, Ai.PROCESSING, Ai.FINISHED, Ai.DO_NOT_PROCESS = 0, 1, 2, 3
local ACTION_DONE = 1

local function s16(v)
  v = math.floor(v) % 65536
  return v >= 32768 and v - 65536 or v
end
local function s8(v)
  v = math.floor(v) % 256
  return v >= 128 and v - 256 or v
end
Ai.s16, Ai.s8 = s16, s8

local function band1(v) return v % 2 end

function Ai.script(data)
  local blob = data.blob
  local bytes = {}
  for i = 1, #blob, 2 do bytes[#bytes + 1] = tonumber(blob:sub(i, i + 1), 16) end
  local base = data.base
  local function read(addr)
    local v = bytes[addr - base + 1]
    if v == nil then error(string.format("contest ai: read outside scripts 0x%08X", addr)) end
    return v
  end
  return { read = read, entries = data.entries, base = base, size = data.size }
end

-- pokeemerald/src/contest_ai.c:298
function Ai.reset(c, contestant)
  c.ai = {
    aiState = 0, nextMove = 0, nextMoveIndex = 0, moveScores = { [0] = 100, 100, 100, 100 },
    aiAction = 0, currentAIFlag = 0, aiFlags = c.mons[contestant].aiFlags or 0,
    scriptResult = 0, vars = { [0] = 0, 0, 0 }, stack = {}, stackSize = 0, contestantId = contestant,
    ptr = 0,
  }
  return c.ai
end

local H = {}

local function rd(c, off) return c.aiScript.read(c.ai.ptr + off) end
local function rd16(c, off) return Disasm.u16(c.aiScript.read, c.ai.ptr + off) end
local function rdPtr(c, off) return Disasm.u32(c.aiScript.read, c.ai.ptr + off) end

local function jumpIf(c, cond, ptrOff, skip)
  if cond then c.ai.ptr = rdPtr(c, ptrOff) else c.ai.ptr = c.ai.ptr + skip end
end

local function setResult(c, v) c.ai.scriptResult = s16(v) end

local function curMove(c)
  return c.mons[c.ai.contestantId].moves[c.ai.nextMoveIndex] or 0
end

local function contestantByTurn(c, turn)
  local i = 0
  while i < CONTESTANT_COUNT do
    if c.results.turnOrder[i] == turn then break end
    i = i + 1
  end
  return i
end

local function status(c, i)
  return assert(c.status[i], "contest ai: no contestant for turn")
end

local function cmpRes(kind, r, v)
  if kind == "lt" then return r < v elseif kind == "gt" then return r > v
  elseif kind == "eq" then return r == v else return r ~= v end
end
local KINDS = { "lt", "gt", "eq", "ne" }

local function getterFamily(first, getter, argKind)
  H[first] = function(c) getter(c); c.ai.ptr = c.ai.ptr + 1 end
  for k = 1, 4 do
    local kind = KINDS[k]
    H[first + k] = function(c)
      getter(c)
      c.ai.ptr = c.ai.ptr + 1
      local v
      if argKind == "s16" then
        v = s16(rd16(c, 0))
        jumpIf(c, cmpRes(kind, c.ai.scriptResult, v), 2, 6)
      else
        v = rd(c, 0)
        if argKind == "s8" then v = s8(v) end
        jumpIf(c, cmpRes(kind, c.ai.scriptResult, v), 1, 5)
      end
    end
  end
end

-- pokeemerald/src/contest_ai.c:395
H[0x00] = function(c)
  local ai = c.ai
  local score = ai.moveScores[ai.nextMoveIndex] + s8(rd(c, 1))
  if score > 255 then score = 255 elseif score < 0 then score = 0 end
  ai.moveScores[ai.nextMoveIndex] = score
  ai.ptr = ai.ptr + 2
end

getterFamily(0x01, function(c) setResult(c, c.contest.appealNumber) end)
getterFamily(0x06, function(c) setResult(c, c.contest.applauseLevel) end)
getterFamily(0x0B, function(c) setResult(c, c.results.turnOrder[c.ai.contestantId]) end)
getterFamily(0x10, function(c)
  local cond = status(c, c.ai.contestantId).condition
  setResult(c, cond >= 0 and math.floor(cond / 10) or -math.floor(-cond / 10))
end)
getterFamily(0x15, function(c) setResult(c, status(c, c.ai.contestantId).pointTotal) end, "s16")
getterFamily(0x1A, function(c) setResult(c, c.round1[c.ai.contestantId]) end, "s16")

-- pokeemerald/src/contest_ai.c:685
H[0x1F] = function(c) setResult(c, c.category); c.ai.ptr = c.ai.ptr + 1 end
H[0x20] = function(c) H[0x1F](c); jumpIf(c, c.ai.scriptResult == rd(c, 0), 1, 5) end
H[0x21] = function(c) H[0x1F](c); jumpIf(c, c.ai.scriptResult ~= rd(c, 0), 1, 5) end

getterFamily(0x22, function(c) setResult(c, c:moveExcitement(curMove(c))) end, "s8")

local function effectOf(c, move) return c.data.moves[move].effect end
local function effectRow(c, move) return c.data.effects[effectOf(c, move)] end

-- pokeemerald/src/contest_ai.c:757
H[0x27] = function(c) setResult(c, effectOf(c, curMove(c))); c.ai.ptr = c.ai.ptr + 1 end
H[0x28] = function(c) H[0x27](c); jumpIf(c, c.ai.scriptResult == rd(c, 0), 1, 5) end
H[0x29] = function(c) H[0x27](c); jumpIf(c, c.ai.scriptResult ~= rd(c, 0), 1, 5) end
H[0x2A] = function(c) setResult(c, effectRow(c, curMove(c)).effectType); c.ai.ptr = c.ai.ptr + 1 end
H[0x2B] = function(c) H[0x2A](c); jumpIf(c, c.ai.scriptResult == rd(c, 0), 1, 5) end
H[0x2C] = function(c) H[0x2A](c); jumpIf(c, c.ai.scriptResult ~= rd(c, 0), 1, 5) end

-- pokeemerald/src/contest_ai.c:813
local function mostOf(c, field)
  local moves = c.mons[c.ai.contestantId].moves
  local mine = effectRow(c, curMove(c))[field]
  local i = 0
  while i < MAX_MON_MOVES do
    local m = moves[i] or 0
    if m ~= 0 and mine < effectRow(c, m)[field] then break end
    i = i + 1
  end
  setResult(c, i == MAX_MON_MOVES and 1 or 0)
  c.ai.ptr = c.ai.ptr + 1
end
H[0x2D] = function(c) mostOf(c, "appeal") end
H[0x2E] = function(c) H[0x2D](c); jumpIf(c, c.ai.scriptResult ~= 0, 0, 4) end
H[0x2F] = function(c) mostOf(c, "jam") end
H[0x30] = function(c) H[0x2F](c); jumpIf(c, c.ai.scriptResult ~= 0, 1, 5) end

getterFamily(0x31, function(c) setResult(c, math.floor(effectRow(c, curMove(c)).appeal / 10)) end)
getterFamily(0x36, function(c) setResult(c, math.floor(effectRow(c, curMove(c)).jam / 10)) end)
-- pokeemerald/src/contest_ai.c:971
getterFamily(0x3B, function(c)
  local st = status(c, c.ai.contestantId)
  if curMove(c) ~= st.prevMove then setResult(c, 0) else setResult(c, st.moveRepeatCount + 1) end
end)

local function flagFamily(first, check)
  H[first] = function(c) check(c); c.ai.ptr = c.ai.ptr + 1 end
  H[first + 1] = function(c) H[first](c); jumpIf(c, c.ai.scriptResult ~= 0, 0, 4) end
  H[first + 2] = function(c) H[first](c); jumpIf(c, c.ai.scriptResult == 0, 0, 4) end
end

-- pokeemerald/src/contest_ai.c:1025
flagFamily(0x40, function(c)
  local moves, move, result = c.mons[c.ai.contestantId].moves, curMove(c), 0
  for i = 0, MAX_MON_MOVES - 1 do
    local m = moves[i] or 0
    if m ~= 0 then
      result = c:areMovesCombo(move, m)
      if result ~= 0 then result = 1; break end
    end
  end
  setResult(c, result ~= 0 and 1 or 0)
end)
-- pokeemerald/src/contest_ai.c:1071
flagFamily(0x43, function(c)
  local moves, move, result = c.mons[c.ai.contestantId].moves, curMove(c), 0
  for i = 0, MAX_MON_MOVES - 1 do
    local m = moves[i] or 0
    if m ~= 0 then
      result = c:areMovesCombo(m, move)
      if result ~= 0 then result = 1; break end
    end
  end
  setResult(c, result ~= 0 and 1 or 0)
end)
-- pokeemerald/src/contest_ai.c:1117
flagFamily(0x46, function(c)
  local st, result = status(c, c.ai.contestantId), 0
  if st.prevMove ~= 0 then result = c:areMovesCombo(st.prevMove, curMove(c)) end
  setResult(c, result ~= 0 and 1 or 0)
end)

local function monFamily(first, getter)
  H[first] = function(c) getter(c, contestantByTurn(c, rd(c, 1))); c.ai.ptr = c.ai.ptr + 2 end
  for k = 1, 4 do
    local kind = KINDS[k]
    H[first + k] = function(c)
      H[first](c)
      jumpIf(c, cmpRes(kind, c.ai.scriptResult, rd(c, 0)), 1, 5)
    end
  end
end

-- pokeemerald/src/contest_ai.c:1152
monFamily(0x49, function(c, i)
  local cond = status(c, i).condition
  setResult(c, cond >= 0 and math.floor(cond / 10) or -math.floor(-cond / 10))
end)
-- pokeemerald/src/contest_ai.c:1200
monFamily(0x4E, function(c, i)
  local result = 0
  if c:isAllowedToCombo(i) then
    result = c.data.moves[status(c, i).prevMove].comboStarterId ~= 0 and 1 or 0
  end
  setResult(c, result)
end)

local function monFlagFamily(first, getter)
  H[first] = function(c) getter(c, contestantByTurn(c, rd(c, 1))); c.ai.ptr = c.ai.ptr + 2 end
  H[first + 1] = function(c) H[first](c); jumpIf(c, c.ai.scriptResult ~= 0, 0, 4) end
  H[first + 2] = function(c) H[first](c); jumpIf(c, c.ai.scriptResult == 0, 0, 4) end
end

-- pokeemerald/src/contest_ai.c:1252
monFlagFamily(0x53, function(c, i) setResult(c, c:isTurnDisabled(i) and 0 or 1) end)
-- pokeemerald/src/contest_ai.c:1282
monFlagFamily(0x56, function(c, i) setResult(c, status(c, i).completedComboFlag) end)

local function diffFamily(first, getter)
  H[first] = function(c) getter(c, contestantByTurn(c, rd(c, 1))); c.ai.ptr = c.ai.ptr + 2 end
  local conds = {
    function(r) return r < 0 end, function(r) return r > 0 end,
    function(r) return r == 0 end, function(r) return r ~= 0 end,
  }
  for k = 1, 4 do
    H[first + k] = function(c) H[first](c); jumpIf(c, conds[k](c.ai.scriptResult), 0, 4) end
  end
end

-- pokeemerald/src/contest_ai.c:1310
diffFamily(0x59, function(c, i)
  setResult(c, status(c, i).pointTotal - status(c, c.ai.contestantId).pointTotal)
end)
-- pokeemerald/src/contest_ai.c:1358
diffFamily(0x5E, function(c, i)
  setResult(c, c.round1[i] - c.round1[c.ai.contestantId])
end)

local function roundFamily(first, getter, count)
  H[first] = function(c)
    getter(c, contestantByTurn(c, rd(c, 1)), rd(c, 2))
    c.ai.ptr = c.ai.ptr + 3
  end
  for k = 1, count do
    local kind = count == 2 and KINDS[k + 2] or KINDS[k]
    H[first + k] = function(c)
      H[first](c)
      jumpIf(c, cmpRes(kind, c.ai.scriptResult, rd(c, 0)), 1, 5)
    end
  end
end

-- pokeemerald/src/contest_ai.c:1406
roundFamily(0x63, function(c, i, round) setResult(c, effectOf(c, c:historyMove(round, i))) end, 4)
-- pokeemerald/src/contest_ai.c:1456
roundFamily(0x68, function(c, i, round) setResult(c, c:historyExcitement(round, i)) end, 4)
-- pokeemerald/src/contest_ai.c:1506
roundFamily(0x6D, function(c, i, round) setResult(c, effectRow(c, c:historyMove(round, i)).effectType) end, 2)

local function var(c, idx)
  local v = c.ai.vars[idx]
  if v == nil then v = c:uninitVar(idx) end
  return v
end
local function setVar(c, idx, v)
  if idx <= 2 then c.ai.vars[idx] = s16(v) end
end

-- pokeemerald/src/contest_ai.c:1536
H[0x70] = function(c) setVar(c, rd(c, 1), c.ai.scriptResult); c.ai.ptr = c.ai.ptr + 2 end
H[0x71] = function(c) setVar(c, rd(c, 1), rd16(c, 2)); c.ai.ptr = c.ai.ptr + 4 end
H[0x72] = function(c)
  local lo, hi = s8(rd(c, 2)), rd(c, 3)
  local add = lo < 0 and lo or lo + hi * 256
  local idx = rd(c, 1)
  setVar(c, idx, var(c, idx) + add)
  c.ai.ptr = c.ai.ptr + 4
end
H[0x73] = function(c)
  local a, b = rd(c, 1), rd(c, 2)
  setVar(c, a, var(c, a) + var(c, b))
  c.ai.ptr = c.ai.ptr + 3
end
H[0x74] = H[0x73]
for k = 1, 4 do
  local kind = KINDS[k]
  H[0x74 + k] = function(c)
    jumpIf(c, cmpRes(kind, var(c, rd(c, 1)), rd16(c, 2)), 4, 8)
  end
  H[0x78 + k] = function(c)
    jumpIf(c, cmpRes(kind, var(c, rd(c, 1)), var(c, rd(c, 2))), 3, 7)
  end
end

-- pokeemerald/src/contest_ai.c:1634
H[0x7D] = function(c)
  local r = c:random() % 256
  jumpIf(c, r < var(c, rd(c, 1)), 2, 6)
end
-- pokeemerald/src/contest_ai.c:1646
H[0x7E] = function(c)
  local r = c:random() % 256
  jumpIf(c, r > var(c, rd(c, 1)), 2, 6)
end

-- pokeemerald/src/contest_ai.c:1658
H[0x7F] = function(c) c.ai.ptr = rdPtr(c, 1) end
H[0x80] = function(c)
  local ai = c.ai
  ai.stack[ai.stackSize] = ai.ptr + 5
  ai.stackSize = ai.stackSize + 1
  ai.ptr = rdPtr(c, 1)
end
H[0x81] = function(c)
  local ai = c.ai
  if ai.stackSize ~= 0 then
    ai.stackSize = ai.stackSize - 1
    ai.ptr = ai.stack[ai.stackSize]
  else
    ai.aiAction = ai.aiAction - ai.aiAction % 2 + ACTION_DONE
  end
end

-- pokeemerald/src/contest_ai.c:1694
flagFamily(0x82, function(c)
  local moves, result = c.mons[c.ai.contestantId].moves, 0
  for i = 0, MAX_MON_MOVES - 1 do
    local m = moves[i] or 0
    if m ~= 0 and c:moveExcitement(m) == 1 then result = 1; break end
  end
  setResult(c, result)
end)

-- pokeemerald/src/contest_ai.c:1742
H[0x85] = function(c)
  local target, moves, has = rd16(c, 1), c.mons[c.ai.contestantId].moves, 0
  for i = 0, MAX_MON_MOVES - 1 do
    if (moves[i] or 0) == target then has = 1; break end
  end
  setResult(c, has)
  c.ai.ptr = c.ai.ptr + 3
end
H[0x86] = function(c) H[0x85](c); jumpIf(c, c.ai.scriptResult ~= 0, 0, 4) end
H[0x87] = function(c) H[0x85](c); jumpIf(c, c.ai.scriptResult == 0, 0, 4) end

Ai.HANDLERS = H

function Ai.step(c)
  local code = c.aiScript.read(c.ai.ptr)
  local h = H[code]
  if not h then error(string.format("contest ai: no handler for op 0x%02X", code)) end
  h(c)
end

-- pokeemerald/src/contest_ai.c:342
local function process(c)
  local ai = c.ai
  local guard = 0
  while ai.aiState ~= Ai.FINISHED do
    guard = guard + 1
    if guard > 200000 then error("contest ai: script did not finish") end
    if ai.aiState == Ai.SETTING_UP then
      ai.ptr = c.aiScript.entries[ai.currentAIFlag]
      local m = c.mons[ai.contestantId].moves[ai.nextMoveIndex] or 0
      ai.nextMove = m
      ai.aiState = Ai.PROCESSING
    elseif ai.aiState == Ai.PROCESSING then
      if ai.nextMove ~= 0 then
        Ai.step(c)
      else
        ai.moveScores[ai.nextMoveIndex] = 0
        ai.aiAction = ai.aiAction - ai.aiAction % 2 + ACTION_DONE
      end
      if band1(ai.aiAction) == 1 then
        ai.nextMoveIndex = ai.nextMoveIndex + 1
        if ai.nextMoveIndex < MAX_MON_MOVES then ai.aiState = 0 else ai.aiState = ai.aiState + 1 end
        ai.aiAction = ai.aiAction - 1
      end
    else
      break
    end
  end
end

-- pokeemerald/src/contest_ai.c:311
function Ai.getActionToUse(c)
  local ai = c.ai
  while ai.aiFlags ~= 0 do
    if ai.aiFlags % 2 == 1 then
      ai.aiState = Ai.SETTING_UP
      process(c)
    end
    ai.aiFlags = math.floor(ai.aiFlags / 2)
    ai.currentAIFlag = ai.currentAIFlag + 1
    ai.nextMoveIndex = 0
  end
  while true do
    local moveIndex = c:random() % MAX_MON_MOVES
    local score = ai.moveScores[moveIndex]
    local i = 0
    while i < MAX_MON_MOVES do
      if score < ai.moveScores[i] then break end
      i = i + 1
    end
    if i == MAX_MON_MOVES then return moveIndex end
  end
end

return Ai
