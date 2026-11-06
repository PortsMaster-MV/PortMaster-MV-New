local Kit = require("src.ui.game3.rse.scene_kit")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Mapsec = require("src.ui.game3.rse.mapsec")
local Pal = require("src.core.game3.pal_fade")

local RegionMap = {}

RegionMap.ID = "rse_region_map"
RegionMap.SUB = "data/generated/gba/rse/region_map"

-- pokeemerald/src/region_map.c:41
RegionMap.MAP_WIDTH = 28
RegionMap.MAP_HEIGHT = 15
RegionMap.CURSOR_X_MIN = 1
RegionMap.CURSOR_Y_MIN = 2
RegionMap.CURSOR_X_MAX = 28
RegionMap.CURSOR_Y_MAX = 16

-- pokeemerald/include/region_map.h:11
RegionMap.INPUT = { NONE = 0, MOVE_START = 1, MOVE_CONT = 2, MOVE_END = 3, A = 4, B = 5 }
-- pokeemerald/include/region_map.h:20
RegionMap.TYPE = { NONE = 0, ROUTE = 1, CITY_CANFLY = 2, CITY_CANTFLY = 3, BATTLE_FRONTIER = 4 }

local INPUT, TYPE = RegionMap.INPUT, RegionMap.TYPE

local manifest

function RegionMap.manifest()
  if manifest then return manifest end
  manifest = assert(Kit.loadLua(RegionMap.SUB .. "/manifest.lua"), "rse region map manifest missing from the cache")
  return manifest
end

local function constants(session)
  local Profile = require("src.core.game3.profile")
  return require("src.core.game3.constants").of(Profile.forSession(session).id)
end

local function flagSet(s, name)
  local id = type(name) == "number" and name or constants(s.session):flag(name)
  if not id then return false end
  local Space = package.loaded["src.core.game3.scripting.space"]
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  if Space and Space.store and Flags and Flags.getFlag then
    return Flags.getFlag(Space.store, nil, id) == true
  end
  local f = s.session and s.session.flags
  return f ~= nil and (f[id] == true or f[id] == 1)
end

local function varGet(s, name)
  local id = constants(s.session):var(name)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  if id and Space and Space.store and Flags and Flags.getVar then
    return tonumber(Flags.getVar(Space.store, nil, id)) or 0
  end
  local v = s.session and s.session.vars
  return tonumber(v and id and v[id]) or 0
end

local function sec(name)
  return RegionMap.manifest().mapsecs[name]
end
RegionMap.mapsec = sec

-- pokeemerald/src/region_map.c:957
function RegionMap.mapSecAt(x, y)
  if y < RegionMap.CURSOR_Y_MIN or y > RegionMap.CURSOR_Y_MAX or x < RegionMap.CURSOR_X_MIN or x > RegionMap.CURSOR_X_MAX then
    return sec("NONE")
  end
  return RegionMap.manifest().layout[y - RegionMap.CURSOR_Y_MIN + 1][x - RegionMap.CURSOR_X_MIN + 1]
end

-- pokeemerald/src/region_map.c:1175
function RegionMap.mapSecType(s, id)
  if id == sec("NONE") then return TYPE.NONE end
  local first, last = sec("LITTLEROOT_TOWN"), sec("EVER_GRANDE_CITY")
  if id >= first and id <= last then
    local visited = constants(s.session):flag("FLAG_VISITED_LITTLEROOT_TOWN") + (id - first)
    return flagSet(s, visited) and TYPE.CITY_CANFLY or TYPE.CITY_CANTFLY
  end
  -- pokeruby/src/region_map.c:731
  if RegionMap.manifest().assetLayout == "rs" and id == sec("BATTLE_TOWER") then
    return flagSet(s, "FLAG_LANDMARK_BATTLE_TOWER") and TYPE.BATTLE_FRONTIER or TYPE.NONE
  end
  if id == sec("BATTLE_FRONTIER") then
    return flagSet(s, "FLAG_LANDMARK_BATTLE_FRONTIER") and TYPE.BATTLE_FRONTIER or TYPE.NONE
  end
  if id == sec("SOUTHERN_ISLAND") then
    return flagSet(s, "FLAG_LANDMARK_SOUTHERN_ISLAND") and TYPE.ROUTE or TYPE.NONE
  end
  return TYPE.ROUTE
end

-- pokeemerald/src/region_map.c:1248
local function terraOrMarineCaveMapSecId(s)
  local list = RegionMap.manifest().terraOrMarineCaveMapSecIds
  local idx = varGet(s, "VAR_ABNORMAL_WEATHER_LOCATION") - 1
  if idx < 0 or idx > #list - 1 then idx = 0 end
  return list[idx + 1]
end

-- pokeemerald/src/region_map.c:1227
function RegionMap.correctSpecialMapSecId(s, id)
  local man = RegionMap.manifest()
  -- pokeruby/src/region_map.c:745
  if man.assetLayout ~= "rs" then
    for _, m in ipairs(man.marineCaveMapSecIds) do
      if m == id then return terraOrMarineCaveMapSecId(s) end
    end
  end
  for _, pair in ipairs(man.specialPlaces) do
    if pair[1] == sec("NONE") then break end
    if pair[1] == id then return pair[2] end
  end
  return id
end

-- pokeemerald/src/region_map.c:1568
function RegionMap.mapName(id)
  if id == sec("SECRET_BASE") then
    local okS, SecretBase = pcall(require, "src.core.game3.rse.secret_base")
    if okS and type(SecretBase) == "table" and SecretBase.mapName then return SecretBase.mapName() end
  end
  if id < sec("NONE") then return Mapsec.name(id) end
  return ""
end

-- pokeemerald/src/region_map.c:1342
local function sameMapSecInRow(s, y)
  if y == 0 then return false end
  y = y - 1
  for x = RegionMap.CURSOR_X_MIN, RegionMap.CURSOR_X_MAX do
    if RegionMap.mapSecAt(x, y) == s.mapSecId then return true end
  end
  return false
end

-- pokeemerald/src/region_map.c:1294
local function positionWithinMapSec(s)
  if s.mapSecId == sec("NONE") then
    s.posWithinMapSec = 0
    return
  end
  local x, y, pos = s.cursorX, s.cursorY, 0
  while true do
    if x <= RegionMap.CURSOR_X_MIN then
      if sameMapSecInRow(s, y) then
        y = y - 1
        x = RegionMap.CURSOR_X_MAX + 1
      else
        break
      end
    else
      x = x - 1
      if RegionMap.mapSecAt(x, y) == s.mapSecId then pos = pos + 1 end
    end
  end
  s.posWithinMapSec = pos
end

local function mapDefOf(mapId)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and (Runtime._game or (Runtime.getGame and Runtime.getGame()))
  local maps = game and game.data and game.data.maps
  return maps and maps[mapId] or nil
end

local function playerCell(s)
  local P = package.loaded["src.core.game3.player"]
  if P and tonumber(P.cellX) then return tonumber(P.cellX), tonumber(P.cellY) end
  return tonumber(s.session and s.session.x) or 0, tonumber(s.session and s.session.y) or 0
end

-- pokeemerald/src/region_map.c:968
function RegionMap.initFromPlayer(s)
  local Map = package.loaded["src.core.game3.map"]
  local def = s.mapDef or (Map and Map.currentDef()) or {}
  local T = require("src.core.game3.field_moves").MAP_TYPES
  local mapType = tonumber(def.mapType) or T.TOWN
  local width, height, x, y
  local px, py = playerCell(s)
  local session = s.session or {}
  if mapType == T.UNDERGROUND or mapType == T.UNKNOWN then
    local esc = session.escapeWarp
    local escDef = def.allowEscaping == 1 and esc and mapDefOf(esc.map) or nil
    if escDef then
      s.mapSecId = tonumber(escDef.regionMapSectionId) or 0
      width, height, x, y = escDef.width, escDef.height, tonumber(esc.x) or 0, tonumber(esc.y) or 0
    else
      s.mapSecId = tonumber(def.regionMapSectionId) or 0
      width, height, x, y = 1, 1, 1, 1
    end
    s.playerIsInCave = true
  elseif mapType == T.SECRET_BASE then
    local dw = session.dynamicWarp or {}
    local dDef = mapDefOf(dw.map) or def
    s.mapSecId = tonumber(dDef.regionMapSectionId) or 0
    s.playerIsInCave = true
    width, height, x, y = dDef.width, dDef.height, tonumber(dw.x) or 0, tonumber(dw.y) or 0
  elseif mapType == T.INDOOR then
    s.mapSecId = tonumber(def.regionMapSectionId) or 0
    local warp
    if s.mapSecId ~= sec("DYNAMIC") then
      warp = session.escapeWarp or {}
    else
      warp = session.dynamicWarp or {}
    end
    local wDef = mapDefOf(warp.map) or def
    if s.mapSecId == sec("DYNAMIC") then s.mapSecId = tonumber(wDef.regionMapSectionId) or 0 end
    s.playerIsInCave = false
    if RegionMap.manifest().assetLayout ~= "rs" then
      for _, id in ipairs(RegionMap.manifest().aquaHideoutOld) do
        if id == s.mapSecId then s.playerIsInCave = true end
      end
    end
    width, height, x, y = wDef.width, wDef.height, tonumber(warp.x) or 0, tonumber(warp.y) or 0
  else
    s.mapSecId = tonumber(def.regionMapSectionId) or 0
    if RegionMap.manifest().assetLayout == "rs" then
      -- pokeruby/src/region_map.c:545
      s.playerIsInCave = s.mapSecId == sec("UNDERWATER_128")
    else
      s.playerIsInCave = s.mapSecId == sec("UNDERWATER_SEAFLOOR_CAVERN") or s.mapSecId == sec("UNDERWATER_MARINE_CAVE")
    end
    width, height, x, y = def.width, def.height, px, py
  end
  local e = Mapsec.entry(s.mapSecId) or { x = 0, y = 0, width = 1, height = 1 }
  local xOnMap = x
  local scale = math.floor((tonumber(width) or 1) / math.max(1, e.width))
  if scale == 0 then scale = 1 end
  x = math.floor(x / scale)
  if x >= e.width then x = e.width - 1 end
  scale = math.floor((tonumber(height) or 1) / math.max(1, e.height))
  if scale == 0 then scale = 1 end
  y = math.floor(y / scale)
  if y >= e.height then y = e.height - 1 end
  if s.mapSecId == sec("ROUTE_114") then
    if y ~= 0 then x = 0 end
  elseif s.mapSecId == sec("ROUTE_126") or s.mapSecId == sec("UNDERWATER_126") then
    x = 0
    if px > 32 then x = x + 1 end
    if px > 51 then x = x + 1 end
    y = 0
    if py > 37 then y = y + 1 end
    if py > 56 then y = y + 1 end
  elseif s.mapSecId == sec("ROUTE_121") then
    x = 0
    if xOnMap > 14 then x = x + 1 end
    if xOnMap > 28 then x = x + 1 end
    if xOnMap > 54 then x = x + 1 end
  elseif s.mapSecId == sec("UNDERWATER_MARINE_CAVE") then
    -- pokeemerald/src/region_map.c:1260
    local coords = RegionMap.manifest().marineCaveCoords
    local total = #RegionMap.manifest().terraOrMarineCaveMapSecIds
    local start = total - #coords + 1
    local idx = varGet(s, "VAR_ABNORMAL_WEATHER_LOCATION")
    if idx < start or idx > total then idx = start end
    idx = idx - start + 1
    s.cursorX = coords[idx].x + RegionMap.CURSOR_X_MIN
    s.cursorY = coords[idx].y + RegionMap.CURSOR_Y_MIN
    return
  end
  s.cursorX = e.x + x + RegionMap.CURSOR_X_MIN
  s.cursorY = e.y + y + RegionMap.CURSOR_Y_MIN
end

local function isEventIsland(id)
  if RegionMap.manifest().assetLayout == "rs" then return false end
  for _, v in ipairs(RegionMap.manifest().offMap) do
    if v == id then return true end
  end
  return false
end

local function frameOf(s)
  return s.cursorFrame
end

local function newState(opts)
  opts = opts or {}
  local s = {
    session = opts.session,
    mode = opts.mode == "fly" and "fly" or "wall",
    mapDef = opts.mapDef,
    onPick = opts.onPick,
    onClose = opts.onClose,
    frameType = tonumber(opts.frameType),
    pal = Pal.new(),
    state = 0,
    frames = 0,
    cursorFrame = 0,
    cursorAnimTimer = 0,
    blinkPlayerIcon = false,
    playerIconVisible = true,
    playerIconTimer = 0,
    moveCounter = 0,
    dx = 0,
    dy = 0,
    inputFn = "full",
  }
  -- pokeemerald/src/region_map.c:544
  RegionMap.initFromPlayer(s)
  s.playerIconX, s.playerIconY = s.cursorX, s.cursorY
  s.mapSecId = RegionMap.correctSpecialMapSecId(s, s.mapSecId)
  s.mapSecType = RegionMap.mapSecType(s, s.mapSecId)
  s.mapSecName = RegionMap.mapName(s.mapSecId)
  positionWithinMapSec(s)
  -- pokeemerald/src/region_map.c:1375
  s.cursorSx, s.cursorSy = 8 * s.cursorX + 4, 8 * s.cursorY + 4
  -- pokeemerald/src/region_map.c:1447
  local cur = (package.loaded["src.core.game3.map"] or {}).currentDef
  local curDef = s.mapDef or (cur and cur()) or {}
  s.showPlayerIcon = not isEventIsland(tonumber(curDef.regionMapSectionId) or -1)
  local gender = s.session and (s.session.gender or s.session.playerGender)
  s.female = gender == 1 or gender == "female" or gender == "girl"
  -- pokeemerald/src/region_map.c:1557
  if s.playerIsInCave then s.blinkPlayerIcon = true end
  s.flyIcons = {}
  if s.mode == "fly" then
    -- pokeemerald/src/region_map.c:1839
    local first, last = sec("LITTLEROOT_TOWN"), sec("EVER_GRANDE_CITY")
    local flag = constants(s.session):flag("FLAG_VISITED_LITTLEROOT_TOWN")
    for id = first, last do
      local e = Mapsec.entry(id)
      local shape = 0
      if e.width == 2 then shape = 1 elseif e.height == 2 then shape = 2 end
      local canFly = flagSet(s, flag)
      s.flyIcons[#s.flyIcons + 1] = {
        sec = id, x = (e.x + RegionMap.CURSOR_X_MIN) * 8 + 4, y = (e.y + RegionMap.CURSOR_Y_MIN) * 8 + 4,
        frame = canFly and (shape + 1) or (shape + 4), flicker = canFly, timer = 0, visible = true,
      }
      flag = flag + 1
    end
    -- pokeemerald/src/region_map.c:1883
    for _, r in ipairs(RegionMap.manifest().redOutlineFlyDestinations) do
      if r.mapSecId == sec("NONE") then break end
      if flagSet(s, r.flag) then
        local e = Mapsec.entry(r.mapSecId)
        s.flyIcons[#s.flyIcons + 1] = {
          sec = r.mapSecId, x = (e.x + RegionMap.CURSOR_X_MIN) * 8, y = (e.y + RegionMap.CURSOR_Y_MIN) * 8,
          frame = 7, flicker = true, timer = 0, visible = true,
        }
      end
    end
    s.drawTall = true
    RegionMap.updateFlyText(s)
  end
  s.nameShown = s.mapSecType ~= TYPE.NONE
  return s
end
RegionMap.newState = newState

-- pokeemerald/src/region_map.c:349
local MULTI_NAME_TABLES = { "sEverGrandeCityNames" }

-- pokeemerald/src/region_map.c:1760
function RegionMap.updateFlyText(s)
  s.flyText = nil
  if s.mapSecType > TYPE.NONE then
    for i, m in ipairs(RegionMap.manifest().multiNameFlyDestinations) do
      if s.mapSecId == m.mapSecId then
        if flagSet(s, m.flag) then
          local sub = m.names[s.posWithinMapSec + 1] or ""
          local key = MULTI_NAME_TABLES[i] and RomText.key(MULTI_NAME_TABLES[i], s.posWithinMapSec)
          if key and RomText.has(key) then sub = RomText.plain(key) end
          s.flyText = { tall = true, name = s.mapSecName, sub = sub }
        end
        break
      end
    end
    if not s.flyText then s.flyText = { tall = false, name = s.mapSecName } end
  else
    s.flyText = { tall = false, name = "" }
  end
end

-- pokeemerald/src/region_map.c:648
local function processInputFull(s, inp)
  local held, new = inp.held or {}, inp.new or {}
  local input = INPUT.NONE
  s.dx, s.dy = 0, 0
  if held.up and s.cursorY > RegionMap.CURSOR_Y_MIN then s.dy = -1; input = INPUT.MOVE_START end
  if held.down and s.cursorY < RegionMap.CURSOR_Y_MAX then s.dy = 1; input = INPUT.MOVE_START end
  if held.left and s.cursorX > RegionMap.CURSOR_X_MIN then s.dx = -1; input = INPUT.MOVE_START end
  if held.right and s.cursorX < RegionMap.CURSOR_X_MAX then s.dx = 1; input = INPUT.MOVE_START end
  if new.a then
    input = INPUT.A
  elseif new.b then
    input = INPUT.B
  end
  if input == INPUT.MOVE_START then
    s.moveCounter = 4
    s.inputFn = "move"
  end
  return input
end

-- pokeemerald/src/region_map.c:691
local function moveCursorFull(s)
  if s.moveCounter ~= 0 then return INPUT.MOVE_CONT end
  if s.dx > 0 then s.cursorX = s.cursorX + 1 end
  if s.dx < 0 then s.cursorX = s.cursorX - 1 end
  if s.dy > 0 then s.cursorY = s.cursorY + 1 end
  if s.dy < 0 then s.cursorY = s.cursorY - 1 end
  local id = RegionMap.mapSecAt(s.cursorX, s.cursorY)
  s.mapSecType = RegionMap.mapSecType(s, id)
  if id ~= s.mapSecId then
    s.mapSecId = id
    s.mapSecName = RegionMap.mapName(id)
  end
  positionWithinMapSec(s)
  s.inputFn = "full"
  return INPUT.MOVE_END
end

function RegionMap.inputCallback(s, inp)
  if s.inputFn == "move" then return moveCursorFull(s) end
  return processInputFull(s, inp)
end

-- pokeemerald/src/region_map.c:1360
local function animateSprites(s)
  if s.moveCounter ~= 0 then
    s.cursorSx = s.cursorSx + 2 * s.dx
    s.cursorSy = s.cursorSy + 2 * s.dy
    s.moveCounter = s.moveCounter - 1
  end
  -- pokeemerald/src/region_map.c:218
  s.cursorAnimTimer = s.cursorAnimTimer + 1
  if s.cursorAnimTimer >= 20 then
    s.cursorAnimTimer = 0
    s.cursorFrame = 1 - s.cursorFrame
  end
  -- pokeemerald/src/region_map.c:1541
  if s.blinkPlayerIcon then
    s.playerIconTimer = s.playerIconTimer + 1
    if s.playerIconTimer > 16 then
      s.playerIconTimer = 0
      s.playerIconVisible = not s.playerIconVisible
    end
  else
    s.playerIconVisible = true
  end
  -- pokeemerald/src/region_map.c:1914
  for _, icon in ipairs(s.flyIcons) do
    if icon.flicker then
      if s.mapSecId == icon.sec then
        icon.timer = icon.timer + 1
        if icon.timer > 16 then
          icon.timer = 0
          icon.visible = not icon.visible
        end
      else
        icon.timer = 16
        icon.visible = true
      end
    end
  end
end

local function finish(s, picked)
  local Stack = require("src.ui.game3.stack")
  RegionMap.Host._s = nil
  Stack.pop(RegionMap.ID)
  if picked and s.onPick then
    s.onPick(s.mapSecId, { posWithinMapSec = s.posWithinMapSec, mapSecType = s.mapSecType })
  end
  if s.onClose then s.onClose(picked) end
end

-- pokeemerald/src/field_region_map.c:140
local function wallFrame(s, inp)
  local st = s.state
  if st == 0 then
    s.state = 1
  elseif st == 1 then
    s.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
    s.state = 2
  elseif st == 2 then
    s.state = 3
  elseif st == 3 then
    if not s.pal:fadeActive() then s.state = 4 end
  elseif st == 4 then
    local r = RegionMap.inputCallback(s, inp)
    if r == INPUT.MOVE_END then
      s.nameShown = s.mapSecType ~= TYPE.NONE
    elseif r == INPUT.A or r == INPUT.B then
      s.state = 5
    end
  elseif st == 5 then
    s.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    s.state = 6
  elseif st == 6 then
    if not s.pal:fadeActive() then return finish(s, false) end
  end
end

-- pokeemerald/src/region_map.c:1647
local function flyFrame(s, inp)
  local st = s.state
  if st < 10 then
    if st == 9 then s.pal:blend(Pal.ALL, 16, Pal.BLACK) end
    s.state = st + 1
  elseif st == 10 then
    s.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
    s.state = 11
  elseif st == 11 then
    if not s.pal:fadeActive() then s.state = 12 end
  elseif st == 12 then
    local r = RegionMap.inputCallback(s, inp)
    if r == INPUT.MOVE_END then
      RegionMap.updateFlyText(s)
    elseif r == INPUT.A then
      if s.mapSecType == TYPE.CITY_CANFLY or s.mapSecType == TYPE.BATTLE_FRONTIER then
        Kit.playSe("SE_SELECT")
        s.chose = true
        s.state = 13
      end
    elseif r == INPUT.B then
      Kit.playSe("SE_SELECT")
      s.chose = false
      s.state = 13
    end
  elseif st == 13 then
    s.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    s.state = 14
  elseif st == 14 then
    if not s.pal:fadeActive() then return finish(s, s.chose) end
  end
end

function RegionMap.frame(s, inp)
  s.frames = s.frames + 1
  if s.mode == "fly" then flyFrame(s, inp) else wallFrame(s, inp) end
  if RegionMap.Host._s ~= s then return end
  animateSprites(s)
  s.pal:updateFade()
end

local function sheet(entry)
  local path = entry.png or entry
  return Kit.image(path)
end

local quads = {}
local function quad(img, x, y, w, h)
  local key = tostring(img) .. ":" .. x .. ":" .. y .. ":" .. w .. ":" .. h
  local q = quads[key]
  if not q then
    q = love.graphics.newQuad(x, y, w, h, img:getWidth(), img:getHeight())
    quads[key] = q
  end
  return q
end

local function drawText(text, x, y)
  FrlgFont.draw(text, x, y, { colors = Kit.messageColors() })
end

-- pokeemerald/src/region_map.c:1687
local function frameType(s)
  if s.frameType then return s.frameType end
  local Chrome = require("src.ui.game3.chrome")
  return Chrome._frameType or 0
end

function RegionMap.draw(s)
  if not s then return end
  local man = RegionMap.manifest()
  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  local bgVisible = s.mode ~= "fly" and s.state >= 3 or (s.mode == "fly" and s.state >= 10)
  if bgVisible then
    local map = sheet(man.layers.map)
    if map then love.graphics.draw(map, quad(map, 0, 0, 240, 160), 0, 0) end
    local fly = sheet(man.sprites.flyIcons)
    if fly then
      for _, icon in ipairs(s.flyIcons) do
        if icon.visible then
          local r = man.sprites.flyIcons.rects[icon.frame]
          love.graphics.draw(fly, quad(fly, r.x, r.y, r.w, r.h), icon.x - 4, icon.y - 4)
        end
      end
    end
    if s.showPlayerIcon and s.playerIconVisible then
      local who = s.female and man.sprites.may or man.sprites.brendan
      local img = sheet(who)
      if img then love.graphics.draw(img, s.playerIconX * 8 + 4 - 8, s.playerIconY * 8 + 4 - 8) end
    end
    if s.mode == "fly" then
      local frame = sheet(man.layers.frame)
      if frame then love.graphics.draw(frame, quad(frame, 0, 0, 240, 160), 0, 0) end
    end
    local cur = sheet(man.sprites.cursor)
    if cur then love.graphics.draw(cur, quad(cur, 0, frameOf(s) * 16, 16, 16), s.cursorSx - 8, s.cursorSy - 8) end
    local colors = Kit.messageColors()
    if s.mode == "fly" then
      -- pokeemerald/src/region_map.c:1713
      drawText(RomText.plain("gText_FlyToWhere"), 8, 18 * 8 + 1)
      local t = s.flyText or { tall = false, name = "" }
      if t.tall then
        Kit.userFrame(17, 15, 12, 4, frameType(s), colors.bg)
        drawText(t.name, 17 * 8, 15 * 8 + 1)
        local w = FrlgFont.measure(t.sub) or 0
        drawText(t.sub, 17 * 8 + math.max(0, 96 - w), 15 * 8 + 17)
      else
        Kit.userFrame(17, 17, 12, 2, frameType(s), colors.bg)
        drawText(t.name, 17 * 8, 17 * 8 + 1)
      end
    else
      -- pokeemerald/src/field_region_map.c:153
      Kit.userFrame(22, 1, 7, 2, frameType(s), colors.bg)
      local hoenn = RomText.plain("gText_Hoenn")
      local w = FrlgFont.measure(hoenn) or 0
      drawText(hoenn, 22 * 8 + math.max(0, math.floor((0x38 - w) / 2)), 8 + 1)
      Kit.userFrame(17, 17, 12, 2, frameType(s), colors.bg)
      if s.nameShown then drawText(s.mapSecName, 17 * 8, 17 * 8 + 1) end
    end
  end
  Kit.drawFade(s.pal, 0)
  love.graphics.pop()
end

local Host = { isMenu = true }
RegionMap.Host = Host
Host._s = nil
Host._step = nil

function RegionMap.show(opts)
  local Stack = require("src.ui.game3.stack")
  local s = newState(opts)
  Host._s = s
  Host._step = Kit.stepper()
  Stack.push(RegionMap.ID, Host, { hideBelow = true, fullscreen = true })
  return s
end

function RegionMap.active()
  return Host._s
end

function RegionMap.reset()
  if Host._s then
    Host._s = nil
    require("src.ui.game3.stack").pop(RegionMap.ID)
  end
  Host._step = nil
  manifest = nil
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local s = Host._s
  if not (s and Host._step) then return end
  Host._step:run(dt, function(inp)
    if Host._s ~= s then return true end
    RegionMap.frame(s, inp)
    if Host._s ~= s then return true end
    return nil
  end)
end

function Host.draw()
  RegionMap.draw(Host._s)
end

-- pokeemerald/src/region_map.c:1995
function RegionMap.flyWarpDestination(session, secId, posWithinMapSec)
  local C = constants(session)
  local SEC = C.region_map_sections.byName
  local H = C.heal_locations.byName
  secId = tonumber(secId)
  local g = session and session.gender
  local female = g == 1 or g == "female" or g == "F"
  local heal
  if secId == SEC.MAPSEC_SOUTHERN_ISLAND then
    heal = H.HEAL_LOCATION_SOUTHERN_ISLAND_EXTERIOR
  elseif RegionMap.manifest().assetLayout == "rs" and secId == SEC.MAPSEC_BATTLE_TOWER then
    -- pokeruby/src/region_map.c:1624
    heal = H.HEAL_LOCATION_BATTLE_TOWER_OUTSIDE
  elseif secId == SEC.MAPSEC_BATTLE_FRONTIER then
    heal = H.HEAL_LOCATION_BATTLE_FRONTIER_OUTSIDE_EAST
  elseif secId == SEC.MAPSEC_LITTLEROOT_TOWN then
    heal = female and H.HEAL_LOCATION_LITTLEROOT_TOWN_MAYS_HOUSE or H.HEAL_LOCATION_LITTLEROOT_TOWN_BRENDANS_HOUSE
  elseif secId == SEC.MAPSEC_EVER_GRANDE_CITY then
    local leagueFlag = RegionMap.manifest().assetLayout == "rs" and "FLAG_SYS_POKEMON_LEAGUE_FLY" or "FLAG_LANDMARK_POKEMON_LEAGUE"
    heal = (flagSet({ session = session }, leagueFlag) and (tonumber(posWithinMapSec) or 0) == 0)
      and H.HEAL_LOCATION_EVER_GRANDE_CITY_POKEMON_LEAGUE or H.HEAL_LOCATION_EVER_GRANDE_CITY
  end
  if not heal then return nil end
  local loc = require("src.core.game3.heal_locations").get(heal)
  if not loc then return nil end
  return { mapsec = secId, map = loc.map, x = loc.x, y = loc.y, healLocation = heal }
end

-- pokeemerald/src/region_map.c:1981
function RegionMap.flyHealLocation(s, secId, posWithinMapSec)
  local row = RegionMap.manifest().heal[(tonumber(secId) or -1) + 1]
  if not row then return nil end
  return row
end

return RegionMap
