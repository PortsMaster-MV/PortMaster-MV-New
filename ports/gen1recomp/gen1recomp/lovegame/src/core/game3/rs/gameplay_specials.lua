local Rse = require("src.core.game3.rse.init")
local M = {}

-- pokeruby/src/field_specials.c:1857
function M.leadMon(session)
  local party = session and session.party or {}
  local egg = require("src.core.game3.constants").active(session):require("species", "SPECIES_EGG")
  for i = 1, 6 do
    local mon = party[i]
    local species = tonumber(mon and (mon.species or mon.speciesId)) or 0
    if species ~= 0 and species ~= egg and not (mon.egg == true or mon.isEgg == true) then return mon end
  end
  return party[1]
end

-- field_specials.c:106
function M.cyclingResults(ctx, frames, collisions)
  frames = math.floor(tonumber(frames) or 0) % 0x100000000
  collisions = math.floor(tonumber(collisions) or 0) % 0x100
  local s1 = collisions <= 99 and tostring(collisions) .. Rse.text("gOtherText_Times")
    or Rse.text("gOtherText_99Times")
  local s2 = frames < 3600 and string.format("%2d.%02d", math.floor(frames / 60), math.floor(frames % 60 * 100 / 60))
    .. Rse.text("gOtherText_Seconds") or Rse.text("gOtherText_1Minute")
  if ctx and ctx.stringVars then ctx.stringVars[1], ctx.stringVars[2] = s1, s2 end
  local score = collisions == 0 and 5 or collisions < 4 and 4 or collisions < 10 and 3
    or collisions < 20 and 2 or collisions < 100 and 1 or 0
  local seconds = math.floor(frames / 60)
  score = score + (seconds <= 10 and 5 or seconds <= 15 and 4 or seconds <= 20 and 3
    or seconds <= 40 and 2 or seconds < 60 and 1 or 0)
  if ctx then Rse.setSpecialVar(ctx, 0x800D, score) end
  return score, s1, s2
end

-- field_specials.c:210
function M.updateCyclingState(session)
  local last = session and session.lastUsedWarp
  if type(last) == "table" then
    local group, num = tonumber(last.mapGroup or last.group), tonumber(last.mapNum or last.num)
    if last.map then group, num = Rse.mapGroupNum(last.map, session) end
    local entrance = require("src.core.game3.constants").active(session):require("map_groups", "MAP_ROUTE110_SEASIDE_CYCLING_ROAD_NORTH_ENTRANCE")
    if group == entrance.group and num == entrance.num then return end
  end
  local state = Rse.var("VAR_CYCLING_CHALLENGE_STATE", session)
  if state == 2 or state == 3 then
    Rse.setVar("VAR_CYCLING_CHALLENGE_STATE", 0, session)
    require("src.core.game3.audio").setSavedSong(nil)
  end
end

-- field_special_scene.c:376
function M.lookThroughPorthole(ctx, adapters)
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    local session = Rse.session()
    local C = require("src.core.game3.constants").active(session)
    local Scene = require("src.core.game3.special_scene_rse")
    local state = Rse.var("VAR_PORTHOLE_STATE", session)
    local dest = Scene.portholeDestination(state, Rse.var("VAR_CRUISE_STEP_COUNT", session), C.map_groups.byName)
    assert(dest, "RS porthole: native cruise state must be two or seven")
    local current = require("src.core.game3.map").current
    local group, num = Rse.mapGroupNum(current, session)
    assert(group ~= nil and num ~= nil, "RS porthole: current native map is missing")
    local Player = require("src.core.game3.player")
    session.dynamicWarp = {map = current, mapGroup = group, mapNum = num, warpId = 0xFF, x = Player.cellX, y = Player.cellY}
    Rse.setFlag("FLAG_SYS_CRUISE_MODE", true, session)
    Rse.setFlag("FLAG_DONT_TRANSITION_MUSIC", true, session)
    Rse.setFlag("FLAG_HIDE_MAP_NAME_POPUP", true, session)
    local profile = require("src.core.game3.profile").forSession(session)
    local Runtime = package.loaded["src.core.game3.runtime"]
    require("src.core.game3.warp").scripted(Runtime._mod, Runtime._game, "rse_porthole_enter",
      profile.map.enginePrefix .. dest.map:gsub("^MAP_", ""), dest.x, dest.y, nil, function()
        Scene.enterPorthole(session, state == 2 and "right" or "left", done,
          {stateVar = "VAR_PORTHOLE_STATE", exitStateOnCruiseEndOnly = true})
      end)
  end)
end

return M
