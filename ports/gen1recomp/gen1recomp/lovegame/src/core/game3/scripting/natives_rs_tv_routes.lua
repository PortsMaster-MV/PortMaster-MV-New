local R = require("src.core.game3.rse.init")
local Tv = require("src.core.game3.rse.tv")
local Daily = require("src.core.game3.rs.tv_daily")
local Q = require("src.core.game3.rs.tv_queries")
local Playback = require("src.core.game3.rs.tv_playback")
local M = {BY_NAME = {}}
local function n(v) return math.floor(tonumber(v) or 0) end
local function on(v) return v == true or n(v) ~= 0 end
local function stringVar(ctx, adapters, id, session, bytes)
  local text = Playback.displayBytes(session, bytes)
  if ctx then
    ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[id] = text
    ctx.rsTvStringVarBytes = ctx.rsTvStringVarBytes or {}; ctx.rsTvStringVarBytes[id] = bytes
  end
  if adapters and adapters.setStringVar then adapters.setStringVar(id, text) end
end

-- tv.c:1670
M.BY_NAME.InterviewBefore = function(ctx, adapters)
  local session = R.session()
  Tv._stringVar1, Tv._stringVar2, Tv._var8006 = nil, nil, nil
  local blocked = Daily.interviewBefore(session, R.specialVar(ctx, 0x8005))
  if Tv._stringVar1 ~= nil then
    stringVar(ctx, adapters, 1, session, Q.encode(session, Tv._stringVar1))
  end
  if Tv._stringVar2 ~= nil then
    local _, nick = Q.leadNickname(session)
    stringVar(ctx, adapters, 2, session, nick)
  end
  if Tv._var8006 ~= nil then R.setSpecialVar(ctx, 0x8006, Tv._var8006) end
  R.setSpecialVar(ctx, 0x800D, blocked and 1 or 0)
  return false
end

-- tv.c:767
M.BY_NAME.InterviewAfter = function(ctx)
  Daily.interviewAfter(R.session(), R.specialVar(ctx, 0x8005), {
    var8004 = R.specialVar(ctx, 0x8004), var8007 = R.specialVar(ctx, 0x8007),
  })
  return false
end

-- tv.c:576
M.BY_NAME.TurnOffTVScreen = function(ctx, adapters)
  return require("src.core.game3.scripting.natives_tv").BY_NAME.TurnOffTVScreen(ctx, adapters)
end

-- tv.c:631
M.BY_NAME.GabbyAndTyBeforeInterview = function()
  Daily.gabbyAndTyBeforeInterview(R.session())
  return false
end
M.BY_NAME.GabbyAndTyAfterInterview = function()
  Daily.gabbyAndTyAfterInterview(R.session())
  return false
end

local function gabby() return Tv.state(R.session()).gabbyAndTyData end
local function battleNum()
  local num = n(gabby().battleNum) % 256
  return num >= 6 and num % 3 + 6 or num
end
-- tv.c:689
M.BY_NAME.GabbyAndTyGetBattleNum = function() return false, battleNum() end

-- tv.c:725
local LOCAL_IDS = {
  [1] = {14, 13}, [2] = {5, 6}, [3] = {18, 17}, [4] = {21, 22},
  [5] = {8, 9}, [6] = {19, 20}, [7] = {23, 24}, [8] = {10, 11},
}
M.BY_NAME.GetGabbyAndTyLocalIds = function(ctx)
  local ids = LOCAL_IDS[battleNum()]
  if ids then R.setSpecialVar(ctx, 0x8004, ids[1]); R.setSpecialVar(ctx, 0x8005, ids[2]) end
  return false
end

-- tv.c:702
M.BY_NAME.GabbyAndTyGetLastQuote = function(ctx, adapters)
  local session, g = R.session(), gabby()
  local quote = n(g.quote[0]) % 65536
  if quote == 65535 then return false, 0 end
  stringVar(ctx, adapters, 1, session, Q.encode(session, Playback.word(quote)))
  g.quote[0] = 65535
  return false, 1
end
-- tv.c:712
M.BY_NAME.GabbyAndTyGetLastBattleTrivia = function()
  local g = gabby()
  if not on(g.battleTookMoreThanOneTurn2) then return false, 1 end
  if on(g.playerThrewABall2) then return false, 2 end
  if on(g.playerUsedHealingItem2) then return false, 3 end
  if on(g.playerLostAMon2) then return false, 4 end
  return false, 0
end

-- tv.c:1531
M.BY_NAME.SetContestCategoryStringVarForInterview = function(ctx, adapters)
  local session, slot = R.session(), R.specialVar(ctx, 0x8004)
  assert(slot >= 0 and slot < 25, "RS contest interview TV slot outside native array")
  local raw = Playback.rawShow(session, Tv.state(session).tvShows[slot])
  local category = raw:byte(20) % 8
  if category < 5 then
    stringVar(ctx, adapters, 2, session, Q.encode(session, R.text(string.format("gStdStrings[%d]", category))))
  end
  return false
end
return M
