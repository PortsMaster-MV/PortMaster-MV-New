local Rse = require("src.core.game3.rse.init")
local Policy = require("src.core.game3.rs.gameplay_specials")
local N = {BY_NAME = {}}
local B = N.BY_NAME

local function delegate(path, name)
  return function(...) return require(path).BY_NAME[name](...) end
end

-- pokeruby/data/specials.inc:300
-- contest_util.c:315
B.sub_8081334 = delegate("src.core.game3.scripting.natives_contest", "DoContestHallWarp")
B.sub_80C5164 = delegate("src.core.game3.scripting.natives_contest", "HideContestEntryMonPic")
B.ScriptRandom = delegate("src.core.game3.scripting.natives_contest", "GenerateContestRand")

B.GetFirstFreePokeblockSlot = delegate("src.core.game3.scripting.natives_pokeblock", "GetFirstFreePokeblockSlot")
B.DoBerryBlending = delegate("src.core.game3.scripting.natives_blender", "DoBerryBlending")
B.ShowBerryBlenderRecordWindow = delegate("src.core.game3.scripting.natives_blender", "ShowBerryBlenderRecordWindow")
B.SafariZoneGetPokeblockNameInFeeder = delegate("src.core.game3.scripting.natives_pokeblock", "GetPokeblockFeederInFront")
B.OpenPokeblockCaseOnFeeder = delegate("src.core.game3.scripting.natives_pokeblock", "OpenPokeblockCaseOnFeeder")
B.GetPokeblockNameByMonNature = delegate("src.core.game3.scripting.natives_pokeblock", "GetPokeblockNameByMonNature")

-- field_specials.c:1374
for _, name in ipairs({"Cool", "Beauty", "Cute", "Smart", "Tough"}) do
  local condition = name:lower()
  B["CheckLeadMon" .. name] = function()
    local mon = Policy.leadMon(Rse.session())
    return false, (tonumber(mon and mon.contest and mon.contest[condition]) or 0) >= 200 and 1 or 0
  end
end
B.LeadMonHasEffortRibbon = function()
  return false, require("src.core.game3.rse.ribbons").get(Policy.leadMon(Rse.session()), "effort")
end
B.GivLeadMonEffortRibbon = function()
  local s = Rse.session()
  s.gameStats = s.gameStats or {}
  s.gameStats[42] = math.min(0xFFFFFF, math.floor(tonumber(s.gameStats[42]) or 0) + 1)
  Rse.setFlag("FLAG_SYS_RIBBON_GET", true, s)
  local mon = Policy.leadMon(s)
  if mon then require("src.core.game3.rse.ribbons").set(mon, "effort", 1) end
  return false
end
B.ScrSpecial_AreLeadMonEVsMaxedOut = function()
  return false, require("src.core.game3.pokemon").evCount(Policy.leadMon(Rse.session())) >= 510 and 1 or 0
end
-- pokedex.c:4088
B.CompletedHoennPokedex = function()
  return false, require("src.core.game3.profiles.rs.pokedex").completedHoenn(Rse.session()) and 1 or 0
end

-- field_specials.c:90
B.GetPlayerAvatarBike = delegate("src.core.game3.bike.specials_rse", "GetPlayerAvatarBike")
B.ScrSpecial_BeginCyclingRoadChallenge = delegate("src.core.game3.bike.specials_rse", "Special_BeginCyclingRoadChallenge")
B.FinishCyclingRoadChallenge = function(ctx)
  local frames, collisions = require("src.core.game3.bike.rse").finishCyclingRoadChallenge()
  Policy.cyclingResults(ctx, frames, collisions)
  require("src.core.game3.bike.specials_rse").recordCyclingRoadResults(frames, collisions)
  return false
end
B.GetRecordedCyclingRoadResults = function(ctx)
  local frames = Rse.var("VAR_CYCLING_ROAD_RECORD_TIME_L") + Rse.var("VAR_CYCLING_ROAD_RECORD_TIME_H") * 0x10000
  if frames == 0 then return false, 0 end
  Policy.cyclingResults(ctx, frames, Rse.var("VAR_CYCLING_ROAD_RECORD_COLLISIONS"))
  return false, 1
end
B.UpdateCyclingRoadState = function() Policy.updateCyclingState(Rse.session()); return false end
B.sub_80C7958 = Policy.lookThroughPorthole

-- field_specials.c:1644
for _, room in ipairs({1, 2, 4, 6}) do
  local flagName = "FLAG_HIDDEN_ITEM_ABANDONED_SHIP_RM_" .. room .. "_KEY"
  B["FoundAbandonedShipRoom" .. room .. "Key"] = function(ctx)
    Rse.setSpecialVar(ctx, 0x8004, Rse.flagId(flagName))
    return false, Rse.flag(flagName) and 1 or 0
  end
end

return N
