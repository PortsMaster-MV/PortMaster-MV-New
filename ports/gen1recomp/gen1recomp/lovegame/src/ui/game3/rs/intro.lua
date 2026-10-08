local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Trig = require("src.core.game3.trig")
local Rng = require("src.core.game3.rng")
local Scenery = require("src.ui.game3.rs.intro_credits_scenery")
local band, bor = bit.band, bit.bor
local Intro = {}; Intro.__index = Intro
Intro.MANIFEST = "data/generated/gba/intro/rs/manifest.lua"
Intro.TITLE = "data/generated/gba/title/manifest.lua"
Intro.SAVE_LOAD_STALL = { ruby = 27, ruby11 = 19, ruby12 = 19, sapphire = 26, sapphire11 = 15, sapphire12 = 15 }
local function s16(n) n = band(n, 65535); return n >= 32768 and n - 65536 or n end
local function div(a, b) local n = a / b; return n < 0 and -math.floor(-n) or math.floor(n) end
local function sine(i) return Trig.SINE[band(i, 255) + 1] end
local function sin(i, amp) return math.floor(sine(i) * amp / 256) end
local function setFunc(self, id, method) self.m.tasks:setFunc(id, function(i, d) self[method](self, i, d) end) end

function Intro.new(machine, opts)
  opts = opts or {}
  local self = setmetatable({ m = machine, log = {}, frames = 0, counter = 0, gender = 0, phase = "copyright", coldBoot = opts.coldBoot == true }, Intro)
  self.man = machine:manifest(Intro.MANIFEST); assert(self.man.layout == "rs", "RS intro needs native assets")
  self.alpha = machine:manifest(Intro.TITLE).alphaBlend
  self.audio = opts.audio or require("src.core.game3.audio")
  self.rng = opts.rng or Rng
  if opts.rtcSeed ~= nil then self.rng.SeedRng(opts.rtcSeed) end
  machine:setCb2(function() self:copyrightCb() end)
  return self
end
function Intro:mark(what) self.log[#self.log + 1] = { frame = self.frames, counter = self.counter, what = what } end
function Intro:pal(name) return assert(self.man.palettes[name], "RS intro palette " .. name) end
function Intro:layer(name) return Machine.layer(assert(self.man.layers[name], "RS intro layer " .. name)) end
function Intro:sprite(name) return assert(self.man.sprites[name], "RS intro sprite " .. name) end
function Intro:template(name, callback)
  local e = self:sprite(name)
  return Machine.template(e, { paletteTag = e.paletteTag, callback = callback })
end
function Intro:vblank() self.m.ppu:vblank() end
function Intro:resetGpu()
  for _, r in ipairs({ "DISPCNT", "BG3HOFS", "BG3VOFS", "BG2HOFS", "BG2VOFS", "BG1HOFS", "BG1VOFS", "BG0HOFS", "BG0VOFS", "BLDCNT", "BLDALPHA", "BLDY" }) do self.m.ppu:set(r, 0) end
end

-- pokeruby/src/intro.c:856
function Intro:copyrightCb()
  local m, p = self.m, self.m.ppu; local pal = p.palette
  if m.state == 0 then
    m:setVBlank(nil); self:resetGpu(); pal.pltt[0] = Palette.WHITE
    for i = 0, 3 do p:setBg(i, 0, nil) end
    p.sprites.oamShown = {}; pal:clearHardware(1); pal:resetFade()
    pal:load(self:pal("gIntroCopyright_Pal"), 0, 16)
    p.scanline:stop(); m.tasks:reset(); p.sprites:resetData(); p.sprites:freeAllPalettes()
    pal:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
    p:setBg(0, 0, self:layer("copyright"))
    m:setVBlank(function() self:vblank() end)
    p:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG0_ON))
    self:mark("copyright")
  end
  if m.state == 140 then
    pal:beginFade(Palette.ALL, 0, 0, 16, Palette.BLACK); m.state = 141; return
  elseif m.state == 141 then
    if pal:update() ~= 0 then return end
    self.taskId = m.tasks:create(function(i, d) self:scene1Load(i, d) end, 0)
    m:setCb2(function() self:mainCb() end)
    if self.coldBoot then m:addStall(assert(Intro.SAVE_LOAD_STALL[self.man.build], "RS revision timing missing")) end
    return
  end
  pal:update(); m.state = m.state + 1
end

-- pokeruby/src/intro.c:826
function Intro:mainCb()
  if self.loadTail then local tail = self.loadTail; self.loadTail = nil; tail()
  else self.m.tasks:run(self) end
  if self.blockMain then self.blockMain = nil; return end
  self.m.ppu.sprites:animateAll(); self.m.ppu.sprites:buildOam(); self.m.ppu.palette:update()
  if self.m.newKeys ~= 0 and not self.m.ppu.palette:fadeActive() then
    self:mark("skip"); self.m:setCb2(function() self:endCb() end)
  elseif self.counter ~= -1 then self.counter = self.counter + 1 end
end
-- pokeruby/src/intro.c:838
function Intro:endCb()
  if self.m.ppu.palette:update() == 0 then self.done = true; self.m:setCb2(nil); self:mark("title handoff") end
end

-- pokeruby/src/intro.c:946
function Intro:scene1Load(id, d)
  local m, p = self.m, self.m.ppu; local sp, pal = p.sprites, p.palette
  m:setVBlank(nil); self.gender = band(self.rng.Random(), 1); self:mark("rider " .. self.gender); self:resetGpu()
  for i, offset in ipairs({ 40, 24, 80, 0 }) do p:set("BG" .. (i - 1) .. "VOFS", offset); p:setBg(i - 1, i - 1, self:layer("scene1_bg" .. (i - 1))) end
  pal:load(self:pal("intro.o:gIntro1BGPals"), 0, 256)
  sp:loadPalette(2000, self:pal("intro.o:Palette_406340")); sp:loadPalette(2001, self:pal("intro.o:Palette_406360")); sp:loadPalette(2002, self:pal("intro.o:gIntro1EonPalette"))
  for k = 0, 6 do pal:copyUnfaded(256, 256 + (15 - k) * 16 + k, 16 - k) end
  d[0] = self:createWaterDrop(236, -14, 512, 1, 120, false)
  self.blockMain = true; m:addStall(2)
  self.loadTail = function() setFunc(self, id, "scene1FadeIn") end
end
-- pokeruby/src/intro.c:983
function Intro:scene1FadeIn(id)
  local m, p = self.m, self.m.ppu
  p.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.BLACK); m:setVBlank(function() self:vblank() end)
  p:set("DISPCNT", bor(Ppu.DISPCNT_MODE_0, Ppu.DISPCNT_OBJ_1D_MAP, Ppu.DISPCNT_BG_ALL_ON, Ppu.DISPCNT_OBJ_ON))
  setFunc(self, id, "scene1WaterDrops"); self.counter = 0; self.phase = "scene1"
  self.audio.playSong("MUS_INTRO", { restart = true }); self:mark("scene1")
end
-- pokeruby/src/intro.c:994
function Intro:scene1WaterDrops(id, d)
  local c, sp = self.counter, self.m.ppu.sprites
  if c == 76 then sp:get(d[0]).data[0] = 1 end
  if c == 251 then sp:get(d[0]).data[0] = 2 end
  if c == 368 then self:createWaterDrop(48, 0, 1024, 5, 112, true) end
  if c == 384 then self:createWaterDrop(200, 60, 1024, 9, 128, true) end
  if c == 560 then
    local task = self.m.tasks:create(function(i, a) self:blendLogo(i, a) end, 0)
    self:createGameFreakLogo(120, 80, task)
  end
  if c > 739 then d[1], d[2], d[3], d[4], d[5], d[6] = 80, 0, 24, 0, 40, 0; setFunc(self, id, "scene1Scroll"); self:mark("pan") end
end
-- pokeruby/src/intro.c:1024
function Intro:scene1Scroll(id, d)
  if self.counter < 904 then
    for _, row in ipairs({ { 1, 2, 0xC000, 2 }, { 3, 4, 0x10000, 1 }, { 5, 6, 0x18000, 0 } }) do
      local n = d[row[1]] * 65536 + band(d[row[2]], 65535) - row[3]
      d[row[1]], d[row[2]] = math.floor(n / 65536), s16(n)
      self.m.ppu:set("BG" .. row[4] .. "VOFS", d[row[1]])
    end
    if self.counter == 880 then
      local sp = self.m.ppu.sprites
      local s = sp:get(sp:create(self:template("eon_silhouette", function(a) self:eonSilhouette(a) end), 200, 160, 10)); s.invisible = true
    end
  elseif self.counter > 1007 then
    self.m.ppu.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA); setFunc(self, id, "scene1Wait"); self:mark("scene1 fade out")
  end
end
-- pokeruby/src/intro.c:1063
function Intro:scene1Wait(id) if self.counter > 1026 then setFunc(self, id, "scene2Load"); self:mark("bike load") end end
-- pokeruby/src/intro.c:1069
function Intro:scene2Load(id)
  local m, p = self.m, self.m.ppu
  self:resetGpu(); m:setVBlank(nil); p.sprites:resetData(); p.sprites:freeAllPalettes()
  m.globals.movingSceneryVBase, m.globals.movingSceneryVOffset = 0, 0
  self.scene2Mode = self.man.game == "sapphire" and 0 or 1
  self.blockMain = true
  self.loadTail = function()
    Scenery.loadIntro(m, self.scene2Mode); setFunc(self, id, "scene2Start")
    self.blockMain, self.part2TailPending = true, true
  end
end
-- pokeruby/src/intro.c:1085
function Intro:scene2Start(id, d)
  local m, p = self.m, self.m.ppu
  if self.part2TailPending then
    self.part2TailPending = nil
    p.sprites:animateAll(); p.sprites:buildOam(); p.palette:update(); self.counter = self.counter + 1
  end
  self.blockMain = true; m:addStall(2)
  self.loadTail = function()
    Scenery.loadRiderEonPalettes(m)
    d[1] = Scenery.createRider(m, self.gender, 272, 100, function(s) self:riderCb(s) end)
    d[2] = Scenery.createEon(m, -64, 60, function(s) self:bikeEonCb(s) end)
    p.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
    m:setVBlank(function() self:vblank() end)
    d[0] = Scenery.createBgTask(m, self.scene2Mode, 0x4000, self.scene2Mode == 0 and 0x40 or 0x400, 0x10)
    Scenery.showIntro(m); setFunc(self, id, "scene2Move")
    Scenery.bicycleBgTask(d[0], m.tasks:get(d[0]).data, m)
    self.phase = "scene2"; self:mark("bike start")
  end
end
-- pokeruby/src/intro.c:1126
function Intro:scene2Move(id, d)
  local c, sp = self.counter, self.m.ppu.sprites
  if c > 1823 then
    self.m.ppu.palette:beginFade(Palette.ALL, 16, 0, 16, Palette.WHITEALPHA)
    setFunc(self, id, "scene2Wait"); self:mark("bike fade out")
  end
  for _, row in ipairs({ { 1109, 1, 1 }, { 1214, 1, 0 }, { 1394, 2, 1 }, { 1398, 1, 2 }, { 1586, 1, 3 }, { 1727, 1, 4 } }) do
    if c == row[1] then sp:get(d[row[2]]).data[0] = row[3] end
  end
  self.m.globals.movingSceneryVOffset = sin(band(math.floor(band(d[3], 65535) / 4), 127), 48)
  if d[3] < 512 then d[3] = d[3] + 1 end
  Scenery.cyclePalette(self.m, self.scene2Mode)
end
-- pokeruby/src/intro.c:1162
function Intro:scene2Wait(id, d)
  if self.counter > 2068 then self.m.tasks:destroy(d[0]); setFunc(self, id, "scene3Load"); self:mark("battle ball load") end
end

-- pokeruby/src/intro.c:1885
function Intro:riderCb(s)
  local state, c = s.data[0], self.counter
  local anim = state == 2 and 2 or state == 3 and 3 or 0
  if s.animNum ~= anim then Sprites.startAnim(s, anim) end
  if state == 0 then s.x = s.x - 1
  elseif state == 1 then if band(c, 7) ~= 0 then return end; s.x = s.x + 1
  elseif state == 2 then if s.x <= 120 or band(c, 7) ~= 0 then s.x = s.x + 1 end
  elseif state == 4 and s.x > -32 then s.x = s.x - 2 end
  if band(c, 7) ~= 0 then return end
  if s.y2 ~= 0 then s.y2 = 0 else
    local roll = band(self.rng.Random(), 3); s.y2 = roll == 0 and -1 or roll == 1 and 1 or 0
  end
end
-- pokeruby/src/intro.c:1939
function Intro:bikeEonCb(s)
  local d = s.data
  if d[0] == 1 then if s.x2 + s.x < 304 then s.x2 = s.x2 + 8 else d[0] = 2 end
  elseif d[0] == 2 then if s.x2 + s.x > 120 then s.x2 = s.x2 - 1 else d[0] = 3 end
  elseif d[0] == 3 and s.x2 > 0 then s.x2 = s.x2 - 2 end
  s.y2 = sin(d[1], 8) - self.m.globals.movingSceneryVOffset; d[1] = s16(d[1] + 4)
end

-- pokeruby/src/intro.c:1502
function Intro:blendLogo(id, d)
  local p = self.m.ppu
  local function alpha(i) local row = self.alpha[i + 1]; p:set("BLDALPHA", Ppu.blendAlpha(row[1], row[2])) end
  if d[0] == 0 then p:set("BLDCNT", 0x3F50); p:set("BLDALPHA", 0x1000); p:set("BLDY", 0); d[1], d[0] = 64, 1
  elseif d[0] == 1 then
    if d[1] ~= 0 then d[1] = d[1] - 1; alpha(math.floor(d[1] / 2)) else alpha(0); d[1], d[0] = 128, 2 end
  elseif d[0] == 2 then if d[1] ~= 0 then d[1] = d[1] - 1 else d[1], d[0] = 0, 3 end
  elseif d[0] == 3 then
    if d[1] <= 61 then d[1] = d[1] + 1; alpha(math.floor(d[1] / 2)) else alpha(31); d[1], d[0] = 16, 4 end
  elseif d[0] == 4 then
    if d[1] ~= 0 then d[1] = d[1] - 1 else p:set("BLDCNT", 0); p:set("BLDALPHA", 0); p:set("BLDY", 0); self.m.tasks:destroy(id) end
  end
end
-- pokeruby/src/intro.c:1964
function Intro:letterCb(s, sp)
  local state = self.m.tasks:get(s.data[0]).data[0]
  if state == 0 then s.invisible = true elseif state ~= 4 then s.invisible = false else sp:destroy(s) end
end
-- pokeruby/src/intro.c:1980
function Intro:createGameFreakLogo(x, y, task)
  local sp = self.m.ppu.sprites
  for _, spec in ipairs({ { "gf_letters", self.man.tables.gameFreakLetters, -4 }, { "gf_small_letters", self.man.tables.gameFreakSmallLetters, 12 } }) do
    for _, row in ipairs(spec[2]) do
      local s = sp:get(sp:create(self:template(spec[1], function(a, b) self:letterCb(a, b) end), x + row[2], y + spec[3], 0))
      s.data[0] = task; Sprites.startAnim(s, row[1])
    end
  end
  local s = sp:get(sp:create(self:template("gf_logo", function(a, b) self:letterCb(a, b) end), 120, y - 4, 0)); s.data[0] = task
end
-- pokeruby/src/intro.c:2003
function Intro:eonSilhouette(s)
  local d, sp = s.data, self.m.ppu.sprites; d[7] = s16(d[7] + 1)
  if d[0] == 0 then
    s.oam.affineMode, s.oam.matrixNum = 3, 1; Sprites.calcCenterToCornerVec(s, 1, 3, 3)
    s.invisible = false; d[0], d[1], d[2], d[3] = 1, 128, -24, 0
  else
    if d[3] < 80 then s.y2, s.x2 = -sin(d[3], 120), -sin(d[3], 140); if d[3] > 64 then s.oam.priority = 3 end end
    local sn, cs = sine(d[2]), sine(d[2] + 64)
    sp:setMatrix(1, s16(div(cs * d[1], 256)), s16(div(sn * d[1], 256)), s16(div(-sn * d[1], 256)), s16(div(cs * d[1], 256)))
    d[1] = s16(d[1] + (d[1] < 256 and 8 or 32))
    if d[2] < 24 then d[2] = d[2] + 1 end
    if d[3] < 64 then d[3] = d[3] + 2 elseif band(d[7], 3) == 0 then d[3] = d[3] + 1 end
  end
end

-- pokeruby/src/intro.c:1649
function Intro:dropRippleCb(s, sp)
  local d = s.data
  if d[2] >= 192 then
    if d[3] ~= 0 then d[3] = d[3] - 1 else
      s.invisible = false; sp:setMatrix(d[1], d[2], 0, 0, d[2]); d[2] = div(d[2] * 95, 100)
      s.oam.paletteNum = math.min(15, div(d[2] - 192, 128) + 9)
    end
  else sp:destroy(s) end
end
function Intro:toRipple(s)
  s.invisible = true; s.x, s.y = s.x + s.x2, s.y + s.y2
  s.sheet = Machine.sheet(self:sprite("water_drop_ripple")); s.anims = self.rippleAnims; Sprites.startAnim(s, 3)
  s.data[2], s.data[3] = 1024, 8 * band(s.data[1], 3)
  s.callback = function(a, b) self:dropRippleCb(a, b) end
  Sprites.setShape(s, 64, 32); Sprites.calcCenterToCornerVec(s, 1, 3, 2)
end
-- pokeruby/src/intro.c:1676
function Intro:dropHalfCb(s, sp)
  local parent = sp:get(s.data[7])
  if parent.data[7] ~= 0 then self:toRipple(s) else s.x2, s.y2, s.x, s.y = parent.x2, parent.y2, parent.x, parent.y end
end
-- pokeruby/src/intro.c:1706
function Intro:dropSlideCb(s)
  local d, sp = s.data, self.m.ppu.sprites
  if s.x <= 116 then
    s.y = s.y + s.y2; s.y2 = 0; s.x = s.x + 4; s.x2 = -4; d[4] = 128
    s.callback = function(a) self:dropReachLeafEndCb(a) end; return
  end
  local sin1, sin2 = sine(d[4]), sine(d[4] + 64); d[4] = s16(d[4] + 2)
  s.y2 = div(sin1, 32); s.x = s.x - 1; if band(s.x, 1) ~= 0 then s.y = s.y + 1 end
  local t = div(-sin2, 16); local sin3, sin4 = sine(t - 16), sine(t + 48)
  local a, b, c, e = div(sin4 * band(d[2], 65535), 256), div(-sin3 * band(d[3], 65535), 256), div(sin3 * band(d[2], 65535), 256), div(sin4 * band(d[3], 65535), 256)
  sp:setMatrix(d[1], d[2], 0, 0, d[3]); sp:setMatrix(d[1] + 1, a, c, b, e); sp:setMatrix(d[1] + 2, a, c, b * 2, e * 2)
end
-- pokeruby/src/intro.c:1755
function Intro:dropReachLeafEndCb(s)
  local d, sp = s.data, self.m.ppu.sprites
  for i = 0, 2 do sp:setMatrix(d[1] + i, d[6] + 64, 0, 0, d[6] + 64) end
  if d[4] ~= 64 then d[4] = s16(d[4] - 8); s.x2, s.y2 = div(sine(d[4] + 64), 64), div(sine(d[4]), 64)
  else d[4] = 0; s.callback = function(a) self:dropDangleCb(a) end end
end
-- pokeruby/src/intro.c:1776
function Intro:dropDangleCb(s)
  local d = s.data
  if d[0] ~= 2 then d[4] = s16(d[4] + 8); local n = div(sine(d[4]), 16) + 64; s.x2, s.y2 = div(sine(n + 64), 64), div(sine(n), 64)
  else s.callback = function(a) self:dropFallCb(a) end end
end
-- pokeruby/src/intro.c:1793
function Intro:dropFallCb(s) if s.y < s.data[5] then s.y = s.y + 4 else s.data[7] = 1; self:toRipple(s) end end
-- pokeruby/src/intro.c:1838
function Intro:createWaterDrop(x, y, scale, matrix, endY, immediately)
  local sp = self.m.ppu.sprites
  if not self.rippleAnims then
    self.rippleAnims = {}
    for i, a in ipairs(self:sprite("water_drop").anims) do
      local list = {}; for j, cmd in ipairs(a) do local row = {}; for k, v in pairs(cmd) do row[k] = v end
        if i == 4 and row.op == "frame" then row.frame = 0 end; list[j] = row end
      self.rippleAnims[i] = list
    end
  end
  local function make(callback) local id = sp:create(self:template("water_drop", callback), x, y, 0); return id, sp:get(id) end
  local parentId, s = make(nil)
  s.data[0], s.data[7], s.data[1], s.data[2], s.data[3], s.data[5], s.data[6] = 0, 0, matrix, scale, scale, endY, scale
  s.oam.affineMode, s.oam.matrixNum = 3, matrix; Sprites.calcCenterToCornerVec(s, 0, 2, 2); Sprites.startAnim(s, 2)
  s.callback = immediately and function(a) self:dropFallCb(a) end or function(a) if a.data[0] ~= 0 then a.callback = function(b) self:dropSlideCb(b) end end end
  for i = 1, 2 do
    local _, part = make(function(a, b) self:dropHalfCb(a, b) end)
    part.data[7], part.data[1], part.oam.affineMode, part.oam.matrixNum = parentId, matrix + i, 3, matrix + i
    Sprites.calcCenterToCornerVec(part, 0, 2, 2); if i == 2 then Sprites.startAnim(part, 1) end
  end
  sp:setMatrix(matrix, scale + 32, 0, 0, scale + 32); sp:setMatrix(matrix + 1, scale + 32, 0, 0, scale + 32); sp:setMatrix(matrix + 2, scale + 32, 0, 0, 2 * (scale + 32))
  return parentId
end

function Intro:update(input)
  self.frames = self.frames + 1; self.rng.Random(); self.m:frame(input)
  return self.done and "title" or nil
end
function Intro:draw() self.m.ppu:draw(0, 0) end
function Intro:snapshot() return self.m.ppu:snapshot() end
function Intro:destroy() end
for name, callback in pairs(require("src.ui.game3.rs.intro_battle")) do Intro[name] = callback end
return Intro
