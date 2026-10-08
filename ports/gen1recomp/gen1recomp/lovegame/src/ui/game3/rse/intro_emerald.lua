local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Scenery = require("src.ui.game3.rse.intro_credits_scenery")
local Ppu = require("src.core.game3.gba_ppu")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Affine = require("src.core.game3.bg_affine")
local Trig = require("src.core.game3.trig")

local band, bor, bxor, lshift, rshift = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift

local Intro = {}
Intro.__index = Intro

Intro.MANIFEST = "data/generated/gba/intro/rse/manifest.lua"
Intro.EXTRA = "data/generated/gba/intro/rse_extra/manifest.lua"
Intro.TITLE = "data/generated/gba/title/manifest.lua"

-- pokeemerald/src/intro.c:117
Intro.COPYRIGHT_START_FADE = 140

-- pokeemerald/src/main.c:366
Intro.BOOT_VBLANKS = 12

Intro.STALL = {
  -- pokeemerald/src/intro.c:1089
  copyrightInit = 1,
  -- pokeemerald/src/intro.c:1151
  saveLoad = 28,
  -- pokeemerald/src/intro.c:1178
  scene1Load = 3,
  -- pokeemerald/src/intro.c:1366
  scene2Load = 2,
  -- pokeemerald/src/intro.c:1381
  scene2CreateSprites = 3,
  -- pokeemerald/src/intro.c:1724
  scene3Load = 1,
  -- pokeemerald/src/intro.c:1779
  loadGroudon = 3,
  -- pokeemerald/src/intro.c:2057
  loadKyogre = 2,
  -- pokeemerald/src/intro.c:2365
  loadClouds1 = 1,
  -- pokeemerald/src/intro.c:2432
  loadLightning = 1,
}

-- pokeemerald/src/intro.c:147
local T = {
  BIG_DROP_START = 76, LOGO_APPEAR = 128, LOGO_LETTERS_COLOR = 144, BIG_DROP_FALLS = 251,
  LOGO_BLEND_OUT = 256, LOGO_DISAPPEAR = 272, SMALL_DROP_1 = 368, SMALL_DROP_2 = 384,
  SPARKLES = 560, FLYGON_SILHOUETTE_APPEAR = 832, END_PAN_UP = 904, END_SCENE_1 = 1007,
  START_SCENE_2 = 1026, MANECTRIC_ENTER = 1088, PLAYER_DRIFT_BACK = 1109, MANECTRIC_RUN_CIRCULAR = 1168,
  PLAYER_MOVE_FORWARD = 1214, TORCHIC_ENTER = 1224, FLYGON_ENTER = 1394, PLAYER_MOVE_BACKWARD = 1398,
  PLAYER_HOLD_POSITION = 1576, PLAYER_EXIT = 1727, TORCHIC_SPEED_UP = 1735, TORCHIC_EXIT = 1856,
  END_SCENE_2 = 1946, START_SCENE_3 = 2068, POKEBALL_FADE = 28, START_LEGENDARIES = 43,
}
Intro.TIMER = T

-- pokeemerald/src/intro.c:121
local TAG_VOLBEAT, TAG_TORCHIC, TAG_MANECTRIC = 1500, 1501, 1502
local TAG_LIGHTNING, TAG_BUBBLES, TAG_SPARKLE = 1503, 1504, 1505
local PALTAG_DROPS, PALTAG_LOGO = 2000, 2001
local TAG_FLYGON_SILHOUETTE, TAG_RAYQUAZA_ORB = 2002, 2003

local SINE = Trig.SINE

local function sine(i)
  return SINE[i + 1]
end

local function Sin(i, amp)
  return math.floor(amp * SINE[i + 1] / 256)
end

local function Cos(i, amp)
  return math.floor(amp * SINE[i + 64 + 1] / 256)
end

local function div(a, b)
  local q = a / b
  if q >= 0 then return math.floor(q) end
  return -math.floor(-q)
end

local function s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

local function u16(v)
  return band(v, 0xFFFF)
end

local function u8(v)
  return band(v, 0xFF)
end

local function songId(name)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get()):require("songs", name)
end

local function speciesId(name)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get()):require("species", name)
end

local function audio()
  return require("src.core.game3.audio")
end

function Intro.new(machine, opts)
  opts = opts or {}
  local self = setmetatable({}, Intro)
  self.m = machine
  self.man = machine:manifest(Intro.MANIFEST)
  self.extra = machine:manifest(Intro.EXTRA)
  self.alpha = machine:manifest(Intro.TITLE).alphaBlend
  self.counter = 0
  self.gender = 0
  self.flygonYOffset = 0
  self.scene = "copyright"
  self.log = {}
  self.coldBoot = opts.coldBoot == true
  if self.coldBoot then machine.vblankCounter1 = -1 end
  self.done = false
  machine:setCb2(function(m) self:copyrightCb() end)
  return self
end

function Intro:mark(what)
  self.log[#self.log + 1] = { frame = self.frames or 0, counter = self.counter, what = what }
end

function Intro:sprite(key)
  return assert(self.man.sprites[key], "intro_emerald: sprite " .. key .. " missing from cache")
end

function Intro:layer(key)
  return Machine.layer(assert(self.man.layers[key], "intro_emerald: layer " .. key .. " missing from cache"))
end

function Intro:pal(name)
  return assert(self.man.palettes[name], "intro_emerald: palette " .. name .. " missing from cache")
end

function Intro:alphaReg(i)
  local row = self.alpha[i + 1]
  return Ppu.blendAlpha(row[1], row[2])
end

-- pokeemerald/src/intro.c:1034
function Intro.vblankIntro(m)
  m.ppu:vblank()
end

-- pokeemerald/src/intro.c:2701
function Intro:resetGpuRegs()
  local p = self.m.ppu
  for _, r in ipairs({ "DISPCNT", "BG3HOFS", "BG3VOFS", "BG2HOFS", "BG2VOFS", "BG1HOFS", "BG1VOFS",
    "BG0HOFS", "BG0VOFS", "BLDCNT", "BLDALPHA", "BLDY" }) do
    p:set(r, 0)
  end
end

function Intro:clearVram()
  for i = 0, 3 do self.m.ppu:setBg(i, 0, nil) end
end

-- pokeemerald/src/intro.c:1072
function Intro:copyrightCb()
  local m, ppu = self.m, self.m.ppu
  local pal = ppu.palette
  if m.state == 0 then
    if self.coldBoot then
      local Rng = require("src.core.game3.rng")
      Rng.SeedRng(0)
      for _ = 1, Intro.BOOT_VBLANKS do Rng.Random() end
    end
    m:setVBlank(nil)
    ppu:set("BLDCNT", 0)
    ppu:set("BLDALPHA", 0)
    ppu:set("BLDY", 0)
    pal.pltt[0] = Palette.WHITE
    ppu:set("DISPCNT", 0)
    ppu:set("BG0HOFS", 0)
    ppu:set("BG0VOFS", 0)
    self:clearVram()
    ppu.sprites.oamShown = {}
    pal:clearHardware(1)
    pal:resetFade()
    pal:load(self:pal("gIntroCopyright_Pal"), 0, 16)
    ppu.scanline:stop()
    m.tasks:reset()
    ppu.sprites:resetData()
    ppu.sprites:freeAllPalettes()
    pal:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
    ppu:setBg(0, 0, self:layer("copyright"))
    m:setVBlank(Intro.vblankIntro)
    ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON))
    m:addStall(Intro.STALL.copyrightInit)
    self:mark("copyright")
  end
  if m.state == Intro.COPYRIGHT_START_FADE then
    pal:beginFade(Palette.ALL, 0, 0, 16, Palette.BLACK)
    m.state = m.state + 1
    return
  end
  if m.state == Intro.COPYRIGHT_START_FADE + 1 then
    if pal:update() ~= 0 then return end
    m.tasks:create(function(id, d) self:scene1Load(id, d) end, 0)
    m:setCb2(function() self:mainCb() end)
    if self.coldBoot then
      require("src.core.game3.rng").Random()
      m:addStall(Intro.STALL.saveLoad)
    end
    return
  end
  pal:update()
  m.state = m.state + 1
end

-- pokeemerald/src/intro.c:1042
function Intro:mainCb()
  local m = self.m
  m.tasks:run(self)
  m.ppu.sprites:animateAll()
  m.ppu.sprites:buildOam()
  m.ppu.palette:update()
  if m.newKeys ~= 0 and not m.ppu.palette:fadeActive() then
    self:mark("skip")
    m:setCb2(function() self:endCb() end)
  else
    self.counter = self.counter + 1
  end
end

-- pokeemerald/src/intro.c:1054
function Intro:endCb()
  if self.m.ppu.palette:update() == 0 then
    self.done = true
    self.m:setCb2(nil)
    self:mark("end")
  end
end

function Intro:update(input)
  self.frames = (self.frames or 0) + 1
  self.m:frame(input)
  if self.done then return "title" end
  return nil
end

function Intro:draw()
  self.m.ppu:draw(0, 0)
end

function Intro:snapshot()
  return self.m.ppu:snapshot()
end

function Intro:destroy()
end

local function template(self, key, paletteTag, callback, extra)
  local t = Machine.template(self:sprite(key), { paletteTag = paletteTag, callback = callback })
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

-- pokeemerald/src/intro.c:1169
function Intro:scene1Load(id, d)
  local m, ppu = self.m, self.m.ppu
  local pal, sp = ppu.palette, ppu.sprites
  local Rng = require("src.core.game3.rng")
  m:setVBlank(nil)
  self.gender = Rng.Random() % 2
  self:mark("gender " .. self.gender)
  self:resetGpuRegs()
  ppu:set("BG3VOFS", 0)
  ppu:set("BG2VOFS", 80)
  ppu:set("BG1VOFS", 24)
  ppu:set("BG0VOFS", 40)
  local bgPal = self:pal("sIntro1Bg_Pal")
  pal:load(bgPal, 0, #bgPal)
  ppu:setBg(3, 3, self:layer("scene1_bg3"))
  ppu:setBg(2, 2, self:layer("scene1_bg2"))
  ppu:setBg(1, 1, self:layer("scene1_bg1"))
  ppu:setBg(0, 0, self:layer("scene1_bg0"))
  sp:loadPalette(PALTAG_DROPS, self:pal("sIntroDrops_Pal"))
  sp:loadPalette(PALTAG_LOGO, self:pal("sIntroLogo_Pal"))
  sp:loadPalette(TAG_FLYGON_SILHOUETTE, self:pal("sIntroFlygonSilhouette_Pal"))
  sp:loadPalette(TAG_SPARKLE, self:pal("gIntroLightning_Pal"))
  for k = 0, 6 do
    pal:copyUnfaded(256, 256 + (15 - k) * 16 + k, 16 - k)
  end
  self:createGameFreakLogoSprites(120, 80)
  d[0] = self:createWaterDrop(236, -14, 0x200, 1, 0x78, false)
  m.tasks:setFunc(id, function(i, dd) self:scene1FadeIn(i, dd) end)
  m:addStall(Intro.STALL.scene1Load)
end

-- pokeemerald/src/intro.c:1209
function Intro:scene1FadeIn(id, d)
  local m, ppu = self.m, self.m.ppu
  ppu.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.BLACK)
  m:setVBlank(Intro.vblankIntro)
  ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG_ALL_ON, Ppu.DISPCNT_OBJ_ON))
  m.tasks:setFunc(id, function(i, dd) self:scene1WaterDrops(i, dd) end)
  self.counter = 0
  self.scene = "scene1"
  audio().playSong(songId("MUS_INTRO"), { restart = true })
  self:mark("scene1 MUS_INTRO")
end

-- pokeemerald/src/intro.c:1228
function Intro:scene1WaterDrops(id, d)
  local m = self.m
  local sp = m.ppu.sprites
  local c = self.counter
  if c == T.BIG_DROP_START then sp:get(d[0]).data[0] = 1 end
  if c == T.LOGO_APPEAR then m.tasks:create(function(i, dd) self:blendLogoIn(i, dd) end, 0) end
  if c == T.BIG_DROP_FALLS then sp:get(d[0]).data[0] = 2 end
  if c == T.LOGO_BLEND_OUT then m.tasks:create(function(i, dd) self:blendLogoOut(i, dd) end, 0) end
  if c == T.SMALL_DROP_1 then self:createWaterDrop(48, 0, 0x400, 5, 0x70, true) end
  if c == T.SMALL_DROP_2 then self:createWaterDrop(200, 60, 0x400, 9, 0x80, true) end
  if c == T.SPARKLES then m.tasks:create(function(i, dd) self:createSparkles(i, dd) end, 0) end
  if c > T.SPARKLES then
    d[1], d[2], d[3], d[4], d[5], d[6] = 80, 0, 24, 0, 40, 0
    m.tasks:setFunc(id, function(i, dd) self:scene1PanUp(i, dd) end)
  end
end

-- pokeemerald/src/intro.c:1268
function Intro:createSparkles(id, d)
  local sp = self.m.ppu.sprites
  d[2] = d[2] + 1
  if band(d[2], 1) ~= 0 then d[3] = d[3] + 1 end
  if d[0] == 0 then
    local xy = self.man.tables.sparkleCoords[d[4] + 1] or { 0, 0 }
    sp:create(template(self, "sparkle", TAG_SPARKLE, function(s, spr)
      s.data[0] = s.data[0] + 1
      if s.data[0] == 12 then spr:destroy(s) end
    end), xy[1], xy[2] + d[3], 0)
    d[0] = d[0] + 1
    d[1] = 12
    d[4] = d[4] + 1
  elseif d[0] == 1 then
    d[1] = d[1] - 1
    if d[1] == 0 then d[0] = 0 end
  end
  if d[3] > 60 then self.m.tasks:destroy(id) end
end

local function panStep(hi, lo, delta)
  local offset = bit.tobit(lshift(hi, 16) + u16(lo)) - delta
  offset = bit.tobit(offset)
  return s16(bit.arshift(offset, 16)), s16(offset)
end

-- pokeemerald/src/intro.c:1306
function Intro:scene1PanUp(id, d)
  local ppu = self.m.ppu
  if self.counter < T.END_PAN_UP then
    d[1], d[2] = panStep(d[1], d[2], 0x6000)
    ppu:set("BG2VOFS", u16(d[1]))
    d[3], d[4] = panStep(d[3], d[4], 0x8000)
    ppu:set("BG1VOFS", u16(d[3]))
    d[5], d[6] = panStep(d[5], d[6], 0xC000)
    ppu:set("BG0VOFS", u16(d[5]))
    if self.counter == T.FLYGON_SILHOUETTE_APPEAR then
      local sid = ppu.sprites:create(template(self, "flygon_silhouette", TAG_FLYGON_SILHOUETTE,
        function(s) self:flygonSilhouetteCb(s) end), 120, 160, 10)
      ppu.sprites:get(sid).invisible = true
    end
  elseif self.counter > T.END_SCENE_1 then
    ppu.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA)
    self.m.tasks:setFunc(id, function(i, dd) self:scene1End(i, dd) end)
  end
end

-- pokeemerald/src/intro.c:1351
function Intro:scene1End(id)
  if self.counter > T.START_SCENE_2 then
    self.m.tasks:setFunc(id, function(i, dd) self:scene2Load(i, dd) end)
  end
end

-- pokeemerald/src/intro.c:1357
function Intro:scene2Load(id)
  local m, ppu = self.m, self.m.ppu
  self:resetGpuRegs()
  m:setVBlank(nil)
  ppu.sprites:resetData()
  ppu.sprites:freeAllPalettes()
  m.globals.movingSceneryVBase = 0
  m.globals.movingSceneryVOffset = 0
  self.flygonYOffset = 0
  Scenery.loadIntroPart2Graphics(m, 1)
  m.tasks:setFunc(id, function(i, dd) self:scene2CreateSprites(i, dd) end)
  m:addStall(Intro.STALL.scene2Load)
  self.scene = "scene2"
  self:mark("scene2")
end

-- pokeemerald/src/intro.c:1375
function Intro:scene2CreateSprites(id, d)
  local m, ppu = self.m, self.m.ppu
  local sp = ppu.sprites
  Scenery.loadPlayerFlygonPalettes(m)
  sp:loadPalette(TAG_VOLBEAT, self:pal("gIntroVolbeat_Pal"))
  sp:loadPalette(TAG_TORCHIC, self:pal("gIntroTorchic_Pal"))
  sp:loadPalette(TAG_MANECTRIC, self:pal("gIntroManectric_Pal"))
  sp:create(template(self, "manectric", TAG_MANECTRIC, function(s, spr) self:manectricCb(s, spr) end), 240 + 32, 128, 0)
  sp:create(template(self, "torchic", TAG_TORCHIC, function(s) self:torchicCb(s) end), 240 + 48, 110, 1)
  local pid
  if self.gender == 0 then
    pid = Scenery.createIntroBrendanSprite(m, 240 + 32, 100)
  else
    pid = Scenery.createIntroMaySprite(m, 240 + 32, 100)
  end
  local player = sp:get(pid)
  player.callback = function(s) self:playerOnBicycleCb(s) end
  player.anims = self.extra.playerBicycleAnims
  d[1] = pid
  sp:create(template(self, "volbeat", TAG_VOLBEAT, function(s, spr) self:volbeatCb(s, spr) end), 240 + 32, 80, 4)
  local fid = Scenery.createIntroFlygonSprite(m, -64, 60)
  sp:get(fid).callback = function(s) self:flygonCb(s) end
  d[2] = fid
  ppu.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
  m:setVBlank(Intro.vblankIntro)
  d[0] = Scenery.createBicycleBgAnimationTask(m, 1, 0x4000, 0x400, 0x10)
  Scenery.setIntroPart2BgCnt(m)
  m.tasks:setFunc(id, function(i, dd) self:scene2BikeRide(i, dd) end)
  m:addStall(Intro.STALL.scene2CreateSprites, true)
end

-- pokeemerald/src/intro.c:1420
function Intro:scene2BikeRide(id, d)
  local m = self.m
  local sp = m.ppu.sprites
  local c = self.counter
  if c == T.TORCHIC_EXIT then
    m.globals.movingSceneryState = Scenery.FROZEN
    m.tasks:destroy(d[0])
  end
  if c > T.END_SCENE_2 then
    m.ppu.palette:beginFade(Palette.ALL, 8, 0, 16, Palette.WHITEALPHA)
    m.tasks:setFunc(id, function(i, dd) self:scene2End(i, dd) end)
  end
  local player, flygon = sp:get(d[1]), sp:get(d[2])
  if c == T.PLAYER_DRIFT_BACK then player.data[0] = 1 end
  if c == T.PLAYER_MOVE_FORWARD then player.data[0] = 0 end
  if c == T.FLYGON_ENTER then flygon.data[0] = 1 end
  if c == T.PLAYER_MOVE_BACKWARD then player.data[0] = 2 end
  if c == T.PLAYER_HOLD_POSITION then player.data[0] = 3 end
  if c == T.PLAYER_EXIT then player.data[0] = 4 end
  self.flygonYOffset = s16(Sin(band(rshift(d[3], 2), 0x7F), 48))
  if d[3] < 512 then d[3] = d[3] + 1 end
  Scenery.cycleSceneryPalette(m, 0)
end

-- pokeemerald/src/intro.c:1463
function Intro:scene2End(id)
  if self.counter > T.START_SCENE_3 then
    self.m.tasks:setFunc(id, function(i, dd) self:scene3Load(i, dd) end)
  end
end

-- pokeemerald/src/intro.c:1488
function Intro:volbeatCb(s, sp)
  local d = s.data
  d[3] = d[3] + 4
  local st = d[0]
  if st == 0 then
    d[1] = d[1] + 1
    if d[1] < 180 then return end
    d[0] = 1
    st = 1
  end
  if st == 1 then
    s.x = s.x - 4
    if s.x == 60 then d[0], d[1], d[2] = 8, 20, 2 end
  elseif st == 2 then
    s.x = s.x + 8
    s.y = s.y - 2
    if s.x == 124 then d[0], d[1], d[2] = 8, 20, 3 end
  elseif st == 3 then
    s.y = s.y + 4
    if s.y == 80 then d[0], d[1], d[2] = 8, 10, 4 end
  elseif st == 4 then
    s.x = s.x - 8
    s.y = s.y - 2
    if s.x == 60 then d[0], d[1], d[2] = 8, 10, 5 end
  elseif st == 5 or st == 6 then
    if st == 5 then
      s.x = s.x + 60
      d[4], d[5], d[6] = 0xC0, 0x80, 3
      d[0] = 6
    end
    s.x2 = Sin(u8(d[4]), 0x3C)
    s.y2 = Sin(u8(d[5]), 0x14)
    d[4] = s16(d[4] + 2)
    d[5] = s16(d[5] + 4)
    if band(d[4], 0xFF) == 64 then
      s.hFlip = false
      d[6] = d[6] - 1
      if d[6] == 0 then
        s.x = s.x + s.x2
        s.x2 = 0
        d[0] = d[0] + 1
      end
    end
  elseif st == 7 then
    s.x = s.x - 2
    s.y2 = Sin(u8(d[5]), 0x14)
    d[5] = s16(d[5] + 4)
    if s.x < -16 then sp:destroy(s) end
  elseif st == 8 then
    s.y2 = Cos(u8(d[3]), 2)
    d[1] = d[1] - 1
    if d[1] == 0 then d[0] = d[2] end
  end
end

-- pokeemerald/src/intro.c:1585
function Intro:torchicCb(s)
  local d = s.data
  local c = self.counter
  if d[0] == 0 then
    if c == T.TORCHIC_ENTER then
      Sprites.startAnim(s, 1)
      d[0] = 1
    end
  elseif d[0] == 1 then
    if c == T.PLAYER_HOLD_POSITION then
      Sprites.startAnim(s, 0)
      d[0] = 2
    else
      d[1] = d[1] + 64
      if band(d[1], 0xFF00) ~= 0 then
        s.x = s.x - 1
        d[1] = band(d[1], 0xFF)
      end
    end
  elseif d[0] == 2 then
    if c ~= T.TORCHIC_SPEED_UP then
      d[1] = d[1] + 32
      if band(d[1], 0xFF00) ~= 0 then
        s.x = s.x + 1
        d[1] = band(d[1], 0xFF)
      end
    else
      Sprites.startAnim(s, 1)
      d[0] = 3
      d[2] = 80
    end
  elseif d[0] == 3 then
    d[2] = d[2] - 1
    if d[2] ~= 0 then
      d[1] = d[1] + 64
      if band(d[1], 0xFF00) ~= 0 then
        s.x = s.x - 1
        d[1] = band(d[1], 0xFF)
      end
    else
      Sprites.startAnim(s, 2)
      d[0] = 4
    end
  elseif d[0] == 4 then
    if s.animEnded then s.x = s.x + 4 end
    if s.x > 336 then
      Sprites.startAnim(s, 1)
      d[0] = 5
    end
  elseif d[0] == 5 then
    if c >= T.TORCHIC_EXIT then s.x = s.x - 2 end
  end
end

-- pokeemerald/src/intro.c:1668
function Intro:manectricCb(s, sp)
  local d = s.data
  local st = d[0]
  if st == 0 then
    if self.counter == T.MANECTRIC_ENTER then d[0] = 1 end
    return
  end
  if st == 1 then
    s.x = s.x - 2
    if self.counter ~= T.MANECTRIC_RUN_CIRCULAR then return end
    s.y = s.y - 12
    d[1] = 0x80
    d[2] = 0
    d[0] = 2
  end
  if s.x + s.x2 <= -32 then
    sp:destroy(s)
  else
    if band(d[1], 0xFF) < 64 then
      s.x2 = Sin(u8(d[1]), 16)
    else
      if band(d[1], 0xFF) == 64 then s.x = s.x - 48 end
      s.x2 = Sin(u8(d[1]), 64)
    end
    d[1] = s16(d[1] + 1)
    s.y2 = Cos(u8(d[2]), 12)
    d[2] = s16(d[2] + 1)
  end
end

-- pokeemerald/src/intro.c:3075
function Intro:playerOnBicycleCb(s)
  local st = s.data[0]
  local c = self.counter
  if st == 0 then
    Sprites.startAnimIfDifferent(s, 0)
    s.x = s.x - 1
  elseif st == 1 then
    Sprites.startAnimIfDifferent(s, 0)
    if band(c, 7) ~= 0 then return end
    s.x = s.x + 1
  elseif st == 2 then
    if s.x <= 120 or band(c, 7) ~= 0 then s.x = s.x + 1 end
  elseif st == 4 then
    if s.x > -32 then s.x = s.x - 2 end
  end
  if band(c, 7) ~= 0 then return end
  if s.y2 ~= 0 then
    s.y2 = 0
  else
    local r = band(require("src.core.game3.rng").Random(), 3)
    if r == 0 then s.y2 = -1 elseif r == 1 then s.y2 = 1 else s.y2 = 0 end
  end
end

-- pokeemerald/src/intro.c:3138
function Intro:flygonCb(s)
  local d = s.data
  if d[0] == 1 then
    if s.x2 + s.x < 240 + 64 then s.x2 = s.x2 + 8 else d[0] = 2 end
  elseif d[0] == 2 then
    if s.x2 + s.x > 120 then s.x2 = s.x2 - 1 else d[0] = 3 end
  elseif d[0] == 3 then
    if s.x2 > 0 then s.x2 = s.x2 - 2 end
  end
  s.y2 = Sin(u8(d[1]), 8) - self.flygonYOffset
  d[1] = s16(d[1] + 4)
end

function Intro:createGameFreakLogoSprites(x, y)
  local sp = self.m.ppu.sprites
  local letters = self.man.tables.gameFreakLetters
  local delays = self.man.tables.gameFreakLetterStartDelay
  local affine = self.extra.gfAffineAnims
  local i = 0
  for n, row in ipairs(letters) do
    i = n - 1
    local id = sp:create(template(self, "gf_letter", PALTAG_LOGO, function(s, spr) self:logoLetterCb(s, spr) end,
      { affineAnims = affine }), row[2] + x, y - 4, 0)
    local s = sp:get(id)
    s.data[0] = 0
    s.data[1] = delays[n]
    s.data[2] = i
    s.invisible = true
    s.oam.matrixNum = i + 12
    Sprites.startAnim(s, row[1])
    sp:startAffineAnim(s, 0)
  end
  i = #letters
  local id = sp:create(template(self, "gf_logo", PALTAG_LOGO, function(s, spr) self:gameFreakLogoCb(s, spr) end,
    { affineAnims = affine }), 120, y - 6, 0)
  local s = sp:get(id)
  s.data[0] = 0
  s.invisible = true
  s.oam.matrixNum = i + 12
  sp:startAffineAnim(s, 1)
  return id
end

local function copyFade(self, t)
  local fade, faded = self.man.gameFreakTextFade, self.m.ppu.palette.faded
  faded[256 + 16 + 15] = fade[t + 1]
  faded[256 + 16 + 4] = fade[t + 16 + 1]
  faded[256 + 16 + 10] = fade[t + 32 + 1]
end

-- pokeemerald/src/intro.c:3176
function Intro:logoLetterCb(s, sp)
  local d = s.data
  local st = d[0]
  if st == 0 then
    if d[1] ~= 0 then
      d[1] = d[1] - 1
    else
      s.invisible = false
      sp:startAffineAnim(s, 1)
      d[0] = 1
    end
  elseif st == 1 then
    if self.counter == T.LOGO_LETTERS_COLOR then
      d[0] = 2
      d[1] = 9
      d[3] = 2
    end
  elseif st == 2 then
    if d[3] == 0 then
      d[3] = 2
      if d[1] ~= 0 then
        copyFade(self, d[1])
        d[1] = d[1] - 1
      else
        copyFade(self, d[1])
        d[0] = 3
      end
    else
      d[3] = d[3] - 1
    end
  elseif st == 3 then
    if d[3] ~= 0 then
      d[3] = d[3] - 1
    else
      d[3] = 2
      if d[1] <= 9 then
        copyFade(self, d[1])
        d[1] = d[1] + 1
      else
        d[0] = 4
      end
    end
  elseif st == 4 then
    if self.counter == T.LOGO_DISAPPEAR then
      sp:startAffineAnim(s, 2)
      s.oam.objMode = Sprites.OBJ_BLEND
      d[0] = 5
    end
  elseif st == 5 then
    d[3] = s16(d[3] + self.man.tables.gameFreakLetterMoveSpeed[d[2] + 1])
    s.x2 = rshift(band(d[3], 0xFF00), 8)
    if d[2] < 4 then s.x2 = -s.x2 end
    if s.affineAnimEnded then sp:destroy(s) end
  end
end

-- pokeemerald/src/intro.c:3274
function Intro:gameFreakLogoCb(s, sp)
  local d = s.data
  if d[0] == 0 then
    if self.counter == T.LOGO_APPEAR then
      s.invisible = false
      d[0] = 1
    end
  elseif d[0] == 1 then
    if self.counter == T.LOGO_DISAPPEAR then
      sp:startAffineAnim(s, 3)
      d[0] = 2
    end
  elseif d[0] == 2 then
    if s.affineAnimEnded then sp:destroy(s) end
  end
end

-- pokeemerald/src/intro.c:2717
function Intro:blendLogoIn(id, d)
  local ppu = self.m.ppu
  if d[0] == 1 then
    if d[1] ~= 0 then
      d[1] = d[1] - 1
      ppu:set("BLDALPHA", self:alphaReg(math.floor(d[1] / 2)))
    else
      ppu:set("BLDALPHA", self:alphaReg(0))
      d[1] = math.floor(#self.alpha / 4)
      d[0] = 2
    end
  elseif d[0] == 2 then
    ppu:set("BLDCNT", 0)
    ppu:set("BLDALPHA", 0)
    ppu:set("BLDY", 0)
    self.m.tasks:destroy(id)
  else
    ppu:set("BLDCNT", bor(Ppu.BLDCNT_EFFECT_BLEND, Ppu.BLDCNT_TGT2_BG0, Ppu.BLDCNT_TGT2_BG1, Ppu.BLDCNT_TGT2_BG2,
      Ppu.BLDCNT_TGT2_BG3, Ppu.BLDCNT_TGT2_OBJ, Ppu.BLDCNT_TGT2_BD))
    ppu:set("BLDALPHA", self:alphaReg(31))
    ppu:set("BLDY", 0)
    d[1] = #self.alpha
    d[0] = d[0] + 1
  end
end

-- pokeemerald/src/intro.c:2760
function Intro:blendLogoOut(id, d)
  local ppu = self.m.ppu
  if d[0] == 1 then
    if d[1] < #self.alpha - 2 then
      d[1] = d[1] + 1
      ppu:set("BLDALPHA", self:alphaReg(math.floor(d[1] / 2)))
    else
      ppu:set("BLDALPHA", self:alphaReg(31))
      d[1] = math.floor(#self.alpha / 4)
      d[0] = 2
    end
  elseif d[0] == 2 then
    if d[1] ~= 0 then
      d[1] = d[1] - 1
    else
      ppu:set("BLDCNT", 0)
      ppu:set("BLDALPHA", 0)
      ppu:set("BLDY", 0)
      self.m.tasks:destroy(id)
    end
  else
    ppu:set("BLDCNT", bor(Ppu.BLDCNT_EFFECT_BLEND, Ppu.BLDCNT_TGT2_BG0, Ppu.BLDCNT_TGT2_BG1, Ppu.BLDCNT_TGT2_BG2,
      Ppu.BLDCNT_TGT2_BG3, Ppu.BLDCNT_TGT2_OBJ, Ppu.BLDCNT_TGT2_BD))
    ppu:set("BLDALPHA", self:alphaReg(0))
    ppu:set("BLDY", 0)
    d[1] = 0
    d[0] = d[0] + 1
  end
end

function Intro:dropRipple(s)
  local e = self.extra.waterDropRipple
  s.sheet = Ppu.indexSheet(e.png, e.w, e.h)
  s.anims = self.rippleAnims
end

local function toRipple(self, s)
  s.invisible = true
  s.x = s.x + s.x2
  s.y = s.y + s.y2
  self:dropRipple(s)
  Sprites.startAnim(s, 3)
  s.data[2] = 1024
  s.data[3] = 8 * band(s.data[1], 3)
  s.callback = function(ss, sp) self:dropRippleCb(ss, sp) end
  Sprites.setShape(s, 64, 32)
  Sprites.calcCenterToCornerVec(s, s.oam.shape, s.oam.size, Sprites.AFFINE_ERASE)
end

-- pokeemerald/src/intro.c:2833
function Intro:dropRippleCb(s, sp)
  local d = s.data
  if d[2] >= 192 then
    if d[3] ~= 0 then
      d[3] = d[3] - 1
    else
      s.invisible = false
      sp:setMatrix(d[1], d[2], 0, 0, d[2])
      d[2] = div(d[2] * 95, 100)
      local palNum = div(d[2] - 192, 128) + 9
      if palNum > 15 then palNum = 15 end
      s.oam.paletteNum = palNum
    end
  else
    sp:destroy(s)
  end
end

-- pokeemerald/src/intro.c:2860
function Intro:dropHalfCb(s, sp)
  local parent = sp:get(s.data[7])
  if parent.data[7] ~= 0 then
    toRipple(self, s)
  else
    s.x2, s.y2, s.x, s.y = parent.x2, parent.y2, parent.x, parent.y
  end
end

-- pokeemerald/src/intro.c:2891
function Intro:dropSlideCb(s)
  local d = s.data
  if s.x <= 116 then
    s.y = s.y + s.y2
    s.y2 = 0
    s.x = s.x + 4
    s.x2 = -4
    d[4] = 128
    s.callback = function(ss) self:dropReachLeafEndCb(ss) end
    return
  end
  local sp = self.m.ppu.sprites
  local data4 = u16(d[4])
  local sin1 = sine(u8(data4))
  local sin2 = sine(u8(data4 + 64))
  d[4] = s16(d[4] + 2)
  s.y2 = div(sin1, 32)
  s.x = s.x - 1
  if band(s.x, 1) ~= 0 then s.y = s.y + 1 end
  local temp = s16(div(-sin2, 16))
  local data2, data3 = u16(d[2]), u16(d[3])
  local sin3 = sine(u8(temp - 16))
  local sin4 = sine(u8(temp + 48))
  local var1 = s16(div(sin4 * data2, 256))
  local var2 = s16(div(-sin3 * data3, 256))
  local var3 = s16(div(sin3 * data2, 256))
  local var4 = s16(div(sin4 * data3, 256))
  sp:setMatrix(d[1], data2, 0, 0, data3)
  sp:setMatrix(d[1] + 1, var1, var3, var2, var4)
  sp:setMatrix(d[1] + 2, var1, var3, var2 * 2, var4 * 2)
end

-- pokeemerald/src/intro.c:2940
function Intro:dropReachLeafEndCb(s)
  local d = s.data
  local sp = self.m.ppu.sprites
  sp:setMatrix(d[1], d[6] + 64, 0, 0, d[6] + 64)
  sp:setMatrix(d[1] + 1, d[6] + 64, 0, 0, d[6] + 64)
  sp:setMatrix(d[1] + 2, d[6] + 64, 0, 0, d[6] + 64)
  if d[4] ~= Sprites.MAX then
    d[4] = s16(d[4] - 8)
    local sinIdx = u16(d[4])
    s.x2 = div(sine(u8(sinIdx + 64)), 64)
    s.y2 = div(sine(u8(sinIdx)), 64)
  else
    d[4] = 0
    s.callback = function(ss) self:dropDangleCb(ss) end
  end
end

-- pokeemerald/src/intro.c:2960
function Intro:dropDangleCb(s)
  local d = s.data
  if d[0] ~= 2 then
    d[4] = s16(d[4] + 8)
    local r2 = s16(div(sine(u8(d[4])), 16) + 64)
    s.x2 = div(sine(u8(r2 + 64)), 64)
    s.y2 = div(sine(u8(r2)), 64)
  else
    s.callback = function(ss) self:dropFallCb(ss) end
  end
end

-- pokeemerald/src/intro.c:2977
function Intro:dropFallCb(s)
  if s.y < s.data[5] then
    s.y = s.y + 4
  else
    s.data[7] = 1
    toRipple(self, s)
  end
end

-- pokeemerald/src/intro.c:3023
function Intro:createWaterDrop(x, y, c, d, e, fallImmediately)
  local sp = self.m.ppu.sprites
  if not self.rippleAnims then
    local anims = {}
    for i, a in ipairs(self:sprite("water_drop").anims) do
      local list = {}
      for j, cmd in ipairs(a) do
        local row = {}
        for k, v in pairs(cmd) do row[k] = v end
        if i == 4 and row.op == "frame" then row.frame = 0 end
        list[j] = row
      end
      anims[i] = list
    end
    self.rippleAnims = anims
  end
  local function make(cb)
    local id = sp:create(template(self, "water_drop", PALTAG_DROPS, cb), x, y, 1)
    return id, sp:get(id)
  end
  local oldId, s = make(nil)
  s.data[0], s.data[7], s.data[1], s.data[2], s.data[3], s.data[5], s.data[6] = 0, 0, d, c, c, e, c
  s.oam.affineMode = Sprites.AFFINE_DOUBLE
  s.oam.matrixNum = d
  Sprites.calcCenterToCornerVec(s, 0, 2, Sprites.AFFINE_ERASE)
  Sprites.startAnim(s, 2)
  if not fallImmediately then
    s.callback = function(ss)
      if ss.data[0] ~= 0 then ss.callback = function(s2) self:dropSlideCb(s2) end end
    end
  else
    s.callback = function(ss) self:dropFallCb(ss) end
  end
  local _, up = make(function(ss, spr) self:dropHalfCb(ss, spr) end)
  up.data[7] = oldId
  up.data[1] = d + 1
  up.oam.affineMode = Sprites.AFFINE_DOUBLE
  up.oam.matrixNum = d + 1
  Sprites.calcCenterToCornerVec(up, 0, 2, Sprites.AFFINE_ERASE)
  local _, low = make(function(ss, spr) self:dropHalfCb(ss, spr) end)
  low.data[7] = oldId
  low.data[1] = d + 2
  Sprites.startAnim(low, 1)
  low.oam.affineMode = Sprites.AFFINE_DOUBLE
  low.oam.matrixNum = d + 2
  Sprites.calcCenterToCornerVec(low, 0, 2, Sprites.AFFINE_ERASE)
  sp:setMatrix(d, c + 32, 0, 0, c + 32)
  sp:setMatrix(d + 1, c + 32, 0, 0, c + 32)
  sp:setMatrix(d + 2, c + 32, 0, 0, 2 * (c + 32))
  return oldId
end

-- pokeemerald/src/intro.c:3339
function Intro:flygonSilhouetteCb(s)
  local d = s.data
  local sp = self.m.ppu.sprites
  d[7] = d[7] + 1
  if d[0] ~= 0 then
    local sn = sine(u8(d[2]))
    local cs = sine(u8(d[2] + 64))
    local dd = s16(div(cs * d[1], 256))
    local c = s16(div(-sn * d[1], 256))
    local b = s16(div(sn * d[1], 256))
    local a = s16(div(cs * d[1], 256))
    sp:setMatrix(1, a, b, c, dd)
  end
  if d[0] == 1 then
    s.x2 = -Sin(u8(d[3]), 140)
    s.y2 = -Sin(u8(d[3]), 120)
    d[1] = d[1] + 7
    d[3] = d[3] + 3
    if s.x + s.x2 <= -16 then
      s.oam.priority = 3
      d[0] = 2
      s.x, s.y = 20, 40
      d[1], d[2], d[3] = 512, 0, 16
    end
  elseif d[0] == 2 then
    s.x2 = Sin(u8(d[3]), 34)
    s.y2 = -Cos(u8(d[3]), 60)
    d[1] = d[1] + 2
    if d[7] % 5 == 0 then d[3] = d[3] + 1 end
  else
    s.oam.affineMode = Sprites.AFFINE_DOUBLE
    s.oam.matrixNum = 1
    Sprites.calcCenterToCornerVec(s, 1, 3, Sprites.AFFINE_DOUBLE)
    s.invisible = false
    d[0] = 1
    d[1], d[2], d[3] = 128, 0, 0
  end
end

function Intro:panFade(x, y, zoom, alpha)
  self.m.ppu:setAffine(2, Affine.panFadeAndZoom(u16(x), u16(y), u16(zoom), u16(alpha)))
end

-- pokeemerald/src/intro.c:1721
function Intro:scene3Load(id, d)
  local m, ppu = self.m, self.m.ppu
  self:resetGpuRegs()
  self:clearVram()
  local ballPal = self:pal("sIntroPokeball_Pal")
  ppu.palette:load(ballPal, 0, #ballPal)
  d[0], d[1], d[2], d[3] = 0, 0, 0, 0
  self:panFade(120, 80, 0, 0)
  ppu.sprites:resetData()
  ppu.sprites:freeAllPalettes()
  ppu.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
  ppu:setBg(2, 3, self:layer("scene3_pokeball"), false)
  ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON))
  m.tasks:setFunc(id, function(i, dd) self:scene3SpinPokeball(i, dd) end)
  m:addStall(Intro.STALL.scene3Load)
  self.counter = 0
  self.scene = "scene3"
  audio().playSong(songId("MUS_INTRO_BATTLE"), { restart = true })
  self:mark("scene3 MUS_INTRO_BATTLE")
end

-- pokeemerald/src/intro.c:1741
function Intro:scene3SpinPokeball(id, d)
  d[0] = s16(d[0] + 0x400)
  if d[1] <= 0x6BF then
    d[1] = s16(d[1] + d[2])
    d[2] = s16(d[2] + 2)
  else
    self.m.tasks:setFunc(id, function(i, dd) self:scene3WaitGroudon(i, dd) end)
  end
  local zoom = d[1] ~= 0 and div(0x10000, d[1]) or 0
  self:panFade(120, 80, zoom, d[0])
  if self.counter == T.POKEBALL_FADE then
    self.m.ppu.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA)
  end
end

-- pokeemerald/src/intro.c:1765
function Intro:scene3WaitGroudon(id)
  if self.counter > T.START_LEGENDARIES then
    self.m.tasks:setFunc(id, function(i, dd) self:scene3LoadGroudon(i, dd) end)
  end
end

-- pokeemerald/src/intro.c:1771
function Intro:scene3LoadGroudon(id)
  local m, ppu = self.m, self.m.ppu
  if ppu.palette:fadeActive() then return end
  self:resetGpuRegs()
  ppu.sprites:resetData()
  ppu.sprites:freeAllPalettes()
  ppu.sprites:setReservedPalettes(8)
  local rocks = self.extra.groudonRocks
  ppu.sprites:loadPalette(rocks.tileTag, self.extra.palettes.rocks)
  ppu.palette:loadUnfaded(self:pal("gIntro3Bg_Pal"), 0, 256)
  m.tasks:setFunc(id, function(i, dd) self:scene3InitGroudonBg(i, dd) end)
  m:addStall(Intro.STALL.loadGroudon)
end

-- pokeemerald/src/intro.c:1795
function Intro:scene3InitGroudonBg(id, d)
  local m, ppu = self.m, self.m.ppu
  ppu:set("WIN0H", 240)
  ppu:set("WIN0V", 160)
  ppu:set("WININ", Ppu.WININ_WIN0_ALL)
  ppu:set("WINOUT", 0)
  ppu:setBg(2, 0, self:layer("scene3_groudon"), true)
  ppu:setBg(1, 1, self:layer("scene3_groudon_bg"))
  ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG1_ON, Ppu.DISPCNT_BG2_ON,
    Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_WIN0_ON))
  ppu.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
  d[0], d[1], d[2], d[3] = 0, s16(0xFFA0), s16(0xFF51), 0x100
  self:panFade(d[1], d[2], d[3], 0)
  m.tasks:setFunc(id, function(i, dd) self:scene3NarrowWindow(i, dd) end)
end

-- pokeemerald/src/intro.c:1830
function Intro:scene3NarrowWindow(id, d)
  local ppu = self.m.ppu
  if d[0] ~= 32 then
    d[0] = d[0] + 4
    ppu:set("WIN0V", u16(d[0] * 256 - (d[0] - 160)))
  else
    ppu:set("WIN0V", Ppu.winRange(32, 160 - 32))
    self.m.tasks:setFunc(id, function(i, dd) self:scene3EndNarrowWindow(i, dd) end)
  end
end

-- pokeemerald/src/intro.c:1848
function Intro:scene3EndNarrowWindow(id)
  self.m.tasks:setFunc(id, function(i, dd) self:scene3StartGroudon(i, dd) end)
end

-- pokeemerald/src/intro.c:1853
function Intro:scene3StartGroudon(id, d)
  local m = self.m
  d[0] = 0
  m.tasks:setFunc(id, function(i, dd) self:scene3Groudon(i, dd) end)
  self:initWave("BG1HOFS")
end

function Intro:initWave(dest)
  local m = self.m
  local w = m.ppu.scanline:initWave(0, 160, 4, 4, 1, dest, nil)
  m.tasks:create(function(i) if not m.ppu.scanline:runWaveTask(w) then m.tasks:destroy(i) end end, 0)
end

local function raw3(self, palIdx)
  return self:pal("gIntro3Bg_Pal")[palIdx / 2 + 1]
end

-- pokeemerald/src/intro.c:1872
function Intro:scene3Groudon(id, d)
  local ppu = self.m.ppu
  local faded = ppu.palette.faded
  d[5] = d[5] + 1
  if d[0] >= 1 and d[0] <= 7 and d[5] % 2 == 0 then d[4] = bxor(d[4], 3) end
  self:panFade(d[1], d[2] + d[4], d[3], 0)
  local st = d[0]
  if st == 0 then
    d[1] = s16(d[1] + 16)
    if d[1] == 160 then
      d[0] = 1
      d[6] = 2
      d[7] = 0x1E2
      self:createGroudonRockSprites(id)
    end
  elseif st == 1 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6] = 2
      faded[16 + 15] = raw3(self, d[7])
      d[7] = d[7] + 2
      if d[7] == 0x1EC then d[0] = 2 end
    end
  elseif st == 2 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6] = 2
      d[0] = 3
    end
  elseif st == 3 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6] = 2
      faded[16 + 15] = raw3(self, d[7])
      d[7] = d[7] - 2
      if d[7] == 0x1E0 then
        d[6] = 8
        d[0] = 4
      end
    end
  elseif st == 4 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[1], d[2], d[6] = -96, 169, 3
      d[0] = 5
    end
  elseif st == 5 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[1], d[2], d[6] = 80, 41, 16
      audio().playCry(speciesId("SPECIES_GROUDON"), { mode = 0, volume = 100, pan = 0 })
      self:mark("cry GROUDON")
      d[0] = 6
    end
  elseif st == 6 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[1], d[2] = 80, 40
      d[0] = 7
    end
  elseif st == 7 then
    d[1] = d[1] + 4
    d[2] = d[2] + 4
    d[6] = s16(d[6] + 0x666)
    d[3] = Sin(rshift(band(d[6], 0xFF00), 8), 64) + 256
    if d[1] == 120 then
      ppu.palette:beginFade(band(Palette.ALL, bit.bnot(1)), 3, 0, 16, Palette.WHITE)
      d[3] = 256
      d[4] = 0
      d[0] = 8
    end
  elseif st == 8 then
    if d[3] ~= 0 then d[3] = d[3] - 8 else d[0] = 9 end
  elseif st == 9 then
    if not ppu.palette:fadeActive() then
      self.m.tasks:setFunc(id, function(i, dd) self:scene3LoadKyogre(i, dd) end)
      ppu.scanline.state = 3
    end
  end
end

-- pokeemerald/src/intro.c:1992
function Intro:createGroudonRockSprites(taskId)
  local sp = self.m.ppu.sprites
  local rocks = self.extra.groudonRocks
  for i, row in ipairs(self.man.tables.groudonRocks) do
    local t = Machine.template(rocks, { paletteTag = rocks.tileTag, callback = function(s) self:groudonRockCb(s) end })
    local id = sp:create(t, row[1], 160, i - 1)
    local s = sp:get(id)
    s.oam.priority = 0
    s.data[1] = i - 1
    s.data[4] = taskId
    Sprites.startAnim(s, row[2])
  end
end

-- pokeemerald/src/intro.c:2008
function Intro:groudonRockCb(s)
  local d = s.data
  d[3] = d[3] + 1
  if d[3] % 2 == 0 then s.y2 = bxor(s.y2, 3) end
  if d[0] == 0 then
    d[2] = d[2] + self.man.tables.groudonRocks[d[1] + 1][3]
    s.y = s.y - rshift(band(d[2], 0xFF00), 8)
    d[2] = band(d[2], 0xFF)
    if self.m.tasks:get(d[4]).data[0] > 7 then d[0] = 1 end
  elseif d[0] == 1 then
    if s.x < 120 then s.x = s.x - 2 else s.x = s.x + 2 end
    if s.y < 80 then s.y = s.y - 2 else s.y = s.y + 2 end
  end
end

-- pokeemerald/src/intro.c:2054
function Intro:scene3LoadKyogre(id, d)
  local m, ppu = self.m, self.m.ppu
  ppu.sprites:resetData()
  ppu:setBg(2, 0, self:layer("scene3_kyogre"), true)
  ppu:setBg(1, 1, self:layer("scene3_kyogre_bg"))
  ppu.sprites:loadPalette(TAG_BUBBLES, self:pal("gIntroBubbles_Pal"))
  ppu.palette:beginFade(band(Palette.ALL, bit.bnot(1)), 0, 16, 0, Palette.WHITEALPHA)
  m.tasks:setFunc(id, function(i, dd) self:scene3Kyogre(i, dd) end)
  d[0], d[1], d[2], d[6], d[3] = 0, 336, 80, 16, 256
  self:panFade(d[1], d[2], d[3], 0)
  self:initWave("BG1VOFS")
  m:addStall(Intro.STALL.loadKyogre)
end

-- pokeemerald/src/intro.c:2073
function Intro:scene3Kyogre(id, d)
  local ppu = self.m.ppu
  local faded = ppu.palette.faded
  self:panFade(d[1], d[2], d[3], 0)
  local st = d[0]
  if st == 0 then
    d[6] = d[6] - 1
    if d[6] ~= 0 then return end
    d[0] = 1
    st = 1
  end
  if st == 1 then
    d[6] = d[6] + 4
    d[1] = 344 - Sin(d[6], 0x100)
    d[2] = 84 - Cos(d[6], 0x40)
    if d[6] == 64 then
      d[6], d[7] = 0x19, 1
      d[0] = 2
      self:createKyogreBubblesBody(0)
    end
  elseif st == 2 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[1] = d[1] + 256
      d[2] = d[2] - 258
      d[6] = 8
      d[0] = 3
      self:createKyogreBubblesBody(0)
      self:createKyogreBubblesFins()
    end
  elseif st == 3 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[1] = d[1] - 256
      d[2] = d[2] + 258
      d[6] = 8
      d[0] = 4
    end
  elseif st == 4 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[2] = d[2] - 252
      d[6] = 8
      d[0] = 5
    end
  elseif st == 5 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[2] = d[2] + 252
      if d[7] ~= 0 then
        d[6] = 12
        d[7] = d[7] - 1
        d[0] = 2
      else
        d[6] = 1
        d[0] = 6
        audio().playCry(speciesId("SPECIES_KYOGRE"), { mode = 0, volume = 120, pan = 0 })
        self:mark("cry KYOGRE")
      end
    end
  elseif st == 6 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6], d[7] = 4, 0x1EA
      d[0] = 7
    end
  elseif st == 7 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6] = 4
      faded[32 + 15] = raw3(self, d[7])
      d[7] = d[7] - 2
      if d[7] == 0x1E0 then d[0] = 8 end
    end
  elseif st == 8 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6], d[7] = 4, 0x1E2
      d[0] = 9
    end
  elseif st == 9 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6] = 4
      faded[32 + 15] = raw3(self, d[7])
      d[7] = d[7] + 2
      if d[7] == 0x1EE then
        d[6] = 16
        d[0] = 10
      end
    end
  elseif st == 10 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      d[6] = 0
      d[0] = 11
      self:createKyogreBubblesBody(id)
    end
  elseif st == 11 then
    d[6] = d[6] + 4
    d[3] = d[3] - 8
    d[1] = Sin(d[6], 0x3C) + 88
    if d[6] == 64 then
      ppu.palette:beginFade(band(Palette.ALL, bit.bnot(1)), 3, 0, 16, Palette.WHITE)
      d[0] = 12
    end
  elseif st == 12 then
    d[6] = d[6] + 4
    d[3] = d[3] - 8
    d[1] = Sin(d[6], 0x14) + 128
    if d[6] == 128 then d[0] = 13 end
  elseif st == 13 then
    if not ppu.palette:fadeActive() then
      self.m.tasks:setFunc(id, function(i, dd) self:scene3LoadClouds1(i, dd) end)
      ppu.scanline.state = 3
    end
  end
end

-- pokeemerald/src/intro.c:2238
function Intro:createKyogreBubblesBody(taskId)
  local sp = self.m.ppu.sprites
  local rows = self.man.tables.kyogreBubbles
  for i = 0, 5 do
    local row = rows[i + 1]
    local id = sp:create(template(self, "bubbles", TAG_BUBBLES, function(s, spr) self:kyogreBubbleCb(s, spr) end),
      row[1], row[2], i)
    local s = sp:get(id)
    s.invisible = true
    s.data[5] = taskId
    s.data[6] = row[3]
    s.data[7] = 64
  end
end

-- pokeemerald/src/intro.c:2257
function Intro:createKyogreBubblesFins()
  local sp = self.m.ppu.sprites
  local rows = self.man.tables.kyogreBubbles
  for i = 0, 5 do
    local row = rows[i + 6 + 1]
    local id = sp:create(template(self, "bubbles", TAG_BUBBLES, function(s, spr) self:kyogreBubbleCb(s, spr) end),
      row[1], row[2], i)
    local s = sp:get(id)
    s.invisible = true
    s.data[6] = rows[i + 1][3]
    s.data[7] = 64
  end
end

-- pokeemerald/src/intro.c:2278
function Intro:kyogreBubbleCb(s, sp)
  local d = s.data
  if d[0] == 0 then
    if d[6] == 0 then
      d[1] = band(d[1] + 11, 0xFF)
      s.x2 = Sin(d[1], 4)
      d[2] = s16(d[2] + 48)
      s.y2 = -bit.arshift(d[2], 8)
      if s.animEnded then
        sp:destroy(s)
        return
      end
    else
      d[6] = d[6] - 1
      if d[6] == 0 then
        Sprites.startAnim(s, 0)
        s.invisible = false
      end
    end
    if self.m.tasks:get(d[5]).data[0] > 11 then d[0] = d[0] + 1 end
  elseif d[0] == 1 then
    if s.x < 120 then s.x = s.x - 3 else s.x = s.x + 3 end
    if s.y < 80 then s.y = s.y - 3 else s.y = s.y + 3 end
    if u16(s.y - 20) > 160 - 20 then sp:destroy(s) end
  end
end

-- pokeemerald/src/intro.c:2329
function Intro:scene3LoadClouds1(id)
  local ppu = self.m.ppu
  ppu:set("BLDCNT", bor(Ppu.BLDCNT_TGT1_BG0, Ppu.BLDCNT_TGT1_BG1, Ppu.BLDCNT_TGT1_BG2, Ppu.BLDCNT_EFFECT_LIGHTEN))
  ppu:set("BLDALPHA", Ppu.blendAlpha(31, 31))
  ppu:set("BLDY", 31)
  ppu:setBg(0, 0, self:layer("scene3_clouds_left"))
  ppu:setBg(1, 0, nil)
  ppu:setBg(2, 2, self:layer("scene3_clouds_sun"))
  ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON, Ppu.DISPCNT_BG1_ON,
    Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_WIN0_ON))
  ppu:set("BG0HOFS", 80)
  ppu:set("BG0VOFS", 0)
  ppu:set("BG1HOFS", u16(-80))
  ppu:set("BG1VOFS", 0)
  ppu:set("BG2HOFS", 0)
  ppu:set("BG2VOFS", 0)
  self.m.tasks:setFunc(id, function(i, dd) self:scene3LoadClouds2(i, dd) end)
  self.m:addStall(Intro.STALL.loadClouds1)
end

-- pokeemerald/src/intro.c:2371
function Intro:scene3LoadClouds2(id)
  self.m.ppu:setBg(1, 0, self:layer("scene3_clouds_right"))
  self.m.tasks:setFunc(id, function(i, dd) self:scene3InitClouds(i, dd) end)
end

-- pokeemerald/src/intro.c:2380
function Intro:scene3InitClouds(id, d)
  local ppu = self.m.ppu
  ppu:set("BLDCNT", 0)
  ppu:set("BLDALPHA", 0)
  ppu:set("BLDY", 0)
  self.m.tasks:setFunc(id, function(i, dd) self:scene3Clouds(i, dd) end)
  d[0] = 0
  d[6] = 16
end

-- pokeemerald/src/intro.c:2391
function Intro:scene3Clouds(id, d)
  local ppu = self.m.ppu
  ppu:set("BG0HOFS", u16(bit.arshift(d[6], 8)))
  ppu:set("BG1HOFS", u16(-bit.arshift(d[6], 8)))
  if d[0] == 0 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      ppu.palette:beginFade(band(Palette.ALL, bit.bnot(1)), 0, 16, 0, Palette.WHITEALPHA)
      d[6] = s16(lshift(80, 8))
      d[0] = 1
    end
  elseif d[0] == 1 then
    if d[6] == s16(lshift(40, 8)) then
      ppu.palette:beginFade(band(Palette.BG, bit.bnot(1)), 3, 0, 16, Palette.rgb(9, 10, 10))
    end
    if d[6] ~= 0 then
      d[6] = s16(d[6] - 128)
    elseif not ppu.palette:fadeActive() then
      self.m.tasks:setFunc(id, function(i, dd) self:scene3LoadLightning(i, dd) end)
    end
  end
end

-- pokeemerald/src/intro.c:2430
function Intro:scene3LoadLightning(id, d)
  local ppu = self.m.ppu
  ppu:setBg(2, 2, self:layer("scene3_rayquaza"))
  ppu:setBg(0, 0, self:layer("scene3_rayquaza_clouds"))
  ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON, Ppu.DISPCNT_BG2_ON,
    Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_WIN0_ON))
  self.m.tasks:setFunc(id, function(i, dd) self:scene3Lightning(i, dd) end)
  d[0], d[6], d[7] = 0, 1, 0
  ppu.sprites:loadPalette(TAG_LIGHTNING, self:pal("gIntroLightning_Pal"))
  self.m:addStall(Intro.STALL.loadLightning)
end

function Intro:lightning(x, y, anim)
  local sp = self.m.ppu.sprites
  local id = sp:create(template(self, "lightning", TAG_LIGHTNING, function(s, spr) self:lightningCb(s, spr) end), x, y, anim)
  if anim > 0 then Sprites.startAnim(sp:get(id), anim) end
end

-- pokeemerald/src/intro.c:2450
function Intro:scene3Lightning(id, d)
  if d[0] == 0 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      self:lightning(200, 48, 0)
      self:lightning(200, 80, 1)
      self:lightning(200, 112, 2)
      d[0] = 1
      d[6] = 72
    end
  elseif d[0] == 1 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      self:lightning(40, 48, 0)
      self:lightning(40, 80, 1)
      self:lightning(40, 112, 2)
      d[0] = 2
      d[6] = 48
    end
  elseif d[0] == 2 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      self.m.tasks:setFunc(id, function(i, dd) self:scene3LoadRayquazaAttack(i, dd) end)
    end
  end
end

-- pokeemerald/src/intro.c:2493
function Intro:lightningCb(s, sp)
  local d = s.data
  local faded = self.m.ppu.palette.faded
  if s.animEnded then s.invisible = true end
  if d[0] == 0 then
    d[1] = 0x1C2
    d[0] = 1
  end
  if d[0] == 1 then
    faded[5 * 16 + 13] = raw3(self, d[1])
    d[1] = d[1] + 2
    if d[1] ~= 0x1CE then return end
    d[1] = 0x1CC
    d[2] = 4
    d[0] = 2
  end
  if d[0] == 2 then
    d[2] = d[2] - 1
    if d[2] == 0 then
      d[2] = 4
      faded[5 * 16 + 13] = raw3(self, d[1])
      d[1] = d[1] - 2
      if d[1] == 0x1C0 then sp:destroy(s) end
    end
  end
end

-- pokeemerald/src/intro.c:2529
function Intro:scene3LoadRayquazaAttack(id, d)
  local m, ppu = self.m, self.m.ppu
  ppu.sprites:loadPalette(TAG_RAYQUAZA_ORB, self:pal("sIntroRayquzaOrb_Pal"))
  ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON, Ppu.DISPCNT_BG2_ON,
    Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_WIN0_ON))
  m.tasks:setFunc(id, function(i, dd) self:scene3Rayquaza(i, dd) end)
  ppu.palette:beginFade(band(Palette.BG, bit.bnot(0x21)), 0, 16, 0, Palette.rgb(9, 10, 10))
  d[0], d[1], d[2], d[3], d[4] = 0, 0xA8, -0x10, -0x88, -0x10
  local attack = m.tasks:create(function(i, dd) self:rayquazaAttack(i, dd) end, 0)
  m.tasks:get(attack).data[4] = id
end

-- pokeemerald/src/intro.c:2552
function Intro:scene3Rayquaza(id, d)
  if d[7] % 2 == 0 then d[6] = bxor(d[6], 2) end
  d[7] = d[7] + 1
  local st = d[0]
  if st == 0 then
    if band(d[7], 1) ~= 0 then
      d[1] = d[1] - 2
      d[2] = d[2] + 1
      d[3] = d[3] + 2
      d[4] = d[4] + 1
    end
    if d[1] == 0x68 then
      d[0] = 1
      d[5] = 1
    end
  elseif st == 1 then
    d[0] = 2
    d[5] = 4
  elseif st == 2 then
    d[1] = d[1] + 4
    d[2] = d[2] - 2
    d[3] = d[3] - 4
    d[4] = d[4] - 2
    if not self.m.ppu.palette:fadeActive() then
      d[5] = 0x8C
      d[0] = 3
    end
  elseif st == 3 then
    d[5] = d[5] - 1
    if d[5] == 0 then
      self.m.tasks:setFunc(id, function(i) self:endIntroMovie(i) end)
    end
  end
end

-- pokeemerald/src/intro.c:2601
function Intro:endIntroMovie(id)
  self.m.tasks:destroy(id)
  self.m:setCb2(function() self:endCb() end)
end

-- pokeemerald/src/intro.c:2607
function Intro:rayquazaAttack(id, d)
  local ppu = self.m.ppu
  local faded = ppu.palette.faded
  d[2] = d[2] + 1
  local st = d[0]
  if st == 0 then
    if band(d[2], 1) ~= 0 then
      faded[5 * 16 + 14] = raw3(self, 0x1A2 + d[1] * 2)
      d[1] = d[1] + 1
    end
    if d[1] == 6 then
      d[0] = 1
      d[1] = 0
      d[3] = 10
    end
  elseif st == 1 then
    if d[3] == 0 then
      if band(d[2], 1) ~= 0 then
        faded[5 * 16 + 8] = raw3(self, 0x1A2 + d[1] * 2)
        d[1] = d[1] + 1
      end
      if d[1] == 6 then
        d[0] = 2
        d[3] = 10
      end
    else
      d[3] = d[3] - 1
    end
  elseif st == 2 then
    if d[3] == 0 then
      if band(d[2], 1) ~= 0 then
        faded[5 * 16 + 12] = raw3(self, 0x182 + d[1] * 2)
        d[1] = d[1] + 1
      end
      if d[1] == 6 then
        local sp = ppu.sprites
        local sid = sp:create(template(self, "rayquaza_orb", TAG_RAYQUAZA_ORB, function(s) self:rayquazaOrbCb(s) end), 120, 88, 15)
        audio().playSe(songId("SE_INTRO_BLAST"))
        self:mark("SE_INTRO_BLAST")
        sp:get(sid).invisible = true
        sp:get(sid).data[3] = d[4]
        d[0] = 3
        d[3] = 16
      end
    else
      d[3] = d[3] - 1
    end
  elseif st == 3 then
    if band(d[2], 1) ~= 0 then
      d[3] = d[3] - 1
      if d[3] ~= 0 then
        ppu.palette:blend(5 * 16, 16, d[3], Palette.rgb(9, 10, 10))
        faded[5 * 16 + 14] = raw3(self, 428)
        faded[5 * 16 + 8] = raw3(self, 428)
        faded[5 * 16 + 12] = raw3(self, 396)
      else
        d[0] = 4
        d[3] = 53
      end
    end
  elseif st == 4 then
    d[3] = d[3] - 1
    if d[3] == 0 then
      ppu.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITE)
      d[0] = 5
    end
  elseif st == 5 then
    if not ppu.palette:fadeActive() then self.m.tasks:destroy(id) end
  end
end

-- pokeemerald/src/intro.c:3405
function Intro:rayquazaOrbCb(s)
  local d = s.data
  local sp = self.m.ppu.sprites
  if d[0] ~= 1 then
    s.invisible = false
    s.oam.affineMode = Sprites.AFFINE_DOUBLE
    s.oam.matrixNum = 18
    Sprites.calcCenterToCornerVec(s, 0, 3, Sprites.AFFINE_DOUBLE)
    d[1] = 0
    d[0] = 1
  end
  d[7] = d[7] + 1
  if band(d[7], 1) ~= 0 then
    s.invisible = true
  else
    s.invisible = false
    if d[1] < 64 then d[1] = d[1] + 1 end
  end
  local foo = u16(256 - div(sine(u8(d[1])), 2))
  sp:setMatrix(18, foo, 0, 0, foo)
end

return Intro
