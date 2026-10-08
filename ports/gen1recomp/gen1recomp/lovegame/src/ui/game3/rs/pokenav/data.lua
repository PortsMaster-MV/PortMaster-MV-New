local Profile = require("src.core.game3.profile")
local Constants = require("src.core.game3.constants")
local Flags = require("src.core.game3.scripting.flags")
local M = {}
-- pokeruby/include/constants/flags.h:773
M.TRAINER_FLAG_START = 0x500
function M.constants(session) return Constants.of(Profile.forSession(session).id) end
function M.flag(session, id)
  if type(id) == "string" then id = M.constants(session):require("flags", id) end
  local Space = package.loaded["src.core.game3.scripting.space"]
  local store = Space and Space.store or session
  return Flags.getFlag(store, nil, id)
end
-- pokeruby/src/pokenav_before.c:1338
function M.mainRows(session)
  return {true, true, true, M.flag(session, "FLAG_SYS_RIBBON_GET"), true}
end
function M.moveCursor(rows, index, delta)
  for _ = 1, #rows do index = (index + delta) % #rows; if rows[index + 1] then return index end end
  return index
end
function M.mapGroupNum(map, session) return require("src.core.game3.rse.init").mapGroupNum(map, session) end
function M.maps(game)
  if game and game.data then return game.data.maps or {} end
  local Runtime = package.loaded["src.core.game3.runtime"]
  local active = Runtime and (Runtime._game or (Runtime.getGame and Runtime.getGame()))
  return active and active.data and active.data.maps or {}
end
function M.mapAt(game, session, group, num)
  for key, def in pairs(M.maps(game)) do
    local g, n = M.mapGroupNum(key, session)
    if g == group and n == num then return def, key end
  end
end
function M.fought(session, trainer)
  return M.flag(session, M.TRAINER_FLAG_START + trainer)
end
-- pokeruby/src/trainers_eye.c:39
function M.trainersEyes(session, game, man)
  local rows = {}
  for i = 0, 55 do
    local r = assert(man.rematches[i], "native Trainer's Eyes rematch record")
    if M.fought(session, r.opponentIDs[1]) then
      local map = assert(M.mapAt(game, session, r.mapGroup, r.mapNum), "native Trainer's Eyes map header missing")
      rows[#rows + 1] = {opponentId = r.opponentIDs[1], descriptionId = r.descriptionId, regionMapSectionId = map.regionMapSectionId,
        rematchNo = tonumber((session.trainerRematches or {})[i]) or 0, rematchTableIdx = i}
    end
  end
  for i = 0, 12 do
    local r = assert(man.leaders[i], "native Trainer's Eyes leader record")
    if M.fought(session, r.opponentId) then
      rows[#rows + 1] = {opponentId = r.opponentId, descriptionId = r.descriptionId, regionMapSectionId = r.regionMapSectionId,
        rematchNo = 0, rematchTableIdx = 56 + i}
    end
  end
  return rows
end
function M.nearbyRematch(session, man)
  local g, n = M.mapGroupNum(session.map, session)
  for i = 0, 55 do
    local r = man.rematches[i]
    if r.mapGroup == g and r.mapNum == n and (tonumber((session.trainerRematches or {})[i]) or 0) ~= 0 then return true end
  end
  return false
end
function M.mapSecAt(man, x, y)
  return man.layout[y - 1] and man.layout[y - 1][x] or man.mapsecs.NONE
end
function M.mapSecType(man, session, id)
  if id == man.mapsecs.NONE then return 0 end
  if id >= man.mapsecs.LITTLEROOT_TOWN and id <= man.mapsecs.EVER_GRANDE_CITY then
    local first = M.constants(session):require("flags", "FLAG_VISITED_LITTLEROOT_TOWN")
    return M.flag(session, first + id - man.mapsecs.LITTLEROOT_TOWN) and 2 or 3
  elseif id == man.mapsecs.BATTLE_TOWER then return M.flag(session, "FLAG_LANDMARK_BATTLE_TOWER") and 4 or 0
  elseif id == man.mapsecs.SOUTHERN_ISLAND then return M.flag(session, "FLAG_LANDMARK_SOUTHERN_ISLAND") and 1 or 0 end
  return 1
end
function M.sectionName(man, id) return man.sections[id] and man.sections[id].name or "" end
function M.landmarks(shell, session, sec, pos, none)
  local start
  for i, r in ipairs(shell.landmarks) do
    if r.mapSec == none or r.mapSec > sec then return {} end
    if r.mapSec == sec then start = i; break end
  end
  local names = {}
  if start then
    for i = start, #shell.landmarks do
      local r = shell.landmarks[i]
      if r.mapSec ~= sec then break end
      if r.id == pos then
        for _, l in ipairs(r.landmarks) do if l.flag == 0xFFFF or M.flag(session, l.flag) then names[#names + 1] = l.name end end
        break
      end
    end
  end
  return names
end
function M.positionWithin(man, sec, x, y)
  if sec == man.mapsecs.NONE then return 0 end
  local pos = 0
  while true do
    if x <= 1 then
      local found = false
      for xx = 1, 28 do if M.mapSecAt(man, xx, y - 1) == sec then found = true; break end end
      if not found then break end
      y, x = y - 1, 29
    else x = x - 1; if M.mapSecAt(man, x, y) == sec then pos = pos + 1 end end
  end
  return pos
end
-- pokeruby/src/region_map.c:514
function M.playerPosition(man, session, game)
  local maps, sec = M.maps(game), man.mapsecs
  local Map = package.loaded["src.core.game3.map"]
  local def = maps[session.map] or (Map and Map.currentDef and Map.currentDef())
  if not def then return nil, "current map header unavailable" end
  local group, num = M.mapGroupNum(session.map, session)
  if group == 25 then
    local C = M.constants(session)
    for _, name in ipairs({"MAP_SS_TIDAL_CORRIDOR", "MAP_SS_TIDAL_LOWER_DECK", "MAP_SS_TIDAL_ROOMS"}) do
      local row = C.map_groups.byName[name]
      if row and row.num == num then return require("src.ui.game3.rs.pokenav.tidal").position(man, session, game) end
    end
  end
  local P = package.loaded["src.core.game3.player"]
  local px, py = P and tonumber(P.cellX) or tonumber(session.x) or 0, P and tonumber(P.cellY) or tonumber(session.y) or 0
  local x, y, width, height, id, cave = px, py, def.width, def.height, tonumber(def.regionMapSectionId), false
  local t = tonumber(def.mapType)
  local warp
  if t == 4 or t == 7 then warp, cave = session.escapeWarp, true
  elseif t == 9 then warp, cave = session.dynamicWarp, true
  elseif t == 8 then warp = id == sec.DYNAMIC and session.dynamicWarp or session.escapeWarp end
  if warp then
    local other = maps[warp.map] or M.mapAt(game, session, warp.mapGroup, warp.mapNum)
    if not other then return nil, "native region-map warp header unavailable" end
    if t ~= 8 or id == sec.DYNAMIC then id = tonumber(other.regionMapSectionId) end
    width, height, x, y = other.width, other.height, tonumber(warp.x) or 0, tonumber(warp.y) or 0
  elseif t == 4 or t == 7 or t == 8 or t == 9 then return nil, "native region-map warp unavailable" end
  if id == sec.UNDERWATER_128 then cave = true end
  local entry = man.sections[id]
  if not entry or entry.width < 1 or entry.height < 1 then return nil, "native region-map section geometry unavailable" end
  local rawX = x
  x = math.min(entry.width - 1, math.floor(x / math.max(1, math.floor(width / entry.width))))
  y = math.min(entry.height - 1, math.floor(y / math.max(1, math.floor(height / entry.height))))
  if id == sec.ROUTE_114 and y ~= 0 then x = 0
  elseif id == sec.ROUTE_126 or id == sec.UNDERWATER_125 then
    x, y = (px > 32 and 1 or 0) + (px > 51 and 1 or 0), (py > 37 and 1 or 0) + (py > 56 and 1 or 0)
  elseif id == sec.ROUTE_121 then x = (rawX > 14 and 1 or 0) + (rawX > 28 and 1 or 0) + (rawX > 54 and 1 or 0) end
  local cx, cy = entry.x + x + 1, entry.y + y + 2
  for _, pair in ipairs(man.specialPlaces) do if pair[1] == id then id = pair[2]; break end end
  return {x = cx, y = cy, mapSec = id, cave = cave}
end
return M
