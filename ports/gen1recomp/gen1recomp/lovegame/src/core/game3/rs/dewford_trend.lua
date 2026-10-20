local bit = require("bit")
local R = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local Easy = require("src.core.game3.easy_chat_text")
local M = { TYPE = 9, EMPTY = 0xFFFF, COUNT = 5 }

function M.trends(session)
  return require("src.core.game3.rse.dewford_trend").trends(session)
end

function M.phraseString(index, session)
  local words = assert(M.trends(session)[index + 1], "native RS trend index out of range").words
  return Town.word(words[1]) .. (words[1] ~= M.EMPTY and " " or "") .. Town.word(words[2])
end

function M.isBoring(session)
  local t = M.trends(session)
  return t[1].trendiness - t[2].trendiness <= 1
    and not t[1].gainingTrendiness and t[2].gainingTrendiness == true
end

function M.paintingNameIndex(session)
  local words = M.trends(session)[1].words
  return bit.band(words[1] + words[2], 7)
end

function M.compare(a, b)
  if a.trendiness ~= b.trendiness then return a.trendiness > b.trendiness end
  if a.maxTrendiness ~= b.maxTrendiness then return a.maxTrendiness > b.maxTrendiness end
  return bit.band(Town.random(), 1) ~= 0
end

function M.seed(trend)
  local value = Town.random() % 98
  if value > 50 then
    value = Town.random() % 98
    if value > 80 then value = Town.random() % 98 end
  end
  trend.maxTrendiness = value + 30
  trend.trendiness = Town.random() % (value + 1) + 30
  trend.rand = Town.random()
end

function M.trySetTrendyPhrase(phrase, session)
  session = Town.session(session)
  local trends = M.trends(session)
  for i = 1, M.COUNT do
    local words = trends[i].words
    if words[1] == phrase[1] and words[2] == phrase[2] then return false end
  end
  if not R.flag("FLAG_SYS_POPWORD_INPUT", session) then
    R.setFlag("FLAG_SYS_POPWORD_INPUT", true, session)
    if not R.flag("FLAG_SYS_MIX_RECORD", session) then
      trends[1].words[1], trends[1].words[2] = phrase[1], phrase[2]
      return true
    end
  end
  local trend = {trendiness = 0, maxTrendiness = 0, gainingTrendiness = true,
    rand = 0, words = {phrase[1], phrase[2]}}
  M.seed(trend)
  for i = 1, M.COUNT do
    if M.compare(trend, trends[i]) then
      for j = M.COUNT, i + 1, -1 do trends[j] = trends[j - 1] end
      trends[i] = trend
      return i == 1
    end
  end
  trends[M.COUNT] = trend
  return false
end

function M.randomHobbyOrLifestyleString()
  local group = bit.band(Town.random(), 1) ~= 0 and Town.EC_GROUP.HOBBIES or Town.EC_GROUP.LIFESTYLE
  return Town.word(Town.randomWordFromGroup(group))
end

function M.editorWords(session)
  local words = M.trends(session)[1].words
  return {words[1], words[2]}
end
function M.editorChanged(before, after)
  return Easy.rawWord(before[1]) ~= Easy.rawWord(after[1])
    or Easy.rawWord(before[2]) ~= Easy.rawWord(after[2])
end
function M.editorValid(before, after)
  if not after or after[1] == nil or after[2] == nil then return false, "incomplete" end
  if after[1] == M.EMPTY and after[2] == M.EMPTY then return false, "empty" end
  if not M.editorChanged(before, after) then return false, "unchanged" end
  if after[1] == M.EMPTY or after[2] == M.EMPTY then return false, "incomplete" end
  return true
end

return M
