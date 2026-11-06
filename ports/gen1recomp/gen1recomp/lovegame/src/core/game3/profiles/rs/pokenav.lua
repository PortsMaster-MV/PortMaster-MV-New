local Pokemon = require("src.core.game3.pokemon")
local Ribbons = require("src.core.game3.rse.ribbons")
local M = {}

-- pokeruby/src/pokemon_2.c:587
function M.ribbonCount(mon)
  if type(mon) ~= "table" or (tonumber(Pokemon.speciesOf(mon)) or 0) == 0 or Pokemon.isEgg(mon) then return 0 end
  local count = 0
  for _, name in ipairs(Ribbons.COUNTED) do count = count + Ribbons.get(mon, name) end
  return count
end

function M.giftDescriptionIndex(session, ribbonId)
  local id = tonumber(ribbonId)
  if not id or id < 25 or id > 31 or id ~= math.floor(id) then return nil end
  local value = math.floor(tonumber((session and session.giftRibbons or {})[id - 24]) or 0) % 256
  if value == 0 then return nil, 0x30F7 + id, value end
  return value - 1, 0x30F7 + id, value
end

return M
