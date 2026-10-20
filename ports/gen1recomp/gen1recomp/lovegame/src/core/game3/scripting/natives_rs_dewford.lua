local R = require("src.core.game3.rse.init")
local Trend = require("src.core.game3.rs.dewford_trend")
local M = {BY_NAME = {}}
local RESULT, INPUT = 0x800D, 0x8004

local function text(ctx, adapters, index, value)
  if adapters and adapters.setStringVar then adapters.setStringVar(index, value) end
  if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[index] = value end
end
local function result(ctx, value)
  R.setSpecialVar(ctx, RESULT, value)
  return false, value
end

M.BY_NAME.BufferTrendyPhraseString = function(ctx, adapters)
  text(ctx, adapters, 1, Trend.phraseString(R.specialVar(ctx, INPUT), R.session()))
  return false
end
M.BY_NAME.IsTrendyPhraseBoring = function(ctx)
  return result(ctx, Trend.isBoring(R.session()) and 1 or 0)
end
M.BY_NAME.GetDewfordHallPaintingNameIndex = function(ctx)
  return result(ctx, Trend.paintingNameIndex(R.session()))
end
M.BY_NAME.BufferRandomHobbyOrLifestyleString = function(ctx, adapters)
  text(ctx, adapters, 2, Trend.randomHobbyOrLifestyleString())
  return false
end

function M.commitTrendyPhrase(ctx, adapters, before, words, session)
  local valid, reason = Trend.editorValid(before, words)
  if not valid then return false, reason end
  R.setSpecialVar(ctx, RESULT, 1)
  local Town = require("src.core.game3.rse.town_common")
  text(ctx, adapters, 2, Town.word(words[1]) .. " " .. Town.word(words[2]))
  local accepted = Trend.trySetTrendyPhrase({words[1], words[2]}, session or R.session())
  R.setSpecialVar(ctx, INPUT, accepted and 1 or 0)
  return true
end
function M.showTrendyPhrase(ctx, adapters)
  local session = R.session()
  local before = Trend.editorWords(session)
  if not (adapters and adapters.openTrendyPhrase) then
    R.missing("easyChat", "native RS type9 openTrendyPhrase host", adapters and adapters.log)
    return result(ctx, 0)
  end
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    local committed = false
    adapters.openTrendyPhrase({type = Trend.TYPE, wordCount = 2, columns = 2, rows = 1,
      words = before, session = session,
      validate = function(words) return Trend.editorValid(before, words) end,
      commit = function(words)
        committed = M.commitTrendyPhrase(ctx, adapters, before, words, session) == true
        return committed
      end,
      cancel = function() R.setSpecialVar(ctx, RESULT, 0) end}, function(confirmed, words)
      if not confirmed or (not committed and not M.commitTrendyPhrase(ctx, adapters, before, words, session)) then
        R.setSpecialVar(ctx, RESULT, 0)
      end
      done()
    end)
  end)
end

M.BY_NAME.ShowEasyChatScreen = function(ctx, adapters)
  if R.specialVar(ctx, INPUT) == Trend.TYPE then return M.showTrendyPhrase(ctx, adapters) end
  return require("src.core.game3.scripting.natives").CORE.ShowEasyChatScreen(ctx, adapters)
end

return M
