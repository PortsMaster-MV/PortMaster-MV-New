local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local Graph = require("src.ui.game3.rse.condition_graph")
local Pokeblock = require("src.core.game3.rse.pokeblock")
local Pokemon = require("src.core.game3.pokemon")

local Use = {}

Use.ID = "rse_use_pokeblock"
Use.open = false

-- pokeemerald/src/use_pokeblock.c:246
Use.WIN = { NAME = { 13, 1, 13, 4 }, NATURE = { 0, 14, 11, 2 }, TEXT = { 1, 17, 28, 2 } }
-- pokeemerald/src/use_pokeblock.c:278
Use.YESNO = { 24, 11 }
-- pokeemerald/src/use_pokeblock.c:1225
Use.MON_X, Use.MON_Y = 38, 104 - 34
-- pokeemerald/src/use_pokeblock.c:1326
Use.MON_FRAME_Y = 34

local st = {}
Use._st = st

local function gfx() return Gfx.of("rse/pokeblock") end
local function man() return gfx():manifest() end

local function se(name)
  pcall(Kit.playSe, name)
end

local function textPal()
  return man().palettes.condition_text
end

local function pc(list, i)
  return Gfx.color(list[i + 1] or 0)
end

local function textColors(fg, shadow)
  local p = textPal()
  return { fg = pc(p, fg), shadow = pc(p, shadow), bg = { 0, 0, 0, 0 } }
end

-- pokeemerald/src/use_pokeblock.c:1157
local function loadParty()
  local party = st.session and st.session.party or {}
  st.party = {}
  for i, mon in ipairs(party) do
    if not Pokemon.isEgg(mon) then st.party[#st.party + 1] = i end
  end
  st.numSelections = #st.party + 1
end

local function isCancel(sel)
  return sel == st.numSelections - 1
end

local function monAt(sel)
  local idx = st.party[sel + 1]
  return idx and st.session.party[idx] or nil, idx
end

-- pokeemerald/src/menu_specialized.c:1037
local function positionsFor(sel)
  if isCancel(sel) then return Graph.centerPositions() end
  return st.graph:calcPositions(Pokeblock.conditions(monAt(sel)), {})
end

local function sparklesFor(sel)
  if isCancel(sel) then return nil end
  local mon = monAt(sel)
  return Graph.Sparkles.new(Pokeblock.sparkles(Pokeblock.sheen(mon)), man().sparkleCoords)
end

-- pokeemerald/src/menu_specialized.c:906
local function nameLine(mon)
  local parts = {}
  local name = Pokemon.displayMonName(mon)
  local sp = Pokemon.speciesOf(mon)
  local g = Pokemon.gender(sp, mon.personality)
  local C = require("src.core.game3.constants")
  local T = C.of(C.versionOf(st.session))
  if (sp == T:require("species", "SPECIES_NIDORAN_F") or sp == T:require("species", "SPECIES_NIDORAN_M"))
      and name == Pokemon.name(sp) then
    g = "U"
  end
  parts.name = name
  parts.gender = g
  parts.level = st.opts.levelText and st.opts.levelText(tonumber(mon.level) or 1)
    or RomText.plain("gText_LvVar1", { stringVars = { tostring(tonumber(mon.level) or 1) } })
  return parts
end

local function refreshText(sel)
  if isCancel(sel) then
    st.nameInfo, st.natureText = nil, nil
    return
  end
  local mon = monAt(sel)
  st.nameInfo = nameLine(mon)
  -- pokeemerald/src/use_pokeblock.c:1395
  st.natureText = st.opts.natureText and st.opts.natureText(mon)
    or RomText.plain("gText_NatureSlash") .. RomText.at("gNatureNamePointers", Pokeblock.natureOf(mon))
end

local function setMonPic(sel)
  if isCancel(sel) then return end
  local mon = monAt(sel)
  local pic = Pokemon.monFrontPic(mon)
  st.monPic = pic and pic.image or nil
end

-- pokeemerald/src/use_pokeblock.c:1412
local function updateSelection(up)
  local cur = st.sel
  local new
  if up then
    new = (cur == 0) and (st.numSelections - 1) or (cur - 1)
  else
    new = (cur < st.numSelections - 1) and (cur + 1) or 0
  end
  st.graph:setNewPositions(positionsFor(cur), positionsFor(new))
  local startedOnMon = not isCancel(cur)
  local endedOnMon = not isCancel(new)
  st.sel = new
  st.sparkles = nil
  st.helper = 0
  if not startedOnMon then
    st.loadNew = "cancel_to_mon"
  elseif not endedOnMon then
    st.loadNew = "mon_to_cancel"
  else
    st.loadNew = "mon_to_mon"
  end
end

local function monEnter()
  local g = st.graph:tryUpdate()
  local moving
  st.monX, moving = Graph.moveMonOnscreen(st.monX)
  return g or moving
end

local function monExit()
  local g = st.graph:tryUpdate()
  local moving
  st.monX, moving = Graph.moveMonOffscreen(st.monX)
  return g or moving
end

-- pokeemerald/src/use_pokeblock.c:1477
local function loadNewSelection()
  local kind, h = st.loadNew, st.helper
  if kind == "cancel_to_mon" then
    if h == 0 then setMonPic(st.sel); st.helper = 1
    elseif h == 1 then refreshText(st.sel); st.helper = 2
    elseif h == 2 then if not monEnter() then st.helper = 3 end
    else
      st.sparkles = sparklesFor(st.sel)
      st.helper = 0
      return false
    end
  elseif kind == "mon_to_cancel" then
    if h == 0 then if not monExit() then st.helper = 1 end
    elseif h == 1 then refreshText(st.sel); st.helper = 2
    elseif h == 2 then st.helper = 3
    else
      st.helper = 0
      return false
    end
  else
    if h == 0 then
      st.graph:tryUpdate()
      local moving
      st.monX, moving = Graph.moveMonOffscreen(st.monX)
      if not moving then
        setMonPic(st.sel)
        st.helper = 1
      end
    elseif h == 1 then refreshText(st.sel); st.helper = 2
    elseif h == 2 then if not monEnter() then st.helper = 3 end
    else
      st.sparkles = sparklesFor(st.sel)
      st.helper = 0
      return false
    end
  end
  return true
end

local function frameTypeOption()
  local ok, Options = pcall(require, "src.core.game3.options")
  return ok and Options.frameType and Options.frameType(st.session) or 0
end

-- pokeemerald/src/use_pokeblock.c:866
local function askUse()
  local mon = monAt(st.sel)
  st.message = Pokemon.displayMonName(mon) .. RomText.plain("gText_GetsAPokeBlockQuestion")
  st.yesNo = Kit.yesNo(Use.YESNO[1], Use.YESNO[2], { frameType = frameTypeOption() })
end

local function beginFade(dir, after)
  st.fadeDir = dir
  st.afterFade = after
end

local function stepFade()
  if st.fadeDir == 0 then return false end
  st.fade = st.fade + st.fadeDir * 2
  if st.fade <= 0 or st.fade >= 16 then
    st.fade = (st.fade <= 0) and 0 or 16
    st.fadeDir = 0
    local cb = st.afterFade
    st.afterFade = nil
    if cb then cb() end
  end
  return true
end

-- pokeemerald/src/use_pokeblock.c:820
local function close()
  beginFade(1, function()
    Use.open = false
    Stack.pop(Use.ID)
    local cb = st.onExit
    if cb then cb() end
  end)
end

-- pokeemerald/src/use_pokeblock.c:690
local function feed()
  local _, partyIdx = monAt(st.sel)
  local opts = st.opts
  beginFade(1, function()
    Use.open = false
    Stack.pop(Use.ID)
    local Feed = require("src.ui.game3.rse.pokeblock_feed")
    Feed.show({
      session = st.session,
      partyIndex = partyIdx,
      pokeblockId = opts.pokeblockId,
      onDone = function(gain)
        local o = {}
        for k, v in pairs(opts) do o[k] = v end
        o.results = { partyIndex = partyIdx, gain = gain }
        Use.show(o)
      end,
    })
  end)
end

local function upDownSprites(enh)
  st.upDown = {}
  local coords = man().upDownCoords
  for i = 1, #Pokeblock.CONDITIONS do
    if (enh[i] or 0) ~= 0 then
      st.upDown[#st.upDown + 1] = { x = coords[i][1], y = coords[i][2], y2 = 0, t = 0 }
    end
  end
end

-- pokeemerald/src/use_pokeblock.c:1141
local function stepUpDown()
  if not st.upDown then return end
  local keep = {}
  for _, s in ipairs(st.upDown) do
    if s.t < 6 then s.y2 = s.y2 - 2 elseif s.t < 12 then s.y2 = s.y2 + 2 end
    s.t = s.t + 1
    if s.t <= 60 then keep[#keep + 1] = s end
  end
  st.upDown = keep
end

local function stepTitle()
  for _, t in ipairs(st.titles) do
    if t.moving then
      local prev = t.x
      t.x = t.x + 8
      if (prev <= t.target and t.x >= t.target) or (prev >= t.target and t.x <= t.target) then
        t.x = t.target
        t.moving = false
      end
    end
  end
end

local function step(inp)
  st.frame = st.frame + 1
  stepTitle()
  stepUpDown()
  if st.sparkles then st.sparkles:update() end
  if stepFade() then return end
  local s = st.state
  if s == "load" then
    -- pokeemerald/src/use_pokeblock.c:533
    local moving
    st.monX, moving = Graph.moveMonOnscreen(st.monX)
    if not moving then
      st.graph:setNewPositions(positionsFor(st.sel), positionsFor(st.sel))
      st.graph:update()
      st.state = "show"
      beginFade(-1, function()
        if not isCancel(st.sel) then st.sparkles = sparklesFor(st.sel) end
        st.state = st.results and "results_wait" or "input"
        if st.results then st.sparkles = nil end
      end)
    end
  elseif s == "input" then
    -- pokeemerald/src/use_pokeblock.c:613
    if inp.held.up then
      se("SE_SELECT")
      updateSelection(true)
      st.state = "loading"
    elseif inp.held.down then
      se("SE_SELECT")
      updateSelection(false)
      st.state = "loading"
    elseif inp.new.b then
      se("SE_SELECT")
      st.state = "closing"
      close()
    elseif inp.new.a then
      se("SE_SELECT")
      if isCancel(st.sel) then
        st.state = "closing"
        close()
      else
        askUse()
        st.state = "confirm"
      end
    end
  elseif s == "loading" then
    if not loadNewSelection() then st.state = "input" end
  elseif s == "confirm" then
    local r = st.yesNo:input(inp)
    if r == 0 then
      st.yesNo = nil
      if Pokeblock.isSheenMaxed(monAt(st.sel)) then
        -- pokeemerald/src/use_pokeblock.c:948
        st.message = RomText.plain("gText_WontEatAnymore")
        st.state = "wont_eat"
      else
        st.message = nil
        st.state = "feeding"
        feed()
      end
    elseif r == 1 or r == -1 then
      se("SE_SELECT")
      st.yesNo = nil
      st.message = nil
      st.state = "input"
    end
  elseif s == "wont_eat" then
    if inp.new.a or inp.new.b then
      st.message = nil
      st.state = "input"
    end
  elseif s == "results_wait" then
    -- pokeemerald/src/use_pokeblock.c:779
    if inp.new.a or inp.new.b then
      local mon = monAt(st.sel)
      local before = positionsFor(st.sel)
      local block = Pokeblock.get(st.session, st.opts.pokeblockId)
      local res = Pokeblock.feed(block, mon, st.results.gain)
      st.enhancements = res.enhancements
      st.graph:setNewPositions(before, positionsFor(st.sel))
      upDownSprites(res.enhancements)
      st.state = "results_graph"
    end
  elseif s == "results_graph" then
    if not st.graph:tryUpdate() then
      st.sparkles = sparklesFor(st.sel)
      st.timer = 0
      st.state = "results_timer"
    end
  elseif s == "results_timer" then
    st.timer = st.timer + 1
    if st.timer > 16 then
      -- pokeemerald/src/use_pokeblock.c:901
      st.texts = Pokeblock.enhancementTexts(st.enhancements)
      st.textIdx = 1
      st.message = st.texts[1]
      st.state = "results_text"
    end
  elseif s == "results_text" then
    if inp.new.a or inp.new.b then
      if st.textIdx < #st.texts then
        st.textIdx = st.textIdx + 1
        st.message = st.texts[st.textIdx]
      else
        -- pokeemerald/src/use_pokeblock.c:813
        Pokeblock.tryClear(st.session, st.opts.pokeblockId)
        st.state = "closing"
        close()
      end
    end
  end
end

-- pokeemerald/src/use_pokeblock.c:416
function Use.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.opts = opts
  st.session = opts.session or Pokeblock.session()
  st.onExit = opts.onExit
  st.results = opts.results
  st.graph = Graph.new(man())
  st.frame = 0
  st.fade = 16
  st.fadeDir = 0
  st.monX = -80
  loadParty()
  st.sel = 0
  if st.results then
    -- pokeemerald/src/use_pokeblock.c:433
    for i, idx in ipairs(st.party) do
      if idx == st.results.partyIndex then st.sel = i - 1 end
    end
  end
  setMonPic(st.sel)
  refreshText(st.sel)
  -- pokeemerald/src/use_pokeblock.c:1621
  st.titles = {
    { x = -96, target = 0 + 0x20, moving = true, tile = 0 },
    { x = -32, target = 64 + 0x20, moving = true, tile = 32 },
  }
  st.state = "load"
  Use.open = true
  Stack.push(Use.ID, Use, { hideBelow = true, fullscreen = true })
  return true
end

function Use.isOpen()
  return Use.open
end

function Use.reset()
  Use.open = false
  Stack.pop(Use.ID)
end

function Use.handleInput(input)
  if not Use.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

function Use.update()
  if not Use.open then return end
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  step(inp)
end

local function layerImages()
  if st.layers then return st.layers end
  local m = man()
  local g = gfx()
  local graphMap = g:map("graph")
  local nat = g:map("nature_win")
  -- pokeemerald/src/use_pokeblock.c:1361
  for y = 0, 3 do
    for x = 0, 11 do graphMap[(13 + y) * 32 + x] = nat[y * 12 + x] end
  end
  local pal2 = Gfx.palette(m.palettes.graph, {}, 2)
  local pal13 = Gfx.palette(m.palettes.mon_frame, {}, 13)
  local pal3 = Gfx.palette(m.palettes.graph_data, {}, 3)
  st.layers = {
    bg1 = g:renderMap(graphMap, "graph", pal2, { rows = 20, tileBase = m.graphTileBase }),
    bg3 = g:renderMap(g:map("mon_frame"), "mon_frame", pal13, { rows = 20, tileBase = m.monFrameTileBase }),
    bg2 = g:renderMap(g:map("graph_data"), "graph", pal3, { rows = 20, tileBase = m.graphTileBase }),
  }
  return st.layers
end

local function sprite(key, tile, w, h, pal)
  return gfx():sprite(key, tile, w, h, pal)
end

local function drawIcons()
  local m = man()
  local cancelPal = m.palettes.cancel
  local ballPal, cancelOwn = {}, {}
  for i = 1, 16 do
    ballPal[i] = cancelPal[i]
    cancelOwn[i] = cancelPal[16 + i]
  end
  local i = 0
  -- pokeemerald/src/use_pokeblock.c:1263
  while i < st.numSelections - 1 do
    local img = sprite("ball", (i == st.sel) and 0 or 4, 16, 16, ballPal)
    love.graphics.draw(img, 226 - 8, i * 20 + 8 - 8)
    i = i + 1
  end
  while i < 6 do
    love.graphics.draw(sprite("ball_placeholder", 0, 8, 8, ballPal), 230 - 4, i * 20 + 8 - 4)
    i = i + 1
  end
  local cimg = sprite("cancel", 0, 32, 16, isCancel(st.sel) and ballPal or cancelOwn)
  love.graphics.draw(cimg, 222 - 16, i * 20 + 8 - 8)
end

function Use.draw()
  if not Use.open then return end
  if st.opts.draw then
    return st.opts.draw(st, {drawIcons = drawIcons, isCancel = isCancel, sprite = sprite})
  end
  local m = man()
  local L = layerImages()
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(L.bg1, 0, 0)
  love.graphics.draw(L.bg3, 0, -Use.MON_FRAME_Y)
  drawIcons()
  st.graph:draw(L.bg2)
  if st.monPic and not isCancel(st.sel) then
    local w, h = st.monPic:getDimensions()
    love.graphics.draw(st.monPic, Use.MON_X + st.monX - w / 2, Use.MON_Y - h / 2)
  end
  local cpal = m.palettes.condition
  for _, t in ipairs(st.titles) do
    love.graphics.draw(sprite("condition", t.tile, 64, 32, cpal), t.x - 32, 17 - 16)
  end
  if st.upDown then
    local img = sprite("updown", 0, 32, 16, m.palettes.updown)
    for _, s in ipairs(st.upDown) do love.graphics.draw(img, s.x - 16, s.y + s.y2 - 8) end
  end
  if st.nameInfo then
    local W = Use.WIN.NAME
    local x, y = W[1] * 8, W[2] * 8 + 1
    local c = textColors(8, 9)
    FrlgFont.draw(st.nameInfo.name, x, y, { colors = c })
    local gx = x + 60
    if st.nameInfo.gender == "M" then
      FrlgFont.draw("♂", gx, y, { colors = textColors(4, 5) })
    elseif st.nameInfo.gender == "F" then
      FrlgFont.draw("♀", gx, y, { colors = textColors(6, 7) })
    end
    FrlgFont.draw("/" .. st.nameInfo.level, gx + FrlgFont.measure(" "), y, { colors = c })
  end
  if st.natureText then
    local W = Use.WIN.NATURE
    local p = textPal()
    FrlgFont.draw(st.natureText, W[1] * 8 + 2, W[2] * 8 + 1,
      { colors = { fg = pc(p, 8), shadow = pc(p, 1), bg = { 0, 0, 0, 0 } } })
  end
  if st.message then
    local W = Use.WIN.TEXT
    Chrome.stdFrame(W[1], W[2], W[3], W[4])
    FrlgFont.draw(st.message, W[1] * 8, W[2] * 8 + 1, { colors = textColors(2, 3) })
  end
  if st.yesNo then st.yesNo:draw() end
  if st.sparkles then
    local frames = {}
    for f = 0, Graph.Sparkles.FRAMES - 1 do frames[f] = sprite("sparkle", f * 4, 16, 16, m.palettes.sparkle) end
    st.sparkles:draw(nil, frames, Use.MON_X + st.monX, Use.MON_Y)
  end
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return Use
