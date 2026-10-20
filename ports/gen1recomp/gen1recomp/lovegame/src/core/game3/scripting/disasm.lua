-- Disassemble FRLG script bytecode into command rows.

local Opcodes = require("src.core.game3.scripting.opcodes")

local Disasm = {}

local function u8(bytes, i)
  return bytes[i] or 0, i + 1
end

local function u16(bytes, i)
  local lo = bytes[i] or 0
  local hi = bytes[i + 1] or 0
  return lo + hi * 256, i + 2
end

local function u32(bytes, i)
  local a, b, c, d = bytes[i] or 0, bytes[i + 1] or 0, bytes[i + 2] or 0, bytes[i + 3] or 0
  return a + b * 256 + c * 65536 + d * 16777216, i + 4
end

local TRAINER_BATTLE_PTRS = {
  SINGLE = { "introText", "defeatText" },
  REMATCH = { "introText", "defeatText" },
  CONTINUE_SCRIPT = { "introText", "defeatText", "eventScript" },
  CONTINUE_SCRIPT_NO_MUSIC = { "introText", "defeatText", "eventScript" },
  SINGLE_NO_INTRO_TEXT = { "defeatText" },
  DOUBLE = { "introText", "defeatText", "notEnoughText" },
  REMATCH_DOUBLE = { "introText", "defeatText", "notEnoughText" },
  CONTINUE_SCRIPT_DOUBLE = { "introText", "defeatText", "notEnoughText", "eventScript" },
  CONTINUE_SCRIPT_DOUBLE_NO_MUSIC = { "introText", "defeatText", "notEnoughText", "eventScript" },
  EARLY_RIVAL = { "defeatText", "victoryText" },
  PYRAMID = { "introText", "defeatText" },
  SET_TRAINER_A = { "introText", "defeatText" },
  SET_TRAINER_B = { "introText", "defeatText" },
  HILL = { "introText", "defeatText" },
}
Disasm.TRAINER_BATTLE_PTRS = TRAINER_BATTLE_PTRS

--- Decode one command at offset. Returns row, nextIndex (1-based).
function Disasm.decodeOne(bytes, i, set)
  set = set or Opcodes.active()
  local opb
  opb, i = u8(bytes, i)
  local def = set:get(opb)
  if not def then
    return { op = "unknown", byte = opb }, i
  end
  local row = { op = def.name, opcode = opb }
  if def.name == "trainerbattle" then
    -- pokeemerald/asm/macros/event.inc:730
    local typ
    typ, i = u8(bytes, i)
    local trainer
    trainer, i = u16(bytes, i)
    local localId
    localId, i = u16(bytes, i)
    row.type = typ
    row.trainer = trainer
    row.localId = localId
    row[1] = trainer
    row[2] = localId

    local kind = set:trainerBattleType(typ)
    local ptrs = kind and TRAINER_BATTLE_PTRS[kind]
    if ptrs then
      if kind == "EARLY_RIVAL" then row.flags = localId end
      for _, field in ipairs(ptrs) do
        local v
        v, i = u32(bytes, i)
        row[field] = v
      end
    else
      row.opaque = true
    end
    return row, i
  end
  for _, a in ipairs(def.args) do
    if a.kind == "byte" then
      local v
      v, i = u8(bytes, i)
      row[#row + 1] = v
    elseif a.kind == "half" then
      local v
      v, i = u16(bytes, i)
      row[#row + 1] = v
    elseif a.kind == "word" then
      local v
      v, i = u32(bytes, i)
      row[#row + 1] = v
    end
  end
  -- Named fields for common Tier A ops.
  if def.name == "loadword" then
    row.dest, row.value = row[1], row[2]
  elseif def.name == "callstd" or def.name == "gotostd" then
    row.std = row[1]
  elseif def.name == "setvar" or def.name == "compare_var_to_value" then
    row.var, row.value = row[1], row[2]
  elseif def.name == "setflag" or def.name == "clearflag" or def.name == "checkflag" then
    row.flag = row[1]
  elseif def.name == "goto" or def.name == "call" then
    row.target = row[1]
  elseif def.name == "goto_if" or def.name == "call_if" then
    row.cond, row.target = row[1], row[2]
  elseif def.name == "applymovement" then
    row.localId, row.movement = row[1], row[2]
  elseif def.name == "waitmovement" or def.name == "removeobject" or def.name == "addobject" then
    row.localId = row[1]
  elseif def.name == "message" then
    row.ptr = row[1]
  elseif def.name == "callnative" or def.name == "gotonative" then
    row.fn = row[1]
  elseif def.name == "special" then
    row.id = row[1]
  elseif def.name == "textcolor" then
    row.color = row[1]
  elseif def.name == "setworldmapflag" then
    row.flag = row[1]
  elseif def.name:find("^buffer", 1, true) then
    row.dest = row[1]
    row.src = row[2]
  end
  return row, i
end

--- Linear disasm until `end`/`return` or maxBytes.
function Disasm.decode(bytes, start, maxBytes, set)
  start = start or 1
  maxBytes = maxBytes or #bytes
  local rows = {}
  local i = start
  local limit = math.min(#bytes + 1, start + maxBytes)
  while i < limit do
    local row
    row, i = Disasm.decodeOne(bytes, i, set)
    rows[#rows + 1] = row
    if row.op == "end" or row.op == "return" or row.op == "unknown" then
      break
    end
  end
  return rows
end

--- Read movement stream until (and including) step_end 0xFE.
function Disasm.decodeMovement(bytes, start)
  start = start or 1
  local out = {}
  local i = start
  while i <= #bytes do
    local b = bytes[i]
    out[#out + 1] = b
    i = i + 1
    if b == Opcodes.STEP_END then break end
  end
  return out
end

--- Encode a small subset of Tier A command rows back to bytes (for tests).
function Disasm.encodeSimple(rows)
  local out = {}
  local function push(...)
    for j = 1, select("#", ...) do out[#out + 1] = select(j, ...) end
  end
  local function half(v)
    v = v % 65536
    push(v % 256, math.floor(v / 256))
  end
  local function word(v)
    v = v % 4294967296
    push(v % 256, math.floor(v / 256) % 256,
      math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256)
  end
  for _, row in ipairs(rows) do
    local name = row.op
    local found
    for byte, def in pairs(Opcodes.TABLE) do
      if def.name == name then found = byte; break end
    end
    if not found then error("unknown op " .. tostring(name)) end
    push(found)
    if name == "loadword" then
      push(row.dest or row[1] or 0)
      word(row.value or row[2] or 0)
    elseif name == "callstd" or name == "gotostd" then
      push(row.std or row[1] or 0)
    elseif name == "setvar" or name == "compare_var_to_value" then
      half(row.var or row[1] or 0)
      half(row.value or row[2] or 0)
    elseif name == "setflag" or name == "clearflag" or name == "checkflag"
        or name == "setworldmapflag" then
      half(row.flag or row[1] or 0)
    elseif name == "goto" or name == "call" then
      word(row.target or row[1] or 0)
    elseif name == "goto_if" or name == "call_if" then
      push(row.cond or row[1] or 0)
      word(row.target or row[2] or 0)
    elseif name == "applymovement" then
      half(row.localId or row[1] or 0)
      word(row.movement or row[2] or 0)
    elseif name == "waitmovement" or name == "removeobject" or name == "addobject" then
      half(row.localId or row[1] or 0)
    elseif name == "turnobject" then
      half(row.localId or row[1] or 0)
      push(row.direction or row[2] or 0)
    elseif name == "message" then
      word(row.ptr or row[1] or 0)
    elseif name == "callnative" then
      word(row.fn or row[1] or 0)
    elseif name == "special" then
      half(row.id or row[1] or 0)
    elseif name == "textcolor" then
      push(row.color or row[1] or 0)
    elseif name == "bufferspeciesname" or name == "bufferitemname"
        or name == "buffernumberstring" or name == "bufferstdstring"
        or name == "bufferpartymonnick" or name == "buffermovename"
        or name == "bufferdecorationname" then
      push(row.dest or row[1] or 0)
      half(row.src or row[2] or 0)
    elseif name == "bufferleadmonspeciesname" then
      push(row.dest or row[1] or 0)
    elseif name == "bufferstring" then
      push(row.dest or row[1] or 0)
      word(row.src or row[2] or 0)
    end
    -- zero-arg ops: end, lock, release, faceplayer, …
  end
  return out
end

return Disasm
