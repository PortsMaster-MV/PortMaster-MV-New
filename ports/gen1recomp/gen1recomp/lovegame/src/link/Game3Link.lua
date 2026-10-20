local Handshake = require("src.link.Handshake")
local Session = require("src.link.Session")
local VersionsGame = require("src.import.gba.versions_game")
local Fingerprint = require("src.link.Fingerprint")

local Game3Link = {}
Game3Link.__index = Game3Link

-- pokefirered/include/link.h:88
Game3Link.LINKTYPE = {
  TRADE = 0x1111,
  TRADE_CONNECTING = 0x1122,
  TRADE_SETUP = 0x1133,
  TRADE_DISCONNECTED = 0x1144,
  BATTLE = 0x2211,
  SINGLE_BATTLE = 0x2233,
  DOUBLE_BATTLE = 0x2244,
  MULTI_BATTLE = 0x2255,
  BERRY_BLENDER_SETUP = 0x4411,
  BERRY_BLENDER = 0x4422,
  BATTLE_TOWER = 0x2288,
  RECORD_MIX_BEFORE = 0x3311,
  RECORD_MIX_AFTER = 0x3322,
  MYSTERY_EVENT = 0x5501,
}

Game3Link.GENERATION = 3
Game3Link.HANDSHAKE_SECONDS = 10
Game3Link.BYE = "game3_bye"
Game3Link.EXIT = "game3_exit_link_room"
Game3Link.HELLO = "game3_hello"
Game3Link.SEAT_ROLES = { [0] = "host", [1] = "guest", [2] = "seat2", [3] = "seat3", [4] = "seat4" }

-- pokefirered/src/link.c:343 InitLocalLinkPlayer
local function localPlayer(game)
  local rt = package.loaded["src.core.game3.runtime"]
  local s = rt and rt.getSession and rt.getSession()
  local name = s and (s.name or s.playerName)
  if type(name) ~= "string" or name == "" then
    name = game and game.save and game.save.player and game.save.player.name or nil
  end
  return name, require("src.core.game3.link.family").trainerId(s),
    (s and (s.gender == "female" or s.gender == 1)) and 1 or 0
end

local function handshakeView(game)
  if type(game) ~= "table" then return nil end
  return { data = game.data, save = game.save, mods = game.mods }
end

local function family()
  return require("src.core.game3.link.family")
end

local function gameVersionOf(game, player)
  local Family = family()
  local v = type(player) == "table" and player.version or nil
  if type(v) ~= "string" and type(game) == "table" then
    v = game.version or (type(game.session) == "table" and game.session.version)
      or (type(game.save) == "table" and game.save.version)
  end
  if Family.isGame3(v) then return v end
  return Family.activeVersion()
end

local function localSession(game)
  local rt = package.loaded["src.core.game3.runtime"]
  local s = rt and rt.getSession and rt.getSession()
  if type(s) == "table" then return s end
  if type(game) == "table" then return game.session or game.save end
  return nil
end

Game3Link.BATTLE_TYPES = {
  [Game3Link.LINKTYPE.BATTLE] = true,
  [Game3Link.LINKTYPE.SINGLE_BATTLE] = true,
  [Game3Link.LINKTYPE.DOUBLE_BATTLE] = true,
  [Game3Link.LINKTYPE.MULTI_BATTLE] = true,
}

Game3Link.TRADE_TYPES = {
  [Game3Link.LINKTYPE.TRADE] = true,
  [Game3Link.LINKTYPE.TRADE_CONNECTING] = true,
  [Game3Link.LINKTYPE.TRADE_SETUP] = true,
  [Game3Link.LINKTYPE.TRADE_DISCONNECTED] = true,
}

function Game3Link.rules(version)
  local ok, value = pcall(Fingerprint.rulesGen3, version)
  return ok and value or nil
end

local function helloFor(game, linkType, player)
  local hello = Handshake.hello(handshakeView(game), nil)
  hello.generation = Game3Link.GENERATION
  hello.type = Game3Link.HELLO
  hello.ruleset = Handshake.DEFAULT_RULESET
  local name, trainerId, gender = localPlayer(game)
  if type(player) == "table" then
    if player.name ~= nil then name = player.name end
    if player.trainerId ~= nil then trainerId = tonumber(player.trainerId) or 0 end
    if player.gender ~= nil then gender = (player.gender == 1 or player.gender == "female") and 1 or 0 end
  end
  hello.name = name
  local version = gameVersionOf(game, player)
  local mod = VersionsGame.game(version)
  local Family = family()
  local lp = Family.localLinkPlayer(type(player) == "table" and player.session or localSession(game), version)
  if type(player) == "table" and player.progressFlags ~= nil then
    lp.progressFlags = tonumber(player.progressFlags) or 0
  end
  hello.game3 = {
    cacheVersion = mod.CACHE_VERSION,
    nativeVersion = mod.NATIVE_VERSION,
    linkType = tonumber(linkType),
    trainerId = trainerId,
    gender = gender,
    version = version,
    family = Family.of(version),
    gameVersion = lp.version,
    progressFlags = lp.progressFlags,
    language = lp.language,
    rules = Game3Link.rules(version),
  }
  local data = type(game) == "table" and game.data or nil
  if type(data) == "table" and Fingerprint.generationOf(data) == 3 then
    local okC, core = pcall(Fingerprint.coreGen3, data, hello.mods)
    local okM, moves = pcall(Fingerprint.movesGen3, data)
    hello.game3.core = okC and core or nil
    hello.game3.moves = okM and moves or nil
  end
  return hello
end

Game3Link.hello = helloFor

local function transportSeat(transport)
  if type(transport) == "table" and type(transport.seat) == "function" then
    local ok, s = pcall(transport.seat, transport)
    if ok then return tonumber(s) end
  end
  return nil
end

local function transportSeats(transport)
  if type(transport) == "table" and type(transport.seats) == "function" then
    local ok, n = pcall(transport.seats, transport)
    if ok then return tonumber(n) end
  end
  return nil
end

function Game3Link.attach(transport, opts)
  opts = opts or {}
  local seat = tonumber(opts.seat) or transportSeat(transport)
  if seat == nil then seat = opts.role == "guest" and 1 or 0 end
  local seats = tonumber(opts.seats) or transportSeats(transport) or 2
  local role = seat == 0 and "host" or "guest"
  local self = setmetatable({
    role = role,
    seat = seat,
    nseats = seats,
    linkType = tonumber(opts.linkType) or Game3Link.LINKTYPE.BATTLE,
    game = opts.game,
    state = "handshake",
    elapsed = 0,
    closed = false,
    onReady = opts.onReady,
    onClosed = opts.onClosed,
    timeout = tonumber(opts.timeout) or Game3Link.HANDSHAKE_SECONDS,
    peerHellos = {},
    peerHello = nil,
    departed = {},
    _transport = transport,
    _session = Session.new(transport, { role = role, kind = "game3" }),
  }, Game3Link)
  local hello = opts.hello
  if type(hello) == "table" then
    local copy = {}
    for k, v in pairs(hello) do copy[k] = v end
    copy.game3 = {}
    for k, v in pairs(type(hello.game3) == "table" and hello.game3 or {}) do copy.game3[k] = v end
    hello = copy
  else
    hello = helloFor(opts.game, self.linkType)
  end
  hello.type = Game3Link.HELLO
  hello.generation = Game3Link.GENERATION
  hello.game3 = hello.game3 or {}
  hello.game3.seat = seat
  if hello.game3.linkType == nil then hello.game3.linkType = self.linkType end
  self.myHello = hello
  self._session:send(self.myHello)
  return self
end

function Game3Link.loopback(opts)
  opts = opts or {}
  local Net = require("src.link.Net")
  local a, b = Net.loopbackPair()
  local host = Game3Link.attach(a, {
    seat = 0, seats = 2, game = opts.game, linkType = opts.linkType,
    timeout = opts.timeout, onReady = opts.onHostReady, onClosed = opts.onHostClosed,
  })
  local guest = Game3Link.attach(b, {
    seat = 1, seats = 2, game = opts.game, linkType = opts.linkType,
    timeout = opts.timeout, onReady = opts.onGuestReady, onClosed = opts.onGuestClosed,
  })
  return host, guest
end

function Game3Link:isOpen()
  return not self.closed
end

function Game3Link:isReady()
  return self.state == "ready" and not self.closed
end

function Game3Link:getStatus()
  return self.state
end

function Game3Link:getSeat()
  return self.seat
end

function Game3Link:seatCount()
  return self.nseats
end

function Game3Link:peerName()
  return self.peerHello and self.peerHello.name or nil
end

function Game3Link:peerLinkType()
  local g3 = self.peerHello and self.peerHello.game3
  return g3 and tonumber(g3.linkType) or nil
end

local function row(hello, seat, isLocal)
  local g3 = type(hello) == "table" and type(hello.game3) == "table" and hello.game3 or {}
  return {
    name = hello and hello.name,
    trainerId = tonumber(g3.trainerId) or 0,
    language = tonumber(g3.language) or 2,
    gender = tonumber(g3.gender) or 0,
    version = g3.version,
    role = Game3Link.SEAT_ROLES[seat] or "guest",
    seat = seat,
    isLocal = isLocal,
  }
end

-- pokefirered/src/link.c:1069 GetLinkPlayerCount_2
function Game3Link:players()
  local list = { row(self.myHello, self.seat, true) }
  for seat, hello in pairs(self.peerHellos) do
    list[#list + 1] = row(hello, seat, false)
  end
  table.sort(list, function(a, b) return a.seat < b.seat end)
  return list
end

function Game3Link:send(message)
  if self.closed or type(message) ~= "table" then return false end
  self._session:send(message)
  return true
end

function Game3Link:take(messageType, predicate)
  return self._session:take(messageType, predicate)
end

function Game3Link:poll()
  return self._session:poll()
end

function Game3Link:peerGone()
  local t = self._transport
  if not t then return true end
  if t.closed == true or t.error then return true end
  if t.peerEnd and t.peerEnd.closed == true then return true end
  local status = self._session:getStatus()
  return status == "closed" or status == "failed"
end

function Game3Link:_finish(state, reason)
  if self.closed then return false end
  self.closed = true
  self.state = state
  self.reason = reason
  self._session:close()
  local cb = self.onClosed
  if cb then cb(reason, state) end
  return true
end

-- pokefirered/src/link.c:419 CloseLink
function Game3Link:close(reason)
  if self.closed then return false end
  pcall(function()
    self._session:send({ type = Game3Link.BYE, seat = self.seat, reason = tostring(reason or "bye") })
  end)
  return self:_finish("closed", reason or "close_link")
end

-- pokeemerald/src/overworld.c:2411
function Game3Link:depart(seat)
  seat = tonumber(seat)
  if seat == nil or seat < 0 or seat == self.seat or self.departed[seat] then return false end
  self.departed[seat] = true
  self.peerHellos[seat] = nil
  self.peerHello = self:_primaryHello()
  local t = self._transport
  if type(t) == "table" and type(t.forgetSeat) == "function" then pcall(t.forgetSeat, t, seat) end
  return true
end

function Game3Link:leave(keepRoom)
  local t = self._transport
  if type(t) == "table" and type(t.leave) == "function" then
    pcall(t.leave, t, keepRoom)
    return true
  end
  return false
end

local function stampsMatch(g3, id)
  local ok, mod = pcall(VersionsGame.game, id)
  return ok and type(mod) == "table" and tonumber(g3.cacheVersion) == mod.CACHE_VERSION
    and tonumber(g3.nativeVersion) == mod.NATIVE_VERSION
end

local function helloVersion(g3, mine)
  if type(g3) ~= "table" then return "firered" end
  if type(g3.version) == "string" then return g3.version end
  local own = type(mine) == "table" and mine.version
  if type(own) == "string" and stampsMatch(g3, own) then return own end
  local GameVersion = require("src.core.GameVersion")
  for _, id in ipairs(GameVersion.ORDER) do
    if VersionsGame.GAMES[id] and family().isGame3(id) and stampsMatch(g3, id) then return id end
  end
  return "firered"
end

local function helloFamily(g3, mine)
  if type(g3) == "table" and type(g3.family) == "string" then return g3.family end
  return family().of(helloVersion(g3, mine))
end

local function helloRules(g3, mine)
  if type(g3) == "table" and g3.rules ~= nil then return g3.rules end
  return Game3Link.rules(helloVersion(g3, mine))
end

function Game3Link.peerVersionOf(myHello, peer)
  return helloVersion(peer and peer.game3, myHello and myHello.game3)
end

function Game3Link.crossFamily(myHello, peer)
  local mine = myHello and myHello.game3
  return helloFamily(mine) ~= helloFamily(peer and peer.game3, mine)
end

local function decideOne(myHello, peer, linkType)
  local g3 = peer and peer.game3
  if type(g3) ~= "table" then
    return "refused", "peer_is_not_firered"
  end
  local Family = family()
  if tonumber(linkType) == Game3Link.LINKTYPE.MYSTERY_EVENT then
    if not Family.isRubySapphire(helloVersion(myHello and myHello.game3))
        or not Family.isRubySapphire(helloVersion(g3, myHello and myHello.game3))
        or tonumber((myHello.game3 or {}).language) ~= tonumber(g3.language) then
      return "refused", "activity_unavailable"
    end
  end
  if tonumber(linkType) == Game3Link.LINKTYPE.BATTLE_TOWER
      and (Family.isRubySapphire(helloVersion(myHello and myHello.game3))
        or Family.isRubySapphire(helloVersion(g3, myHello and myHello.game3))) then
    return "refused", "activity_unavailable"
  end
  local verdict, reason = Handshake.checkCompat(myHello, peer)
  local cross, hostRules = false, false
  local modified = (myHello and myHello.linkModified) or peer.linkModified
  local battle = Game3Link.BATTLE_TYPES[tonumber(linkType) or -1]
  local mine = myHello and myHello.game3
  if verdict == "subset" and not modified and type(mine) == "table"
      and helloVersion(mine) ~= helloVersion(g3, mine)
      and Game3Link.TRADE_TYPES[tonumber(linkType) or -1] then
    cross = true
  elseif verdict == "subset" and not modified and battle and type(mine) == "table"
      and mine.core ~= nil and mine.core == g3.core
      and tostring(myHello.ruleset or Handshake.DEFAULT_RULESET) == tostring(peer.ruleset or Handshake.DEFAULT_RULESET) then
    hostRules = true
    cross = Game3Link.crossFamily(myHello, peer)
  elseif verdict ~= "full" then
    return "refused", reason or verdict
  end
  local peerVersion = helloVersion(g3, mine)
  local ok, mod = pcall(VersionsGame.game, peerVersion)
  if not (ok and type(mod) == "table" and family().isGame3(peerVersion)) then
    return "refused", "unknown_game_version"
  end
  if tonumber(g3.cacheVersion) ~= mod.CACHE_VERSION then
    return "refused", "cache_version_mismatch"
  end
  if tonumber(g3.nativeVersion) ~= mod.NATIVE_VERSION then
    return "refused", "native_version_mismatch"
  end
  if battle and helloRules(mine) ~= helloRules(g3, mine) then
    if modified then return "refused", "rules_mismatch" end
    hostRules = true
    cross = Game3Link.crossFamily(myHello, peer)
  end
  return "full", nil, cross, hostRules
end

Game3Link.decideOne = decideOne

function Game3Link:decide()
  local linkType = self.linkType
  if next(self.peerHellos) == nil then
    local verdict, reason, cross, hostRules = decideOne(self.myHello, self.peerHello, linkType)
    self.crossVersion = cross == true
    self.hostRules = hostRules == true
    return verdict, reason
  end
  local seats = {}
  for seat in pairs(self.peerHellos) do seats[#seats + 1] = seat end
  table.sort(seats)
  local anyCross, anyHost = false, false
  for _, seat in ipairs(seats) do
    local verdict, reason, cross, hostRules = decideOne(self.myHello, self.peerHellos[seat], linkType)
    if verdict ~= "full" then return verdict, reason end
    anyCross = anyCross or cross == true
    anyHost = anyHost or hostRules == true
  end
  self.crossVersion = anyCross
  self.hostRules = anyHost
  return "full", nil
end

-- pokeemerald/src/battle_controllers.c:397
function Game3Link:hostGame3()
  local hello = self.seat == 0 and self.myHello or self.peerHellos[0] or self.peerHello
  return hello and hello.game3 or nil
end

function Game3Link:peerGame()
  local g3 = self.peerHello and self.peerHello.game3
  if type(g3) ~= "table" then return nil end
  local mine = self.myHello and self.myHello.game3
  return {
    version = helloVersion(g3, mine),
    family = helloFamily(g3, mine),
    gameVersion = tonumber(g3.gameVersion),
    progressFlags = tonumber(g3.progressFlags) or 0,
  }
end

function Game3Link:_helloSeat(hello)
  local s = tonumber(hello.seat)
  if s == nil or s < 0 then
    local g3 = type(hello.game3) == "table" and hello.game3 or {}
    s = tonumber(g3.seat)
  end
  if s == nil or s < 0 or s == self.seat then
    if self.nseats <= 2 then return 1 - (self.seat == 1 and 1 or 0) end
    return nil
  end
  return s
end

function Game3Link:_allHellos()
  local n = 0
  for _ in pairs(self.peerHellos) do n = n + 1 end
  return n >= self.nseats - 1
end

function Game3Link:_primaryHello()
  if self.seat ~= 0 and self.peerHellos[0] then return self.peerHellos[0] end
  local best
  for seat, hello in pairs(self.peerHellos) do
    if best == nil or seat < best then best = seat end
  end
  return best ~= nil and self.peerHellos[best] or nil
end

function Game3Link:update(dt)
  if self.closed then return self.state end
  self.elapsed = self.elapsed + (tonumber(dt) or 0)
  self._session:update()

  local exit = self._session:take(Game3Link.EXIT)
  while exit do
    self:depart(exit.seat)
    exit = self._session:take(Game3Link.EXIT)
  end
  local departed = self.departed
  while self._session:take(Game3Link.BYE, function(m) return departed[tonumber(m.seat)] == true end) do end

  if self._session:take(Game3Link.BYE) then
    self:_finish("closed", "peer_left")
    return self.state
  end

  if self.state == "handshake" then
    local hello = self._session:take(Game3Link.HELLO) or self._session:take("hello")
    while hello do
      local seat = self:_helloSeat(hello)
      if seat ~= nil and not self.departed[seat] then self.peerHellos[seat] = hello end
      hello = self._session:take(Game3Link.HELLO)
    end
    self.peerHello = self:_primaryHello()
    if self.peerHello and self:_allHellos() then
      local verdict, reason = self:decide()
      self.verdict = verdict
      if verdict == "full" then
        self.state = "ready"
        local cb = self.onReady
        if cb then cb(self) end
      else
        self:close(reason or "refused")
        return self.state
      end
    end
  end

  if self:peerGone() then
    self:_finish("failed", self.peerHello and "peer_dropped" or "no_peer")
    return self.state
  end

  if self.state == "handshake" and self.timeout > 0 and self.elapsed >= self.timeout then
    self:_finish("failed", "handshake_timeout")
  end
  return self.state
end

return Game3Link
