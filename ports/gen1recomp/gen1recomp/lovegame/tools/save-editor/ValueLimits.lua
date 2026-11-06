local Gen = require("Gen")
local MonOps = require("MonOps")
local L = {}
L.EV_KEYS = { "hp", "atk", "def", "spa", "spd", "spe" }
function L.evTotal(mon)
  local total = 0
  for _, k in ipairs(L.EV_KEYS) do
    total = total + (tonumber(mon.evs and mon.evs[k]) or 0)
  end
  return total
end
function L.expAt(S, mon, level)
  local def = S.data and S.data.pokemon and S.data.pokemon[mon.species or mon.speciesId]
  local g = Gen.ofState(S)
  if g == 3 then
    return require("src.core.game3.summary_data").expForLevel(
      require("src.core.game3.pokemon").growthRate(mon.species or mon.speciesId),
      level
    )
  elseif g == 2 then
    local Mon = require("src.battle.gen2.Mon")
    return Mon.experienceForLevel(Mon.growthFor(S.data, def and def.growthRate), level)
  end
  return require("src.pokemon.Growth").expForLevel(
    def and def.growthRate or 0,
    level,
    S.data.growth_rates
  )
end
function L.mon(S, mon, id)
  local egg = mon.egg or mon.isEgg
  local lo, hi, help = 0, 255, "Slide for big changes. Roll the numbers for small ones."
  local key = id:match("^ev%-(.+)")
  if key then
    hi =
      math.max(0, math.min(255, 510 - L.evTotal(mon) + (tonumber(mon.evs and mon.evs[key]) or 0)))
    help = "Training points. All six stats share 510. Lower one to free up another."
  elseif id:match("^iv%-") then
    hi, help = 31, "Natural stat strength. Higher is stronger."
  elseif id:match("^dv%-") then
    hi, help = 15, "Natural stat strength. These also set HP, and in Gen 2, gender and shininess."
  elseif id:match("^se%-") then
    hi, help = 65535, "Stat training. Each stat has its own limit."
  elseif id == "level" then
    lo, hi, help =
      egg and 5 or math.min(100, math.max(1, tonumber(mon.metLevel) or 1)),
      egg and 5 or 100,
      "Changes level and recalculates stats. Moves stay the same."
  elseif id == "experience" then
    lo, hi, help =
      L.expAt(S, mon, egg and 5 or math.min(100, math.max(1, tonumber(mon.metLevel) or 1))),
      L.expAt(S, mon, egg and 5 or 100),
      "Total experience. Level updates to match."
  elseif id == "hp" or id == "current-hp" then
    hi, help =
      mon.maxHp or (mon.stats and mon.stats.hp) or 0,
      "Current health. The limit follows level and stats. Max fills it."
  elseif id == "happiness" or id == "friendship" then
    help = egg and "Egg hatch countdown. Lower means closer to hatching."
      or "Friendship. Max makes it as friendly as it can be."
  elseif id:match("^ppup%-%d") or id:match("^pp%-%d") then
    local slot = tonumber(id:match("(%d+)$"))
    local base = MonOps.getBasePp(S.data, mon, slot)
    if id:match("^ppup%-") then
      hi, help =
        (egg or base == 1) and 0 or 3, "Raises this move's PP limit. Then use Max on PP to fill it."
    else
      hi = MonOps.calcMaxPp(base, MonOps.getPpUps(mon, slot), Gen.ofState(S))
      help = "Uses left for this move. PP Ups raise the limit."
    end
  else
    local d = require("Properties").find(S, id)
    if d then
      lo, hi, help = d.lo or 0, d.hi or 255, d.help or help
    end
    if id == "metLevel" then
      hi = math.min(hi, tonumber(mon.level) or hi)
    end
  end
  return {
    lo = lo,
    hi = hi,
    help = help,
    step = id == "level" and 5 or 1,
    remaining = key and math.max(0, 510 - L.evTotal(mon)) or nil,
  }
end
return L
