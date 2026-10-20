local Profile = require("src.core.game3.profile")

local FieldModules = {}

FieldModules.NAMES = {
  questLog = true,
  mapPreview = true,
  mapNamePopup = true,
  helpSystem = true,
  vsSeeker = true,
  deoxys = true,
  renewableHiddenItems = true,
  leagueLighting = true,
  ssAnne = true,
  unionPlaza = true,
  seafoamSurf = true,
  viridianForestEscape = true,
}

FieldModules.FAMILY_DEFAULTS = {
  -- pokeemerald/src/map_name_popup.c:231
  rse = { mapNamePopup = true },
}

function FieldModules.list(session)
  local row = Profile.forSession(session)
  local map = row and row.map
  return map and map.fieldModules or nil
end

function FieldModules.enabled(name, session)
  if not FieldModules.NAMES[name] then
    error("field module name '" .. tostring(name) .. "' is not known", 2)
  end
  local list = FieldModules.list(session)
  if list == nil then return true end
  if list[name] ~= nil then return list[name] == true end
  local defaults = FieldModules.FAMILY_DEFAULTS[Profile.family(session)]
  return defaults ~= nil and defaults[name] == true
end

return FieldModules
