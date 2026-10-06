-- 1:1 FireRed Map Name Popup Overlay (pokefirered/src/map_name_popup.c)
-- Slides down from top-left on area/map transitions when showMapName == 1.

local FrlgFont = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local MapSectionsExtract = require("src.import.gba.map_sections_extract")
local Strings = require("src.core.Strings")
local RomText = require("src.core.game3.rom_text")
local Rs = require("src.ui.game3.rs.map_name_popup")

local MapNamePopup = {}
MapNamePopup.Rs = Rs

-- State Machine Constants
local STATE_IDLE = 0
local STATE_SLIDE_IN = 1
local STATE_HOLD = 2
local STATE_SLIDE_OUT = 3

MapNamePopup.STATE = {
  IDLE = STATE_IDLE,
  SLIDE_IN = STATE_SLIDE_IN,
  HOLD = STATE_HOLD,
  SLIDE_OUT = STATE_SLIDE_OUT,
}

MapNamePopup._state = STATE_IDLE
MapNamePopup._tPos = 0 -- 0..24 pixels (Love2D Y = _tPos - 24)
MapNamePopup._timer = 0 -- frame counter for hold state
MapNamePopup._reshow = false
MapNamePopup._pendingName = nil
MapNamePopup._pendingWidthTiles = 14
MapNamePopup._pendingWidth = 112

-- Active banner properties
MapNamePopup._name = ""
MapNamePopup._widthTiles = 14
MapNamePopup._contentWidth = 112 -- 14 tiles * 8px
MapNamePopup._floorNum = 0

-- pokefirered/include/constants/flags.h:1530
local FLAG_DONT_SHOW_MAP_NAME_POPUP = 0x4000

-- pokefirered/src/map_name_popup.c:30
local function isFlagSuppressed()
  local Space = package.loaded["src.core.game3.scripting.space"]
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  local store = Space and Space.store
  if store and Flags and Flags.getFlag then
    if Flags.getFlag(store, nil, FLAG_DONT_SHOW_MAP_NAME_POPUP) then return true end
  end
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  if session and session.flags and session.flags[FLAG_DONT_SHOW_MAP_NAME_POPUP] then
    return true
  end
  return false
end

local Rse = {}
MapNamePopup.Rse = Rse

-- pokeemerald/src/map_name_popup.c:219
local RSE_PRINT, RSE_SLIDE_IN, RSE_WAIT, RSE_SLIDE_OUT, RSE_ERASE, RSE_END = 6, 0, 1, 2, 4, 5
Rse.STATE = {
  PRINT = RSE_PRINT, SLIDE_IN = RSE_SLIDE_IN, WAIT = RSE_WAIT,
  SLIDE_OUT = RSE_SLIDE_OUT, ERASE = RSE_ERASE, END = RSE_END,
}
-- pokeemerald/src/map_name_popup.c:222
Rse.OFFSCREEN_Y = 40
Rse.SLIDE_SPEED = 2
Rse.task = nil
Rse.def = nil
Rse.window = nil

local function themed()
  local ok, Profile = pcall(require, "src.core.game3.profile")
  return ok and Profile.family() == "rse"
end

local function rseConstants()
  local Profile = require("src.core.game3.profile")
  return require("src.core.game3.constants").of(Profile.forSession().id)
end

local function rseHidden()
  local id = rseConstants():flag("FLAG_HIDE_MAP_NAME_POPUP")
  local Space = package.loaded["src.core.game3.scripting.space"]
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  if Space and Space.store and Flags and Flags.getFlag then
    return Flags.getFlag(Space.store, nil, id) == true
  end
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  return session and session.flags and session.flags[id] == true or false
end

local images = {}

local function idxImage(theme, suffix, pal)
  local key = theme .. suffix .. "|" .. table.concat(pal, ",", 1, 16)
  local hit = images[key]
  if hit then return hit end
  local Mapsec = require("src.ui.game3.rse.mapsec")
  local rel = "chrome/map_popup/" .. theme .. suffix .. ".idx"
  local bytes = assert(Mapsec.read(rel), "missing " .. rel)
  local Kit = require("src.ui.game3.rse.scene_kit")
  local W, H = 80, 24
  local data = love.image.newImageData(W, H)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local v = bytes:byte(y * W + x + 1) or 0
      if v ~= 0 then
        local r, g, b = Kit.rgb555(pal[v + 1])
        data:setPixel(x, y, r, g, b, 1)
      end
    end
  end
  local img = love.graphics.newImage(data)
  img:setFilter("nearest", "nearest")
  images[key] = img
  return img
end

-- pokeemerald/src/map_name_popup.c:382
local FRAME_TILES = {}
for i = 0, 11 do FRAME_TILES[#FRAME_TILES + 1] = { i, i, 0 } end
FRAME_TILES[#FRAME_TILES + 1] = { 12, 0, 1 }
FRAME_TILES[#FRAME_TILES + 1] = { 13, 11, 1 }
FRAME_TILES[#FRAME_TILES + 1] = { 14, 0, 2 }
FRAME_TILES[#FRAME_TILES + 1] = { 15, 11, 2 }
FRAME_TILES[#FRAME_TILES + 1] = { 16, 0, 3 }
FRAME_TILES[#FRAME_TILES + 1] = { 17, 11, 3 }
for i = 0, 11 do FRAME_TILES[#FRAME_TILES + 1] = { 18 + i, i, 4 } end
Rse.FRAME_TILES = FRAME_TILES

-- pokeemerald/src/map_name_popup.c:335
local function rsePrint()
  local def = Rse.def or {}
  local Mapsec = require("src.ui.game3.rse.mapsec")
  local sec = tonumber(def.regionMapSectionId or def.region_map_section_id or def.mapsec) or 0
  local theme = Mapsec.theme(sec) or "wood"
  local man = Mapsec.readLua("chrome/map_popup/manifest.lua")
  local pal = man.palettes[theme]
  -- pokeemerald/src/map_name_popup.c:421
  local bubbles = rseConstants():id("weather", "WEATHER_UNDERWATER_BUBBLES")
  if bubbles ~= nil and tonumber(def.weather) == bubbles then pal = man.underwaterPalette end
  local name = Mapsec.name(sec)
  local R = require("src.core.game3.rse.init")
  local pyramid = R.system("pyramid")
  -- pokeemerald/src/map_name_popup.c:339
  if pyramid and pyramid.inPyramid and pyramid.inPyramid() then
    local headers = pyramid.manifest().mapHeaders
    local sess = R.session()
    local idx = pyramid.location(sess) == pyramid.LOCATION.TOP and #headers or
      (tonumber(pyramid.frontier(sess).curChallengeBattleNum) or 0) + 1
    local ref = headers[idx]
    if ref then name = require("src.core.game3.scripting.text_ir").toPlain(RomText.refIr(ref)) end
  elseif sec == rseConstants():id("region_map_sections", "MAPSEC_SECRET_BASE") then
    -- pokeemerald/src/secret_base.c:735
    local sb = R.system("secretBase")
    if sb and sb.mapName then name = sb.mapName() end
  end
  local width = FrlgFont.measure(name, { font = "narrow" }) or 0
  local Kit = require("src.ui.game3.rse.scene_kit")
  Rse.window = {
    sec = sec,
    theme = theme,
    name = name,
    -- pokeemerald/src/map_name_popup.c:363
    textX = width < 80 and math.floor((80 - width) / 2) or 0,
    bitmap = idxImage(theme, "", pal),
    outline = idxImage(theme, "_outline", pal),
    colors = { fg = Kit.color555(pal[3]), shadow = Kit.color555(pal[4]), bg = { 0, 0, 0, 0 } },
  }
end

-- pokeemerald/include/constants/map_types.h:13
local MAP_TYPE_SECRET_BASE = 9

-- pokeemerald/src/map_name_popup.c:231
function Rse.show(mapDef)
  if rseHidden() then return false end
  -- pokeemerald/src/secret_base.c:453
  if mapDef and tonumber(mapDef.mapType) == MAP_TYPE_SECRET_BASE then
    local R = require("src.core.game3.rse.init")
    if R.var("VAR_INIT_SECRET_BASE") == 0 then return false end
  end
  Rse.def = mapDef
  local t = Rse.task
  if not t then
    Rse.task = { state = RSE_PRINT, yOffset = Rse.OFFSCREEN_Y, printTimer = 0, onscreen = 0, incoming = false }
  else
    if t.state ~= RSE_SLIDE_OUT then t.state = RSE_SLIDE_OUT end
    t.incoming = true
  end
  return true
end

-- pokeemerald/src/map_name_popup.c:254
function Rse.frame()
  local t = Rse.task
  if not t then return end
  if t.state == RSE_PRINT then
    t.printTimer = t.printTimer + 1
    if t.printTimer > 30 then
      t.state = RSE_SLIDE_IN
      t.printTimer = 0
      rsePrint()
    end
  elseif t.state == RSE_SLIDE_IN then
    t.yOffset = t.yOffset - Rse.SLIDE_SPEED
    if t.yOffset <= 0 then
      t.yOffset = 0
      t.state = RSE_WAIT
      t.onscreen = 0
    end
  elseif t.state == RSE_WAIT then
    t.onscreen = t.onscreen + 1
    if t.onscreen > 120 then
      t.onscreen = 0
      t.state = RSE_SLIDE_OUT
    end
  elseif t.state == RSE_SLIDE_OUT then
    t.yOffset = t.yOffset + Rse.SLIDE_SPEED
    if t.yOffset >= Rse.OFFSCREEN_Y then
      t.yOffset = Rse.OFFSCREEN_Y
      if t.incoming then
        t.state = RSE_PRINT
        t.printTimer = 0
        t.incoming = false
      else
        t.state = RSE_ERASE
      end
    end
  elseif t.state == RSE_ERASE then
    Rse.window = nil
    t.state = RSE_END
  elseif t.state == RSE_END then
    Rse.dismiss()
  end
end

-- pokeemerald/src/map_name_popup.c:319
function Rse.dismiss()
  Rse.task = nil
  Rse.window = nil
end

function Rse.update(dt)
  local step = math.max(1, math.floor(((dt or (1 / 60)) * 60) + 0.5))
  for _ = 1, step do
    if not Rse.task then return end
    Rse.frame()
  end
end

function Rse.draw()
  local t, w = Rse.task, Rse.window
  if not (t and w) or t.yOffset >= Rse.OFFSCREEN_Y then return end
  local oy = -t.yOffset
  love.graphics.setColor(1, 1, 1, 1)
  local q = Rse._quad or love.graphics.newQuad(0, 0, 8, 8, 80, 24)
  Rse._quad = q
  for _, e in ipairs(FRAME_TILES) do
    q:setViewport((e[1] % 10) * 8, math.floor(e[1] / 10) * 8, 8, 8, 80, 24)
    love.graphics.draw(w.outline, q, e[2] * 8, oy + e[3] * 8)
  end
  love.graphics.draw(w.bitmap, 8, oy + 8)
  FrlgFont.draw(w.name, 8 + w.textX, oy + 8 + 3, { font = "narrow", colors = w.colors, maxWidth = 80 })
  love.graphics.setColor(1, 1, 1, 1)
end

--- Format clean fallback name from mapId if somehow unresolved
local function cleanMapName(mapId)
  if type(mapId) ~= "string" or mapId == "" then return "KANTO" end
  local s = mapId:gsub("^FR_", ""):gsub("^SEVII_", "")
  s = s:gsub("(%l)(%u)", "%1 %2")
  s = s:gsub("(%a)(%d)", "%1 %2")
  s = s:gsub("(%d)(%a)", "%1 %2")
  s = s:gsub("_", " "):gsub("%s+", " "):upper()
  return s
end

--- Trigger map name popup display
-- The section names are the cart's English, with the floor label
-- map_name_popup.c appends.  Both go through Strings(): the floor as a whole
-- label ("3F", "B1F", "ROOFTOP", the cart's gText_3F... rows), since the
-- European carts count floors differently (3F is "2E" in French).
local function translated_name(info)
  local base = Strings(info.rawName or info.name)
  local floor = tonumber(info.floorNum) or 0
  -- pokefirered/src/map_name_popup.c:211
  if floor == 127 then return base .. " " .. RomText.plain("gText_Rooftop2") end
  local label
  if floor < 0 then label = string.format("B%dF", -floor)
  elseif floor > 0 then label = string.format("%dF", floor) end
  if not label then return base end
  return base .. " " .. Strings(label)
end

function MapNamePopup.show(mapDef, opts)
  opts = opts or {}
  if Rs.matches() then return Rs.show(mapDef, opts) end
  if themed() then return Rse.show(mapDef, opts) end
  if isFlagSuppressed() then return false end

  -- Strict indoor suppression: showMapName must be 1/true unless forced by opts
  if not opts.force then
    local showFlag = mapDef and (mapDef.showMapName or mapDef.show_map_name)
    if showFlag == 0 or showFlag == false then
      MapNamePopup.dismiss()
      return false
    end
  end

  local secId = mapDef and (mapDef.regionMapSectionId or mapDef.region_map_section_id or mapDef.mapsec)
  local mapId = mapDef and (mapDef.id or mapDef.name or mapDef.map)
  local floorNum = mapDef and (mapDef.floorNum or mapDef.floor_num or mapDef.floor) or 0

  local info = MapSectionsExtract.getInfo(secId, mapId, floorNum)
  local name = info and info.name
  -- getInfo answers with the Pallet Town placeholder for a map it could not
  -- identify (resolved == false).  Treat that as "no name" so the popup shows
  -- the cleaned map id instead of a place the map is not.
  if not name or name == "???" or name == "" or (info and info.resolved == false) then
    name = cleanMapName(mapId)
  else
    name = translated_name(info)
  end

  -- Calculate width matching pokefirered MapNamePopupCreateWindow:
  -- Floor == 0: width = 14 (112px content)
  -- Floor != 0 and Floor != 127: width = 19 (152px content)
  -- Floor == 127 (Rooftop): width = 22 (176px content)
  local widthTiles = 14
  local contentW = 112
  local floor = tonumber(floorNum) or (info and info.floorNum) or 0
  if floor ~= 0 then
    if floor == 127 then
      widthTiles = 22
      contentW = 176
    else
      widthTiles = 19
      contentW = 152
    end
  end

  if MapNamePopup._state == STATE_IDLE then
    MapNamePopup._name = name
    MapNamePopup._widthTiles = widthTiles
    MapNamePopup._contentWidth = contentW
    MapNamePopup._floorNum = floor
    MapNamePopup._tPos = 0
    MapNamePopup._timer = 0
    MapNamePopup._reshow = false
    MapNamePopup._state = STATE_SLIDE_IN
  else
    -- If already active, trigger reshow: slide up and reload text
    MapNamePopup._pendingName = name
    MapNamePopup._pendingWidthTiles = widthTiles
    MapNamePopup._pendingWidth = contentW
    MapNamePopup._reshow = true
    if MapNamePopup._state ~= STATE_SLIDE_OUT then
      MapNamePopup._state = STATE_SLIDE_OUT
    end
  end

  return true
end

--- Dismiss active popup immediately (e.g. on dialogue open, battle, or indoor warp)
function MapNamePopup.dismiss()
  Rs.dismiss()
  Rse.dismiss()
  if MapNamePopup._state ~= STATE_IDLE then
    MapNamePopup._state = STATE_IDLE
    MapNamePopup._tPos = 0
    MapNamePopup._timer = 0
    MapNamePopup._reshow = false
    MapNamePopup._pendingName = nil
  end
end

--- Check if popup is currently visible/animating
function MapNamePopup.isActive()
  return MapNamePopup._state ~= STATE_IDLE or Rse.task ~= nil or Rs.task ~= nil
end

--- Frame tick (60 FPS / dt-based)
function MapNamePopup.update(dt)
  if Rs.task then Rs.update(dt) end
  if Rse.task then Rse.update(dt) end
  if MapNamePopup._state == STATE_IDLE then return end

  -- Fixed-step 60 FPS increments (or accumulated sub-frames)
  local step = math.max(1, math.floor(((dt or (1 / 60)) * 60) + 0.5))

  for _ = 1, step do
    if MapNamePopup._state == STATE_SLIDE_IN then
      -- pokefirered/src/map_name_popup.c:66: task->tPos -= 2 (slide down 2px per frame)
      MapNamePopup._tPos = MapNamePopup._tPos + 2
      if MapNamePopup._tPos >= 24 then
        MapNamePopup._tPos = 24
        MapNamePopup._state = STATE_HOLD
        MapNamePopup._timer = 0
      end
    elseif MapNamePopup._state == STATE_HOLD then
      -- pokefirered/src/map_name_popup.c:75: hold for 120 frames (2.0 seconds)
      MapNamePopup._timer = MapNamePopup._timer + 1
      if MapNamePopup._timer > 120 then
        MapNamePopup._timer = 0
        MapNamePopup._state = STATE_SLIDE_OUT
      end
    elseif MapNamePopup._state == STATE_SLIDE_OUT then
      -- pokefirered/src/map_name_popup.c:82: slide back up 2px per frame
      MapNamePopup._tPos = MapNamePopup._tPos - 2
      if MapNamePopup._tPos <= 0 then
        MapNamePopup._tPos = 0
        if MapNamePopup._reshow and MapNamePopup._pendingName then
          MapNamePopup._name = MapNamePopup._pendingName
          MapNamePopup._widthTiles = MapNamePopup._pendingWidthTiles or 14
          MapNamePopup._contentWidth = MapNamePopup._pendingWidth or 112
          MapNamePopup._pendingName = nil
          MapNamePopup._reshow = false
          MapNamePopup._state = STATE_SLIDE_IN
        else
          MapNamePopup._state = STATE_IDLE
          return
        end
      end
    end
  end
end

--- Draw 1:1 FireRed location banner
function MapNamePopup.draw()
  if Rs.task then Rs.draw() end
  if Rse.task then Rse.draw() end
  if MapNamePopup._state == STATE_IDLE or MapNamePopup._tPos <= 0 then
    return
  end

  local tPos = MapNamePopup._tPos
  -- Love2D coordinate translation: base Y sits at tPos - 24
  -- When tPos = 0: py = -24 (offscreen above viewport)
  -- When tPos = 24: py = 0 (flush against top bezel [0, 0])
  local px = 0
  local py = tPos - 24
  local widthTiles = MapNamePopup._widthTiles or 14
  local contentW = MapNamePopup._contentWidth or (widthTiles * 8)

  -- 1. Draw 9-slice standard text window border and white interior
  Chrome.mapPopupFrame(px, py, widthTiles)

  -- 2. Map Name Text (Centered vertically and horizontally in enclosed window)
  -- Uses FONT_NORMAL with dark gray (#626262) fg and light gray (#D5D5CD) shadow
  local name = MapNamePopup._name or ""
  local textW = (FrlgFont.measure and FrlgFont.measure(name)) or (6 * #name)
  local textX = px + 8 + math.floor((contentW - textW) / 2)
  local textY = py + 5

  FrlgFont.draw(name, textX, textY, {
    colors = FrlgFont.COLOR.NORMAL,
    maxWidth = contentW,
  })

  love.graphics.setColor(1, 1, 1, 1)
end

return MapNamePopup
