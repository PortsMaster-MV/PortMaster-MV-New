local Contest = require("src.core.game3.rse.contest")

local Util = {}

-- pokeemerald/include/constants/contest.h:29
Util.WINNER = {
  ARTIST = 0, HALL_1 = 1, HALL_2 = 2, HALL_3 = 3, HALL_4 = 4, HALL_5 = 5, HALL_6 = 6,
  HALL_UNUSED_1 = 7, HALL_UNUSED_2 = 8,
  MUSEUM_COOL = 9, MUSEUM_BEAUTY = 10, MUSEUM_CUTE = 11, MUSEUM_SMART = 12, MUSEUM_TOUGH = 13,
}
-- pokeemerald/include/constants/global.h:62
Util.NUM_CONTEST_WINNERS = 13
Util.NUM_CONTEST_HALL_WINNERS = 8
Util.MUSEUM_CONTEST_WINNERS_START = 8
Util.SAVE_FOR_MUSEUM = 0xFF
Util.SAVE_FOR_ARTIST = 0xFE
Util.NUM_PAINTING_CAPTIONS = 3
-- pokeemerald/include/constants/contest.h:55
Util.ELIGIBILITY = { CANT_ENTER = 0, EQUAL_RANK = 1, HIGH_RANK = 2, EGG = 3, FAINTED = 4 }
-- pokeemerald/src/contest_util.c:83
Util.MAX_BAR_LENGTH = 11 * 8
Util.ARTIST_POINTS = 800

Util.state = nil

local function Ribbons() return require("src.core.game3.rse.ribbons") end
local function Pokemon() return require("src.core.game3.pokemon") end
local function Rse() return require("src.core.game3.rse.init") end

local function num(v) return tonumber(v) or 0 end

local function constants(session)
  local C = require("src.core.game3.constants")
  return C.of(C.versionOf(session))
end

local function itemId(session, v)
  if type(v) == "number" then return v end
  if type(v) == "string" then return constants(session):id("items", v) end
  return 0
end

local function moveId(entry)
  if type(entry) == "table" then return num(entry.id or entry.move) end
  return num(entry)
end

function Util.categoryName(category)
  return Contest.CATEGORY_NAMES[num(category)]
end

-- pokeemerald/src/contest.c:2777
function Util.contestantFromMon(mon, session)
  session = session or Rse().session()
  local P = Pokemon()
  local c = require("src.core.game3.rse.pokeblock").contest(mon) or {}
  local moves = {}
  for i = 1, 4 do moves[i] = moveId(mon.moves and mon.moves[i]) end
  local item = itemId(session, mon.item or mon.heldItem)
  local scarf
  for cat = 0, 4 do
    if item ~= 0 and item == itemId(session, Contest.SCARVES[cat]) then scarf = cat end
  end
  local female = session and (session.gender == "female" or session.gender == "F" or session.gender == 1)
  local C = constants(session)
  return {
    species = num(P.speciesOf(mon)),
    moves = moves,
    cool = num(c.cool), beauty = num(c.beauty), cute = num(c.cute), smart = num(c.smart), tough = num(c.tough),
    sheen = num(c.sheen),
    personality = num(mon.personality) % 4294967296,
    otId = num(mon.otId) % 65536 + (num(mon.otSecretId) % 65536) * 65536,
    nickname = mon.nickname,
    trainerName = session and (session.name or session.playerName) or nil,
    trainerGfxId = C:id("event_objects", female and "OBJ_EVENT_GFX_LINK_MAY" or "OBJ_EVENT_GFX_LINK_BRENDAN") or 0,
    scarfCategory = scarf,
  }
end

-- pokeemerald/src/contest.c:2958
function Util.eligibility(mon, category, rank)
  local P = Pokemon()
  if P.isEgg(mon) then return Util.ELIGIBILITY.EGG end
  if num(mon.hp) == 0 then return Util.ELIGIBILITY.FAINTED end
  local name = Util.categoryName(category)
  if not name then return Util.ELIGIBILITY.CANT_ENTER end
  local ribbon = Ribbons().get(mon, name)
  rank = num(rank)
  if ribbon > rank then return Util.ELIGIBILITY.HIGH_RANK end
  if ribbon >= rank then return Util.ELIGIBILITY.EQUAL_RANK end
  return Util.ELIGIBILITY.CANT_ENTER
end

local function gameClear(session)
  local ok, v = pcall(function() return Rse().flag("FLAG_SYS_GAME_CLEAR", session) end)
  return ok and v == true
end

-- pokeemerald/src/contest_util.c:1958
function Util.tryEnterContestMon(session, partyIndex, category, rank, opts)
  opts = opts or {}
  local mon = session.party[partyIndex + 1]
  local e = Util.eligibility(mon, category, rank)
  if e ~= Util.ELIGIBILITY.CANT_ENTER then
    local c = Contest.new({ data = opts.data, category = category, rank = rank, rng = opts.rng })
    c:setContestants({ gameClear = opts.gameClear == nil and gameClear(session) or opts.gameClear,
      player = Util.contestantFromMon(mon, session) })
    c:calculateRound1Points()
    Util.state = { contest = c, partyIndex = partyIndex, category = category, rank = rank }
  end
  return e
end

function Util.current()
  return Util.state and Util.state.contest or nil
end

-- pokeemerald/src/contest_util.c:616
function Util.persistLinkResults(session, c)
  if not (c and c:isLink()) then return true end
  local warp = session and session.dynamicWarp
  local x, y = type(warp) == "table" and tonumber(warp.x), type(warp) == "table" and tonumber(warp.y)
  if type(warp) ~= "table" or type(warp.map) ~= "string" or warp.map == ""
      or not x or not y or x < 0 or y < 0 or x >= math.huge or y >= math.huge
      or x ~= math.floor(x) or y ~= math.floor(y) then
    return false, "The saved contest entrance is incomplete. The results were not saved."
  end
  local R, bit = Rse(), require("bit")
  local id, store = R.varId("VAR_CONTEST_HALL_STATE", session), R.store()
  local vars = store and store.vars
  if not id or not vars then return false, "The contest results could not be saved." end
  local before = vars[id]
  R.setVar(id, 0, session)
  if session.vars then session.vars[id] = 0 end
  session.continueGameWarp = { map = warp.map, warpId = warp.warpId, x = x, y = y }
  session.specialSaveWarpFlags = bit.bor(tonumber(session.specialSaveWarpFlags) or 0, 1)
  local ok, written = pcall(require("src.core.game3.rse.frontier.util").persist)
  session.specialSaveWarpFlags = bit.band(tonumber(session.specialSaveWarpFlags) or 0, bit.bnot(1))
  vars[id] = before
  if session.vars then session.vars[id] = before end
  if not ok or written ~= true then return false, "The contest results could not be saved." end
  return true
end

local function playerMon(session)
  local st = Util.state
  return st and session and session.party and session.party[st.partyIndex + 1] or nil
end

-- pokeemerald/src/contest_util.c:1972
function Util.hasMonWonThisContestBefore(mon, category, rank)
  local name = Util.categoryName(category)
  if not name then return false end
  return Ribbons().get(mon, name) > num(rank)
end

-- pokeemerald/src/contest_util.c:2003
function Util.giveMonContestRibbon(session)
  local c, st = Util.current(), Util.state
  if not c or c.standings[c.playerIndex] ~= 0 then return false end
  local mon = playerMon(session)
  if not mon then return false end
  local name = Util.categoryName(st.category)
  local have = Ribbons().get(mon, name)
  if have <= st.rank and have <= Contest.RANK.MASTER then
    Ribbons().set(mon, name, have + 1)
    if Ribbons().count(mon) > Ribbons().NUM_CUTIES_RIBBONS then
      Rse().call("tv", "putSpotTheCutiesOnAir", "TryPutSpotTheCutiesOnAir", nil, mon, name)
    end
    return true
  end
  return false
end

-- pokeemerald/src/contest_util.c:2549
function Util.giveMonArtistRibbon(session)
  local c, st = Util.current(), Util.state
  if not c then return false end
  local mon = playerMon(session)
  if not mon then return false end
  if Ribbons().get(mon, "artist") == 0 and c.standings[c.playerIndex] == 0 and st.rank == Contest.RANK.MASTER
    and c.totals[c.playerIndex] >= Util.ARTIST_POINTS then
    Ribbons().set(mon, "artist", 1)
    if Ribbons().count(mon) > Ribbons().NUM_CUTIES_RIBBONS then
      Rse().call("tv", "putSpotTheCutiesOnAir", "TryPutSpotTheCutiesOnAir", nil, mon, "artist")
    end
    return true
  end
  return false
end

-- pokeemerald/src/contest_util.c:61
function Util.winnerId(c)
  c = c or Util.current()
  local i = 0
  while i < Contest.CONTESTANT_COUNT and c.standings[i] ~= 0 do i = i + 1 end
  return i
end

-- pokeemerald/src/contest_util.c:2077
function Util.conditionRanking(c, who)
  local rank = 0
  for i = 0, Contest.CONTESTANT_COUNT - 1 do
    if c.round1[who] < c.round1[i] then rank = rank + 1 end
  end
  return rank
end

-- pokeemerald/src/contest_util.c:2090
function Util.condition(c, who)
  return c.round1[who]
end

-- pokeemerald/src/contest_util.c:2367
function Util.shouldReadyContestArtist(c)
  c = c or Util.current()
  return c ~= nil and c.standings[c.playerIndex] == 0 and c.rank == Contest.RANK.MASTER
    and c.totals[c.playerIndex] >= Util.ARTIST_POINTS
end

-- pokeemerald/src/contest_util.c:2294
function Util.setContestTrainerGfxIds(session, c)
  c = c or Util.current()
  for i = 0, 2 do
    Rse().setVar("VAR_OBJ_GFX_ID_" .. i, c.mons[i].trainerGfxId or 0, session)
  end
end

local function copyWinner(w)
  if type(w) ~= "table" then return nil end
  local out = {}
  for k, v in pairs(w) do
    if type(v) == "table" then
      local t = {}
      for k2, v2 in pairs(v) do t[k2] = v2 end
      out[k] = t
    else
      out[k] = v
    end
  end
  return out
end

local function emptyWinner()
  return { personality = 0, trainerId = 0, species = 0, contestCategory = 0, monName = {}, trainerName = {},
    contestRank = 0 }
end

function Util.defaultWinners(data)
  data = data or Contest.data()
  return data.manifest.defaultWinners
end

-- pokeemerald/src/contest.c:5630
function Util.clearHallWinners(session, data)
  local defaults = Util.defaultWinners(data)
  session.contestWinners = session.contestWinners or {}
  for i = 0, Util.MUSEUM_CONTEST_WINNERS_START - 1 do
    session.contestWinners[i + 1] = copyWinner(defaults[i]) or emptyWinner()
  end
end

-- pokeemerald/src/new_game.c:108
function Util.clearAllWinners(session, data)
  session.contestWinners = {}
  Util.clearHallWinners(session, data)
  for i = Util.MUSEUM_CONTEST_WINNERS_START, Util.NUM_CONTEST_WINNERS - 1 do
    session.contestWinners[i + 1] = emptyWinner()
  end
end

-- pokeemerald/src/contest.c:5594
function Util.winnerSaveIdx(session, rank, category, shift)
  rank = num(rank)
  if rank <= Contest.RANK.MASTER then
    if shift then
      local w = session.contestWinners
      for i = Util.NUM_CONTEST_HALL_WINNERS - 1, 1, -1 do w[i + 1] = copyWinner(w[i]) end
    end
    return Util.WINNER.HALL_1 - 1
  end
  local map = { [0] = Util.WINNER.MUSEUM_COOL, Util.WINNER.MUSEUM_BEAUTY, Util.WINNER.MUSEUM_CUTE,
    Util.WINNER.MUSEUM_SMART }
  return (map[num(category)] or Util.WINNER.MUSEUM_TOUGH) - 1
end

-- pokeemerald/src/contest.c:5522
function Util.saveContestWinner(session, rank, c)
  c = c or Util.current()
  local captionId = c:random() % Util.NUM_PAINTING_CAPTIONS
  local i = 0
  while i < Contest.CONTESTANT_COUNT - 1 do
    if c.standings[i] == 0 then break end
    i = i + 1
  end
  if rank == Util.SAVE_FOR_MUSEUM and i ~= c.playerIndex then return false end
  if c.category >= 0 and c.category <= 4 then captionId = captionId + Util.NUM_PAINTING_CAPTIONS * c.category end
  local m = c.mons[i]
  local row = {
    personality = m.personality or 0, species = m.species or 0, trainerId = m.otId or 0,
    monName = m.nickname, trainerName = m.trainerName,
  }
  if rank ~= Util.SAVE_FOR_ARTIST then
    session.contestWinners = session.contestWinners or {}
    local id = Util.winnerSaveIdx(session, rank, c.category, true)
    row.contestRank = c:isLink() and Contest.RANK.LINK or c.rank
    row.contestCategory = rank ~= Util.SAVE_FOR_MUSEUM and c.category or captionId
    session.contestWinners[id + 1] = row
  else
    row.contestCategory = captionId
    Util.curWinner = row
  end
  return true
end

-- pokeemerald/src/contest_util.c:2381
function Util.countPlayerMuseumPaintings(session)
  local n = 0
  local w = session.contestWinners or {}
  for i = Util.MUSEUM_CONTEST_WINNERS_START, Util.NUM_CONTEST_WINNERS - 1 do
    if w[i + 1] and num(w[i + 1].species) ~= 0 then n = n + 1 end
  end
  return n
end

-- pokeemerald/src/contest_util.c:2333
function Util.categoryHasMuseumPainting(session, category)
  local id = Util.winnerSaveIdx(session, Util.SAVE_FOR_MUSEUM, category, false)
  local w = (session.contestWinners or {})[id + 1]
  return w ~= nil and num(w.species) ~= 0
end

-- pokeemerald/src/contest_util.c:1470
function Util.preliminaryStars(c, i, cap)
  local condition = c.round1[i] % 65536 * 65536
  local stars = math.floor(condition / 0x3F)
  if stars % 65536 ~= 0 then stars = stars + 0x10000 end
  stars = math.floor(stars / 65536)
  if stars == 0 and condition ~= 0 then stars = 1 end
  if cap and stars > 10 then stars = 10 end
  return stars % 256
end

-- pokeemerald/src/contest_util.c:1489
function Util.round2Hearts(c, i, cap)
  local res = c.round2[i]
  local r4 = math.abs(res) % 65536 * 65536
  local hearts = math.floor(r4 / 80)
  if hearts % 65536 ~= 0 then hearts = hearts + 0x10000 end
  hearts = math.floor(hearts / 65536)
  if hearts == 0 and r4 ~= 0 then hearts = 1 end
  if cap and hearts > 10 then hearts = 10 end
  return Contest.s8(res < 0 and -hearts or hearts)
end

local function tdiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or -math.floor(-q)
end

-- pokeemerald/src/contest_util.c:1694
function Util.resultsData(c)
  c = c or Util.current()
  local N = Contest.CONTESTANT_COUNT
  local highest = c.totals[0]
  for i = 1, N - 1 do if highest < c.totals[i] then highest = c.totals[i] end end
  if highest < 0 then
    highest = c.totals[0]
    for i = 1, N - 1 do if highest > c.totals[i] then highest = c.totals[i] end end
  end
  local out = {}
  local denom = math.abs(highest)
  for i = 0, N - 1 do
    local r = {}
    local rel = denom ~= 0 and tdiv(c.round1[i] * 1000, denom) or 0
    if rel % 10 > 4 then rel = rel + 10 end
    r.relativePreliminaryPoints = tdiv(rel, 10)
    rel = denom ~= 0 and tdiv(math.abs(c.round2[i]) * 1000, denom) or 0
    if rel % 10 > 4 then rel = rel + 10 end
    r.relativeRound2Points = tdiv(rel, 10)
    r.lostPoints = c.round2[i] < 0
    local bar = math.floor(r.relativePreliminaryPoints * 0x5800 / 100) % 4294967296
    if bar % 256 > 0x7F then bar = bar + 0x100 end
    r.barLengthPreliminary = math.floor(bar / 256) % 256
    bar = math.floor(r.relativeRound2Points * 0x5800 / 100) % 4294967296
    if bar % 256 > 0x7F then bar = bar + 0x100 end
    r.barLengthRound2 = math.floor(bar / 256) % 256
    r.numStars = Util.preliminaryStars(c, i, true)
    r.numHearts = math.abs(Util.round2Hearts(c, i, true))
    if c.standings[i] ~= 0 then
      local pre, r2 = r.barLengthPreliminary, r.barLengthRound2
      if r.lostPoints then r2 = -r2 end
      if pre + r2 == Util.MAX_BAR_LENGTH then
        if r2 > 0 then r.barLengthRound2 = r.barLengthRound2 - 1
        elseif pre > 0 then r.barLengthPreliminary = r.barLengthPreliminary - 1 end
      end
    end
    out[i] = r
  end
  return out
end

-- pokeemerald/src/contest_util.c:2396
function Util.contestantAtConditionRank(c, rankIn)
  local N = Contest.CONTESTANT_COUNT
  local cond = {}
  for i = 0, N - 1 do cond[i] = c.round1[i] end
  for i = 0, N - 2 do
    for j = N - 1, i + 1, -1 do
      if cond[j - 1] < cond[j] then cond[j], cond[j - 1] = cond[j - 1], cond[j] end
    end
  end
  local condition = cond[rankIn]
  local numAt, tieRank = 0, 0
  for i = 0, N - 1 do
    if cond[i] == condition then
      numAt = numAt + 1
      if i == rankIn then tieRank = numAt end
    end
  end
  local rank = 0
  while rank < N and cond[rank] ~= condition do rank = rank + 1 end
  local offset, who = tieRank, 0
  while who < N do
    if condition == c.round1[who] then
      if offset == 1 then break end
      offset = offset - 1
    end
    who = who + 1
  end
  local adjusted
  if numAt == 1 or tieRank == numAt then adjusted = rank else adjusted = rank + N end
  return who, adjusted
end

-- pokeemerald/src/contest_util.c:2680
function Util.generateContestRand(c, modulo)
  modulo = num(modulo)
  if modulo == 0 then return 0 end
  return c:random() % modulo
end

function Util.monName(m)
  local v = m and m.nickname
  if type(v) == "string" then return v end
  if type(v) == "table" then return Util.decode(v) end
  return ""
end

function Util.trainerName(m)
  local v = m and m.trainerName
  if type(v) == "string" then return v end
  if type(v) == "table" then return Util.decode(v) end
  return ""
end

function Util.decode(bytes)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local list = {}
  for i = 1, #bytes do list[i] = bytes[i] end
  if #list == 0 or list[#list] ~= 0xFF then list[#list + 1] = 0xFF end
  return TextIR.toPlain(TextIR.decode(list, { dialect = TextIR.dialectOf() }), {})
end

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  SaveSections.register("contests", SaveSections.fields({ "contestWinners", "contestLinkResults" }, function(session)
    local ok = pcall(Util.clearAllWinners, session)
    if not ok then session.contestWinners = nil end
    local r = {}
    for cat = 0, 4 do r[cat + 1] = { 0, 0, 0, 0 } end
    session.contestLinkResults = r
  end))
end

return Util
