local Kit = require("src.ui.game3.rse.scene_kit")
local Rtc = require("src.core.game3.rtc")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local Pal = require("src.core.game3.pal_fade")

local WallClock = {}
WallClock.__index = WallClock

WallClock.MODE = { SET = "set", VIEW = "view" }

-- pokeemerald/src/wallclock.c:64
local MOVE_NONE, MOVE_BACKWARD, MOVE_FORWARD = 0, 1, 2
local PERIOD_AM, PERIOD_PM = 0, 1
WallClock.MOVE = { NONE = MOVE_NONE, BACKWARD = MOVE_BACKWARD, FORWARD = MOVE_FORWARD }
WallClock.PERIOD = { AM = PERIOD_AM, PM = PERIOD_PM }

-- pokeemerald/src/trig.c:527
function WallClock.sin2(angle)
  angle = math.floor(angle) % 65536
  local m = angle % 180
  local v = math.floor(math.sin(m * math.pi / 180) * 4096 + 0.5)
  if math.floor(angle / 180) % 2 == 1 then return -v end
  return v
end

-- pokeemerald/src/trig.c:540
function WallClock.cos2(angle)
  return WallClock.sin2(angle + 90)
end

local function idiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or math.ceil(q)
end

-- pokeemerald/src/wallclock.c:902
function WallClock.calcMinHandDelta(speed)
  if speed > 60 then return 6 end
  if speed > 30 then return 3 end
  if speed > 10 then return 2 end
  return 1
end

-- pokeemerald/src/wallclock.c:35
function WallClock.calcNewMinHandAngle(angle, direction, speed)
  local delta = WallClock.calcMinHandDelta(speed)
  if direction == MOVE_BACKWARD then
    if angle ~= 0 then angle = angle - delta else angle = 360 - delta end
  elseif direction == MOVE_FORWARD then
    if angle < 360 - delta then angle = angle + delta else angle = 0 end
  end
  return angle % 65536
end

-- pokeemerald/src/wallclock.c:37
local function updateClockPeriod(t, direction)
  local h = t.hours
  if direction == MOVE_BACKWARD then
    if h == 11 then t.period = PERIOD_AM elseif h == 23 then t.period = PERIOD_PM end
  elseif direction == MOVE_FORWARD then
    if h == 0 then t.period = PERIOD_AM elseif h == 12 then t.period = PERIOD_PM end
  end
end

-- pokeemerald/src/wallclock.c:36
function WallClock.advanceClock(t, direction)
  if direction == MOVE_BACKWARD then
    if t.minutes > 0 then
      t.minutes = t.minutes - 1
    else
      t.minutes = 59
      if t.hours > 0 then t.hours = t.hours - 1 else t.hours = 23 end
      updateClockPeriod(t, direction)
    end
  elseif direction == MOVE_FORWARD then
    if t.minutes < 59 then
      t.minutes = t.minutes + 1
    else
      t.minutes = 0
      if t.hours < 23 then t.hours = t.hours + 1 else t.hours = 0 end
      updateClockPeriod(t, direction)
    end
  end
end

local function handAngles(t)
  t.minuteAngle = t.minutes * 6
  t.hourAngle = (t.hours % 12) * 30 + math.floor(t.minutes / 10) * 5
end

-- pokeemerald/src/wallclock.c:38
local function initClockWithRtc(self)
  local lt = Rtc.calcLocalTime(self.session)
  local t = self.t
  t.hours = lt.hours
  t.minutes = lt.minutes
  handAngles(t)
  t.period = lt.hours < 12 and PERIOD_AM or PERIOD_PM
end

-- pokeemerald/src/wallclock.c:41
local function stepPm(s, period)
  if period ~= PERIOD_AM then
    if s.angle >= 60 and s.angle < 90 then s.angle = s.angle + 5 end
    if s.angle < 60 then s.angle = s.angle + 1 end
  else
    if s.angle >= 46 and s.angle < 76 then s.angle = s.angle - 5 end
    if s.angle > 75 then s.angle = s.angle - 1 end
  end
end

-- pokeemerald/src/wallclock.c:42
local function stepAm(s, period)
  if period ~= PERIOD_AM then
    if s.angle >= 105 and s.angle < 135 then s.angle = s.angle + 5 end
    if s.angle < 105 then s.angle = s.angle + 1 end
  else
    if s.angle >= 91 and s.angle < 121 then s.angle = s.angle - 5 end
    if s.angle > 120 then s.angle = s.angle - 1 end
  end
end

local function indicatorOffset(angle)
  return idiv(WallClock.cos2(angle) * 30, 0x1000), idiv(WallClock.sin2(angle) * 30, 0x1000)
end
WallClock.indicatorOffset = indicatorOffset

function WallClock.new(opts)
  opts = opts or {}
  local mode = opts.mode or WallClock.MODE.SET
  local gender = (opts.gender == 1 or opts.gender == "female") and "female" or "male"
  local self = setmetatable({
    mode = mode,
    gender = gender,
    session = opts.session,
    onDone = opts.onDone,
    frameType = opts.frameType or 0,
    man = Kit.manifest("wallclock"),
    pal = Pal.new(),
    t = { minuteAngle = 0, hourAngle = 300, hours = 10, minutes = 0, moveDir = MOVE_NONE, period = PERIOD_AM, moveSpeed = 0 },
    pm = { angle = 45 },
    am = { angle = 90 },
    state = "wait_fade_in",
    frames = 0,
  }, WallClock)
  if not self.man then error("wall clock: data/generated/gba/wallclock/manifest.lua missing from the cache", 2) end
  if self.man.layout == "rs" then self.nativePolicy = require("src.ui.game3.rs.wall_clock_policy") end
  if mode == WallClock.MODE.VIEW then
    -- pokeemerald/src/wallclock.c:728
    initClockWithRtc(self)
    if self.t.period == PERIOD_AM then
      self.pm.angle, self.am.angle = 45, 90
    else
      self.pm.angle, self.am.angle = 90, 135
    end
  end
  -- pokeemerald/src/wallclock.c:671
  self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  return self
end

function WallClock:time()
  return self.t.hours, self.t.minutes
end

local function finish(self, result)
  self.done = true
  self.result = result
end

-- pokeemerald/src/wallclock.c:26
local function setClockInput(self, inp)
  local t = self.t
  if t.minuteAngle % 6 ~= 0 then
    t.minuteAngle = WallClock.calcNewMinHandAngle(t.minuteAngle, t.moveDir, t.moveSpeed)
    return
  end
  handAngles(t)
  if inp.new.a then
    self.state = "ask_confirm"
    return
  end
  t.moveDir = MOVE_NONE
  if inp.held.left then t.moveDir = MOVE_BACKWARD end
  if inp.held.right then t.moveDir = MOVE_FORWARD end
  if t.moveDir ~= MOVE_NONE then
    if t.moveSpeed < 0xFF then t.moveSpeed = t.moveSpeed + 1 end
    t.minuteAngle = WallClock.calcNewMinHandAngle(t.minuteAngle, t.moveDir, t.moveSpeed)
    WallClock.advanceClock(t, t.moveDir)
  else
    t.moveSpeed = 0
  end
end

function WallClock:frame(inp)
  inp = inp or { new = {}, held = {} }
  inp.new, inp.held = inp.new or {}, inp.held or {}
  self.frames = self.frames + 1
  local st = self.state
  if st == "wait_fade_in" then
    if not self.pal:fadeActive() then
      self.state = self.mode == WallClock.MODE.VIEW and "view_input" or "set_input"
    end
  elseif st == "set_input" then
    setClockInput(self, inp)
  elseif st == "ask_confirm" then
    -- pokeemerald/src/wallclock.c:27
    if self.nativePolicy then self.confirm = self.nativePolicy.confirm(self.frameType)
    else
      self.confirm = Kit.yesNo(self.man.confirmWindow.tilemapLeft, self.man.confirmWindow.tilemapTop,
        { frameType = self.frameType, initial = 0 })
    end
    self.state = "confirm_input"
  elseif st == "confirm_input" then
    -- pokeemerald/src/wallclock.c:28
    local r = self.confirm:input(inp)
    if r == 0 then
      Kit.playSe("SE_SELECT")
      if not self.nativePolicy then self.confirm = nil end
      self.state = "confirmed"
    elseif r == 1 or r == -1 then
      Kit.playSe("SE_SELECT")
      self.confirm = nil
      self.state = "set_input"
    end
  elseif st == "confirmed" then
    -- pokeemerald/src/wallclock.c:29
    Rtc.initLocalTimeOffset(self.session, self.t.hours, self.t.minutes)
    self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    self.state = "set_exit"
  elseif st == "set_exit" then
    if not self.pal:fadeActive() then
      finish(self, { hours = self.t.hours, minutes = self.t.minutes, confirmed = true })
    end
  elseif st == "view_input" then
    -- pokeemerald/src/wallclock.c:32
    initClockWithRtc(self)
    if inp.new.a or inp.new.b then self.state = "view_fade_out" end
  elseif st == "view_fade_out" then
    self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    self.state = "view_exit"
  elseif st == "view_exit" then
    if not self.pal:fadeActive() then finish(self, { confirmed = false }) end
  end
  stepPm(self.pm, self.t.period)
  stepAm(self.am, self.t.period)
  self.pal:updateFade()
  if self.done and self.onDone then
    local cb = self.onDone
    self.onDone = nil
    cb(self.result)
  end
  return self.done
end

local function handOffset(man, angle)
  local c = man.handCoords and man.handCoords[(angle % 360) + 1]
  if not c then return 0, 0 end
  return c[1], c[2]
end

local function drawSprite(img, cx, cy, rot)
  if not img then return end
  local w, h = img:getDimensions()
  love.graphics.draw(img, cx, cy, rot or 0, 1, 1, w / 2, h / 2)
end

function WallClock:draw()
  local man = self.man
  local g = self.gender
  local layer = man.layers[self.mode == WallClock.MODE.VIEW and "view" or "start"]
  local pal = man.palettes and man.palettes[g]
  local bd = Kit.color555(pal and pal[1] or 0)
  love.graphics.clear(bd[1], bd[2], bd[3], 1)
  love.graphics.setColor(1, 1, 1, 1)
  local s = man.sprites
  -- pokeemerald/src/wallclock.c:41
  local px, py = indicatorOffset(self.pm.angle)
  local ax, ay = indicatorOffset(self.am.angle)
  drawSprite(Kit.image(s.pm.variants[g]), 120 + px, 80 + py)
  drawSprite(Kit.image(s.am.variants[g]), 120 + ax, 80 + ay)
  local bg = Kit.maskedLayer(layer.variants[g], layer.index) or Kit.image(layer.variants[g])
  if bg then love.graphics.draw(bg, 0, 0) end
  -- pokeemerald/src/wallclock.c:39
  local mx, my = handOffset(man, self.t.minuteAngle)
  local hx, hy = handOffset(man, self.t.hourAngle)
  drawSprite(Kit.image(s.hour_hand.variants[g]), 120 + hx, 80 + hy, math.rad(self.t.hourAngle))
  drawSprite(Kit.image(s.minute_hand.variants[g]), 120 + mx, 80 + my, math.rad(self.t.minuteAngle))
  if self.nativePolicy then
    self.nativePolicy.draw(self)
    Kit.drawFade(self.pal, 0)
    self.nativePolicy.drawCursor(self)
    return
  end
  local tp = man.palettes and man.palettes.textPrompt
  local label = self.mode == WallClock.MODE.VIEW and "gText_Cancel4" or "gText_Confirm3"
  local w2 = man.windows and man.windows[2]
  if w2 then
    local colors = tp and {
      fg = Kit.color555(tp[3]), bg = Kit.color555(tp[2]), shadow = Kit.color555(tp[4]),
    } or FrlgFont.COLOR.WHITE
    FrlgFont.draw(RomText.plain(label), w2.tilemapLeft * 8, w2.tilemapTop * 8 + 1, { colors = colors })
  end
  if self.confirm or self.state == "confirm_input" then
    local w1 = man.windows[1]
    local colors = Kit.messageColors()
    Kit.userFrame(w1.tilemapLeft, w1.tilemapTop, w1.width, w1.height, self.frameType, colors.bg)
    FrlgFont.draw(RomText.plain("gText_IsThisTheCorrectTime"), w1.tilemapLeft * 8, w1.tilemapTop * 8 + 1,
      { colors = colors })
    if self.confirm then self.confirm:draw() end
  end
  Kit.drawFade(self.pal, 0)
end


local Host = {}
WallClock.Host = Host
Host._clock = nil
Host._step = nil

function WallClock.open(opts)
  local Stack = require("src.ui.game3.stack")
  local clock = WallClock.new(opts)
  Host._clock = clock
  Host._step = Kit.stepper()
  local userDone = clock.onDone
  clock.onDone = function(result)
    Host._clock = nil
    Stack.pop("wall_clock")
    if userDone then userDone(result) end
  end
  Stack.push("wall_clock", Host, { hideBelow = true, fullscreen = true })
  return clock
end

function WallClock.isOpen()
  return Host._clock ~= nil
end

function WallClock.active()
  return Host._clock
end

function WallClock.reset()
  if Host._clock then
    Host._clock = nil
    require("src.ui.game3.stack").pop("wall_clock")
  end
  Host._step = nil
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local clock = Host._clock
  if not clock then return end
  Host._step:run(dt, function(inp)
    if clock.done then return true end
    clock:frame(inp)
    return clock.done or nil
  end)
end

function Host.draw()
  if Host._clock then Host._clock:draw() end
end

return WallClock
