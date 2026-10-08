local Policy = {}

local function song(ctx, name)
  local id = ctx.songs[name]
  if id == nil then error("audio_policy_rse: no song " .. tostring(name), 2) end
  return id
end

local function isMap(loc, name)
  return loc ~= nil and loc.map == name
end

local function mapIn(loc, names)
  if not loc then return false end
  for _, n in ipairs(names) do
    if loc.map == n then return true end
  end
  return false
end

local function flag(ctx, name) return ctx.flag(name) == true end
local function var(ctx, name) return tonumber(ctx.var(name)) or 0 end

-- pokeemerald/src/overworld.c:1010
local LEGEND_WEATHER_MAPS = {
  "LILYCOVE_CITY", "MOSSDEEP_CITY", "SOOTOPOLIS_CITY", "EVER_GRANDE_CITY",
  "ROUTE124", "ROUTE125", "ROUTE126", "ROUTE127", "ROUTE128",
}
-- pokeemerald/src/overworld.c:1033
local LEGEND_WEATHER_LATE_MAPS = { "ROUTE129", "ROUTE130", "ROUTE131" }

function Policy.shouldLegendaryMusicPlayAtLocation(ctx, loc)
  if not flag(ctx, "FLAG_SYS_WEATHER_CTRL") then return false end
  if mapIn(loc, LEGEND_WEATHER_MAPS) then return true end
  if var(ctx, "VAR_SOOTOPOLIS_CITY_STATE") < 4 then return false end
  return mapIn(loc, LEGEND_WEATHER_LATE_MAPS)
end

-- pokeemerald/src/overworld.c:1043
function Policy.noMusicInSootopolisWithLegendaries(ctx, loc)
  if var(ctx, "VAR_SKY_PILLAR_STATE") ~= 1 then return false end
  return isMap(loc, "SOOTOPOLIS_CITY")
end

-- pokeemerald/src/overworld.c:1055
function Policy.isInfiltratedWeatherInstitute(ctx, loc)
  if var(ctx, "VAR_WEATHER_INSTITUTE_STATE") ~= 0 then return false end
  return mapIn(loc, { "ROUTE119_WEATHER_INSTITUTE_1F", "ROUTE119_WEATHER_INSTITUTE_2F" })
end

-- pokeemerald/src/overworld.c:1068
function Policy.isInfiltratedSpaceCenter(ctx, loc)
  local state = var(ctx, "VAR_MOSSDEEP_CITY_STATE")
  if state == 0 or state > 2 then return false end
  return mapIn(loc, { "MOSSDEEP_CITY_SPACE_CENTER_1F", "MOSSDEEP_CITY_SPACE_CENTER_2F" })
end

-- pokeemerald/src/overworld.c:1082
function Policy.locationMusic(ctx, loc)
  if Policy.noMusicInSootopolisWithLegendaries(ctx, loc) then return song(ctx, "MUS_NONE") end
  if Policy.shouldLegendaryMusicPlayAtLocation(ctx, loc) then return song(ctx, "MUS_ABNORMAL_WEATHER") end
  if Policy.isInfiltratedSpaceCenter(ctx, loc) then return song(ctx, "MUS_ENCOUNTER_MAGMA") end
  if Policy.isInfiltratedWeatherInstitute(ctx, loc) then return song(ctx, "MUS_MT_CHIMNEY") end
  return ctx.headerMusic(loc)
end

-- pokeemerald/src/overworld.c:1096
function Policy.currLocationDefaultMusic(ctx)
  local loc = ctx.location
  if isMap(loc, "ROUTE111") and ctx.savedWeather() == ctx.weather("WEATHER_SANDSTORM") then
    return song(ctx, "MUS_DESERT")
  end
  local music = Policy.locationMusic(ctx, loc)
  if music ~= song(ctx, "MUS_ROUTE118") then return music end
  if (tonumber(loc and loc.x) or 0) < 24 then return song(ctx, "MUS_ROUTE110") end
  return song(ctx, "MUS_ROUTE119")
end

-- pokeemerald/src/overworld.c:1120
function Policy.warpDestinationMusic(ctx, dest)
  local music = Policy.locationMusic(ctx, dest)
  if music ~= song(ctx, "MUS_ROUTE118") then return music end
  if isMap(ctx.location, "MAUVILLE_CITY") then return song(ctx, "MUS_ROUTE110") end
  return song(ctx, "MUS_ROUTE119")
end

local function silentOrAbnormal(ctx, music)
  return music == song(ctx, "MUS_ABNORMAL_WEATHER") or music == song(ctx, "MUS_NONE")
end

-- pokeemerald/src/overworld.c:1142
function Policy.specialMapMusic(ctx)
  local music = Policy.currLocationDefaultMusic(ctx)
  if not silentOrAbnormal(ctx, music) then
    local saved = tonumber(ctx.savedMusic)
    if saved and saved ~= 0 then
      music = saved
    elseif ctx.underwater then
      music = song(ctx, "MUS_UNDERWATER")
    elseif ctx.surfing then
      music = song(ctx, "MUS_SURF")
    end
  end
  return music
end

function Policy.playSpecialMapMusic(ctx)
  local music = Policy.specialMapMusic(ctx)
  if music ~= ctx.currentMusic then return music end
  return nil
end

-- pokeemerald/src/overworld.c:1170
function Policy.transitionMapMusic(ctx, dest)
  if flag(ctx, "FLAG_DONT_TRANSITION_MUSIC") then return nil end
  local newMusic = Policy.warpDestinationMusic(ctx, dest)
  local current = ctx.currentMusic
  if not silentOrAbnormal(ctx, newMusic) then
    if current == song(ctx, "MUS_UNDERWATER") or current == song(ctx, "MUS_SURF") then return nil end
    if ctx.surfing then newMusic = song(ctx, "MUS_SURF") end
  end
  if newMusic == current then return nil end
  if ctx.biking then
    return { song = newMusic, fadeOut = 4, fadeIn = 4 }
  end
  return { song = newMusic, fadeOut = 8 }
end

-- pokeemerald/src/overworld.c:1193
function Policy.changeMusicToDefault(ctx)
  local def = Policy.currLocationDefaultMusic(ctx)
  if ctx.currentMusic ~= def then return { song = def, fadeOut = 8 } end
  return nil
end

-- pokeemerald/src/overworld.c:1200
function Policy.changeMusicTo(ctx, newMusic)
  local current = ctx.currentMusic
  if current ~= newMusic and current ~= song(ctx, "MUS_ABNORMAL_WEATHER") then
    return { song = newMusic, fadeOut = 8 }
  end
  return nil
end

-- pokeemerald/src/overworld.c:1207
function Policy.mapMusicFadeoutSpeed(ctx, dest)
  if ctx.isIndoor(dest) then return 2 end
  return 4
end

-- pokeemerald/src/overworld.c:1216
function Policy.tryFadeOutOldMapMusic(ctx, dest)
  local current = ctx.currentMusic
  local warpMusic = Policy.warpDestinationMusic(ctx, dest)
  if flag(ctx, "FLAG_DONT_TRANSITION_MUSIC") or warpMusic == current then return nil end
  if current == song(ctx, "MUS_SURF")
      and var(ctx, "VAR_SKY_PILLAR_STATE") == 2
      and isMap(ctx.location, "SOOTOPOLIS_CITY")
      and isMap(dest, "SOOTOPOLIS_CITY")
      and tonumber(dest.x) == 29 and tonumber(dest.y) == 53 then
    return nil
  end
  return Policy.mapMusicFadeoutSpeed(ctx, dest)
end

local function shortName(mapId, prefix)
  if type(mapId) ~= "string" then return nil end
  if prefix and prefix ~= "" and mapId:sub(1, #prefix) == prefix then
    return mapId:sub(#prefix + 1)
  end
  return mapId
end

function Policy.location(mapId, x, y, prefix)
  return { id = mapId, map = shortName(mapId, prefix), x = x, y = y }
end

function Policy.live(Audio, opts)
  opts = opts or {}
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession() or nil
  local Profile = require("src.core.game3.profile")
  local profile = Profile.forSession(session)
  local version = profile.id
  local prefix = profile.map and profile.map.enginePrefix
  local C = require("src.core.game3.constants").of(version)
  local Song = require("src.core.game3.song_ids")
  local Flags = require("src.core.game3.scripting.flags")
  local ids = Flags.forVersion(version)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local store = Space and Space.store
  local game = Runtime and Runtime._game
  local maps = game and game.data and game.data.maps
  local Map = package.loaded["src.core.game3.map"]
  local P = package.loaded["src.core.game3.player"]
  local Dataset = require("src.core.game3.dataset")

  local function defOf(mapId)
    local def = maps and maps[mapId]
    if not def and Map and Map.currentDef then
      local cur = Map.currentDef()
      if cur and (cur.id == mapId or (session and session.map == mapId)) then def = cur end
    end
    return def
  end

  local curMap = opts.locationMap or (session and session.map)
  local x = opts.x or (P and P.cellX) or (session and session.x)
  local y = opts.y or (P and P.cellY) or (session and session.y)
  local curDef = defOf(curMap)

  local ctx = {
    songs = Song.forVersion(version),
    location = Policy.location(curMap, x, y, prefix),
    at = function(mapId, ax, ay) return Policy.location(mapId, ax, ay, prefix) end,
    flag = function(name)
      local id = ids.IDS[name]
      if not (id and store) then return false end
      return Flags.getFlag(store, nil, id)
    end,
    var = function(name)
      local id = ids.VAR_IDS[name]
      if not (id and store) then return 0 end
      return Flags.getVar(store, nil, id)
    end,
    weather = function(name) return C.weather.byName[name] end,
    savedWeather = function()
      local W = package.loaded["src.core.game3.weather"]
      if W and W.getSaved and session then return W.getSaved(session) end
      return nil
    end,
    headerMusic = function(loc)
      local def = defOf(loc and loc.id)
      local music = def and def.music
      if music == nil then
        local idx = Audio._pack and Audio._pack.index and Audio._pack.index.mapSongs
        music = idx and loc and idx[loc.id]
      end
      return tonumber(music) or 0
    end,
    isIndoor = function(loc)
      local def = defOf(loc and loc.id)
      return def ~= nil and Dataset.isIndoorMapType(def.mapType)
    end,
    savedMusic = Audio._savedSong,
    currentMusic = Audio.currentMapMusic(),
    surfing = P ~= nil and (P.surfing or P.surfHopping) and not P.dismounting or false,
    biking = P ~= nil and P.biking and true or false,
    underwater = false,
  }
  if curDef then
    local _, kind = Dataset.kindOfMapType(curDef.mapType)
    ctx.underwater = kind == "UNDERWATER"
  end
  return ctx
end

return Policy
