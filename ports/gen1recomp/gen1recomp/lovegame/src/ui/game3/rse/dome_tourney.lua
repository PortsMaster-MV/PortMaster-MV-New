local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local PalFade = require("src.core.game3.pal_fade")

local UI = {}

UI.ID = "rse_dome_tourney"
UI.open = false

-- pokeemerald/include/constants/battle_dome.h:74
UI.CLOSE_BUTTON = 31
-- pokeemerald/include/constants/text.h:26
local COLOR = { TRANSPARENT = 0, LIGHT_GRAY = 3, RED = 4, DYNAMIC_2 = 11, DYNAMIC_4 = 13, DYNAMIC_5 = 14 }
local TRAINERS, MATCHES = 16, 15

local st = {}
UI._st = st

local function G() return Gfx.of("rse/frontier_f2") end
local function man() return G():manifest() end
local function M() return man().dome end
local function Dome() return require("src.core.game3.rse.frontier.dome") end
local function D() return require("src.core.game3.rse.frontier.trainers") end

local function se(name) pcall(Kit.playSe, name) end

local function session()
  if st.session then return st.session end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function textOf(ir, vars)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local s = session()
  return TextIR.toPlain(ir or {}, { playerName = s and s.name, stringVars = vars or {} })
end

-- pokeemerald/src/battle_dome.c:5382
local function wtColor(i)
  return Gfx.color(M().palettes.windowText[i + 1] or 0)
end

local function colors(fg, shadow)
  return { fg = wtColor(fg), shadow = wtColor(shadow), bg = { 0, 0, 0, 0 } }
end

local function chars(s)
  local out = {}
  for ch in tostring(s or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch end
  return out
end

local function measure(s, font, ls)
  local w = 0
  for _, ch in ipairs(chars(s)) do w = w + FrlgFont.measure(ch, { font = font }) + (ls or 0) end
  return w
end

-- pokeemerald/src/text.c:1018
local function drawSpaced(s, x, y, c, font, ls)
  if (ls or 0) == 0 then
    FrlgFont.draw(s, x, y, { font = font, colors = c })
    return
  end
  local pen = x
  for _, ch in ipairs(chars(s)) do
    FrlgFont.draw(ch, pen, y, { font = font, colors = c })
    pen = pen + FrlgFont.measure(ch, { font = font }) + ls
  end
end

-- pokeemerald/src/text.c:1154
local function centerX(s, width, font, ls)
  return math.floor((width - measure(s, font, ls)) / 2)
end

local function bgPal(matchMode)
  local list = M().palettes.tree
  local pal = {}
  for i = 1, #list do pal[i - 1] = list[i] end
  local wt = M().palettes.windowText
  for i = 1, 16 do pal[15 * 16 + i - 1] = wt[i] end
  if matchMode then
    local mc = M().palettes.matchCardBg
    for i = 1, 16 do pal[5 * 16 + i - 1] = mc[i] end
  end
  return pal
end

local function objPal(bank)
  local list = M().palettes.buttons
  local out = {}
  for i = 1, 16 do out[i] = list[bank * 16 + i] or 0 end
  return out
end

local function wrapDraw(img, sx, sy, x0, y0)
  local w, h = img:getDimensions()
  local ox = -(sx % w)
  local oy = -(sy % h)
  for yy = oy, 160, h do
    for xx = ox, 240, w do love.graphics.draw(img, x0 + xx, y0 + yy) end
  end
end

-- pokeemerald/src/battle_dome.c:5565
local function applyLine(map, tid, round)
  if round < 0 or round > 3 then return end
  for _, sec in ipairs(M().lineSections[tid + 1][round + 1] or {}) do
    map[sec.y * 32 + sec.x] = sec.tile
  end
end

local function trainerName(s, trainerId)
  return Dome().trainerName(s, trainerId)
end

-- pokeemerald/src/battle_dome.c:5334
local function buildTree(mode)
  local s = session()
  local f = Dome().frontier(s)
  local cur = tonumber(f.curChallengeBattleNum) or 0
  local map = G():map("tree")
  local names = {}
  local notInteractive = mode == "static"
  local prev = mode == "prev"
  for i = 0, TRAINERS - 1 do
    local t = f.domeTrainers[i + 1]
    if notInteractive then
      if t.isEliminated then
        if t.eliminatedAt ~= 0 then applyLine(map, i, t.eliminatedAt - 1) end
      elseif cur ~= 1 then
        applyLine(map, i, cur - 2)
      end
    else
      if t.isEliminated then
        if t.eliminatedAt ~= 0 then applyLine(map, i, t.eliminatedAt - 1) end
      elseif cur ~= 0 then
        applyLine(map, i, prev and cur or cur - 1)
      end
    end
    local roundId = prev and cur or cur - 1
    local gray = t.isEliminated and ((notInteractive and t.eliminatedAt < cur - 1) or (not notInteractive and t.eliminatedAt <= roundId))
    local c
    if t.trainerId == D().TRAINER_PLAYER then c = colors(COLOR.LIGHT_GRAY, COLOR.RED)
    elseif gray then c = colors(COLOR.DYNAMIC_2, COLOR.DYNAMIC_4)
    else c = colors(COLOR.DYNAMIC_5, COLOR.DYNAMIC_4) end
    names[i] = { text = trainerName(s, t.trainerId), colors = c }
  end
  st.treeMap = map
  st.names = names
  st.treeImage = nil
end

-- pokeemerald/src/battle_dome.c:5608
local function staticResults()
  local s = session()
  local f = Dome().frontier(s)
  local cur = tonumber(f.curChallengeBattleNum) or 0
  for i = 0, TRAINERS - 1 do
    local t = f.domeTrainers[i + 1]
    if t.eliminatedAt == cur - 1 and t.isEliminated then
      st.names[i].colors = colors(COLOR.DYNAMIC_2, COLOR.DYNAMIC_4)
    end
    if not t.isEliminated then applyLine(st.treeMap, i, cur - 1) end
  end
  st.treeImage = nil
end

local function treeImage()
  if st.treeImage then return st.treeImage end
  st.treeImage = G():renderMap(st.treeMap, "tree", bgPal(false), { width = 32, rows = 32 })
  return st.treeImage
end

local function lineImage(key)
  st.lineImages = st.lineImages or {}
  local hit = st.lineImages[key]
  if hit then return hit end
  hit = G():renderMap(G():map(key), "line", bgPal(false), { width = 32, rows = 32 })
  st.lineImages[key] = hit
  return hit
end

-- pokeemerald/src/battle_dome.c:5690
local BANDS = {
  { 42, 50, "bg3", { { 152, 155 }, { 85, 88 } } },
  { 58, 75, "bg3", { { 144, 152 }, { 88, 96 } } },
  { 75, 82, "bg3", { { 152, 155 }, { 85, 88 } } },
  { 95, 103, "bg2", { { 152, 155 }, { 85, 88 } } },
  { 103, 119, "bg2", { { 144, 152 }, { 88, 96 } } },
  { 127, 135, "bg2", { { 152, 155 }, { 85, 88 } } },
}

local function bandAt(y)
  for _, b in ipairs(BANDS) do
    if y >= b[1] and y < b[2] then return b end
  end
  return nil
end

local function drawLines()
  local bg2, bg3 = lineImage("lineDown"), lineImage("lineUp")
  local y2 = st.bg2y or 0
  local y3 = st.bg3y or 11
  local function layer(img, sy, x0, y0, x1, y1)
    love.graphics.setScissor(x0, y0, x1 - x0, y1 - y0)
    wrapDraw(img, 0, sy, 0, 0)
  end
  local y = 0
  while y < 160 do
    local band = bandAt(y)
    local nextY = 160
    for _, b in ipairs(BANDS) do
      if b[1] > y and b[1] < nextY then nextY = b[1] end
      if b[1] <= y and b[2] > y and b[2] < nextY then nextY = b[2] end
    end
    if nextY == 91 or (y < 91 and nextY > 91) then nextY = math.min(nextY, 91) end
    if y < 91 and nextY > 91 then nextY = 91 end
    local inside = {}
    if band then inside = band[4] end
    local xs = { 0 }
    local cuts = {}
    for _, r in ipairs(inside) do cuts[#cuts + 1] = r end
    table.sort(cuts, function(a, b) return a[1] < b[1] end)
    local x = 0
    local function outside(x0, x1)
      if x1 <= x0 then return end
      if y < 91 then
        layer(bg3, y3, x0, y, x1, nextY)
        layer(bg2, y2, x0, y, x1, nextY)
      else
        layer(bg2, y2, x0, y, x1, nextY)
        layer(bg3, y3, x0, y, x1, nextY)
      end
    end
    for _, r in ipairs(cuts) do
      outside(x, r[1])
      if band[3] == "bg3" then layer(bg3, y3, r[1], y, r[2], nextY) else layer(bg2, y2, r[1], y, r[2], nextY) end
      x = r[2]
    end
    outside(x, 240)
    local _ = xs
    y = nextY
  end
  love.graphics.setScissor()
end

local function spriteImg(template, animIdx, frameIdx)
  local anim = template.anims[animIdx] or template.anims[1] or {}
  local frames = {}
  for _, c in ipairs(anim) do if c.op == "frame" then frames[#frames + 1] = c end end
  local fr = frames[((frameIdx or 0) % math.max(1, #frames)) + 1] or { tile = 0 }
  local oam = template.oam
  return G():sprite("buttons", fr.tile, oam.w, oam.h, objPal(oam.paletteNum or 0)), oam, frames
end

local function drawTreeSprites()
  local T = M().sprites
  local coords = M().pokeballCoords
  local blink = math.floor((st.frame or 0) / 16)
  for i = 0, TRAINERS + MATCHES - 1 do
    local c = coords[i + 1]
    local img, oam = spriteImg(T.pokeball, (st.cursor == i) and 2 or 1, blink)
    love.graphics.draw(img, c[1] - oam.w / 2, c[2] - oam.h / 2)
  end
  local tpl = st.mode == "prev" and T.exit or T.cancel
  local img, oam = spriteImg(tpl, (st.cursor == UI.CLOSE_BUTTON) and 2 or 1, blink)
  love.graphics.draw(img, 218 - oam.w / 2, 12 - oam.h / 2)
end

local function drawTree()
  local pal = bgPal(false)
  love.graphics.setColor(Gfx.color(pal[0] or 0))
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  drawLines()
  love.graphics.draw(treeImage(), 0, 0)
  local W = M().treeWindows
  local title = st.treeTitle
  local tw = W[3]
  drawSpaced(title, tw.left * 8 + centerX(title, 0x70, "short", 2), tw.top * 8 + 1,
    colors(COLOR.DYNAMIC_5, COLOR.DYNAMIC_4), "short", 2)
  local pos = M().namePositions
  for i = 0, TRAINERS - 1 do
    local n = st.names[i]
    local w = W[pos[i + 1][1] + 1]
    local x
    if pos[i + 1][1] == Dome().WIN.NAMES_LEFT then x = 0x3D - measure(n.text, "short", 2) else x = 3 end
    drawSpaced(n.text, w.left * 8 + x, w.top * 8 + pos[i + 1][2], n.colors, "short", 2)
  end
  if st.mode ~= "static" then drawTreeSprites() end
end

-- pokeemerald/src/battle_dome.c:4316
local function trainerCardData(tid)
  return Dome().trainerCard(session(), tid)
end

local function cardRegion(kind)
  st.cardImage = st.cardImage or {}
  local hit = st.cardImage[kind]
  if hit then return hit end
  local raw = G():map("card")
  local grid = { n = 64 * 64 }
  for ty = 0, 63 do
    for tx = 0, 63 do
      local blk = math.floor(ty / 32) * 2 + math.floor(tx / 32)
      grid[ty * 64 + tx] = raw[blk * 1024 + (ty % 32) * 32 + (tx % 32)] or 0
    end
  end
  local oy = kind == "trainer" and 20 or 0
  local sub = { n = 32 * 20 }
  for ty = 0, 19 do
    for tx = 0, 31 do sub[ty * 32 + tx] = grid[(ty + oy) * 64 + tx] end
  end
  hit = G():renderMap(sub, "card", bgPal(kind == "match"), { width = 32, rows = 20 })
  st.cardImage[kind] = hit
  return hit
end

local function cardBgImage(matchMode)
  local key = matchMode and "bgMatch" or "bgTrainer"
  st.cardImage = st.cardImage or {}
  local hit = st.cardImage[key]
  if hit then return hit end
  hit = G():renderMap(G():map("cardBg"), "card", bgPal(matchMode), { width = 32, rows = 32 })
  st.cardImage[key] = hit
  return hit
end

local function playerFrontPic(s)
  local C = D().constants(s)
  local gender = s and (s.gender or s.playerGender)
  local female = gender == 1 or gender == "female" or gender == "F" or gender == "girl"
  return C:require("trainer_classes", female and "TRAINER_PIC_MAY" or "TRAINER_PIC_BRENDAN")
end

local function picFor(trainerId)
  local s = session()
  if trainerId == D().TRAINER_PLAYER then return playerFrontPic(s) end
  if trainerId == D().TRAINER_FRONTIER_BRAIN then return Dome().brainTrainer().pic or 0 end
  return D().frontSpriteId(s, trainerId, D().FACILITY.DOME)
end

local function drawPic(picId, cx, cy, lost)
  local TrainerPic = require("src.core.game3.trainer_pic")
  local pic = TrainerPic.front(picId)
  if not (pic and pic.image) then return end
  if lost then
    Kit.drawTinted(pic.image, nil, cx - 32, cy - 32, 0.5, { 0.4, 0.4, 0.4 })
  else
    love.graphics.draw(pic.image, cx - 32, cy - 32)
  end
end

local function drawIcon(species, cx, cy, still)
  local Pokemon = require("src.core.game3.pokemon")
  local icon = Pokemon.icon(species)
  if not (icon and icon.image) then return end
  local f = still and 0 or (math.floor((st.frame or 0) / 8) % (icon.frames or 1))
  local q = icon.quads[f] or icon.quads[0]
  if still then
    Kit.drawTinted(icon.image, q, cx - 16, cy - 16, 0.5, { 0.4, 0.4, 0.4 })
  else
    love.graphics.draw(icon.image, q, cx - 16, cy - 16)
  end
end

local function winText(win, text, x, y, c, font, ls, ox, oy)
  drawSpaced(text, ox + win.left * 8 + x, oy + win.top * 8 + y, c, font, ls)
end

-- pokeemerald/src/battle_dome.c:4316
local function drawTrainerCard(card, ox, oy)
  love.graphics.draw(cardRegion("trainer"), ox, oy)
  local W = M().cardWindows
  local c = colors(COLOR.DYNAMIC_5, COLOR.DYNAMIC_4)
  local d = card.data
  winText(W[1], d.title, centerX(d.title, 0xD0, "short", 2), 0, c, "short", 2, ox, oy)
  local ys = M().speciesNameY
  local Pokemon = require("src.core.game3.pokemon")
  for i = 1, 3 do
    local name = Pokemon.name(d.species[i]) or ""
    winText(W[1 + i], name, (i == 2) and 7 or 0, ys[i], c, "short", 0, ox, oy)
  end
  local fw = W[5]
  winText(fw, textOf(d.potential), 0, 4, c, "normal", 0, ox, oy)
  winText(fw, textOf(d.styleText), 0, 20, c, "normal", 0, ox, oy)
  winText(fw, textOf(d.statText), 0, 36, c, "normal", 0, ox, oy)
  drawPic(picFor(d.trainerId), ox + 48, oy + 64, false)
  local mx, my = M().infoTrainerMonX, M().infoTrainerMonY
  for i = 1, 3 do drawIcon(d.species[i], ox + mx[i], oy + my[i], false) end
end

-- pokeemerald/src/battle_dome.c:4777
local function matchCardData(matchNo)
  local s = session()
  local f = Dome().frontier(s)
  local ws = Dome().winString(s, matchNo)
  local range = M().competitorRange[matchNo + 1]
  local out = { matchNo = matchNo, win = ws, sides = {} }
  for i = 1, 2 do
    local tid = ws.tournamentIds[i] or 0
    local t = f.domeTrainers[tid + 1]
    local species = {}
    for k = 1, 3 do
      if t.trainerId == D().TRAINER_PLAYER or t.trainerId == D().TRAINER_FRONTIER_BRAIN then
        species[k] = f.domeMonIds[tid + 1][k]
      else
        species[k] = Dome().facilityMon(s, f.domeMonIds[tid + 1][k]).species
      end
    end
    out.sides[i] = { tournamentId = tid, trainerId = t.trainerId, species = species,
      lost = t.eliminatedAt <= range[3] and t.isEliminated, name = trainerName(s, t.trainerId) }
  end
  return out
end

local function drawMatchCard(card, ox, oy)
  love.graphics.draw(cardRegion("match"), ox, oy)
  local W = M().cardWindows
  local c = colors(COLOR.DYNAMIC_5, COLOR.DYNAMIC_4)
  local d = card.data
  local wt = textOf(d.winIr, { d.win.var1, d.win.var2 })
  winText(W[9], wt, 0, 0, c, "normal", 0, ox, oy)
  local left, right = d.sides[1], d.sides[2]
  winText(W[7], left.name, centerX(left.name, 0x40, "short", 2), 2, c, "short", 2, ox, oy)
  winText(W[8], right.name, centerX(right.name, 0x40, "short", 2), 2, c, "short", 2, ox, oy)
  local mn = textOf(d.matchNoIr)
  winText(W[6], mn, centerX(mn, 0xA0, "short", 0), 2, c, "short", 0, ox, oy)
  drawPic(picFor(left.trainerId), ox + 48, oy + 88, left.lost)
  drawPic(picFor(right.trainerId), ox + 192, oy + 88, right.lost)
  local lx, ly, rx, ry = M().leftMonX, M().leftMonY, M().rightMonX, M().rightMonY
  for i = 1, 3 do
    drawIcon(left.species[i], ox + lx[i], oy + ly[i], left.lost)
    drawIcon(right.species[i], ox + rx[i], oy + ry[i], right.lost)
  end
end

local function makeCard(kind, id)
  if kind == "trainer" then return { kind = kind, id = id, data = trainerCardData(id) } end
  local data = matchCardData(id)
  local Dome = require("src.core.game3.rse.frontier.dome")
  -- pokeemerald/src/battle_dome.c:4931, :4977
  data.winIr = Dome.tableText(M().text.wins, "sBattleDomeWinTexts", data.win.id + 1)
  data.matchNoIr = Dome.tableText(M().text.matchNumbers, "sBattleDomeMatchNumberTexts", data.matchNo + 1)
  return { kind = kind, id = id, data = data }
end

-- pokeemerald/src/battle_dome.c:5415
local function treeTitle()
  return textOf(require("src.core.game3.rom_text").irOr("gText_BattleTourney", M().text.battleTourney))
end

local function drawCard(card, ox, oy)
  if card.kind == "trainer" then drawTrainerCard(card, ox, oy) else drawMatchCard(card, ox, oy) end
end

local function drawArrows()
  if st.cardMode == "next" then return end
  local T = M().sprites
  local vis = st.arrows or {}
  local blink = math.floor((st.frame or 0) / 16)
  local function put(tpl, anim, x, y, show)
    if not show then return end
    local img, oam = spriteImg(tpl, anim, blink)
    love.graphics.draw(img, x - oam.w / 2, y - oam.h / 2)
  end
  put(T.vArrow, 1, 120, 4, vis.up)
  put(T.vArrow, 2, 120, 156, vis.down)
  put(T.hArrow, 1, 6, 80, vis.left)
  put(T.hArrow, 2, 234, 80, vis.right)
end

-- pokeemerald/src/battle_dome.c:3351
local function updateArrows()
  local s = session()
  local f = Dome().frontier(s)
  local cur = tonumber(f.curChallengeBattleNum) or 0
  local a = {}
  if st.cardMode == "trainer" then
    local t = f.domeTrainers[M().treeTrainerIds[st.cursor + 1] + 1]
    a.up, a.down = st.pos == 0, st.pos == 0
    a.left = st.pos ~= 0
    a.right = (t.isEliminated and st.pos - 1 < t.eliminatedAt) or ((not t.isEliminated) and st.pos - 1 < cur)
  elseif st.cardMode == "match" then
    a.up, a.down = st.pos == 1, st.pos == 1
    a.left = st.pos ~= 0
    a.right = st.pos <= 1
  end
  st.arrows = a
end

local function drawCardScreen()
  local matchMode = st.cardMode == "match"
  local bg = cardBgImage(matchMode)
  wrapDraw(bg, st.bg3x or 0, st.bg3y or 0, 0, 0)
  if st.slide then
    local sl = st.slide
    drawCard(sl.from, sl.fx, sl.fy)
    drawCard(sl.to, sl.tx, sl.ty)
  elseif st.card then
    drawCard(st.card, 0, 0)
  end
  if not st.slide then drawArrows() end
end

function UI.isOpen()
  return UI.open
end

local function push()
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.clear then Fade.clear() end
  UI.open = true
  if not Stack.has(UI.ID) then Stack.push(UI.ID, UI, { hideBelow = true, fullscreen = true }) end
end

local function close()
  UI.open = false
  Stack.pop(UI.ID)
  -- pokeemerald/src/overworld.c:1720
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.begin then Fade.begin(Fade.MODE.FROM_BLACK, 1) end
  local cb = st.onClose
  st.onClose = nil
  if cb then cb() end
end

local function fadeIn()
  st.pal = Kit.fade()
  st.pal:beginFade(PalFade.ALL, 0, 16, 0, PalFade.BLACK)
end

local function fadeOut()
  st.pal:beginFade(PalFade.ALL, 0, 0, 16, PalFade.BLACK)
end

-- pokeemerald/src/battle_dome.c:4986
function UI.showTree(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  st.onClose = opts.onClose
  st.mode = opts.mode or "interactive"
  st.screen = "tree"
  st.cursor = opts.cursor or 0
  st.frame, st.bg2y, st.bg3y = 0, 0, 11
  buildTree(st.mode)
  st.treeTitle = treeTitle()
  st.phase = "fadein"
  fadeIn()
  push()
  return true
end

-- pokeemerald/src/battle_dome.c:3043
function UI.showCard(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  st.onClose = opts.onClose
  st.screen = "card"
  st.cardMode = opts.mode or "next"
  st.frame, st.bg3x, st.bg3y = 0, 0, 0
  if st.cardMode == "match" then
    st.card = makeCard("match", opts.id)
    st.pos = 1
  else
    st.card = makeCard("trainer", opts.id)
    st.pos = 0
  end
  st.phase = "fadein"
  fadeIn()
  push()
  return true
end

local function openCardFromTree(kind)
  st.returnTree = { mode = st.mode, cursor = st.cursor }
  st.screen = "card"
  st.cardImage = nil
  st.bg3x, st.bg3y = 0, 0
  if kind == "trainer" then
    st.cardMode = "trainer"
    st.card = makeCard("trainer", M().treeTrainerIds[st.cursor + 1])
    st.pos = 0
  else
    st.cardMode = "match"
    st.card = makeCard("match", st.cursor - TRAINERS)
    st.pos = 1
  end
  st.phase = "fadein"
  fadeIn()
end

local function backToTree()
  local rt = st.returnTree
  st.returnTree = nil
  st.screen = "tree"
  st.card, st.slide = nil, nil
  st.cursor = rt.cursor
  st.mode = rt.mode
  st.bg2y, st.bg3y = 0, 11
  buildTree(st.mode)
  st.treeTitle = st.treeTitle or treeTitle()
  st.phase = "fadein"
  fadeIn()
end

-- pokeemerald/src/battle_dome.c:5125
local function treeInput(inp)
  local s = session()
  local cur = tonumber(Dome().frontier(s).curChallengeBattleNum) or 0
  local new = inp.new
  if new.b or (new.a and st.cursor == UI.CLOSE_BUTTON) then
    se("SE_SELECT")
    st.next = "close"
    st.phase = "fadeout"
    fadeOut()
    return
  end
  if new.a then
    se("SE_SELECT")
    st.next = st.cursor < TRAINERS and "trainer" or "match"
    st.phase = "fadeout"
    fadeOut()
    return
  end
  local row = M().cursorMap[st.cursor + 1][cur + 1]
  local dir
  if new.up and row[1] ~= 0xFF then dir = 1
  elseif new.down and row[2] ~= 0xFF then dir = 2
  elseif new.left and row[3] ~= 0xFF then dir = 3
  elseif new.right and row[4] ~= 0xFF then dir = 4 end
  if dir then
    se("SE_SELECT")
    st.cursor = row[dir]
  end
end

local function startSlide(to, dx, dy, frames)
  st.slide = { from = st.card, to = to, fx = 0, fy = 0, tx = -dx * frames, ty = -dy * frames, dx = dx, dy = dy,
    n = frames }
  st.card = to
end

-- pokeemerald/src/battle_dome.c:4192
local function cardInput(inp)
  local s = session()
  local f = Dome().frontier(s)
  local cur = tonumber(f.curChallengeBattleNum) or 0
  local new = inp.new
  if new.a or new.b then
    if st.cardMode ~= "next" and st.returnTree then
      local position = st.cursor
      if st.cardMode == "trainer" then
        if st.pos ~= 0 then
          position = M().trainerAndRoundToLastMatchCardNum[math.floor(position / 2) + 1][st.pos]
        end
      else
        local ids = Dome().winString(s, st.cursor - TRAINERS).tournamentIds
        if st.pos == 0 then position = M().pairedTrainerIds[(ids[1] or 0) + 1]
        elseif st.pos == 2 then position = M().pairedTrainerIds[(ids[2] or 0) + 1] end
      end
      st.returnTree.cursor = position
    end
    st.next = "back"
    st.phase = "fadeout"
    fadeOut()
    return
  end
  if st.cardMode == "next" then return end
  local position = st.cursor
  local moved
  if st.cardMode == "trainer" then
    local tid = M().treeTrainerIds[position + 1]
    local t = f.domeTrainers[tid + 1]
    if new.up and st.pos == 0 then
      position = (position == 0) and (TRAINERS - 1) or (position - 1)
      st.cursor = position
      startSlide(makeCard("trainer", M().treeTrainerIds[position + 1]), 0, 4, 40)
      moved = true
    elseif new.down and st.pos == 0 then
      position = (position == TRAINERS - 1) and 0 or (position + 1)
      st.cursor = position
      startSlide(makeCard("trainer", M().treeTrainerIds[position + 1]), 0, -4, 40)
      moved = true
    elseif new.left and st.pos ~= 0 then
      st.pos = st.pos - 1
      if st.pos == 0 then
        startSlide(makeCard("trainer", tid), 4, 0, 64)
      else
        startSlide(makeCard("match", M().idToMatchNumber[position + 1][st.pos]), 4, 0, 64)
      end
      moved = true
    elseif new.right and ((t.isEliminated and st.pos - 1 < t.eliminatedAt) or (not t.isEliminated and st.pos - 1 < cur)) then
      st.pos = st.pos + 1
      startSlide(makeCard("match", M().idToMatchNumber[position + 1][st.pos]), -4, 0, 64)
      moved = true
    end
  else
    local matchNo = position - TRAINERS
    local function side(i) return Dome().winString(s, matchNo).tournamentIds[i] or 0 end
    if new.up and st.pos == 1 then
      position = (position == TRAINERS) and M().lastMatchCardNum[cur + 1] or (position - 1)
      st.cursor = position
      startSlide(makeCard("match", position - TRAINERS), 0, 4, 40)
      moved = true
    elseif new.down and st.pos == 1 then
      position = (position == M().lastMatchCardNum[cur + 1]) and TRAINERS or (position + 1)
      st.cursor = position
      startSlide(makeCard("match", position - TRAINERS), 0, -4, 40)
      moved = true
    elseif new.left and st.pos ~= 0 then
      st.pos = st.pos - 1
      if st.pos == 0 then
        startSlide(makeCard("trainer", side(1)), 4, 0, 64)
      else
        startSlide(makeCard("match", matchNo), 4, 0, 64)
      end
      moved = true
    elseif new.right and (st.pos == 0 or st.pos == 1) then
      st.pos = st.pos + 1
      if st.pos == 1 then
        startSlide(makeCard("match", matchNo), -4, 0, 64)
      else
        startSlide(makeCard("trainer", side(2)), -4, 0, 64)
      end
      moved = true
    end
  end
  if moved then se("SE_SELECT") end
end

function UI.handleInput(input)
  if not UI.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

function UI.update()
  if UI.open then
    st.frame = (st.frame or 0) + 1
    local inp = st.input or { new = {}, held = {}, rep = {} }
    st.input = nil
    if st.screen == "tree" then
      -- pokeemerald/src/battle_dome.c:5762
      st.bg2y = (st.bg2y or 0) - 0.5
      st.bg3y = (st.bg3y or 0) + 0.5
    else
      -- pokeemerald/src/battle_dome.c:5670
      st.bg3x = (st.bg3x or 0) + 0.5
      st.bg3y = (st.bg3y or 0) - 0.5
    end
    if st.phase == "fadein" then
      if not st.pal:updateFade() then
        if st.screen == "tree" and st.mode == "static" then
          staticResults()
          st.phase, st.delay = "delay", 64
        else
          st.phase = "input"
        end
      end
    elseif st.phase == "delay" then
      st.delay = st.delay - 1
      if st.delay <= 0 then st.phase = "wait" end
    elseif st.phase == "wait" then
      if inp.new.a or inp.new.b then
        st.next = "close"
        st.phase = "fadeout"
        fadeOut()
      end
    elseif st.phase == "input" then
      if st.screen == "tree" then
        treeInput(inp)
      elseif st.slide then
        local sl = st.slide
        sl.fx, sl.fy = sl.fx + sl.dx, sl.fy + sl.dy
        sl.tx, sl.ty = sl.tx + sl.dx, sl.ty + sl.dy
        sl.n = sl.n - 1
        if sl.n <= 0 then st.slide = nil end
      else
        cardInput(inp)
      end
      if st.screen == "card" then updateArrows() end
    elseif st.phase == "fadeout" then
      if not st.pal:updateFade() then
        local nxt = st.next
        st.next = nil
        if nxt == "trainer" or nxt == "match" then
          openCardFromTree(nxt)
        elseif nxt == "back" and st.returnTree then
          backToTree()
        else
          close()
        end
      end
    end
  end
end

function UI.draw()
  if not UI.open then return end
  love.graphics.setColor(1, 1, 1, 1)
  if st.screen == "tree" then drawTree() else drawCardScreen() end
  if st.pal then Kit.drawFade(st.pal, 0, 240, 160) end
end

function UI.reset()
  UI.open = false
  for k in pairs(st) do st[k] = nil end
  UI.confetti = nil
end

-- pokeemerald/src/hall_of_fame.c:1412
function UI.startConfetti(frames)
  UI.confetti = { timer = frames, list = {}, count = 0, clock = nil, frame = 0 }
  local UiPass = require("src.ui.game3.ui_pass")
  if UiPass._domeConfetti then return end
  local orig = UiPass.drawUi
  UiPass.drawUi = function(...)
    local r = { orig(...) }
    local ok, err = pcall(UI.drawConfetti)
    if not ok then print("[game3/dome_tourney] confetti draw failed: " .. tostring(err)) end
    return (table.unpack or unpack)(r)
  end
  UiPass._domeConfetti = true
end

-- pokeemerald/src/hall_of_fame.c:1437
function UI.stepConfetti()
  local c = UI.confetti
  if not c then return end
  local Rng = require("src.core.game3.rng")
  local anims = man().confetti.anims
  if c.timer ~= 0 and c.timer % 3 == 0 then
    local e = { x = Rng.Random() % 240, y = -(Rng.Random() % 8), anim = Rng.Random() % #anims, dy = 0, dx = 0,
      sine = 0, extra = (Rng.Random() % 4 == 0) and 1 or 0 }
    c.list[#c.list + 1] = e
    c.count = c.count + 1
  end
  local keep = {}
  for _, e in ipairs(c.list) do
    if e.dy > 110 then
      c.count = c.count - 1
    else
      e.dy = e.dy + 1 + e.extra
      local rand = (Rng.Random() % 4) + 8
      local sine = math.floor(math.sin((e.sine % 256) / 256 * 2 * math.pi) * 256)
      e.dx = math.floor(rand * sine / 256)
      e.sine = e.sine + 4
      keep[#keep + 1] = e
    end
  end
  c.list = keep
  if c.timer ~= 0 then c.timer = c.timer - 1
  elseif c.count == 0 then UI.confetti = nil end
end

function UI.drawConfetti()
  local c = UI.confetti
  if not c then return end
  local now = love.timer and love.timer.getTime() or 0
  c.clock = c.clock or now
  local steps = math.floor((now - c.clock) * 60)
  if steps > 0 then
    c.clock = c.clock + steps / 60
    for _ = 1, math.min(steps, 8) do UI.stepConfetti() end
  end
  if not UI.confetti then return end
  local conf = man().confetti
  local pal = conf.pal
  for _, e in ipairs(c.list) do
    local anim = conf.anims[e.anim + 1] or {}
    local fr
    for _, cmd in ipairs(anim) do if cmd.op == "frame" then fr = cmd break end end
    local tile = fr and fr.tile or 0
    local img = G():sprite("confetti", tile, 8, 8, pal)
    love.graphics.draw(img, e.x + e.dx - 4, e.y + e.dy - 4)
  end
end

return UI
