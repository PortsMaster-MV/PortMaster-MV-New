-- pokeemerald/data/script_cmd_table.inc:217
local Cmds = require("src.core.game3.constants.emerald.script_cmds")

local FIRST, LAST = 0xC7, 0xE2

local RENAMES = {
  setmodernfatefulencounter = "setmonmodernfatefulencounter",
  checkmodernfatefulencounter = "checkmonmodernfatefulencounter",
}

local tail = {}
for byte = FIRST, LAST do
  local e = assert(Cmds.byId[byte], "pokeemerald script command missing")
  local args = {}
  for i, a in ipairs(e.args or {}) do args[i] = { kind = a.kind } end
  local name = e.stub and "nop1" or (RENAMES[e.name] or e.name)
  tail[byte] = { name = name, size = e.size, args = args, pret = e.name }
end

return tail
