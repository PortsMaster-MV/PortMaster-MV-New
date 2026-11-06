local M = {}

M.MSG = "game3_link_player"
M.VOBJ_BASE = 0x7E00
local WALK_FRAMES = 16
local CELL = 16
local KEEPALIVE = 60
local MAX_QUEUE = 32
local ROOM_KEYS = { "tradeCenter", "colosseum2P", "colosseum4P", "recordCorner" }
local DIR_NUM = { down = 1, up = 2, left = 3, right = 4 }

M._remotes = {}
M._queues = {}
M._base = nil
M._sent = nil
M._sentAt = 0
M._frame = 0
M._mapId = nil

local function Link() return package.loaded["src.core.game3.link.init"] end
local function VObj() return require("src.core.game3.virtual_objects") end
local function Family() return require("src.core.game3.link.family") end

function M.roomKey(mapId)
  if type(mapId) ~= "string" then return nil end
  local ok, version = pcall(function() return Family().activeVersion() end)
  if not ok then return nil end
  for _, key in ipairs(ROOM_KEYS) do
    local okId, id = pcall(Family().mapId, version, key)
    if okId and id == mapId then return key end
  end
  return nil
end

function M.isLinkRoom(mapId)
  return M.roomKey(mapId) ~= nil
end

local function liveLink()
  local L = Link()
  local lk = L and L.link
  if not (lk and lk.isOpen and lk:isOpen() and lk.isReady and lk:isReady()) then return nil end
  if type(lk.send) ~= "function" or type(lk.take) ~= "function" then return nil end
  return lk
end

local function ownSeat(lk)
  return tonumber(lk.getSeat and lk:getSeat()) or (lk.role == "guest" and 1 or 0)
end

function M.clear()
  local V = package.loaded["src.core.game3.virtual_objects"]
  for seat in pairs(M._remotes) do
    if V then V.remove(M.VOBJ_BASE + seat) end
  end
  M._remotes, M._queues = {}, {}
  M._base, M._sent, M._mapId = nil, nil, nil
  M._sentAt, M._frame = 0, 0
end

-- pokeruby/src/overworld.c:2726
local function graphicsFor(player)
  local ok, gfx = pcall(function()
    return Family().linkPlayerGfx(nil, player.version, player.gender)
  end)
  return ok and gfx or 0
end

-- pokeemerald/src/overworld.c:2323
local function localBusy()
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return true end
  local Field = package.loaded["src.core.game3.field"]
  if Field and Field.locked then return true end
  local Runtime = package.loaded["src.core.game3.runtime"]
  return (Runtime and Runtime.uiBusy and Runtime.uiBusy()) and true or false
end

local function localState(mapId)
  local P = require("src.core.game3.player")
  local moving = P.moving == true and not P.jumping
  return {
    busy = localBusy(),
    map = mapId,
    x = tonumber(P.cellX) or 0,
    y = tonumber(P.cellY) or 0,
    tx = moving and tonumber(P.targetX) or nil,
    ty = moving and tonumber(P.targetY) or nil,
    facing = P.facing or "down",
    frames = moving and tonumber(P.stepFrames) or nil,
  }
end

local function sameState(a, b)
  return a and b and a.map == b.map and a.x == b.x and a.y == b.y and a.tx == b.tx
    and a.ty == b.ty and a.facing == b.facing and a.busy == b.busy
end

local function sendLocal(lk, mapId)
  local st = localState(mapId)
  if sameState(st, M._sent) and M._frame - M._sentAt < KEEPALIVE then return end
  if sameState(st, M._sent) and st.tx then return end
  M._sent, M._sentAt = st, M._frame
  lk:send({ type = M.MSG, seat = ownSeat(lk), map = st.map, x = st.x, y = st.y,
    tx = st.tx, ty = st.ty, facing = st.facing, frames = st.frames, busy = st.busy })
end

local function receive(lk, own)
  local msg = lk:take(M.MSG)
  while msg do
    local seat = tonumber(msg.seat)
    if seat and seat ~= own and not (lk.departed and lk.departed[seat]) then
      local q = M._queues[seat] or {}
      M._queues[seat] = q
      q[#q + 1] = msg
    end
    msg = lk:take(M.MSG)
  end
end

local function snap(r, x, y)
  r.x, r.y, r.prevX, r.prevY = x, y, x, y
  r.moving, r.progress, r.px, r.py = false, 0, nil, nil
end

-- pokeruby/src/overworld.c:2646
local function beginStep(r, tx, ty, frames)
  local dx, dy = tx - r.x, ty - r.y
  r.facing = dx > 0 and "right" or dx < 0 and "left" or dy > 0 and "down" or "up"
  r.prevX, r.prevY = r.x, r.y
  r.x, r.y = tx, ty
  r.moving, r.progress, r.animClock = true, 0, 0
  r.stepFrames = math.max(1, math.floor(tonumber(frames) or WALK_FRAMES))
end

local function applyMessage(r, msg, mapId)
  r.map = msg.map
  r.busy = msg.busy == true
  local x, y = tonumber(msg.x), tonumber(msg.y)
  if not (x and y) then return end
  if msg.map ~= mapId then snap(r, x, y); return end
  local tx, ty = tonumber(msg.tx), tonumber(msg.ty)
  if tx and ty then
    if r.x ~= x or r.y ~= y then snap(r, x, y) end
    if math.abs(tx - x) + math.abs(ty - y) == 1 then beginStep(r, tx, ty, msg.frames)
    else snap(r, tx, ty) end
  else
    if r.x ~= x or r.y ~= y then snap(r, x, y) end
    r.facing = DIR_NUM[msg.facing] and msg.facing or r.facing
  end
end

-- pokeruby/src/overworld.c:2677
local function tickRemote(r)
  if not r.moving then return end
  r.progress = r.progress + 1
  r.animClock = r.animClock + 1
  local off = math.floor(CELL * math.min(r.progress, r.stepFrames) / r.stepFrames)
  local dx, dy = r.x - r.prevX, r.y - r.prevY
  r.px = r.prevX * CELL + dx * off
  r.py = r.prevY * CELL + dy * off
  if r.progress >= r.stepFrames then
    r.moving, r.progress, r.px, r.py = false, 0, nil, nil
    r.prevX, r.prevY = r.x, r.y
    r.stepFlip = not r.stepFlip
  end
end

local function pump(r, seat, mapId)
  local q = M._queues[seat]
  if not q or #q == 0 then return end
  if #q > MAX_QUEUE then
    local last = q[#q]
    for i = #q, 1, -1 do q[i] = nil end
    snap(r, tonumber(last.tx) or tonumber(last.x) or r.x, tonumber(last.ty) or tonumber(last.y) or r.y)
    r.map = last.map
    r.facing = DIR_NUM[last.facing] and last.facing or r.facing
    return
  end
  while #q > 0 and not r.moving do
    local msg = table.remove(q, 1)
    applyMessage(r, msg, mapId)
    if r.moving and #q > 1 then r.stepFrames = math.max(4, math.floor(r.stepFrames / 2)) end
  end
end

local function mirror(r, seat, mapId)
  local V = VObj()
  local id = M.VOBJ_BASE + seat
  if r.map ~= nil and r.map ~= mapId then V.remove(id); return end
  local vo = V.get(id) or V.spawn(id, r.gfx, r.x, r.y, 3, DIR_NUM[r.facing] or 2)
  vo.graphicsId = r.gfx
  vo.x, vo.y = r.x, r.y
  vo.prevX, vo.prevY = r.prevX, r.prevY
  vo.direction = DIR_NUM[r.facing] or 2
  vo.solid = true
  vo.linkPlayer = seat
  vo.moving = r.moving
  vo.px, vo.py = r.px, r.py
  vo.targetX, vo.targetY = r.moving and r.x or nil, r.moving and r.y or nil
  vo.animClock, vo.stepFrames, vo.stepFlip = r.animClock, r.stepFrames, r.stepFlip
end

-- pokeruby/src/overworld.c:1890
local function spawnAll(lk, own)
  local P = require("src.core.game3.player")
  if not M._base then
    M._base = { x = (tonumber(P.cellX) or 0) - own, y = tonumber(P.cellY) or 0 }
  end
  local players = lk.players and lk:players() or {}
  local present = {}
  for i, player in ipairs(players) do present[tonumber(player.seat) or (i - 1)] = player end
  local V = package.loaded["src.core.game3.virtual_objects"]
  for seat in pairs(M._remotes) do
    if not present[seat] then
      if V then V.remove(M.VOBJ_BASE + seat) end
      M._remotes[seat], M._queues[seat] = nil, nil
    end
  end
  for i, player in ipairs(players) do
    local seat = tonumber(player.seat) or (i - 1)
    if seat ~= own and not M._remotes[seat] then
      local r = { seat = seat, gfx = graphicsFor(player), facing = "up", stepFlip = false,
        animClock = 0, stepFrames = WALK_FRAMES, progress = 0 }
      snap(r, M._base.x + seat, M._base.y)
      M._remotes[seat] = r
    end
  end
end

function M.update()
  local lk = liveLink()
  if not lk then
    if next(M._remotes) or M._base then M.clear() end
    return false
  end
  M._frame = M._frame + 1
  local own = ownSeat(lk)
  receive(lk, own)
  local L = Link()
  local mapId = M.roomKey(L.currentMap())
  local inRoom = mapId ~= nil
  local Warp = package.loaded["src.core.game3.warp"]
  local warping = Warp and Warp.isBusy and Warp.isBusy()
  if not inRoom then
    if M._sent and M._sent.map ~= "" then
      M._sent = { map = "" }
      lk:send({ type = M.MSG, seat = own, map = "" })
    end
    local V = package.loaded["src.core.game3.virtual_objects"]
    for seat in pairs(M._remotes) do if V then V.remove(M.VOBJ_BASE + seat) end end
    M._mapId = nil
    return true
  end
  if warping then return true end
  M._mapId = mapId
  spawnAll(lk, own)
  sendLocal(lk, mapId)
  for seat, r in pairs(M._remotes) do
    pump(r, seat, mapId)
    tickRemote(r)
    mirror(r, seat, mapId)
  end
  return true
end

-- pokeruby/src/overworld.c:2362
local SEATS = {
  tradeCenter = { ["4,5"] = "right", ["7,5"] = "left" },
  colosseum2P = { ["3,5"] = "right", ["10,5"] = "left" },
  colosseum4P = { ["3,4"] = "right", ["3,6"] = "right", ["10,4"] = "left", ["10,6"] = "left" },
  recordCorner = { ["6,4"] = "right", ["6,6"] = "right", ["13,4"] = "left", ["13,6"] = "left" },
}
-- pokefirered/src/overworld.c:3128
local SEATS_FRLG = setmetatable({
  recordCorner = { ["6,4"] = "right", ["6,6"] = "left", ["13,4"] = "right", ["13,6"] = "left" },
}, { __index = SEATS })

function M.seatFacing(x, y)
  if not liveLink() then return nil end
  local key = M.roomKey(Link().currentMap())
  if not key then return nil end
  local ok, family = pcall(function() return Family().of(Family().activeVersion()) end)
  local rows = (ok and family == "frlg" and SEATS_FRLG or SEATS)[key]
  return rows and rows[tostring(x) .. "," .. tostring(y)] or nil
end

function M.forceSeatFacing(x, y)
  local facing = M.seatFacing(x, y)
  if not facing then return false end
  local P = require("src.core.game3.player")
  if P.scriptFace then P.scriptFace(facing) else P.facing = facing end
  return true
end

local SCRIPTS = {
  plain = { "TradeRoom_ReadTrainerCard1", "CableClub_EventScript_ReadTrainerCard" },
  colored = { "TradeRoom_ReadTrainerCard2", "CableClub_EventScript_ReadTrainerCardColored" },
  busy = { "TradeRoom_TooBusyToNotice", "CableClub_EventScript_TooBusyToNotice" },
}
local COLOR_TABLES = { "gTrainerCardColorNames", "sTrainerCardColorNames" }

local function scriptKey(Space, kind)
  for _, name in ipairs(SCRIPTS[kind]) do
    local key = Space.scriptKey(name)
    if key then return key end
  end
  return nil
end

local function colorName(stars)
  local RomText = require("src.core.game3.rom_text")
  for _, name in ipairs(COLOR_TABLES) do
    local key = RomText.key(name, stars - 1)
    local ok, has = pcall(RomText.has, key)
    if ok and has then return RomText.plain(key) end
  end
  return ""
end

function M.seatAt(x, y)
  for seat, r in pairs(M._remotes) do
    if r.x == x and r.y == y and (r.map == nil or r.map == M._mapId) then return seat end
  end
  return nil
end

-- pokeemerald/src/overworld.c:2745
function M.tryInteract(x, y)
  local lk = liveLink()
  if not lk or not M._mapId or M.roomKey(Link().currentMap()) ~= M._mapId then return false end
  local seat = M.seatAt(x, y)
  if seat == nil then return false end
  local Space = package.loaded["src.core.game3.scripting.space"]
  if not (Space and Space.vm and Space.startScript) then return false end
  local L = Link()
  local card = L.peerCards and L.peerCards[seat]
  if card == nil and (tonumber(lk.nseats) or 2) <= 2 then card = L.peerCard end
  local name
  for _, player in ipairs(lk:players()) do
    if tonumber(player.seat) == seat then name = player.name end
  end
  name = tostring((card and card.name) or name or "")
  -- pokeemerald/src/cable_club.c:1203
  local stars = math.max(0, math.min(4, math.floor(tonumber(card and card.stars) or 0)))
  local kind = M._remotes[seat].busy and "busy" or (stars == 0 and "plain" or "colored")
  local key = scriptKey(Space, kind)
  if not key then return false end
  Space.vm._presetSpecial = { [L.VAR_0x8006] = seat }
  Space.vm._presetStrings = { [1] = name, [2] = stars > 0 and colorName(stars) or "" }
  -- pokeemerald/src/overworld.c:2832
  local Audio = package.loaded["src.core.game3.audio"]
  if Audio and Audio.playSe then Audio.playSe(require("src.core.game3.se_ids").SE_SELECT) end
  if Space.startScript(key) then return true end
  Space.vm._presetSpecial, Space.vm._presetStrings = nil, nil
  return false
end

function M.remotes()
  return M._remotes
end

return M
