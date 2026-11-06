local Rse = require("src.core.game3.rse.init")
local L = require("src.core.game3.rse.fan_club_lifecycle_rs")
local N = {BY_NAME = {}}
local function s() return assert(Rse.session(), "RS fan-club session missing") end
N.BY_NAME.ShouldMoveLilycoveFanClubMember = function(ctx) return false, L.isFan(s(), Rse.specialVar(ctx, 0x8004)) end
N.BY_NAME.GetNumMovedLilycoveFanClubMembers = function() return false, require("src.core.game3.rse.fan_club_rs").count(s()) end
N.BY_NAME.BufferStreakTrainerText = function(ctx, adapters)
  local text, raw = L.bufferName(s(), Rse.specialVar(ctx, 0x8004))
  if ctx then
    ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[1] = text
    ctx.stringVarsNative = ctx.stringVarsNative or {}; ctx.stringVarsNative[1] = raw
  end
  if adapters and adapters.setStringVar then adapters.setStringVar(1, text) end
  return false
end
N.BY_NAME.sub_810FA74 = function() L.updateAfterLinkHours(s()); return false end
N.BY_NAME.UpdateMovedLilycoveFanClubMembers = function() L.updateMoved(s()); return false end
N.BY_NAME.sub_810FF48 = function() L.setInitialized(s()); return false end
N.BY_NAME.UpdateTrainerFanClubGameClear = function() L.gameClear(s()); return false end
return N
