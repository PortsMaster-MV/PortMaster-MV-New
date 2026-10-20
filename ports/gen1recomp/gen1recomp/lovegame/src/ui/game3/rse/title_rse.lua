local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Affine = require("src.core.game3.bg_affine")
local Trig = require("src.core.game3.trig")

local band, bor, rshift = bit.band, bit.bor, bit.rshift

local Title = {}
Title.__index = Title

Title.MANIFEST = "data/generated/gba/title/manifest.lua"

-- pokeemerald/src/title_screen.c:26
local TAG_VERSION, TAG_PRESS_START_COPYRIGHT = 1000, 1001
local VERSION_BANNER_LEFT_X, VERSION_BANNER_RIGHT_X = 98, 162
local VERSION_BANNER_Y, VERSION_BANNER_Y_GOAL = 2, 66
local START_BANNER_X = 128
local NUM_PRESS_START_FRAMES = 5

local SHINE_MODE_SINGLE_NO_BG_COLOR, SHINE_MODE_DOUBLE, SHINE_MODE_SINGLE = 0, 1, 2
local SHINE_SPEED = 4

-- pokeemerald/src/title_screen.c:599
Title.STALL_LOAD = 3

local A_B_START_SELECT = bor(Machine.A_BUTTON, Machine.B_BUTTON, Machine.START_BUTTON, Machine.SELECT_BUTTON)
local CLEAR_SAVE_BUTTON_COMBO = bor(Machine.B_BUTTON, Machine.SELECT_BUTTON, Machine.DPAD_UP)
local RESET_RTC_BUTTON_COMBO = bor(Machine.B_BUTTON, Machine.SELECT_BUTTON, Machine.DPAD_LEFT)
local BERRY_UPDATE_BUTTON_COMBO = bor(Machine.B_BUTTON, Machine.SELECT_BUTTON)

local SINE = Trig.SINE

local function Cos(i, amp)
  return math.floor(amp * SINE[i + 64 + 1] / 256)
end

local function trunc(x)
  if x >= 0 then return math.floor(x) end
  return -math.floor(-x)
end

local function audio()
  return require("src.core.game3.audio")
end

local function songId(name)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get()):require("songs", name)
end

function Title.songFrames(id)
  local Seq = require("src.core.game3.m4a_seq")
  local blob = love.filesystem.read(string.format("data/generated/gba/audio/songs/%d.bin", id))
  assert(blob, "title_rse: song " .. tostring(id) .. " missing from cache")
  local p = Seq.newPlayer(Seq.parseSongBin(blob))
  local n = 0
  while n < 1000000 do
    Seq.update(p, 1)
    n = n + 1
    local all = true
    for _, tr in ipairs(p.tracks) do
      if not tr.done then
        all = false
        break
      end
    end
    if all then return n end
  end
  return nil
end

function Title.new(machine, opts)
  opts = opts or {}
  local self = setmetatable({}, Title)
  self.m = machine
  self.man = machine:manifest(Title.MANIFEST)
  self.params = assert(opts.params, "title_rse: profile boot.title params required")
  self.canResetRtc = opts.canResetRtc
  self.log = {}
  self.result = nil
  self.phase = "init"
  machine:setCb2(function() self:initCb() end)
  return self
end

function Title:mark(what)
  self.log[#self.log + 1] = { frame = self.frames or 0, what = what }
end

function Title:layer(key)
  return Machine.layer(assert(self.man.layers[key], "title_rse: layer " .. key .. " missing from cache"))
end

function Title:sprite(key)
  return assert(self.man.sprites[key], "title_rse: sprite " .. key .. " missing from cache")
end

function Title:alphaReg(i)
  local row = self.man.alphaBlend[i + 1]
  return Ppu.blendAlpha(row[1], row[2])
end

-- pokeemerald/src/title_screen.c:561
function Title:vblankCb()
  local m = self.m
  m.ppu:vblank()
  m.ppu:set("BG1VOFS", band(m.globals.battleBg1Y, 0xFFFF))
end

-- pokeemerald/src/title_screen.c:570
function Title:initCb()
  local m, ppu = self.m, self.m.ppu
  local pal = ppu.palette
  local st = m.state
  if st == 0 then
    m:setVBlank(nil)
    ppu:set("BLDCNT", 0)
    ppu:set("BLDALPHA", 0)
    ppu:set("BLDY", 0)
    pal.pltt[0] = Palette.WHITE
    ppu:set("DISPCNT", 0)
    for i = 0, 3 do ppu:setBg(i, 0, nil) end
    for _, r in ipairs({ "BG2HOFS", "BG2VOFS", "BG1HOFS", "BG1VOFS", "BG0HOFS", "BG0VOFS" }) do ppu:set(r, 0) end
    ppu.sprites.oamShown = {}
    pal:clearHardware(1)
    pal:resetFade()
    m.state = 1
  elseif st == 1 then
    pal:load(self.man.palettes.bg, 0, #self.man.palettes.bg)
    self.logo = self:layer("logo")
    self.rayquaza = self:layer("rayquaza")
    self.clouds = self:layer("clouds")
    ppu.scanline:stop()
    m.tasks:reset()
    ppu.sprites:resetData()
    ppu.sprites:freeAllPalettes()
    ppu.sprites:setReservedPalettes(9)
    pal:load(self.man.palettes.version, 256, 16)
    ppu.sprites:loadPalette(TAG_PRESS_START_COPYRIGHT, self.man.palettes.pressStart)
    m.state = 2
    m:addStall(Title.STALL_LOAD)
  elseif st == 2 then
    local id = m.tasks:create(function(i, d) self:phase1(i, d) end, 0)
    local d = m.tasks:get(id).data
    d[0], d[1], d[2], d[3] = 256, 0, -16, -32
    self.taskId = id
    m.state = 3
  elseif st == 3 then
    pal:beginFade(Palette.ALL, 1, 16, 0, Palette.WHITEALPHA)
    m:setVBlank(function() self:vblankCb() end)
    m.state = 4
  elseif st == 4 then
    ppu:setAffine(2, Affine.panFadeAndZoom(120, 80, 0x100, 0))
    ppu:set("BG2X", -29 * 256)
    ppu:set("BG2Y", -32 * 256)
    ppu:set("WIN0H", 0)
    ppu:set("WIN0V", 0)
    ppu:set("WIN1H", 0)
    ppu:set("WIN1V", 0)
    ppu:set("WININ", bor(Ppu.WININ_WIN0_BG_ALL, Ppu.WININ_WIN0_OBJ, Ppu.WININ_WIN1_BG_ALL, Ppu.WININ_WIN1_OBJ))
    ppu:set("WINOUT", bor(Ppu.WINOUT_WIN01_BG_ALL, Ppu.WINOUT_WIN01_OBJ, Ppu.WINOUT_WINOBJ_ALL))
    ppu:set("BLDCNT", bor(Ppu.BLDCNT_TGT1_BG2, Ppu.BLDCNT_EFFECT_LIGHTEN))
    ppu:set("BLDALPHA", 0)
    ppu:set("BLDY", 12)
    ppu:setBg(0, 3, self.rayquaza)
    ppu:setBg(1, 2, self.clouds)
    ppu:setBg(2, 1, self.logo, false)
    ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON,
      Ppu.DISPCNT_WIN0_ON, Ppu.DISPCNT_OBJWIN_ON))
    local song = songId(self.params.song)
    audio().playSong(song, { restart = true })
    self.songFrames = Title.songFrames(song)
    self.songStart = self.frames or 0
    self:mark("song " .. self.params.song)
    m.state = 5
  elseif st == 5 then
    if pal:update() == 0 then
      self:startShine(SHINE_MODE_SINGLE_NO_BG_COLOR)
      local w = ppu.scanline:initWave(0, 160, 4, 4, 0, "BG1HOFS", function() return m.globals.battleBg1X end)
      m.tasks:create(function(i) if not ppu.scanline:runWaveTask(w) then m.tasks:destroy(i) end end, 0)
      self.phase = "phase1"
      self:mark("phase1")
      m:setCb2(function() self:mainCb() end)
    end
  end
end

-- pokeemerald/src/title_screen.c:675
function Title:mainCb()
  local m = self.m
  m.tasks:run(self)
  m.ppu.sprites:animateAll()
  m.ppu.sprites:buildOam()
  m.ppu.palette:update()
end

-- pokeemerald/src/title_screen.c:467
function Title:shineCb(s, sp)
  local d = s.data
  local faded = self.m.ppu.palette.faded
  if s.x < 240 + 32 then
    if d[0] ~= SHINE_MODE_SINGLE_NO_BG_COLOR then
      if s.x < 120 then
        if d[1] < 31 then d[1] = d[1] + 1 end
        if d[1] < 31 then d[1] = d[1] + 1 end
      else
        if d[1] ~= 0 then d[1] = d[1] - 1 end
        if d[1] ~= 0 then d[1] = d[1] - 1 end
      end
      local bg = Palette.rgb(d[1], d[1], d[1])
      if s.x == 120 + 3 * SHINE_SPEED or s.x == 120 + 4 * SHINE_SPEED
          or s.x == 120 + 5 * SHINE_SPEED or s.x == 120 + 6 * SHINE_SPEED then
        faded[0] = Palette.rgb(24, 31, 12)
      else
        faded[0] = bg
      end
    end
    s.x = s.x + SHINE_SPEED
  else
    faded[0] = Palette.BLACK
    sp:destroy(s)
  end
end

-- pokeemerald/src/title_screen.c:517
local function shineFastCb(s, sp)
  if s.x < 240 + 32 then
    s.x = s.x + SHINE_SPEED * 2
  else
    sp:destroy(s)
  end
end

function Title:shineTemplate(cb)
  return Machine.template(self:sprite("logo_shine"), { paletteTag = TAG_PRESS_START_COPYRIGHT, callback = cb })
end

-- pokeemerald/src/title_screen.c:525
function Title:startShine(mode)
  local sp = self.m.ppu.sprites
  local cb = function(s, spr) self:shineCb(s, spr) end
  if mode == SHINE_MODE_SINGLE_NO_BG_COLOR or mode == SHINE_MODE_SINGLE then
    local s = sp:get(sp:create(self:shineTemplate(cb), 0, 68, 0))
    s.oam.objMode = Sprites.OBJ_WINDOW
    s.data[0] = mode
  elseif mode == SHINE_MODE_DOUBLE then
    local s = sp:get(sp:create(self:shineTemplate(cb), 0, 68, 0))
    s.oam.objMode = Sprites.OBJ_WINDOW
    s.data[0] = mode
    s.invisible = true
    s = sp:get(sp:create(self:shineTemplate(shineFastCb), 0, 68, 0))
    s.oam.objMode = Sprites.OBJ_WINDOW
    s = sp:get(sp:create(self:shineTemplate(shineFastCb), -80, 68, 0))
    s.oam.objMode = Sprites.OBJ_WINDOW
  end
  self:mark("shine " .. mode)
end

-- pokeemerald/src/title_screen.c:374
function Title:bannerLeftCb(s)
  local parent = self.m.tasks:get(s.data[1]).data
  if parent[1] ~= 0 then
    s.oam.objMode = Sprites.OBJ_NORMAL
    s.y = VERSION_BANNER_Y_GOAL
  else
    if s.y ~= VERSION_BANNER_Y_GOAL then s.y = s.y + 1 end
    if s.data[0] ~= 0 then s.data[0] = s.data[0] - 1 end
    self.m.ppu:set("BLDALPHA", self:alphaReg(s.data[0]))
  end
end

-- pokeemerald/src/title_screen.c:391
function Title:bannerRightCb(s)
  local parent = self.m.tasks:get(s.data[1]).data
  if parent[1] ~= 0 then
    s.oam.objMode = Sprites.OBJ_NORMAL
    s.y = VERSION_BANNER_Y_GOAL
  elseif s.y ~= VERSION_BANNER_Y_GOAL then
    s.y = s.y + 1
  end
end

-- pokeemerald/src/title_screen.c:409
local function pressStartCb(s)
  if s.data[0] == 1 then
    s.data[1] = s.data[1] + 1
    s.invisible = band(s.data[1], 16) == 0
  else
    s.invisible = false
  end
end

function Title:bannerTemplate()
  return Machine.template(self:sprite("press_start"), { paletteTag = TAG_PRESS_START_COPYRIGHT, callback = pressStartCb })
end

-- pokeemerald/src/title_screen.c:425
function Title:createPressStartBanner(x, y)
  local sp = self.m.ppu.sprites
  x = x - 64
  for i = 0, NUM_PRESS_START_FRAMES - 1 do
    local s = sp:get(sp:create(self:bannerTemplate(), x, y, 0))
    Sprites.startAnim(s, i)
    s.data[0] = 1
    x = x + 32
  end
end

-- pokeemerald/src/title_screen.c:439
function Title:createCopyrightBanner(x, y)
  local sp = self.m.ppu.sprites
  x = x - 64
  for i = 0, NUM_PRESS_START_FRAMES - 1 do
    local s = sp:get(sp:create(self:bannerTemplate(), x, y, 0))
    Sprites.startAnim(s, i + NUM_PRESS_START_FRAMES)
    x = x + 32
  end
end

-- pokeemerald/src/title_screen.c:684
function Title:phase1(id, d)
  local m, ppu = self.m, self.m.ppu
  if m:joyNew(A_B_START_SELECT) or d[1] ~= 0 then
    d[1] = 1
    d[0] = 0
  end
  if d[0] ~= 0 then
    local frameNum = d[0]
    if frameNum == 176 then
      self:startShine(SHINE_MODE_DOUBLE)
    elseif frameNum == 64 then
      self:startShine(SHINE_MODE_SINGLE)
    end
    d[0] = d[0] - 1
  else
    ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON))
    ppu:set("WININ", 0)
    ppu:set("WINOUT", 0)
    ppu:set("BLDCNT", bor(Ppu.BLDCNT_TGT1_OBJ, Ppu.BLDCNT_EFFECT_BLEND, Ppu.BLDCNT_TGT2_ALL))
    ppu:set("BLDALPHA", Ppu.blendAlpha(16, 0))
    ppu:set("BLDY", 0)
    local sp = ppu.sprites
    local left = sp:get(sp:create(Machine.template(self:sprite("version_banner_left"),
      { paletteTag = TAG_VERSION, callback = function(s) self:bannerLeftCb(s) end }),
      VERSION_BANNER_LEFT_X, VERSION_BANNER_Y, 0))
    left.data[0] = #self.man.alphaBlend
    left.data[1] = id
    local right = sp:get(sp:create(Machine.template(self:sprite("version_banner_right"),
      { paletteTag = TAG_VERSION, callback = function(s) self:bannerRightCb(s) end }),
      VERSION_BANNER_RIGHT_X, VERSION_BANNER_Y, 0))
    right.data[1] = id
    d[0] = 144
    m.tasks:setFunc(id, function(i, dd) self:phase2(i, dd) end)
    self.phase = "phase2"
    self:mark("phase2")
  end
end

-- pokeemerald/src/title_screen.c:732
function Title:phase2(id, d)
  local m, ppu = self.m, self.m.ppu
  if m:joyNew(A_B_START_SELECT) or d[1] ~= 0 then
    d[1] = 1
    d[0] = 0
  end
  if d[0] ~= 0 then
    d[0] = d[0] - 1
  else
    d[1] = 1
    ppu:set("BLDCNT", bor(Ppu.BLDCNT_TGT1_BG1, Ppu.BLDCNT_EFFECT_BLEND, Ppu.BLDCNT_TGT2_BG0, Ppu.BLDCNT_TGT2_BD))
    ppu:set("BLDALPHA", Ppu.blendAlpha(6, 15))
    ppu:set("BLDY", 0)
    ppu:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON, Ppu.DISPCNT_BG1_ON,
      Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON))
    self:createPressStartBanner(START_BANNER_X, 108)
    self:createCopyrightBanner(START_BANNER_X, 148)
    d[4] = 0
    m.tasks:setFunc(id, function(i, dd) self:phase3(i, dd) end)
    self.phase = "phase3"
    self:mark("phase3")
  end
  if band(d[0], 3) == 0 and d[2] ~= 0 then d[2] = d[2] + 1 end
  if band(d[0], 1) == 0 and d[3] ~= 0 then d[3] = d[3] + 1 end
  ppu:set("BG2Y", d[3] * 256)
end

-- pokeemerald/src/title_screen.c:857
function Title:updateLegendaryMarkingColor(frameNum)
  if frameNum % 4 == 0 then
    local intensity = Cos(frameNum, 128) + 128
    local r = 31 - trunc(intensity * 31 / 256)
    local g = 31 - trunc(intensity * 22 / 256)
    self.m.ppu.palette:load({ Palette.rgb(r, g, 12) }, 14 * 16 + 15, 1)
  end
end

-- pokeemerald/src/title_screen.c:780
function Title:phase3(id, d)
  local m, ppu = self.m, self.m.ppu
  local pal = ppu.palette
  if m:joyNew(Machine.A_BUTTON) or m:joyNew(Machine.START_BUTTON) then
    audio().fadeOutBgm(4)
    pal:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA)
    self:leaveTo("menu")
  elseif m:joyHeld(CLEAR_SAVE_BUTTON_COMBO) == CLEAR_SAVE_BUTTON_COMBO then
    self:leaveTo({ combo = "clearSave" })
  elseif m:joyHeld(RESET_RTC_BUTTON_COMBO) == RESET_RTC_BUTTON_COMBO
      and self.canResetRtc and self.canResetRtc() == true then
    audio().fadeOutBgm(4)
    pal:beginFade(Palette.ALL, 0, 0, 16, Palette.BLACK)
    self:leaveTo({ combo = "resetRtc" })
  elseif m:joyHeld(BERRY_UPDATE_BUTTON_COMBO) == BERRY_UPDATE_BUTTON_COMBO then
    audio().fadeOutBgm(4)
    pal:beginFade(Palette.ALL, 0, 0, 16, Palette.BLACK)
    self:leaveTo({ combo = "berryFix", stopAll = true })
  else
    ppu:set("BG2Y", 0)
    d[0] = bit.tobit(d[0] + 1)
    if band(d[0], 1) ~= 0 then
      d[4] = d[4] + 1
      m.globals.battleBg1Y = math.floor(d[4] / 2)
      m.globals.battleBg1X = 0
    end
    self:updateLegendaryMarkingColor(band(d[0], 0xFF))
    if self.songFrames and (self.frames or 0) - self.songStart >= self.songFrames then
      pal:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA)
      self:leaveTo("copyright")
    end
  end
end

-- pokeemerald/src/title_screen.c:824
function Title:leaveTo(target)
  self:mark("leave " .. (type(target) == "table" and target.combo or target))
  self.m:setCb2(function()
    if self.m.ppu.palette:update() == 0 then
      if type(target) == "table" and target.stopAll then audio().stopAll() end
      self.result = target
      self.m:setCb2(nil)
    end
  end)
end

function Title:update(input)
  self.frames = (self.frames or 0) + 1
  self.m:frame(input)
  local r = self.result
  if r then
    self.result = nil
    return r
  end
  return nil
end

function Title:draw()
  self.m.ppu:draw(0, 0)
end

function Title:snapshot()
  return self.m.ppu:snapshot()
end

function Title:destroy()
end

return Title
