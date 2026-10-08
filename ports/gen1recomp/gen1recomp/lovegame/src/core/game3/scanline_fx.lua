local Trig = require("src.core.game3.trig")

local Scanline = {}
Scanline.__index = Scanline

Scanline.BUFFER = 0x3C0
Scanline.LINES = 160

local SINE = Trig.SINE

local function u16(v)
  return v % 65536
end

local function trunc(x)
  if x >= 0 then return math.floor(x) end
  return -math.floor(-x)
end

function Scanline.new()
  local self = setmetatable({}, Scanline)
  self.buffers = { [0] = {}, [1] = {} }
  self:clear()
  self.lines = nil
  self.stopWaveTask = false
  return self
end

-- pokeemerald/src/scanline_effect.c:32
function Scanline:clear()
  for b = 0, 1 do
    local buf = self.buffers[b]
    for i = 0, Scanline.BUFFER - 1 do buf[i] = 0 end
  end
  self.srcBuffer = 0
  self.state = 0
  self.dest = nil
  self.wave = nil
end

-- pokeemerald/src/scanline_effect.c:21
function Scanline:stop()
  self.state = 0
  self.lines = nil
  self.wave = nil
end

-- pokeemerald/src/scanline_effect.c:72
function Scanline:vblank(regs)
  if self.state == 0 then return end
  if self.state == 3 then
    self.state = 0
    local last = self.lines
    self.lines = nil
    if last and regs and self.dest then regs[self.dest] = last[Scanline.LINES] or 0 end
    self.stopWaveTask = true
    return
  end
  local src = self.buffers[self.srcBuffer]
  local lines = {}
  for i = 0, Scanline.LINES do lines[i] = src[i] end
  self.lines = lines
  self.srcBuffer = 1 - self.srcBuffer
end

function Scanline:lineValues()
  if self.state == 0 or not self.lines then return nil end
  return self.lines, self.dest
end

-- pokeemerald/src/scanline_effect.c:197
local function generateWave(buffer, base, frequency, amplitude)
  local theta = 0
  for i = 0, 255 do
    buffer[base + i] = u16(trunc(SINE[theta + 1] * amplitude / 256))
    theta = (theta + frequency) % 256
  end
end

-- pokeemerald/src/scanline_effect.c:214
function Scanline:initWave(startLine, endLine, frequency, amplitude, delayInterval, dest, offsetFn)
  self:clear()
  self.dest = dest
  self.state = 1
  self.wave = {
    startLine = startLine,
    endLine = endLine,
    waveLength = math.floor(256 / frequency),
    srcOffset = 0,
    framesUntilMove = delayInterval,
    delayInterval = delayInterval,
    offsetFn = offsetFn,
  }
  self.stopWaveTask = false
  local b0, b1 = self.buffers[0], self.buffers[1]
  generateWave(b0, 320, frequency, amplitude)
  local offset = 320
  for i = startLine, endLine - 1 do
    b0[i] = b0[offset]
    b1[i] = b0[offset]
    offset = offset + 1
  end
  return self.wave
end

-- pokeemerald/src/scanline_effect.c:126
function Scanline:runWaveTask(w)
  w = w or self.wave
  if not w then return false end
  if self.stopWaveTask then
    if self.wave == w then self.wave = nil end
    return false
  end
  local value = w.offsetFn and w.offsetFn() or 0
  local dst, b0 = self.buffers[self.srcBuffer], self.buffers[0]
  local offset = w.srcOffset + 320
  for i = w.startLine, w.endLine - 1 do
    dst[i] = u16(b0[offset] + value)
    offset = offset + 1
  end
  if w.framesUntilMove ~= 0 then
    w.framesUntilMove = w.framesUntilMove - 1
  else
    w.framesUntilMove = w.delayInterval
    w.srcOffset = w.srcOffset + 1
    if w.srcOffset == w.waveLength then w.srcOffset = 0 end
  end
  return true
end

return Scanline
