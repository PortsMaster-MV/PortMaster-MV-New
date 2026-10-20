local Cry = {}

-- pokeemerald/src/pokedex_cry_screen.c:23
Cry.MIN_NEEDLE_POS = 32
Cry.MAX_NEEDLE_POS = -32
Cry.NEEDLE_MOVE_INCREMENT = 5
Cry.WAVEFORM_WINDOW_HEIGHT = 56

local function tdiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or math.ceil(q)
end
Cry.tdiv = tdiv

local function s8(v)
  v = v % 256
  if v >= 128 then v = v - 256 end
  return v
end

-- pokeemerald/src/pokedex_cry_screen.c:169
local WAVEFORM_COLOR = { [0] = 15, 14, 13, 12, 11, 10, 9, 8, 8, 9, 10, 11, 12, 13, 14, 15 }

-- pokeemerald/src/pokedex_cry_screen.c:228
function Cry.new(bgTile)
  local c = {
    buffer = {},
    cryState = 0,
    playhead = 0,
    previousY = Cry.WAVEFORM_WINDOW_HEIGHT / 2,
    playStartPos = 30,
    cryOverrideCountdown = 0,
    cryRepeatDelay = 0,
    pixels = {},
    bgTile = bgTile,
    needle = { rotation = Cry.MIN_NEEDLE_POS, target = Cry.MIN_NEEDLE_POS, inc = 0 },
    dirty = true,
  }
  for i = 0, 15 do c.buffer[i] = 0 end
  for y = 0, Cry.WAVEFORM_WINDOW_HEIGHT - 1 do
    for x = 0, 255 do c.pixels[y * 256 + x] = bgTile[(y % 8) * 8 + (x % 8)] end
  end
  for i = 0, c.playStartPos * 8 - 1 do Cry.drawSegment(c, i, 0) end
  return c
end

-- pokeemerald/src/pokedex_cry_screen.c:390
function Cry.drawSegment(c, position, amplitude)
  position = position % 256
  local y = math.floor(((amplitude + 127) * 256) % 65536 / 1152.0)
  if y > Cry.WAVEFORM_WINDOW_HEIGHT - 1 then y = Cry.WAVEFORM_WINDOW_HEIGHT - 1 end
  local current = y
  local function plot(yy)
    c.pixels[yy * 256 + position] = WAVEFORM_COLOR[(math.floor(yy / 3) - 1) % 16]
  end
  if y > c.previousY then
    repeat
      plot(y)
      y = y - 1
    until y <= c.previousY
  else
    repeat
      plot(y)
      y = y + 1
    until y >= c.previousY
  end
  c.previousY = current
  c.dirty = true
end

-- pokeemerald/src/pokedex_cry_screen.c:376
local function advancePlayhead(c)
  c.playhead = (c.playhead + 2) % 256
  local col = (math.floor(c.playhead / 8) + c.playStartPos + 1) % 32
  for y = 0, Cry.WAVEFORM_WINDOW_HEIGHT - 1 do
    for px = 0, 7 do c.pixels[y * 256 + col * 8 + px] = c.bgTile[(y % 8) * 8 + px] end
  end
  c.dirty = true
end

local function flatline(c)
  Cry.drawSegment(c, c.playStartPos * 8 + c.playhead - 2, 0)
  Cry.drawSegment(c, c.playStartPos * 8 + c.playhead - 1, 0)
end

-- pokeemerald/src/pokedex_cry_screen.c:271
function Cry.update(c, hooks)
  advancePlayhead(c)
  if c.cryRepeatDelay > 0 then c.cryRepeatDelay = c.cryRepeatDelay - 1 end
  if c.cryOverrideCountdown > 0 then
    c.cryOverrideCountdown = c.cryOverrideCountdown - 1
    if c.cryOverrideCountdown == 0 then
      hooks.play()
      c.cryState = 1
      flatline(c)
      return
    end
  end
  if c.cryState == 0 then
    flatline(c)
    return
  end
  if c.cryState == 1 then
    hooks.buffer(c.buffer)
  elseif c.cryState > 8 then
    if not hooks.playing() then
      flatline(c)
      c.cryState = 0
      return
    end
    hooks.buffer(c.buffer)
    c.cryState = 1
  end
  local idx = 2 * (c.cryState - 1)
  Cry.drawSegment(c, c.playStartPos * 8 + c.playhead - 2, c.buffer[idx] % 256)
  Cry.drawSegment(c, c.playStartPos * 8 + c.playhead - 1, c.buffer[idx + 1] % 256)
  c.cryState = c.cryState + 1
end

-- pokeemerald/src/pokedex_cry_screen.c:327
function Cry.playButton(c, hooks)
  if c.cryOverrideCountdown == 0 and c.cryRepeatDelay == 0 then
    c.cryRepeatDelay = 4
    if hooks.playing() then
      hooks.stop()
      c.cryOverrideCountdown = 2
    else
      hooks.play()
      c.cryState = 1
    end
  end
end

local function setTarget(c, offset)
  local rotation = (Cry.MIN_NEEDLE_POS - offset) % 256
  if rotation > Cry.MIN_NEEDLE_POS and rotation < (Cry.MAX_NEEDLE_POS % 256) then
    rotation = Cry.MAX_NEEDLE_POS % 256
  end
  c.needle.target = s8(rotation)
  c.needle.inc = Cry.NEEDLE_MOVE_INCREMENT
end

-- pokeemerald/src/pokedex_cry_screen.c:488
function Cry.stepNeedle(c, sine)
  local n = c.needle
  if c.cryState == 0 then
    n.target = Cry.MIN_NEEDLE_POS
    if n.rotation > 0 then
      if n.inc ~= 1 then n.inc = n.inc - 1 end
    else
      n.inc = Cry.NEEDLE_MOVE_INCREMENT
    end
  elseif c.cryState == 2 then
    local peak = 0
    for i = 0, 15 do
      local v = s8(c.buffer[i])
      if peak < v then peak = v end
    end
    setTarget(c, s8(tdiv(peak * 208, 256)))
  elseif c.cryState == 6 then
    local amp = c.buffer[10] % 256
    setTarget(c, s8(math.floor(amp * 208 / 256)))
  end
  if n.rotation ~= n.target then
    if n.rotation < n.target then
      n.rotation = s8(n.rotation + n.inc)
      if n.rotation > n.target then
        n.rotation = n.target
        n.target = 0
      end
    else
      n.rotation = s8(n.rotation - n.inc)
      if n.rotation < n.target then
        n.rotation = n.target
        n.target = 0
      end
    end
  end
  local a = (n.rotation + 0x7F) % 256
  return tdiv(sine(a) * 24, 256), tdiv(sine(a + 64) * 24, 256)
end

return Cry
