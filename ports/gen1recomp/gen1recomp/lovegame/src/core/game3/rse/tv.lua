local Tv = {}

-- pokeemerald/include/constants/tv.h:76
Tv.NUM_NORMAL_TVSHOW_SLOTS = 5
Tv.TV_SHOWS_COUNT = Tv.NUM_NORMAL_TVSHOW_SLOTS + 20
Tv.LAST_TVSHOW_IDX = Tv.TV_SHOWS_COUNT - 1
-- pokeemerald/include/constants/global.h:49
Tv.POKE_NEWS_COUNT = 16
-- pokeemerald/include/constants/tv.h:276
Tv.SMARTSHOPPER_NUM_ITEMS = 3
-- pokeemerald/include/constants/easy_chat.h:1129
Tv.EC_EMPTY_WORD = 0xFFFF
-- pokeemerald/include/constants/global.h:20
Tv.LANGUAGE_JAPANESE = 1
Tv.LANGUAGE_ENGLISH = 2
Tv.GAME_LANGUAGE = Tv.LANGUAGE_ENGLISH

-- pokeemerald/include/constants/tv.h:25
Tv.TVSHOW_OFF_AIR = 0
Tv.TVSHOW_FAN_CLUB_LETTER = 1
Tv.TVSHOW_RECENT_HAPPENINGS = 2
Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS = 3
Tv.TVSHOW_DUMMY = 4
Tv.TVSHOW_NAME_RATER_SHOW = 5
Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE = 6
Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE = 7
Tv.TVSHOW_CONTEST_LIVE_UPDATES = 8
Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS = 9
Tv.TVSHOW_BATTLE_UPDATE = 10
Tv.TVSHOW_FAN_CLUB_SPECIAL = 11
Tv.TVSHOW_LILYCOVE_CONTEST_LADY = 12
Tv.TVSHOW_POKEMON_TODAY_CAUGHT = 21
Tv.TVSHOW_SMART_SHOPPER = 22
Tv.TVSHOW_POKEMON_TODAY_FAILED = 23
Tv.TVSHOW_FISHING_ADVICE = 24
Tv.TVSHOW_WORLD_OF_MASTERS = 25
Tv.TVSHOW_TODAYS_RIVAL_TRAINER = 26
Tv.TVSHOW_TREND_WATCHER = 27
Tv.TVSHOW_TREASURE_INVESTIGATORS = 28
Tv.TVSHOW_FIND_THAT_GAMER = 29
Tv.TVSHOW_BREAKING_NEWS = 30
Tv.TVSHOW_SECRET_BASE_VISIT = 31
Tv.TVSHOW_LOTTO_WINNER = 32
Tv.TVSHOW_BATTLE_SEMINAR = 33
Tv.TVSHOW_TRAINER_FAN_CLUB = 34
Tv.TVSHOW_CUTIES = 35
Tv.TVSHOW_FRONTIER = 36
Tv.TVSHOW_NUMBER_ONE = 37
Tv.TVSHOW_SECRET_BASE_SECRETS = 38
Tv.TVSHOW_SAFARI_FAN_CLUB = 39
Tv.TVSHOW_MASS_OUTBREAK = 41

-- pokeemerald/include/constants/tv.h:28
Tv.TVGROUP_NORMAL_START, Tv.TVGROUP_NORMAL_END = 1, 20
Tv.TVGROUP_RECORD_MIX_START, Tv.TVGROUP_RECORD_MIX_END = 21, 40
Tv.TVGROUP_OUTBREAK_START, Tv.TVGROUP_OUTBREAK_END = 41, 60
-- pokeemerald/src/tv.c:53
Tv.TVGROUP = { NONE = 0, UNUSED = 1, NORMAL = 2, RECORD_MIX = 3, OUTBREAK = 4 }

-- pokeemerald/include/constants/tv.h:4
Tv.POKENEWS_NONE = 0
Tv.POKENEWS_SLATEPORT = 1
Tv.POKENEWS_GAME_CORNER = 2
Tv.POKENEWS_LILYCOVE = 3
Tv.POKENEWS_BLENDMASTER = 4
Tv.NUM_POKENEWS_TYPES = 4
Tv.POKENEWS_STATE_INACTIVE = 0
Tv.POKENEWS_STATE_UPCOMING = 1
Tv.POKENEWS_STATE_ACTIVE = 2
Tv.POKENEWS_COUNTDOWN = 4

-- pokeemerald/include/constants/tv.h:79
Tv.PLAYERS_HOUSE_TV_NONE = 0
Tv.PLAYERS_HOUSE_TV_LATI = 1
Tv.PLAYERS_HOUSE_TV_MOVIE = 2

-- pokeemerald/include/constants/metatile_labels.h:117
Tv.METATILE_TV_OFF = 0x002
Tv.METATILE_TV_ON = 0x003

-- pokeemerald/include/constants/tv.h:84
Tv.NUM_CUTIES_RIBBONS = 4
-- pokeemerald/include/constants/tv.h:130
Tv.SBSECRETS_NUM_STATES = 43
-- pokeemerald/include/constants/tv.h:171
Tv.NUM_SECRET_BASE_FLAGS = 32

-- pokeemerald/include/constants/battle.h:100
Tv.B_OUTCOME_WON = 1
Tv.B_OUTCOME_LOST = 2
Tv.B_OUTCOME_DREW = 3
Tv.B_OUTCOME_RAN = 4
Tv.B_OUTCOME_PLAYER_TELEPORTED = 5
Tv.B_OUTCOME_MON_FLED = 6
Tv.B_OUTCOME_CAUGHT = 7
Tv.B_OUTCOME_NO_SAFARI_BALLS = 8
Tv.B_OUTCOME_FORFEITED = 9
Tv.B_OUTCOME_MON_TELEPORTED = 10

-- pokeemerald/include/pokeball.h:18
Tv.POKEBALL_COUNT = 12

-- pokeemerald/include/constants/game_stat.h:9
Tv.GAME_STAT_STEPS = 5
Tv.GAME_STAT_GOT_INTERVIEWED = 6

-- pokeemerald/include/constants/pokemon.h:97
Tv.RIBBON = {
  champion = 0, cool = 1, beauty = 5, cute = 9, smart = 13, tough = 17,
  winning = 21, victory = 22, artist = 23, effort = 24, marine = 25, land = 26, sky = 27,
  country = 28, national = 29, earth = 30, world = 31,
}
-- pokeemerald/src/tv.c:2277
Tv.RIBBON_ORDER = {
  "cool", "beauty", "cute", "smart", "tough", "champion", "winning", "victory", "artist",
  "effort", "marine", "land", "sky", "country", "national", "earth", "world",
}
-- pokeemerald/include/pokemon.h:150
local RIBBON_BITS = {
  cool = { 0, 3 }, beauty = { 3, 3 }, cute = { 6, 3 }, smart = { 9, 3 }, tough = { 12, 3 },
  champion = { 15, 1 }, winning = { 16, 1 }, victory = { 17, 1 }, artist = { 18, 1 }, effort = { 19, 1 },
  marine = { 20, 1 }, land = { 21, 1 }, sky = { 22, 1 }, country = { 23, 1 }, national = { 24, 1 },
  earth = { 25, 1 }, world = { 26, 1 },
}
-- pokeemerald/include/pokemon.h:58
local MON_DATA_RIBBON = {
  [50] = "cool", [51] = "beauty", [52] = "cute", [53] = "smart", [54] = "tough", [67] = "champion",
  [68] = "winning", [69] = "victory", [70] = "artist", [71] = "effort", [72] = "marine", [73] = "land",
  [74] = "sky", [75] = "country", [76] = "national", [77] = "earth", [78] = "world",
}

-- pokeemerald/src/tv.c:61
local SLOT_MACHINE, ROULETTE = 0, 1

Tv._curSlot = 0
Tv._showState = 0
Tv._anglerSpecies = 0
Tv._anglerCounters = 0
Tv._gamerCoinsSpent = 0
Tv._gamerWhichGame = SLOT_MACHINE
Tv._sbRandom = { 0, 0, 0 }
Tv._battleResults = nil

function Tv.resetRuntime()
  Tv._curSlot = 0
  Tv._showState = 0
  Tv._anglerSpecies = 0
  Tv._anglerCounters = 0
  Tv._gamerCoinsSpent = 0
  Tv._gamerWhichGame = SLOT_MACHINE
  Tv._sbRandom = { 0, 0, 0 }
  Tv._battleResults = nil
end

local function n(v) return tonumber(v) or 0 end

local function u16(v) return n(v) % 0x10000 end

local function nameChars(s)
  local out = {}
  for ch in tostring(s or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch end
  return out
end

local function rse()
  return require("src.core.game3.rse.init")
end

local function sessionOf(s)
  if type(s) == "table" then return s end
  local R = package.loaded["src.core.game3.rse.init"]
  return R and R.session() or nil
end

Tv.random = function()
  return require("src.core.game3.rng").Random()
end

local function random() return n(Tv.random()) end

-- pokeemerald/src/tv.c:3142
local function bernoulli(ratio)
  if random() <= ratio then return false end
  return true
end

-- pokeemerald/src/tv.c:51
local function rbernoulli(num, den)
  return bernoulli(math.floor(0xFFFF * num / den))
end
Tv.rbernoulli = rbernoulli

local function blankShow()
  return { kind = Tv.TVSHOW_OFF_AIR, active = false }
end

local function blankNews()
  return { kind = Tv.POKENEWS_NONE, state = Tv.POKENEWS_STATE_INACTIVE, dayCountdown = 0 }
end

local function copy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = copy(x) end
  return out
end
Tv.copy = copy

local function emptyWords(count)
  local out = {}
  for i = 1, count do out[i] = Tv.EC_EMPTY_WORD end
  return out
end

-- pokeemerald/src/tv.c:914
local function blankGabby()
  return {
    mon1 = 0, mon2 = 0, lastMove = 0, quote = { [0] = Tv.EC_EMPTY_WORD },
    battleTookMoreThanOneTurn = false, playerLostAMon = false, playerUsedHealingItem = false,
    playerThrewABall = false, onAir = false, valA_5 = 0,
    battleTookMoreThanOneTurn2 = false, playerLostAMon2 = false, playerUsedHealingItem2 = false,
    playerThrewABall2 = false, valB_4 = 0, mapnum = 0, battleNum = 0,
  }
end

Tv.OUTBREAK_FIELDS = {
  "outbreakPokemonSpecies", "outbreakLocationMapNum", "outbreakLocationMapGroup", "outbreakPokemonLevel",
  "outbreakUnused1", "outbreakUnused2", "outbreakPokemonMoves", "outbreakUnused3", "outbreakPokemonProbability",
  "outbreakDaysLeft",
}

-- pokeemerald/include/global.h:1036
function Tv.state(session)
  session = session or {}
  if type(session.tvShows) ~= "table" then session.tvShows = {} end
  for i = 0, Tv.TV_SHOWS_COUNT - 1 do
    if type(session.tvShows[i]) ~= "table" then session.tvShows[i] = blankShow() end
  end
  if type(session.pokeNews) ~= "table" then session.pokeNews = {} end
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    if type(session.pokeNews[i]) ~= "table" then session.pokeNews[i] = blankNews() end
  end
  if type(session.gabbyAndTyData) ~= "table" then session.gabbyAndTyData = { onAir = false } end
  if type(session.gabbyAndTyData.quote) ~= "table" then session.gabbyAndTyData.quote = { [0] = Tv.EC_EMPTY_WORD } end
  return session
end

-- pokeemerald/src/tv.c:3337
function Tv.groupOf(kind)
  kind = n(kind)
  if kind == Tv.TVSHOW_OFF_AIR then return Tv.TVGROUP.NONE end
  if kind >= Tv.TVGROUP_NORMAL_START and kind <= Tv.TVGROUP_NORMAL_END then return Tv.TVGROUP.NORMAL end
  if kind >= Tv.TVGROUP_RECORD_MIX_START and kind <= Tv.TVGROUP_RECORD_MIX_END then return Tv.TVGROUP.RECORD_MIX end
  if kind >= Tv.TVGROUP_OUTBREAK_START and kind <= Tv.TVGROUP_OUTBREAK_END then return Tv.TVGROUP.OUTBREAK end
  return Tv.TVGROUP.NONE
end

-- pokeemerald/src/tv.c:6825
function Tv.resetShowState()
  Tv._showState = 0
end

function Tv.showState()
  return Tv._showState
end

local function shows(session)
  return Tv.state(session).tvShows
end

-- pokeemerald/src/tv.c:3029
local function deleteShow(list, idx)
  local show = list[idx]
  if type(show) ~= "table" then list[idx] = blankShow() return end
  for k in pairs(show) do show[k] = nil end
  show.kind = Tv.TVSHOW_OFF_AIR
  show.active = false
end
Tv.deleteShow = deleteShow

-- pokeemerald/src/tv.c:3039
local function compactShows(list)
  for i = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - 2 do
    if n(list[i].kind) == Tv.TVSHOW_OFF_AIR then
      for j = i + 1, Tv.NUM_NORMAL_TVSHOW_SLOTS - 1 do
        if n(list[j].kind) ~= Tv.TVSHOW_OFF_AIR then
          list[i] = list[j]
          list[j] = blankShow()
          break
        end
      end
    end
  end
  for i = Tv.NUM_NORMAL_TVSHOW_SLOTS, Tv.LAST_TVSHOW_IDX - 1 do
    if n(list[i].kind) == Tv.TVSHOW_OFF_AIR then
      for j = i + 1, Tv.LAST_TVSHOW_IDX - 1 do
        if n(list[j].kind) ~= Tv.TVSHOW_OFF_AIR then
          list[i] = list[j]
          list[j] = blankShow()
          break
        end
      end
    end
  end
end
Tv.compactShows = compactShows

-- pokeemerald/src/tv.c:3118
local function firstEmptyNormalSlot(list)
  for i = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - 1 do
    if n(list[i].kind) == Tv.TVSHOW_OFF_AIR then return i end
  end
  return -1
end
Tv.firstEmptyNormalSlot = firstEmptyNormalSlot

-- pokeemerald/src/tv.c:3130
local function firstEmptyRecordMixSlot(list)
  for i = Tv.NUM_NORMAL_TVSHOW_SLOTS, Tv.LAST_TVSHOW_IDX - 1 do
    if n(list[i].kind) == Tv.TVSHOW_OFF_AIR then return i end
  end
  return -1
end
Tv.firstEmptyRecordMixSlot = firstEmptyRecordMixSlot

-- pokeemerald/src/tv.c:3354
function Tv.playerId(session)
  session = sessionOf(session) or {}
  local tid = u16(session.trainerId or session.id or session.playerId)
  local sid = u16(session.secretId)
  return tid + sid * 0x10000
end

local function playerName(session)
  session = sessionOf(session) or {}
  return tostring(session.name or session.playerName or "")
end

local function playerGender(session)
  local g = (sessionOf(session) or {}).gender
  if g == 1 or g == "female" or g == "F" then return 1 end
  return 0
end

-- pokeemerald/src/tv.c:1219
local function storeIdRecordMix(show, session)
  local id = Tv.playerId(session)
  show.srcTrainerId2Lo = id % 256
  show.srcTrainerId2Hi = math.floor(id / 256) % 256
  show.srcTrainerIdLo = id % 256
  show.srcTrainerIdHi = math.floor(id / 256) % 256
  show.trainerIdLo = id % 256
  show.trainerIdHi = math.floor(id / 256) % 256
end

-- pokeemerald/src/tv.c:1230
local function storeIdNormal(show, session)
  local id = Tv.playerId(session)
  show.srcTrainerIdLo = id % 256
  show.srcTrainerIdHi = math.floor(id / 256) % 256
  show.trainerIdLo = id % 256
  show.trainerIdHi = math.floor(id / 256) % 256
end

local function flag(name, session)
  local ok, v = pcall(rse().flag, name, session)
  return ok and v == true
end

local function setFlag(name, on, session)
  pcall(rse().setFlag, name, on, session)
end

local function var(name, session)
  local ok, v = pcall(rse().var, name, session)
  return ok and n(v) or 0
end

local function setVar(name, value, session)
  pcall(rse().setVar, name, u16(value), session)
end

local function gameStat(session, id)
  local st = (sessionOf(session) or {}).gameStats
  return type(st) == "table" and n(st[id]) or 0
end

local function incGameStat(session, id)
  session = sessionOf(session)
  if type(session) ~= "table" then return end
  if type(session.gameStats) ~= "table" then session.gameStats = {} end
  session.gameStats[id] = math.min(0xFFFFFF, n(session.gameStats[id]) + 1)
end

local function consts()
  local Constants = require("src.core.game3.constants")
  return Constants.of("emerald")
end

local function constId(kind, name)
  local ok, v = pcall(function() return consts():id(kind, name) end)
  return ok and v or nil
end

-- pokeemerald/src/overworld.c:1391
local function mapSec(session)
  session = sessionOf(session) or {}
  local sec = tonumber(session.regionMapSectionId or session.mapSec)
  if sec then return sec end
  local ok, Pokemon = pcall(require, "src.core.game3.pokemon")
  local v = ok and Pokemon.currentMapSec and Pokemon.currentMapSec(session) or nil
  return n(v)
end
Tv.mapSec = mapSec

local layoutIds = {}

-- pokeemerald/include/global.fieldmap.h:178
local function mapLayoutId(session)
  session = sessionOf(session) or {}
  if session.mapLayoutId then return n(session.mapLayoutId) end
  local g, num = rse().mapGroupNum(session.map, session)
  if not g then return 0 end
  local key = g .. "_" .. num
  if layoutIds[key] == nil then
    local cache = require("src.core.game3.dataset").cache()
    local raw = cache and cache:read("data/generated/gba/map_tree/maps/" .. key .. "/header.json")
    layoutIds[key] = tonumber(raw and raw:match('"layoutId":(%d+)')) or 0
  end
  return layoutIds[key]
end

local function speciesOf(mon)
  return mon and n(mon.species or mon.speciesId) or 0
end

local function isEgg(mon)
  return type(mon) == "table" and (mon.isEgg == true or mon.egg == true)
end

function Tv.speciesName(species)
  local f = Tv.names and Tv.names.species
  if f then return f(n(species)) end
  local ok, Pokemon = pcall(require, "src.core.game3.pokemon")
  if not ok then return "" end
  local okN, name = pcall(Pokemon.name, n(species))
  return okN and tostring(name or "") or ""
end

-- pokeemerald/src/pokemon.c:3758
local function nickname(mon)
  if type(mon) ~= "table" then return "" end
  local nick = mon.nickname
  if type(nick) == "string" and nick ~= "" then return nick end
  if type(mon.name) == "string" and mon.name ~= "" then return mon.name end
  return Tv.speciesName(speciesOf(mon))
end
Tv.nickname = nickname

local function language(mon)
  return tonumber(mon and mon.language) or Tv.GAME_LANGUAGE
end

local function party(session)
  local p = (sessionOf(session) or {}).party
  return type(p) == "table" and p or {}
end

-- pokeemerald/src/field_specials.c:1531
local function leadMonIndex(session)
  local p = party(session)
  for i = 1, #p do
    if speciesOf(p[i]) ~= 0 and not isEgg(p[i]) then return i end
  end
  return 1
end

local function leadMon(session)
  return party(session)[leadMonIndex(session)]
end

local function dex(session)
  return (sessionOf(session) or {}).dex
end

-- pokeemerald/src/pokedex.c:4263
local function seenSpecies(session, species)
  local ok, Dex = pcall(require, "src.core.game3.dex")
  if not ok then return false end
  local okS, v = pcall(Dex.isSeen, dex(session), n(species))
  return okS and v == true
end
Tv.seenSpecies = seenSpecies

-- pokeemerald/src/tv.c:2277
function Tv.ribbonCount(mon)
  if type(mon) ~= "table" then return 0 end
  local r = mon.ribbons
  local okR, Ribbons = pcall(require, "src.core.game3.rse.ribbons")
  if okR and type(Ribbons) == "table" and Ribbons.word then r = tonumber(Ribbons.word(mon)) or 0 end
  local total = 0
  for _, key in ipairs(Tv.RIBBON_ORDER) do
    local v = 0
    if type(r) == "table" then
      local x = r[key]
      v = (x == true and 1) or n(x)
    elseif type(r) == "number" then
      local b = RIBBON_BITS[key]
      v = math.floor(r / 2 ^ b[1]) % 2 ^ b[2]
    end
    if key == "champion" and v == 0 and mon.championRibbon == true then v = 1 end
    total = total + v
  end
  return total
end

-- pokeemerald/src/tv.c:2302
function Tv.ribbonOf(key)
  if type(key) == "number" then key = MON_DATA_RIBBON[key] end
  return Tv.RIBBON[key] or Tv.RIBBON.champion
end

-- pokeemerald/src/tv.c:2821
local function isRecordMixShowAlreadySpawned(session, kind, delete)
  local list = shows(session)
  local id = Tv.playerId(session)
  local lo, hi = id % 256, math.floor(id / 256) % 256
  for i = Tv.NUM_NORMAL_TVSHOW_SLOTS, Tv.LAST_TVSHOW_IDX - 1 do
    local s = list[i]
    if n(s.kind) == kind and lo == n(s.trainerIdLo) and hi == n(s.trainerIdHi) then
      if delete then
        deleteShow(list, i)
        compactShows(list)
      end
      return true
    end
  end
  return false
end
Tv.isRecordMixShowAlreadySpawned = isRecordMixShowAlreadySpawned

-- pokeemerald/src/tv.c:3108
function Tv.findEmptyNormalSlotForScript(session)
  Tv._curSlot = firstEmptyNormalSlot(shows(session))
  Tv._var8006 = Tv._curSlot == -1 and 0xFFFF or Tv._curSlot
  Tv._result = Tv._curSlot == -1
  return Tv._result
end

-- pokeemerald/src/tv.c:2867
local function tryReplaceOldShowOfKind(session, kind)
  local list = shows(session)
  for i = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - 1 do
    if n(list[i].kind) == kind then
      if list[i].active == true then
        Tv._result = true
      else
        deleteShow(list, i)
        compactShows(list)
        Tv.findEmptyNormalSlotForScript(session)
      end
      return Tv._result
    end
  end
  Tv.findEmptyNormalSlotForScript(session)
  return Tv._result
end
Tv.tryReplaceOldShowOfKind = tryReplaceOldShowOfKind

-- pokeemerald/src/tv.c:761
function Tv.clearTVShowData(session)
  local s = Tv.state(session)
  for i = 0, Tv.TV_SHOWS_COUNT - 1 do s.tvShows[i] = blankShow() end
  Tv.clearPokeNews(session)
end

-- pokeemerald/src/tv.c:914
function Tv.resetGabbyAndTy(session)
  Tv.state(session).gabbyAndTyData = blankGabby()
end

-- pokeemerald/src/new_game.c:168
function Tv.newGame(session)
  Tv.clearTVShowData(session)
  Tv.resetGabbyAndTy(session)
  Tv.endMassOutbreak(session)
  Tv.resetRuntime()
end

local function isShowOnAir(show)
  if Tv.groupOf(show.kind) ~= Tv.TVGROUP.OUTBREAK then
    return show.active == true
  end
  return n(show.daysBeforeOutbreak) == 0 and show.active == true
end

-- pokeemerald/src/tv.c:775
function Tv.getRandomActiveShowIdx(session, rand)
  local s = Tv.state(session)
  local i = Tv.NUM_NORMAL_TVSHOW_SLOTS
  while i < Tv.LAST_TVSHOW_IDX do
    if n(s.tvShows[i].kind) == Tv.TVSHOW_OFF_AIR then break end
    i = i + 1
  end
  local j = n((rand or Tv.random)()) % i
  local sel = j
  repeat
    if isShowOnAir(s.tvShows[j]) then return j end
    if j == 0 then j = Tv.TV_SHOWS_COUNT - 2 else j = j - 1 end
  until j == sel
  return 0xFF
end

-- pokeemerald/src/tv.c:887
function Tv.firstActiveNotOutbreak(session)
  local s = Tv.state(session)
  for i = 0, Tv.TV_SHOWS_COUNT - 2 do
    local show = s.tvShows[i]
    if n(show.kind) ~= Tv.TVSHOW_OFF_AIR and n(show.kind) ~= Tv.TVSHOW_MASS_OUTBREAK and show.active == true then
      return i
    end
  end
  return 0xFF
end

-- pokeemerald/src/tv.c:813
function Tv.findAnyShowOnAir(session, rand)
  local slot = Tv.getRandomActiveShowIdx(session, rand)
  if slot == 0xFF then return 0xFF end
  local s = Tv.state(session)
  if n(s.outbreakPokemonSpecies) ~= 0 and n(s.tvShows[slot].kind) == Tv.TVSHOW_MASS_OUTBREAK then
    return Tv.firstActiveNotOutbreak(session)
  end
  return slot
end

-- pokeemerald/src/tv.c:901
function Tv.nextActiveIfMassOutbreak(session, idx)
  local s = Tv.state(session)
  local show = s.tvShows[n(idx)]
  if show and n(show.kind) == Tv.TVSHOW_MASS_OUTBREAK and n(s.outbreakPokemonSpecies) ~= 0 then
    return Tv.firstActiveNotOutbreak(session)
  end
  return n(idx)
end

-- pokeemerald/src/tv.c:882
function Tv.selectedShowKind(session, idx)
  local show = Tv.state(session).tvShows[n(idx)]
  return show and n(show.kind) or Tv.TVSHOW_OFF_AIR
end

-- pokeemerald/src/tv.c:3268
function Tv.isShowAlreadyInQueue(session, kind)
  local list = shows(session)
  for i = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - 1 do
    if n(list[i].kind) == n(kind) then return true end
  end
  return false
end

-- pokeemerald/src/tv.c:1004
function Tv.isGabbyAndTyOnAir(session)
  return Tv.state(session).gabbyAndTyData.onAir == true
end

-- pokeemerald/src/tv.c:935
function Tv.gabbyAndTyBeforeInterview(session, results)
  local g = Tv.state(session).gabbyAndTyData
  results = results or Tv._battleResults or {}
  g.mon1 = n(results.playerMon1Species)
  g.mon2 = n(results.playerMon2Species)
  g.lastMove = n(results.lastUsedMovePlayer)
  if n(g.battleNum) ~= 0xFF then g.battleNum = n(g.battleNum) + 1 end
  g.battleTookMoreThanOneTurn = results.playerMonWasDamaged == true
  g.playerLostAMon = n(results.playerFaintCounter) ~= 0
  g.playerUsedHealingItem = n(results.numHealingItemsUsed) ~= 0
  if not results.usedMasterBall then
    local attempts = type(results.catchAttempts) == "table" and results.catchAttempts or {}
    for i = 1, Tv.POKEBALL_COUNT - 1 do
      if n(attempts[i]) ~= 0 then
        g.playerThrewABall = true
        break
      end
    end
  else
    g.playerThrewABall = true
  end
  g.onAir = false
  if g.lastMove == 0 then setFlag("FLAG_TEMP_SKIP_GABBY_INTERVIEW", true, session) end
end

-- pokeemerald/src/tv.c:979
function Tv.gabbyAndTyAfterInterview(session)
  local g = Tv.state(session).gabbyAndTyData
  g.battleTookMoreThanOneTurn2 = g.battleTookMoreThanOneTurn == true
  g.playerLostAMon2 = g.playerLostAMon == true
  g.playerUsedHealingItem2 = g.playerUsedHealingItem == true
  g.playerThrewABall2 = g.playerThrewABall == true
  g.onAir = true
  g.mapnum = mapSec(session)
  incGameStat(session, Tv.GAME_STAT_GOT_INTERVIEWED)
end

-- pokeemerald/src/tv.c:1105
function Tv.tryPutPokemonTodayOnAir(session, results, outcome)
  session = sessionOf(session)
  results = results or {}
  Tv.tryPutRandomPokeNewsOnAir(session)
  Tv.tryStartRandomMassOutbreak(session)
  local caught = n(results.caughtMonSpecies)
  if caught == 0 then
    Tv.tryPutPokemonTodayFailedOnTheAir(session, results, outcome)
    return
  end
  Tv.initWorldOfMastersShowAttempt(session, results)
  if not rbernoulli(1, 1) and Tv.speciesName(caught) ~= tostring(results.caughtMonNick or "") then
    local list = shows(session)
    Tv._curSlot = firstEmptyRecordMixSlot(list)
    if Tv._curSlot ~= -1 and not isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_POKEMON_TODAY_CAUGHT, false) then
      local attempts = type(results.catchAttempts) == "table" and results.catchAttempts or {}
      local balls = 0
      for i = 1, Tv.POKEBALL_COUNT - 1 do balls = balls + n(attempts[i]) end
      if balls ~= 0 or results.usedMasterBall then
        local show = list[Tv._curSlot]
        show.kind = Tv.TVSHOW_POKEMON_TODAY_CAUGHT
        show.active = false
        local ball
        if results.usedMasterBall then
          balls = 1
          ball = constId("items", "ITEM_MASTER_BALL") or 1
        else
          if balls > 255 then balls = 255 end
          ball = n(results.lastUsedItem)
        end
        show.nBallsUsed = balls
        show.ball = ball
        show.playerName = playerName(session)
        show.nickname = tostring(results.caughtMonNick or "")
        show.species = caught
        storeIdRecordMix(show, session)
        show.language = Tv.GAME_LANGUAGE
        show.language2 = Tv.GAME_LANGUAGE
      end
    end
  end
end

-- pokeemerald/src/tv.c:1170
function Tv.initWorldOfMastersShowAttempt(session, results)
  local list = shows(session)
  local show = list[Tv.LAST_TVSHOW_IDX]
  if n(show.kind) ~= Tv.TVSHOW_WORLD_OF_MASTERS then
    deleteShow(list, Tv.LAST_TVSHOW_IDX)
    show = list[Tv.LAST_TVSHOW_IDX]
    show.steps = u16(gameStat(session, Tv.GAME_STAT_STEPS))
    show.kind = Tv.TVSHOW_WORLD_OF_MASTERS
  end
  show.numPokeCaught = u16(n(show.numPokeCaught) + 1)
  show.caughtPoke = n(results.caughtMonSpecies)
  show.species = n(results.playerMon1Species)
  show.location = mapSec(session)
end

-- pokeemerald/src/tv.c:1185
function Tv.tryPutPokemonTodayFailedOnTheAir(session, results, outcome)
  results = results or {}
  if rbernoulli(1, 1) then return end
  local attempts = type(results.catchAttempts) == "table" and results.catchAttempts or {}
  local balls = 0
  for i = 1, Tv.POKEBALL_COUNT - 1 do balls = balls + n(attempts[i]) end
  if balls > 255 then balls = 255 end
  outcome = n(outcome)
  if balls > 2 and (outcome == Tv.B_OUTCOME_MON_FLED or outcome == Tv.B_OUTCOME_WON) then
    local list = shows(session)
    Tv._curSlot = firstEmptyRecordMixSlot(list)
    if Tv._curSlot ~= -1 and not isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_POKEMON_TODAY_FAILED, false) then
      local show = list[Tv._curSlot]
      show.kind = Tv.TVSHOW_POKEMON_TODAY_FAILED
      show.active = false
      show.species = n(results.playerMon1Species)
      show.species2 = n(results.lastOpponentSpecies)
      show.nBallsUsed = balls
      show.outcome = outcome
      show.location = mapSec(session)
      show.playerName = playerName(session)
      storeIdRecordMix(show, session)
      show.language = Tv.GAME_LANGUAGE
    end
  end
end

-- pokeemerald/src/tv.c:1239
local function interviewAfterContestLiveUpdates(session, ctxv)
  local list = shows(session)
  local show = list[Tv.LAST_TVSHOW_IDX]
  if n(show.kind) ~= Tv.TVSHOW_CONTEST_LIVE_UPDATES then return end
  local show2 = list[Tv._curSlot]
  if not show2 then return end
  show2.kind = Tv.TVSHOW_CONTEST_LIVE_UPDATES
  show2.active = true
  show2.winningTrainerName = playerName(session)
  show2.category = n(ctxv.contestCategory)
  show2.winningSpecies = speciesOf(ctxv.contestMon)
  show2.losingSpecies = n(show.losingSpecies)
  show2.loserAppealFlag = n(show.loserAppealFlag)
  show2.round1Placing = n(show.round1Placing)
  show2.round2Placing = n(show.round2Placing)
  show2.move = n(show.move)
  show2.winnerAppealFlag = n(show.winnerAppealFlag)
  show2.losingTrainerName = tostring(show.losingTrainerName or "")
  storeIdNormal(show2, session)
  show2.winningTrainerLanguage = Tv.GAME_LANGUAGE
  show2.losingTrainerLanguage = n(show.losingTrainerLanguage)
  deleteShow(list, Tv.LAST_TVSHOW_IDX)
end

-- pokeemerald/src/tv.c:1267
function Tv.putBattleUpdateOnTheAir(session, opponentName, move, speciesPlayer, speciesOpponent, battleType, opponentLanguage)
  local list = shows(session)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot == -1 then return false end
  if tryReplaceOldShowOfKind(session, Tv.TVSHOW_BATTLE_UPDATE) == true then return false end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_BATTLE_UPDATE
  show.active = true
  show.playerName = playerName(session)
  show.battleType = n(battleType)
  show.move = n(move)
  show.speciesPlayer = n(speciesPlayer)
  show.speciesOpponent = n(speciesOpponent)
  show.linkOpponentName = tostring(opponentName or "")
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.linkOpponentLanguage = tonumber(opponentLanguage) or Tv.GAME_LANGUAGE
  return true
end

-- pokeemerald/src/tv.c:1306
function Tv.put3CheersForPokeblocksOnTheAir(session, partnersName, flavor, color, sheen, lang)
  local list = shows(session)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot == -1 then return false end
  if tryReplaceOldShowOfKind(session, Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS) == true then return false end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS
  show.active = true
  show.playerName = playerName(session)
  show.worstBlenderName = tostring(partnersName or "")
  show.flavor = n(flavor) % 8
  show.color = n(color) % 4
  show.sheen = n(sheen) % 256
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.worstBlenderLanguage = tonumber(lang) or Tv.GAME_LANGUAGE
  return true
end

-- pokeemerald/src/tv.c:1338
function Tv.putFanClubSpecialOnTheAir(session, slot, score, idolName, idolLanguage)
  local list = shows(session)
  local show = list[n(slot)]
  if not show then return false end
  show.score = (n(score) * 10) % 256
  show.playerName = playerName(session)
  show.kind = Tv.TVSHOW_FAN_CLUB_SPECIAL
  show.active = true
  local id = Tv.playerId(session)
  show.idLo = id % 256
  show.idHi = math.floor(id / 256) % 256
  show.idolName = tostring(idolName or "")
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.idolNameLanguage = tonumber(idolLanguage) or Tv.GAME_LANGUAGE
  return true
end

-- pokeemerald/src/tv.c:1363
function Tv.contestLiveUpdatesInit(session, round1Placing)
  local list = shows(session)
  deleteShow(list, Tv.LAST_TVSHOW_IDX)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot ~= -1 then
    local show = list[Tv.LAST_TVSHOW_IDX]
    show.round1Placing = n(round1Placing)
    show.kind = Tv.TVSHOW_CONTEST_LIVE_UPDATES
  end
end

local function liveUpdatesField(session, field, value)
  local list = shows(session)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot ~= -1 then list[Tv.LAST_TVSHOW_IDX][field] = value end
end

-- pokeemerald/src/tv.c:1377
function Tv.contestLiveUpdatesSetRound2Placing(session, placing)
  liveUpdatesField(session, "round2Placing", n(placing))
end

-- pokeemerald/src/tv.c:1385
function Tv.contestLiveUpdatesSetWinnerAppealFlag(session, flagValue)
  liveUpdatesField(session, "winnerAppealFlag", n(flagValue))
end

-- pokeemerald/src/tv.c:1393
function Tv.contestLiveUpdatesSetWinnerMoveUsed(session, move)
  liveUpdatesField(session, "move", n(move))
end

-- pokeemerald/src/tv.c:1401
function Tv.contestLiveUpdatesSetLoserData(session, flagValue, loserSpecies, loserTrainerName, loserLanguage)
  local list = shows(session)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot == -1 then return end
  local show = list[Tv.LAST_TVSHOW_IDX]
  show.losingSpecies = n(loserSpecies)
  show.losingTrainerName = tostring(loserTrainerName or "")
  show.loserAppealFlag = n(flagValue)
  show.losingTrainerLanguage = tonumber(loserLanguage) or Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1421
local function interviewAfterBravoTrainerPokemonProfile(session)
  local list = shows(session)
  local show = list[Tv.LAST_TVSHOW_IDX]
  if n(show.kind) ~= Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE then return end
  local show2 = list[Tv._curSlot]
  if not show2 then return end
  show2.kind = Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE
  show2.active = true
  show2.species = n(show.species)
  show2.playerName = playerName(session)
  show2.pokemonNickname = tostring(show.pokemonNickname or "")
  show2.contestCategory = n(show.contestCategory)
  show2.contestRank = n(show.contestRank)
  show2.move = n(show.move)
  show2.contestResult = n(show.contestResult)
  storeIdNormal(show2, session)
  show2.language = Tv.GAME_LANGUAGE
  show2.pokemonNameLanguage = tonumber(show.pokemonNameLanguage) or Tv.GAME_LANGUAGE
  deleteShow(list, Tv.LAST_TVSHOW_IDX)
end

-- pokeemerald/src/tv.c:2976
local function interviewBeforeBravoTrainerPkmnProfile(session)
  tryReplaceOldShowOfKind(session, Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE)
  if not Tv._result then shows(session)[Tv._curSlot].words = emptyWords(2) end
end

-- pokeemerald/src/tv.c:1450
function Tv.bravoTrainerPokemonProfileBeforeInterview1(session, move)
  local list = shows(session)
  Tv._result = false
  interviewBeforeBravoTrainerPkmnProfile(session)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot ~= -1 then
    deleteShow(list, Tv.LAST_TVSHOW_IDX)
    local show = list[Tv.LAST_TVSHOW_IDX]
    show.move = n(move)
    show.kind = Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE
  end
end

-- pokeemerald/src/tv.c:1463
function Tv.bravoTrainerPokemonProfileBeforeInterview2(session, place, category, rank, mon)
  local list = shows(session)
  Tv._curSlot = firstEmptyNormalSlot(list)
  if Tv._curSlot == -1 then return end
  local show = list[Tv.LAST_TVSHOW_IDX]
  show.contestResult = n(place) % 4
  show.contestCategory = n(category) % 8
  show.contestRank = n(rank) % 4
  show.species = speciesOf(mon)
  show.pokemonNickname = nickname(mon)
  show.pokemonNameLanguage = language(mon)
end

-- pokeemerald/src/tv.c:1479
local function interviewAfterBravoTrainerBattleTowerProfile(session, ctxv)
  local show = shows(session)[Tv._curSlot]
  if not show then return end
  local row = rse().profile(session)
  local policy = row and row.tv
  local iv = policy and policy.towerInterview and policy.towerInterview(session) or ctxv.towerInterview or {}
  show.kind = Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE
  show.active = true
  show.playerName = playerName(session)
  show.opponentName = tostring(iv.opponentName or "")
  show.species = n(iv.playerSpecies)
  show.defeatedSpecies = n(iv.opponentSpecies)
  show.numFights = n(iv.numFights)
  show.wonTheChallenge = iv.wonTheChallenge == true or iv.wonTheChallenge == 1
  show.battleOutcome = iv.battleOutcome
  -- pokeemerald/include/constants/battle_frontier.h:51
  show.btLevel = n(iv.lvlMode) == 0 and 50 or 100
  show.interviewResponse = n(ctxv.var8004)
  storeIdNormal(show, session)
  show.playerLanguage = Tv.GAME_LANGUAGE
  if policy and policy.towerInterview then
    show.opponentLanguage = nil
  else
    show.opponentLanguage = tonumber(iv.opponentLanguage) or Tv.GAME_LANGUAGE
  end
end

-- pokeemerald/src/tv.c:2846
local function sortPurchasesByQuantity(history)
  for i = 1, Tv.SMARTSHOPPER_NUM_ITEMS - 1 do
    for j = i + 1, Tv.SMARTSHOPPER_NUM_ITEMS do
      local a, b = history[i] or {}, history[j] or {}
      if n(a.quantity) < n(b.quantity) then history[i], history[j] = b, a end
    end
  end
end

-- pokeemerald/src/tv.c:1503
function Tv.tryPutSmartShopperOnAir(session, history)
  session = sessionOf(session)
  local m = session and session.map
  if m == "EM_TRAINER_HILL_ENTRANCE" or m == "EM_BATTLE_FRONTIER_MART" then return end
  if rbernoulli(1, 3) then return end
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_SMART_SHOPPER, false) then return end
  history = history or {}
  sortPurchasesByQuantity(history)
  if n(history[1] and history[1].quantity) < 20 then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_SMART_SHOPPER
  show.active = false
  show.shopLocation = mapSec(session)
  show.itemIds, show.itemAmounts = {}, {}
  for i = 1, Tv.SMARTSHOPPER_NUM_ITEMS do
    show.itemIds[i] = n(history[i] and history[i].itemId)
    show.itemAmounts[i] = n(history[i] and history[i].quantity)
  end
  show.priceReduced = Tv.isPokeNewsActive(session, Tv.POKENEWS_SLATEPORT, Tv.shouldApplyPokeNews) and 1 or 0
  show.playerName = playerName(session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:3086
function Tv.randomDifferentSpeciesSeen(session, excluded)
  local C = consts()
  local numSpecies = n(C.species and C.species.byName and C.species.byName.NUM_SPECIES)
  if numSpecies <= 1 then numSpecies = 412 end
  local species = random() % (numSpecies - 1) + 1
  local init = species
  while not seenSpecies(session, species) or species == n(excluded) do
    if species == 1 then species = numSpecies - 1 else species = species - 1 end
    if species == init then return n(excluded) end
  end
  return species
end

-- pokeemerald/src/tv.c:1536
function Tv.putNameRaterShowOnTheAir(session, monIndex)
  Tv._result = false
  tryReplaceOldShowOfKind(session, Tv.TVSHOW_NAME_RATER_SHOW)
  if Tv._result == true then return false end
  local mon = party(session)[n(monIndex) + 1]
  local nick = nickname(mon)
  if #nameChars(playerName(session)) <= 1 or #nameChars(nick) <= 1 then return false end
  local show = shows(session)[Tv._curSlot]
  show.kind = Tv.TVSHOW_NAME_RATER_SHOW
  show.active = true
  show.species = speciesOf(mon)
  show.random = random() % 3
  show.random2 = random() % 2
  show.randomSpecies = Tv.randomDifferentSpeciesSeen(session, show.species)
  show.trainerName = playerName(session)
  show.pokemonName = nick
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.pokemonNameLanguage = language(mon)
  return true
end

-- pokeemerald/src/tv.c:3280
function Tv.tryPutNameRaterShowOnTheAir(session, monIndex, oldNickname)
  local mon = party(session)[n(monIndex) + 1]
  if tostring(oldNickname or "") == nickname(mon) then return false end
  Tv.putNameRaterShowOnTheAir(session, monIndex)
  return true
end

local function mapIdOf(group, num)
  local C = consts()
  for name, e in pairs(C.map_groups.byName) do
    if n(e.group) == n(group) and n(e.num) == n(num) then return "EM_" .. name:sub(5) end
  end
  return nil
end
Tv.mapIdOf = mapIdOf

-- pokeemerald/src/wild_encounter.c:481
function Tv.syncOutbreak(session)
  if type(session) ~= "table" then return nil end
  local species = n(session.outbreakPokemonSpecies)
  if species == 0 then
    session.outbreak = nil
    return nil
  end
  local moves = {}
  for i = 1, 4 do moves[i] = n(session.outbreakPokemonMoves and session.outbreakPokemonMoves[i]) end
  session.outbreak = {
    species = species,
    level = n(session.outbreakPokemonLevel),
    moves = moves,
    map = mapIdOf(session.outbreakLocationMapGroup, session.outbreakLocationMapNum),
    probability = n(session.outbreakPokemonProbability),
  }
  return session.outbreak
end

-- pokeemerald/src/tv.c:1563
function Tv.startMassOutbreak(session, idx)
  session = sessionOf(session)
  local show = shows(session)[n(idx)]
  if not show then return end
  session.outbreakPokemonSpecies = n(show.species)
  session.outbreakLocationMapNum = n(show.locationMapNum)
  session.outbreakLocationMapGroup = n(show.locationMapGroup)
  session.outbreakPokemonLevel = n(show.level)
  session.outbreakUnused1 = n(show.unused1)
  session.outbreakUnused2 = n(show.unused2)
  session.outbreakPokemonMoves = {}
  for i = 1, 4 do session.outbreakPokemonMoves[i] = n(show.moves and show.moves[i]) end
  session.outbreakUnused3 = n(show.unused3)
  session.outbreakPokemonProbability = n(show.probability)
  session.outbreakDaysLeft = 2
  Tv.syncOutbreak(session)
end

-- pokeemerald/src/tv.c:1690
function Tv.endMassOutbreak(session)
  session = sessionOf(session)
  if type(session) ~= "table" then return end
  session.outbreakPokemonSpecies = 0
  session.outbreakLocationMapNum = 0
  session.outbreakLocationMapGroup = 0
  session.outbreakPokemonLevel = 0
  session.outbreakUnused1 = 0
  session.outbreakUnused2 = 0
  session.outbreakPokemonMoves = { 0, 0, 0, 0 }
  session.outbreakUnused3 = 0
  session.outbreakPokemonProbability = 0
  session.outbreakDaysLeft = 0
  Tv.syncOutbreak(session)
end

-- pokeemerald/src/tv.c:1581
function Tv.putLilycoveContestLadyShowOnTheAir(session, lady)
  Tv.findEmptyNormalSlotForScript(session)
  if Tv._result == true then return false end
  lady = lady or {}
  local show = shows(session)[Tv._curSlot]
  show.language = tonumber(lady.language) or Tv.GAME_LANGUAGE
  show.pokemonNameLanguage = Tv.GAME_LANGUAGE
  show.kind = Tv.TVSHOW_LILYCOVE_CONTEST_LADY
  show.active = true
  show.playerName = tostring(lady.playerName or "")
  show.contestCategory = n(lady.contestCategory)
  show.nickname = tostring(lady.nickname or "")
  show.pokeblockState = n(lady.pokeblockState)
  storeIdNormal(show, session)
  return true
end

-- pokeemerald/src/tv.c:1600
local function interviewAfterFanClubLetter(session)
  local show = shows(session)[Tv._curSlot]
  if not show then return end
  show.kind = Tv.TVSHOW_FAN_CLUB_LETTER
  show.active = true
  show.playerName = playerName(session)
  show.species = speciesOf(leadMon(session))
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1611
local function interviewAfterRecentHappenings(session)
  local show = shows(session)[Tv._curSlot]
  if not show then return end
  show.kind = Tv.TVSHOW_RECENT_HAPPENINGS
  show.active = true
  show.playerName = playerName(session)
  show.species = 0
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1622
local function interviewAfterPkmnFanClubOpinions(session, ctxv)
  local show = shows(session)[Tv._curSlot]
  if not show then return end
  local mon = leadMon(session)
  show.kind = Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS
  show.active = true
  local friendship = n(mon and (mon.friendship or mon.happiness))
  show.friendshipHighNybble = math.floor(friendship / 16) % 16
  show.questionAsked = n(ctxv.var8007) % 16
  show.playerName = playerName(session)
  show.nickname = nickname(mon)
  show.species = speciesOf(mon)
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.pokemonNameLanguage = language(mon)
end

-- pokeemerald/src/tv.c:1646
function Tv.tryStartRandomMassOutbreak(session, list)
  if not flag("FLAG_SYS_GAME_CLEAR", session) then return end
  local tvShows = shows(session)
  for i = 0, Tv.LAST_TVSHOW_IDX - 1 do
    if n(tvShows[i].kind) == Tv.TVSHOW_MASS_OUTBREAK then return end
  end
  if rbernoulli(1, 200) then return end
  Tv._curSlot = firstEmptyNormalSlot(tvShows)
  if Tv._curSlot == -1 then return end
  list = list or Tv.outbreakSpeciesList()
  if type(list) ~= "table" or #list == 0 then return end
  local e = list[random() % #list + 1]
  local show = tvShows[Tv._curSlot]
  show.kind = Tv.TVSHOW_MASS_OUTBREAK
  show.active = true
  show.level = n(e.level)
  show.unused1 = 0
  show.unused3 = 0
  show.species = n(e.species)
  show.unused2 = 0
  show.moves = {}
  for i = 1, 4 do show.moves[i] = n(e.moves and e.moves[i]) end
  show.locationMapNum = n(e.location)
  show.locationMapGroup = 0
  show.unused4 = 0
  show.probability = 50
  show.unused5 = 0
  show.daysBeforeOutbreak = 1
  storeIdNormal(show, session)
  show.language = Tv.GAME_LANGUAGE
  return Tv._curSlot
end

-- pokeemerald/src/tv.c:1716
local function updateTimeBeforeMassOutbreak(session, days)
  if n(session.outbreakPokemonSpecies) ~= 0 then return end
  local list = shows(session)
  for i = 0, Tv.LAST_TVSHOW_IDX - 1 do
    local show = list[i]
    if n(show.kind) == Tv.TVSHOW_MASS_OUTBREAK and show.active == true then
      if n(show.daysBeforeOutbreak) < days then
        show.daysBeforeOutbreak = 0
      else
        show.daysBeforeOutbreak = n(show.daysBeforeOutbreak) - days
      end
      break
    end
  end
end

-- pokeemerald/src/tv.c:1739
local function tryEndMassOutbreak(session, days)
  if n(session.outbreakDaysLeft) <= days then
    Tv.endMassOutbreak(session)
  else
    session.outbreakDaysLeft = n(session.outbreakDaysLeft) - days
  end
end

-- pokeemerald/src/tv.c:1747
function Tv.recordFishingAttempt(session, caughtFish)
  local c = Tv._anglerCounters
  if caughtFish then
    if math.floor(c / 256) > 4 then Tv.tryPutFishingAdviceOnAir(session) end
    c = Tv._anglerCounters % 256
    if c ~= 0xFF then c = c + 1 end
    Tv._anglerCounters = math.floor(Tv._anglerCounters / 256) * 256 + c
  else
    if c % 256 > 4 then Tv.tryPutFishingAdviceOnAir(session) end
    local hi = math.floor(Tv._anglerCounters / 256)
    if hi ~= 0xFF then hi = hi + 1 end
    Tv._anglerCounters = hi * 256
  end
end

-- pokeemerald/src/tv.c:1769
function Tv.tryPutFishingAdviceOnAir(session)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_FISHING_ADVICE, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_FISHING_ADVICE
  show.active = false
  show.nBites = Tv._anglerCounters % 256
  show.nFails = math.floor(Tv._anglerCounters / 256) % 256
  show.species = Tv._anglerSpecies
  show.playerName = playerName(session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1788
function Tv.setPokemonAnglerSpecies(species)
  Tv._anglerSpecies = n(species)
end

-- pokeemerald/src/tv.c:1809
local function tryPutWorldOfMastersOnAir(session)
  local list = shows(session)
  local show = list[Tv.LAST_TVSHOW_IDX]
  if rbernoulli(1, 1) then return end
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_WORLD_OF_MASTERS, false) then return end
  local show2 = list[Tv._curSlot]
  show2.kind = Tv.TVSHOW_WORLD_OF_MASTERS
  show2.active = false
  show2.numPokeCaught = n(show.numPokeCaught)
  show2.steps = u16(gameStat(session, Tv.GAME_STAT_STEPS) - n(show.steps))
  show2.caughtPoke = n(show.caughtPoke)
  show2.species = n(show.species)
  show2.location = n(show.location)
  show2.playerName = playerName(session)
  storeIdRecordMix(show2, session)
  show2.language = Tv.GAME_LANGUAGE
  deleteShow(list, Tv.LAST_TVSHOW_IDX)
end

-- pokeemerald/src/tv.c:1797
local function resolveWorldOfMastersShow(session)
  local list = shows(session)
  if n(list[Tv.LAST_TVSHOW_IDX].kind) == Tv.TVSHOW_WORLD_OF_MASTERS then
    if n(list[Tv.LAST_TVSHOW_IDX].numPokeCaught) >= 20 then tryPutWorldOfMastersOnAir(session) end
    deleteShow(list, Tv.LAST_TVSHOW_IDX)
  end
end

local function symbolCount(session, names)
  local c = 0
  for _, name in ipairs(names or {}) do
    if flag(name, session) then c = c + 1 end
  end
  return c
end

local function dexCaughtCount(session)
  local ok, Dex = pcall(require, "src.core.game3.dex")
  if not ok then return 0 end
  local d = dex(session)
  if not d then return 0 end
  local okN, national = pcall(Dex.nationalEnabled, session)
  local C = consts()
  local numSpecies = n(C.species.byName.NUM_SPECIES)
  local count = 0
  for sp = 1, numSpecies - 1 do
    if Dex.isCaught(d, sp) and (okN and national or Dex.inRegional(sp, "emerald")) then count = count + 1 end
  end
  return count
end

-- pokeemerald/src/tv.c:1836
function Tv.tryPutTodaysRivalTrainerOnAir(session)
  session = sessionOf(session)
  isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_TODAYS_RIVAL_TRAINER, true)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_TODAYS_RIVAL_TRAINER
  show.active = false
  local badges = 0
  for i = 1, 8 do
    if flag(string.format("FLAG_BADGE%02d_GET", i), session) then badges = badges + 1 end
  end
  show.badgeCount = badges
  show.dexCount = dexCaughtCount(session)
  show.location = mapSec(session)
  show.mapLayoutId = mapLayoutId(session)
  local data = Tv.data()
  show.nSilverSymbols = symbolCount(session, data and data.silverSymbolFlags)
  show.nGoldSymbols = symbolCount(session, data and data.goldSymbolFlags)
  local frontier = type(session) == "table" and session.frontier or nil
  show.battlePoints = n(type(frontier) == "table" and frontier.battlePoints)
  show.playerName = playerName(session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1878
function Tv.tryPutTrendWatcherOnAir(session, words)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_TREND_WATCHER, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_TREND_WATCHER
  show.active = false
  show.gender = playerGender(session)
  show.words = { n(words and words[1]), n(words and words[2]) }
  show.playerName = playerName(session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1897
function Tv.tryPutTreasureInvestigatorsOnAir(session, item)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_TREASURE_INVESTIGATORS, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_TREASURE_INVESTIGATORS
  show.active = false
  show.item = n(item)
  show.location = mapSec(session)
  show.mapLayoutId = mapLayoutId(session)
  show.playerName = playerName(session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1916
function Tv.tryPutFindThatGamerOnAir(session, paidOut)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_FIND_THAT_GAMER, false) then return end
  paidOut = n(paidOut)
  local spent = Tv._gamerCoinsSpent
  local won, coins = false, 0
  if Tv._gamerWhichGame == SLOT_MACHINE then
    if paidOut >= spent + 200 then
      won, coins = true, paidOut - spent
    elseif spent >= 100 and paidOut <= spent - 100 then
      coins = spent - paidOut
    else
      return
    end
  elseif Tv._gamerWhichGame == ROULETTE then
    if paidOut >= spent + 50 then
      won, coins = true, paidOut - spent
    elseif spent >= 50 and paidOut <= spent - 50 then
      coins = spent - paidOut
    else
      return
    end
  else
    return
  end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_FIND_THAT_GAMER
  show.active = false
  show.nCoins = u16(coins)
  show.whichGame = Tv._gamerWhichGame
  show.won = won
  show.playerName = playerName(session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:1969
function Tv.alertPlayedSlotMachine(coinsSpent)
  Tv._gamerWhichGame = SLOT_MACHINE
  Tv._gamerCoinsSpent = n(coinsSpent)
end

-- pokeemerald/src/tv.c:1975
function Tv.alertPlayedRoulette(coinsSpent)
  Tv._gamerWhichGame = ROULETTE
  Tv._gamerCoinsSpent = n(coinsSpent)
end

-- pokeemerald/src/tv.c:1981
local function secretBaseVisitDecorations(show, decorations)
  local buf = {}
  local count = 0
  for i = 1, #decorations do
    local d = n(decorations[i])
    if d ~= 0 then
      for j = 1, #decorations do
        if buf[j] == nil or buf[j] == 0 then
          buf[j] = d
          count = count + 1
          break
        end
        if buf[j] == d then break end
      end
    end
  end
  show.numDecorations = math.min(count, 4)
  show.decorations = {}
  if show.numDecorations == 1 then
    show.decorations[1] = buf[1]
  elseif show.numDecorations > 1 then
    for _ = 1, count * count do
      local a = random() % count + 1
      local b = random() % count + 1
      buf[a], buf[b] = buf[b], buf[a]
    end
    for i = 1, show.numDecorations do show.decorations[i] = buf[i] end
  end
end

-- pokeemerald/src/tv.c:2044
local function secretBaseVisitParty(show, session)
  local mons = {}
  for _, mon in ipairs(party(session)) do
    if speciesOf(mon) ~= 0 and not isEgg(mon) then
      local moves = {}
      for i = 1, 4 do
        local mv = n(mon.moves and mon.moves[i])
        if mv ~= 0 then moves[#moves + 1] = mv end
      end
      mons[#mons + 1] = { level = n(mon.level), species = speciesOf(mon), move = moves[random() % math.max(1, #moves) + 1] or 0 }
    end
  end
  if #mons == 0 then return end
  local sum = 0
  for _, m in ipairs(mons) do sum = sum + m.level end
  show.avgLevel = math.floor(sum / #mons)
  local j = random() % #mons + 1
  show.species = mons[j].species
  show.move = mons[j].move
end

-- pokeemerald/src/tv.c:2102
function Tv.tryPutSecretBaseVisitOnAir(session, decorations)
  session = sessionOf(session)
  isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_SECRET_BASE_VISIT, true)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 then return end
  if decorations == nil then
    local bases = type(session) == "table" and session.secretBases or nil
    local own = type(bases) == "table" and (bases[0] or bases[1]) or nil
    decorations = type(own) == "table" and own.decorations or {}
  end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_SECRET_BASE_VISIT
  show.active = false
  show.playerName = playerName(session)
  secretBaseVisitDecorations(show, decorations)
  secretBaseVisitParty(show, session)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2121
function Tv.tryPutBreakingNewsOnAir(session, results, outcome)
  results = results or {}
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_BREAKING_NEWS, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_BREAKING_NEWS
  show.active = false
  local attempts = type(results.catchAttempts) == "table" and results.catchAttempts or {}
  local balls = 0
  for i = 1, Tv.POKEBALL_COUNT - 1 do balls = balls + n(attempts[i]) end
  if results.usedMasterBall then balls = balls + 1 end
  show.location = mapSec(session)
  show.playerName = playerName(session)
  show.poke1Species = n(results.playerMon1Species)
  outcome = n(outcome)
  if outcome == Tv.B_OUTCOME_LOST or outcome == Tv.B_OUTCOME_DREW then
    show.kind = Tv.TVSHOW_OFF_AIR
    return
  elseif outcome == Tv.B_OUTCOME_CAUGHT then
    show.outcome = 0
  elseif outcome == Tv.B_OUTCOME_WON then
    show.outcome = 1
  elseif outcome == Tv.B_OUTCOME_RAN or outcome == Tv.B_OUTCOME_PLAYER_TELEPORTED or outcome == Tv.B_OUTCOME_NO_SAFARI_BALLS then
    show.outcome = 2
  elseif outcome == Tv.B_OUTCOME_MON_FLED or outcome == Tv.B_OUTCOME_MON_TELEPORTED then
    show.outcome = 3
  end
  show.lastOpponentSpecies = n(results.lastOpponentSpecies)
  if n(show.outcome) == 0 then
    if results.usedMasterBall then
      show.caughtMonBall = constId("items", "ITEM_MASTER_BALL") or 1
    else
      show.caughtMonBall = n(results.caughtMonBall)
    end
    show.balls = balls
  elseif n(show.outcome) == 1 then
    show.lastUsedMove = n(results.lastUsedMovePlayer)
  end
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2186
function Tv.tryPutLotteryWinnerReportOnAir(session, prizeIndex, item)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_LOTTO_WINNER, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_LOTTO_WINNER
  show.active = false
  show.playerName = playerName(session)
  show.whichPrize = (4 - n(prizeIndex)) % 256
  show.item = n(item)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2204
function Tv.tryPutBattleSeminarOnAir(session, foeSpecies, species, moveIndex, moves, betterMove)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_BATTLE_SEMINAR, false) then return end
  moves = moves or {}
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_BATTLE_SEMINAR
  show.active = false
  show.playerName = playerName(session)
  show.foeSpecies = n(foeSpecies)
  show.species = n(species)
  show.move = n(moves[n(moveIndex) + 1])
  show.otherMoves = {}
  local j = 0
  for i = 0, 3 do
    if i ~= n(moveIndex) and n(moves[i + 1]) ~= 0 then
      j = j + 1
      show.otherMoves[j] = n(moves[i + 1])
    end
  end
  show.nOtherMoves = j
  show.betterMove = n(betterMove)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2235
function Tv.tryPutSafariFanClubOnAir(session, monsCaught, pokeblocksUsed)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_SAFARI_FAN_CLUB, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_SAFARI_FAN_CLUB
  show.active = false
  show.playerName = playerName(session)
  show.monsCaught = n(monsCaught) % 256
  show.pokeblocksUsed = n(pokeblocksUsed) % 256
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2253
function Tv.tryPutSpotTheCutiesOnAir(session, mon, ribbon)
  session = sessionOf(session)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_CUTIES, false) then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_CUTIES
  show.active = false
  show.playerName = playerName(session)
  show.nickname = nickname(mon)
  show.nRibbons = Tv.ribbonCount(mon)
  show.selectedRibbon = Tv.ribbonOf(ribbon)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.pokemonNameLanguage = language(mon)
end

Tv.putSpotTheCutiesOnAir = Tv.tryPutSpotTheCutiesOnAir

-- pokeemerald/src/tv.c:2324
function Tv.tryPutTrainerFanClubOnAir(session)
  session = sessionOf(session)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 or isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_TRAINER_FAN_CLUB, false) then return end
  local show = list[Tv._curSlot]
  local profile = type(session) == "table" and session.easyChatProfile or {}
  show.kind = Tv.TVSHOW_TRAINER_FAN_CLUB
  show.active = false
  show.playerName = playerName(session)
  show.words = { n(profile[1]), n(profile[2]) }
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2342
function Tv.shouldHideFanClubInterviewer(session)
  session = sessionOf(session)
  Tv._curSlot = firstEmptyNormalSlot(shows(session))
  Tv._result = false
  if Tv._curSlot == -1 then return true end
  tryReplaceOldShowOfKind(session, Tv.TVSHOW_FAN_CLUB_SPECIAL)
  if Tv._result == true then return true end
  local recs = type(session) == "table" and session.linkBattleRecords or nil
  local entries = type(recs) == "table" and (recs.entries or recs) or nil
  local first = type(entries) == "table" and (entries[1] or entries[0]) or nil
  if type(first) ~= "table" or tostring(first.name or "") == "" then return true end
  return false
end

-- pokeemerald/src/tv.c:2358
function Tv.shouldAirFrontierTVShow(session)
  local list = shows(session)
  if isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_FRONTIER, false) then
    local id = Tv.playerId(session)
    for i = Tv.NUM_NORMAL_TVSHOW_SLOTS, Tv.LAST_TVSHOW_IDX - 1 do
      local s = list[i]
      if n(s.kind) == Tv.TVSHOW_FRONTIER and id % 256 == n(s.trainerIdLo)
          and math.floor(id / 256) % 256 == n(s.trainerIdHi) then
        deleteShow(list, i)
        compactShows(list)
        return true
      end
    end
  end
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  return Tv._curSlot ~= -1
end

-- pokeemerald/include/constants/battle_frontier.h:87
Tv.FRONTIER_SHOW_TOWER_DOUBLES = 2
Tv.FRONTIER_SHOW_TOWER_MULTIS = 3
Tv.FRONTIER_SHOW_TOWER_LINK_MULTIS = 4

-- pokeemerald/src/tv.c:2385
function Tv.tryPutFrontierTVShowOnAir(session, winStreak, facilityAndMode, selectedPartyMons)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 then return end
  local p = party(session)
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_FRONTIER
  show.active = false
  show.playerName = playerName(session)
  show.winStreak = u16(winStreak)
  show.facilityAndMode = n(facilityAndMode)
  local mode = show.facilityAndMode
  if mode == Tv.FRONTIER_SHOW_TOWER_DOUBLES then
    for i = 1, 4 do show["species" .. i] = speciesOf(p[i]) end
  elseif mode == Tv.FRONTIER_SHOW_TOWER_MULTIS then
    for i = 1, 2 do show["species" .. i] = speciesOf(p[i]) end
  elseif mode == Tv.FRONTIER_SHOW_TOWER_LINK_MULTIS then
    local sel = selectedPartyMons or {}
    for i = 1, 2 do show["species" .. i] = speciesOf(p[n(sel[i])]) end
  elseif mode >= 1 and mode <= 13 then
    for i = 1, 3 do show["species" .. i] = speciesOf(p[i]) end
  end
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2434
function Tv.tryPutSecretBaseSecretsOnAir(session, ownerName, ownerLanguage)
  if isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_SECRET_BASE_SECRETS, false) then return end
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_SECRET_BASE_SECRETS
  show.active = false
  show.playerName = playerName(session)
  show.stepsInBase = var("VAR_SECRET_BASE_STEP_COUNTER", session)
  show.baseOwnersName = tostring(ownerName or "")
  show.item = var("VAR_SECRET_BASE_LAST_ITEM_USED", session)
  show.flags = var("VAR_SECRET_BASE_LOW_TV_FLAGS", session) + var("VAR_SECRET_BASE_HIGH_TV_FLAGS", session) * 0x10000
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
  show.baseOwnersNameLanguage = tonumber(ownerLanguage) or Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2484
local function tryPutNumberOneOnAir(session, actionIdx, count)
  isRecordMixShowAlreadySpawned(session, Tv.TVSHOW_NUMBER_ONE, true)
  local list = shows(session)
  Tv._curSlot = firstEmptyRecordMixSlot(list)
  if Tv._curSlot == -1 then return end
  local show = list[Tv._curSlot]
  show.kind = Tv.TVSHOW_NUMBER_ONE
  show.active = false
  show.playerName = playerName(session)
  show.actionIdx = actionIdx
  show.count = u16(count)
  storeIdRecordMix(show, session)
  show.language = Tv.GAME_LANGUAGE
end

-- pokeemerald/src/tv.c:2467
local function resolveNumberOneShow(session)
  local data = Tv.data()
  local rows = data and data.numberOne or {}
  for i, row in ipairs(rows) do
    local v = var(row.var, session)
    if v >= n(row.threshold) then
      tryPutNumberOneOnAir(session, i - 1, v)
      break
    end
  end
  for _, row in ipairs(rows) do setVar(row.var, 0, session) end
end

local function incVar(name, delta, session)
  setVar(name, var(name, session) + (delta or 1), session)
end

-- pokeemerald/src/tv.c:2503
function Tv.incrementDailySlotsUses(session) incVar("VAR_DAILY_SLOTS", 1, session) end
-- pokeemerald/src/tv.c:2508
function Tv.incrementDailyRouletteUses(session) incVar("VAR_DAILY_ROULETTE", 1, session) end
-- pokeemerald/src/tv.c:2513
function Tv.incrementDailyWildBattles(session) incVar("VAR_DAILY_WILDS", 1, session) end
-- pokeemerald/src/tv.c:2518
function Tv.incrementDailyBerryBlender(session) incVar("VAR_DAILY_BLENDER", 1, session) end
-- pokeemerald/src/tv.c:2523
function Tv.incrementDailyPlantedBerries(session) incVar("VAR_DAILY_PLANTED_BERRIES", 1, session) end
-- pokeemerald/src/tv.c:2528
function Tv.incrementDailyPickedBerries(session, count) incVar("VAR_DAILY_PICKED_BERRIES", n(count), session) end
-- pokeemerald/src/tv.c:2533
function Tv.incrementDailyBattlePoints(session, delta) incVar("VAR_DAILY_BP", n(delta), session) end

-- pokeemerald/src/tv.c:2558
local function firstEmptyNewsSlot(news)
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    if n(news[i].kind) == Tv.POKENEWS_NONE then return i end
  end
  return -1
end

-- pokeemerald/src/tv.c:2578
local function clearNewsSlot(news, i)
  news[i] = blankNews()
end

-- pokeemerald/src/tv.c:2570
function Tv.clearPokeNews(session)
  local s = Tv.state(session)
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do clearNewsSlot(s.pokeNews, i) end
end

-- pokeemerald/src/tv.c:2585
local function compactNews(news)
  for i = 0, Tv.POKE_NEWS_COUNT - 2 do
    if n(news[i].kind) == Tv.POKENEWS_NONE then
      for j = i + 1, Tv.POKE_NEWS_COUNT - 1 do
        if n(news[j].kind) ~= Tv.POKENEWS_NONE then
          news[i] = news[j]
          clearNewsSlot(news, j)
          break
        end
      end
    end
  end
end

-- pokeemerald/src/tv.c:2697
local function isAddingNewsDisallowed(news, kind)
  if kind == Tv.POKENEWS_NONE then return true end
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    if n(news[i].kind) == kind then return true end
  end
  return false
end

-- pokeemerald/src/tv.c:2540
function Tv.tryPutRandomPokeNewsOnAir(session)
  if not flag("FLAG_SYS_GAME_CLEAR", session) then return end
  local news = Tv.state(session).pokeNews
  Tv._curSlot = firstEmptyNewsSlot(news)
  if Tv._curSlot == -1 or rbernoulli(1, 100) == true then return end
  local kind = random() % Tv.NUM_POKENEWS_TYPES + 1
  if isAddingNewsDisallowed(news, kind) then return end
  news[Tv._curSlot].kind = kind
  news[Tv._curSlot].dayCountdown = Tv.POKENEWS_COUNTDOWN
  news[Tv._curSlot].state = Tv.POKENEWS_STATE_UPCOMING
end

-- pokeemerald/src/tv.c:2607
function Tv.findPokeNewsOnAir(session)
  local s = Tv.state(session)
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    local e = s.pokeNews[i]
    if n(e.kind) ~= Tv.POKENEWS_NONE and n(e.state) == Tv.POKENEWS_STATE_UPCOMING
        and n(e.dayCountdown) < Tv.POKENEWS_COUNTDOWN - 1 then
      return i
    end
  end
  return 0xFF
end

-- pokeemerald/src/tv.c:2621
function Tv.doPokeNews(session, hours, sv)
  local i = Tv.findPokeNewsOnAir(session)
  if i == 0xFF then return nil, false end
  local e = Tv.state(session).pokeNews[i]
  local group
  if n(e.dayCountdown) == 0 then
    e.state = Tv.POKENEWS_STATE_ACTIVE
    group = n(hours) < 20 and "sPokeNewsTextGroup_Ongoing" or "sPokeNewsTextGroup_Ending"
  else
    if sv then sv[1] = tostring(n(e.dayCountdown) % 10) end
    e.state = Tv.POKENEWS_STATE_INACTIVE
    group = "sPokeNewsTextGroup_Upcoming"
  end
  return { group = group, index = n(e.kind) }, true
end

-- pokeemerald/src/tv.c:2654
function Tv.isPokeNewsActive(session, kind, shouldApply)
  kind = n(kind)
  if kind == Tv.POKENEWS_NONE then return false end
  local s = Tv.state(session)
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    local e = s.pokeNews[i]
    if n(e.kind) == kind then
      return n(e.state) == Tv.POKENEWS_STATE_ACTIVE and shouldApply ~= nil and shouldApply(kind) == true
    end
  end
  return false
end

-- pokeemerald/include/constants/map_event_ids.h:756
Tv.LOCALID_SLATEPORT_ENERGY_GURU = 25

local function lastTalked()
  local Space = package.loaded["src.core.game3.scripting.space"]
  local ctx = Space and Space.vm and Space.vm.ctx
  local sv = ctx and ctx.specialVars
  return n(sv and sv[0x800F])
end

-- pokeemerald/src/tv.c:2678
function Tv.shouldApplyPokeNews(kind, session, talked)
  session = sessionOf(session) or {}
  kind = n(kind)
  if kind == Tv.POKENEWS_SLATEPORT then
    return session.map == "EM_SLATEPORT_CITY" and n(talked or lastTalked()) == Tv.LOCALID_SLATEPORT_ENERGY_GURU
  elseif kind == Tv.POKENEWS_LILYCOVE then
    return session.map == "EM_LILYCOVE_CITY_DEPARTMENT_STORE_ROOFTOP"
  end
  return true
end

-- pokeemerald/src/tv.c:2712
local function updatePokeNewsCountdown(session, days)
  local news = Tv.state(session).pokeNews
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    local e = news[i]
    if n(e.kind) ~= Tv.POKENEWS_NONE then
      if n(e.dayCountdown) < days then
        clearNewsSlot(news, i)
      else
        if n(e.state) == Tv.POKENEWS_STATE_INACTIVE and flag("FLAG_SYS_GAME_CLEAR", session) then
          e.state = Tv.POKENEWS_STATE_UPCOMING
        end
        e.dayCountdown = n(e.dayCountdown) - days
      end
    end
  end
  compactNews(news)
end

-- pokeemerald/src/tv.c:1707
function Tv.updatePerDay(session, days)
  session = sessionOf(session)
  if type(session) ~= "table" then return end
  days = n(days)
  Tv.state(session)
  updateTimeBeforeMassOutbreak(session, days)
  tryEndMassOutbreak(session, days)
  updatePokeNewsCountdown(session, days)
  resolveWorldOfMastersShow(session)
  resolveNumberOneShow(session)
end

-- pokeemerald/src/tv.c:2894
function Tv.interviewBefore(session, kind)
  session = sessionOf(session)
  Tv._result = false
  kind = n(kind)
  local list = shows(session)
  if kind == Tv.TVSHOW_FAN_CLUB_LETTER then
    tryReplaceOldShowOfKind(session, kind)
    if not Tv._result then
      Tv._stringVar1 = Tv.speciesName(speciesOf(leadMon(session)))
      list[Tv._curSlot].words = emptyWords(6)
    end
  elseif kind == Tv.TVSHOW_RECENT_HAPPENINGS then
    tryReplaceOldShowOfKind(session, kind)
    if not Tv._result then list[Tv._curSlot].words = emptyWords(6) end
  elseif kind == Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS then
    tryReplaceOldShowOfKind(session, kind)
    if not Tv._result then
      local mon = leadMon(session)
      Tv._stringVar1 = Tv.speciesName(speciesOf(mon))
      Tv._stringVar2 = nickname(mon)
      list[Tv._curSlot].words = emptyWords(2)
    end
  elseif kind == Tv.TVSHOW_DUMMY then
    Tv._result = true
  elseif kind == Tv.TVSHOW_NAME_RATER_SHOW or kind == Tv.TVSHOW_CONTEST_LIVE_UPDATES
      or kind == Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS then
    tryReplaceOldShowOfKind(session, kind)
  elseif kind == Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE then
    interviewBeforeBravoTrainerPkmnProfile(session)
  elseif kind == Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE then
    tryReplaceOldShowOfKind(session, kind)
    if not Tv._result then list[Tv._curSlot].words = emptyWords(1) end
  elseif kind == Tv.TVSHOW_FAN_CLUB_SPECIAL then
    tryReplaceOldShowOfKind(session, kind)
    if not Tv._result then list[Tv._curSlot].words = emptyWords(1) end
  end
  return Tv._result
end

-- pokeemerald/src/tv.c:1077
function Tv.interviewAfter(session, kind, ctxv)
  session = sessionOf(session)
  ctxv = ctxv or {}
  kind = n(kind)
  if kind == Tv.TVSHOW_FAN_CLUB_LETTER then
    interviewAfterFanClubLetter(session)
  elseif kind == Tv.TVSHOW_RECENT_HAPPENINGS then
    interviewAfterRecentHappenings(session)
  elseif kind == Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS then
    interviewAfterPkmnFanClubOpinions(session, ctxv)
  elseif kind == Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE then
    interviewAfterBravoTrainerPokemonProfile(session)
  elseif kind == Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE then
    interviewAfterBravoTrainerBattleTowerProfile(session, ctxv)
  elseif kind == Tv.TVSHOW_CONTEST_LIVE_UPDATES then
    interviewAfterContestLiveUpdates(session, ctxv)
  end
end

-- pokeemerald/src/tv.c:3010
function Tv.isLeadMonNicknamedOrNotEnglish(session)
  local mon = leadMon(session)
  if language(mon) == Tv.GAME_LANGUAGE and Tv.speciesName(speciesOf(mon)) == nickname(mon) then return false end
  return true
end

-- pokeemerald/include/constants/easy_chat.h:9
Tv.EASY_CHAT_TYPE = {
  INTERVIEW = 5, FAN_CLUB = 7, DUMMY_SHOW = 8, GABBY_AND_TY = 10, CONTEST_INTERVIEW = 11,
  BATTLE_TOWER_INTERVIEW = 12, FAN_QUESTION = 14,
}

-- pokeemerald/src/easy_chat.c:1486
function Tv.easyChatWords(session, chatType, slot, person)
  local s = Tv.state(sessionOf(session))
  local T = Tv.EASY_CHAT_TYPE
  chatType = n(chatType)
  local show = s.tvShows[n(slot)]
  local function words(count)
    if type(show.words) ~= "table" then show.words = emptyWords(count) end
    return show.words
  end
  if chatType == T.INTERVIEW then
    return words(6), 1, 4
  elseif chatType == T.FAN_CLUB then
    return words(2), n(person) + 1, 1
  elseif chatType == T.DUMMY_SHOW then
    return words(2), 1, 2
  elseif chatType == T.GABBY_AND_TY then
    s.gabbyAndTyData.quote[0] = Tv.EC_EMPTY_WORD
    return s.gabbyAndTyData.quote, 0, 1
  elseif chatType == T.CONTEST_INTERVIEW then
    return words(2), n(person) + 1, 1
  elseif chatType == T.BATTLE_TOWER_INTERVIEW then
    return words(1), 1, 1
  elseif chatType == T.FAN_QUESTION then
    local w = words(1)
    w[1] = Tv.EC_EMPTY_WORD
    return w, 1, 1
  end
  return nil
end

-- pokeemerald/src/tv.c:3359
function Tv.checkForPlayersHouseNews(opts)
  if opts.mapGroup ~= opts.housesGroup then return Tv.PLAYERS_HOUSE_TV_NONE end
  local want = opts.gender == 0 and opts.brendanNum or opts.mayNum
  if opts.mapNum ~= want then return Tv.PLAYERS_HOUSE_TV_NONE end
  if opts.flag(opts.latiFlag or "FLAG_SYS_TV_LATIAS_LATIOS") then return Tv.PLAYERS_HOUSE_TV_LATI end
  if opts.flag("FLAG_SYS_TV_HOME") then return Tv.PLAYERS_HOUSE_TV_MOVIE end
  return Tv.PLAYERS_HOUSE_TV_LATI
end

-- pokeemerald/src/tv.c:3386
function Tv.momOrDad(opts)
  if opts.mapGroup == opts.housesGroup then
    local want = opts.gender == 0 and opts.brendanNum or opts.mayNum
    if opts.mapNum == want then opts.setTemp3(1) end
  end
  local v = tonumber(opts.getTemp3()) or 0
  if v == 1 then return "mom" end
  if v == 2 then return "dad" end
  if v > 2 then return (v % 2 == 0) and "mom" or "dad" end
  if (tonumber(opts.random()) or 0) % 2 ~= 0 then
    opts.setTemp3(1)
    return "mom"
  end
  opts.setTemp3(2)
  return "dad"
end

-- pokeemerald/src/tv.c:854
function Tv.setScreens(layout, behaviorAt, setMetatile, isTv, metatile)
  if not layout then return 0 end
  local count = 0
  for y = 0, (layout.height or 0) - 1 do
    for x = 0, (layout.width or 0) - 1 do
      if isTv(behaviorAt(x, y)) then
        setMetatile(x, y, metatile)
        count = count + 1
      end
    end
  end
  return count
end

-- pokeemerald/src/tv.c:3626
local function findInactiveShow(list)
  for i = 0, Tv.LAST_TVSHOW_IDX - 1 do
    local k = n(list[i].kind)
    if list[i].active ~= true and k >= 1 and k <= Tv.TVGROUP_OUTBREAK_END then return i end
  end
  return -1
end

local function idMatches(id, lo, hi)
  return id % 256 == n(lo) and math.floor(id / 256) % 256 == n(hi)
end

-- pokeemerald/src/tv.c:3570
local function mixNormal(dest, src, linkId)
  if idMatches(linkId, src.trainerIdLo, src.trainerIdHi) then return false end
  src.trainerIdLo, src.trainerIdHi = src.srcTrainerIdLo, src.srcTrainerIdHi
  src.srcTrainerIdLo, src.srcTrainerIdHi = linkId % 256, math.floor(linkId / 256) % 256
  local out = copy(src)
  out.active = true
  return out
end

-- pokeemerald/src/tv.c:3587
local function mixRecordMix(dest, src, linkId)
  if idMatches(linkId, src.srcTrainerIdLo, src.srcTrainerIdHi) then return false end
  if idMatches(linkId, src.trainerIdLo, src.trainerIdHi) then return false end
  src.srcTrainerIdLo, src.srcTrainerIdHi = src.srcTrainerId2Lo, src.srcTrainerId2Hi
  src.srcTrainerId2Lo, src.srcTrainerId2Hi = linkId % 256, math.floor(linkId / 256) % 256
  local out = copy(src)
  out.active = true
  return out
end

-- pokeemerald/src/tv.c:3608
local function mixOutbreak(dest, src, linkId)
  local out = mixNormal(dest, src, linkId)
  if out then out.daysBeforeOutbreak = 1 end
  return out
end

-- pokeemerald/src/tv.c:3539
local function tryMixShow(dest, src, srcSlot, destSlot, linkId)
  local g = Tv.groupOf(src[srcSlot].kind)
  local out
  if g == Tv.TVGROUP.NORMAL then
    out = mixNormal(dest[destSlot], src[srcSlot], linkId)
  elseif g == Tv.TVGROUP.RECORD_MIX then
    out = mixRecordMix(dest[destSlot], src[srcSlot], linkId)
  elseif g == Tv.TVGROUP.OUTBREAK then
    out = mixOutbreak(dest[destSlot], src[srcSlot], linkId)
  end
  if out then
    dest[destSlot] = out
    deleteShow(src, srcSlot)
    return true
  end
  return false
end

-- pokeemerald/src/tv.c:3498
function Tv.setMixedShows(lists, trainerIds)
  local count = #lists
  local without = 0
  for _ = 1, 10000 do
    for i = 0, count - 1 do
      if i == 0 then without = 0 end
      local src = lists[i + 1]
      local slot = findInactiveShow(src)
      if slot == -1 then
        without = without + 1
        if without == count then return end
      else
        local j = 0
        while j < count - 1 do
          local di = (i + j + 1) % count
          local dest = lists[di + 1]
          local destSlot = firstEmptyRecordMixSlot(dest)
          if destSlot ~= -1 and tryMixShow(dest, src, slot, destSlot, n(trainerIds[di + 1])) then break end
          j = j + 1
        end
        if j == count - 1 then deleteShow(src, slot) end
      end
    end
  end
end

-- pokeemerald/src/tv.c:3822
local function deleteExcessMixedShows(list)
  local empty = 0
  for i = Tv.NUM_NORMAL_TVSHOW_SLOTS, Tv.LAST_TVSHOW_IDX - 1 do
    if n(list[i].kind) == Tv.TVSHOW_OFF_AIR then empty = empty + 1 end
  end
  for i = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - empty - 1 do
    deleteShow(list, i + Tv.NUM_NORMAL_TVSHOW_SLOTS)
  end
end

-- pokeemerald/src/tv.c:3639
local SPECIES_FIELDS = {
  [Tv.TVSHOW_CONTEST_LIVE_UPDATES] = { "winningSpecies", "losingSpecies" },
  [Tv.TVSHOW_BATTLE_UPDATE] = { "speciesPlayer", "speciesOpponent" },
  [Tv.TVSHOW_FAN_CLUB_LETTER] = { "species" },
  [Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS] = { "species" },
  [Tv.TVSHOW_DUMMY] = { "species" },
  [Tv.TVSHOW_NAME_RATER_SHOW] = { "species", "randomSpecies" },
  [Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE] = { "species" },
  [Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE] = { "species", "defeatedSpecies" },
  [Tv.TVSHOW_POKEMON_TODAY_CAUGHT] = { "species" },
  [Tv.TVSHOW_POKEMON_TODAY_FAILED] = { "species", "species2" },
  [Tv.TVSHOW_FISHING_ADVICE] = { "species" },
  [Tv.TVSHOW_WORLD_OF_MASTERS] = { "species", "caughtPoke" },
  [Tv.TVSHOW_BREAKING_NEWS] = { "lastOpponentSpecies", "poke1Species" },
  [Tv.TVSHOW_SECRET_BASE_VISIT] = { "species" },
  [Tv.TVSHOW_BATTLE_SEMINAR] = { "species", "foeSpecies" },
}
local NO_SPECIES = {
  [Tv.TVSHOW_OFF_AIR] = true, [Tv.TVSHOW_RECENT_HAPPENINGS] = true, [Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS] = true,
  [Tv.TVSHOW_TODAYS_RIVAL_TRAINER] = true, [Tv.TVSHOW_TREND_WATCHER] = true, [Tv.TVSHOW_TREASURE_INVESTIGATORS] = true,
  [Tv.TVSHOW_FIND_THAT_GAMER] = true, [Tv.TVSHOW_TRAINER_FAN_CLUB] = true, [Tv.TVSHOW_CUTIES] = true,
  [Tv.TVSHOW_SMART_SHOPPER] = true, [Tv.TVSHOW_FAN_CLUB_SPECIAL] = true, [Tv.TVSHOW_LILYCOVE_CONTEST_LADY] = true,
  [Tv.TVSHOW_LOTTO_WINNER] = true, [Tv.TVSHOW_NUMBER_ONE] = true, [Tv.TVSHOW_SECRET_BASE_SECRETS] = true,
  [Tv.TVSHOW_SAFARI_FAN_CLUB] = true, [Tv.TVSHOW_MASS_OUTBREAK] = true,
}

local function deactivateShowsWithUnseenSpecies(session)
  local list = shows(session)
  for i = 0, Tv.LAST_TVSHOW_IDX - 1 do
    local show = list[i]
    local kind = n(show.kind)
    local fields = SPECIES_FIELDS[kind]
    if fields then
      for _, f in ipairs(fields) do
        if not seenSpecies(session, show[f]) then show.active = false end
      end
    elseif kind == Tv.TVSHOW_FRONTIER then
      local check = { "species1", "species2" }
      local mode = n(show.facilityAndMode)
      if mode == Tv.FRONTIER_SHOW_TOWER_DOUBLES then
        check[3], check[4] = "species3", "species4"
      elseif mode ~= Tv.FRONTIER_SHOW_TOWER_MULTIS and mode ~= Tv.FRONTIER_SHOW_TOWER_LINK_MULTIS and mode >= 1 and mode <= 13 then
        check[3] = "species3"
      end
      for _, f in ipairs(check) do
        if not seenSpecies(session, show[f]) then show.active = false end
      end
    elseif not NO_SPECIES[kind] then
      show.active = false
    end
  end
end

-- pokeemerald/src/tv.c:3794
local function deactivateGameCompleteShowsIfNotUnlocked(session)
  if flag("FLAG_SYS_GAME_CLEAR", session) then return end
  local list = shows(session)
  for i = 0, Tv.LAST_TVSHOW_IDX - 1 do
    local k = n(list[i].kind)
    if k == Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE or k == Tv.TVSHOW_MASS_OUTBREAK then
      list[i].active = false
    end
  end
end

-- pokeemerald/src/tv.c:3810
function Tv.deactivateAllNormalShows(session)
  local list = shows(session)
  for i = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - 1 do
    if Tv.groupOf(list[i].kind) == Tv.TVGROUP.NORMAL then list[i].active = false end
  end
end

function Tv.mixExport(session)
  session = sessionOf(session)
  local s = Tv.state(session)
  local out = { tvShows = copy(s.tvShows), pokeNews = copy(s.pokeNews), trainerId = Tv.playerId(session) }
  local sending = copy(out.tvShows)
  for slot = 0, Tv.NUM_NORMAL_TVSHOW_SLOTS - 1 do
    if Tv.groupOf(sending[slot].kind) == Tv.TVGROUP.NORMAL then sending[slot].active = false end
  end
  local row = rse().profile(session)
  local raw = require("src.save_convert.Gen3Save").forVersion(row and row.id or "emerald").recordMixTvPrefix(session, sending)
  local sum = 0
  for i = 1, 256 do sum = sum + raw:byte(i) end
  out.tvShowByteSum = sum % 256
  return out
end

-- pokeemerald/src/tv.c:3449
function Tv.receiveShows(session, players, myIndex)
  session = sessionOf(session)
  local lists, ids = {}, {}
  for i, p in ipairs(players) do
    if i == myIndex then
      lists[i] = shows(session)
      ids[i] = Tv.playerId(session)
    else
      lists[i] = p.tvShows
      for k = 0, Tv.TV_SHOWS_COUNT - 1 do
        if type(lists[i][k]) ~= "table" then lists[i][k] = blankShow() end
      end
      ids[i] = n(p.trainerId)
    end
  end
  Tv.setMixedShows(lists, ids)
  local mine = shows(session)
  compactShows(mine)
  deleteExcessMixedShows(mine)
  compactShows(mine)
  deactivateShowsWithUnseenSpecies(session)
  deactivateGameCompleteShowsIfNotUnlocked(session)
end

-- pokeemerald/src/tv.c:3907
local function tryMixNews(dest, src, slot)
  if n(src.kind) == Tv.POKENEWS_NONE then return false end
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    if n(dest[i].kind) == n(src.kind) then return false end
  end
  dest[slot] = { kind = n(src.kind), state = Tv.POKENEWS_STATE_UPCOMING, dayCountdown = n(src.dayCountdown) }
  return true
end

-- pokeemerald/src/tv.c:3835
function Tv.receivePokeNews(session, players, myIndex)
  session = sessionOf(session)
  local lists = {}
  for i, p in ipairs(players) do
    if i == myIndex then
      lists[i] = Tv.state(session).pokeNews
    else
      lists[i] = p.pokeNews
      for k = 0, Tv.POKE_NEWS_COUNT - 1 do
        if type(lists[i][k]) ~= "table" then lists[i][k] = blankNews() end
      end
    end
  end
  local count = #lists
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    for j = 0, count - 1 do
      if n(lists[j + 1][i].kind) ~= Tv.POKENEWS_NONE then
        for k = 0, count - 2 do
          local dest = lists[(j + k + 1) % count + 1]
          local slot = firstEmptyNewsSlot(dest)
          if slot ~= -1 then tryMixNews(dest, lists[j + 1][i], slot) end
        end
      end
    end
  end
  local news = Tv.state(session).pokeNews
  for i = 0, Tv.POKE_NEWS_COUNT - 1 do
    if n(news[i].kind) > Tv.POKENEWS_BLENDMASTER then clearNewsSlot(news, i) end
  end
  compactNews(news)
  if not flag("FLAG_SYS_GAME_CLEAR", session) then
    for i = 0, Tv.POKE_NEWS_COUNT - 1 do news[i].state = Tv.POKENEWS_STATE_INACTIVE end
  end
end

-- pokeemerald/src/battle_main.c:5102
Tv.BATTLE_RESULT_EXCLUDED = {
  "link", "recordedLink", "firstBattle", "safari", "ereaderTrainer", "wallyTutorial", "frontier",
}

-- pokeemerald/src/battle_main.c:5098
function Tv.onBattleEnd(session, results, outcome, battleType)
  session = sessionOf(session)
  results = results or {}
  battleType = battleType or {}
  Tv._battleResults = results
  for _, k in ipairs(Tv.BATTLE_RESULT_EXCLUDED) do
    if battleType[k] then return end
  end
  Tv.tryPutPokemonTodayOnAir(session, results, outcome)
  -- pokeemerald/src/battle_main.c:5129
  if results.shinyWildMon and not battleType.trainer then
    Tv.tryPutBreakingNewsOnAir(session, results, outcome)
  end
end

local DATA_REL = "data/generated/gba/tv/manifest.lua"
local dataCache = {}

function Tv.data()
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get()) .. ":" .. tostring(GameVersion.cachePrefix and GameVersion.cachePrefix())
  if dataCache[key] ~= nil then return dataCache[key] or nil end
  local ok, Dataset = pcall(require, "src.core.game3.dataset")
  local cache = ok and Dataset.cache and Dataset.cache() or nil
  local src = cache and cache:read(DATA_REL)
  local t
  if type(src) == "string" then
    local chunk = load(src, "@" .. DATA_REL, "t", {})
    local okL, v = pcall(chunk)
    if okL and type(v) == "table" then t = v end
  end
  dataCache[key] = t or false
  return t
end

function Tv.resetData()
  dataCache = {}
  layoutIds = {}
end

-- pokeemerald/src/tv.c:192
function Tv.outbreakSpeciesList()
  local d = Tv.data()
  return d and d.outbreakSpecies or nil
end

local SHOW = {}
Tv.SHOW_TEXT = SHOW

local function group(kind)
  return ({
    [Tv.TVSHOW_FAN_CLUB_LETTER] = "sTVFanClubTextGroup",
    [Tv.TVSHOW_RECENT_HAPPENINGS] = "sTVRecentHappeninssTextGroup",
    [Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS] = "sTVFanClubOpinionsTextGroup",
    [Tv.TVSHOW_MASS_OUTBREAK] = "sTVMassOutbreakTextGroup",
    [Tv.TVSHOW_POKEMON_TODAY_CAUGHT] = "sTVPokemonTodaySuccessfulTextGroup",
    [Tv.TVSHOW_SMART_SHOPPER] = "sTVTodaysSmartShopperTextGroup",
    [Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE] = "sTVBravoTrainerTextGroup",
    [Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS] = "sTV3CheersForPokeblocksTextGroup",
    [Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE] = "sTVBravoTrainerBattleTowerTextGroup",
    [Tv.TVSHOW_CONTEST_LIVE_UPDATES] = "sTVContestLiveUpdatesTextGroup",
    [Tv.TVSHOW_BATTLE_UPDATE] = "sTVPokemonBattleUpdateTextGroup",
    [Tv.TVSHOW_FAN_CLUB_SPECIAL] = "sTVTrainerFanClubSpecialTextGroup",
    [Tv.TVSHOW_NAME_RATER_SHOW] = "sTVNameRaterTextGroup",
    [Tv.TVSHOW_LILYCOVE_CONTEST_LADY] = "sTVLilycoveContestLadyTextGroup",
    [Tv.TVSHOW_POKEMON_TODAY_FAILED] = "sTVPokemonTodayFailedTextGroup",
    [Tv.TVSHOW_FISHING_ADVICE] = "sTVPokemonAnglerTextGroup",
    [Tv.TVSHOW_WORLD_OF_MASTERS] = "sTVWorldOfMastersTextGroup",
    [Tv.TVSHOW_TODAYS_RIVAL_TRAINER] = "sTVTodaysRivalTrainerTextGroup",
    [Tv.TVSHOW_TREND_WATCHER] = "sTVDewfordTrendWatcherNetworkTextGroup",
    [Tv.TVSHOW_TREASURE_INVESTIGATORS] = "sTVHoennTreasureInvestisatorsTextGroup",
    [Tv.TVSHOW_FIND_THAT_GAMER] = "sTVFindThatGamerTextGroup",
    [Tv.TVSHOW_BREAKING_NEWS] = "sTVBreakingNewsTextGroup",
    [Tv.TVSHOW_SECRET_BASE_VISIT] = "sTVSecretBaseVisitTextGroup",
    [Tv.TVSHOW_LOTTO_WINNER] = "sTVPokemonLotteryWinnerFlashReportTextGroup",
    [Tv.TVSHOW_BATTLE_SEMINAR] = "sTVThePokemonBattleSeminarTextGroup",
    [Tv.TVSHOW_TRAINER_FAN_CLUB] = "sTVTrainerFanClubTextGroup",
    [Tv.TVSHOW_CUTIES] = "sTVCutiesTextGroup",
    [Tv.TVSHOW_FRONTIER] = "sTVPokemonNewsBattleFrontierTextGroup",
    [Tv.TVSHOW_NUMBER_ONE] = "sTVWhatsNo1InHoennTodayTextGroup",
    [Tv.TVSHOW_SECRET_BASE_SECRETS] = "sTVSecretBaseSecretsTextGroup",
    [Tv.TVSHOW_SAFARI_FAN_CLUB] = "sTVSafariFanClubTextGroup",
  })[kind]
end
Tv.textGroupOf = group

Tv.names = {}

local function nameFn(key, default)
  return function(...)
    local f = Tv.names[key]
    if f then return f(...) end
    return default(...)
  end
end

local function romText(key)
  local RomText = require("src.core.game3.rom_text")
  local ok, v = pcall(RomText.plain, key)
  return ok and tostring(v or "") or ""
end

local N = {
  species = nameFn("species", function(id) return Tv.speciesName(id) end),
  move = nameFn("move", function(id)
    local ok, v = pcall(require("src.core.game3.pokemon").moveName, n(id))
    return ok and tostring(v or "") or ""
  end),
  item = nameFn("item", function(id)
    local ok, v = pcall(require("src.core.game3.items_data").displayName, n(id))
    return ok and tostring(v or "") or ""
  end),
  itemPrice = nameFn("itemPrice", function(id)
    local ok, info = pcall(require("src.core.game3.items_data").info, n(id))
    return ok and type(info) == "table" and n(info.price) or 0
  end),
  decoration = nameFn("decoration", function(id)
    local ok, info = pcall(require("src.core.game3.rse.decoration_inventory").info, n(id))
    return ok and type(info) == "table" and tostring(info.name or "") or ""
  end),
  mapName = nameFn("mapName", function(sec)
    sec = n(sec)
    local secretBase = constId("region_map_sections", "MAPSEC_SECRET_BASE")
    local none = constId("region_map_sections", "MAPSEC_NONE") or 213
    if sec == secretBase then
      local r = rse().call("secretBase", "mapName", "GetSecretBaseMapName")
      return tostring(r or "")
    elseif sec < none then
      local ok, v = pcall(require("src.ui.game3.rse.mapsec").name, sec)
      return ok and tostring(v or "") or ""
    end
    return string.rep(" ", 18)
  end),
  word = nameFn("word", function(id)
    if n(id) == Tv.EC_EMPTY_WORD then return "" end
    local ok, v = pcall(require("src.core.game3.easy_chat_text").word, n(id))
    return ok and tostring(v or "") or ""
  end),
  phrase = nameFn("phrase", function(words, cols, rows)
    local ok, v = pcall(require("src.core.game3.easy_chat_text").phrase, words, cols, rows)
    return ok and tostring(v or "") or ""
  end),
  text = nameFn("text", romText),
}
Tv.N = N

local function stdString(i) return N.text(string.format("gStdStrings[%d]", i)) end

local function context(show, sv)
  local t = { show = show, sv = sv, state = Tv._showState }
  function t.set(v) Tv._showState = v end
  function t.done()
    Tv._result = true
    Tv._showState = 0
    show.active = false
  end
  function t.str(i, v) sv[i] = tostring(v or "") end
  function t.num(idx0, v) sv[idx0 + 1] = tostring(math.floor(n(v))) end
  function t.species(i, id) sv[i] = N.species(n(id)) end
  function t.moveName(i, id) sv[i] = N.move(n(id)) end
  function t.itemName(i, id) sv[i] = N.item(n(id)) end
  function t.map(i, sec) sv[i] = N.mapName(sec) end
  function t.word(i, id) sv[i] = N.word(id) end
  -- pokeemerald/src/tv.c:2757
  function t.category(idx0, cat) sv[idx0 + 1] = stdString(n(cat)) end
  -- pokeemerald/src/tv.c:2738
  function t.rank(idx0, rank) sv[idx0 + 1] = stdString(5 + n(rank)) end
  return t
end

-- pokeemerald/src/tv.c:3152
local function randomWordFromShow(t)
  local words = t.show.words or {}
  local count = 6
  local i = random() % count
  for _ = 1, count do
    if i == count then i = 0 end
    if n(words[i + 1]) ~= Tv.EC_EMPTY_WORD and words[i + 1] ~= nil then break end
    i = i + 1
  end
  if i == count then i = 0 end
  t.word(3, words[i + 1])
end

local charCodes

-- pokeemerald/src/tv.c:3171
local function nameRaterStateFromName(show)
  if not charCodes then
    charCodes = {}
    local ok, TextIR = pcall(require, "src.core.game3.scripting.text_ir")
    for code, ch in pairs(ok and TextIR.CHARMAP or {}) do
      if charCodes[ch] == nil or code < charCodes[ch] then charCodes[ch] = code end
    end
  end
  local sum = 0
  local chars = nameChars(show.pokemonName)
  for i = 1, math.min(#chars, 11) do sum = sum + n(charCodes[chars[i]]) end
  return sum % 8
end

-- pokeemerald/src/tv.c:3187
local function nicknameSubstring(t, idx0, pos, charParam, which, species)
  local show = t.show
  local src
  if which == 0 then src = show.trainerName
  elseif which == 1 then src = show.pokemonName
  else src = N.species(species) end
  local chars = nameChars(src)
  local len = #chars
  local function at(i) return (i >= 0 and i < len) and chars[i + 1] or "" end
  local out
  if charParam == 0 then out = at(pos)
  elseif charParam == 1 then out = at(len - pos)
  elseif charParam == 2 then out = at(pos) .. (at(pos) ~= "" and at(pos + 1) or "")
  else out = at(len - (pos + 2)) .. at(len - (pos + 1)) end
  t.sv[idx0 + 1] = out
end

-- pokeemerald/src/tv.c:4304
SHOW[Tv.TVSHOW_BRAVO_TRAINER_POKEMON_PROFILE] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.category(1, s.contestCategory)
    t.rank(2, s.contestRank)
    if N.species(s.species) == tostring(s.pokemonNickname or "") then t.set(8) else t.set(1) end
  elseif st == 1 then
    t.species(1, s.species)
    t.str(2, s.pokemonNickname)
    t.category(2, s.contestCategory)
    t.set(2)
  elseif st == 2 then
    t.str(1, s.playerName)
    if n(s.contestResult) == 0 then t.set(3) else t.set(4) end
  elseif st == 3 or st == 4 then
    t.str(1, s.playerName)
    t.word(2, s.words and s.words[1])
    t.num(2, n(s.contestResult) + 1)
    t.set(5)
  elseif st == 5 then
    t.str(1, s.playerName)
    t.category(1, s.contestCategory)
    t.word(3, s.words and s.words[2])
    if n(s.move) ~= 0 then t.set(6) else t.set(7) end
  elseif st == 6 then
    t.species(1, s.species)
    t.moveName(2, s.move)
    t.word(3, s.words and s.words[2])
    t.set(7)
  elseif st == 7 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.done()
  elseif st == 8 then
    t.species(1, s.species)
    t.set(2)
  end
  return st
end

-- pokeemerald/src/tv.c:4379
SHOW[Tv.TVSHOW_BRAVO_TRAINER_BATTLE_TOWER_PROFILE] = function(t)
  local s, st = t.show, t.state
  local resp = n(s.interviewResponse)
  if st == 0 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    -- pokeemerald/include/constants/battle_frontier.h:57
    if n(s.numFights) >= 7 then t.set(1) else t.set(2) end
  elseif st == 1 then
    t.str(1, N.text(n(s.btLevel) == 50 and "gText_Lv50" or "gText_OpenLevel"))
    t.num(1, s.numFights)
    if s.wonTheChallenge == true or s.wonTheChallenge == 1 then t.set(3) else t.set(4) end
  elseif st == 2 then
    t.str(1, s.opponentName)
    t.num(1, n(s.numFights) + 1)
    t.set(resp == 0 and 5 or 6)
  elseif st == 3 or st == 4 then
    t.str(1, s.opponentName)
    t.species(2, s.defeatedSpecies)
    t.set(resp == 0 and 5 or 6)
  elseif st == 5 or st == 6 then
    t.str(1, s.opponentName)
    t.set(11)
  elseif st == 7 then
    t.set(11)
  elseif st == 8 or st == 9 or st == 10 then
    t.str(1, s.playerName)
    t.set(11)
  elseif st == 11 then
    t.word(1, s.words and s.words[1])
    t.set(resp == 0 and 12 or 13)
  elseif st == 12 or st == 13 then
    t.word(1, s.words and s.words[1])
    t.str(2, s.playerName)
    t.str(3, s.opponentName)
    t.set(14)
  elseif st == 14 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:2805
local function smartShopperTotal(t, idx0)
  local s = t.show
  local price = 0
  for i = 1, Tv.SMARTSHOPPER_NUM_ITEMS do
    local id = n(s.itemIds and s.itemIds[i])
    if id ~= 0 then price = price + N.itemPrice(id) * n(s.itemAmounts and s.itemAmounts[i]) end
  end
  if n(s.priceReduced) == 1 or s.priceReduced == true then price = math.floor(price / 2) end
  t.num(idx0, price)
end

-- pokeemerald/src/tv.c:4474
SHOW[Tv.TVSHOW_SMART_SHOPPER] = function(t)
  local s, st = t.show, t.state
  local ids, amts = s.itemIds or {}, s.itemAmounts or {}
  local reduced = n(s.priceReduced) == 1 or s.priceReduced == true
  if st == 0 then
    t.str(1, s.playerName)
    t.map(2, s.shopLocation)
    if n(amts[1]) >= 255 then t.set(11) else t.set(1) end
  elseif st == 1 then
    t.str(1, s.playerName)
    t.itemName(2, ids[1])
    t.num(2, amts[1])
    t.set(Tv._showState + 1 + (random() % 4))
  elseif st == 2 or st == 4 or st == 5 then
    if n(ids[2]) ~= 0 then t.set(6) else t.set(10) end
  elseif st == 3 then
    t.num(2, n(amts[1]) + 1)
    if n(ids[2]) ~= 0 then t.set(6) else t.set(10) end
  elseif st == 6 then
    t.itemName(2, ids[2])
    t.num(2, amts[2])
    if n(ids[3]) ~= 0 then t.set(7) elseif reduced then t.set(8) else t.set(9) end
  elseif st == 7 then
    t.itemName(2, ids[3])
    t.num(2, amts[3])
    if reduced then t.set(8) else t.set(9) end
  elseif st == 8 then
    if n(amts[1]) >= 255 then t.set(12) else t.set(9) end
  elseif st == 9 then
    smartShopperTotal(t, 1)
    t.done()
  elseif st == 10 then
    if reduced then t.set(8) else t.set(9) end
  elseif st == 11 then
    t.str(1, s.playerName)
    t.itemName(2, ids[1])
    if reduced then t.set(8) else t.set(12) end
  elseif st == 12 then
    t.str(1, s.playerName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:4570
SHOW[Tv.TVSHOW_NAME_RATER_SHOW] = function(t)
  local s, st = t.show, t.state
  local function byRandom()
    local r = n(s.random)
    if r == 0 then t.set(9) elseif r == 1 then t.set(10) elseif r == 2 then t.set(11) end
  end
  if st == 0 then
    t.str(1, s.trainerName)
    t.species(2, s.species)
    t.str(3, s.pokemonName)
    t.set(nameRaterStateFromName(s) + 1)
  elseif st == 1 or (st >= 3 and st <= 8) then
    byRandom()
  elseif st == 2 then
    t.str(1, s.trainerName)
    byRandom()
  elseif st == 9 or st == 10 or st == 11 then
    t.str(1, s.pokemonName)
    nicknameSubstring(t, 1, 0, 0, 1, 0)
    nicknameSubstring(t, 2, 1, 0, 1, 0)
    t.set(12)
  elseif st == 13 then
    t.str(1, s.trainerName)
    nicknameSubstring(t, 1, 0, 2, 0, 0)
    nicknameSubstring(t, 2, 0, 3, 1, 0)
    t.set(14)
  elseif st == 14 then
    nicknameSubstring(t, 1, 0, 2, 1, 0)
    nicknameSubstring(t, 2, 0, 3, 0, 0)
    t.set(18)
  elseif st == 15 then
    nicknameSubstring(t, 0, 0, 2, 1, 0)
    t.species(2, s.species)
    nicknameSubstring(t, 2, 0, 3, 2, s.species)
    t.set(16)
  elseif st == 16 then
    nicknameSubstring(t, 0, 0, 2, 2, s.species)
    nicknameSubstring(t, 2, 0, 3, 1, 0)
    t.set(17)
  elseif st == 17 then
    nicknameSubstring(t, 0, 0, 2, 1, 0)
    t.species(2, s.randomSpecies)
    nicknameSubstring(t, 2, 0, 3, 2, s.randomSpecies)
    t.set(18)
  elseif st == 12 or st == 18 then
    if st == 12 then
      st = 18
      t.set(18)
    end
    t.str(1, s.pokemonName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:4656
SHOW[Tv.TVSHOW_POKEMON_TODAY_CAUGHT] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.str(3, s.nickname)
    if n(s.ball) == (constId("items", "ITEM_MASTER_BALL") or 1) then t.set(5) else t.set(1) end
  elseif st == 1 then
    t.set(2)
  elseif st == 2 then
    t.itemName(2, s.ball)
    t.num(2, s.nBallsUsed)
    if n(s.nBallsUsed) < 4 then t.set(3) else t.set(4) end
  elseif st == 3 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.str(3, s.nickname)
    t.set(6)
  elseif st == 4 then
    t.set(6)
  elseif st == 5 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.set(6)
  elseif st == 6 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.str(3, s.nickname)
    t.set(Tv._showState + 1 + (random() % 4))
  elseif st == 7 or st == 8 then
    t.species(1, s.species)
    t.str(2, s.nickname)
    t.species(3, Tv.randomDifferentSpeciesSeen(t.session, s.species))
    t.set(11)
  elseif st == 9 or st == 10 then
    t.species(1, s.species)
    t.str(2, s.nickname)
    t.set(11)
  elseif st == 11 then
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:4726
SHOW[Tv.TVSHOW_POKEMON_TODAY_FAILED] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.set(1)
  elseif st == 1 then
    t.str(1, s.playerName)
    t.map(2, s.location)
    t.species(3, s.species2)
    if n(s.outcome) == 1 then t.set(3) else t.set(2) end
  elseif st == 2 or st == 3 then
    t.str(1, s.playerName)
    t.num(1, s.nBallsUsed)
    if random() % 3 == 0 then t.set(5) else t.set(4) end
  elseif st == 4 or st == 5 then
    t.str(1, s.playerName)
    t.set(6)
  elseif st == 6 then
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:4771
SHOW[Tv.TVSHOW_FAN_CLUB_LETTER] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.set(50)
  elseif st == 1 then
    local r = random() % 4 + 1
    if r == 1 then t.set(2) else t.set(r + 2) end
  elseif st == 2 then
    t.set(51)
  elseif st == 3 then
    t.set(Tv._showState + random() % 3 + 1)
  elseif st == 4 or st == 5 or st == 6 then
    randomWordFromShow(t)
    t.set(7)
  elseif st == 7 then
    t.num(2, random() % 0x1f + 0x46)
    t.done()
  elseif st == 50 then
    t.set(1)
    return nil, N.phrase(s.words, 2, 2)
  elseif st == 51 then
    t.set(3)
    return nil, N.phrase(s.words, 2, 2)
  end
  return st
end

-- pokeemerald/src/tv.c:4825
SHOW[Tv.TVSHOW_RECENT_HAPPENINGS] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    randomWordFromShow(t)
    t.set(50)
  elseif st == 1 then
    t.set(Tv._showState + 1 + random() % 3)
  elseif st == 2 or st == 3 or st == 4 then
    t.set(5)
  elseif st == 5 then
    t.done()
  elseif st == 50 then
    t.set(1)
    return nil, N.phrase(s.words, 2, 2)
  end
  return st
end

-- pokeemerald/src/tv.c:4860
SHOW[Tv.TVSHOW_PKMN_FAN_CLUB_OPINIONS] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.str(3, s.nickname)
    t.set(n(s.questionAsked) + 1)
  elseif st == 1 or st == 2 or st == 3 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.word(3, s.words and s.words[1])
    t.set(4)
  elseif st == 4 then
    t.str(1, s.playerName)
    t.word(3, s.words and s.words[2])
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:4898
SHOW[Tv.TVSHOW_MASS_OUTBREAK] = function(t)
  local s = t.show
  t.map(1, s.locationMapNum)
  t.species(2, s.species)
  t.done()
  Tv.startMassOutbreak(t.session, t.idx)
  return Tv._showState
end

local CONTESTLIVE_WINNER = {
  [1] = 8, [2] = 5, [4] = 14, [8] = 7, [16] = 6, [32] = 20, [64] = 21, [128] = 22,
}
local CONTESTLIVE_LOSER = {
  [1] = 31, [2] = 30, [4] = 29, [8] = 28, [16] = 27, [32] = 26, [64] = 25, [128] = 24,
}

-- pokeemerald/src/tv.c:4916
SHOW[Tv.TVSHOW_CONTEST_LIVE_UPDATES] = function(t)
  local s, st = t.show, t.state
  local function winner()
    local nx = CONTESTLIVE_WINNER[n(s.winnerAppealFlag)]
    if nx then t.set(nx) end
  end
  local cat = n(s.category)
  if st == 0 then
    t.str(1, N.text(string.format("sContestNames[%d]", cat)))
    t.species(2, s.winningSpecies)
    t.str(3, s.winningTrainerName)
    local r1, r2 = n(s.round1Placing), n(s.round2Placing)
    if r1 == r2 then
      t.set(r1 == 0 and 1 or 3)
    elseif r1 > r2 then
      t.set(2)
    else
      t.set(4)
    end
  elseif st == 1 or st == 2 then
    t.species(2, s.winningSpecies)
    winner()
  elseif st == 3 then
    t.species(2, s.winningSpecies)
    t.str(3, s.winningTrainerName)
    winner()
  elseif st == 4 then
    local key = ({ [0] = "gText_Cool", "gText_Beauty", "gText_Cute", "gText_Smart", "gText_Tough" })[cat]
    if key then t.str(1, N.text(key)) end
    t.species(2, s.winningSpecies)
    winner()
  elseif st == 5 or st == 6 or st == 7 then
    t.species(2, s.winningSpecies)
    t.set(23)
  elseif st == 8 then
    t.species(2, s.winningSpecies)
    if cat >= 0 and cat <= 4 then t.set(9 + cat) end
  elseif st >= 9 and st <= 13 then
    t.species(2, s.winningSpecies)
    t.set(23)
  elseif st == 14 then
    t.species(2, s.winningSpecies)
    if cat >= 0 and cat <= 4 then t.set(15 + cat) end
  elseif (st >= 15 and st <= 19) or st == 20 or st == 21 then
    t.species(2, s.winningSpecies)
    t.set(23)
  elseif st == 22 then
    t.species(2, s.winningSpecies)
    t.moveName(3, s.move)
    t.set(23)
  elseif st == 23 then
    t.species(1, s.winningSpecies)
    t.str(2, s.losingTrainerName)
    t.species(3, s.losingSpecies)
    local nx = CONTESTLIVE_LOSER[n(s.loserAppealFlag)]
    if nx then t.set(nx) end
  elseif st == 24 then
    t.species(1, s.losingSpecies)
    t.set(32)
  elseif st == 25 then
    t.str(1, s.losingTrainerName)
    t.species(2, s.losingSpecies)
    t.set(32)
  elseif st == 28 then
    t.set(32)
  elseif st == 29 then
    t.str(1, s.winningTrainerName)
    t.species(2, s.winningSpecies)
    t.str(3, s.losingTrainerName)
    t.set(32)
  elseif st == 26 or st == 27 or st == 30 or st == 31 then
    t.str(1, s.losingTrainerName)
    t.set(32)
  elseif st == 32 then
    t.str(1, s.winningTrainerName)
    t.species(2, s.winningSpecies)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5258
SHOW[Tv.TVSHOW_BATTLE_UPDATE] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    local bt = n(s.battleType)
    if bt == 0 or bt == 1 then t.set(1) elseif bt == 2 then t.set(5) end
  elseif st == 1 then
    t.str(1, s.playerName)
    t.str(2, s.linkOpponentName)
    t.str(3, N.text(n(s.battleType) == 0 and "gText_Single" or "gText_Double"))
    t.set(2)
  elseif st == 2 or st == 6 then
    t.str(1, s.playerName)
    t.species(2, s.speciesPlayer)
    t.moveName(3, s.move)
    t.set(st == 2 and 3 or 7)
  elseif st == 3 then
    t.str(1, s.linkOpponentName)
    t.species(2, s.speciesOpponent)
    t.set(4)
  elseif st == 4 then
    t.str(1, s.playerName)
    t.str(2, s.linkOpponentName)
    t.done()
  elseif st == 5 then
    t.str(1, s.playerName)
    t.str(2, s.linkOpponentName)
    t.set(6)
  elseif st == 7 then
    t.str(1, s.playerName)
    t.str(2, s.linkOpponentName)
    t.species(3, s.speciesOpponent)
    t.done()
  end
  return st
end

local FLAVORS = { [0] = "gText_Spicy2", "gText_Dry2", "gText_Sweet2", "gText_Bitter2", "gText_Sour2" }

-- pokeemerald/src/tv.c:5330
SHOW[Tv.TVSHOW_3_CHEERS_FOR_POKEBLOCKS] = function(t)
  local s, st = t.show, t.state
  local sheen = n(s.sheen)
  if st == 0 then
    t.str(1, s.playerName)
    if sheen > 20 then t.set(1) else t.set(3) end
  elseif st == 1 then
    if FLAVORS[n(s.flavor)] then t.str(1, N.text(FLAVORS[n(s.flavor)])) end
    t.str(2, N.text(sheen > 24 and "gText_Excellent" or (sheen > 22 and "gText_VeryGood" or "gText_Good")))
    t.str(3, s.playerName)
    t.set(2)
  elseif st == 2 then
    t.str(1, s.worstBlenderName)
    t.set(5)
  elseif st == 3 then
    if FLAVORS[n(s.flavor)] then t.str(1, N.text(FLAVORS[n(s.flavor)])) end
    t.str(2, N.text(sheen > 16 and "gText_SoSo" or (sheen > 13 and "gText_Bad" or "gText_TheWorst")))
    t.str(3, s.playerName)
    t.set(4)
  elseif st == 4 then
    t.str(1, s.worstBlenderName)
    t.str(2, s.playerName)
    t.set(5)
  elseif st == 5 then
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5481
SHOW[Tv.TVSHOW_FISHING_ADVICE] = function(t)
  local s = t.show
  local st = n(s.nBites) < n(s.nFails) and 0 or 1
  t.set(st)
  t.str(1, s.playerName)
  t.species(2, s.species)
  t.num(2, st == 0 and s.nFails or s.nBites)
  t.done()
  return st
end

-- pokeemerald/src/tv.c:5511
SHOW[Tv.TVSHOW_WORLD_OF_MASTERS] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.num(1, s.steps)
    t.num(2, s.numPokeCaught)
    t.set(1)
  elseif st == 1 then
    t.species(1, s.species)
    t.set(2)
  elseif st == 2 then
    t.str(1, s.playerName)
    t.map(2, s.location)
    t.species(3, s.caughtPoke)
    t.done()
  end
  return st
end

-- pokeemerald/include/constants/layouts.h:284
local SS_TIDAL_LAYOUTS = { [277] = true, [278] = true, [279] = true }

-- pokeemerald/src/tv.c:5541
SHOW[Tv.TVSHOW_TODAYS_RIVAL_TRAINER] = function(t)
  local s, st = t.show, t.state
  local function badgesNext()
    if n(s.badgeCount) ~= 0 then t.set(1) else t.set(2) end
  end
  local function frontierNext()
    if flag("FLAG_LANDMARK_BATTLE_FRONTIER", t.session) then
      if n(s.nSilverSymbols) ~= 0 or n(s.nGoldSymbols) ~= 0 then t.set(4) else t.set(3) end
    else
      t.set(6)
    end
  end
  if st == 0 then
    local loc = n(s.location)
    if loc == constId("region_map_sections", "MAPSEC_SECRET_BASE") then
      t.set(8)
    elseif loc == constId("region_map_sections", "MAPSEC_DYNAMIC") then
      t.set(SS_TIDAL_LAYOUTS[n(s.mapLayoutId)] and 10 or 9)
    else
      t.set(7)
    end
  elseif st == 7 then
    t.str(1, s.playerName)
    t.num(1, s.dexCount)
    t.map(3, s.location)
    badgesNext()
  elseif st == 8 or st == 9 or st == 10 then
    t.str(1, s.playerName)
    t.num(1, s.dexCount)
    badgesNext()
  elseif st == 1 then
    t.num(0, s.badgeCount)
    frontierNext()
  elseif st == 2 then
    frontierNext()
  elseif st == 3 then
    if n(s.battlePoints) == 0 then t.set(6) else t.set(5) end
  elseif st == 4 then
    t.num(0, s.nGoldSymbols)
    t.num(1, s.nSilverSymbols)
    if n(s.battlePoints) == 0 then t.set(6) else t.set(5) end
  elseif st == 5 then
    t.num(0, s.battlePoints)
    t.set(6)
  elseif st == 6 then
    t.str(1, s.playerName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5660
SHOW[Tv.TVSHOW_TREND_WATCHER] = function(t)
  local s, st = t.show, t.state
  local w = s.words or {}
  t.word(1, w[1])
  t.word(2, w[2])
  if st == 0 then
    t.set(n(s.gender) == 0 and 1 or 2)
  elseif st == 1 or st == 2 then
    t.str(3, s.playerName)
    t.set(3)
  elseif st == 3 then
    t.set(n(s.gender) == 0 and 4 or 5)
  elseif st == 4 or st == 5 then
    t.str(3, s.playerName)
    t.set(6)
  elseif st == 6 then
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5708
SHOW[Tv.TVSHOW_TREASURE_INVESTIGATORS] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.itemName(1, s.item)
    if n(s.location) == constId("region_map_sections", "MAPSEC_DYNAMIC") and SS_TIDAL_LAYOUTS[n(s.mapLayoutId)] then
      t.set(2)
    else
      t.set(1)
    end
  elseif st == 1 then
    t.itemName(1, s.item)
    t.str(2, s.playerName)
    t.map(3, s.location)
    t.done()
  elseif st == 2 then
    t.itemName(1, s.item)
    t.str(2, s.playerName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5754
SHOW[Tv.TVSHOW_FIND_THAT_GAMER] = function(t)
  local s, st = t.show, t.state
  local game = n(s.whichGame)
  local function gameName(i, swap)
    local g = swap and (1 - game) or game
    if g == 0 then t.str(i, N.text("gText_Slots")) elseif g == 1 then t.str(i, N.text("gText_Roulette")) end
  end
  if st == 0 then
    t.str(1, s.playerName)
    gameName(2)
    if s.won == true or s.won == 1 then t.set(1) else t.set(2) end
  elseif st == 1 then
    t.str(1, s.playerName)
    gameName(2)
    t.num(2, s.nCoins)
    t.done()
  elseif st == 2 then
    t.str(1, s.playerName)
    gameName(2)
    t.num(2, s.nCoins)
    t.set(3)
  elseif st == 3 then
    t.str(1, s.playerName)
    gameName(2, true)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5824
SHOW[Tv.TVSHOW_BREAKING_NEWS] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    if n(s.outcome) == 0 then t.set(1) else t.set(5) end
  elseif st == 1 or st == 5 or st == 9 or st == 10 then
    t.str(1, s.playerName)
    t.species(2, s.lastOpponentSpecies)
    t.map(3, s.location)
    if st == 1 then t.set(2) elseif st == 5 then t.set(6) else t.set(11) end
  elseif st == 2 then
    t.str(1, s.playerName)
    t.species(2, s.lastOpponentSpecies)
    t.species(3, s.poke1Species)
    t.set(3)
  elseif st == 3 then
    t.num(0, s.balls)
    t.itemName(2, s.caughtMonBall)
    t.set(4)
  elseif st == 4 then
    t.str(1, s.playerName)
    t.map(2, s.location)
    t.done()
  elseif st == 6 then
    t.str(1, s.playerName)
    t.species(2, s.lastOpponentSpecies)
    t.species(3, s.poke1Species)
    local o = n(s.outcome)
    if o == 1 then
      t.set(n(s.lastUsedMove) == 0 and 12 or 7)
    elseif o == 2 then
      t.set(9)
    elseif o == 3 then
      t.set(10)
    end
  elseif st == 7 then
    t.moveName(1, s.lastUsedMove)
    t.species(2, s.poke1Species)
    t.set(8)
  elseif st == 12 then
    t.str(1, s.playerName)
    t.species(2, s.lastOpponentSpecies)
    t.species(3, s.poke1Species)
    t.set(8)
  elseif st == 8 then
    t.str(1, s.playerName)
    t.map(2, s.location)
    t.set(11)
  elseif st == 11 then
    t.str(1, s.playerName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5919
SHOW[Tv.TVSHOW_SECRET_BASE_VISIT] = function(t)
  local s, st = t.show, t.state
  local d = s.decorations or {}
  local nd = n(s.numDecorations)
  if st == 0 then
    t.str(1, s.playerName)
    t.set(nd == 0 and 2 or 1)
  elseif st == 1 then
    t.str(2, N.decoration(d[1]))
    t.set(nd == 1 and 4 or 3)
  elseif st == 3 then
    t.str(2, N.decoration(d[2]))
    if nd == 2 then t.set(7) elseif nd == 3 then t.set(6) elseif nd == 4 then t.set(5) end
  elseif st == 5 then
    t.str(2, N.decoration(d[3]))
    t.str(3, N.decoration(d[4]))
    t.set(8)
  elseif st == 6 then
    t.str(2, N.decoration(d[3]))
    t.set(8)
  elseif st == 2 or st == 4 or st == 7 then
    t.set(8)
  elseif st == 8 then
    t.str(1, s.playerName)
    local lv = n(s.avgLevel)
    if lv < 25 then t.set(12) elseif lv < 50 then t.set(11) elseif lv < 70 then t.set(10) else t.set(9) end
  elseif st >= 9 and st <= 12 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.moveName(3, s.move)
    t.set(13)
  elseif st == 13 then
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:5999
SHOW[Tv.TVSHOW_LOTTO_WINNER] = function(t)
  local s, st = t.show, t.state
  t.str(1, s.playerName)
  local p = n(s.whichPrize)
  t.str(2, N.text(p == 0 and "gText_Jackpot" or (p == 1 and "gText_First" or (p == 2 and "gText_Second" or "gText_Third"))))
  t.itemName(3, s.item)
  t.done()
  return st
end

-- pokeemerald/src/tv.c:6021
SHOW[Tv.TVSHOW_BATTLE_SEMINAR] = function(t)
  local s, st = t.show, t.state
  local o = s.otherMoves or {}
  if st == 0 then
    t.str(1, s.playerName)
    t.species(2, s.species)
    t.species(3, s.foeSpecies)
    t.set(1)
  elseif st == 1 then
    t.str(1, s.playerName)
    t.species(2, s.foeSpecies)
    t.moveName(3, s.move)
    t.set(2)
  elseif st == 2 then
    t.species(1, s.species)
    local c = n(s.nOtherMoves)
    if c == 1 then t.set(5) elseif c == 2 then t.set(4) elseif c == 3 then t.set(3) else t.set(6) end
  elseif st == 3 then
    t.moveName(1, o[1])
    t.moveName(2, o[2])
    t.moveName(3, o[3])
    t.set(6)
  elseif st == 4 then
    t.moveName(1, o[1])
    t.moveName(2, o[2])
    t.set(6)
  elseif st == 5 then
    t.moveName(2, o[1])
    t.set(6)
  elseif st == 6 then
    t.moveName(1, s.betterMove)
    t.moveName(2, s.move)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:6085
SHOW[Tv.TVSHOW_FAN_CLUB_SPECIAL] = function(t)
  local s, st = t.show, t.state
  local score = n(s.score)
  t.str(1, s.idolName)
  t.str(2, s.playerName)
  if st == 0 then
    t.word(3, s.words and s.words[1])
    if score >= 90 then t.set(1) elseif score >= 70 then t.set(2) elseif score >= 30 then t.set(3) else t.set(4) end
  elseif st >= 1 and st <= 4 then
    t.num(2, score)
    t.set(5)
  elseif st == 5 then
    t.word(3, s.words and s.words[1])
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:6142
SHOW[Tv.TVSHOW_TRAINER_FAN_CLUB] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    local id = n(s.trainerIdHi) * 256 + n(s.trainerIdLo)
    t.set(id % 10 + 1)
  elseif st >= 1 and st <= 10 then
    t.set(11)
  elseif st == 11 then
    t.str(1, s.playerName)
    t.word(2, s.words and s.words[1])
    t.word(3, s.words and s.words[2])
    t.done()
  end
  return st
end

local CUTIES_RIBBON_STATE = {
  [0] = 5, [1] = 6, [2] = 6, [3] = 6, [4] = 6, [5] = 7, [6] = 7, [7] = 7, [8] = 7,
  [9] = 8, [10] = 8, [11] = 8, [12] = 8, [13] = 9, [14] = 9, [15] = 9, [16] = 9,
  [17] = 10, [18] = 10, [19] = 10, [20] = 10, [21] = 11, [22] = 12, [23] = 13, [24] = 14,
}

-- pokeemerald/src/tv.c:6230
SHOW[Tv.TVSHOW_CUTIES] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    t.str(2, s.nickname)
    local r = n(s.nRibbons)
    if r < 10 then t.set(1) elseif r < 20 then t.set(2) else t.set(3) end
  elseif st >= 1 and st <= 3 then
    t.str(1, s.playerName)
    t.str(2, s.nickname)
    t.num(2, s.nRibbons)
    t.set(4)
  elseif st == 4 then
    t.str(2, s.nickname)
    local nx = CUTIES_RIBBON_STATE[n(s.selectedRibbon)]
    if nx then t.set(nx) end
  elseif st >= 5 and st <= 14 then
    t.str(2, s.nickname)
    t.set(15)
  elseif st == 15 then
    t.done()
  end
  return st
end

local FRONTIER_NEXT = { [1] = 14, [2] = 16, [3] = 15, [4] = 15 }

-- pokeemerald/src/tv.c:6336
SHOW[Tv.TVSHOW_FRONTIER] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    local m = n(s.facilityAndMode)
    if m >= 1 and m <= 13 then t.set(m) end
  elseif st >= 1 and st <= 13 then
    t.str(1, s.playerName)
    t.num(1, s.winStreak)
    t.set(FRONTIER_NEXT[st] or 14)
  elseif st == 14 or st == 16 then
    t.species(1, s.species1)
    t.species(2, s.species2)
    t.species(3, s.species3)
    t.set(st == 14 and 18 or 17)
  elseif st == 15 then
    t.species(1, s.species1)
    t.species(2, s.species2)
    t.set(18)
  elseif st == 17 then
    t.species(1, s.species4)
    t.set(18)
  elseif st == 18 then
    t.str(1, s.playerName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:6484
SHOW[Tv.TVSHOW_NUMBER_ONE] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, s.playerName)
    local a = n(s.actionIdx)
    if a >= 0 and a <= 6 then t.set(a + 1) end
  elseif st >= 1 and st <= 7 then
    t.str(1, s.playerName)
    t.num(1, s.count)
    t.set(8)
  elseif st == 8 then
    t.str(1, s.playerName)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:6564
function Tv.secretBaseSecretsActions(show)
  local c = 0
  local flags = n(show.flags)
  for i = 0, Tv.NUM_SECRET_BASE_FLAGS - 1 do
    if math.floor(flags / 2 ^ i) % 2 == 1 then c = c + 1 end
  end
  return c
end

-- pokeemerald/src/tv.c:6577
local function secretsStateByFlag(show, flagId)
  local d = Tv.data()
  local actions = assert(d and d.secretBaseSecretsActions, "tv/manifest.lua is not in the cache")
  local set = 0
  local flags = n(show.flags)
  for i = 0, Tv.NUM_SECRET_BASE_FLAGS - 1 do
    if math.floor(flags / 2 ^ i) % 2 == 1 then
      if set == flagId then return n(actions[i + 1]) end
      set = set + 1
    end
  end
  return 0
end

-- pokeemerald/src/tv.c:6595
SHOW[Tv.TVSHOW_SECRET_BASE_SECRETS] = function(t)
  local s, st = t.show, t.state
  local R = Tv._sbRandom
  if st == 0 then
    t.str(1, s.baseOwnersName)
    t.str(2, s.playerName)
    local count = Tv.secretBaseSecretsActions(s)
    if count == 0 then
      t.set(8)
    else
      s.savedState = 1
      R[1] = random() % count
      t.set(secretsStateByFlag(s, R[1]))
    end
  elseif st == 1 then
    t.str(2, s.playerName)
    local count = Tv.secretBaseSecretsActions(s)
    if count == 1 then
      t.set(9)
    elseif count == 2 then
      s.savedState = 2
      t.set(secretsStateByFlag(s, R[1] == 0 and 1 or 0))
    else
      for _ = 1, 0xFFFF do
        R[2] = random() % count
        if R[2] ~= R[1] then break end
      end
      s.savedState = 2
      t.set(secretsStateByFlag(s, R[2]))
    end
  elseif st == 2 then
    t.str(2, s.playerName)
    local count = Tv.secretBaseSecretsActions(s)
    if count == 2 then
      t.set(9)
    else
      for _ = 1, 0xFFFF do
        R[3] = random() % count
        if R[3] ~= R[1] and R[3] ~= R[2] then break end
      end
      s.savedState = 3
      t.set(secretsStateByFlag(s, R[3]))
    end
  elseif st == 3 then
    t.str(1, s.baseOwnersName)
    t.str(2, s.playerName)
    t.num(2, s.stepsInBase)
    local steps = n(s.stepsInBase)
    if steps <= 30 then t.set(4) elseif steps <= 100 then t.set(5) else t.set(6) end
  elseif st >= 4 and st <= 6 then
    t.str(1, s.baseOwnersName)
    t.str(2, s.playerName)
    t.set(7)
  elseif st == 7 then
    t.str(1, s.baseOwnersName)
    t.str(2, s.playerName)
    t.done()
  elseif st == 8 or st == 9 then
    t.set(3)
  elseif st >= 10 and st <= 18 then
    t.set(n(s.savedState))
  elseif st == 19 then
    t.itemName(2, s.item)
    t.set(n(s.savedState))
  elseif st == 20 then
    t.set(n(s.trainerIdLo) % 2 == 1 and 22 or 21)
  elseif st >= 21 and st <= Tv.SBSECRETS_NUM_STATES then
    t.set(n(s.savedState))
  end
  return st
end

-- pokeemerald/src/tv.c:6717
SHOW[Tv.TVSHOW_SAFARI_FAN_CLUB] = function(t)
  local s, st = t.show, t.state
  local caught, blocks = n(s.monsCaught), n(s.pokeblocksUsed)
  if st == 0 then
    if caught == 0 then t.set(6) elseif caught < 4 then t.set(5) else t.set(1) end
  elseif st == 1 then
    t.str(1, s.playerName)
    t.num(1, caught)
    t.set(blocks == 0 and 3 or 2)
  elseif st == 2 then
    t.num(1, blocks)
    t.set(4)
  elseif st == 3 then
    t.set(4)
  elseif st == 4 then
    t.str(1, s.playerName)
    t.set(10)
  elseif st == 5 then
    t.str(1, s.playerName)
    t.num(1, caught)
    t.set(blocks == 0 and 8 or 7)
  elseif st == 6 then
    t.str(1, s.playerName)
    t.set(blocks == 0 and 8 or 7)
  elseif st == 7 then
    t.num(1, blocks)
    t.set(9)
  elseif st == 8 then
    t.set(9)
  elseif st == 9 then
    t.str(1, s.playerName)
    t.set(10)
  elseif st == 10 then
    t.done()
  end
  return st
end

-- pokeemerald/include/constants/lilycove_lady.h:26
local CONTEST_LADY_NORMAL, CONTEST_LADY_GOOD = 0, 1

-- pokeemerald/src/tv.c:6788
SHOW[Tv.TVSHOW_LILYCOVE_CONTEST_LADY] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.str(1, N.text(string.format("sContestNames[%d]", n(s.contestCategory))))
    local p = n(s.pokeblockState)
    if p == CONTEST_LADY_GOOD then t.set(1) elseif p == CONTEST_LADY_NORMAL then t.set(2) else t.set(3) end
  elseif st == 1 or st == 2 or st == 3 then
    if st ~= 3 then t.str(3, s.playerName) end
    t.str(2, s.nickname)
    t.done()
  end
  return st
end

-- pokeemerald/src/tv.c:4198
function Tv.doTVShow(session, idx, sv)
  session = sessionOf(session)
  sv = sv or {}
  local list = shows(session)
  local show = list[n(idx)]
  if not (show and show.active == true) then return nil, nil end
  local fn = SHOW[n(show.kind)]
  if not fn then return nil, nil end
  Tv._result = false
  local t = context(show, sv)
  t.session = session
  t.idx = n(idx)
  local st, text = fn(t)
  local done = Tv._result == true
  if text ~= nil then return { text = text }, done end
  if st == nil then return nil, done end
  return { group = group(n(show.kind)), index = st }, done
end

-- pokeemerald/src/tv.c:5427
function Tv.doInSearchOfTrainers(session, sv)
  local g = Tv.state(sessionOf(session)).gabbyAndTyData
  sv = sv or {}
  Tv._result = false
  local st = Tv._showState
  if st == 0 then
    sv[1] = N.mapName(g.mapnum)
    Tv._showState = n(g.battleNum) > 1 and 1 or 2
  elseif st == 1 then
    Tv._showState = 2
  elseif st == 2 then
    if not g.battleTookMoreThanOneTurn then Tv._showState = 4
    elseif g.playerThrewABall then Tv._showState = 5
    elseif g.playerUsedHealingItem then Tv._showState = 6
    elseif g.playerLostAMon then Tv._showState = 7
    else Tv._showState = 3 end
  elseif st == 3 then
    sv[1] = N.species(g.mon1)
    sv[2] = N.move(g.lastMove)
    sv[3] = N.species(g.mon2)
    Tv._showState = 8
  elseif st >= 4 and st <= 7 then
    Tv._showState = 8
  elseif st == 8 then
    sv[1] = N.word(g.quote and g.quote[0])
    sv[2] = N.species(g.mon1)
    sv[3] = N.species(g.mon2)
    Tv._result = true
    Tv._showState = 0
    g.onAir = false
  end
  return { group = "sTVInSearchOfTrainersTextGroup", index = st }, Tv._result
end

-- pokeemerald/src/tv.c:3442
function Tv.hideBattleTowerReporter(session)
  setVar("VAR_BRAVO_TRAINER_BATTLE_TOWER_ON", 0, session)
  setFlag("FLAG_HIDE_BATTLE_TOWER_REPORTER", true, session)
end

-- pokeemerald/include/global.h:1036
Tv.SAVE_FIELDS = { "tvShows", "pokeNews", "gabbyAndTyData" }
for _, f in ipairs(Tv.OUTBREAK_FIELDS) do Tv.SAVE_FIELDS[#Tv.SAVE_FIELDS + 1] = f end

do
  local ok, SaveSections = pcall(require, "src.core.game3.save_sections")
  if ok and SaveSections and SaveSections.register then
    local def = SaveSections.fields(Tv.SAVE_FIELDS, function(session) Tv.newGame(session) end)
    local restore = def.restore
    def.restore = function(save, session)
      restore(save, session)
      Tv.state(session)
      Tv.syncOutbreak(session)
    end
    SaveSections.register("tv", def)
  end
end

local function lifecycleCall(session, method, ...)
  if type(session) ~= "table" then return false end
  local p = require("src.core.game3.profile").forSession(session)
  local policy = p.tv and p.tv.lifecycle
  if type(policy) == "string" then policy = require(policy) end
  if type(policy) ~= "table" then return false end
  if type(policy[method]) == "function" then return true, policy[method](session, ...) end
  if policy.unsupported and policy.unsupported[method] then return true end
  return false
end
local function lifecycleMethod(method)
  local original = assert(Tv[method], "TV lifecycle function missing: " .. method)
  Tv[method] = function(session, ...)
    local handled, a, b, c = lifecycleCall(sessionOf(session), method, ...)
    if handled then return a, b, c end
    return original(session, ...)
  end
end
for _, method in ipairs({
  "clearTVShowData", "resetGabbyAndTy", "findAnyShowOnAir", "gabbyAndTyBeforeInterview", "gabbyAndTyAfterInterview", "tryPutPokemonTodayOnAir",
  "initWorldOfMastersShowAttempt", "tryPutPokemonTodayFailedOnTheAir", "tryPutSmartShopperOnAir",
  "bravoTrainerPokemonProfileBeforeInterview1", "bravoTrainerPokemonProfileBeforeInterview2",
  "syncOutbreak", "endMassOutbreak", "tryStartRandomMassOutbreak", "recordFishingAttempt", "tryPutFishingAdviceOnAir",
  "tryPutRandomPokeNewsOnAir", "updatePerDay", "interviewBefore", "interviewAfter", "onBattleEnd",
  "tryPutTodaysRivalTrainerOnAir", "tryPutTrendWatcherOnAir", "tryPutTreasureInvestigatorsOnAir",
  "tryPutFindThatGamerOnAir", "tryPutBreakingNewsOnAir", "tryPutSecretBaseVisitOnAir", "tryPutLotteryWinnerReportOnAir",
  "tryPutBattleSeminarOnAir", "tryPutSafariFanClubOnAir", "tryPutSpotTheCutiesOnAir", "putSpotTheCutiesOnAir",
  "tryPutTrainerFanClubOnAir", "tryPutFrontierTVShowOnAir", "tryPutSecretBaseSecretsOnAir",
  "incrementDailySlotsUses", "incrementDailyRouletteUses", "incrementDailyWildBattles", "incrementDailyBerryBlender",
  "incrementDailyPlantedBerries", "incrementDailyPickedBerries", "incrementDailyBattlePoints",
}) do lifecycleMethod(method) end
do
  local original = Tv.shouldApplyPokeNews
  Tv.shouldApplyPokeNews = function(kind, session, talked)
    local handled, value = lifecycleCall(sessionOf(session), "shouldApplyPokeNews", kind, talked)
    if handled then return value end
    return original(kind, session, talked)
  end
end
local function lifecycleNoSession(method)
  local original = Tv[method]
  Tv[method] = function(...)
    local handled, a, b, c = lifecycleCall(sessionOf(nil), method, ...)
    if handled then return a, b, c end
    return original(...)
  end
end
lifecycleNoSession("alertPlayedSlotMachine")
lifecycleNoSession("alertPlayedRoulette")

local NO_SESSION = {
  shouldApplyPokeNews = true, setPokemonAnglerSpecies = true, alertPlayedSlotMachine = true,
  alertPlayedRoulette = true, groupOf = true, ribbonCount = true, ribbonOf = true,
}

Tv.api = setmetatable({
  isPokeNewsActive = function(kind)
    return Tv.isPokeNewsActive(sessionOf(nil), kind, Tv.shouldApplyPokeNews)
  end,
}, {
  __index = function(_, k)
    local f = Tv[k]
    if type(f) ~= "function" then return nil end
    if NO_SESSION[k] then return f end
    return function(...) return f(sessionOf(nil), ...) end
  end,
})

do
  local ok, R = pcall(require, "src.core.game3.rse.init")
  if ok and R and R.register then R.register("tv", Tv.api) end
end

return Tv
