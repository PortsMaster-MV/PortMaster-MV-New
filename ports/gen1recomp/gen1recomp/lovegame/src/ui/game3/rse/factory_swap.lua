local Stack = require("src.ui.game3.stack")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")
local PalFade = require("src.core.game3.pal_fade")
local Select = require("src.ui.game3.rse.factory_select")

local Common = Select.Common

local Swap = {}

Swap.ID = "rse_factory_swap"
Swap.open = false

local FRONTIER_PARTY_SIZE = 3
-- pokeemerald/src/battle_factory_screen.c:1038
local ACTION = { MON = 1, PKMN_FOR_SWAP = 2, CANCEL = 3 }
Swap.ACTION = ACTION
-- pokeemerald/src/battle_factory_screen.c:1042
local PLAYER_ACTIONS = { ACTION.MON, ACTION.MON, ACTION.MON, ACTION.CANCEL }
local ENEMY_ACTIONS = { ACTION.MON, ACTION.MON, ACTION.MON, ACTION.PKMN_FOR_SWAP, ACTION.CANCEL }

local st = {}
Swap._st = st

local function session()
  if st.session then return st.session end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function ballX(i) return (48 * (i - 1)) + 72 end

-- pokeemerald/src/battle_factory_screen.c:3945
local function initActions(enemy)
  st.inEnemyScreen = enemy
  st.cursor = 0
  st.actions = enemy and ENEMY_ACTIONS or PLAYER_ACTIONS
end

local function curParty() return st.inEnemyScreen and st.enemy or st.party end
local function curMon()
  if st.cursor >= FRONTIER_PARTY_SIZE then return nil end
  return curParty()[st.cursor + 1]
end

-- pokeemerald/src/battle_factory_screen.c:3267
function Swap.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  st.onDone = opts.onDone
  st.sameSpecies = opts.sameSpecies
  st.party = opts.party or {}
  st.enemy = opts.enemy or {}
  st.cache = {}
  st.balls = {}
  for i = 1, FRONTIER_PARTY_SIZE do
    st.balls[i] = Common.newBall(ballX(i), 64)
    st.balls[i].selected = true
    st.balls[i].pal = "ballSelected"
  end
  initActions(false)
  st.menuCursor, st.yesNoCursor = 0, 0
  st.monSwapped = false
  st.playerMonId = 0
  st.pkmnButtonX, st.cancelButtonX = 240, 192
  st.info = RomText.plain("gText_SelectPkmnToSwap")
  st.showActions = true
  st.fade = { coeff = 0, state = "init", active = false }
  st.pal = Kit.fade()
  st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.BLACK)
  st.phase = "fadein"
  Swap.open = true
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.clear then Fade.clear() end
  Stack.push(Swap.ID, Swap, { hideBelow = true, fullscreen = true })
  return true
end

function Swap.isOpen() return Swap.open end

function Swap.handleInput(input)
  if not Swap.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

local function animating() return st.picAnim ~= nil and not st.picAnim.finished end

local function openPic(onDone)
  st.picAnim = Common.newPicAnim("open", { 120 }, { 11 }, 88, 152, function()
    st.picShown = { xs = { 120 }, tiles = { 11 }, winLeft = 88, winRight = 152 }
    local m = curMon()
    st.pics = m and { { mon = m, x = 88, y = 32 } } or nil
    if onDone then onDone() end
  end)
end

local function closePic(onDone)
  st.pics, st.picShown = nil, nil
  st.picAnim = Common.startClose({ 120 }, { 11 }, 88, 152, function()
    st.picAnim = nil
    if onDone then onDone() end
  end)
end

-- pokeemerald/src/battle_factory_screen.c:2880
local function slideButtons(on, onDone)
  st.slide = { on = on, delay = st.inEnemyScreen and (on and 10 or 5) or 0, pkmnDone = not st.inEnemyScreen,
    cancelDone = false, cancelStarted = not st.inEnemyScreen, onDone = onDone }
end

local function stepSlide()
  local s = st.slide
  if not s then return end
  local dx = s.on and -6 or 6
  if not s.pkmnDone then
    local target = s.on and 160 or 240
    local nx = st.pkmnButtonX + dx
    if (s.on and nx > target) or (not s.on and nx < target) then st.pkmnButtonX = nx
    else st.pkmnButtonX = target s.pkmnDone = true end
  end
  if not s.cancelStarted then
    if s.delay == 0 then s.cancelStarted = true else s.delay = s.delay - 1 end
  elseif not s.cancelDone then
    local target = s.on and 192 or 240
    local nx = st.cancelButtonX + dx
    if (s.on and nx > target) or (not s.on and nx < target) then st.cancelButtonX = nx
    else st.cancelButtonX = target s.cancelDone = true end
  end
  if s.pkmnDone and s.cancelDone then
    st.slide = nil
    if s.onDone then s.onDone() end
  end
end

-- pokeemerald/src/battle_factory_screen.c:3001
local function transitionOut(nextFn)
  st.showActions = false
  st.menuShown = false
  st.phase = "transition"
  slideButtons(false, nextFn)
end

-- pokeemerald/src/battle_factory_screen.c:3084
local function transitionIn(nextFn)
  st.phase = "transition"
  local function go()
    slideButtons(true, function()
      st.showActions = true
      st.info = RomText.plain(st.inEnemyScreen and "gText_SelectPkmnToAccept" or "gText_SelectPkmnToSwap")
      st.fade.active = true
      if nextFn then nextFn() end
    end)
  end
  if animating() then st.afterPic = go else go() end
end

local function toChoose() st.phase = "choose" end

-- pokeemerald/src/battle_factory_screen.c:2409
local function exit()
  st.phase = "exit"
  st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
end

-- pokeemerald/src/battle_factory_screen.c:2540
local function askQuit()
  st.info = RomText.plain("gText_QuitSwapping")
  st.monSwapped = false
  st.yesNoCursor = 0
  st.yesNoShown = true
  st.onYesNo = function(yes)
    if yes then exit() else transitionIn(toChoose) end
  end
  st.phase = "yesno"
end

-- pokeemerald/src/battle_factory_screen.c:2571
local function askAccept()
  openPic()
  st.info = RomText.plain("gText_AcceptThisPkmn")
  st.monSwapped = true
  st.onYesNo = function(yes)
    closePic()
    if yes then exit() else transitionIn(toChoose) end
  end
  st.phase = "yesno_wait"
end

-- pokeemerald/src/battle_factory_screen.c:3196
local function switchPartyScreen()
  st.phase = "switch"
  st.fade.active = false
  st.cycle = { cycled = { false, false, false } }
end

-- pokeemerald/src/battle_factory_screen.c:2787
local function stepCycle()
  local c = st.cycle
  local finished = false
  local lastX = 0
  for i = FRONTIER_PARTY_SIZE, 1, -1 do
    local b = st.balls[i]
    if i ~= FRONTIER_PARTY_SIZE then
      local posX = (lastX - b.x) % 256
      if posX == 16 or c.cycled[i + 1] then
        lastX = b.x
        b.x = b.x + 10
      elseif posX > 16 then
        b.x = st.balls[i + 1].x - 48
      end
    else
      lastX = b.x
      b.x = b.x + 10
    end
    if c.cycled[i] then
      local dest = ((i - 1) * 48) + 72
      if b.x >= dest then
        b.x = dest
        finished = true
      else
        finished = false
      end
    else
      finished = false
    end
    if b.x - 16 > 240 then
      lastX = b.x
      b.x = -16
      b.pal = st.inEnemyScreen and "ballSelected" or "ballGray"
      c.cycled[i] = true
    end
  end
  if finished then
    st.cycle = nil
    initActions(not st.inEnemyScreen)
    if not st.inEnemyScreen then st.pkmnButtonX = 240 end
    st.fade.coeff = 6
    transitionIn(toChoose)
  end
end

-- pokeemerald/src/battle_factory_screen.c:4023
local function runAction()
  local act = st.actions[st.cursor + 1]
  if act == ACTION.CANCEL then
    transitionOut(askQuit)
  elseif act == ACTION.PKMN_FOR_SWAP then
    transitionOut(switchPartyScreen)
  elseif not st.inEnemyScreen then
    transitionOut(function()
      openPic(function() end)
      st.phase = "menu_open"
    end)
  elseif st.sameSpecies and st.sameSpecies(st.cursor + 1, st.playerMonId + 1) then
    openPic()
    st.phase = "same_species"
  else
    transitionOut(askAccept)
  end
end

local function stepChoose(inp)
  local n = #st.actions
  if inp.new.a then
    Common.se("SE_SELECT")
    st.fade.active = false
    runAction()
  elseif inp.new.b then
    Common.se("SE_SELECT")
    st.fade.active = false
    transitionOut(askQuit)
  elseif inp.rep.left then
    Common.se("SE_SELECT")
    st.cursor = st.cursor == 0 and n - 1 or st.cursor - 1
  elseif inp.rep.right then
    Common.se("SE_SELECT")
    st.cursor = (st.cursor + 1 == n) and 0 or st.cursor + 1
  elseif inp.rep.down then
    Common.se("SE_SELECT")
    if st.cursor < FRONTIER_PARTY_SIZE then st.cursor = FRONTIER_PARTY_SIZE
    elseif st.cursor + 1 ~= n then st.cursor = st.cursor + 1
    else st.cursor = 0 end
  elseif inp.rep.up then
    Common.se("SE_SELECT")
    if st.cursor < FRONTIER_PARTY_SIZE then st.cursor = n - 1
    elseif st.cursor ~= 0 then st.cursor = st.cursor - 1
    else st.cursor = n - 1 end
  end
end

local function openSummary()
  st.phase = "summary_fade"
  st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
end

-- pokeemerald/src/battle_factory_screen.c:2378
local function showSummary()
  st.phase = "summary"
  st.pics, st.picShown, st.picAnim = nil, nil, nil
  local SummaryMenu = require("src.ui.game3.summary_menu")
  SummaryMenu.openMenu(st.party, st.cursor + 1, {
    session = session(),
    context = "factory",
    onClose = function()
      st.cursor = (SummaryMenu._cursor or (st.cursor + 1)) - 1
      Stack.push(Swap.ID, Swap, { hideBelow = true, fullscreen = true })
      st.pal = Kit.fade()
      st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.BLACK)
      st.picShown = { xs = { 120 }, tiles = { 11 }, winLeft = 88, winRight = 152 }
      st.pics = { { mon = curMon(), x = 88, y = 32 } }
      st.menuShown = true
      st.phase = "menu_reinit"
    end,
  })
end

-- pokeemerald/src/battle_factory_screen.c:2585
local function stepMenu(inp)
  if animating() then return end
  if inp.new.a then
    Common.se("SE_SELECT")
    if st.menuCursor == 0 then
      openSummary()
    elseif st.menuCursor == 1 then
      closePic()
      st.playerMonId = st.cursor
      st.menuShown = false
      switchPartyScreen()
    else
      closePic()
      st.menuShown = false
      transitionIn(toChoose)
    end
  elseif inp.new.b then
    Common.se("SE_SELECT")
    closePic()
    st.menuShown = false
    transitionIn(toChoose)
  elseif inp.rep.up then
    Common.se("SE_SELECT")
    st.menuCursor = st.menuCursor == 0 and 2 or st.menuCursor - 1
  elseif inp.rep.down then
    Common.se("SE_SELECT")
    st.menuCursor = st.menuCursor == 2 and 0 or st.menuCursor + 1
  end
end

-- pokeemerald/src/battle_factory_screen.c:2465
local function stepYesNo(inp)
  if animating() then return end
  local function answer(yes)
    st.yesNoShown = false
    local cb = st.onYesNo
    st.onYesNo = nil
    if cb then cb(yes) end
  end
  if inp.new.a then
    Common.se("SE_SELECT")
    answer(st.yesNoCursor == 0)
  elseif inp.new.b then
    Common.se("SE_SELECT")
    answer(false)
  elseif inp.rep.up or inp.rep.down then
    Common.se("SE_SELECT")
    st.yesNoCursor = 1 - st.yesNoCursor
  end
end

function Swap.update()
  if not Swap.open then return end
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  for _, b in ipairs(st.balls) do
    b.selected = true
    Common.stepBall(b)
  end
  Common.stepPicAnim(st.picAnim)
  if st.picAnim and st.picAnim.finished and st.picAnim.kind == "open" then st.picAnim = nil end
  if st.afterPic and not animating() then
    local f = st.afterPic
    st.afterPic = nil
    f()
  end
  stepSlide()
  local ph = st.phase
  if ph == "fadein" then
    if not st.pal:updateFade() then
      st.fade.active = true
      st.phase = "choose"
    end
  elseif ph == "choose" then
    stepChoose(inp)
  elseif ph == "menu_open" then
    if not animating() then
      st.menuCursor = 0
      st.menuShown = true
      st.phase = "menu"
    end
  elseif ph == "menu" then
    stepMenu(inp)
  elseif ph == "menu_reinit" then
    if not st.pal:updateFade() then st.phase = "menu" end
  elseif ph == "yesno_wait" then
    if not animating() then
      st.yesNoCursor = 0
      st.yesNoShown = true
      st.phase = "yesno"
    end
  elseif ph == "yesno" then
    st.yesNoShown = true
    stepYesNo(inp)
  elseif ph == "same_species" then
    -- pokeemerald/src/battle_factory_screen.c:4120
    if not animating() then
      st.info = RomText.plain("gText_SamePkmnInPartyAlready")
      st.monSwapped = false
      if inp.new.a or inp.new.b then
        Common.se("SE_SELECT")
        closePic(function()
          st.info = RomText.plain("gText_SelectPkmnToAccept")
          st.fade.active = true
          st.phase = "choose"
        end)
        st.phase = "same_species_close"
      end
    end
  elseif ph == "switch" then
    if st.cycle then stepCycle() end
  elseif ph == "summary_fade" then
    if not st.pal:updateFade() then showSummary() end
  elseif ph == "exit" then
    if not st.pal:updateFade() then
      Swap.open = false
      Stack.pop(Swap.ID)
      local cb = st.onDone
      st.onDone = nil
      if cb then
        cb({ swapped = st.monSwapped == true, playerMonId = st.playerMonId + 1, enemyMonId = st.cursor + 1 })
      end
    end
  end
  if st.fade.active then
    st.fade.tick = (st.fade.tick or 0) + 1
    if st.fade.tick > 6 then
      st.fade.tick = 0
      st.fade.coeff = (st.fade.coeff + 1) % 7
    end
  end
end

-- pokeemerald/src/battle_factory_screen.c:3845
local function drawActionString(s, y)
  Common.text(s, 21 * 8 + Common.rightAlign(s, 70, "small"), 14 * 8 + y, "menu", nil, "small")
end

function Swap.draw()
  if not Swap.open then return end
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(Common.menuImage(st.cache), 0, 0)
  for _, b in ipairs(st.balls) do Common.drawBall(b, b.pal) end
  local onBall = st.cursor < FRONTIER_PARTY_SIZE
  if onBall and st.phase ~= "switch" and st.phase ~= "summary" then Common.drawArrow(st.balls[st.cursor + 1].x, 88) end
  local act = st.actions[st.cursor + 1]
  love.graphics.setColor(1, 1, 1, 1)
  if st.inEnemyScreen or st.pkmnButtonX < 240 then
    local x = st.pkmnButtonX
    love.graphics.draw(Common.sprite("actionBoxLeft", 0, 16, 16, "interface"), x, 120)
    love.graphics.draw(Common.sprite("actionBoxRight", 0, 32, 16, "interface"), x + 16, 120)
    love.graphics.draw(Common.sprite("actionBoxRight", 0, 32, 16, "interface"), x + 48, 120)
    if not onBall and act == ACTION.PKMN_FOR_SWAP and st.phase == "choose" then
      love.graphics.draw(Common.sprite("actionHighlightLeft", 0, 16, 16, "interface"), x, 120)
      love.graphics.draw(Common.sprite("actionHighlightMiddle", 0, 32, 16, "interface"), x + 16, 120)
      love.graphics.draw(Common.sprite("actionHighlightRight", 0, 32, 16, "interface"), x + 48, 120)
    end
  end
  local cx = st.cancelButtonX
  love.graphics.draw(Common.sprite("actionBoxLeft", 0, 16, 16, "interface"), cx, 144)
  love.graphics.draw(Common.sprite("actionBoxRight", 0, 32, 16, "interface"), cx + 16, 144)
  if not onBall and act == ACTION.CANCEL and st.phase == "choose" then
    love.graphics.draw(Common.sprite("actionHighlightLeft", 0, 16, 16, "interface"), cx, 144)
    love.graphics.draw(Common.sprite("actionHighlightRight", 0, 32, 16, "interface"), cx + 16, 144)
  end
  Common.drawPicBg(st.cache, st.picAnim, st.picShown)
  if st.menuShown then Common.drawMenuHighlight(176, 208, st.menuCursor * 16 + 112) end
  if st.yesNoShown then Common.drawMenuHighlight(176, 208, st.yesNoCursor * 16 + 112) end
  Common.text(RomText.plain("gText_PkmnSwap"), 2, 16 + 1)
  local mon = curMon()
  if mon and st.phase ~= "switch" then
    local name = Common.speciesName(mon.species)
    Common.text(name, 19 * 8 + Common.rightAlign(name, 86), 16 + 1, "species", st.fade.coeff)
    local cat = Common.categoryText(mon.species)
    Common.text(cat, 15 * 8 + Common.rightAlign(cat, 118), 1)
  end
  Common.text(st.info, 2, 15 * 8 + 5)
  if st.showActions and not st.menuShown and not st.yesNoShown then
    if st.inEnemyScreen then drawActionString(RomText.plain("gText_PkmnForSwap"), 8) end
    drawActionString(RomText.plain("gText_Cancel3"), 32)
  end
  if st.menuShown then
    local labels = { RomText.plain("gText_Summary2"), RomText.plain("gText_Swap"), RomText.plain("gText_Rechoose") }
    for i = 1, 3 do Common.text(labels[i], 21 * 8 + 15, 14 * 8 + 1 + (i - 1) * 16, "menu") end
  end
  if st.yesNoShown then
    Common.text(RomText.plain("gText_Yes3"), 22 * 8 + 7, 14 * 8 + 1, "menu")
    Common.text(RomText.plain("gText_No3"), 22 * 8 + 7, 14 * 8 + 17, "menu")
  end
  for _, p in ipairs(st.pics or {}) do
    local img = p.mon and Common.monPic(p.mon)
    if img then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, p.x, p.y)
    end
  end
  if st.pal then Kit.drawFade(st.pal, 0, 240, 160) end
end

function Swap.reset()
  Swap.open = false
  Stack.pop(Swap.ID)
  for k in pairs(st) do st[k] = nil end
end

return Swap
