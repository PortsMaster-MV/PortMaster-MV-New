local bit = require("bit")
local Trig = require("src.core.game3.trig")
local Data = require("src.core.game3.mon_anim_data")

local band, arshift = bit.band, bit.arshift
local floor = math.floor

local MonAnim = {}

MonAnim.Data = Data
MonAnim.oob = 0

local function s16(v)
  v = band(floor(v), 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

local function u16(v) return band(floor(v), 0xFFFF) end
local function u8(v) return band(floor(v), 0xFF) end

local function s8(v)
  v = band(floor(v), 0xFF)
  if v >= 0x80 then v = v - 0x100 end
  return v
end

local function div(a, b)
  if b == 0 then return 0 end
  local q = a / b
  if q >= 0 then return floor(q) end
  return -floor(-q)
end

local function mod(a, b)
  if b == 0 then return 0 end
  return a - div(a, b) * b
end

MonAnim.s16, MonAnim.u16, MonAnim.u8, MonAnim.s8, MonAnim.div, MonAnim.mod = s16, u16, u8, s8, div, mod

local function sine(i)
  local v = Trig.SINE[i + 1]
  if v == nil then
    MonAnim.oob = MonAnim.oob + 1
    v = Trig.SINE[band(i, 0xFF) + 1]
  end
  return v
end

-- pokeemerald/src/trig.c:515
local function Sin(index, amplitude)
  return s16(arshift(s16(amplitude) * sine(s16(index)), 8))
end

-- pokeemerald/src/trig.c:521
local function Cos(index, amplitude)
  return s16(arshift(s16(amplitude) * sine(s16(index) + 64), 8))
end

MonAnim.Sin, MonAnim.Cos = Sin, Cos

local function rgb(r, g, b) return r + g * 32 + b * 1024 end
-- pokeemerald/include/constants/rgb.h:15
local RGB_BLACK = rgb(0, 0, 0)
local RGB_RED = rgb(31, 0, 0)
local RGB_GREEN = rgb(0, 31, 0)
local RGB_BLUE = rgb(0, 0, 31)
local RGB_YELLOW = rgb(31, 31, 0)

local MAX_BATTLERS_COUNT = 4

-- pokeemerald/src/pokemon_animation.c:209
local sAnims = {}
for i = 0, MAX_BATTLERS_COUNT - 1 do sAnims[i] = { delay = 0, speed = 0, runs = 1, rotation = 0, data = 0 } end
local sAnimIdx = 0
local sIsSummaryAnim = false

local F = {}
MonAnim.F = F

local function SpriteCallbackDummy() end
local function SpriteCallbackDummy_2() end
local function MonAnimDummySpriteCallback() end
MonAnim.SpriteCallbackDummy = SpriteCallbackDummy
MonAnim.SpriteCallbackDummy_2 = SpriteCallbackDummy_2

-- pokeemerald/src/pokemon_animation.c:207
local function WaitAnimEnd(sprite)
  if sprite.animEnded then sprite.callback = SpriteCallbackDummy end
end
F.WaitAnimEnd = WaitAnimEnd

-- pokeemerald/src/pokemon_animation.c:868
local function SetPosForRotation(sprite, index, amplitudeX, amplitudeY)
  amplitudeX = s16(-amplitudeX)
  amplitudeY = s16(-amplitudeY)
  local xAdder = s16(Cos(index, amplitudeX) - Sin(index, amplitudeY))
  local yAdder = s16(Cos(index, amplitudeY) + Sin(index, amplitudeX))
  amplitudeX = s16(-amplitudeX)
  amplitudeY = s16(-amplitudeY)
  sprite.x2 = s16(xAdder + amplitudeX)
  sprite.y2 = s16(yAdder + amplitudeY)
end

-- pokeemerald/src/pokemon_animation.c:984
local function SetAffineData(sprite, xScale, yScale, rotation)
  local m = sprite.matrix
  m.xScale, m.yScale, m.rotation = s16(xScale), s16(yScale), u16(rotation)
end

local function calcCenterToCornerVec(sprite)
  sprite.centerToCornerVecX = sprite.affineMode == "double" and -64 or -32
end

-- pokeemerald/src/pokemon_animation.c:1003
local function HandleStartAffineAnim(sprite)
  sprite.affineMode = "double"
  sprite.affineAnimNum = (sprite.data[1] == 0) and 1 or 0
  sprite.affineAnimBeginning = true
  calcCenterToCornerVec(sprite)
end

-- pokeemerald/src/pokemon_animation.c:1020
local function HandleSetAffineData(sprite, xScale, yScale, rotation)
  xScale, rotation = s16(xScale), u16(rotation)
  if sprite.data[1] == 0 then
    xScale = s16(-xScale)
    rotation = u16(-rotation)
  end
  SetAffineData(sprite, xScale, yScale, rotation)
end

-- pokeemerald/src/pokemon_animation.c:1031
local function TryFlipX(sprite)
  if sprite.data[1] == 0 then sprite.x2 = s16(-sprite.x2) end
end

-- pokeemerald/src/pokemon_animation.c:1037
local function InitAnimData(id)
  if id >= MAX_BATTLERS_COUNT then return false end
  local a = sAnims[id]
  a.rotation, a.delay, a.runs, a.speed, a.data = 0, 0, 1, 0, 0
  return true
end

-- pokeemerald/src/pokemon_animation.c:1054
local function AddNewAnim()
  sAnimIdx = (sAnimIdx + 1) % MAX_BATTLERS_COUNT
  InitAnimData(sAnimIdx)
  return sAnimIdx
end

-- pokeemerald/src/pokemon_animation.c:1061
local function ResetSpriteAfterAnim(sprite)
  sprite.affineMode = "normal"
  calcCenterToCornerVec(sprite)
  if sIsSummaryAnim then
    sprite.hFlip = sprite.data[1] == 0
    sprite.affineMode = "off"
  end
end

local function blend(sprite, coeff, color)
  sprite.blendCoeff = u8(coeff)
  sprite.blendColor = color
end

local function S(v) return sAnims[v] end

-- pokeemerald/src/pokemon_animation.c:56
function F.Anim_CircularStretchTwice(sprite)
  local d = sprite.data
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 40 then
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local var = s16(mod(div(d[2] * 512, 40), 256))
    d[4] = Sin(var, 32) + 256
    d[5] = Cos(var, 32) + 256
    HandleSetAffineData(sprite, d[4], d[5], 0)
  end
  d[2] = d[2] + 1
end

local function hVibrate(sprite, amp)
  local d = sprite.data
  if d[2] > 40 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
  else
    local sign = (band(d[2], 1) == 0) and 1 or -1
    sprite.x2 = s16(Sin(mod(div(d[2] * 128, 40), 256), amp) * sign)
  end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:57
function F.Anim_HorizontalVibrate(sprite) hVibrate(sprite, 6) end

-- pokeemerald/src/pokemon_animation.c:1131
function F.HorizontalSlide(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] > d[0] then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
  else
    sprite.x2 = Sin(mod(div(d[2] * 384, d[0]), 256), 6)
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

function F.Anim_HorizontalSlide(sprite)
  sprite.data[0] = 40
  F.HorizontalSlide(sprite)
  sprite.callback = F.HorizontalSlide
end

-- pokeemerald/src/pokemon_animation.c:1156
function F.VerticalSlide(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] > d[0] then
    sprite.callback = WaitAnimEnd
    sprite.y2 = 0
  else
    sprite.y2 = s16(-Sin(mod(div(d[2] * 384, d[0]), 256), 6))
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

function F.Anim_VerticalSlide(sprite)
  sprite.data[0] = 40
  F.VerticalSlide(sprite)
  sprite.callback = F.VerticalSlide
end

-- pokeemerald/src/pokemon_animation.c:1181
function F.VerticalJumps(sprite)
  local d = sprite.data
  local counter = d[2]
  if counter > 384 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
    sprite.y2 = 0
  else
    local divCounter = div(counter, 128)
    if divCounter == 0 or divCounter == 1 then
      sprite.y2 = s16(-Sin(mod(counter, 128), d[0] * 2))
    elseif divCounter == 2 or divCounter == 3 then
      counter = counter - 256
      sprite.y2 = s16(-Sin(counter, d[0] * 3))
    end
  end
  d[2] = d[2] + 12
end

function F.Anim_VerticalJumps_Big(sprite)
  sprite.data[0] = 4
  F.VerticalJumps(sprite)
  sprite.callback = F.VerticalJumps
end

-- pokeemerald/src/pokemon_animation.c:61
function F.Anim_VerticalJumpsHorizontalJumps(sprite)
  local d = sprite.data
  local counter = d[2]
  if counter > 768 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
    sprite.y2 = 0
  else
    local divCounter = div(counter, 128)
    if divCounter == 0 or divCounter == 1 then
      sprite.x2 = 0
    elseif divCounter == 2 then
      counter = 0
    elseif divCounter == 3 then
      sprite.x2 = s16(div(-(mod(counter, 128) * 8), 128))
    elseif divCounter == 4 then
      sprite.x2 = s16(div(mod(counter, 128), 8) - 8)
    elseif divCounter == 5 then
      sprite.x2 = s16(div(-(mod(counter, 128) * 8), 128) + 8)
    end
    sprite.y2 = s16(-Sin(mod(counter, 128), 8))
  end
  d[2] = d[2] + 12
end

-- pokeemerald/src/pokemon_animation.c:64
function F.Anim_GrowVibrate(sprite)
  local d = sprite.data
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 40 then
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local index = s16(mod(div(d[2] * 256, 40), 256))
    if mod(d[2], 2) == 0 then
      d[4] = Sin(index, 32) + 256
      d[5] = Sin(index, 32) + 256
    else
      d[4] = Sin(index, 8) + 256
      d[5] = Sin(index, 8) + 256
    end
    HandleSetAffineData(sprite, d[4], d[5], 0)
  end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:1290
local sZigzagData = {
  [0] = { -1, -1, 6 }, { 2, 0, 6 }, { -2, 2, 6 }, { 2, 0, 6 }, { -2, -2, 6 },
  { 2, 0, 6 }, { -2, 2, 6 }, { 2, 0, 6 }, { -1, -1, 6 }, { 0, 0, 0 },
}

-- pokeemerald/src/pokemon_animation.c:1304
function F.Zigzag(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then d[3] = 0 end
  if sZigzagData[d[3]][3] == d[2] then
    if sZigzagData[d[3]][3] == 0 then
      sprite.callback = WaitAnimEnd
    else
      d[3] = d[3] + 1
      d[2] = 0
    end
  end
  if sZigzagData[d[3]][3] == 0 then
    sprite.callback = WaitAnimEnd
  else
    sprite.x2 = s16(sprite.x2 + sZigzagData[d[3]][1])
    sprite.y2 = s16(sprite.y2 + sZigzagData[d[3]][2])
    d[2] = d[2] + 1
    TryFlipX(sprite)
  end
end

function F.Anim_ZigzagFast(sprite)
  F.Zigzag(sprite)
  sprite.callback = F.Zigzag
end

-- pokeemerald/src/pokemon_animation.c:1343
function F.HorizontalShake(sprite)
  local d = sprite.data
  local counter = d[2]
  if counter > 2304 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
  else
    sprite.x2 = Sin(mod(counter, 256), d[7])
  end
  d[2] = d[2] + d[0]
end

function F.Anim_HorizontalShake(sprite)
  sprite.data[0] = 60
  sprite.data[7] = 3
  F.HorizontalShake(sprite)
  sprite.callback = F.HorizontalShake
end

-- pokeemerald/src/pokemon_animation.c:1368
function F.VerticalShake(sprite)
  local d = sprite.data
  local counter = d[2]
  if counter > 2304 then
    sprite.callback = WaitAnimEnd
    sprite.y2 = 0
  else
    sprite.y2 = Sin(mod(counter, 256), 3)
  end
  d[2] = d[2] + d[0]
end

function F.Anim_VerticalShake(sprite)
  sprite.data[0] = 60
  F.VerticalShake(sprite)
  sprite.callback = F.VerticalShake
end

-- pokeemerald/src/pokemon_animation.c:72
function F.Anim_CircularVibrate(sprite)
  local d = sprite.data
  if d[2] > 512 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
    sprite.y2 = 0
  else
    local sign = (band(d[2], 1) == 0) and 1 or -1
    local amplitude = Sin(div(d[2], 4), 8)
    local index = mod(d[2], 256)
    sprite.y2 = s16(Sin(index, amplitude) * sign)
    sprite.x2 = s16(Cos(index, amplitude) * sign)
  end
  d[2] = d[2] + 9
end

-- pokeemerald/src/pokemon_animation.c:1420
function F.Twist(sprite)
  local d = sprite.data
  local a = S(d[0])
  if a.delay ~= 0 then
    a.delay = a.delay - 1
  else
    if d[2] == 0 and a.data == 0 then
      HandleStartAffineAnim(sprite)
      a.data = a.data + 1
    end
    if d[2] > a.rotation then
      HandleSetAffineData(sprite, 256, 256, 0)
      if a.runs > 1 then
        a.runs = a.runs - 1
        a.delay = 10
        d[2] = 0
      else
        ResetSpriteAfterAnim(sprite)
        sprite.callback = WaitAnimEnd
      end
    else
      d[6] = Sin(mod(d[2], 256), 4096)
      HandleSetAffineData(sprite, 256, 256, d[6])
    end
    d[2] = d[2] + 16
  end
end

function F.Anim_Twist(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 512
  sAnims[id].delay = 0
  F.Twist(sprite)
  sprite.callback = F.Twist
end

-- pokeemerald/src/pokemon_animation.c:1472
function F.Spin(sprite)
  local d = sprite.data
  local a = S(u8(d[0]))
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > a.delay then
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    d[6] = s16(div(65536, a.data) * d[2])
    HandleSetAffineData(sprite, 256, 256, d[6])
  end
  d[2] = d[2] + 1
end

function F.Anim_Spin_Long(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].delay = 60
  sAnims[id].data = 20
  F.Spin(sprite)
  sprite.callback = F.Spin
end

-- pokeemerald/src/pokemon_animation.c:1504
function F.CircleCounterclockwise(sprite)
  local d = sprite.data
  local a = S(u8(d[0]))
  TryFlipX(sprite)
  if d[2] > a.rotation then
    sprite.x2 = 0
    sprite.y2 = 0
    sprite.callback = WaitAnimEnd
  else
    local index = s16(mod(d[2] + 192, 256))
    sprite.x2 = s16(-Cos(index, a.data * 2))
    sprite.y2 = s16(Sin(index, a.data) + a.data)
  end
  d[2] = d[2] + a.speed
  TryFlipX(sprite)
end

function F.Anim_CircleCounterclockwise(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 512
  sAnims[id].data = 6
  sAnims[id].speed = 24
  F.CircleCounterclockwise(sprite)
  sprite.callback = F.CircleCounterclockwise
end

-- pokeemerald/src/pokemon_animation.c:1539
local function GlowColor(sprite, color, colorIncrement, speed)
  local d = sprite.data
  if d[2] == 0 then d[7] = 0x100 + (sprite.paletteNum or 0) * 16 end
  if d[2] > 128 then
    blend(sprite, 0, color)
    sprite.callback = WaitAnimEnd
  else
    d[6] = Sin(d[2], colorIncrement)
    blend(sprite, d[6], color)
  end
  d[2] = d[2] + speed
end

function F.Anim_GlowBlack(sprite) GlowColor(sprite, RGB_BLACK, 16, 1) end

-- pokeemerald/src/pokemon_animation.c:77
function F.Anim_HorizontalStretch(sprite)
  local d = sprite.data
  local index1, index2 = 0, 0
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 40 then
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    index2 = div(d[2] * 128, 40)
    if d[2] >= 10 and d[2] <= 29 then
      d[7] = s16(d[7] + 51)
      index1 = band(0xFF, d[7])
    end
    if d[1] == 0 then
      d[4] = (Sin(index2, 40) - 256) + Sin(index1, 16)
    else
      d[4] = (256 - Sin(index2, 40)) - Sin(index1, 16)
    end
    d[5] = Sin(index2, 16) + 256
    SetAffineData(sprite, d[4], d[5], 0)
  end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:78
function F.Anim_VerticalStretch(sprite)
  local d = sprite.data
  local posY, index1, index2 = 0, 0, 0
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 40 then
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
    sprite.y2 = posY
  else
    index2 = div(d[2] * 128, 40)
    if d[2] >= 10 and d[2] <= 29 then
      d[7] = s16(d[7] + 51)
      index1 = band(0xFF, d[7])
    end
    if d[1] == 0 then
      d[4] = -Sin(index2, 16) - 256
    else
      d[4] = Sin(index2, 16) + 256
    end
    d[5] = (256 - Sin(index2, 40)) - Sin(index1, 8)
    if d[5] ~= 256 then posY = div(256 - d[5], 8) end
    sprite.y2 = s16(-posY)
    SetAffineData(sprite, d[4], d[5], 0)
  end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:622
local sVerticalShakeData = { [0] = { 6, 30 }, { 254, 15 }, { 6, 30 }, { 255, 0 } }

-- pokeemerald/src/pokemon_animation.c:1638
function F.VerticalShakeTwice(sprite)
  local d = sprite.data
  local index = u8(d[2])
  local var7 = u8(d[6])
  local var5 = sVerticalShakeData[d[5]][1]
  local var6 = sVerticalShakeData[d[5]][2]
  local amplitude
  if var5 ~= 254 then
    amplitude = u8(div((var6 - var7) * var5, var6))
  else
    amplitude = 0
  end
  if var5 == 255 then
    sprite.callback = WaitAnimEnd
    sprite.y2 = 0
  else
    sprite.y2 = Sin(index, amplitude)
    if var7 == var6 then
      d[5] = d[5] + 1
      d[6] = 0
    else
      d[2] = d[2] + d[0]
      d[6] = d[6] + 1
    end
  end
end

function F.Anim_VerticalShakeTwice(sprite)
  sprite.data[0] = 48
  F.VerticalShakeTwice(sprite)
  sprite.callback = F.VerticalShakeTwice
end

-- pokeemerald/src/pokemon_animation.c:81
function F.Anim_TipMoveForward(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  local counter = u8(d[2])
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 35 then
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
  else
    local index = s16(div((counter - 10) * 128, 20))
    if counter < 10 then
      HandleSetAffineData(sprite, 256, 256, div(counter, 2) * 512)
    elseif counter >= 10 and counter <= 29 then
      sprite.x2 = s16(-Sin(index, 5))
    else
      HandleSetAffineData(sprite, 256, 256, div(35 - counter, 2) * 1024)
    end
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:82
function F.Anim_HorizontalPivot(sprite)
  local d = sprite.data
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 100 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local index = s16(div(d[2] * 256, 100))
    sprite.y2 = Sin(index, 10)
    HandleSetAffineData(sprite, 256, 256, Sin(index, 3276))
  end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:1735
function F.VerticalSlideWobble(sprite)
  local d = sprite.data
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 100 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local index = s16(div(d[2] * 256, 100))
    local var = band(div(d[2] * 512, 100), 0xFF)
    sprite.y2 = Sin(index, d[0])
    HandleSetAffineData(sprite, 256, 256, Sin(var, 3276))
  end
  d[2] = d[2] + 1
end

function F.Anim_VerticalSlideWobble(sprite)
  sprite.data[0] = 10
  F.VerticalSlideWobble(sprite)
  sprite.callback = F.VerticalSlideWobble
end

-- pokeemerald/src/pokemon_animation.c:1769
function F.RisingWobble(sprite)
  local d = sprite.data
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 100 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local index = s16(div(d[2] * 256, 100))
    local var = band(div(d[2] * 512, 100), 0xFF)
    sprite.y2 = s16(-Sin(div(index, 2), d[0] * 2))
    HandleSetAffineData(sprite, 256, 256, Sin(var, 3276))
  end
  d[2] = d[2] + 1
end

function F.Anim_RisingWobble(sprite)
  sprite.data[0] = 5
  F.RisingWobble(sprite)
  sprite.callback = F.RisingWobble
end

-- pokeemerald/src/pokemon_animation.c:84
function F.Anim_HorizontalSlideWobble(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  if d[2] > 100 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local index = s16(div(d[2] * 256, 100))
    local var = band(div(d[2] * 512, 100), 0xFF)
    sprite.x2 = Sin(index, 8)
    HandleSetAffineData(sprite, 256, 256, Sin(var, 3276))
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:1834
function F.VerticalSquishBounce(sprite)
  local d = sprite.data
  local posY = 0
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[3] = 0
  end
  TryFlipX(sprite)
  if d[2] > d[0] * 3 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local yScale = s16(Sin(d[4], 32) + 256)
    if d[2] > d[0] and d[2] < d[0] * 2 then d[3] = s16(d[3] + div(128, d[0])) end
    if yScale > 256 then posY = div(256 - yScale, 8) end
    sprite.y2 = s16(-Sin(d[3], 10) - posY)
    HandleSetAffineData(sprite, 256 - Sin(d[4], 32), yScale, 0)
    d[2] = d[2] + 1
    d[4] = band(d[4] + div(128, d[0]), 0xFF)
  end
  TryFlipX(sprite)
end

function F.Anim_VerticalSquishBounce(sprite)
  sprite.data[0] = 16
  F.VerticalSquishBounce(sprite)
  sprite.callback = F.VerticalSquishBounce
end

-- pokeemerald/src/pokemon_animation.c:1878
function F.ShrinkGrow(sprite)
  local d = sprite.data
  local posY = 0
  if d[2] > div(128, d[6]) * d[7] then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local yScale = s16(Sin(d[4], 32) + 256)
    if yScale > 256 then posY = div(256 - yScale, 8) end
    sprite.y2 = s16(-posY)
    HandleSetAffineData(sprite, Sin(d[4], 48) + 256, yScale, 0)
    d[2] = d[2] + 1
    d[4] = band(d[4] + d[6], 0xFF)
  end
end

function F.Anim_ShrinkGrow(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[7] = 3
    d[6] = 8
  end
  F.ShrinkGrow(sprite)
end

-- pokeemerald/src/pokemon_animation.c:1915
local sBounceRotateToSidesData = {
  [0] = {
    [0] = { 0, 8, 8 }, { 8, -8, 12 }, { -8, 8, 12 }, { 8, -8, 12 },
    { -8, 8, 12 }, { 8, -8, 12 }, { -8, 0, 12 }, { 0, 0, 0 },
  },
  [1] = {
    [0] = { 0, 8, 16 }, { 8, -8, 24 }, { -8, 8, 24 }, { 8, -8, 24 },
    { -8, 8, 24 }, { 8, -8, 24 }, { -8, 0, 24 }, { 0, 0, 0 },
  },
}

-- pokeemerald/src/pokemon_animation.c:1939
function F.BounceRotateToSides(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  local a = S(u8(d[0]))
  local var = a.rotation
  local tbl = sBounceRotateToSidesData[a.data]
  local r9 = s8(tbl[d[4]][1])
  local r10 = s16(tbl[d[4]][2] - r9)
  local r7 = d[3]
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
  end
  local time = tbl[d[4]][3]
  if time == 0 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.x2 = 0
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    sprite.y2 = s16(-Sin(div(r7 * 128, time), 10))
    sprite.x2 = s16(div(r10 * r7, time) + r9)
    local rotation = u16(div(-(var * sprite.x2), 8))
    HandleSetAffineData(sprite, 256, 256, rotation)
    if r7 == time then
      d[4] = d[4] + 1
      d[3] = 0
    else
      d[3] = d[3] + 1
    end
  end
  TryFlipX(sprite)
end

function F.Anim_BounceRotateToSides(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 4096
  sAnims[id].data = sprite.data[6]
  F.BounceRotateToSides(sprite)
  sprite.callback = F.BounceRotateToSides
end

-- pokeemerald/src/pokemon_animation.c:87
function F.Anim_GlowOrange(sprite) GlowColor(sprite, rgb(31, 22, 0), 12, 2) end
function F.Anim_GlowRed(sprite) GlowColor(sprite, RGB_RED, 12, 2) end
function F.Anim_GlowBlue(sprite) GlowColor(sprite, RGB_BLUE, 12, 2) end
function F.Anim_GlowYellow(sprite) GlowColor(sprite, RGB_YELLOW, 12, 2) end
function F.Anim_GlowPurple(sprite) GlowColor(sprite, rgb(24, 0, 24), 12, 2) end

-- pokeemerald/src/pokemon_animation.c:92
function F.Anim_BackAndLunge(sprite)
  HandleStartAffineAnim(sprite)
  sprite.callback = F.BackAndLunge_0
end

function F.BackAndLunge_0(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + 1)
  if sprite.x2 > 7 then
    sprite.x2 = 8
    sprite.data[7] = 2
    sprite.callback = F.BackAndLunge_1
  end
  TryFlipX(sprite)
end

function F.BackAndLunge_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 - d[7])
  d[7] = d[7] + 1
  if sprite.x2 <= 0 then
    local var = u8(d[7])
    d[6] = 0
    local subResult = sprite.x2
    repeat
      subResult = s16(subResult - var)
      d[6] = d[6] + 1
      var = u8(var + 1)
    until not (subResult > -8)
    d[5] = 1
    sprite.callback = F.BackAndLunge_2
  end
  TryFlipX(sprite)
end

function F.BackAndLunge_2(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 - d[7])
  d[7] = d[7] + 1
  local rotation = u8(div(d[5] * 6, d[6]))
  d[5] = d[5] + 1
  if d[5] > d[6] then d[5] = d[6] end
  HandleSetAffineData(sprite, 256, 256, rotation * 256)
  if sprite.x2 < -8 then
    sprite.x2 = -8
    d[4] = 2
    d[3] = 0
    d[2] = rotation
    sprite.callback = F.BackAndLunge_3
  end
  TryFlipX(sprite)
end

function F.BackAndLunge_3(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[3] > 11 then
    d[2] = d[2] - 2
    if d[2] < 0 then d[2] = 0 end
    HandleSetAffineData(sprite, 256, 256, d[2] * 256)
    if d[2] == 0 then sprite.callback = F.BackAndLunge_4 end
  else
    sprite.x2 = s16(sprite.x2 + d[4])
    d[4] = -d[4]
    d[3] = d[3] + 1
  end
  TryFlipX(sprite)
end

function F.BackAndLunge_4(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + 2)
  if sprite.x2 > 0 then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:93
function F.Anim_BackFlip(sprite)
  HandleStartAffineAnim(sprite)
  sprite.data[3] = 0
  sprite.callback = F.BackFlip_0
end

function F.BackFlip_0(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + 1)
  sprite.y2 = s16(sprite.y2 - 1)
  if mod(sprite.x2, 2) == 0 and d[3] <= 0 then d[3] = 10 end
  if sprite.x2 > 7 then
    sprite.x2 = 8
    sprite.y2 = -8
    d[4] = 0
    sprite.callback = F.BackFlip_1
  end
  TryFlipX(sprite)
end

function F.BackFlip_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(Cos(d[4], 16) - 8)
  sprite.y2 = s16(Sin(d[4], 16) - 8)
  if d[4] > 63 then
    d[2] = 160
    d[3] = 10
    sprite.callback = F.BackFlip_2
  end
  d[4] = d[4] + 8
  if d[4] > 64 then d[4] = 64 end
  TryFlipX(sprite)
end

function F.BackFlip_2(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[3] > 0 then
    d[3] = d[3] - 1
  else
    sprite.x2 = s16(Cos(d[2], 5) - 4)
    sprite.y2 = s16(-Sin(d[2], 5) + 4)
    d[2] = d[2] - 4
    local rotation = d[2] - 32
    HandleSetAffineData(sprite, 256, 256, rotation * 512)
    if d[2] <= 32 then
      sprite.x2 = 0
      sprite.y2 = 0
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    end
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:94
function F.Anim_Flicker(sprite)
  local d = sprite.data
  if d[3] > 0 then
    d[3] = d[3] - 1
  else
    d[4] = (d[4] == 0) and 1 or 0
    sprite.invisible = d[4] ~= 0
    d[2] = d[2] + 1
    if d[2] > 19 then
      sprite.invisible = false
      sprite.callback = WaitAnimEnd
    end
    d[3] = 2
  end
end

-- pokeemerald/src/pokemon_animation.c:95
function F.Anim_BackFlipBig(sprite)
  HandleStartAffineAnim(sprite)
  sprite.callback = F.BackFlipBig_0
end

function F.BackFlipBig_0(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 - 1)
  sprite.y2 = s16(sprite.y2 + 1)
  if sprite.x2 <= -16 then
    sprite.x2 = -16
    sprite.y2 = 16
    sprite.callback = F.BackFlipBig_1
    sprite.data[2] = 160
  end
  TryFlipX(sprite)
end

function F.BackFlipBig_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[2] = d[2] - 4
  sprite.x2 = Cos(d[2], 22)
  sprite.y2 = s16(-Sin(d[2], 22))
  local rotation = d[2] - 32
  HandleSetAffineData(sprite, 256, 256, rotation * 512)
  if d[2] <= 32 then sprite.callback = F.BackFlipBig_2 end
  TryFlipX(sprite)
end

function F.BackFlipBig_2(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 - 1)
  sprite.y2 = s16(sprite.y2 + 1)
  if sprite.x2 <= 0 then
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:96
function F.Anim_FrontFlip(sprite)
  HandleStartAffineAnim(sprite)
  sprite.callback = F.FrontFlip_0
end

function F.FrontFlip_0(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + 1)
  sprite.y2 = s16(sprite.y2 - 1)
  if sprite.x2 > 15 then
    sprite.data[2] = 0
    sprite.callback = F.FrontFlip_1
  end
  TryFlipX(sprite)
end

function F.FrontFlip_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[2] = d[2] + 16
  if sprite.x2 <= -16 then
    sprite.x2 = -16
    sprite.y2 = 16
    d[2] = 0
    sprite.callback = F.FrontFlip_2
  else
    sprite.x2 = s16(sprite.x2 - 2)
    sprite.y2 = s16(sprite.y2 + 2)
  end
  HandleSetAffineData(sprite, 256, 256, d[2] * 256)
  TryFlipX(sprite)
end

function F.FrontFlip_2(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + 1)
  sprite.y2 = s16(sprite.y2 - 1)
  if sprite.x2 >= 0 then
    sprite.x2 = 0
    sprite.y2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:97
function F.Anim_TumblingFrontFlip(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].speed = 2
  F.TumblingFrontFlip(sprite)
  sprite.callback = F.TumblingFrontFlip
end

function F.TumblingFrontFlip(sprite)
  local d = sprite.data
  local a = S(d[0])
  if a.delay ~= 0 then
    a.delay = a.delay - 1
  else
    TryFlipX(sprite)
    if d[2] == 0 then
      d[2] = d[2] + 1
      HandleStartAffineAnim(sprite)
      d[7] = a.speed
      d[3] = -1
      d[4] = -1
      d[5] = 0
      d[6] = 0
    end
    sprite.x2 = s16(sprite.x2 + d[7] * 2 * d[3])
    sprite.y2 = s16(sprite.y2 + d[7] * d[4])
    d[6] = d[6] + 8
    if sprite.x2 <= -16 or sprite.x2 >= 16 then
      sprite.x2 = s16(d[3] * 16)
      d[3] = -d[3]
      d[5] = d[5] + 1
    elseif sprite.y2 <= -16 or sprite.y2 >= 16 then
      sprite.y2 = s16(d[4] * 16)
      d[4] = -d[4]
      d[5] = d[5] + 1
    end
    if d[5] > 5 and sprite.x2 <= 0 then
      sprite.x2 = 0
      sprite.y2 = 0
      if a.runs > 1 then
        a.runs = a.runs - 1
        d[5] = 0
        d[6] = 0
        a.delay = 10
      else
        ResetSpriteAfterAnim(sprite)
        sprite.callback = WaitAnimEnd
      end
    end
    HandleSetAffineData(sprite, 256, 256, d[6] * 256)
    TryFlipX(sprite)
  end
end

-- pokeemerald/src/pokemon_animation.c:98
function F.Anim_Figure8(sprite)
  HandleStartAffineAnim(sprite)
  sprite.data[6] = 0
  sprite.data[7] = 0
  sprite.callback = F.Figure8
end

function F.Figure8(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[6] = d[6] + 4
  sprite.x2 = s16(-Sin(d[6], 16))
  sprite.y2 = s16(-Sin(band(d[6] * 2, 0xFF), 8))
  if d[6] > 192 and d[7] == 1 then
    HandleSetAffineData(sprite, 256, 256, 0)
    d[7] = d[7] + 1
  elseif d[6] > 64 and d[7] == 0 then
    HandleSetAffineData(sprite, -256, 256, 0)
    d[7] = d[7] + 1
  end
  if d[6] > 255 then
    sprite.x2 = 0
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:604
local sYellowFlashData = {
  [0] = { 0, 5 }, { 1, 1 }, { 0, 15 }, { 1, 4 }, { 0, 2 }, { 1, 2 }, { 0, 2 },
  { 1, 2 }, { 0, 2 }, { 1, 2 }, { 0, 2 }, { 1, 2 }, { 0, 2 }, { 0, 255 },
}

-- pokeemerald/src/pokemon_animation.c:99
function F.Anim_FlashYellow(sprite)
  local d = sprite.data
  d[2] = d[2] + 1
  if d[2] == 1 then
    d[7] = 0x100 + (sprite.paletteNum or 0) * 16
    d[6] = 0
    d[5] = 0
    d[4] = 0
  end
  if sYellowFlashData[d[6]][2] == 255 then
    sprite.callback = WaitAnimEnd
  else
    if d[4] == 1 then
      if sYellowFlashData[d[6]][1] ~= 0 then
        blend(sprite, 16, RGB_YELLOW)
      else
        blend(sprite, 0, RGB_YELLOW)
      end
      d[4] = 0
    end
    if sYellowFlashData[d[6]][2] == d[5] then
      d[4] = 1
      d[5] = 0
      d[6] = d[6] + 1
    else
      d[5] = d[5] + 1
    end
  end
end

-- pokeemerald/src/pokemon_animation.c:2512
function F.SwingConcave(sprite)
  local d = sprite.data
  local a = S(d[0])
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  TryFlipX(sprite)
  if d[2] > a.data then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.x2 = 0
    if a.runs > 1 then
      a.runs = a.runs - 1
      d[2] = 0
    else
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    end
  else
    local index = s16(div(d[2] * 256, a.data))
    sprite.x2 = s16(-Sin(index, 10))
    HandleSetAffineData(sprite, 256, 256, Sin(index, 3276))
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

function F.Anim_SwingConcave_FastShort(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 50
  F.SwingConcave(sprite)
  sprite.callback = F.SwingConcave
end

-- pokeemerald/src/pokemon_animation.c:2552
function F.SwingConvex(sprite)
  local d = sprite.data
  local a = S(d[0])
  if d[2] == 0 then HandleStartAffineAnim(sprite) end
  TryFlipX(sprite)
  if d[2] > a.data then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.x2 = 0
    if a.runs > 1 then
      a.runs = a.runs - 1
      d[2] = 0
    else
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    end
  else
    local index = s16(div(d[2] * 256, a.data))
    sprite.x2 = s16(-Sin(index, 10))
    HandleSetAffineData(sprite, 256, 256, -Sin(index, 3276))
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

function F.Anim_SwingConvex_FastShort(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 50
  F.SwingConvex(sprite)
  sprite.callback = F.SwingConvex
end

-- pokeemerald/src/pokemon_animation.c:102
function F.Anim_RotateUpSlamDown(sprite)
  HandleStartAffineAnim(sprite)
  sprite.data[6] = s16(-div(14 * sprite.centerToCornerVecX, 10))
  sprite.data[7] = 128
  sprite.callback = F.RotateUpSlamDown_0
end

function F.RotateUpSlamDown_0(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[7] = d[7] - 1
  sprite.x2 = s16(d[6] + Cos(d[7], d[6]))
  sprite.y2 = s16(-Sin(d[7], d[6]))
  HandleSetAffineData(sprite, 256, 256, (d[7] - 128) * 256)
  if d[7] <= 120 then
    d[7] = 120
    d[3] = 0
    sprite.callback = F.RotateUpSlamDown_1
  end
  TryFlipX(sprite)
end

function F.RotateUpSlamDown_1(sprite)
  local d = sprite.data
  if d[3] == 20 then
    sprite.callback = F.RotateUpSlamDown_2
    d[3] = 0
  end
  d[3] = d[3] + 1
end

function F.RotateUpSlamDown_2(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[7] = d[7] + 2
  sprite.x2 = s16(d[6] + Cos(d[7], d[6]))
  sprite.y2 = s16(-Sin(d[7], d[6]))
  HandleSetAffineData(sprite, 256, 256, (d[7] - 128) * 256)
  if d[7] >= 128 then
    sprite.x2 = 0
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    d[2] = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = F.Anim_VerticalShake
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:2656
function F.DeepVerticalSquishBounce(sprite)
  local d = sprite.data
  local a = S(d[0])
  if a.delay ~= 0 then
    a.delay = a.delay - 1
  else
    if d[2] == 0 then
      HandleStartAffineAnim(sprite)
      d[4] = 0
      d[5] = 0
      d[2] = 1
    end
    if d[5] == 0 then
      d[7] = Sin(d[4], 256)
      sprite.y2 = Sin(d[4], 16)
      d[6] = Sin(d[4], 32)
      HandleSetAffineData(sprite, 256 - d[6], 256 + d[7], 0)
      if d[4] == 128 then
        d[4] = 0
        d[5] = 1
      end
    elseif d[5] == 1 then
      d[7] = Sin(d[4], 32)
      sprite.y2 = s16(-Sin(d[4], 8))
      d[6] = Sin(d[4], 128)
      HandleSetAffineData(sprite, 256 + d[6], 256 - d[7], 0)
      if d[4] == 128 then
        if a.runs > 1 then
          a.runs = a.runs - 1
          a.delay = 10
          d[4] = 0
          d[5] = 0
        else
          HandleSetAffineData(sprite, 256, 256, 0)
          ResetSpriteAfterAnim(sprite)
          sprite.callback = WaitAnimEnd
        end
      end
    end
    d[4] = d[4] + a.rotation
  end
end

function F.Anim_DeepVerticalSquishBounce(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 4
  F.DeepVerticalSquishBounce(sprite)
  sprite.callback = F.DeepVerticalSquishBounce
end

-- pokeemerald/src/pokemon_animation.c:104
function F.Anim_HorizontalJumps(sprite)
  local d = sprite.data
  local counter = d[2]
  TryFlipX(sprite)
  if counter > 512 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
    sprite.y2 = 0
  else
    local c = div(d[2], 128)
    if c == 0 then
      sprite.x2 = s16(div(-(mod(counter, 128) * 8), 128))
    elseif c == 1 then
      sprite.x2 = s16(div(mod(counter, 128), 16) - 8)
    elseif c == 2 then
      sprite.x2 = s16(div(mod(counter, 128), 16))
    elseif c == 3 then
      sprite.x2 = s16(div(-(mod(counter, 128) * 8), 128) + 8)
    end
    sprite.y2 = s16(-Sin(mod(counter, 128), 8))
  end
  d[2] = d[2] + 12
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:105
function F.Anim_HorizontalJumpsVerticalStretch(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = -1
  HandleStartAffineAnim(sprite)
  sprite.data[3] = 0
  F.HorizontalJumpsVerticalStretch_0(sprite)
  sprite.callback = F.HorizontalJumpsVerticalStretch_0
end

function F.HorizontalJumpsVerticalStretch_0(sprite)
  local d = sprite.data
  local a = S(d[0])
  if a.delay ~= 0 then
    a.delay = a.delay - 1
  else
    TryFlipX(sprite)
    local counter = d[2]
    if d[2] > 128 then
      d[2] = 0
      sprite.callback = F.HorizontalJumpsVerticalStretch_1
    else
      local var = 8 * a.data
      sprite.x2 = s16(div(var * mod(counter, 128), 128))
      sprite.y2 = s16(-Sin(mod(counter, 128), 8))
      d[2] = d[2] + 12
    end
    TryFlipX(sprite)
  end
end

function F.HorizontalJumpsVerticalStretch_1(sprite)
  local d = sprite.data
  local a = S(d[0])
  TryFlipX(sprite)
  if d[2] > 48 then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.y2 = 0
    d[2] = 0
    sprite.callback = F.HorizontalJumpsVerticalStretch_2
  else
    local yScale = s16(Sin(d[4], 64) + 256)
    if d[2] >= 16 and d[2] <= 31 then
      d[3] = d[3] + 8
      sprite.x2 = s16(sprite.x2 - a.data)
    end
    local yDelta = 0
    if yScale > 256 then yDelta = div(256 - yScale, 8) end
    sprite.y2 = s16(-Sin(d[3], 20) - yDelta)
    HandleSetAffineData(sprite, 256 - Sin(d[4], 32), yScale, 0)
    d[2] = d[2] + 1
    d[4] = band(d[4] + 8, 0xFF)
  end
  TryFlipX(sprite)
end

function F.HorizontalJumpsVerticalStretch_2(sprite)
  local d = sprite.data
  local a = S(d[0])
  TryFlipX(sprite)
  local counter = d[2]
  if counter > 128 then
    if a.runs > 1 then
      a.runs = a.runs - 1
      a.delay = 10
      d[3] = 0
      d[2] = 0
      d[4] = 0
      sprite.callback = F.HorizontalJumpsVerticalStretch_0
    else
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    end
    sprite.x2 = 0
    sprite.y2 = 0
  else
    local var = a.data
    sprite.x2 = s16(div(var * (mod(counter, 128) * 8), 128) + 8 * -var)
    sprite.y2 = s16(-Sin(mod(counter, 128), 8))
  end
  d[2] = d[2] + 12
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:2870
function F.RotateToSides(sprite)
  local d = sprite.data
  local a = S(d[0])
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
  end
  TryFlipX(sprite)
  if d[7] > 254 then
    sprite.x2 = 0
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    if a.runs > 1 then
      a.runs = a.runs - 1
      d[2] = 0
      d[7] = 0
    else
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    end
    TryFlipX(sprite)
  else
    sprite.x2 = s16(-Sin(d[7], 16))
    local rotation = u16(Sin(d[7], 32))
    HandleSetAffineData(sprite, 256, 256, rotation * 256)
    d[7] = d[7] + a.rotation
    TryFlipX(sprite)
  end
end

function F.Anim_RotateToSides_Fast(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 4
  F.RotateToSides(sprite)
  sprite.callback = F.RotateToSides
end

-- pokeemerald/src/pokemon_animation.c:107
function F.Anim_RotateUpToSides(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
  end
  TryFlipX(sprite)
  if d[7] > 254 then
    sprite.x2 = 0
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
    TryFlipX(sprite)
  else
    sprite.x2 = s16(-Sin(d[7], 16))
    sprite.y2 = s16(-Sin(mod(d[7], 128), 16))
    local rotation = u16(Sin(d[7], 32))
    HandleSetAffineData(sprite, 256, 256, rotation * 256)
    d[7] = d[7] + 8
    TryFlipX(sprite)
  end
end

-- pokeemerald/src/pokemon_animation.c:108
function F.Anim_FlickerIncreasing(sprite)
  local d = sprite.data
  if d[2] == 0 then d[7] = 0 end
  if d[2] == d[7] then
    d[7] = 0
    d[2] = d[2] + 1
    sprite.invisible = false
  else
    d[7] = d[7] + 1
    sprite.invisible = true
  end
  if d[2] > 10 then
    sprite.invisible = false
    sprite.callback = WaitAnimEnd
  end
end

-- pokeemerald/src/pokemon_animation.c:109
function F.Anim_TipHopForward(sprite)
  HandleStartAffineAnim(sprite)
  sprite.data[7] = 0
  sprite.callback = F.TipHopForward_0
end

function F.TipHopForward_0(sprite)
  local d = sprite.data
  if d[7] > 31 then
    d[7] = 32
    d[2] = 0
    sprite.callback = F.TipHopForward_1
  else
    d[7] = d[7] + 4
  end
  HandleSetAffineData(sprite, 256, 256, d[7] * 256)
end

function F.TipHopForward_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] > 512 then
    sprite.callback = F.TipHopForward_2
    d[6] = 0
  else
    sprite.x2 = s16(div(-(d[2] * 16), 512))
    sprite.y2 = s16(-Sin(mod(d[2], 128), 4))
    d[2] = d[2] + 12
  end
  TryFlipX(sprite)
end

function F.TipHopForward_2(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[7] = d[7] - 2
  if d[7] < 0 then
    d[7] = 0
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    sprite.x2 = s16(-Sin(d[7] * 2, 16))
  end
  HandleSetAffineData(sprite, 256, 256, d[7] * 256)
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:110
function F.Anim_PivotShake(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
  end
  TryFlipX(sprite)
  if d[7] > 255 then
    sprite.x2 = 0
    sprite.y2 = 0
    d[7] = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    d[7] = d[7] + 16
    sprite.x2 = s16(-Sin(mod(d[7], 128), 8))
    sprite.y2 = s16(-Sin(mod(d[7], 128), 8))
  end
  local rotation = u16(Sin(mod(d[7], 128), 16))
  HandleSetAffineData(sprite, 256, 256, rotation * 256)
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:111
function F.Anim_TipAndShake(sprite)
  HandleStartAffineAnim(sprite)
  sprite.data[7] = 0
  sprite.data[4] = 0
  sprite.callback = F.TipAndShake_0
end

function F.TipAndShake_0(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[7] > 24 then
    d[4] = d[4] + 1
    if d[4] > 4 then
      d[4] = 0
      sprite.callback = F.TipAndShake_1
    end
  else
    d[7] = d[7] + 2
    sprite.x2 = Sin(d[7], 8)
    sprite.y2 = s16(-Sin(d[7], 8))
  end
  HandleSetAffineData(sprite, 256, 256, -d[7] * 256)
  TryFlipX(sprite)
end

function F.TipAndShake_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[7] > 32 then
    d[6] = 1
    sprite.callback = F.TipAndShake_2
  else
    d[7] = d[7] + 2
    sprite.x2 = Sin(d[7], 8)
    sprite.y2 = s16(-Sin(d[7], 8))
  end
  HandleSetAffineData(sprite, 256, 256, -d[7] * 256)
  TryFlipX(sprite)
end

function F.TipAndShake_2(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  d[7] = d[7] + d[6] * 4
  if d[5] > 9 then
    d[7] = 32
    sprite.callback = F.TipAndShake_3
  end
  sprite.x2 = Sin(d[7], 8)
  sprite.y2 = s16(-Sin(d[7], 8))
  if d[7] <= 28 or d[7] >= 36 then
    d[6] = -d[6]
    d[5] = d[5] + 1
  end
  HandleSetAffineData(sprite, 256, 256, -d[7] * 256)
  TryFlipX(sprite)
end

function F.TipAndShake_3(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[7] <= 0 then
    d[7] = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    d[7] = d[7] - 2
    sprite.x2 = Sin(d[7], 8)
    sprite.y2 = s16(-Sin(d[7], 8))
  end
  HandleSetAffineData(sprite, 256, 256, -d[7] * 256)
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:112
function F.Anim_VibrateToCorners(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] > 40 then
    sprite.callback = WaitAnimEnd
    sprite.x2 = 0
  else
    local sign = (band(d[2], 1) == 0) and 1 or -1
    if div(mod(d[2], 4), 2) == 0 then
      sprite.x2 = s16(Sin(mod(div(d[2] * 128, 40), 256), 16) * sign)
      sprite.y2 = s16(-sprite.x2)
    else
      sprite.x2 = s16(-Sin(mod(div(d[2] * 128, 40), 256), 16) * sign)
      sprite.y2 = sprite.x2
    end
  end
  d[2] = d[2] + 1
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:113
function F.Anim_GrowInStages(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[5] = 0
    d[6] = 0
    d[7] = 0
    d[2] = d[2] + 1
  end
  if d[6] > 0 then
    d[6] = d[6] - 1
    if d[5] ~= 3 then
      local scale = s16(div(8 * d[6], 20))
      scale = Sin(d[7] - scale, 64)
      HandleSetAffineData(sprite, 256 - scale, 256 - scale, 0)
    end
  else
    local var
    if d[5] == 3 then
      if d[7] > 63 then
        d[7] = 64
        HandleSetAffineData(sprite, 256, 256, 0)
        ResetSpriteAfterAnim(sprite)
        sprite.callback = WaitAnimEnd
      end
      var = Cos(d[7], 64)
    else
      var = Sin(d[7], 64)
      if d[7] > 63 then
        d[5] = 3
        d[6] = 10
        d[7] = 0
      else
        if var > 48 and d[5] == 1 then
          d[5] = 2
          d[6] = 20
        elseif var > 16 and d[5] == 0 then
          d[5] = 1
          d[6] = 20
        end
      end
    end
    d[7] = d[7] + 2
    HandleSetAffineData(sprite, 256 - var, 256 - var, 0)
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:114
function F.Anim_VerticalSpring(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
  end
  if d[7] > 512 then
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    sprite.y2 = Sin(mod(d[7], 256), 8)
    d[7] = d[7] + 8
    local yScale = Sin(mod(d[7], 128), 96)
    HandleSetAffineData(sprite, 256, yScale + 256, 0)
  end
end

-- pokeemerald/src/pokemon_animation.c:115
function F.Anim_VerticalRepeatedSpring(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
  end
  if d[7] > 256 then
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    sprite.y2 = Sin(d[7], 16)
    d[7] = d[7] + 4
    local yScale = Sin(mod(d[7], 64) * 2, 128)
    HandleSetAffineData(sprite, 256, yScale + 256, 0)
  end
end

-- pokeemerald/src/pokemon_animation.c:116
function F.Anim_SpringRising(sprite)
  HandleStartAffineAnim(sprite)
  sprite.callback = F.SpringRising_0
  sprite.data[7] = 0
end

function F.SpringRising_0(sprite)
  local d = sprite.data
  local yScale
  d[7] = d[7] + 8
  if d[7] > 63 then
    d[7] = 0
    d[6] = 0
    sprite.callback = F.SpringRising_1
    yScale = Sin(64, 128)
  else
    yScale = Sin(d[7], 128)
  end
  HandleSetAffineData(sprite, 256, 256 + yScale, 0)
end

function F.SpringRising_1(sprite)
  local d = sprite.data
  local yScale
  d[7] = d[7] + 4
  if d[7] > 95 then
    yScale = Cos(0, 128)
    d[7] = 0
    d[6] = d[6] + 1
  else
    sprite.y2 = s16(-(d[6] * 4) - Sin(d[7], 8))
    local sign, index
    if d[7] > 63 then
      sign = -1
      index = d[7] - 64
    else
      sign = 1
      index = 0
    end
    yScale = s16(Cos((index * 2) + d[7], 128) * sign)
  end
  HandleSetAffineData(sprite, 256, 256 + yScale, 0)
  if d[6] == 3 then
    d[7] = 0
    sprite.callback = F.SpringRising_2
  end
end

function F.SpringRising_2(sprite)
  local d = sprite.data
  d[7] = d[7] + 8
  local yScale = Cos(d[7], 128)
  sprite.y2 = s16(-Cos(d[7], 12))
  if d[7] > 63 then
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
  end
  HandleSetAffineData(sprite, 256, 256 + yScale, 0)
end

-- pokeemerald/src/pokemon_animation.c:3407
function F.HorizontalSpring(sprite)
  local d = sprite.data
  if d[7] > d[5] then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
    HandleSetAffineData(sprite, 256, 256, 0)
  else
    sprite.x2 = Sin(mod(d[7], 256), d[4])
    d[7] = d[7] + d[6]
    local xScale = Sin(mod(d[7], 128), 96)
    HandleSetAffineData(sprite, 256 + xScale, 256, 0)
  end
end

local function springInit(sprite, d6, d5, d4)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
    d[6] = d6
    d[5] = d5
    d[4] = d4
  end
end

function F.Anim_HorizontalSpring(sprite)
  springInit(sprite, 8, 512, 8)
  F.HorizontalSpring(sprite)
end

-- pokeemerald/src/pokemon_animation.c:3442
function F.HorizontalRepeatedSpring(sprite)
  local d = sprite.data
  if d[7] > d[5] then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
    HandleSetAffineData(sprite, 256, 256, 0)
  else
    sprite.x2 = Sin(mod(d[7], 256), d[4])
    d[7] = d[7] + d[6]
    local xScale = Sin(mod(d[7], 64) * 2, 128)
    HandleSetAffineData(sprite, 256 + xScale, 256, 0)
  end
end

function F.Anim_HorizontalRepeatedSpring_Slow(sprite)
  springInit(sprite, 4, 256, 16)
  F.HorizontalRepeatedSpring(sprite)
end

-- pokeemerald/src/pokemon_animation.c:119
function F.Anim_HorizontalSlideShrink(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
  end
  if d[7] > 512 then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.callback = WaitAnimEnd
  else
    sprite.x2 = Sin(mod(d[7], 256), 8)
    d[7] = d[7] + 8
    local scale = Sin(mod(d[7], 128), 96)
    HandleSetAffineData(sprite, 256 + scale, 256 + scale, 0)
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:120
function F.Anim_LungeGrow(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
  end
  if d[7] > 512 then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.callback = WaitAnimEnd
  else
    sprite.x2 = s16(-Sin(div(mod(d[7], 256), 2), 16))
    d[7] = d[7] + 8
    local scale = s16(-Sin(div(mod(d[7], 256), 2), 64))
    HandleSetAffineData(sprite, 256 + scale, 256 + scale, 0)
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:121
function F.Anim_CircleIntoBackground(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
  end
  if d[7] > 512 then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.callback = WaitAnimEnd
  else
    sprite.x2 = s16(-Sin(mod(d[7], 256), 8))
    d[7] = d[7] + 8
    local scale = Sin(div(mod(d[7], 256), 2), 96)
    HandleSetAffineData(sprite, 256 + scale, 256 + scale, 0)
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:122
function F.Anim_RapidHorizontalHops(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] > 2048 then
    sprite.callback = WaitAnimEnd
    d[6] = 0
  else
    local caseVar = mod(div(d[2], 512), 4)
    if caseVar == 0 then
      sprite.x2 = s16(div(-(mod(d[2], 512) * 16), 512))
    elseif caseVar == 1 then
      sprite.x2 = s16(div(mod(d[2], 512), 32) - 16)
    elseif caseVar == 2 then
      sprite.x2 = s16(div(mod(d[2], 512), 32))
    elseif caseVar == 3 then
      sprite.x2 = s16(div(-(mod(d[2], 512) * 16), 512) + 16)
    end
    sprite.y2 = s16(-Sin(mod(d[2], 128), 4))
    d[2] = d[2] + 24
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:123
function F.Anim_FourPetal(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then
    d[6] = 0
    d[7] = 64
    d[2] = d[2] + 1
  end
  d[7] = d[7] + 8
  if d[6] == 4 then
    if d[7] > 63 then
      d[7] = 0
      d[6] = d[6] + 1
    end
  else
    if d[7] > 127 then
      d[7] = 0
      d[6] = d[6] + 1
    end
  end
  local c = d[6]
  if c == 1 then
    sprite.x2 = s16(-Cos(d[7], 8))
    sprite.y2 = s16(Sin(d[7], 8) - 8)
  elseif c == 2 then
    sprite.x2 = s16(Sin(d[7] + 128, 8) + 8)
    sprite.y2 = s16(-Cos(d[7], 8))
  elseif c == 3 then
    sprite.x2 = Cos(d[7], 8)
    sprite.y2 = s16(Sin(d[7] + 128, 8) + 8)
  elseif c == 0 or c == 4 then
    sprite.x2 = s16(Sin(d[7], 8) - 8)
    sprite.y2 = Cos(d[7], 8)
  else
    sprite.x2 = 0
    sprite.y2 = 0
    sprite.callback = WaitAnimEnd
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:124
function F.Anim_VerticalSquishBounce_Slow(sprite)
  sprite.data[0] = 32
  F.VerticalSquishBounce(sprite)
  sprite.callback = F.VerticalSquishBounce
end

function F.Anim_HorizontalSlide_Slow(sprite)
  sprite.data[0] = 80
  F.HorizontalSlide(sprite)
  sprite.callback = F.HorizontalSlide
end

function F.Anim_VerticalSlide_Slow(sprite)
  sprite.data[0] = 80
  F.VerticalSlide(sprite)
  sprite.callback = F.VerticalSlide
end

-- pokeemerald/src/pokemon_animation.c:127
function F.Anim_BounceRotateToSides_Small(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 2048
  sAnims[id].data = sprite.data[6]
  F.BounceRotateToSides(sprite)
  sprite.callback = F.BounceRotateToSides
end

function F.Anim_BounceRotateToSides_Slow(sprite)
  sprite.data[6] = 1
  F.Anim_BounceRotateToSides(sprite)
end

function F.Anim_BounceRotateToSides_SmallSlow(sprite)
  sprite.data[6] = 1
  F.Anim_BounceRotateToSides_Small(sprite)
end

-- pokeemerald/src/pokemon_animation.c:130
function F.Anim_ZigzagSlow(sprite)
  local d = sprite.data
  if d[2] == 0 then d[0] = 0 end
  if d[0] <= 0 then
    F.Zigzag(sprite)
    d[0] = 1
  else
    d[0] = d[0] - 1
  end
end

function F.Anim_HorizontalShake_Slow(sprite)
  sprite.data[0] = 30
  sprite.data[7] = 3
  F.HorizontalShake(sprite)
  sprite.callback = F.HorizontalShake
end

function F.Anim_VertialShake_Slow(sprite)
  sprite.data[0] = 30
  F.VerticalShake(sprite)
  sprite.callback = F.VerticalShake
end

function F.Anim_Twist_Twice(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 1024
  sAnims[id].delay = 0
  sAnims[id].runs = 2
  F.Twist(sprite)
  sprite.callback = F.Twist
end

function F.Anim_CircleCounterclockwise_Slow(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 512
  sAnims[id].data = 3
  sAnims[id].speed = 12
  F.CircleCounterclockwise(sprite)
  sprite.callback = F.CircleCounterclockwise
end

function F.Anim_VerticalShakeTwice_Slow(sprite)
  sprite.data[0] = 24
  F.VerticalShakeTwice(sprite)
  sprite.callback = F.VerticalShakeTwice
end

function F.Anim_VerticalSlideWobble_Small(sprite)
  sprite.data[0] = 5
  F.VerticalSlideWobble(sprite)
  sprite.callback = F.VerticalSlideWobble
end

function F.Anim_VerticalJumps_Small(sprite)
  sprite.data[0] = 3
  F.VerticalJumps(sprite)
  sprite.callback = F.VerticalJumps
end

function F.Anim_Spin(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].delay = 60
  sAnims[id].data = 30
  F.Spin(sprite)
  sprite.callback = F.Spin
end

function F.Anim_TumblingFrontFlip_Twice(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].speed = 1
  sAnims[id].runs = 2
  F.TumblingFrontFlip(sprite)
  sprite.callback = F.TumblingFrontFlip
end

function F.Anim_DeepVerticalSquishBounce_Twice(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 4
  sAnims[id].runs = 2
  F.DeepVerticalSquishBounce(sprite)
  sprite.callback = F.DeepVerticalSquishBounce
end

function F.Anim_HorizontalJumpsVerticalStretch_Twice(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 1
  sAnims[id].runs = 2
  HandleStartAffineAnim(sprite)
  sprite.data[3] = 0
  F.HorizontalJumpsVerticalStretch_0(sprite)
  sprite.callback = F.HorizontalJumpsVerticalStretch_0
end

function F.Anim_RotateToSides(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 2
  F.RotateToSides(sprite)
  sprite.callback = F.RotateToSides
end

function F.Anim_RotateToSides_Twice(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 4
  sAnims[id].runs = 2
  F.RotateToSides(sprite)
  sprite.callback = F.RotateToSides
end

function F.Anim_SwingConcave(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 100
  F.SwingConcave(sprite)
  sprite.callback = F.SwingConcave
end

function F.Anim_SwingConcave_Fast(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 50
  sAnims[id].runs = 2
  F.SwingConcave(sprite)
  sprite.callback = F.SwingConcave
end

function F.Anim_SwingConvex(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 100
  F.SwingConvex(sprite)
  sprite.callback = F.SwingConvex
end

function F.Anim_SwingConvex_Fast(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].data = 50
  sAnims[id].runs = 2
  F.SwingConvex(sprite)
  sprite.callback = F.SwingConvex
end

-- pokeemerald/src/pokemon_animation.c:3875
function F.VerticalShakeBack(sprite)
  local d = sprite.data
  local counter = d[2]
  if counter > 2304 then
    sprite.callback = WaitAnimEnd
    sprite.y2 = 0
  else
    sprite.y2 = s16(Sin(mod(counter + 192, 256), d[7]) + d[7])
  end
  d[2] = d[2] + d[0]
end

function F.Anim_VerticalShakeBack(sprite)
  sprite.data[0] = 60
  sprite.data[7] = 3
  F.VerticalShakeBack(sprite)
  sprite.callback = F.VerticalShakeBack
end

function F.Anim_VerticalShakeBack_Slow(sprite)
  sprite.data[0] = 30
  sprite.data[7] = 3
  F.VerticalShakeBack(sprite)
  sprite.callback = F.VerticalShakeBack
end

local function vShakeHSlide(sprite, step, ymod)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] > 2048 then
    sprite.callback = WaitAnimEnd
    d[6] = 0
  else
    local divCase = mod(div(d[2], 512), 4)
    if divCase == 0 then
      sprite.x2 = s16(div(mod(d[2], 512), 32))
    elseif divCase == 2 then
      sprite.x2 = s16(div(-(mod(d[2], 512) * 16), 512))
    elseif divCase == 1 then
      sprite.x2 = s16(div(-(mod(d[2], 512) * 16), 512) + 16)
    elseif divCase == 3 then
      sprite.x2 = s16(div(mod(d[2], 512), 32) - 16)
    end
    sprite.y2 = Sin(mod(d[2], ymod), 4)
    d[2] = d[2] + step
  end
  TryFlipX(sprite)
end

-- pokeemerald/src/pokemon_animation.c:144
function F.Anim_VerticalShakeHorizontalSlide_Slow(sprite) vShakeHSlide(sprite, 24, 128) end

-- pokeemerald/src/pokemon_animation.c:3941
function F.VerticalStretchBothEnds(sprite)
  local d = sprite.data
  local index1, index2 = 0, 0
  if d[5] > d[6] then
    sprite.y2 = 0
    d[5] = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    if d[4] <= 1 then
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    else
      d[4] = d[4] - 1
      d[7] = 0
    end
  else
    index2 = s16(div(d[5] * 128, d[6]))
    local cmpVal1 = u8(div(d[6], 4))
    local cmpVal2 = u8(cmpVal1 * 3)
    if d[5] >= cmpVal1 and d[5] < cmpVal2 then
      d[7] = s16(d[7] + 51)
      index1 = band(d[7], 0xFF)
    end
    local xScale
    if d[1] == 0 then
      xScale = -256 - Sin(index2, 16)
    else
      xScale = 256 + Sin(index2, 16)
    end
    local amplitude = u8(d[3])
    local yScale = 256 - Sin(index2, amplitude) - Sin(index1, div(amplitude, 5))
    SetAffineData(sprite, xScale, yScale, 0)
    d[5] = d[5] + 1
  end
end

local function stretchInit(sprite, d4, d6, d3, with5)
  local d = sprite.data
  if d[2] == 0 then
    d[2] = 1
    HandleStartAffineAnim(sprite)
    d[4] = d4
    d[6] = d6
    d[3] = d3
    if with5 then d[5] = 0 end
    d[7] = 0
  end
end

function F.Anim_VerticalStretchBothEnds_Slow(sprite)
  stretchInit(sprite, 1, 40, 40, true)
  F.VerticalStretchBothEnds(sprite)
end

-- pokeemerald/src/pokemon_animation.c:4003
function F.HorizontalStretchFar(sprite)
  local d = sprite.data
  local index1, index2 = 0, 0
  if d[5] > d[6] then
    d[5] = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    if d[4] <= 1 then
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    else
      d[4] = d[4] - 1
      d[7] = 0
    end
  else
    index2 = s16(div(d[5] * 128, d[6]))
    local cmpVal1 = u8(div(d[6], 4))
    local cmpVal2 = u8(cmpVal1 * 3)
    if d[5] >= cmpVal1 and d[5] < cmpVal2 then
      d[7] = s16(d[7] + 51)
      index1 = band(d[7], 0xFF)
    end
    local amplitude = u8(d[3])
    local xScale
    if d[1] == 0 then
      xScale = -256 + Sin(index2, amplitude) + Sin(index1, div(amplitude, 5) * 2)
    else
      xScale = 256 - Sin(index2, amplitude) - Sin(index1, div(amplitude, 5) * 2)
    end
    SetAffineData(sprite, xScale, 256, 0)
    d[5] = d[5] + 1
  end
end

function F.Anim_HorizontalStretchFar_Slow(sprite)
  stretchInit(sprite, 1, 40, 40, true)
  F.HorizontalStretchFar(sprite)
end

-- pokeemerald/src/pokemon_animation.c:4064
function F.VerticalShakeLowTwice(sprite)
  local d = sprite.data
  local var8 = u8(d[2])
  local var9 = u8(d[6])
  local row = sVerticalShakeData[d[5]]
  local var5 = row[1]
  if var5 ~= 255 then var5 = u8(d[7]) end
  local var6 = row[2]
  local var7
  if row[1] ~= 254 then
    var7 = u8(div((var6 - var9) * var5, var6))
  else
    var7 = 0
  end
  if var5 == 255 then
    sprite.callback = WaitAnimEnd
    sprite.y2 = 0
  else
    sprite.y2 = s16(Sin(mod(var8 + 192, 256), var7) + var7)
    if var9 == var6 then
      d[5] = d[5] + 1
      d[6] = 0
    else
      d[2] = d[2] + d[0]
      d[6] = d[6] + 1
    end
  end
end

function F.Anim_VerticalShakeLowTwice(sprite)
  sprite.data[0] = 40
  sprite.data[7] = 6
  F.VerticalShakeLowTwice(sprite)
  sprite.callback = F.VerticalShakeLowTwice
end

function F.Anim_HorizontalShake_Fast(sprite)
  sprite.data[0] = 70
  sprite.data[7] = 6
  F.HorizontalShake(sprite)
  sprite.callback = F.HorizontalShake
end

function F.Anim_HorizontalSlide_Fast(sprite)
  sprite.data[0] = 20
  F.HorizontalSlide(sprite)
  sprite.callback = F.HorizontalSlide
end

-- pokeemerald/src/pokemon_animation.c:150
function F.Anim_HorizontalVibrate_Fast(sprite) hVibrate(sprite, 9) end
function F.Anim_HorizontalVibrate_Fastest(sprite) hVibrate(sprite, 12) end

function F.Anim_VerticalShakeBack_Fast(sprite)
  sprite.data[0] = 70
  sprite.data[7] = 6
  F.VerticalShakeBack(sprite)
  sprite.callback = F.VerticalShakeBack
end

function F.Anim_VerticalShakeLowTwice_Slow(sprite)
  sprite.data[0] = 24
  sprite.data[7] = 6
  F.VerticalShakeLowTwice(sprite)
  sprite.callback = F.VerticalShakeLowTwice
end

function F.Anim_VerticalShakeLowTwice_Fast(sprite)
  sprite.data[0] = 56
  sprite.data[7] = 9
  F.VerticalShakeLowTwice(sprite)
  sprite.callback = F.VerticalShakeLowTwice
end

function F.Anim_CircleCounterclockwise_Long(sprite)
  local id = AddNewAnim()
  sprite.data[0] = id
  sAnims[id].rotation = 1024
  sAnims[id].data = 6
  sAnims[id].speed = 24
  F.CircleCounterclockwise(sprite)
  sprite.callback = F.CircleCounterclockwise
end

-- pokeemerald/src/pokemon_animation.c:4202
function F.GrowStutter(sprite)
  local d = sprite.data
  local index1, index2 = 0, 0
  if d[5] > d[6] then
    sprite.y2 = 0
    d[5] = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    if d[4] <= 1 then
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
    else
      d[4] = d[4] - 1
      d[7] = 0
    end
  else
    index2 = s16(div(d[5] * 128, d[6]))
    local cmpVal1 = u8(div(d[6], 4))
    local cmpVal2 = u8(cmpVal1 * 3)
    if d[5] >= cmpVal1 and d[5] < cmpVal2 then
      d[7] = s16(d[7] + 51)
      index1 = band(d[7], 0xFF)
    end
    local amplitude = u8(d[3])
    local xScale
    if d[1] == 0 then
      xScale = Sin(index2, amplitude) + (Sin(index1, div(amplitude, 5) * 2) - 256)
    else
      xScale = 256 - Sin(index1, div(amplitude, 5) * 2) - Sin(index2, amplitude)
    end
    local yScale = 256 - Sin(index1, div(amplitude, 5)) - Sin(index2, amplitude)
    SetAffineData(sprite, xScale, yScale, 0)
    d[5] = d[5] + 1
  end
end

function F.Anim_GrowStutter_Slow(sprite)
  stretchInit(sprite, 1, 40, 40, true)
  F.GrowStutter(sprite)
end

-- pokeemerald/src/pokemon_animation.c:157
function F.Anim_VerticalShakeHorizontalSlide(sprite) vShakeHSlide(sprite, 48, 128) end
function F.Anim_VerticalShakeHorizontalSlide_Fast(sprite) vShakeHSlide(sprite, 64, 96) end

-- pokeemerald/src/pokemon_animation.c:4332
local sTriangleDownData = { [0] = { 1, 1, 12 }, { -2, 0, 12 }, { 1, -1, 12 }, { 0, 0, 0 } }

-- pokeemerald/src/pokemon_animation.c:4341
function F.TriangleDown(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then d[3] = 0 end
  if div(sTriangleDownData[d[3]][3], d[5]) == d[2] then
    d[3] = d[3] + 1
    d[2] = 0
  end
  if div(sTriangleDownData[d[3]][3], d[5]) == 0 then
    d[6] = d[6] - 1
    if d[6] == 0 then
      sprite.callback = WaitAnimEnd
    else
      d[2] = 0
    end
  else
    local amplitude = d[5]
    sprite.x2 = s16(sprite.x2 + sTriangleDownData[d[3]][1] * amplitude)
    sprite.y2 = s16(sprite.y2 + sTriangleDownData[d[3]][2] * d[5])
    d[2] = d[2] + 1
    TryFlipX(sprite)
  end
end

local function triangleInit(sprite, d5, d6)
  sprite.data[5] = d5
  sprite.data[6] = d6
  F.TriangleDown(sprite)
  sprite.callback = F.TriangleDown
end

function F.Anim_TriangleDown_Slow(sprite) triangleInit(sprite, 1, 1) end
function F.Anim_TriangleDown(sprite) triangleInit(sprite, 2, 1) end
function F.Anim_TriangleDown_Fast(sprite) triangleInit(sprite, 2, 2) end

-- pokeemerald/src/pokemon_animation.c:4394
function F.Grow(sprite)
  local d = sprite.data
  if d[7] > 255 then
    if d[5] <= 1 then
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
      HandleSetAffineData(sprite, 256, 256, 0)
    else
      d[5] = d[5] - 1
      d[7] = 0
    end
  else
    d[7] = d[7] + d[6]
    if d[7] > 256 then d[7] = 256 end
    local scale = Sin(div(d[7], 2), 64)
    HandleSetAffineData(sprite, 256 - scale, 256 - scale, 0)
  end
end

local function growInit(sprite, d6, d5)
  local d = sprite.data
  TryFlipX(sprite)
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[2] = d[2] + 1
    d[7] = 0
    d[6] = d6
    d[5] = d5
  end
  F.Grow(sprite)
  TryFlipX(sprite)
end

function F.Anim_Grow(sprite) growInit(sprite, 4, 1) end
function F.Anim_Grow_Twice(sprite) growInit(sprite, 8, 2) end

-- pokeemerald/src/pokemon_animation.c:164
function F.Anim_HorizontalSpring_Fast(sprite)
  springInit(sprite, 8, 512, 16)
  F.HorizontalSpring(sprite)
end

function F.Anim_HorizontalSpring_Slow(sprite)
  springInit(sprite, 4, 256, 16)
  F.HorizontalSpring(sprite)
end

function F.Anim_HorizontalRepeatedSpring_Fast(sprite)
  springInit(sprite, 8, 512, 16)
  F.HorizontalRepeatedSpring(sprite)
end

function F.Anim_HorizontalRepeatedSpring(sprite)
  springInit(sprite, 8, 512, 8)
  F.HorizontalRepeatedSpring(sprite)
end

-- pokeemerald/src/pokemon_animation.c:168
function F.Anim_ShrinkGrow_Fast(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[7] = 5
    d[6] = 8
  end
  F.ShrinkGrow(sprite)
end

function F.Anim_ShrinkGrow_Slow(sprite)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[7] = 3
    d[6] = 4
  end
  F.ShrinkGrow(sprite)
end

-- pokeemerald/src/pokemon_animation.c:170
function F.Anim_VerticalStretchBothEnds(sprite)
  stretchInit(sprite, 1, 30, 60, false)
  F.VerticalStretchBothEnds(sprite)
end

function F.Anim_VerticalStretchBothEnds_Twice(sprite)
  stretchInit(sprite, 2, 20, 70, false)
  F.VerticalStretchBothEnds(sprite)
end

function F.Anim_HorizontalStretchFar_Twice(sprite)
  stretchInit(sprite, 2, 20, 70, true)
  F.HorizontalStretchFar(sprite)
end

function F.Anim_HorizontalStretchFar(sprite)
  stretchInit(sprite, 1, 30, 60, true)
  F.HorizontalStretchFar(sprite)
end

function F.Anim_GrowStutter_Twice(sprite)
  stretchInit(sprite, 2, 20, 70, true)
  F.GrowStutter(sprite)
end

function F.Anim_GrowStutter(sprite)
  stretchInit(sprite, 1, 30, 60, true)
  F.GrowStutter(sprite)
end

-- pokeemerald/src/pokemon_animation.c:4633
function F.ConcaveArc(sprite)
  local d = sprite.data
  if d[7] > 255 then
    if d[6] <= 1 then
      sprite.callback = WaitAnimEnd
      sprite.x2 = 0
      sprite.y2 = 0
    else
      d[7] = mod(d[7], 256)
      d[6] = d[6] - 1
    end
  else
    sprite.x2 = s16(-Sin(d[7], d[5]))
    sprite.y2 = Sin(mod(d[7] + 192, 256), d[4])
    if sprite.y2 > 0 then sprite.y2 = s16(-sprite.y2) end
    sprite.y2 = s16(sprite.y2 + d[4])
    d[7] = d[7] + d[3]
  end
end

local function arcInit(sprite, d6, d5, d4, d3)
  local d = sprite.data
  if d[2] == 0 then
    d[2] = 1
    d[6] = d6
    d[7] = 0
    d[5] = d5
    d[4] = d4
    d[3] = d3
  end
end

function F.Anim_ConcaveArcLarge_Slow(sprite) arcInit(sprite, 1, 12, 12, 4) F.ConcaveArc(sprite) end
function F.Anim_ConcaveArcLarge(sprite) arcInit(sprite, 1, 12, 12, 6) F.ConcaveArc(sprite) end
function F.Anim_ConcaveArcLarge_Twice(sprite) arcInit(sprite, 2, 12, 12, 8) F.ConcaveArc(sprite) end

-- pokeemerald/src/pokemon_animation.c:4706
function F.ConvexDoubleArc(sprite)
  local d = sprite.data
  if d[7] > 256 then
    if d[6] <= d[4] then
      sprite.callback = WaitAnimEnd
    else
      d[4] = d[4] + 1
      d[7] = 0
    end
    sprite.x2 = 0
    sprite.y2 = 0
  else
    if d[7] > 159 then
      if d[7] > 256 then d[7] = 256 end
      sprite.y2 = s16(-Sin(mod(d[7], 256), 8))
    elseif d[7] > 95 then
      sprite.y2 = s16(Sin(96, 6) - Sin((d[7] - 96) * 2, 4))
    else
      sprite.y2 = Sin(d[7], 6)
    end
    local posX = s16(-Sin(div(d[7], 2), d[5]))
    if mod(d[4], 2) == 0 then posX = s16(-posX) end
    sprite.x2 = posX
    d[7] = d[7] + d[3]
  end
end

function F.Anim_ConvexDoubleArc_Slow(sprite) arcInit(sprite, 2, 16, 1, 4) F.ConvexDoubleArc(sprite) end
function F.Anim_ConvexDoubleArc(sprite) arcInit(sprite, 2, 16, 1, 6) F.ConvexDoubleArc(sprite) end
function F.Anim_ConvexDoubleArc_Twice(sprite) arcInit(sprite, 3, 16, 1, 8) F.ConvexDoubleArc(sprite) end

-- pokeemerald/src/pokemon_animation.c:182
function F.Anim_ConcaveArcSmall_Slow(sprite) arcInit(sprite, 1, 4, 6, 4) F.ConcaveArc(sprite) end
function F.Anim_ConcaveArcSmall(sprite) arcInit(sprite, 1, 4, 6, 6) F.ConcaveArc(sprite) end
function F.Anim_ConcaveArcSmall_Twice(sprite) arcInit(sprite, 2, 4, 6, 8) F.ConcaveArc(sprite) end

-- pokeemerald/src/pokemon_animation.c:4842
local function SetHorizontalDip(sprite)
  local d = sprite.data
  local index = u16(Sin(div(d[2] * 128, d[7]), d[5]))
  d[6] = s16(-(index * 256))
  SetPosForRotation(sprite, index, d[4], 0)
  HandleSetAffineData(sprite, 256, 256, d[6])
end

local function horizontalDip(sprite, d7, d3)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    d[7] = d7
    d[5] = 8
    d[4] = -32
    d[3] = d3
    d[0] = 0
  end
  if d[2] > d[7] then
    HandleSetAffineData(sprite, 256, 256, 0)
    sprite.x2 = 0
    sprite.y2 = 0
    d[0] = d[0] + 1
    if d[3] <= d[0] then
      ResetSpriteAfterAnim(sprite)
      sprite.callback = WaitAnimEnd
      return
    else
      d[2] = 0
    end
  else
    SetHorizontalDip(sprite)
  end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:185
function F.Anim_HorizontalDip(sprite) horizontalDip(sprite, 60, 1) end
function F.Anim_HorizontalDip_Fast(sprite) horizontalDip(sprite, 90, 1) end
function F.Anim_HorizontalDip_Twice(sprite) horizontalDip(sprite, 30, 2) end

-- pokeemerald/src/pokemon_animation.c:4961
function F.ShrinkGrowVibrate(sprite)
  local d = sprite.data
  if d[2] > d[7] then
    sprite.y2 = 0
    HandleSetAffineData(sprite, 256, 256, 0)
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  else
    local index = s16(mod(div(u16(mod(d[2], d[6]) * 256), d[6]), 256))
    local sinY
    if mod(d[2], 2) == 0 then
      d[4] = Sin(index, 32) + 256
      d[5] = Sin(index, 32) + 256
      sinY = s8(Sin(index, 32))
    else
      d[4] = Sin(index, 8) + 256
      d[5] = Sin(index, 8) + 256
      sinY = s8(Sin(index, 8))
    end
    local y = u16(div(sinY, 8))
    sprite.y2 = s16(y)
    HandleSetAffineData(sprite, d[4], d[5], 0)
  end
  d[2] = d[2] + 1
end

local function sgvInit(sprite, d6, d7)
  local d = sprite.data
  if d[2] == 0 then
    HandleStartAffineAnim(sprite)
    sprite.y2 = s16(sprite.y2 + 2)
    d[6] = d6
    d[7] = d7
  end
  F.ShrinkGrowVibrate(sprite)
end

function F.Anim_ShrinkGrowVibrate_Fast(sprite) sgvInit(sprite, 40, 80) end
function F.Anim_ShrinkGrowVibrate(sprite) sgvInit(sprite, 40, 40) end
function F.Anim_ShrinkGrowVibrate_Slow(sprite) sgvInit(sprite, 80, 80) end

-- pokeemerald/src/pokemon_animation.c:5040
function F.JoltRight(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 - d[2])
  if sprite.x2 <= -d[6] then
    sprite.x2 = s16(-d[6])
    d[7] = 2
    sprite.callback = F.JoltRight_0
  end
  TryFlipX(sprite)
end

function F.JoltRight_0(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + d[7])
  d[7] = d[7] + 1
  if sprite.x2 >= 0 then sprite.callback = F.JoltRight_1 end
  TryFlipX(sprite)
end

function F.JoltRight_1(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 + d[7])
  d[7] = d[7] + 1
  if sprite.x2 > d[6] then
    sprite.x2 = d[6]
    sprite.callback = F.JoltRight_2
  end
  TryFlipX(sprite)
end

function F.JoltRight_2(sprite)
  local d = sprite.data
  TryFlipX(sprite)
  if d[3] >= d[5] then
    sprite.callback = F.JoltRight_3
  else
    sprite.x2 = s16(sprite.x2 + d[4])
    d[4] = -d[4]
    d[3] = d[3] + 1
  end
  TryFlipX(sprite)
end

function F.JoltRight_3(sprite)
  TryFlipX(sprite)
  sprite.x2 = s16(sprite.x2 - 2)
  if sprite.x2 <= 0 then
    sprite.x2 = 0
    ResetSpriteAfterAnim(sprite)
    sprite.callback = WaitAnimEnd
  end
  TryFlipX(sprite)
end

local function joltInit(sprite, d7, d6, d5, d4, d2)
  HandleStartAffineAnim(sprite)
  local d = sprite.data
  d[7], d[6], d[5], d[4], d[3], d[2] = d7, d6, d5, d4, 0, d2
  sprite.callback = F.JoltRight
end

-- pokeemerald/src/pokemon_animation.c:191
function F.Anim_JoltRight_Fast(sprite) joltInit(sprite, 4, 12, 16, 4, 2) end
function F.Anim_JoltRight(sprite) joltInit(sprite, 2, 8, 12, 2, 1) end
function F.Anim_JoltRight_Slow(sprite) joltInit(sprite, 0, 6, 6, 2, 1) end

-- pokeemerald/src/pokemon_animation.c:5146
local function SetShakeFlashYellowPos(sprite)
  local d = sprite.data
  sprite.x2 = d[1]
  if d[0] > 1 then
    d[1] = s16(-d[1])
    d[0] = 0
  else
    d[0] = d[0] + 1
  end
end

-- pokeemerald/src/pokemon_animation.c:5216
local sShakeYellowFlashData = {
  [0] = {
    [0] = { 0, 1 }, { 1, 2 }, { 0, 15 }, { 1, 1 }, { 0, 15 }, { 1, 1 }, { 0, 15 }, { 1, 1 }, { 0, 1 },
    { 1, 1 }, { 0, 1 }, { 1, 1 }, { 0, 1 }, { 1, 1 }, { 0, 1 }, { 1, 1 }, { 0, 1 }, { 1, 1 }, { 0, 1 },
    { 0, 255 },
  },
  [1] = {
    [0] = { 0, 5 }, { 1, 1 }, { 0, 15 }, { 1, 4 }, { 0, 2 }, { 1, 2 }, { 0, 2 }, { 1, 2 }, { 0, 2 },
    { 1, 2 }, { 0, 2 }, { 1, 2 }, { 0, 2 }, { 0, 255 },
  },
  [2] = {
    [0] = { 0, 1 }, { 1, 1 }, { 0, 20 }, { 1, 1 }, { 0, 20 }, { 1, 1 }, { 0, 20 }, { 1, 1 }, { 0, 1 },
    { 0, 255 },
  },
}

-- pokeemerald/src/pokemon_animation.c:5223
function F.ShakeFlashYellow(sprite)
  local d = sprite.data
  local array = sShakeYellowFlashData[d[3]]
  SetShakeFlashYellowPos(sprite)
  if array[d[6]][2] == 255 then
    sprite.x2 = 0
    sprite.callback = WaitAnimEnd
  else
    if d[4] == 1 then
      if array[d[6]][1] ~= 0 then
        blend(sprite, 16, RGB_YELLOW)
      else
        blend(sprite, 0, RGB_YELLOW)
      end
      d[4] = 0
    end
    if array[d[6]][2] == d[5] then
      d[4] = 1
      d[5] = 0
      d[6] = d[6] + 1
    else
      d[5] = d[5] + 1
    end
  end
end

local function shakeFlashInit(sprite, which)
  local d = sprite.data
  d[2] = d[2] + 1
  if d[2] == 1 then
    d[7] = 0x100 + (sprite.paletteNum or 0) * 16
    d[6], d[5], d[4], d[3] = 0, 0, 0, which
  end
  F.ShakeFlashYellow(sprite)
end

function F.Anim_ShakeFlashYellow_Fast(sprite) shakeFlashInit(sprite, 0) end
function F.Anim_ShakeFlashYellow(sprite) shakeFlashInit(sprite, 1) end
function F.Anim_ShakeFlashYellow_Slow(sprite) shakeFlashInit(sprite, 2) end

-- pokeemerald/src/pokemon_animation.c:5308
local sShakeGlowColors = { [0] = RGB_RED, RGB_GREEN, RGB_BLUE, RGB_BLACK }

-- pokeemerald/src/pokemon_animation.c:5306
local function ShakeGlow_Blend(sprite)
  local d = sprite.data
  if d[2] > 127 then
    blend(sprite, 0, RGB_RED)
    sprite.callback = WaitAnimEnd
  else
    d[6] = Sin(d[2], 12)
    blend(sprite, d[6], sShakeGlowColors[d[1]])
  end
end

-- pokeemerald/src/pokemon_animation.c:5328
local function ShakeGlow_Move(sprite)
  local d = sprite.data
  if d[3] < d[4] then
    TryFlipX(sprite)
    if d[5] > d[0] then
      d[3] = d[3] + 1
      if d[3] < d[4] then d[5] = 0 end
      sprite.x2 = 0
    else
      local sign = s8(1 - (mod(d[3], 2) * 2))
      sprite.x2 = s16(sign * Sin(mod(div(d[5] * 384, d[0]), 256), 6))
      d[5] = d[5] + 1
    end
    TryFlipX(sprite)
  end
end

local function shakeGlow(sprite, d0, d4, color)
  local d = sprite.data
  if d[2] == 0 then
    d[7] = 0x100 + (sprite.paletteNum or 0) * 16
    d[0], d[5], d[4], d[3], d[1] = d0, 0, d4, 0, color
  end
  if mod(d[2], 2) == 0 then ShakeGlow_Blend(sprite) end
  if d[2] >= div(128 - d[0] * d[4], 2) then ShakeGlow_Move(sprite) end
  d[2] = d[2] + 1
end

-- pokeemerald/src/pokemon_animation.c:197
function F.Anim_ShakeGlowRed_Fast(sprite) shakeGlow(sprite, 10, 2, 0) end
function F.Anim_ShakeGlowRed(sprite) shakeGlow(sprite, 20, 1, 0) end
function F.Anim_ShakeGlowRed_Slow(sprite) shakeGlow(sprite, 80, 1, 0) end
function F.Anim_ShakeGlowGreen_Fast(sprite) shakeGlow(sprite, 10, 2, 1) end
function F.Anim_ShakeGlowGreen(sprite) shakeGlow(sprite, 20, 1, 1) end
function F.Anim_ShakeGlowGreen_Slow(sprite) shakeGlow(sprite, 80, 1, 1) end
function F.Anim_ShakeGlowBlue_Fast(sprite) shakeGlow(sprite, 10, 2, 2) end
function F.Anim_ShakeGlowBlue(sprite) shakeGlow(sprite, 20, 1, 2) end
function F.Anim_ShakeGlowBlue_Slow(sprite) shakeGlow(sprite, 80, 1, 2) end

function MonAnim.animFunction(id)
  local name = Data.functionName(id)
  local fn = name and F[name]
  if not fn then error("mon_anim: no port for anim function " .. tostring(id) .. " (" .. tostring(name) .. ")") end
  return fn, name
end

function MonAnim.callbackName(sprite)
  local cb = sprite and sprite.callback
  if cb == nil then return nil end
  if cb == SpriteCallbackDummy then return "SpriteCallbackDummy" end
  if cb == SpriteCallbackDummy_2 then return "SpriteCallbackDummy_2" end
  if cb == MonAnimDummySpriteCallback then return "MonAnimDummySpriteCallback" end
  for k, v in pairs(F) do if v == cb then return k end end
  return "?"
end

-- pokeemerald/src/sprite.c:62
local function setFrame(sprite, cmd)
  local duration = cmd.duration or 0
  if duration > 0 then duration = duration - 1 end
  sprite.animDelayCounter = duration
  sprite.frame = cmd.frame
end

local function beginAnim(sprite)
  sprite.animCmdIndex = 0
  sprite.animEnded = false
  sprite.animLoopCounter = 0
  local cmd = sprite.anims[sprite.animNum][sprite.animCmdIndex + 1]
  if cmd and cmd.frame ~= nil then
    sprite.animBeginning = false
    setFrame(sprite, cmd)
  end
end

local continueAnim

local function jumpToTopOfAnimLoop(sprite)
  if sprite.animLoopCounter ~= 0 then
    local list = sprite.anims[sprite.animNum]
    sprite.animCmdIndex = sprite.animCmdIndex - 1
    while not (list[sprite.animCmdIndex] and list[sprite.animCmdIndex].op == "loop") do
      if sprite.animCmdIndex == 0 then break end
      sprite.animCmdIndex = sprite.animCmdIndex - 1
    end
    sprite.animCmdIndex = sprite.animCmdIndex - 1
  end
end

-- pokeemerald/src/sprite.c:61
continueAnim = function(sprite)
  if sprite.animDelayCounter ~= 0 then
    if not sprite.animPaused then sprite.animDelayCounter = sprite.animDelayCounter - 1 end
  elseif not sprite.animPaused then
    sprite.animCmdIndex = sprite.animCmdIndex + 1
    local list = sprite.anims[sprite.animNum]
    local cmd = list[sprite.animCmdIndex + 1]
    if cmd == nil or cmd.op == "end" then
      sprite.animCmdIndex = sprite.animCmdIndex - 1
      sprite.animEnded = true
    elseif cmd.op == "jump" then
      sprite.animCmdIndex = cmd.target
      setFrame(sprite, list[cmd.target + 1])
    elseif cmd.op == "loop" then
      if sprite.animLoopCounter ~= 0 then
        sprite.animLoopCounter = sprite.animLoopCounter - 1
      else
        sprite.animLoopCounter = cmd.count
      end
      jumpToTopOfAnimLoop(sprite)
      continueAnim(sprite)
    else
      setFrame(sprite, cmd)
    end
  end
end

-- pokeemerald/src/sprite.c:901
local function animateSprite(sprite)
  if sprite.animBeginning then beginAnim(sprite) else continueAnim(sprite) end
  if sprite.affineMode ~= "off" and sprite.affineAnimBeginning then
    sprite.affineAnimBeginning = false
    local m = sprite.matrix
    m.xScale, m.yScale, m.rotation = (sprite.affineAnimNum == 1) and -256 or 256, 256, 0
  end
end

-- pokeemerald/src/sprite.c:1346
function MonAnim.startSpriteAnim(sprite, animNum)
  if not sprite.anims[animNum] then return end
  sprite.animNum = animNum
  sprite.animBeginning = true
  sprite.animEnded = false
end

function MonAnim.newSprite(species, opts)
  opts = opts or {}
  local sprite = {
    species = tonumber(species) or 0,
    data = { [0] = 0, 0, 0, 0, 0, 0, 0, 0 },
    x2 = 0, y2 = 0,
    invisible = false,
    hFlip = opts.hFlip and true or false,
    affineMode = opts.affineMode or "normal",
    affineAnimNum = 0,
    affineAnimBeginning = false,
    matrix = { xScale = 256, yScale = 256, rotation = 0 },
    centerToCornerVecX = -32,
    paletteNum = opts.paletteNum or 0,
    blendCoeff = 0, blendColor = 0,
    anims = Data.anims(species) or { [0] = { { frame = 0, duration = 0 }, { op = "end" } } },
    animNum = 0, animCmdIndex = 0, animDelayCounter = 0, animLoopCounter = 0,
    animBeginning = true, animEnded = false, animPaused = false,
    frame = 0,
    callback = SpriteCallbackDummy,
    tasks = {},
    frames = 0,
  }
  for i, v in pairs(opts.data or {}) do sprite.data[i] = v end
  calcCenterToCornerVec(sprite)
  return sprite
end

local function createTask(sprite, fn, priority)
  local t = { fn = fn, priority = priority, data = {}, active = true }
  local list = sprite.tasks
  local at = #list + 1
  for i, other in ipairs(list) do
    if other.priority > priority then at = i break end
  end
  table.insert(list, at, t)
  return t
end

local function destroyTask(sprite, task)
  task.active = false
  for i, t in ipairs(sprite.tasks) do
    if t == task then table.remove(sprite.tasks, i) return end
  end
end

local function runTasks(sprite)
  local snapshot = {}
  local i = 1
  while i <= #sprite.tasks do
    local t = sprite.tasks[i]
    if not snapshot[t] then
      snapshot[t] = true
      if t.active then t.fn(sprite, t) end
      i = 1
    else
      i = i + 1
    end
  end
end

-- pokeemerald/src/pokemon_animation.c:911
local function Task_HandleMonAnimation(sprite, task)
  if task.state == 0 then
    task.battlerId = sprite.data[0]
    task.speciesId = sprite.data[2]
    sprite.data[1] = 1
    sprite.data[0] = 0
    for i = 2, 7 do sprite.data[i] = 0 end
    sprite.callback = MonAnim.animFunction(task.animId)
    sIsSummaryAnim = false
    task.state = task.state + 1
  end
  if sprite.callback == SpriteCallbackDummy then
    sprite.data[0] = task.battlerId
    sprite.data[2] = task.speciesId
    sprite.data[1] = 0
    destroyTask(sprite, task)
  end
end

-- pokeemerald/src/pokemon_animation.c:941
function MonAnim.launchFront(sprite, frontAnimId)
  local t = createTask(sprite, Task_HandleMonAnimation, 128)
  t.state = 0
  t.animId = frontAnimId
  sprite.animId = frontAnimId
end

-- pokeemerald/src/pokemon_animation.c:949
function MonAnim.startSummary(sprite, frontAnimId)
  sIsSummaryAnim = true
  sprite.summary = true
  sprite.animId = frontAnimId
  sprite.callback = MonAnim.animFunction(frontAnimId)
end

-- pokeemerald/src/pokemon_animation.c:956
function MonAnim.launchBack(sprite, backAnimSet, nature)
  local t = createTask(sprite, Task_HandleMonAnimation, 128)
  t.state = 0
  t.animId = Data.backAnimId(backAnimSet, nature)
  sprite.animId = t.animId
end

local function speciesConst(name)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(GameVersion.get()):id("species", name)
end

-- pokeemerald/src/pokemon.c:6988
function MonAnim.hasTwoFramesAnimation(species)
  species = tonumber(species)
  return species ~= speciesConst("SPECIES_CASTFORM")
    and species ~= speciesConst("SPECIES_DEOXYS")
    and species ~= speciesConst("SPECIES_SPINDA")
    and species ~= speciesConst("SPECIES_UNOWN")
end

local function playCry(opts, species, pan)
  if opts and opts.cry then return opts.cry(species, pan) end
  pcall(function() require("src.core.game3.audio").playCry(species, 0, pan) end)
end

-- pokeemerald/src/pokemon.c:6784
local function Task_AnimateAfterDelay(sprite, task)
  task.delay = task.delay - 1
  if task.delay == 0 then
    MonAnim.launchFront(sprite, task.animId)
    destroyTask(sprite, task)
  end
end

-- pokeemerald/src/pokemon.c:6811
function MonAnim.doFront(sprite, species, noCry, panModeAnimFlag, opts)
  local flag = panModeAnimFlag or 0
  local panMode = band(flag, 0x7F)
  local pan = (panMode == 0 and -25) or (panMode == 1 and 25) or 0
  if band(flag, 0x80) ~= 0 then
    if not noCry then playCry(opts, species, pan) end
    sprite.callback = SpriteCallbackDummy
    return sprite
  end
  if not noCry then
    playCry(opts, species, pan)
    if MonAnim.hasTwoFramesAnimation(species) then MonAnim.startSpriteAnim(sprite, 1) end
  end
  local delay = Data.delay(species)
  local animId = Data.frontAnimId(species)
  if delay ~= 0 then
    local t = createTask(sprite, Task_AnimateAfterDelay, 0)
    t.animId = animId
    t.delay = delay
  else
    MonAnim.launchFront(sprite, animId)
  end
  sprite.callback = SpriteCallbackDummy_2
  return sprite
end

MonAnim.SKIP_FRONT_ANIM = 0x80

-- pokeemerald/src/pokemon.c:6803
function MonAnim.battleFront(sprite, species, noCry, panMode, opts)
  local flag = panMode or 0
  if opts and opts.noAnimations then flag = flag + MonAnim.SKIP_FRONT_ANIM end
  return MonAnim.doFront(sprite, species, noCry, flag, opts)
end

-- pokeemerald/src/pokemon.c:6886
function MonAnim.battleBack(sprite, species, nature, opts)
  if opts and opts.noAnimations then
    sprite.callback = SpriteCallbackDummy
    return sprite
  end
  MonAnim.launchBack(sprite, Data.backAnimSet(species), nature)
  sprite.callback = SpriteCallbackDummy_2
  return sprite
end

-- pokeemerald/src/pokemon.c:6793
local function Task_PokemonSummaryAnimateAfterDelay(sprite, task)
  task.delay = task.delay - 1
  if task.delay == 0 then
    MonAnim.startSummary(sprite, task.animId)
    destroyTask(sprite, task)
  end
end

-- pokeemerald/src/pokemon.c:6858
function MonAnim.summary(sprite, species, oneFrame)
  if not oneFrame and MonAnim.hasTwoFramesAnimation(species) then MonAnim.startSpriteAnim(sprite, 1) end
  local delay = Data.delay(species)
  local animId = Data.frontAnimId(species)
  sprite.summary = true
  if delay ~= 0 then
    local t = createTask(sprite, Task_PokemonSummaryAnimateAfterDelay, 0)
    t.animId = animId
    t.delay = delay
    sprite.callback = MonAnimDummySpriteCallback
  else
    MonAnim.startSummary(sprite, animId)
  end
  return sprite
end

local function wrap(sprite)
  local d = sprite.data
  for i = 0, 7 do d[i] = s16(d[i]) end
  sprite.x2 = s16(sprite.x2)
  sprite.y2 = s16(sprite.y2)
end

function MonAnim.animateSprites(sprite)
  sIsSummaryAnim = sprite.summary == true
  sprite.callback(sprite)
  wrap(sprite)
  animateSprite(sprite)
end

function MonAnim.runTasks(sprite)
  if #sprite.tasks > 0 then runTasks(sprite) end
end

function MonAnim.step(sprite, tasksFirst)
  if not sprite then return end
  if tasksFirst then MonAnim.runTasks(sprite) end
  MonAnim.animateSprites(sprite)
  if not tasksFirst then MonAnim.runTasks(sprite) end
  sprite.frames = sprite.frames + 1
end

function MonAnim.done(sprite)
  return sprite == nil or (sprite.callback == SpriteCallbackDummy and #sprite.tasks == 0)
end

function MonAnim.busy(sprite)
  return sprite ~= nil and not MonAnim.done(sprite)
end

function MonAnim.enabled()
  return Data.available()
end

function MonAnim.run(sprite, opts)
  opts = opts or {}
  local Task = require("src.core.game3.task")
  local limit = opts.limit or 1200
  sprite.task = Task.spawn(function()
    if sprite.stopped then return true end
    MonAnim.step(sprite, opts.tasksFirst)
    if opts.onStep then opts.onStep(sprite) end
    if MonAnim.done(sprite) then
      if opts.onDone then opts.onDone(sprite) end
      return true
    end
    limit = limit - 1
    if limit <= 0 then
      sprite.callback = SpriteCallbackDummy
      if opts.onDone then opts.onDone(sprite) end
      return true
    end
  end)
  return sprite
end

function MonAnim.stop(sprite)
  if sprite then sprite.stopped = true end
end

-- pokeemerald/src/pokemon_animation.c:984
function MonAnim.transform(sprite)
  local t = { x2 = sprite.x2, y2 = sprite.y2, invisible = sprite.invisible, frame = sprite.frame,
    blendCoeff = sprite.blendCoeff, blendColor = sprite.blendColor }
  if sprite.affineMode == "off" then
    t.sx, t.sy, t.rotation = sprite.hFlip and -1 or 1, 1, 0
  else
    local m = sprite.matrix
    local xs = m.xScale ~= 0 and m.xScale or 1
    local ys = m.yScale ~= 0 and m.yScale or 1
    t.sx, t.sy = 256 / xs, 256 / ys
    t.rotation = -(floor(m.rotation / 256) * 2 * math.pi / 256)
  end
  return t
end

-- pokeemerald/src/util.c:264
function MonAnim.blendRgb(sprite)
  local c = sprite.blendColor or 0
  return (c % 32) / 31, (floor(c / 32) % 32) / 31, (floor(c / 1024) % 32) / 31, (sprite.blendCoeff or 0) / 16
end

local sheets = {}

function MonAnim.framePic(species, frame, shiny)
  if (tonumber(frame) or 0) == 0 then return nil end
  if not (love and love.graphics and love.image) then return nil end
  species = tonumber(species)
  local key = require("src.core.GameVersion").get() .. ":" .. tostring(species) .. ":" .. tostring(frame)
    .. (shiny and ":s" or "")
  local hit = sheets[key]
  if hit ~= nil then return hit or nil end
  local cache = Data.cache()
  local rgba = cache and cache:read(string.format(shiny and Data.SHEET_SHINY or Data.SHEET, species))
  local size = 64 * 64 * 4
  if type(rgba) ~= "string" or #rgba < size * (frame + 1) then
    sheets[key] = false
    return nil
  end
  local img = love.image.newImageData(64, 64, "rgba8", rgba:sub(size * frame + 1, size * (frame + 1)))
  local image = love.graphics.newImage(img)
  image:setFilter("nearest", "nearest")
  hit = { image = image, w = 64, h = 64 }
  sheets[key] = hit
  return hit
end

local silhouette

function MonAnim.draw(sprite, image, cx, cy, opts)
  if not (sprite and image) then return end
  opts = opts or {}
  local t = MonAnim.transform(sprite)
  if t.invisible then return end
  local x, y = cx + t.x2, cy + t.y2
  local r, g, b, a = love.graphics.getColor()
  love.graphics.draw(image, x, y, t.rotation, t.sx, t.sy, 32, 32)
  if (sprite.blendCoeff or 0) > 0 then
    if silhouette == nil then
      local okS, sh = pcall(love.graphics.newShader, [[
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  return vec4(color.rgb, Texel(tex, tc).a * color.a);
}
]])
      silhouette = okS and sh or false
    end
    if silhouette then
      local br, bg, bb, k = MonAnim.blendRgb(sprite)
      love.graphics.setShader(silhouette)
      love.graphics.setColor(br, bg, bb, math.min(1, k) * a)
      love.graphics.draw(image, x, y, t.rotation, t.sx, t.sy, 32, 32)
      love.graphics.setShader()
    end
  end
  love.graphics.setColor(r, g, b, a)
end

function MonAnim.resetState()
  for i = 0, MAX_BATTLERS_COUNT - 1 do InitAnimData(i) end
  sAnimIdx = 0
  sIsSummaryAnim = false
  MonAnim.oob = 0
end

return MonAnim
