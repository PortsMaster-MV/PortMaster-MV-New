local bit = require("bit")
local G = require("src.ui.game3.rse.gc_kit")
local Kit = require("src.ui.game3.rse.scene_kit")
local Vram = require("src.ui.game3.rse.contest_vram")
local Sprites = require("src.core.game3.gba_sprites")
local Pokemon = require("src.core.game3.pokemon")
local IR = require("src.core.game3.scripting.text_ir")
local Stack = require("src.ui.game3.stack")
local Task = require("src.core.game3.task")
local Palette = require("src.core.game3.gba_palette")
local H = {ID = "rs_egg_hatch", SUB = "rse/rs_egg_hatch"}
local Scene = {}; Scene.__index = Scene
H.Scene = Scene

local function copy(t)
  local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out
end

function H.new(mon, opts)
  opts = opts or {}
  local man = opts.manifest or Vram.manifest(H.SUB)
  assert(man.assetLayout == "rs", "native RS hatch pack required")
  local self = setmetatable({mon = assert(mon), opts = opts, man = man, session = opts.session,
    m = G.newMachine(), setupState = 0, state = 0, frames = 0, shardVelocityId = 0,
    headless = opts.headless or Vram.headless(), done = false, softwareFx = {}, displayFx = {}}, Scene)
  self.sound = opts.sound or G.sound({muted = self.headless})
  local pal = self.m.ppu.palette
  local blend = pal.blend
  pal.blend = function(p, offset, count, coeff, color)
    blend(p, offset, count, coeff, color)
    for bank = math.floor(offset / 16), math.floor((offset + count - 1) / 16) do
      self.softwareFx[bank] = {y = coeff, color = color}
    end
  end
  return self
end
function Scene:pal() return self.m.ppu.palette end
function Scene:sp() return self.m.ppu.sprites end
function Scene:beginFade(from, to, color, delay)
  self:pal():beginFade(0xFFFFFFFF, delay or 0, from, to, color)
  self.displayFx = copy(self.softwareFx)
end
function Scene:bytes(kind, key) return (Vram.bytes(self.man, kind, key)) end
function Scene:text(key, vars)
  return IR.decode(assert(self.man.texts[key]), {dialect = "rs"}), {stringVars = vars or {}}
end
function Scene:print(key, immediate)
  local ir, ctx = self:text(key, {Pokemon.displayMonName(self.mon)})
  local option = require("src.core.game3.options").textSpeed(self.session)
  self.printer = Kit.printer(ir, {ctx = ctx, speed = immediate and 0 or assert(self.man.textSpeedDelays[option]),
    textSpeedOption = option, linePitch = 16, canSpeedUp = true})
end

function Scene:makeSprite(kind, x, y, sub, callback)
  local def = self.man.templates[kind]
  local id = self:sp():create({w = def.oam.w, h = def.oam.h, oam = def.oam,
    anims = def.anims, sheet = self.sheets[kind], paletteTag = def.paletteTag,
    callback = callback}, x, y, sub)
  assert(id < Sprites.MAX, "native RS hatch sprite pool exhausted")
  return self:sp().sprites[id]
end

function Scene:setup()
  local st, p = self.setupState, self.m.ppu
  if st == 0 then
    p:set("DISPCNT", 0)
    self.m.tasks:reset(); self:sp():resetData(); self:sp():freeAllPalettes()
    self.savedSong = self.opts.savedSong or self.sound:mapMusic()
    if self.opts.onSavedSong then self.opts.onSavedSong(self.savedSong) end
  elseif st == 1 then
    self:pal():load(self.man.palettes.text, 240, 16)
    self.frameType = require("src.core.game3.options").frameType(self.session)
    if self.frameType < 0 or self.frameType > 19 then self.frameType = 0 end
    self:pal():load(assert(self.man.framePalettes[self.frameType]), 224, 16)
    p:set("BG0CNT", self.man.bgControl[0])
  elseif st == 2 then
    self.bg = {}
    self.bg[1] = Vram.layer(Vram.decodeTiles(self:bytes("gfx", "textbox")), 32, 32, self.headless)
    self.bg[1]:load(Vram.u16s(self:bytes("maps", "textbox")), 32 * 20)
    self:pal():load(self.man.palettes.textbox, 0, 16)
    p:setBg(1, 1, self.bg[1].layer, false)
  elseif st == 3 then
    self.sheets = {}
    for _, kind in ipairs({"egg", "shard"}) do
      local def, frames = self.man.templates[kind], {}
      local stride = def.oam.w * def.oam.h / 64
      for i = 0, 3 do frames[i + 1] = i * stride end
      self.sheets[kind] = Vram.sheet(Vram.decodeTiles(self:bytes("gfx", kind)), frames,
        def.oam.w, def.oam.h, self.headless)
    end
    self:sp():loadPalette(self.man.templates.egg.paletteTag, self.man.palettes.egg)
  elseif st == 4 then
    self.egg = self:makeSprite("egg", 120, 75, 5)
    local hatch = self.opts.hatchMon or require("src.core.game3.breeding").hatchMon
    hatch(self.session, self.mon)
    self.species = Pokemon.speciesOf(self.mon)
  elseif st == 5 then
    local species = Pokemon.monPicSpecies(self.mon)
    local kind = Pokemon.isShiny(self.mon) and "front_shiny" or "front"
    local rgba = self.opts.frontRgba
    if not rgba and species == Pokemon.SPECIES_SPINDA then
      rgba = Pokemon.spindaRgba(self.mon.personality, Pokemon.isShiny(self.mon))
    end
    rgba = rgba or Vram.readCache("data/generated/gba/pokemon/" .. kind .. "/" .. species .. ".rgba")
    assert(rgba and #rgba >= 64 * 64 * 4, "native RS hatched front pic missing")
    self.frontSheet, self.frontPalette = Vram.indexedPic(rgba, self.headless)
    self:sp():loadPalette(self.species, self.frontPalette)
  elseif st == 6 then
    local oam = self.man.templates.frontOam
    local id = self:sp():create({w = 64, h = 64, oam = oam, paletteTag = self.species,
      sheet = self.frontSheet, affineAnims = self.man.frontAffine,
      anims = {{{op = "frame", frame = 0, duration = 1}, {op = "end"}}}}, 120, 70, 6)
    assert(id < Sprites.MAX, "native RS hatch front sprite pool exhausted")
    self.front = self:sp().sprites[id]; self.front.invisible = true
  elseif st == 7 then
    self.bg[2] = G.layer(self:bytes("gfx", "shadow"), 64, 32, {headless = self.headless})
    for i, value in pairs(Vram.u16s(self:bytes("maps", "shadow"))) do self.bg[2]:putIndex(i, value) end
    self.bg[2]:flush()
    self:pal():load(self.man.palettes.shadow, 16, 80)
    p:set("BG2CNT", self.man.bgControl[2]); p:setBg(2, 2, self.bg[2].layer, false)
  elseif st == 8 then
    p:set("BG1CNT", self.man.bgControl[1])
    for i = 0, 2 do p:set("BG" .. i .. "HOFS", 0); p:set("BG" .. i .. "VOFS", 0) end
    self.setupDone = true
  end
  self.setupState = st + 1
end

function Scene:shard()
  local velocity = assert(self.man.shardVelocities[self.shardVelocityId], "native hatch shard velocity overflow")
  self.shardVelocityId = self.shardVelocityId + 1
  local s = self:makeSprite("shard", 120, 60, 4, function(sprite)
    local d = sprite.data
    d[4], d[5] = G.s16(d[4] + d[1]), G.s16(d[5] + d[2])
    sprite.x2, sprite.y2 = G.cdiv(d[4], 256), G.cdiv(d[5], 256)
    d[2] = G.s16(d[2] + d[3])
    if sprite.y2 > 20 and d[2] > 0 then self:sp():destroy(sprite) end
  end)
  s.data[1], s.data[2], s.data[3] = velocity[1], velocity[2], 100
  Sprites.startAnim(s, (self.opts.random or require("src.core.game3.rng").Random)() % 4)
end
function Scene:crack(s, anim, shards)
  self.sound:se("SE_BALL"); Sprites.startAnim(s, anim)
  for _ = 1, shards or 0 do self:shard() end
end

function Scene:eggCallback(s)
  local d, phase = s.data, self.eggPhase
  if phase == 0 or phase == 1 or phase == 2 then
    local advance = phase == 0
    if not advance then d[2] = d[2] + 1; advance = d[2] > 30 end
    if not advance then return end
    d[0] = d[0] + 1
    if d[0] > (phase == 2 and 38 or 20) then
      self.eggPhase, d[0] = phase + 1, 0
      if phase == 1 then d[2] = 0 end
      if phase == 2 then self.front.x2, self.front.y2 = 0, assert(self.man.frontY[self.species]) end
      return
    end
    d[1] = bit.band(d[1] + 20, 255)
    s.x2 = G.sin(self.man, d[1], phase == 0 and 1 or 2)
    if d[0] == 15 then self:crack(s, phase == 0 and 1 or 2, phase == 0 and 1 or (phase == 2 and 2 or 0)) end
    if phase == 2 and d[0] == 30 then self.sound:se("SE_BALL") end
  elseif phase == 3 then
    d[0] = d[0] + 1
    if d[0] > 50 then self.eggPhase, d[0] = 4, 0 end
  elseif phase == 4 then
    if d[0] == 0 then self:beginFade(0, 16, 0x7FFF, -1) end
    if d[0] < 4 then for _ = 1, 4 do self:shard() end end
    d[0] = d[0] + 1
    if not self:pal():fadeActive() then
      self.sound:se("SE_EGG_HATCH"); s.invisible = true
      self.eggPhase, d[0] = 5, 0
    end
  elseif phase == 5 then
    if d[0] == 0 then self.front.invisible = false; self:sp():startAffineAnim(self.front, 1) end
    if d[0] == 8 then self:beginFade(16, 0, 0x7FFF, -1) end
    if d[0] <= 9 then self.front.y = self.front.y - 1 end
    if d[0] > 40 then self.eggPhase, s.callback = "dummy", nil end
    d[0] = d[0] + 1
  end
end

function Scene:main()
  local st, p = self.state, self.m.ppu
  if st == 0 then
    self:beginFade(16, 0, 0); p:set("DISPCNT", self.man.displayControl)
    local id = self.m.tasks:create(function(tid, d)
      if d[0] == 0 then self.sound:stopMapMusic() end
      if d[0] == 1 then self.sound:playMapMusic(self.man.songs.intro) end
      if d[0] > 60 then self.sound:playMapMusic(self.man.songs.evolution); self.m.tasks:destroy(tid) end
      d[0] = d[0] + 1
    end, 5)
    self.bgmTaskId, self.state = id, 1
  elseif st == 1 then
    if not self:pal():fadeActive() then self.counter, self.state = 0, 2 end
  elseif st == 2 then
    self.counter = self.counter + 1
    if self.counter > 30 then
      self.state, self.eggPhase = 3, 0
      self.egg.callback = function(s) self:eggCallback(s) end
    end
  elseif st == 3 then
    if self.eggPhase == "dummy" then self.state = 4 end
  elseif st == 4 then
    self:print("hatched", true)
    self.sound:fanfare("MUS_EVOLVED")
    G.fanfareTask(self.m, self.man.fanfareFrames)
    self.state = 5
  elseif st == 5 or st == 6 then
    if G.fanfareInactive(self.m) then self.state = st + 1 end
  elseif st == 7 then
    self:print("nickname", false); self.state = 8
  elseif st == 8 then
    self.printer:run(self.inp)
    if not self.printer:isActive() then
      self.choice, self.state = 0, 9
      local colors = {}; for i = 1, 16 do colors[i] = 0 end; colors[13] = 0x2D9F
      self.cursorPal = self:sp():loadPalette(0xFFF0, colors)
    end
  elseif st == 9 then
    local n = self.inp.new or {}
    if n.a then
      self.sound:se("SE_SELECT")
      if self.choice == 0 then self:naming() else self.state = 10 end
    elseif n.b then self.state = 10
    elseif n.up and self.choice > 0 then self.choice = self.choice - 1; self.sound:se("SE_SELECT")
    elseif n.down and self.choice < 1 then self.choice = self.choice + 1; self.sound:se("SE_SELECT") end
  elseif st == 10 then
    self:beginFade(0, 16, 0); self.state = 11
  elseif st == 11 then
    if not self:pal():fadeActive() then self.done = true end
  end
  self.m.tasks:run(self)
  self:sp():animateAll(); self:sp():buildOam(); self:pal():update()
end

function Scene:naming()
  self.state = "naming"
  local Naming = require("src.ui.game3.naming")
  Naming.open({template = Naming.TEMPLATE.NICKNAME, title = Naming.monTitle(Pokemon.displayMonName(self.mon)),
    seed = Pokemon.displayMonName(self.mon), maxLen = 10, species = self.species,
    gender = Pokemon.gender(self.species, self.mon.personality), personality = self.mon.personality, session = self.session,
    onDone = function(name)
      if H._scene ~= self then return end
      if type(name) == "string" then
        self.mon.nickname, self.mon.name = name, name
        if self.mon.cartExtra then
          self.mon.cartExtra.nicknameBytes, self.mon.cartExtra.nicknameRaw, self.mon.cartExtra.nicknameLanguage = nil, nil, nil
        end
      end
      self.done = true
      H.finish(self)
    end})
end

function Scene:frame(inp)
  if self.done or self.state == "naming" then return end
  self.frames = self.frames + 1; self.inp = inp or {new = {}, held = {}, rep = {}}
  self.m.vblankCounter1 = self.m.vblankCounter1 + 1
  if self.setupState > 0 then
    self.m.ppu:vblank(); self.displayFx = copy(self.softwareFx)
    if self.bg then for _, bg in pairs(self.bg) do bg:flush() end end
  end
  G.readKeys(self.m, self.inp)
  if not self.setupDone then self:setup() else self:main() end
end

function Scene:draw()
  if self.headless then return end
  self.m.ppu:draw(0, 0)
  if self.printer then
    local w, pal = self.man.windows.text, self:pal().pltt
    self.printer:draw(24, 120, {colors = {fg = G.color555(pal[w.paletteNum * 16 + w.fg]),
      bg = G.color555(pal[w.paletteNum * 16 + w.background]), shadow = G.color555(pal[w.paletteNum * 16 + w.shadow])},
      clip = {24, 120, 216, 40}, maxWidth = 216})
  end
  if self.choice ~= nil then
    local Chrome, Fx = require("src.ui.game3.chrome"), require("src.core.game3.gba_fx")
    Fx.draw(function() Chrome.userFrame(self.frameType, 23, 9, 4, 4) end, self.displayFx[14])
    local w, pal = self.man.windows.menu, self:pal().pltt
    local options = {font = "native_" .. w.font, colors = {fg = G.color555(pal[w.paletteNum * 16 + w.fg]),
      shadow = G.color555(pal[w.paletteNum * 16 + w.shadow])}}
    local font = require("src.ui.game3.frlg_font")
    for i, key in ipairs({"yes", "no"}) do
      local ir = self:text(key); font.draw(IR.toPlain(ir), 184, 72 + (i - 1) * 16, options)
    end
    local parts = assert(Kit.manifest("rse/common_ui").menuCursor)
    parts = parts.parts or parts
    local segments = require("src.ui.game3.rs.menu_cursor").segments(32)
    local color = G.color555(pal[256 + self.cursorPal * 16 + 12])
    for i = #segments, 1, -1 do
      local segment = segments[i]; love.graphics.setColor(color)
      love.graphics.draw(assert(Kit.image(parts[segment.part].mask)), 184 + segment.x, 72 + self.choice * 16)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function H.start(mon, opts)
  opts = opts or {}
  if not mon then if opts.onDone then opts.onDone("error") end; return false end
  H.reset()
  H._pending = {mon = mon, opts = opts}
  local function open()
    if not H._pending then return end
    H._fieldFade = nil
    require("src.ui.game3.fade").clear()
    require("src.core.game3.weather").suspend()
    H._weatherSuspended = true
    H._pending = nil; H._scene = H.new(mon, opts); H._step = Kit.stepper()
    Stack.push(H.ID, H, {hideBelow = true, fullscreen = true})
  end
  if opts.headless or opts.skipEntryFade then open()
  else
    H._fieldFade = H.fieldFade(0, 16, nil, open)
  end
  return true
end
function H.isOpen() return H._scene ~= nil or H._pending ~= nil or H._returning ~= nil end
function H.active() return H._scene end
function H.finish(scene)
  if not scene or H._scene ~= scene then return end
  H._scene, H._step = nil, nil; Stack.pop(H.ID)
  H._returning = scene
  local Weather = require("src.core.game3.weather")
  Weather.resumePaused(); Weather.resume(); H._weatherSuspended = nil
  if scene.opts.restoreMapMusic then scene.opts.restoreMapMusic(scene)
  elseif scene.headless then scene.sound:playMapMusic(scene.savedSong or 0)
  else require("src.core.game3.audio").mapLoadMusic() end
  local function done()
    if H._returning ~= scene then return end
    H._returning, H._fieldFade = nil, nil
    require("src.ui.game3.fade").clear()
    if scene.opts.onDone then scene.opts.onDone("hatched", scene) end
  end
  if scene.opts.returnToField then scene.opts.returnToField(scene, done)
  else H._fieldFade = H.fieldFade(16, 0, Weather.get(), done) end
end

-- field_fadetransition.c:82
function H.fieldFade(from, to, weather, done)
  local Fade = require("src.ui.game3.fade")
  Fade.clear(); Fade.mode = to == 16 and Fade.MODE.TO_BLACK or Fade.MODE.FROM_BLACK
  Fade.t = from; Fade.lockInput = true
  local weatherFade = to == 0 and ({[3] = true, [4] = true, [5] = true,
    [6] = true, [11] = true, [12] = true, [13] = true})[weather]
  local palette, counter, lastBlend = Palette.new(), 0, from
  local blend = palette.blend
  palette.blend = function(p, offset, count, coeff, color)
    blend(p, offset, count, coeff, color)
    if offset == 0 then lastBlend = coeff end
  end
  if not weatherFade then palette:beginFade(0xFFFFFFFF, 0, from, to, 0) end
  return Task.spawn(function()
    if weatherFade then
      if counter >= (weather == 6 and 17 or 16) then done(); return true end
      counter = counter + 1; Fade.t = math.max(0, 16 - counter)
    else
      if not palette:fadeActive() then done(); return true end
      palette:transfer(); Fade.t = lastBlend; palette:update()
    end
  end)
end
function H.handleInput(input) if H._step then H._step:collect(input) end end
function H.update(dt)
  local scene = H._scene
  if not scene then return end
  H._step:run(dt, function(inp) scene:frame(inp); return scene.done or nil end)
  if scene.done then H.finish(scene) end
end
function H.draw() if H._scene then H._scene:draw() end end
function H.reset()
  if H._fieldFade then Task.cancel(H._fieldFade.id) end
  if H._pending or H._returning or H._fieldFade then require("src.ui.game3.fade").clear() end
  if H._weatherSuspended then require("src.core.game3.weather").resume() end
  H._returning, H._fieldFade, H._weatherSuspended = nil, nil, nil
  H._pending, H._scene, H._step = nil, nil, nil
  Stack.pop(H.ID)
end
return H
