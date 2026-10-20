local bit = require("bit")
local band, rshift = bit.band, bit.rshift

local Tasks = require("src.core.game3.gba_tasks")

local RsPolicy = require("src.core.game3.rs.berry_blender_policy")
local CacheBlob = require("src.import.CacheBlob")
local Blender = {}
Blender.__index = Blender

-- pokeemerald/src/berry_blender.c:79
Blender.MAX_PLAYERS = 4
Blender.NO_PLAYER = 0xFF
Blender.MAX_PROGRESS_BAR = 1000
Blender.MAX_ARROW_POS = 0x10000
Blender.MIN_ARROW_SPEED = 0x80
Blender.ARROW_FALL_ROTATION = 0x5800
-- pokeemerald/src/berry_blender.c:2216
Blender.MAX_GAME_TIME = (99 * 60 * 60) + (59 * 60)

-- pokeemerald/src/berry_blender.c:42
Blender.SCORE = { BEST = 0, GOOD = 1, MISS = 2 }
Blender.NUM_SCORE_TYPES = 3
-- pokeemerald/src/berry_blender.c:50
Blender.PROXIMITY = { MISS = 0, GOOD = 1, BEST = 2 }
-- pokeemerald/src/berry_blender.c:56
Blender.SCOREANIM = { GOOD = 0, MISS = 1, BEST_FLASH = 2, BEST_STATIC = 3 }
-- pokeemerald/src/berry_blender.c:63
Blender.PLAY_AGAIN = { YES = 0, NO = 1, CANT_PLAY_NO_BERRIES = 2, CANT_PLAY_NO_PKBLCK_SPACE = 3 }
-- pokeemerald/src/berry_blender.c:70
Blender.NAME = { MISTER = 0, LADDIE = 1, LASSIE = 2, MASTER = 3, DUDE = 4, MISS = 5 }

-- pokeemerald/include/link.h:52
Blender.CMD = {
  BEST = 0x4523, GOOD = 0x5432, MISS = 0x2345, SEND_KEYS = 0x4444,
}
-- pokeemerald/include/berry_blender.h:5
local COMM_INPUT_STATE, COMM_SCORE = 0, 2

-- pokeemerald/include/constants/berry.h:13
Blender.FLAVOR_COUNT = 5
-- pokeemerald/include/pokeblock.h:6
Blender.COLOR = {
  NONE = 0, RED = 1, BLUE = 2, PINK = 3, GREEN = 4, YELLOW = 5, PURPLE = 6, INDIGO = 7,
  BROWN = 8, LITE_BLUE = 9, OLIVE = 10, GRAY = 11, BLACK = 12, WHITE = 13, GOLD = 14,
}
-- pokeemerald/include/constants/game_stat.h:37
Blender.GAME_STAT_POKEBLOCKS = 33
Blender.GAME_STAT_POKEBLOCKS_WITH_FRIENDS = 34

Blender.MANIFEST = "data/generated/gba/rse/berry_blender/manifest.lua"
Blender.BERRIES = "data/generated/gba/berries/berries.lua"

local function u16(v) return band(v, 0xFFFF) end
local function s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end
local function u8(v) return band(v, 0xFF) end
local function cdiv(a, b)
  local q = a / b
  if q >= 0 then return math.floor(q) end
  return math.ceil(q)
end
Blender.cdiv = cdiv

local function readCache(path)
  local okD, Dataset = pcall(require, "src.core.game3.dataset")
  if okD and Dataset and Dataset.cache then
    local okR, s = pcall(function() return Dataset.cache():read(path) end)
    if okR and s then return s end
  end
  if love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
    return CacheBlob.readFs(path)
  end
  return nil
end

local function loadLua(path)
  local src = readCache(path)
  if type(src) ~= "string" then return nil end
  local chunk = load(src, "@" .. path, "t", {})
  if not chunk then return nil end
  local ok, t = pcall(chunk)
  return ok and type(t) == "table" and t or nil
end
Blender.loadLua = loadLua

local manifestCache, berriesCache

function Blender.manifest()
  if not manifestCache then
    manifestCache = assert(loadLua(Blender.MANIFEST), Blender.MANIFEST .. " is missing from the cache")
  end
  return manifestCache
end

function Blender.berriesPack()
  if not berriesCache then
    berriesCache = assert(loadLua(Blender.BERRIES), Blender.BERRIES .. " is missing from the cache")
  end
  return berriesCache
end

function Blender.resetCaches()
  manifestCache, berriesCache = nil, nil
end

local function constants(version)
  local Constants = require("src.core.game3.constants")
  return Constants.of(version or Constants.versionOf(Blender.session()))
end

function Blender.session(s)
  if s then return s end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

-- pokeemerald/include/constants/items.h:424
function Blender.itemIds(version)
  local C = constants(version)
  return {
    first = C:require("items", "ITEM_CHERI_BERRY"),
    aspear = C:require("items", "ITEM_ASPEAR_BERRY"),
    spelon = C:require("items", "ITEM_SPELON_BERRY"),
    enigma = C:require("items", "ITEM_ENIGMA_BERRY"),
  }
end

function Blender.defaultRandom()
  return require("src.core.game3.rng").Random()
end

-- pokeemerald/src/berry_blender.c:1210
function Blender.blenderBerry(itemId, berries, ids, session)
  local info = berries[itemId - ids.first] or {}
  if itemId == ids.enigma then info = require("src.core.game3.rs.enigma").info(session) or info end
  return {
    itemId = itemId,
    name = info.name or "",
    flavors = {
      [0] = info.spicy or 0, info.dry or 0, info.sweet or 0, info.bitter or 0, info.sour or 0,
      info.smoothness or 0,
    },
  }
end

-- pokeemerald/src/berry_blender.c:2246
local function berriesSame(berries, a, b)
  local x, y = berries[a], berries[b]
  if x.itemId ~= y.itemId then return true end
  if x.name ~= y.name then return false end
  for i = 0, Blender.FLAVOR_COUNT do
    if x.flavors[i] ~= y.flavors[i] then return false end
  end
  return true
end

-- pokeemerald/src/berry_blender.c:2263
function Blender.pokeblockColor(berries, flavors, numPlayers, negativeFlavors, ids)
  local C = Blender.COLOR
  local zeros = 0
  for i = 0, Blender.FLAVOR_COUNT - 1 do
    if flavors[i] == 0 then zeros = zeros + 1 end
  end
  if zeros == Blender.FLAVOR_COUNT or negativeFlavors > 3 then return C.BLACK end
  for i = 0, numPlayers - 1 do
    for j = 0, numPlayers - 1 do
      if berries[i].itemId == berries[j].itemId and i ~= j
        and (berries[i].itemId ~= ids.enigma or berriesSame(berries, i, j)) then
        return C.BLACK
      end
    end
  end
  local numFlavors = 0
  for i = 0, Blender.FLAVOR_COUNT - 1 do
    if flavors[i] > 0 then numFlavors = numFlavors + 1 end
  end
  if numFlavors > 3 then return C.WHITE end
  if numFlavors == 3 then return C.GRAY end
  for i = 0, Blender.FLAVOR_COUNT - 1 do
    if flavors[i] > 50 then return C.GOLD end
  end
  if numFlavors == 1 then
    if flavors[0] > 0 then return C.RED end
    if flavors[1] > 0 then return C.BLUE end
    if flavors[2] > 0 then return C.PINK end
    if flavors[3] > 0 then return C.GREEN end
    if flavors[4] > 0 then return C.YELLOW end
  end
  if numFlavors == 2 then
    local present = {}
    for i = 0, Blender.FLAVOR_COUNT - 1 do
      if flavors[i] > 0 then present[#present + 1] = i end
    end
    local byFlavor = { [0] = C.PURPLE, C.INDIGO, C.BROWN, C.LITE_BLUE, C.OLIVE }
    if flavors[present[1]] >= flavors[present[2]] then
      return byFlavor[present[1]]
    end
    return byFlavor[present[2]]
  end
  return C.NONE
end

-- pokeemerald/src/berry_blender.c:2387
function Blender.calculatePokeblock(berries, numPlayers, maxRPM, random, ids, blackFlags)
  local f = {}
  for i = 0, Blender.FLAVOR_COUNT do f[i] = 0 end
  for i = 0, numPlayers - 1 do
    for j = 0, Blender.FLAVOR_COUNT do f[j] = s16(f[j] + berries[i].flavors[j]) end
  end
  local first = f[0]
  f[0] = s16(f[0] - f[1])
  f[1] = s16(f[1] - f[2])
  f[2] = s16(f[2] - f[3])
  f[3] = s16(f[3] - f[4])
  f[4] = s16(f[4] - first)
  local negatives = 0
  for i = 0, Blender.FLAVOR_COUNT - 1 do
    if f[i] < 0 then
      f[i] = 0
      negatives = negatives + 1
    end
  end
  for i = 0, Blender.FLAVOR_COUNT - 1 do
    if f[i] > 0 then
      if f[i] < negatives then f[i] = 0 else f[i] = f[i] - negatives end
    end
  end
  local factor = math.floor(maxRPM / 333) + 100
  for i = 0, Blender.FLAVOR_COUNT - 1 do
    local flavor = cdiv(f[i] * factor, 10)
    local remainder = math.fmod(flavor, 10)
    flavor = cdiv(flavor, 10)
    if remainder > 4 then flavor = flavor + 1 end
    f[i] = s16(flavor)
  end
  local color = Blender.pokeblockColor(berries, f, numPlayers, u8(negatives), ids)
  f[5] = s16(cdiv(f[5], numPlayers) - numPlayers)
  if f[5] < 0 then f[5] = 0 end
  if color == Blender.COLOR.BLACK then
    local pick = (random() % #blackFlags) + 1
    local flags = blackFlags[pick]
    for i = 0, Blender.FLAVOR_COUNT - 1 do
      if band(rshift(flags, i), 1) == 1 then f[i] = 2 else f[i] = 0 end
    end
  end
  for i = 0, Blender.FLAVOR_COUNT do
    if f[i] > 255 then f[i] = 255 end
  end
  return {
    color = color, spicy = u8(f[0]), dry = u8(f[1]), sweet = u8(f[2]), bitter = u8(f[3]), sour = u8(f[4]),
    feel = u8(f[5]),
  }, { factor = factor, negatives = negatives }
end

-- pokeemerald/src/berry_blender.c:3347
function Blender.arrowSpeedToRPM(speed)
  return math.floor(60 * 60 * 100 * u16(speed) / Blender.MAX_ARROW_POS)
end

function Blender.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Blender)
  self.session = opts.session or require("src.core.game3.rs.enigma").session()
  self.T = opts.tables or Blender.manifest().tables
  self.random = opts.random or Blender.defaultRandom
  self.ids = opts.itemIds or Blender.itemIds(opts.version)
  self.berries = opts.berries or Blender.berriesPack().berries
  self.var8004 = opts.opponents or 1
  self.linked = opts.linked == true
  self.localPlayerId = tonumber(opts.localPlayerId) or 0
  self.nativeRS = RsPolicy.matches(opts.version or require("src.core.game3.profile").forSession().id)
  self.blendMaster = not self.nativeRS and opts.blendMaster and true or false
  self.names = opts.opponentNames or Blender.manifest().opponentNames
  self.playerName = opts.playerName or ""
  self.events = {}
  self.tasks = Tasks.new()
  self.arrowPos = 0
  self.speed = 0
  self.maxRPM = 0
  self.bg_X, self.bg_Y = 0, 0
  self.progressBarValue = 0
  self.maxProgressBarValue = 0
  self.gameFrameTime = 0
  self.slowdownTimer = 0
  self.gameEndState = 0
  self.framesToWait = 0
  self.centerScale = 80
  self.perfectOpponents = false
  self.opponentTaskIds = {}
  self.sendScore = 0
  self.recv = {}
  for i = 0, Blender.MAX_PLAYERS - 1 do
    self.recv[i] = { [0] = 0, 0, 0, 0, 0, 0, 0, 0 }
  end
  self.scores = {}
  for i = 0, Blender.MAX_PLAYERS - 1 do self.scores[i] = { [0] = 0, 0, 0 } end
  self.chosenItemId = { [0] = 0, 0, 0, 0 }
  self.blendedBerries = {}
  self.playerNames = {}
  self.arrowIdToPlayerId, self.playerIdToArrowId = {}, {}
  if self.linked then
    self.numPlayers = math.max(2, math.min(Blender.MAX_PLAYERS, tonumber(opts.numPlayers) or 2))
    self.playerNames = {}
    for i = 0, self.numPlayers - 1 do
      self.playerNames[i] = tostring(opts.playerNames and opts.playerNames[i + 1] or "")
    end
  else
    self:initLocalPlayers(self.var8004)
  end
  if opts.playerItem then self:setBerries(opts.playerItem) end
  return self
end

function Blender:emit(ev)
  self.events[#self.events + 1] = ev
  return ev
end

function Blender:takeEvents()
  local ev = self.events
  self.events = {}
  return ev
end

function Blender:rand()
  return band(self.random(), 0xFFFF)
end

-- pokeemerald/src/berry_blender.c:1224
function Blender:initLocalPlayers(n)
  if self.nativeRS then return RsPolicy.initLocalPlayers(self,n) end
  local N = Blender.NAME
  local nm = function(i) return self.names[i + 1] end
  local p = self.playerNames
  if n == 1 then
    self.numPlayers = 2
    p[0] = self.playerName
    p[1] = self.blendMaster and nm(N.MASTER) or nm(N.MISTER)
  elseif n == 2 then
    self.numPlayers = 3
    p[0], p[1], p[2] = self.playerName, nm(N.DUDE), nm(N.LASSIE)
  elseif n == 3 then
    self.numPlayers = 4
    p[0], p[1], p[2], p[3] = self.playerName, nm(N.MISS), nm(N.LADDIE), nm(N.LASSIE)
  end
end

-- pokeemerald/src/berry_blender.c:3214
function Blender:setPlayerBerryData(playerId, itemId)
  self.chosenItemId[playerId] = itemId
  self.blendedBerries[playerId] = Blender.blenderBerry(itemId, self.berries, self.ids, self.session)
end

-- pokeemerald/src/berry_blender.c:1542
function Blender:setOpponentsBerryData(playerItem, playersNum)
  local ids, T = self.ids, self.T
  local numNpc = ids.aspear - ids.first + 1
  local setId = 0
  if playerItem == ids.enigma then
    local fl = self.blendedBerries[0].flavors
    for i = 0, Blender.FLAVOR_COUNT - 1 do
      if fl[setId] > fl[i] then setId = i end
    end
    setId = setId + numNpc
  else
    setId = playerItem - ids.first
    if setId >= numNpc then setId = (setId % numNpc) + numNpc end
  end
  local nMaster = #T.berryMasterBerries
  for i = 0, playersNum - 2 do
    local opp = T.opponentBerrySets[setId + 1][i + 1]
    local diff = u16(playerItem - ids.spelon)
    if self.blendMaster and self.var8004 == 1 then
      setId = setId % nMaster
      opp = T.berryMasterBerries[setId + 1]
      if diff < nMaster then opp = opp - nMaster end
    end
    self:setPlayerBerryData(i + 1, opp + ids.first)
  end
end

-- pokeemerald/src/berry_blender.c:1641
function Blender:setBerries(playerItem)
  self:setPlayerBerryData(0, playerItem)
  self:setOpponentsBerryData(playerItem, self.numPlayers)
end

function Blender:setLinkBerries(items)
  if type(items) ~= "table" then return false end
  for playerId = 0, self.numPlayers - 1 do
    local itemId = tonumber(items[playerId]) or tonumber(items[playerId + 1])
    if not itemId or itemId <= 0 then return false end
    self:setPlayerBerryData(playerId, itemId)
  end
  return true
end

-- pokeemerald/src/berry_blender.c:1582
function Blender:setPlayerIdMaps()
  local map = self.T.playerIdMap[self.numPlayers - 1]
  for i = 0, Blender.MAX_PLAYERS - 1 do
    self.playerIdToArrowId[i] = Blender.NO_PLAYER
    self.arrowIdToPlayerId[i] = map[i + 1]
  end
  for j = 0, Blender.MAX_PLAYERS - 1 do
    for i = 0, Blender.MAX_PLAYERS - 1 do
      if self.arrowIdToPlayerId[i] == j then self.playerIdToArrowId[j] = i end
    end
  end
end

function Blender:arrowStartPos()
  local T = self.T
  return T.arrowStartPos[T.arrowStartPosIds[self.numPlayers - 1] + 1]
end

-- pokeemerald/src/berry_blender.c:1710
function Blender:beginFall()
  self.arrowPos = u16(self:arrowStartPos() - Blender.ARROW_FALL_ROTATION)
end

-- pokeemerald/src/berry_blender.c:1728
function Blender:fallFrame()
  self.arrowPos = u16(self.arrowPos + 0x200)
  self.centerScale = self.centerScale + 4
  if self.centerScale > 255 then
    self.centerScale = 256
    self.arrowPos = self:arrowStartPos()
    self.framesToWait = 0
    return true
  end
  return false
end

-- pokeemerald/src/berry_blender.c:3398
function Blender:landShakeCoord(coord, timer)
  local strength = timer < 10 and 16 or 8
  if coord == 0 then
    return s16((self:rand() % strength) - cdiv(strength, 2))
  end
  if coord < 0 then coord = coord + 1 end
  if coord > 0 then coord = coord - 1 end
  return coord
end

-- pokeemerald/src/berry_blender.c:3421
function Blender:landShakeFrame()
  if self.framesToWait == 0 then self.bg_X, self.bg_Y = 0, 0 end
  self.framesToWait = self.framesToWait + 1
  self.bg_X = self:landShakeCoord(self.bg_X, self.framesToWait)
  self.bg_Y = self:landShakeCoord(self.bg_Y, self.framesToWait)
  if self.framesToWait == 20 then
    self.bg_X, self.bg_Y = 0, 0
    return true
  end
  return false
end

-- pokeemerald/src/berry_blender.c:1525
function Blender:arrowProximity(arrowPos, playerId)
  local pos = math.floor(arrowPos / 256) + 24
  local arrowId = self.playerIdToArrowId[playerId]
  local start = self.T.arrowHitRangeStart[arrowId + 1]
  if pos >= start and pos < start + 48 then
    if pos >= start + 20 and pos < start + 28 then return Blender.PROXIMITY.BEST end
    return Blender.PROXIMITY.GOOD
  end
  return Blender.PROXIMITY.MISS
end

-- pokeemerald/src/berry_blender.c:1832
function Blender:createOpponentMissTask(playerId, delay)
  local id = self.tasks:create(function(tid, data)
    data[0] = data[0] + 1
    if data[0] > data[1] then
      self.recv[data[2]][COMM_SCORE] = Blender.CMD.MISS
      self.tasks:destroy(tid)
    end
  end, 80)
  local d = self.tasks:get(id).data
  d[1], d[2] = delay, playerId
end

local function randPct(self) return u8(math.floor(self:rand() / 655)) end

-- pokeemerald/src/berry_blender.c:1845
function Blender:opponent1(tid, data)
  local CMD = Blender.CMD
  if self:arrowProximity(self.arrowPos, 1) == Blender.PROXIMITY.BEST then
    if data[0] == 0 then
      if not self.perfectOpponents then
        local rand = randPct(self)
        if self.speed < 500 then
          self.recv[1][COMM_SCORE] = CMD.GOOD
        elseif self.speed < 1500 then
          if rand > 80 then
            self.recv[1][COMM_SCORE] = CMD.BEST
          else
            local value = u8(rand - 21)
            if value < 60 then
              self.recv[1][COMM_SCORE] = CMD.GOOD
            elseif rand < 10 then
              self:createOpponentMissTask(1, 5)
            end
          end
        elseif rand <= 90 then
          local value = u8(rand - 71)
          if value < 20 then
            self.recv[1][COMM_SCORE] = CMD.GOOD
          elseif rand < 30 then
            self:createOpponentMissTask(1, 5)
          end
        else
          self.recv[1][COMM_SCORE] = CMD.BEST
        end
      else
        self.recv[1][COMM_SCORE] = CMD.BEST
      end
      data[0] = 1
    end
  else
    data[0] = 0
  end
end

local function nearWindow(self, playerId)
  local var1 = u16(self.arrowPos + 0x1800)
  local arrowId = self.playerIdToArrowId[playerId]
  local start = self.T.arrowHitRangeStart[arrowId + 1]
  local hi = rshift(var1, 8)
  return hi > start + 20 and hi < start + 40
end

-- pokeemerald/src/berry_blender.c:1908
function Blender:opponent2(tid, data)
  local CMD = Blender.CMD
  if nearWindow(self, 2) then
    if data[0] == 0 then
      if not self.perfectOpponents then
        local rand = randPct(self)
        if self.speed < 500 then
          self.recv[2][COMM_SCORE] = rand > 66 and CMD.BEST or CMD.GOOD
        else
          if rand > 65 then self.recv[2][COMM_SCORE] = CMD.BEST end
          if rand > 40 and rand <= 65 then self.recv[2][COMM_SCORE] = CMD.GOOD end
          if rand < 10 then self:createOpponentMissTask(2, 5) end
        end
      else
        self.recv[2][COMM_SCORE] = CMD.BEST
      end
      data[0] = 1
    end
  else
    data[0] = 0
  end
end

-- pokeemerald/src/berry_blender.c:1951
function Blender:opponent3(tid, data)
  local CMD = Blender.CMD
  if nearWindow(self, 3) then
    if data[0] == 0 then
      if not self.perfectOpponents then
        local rand = randPct(self)
        if self.speed < 500 then
          self.recv[3][COMM_SCORE] = rand > 88 and CMD.BEST or CMD.GOOD
        else
          if rand > 60 then
            self.recv[3][COMM_SCORE] = CMD.BEST
          elseif rand > 55 and rand <= 60 then
            self.recv[3][COMM_SCORE] = CMD.GOOD
          end
          if rand < 5 then self:createOpponentMissTask(3, 5) end
        end
      else
        self.recv[3][COMM_SCORE] = CMD.BEST
      end
      data[0] = 1
    end
  else
    data[0] = 0
  end
end

-- pokeemerald/src/berry_blender.c:1993
function Blender:berryMaster(tid, data)
  if self:arrowProximity(self.arrowPos, 1) == Blender.PROXIMITY.BEST then
    if data[0] == 0 then
      self.recv[1][COMM_SCORE] = Blender.CMD.BEST
      data[0] = 1
    end
  else
    data[0] = 0
  end
end

local OPPONENTS = { "opponent1", "opponent2", "opponent3" }

-- pokeemerald/src/berry_blender.c:1768
function Blender:startPlay()
  for i = 0, Blender.MAX_PLAYERS - 1 do
    self.recv[i][COMM_INPUT_STATE] = 0
    self.recv[i][COMM_SCORE] = 0
  end
  self.sendScore = 0
  self.speed = Blender.MIN_ARROW_SPEED
  self.gameFrameTime = 0
  self.perfectOpponents = false
  self.slowdownTimer = 0
  local function task(name)
    return function(tid, data) self[name](self, tid, data) end
  end
  if not self.linked and self.var8004 == 1 then
    self.opponentTaskIds[0] = self.tasks:create(task(self.blendMaster and "berryMaster" or "opponent1"), 10)
  end
  if not self.linked and self.var8004 > 1 then
    for i = 0, self.var8004 - 1 do
      self.opponentTaskIds[i] = self.tasks:create(task(OPPONENTS[i + 1]), 10 + i)
    end
  end
  self:emit({ kind = "pitch", value = 2 * (self.speed - Blender.MIN_ARROW_SPEED) })
end

-- pokeemerald/src/berry_blender.c:3377
function Blender:shakeCoordForHit(coord, speed)
  if coord == 0 then
    speed = u16(speed)
    return s16((self:rand() % speed) - math.floor(speed / 2))
  end
  return coord
end

-- pokeemerald/src/berry_blender.c:3170
function Blender:particles()
  local limit = (self:rand() % 2) + 1
  local sine = self.T.sine
  local out = {}
  for i = 1, limit do
    local r = u16(self.arrowPos + (self:rand() % 20))
    local x = cdiv(sine[band(r, 0xFF) + 64 + 1], 4)
    local y = cdiv(sine[band(r, 0xFF) + 1], 4)
    local dx = 16 - (self:rand() % 32)
    local dy = 16 - (self:rand() % 32)
    out[i] = { x = x + 120, y = y + 80, dx = dx, dy = dy }
  end
  return out
end

-- pokeemerald/src/berry_blender.c:2011
function Blender:scoreSymbol(cmd, arrowId)
  self:emit({ kind = "score", cmd = cmd, arrowId = arrowId, particles = self:particles() })
end

-- pokeemerald/src/berry_blender.c:2038
function Blender:updateSpeedFromHit(cmd)
  local CMD = Blender.CMD
  local div = self.T.numPlayersToSpeedDivisor[self.numPlayers + 1]
  self:emit({ kind = "pitch", value = 2 * (self.speed - Blender.MIN_ARROW_SPEED) })
  if cmd == CMD.BEST then
    if self.speed < 1500 then
      self.speed = s16(self.speed + math.floor(384 / div))
    else
      self.speed = s16(self.speed + math.floor(128 / div))
      self.bg_X = self:shakeCoordForHit(self.bg_X, cdiv(self.speed, 100) - 10)
      self.bg_Y = self:shakeCoordForHit(self.bg_Y, cdiv(self.speed, 100) - 10)
    end
  elseif cmd == CMD.GOOD then
    if self.speed < 1500 then self.speed = s16(self.speed + math.floor(256 / div)) end
  elseif cmd == CMD.MISS then
    self.speed = s16(self.speed - math.floor(256 / div))
    if self.speed < Blender.MIN_ARROW_SPEED then self.speed = Blender.MIN_ARROW_SPEED end
  end
end

-- pokeemerald/src/berry_blender.c:2084
function Blender:updateOpponentScores(remoteScores)
  local CMD, SC = Blender.CMD, Blender.SCORE
  local recv = self.recv
  if self.sendScore ~= 0 then
    local playerId = self.localPlayerId or 0
    recv[playerId][COMM_SCORE] = self.sendScore
    recv[playerId][COMM_INPUT_STATE] = CMD.SEND_KEYS
    self.sendScore = 0
  end
  if self.linked and type(remoteScores) == "table" then
    for playerId, score in pairs(remoteScores) do
      playerId, score = tonumber(playerId), tonumber(score)
      if playerId and playerId ~= self.localPlayerId and playerId >= 0 and playerId < self.numPlayers
          and score and score ~= 0 then
        recv[playerId][COMM_SCORE] = score
        recv[playerId][COMM_INPUT_STATE] = CMD.SEND_KEYS
      end
    end
  end
  for i = 1, Blender.MAX_PLAYERS - 1 do
    if recv[i][COMM_SCORE] ~= 0 then recv[i][COMM_INPUT_STATE] = CMD.SEND_KEYS end
  end
  for i = 0, self.numPlayers - 1 do
    if recv[i][COMM_INPUT_STATE] == CMD.SEND_KEYS then
      local arrowId = self.playerIdToArrowId[i]
      local sc = recv[i][COMM_SCORE]
      if sc == CMD.BEST then
        self:updateSpeedFromHit(CMD.BEST)
        self.progressBarValue = u16(self.progressBarValue + math.floor(u16(self.speed) / 55))
        if self.progressBarValue >= Blender.MAX_PROGRESS_BAR then self.progressBarValue = Blender.MAX_PROGRESS_BAR end
        self:scoreSymbol(CMD.BEST, arrowId)
        self.scores[i][SC.BEST] = self.scores[i][SC.BEST] + 1
      elseif sc == CMD.GOOD then
        self:updateSpeedFromHit(CMD.GOOD)
        self.progressBarValue = u16(self.progressBarValue + math.floor(u16(self.speed) / 70))
        self:scoreSymbol(CMD.GOOD, arrowId)
        self.scores[i][SC.GOOD] = self.scores[i][SC.GOOD] + 1
      elseif sc == CMD.MISS then
        self:scoreSymbol(CMD.MISS, arrowId)
        self:updateSpeedFromHit(CMD.MISS)
        if self.scores[i][SC.MISS] < 999 then self.scores[i][SC.MISS] = self.scores[i][SC.MISS] + 1 end
      end
      -- pokeemerald/src/berry_blender.c:2142
      local bugged = recv[2][i]
      if sc == CMD.MISS or bugged == CMD.BEST or bugged == CMD.GOOD then
        if self.speed > 1500 then
          self:emit({ kind = "tempo", value = cdiv(self.speed - 750, 20) + 256 })
        else
          self:emit({ kind = "tempo", value = 256 })
        end
      end
    end
  end
  for i = 0, self.numPlayers - 1 do
    recv[i][COMM_INPUT_STATE] = 0
    recv[i][COMM_SCORE] = 0
  end
end

-- pokeemerald/src/berry_blender.c:2164
function Blender:handlePlayerInput(pressedA)
  local playerId = self.localPlayerId or 0
  local arrowId = self.playerIdToArrowId[playerId]
  if self.gameEndState == 0 and pressedA then
    self:emit({ kind = "flash", arrowId = arrowId })
    local p = self:arrowProximity(self.arrowPos, playerId)
    if p == Blender.PROXIMITY.BEST then
      self.sendScore = Blender.CMD.BEST
    elseif p == Blender.PROXIMITY.GOOD then
      self.sendScore = Blender.CMD.GOOD
    else
      self.sendScore = Blender.CMD.MISS
    end
  end
  self.slowdownTimer = self.slowdownTimer + 1
  if self.slowdownTimer > 5 then
    if self.speed > Blender.MIN_ARROW_SPEED then self.speed = self.speed - 1 end
    self.slowdownTimer = 0
  end
end

function Blender:previewInputScore(pressedA)
  if not pressedA or self.gameEndState ~= 0 then return 0 end
  local nextArrowPos = u16(self.arrowPos + self.speed)
  local proximity = self:arrowProximity(nextArrowPos, self.localPlayerId or 0)
  if proximity == Blender.PROXIMITY.BEST then return Blender.CMD.BEST end
  if proximity == Blender.PROXIMITY.GOOD then return Blender.CMD.GOOD end
  return Blender.CMD.MISS
end

-- pokeemerald/src/berry_blender.c:3303
function Blender:tryUpdateProgressBar()
  if self.maxProgressBarValue < self.progressBarValue then
    self.maxProgressBarValue = self.maxProgressBarValue + 2
    return true
  end
  return false
end

-- pokeemerald/src/berry_blender.c:3352
function Blender:updateRPM()
  local rpm = Blender.arrowSpeedToRPM(self.speed)
  if self.maxRPM < rpm then self.maxRPM = u16(rpm) end
  self.currentRPM = rpm
  return rpm
end

-- pokeemerald/src/berry_blender.c:3392
function Blender:restoreBgCoords()
  if self.bg_X < 0 then self.bg_X = self.bg_X + 1 end
  if self.bg_X > 0 then self.bg_X = self.bg_X - 1 end
  if self.bg_Y < 0 then self.bg_Y = self.bg_Y + 1 end
  if self.bg_Y > 0 then self.bg_Y = self.bg_Y - 1 end
end

-- pokeemerald/src/berry_blender.c:3145
function Blender:updateCenter()
  self.arrowPos = u16(self.arrowPos + self.speed)
end

-- pokeemerald/src/berry_blender.c:2212
function Blender:playFrame(pressedA, onCenter, remoteScores)
  self:updateCenter()
  if onCenter then onCenter() end
  if self.gameFrameTime < Blender.MAX_GAME_TIME then self.gameFrameTime = self.gameFrameTime + 1 end
  self:handlePlayerInput(pressedA)
  self:updateOpponentScores(remoteScores)
  if self:tryUpdateProgressBar() then self:emit({ kind = "progress", value = self.maxProgressBarValue }) end
  self:updateRPM()
  self:restoreBgCoords()
  local ended = false
  if self.gameEndState == 0 and self.maxProgressBarValue >= Blender.MAX_PROGRESS_BAR then
    self.progressBarValue = Blender.MAX_PROGRESS_BAR
    self.gameEndState = 1
    ended = true
  end
  self.tasks:run(self)
  return ended
end

-- pokeemerald/src/berry_blender.c:2554
function Blender:endFrame(onCenter)
  if self.gameEndState < 3 then
    self:updateCenter()
    if onCenter then onCenter() end
  end
  local st = self.gameEndState
  if st == 1 then
    self:emit({ kind = "tempo", value = 256 })
    for i = 0, self.var8004 - 1 do
      if self.opponentTaskIds[i] then self.tasks:destroy(self.opponentTaskIds[i]) end
    end
    self.gameEndState = 2
  elseif st == 2 then
    self.speed = s16(self.speed - 32)
    if self.speed <= 0 then
      self.speed = 0
      self.gameEndState = 5
      self:emit({ kind = "stopSe" })
    end
    self:emit({ kind = "pitch", value = 2 * (self.speed - Blender.MIN_ARROW_SPEED) })
  end
  self:restoreBgCoords()
  self:updateRPM()
  self.tasks:run(self)
  return self.gameEndState >= 5
end

-- pokeemerald/src/berry_blender.c:3617
function Blender:sortScores()
  local SC = Blender.SCORE
  local places, points = {}, {}
  for i = 0, self.numPlayers - 1 do places[i] = i end
  for i = 0, self.numPlayers - 1 do
    points[i] = 1000000 * self.scores[i][SC.BEST] + 1000 * self.scores[i][SC.GOOD] + 1000 - self.scores[i][SC.MISS]
  end
  for i = 0, self.numPlayers - 1 do
    for j = 0, self.numPlayers - 1 do
      if points[places[i]] > points[places[j]] then places[i], places[j] = places[j], places[i] end
    end
  end
  self.playerPlaces = places
  for i = 0, self.numPlayers - 1 do
    if places[i] == 0 then self.ownRanking = i end
  end
  return places
end

function Blender:calculate()
  local block = Blender.calculatePokeblock(self.blendedBerries, self.numPlayers, self.maxRPM,
    function() return self:rand() end, self.ids, self.T.blackPokeblockFlavorFlags)
  self.pokeblock = block
  return block
end

-- pokeemerald/src/pokeblock.c:1322
function Blender.flavorLevel(block)
  local best = block.spicy
  for _, k in ipairs({ "dry", "sweet", "bitter", "sour" }) do
    if best < block[k] then best = block[k] end
  end
  return best
end

-- pokeemerald/src/pokeblock.c:1337
function Blender.feel(block)
  return math.min(block.feel, 99)
end

-- pokeemerald/src/berry_blender.c:3592
function Blender.madeText(block, texts, pokeblockNames)
  return (pokeblockNames[block.color] or "") .. texts.wasMade .. "\n" .. texts.theLevelIs
    .. tostring(Blender.flavorLevel(block)) .. texts.theFeelIs .. tostring(Blender.feel(block)) .. texts.dot2
end

function Blender.records(session)
  session = Blender.session(session)
  if not session then return { 0, 0, 0 } end
  local r = session.berryBlenderRecords
  if type(r) ~= "table" then
    r = { 0, 0, 0 }
    session.berryBlenderRecords = r
  end
  for i = 1, 3 do r[i] = math.floor(tonumber(r[i]) or 0) end
  return r
end

-- pokeemerald/src/berry_blender.c:3449
function Blender:tryUpdateRecord(session)
  local r = Blender.records(session)
  local i = self.numPlayers - 1
  if r[i] < self.maxRPM then
    r[i] = self.maxRPM
    return true
  end
  return false
end

-- pokeemerald/src/string_util.c:207
Blender.SPACER = "{UNK_SPACER}"

function Blender.rightAlign(n, digits)
  local s = tostring(math.floor(n))
  return string.rep(Blender.SPACER, math.max(0, digits - #s)) .. s
end

-- pokeemerald/src/berry_blender.c:3776
function Blender.recordText(record, texts)
  return Blender.rightAlign(math.floor(record / 100), 3) .. texts.dot .. string.format("%02d", record % 100) .. texts.rpm
end

-- pokeemerald/src/berry_blender.c:3519
function Blender.maxSpeedText(maxRPM, texts)
  return Blender.rightAlign(math.floor(maxRPM / 100), 3) .. texts.dot .. string.format("%02d", maxRPM % 100) .. texts.rpm
end

-- pokeemerald/src/berry_blender.c:3530
function Blender.timeText(frames, texts)
  local seconds = math.floor(frames / 60) % 60
  local minutes = math.floor(frames / 3600)
  return string.format("%02d", minutes) .. texts.min .. string.format("%02d", seconds) .. texts.sec
end

-- pokeemerald/src/berry_blender.c:3572
function Blender:finishBlend(session)
  session = Blender.session(session)
  local block = self.pokeblock or self:calculate()
  if not session then return block end
  local okR, Rse = pcall(require, "src.core.game3.rse.init")
  if not self.nativeRS and okR and Rse then Rse.call("tv", "incrementDailyBerryBlender", nil, nil, session) end
  if session.bag then
    local localItem = self.chosenItemId[self.localPlayerId or 0]
    require("src.core.game3.bag").remove(session.bag, localItem, 1)
  end
  require("src.core.game3.rse.pokeblock").add(session, block)
  return block
end

-- pokeemerald/src/berry_blender.c:2655
function Blender.incrementGameStat(session, id)
  session = Blender.session(session)
  if not session then return end
  if type(session.gameStats) ~= "table" then session.gameStats = {} end
  session.gameStats[id] = math.min(0xFFFFFF, math.floor(tonumber(session.gameStats[id]) or 0) + 1)
end

Blender.SAVE_FIELDS = { "berryBlenderRecords" }

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  SaveSections.register("berryBlender", SaveSections.fields(Blender.SAVE_FIELDS, function(session)
    -- pokeemerald/src/load_save.c:64
    session.berryBlenderRecords = { 0, 0, 0 }
  end))
end

local okR, Rse = pcall(require, "src.core.game3.rse.init")
if okR and Rse and Rse.register then Rse.register("berryBlender", Blender) end

return Blender
