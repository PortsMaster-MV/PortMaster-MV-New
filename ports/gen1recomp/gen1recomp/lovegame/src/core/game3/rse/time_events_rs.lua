local Constants = require("src.core.game3.constants")
local Flags = require("src.core.game3.scripting.flags")
local Rng = require("src.core.game3.rng")

local Rs = { perDay = {} }
local function C(sess) return Constants.active(sess) end
local function get(sess, store, name) return tonumber(Flags.getVar(store, nil, C(sess):require("vars", name))) or 0 end
local function set(sess, store, name, value) Flags.setVar(store, nil, C(sess):require("vars", name), value) end
local function flag(sess, store, name, value) Flags.setFlag(store, nil, C(sess):require("flags", name), value) end
local function num(value) return tonumber(value) or 0 end

-- pokeruby/src/event_data.c:46
Rs.perDay.ClearDailyFlags = function(sess, _days, _time, store)
  local lo = C(sess):require("flags", "DAILY_FLAGS_START")
  for id = lo, lo + 63 do Flags.setFlag(store, nil, id, false) end
end
-- pokeruby/src/dewford_trend.c:40
Rs.perDay.UpdateDewfordTrendPerDay = function(sess, days)
  require("src.core.game3.rse.dewford_trend").updatePerDay(days, sess)
end
-- pokeruby/src/field_weather_effects.c:2379
Rs.perDay.UpdateWeatherPerDay = function(sess, days)
  sess.weatherCycleStage = ((num(sess.weatherCycleStage) + days) % 65536) % 4
end
-- pokeruby/src/time_events.c:31
Rs.perDay.UpdateMirageRnd = function(sess, days, _time, store)
  local rnd = get(sess, store, "VAR_MIRAGE_RND_H") * 65536 + get(sess, store, "VAR_MIRAGE_RND_L")
  for _ = 1, days do rnd = (Rng.mulU32(rnd, 1103515245) + 12345) % 4294967296 end
  set(sess, store, "VAR_MIRAGE_RND_H", math.floor(rnd / 65536))
  set(sess, store, "VAR_MIRAGE_RND_L", rnd % 65536)
end
-- pokeruby/src/time_events.c:113
Rs.perDay.UpdateBirchState = function(sess, days, _time, store)
  set(sess, store, "VAR_BIRCH_STATE", ((get(sess, store, "VAR_BIRCH_STATE") + days) % 65536) % 7)
end
-- pokeruby/src/field_specials.c:1733
Rs.perDay.SetShoalItemFlag = function(sess, _days, _time, store)
  flag(sess, store, "FLAG_SYS_SHOAL_ITEM", true)
end
-- pokeruby/src/lottery_corner.c:36
Rs.perDay.SetRandomLotteryNumber = function(sess, days, _time, store)
  local rnd = Rng.Random()
  for _ = 1, days do rnd = (Rng.mulU32(rnd, 1103515245) + 12345) % 4294967296 end
  set(sess, store, "VAR_LOTTERY_RND_L", rnd % 65536)
  set(sess, store, "VAR_LOTTERY_RND_H", math.floor(rnd / 65536))
end

-- pokeruby/src/tv.c:1194
Rs.perDay.UpdateTVShowsPerDay = function(sess, days)
  return require("src.core.game3.rse.tv").updatePerDay(sess, days)
end

return Rs
