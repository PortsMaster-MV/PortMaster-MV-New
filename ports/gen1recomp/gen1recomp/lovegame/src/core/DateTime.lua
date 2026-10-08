-- Shared local date/time presentation for engine UI and mods. Preferences
-- live in options.lua, never checkpoint progress. "device" uses the process
-- time locale when the platform supplies one and otherwise falls back to the
-- deterministic DD-MM-YYYY / 24-hour convention.

local DateTime = {}

local DATE_FORMATS = {
  dmy = "%d-%m-%Y",
  mdy = "%m-%d-%Y",
  ymd = "%Y-%m-%d",
}
local TIME_FORMATS = {
  ["24h"] = "%H:%M",
  ["12h"] = "%I:%M %p",
}

local function validTimestamp(value)
  return type(value) == "number" and value == value and value >= 0
    and value ~= math.huge and value ~= -math.huge
end

local function render(timestamp, pattern)
  local ok, value = pcall(os.date, pattern, math.floor(timestamp))
  if not ok or type(value) ~= "string" or value == "" then return nil end
  return value
end

local function currentLocale()
  if not os.setlocale then return nil end
  local ok, value = pcall(os.setlocale, nil, "time")
  if not ok or type(value) ~= "string" then return nil end
  return value
end

local function deviceAvailable(localeName)
  return type(localeName) == "string" and localeName ~= ""
    and localeName ~= "C" and localeName ~= "POSIX"
end

function DateTime.formatWithLocale(timestamp, datePreference, timePreference, localeName)
  if not validTimestamp(timestamp) then return { date = "----", time = "----" } end
  local datePattern = DATE_FORMATS[datePreference]
  local timePattern = TIME_FORMATS[timePreference]
  if not datePattern then
    datePattern = deviceAvailable(localeName) and "%x" or DATE_FORMATS.dmy
  end
  if not timePattern then
    if deviceAvailable(localeName) then
      local sample = render(timestamp, "%X") or ""
      local marker = render(timestamp, "%p") or ""
      timePattern = marker ~= "" and sample:find(marker, 1, true)
        and TIME_FORMATS["12h"] or TIME_FORMATS["24h"]
    else
      timePattern = TIME_FORMATS["24h"]
    end
  end
  return {
    date = render(timestamp, datePattern) or "----",
    time = render(timestamp, timePattern) or "----",
  }
end

local function preferences(game)
  local options = game and game.save and game.save.options
  options = type(options) == "table" and options or {}
  return options.dateFormat or "device", options.timeFormat or "device"
end

function DateTime.date(game, timestamp)
  local datePreference, timePreference = preferences(game)
  return DateTime.formatWithLocale(timestamp, datePreference, timePreference,
    currentLocale()).date
end

function DateTime.time(game, timestamp)
  local datePreference, timePreference = preferences(game)
  return DateTime.formatWithLocale(timestamp, datePreference, timePreference,
    currentLocale()).time
end

function DateTime.dateTime(game, timestamp)
  local datePreference, timePreference = preferences(game)
  local value = DateTime.formatWithLocale(timestamp, datePreference, timePreference,
    currentLocale())
  if value.date == "----" or value.time == "----" then return "----" end
  return value.date .. " " .. value.time
end

return DateTime
