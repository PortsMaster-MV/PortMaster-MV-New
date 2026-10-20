local Easy = require("src.core.game3.easy_chat_text")
local M = {EMPTY = 0xFFFF, USED_FLAG = "FLAG_SYS_CHAT_USED"}

M.SHAPES = {
  [0] = {count = 6, columns = 2, rows = 3, cursor = {4, 3}, pen = {5, 3}, frame = {2, 2, 0, 10, 26, 8}},
  [1] = {count = 9, columns = 2, rows = 5, cursor = {4, 0}, pen = {5, 0}, frame = {2, 0, 0, 0, 26, 10}},
  [2] = {count = 1, columns = 1, rows = 1, cursor = {16, 4}, pen = {17, 4}, frame = {14, 3, 13, 18, 13, 4}},
  [3] = {count = 2, columns = 2, rows = 1, cursor = {5, 3}, pen = {6, 3}, frame = {3, 2, 0, 32, 24, 4}},
  [4] = {count = 4, columns = 2, rows = 2, cursor = {5, 4}, pen = {6, 4}, frame = {3, 3, 0, 26, 24, 6}},
  [5] = {count = 4, columns = 1, rows = 4, cursor = {16, 2}, pen = {17, 2}, frame = {14, 2, 0, 18, 13, 8}},
}

M.PROMPTS = {
  [0] = {"OtherText_MakeProfilePage1", "OtherText_MakeProfilePage2", true},
  {"OtherText_MakeMessagePage1", "OtherText_MakeMessagePage2", true},
  {"OtherText_CombineNinePhrasesPage1", "OtherText_CombineNinePhrasesPage2", true},
  {"OtherText_DescribeFeelingsPage1", "OtherText_DescribeFeelingsPage2", true},
  {"OtherText_ImproveBardSongPage1", "OtherText_ImproveBardSongPage2", true},
  {"OtherText_CombineTwoPhrasesPage1", "OtherText_CombineTwoPhrasesPage2", true},
  {"OtherText_YourProfile", "OtherText_ConfirmTrendyPage2", false},
  {"OtherText_YourFeelingBattle", "OtherText_ConfirmTrendyPage2", true},
  {"OtherText_SetWinMessage", "OtherText_ConfirmTrendyPage2", true},
  {"OtherText_SetLossMessage", "OtherText_ConfirmTrendyPage2", true},
  {"OtherText_MailMessage", "OtherText_ConfirmTrendyPage2", true},
  {"OtherText_MailSalutation", "OtherText_ConfirmTrendyPage2", true},
  {"OtherText_NewSong", "OtherText_ConfirmTrendyPage2", false},
  {"OtherText_TheAnswer", "OtherText_ConfirmTrendyPage2", false},
  {"OtherText_ConfirmTrendyPage1", "OtherText_ConfirmTrendyPage2", true},
  {"OtherText_HipsterPage1", "OtherText_HipsterPage2", true},
  {"OtherText_WithFourPhrases", "OtherText_CombineNinePhrasesPage2", true},
}
local types = {
  [0] = {4, 0, 6, "Profile", "profile"},
  {0, 1, 7, "AtBattleStart", "battleStart"},
  {0, 1, 8, "UponWinningBattle", "battleWon"},
  {0, 1, 9, "UponLosingBattle", "battleLost"},
  {1, 2, 10, false, "mail"},
  {5, 16, 13, "Interview", "tvFourWords"},
  {0, 4, 12, "TheBardsSong", "bardTemporary"},
  {2, 3, 13, "Interview", "tvOpinion"},
  {2, 3, 13, "Interview", "tvSpeciesAlias"},
  {3, 5, 14, "WhatsHipHappening", "trend"},
  {2, 3, 13, "Interview", "gabbyQuote"},
  {2, 3, 13, "Interview", "tvContest"},
  {2, 3, 13, "Interview", "tvTower"},
  {3, 15, 13, "GoodSaying", "berryWife"},
}
M.TYPES = {}
for id, row in pairs(types) do
  M.TYPES[id] = {type = id, shapeId = row[1], shape = M.SHAPES[row[1]],
    editPromptId = row[2], confirmPromptId = row[3],
    editPrompt = M.PROMPTS[row[2]], confirmPrompt = M.PROMPTS[row[3]],
    header = row[4] and "gOtherText_" .. row[4] or nil, destination = row[5],
    cancelWarnings = (id <= 3 or id == 6) and 2 or 1, cancelDefault = 1,
    confirmDefault = 0, deleteDefault = 1, deleteAllowed = id ~= 6,
    cancelPrompt = id == 9 and "gOtherText_QuitGivingInfo" or id == 4 and "gOtherText_StopGivingMail" or "gOtherText_QuitEditing",
    changesInput = id == 0 or id == 9 or id == 13,
  }
end
M.ERRORS = {empty = "gOtherText_EnterAPhraseOrWord", unchanged = "gOtherText_TrendyAlready",
  incomplete = "gOtherText_CombineTwoPhrases", noDelete = "gOtherText_TextNoDelete",
  bardRestore = {"gOtherText_OnlyOnePhrase", "gOtherText_OriginalSongRestored"}}
M.CONTROLS = {footer = {"delete", "cancel", "confirm"}, footerArt = "gUnknown_08E945D0",
  start = "confirm", horizontalWrap = true, verticalWrap = true,
  deletePrompt = {"gOtherText_TextDeletedConfirmPage1", "gOtherText_TextDeletedConfirmPage2"},
  discardPrompt = {"gOtherText_EditedTextNoSavePage1", "gOtherText_EditedTextNoSavePage2"},
  promptPens = {{4, 15}, {4, 17}}, yesNo = {23, 8}}

M.MYSTERY = {10 * 512 + 0x3A, 12 * 512 + 0x17, 8 * 512 + 0x0B, 16 * 512 + 0x0F}
M.BERRY_PHRASES = {{9 * 512 + 0x40, 3 * 512 + 0x28}, {3 * 512 + 0x1F, 17 * 512 + 4},
  {10 * 512 + 0x22, 407}, {2 * 512 + 0x15, 408}, {17 * 512 + 7, 2 * 512 + 0x49}}
M.INITIALIZATION = {profile = {5 * 512 + 41, 8 * 512 + 32, 512 + 14, 9 * 512 + 64},
  battleStart = {8 * 512 + 15, 5 * 512 + 2, 7 * 512 + 37, 6 * 512 + 3, 4 * 512 + 3, 6 * 512},
  battleWon = {65535, 65535, 65535, 65535, 65535, 65535},
  battleLost = {65535, 65535, 65535, 65535, 65535, 65535}, mailCount = 16, mailWords = 9,
  rawClear = {offset = 0x2D8C, size = 64, value = 0}}

local function codecFor(session)
  local codec = require("src.save_convert.Gen3Save").forVersion(assert(session and session.version, "RS EasyChat requires a session"))
  assert(codec.L.FAMILY == "rs", "native RS EasyChat cannot mutate another game's save")
  return codec
end
local function copy(words, count)
  local out = {}
  for i = 1, count do out[i] = words and words[i] or M.EMPTY end
  return out
end
local function byteString(bytes, size)
  if type(bytes) ~= "table" or #bytes ~= size then return string.rep("\0", size) end
  local out = {}
  for i = 1, size do out[i] = string.char(bytes[i]) end
  return table.concat(out)
end
local function rawTv(token)
  local Tv = require("src.save_convert.gen3_port.sections.rs_tv_shows")
  local show = token.session.tvShows and token.session.tvShows[token.slot] or {kind = 0, active = false}
  local raw = Tv.render(token.codec, byteString(show.nativeBytes, 36), show, require("src.save_convert.gen3_port.rse").same)
  if show.kind == 0 and type(show.words) == "table" and token.type ~= 8 then
    local at = token.type == 5 and 4 or token.type == 7 and 28 or token.type == 11 and 4 or 24
    local count = token.type == 5 and 6 or (token.type == 7 or token.type == 11) and 2 or 1
    local buf = token.codec.newBuf(36, raw)
    for i = 1, count do if show.words[i] ~= nil then buf:w16(at + (i - 1) * 2, show.words[i]) end end
    raw = buf:str()
  end
  return raw
end
local function writeTv(token, words)
  local Tv = require("src.save_convert.gen3_port.sections.rs_tv_shows")
  local buf = token.codec.newBuf(36, rawTv(token))
  for i = 1, token.wordCount do buf:w16(token.offset + (i - 1) * 2, words[i]) end
  local raw = buf:str()
  local show = Tv.readSlot(raw, token.codec)
  if show.kind == 0 then
    if token.type == 8 then show.species = token.codec.u16(raw, 2)
    else
      local at = token.type == 5 and 4 or token.type == 7 and 28 or token.type == 11 and 4 or 24
      local count = token.type == 5 and 6 or (token.type == 7 or token.type == 11) and 2 or 1
      show.words = {}
      for i = 1, count do show.words[i] = token.codec.u16(raw, at + (i - 1) * 2) end
    end
  end
  token.session.tvShows = token.session.tvShows or {}
  token.session.tvShows[token.slot] = show
end
local function oldManRaw(token)
  local OldMan = require("src.save_convert.gen3_port.sections.rs_old_man")
  local state = token.session.oldMan or {id = 0}
  return OldMan.render(token.codec, byteString(state.nativeBytes, 64), state, require("src.save_convert.gen3_port.rse").same)
end
local function writeBard(token, words)
  local buf = token.codec.newBuf(64, oldManRaw(token))
  for i = 1, 6 do buf:w16(14 + (i - 1) * 2, words[i]) end
  token.session.oldMan = require("src.save_convert.gen3_port.sections.rs_old_man").read(buf:str(), token.codec)
end
local fields = {[0] = "easyChatProfile", [1] = "easyChatBattleStart", [2] = "easyChatBattleWon", [3] = "easyChatBattleLost"}

function M.prepare(session, kind, vars)
  local descriptor = M.TYPES[kind]
  if not descriptor then return nil end
  vars = vars or {}
  local token = {type = kind, session = session, codec = codecFor(session), descriptor = descriptor,
    wordCount = descriptor.shape.count, columns = descriptor.shape.columns, rows = descriptor.shape.rows,
    variant = 3, slot = vars.slot or 0, person = vars.person or 0}
  local words
  if fields[kind] then
    words = session[fields[kind]]
    if not words then words = M.INITIALIZATION[descriptor.destination] end
  elseif kind == 4 then
    local record = assert(require("src.core.game3.mail").slot(session, token.slot), "RS EasyChat mail index out of range")
    words = record.words
  elseif kind == 6 then
    local raw = oldManRaw(token)
    words = {}
    for i = 1, 6 do words[i] = token.codec.u16(raw, 2 + (i - 1) * 2) end
    writeBard(token, words)
  elseif kind == 9 then
    words = require("src.core.game3.rs.dewford_trend").editorWords(session)
  elseif kind == 10 then
    session.gabbyAndTyData = session.gabbyAndTyData or {}
    session.gabbyAndTyData.quote = session.gabbyAndTyData.quote or {}
    session.gabbyAndTyData.quote[0] = M.EMPTY
    words, token.variant = {M.EMPTY}, 1
  elseif kind == 13 then words = {M.EMPTY, M.EMPTY}
  else
    assert(token.slot >= 0 and token.slot < 25, "RS EasyChat TV slot out of range")
    if kind == 5 then token.offset, token.variant = 4, vars.variant or 0
    elseif kind == 7 then
      assert(token.person >= 0 and token.person < 4, "RS EasyChat opinion index out of range")
      token.offset, token.variant = 28 + token.person * 2, 1
    elseif kind == 8 then token.offset, token.variant = 2, 0
    elseif kind == 11 then
      assert(token.person >= 0 and token.person < 2, "RS EasyChat contest index out of range")
      token.offset, token.variant = 4 + token.person * 2, 0
    elseif kind == 12 then token.offset, token.variant = 24, 1 end
    words = {}
    local raw = rawTv(token)
    for i = 1, token.wordCount do words[i] = token.codec.u16(raw, token.offset + (i - 1) * 2) end
  end
  token.before = copy(words, token.wordCount)
  token.words = copy(words, token.wordCount)
  return token
end

function M.changed(token, words)
  local count = 0
  for i = 1, token.wordCount do
    if Easy.rawWord(token.before[i]) ~= Easy.rawWord(words[i]) then count = count + 1 end
  end
  return count
end
function M.wordBytes(token, word)
  local text = Easy.rawWord(word)
  return token.codec.encodeString(text, #text * 2 + 1, 255):match("^[^\255]*") .. string.char(255)
end
function M.validate(token, words)
  if type(words) ~= "table" then return false, "incomplete" end
  local empty = true
  for i = 1, token.wordCount do
    local word = tonumber(words[i])
    if not word or word % 1 ~= 0 or word < 0 or word > M.EMPTY then return false, "incomplete" end
    if word ~= M.EMPTY then empty = false end
  end
  if empty then return false, "empty" end
  if token.type == 9 then return require("src.core.game3.rs.dewford_trend").editorValid(token.before, words) end
  if token.type == 4 and M.changed(token, words) == 0 then return false, "cancelPrompt" end
  return true
end
function M.passphrase(words)
  for i = 1, 4 do if Easy.rawWord(words[i]) ~= Easy.rawWord(M.MYSTERY[i]) then return false end end
  return true
end
function M.berryPhrase(words)
  local phrase = Easy.rawWord(words[1]) .. " " .. Easy.rawWord(words[2])
  for i, pair in ipairs(M.BERRY_PHRASES) do
    if phrase == Easy.rawWord(pair[1]) .. " " .. Easy.rawWord(pair[2]) then return i end
  end
  return 0
end

function M.commit(token, words)
  local valid, reason = M.validate(token, words)
  if not valid then return nil, reason end
  local out = {result = M.changed(token, words) ~= 0 and 1 or 0}
  if fields[token.type] then
    local target = token.session[fields[token.type]] or {}
    for i = 1, token.wordCount do target[i] = words[i] end
    token.session[fields[token.type]] = target
  elseif token.type == 4 then
    local record = require("src.core.game3.mail").slot(token.session, token.slot)
    record.words = copy(words, 9)
  elseif token.type == 6 then writeBard(token, words)
  elseif token.type == 10 then token.session.gabbyAndTyData.quote[0] = words[1]
  elseif token.type == 9 then
    out.stringVar2 = Easy.rawWord(words[1]) .. " " .. Easy.rawWord(words[2])
    out.input = require("src.core.game3.rs.dewford_trend").trySetTrendyPhrase(words, token.session) and 1 or 0
  elseif token.type ~= 13 then writeTv(token, words) end
  if token.type == 0 then out.input = M.passphrase(words) and 1 or 0 end
  if token.type == 13 then
    out.input = M.berryPhrase(words)
    if words[1] == M.EMPTY or words[2] == M.EMPTY then out.result = 0 end
  end
  token.words = copy(words, token.wordCount)
  token.committed = true
  return out
end
function M.cancel(token)
  token.cancelled = true
  return {result = 0}
end
function M.declineSave(token, words)
  if token.type == 6 and M.changed(token, words) ~= 0 then
    local raw, out = oldManRaw(token), {}
    for i = 1, 6 do out[i] = token.codec.u16(raw, 14 + (i - 1) * 2) end
    return out, M.ERRORS.bardRestore
  end
  return copy(words, token.wordCount)
end
return M
