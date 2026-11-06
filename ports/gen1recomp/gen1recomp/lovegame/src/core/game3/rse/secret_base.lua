local Rse = require("src.core.game3.rse.init")
local Decor = require("src.core.game3.rse.decoration")
local MB = require("src.core.game3.mb")

local SB = {}

-- pokeemerald/include/constants/global.h:48
SB.COUNT = 20
-- pokeemerald/include/constants/global.h:97
SB.PLAYER_NAME_LENGTH = 7
SB.TRAINER_ID_LENGTH = 4
-- pokeemerald/include/constants/global.h:30
SB.GAME_LANGUAGE = 2
-- pokeemerald/include/constants/secret_bases.h:4
SB.TYPE = { RED_CAVE = 1, BROWN_CAVE = 2, BLUE_CAVE = 3, YELLOW_CAVE = 4, TREE = 5, SHRUB = 6 }
-- pokeemerald/include/constants/secret_bases.h:26
SB.GROUP_MAPS = {
  "RED_CAVE1", "RED_CAVE2", "RED_CAVE3", "RED_CAVE4", "BROWN_CAVE1", "BROWN_CAVE2", "BROWN_CAVE3", "BROWN_CAVE4",
  "BLUE_CAVE1", "BLUE_CAVE2", "BLUE_CAVE3", "BLUE_CAVE4", "YELLOW_CAVE1", "YELLOW_CAVE2", "YELLOW_CAVE3", "YELLOW_CAVE4",
  "TREE1", "TREE2", "TREE3", "TREE4", "SHRUB1", "SHRUB2", "SHRUB3", "SHRUB4",
}
-- pokeemerald/src/secret_base.c:52
SB.UNREGISTERED, SB.REGISTERED, SB.NEW = 0, 1, 2
-- pokeemerald/include/constants/game_stat.h:24
SB.GAME_STAT_MOVED_SECRET_BASE = 20
-- pokeemerald/include/constants/tv.h:136
SB.LOW = {
  USED_CHAIR = 0x1, USED_BALLOON = 0x2, USED_TENT = 0x4, USED_PLANT = 0x8, USED_GOLD_SHIELD = 0x10,
  USED_SILVER_SHIELD = 0x20, USED_GLASS_ORNAMENT = 0x40, USED_TV = 0x80, USED_MUD_BALL = 0x100, USED_BAG = 0x200,
  USED_CUSHION = 0x400, BATTLED_WON = 0x800, BATTLED_LOST = 0x1000, DECLINED_BATTLE = 0x2000, USED_POSTER = 0x4000,
  USED_NOTE_MAT = 0x8000,
}
SB.HIGH = {
  BATTLED_DRAW = 0x1, USED_SPIN_MAT = 0x2, USED_SAND_ORNAMENT = 0x4, USED_DESK = 0x8, USED_BRICK = 0x10,
  USED_SOLID_BOARD = 0x20, USED_FENCE = 0x40, USED_GLITTER_MAT = 0x80, USED_TIRE = 0x100, USED_STAND = 0x200,
  USED_BREAKABLE_DOOR = 0x400, USED_DOLL = 0x800, USED_SLIDE = 0x1000, DECLINED_SLIDE = 0x2000, USED_JUMP_MAT = 0x4000,
}
-- pokeemerald/include/constants/trainers.h:14
SB.TRAINER_SECRET_BASE = 1024
-- pokeemerald/include/constants/battle.h:62
SB.BATTLE_TYPE_TRAINER = 0x8
SB.BATTLE_TYPE_SECRET_BASE = 0x800000
-- pokeemerald/include/constants/battle_frontier.h:37
SB.SPECIAL_BATTLE_SECRET_BASE = 1

SB._curId = 0
SB._inFriendBase = false

local bit = require("bit")
local band, bor, bxor, bnot = bit.band, bit.bor, bit.bxor, bit.bnot

local function session(sess)
  return sess or Rse.session()
end

local function consts(sess)
  local Constants = require("src.core.game3.constants")
  return Constants.of(Constants.versionOf(session(sess)))
end

local function player()
  return package.loaded["src.core.game3.player"] or require("src.core.game3.player")
end

function SB.manifest()
  return Decor.manifest()
end

local function newBase()
  local b = {
    secretBaseId = 0, toRegister = 0, gender = 0, battledOwnerToday = 0, registryStatus = 0,
    trainerName = "", trainerId = { 0, 0, 0, 0 }, language = 0, numSecretBasesReceived = 0, numTimesEntered = 0,
    decorations = {}, decorationPositions = {},
    party = { personality = {}, moves = {}, species = {}, heldItems = {}, levels = {}, EVs = {} },
  }
  for i = 1, Decor.MAX_SECRET_BASE do b.decorations[i], b.decorationPositions[i] = 0, 0 end
  for i = 1, 6 do
    b.party.personality[i], b.party.species[i], b.party.heldItems[i], b.party.levels[i], b.party.EVs[i] = 0, 0, 0, 0, 0
  end
  for i = 1, 24 do b.party.moves[i] = 0 end
  return b
end
SB.newBase = newBase

local function normalize(b)
  local fresh = newBase()
  if type(b) ~= "table" then return fresh end
  for k, v in pairs(fresh) do
    if b[k] == nil then b[k] = v end
  end
  for i = 1, Decor.MAX_SECRET_BASE do
    b.decorations[i] = tonumber(b.decorations[i]) or 0
    b.decorationPositions[i] = tonumber(b.decorationPositions[i]) or 0
  end
  return b
end

function SB.bases(sess)
  sess = session(sess)
  if type(sess.secretBases) ~= "table" then sess.secretBases = {} end
  for i = 1, SB.COUNT do sess.secretBases[i] = normalize(sess.secretBases[i]) end
  return sess.secretBases
end

function SB.base(sess, idx)
  return SB.bases(sess)[(tonumber(idx) or 0) + 1]
end

-- pokeemerald/src/secret_base.c:222
local function clearBase(b)
  local fresh = newBase()
  for k in pairs(b) do b[k] = nil end
  for k, v in pairs(fresh) do b[k] = v end
end
SB.clearBase = clearBase

-- pokeemerald/src/secret_base.c:230
function SB.clearAll(sess)
  for _, b in ipairs(SB.bases(sess)) do clearBase(b) end
end

local function var(name, sess) return Rse.var(name, session(sess)) end
local function setVar(name, v, sess) Rse.setVar(name, v, session(sess)) end
local function flag(name, sess) return Rse.flag(name, session(sess)) end
local function setFlag(name, on, sess) Rse.setFlag(name, on, session(sess)) end

local function orVar(name, bits)
  setVar(name, bor(var(name), bits))
end

local groupMaps

function SB.mapIdForGroup(g, sess)
  groupMaps = groupMaps or {}
  local key = tostring(g)
  if groupMaps[key] then return groupMaps[key] end
  local C = consts(sess)
  local name = "MAP_SECRET_BASE_" .. assert(SB.GROUP_MAPS[g + 1], "no secret base group " .. tostring(g))
  local row = Rse.profile(session(sess))
  local prefix = row and row.map and row.map.enginePrefix or ""
  local e = C:require("map_groups", name)
  local m = SB.manifest().entrances[g]
  assert(m and m.mapNum == e.num, "sSecretBaseEntrancePositions map mismatch for " .. name)
  groupMaps[key] = prefix .. name:sub(5)
  return groupMaps[key]
end

function SB.groupOfId(id)
  return math.floor((tonumber(id) or 0) / 10)
end

-- pokeemerald/src/secret_base.c:510
function SB.curMapIsSecretBase(sess, mapId)
  sess = session(sess)
  mapId = mapId or (sess and sess.map)
  local g, n = Rse.mapGroupNum(mapId, sess)
  if not g then return false end
  local C = consts(sess)
  local first = C:require("map_groups", "MAP_SECRET_BASE_RED_CAVE1")
  local last = C:require("map_groups", "MAP_SECRET_BASE_SHRUB4")
  return g == first.group and n <= last.num
end

local function metatile(name, sess)
  local policy = Rse.profile(session(sess)).secretBase
  if policy and policy.metatiles and policy.metatiles[name] ~= nil then return policy.metatiles[name] end
  return consts(sess):require("metatile_labels", name)
end
SB.metatile = metatile

local DELTA = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

function SB.frontOfPlayer()
  local P = player()
  local d = DELTA[P.facing or "down"] or DELTA.down
  return (tonumber(P.cellX) or 0) + d[1], (tonumber(P.cellY) or 0) + d[2]
end

local function layout()
  local Collision = package.loaded["src.core.game3.collision"]
  local def = Collision and Collision._mapDef
  return def and def.midLayout, def
end

function SB.fieldGrid()
  local Collision = require("src.core.game3.collision")
  local Field = require("src.core.game3.field")
  local grid = {}
  function grid.behavior(x, y) return Collision.behavior(x, y) end
  function grid.metatile(x, y)
    local l = layout()
    return l and l:midAt(x, y) or nil
  end
  function grid.original(x, y)
    local l = layout()
    if not l or x < 0 or y < 0 or x >= l.width or y >= l.height then return nil end
    local c = l.cells[y * l.width + x + 1]
    return c and c.mid
  end
  function grid.metatileId(name)
    local ok, v = pcall(metatile, name)
    return ok and v or nil
  end
  function grid.setMetatile(x, y, mid, impassable, elev)
    Field.setMetatile(x, y, mid, impassable == true)
    if elev ~= nil then
      local l, def = layout()
      local ov = l and l.overrides[y * 1024 + x]
      if ov then
        ov.elev = elev
        Collision.bindMap(Field._game, def and def.id or (Field._session and Field._session.map), def)
      end
    end
  end
  function grid.restoreMetatile(x, y, elev)
    local mid = grid.original(x, y)
    if mid then grid.setMetatile(x, y, mid, false, elev) end
  end
  function grid.objectAt(x, y)
    local P = player()
    if P.cellX == x and P.cellY == y then return 0 end
    local Objects = package.loaded["src.core.game3.objects"]
    local eo = Objects and Objects.at(x, y)
    if eo and not eo.hidden then return eo.localId or 1 end
    return nil
  end
  function grid.size()
    local l = layout()
    return l and l.width or 0, l and l.height or 0
  end
  function grid.visibleDecorationFlagAt(x, y)
    local Objects = package.loaded["src.core.game3.objects"]
    if not Objects then return nil end
    local lo, hi = SB.decorationFlagRange()
    for _, lid in ipairs(Objects._order or {}) do
      local eo = Objects._byId[lid]
      local f = eo and eo.def and tonumber(eo.def.flag or eo.def.flagId)
      if f and f >= lo and f <= hi and not eo.hidden and eo.cellX == x and eo.cellY == y then return f end
    end
    return nil
  end
  return grid
end

function SB.decorationFlagRange(sess)
  local C = consts(sess)
  if C.game == "ruby" then
    return C:require("flags", "FLAG_DECORATION_2"), C:require("flags", "FLAG_DECORATION_15")
  end
  return C:require("flags", "FLAG_DECORATION_1"), C:require("flags", "FLAG_DECORATION_14")
end

-- pokeemerald/src/secret_base.c:242
function SB.trySetCurIndex(sess)
  local found = false
  for i, b in ipairs(SB.bases(sess)) do
    if SB._curId == b.secretBaseId then
      found = true
      setVar("VAR_CURRENT_SECRET_BASE", i - 1, sess)
      break
    end
  end
  return found
end

-- pokeemerald/src/secret_base.c:681
function SB.trySetCur(id, sess)
  SB._curId = tonumber(id) or 0
  return not SB.trySetCurIndex(sess)
end

-- pokeemerald/src/secret_base.c:258
function SB.playerHasBase(sess)
  return SB.base(sess, 0).secretBaseId ~= 0
end

local SPOTS = {
  { SB.TYPE.RED_CAVE, "SECRET_BASE_SPOT_RED_CAVE", "SECRET_BASE_SPOT_RED_CAVE_OPEN" },
  { SB.TYPE.BROWN_CAVE, "SECRET_BASE_SPOT_BROWN_CAVE", "SECRET_BASE_SPOT_BROWN_CAVE_OPEN" },
  { SB.TYPE.BLUE_CAVE, "SECRET_BASE_SPOT_BLUE_CAVE", "SECRET_BASE_SPOT_BLUE_CAVE_OPEN" },
  { SB.TYPE.YELLOW_CAVE, "SECRET_BASE_SPOT_YELLOW_CAVE", "SECRET_BASE_SPOT_YELLOW_CAVE_OPEN" },
  { SB.TYPE.TREE, "SECRET_BASE_SPOT_TREE_LEFT", "SECRET_BASE_SPOT_TREE_LEFT_OPEN",
    "SECRET_BASE_SPOT_TREE_RIGHT", "SECRET_BASE_SPOT_TREE_RIGHT_OPEN" },
  { SB.TYPE.SHRUB, "SECRET_BASE_SPOT_SHRUB", "SECRET_BASE_SPOT_SHRUB_OPEN" },
}

-- pokeemerald/src/secret_base.c:267
function SB.typeAt(beh)
  for _, row in ipairs(SPOTS) do
    for i = 2, #row do
      if beh ~= nil and beh == MB.id(row[i]) then return row[1] end
    end
  end
  return 0
end

-- pokeemerald/src/metatile_behavior.c:507
function SB.isOpenDoor(beh)
  if beh == nil then return false end
  for _, row in ipairs(SPOTS) do
    for i = 3, #row, 2 do
      if beh == MB.id(row[i]) then return true end
    end
  end
  return false
end

-- pokeemerald/src/metatile_behavior.c:521
function SB.isCave(beh)
  local t = SB.typeAt(beh)
  return t >= SB.TYPE.RED_CAVE and t <= SB.TYPE.YELLOW_CAVE and not SB.isOpenDoor(beh)
end

function SB.isTree(beh)
  return SB.typeAt(beh) == SB.TYPE.TREE and not SB.isOpenDoor(beh)
end

function SB.isShrub(beh)
  return SB.typeAt(beh) == SB.TYPE.SHRUB and not SB.isOpenDoor(beh)
end

local function entranceMetatiles()
  return SB.manifest().entranceMetatiles
end

-- pokeemerald/src/secret_base.c:321
function SB.toggleEntrance(x, y, grid)
  grid = grid or SB.fieldGrid()
  local mid = grid.metatile(x, y)
  for _, e in ipairs(entranceMetatiles()) do
    if e.closed == mid then
      grid.setMetatile(x, y, e.open, true)
      return true
    end
  end
  for _, e in ipairs(entranceMetatiles()) do
    if e.open == mid then
      grid.setMetatile(x, y, e.closed, true)
      return true
    end
  end
  return false
end

local function trainerIdBytes(sess)
  local tid = tonumber(sess.trainerId or sess.playerId) or 0
  local sid = tonumber(sess.secretId) or 0
  return { tid % 256, math.floor(tid / 256) % 256, sid % 256, math.floor(sid / 256) % 256 }
end

local function playerGender(sess)
  local g = sess.gender
  if g == 1 or g == "female" or g == "F" or g == "girl" then return 1 end
  return 0
end

-- pokeemerald/src/secret_base.c:365
function SB.setPlayerBase(sess)
  sess = session(sess)
  local b = SB.base(sess, 0)
  b.secretBaseId = SB._curId
  b.trainerId = trainerIdBytes(sess)
  setVar("VAR_CURRENT_SECRET_BASE", 0, sess)
  b.trainerName = tostring(sess.name or sess.playerName or ""):sub(1, SB.PLAYER_NAME_LENGTH)
  b.gender = playerGender(sess)
  b.language = SB.GAME_LANGUAGE
  local _, def = layout()
  local sec = def and def.regionMapSectionId
  if sec == nil then
    local Map = package.loaded["src.core.game3.map"]
    local cur = Map and Map.currentDef and Map.currentDef()
    sec = cur and cur.regionMapSectionId
  end
  setVar("VAR_SECRET_BASE_MAP", tonumber(sec) or 0, sess)
end

local function mapEvents(mapId, def)
  if def and type(def.bgEvents) == "table" then return def.bgEvents end
  local Space = package.loaded["src.core.game3.scripting.space"]
  local ev = Space and Space.bundle and Space.bundle.events and Space.bundle.events[mapId]
  return ev and ev.bgEvents or {}
end
SB.mapEvents = mapEvents

local function isBaseEvent(ev)
  return ev.type == "secret_base" or ev.kind == 8
end

-- pokeemerald/src/secret_base.c:381
function SB.setOccupiedEntrances(events, grid, sess)
  grid = grid or SB.fieldGrid()
  local bases = SB.bases(sess)
  for _, ev in ipairs(events or {}) do
    if isBaseEvent(ev) then
      for _, b in ipairs(bases) do
        if b.secretBaseId == ev.secretBaseId then
          local mid = grid.metatile(ev.x, ev.y)
          for _, e in ipairs(entranceMetatiles()) do
            if e.closed == mid then
              grid.setMetatile(ev.x, ev.y, e.open, true)
              break
            end
          end
          break
        end
      end
    end
  end
end

-- pokeemerald/src/secret_base.c:301
function SB.findMetatile(grid, mid)
  local w, h = grid.size()
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if grid.original(x, y) == mid then return x, y end
    end
  end
  return nil
end

-- pokeemerald/src/secret_base.c:519
function SB.initAppearance(hidePC, grid, sess)
  sess = session(sess)
  if not SB.curMapIsSecretBase(sess) then return false end
  grid = grid or SB.fieldGrid()
  local idx = var("VAR_CURRENT_SECRET_BASE", sess)
  local b = SB.base(sess, idx)
  for i = 1, Decor.MAX_SECRET_BASE do
    local decor = b.decorations[i]
    if decor > 0 and decor <= Decor.NUM_DECORATIONS and not Decor.isSprite(decor) then
      local x, y = Decor.decodePos(b.decorationPositions[i])
      Decor.showOnMap(grid, x, y, decor)
    end
  end
  local pcMid = metatile("METATILE_SecretBase_PC", sess)
  if idx ~= 0 then
    local x, y = SB.findMetatile(grid, pcMid)
    if x then grid.setMetatile(x, y, metatile("METATILE_SecretBase_RegisterPC", sess), true) end
  elseif hidePC == true and var("VAR_SECRET_BASE_INITIALIZED", sess) == 1 then
    local x, y = SB.findMetatile(grid, pcMid)
    if x then grid.setMetatile(x, y, metatile("METATILE_SecretBase_Ground", sess), true) end
  end
  return true
end

-- pokeemerald/src/fieldmap.c:62
function SB.onMapLoad(sess, def, enterVia)
  sess = session(sess)
  if not (sess and Rse.isRse(sess)) then return false end
  local grid = SB.fieldGrid()
  SB.checkLeftFriendsBase(sess)
  SB.setOccupiedEntrances(mapEvents(sess.map, def), grid, sess)
  if enterVia == "continue" then
    SB.initAppearance(false, grid, sess)
    local id = Rse.profile(sess).id
    if (id == "ruby" or id == "sapphire") and SB.curMapIsSecretBase(sess) then
      SB.hideDecorationSprites(sess)
      require("src.core.game3.rs.room_decorations").init({specialVars = {[0x8004] = 0}}, sess, grid)
    end
  else
    SB.initAppearance(true, grid, sess)
  end
  return true
end

-- pokeemerald/src/secret_base.c:659
function SB.curIdFromPosition(x, y, events)
  for _, ev in ipairs(events or {}) do
    if isBaseEvent(ev) and ev.x == x and ev.y == y then
      SB._curId = tonumber(ev.secretBaseId) or 0
      return SB._curId
    end
  end
  return nil
end

local function startScript(label)
  local policy = Rse.profile(session()).secretBase
  label = policy and policy.scriptAliases and policy.scriptAliases[label] or label
  local Space = package.loaded["src.core.game3.scripting.space"] or require("src.core.game3.scripting.space")
  local key = Space.scriptKey(label)
  if not key then return false end
  return Space.startScript(key, nil) ~= false
end
SB.startScript = startScript

-- pokeemerald/src/field_control_avatar.c:354
function SB.bgEventScript(ev, facing)
  if not (ev and isBaseEvent(ev)) then return nil end
  if facing ~= "up" and facing ~= 2 then return nil end
  if SB.trySetCur(ev.secretBaseId) then
    local policy = Rse.profile(session()).secretBase
    return policy and policy.scriptAliases and policy.scriptAliases.SecretBase_EventScript_CheckEntrance
      or "SecretBase_EventScript_CheckEntrance"
  end
  return nil
end

function SB.interactBg(x, y, facing, elevation)
  local sess = session()
  for _, ev in ipairs(mapEvents(sess and sess.map)) do
    if isBaseEvent(ev) and ev.x == x and ev.y == y
        and (not ev.elevation or ev.elevation == 0 or elevation == nil or ev.elevation == elevation) then
      local label = SB.bgEventScript(ev, facing)
      if label then return startScript(label) end
      return false
    end
  end
  return false
end

-- pokeemerald/src/field_control_avatar.c:837
function SB.tryDoorWarp(game, x, y)
  local Collision = require("src.core.game3.collision")
  if not SB.isOpenDoor(Collision.behavior(x, y)) then return false end
  local sess = session()
  -- pokeemerald/src/secret_base.c:674
  SB.curIdFromPosition(x, y, mapEvents(sess and sess.map))
  SB.trySetCurIndex(sess)
  return startScript("SecretBase_EventScript_Enter")
end

local function warpTo(mapId, x, y, facing, onDone)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local Warp = require("src.core.game3.warp")
  return Warp.scripted(Runtime and Runtime._mod, Runtime and Runtime._game, "warp", mapId, x, y, facing, onDone)
end

local function entranceWarp(g, sess)
  local mapId = SB.mapIdForGroup(g, sess)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local def = game and game.data and game.data.maps and game.data.maps[mapId]
  local w = def and def.warps and def.warps[(SB.manifest().entrances[g].warpId or 0) + 1]
  return mapId, w and tonumber(w.x) or 0, w and tonumber(w.y) or 0
end

-- pokeemerald/src/secret_base.c:446
function SB.enter(sess, onDone)
  sess = session(sess)
  local idx = var("VAR_CURRENT_SECRET_BASE", sess)
  local b = SB.base(sess, idx)
  if b.numTimesEntered < 255 then b.numTimesEntered = b.numTimesEntered + 1 end
  local P = player()
  -- pokeemerald/src/overworld.c:643
  sess.dynamicWarp = { map = sess.map, warpId = 0xFF, x = P.cellX, y = P.cellY }
  local mapId, x, y = entranceWarp(SB.groupOfId(SB._curId), sess)
  return warpTo(mapId, x, y, P.facing, onDone)
end

-- pokeemerald/src/secret_base.c:504
function SB.enterNewlyCreated(sess, onDone)
  sess = session(sess)
  local Fade = require("src.ui.game3.fade")
  local Field = require("src.core.game3.field")
  local Map = require("src.core.game3.map")
  local Runtime = package.loaded["src.core.game3.runtime"]
  local e = SB.manifest().entrances[SB.groupOfId(SB._curId)]
  local mapId = sess.map
  Field.lock()
  Fade.begin(Fade.MODE.TO_BLACK, 1, function()
    Map.load(Runtime and Runtime._mod, Runtime and Runtime._game, mapId, { x = e.x, y = e.y, facing = "up",
      depth1Connections = true })
    SB.onMapLoad(sess, nil, "warp")
    -- pokeemerald/src/secret_base.c:471
    Field.lock()
    local MapNamePopup = package.loaded["src.ui.game3.map_name_popup"]
    if MapNamePopup and MapNamePopup.dismiss then MapNamePopup.dismiss() end
    local grid = SB.fieldGrid()
    local pcMid = metatile("METATILE_SecretBase_PC", sess)
    local x, y = SB.findMetatile(grid, pcMid)
    if x then grid.setMetatile(x, y, pcMid, true) end
    player().facing = "up"
    Fade.begin(Fade.MODE.FROM_BLACK, 1, function()
      Field.unlock()
      if onDone then onDone() end
    end)
  end)
  return true
end

-- pokeemerald/src/secret_base.c:714
function SB.warpOut(sess, onDone)
  sess = session(sess)
  local dw = sess.dynamicWarp or {}
  local Field = require("src.core.game3.field")
  Field.lock()
  return warpTo(dw.map, tonumber(dw.x) or 0, tonumber(dw.y) or 0, "down", function()
    if onDone then onDone() end
  end)
end

-- pokeemerald/src/secret_base.c:720
function SB.ownedByAnotherPlayer(sess)
  return SB.base(sess, 0).secretBaseId ~= SB._curId
end

-- pokeemerald/src/secret_base.c:728; the European carts put the owner in the
-- row's STR_VAR_1 ("BASE DE {STR_VAR_1}", pret pokeemerald multi-language,
-- src/secret_base.c:732), the US and Japanese ones append the row to it.
function SB.name(idx, sess)
  local b = SB.base(sess, idx)
  local owner = tostring(b.trainerName or "")
  local ok, base = pcall(function()
    return require("src.core.game3.rom_text").plain("gText_ApostropheSBase", { stringVars = { "\1" } })
  end)
  if not ok then return owner .. "'s BASE" end
  if base:find("\1", 1, true) then return (base:gsub("\1", function() return owner end)) end
  return owner .. base
end

-- pokeemerald/src/secret_base.c:735
function SB.mapName(sess)
  return SB.name(var("VAR_CURRENT_SECRET_BASE", sess), sess)
end

function SB.ownerName(sess)
  return tostring(SB.base(sess, var("VAR_CURRENT_SECRET_BASE", sess)).trainerName or "")
end

-- pokeemerald/src/secret_base.c:759
local function averageEvs(mon)
  local ev = mon.evs or mon.EVs or {}
  local total = 0
  for _, k in ipairs({ "hp", "atk", "def", "spe", "spa", "spd" }) do total = total + (tonumber(ev[k]) or 0) end
  if total == 0 then
    for i = 1, 6 do total = total + (tonumber(ev[i]) or 0) end
  end
  return math.floor(total / 6)
end

-- pokeemerald/src/secret_base.c:771
function SB.setPlayerParty(sess)
  sess = session(sess)
  local b = SB.base(sess, 0)
  if b.secretBaseId == 0 then return end
  local p = b.party
  for i = 1, 6 do
    for m = 1, 4 do p.moves[(i - 1) * 4 + m] = 0 end
    p.species[i], p.heldItems[i], p.levels[i], p.personality[i], p.EVs[i] = 0, 0, 0, 0, 0
  end
  local n = 0
  for _, mon in ipairs(sess.party or {}) do
    if mon and (tonumber(mon.species) or 0) ~= 0 and not mon.isEgg then
      n = n + 1
      for m = 1, 4 do
        local mv = mon.moves and mon.moves[m]
        p.moves[(n - 1) * 4 + m] = tonumber(type(mv) == "table" and (mv.id or mv.move) or mv) or 0
      end
      p.species[n] = tonumber(mon.species) or 0
      p.heldItems[n] = tonumber(mon.heldItem or mon.item) or 0
      p.levels[n] = tonumber(mon.level) or 0
      p.personality[n] = tonumber(mon.personality) or 0
      p.EVs[n] = averageEvs(mon)
    end
  end
end

-- pokeemerald/src/secret_base.c:810
function SB.clearAndLeave(sess, onDone)
  sess = session(sess)
  local b = SB.base(sess, 0)
  local keep = b.numSecretBasesReceived
  clearBase(b)
  b.numSecretBasesReceived = keep
  return SB.warpOut(sess, onDone)
end

local function incrementStat(sess, id)
  if type(sess.gameStats) ~= "table" then sess.gameStats = {} end
  sess.gameStats[id] = math.min(0xFFFFFF, (tonumber(sess.gameStats[id]) or 0) + 1)
end

local function returnDecorations(sess)
  local b = SB.base(sess, 0)
  for i = 1, Decor.MAX_SECRET_BASE do b.decorations[i], b.decorationPositions[i] = 0, 0 end
end

-- pokeemerald/src/secret_base.c:818
function SB.moveOut(sess, onDone)
  sess = session(sess)
  incrementStat(sess, SB.GAME_STAT_MOVED_SECRET_BASE)
  returnDecorations(sess)
  return SB.clearAndLeave(sess, onDone)
end

-- pokeemerald/src/secret_base.c:824
function SB.closePlayerEntrance(sess, grid)
  sess = session(sess)
  grid = grid or SB.fieldGrid()
  local id = SB.base(sess, 0).secretBaseId
  for _, ev in ipairs(mapEvents(sess.map)) do
    if isBaseEvent(ev) and ev.secretBaseId == id then
      local mid = grid.metatile(ev.x, ev.y)
      for _, e in ipairs(entranceMetatiles()) do
        if e.open == mid then
          grid.setMetatile(ev.x, ev.y, e.closed, true)
          break
        end
      end
      break
    end
  end
end

-- pokeemerald/src/secret_base.c:856
function SB.moveOutFromOutside(sess, grid)
  sess = session(sess)
  SB.closePlayerEntrance(sess, grid)
  incrementStat(sess, SB.GAME_STAT_MOVED_SECRET_BASE)
  local b = SB.base(sess, 0)
  local keep = b.numSecretBasesReceived
  clearBase(b)
  b.numSecretBasesReceived = keep
end

-- pokeemerald/src/secret_base.c:751
function SB.isRegistered(idx, sess)
  return SB.base(sess, idx).registryStatus ~= 0
end

-- pokeemerald/src/secret_base.c:867
function SB.numRegistered(sess)
  local n = 0
  for i = 1, SB.COUNT - 1 do
    if SB.isRegistered(i, sess) then n = n + 1 end
  end
  return n
end

-- pokeemerald/src/secret_base.c:880
function SB.registrationValidity(sess)
  if SB.isRegistered(var("VAR_CURRENT_SECRET_BASE", sess), sess) then return 1 end
  if SB.numRegistered(sess) >= 10 then return 2 end
  return 0
end

-- pokeemerald/src/secret_base.c:890
function SB.toggleRegistry(sess)
  local b = SB.base(sess, var("VAR_CURRENT_SECRET_BASE", sess))
  b.registryStatus = bxor(b.registryStatus, 1)
  setFlag("FLAG_SECRET_BASE_REGISTRY_ENABLED", true, sess)
end

-- pokeemerald/src/secret_base.c:938
function SB.registryEntries(sess)
  local out = {}
  for i = 1, SB.COUNT - 1 do
    if SB.isRegistered(i, sess) then out[#out + 1] = { id = i, name = SB.name(i, sess) } end
  end
  return out
end

-- pokeemerald/src/secret_base.c:1075
function SB.unregister(idx, sess)
  SB.base(sess, idx).registryStatus = SB.UNREGISTERED
end

-- pokeemerald/src/secret_base.c:1132
function SB.ownerType(idx, sess)
  local b = SB.base(sess, idx)
  return (b.trainerId[1] or 0) % 5 + (b.gender or 0) * 5
end

-- pokeemerald/src/secret_base.c:1138
function SB.loseTextLabel(sess)
  return "SecretBase_Text_Trainer" .. SB.ownerType(var("VAR_CURRENT_SECRET_BASE", sess), sess) .. "Defeated"
end

-- pokeemerald/src/secret_base.c:1163
function SB.prepBattleFlags(sess)
  sess = session(sess)
  Rse.call("fanClub", "tryGainNewFanFromCounter", "TryGainNewFanFromCounter", nil, 1)
  sess.trainerBattleOpponentA = SB.TRAINER_SECRET_BASE
  sess.battleTypeFlags = bor(SB.BATTLE_TYPE_TRAINER, SB.BATTLE_TYPE_SECRET_BASE)
end

-- pokeemerald/src/secret_base.c:1170
function SB.setBattledOwner(result, sess)
  SB.base(sess, var("VAR_CURRENT_SECRET_BASE", sess)).battledOwnerToday = (tonumber(result) or 0) ~= 0 and 1 or 0
end

-- pokeemerald/src/secret_base.c:1175
function SB.ownerAndState(sess)
  local idx = var("VAR_CURRENT_SECRET_BASE", sess)
  if not flag("FLAG_DAILY_SECRET_BASE", sess) then
    for _, b in ipairs(SB.bases(sess)) do b.battledOwnerToday = 0 end
    setFlag("FLAG_DAILY_SECRET_BASE", true, sess)
  end
  return SB.ownerType(idx, sess), SB.base(sess, idx).battledOwnerToday
end

-- pokeemerald/src/secret_base.c:654
function SB.ownerGfxId(sess)
  local t = SB.ownerType(var("VAR_CURRENT_SECRET_BASE", sess), sess)
  return SB.manifest().ownerGfx[t + 1] or 0
end

-- pokeemerald/src/pokemon.c:4563
function SB.enemyParty(idx, sess)
  local b = SB.base(sess, idx)
  local out = {}
  for i = 1, 6 do
    if (b.party.species[i] or 0) ~= 0 then
      local moves = {}
      for m = 1, 4 do moves[m] = b.party.moves[(i - 1) * 4 + m] or 0 end
      out[#out + 1] = {
        species = b.party.species[i], level = b.party.levels[i], fixedIV = 15, personality = b.party.personality[i],
        heldItem = b.party.heldItems[i], ev = b.party.EVs[i], moves = moves,
      }
    end
  end
  return out, b
end

-- pokeemerald/src/pokemon.c:2057,4597-4605
-- pokeemerald/src/battle_tower.c:2032-2038
function SB.battleFoe(idx, sess)
  sess = session(sess)
  local partyRows, base = SB.enemyParty(idx, sess)
  if #partyRows == 0 then return nil end
  local D = require("src.core.game3.rse.frontier.trainers")
  local Rng = D.rng()
  local otId
  repeat
    otId = Rng.Random32()
  until not D.isShiny(otId, partyRows[1].personality)
  local party = {}
  for i, row in ipairs(partyRows) do
    local mon = D.createMon(row.species, row.level, 15, row.personality, otId,
      { otName = base.trainerName, otGender = base.gender, moves = row.moves })
    D.setEvs(mon, { row.ev, row.ev, row.ev, row.ev, row.ev, row.ev })
    D.setHeldItem(mon, row.heldItem)
    party[i] = mon
  end
  local facilityClasses = SB.manifest().facilityClasses or {}
  local classIndex = (tonumber(base.gender) or 0) * 5 + ((tonumber(base.trainerId[1]) or 0) % 5) + 1
  local facilityClass = facilityClasses[classIndex] or 0
  local trainerClass, trainerPic = D.secretBaseTrainerInfo(facilityClass)
  local className = D.className(sess, trainerClass)
  local first = party[1]
  local BP = require("src.core.game3.battle.profile")
  local profile = BP.get(sess)
  return {
    party = party,
    species = first.species,
    level = first.level,
    moves = first.moves,
    trainerId = SB.TRAINER_SECRET_BASE,
    trainerClass = trainerClass,
    trainerClassName = className,
    trainerName = base.trainerName,
    trainerPicId = trainerPic,
    song = BP.battleSong(profile, { trainerClass = trainerClass }),
  }, base
end

-- pokeemerald/src/battle_tower.c:2028-2038
function SB.doSpecialBattle(ctx, adapters, sess, which)
  if tonumber(which) ~= SB.SPECIAL_BATTLE_SECRET_BASE then return false end
  sess = session(sess)
  local index = var("VAR_CURRENT_SECRET_BASE", sess)
  local foe = SB.battleFoe(index, sess)
  local N = require("src.core.game3.scripting.natives")
  local function fail()
    local code = N.outcome_to_code("lose")
    Rse.setSpecialVar(ctx, Rse.varId("VAR_RESULT", sess), code)
    if sess then sess.battleOutcome = code end
    return false, code
  end
  if not foe then return fail() end
  local Runtime = package.loaded["src.core.game3.runtime"]
  local BattleBridge = require("src.core.game3.battle_bridge")
  local Transition = require("src.core.game3.battle_transition_ids_rse")
  local playerLevel = 5
  for _, mon in ipairs(sess.party or {}) do
    if (tonumber(mon.species) or 0) ~= 0 then playerLevel = math.max(playerLevel, tonumber(mon.level) or 1) end
  end
  local enemyLevel = 1
  for _, mon in ipairs(foe.party) do enemyLevel = math.max(enemyLevel, tonumber(mon.level) or 1) end
  local transitionId = Transition.pickSpecial("secret_base", { playerLevel = playerLevel, enemyLevel = enemyLevel })
  return N.yieldHost(ctx, adapters, function(done)
    local function finish(result)
      local code = N.outcome_to_code(result or "win")
      Rse.setSpecialVar(ctx, Rse.varId("VAR_RESULT", sess), code)
      sess.battleOutcome = code
      if ctx then ctx.lastBattleOutcome = code end
      done()
      local Space = package.loaded["src.core.game3.scripting.space"]
      if Space and Space.vm then Space.vm:tick() end
    end
    local ok, err = BattleBridge.start(Runtime and Runtime._mod, Runtime and Runtime._game, foe, {
      wild = false,
      trainerId = SB.TRAINER_SECRET_BASE,
      trainerName = foe.trainerName,
      trainerClass = foe.trainerClass,
      trainerClassName = foe.trainerClassName,
      trainerPicId = foe.trainerPicId,
      secretBase = true,
      noWhiteout = true,
      deferHeal = true,
      transitionId = transitionId,
      done = finish,
    })
    if not ok then
      local msg = "[game3] Secret Base battle did not start (" .. tostring(err) .. ")"
      if adapters and adapters.log then adapters.log(msg) else print(msg) end
      fail()
      done()
    end
  end)
end

-- pokeemerald/src/secret_base.c:1804
function SB.initVars(sess)
  if not Rse.varId("VAR_SECRET_BASE_IS_NOT_LOCAL", sess) then return end
  setVar("VAR_SECRET_BASE_STEP_COUNTER", 0, sess)
  setVar("VAR_SECRET_BASE_LAST_ITEM_USED", 0, sess)
  setVar("VAR_SECRET_BASE_LOW_TV_FLAGS", 0, sess)
  setVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", 0, sess)
  setVar("VAR_SECRET_BASE_IS_NOT_LOCAL", var("VAR_CURRENT_SECRET_BASE", sess) ~= 0 and 1 or 0, sess)
  SB._inFriendBase = false
end

-- pokeemerald/src/secret_base.c:1818
function SB.checkLeftFriendsBase(sess)
  if not Rse.varId("VAR_SECRET_BASE_IS_NOT_LOCAL", sess) then return end
  if var("VAR_SECRET_BASE_IS_NOT_LOCAL", sess) ~= 0 and SB._inFriendBase and not SB.curMapIsSecretBase(sess) then
    setVar("VAR_SECRET_BASE_IS_NOT_LOCAL", 0, sess)
    SB._inFriendBase = false
    local b = SB.base(sess, var("VAR_CURRENT_SECRET_BASE", sess))
    Rse.call("tv", "tryPutSecretBaseSecretsOnAir", "TryPutSecretBaseSecretsOnAir", nil, b.trainerName, b.language)
    setVar("VAR_SECRET_BASE_STEP_COUNTER", 0, sess)
    setVar("VAR_SECRET_BASE_LAST_ITEM_USED", 0, sess)
    setVar("VAR_SECRET_BASE_LOW_TV_FLAGS", 0, sess)
    setVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", 0, sess)
    setVar("VAR_SECRET_BASE_IS_NOT_LOCAL", 0, sess)
  end
end

local function friendBase(sess)
  if not Rse.varId("VAR_SECRET_BASE_IS_NOT_LOCAL", sess) then return false end
  return var("VAR_CURRENT_SECRET_BASE", sess) ~= 0
end

local function battleOutcome(lowBit, highBit)
  if not friendBase() then return end
  local L, H = SB.LOW, SB.HIGH
  setVar("VAR_SECRET_BASE_LOW_TV_FLAGS",
    band(var("VAR_SECRET_BASE_LOW_TV_FLAGS"), bnot(bor(L.BATTLED_WON, L.BATTLED_LOST, L.DECLINED_BATTLE))) % 0x10000)
  setVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", band(var("VAR_SECRET_BASE_HIGH_TV_FLAGS"), bnot(H.BATTLED_DRAW)) % 0x10000)
  if lowBit then orVar("VAR_SECRET_BASE_LOW_TV_FLAGS", lowBit) end
  if highBit then orVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", highBit) end
end

-- pokeemerald/src/secret_base.c:1845
function SB.declinedBattle() battleOutcome(SB.LOW.DECLINED_BATTLE, nil) end
-- pokeemerald/src/secret_base.c:1855
function SB.wonBattle() battleOutcome(SB.LOW.BATTLED_WON, nil) end
-- pokeemerald/src/secret_base.c:1865
function SB.lostBattle() battleOutcome(SB.LOW.BATTLED_LOST, nil) end
-- pokeemerald/src/secret_base.c:1875
function SB.drewBattle() battleOutcome(nil, SB.HIGH.BATTLED_DRAW) end

function SB.markLow(bits)
  if friendBase() then orVar("VAR_SECRET_BASE_LOW_TV_FLAGS", bits) end
end

function SB.markHigh(bits)
  if friendBase() then orVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", bits) end
end

local function frontMetatileIn(names)
  local x, y = SB.frontOfPlayer()
  local mid = SB.fieldGrid().metatile(x, y)
  for _, n in ipairs(names) do
    local ok, v = pcall(metatile, n)
    if ok and v == mid then return true end
  end
  return false
end

local function labels(prefix, list)
  local out = {}
  for _, s in ipairs(list) do out[#out + 1] = "METATILE_SecretBase_" .. prefix .. s end
  return out
end

-- pokeemerald/src/secret_base.c:1885
SB.POSTERS = labels("", { "PikaPoster_Left", "PikaPoster_Right", "LongPoster_Left", "LongPoster_Right", "SeaPoster_Left",
  "SeaPoster_Right", "SkyPoster_Left", "SkyPoster_Right", "KissPoster_Left", "KissPoster_Right", "BallPoster",
  "GreenPoster", "RedPoster", "BluePoster", "CutePoster" })

function SB.checkPoster()
  if frontMetatileIn(SB.POSTERS) then SB.markLow(SB.LOW.USED_POSTER) end
end

local DESK_BOTTOM = labels("", { "SmallDesk", "PokemonDesk", "HeavyDesk_BottomLeft", "HeavyDesk_BottomMid",
  "HeavyDesk_BottomRight", "RaggedDesk_BottomLeft", "RaggedDesk_BottomMid", "RaggedDesk_BottomRight",
  "ComfortDesk_BottomLeft", "ComfortDesk_BottomMid", "ComfortDesk_BottomRight", "BrickDesk_BottomLeft",
  "BrickDesk_BottomMid", "BrickDesk_BottomRight", "CampDesk_BottomLeft", "CampDesk_BottomMid", "CampDesk_BottomRight",
  "HardDesk_BottomLeft", "HardDesk_BottomMid", "HardDesk_BottomRight", "PrettyDesk_BottomLeft", "PrettyDesk_BottomMid",
  "PrettyDesk_BottomRight" })
local PLANTS = labels("", { "RedPlant_Base1", "RedPlant_Base2", "TropicalPlant_Base1", "TropicalPlant_Base2",
  "PrettyFlowers_Base1", "PrettyFlowers_Base2", "ColorfulPlant_BaseLeft1", "ColorfulPlant_BaseRight1",
  "ColorfulPlant_BaseLeft2", "ColorfulPlant_BaseRight2", "BigPlant_BaseLeft1", "BigPlant_BaseRight1",
  "BigPlant_BaseLeft2", "BigPlant_BaseRight2", "GorgeousPlant_BaseLeft1", "GorgeousPlant_BaseRight1",
  "GorgeousPlant_BaseLeft2", "GorgeousPlant_BaseRight2" })

-- pokeemerald/src/secret_base.c:1913
function SB.checkFurnitureBottom()
  if frontMetatileIn(labels("", { "GlassOrnament_Base1", "GlassOrnament_Base2" })) then
    SB.markLow(SB.LOW.USED_GLASS_ORNAMENT)
  elseif frontMetatileIn(PLANTS) then
    SB.markLow(SB.LOW.USED_PLANT)
  elseif frontMetatileIn(labels("", { "Fence_Horizontal", "Fence_Vertical" })) then
    SB.markHigh(SB.HIGH.USED_FENCE)
  elseif frontMetatileIn(labels("", { "Tire_BottomLeft", "Tire_BottomRight" })) then
    SB.markHigh(SB.HIGH.USED_TIRE)
  elseif frontMetatileIn(labels("", { "RedBrick_Bottom", "YellowBrick_Bottom", "BlueBrick_Bottom" })) then
    SB.markHigh(SB.HIGH.USED_BRICK)
  elseif frontMetatileIn(DESK_BOTTOM) then
    SB.markHigh(SB.HIGH.USED_DESK)
  end
end

-- pokeemerald/src/secret_base.c:1991
function SB.checkFurnitureMiddle()
  if frontMetatileIn(labels("", { "HeavyDesk_TopMid", "RaggedDesk_TopMid", "ComfortDesk_TopMid", "BrickDesk_TopMid",
      "BrickDesk_Center", "CampDesk_TopMid", "CampDesk_Center", "HardDesk_TopMid", "HardDesk_Center",
      "PrettyDesk_TopMid", "PrettyDesk_Center" })) then
    SB.markHigh(SB.HIGH.USED_DESK)
  end
end

-- pokeemerald/src/secret_base.c:2015
function SB.checkFurnitureTop()
  if frontMetatileIn(labels("", { "HeavyDesk_TopLeft", "HeavyDesk_TopRight", "RaggedDesk_TopLeft", "RaggedDesk_TopRight",
      "ComfortDesk_TopLeft", "ComfortDesk_TopRight", "BrickDesk_TopLeft", "BrickDesk_TopRight", "BrickDesk_MidLeft",
      "BrickDesk_MidRight", "CampDesk_TopLeft", "CampDesk_TopRight", "CampDesk_MidLeft", "CampDesk_MidRight",
      "HardDesk_TopLeft", "HardDesk_TopRight", "HardDesk_MidLeft", "HardDesk_MidRight", "PrettyDesk_TopLeft",
      "PrettyDesk_TopRight", "PrettyDesk_MidLeft", "PrettyDesk_MidRight" })) then
    SB.markHigh(SB.HIGH.USED_DESK)
  elseif frontMetatileIn(labels("", { "Tire_TopLeft", "Tire_TopRight" })) then
    SB.markHigh(SB.HIGH.USED_TIRE)
  elseif frontMetatileIn(labels("", { "RedBrick_Top", "YellowBrick_Top", "BlueBrick_Top" })) then
    SB.markHigh(SB.HIGH.USED_BRICK)
  end
end

-- pokeemerald/src/secret_base.c:2061
function SB.checkSandOrnament()
  if frontMetatileIn(labels("", { "SandOrnament_Base1", "SandOrnament_Base2" })) then
    SB.markHigh(SB.HIGH.USED_SAND_ORNAMENT)
  end
end

-- pokeemerald/src/fldeff_misc.c:1119
function SB.shieldOrTv()
  local x, y = SB.frontOfPlayer()
  local mid = SB.fieldGrid().metatile(x, y)
  local rows = {
    { "METATILE_SecretBase_GoldShield_Base1", 0, "100", "gText_Gold", SB.LOW.USED_GOLD_SHIELD },
    { "METATILE_SecretBase_SilverShield_Base1", 0, "50", "gText_Silver", SB.LOW.USED_SILVER_SHIELD },
    { "METATILE_SecretBase_TV", 1, nil, nil, SB.LOW.USED_TV },
    { "METATILE_SecretBase_RoundTV", 2, nil, nil, SB.LOW.USED_TV },
    { "METATILE_SecretBase_CuteTV", 3, nil, nil, SB.LOW.USED_TV },
  }
  for _, r in ipairs(rows) do
    local ok, v = pcall(metatile, r[1])
    if ok and v == mid then
      SB.markLow(r[5])
      return r[2], r[3], r[4]
    end
  end
  return nil
end

local BALLOONS = { "METATILE_SecretBase_RedBalloon", "METATILE_SecretBase_BlueBalloon", "METATILE_SecretBase_YellowBalloon" }
local CHAIRS = labels("", { "SmallChair", "PokemonChair", "HeavyChair", "PrettyChair", "ComfortChair", "RaggedChair",
  "BrickChair", "CampChair", "HardChair" })

local function midIn(mid, names)
  for _, n in ipairs(names) do
    local ok, v = pcall(metatile, n)
    if ok and v == mid then return true end
  end
  return false
end

-- pokeemerald/src/secret_base.c:1198
function SB.perStep(game, data)
  local FldeffMisc = require("src.core.game3.fldeff_misc")
  local P = player()
  local function dest()
    if P.moving and P.targetX then return P.targetX, P.targetY end
    return P.cellX, P.cellY
  end
  if (data.state or 0) == 0 then
    SB._inFriendBase = friendBase()
    data.x, data.y = dest()
    data.state = 1
    return false
  end
  local x, y = dest()
  if x == data.x and y == data.y then return false end
  data.x, data.y = x, y
  if Rse.varId("VAR_SECRET_BASE_STEP_COUNTER") then
    setVar("VAR_SECRET_BASE_STEP_COUNTER", (var("VAR_SECRET_BASE_STEP_COUNTER") + 1) % 0x10000)
  end
  local grid = SB.fieldGrid()
  local beh = grid.behavior(x, y)
  local mid = grid.metatile(x, y)
  local friend = SB._inFriendBase
  local function low(b) if friend then orVar("VAR_SECRET_BASE_LOW_TV_FLAGS", b) end end
  local function high(b) if friend then orVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", b) end end
  if midIn(mid, { "METATILE_SecretBase_SolidBoard_Top", "METATILE_SecretBase_SolidBoard_Bottom" }) then
    high(SB.HIGH.USED_SOLID_BOARD)
  elseif midIn(mid, CHAIRS) then
    low(SB.LOW.USED_CHAIR)
  elseif midIn(mid, labels("", { "RedTent_DoorTop", "RedTent_Door", "BlueTent_DoorTop", "BlueTent_Door" })) then
    low(SB.LOW.USED_TENT)
  elseif (Decor.isBeh(beh, "IMPASSABLE_NORTHEAST") and midIn(mid, { "METATILE_SecretBase_Stand_CornerRight" }))
      or (Decor.isBeh(beh, "IMPASSABLE_NORTHWEST") and midIn(mid, { "METATILE_SecretBase_Stand_CornerLeft" })) then
    high(SB.HIGH.USED_STAND)
  elseif Decor.isBeh(beh, "IMPASSABLE_WEST_AND_EAST") and midIn(mid, { "METATILE_SecretBase_Slide_StairLanding" }) then
    if friend then
      setVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", bxor(var("VAR_SECRET_BASE_HIGH_TV_FLAGS"), SB.HIGH.USED_SLIDE))
      orVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", SB.HIGH.DECLINED_SLIDE)
    end
  elseif Decor.isBeh(beh, "SLIDE_SOUTH") and midIn(mid, { "METATILE_SecretBase_Slide_SlideTop" }) then
    if friend then
      orVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", SB.HIGH.USED_SLIDE)
      setVar("VAR_SECRET_BASE_HIGH_TV_FLAGS", bxor(var("VAR_SECRET_BASE_HIGH_TV_FLAGS"), SB.HIGH.DECLINED_SLIDE))
    end
  elseif Decor.isBeh(beh, "SECRET_BASE_GLITTER_MAT") then
    high(SB.HIGH.USED_GLITTER_MAT)
  elseif Decor.isBeh(beh, "SECRET_BASE_BALLOON") then
    FldeffMisc.popBalloon(mid, x, y)
    if midIn(mid, BALLOONS) then
      low(SB.LOW.USED_BALLOON)
    elseif midIn(mid, { "METATILE_SecretBase_MudBall" }) then
      low(SB.LOW.USED_MUD_BALL)
    end
  elseif Decor.isBeh(beh, "SECRET_BASE_BREAKABLE_DOOR") then
    high(SB.HIGH.USED_BREAKABLE_DOOR)
    FldeffMisc.shatterBreakableDoor(x, y)
  elseif Decor.isBeh(beh, "SECRET_BASE_SOUND_MAT") then
    low(SB.LOW.USED_NOTE_MAT)
  elseif Decor.isBeh(beh, "SECRET_BASE_JUMP_MAT") then
    high(SB.HIGH.USED_JUMP_MAT)
  elseif Decor.isBeh(beh, "SECRET_BASE_SPIN_MAT") then
    high(SB.HIGH.USED_SPIN_MAT)
  end
  return false
end

local function objectsMod()
  return package.loaded["src.core.game3.objects"] or require("src.core.game3.objects")
end

local function flagStore()
  return Rse.store()
end

local function setFlagId(id, on)
  require("src.core.game3.scripting.flags").setFlag(flagStore(), nil, id, on)
end

local function templates()
  return objectsMod()._defs or {}
end

local function gfxVarFor(def, sess)
  local g = tonumber(def.graphicsId or def.graphics) or 0
  return consts(sess):require("vars", "VAR_OBJ_GFX_ID_0") + (g - consts(sess):require("event_objects", "OBJ_EVENT_GFX_VAR_0"))
end

local function spawnDecorationObject(def, decor, x, y, sess, nativeInfo)
  local Flags = require("src.core.game3.scripting.flags")
  local d = nativeInfo or Decor.info(decor)
  Flags.setVar(flagStore(), nil, gfxVarFor(def, sess), d.tiles[1] or 0)
  local lid = tonumber(def.localId or def.index) or 0
  local flagId = tonumber(def.flag or def.flagId) or 0
  setFlagId(flagId, false)
  local O = objectsMod()
  O.syncFlagVisibility(flagId, false, true)
  O.addObject(lid)
  O.setObjectXY(lid, x, y)
  O.copyObjectXYToPerm(lid)
  if O.refreshGraphics then O.refreshGraphics() end
  return lid
end

-- pokeemerald/src/secret_base.c:552
function SB.initDecorationSprites(counter, sess, grid, opts)
  sess = session(sess)
  grid = grid or SB.fieldGrid()
  counter = tonumber(counter) or 0
  opts = opts or {}
  local items, pos
  local inBase = SB.curMapIsSecretBase(sess)
  if inBase then
    local b = SB.base(sess, var("VAR_CURRENT_SECRET_BASE", sess))
    items, pos = b.decorations, b.decorationPositions
  else
    local ctx = Decor.context(sess, true)
    items, pos = ctx.items, ctx.pos
  end
  local first = opts.flagFirst or SB.decorationFlagRange(sess)
  local spawned = {}
  for i = 1, #items do
    local decor = items[i]
    local nativeInfo = opts.decorations and opts.decorations[decor]
    local sprite = nativeInfo and nativeInfo.permission == Decor.PERM.SPRITE
    if decor ~= 0 and (opts.decorations and sprite or not opts.decorations and Decor.isSprite(decor)) then
      local def
      for _, t in ipairs(templates()) do
        if tonumber(t.flag or t.flagId) == first + counter then def = t break end
      end
      if def then
        local x, y = Decor.decodePos(pos[i])
        if opts.onPosition then opts.onPosition(x, y) end
        local beh = grid.behavior(x, y)
        if Decor.isBeh(beh, "HOLDS_SMALL_DECORATION") or Decor.isBeh(beh, "HOLDS_LARGE_DECORATION") then
          local lid = spawnDecorationObject(def, decor, x, y, sess, nativeInfo)
          local basePolicy = Rse.profile(sess).secretBase
          if not opts.nativeRS and not (basePolicy and basePolicy.preserveDecorationScripts)
              and inBase and var("VAR_CURRENT_SECRET_BASE", sess) ~= 0 then
            local cat = require("src.core.game3.rse.decoration_inventory").categoryOf(decor)
            local eo = objectsMod().find(lid)
            -- pokeemerald/src/event_object_movement.c:2515
            if eo and eo.def and (cat == Decor.CAT.DOLL or cat == Decor.CAT.CUSHION) then
              local Space = package.loaded["src.core.game3.scripting.space"]
              eo.def.scriptKey = Space and Space.scriptKey(cat == Decor.CAT.DOLL and "SecretBase_EventScript_DollInteract"
                or "SecretBase_EventScript_CushionInteract")
            end
          end
          spawned[#spawned + 1] = lid
          counter = counter + 1
          if opts.onSpawn then opts.onSpawn(lid, counter) end
        end
      end
    end
  end
  return counter, spawned
end

-- pokeemerald/src/secret_base.c:635
function SB.hideDecorationSprites(sess)
  local lo, hi = SB.decorationFlagRange(sess)
  local O = objectsMod()
  for _, t in ipairs(templates()) do
    local f = tonumber(t.flag or t.flagId) or 0
    if f >= lo and f <= hi then
      O.removeObject(tonumber(t.localId or t.index) or 0)
      setFlagId(f, true)
    end
  end
end

-- pokeemerald/src/decoration.c:1282
function SB.setDecoration(decor, x, y, sess)
  local lo, hi = SB.decorationFlagRange(sess)
  local Flags = require("src.core.game3.scripting.flags")
  for f = lo, hi do
    if Flags.getFlag(flagStore(), nil, f) then
      for _, t in ipairs(templates()) do
        if tonumber(t.flag or t.flagId) == f then
          return spawnDecorationObject(t, decor, x, y, sess)
        end
      end
      return nil
    end
  end
  return nil
end

-- pokeemerald/src/fldeff_misc.c:547
function SB.setUpFieldMove(ctx)
  local sess = session(ctx and ctx.session)
  if SB.playerHasBase(sess) then return { ok = false } end
  local P = player()
  if P.facing ~= "up" then return { ok = false } end
  local x, y = SB.frontOfPlayer()
  local Collision = require("src.core.game3.collision")
  local beh = Collision.behavior(x, y)
  local label
  if SB.isCave(beh) then
    label = "SecretBase_EventScript_CaveUseSecretPower"
  elseif SB.isTree(beh) then
    label = "SecretBase_EventScript_TreeUseSecretPower"
  elseif SB.isShrub(beh) then
    label = "SecretBase_EventScript_ShrubUseSecretPower"
  else
    return { ok = false }
  end
  SB.curIdFromPosition(x, y, mapEvents(sess and sess.map))
  SB.trySetCurIndex(sess)
  local slot = ctx and ctx.slot
  if not slot and ctx and ctx.party and ctx.mon then
    for i, m in ipairs(ctx.party) do if m == ctx.mon then slot = i end end
  end
  local Task = require("src.core.game3.task")
  -- pokeemerald/src/fldeff_misc.c:586
  Task.spawn(function()
    local Runtime = package.loaded["src.core.game3.runtime"]
    if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return false end
    require("src.core.game3.field_effects").setFieldEffectArgument(0, (tonumber(slot) or 1) - 1)
    startScript(label)
    return true
  end)
  return { ok = true, action = "secret_power", secretPowerScript = label }
end

local function copyBase(b)
  local out = {}
  for k, v in pairs(b) do
    if type(v) == "table" then
      local t = {}
      for k2, v2 in pairs(v) do
        if type(v2) == "table" then
          local u = {}
          for k3, v3 in pairs(v2) do u[k3] = v3 end
          t[k2] = u
        else
          t[k2] = v2
        end
      end
      out[k] = t
    else
      out[k] = v
    end
  end
  return out
end

-- pokeemerald/src/record_mixing.c:222
function SB.mixExport(sess)
  sess = session(sess)
  pcall(SB.setPlayerParty, sess)
  local out = {}
  for i, b in ipairs(SB.bases(sess)) do out[i] = copyBase(b) end
  return out
end

local function on(v)
  return v == true or v == 1
end

local function nameChars(s)
  return tostring(s or ""):sub(1, SB.PLAYER_NAME_LENGTH)
end

local function sameTrainerId(a, b)
  for i = 1, SB.TRAINER_ID_LENGTH do
    if (tonumber(a.trainerId[i]) or 0) ~= (tonumber(b.trainerId[i]) or 0) then return false end
  end
  return true
end

-- pokeemerald/src/secret_base.c:1383
local function belongToSamePlayer(a, b)
  return (a.gender or 0) == (b.gender or 0) and sameTrainerId(a, b) and nameChars(a.trainerName) == nameChars(b.trainerName)
end

-- pokeemerald/src/secret_base.c:1519
local function belongsToPlayer(b, sess)
  if (b.secretBaseId or 0) == 0 then return false end
  if b.gender ~= playerGender(sess) then return false end
  if not sameTrainerId(b, { trainerId = trainerIdBytes(sess) }) then return false end
  return nameChars(b.trainerName) == nameChars(sess.name or sess.playerName)
end

-- pokeemerald/src/secret_base.c:1395
local function indexFromId(saved, id)
  for i = 0, SB.COUNT - 1 do
    if saved[i + 1].secretBaseId == id then return i end
  end
  return -1
end

-- pokeemerald/src/secret_base.c:1336
local function saveBase(saved, idx, b)
  saved[idx + 1] = normalize(copyBase(b))
  saved[idx + 1].registryStatus = SB.NEW
end

-- pokeemerald/src/secret_base.c:1432
local function trySaveFriendsBase(saved, b)
  if (b.secretBaseId or 0) == 0 then return 0 end
  local index = indexFromId(saved, b.secretBaseId)
  if index == 0 then return 0 end
  if index ~= -1 then
    if on(saved[index + 1].toRegister) then return 0 end
    if saved[index + 1].registryStatus ~= SB.NEW or on(b.toRegister) then
      saveBase(saved, index, b)
      return index
    end
    return 0
  end
  for i = 1, SB.COUNT - 1 do
    if saved[i + 1].secretBaseId == 0 then
      saveBase(saved, i, b)
      return i
    end
  end
  for i = 1, SB.COUNT - 1 do
    if saved[i + 1].registryStatus == SB.UNREGISTERED and not on(saved[i + 1].toRegister) then
      saveBase(saved, i, b)
      return i
    end
  end
  return 0
end

-- pokeemerald/src/secret_base.c:1486
local function sortByRegistryStatus(saved)
  for i = 1, SB.COUNT - 2 do
    for j = i + 1, SB.COUNT - 1 do
      local a, b = saved[i + 1], saved[j + 1]
      if (a.registryStatus == SB.UNREGISTERED and b.registryStatus == SB.REGISTERED)
        or (a.registryStatus == SB.NEW and b.registryStatus ~= SB.NEW) then
        saved[i + 1], saved[j + 1] = b, a
      end
    end
  end
end

-- pokeemerald/src/secret_base.c:1509
local function trySaveFriendsBases(saved, mixer, status)
  for i = 1, SB.COUNT - 1 do
    if mixer[i + 1].registryStatus == status then trySaveFriendsBase(saved, mixer[i + 1]) end
  end
end

-- pokeemerald/src/secret_base.c:1549
local function deleteFirstOldBaseFromPlayer(mixers, sess)
  local done = { false, false, false }
  for i = 1, SB.COUNT do
    for m = 1, 3 do
      if not done[m] and belongsToPlayer(mixers[m][i], sess) then
        clearBase(mixers[m][i])
        done[m] = true
      end
    end
    if done[1] and done[2] and done[3] then break end
  end
end

-- pokeemerald/src/secret_base.c:1595
local function clearDuplicateOwned(b, list, idx)
  for i = 1, SB.COUNT do
    local other = list[i]
    if other.secretBaseId ~= 0 and belongToSamePlayer(b, other) then
      if idx == 0 then
        clearBase(other)
        return false
      end
      if (b.numSecretBasesReceived or 0) > (other.numSecretBasesReceived or 0) then
        clearBase(other)
        return false
      end
      other.toRegister = b.toRegister
      clearBase(b)
      return true
    end
  end
  return false
end

-- pokeemerald/src/secret_base.c:1627
local function clearDuplicateOwnedBases(saved, a, b, c)
  for i = 1, SB.COUNT - 1 do
    local mine = saved[i + 1]
    if mine.secretBaseId ~= 0 then
      if mine.registryStatus == SB.REGISTERED then mine.toRegister = 1 end
      if not clearDuplicateOwned(mine, a, i) then
        if not clearDuplicateOwned(mine, b, i) then clearDuplicateOwned(mine, c, i) end
      end
    end
  end
  for i = 0, SB.COUNT - 1 do
    if a[i + 1].secretBaseId ~= 0 then
      a[i + 1].battledOwnerToday = 0
      if not clearDuplicateOwned(a[i + 1], b, i) then clearDuplicateOwned(a[i + 1], c, i) end
    end
  end
  for i = 0, SB.COUNT - 1 do
    if b[i + 1].secretBaseId ~= 0 then
      b[i + 1].battledOwnerToday = 0
      clearDuplicateOwned(b[i + 1], c, i)
    end
    if c[i + 1].secretBaseId ~= 0 then c[i + 1].battledOwnerToday = 0 end
  end
end

-- pokeemerald/src/secret_base.c:1696
local function saveRecordMixBases(saved, mixers, sess)
  deleteFirstOldBaseFromPlayer(mixers, sess)
  clearDuplicateOwnedBases(saved, mixers[1], mixers[2], mixers[3])
  -- pokeemerald/src/secret_base.c:1684
  for i = 1, SB.COUNT do
    for m = 1, 3 do
      local b = mixers[m][i]
      if on(b.toRegister) then
        trySaveFriendsBase(saved, b)
        clearBase(b)
      end
    end
  end
  for m = 1, 3 do trySaveFriendsBase(saved, mixers[m][1]) end
  for m = 1, 3 do trySaveFriendsBases(saved, mixers[m], SB.REGISTERED) end
  for m = 1, 3 do trySaveFriendsBases(saved, mixers[m], SB.UNREGISTERED) end
end

local function mixerList(list)
  local out = {}
  for i = 1, SB.COUNT do
    local b = type(list) == "table" and list[i] or nil
    out[i] = normalize(type(b) == "table" and copyBase(b) or nil)
    out[i].secretBaseId = tonumber(out[i].secretBaseId) or 0
    out[i].registryStatus = tonumber(out[i].registryStatus) or 0
  end
  return out
end

-- pokeemerald/src/secret_base.c:1731
function SB.mixImport(sess, records, myIndex)
  sess = session(sess)
  local okF, received = pcall(flag, "FLAG_RECEIVED_SECRET_POWER", sess)
  if not (okF and received) then return true end
  records = records or {}
  local count = #records
  local slots = {}
  for i = 0, 3 do slots[i] = i < count and records[i + 1] or nil end
  local linkIdx = (tonumber(myIndex) or 1) - 1
  local mixers = {}
  for k = 1, 3 do mixers[k] = mixerList(slots[(linkIdx + k) % 4]) end
  local saved = SB.bases(sess)
  saveRecordMixBases(saved, mixers, sess)
  for i = 1, SB.COUNT - 1 do
    if on(saved[i + 1].toRegister) then
      saved[i + 1].registryStatus = SB.REGISTERED
      saved[i + 1].toRegister = 0
    end
  end
  sortByRegistryStatus(saved)
  for i = 1, SB.COUNT - 1 do
    if saved[i + 1].registryStatus == SB.NEW then saved[i + 1].registryStatus = SB.UNREGISTERED end
  end
  local mine = saved[1]
  if mine.secretBaseId ~= 0 and (mine.numSecretBasesReceived or 0) ~= 0xFFFF then
    mine.numSecretBasesReceived = (mine.numSecretBasesReceived or 0) + 1
  end
  return true
end

function SB.reset()
  SB._curId = 0
  SB._inFriendBase = false
  groupMaps = nil
end

Rse.register("secretBase", SB)
Rse.register("secretBaseField", { setUpFieldMove = SB.setUpFieldMove })
Rse.register("decorationMenu", {
  open = function(opts)
    local ui = require("src.ui.game3.screens").get("decoration", opts and opts.session)
      or require("src.ui.game3.rse.decoration")
    return ui.openPlayerRoom(opts)
  end,
  chooseForTrade = function(ctx, done)
    local ui = require("src.ui.game3.screens").get("decoration", session())
      or require("src.ui.game3.rse.decoration")
    return ui.openTrade(ctx, done)
  end,
})

do
  local ok, Forced = pcall(require, "src.core.game3.forced_movement")
  if ok and Forced and Forced.registerStepCallback then
    Forced.registerStepCallback("secretBase", SB.perStep)
  end
end

do
  local SaveSections = require("src.core.game3.save_sections")
  SaveSections.register("secretBases", SaveSections.fields({ "secretBases", "playerRoomDecorationPositions" }))
end

return SB
