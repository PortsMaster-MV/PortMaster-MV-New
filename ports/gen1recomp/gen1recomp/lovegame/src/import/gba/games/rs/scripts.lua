return function(V)
  local Catalog = require("src.import.gba.versions_scripts_rs")
  V.NAMED_SCRIPTS = {
    EventScript_PC = V.sym("EventScript_PC"),
    EventScript_RegionMap = V.sym("EventScript_RegionMap"),
    EventScript_TV = V.sym("Event_TV"), -- pokeruby/data/scripts/tv.inc:1
    EventScript_WhiteOut = V.sym("EventScript_WhiteOut"),
    EventScript_ResetAllMapFlags = V.sym("EventScript_ResetAllMapFlags"),
  }

  local labels
  function V.SCRIPT_LABELS()
    if labels then return labels end
    labels = {}
    for _, name in ipairs(Catalog.scripts) do
      if V.SYMS.has(name) then
        labels[#labels + 1] = { name = name, off = V.sym(name) }
      end
    end
    table.sort(labels, function(a, b) return a.name < b.name end)
    return labels
  end
  function V.SEED_SCRIPTS()
    local out = {}
    for i, row in ipairs(V.SCRIPT_LABELS()) do out[i] = row.off end
    return out
  end
  V.SCRIPT_DATA_OFFSETS = {}
  for _, names in ipairs({ Catalog.movements, Catalog.data }) do
    for _, name in ipairs(names) do
      if V.SYMS.has(name) then V.SCRIPT_DATA_OFFSETS[V.sym(name)] = true end
    end
  end
end
