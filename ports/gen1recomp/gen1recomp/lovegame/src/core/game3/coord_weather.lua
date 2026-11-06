-- pokeemerald/src/coord_event_weather.c

local Weather = require("src.core.game3.weather")

local CoordWeather = {}

-- pokeemerald/include/constants/weather.h:26
CoordWeather.BY_TRIGGER = {
  [1] = Weather.SUNNY_CLOUDS,
  [2] = Weather.SUNNY,
  [3] = Weather.RAIN,
  [4] = Weather.SNOW,
  [5] = Weather.RAIN_THUNDERSTORM,
  [6] = Weather.FOG_HORIZONTAL,
  [7] = Weather.FOG_DIAGONAL,
  [8] = Weather.VOLCANIC_ASH,
  [9] = Weather.SANDSTORM,
  [10] = Weather.SHADE,
  [11] = Weather.DROUGHT,
  [20] = Weather.ROUTE119_CYCLE,
  [21] = Weather.ROUTE123_CYCLE,
}

-- pokeemerald/asm/macros/map.inc:84
function CoordWeather.isWeatherEvent(ev)
  return type(ev) == "table" and ev.scriptKey == nil and (tonumber(ev.scriptPtr) or 0) == 0
end

-- pokeemerald/src/coord_event_weather.c:108
function CoordWeather.run(trigger)
  local w = CoordWeather.BY_TRIGGER[tonumber(trigger) or -1]
  if w == nil then return false end
  Weather.setWeather(w)
  return true
end

return CoordWeather
