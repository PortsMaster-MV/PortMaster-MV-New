local Rematch = require("src.core.game3.rse.rematch")

local MatchCall = {}

MatchCall.REL = "rse/match_call/manifest.lua"

-- pokeemerald/src/match_call.c:56
MatchCall.STR = { TRAINER_NAME = 0, MAP_NAME = 1, SPECIES_IN_ROUTE = 2, SPECIES_IN_PARTY = 3, FACILITY_NAME = 4,
  FRONTIER_STREAK = 5 }
-- pokeemerald/src/match_call.c:67
MatchCall.GEN_TOPIC = { PERSONAL = 1, STREAK = 2, STREAK_RECORD = 3, B_DOME = 4, B_PIKE = 5, B_PYRAMID = 6 }
-- pokeemerald/include/constants/battle_frontier.h:9
MatchCall.FACILITY = { TOWER = 0, DOME = 1, PALACE = 2, ARENA = 3, FACTORY = 4, PIKE = 5, PYRAMID = 6 }
-- pokeemerald/src/match_call.c:40
MatchCall.MC_FACTORY = MatchCall.FACILITY.PIKE
MatchCall.MC_PIKE = MatchCall.FACILITY.FACTORY
-- pokeemerald/src/pokenav_match_call_data.c:171
MatchCall.REMATCH_CALL_START = 0xFFFE
MatchCall.ALWAYS_AVAILABLE = 0xFFFF
MatchCall.NO_FLAG_TO_SET = 0xFFFF
-- pokeemerald/src/match_call.c:1702
MatchCall.LAND_SLOT_CHANCES = { 20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1 }
MatchCall.WATER_SLOT_CHANCES = { 60, 30, 5, 4, 1 }

MatchCall.rng = function() return require("src.core.game3.rng").Random() end

local manifest, manifestRoot

local function cacheRoot()
  return require("src.core.game3.cache_paths").CACHE_ROOT
end

local function readLua(rel)
  local cache = require("src.core.game3.dataset").cache()
  local src = cache and cache:read(cacheRoot() .. "/" .. rel)
  if not src then return nil end
  local chunk = load(src, "@" .. rel, "t", {})
  local ok, t = pcall(chunk)
  return ok and t or nil
end

function MatchCall.manifest()
  if manifest and manifestRoot == cacheRoot() then return manifest end
  manifest = assert(readLua(MatchCall.REL), "match call manifest is not in the cache")
  manifestRoot = cacheRoot()
  return manifest
end

function MatchCall.reset()
  manifest, manifestRoot = nil, nil
  MatchCall._state = nil
  MatchCall._mapsecByMap = nil
end

local function runtime()
  return package.loaded["src.core.game3.runtime"]
end

local function runtimeSession()
  local rt = runtime()
  return rt and rt.getSession and rt.getSession() or nil
end

function MatchCall.enabled(session)
  local ok, gate = pcall(function()
    return require("src.core.game3.capabilities").gate(session or runtimeSession(), "match_call")
  end)
  return ok and gate == true
end

local function constants(session)
  local C = require("src.core.game3.constants")
  return C.of(C.versionOf(session))
end

local function flag(session, name) return Rematch.flag(session, name) end

local function varId(session, name)
  return assert(constants(session):var(name), "match call: unknown var " .. tostring(name))
end

local function getVar(session, name)
  local Flags = require("src.core.game3.scripting.flags")
  return tonumber(Flags.getVar(Rematch.store(session), nil, varId(session, name))) or 0
end

local function setVar(session, name, v)
  local Flags = require("src.core.game3.scripting.flags")
  local st = Rematch.store(session)
  if st then Flags.setVar(st, nil, varId(session, name), v) end
end

local mapIds

function MatchCall.mapIdFor(session, group, num)
  local C = constants(session)
  if not mapIds or mapIds.game ~= C.game then
    mapIds = { game = C.game }
    local Profile = require("src.core.game3.profile")
    local ok, row = pcall(Profile.forSession, session)
    local prefix = ok and row and row.map and row.map.enginePrefix or "EM_"
    for name, e in pairs(C.map_groups.byName) do
      mapIds[e.group * 256 + e.num] = prefix .. name:sub(5)
    end
  end
  return mapIds[group * 256 + num]
end

function MatchCall.mapDef(mapId)
  local rt = runtime()
  local game = rt and (rt._game or (rt.getGame and rt.getGame()))
  local maps = game and game.data and game.data.maps
  return maps and mapId and maps[mapId] or nil
end

function MatchCall.currentDef()
  local Map = package.loaded["src.core.game3.map"]
  return Map and Map.currentDef and Map.currentDef() or nil
end

function MatchCall.mapsecOfMap(session, mapId)
  local def = MatchCall.mapDef(mapId)
  return def and tonumber(def.regionMapSectionId) or nil
end

local function mapsecNamed(session, mapName)
  local g = constants(session):map(mapName)
  return g and MatchCall.mapsecOfMap(session, MatchCall.mapIdFor(session, g.group, g.num)) or nil
end

function MatchCall.currentMapsec()
  local def = MatchCall.currentDef()
  return def and tonumber(def.regionMapSectionId) or nil
end

-- pokeemerald/src/overworld.c:1366
function MatchCall.mapTypeAllowsTeleportAndFly(mapType)
  local T = require("src.core.game3.field_moves").MAP_TYPES
  mapType = tonumber(mapType)
  return mapType == T.ROUTE or mapType == T.TOWN or mapType == T.OCEAN_ROUTE or mapType == T.CITY
end

function MatchCall.state(session)
  session = session or runtimeSession()
  local s = MatchCall._state
  if not s or s.session ~= session then
    s = { session = session }
    MatchCall._state = s
    MatchCall.initCounters(session)
  end
  return s
end

local function totalMinutes(session)
  local Rtc = require("src.core.game3.rtc")
  local t = Rtc.calcLocalTime(session)
  return t.days * 24 * 60 + t.hours * 60 + t.minutes
end
MatchCall.totalMinutes = totalMinutes

-- pokeemerald/src/match_call.c:1029
function MatchCall.initCounters(session)
  session = session or runtimeSession()
  local s = MatchCall._state
  if not s or s.session ~= session then
    s = { session = session }
    MatchCall._state = s
  end
  s.minutes = totalMinutes(session) + 10
  s.stepCounter = 0
  s.trainerId = 0
  s.triggeredFromScript = false
  return s
end

-- pokeemerald/src/match_call.c:1041
local function updateMinutesCounter(s)
  local cur = totalMinutes(s.session)
  if s.minutes > cur or cur - s.minutes > 9 then
    s.minutes = cur
    return true
  end
  return false
end

-- pokeemerald/src/match_call.c:1055
local function checkChance(session)
  local chance = 1
  local lead = session.party and session.party[1]
  local Pokemon = require("src.core.game3.pokemon")
  if lead and not Pokemon.isEgg(lead) then
    local ability = lead.ability or Pokemon.abilityId(lead.species, lead.personality)
    if ability == constants(session).abilities.byName.ABILITY_LIGHTNING_ROD then chance = 2 end
  end
  return MatchCall.rng() % 10 < chance * 3
end

-- pokeemerald/src/match_call.c:1067
function MatchCall.mapAllowsMatchCall(session)
  local def = MatchCall.currentDef() or {}
  local sec = tonumber(def.regionMapSectionId)
  if not MatchCall.mapTypeAllowsTeleportAndFly(def.mapType) then return false end
  if sec == mapsecNamed(session, "MAP_SAFARI_ZONE_NORTH") then return false end
  if sec == mapsecNamed(session, "MAP_SOOTOPOLIS_CITY")
      and flag(session, "FLAG_HIDE_SOOTOPOLIS_CITY_RAYQUAZA") and not flag(session, "FLAG_NEVER_SET_0x0DC") then
    return false
  end
  if sec == mapsecNamed(session, "MAP_MT_CHIMNEY")
      and flag(session, "FLAG_MET_ARCHIE_METEOR_FALLS") and not flag(session, "FLAG_DEFEATED_EVIL_TEAM_MT_CHIMNEY") then
    return false
  end
  return true
end

-- pokeemerald/src/match_call.c:1085
local function updateStepCounter(s)
  s.stepCounter = s.stepCounter + 1
  if s.stepCounter >= 10 then
    s.stepCounter = 0
    return true
  end
  return false
end

-- pokeemerald/src/match_call.c:1118
function MatchCall.numRegisteredTrainers(session)
  local n = 0
  for i = 0, Rematch.SPECIAL_TRAINER_START - 1 do
    if flag(session, Rematch.registeredFlagId(session, i)) then n = n + 1 end
  end
  return n
end

-- pokeemerald/src/match_call.c:1130
function MatchCall.activeTrainerId(session, n)
  for i = 0, Rematch.SPECIAL_TRAINER_START - 1 do
    if flag(session, Rematch.registeredFlagId(session, i)) then
      if n == 0 then return Rematch.trainerIds(i)[1] end
      n = n - 1
    end
  end
  return nil
end

-- pokeemerald/src/match_call.c:1545
function MatchCall.matchCallId(trainerId)
  local t = MatchCall.manifest().trainers
  local i = 0
  while t[i] do
    if t[i].trainerId == trainerId then return i end
    i = i + 1
  end
  return nil
end

-- pokeemerald/src/match_call.c:1461
function MatchCall.isEligibleForRematch(session, matchCallId)
  return Rematch.get(session, matchCallId) > 0
end

-- pokeemerald/src/match_call.c:1466
function MatchCall.rematchLocation(session, matchCallId)
  local e = Rematch.entry(matchCallId)
  if not e then return nil end
  return MatchCall.mapsecOfMap(session, MatchCall.mapIdFor(session, e.mapGroup, e.mapNum))
end

-- pokeemerald/src/match_call.c:1098
function MatchCall.selectTrainer(session, s)
  local n = MatchCall.numRegisteredTrainers(session)
  if n == 0 then return false end
  s.trainerId = MatchCall.activeTrainerId(session, MatchCall.rng() % n)
  s.triggeredFromScript = false
  if not s.trainerId then return false end
  local id = MatchCall.matchCallId(s.trainerId)
  if MatchCall.rematchLocation(session, id) == MatchCall.currentMapsec() and not MatchCall.isEligibleForRematch(session, id) then
    return false
  end
  return true
end

-- pokeemerald/src/match_call.c:1156
function MatchCall.tryStartMatchCall(session, game)
  session = session or runtimeSession()
  if not (session and MatchCall.enabled(session)) then return false end
  local s = MatchCall.state(session)
  if flag(session, "FLAG_HAS_MATCH_CALL") and updateStepCounter(s) and updateMinutesCounter(s) and checkChance(session)
      and MatchCall.mapAllowsMatchCall(session) and MatchCall.selectTrainer(session, s) then
    MatchCall.startCall(session, game, { trainerId = s.trainerId })
    return true
  end
  return false
end

function MatchCall.startCall(session, game, opts)
  opts = opts or {}
  MatchCall.lastCall = { trainerId = opts.trainerId, fromScript = opts.fromScript == true, frame = MatchCall.calls }
  MatchCall.calls = (MatchCall.calls or 0) + 1
  local Window = require("src.ui.game3.rse.pokenav.call_window")
  if opts.fromScript then
    return Window.start({ session = session, text = opts.text, onDone = opts.onDone })
  end
  local ok, StepEvents = pcall(require, "src.core.game3.step_events")
  local function run(onDone)
    Window.start({
      session = session,
      message = function() return MatchCall.selectMessage(session, opts.trainerId) end,
      onDone = function()
        if opts.onDone then opts.onDone() end
        onDone()
      end,
    })
  end
  if ok and StepEvents and StepEvents.queueEvent then
    StepEvents.queueEvent({ type = "match_call", run = run })
  else
    run(function() end)
  end
  return true
end

-- pokeemerald/src/match_call.c:1472
local function numRematchTrainersFought(session)
  local n = 0
  for i = 0, Rematch.SPECIAL_TRAINER_START - 1 do
    if Rematch.hasTrainerBeenFought(session, Rematch.trainerIds(i)[1]) then n = n + 1 end
  end
  return n
end

-- pokeemerald/src/match_call.c:1487
local function nthRematchTrainerFought(session, n)
  local count = 0
  for i = 0, Rematch.count() - 1 do
    if Rematch.hasTrainerBeenFought(session, Rematch.trainerIds(i)[1]) then
      if count == n then return i end
      count = count + 1
    end
  end
  return Rematch.count()
end

-- pokeemerald/src/match_call.c:1868
local function numOwnedBadges(session)
  for i, name in ipairs(Rematch.BADGE_FLAGS) do
    if not flag(session, name) then return i - 1 end
  end
  return #Rematch.BADGE_FLAGS
end

-- pokeemerald/src/match_call.c:1882
function MatchCall.shouldTrainerRequestBattle(session, matchCallId)
  if numOwnedBadges(session) < 5 then return false end
  local Rtc = require("src.core.game3.rtc")
  Rtc.calcLocalTime(session)
  local dayCount = Rtc.localDayCount()
  local otId = (tonumber(session.trainerId) or 0) % 65536
  local trends = session.dewfordTrends
  local dewfordRand = tonumber(trends and trends[1] and trends[1].rand) or 0
  local fought = numRematchTrainersFought(session)
  local max = math.floor(fought * 13 / 10)
  if max == 0 then return false end
  local bit = rawget(_G, "bit") or require("bit")
  local stat = Rematch.gameStat(session, Rematch.GAME_STAT_TRAINER_BATTLES)
  local rand = bit.bxor(bit.bxor(dayCount, dewfordRand) + bit.bxor(dewfordRand, stat), otId)
  local n = rand % max
  if n < fought then return nthRematchTrainerFought(session, n) == matchCallId end
  return false
end

local function topicText(list, topic, id)
  local t = list[topic]
  return t and t[id] or nil
end

-- pokeemerald/src/match_call.c:1557
local function sameRouteText(man, id)
  local tid = man.trainers[id].sameRouteTextId
  return topicText(man.requestTopics, math.floor(tid / 256), tid % 256)
end

local function differentRouteText(man, id)
  local tid = man.trainers[id].differentRouteTextId
  return topicText(man.requestTopics, math.floor(tid / 256), tid % 256)
end

-- pokeemerald/src/match_call.c:1575
local function battleText(man, id)
  local tid = man.trainers[id].battleTopicTextIds[MatchCall.rng() % 3 + 1]
  return topicText(man.battleTopics, math.floor(tid / 256), tid % 256)
end

-- pokeemerald/src/match_call.c:1910
function MatchCall.frontierStreak(session, facility)
  local f = type(session.frontier) == "table" and session.frontier or {}
  local function best(t)
    local v = 0
    if type(t) ~= "table" then return 0 end
    for _, x in pairs(t) do
      if type(x) == "table" then
        for _, y in pairs(x) do if (tonumber(y) or 0) > v then v = tonumber(y) end end
      elseif (tonumber(x) or 0) > v then
        v = tonumber(x)
      end
    end
    return v
  end
  local G, F = MatchCall.GEN_TOPIC, MatchCall.FACILITY
  if facility == F.DOME then return best(f.domeRecordWinStreaks), G.B_DOME - 1 end
  if facility == MatchCall.MC_PIKE then return best(f.pikeRecordStreaks), G.B_PIKE - 1 end
  if facility == F.TOWER then return best(f.towerRecordWinStreaks), G.STREAK_RECORD - 1 end
  if facility == F.PALACE then return best(f.palaceRecordWinStreaks), G.STREAK_RECORD - 1 end
  if facility == MatchCall.MC_FACTORY then return best(f.factoryRecordWinStreaks), G.STREAK_RECORD - 1 end
  if facility == F.ARENA then return best(f.arenaRecordStreaks), G.STREAK_RECORD - 1 end
  if facility == F.PYRAMID then return best(f.pyramidRecordStreaks), G.B_PYRAMID - 1 end
  return 0, 0
end

-- pokeemerald/src/match_call.c:1591
local function generalText(session, man, id, info)
  local rand = MatchCall.rng()
  if rand % 2 == 0 then
    local count = 0
    for i = 0, 6 do
      if MatchCall.frontierStreak(session, i) > 1 then count = count + 1 end
    end
    if count > 0 then
      count = MatchCall.rng() % count
      local i, topic = 0, 0
      while i <= 6 do
        local streak
        streak, topic = MatchCall.frontierStreak(session, i)
        info.streak = streak
        if streak >= 2 then
          if count == 0 then break end
          count = count - 1
        end
        i = i + 1
      end
      info.facilityId = i
      return topicText(man.generalTopics, topic + 1, man.trainers[id].streakTextIndex)
    end
  end
  local g = man.trainers[id].generalTextId
  return topicText(man.generalTopics, math.floor(g / 256), g % 256)
end

function MatchCall.trainerName(session, matchCallId)
  local man = MatchCall.manifest()
  local trainerId = man.trainers[matchCallId].trainerId
  local RomText = require("src.core.game3.rom_text")
  for _, r in ipairs(man.multiTrainerNames) do
    if r.trainerId == trainerId then return RomText.plain(r.text) end
  end
  local t = require("src.core.game3.scripting.trainers").get(trainerId)
  return t and t.name or ""
end

-- pokeemerald/src/match_call.c:1750
local function speciesFromLocation(session, matchCallId)
  local e = Rematch.entry(matchCallId)
  local raw = readLua("encounters.lua")
  local h = raw and e and raw[e.mapGroup .. ":" .. e.mapNum]
  if not h then return "" end
  local species = {}
  local function pick(area, chances)
    local total = 0
    for _, c in ipairs(chances) do total = total + c end
    local r, acc = MatchCall.rng() % total, 0
    for i, c in ipairs(chances) do
      acc = acc + c
      if r < acc then return area.slots[i] end
    end
  end
  if h.land then species[#species + 1] = pick(h.land, MatchCall.LAND_SLOT_CHANCES).species end
  if h.water then species[#species + 1] = pick(h.water, MatchCall.WATER_SLOT_CHANCES).species end
  if #species == 0 then return "" end
  return require("src.core.game3.pokemon").name(species[MatchCall.rng() % #species + 1]) or ""
end

-- pokeemerald/src/match_call.c:1796
local function speciesFromParty(session, matchCallId)
  local man = MatchCall.manifest()
  local trainerId = Rematch.lastBeatenRematchTrainerId(session, man.trainers[matchCallId].trainerId)
  local t = require("src.core.game3.scripting.trainers").get(trainerId)
  local party = t and t.party or {}
  if #party == 0 then return "" end
  local mon = party[MatchCall.rng() % #party + 1]
  return require("src.core.game3.pokemon").name(mon.species) or ""
end

function MatchCall.mapName(sec)
  if not sec then return "" end
  return require("src.ui.game3.rse.mapsec").name(sec)
end

local function populate(session, matchCallId, funcId, info)
  local S = MatchCall.STR
  if funcId == S.TRAINER_NAME then return MatchCall.trainerName(session, matchCallId) end
  if funcId == S.MAP_NAME then return MatchCall.mapName(MatchCall.rematchLocation(session, matchCallId)) end
  if funcId == S.SPECIES_IN_ROUTE then return speciesFromLocation(session, matchCallId) end
  if funcId == S.SPECIES_IN_PARTY then return speciesFromParty(session, matchCallId) end
  if funcId == S.FACILITY_NAME then
    local key = MatchCall.manifest().frontierFacilityNames[info.facilityId or 0]
    return key and require("src.core.game3.rom_text").plain(key) or ""
  end
  if funcId == S.FRONTIER_STREAK then return tostring(info.streak or 0) end
  return ""
end

function MatchCall.textCtx(session, stringVars)
  return {
    playerName = session and (session.name or session.playerName) or nil,
    playerGender = session and (session.gender or session.playerGender) or nil,
    stringVars = stringVars or {},
  }
end

-- pokeemerald/src/match_call.c:1505
function MatchCall.selectMessage(session, trainerId)
  local man = MatchCall.manifest()
  local id = assert(MatchCall.matchCallId(trainerId), "match call: trainer " .. tostring(trainerId) .. " has no match call row")
  local info = { facilityId = 0, streak = 0 }
  local text
  local newRequest = false
  if MatchCall.isEligibleForRematch(session, id) and MatchCall.rematchLocation(session, id) == MatchCall.currentMapsec() then
    text = sameRouteText(man, id)
  elseif MatchCall.shouldTrainerRequestBattle(session, id) then
    text = differentRouteText(man, id)
    newRequest = true
    Rematch.updateIfDefeated(session, id)
  elseif MatchCall.rng() % 3 ~= 0 then
    text = battleText(man, id)
  else
    text = generalText(session, man, id, info)
  end
  local vars = {}
  for i, f in ipairs(text.vars) do
    if f >= 0 then vars[i] = populate(session, id, f, info) end
  end
  return { key = text.text, ctx = MatchCall.textCtx(session, vars), newRematchRequest = newRequest, matchCallId = id }
end

-- pokeemerald/src/pokenav_match_call_data.c:752
function MatchCall.header(idx)
  return MatchCall.manifest().headers[idx]
end

function MatchCall.headerCount()
  local h, n = MatchCall.manifest().headers, 0
  while h[n] do n = n + 1 end
  return n
end

local function genderOf(session)
  local g = session and (session.gender or session.playerGender)
  if g == 1 or g == "female" or g == "girl" or g == "F" then return 1 end
  return 0
end

-- pokeemerald/src/pokenav_match_call_data.c:752
function MatchCall.headerEnabled(session, idx)
  local h = MatchCall.header(idx)
  if not h then return false end
  if h.type == "rival" then
    if h.playerGender ~= genderOf(session) then return false end
  elseif h.type == "birch" then
    return flag(session, h.flag)
  end
  if h.flag == 0xFFFF then return true end
  return flag(session, h.flag)
end

-- pokeemerald/src/pokenav_match_call_data.c:799
function MatchCall.headerMapSec(session, idx)
  local h = MatchCall.header(idx)
  if not h then return 0 end
  if h.type == "wally" then
    local loc = h.locations
    local i = 1
    while loc[i] and loc[i].flag ~= 0xFFFF do
      if not flag(session, loc[i].flag) then break end
      i = i + 1
    end
    return loc[i] and loc[i].mapSec or 0
  end
  if h.type == "rival" or h.type == "birch" then return MatchCall.mapsecNone() end
  return h.mapSec or 0
end

function MatchCall.mapsecNone()
  local ok, n = pcall(function() return require("src.ui.game3.rse.mapsec").count() end)
  return ok and n or 213
end

-- pokeemerald/src/pokenav_match_call_data.c:926
function MatchCall.headerRematchTableIdx(idx)
  local h = MatchCall.header(idx)
  if h and (h.type == "trainer" or h.type == "leader" or h.type == "wally") then return h.rematchTableIdx end
  return Rematch.count()
end

-- pokeemerald/src/pokenav_match_call_data.c:882
function MatchCall.headerHasCheckPage(idx)
  local h = MatchCall.header(idx)
  if not h then return false end
  if h.type == "trainer" or h.type == "leader" or h.type == "wally" then return true end
  for _, o in ipairs(MatchCall.manifest().checkPageOverrides) do
    if o.idx == idx then return true end
  end
  return false
end

-- pokeemerald/src/pokenav_match_call_data.c:843
function MatchCall.headerIsRematchable(session, idx)
  local h = MatchCall.header(idx)
  if not h then return false end
  if h.type == "trainer" or h.type == "leader" then
    if h.rematchTableIdx >= Rematch.ELITE_FOUR_ENTRIES then return false end
    return Rematch.get(session, h.rematchTableIdx) ~= 0
  end
  if h.type == "wally" then return Rematch.get(session, h.rematchTableIdx) ~= 0 end
  return false
end

-- pokeemerald/src/pokenav_match_call_data.c:1004
local function bufferCallMessageText(session, textData)
  local i = #textData
  while i > 1 do
    local d = textData[i]
    if d.availability ~= MatchCall.ALWAYS_AVAILABLE and flag(session, d.availability) then break end
    i = i - 1
  end
  local d = textData[i]
  if d.setFlag ~= MatchCall.NO_FLAG_TO_SET then Rematch.setFlag(session, d.setFlag, true) end
  return d.text
end

-- pokeemerald/src/pokenav_match_call_data.c:1022
local function bufferByRematchTeam(session, textData, idx)
  local i = 1
  while textData[i] do
    local a = textData[i].availability
    if a == MatchCall.REMATCH_CALL_START then break end
    if a ~= MatchCall.ALWAYS_AVAILABLE and not flag(session, a) then break end
    i = i + 1
  end
  local d = textData[i]
  if not d or d.availability ~= MatchCall.REMATCH_CALL_START then
    if i > 1 then i = i - 1 end
    d = textData[i]
    if d.setFlag ~= MatchCall.NO_FLAG_TO_SET then Rematch.setFlag(session, d.setFlag, true) end
    return d.text
  end
  if flag(session, "FLAG_SYS_GAME_CLEAR") then
    if Rematch.get(session, idx) ~= 0 then
      i = i + 2
    elseif Rematch.countBattledRematchTeams(session, idx) >= 2 then
      i = i + 3
    else
      i = i + 1
    end
  end
  return textData[i].text
end

-- pokeemerald/src/match_call.c:1991
local function pokedexRatingLevel(session, caught)
  if caught < 200 then return math.floor(caught / 10) end
  local C = constants(session)
  local Dex = require("src.core.game3.dex")
  if Dex.isCaught(session.dex, C.species.byName.SPECIES_DEOXYS) then caught = caught - 1 end
  if Dex.isCaught(session.dex, C.species.byName.SPECIES_JIRACHI) then caught = caught - 1 end
  if caught < 200 then return 19 end
  return 20
end

-- pokeemerald/src/pokedex.c:4343
function MatchCall.dexCounts(session, national)
  local Dex = require("src.core.game3.dex")
  local dex = session.dex
  local seen, caught = 0, 0
  local last = constants(session).species.byName.SPECIES_CHIMECHO or 411
  for sp = 1, last do
    if national or Dex.inRegional(sp, session.version) then
      if Dex.isSeen(dex, sp) then seen = seen + 1 end
      if Dex.isCaught(dex, sp) then caught = caught + 1 end
    end
  end
  return seen, caught
end

-- pokeemerald/src/match_call.c:2070
function MatchCall.birchRatingMessages(session)
  local man = MatchCall.manifest()
  local seen, caught = MatchCall.dexCounts(session, false)
  local out = {
    { key = "gBirchDexRatingText_AreYouCurious", ctx = MatchCall.textCtx(session, { tostring(seen), tostring(caught) }) },
    { key = "gBirchDexRatingText_SoYouveSeenAndCaught", ctx = MatchCall.textCtx(session, { tostring(seen), tostring(caught) }) },
    { key = man.birchDexRatingTexts[pokedexRatingLevel(session, caught)],
      ctx = MatchCall.textCtx(session, { tostring(seen), tostring(caught) }) },
  }
  local Dex = require("src.core.game3.dex")
  if Dex.nationalEnabled(session) then
    local ns, nc = MatchCall.dexCounts(session, true)
    out[#out + 1] = { key = "gBirchDexRatingText_OnANationwideBasis", ctx = MatchCall.textCtx(session, { tostring(ns), tostring(nc) }) }
  end
  return out
end

-- pokeemerald/src/pokenav_match_call_data.c:963
function MatchCall.headerMessage(session, idx)
  local h = MatchCall.header(idx)
  local ctx = MatchCall.textCtx(session)
  if h.type == "birch" then return { parts = MatchCall.birchRatingMessages(session) } end
  if h.type == "leader" then return { key = bufferByRematchTeam(session, h.textData, h.rematchTableIdx), ctx = ctx } end
  return { key = bufferCallMessageText(session, h.textData), ctx = ctx }
end

-- pokeemerald/src/pokenav_match_call_data.c:1061
function MatchCall.headerNameAndDesc(idx)
  local h = MatchCall.header(idx)
  local RomText = require("src.core.game3.rom_text")
  local Trainers = require("src.core.game3.scripting.trainers")
  local function byRematch(r)
    local t = Trainers.get(Rematch.trainerIds(r)[1])
    return t and t.className or "", t and t.name or ""
  end
  local desc, name
  if (h.type == "trainer" or h.type == "leader") and not h.name then
    desc, name = byRematch(h.rematchTableIdx)
    desc = RomText.plain(h.desc)
  elseif h.type == "wally" then
    desc, name = byRematch(h.rematchTableIdx)
    desc = RomText.plain(h.desc)
  else
    desc = h.desc and RomText.plain(h.desc) or nil
    name = h.name and RomText.plain(h.name) or nil
  end
  return desc, name
end

-- pokeemerald/src/pokenav_match_call_data.c:1114
function MatchCall.overrideFlavorText(session, idx, entry)
  local list = MatchCall.manifest().checkPageOverrides
  for i, o in ipairs(list) do
    if o.idx == idx then
      while list[i + 1] and list[i + 1].idx == idx and flag(session, list[i + 1].flag) do i = i + 1 end
      return list[i].texts[entry]
    end
  end
  return nil
end

function MatchCall.overrideFacilityClass(idx)
  for _, o in ipairs(MatchCall.manifest().checkPageOverrides) do
    if o.idx == idx then return o.facilityClass end
  end
  return -1
end

-- pokeemerald/src/pokenav_match_call_data.c:1143
function MatchCall.hasRematchId(idx)
  for i = 0, MatchCall.headerCount() - 1 do
    local id = MatchCall.headerRematchTableIdx(i)
    if id ~= Rematch.count() and id == idx then return true end
  end
  return false
end

-- pokeemerald/src/pokenav_match_call_data.c:1156
function MatchCall.setRegisteredFlag(session, trainerId)
  local idx = Rematch.firstBattleTableId(trainerId)
  if idx >= 0 then Rematch.setFlag(session, Rematch.registeredFlagId(session, idx), true) end
end

-- pokeemerald/src/pokenav_match_call_list.c:205
function MatchCall.buildList(session)
  local list = {}
  for j = 0, MatchCall.headerCount() - 1 do
    if MatchCall.headerEnabled(session, j) then
      list[#list + 1] = { headerId = j, isSpecialTrainer = true, mapSec = MatchCall.headerMapSec(session, j) }
    end
  end
  for i = 0, Rematch.count() - 1 do
    if not MatchCall.hasRematchId(i) and flag(session, Rematch.registeredFlagId(session, i)) then
      local e = Rematch.entry(i)
      list[#list + 1] = { headerId = i, isSpecialTrainer = false,
        mapSec = MatchCall.mapsecOfMap(session, MatchCall.mapIdFor(session, e.mapGroup, e.mapNum)) }
    end
  end
  return list
end

-- pokeemerald/src/pokenav_match_call_list.c:315
function MatchCall.entryRematchIdx(entry)
  if not entry.isSpecialTrainer then return entry.headerId end
  return MatchCall.headerRematchTableIdx(entry.headerId)
end

function MatchCall.showRematchIcon(session, entry)
  local idx = MatchCall.entryRematchIdx(entry)
  if idx == Rematch.count() then return false end
  return Rematch.get(session, idx) ~= 0
end

-- pokeemerald/src/pokenav_match_call_list.c:351
function MatchCall.entryMessage(session, entry)
  local def = MatchCall.currentDef() or {}
  if not MatchCall.mapTypeAllowsTeleportAndFly(def.mapType) then
    return { key = "gText_CallCantBeMadeHere", ctx = MatchCall.textCtx(session) }, false
  end
  if not entry.isSpecialTrainer then
    local m = MatchCall.selectMessage(session, Rematch.trainerIds(entry.headerId)[1])
    return m, m.newRematchRequest
  end
  return MatchCall.headerMessage(session, entry.headerId), false
end

-- pokeemerald/src/pokenav_match_call_list.c:366
function MatchCall.entryFlavorText(session, entry, checkPageEntry)
  local rematchId
  if entry.isSpecialTrainer then
    rematchId = MatchCall.headerRematchTableIdx(entry.headerId)
    if rematchId == Rematch.count() then return MatchCall.overrideFlavorText(session, entry.headerId, checkPageEntry) end
  else
    rematchId = entry.headerId
  end
  local row = MatchCall.manifest().flavorTexts[rematchId]
  return row and row[checkPageEntry] or nil
end

-- pokeemerald/src/pokenav_match_call_list.c:329
function MatchCall.entryTrainerPic(session, entry)
  local Trainers = require("src.core.game3.scripting.trainers")
  local r = MatchCall.entryRematchIdx(entry)
  if r ~= Rematch.count() then
    local t = Trainers.get(Rematch.trainerIds(r)[1])
    return t and t.pic or -1
  end
  local fc = MatchCall.overrideFacilityClass(entry.headerId)
  local pack = Trainers.pack()
  return fc >= 0 and pack and pack.facilityClassToPic and pack.facilityClassToPic[fc] or -1
end

-- pokeemerald/src/pokenav_match_call_list.c:399
function MatchCall.entryNameAndDesc(entry)
  if not entry.isSpecialTrainer then
    local t = require("src.core.game3.scripting.trainers").get(Rematch.trainerIds(entry.headerId)[1])
    return t and t.className or "", t and t.name or ""
  end
  return MatchCall.headerNameAndDesc(entry.headerId)
end

-- pokeemerald/src/pokenav_match_call_list.c:491
function MatchCall.shouldDoNearbyMessage(session, entry)
  local cur = MatchCall.currentMapsec()
  if not entry.isSpecialTrainer then
    return entry.mapSec == cur and Rematch.get(session, entry.headerId) == 0
  end
  local h = MatchCall.header(entry.headerId)
  if h and h.flag == constants(session):flag("FLAG_ENABLE_WATTSON_MATCH_CALL") then
    if entry.mapSec == cur and flag(session, "FLAG_BADGE05_GET") then
      return not flag(session, "FLAG_WATTSON_REMATCH_AVAILABLE")
    end
  end
  return false
end

-- pokeemerald/src/pokenav_menu_handler_gfx.c:366
function MatchCall.anyRematchesNearby(session)
  local cur = MatchCall.currentMapsec()
  for i = 0, Rematch.count() - 1 do
    if MatchCall.rematchLocation(session, i) == cur and flag(session, Rematch.registeredFlagId(session, i))
        and Rematch.get(session, i) ~= 0 then
      return true
    end
  end
  return false
end

-- pokeemerald/src/field_specials.c:353
MatchCall.STEP_CALLS = {
  { flag = "FLAG_ENABLE_FIRST_WALLY_POKENAV_CALL", var = "VAR_WALLY_CALL_STEP_COUNTER", steps = 250,
    script = "MauvilleCity_EventScript_RegisterWallyCall" },
  { flag = "FLAG_SCOTT_CALL_FORTREE_GYM", var = "VAR_SCOTT_FORTREE_CALL_STEP_COUNTER", steps = 10,
    script = "Route119_EventScript_ScottWonAtFortreeGymCall" },
  { flag = "FLAG_SCOTT_CALL_BATTLE_FRONTIER", var = "VAR_SCOTT_BF_CALL_STEP_COUNTER", steps = 10,
    script = "LittlerootTown_ProfessorBirchsLab_EventScript_ScottAboardSSTidalCall" },
  { flag = "FLAG_ENABLE_ROXANNE_FIRST_CALL", var = "VAR_ROXANNE_CALL_STEP_COUNTER", steps = 250,
    script = "RustboroCity_Gym_EventScript_RegisterRoxanne" },
  { flag = "FLAG_DEFEATED_MAGMA_SPACE_CENTER", var = "VAR_RIVAL_RAYQUAZA_CALL_STEP_COUNTER", steps = 250,
    script = "MossdeepCity_SpaceCenter_2F_EventScript_RivalRayquazaCall" },
}

-- pokeemerald/src/field_specials.c:353
function MatchCall.shouldDoStepCall(session, row)
  if not flag(session, row.flag) then return false end
  local def = MatchCall.currentDef() or {}
  if not MatchCall.mapTypeAllowsTeleportAndFly(def.mapType) then return false end
  local v = getVar(session, row.var) + 1
  setVar(session, row.var, v)
  return v >= row.steps
end

-- pokeemerald/src/field_control_avatar.c:543
function MatchCall.incrementRematchStepCounter(session)
  MatchCall.stepHookCalls = (MatchCall.stepHookCalls or 0) + 1
  session = session or runtimeSession()
  if not (session and MatchCall.enabled(session)) then return end
  Rematch.incrementStepCounter(session)
end

-- pokeemerald/src/field_control_avatar.c:570
function MatchCall.tryStepCountScripts(session, game)
  session = session or runtimeSession()
  if not (session and MatchCall.enabled(session)) then return false end
  for _, row in ipairs(MatchCall.STEP_CALLS) do
    if MatchCall.shouldDoStepCall(session, row) then
      local Space = require("src.core.game3.scripting.space")
      local key = Space.scriptKey(row.script)
      if key and Space.startScript(key) then return true end
      return false
    end
  end
  return false
end

function MatchCall.onStep(session, game, opts)
  opts = opts or {}
  MatchCall.incrementRematchStepCounter(session)
  if not opts.forced and MatchCall.tryStepCountScripts(session, game) then return true end
  return MatchCall.tryStartMatchCall(session, game)
end

local function opcodes()
  return require("src.core.game3.scripting.opcodes")
end

-- pokeemerald/src/field_message_box.c:80
function MatchCall.fieldMessage(vm, ptr)
  local session = runtimeSession()
  local ir
  if type(ptr) == "string" then
    ir = vm:getText(ptr)
  elseif ptr ~= nil then
    ir = vm:getText(opcodes().key(ptr)) or vm:getText(ptr)
  end
  if not ir then return false end
  local a = vm.adapters or {}
  local function val(v) if type(v) == "function" then return v() end return v end
  local ctx = {
    stringVars = vm.ctx.stringVars,
    playerName = val(a.playerName) or vm.ctx.playerName,
    rivalName = val(a.rivalName) or vm.ctx.rivalName,
    playerGender = session and (session.gender or session.playerGender) or nil,
  }
  local done = false
  vm.ctx.mode = "native"
  vm.ctx.status = "waiting"
  vm.ctx.nativePoll = function() return done end
  MatchCall.startCall(session, nil, { fromScript = true, text = { ir = ir, ctx = ctx }, onDone = function() done = true end })
  return not done
end

require("src.core.game3.rse.init").register("pokenav", { fieldMessage = MatchCall.fieldMessage })
require("src.core.game3.rse.init").register("rematch", Rematch)

return MatchCall
