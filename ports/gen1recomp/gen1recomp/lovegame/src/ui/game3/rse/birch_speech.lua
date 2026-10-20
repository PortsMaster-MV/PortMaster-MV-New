local Kit = require("src.ui.game3.rse.scene_kit")
local Audio = require("src.core.game3.audio")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local Pal = require("src.core.game3.pal_fade")
local Trig = require("src.core.game3.trig")
local Rng = require("src.core.game3.rng")
local Naming = require("src.ui.game3.naming")

local Birch = {}
Birch.__index = Birch

local MALE, FEMALE = 0, 1

-- pokeemerald/src/main_menu.c:374
local WIN_TEXT = { left = 2, top = 15, width = 27, height = 4 }
local WIN_GENDER = { left = 3, top = 5, width = 6, height = 4 }

-- pokeemerald/src/data.c:144
local AFFINE_EMERGE = { { set = 0x28 }, { delta = 0x12, frames = 12 } }
-- pokeemerald/src/main_menu.c:445
local AFFINE_SHRINK = { { delta = -2, frames = 0x30 } }
-- pokeemerald/src/pokeball.c:133
local BALL_ANIMS = {
  [0] = { { frame = 0, dur = 1 } },
  [1] = { { frame = 1, dur = 5 }, { frame = 2, dur = 5 } },
  [2] = { { frame = 1, dur = 5 }, { frame = 0, dur = 5 } },
}

local function idiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or math.ceil(q)
end

-- pokeemerald/src/trig.c:5
local function sin(index, amp)
  return math.floor(Trig.SINE[(math.floor(index) % 256) + 1] * amp / 256)
end

local function sprite(img, frames, x, y)
  return {
    img = img, frames = frames or 1, frame = 0,
    x = x or 0, y = y or 0, x2 = 0, y2 = 0,
    invisible = true, blend = false, callback = "null",
    scale = 1, sx = 1, sy = 1, affine = nil, affineEnded = false,
  }
end

local function startAffine(s, cmds)
  s.affine = { cmds = cmds, idx = 1, left = nil, value = 0x100 }
  s.affineEnded = false
  local c = cmds[1]
  if c.set then
    s.affine.value = c.set
    s.affine.idx = 2
  else
    s.affine.value = s.affine.value + c.delta
    s.affine.left = c.frames - 1
  end
  s.scale = s.affine.value / 256
end

local function stepAffine(s)
  local a = s.affine
  if not a or s.affineEnded then return end
  if a.left and a.left > 0 then
    a.value = a.value + a.cmds[a.idx].delta
    a.left = a.left - 1
    if a.left == 0 then
      a.left = nil
      a.idx = a.idx + 1
    end
  else
    local c = a.cmds[a.idx]
    if a.left == 0 then
      a.left = nil
      a.idx = a.idx + 1
      c = a.cmds[a.idx]
    end
    if not c then
      s.affineEnded = true
    elseif c.set then
      a.value = c.set
      a.idx = a.idx + 1
    else
      a.value = a.value + c.delta
      a.left = c.frames - 1
      if a.left == 0 then
        a.left = nil
        a.idx = a.idx + 1
      end
    end
  end
  s.scale = a.value / 256
end

local function startAnim(s, anims, num)
  s.anim = { cmds = anims[num], idx = 1, timer = anims[num][1].dur }
  s.frame = anims[num][1].frame
  s.animEnded = false
end

local function stepAnim(s)
  local a = s.anim
  if not a or s.animEnded then return end
  if a.timer > 1 then
    a.timer = a.timer - 1
    return
  end
  a.idx = a.idx + 1
  local c = a.cmds[a.idx]
  if not c then
    s.animEnded = true
    return
  end
  s.frame = c.frame
  a.timer = c.dur
end

function Birch.new(opts, ctx)
  if Kit.isBootState(opts) then
    local state = opts
    opts = {
      textSpeed = state.textSpeed,
      frameType = state.continueInfo and state.continueInfo.frameType or 0,
    }
  end
  opts = opts or {}
  local man = Kit.manifest("birch")
  if not man then error("birch speech: data/generated/gba/birch/manifest.lua missing from the cache", 2) end
  local pics = man.pics
  local self = setmetatable({
    man = man,
    pal = Pal.new(),
    step = Kit.stepper(),
    textSpeedOption = tonumber(opts.textSpeed) or 1,
    frameType = tonumber(opts.frameType) or 0,
    tasks = {},
    frames = 0,
    result = nil,
    gradState = man.layers.bg.initialState or 8,
    bg1hofs = 0,
    bgVisible = false,
    bld = { eva = 16, evb = 0 },
    monBlend = 0,
    events = {},
  }, Birch)
  self.textSpeed = Kit.textSpeedDelay(self.textSpeedOption)
  local s = {
    birch = sprite(Kit.image(pics.birch.png), 1, 136, 60),
    lotad = sprite(Kit.image(pics.lotad.png), pics.lotad.frames, 100, 75),
    brendan = sprite(Kit.image(pics.brendan.png), 1, 120, 60),
    may = sprite(Kit.image(pics.may.png), 1, 120, 60),
  }
  self.sprites = s
  self.lotadSpecies = pics.lotad.species
  self.main = { func = "Init", timer = 0, bg1hofs = 0, doneFading = false }
  self.gender = MALE
  self.playerName = ""
  return self
end

function Birch:event(name)
  self.events[#self.events + 1] = { frame = self.frames, name = name }
  if self.onEvent then self.onEvent(name, self.frames) end
end

function Birch:createTask(fn, data)
  local t = { fn = fn, data = data or {}, alive = true }
  self.tasks[#self.tasks + 1] = t
  return t
end

-- pokeemerald/src/main_menu.c:1921

local function fadeOutTarget1InTarget2(self, t)
  local d = t.data
  if d.a1 == 0 then
    self.main.doneFading = true
    t.alive = false
  elseif d.timer ~= 0 then
    d.timer = d.timer - 1
  else
    d.timer = d.delay
    d.a1 = d.a1 - 1
    d.a2 = d.a2 + 1
    self.bld = { eva = d.a1, evb = d.a2 }
  end
end

function Birch:startFadeOutTarget1InTarget2(delay)
  self.bld = { eva = 16, evb = 0 }
  self.main.doneFading = false
  self:createTask(fadeOutTarget1InTarget2, { a1 = 16, a2 = 0, delay = delay, timer = delay })
end

local function fadeInTarget1OutTarget2(self, t)
  local d = t.data
  if d.a1 == 16 then
    self.main.doneFading = true
    t.alive = false
  elseif d.timer ~= 0 then
    d.timer = d.timer - 1
  else
    d.timer = d.delay
    d.a1 = d.a1 + 1
    d.a2 = d.a2 - 1
    self.bld = { eva = d.a1, evb = d.a2 }
  end
end

function Birch:startFadeInTarget1OutTarget2(delay)
  self.bld = { eva = 0, evb = 16 }
  self.main.doneFading = false
  self:createTask(fadeInTarget1OutTarget2, { a1 = 0, a2 = 16, delay = delay, timer = delay })
end

local function fadePlatformIn(self, t)
  local d = t.data
  if d.before ~= 0 then
    d.before = d.before - 1
  elseif d.pal == 8 then
    t.alive = false
  elseif d.timer ~= 0 then
    d.timer = d.timer - 1
  else
    d.timer = d.delay
    d.pal = d.pal + 1
    self.gradState = d.pal
  end
end

function Birch:startFadePlatformIn(delay)
  self:createTask(fadePlatformIn, { pal = 0, before = 8, delay = delay, timer = delay })
end

local function fadePlatformOut(self, t)
  local d = t.data
  if d.before ~= 0 then
    d.before = d.before - 1
  elseif d.pal == 0 then
    t.alive = false
  elseif d.timer ~= 0 then
    d.timer = d.timer - 1
  else
    d.timer = d.delay
    d.pal = d.pal - 1
    self.gradState = d.pal
  end
end

function Birch:startFadePlatformOut(delay)
  self:createTask(fadePlatformOut, { pal = 8, before = 8, delay = delay, timer = delay })
end


function Birch:print(key, onPause)
  self.printer = Kit.printer(key, {
    speed = self.textSpeed,
    ctx = { playerName = self.playerName, playerGender = self.gender },
    textSpeedOption = self.textSpeedOption,
    onPause = onPause,
  })
end

function Birch:printersActive(inp)
  if self.printer then
    self.printer:run(inp)
    return self.printer:isActive()
  end
  return false
end

function Birch:clearWindow()
  self.printer = nil
end

-- pokeemerald/src/pokeball.c:1031

function Birch:ballColor()
  local ok, BallOpen = pcall(require, "src.core.game3.battle.ball_open")
  local d = ok and BallOpen.data() or nil
  local c = d and d.fadeColors and d.fadeColors[1]
  return c and { c[1] / 31, c[2] / 31, c[3] / 31 } or { 1, 1, 1 }
end

function Birch:createReleaseBall(mon, x, y, delay)
  local ball = sprite(Kit.rgbaImage("data/generated/gba/pokemon/battle/ball_open/balls.rgba", 192, 48), 3, x, y)
  ball.invisible = false
  startAnim(ball, BALL_ANIMS, 0)
  ball.finalX, ball.finalY = mon.x, mon.y
  mon.x, mon.y = x, y
  mon.invisible = true
  ball.delay = delay
  ball.callback = "releaseMon"
  ball.mon = mon
  self.ball = ball
  return ball
end

local function launchBallFadeMon(self)
  -- pokeemerald/src/battle_anim_throw.c:2033
  self.monBlend = 16
  self:createTask(function(me, t)
    local d = t.data
    if d.stage == 0 then
      if not me.pal:fadeActive() then
        me.pal:beginFade(Pal.BG, 0, 16, 0, Pal.WHITE)
        d.stage = 1
      end
    elseif d.timer <= 16 then
      me.monBlend = d.coeff
      d.coeff = d.coeff - 1
      d.timer = d.timer + 1
    else
      me.monBlend = 0
      t.alive = false
    end
  end, { stage = 0, coeff = 16, timer = 0 })
  self.pal:beginFade(Pal.BG, 0, 0, 16, Pal.WHITE)
end

function Birch:ballCallback(ball)
  if ball.callback == "releaseMon" then
    if ball.delay == 0 then
      startAnim(ball, BALL_ANIMS, 1)
      local ok, BallOpen = pcall(require, "src.core.game3.battle.ball_open")
      if ok and BallOpen then pcall(BallOpen.startParticles, ball.x, ball.y - 5, 4) end
      launchBallFadeMon(self)
      ball.callback = "flyOut"
      ball.mon.invisible = false
      startAffine(ball.mon, AFFINE_EMERGE)
      ball.trig = 0
      self:event("lotad_release")
    else
      ball.delay = ball.delay - 1
    end
  elseif ball.callback == "flyOut" then
    -- pokeemerald/src/pokeball.c:36
    local mon = ball.mon
    local emerged, atFinal = false, false
    if ball.animEnded then ball.invisible = true end
    if mon.affineEnded then
      mon.affine = nil
      mon.scale = 1
      emerged = true
    end
    mon.x = idiv((ball.finalX - ball.x) * ball.trig, 128) + ball.x
    mon.y = idiv((ball.finalY - ball.y) * ball.trig, 128) + ball.y
    if ball.trig < 128 then
      local sine = -idiv(Trig.SINE[(ball.trig % 256) + 1], 8)
      ball.trig = ball.trig + 4
      mon.x2, mon.y2 = sine, sine
    else
      mon.x, mon.y = ball.finalX, ball.finalY
      mon.x2, mon.y2 = 0, 0
      atFinal = true
    end
    if ball.animEnded and emerged and atFinal then
      self:monFrontAnimation(mon)
      self.ball = nil
    end
  end
end

-- pokeemerald/src/pokemon.c:6811
function Birch:monFrontAnimation(mon)
  local MonAnim = require("src.core.game3.mon_anim")
  local sp = self.lotadSpecies
  mon.anim = nil
  mon.ma = MonAnim.newSprite(sp, { data = { [2] = sp } })
  MonAnim.doFront(mon.ma, sp, false, 0, {
    cry = function(s, pan)
      Audio.playCry(s, 0, pan)
      self:event("lotad_cry")
    end,
  })
  mon.callback = "monAnim"
end

local function monAnimStep(mon)
  local MonAnim = require("src.core.game3.mon_anim")
  MonAnim.step(mon.ma, true)
  local t = MonAnim.transform(mon.ma)
  mon.x2, mon.y2, mon.sx, mon.sy, mon.frame = t.x2, t.y2, t.sx, t.sy, t.frame
  mon.rotation = t.rotation
  if MonAnim.done(mon.ma) then mon.callback = "dummy" end
end

function Birch:spriteCallbacks()
  for _, s in pairs(self.sprites) do
    if s.callback == "monAnim" then
      monAnimStep(s)
    elseif s.callback == "waitAnimEnd" then
      if s.animEnded then s.callback = "dummy" end
    elseif s.callback == "shrinkDown" then
      -- pokeemerald/src/main_menu.c:1864
      local v = s.y * 65536 + (s.fracY or 0) + 0xC000
      s.y = math.floor(v / 65536)
      s.fracY = v % 65536
    end
    stepAnim(s)
    stepAffine(s)
  end
  if self.ball then
    self:ballCallback(self.ball)
    if self.ball then stepAnim(self.ball) end
  end
  local ok, BallOpen = pcall(require, "src.core.game3.battle.ball_open")
  if ok and BallOpen and BallOpen.tick then pcall(BallOpen.tick) end
end

-- pokeemerald/src/main_menu.c:1265

local F = {}

function F.Init(self, m)
  -- pokeemerald/src/main_menu.c:1265
  self.bgVisible = true
  self.gradState = 8
  self.pal:blend(Pal.ALL, 16, Pal.BLACK)
  self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  m.bg1hofs = 0
  m.timer = 0xD8
  m.player = nil
  Audio.playSong(Kit.song("MUS_ROUTE122"), { restart = true })
  self:event("mus_route122")
  m.func = "WaitToShowBirch"
end

function F.WaitToShowBirch(self, m)
  if m.timer > 0 then
    m.timer = m.timer - 1
    return
  end
  local b = self.sprites.birch
  b.x, b.y, b.invisible, b.blend = 136, 60, false, true
  self:startFadeInTarget1OutTarget2(10)
  self:startFadePlatformOut(20)
  m.timer = 80
  self:event("birch_fade_in")
  m.func = "WaitForSpriteFadeInWelcome"
end

function F.WaitForSpriteFadeInWelcome(self, m)
  if not m.doneFading then return end
  self.sprites.birch.blend = false
  if m.timer > 0 then
    m.timer = m.timer - 1
    return
  end
  self.showDialogue = true
  self:clearWindow()
  self:print("gText_Birch_Welcome")
  self:event("welcome_text")
  m.func = "ThisIsAPokemon"
end

function F.ThisIsAPokemon(self, m, inp)
  if self.pal:fadeActive() then return end
  if self:printersActive(inp) then return end
  m.func = "MainSpeech"
  self.startedBallTask = false
  self:print("gText_ThisIsAPokemon", function()
    -- pokeemerald/src/main_menu.c:2249
    if not self.startedBallTask then
      self.startedBallTask = true
      self:createTask(Birch.Sub_InitPokeBall, { state = 0 })
    end
  end)
end

function Birch.Sub_InitPokeBall(self, t)
  -- pokeemerald/src/main_menu.c:1368
  local l = self.sprites.lotad
  l.x, l.y, l.invisible = 100, 75, false
  self:createReleaseBall(l, 112, 58, 32)
  self:event("ball_created")
  t.fn = Birch.Sub_WaitForLotad
  self.main.timer = 0
end

function Birch.Sub_WaitForLotad(self, t)
  -- pokeemerald/src/main_menu.c:1382
  local d = t.data
  local l = self.sprites.lotad
  if d.state == 0 then
    if l.callback ~= "dummy" then return end
    l.affine = nil
  elseif d.state == 1 then
    if self.main.timer >= 96 then
      t.alive = false
      if self.main.timer < 0x4000 then self.main.timer = self.main.timer + 1 end
    end
    return
  end
  d.state = d.state + 1
  if self.main.timer < 0x4000 then self.main.timer = self.main.timer + 1 end
end

function F.MainSpeech(self, m, inp)
  if self:printersActive(inp) then return end
  self:print("gText_Birch_MainSpeech")
  m.func = "AndYouAre"
end

function F.AndYouAre(self, m, inp)
  if self:printersActive(inp) then return end
  self.startedBallTask = false
  self:print("gText_Birch_AndYouAre")
  m.func = "StartBirchLotadPlatformFade"
end

function F.StartBirchLotadPlatformFade(self, m, inp)
  if self:printersActive(inp) then return end
  self.sprites.birch.blend = true
  self.sprites.lotad.blend = true
  self:startFadeOutTarget1InTarget2(2)
  self:startFadePlatformIn(1)
  m.timer = 64
  m.func = "SlidePlatformAway"
end

function F.SlidePlatformAway(self, m)
  if m.bg1hofs ~= -60 then
    m.bg1hofs = m.bg1hofs - 2
  else
    m.func = "StartPlayerFadeIn"
  end
end

function F.StartPlayerFadeIn(self, m)
  if not m.doneFading then return end
  self.sprites.birch.invisible = true
  self.sprites.lotad.invisible = true
  if m.timer > 0 then
    m.timer = m.timer - 1
    return
  end
  local s = self.sprites.brendan
  s.x, s.y, s.invisible, s.blend = 180, 60, false, true
  m.player = "brendan"
  m.gender = MALE
  self:startFadeInTarget1OutTarget2(2)
  self:startFadePlatformOut(1)
  self:event("player_fade_in")
  m.func = "WaitForPlayerFadeIn"
end

function F.WaitForPlayerFadeIn(self, m)
  if not m.doneFading then return end
  self.sprites[m.player].blend = false
  m.func = "BoyOrGirl"
end

function F.BoyOrGirl(self, m)
  self:clearWindow()
  self:print("gText_Birch_BoyOrGirl")
  m.func = "WaitToShowGenderMenu"
end

function F.WaitToShowGenderMenu(self, m, inp)
  if self:printersActive(inp) then return end
  self.genderMenu = { cursor = 0 }
  self:event("gender_menu")
  m.func = "ChooseGender"
end

-- pokeemerald/src/menu.c:1013
local function genderMenuInput(menu, inp)
  if inp.new.a then
    Kit.playSe("SE_SELECT")
    return menu.cursor
  elseif inp.new.b then
    return -1
  elseif inp.new.up and menu.cursor > 0 then
    menu.cursor = menu.cursor - 1
    Kit.playSe("SE_SELECT")
  elseif inp.new.down and menu.cursor < 1 then
    menu.cursor = menu.cursor + 1
    Kit.playSe("SE_SELECT")
  end
  return -2
end

function F.ChooseGender(self, m, inp)
  local g = genderMenuInput(self.genderMenu, inp)
  if g == MALE or g == FEMALE then
    Kit.playSe("SE_SELECT")
    self.gender = g
    self.genderMenu = nil
    self:event(g == MALE and "chose_boy" or "chose_girl")
    m.func = "WhatsYourName"
    return
  end
  local g2 = self.genderMenu.cursor
  if g2 ~= m.gender then
    m.gender = g2
    self.sprites[m.player].blend = true
    self:startFadeOutTarget1InTarget2(0)
    self:event("gender_slide")
    m.func = "SlideOutOldGenderSprite"
  end
end

function F.SlideOutOldGenderSprite(self, m)
  local s = self.sprites[m.player]
  if not m.doneFading then
    s.x = s.x + 4
    return
  end
  s.invisible = true
  local key = m.gender ~= MALE and "may" or "brendan"
  local n = self.sprites[key]
  n.x, n.y, n.invisible, n.blend = 240, 60, false, true
  m.player = key
  self:startFadeInTarget1OutTarget2(0)
  m.func = "SlideInNewGenderSprite"
end

function F.SlideInNewGenderSprite(self, m)
  local s = self.sprites[m.player]
  if s.x > 180 then
    s.x = s.x - 4
    return
  end
  s.x = 180
  if m.doneFading then
    s.blend = false
    m.func = "ChooseGender"
  end
end

function F.WhatsYourName(self, m)
  self:clearWindow()
  self:print("gText_Birch_WhatsYourName")
  m.func = "WaitForWhatsYourNameToPrint"
end

function F.WaitForWhatsYourNameToPrint(self, m, inp)
  if not self:printersActive(inp) then m.func = "WaitPressBeforeNameChoice" end
end

function F.WaitPressBeforeNameChoice(self, m, inp)
  if inp.new.a or inp.new.b then
    self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    m.func = "StartNamingScreen"
  end
end

function F.StartNamingScreen(self, m)
  if self.pal:fadeActive() then return end
  -- pokeemerald/src/main_menu.c:2102
  local names = self.man.presetNames[self.gender == MALE and "male" or "female"]
  local count = #names
  local other = #self.man.presetNames[self.gender == MALE and "female" or "male"]
  if other < count then count = other end
  self.playerName = names[(Rng.Random() % count) + 1]
  self.showDialogue = false
  self.printer = nil
  self:enterNaming()
  m.func = "Naming"
end

function F.Naming() end

function Birch:enterNaming()
  -- pokeemerald/src/naming_screen.c:395
  local me = self
  -- pokeemerald/src/naming_screen.c:418
  self.naming = { stage = "setup", timer = 21, pal = Pal.new(), frames = 0 }
  self.naming.pal:blend(Pal.ALL, 16, Pal.BLACK)
  self:event("naming_open")
  Naming.open({
    template = "PLAYER",
    gender = self.gender,
    seed = self.playerName,
    hold = true,
    onDone = function(name)
      if name and name ~= "" then me.playerName = name end
      me.naming.stage = "fade_out"
      me.naming.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    end,
  })
end

function Birch:namingFrame(inp)
  local n = self.naming
  n.frames = n.frames + 1
  if n.stage == "setup" then
    n.timer = n.timer - 1
    if n.timer <= 0 then
      n.stage = "fade_in"
      n.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
    end
  elseif n.stage == "fade_in" then
    n.pal:updateFade()
    if not n.pal:fadeActive() then n.stage = "input" end
  elseif n.stage == "input" then
    self.namingInput = {
      wasPressed = function(_, k) return inp.new[k] == true end,
      isDown = function(_, k) return inp.held[k] == true end,
    }
    Naming.handleInput(self.namingInput)
    Naming.update(1 / Kit.GBA_HZ)
  elseif n.stage == "fade_out" then
    n.pal:updateFade()
    if not n.pal:fadeActive() then
      -- pokeemerald/src/naming_screen.c:701
      local cycles = n.frames * 280896
      self.trainerIdLower = cycles % 65536
      Rng.SeedRng(self.trainerIdLower)
      Naming.dismiss()
      n.stage = "return_hold"
      n.timer = 7
    end
  elseif n.stage == "return_hold" then
    -- pokeemerald/src/main_menu.c:1788
    n.timer = n.timer - 1
    if n.timer <= 0 then
      self.naming = nil
      self:returnFromNaming()
    end
  end
end

-- pokeemerald/src/main_menu.c:1788
function Birch:returnFromNaming()
  self.pal = Pal.new()
  self.pal:blend(Pal.ALL, 16, Pal.BLACK)
  self.gradState = 1
  self.bgVisible = true
  self.tasks = {}
  local m = self.main
  m.timer = 5
  m.bg1hofs = -60
  for _, k in ipairs({ "birch", "lotad", "brendan", "may" }) do
    local s = self.sprites[k]
    s.invisible, s.blend, s.callback = true, false, "null"
  end
  m.gender = self.gender
  m.player = self.gender ~= MALE and "may" or "brendan"
  local p = self.sprites[m.player]
  p.x, p.y, p.invisible = 180, 60, false
  self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  self.showDialogue = false
  self.bld = { eva = 16, evb = 0 }
  self:event("naming_return")
  m.func = "ReturnFromNamingScreenShowTextbox"
end

function F.ReturnFromNamingScreenShowTextbox(self, m)
  local t = m.timer
  m.timer = m.timer - 1
  if t <= 0 then
    self.showDialogue = true
    m.func = "SoItsPlayerName"
  end
end

function F.SoItsPlayerName(self, m)
  self:clearWindow()
  self:print("gText_Birch_SoItsPlayer")
  m.func = "CreateNameYesNo"
end

function F.CreateNameYesNo(self, m, inp)
  if self:printersActive(inp) then return end
  self.yesNo = Kit.yesNo(3, 2, { frameType = self.frameType })
  m.func = "ProcessNameYesNoMenu"
end

function F.ProcessNameYesNoMenu(self, m, inp)
  local r = self.yesNo:input(inp)
  if r == 0 then
    Kit.playSe("SE_SELECT")
    self.yesNo = nil
    self.sprites[m.player].blend = true
    self:startFadeOutTarget1InTarget2(2)
    self:startFadePlatformIn(1)
    self:event("name_confirmed")
    m.func = "SlidePlatformAway2"
  elseif r == 1 or r == -1 then
    Kit.playSe("SE_SELECT")
    self.yesNo = nil
    m.func = "BoyOrGirl"
  end
end

function F.SlidePlatformAway2(self, m)
  if m.bg1hofs ~= 0 then
    m.bg1hofs = m.bg1hofs + 2
  else
    m.func = "ReshowBirchLotad"
  end
end

function F.ReshowBirchLotad(self, m)
  if not m.doneFading then return end
  self.sprites.brendan.invisible = true
  self.sprites.may.invisible = true
  local b, l = self.sprites.birch, self.sprites.lotad
  b.x, b.y, b.invisible, b.blend = 136, 60, false, true
  l.x, l.y, l.invisible, l.blend = 100, 75, false, true
  l.frame = 0
  self:startFadeInTarget1OutTarget2(2)
  self:startFadePlatformOut(1)
  self:clearWindow()
  self:print("gText_Birch_YourePlayer")
  m.func = "WaitForSpriteFadeInAndTextPrinter"
end

function F.WaitForSpriteFadeInAndTextPrinter(self, m, inp)
  if not m.doneFading then return end
  self.sprites.birch.blend = false
  self.sprites.lotad.blend = false
  if self:printersActive(inp) then return end
  self.sprites.birch.blend = true
  self.sprites.lotad.blend = true
  self:startFadeOutTarget1InTarget2(2)
  self:startFadePlatformIn(1)
  m.timer = 64
  m.func = "AreYouReady"
end

function F.AreYouReady(self, m)
  if not m.doneFading then return end
  self.sprites.birch.invisible = true
  self.sprites.lotad.invisible = true
  if m.timer > 0 then
    m.timer = m.timer - 1
    return
  end
  local key = self.gender ~= MALE and "may" or "brendan"
  local s = self.sprites[key]
  s.x, s.y, s.invisible, s.blend = 120, 60, false, true
  m.player = key
  self:startFadeInTarget1OutTarget2(2)
  self:startFadePlatformOut(1)
  self:print("gText_Birch_AreYouReady")
  m.func = "ShrinkPlayer"
end

function F.ShrinkPlayer(self, m, inp)
  if not m.doneFading then return end
  local s = self.sprites[m.player]
  s.blend = false
  if self:printersActive(inp) then return end
  startAffine(s, AFFINE_SHRINK)
  s.callback = "shrinkDown"
  s.fracY = 0
  self.pal:beginFade(Pal.BG, 0, 0, 16, Pal.BLACK)
  Audio.fadeOutBgm(4)
  self:event("shrink_start")
  m.func = "WaitForPlayerShrink"
end

function F.WaitForPlayerShrink(self, m)
  if self.sprites[m.player].affineEnded then
    self:event("shrink_end")
    m.func = "FadePlayerToWhite"
  end
end

function F.FadePlayerToWhite(self, m)
  if self.pal:fadeActive() then return end
  self.sprites[m.player].callback = "null"
  self.bgVisible = false
  self.showDialogue = false
  self.printer = nil
  self.pal:beginFade(Pal.OBJ, 0, 0, 16, Pal.WHITE)
  self:event("white_fade_start")
  m.func = "Cleanup"
end

function F.Cleanup(self, m)
  if self.pal:fadeActive() then return end
  self:event("cleanup")
  self.result = {
    action = "new_game",
    name = self.playerName,
    gender = self.gender,
    fieldCallback = "truck",
    trainerIdLower = self.trainerIdLower,
  }
  m.func = "Done"
end

function F.Done() end

Birch.TASKS = F

function Birch:frame(inp)
  self.frames = self.frames + 1
  if self.naming then
    self:namingFrame(inp)
    return nil
  end
  local m = self.main
  local fn = F[m.func]
  fn(self, m, inp)
  local i = 1
  while i <= #self.tasks do
    local t = self.tasks[i]
    if t.alive then t.fn(self, t) end
    i = i + 1
  end
  local keep = {}
  for _, t in ipairs(self.tasks) do if t.alive then keep[#keep + 1] = t end end
  self.tasks = keep
  self:spriteCallbacks()
  self.pal:updateFade()
  return self.result
end

function Birch:update(input, dt)
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end

function Birch:destroy()
  if Naming.isOpen() then Naming.dismiss() end
  self.naming = nil
end


local quadCache = setmetatable({}, { __mode = "k" })

local function frameQuad(img, frame, w, h)
  local per = quadCache[img]
  if not per then
    per = {}
    quadCache[img] = per
  end
  local key = frame .. ":" .. w .. ":" .. h
  local q = per[key]
  if not q then
    q = love.graphics.newQuad(0, frame * h, w, h, img:getDimensions())
    per[key] = q
  end
  return q
end

local function ballQuad(img, frame)
  local per = quadCache[img]
  if not per then
    per = {}
    quadCache[img] = per
  end
  local q = per[frame]
  if not q then
    q = love.graphics.newQuad(0, frame * 16, 16, 16, img:getDimensions())
    per[frame] = q
  end
  return q
end

function Birch:drawSprite(s, w, h, objY, objColor)
  if s.invisible or not s.img then return end
  local alpha = s.blend and (self.bld.eva / 16) or 1
  local q = frameQuad(s.img, s.frame or 0, w, h)
  local sx, sy = (s.scale or 1) * (s.sx or 1), (s.scale or 1) * (s.sy or 1)
  local cx, cy = s.x + s.x2, s.y + s.y2
  local amount = objY and objY > 0 and objY / 16 or nil
  local target = objColor and { objColor[1] / 31, objColor[2] / 31, objColor[3] / 31 } or nil
  if s == self.sprites.lotad and self.monBlend > 0 and not amount then
    amount, target = self.monBlend / 16, self:ballColor()
  end
  Kit.drawTinted(s.img, q, math.floor(cx), math.floor(cy), amount, target, alpha, sx, sy, w / 2, h / 2)
end

function Birch:draw()
  if self.naming then
    love.graphics.clear(0, 0, 0, 1)
    if self.naming.stage == "return_hold" then return end
    if Naming.isOpen() then Naming.draw() end
    Kit.drawFade(self.naming.pal, 0)
    return
  end
  love.graphics.clear(0, 0, 0, 1)
  local layer = self.man.layers.bg
  if self.bgVisible then
    local img = Kit.image(layer.variants[tostring(self.gradState)])
    if img then
      local x = (-self.main.bg1hofs) % 256
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, x, 0)
      love.graphics.draw(img, x - 256, 0)
    end
  end
  if self.showDialogue then
    local w = WIN_TEXT
    Kit.birchDialogueFrame(w.left, w.top, w.width, w.height)
    if self.printer then self.printer:draw(w.left * 8, w.top * 8 + 1, { colors = Kit.messageColors(), clip = { w.left * 8, w.top * 8, w.width * 8, w.height * 8 } }) end
  end
  if self.genderMenu then
    local w = WIN_GENDER
    local colors = Kit.messageColors()
    Kit.userFrame(w.left, w.top, w.width, w.height, self.frameType, colors.bg)
    FrlgFont.draw(RomText.plain("gText_BirchBoy"), w.left * 8 + 8, w.top * 8 + 1, { colors = colors })
    FrlgFont.draw(RomText.plain("gText_BirchGirl"), w.left * 8 + 8, w.top * 8 + 17, { colors = colors })
    FrlgFont.draw(RomText.plain("gText_SelectorArrow3"), w.left * 8, w.top * 8 + 1 + self.genderMenu.cursor * 16,
      { colors = colors })
  end
  if self.yesNo then self.yesNo:draw() end
  Kit.drawFade(self.pal, 0)
  local objY, objColor = Kit.fadeY(self.pal, 16)
  for _, k in ipairs({ "birch", "lotad", "brendan", "may" }) do
    self:drawSprite(self.sprites[k], 64, 64, objY, objColor)
  end
  if self.ball and not self.ball.invisible and self.ball.img then
    local b = self.ball
    Kit.drawTinted(b.img, ballQuad(b.img, b.frame or 0), b.x - 8, b.y - 8, objY > 0 and objY / 16 or nil,
      objColor and { objColor[1] / 31, objColor[2] / 31, objColor[3] / 31 } or nil)
  end
  local ok, BallOpen = pcall(require, "src.core.game3.battle.ball_open")
  if ok and BallOpen and BallOpen.draw then pcall(BallOpen.draw) end
end

return Birch
