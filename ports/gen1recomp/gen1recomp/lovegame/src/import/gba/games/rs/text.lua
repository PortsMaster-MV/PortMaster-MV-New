return function(V)
  local Source = require("src.import.gba.versions_text_rs")
  local function offsets(names)
    local out = {}
    for _, name in ipairs(names) do out[name] = V.sym(name) end
    return out
  end
  V.NAMED_TEXTS = offsets(Source.NAMED_TEXTS)
  V.NAMED_BATTLE_TEXTS = offsets(Source.NAMED_BATTLE_TEXTS)
  V.BATTLE_STRING_IDS = Source.BATTLE_STRING_IDS
  V.TEXT_TABLES = {}
  for i, t in ipairs(Source.TEXT_TABLES) do
    V.TEXT_TABLES[i] = {
      name = t.name, addr = V.sym(t.name), stride = t.stride,
      count = V.count(t.name, t.stride * (t.inner or 1)),
      inner = t.inner, battle = t.battle or t.name == "gBattleStringsTable", inline = t.inline, ids = t.ids,
    }
  end

  local stems = {
    UNKNOWN = "Empty", KUN_MALE = "Kun", KUN_FEMALE = "Chan",
    RIVAL_MALE = "May", RIVAL_FEMALE = "Brendan",
    VERSION = V.GAME == "sapphire" and "Sapphire" or "Ruby",
    AQUA = "Aqua", MAGMA = "Magma", ARCHIE = "Archie", MAXIE = "Maxie",
    KYOGRE = "Kyogre", GROUDON = "Groudon",
  }
  -- pokeruby/src/string_util.c:476
  local evil, good = { "Magma", "Maxie", "Groudon" }, { "Aqua", "Archie", "Kyogre" }
  if V.GAME == "sapphire" then evil, good = good, evil end
  for i, name in ipairs({ "TEAM", "LEADER", "LEGENDARY" }) do
    stems["EVIL_" .. name], stems["GOOD_" .. name] = evil[i], good[i]
  end
  V.TEXT_PLACEHOLDERS = {}
  for name, stem in pairs(stems) do V.TEXT_PLACEHOLDERS[name] = V.sym("gExpandedPlaceholder_" .. stem) end
end
