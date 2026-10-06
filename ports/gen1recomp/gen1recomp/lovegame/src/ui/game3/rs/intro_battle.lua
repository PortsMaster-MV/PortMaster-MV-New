local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Affine = require("src.core.game3.bg_affine")
local Trig = require("src.core.game3.trig")
local band = bit.band
local B = {}
local function s16(n) n = band(n, 65535); return n >= 32768 and n - 65536 or n end
local function div(a, b) local n = a / b; return n < 0 and -math.floor(-n) or math.floor(n) end
local function sine(i) return Trig.SINE[band(i, 255) + 1] end
local function sin(i, a) return math.floor(sine(i) * a / 256) end
local function setFunc(self, id, name) self.m.tasks:setFunc(id, function(i, d) self[name](self, i, d) end) end
local function sprite(self, name, x, y, priority, method)
  local sp = self.m.ppu.sprites
  return sp:get(sp:create(self:template(name, function(s) self[method](self, s) end), x, y, priority))
end
local function matrix(sp, index, scale, flip) sp:setMatrix(index, flip and -scale or scale, 0, 0, scale) end

-- pokeruby/src/intro.c:1171
function B:scene3Load(id, d)
  local m, p = self.m, self.m.ppu
  self:resetGpu(); p:setBg(2, 3, self:layer("pokeball"))
  p.palette:load(self:pal("intro.o:gIntro3PokeballPal"), 0, 256)
  p:setAffine(2, Affine.panFadeAndZoom(120, 80, 0, 0))
  p.sprites:resetData(); p.sprites:freeAllPalettes()
  self.blockMain = true
  self.loadTail = function()
    for i = 0, 3 do d[i] = 0 end
    p.palette:beginFade(Palette.ALL, 0, 16, 0, Palette.WHITEALPHA)
    p:set("DISPCNT", 0x1441); setFunc(self, id, "scene3Spin")
    self.counter, self.phase = 0, "scene3"
    self.audio.playSong("MUS_INTRO_BATTLE", { restart = true }); self:mark("spinning ball")
  end
end
-- pokeruby/src/intro.c:1192
function B:scene3Spin(id, d)
  d[0] = s16(d[0] + 0x400)
  if d[1] <= 0x6BF then d[1], d[2] = d[1] + d[2], d[2] + 1 else setFunc(self, id, "scene3WaitBattle") end
  self.m.ppu:setAffine(2, Affine.panFadeAndZoom(120, 80, d[1] == 0 and 0 or div(65536, d[1]), d[0]))
  if self.counter == 44 then self.m.ppu.palette:beginFade(Palette.ALL, 0, 0, 16, Palette.WHITEALPHA) end
end
-- pokeruby/src/intro.c:1209
function B:scene3WaitBattle(id) if self.counter > 59 then setFunc(self, id, "battleLoad"); self:mark("battle streak load") end end
-- pokeruby/src/intro.c:1629
function B:battleColor(mode)
  local color = ({ 0x3FF6, 0x31DF, 0x518C })[mode + 1]
  local pal = self.m.ppu.palette; pal.unfaded[241], pal.faded[241] = color, color
end
-- pokeruby/src/intro.c:1215
function B:battleLoad(id)
  local p, sp = self.m.ppu, self.m.ppu.sprites
  self:resetGpu()
  p:setBg(3, 3, self:layer("battle_floor")); p:setBg(0, 0, self:layer("battle_bars")); p:setBg(2, 3, self:layer("battle_streaks"))
  p.palette.unfaded[240], p.palette.faded[240] = Palette.WHITE, Palette.WHITE
  self:battleColor(1); p.palette.unfaded[242], p.palette.faded[242] = Palette.BLACK, Palette.BLACK
  p.palette:load(self:pal("intro.o:gIntro3Streaks_Pal"), 0, 16)
  sp:resetData(); sp:freeAllPalettes(); sp:setReservedPalettes(8)
  sp:loadPalette(self:sprite("battle_ball").paletteTag, self:pal("gInterfacePal_PokeBall"))
  sp:loadPalette(self:sprite("battle_ball_particle").paletteTag, self:pal("intro.o:gIntro3Misc1Palette"))
  sp:loadPalette(self:sprite("battle_dust").paletteTag, self:pal("intro.o:gIntro3Misc2Palette"))
  self.blockMain = true; self.loadTail = function() setFunc(self, id, "battleWindowSetup") end
end
-- pokeruby/src/intro.c:1252
function B:battleWindowSetup(id, d)
  local p = self.m.ppu
  p:set("WIN0H", 0x00F0); p:set("WIN0V", 0x00A0); p:set("WININ", 0x1C); p:set("WINOUT", 0x1D); p:set("DISPCNT", 0x3940)
  d[15] = self.m.tasks:create(function(i, a) self:battleBg(i, a) end, 0)
  d[0] = 0; setFunc(self, id, "battleWindowOpen")
end
-- pokeruby/src/intro.c:1273
function B:battleWindowOpen(id, d)
  if d[0] ~= 32 then local old = d[0]; d[0] = d[0] + 4; self.m.ppu:set("WIN0V", d[0] * 256 - (old - 156))
  else self.m.ppu:set("WIN0V", 0x2080); setFunc(self, id, "battleWindowWait") end
end
function B:battleWindowWait(id) setFunc(self, id, "battleStart") end
function B:battleStart(id) self.stopBattleEffects = false; setFunc(self, id, "battleMove"); self:mark("double battle") end
-- pokeruby/src/intro.c:1596
function B:battleMon(name, x, y, palette, method)
  local sp, p = self.m.ppu.sprites, self.m.ppu.palette
  p:load(self:pal(name), 256 + palette * 16, 16)
  local s = sp:get(sp:create(Machine.template(self:sprite(name), { callback = function(a) self[method](self, a) end }), x, y, (palette + 1) * 4))
  s.oam.paletteNum, s.oam.priority = palette, 1
  return s
end
-- pokeruby/src/intro.c:1311
function B:battleMove(id, d)
  local c, sp, tasks, pal = self.counter, self.m.ppu.sprites, self.m.tasks, self.m.ppu.palette
  if c == 80 or c == 152 then
    local s = self:battleMon(c == 80 and "sharpedo_front" or "duskull_front", c == 80 and 240 or 0, 160, c == 80 and 5 or 4, "battleEnemyJump")
    s.data[1], s.data[2] = c == 80 and 1 or 2, c == 80 and 0 or 1
  elseif c == 219 then
    self:battleColor(0)
    local name = self.gender == 0 and "trainer_brendan" or "trainer_may"
    pal:load(self:pal(name), 352, 16)
    local s = sp:get(sp:create(Machine.template(self:sprite(name), { callback = function(a) self:battleTrainer(a) end }), 272, 96, 1))
    s.oam.paletteNum, s.oam.priority, d[1] = 6, 1, s.id
  elseif c == 304 then tasks:get(d[15]).data[0], sp:get(d[1]).data[0] = 4, 2
  elseif c == 384 then tasks:get(d[15]).data[0], sp:get(d[1]).data[0] = 0, 4
  elseif c == 400 then pal:beginFade(0xFF0000, 0, 16, 0, 0x7EFF)
  elseif c == 432 then sp:get(d[1]).data[0] = 5
  elseif c == 462 then sp:get(d[1]).data[0], tasks:get(d[15]).data[0] = 6, 2
  elseif c == 463 then
    self:battleColor(1); local s = self:battleMon("sharpedo_front", 208, 8, 5, "battleAttackFront"); d[2] = s.id
    local e = sprite(self, "battle_dust_burst", 0, 0, 0, "battleDustEmitter"); e.data[0], e.data[1], e.data[3] = s.id, -12, 136
  elseif c == 539 then
    local s = self:battleMon("duskull_front", 248, 16, 4, "battleAttackFront"); d[3] = s.id
    for i = 0, 7 do local e = sprite(self, "sharpedo_wave", s.x, s.y, 0, "battleOrbit"); e.data[0], e.data[1] = s.id, i * 32 end
  elseif c == 623 then sp:get(d[2]).data[0], sp:get(d[3]).data[0], tasks:get(d[15]).data[0] = 2, 2, 3
  elseif c == 624 then
    self:battleColor(0); local s = self:battleMon("mudkip_back", 32, 152, 0, "battleAttackBack"); d[4] = s.id
    local e = sprite(self, "mudkip_water", 0, 0, 0, "battleWaterEmitter"); e.data[0], e.data[2], e.data[3] = s.id, 12, 24
  elseif c == 700 then
    local s = self:battleMon("torchic_back", -8, 144, 1, "battleAttackBack"); d[5] = s.id
    local e = sprite(self, "attack_smoke", 0, 0, 0, "battleSmokeEmitter"); e.data[0], e.data[2], e.data[3] = s.id, 8, 24
    for i, scale in ipairs(self.man.tables.smokeScales) do matrix(sp, i + 17, scale[1], false) end
  elseif c == 776 then self.stopBattleEffects = true; sp:get(d[4]).data[0], sp:get(d[5]).data[0], tasks:get(d[15]).data[0] = 2, 2, 0
  elseif c == 781 then
    self:battleColor(2); for i = 2, 5 do sp:get(d[i]).data[0] = 3 end
    sprite(self, "battle_blast", 120, 80, 15, "battleBlast").invisible = true
  elseif c == 800 then self.audio.playSe("SE_INTRO_BLAST")
  elseif c == 850 then pal:beginFade(Palette.ALL, 4, 0, 16, Palette.WHITEALPHA)
  elseif c == 946 then setFunc(self, id, "battleFinish") end
end
-- pokeruby/src/intro.c:1440
function B:battleFinish(id) self.m.tasks:destroy(id); self.m:setCb2(function() self:endCb() end); self:mark("battle end") end
-- pokeruby/src/intro.c:1446
function B:battleBg(id, d)
  local p = self.m.ppu; d[15] = s16(d[15] + 1)
  if d[0] == 0 then p:set("DISPCNT", 0x3940); d[0] = 255; return end
  if d[0] == 2 or d[0] == 3 or d[0] == 4 then
    local state = d[0]
    p.palette:beginFade(1, state == 4 and 5 or 0, state == 4 and 0 or 16, state == 4 and 16 or 0, state == 4 and 0x37F7 or Palette.WHITEALPHA)
    p:set("DISPCNT", 0x3D40); d[1], d[2] = 0, 0; d[0] = state * 10
    if state == 4 then d[3] = 8 end
  end
  if d[0] == 20 or d[0] == 30 or d[0] == 40 then
    p:set("BG2VOFS", d[1]); p:set("BG2HOFS", d[2])
    local vy, vx = 6, -8
    if d[0] == 30 then vy, vx = -6, 8 elseif d[0] == 40 then vy, vx = -d[3], d[3] end
    d[1], d[2] = s16(d[1] + vy), s16(d[2] + vx)
    if d[0] == 40 and band(d[15], 7) == 0 and d[3] ~= 0 then d[3] = d[3] - 1 end
  end
end

-- pokeruby/src/intro.c:2059
function B:battleEnemyJump(s)
  local d, sp = s.data, self.m.ppu.sprites
  if d[0] == 0 then s.hFlip = d[2] ~= 0; d[0] = 1 end
  if d[0] == 1 then
    if s.y > 96 then s.y, s.x = s.y - 4, s.x + (d[2] ~= 0 and 2 or -2) else d[0], d[3] = 2, 8 end
  elseif d[0] == 2 then if d[3] ~= 0 then d[3] = d[3] - 1 else d[0], d[3] = 3, 0 end
  elseif d[0] == 3 then
    s.oam.affineMode, s.oam.matrixNum = 3, d[1]; Sprites.calcCenterToCornerVec(s, 0, 3, 3)
    matrix(sp, d[1], 256, d[2] ~= 0); d[0], d[4] = 4, 0
  elseif d[0] == 4 then
    d[4] = d[4] + 1
    if s.y + s.y2 > -32 and s.x + s.x2 > -64 then
      s.y2 = div(-d[4] * d[4], 8); s.x2 = s.x2 + (d[2] ~= 0 and d[4] or -d[4])
      if d[3] < 128 then d[3] = d[3] + 8 end
      matrix(sp, d[1], 256 - d[3], d[2] ~= 0)
    else sp:destroy(s) end
  end
end
-- pokeruby/src/intro.c:2128
function B:battleMonGrow(s)
  local d, sp = s.data, self.m.ppu.sprites
  if d[0] == 0 then s.invisible = false; s.oam.affineMode, s.oam.matrixNum = 1, d[1]; d[3], d[0] = 2048, 1 end
  if d[0] == 1 then
    if d[3] > 256 then d[3] = d[3] - 128 else d[0] = 2 end
    matrix(sp, d[1], d[3], d[2] ~= 0)
  elseif d[0] == 3 then d[4] = d[4] + 1; s.y2 = div(d[4] * d[4], 32); s.x2 = div(d[4], 4) * (d[2] ~= 0 and 1 or -1) end
end
-- pokeruby/src/intro.c:2171
function B:battleTrainer(s)
  local d, sp, pal = s.data, self.m.ppu.sprites, self.m.ppu.palette
  if d[0] == 0 then
    if s.x > 40 then s.x = s.x - 4 else
      Sprites.startAnim(s, 1); d[6] = sprite(self, "battle_ball", 16, 104, 100, "battleBall").id
      d[7] = sprite(self, "battle_ball", 12, 106, 101, "battleBall").id; d[0] = 1
    end
  elseif d[0] == 2 then Sprites.startAnim(s, 2); sp:get(d[6]).data[0], sp:get(d[7]).data[0], d[0] = 1, 2, 3
  elseif d[0] == 3 then if s.y > 160 then s.invisible, d[0] = true, 1 else s.y, s.x = s.y + 2, s.x - 1 end
  elseif d[0] == 4 then
    for _, spec in ipairs({ { 6, "torchic_front", 2, 1, 1 }, { 7, "mudkip_front", 3, 2, 0 } }) do
      local old = sp:get(d[spec[1]]); local x, y = old.x + old.x2, old.y + old.y2; sp:destroy(old)
      local mon = self:battleMon(spec[2], x, y, spec[3], "battleMonGrow")
      mon.invisible = true; mon.data[1], mon.data[2], d[spec[1]] = spec[4], spec[5], mon.id; self:battleParticles(x, y)
    end
    pal:beginFade(0xFF0000, 0, 16, 16, 0x7EFF); d[0] = 1
  elseif d[0] == 5 then sp:get(d[6]).data[0], sp:get(d[7]).data[0] = 3, 3
  elseif d[0] == 6 then sp:destroy(sp:get(d[6])); sp:destroy(sp:get(d[7])); sp:destroy(s) end
end
local function attack(s, direction)
  local d = s.data
  if d[0] == 0 then
    if s.x2 * direction < 56 then s.x2, s.y2 = s.x2 + direction * 8, s.y2 - direction * 6 else
      d[6], d[7] = s.x, s.y; s.x, s.y, s.x2, s.y2, d[0], d[1] = s.x + s.x2, s.y + s.y2, 0, 0, 1, 0
    end
  elseif d[0] == 1 then
    if band(d[1], 1) == 0 then local v = band(d[1], 2) ~= 0 and 1 or 0; s.x2, s.y2 = v * direction, -v * direction end
    d[1] = d[1] + 1
  elseif d[0] == 2 then s.invisible = true; s.x, s.y, s.x2, s.y2 = d[6], d[7], 0, 0
  elseif d[0] == 3 or d[0] == 4 then
    if d[0] == 3 then s.invisible = false; d[1] = d[1] + 1 end
    if s.x2 * direction < 56 then s.x2, s.y2 = s.x2 + direction * 4, s.y2 - direction * 3
    else s.x, s.y, s.x2, s.y2, d[0] = s.x + s.x2, s.y + s.y2, 0, 0, 1 end
  end
end
-- pokeruby/src/intro.c:2274
function B:battleAttackFront(s) attack(s, -1) end
function B:battleAttackBack(s) attack(s, 1) end
-- pokeruby/src/intro.c:2396
function B:battleBall(s)
  local d = s.data; d[7] = d[7] + 1
  if d[0] == 1 or d[0] == 2 then s.oam.affineMode, s.oam.matrixNum = 1, d[0]; d[0], d[4] = d[0] * 10, 36 end
  if d[0] == 10 or d[0] == 20 then
    local first = d[0] == 10
    if s.x <= (first and 144 or 96) then s.x, s.y, s.y2 = s.x + (first and 4 or 3), s.y - 1, -sin(d[2], 24); d[2] = d[2] + 4 end
    d[3] = s16(d[3] - d[4]); if band(d[7], 1) ~= 0 and d[4] ~= 0 then d[4] = d[4] - 1 end
    self.m.ppu.sprites:setMatrix(first and 1 or 2, sine(d[3] + 64), sine(d[3]), -sine(d[3]), sine(d[3] + 64))
  end
end
-- pokeruby/src/intro.c:2455
function B:battleParticle(s)
  local d, sp = s.data, self.m.ppu.sprites; d[7] = d[7] + 1; s.invisible = band(d[7], 1) == 0
  if d[2] >= 64 then sp:destroy(s); return end
  d[2] = d[2] + 2; local r = sin(d[2], 40); s.x2, s.y2 = sin(d[0] * 32 + 64, r), sin(d[0] * 32, r)
  if d[0] == 0 then
    d[3] = s16(d[3] - d[1]); if band(d[7], 1) ~= 0 and d[1] ~= 0 then d[1] = d[1] - 1 end
    sp:setMatrix(16, sine(d[3] + 64), sine(d[3]), -sine(d[3]), sine(d[3] + 64))
  end
end
function B:battleParticles(x, y)
  for i = 0, 7 do local s = sprite(self, "battle_ball_particle", x, y, 0, "battleParticle"); s.oam.affineMode, s.oam.matrixNum, s.data[0], s.data[1] = 1, 16, i, 32 end
end
local function stopped(self, s)
  if self.stopBattleEffects then self.m.ppu.sprites:destroy(s); return true end
  s.invisible = self.m.ppu.sprites:get(s.data[0]).invisible; return false
end
-- pokeruby/src/intro.c:2504
function B:battleDust(s)
  if stopped(self, s) then return end
  local d = s.data; if d[7] < 12 then d[7] = d[7] + 1 end
  d[6] = d[6] + 4; s.x, s.y = d[4] + div(sine(d[3] + 64) * d[6], 256), d[5] + div(sine(d[3]) * d[6], 256)
  s.y2 = div(sine(d[1]) * d[7], 256); d[1] = s16(d[1] + 16)
  if s.y > d[2] then self.m.ppu.sprites:destroy(s) end
end
-- pokeruby/src/intro.c:2527
function B:battleDustEmitter(s)
  if stopped(self, s) then return end
  local d, parent = s.data, self.m.ppu.sprites:get(s.data[0]); d[7] = d[7] + 1; s.invisible = true
  if parent.data[0] == 1 and band(d[7], 3) == 0 then
    local x, y = parent.x + d[1], parent.y + d[2]
    for i = 0, 2 do
      local e = sprite(self, "battle_dust", x, y, band(parent.subpriority - 1, 255), "battleDust")
      if e.id ~= 64 then e.data[0], e.data[1], e.data[2], e.data[3], e.data[4], e.data[5] = d[0], band(math.floor(d[7] / 4), 7) * 32 + i * 85, d[3], 104, x, y end
    end
  end
end
-- pokeruby/src/intro.c:2581
function B:battleOrbit(s)
  if stopped(self, s) then return end
  local d, parent = s.data, self.m.ppu.sprites:get(s.data[0]); d[7] = d[7] + 1; if d[3] < 40 then d[3] = d[3] + 2 end
  s.x = parent.x + parent.x2 + div(sine(d[1] + 64) * d[3], 256)
  s.y = parent.y + parent.y2 + div(sine(d[1]) * d[3], 512); d[1] = s16(d[1] + 2)
  s.y2 = div(sine(d[2]), 32); d[2] = s16(d[2] + 8); s.subpriority = band(parent.subpriority + (band(d[1], 255) < 128 and -1 or 1), 255)
end
-- pokeruby/src/intro.c:2621
function B:battleSmoke(s)
  if stopped(self, s) then return end
  local d = s.data; d[7], d[6] = d[7] + 1, d[6] + 8
  s.x, s.y = d[4] + div(sine(d[3] + 64) * d[6], 256), d[5] + div(sine(d[3]) * d[6], 256)
  s.oam.matrixNum = band(math.min(9, div(d[6], 16)) + 18, 31)
  if d[6] > 160 then self.m.ppu.sprites:destroy(s) end
end
-- pokeruby/src/intro.c:2648
function B:battleSmokeEmitter(s)
  if stopped(self, s) then return end
  local d, parent = s.data, self.m.ppu.sprites:get(s.data[0]); d[7] = d[7] + 1; s.invisible = true
  if parent.data[0] == 1 and band(d[7], 1) == 0 then
    local x, y = parent.x + d[1], parent.y + d[2]; local e = sprite(self, "duskull_smoke", x, y, band(parent.subpriority + 1, 255), "battleSmoke")
    if e.id ~= 64 then
      e.oam.affineMode, e.oam.matrixNum = 3, 18; Sprites.calcCenterToCornerVec(e, 0, 1, 3)
      e.data[0], e.data[3], e.data[4], e.data[5] = d[0], self.man.tables.smokeAngles[band(div(d[7], 2), 7) + 1][1], x, y
    end
  end
end
-- pokeruby/src/intro.c:2703
function B:battleWater(s)
  if stopped(self, s) then return end
  local d = s.data; d[7], d[6] = d[7] + 1, d[6] + 8
  s.x, s.y = d[4] + div(sine(d[3] + 64) * d[6], 256), d[5] + div(sine(d[3]) * d[6], 256)
  s.y2 = div(sine(d[1]), 64); d[1] = s16(d[1] + 16)
  if s.y < d[2] then self.m.ppu.sprites:destroy(s) end
end
-- pokeruby/src/intro.c:2724
function B:battleWaterEmitter(s)
  if stopped(self, s) then return end
  local d, sp = s.data, self.m.ppu.sprites; local parent = sp:get(d[0]); d[7] = d[7] + 1; s.invisible = true
  if parent.data[0] == 1 then
    if band(d[7], 1) == 0 then
      local x, y = parent.x + d[1], parent.y + d[2]; local e = sprite(self, "torchic_fire", x, y, band(parent.subpriority + 1, 255), "battleWater")
      if e.id ~= 64 then
        e.oam.affineMode, e.oam.matrixNum = 3, 17; Sprites.calcCenterToCornerVec(e, 0, 1, 3)
        e.data[0], e.data[1], e.data[2], e.data[3], e.data[4], e.data[5] = d[0], band(div(d[7], 4), 7) * 32, d[3], 232, x, y
      end
    end
    if d[6] < 112 then d[6] = d[6] + 4 end
  end
  matrix(sp, 17, 256 - div(sine(d[6]), 2), false)
end
-- pokeruby/src/intro.c:2780
function B:battleBlast(s)
  local d, sp = s.data, self.m.ppu.sprites
  if d[0] == 0 then s.invisible = false; s.oam.affineMode, s.oam.matrixNum = 3, 18; Sprites.calcCenterToCornerVec(s, 0, 3, 3); d[1], d[0] = 0, 1 end
  d[7] = d[7] + 1; s.invisible = band(d[7], 1) ~= 0
  if not s.invisible and d[1] < 64 then d[1] = d[1] + 1 end
  matrix(sp, 18, 256 - div(sine(d[1]), 2), false)
end
return B
