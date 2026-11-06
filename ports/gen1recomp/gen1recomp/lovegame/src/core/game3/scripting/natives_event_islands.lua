local Rse = require("src.core.game3.rse.init")
local EventIslands = require("src.core.game3.rse.event_islands")

local NativesEventIslands = {}

local function natives() return require("src.core.game3.scripting.natives") end

local Types = require("src.core.game3.rse.easy_chat_types")

-- pokeemerald/src/easy_chat.c:1539
Types.register(Types.ID.QUESTIONNAIRE, {
  words = function(_, sess)
    local MysteryGift = require("src.core.game3.mystery_gift")
    local w = MysteryGift.questionnaireWords(sess)
    return { w[1], w[2], w[3], w[4] }
  end,
  -- pokeemerald/src/easy_chat.c:2972
  commit = function(ctx, sess, words)
    local MysteryGift = require("src.core.game3.mystery_gift")
    local w = MysteryGift.questionnaireWords(sess)
    for i = 1, 4 do w[i] = tonumber(words[i]) or 0xFFFF end
    Rse.setSpecialVar(ctx, 0x8004, MysteryGift.isMysteryGiftPhrase(w) and 2 or 0)
  end,
})

NativesEventIslands.BY_NAME = {
  -- pokeemerald/src/field_specials.c:3264
  DoDeoxysRockInteraction = function(ctx)
    local s = Rse.session()
    if not s then return false end
    local result, anim = EventIslands.rockInteraction(s)
    Rse.setSpecialVar(ctx, EventIslands.VAR_RESULT, result)
    NativesEventIslands.lastResult = result
    if anim then
      -- pokeemerald/src/field_specials.c:3368
      natives().awaitState(ctx, function()
        local FieldEffects = package.loaded["src.core.game3.field_effects"]
        for _, a in ipairs(FieldEffects and FieldEffects._anims or {}) do
          if a == anim then return false end
        end
        return true
      end)
    end
    return false
  end,
  -- pokeemerald/src/pokemon.c:2773
  CreateEnemyEventMon = function(ctx)
    local Enc = require("src.core.game3.encounters")
    local item = Rse.specialVar(ctx, 0x8006)
    Enc.setWildBattle(Rse.specialVar(ctx, 0x8004), Rse.specialVar(ctx, 0x8005), item ~= 0 and item or nil)
    -- pokeemerald/src/pokemon.c:2635
    if Enc._pendingWild then Enc._pendingWild.fatefulEncounter = true end
    return false
  end,
  -- pokeemerald/src/field_specials.c:3389
  SetDeoxysRockPalette = function()
    EventIslands.setRockPalette(Rse.session())
    return false
  end,
}

return NativesEventIslands
