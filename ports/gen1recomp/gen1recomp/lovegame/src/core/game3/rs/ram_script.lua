local Disasm = require("src.core.game3.scripting.disasm")
local Opcodes = require("src.core.game3.scripting.opcodes")
local IR = require("src.core.game3.scripting.text_ir")
local M = {}
function M.clear(session)
  session.ramScriptNativeBytes = {}
  for i = 1, 1004 do session.ramScriptNativeBytes[i] = 0 end
end
local function word(raw, at)
  return raw[at] + raw[at + 1] * 256 + raw[at + 2] * 65536 + raw[at + 3] * 16777216
end
function M.install(session, bytes, group, num, localId)
  M.clear(session)
  if #bytes > 996 then return false end
  local raw = session.ramScriptNativeBytes
  raw[5], raw[6], raw[7], raw[8] = 51, group, num, localId
  for i = 1, #bytes do raw[i + 8] = bytes[i] end
  local checksum = 0
  for i = 5, 1004 do checksum = checksum + raw[i] end
  for i = 1, 4 do raw[i] = math.floor(checksum / 256 ^ (i - 1)) % 256 end
  return true
end
function M.compile(bytes, vm, opts)
  opts = opts or {}
  local prefix, base = opts.prefix or "rsram:", opts.base
  local set = Opcodes.forGame("ruby")
  local pending, seen, relocations = {{at = opts.start or 1, virtual = opts.virtual}}, {}, {}
  local function pointer(ptr, virtual)
    local off
    if virtual then off = ptr - virtual + 1
    elseif base then off = ptr - base + 1 end
    if off and off >= 1 and off <= #bytes then return off end
  end
  local function script(ptr, virtual)
    local off = pointer(ptr, virtual)
    if off then pending[#pending + 1] = {at = off, virtual = virtual}; return prefix .. off end
    local key = Opcodes.key(ptr)
    assert(vm.scripts[key], "RAM event references an unavailable native script " .. key)
    return key
  end
  local function text(ptr, virtual)
    local off = pointer(ptr, virtual)
    if not off then return Opcodes.key(ptr) end
    local key, raw = prefix .. "text:" .. off, {}
    for i = off, #bytes do raw[#raw + 1] = bytes[i]; if bytes[i] == 255 then break end end
    assert(raw[#raw] == 255, "RAM event text missing EOS")
    vm.text[key] = IR.decode(raw, {dialect = "rs"})
    return key
  end
  local function nextOffset(at, virtual)
    if at > #bytes then return {op = "end"} end
    pending[#pending + 1] = {at = at, virtual = virtual}
    return {op = "goto", target = prefix .. at}
  end
  while #pending > 0 do
    local p = table.remove(pending)
    if seen[p.at] then
      assert(relocations[p.at] == p.virtual, "RAM event has conflicting virtual addresses")
    else
      seen[p.at], relocations[p.at] = true, p.virtual
      local row, after = Disasm.decodeOne(bytes, p.at, set)
      assert(row.op ~= "unknown" and after <= #bytes + 1, "RAM event invalid/truncated opcode")
      local op, virtual = row.op, p.virtual
      if op == "returnram" and opts.nullReturn then row.op = "end" end
      if op == "setvaddress" then virtual = row[1] - (p.at - 1) end
      if op == "goto" or op == "call" or op == "goto_if" or op == "call_if"
          or op == "vgoto" or op == "vcall" or op == "vgoto_if" or op == "vcall_if" then
        local conditional = op:find("_if", 1, true) ~= nil
        row.target = script(row.target or row[conditional and 2 or 1], op:sub(1, 1) == "v" and virtual or nil)
      elseif op == "message" then row.ptr = text(row[1])
      elseif op == "loadword" and row[1] == 0 then row.value = text(row[2])
      elseif op == "vmessage" or op == "vbuffermessage" then row[1] = text(row[1], virtual)
      elseif op == "vbufferstring" then row.ptr = text(row[2], virtual)
      elseif op == "bufferstring" then row.src = text(row[2])
      elseif op == "applymovement" then
        local off = pointer(row.movement)
        if off then row.movement = prefix .. "move:" .. off; vm.movements[row.movement] = Disasm.decodeMovement(bytes, off)
        else row.movement = Opcodes.key(row.movement) end
      elseif op == "trainerbattle" then
        for _, field in ipairs({"introText", "defeatText", "notEnoughText", "victoryText"}) do
          if row[field] then row[field] = text(row[field]) end
        end
        if row.eventScript then row.eventScript = script(row.eventScript) end
      end
      local terminal = op == "end" or op == "return" or op == "endram" or op == "returnram"
        or op == "goto" or op == "vgoto" or op == "gotostd"
      vm.scripts[prefix .. p.at] = terminal and {row} or {row, nextOffset(after, virtual)}
    end
  end
  return prefix .. (opts.start or 1)
end
function M.select(session, vm, localId, original)
  vm.ctx.rsRamReturnKey = nil
  if not session or not require("src.core.game3.rs.enigma").matches(session) then return original end
  local raw = session.ramScriptNativeBytes
  if type(raw) ~= "table" or #raw ~= 1004 or raw[5] ~= 51 then return original end
  local group, num = require("src.import.gba.map_catalog").groupNumFor(session.map)
  if raw[6] ~= group or raw[7] ~= num or raw[8] ~= localId then return original end
  local sum = 0
  for i = 5, 1004 do sum = sum + raw[i] end
  if sum ~= word(raw, 1) then M.clear(session); return original end
  local bytes = {}; for i = 9, 1004 do bytes[#bytes + 1] = raw[i] end
  local key = M.compile(bytes, vm, {base = 0x02025734 + 0x3690 + 8, nullReturn = original == nil})
  vm.ctx.rsRamReturnKey = original
  return key
end
return M
