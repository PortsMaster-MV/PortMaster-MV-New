local Pokemon = require("src.core.game3.pokemon")
local M = {}

local function bonus(mon, slot, entry, base)
  local packed = mon.ppBonusesPacked
  if type(packed) == "number" then return math.floor(packed / 2 ^ ((slot - 1) * 2)) % 4 end
  local perMove = type(mon.ppBonuses) == "table" and mon.ppBonuses[slot] or nil
  if perMove == nil and type(entry) == "table" then perMove = entry.ppBonuses or entry.ppUps end
  if perMove ~= nil then return math.max(0, math.min(3, math.floor(tonumber(perMove) or 0))) end
  local max = type(mon.maxPp) == "table" and tonumber(mon.maxPp[slot])
    or type(entry) == "table" and tonumber(entry.maxPp)
  if max then
    for n = 3, 0, -1 do if base + math.floor(base * n / 5) <= max then return n end end
  end
  return 0
end

-- pokeruby/src/pokemon_3.c:1285
-- pokemon_storage_system_4.c:1321
function M.restorePP(mon)
  if type(mon.moves) ~= "table" then return end
  mon.pp, mon.maxPp = mon.pp or {}, mon.maxPp or {}
  for slot = 1, 4 do
    local id = Pokemon.moveIdAt(mon, slot)
    if id and id ~= 0 then
      local entry, base = mon.moves[slot], Pokemon.movePp(id)
      local max = base + math.floor(base * bonus(mon, slot, entry, base) / 5)
      mon.pp[slot], mon.maxPp[slot] = max, max
      if type(entry) == "table" then entry.pp, entry.maxPp = max, max end
    end
  end
end
return M
