local Std = require("src.core.game3.scripting.stdscripts")
local Tv = require("src.core.game3.rse.tv")
local Rse = require("src.core.game3.rse.init")

local NativesTv = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_0x8005 = 0x8005
local VAR_0x8006 = 0x8006
local VAR_0x8007 = 0x8007
local VAR_RESULT = 0x800D
-- pokeemerald/include/constants/vars.h:300
local VAR_CONTEST_CATEGORY = 0x8011

-- pokeemerald/src/tv.c:1038
local GABBY_TY_LOCAL_IDS = {
  [1] = { 14, 13 }, [2] = { 5, 6 }, [3] = { 18, 17 }, [4] = { 21, 22 },
  [5] = { 8, 9 }, [6] = { 19, 20 }, [7] = { 23, 24 }, [8] = { 10, 11 },
}

local function random()
  return require("src.core.game3.rng").Random()
end

local function housesOpts(session)
  local profile = require("src.core.game3.profile").forSession(session)
  local prefix = profile.map.enginePrefix
  local g, n = Rse.mapGroupNum(session and session.map, session)
  local hg, bn = Rse.mapGroupNum(prefix .. "LITTLEROOT_TOWN_BRENDANS_HOUSE_1F", session)
  local _, mn = Rse.mapGroupNum(prefix .. "LITTLEROOT_TOWN_MAYS_HOUSE_1F", session)
  return {
    mapGroup = g,
    mapNum = n,
    housesGroup = hg,
    brendanNum = bn,
    mayNum = mn,
    latiFlag = profile.tv and profile.tv.latiFlag,
    gender = tonumber(session and session.gender) or 0,
    flag = function(name) return Rse.flag(name, session) end,
  }
end

local function currentLayout()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local session = Rse.session()
  local mapId = session and session.map
  local def = mapId and game and game.data and game.data.maps and game.data.maps[mapId]
  return def, def and def.midLayout
end

local function tvMetatile(on)
  local C = require("src.core.game3.constants").active(Rse.session())
  return C:require("metatile_labels", on and "METATILE_Building_TV_On" or "METATILE_Building_TV_Off")
end

local function setScreens(metatile)
  local def, layout = currentLayout()
  if not layout then return 0 end
  local Collision = require("src.core.game3.collision")
  local Field = require("src.core.game3.field")
  local MB = require("src.core.game3.mb")
  local tv = MB.id("TELEVISION")
  return Tv.setScreens(layout,
    function(x, y) return Collision.behaviorOn(def, x, y) end,
    function(x, y, m) Field.setMetatile(x, y, m, true) end,
    function(b) return b == tv end,
    metatile)
end

NativesTv.setScreens = setScreens

-- pokeemerald/src/tv.c:826
function NativesTv.updateScreensOnMap(session)
  session = session or Rse.session()
  if not session then return end
  Rse.setFlag("FLAG_SYS_TV_WATCH", true, session)
  local news = Tv.checkForPlayersHouseNews(housesOpts(session))
  if news == Tv.PLAYERS_HOUSE_TV_LATI then
    setScreens(tvMetatile(true))
  elseif news == Tv.PLAYERS_HOUSE_TV_MOVIE then
    return
  elseif session.map == require("src.core.game3.profile").forSession(session).map.enginePrefix .. "LILYCOVE_CITY_COVE_LILY_MOTEL_1F" then
    setScreens(tvMetatile(true))
  elseif Rse.flag("FLAG_SYS_TV_START", session) and (NativesTv.anyShowOnAir(session)
      or Tv.findPokeNewsOnAir(session) ~= 0xFF or Tv.isGabbyAndTyOnAir(session)) then
    Rse.setFlag("FLAG_SYS_TV_WATCH", false, session)
    setScreens(tvMetatile(true))
  end
end

-- pokeemerald/src/tv.c:813
function NativesTv.findAnyShowOnAir(session)
  return Tv.findAnyShowOnAir(session, random)
end

function NativesTv.anyShowOnAir(session)
  return NativesTv.findAnyShowOnAir(session) ~= 0xFF
end

-- pokeemerald/src/tv.c:996
function NativesTv.gabbyBattleNum(session)
  local n = tonumber(Tv.state(session).gabbyAndTyData.battleNum) or 0
  if n > 5 then return (n % 3) + 6 end
  return n
end

local function stringVars(ctx)
  if not ctx then return {} end
  if type(ctx.stringVars) ~= "table" then ctx.stringVars = { [1] = "", [2] = "", [3] = "" } end
  return ctx.stringVars
end

local function syncStringVars(ctx, adapters)
  if not (adapters and adapters.setStringVar and ctx and ctx.stringVars) then return end
  for i = 1, 3 do adapters.setStringVar(i, ctx.stringVars[i] or "") end
end

local function setStringVar(ctx, adapters, i, text)
  stringVars(ctx)[i] = text
  if adapters and adapters.setStringVar then adapters.setStringVar(i, text) end
end

local function textView(ctx, adapters)
  local a = adapters or {}
  local function val(v) if type(v) == "function" then return v() end return v end
  return {
    stringVars = ctx and ctx.stringVars or {},
    playerName = val(a.playerName) or (ctx and ctx.playerName),
    rivalName = val(a.rivalName) or (ctx and ctx.rivalName),
  }
end

-- pokeemerald/src/field_message_box.c:62
function NativesTv.render(ctx, adapters, res)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local view = textView(ctx, adapters)
  if res.text then return TextIR.toTextBox(TextIR.fromAscii(res.text), view) end
  local RomText = require("src.core.game3.rom_text")
  return RomText.box(RomText.key(res.group, res.index), view)
end

local function showMessage(ctx, adapters, res)
  syncStringVars(ctx, adapters)
  local body = NativesTv.render(ctx, adapters, res)
  NativesTv.lastMessage = body
  NativesTv.lastText = res
  if ctx then
    ctx.messageOpen = true
    ctx.printerDone = false
  end
  local open = adapters and (adapters.openMessageStay or adapters.openMessageAsync)
  if open then
    open(body, nil)
  elseif adapters and adapters.openMessage then
    adapters.openMessage(body)
  end
  return body
end
NativesTv.showMessage = showMessage

local function setResult(ctx, v)
  Rse.setSpecialVar(ctx, VAR_RESULT, v)
end

local function boolRet(ctx, v)
  local r = v and 1 or 0
  setResult(ctx, r)
  return false, r
end

local function monIndexVar(ctx)
  return Rse.specialVar(ctx, VAR_0x8004)
end

local function contestMon(session)
  local impl = Rse.system("contest")
  local idx = impl and tonumber(type(impl.contestMonPartyIndex) == "function" and impl.contestMonPartyIndex()
    or impl.contestMonPartyIndex)
  local party = session and session.party or {}
  if idx then return party[idx + 1] end
  return nil
end

-- pokeemerald/src/tv.c:1479
local function towerInterview(session)
  local impl = Rse.system("frontier")
  if impl and type(impl.towerInterviewTv) == "function" then return impl.towerInterviewTv(session) end
  local f = session and session.frontier
  return type(f) == "table" and f.towerInterview or {}
end

local function lilycoveContestLady(session)
  local r = Rse.call("lilycoveLady", "contestLadyTvData", "PutLilycoveContestLadyShowOnTheAir", nil, session)
  return type(r) == "table" and r or nil
end

-- pokeemerald/src/clock.c:46
function NativesTv.installTimeHooks()
  local TimeEvents = require("src.core.game3.time_events")
  local perDay = TimeEvents.handlers()
  if perDay.UpdateTVShowsPerDay == nil then
    TimeEvents.onDay("UpdateTVShowsPerDay", function(sess, days)
      if Rse.isRse(sess) then Tv.updatePerDay(sess, days) end
    end)
  end
end

NativesTv.BY_NAME = {
  -- pokeemerald/src/tv.c:6825
  ResetTVShowState = function()
    Tv.resetShowState()
    return false
  end,
  -- pokeemerald/src/tv.c:3359
  CheckForPlayersHouseNews = function()
    return false, Tv.checkForPlayersHouseNews(housesOpts(Rse.session()))
  end,
  -- pokeemerald/src/tv.c:1004
  IsGabbyAndTyShowOnTheAir = function()
    return false, Tv.isGabbyAndTyOnAir(Rse.session()) and 1 or 0
  end,
  -- pokeemerald/src/tv.c:996
  GabbyAndTyGetBattleNum = function()
    return false, NativesTv.gabbyBattleNum(Rse.session())
  end,
  -- pokeemerald/src/tv.c:1038
  GetGabbyAndTyLocalIds = function(ctx)
    local ids = GABBY_TY_LOCAL_IDS[NativesTv.gabbyBattleNum(Rse.session())]
    if ids then
      Rse.setSpecialVar(ctx, VAR_0x8004, ids[1])
      Rse.setSpecialVar(ctx, VAR_0x8005, ids[2])
    end
    return false
  end,
  -- pokeemerald/src/tv.c:1009
  GabbyAndTyGetLastQuote = function(ctx, adapters)
    local g = Tv.state(Rse.session()).gabbyAndTyData
    local q = g.quote and g.quote[0]
    if q == nil or q == -1 or q == Tv.EC_EMPTY_WORD then return false, 0 end
    setStringVar(ctx, adapters, 1, require("src.core.game3.easy_chat_text").word(q))
    g.quote[0] = Tv.EC_EMPTY_WORD
    return false, 1
  end,
  -- pokeemerald/src/tv.c:1020
  GabbyAndTyGetLastBattleTrivia = function()
    local g = Tv.state(Rse.session()).gabbyAndTyData
    if not g.battleTookMoreThanOneTurn2 then return false, 1 end
    if g.playerThrewABall2 then return false, 2 end
    if g.playerUsedHealingItem2 then return false, 3 end
    if g.playerLostAMon2 then return false, 4 end
    return false, 0
  end,
  -- pokeemerald/src/tv.c:935
  GabbyAndTyBeforeInterview = function()
    Tv.gabbyAndTyBeforeInterview(Rse.session())
    return false
  end,
  -- pokeemerald/src/tv.c:979
  GabbyAndTyAfterInterview = function()
    Tv.gabbyAndTyAfterInterview(Rse.session())
    return false
  end,
  -- pokeemerald/src/tv.c:775
  GetRandomActiveShowIdx = function()
    return false, Tv.getRandomActiveShowIdx(Rse.session(), random)
  end,
  -- pokeemerald/src/tv.c:901
  GetNextActiveShowIfMassOutbreak = function(ctx)
    return false, Tv.nextActiveIfMassOutbreak(Rse.session(), Rse.specialVar(ctx, VAR_0x8004))
  end,
  -- pokeemerald/src/tv.c:882
  GetSelectedTVShow = function(ctx)
    return false, Tv.selectedShowKind(Rse.session(), Rse.specialVar(ctx, VAR_0x8004))
  end,
  -- pokeemerald/src/tv.c:3386
  GetMomOrDadStringForTVMessage = function(ctx, adapters)
    local session = Rse.session()
    local opts = housesOpts(session)
    opts.random = random
    opts.getTemp3 = function() return Rse.var("VAR_TEMP_3", session) end
    opts.setTemp3 = function(v) Rse.setVar("VAR_TEMP_3", v, session) end
    local who = Tv.momOrDad(opts)
    setStringVar(ctx, adapters, 1, Rse.text(who == "mom" and "gText_Mom" or "gText_Dad"))
    return false
  end,
  -- pokeemerald/src/tv.c:875
  TurnOnTVScreen = function()
    setScreens(tvMetatile(true))
    return false
  end,
  -- pokeemerald/src/tv.c:869
  TurnOffTVScreen = function()
    setScreens(tvMetatile(false))
    return false
  end,
  -- pokeemerald/src/tv.c:2621
  DoPokeNews = function(ctx, adapters)
    local session = Rse.session()
    local Rtc = require("src.core.game3.rtc")
    local hours = (Rtc.localTime and Rtc.localTime.hours) or 0
    local res, shown = Tv.doPokeNews(session, hours, stringVars(ctx))
    if not shown then return boolRet(ctx, false) end
    showMessage(ctx, adapters, res)
    return boolRet(ctx, true)
  end,
  -- pokeemerald/src/tv.c:4198
  DoTVShow = function(ctx, adapters)
    local res, done = Tv.doTVShow(Rse.session(), Rse.specialVar(ctx, VAR_0x8004), stringVars(ctx))
    if not res then return boolRet(ctx, true) end
    showMessage(ctx, adapters, res)
    return boolRet(ctx, done)
  end,
  -- pokeemerald/src/tv.c:5427
  DoTVShowInSearchOfTrainers = function(ctx, adapters)
    local res, done = Tv.doInSearchOfTrainers(Rse.session(), stringVars(ctx))
    showMessage(ctx, adapters, res)
    return boolRet(ctx, done)
  end,
  -- pokeemerald/src/tv.c:2894
  InterviewBefore = function(ctx, adapters)
    Tv._stringVar1, Tv._stringVar2, Tv._var8006 = nil, nil, nil
    local r = Tv.interviewBefore(Rse.session(), Rse.specialVar(ctx, VAR_0x8005))
    if Tv._stringVar1 then setStringVar(ctx, adapters, 1, Tv._stringVar1) end
    if Tv._stringVar2 then setStringVar(ctx, adapters, 2, Tv._stringVar2) end
    if Tv._var8006 then Rse.setSpecialVar(ctx, VAR_0x8006, Tv._var8006) end
    return boolRet(ctx, r)
  end,
  -- pokeemerald/src/tv.c:1077
  InterviewAfter = function(ctx)
    local session = Rse.session()
    Tv.interviewAfter(session, Rse.specialVar(ctx, VAR_0x8005), {
      var8004 = Rse.specialVar(ctx, VAR_0x8004),
      var8007 = Rse.specialVar(ctx, VAR_0x8007),
      contestCategory = Rse.specialVar(ctx, VAR_CONTEST_CATEGORY),
      contestMon = contestMon(session),
      towerInterview = towerInterview(session),
    })
    return false
  end,
  -- pokeemerald/src/tv.c:3024
  IsLeadMonNicknamedOrNotEnglish = function(ctx)
    return boolRet(ctx, Tv.isLeadMonNicknamedOrNotEnglish(Rse.session()))
  end,
  -- pokeemerald/src/tv.c:2779
  SetContestCategoryStringVarForInterview = function(ctx, adapters)
    local show = Tv.state(Rse.session()).tvShows[Rse.specialVar(ctx, VAR_0x8004)]
    local cat = tonumber(show and show.contestCategory) or 0
    setStringVar(ctx, adapters, 2, Rse.text(string.format("gStdStrings[%d]", cat)))
    return false
  end,
  -- pokeemerald/src/tv.c:3268
  IsTVShowAlreadyInQueue = function(ctx)
    return boolRet(ctx, Tv.isShowAlreadyInQueue(Rse.session(), Rse.specialVar(ctx, VAR_0x8004)))
  end,
  -- pokeemerald/src/tv.c:3280
  TryPutNameRaterShowOnTheAir = function(ctx)
    local sv = stringVars(ctx)
    return boolRet(ctx, Tv.tryPutNameRaterShowOnTheAir(Rse.session(), monIndexVar(ctx), sv[3]))
  end,
  -- pokeemerald/src/tv.c:1897
  TryPutTreasureInvestigatorsOnAir = function(ctx)
    Tv.tryPutTreasureInvestigatorsOnAir(Rse.session(), Rse.specialVar(ctx, VAR_0x8005))
    return false
  end,
  -- pokeemerald/src/tv.c:2186
  TryPutLotteryWinnerReportOnAir = function(ctx)
    Tv.tryPutLotteryWinnerReportOnAir(Rse.session(), Rse.specialVar(ctx, VAR_0x8004), Rse.specialVar(ctx, VAR_0x8005))
    return false
  end,
  -- pokeemerald/src/tv.c:2324
  TryPutTrainerFanClubOnAir = function()
    Tv.tryPutTrainerFanClubOnAir(Rse.session())
    return false
  end,
  -- pokeemerald/src/tv.c:2342
  ShouldHideFanClubInterviewer = function(ctx)
    Tv._var8006 = nil
    local hide = Tv.shouldHideFanClubInterviewer(Rse.session())
    if Tv._var8006 then Rse.setSpecialVar(ctx, VAR_0x8006, Tv._var8006) end
    return boolRet(ctx, hide)
  end,
  -- pokeemerald/src/tv.c:1338
  PutFanClubSpecialOnTheAir = function(ctx)
    local session = Rse.session()
    local recs = session and session.linkBattleRecords
    local entries = type(recs) == "table" and (recs.entries or recs) or {}
    local first = type(entries) == "table" and (entries[1] or entries[0]) or nil
    Tv.putFanClubSpecialOnTheAir(session, Rse.specialVar(ctx, VAR_0x8006), Rse.specialVar(ctx, VAR_0x8005),
      stringVars(ctx)[1], type(first) == "table" and first.language or nil)
    return false
  end,
  -- pokeemerald/src/tv.c:1581
  PutLilycoveContestLadyShowOnTheAir = function(ctx)
    local session = Rse.session()
    local lady = lilycoveContestLady(session)
    if lady then
      Tv.putLilycoveContestLadyShowOnTheAir(session, lady)
      setResult(ctx, Tv._result and 1 or 0)
    end
    return false
  end,
}

-- pokeemerald/src/easy_chat.c:1486
function NativesTv.installEasyChatTypes()
  local ok, Types = pcall(require, "src.core.game3.rse.easy_chat_types")
  if not (ok and type(Types) == "table" and Types.register) then return false end
  for _, typeId in ipairs({ Tv.EASY_CHAT_TYPE.INTERVIEW, Tv.EASY_CHAT_TYPE.FAN_CLUB, Tv.EASY_CHAT_TYPE.GABBY_AND_TY,
      Tv.EASY_CHAT_TYPE.CONTEST_INTERVIEW, Tv.EASY_CHAT_TYPE.BATTLE_TOWER_INTERVIEW, Tv.EASY_CHAT_TYPE.FAN_QUESTION }) do
    local function slot(ctx, sess)
      return Tv.easyChatWords(sess, typeId, Rse.specialVar(ctx, VAR_0x8005), Rse.specialVar(ctx, VAR_0x8006))
    end
    Types.register(typeId, {
      words = function(ctx, sess)
        local arr, first, count = slot(ctx, sess)
        if not arr then return nil end
        local out = {}
        for i = 0, count - 1 do out[i + 1] = arr[first + i] or Tv.EC_EMPTY_WORD end
        return out
      end,
      commit = function(ctx, sess, words)
        local s = Tv.state(sess)
        local arr, first, count
        if typeId == Tv.EASY_CHAT_TYPE.GABBY_AND_TY then
          arr, first, count = s.gabbyAndTyData.quote, 0, 1
        else
          local show = s.tvShows[Rse.specialVar(ctx, VAR_0x8005)]
          if not (show and type(show.words) == "table") then return end
          arr = show.words
          first = (typeId == Tv.EASY_CHAT_TYPE.FAN_CLUB or typeId == Tv.EASY_CHAT_TYPE.CONTEST_INTERVIEW)
            and Rse.specialVar(ctx, VAR_0x8006) + 1 or 1
          count = typeId == Tv.EASY_CHAT_TYPE.INTERVIEW and 4 or 1
        end
        for i = 0, count - 1 do arr[first + i] = tonumber(words[i + 1]) or Tv.EC_EMPTY_WORD end
      end,
    })
  end
  return true
end

NativesTv.installTimeHooks()
NativesTv.installEasyChatTypes()
Std.legacyHandlers(NativesTv)

return NativesTv
