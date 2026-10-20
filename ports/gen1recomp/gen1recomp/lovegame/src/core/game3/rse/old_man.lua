local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")

local bit = require("bit")

local OldMan = {}

-- pokeemerald/include/constants/mauville_old_man.h:4
OldMan.BARD, OldMan.HIPSTER, OldMan.TRADER, OldMan.STORYTELLER, OldMan.GIDDY = 0, 1, 2, 3, 4
-- pokeemerald/include/constants/global.h:117
OldMan.NUM_BARD_SONG_WORDS = 6
OldMan.NUM_STORYTELLER_TALES = 4
OldMan.NUM_TRADER_ITEMS = 4
OldMan.GIDDY_MAX_TALES = 10
OldMan.GIDDY_MAX_QUESTIONS = 8
OldMan.NUM_TRENDY_SAYINGS = 33
-- pokeemerald/include/constants/decorations.h:125
OldMan.NUM_DECORATIONS = 120

function OldMan.state(sess)
  sess = Town.session(sess)
  if not sess then return nil end
  if type(sess.oldMan) ~= "table" or sess.oldMan.id == nil then OldMan.set(sess) end
  return sess.oldMan
end

local function copy(list, n, fill)
  local out = {}
  for i = 1, n do out[i] = list and list[i] or fill end
  return out
end

-- pokeemerald/src/mauville_old_man.c:74
local function setupBard(sess)
  local lyrics = Town.data().bard.defaultLyrics
  return { id = OldMan.BARD, hasChangedSong = false, language = Town.GAME_LANGUAGE,
    songLyrics = copy(lyrics, OldMan.NUM_BARD_SONG_WORDS, 0), newSongLyrics = copy(nil, OldMan.NUM_BARD_SONG_WORDS, 0),
    playerName = "", playerTrainerId = 0 }
end

-- pokeemerald/src/mauville_old_man.c:86
local function setupHipster()
  return { id = OldMan.HIPSTER, taughtWord = false, language = Town.GAME_LANGUAGE }
end

-- pokeemerald/src/mauville_old_man.c:1201
local function setupStoryteller()
  return { id = OldMan.STORYTELLER, alreadyRecorded = false, gameStatIDs = copy(nil, OldMan.NUM_STORYTELLER_TALES, 0),
    trainerNames = copy(nil, OldMan.NUM_STORYTELLER_TALES, ""), statValues = copy(nil, OldMan.NUM_STORYTELLER_TALES, 0),
    language = copy(nil, OldMan.NUM_STORYTELLER_TALES, 0) }
end

-- pokeemerald/src/mauville_old_man.c:100
local function setupGiddy()
  return { id = OldMan.GIDDY, taleCounter = 0, questionNum = 0, language = Town.GAME_LANGUAGE,
    randomWords = copy(nil, OldMan.GIDDY_MAX_TALES, 0), questionList = copy(nil, OldMan.GIDDY_MAX_QUESTIONS, 0) }
end

-- pokeemerald/src/trader.c:34
local function setupTrader()
  local d = Town.data().oldMan
  local RomText = require("src.core.game3.rom_text")
  local t = { id = OldMan.TRADER, alreadyTraded = false, decorations = {}, playerNames = {}, language = {} }
  for i = 1, OldMan.NUM_TRADER_ITEMS do
    t.playerNames[i] = RomText.plain(d.traderNames[i])
    t.decorations[i] = d.traderDecorations[i]
    t.language[i] = Town.GAME_LANGUAGE
  end
  return t
end

-- pokeemerald/src/mauville_old_man.c:114
function OldMan.set(sess)
  sess = Town.session(sess)
  local which = math.floor((Town.trainerId16(sess) % 10) / 2)
  local m
  if which == OldMan.BARD then m = setupBard(sess)
  elseif which == OldMan.HIPSTER then m = setupHipster()
  elseif which == OldMan.TRADER then m = setupTrader()
  elseif which == OldMan.STORYTELLER then m = setupStoryteller()
  else m = setupGiddy() end
  if sess then sess.oldMan = m end
  return m
end

function OldMan.current(sess)
  return OldMan.state(sess).id
end

-- pokeemerald/src/mauville_old_man.c:399
function OldMan.resetFlag(sess)
  local m = OldMan.state(sess)
  if m.id == OldMan.BARD then m.hasChangedSong = false
  elseif m.id == OldMan.HIPSTER then m.taughtWord = false
  elseif m.id == OldMan.STORYTELLER then m.alreadyRecorded = false
  elseif m.id == OldMan.TRADER then m.alreadyTraded = false end
end

-- pokeemerald/src/mauville_old_man.c:156
function OldMan.saveBardSongLyrics(sess)
  sess = Town.session(sess)
  local b = OldMan.state(sess)
  local policy = require("src.core.game3.profile").forSession(sess).oldMan
  if policy and policy.saveBardSongLyrics then
    return policy.saveBardSongLyrics(sess, b)
  end
  b.playerName = Town.playerName(sess)
  b.playerTrainerId = tonumber(sess and sess.trainerId) or 0
  for i = 1, OldMan.NUM_BARD_SONG_WORDS do b.songLyrics[i] = b.newSongLyrics[i] end
  b.hasChangedSong = true
end

function OldMan.lyrics(useNew, sess)
  local b = OldMan.state(sess)
  return useNew and b.newSongLyrics or b.songLyrics
end

-- pokeemerald/src/mauville_old_man.c:176
function OldMan.songText(useNew, sess)
  local lyrics = OldMan.lyrics(useNew, sess)
  return Town.words({ lyrics[1], lyrics[2], lyrics[3] }, 2, 2):gsub("\n$", ""),
    Town.words({ lyrics[4], lyrics[5], lyrics[6] }, 2, 2):gsub("\n$", "")
end

local function sayings(sess)
  sess = Town.session(sess)
  local t = sess.unlockedTrendySayings
  if type(t) ~= "table" then
    t = { 0, 0, 0, 0, 0 }
    sess.unlockedTrendySayings = t
  end
  return t
end

-- pokeemerald/src/easy_chat.c:5445
function OldMan.isTrendySayingUnlocked(i, sess)
  local t = sayings(sess)
  return bit.band(bit.rshift(t[math.floor(i / 8) + 1] or 0, i % 8), 1) == 1
end

-- pokeemerald/src/easy_chat.c:5452
function OldMan.unlockTrendySaying(i, sess)
  if i >= OldMan.NUM_TRENDY_SAYINGS then return end
  local t = sayings(sess)
  local b = math.floor(i / 8) + 1
  t[b] = bit.bor(t[b] or 0, bit.lshift(1, i % 8))
end

-- pokeemerald/src/easy_chat.c:5476
function OldMan.unlockRandomTrendySaying(sess)
  local n = 0
  for i = 0, OldMan.NUM_TRENDY_SAYINGS - 1 do
    if OldMan.isTrendySayingUnlocked(i, sess) then n = n + 1 end
  end
  if n == OldMan.NUM_TRENDY_SAYINGS then return Town.EC_EMPTY_WORD end
  local skip = Town.random() % (OldMan.NUM_TRENDY_SAYINGS - n)
  for i = 0, OldMan.NUM_TRENDY_SAYINGS - 1 do
    if not OldMan.isTrendySayingUnlocked(i, sess) then
      if skip > 0 then
        skip = skip - 1
      else
        OldMan.unlockTrendySaying(i, sess)
        return require("src.core.game3.easy_chat_text").encodeWord(Town.EC_GROUP.TRENDY_SAYING, i)
      end
    end
  end
  return Town.EC_EMPTY_WORD
end

-- pokeemerald/src/mauville_old_man.c:317
local function initGiddyTaleList(g, sess)
  local G = Town.EC_GROUP
  local groups = { G.POKEMON, G.LIFESTYLE, G.HOBBIES, G.MOVE_1, G.MOVE_2, G.POKEMON_NATIONAL }
  for i = 1, OldMan.GIDDY_MAX_QUESTIONS do g.questionList[i] = i - 1 end
  for i = 0, OldMan.GIDDY_MAX_QUESTIONS - 1 do
    local v = Town.random() % (i + 1)
    g.questionList[i + 1], g.questionList[v + 1] = g.questionList[v + 1], g.questionList[i + 1]
  end
  local counts, total = {}, 0
  for i, gid in ipairs(groups) do
    counts[i] = Town.numWordsInGroup(gid, sess)
    total = (total + counts[i]) % 0x10000
  end
  g.questionNum = 0
  local questions = 0
  for i = 0, OldMan.GIDDY_MAX_TALES - 1 do
    local v = Town.random() % 10
    if v < 3 and questions < OldMan.GIDDY_MAX_QUESTIONS then
      g.randomWords[i + 1] = Town.EC_EMPTY_WORD
      questions = questions + 1
    else
      local randWord = total > 0 and (Town.random() % total) or 0
      if randWord >= 0x8000 then randWord = randWord - 0x10000 end
      local var = 0
      if i < #groups then
        while true do
          randWord = randWord - counts[var + 1]
          if randWord <= 0 then break end
          var = var + 1
          if var >= #groups then break end
        end
      end
      if var == #groups then var = 0 end
      g.randomWords[i + 1] = Town.randomWordFromUnlockedGroup(groups[var + 1], sess)
    end
  end
end

-- pokeemerald/src/mauville_old_man.c:267
function OldMan.giddyShouldTellAnotherTale(sess)
  local g = OldMan.state(sess)
  if g.taleCounter == OldMan.GIDDY_MAX_TALES then
    g.taleCounter = 0
    return false
  end
  return true
end

-- pokeemerald/src/mauville_old_man.c:282
function OldMan.generateGiddyLine(sess)
  local RomText = require("src.core.game3.rom_text")
  local d = Town.data().oldMan
  local g = OldMan.state(sess)
  if g.taleCounter == 0 then initGiddyTaleList(g, sess) end
  local line
  local w = g.randomWords[g.taleCounter + 1]
  if w ~= Town.EC_EMPTY_WORD then
    local adjective = Town.random() % #d.giddyAdjectives
    line = Town.word(w) .. RomText.plain("GiddyText_Is") .. RomText.plain(d.giddyAdjectives[adjective + 1])
      .. RomText.plain("GiddyText_DontYouAgree")
  else
    line = RomText.plain(d.giddyQuestions[(g.questionList[g.questionNum + 1] or 0) + 1])
    g.questionNum = g.questionNum + 1
  end
  if Town.random() % 10 == 0 then
    g.taleCounter = OldMan.GIDDY_MAX_TALES
  else
    g.taleCounter = g.taleCounter + 1
  end
  return line
end

-- pokeemerald/src/mauville_old_man.c:1223
local function storyStat(stat)
  if stat == 50 then return 0 end
  return stat
end

local function storyByStat(stat)
  local stories = Town.data().oldMan.stories
  for _, s in ipairs(stories) do
    if s.stat == stat then return s end
  end
  return stories[#stories]
end
OldMan.storyByStat = storyByStat

function OldMan.gameStat(stat, sess)
  return Town.gameStat(sess, storyStat(stat))
end

-- pokeemerald/src/mauville_old_man.c:1257
function OldMan.freeStorySlot(sess)
  local s = OldMan.state(sess)
  for i = 1, OldMan.NUM_STORYTELLER_TALES do
    if (s.gameStatIDs[i] or 0) == 0 then return i - 1 end
  end
  return OldMan.NUM_STORYTELLER_TALES
end

-- pokeemerald/src/mauville_old_man.c:1310
local function recordNewStat(slot, stat, sess)
  local s = OldMan.state(sess)
  local policy = require("src.core.game3.profile").forSession(Town.session(sess)).oldMan
  if policy and policy.recordStoryStat then
    local value = OldMan.gameStat(stat, sess)
    policy.recordStoryStat(Town.session(sess), s, slot, stat, value)
    return value, storyByStat(stat).action
  end
  s.gameStatIDs[slot + 1] = stat
  s.trainerNames[slot + 1] = Town.playerName(sess):sub(1, 7)
  s.statValues[slot + 1] = OldMan.gameStat(stat, sess)
  s.language[slot + 1] = Town.GAME_LANGUAGE
  return OldMan.gameStat(stat, sess), storyByStat(stat).action
end

-- pokeemerald/src/mauville_old_man.c:1320
local function scrambleStatList(count)
  local arr = {}
  for i = 0, count - 1 do arr[i + 1] = i end
  for _ = 1, count do
    local a = Town.random() % count
    local b = Town.random() % count
    arr[a + 1], arr[b + 1] = arr[b + 1], arr[a + 1]
  end
  return arr
end

OldMan.selectedStory = 0

-- pokeemerald/src/mauville_old_man.c:1335
function OldMan.initializeRandomStat(sess)
  local s = OldMan.state(sess)
  local stories = Town.data().oldMan.stories
  local order = scrambleStatList(#stories)
  for i = 1, #stories do
    local story = stories[order[i] + 1]
    local present = false
    for j = 1, OldMan.NUM_STORYTELLER_TALES do
      if s.gameStatIDs[j] == story.stat then present = true; break end
    end
    if not present and OldMan.gameStat(story.stat, sess) >= story.minVal then
      s.alreadyRecorded = true
      local slot = OldMan.freeStorySlot(sess)
      if slot == OldMan.NUM_STORYTELLER_TALES then slot = OldMan.selectedStory end
      return true, recordNewStat(slot, story.stat, sess)
    end
  end
  return false
end

-- pokeemerald/src/mauville_old_man.c:1453
function OldMan.updateStat(sess)
  local s = OldMan.state(sess)
  local i = OldMan.selectedStory
  local stat = s.gameStatIDs[i + 1]
  if OldMan.gameStat(stat, sess) > (s.statValues[i + 1] or 0) then
    return true, recordNewStat(i, stat, sess)
  end
  return false
end

-- pokeemerald/src/mauville_old_man.c:1364
function OldMan.story(slot, sess)
  local s = OldMan.state(sess)
  local story = storyByStat(s.gameStatIDs[slot + 1])
  return story, s.statValues[slot + 1] or 0, s.trainerNames[slot + 1] or ""
end

function OldMan.storyTitles(sess)
  local RomText = require("src.core.game3.rom_text")
  local s = OldMan.state(sess)
  local out = {}
  for i = 1, OldMan.NUM_STORYTELLER_TALES do
    local stat = s.gameStatIDs[i] or 0
    if stat == 0 then break end
    out[#out + 1] = RomText.plain(storyByStat(stat).title)
  end
  return out
end

-- pokeemerald/src/trader.c:199
function OldMan.traderDoTrade(receive, give, slot, sess)
  local Inv = require("src.core.game3.rse.decoration_inventory")
  local t = OldMan.state(sess)
  local policy = require("src.core.game3.profile").forSession(Town.session(sess)).oldMan
  if policy and policy.traderDoTrade then
    return policy.traderDoTrade(Town.session(sess), t, receive, give, slot)
  end
  Inv.remove(give, sess)
  Inv.add(receive, sess)
  t.playerNames[slot + 1] = Town.playerName(sess)
  t.decorations[slot + 1] = give
  t.language[slot + 1] = Town.GAME_LANGUAGE
  t.alreadyTraded = true
end

function OldMan.mixExport(sess)
  local function deep(v)
    if type(v) ~= "table" then return v end
    local o = {}
    for k, x in pairs(v) do o[k] = deep(x) end
    return o
  end
  return deep(OldMan.state(sess))
end

-- pokeemerald/src/mauville_old_man.c:858
local function sanitizeReceived(m, language)
  if m.id ~= OldMan.STORYTELLER or language ~= 1 then return end
  for i = 1, OldMan.NUM_STORYTELLER_TALES do
    if (tonumber(m.gameStatIDs and m.gameStatIDs[i]) or 0) ~= 0 then
      m.language = m.language or {}
      m.language[i] = Town.GAME_LANGUAGE
    end
  end
end

-- pokeemerald/src/record_mixing.c:629
function OldMan.mixImport(players, sess, myIndex)
  sess = Town.session(sess)
  local MixUtil = require("src.core.game3.rse.record_mix_util")
  local partner = MixUtil.partner(players or {}, tonumber(myIndex) or 1)
  local m = type(partner) == "table" and partner.oldMan or nil
  if type(m) ~= "table" or m.id == nil then return false end
  m = MixUtil.deep(m)
  sanitizeReceived(m, tonumber(partner.language) or Town.GAME_LANGUAGE)
  sess.oldMan = m
  OldMan.resetFlag(sess)
  return true
end

local SaveSections = require("src.core.game3.save_sections")
-- pokeemerald/src/new_game.c:191
SaveSections.register("oldMan", SaveSections.fields({ "oldMan" }, function(sess) OldMan.set(sess) end))

Rse.register("oldMan", OldMan)

return OldMan
