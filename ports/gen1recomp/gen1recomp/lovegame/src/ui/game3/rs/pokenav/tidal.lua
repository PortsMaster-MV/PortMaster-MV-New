local M = {}
local function variable(session, C, name)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local store = Space and Space.store or session
  return require("src.core.game3.scripting.flags").getVar(store, nil, C:require("vars", name))
end
-- pokeruby/src/field_specials.c:246
-- region_map.c:641
function M.position(man, session, game)
  local Data = require("src.ui.game3.rs.pokenav.data")
  local C = Data.constants(session)
  local state, count = variable(session, C, "VAR_PORTHOLE_STATE"), variable(session, C, "VAR_CRUISE_STEP_COUNT")
  local id, x, y = nil, 0, 0
  if state == 1 or state == 8 then id = man.mapsecs.SLATEPORT_CITY
  elseif state == 3 or state == 9 then id = man.mapsecs.ROUTE_131
  elseif state == 4 or state == 5 then id = man.mapsecs.LILYCOVE_CITY
  elseif state == 6 or state == 10 then id = man.mapsecs.ROUTE_124
  else
    local route, cell
    if state == 2 then
      if count < 60 then route, cell = "MAP_ROUTE134", count + 19
      elseif count < 140 then route, cell = "MAP_ROUTE133", count - 60
      else route, cell = "MAP_ROUTE132", count - 140 end
    elseif state == 7 then
      if count < 66 then route, cell = "MAP_ROUTE132", 65 - count
      elseif count < 146 then route, cell = "MAP_ROUTE133", 145 - count
      else route, cell = "MAP_ROUTE134", 224 - count end
    else return nil, "native SS Tidal porthole state is not initialized" end
    local slot = assert(C.map_groups.byName[route], "native SS Tidal route constant")
    local def = assert(Data.mapAt(game, session, slot.group, slot.num), "native SS Tidal route header missing")
    id = tonumber(def.regionMapSectionId)
    local entry = assert(man.sections[id], "native SS Tidal region section")
    cell = cell % 65536; if cell >= 32768 then cell = cell - 65536 end
    local ux = cell % 65536
    x = math.min(entry.width - 1, math.floor(ux / math.max(1, math.floor(def.width / entry.width))))
    y = math.min(entry.height - 1, math.floor(20 / math.max(1, math.floor(def.height / entry.height))))
  end
  local entry = assert(man.sections[id], "native SS Tidal section geometry")
  return {x = entry.x + x + 1, y = entry.y + y + 2, mapSec = id, cave = false}
end
return M
