-- ../pokecrystal/engine/events/map_name_sign.asm:3
-- ../pokecrystal/engine/events/map_name_sign.asm:99
-- ../pokecrystal/engine/events/map_name_sign.asm:197

local Assets = require("src.render.Assets")
local Font = require("src.render.Font")
local GameVersion = require("src.core.GameVersion")
local GbcPalette = require("src.render.GbcPalette")
local Palettes = require("src.world.gen2.Palettes")

local MapNameSign = {}

-- ../pokecrystal/engine/events/map_name_sign.asm:1
MapNameSign.TILES = 14
-- ../pokecrystal/engine/events/map_name_sign.asm:42-44
MapNameSign.DURATION = 60
-- ../pokecrystal/engine/overworld/events.asm:177-191
MapNameSign.FRAMES_PER_TICK = 2
MapNameSign.SHEET = "assets/generated/fonts/map_entry_sign.png"

-- ../pokecrystal/engine/events/map_name_sign.asm:134-140
-- ../pokecrystal/engine/events/map_name_sign.asm:114
local COLS = 20
local ROWS = 4
local TOP = 112

-- ../pokecrystal/engine/events/map_name_sign.asm:69-87
local NO_SIGN = {
  LANDMARK_SPECIAL = true,
  LANDMARK_RADIO_TOWER = true,
  LANDMARK_LAV_RADIO_TOWER = true,
  LANDMARK_UNDERGROUND_PATH = true,
  LANDMARK_INDIGO_PLATEAU = true,
  LANDMARK_POWER_PLANT = true,
}

-- ../pokecrystal/engine/events/map_name_sign.asm:89-97
local PARK_GATES = {
  ROUTE_35_NATIONAL_PARK_GATE = true,
  ROUTE_36_NATIONAL_PARK_GATE = true,
}

-- ../pokecrystal/data/maps/setup_scripts.asm:177
-- ../pokecrystal/engine/menus/intro_menu.asm:467-468
local SUPPRESSED_VIA = { boot = true, continue = true }

local sheet, quads

Assets.register(function() sheet, quads = nil, nil end)

local function loadSheet(world)
  if sheet ~= nil then return sheet or nil end
  local data = world and world.game and world.game.data
  local path = (data and data.font and data.font.imageMapSign)
    or MapNameSign.SHEET
  if not Assets.exists(Assets.resolve(path)) then
    sheet = false
    return nil
  end
  local ok, img = pcall(Assets.image, path)
  if not ok or not img then
    sheet = false
    return nil
  end
  local iw, ih = img:getDimensions()
  quads = {}
  for i = 0, MapNameSign.TILES - 1 do
    quads[i] = love.graphics.newQuad(i * 8, 0, 8, 8, iw, ih)
  end
  sheet = img
  return sheet
end

function MapNameSign.state(world)
  local save = world and world.game and world.game.save
  if save then
    local crystal = require("src.core.gen2.Save").crystalState(save)
    crystal.mapSign = crystal.mapSign or {}
    return crystal.mapSign
  end
  world.mapSignState = world.mapSignState or {}
  return world.mapSignState
end

-- ../pokecrystal/engine/events/map_name_sign.asm:11-56
function MapNameSign.init(world, via)
  if GameVersion.engine() ~= "crystal" then return end
  world.mapSign = nil
  local st = MapNameSign.state(world)
  local def = world.map and world.map.def
  local id = def and world:currentLandmarkId() or false
  if not def or def.environment == "GATE"
      or PARK_GATES[world.map and world.map.id] then
    id = false
  end
  if SUPPRESSED_VIA[via] then
    st.prev = id
    return
  end
  local prev = st.prev
  if prev == nil then prev = false end
  st.prev = id
  -- ../pokecrystal/engine/events/map_name_sign.asm:60-67
  if id == prev or prev == "LANDMARK_SPECIAL" then return end
  if id == false or NO_SIGN[id] then return end
  world.mapSign = {
    timer = MapNameSign.DURATION,
    frames = 0,
    shown = false,
    -- ../pokecrystal/engine/events/map_name_sign.asm:143-145
    -- ../pokecrystal/constants/charmap.asm:9
    name = ((world:landmarkName() or ""):gsub("\n", " ")),
  }
end

-- ../pokecrystal/engine/overworld/events.asm:284-285
function MapNameSign.cancel(world)
  if world then world.mapSign = nil end
end

-- ../pokecrystal/engine/events/map_name_sign.asm:99-125
local function place(world, s)
  if s.timer <= 0 then
    world.mapSign = nil
    return
  end
  s.timer = s.timer - 1
  if s.timer <= MapNameSign.DURATION - 2 then s.shown = true end
end

-- ../pokecrystal/engine/overworld/events.asm:177-191
function MapNameSign.frame(world)
  local s = world and world.mapSign
  if not s or world.mapSetup or world.textbox then return end
  s.frames = (s.frames or 0) + 1
  if s.frames < MapNameSign.FRAMES_PER_TICK then return end
  s.frames = 0
  place(world, s)
end

-- ../pokecrystal/home/window.asm:42
function MapNameSign.tick(world)
  if world.mapSign and world.textbox then MapNameSign.cancel(world) end
end

-- ../pokecrystal/engine/events/map_name_sign.asm:197-233
-- ../pokecrystal/engine/events/map_name_sign.asm:235
function MapNameSign.tiles()
  local rows = {}
  for row = 0, ROWS - 1 do rows[row] = {} end
  rows[0][0], rows[0][COLS - 1] = 1, 4
  rows[1][0], rows[1][COLS - 1] = 5, 11
  rows[2][0], rows[2][COLS - 1] = 6, 12
  rows[3][0], rows[3][COLS - 1] = 7, 10
  for i = 0, COLS - 3 do
    local edge = (i % 4 < 2) and 1 or 0
    rows[0][i + 1] = 2 + edge
    rows[1][i + 1] = 13
    rows[2][i + 1] = 13
    rows[3][i + 1] = 8 + edge
  end
  return rows
end

local LAYOUT = MapNameSign.tiles()

-- ../pokecrystal/engine/events/map_name_sign.asm:142-156
function MapNameSign.textX(name)
  if Font.ttfActive() then
    return math.floor((COLS * 8 - Font.width(name)) / 2)
  end
  return math.floor((COLS - #Font.encode(name)) / 2) * 8
end

-- ../pokecrystal/gfx/tilesets/bg_tiles.pal:9
function MapNameSign.colors(world)
  return Palettes.textColors(world and world.palettes)
end

function MapNameSign.draw(world, w, h, posLift)
  local s = world.mapSign
  if not s or not s.shown or GameVersion.engine() ~= "crystal" then return end
  if world.textbox then return end
  local img = loadSheet(world)
  if not img then return end
  local G = love.graphics
  local scale = world:fitScale()
  G.push()
  G.translate(math.floor((w - 160 * scale) / 2),
    math.floor((h - 144 * scale) / 2) - (posLift or 0))
  G.scale(scale, scale)
  G.setColor(1, 1, 1, 1)
  local function blit()
    for row = 0, ROWS - 1 do
      for col = 0, COLS - 1 do
        local quad = quads[LAYOUT[row][col]]
        if quad then G.draw(img, quad, col * 8, TOP + row * 8) end
      end
    end
    Font.draw(s.name, MapNameSign.textX(s.name), TOP + 2 * 8)
  end
  -- ../pokecrystal/engine/events/map_name_sign.asm:181
  local colors = MapNameSign.colors(world)
  if colors and GbcPalette.available() then
    GbcPalette.with(colors, blit)
  else
    blit()
  end
  G.pop()
  G.setColor(1, 1, 1, 1)
end

return MapNameSign
