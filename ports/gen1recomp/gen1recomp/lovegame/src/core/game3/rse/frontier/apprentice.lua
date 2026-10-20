local Rse = require("src.core.game3.rse.init")

local bit = rawget(_G, "bit") or require("bit")

local Apprentice = {}

Apprentice.MANIFEST = "data/generated/gba/rse/apprentice/manifest.lua"

-- pokeemerald/include/constants/apprentice.h:4
Apprentice.NUM = 16
Apprentice.SPECIES_COUNT = 10
Apprentice.NUM_WHICH_MON = 3
Apprentice.NUM_WHICH_MOVE = 5
-- pokeemerald/include/constants/global.h:60
Apprentice.MAX_QUESTIONS = 9
Apprentice.COUNT = 4
Apprentice.MULTI_PARTY_SIZE = 3
-- pokeemerald/include/constants/apprentice.h:12
Apprentice.LVL_MODE_50, Apprentice.LVL_MODE_OPEN = 1, 2
-- pokeemerald/include/constants/apprentice.h:15
Apprentice.FUNC = {
  GAVE_LVLMODE = 0, SET_LVLMODE = 1, SET_ID = 2, SHUFFLE_SPECIES = 3, RANDOMIZE_QUESTIONS = 4,
  ANSWERED_QUESTION = 5, IS_FINAL_QUESTION = 6, MENU = 7, PRINT_MSG = 8, RESET = 9, CHECK_GONE = 10,
  GET_QUESTION = 11, GET_NUM_PARTY_MONS = 12, SET_PARTY_MON = 13, INIT_QUESTION_DATA = 14,
  FREE_QUESTION_DATA = 15, BUFFER_STRING = 16, SET_MOVE = 17, SET_LEAD_MON = 18, OPEN_BAG = 19,
  TRY_SET_HELD_ITEM = 20, SAVE = 21, SET_GFX_SAVED = 22, SET_GFX = 23, SHOULD_LEAVE = 24, SHIFT_SAVED = 25,
}
-- pokeemerald/include/constants/apprentice.h:42
Apprentice.MSG = {
  PLEASE_TEACH = 0, REJECT = 1, WHICH_LVL_MODE = 2, THANKS_LVL_MODE = 3, WHICH_MON_FIRST = 4,
  THANKS_MON_FIRST = 5, WHICH_MON = 6, THANKS_MON = 7, WHICH_MOVE = 8, THANKS_MOVE = 9, WHAT_HELD_ITEM = 10,
  PICK_WIN_SPEECH = 11, THANKS_HELD_ITEM = 12, HOLD_NOTHING = 13, THANKS_NO_HELD_ITEM = 14,
  THANKS_WIN_SPEECH = 15, ITEM_ALREADY_SUGGESTED = 16,
}
-- pokeemerald/include/constants/apprentice.h:60
Apprentice.QUESTION = { WHICH_FIRST = 1, WHICH_MON = 2, WHICH_MOVE = 3, WHAT_ITEM = 4, WIN_SPEECH = 5 }
Apprentice.QID = { WIN_SPEECH = 0, WHAT_ITEM = 1, WHICH_MOVE = 2, WHICH_FIRST = 3 }
-- pokeemerald/include/constants/apprentice.h:72
Apprentice.ASK = { WHICH_LEVEL = 0, THREE_SPECIES = 1, TWO_SPECIES = 2, MOVES = 3, GIVE = 4, YES_NO = 6 }
-- pokeemerald/include/constants/apprentice.h:79
Apprentice.BUFF = {
  SPECIES1 = 0, SPECIES2 = 1, SPECIES3 = 2, MOVE1 = 3, MOVE2 = 4, ITEM = 5, NAME = 6, WIN_SPEECH = 7,
  LEVEL = 8, LEAD_MON_SPECIES = 9,
}
-- pokeemerald/include/constants/vars.h:287
Apprentice.VAR_0x8004, Apprentice.VAR_0x8005, Apprentice.VAR_0x8006, Apprentice.VAR_RESULT = 0x8004, 0x8005, 0x8006, 0x800D
-- pokeemerald/include/constants/battle_frontier.h:51
Apprentice.FRONTIER_MAX_LEVEL_50 = 50
Apprentice.OPEN_LEARNSET_LEVEL = 60
Apprentice.MULTI_B_PRESSED = 127
Apprentice.NUM_TMHM = 58
-- pokeemerald/include/constants/easy_chat.h:1129
Apprentice.EC_EMPTY_WORD = 0xFFFF

local cache = {}

function Apprentice.manifest()
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get())
  local hit = cache[key]
  if hit then return hit end
  local src = require("src.core.game3.dataset").cache():read(Apprentice.MANIFEST)
  if type(src) ~= "string" then error("apprentice: " .. Apprentice.MANIFEST .. " missing from the cache", 0) end
  local chunk = assert((loadstring or load)(src, "@" .. Apprentice.MANIFEST))
  if setfenv then setfenv(chunk, {}) end
  hit = chunk()
  cache[key] = hit
  return hit
end

local function D() return require("src.core.game3.rse.frontier.trainers") end
local function rng() return D().rng() end
local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end
local function setSpecialVar(ctx, id, v) Rse.setSpecialVar(ctx, id, v) end
local function setResult(ctx, v) setSpecialVar(ctx, Apprentice.VAR_RESULT, v) end

function Apprentice.defs()
  return D().pack("apprentices").apprentices
end

function Apprentice.def(id)
  return Apprentice.defs()[tonumber(id) or 0]
end

local function newQuestions()
  local q = {}
  for i = 1, Apprentice.MAX_QUESTIONS do
    q[i] = { questionId = 0, monId = 0, moveSlot = 0, suggestedChange = 0, data = 0 }
  end
  return q
end

-- pokeemerald/include/global.h:473
function Apprentice.newPlayerApprentice()
  return { id = 0, lvlMode = 0, questionsAnswered = 0, leadMonId = 0, party = 0, saveId = 0,
    speciesIds = { 0, 0, 0 }, questions = newQuestions() }
end

-- pokeemerald/include/global.h:266
function Apprentice.newSaved()
  local speech = {}
  for i = 1, 6 do speech[i] = Apprentice.EC_EMPTY_WORD end
  local party = {}
  for i = 1, 3 do party[i] = { species = 0, moves = { 0, 0, 0, 0 }, item = 0 } end
  return { id = Apprentice.NUM, lvlMode = 0, numQuestions = 0, number = 0, party = party, speechWon = speech,
    playerId = { 0, 0, 0, 0 }, playerName = "", language = 2, checksum = 0 }
end

function Apprentice.player(sess)
  sess = sess or Rse.session()
  if type(sess.playerApprentice) ~= "table" then
    sess.playerApprentice = Apprentice.newPlayerApprentice()
    -- pokeemerald/src/new_game.c:200
    Apprentice.setId(sess)
  end
  local p = sess.playerApprentice
  if type(p.questions) ~= "table" then p.questions = newQuestions() end
  if type(p.speciesIds) ~= "table" then p.speciesIds = { 0, 0, 0 } end
  return p
end

function Apprentice.saved(sess)
  sess = sess or Rse.session()
  if type(sess.apprentices) ~= "table" then sess.apprentices = {} end
  for i = 1, Apprentice.COUNT do
    if type(sess.apprentices[i]) ~= "table" then sess.apprentices[i] = Apprentice.newSaved() end
  end
  return sess.apprentices
end

-- pokeemerald/src/apprentice.c:151
function Apprentice.resetAll(sess)
  local p = Apprentice.player(sess)
  p.saveId = 0
  sess.apprentices = nil
  Apprentice.saved(sess)
  Apprentice.resetPlayer(sess)
end

Apprentice.SAVE_FIELDS = { "playerApprentice", "apprentices" }

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  SaveSections.register("apprentice", SaveSections.fields(Apprentice.SAVE_FIELDS, function(session)
    session.playerApprentice = nil
    session.apprentices = nil
    Apprentice.resetAll(session)
  end))
end

-- pokeemerald/src/apprentice.c:179
function Apprentice.setId(sess)
  local p = Apprentice.player(sess)
  local saved = Apprentice.saved(sess)
  local m = Apprentice.manifest()
  local Rng = rng()
  if (tonumber(saved[1].number) or 0) == 0 then
    repeat
      p.id = m.initialIds[(Rng.Random() % #m.initialIds) + 1]
    until p.id ~= saved[1].id
  else
    repeat
      p.id = Rng.Random() % Apprentice.NUM
    until p.id ~= saved[1].id
  end
end

-- pokeemerald/src/apprentice.c:727
function Apprentice.resetPlayer(sess)
  local p = Apprentice.player(sess)
  Apprentice.setId(sess)
  p.lvlMode, p.questionsAnswered, p.leadMonId, p.party = 0, 0, 0, 0
  p.speciesIds = { 0, 0, 0 }
  p.questions = newQuestions()
end

-- pokeemerald/src/apprentice.c:202
function Apprentice.shuffleSpecies(sess)
  local p = Apprentice.player(sess)
  local Rng = rng()
  local species = {}
  for i = 0, Apprentice.SPECIES_COUNT - 1 do species[i + 1] = i end
  for _ = 1, 50 do
    local a = Rng.Random() % Apprentice.SPECIES_COUNT
    local b = Rng.Random() % Apprentice.SPECIES_COUNT
    species[a + 1], species[b + 1] = species[b + 1], species[a + 1]
  end
  for i = 0, Apprentice.MULTI_PARTY_SIZE - 1 do
    p.speciesIds[i + 1] = bit.bor(bit.lshift(bit.band(species[i * 2 + 1], 0xF), 4), bit.band(species[i * 2 + 2], 0xF))
  end
end

-- pokeemerald/src/apprentice.c:323
function Apprentice.speciesIdOf(sess, monId)
  local p = Apprentice.player(sess)
  if monId >= Apprentice.MULTI_PARTY_SIZE then return 0 end
  local shift = bit.band(bit.rshift(p.party, monId), 1) * 4
  return bit.band(bit.rshift(p.speciesIds[monId + 1], shift), 0xF)
end

function Apprentice.species(sess, arrayId)
  local def = Apprentice.def(Apprentice.player(sess).id)
  return def and def.species[arrayId + 1] or 0
end

local function learnsetUpTo(sess, species)
  local Pokemon = require("src.core.game3.pokemon")
  local p = Apprentice.player(sess)
  local level = (p.lvlMode == Apprentice.LVL_MODE_50) and Apprentice.FRONTIER_MAX_LEVEL_50 or Apprentice.OPEN_LEARNSET_LEVEL
  local out = {}
  for _, e in ipairs(Pokemon.learnset(species)) do
    local lv = tonumber(e.level or e[1]) or 0
    if lv > level then break end
    out[#out + 1] = tonumber(e.move or e.moveId or e[2]) or 0
  end
  return out
end
Apprentice.learnsetUpTo = learnsetUpTo

-- pokeemerald/src/apprentice.c:459
function Apprentice.latestMoves(sess, species)
  local list = learnsetUpTo(sess, species)
  local n = math.min(#list, 4)
  local moves = { 0, 0, 0, 0 }
  for j = 0, n - 1 do moves[j + 1] = list[#list - j] end
  return moves
end

-- pokeemerald/src/apprentice.c:445
local function trySetMove(pm, monId, move)
  for i = 1, Apprentice.NUM_WHICH_MOVE do
    if pm.moves[monId + 1][i] == move then return false end
  end
  pm.moves[monId + 1][pm.moveCounter + 1] = move
  return true
end

-- pokeemerald/src/apprentice.c:332
function Apprentice.randomAlternateMove(sess, pm, monId)
  local Pokemon = require("src.core.game3.pokemon")
  local m = Apprentice.manifest()
  local Rng = rng()
  local species = Apprentice.species(sess, Apprentice.speciesIdOf(sess, monId))
  local list = learnsetUpTo(sess, species)
  local n = #list
  local needTMs = false
  local move = 0
  local i = 0
  local guard = 0
  while i < 5 and guard < 1000 do
    guard = guard + 1
    local skip = false
    if Rng.Random() % 2 == 0 or needTMs then
      local ok = false
      local inner = 0
      repeat
        inner = inner + 1
        local id
        repeat
          id = Rng.Random() % Apprentice.NUM_TMHM
          inner = inner + 1
        until Pokemon.canLearnTmIndex(species, id) or inner > 4000
        move = Pokemon.moveFromTmItem(289 + id) or 0
        ok = true
        local j = (n <= 4) and 0 or (n - 4)
        for k = j + 1, n do
          if list[k] == move then ok = false break end
        end
      until ok or inner > 4000
    else
      if n <= 4 then
        needTMs = true
        skip = true
      else
        local ok
        local inner = 0
        repeat
          inner = inner + 1
          move = list[(Rng.Random() % (n - 4)) + 1]
          ok = true
          for k = n - 3, n do
            if list[k] == move then ok = false break end
          end
        until ok or inner > 4000
      end
    end
    if not skip then
      if trySetMove(pm, monId, move) then
        if (m.validMoves[move + 1] or 0) ~= 0 then break end
        i = i + 1
      end
    end
  end
  pm.moveCounter = pm.moveCounter + 1
  return move
end

-- pokeemerald/src/apprentice.c:252
function Apprentice.setRandomQuestionData(sess)
  local p = Apprentice.player(sess)
  local m = Apprentice.manifest()
  local Rng = rng()
  local partyOrder = { 0, 1, 2 }
  for _ = 1, 10 do
    local a = Rng.Random() % 3
    local b = Rng.Random() % 3
    partyOrder[a + 1], partyOrder[b + 1] = partyOrder[b + 1], partyOrder[a + 1]
  end
  local order = {}
  for i = 1, #m.questionPossibilities do order[i] = m.questionPossibilities[i] end
  for _ = 1, 50 do
    local a = Rng.Random() % #order
    local b = Rng.Random() % #order
    order[a + 1], order[b + 1] = order[b + 1], order[a + 1]
  end
  local pm = { moveCounter = 0, moves = {}, moveSlots = {} }
  for j = 1, 3 do
    pm.moves[j] = { 0, 0, 0, 0, 0 }
    pm.moveSlots[j] = { 4, 4, 4, 4, 4 }
  end
  local partySlot = 0
  for i = 1, Apprentice.MAX_QUESTIONS do
    local q = p.questions[i]
    q.questionId = order[i]
    if order[i] ~= Apprentice.QID.WHICH_FIRST then
      local monId = 0
      if order[i] == Apprentice.QID.WHICH_MOVE then
        repeat
          monId = Rng.Random() % 3
          local count = 0
          for k = 1, Apprentice.NUM_WHICH_MOVE do
            if pm.moves[monId + 1][k] ~= 0 then count = count + 1 end
          end
        until count <= 3
      elseif order[i] == Apprentice.QID.WHAT_ITEM then
        monId = partyOrder[partySlot + 1]
        partySlot = partySlot + 1
      end
      q.monId = monId
      if order[i] == Apprentice.QID.WHICH_MOVE then
        local r
        repeat
          r = Rng.Random() % 4
          local j = 0
          while j < pm.moveCounter + 1 do
            if pm.moveSlots[monId + 1][j + 1] == r then break end
            j = j + 1
          end
        until j == pm.moveCounter + 1
        pm.moveSlots[monId + 1][pm.moveCounter + 1] = r
        q.moveSlot = r
        q.data = Apprentice.randomAlternateMove(sess, pm, monId)
      end
    end
  end
end

local function currentQuestion(p)
  return p.questionsAnswered - Apprentice.NUM_WHICH_MON
end

local function numQuestions(p)
  local n = 0
  for i = 1, Apprentice.MAX_QUESTIONS do
    if p.questions[i].questionId == Apprentice.QID.WIN_SPEECH then break end
    n = n + 1
  end
  return n
end

-- pokeemerald/src/apprentice.c:487
function Apprentice.defaultMove(sess, monId, speciesArrayId, moveSlot)
  local p = Apprentice.player(sess)
  if p.questionsAnswered < Apprentice.NUM_WHICH_MON then return 0 end
  local moves = Apprentice.latestMoves(sess, Apprentice.species(sess, speciesArrayId))
  local nq = numQuestions(p)
  for i = 0, nq - 1 do
    if i >= currentQuestion(p) then break end
    local q = p.questions[i + 1]
    if q.questionId == Apprentice.QID.WHICH_MOVE and q.monId == monId and q.suggestedChange ~= 0 then
      moves[q.moveSlot + 1] = q.data
    end
  end
  return moves[moveSlot + 1]
end

-- pokeemerald/src/apprentice.c:920
function Apprentice.getQuestion(ctx, sess)
  local p = Apprentice.player(sess)
  local Q = Apprentice.QUESTION
  if p.questionsAnswered < Apprentice.NUM_WHICH_MON then
    setResult(ctx, Q.WHICH_MON)
  elseif p.questionsAnswered > Apprentice.MAX_QUESTIONS + Apprentice.NUM_WHICH_MON - 1 then
    setResult(ctx, Q.WIN_SPEECH)
  else
    local qid = p.questions[currentQuestion(p) + 1].questionId
    if qid == Apprentice.QID.WHAT_ITEM then setResult(ctx, Q.WHAT_ITEM)
    elseif qid == Apprentice.QID.WHICH_MOVE then setResult(ctx, Q.WHICH_MOVE)
    elseif qid == Apprentice.QID.WHICH_FIRST then setResult(ctx, Q.WHICH_FIRST)
    else setResult(ctx, Q.WIN_SPEECH) end
  end
end

-- pokeemerald/src/apprentice.c:977
function Apprentice.initQuestionData(ctx, sess)
  local p = Apprentice.player(sess)
  local which = specialVar(ctx, Apprentice.VAR_0x8005)
  local qd = { speciesId = 0, altSpeciesId = 0, move1 = 0, move2 = 0 }
  local count = numQuestions(p)
  local Q = Apprentice.QUESTION
  if which == Q.WHICH_MON then
    if p.questionsAnswered < Apprentice.NUM_WHICH_MON then
      local ids = p.speciesIds[p.questionsAnswered + 1]
      qd.altSpeciesId = Apprentice.species(sess, bit.rshift(ids, 4))
      qd.speciesId = Apprentice.species(sess, bit.band(ids, 0xF))
    end
  elseif which == Q.WHICH_MOVE or which == Q.WHAT_ITEM then
    local cq = currentQuestion(p)
    local q = p.questions[cq + 1]
    local want = which == Q.WHICH_MOVE and Apprentice.QID.WHICH_MOVE or Apprentice.QID.WHAT_ITEM
    if p.questionsAnswered >= Apprentice.NUM_WHICH_MON and p.questionsAnswered < count + Apprentice.NUM_WHICH_MON
        and q and q.questionId == want then
      local monId = q.monId
      local sel = bit.band(bit.rshift(p.party, monId), 1)
      local arrayId = bit.band(bit.rshift(p.speciesIds[monId + 1], sel * 4), 0xF)
      qd.speciesId = Apprentice.species(sess, arrayId)
      if which == Q.WHICH_MOVE then
        qd.move1 = Apprentice.defaultMove(sess, monId, arrayId, q.moveSlot)
        qd.move2 = q.data
      end
    end
  end
  Apprentice.questionData = qd
end

-- pokeemerald/src/apprentice.c:1032
function Apprentice.bufferString(ctx, adapters, sess)
  local Util = require("src.core.game3.rse.frontier.util")
  local Pokemon = require("src.core.game3.pokemon")
  local p = Apprentice.player(sess)
  local slot = specialVar(ctx, Apprentice.VAR_0x8005)
  if slot > 2 then return end
  local which = specialVar(ctx, Apprentice.VAR_0x8006)
  local qd = Apprentice.questionData or {}
  local B = Apprentice.BUFF
  local RomText = require("src.core.game3.rom_text")
  local s
  if which == B.SPECIES1 or which == B.SPECIES3 then s = Pokemon.name(qd.speciesId or 0)
  elseif which == B.SPECIES2 then s = Pokemon.name(qd.altSpeciesId or 0)
  elseif which == B.MOVE1 then s = Pokemon.moveName(qd.move1 or 0)
  elseif which == B.MOVE2 then s = Pokemon.moveName(qd.move2 or 0)
  elseif which == B.ITEM then
    local q = p.questions[currentQuestion(p) + 1]
    s = require("src.core.game3.items_data").displayName(q and q.data or 0)
  elseif which == B.NAME then
    local def = Apprentice.def(p.id)
    s = def and def.name or ""
  elseif which == B.LEVEL then
    s = RomText.plain(p.lvlMode == Apprentice.LVL_MODE_50 and "gText_Lv50" or "gText_OpenLevel")
  elseif which == B.WIN_SPEECH then
    local TextIR = require("src.core.game3.scripting.text_ir")
    s = TextIR.toPlain(D().speechToString(Apprentice.saved(sess)[1].speechWon), {})
  elseif which == B.LEAD_MON_SPECIES then
    s = Pokemon.name(Apprentice.species(sess, Apprentice.speciesIdOf(sess, p.leadMonId)))
  end
  if s then Util.setStringVar(ctx, adapters, slot + 1, s) end
end

-- pokeemerald/src/apprentice.c:1104
function Apprentice.trySetHeldItem(ctx, sess)
  local p = Apprentice.player(sess)
  if p.questionsAnswered < Apprentice.NUM_WHICH_MON then return end
  local item = specialVar(ctx, Apprentice.VAR_0x8005)
  local count = numQuestions(p)
  local cq = currentQuestion(p)
  for i = 0, count - 1 do
    if i >= cq then break end
    local q = p.questions[i + 1]
    if q.questionId == Apprentice.QID.WHAT_ITEM and q.suggestedChange ~= 0 and q.data == item then
      p.questions[cq + 1].suggestedChange = 0
      p.questions[cq + 1].data = item
      setResult(ctx, 0)
      return
    end
  end
  p.questions[cq + 1].suggestedChange = 1
  p.questions[cq + 1].data = item
  setResult(ctx, 1)
end

-- pokeemerald/src/apprentice.c:513
function Apprentice.saveParty(sess, nq)
  local p = Apprentice.player(sess)
  local a = Apprentice.saved(sess)[1]
  for i = 1, 3 do a.party[i] = { species = 0, moves = { 0, 0, 0, 0 }, item = 0 } end
  local mons = {}
  local j = p.leadMonId
  for i = 1, 3 do
    mons[j + 1] = a.party[i]
    j = (j + 1) % 3
  end
  for i = 0, 2 do
    mons[i + 1].species = Apprentice.species(sess, Apprentice.speciesIdOf(sess, i))
    mons[i + 1].moves = Apprentice.latestMoves(sess, mons[i + 1].species)
  end
  for i = 1, nq do
    local q = p.questions[i]
    if q.questionId == Apprentice.QID.WHAT_ITEM and q.suggestedChange ~= 0 then
      mons[q.monId + 1].item = q.data
    elseif q.questionId == Apprentice.QID.WHICH_MOVE and q.suggestedChange ~= 0 then
      mons[q.monId + 1].moves[q.moveSlot + 1] = q.data
    end
  end
end

-- pokeemerald/src/apprentice.c:1177
function Apprentice.save(sess)
  local p = Apprentice.player(sess)
  local a = Apprentice.saved(sess)[1]
  a.id = p.id
  a.lvlMode = p.lvlMode
  a.numQuestions = numQuestions(p)
  if a.number < 255 then a.number = a.number + 1 end
  Apprentice.saveParty(sess, a.numQuestions)
  local tid = tonumber(sess.trainerId) or 0
  local sid = tonumber(sess.secretId) or 0
  a.playerId = { tid % 256, math.floor(tid / 256) % 256, sid % 256, math.floor(sid / 256) % 256 }
  a.playerName = sess.name or ""
  a.language = 2
end

local function trainerIdOf(bytes)
  return (tonumber(bytes[1]) or 0) + (tonumber(bytes[2]) or 0) * 256
end

-- pokeemerald/src/apprentice.c:1142
function Apprentice.shiftSaved(sess)
  local list = Apprentice.saved(sess)
  if (list[1].playerName or "") == "" then return end
  for i = 1, Apprentice.COUNT - 1 do
    if (list[i + 1].playerName or "") == "" then
      list[i + 1] = Apprentice.copy(list[1])
      return
    end
  end
  local best, idx = 0xFFFF, -1
  local mine = (tonumber(sess.trainerId) or 0) % 65536
  for i = 2, Apprentice.COUNT do
    if trainerIdOf(list[i].playerId) == mine and list[i].number < best then
      best, idx = list[i].number, i
    end
  end
  if idx > 1 then list[idx] = Apprentice.copy(list[1]) end
end

function Apprentice.copy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = Apprentice.copy(x) end
  return out
end

-- pokeemerald/src/apprentice.c:1226
function Apprentice.setGfx(sess)
  local def = Apprentice.def(Apprentice.player(sess).id)
  if not def then return end
  Rse.setVar("VAR_OBJ_GFX_ID_0", D().facilityClassToGfx(def.facilityClass), sess)
end

-- pokeemerald/src/apprentice.c:1202
function Apprentice.setSavedGfx(sess)
  local def = Apprentice.def(Apprentice.saved(sess)[1].id)
  if not def then return end
  Rse.setVar("VAR_OBJ_GFX_ID_0", D().facilityClassToGfx(def.facilityClass), sess)
end

-- pokeemerald/src/apprentice.c:827
function Apprentice.message(sess, which)
  local m = Apprentice.manifest()
  local id = Apprentice.player(sess).id + 1
  local M = Apprentice.MSG
  local map = {
    [M.WHICH_MON] = { m.whichMon, 1 }, [M.THANKS_MON] = { m.whichMon, 2 },
    [M.WHICH_MOVE] = { m.whichMove, 1 }, [M.THANKS_MOVE] = { m.whichMove, 2 },
    [M.WHICH_MON_FIRST] = { m.whichMonFirst, 1 }, [M.THANKS_MON_FIRST] = { m.whichMonFirst, 2 },
    [M.WHAT_HELD_ITEM] = { m.heldItem, 1 }, [M.PICK_WIN_SPEECH] = { m.pickWinSpeech, 1 },
    [M.THANKS_HELD_ITEM] = { m.heldItem, 4 }, [M.HOLD_NOTHING] = { m.heldItem, 2 },
    [M.ITEM_ALREADY_SUGGESTED] = { m.heldItem, 5 }, [M.THANKS_NO_HELD_ITEM] = { m.heldItem, 3 },
    [M.THANKS_WIN_SPEECH] = { m.pickWinSpeech, 2 }, [M.PLEASE_TEACH] = { m.firstMeeting, 1 },
    [M.REJECT] = { m.firstMeeting, 2 }, [M.WHICH_LVL_MODE] = { m.firstMeeting, 3 },
    [M.THANKS_LVL_MODE] = { m.firstMeeting, 4 },
  }
  local e = map[which]
  if not e then return nil end
  local ref = e[1][id] and e[1][id][e[2]]
  return ref and require("src.core.game3.rom_text").refIr(ref)
end

-- pokeemerald/src/apprentice.c:564
function Apprentice.menuOptions(sess, which)
  local Pokemon = require("src.core.game3.pokemon")
  local RomText = require("src.core.game3.rom_text")
  local A = Apprentice.ASK
  local qd = Apprentice.questionData or {}
  local p = Apprentice.player(sess)
  if which == A.WHICH_LEVEL then
    return { RomText.plain("gText_Lv50"), RomText.plain("gText_OpenLevel") }, 18, 8
  elseif which == A.THREE_SPECIES then
    local out = {}
    for i = 0, 2 do out[i + 1] = Pokemon.name(Apprentice.species(sess, Apprentice.speciesIdOf(sess, i))) end
    return out, 18, 6
  elseif which == A.TWO_SPECIES then
    if p.questionsAnswered >= Apprentice.NUM_WHICH_MON then return nil end
    return { Pokemon.name(qd.speciesId or 0), Pokemon.name(qd.altSpeciesId or 0) }, 18, 8
  elseif which == A.MOVES then
    return { Pokemon.moveName(qd.move1 or 0), Pokemon.moveName(qd.move2 or 0) }, 17, 8
  elseif which == A.GIVE then
    return { RomText.plain("gText_Give"), RomText.plain("gText_NoNeed") }, 18, 8
  elseif which == A.YES_NO then
    return { RomText.plain("gText_Yes"), RomText.plain("gText_No") }, 20, 8
  end
  return nil
end

-- pokeemerald/src/item_menu.c:595
function Apprentice.holdableItems(sess)
  local Bag = require("src.core.game3.bag")
  local ItemsData = require("src.core.game3.items_data")
  local out = {}
  for _, pocket in ipairs({ "ITEMS", "BERRY_POUCH" }) do
    for _, row in ipairs(Bag.listPocket(sess.bag, pocket) or {}) do
      local info = ItemsData.info(row.id) or {}
      if (tonumber(info.importance) or 0) == 0 then out[#out + 1] = ItemsData.toNumericId(row.id) or row.id end
    end
  end
  return out
end

local function easyChatType()
  local okT, Types = pcall(require, "src.core.game3.rse.easy_chat_types")
  if not okT then return end
  -- pokeemerald/src/easy_chat.c:598
  Types.register(Types.ID.APPRENTICE, {
    words = function(_, sess)
      local out = {}
      local w = Apprentice.saved(sess)[1].speechWon
      for i = 1, 6 do out[i] = w[i] end
      return out
    end,
    commit = function(_, sess, words)
      local a = Apprentice.saved(sess)[1]
      for i = 1, 6 do a.speechWon[i] = tonumber(words[i]) or Apprentice.EC_EMPTY_WORD end
    end,
  })
end
easyChatType()

local function mixUtil()
  return require("src.core.game3.rse.record_mix_util")
end

-- pokeemerald/src/record_mixing.c:1062
function Apprentice.mixExport(sess)
  sess = sess or Rse.session()
  local MixUtil = mixUtil()
  local src = Apprentice.saved(sess)
  local saveId = tonumber(Apprentice.player(sess).saveId) or 0
  local dst = { Apprentice.copy(src[1]), Apprentice.newSaved() }
  dst[2].playerName = ""
  local mine = MixUtil.sessionLinkTrainerId(sess)
  local slots = Apprentice.COUNT - 1
  local oldId, numOld, mixId, numMix = 0, 0, 0, 0
  for i = 0, 1 do
    local id = (i + saveId) % slots + 1
    if (src[id + 1].playerName or "") ~= "" then
      local tid = MixUtil.getTrainerId(src[id + 1].playerId)
      if tid ~= mine then numMix, mixId = numMix + 1, id end
      if tid == mine then numOld, oldId = numOld + 1, id end
    end
  end
  if numMix == 0 and numOld ~= 0 then numMix, mixId = numOld, oldId end
  if numMix == 1 then
    dst[2] = Apprentice.copy(src[mixId + 1])
  elseif numMix == 2 then
    if rng().Random2() > 0x3333 then
      dst[2] = Apprentice.copy(src[saveId + 1 + 1])
    else
      dst[2] = Apprentice.copy(src[((saveId + 1) % slots + 1) + 1])
    end
  end
  return dst
end

-- pokeemerald/src/record_mixing.c:1155
local function alreadySaved(a, saved)
  local MixUtil = mixUtil()
  for i = 1, Apprentice.COUNT do
    if MixUtil.getTrainerId(a.playerId) == MixUtil.getTrainerId(saved[i].playerId)
      and (tonumber(a.number) or 0) == (tonumber(saved[i].number) or 0) then
      return true
    end
  end
  return false
end

-- pokeemerald/src/record_mixing.c:1169
function Apprentice.mixImport(players, sess, myIndex)
  sess = sess or Rse.session()
  local partner = mixUtil().partner(players or {}, tonumber(myIndex) or 1)
  local mix = type(partner) == "table" and partner.apprentices or nil
  if type(mix) ~= "table" then return false end
  local saved = Apprentice.saved(sess)
  local p = Apprentice.player(sess)
  local slots = Apprentice.COUNT - 1
  local num, which = 0, 0
  for i = 0, 1 do
    local a = mix[i + 1]
    if type(a) == "table" and (a.playerName or "") ~= "" and not alreadySaved(a, saved) then
      num, which = num + 1, i
    end
  end
  local saveId = tonumber(p.saveId) or 0
  if num == 1 then
    saved[saveId + 1 + 1] = Apprentice.copy(mix[which + 1])
    p.saveId = (saveId + 1) % slots
  elseif num == 2 then
    for i = 0, 1 do
      local idx = (bit.bxor(i, 1) + saveId) % slots + 1
      saved[idx + 1] = Apprentice.copy(mix[i + 1])
    end
    p.saveId = (saveId + 2) % slots
  end
  return true
end

Rse.register("apprentice", Apprentice)

return Apprentice
