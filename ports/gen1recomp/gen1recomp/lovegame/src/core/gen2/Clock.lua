-- The game clock, as the cart keeps it (home/time.asm, engine/rtc/timeset.asm).
--
-- Gold does not store "the time".  It stores wStartHour / wStartMinute /
-- wStartDay -- the RTC reading at the moment the player answered Oak -- and
-- every read is CalcNSecsHoursDaysSince: the RTC now, MINUS that base, plus
-- what the player said it was.  That is why setting the clock to 10 AM does
-- not stop it: it only re-anchors the offset the RTC is read through.
--
-- The port has no battery-backed RTC to read, so `now` is the host clock and
-- the base is the host clock at the moment the player answered.  The stored
-- pair is the same pair the cart stores, so the arithmetic below IS
-- InitTime's, not a second clock: a save with no base at all reads the host
-- clock straight through, which is what every save made before this did.
--
-- Lives here rather than on World because two screens and one special write
-- it (src/ui/gen2/InitClock.lua, src/script/gen2/Specials.lua SetDayOfWeek)
-- and World only ever reads it.

local Palettes = require("src.world.gen2.Palettes")
local Runtime = require("src.mods.Runtime")
local Strings = require("src.core.Strings")

local Clock = {}

Clock.MINUTES_PER_DAY = 24 * 60
Clock.DAYS = 7

-- data/text/day_of_week.asm order, which is wCurDay's own: SUNDAY is 0, so
-- index 1 is SUNDAY -- matching both InitClock's `self.day + 1` and
-- `Clock.weekday(save) + 1`.  Strings.source, not Strings: built at require
-- time, before Strings.load has a catalog, so Clock.weekdayName looks each
-- name up at display time instead (src/battle/MoveEffects.lua's STAT_LABEL
-- is the same pattern).  One shared table and one lookup function, so
-- InitClock's screens, the main menu clock box and the Pokegear clock card
-- cannot drift apart on what a weekday is called.
Clock.DAY_NAMES = {
  Strings.source("SUNDAY"), Strings.source("MONDAY"), Strings.source("TUESDAY"),
  Strings.source("WEDNESDAY"), Strings.source("THURSDAY"), Strings.source("FRIDAY"),
  Strings.source("SATURDAY"),
}

-- The translated name for a 1-based weekday (SUNDAY = 1), or nil if `day` is
-- out of range.
function Clock.weekdayName(day)
  local name = Clock.DAY_NAMES[day]
  return name and Strings(name)
end

-- The three words Palettes.clockDaytime can hand back, translated (never
-- DARK: that one only comes out of Palettes.daytimeFor, for a PALETTE_DARK
-- map, and is never printed as text).  Strings.source, not Strings:
-- clockDaytime's return value is also an internal key every
-- FORCED_DAYTIME/palette lookup in Palettes.lua compares against, so THAT
-- stays untranslated -- only this table, and Clock.daytimeLabel below, look
-- a word up, at the UI call sites that actually print it.
local DAYTIME_LABEL = {
  MORN = Strings.source("MORN"), DAY = Strings.source("DAY"),
  NITE = Strings.source("NITE"),
}

-- clockDaytime's word, translated -- the one InitClock's clock-setting
-- screen and the Pokegear's clock card print (DisplayHourOClock /
-- Pokegear_UpdateClock).
function Clock.daytimeLabel(hour)
  local daytime = Palettes.clockDaytime(hour)
  return Strings(DAYTIME_LABEL[daytime] or daytime)
end

-- InitClock's own default: `ld a, 10 ; default hour = 10 AM`, with the minute
-- buffer left at the zero ByteFill put there.
Clock.DEFAULT_HOUR = 10
Clock.DEFAULT_MINUTE = 0

local function hostMinutes()
  local hour = tonumber(os.date("%H")) or 0
  local minute = tonumber(os.date("%M")) or 0
  return (hour * 60 + minute) % Clock.MINUTES_PER_DAY
end

local function hostWeekday()
  -- os.date("%w") is Sunday 0, and constants/misc_constants.asm's SUNDAY is 0
  -- too, so the two agree without a shift.
  return (tonumber(os.date("%w")) or 0) % Clock.DAYS
end

Clock.hostMinutes = hostMinutes
Clock.hostWeekday = hostWeekday

local function rtc(save)
  return type(save) == "table" and save.rtc or nil
end

-- clock.day_changed, a Gen 2 invention: Gen 1 has no clock at all, so there is
-- no name to share.  The cart has no "day changed" routine either -- everything
-- daily is a countdown compared against wCurDay when it is next read -- so the
-- event is raised off the read that IS GetWeekday: every consumer of the day
-- (VAR_WEEKDAY, the world.tod ctx, the Pokegear clock card, the daily resets)
-- goes through Clock.weekday, so a rollover cannot get past this.
--
--   day       the weekday now, SUNDAY 0 .. SATURDAY 6
--   previous  the weekday the last read answered
--   reason    "rollover" for the host clock crossing midnight, "set" for
--             Mom's wheel re-anchoring the day (src/ui/gen2/InitClock.lua)
--
-- The last-seen day is process-local rather than saved: the first read after a
-- boot has nothing to compare against and reports nothing, which is why a
-- Gold boot does not open with a spurious day change.  It is only maintained
-- while somebody is subscribed, which is what keeps a mod-free boot free.
local lastDay = nil

local function noteDay(day, reason)
  if not Runtime.wants("clock.day_changed") then
    lastDay = nil
    return day
  end
  local previous = lastDay
  lastDay = day
  if previous ~= nil and previous ~= day then
    Runtime.emit("clock.day_changed",
      { day = day, previous = previous, reason = reason })
  end
  return day
end

-- _InitTime: store the base so that reading it back answers `hour:minute`.
function Clock.setTime(save, hour, minute)
  if type(save) ~= "table" then return false end
  save.rtc = save.rtc or {}
  local wanted = (math.floor(hour or 0) % 24) * 60
    + (math.floor(minute or 0) % 60)
  save.rtc.startMinute = (wanted - hostMinutes()) % Clock.MINUTES_PER_DAY
  return true
end

-- InitDayOfWeek, which is the same anchor for wCurDay.
function Clock.setWeekday(save, day)
  if type(save) ~= "table" then return false end
  save.rtc = save.rtc or {}
  save.rtc.startDay = (math.floor(day or 0) - hostWeekday()) % Clock.DAYS
  save.rtc.dayOfWeek = math.floor(day or 0) % Clock.DAYS
  noteDay(save.rtc.dayOfWeek, "set")
  return true
end

-- The clock the game reads: the host clock through the stored offset.
function Clock.minutes(save)
  local r = rtc(save)
  local offset = r and tonumber(r.startMinute) or 0
  return (hostMinutes() + offset) % Clock.MINUTES_PER_DAY
end

function Clock.hour(save)
  return math.floor(Clock.minutes(save) / 60)
end

function Clock.minute(save)
  return Clock.minutes(save) % 60
end

-- GetWeekday, and the poll site clock.day_changed is raised from (see noteDay).
function Clock.weekday(save)
  local r = rtc(save)
  local offset = r and tonumber(r.startDay) or 0
  return noteDay((hostWeekday() + offset) % Clock.DAYS, "rollover")
end

-- True once the player has actually answered Oak, so a caller can tell "10 AM
-- because that is what the host says" from "10 AM because the player set it".
function Clock.isSet(save)
  local r = rtc(save)
  return r ~= nil and r.startMinute ~= nil
end

return Clock
