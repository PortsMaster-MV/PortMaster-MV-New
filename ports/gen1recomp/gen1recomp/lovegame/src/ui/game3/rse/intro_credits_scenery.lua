local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")

local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local Scenery = {}

Scenery.MANIFEST = "data/generated/gba/intro/rse/scenery/manifest.lua"

Scenery.NORMAL = 0
Scenery.DESTROY = 1
Scenery.FROZEN = 2

Scenery.SCENE_OCEAN_MORNING = 0
Scenery.SCENE_OCEAN_SUNSET = 1
Scenery.SCENE_FOREST_RIVAL_ARRIVE = 2
Scenery.SCENE_FOREST_CATCH_RIVAL = 3
Scenery.SCENE_CITY_NIGHT = 4

Scenery.TAG_BICYCLE = 1001
Scenery.TAG_BRENDAN = 1002
Scenery.TAG_MAY = 1003
Scenery.TAG_FLYGON_LATIOS = 1004
Scenery.TAG_FLYGON_LATIAS = 1005

local function s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

local function u16(v)
  return band(v, 0xFFFF)
end

function Scenery.manifest(m)
  return m:manifest(Scenery.MANIFEST)
end

local function globals(m)
  local g = m.globals
  g.movingSceneryVBase = g.movingSceneryVBase or 0
  g.movingSceneryVOffset = g.movingSceneryVOffset or 0
  g.movingSceneryState = g.movingSceneryState or Scenery.NORMAL
  return g
end

local function anyPath(entry)
  if entry.png then return entry.png end
  local keys = {}
  for k in pairs(entry.variants or {}) do keys[#keys + 1] = k end
  table.sort(keys)
  return entry.variants[keys[1]]
end

local function atlasSheet(entry)
  local rects = {}
  for i, r in ipairs(entry.rects) do rects[i] = { x = r.x, y = r.y, w = r.w, h = r.h, tile = r.tile } end
  return Ppu.indexSheet(anyPath(entry), entry.w, entry.h, rects)
end

local function atlasAnims(entry)
  local frameOfTile = {}
  for i, r in ipairs(entry.rects) do frameOfTile[r.tile] = i - 1 end
  local anims = {}
  for ai, anim in ipairs(entry.anims) do
    local list = {}
    for ci, c in ipairs(anim) do
      local row = {}
      for k, v in pairs(c) do row[k] = v end
      if c.op == "frame" then row.frame = frameOfTile[c.tile] or 0 end
      list[ci] = row
    end
    anims[ai] = list
  end
  return anims
end

local function palette(man, name)
  return assert(man.palettes[name], "intro_credits_scenery: palette " .. name .. " missing from cache")
end

-- pokeemerald/src/intro_credits_graphics.c:1037
local function movingSceneryCb(s, sp, m)
  local g = globals(m)
  local state = g.movingSceneryState
  if state == Scenery.FROZEN then return end
  if state ~= Scenery.NORMAL then
    sp:destroy(s)
    return
  end
  local x = bor(lshift(s.x, 16), u16(s.data[2])) + u16(s.data[1])
  x = bit.tobit(x)
  s.x = s16(rshift(x, 16))
  s.data[2] = s16(x)
  if s.x > 255 then s.x = -32 end
  if s.data[0] ~= 0 then
    s.y2 = -(g.movingSceneryVBase + g.movingSceneryVOffset)
  else
    s.y2 = -g.movingSceneryVBase
  end
end

-- pokeemerald/src/intro_credits_graphics.c:1064
local function createMovingScenerySprites(m, hasVerticalMove, entry)
  local sp = m.ppu.sprites
  local sheet = atlasSheet(entry)
  local anims = atlasAnims(entry)
  for _, md in ipairs(entry.sprites) do
    local id = sp:create({
      w = md.w, h = md.h, anims = anims, sheet = sheet,
      callback = function(s, spr) movingSceneryCb(s, spr, m) end,
    }, md.x, md.y, md.subpriority)
    local s = sp:get(id)
    Sprites.calcCenterToCornerVec(s, md.shape, md.size, 0)
    s.oam.priority = 3
    s.oam.shape, s.oam.size = md.shape, md.size
    s.oam.paletteNum = 0
    Sprites.startAnim(s, md.animNum)
    s.data[0] = hasVerticalMove and 1 or 0
    s.data[1] = s16(md.xOff)
    s.data[2] = 0
  end
end

local function bindLayer(m, bg, man, key, priority)
  m.ppu:setBg(bg, priority, Machine.layer(man.layers[key]), false)
end

-- pokeemerald/src/intro_credits_graphics.c:729
function Scenery.loadIntroPart2Graphics(m, scenery)
  local man = Scenery.manifest(m)
  local pal = m.ppu.palette
  pal:load(palette(man, "sGrass_Pal"), 15 * 16, #palette(man, "sGrass_Pal"))
  local g = globals(m)
  if scenery == 1 then
    pal:load(palette(man, "sTrees_Pal"), 0, #palette(man, "sTrees_Pal"))
    pal:load(palette(man, "sTreesSmall_Pal"), 256, #palette(man, "sTreesSmall_Pal"))
    m.sceneryLayers = { bg3 = "trees_bg3", bg2 = "trees_bg2" }
    createMovingScenerySprites(m, true, man.scenery.moving_trees)
  else
    pal:load(palette(man, "sCloudsBg_Pal"), 0, #palette(man, "sCloudsBg_Pal"))
    pal:load(palette(man, "sClouds_Pal"), 256, #palette(man, "sClouds_Pal"))
    m.sceneryLayers = { bg3 = "clouds_bg3", bg2 = "clouds_bg2" }
    createMovingScenerySprites(m, false, man.scenery.moving_clouds)
  end
  g.movingSceneryState = Scenery.NORMAL
  m.ppu.sprites:setReservedPalettes(8)
end

-- pokeemerald/src/intro_credits_graphics.c:761
function Scenery.setIntroPart2BgCnt(m)
  local man = Scenery.manifest(m)
  local layers = m.sceneryLayers
  bindLayer(m, 3, man, layers.bg3, 3)
  bindLayer(m, 2, man, layers.bg2, 2)
  bindLayer(m, 1, man, "grass", 1)
  m.ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG1_ON,
    Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_BG3_ON, Ppu.DISPCNT_OBJ_ON))
end

-- pokeemerald/src/intro_credits_graphics.c:838
function Scenery.loadCreditsSceneGraphics(m, scene)
  local man = Scenery.manifest(m)
  local pal = m.ppu.palette
  local function load(name, offset)
    local p = palette(man, name)
    pal:load(p, offset, #p)
  end
  if scene == Scenery.SCENE_OCEAN_SUNSET then
    load("sGrassSunset_Pal", 15 * 16)
    load("sCloudsBgSunset_Pal", 0)
    load("sCloudsSunset_Pal", 256)
    m.sceneryLayers = { bg3 = "clouds_bg3", bg2 = "clouds_bg2" }
    createMovingScenerySprites(m, false, man.scenery.moving_clouds)
  elseif scene == Scenery.SCENE_FOREST_RIVAL_ARRIVE or scene == Scenery.SCENE_FOREST_CATCH_RIVAL then
    load("sGrassSunset_Pal", 15 * 16)
    load("sTreesSunset_Pal", 0)
    load("sTreesSunset_Pal", 256)
    m.sceneryLayers = { bg3 = "trees_bg3", bg2 = "trees_bg2" }
    createMovingScenerySprites(m, true, man.scenery.moving_trees)
  elseif scene == Scenery.SCENE_CITY_NIGHT then
    load("sGrassNight_Pal", 15 * 16)
    load("sHouses_Pal", 0)
    load("sHouseSilhouette_Pal", 256)
    m.sceneryLayers = { bg3 = "houses_bg3", bg2 = "houses_bg2" }
    createMovingScenerySprites(m, true, man.scenery.moving_houses)
  else
    load("sGrass_Pal", 15 * 16)
    load("sCloudsBg_Pal", 0)
    load("sClouds_Pal", 256)
    m.sceneryLayers = { bg3 = "clouds_bg3", bg2 = "clouds_bg2" }
    createMovingScenerySprites(m, false, man.scenery.moving_clouds)
  end
  m.ppu.sprites:setReservedPalettes(8)
  globals(m).movingSceneryState = Scenery.NORMAL
end

-- pokeemerald/src/intro_credits_graphics.c:889
function Scenery.setCreditsSceneBgCnt(m)
  local man = Scenery.manifest(m)
  local layers = m.sceneryLayers
  bindLayer(m, 3, man, layers.bg3, 3)
  bindLayer(m, 2, man, layers.bg2, 2)
  bindLayer(m, 1, man, "grass", 1)
  m.ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG_ALL_ON, Ppu.DISPCNT_OBJ_ON))
end

local function step(hi, lo, speed)
  local offset = bit.tobit(lshift(hi, 16) + u16(lo))
  offset = bit.tobit(offset - lshift(u16(speed), 4))
  return s16(bit.arshift(offset, 16)), s16(offset)
end

-- pokeemerald/src/intro_credits_graphics.c:942
local function bicycleBgTask(id, d, m)
  local g = globals(m)
  local ppu = m.ppu
  if d[1] ~= 0 then
    d[2], d[3] = step(d[2], d[3], d[1])
    ppu:set("BG1HOFS", u16(d[2]))
    ppu:set("BG1VOFS", u16(g.movingSceneryVBase + g.movingSceneryVOffset))
  end
  if d[4] ~= 0 then
    d[5], d[6] = step(d[5], d[6], d[4])
    ppu:set("BG2HOFS", u16(d[5]))
    if d[0] ~= 0 then
      ppu:set("BG2VOFS", u16(g.movingSceneryVBase + g.movingSceneryVOffset))
    else
      ppu:set("BG2VOFS", u16(g.movingSceneryVBase))
    end
  end
  if d[7] ~= 0 then
    d[8], d[9] = step(d[8], d[9], d[7])
    ppu:set("BG3HOFS", u16(d[8]))
    ppu:set("BG3VOFS", u16(g.movingSceneryVBase))
  end
end

Scenery.bicycleBgTask = bicycleBgTask

-- pokeemerald/src/intro_credits_graphics.c:924
function Scenery.createBicycleBgAnimationTask(m, mode, bg1Speed, bg2Speed, bg3Speed)
  local id = m.tasks:create(function(i, d) bicycleBgTask(i, d, m) end, 0)
  local d = m.tasks:get(id).data
  d[0] = mode
  d[1] = s16(bg1Speed)
  d[2], d[3] = 0, 0
  d[4] = s16(bg2Speed)
  d[5], d[6] = 0, 0
  d[7] = s16(bg3Speed)
  d[8], d[9] = 8, 0
  bicycleBgTask(id, d, m)
  return id
end

-- pokeemerald/src/intro_credits_graphics.c:989
function Scenery.cycleSceneryPalette(m, mode)
  local pal = m.ppu.palette
  local vb = m.vblankCounter1
  if mode == 1 then return end
  if band(vb, 3) ~= 0 or pal:fadeActive() then return end
  local x, y
  if mode == 2 then
    if band(vb, 4) ~= 0 then
      x = bor(7, lshift(9, 5), lshift(15, 10))
      y = bor(21, lshift(20, 5), lshift(0, 10))
    else
      x = bor(28, lshift(24, 5), lshift(0, 10))
      y = bor(7, lshift(9, 5), lshift(15, 10))
    end
    pal:load({ x }, 12, 1)
    pal:load({ y }, 13, 1)
    return
  end
  if band(vb, 4) ~= 0 then
    x, y = pal.unfaded[9], pal.unfaded[10]
  else
    x, y = pal.unfaded[10], pal.unfaded[9]
  end
  pal:load({ x }, 9, 1)
  pal:load({ y }, 10, 1)
end

local function spriteEntry(m, key)
  return assert(Scenery.manifest(m).sprites[key], "intro_credits_scenery: sprite " .. key .. " missing from cache")
end

local function template(m, key, paletteTag, callback)
  local e = spriteEntry(m, key)
  return Machine.template(e, { paletteTag = paletteTag, callback = callback })
end

-- pokeemerald/src/intro_credits_graphics.c:1109
local function bicycleCb(s, sp)
  local p = sp:get(s.data[0])
  s.invisible = p.invisible
  s.x = p.x
  s.y = p.y + 8
  s.x2 = p.x2
  s.y2 = p.y2
end

local function createPlayer(m, key, tag, x, y)
  local sp = m.ppu.sprites
  local player = sp:create(template(m, key, tag, nil), x, y, 2)
  local bike = sp:create(template(m, "bicycle", tag, bicycleCb), x, y + 8, 3)
  sp:get(bike).data[0] = player
  return player
end

-- pokeemerald/src/intro_credits_graphics.c:1118
function Scenery.createIntroBrendanSprite(m, x, y)
  return createPlayer(m, "brendan", Scenery.TAG_BRENDAN, x, y)
end

-- pokeemerald/src/intro_credits_graphics.c:1126
function Scenery.createIntroMaySprite(m, x, y)
  return createPlayer(m, "may", Scenery.TAG_MAY, x, y)
end

-- pokeemerald/src/intro_credits_graphics.c:1142
local function flygonRightCb(s, sp)
  local l = sp:get(s.data[0])
  s.invisible = l.invisible
  s.y = l.y
  s.x2 = l.x2
  s.y2 = l.y2
end

-- pokeemerald/src/intro_credits_graphics.c:1162
function Scenery.createIntroFlygonSprite(m, x, y)
  local sp = m.ppu.sprites
  local left = sp:create(template(m, "flygon", Scenery.TAG_FLYGON_LATIAS, nil), x - 32, y, 5)
  local right = sp:create(template(m, "flygon", Scenery.TAG_FLYGON_LATIAS, nil), x + 32, y, 6)
  local r = sp:get(right)
  r.data[0] = left
  Sprites.startAnim(r, 1)
  r.callback = flygonRightCb
  return left
end

-- pokeemerald/src/intro_credits_graphics.c:630
function Scenery.loadPlayerFlygonPalettes(m)
  local man = Scenery.manifest(m)
  local sp = m.ppu.sprites
  sp:loadPalette(Scenery.TAG_BRENDAN, palette(man, "gIntroPlayer_Pal"))
  sp:loadPalette(Scenery.TAG_MAY, palette(man, "gIntroPlayer_Pal"))
  sp:loadPalette(Scenery.TAG_FLYGON_LATIOS, palette(man, "gIntroFlygon_Pal"))
  sp:loadPalette(Scenery.TAG_FLYGON_LATIAS, palette(man, "gIntroFlygon_Pal"))
end

return Scenery
