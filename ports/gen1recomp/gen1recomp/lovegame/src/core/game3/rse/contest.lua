local Ai = require("src.core.game3.rse.contest_ai")

local Contest = {}
Contest.__index = Contest

-- pokeemerald/include/constants/contest.h:4
Contest.APPLAUSE_METER_SIZE = 5
Contest.NUM_APPEALS = 5
Contest.LAST_APPEAL = 4
Contest.CONTESTANT_COUNT = 4
Contest.NONE = 0xFF
Contest.RANK = { NORMAL = 0, SUPER = 1, HYPER = 2, MASTER = 3, LINK = 4 }
Contest.CATEGORY = { COOL = 0, BEAUTY = 1, CUTE = 2, SMART = 3, TOUGH = 4 }
Contest.CATEGORY_NAMES = { [0] = "cool", "beauty", "cute", "smart", "tough" }
Contest.FILTER = { NONE = 0, NO_POSTGAME = 1, ONLY_POSTGAME = 2 }
Contest.CONDITION = { NO_CHANGE = 0, GAIN = 1, LOSE = 2 }
-- pokeemerald/include/contest.h:7
Contest.STRING = {
  MORE_CONSCIOUS = 0, NO_APPEAL = 1, SETTLE_DOWN = 2, OBLIVIOUS_TO_OTHERS = 3, LESS_AWARE = 4,
  STOPPED_CARING = 5, STARTLE_ATTEMPT = 6, DAZZLE_ATTEMPT = 7, JUDGE_LOOK_AWAY2 = 8, UNNERVE_ATTEMPT = 9,
  NERVOUS = 10, UNNERVE_WAITING = 11, TAUNT_WELL = 12, REGAINED_FORM = 13, JAM_WELL = 14,
  HUSTLE_STANDOUT = 15, WORK_HARD_UNNOTICED = 16, WORK_BEFORE = 17, APPEAL_NOT_WELL = 18,
  WORK_PRECEDING = 19, APPEAL_NOT_WELL2 = 20, APPEAL_NOT_SHOWN_WELL = 21, APPEAL_SLIGHTLY_WELL = 22,
  APPEAL_PRETTY_WELL = 23, APPEAL_EXCELLENTLY = 24, APPEAL_DUD = 25, APPEAL_NOT_VERY_WELL = 26,
  APPEAL_SLIGHTLY_WELL2 = 27, APPEAL_PRETTY_WELL2 = 28, APPEAL_VERY_WELL = 29, APPEAL_EXCELLENTLY2 = 30,
  SAME_TYPE_GOOD = 31, DIFF_TYPE_GOOD = 32, STOOD_OUT_AS_MUCH = 33, NOT_AS_WELL = 34, CONDITION_ROSE = 35,
  HOT_STATUS = 36, MOVE_UP_LINE = 37, MOVE_BACK_LINE = 38, SCRAMBLE_ORDER = 39, JUDGE_EXPECTANTLY2 = 40,
  WENT_OVER_WELL = 41, WENT_OVER_VERY_WELL = 42, APPEAL_COMBO_EXCELLENTLY = 43, AVERT_GAZE = 44,
  AVOID_SEEING = 45, NOT_FAZED = 46, LITTLE_DISTRACTED = 47, ATTEMPT_STARTLE = 48, LOOKED_DOWN = 49,
  TURNED_BACK = 50, UTTER_CRY = 51, LEAPT_UP = 52, TRIPPED_OVER = 53, MESSED_UP2 = 54,
  FAILED_TARGET_NERVOUS = 55, FAILED_ANYONE_NERVOUS = 56, IGNORED = 57, NO_CONDITION_IMPROVE = 58,
  BAD_CONDITION_WEAK_APPEAL = 59, UNAFFECTED = 60, ATTRACTED_ATTENTION = 61, NONE = 255,
}
local STR = Contest.STRING
-- pokeemerald/include/constants/contest.h:100
Contest.EFFECT = {
  HIGHLY_APPEALING = 0, USER_MORE_EASILY_STARTLED = 1, GREAT_APPEAL_BUT_NO_MORE_MOVES = 2,
  REPETITION_NOT_BORING = 3, AVOID_STARTLE_ONCE = 4, AVOID_STARTLE = 5, AVOID_STARTLE_SLIGHTLY = 6,
  USER_LESS_EASILY_STARTLED = 7, STARTLE_FRONT_MON = 8, SLIGHTLY_STARTLE_PREV_MONS = 9, STARTLE_PREV_MON = 10,
  STARTLE_PREV_MONS = 11, BADLY_STARTLE_FRONT_MON = 12, BADLY_STARTLE_PREV_MONS = 13, STARTLE_PREV_MON_2 = 14,
  STARTLE_PREV_MONS_2 = 15, SHIFT_JUDGE_ATTENTION = 16, STARTLE_MON_WITH_JUDGES_ATTENTION = 17,
  JAMS_OTHERS_BUT_MISS_ONE_TURN = 18, STARTLE_MONS_SAME_TYPE_APPEAL = 19, STARTLE_MONS_COOL_APPEAL = 20,
  STARTLE_MONS_BEAUTY_APPEAL = 21, STARTLE_MONS_CUTE_APPEAL = 22, STARTLE_MONS_SMART_APPEAL = 23,
  STARTLE_MONS_TOUGH_APPEAL = 24, MAKE_FOLLOWING_MON_NERVOUS = 25, MAKE_FOLLOWING_MONS_NERVOUS = 26,
  WORSEN_CONDITION_OF_PREV_MONS = 27, BADLY_STARTLES_MONS_IN_GOOD_CONDITION = 28, BETTER_IF_FIRST = 29,
  BETTER_IF_LAST = 30, APPEAL_AS_GOOD_AS_PREV_ONES = 31, APPEAL_AS_GOOD_AS_PREV_ONE = 32,
  BETTER_WHEN_LATER = 33, QUALITY_DEPENDS_ON_TIMING = 34, BETTER_IF_SAME_TYPE = 35, BETTER_IF_DIFF_TYPE = 36,
  AFFECTED_BY_PREV_APPEAL = 37, IMPROVE_CONDITION_PREVENT_NERVOUSNESS = 38, BETTER_WITH_GOOD_CONDITION = 39,
  NEXT_APPEAL_EARLIER = 40, NEXT_APPEAL_LATER = 41, MAKE_SCRAMBLING_TURN_ORDER_EASIER = 42,
  SCRAMBLE_NEXT_TURN_ORDER = 43, EXCITE_AUDIENCE_IN_ANY_CONTEST = 44, BADLY_STARTLE_MONS_WITH_GOOD_APPEALS = 45,
  BETTER_WHEN_AUDIENCE_EXCITED = 46, DONT_EXCITE_AUDIENCE = 47,
}
-- pokeemerald/include/constants/tv.h:209
Contest.LIVE = {
  EXCITING_APPEAL = 0x1, GOT_NERVOUS = 0x2, MAXED_EXCITEMENT = 0x4, USED_COMBO = 0x8,
  STARTLED_OTHER = 0x10, SKIPPED_TURN = 0x20, GOT_STARTLED = 0x40, MADE_APPEAL = 0x80,
}
-- pokeemerald/include/constants/tv.h:219
Contest.LIVE_LOSER = {
  LOST = 0x1, REPEATED_MOVE = 0x2, LOST_SMALL_MARGIN = 0x4, NO_EXCITEMENT = 0x8, BLEW_LEAD = 0x10,
  MISSED_EXCITEMENT = 0x20, LAST_BOTH_ROUNDS = 0x40, NO_APPEALS = 0x80,
}
-- pokeemerald/src/contest.c:214
Contest.JUDGE = {
  SWIRL = 0, SWIRL_UNUSED = 1, ONE_EXCLAMATION = 2, TWO_EXCLAMATIONS = 3, NUMBER_ONE_UNUSED = 4, NUMBER_ONE = 5,
  NUMBER_FOUR = 6, QUESTION_MARK = 7, STAR = 8,
}

Contest.REL_MOVES = "pokemon/contest_moves.lua"
Contest.REL_MANIFEST = "rse/contest/manifest.lua"

local N = Contest.CONTESTANT_COUNT
local NONE = Contest.NONE

local function s16(v)
  v = math.floor(v) % 65536
  return v >= 32768 and v - 65536 or v
end
local function s8(v)
  v = math.floor(v) % 256
  return v >= 128 and v - 256 or v
end
local function u8(v) return math.floor(v) % 256 end
local function u16(v) return math.floor(v) % 65536 end
local function bits(v, n) return math.floor(v) % (2 ^ n) end
local function tdiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or -math.floor(-q)
end
Contest.s16, Contest.s8, Contest.u8 = s16, s8, u8

local dataCache, dataRoot

local function cacheRoot()
  return require("src.core.game3.cache_paths").CACHE_ROOT
end

local function readLua(rel)
  local cache = require("src.core.game3.dataset").cache()
  local src = cache and cache:read(cacheRoot() .. "/" .. rel)
  if not src then return nil end
  local chunk = load(src, "@" .. rel, "t", {})
  if not chunk then return nil end
  local ok, t = pcall(chunk)
  return ok and t or nil
end

function Contest.buildData(moves, manifest)
  local d = {
    moves = moves.moves,
    effects = moves.effects,
    manifest = manifest,
    opponents = manifest.opponents,
    opponentCount = manifest.opponentCount,
    postgameFilter = manifest.postgameFilter,
    comboLookup = manifest.comboStarterLookup,
    excitement = manifest.excitementTable,
  }
  d.aiScript = Ai.script(manifest.ai)
  return d
end

function Contest.data()
  if dataCache and dataRoot == cacheRoot() then return dataCache end
  local moves = assert(readLua(Contest.REL_MOVES), "contest moves are not in the cache")
  local manifest = assert(readLua(Contest.REL_MANIFEST), "contest manifest is not in the cache")
  if manifest.assetLayout == "rs" then
    local native = assert(readLua("rse/contest_data/manifest.lua"), "RS contest data is not in the cache")
    assert(native.assetLayout == "rs", "RS contest data layout")
    local merged = {}
    for k, v in pairs(manifest) do merged[k] = v end
    for k, v in pairs(native) do merged[k] = v end
    manifest = merged
  end
  dataCache, dataRoot = Contest.buildData(moves, manifest), cacheRoot()
  return dataCache
end

function Contest.reset()
  dataCache, dataRoot = nil, nil
end

local function newStatus()
  return {
    baseAppeal = 0, appeal = 0, pointTotal = 0, currMove = 0, prevMove = 0, moveCategory = 0,
    ranking = 0, moveRepeatCount = 0, noMoreTurns = 0, nervous = 0, numTurnsSkipped = 0,
    condition = 0, jam = 0, jamReduction = 0, resistant = 0, immune = 0, moreEasilyStartled = 0,
    usedRepeatableMove = 0, conditionMod = 0, turnOrderMod = 0, turnOrderModAction = 0,
    turnSkipped = 0, exploded = 0, overrideCategoryExcitementMod = 0, appealTripleCondition = 0,
    jamSafetyCount = 0, effectStringId = 0, effectStringId2 = 0, repeatedMove = 0,
    repeatedPrevMove = 0, completedComboFlag = 0, hasJudgesAttention = 0, judgesAttentionWasRemoved = 0,
    usedComboMove = 0, completedCombo = 0, comboAppealBonus = 0, repeatJam = 0, nextTurnOrder = 0,
    attentionLevel = 0, contestantAnimTarget = 0,
  }
end
Contest.newStatus = newStatus

local function zero4(v)
  return { [0] = v or 0, v or 0, v or 0, v or 0 }
end

local function newContestState()
  local mh, eh = {}, {}
  for r = 0, Contest.NUM_APPEALS - 1 do mh[r] = zero4(); eh[r] = zero4() end
  return {
    playerMoveChoice = 0, appealNumber = 0, turnNumber = 0, currentContestant = 0, applauseLevel = 0,
    prevTurnOrder = zero4(), moveHistory = mh, excitementHistory = eh,
  }
end

local function newTv()
  return { appeals = { [0] = 0, 0, 0, 0, 0 }, move = 0, winnerFlags = 0, loserFlags = 0, madeAppeal = 0,
    madeExcitingAppeal = 0 }
end

function Contest.new(opts)
  opts = opts or {}
  local c = setmetatable({}, Contest)
  c.data = opts.data or Contest.data()
  c.aiScript = c.data.aiScript
  c.category = opts.category or 0
  c.rank = opts.rank or 0
  c.linkFlags = opts.linkFlags or 0
  c.rng = opts.rng or function() return require("src.core.game3.rng").Random() end
  c.uninit = opts.uninit
  c.nativeContestRam, c.nativeContestGfx, c.nativeContestMoveAnim =
    opts.nativeContestRam, opts.nativeContestGfx, opts.nativeContestMoveAnim
  c.playerIndex = opts.playerIndex or (N - 1)
  c.mons = { [0] = false, false, false, false }
  c.round1, c.totals, c.appealTotals, c.round2 = zero4(), zero4(), zero4(), zero4()
  c.standings = zero4()
  c.turnOrder = zero4()
  c.contest = newContestState()
  c.status = { [0] = newStatus(), newStatus(), newStatus(), newStatus() }
  c.results = { turnOrder = zero4(), jam = 0, jam2 = 0, jamQueue = { [0] = 0, 0, 0, 0, 0 },
    unnervedPokes = zero4(), contestant = 0 }
  c.excitement = { moveExcitement = 0, frozen = 0, freezer = 0, excitementAppealBonus = 0 }
  c.tv = { [0] = newTv(), newTv(), newTv(), newTv() }
  return c
end

function Contest:random()
  return u16(self.rng())
end

function Contest:isLink()
  return self.linkFlags % 2 == 1
end

-- pokeemerald/src/contest.c:4748
function Contest:moveExcitement(move)
  return self.data.excitement[self.category][self.data.moves[move].category]
end

-- pokeemerald/src/contest_effect.c:60
function Contest:areMovesCombo(lastMove, nextMove)
  local starter = self.data.moves[lastMove].comboStarterId
  local combo = self.data.moves[nextMove].comboMoves
  if starter == 0 then return 0 end
  if starter == combo[1] or starter == combo[2] or starter == combo[3] or starter == combo[4] then
    return self.data.comboLookup[starter]
  end
  return 0
end

-- pokeemerald/src/contest.c:5057
function Contest:isAllowedToCombo(i)
  local st = self.status[i]
  return not (st.repeatedMove ~= 0 or st.nervous ~= 0)
end

-- pokeemerald/src/contest.c:3543
function Contest:isTurnDisabled(i)
  local st = self.status[i]
  return st.numTurnsSkipped ~= 0 or st.noMoreTurns ~= 0
end

function Contest:historyMove(round, i)
  local row = self.contest.moveHistory[round]
  return row and row[i] or 0
end

function Contest:historyExcitement(round, i)
  local row = self.contest.excitementHistory[round]
  return row and row[i] or 0
end

-- pokeemerald/src/contest.c:1123
Contest.HEAP = {
  aiSize = 0x44, excitement = 0x54, gfxState = 0x74, moveAnim = 0x94, tv = 0xB8, unused = 0x108,
  tilemap0 = 0x124,
  words = { [0x42] = 0x0000, [0x6A] = 0x0000, [0x80] = 0x0804, [0x92] = 0x0200, [0x114] = 0x0001, [0x118] = 0x1000 },
}

function Contest:uninitVar(idx)
  if self.uninit then return s16(self.uninit(idx, self)) end
  if self.data and self.data.manifest and self.data.manifest.assetLayout == "rs" then
    return require("src.core.game3.rs.contest_memory").uninitVar(self, idx)
  end
  local off = 0x1A + idx * 2
  local H = Contest.HEAP
  local w = H.words[off]
  if w then return s16(w) end
  if off >= H.tv and off < H.tv + 64 then
    local t = self.tv[math.floor((off - H.tv) / 16)]
    local rel = (off - H.tv) % 16
    if rel < 10 then return s16(t.appeals[rel / 2] or 0) end
    if rel == 10 then return s16(t.move) end
    return 0
  end
  return 0
end

-- pokeemerald/src/contest.c:2852
function Contest:setContestants(opts)
  opts = opts or {}
  if not self:isLink() then self.playerIndex = N - 1 end
  local allowPostgame = opts.gameClear == true and not self:isLink()
  local list, count = {}, 0
  local d = self.data
  for i = 0, d.opponentCount - 1 do
    local o = d.opponents[i]
    if self.rank == o.whichRank then
      local f = d.postgameFilter[i]
      local skip
      if allowPostgame then skip = f == Contest.FILTER.NO_POSTGAME else skip = f == Contest.FILTER.ONLY_POSTGAME end
      if not skip and o.aiPool[Contest.CATEGORY_NAMES[self.category]] then
        list[count] = i
        count = count + 1
      end
    end
  end
  list[count] = NONE
  self.opponentIds = {}
  for i = 0, N - 2 do
    local rnd = self:random() % count
    self.opponentIds[i] = list[rnd]
    self.mons[i] = Contest.copyMon(d.opponents[list[rnd]])
    local j = rnd
    while list[j] ~= NONE do
      list[j] = list[j + 1]
      j = j + 1
    end
    count = count - 1
  end
  if opts.player then self:createPlayerMon(opts.player) end
end

function Contest.copyMon(o)
  local m = {}
  for k, v in pairs(o) do
    if type(v) == "table" then
      local t = {}
      for k2, v2 in pairs(v) do t[k2] = v2 end
      m[k] = t
    else
      m[k] = v
    end
  end
  if o.moves and o.moves[0] == nil then
    m.moves = { [0] = o.moves[1] or 0, o.moves[2] or 0, o.moves[3] or 0, o.moves[4] or 0 }
  end
  return m
end

-- pokeemerald/src/contest.c:2825
Contest.SCARVES = { [0] = "ITEM_RED_SCARF", "ITEM_BLUE_SCARF", "ITEM_PINK_SCARF", "ITEM_GREEN_SCARF", "ITEM_YELLOW_SCARF" }

-- pokeemerald/src/contest.c:2777
function Contest.buildContestMon(p)
  local m = {
    trainerName = p.trainerName, trainerGfxId = p.trainerGfxId or 0, aiFlags = 0, highestRank = 0,
    species = p.species or 0, nickname = p.nickname, isPlayer = true,
    moves = { [0] = p.moves[1] or 0, p.moves[2] or 0, p.moves[3] or 0, p.moves[4] or 0 },
    personality = p.personality or 0, otId = p.otId or 0, sheen = p.sheen or 0,
  }
  local stats = { cool = p.cool or 0, beauty = p.beauty or 0, cute = p.cute or 0, smart = p.smart or 0,
    tough = p.tough or 0 }
  local scarf = p.scarfCategory
  if scarf ~= nil then
    local key = Contest.CATEGORY_NAMES[scarf]
    stats[key] = stats[key] + 20
  end
  for k, v in pairs(stats) do m[k] = v > 255 and 255 or v end
  return m
end

function Contest:createPlayerMon(p)
  local m = Contest.buildContestMon(p)
  self.mons[self.playerIndex] = m
  return m
end

-- pokeemerald/src/contest.c:2910
function Contest:setLinkAIContestants(numPlayers, rank, gameCleared, rand)
  if numPlayers >= N then return end
  local d = self.data
  local list, count = {}, 0
  for i = 0, d.opponentCount - 1 do
    local o = d.opponents[i]
    if rank == o.whichRank then
      local f = d.postgameFilter[i]
      local skip
      if gameCleared == true then skip = f == Contest.FILTER.NO_POSTGAME else skip = f == Contest.FILTER.ONLY_POSTGAME end
      if not skip and o.aiPool[Contest.CATEGORY_NAMES[self.category]] then
        list[count] = i
        count = count + 1
      end
    end
  end
  list[count] = NONE
  self.opponentIds = self.opponentIds or {}
  for i = 0, N - numPlayers - 1 do
    local rnd = rand() % count
    self.opponentIds[numPlayers + i] = list[rnd]
    self.mons[numPlayers + i] = Contest.copyMon(d.opponents[list[rnd]])
    local j = rnd
    while list[j] ~= NONE do
      list[j] = list[j + 1]
      j = j + 1
    end
    count = count - 1
  end
end

-- pokeemerald/src/contest.c:3051
local ROUND1 = {
  [0] = { "cool", "tough", "beauty" }, { "beauty", "cool", "cute" }, { "cute", "beauty", "smart" },
  { "smart", "cute", "tough" }, { "tough", "smart", "cool" },
}
function Contest:round1Points(who)
  local m = self.mons[who]
  local k = ROUND1[self.category] or ROUND1[4]
  return u16(m[k[1]] + math.floor((m[k[2]] + m[k[3]] + m.sheen) / 2))
end

-- pokeemerald/src/contest.c:3089
function Contest:calculateRound1Points()
  for i = 0, N - 1 do self.round1[i] = s16(self:round1Points(i)) end
end

local function uniqueRandoms(c)
  local r = zero4()
  local i = 0
  while i < N do
    r[i] = c:random()
    local dup = false
    for j = 0, i - 1 do
      if r[i] == r[j] then dup = true; break end
    end
    if not dup then i = i + 1 end
  end
  return r
end

-- pokeemerald/src/contest.c:4298
function Contest:sortContestants(useRanking)
  local rnd = uniqueRandoms(self)
  local order = self.turnOrder
  if not useRanking then
    for i = 0, N - 1 do
      order[i] = i
      local v3 = 0
      while v3 < i do
        local o = order[v3]
        if self.round1[o] < self.round1[i] or (self.round1[o] == self.round1[i] and rnd[o] < rnd[i]) then
          for j = i, v3 + 1, -1 do order[j] = order[j - 1] end
          order[v3] = i
          break
        end
        v3 = v3 + 1
      end
      if v3 == i then order[i] = i end
    end
    local scratch = zero4()
    for i = 0, N - 1 do scratch[i] = order[i] end
    for i = 0, N - 1 do order[scratch[i]] = i end
  else
    local scratch = zero4(NONE)
    for i = 0, N - 1 do
      local j = self.status[i].ranking
      while true do
        if scratch[j] == NONE then
          scratch[j] = i
          order[i] = j
          break
        end
        j = j + 1
      end
    end
    for i = 0, N - 2 do
      for v3 = N - 1, i + 1, -1 do
        if self.status[v3 - 1].ranking == self.status[v3].ranking
          and order[v3 - 1] < order[v3] and rnd[v3 - 1] < rnd[v3] then
          order[v3], order[v3 - 1] = order[v3 - 1], order[v3]
        end
      end
    end
  end
end

-- pokeemerald/src/contest.c:4602
function Contest:applyNextTurnOrder()
  local nextContestant = 0
  local newOrder, ordered = zero4(), {}
  for i = 0, N - 1 do newOrder[i] = self.turnOrder[i]; ordered[i] = false end
  for i = 0, N - 1 do
    local j = 0
    while j < N do
      if self.status[j].nextTurnOrder == i then
        newOrder[j] = i
        ordered[j] = true
        break
      end
      j = j + 1
    end
    if j == N then
      j = 0
      while j < N do
        if not ordered[j] and self.status[j].nextTurnOrder == NONE then
          nextContestant = j
          j = j + 1
          break
        end
        j = j + 1
      end
      while j < N do
        if not ordered[j] and self.status[j].nextTurnOrder == NONE
          and self.turnOrder[nextContestant] > self.turnOrder[j] then
          nextContestant = j
        end
        j = j + 1
      end
      newOrder[nextContestant] = i
      ordered[nextContestant] = true
    end
  end
  for i = 0, N - 1 do
    self.results.turnOrder[i] = newOrder[i]
    self.status[i].nextTurnOrder = NONE
    self.status[i].turnOrderMod = 0
    self.turnOrder[i] = newOrder[i]
  end
end

-- pokeemerald/src/contest.c:1085
function Contest:init()
  self.contest = newContestState()
  for i = 0, N - 1 do
    self.status[i] = newStatus()
    self.status[i].effectStringId = STR.NONE
    self.status[i].effectStringId2 = STR.NONE
  end
  self.results = { turnOrder = zero4(), jam = 0, jam2 = 0, jamQueue = { [0] = 0, 0, 0, 0, 0 },
    unnervedPokes = zero4(), contestant = 0 }
  self.excitement = { moveExcitement = 0, frozen = 0, freezer = 0, excitementAppealBonus = 0 }
  if not self:isLink() then self:sortContestants(false) end
  for i = 0, N - 1 do
    self.status[i].nextTurnOrder = NONE
    self.contest.prevTurnOrder[i] = self.turnOrder[i]
  end
  self:applyNextTurnOrder()
  self.tv = { [0] = newTv(), newTv(), newTv(), newTv() }
end

-- pokeemerald/src/contest.c:3388
function Contest:chosenMove(i)
  if self:isTurnDisabled(i) then return 0 end
  if i == self.playerIndex then
    return self.mons[i].moves[self.contest.playerMoveChoice] or 0
  end
  Ai.reset(self, i)
  local choice = Ai.getActionToUse(self)
  self.lastAiChoice = self.lastAiChoice or {}
  self.lastAiChoice[i] = { index = choice, scores = self.ai.moveScores }
  return self.mons[i].moves[choice] or 0
end

-- pokeemerald/src/contest.c:3406
function Contest:chooseMoves(playerMoveChoice)
  if playerMoveChoice ~= nil then self.contest.playerMoveChoice = playerMoveChoice end
  local linked = self.linkMoves
  for i = 0, N - 1 do
    if linked and linked[i] ~= nil then
      -- pokeemerald/src/contest_link.c:295
      self.status[i].currMove = self:isTurnDisabled(i) and 0 or (tonumber(linked[i]) or 0)
    else
      self.status[i].currMove = self:chosenMove(i)
    end
  end
end

local E = {}
Contest.EFFECT_FUNCS = E

local function setStr(c, i, id) c.status[i].effectStringId = id end
local function setStr2(c, i, id) c.status[i].effectStringId2 = id end
Contest.setEffectString = setStr

-- pokeemerald/src/contest.c:4553
local function setStartledString(c, i, jam)
  if jam >= 60 then setStr(c, i, STR.TRIPPED_OVER)
  elseif jam >= 40 then setStr(c, i, STR.LEAPT_UP)
  elseif jam >= 30 then setStr(c, i, STR.UTTER_CRY)
  elseif jam >= 20 then setStr(c, i, STR.TURNED_BACK)
  elseif jam >= 10 then setStr(c, i, STR.LOOKED_DOWN) end
end

-- pokeemerald/src/contest.c:4586
local function makeNervous(c, i)
  c.status[i].nervous = 1
  c.status[i].currMove = 0
end

-- pokeemerald/src/contest_effect.c:260
local function canUnnerve(c, i)
  c.results.unnervedPokes[i] = 1
  local st = c.status[i]
  if st.immune ~= 0 then
    setStr(c, i, STR.AVOID_SEEING)
    return false
  elseif st.jamSafetyCount ~= 0 then
    st.jamSafetyCount = u8(st.jamSafetyCount - 1)
    setStr(c, i, STR.AVERT_GAZE)
    return false
  elseif st.noMoreTurns == 0 and st.numTurnsSkipped == 0 then
    return true
  end
  return false
end

-- pokeemerald/src/contest_effect.c:1066
local function jamContestant(c, i, jam)
  jam = u8(jam)
  local st = c.status[i]
  st.appeal = s16(st.appeal - jam)
  st.jam = u8(st.jam + jam)
end

-- pokeemerald/src/contest_effect.c:1022
local function wasAnyJammed(c)
  local buf = zero4()
  local r = c.results
  local i = 0
  while r.jamQueue[i] ~= NONE do
    local who = r.jamQueue[i]
    if canUnnerve(c, who) then
      local st = c.status[who]
      r.jam2 = r.jam
      if st.moreEasilyStartled ~= 0 then r.jam2 = s16(r.jam2 * 2) end
      if st.resistant ~= 0 then
        r.jam2 = 10
        setStr(c, who, STR.LITTLE_DISTRACTED)
      else
        r.jam2 = s16(r.jam2 - st.jamReduction)
        if r.jam2 <= 0 then
          r.jam2 = 0
          setStr(c, who, STR.NOT_FAZED)
        else
          jamContestant(c, who, r.jam2)
          setStartledString(c, who, u8(r.jam2))
          buf[who] = r.jam2
        end
      end
    end
    i = i + 1
  end
  for k = 0, N - 1 do
    if buf[k] ~= 0 then return true end
  end
  return false
end

-- pokeemerald/src/contest_effect.c:1072
local function roundTowardsZero(score)
  local a = math.abs(score) % 10
  if score < 0 then
    if a ~= 0 then score = score - (10 - a) end
  else
    score = score - a
  end
  return s16(score)
end
-- pokeemerald/src/contest_effect.c:1087
local function roundUp(score)
  local a = math.abs(score) % 10
  if a ~= 0 then score = score + (10 - a) end
  return s16(score)
end

local function me(c) return c.results.contestant end
local function order(c, i) return c.results.turnOrder[i] end

E[0] = function() end
E[1] = function(c)
  c.status[me(c)].moreEasilyStartled = 1
  setStr(c, me(c), STR.MORE_CONSCIOUS)
end
E[2] = function(c)
  c.status[me(c)].exploded = 1
  setStr(c, me(c), STR.NO_APPEAL)
end
E[3] = function(c)
  local st = c.status[me(c)]
  st.usedRepeatableMove = 1
  st.repeatedMove = 0
  st.moveRepeatCount = 0
end
E[4] = function(c)
  c.status[me(c)].jamSafetyCount = 1
  setStr(c, me(c), STR.SETTLE_DOWN)
end
E[5] = function(c)
  c.status[me(c)].immune = 1
  setStr(c, me(c), STR.OBLIVIOUS_TO_OTHERS)
end
E[6] = function(c)
  c.status[me(c)].jamReduction = 20
  setStr(c, me(c), STR.LESS_AWARE)
end
E[7] = function(c)
  c.status[me(c)].resistant = 1
  setStr(c, me(c), STR.STOPPED_CARING)
end

-- pokeemerald/src/contest_effect.c:136
local function startleFrontMon(c)
  local idx = false
  local a = me(c)
  if order(c, a) ~= 0 then
    local i = 0
    while i < N do
      if order(c, a) - 1 == order(c, i) then break end
      i = i + 1
    end
    c.results.jamQueue[0] = i
    c.results.jamQueue[1] = NONE
    idx = wasAnyJammed(c)
  end
  if not idx then setStr2(c, me(c), STR.MESSED_UP2) end
  setStr(c, me(c), STR.ATTEMPT_STARTLE)
end

-- pokeemerald/src/contest_effect.c:160
local function startlePrevMons(c)
  local idx = false
  local a = me(c)
  if order(c, a) ~= 0 then
    local j = 0
    for i = 0, N - 1 do
      if order(c, a) > order(c, i) then
        c.results.jamQueue[j] = i
        j = j + 1
      end
    end
    c.results.jamQueue[j] = NONE
    idx = wasAnyJammed(c)
  end
  if not idx then setStr2(c, me(c), STR.MESSED_UP2) end
  setStr(c, me(c), STR.ATTEMPT_STARTLE)
end

E[8], E[9], E[10], E[11], E[12], E[13] =
  startleFrontMon, startlePrevMons, startleFrontMon, startlePrevMons, startleFrontMon, startlePrevMons

-- pokeemerald/src/contest_effect.c:184
E[14] = function(c)
  local rval = c:random() % 10
  local jam
  if rval < 2 then jam = 20 elseif rval < 8 then jam = 40 else jam = 60 end
  c.results.jam = jam
  startleFrontMon(c)
end

-- pokeemerald/src/contest_effect.c:201
E[15] = function(c)
  local numStartled = 0
  local a = me(c)
  if order(c, a) ~= 0 then
    for i = 0, 3 do
      if order(c, a) > order(c, i) then
        c.results.jamQueue[0] = i
        c.results.jamQueue[1] = NONE
        local rval = c:random() % 10
        local jam
        if rval == 0 then jam = 0
        elseif rval <= 2 then jam = 10
        elseif rval <= 4 then jam = 20
        elseif rval <= 6 then jam = 30
        elseif rval <= 8 then jam = 40
        else jam = 60 end
        c.results.jam = jam
        if wasAnyJammed(c) then numStartled = numStartled + 1 end
      end
    end
  end
  setStr(c, me(c), STR.ATTEMPT_STARTLE)
  if numStartled == 0 then setStr2(c, me(c), STR.MESSED_UP2) end
end

-- pokeemerald/src/contest_effect.c:247
E[16] = function(c)
  local hit = false
  local a = me(c)
  if order(c, a) ~= 0 then
    for i = 0, 3 do
      local st = c.status[i]
      if order(c, a) > order(c, i) and st.hasJudgesAttention ~= 0 and canUnnerve(c, i) then
        st.hasJudgesAttention = 0
        st.judgesAttentionWasRemoved = 1
        setStr(c, i, STR.JUDGE_LOOK_AWAY2)
        hit = true
      end
    end
  end
  setStr(c, me(c), STR.DAZZLE_ATTEMPT)
  if not hit then setStr2(c, me(c), STR.MESSED_UP2) end
end

-- pokeemerald/src/contest_effect.c:277
E[17] = function(c)
  local numStartled = 0
  local a = me(c)
  if order(c, a) ~= 0 then
    for i = 0, 3 do
      if order(c, a) > order(c, i) then
        c.results.jam = c.status[i].hasJudgesAttention ~= 0 and 50 or 10
        c.results.jamQueue[0] = i
        c.results.jamQueue[1] = NONE
        if wasAnyJammed(c) then numStartled = numStartled + 1 end
      end
    end
  end
  setStr(c, me(c), STR.ATTEMPT_STARTLE)
  if numStartled == 0 then setStr2(c, me(c), STR.MESSED_UP2) end
end

-- pokeemerald/src/contest_effect.c:307
E[18] = function(c)
  c.status[me(c)].turnSkipped = 1
  startlePrevMons(c)
  setStr(c, me(c), STR.ATTEMPT_STARTLE)
end

-- pokeemerald/src/contest_effect.c:974
local function jamByCategory(c, category)
  local numJammed = 0
  local a = me(c)
  for i = 0, N - 1 do
    if order(c, a) > order(c, i) then
      if category == c.data.moves[c.status[i].currMove].category then c.results.jam = 40 else c.results.jam = 10 end
      c.results.jamQueue[0] = i
      c.results.jamQueue[1] = NONE
      if wasAnyJammed(c) then numJammed = numJammed + 1 end
    end
  end
  if numJammed == 0 then setStr2(c, me(c), STR.MESSED_UP2) end
end

E[19] = function(c)
  jamByCategory(c, c.data.moves[c.status[me(c)].currMove].category)
  setStr(c, me(c), STR.ATTEMPT_STARTLE)
end
for k = 0, 4 do
  E[20 + k] = function(c)
    jamByCategory(c, k)
    setStr(c, me(c), STR.ATTEMPT_STARTLE)
  end
end

-- pokeemerald/src/contest_effect.c:358
E[25] = function(c)
  local hit = false
  local a = me(c)
  if order(c, a) ~= 3 then
    for i = 0, 3 do
      if order(c, a) + 1 == order(c, i) then
        if canUnnerve(c, i) then
          makeNervous(c, i)
          setStr(c, i, STR.NERVOUS)
        else
          setStr(c, i, STR.UNAFFECTED)
        end
        hit = true
      end
    end
  end
  setStr(c, me(c), STR.UNNERVE_ATTEMPT)
  if not hit then setStr2(c, me(c), STR.MESSED_UP2) end
end

-- pokeemerald/src/contest_effect.c:390
E[26] = function(c)
  local numUnnerved = 0
  local ids = { [0] = NONE, NONE, NONE, NONE, NONE }
  local a = me(c)
  local numAfter = 0
  for i = 0, N - 1 do
    if order(c, a) < order(c, i) and c.status[i].nervous == 0 and not c:isTurnDisabled(i) then
      ids[numAfter] = i
      numAfter = numAfter + 1
    end
  end
  local odds = zero4()
  if numAfter == 1 then odds[0] = 60
  elseif numAfter == 2 then odds[0], odds[1] = 30, 30
  elseif numAfter == 3 then odds[0], odds[1], odds[2] = 20, 20, 20 end
  local mod = zero4()
  for i = 0, N - 1 do
    local st = c.status[i]
    if st.hasJudgesAttention ~= 0 and c:isAllowedToCombo(i) then
      mod[i] = c.data.comboLookup[c.data.moves[st.prevMove].comboStarterId] * 10
    else
      mod[i] = 0
    end
    mod[i] = mod[i] - tdiv(st.condition, 10) * 10
  end
  if odds[0] ~= 0 then
    local i = 0
    while ids[i] ~= NONE do
      local unaffected = false
      if c:random() % 100 < odds[i] + mod[ids[i]] then
        if canUnnerve(c, ids[i]) then
          makeNervous(c, ids[i])
          setStr(c, ids[i], STR.NERVOUS)
          numUnnerved = numUnnerved + 1
        else
          unaffected = true
        end
      else
        unaffected = true
      end
      if unaffected then
        setStr(c, ids[i], STR.UNAFFECTED)
        numUnnerved = numUnnerved + 1
      end
      c.results.unnervedPokes[ids[i]] = 1
      i = i + 1
    end
  end
  setStr(c, me(c), STR.UNNERVE_WAITING)
  if numUnnerved == 0 then setStr2(c, me(c), STR.MESSED_UP2) end
end

-- pokeemerald/src/contest_effect.c:473
E[27] = function(c)
  local numHit = 0
  local a = me(c)
  for i = 0, N - 1 do
    local st = c.status[i]
    if order(c, a) > order(c, i) and st.condition > 0 and canUnnerve(c, i) then
      st.condition = 0
      st.conditionMod = Contest.CONDITION.LOSE
      setStr(c, i, STR.REGAINED_FORM)
      numHit = numHit + 1
    end
  end
  setStr(c, me(c), STR.TAUNT_WELL)
  if numHit == 0 then setStr2(c, me(c), STR.IGNORED) end
end

-- pokeemerald/src/contest_effect.c:497
E[28] = function(c)
  local numHit = 0
  local a = me(c)
  for i = 0, N - 1 do
    if order(c, a) > order(c, i) then
      c.results.jam = c.status[i].condition > 0 and 40 or 10
      c.results.jamQueue[0] = i
      c.results.jamQueue[1] = NONE
      if wasAnyJammed(c) then numHit = numHit + 1 end
    end
  end
  setStr(c, me(c), STR.JAM_WELL)
  if numHit == 0 then setStr2(c, me(c), STR.IGNORED) end
end

local function moveAppeal(c, move)
  return c.data.effects[c.data.moves[move].effect].appeal
end

-- pokeemerald/src/contest_effect.c:522
E[29] = function(c)
  if c.turnOrder[me(c)] == 0 then
    local st = c.status[me(c)]
    st.appeal = s16(st.appeal + 2 * moveAppeal(c, st.currMove))
    setStr(c, me(c), STR.HUSTLE_STANDOUT)
  end
end
-- pokeemerald/src/contest_effect.c:533
E[30] = function(c)
  if c.turnOrder[me(c)] == 3 then
    local st = c.status[me(c)]
    st.appeal = s16(st.appeal + 2 * moveAppeal(c, st.currMove))
    setStr(c, me(c), STR.WORK_HARD_UNNOTICED)
  end
end

-- pokeemerald/src/contest_effect.c:544
E[31] = function(c)
  local sum = 0
  local a = me(c)
  for i = 0, N - 1 do
    if order(c, a) > order(c, i) then sum = sum + c.status[i].appeal end
  end
  if sum < 0 then sum = 0 end
  local st = c.status[a]
  if order(c, a) == 0 or sum == 0 then
    setStr(c, a, STR.APPEAL_NOT_WELL)
  else
    st.appeal = s16(st.appeal + tdiv(sum, 2))
    setStr(c, a, STR.WORK_BEFORE)
  end
  st.appeal = roundTowardsZero(st.appeal)
end

-- pokeemerald/src/contest_effect.c:570
E[32] = function(c)
  local appeal = 0
  local a = me(c)
  if order(c, a) ~= 0 then
    for i = 0, N - 1 do
      if order(c, a) - 1 == order(c, i) then appeal = c.status[i].appeal end
    end
  end
  if order(c, a) == 0 or appeal <= 0 then
    setStr(c, a, STR.APPEAL_NOT_WELL2)
  else
    c.status[a].appeal = s16(c.status[a].appeal + appeal)
    setStr(c, a, STR.WORK_PRECEDING)
  end
end

-- pokeemerald/src/contest_effect.c:595
E[33] = function(c)
  local a = me(c)
  local whichTurn = order(c, a)
  if whichTurn == 0 then c.status[a].appeal = 10 else c.status[a].appeal = s16(20 * whichTurn) end
  if whichTurn == 0 then setStr(c, a, STR.APPEAL_NOT_SHOWN_WELL)
  elseif whichTurn == 1 then setStr(c, a, STR.APPEAL_SLIGHTLY_WELL)
  elseif whichTurn == 2 then setStr(c, a, STR.APPEAL_PRETTY_WELL)
  else setStr(c, a, STR.APPEAL_EXCELLENTLY) end
end

-- pokeemerald/src/contest_effect.c:613
E[34] = function(c)
  local rval = c:random() % 10
  local a = me(c)
  local appeal
  if rval < 3 then appeal = 10; setStr(c, a, STR.APPEAL_NOT_VERY_WELL)
  elseif rval < 6 then appeal = 20; setStr(c, a, STR.APPEAL_SLIGHTLY_WELL2)
  elseif rval < 8 then appeal = 40; setStr(c, a, STR.APPEAL_PRETTY_WELL2)
  elseif rval < 9 then appeal = 60; setStr(c, a, STR.APPEAL_VERY_WELL)
  else appeal = 80; setStr(c, a, STR.APPEAL_EXCELLENTLY2) end
  c.status[a].appeal = appeal
end

-- pokeemerald/src/contest_effect.c:646
E[35] = function(c)
  local a = me(c)
  local turn = s8(order(c, a))
  local i = s8(turn - 1)
  if turn == 0 then return end
  local j
  while true do
    j = 0
    while j < N do
      if order(c, j) == u8(i) then break end
      j = j + 1
    end
    local st = c.status[j]
    if st.noMoreTurns ~= 0 or st.nervous ~= 0 or st.numTurnsSkipped ~= 0 then
      i = s8(i - 1)
      if i < 0 then return end
    else
      break
    end
  end
  local move = c.status[a].currMove
  if c.data.moves[move].category == c.data.moves[c.status[j].currMove].category then
    c.status[a].appeal = s16(c.status[a].appeal + moveAppeal(c, move) * 2)
    setStr(c, a, STR.SAME_TYPE_GOOD)
  end
end

-- pokeemerald/src/contest_effect.c:682
E[36] = function(c)
  local a = me(c)
  if order(c, a) ~= 0 then
    local move = c.status[a].currMove
    for i = 0, N - 1 do
      if order(c, a) - 1 == order(c, i)
        and c.data.moves[move].category ~= c.data.moves[c.status[i].currMove].category then
        c.status[a].appeal = s16(c.status[a].appeal + moveAppeal(c, move) * 2)
        setStr(c, a, STR.DIFF_TYPE_GOOD)
        break
      end
    end
  end
end

-- pokeemerald/src/contest_effect.c:703
E[37] = function(c)
  local a = me(c)
  if order(c, a) ~= 0 then
    for i = 0, N - 1 do
      if order(c, a) - 1 == order(c, i) then
        local st = c.status[a]
        if st.appeal > c.status[i].appeal then
          st.appeal = s16(st.appeal * 2)
          setStr(c, a, STR.STOOD_OUT_AS_MUCH)
        elseif st.appeal < c.status[i].appeal then
          st.appeal = 0
          setStr(c, a, STR.NOT_AS_WELL)
        end
      end
    end
  end
end

-- pokeemerald/src/contest_effect.c:729
E[38] = function(c)
  local st = c.status[me(c)]
  if st.condition < 30 then
    st.condition = s8(st.condition + 10)
    st.conditionMod = Contest.CONDITION.GAIN
    setStr(c, me(c), STR.CONDITION_ROSE)
  else
    setStr(c, me(c), STR.NO_CONDITION_IMPROVE)
  end
end

-- pokeemerald/src/contest_effect.c:744
E[39] = function(c)
  local st = c.status[me(c)]
  st.appealTripleCondition = 1
  if st.condition ~= 0 then setStr(c, me(c), STR.HOT_STATUS)
  else setStr(c, me(c), STR.BAD_CONDITION_WEAK_APPEAL) end
end

-- pokeemerald/src/contest_effect.c:754
E[40] = function(c)
  if c.contest.appealNumber == Contest.LAST_APPEAL then return end
  local a = me(c)
  local t = zero4()
  for i = 0, N - 1 do t[i] = c.status[i].nextTurnOrder end
  t[a] = NONE
  for i = 0, N - 1 do
    local j = 0
    while j < N do
      if j ~= a and i == t[j] and t[j] == c.status[j].nextTurnOrder then
        t[j] = u8(t[j] + 1)
        break
      end
      j = j + 1
    end
    if j == N then break end
  end
  t[a] = 0
  c.status[a].turnOrderMod = 1
  for i = 0, N - 1 do c.status[i].nextTurnOrder = t[i] end
  c.status[a].turnOrderModAction = 1
  setStr(c, a, STR.MOVE_UP_LINE)
end

-- pokeemerald/src/contest_effect.c:796
E[41] = function(c)
  if c.contest.appealNumber == Contest.LAST_APPEAL then return end
  local a = me(c)
  local t = zero4()
  for i = 0, N - 1 do t[i] = c.status[i].nextTurnOrder end
  t[a] = NONE
  for i = N - 1, 0, -1 do
    local j = 0
    while j < N do
      if j ~= a and i == t[j] and t[j] == c.status[j].nextTurnOrder then
        t[j] = u8(t[j] - 1)
        break
      end
      j = j + 1
    end
    if j == N then break end
  end
  t[a] = N - 1
  c.status[a].turnOrderMod = 1
  for i = 0, N - 1 do c.status[i].nextTurnOrder = t[i] end
  c.status[a].turnOrderModAction = 2
  setStr(c, a, STR.MOVE_BACK_LINE)
end

E[42] = function() end

-- pokeemerald/src/contest_effect.c:844
E[43] = function(c)
  if c.contest.appealNumber == Contest.LAST_APPEAL then return end
  local t, free = zero4(), zero4()
  for i = 0, N - 1 do
    t[i] = c.status[i].nextTurnOrder
    free[i] = i
  end
  for i = 0, N - 1 do
    local rval = c:random() % (N - i)
    for j = 0, N - 1 do
      if free[j] ~= NONE then
        if rval == 0 then
          t[j] = i
          free[j] = NONE
          break
        else
          rval = rval - 1
        end
      end
    end
  end
  for i = 0, N - 1 do
    c.status[i].nextTurnOrder = t[i]
    c.status[i].turnOrderMod = 2
  end
  c.status[me(c)].turnOrderModAction = 3
  setStr(c, me(c), STR.SCRAMBLE_ORDER)
end

-- pokeemerald/src/contest_effect.c:892
E[44] = function(c)
  local st = c.status[me(c)]
  if c.data.moves[st.currMove].category ~= c.category then st.overrideCategoryExcitementMod = 1 end
end

-- pokeemerald/src/contest_effect.c:901
E[45] = function(c)
  local numJammed = 0
  local a = me(c)
  for i = 0, N - 1 do
    if order(c, a) > order(c, i) then
      if c.status[i].appeal > 0 then
        c.results.jam = s16(tdiv(c.status[i].appeal, 2))
        c.results.jam = roundUp(c.results.jam)
      else
        c.results.jam = 10
      end
      c.results.jamQueue[0] = i
      c.results.jamQueue[1] = NONE
      if wasAnyJammed(c) then numJammed = numJammed + 1 end
    end
  end
  if numJammed == 0 then setStr2(c, a, STR.MESSED_UP2) end
  setStr(c, a, STR.ATTEMPT_STARTLE)
end

-- pokeemerald/src/contest_effect.c:931
E[46] = function(c)
  local a, lvl = me(c), c.contest.applauseLevel
  local appeal
  if lvl == 0 then appeal = 10; setStr(c, a, STR.APPEAL_NOT_VERY_WELL)
  elseif lvl == 1 then appeal = 20; setStr(c, a, STR.APPEAL_SLIGHTLY_WELL2)
  elseif lvl == 2 then appeal = 30; setStr(c, a, STR.APPEAL_PRETTY_WELL2)
  elseif lvl == 3 then appeal = 50; setStr(c, a, STR.APPEAL_VERY_WELL)
  else appeal = 60; setStr(c, a, STR.APPEAL_EXCELLENTLY2) end
  c.status[a].appeal = appeal
end

-- pokeemerald/src/contest_effect.c:964
E[47] = function(c)
  local x = c.excitement
  if x.frozen == 0 then
    x.frozen = 1
    x.freezer = me(c)
    setStr(c, me(c), STR.ATTRACTED_ATTENTION)
  end
end

-- pokeemerald/src/contest.c:3488
local function canUseTurn(c, i)
  local st = c.status[i]
  return not (st.numTurnsSkipped ~= 0 or st.noMoreTurns ~= 0)
end

-- pokeemerald/src/contest.c:4425
function Contest:calculateAppealMoveImpact(contestant)
  local st = self.status[contestant]
  local d = self.data
  st.appeal = 0
  st.baseAppeal = 0
  if not canUseTurn(self, contestant) then return end
  local move = st.currMove
  local effect = d.moves[move].effect
  st.moveCategory = d.moves[st.currMove].category
  if st.currMove == st.prevMove and st.currMove ~= 0 then
    st.repeatedMove = 1
    st.moveRepeatCount = bits(st.moveRepeatCount + 1, 3)
  else
    st.moveRepeatCount = 0
  end
  st.baseAppeal = d.effects[effect].appeal
  st.appeal = st.baseAppeal
  self.results.jam = d.effects[effect].jam
  self.results.jam2 = self.results.jam
  self.results.contestant = contestant
  for i = 0, N - 1 do
    self.status[i].jam = 0
    self.results.unnervedPokes[i] = 0
  end
  if st.hasJudgesAttention ~= 0 and self:areMovesCombo(st.prevMove, st.currMove) == 0 then
    st.hasJudgesAttention = 0
  end
  local fn = E[effect]
  if fn then fn(self) end
  if st.conditionMod == Contest.CONDITION.GAIN then
    st.appeal = s16(st.appeal + st.condition - 10)
  elseif st.appealTripleCondition ~= 0 then
    st.appeal = s16(st.appeal + st.condition * 3)
  else
    st.appeal = s16(st.appeal + st.condition)
  end
  st.completedCombo = 0
  st.usedComboMove = 0
  if self:isAllowedToCombo(contestant) then
    local completed = self:areMovesCombo(st.prevMove, st.currMove)
    if completed ~= 0 and st.hasJudgesAttention ~= 0 then
      st.completedCombo = completed
      st.usedComboMove = 1
      st.hasJudgesAttention = 0
      st.comboAppealBonus = u8(st.baseAppeal * st.completedCombo)
      st.completedComboFlag = 1
    else
      if d.moves[st.currMove].comboStarterId ~= 0 then
        st.hasJudgesAttention = 1
        st.usedComboMove = 1
      else
        st.hasJudgesAttention = 0
      end
    end
  end
  if st.repeatedMove ~= 0 then st.repeatJam = u8((st.moveRepeatCount + 1) * 10) end
  if st.nervous ~= 0 then
    st.hasJudgesAttention = 0
    st.appeal = 0
    st.baseAppeal = 0
  end
  local x = self.excitement
  x.moveExcitement = self:moveExcitement(st.currMove)
  if st.overrideCategoryExcitementMod ~= 0 then x.moveExcitement = 1 end
  if x.moveExcitement > 0 then
    if self.contest.applauseLevel + x.moveExcitement > 4 then x.excitementAppealBonus = 60
    else x.excitementAppealBonus = 10 end
  else
    x.excitementAppealBonus = 0
  end
  local rnd = self:random() % (N - 1)
  local i = 0
  while i < N do
    if i ~= contestant then
      if rnd == 0 then break end
      rnd = rnd - 1
    end
    i = i + 1
  end
  st.contestantAnimTarget = i
end

-- pokeemerald/src/contest.c:5638
function Contest:setLiveUpdateFlags(contestant)
  local L, x, st, tv = Contest.LIVE, self.excitement, self.status[contestant], self.tv[contestant]
  local function wf(t, flag) t.winnerFlags = t.winnerFlags - t.winnerFlags % (flag * 2) + t.winnerFlags % flag + flag end
  local function lf(t, flag) t.loserFlags = t.loserFlags - t.loserFlags % (flag * 2) + t.loserFlags % flag + flag end
  if x.frozen == 0 and x.moveExcitement > 0 and st.repeatedMove == 0 then
    wf(tv, L.EXCITING_APPEAL)
    tv.madeExcitingAppeal = 1
  end
  if st.nervous ~= 0 then wf(tv, L.GOT_NERVOUS) end
  if x.frozen == 0 and x.moveExcitement ~= 0 and x.excitementAppealBonus == 60 then wf(tv, L.MAXED_EXCITEMENT) end
  if st.usedComboMove ~= 0 and st.completedCombo ~= 0 then wf(tv, L.USED_COMBO) end
  for i = 0, N - 1 do
    if i ~= contestant and self.status[i].jam ~= 0 then
      wf(tv, L.STARTLED_OTHER)
      wf(self.tv[i], L.GOT_STARTLED)
    end
  end
  if st.numTurnsSkipped ~= 0 or st.noMoreTurns ~= 0 then
    wf(tv, L.SKIPPED_TURN)
  elseif st.nervous == 0 then
    wf(tv, L.MADE_APPEAL)
    tv.madeAppeal = 1
    tv.appeals[self.contest.appealNumber] = st.currMove
  end
  local LL = Contest.LIVE_LOSER
  if st.repeatedMove ~= 0 then lf(tv, LL.REPEATED_MOVE) end
  if self.contest.applauseLevel == 4 and x.frozen == 0 and x.moveExcitement < 0 then lf(tv, LL.MISSED_EXCITEMENT) end
end

-- pokeemerald/src/contest.c:1736
function Contest:startTurn()
  local i = 0
  while self.contest.turnNumber ~= self.results.turnOrder[i] do i = i + 1 end
  self.contest.currentContestant = i
  self:calculateAppealMoveImpact(i)
  return i
end

local function ev(list, kind, t)
  t = t or {}
  t.kind = kind
  list[#list + 1] = t
  return t
end

-- pokeemerald/src/contest.c:1727
function Contest:runTurn()
  local contestant = self:startTurn()
  return self:completeTurn(contestant), contestant
end

function Contest:completeTurn(contestant)
  local out = {}
  local st = self.status[contestant]
  local c = self.contest
  self:setLiveUpdateFlags(contestant)
  ev(out, "turn", { contestant = contestant, move = st.currMove, turn = c.turnNumber })
  if st.numTurnsSkipped ~= 0 or st.noMoreTurns ~= 0 then
    ev(out, "text", { text = "gText_MonWasWatchingOthers", contestant = contestant })
    return out
  end
  ev(out, "slideIn", { contestant = contestant })
  if st.nervous ~= 0 then
    if st.hasJudgesAttention ~= 0 then st.hasJudgesAttention = 0 end
    ev(out, "text", { text = "gText_MonWasTooNervousToMove", contestant = contestant, move = st.currMove })
  else
    ev(out, "text", { text = "gText_MonAppealedWithMove", contestant = contestant, move = st.currMove })
    ev(out, "moveAnim", { contestant = contestant, move = st.currMove, target = st.contestantAnimTarget })
    local guard = 0
    while true do
      guard = guard + 1
      if guard > 8 then break end
      if st.effectStringId ~= STR.NONE then
        ev(out, "result", { contestant = contestant, stringId = st.effectStringId })
        st.effectStringId = STR.NONE
      elseif st.effectStringId2 ~= STR.NONE then
        local other = false
        for i = 0, N - 1 do
          if i ~= contestant and self.status[i].effectStringId ~= STR.NONE then other = true; break end
        end
        if not other then
          ev(out, "result", { contestant = contestant, stringId = st.effectStringId2 })
          st.effectStringId2 = STR.NONE
        end
        break
      else
        break
      end
    end
    if st.turnOrderModAction == 1 then ev(out, "judge", { symbol = Contest.JUDGE.NUMBER_ONE })
    elseif st.turnOrderModAction == 2 then ev(out, "judge", { symbol = Contest.JUDGE.NUMBER_FOUR })
    elseif st.turnOrderModAction == 3 then ev(out, "judge", { symbol = Contest.JUDGE.QUESTION_MARK }) end
    ev(out, "nextTurnGfx", {})
    ev(out, "hearts", { contestant = contestant, from = 0, delta = st.appeal })
    if st.conditionMod == Contest.CONDITION.GAIN then ev(out, "judge", { symbol = Contest.JUDGE.STAR }) end
    self:updateConditionStars(contestant, out)
    ev(out, "status", { contestant = contestant })
    local from = 0
    while true do
      local found
      for t = from, N - 1 do
        for j = 0, N - 1 do
          if j ~= contestant and self.turnOrder[j] == t and self.status[j].effectStringId ~= STR.NONE then
            found = j
            break
          end
        end
        if found then break end
      end
      if not found then break end
      from = self.turnOrder[found]
      local o = self.status[found]
      ev(out, "result", { contestant = found, stringId = o.effectStringId, attacker = contestant })
      o.effectStringId = STR.NONE
      ev(out, "hearts", { contestant = found, from = o.appeal + o.jam, delta = -o.jam })
      self:updateConditionStars(found, out)
      ev(out, "status", { contestant = found })
      if o.judgesAttentionWasRemoved ~= 0 then
        ev(out, "judgeEye", { contestant = found, on = false })
        o.judgesAttentionWasRemoved = 0
      end
      from = from + 1
    end
    if st.numTurnsSkipped ~= 0 or st.turnSkipped ~= 0 then
      ev(out, "text", { text = "gText_MonCantAppealNextTurn", contestant = contestant })
    end
    if st.usedComboMove ~= 0 then
      if st.completedCombo ~= 0 then
        ev(out, "text", { text = st.completedCombo == 1 and "gText_AppealComboWentOverWell"
          or st.completedCombo == 2 and "gText_AppealComboWentOverVeryWell" or "gText_AppealComboWentOverExcellently" })
        ev(out, "judge", { symbol = Contest.JUDGE.TWO_EXCLAMATIONS })
      else
        ev(out, "text", { text = "gText_JudgeLookedAtMonExpectantly", contestant = contestant })
        ev(out, "judge", { symbol = Contest.JUDGE.ONE_EXCLAMATION })
      end
      ev(out, "judgeEye", { contestant = contestant, on = st.hasJudgesAttention ~= 0 })
      if st.hasJudgesAttention == 0 then
        ev(out, "hearts", { contestant = contestant, from = st.appeal, delta = st.comboAppealBonus })
        st.appeal = s16(st.appeal + st.comboAppealBonus)
      end
    end
    if st.repeatedMove ~= 0 then
      ev(out, "text", { text = "gText_RepeatedAppeal", contestant = contestant })
      ev(out, "judge", { symbol = Contest.JUDGE.SWIRL })
      ev(out, "hearts", { contestant = contestant, from = st.appeal, delta = -st.repeatJam })
      st.appeal = s16(st.appeal - st.repeatJam)
    end
    self:updateCrowd(contestant, out)
  end
  if c.applauseLevel > 4 then
    c.applauseLevel = 0
    ev(out, "applause", { level = 0, reset = true })
  end
  ev(out, "slideOut", { contestant = contestant })
  return out
end

-- pokeemerald/src/contest.c:3271
function Contest:updateConditionStars(i, out)
  local st = self.status[i]
  if st.conditionMod == Contest.CONDITION.NO_CHANGE then return false end
  ev(out, "stars", { contestant = i, condition = st.condition, gain = st.conditionMod == Contest.CONDITION.GAIN })
  st.conditionMod = Contest.CONDITION.NO_CHANGE
  return true
end

-- pokeemerald/src/contest.c:2198
function Contest:updateCrowd(contestant, out)
  local st, x, c = self.status[contestant], self.excitement, self.contest
  if x.frozen ~= 0 and contestant ~= x.freezer then
    ev(out, "text", { text = "gText_CrowdContinuesToWatchMon", contestant = contestant, freezer = x.freezer,
      move = st.currMove })
    ev(out, "text", { text = "gText_MonsMoveIsIgnored", contestant = contestant })
    return
  end
  local r3 = x.moveExcitement
  local override = st.overrideCategoryExcitementMod ~= 0
  if override then r3 = 1 end
  if r3 > 0 and st.repeatedMove ~= 0 then r3 = 0 end
  c.applauseLevel = s8(c.applauseLevel + r3)
  if c.applauseLevel < 0 then c.applauseLevel = 0 end
  if r3 == 0 then return end
  local text
  if r3 < 0 then text = "gText_MonsXDidntGoOverWell"
  elseif c.applauseLevel <= 4 then text = "gText_MonsXWentOverGreat"
  else text = "gText_MonsXGotTheCrowdGoing" end
  ev(out, "text", { text = text, contestant = contestant, move = override and st.currMove or nil,
    condition = not override and self.data.moves[st.currMove].category or nil })
  ev(out, "crowd", { delta = r3, level = c.applauseLevel })
  if r3 > 0 then
    ev(out, "hearts", { contestant = contestant, from = st.appeal, delta = x.excitementAppealBonus })
    st.appeal = s16(st.appeal + x.excitementAppealBonus)
  end
end

-- pokeemerald/src/contest.c:3414
function Contest:rankContestants()
  local arr = zero4()
  for i = 0, N - 1 do
    local st = self.status[i]
    st.pointTotal = s16(st.pointTotal + st.appeal)
    arr[i] = st.pointTotal
  end
  for i = 0, N - 2 do
    for j = N - 1, i + 1, -1 do
      if arr[j - 1] < arr[j] then arr[j], arr[j - 1] = arr[j - 1], arr[j] end
    end
  end
  for i = 0, N - 1 do
    for j = 0, N - 1 do
      if self.status[i].pointTotal == arr[j] then
        self.status[i].ranking = bits(j, 2)
        break
      end
    end
  end
  self:sortContestants(true)
  self:applyNextTurnOrder()
end

-- pokeemerald/src/contest.c:3463
function Contest:setAttentionLevels()
  for i = 0, N - 1 do
    local st = self.status[i]
    local lvl
    if st.currMove == 0 then lvl = 5
    elseif st.appeal <= 0 then lvl = 0
    elseif st.appeal < 30 then lvl = 1
    elseif st.appeal < 60 then lvl = 2
    elseif st.appeal < 80 then lvl = 3
    else lvl = 4 end
    st.attentionLevel = lvl
  end
end

-- pokeemerald/src/contest.c:2478
function Contest:finishRound()
  self:rankContestants()
  self:setAttentionLevels()
end

-- pokeemerald/src/contest.c:3496
function Contest:setStatusesForNextRound()
  for i = 0, N - 1 do
    local st = self.status[i]
    st.appeal = 0
    st.baseAppeal = 0
    st.jamSafetyCount = 0
    if st.numTurnsSkipped > 0 then st.numTurnsSkipped = st.numTurnsSkipped - 1 end
    st.jam = 0
    st.resistant = 0
    st.jamReduction = 0
    st.immune = 0
    st.moreEasilyStartled = 0
    st.usedRepeatableMove = 0
    st.nervous = 0
    st.effectStringId = STR.NONE
    st.effectStringId2 = STR.NONE
    st.conditionMod = Contest.CONDITION.NO_CHANGE
    st.repeatedPrevMove = st.repeatedMove
    st.repeatedMove = 0
    st.turnOrderModAction = 0
    st.appealTripleCondition = 0
    if st.turnSkipped ~= 0 then
      st.numTurnsSkipped = 1
      st.turnSkipped = 0
    end
    if st.exploded ~= 0 then
      st.noMoreTurns = 1
      st.exploded = 0
    end
    st.overrideCategoryExcitementMod = 0
  end
  local c = self.contest
  for i = 0, N - 1 do
    local st = self.status[i]
    st.prevMove = st.currMove
    c.moveHistory[c.appealNumber][i] = st.currMove
    c.excitementHistory[c.appealNumber][i] = self:moveExcitement(st.currMove)
    st.currMove = 0
  end
  self.excitement.frozen = 0
end

-- pokeemerald/src/contest.c:5150
function Contest:resetForNextRound()
  for i = 0, N - 1 do self.contest.prevTurnOrder[i] = self.turnOrder[i] end
  self:setStatusesForNextRound()
end

-- pokeemerald/src/contest.c:2633
function Contest:nextRound()
  self.contest.appealNumber = self.contest.appealNumber + 1
  return self.contest.appealNumber < Contest.NUM_APPEALS
end

-- pokeemerald/src/contest.c:3646
local function placedHigher(a, b, s)
  if s[a].totalPoints < s[b].totalPoints then return true
  elseif s[a].totalPoints > s[b].totalPoints then return false
  elseif s[a].round1Points < s[b].round1Points then return true
  elseif s[a].round1Points > s[b].round1Points then return false
  elseif s[a].random < s[b].random then return true end
  return false
end

-- pokeemerald/src/contest.c:3571
function Contest:determineFinalStandings()
  local rnd = uniqueRandoms(self)
  local s = {}
  for i = 0, N - 1 do
    s[i] = { totalPoints = self.totals[i], round1Points = self.round1[i], random = rnd[i], contestant = i }
  end
  for i = 0, N - 2 do
    for j = N - 1, i + 1, -1 do
      if placedHigher(j - 1, j, s) then s[j - 1], s[j] = s[j], s[j - 1] end
    end
  end
  for i = 0, N - 1 do self.standings[s[i].contestant] = i end
end

-- pokeemerald/src/contest.c:3557
function Contest:calculateFinalScores()
  for i = 0, N - 1 do
    self.round2[i] = s16(self.appealTotals[i] * 2)
    self.totals[i] = s16(self.round1[i] + self.round2[i])
  end
  self:determineFinalStandings()
end

-- pokeemerald/src/contest.c:2659
function Contest:endAppeals()
  for i = 0, N - 1 do self.appealTotals[i] = self.status[i].pointTotal end
  self:calculateFinalScores()
end

function Contest:winner()
  for i = 0, N - 1 do
    if self.standings[i] == 0 then return i end
  end
  return 0
end

function Contest:playerPlace()
  return self.standings[self.playerIndex]
end

-- pokeemerald/src/contest.c:1498
function Contest:runRound(playerMoveChoice)
  local events = {}
  self:chooseMoves(playerMoveChoice)
  self.contest.turnNumber = 0
  for t = 0, N - 1 do
    self.contest.turnNumber = t
    local out, who = self:runTurn()
    events[#events + 1] = { contestant = who, events = out }
  end
  self:finishRound()
  return events
end

function Contest:run(schedule)
  schedule = schedule or {}
  local rounds = {}
  while true do
    local r = self.contest.appealNumber
    rounds[r + 1] = self:runRound(schedule[r + 1] or 0)
    self:resetForNextRound()
    if not self:nextRound() then break end
  end
  self:endAppeals()
  return rounds
end

return Contest
