local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Affine = require("src.core.game3.bg_affine")
local Base = require("src.ui.game3.rse.title_rse")
local band, bor = bit.band, bit.bor
local Title = {}
Title.__index = Title
Title.MANIFEST = Base.MANIFEST
local TAG_VERSION, TAG_PRESS = 1000, 1001
local SKIP = bor(Machine.A_BUTTON, Machine.B_BUTTON, Machine.START_BUTTON, Machine.SELECT_BUTTON)
local CLEAR = bor(Machine.B_BUTTON, Machine.SELECT_BUTTON, Machine.DPAD_UP)
local RESET = bor(Machine.B_BUTTON, Machine.SELECT_BUTTON, Machine.DPAD_LEFT)
local function s16(v) v = band(v, 0xFFFF); return v < 0x8000 and v or v - 0x10000 end

function Title.songFrames(id)
  local Seq = require("src.core.game3.m4a_seq")
  local blob = assert(love.filesystem.read(string.format("data/generated/gba/audio/songs/%d.bin", id)), "RS title song missing")
  local p = Seq.newPlayer(Seq.parseSongBin(blob))
  for frame = 1, 1000000 do
    local done = true
    for _, track in ipairs(p.tracks) do if not track.done then done = false; break end end
    if done and p.tempoC + p.tempo >= 150 then return frame end
    Seq.update(p, 1)
  end
  return nil
end

function Title.new(machine, opts)
  opts = opts or {}
  local self = setmetatable({ m = machine, log = {}, phase = "init", frames = 0 }, Title)
  self.man = machine:manifest(Title.MANIFEST)
  assert(self.man.layout == "rs", "RS title needs native RS assets")
  self.params = assert(opts.params, "RS title profile parameters required")
  self.canResetRtc = opts.canResetRtc
  self.audio = opts.audio or require("src.core.game3.audio")
  self.songLength = opts.songFrames or Title.songFrames
  machine:setCb2(function() self:initCb() end)
  return self
end

function Title:mark(what) self.log[#self.log + 1] = { frame = self.frames, what = what } end
function Title:layer(key) return Machine.layer(assert(self.man.layers[key], "RS title layer " .. key)) end
function Title:sprite(key) return assert(self.man.sprites[key], "RS title sprite " .. key) end
function Title:alphaReg(i) local a = self.man.alphaBlend[i + 1]; return Ppu.blendAlpha(a[1], a[2]) end
function Title:vblankCb()
  self.m.ppu:vblank()
  self.m.ppu:set("BG1VOFS", band(self.m.globals.battleBg1Y, 0xFFFF))
end

-- pokeruby/src/title_screen.c:519
function Title:initCb()
  local m, p = self.m, self.m.ppu
  local pal, st = p.palette, m.state
  if st == 0 then
    m:setVBlank(nil)
    for _, r in ipairs({ "BLDCNT", "BLDALPHA", "BLDY", "DISPCNT", "BG2HOFS", "BG2VOFS",
      "BG1HOFS", "BG1VOFS", "BG0HOFS", "BG0VOFS" }) do p:set(r, 0) end
    for i = 0, 3 do p:setBg(i, 0, nil) end
    pal.pltt[0] = Palette.WHITE
    p.sprites.oamShown = {}
    pal:clearHardware(1)
    pal:resetFade()
    m.state = 1
  elseif st == 1 then
    pal:load(self.man.palettes.bg, 0, 256)
    self.logo, self.legendary, self.backdrop = self:layer("logo"), self:layer("legendary"), self:layer("backdrop")
    p.scanline:stop()
    m.tasks:reset()
    p.sprites:resetData()
    p.sprites:freeAllPalettes()
    p.sprites:setReservedPalettes(14)
    pal:load(self.man.palettes.version, 256, 224)
    p.sprites:loadPalette(TAG_PRESS, self.man.palettes.pressStart)
    m.state = 2
    m:addStall(self.man.game == "sapphire" and 3 or 2)
  elseif st == 2 then
    self.taskId = m.tasks:create(function(i, d) self:phase1(i, d) end, 0)
    local d = m.tasks:get(self.taskId).data
    d[0], d[1], d[2], d[3] = 256, 0, -16, -32
    m.state = 3
  elseif st == 3 then
    pal:beginFade(Palette.ALL, 1, 16, 0, Palette.WHITEALPHA)
    m:setVBlank(function() self:vblankCb() end)
    m.state = 4
  elseif st == 4 then
    p:setAffine(2, Affine.panFadeAndZoom(120, 80, 0x100, 0))
    p:set("BG2X", -29 * 256)
    p:set("BG2Y", -33 * 256)
    for _, r in ipairs({ "WIN0H", "WIN0V", "WIN1H", "WIN1V" }) do p:set(r, 0) end
    p:set("WININ", 0x1F1F)
    p:set("WINOUT", 0x3F1F)
    p:set("BLDCNT", 0x84)
    p:set("BLDALPHA", 0)
    p:set("BLDY", 8)
    p:setBg(0, 3, self.legendary, true)
    p:setBg(1, 2, self.backdrop, true)
    p:setBg(2, 1, self.logo, false)
    p:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG2_ON,
      Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_WIN0_ON, Ppu.DISPCNT_OBJWIN_ON))
    local song = require("src.core.game3.constants").of(self.man.game):require("songs", self.params.song)
    self.audio.playSong(song, { restart = true })
    self.songDuration, self.songStart = self.songLength(song), self.frames
    self:mark("song " .. self.params.song)
    m.state = 5
  elseif st == 5 and pal:update() == 0 then
    self:startShine(false)
    local w = p.scanline:initWave(0, 160, 4, 4, 0, "BG1HOFS", function() return m.globals.battleBg1X end)
    m.tasks:create(function(i) if not p.scanline:runWaveTask(w) then m.tasks:destroy(i) end end, 0)
    self.phase = "phase1"
    self:mark("phase1")
    m:setCb2(function() self:mainCb() end)
  end
end

function Title:mainCb()
  self.m.tasks:run(self)
  self.m.ppu.sprites:animateAll()
  self.m.ppu.sprites:buildOam()
  self.m.ppu.palette:update()
end

-- pokeruby/src/title_screen.c:463
function Title:shineCb(s, sp)
  local d, faded = s.data, self.m.ppu.palette.faded
  if self.m.tasks:get(self.taskId).data[1] == 0 and s.x < 272 then
    if d[0] ~= 0 then
      if s.x < 120 then d[1] = math.min(31, d[1] + 2) else d[1] = math.max(0, d[1] - 2) end
      local c = Palette.rgb(d[1], d[1], d[1])
      faded[0], faded[self.man.logoFlashPaletteIndex] = c, c
    end
    s.x = s.x + 4
  else
    faded[0], faded[self.man.logoFlashPaletteIndex] = Palette.BLACK, Palette.BLACK
    sp:destroy(s)
  end
end
function Title:startShine(flash)
  local sp = self.m.ppu.sprites
  local s = sp:get(sp:create(Machine.template(self:sprite("logo_shine"), {
    paletteTag = TAG_PRESS, callback = function(a, b) self:shineCb(a, b) end }), 0, 68, 0))
  s.oam.objMode, s.data[0] = Sprites.OBJ_WINDOW, flash and 1 or 0
  self:mark("shine " .. tostring(flash))
end

function Title:bannerLeftCb(s)
  local d = self.m.tasks:get(s.data[1]).data
  if d[1] ~= 0 then s.oam.objMode, s.y, s.invisible = Sprites.OBJ_NORMAL, 66, false
  else
    if d[5] ~= 0 then d[5] = d[5] - 1 end
    if d[5] < 64 then
      s.invisible = false
      if s.y ~= 66 then s.y = s.y + 1 end
      self.m.ppu:set("BLDALPHA", self:alphaReg(math.floor(d[5] / 2)))
    end
  end
end
function Title:bannerRightCb(s)
  local d = self.m.tasks:get(s.data[1]).data
  if d[1] ~= 0 then s.oam.objMode, s.y, s.invisible = Sprites.OBJ_NORMAL, 66, false
  elseif d[5] < 64 then s.invisible = false; if s.y ~= 66 then s.y = s.y + 1 end end
end
local function pressCb(s)
  if s.data[0] == 1 then s.data[1] = s16(s.data[1] + 1); s.invisible = band(s.data[1], 16) == 0
  else s.invisible = false end
end
function Title:createTextBanners()
  local sp = self.m.ppu.sprites
  local template = Machine.template(self:sprite("press_start"), { paletteTag = TAG_PRESS, callback = pressCb })
  for i = 0, 7 do
    local press = i < 3
    local x, y = press and (88 + i * 32) or (56 + (i - 3) * 32), press and 108 or 148
    local s = sp:get(sp:create(template, x, y, 0))
    Sprites.startAnim(s, i)
    if press then s.data[0] = 1 end
  end
end

function Title:phase1(id, d)
  local m, p = self.m, self.m.ppu
  if m:joyNew(SKIP) or d[1] ~= 0 then d[1], d[0] = 1, 0 end
  if d[0] ~= 0 then
    if d[0] == 160 or d[0] == 64 then self:startShine(true) end
    d[0] = d[0] - 1
  else
    p:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON))
    p:set("WININ", 0); p:set("WINOUT", 0)
    p:set("BLDCNT", 0x3F50); p:set("BLDALPHA", 0x1F); p:set("BLDY", 0)
    for i, key in ipairs({ "version_banner_left", "version_banner_right" }) do
      local cb = i == 1 and function(s) self:bannerLeftCb(s) end or function(s) self:bannerRightCb(s) end
      local s = p.sprites:get(p.sprites:create(Machine.template(self:sprite(key), { paletteTag = TAG_VERSION, callback = cb }),
        i == 1 and 98 or 162, 26, 0))
      s.invisible, s.data[1] = true, id
    end
    d[5], d[0] = 88, 144
    m.tasks:setFunc(id, function(i, a) self:phase2(i, a) end)
    self.phase = "phase2"; self:mark("phase2")
  end
end
function Title:phase2(id, d)
  local m, p = self.m, self.m.ppu
  if m:joyNew(SKIP) or d[1] ~= 0 then d[1], d[0] = 1, 0 end
  if d[0] ~= 0 then d[0] = d[0] - 1
  else
    d[1] = 1
    p:set("DISPCNT", bor(Ppu.DISPCNT_MODE_1, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON,
      Ppu.DISPCNT_BG1_ON, Ppu.DISPCNT_BG2_ON, Ppu.DISPCNT_OBJ_ON))
    self:createTextBanners()
    d[4] = 0
    m.tasks:setFunc(id, function(i, a) self:phase3(i, a) end)
    self.phase = "phase3"; self:mark("phase3")
  end
  if band(d[0], 1) == 0 and d[3] ~= 0 then d[3] = d[3] + 1 end
  p:set("BG2Y", d[3] * 256)
end
function Title:updateLegendaryMarkingColor(frame)
  if frame % 4 == 0 then
    local c = band(math.floor(frame / 4), 31)
    if band(math.floor(frame / 4), 32) ~= 0 then c = 31 - c end
    local color = self.man.game == "sapphire" and Palette.rgb(c, 0, 0) or Palette.rgb(0, 0, c)
    self.m.ppu.palette:load({ color }, 0xEF, 1)
  end
end
function Title:phase3(_, d)
  local m, p = self.m, self.m.ppu
  p:set("BLDCNT", 0x2142); p:set("BLDALPHA", 0x1F0F); p:set("BLDY", 0)
  if m:joyNew(Machine.A_BUTTON) or m:joyNew(Machine.START_BUTTON) then
    self.audio.fadeOutBgm(4)
    p.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA)
    self:leaveTo("menu")
  else
    if m:joyHeld(CLEAR) == CLEAR then self:leaveTo({ combo = "clearSave" }) end
    if m:joyHeld(RESET) == RESET and self.canResetRtc and self.canResetRtc() == true then
      self.audio.fadeOutBgm(4)
      p.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.BLACK)
      self:leaveTo({ combo = "resetRtc" })
    else
      p:set("BG2Y", 0)
      d[0] = s16(d[0] + 1)
      if band(d[0], 1) ~= 0 then d[4] = s16(d[4] + 1); m.globals.battleBg1Y, m.globals.battleBg1X = d[4], 0 end
      self:updateLegendaryMarkingColor(band(d[0], 255))
      if self.songDuration and self.frames - self.songStart >= self.songDuration then
        p.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA)
        self:leaveTo("copyright")
      end
    end
  end
end
function Title:leaveTo(target)
  self:mark("leave " .. (type(target) == "table" and target.combo or target))
  self.m:setCb2(function()
    if self.m.ppu.palette:update() == 0 then self.result = target; self.m:setCb2(nil) end
  end)
end
function Title:update(input)
  self.frames = self.frames + 1
  self.m:frame(input)
  local r = self.result; self.result = nil; return r
end
function Title:draw() self.m.ppu:draw(0, 0) end
function Title:snapshot() return self.m.ppu:snapshot() end
function Title:destroy() end
return Title
