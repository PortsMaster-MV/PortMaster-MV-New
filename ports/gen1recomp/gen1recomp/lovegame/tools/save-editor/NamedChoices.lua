local Gen = require("Gen")
local C = {}
function C.locations(S)
  local rows = {}
  if Gen.ofState(S) == 3 then
    local pack = require("src.core.game3.encounters").loadCacheFile("region_map/map_sections.lua")
    local sections = pack and pack.sections
    local Maps = not sections and require("src.import.gba.map_sections_extract")
    for id = 0, 252 do
      local info = sections and sections[id]
      if not sections then
        local ok, result = pcall(Maps.getInfo, id, nil, 0)
        if ok and result and result.resolved then
          info = result
        end
      end
      if info and info.name and info.name ~= "" then
        local name = tostring(info.rawName or info.name):gsub("\n", " ")
        if info.id and info.id:find("POKECENTER", 1, true) then
          name = name .. " · Pokémon Center"
        end
        rows[#rows + 1] = { id, name }
      end
    end
    rows[#rows + 1] = { 253, "Special egg" }
    rows[#rows + 1] = { 254, "In-game trade" }
    rows[#rows + 1] = { 255, "Fateful encounter" }
  else
    rows = { { 0, "Unknown" } }
    for _, rec in pairs(S.data.gen2Landmarks and S.data.gen2Landmarks.landmarks or {}) do
      if type(rec) == "table" and rec.index and rec.index > 0 and rec.index < 126 then
        rows[#rows + 1] = { rec.index, tostring(rec.name or rec.id):gsub("\n", " ") }
      end
    end
    rows[#rows + 1], rows[#rows + 2] = { 127, "Event" }, { 126, "Gift" }
  end
  table.sort(rows, function(a, b)
    return a[2] < b[2]
  end)
  return rows
end
function C.property(S, d)
  if d.choices then
    return d.choices
  end
  if d.key == "metLocation" or d.key == "caughtLocation" then
    if not S._locationChoices then
      S._locationChoices = C.locations(S)
    end
    return S._locationChoices
  elseif d.key == "caughtTime" then
    return { { 0, "Unknown" }, { 1, "Morning" }, { 2, "Day" }, { 3, "Night" } }
  elseif d.key == "pokerus" then
    local rows = { { 0, "None" } }
    for strain = 1, Gen.ofState(S) == 2 and 8 or 15 do
      rows[#rows + 1] = { strain * 16, "Cured · strain " .. strain }
      for days = 1, strain % 4 + 1 do
        rows[#rows + 1] = {
          strain * 16 + days,
          "Strain " .. strain .. " · " .. days .. (days == 1 and " day left" or " days left"),
        }
      end
    end
    return rows
  elseif d.key == "markings" then
    local rows, names = {}, { "Circle", "Square", "Triangle", "Heart" }
    for mask = 0, 15 do
      local shown = {}
      for i, n in ipairs(names) do
        if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then
          shown[#shown + 1] = n
        end
      end
      rows[#rows + 1] = { mask, #shown == 0 and "None" or table.concat(shown, " + ") }
    end
    return rows
  end
end
return C
