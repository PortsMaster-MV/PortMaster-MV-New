local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local Pokeblock = require("src.core.game3.rse.pokeblock")
local Pokemon = require("src.core.game3.pokemon")

local Feed = {}

Feed.ID = "rse_pokeblock_feed"
Feed.open = false

-- pokeemerald/src/pokeblock_feed.c:57
Feed.MON_X, Feed.MON_Y = 48, 80
-- pokeemerald/src/pokeblock_feed.c:454
Feed.WIN = { 1, 15, 28, 4 }
-- pokeemerald/src/pokeblock_feed.c:805
local STATE_START_THROW = 255
local STATE_SPAWN_PBLOCK = STATE_START_THROW + 14
local STATE_START_JUMP = STATE_SPAWN_PBLOCK + 12
local STATE_PRINT_MSG = STATE_START_JUMP + 16

-- pokeemerald/src/pokeblock_feed.c:29
local ROT_IDX, ROT_SPEED, SIN_AMP, COS_AMP, TIME, ROT_ACCEL, TARGET_X, TARGET_Y, APPR_TIME, IS_LAST = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
-- pokeemerald/src/pokeblock_feed.c:54
local NUM_MON_AFFINES = 10

local st = {}
Feed._st = st

local bit = require("bit")

local function gfx() return Gfx.of("rse/pokeblock") end
local function man() return gfx():manifest() end

local function s16(v)
  v = v % 0x10000
  return v >= 0x8000 and v - 0x10000 or v
end

local function cdiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or math.ceil(q)
end

local function sine(i)
  return man().sine[(i % 320) + 1] or 0
end

-- pokeemerald/src/trig.c:515
local function Sin(index, amplitude)
  return bit.arshift(s16(amplitude) * sine(s16(index)), 8)
end

-- pokeemerald/src/trig.c:521
local function Cos(index, amplitude)
  return bit.arshift(s16(amplitude) * sine(s16(index) + 64), 8)
end

local Affine = {}
Affine.__index = Affine

-- pokeemerald/src/sprite.c:1180
function Affine.new(cmds)
  local a = setmetatable({ cmds = cmds, idx = 1, delay = 0, xScale = 256, yScale = 256, rot = 0, ended = false }, Affine)
  a:apply()
  return a
end

function Affine:apply()
  local c = self.cmds[self.idx]
  if not c or c.op ~= "frame" then
    self.ended = true
    return
  end
  if c.duration > 0 then
    self.delay = c.duration - 1
    self:relative(c)
  else
    self.xScale, self.yScale, self.rot = c.xScale, c.yScale, (c.rotation * 256) % 0x10000
    self.delay = 0
  end
end

function Affine:relative(c)
  self.xScale = self.xScale + c.xScale
  self.yScale = self.yScale + c.yScale
  self.rot = (self.rot + c.rotation * 256) % 0x10000
end

-- pokeemerald/src/sprite.c:1084
function Affine:step()
  if self.ended then return end
  if self.delay > 0 then
    self.delay = self.delay - 1
    self:relative(self.cmds[self.idx])
    return
  end
  self.idx = self.idx + 1
  local c = self.cmds[self.idx]
  if not c or c.op == "end" then
    self.ended = true
    self.idx = self.idx - 1
  elseif c.op == "jump" then
    self.idx = c.target + 1
    self:apply()
  else
    self:apply()
  end
end

function Affine:transform()
  return -(self.rot / 0x10000) * 2 * math.pi, self.xScale / 256, self.yScale / 256
end
Feed.Affine = Affine

local function textSpeed()
  local ok, Options = pcall(require, "src.core.game3.options")
  return Kit.textSpeedDelay(ok and Options.textSpeed(st.session) or 1)
end

-- pokeemerald/src/pokeblock_feed.c:994
local function calcAnimLength()
  local m = man()
  local len = 1
  local animId = m.natureAnims[st.nature + 1][1]
  for _ = 0, 7 do
    local row = m.feedAnims[animId + 1]
    len = len + row[TIME + 1]
    if row[IS_LAST + 1] == 1 then break end
    animId = animId + 1
  end
  st.monAnimLength = len
end

-- pokeemerald/src/pokeblock_feed.c:1149
local function calcMovement()
  local ad = st.animData
  local negative = false
  local x = st.monX - st.monInitX
  local y = st.monY - st.monInitY
  while true do
    local accel = math.abs(ad[ROT_ACCEL])
    local amplitude = (accel + ad[COS_AMP]) % 0x10000
    ad[COS_AMP] = s16(amplitude)
    if ad[SIN_AMP] < 0 then negative = true end
    local time = (st.maxAnimStageTime - ad[TIME]) % 0x10000
    if ad[TIME] == 0 then break end
    local q = math.floor(amplitude / 0x100)
    if not negative then
      st.animX[time] = s16(Sin(ad[ROT_IDX], ad[SIN_AMP] + q) + x)
      st.animY[time] = s16(Cos(ad[ROT_IDX], ad[COS_AMP] + q) + y)
    else
      st.animX[time] = s16(Sin(ad[ROT_IDX], ad[SIN_AMP] - q) + x)
      st.animY[time] = s16(Cos(ad[ROT_IDX], ad[COS_AMP] - q) + y)
    end
    ad[ROT_IDX] = (ad[ROT_IDX] + ad[ROT_SPEED]) % 256
    ad[TIME] = ad[TIME] - 1
  end
end

-- pokeemerald/src/pokeblock_feed.c:1127
local function calcMovementEnd()
  local ad = st.animData
  local approach = ad[APPR_TIME] % 0x10000
  local time = (st.maxAnimStageTime - approach) % 0x10000
  local x = s16(st.monX + ad[TARGET_X])
  local y = s16(st.monY + ad[TARGET_Y])
  for i = 0, time - 2 do
    local xo = (st.animX[approach + i] or 0) - x
    local yo = (st.animY[approach + i] or 0) - y
    st.animX[approach + i] = s16((st.animX[approach + i] or 0) - cdiv(xo * (i + 1), time))
    st.animY[approach + i] = s16((st.animY[approach + i] or 0) - cdiv(yo * (i + 1), time))
  end
  st.animX[approach + time - 1] = x
  st.animY[approach + time - 1] = y
end

-- pokeemerald/src/pokeblock_feed.c:1076
local function initAnimStage()
  local row = man().feedAnims[st.animId + 1]
  local ad = {}
  for i = 0, 9 do ad[i] = row[i + 1] end
  st.animData = ad
  if ad[TIME] == 0 then return true end
  st.monInitX = Sin(ad[ROT_IDX], ad[SIN_AMP])
  st.monInitY = Cos(ad[ROT_IDX], ad[COS_AMP])
  st.maxAnimStageTime = ad[TIME]
  st.monX = st.mon.x2
  st.monY = st.mon.y2
  calcMovement()
  ad[TIME] = st.maxAnimStageTime
  calcMovementEnd()
  ad[TIME] = st.maxAnimStageTime
  return false
end

-- pokeemerald/src/pokeblock_feed.c:1106
local function doAnimStep()
  local time = st.maxAnimStageTime - st.animData[TIME]
  st.mon.x2 = st.animX[time] or 0
  st.mon.y2 = st.animY[time] or 0
  st.animData[TIME] = st.animData[TIME] - 1
  return st.animData[TIME] == 0
end

-- pokeemerald/src/pokeblock_feed.c:1012
local function updateMonAnim()
  local m = man()
  local affineId = m.natureAnims[st.nature + 1][2]
  local rs = st.animRunState
  if rs == 0 then
    st.animId = m.natureAnims[st.nature + 1][1]
    st.animRunState = 10
    return
  end
  if rs == 10 then
    initAnimStage()
    st.animRunState = 50
    rs = 50
  end
  if rs == 50 then
    if affineId ~= 0 then
      local idx = st.noMonFlip and affineId or (affineId + NUM_MON_AFFINES)
      st.mon.affine = Affine.new(m.affine.mon[idx + 1])
    end
    st.animRunState = 60
  elseif rs == 60 then
    if doAnimStep() then
      if st.animData[IS_LAST] == 0 then
        st.animId = st.animId + 1
        initAnimStage()
        st.animRunState = 60
      else
        st.animRunState = 70
      end
    end
  elseif rs == 70 then
    st.animId = 0
    st.animRunState = 0
  end
end

local function startMessage()
  local mon = st.session.party[st.partyIndex]
  local block = Pokeblock.get(st.session, st.pokeblockId)
  -- pokeemerald/src/pokeblock_feed.c:863
  st.gain = Pokeblock.gain(st.nature, block)
  st.printer = Kit.printer(Pokeblock.ateText(st.gain), {
    ctx = { stringVars = { Pokemon.displayMonName(mon), Pokeblock.name(block) } },
    speed = textSpeed(),
  })
end

-- pokeemerald/src/pokeblock_feed.c:810
local function feedTask()
  local s = st.tState
  if s == 0 then
    st.animRunState = 0
    st.timer = 0
    calcAnimLength()
  elseif s == STATE_START_THROW then
    st.case.affine = Affine.new(man().affine.caseThrow[1])
  elseif s == STATE_SPAWN_PBLOCK then
    -- pokeemerald/src/pokeblock_feed.c:977
    st.block = { x = 174, y = 84, speed = -12, accel = 1, affine = Affine.new(man().affine.pokeblock[1]) }
  elseif s == STATE_START_JUMP then
    -- pokeemerald/src/pokeblock_feed.c:931
    st.mon.x, st.mon.y = Feed.MON_X, Feed.MON_Y
    st.mon.jump = { speed = -8, accel = 1 }
  elseif s == STATE_PRINT_MSG then
    st.phase = "message"
    startMessage()
    return
  end
  if st.timer < st.monAnimLength then
    updateMonAnim()
  elseif st.timer == st.monAnimLength then
    st.tState = STATE_START_THROW - 1
  end
  st.timer = st.timer + 1
  st.tState = st.tState + 1
end

local function stepSprites()
  local mon = st.mon
  if mon.affine then mon.affine:step() end
  if mon.jump then
    -- pokeemerald/src/pokeblock_feed.c:940
    mon.x = mon.x + 4
    mon.y = mon.y + mon.jump.speed
    mon.jump.speed = mon.jump.speed + mon.jump.accel
    if mon.jump.speed == 0 then
      pcall(function() require("src.core.game3.audio").playCry(st.species) end)
    end
    if mon.jump.speed == 9 then mon.jump = nil end
  end
  if st.case.affine then st.case.affine:step() end
  local b = st.block
  if b then
    -- pokeemerald/src/pokeblock_feed.c:985
    b.x = b.x - 4
    b.y = b.y + b.speed
    b.speed = b.speed + b.accel
    b.affine:step()
    if b.speed == 10 then st.block = nil end
  end
end

local function step(inp)
  st.frame = st.frame + 1
  if st.fadeDir ~= 0 then
    st.fade = st.fade + st.fadeDir * 2
    if st.fade <= 0 then
      st.fade, st.fadeDir = 0, 0
    elseif st.fade >= 16 then
      st.fade, st.fadeDir = 16, 0
      Feed.finish()
      return
    end
    stepSprites()
    return
  end
  if st.phase == "anim" then
    feedTask()
  elseif st.phase == "message" then
    if st.printer and st.printer:isActive() then
      st.printer:run(inp)
    else
      -- pokeemerald/src/pokeblock_feed.c:852
      st.phase = "done"
      st.fadeDir = 1
    end
  end
  stepSprites()
end

-- pokeemerald/src/pokeblock_feed.c:687
function Feed.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session or Pokeblock.session()
  st.partyIndex = opts.partyIndex or 1
  st.pokeblockId = opts.pokeblockId or 0
  st.onDone = opts.onDone
  local mon = st.session.party[st.partyIndex]
  st.species = Pokemon.speciesOf(mon)
  st.nature = Pokeblock.natureOf(mon)
  local pic = Pokemon.monFrontPic(mon)
  -- pokeemerald/src/pokeblock_feed.c:919
  st.noMonFlip = man().noFlip[tonumber(st.species) or -1] == true
  st.mon = { x = Feed.MON_X, y = Feed.MON_Y, x2 = 0, y2 = 0, image = pic and pic.image or nil }
  if not st.noMonFlip then st.mon.affine = Affine.new(man().affine.monNoFlip[1]) end
  st.case = { x = 188, y = 100, affine = Affine.new(man().affine.caseStill[1]) }
  st.tState = 0
  st.timer = 0
  st.frame = 0
  st.phase = "anim"
  st.fade = 16
  st.fadeDir = -1
  st.animX, st.animY = {}, {}
  Feed.open = true
  Stack.push(Feed.ID, Feed, { hideBelow = true, fullscreen = true })
  return true
end

function Feed.isOpen()
  return Feed.open
end

-- pokeemerald/src/pokeblock_feed.c:879
function Feed.finish()
  Feed.open = false
  Stack.pop(Feed.ID)
  local cb, gain = st.onDone, st.gain or 0
  if cb then cb(gain) end
end

function Feed.reset()
  Feed.open = false
  Stack.pop(Feed.ID)
end

function Feed.handleInput(input)
  if not Feed.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

function Feed.update()
  if not Feed.open then return end
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  step(inp)
end

local function drawAffine(img, cx, cy, affine)
  local w, h = img:getDimensions()
  local r, sx, sy = 0, 1, 1
  if affine then r, sx, sy = affine:transform() end
  love.graphics.draw(img, cx, cy, r, sx, sy, w / 2, h / 2)
end

function Feed.draw()
  if not Feed.open then return end
  local m = man()
  if not st.bg then
    local pal = Gfx.palette(m.palettes.feed_bg, {}, 2)
    pal[0] = 0
    st.bg = gfx():renderMap(gfx():map("feed_bg"), "feed_bg", pal, { rows = 20, backdrop = true })
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(st.bg, 0, 0)
  local caseImg = gfx():sprite("device", 0, 64, 64, m.palettes.device)
  drawAffine(caseImg, st.case.x, st.case.y, st.case.affine)
  if st.mon.image then
    drawAffine(st.mon.image, st.mon.x + st.mon.x2, st.mon.y + st.mon.y2, st.mon.affine)
  end
  if st.block then
    local block = Pokeblock.get(st.session, st.pokeblockId)
    local pal = m.colors[Pokeblock.data(block, 0)] or m.colors[1]
    drawAffine(gfx():sprite("pokeblock", 0, 8, 8, pal), st.block.x, st.block.y, st.block.affine)
  end
  local W = Feed.WIN
  Chrome.stdFrame(W[1], W[2], W[3], W[4])
  if st.printer then
    local p = Kit.chromePalettes() and Kit.chromePalettes().std_menu
    local function c(i) return p and Kit.color8(p[i]) or { 0, 0, 0, 1 } end
    st.printer:draw(W[1] * 8, W[2] * 8 + 1, { colors = { fg = c(2), shadow = c(3), bg = c(1) } })
  end
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

Feed.FrlgFont = FrlgFont

return Feed
