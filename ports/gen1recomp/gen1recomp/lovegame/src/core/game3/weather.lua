-- Field weather session state (H5). Ops setweather / doweather / resetweather.
-- pokefirered/include/constants/weather.h
-- pokefirered/src/field_weather.c

local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local Weather = {}

Weather.NONE = 0
Weather.SUNNY_CLOUDS = 1
Weather.SUNNY = 2
Weather.RAIN = 3
Weather.SNOW = 4
Weather.RAIN_THUNDERSTORM = 5
Weather.FOG_HORIZONTAL = 6
Weather.VOLCANIC_ASH = 7
Weather.SANDSTORM = 8
Weather.FOG_DIAGONAL = 9
Weather.UNDERWATER = 10
Weather.SHADE = 11
Weather.DROUGHT = 12
Weather.DOWNPOUR = 13
Weather.UNDERWATER_BUBBLES = 14
Weather.ABNORMAL = 15
-- pokeemerald/include/constants/weather.h:20
Weather.ROUTE119_CYCLE = 20
Weather.ROUTE123_CYCLE = 21

-- Aliases
Weather.FOG = Weather.FOG_HORIZONTAL
Weather.ASH = Weather.VOLCANIC_ASH

Weather.current = Weather.NONE
Weather._pending = nil
Weather._active = false
Weather._suspended = false

-- pokeemerald/src/field_weather_effect.c:2579
Weather.CYCLE_LENGTH = 4

local function rseEngine()
  local ok, Profile = pcall(lazyReq, "src.core.game3.profile")
  if not ok then return nil end
  local okRow, row = pcall(Profile.forSession, nil)
  if not okRow or type(row) ~= "table" or row.family ~= "rse" then return nil end
  return lazyReq("src.core.game3.field_weather_rse")
end
Weather.rseEngine = rseEngine

local function weatherPolicy(sess)
  local Profile = lazyReq("src.core.game3.profile")
  local row = Profile.forSession(sess)
  return type(row) == "table" and type(row.weather) == "table" and row.weather or nil
end

local function session()
  local Runtime = package.loaded["src.core.game3.runtime"]
  return Runtime and Runtime.getSession and Runtime.getSession() or nil
end

local function syncActive(id)
  Weather.current = tonumber(id) or Weather.NONE
  Weather._active = Weather.current ~= Weather.NONE and Weather.current ~= Weather.SUNNY
end

local cycleCache = nil

-- pokeemerald/src/field_weather_effect.c:2581
function Weather.cycles()
  if cycleCache then return cycleCache end
  local okD, Dataset = pcall(lazyReq, "src.core.game3.dataset")
  local cache = okD and Dataset.cache and Dataset.cache()
  local body = cache and cache.read and cache:read("data/generated/gba/weather/manifest.lua")
  local chunk = body and load(body, "=weather_manifest", "t", {})
  local ok, m = false, nil
  if chunk then ok, m = pcall(chunk) end
  if not (ok and type(m) == "table" and type(m.cycles) == "table") then
    error("weather manifest has no cycles table (reimport the Emerald cache)", 0)
  end
  cycleCache = m.cycles
  return cycleCache
end

function Weather.invalidate()
  cycleCache = nil
end

-- pokeemerald/src/field_weather_effect.c:2596
function Weather.translate(weather, sess)
  weather = tonumber(weather) or Weather.NONE
  local policy = weatherPolicy(sess)
  -- pokeruby/src/field_weather_effects.c:2354
  if policy and policy.translateByte then weather = math.floor(weather) % 256 end
  local directMax = policy and policy.directWeatherMax or Weather.ABNORMAL
  if weather >= Weather.NONE and weather <= directMax then return weather end
  local stage = (tonumber((sess or session() or {}).weatherCycleStage) or 0) % Weather.CYCLE_LENGTH
  if weather == Weather.ROUTE119_CYCLE then return Weather.cycles().route119[stage + 1] end
  if weather == Weather.ROUTE123_CYCLE then return Weather.cycles().route123[stage + 1] end
  return Weather.NONE
end

-- pokeemerald/src/field_weather_effect.c:2629
local function updateRainCounter(newWeather, oldWeather, sess)
  if newWeather ~= oldWeather and (newWeather == Weather.RAIN or newWeather == Weather.RAIN_THUNDERSTORM) then
    if type(sess) == "table" then
      if type(sess.gameStats) ~= "table" then sess.gameStats = {} end
      -- pokeemerald/include/constants/game_stat.h:44
      local id = 40
      sess.gameStats[id] = math.min(0xFFFFFF, math.floor(tonumber(sess.gameStats[id]) or 0) + 1)
    end
  end
end

-- pokeemerald/src/field_weather_effect.c:2510
function Weather.setSaved(weather, sess)
  sess = sess or session() or {}
  local old = tonumber(sess.savedWeather) or Weather.NONE
  sess.savedWeather = Weather.translate(weather, sess)
  updateRainCounter(sess.savedWeather, old, sess)
  return sess.savedWeather
end

-- pokeemerald/src/field_weather_effect.c:2517
function Weather.getSaved(sess)
  sess = sess or session() or {}
  return tonumber(sess.savedWeather) or Weather.NONE
end

-- pokeemerald/src/field_weather_effect.c:2522
function Weather.setSavedFromHeader(headerWeather, sess)
  return Weather.setSaved(headerWeather, sess)
end

-- pokeemerald/src/field_weather_effect.c:2529
function Weather.setWeather(weather, sess)
  Weather.setSaved(weather, sess)
  local E = rseEngine()
  if E then
    E.setNextWeather(Weather.getSaved(sess))
    syncActive(E.getCurrentWeather())
  end
end

local function abnormalTarget(E, resume)
  local w = Weather.getSaved()
  local policy = weatherPolicy()
  -- pokeruby/src/field_weather_effects.c:2329
  if w == Weather.ABNORMAL and not (policy and policy.abnormal == false) then
    w = E.startAbnormal()
  else
    E.stopAbnormal()
  end
  if resume then E.setCurrentAndNextWeather(w) else E.setNextWeather(w) end
  return w
end

-- pokeemerald/src/field_weather_effect.c:2541
function Weather.doCurrent()
  local E = rseEngine()
  if not E then return end
  abnormalTarget(E, false)
  syncActive(E.getCurrentWeather())
end

-- pokeemerald/src/field_weather_effect.c:2560
function Weather.resumePaused()
  local E = rseEngine()
  if not E then return end
  abnormalTarget(E, true)
  E.readyForInit()
  syncActive(E.getCurrentWeather())
end

-- pokeemerald/src/field_weather_effect.c:2622
function Weather.updatePerDay(increment, sess)
  sess = sess or session()
  if type(sess) ~= "table" then return end
  local stage = (tonumber(sess.weatherCycleStage) or 0) + (tonumber(increment) or 0)
  sess.weatherCycleStage = stage % Weather.CYCLE_LENGTH
end

function Weather.installRseHooks()
  local TimeEvents = lazyReq("src.core.game3.time_events")
  local perDay = TimeEvents.handlers()
  if perDay.UpdateWeatherPerDay == nil then
    -- pokeemerald/src/clock.c:47
    TimeEvents.onDay("UpdateWeatherPerDay", function(sess, daysSince)
      Weather.updatePerDay(daysSince, sess)
    end)
  end
end

do
  local SaveSections = lazyReq("src.core.game3.save_sections")
  -- pokeemerald/include/global.h:994
  SaveSections.register("weather", SaveSections.fields({ "savedWeather", "weatherCycleStage" }, function(sess)
    sess.savedWeather = Weather.NONE
    sess.weatherCycleStage = 0
  end))
end

Weather._applySeq = 0
Weather._scriptSaved = nil

local function currentMapId()
  local Map = package.loaded["src.core.game3.map"]
  return Map and Map.current or nil
end

function Weather.set(id)
  if rseEngine() then
    -- pokeemerald/src/scrcmd.c:706
    Weather.setSaved(id)
    Weather._scriptSaved = { map = currentMapId(), seq = Weather._applySeq }
    return
  end
  Weather._pending = tonumber(id) or Weather.NONE
end

function Weather.doWeather()
  if rseEngine() then
    -- pokeemerald/src/scrcmd.c:720
    Weather.doCurrent()
    return
  end
  Weather.current = Weather._pending or Weather.current
  Weather._active = Weather.current ~= Weather.NONE and Weather.current ~= Weather.SUNNY
  Weather.apply(Weather.current)
end

function Weather.reset()
  if rseEngine() then
    -- pokeemerald/src/scrcmd.c:714
    local Map = package.loaded["src.core.game3.map"]
    local def = Map and Map.currentDef and Map.currentDef()
    Weather.setSavedFromHeader(def and def.weather or Weather.NONE)
    return
  end
  Weather._pending = Weather.NONE
  Weather.current = Weather.NONE
  Weather._active = false
  Weather.apply(Weather.NONE)
end

local function fieldLocked()
  local Field = package.loaded["src.core.game3.field"]
  return Field and Field.locked == true
end

function Weather.apply(id, opts)
  local E = rseEngine()
  if E then
    Weather.installRseHooks()
    opts = opts or {}
    local seamless = opts.seamless
    if seamless == nil then seamless = not fieldLocked() and E.isStarted() end
    local pinned = Weather._scriptSaved
    -- pokeemerald/src/overworld.c:854
    -- pokeruby/src/overworld.c:1479
    if not opts.continue and not (pinned and pinned.seq == Weather._applySeq and pinned.map == currentMapId()) then
      Weather.setSavedFromHeader(id)
    end
    Weather._applySeq = Weather._applySeq + 1
    Weather._scriptSaved = nil
    if seamless then
      -- pokeemerald/src/overworld.c:818
      Weather.doCurrent()
    else
      -- pokeemerald/src/overworld.c:2147
      E.restart()
      Weather.resumePaused()
    end
    return
  end

  Weather.current = tonumber(id) or Weather.NONE
  Weather._active = Weather.current ~= Weather.NONE and Weather.current ~= Weather.SUNNY

  local okFw, FieldWeather = pcall(lazyReq, "src.core.game3.field_weather")
  if okFw and FieldWeather and FieldWeather.setWeather then
    FieldWeather.setWeather(Weather.current)
  end

  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local world = game and (game.overworld or game.world)
  if world and world.setWeather then
    pcall(function() world:setWeather(Weather.current) end)
  end
end

function Weather.get()
  local E = rseEngine()
  if E then
    -- pokeemerald/src/field_weather.c:1032 GetCurrentWeather
    syncActive(E.getCurrentWeather())
  end
  return Weather.current
end

function Weather.isActive()
  if rseEngine() then Weather.get() end
  return Weather._active
end

function Weather.suspend()
  Weather._suspended = true
end

function Weather.resume()
  Weather._suspended = false
end

function Weather.isSuspended()
  return Weather._suspended
end

return Weather
