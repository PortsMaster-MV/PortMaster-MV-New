local Rse = require("src.core.game3.rse.init")

local Town = {}

Town.MANIFEST = "data/generated/gba/rse/misc/manifest.lua"

-- pokeemerald/include/constants/easy_chat.h:4
Town.EC_GROUP = {
  POKEMON = 0, TRAINER = 1, STATUS = 2, BATTLE = 3, GREETINGS = 4, PEOPLE = 5, VOICES = 6, SPEECH = 7,
  ENDINGS = 8, FEELINGS = 9, CONDITIONS = 10, ACTIONS = 11, LIFESTYLE = 12, HOBBIES = 13, TIME = 14,
  MISC = 15, ADJECTIVES = 16, EVENTS = 17, MOVE_1 = 18, MOVE_2 = 19, TRENDY_SAYING = 20, POKEMON_NATIONAL = 21,
}
Town.EC_NUM_GROUPS = 22
-- pokeemerald/include/constants/easy_chat.h:1129
Town.EC_EMPTY_WORD = 0xFFFF
-- pokeemerald/include/constants/global.h:30
Town.GAME_LANGUAGE = 2

local VALUE_GROUPS = { [0] = true, [18] = true, [19] = true, [21] = true }

local cached = {}

function Town.data()
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get()) .. ":" .. tostring(GameVersion.cachePrefix and GameVersion.cachePrefix() or "")
  if cached[key] then return cached[key] end
  local src = require("src.core.game3.dataset").cache():read(Town.MANIFEST)
  if type(src) ~= "string" then error("town_common: " .. Town.MANIFEST .. " missing from the cache", 0) end
  local t = assert(load(src, "@" .. Town.MANIFEST, "t", {}))()
  cached[key] = t
  return t
end

function Town.reset()
  cached = {}
end

function Town.session(sess)
  return sess or Rse.session()
end

function Town.trainerId16(sess)
  sess = Town.session(sess)
  return math.floor(tonumber(sess and (sess.trainerId or sess.playerId)) or 0) % 0x10000
end

function Town.random()
  return require("src.core.game3.rng").Random()
end

function Town.playerName(sess)
  sess = Town.session(sess)
  return tostring(sess and (sess.name or sess.playerName) or "")
end

function Town.setString(ctx, adapters, i, text)
  if adapters and adapters.setStringVar then adapters.setStringVar(i, text) end
  if ctx and ctx.stringVars then ctx.stringVars[i] = text end
end

function Town.gameStat(sess, id)
  sess = Town.session(sess)
  local stats = sess and sess.gameStats
  return math.floor(tonumber(type(stats) == "table" and stats[id]) or 0)
end

function Town.itemName(itemId)
  return tostring(require("src.core.game3.items_data").displayName(itemId) or "")
end

local function wordsTable()
  return require("src.core.game3.easy_chat_text").groups()
end

function Town.group(groupId)
  return wordsTable()[groupId]
end

-- pokeemerald/src/easy_chat.c:5353
function Town.randomWordFromGroup(groupId)
  local EasyChatText = require("src.core.game3.easy_chat_text")
  local g = assert(Town.group(groupId), "easy chat group " .. tostring(groupId) .. " missing")
  local index = Town.random() % g.numWords
  if VALUE_GROUPS[groupId] then index = g.words[index + 1].value end
  return EasyChatText.encodeWord(groupId, index)
end

local function flagOn(name, sess)
  local id = Rse.flagId(name, sess)
  return id ~= nil and Rse.flag(name, sess)
end

local function nationalDex(sess)
  local ok, PokedexData = pcall(require, "src.core.game3.pokedex_data")
  if not ok then return false end
  local okN, on = pcall(PokedexData.isNationalUnlocked, sess, sess and sess.dex)
  return okN and on == true
end

-- pokeemerald/src/easy_chat.c:5107
function Town.groupUnlocked(groupId, sess)
  sess = Town.session(sess)
  local G = Town.EC_GROUP
  if groupId == G.TRENDY_SAYING then return flagOn("FLAG_UNLOCKED_TRENDY_SAYINGS", sess) end
  if groupId == G.EVENTS or groupId == G.MOVE_1 or groupId == G.MOVE_2 then return flagOn("FLAG_SYS_GAME_CLEAR", sess) end
  if groupId == G.POKEMON_NATIONAL then return nationalDex(sess) end
  return true
end

local function seenSpecies(sess)
  local Dex = require("src.core.game3.dex")
  local dex = sess and sess.dex
  local g = Town.group(Town.EC_GROUP.POKEMON)
  local out = {}
  for _, w in ipairs(g.words) do
    if dex and Dex.isSeen(dex, w.value) then out[#out + 1] = w.value end
  end
  return out
end

-- pokeemerald/src/easy_chat.c:5124
function Town.numWordsInGroup(groupId, sess)
  sess = Town.session(sess)
  if groupId == Town.EC_GROUP.POKEMON then return #seenSpecies(sess) end
  if Town.groupUnlocked(groupId, sess) then return Town.group(groupId).numEnabled end
  return 0
end

-- pokeemerald/src/easy_chat.c:5533
local function randomUnlockedPokemon(sess)
  local seen = seenSpecies(sess)
  if #seen == 0 then return Town.EC_EMPTY_WORD end
  local index = Town.random() % #seen
  return require("src.core.game3.easy_chat_text").encodeWord(Town.EC_GROUP.POKEMON, seen[index + 1])
end

-- pokeemerald/src/easy_chat.c:5367
function Town.randomWordFromUnlockedGroup(groupId, sess)
  sess = Town.session(sess)
  if not Town.groupUnlocked(groupId, sess) then return Town.EC_EMPTY_WORD end
  if groupId == Town.EC_GROUP.POKEMON then return randomUnlockedPokemon(sess) end
  return Town.randomWordFromGroup(groupId)
end

function Town.word(wordId)
  if wordId == nil or wordId == Town.EC_EMPTY_WORD then return "" end
  return require("src.core.game3.easy_chat_text").word(wordId)
end

-- pokeemerald/src/easy_chat.c:5238
function Town.words(words, columns, rows)
  local out, index = {}, 1
  for r = 1, rows do
    local line = {}
    for _ = 1, columns do
      local w = words[index]
      if w ~= nil and w ~= Town.EC_EMPTY_WORD then line[#line + 1] = Town.word(w) end
      index = index + 1
    end
    out[r] = table.concat(line, " ")
  end
  return table.concat(out, "\n")
end

function Town.copyWords(words, n)
  local out = {}
  for i = 1, n do out[i] = tonumber(words and words[i]) or Town.EC_EMPTY_WORD end
  return out
end

function Town.showMessage(ctx, adapters, key)
  local RomText = require("src.core.game3.rom_text")
  local body = RomText.box(key, ctx)
  if ctx then ctx.messageOpen = true end
  local open = adapters and (adapters.openMessageStay or adapters.openMessageAsync)
  if open then
    open(body, nil)
  elseif adapters and adapters.openMessage then
    adapters.openMessage(body)
  end
end

return Town
