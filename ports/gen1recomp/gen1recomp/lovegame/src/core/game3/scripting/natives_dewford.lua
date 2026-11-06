local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local Dewford = require("src.core.game3.rse.dewford_trend")
local Types = require("src.core.game3.rse.easy_chat_types")
require("src.core.game3.rse.easy_chat_player")
require("src.core.game3.rse.daily_events")

local NativesDewford = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_RESULT = 0x800D

-- pokeemerald/src/easy_chat.c:1498
Types.register(Types.ID.TRENDY_PHRASE, {
  words = function(_, sess)
    local t = Dewford.trends(sess)[1]
    return { t.words[1], t.words[2] }
  end,
  -- pokeemerald/src/easy_chat.c:2980
  commit = function(ctx, sess, words)
    local phrase = { tonumber(words[1]) or Town.EC_EMPTY_WORD, tonumber(words[2]) or Town.EC_EMPTY_WORD }
    if ctx and ctx.stringVars then ctx.stringVars[2] = Town.words(phrase, 2, 1) end
    Rse.setSpecialVar(ctx, VAR_0x8004, Dewford.trySetTrendyPhrase(phrase, sess) and 1 or 0)
  end,
})

NativesDewford.BY_NAME = {
  -- pokeemerald/src/dewford_trend.c:290
  BufferTrendyPhraseString = function(ctx, adapters)
    Town.setString(ctx, adapters, 1, Dewford.phraseString(Rse.specialVar(ctx, VAR_0x8004)))
    return false
  end,
  -- pokeemerald/src/dewford_trend.c:298
  IsTrendyPhraseBoring = function(ctx)
    local v = Dewford.isBoring() and 1 or 0
    Rse.setSpecialVar(ctx, VAR_RESULT, v)
    return false, v
  end,
  -- pokeemerald/src/dewford_trend.c:320
  GetDewfordHallPaintingNameIndex = function(ctx)
    local v = Dewford.paintingNameIndex()
    Rse.setSpecialVar(ctx, VAR_RESULT, v)
    return false, v
  end,
  -- pokeemerald/src/easy_chat.c:5421
  BufferDeepLinkPhrase = function(ctx, adapters)
    local G = Town.EC_GROUP
    local group = require("bit").band(Town.random(), 1) == 1 and G.HOBBIES or G.LIFESTYLE
    Town.setString(ctx, adapters, 2, Town.word(Town.randomWordFromUnlockedGroup(group)))
    return false
  end,
  ShowEasyChatScreen = Types.handler(function(ctx, adapters)
    Rse.missing("easyChat", "ShowEasyChatScreen type " .. tostring(Rse.specialVar(ctx, VAR_0x8004)), adapters and adapters.log)
    Rse.setSpecialVar(ctx, VAR_RESULT, 0)
    return false
  end),
}

Std.legacyHandlers(NativesDewford)

return NativesDewford
