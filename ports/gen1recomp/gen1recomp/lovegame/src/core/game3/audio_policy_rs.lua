local Policy = {}
local Shared = require("src.core.game3.audio_policy_rse")

local function song(ctx, name)
  return assert(ctx.songs[name], "audio_policy_rs: no song " .. tostring(name))
end

local function isMap(loc, name) return loc and loc.map == name end
local function weatherSong(ctx)
  return song(ctx, ctx.legendaryWeatherSong)
end

-- pokeruby/src/overworld.c:807
local WEATHER_MAPS = {
  LILYCOVE_CITY = true, MOSSDEEP_CITY = true, SOOTOPOLIS_CITY = true,
  EVER_GRANDE_CITY = true, ROUTE124 = true, ROUTE125 = true,
  ROUTE126 = true, ROUTE127 = true, ROUTE128 = true,
}

function Policy.shouldLegendaryMusicPlayAtLocation(ctx, loc)
  return ctx.flag("FLAG_SYS_WEATHER_CTRL") == true and loc ~= nil and WEATHER_MAPS[loc.map] == true
end

-- pokeruby/src/overworld.c:831
function Policy.isInfiltratedWeatherInstitute(ctx, loc)
  return (tonumber(ctx.var("VAR_WEATHER_INSTITUTE_STATE")) or 0) == 0
    and (isMap(loc, "ROUTE119_WEATHER_INSTITUTE_1F") or isMap(loc, "ROUTE119_WEATHER_INSTITUTE_2F"))
end

-- pokeruby/src/overworld.c:843
function Policy.locationMusic(ctx, loc)
  if Policy.shouldLegendaryMusicPlayAtLocation(ctx, loc) then return weatherSong(ctx) end
  if Policy.isInfiltratedWeatherInstitute(ctx, loc) then return song(ctx, "MUS_MT_CHIMNEY") end
  return ctx.headerMusic(loc)
end

-- pokeruby/src/overworld.c:853
function Policy.currLocationDefaultMusic(ctx)
  if isMap(ctx.location, "ROUTE111") and ctx.savedWeather() == ctx.weather("WEATHER_SANDSTORM") then
    return song(ctx, "MUS_ROUTE111")
  end
  local music = Policy.locationMusic(ctx, ctx.location)
  if music ~= 0x7FFF then return music end
  return song(ctx, (tonumber(ctx.location and ctx.location.x) or 0) < 24 and "MUS_ROUTE110" or "MUS_ROUTE119")
end

-- pokeruby/src/overworld.c:877
function Policy.warpDestinationMusic(ctx, dest)
  local music = Policy.locationMusic(ctx, dest)
  if music ~= 0x7FFF then return music end
  return song(ctx, isMap(ctx.location, "MAUVILLE_CITY") and "MUS_ROUTE110" or "MUS_ROUTE119")
end

-- pokeruby/src/overworld.c:899
function Policy.specialMapMusic(ctx)
  local music = Policy.currLocationDefaultMusic(ctx)
  if music ~= weatherSong(ctx) then
    if tonumber(ctx.savedMusic) and tonumber(ctx.savedMusic) ~= 0 then music = tonumber(ctx.savedMusic)
    elseif ctx.underwater then music = song(ctx, "MUS_UNDERWATER")
    elseif ctx.surfing then music = song(ctx, "MUS_SURF") end
  end
  return music
end

function Policy.playSpecialMapMusic(ctx)
  local music = Policy.specialMapMusic(ctx)
  if music ~= ctx.currentMusic then return music end
end

-- pokeruby/src/overworld.c:927
function Policy.transitionMapMusic(ctx, dest)
  if ctx.flag("FLAG_DONT_TRANSITION_MUSIC") == true then return nil end
  local music = Policy.warpDestinationMusic(ctx, dest)
  if music ~= weatherSong(ctx) then
    if ctx.currentMusic == song(ctx, "MUS_UNDERWATER") or ctx.currentMusic == song(ctx, "MUS_SURF") then return nil end
    if ctx.surfing then music = song(ctx, "MUS_SURF") end
  end
  if music == ctx.currentMusic then return nil end
  if ctx.biking then return { song = music, fadeOut = 4, fadeIn = 4 } end
  return { song = music, fadeOut = 8 }
end

-- pokeruby/src/overworld.c:950
function Policy.changeMusicToDefault(ctx)
  local music = Policy.currLocationDefaultMusic(ctx)
  if music ~= ctx.currentMusic then return { song = music, fadeOut = 8 } end
end

-- pokeruby/src/overworld.c:957
function Policy.changeMusicTo(ctx, music)
  if music ~= ctx.currentMusic and ctx.currentMusic ~= weatherSong(ctx) then
    return { song = music, fadeOut = 8 }
  end
end

-- pokeruby/src/overworld.c:964
function Policy.mapMusicFadeoutSpeed(ctx, dest) return ctx.isIndoor(dest) and 2 or 4 end

-- pokeruby/src/overworld.c:973
function Policy.tryFadeOutOldMapMusic(ctx, dest)
  if ctx.flag("FLAG_DONT_TRANSITION_MUSIC") ~= true and Policy.warpDestinationMusic(ctx, dest) ~= ctx.currentMusic then
    return Policy.mapMusicFadeoutSpeed(ctx, dest)
  end
end

Policy.location = Shared.location
function Policy.live(Audio, opts)
  local ctx = Shared.live(Audio, opts)
  ctx.legendaryWeatherSong = Audio.config().legendaryWeatherSong
  return ctx
end

return Policy
