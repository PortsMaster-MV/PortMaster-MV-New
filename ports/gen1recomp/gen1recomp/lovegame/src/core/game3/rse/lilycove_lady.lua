local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")

local Lady = {}

-- pokeemerald/include/constants/lilycove_lady.h:4
Lady.QUIZ, Lady.FAVOR, Lady.CONTEST = 0, 1, 2
Lady.STATE_READY, Lady.STATE_COMPLETED, Lady.STATE_PRIZE = 0, 1, 2
Lady.GIFT_THRESHOLD = 5
Lady.QUIZ_AUTHOR_PLAYER, Lady.QUIZ_AUTHOR_OTHER_PLAYER, Lady.QUIZ_AUTHOR_LADY = 0, 1, 2
Lady.QUIZ_AUTHOR_NAME_LADY, Lady.QUIZ_AUTHOR_NAME_PLAYER, Lady.QUIZ_AUTHOR_NAME_OTHER_PLAYER = 0, 1, 2
Lady.CONTEST_LADY_NORMAL, Lady.CONTEST_LADY_GOOD, Lady.CONTEST_LADY_BAD = 0, 1, 2
-- pokeemerald/include/global.h:797
Lady.QUIZ_QUESTION_LEN = 9
-- pokeemerald/include/constants/global.h:91
Lady.CONTEST_CATEGORIES_COUNT = 5

local function data()
  return Town.data().lady
end

function Lady.state(sess)
  sess = Town.session(sess)
  if not sess then return nil end
  if type(sess.lilycoveLady) ~= "table" or sess.lilycoveLady.id == nil then Lady.init(sess) end
  return sess.lilycoveLady
end

function Lady.id(sess)
  return Lady.state(sess).id
end

local function playerTrainerId(sess)
  return Town.trainerId16(sess)
end

-- pokeemerald/src/lilycove_lady.c:128
local function favorPick(f)
  local d = data()
  f.favorId = Town.random() % #d.favorRequests
  local items = d.favorAccepted[f.favorId + 1]
  f.bestItem = items[(Town.random() % #items) + 1]
end

-- pokeemerald/src/lilycove_lady.c:139
local function initFavor()
  local f = { id = Lady.FAVOR, state = Lady.STATE_READY, playerName = "", likedItem = false, numItemsGiven = 0,
    itemId = 0, language = Town.GAME_LANGUAGE }
  favorPick(f)
  return { id = Lady.FAVOR, favor = f }
end

-- pokeemerald/src/lilycove_lady.c:300
local function quizPick(q)
  local d = data()
  local qid = Town.random() % #d.quizQuestions
  q.question = Town.copyWords(d.quizQuestions[qid + 1], Lady.QUIZ_QUESTION_LEN)
  q.correctAnswer = d.quizAnswers[qid + 1]
  q.prize = d.quizPrizes[qid + 1]
  q.questionId = qid
  q.playerName = ""
end

-- pokeemerald/src/lilycove_lady.c:314
local function initQuiz()
  local q = { id = Lady.QUIZ, state = Lady.STATE_READY, question = Town.copyWords(nil, Lady.QUIZ_QUESTION_LEN),
    correctAnswer = Town.EC_EMPTY_WORD, playerAnswer = Town.EC_EMPTY_WORD, playerTrainerId = 0, prize = 0,
    waitingForChallenger = false, prevQuestionId = #data().quizQuestions, language = Town.GAME_LANGUAGE }
  quizPick(q)
  return { id = Lady.QUIZ, quiz = q }
end

-- pokeemerald/src/lilycove_lady.c:598
local function resetContestData(c)
  c.playerName = ""
  c.numGoodPokeblocksGiven = 0
  c.numOtherPokeblocksGiven = 0
  c.maxSheen = 0
  c.category = Town.random() % Lady.CONTEST_CATEGORIES_COUNT
end

-- pokeemerald/src/lilycove_lady.c:607
local function initContest()
  local c = { id = Lady.CONTEST, givenPokeblock = false, language = Town.GAME_LANGUAGE }
  resetContestData(c)
  return { id = Lady.CONTEST, contest = c }
end

-- pokeemerald/src/lilycove_lady.c:61
function Lady.init(sess)
  sess = Town.session(sess)
  local id = math.floor((playerTrainerId(sess) % 6) / 2)
  local lady
  if id == Lady.QUIZ then lady = initQuiz()
  elseif id == Lady.FAVOR then lady = initFavor()
  else lady = initContest() end
  if sess then sess.lilycoveLady = lady end
  return lady
end

-- pokeemerald/src/lilycove_lady.c:80
function Lady.resetForRecordMix(sess)
  local l = Lady.state(sess)
  if l.id == Lady.QUIZ then
    local q = l.quiz
    q.state, q.waitingForChallenger, q.playerAnswer = Lady.STATE_READY, false, Town.EC_EMPTY_WORD
  elseif l.id == Lady.FAVOR then
    l.favor.state = Lady.STATE_READY
  else
    local c = l.contest
    c.givenPokeblock = false
    if c.numGoodPokeblocksGiven == Lady.GIFT_THRESHOLD or c.numOtherPokeblocksGiven == Lady.GIFT_THRESHOLD then
      resetContestData(c)
    end
  end
end

-- pokeemerald/src/lilycove_lady.c:44
function Lady.gfx(sess)
  local l = Lady.state(sess)
  local d = data()
  local mon = nil
  if l.id == Lady.CONTEST then mon = d.contestMonGfx[l.contest.category + 1] end
  return d.gfx[l.id + 1], mon
end

local function favor(sess)
  local l = Lady.state(sess)
  return l.id == Lady.FAVOR and l.favor or nil
end
Lady.favor = favor

-- pokeemerald/src/lilycove_lady.c:159
function Lady.favorState(sess)
  local f = favor(sess)
  if not f then return Lady.STATE_READY end
  if f.state == Lady.STATE_PRIZE or f.state == Lady.STATE_COMPLETED then return f.state end
  return Lady.STATE_READY
end

function Lady.favorRequest(sess)
  local f = favor(sess)
  return data().favorRequests[(f and f.favorId or 0) + 1]
end

-- pokeemerald/src/lilycove_lady.c:229
function Lady.doesFavorLadyLikeItem(itemId, sess)
  local f = favor(sess)
  local items = data().favorAccepted[f.favorId + 1]
  f.state = Lady.STATE_COMPLETED
  f.itemId = itemId
  f.playerName = Town.playerName(sess)
  f.language = Town.GAME_LANGUAGE
  local liked = false
  for _, it in ipairs(items) do
    if it == itemId then
      liked = true
      f.numItemsGiven = f.numItemsGiven + 1
      f.likedItem = true
      if f.bestItem == itemId then f.numItemsGiven = Lady.GIFT_THRESHOLD end
      break
    end
    f.likedItem = false
  end
  return liked
end

-- pokeemerald/src/lilycove_lady.c:264
function Lady.favorThresholdMet(sess)
  return (favor(sess).numItemsGiven or 0) >= Lady.GIFT_THRESHOLD
end

-- pokeemerald/src/lilycove_lady.c:278
function Lady.favorPrize(sess)
  local f = favor(sess)
  f.state = Lady.STATE_PRIZE
  return data().favorPrizes[f.favorId + 1]
end

-- pokeemerald/src/lilycove_lady.c:289
function Lady.setFavorComplete(sess)
  sess = Town.session(sess)
  sess.lilycoveLady = initFavor()
  sess.lilycoveLady.favor.state = Lady.STATE_COMPLETED
end

local function quiz(sess)
  local l = Lady.state(sess)
  return l.id == Lady.QUIZ and l.quiz or nil
end
Lady.quiz = quiz

-- pokeemerald/src/lilycove_lady.c:347
function Lady.quizState(sess)
  local q = quiz(sess)
  if not q then return Lady.STATE_READY end
  if q.state == Lady.STATE_PRIZE or q.state == Lady.STATE_COMPLETED then return q.state end
  return Lady.STATE_READY
end

-- pokeemerald/src/easy_chat.c:5865
local function isAnswerUnlocked(word, sess)
  sess = Town.session(sess)
  local groupId = math.floor(word / 512) % 128
  local index = word % 512
  if not Town.groupUnlocked(groupId, sess) then return false end
  -- pokeemerald/src/easy_chat.c:5806
  if groupId == Town.EC_GROUP.POKEMON then
    local Dex = require("src.core.game3.dex")
    return sess and sess.dex and Dex.isSeen(sess.dex, index) or false
  end
  if groupId == Town.EC_GROUP.TRENDY_SAYING then
    return require("src.core.game3.rse.old_man").isTrendySayingUnlocked(index, sess)
  end
  return true
end
Lady.isAnswerUnlocked = isAnswerUnlocked

-- pokeemerald/src/lilycove_lady.c:389
function Lady.quizAuthorName(sess)
  sess = Town.session(sess)
  local q = quiz(sess)
  if (q.playerName or "") == "" then
    return Lady.QUIZ_AUTHOR_NAME_LADY, require("src.core.game3.rom_text").plain("gText_QuizLady_Lady")
  end
  local id = Lady.QUIZ_AUTHOR_NAME_PLAYER
  local mine = Town.playerName(sess)
  if #q.playerName == #mine and q.playerName ~= mine then id = Lady.QUIZ_AUTHOR_NAME_OTHER_PLAYER end
  return id, q.playerName
end

-- pokeemerald/src/lilycove_lady.c:358
function Lady.quizAuthor(sess)
  sess = Town.session(sess)
  local q = quiz(sess)
  local d = data()
  if not isAnswerUnlocked(q.correctAnswer, sess) then
    local i = q.questionId
    local n = #d.quizQuestions
    for _ = 1, n do
      i = i + 1
      if i >= n then i = 0 end
      if isAnswerUnlocked(d.quizAnswers[i + 1], sess) then break end
    end
    q.question = Town.copyWords(d.quizQuestions[i + 1], Lady.QUIZ_QUESTION_LEN)
    q.correctAnswer = d.quizAnswers[i + 1]
    q.prize = d.quizPrizes[i + 1]
    q.questionId = i
    q.playerName = ""
  end
  local nameId, name = Lady.quizAuthorName(sess)
  if nameId == Lady.QUIZ_AUTHOR_NAME_LADY then return Lady.QUIZ_AUTHOR_LADY, name end
  if nameId == Lady.QUIZ_AUTHOR_NAME_OTHER_PLAYER or (q.playerTrainerId or 0) ~= playerTrainerId(sess) then
    return Lady.QUIZ_AUTHOR_OTHER_PLAYER, name
  end
  return Lady.QUIZ_AUTHOR_PLAYER, name
end

-- pokeemerald/src/lilycove_lady.c:479
function Lady.isAnswerCorrect(sess)
  local q = quiz(sess)
  return Town.word(q.correctAnswer) == Town.word(q.playerAnswer)
end

-- pokeemerald/src/lilycove_lady.c:516
function Lady.pickNewQuestion(sess)
  local q = quiz(sess)
  local nameId = Lady.quizAuthorName(sess)
  if nameId == Lady.QUIZ_AUTHOR_NAME_LADY then
    q.language = Town.GAME_LANGUAGE
    q.prevQuestionId = q.questionId
  else
    q.prevQuestionId = #data().quizQuestions
  end
  quizPick(q)
end

-- pokeemerald/src/lilycove_lady.c:547
function Lady.recordCustomQuiz(prize, sess)
  sess = Town.session(sess)
  local q = quiz(sess)
  q.prize = prize
  q.playerTrainerId = playerTrainerId(sess)
  q.playerName = Town.playerName(sess)
  q.language = Town.GAME_LANGUAGE
end

local function contest(sess)
  local l = Lady.state(sess)
  return l.id == Lady.CONTEST and l.contest or nil
end
Lady.contest = contest

-- pokeemerald/src/lilycove_lady.c:639
function Lady.givePokeblock(pokeblock, sess)
  local c = contest(sess)
  local key = ({ [0] = "spicy", "dry", "sweet", "bitter", "sour" })[c.category]
  local sheen = tonumber(pokeblock and pokeblock[key]) or 0
  local correct = sheen ~= 0
  if correct then
    -- pokeemerald/src/lilycove_lady.c:627
    if c.maxSheen <= sheen then
      c.maxSheen = sheen
      c.playerName = Town.playerName(sess):sub(1, 7)
      c.language = Town.GAME_LANGUAGE
    end
    c.numGoodPokeblocksGiven = c.numGoodPokeblocksGiven + 1
  else
    c.numOtherPokeblocksGiven = c.numOtherPokeblocksGiven + 1
  end
  return correct
end

-- pokeemerald/src/lilycove_lady.c:727
function Lady.pokeblockState(sess)
  local c = contest(sess)
  if c.numGoodPokeblocksGiven >= Lady.GIFT_THRESHOLD then return Lady.CONTEST_LADY_GOOD end
  if c.numGoodPokeblocksGiven == 0 then return Lady.CONTEST_LADY_BAD end
  return Lady.CONTEST_LADY_NORMAL
end

-- pokeemerald/src/lilycove_lady.c:747
function Lady.shouldShowGoOnAir(sess)
  local c = contest(sess)
  return c.numGoodPokeblocksGiven >= Lady.GIFT_THRESHOLD or c.numOtherPokeblocksGiven >= Lady.GIFT_THRESHOLD
end

-- pokeemerald/src/tv.c:1581
function Lady.contestLadyTvData(sess)
  local c = contest(sess)
  if not c then return nil end
  local RomText = require("src.core.game3.rom_text")
  return {
    language = c.language,
    playerName = c.playerName,
    contestCategory = c.category,
    nickname = RomText.plain(string.format("sContestLadyMonNames[%d]", c.category)),
    pokeblockState = Lady.pokeblockState(sess),
  }
end

function Lady.mixExport(sess)
  local MixUtil = require("src.core.game3.rse.record_mix_util")
  return MixUtil.deep(Lady.state(sess))
end

-- pokeemerald/src/lilycove_lady.c:577
local function quizClearQuestionForRecordMix(prev, sess)
  local l = Lady.state(sess)
  local count = #data().quizQuestions
  local prevId = tonumber(prev.quiz and prev.quiz.prevQuestionId) or count
  if prevId < count and l.id == Lady.QUIZ then
    local q = l.quiz
    for _ = 1, 4 do
      if prevId ~= q.questionId then break end
      q.questionId = Town.random() % count
    end
    if prevId == q.questionId then q.questionId = (q.questionId + 1) % count end
    q.prevQuestionId = prevId
  end
end

-- pokeemerald/src/record_mixing.c:682
function Lady.mixImport(players, sess, myIndex)
  sess = Town.session(sess)
  local MixUtil = require("src.core.game3.rse.record_mix_util")
  local partner = MixUtil.partner(players or {}, tonumber(myIndex) or 1)
  local src = type(partner) == "table" and partner.lilycoveLady or nil
  if type(src) ~= "table" or src.id == nil then return false end
  local mine = Lady.state(sess)
  local prev = mine.id == Lady.QUIZ and MixUtil.deep(mine) or nil
  sess.lilycoveLady = MixUtil.deep(src)
  Lady.resetForRecordMix(sess)
  if prev then quizClearQuestionForRecordMix(prev, sess) end
  return true
end

local SaveSections = require("src.core.game3.save_sections")
-- pokeemerald/src/new_game.c:199
SaveSections.register("lilycoveLady", SaveSections.fields({ "lilycoveLady" }, function(sess) Lady.init(sess) end))

Rse.register("lilycoveLady", Lady)

return Lady
