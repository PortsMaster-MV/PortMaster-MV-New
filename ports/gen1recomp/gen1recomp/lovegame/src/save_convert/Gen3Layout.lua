local L = require("src.save_convert.gen3_layouts.frlg")

local FAMILIES = { frlg = "src.save_convert.gen3_layouts.frlg", emerald = "src.save_convert.gen3_layouts.emerald", rs = "src.save_convert.gen3_layouts.rs" }

function L.family(name)
  local path = FAMILIES[name]
  if not path then error("gen3 save layout: no family " .. tostring(name), 2) end
  return require(path)
end

function L.familyOf(version)
  if version == "ruby" or version == "sapphire" then return "rs" end
  local GameVersion = require("src.core.GameVersion")
  if GameVersion.layout and GameVersion.layout(version) == "rse" then return version end
  return "frlg"
end

function L.forVersion(version)
  local family = L.familyOf(version)
  local layout = L.family(family)
  return family == "rs" and layout.forVersion(version) or layout
end

return L
