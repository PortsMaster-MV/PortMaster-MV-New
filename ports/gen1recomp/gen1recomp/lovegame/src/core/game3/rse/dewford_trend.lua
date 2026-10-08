local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")

local bit = require("bit")

local Dewford = {}

-- pokeemerald/include/global.h:641
Dewford.SAVED_TRENDS_COUNT = 5
-- pokeemerald/src/dewford_trend.c:58
Dewford.SORT_MODE_NORMAL = 0
Dewford.SORT_MODE_MAX_FIRST = 1
Dewford.SORT_MODE_FULL = 2

local function u16(v) return bit.band(v, 0xFFFF) end
local function u7(v) return bit.band(v, 0x7F) end

function Dewford.newTrend()
  return { trendiness = 0, maxTrendiness = 0, gainingTrendiness = false, rand = 0, words = { 0, 0 } }
end

local function copyTrend(t)
  return {
    trendiness = t.trendiness, maxTrendiness = t.maxTrendiness, gainingTrendiness = t.gainingTrendiness,
    rand = t.rand, words = { t.words[1], t.words[2] },
  }
end
Dewford.copyTrend = copyTrend

-- pokeemerald/src/dewford_trend.c:369
local function seedTrendRng(trend)
  local rand = Town.random() % 98
  if rand > 50 then
    rand = Town.random() % 98
    if rand > 80 then rand = Town.random() % 98 end
  end
  trend.maxTrendiness = u7(rand + 30)
  trend.trendiness = u7((Town.random() % (rand + 1)) + 30)
  trend.rand = Town.random()
end
Dewford.seedTrendRng = seedTrendRng

-- pokeemerald/src/dewford_trend.c:328
function Dewford.compare(a, b, mode)
  if mode == Dewford.SORT_MODE_NORMAL then
    if a.trendiness > b.trendiness then return true end
    if a.trendiness < b.trendiness then return false end
    if a.maxTrendiness > b.maxTrendiness then return true end
    if a.maxTrendiness < b.maxTrendiness then return false end
  elseif mode == Dewford.SORT_MODE_MAX_FIRST then
    if a.maxTrendiness > b.maxTrendiness then return true end
    if a.maxTrendiness < b.maxTrendiness then return false end
    if a.trendiness > b.trendiness then return true end
    if a.trendiness < b.trendiness then return false end
  elseif mode == Dewford.SORT_MODE_FULL then
    if a.trendiness > b.trendiness then return true end
    if a.trendiness < b.trendiness then return false end
    if a.maxTrendiness > b.maxTrendiness then return true end
    if a.maxTrendiness < b.maxTrendiness then return false end
    if a.rand > b.rand then return true end
    if a.rand < b.rand then return false end
    if a.words[1] > b.words[1] then return true end
    if a.words[1] < b.words[1] then return false end
    if a.words[2] > b.words[2] then return true end
    if a.words[2] < b.words[2] then return false end
    return true
  end
  return bit.band(Town.random(), 1) == 1
end

-- pokeemerald/src/dewford_trend.c:209
function Dewford.sort(trends, n, mode)
  for i = 1, n do
    for j = i + 1, n do
      if Dewford.compare(trends[j], trends[i], mode) then
        trends[i], trends[j] = trends[j], trends[i]
      end
    end
  end
end

function Dewford.trends(sess)
  sess = Town.session(sess)
  if not sess then return nil end
  if type(sess.dewfordTrends) ~= "table" or #sess.dewfordTrends ~= Dewford.SAVED_TRENDS_COUNT then
    Dewford.init(sess)
  end
  return sess.dewfordTrends
end

-- pokeemerald/src/dewford_trend.c:71
function Dewford.init(sess)
  sess = Town.session(sess)
  local G = Town.EC_GROUP
  local trends = {}
  for i = 1, Dewford.SAVED_TRENDS_COUNT do
    local t = Dewford.newTrend()
    t.words[1] = Town.randomWordFromGroup(G.CONDITIONS)
    if bit.band(Town.random(), 1) == 1 then
      t.words[2] = Town.randomWordFromGroup(G.LIFESTYLE)
    else
      t.words[2] = Town.randomWordFromGroup(G.HOBBIES)
    end
    t.gainingTrendiness = bit.band(Town.random(), 1) == 1
    seedTrendRng(t)
    trends[i] = t
  end
  Dewford.sort(trends, Dewford.SAVED_TRENDS_COUNT, Dewford.SORT_MODE_NORMAL)
  if sess then sess.dewfordTrends = trends end
  return trends
end

-- pokeemerald/src/dewford_trend.c:90
function Dewford.updatePerDay(days, sess)
  days = u16(tonumber(days) or 0)
  if days == 0 then return end
  local trends = Dewford.trends(sess)
  if not trends then return end
  local clockRand = days * 5
  for i = 1, Dewford.SAVED_TRENDS_COUNT do
    local trend = trends[i]
    local rand = clockRand
    local skip = false
    if not trend.gainingTrendiness then
      if trend.trendiness >= u16(rand) then
        trend.trendiness = u7(trend.trendiness - rand)
        if trend.trendiness == 0 then trend.gainingTrendiness = true end
        skip = true
      else
        rand = rand - trend.trendiness
        trend.trendiness = 0
        trend.gainingTrendiness = true
      end
    end
    if not skip then
      local trendiness = trend.trendiness + rand
      if u16(trendiness) > trend.maxTrendiness then
        local newTrendiness = trendiness % trend.maxTrendiness
        trendiness = math.floor(trendiness / trend.maxTrendiness)
        trend.gainingTrendiness = bit.band(bit.bxor(trendiness, 1), 1) == 1
        if trend.gainingTrendiness then
          trend.trendiness = u7(newTrendiness)
        else
          trend.trendiness = u7(trend.maxTrendiness - newTrendiness)
        end
      else
        trend.trendiness = u7(trendiness)
        if trend.trendiness == trend.maxTrendiness then trend.gainingTrendiness = false end
      end
    end
  end
  Dewford.sort(trends, Dewford.SAVED_TRENDS_COUNT, Dewford.SORT_MODE_NORMAL)
end

local function pairEqual(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

-- pokeemerald/src/dewford_trend.c:385
function Dewford.isPhraseSaved(phrase, sess)
  for _, t in ipairs(Dewford.trends(sess)) do
    if pairEqual(phrase, t.words) then return true end
  end
  return false
end

local function trendWatcher(phrase)
  Rse.call("tv", "tryPutTrendWatcherOnAir", "TryPutTrendWatcherOnAir", nil, { phrase[1], phrase[2] })
end

-- pokeemerald/src/dewford_trend.c:151
function Dewford.trySetTrendyPhrase(phrase, sess)
  sess = Town.session(sess)
  local trends = Dewford.trends(sess)
  if Dewford.isPhraseSaved(phrase, sess) then return false end
  if not Rse.flag("FLAG_SYS_CHANGED_DEWFORD_TREND", sess) then
    Rse.setFlag("FLAG_SYS_CHANGED_DEWFORD_TREND", true, sess)
    if not Rse.flag("FLAG_SYS_MIX_RECORD", sess) then
      trends[1].words[1] = phrase[1]
      trends[1].words[2] = phrase[2]
      return true
    end
  end
  local trend = Dewford.newTrend()
  trend.words[1], trend.words[2] = phrase[1], phrase[2]
  trend.gainingTrendiness = true
  seedTrendRng(trend)
  local n = Dewford.SAVED_TRENDS_COUNT
  for i = 1, n do
    if Dewford.compare(trend, trends[i], Dewford.SORT_MODE_NORMAL) then
      for j = n, i + 1, -1 do trends[j] = trends[j - 1] end
      trends[i] = trend
      if i == n then trendWatcher(phrase) end
      return i == 1
    end
  end
  trends[n] = trend
  trendWatcher(phrase)
  return false
end

-- pokeemerald/src/dewford_trend.c:298
function Dewford.isBoring(sess)
  local t = Dewford.trends(sess)
  if t[1].trendiness - t[2].trendiness > 1 then return false end
  if t[1].gainingTrendiness then return false end
  if not t[2].gainingTrendiness then return false end
  return true
end

-- pokeemerald/src/dewford_trend.c:320
function Dewford.paintingNameIndex(sess)
  local t = Dewford.trends(sess)[1]
  return bit.band(t.words[1] + t.words[2], 7)
end

-- pokeemerald/src/dewford_trend.c:290
function Dewford.phraseString(index, sess)
  local t = Dewford.trends(sess)[(tonumber(index) or 0) + 1]
  return Town.words(t and t.words or {}, 2, 1)
end

function Dewford.mixExport(sess)
  local out = {}
  for i, t in ipairs(Dewford.trends(sess)) do out[i] = copyTrend(t) end
  return out
end

local function savedIndex(saved, trend, n)
  for i = 1, n do
    if pairEqual(trend.words, saved[i].words) then return i end
  end
  return nil
end

-- pokeemerald/src/dewford_trend.c:229
function Dewford.mixImport(players, sess)
  sess = Town.session(sess)
  local saved, n = {}, 0
  for _, list in ipairs(players or {}) do
    for j = 1, Dewford.SAVED_TRENDS_COUNT do
      local src = list[j]
      if src then
        local idx = savedIndex(saved, src, n)
        if not idx then
          n = n + 1
          saved[n] = copyTrend(src)
        elseif saved[idx].trendiness < src.trendiness then
          saved[idx] = copyTrend(src)
        end
      end
    end
  end
  Dewford.sort(saved, n, Dewford.SORT_MODE_FULL)
  local out = {}
  for i = 1, Dewford.SAVED_TRENDS_COUNT do out[i] = saved[i] or Dewford.newTrend() end
  sess.dewfordTrends = out
  return out
end

function Dewford.installTimeHooks()
  local TimeEvents = require("src.core.game3.time_events")
  -- pokeemerald/src/clock.c:45
  TimeEvents.onDay("UpdateDewfordTrendPerDay", function(sess, daysSince)
    if require("src.core.game3.capabilities").gate(sess, "dewford_trend") then
      Dewford.updatePerDay(daysSince, sess)
    end
  end)
end

local SaveSections = require("src.core.game3.save_sections")
-- pokeemerald/include/global.h:1057
SaveSections.register("dewfordTrends", SaveSections.fields({ "dewfordTrends", "unlockedTrendySayings" }, function(sess)
  Dewford.init(sess)
end))

Dewford.installTimeHooks()
Rse.register("dewfordTrend", Dewford)

return Dewford
