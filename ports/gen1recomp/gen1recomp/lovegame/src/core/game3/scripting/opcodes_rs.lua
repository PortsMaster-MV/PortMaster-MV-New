local Native = require("src.core.game3.constants.ruby.script_cmds")

local names = {
  gotoram = "returnram", killscript = "endram",
  writebytetoaddr = "setptr", loadbytefromaddr = "loadbytefromptr",
  compare_local_to_addr = "compare_local_to_ptr",
  compare_addr_to_local = "compare_ptr_to_local",
  compare_addr_to_value = "compare_ptr_to_value",
  compare_addr_to_addr = "compare_ptr_to_ptr",
  applymovement_at = "applymovementat", waitmovement_at = "waitmovementat",
  removeobject_at = "removeobjectat", addobject_at = "addobjectat",
  trainerbattlebegin = "dotrainerbattle",
  moveobjectoffscreen = "copyobjectxytoperm",
  showcontestwinner = "showcontestpainting",
  getpricereduction = "getpokenewsactive", setflashradius = "setflashlevel",
  setobjectpriority = "setobjectsubpriority", resetobjectpriority = "resetobjectsubpriority",
  vloadptr = "vbuffermessage",
}

local out = {}
for byte = 0, Native.count - 1 do
  local row = assert(Native.byId[byte], "missing RS opcode " .. byte)
  out[byte] = {
    name = names[row.name] or row.name,
    size = row.name == "trainerbattle" and 1 or assert(row.size, "variable RS opcode " .. row.name),
    args = row.name == "trainerbattle" and {} or row.args,
  }
end
return out
