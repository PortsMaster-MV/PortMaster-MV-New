local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local PalFade = require("src.core.game3.pal_fade")

local Pass = { isMenu = true }

Pass.ID = "rse_frontier_pass"
Pass.MAP_ID = "rse_frontier_map"
Pass.open = false

-- pokeemerald/src/frontier_pass.c:66
Pass.AREA = {
  NOTHING = 0, MAP = 1, CARD = 2, RECORD = 3, CANCEL = 4, POINTS = 5, EARNED_SYMBOLS = 6, SYMBOL_TOWER = 7,
  SYMBOL_DOME = 8, SYMBOL_PALACE = 9, SYMBOL_ARENA = 10, SYMBOL_FACTORY = 11, SYMBOL_PIKE = 12,
  SYMBOL_PYRAMID = 13, COUNT = 14,
}
local A = Pass.AREA
local NUM_FACILITIES = 7

local st = {}
Pass._st = st

local function gfx() return Gfx.of("rse/frontier_pass") end
local function man() return gfx():manifest() end

local function se(name) pcall(Kit.playSe, name) end

local function session()
  if st.session then return st.session end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function textOf(ir)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local s = session()
  return TextIR.toPlain(ir, { playerName = s and s.name, stringVars = {} })
end

local function colors(i)
  -- pokeemerald/src/frontier_pass.c:332
  local ids = ({ { 0, 2, 3 }, { 0, 1, 9 }, { 0, 4, 5 } })[i + 1]
  local pals = Kit.chromePalettes()
  -- pokeemerald/src/text_window.c:162
  local pal = pals and pals.text_window and pals.text_window[0] or {}
  return { fg = Kit.color8(pal[ids[2]]), shadow = Kit.color8(pal[ids[3]]), bg = { 0, 0, 0, 0 } }
end

local function pal256(stars)
  local list = man().palettes.bg
  local pal = {}
  for i = 1, #list do pal[i - 1] = list[i] end
  if stars then
    for j = 0, 15 do pal[16 + j] = list[(1 + stars) * 16 + j + 1] end
  end
  return pal
end

local function trainerStars(s)
  local ok, TC = pcall(require, "src.ui.game3.trainer_card")
  if ok and TC and TC.countStars then
    local okS, n = pcall(TC.countStars, s)
    if okS and tonumber(n) then return tonumber(n) end
  end
  local Natives = require("src.core.game3.scripting.natives")
  local h = Natives.handlerFor and Natives.handlerFor("CountPlayerTrainerStars")
  if h then
    local ctx = { specialVars = {} }
    local _, v = h(ctx, nil)
    if tonumber(v) then return tonumber(v) end
    return tonumber(ctx.specialVars[0x800D]) or 0
  end
  return 0
end

local function symbolCounts(s)
  local Util = require("src.core.game3.rse.frontier.util")
  local out = {}
  for i = 0, NUM_FACILITIES - 1 do out[i] = Util.symbolCount(s, i) end
  return out
end

local function hasBattleRecord(s)
  local impl = require("src.core.game3.rse.init").system("recordedBattle")
  return impl and type(impl.canCopy) == "function" and impl.canCopy(s) or false
end

local function mapsecOf(s)
  local okM, Mapsec = pcall(require, "src.ui.game3.rse.mapsec")
  if okM and Mapsec and Mapsec.current then
    local okC, v = pcall(Mapsec.current, s)
    if okC then return v end
  end
  return nil
end

local function inFrontier(s)
  local m = tostring(s and s.map or "")
  return m:find("^EM_BATTLE_FRONTIER_") ~= nil or m:find("^EM_ARTISAN_CAVE") ~= nil
end

-- pokeemerald/src/frontier_pass.c:869
function Pass.areaAt(x, y)
  local areas = man().areas
  for i = 0, #areas - 1 do
    local r = areas[i + 1]
    if r.yStart <= y and r.yEnd >= y and r.xStart <= x and r.xEnd >= x then
      if i >= A.SYMBOL_TOWER - 1 and (st.symbols[i - A.SYMBOL_TOWER + 1] or 0) == 0 then break end
      return i + 1
    end
  end
  return A.NOTHING
end

local function copyBlock(dst, src, srcStart, x, y, w, h)
  local i = srcStart
  for yy = y, y + h - 1 do
    for xx = x, x + w - 1 do
      dst[yy * 32 + xx] = src[i] or 0
      i = i + 1
    end
  end
end

-- pokeemerald/src/frontier_pass.c:1244
local function updateHighlight(cur, prev)
  local function nonHighlight(a) return a == A.NOTHING or a > A.CANCEL end
  local g = gfx()
  local mc = st.mapAndCard
  local rec = st.recordMap
  local bg = st.bgMap
  if prev == A.MAP then copyBlock(bg, mc, 0, 16, 3, 12, 7)
  elseif prev == A.CARD then copyBlock(bg, mc, 168, 16, 10, 12, 7)
  elseif prev == A.RECORD then
    if st.hasRecord then copyBlock(bg, rec, 0, 2, 10, 12, 3)
    elseif nonHighlight(cur) then return end
  elseif prev == A.CANCEL then copyBlock(bg, st.cancelMap, 0, 21, 0, 9, 2)
  elseif nonHighlight(cur) then return end
  if cur == A.MAP then copyBlock(bg, mc, 84, 16, 3, 12, 7)
  elseif cur == A.CARD then copyBlock(bg, mc, 252, 16, 10, 12, 7)
  elseif cur == A.RECORD then
    if st.hasRecord then copyBlock(bg, rec, 36, 2, 10, 12, 3) else return end
  elseif cur == A.CANCEL then copyBlock(bg, st.cancelHiMap, 0, 21, 0, 9, 2)
  elseif nonHighlight(prev) then return end
  st.bgImage = nil
  local _ = g
end

-- pokeemerald/src/frontier_pass.c:530
local function description(i)
  return RomText.irOr(RomText.key("sPassAreaDescriptions", i), man().descriptions[i + 1])
end

-- pokeemerald/src/frontier_pass.c:556
local LANDMARK_TEXTS = {
  { "gText_BattleTower3", "gText_BattleTowerDesc" },
  { "gText_BattleDome2", "gText_BattleDomeDesc" },
  { "gText_BattlePalace2", "gText_BattlePalaceDesc" },
  { "gText_BattleArena2", "gText_BattleArenaDesc" },
  { "gText_BattleFactory2", "gText_BattleFactoryDesc" },
  { "gText_BattlePike2", "gText_BattlePikeDesc" },
  { "gText_BattlePyramid2", "gText_BattlePyramidDesc" },
}

local function landmarkText(i, field)
  local labels = LANDMARK_TEXTS[i + 1]
  return RomText.irOr(labels and labels[field == "name" and 1 or 2], man().landmarks[i + 1][field])
end

local function describe(area)
  if area == A.RECORD and not st.hasRecord then
    st.desc = textOf(description(A.NOTHING))
  elseif area ~= A.NOTHING then
    st.desc = textOf(description(area))
  else
    st.desc = nil
  end
end

local function loadMaps()
  local g = gfx()
  st.bgMap = g:map("bg")
  st.mapAndCard = g:map("mapAndCard")
  st.recordMap = g:map("record")
  st.cancelMap = g:map("cancel")
  st.cancelHiMap = g:map("cancelHi")
end

-- pokeemerald/src/frontier_pass.c:595
function Pass.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  st.onClose = opts.onClose
  local s = session()
  st.cursorX, st.cursorY = 176, inFrontier(s) and 48 or 104
  local Util = require("src.core.game3.rse.frontier.util")
  st.battlePoints = tonumber(Util.frontier(s).battlePoints) or 0
  st.hasRecord = hasBattleRecord(s)
  st.stars = math.max(0, math.min(4, trainerStars(s)))
  st.symbols = symbolCounts(s)
  st.frame = 0
  Pass.enter()
  Pass.open = true
  Stack.push(Pass.ID, Pass, { hideBelow = true, fullscreen = true })
  return true
end

-- pokeemerald/src/frontier_pass.c:729
function Pass.enter()
  loadMaps()
  st.pal = Kit.fade()
  st.cursorArea, st.prevArea = A.NOTHING, A.NOTHING
  st.cursorArea = Pass.areaAt(st.cursorX - 5, st.cursorY + 5)
  describe(st.cursorArea)
  updateHighlight(st.cursorArea, st.prevArea)
  st.phase = "fadein"
  if st.zoomOut then
    st.phase = "zoom"
    st.zoom = { scale = 508, speed = -0x15, out = true }
    st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.WHITE)
  else
    st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.BLACK)
  end
end

function Pass.isOpen()
  return Pass.open
end

local function close()
  Pass.open = false
  Stack.pop(Pass.ID)
  local cb = st.onClose
  if cb then cb() end
end

function Pass.handleInput(input)
  if not Pass.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

-- pokeemerald/src/frontier_pass.c:987
local function stepInput(inp)
  local moved = false
  local held = inp.held
  if held.up and st.cursorY >= 9 then
    st.cursorY = st.cursorY - 2
    if st.cursorY <= 7 then st.cursorY = 2 end
    moved = true
  end
  if held.down and st.cursorY <= 135 then
    st.cursorY = st.cursorY + 2
    if st.cursorY >= 137 then st.cursorY = 136 end
    moved = true
  end
  if held.left and st.cursorX >= 6 then
    st.cursorX = st.cursorX - 2
    if st.cursorX <= 4 then st.cursorX = 5 end
    moved = true
  end
  if held.right and st.cursorX <= 231 then
    st.cursorX = st.cursorX + 2
    if st.cursorX >= 233 then st.cursorX = 232 end
    moved = true
  end
  if not moved then
    if st.cursorArea ~= A.NOTHING and inp.new.a then
      if st.cursorArea <= A.RECORD then
        se("SE_SELECT")
        if st.cursorArea == A.RECORD then
          if st.hasRecord then
            st.areaToShow = A.RECORD
            st.phase = "fadeout"
            st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
            return
          end
        else
          st.areaToShow = st.cursorArea
          st.phase = "zoom"
          st.zoom = { scale = 256, speed = 0x15, out = false }
          st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.WHITE)
          return
        end
      elseif st.cursorArea == A.CANCEL then
        se("SE_PC_OFF")
        st.areaToShow = nil
        st.phase = "fadeout"
        st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
        return
      end
    end
    if inp.new.b then
      se("SE_PC_OFF")
      st.areaToShow = nil
      st.phase = "fadeout"
      st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
    end
  else
    local area = Pass.areaAt(st.cursorX - 5, st.cursorY + 5)
    if area ~= st.cursorArea then
      describe(area)
      st.prevArea = st.cursorArea
      st.cursorArea = area
      updateHighlight(st.cursorArea, st.prevArea)
    end
  end
end

-- pokeemerald/src/frontier_pass.c:938
local function showFeature()
  local area = st.areaToShow
  if area == A.MAP then
    st.phase = "map"
    Pass.Map.show()
  elseif area == A.CARD then
    st.phase = "card"
    local s = session()
    local TrainerCard = require("src.ui.game3.screens").get("trainer_card", s)
    TrainerCard.show({ session = s, onClose = function() Pass.reshow() end })
  elseif area == A.RECORD then
    local impl = require("src.core.game3.rse.init").system("recordedBattle")
    if impl and type(impl.play) == "function" then
      st.phase = "record"
      impl.play(session(), function() Pass.reshow() end)
    else
      Pass.reshow()
    end
  end
end

-- pokeemerald/src/frontier_pass.c:892
function Pass.reshow()
  if not Pass.open then return end
  st.zoomOut = st.areaToShow == A.MAP or st.areaToShow == A.CARD
  Stack.push(Pass.ID, Pass, { hideBelow = true, fullscreen = true })
  Pass.enter()
  st.zoomOut = nil
end

-- pokeemerald/src/frontier_pass.c:1068
local function stepZoom()
  local z = st.zoom
  st.pal:updateFade()
  if not z.done then
    z.scale = z.scale + z.speed
    if (not z.out and z.scale > 508) or (z.out and z.scale == 256) then z.done = true end
    if z.out and z.scale < 256 then z.scale = 256 z.done = true end
    return
  end
  if st.pal:fadeActive() then return end
  st.zoom = nil
  if not z.out then
    showFeature()
  else
    st.areaToShow = A.NOTHING
    st.phase = "input"
  end
end

function Pass.update()
  if not Pass.open then return end
  st.frame = (st.frame or 0) + 1
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  if st.phase == "fadein" then
    if not st.pal:updateFade() then st.phase = "input" end
  elseif st.phase == "input" then
    stepInput(inp)
  elseif st.phase == "zoom" then
    stepZoom()
  elseif st.phase == "fadeout" then
    if not st.pal:updateFade() then
      if st.areaToShow == A.RECORD then showFeature() else close() end
    end
  elseif st.phase == "map" then
    Pass.Map.update(inp)
  end
end

local function bgImage()
  if st.bgImage then return st.bgImage end
  st.bgImage = gfx():renderMap(st.bgMap, "bg", pal256(st.stars), { width = 32, rows = 20, backdrop = true })
  return st.bgImage
end

local function spriteFrame(key, tile, w, h, pal16, opts)
  return gfx():sprite(key, tile, w, h, pal16, opts)
end

local function drawText(s, x, y, c, font)
  FrlgFont.draw(s, x, y, { font = font, colors = c })
end

-- pokeemerald/src/frontier_pass.c:1154
local function drawWindows()
  local c0 = colors(0)
  local sym = RomText.plain("gText_SymbolsEarned")
  drawText(sym, 16 + math.floor((96 - FrlgFont.measure(sym)) / 2), 24 + 5, c0)
  local rec = RomText.plain("gText_BattleRecord")
  drawText(rec, 16 + math.floor((96 - FrlgFont.measure(rec)) / 2), 80 + 5, c0)
  drawText(RomText.plain("gText_BattlePoints"), 16 + 5, 104 + 4, c0, "small_narrow")
  local n = tostring(st.battlePoints)
  drawText(n, 16 + 91 - FrlgFont.measure(n, { font = "small_narrow" }), 104 + 16, c0, "small_narrow")
  if st.desc then drawText(st.desc, 2, 144, colors(1)) end
end

local function drawSprites()
  local p = man().palettes
  for i = 0, NUM_FACILITIES - 1 do
    local n = st.symbols[i] or 0
    if n > 0 then
      local r = man().areas[A.SYMBOL_TOWER + i]
      local img = spriteFrame("medals", i * 4, 16, 16, n == 2 and p.medalsGold or p.medalsSilver)
      love.graphics.draw(img, r.xStart + 8 - 8, r.yStart + 6 - 8)
    end
  end
  local cur = spriteFrame("cursor", 0, 16, 16, p.cursor)
  love.graphics.draw(cur, st.cursorX - 8, st.cursorY - 8)
end

function Pass.draw()
  if not Pass.open then return end
  love.graphics.setColor(1, 1, 1, 1)
  if st.phase == "map" and Pass.Map.active then
    Pass.Map.draw()
    return
  end
  local pal = pal256(st.stars)
  love.graphics.setColor(Gfx.color(pal[0] or 0))
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(bgImage(), 0, 0)
  drawWindows()
  if st.zoom then
    local coords = man().affineCoords[(st.areaToShow == A.CARD) and 2 or 1]
    local s = st.zoom.scale / 256
    local q = st.areaToShow == A.CARD and { 16, 10 } or { 16, 3 }
    love.graphics.push()
    love.graphics.translate(coords[1], coords[2])
    love.graphics.scale(s, s)
    love.graphics.translate(-coords[1], -coords[2])
    love.graphics.setScissor()
    local quad = love.graphics.newQuad(q[1] * 8, q[2] * 8, 96, 56, bgImage():getDimensions())
    love.graphics.draw(bgImage(), quad, q[1] * 8, q[2] * 8)
    love.graphics.pop()
  else
    drawSprites()
  end
  Kit.drawFade(st.pal, 0, 240, 160)
end

function Pass.reset()
  Pass.open = false
  Stack.pop(Pass.ID)
  Stack.pop(Pass.MAP_ID)
  for k in pairs(st) do st[k] = nil end
end

local Map = {}
Pass.Map = Map
Map.active = false

-- pokeemerald/src/frontier_pass.c:1368
function Map.show()
  Map.active = true
  Map.pos = 0
  Map.state = "fadein"
  Map.moveSteps = 0
  Map.cursorY = 8
  Map.frame = 0
  Map.pal = Kit.fade()
  Map.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.WHITE)
  Map.image = nil
  Map.head = Map.headPosition()
  Map.landmarks = {}
  for i = 0, NUM_FACILITIES - 1 do
    Map.landmarks[i] = { name = textOf(landmarkText(i, "name")), description = textOf(landmarkText(i, "description")) }
  end
end

-- pokeemerald/src/frontier_pass.c:1582
function Map.facilityOfMap(mapId)
  local m = tostring(mapId or "")
  local prefix = {
    { "EM_BATTLE_FRONTIER_BATTLE_TOWER_", 0 }, { "EM_BATTLE_FRONTIER_BATTLE_DOME_", 1 },
    { "EM_BATTLE_FRONTIER_BATTLE_PALACE_", 2 }, { "EM_BATTLE_FRONTIER_BATTLE_ARENA_", 3 },
    { "EM_BATTLE_FRONTIER_BATTLE_FACTORY_", 4 }, { "EM_BATTLE_FRONTIER_BATTLE_PIKE_", 5 },
    { "EM_BATTLE_FRONTIER_BATTLE_PYRAMID_", 6 },
  }
  for _, p in ipairs(prefix) do
    if m:sub(1, #p[1]) == p[1] then return p[2] + 1 end
  end
  return 0
end

-- pokeemerald/src/frontier_pass.c:1633
function Map.headPosition()
  local s = session()
  if not inFrontier(s) then return nil end
  local P = package.loaded["src.core.game3.player"]
  local px = P and P.cellX or tonumber(s.x) or 0
  local py = P and P.cellY or tonumber(s.y) or 0
  local female = s.gender == 1 or s.gender == "female" or s.gender == "F"
  local lm = man().landmarks
  if s.map == "EM_BATTLE_FRONTIER_OUTSIDE_WEST" or s.map == "EM_BATTLE_FRONTIER_OUTSIDE_EAST" then
    local x = (s.map == "EM_BATTLE_FRONTIER_OUTSIDE_EAST") and 55 or 0
    x = math.floor((x + px) / 8)
    local y = math.floor(py / 8)
    return { x = x * 8 + 20, y = y * 8 + 36, female = female }
  end
  local id = Map.facilityOfMap(s.map)
  if id ~= 0 then return { x = lm[id].x, y = lm[id].y, female = female } end
  local w = s.escapeWarp or {}
  local x = tonumber(w.x) or 0
  if w.map == "EM_BATTLE_FRONTIER_OUTSIDE_EAST" then x = x + 55 end
  return { x = math.floor(x / 8) * 8 + 20, y = math.floor((tonumber(w.y) or 0) / 8) * 8 + 36, female = female }
end

-- pokeemerald/src/frontier_pass.c:1743
local function moveCursor(up)
  if up then Map.pos = (Map.pos + 6) % NUM_FACILITIES else Map.pos = (Map.pos + 1) % NUM_FACILITIES end
  Map.cursorY = Map.pos * 16 + 8
  se("SE_DEX_SCROLL")
end

-- pokeemerald/src/frontier_pass.c:1512
function Map.update(inp)
  Map.frame = Map.frame + 1
  if Map.state == "fadein" then
    if not Map.pal:updateFade() then Map.state = "input" end
  elseif Map.state == "input" then
    if inp.new.b then
      se("SE_PC_OFF")
      Map.state = "exit"
      Map.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.WHITE)
    elseif inp.new.down then
      if Map.pos >= NUM_FACILITIES - 1 then moveCursor(false) else Map.state = "down" end
    elseif inp.new.up then
      if Map.pos == 0 then moveCursor(true) else Map.state = "up" end
    end
  elseif Map.state == "down" or Map.state == "up" then
    if Map.moveSteps > 3 then
      moveCursor(Map.state == "up")
      Map.moveSteps = 0
      Map.state = "input"
    else
      Map.cursorY = Map.cursorY + (Map.state == "down" and 4 or -4)
      Map.moveSteps = Map.moveSteps + 1
    end
  elseif Map.state == "exit" then
    if not Map.pal:updateFade() then
      Map.active = false
      Pass.reshow()
    end
  end
end

function Map.draw()
  local p = man().palettes
  if not Map.image then
    Map.image = gfx():renderMap(gfx():map("mapScreen"), "mapScreen", pal256(nil), { width = 32, rows = 20, backdrop = true })
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(Map.image, 0, 0)
  local lm = man().landmarks
  for i = 0, NUM_FACILITIES - 1 do
    drawText(Map.landmarks[i].name, 160 + 4, 8 + i * 16 + 1, colors(i == Map.pos and 2 or 1), "narrow")
  end
  drawText(Map.landmarks[Map.pos].description, 16 + 4, 128, colors(0))
  local cur = spriteFrame("cursor", 4, 16, 16, p.cursor)
  love.graphics.draw(cur, 155 + 8, Map.cursorY - 8, 0, -1, 1)
  local mark = lm[Map.pos + 1]
  local base = mark.animNum == 1 and 16 or 0
  local frame = (math.floor(Map.frame / 45) % 2 == 0) and base or base + 8
  local ind = spriteFrame("mapCursor", frame, 32, 16, p.mapCursor)
  love.graphics.draw(ind, mark.x - 16, mark.y - 8)
  if Map.head then
    local head = spriteFrame("heads", Map.head.female and 4 or 0, 16, 16, Map.head.female and p.femaleHead or p.maleHead)
    love.graphics.draw(head, Map.head.x - 8, Map.head.y - 8)
  end
  Kit.drawFade(Map.pal, 0, 240, 160)
end

return Pass
