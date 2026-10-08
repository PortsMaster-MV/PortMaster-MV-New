local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Strings = require("src.core.Strings")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local PalFade = require("src.core.game3.pal_fade")

local Select = {}

Select.ID = "rse_factory_select"
Select.open = false

-- pokeemerald/src/battle_factory_screen.c:45
local SELECTABLE_MONS_COUNT = 6
local FRONTIER_PARTY_SIZE = 3

local Common = {}
Select.Common = Common

function Common.gfx() return Gfx.of("rse/factory") end
function Common.man() return Common.gfx():manifest() end

function Common.se(name) pcall(Kit.playSe, name) end

-- pokeemerald/src/battle_factory_screen.c:1238
function Common.bgPalette()
  local p = Common.man().palettes
  local pal = {}
  for i = 1, #p.menu do pal[i - 1] = p.menu[i] end
  for i = 1, 16 do pal[32 + i - 1] = p.monPicBg[i] end
  return pal
end

function Common.menuImage(cache)
  if cache.menu then return cache.menu end
  local g = Common.gfx()
  cache.menu = g:renderMap(g:map("menu"), "menu", Common.bgPalette(), { width = 32, rows = 20 })
  return cache.menu
end

-- pokeemerald/src/battle_factory_screen.c:1254
function Common.monPicBgImage(cache, xs)
  local key = "picbg:" .. table.concat(xs, ",")
  if cache[key] then return cache[key] end
  local g = Common.gfx()
  local src = g:map("monPicBg")
  local entries = { n = 32 * 20 }
  for i = 0, 32 * 20 - 1 do entries[i] = 0 end
  for _, tx in ipairs(xs) do
    for y = 0, 7 do
      for x = 0, 7 do entries[(4 + y) * 32 + tx + x] = src[y * 8 + x] or 0 end
    end
  end
  local pal = Common.bgPalette()
  for i = 0, 15 do pal[i] = pal[32 + i] end
  local img = g:renderMap(entries, "monPicBg", pal, { width = 32, rows = 20 })
  cache[key] = img
  return img
end

function Common.sprite(key, tile, w, h, palName, opts)
  return Common.gfx():sprite(key, tile, w, h, Common.man().palettes[palName], opts)
end

-- pokeemerald/src/battle_factory_screen.c:492
local BALL_STILL = { { 0, 30 } }
local BALL_MOVING = {
  { 16, 4 }, { 0, 4 }, { 32, 4 }, { 0, 4 }, { 16, 4 }, { 0, 4 }, { 32, 4 }, { 0, 4 }, { 0, 32 }, { 16, 8 }, { 0, 8 },
  { 32, 8 }, { 0, 8 }, { 16, 8 }, { 0, 8 }, { 32, 8 }, { 0, 8 },
}

function Common.newBall(x, y)
  return { x = x, y = y, anim = 0, frame = 1, timer = BALL_STILL[1][2], ended = false, wait = 0, selected = false }
end

local function startBallAnim(b, anim)
  b.anim, b.frame, b.ended = anim, 1, false
  local seq = anim == 1 and BALL_MOVING or BALL_STILL
  b.timer = seq[1][2]
end

-- pokeemerald/src/battle_factory_screen.c:1059
function Common.stepBall(b)
  local Rng = require("src.core.game3.rng")
  if b.selected then
    if b.ended then
      if b.wait ~= 0 then
        b.wait = b.wait - 1
      elseif Rng.Random() % 5 == 0 then
        startBallAnim(b, 0)
        b.wait = 32
      else
        startBallAnim(b, 1)
      end
    elseif b.anim ~= 1 then
      startBallAnim(b, 1)
    end
  elseif b.anim ~= 0 then
    startBallAnim(b, 0)
  end
  local seq = b.anim == 1 and BALL_MOVING or BALL_STILL
  if not b.ended then
    b.timer = b.timer - 1
    if b.timer <= 0 then
      if b.frame < #seq then
        b.frame = b.frame + 1
        b.timer = seq[b.frame][2]
      else
        b.ended = true
      end
    end
  end
end

function Common.drawBall(b, palName)
  local seq = b.anim == 1 and BALL_MOVING or BALL_STILL
  local tile = seq[math.min(b.frame, #seq)][1]
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(Common.sprite("ball", tile, 32, 32, palName), b.x - 16, b.y - 16)
end

function Common.drawArrow(x, y)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(Common.sprite("arrow", 0, 16, 16, "interface"), x - 8, y - 8)
end

-- pokeemerald/src/battle_factory_screen.c:1832
function Common.drawMenuHighlight(x1, x2, y)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(Common.sprite("menuHighlightLeft", 0, 32, 16, "interface"), x1, y)
  love.graphics.draw(Common.sprite("menuHighlightRight", 0, 32, 16, "interface"), x2, y)
end

local function textColor(i)
  return Kit.color555(Common.man().palettes.text[i + 1])
end

-- pokeemerald/src/battle_factory_screen.c:409
function Common.colors(kind, fadeCoeff)
  local clear = { 0, 0, 0, 0 }
  if kind == "menu" then return { fg = textColor(2), shadow = clear, bg = clear } end
  if kind == "species" then
    local c = textColor(4)
    local k = 1 - (fadeCoeff or 0) / 16
    return { fg = { c[1] * k, c[2] * k, c[3] * k, 1 }, shadow = clear, bg = clear }
  end
  return { fg = textColor(2), shadow = textColor(3), bg = clear }
end

function Common.text(s, x, y, kind, fadeCoeff, font)
  FrlgFont.draw(s or "", x, y, { colors = Common.colors(kind, fadeCoeff), font = font })
end

function Common.rightAlign(s, width, font)
  return width - (FrlgFont.measure(s or "", { font = font }) or 0)
end

local entriesPack
-- pokeemerald/src/international_string_util.c:86
function Common.categoryText(species)
  if not entriesPack then
    entriesPack = Gfx.loadLua("data/generated/gba/pokemon/pokedex/entries.lua") or {}
  end
  local e = entriesPack[tonumber(species) or 0] or {}
  return Strings(e.category or "") .. " " .. RomText.plain("gText_Pokemon")
end

function Common.speciesName(species)
  return require("src.core.game3.pokemon").name(species)
end

function Common.monPic(mon)
  local Pokemon = require("src.core.game3.pokemon")
  local ok, pic = pcall(Pokemon.monFrontPic, mon)
  return ok and pic and pic.image or nil
end

-- pokeemerald/src/battle_factory_screen.c:536
local OPENING = { 5, 5, 16, 16, 32, 32, 64, 64, 128, 128, 256 }
local CLOSING = { 128, 128, 64, 64, 32, 32, 16, 16, 5, 5 }

-- pokeemerald/src/battle_factory_screen.c:4192
function Common.newPicAnim(kind, xs, tiles, winLeft, winRight, onDone)
  return { kind = kind, xs = xs, tiles = tiles, step = "sprite", t = 0, top = 64, bottom = 65, winLeft = winLeft,
    winRight = winRight, onDone = onDone }
end

function Common.stepPicAnim(a)
  if not a or a.finished then return end
  a.t = a.t + 1
  if a.kind == "open" then
    if a.step == "sprite" then
      if a.t >= #OPENING then a.step, a.t = "window", 0 end
    elseif a.step == "window" then
      if a.t > 1 then
        a.top, a.bottom = a.top - 4, a.bottom + 4
        if a.top <= 32 or a.bottom >= 96 then a.top, a.bottom = 32, 96 end
        if a.top == 32 then
          a.finished = true
          if a.onDone then a.onDone() end
        end
      end
    end
  else
    if a.step == "window" then
      a.top, a.bottom = a.top + 4, a.bottom - 4
      if a.top >= 64 or a.bottom <= 65 then a.top, a.bottom = 64, 65 end
      if a.top == 64 then a.step, a.t = "sprite", 0 end
    elseif a.step == "sprite" then
      if a.t >= #CLOSING then
        a.finished = true
        if a.onDone then a.onDone() end
      end
    end
  end
end

function Common.startClose(xs, tiles, winLeft, winRight, onDone)
  local a = Common.newPicAnim("close", xs, tiles, winLeft, winRight, onDone)
  a.step, a.top, a.bottom = "window", 32, 96
  return a
end

local function drawBlendedBg3(img)
  love.graphics.setColor(0, 0, 0, 12 / 16)
  love.graphics.draw(img, 0, 0)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(11 / 16, 11 / 16, 11 / 16, 1)
  love.graphics.draw(img, 0, 0)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
end

-- pokeemerald/src/battle_factory_screen.c:4192
function Common.drawPicBg(cache, a, open)
  local cur = a or open or {}
  local xs, tiles = cur.xs or {}, cur.tiles or {}
  if a and not a.finished and a.step == "sprite" then
    local seq = a.kind == "open" and OPENING or CLOSING
    local s = seq[math.max(1, math.min(a.t + 1, #seq))] / 256
    local img = Common.sprite("monPicBgAnim", 0, 64, 64, "monPicBg")
    for _, x in ipairs(xs) do
      love.graphics.setColor(1, 1, 1, 11 / 16)
      love.graphics.draw(img, x, 64, 0, s, s, 32, 32)
    end
    love.graphics.setColor(1, 1, 1, 1)
    return
  end
  local top, bottom, left, right
  if a and not a.finished then
    top, bottom, left, right = a.top, a.bottom, a.winLeft, a.winRight
  elseif open then
    top, bottom, left, right = 32, 96, open.winLeft, open.winRight
  else
    return
  end
  if bottom <= top then return end
  love.graphics.setScissor(left, top, right - left, bottom - top)
  local okS = pcall(drawBlendedBg3, Common.monPicBgImage(cache, tiles))
  love.graphics.setScissor()
  if not okS then love.graphics.setBlendMode("alpha") end
end

local st = {}
Select._st = st

local function session()
  if st.session then return st.session end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function ballX(i) return (35 * (i - 1)) + 32 end

-- pokeemerald/src/battle_factory_screen.c:1893
local function selectMonString()
  local n = st.selectingState
  if n == 1 then return RomText.plain("gText_SelectFirstPkmn") end
  if n == 2 then return RomText.plain("gText_SelectSecondPkmn") end
  if n == 3 then return RomText.plain("gText_SelectThirdPkmn") end
  return RomText.plain("gText_TheseThreePkmnOkay")
end

-- pokeemerald/src/battle_factory_screen.c:1108
function Select.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  st.onDone = opts.onDone
  st.speciesValid = opts.speciesValid
  st.mons = {}
  for i = 1, SELECTABLE_MONS_COUNT do
    local m = opts.mons[i]
    st.mons[i] = { monId = m.monId, monData = m.mon, selectedId = 0 }
  end
  st.cursor = 1
  st.selectingState = 1
  st.menuCursor = 0
  st.yesNoCursor = 0
  st.cache = {}
  st.balls = {}
  for i = 1, SELECTABLE_MONS_COUNT do st.balls[i] = Common.newBall(ballX(i), 64) end
  st.info = selectMonString()
  st.fade = { coeff = 0, delay = 0, out = true, wait = 0, state = "init", active = false }
  st.phase = "fadein"
  st.pal = Kit.fade()
  st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.BLACK)
  st.frame = 0
  Select.open = true
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.clear then Fade.clear() end
  Stack.push(Select.ID, Select, { hideBelow = true, fullscreen = true })
  return true
end

function Select.isOpen() return Select.open end

function Select.handleInput(input)
  if not Select.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

-- pokeemerald/src/battle_factory_screen.c:2277
local function stepSpeciesFade()
  local f = st.fade
  if f.state == "init" then
    f.coeffDelay, f.coeff, f.out = 0, 0, true
    f.state = "run"
  elseif f.state == "run" then
    if f.active then
      if (f.delayCount or 0) ~= 0 then
        f.state = "delay"
      else
        f.coeffDelay = f.coeffDelay + 1
        if f.coeffDelay > 6 then
          f.coeffDelay = 0
          if not f.out then f.coeff = f.coeff - 1 else f.coeff = f.coeff + 1 end
        end
        if f.coeff > 5 then
          f.out = false
        elseif f.coeff == 0 then
          f.state = "delay"
          f.out = true
        end
      end
    end
  elseif f.state == "delay" then
    if (f.delayCount or 0) > 14 then
      f.delayCount = 0
      f.state = "run"
    else
      f.delayCount = (f.delayCount or 0) + 1
    end
  end
end

-- pokeemerald/src/battle_factory_screen.c:1411
local function selectionChange()
  local m = st.mons[st.cursor]
  if m.selectedId ~= 0 then
    if st.selectingState == FRONTIER_PARTY_SIZE and m.selectedId == 1 then
      local found
      for i = 1, SELECTABLE_MONS_COUNT do
        if st.mons[i].selectedId == FRONTIER_PARTY_SIZE - 1 then found = i break end
      end
      if not found then return end
      st.mons[found].selectedId = 1
    end
    m.selectedId = 0
    st.selectingState = st.selectingState - 1
  else
    m.selectedId = st.selectingState
    st.selectingState = st.selectingState + 1
  end
end

local function chosenIndices()
  local out = {}
  for i = 1, FRONTIER_PARTY_SIZE do
    for j = 1, SELECTABLE_MONS_COUNT do
      if st.mons[j].selectedId == i then out[i] = j break end
    end
  end
  return out
end
Select.chosenIndices = chosenIndices

local function selectedMonIds()
  local out = {}
  for i = 1, st.selectingState - 1 do
    for j = 1, SELECTABLE_MONS_COUNT do
      if st.mons[j].selectedId == i then out[#out + 1] = j break end
    end
  end
  return out
end

local function openPic()
  st.picAnim = Common.newPicAnim("open", { 120 }, { 11 }, 88, 152, function()
    st.picShown = { xs = { 120 }, tiles = { 11 }, winLeft = 88, winRight = 152 }
    st.pics = { { mon = st.mons[st.cursor].monData, x = 88, y = 32 } }
  end)
end

local function closePic(onDone)
  st.pics = nil
  st.picShown = nil
  st.picAnim = Common.startClose({ 120 }, { 11 }, 88, 152, function()
    st.picAnim = nil
    if onDone then onDone() end
  end)
end

local function animating() return st.picAnim ~= nil and not st.picAnim.finished end

-- pokeemerald/src/battle_factory_screen.c:2219
local function showChosen()
  st.picAnim = Common.newPicAnim("open", { 44, 120, 196 }, { 2, 11, 20 }, 16, 224, function()
    st.picShown = { xs = { 44, 120, 196 }, tiles = { 2, 11, 20 }, winLeft = 16, winRight = 224 }
    local pics = {}
    local idx = chosenIndices()
    for i = 1, FRONTIER_PARTY_SIZE do
      if idx[i] then pics[#pics + 1] = { mon = st.mons[idx[i]].monData, x = ((i - 1) * 72) + 16, y = 32 } end
    end
    st.pics = pics
  end)
end

local function hideChosen(onDone)
  st.pics = nil
  st.picShown = nil
  st.picAnim = Common.startClose({ 44, 120, 196 }, { 2, 11, 20 }, 16, 224, function()
    st.picAnim = nil
    if onDone then onDone() end
  end)
end

local function exit()
  st.phase = "exit"
  st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
end

-- pokeemerald/src/battle_factory_screen.c:1456
local function openSummary()
  st.phase = "summary_fade"
  st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
end

local function showSummary()
  st.phase = "summary"
  st.pics, st.picShown, st.picAnim = nil, nil, nil
  local list = {}
  for i = 1, SELECTABLE_MONS_COUNT do list[i] = st.mons[i].monData end
  local SummaryMenu = require("src.ui.game3.summary_menu")
  SummaryMenu.openMenu(list, st.cursor, {
    session = session(),
    context = "factory",
    onClose = function()
      -- pokeemerald/src/battle_factory_screen.c:1264
      st.cursor = SummaryMenu._cursor or st.cursor
      Stack.push(Select.ID, Select, { hideBelow = true, fullscreen = true })
      st.pal = Kit.fade()
      st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.BLACK)
      st.picShown = { xs = { 120 }, tiles = { 11 }, winLeft = 88, winRight = 152 }
      st.pics = { { mon = st.mons[st.cursor].monData, x = 88, y = 32 } }
      st.menuShown = true
      st.phase = "menu_reinit"
    end,
  })
end

local function menuOptionLabels()
  local sel = st.mons[st.cursor].selectedId
  return { RomText.plain("gText_Summary"), RomText.plain(sel ~= 0 and "gText_Deselect" or "gText_Rent"),
    RomText.plain("gText_Others2") }
end

-- pokeemerald/src/battle_factory_screen.c:1949
local function optionRentDeselect()
  local m = st.mons[st.cursor]
  if m.selectedId == 0 and st.speciesValid and not st.speciesValid(selectedMonIds(), m.monId) then
    st.info = RomText.plain("gText_CantSelectSamePkmn")
    st.menuShown = false
    return "invalid"
  end
  closePic()
  selectionChange()
  st.info = selectMonString()
  st.menuShown = false
  if st.selectingState > FRONTIER_PARTY_SIZE then return "confirm" end
  return "continue"
end

local function stepChoose(inp)
  if animating() then return end
  if inp.new.a then
    Common.se("SE_SELECT")
    st.fade.active = false
    openPic()
    st.phase = "menu_open"
  elseif inp.rep.left then
    Common.se("SE_SELECT")
    st.cursor = st.cursor == 1 and SELECTABLE_MONS_COUNT or st.cursor - 1
  elseif inp.rep.right then
    Common.se("SE_SELECT")
    st.cursor = st.cursor == SELECTABLE_MONS_COUNT and 1 or st.cursor + 1
  end
end

local function stepMenu(inp)
  if inp.new.a then
    Common.se("SE_SELECT")
    local opt = st.menuCursor
    if opt == 0 then
      openSummary()
    elseif opt == 1 then
      local r = optionRentDeselect()
      if r == "continue" then
        st.fade.active = true
        st.phase = "choose"
      elseif r == "confirm" then
        st.phase = "confirm_show"
      else
        st.phase = "invalid"
      end
    else
      closePic()
      st.menuShown = false
      st.fade.active = true
      st.phase = "choose"
    end
  elseif inp.new.b then
    Common.se("SE_SELECT")
    closePic()
    st.menuShown = false
    st.fade.active = true
    st.phase = "choose"
  elseif inp.rep.up then
    Common.se("SE_SELECT")
    st.menuCursor = st.menuCursor == 0 and 2 or st.menuCursor - 1
  elseif inp.rep.down then
    Common.se("SE_SELECT")
    st.menuCursor = st.menuCursor == 2 and 0 or st.menuCursor + 1
  end
end

-- pokeemerald/src/battle_factory_screen.c:1525
local function stepYesNo(inp)
  if animating() then return end
  local function decline()
    st.yesNoShown = false
    hideChosen()
    selectionChange()
    st.info = selectMonString()
    st.fade.active = true
    st.phase = "choose"
  end
  if inp.new.a then
    Common.se("SE_SELECT")
    if st.yesNoCursor == 0 then
      st.yesNoShown = false
      hideChosen(function() exit() end)
      st.phase = "exit_wait"
    else
      decline()
    end
  elseif inp.new.b then
    Common.se("SE_SELECT")
    decline()
  elseif inp.rep.up or inp.rep.down then
    Common.se("SE_SELECT")
    st.yesNoCursor = 1 - st.yesNoCursor
  end
end

function Select.update()
  if not Select.open then return end
  st.frame = st.frame + 1
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  for i, b in ipairs(st.balls) do
    b.selected = st.mons[i].selectedId ~= 0
    Common.stepBall(b)
  end
  stepSpeciesFade()
  Common.stepPicAnim(st.picAnim)
  if st.picAnim and st.picAnim.finished and st.picAnim.kind == "open" then st.picAnim = nil end
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
  elseif ph == "invalid" then
    if inp.new.a then
      Common.se("SE_SELECT")
      closePic()
      st.info = selectMonString()
      st.fade.active = true
      st.phase = "choose"
    end
  elseif ph == "confirm_show" then
    if not animating() then
      showChosen()
      st.phase = "confirm_wait"
    end
  elseif ph == "confirm_wait" then
    if not animating() then
      st.yesNoCursor = 0
      st.yesNoShown = true
      st.phase = "yesno"
    end
  elseif ph == "yesno" then
    stepYesNo(inp)
  elseif ph == "summary_fade" then
    if not st.pal:updateFade() then showSummary() end
  elseif ph == "exit" then
    if not st.pal:updateFade() then
      Select.open = false
      Stack.pop(Select.ID)
      local cb = st.onDone
      local chosen = chosenIndices()
      st.onDone = nil
      if cb then cb(chosen) end
    end
  end
end

function Select.draw()
  if not Select.open then return end
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(Common.menuImage(st.cache), 0, 0)
  for _, b in ipairs(st.balls) do Common.drawBall(b, b.selected and "ballSelected" or "ballGray") end
  if st.phase ~= "summary" then Common.drawArrow(st.balls[st.cursor].x, 88) end
  Common.drawPicBg(st.cache, st.picAnim, st.picShown)
  if st.menuShown then Common.drawMenuHighlight(176, 208, st.menuCursor * 16 + 112) end
  if st.yesNoShown then Common.drawMenuHighlight(176, 208, st.yesNoCursor * 16 + 112) end
  Common.text(RomText.plain("gText_RentalPkmn2"), 2, 16 + 1)
  local mon = st.mons[st.cursor].monData
  local name = Common.speciesName(mon.species)
  Common.text(name, 19 * 8 + Common.rightAlign(name, 86), 16 + 1, "species", st.fade.coeff)
  local cat = Common.categoryText(mon.species)
  Common.text(cat, 15 * 8 + Common.rightAlign(cat, 118), 1)
  Common.text(st.info, 2, 15 * 8 + 5)
  if st.menuShown then
    local labels = menuOptionLabels()
    for i = 1, 3 do Common.text(labels[i], 22 * 8 + 7, 14 * 8 + 1 + (i - 1) * 16, "menu") end
  end
  if st.yesNoShown then
    Common.text(RomText.plain("gText_Yes2"), 22 * 8 + 7, 14 * 8 + 1, "menu")
    Common.text(RomText.plain("gText_No2"), 22 * 8 + 7, 14 * 8 + 17, "menu")
  end
  for _, p in ipairs(st.pics or {}) do
    local img = Common.monPic(p.mon)
    if img then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, p.x, p.y)
    end
  end
  if st.pal then Kit.drawFade(st.pal, 0, 240, 160) end
end

function Select.reset()
  Select.open = false
  Stack.pop(Select.ID)
  for k in pairs(st) do st[k] = nil end
  entriesPack = nil
end

return Select
