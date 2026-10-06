local Rse = require("src.core.game3.rse.init")
local Apprentice = require("src.core.game3.rse.frontier.apprentice")

local NativesApprentice = {}

local function natives() return require("src.core.game3.scripting.natives") end
local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end
local function setResult(ctx, v) Rse.setSpecialVar(ctx, Apprentice.VAR_RESULT, v) end

-- pokeemerald/src/apprentice.c:564
function NativesApprentice.menu(ctx, adapters, s)
  local which = specialVar(ctx, Apprentice.VAR_0x8005)
  local labels, left, top = Apprentice.menuOptions(s, which)
  if not labels then return end
  local FrlgFont = require("src.ui.game3.frlg_font")
  local widest = 0
  for _, l in ipairs(labels) do
    local w = FrlgFont.measure(l)
    if w > widest then widest = w end
  end
  -- pokeemerald/src/script_menu.c:743
  local width = math.floor((widest + 9) / 8) + 1
  if left + width > 28 then left = 28 - width end
  local done = false
  natives().awaitState(ctx, function() return done end)
  require("src.ui.game3.choice").multi(labels, 0, function(pick)
    if pick == nil or pick == Apprentice.MULTI_B_PRESSED then pick = Apprentice.MULTI_B_PRESSED end
    setResult(ctx, tonumber(pick) or 0)
    done = true
  end, { left = left, top = top, ignoreBPress = true })
end

-- pokeemerald/src/apprentice.c:827
function NativesApprentice.printMessage(ctx, adapters, s)
  local waitButton = specialVar(ctx, Apprentice.VAR_0x8005) ~= 0
  local ir = Apprentice.message(s, specialVar(ctx, Apprentice.VAR_0x8006))
  if not ir then return end
  local Util = require("src.core.game3.rse.frontier.util")
  local body = Util.textBox(ir, ctx)
  local done = false
  natives().awaitState(ctx, function() return done end)
  if waitButton and adapters and adapters.openMessageAsync then
    if ctx then ctx.messageOpen = false end
    adapters.openMessageAsync(body, function() done = true end)
  else
    Util.showFieldMessage(ctx, adapters, ir)
    done = true
  end
end

-- pokeemerald/src/item_menu.c:595
function NativesApprentice.openBag(ctx, adapters, s)
  local ItemsData = require("src.core.game3.items_data")
  local items = Apprentice.holdableItems(s)
  local done = false
  natives().awaitState(ctx, function() return done end)
  local bagSys = Rse.system("bag")
  if bagSys and type(bagSys.chooseHoldItem) == "function" then
    bagSys.chooseHoldItem(ctx, function(item)
      if item and item ~= 0 then
        Rse.setSpecialVar(ctx, Apprentice.VAR_0x8005, item)
        setResult(ctx, 1)
      else
        setResult(ctx, 0)
      end
      done = true
    end)
    return
  end
  local labels = {}
  local shown = {}
  for i = 1, math.min(#items, 7) do
    labels[i] = ItemsData.displayName(items[i])
    shown[i] = items[i]
  end
  labels[#labels + 1] = require("src.core.game3.rom_text").plain("gText_Cancel2")
  require("src.ui.game3.choice").multi(labels, 0, function(pick)
    local item = pick ~= nil and shown[(tonumber(pick) or -1) + 1] or nil
    if item then
      Rse.setSpecialVar(ctx, Apprentice.VAR_0x8005, item)
      setResult(ctx, 1)
    else
      setResult(ctx, 0)
    end
    done = true
  end, { left = 15, top = 1 })
end

local FUNCS = {}
local Fn = Apprentice.FUNC
FUNCS[Fn.GAVE_LVLMODE] = function(ctx, _, s) setResult(ctx, (Apprentice.player(s).lvlMode or 0) ~= 0 and 1 or 0) end
FUNCS[Fn.SET_LVLMODE] = function(ctx, _, s) Apprentice.player(s).lvlMode = specialVar(ctx, Apprentice.VAR_0x8005) end
FUNCS[Fn.SET_ID] = function(_, _, s) Apprentice.setId(s) end
FUNCS[Fn.SHUFFLE_SPECIES] = function(_, _, s) Apprentice.shuffleSpecies(s) end
FUNCS[Fn.RANDOMIZE_QUESTIONS] = function(_, _, s) Apprentice.setRandomQuestionData(s) end
FUNCS[Fn.ANSWERED_QUESTION] = function(_, _, s)
  local p = Apprentice.player(s)
  p.questionsAnswered = p.questionsAnswered + 1
end
-- pokeemerald/src/apprentice.c:789
FUNCS[Fn.IS_FINAL_QUESTION] = function(ctx, _, s)
  local p = Apprentice.player(s)
  local q = p.questionsAnswered - Apprentice.NUM_WHICH_MON
  if q < 0 then setResult(ctx, 0) return end
  local row = p.questions[q + 1]
  setResult(ctx, (q > Apprentice.MAX_QUESTIONS - 1 or (row and row.questionId == Apprentice.QID.WIN_SPEECH)) and 1 or 0)
end
FUNCS[Fn.MENU] = NativesApprentice.menu
FUNCS[Fn.PRINT_MSG] = NativesApprentice.printMessage
FUNCS[Fn.RESET] = function(_, _, s) Apprentice.resetPlayer(s) end
-- pokeemerald/src/apprentice.c:1252
FUNCS[Fn.CHECK_GONE] = function(ctx) Rse.setSpecialVar(ctx, Apprentice.VAR_0x8004, 1) end
FUNCS[Fn.GET_QUESTION] = function(ctx, _, s) Apprentice.getQuestion(ctx, s) end
FUNCS[Fn.GET_NUM_PARTY_MONS] = function(ctx, _, s) setResult(ctx, Apprentice.player(s).questionsAnswered) end
-- pokeemerald/src/apprentice.c:954
FUNCS[Fn.SET_PARTY_MON] = function(ctx, _, s)
  if specialVar(ctx, Apprentice.VAR_0x8005) ~= 0 then
    local p = Apprentice.player(s)
    p.party = require("bit").bor(p.party, require("bit").lshift(1, specialVar(ctx, Apprentice.VAR_0x8006)))
  end
end
FUNCS[Fn.INIT_QUESTION_DATA] = function(ctx, _, s) Apprentice.initQuestionData(ctx, s) end
FUNCS[Fn.FREE_QUESTION_DATA] = function() Apprentice.questionData = nil end
FUNCS[Fn.BUFFER_STRING] = function(ctx, adapters, s) Apprentice.bufferString(ctx, adapters, s) end
-- pokeemerald/src/apprentice.c:965
FUNCS[Fn.SET_MOVE] = function(ctx, _, s)
  local p = Apprentice.player(s)
  if p.questionsAnswered >= Apprentice.NUM_WHICH_MON then
    local q = p.questions[p.questionsAnswered - Apprentice.NUM_WHICH_MON + 1]
    if q then q.suggestedChange = specialVar(ctx, Apprentice.VAR_0x8005) ~= 0 and 1 or 0 end
  end
end
FUNCS[Fn.SET_LEAD_MON] = function(ctx, _, s) Apprentice.player(s).leadMonId = specialVar(ctx, Apprentice.VAR_0x8005) end
FUNCS[Fn.OPEN_BAG] = NativesApprentice.openBag
FUNCS[Fn.TRY_SET_HELD_ITEM] = function(ctx, _, s) Apprentice.trySetHeldItem(ctx, s) end
FUNCS[Fn.SAVE] = function(_, _, s) Apprentice.save(s) end
FUNCS[Fn.SET_GFX_SAVED] = function(_, _, s) Apprentice.setSavedGfx(s) end
FUNCS[Fn.SET_GFX] = function(_, _, s) Apprentice.setGfx(s) end
-- pokeemerald/src/apprentice.c:1257
FUNCS[Fn.SHOULD_LEAVE] = function(ctx) Rse.setSpecialVar(ctx, Apprentice.VAR_0x8004, 1) end
FUNCS[Fn.SHIFT_SAVED] = function(_, _, s) Apprentice.shiftSaved(s) end

NativesApprentice.FUNCS = FUNCS

NativesApprentice.BY_NAME = {
  -- pokeemerald/src/apprentice.c:722
  CallApprenticeFunction = function(ctx, adapters)
    local s = Rse.session()
    local id = specialVar(ctx, Apprentice.VAR_0x8004)
    local fn = FUNCS[id]
    if not (s and fn) then
      Rse.missing("apprentice", "CallApprenticeFunction " .. tostring(id), adapters and adapters.log)
      return false
    end
    return fn(ctx, adapters, s) == true
  end,
}

return NativesApprentice
