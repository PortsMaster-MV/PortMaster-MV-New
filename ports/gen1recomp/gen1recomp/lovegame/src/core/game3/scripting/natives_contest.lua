local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")

local NativesContest = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_0x8005 = 0x8005
local VAR_0x8006 = 0x8006
local VAR_RESULT = 0x800D
-- pokeemerald/include/constants/vars.h:299
local VAR_CONTEST_RANK = 0x8010
local VAR_CONTEST_CATEGORY = 0x8011
-- pokeemerald/include/constants/global.h:33
local PARTY_SIZE = 6
-- pokeemerald/include/constants/party_menu.h:4
local PARTY_NOTHING_CHOSEN = 0xFF
-- pokeemerald/include/link.h:4
local MAX_LINK_PLAYERS = 4
-- pokeemerald/include/constants/cable_club.h:22
local LINKUP_FAILED = 5

NativesContest.partyIndex = 0
NativesContest.linkFlags = 0
NativesContest.ui = {}

local function Util(sess)
  local Rs = require("src.core.game3.rs.contest_util")
  if Rs.is(sess or Rse.session()) then return Rs end
  return require("src.core.game3.rse.contest_util")
end
local function ContestLink() return require("src.core.game3.link.contest_link") end
local function Link() return require("src.core.game3.link.init") end
local function Natives() return require("src.core.game3.scripting.natives") end
local function session() return Rse.session() end

local function logger(adapters)
  return adapters and adapters.log or nil
end

local function var(ctx, id) return Rse.specialVar(ctx, id) end
local function setVar(ctx, id, v) Rse.setSpecialVar(ctx, id, v) end

local function setString(ctx, i, s)
  if ctx and ctx.stringVars then ctx.stringVars[i] = s end
end

local function current() return Util().current() end

-- pokeemerald/src/new_game.c:176
local function ensureWinners(sess, data)
  if sess and type(sess.contestWinners) ~= "table" then
    local c = current()
    Util(sess).clearAllWinners(sess, data or (c and c.data) or nil)
  end
  return sess
end
NativesContest.ensureWinners = ensureWinners

local function uiModule(key, path)
  local m = NativesContest.ui[key]
  if m then return m end
  local ui = require("src.core.game3.profile").forSession(session()).ui
  local native = ui and ui.contest and ui.contest[key]
  if native then return require(native) end
  return require(path)
end

function NativesContest.reset()
  NativesContest.partyIndex = 0
  NativesContest.linkFlags = 0
  local CL = package.loaded["src.core.game3.link.contest_link"]
  if CL then CL.reset() end
end

-- pokeemerald/src/contest_util.c:61
local function winnerIndex(c)
  return Util().winnerId(c)
end

-- pokeemerald/src/field_screen_effect.c:755
function NativesContest.doContestHallWarp(ctx, adapters)
  local sess = session()
  local dest = sess and sess.warpDestination
  if not (type(dest) == "table" and adapters and adapters.warp) then return false end
  if adapters.playSe then
    local okS, SE = pcall(require, "src.core.game3.se_ids")
    if okS and SE and SE.SE_EXIT then adapters.playSe(SE.SE_EXIT, false) end
  end
  ctx.warpPending = true
  adapters.warp(dest.mapGroup, dest.mapNum, dest.warpId, dest.x, dest.y, function()
    ctx.warpPending = false
  end, "warp")
  return false
end

-- pokeemerald/src/party_menu.c:6234
function NativesContest.chooseContestMon(vm)
  local ctx, adapters = vm.ctx, vm.adapters
  local sess = session()
  if require("src.core.game3.rs.contest_util").is(sess) then
    return Natives().yieldHost(ctx, adapters, function(done)
      require("src.ui.game3.rse.contest_party").show(sess,
        var(ctx, VAR_CONTEST_CATEGORY), var(ctx, VAR_CONTEST_RANK), function(slot)
          slot = tonumber(slot) or PARTY_NOTHING_CHOSEN
          if slot < 0 or slot >= PARTY_SIZE then slot = PARTY_NOTHING_CHOSEN end
          setVar(ctx, VAR_0x8004, slot)
          NativesContest.partyIndex = slot
          done()
        end)
    end)
  end
  local yield = Natives().choosePartyMon(ctx, adapters, "choose_contest")
  local function settle()
    local slot = var(ctx, VAR_0x8004)
    if slot >= PARTY_SIZE then
      slot = PARTY_NOTHING_CHOSEN
      setVar(ctx, VAR_0x8004, slot)
    end
    NativesContest.partyIndex = slot
  end
  if not yield then
    settle()
    return false
  end
  local poll = ctx.nativePoll
  ctx.nativePoll = function()
    if poll and not poll() then return false end
    settle()
    return true
  end
  return true
end

local function fadeClear()
  local Fade = require("src.ui.game3.fade")
  Fade.clear()
end

local function fadeInField()
  local Fade = require("src.ui.game3.fade")
  Fade.mode, Fade.t, Fade.active = Fade.MODE.TO_BLACK, 16, false
  Fade.begin(Fade.MODE.FROM_BLACK, 1)
end

local function screen(vm, key, path, opts, onClose)
  local ctx, adapters = vm.ctx, vm.adapters
  return Natives().yieldHost(ctx, adapters, function(done)
    local Fade = require("src.ui.game3.fade")
    local function open()
      fadeClear()
      local mod = uiModule(key, path)
      opts.onDone = function(...)
        if onClose then onClose(...) end
        fadeInField()
        done()
      end
      mod.open(opts)
    end
    if Fade.t and Fade.t >= 16 then
      open()
    else
      Fade.begin(Fade.MODE.TO_BLACK, 1, open)
    end
  end)
end

-- pokeemerald/src/contest_util.c:2131
function NativesContest.startContest(vm)
  local c = current()
  if not c then
    Rse.missing("contest", "startcontest without TryEnterContestMon", logger(vm.adapters))
    return false
  end
  return screen(vm, "stage", "src.ui.game3.rse.contest", { contest = c, session = session() })
end

-- pokeemerald/src/contest_util.c:2152
function NativesContest.showContestResults(vm)
  local c = current()
  if not c then
    Rse.missing("contest", "showcontestresults without a contest", logger(vm.adapters))
    return false
  end
  return screen(vm, "results", "src.ui.game3.rse.contest_results", { contest = c, session = session() })
end

-- pokeemerald/src/scrcmd.c:1469
function NativesContest.showContestPainting(vm, winnerId)
  winnerId = tonumber(winnerId) or 0
  local U = Util()
  local sess = ensureWinners(session())
  local winner, isForArtist, saveIdx
  if winnerId ~= U.WINNER.ARTIST then
    -- pokeemerald/src/contest_painting.c:164
    winner = sess and sess.contestWinners and sess.contestWinners[winnerId]
    saveIdx = winnerId - 1
    isForArtist = false
    NativesContest.curWinner, NativesContest.curSaveIdx, NativesContest.curIsForArtist = winner, saveIdx, false
  else
    winner = NativesContest.curWinner or U.curWinner
    saveIdx = NativesContest.curSaveIdx or U.winnerSaveIdx(sess or {}, U.SAVE_FOR_ARTIST, 0, false)
    isForArtist = NativesContest.curIsForArtist ~= false
  end
  if type(winner) ~= "table" then
    Rse.missing("contestPainting", "painting without a contest winner", logger(vm.adapters))
    return false
  end
  return screen(vm, "painting", "src.ui.game3.rse.contest_painting",
    { winner = winner, saveIdx = saveIdx, isForArtist = isForArtist, session = sess })
end

-- pokeemerald/src/contest_util.c:662
function NativesContest.onResultsShown(c, sess)
  local U = Util(sess)
  sess = ensureWinners(sess or session(), c.data)
  U.saveContestWinner(sess, c.rank, c)
  U.saveContestWinner(sess, U.SAVE_FOR_ARTIST, c)
  NativesContest.curWinner = U.curWinner
  NativesContest.curIsForArtist = true
  NativesContest.curSaveIdx = U.winnerSaveIdx(sess, U.SAVE_FOR_ARTIST, c.category, false)
end

local function isLink()
  return NativesContest.linkFlags % 2 == 1
end

local function isWireless()
  return math.floor(NativesContest.linkFlags / 2) % 2 == 1
end

local function linkSession()
  local CL = ContestLink()
  return isLink() and CL.active or nil
end

-- pokeemerald/src/contest_util.c:2164
function NativesContest.contestLinkTransfer(vm)
  local ctx, adapters = vm.ctx, vm.adapters
  local CL = ContestLink()
  local lk = Link().link
  local sess = session()
  local mon = sess and sess.party and sess.party[NativesContest.partyIndex + 1]
  if not (lk and lk:isOpen() and mon) then
    setVar(ctx, VAR_0x8004, CL.RESULT.ERROR)
    return false
  end
  local Natives = Natives()
  if not Natives.yieldHost(ctx, adapters, function() end) then return false end
  local job
  local category = var(ctx, VAR_CONTEST_CATEGORY)
  ctx.nativePoll = function()
    local live = Link().link
    if not (live and live:isOpen()) then
      setVar(ctx, VAR_0x8004, CL.RESULT.ERROR)
      return true
    end
    if not job then
      if live.isReady and not live:isReady() then return false end
      -- pokeemerald/src/contest_link.c:74
      local flags = CL.FLAG.IS_LINK + (CL.wireless and CL.FLAG.IS_WIRELESS or 0)
      local s = CL.newSession(live, { flags = flags })
      local contestant = Util().contestantFromMon(mon, sess)
      if contestant.nickname == nil or contestant.nickname == "" then
        local Pokemon = require("src.core.game3.pokemon")
        contestant.nickname = Pokemon.displayName and Pokemon.displayName(mon) or Pokemon.name(contestant.species)
      end
      local okF, cleared = pcall(Rse.flag, "FLAG_SYS_GAME_CLEAR", sess)
      job = CL.beginTransfer({ session = s, category = category, partyMon = mon, contestant = contestant,
        gameCleared = okF and cleared == true })
    end
    local code = job:step()
    if code == nil then return false end
    setVar(ctx, VAR_0x8004, code)
    if code == CL.RESULT.OK then
      local s = job.session
      NativesContest.linkFlags = s.flags
      CL.active = s
      Util().state = { contest = job.contest, partyIndex = NativesContest.partyIndex,
        category = job.contest.category, rank = job.contest.rank, link = s }
      -- pokeemerald/src/contest_util.c:2268
      if sess then sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = sess.x, y = sess.y } end
    else
      job.session:abort()
    end
    return true
  end
  return true
end

NativesContest.SYSTEM = {
  choosecontestmon = function(vm) return NativesContest.chooseContestMon(vm) end,
  startcontest = function(vm) return NativesContest.startContest(vm) end,
  showcontestresults = function(vm) return NativesContest.showContestResults(vm) end,
  -- pokeemerald/src/contest_util.c:2164
  contestlinktransfer = function(vm) return NativesContest.contestLinkTransfer(vm) end,
  contestMonPartyIndex = function() return NativesContest.partyIndex end,
}

NativesContest.PAINTING = {
  show = function(vm, winnerId) return NativesContest.showContestPainting(vm, winnerId) end,
}

local function linkup(min, max, linkType)
  return function(ctx, adapters)
    local CL = ContestLink()
    CL.wireless = false
    local okB, LinkBattle = pcall(require, "src.core.game3.link.battle")
    if not (okB and LinkBattle and LinkBattle.createLinkupTask) then
      setVar(ctx, VAR_RESULT, LINKUP_FAILED)
      return false
    end
    return LinkBattle.createLinkupTask(ctx, adapters, { min = min, max = max, linkType = CL.LINKTYPE[linkType] })
  end
end

-- pokeemerald/src/contest_util.c:2718
function NativesContest.linkContestWaitForConnection(ctx, adapters)
  local s = linkSession()
  if not (s and isWireless()) then return false, 0 end
  local Natives = Natives()
  if not Natives.yieldHost(ctx, adapters, function() end) then return false, 1 end
  ctx.nativePoll = function()
    local ok, err = s:standby()
    return ok == true or err ~= nil
  end
  return true, 1
end

NativesContest.BY_NAME = {
  -- pokeemerald/src/contest_util.c:2302
  GetNpcContestantLocalId = function(ctx)
    local contestant = var(ctx, VAR_0x8005) % 0x100
    local localId = ({ 3, 4, 5 })[contestant + 1] or 100
    setVar(ctx, VAR_0x8004, localId)
    return false
  end,
  -- pokeemerald/src/contest_util.c:1958
  TryEnterContestMon = function(ctx)
    local sess = session()
    local idx = NativesContest.partyIndex
    local mon = sess and sess.party and sess.party[idx + 1]
    if not mon then
      setVar(ctx, VAR_RESULT, 0)
      return false
    end
    local e = Util().tryEnterContestMon(sess, idx, var(ctx, VAR_CONTEST_CATEGORY), var(ctx, VAR_CONTEST_RANK))
    local c = current()
    local m = c and c.mons[c.playerIndex]
    if e ~= 0 and m and (m.nickname == nil or m.nickname == "") then
      -- pokeemerald/src/contest.c:2798
      local Pokemon = require("src.core.game3.pokemon")
      m.nickname = Pokemon.displayName and Pokemon.displayName(mon) or Pokemon.name(m.species)
    end
    setVar(ctx, VAR_RESULT, e)
    return false
  end,
  -- pokeemerald/src/contest_util.c:1972
  HasMonWonThisContestBefore = function(ctx)
    local sess = session()
    local mon = sess and sess.party and sess.party[NativesContest.partyIndex + 1]
    if not mon then return false, 0 end
    local won = Util().hasMonWonThisContestBefore(mon, var(ctx, VAR_CONTEST_CATEGORY), var(ctx, VAR_CONTEST_RANK))
    return false, won and 1 or 0
  end,
  -- pokeemerald/src/contest_util.c:2003
  GiveMonContestRibbon = function()
    Util().giveMonContestRibbon(session())
    return false
  end,
  -- pokeemerald/src/contest_util.c:2549
  GiveMonArtistRibbon = function()
    return false, Util().giveMonArtistRibbon(session()) and 1 or 0
  end,
  -- pokeemerald/src/contest_util.c:2077
  GetContestMonConditionRanking = function(ctx)
    local c = current()
    if c then setVar(ctx, VAR_0x8004, Util().conditionRanking(c, var(ctx, VAR_0x8006))) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2090
  GetContestMonCondition = function(ctx)
    local c = current()
    if c then setVar(ctx, VAR_0x8004, Util().condition(c, var(ctx, VAR_0x8006))) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2095
  GetContestWinnerId = function(ctx)
    local c = current()
    if c then setVar(ctx, VAR_0x8005, winnerIndex(c)) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2102
  BufferContestWinnerTrainerName = function(ctx)
    local c = current()
    if c then setString(ctx, 3, Util().trainerName(c.mons[winnerIndex(c)])) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2110
  BufferContestWinnerMonName = function(ctx)
    local c = current()
    if c then setString(ctx, 1, Util().monName(c.mons[winnerIndex(c)])) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2159
  GetContestPlayerId = function(ctx)
    local c = current()
    setVar(ctx, VAR_0x8004, c and c.playerIndex or 3)
    return false
  end,
  -- pokeemerald/src/contest_util.c:2294
  SetContestTrainerGfxIds = function()
    if current() then Util().setContestTrainerGfxIds(session()) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2325
  BufferContestTrainerAndMonNames = function(ctx)
    local c = current()
    if not c then return false end
    local m = c.mons[var(ctx, VAR_0x8006)]
    if not m then return false end
    setString(ctx, 1, Util().trainerName(m))
    setString(ctx, 3, Util().monName(m))
    setVar(ctx, VAR_0x8004, tonumber(m.species) or 0)
    return false
  end,
  -- pokeemerald/src/contest_util.c:2333
  DoesContestCategoryHaveMuseumPainting = function(ctx)
    setVar(ctx, VAR_0x8004, Util().categoryHasMuseumPainting(ensureWinners(session()), var(ctx, VAR_CONTEST_CATEGORY)) and 1 or 0)
    return false
  end,
  -- pokeemerald/src/contest_util.c:2362
  SaveMuseumContestPainting = function()
    if current() then Util().saveContestWinner(ensureWinners(session()), Util().SAVE_FOR_MUSEUM) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2367
  ShouldReadyContestArtist = function(ctx)
    setVar(ctx, VAR_0x8004, Util().shouldReadyContestArtist(current()) and 1 or 0)
    return false
  end,
  -- pokeemerald/src/contest_util.c:2381
  CountPlayerMuseumPaintings = function()
    return false, Util().countPlayerMuseumPaintings(ensureWinners(session()) or {})
  end,
  -- pokeemerald/src/contest_util.c:2396
  GetContestantNamesAtRank = function(ctx)
    local c = current()
    if not c then return false end
    local who, rank = Util().contestantAtConditionRank(c, var(ctx, VAR_0x8006))
    setString(ctx, 1, Util().monName(c.mons[who]))
    setString(ctx, 2, Util().trainerName(c.mons[who]))
    setVar(ctx, VAR_0x8006, rank)
    return false
  end,
  -- pokeemerald/src/contest_util.c:2478
  ShowContestPainting = function(ctx, adapters)
    local vm = { ctx = ctx, adapters = adapters }
    return NativesContest.showContestPainting(vm, NativesContest.curSaveIdx and NativesContest.curSaveIdx + 1 or 0)
  end,
  -- pokeemerald/src/contest_util.c:2484
  SetLinkContestPlayerGfx = function()
    local c = current()
    if not (c and isLink()) then return false end
    for i = 0, 3 do
      local m = c.mons[i]
      if m then Rse.setVar("VAR_OBJ_GFX_ID_" .. i, tonumber(m.trainerGfxId) or 0, session()) end
    end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2509
  LoadLinkContestPlayerPalettes = function() return false end,
  -- pokeemerald/src/contest_util.c:2572
  IsContestDebugActive = function() return false, 0 end,
  -- pokeemerald/src/contest_util.c:2577
  ShowContestEntryMonPic = function(ctx)
    local c = current()
    if not c then return false end
    local m = c.mons[var(ctx, VAR_0x8006)]
    if m then uiModule("entryPic", "src.ui.game3.rse.contest_entry_pic").show(m) end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2626
  HideContestEntryMonPic = function()
    uiModule("entryPic", "src.ui.game3.rse.contest_entry_pic").hide()
    return false
  end,
  -- pokeemerald/src/contest_util.c:2670
  GetContestMultiplayerId = function(ctx)
    local s = linkSession()
    if s and s.count == MAX_LINK_PLAYERS and not isWireless() then
      setVar(ctx, VAR_RESULT, s.seat)
    else
      setVar(ctx, VAR_RESULT, MAX_LINK_PLAYERS)
    end
    return false
  end,
  -- pokeemerald/src/contest_util.c:2680
  GenerateContestRand = function(ctx)
    local modulo = var(ctx, VAR_RESULT)
    local s = linkSession()
    local r
    if s and s.contestRng then
      r = s.contestRng.next()
    else
      r = require("src.core.game3.rng").Random() % 65536
    end
    setVar(ctx, VAR_RESULT, modulo ~= 0 and (r % modulo) or 0)
    return false
  end,
  -- pokeemerald/src/contest_util.c:2705
  LinkContestWaitForConnection = function(ctx, adapters)
    return NativesContest.linkContestWaitForConnection(ctx, adapters)
  end,
  -- pokeemerald/src/contest_util.c:2742
  LinkContestTryShowWirelessIndicator = function() return false end,
  -- pokeemerald/src/contest_util.c:2754
  LinkContestTryHideWirelessIndicator = function() return false end,
  -- pokeemerald/src/contest_util.c:2763
  IsContestWithRSPlayer = function() return false, 0 end,
  -- pokeemerald/src/contest_util.c:2771
  ClearLinkContestFlags = function()
    NativesContest.linkFlags = 0
    ContestLink().active = nil
    return false
  end,
  -- pokeemerald/src/contest_util.c:2776
  IsWirelessContest = function() return false, isWireless() and 1 or 0 end,
  -- pokeemerald/src/field_screen_effect.c:755
  DoContestHallWarp = function(ctx, adapters)
    return NativesContest.doContestHallWarp(ctx, adapters)
  end,
  -- pokeemerald/src/cable_club.c:710
  TryContestGModeLinkup = linkup(4, 4, "GMODE"),
  -- pokeemerald/src/cable_club.c:717
  TryContestEModeLinkup = linkup(2, 4, "EMODE"),
}

Rse.register("contest", NativesContest.SYSTEM)
Rse.register("contestPainting", NativesContest.PAINTING)

Std.legacyHandlers(NativesContest)

ContestLink()

return NativesContest
