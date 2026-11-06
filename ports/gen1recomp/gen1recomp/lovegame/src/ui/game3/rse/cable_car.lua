local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local TileLayer = require("src.ui.game3.rse.tile_layer")
local OwSheet = require("src.ui.game3.rse.ow_sheet")
local CacheBlob = require("src.import.CacheBlob")

local band = bit.band

local CableCar = {}
CableCar.__index = CableCar

CableCar.MANIFEST = "data/generated/gba/cable_car/manifest.lua"

-- pokeemerald/src/cable_car.c:28
local STATE_END = 0xFF
-- pokeemerald/src/cable_car.c:31
local TAG_CABLE_CAR = 1
-- pokeemerald/include/field_weather.h:18
local PALTAG_WEATHER, PALTAG_WEATHER_2 = 0x1200, 0x1201
-- pokeemerald/include/constants/weather.h:4
local WEATHER_NONE, WEATHER_SUNNY, WEATHER_VOLCANIC_ASH = 0, 2, 7
-- pokeemerald/include/constants/field_weather.h:7
local NUM_ASH_SPRITES = 20
-- pokeemerald/include/gba/io_reg.h:610
local BLDCNT_TGT2_ALL = 0x3F00
local DISPLAY_WIDTH, DISPLAY_HEIGHT = 240, 160

CableCar.STALL = {
  -- pokeemerald/src/field_weather_effect.c:1657
  createAshSprites = 1,
}

-- pokeemerald/src/cable_car.c:586
local F_014, F_0067 = 0.14000000059604645, 0.06700000166893005

-- pokeemerald/src/data/object_events/object_event_anims.h:178
local ANIMS_STANDARD = {
  [1] = { { op = "frame", frame = 0, duration = 16 }, { op = "jump", target = 0 } },
  [7] = {
    { op = "frame", frame = 7, duration = 8 }, { op = "frame", frame = 2, duration = 8 },
    { op = "frame", frame = 8, duration = 8 }, { op = "frame", frame = 2, duration = 8 }, { op = "jump", target = 0 },
  },
  [8] = {
    { op = "frame", frame = 7, duration = 8, hFlip = true }, { op = "frame", frame = 2, duration = 8, hFlip = true },
    { op = "frame", frame = 8, duration = 8, hFlip = true }, { op = "frame", frame = 2, duration = 8, hFlip = true },
    { op = "jump", target = 0 },
  },
}
-- pokeemerald/include/constants/event_object_movement.h:255
local ANIM_STD_GO_WEST, ANIM_STD_GO_EAST = 6, 7

-- pokeemerald/src/field_weather_effect.c:1629
local ASH_ANIMS = { { { op = "frame", frame = 0, duration = 60 }, { op = "frame", frame = 1, duration = 60 },
  { op = "jump", target = 0 } } }

local function u8(v) return v % 256 end

local function s16(v)
  v = v % 65536
  if v >= 32768 then v = v - 65536 end
  return v
end

local function audio()
  return require("src.core.game3.audio")
end

local function song(name)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get()):require("songs", name)
end

local function gfxId(name)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get()):require("event_objects", name)
end

function CableCar.new(opts)
  opts = opts or {}
  local self = setmetatable({}, CableCar)
  self.m = Machine.new()
  self.man = self.m:manifest(CableCar.MANIFEST)
  if opts.requireAssetLayout then
    assert(self.man.assetLayout == opts.requireAssetLayout, "cable_car: incorrect native asset layout")
  end
  self.playerGfxNames, self.hikerGfxNames = opts.playerGfxNames, opts.hikerGfxNames
  self.goingDown = opts.goingDown and true or false
  self.female = opts.female and true or false
  self.random = opts.random or function() return require("src.core.game3.rng").Random() end
  self.onDone = opts.onDone
  self.done = false
  self.frames = 0
  self.log = {}
  self.m:setCb2(function() self:loadCb() end)
  return self
end

function CableCar:mark(what)
  self.log[#self.log + 1] = { frame = self.frames, what = what }
end

local function blendReg(eva, evb)
  return band(eva, 0xFF) + band(evb, 0xFF) * 256
end

function CableCar:template(key, extra)
  local t = Machine.template(assert(self.man.sprites[key], "cable_car: sprite " .. key .. " missing"), extra)
  return t
end

function CableCar:owTemplate(graphicsId, callback)
  local ow = OwSheet.build(graphicsId)
  local sp = self.m.ppu.sprites
  sp:loadPalette(ow.paletteTag, ow.palette)
  return {
    w = ow.w, h = ow.h, bpp = 4, anims = ANIMS_STANDARD, priority = 0,
    sheet = ow.sheet, paletteTag = ow.paletteTag, callback = callback,
  }
end

-- pokeemerald/src/sprite.c:513
function CableCar:createAtEnd(template, x, y, subpriority)
  local sp = self.m.ppu.sprites
  for i = Sprites.MAX - 1, 0, -1 do
    if not sp.sprites[i].inUse then return sp:createAt(i, template, x, y, subpriority) end
  end
  return Sprites.MAX
end

-- pokeemerald/src/field_weather.c:154
function CableCar:startWeather()
  local sp = self.m.ppu.sprites
  local idx = sp:indexOfPaletteTag(Sprites.TAG_NONE)
  sp.paletteTags[idx] = PALTAG_WEATHER
  self.m.ppu.palette:loadUnfaded(self.man.palettes.fog, 256 + idx * 16, 16)
  local idx2 = sp:indexOfPaletteTag(Sprites.TAG_NONE)
  sp.paletteTags[idx2] = PALTAG_WEATHER_2
  self.w = {
    currWeather = WEATHER_NONE, nextWeather = WEATHER_NONE, readyForInit = false, initialized = false,
    weatherChangeComplete = true, ashSpritesCreated = false, ash = {}, ashBaseSpritesX = 0,
    initStep = 0, finishStep = 0, weatherGfxLoaded = false,
  }
  self:setBlendCoeffs(16, 0)
  self.m.tasks:create(function() self:weatherTask() end, 80)
end

-- pokeemerald/src/field_weather.c:939
function CableCar:setBlendCoeffs(eva, evb)
  local w = self.w
  w.currBlendEVA, w.currBlendEVB, w.targetBlendEVA, w.targetBlendEVB = eva, evb, eva, evb
  self.m.ppu:set("BLDALPHA", blendReg(eva, evb))
end

-- pokeemerald/src/field_weather.c:948
function CableCar:setTargetBlendCoeffs(eva, evb, delay)
  local w = self.w
  w.targetBlendEVA, w.targetBlendEVB, w.blendDelay = eva, evb, delay
  w.blendFrameCounter, w.blendUpdateCounter = 0, 0
end

-- pokeemerald/src/field_weather.c:957
function CableCar:updateBlend()
  local w = self.w
  if w.currBlendEVA == w.targetBlendEVA and w.currBlendEVB == w.targetBlendEVB then return true end
  w.blendFrameCounter = w.blendFrameCounter + 1
  if w.blendFrameCounter > w.blendDelay then
    w.blendFrameCounter = 0
    w.blendUpdateCounter = w.blendUpdateCounter + 1
    if w.blendUpdateCounter % 2 == 1 then
      if w.currBlendEVA < w.targetBlendEVA then w.currBlendEVA = w.currBlendEVA + 1
      elseif w.currBlendEVA > w.targetBlendEVA then w.currBlendEVA = w.currBlendEVA - 1 end
    else
      if w.currBlendEVB < w.targetBlendEVB then w.currBlendEVB = w.currBlendEVB + 1
      elseif w.currBlendEVB > w.targetBlendEVB then w.currBlendEVB = w.currBlendEVB - 1 end
    end
  end
  self.m.ppu:set("BLDALPHA", blendReg(w.currBlendEVA, w.currBlendEVB))
  return w.currBlendEVA == w.targetBlendEVA and w.currBlendEVB == w.targetBlendEVB
end

-- pokeemerald/src/field_weather_effect.c:1704
local function updateAshSprite(cc)
  return function(s)
    local d = s.data
    d[1] = d[1] + 1
    if d[1] > 5 then
      d[1] = 0
      d[0] = s16(d[0] + 1)
    end
    s.y = cc.coordOffsetY + d[0]
    s.x = cc.w.ashBaseSpritesX + 32 + d[2] * 64
    if s.x >= DISPLAY_WIDTH + 32 then
      s.x = band(cc.w.ashBaseSpritesX + DISPLAY_WIDTH * 2 - (4 - d[2]) * 64, 0x1FF)
    end
  end
end

-- pokeemerald/src/field_weather_effect.c:1657
function CableCar:createAshSprites()
  local w = self.w
  if w.ashSpritesCreated then return end
  local tpl = self:template("ash", {
    anims = ASH_ANIMS, priority = 1, objMode = Sprites.OBJ_BLEND, paletteTag = PALTAG_WEATHER,
    callback = updateAshSprite(self),
  })
  local sp = self.m.ppu.sprites
  for i = 0, NUM_ASH_SPRITES - 1 do
    local id = self:createAtEnd(tpl, 0, 0, 0x4E)
    if id ~= Sprites.MAX then
      local s = sp.sprites[id]
      s.data[1] = 0
      s.data[2] = i % 5
      s.data[3] = math.floor(i / 5)
      s.data[0] = s.data[3] * 64 + 32
      w.ash[i] = s
    else
      w.ash[i] = nil
    end
  end
  w.ashSpritesCreated = true
end

function CableCar:destroyAshSprites()
  local w = self.w
  if not w.ashSpritesCreated then return end
  for i = 0, NUM_ASH_SPRITES - 1 do
    if w.ash[i] then self.m.ppu.sprites:destroy(w.ash[i]) end
    w.ash[i] = nil
  end
  w.ashSpritesCreated = false
end

local WEATHER = {}

WEATHER[WEATHER_NONE] = {
  initVars = function() end, main = function() end, initAll = function() end, finish = function() return false end,
}
WEATHER[WEATHER_SUNNY] = WEATHER[WEATHER_NONE]

WEATHER[WEATHER_VOLCANIC_ASH] = {
  -- pokeemerald/src/field_weather_effect.c:1525
  initVars = function(cc)
    local w = cc.w
    w.initStep = 0
    w.weatherGfxLoaded = false
    if not w.ashSpritesCreated then
      cc:setBlendCoeffs(0, 16)
      cc.m.ppu:set("BLDALPHA", blendReg(64, 63))
    end
  end,
  -- pokeemerald/src/field_weather_effect.c:1546
  main = function(cc)
    local w = cc.w
    w.ashBaseSpritesX = band(cc.coordOffsetX, 0x1FF)
    while w.ashBaseSpritesX >= DISPLAY_WIDTH do w.ashBaseSpritesX = w.ashBaseSpritesX - DISPLAY_WIDTH end
    if w.initStep == 0 then
      w.initStep = 1
    elseif w.initStep == 1 then
      if not w.ashSpritesCreated then
        cc:createAshSprites()
        cc.m:addStall(CableCar.STALL.createAshSprites)
      end
      cc:setTargetBlendCoeffs(16, 0, 1)
      w.initStep = 2
    elseif w.initStep == 2 then
      if cc:updateBlend() then
        w.weatherGfxLoaded = true
        w.initStep = 3
      end
    else
      cc:updateBlend()
    end
  end,
  -- pokeemerald/src/field_weather_effect.c:1578
  finish = function(cc)
    local w = cc.w
    if w.finishStep == 0 then
      cc:setTargetBlendCoeffs(0, 16, 1)
      w.finishStep = 1
    elseif w.finishStep == 1 then
      if cc:updateBlend() then
        cc:destroyAshSprites()
        w.finishStep = 2
      end
    elseif w.finishStep == 2 then
      cc.m.ppu:set("BLDALPHA", 0)
      w.finishStep = 3
      return false
    else
      return false
    end
    return true
  end,
}
-- pokeemerald/src/field_weather_effect.c:1539
WEATHER[WEATHER_VOLCANIC_ASH].initAll = function(cc)
  WEATHER[WEATHER_VOLCANIC_ASH].initVars(cc)
  while not cc.w.weatherGfxLoaded do WEATHER[WEATHER_VOLCANIC_ASH].main(cc) end
end

-- pokeemerald/src/field_weather.c:183
function CableCar:setNextWeather(weather)
  local w = self.w
  if w.nextWeather ~= weather and w.currWeather == weather then WEATHER[weather].initVars(self) end
  w.weatherChangeComplete = false
  w.nextWeather = weather
  w.finishStep = 0
end

-- pokeemerald/src/field_weather.c:207
function CableCar:setCurrentAndNextWeatherNoDelay(weather)
  local w = self.w
  w.currWeather, w.nextWeather = weather, weather
  w.readyForInit = true
end

-- pokeemerald/src/field_weather.c:216
function CableCar:weatherTask()
  local w = self.w
  if not w then return end
  if not w.initialized then
    if w.readyForInit then
      WEATHER[w.currWeather].initAll(self)
      w.initialized = true
    end
    return
  end
  -- pokeemerald/src/field_weather.c:227
  if w.currWeather ~= w.nextWeather then
    if not WEATHER[w.currWeather].finish(self) then
      WEATHER[w.nextWeather].initVars(self)
      w.currWeather = w.nextWeather
      w.weatherChangeComplete = true
    end
  else
    WEATHER[w.currWeather].main(self)
  end
end

-- pokeemerald/src/cable_car.c:711
function CableCar:setBgRegs(active)
  local ppu = self.m.ppu
  for _, r in ipairs({ "WININ", "WINOUT", "WIN0H", "WIN1H", "WIN0V", "WIN1V" }) do ppu:set(r, 0) end
  if not active then
    ppu:set("DISPCNT", 0)
    for _, r in ipairs({ "BG3HOFS", "BG3VOFS", "BG2HOFS", "BG2VOFS", "BG1HOFS", "BG1VOFS", "BG0HOFS", "BG0VOFS" }) do
      ppu:set(r, 0)
    end
    ppu:set("BLDCNT", 0)
    return
  end
  local c = self.c
  if not self.goingDown then
    c.bg3H, c.bg3V, c.bg1H, c.bg1V, c.bg0V = 176, 16, 0, 80, 0
  else
    c.bg3H, c.bg3V, c.bg1H, c.bg1V, c.bg0V = 96, 232, 0, 4, 0
  end
  self:applyScroll()
  ppu:set("BG2HOFS", 0)
  ppu:set("BG2VOFS", 0)
  -- pokeemerald/src/cable_car.c:773
  self.bg[1]:flush()
  self.bg[2]:flush()
  ppu:set("DISPCNT", bit.bor(Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG_ALL_ON))
  ppu:set("BLDCNT", BLDCNT_TGT2_ALL)
end

function CableCar:applyScroll()
  local ppu, c = self.m.ppu, self.c
  ppu:set("BG3HOFS", c.bg3H)
  ppu:set("BG3VOFS", c.bg3V)
  ppu:set("BG1HOFS", c.bg1H)
  ppu:set("BG1VOFS", c.bg1V)
  ppu:set("BG0HOFS", c.bg0H)
  ppu:set("BG0VOFS", c.bg0V)
end

-- pokeemerald/src/cable_car.c:243
function CableCar:loadCb()
  local m, ppu = self.m, self.m.ppu
  local st = m.state
  if st == 0 then
    m:setVBlank(nil)
    self:setBgRegs(false)
    ppu.scanline:stop()
    ppu.palette:clearHardware(0)
    ppu.sprites.oamShown = {}
    self.c = {
      state = 0, weather = 0, weatherDelay = 0, timer = 0,
      bg0H = 0, bg0V = 0, bg1H = 0, bg1V = 0, bg3H = 0, bg3V = 0,
      groundTileIdx = 0, groundSegmentXStart = 0, groundSegmentYStart = 0, groundTilemapOffset = 0,
      groundTimer = 0, groundXOffset = 0, groundYOffset = 0, groundXBase = 0, groundYBase = 0,
      groundTileBuffer = {},
    }
    for i = 0, 8 do
      local row = {}
      for j = 0, 11 do row[j] = 0 end
      self.c.groundTileBuffer[i] = row
    end
    m.state = 1
  elseif st == 1 then
    ppu.sprites:resetData()
    m.tasks:reset()
    ppu.sprites:freeAllPalettes()
    ppu.palette:resetFade()
    self:startWeather()
    local tiles = assert(CacheBlob.readFs(self.man.bgTiles), "cable_car: bg tiles missing from cache")
    self.bg = {}
    for i = 0, 3 do self.bg[i] = TileLayer.new(tiles) end
    -- pokeemerald/src/cable_car.c:95
    local prio = { [0] = 1, 2, 3, 0 }
    for i = 0, 3 do ppu:setBg(i, prio[i], self.bg[i].layer, true) end
    self.coordOffsetX, self.coordOffsetY = 0, 0
    m.state = 2
  elseif st == 2 then
    local sp = ppu.sprites
    sp:loadPalette(TAG_CABLE_CAR, self.man.palettes.car)
    self.maps = self.man.tilemaps
    m.state = 3
  elseif st == 3 then
    ppu.palette:load(self.man.palettes.bg, 0, 64)
    m.state = 4
  elseif st == 4 then
    self:createSprites()
    m.tasks:run(self)
    m.state = 5
  elseif st == 5 then
    -- pokeemerald/src/cable_car.c:307
    if self.c.weather == WEATHER_VOLCANIC_ASH then
      m.state = 6
    elseif self.w.ash[0] then
      for i = 0, NUM_ASH_SPRITES - 1 do
        if self.w.ash[i] then self.w.ash[i].oam.priority = 0 end
      end
      m.state = 6
    end
  elseif st == 6 then
    local T = self.maps
    self.bg[1]:copyRect(T.trees, 0, 0, 17, 32, 15)
    self.bg[2]:copyRect(T.bgMountains, 0, 0, 0, 30, 20)
    self.bg[3]:copyRect(T.pylonTop, 0, 0, 0, 5, 2)
    self.bg[3]:copyRect(T.pylonPole, 0, 0, 2, 2, 20)
    m.state = 7
  elseif st == 7 then
    self:initGroundTilemapData()
    local G, b0 = self.maps.ground, self.bg[0]
    -- pokeemerald/src/cable_car.c:332
    b0:copyRect(G, 0x48, 0, 14, 12, 3)
    b0:copyRect(G, 0x6C, 12, 17, 12, 3)
    b0:copyRect(G, 0x90, 24, 20, 12, 3)
    b0:copyRect(G, 0x0, 0, 17, 12, 3)
    b0:copyRect(G, 0x24, 0, 20, 12, 3)
    b0:copyRect(G, 0x0, 12, 20, 12, 3)
    b0:copyRect(G, 0x24, 12, 23, 12, 3)
    b0:copyRect(G, 0x0, 24, 23, 12, 3)
    m.state = 8
  elseif st == 8 then
    ppu.palette:beginFade(Palette.ALL, 3, 16, 0, Palette.BLACK)
    audio().fadeInBgm(song("MUS_CABLE_CAR"), 1)
    self:setBgRegs(true)
    self:mark("fade_in")
    m.state = 9
  elseif st == 9 then
    m:setVBlank(function() self:vblankCb() end)
    m:setCb2(function() self:mainCb() end)
    m.tasks:create(function() self:taskCableCar() end, 0)
    if not self.goingDown then
      self.bgTaskId = m.tasks:create(function() self:taskBgGoingUp() end, 1)
    else
      self.bgTaskId = m.tasks:create(function() self:taskBgGoingDown() end, 1)
    end
  end
end

-- pokeemerald/src/cable_car.c:361
function CableCar:mainCb()
  local m = self.m
  m.tasks:run(self)
  m.ppu.sprites:animateAll()
  m.ppu.sprites:buildOam()
  m.ppu.palette:update()
end

-- pokeemerald/src/cable_car.c:557
function CableCar:vblankCb()
  self.bg[0]:flush()
  self.bg[3]:flush()
  self:applyScroll()
  self.m.ppu:vblank()
end

-- pokeemerald/src/cable_car.c:370
function CableCar:endCb()
  local ppu = self.m.ppu
  self:setBgRegs(false)
  self.coordOffsetX = 0
  self.m.tasks:reset()
  ppu.sprites:resetData()
  ppu.palette:resetFade()
  self:mark("end")
  self.done = true
  self.m:setCb2(nil)
  if self.onDone then self.onDone() end
end

-- pokeemerald/src/cable_car.c:406
function CableCar:taskCableCar()
  local c, w = self.c, self.w
  c.timer = (c.timer + 1) % 65536
  if c.state == 0 then
    if c.timer == c.weatherDelay then
      self:setNextWeather(c.weather)
      c.state = 1
      self:mark("weather")
    end
  elseif c.state == 1 then
    if c.weather == WEATHER_VOLCANIC_ASH then
      if w.ash[0] and w.ash[0].oam.priority ~= 0 then
        for i = 0, NUM_ASH_SPRITES - 1 do
          if w.ash[i] then w.ash[i].oam.priority = 0 end
        end
        c.state = 2
      end
    elseif c.weather == WEATHER_SUNNY then
      if w.currWeather == WEATHER_SUNNY then
        c.state = 2
      elseif c.timer >= c.weatherDelay + 8 then
        for i = 0, NUM_ASH_SPRITES - 1 do
          if w.ash[i] then w.ash[i].invisible = not w.ash[i].invisible end
        end
      end
    end
  elseif c.state == 2 then
    if c.timer == 570 then
      c.state = 3
      self.m.ppu.palette:beginFade(Palette.ALL, 3, 0, 16, Palette.BLACK)
      audio().fadeOutBgm(4)
      self:mark("fade_out")
    end
  elseif c.state == 3 then
    if not self.m.ppu.palette:fadeActive() then c.state = STATE_END end
  elseif c.state == STATE_END then
    self.m:setVBlank(nil)
    self.m.tasks:reset()
    self.m:setCb2(function() self:endCb() end)
  end
end

-- pokeemerald/src/cable_car.c:476
function CableCar:taskBgGoingUp()
  local c = self.c
  if c.state ~= STATE_END then
    c.bg3H = u8(c.bg3H - 1)
    if c.timer % 2 == 0 then c.bg3V = u8(c.bg3V - 1) end
    if c.timer % 8 == 0 then
      c.bg1H = u8(c.bg1H - 1)
      c.bg1V = u8(c.bg1V - 1)
    end
    local b3, T = self.bg[3], self.maps
    if c.bg3H == 175 then
      b3:fill(0, 0, 22, 2, 10)
    elseif c.bg3H == 40 then
      b3:fill(0, 3, 0, 2, 2)
    elseif c.bg3H == 32 then
      b3:fill(0, 2, 0, 1, 2)
    elseif c.bg3H == 16 then
      b3:copyRect(T.pylonTop, 0, 0, 0, 5, 2)
      b3:copyRect(T.pylonPole, 0, 0, 2, 2, 30)
      c.bg3V = 64
    end
  end
  self:animateGroundGoingUp()
  self.coordOffsetX = (self.coordOffsetX + 1) % 128
end

-- pokeemerald/src/cable_car.c:513
function CableCar:taskBgGoingDown()
  local c = self.c
  if c.state ~= STATE_END then
    c.bg3H = u8(c.bg3H + 1)
    if c.timer % 2 == 0 then c.bg3V = u8(c.bg3V + 1) end
    if c.timer % 8 == 0 then
      c.bg1H = u8(c.bg1H + 1)
      c.bg1V = u8(c.bg1V + 1)
    end
    local b3, T = self.bg[3], self.maps
    if c.bg3H == 176 then
      b3:copyRect(T.pylonPole, 0, 0, 2, 2, 30)
    elseif c.bg3H == 16 then
      b3:fill(0, 2, 0, 3, 2)
      b3:fill(0, 0, 22, 2, 10)
      c.bg3V = 192
    elseif c.bg3H == 32 then
      b3:fill(T.pylonTop[3], 2, 0, 1, 1)
      b3:fill(T.pylonTop[4], 3, 0, 1, 1)
      b3:fill(T.pylonTop[8], 2, 1, 1, 1)
      b3:fill(T.pylonTop[9], 3, 1, 1, 1)
    elseif c.bg3H == 40 then
      b3:fill(T.pylonTop[5], 4, 0, 1, 1)
      b3:fill(T.pylonTop[10], 4, 1, 1, 1)
    end
  end
  self:animateGroundGoingDown()
  if c.timer < c.weatherDelay then
    self.coordOffsetX = (self.coordOffsetX + 247) % 248
  else
    self.w.ashBaseSpritesX = (self.w.ashBaseSpritesX + 247) % 248
  end
end

local function carMotion(cc, s)
  local t = cc.c.timer
  -- pokeemerald/src/cable_car.c:586
  local dx, dy = u8(math.floor(F_014 * t)), u8(math.floor(F_0067 * t))
  if not cc.goingDown then
    s.x = s.data[0] - dx
    s.y = s.data[1] - dy
  else
    s.x = s.data[0] + dx
    s.y = s.data[1] + dy
  end
end

-- pokeemerald/src/cable_car.c:580
local function spriteCbCableCar(cc)
  return function(s)
    if cc.c.state ~= STATE_END then carMotion(cc, s) end
  end
end

-- pokeemerald/src/cable_car.c:600
local function spriteCbPlayer(cc)
  return function(s)
    if cc.c.state == STATE_END then return end
    carMotion(cc, s)
    local d = s.data
    if d[2] == 0 then
      s.y2 = 17
      local old = d[3]
      d[3] = d[3] + 1
      if old > 9 then
        d[3] = 0
        d[2] = d[2] + 1
      end
    else
      s.y2 = 16
      local old = d[3]
      d[3] = d[3] + 1
      if old > 9 then
        d[3] = 0
        d[2] = 0
      end
    end
  end
end

-- pokeemerald/src/cable_car.c:646
local function spriteCbHikerGoingUp(cc)
  return function(s, sp)
    local d = s.data
    if d[0] == 0 then
      s.x = s.x + 2 * s.centerToCornerVecX
      s.y = s.y + 16 + s.centerToCornerVecY
    end
    d[0] = d[0] + 1
    if d[0] >= d[2] then
      if d[1] == 0 then
        s.x = s.x + 1
        if d[0] % 4 == 0 then s.y = s.y + 1 end
      elseif d[0] % 2 ~= 0 then
        s.x = s.x + 1
        if s.x % 4 == 0 then s.y = s.y + 1 end
      end
      if s.y > DISPLAY_HEIGHT then sp:destroy(s) end
    end
  end
end

-- pokeemerald/src/cable_car.c:679
local function spriteCbHikerGoingDown(cc)
  return function(s, sp)
    local d = s.data
    if d[0] == 0 then s.y = s.y + 16 + s.centerToCornerVecY end
    d[0] = d[0] + 1
    if d[0] >= d[2] then
      if d[1] == 0 then
        s.x = s.x - 1
        if d[0] % 4 == 0 then s.y = s.y - 1 end
      elseif d[0] % 2 ~= 0 then
        s.x = s.x - 1
        if s.x % 4 == 0 then s.y = s.y - 1 end
      end
      if s.y < 80 then sp:destroy(s) end
    end
  end
end

-- pokeemerald/src/cable_car.c:784
function CableCar:createSprites()
  local sp, c = self.m.ppu.sprites, self.c
  local rval = self.random() % 65536
  local playerNames = self.playerGfxNames or {[0] = "OBJ_EVENT_GFX_RIVAL_BRENDAN_NORMAL", "OBJ_EVENT_GFX_RIVAL_MAY_NORMAL"}
  local hikerNames = self.hikerGfxNames or {
    [0] = "OBJ_EVENT_GFX_HIKER", "OBJ_EVENT_GFX_CAMPER", "OBJ_EVENT_GFX_PICNICKER", "OBJ_EVENT_GFX_ZIGZAGOON_1",
  }
  local playerGfx, hikerGfx = gfxId(playerNames[self.female and 1 or 0]), {}
  for i = 0, 3 do hikerGfx[i] = gfxId(hikerNames[i]) end
  local hikerCoords = { [0] = { 0, 80 }, { 240, 146 } }
  local hikerDelay = { [0] = 0, 60, 120, 170 }
  local carTpl = self:template("car", { callback = spriteCbCableCar(self), paletteTag = TAG_CABLE_CAR })
  local doorTpl = self:template("door", { callback = spriteCbCableCar(self), paletteTag = TAG_CABLE_CAR })
  local cableTpl = self:template("cable", { paletteTag = TAG_CABLE_CAR })
  local function place(tpl, x, y, sub, x2, y2)
    local id = sp:create(tpl, x, y, sub)
    local s = sp.sprites[id]
    s.x2, s.y2 = x2, y2
    s.data[0], s.data[1] = x, y
    return s
  end
  local playerTpl = self:owTemplate(playerGfx, spriteCbPlayer(self))
  local px, py, cx, cy, dx, dy
  if not self.goingDown then
    px, py, cx, cy, dx, dy = 200, 73, 176, 43, 200, 99
    c.weather, c.weatherDelay = WEATHER_VOLCANIC_ASH, 350
    self:setCurrentAndNextWeatherNoDelay(WEATHER_SUNNY)
  else
    self.bg[0]:copyRect(self.man.tilemaps.ground, 0x24, 24, 26, 12, 3)
    px, py, cx, cy, dx, dy = 128, 39, 104, 9, 128, 65
    c.weather, c.weatherDelay = WEATHER_SUNNY, 265
    self:setCurrentAndNextWeatherNoDelay(WEATHER_VOLCANIC_ASH)
  end
  local player = place(playerTpl, px, py, 102, 8, 16)
  player.oam.priority = 2
  self.player = player
  self.car = place(carTpl, cx, cy, 0x67, 32, 32)
  place(doorTpl, dx, dy, 0x65, 8, 4)
  for i = 0, 8 do
    local id = sp:create(cableTpl, 16 * i + 96, 8 * i - 8, 0x68)
    local s = sp.sprites[id]
    s.x2, s.y2 = 8, 8
  end
  -- pokeemerald/src/cable_car.c:877
  if rval % 64 == 0 then
    local dir = self.goingDown and 1 or 0
    local tpl = self:owTemplate(hikerGfx[rval % 3], dir == 0 and spriteCbHikerGoingUp(self) or spriteCbHikerGoingDown(self))
    local id = sp:create(tpl, hikerCoords[dir][1], hikerCoords[dir][2], 106)
    if id ~= Sprites.MAX then
      local s = sp.sprites[id]
      s.oam.priority = 2
      s.x2, s.y2 = -s.centerToCornerVecX, -s.centerToCornerVecY
      if not self.goingDown then
        if rval % 2 == 1 then
          Sprites.startAnim(s, ANIM_STD_GO_WEST)
          s.data[1] = 1
          s.y = s.y + 2
        else
          Sprites.startAnim(s, ANIM_STD_GO_EAST)
          s.data[1] = 0
        end
      else
        if rval % 2 == 1 then
          Sprites.startAnim(s, ANIM_STD_GO_EAST)
          s.data[1] = 1
          s.y = s.y + 2
        else
          Sprites.startAnim(s, ANIM_STD_GO_WEST)
          s.data[1] = 0
        end
      end
      s.data[2] = hikerDelay[rval % 4]
      self.hiker = s
    end
  end
end

-- pokeemerald/src/cable_car.c:925
function CableCar:bufferNextGroundSegment()
  local c, G = self.c, self.maps.ground
  local offset, k = u8(0x24 * (c.groundTilemapOffset + 2)), 0
  for i = 0, 2 do
    for j = 0, 11 do
      c.groundTileBuffer[i][j] = G[offset + 1] or 0
      offset = u8(offset + 1)
      c.groundTileBuffer[i + 3][j] = G[k + 1] or 0
      c.groundTileBuffer[i + 6][j] = G[0x24 + k + 1] or 0
      k = k + 1
    end
  end
  c.groundTilemapOffset = (c.groundTilemapOffset + 1) % 3
end

-- pokeemerald/src/cable_car.c:944
function CableCar:animateGroundGoingUp()
  local c = self.c
  c.groundTimer = (c.groundTimer + 1) % 96
  c.bg0H = u8(c.groundXBase - c.groundXOffset)
  c.bg0V = u8(c.groundYBase - c.groundYOffset)
  c.groundXOffset = u8(c.groundXOffset + 1)
  if c.groundXOffset % 4 == 0 then c.groundYOffset = u8(c.groundYOffset + 1) end
  if c.groundXOffset > 16 then self:drawNextGroundSegmentGoingUp() end
end

-- pokeemerald/src/cable_car.c:957
function CableCar:animateGroundGoingDown()
  local c = self.c
  c.groundTimer = (c.groundTimer + 1) % 96
  c.bg0H = u8(c.groundXBase + c.groundXOffset)
  c.bg0V = u8(c.groundYBase + c.groundYOffset)
  c.groundXOffset = u8(c.groundXOffset + 1)
  if c.groundXOffset % 4 == 0 then c.groundYOffset = u8(c.groundYOffset + 1) end
  if c.groundXOffset > 16 then self:drawNextGroundSegmentGoingDown() end
end

-- pokeemerald/src/cable_car.c:970
function CableCar:drawNextGroundSegmentGoingUp()
  local c, b0 = self.c, self.bg[0]
  c.groundXOffset, c.groundYOffset = 0, 0
  c.groundXBase, c.groundYBase = c.bg0H, c.bg0V
  c.groundSegmentXStart = (c.groundSegmentXStart + 30) % 32
  c.groundTileIdx = u8(c.groundTileIdx - 2)
  local segY = (c.groundSegmentYStart + 23) % 32
  for i = 0, 8 do
    local x = c.groundSegmentXStart
    local y = (segY + i) % 32
    b0:fill(c.groundTileBuffer[i][c.groundTileIdx] or 0, x, y, 1, 1)
    x = (x + 1) % 32
    b0:fill(c.groundTileBuffer[i][c.groundTileIdx + 1] or 0, x, y, 1, 1)
  end
  b0:fill(0, (c.groundSegmentXStart + 30) % 32, 0, 2, 32)
  if c.groundTileIdx == 0 then
    c.groundSegmentYStart = (c.groundSegmentYStart + 29) % 32
    c.groundTileIdx = 12
    self:bufferNextGroundSegment()
    b0:fill(0, 0, (c.groundSegmentYStart + 1) % 32, 32, 9)
  end
end

-- pokeemerald/src/cable_car.c:1004
function CableCar:drawNextGroundSegmentGoingDown()
  local c, b0 = self.c, self.bg[0]
  c.groundXOffset, c.groundYOffset = 0, 0
  c.groundXBase, c.groundYBase = c.bg0H, c.bg0V
  c.groundSegmentXStart = (c.groundSegmentXStart + 2) % 32
  c.groundTileIdx = u8(c.groundTileIdx + 2)
  local segY = c.groundSegmentYStart
  for i = 0, 8 do
    local x = c.groundSegmentXStart
    local y = (segY + i) % 32
    b0:fill(c.groundTileBuffer[i][c.groundTileIdx] or 0, x, y, 1, 1)
    x = (x + 1) % 32
    b0:fill(c.groundTileBuffer[i][c.groundTileIdx + 1] or 0, x, y, 1, 1)
  end
  b0:fill(0, c.groundSegmentXStart, (c.groundSegmentYStart + 23) % 32, 2, 9)
  if c.groundTileIdx == 10 then
    c.groundSegmentYStart = (c.groundSegmentYStart + 3) % 32
    c.groundTileIdx = u8(-2)
    self:bufferNextGroundSegment()
  end
end

-- pokeemerald/src/cable_car.c:1036
function CableCar:initGroundTilemapData()
  local c = self.c
  c.groundTilemapOffset = 2
  c.groundSegmentYStart = 20
  if not self.goingDown then
    c.groundSegmentXStart = 0
    c.groundTileIdx = 12
    self:bufferNextGroundSegment()
    self:drawNextGroundSegmentGoingUp()
  else
    c.groundSegmentXStart = 28
    c.groundTileIdx = 4
    self:bufferNextGroundSegment()
    self:drawNextGroundSegmentGoingDown()
  end
  c.groundTimer = 0
end

function CableCar:frame(input)
  if self.done then return end
  self.frames = self.frames + 1
  self.m:frame(input)
end

function CableCar:draw()
  self.m.ppu:draw(0, 0)
end

local Host = {}
CableCar.Host = Host
Host._screen = nil
Host._step = nil

function CableCar.open(opts)
  local Stack = require("src.ui.game3.stack")
  local Kit = require("src.ui.game3.rse.scene_kit")
  local screen = CableCar.new(opts)
  Host._screen = screen
  Host._step = Kit.stepper()
  local userDone = opts and opts.onDone
  screen.onDone = function()
    Host._screen = nil
    Stack.pop("cable_car")
    if userDone then userDone(screen) end
  end
  Stack.push("cable_car", Host, { hideBelow = true, fullscreen = true })
  return screen
end

function CableCar.active()
  return Host._screen
end

function CableCar.reset()
  if Host._screen then
    Host._screen = nil
    require("src.ui.game3.stack").pop("cable_car")
  end
  Host._step = nil
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local screen = Host._screen
  if not screen then return end
  Host._step:run(dt, function(inp)
    if screen.done then return true end
    screen:frame(inp)
    return screen.done or nil
  end)
end

function Host.draw()
  local screen = Host._screen
  if screen then
    screen:draw()
  else
    love.graphics.clear(0, 0, 0, 1)
  end
end

return CableCar
