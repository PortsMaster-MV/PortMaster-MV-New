local Rse = require("src.core.game3.rse.init")

local Daily = {}

-- pokeemerald/include/constants/battle_frontier.h:82
Daily.FRONTIER_MANIAC_FACILITY_COUNT = 10
-- pokeemerald/include/constants/battle_frontier.h:112
Daily.FRONTIER_GAMBLER_CHALLENGE_COUNT = 12

local function rse(sess)
  local ok, Profile = pcall(require, "src.core.game3.profile")
  if not ok then return false end
  local okF, family = pcall(Profile.family, sess)
  return okF and family == "rse"
end

local function advance(var, days, count, sess)
  local v = Rse.var(var, sess)
  Rse.setVar(var, ((v + (tonumber(days) or 0)) % 0x10000) % count, sess)
end

-- pokeemerald/src/field_specials.c:2053
function Daily.updateFrontierManiac(days, sess)
  advance("VAR_FRONTIER_MANIAC_FACILITY", days, Daily.FRONTIER_MANIAC_FACILITY_COUNT, sess)
end

-- pokeemerald/src/field_specials.c:2817
function Daily.updateFrontierGambler(days, sess)
  advance("VAR_FRONTIER_GAMBLER_CHALLENGE", days, Daily.FRONTIER_GAMBLER_CHALLENGE_COUNT, sess)
end

function Daily.install()
  local TimeEvents = require("src.core.game3.time_events")
  local perDay = TimeEvents.handlers()
  if perDay.UpdateFrontierManiac == nil then
    -- pokeemerald/src/clock.c:51
    TimeEvents.onDay("UpdateFrontierManiac", function(sess, days)
      if rse(sess) then Daily.updateFrontierManiac(days, sess) end
    end)
  end
  if perDay.UpdateFrontierGambler == nil then
    -- pokeemerald/src/clock.c:52
    TimeEvents.onDay("UpdateFrontierGambler", function(sess, days)
      if rse(sess) then Daily.updateFrontierGambler(days, sess) end
    end)
  end
  require("src.core.game3.rse.dewford_trend")
  require("src.core.game3.rse.lottery")
end

Daily.install()

return Daily
