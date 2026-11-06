local bit = require("bit")
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift

local Palette = {}
Palette.__index = Palette

Palette.SIZE = 512
Palette.OBJ_OFFSET = 256
Palette.ALL = 0xFFFFFFFF
Palette.BG = 0x0000FFFF
Palette.OBJ = 0xFFFF0000

Palette.STATUS_DONE = 0
Palette.STATUS_ACTIVE = 1
Palette.STATUS_DELAY = 2
Palette.STATUS_LOADING = 0xFF

Palette.WHITE = 0x7FFF
Palette.BLACK = 0x0000
Palette.WHITEALPHA = 0xFFFF

function Palette.rgb(r, g, b)
  return bor(band(r, 31), lshift(band(g, 31), 5), lshift(band(b, 31), 10))
end

function Palette.new()
  local self = setmetatable({ unfaded = {}, faded = {}, pltt = {} }, Palette)
  for i = 0, Palette.SIZE - 1 do
    self.unfaded[i], self.faded[i], self.pltt[i] = 0, 0, 0
  end
  self.pending = 0
  self:resetFadeControl()
  return self
end

-- pokeemerald/src/palette.c:361
function Palette:resetFadeControl()
  self.selected = 0
  self.delay = 0
  self.delayCounter = 0
  self.y = 0
  self.targetY = 0
  self.blendColor = 0
  self.active = false
  self.yDec = false
  self.bufferTransferDisabled = false
  self.finishing = false
  self.finishingCounter = 0
  self.objToggle = 0
  self.deltaY = 2
end

-- pokeemerald/src/palette.c:133
function Palette:resetFade()
  self:resetFadeControl()
end

-- pokeemerald/src/palette.c:91
function Palette:load(src, offset, count, first)
  first = first or 1
  count = count or #src
  for i = 0, count - 1 do
    local c = band(src[first + i] or 0, 0xFFFF)
    self.unfaded[offset + i] = c
    self.faded[offset + i] = c
  end
end

function Palette:loadUnfaded(src, offset, count, first)
  first = first or 1
  count = count or #src
  for i = 0, count - 1 do
    self.unfaded[offset + i] = band(src[first + i] or 0, 0xFFFF)
  end
end

-- pokeemerald/src/palette.c:97
function Palette:fill(value, offset, count)
  for i = 0, count - 1 do
    self.unfaded[offset + i] = value
    self.faded[offset + i] = value
  end
end

function Palette:copyUnfaded(from, to, count)
  local tmp = {}
  for i = 0, count - 1 do tmp[i] = self.unfaded[from + i] end
  for i = 0, count - 1 do self.unfaded[to + i] = tmp[i] end
end

-- pokeemerald/src/util.c:264
function Palette:blend(offset, count, coeff, color)
  local tr, tg, tb = band(color, 31), band(rshift(color, 5), 31), band(rshift(color, 10), 31)
  for i = 0, count - 1 do
    local c = self.unfaded[offset + i]
    local r, g, b = band(c, 31), band(rshift(c, 5), 31), band(rshift(c, 10), 31)
    r = r + math.floor((tr - r) * coeff / 16)
    g = g + math.floor((tg - g) * coeff / 16)
    b = b + math.floor((tb - b) * coeff / 16)
    self.faded[offset + i] = Palette.rgb(r, g, b)
  end
end

-- pokeemerald/src/palette.c:830
function Palette:blendMask(mask, coeff, color)
  local offset = 0
  mask = band(mask, 0xFFFFFFFF)
  while mask ~= 0 do
    if band(mask, 1) ~= 0 then self:blend(offset, 16, coeff, color) end
    mask = rshift(mask, 1)
    offset = offset + 16
  end
end

-- pokeemerald/src/palette.c:806
function Palette:_finishing()
  if self.finishing then
    if self.finishingCounter == 4 then
      self.active = false
      self.finishing = false
      self.finishingCounter = 0
    else
      self.finishingCounter = self.finishingCounter + 1
    end
    return true
  end
  return false
end

-- pokeemerald/src/palette.c:406
function Palette:_updateNormal()
  if not self.active then return Palette.STATUS_DONE end
  if self:_finishing() then
    return self.active and Palette.STATUS_ACTIVE or Palette.STATUS_DONE
  end
  if self.objToggle == 0 then
    if self.delayCounter < self.delay then
      self.delayCounter = self.delayCounter + 1
      return Palette.STATUS_DELAY
    end
    self.delayCounter = 0
  end
  local sel, offset
  if self.objToggle == 0 then
    sel, offset = band(self.selected, 0xFFFF), 0
  else
    sel, offset = band(rshift(self.selected, 16), 0xFFFF), Palette.OBJ_OFFSET
  end
  while sel ~= 0 do
    if band(sel, 1) ~= 0 then self:blend(offset, 16, self.y, self.blendColor) end
    sel = rshift(sel, 1)
    offset = offset + 16
  end
  self.objToggle = 1 - self.objToggle
  if self.objToggle == 0 then
    if self.y == self.targetY then
      self.selected = 0
      self.finishing = true
    elseif not self.yDec then
      self.y = math.min(self.targetY, self.y + self.deltaY)
    else
      self.y = math.max(self.targetY, self.y - self.deltaY)
    end
  end
  return self.active and Palette.STATUS_ACTIVE or Palette.STATUS_DONE
end

-- pokeemerald/src/palette.c:114
function Palette:update()
  if self.pending ~= 0 then return Palette.STATUS_LOADING end
  local result = self:_updateNormal()
  self.pending = self.selected
  return result
end

-- pokeemerald/src/palette.c:156
function Palette:beginFade(selected, delay, startY, targetY, color)
  if self.active then return false end
  self.deltaY = 2
  if delay < 0 then
    self.deltaY = self.deltaY - delay
    delay = 0
  end
  self.selected = band(selected, 0xFFFFFFFF)
  self.delayCounter = delay
  self.delay = delay
  self.y = startY
  self.targetY = targetY
  self.blendColor = band(color, 0x7FFF)
  self.active = true
  self.yDec = not (startY < targetY)
  self:update()
  for i = 0, Palette.SIZE - 1 do self.pltt[i] = self.faded[i] end
  self.pending = 0
  return true
end

function Palette:fadeActive()
  return self.active
end

-- pokeemerald/src/palette.c:103
function Palette:transfer()
  if not self.bufferTransferDisabled then
    for i = 0, Palette.SIZE - 1 do self.pltt[i] = self.faded[i] end
    self.pending = 0
  end
end

function Palette:clearHardware(from)
  for i = from or 0, Palette.SIZE - 1 do self.pltt[i] = 0 end
end

return Palette
