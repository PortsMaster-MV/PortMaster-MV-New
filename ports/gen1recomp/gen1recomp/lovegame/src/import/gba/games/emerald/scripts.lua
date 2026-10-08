return function(V)
  local sym = V.sym

  V.NAMED_SCRIPTS = {
    -- pokeemerald/data/scripts/pc.inc:1
    EventScript_PC = sym("EventScript_PC"),
    -- pokeemerald/data/event_scripts.s:731
    EventScript_RegionMap = sym("EventScript_RegionMap"),
    -- pokeemerald/data/scripts/tv.inc:1
    EventScript_TV = sym("EventScript_TV"),
    -- pokeemerald/data/event_scripts.s:585
    EventScript_WhiteOut = sym("EventScript_WhiteOut"),
    -- pokeemerald/data/scripts/new_game.inc:115
    EventScript_ResetAllMapFlags = sym("EventScript_ResetAllMapFlags"),
  }

  local labels
  function V.SCRIPT_LABELS()
    if labels then return labels end
    local src = require("src.import.gba.syms." .. V.GAME)
    package.loaded["src.import.gba.syms." .. V.GAME] = nil
    local list = {}
    for name, off in src.data:gmatch("([^ \n]+) (%x+) ") do
      if (name:find("EventScript", 1, true) or name:match("Script$"))
          and not name:find("BattleScript", 1, true) and not name:find("Movement", 1, true) then
        list[#list + 1] = { name = name, off = tonumber(off, 16) }
      end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    labels = list
    return labels
  end

  V.SEED_SCRIPTS = function()
    local out = {}
    for i, row in ipairs(V.SCRIPT_LABELS()) do out[i] = row.off end
    return out
  end
end
