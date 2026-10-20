local M = {}

-- pokeemerald/src/battle_pyramid.c:1621
function M.closure(c, labels)
  local ExtractScripts = require("src.import.gba.extract_scripts")
  local Opcodes = require("src.core.game3.scripting.opcodes")
  local ptrs, keys = {}, {}
  for _, label in ipairs(labels) do
    local ptr = c:off(label) + 0x08000000
    ptrs[#ptrs + 1] = ptr
    keys[label] = Opcodes.key(ptr)
  end
  local out = ExtractScripts.bfsFromSeeds(c.rom, ptrs)
  return { labels = keys, scripts = out.scripts, text = out.text, movements = out.movements }
end

return M
