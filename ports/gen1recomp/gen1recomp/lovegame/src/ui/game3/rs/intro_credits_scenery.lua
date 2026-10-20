local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local band = bit.band
local Scenery = { MANIFEST = "data/generated/gba/intro/rs/scenery/manifest.lua" }
local function s16(n) n = band(n, 65535); return n >= 32768 and n - 65536 or n end
local function manifest(m)
  local man = m:manifest(Scenery.MANIFEST)
  assert(man.layout == "rs", "RS scenery needs native assets")
  return man
end
local function palette(man, name) return assert(man.palettes[name], "RS scenery palette " .. name) end

-- pokeruby/src/intro_credits_graphics.c:529
local function movingCb(s, sp, m)
  local g = m.globals
  if g.movingSceneryState ~= 0 then sp:destroy(s); return end
  local n = bit.tobit(s.x * 65536 + band(s.data[2], 65535) + band(s.data[1], 65535))
  s.x, s.data[2] = math.floor(n / 65536), s16(n)
  if s.x > 255 then s.x = -32 end
  s.y2 = -(g.movingSceneryVBase + (s.data[0] ~= 0 and g.movingSceneryVOffset or 0))
end

-- pokeruby/src/intro_credits_graphics.c:551
local function createMoving(m, entry, vertical)
  local frameByTile, anims = {}, {}
  for i, rect in ipairs(entry.rects) do frameByTile[rect.tile] = i - 1 end
  for ai, anim in ipairs(entry.anims) do
    local list = {}
    for ci, cmd in ipairs(anim) do
      local row = {}; for k, v in pairs(cmd) do row[k] = v end
      if row.op == "frame" then row.frame = assert(frameByTile[row.tile], "RS scenery tile absent") end
      list[ci] = row
    end
    anims[ai] = list
  end
  local sheet = Ppu.indexSheet(entry.variants.day or entry.variants.night, entry.w, entry.h, entry.rects)
  local sp = m.ppu.sprites
  for _, md in ipairs(entry.sprites) do
    local s = sp:get(sp:create({ w = md.w, h = md.h, sheet = sheet, anims = anims,
      callback = function(a, b) movingCb(a, b, m) end }, md.x, md.y, md.subpriority))
    Sprites.calcCenterToCornerVec(s, md.shape, md.size, 0)
    s.oam.priority, s.oam.shape, s.oam.size, s.oam.paletteNum = 3, md.shape, md.size, 0
    Sprites.startAnim(s, md.animNum)
    s.data[0], s.data[1], s.data[2] = vertical and 1 or 0, s16(md.xOff), 0
  end
end

-- pokeruby/src/intro_credits_graphics.c:313
function Scenery.loadIntro(m, mode)
  local man, p = manifest(m), m.ppu
  local function load(name, offset) local pal = palette(man, name); p.palette:load(pal, offset, #pal) end
  load("gUnknown_084121FC", 240)
  if mode == 1 then
    load("gUnknown_08413300", 0); load("gUnknown_08413CCC", 256)
    m.sceneryLayers = { "trees_bg3", "trees_bg2" }
    createMoving(m, man.scenery.moving_trees, true)
  else
    load("gUnknown_08412818", 0); load("gUnknown_08413184", 256)
    m.sceneryLayers = { "clouds_bg3", "clouds_bg2" }
    createMoving(m, man.scenery.moving_clouds, false)
  end
  m.globals.movingSceneryState = 0
  p.sprites:setReservedPalettes(8)
end

-- pokeruby/src/intro_credits_graphics.c:343
function Scenery.showIntro(m)
  local man, p = manifest(m), m.ppu
  p:setBg(3, 3, Machine.layer(man.layers[m.sceneryLayers[1]]))
  p:setBg(2, 2, Machine.layer(man.layers[m.sceneryLayers[2]]))
  p:setBg(1, 1, Machine.layer(man.layers.grass))
  p:set("DISPCNT", 0x1E40)
end

local function step(hi, lo, speed)
  local n = bit.tobit(hi * 65536 + band(lo, 65535) - 16 * band(speed, 65535))
  return math.floor(n / 65536), s16(n)
end
-- pokeruby/src/intro_credits_graphics.c:438
function Scenery.bicycleBgTask(_, d, m)
  local g, p = m.globals, m.ppu
  if d[1] ~= 0 then
    d[2], d[3] = step(d[2], d[3], d[1]); p:set("BG1HOFS", d[2])
    p:set("BG1VOFS", g.movingSceneryVBase + g.movingSceneryVOffset)
  end
  if d[4] ~= 0 then
    d[5], d[6] = step(d[5], d[6], d[4]); p:set("BG2HOFS", d[5])
    p:set("BG2VOFS", g.movingSceneryVBase + (d[0] ~= 0 and g.movingSceneryVOffset or 0))
  end
  if d[7] ~= 0 then
    d[8], d[9] = step(d[8], d[9], d[7]); p:set("BG3HOFS", d[8]); p:set("BG3VOFS", g.movingSceneryVBase)
  end
end
-- pokeruby/src/intro_credits_graphics.c:421
function Scenery.createBgTask(m, mode, bg1, bg2, bg3)
  local id = m.tasks:create(function(i, d) Scenery.bicycleBgTask(i, d, m) end, 0)
  local d = m.tasks:get(id).data
  d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9] = mode, s16(bg1), 0, 0, s16(bg2), 0, 0, s16(bg3), 8, 0
  Scenery.bicycleBgTask(id, d, m)
  return id
end
-- pokeruby/src/intro_credits_graphics.c:483
function Scenery.cyclePalette(m, mode)
  if mode == 1 then return end
  local pal, vb = m.ppu.palette, m.vblankCounter1
  if band(vb, 3) ~= 0 or pal:fadeActive() then return end
  local x, y
  if mode == 2 then
    if band(vb, 4) ~= 0 then x, y = 0x3D27, 0x0295 else x, y = 0x031C, 0x3D27 end
    pal:load({ x, y }, 12, 2)
  else
    if band(vb, 4) ~= 0 then x, y = pal.unfaded[9], pal.unfaded[10] else x, y = pal.unfaded[10], pal.unfaded[9] end
    pal:load({ x, y }, 9, 2)
  end
end

-- pokeruby/src/intro_credits_graphics.c:285
function Scenery.loadRiderEonPalettes(m)
  local man = manifest(m)
  for _, row in ipairs({ { 1002, "gIntro2BrendanPalette" }, { 1003, "gIntro2MayPalette" },
    { 1004, "gIntro2LatiosPalette" }, { 1005, "gIntro2LatiasPalette" } }) do
    m.ppu.sprites:loadPalette(row[1], palette(man, row[2]))
  end
end
local function template(m, key, callback, tag)
  local e = assert(manifest(m).sprites[key], "RS scenery sprite " .. key)
  return Machine.template(e, { callback = callback, paletteTag = tag or e.paletteTag })
end
-- pokeruby/src/intro_credits_graphics.c:590
local function bicycleCb(s, sp)
  local rider = sp:get(s.data[0])
  s.invisible, s.x, s.y, s.x2, s.y2 = rider.invisible, rider.x, rider.y + 8, rider.x2, rider.y2
end
-- pokeruby/src/intro_credits_graphics.c:601
function Scenery.createRider(m, gender, x, y, callback)
  local sp, key = m.ppu.sprites, gender == 0 and "brendan" or "may"
  local rider = sp:create(template(m, key, callback), x, y, 0)
  local bicycle = sp:get(sp:create(template(m, "bicycle", bicycleCb, gender == 0 and 1002 or 1003), x, y + 8, 1))
  bicycle.data[0] = rider
  return rider
end
-- pokeruby/src/intro_credits_graphics.c:626
local function eonRightCb(s, sp)
  local left = sp:get(s.data[0])
  s.invisible, s.y, s.x2, s.y2 = left.invisible, left.y, left.x2, left.y2
end
-- pokeruby/src/intro_credits_graphics.c:635
function Scenery.createEon(m, x, y, callback)
  local sp, key = m.ppu.sprites, manifest(m).game == "sapphire" and "latias" or "latios"
  local left = sp:create(template(m, key, callback), x - 32, y, 2)
  local right = sp:get(sp:create(template(m, key, eonRightCb), x + 32, y, 2))
  right.data[0] = left; Sprites.startAnim(right, 1)
  return left
end

return Scenery
