local bit = require("bit")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Affine = require("src.core.game3.bg_affine")

local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift

local RayScene = {}
RayScene.__index = RayScene

RayScene.MANIFEST = "data/generated/gba/rayquaza_scene/manifest.lua"

-- pokeemerald/src/rayquaza_scene.c:35
RayScene.DUO_FIGHT_PRE, RayScene.DUO_FIGHT, RayScene.TAKES_FLIGHT = 0, 1, 2
RayScene.DESCENDS, RayScene.CHARGES, RayScene.CHASES_AWAY, RayScene.END = 3, 4, 5, 6

-- pokeemerald/include/gba/io_reg.h:589
local TGT1 = { BG0 = 0x1, BG1 = 0x2, BG2 = 0x4, BG3 = 0x8, OBJ = 0x10 }
local TGT2 = { BG0 = 0x100, BG1 = 0x200, BG2 = 0x400, BG3 = 0x800, OBJ = 0x1000 }
local EFFECT_BLEND = 0x40
-- pokeemerald/include/gba/io_reg.h:557
local WIN0_ALL, WIN01_ALL = 0x3F, 0x3F3F
-- pokeemerald/include/palette.h:16
local PALETTES_ALL, PALETTES_BG, PALETTES_OBJECTS = 0xFFFFFFFF, 0x0000FFFF, 0xFFFF0000
-- pokeemerald/include/constants/rgb.h:23
local RGB_BLACK, RGB_WHITE, RGB_WHITEALPHA = 0x0000, 0x7FFF, 0xFFFF
local DISPLAY_WIDTH, DISPLAY_HEIGHT = 240, 160
-- pokeemerald/src/rayquaza_scene.c:60
local MAX_SMOKE = 10

RayScene.STALL = {
  -- pokeemerald/src/rayquaza_scene.c:1587
  duoFight = 3,
  -- pokeemerald/src/rayquaza_scene.c:2025
  takesFlight = 4,
  -- pokeemerald/src/rayquaza_scene.c:2229
  descends = 3,
  -- pokeemerald/src/rayquaza_scene.c:2479
  charges = 4,
  -- pokeemerald/src/rayquaza_scene.c:2665
  chasesAway = 6,
}

local function s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

local function u16(v) return band(v, 0xFFFF) end

local function s8(v)
  v = band(v, 0xFF)
  if v >= 0x80 then v = v - 0x100 end
  return v
end

local function audio()
  return require("src.core.game3.audio")
end

local function constants()
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get())
end

local function playSe(name)
  local SE = require("src.core.game3.se_ids")
  local id = SE[name]
  if id == nil then error("rayquaza_scene: unknown SE " .. tostring(name)) end
  audio().playSe(id)
end

function RayScene.new(opts)
  opts = opts or {}
  local self = setmetatable({}, RayScene)
  self.m = Machine.new()
  self.man = self.m:manifest(RayScene.MANIFEST)
  self.animId = opts.animId or RayScene.DUO_FIGHT_PRE
  self.endEarly = opts.endEarly and true or false
  self.onDone = opts.onDone
  self.random = opts.random or function() return require("src.core.game3.rng").Random() end
  self.done = false
  self.frames = 0
  self.log = {}
  self.bgX, self.bgY = { [0] = 0, 0, 0, 0 }, { [0] = 0, 0, 0, 0 }
  self.m:setCb2(function() self:initCb() end)
  return self
end

function RayScene:mark(what)
  self.log[#self.log + 1] = { frame = self.frames, what = what, anim = self.animId }
end

function RayScene:layer(key)
  return Machine.layer(assert(self.man.layers[key], "rayquaza_scene: layer " .. key .. " missing from cache"))
end

function RayScene:sprite(key, callback)
  local e = assert(self.man.sprites[key], "rayquaza_scene: sprite " .. key .. " missing from cache")
  return Machine.template(e, { paletteTag = e.paletteTag, callback = callback })
end

function RayScene:loadSpritePalette(tag, palKey)
  self.m.ppu.sprites:loadPalette(tag, self.man.palettes[palKey])
end

function RayScene:create(key, x, y, subpriority, callback)
  return self.m.ppu.sprites:create(self:sprite(key, callback), x, y, subpriority)
end

function RayScene:spr(id)
  return self.m.ppu.sprites.sprites[id]
end

function RayScene:createTask(fn, priority)
  return self.m.tasks:create(fn, priority)
end

function RayScene:task(id)
  return self.m.tasks:get(id)
end

-- pokeemerald/src/rayquaza_scene.c:1296
function RayScene:initCb()
  local m, ppu = self.m, self.m.ppu
  self.sceneVBlank = false
  m:setVBlank(function() self:vblankIntr() end)
  ppu.scanline:stop()
  ppu.sprites:freeAllPalettes()
  ppu.palette:resetFade()
  ppu.sprites:resetData()
  m.tasks:reset()
  ppu.palette:fill(RGB_BLACK, 15 * 16, 16)
  self:createTask(self:animTask(self.animId), 0)
  self:mark("init")
  m:setCb2(function() self:mainCb() end)
end

-- pokeemerald/src/rayquaza_scene.c:1310
function RayScene:mainCb()
  local m = self.m
  m.tasks:run(self)
  m.ppu.sprites:animateAll()
  m.ppu.sprites:buildOam()
  m.ppu.palette:update()
end

function RayScene:setReg(name, value)
  self.pendingRegs = self.pendingRegs or {}
  self.pendingRegs[name] = value
end

function RayScene:getReg(name)
  local p = self.pendingRegs and self.pendingRegs[name]
  if p ~= nil then return p end
  return self.m.ppu:get(name)
end

-- pokeemerald/src/gpu_regs.c:49
function RayScene:flushRegs()
  local ppu = self.m.ppu
  for name, v in pairs(self.pendingRegs or {}) do ppu:set(name, v) end
  self.pendingRegs = {}
  if self.pendingAffine then
    ppu:setAffine(self.pendingAffine.bg, self.pendingAffine.reg)
    self.pendingAffine = nil
  end
end

-- pokeemerald/src/main.c:340
function RayScene:vblankIntr()
  if self.sceneVBlank then self:vblankCb() end
  self:flushRegs()
  if self.hblank then self:hblankFrame() end
end

-- pokeemerald/src/rayquaza_scene.c:1319
function RayScene:vblankCb()
  self.m.ppu:vblank()
end

function RayScene:animTask(animId)
  local list = {
    [RayScene.DUO_FIGHT_PRE] = self.taskDuoFightAnim,
    [RayScene.DUO_FIGHT] = self.taskDuoFightAnim,
    [RayScene.TAKES_FLIGHT] = self.taskRayTakesFlightAnim,
    [RayScene.DESCENDS] = self.taskRayDescendsAnim,
    [RayScene.CHARGES] = self.taskRayChargesAnim,
    [RayScene.CHASES_AWAY] = self.taskRayChasesAwayAnim,
    [RayScene.END] = self.taskEndAfterFadeScreen,
  }
  local f = list[animId]
  return function(id, data) return f(self, id, data) end
end

function RayScene:setTaskFunc(id, method)
  self.m.tasks:setFunc(id, function(tid, data) return method(self, tid, data) end)
end

-- pokeemerald/src/rayquaza_scene.c:1326
function RayScene:taskEndAfterFadeScreen(taskId)
  if not self.m.ppu.palette:fadeActive() then
    self.m.ppu.sprites:resetData()
    self.m.ppu.sprites:freeAllPalettes()
    self.m.tasks:destroy(taskId)
    self:mark("end")
    self.done = true
    self.m:setCb2(nil)
    if self.onDone then self.onDone() end
  end
end

-- pokeemerald/src/rayquaza_scene.c:1338
function RayScene:taskSetNextAnim(taskId)
  if not self.m.ppu.palette:fadeActive() then
    if self.endEarly then
      self:setTaskFunc(taskId, RayScene.taskEndAfterFadeScreen)
    else
      self.animId = self.animId + 1
      self:mark("anim")
      local f = self:animTask(self.animId)
      self.m.tasks:setFunc(taskId, f)
    end
  end
end

-- pokeemerald/src/rayquaza_scene.c:1357
function RayScene:setWindowsHideVertBorders()
  local ppu = self.m.ppu
  self:setReg("WININ", WIN0_ALL)
  self:setReg("WINOUT", 0)
  self:setReg("WIN0H", Ppu.winRange(0, DISPLAY_WIDTH))
  self:setReg("WIN0V", Ppu.winRange(24, DISPLAY_HEIGHT - 24))
  ppu.palette.unfaded[0] = 0
  ppu.palette.faded[0] = 0
end

-- pokeemerald/src/rayquaza_scene.c:1367
function RayScene:resetWindowDimensions()
  self:setReg("WININ", WIN0_ALL)
  self:setReg("WINOUT", WIN01_ALL)
end

-- pokeemerald/src/menu_helpers.c:94
function RayScene:resetBgs(mode, templates)
  local ppu = self.m.ppu
  self:setReg("DISPCNT", 0)
  for i = 0, 3 do
    ppu:setBg(i, 0, nil)
    self.bgX[i], self.bgY[i] = 0, 0
    self:setReg("BG" .. i .. "HOFS", 0)
    self:setReg("BG" .. i .. "VOFS", 0)
  end
  ppu.palette:clearHardware(0)
  self.mode = mode
  for i, row in pairs(templates) do
    ppu:setBg(i, row[1], row[2] and self:layer(row[2]) or nil, false)
  end
end

function RayScene:showBgs(list, extra)
  local d = bor(Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_OBJ_1D_MAP, self.mode or 0, extra or 0)
  for _, i in ipairs(list) do d = bor(d, lshift(0x100, i)) end
  self:setReg("DISPCNT", d)
  self:setReg("BLDCNT", 0)
end

-- pokeemerald/src/bg.c:541
function RayScene:changeBgX(bg, value, op)
  local v = self.bgX[bg]
  if op == "set" then v = value elseif op == "add" then v = v + value else v = v - value end
  v = bit.tobit(v)
  self.bgX[bg] = v
  if not (self.mode == 1 and bg == 2) then self:setReg("BG" .. bg .. "HOFS", band(rshift(v, 8), 0x1FF)) end
  return v
end

-- pokeemerald/src/bg.c:621
function RayScene:changeBgY(bg, value, op)
  local v = self.bgY[bg]
  if op == "set" then v = value elseif op == "add" then v = v + value else v = v - value end
  v = bit.tobit(v)
  self.bgY[bg] = v
  if not (self.mode == 1 and bg == 2) then self:setReg("BG" .. bg .. "VOFS", band(rshift(v, 8), 0x1FF)) end
  return v
end

-- pokeemerald/src/bg.c:772
function RayScene:setBgAffine(bg, srcX, srcY, dispX, dispY, sx, sy, rot)
  local reg = Affine.bgAffineSet({ texX = srcX, texY = srcY, scrX = dispX, scrY = dispY, sx = sx, sy = sy, alpha = rot })
  self.pendingAffine = { bg = bg, reg = reg }
end

-- pokeemerald/src/palette.c:830
function RayScene:blendPalettes(mask, coeff, color)
  self.m.ppu.palette:blendMask(mask, coeff, color)
end

-- pokeemerald/src/palette.c:156
function RayScene:beginFade(mask, delay, startY, targetY, color)
  self.m.ppu.palette:beginFade(mask, delay, startY, targetY, color)
end

-- pokeemerald/src/palette.c:951
function RayScene:blendPalettesGradually(mask, delay, coeff, target, color, priority)
  local st = { coeff = coeff, target = target, color = color, mask = mask, timer = 0 }
  if delay >= 0 then
    st.delay, st.delta = delay, 1
  else
    st.delay, st.delta = 0, -delay + 1
  end
  if target < coeff then st.delta = -st.delta end
  local id
  -- pokeemerald/src/palette.c:1005
  local function run(tid)
    st.timer = st.timer + 1
    if st.timer > st.delay then
      st.timer = 0
      self:blendPalettes(st.mask, st.coeff, st.color)
      if st.coeff == st.target then
        self.m.tasks:destroy(tid)
      else
        st.coeff = st.coeff + st.delta
        if st.delta >= 0 then
          if st.coeff < st.target then return end
        elseif st.coeff > st.target then
          return
        end
        st.coeff = st.target
      end
    end
  end
  id = self.m.tasks:create(run, priority)
  run(id)
  return id
end


-- pokeemerald/src/rayquaza_scene.c:1607
function RayScene:taskDuoFightAnim(taskId, data)
  self.m:addStall(RayScene.STALL.duoFight, true)
  local ppu = self.m.ppu
  ppu.scanline:clear()
  -- pokeemerald/src/rayquaza_scene.c:1568
  self:resetBgs(0, { [0] = { 0, "clouds2" }, [1] = { 2, "clouds1" }, [2] = { 1, "clouds3" } })
  self:showBgs({ 0, 1, 2 })
  -- pokeemerald/src/rayquaza_scene.c:1587
  ppu.palette:load(self.man.palettes.duo_clouds, 0, 32)
  self:loadSpritePalette(self.man.sprites.df_groudon.paletteTag, "duo_groudon")
  self:loadSpritePalette(self.man.sprites.df_kyogre.paletteTag, "duo_kyogre")
  for i = 0, 1 do
    for l = 0, 0x3BF do ppu.scanline.buffers[i][l] = 0 end
  end
  -- pokeemerald/src/rayquaza_scene.c:492
  ppu.scanline.dest = "BG1HOFS"
  ppu.scanline.state = 1
  data[0] = 0
  data[1] = self:createTask(function(id, d) self:taskDuoFightAnimateClouds(id, d) end, 0)
  if self.animId == RayScene.DUO_FIGHT_PRE then
    data[2] = self:duoFightPreCreateGroudonSprites()
    data[3] = self:duoFightPreCreateKyogreSprites()
    self:setTaskFunc(taskId, RayScene.taskHandleDuoFightPre)
  else
    data[2] = self:duoFightCreateGroudonSprites()
    data[3] = self:duoFightCreateKyogreSprites()
    self:setTaskFunc(taskId, RayScene.taskHandleDuoFight)
    audio().playSong(0)
  end
  self:blendPalettes(PALETTES_ALL, 0x10, RGB_BLACK)
  self:beginFade(PALETTES_ALL, 0, 0x10, 0, RGB_BLACK)
  self.sceneVBlank = true
  playSe("SE_DOWNPOUR")
end

-- pokeemerald/src/rayquaza_scene.c:1637
function RayScene:taskDuoFightAnimateClouds(taskId, data)
  local b0, b1 = self.m.ppu.scanline.buffers[0], self.m.ppu.scanline.buffers[1]
  for i = 24, 91 do
    local v
    if i <= 47 then v = rshift(u16(data[0]), 8)
    elseif i <= 63 then v = rshift(u16(data[1]), 8)
    elseif i <= 75 then v = rshift(u16(data[2]), 8)
    elseif i <= 83 then v = rshift(u16(data[3]), 8)
    elseif i <= 87 then v = rshift(u16(data[4]), 8)
    else v = rshift(u16(data[5]), 8) end
    b0[i], b1[i] = v, v
  end
  local steps = (self.animId == RayScene.DUO_FIGHT_PRE) and { 448, 384, 320, 256, 192, 128 }
    or { 768, 640, 512, 384, 256, 128 }
  for k = 0, 5 do data[k] = u16(data[k] + steps[k + 1]) end
end

-- pokeemerald/src/rayquaza_scene.c:1385
function RayScene:taskHandleDuoFightPre(taskId, data)
  self:duoFightAnimateRain()
  if not self.m.ppu.palette:fadeActive() then
    local frame = data[0]
    if frame == 64 then
      self:duoFightLightning1()
    elseif frame == 144 then
      self:duoFightLightning2()
    elseif frame == 328 then
      self:duoFightEnd(taskId, 0)
      return
    elseif frame == 148 then
      self:duoFightLightningLong()
    end
    data[0] = s16(data[0] + 1)
  end
end

-- pokeemerald/src/rayquaza_scene.c:1696
function RayScene:taskHandleDuoFight(taskId, data)
  self:duoFightAnimateRain()
  if not self.m.ppu.palette:fadeActive() then
    local frame = data[0]
    if frame == 32 or frame == 112 then
      self:duoFightLightning1()
    elseif frame == 216 then
      self:duoFightLightning2()
    elseif frame == 220 then
      self:duoFightLightningLong()
    elseif frame == 412 then
      self:duoFightEnd(taskId, 2)
      return
    elseif frame == 380 then
      self:setReg("BLDCNT", bor(TGT1.BG2, TGT2.BG1, EFFECT_BLEND))
      local helper = self:task(data[1])
      self.m.tasks:setFunc(data[1], function(id, d) self:duoFightPanOffScene(id, d) end)
      helper.data[0] = 0
      helper.data[2] = data[2]
      helper.data[3] = data[3]
      self.m.ppu.scanline:stop()
    end
    data[0] = s16(data[0] + 1)
  end
end

-- pokeemerald/src/rayquaza_scene.c:1739
function RayScene:duoFightLightning1()
  playSe("SE_THUNDER")
  self:blendPalettesGradually(band(PALETTES_BG, bit.bnot(0x8000)), 0, 16, 0, RGB_WHITEALPHA, 0)
  self:blendPalettesGradually(PALETTES_OBJECTS, 0, 16, 0, RGB_BLACK, 0)
end

-- pokeemerald/src/rayquaza_scene.c:1746
function RayScene:duoFightLightning2()
  playSe("SE_THUNDER")
  self:blendPalettesGradually(band(PALETTES_BG, bit.bnot(0x8000)), 0, 16, 16, RGB_WHITEALPHA, 0)
  self:blendPalettesGradually(PALETTES_OBJECTS, 0, 16, 16, RGB_BLACK, 0)
end

-- pokeemerald/src/rayquaza_scene.c:1753
function RayScene:duoFightLightningLong()
  self:blendPalettesGradually(band(PALETTES_BG, bit.bnot(0x8000)), 4, 16, 0, RGB_WHITEALPHA, 0)
  self:blendPalettesGradually(PALETTES_OBJECTS, 4, 16, 0, RGB_BLACK, 0)
end

-- pokeemerald/src/rayquaza_scene.c:1759
function RayScene:duoFightAnimateRain()
  self:changeBgX(2, 0x400, "add")
  self:changeBgY(2, 0x800, "sub")
end

-- pokeemerald/src/rayquaza_scene.c:1767
function RayScene:duoFightPanOffScene(taskId, data)
  self:duoFightSlideGroudonDown(self:spr(data[2]))
  self:duoFightSlideKyogreDown(self:spr(data[3]))
  local bgY = u16(self.bgY[1])
  if self.bgY[1] == 0 or bgY > 0x8000 then self:changeBgY(1, 0x400, "sub") end
  if data[0] ~= 16 then
    data[0] = data[0] + 1
    self:setReg("BLDALPHA", Ppu.blendAlpha(16 - data[0], data[0]))
  end
end

-- pokeemerald/src/rayquaza_scene.c:1785
function RayScene:duoFightEnd(taskId, palDelay)
  playSe("SE_DOWNPOUR_STOP")
  self:beginFade(PALETTES_ALL, palDelay, 0, 0x10, RGB_BLACK)
  self:setTaskFunc(taskId, RayScene.taskDuoFightEnd)
end

-- pokeemerald/src/rayquaza_scene.c:1792
function RayScene:taskDuoFightEnd(taskId, data)
  self:duoFightAnimateRain()
  if not self.m.ppu.palette:fadeActive() then
    self.m.tasks:destroy(data[1])
    self:changeBgY(1, 0, "set")
    self.sceneVBlank = false
    self.m.ppu.scanline:stop()
    self.m.ppu.sprites:resetData()
    self.m.ppu.sprites:freeAllPalettes()
    data[0] = 0
    self:setTaskFunc(taskId, RayScene.taskSetNextAnim)
  end
end

local function groudonShift(cc, sprite)
  local d = sprite.data
  local shoulder, claw = cc:spr(d[1]), cc:spr(d[2])
  local idx = sprite.animCmdIndex
  if idx == 0 then
    shoulder.x2, shoulder.y2, claw.x2, claw.y2 = 0, 0, 0, 0
  elseif idx == 1 or idx == 3 then
    shoulder.x2, shoulder.y2, claw.x2, claw.y2 = -1, 0, -1, 0
  elseif idx == 2 then
    shoulder.x2, shoulder.y2, claw.x2, claw.y2 = -1, 1, -2, 1
  end
end

local function groudonStep(cc, sprite)
  local d = sprite.data
  sprite.x = sprite.x - 1
  cc:spr(d[0]).x = cc:spr(d[0]).x - 1
  cc:spr(d[1]).x = cc:spr(d[1]).x - 1
  cc:spr(d[2]).x = cc:spr(d[2]).x - 1
end

local function kyogreParts(cc, sprite)
  local d = sprite.data
  return {
    cc:spr(rshift(d[0], 8)), cc:spr(band(d[0], 0xFF)), cc:spr(rshift(d[1], 8)), cc:spr(band(d[1], 0xFF)),
    cc:spr(rshift(d[2], 8)), cc:spr(band(d[2], 0xFF)), cc:spr(rshift(d[3], 8)), cc:spr(band(d[3], 0xFF)),
    cc:spr(rshift(d[4], 8)), cc:spr(band(d[4], 0xFF)),
  }
end

local function kyogreBob(cc, sprite)
  local d = sprite.data
  local p = kyogreParts(cc, sprite)
  local idx = cc:spr(band(d[2], 0xFF)).animCmdIndex
  if idx == 0 then
    sprite.y2 = 0
    for _, s in ipairs(p) do s.y2 = 0 end
  elseif idx == 1 or idx == 3 then
    sprite.y2 = 1
    for _, s in ipairs(p) do s.y2 = 1 end
  elseif idx == 2 then
    sprite.y2 = 2
    for k = 1, 5 do p[k].y2 = 2 end
    p[10].y2 = 2
  end
end

-- pokeemerald/src/rayquaza_scene.c:1417
function RayScene:duoFightPreCreateGroudonSprites()
  local id = self:create("dfp_groudon", 88, 72, 3, function(s) self:spriteCbDuoFightPreGroudon(s) end)
  local d = self:spr(id).data
  d[0] = self:create("dfp_groudon", 56, 104, 3)
  d[1] = self:create("dfp_groudon_shoulder", 75, 101, 0)
  d[2] = self:create("dfp_groudon_claw", 109, 114, 1)
  Sprites.startAnim(self:spr(d[0]), 1)
  return id
end

-- pokeemerald/src/rayquaza_scene.c:1432
function RayScene:spriteCbDuoFightPreGroudon(sprite)
  local d = sprite.data
  d[5] = band(d[5] + 1, 0x1F)
  if d[5] == 0 and sprite.x ~= 72 then groudonStep(self, sprite) end
  groudonShift(self, sprite)
end

local KYOGRE_LAYOUT = {
  { 168, 96, 1, 1 }, { 136, 112, 1, 2 }, { 168, 112, 1, 3 }, { 136, 128, 1, 4 }, { 168, 128, 1, 5 },
  { 104, 128, 2, 6 }, { 136, 128, 2, 7 }, { 184, 128, 0, 8 },
}

function RayScene:createKyogre(prefix, bx, pectoral, dorsal, cb)
  local id = self:create(prefix .. "_kyogre", 136 + bx, 96, 1, cb)
  local d = self:spr(id).data
  local ids = {}
  for k, row in ipairs(KYOGRE_LAYOUT) do
    ids[k] = self:create(prefix .. "_kyogre", row[1] + bx, row[2], row[3])
  end
  ids[9] = self:create(prefix .. "_kyogre_pectoral", pectoral[1], pectoral[2], 0)
  ids[10] = self:create(prefix .. "_kyogre_dorsal", dorsal[1], dorsal[2], 1)
  for k = 0, 4 do d[k] = bor(lshift(ids[k * 2 + 1], 8), ids[k * 2 + 2]) end
  for k, row in ipairs(KYOGRE_LAYOUT) do Sprites.startAnim(self:spr(ids[k]), row[4]) end
  return id
end

-- pokeemerald/src/rayquaza_scene.c:1469
function RayScene:duoFightPreCreateKyogreSprites()
  return self:createKyogre("dfp", 0, { 208, 132 }, { 200, 120 }, function(s) self:spriteCbDuoFightPreKyogre(s) end)
end

-- pokeemerald/src/rayquaza_scene.c:1501
function RayScene:spriteCbDuoFightPreKyogre(sprite)
  local d = sprite.data
  d[5] = band(d[5] + 1, 0x1F)
  if d[5] == 0 and sprite.x ~= 152 then
    sprite.x = sprite.x + 1
    for _, s in ipairs(kyogreParts(self, sprite)) do s.x = s.x + 1 end
  end
  kyogreBob(self, sprite)
end

-- pokeemerald/src/rayquaza_scene.c:1809
function RayScene:duoFightCreateGroudonSprites()
  local id = self:create("df_groudon", 98, 72, 3, function(s) self:spriteCbDuoFightGroudon(s) end)
  local d = self:spr(id).data
  d[0] = self:create("df_groudon", 66, 104, 3)
  d[1] = self:create("df_groudon_shoulder", 85, 101, 0)
  d[2] = self:create("df_groudon_claw", 119, 114, 1)
  Sprites.startAnim(self:spr(d[0]), 1)
  return id
end

-- pokeemerald/src/rayquaza_scene.c:1824
function RayScene:spriteCbDuoFightGroudon(sprite)
  local d = sprite.data
  d[5] = band(d[5] + 1, 0xF)
  if band(d[5], 7) == 0 and sprite.x ~= 72 then groudonStep(self, sprite) end
  groudonShift(self, sprite)
end

-- pokeemerald/src/rayquaza_scene.c:1861
function RayScene:duoFightSlideGroudonDown(sprite)
  local d = sprite.data
  if sprite.y <= DISPLAY_HEIGHT then
    sprite.y = sprite.y + 8
    for k = 0, 2 do self:spr(d[k]).y = self:spr(d[k]).y + 8 end
  end
end

-- pokeemerald/src/rayquaza_scene.c:1873
function RayScene:duoFightCreateKyogreSprites()
  return self:createKyogre("df", -10, { 198, 132 }, { 190, 120 }, function(s) self:spriteCbDuoFightKyogre(s) end)
end

-- pokeemerald/src/rayquaza_scene.c:1905
function RayScene:spriteCbDuoFightKyogre(sprite)
  local d = sprite.data
  d[5] = band(d[5] + 1, 0xF)
  if band(d[5], 7) == 0 and sprite.x ~= 152 then
    sprite.x = sprite.x + 1
    for _, s in ipairs(kyogreParts(self, sprite)) do s.x = s.x + 1 end
  end
  kyogreBob(self, sprite)
end

-- pokeemerald/src/rayquaza_scene.c:1966
function RayScene:duoFightSlideKyogreDown(sprite)
  if sprite.y <= DISPLAY_HEIGHT then
    sprite.y = sprite.y + 8
    for _, s in ipairs(kyogreParts(self, sprite)) do s.y = s.y + 8 end
  end
end


-- pokeemerald/src/rayquaza_scene.c:2041
function RayScene:taskRayTakesFlightAnim(taskId, data)
  self.m:addStall(RayScene.STALL.takesFlight, true)
  local ppu = self.m.ppu
  audio().playSong(constants():require("songs", "MUS_RAYQUAZA_APPEARS"))
  -- pokeemerald/src/rayquaza_scene.c:2006
  self:resetBgs(1, { [0] = { 0, "clouds2" }, [1] = { 2, "tf_bg" }, [2] = { 1, "tf_rayquaza" } })
  self:showBgs({ 0, 1, 2 })
  -- pokeemerald/src/rayquaza_scene.c:2025
  ppu.palette:load(self.man.palettes.tf_rayquaza, 0, 32)
  self:loadSpritePalette(self.man.sprites.tf_smoke.paletteTag, "tf_smoke")
  self:setReg("BLDCNT", bor(TGT1.OBJ, TGT2.BG1, EFFECT_BLEND))
  self:setReg("BLDALPHA", Ppu.blendAlpha(8, 8))
  self:blendPalettes(PALETTES_ALL, 16, 0)
  self.sceneVBlank = true
  self:createTask(function(id, d) self:taskTakesFlightCreateSmoke(id, d) end, 0)
  data[0], data[1] = 0, 0
  self:setTaskFunc(taskId, RayScene.taskHandleRayTakesFlight)
end

-- pokeemerald/src/rayquaza_scene.c:2059
function RayScene:taskHandleRayTakesFlight(taskId, data)
  local st = data[0]
  if st == 0 then
    if data[1] == 8 then
      self:beginFade(PALETTES_ALL, 0, 0x10, 0, RGB_BLACK)
      data[2], data[3], data[4], data[5], data[1] = 0, 30, 0, 7, 0
      data[0] = 1
    else
      data[1] = data[1] + 1
    end
  elseif st == 1 then
    data[2] = data[2] + data[3]
    data[4] = data[4] + data[5]
    if data[3] > 3 then data[3] = data[3] - 3 end
    if data[5] ~= 0 then data[5] = data[5] - 1 end
    if data[2] > 255 then
      data[2], data[3], data[6], data[7], data[1] = 256, 0, 12, -1, 0
      data[0] = 2
    end
    self:setBgAffine(2, 0x7800, 0x1800, 120, data[4] + 32, data[2], data[2], 0)
  elseif st == 2 then
    data[1] = data[1] + 1
    self:setBgAffine(2, 0x7800, 0x1800, 120, data[4] + 32 + bit.arshift(data[6], 2), data[2], data[2], 0)
    data[6] = data[6] + data[7]
    if data[6] == 12 or data[6] == -12 then
      data[7] = -data[7]
      if data[1] > 295 then
        data[0] = 3
        self:beginFade(PALETTES_ALL, 6, 0, 0x10, RGB_BLACK)
      end
    end
  elseif st == 3 then
    data[2] = data[2] + 16
    self:setBgAffine(2, 0x7800, 0x1800, 120, data[4] + 32, data[2], data[2], 0)
    self:taskRayTakesFlightEnd(taskId)
  end
end

-- pokeemerald/src/rayquaza_scene.c:2136
function RayScene:taskRayTakesFlightEnd(taskId)
  if not self.m.ppu.palette:fadeActive() then
    self.sceneVBlank = false
    self.m.ppu.sprites:resetData()
    self.m.ppu.sprites:freeAllPalettes()
    self:setTaskFunc(taskId, RayScene.taskSetNextAnim)
  end
end

-- pokeemerald/src/rayquaza_scene.c:2153
function RayScene:taskTakesFlightCreateSmoke(taskId, data)
  if band(data[1], 3) == 0 then
    local c = self.man.smokeCoords[data[0] + 1]
    local id = self:create("tf_smoke", c[1] * 4 + 120, c[2] * 4 + 80, 0, function(s) self:spriteCbTakesFlightSmoke(s) end)
    local s = self:spr(id)
    s.data[0] = s8(data[0])
    s.oam.objMode = Sprites.OBJ_BLEND
    s.oam.affineMode = Sprites.AFFINE_DOUBLE
    s.oam.priority = 2
    s.affineAnims = self.man.sprites.tf_smoke.affineAnims
    self.m.ppu.sprites:initAffineAnim(s)
    if data[0] == MAX_SMOKE - 1 then
      self.m.tasks:destroy(taskId)
      return
    else
      data[0] = data[0] + 1
    end
  end
  data[1] = data[1] + 1
end

-- pokeemerald/src/rayquaza_scene.c:2184
function RayScene:spriteCbTakesFlightSmoke(sprite)
  local d = sprite.data
  if d[1] == 0 then
    sprite.x2, sprite.y2 = 0, 0
  else
    local c = self.man.smokeCoords[d[0] + 1]
    sprite.x2 = sprite.x2 + c[1]
    sprite.y2 = sprite.y2 + c[2]
  end
  d[1] = band(d[1] + 1, 0xF)
end


-- pokeemerald/src/rayquaza_scene.c:2281
function RayScene:taskRayDescendsAnim(taskId, data)
  self.m:addStall(RayScene.STALL.descends, true)
  local ppu = self.m.ppu
  -- pokeemerald/src/rayquaza_scene.c:2207
  self:resetBgs(0, {
    [0] = { 0, "de_light" }, [1] = { 1, "de_bg_top" }, [2] = { 2, nil }, [3] = { 3, "de_bg" },
  })
  self:showBgs({ 0, 1, 2, 3 })
  -- pokeemerald/src/rayquaza_scene.c:2229
  ppu.palette:load(self.man.palettes.de_bg, 0, 32)
  ppu.palette.unfaded[0], ppu.palette.faded[0] = RGB_WHITE, RGB_WHITE
  self:loadSpritePalette(self.man.sprites.de_rayquaza.paletteTag, "tf_rayquaza")
  self:setReg("BLDCNT", bor(self:getReg("BLDCNT"), TGT1.BG0, TGT2.BG1, TGT2.BG2, TGT2.BG3, TGT2.OBJ, EFFECT_BLEND))
  self:setReg("BLDALPHA", Ppu.blendAlpha(0, 16))
  self:blendPalettes(PALETTES_ALL, 0x10, RGB_BLACK)
  self.sceneVBlank = true
  self.revealedLightLine, self.revealedLightTimer = 0, 0
  data[0], data[1], data[2], data[3], data[4] = 0, 0, 0, 0, 0x1000
  self:setTaskFunc(taskId, RayScene.taskHandleRayDescends)
end

-- pokeemerald/src/rayquaza_scene.c:2251
function RayScene:hblankFrame()
  local r = self.revealedLightLine
  if r <= 0x1FFF then
    if r <= 39 then r = r + 4 elseif r <= 79 then r = r + 2 else r = r + 1 end
  end
  self.revealedLightLine = r
  self.revealedLightTimer = self.revealedLightTimer + 1
  local ppu = self.m.ppu
  local bottom = math.min(137, 26 + r)
  ppu:set("BLDALPHA", 0xD08)
  ppu:set("WININ", WIN0_ALL)
  ppu:set("WINOUT", band(WIN0_ALL, bit.bnot(0x1)))
  ppu:set("WIN0H", Ppu.winRange(0, DISPLAY_WIDTH))
  ppu:set("WIN0V", Ppu.winRange(25, bottom))
  ppu:set("DISPCNT", bor(ppu:get("DISPCNT"), Ppu.DISPCNT_WIN0_ON))
end

-- pokeemerald/src/rayquaza_scene.c:2300
function RayScene:taskHandleRayDescends(taskId, data)
  local st = data[0]
  if st == 0 then
    if data[1] == 8 then
      self:beginFade(PALETTES_ALL, 0, 0x10, 0, RGB_BLACK)
      data[1], data[0] = 0, 1
    else
      data[1] = data[1] + 1
    end
  elseif st == 1 then
    if not self.m.ppu.palette:fadeActive() then
      if data[1] == 10 then
        data[1], data[0] = 0, 2
        self.hblank = true
      else
        data[1] = data[1] + 1
      end
    end
  elseif st == 2 then
    if data[1] == 80 then
      data[1], data[0] = 0, 3
      self:createDescendsRayquazaSprite()
    else
      data[1] = data[1] + 1
    end
  elseif st == 3 then
    data[1] = data[1] + 1
    if data[1] == 368 then data[1], data[0] = 0, 4 end
  elseif st == 4 then
    self:beginFade(PALETTES_ALL, 0, 0, 0x10, RGB_BLACK)
    self:setTaskFunc(taskId, RayScene.taskRayDescendsEnd)
  end
end

-- pokeemerald/src/rayquaza_scene.c:2364
function RayScene:taskRayDescendsEnd(taskId)
  if not self.m.ppu.palette:fadeActive() then
    self.sceneVBlank = false
    self.hblank = false
    local ppu = self.m.ppu
    self:setReg("DISPCNT", band(self:getReg("DISPCNT"), bit.bnot(Ppu.DISPCNT_WIN0_ON)))
    ppu.sprites:resetData()
    ppu.sprites:freeAllPalettes()
    self:setTaskFunc(taskId, RayScene.taskSetNextAnim)
  end
end

-- pokeemerald/src/rayquaza_scene.c:2381
function RayScene:createDescendsRayquazaSprite()
  local id = self:create("de_rayquaza", 160, 0, 0, function(s) self:spriteCbDescendsRayquaza(s) end)
  local s = self:spr(id)
  s.data[0] = self:create("de_rayquaza_tail", 184, -48, 0)
  s.oam.priority = 3
  self:spr(s.data[0]).oam.priority = 3
  return id
end

-- pokeemerald/src/rayquaza_scene.c:2392
function RayScene:spriteCbDescendsRayquaza(sprite)
  local d = sprite.data
  local frame = d[2]
  local periods = { [0] = { 12, 8 }, [256] = { 9, 7 }, [268] = { 8, 6 }, [280] = { 7, 5 }, [292] = { 6, 4 },
    [304] = { 5, 3 }, [320] = { 4, 2 } }
  local p = periods[frame]
  if p then d[3], d[4] = p[1], p[2] end
  local tail = self:spr(d[0])
  if d[2] % d[3] == 0 then
    sprite.x2 = sprite.x2 - 1
    tail.x2 = tail.x2 - 1
  end
  if d[2] % d[4] == 0 then
    sprite.y2 = sprite.y2 + 1
    tail.y2 = tail.y2 + 1
  end
  d[2] = s16(d[2] + 1)
end


-- pokeemerald/src/rayquaza_scene.c:2499
function RayScene:taskRayChargesAnim(taskId, data)
  self.m:addStall(RayScene.STALL.charges, true)
  local ppu = self.m.ppu
  -- pokeemerald/src/rayquaza_scene.c:2457
  self:resetBgs(0, {
    [0] = { 0, "ch_orbs" }, [1] = { 1, "ch_rayquaza" }, [2] = { 2, "ch_streaks" }, [3] = { 3, "ch_bg" },
  })
  self:showBgs({ 0, 1, 2, 3 }, Ppu.DISPCNT_WIN0_ON)
  -- pokeemerald/src/rayquaza_scene.c:2479
  ppu.palette:load(self.man.palettes.ch_bg, 0, 64)
  self:setWindowsHideVertBorders()
  self:blendPalettes(PALETTES_ALL, 0x10, RGB_BLACK)
  self.sceneVBlank = true
  data[0], data[1] = 0, 0
  data[2] = self:createTask(function(id, d) self:taskRayChargesShakeRayquaza(id, d) end, 0)
  self:setTaskFunc(taskId, RayScene.taskHandleRayCharges)
end

-- pokeemerald/src/rayquaza_scene.c:2513
function RayScene:taskHandleRayCharges(taskId, data)
  self:rayChargesAnimateBg()
  if band(data[3], 7) == 0 and data[0] <= 1 and data[1] <= 89 then playSe("SE_INTRO_BLAST") end
  data[3] = s16(data[3] + 1)
  local st = data[0]
  if st == 0 then
    if data[1] == 8 then
      self:beginFade(PALETTES_ALL, 0, 0x10, 0, RGB_BLACK)
      data[1], data[0] = 0, 1
    else
      data[1] = data[1] + 1
    end
  elseif st == 1 then
    if data[1] == 127 then
      data[1], data[0] = 0, 2
      self.m.tasks:setFunc(data[2], function(id, d) self:taskRayChargesFlyOffscreen(id, d) end)
    else
      data[1] = data[1] + 1
    end
  elseif st == 2 then
    if data[1] == 12 then data[1], data[0] = 0, 3 else data[1] = data[1] + 1 end
  elseif st == 3 then
    self:beginFade(PALETTES_ALL, 0, 0, 0x10, RGB_BLACK)
    self:setTaskFunc(taskId, RayScene.taskRayChargesEnd)
  end
end

-- pokeemerald/src/rayquaza_scene.c:2578
function RayScene:taskRayChargesShakeRayquaza(taskId, data)
  if band(data[15], 3) == 0 then
    self:changeBgX(1, lshift(self.random() % 8 - 4, 8), "set")
    self:changeBgY(1, lshift(self.random() % 8 - 4, 8), "set")
  end
  data[15] = s16(data[15] + 1)
end

-- pokeemerald/src/rayquaza_scene.c:2591
function RayScene:taskRayChargesFlyOffscreen(taskId, data)
  if data[0] == 0 then
    self:changeBgX(1, 0, "set")
    self:changeBgY(1, 0, "set")
    data[0] = 1
    data[1], data[2] = 10, -1
  elseif data[0] == 1 then
    self:changeBgX(1, lshift(data[1], 8), "sub")
    self:changeBgY(1, lshift(data[1], 8), "add")
    data[1] = data[1] + data[2]
    if data[1] == -10 then data[2] = -data[2] end
  end
end

-- pokeemerald/src/rayquaza_scene.c:2617
function RayScene:rayChargesAnimateBg()
  self:changeBgX(2, 0x400, "sub")
  self:changeBgY(2, 0x400, "add")
  self:changeBgX(0, 0x800, "sub")
  self:changeBgY(0, 0x800, "add")
end

-- pokeemerald/src/rayquaza_scene.c:2628
function RayScene:taskRayChargesEnd(taskId, data)
  self:rayChargesAnimateBg()
  if not self.m.ppu.palette:fadeActive() then
    self.sceneVBlank = false
    self:resetWindowDimensions()
    self.m.tasks:destroy(data[2])
    self:setTaskFunc(taskId, RayScene.taskSetNextAnim)
  end
end


-- pokeemerald/src/rayquaza_scene.c:2692
function RayScene:taskRayChasesAwayAnim(taskId, data)
  self.m:addStall(RayScene.STALL.chasesAway, true)
  local ppu = self.m.ppu
  -- pokeemerald/src/rayquaza_scene.c:2646
  self:resetBgs(1, { [0] = { 1, "ca_light" }, [1] = { 2, "ca_bg" }, [2] = { 0, "ca_ring" } })
  self:showBgs({ 0, 1, 2 }, Ppu.DISPCNT_WIN0_ON)
  -- pokeemerald/src/rayquaza_scene.c:2665
  ppu.palette:load(self.man.palettes.ca_bg, 0, 48)
  for _, pair in ipairs({ { "ca_groudon", "ca_groudon" }, { "ca_kyogre", "ca_kyogre" }, { "ca_rayquaza", "ca_rayquaza" },
    { "ca_splash", "ca_splash" } }) do
    self:loadSpritePalette(self.man.sprites[pair[1]].paletteTag, pair[2])
  end
  self:setWindowsHideVertBorders()
  self:setReg("DISPCNT", band(self:getReg("DISPCNT"), bit.bnot(Ppu.DISPCNT_BG2_ON)))
  self:setReg("BLDCNT", bor(TGT1.BG0, TGT2.BG1, EFFECT_BLEND))
  self:setReg("BLDALPHA", Ppu.blendAlpha(9, 14))
  self:blendPalettes(PALETTES_ALL, 0x10, RGB_BLACK)
  self.sceneVBlank = true
  data[0], data[1] = 0, 0
  self:setTaskFunc(taskId, RayScene.taskHandleRayChasesAway)
  data[2] = self:createTask(function(id, d) self:taskChasesAwayAnimateBg(id, d) end, 0)
  local bg = self:task(data[2]).data
  bg[0], bg[1], bg[2], bg[3], bg[4] = 0, 0, 0, 1, 1
end

-- pokeemerald/src/rayquaza_scene.c:2714
function RayScene:taskHandleRayChasesAway(taskId, data)
  local st = data[0]
  if st == 0 then
    if data[1] == 8 then
      self:chasesAwayCreateTrioSprites(taskId)
      self:beginFade(PALETTES_ALL, 0, 0x10, 0, RGB_BLACK)
      data[1], data[0] = 0, 1
    else
      data[1] = data[1] + 1
    end
  elseif st == 1 then
    if self:spr(data[5]).floating then
      if data[1] == 64 then
        self:chasesAwayKyogreStartLeave(taskId)
        self:chasesAwayGroudonStartLeave(taskId)
        data[1], data[0] = 0, 2
      else
        data[1] = data[1] + 1
      end
    end
  elseif st == 2 then
    if data[1] == 448 then
      data[1], data[0] = 0, 3
    else
      data[1] = data[1] + 1
      if data[1] % 144 == 0 then
        self:blendPalettesGradually(band(PALETTES_BG, bit.bnot(1)), 0, 16, 0, RGB_WHITEALPHA, 0)
        self:blendPalettesGradually(PALETTES_OBJECTS, 0, 16, 0, RGB_BLACK, 0)
      end
    end
  elseif st == 3 then
    self:beginFade(PALETTES_ALL, 4, 0, 0x10, RGB_BLACK)
    self:setTaskFunc(taskId, RayScene.taskRayChasesAwayEnd)
  end
end

-- pokeemerald/src/rayquaza_scene.c:2787
function RayScene:taskChasesAwayAnimateBg(taskId, data)
  if band(data[0], 0xF) == 0 then
    self:setReg("BLDALPHA", bor(band(lshift(data[1] + 14, 8), 0x1F00), band(data[2] + 9, 0xF)))
    data[1] = data[1] - data[3]
    data[2] = data[2] + data[4]
    if data[1] == -3 or data[1] == 0 then data[3] = -data[3] end
    if data[2] == 3 or data[2] == 0 then data[4] = -data[4] end
  end
  data[0] = s16(data[0] + 1)
end

-- pokeemerald/src/rayquaza_scene.c:2812
function RayScene:taskRayChasesAwayEnd(taskId, data)
  if not self.m.ppu.palette:fadeActive() then
    audio().playSong(0)
    if data[1] == 0 then
      self.sceneVBlank = false
      self:resetWindowDimensions()
      self.m.ppu.sprites:resetData()
      self.m.ppu.sprites:freeAllPalettes()
      self.m.tasks:destroy(data[2])
    end
    if data[1] == 32 then
      data[1] = 0
      self:setTaskFunc(taskId, RayScene.taskSetNextAnim)
    else
      data[1] = data[1] + 1
    end
  end
end

-- pokeemerald/src/rayquaza_scene.c:2846
function RayScene:chasesAwayCreateTrioSprites(taskId)
  local td = self:task(taskId).data
  td[3] = self:create("ca_groudon", 64, 120, 0)
  local g = self:spr(td[3])
  g.data[0] = self:create("ca_groudon_tail", 16, 130, 0)
  g.oam.priority = 1
  self:spr(g.data[0]).oam.priority = 1

  td[4] = self:create("ca_kyogre", 160, 128, 1)
  local k = self:spr(td[4])
  k.data[0] = self:create("ca_kyogre", 192, 128, 1)
  k.data[1] = self:create("ca_kyogre", 224, 128, 1)
  k.oam.priority = 1
  self:spr(k.data[0]).oam.priority = 1
  self:spr(k.data[1]).oam.priority = 1
  Sprites.startAnim(self:spr(k.data[0]), 1)
  Sprites.startAnim(self:spr(k.data[1]), 2)

  td[5] = self:create("ca_rayquaza", 120, -65, 0, function(s) self:spriteCbChasesAwayRayquaza(s) end)
  local r = self:spr(td[5])
  r.data[0] = self:create("ca_rayquaza_tail", 120, -113, 0)
  r.oam.priority = 1
  self:spr(r.data[0]).oam.priority = 1
  self.trioTask = taskId
end

-- pokeemerald/src/rayquaza_scene.c:2882
function RayScene:chasesAwayPushDuoBack(taskId)
  local td = self:task(taskId).data
  for _, row in ipairs({ { td[3], 0 }, { td[4], 1 } }) do
    local s = self:spr(row[1])
    s.callback = function(sp) self:spriteCbChasesAwayDuoRingPush(sp) end
    s.data[4], s.data[5], s.data[6], s.data[7] = 0, 0, 4, row[2]
  end
end

-- pokeemerald/src/rayquaza_scene.c:2900
function RayScene:spriteCbChasesAwayDuoRingPush(sprite)
  local d = sprite.data
  if band(d[4], 7) == 0 then
    if d[7] == 0 then
      sprite.x = sprite.x - d[6]
      self:spr(d[0]).x = self:spr(d[0]).x - d[6]
    else
      sprite.x = sprite.x + d[6]
      self:spr(d[0]).x = self:spr(d[0]).x + d[6]
      self:spr(d[1]).x = self:spr(d[1]).x + d[6]
    end
    d[5] = d[5] + 1
    d[6] = d[6] - d[5]
    if d[5] == 3 then
      d[4], d[5], d[6] = 0, 0, 0
      sprite.callback = nil
      return
    end
  end
  d[4] = s16(d[4] + 1)
end

-- pokeemerald/src/rayquaza_scene.c:2938
function RayScene:chasesAwayGroudonStartLeave(taskId)
  local s = self:spr(self:task(taskId).data[3])
  s.callback = function(sp) self:spriteCbChasesAwayGroudonLeave(sp) end
  Sprites.startAnim(s, 1)
end

-- pokeemerald/src/rayquaza_scene.c:2945
function RayScene:spriteCbChasesAwayGroudonLeave(sprite)
  local tail = self:spr(sprite.data[0])
  local idx = sprite.animCmdIndex
  if idx == 0 or idx == 2 then
    if sprite.animDelayCounter % 12 == 0 then
      sprite.x = sprite.x - 2
      tail.x = tail.x - 2
    end
    tail.y2 = 0
  elseif idx == 1 or idx == 3 then
    tail.y2 = -2
    if band(sprite.animDelayCounter, 15) == 0 then
      sprite.y = sprite.y + 1
      tail.y = tail.y + 1
    end
  end
end

-- pokeemerald/src/rayquaza_scene.c:2970
function RayScene:chasesAwayKyogreStartLeave(taskId)
  local s = self:spr(self:task(taskId).data[4])
  local cb = function(sp) self:spriteCbChasesAwayKyogreLeave(sp) end
  s.callback = cb
  self:spr(s.data[0]).callback = cb
  self:spr(s.data[1]).callback = cb
end

-- pokeemerald/src/rayquaza_scene.c:2982
function RayScene:spriteCbChasesAwayKyogreLeave(sprite)
  local d = sprite.data
  if band(d[4], 3) == 0 then
    if sprite.x2 == 1 then sprite.x2 = -1 else sprite.x2 = 1 end
  end
  if d[5] == 128 then
    d[7] = self:create("ca_splash", 152, 132, 0)
    self:spr(d[7]).oam.priority = 1
    d[7] = self:create("ca_splash", 224, 132, 0)
    self:spr(d[7]).oam.priority = 1
    self:spr(d[7]).hFlip = true
    d[5] = d[5] + 1
  end
  if d[5] > 127 then
    if sprite.y2 ~= 32 then
      d[6] = d[6] + 1
      sprite.y2 = bit.arshift(d[6], 4)
    end
  else
    d[5] = d[5] + 1
  end
  if d[4] % 64 == 0 then playSe("SE_M_WHIRLPOOL") end
  d[4] = s16(d[4] + 1)
end

-- pokeemerald/src/rayquaza_scene.c:3028
function RayScene:spriteCbChasesAwayRayquaza(sprite)
  local d = sprite.data
  local tail = self:spr(d[0])
  local frame = d[7]
  if frame <= 64 then
    sprite.y2 = sprite.y2 + 2
    tail.y2 = tail.y2 + 2
    if d[7] == 64 then
      self:chasesAwaySetRayquazaAnim(sprite, 1, 0, -48)
      d[4], d[5] = 5, -1
      tail.data[4], tail.data[5] = 3, 5
    end
  elseif frame <= 111 then
    self:spriteCbChasesAwayRayquazaFloat(sprite)
    if d[4] == 0 then playSe("SE_MUGSHOT") end
    if d[4] == -3 then self:chasesAwaySetRayquazaAnim(sprite, 2, 48, 16) end
  elseif frame == 112 then
    tail.data[4], tail.data[5] = 7, 3
    self:spriteCbChasesAwayRayquazaFloat(sprite)
  elseif frame <= 327 then
    self:spriteCbChasesAwayRayquazaFloat(sprite)
  elseif frame == 328 then
    self:spriteCbChasesAwayRayquazaFloat(sprite)
    self:chasesAwaySetRayquazaAnim(sprite, 3, 48, 16)
    sprite.x2 = 1
    tail.x2 = 1
    pcall(function() audio().playCry(constants():require("species", "SPECIES_RAYQUAZA"), 0) end)
    self:createTask(function(id, td) self:taskChasesAwayAnimateRing(id, td) end, 0)
  elseif frame == 376 then
    sprite.x2 = 0
    tail.x2 = 0
    self:spriteCbChasesAwayRayquazaFloat(sprite)
    self:chasesAwaySetRayquazaAnim(sprite, 2, 48, 16)
    sprite.callback = function(sp) self:spriteCbChasesAwayRayquazaFloat(sp) end
    sprite.floating = true
    return
  elseif frame == 352 then
    self:chasesAwayPushDuoBack(self.trioTask)
  end
  if d[7] > 328 and band(d[7], 1) == 0 then
    sprite.x2 = -sprite.x2
    tail.x2 = sprite.x2
  end
  d[7] = s16(d[7] + 1)
end

-- pokeemerald/src/rayquaza_scene.c:3097
function RayScene:spriteCbChasesAwayRayquazaFloat(body)
  local d = body.data
  local tail = self:spr(d[0])
  if band(d[6], tail.data[4]) == 0 then
    body.y2 = body.y2 + d[4]
    tail.y2 = tail.y2 + d[4]
    d[4] = d[4] + d[5]
    local peak = tail.data[5]
    if d[4] >= peak or d[4] <= -peak then
      if d[4] > peak then d[4] = peak elseif d[4] < -peak then d[4] = -peak end
      d[5] = -d[5]
    end
  end
  d[6] = s16(d[6] + 1)
end

-- pokeemerald/src/rayquaza_scene.c:3119
function RayScene:chasesAwaySetRayquazaAnim(body, animNum, x, y)
  local tail = self:spr(body.data[0])
  tail.x, tail.y = body.x + x, body.y + y
  tail.x2, tail.y2 = body.x2, body.y2
  Sprites.startAnim(body, animNum)
  Sprites.startAnim(tail, animNum)
end

-- pokeemerald/src/rayquaza_scene.c:3148
function RayScene:taskChasesAwayAnimateRing(taskId, data)
  local ppu = self.m.ppu
  if data[0] == 0 then
    self:setBgAffine(2, 0x4000, 0x4000, 120, 64, 256, 256, 0)
    self:setReg("DISPCNT", bor(self:getReg("DISPCNT"), Ppu.DISPCNT_BG2_ON))
    data[4] = 16
    data[0] = 1
  elseif data[0] == 1 then
    if data[5] == 8 then playSe("SE_SLIDING_DOOR") end
    if data[2] == 2 then
      data[0] = 2
    else
      data[1] = data[1] + data[4]
      data[5] = data[5] + 1
      if data[3] % 3 == 0 and data[4] ~= 4 then data[4] = data[4] - 2 end
      data[3] = data[3] + 1
      self:setBgAffine(2, 0x4000, 0x4000, 120, 64, 256 - data[1], 256 - data[1], 0)
      if data[1] > 255 then
        data[1], data[3], data[5], data[4] = 0, 0, 0, 16
        data[2] = data[2] + 1
      end
    end
  elseif data[0] == 2 then
    self:setReg("DISPCNT", band(self:getReg("DISPCNT"), bit.bnot(Ppu.DISPCNT_BG2_ON)))
    self.m.tasks:destroy(taskId)
  end
end

function RayScene:frame(input)
  if self.done then return end
  self.frames = self.frames + 1
  self.m:frame(input)
end

function RayScene:draw()
  self.m.ppu:draw(0, 0)
end

local Host = {}
RayScene.Host = Host
Host._screen = nil
Host._step = nil

function RayScene.open(opts)
  local Stack = require("src.ui.game3.stack")
  local Kit = require("src.ui.game3.rse.scene_kit")
  local screen = RayScene.new(opts)
  Host._screen = screen
  Host._step = Kit.stepper()
  local userDone = opts and opts.onDone
  screen.onDone = function()
    Host._screen = nil
    Stack.pop("rayquaza_scene")
    if userDone then userDone(screen) end
  end
  Stack.push("rayquaza_scene", Host, { hideBelow = true, fullscreen = true })
  return screen
end

function RayScene.active()
  return Host._screen
end

function RayScene.reset()
  if Host._screen then
    Host._screen = nil
    require("src.ui.game3.stack").pop("rayquaza_scene")
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

return RayScene
