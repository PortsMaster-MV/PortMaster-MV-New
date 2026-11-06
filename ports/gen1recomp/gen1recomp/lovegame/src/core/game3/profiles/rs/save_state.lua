local SaveSections = require("src.core.game3.save_sections")
local fields = {
  "trainerRematchStepCounter", "trainerRematches", "regionMapZoom", "battleTower", "contestWinners",
  "dewfordTrends", "unlockedTrendySayings", "oldMan", "easyChatProfile",
  "easyChatBattleStart", "easyChatBattleWon", "easyChatBattleLost",
  "externalEventDataNativeBytes", "externalEventFlagsNativeBytes", "enigmaBerryNativeBytes", "ramScriptNativeBytes",
}
-- pokeruby/src/new_game.c:173
SaveSections.register("rsState", SaveSections.fields(fields, function(session)
  session.battleTower = {}
  session.trainerRematchStepCounter, session.trainerRematches = 0, {}
  session.regionMapZoom = false
  local C = require("src.core.game3.constants").of(session.version)
  local L = require("src.save_convert.gen3_layouts.rs")
  -- pokeruby/src/new_game.c:99
  local path = "data/generated/gba/rse/contest/manifest.lua"
  local src = assert(require("src.core.game3.dataset").cache():read(path), "RS contest defaults missing")
  local manifest = assert(load(src, "@" .. path, "t", {}))()
  local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, item in pairs(v) do out[k] = copy(item) end
    return out
  end
  session.contestWinners = {}
  for i = 0, 7 do session.contestWinners[i + 1] = copy(assert(manifest.defaultWinners[i], "RS default winner missing")) end
  local function emptyName(n)
    local out = { 255 }
    for i = 2, n do out[i] = 0 end
    return out
  end
  for i = 9, 13 do
    session.contestWinners[i] = { personality = 0, trainerId = 0, species = 0, contestCategory = 0,
      monName = emptyName(11), trainerName = emptyName(8) }
  end
  session.unlockedTrendySayings = { 0, 0, 0, 0 }
  local function words(list, n)
    local out = {}
    for i = 1, n do
      local w = list[i]
      out[i] = w and (C:require("easy_chat", w[1]) * 512 + w[2]) or 0xFFFF
    end
    return out
  end
  -- pokeruby/src/easy_chat_1.c:529
  session.easyChatProfile = words(L.DEFAULT_EASY_CHAT.profile, 4)
  session.easyChatBattleStart = words(L.DEFAULT_EASY_CHAT.start, 6)
  session.easyChatBattleWon, session.easyChatBattleLost = words({}, 6), words({}, 6)
  -- pokeruby/src/new_game.c:202
  require("src.core.game3.profiles.rs.old_man").set(session)
  require("src.core.game3.rse.dewford_trend").init(session)
  -- pokeruby/src/field_specials.c:1955
  session.vars[C:require("vars", "VAR_FANCLUB_UNKNOWN_1")] = 0
  session.vars[C:require("vars", "VAR_FANCLUB_UNKNOWN_2")] = 0
  -- pokeruby/src/lottery_corner.c:29
  local Rng = require("src.core.game3.rng")
  session.vars[C:require("vars", "VAR_LOTTERY_RND_L")] = Rng.Random()
  session.vars[C:require("vars", "VAR_LOTTERY_RND_H")] = Rng.Random()
  session.vars[C:require("vars", "VAR_LOTTERY_PRIZE")] = 0
end))
return fields
