local Rse = require("src.core.game3.rse.init")

local Types = {}

-- pokeemerald/include/constants/easy_chat.h:4
Types.ID = {
  PROFILE = 0, BATTLE_START = 1, BATTLE_WON = 2, BATTLE_LOST = 3, MAIL = 4, INTERVIEW = 5, BARD_SONG = 6,
  FAN_CLUB = 7, DUMMY_SHOW = 8, TRENDY_PHRASE = 9, GABBY_AND_TY = 10, CONTEST_INTERVIEW = 11,
  BATTLE_TOWER_INTERVIEW = 12, GOOD_SAYING = 13, FAN_QUESTION = 14, QUIZ_ANSWER = 15, QUIZ_QUESTION = 16,
  QUIZ_SET_QUESTION = 17, QUIZ_SET_ANSWER = 18, APPRENTICE = 19, QUESTIONNAIRE = 20,
}

local handlers = {}

function Types.register(typeId, def)
  assert(type(def) == "table" and type(def.words) == "function", "easy chat type needs words()")
  handlers[typeId] = def
end

function Types.get(typeId)
  return handlers[tonumber(typeId) or -1]
end

local VAR_0x8004 = 0x8004
local VAR_RESULT = 0x800D

-- pokeemerald/src/easy_chat.c:2332
function Types.changed(before, after)
  for i = 1, math.max(#before, #after) do
    if (tonumber(before[i]) or 0xFFFF) ~= (tonumber(after[i]) or 0xFFFF) then return true end
  end
  return false
end

-- pokeemerald/src/easy_chat.c:1456
function Types.show(ctx, adapters, typeId)
  local def = Types.get(typeId)
  if not def then return nil end
  local Natives = require("src.core.game3.scripting.natives")
  local sess = Rse.session()
  local words = def.words(ctx, sess)
  if not words then return false end
  if not (adapters and adapters.openEasyChat) then
    Rse.missing("easyChat", "openEasyChat adapter", adapters and adapters.log)
    Rse.setSpecialVar(ctx, VAR_RESULT, 0)
    return false
  end
  return Natives.yieldHost(ctx, adapters, function(done)
    adapters.openEasyChat({ type = typeId, words = words, session = sess }, function(confirmed, out)
      -- pokeemerald/src/easy_chat.c:1995
      if confirmed and type(out) == "table" then
        local completed
        if def.completed then completed = def.completed(words, out) else completed = Types.changed(words, out) end
        if def.commit then def.commit(ctx, sess, out) end
        Rse.setSpecialVar(ctx, VAR_RESULT, completed and 1 or 0)
      else
        if def.cancel then def.cancel(ctx, sess) end
        Rse.setSpecialVar(ctx, VAR_RESULT, 0)
      end
      done()
    end)
  end)
end

function Types.handler(fallback)
  return function(ctx, adapters)
    local typeId = Rse.specialVar(ctx, VAR_0x8004)
    local yield = Types.show(ctx, adapters, typeId)
    if yield ~= nil then return yield end
    if fallback then return fallback(ctx, adapters) end
    return false
  end
end

return Types
