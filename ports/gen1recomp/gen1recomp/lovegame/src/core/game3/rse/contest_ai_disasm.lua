local Disasm = {}

local function op(name, size, args, jump, flow)
  return { name = name, size = size, args = args or {}, jump = jump, flow = flow }
end

local function getter(name) return op(name, 1) end
local function ifU8(name) return op(name, 6, { { "num", 1, "u8" } }, 2) end
local function ifS8(name) return op(name, 6, { { "num", 1, "s8" } }, 2) end
local function ifS16(name) return op(name, 7, { { "num", 1, "s16" } }, 3) end
local function ifFlag(name) return op(name, 5, {}, 1) end
local function monGet(name) return op(name, 2, { { "mon", 1, "u8" } }) end
local function monIfU8(name) return op(name, 7, { { "mon", 1, "u8" }, { "num", 2, "u8" } }, 3) end
local function monIfFlag(name) return op(name, 6, { { "mon", 1, "u8" } }, 2) end
local function roundGet(name) return op(name, 3, { { "mon", 1, "u8" }, { "round", 2, "u8" } }) end
local function roundIf(name) return op(name, 8, { { "mon", 1, "u8" }, { "round", 2, "u8" }, { "num", 3, "u8" } }, 4) end

-- pokeemerald/src/contest_ai.c:153
Disasm.OPS = {
  [0x00] = op("score", 2, { { "score", 1, "s8" } }),
  [0x01] = getter("get_appeal_num"),
  [0x02] = ifU8("if_appeal_num_less_than"),
  [0x03] = ifU8("if_appeal_num_more_than"),
  [0x04] = ifU8("if_appeal_num_eq"),
  [0x05] = ifU8("if_appeal_num_not_eq"),
  [0x06] = getter("get_excitement"),
  [0x07] = ifU8("if_excitement_less_than"),
  [0x08] = ifU8("if_excitement_more_than"),
  [0x09] = ifU8("if_excitement_eq"),
  [0x0A] = ifU8("if_excitement_not_eq"),
  [0x0B] = getter("get_user_order"),
  [0x0C] = ifU8("if_user_order_less_than"),
  [0x0D] = ifU8("if_user_order_more_than"),
  [0x0E] = ifU8("if_user_order_eq"),
  [0x0F] = ifU8("if_user_order_not_eq"),
  [0x10] = getter("get_user_condition"),
  [0x11] = ifU8("if_user_condition_less_than"),
  [0x12] = ifU8("if_user_condition_more_than"),
  [0x13] = ifU8("if_user_condition_eq"),
  [0x14] = ifU8("if_user_condition_not_eq"),
  [0x15] = getter("get_points"),
  [0x16] = ifS16("if_points_less_than"),
  [0x17] = ifS16("if_points_more_than"),
  [0x18] = ifS16("if_points_eq"),
  [0x19] = ifS16("if_points_not_eq"),
  [0x1A] = getter("get_preliminary_points"),
  [0x1B] = ifS16("if_preliminary_points_less_than"),
  [0x1C] = ifS16("if_preliminary_points_more_than"),
  [0x1D] = ifS16("if_preliminary_points_eq"),
  [0x1E] = ifS16("if_preliminary_points_not_eq"),
  [0x1F] = getter("get_contest_type"),
  [0x20] = ifU8("if_contest_type_eq"),
  [0x21] = ifU8("if_contest_type_not_eq"),
  [0x22] = getter("get_move_excitement"),
  [0x23] = ifS8("if_move_excitement_less_than"),
  [0x24] = ifS8("if_move_excitement_more_than"),
  [0x25] = ifS8("if_move_excitement_eq"),
  [0x26] = ifS8("if_move_excitement_not_eq"),
  [0x27] = getter("get_effect"),
  [0x28] = ifU8("if_effect_eq"),
  [0x29] = ifU8("if_effect_not_eq"),
  [0x2A] = getter("get_effect_type"),
  [0x2B] = ifU8("if_effect_type_eq"),
  [0x2C] = ifU8("if_effect_type_not_eq"),
  [0x2D] = getter("check_most_appealing_move"),
  [0x2E] = ifFlag("if_most_appealing_move"),
  [0x2F] = getter("check_most_jamming_move"),
  -- pokeemerald/src/contest_ai.c:865
  [0x30] = op("if_most_jamming_move", 6, {}, 2),
  [0x31] = getter("get_num_move_hearts"),
  [0x32] = ifU8("if_num_move_hearts_less_than"),
  [0x33] = ifU8("if_num_move_hearts_more_than"),
  [0x34] = ifU8("if_num_move_hearts_eq"),
  [0x35] = ifU8("if_num_move_hearts_not_eq"),
  [0x36] = getter("get_num_move_jam_hearts"),
  [0x37] = ifU8("if_num_move_jam_hearts_less_than"),
  [0x38] = ifU8("if_num_move_jam_hearts_more_than"),
  [0x39] = ifU8("if_num_move_jam_hearts_eq"),
  [0x3A] = ifU8("if_num_move_jam_hearts_not_eq"),
  [0x3B] = getter("get_move_used_count"),
  [0x3C] = ifU8("if_move_used_count_less_than"),
  [0x3D] = ifU8("if_move_used_count_more_than"),
  [0x3E] = ifU8("if_move_used_count_eq"),
  [0x3F] = ifU8("if_move_used_count_not_eq"),
  [0x40] = getter("check_combo_starter"),
  [0x41] = ifFlag("if_combo_starter"),
  [0x42] = ifFlag("if_not_combo_starter"),
  [0x43] = getter("check_combo_finisher"),
  [0x44] = ifFlag("if_combo_finisher"),
  [0x45] = ifFlag("if_not_combo_finisher"),
  [0x46] = getter("check_would_finish_combo"),
  [0x47] = ifFlag("if_would_finish_combo"),
  [0x48] = ifFlag("if_would_not_finish_combo"),
  [0x49] = monGet("get_condition"),
  [0x4A] = monIfU8("if_condition_less_than"),
  [0x4B] = monIfU8("if_condition_more_than"),
  [0x4C] = monIfU8("if_condition_eq"),
  [0x4D] = monIfU8("if_condition_not_eq"),
  [0x4E] = monGet("get_used_combo_starter"),
  [0x4F] = monIfU8("if_used_combo_starter_less_than"),
  [0x50] = monIfU8("if_used_combo_starter_more_than"),
  [0x51] = monIfU8("if_used_combo_starter_eq"),
  [0x52] = monIfU8("if_used_combo_starter_not_eq"),
  [0x53] = monGet("check_can_participate"),
  [0x54] = monIfFlag("if_can_participate"),
  [0x55] = monIfFlag("if_cannot_participate"),
  [0x56] = monGet("get_completed_combo"),
  [0x57] = monIfFlag("if_completed_combo"),
  [0x58] = monIfFlag("if_not_completed_combo"),
  [0x59] = monGet("get_points_diff"),
  [0x5A] = monIfFlag("if_points_more_than_mon"),
  [0x5B] = monIfFlag("if_points_less_than_mon"),
  [0x5C] = monIfFlag("if_points_eq_mon"),
  [0x5D] = monIfFlag("if_points_not_eq_mon"),
  [0x5E] = monGet("get_preliminary_points_diff"),
  [0x5F] = monIfFlag("if_preliminary_points_more_than_mon"),
  [0x60] = monIfFlag("if_preliminary_points_less_than_mon"),
  [0x61] = monIfFlag("if_preliminary_points_eq_mon"),
  [0x62] = monIfFlag("if_preliminary_points_not_eq_mon"),
  [0x63] = roundGet("get_used_moves_effect"),
  [0x64] = roundIf("if_used_moves_effect_less_than"),
  [0x65] = roundIf("if_used_moves_effect_more_than"),
  [0x66] = roundIf("if_used_moves_effect_eq"),
  [0x67] = roundIf("if_used_moves_effect_not_eq"),
  [0x68] = roundGet("get_used_moves_excitement"),
  [0x69] = roundIf("if_used_moves_excitement_less_than"),
  [0x6A] = roundIf("if_used_moves_excitement_more_than"),
  [0x6B] = roundIf("if_used_moves_excitement_eq"),
  [0x6C] = roundIf("if_used_moves_excitement_not_eq"),
  [0x6D] = roundGet("get_used_moves_effect_type"),
  [0x6E] = roundIf("if_used_moves_effect_type_eq"),
  [0x6F] = roundIf("if_used_moves_effect_type_not_eq"),
  [0x70] = op("save_result", 2, { { "var", 1, "u8" } }),
  [0x71] = op("setvar", 4, { { "var", 1, "u8" }, { "num", 2, "u16" } }),
  [0x72] = op("add", 4, { { "var", 1, "u8" }, { "lo", 2, "s8" }, { "hi", 3, "u8" } }),
  [0x73] = op("addvar", 3, { { "var", 1, "u8" }, { "var2", 2, "u8" } }),
  [0x74] = op("addvar_duplicate", 3, { { "var", 1, "u8" }, { "var2", 2, "u8" } }),
  [0x75] = op("if_less_than", 8, { { "var", 1, "u8" }, { "num", 2, "u16" } }, 4),
  [0x76] = op("if_greater_than", 8, { { "var", 1, "u8" }, { "num", 2, "u16" } }, 4),
  [0x77] = op("if_eq", 8, { { "var", 1, "u8" }, { "num", 2, "u16" } }, 4),
  [0x78] = op("if_not_eq", 8, { { "var", 1, "u8" }, { "num", 2, "u16" } }, 4),
  [0x79] = op("if_less_than_var", 7, { { "var", 1, "u8" }, { "var2", 2, "u8" } }, 3),
  [0x7A] = op("if_greater_than_var", 7, { { "var", 1, "u8" }, { "var2", 2, "u8" } }, 3),
  [0x7B] = op("if_eq_var", 7, { { "var", 1, "u8" }, { "var2", 2, "u8" } }, 3),
  [0x7C] = op("if_not_eq_var", 7, { { "var", 1, "u8" }, { "var2", 2, "u8" } }, 3),
  [0x7D] = op("if_random_less_than", 6, { { "num", 1, "u8" } }, 2),
  [0x7E] = op("if_random_greater_than", 6, { { "num", 1, "u8" } }, 2),
  [0x7F] = op("goto", 5, {}, 1, "goto"),
  [0x80] = op("call", 5, {}, 1, "call"),
  [0x81] = op("end", 1, {}, nil, "end"),
  [0x82] = getter("check_user_has_exciting_move"),
  [0x83] = ifFlag("if_user_has_exciting_move"),
  [0x84] = ifFlag("if_user_doesnt_have_exciting_move"),
  [0x85] = op("check_user_has_move", 3, { { "move", 1, "u16" } }),
  [0x86] = op("if_user_has_move", 7, { { "move", 1, "u16" } }, 3),
  [0x87] = op("if_user_doesnt_have_move", 7, { { "move", 1, "u16" } }, 3),
}

Disasm.COUNT = 0x88

local function u8(read, a) return read(a) end
local function s8(read, a)
  local v = read(a)
  return v >= 0x80 and v - 0x100 or v
end
local function u16(read, a) return read(a) + read(a + 1) * 256 end
local function s16(read, a)
  local v = u16(read, a)
  return v >= 0x8000 and v - 0x10000 or v
end
local function u32(read, a) return u16(read, a) + u16(read, a + 2) * 65536 end
local READERS = { u8 = u8, s8 = s8, u16 = u16, s16 = s16 }

Disasm.u8, Disasm.s8, Disasm.u16, Disasm.s16, Disasm.u32 = u8, s8, u16, s16, u32

function Disasm.decode(read, addr)
  local code = read(addr)
  local def = Disasm.OPS[code]
  if not def then return nil, string.format("contest ai: unknown op 0x%02X at 0x%08X", code or -1, addr) end
  local ins = { addr = addr, op = code, name = def.name, size = def.size, flow = def.flow, args = {} }
  for _, a in ipairs(def.args) do ins.args[a[1]] = READERS[a[3]](read, addr + a[2]) end
  if def.jump then ins.target = u32(read, addr + def.jump) end
  return ins
end

function Disasm.walk(read, entries, inRange)
  local seen, order, queue, lo, hi = {}, {}, {}, nil, nil
  for _, e in ipairs(entries) do queue[#queue + 1] = e end
  while #queue > 0 do
    local addr = table.remove(queue)
    while addr and not seen[addr] do
      if inRange and not inRange(addr) then error(string.format("contest ai: jump out of range 0x%08X", addr)) end
      local ins, err = Disasm.decode(read, addr)
      if not ins then error(err) end
      seen[addr] = ins
      order[#order + 1] = addr
      lo = (not lo or addr < lo) and addr or lo
      hi = (not hi or addr + ins.size > hi) and addr + ins.size or hi
      if ins.target then queue[#queue + 1] = ins.target end
      if ins.flow == "goto" or ins.flow == "end" then
        addr = nil
      else
        addr = addr + ins.size
      end
    end
  end
  table.sort(order)
  return { ins = seen, order = order, lo = lo, hi = hi }
end

function Disasm.listing(walk)
  local out = {}
  for _, a in ipairs(walk.order) do
    local ins = walk.ins[a]
    local parts = { string.format("%08X %s", a, ins.name) }
    local keys = {}
    for k in pairs(ins.args) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. tostring(ins.args[k]) end
    if ins.target then parts[#parts + 1] = string.format("-> %08X", ins.target) end
    out[#out + 1] = table.concat(parts, " ")
  end
  return out
end

return Disasm
