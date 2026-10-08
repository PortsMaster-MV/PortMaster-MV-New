return {
  rtc = true, timeEvents = true,
  -- pokeruby/src/clock.c:27
  updateInPokemonCenters = true,
  timeEventsModule = "src.core.game3.rse.time_events_rs",
  allowExtraTimeHandlers = false,
  perDayOrder = {
    "ClearDailyFlags", "UpdateDewfordTrendPerDay", "UpdateTVShowsPerDay", "UpdateWeatherPerDay",
    "UpdatePartyPokerusTime", "UpdateMirageRnd", "UpdateBirchState", "SetShoalItemFlag", "SetRandomLotteryNumber",
  },
  perMinuteOrder = { "BerryTreeTimeUpdate" },
}
