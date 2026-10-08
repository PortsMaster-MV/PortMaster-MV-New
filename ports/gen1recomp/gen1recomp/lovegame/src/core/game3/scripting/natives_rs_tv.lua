local R = require("src.core.game3.rse.init")
local Tv = require("src.core.game3.rse.tv")
local Queries = require("src.core.game3.rs.tv_queries")
local M = {BY_NAME = {}}
local function stringVar(ctx, adapters, i, value, bytes)
  if ctx then
    ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[i] = value
    ctx.rsTvStringVarBytes = ctx.rsTvStringVarBytes or {}; ctx.rsTvStringVarBytes[i] = bytes
  end
  if adapters and adapters.setStringVar then adapters.setStringVar(i, value) end
end
local function houses(session)
  local profile = require("src.core.game3.profile").forSession(session)
  local prefix = profile.map.enginePrefix
  local group, num = R.mapGroupNum(session.map, session)
  local hg, bn = R.mapGroupNum(prefix .. "LITTLEROOT_TOWN_BRENDANS_HOUSE_1F", session)
  local _, mn = R.mapGroupNum(prefix .. "LITTLEROOT_TOWN_MAYS_HOUSE_1F", session)
  return {mapGroup = group, mapNum = num, housesGroup = hg, brendanNum = bn, mayNum = mn,
    gender = session.gender == "female" and 1 or tonumber(session.gender) or 0,
    latiFlag = "FLAG_SYS_TV_LATI", flag = function(name) return R.flag(name, session) end}
end
-- pokeruby/tv.c:470
M.BY_NAME.special_0x44 = function() return false, Queries.randomActive(R.session()) end
M.BY_NAME.GetTVShowType = function(ctx)
  return false, Tv.selectedShowKind(R.session(), R.specialVar(ctx, 0x8004))
end
M.BY_NAME.GetNonMassOutbreakActiveTVShow = function(ctx)
  return false, Queries.nonOutbreakActive(R.session(), R.specialVar(ctx, 0x8004))
end
M.BY_NAME.IsTVShowInSearchOfTrainersAiring = function()
  return false, Tv.isGabbyAndTyOnAir(R.session()) and 1 or 0
end
-- tv.c:2039
M.BY_NAME.TV_IsScriptShowKindAlreadyInQueue = function(ctx)
  return false, Tv.isShowAlreadyInQueue(R.session(), R.specialVar(ctx, 0x8004)) and 1 or 0
end
M.BY_NAME.CheckForBigMovieOrEmergencyNewsOnTV = function()
  return false, Tv.checkForPlayersHouseNews(houses(R.session()))
end
-- tv.c:2136
M.BY_NAME.GetMomOrDadStringForTVMessage = function(ctx, adapters)
  local session = R.session(); local opts = houses(session)
  opts.getTemp3 = function() return R.var("VAR_TEMP_3", session) end
  opts.setTemp3 = function(v) R.setVar("VAR_TEMP_3", v, session) end
  opts.random = function() return require("src.core.game3.rng").Random() end
  local who = Tv.momOrDad(opts)
  stringVar(ctx, adapters, 1, R.text(who == "mom" and "gOtherText_Mom" or "gOtherText_Dad"))
  return false
end
M.BY_NAME.LeadMonNicknamed = function(ctx, adapters)
  local session = R.session(); local changed, nick = Queries.leadNickname(session)
  stringVar(ctx, adapters, 1, Queries.text(session, nick), nick)
  return false, changed and 1 or 0
end
M.BY_NAME.TV_PutNameRaterShowOnTheAirIfNicnkameChanged = function(ctx, adapters)
  local session = R.session()
  local changed, nick, var8006, queueResult = Queries.nameRater(session, R.specialVar(ctx, 0x8004),
    ctx and ctx.stringVars and ctx.stringVars[3] or "")
  stringVar(ctx, adapters, 1, Queries.text(session, nick), nick)
  if var8006 ~= nil then R.setSpecialVar(ctx, 0x8006, var8006) end
  if queueResult ~= nil then R.setSpecialVar(ctx, 0x800D, queueResult) end
  return false, changed and 1 or 0
end
return M
