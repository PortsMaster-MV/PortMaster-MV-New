local Rse = require("src.core.game3.rse.init")

local Specials = {}

-- pokeemerald/include/constants/vars.h:296
local VAR_RESULT = 0x800D

local function bike()
  return require("src.core.game3.bike.rse")
end

local function player()
  return package.loaded["src.core.game3.player"] or require("src.core.game3.player")
end

local function itemId(name, sess)
  return require("src.core.game3.constants").active(sess):require("items", name)
end

-- pokeemerald/src/field_specials.c:177 DetermineCyclingRoadResults
function Specials.cyclingRoadResults(ctx, numFrames, collisions)
  local s1, s2
  if collisions < 100 then
    s1 = tostring(collisions) .. Rse.text("gText_SpaceTimes")
  else
    s1 = Rse.text("gText_99TimesPlus")
  end
  if numFrames < 3600 then
    s2 = string.format("%2d.%02d", math.floor(numFrames / 60), math.floor(((numFrames % 60) * 100) / 60))
      .. Rse.text("gText_SpaceSeconds")
  else
    s2 = Rse.text("gText_1MinutePlus")
  end
  if ctx and ctx.stringVars then
    ctx.stringVars[1] = s1
    ctx.stringVars[2] = s2
  end
  local result = 0
  if collisions == 0 then
    result = 5
  elseif collisions < 4 then
    result = 4
  elseif collisions < 10 then
    result = 3
  elseif collisions < 20 then
    result = 2
  elseif collisions < 100 then
    result = 1
  end
  local seconds = math.floor(numFrames / 60)
  if seconds <= 10 then
    result = result + 5
  elseif seconds <= 15 then
    result = result + 4
  elseif seconds <= 20 then
    result = result + 3
  elseif seconds <= 40 then
    result = result + 2
  elseif seconds < 60 then
    result = result + 1
  end
  if ctx then Rse.setSpecialVar(ctx, VAR_RESULT, result) end
  return result, s1, s2
end

-- pokeemerald/src/field_specials.c:237 RecordCyclingRoadResults
function Specials.recordCyclingRoadResults(numFrames, collisions)
  local record = Rse.var("VAR_CYCLING_ROAD_RECORD_TIME_L") + Rse.var("VAR_CYCLING_ROAD_RECORD_TIME_H") * 0x10000
  if record > numFrames or record == 0 then
    Rse.setVar("VAR_CYCLING_ROAD_RECORD_TIME_L", numFrames % 0x10000)
    Rse.setVar("VAR_CYCLING_ROAD_RECORD_TIME_H", math.floor(numFrames / 0x10000))
    Rse.setVar("VAR_CYCLING_ROAD_RECORD_COLLISIONS", collisions)
  end
end

Specials.BY_NAME = {
  -- pokeemerald/src/field_specials.c:168
  GetPlayerAvatarBike = function()
    local P = player()
    if P.biking and P.bikeType == "acro" then return false, 1 end
    if P.biking then return false, 2 end
    return false, 0
  end,
  -- pokeemerald/src/item.c:572
  SwapRegisteredBike = function()
    local sess = Rse.session()
    if not sess then return false end
    local ItemsData = require("src.core.game3.items_data")
    local reg = sess.registeredItem and (ItemsData.toNumericId(sess.registeredItem) or tonumber(sess.registeredItem))
    local mach, acro = itemId("ITEM_MACH_BIKE", sess), itemId("ITEM_ACRO_BIKE", sess)
    if reg == mach then
      sess.registeredItem = acro
    elseif reg == acro then
      sess.registeredItem = mach
    end
    return false
  end,
  -- pokeemerald/src/field_specials.c:161
  Special_BeginCyclingRoadChallenge = function()
    bike().beginCyclingRoadChallenge()
    return false
  end,
  -- pokeemerald/src/field_specials.c:229
  FinishCyclingRoadChallenge = function(ctx)
    local frames, collisions = bike().finishCyclingRoadChallenge()
    Specials.cyclingRoadResults(ctx, frames, collisions)
    Specials.recordCyclingRoadResults(frames, collisions)
    return false
  end,
  -- pokeemerald/src/field_specials.c:251
  GetRecordedCyclingRoadResults = function(ctx)
    local record = Rse.var("VAR_CYCLING_ROAD_RECORD_TIME_L") + Rse.var("VAR_CYCLING_ROAD_RECORD_TIME_H") * 0x10000
    if record == 0 then return false, 0 end
    Specials.cyclingRoadResults(ctx, record, Rse.var("VAR_CYCLING_ROAD_RECORD_COLLISIONS"))
    return false, 1
  end,
  -- pokeemerald/src/field_specials.c:264
  UpdateCyclingRoadState = function()
    local sess = Rse.session()
    local last = sess and sess.lastUsedWarp
    if type(last) == "table" and last.map == "EM_ROUTE110_SEASIDE_CYCLING_ROAD_NORTH_ENTRANCE" then return false end
    local state = Rse.var("VAR_CYCLING_CHALLENGE_STATE")
    if state == 2 or state == 3 then
      Rse.setVar("VAR_CYCLING_CHALLENGE_STATE", 0)
      require("src.core.game3.audio").setSavedSong(nil)
    end
    return false
  end,
  -- pokeemerald/src/field_tasks.c:637
  SetSootopolisGymCrackedIceMetatiles = function()
    require("src.core.game3.step_callbacks_rse").setSootopolisGymCrackedIceMetatiles()
    return false
  end,
}

return Specials
