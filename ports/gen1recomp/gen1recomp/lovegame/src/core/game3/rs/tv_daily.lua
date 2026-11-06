local Tv = require("src.core.game3.rse.tv")
local Q = require("src.core.game3.rs.tv_queries")
local Playback = require("src.core.game3.rs.tv_playback")
local M = {}
local function n(v) return math.floor(tonumber(v) or 0) end
local function u16(v) return n(v) % 65536 end
local function on(v) return v == true or n(v) ~= 0 end
local function random() return Tv.random() end
-- tv.c:1923
local function accepts(value) return n((M.random or random)()) <= value end
local function C(session) return require("src.save_convert.Gen3Save").forVersion(session.version) end
local function constants(session) return require("src.core.game3.constants").active(session) end
local function list(session) return Tv.state(session).tvShows end
local function species(mon) return n(mon and (mon.species or mon.speciesId)) end
local function stat(session, id) return n(session.gameStats and session.gameStats[id]) end
local function kind(show) return n(show and show.kind) % 256 end
local function flag(session, name) return require("src.core.game3.rse.init").flag(name, session) end
local function name(session) return Q.encode(session, session.name or session.playerName, 8) end
local function raw(session, show) return Playback.rawShow(session, show or {kind = 0, active = false}) end
local function buffer(session, slot) return C(session).newBuf(36, raw(session, list(session)[slot])) end
local function commit(session, slot, b)
  list(session)[slot] = require("src.save_convert.gen3_port.sections.rs_tv_shows").readSlot(b:str(), C(session))
end
local function bytes(s, off)
  local out = {}
  for i = off + 1, #s do out[#out + 1] = s:byte(i); if s:byte(i) == 255 then return out end end
  out[#out + 1] = 255; return out
end
local function copy(b, off, a)
  for i, v in ipairs(a) do
    if off + i > 36 then break end
    b:w8(off + i - 1, v); if v == 255 then break end
  end
end
local function ids(b, session, recordMix)
  local id = Tv.playerId(session) % 65536
  if recordMix then b:w16(30, id) end
  b:w16(32, id); b:w16(34, id)
end
local function ownDuplicate(session, showKind)
  local id = Tv.playerId(session) % 65536
  for i = 5, 23 do
    local s = list(session)[i]
    if kind(s) == showKind then
      local r = raw(session, s)
      if r:byte(35) + r:byte(36) * 256 == id then return true end
    end
  end
  return false
end
local function recordSlot(session, showKind)
  Tv._curSlot = Tv.firstEmptyRecordMixSlot(list(session))
  if Tv._curSlot == -1 or ownDuplicate(session, showKind) then return nil end
  return Tv._curSlot
end
local function lead(session)
  local p = session.party or {}
  for i = 1, 6 do
    if species(p[i]) == 0 then break end
    if not (p[i].isEgg == true or p[i].egg == true or p[i].isBadEgg == true) then return p[i] end
  end
  return p[1]
end
local function ballCount(results)
  local total = 0
  for i = 1, 11 do total = u16(total + n(results.catchAttempts and results.catchAttempts[i])) end
  return total
end
local function news(session) return Tv.state(session).pokeNews end
local function emptyNews() return {kind = 0, state = 0, dayCountdown = 0} end

-- tv.c:434
function M.clearTVShowData(session)
  local s = Tv.state(session)
  for i = 0, 24 do Tv.deleteShow(s.tvShows, i) end
  for i = 0, 15 do s.pokeNews[i] = emptyNews() end
end
function M.resetGabbyAndTy(session)
  Tv.state(session).gabbyAndTyData = {
    mon1 = 0, mon2 = 0, lastMove = 0, quote = {[0] = 65535}, mapnum = 0, battleNum = 0,
    battleTookMoreThanOneTurn = false, playerLostAMon = false, playerUsedHealingItem = false,
    playerThrewABall = false, onAir = false, valA_5 = 0,
    battleTookMoreThanOneTurn2 = false, playerLostAMon2 = false, playerUsedHealingItem2 = false,
    playerThrewABall2 = false, valB_4 = 0, valB_5 = 0,
  }
end

-- tv.c:1432
function M.shouldApplyPokeNews(session, newsKind, talked)
  local prefix = require("src.core.game3.profile").forSession(session).map.enginePrefix
  if talked == nil then
    local Space = package.loaded["src.core.game3.scripting.space"]
    local ctx = Space and Space.vm and Space.vm.ctx
    talked = ctx and ctx.specialVars and ctx.specialVars[0x800F]
  end
  if n(newsKind) == 1 then return session.map == prefix .. "SLATEPORT_CITY" and n(talked) == 26 end
  if n(newsKind) == 3 then return session.map == prefix .. "LILYCOVE_CITY_DEPARTMENT_STORE_ROOFTOP" end
  return true
end
local function discounted(session, k)
  if k == 0 then return false end
  for i = 0, 15 do
    local e = news(session)[i]
    if n(e.kind) == k then return n(e.state) == 2 and M.shouldApplyPokeNews(session, k) end
  end
  return false
end
M.syncOutbreak = Playback.syncOutbreak
-- tv.c:1177
function M.endMassOutbreak(session)
  for _, f in ipairs(Tv.OUTBREAK_FIELDS) do
    session[f] = f == "outbreakPokemonMoves" and {0, 0, 0, 0} or 0
  end
  M.syncOutbreak(session)
end
-- tv.c:1286
local function resolveWorld(session)
  local src = list(session)[24]
  if kind(src) ~= 25 then return end
  if u16(src.numPokeCaught) < 20 then Tv.deleteShow(list(session), 24); return end
  if not accepts(65535) then return end
  local slot = recordSlot(session, 25)
  if not slot then return end
  local b = buffer(session, slot)
  b:w8(0, 25); b:w8(1, 0); b:w16(2, n(src.numPokeCaught))
  b:w16(4, n(src.caughtPoke)); b:w16(6, u16(stat(session, 5) - n(src.steps)))
  b:w16(8, n(src.species)); b:w8(10, n(src.location)); copy(b, 19, name(session))
  ids(b, session, true); b:w8(11, 2); commit(session, slot, b)
end
-- tv.c:1194
function M.updatePerDay(session, days)
  days = u16(days)
  if n(session.outbreakPokemonSpecies) == 0 then
    for i = 0, 23 do
      local s = list(session)[i]
      if kind(s) == 41 and Q.activeByte(s) == 1 then
        s.daysBeforeOutbreak = math.max(0, u16(s.daysBeforeOutbreak) - days); break
      end
    end
  end
  if n(session.outbreakDaysLeft) <= days then M.endMassOutbreak(session)
  else session.outbreakDaysLeft = u16(session.outbreakDaysLeft - days) end
  local rows = news(session)
  for i = 0, 15 do
    local e = rows[i]
    if n(e.kind) ~= 0 then
      if u16(e.dayCountdown) < days then rows[i] = emptyNews()
      else
        if n(e.state) == 0 and flag(session, "FLAG_SYS_GAME_CLEAR") then e.state = 1 end
        e.dayCountdown = u16(e.dayCountdown) - days
      end
    end
  end
  for i = 0, 14 do
    if n(rows[i].kind) == 0 then
      for j = i + 1, 15 do
        if n(rows[j].kind) ~= 0 then rows[i], rows[j] = rows[j], emptyNews(); break end
      end
    end
  end
  resolveWorld(session)
end
-- tv.c:1323
function M.tryPutRandomPokeNewsOnAir(session)
  if not flag(session, "FLAG_SYS_GAME_CLEAR") then return end
  local rows, slot = news(session)
  for i = 0, 15 do if n(rows[i].kind) == 0 then slot = i; break end end
  Tv._curSlot = slot or -1
  if slot == nil or not accepts(655) then return end
  local k = n((M.random or random)()) % 3 + 1
  for i = 0, 15 do if n(rows[i].kind) == k then return end end
  rows[slot] = {kind = k, state = 1, dayCountdown = 4}
end
local outbreakData
function M.resetData() outbreakData = nil end
local function outbreaks()
  if M.outbreakSpecies then return M.outbreakSpecies end
  if not outbreakData then
    local cache = require("src.core.game3.dataset").cache()
    local path = "data/generated/gba/rse/rs_tv/manifest.lua"
    local source = assert(cache and cache:read(path), "native RS TV outbreak data missing: " .. path)
    local chunk = assert(load(source, "@" .. path, "t", {}))
    outbreakData = assert(chunk().outbreakSpecies, "native RS TV outbreak rows missing")
  end
  assert(#outbreakData == 5, "native RS TV requires exactly five outbreak rows")
  return outbreakData
end
-- tv.c:1132
function M.tryStartRandomMassOutbreak(session, rows)
  if not flag(session, "FLAG_SYS_GAME_CLEAR") then return end
  for i = 0, 23 do if kind(list(session)[i]) == 41 then return end end
  if not accepts(327) then return end
  local slot = Tv.firstEmptyNormalSlot(list(session)); Tv._curSlot = slot
  if slot == -1 then return end
  rows = rows or outbreaks(); assert(#rows == 5, "native RS outbreak row count")
  local e, b = rows[n((M.random or random)()) % 5 + 1], buffer(session, slot)
  b:w8(0, 41); b:w8(1, 1); b:w8(20, e.level); b:w8(2, 0); b:w8(3, 0)
  b:w16(12, e.species); b:w16(14, 0)
  for i = 1, 4 do b:w16(2 + i * 2, e.moves[i]) end
  b:w8(16, e.location); b:w8(17, 0); b:w8(18, 0); b:w8(19, 50); b:w8(21, 0)
  b:w16(22, 1); ids(b, session, false); b:w8(24, 2); commit(session, slot, b)
  return slot
end
-- tv.c:858
function M.initWorldOfMastersShowAttempt(session, results)
  local src = list(session)[24]
  if kind(src) ~= 25 then
    Tv.deleteShow(list(session), 24)
    local b = buffer(session, 24); b:w16(6, u16(stat(session, 5))); b:w8(0, 25); commit(session, 24, b)
  end
  local b = buffer(session, 24)
  b:w16(2, u16(n(list(session)[24].numPokeCaught) + 1)); b:w16(4, n(results.caughtMonSpecies))
  b:w16(8, n(results.playerMon1Species)); b:w8(10, Tv.mapSec(session)); commit(session, 24, b)
end
-- tv.c:874
function M.tryPutPokemonTodayFailedOnTheAir(session, results, outcome)
  results = results or {}
  if not accepts(65535) then return end
  local total = math.min(ballCount(results), 255)
  if total <= 2 or n(outcome) ~= 1 then return end
  local slot = recordSlot(session, 23); if not slot then return end
  local b = buffer(session, slot)
  b:w8(0, 23); b:w8(1, 0); b:w16(12, n(results.playerMon1Species)); b:w16(14, n(results.lastOpponentSpecies))
  b:w8(16, total); b:w8(17, outcome); b:w8(18, Tv.mapSec(session)); copy(b, 19, name(session))
  ids(b, session, true); b:w8(2, 2); commit(session, slot, b)
end
-- tv.c:798
function M.tryPutPokemonTodayOnAir(session, results, outcome)
  results = results or {}
  M.tryPutRandomPokeNewsOnAir(session); M.tryStartRandomMassOutbreak(session)
  local caught = n(results.caughtMonSpecies)
  if caught == 0 then return M.tryPutPokemonTodayFailedOnTheAir(session, results, outcome) end
  M.initWorldOfMastersShowAttempt(session, results)
  if not accepts(65535) then return end
  local nick = results.caughtMonNickBytes or Q.encode(session, results.caughtMonNick, 256)
  if Q.equal(Q.encode(session, Tv.speciesName(caught)), nick) then return end
  local slot = recordSlot(session, 21); if not slot then return end
  local total, master = ballCount(results), on(results.usedMasterBall)
  if total == 0 and not master then return end
  local b = buffer(session, slot)
  b:w8(0, 21); b:w8(1, 0)
  if master then total = 1; b:w8(15, constants(session):require("items", "ITEM_MASTER_BALL"))
  else total = math.min(total, 255); b:w8(15, n(results.lastUsedItem)) end
  b:w8(18, total); copy(b, 19, name(session)); copy(b, 4, nick); b:w16(16, caught)
  ids(b, session, true); b:w8(2, 2); b:w8(3, nick[1] == 252 and nick[2] == 21 and 1 or 2)
  copy(b, 4, Q.strip(bytes(b:str(), 4))); commit(session, slot, b)
end
-- tv.c:1233
function M.recordFishingAttempt(session, success)
  local value = u16(Tv._anglerCounters)
  if on(success) then
    if math.floor(value / 256) > 4 then M.tryPutFishingAdviceOnAir(session) end
    Tv._anglerCounters = math.min(value % 256 + 1, 255)
  else
    if value % 256 > 4 then M.tryPutFishingAdviceOnAir(session) end
    Tv._anglerCounters = math.min(math.floor(value / 256) + 1, 255) * 256
  end
end
function M.tryPutFishingAdviceOnAir(session)
  local slot = recordSlot(session, 24); if not slot then return end
  local b, value = buffer(session, slot), u16(Tv._anglerCounters)
  b:w8(0, 24); b:w8(1, 0); b:w8(2, value % 256); b:w8(3, math.floor(value / 256))
  b:w16(4, u16(Tv._anglerSpecies)); copy(b, 19, name(session)); ids(b, session, true)
  b:w8(6, 2); commit(session, slot, b)
end
-- tv.c:1007
function M.tryPutSmartShopperOnAir(session, history)
  if not accepts(21845) then return end
  local slot = recordSlot(session, 22); if not slot then return end
  history = history or {}
  for i = 1, 3 do history[i] = history[i] or {itemId = 0, quantity = 0} end
  for i = 1, 2 do
    for j = i + 1, 3 do
      if u16(history[i].quantity) < u16(history[j].quantity) then history[i], history[j] = history[j], history[i] end
    end
  end
  if u16(history[1].quantity) < 20 then return end
  local b = buffer(session, slot); b:w8(0, 22); b:w8(1, 0); b:w8(18, Tv.mapSec(session))
  for i = 1, 3 do b:w16(4 + i * 2, u16(history[i].itemId)); b:w16(10 + i * 2, u16(history[i].quantity)) end
  b:w8(2, discounted(session, 1) and 1 or 0); copy(b, 19, name(session)); ids(b, session, true)
  b:w8(3, 2); commit(session, slot, b)
end
local function queue(session, k)
  local shows = list(session)
  for i = 0, 4 do
    if kind(shows[i]) == k then
      if Q.activeByte(shows[i]) == 1 then Tv._result = true; return nil end
      Tv.deleteShow(shows, i); Tv.compactShows(shows); break
    end
  end
  Tv._curSlot = Tv.firstEmptyNormalSlot(shows)
  Tv._var8006 = Tv._curSlot == -1 and 65535 or Tv._curSlot
  Tv._result = Tv._curSlot == -1
  return Tv._curSlot ~= -1 and Tv._curSlot or nil
end
-- tv.c:1670
function M.interviewBefore(session, k)
  k = n(k); Tv._result = false
  if k == 4 then Tv._result = true; return true end
  if not ({[1] = true, [2] = true, [3] = true, [5] = true, [6] = true, [7] = true})[k] then return false end
  local slot = queue(session, k); if not slot then return Tv._result end
  if k == 5 then return Tv._result end
  local b = buffer(session, slot)
  local off, count = 4, 6
  if k == 3 then off, count = 28, 2 elseif k == 6 then count = 2 elseif k == 7 then off, count = 24, 1 end
  for i = 0, count - 1 do b:w16(off + i * 2, 65535) end
  commit(session, slot, b)
  if k == 1 or k == 3 then Tv._stringVar1 = Tv.speciesName(species(lead(session))) end
  if k == 3 then Tv._stringVar2 = Playback.displayBytes(session, Q.nicknameBytes(session, lead(session))) end
  return Tv._result
end
-- tv.c:957
function M.bravoTrainerPokemonProfileBeforeInterview1(session, move)
  local slot = queue(session, 6)
  if slot then
    local b = buffer(session, slot); b:w16(4, 65535); b:w16(6, 65535); commit(session, slot, b)
  end
  Tv._curSlot = Tv.firstEmptyNormalSlot(list(session))
  if Tv._curSlot ~= -1 then
    Tv.deleteShow(list(session), 24)
    local b = buffer(session, 24); b:w16(20, u16(move)); b:w8(0, 6); commit(session, 24, b)
  end
end
function M.bravoTrainerPokemonProfileBeforeInterview2(session, place, category, rank, mon)
  Tv._curSlot = Tv.firstEmptyNormalSlot(list(session)); if Tv._curSlot == -1 then return end
  local b = buffer(session, 24)
  local prior = b:str():byte(20)
  b:w8(19, prior - math.floor(prior / 32) % 4 * 32 + n(place) % 4 * 32)
  prior = b:str():byte(20); b:w8(19, prior - prior % 8 + n(category) % 8)
  prior = b:str():byte(20); b:w8(19, prior - math.floor(prior / 8) % 4 * 8 + n(rank) % 4 * 8)
  b:w16(2, species(mon)); copy(b, 8, Q.nicknameBytes(session, mon)); commit(session, 24, b)
end
-- tv.c:932
function M.interviewAfter(session, k, args)
  args = args or {}; k = n(k)
  if k == 4 or not ({[1] = true, [2] = true, [3] = true, [6] = true, [7] = true})[k] then return end
  local slot = n(Tv._curSlot); if slot < 0 or slot > 23 then return end
  local b = buffer(session, slot)
  if k == 6 and kind(list(session)[24]) ~= 6 then return end
  b:w8(0, k); b:w8(1, 1)
  if k == 1 or k == 2 then
    copy(b, 16, name(session)); b:w16(2, k == 1 and species(lead(session)) or 0)
    ids(b, session, false); b:w8(24, 2)
  elseif k == 3 then
    local mon, nick = lead(session), Q.nicknameBytes(session, lead(session))
    local friendship = n(mon and (mon.friendship or mon.happiness)) % 256
    b:w8(4, math.floor(friendship / 16) + n(args.var8007) % 16 * 16)
    copy(b, 5, name(session)); copy(b, 16, nick); b:w16(2, species(mon)); ids(b, session, false)
    b:w8(13, 2); b:w8(14, nick[1] == 252 and nick[2] == 21 and 1 or 2)
    copy(b, 16, Q.strip(bytes(b:str(), 16)))
  elseif k == 6 then
    local src = raw(session, list(session)[24]); local nick = bytes(src, 8)
    b:w16(2, src:byte(3) + src:byte(4) * 256); copy(b, 22, name(session)); copy(b, 8, nick)
    local old = b:str():byte(20); b:w8(19, math.floor(old / 128) * 128 + src:byte(20) % 128)
    b:w16(20, src:byte(21) + src:byte(22) * 256); ids(b, session, false)
    b:w8(30, 2); b:w8(31, nick[1] == 252 and nick[2] == 21 and 1 or 2)
    copy(b, 8, Q.strip(bytes(b:str(), 8)))
  elseif k == 7 then
    local t = session.battleTower or {}
    local policy = require("src.core.game3.profiles.rs.tv")
    copy(b, 2, name(session)); copy(b, 12, Q.encode(session, t.defeatedByTrainerName, 8))
    b:w16(10, n(t.firstMonSpecies)); b:w16(20, n(t.defeatedBySpecies))
    b:w16(22, policy.currentWinStreak(t, t.lastStreakLevelType)); b:w8(28, n(t.battleOutcome))
    b:w8(26, n(t.lastStreakLevelType) == 0 and 50 or 100); b:w8(27, n(args.var8004))
    ids(b, session, false); b:w8(29, 2)
  end
  commit(session, slot, b)
end
-- tv.c:631
function M.gabbyAndTyBeforeInterview(session, results)
  results = results or Tv._battleResults or {}
  local g = Tv.state(session).gabbyAndTyData
  g.mon1, g.mon2, g.lastMove = u16(results.playerMon1Species), u16(results.opponentSpecies), u16(results.lastUsedMovePlayer)
  if n(g.battleNum) ~= 255 then g.battleNum = (n(g.battleNum) + 1) % 256 end
  g.battleTookMoreThanOneTurn = on(results.playerMonWasDamaged)
  g.playerLostAMon = n(results.playerFaintCounter) ~= 0
  g.playerUsedHealingItem = n(results.numHealingItemsUsed) ~= 0
  if on(results.usedMasterBall) then g.playerThrewABall = true
  else
    for i = 1, 11 do
      if n(results.catchAttempts and results.catchAttempts[i]) ~= 0 then g.playerThrewABall = true; break end
    end
  end
  g.onAir = false
  if g.lastMove == 0 then require("src.core.game3.rse.init").setFlag("FLAG_TEMP_1", true, session) end
end
function M.gabbyAndTyAfterInterview(session)
  local g = Tv.state(session).gabbyAndTyData
  g.battleTookMoreThanOneTurn2, g.playerLostAMon2 = g.battleTookMoreThanOneTurn == true, g.playerLostAMon == true
  g.playerUsedHealingItem2, g.playerThrewABall2 = g.playerUsedHealingItem == true, g.playerThrewABall == true
  g.onAir, g.mapnum = true, Tv.mapSec(session) % 256
  session.gameStats = session.gameStats or {}; session.gameStats[6] = math.min(16777215, stat(session, 6) + 1)
end
function M.findAnyShowOnAir(session, draw)
  local slot = Q.randomActive(session, draw); if slot == 255 then return 255 end
  return Q.nonOutbreakActive(session, slot)
end
-- battle_main.c:5033
function M.onBattleEnd(session, results, outcome, kinds)
  Tv._battleResults = results or {}; kinds = kinds or {}
  for _, key in ipairs({"link", "recordedLink", "firstBattle", "safari", "ereaderTrainer", "wallyTutorial", "frontier", "battleTower"}) do
    if kinds[key] then return end
  end
  M.tryPutPokemonTodayOnAir(session, Tv._battleResults, outcome)
end
M.unsupported = {}
for _, key in ipairs({"tryPutTodaysRivalTrainerOnAir", "tryPutTrendWatcherOnAir", "tryPutTreasureInvestigatorsOnAir",
  "tryPutFindThatGamerOnAir", "tryPutBreakingNewsOnAir", "tryPutSecretBaseVisitOnAir", "tryPutLotteryWinnerReportOnAir",
  "tryPutBattleSeminarOnAir", "tryPutSafariFanClubOnAir", "tryPutSpotTheCutiesOnAir", "putSpotTheCutiesOnAir", "tryPutTrainerFanClubOnAir",
  "tryPutFrontierTVShowOnAir", "tryPutSecretBaseSecretsOnAir", "incrementDailySlotsUses", "incrementDailyRouletteUses",
  "incrementDailyWildBattles", "incrementDailyBerryBlender", "incrementDailyPlantedBerries", "incrementDailyPickedBerries",
  "incrementDailyBattlePoints", "alertPlayedSlotMachine", "alertPlayedRoulette"}) do M.unsupported[key] = true end
return M
