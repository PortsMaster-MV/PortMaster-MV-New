local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local Lady = require("src.core.game3.rse.lilycove_lady")
local Types = require("src.core.game3.rse.easy_chat_types")

local NativesLady = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_0x8005 = 0x8005
local VAR_RESULT = 0x800D
local VAR_ITEM_ID = 0x800E
-- pokeemerald/include/constants/script_menu.h:8
local MENU_B_PRESSED = 0x7F

local function result(ctx, v)
  v = (v == true and 1) or (v == false and 0) or tonumber(v) or 0
  Rse.setSpecialVar(ctx, VAR_RESULT, v)
  return false, v
end

local function text(key, ctx)
  return require("src.core.game3.rom_text").plain(key, ctx)
end

local function set(ctx, adapters, i, s)
  Town.setString(ctx, adapters, i, s)
end

-- pokeemerald/src/easy_chat.c:1525
Types.register(Types.ID.QUIZ_ANSWER, {
  words = function(_, sess) return { Lady.quiz(sess).playerAnswer } end,
  commit = function(_, sess, words) Lady.quiz(sess).playerAnswer = tonumber(words[1]) or Town.EC_EMPTY_WORD end,
})

local function questionFilled(q)
  for i = 1, Lady.QUIZ_QUESTION_LEN do
    if (q[i] or Town.EC_EMPTY_WORD) ~= Town.EC_EMPTY_WORD then return true end
  end
  return false
end

-- pokeemerald/src/easy_chat.c:1530
Types.register(Types.ID.QUIZ_SET_QUESTION, {
  words = function(_, sess) return Town.copyWords(Lady.quiz(sess).question, Lady.QUIZ_QUESTION_LEN) end,
  commit = function(_, sess, words)
    local q = Lady.quiz(sess)
    for i = 1, Lady.QUIZ_QUESTION_LEN do q.question[i] = tonumber(words[i]) or Town.EC_EMPTY_WORD end
  end,
  -- pokeemerald/src/easy_chat.c:2334
  completed = function(_, out)
    local q = Lady.quiz()
    return questionFilled(out) and q.correctAnswer ~= Town.EC_EMPTY_WORD
  end,
})

-- pokeemerald/src/easy_chat.c:1533
Types.register(Types.ID.QUIZ_SET_ANSWER, {
  words = function(_, sess) return { Lady.quiz(sess).correctAnswer } end,
  commit = function(_, sess, words) Lady.quiz(sess).correctAnswer = tonumber(words[1]) or Town.EC_EMPTY_WORD end,
  completed = function(_, out)
    return questionFilled(Lady.quiz().question) and (tonumber(out[1]) or Town.EC_EMPTY_WORD) ~= Town.EC_EMPTY_WORD
  end,
})

local function importance(itemId)
  local ItemsData = require("src.core.game3.items_data")
  local info = ItemsData.info(itemId)
  if not info then return true end
  if info.pocket == "KEY_ITEMS" then return true end
  return (tostring(info.name or "")):match("^HM%d") ~= nil
end

local function giftableItems(sess)
  local Bag = require("src.core.game3.bag")
  local ItemsData = require("src.core.game3.items_data")
  local C = require("src.core.game3.constants").of("emerald")
  local enigma = C:require("items", "ITEM_ENIGMA_BERRY")
  local out = {}
  for _, pocket in ipairs(ItemsData.BAG_POCKET_ORDER) do
    for _, e in ipairs(Bag.listPocket(sess and sess.bag, pocket) or {}) do
      local id = tonumber(e.id or e.item or e[1])
      if id and id ~= 0 and id ~= enigma and not importance(id) then out[#out + 1] = id end
    end
  end
  return out
end
NativesLady.giftableItems = giftableItems

-- pokeemerald/src/item_menu.c:602
local function chooseItem(ctx, adapters, location)
  local Natives = require("src.core.game3.scripting.natives")
  Rse.setSpecialVar(ctx, VAR_RESULT, 0)
  Rse.setSpecialVar(ctx, VAR_ITEM_ID, 0)
  local function picked(item)
    item = tonumber(item) or 0
    if item ~= 0 then
      Rse.setSpecialVar(ctx, VAR_ITEM_ID, item)
      Rse.setSpecialVar(ctx, VAR_RESULT, 1)
    end
  end
  -- pokeemerald/src/item_menu.c:2387
  local function back(done)
    local Fade = require("src.ui.game3.fade")
    Fade.begin(Fade.MODE.FROM_BLACK, 0, done)
  end
  local bag = Rse.system("bag")
  if bag and type(bag.chooseItem) == "function" then
    return Natives.yieldHost(ctx, adapters, function(done)
      bag.chooseItem(ctx, { location = location }, function(item)
        picked(item)
        back(done)
      end)
    end)
  end
  local items = giftableItems(Rse.session())
  local labels = {}
  for i, id in ipairs(items) do labels[i] = Town.itemName(id) end
  labels[#labels + 1] = text("gText_Cancel")
  local ListMenu = require("src.core.game3.scripting.natives_listmenu")
  return Natives.yieldHost(ctx, adapters, function(done)
    require("src.ui.game3.fade").clear()
    local shown = ListMenu.Menu.showItems("lady_items", labels,
      { count = #labels, maxShowed = 6, left = 16, top = 1, height = 12 }, 0, 0, function(index)
        if index ~= MENU_B_PRESSED and index < #items then picked(items[index + 1]) end
        back(done)
      end)
    if not shown then back(done) end
  end)
end

local function quizQuestionText(sess)
  local q = Lady.quiz(sess)
  return Town.words(q.question, 3, 3)
end
NativesLady.quizQuestionText = quizQuestionText

NativesLady.BY_NAME = {
  -- pokeemerald/src/lilycove_lady.c:44
  SetLilycoveLadyGfx = function(ctx)
    local gfx, mon = Lady.gfx()
    Rse.setVar("VAR_OBJ_GFX_ID_0", gfx)
    if mon then
      Rse.setVar("VAR_OBJ_GFX_ID_1", mon)
      return result(ctx, true)
    end
    return result(ctx, false)
  end,
  -- pokeemerald/src/lilycove_lady.c:115
  Script_GetLilycoveLadyId = function(ctx) return result(ctx, Lady.id()) end,
  -- pokeemerald/src/lilycove_lady.c:159
  GetFavorLadyState = function(ctx) return result(ctx, Lady.favorState()) end,
  -- pokeemerald/src/lilycove_lady.c:175
  BufferFavorLadyRequest = function(ctx, adapters)
    set(ctx, adapters, 1, text(Lady.favorRequest()))
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:181
  HasAnotherPlayerGivenFavorLadyItem = function(ctx, adapters)
    local f = Lady.favor()
    if f and (f.playerName or "") ~= "" then
      set(ctx, adapters, 3, f.playerName)
      return result(ctx, true)
    end
    return result(ctx, false)
  end,
  -- pokeemerald/src/lilycove_lady.c:198
  BufferFavorLadyItemName = function(ctx, adapters)
    set(ctx, adapters, 2, Town.itemName(Lady.favor().itemId))
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:210
  BufferFavorLadyPlayerName = function(ctx, adapters)
    set(ctx, adapters, 3, Lady.favor().playerName or "")
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:218
  DidFavorLadyLikeItem = function(ctx) return result(ctx, Lady.favor().likedItem == true) end,
  -- pokeemerald/src/lilycove_lady.c:224
  Script_FavorLadyOpenBagMenu = function(ctx, adapters) return chooseItem(ctx, adapters, "favorLady") end,
  -- pokeemerald/src/lilycove_lady.c:259
  Script_DoesFavorLadyLikeItem = function(ctx, adapters)
    local item = Rse.specialVar(ctx, VAR_ITEM_ID)
    set(ctx, adapters, 2, Town.itemName(item))
    return result(ctx, Lady.doesFavorLadyLikeItem(item))
  end,
  -- pokeemerald/src/lilycove_lady.c:264
  IsFavorLadyThresholdMet = function(ctx) return result(ctx, Lady.favorThresholdMet()) end,
  -- pokeemerald/src/lilycove_lady.c:278
  FavorLadyGetPrize = function(ctx, adapters)
    local prize = Lady.favorPrize()
    set(ctx, adapters, 2, Town.itemName(prize))
    return false, prize
  end,
  -- pokeemerald/src/lilycove_lady.c:289
  SetFavorLadyState_Complete = function()
    Lady.setFavorComplete()
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:347
  GetQuizLadyState = function(ctx) return result(ctx, Lady.quizState()) end,
  -- pokeemerald/src/lilycove_lady.c:358
  GetQuizAuthor = function(ctx, adapters)
    local author, name = Lady.quizAuthor()
    set(ctx, adapters, 1, name)
    return result(ctx, author)
  end,
  -- pokeemerald/src/lilycove_lady.c:452
  BufferQuizPrizeName = function(ctx, adapters)
    set(ctx, adapters, 1, Town.itemName(Lady.quiz().prize))
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:457
  BufferQuizAuthorNameAndCheckIfLady = function(ctx, adapters)
    local id, name = Lady.quizAuthorName()
    set(ctx, adapters, 1, name)
    if id == Lady.QUIZ_AUTHOR_NAME_LADY then
      Lady.quiz().language = Town.GAME_LANGUAGE
      return result(ctx, true)
    end
    return result(ctx, false)
  end,
  -- pokeemerald/src/lilycove_lady.c:468
  IsQuizLadyWaitingForChallenger = function(ctx) return result(ctx, Lady.quiz().waitingForChallenger == true) end,
  -- pokeemerald/src/easy_chat.c:1573
  QuizLadyShowQuizQuestion = function(ctx, adapters)
    Lady.quiz().playerAnswer = Town.EC_EMPTY_WORD
    local Natives = require("src.core.game3.scripting.natives")
    local body = quizQuestionText()
    return Natives.yieldHost(ctx, adapters, function(done)
      local function answer()
        Rse.setSpecialVar(ctx, VAR_0x8004, Types.ID.QUIZ_ANSWER)
        local def = Types.get(Types.ID.QUIZ_ANSWER)
        local sess = Rse.session()
        adapters.openEasyChat({ type = Types.ID.QUIZ_ANSWER, words = def.words(ctx, sess), session = sess },
          function(confirmed, out)
            if confirmed and type(out) == "table" then
              local changed = Types.changed(def.words(ctx, sess), out)
              def.commit(ctx, sess, out)
              Rse.setSpecialVar(ctx, VAR_RESULT, changed and 1 or 0)
            else
              Rse.setSpecialVar(ctx, VAR_RESULT, 0)
            end
            done()
          end)
      end
      if adapters and adapters.openEasyChat then
        require("src.ui.game3.message").show(body, { hold = true, done = answer })
      else
        Rse.setSpecialVar(ctx, VAR_RESULT, 0)
        done()
      end
    end)
  end,
  -- pokeemerald/src/lilycove_lady.c:474
  QuizLadyGetPlayerAnswer = function(ctx, adapters)
    return Types.show(ctx, adapters, Types.ID.QUIZ_ANSWER) or false
  end,
  -- pokeemerald/src/lilycove_lady.c:479
  IsQuizAnswerCorrect = function(ctx, adapters)
    local q = Lady.quiz()
    set(ctx, adapters, 1, Town.word(q.correctAnswer))
    set(ctx, adapters, 2, Town.word(q.playerAnswer))
    return result(ctx, Lady.isAnswerCorrect())
  end,
  -- pokeemerald/src/lilycove_lady.c:487
  BufferQuizPrizeItem = function(ctx)
    Rse.setSpecialVar(ctx, VAR_0x8005, Lady.quiz().prize)
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:493
  SetQuizLadyState_Complete = function()
    Lady.quiz().state = Lady.STATE_COMPLETED
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:499
  SetQuizLadyState_GivePrize = function()
    Lady.quiz().state = Lady.STATE_PRIZE
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:505
  ClearQuizLadyPlayerAnswer = function()
    Lady.quiz().playerAnswer = Town.EC_EMPTY_WORD
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:511
  Script_QuizLadyOpenBagMenu = function(ctx, adapters) return chooseItem(ctx, adapters, "quizLady") end,
  -- pokeemerald/src/lilycove_lady.c:516
  QuizLadyPickNewQuestion = function()
    Lady.pickNewQuestion()
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:526
  ClearQuizLadyQuestionAndAnswer = function()
    local q = Lady.quiz()
    for i = 1, Lady.QUIZ_QUESTION_LEN do q.question[i] = Town.EC_EMPTY_WORD end
    q.correctAnswer = Town.EC_EMPTY_WORD
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:536
  QuizLadySetCustomQuestion = function(ctx, adapters)
    Rse.setSpecialVar(ctx, VAR_0x8004, Types.ID.QUIZ_SET_QUESTION)
    local Natives = require("src.core.game3.scripting.natives")
    if not (adapters and adapters.openEasyChat) then
      Rse.missing("easyChat", "openEasyChat adapter", adapters and adapters.log)
      return result(ctx, false)
    end
    local sess = Rse.session()
    return Natives.yieldHost(ctx, adapters, function(done)
      local qDef, aDef = Types.get(Types.ID.QUIZ_SET_QUESTION), Types.get(Types.ID.QUIZ_SET_ANSWER)
      adapters.openEasyChat({ type = Types.ID.QUIZ_SET_QUESTION, words = qDef.words(ctx, sess), session = sess },
        function(okQ, question)
          if okQ and type(question) == "table" then qDef.commit(ctx, sess, question) end
          adapters.openEasyChat({ type = Types.ID.QUIZ_SET_ANSWER, words = aDef.words(ctx, sess), session = sess },
            function(okA, answer)
              if okA and type(answer) == "table" then aDef.commit(ctx, sess, answer) end
              local q = Lady.quiz(sess)
              local complete = (okQ or okA) and questionFilled(q.question) and q.correctAnswer ~= Town.EC_EMPTY_WORD
              Rse.setSpecialVar(ctx, VAR_RESULT, complete and 1 or 0)
              done()
            end)
        end)
    end)
  end,
  -- pokeemerald/src/lilycove_lady.c:542
  QuizLadyTakePrizeForCustomQuiz = function(ctx)
    local Bag = require("src.core.game3.bag")
    local sess = Rse.session()
    Bag.remove(sess and sess.bag, Rse.specialVar(ctx, VAR_ITEM_ID), 1)
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:547
  QuizLadyRecordCustomQuizData = function(ctx)
    Lady.recordCustomQuiz(Rse.specialVar(ctx, VAR_ITEM_ID))
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:559
  QuizLadySetWaitingForChallenger = function()
    Lady.quiz().waitingForChallenger = true
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:565
  BufferQuizCorrectAnswer = function(ctx, adapters)
    set(ctx, adapters, 3, Town.word(Lady.quiz().correctAnswer))
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:739
  HasPlayerGivenContestLadyPokeblock = function(ctx) return result(ctx, Lady.contest().givenPokeblock == true) end,
  -- pokeemerald/src/lilycove_lady.c:747
  ShouldContestLadyShowGoOnAir = function(ctx) return result(ctx, Lady.shouldShowGoOnAir()) end,
  -- pokeemerald/src/lilycove_lady.c:759
  Script_BufferContestLadyCategoryAndMonName = function(ctx, adapters)
    local cat = Lady.contest().category
    set(ctx, adapters, 2, text(string.format("sContestLadyCategoryNames[%d]", cat)))
    set(ctx, adapters, 1, text(string.format("sContestLadyMonNames[%d]", cat)))
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:764
  OpenPokeblockCaseForContestLady = function(ctx, adapters)
    Rse.setSpecialVar(ctx, VAR_RESULT, 0xFFFF)
    local okP, Pokeblock = pcall(require, "src.core.game3.rse.pokeblock")
    if not (okP and type(Pokeblock) == "table" and Pokeblock.openCase) then
      Rse.missing("pokeblock", "OpenPokeblockCaseForContestLady", adapters and adapters.log)
      return false
    end
    local Natives = require("src.core.game3.scripting.natives")
    local sess = Rse.session()
    return Natives.yieldHost(ctx, adapters, function(done)
      Pokeblock.openCase(sess, {
        caseId = Pokeblock.CASE.GIVE,
        -- pokeemerald/src/pokeblock.c:1284
        onUse = function(id)
          Rse.setSpecialVar(ctx, VAR_0x8004, Lady.givePokeblock(Pokeblock.get(sess, id), sess) and 1 or 0)
          Rse.setSpecialVar(ctx, VAR_RESULT, id)
          Pokeblock.tryClear(sess, id)
          Rse.setSpecialVar(ctx, VAR_ITEM_ID, 0)
          return id
        end,
        onClose = function(result)
          if result == nil then Rse.setSpecialVar(ctx, VAR_RESULT, 0xFFFF) end
          -- pokeemerald/src/pokeblock.c:985
          local Fade = require("src.ui.game3.fade")
          Fade.begin(Fade.MODE.FROM_BLACK, 0, done)
        end,
      })
    end)
  end,
  -- pokeemerald/src/lilycove_lady.c:769
  SetContestLadyGivenPokeblock = function()
    Lady.contest().givenPokeblock = true
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:775
  GetContestLadyMonSpecies = function(ctx)
    local d = Town.data().lady
    Rse.setSpecialVar(ctx, VAR_0x8005, d.contestMonSpecies[Lady.contest().category + 1])
    return false
  end,
  -- pokeemerald/src/lilycove_lady.c:781
  GetContestLadyCategory = function(ctx) return result(ctx, Lady.contest().category) end,
}

Std.legacyHandlers(NativesLady)

return NativesLady
