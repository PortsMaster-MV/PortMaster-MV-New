local bit = require("bit")
local Affine = require("src.core.game3.bg_affine")

local band, bor = bit.band, bit.bor

local Sprites = {}
Sprites.__index = Sprites

Sprites.MAX = 64
Sprites.MATRIX_COUNT = 32
Sprites.TAG_NONE = 0xFFFF

Sprites.AFFINE_OFF = 0
Sprites.AFFINE_NORMAL = 1
Sprites.AFFINE_ERASE = 2
Sprites.AFFINE_DOUBLE = 3

Sprites.OBJ_NORMAL = 0
Sprites.OBJ_BLEND = 1
Sprites.OBJ_WINDOW = 2

-- pokeemerald/src/sprite.c:137
local CENTER_TO_CORNER = {
  [0] = { [0] = { -4, -4 }, { -8, -8 }, { -16, -16 }, { -32, -32 } },
  [1] = { [0] = { -8, -4 }, { -16, -4 }, { -16, -8 }, { -32, -16 } },
  [2] = { [0] = { -4, -8 }, { -4, -16 }, { -8, -16 }, { -16, -32 } },
}

local DIMS = {
  [0] = { [0] = { 8, 8 }, { 16, 16 }, { 32, 32 }, { 64, 64 } },
  [1] = { [0] = { 16, 8 }, { 32, 8 }, { 32, 16 }, { 64, 32 } },
  [2] = { [0] = { 8, 16 }, { 8, 32 }, { 16, 32 }, { 32, 64 } },
}

function Sprites.dims(shape, size)
  local d = DIMS[shape][size]
  return d[1], d[2]
end

function Sprites.shapeOf(w, h)
  for shape = 0, 2 do
    for size = 0, 3 do
      local d = DIMS[shape][size]
      if d[1] == w and d[2] == h then return shape, size end
    end
  end
  error(string.format("gba_sprites: no OBJ shape for %dx%d", w, h))
end

local function s8(v)
  v = band(v, 0xFF)
  if v >= 0x80 then v = v - 0x100 end
  return v
end

local function s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

local function newSprite()
  local s = { data = {}, oam = {} }
  for i = 0, 7 do s.data[i] = 0 end
  return s
end

local function resetSprite(s)
  for k in pairs(s) do s[k] = nil end
  s.data = {}
  for i = 0, 7 do s.data[i] = 0 end
  s.oam = {
    shape = 0, size = 0, affineMode = 0, objMode = 0, priority = 0, paletteNum = 0,
    matrixNum = 0, bpp = 4, x = 0, y = 0, hFlip = false, vFlip = false,
  }
  s.inUse = false
  s.x, s.y, s.x2, s.y2 = 0, 0, 0, 0
  s.centerToCornerVecX, s.centerToCornerVecY = 0, 0
  s.subpriority = 0
  s.animNum, s.animCmdIndex, s.animDelayCounter, s.animLoopCounter = 0, 0, 0, 0
  s.animBeginning, s.animEnded, s.animPaused = false, false, false
  s.affineAnimBeginning, s.affineAnimEnded, s.affineAnimPaused = false, false, false
  s.invisible = false
  s.hFlip, s.vFlip = false, false
  s.frame = 0
  s.callback = nil
end

function Sprites.new(palette)
  local self = setmetatable({ palette = palette }, Sprites)
  self.sprites = {}
  for i = 0, Sprites.MAX do
    self.sprites[i] = newSprite()
    resetSprite(self.sprites[i])
  end
  self.order = {}
  self.matrices = {}
  self.affineStates = {}
  self.paletteTags = {}
  self.reservedPalettes = 0
  self.oamLimit = 64
  self.oamBuffer = {}
  self.oamShown = {}
  self:resetData()
  self:freeAllPalettes()
  return self
end

-- pokeemerald/src/sprite.c:661
function Sprites:resetMatrices()
  for i = 0, Sprites.MATRIX_COUNT - 1 do
    self.matrices[i] = { a = 0x100, b = 0, c = 0, d = 0x100 }
  end
end

-- pokeemerald/src/sprite.c:1271
function Sprites:affineStateReset(i)
  self.affineStates[i] = {
    animNum = 0, animCmdIndex = 0, delayCounter = 0, loopCounter = 0,
    xScale = 0x100, yScale = 0x100, rotation = 0,
  }
end

-- pokeemerald/src/sprite.c:294
function Sprites:resetData()
  for i = 0, Sprites.MAX do
    resetSprite(self.sprites[i])
  end
  for i = 0, Sprites.MAX - 1 do self.order[i] = i end
  self.matrixBitmap = 0
  self:resetMatrices()
  for i = 0, Sprites.MATRIX_COUNT - 1 do self:affineStateReset(i) end
  self.oamLimit = 64
  self.oamBuffer = {}
end

-- pokeemerald/src/sprite.c:1577
function Sprites:freeAllPalettes()
  self.reservedPalettes = 0
  for i = 0, 15 do self.paletteTags[i] = Sprites.TAG_NONE end
end

function Sprites:setReservedPalettes(n)
  self.reservedPalettes = n
end

-- pokeemerald/src/sprite.c:1633
function Sprites:indexOfPaletteTag(tag)
  for i = self.reservedPalettes, 15 do
    if self.paletteTags[i] == tag then return i end
  end
  return 0xFF
end

-- pokeemerald/src/sprite.c:1585
function Sprites:loadPalette(tag, colors)
  local index = self:indexOfPaletteTag(tag)
  if index ~= 0xFF then return index end
  index = self:indexOfPaletteTag(Sprites.TAG_NONE)
  if index == 0xFF then return 0xFF end
  self.paletteTags[index] = tag
  self.palette:load(colors, 256 + index * 16, 16)
  return index
end

-- pokeemerald/src/sprite.c:1427
function Sprites:allocMatrix()
  for i = 0, Sprites.MATRIX_COUNT - 1 do
    local b = bit.lshift(1, i)
    if band(self.matrixBitmap, b) == 0 then
      self.matrixBitmap = bor(self.matrixBitmap, b)
      return i
    end
  end
  return 0xFF
end

-- pokeemerald/src/sprite.c:674
function Sprites:setMatrix(n, a, b, c, d)
  self.matrices[n] = { a = s16(a), b = s16(b), c = s16(c), d = s16(d) }
end

-- pokeemerald/src/sprite.c:687
function Sprites.calcCenterToCornerVec(s, shape, size, affineMode)
  local v = CENTER_TO_CORNER[shape][size]
  local x, y = v[1], v[2]
  if band(affineMode, 2) ~= 0 then
    x, y = s8(x * 2), s8(y * 2)
  end
  s.centerToCornerVecX, s.centerToCornerVecY = x, y
end

function Sprites.setShape(s, w, h)
  local shape, size = Sprites.shapeOf(w, h)
  s.oam.shape, s.oam.size = shape, size
end

local function animCmd(s, idx)
  local anim = s.anims and s.anims[s.animNum + 1]
  return anim and anim[idx + 1]
end

local function imageValue(cmd)
  if not cmd then return -1 end
  if cmd.op == "frame" then return cmd.frame or 0 end
  if cmd.op == "end" then return -1 end
  return -1
end

local function setFlip(s, cmd)
  if band(s.oam.affineMode, 1) == 0 then
    s.oam.hFlip = ((cmd and cmd.hFlip) and true or false) ~= (s.hFlip and true or false)
    s.oam.vFlip = ((cmd and cmd.vFlip) and true or false) ~= (s.vFlip and true or false)
  end
end

-- pokeemerald/src/sprite.c:502
function Sprites:create(template, x, y, subpriority)
  for i = 0, Sprites.MAX - 1 do
    if not self.sprites[i].inUse then return self:createAt(i, template, x, y, subpriority) end
  end
  return Sprites.MAX
end

function Sprites:createAt(i, template, x, y, subpriority)
  local s = self.sprites[i]
  resetSprite(s)
  s.id = i
  s.inUse = true
  s.animBeginning = true
  s.affineAnimBeginning = true
  s.subpriority = subpriority or 0
  local oam = template.oam or {}
  local w, h = template.w, template.h
  local shape, size = Sprites.shapeOf(w, h)
  s.oam.shape, s.oam.size = shape, size
  s.oam.affineMode = oam.affineMode or template.affineMode or 0
  s.oam.objMode = oam.objMode or template.objMode or 0
  s.oam.priority = oam.priority or template.priority or 0
  s.oam.bpp = template.bpp or 4
  s.oam.paletteNum = oam.paletteNum or 0
  s.anims = template.anims
  s.affineAnims = template.affineAnims
  s.sheet = template.sheet
  s.template = template
  s.callback = template.callback
  s.x, s.y = x, y
  Sprites.calcCenterToCornerVec(s, shape, size, s.oam.affineMode)
  local first = animCmd(s, 0)
  local iv = imageValue(first)
  s.frame = iv < 0 and 0 or iv
  if band(s.oam.affineMode, 1) ~= 0 then self:initAffineAnim(s) end
  if template.paletteTag and template.paletteTag ~= Sprites.TAG_NONE then
    s.oam.paletteNum = band(self:indexOfPaletteTag(template.paletteTag), 0xF)
  end
  return i
end

-- pokeemerald/src/sprite.c:1463
function Sprites:initAffineAnim(s)
  local n = self:allocMatrix()
  if n ~= 0xFF then
    Sprites.calcCenterToCornerVec(s, s.oam.shape, s.oam.size, s.oam.affineMode)
    s.oam.matrixNum = n
    s.affineAnimBeginning = true
    self:affineStateReset(n)
  end
end

function Sprites:destroy(s)
  if s.inUse then resetSprite(s) end
end

function Sprites:get(i)
  return self.sprites[i]
end

-- pokeemerald/src/sprite.c:1346
function Sprites.startAnim(s, n)
  s.animNum = n
  s.animBeginning = true
  s.animEnded = false
end

function Sprites.startAnimIfDifferent(s, n)
  if s.animNum ~= n then Sprites.startAnim(s, n) end
end

function Sprites:matrixNumOf(s)
  if band(s.oam.affineMode, 1) ~= 0 then return s.oam.matrixNum end
  return 0
end

-- pokeemerald/src/sprite.c:1373
function Sprites:startAffineAnim(s, n)
  local m = self:matrixNumOf(s)
  local st = self.affineStates[m]
  st.animNum, st.animCmdIndex, st.delayCounter, st.loopCounter = n, 0, 0, 0
  st.xScale, st.yScale, st.rotation = 0x100, 0x100, 0
  s.affineAnimBeginning = true
  s.affineAnimEnded = false
end

-- pokeemerald/src/sprite.c:909
local function beginAnim(s)
  s.animCmdIndex = 0
  s.animEnded = false
  s.animLoopCounter = 0
  local cmd = animCmd(s, 0)
  local iv = imageValue(cmd)
  if iv ~= -1 then
    s.animBeginning = false
    local d = cmd.duration or 0
    if d > 0 then d = d - 1 end
    s.animDelayCounter = d
    setFlip(s, cmd)
    s.frame = iv
  end
end

local continueAnim

-- pokeemerald/src/sprite.c:968
local function animFrame(s)
  local cmd = animCmd(s, s.animCmdIndex)
  local d = cmd.duration or 0
  if d > 0 then d = d - 1 end
  s.animDelayCounter = d
  setFlip(s, cmd)
  s.frame = imageValue(cmd)
end

local function animEnd(s)
  s.animCmdIndex = s.animCmdIndex - 1
  s.animEnded = true
end

local function animJump(s)
  s.animCmdIndex = animCmd(s, s.animCmdIndex).target
  animFrame(s)
end

local function jumpToTopOfLoop(s)
  if s.animLoopCounter ~= 0 then
    s.animCmdIndex = s.animCmdIndex - 1
    while true do
      local prev = animCmd(s, s.animCmdIndex - 1)
      if prev and prev.op == "loop" then break end
      if s.animCmdIndex == 0 then break end
      s.animCmdIndex = s.animCmdIndex - 1
    end
    s.animCmdIndex = s.animCmdIndex - 1
  end
end

local function animLoop(s)
  if s.animLoopCounter ~= 0 then
    s.animLoopCounter = s.animLoopCounter - 1
  else
    s.animLoopCounter = animCmd(s, s.animCmdIndex).count
  end
  jumpToTopOfLoop(s)
  continueAnim(s)
end

-- pokeemerald/src/sprite.c:943
continueAnim = function(s)
  if s.animDelayCounter ~= 0 then
    if not s.animPaused then s.animDelayCounter = s.animDelayCounter - 1 end
    setFlip(s, animCmd(s, s.animCmdIndex))
  elseif not s.animPaused then
    s.animCmdIndex = s.animCmdIndex + 1
    local cmd = animCmd(s, s.animCmdIndex)
    local op = cmd and cmd.op or "end"
    if op == "loop" then animLoop(s)
    elseif op == "jump" then animJump(s)
    elseif op == "end" then animEnd(s)
    else animFrame(s) end
  end
end

local function affineCmd(s, st, idx)
  local anim = s.affineAnims and s.affineAnims[st.animNum + 1]
  return anim and anim[idx + 1]
end

-- pokeemerald/src/sprite.c:1302
function Sprites:_applyRelative(m, cmd)
  local st = self.affineStates[m]
  st.xScale = s16(st.xScale + (cmd.xScale or 0))
  st.yScale = s16(st.yScale + (cmd.yScale or 0))
  st.rotation = band(st.rotation + bit.lshift(band(cmd.rotation or 0, 0xFF), 8), 0xFF00)
  local mat = Affine.objAffineSet(Affine.convertScaleParam(st.xScale), Affine.convertScaleParam(st.yScale), st.rotation)
  self.matrices[m] = mat
end

-- pokeemerald/src/sprite.c:1330
function Sprites:_applyFrame(m, cmd)
  local dummy = { xScale = 0, yScale = 0, rotation = 0, duration = 0 }
  local frame = { xScale = cmd.xScale or 0, yScale = cmd.yScale or 0, rotation = cmd.rotation or 0, duration = cmd.duration or 0 }
  if frame.duration ~= 0 then
    frame.duration = frame.duration - 1
    self:_applyRelative(m, frame)
  else
    local st = self.affineStates[m]
    st.xScale, st.yScale = s16(frame.xScale), s16(frame.yScale)
    st.rotation = band(bit.lshift(band(frame.rotation, 0xFF), 8), 0xFFFF)
    self:_applyRelative(m, dummy)
  end
  return frame.duration
end

-- pokeemerald/src/sprite.c:1067
function Sprites:beginAffineAnim(s)
  if band(s.oam.affineMode, 1) == 0 then return end
  local first = s.affineAnims and s.affineAnims[1] and s.affineAnims[1][1]
  if not first or first.op == "end" then return end
  local m = self:matrixNumOf(s)
  local st = self.affineStates[m]
  st.animCmdIndex, st.delayCounter, st.loopCounter = 0, 0, 0
  local cmd = affineCmd(s, st, 0)
  s.affineAnimBeginning = false
  s.affineAnimEnded = false
  st.delayCounter = self:_applyFrame(m, cmd)
end

-- pokeemerald/src/sprite.c:1084
function Sprites:continueAffineAnim(s)
  if band(s.oam.affineMode, 1) == 0 then return end
  if not s.affineAnims or #s.affineAnims == 0 then return end
  local m = self:matrixNumOf(s)
  local st = self.affineStates[m]
  if st.delayCounter ~= 0 then
    if not s.affineAnimPaused then st.delayCounter = st.delayCounter - 1 end
    if not s.affineAnimPaused then
      self:_applyRelative(m, affineCmd(s, st, st.animCmdIndex))
    end
    return
  elseif s.affineAnimPaused then
    return
  end
  st.animCmdIndex = st.animCmdIndex + 1
  local cmd = affineCmd(s, st, st.animCmdIndex)
  local op = cmd and cmd.op or "end"
  if op == "loop" then
    if st.loopCounter ~= 0 then
      st.loopCounter = st.loopCounter - 1
    else
      st.loopCounter = cmd.count
    end
    if st.loopCounter ~= 0 then
      st.animCmdIndex = st.animCmdIndex - 1
      while true do
        local prev = affineCmd(s, st, st.animCmdIndex - 1)
        if prev and prev.op == "loop" then break end
        if st.animCmdIndex == 0 then break end
        st.animCmdIndex = st.animCmdIndex - 1
      end
      st.animCmdIndex = st.animCmdIndex - 1
    end
    self:continueAffineAnim(s)
  elseif op == "jump" then
    st.animCmdIndex = cmd.target
    st.delayCounter = self:_applyFrame(m, affineCmd(s, st, st.animCmdIndex))
  elseif op == "end" then
    s.affineAnimEnded = true
    st.animCmdIndex = st.animCmdIndex - 1
    self:_applyRelative(m, { xScale = 0, yScale = 0, rotation = 0 })
  else
    st.delayCounter = self:_applyFrame(m, cmd)
  end
end

-- pokeemerald/src/sprite.c:901
function Sprites:animate(s)
  if s.animBeginning then beginAnim(s) else continueAnim(s) end
  if s.affineAnimBeginning then self:beginAffineAnim(s) else self:continueAffineAnim(s) end
end

-- pokeemerald/src/sprite.c:308
function Sprites:animateAll()
  for i = 0, Sprites.MAX - 1 do
    local s = self.sprites[i]
    if s.inUse then
      if s.callback then s.callback(s, self) end
      if s.inUse then self:animate(s) end
    end
  end
end

local function sortY(s)
  local y = s.oam.y
  if y >= 160 then y = y - 256 end
  if s.oam.affineMode == 3 and s.oam.size == 3 and (s.oam.shape == 0 or s.oam.shape == 2) then
    if y > 128 then y = y - 256 end
  end
  return y
end

-- pokeemerald/src/sprite.c:325
function Sprites:buildOam()
  local pri = {}
  for i = 0, Sprites.MAX - 1 do
    local s = self.sprites[i]
    if s.inUse and not s.invisible then
      s.oam.x = band(s.x + s.x2 + s.centerToCornerVecX, 0x1FF)
      s.oam.y = band(s.y + s.y2 + s.centerToCornerVecY, 0xFF)
    end
    pri[i] = bor(band(s.subpriority, 0xFF), bit.lshift(s.oam.priority, 8))
  end
  local order, sp = self.order, self.sprites
  for i = 1, Sprites.MAX - 1 do
    local j = i
    while j > 0 do
      local a, b = order[j - 1], order[j]
      local pa, pb = pri[a], pri[b]
      if pa > pb or (pa == pb and sortY(sp[a]) < sortY(sp[b])) then
        order[j], order[j - 1] = a, b
        j = j - 1
      else
        break
      end
    end
  end
  local out = {}
  for i = 0, Sprites.MAX - 1 do
    local s = sp[order[i]]
    if s.inUse and not s.invisible then
      if #out >= self.oamLimit then break end
      local w, h = Sprites.dims(s.oam.shape, s.oam.size)
      local m = self.matrices[s.oam.matrixNum % Sprites.MATRIX_COUNT]
      out[#out + 1] = {
        sheet = s.sheet, frame = s.frame, w = w, h = h,
        x = s.oam.x, y = s.oam.y,
        affineMode = s.oam.affineMode, objMode = s.oam.objMode,
        priority = s.oam.priority, paletteNum = s.oam.paletteNum, bpp = s.oam.bpp,
        hFlip = s.oam.hFlip, vFlip = s.oam.vFlip,
        matrixNum = s.oam.matrixNum,
        a = m.a, b = m.b, c = m.c, d = m.d,
      }
    end
  end
  self.oamBuffer = out
end

-- pokeemerald/src/sprite.c:640
function Sprites:loadOam()
  self.oamShown = self.oamBuffer
end

return Sprites
