local Rng = require("src.core.game3.rng")
local bit = require("bit")

local ContestLink = {}

ContestLink.MSG = { BLOCK = "game3_contest_block", ABORT = "game3_contest_abort" }
-- pokeemerald/include/constants/contest.h:11
ContestLink.FLAG = { IS_LINK = 1, IS_WIRELESS = 2, HAS_RS_PLAYER = 4 }
-- pokeemerald/include/link.h:105
ContestLink.LINKTYPE = { GMODE = 0x6601, EMODE = 0x6602 }
-- pokeemerald/include/constants/union_room.h:73
ContestLink.WIRES = { [0] = "contest_cool", "contest_beauty", "contest_cute", "contest_smart", "contest_tough" }
ContestLink.LINK_GROUP_COOL = 15
ContestLink.RESULT = { OK = 0, DIFF_CONTEST = 1, ERROR = 2 }
ContestLink.WAIT_TICKS = 3600
-- pokeemerald/src/contest_link_util.c:246
ContestLink.LEADER_ID = 0x6E
ContestLink.CONTESTANT_COUNT = 4

ContestLink.active = nil
ContestLink.wireless = false

local N = ContestLink.CONTESTANT_COUNT
local U32 = 4294967296

-- pokeemerald/include/random.h:16
function ContestLink.newRng(seed)
  local r = { state = math.floor(tonumber(seed) or 0) % U32 }
  function r.next()
    r.state = (Rng.mulU32(r.state, 1103515245) + 24691) % U32
    return math.floor(r.state / 65536)
  end
  return r
end

local function linkSeat(link)
  if type(link.getSeat) == "function" then return tonumber(link:getSeat()) or 0 end
  return tonumber(link.seat) or 0
end

local function linkCount(link)
  if type(link.players) == "function" then
    local ok, list = pcall(link.players, link)
    if ok and type(list) == "table" and #list > 0 then return #list end
  end
  if type(link.seatCount) == "function" then return tonumber(link:seatCount()) or 2 end
  return tonumber(link.nseats) or 2
end

local Session = {}
Session.__index = Session
ContestLink.Session = Session

function ContestLink.newSession(link, opts)
  opts = opts or {}
  local self = setmetatable({
    link = link,
    seat = tonumber(opts.seat) or linkSeat(link),
    count = tonumber(opts.count) or linkCount(link),
    blocks = {},
    sent = {},
    standbyN = 0,
    standbyKey = nil,
    waitKey = nil,
    waitTicks = 0,
    aborted = false,
    flags = tonumber(opts.flags) or ContestLink.FLAG.IS_LINK,
  }, Session)
  return self
end

function Session:isOpen()
  local lk = self.link
  return lk ~= nil and (lk.isOpen == nil or lk:isOpen()) and not self.aborted
end

function Session:isLeader()
  return self.seat == 0
end

function Session:pump()
  local lk = self.link
  if not lk then return end
  for _ = 1, 64 do
    local msg = lk:take(ContestLink.MSG.BLOCK)
    if not msg then break end
    local from, key = tonumber(msg.from), msg.key
    if from and type(key) == "string" then
      local row = self.blocks[key] or {}
      self.blocks[key] = row
      if row[from] == nil then row[from] = msg.data == nil and false or msg.data end
    end
  end
  if lk:take(ContestLink.MSG.ABORT) then self.aborted = true end
end

function Session:send(key, data)
  if self.sent[key] then return true end
  self.sent[key] = true
  local row = self.blocks[key] or {}
  self.blocks[key] = row
  row[self.seat] = data == nil and false or data
  if not self:isOpen() then return false end
  self.link:send({ type = ContestLink.MSG.BLOCK, key = key, from = self.seat, data = data })
  return true
end

function Session:abort()
  if self.link and (self.link.isOpen == nil or self.link:isOpen()) then
    self.link:send({ type = ContestLink.MSG.ABORT, from = self.seat })
  end
  self.aborted = true
end

function Session:waiting(key)
  self.waitTicks = self.waitKey == key and self.waitTicks + 1 or 1
  self.waitKey = key
  if not self:isOpen() then return nil, "closed" end
  if self.waitTicks > ContestLink.WAIT_TICKS then return nil, "timeout" end
  return nil
end

function Session:all(key)
  local row = self.blocks[key]
  if not row then return nil end
  for seat = 0, self.count - 1 do
    if row[seat] == nil then return nil end
  end
  return row
end

-- pokeemerald/src/contest_link.c:45
function Session:exchange(key, data)
  self:send(key, data)
  self:pump()
  local row = self:all(key)
  if row then
    self.waitKey, self.waitTicks = nil, 0
    return row
  end
  return self:waiting(key)
end

-- pokeemerald/src/contest_link.c:31
function Session:fromLeader(key, data)
  if self:isLeader() then self:send(key, data) end
  self:pump()
  local row = self.blocks[key]
  if row and row[0] ~= nil then
    self.waitKey, self.waitTicks = nil, 0
    return row[0]
  end
  return self:waiting(key)
end

-- pokeemerald/src/contest_util.c:2718
function Session:standby()
  if not self.standbyKey then
    self.standbyN = self.standbyN + 1
    self.standbyKey = "standby:" .. self.standbyN
  end
  local row, err = self:exchange(self.standbyKey, 1)
  if row or err then self.standbyKey = nil end
  if err then return nil, err end
  return row ~= nil
end

function ContestLink.packMon(m)
  local out = {}
  for k, v in pairs(m or {}) do
    if k ~= "moves" and type(v) ~= "table" and type(v) ~= "function" then out[k] = v end
  end
  local moves = m and m.moves or {}
  out.moves = { tonumber(moves[0]) or 0, tonumber(moves[1]) or 0, tonumber(moves[2]) or 0, tonumber(moves[3]) or 0 }
  return out
end

function ContestLink.unpackMon(w)
  local m = {}
  for k, v in pairs(type(w) == "table" and w or {}) do
    if k ~= "moves" then m[k] = v end
  end
  local mv = type(w) == "table" and type(w.moves) == "table" and w.moves or {}
  m.moves = { [0] = tonumber(mv[1]) or 0, tonumber(mv[2]) or 0, tonumber(mv[3]) or 0, tonumber(mv[4]) or 0 }
  m.aiFlags = 0
  m.isPlayer = nil
  return m
end

function ContestLink.digest(text)
  local h = 0x811C9DC5
  for i = 1, #text do
    h = bit.bxor(h, text:byte(i)) % U32
    h = Rng.mulU32(h, 0x01000193)
  end
  return string.format("%08x", h % U32)
end

function ContestLink.hash(c)
  local parts = {}
  for i = 0, N - 1 do
    local st = c.status[i]
    parts[#parts + 1] = table.concat({ st.pointTotal, st.appeal, st.ranking, st.prevMove, st.currMove,
      st.nervous, st.noMoreTurns, st.numTurnsSkipped, st.condition, c.turnOrder[i],
      c.results.turnOrder[i], c.round1[i] }, ",")
  end
  parts[#parts + 1] = tostring(c.contest.applauseLevel) .. "," .. tostring(c.contest.appealNumber)
  return ContestLink.digest(table.concat(parts, ";"))
end

function ContestLink.setupDigest(c)
  local parts = {}
  for i = 0, N - 1 do
    local m = c.mons[i] or {}
    parts[#parts + 1] = table.concat({ tonumber(m.species) or 0, c.round1[i], c.turnOrder[i] }, ",")
  end
  return ContestLink.digest(table.concat(parts, ";"))
end

-- pokeemerald/src/contest_link_util.c:37
local function highestRank(mon, category)
  local okR, Ribbons = pcall(require, "src.core.game3.rse.ribbons")
  local Contest = require("src.core.game3.rse.contest")
  local name = Contest.CATEGORY_NAMES[category]
  if not (okR and mon and name) then return 0 end
  local ok, v = pcall(Ribbons.get, mon, name)
  return ok and (tonumber(v) or 0) or 0
end
ContestLink.highestRank = highestRank

-- pokeemerald/src/contest_util.c:2164
function ContestLink.beginTransfer(opts)
  local Contest = require("src.core.game3.rse.contest")
  local job = {
    session = opts.session,
    stage = "entry",
    category = tonumber(opts.category) or 0,
    partyMon = opts.partyMon,
    contestant = opts.contestant,
    gameCleared = opts.gameCleared == true,
    data = opts.data,
    seed = opts.seed,
  }
  local sess = job.session
  -- pokeemerald/src/contest_link_util.c:58
  local mine = Contest.buildContestMon(job.contestant)
  mine.highestRank = highestRank(job.partyMon, job.category)
  mine.gameCleared = job.gameCleared and 1 or 0
  job.entry = { mon = ContestLink.packMon(mine), category = job.category, leaderId = ContestLink.LEADER_ID }

  function job:step()
    if self.result then return self.result end
    local s = self.session
    if self.stage == "entry" then
      local row, err = s:exchange("entry", self.entry)
      if err then self.result = ContestLink.RESULT.ERROR return self.result end
      if not row then return nil end
      self.entries = row
      self.stage = "rng"
    end
    if self.stage == "rng" then
      local seed = self.seed or (s:isLeader() and Rng.Random32() or nil)
      local got, err = s:fromLeader("rng", seed)
      if err then self.result = ContestLink.RESULT.ERROR return self.result end
      if got == nil then return nil end
      self.sharedSeed = math.floor(tonumber(got) or 0) % U32
      self:build()
      self.stage = "setup"
    end
    if self.stage == "setup" then
      local row, err = s:exchange("setup", self.digest)
      if err then self.result = ContestLink.RESULT.ERROR return self.result end
      if not row then return nil end
      for seat = 0, s.count - 1 do
        if row[seat] ~= self.digest then
          self.result = ContestLink.RESULT.ERROR
          return self.result
        end
      end
      self.result = self.diffCategory and ContestLink.RESULT.DIFF_CONTEST or ContestLink.RESULT.OK
    end
    return self.result
  end

  -- pokeemerald/src/contest_link_util.c:78
  function job:build()
    local s = self.session
    local n = s.count
    local categories, diff = {}, false
    for i = 0, n - 1 do
      categories[i] = tonumber(self.entries[i] and self.entries[i].category) or -1
      if categories[i] ~= categories[0] then diff = true end
    end
    self.diffCategory = diff
    local engineRng = ContestLink.newRng(self.sharedSeed)
    local contestRng = ContestLink.newRng(self.sharedSeed)
    local c = Contest.new({
      data = self.data,
      category = categories[0],
      rank = Contest.RANK.MASTER,
      linkFlags = s.flags,
      rng = engineRng.next,
      playerIndex = s.seat,
    })
    for i = 0, n - 1 do
      c.mons[i] = ContestLink.unpackMon(self.entries[i] and self.entries[i].mon)
    end
    c.mons[s.seat].isPlayer = true
    if n < N then
      local rank = tonumber(c.mons[0].highestRank) or 0
      local cleared = true
      for i = 0, n - 1 do
        local r = tonumber(c.mons[i].highestRank) or 0
        if r > rank then rank = r end
        if (tonumber(c.mons[i].gameCleared) or 0) == 0 then cleared = false end
      end
      if rank > 0 then rank = rank - 1 end
      c:setLinkAIContestants(n, rank, cleared, contestRng.next)
    end
    -- pokeemerald/src/contest_link_util.c:141
    c:calculateRound1Points()
    -- pokeemerald/src/contest_link_util.c:147
    c:sortContestants(false)
    c.link = s
    c.linkPlayers = n
    s.contestRng = contestRng
    s.engineRng = engineRng
    self.contest = c
    self.digest = ContestLink.setupDigest(c)
  end

  return job
end

-- pokeemerald/src/contest.c:1632
function ContestLink.exchangeMoves(c, move)
  local s = c.link
  if not s then return nil, "no_link" end
  local key = "move:" .. tostring(c.contest.appealNumber)
  local row, err = s:exchange(key, { move = tonumber(move) or 0, hash = ContestLink.hash(c) })
  if err then return nil, err end
  if not row then return nil end
  local moves, mine = {}, ContestLink.hash(c)
  for seat = 0, s.count - 1 do
    local r = row[seat]
    moves[seat] = type(r) == "table" and tonumber(r.move) or 0
    if type(r) == "table" and r.hash ~= mine and not c.linkDesync then
      c.linkDesync = { round = c.contest.appealNumber, seat = seat }
      print(string.format("[contest link] desync round=%d seat=%d", c.contest.appealNumber, seat))
    end
  end
  return moves
end

-- pokeemerald/src/contest_link.c:307
function ContestLink.exchangeFinalStandings(c)
  local s = c.link
  if not s then return true end
  local function list(t)
    return { tonumber(t[0]) or 0, tonumber(t[1]) or 0, tonumber(t[2]) or 0, tonumber(t[3]) or 0 }
  end
  local row, err = s:exchange("final", { totals = list(c.totals), appealTotals = list(c.appealTotals),
    round2 = list(c.round2), standings = list(c.standings) })
  if err then return nil, err end
  if not row then return nil end
  local lead = row[0]
  if type(lead) == "table" then
    for _, key in ipairs({ "totals", "appealTotals", "round2", "standings" }) do
      local src = type(lead[key]) == "table" and lead[key] or {}
      for i = 0, N - 1 do c[key][i] = tonumber(src[i + 1]) or c[key][i] end
    end
  end
  return true
end

function ContestLink.close(reason)
  local s = ContestLink.active
  ContestLink.active = nil
  local okL, Link = pcall(require, "src.core.game3.link.init")
  if okL and Link and Link.closeLink then Link.closeLink(reason or "contest_done") end
  return s ~= nil
end

function ContestLink.reset()
  ContestLink.active = nil
  ContestLink.wireless = false
end

-- pokeemerald/src/union_room.c:375
function ContestLink.onLinked()
  ContestLink.wireless = true
  return false
end

function ContestLink.registerGroups()
  local okG, RseGroups = pcall(require, "src.core.game3.link.rse_groups")
  if not (okG and RseGroups and RseGroups.register) then return false end
  for _, wire in pairs(ContestLink.WIRES) do
    RseGroups.register(wire, {
      linkType = ContestLink.LINKTYPE.EMODE,
      onLinked = function(ctx, adapters, link) return ContestLink.onLinked(ctx, adapters, link) end,
    })
  end
  return true
end

ContestLink.registerGroups()

return ContestLink
