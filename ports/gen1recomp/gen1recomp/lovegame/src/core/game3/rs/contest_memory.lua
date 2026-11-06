local M = {AI_BASE = 0x192E4, AI_SIZE = 0x44, EXCITEMENT_BASE = 0x19328,
  GFX_BASE = 0x19338, MOVE_ANIM_BASE = 0x19348}

local function byte(v, shift) return math.floor((tonumber(v) or 0) / 2 ^ (shift or 0)) % 256 end
local function flag(v) return v == true or (type(v) == "number" and v ~= 0) end
local function bit(v, shift) return flag(v) and 2 ^ shift or 0 end
local function s16(v) v = v % 65536; return v >= 32768 and v - 65536 or v end

-- pokeruby/include/contest.h:271
local function aiByte(c, off)
  local a = c.ai
  if not a then return nil end
  if off == 0 then return byte(a.aiState) end
  if off >= 2 and off <= 3 then return byte(a.nextMove, (off - 2) * 8) end
  if off == 4 then return byte(a.nextMoveIndex) end
  if off >= 5 and off <= 8 then return byte(a.moveScores and a.moveScores[off - 5]) end
  if off == 9 then return byte(a.aiAction) end
  if off == 16 then return byte(a.currentAIFlag) end
  if off >= 20 and off <= 23 then return byte(a.aiFlags, (off - 20) * 8) end
  if off >= 24 and off <= 25 then return byte(a.scriptResult, (off - 24) * 8) end
  if off >= 26 and off <= 31 then
    local n = off - 26
    return byte(a.vars and a.vars[math.floor(n / 2)], n % 2 * 8)
  end
  if off >= 32 and off <= 63 then
    local n = off - 32
    return byte(a.stack and a.stack[math.floor(n / 4)], n % 4 * 8)
  end
  if off == 64 then return byte(a.stackSize) end
  if off == 65 then return byte(a.contestantId) end
  return 0
end

local function excitationByte(c, off)
  local x = c.excitement
  if not x then return nil end
  if off == 0 then return byte(x.moveExcitement) end
  if off == 1 then return bit(x.frozen, 0) + byte(x.freezer) % 8 * 2 end
  if off == 2 then return byte(x.excitementAppealBonus) end
  return 0
end

local function gfxByte(c, off)
  local rows = c.nativeContestGfx
  local row = rows and rows[math.floor(off / 4)]
  if not row then return nil end
  local n = off % 4
  if n == 0 then return row.sliderHeartSpriteId ~= nil and byte(row.sliderHeartSpriteId) or nil end
  if n == 1 then return row.nextTurnSpriteId ~= nil and byte(row.nextTurnSpriteId) or nil end
  if n == 2 then
    return bit(row.sliderUpdating, 0) + bit(row.boxBlinking, 1) + bit(row.updatingAppealHearts, 2)
  end
  return 0
end

local function moveByte(c, off)
  local row = c.nativeContestMoveAnim
  if not row then return nil end
  if off < 2 then return byte(row.species, off * 8) end
  if off < 4 then return byte(row.targetSpecies, (off - 2) * 8) end
  if off == 4 then return bit(row.hasTargetAnim, 0) end
  if off == 5 then return byte(row.contestant) end
  if off < 8 then return 0 end
  if off < 12 then return byte(row.personality, (off - 8) * 8) end
  if off < 16 then return byte(row.otId, (off - 12) * 8) end
  return byte(row.targetPersonality, (off - 16) * 8)
end

local function priorByte(c, addr)
  local mem = c.nativeContestRam
  if type(mem) == "function" then return mem(addr, c) end
  if type(mem) ~= "table" then return nil end
  if type(mem.read) == "function" then
    local value = mem.read(addr, c)
    if value ~= nil then return value end
  end
  if mem[addr] ~= nil then return mem[addr] end
  local bytes, i = mem.bytes, addr - (mem.base or M.AI_BASE) + 1
  if i < 1 then return nil end
  if type(bytes) == "string" then return bytes:byte(i) end
  if type(bytes) == "table" then return bytes[i] end
end

-- pokeruby/include/ewram.h:65
function M.readByte(c, addr)
  local value
  if addr >= M.AI_BASE and addr < M.AI_BASE + M.AI_SIZE then value = aiByte(c, addr - M.AI_BASE)
  elseif addr >= M.EXCITEMENT_BASE and addr < M.EXCITEMENT_BASE + 4 then value = excitationByte(c, addr - M.EXCITEMENT_BASE)
  elseif addr >= M.GFX_BASE and addr < M.GFX_BASE + 16 then value = gfxByte(c, addr - M.GFX_BASE)
  elseif addr >= M.MOVE_ANIM_BASE and addr < M.MOVE_ANIM_BASE + 20 then value = moveByte(c, addr - M.MOVE_ANIM_BASE) end
  if value == nil then value = priorByte(c, addr) end
  if value ~= nil then return byte(value) end
  c.nativeContestOpaqueReads = c.nativeContestOpaqueReads or {}
  c.nativeContestOpaqueReads[addr] = true
  return 0
end

-- contest_ai.c:1633
function M.uninitVar(c, index)
  local addr = M.AI_BASE + 0x1A + index * 2
  return s16(M.readByte(c, addr) + M.readByte(c, addr + 1) * 256)
end
return M
