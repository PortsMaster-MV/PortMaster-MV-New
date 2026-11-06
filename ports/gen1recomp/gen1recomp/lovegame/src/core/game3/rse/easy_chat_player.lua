local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local Types = require("src.core.game3.rse.easy_chat_types")

local Player = {}

local G = Town.EC_GROUP
local function w(group, index) return group * 512 + index end

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004

-- pokeemerald/include/constants/global.h:99
Player.EASY_CHAT_BATTLE_WORDS_COUNT = 6
Player.PROFILE_WORDS = 4
Player.GOOD_SAYING_WORDS = 2

-- pokeemerald/src/easy_chat.c:1240
Player.DEFAULT_PROFILE = { w(G.PEOPLE, 41), w(G.ENDINGS, 32), w(G.TRAINER, 14), w(G.PEOPLE, 51) }
Player.DEFAULT_BATTLE = {
  easyChatBattleStart = { w(G.ENDINGS, 15), w(G.PEOPLE, 2), w(G.SPEECH, 37), w(G.VOICES, 3), w(G.GREETINGS, 3), w(G.VOICES, 0) },
  easyChatBattleWon = { w(G.VOICES, 58), w(G.VOICES, 58), w(G.VOICES, 1), w(G.PEOPLE, 42), w(G.BATTLE, 7), w(G.VOICES, 1) },
  easyChatBattleLost = { w(G.ENDINGS, 57), w(G.FEELINGS, 46), w(G.VOICES, 4), w(G.PEOPLE, 61), w(G.BATTLE, 48), w(G.VOICES, 4) },
}
Player.BATTLE_FIELDS = { "easyChatBattleStart", "easyChatBattleWon", "easyChatBattleLost" }

-- pokeemerald/src/easy_chat.c:700
Player.BERRY_MASTER_WIFE_PHRASES = {
  { w(G.FEELINGS, 64), w(G.BATTLE, 40) },
  { w(G.BATTLE, 31), w(G.EVENTS, 4) },
  { w(G.CONDITIONS, 34), w(G.POKEMON, 407) },
  { w(G.STATUS, 21), w(G.POKEMON, 408) },
  { w(G.EVENTS, 7), w(G.STATUS, 73) },
}

local function copy(list, n, fallback)
  local out = {}
  for i = 1, n do
    local v = list and tonumber(list[i])
    if v == nil and fallback then v = fallback[i] end
    out[i] = v or Town.EC_EMPTY_WORD
  end
  return out
end

-- pokeemerald/src/easy_chat.c:5562
function Player.init(sess)
  for _, f in ipairs(Player.BATTLE_FIELDS) do
    sess[f] = copy(Player.DEFAULT_BATTLE[f], Player.EASY_CHAT_BATTLE_WORDS_COUNT)
  end
end

function Player.battleWords(sess, field)
  sess = sess or Rse.session()
  if type(sess[field]) ~= "table" then
    sess[field] = copy(Player.DEFAULT_BATTLE[field], Player.EASY_CHAT_BATTLE_WORDS_COUNT)
  end
  return sess[field]
end

function Player.profile(sess)
  sess = sess or Rse.session()
  return copy(sess and sess.easyChatProfile, Player.PROFILE_WORDS, Player.DEFAULT_PROFILE)
end

-- pokeemerald/src/easy_chat.c:2993
function Player.berryMasterWifePhrase(words)
  for i, p in ipairs(Player.BERRY_MASTER_WIFE_PHRASES) do
    if tonumber(words[1]) == p[1] and tonumber(words[2]) == p[2] then return i end
  end
  return 0
end

local function full(words, n)
  for i = 1, n do
    local v = tonumber(words[i])
    if v == nil or v == Town.EC_EMPTY_WORD then return false end
  end
  return true
end

-- pokeemerald/src/easy_chat.c:1464
Types.register(Types.ID.PROFILE, {
  words = function(_, sess) return Player.profile(sess) end,
  -- pokeemerald/src/easy_chat.c:2969
  commit = function(_, sess, words)
    sess.easyChatProfile = copy(words, Player.PROFILE_WORDS)
    Rse.setFlag("FLAG_SYS_CHAT_USED", true, sess)
  end,
})

-- pokeemerald/src/easy_chat.c:1467
for id, field in pairs({ [Types.ID.BATTLE_START] = "easyChatBattleStart", [Types.ID.BATTLE_WON] = "easyChatBattleWon",
  [Types.ID.BATTLE_LOST] = "easyChatBattleLost" }) do
  Types.register(id, {
    words = function(_, sess) return copy(Player.battleWords(sess, field), Player.EASY_CHAT_BATTLE_WORDS_COUNT) end,
    commit = function(_, sess, words) sess[field] = copy(words, Player.EASY_CHAT_BATTLE_WORDS_COUNT) end,
  })
end

-- pokeemerald/src/easy_chat.c:1516
Types.register(Types.ID.GOOD_SAYING, {
  words = function() return copy(nil, Player.GOOD_SAYING_WORDS) end,
  -- pokeemerald/src/easy_chat.c:2143
  completed = function(_, out) return full(out, Player.GOOD_SAYING_WORDS) end,
  -- pokeemerald/src/easy_chat.c:2982
  commit = function(ctx, _, words)
    Rse.setSpecialVar(ctx, VAR_0x8004, Player.berryMasterWifePhrase(words))
  end,
})

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  -- pokeemerald/include/global.h:1050
  SaveSections.register("easyChat", {
    fields = Player.BATTLE_FIELDS,
    newGame = Player.init,
    export = function(sess, out)
      for _, f in ipairs(Player.BATTLE_FIELDS) do
        if type(sess[f]) == "table" then out[f] = copy(sess[f], Player.EASY_CHAT_BATTLE_WORDS_COUNT) end
      end
    end,
    restore = function(save, sess)
      for _, f in ipairs(Player.BATTLE_FIELDS) do
        sess[f] = copy(save[f], Player.EASY_CHAT_BATTLE_WORDS_COUNT, type(save[f]) ~= "table" and Player.DEFAULT_BATTLE[f] or nil)
      end
    end,
  })
end

return Player
