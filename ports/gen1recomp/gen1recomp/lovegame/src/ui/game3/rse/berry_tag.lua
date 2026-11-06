local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local BerryTrees = require("src.core.game3.rse.berry_trees")

local Tag = { isMenu = true }

Tag.ID = "rse_berry_tag"
Tag.open = false

-- pokeemerald/src/berry_tag_screen.c:103
Tag.WIN = {
  NAME = { 11, 4, 8, 2 }, SIZE_FIRM = { 11, 7, 18, 4 }, DESC = { 4, 14, 25, 4 }, TITLE = { 2, 0, 8, 2 },
}
-- pokeemerald/src/berry_tag_screen.c:313
local BG_TILE = 0x42
-- pokeemerald/src/berry_tag_screen.c:595
local DISPLAY_SPEED = 16
-- pokeemerald/src/berry_tag_screen.c:472
Tag.CIRCLE_X = { 64, 104, 144, 184, 224 }
Tag.CIRCLE_Y = 116
-- pokeemerald/src/berry_tag_screen.c:461
Tag.PIC_X, Tag.PIC_Y = 56, 64
-- pokeemerald/include/constants/items.h:426
Tag.MAX_BERRY_INDEX = 43

local st = {}
Tag._st = st

local function gfx() return Gfx.of("rse/berry_tag") end
local function man() return gfx():manifest() end

local function se(name)
  pcall(Kit.playSe, name)
end

local function fontColors(ids)
  local p = man().palettes.font
  local function c(i)
    if i == 0 then return { 0, 0, 0, 0 } end
    return Gfx.color(p[i + 1] or 0)
  end
  return { bg = c(ids[1]), fg = c(ids[2]), shadow = c(ids[3]) }
end

local function female()
  local s = st.session
  return s and (s.gender == 1 or s.gender == "female" or s.playerGender == 1) or false
end

function Tag.berryInfo(berryId)
  return BerryTrees.info(berryId)
end

-- pokeemerald/src/berry_tag_screen.c:403
local function nameText()
  local info = Tag.berryInfo(st.berryId)
  return RomText.plain("gText_NumberVar1Var2", { stringVars = { string.format("%02d", st.berryId), info.name } })
end

-- pokeemerald/src/berry_tag_screen.c:412
function Tag.sizeParts(size)
  local inches = math.floor(1000 * (tonumber(size) or 0) / 254)
  if inches % 10 > 4 then inches = inches + 10 end
  local fraction = math.floor((inches % 100) / 10)
  return math.floor(inches / 100), fraction
end

function Tag.sizeText(size)
  if (tonumber(size) or 0) == 0 then return RomText.plain("gText_ThreeMarks") end
  local inches, fraction = Tag.sizeParts(size)
  return RomText.plain("gText_Var1DotVar2", { stringVars = { tostring(inches), tostring(fraction) } })
end

-- pokeemerald/src/berry_tag_screen.c:437
local function firmText(firmness)
  firmness = tonumber(firmness) or 0
  if firmness == 0 then return RomText.plain("gText_ThreeMarks") end
  return RomText.plain(man().firmness[firmness])
end

local function printName() st.text.name = nameText() end
local function printSize()
  st.text.size = Tag.sizeText(Tag.berryInfo(st.berryId).size)
end
local function printFirm()
  st.text.firm = firmText(Tag.berryInfo(st.berryId).firmness)
end
local function printDesc1() st.text.desc1 = Tag.berryInfo(st.berryId).description1 or "" end
local function printDesc2() st.text.desc2 = Tag.berryInfo(st.berryId).description2 or "" end
local function setCircles()
  local info = Tag.berryInfo(st.berryId)
  st.circles = { (info.spicy or 0) ~= 0, (info.dry or 0) ~= 0, (info.sweet or 0) ~= 0,
    (info.bitter or 0) ~= 0, (info.sour or 0) ~= 0 }
end
local function setPic() st.picBerry = st.berryId end

-- pokeemerald/src/berry_tag_screen.c:394
local function printAll()
  printName()
  printSize()
  printFirm()
  printDesc1()
  printDesc2()
end

local function itemAt(pos)
  return st.list and st.list[pos + 1] or nil
end

-- pokeemerald/src/berry_tag_screen.c:554
local function tryChange(toMove)
  local newPos = st.pos + toMove
  if newPos >= 0 and newPos < Tag.MAX_BERRY_INDEX and itemAt(newPos) and itemAt(newPos) ~= 0 then
    st.bgOp = (toMove < 0) and "sub" or "add"
    st.berryY = 0
    se("SE_SELECT")
    st.pos = newPos
    if st.onMove then st.onMove(toMove, newPos) end
    st.berryId = BerryTrees.itemToBerry(itemAt(newPos), st.session)
    st.phase = "scroll"
  end
end

local ADD_STEPS = {
  [3] = function() st.text.name = nil end, [4] = printName, [5] = setPic,
  [6] = function() st.text.size, st.text.firm = nil, nil end, [7] = printSize, [8] = printFirm,
  [9] = setCircles, [10] = function() st.text.desc1, st.text.desc2 = nil, nil end, [11] = printDesc1,
  [12] = printDesc2,
}
local SUB_STEPS = {
  [3] = function() st.text.desc1, st.text.desc2 = nil, nil end, [4] = printDesc2, [5] = printDesc1,
  [6] = setCircles, [7] = function() st.text.size, st.text.firm = nil, nil end, [8] = printFirm,
  [9] = printSize, [10] = setPic, [11] = function() st.text.name = nil end, [12] = printName,
}

-- pokeemerald/src/berry_tag_screen.c:597
local function scrollStep()
  st.berryY = (st.berryY + DISPLAY_SPEED) % 256
  local steps = (st.bgOp == "add") and ADD_STEPS or SUB_STEPS
  local k = st.berryY / DISPLAY_SPEED
  if steps[k] then steps[k]() end
  if st.berryY == 0 then st.phase = "input" end
end

local function step(inp)
  st.frame = st.frame + 1
  if st.fadeDir ~= 0 then
    st.fade = st.fade + st.fadeDir * 2
    if st.fade <= 0 then
      st.fade, st.fadeDir = 0, 0
    elseif st.fade >= 16 then
      st.fade, st.fadeDir = 16, 0
      Tag.finish()
    end
    return
  end
  if st.phase == "input" then
    -- pokeemerald/src/berry_tag_screen.c:537
    if inp.rep.up and not inp.held.down then
      tryChange(-1)
    elseif inp.rep.down and not inp.held.up then
      tryChange(1)
    elseif inp.new.a or inp.new.b then
      se("SE_SELECT")
      st.phase = "closing"
      st.fadeDir = 1
    end
  elseif st.phase == "scroll" then
    scrollStep()
  end
end

-- pokeemerald/src/berry_tag_screen.c:176
function Tag.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  if not st.session then
    local rt = package.loaded["src.core.game3.runtime"]
    st.session = rt and rt.getSession and rt.getSession() or nil
  end
  st.list = opts.list
  st.pos = opts.pos or 0
  st.onMove = opts.onMove
  st.onClose = opts.onClose
  st.berryId = opts.berryId or BerryTrees.itemToBerry(opts.item or itemAt(st.pos), st.session)
  st.text = {}
  printAll()
  setCircles()
  setPic()
  st.phase = "input"
  st.frame = 0
  st.fade = 16
  st.fadeDir = -1
  st.berryY = 0
  Tag.open = true
  Stack.push(Tag.ID, Tag, { hideBelow = true, fullscreen = true })
  return true
end

function Tag.isOpen()
  return Tag.open
end

function Tag.current()
  return st.berryId, st.pos
end

-- pokeemerald/src/berry_tag_screen.c:524
function Tag.finish()
  Tag.open = false
  Stack.pop(Tag.ID)
  local cb = st.onClose
  if cb then cb(st.pos) end
end

function Tag.reset()
  Tag.open = false
  Stack.pop(Tag.ID)
end

function Tag.handleInput(input)
  if not Tag.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

function Tag.update()
  if not Tag.open then return end
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  step(inp)
end

local function checkPalette()
  return Gfx.palette(man().palettes.check, {}, 0)
end

local function layers()
  if st.layers and st.layersFemale == female() then return st.layers end
  local g = gfx()
  local pal = checkPalette()
  -- pokeemerald/src/berry_tag_screen.c:339
  local fill = { n = 1024 }
  local e = ((female() and 5 or 4) * 4096) + BG_TILE
  for i = 0, 1023 do fill[i] = e end
  st.layers = {
    bg3 = g:renderMap(fill, "check", pal, { rows = 20, backdrop = true }),
    bg2 = g:renderMap(g:map("tag"), "check", pal),
    bg0 = g:renderMap(g:map("title"), "check", pal, { rows = 20 }),
  }
  st.layersFemale = female()
  return st.layers
end

-- pokeemerald/src/item_menu_icons.c:590
local function berryPic(id)
  st.pics = st.pics or {}
  if st.pics[id] then return st.pics[id] end
  local m = man()
  local pal = m.berryPals[id] or m.berryPals[1]
  local img = gfx():sprite("berries", 0, 48, 48, pal, { tilesWide = 6, byteOffset = (id - 1) * 6 * 6 * 32 })
  st.pics[id] = img
  return img
end

local function drawWrapped(img, y)
  love.graphics.draw(img, 0, y)
  love.graphics.draw(img, 0, y + 256)
  love.graphics.draw(img, 0, y - 256)
end

local function drawText(text, W, dx, dy, yoff, colors)
  if not text or text == "" then return end
  local x, y = W[1] * 8 + dx, W[2] * 8 + dy
  for _, off in ipairs({ 0, 256, -256 }) do
    local yy = y + yoff + off
    if yy > -16 and yy < 160 then FrlgFont.draw(text, x, yy, { colors = colors }) end
  end
end

function Tag.draw()
  if not Tag.open then return end
  local L = layers()
  local y = 0
  if st.phase == "scroll" then y = (st.bgOp == "add") and -st.berryY or st.berryY end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(L.bg3, 0, 0)
  drawWrapped(L.bg2, y)
  local c0 = fontColors({ 0, 2, 3 })
  drawText(st.text.name, Tag.WIN.NAME, 0, 1, y, c0)
  if st.text.size then
    drawText(RomText.plain("gText_SizeSlash"), Tag.WIN.SIZE_FIRM, 0, 1, y, c0)
    drawText(st.text.size, Tag.WIN.SIZE_FIRM, 0x28, 1, y, c0)
  end
  if st.text.firm then
    drawText(RomText.plain("gText_FirmSlash"), Tag.WIN.SIZE_FIRM, 0, 0x11, y, c0)
    drawText(st.text.firm, Tag.WIN.SIZE_FIRM, 0x28, 0x11, y, c0)
  end
  drawText(st.text.desc1, Tag.WIN.DESC, 0, 1, y, c0)
  drawText(st.text.desc2, Tag.WIN.DESC, 0, 0x11, y, c0)
  local pic = berryPic(st.picBerry)
  if pic then love.graphics.draw(pic, Tag.PIC_X - 32 + 8, Tag.PIC_Y - 32 + 8 + y) end
  local m = man()
  local circle = gfx():sprite("circle", 0, 64, 64, { unpack(m.palettes.check, 1, 16) })
  for i, x in ipairs(Tag.CIRCLE_X) do
    if st.circles[i] then love.graphics.draw(circle, x - 32, Tag.CIRCLE_Y - 32 + y) end
  end
  love.graphics.draw(L.bg0, 0, 0)
  -- pokeemerald/src/berry_tag_screen.c:385
  local W = Tag.WIN.TITLE
  local fp = m.palettes.font
  love.graphics.setColor(Gfx.color(fp[16]))
  love.graphics.rectangle("fill", W[1] * 8, W[2] * 8, W[3] * 8, W[4] * 8)
  love.graphics.setColor(1, 1, 1, 1)
  local title = RomText.plain("gText_BerryTag")
  FrlgFont.draw(title, W[1] * 8 + math.floor((0x40 - FrlgFont.measure(title)) / 2), W[2] * 8 + 1,
    { colors = fontColors({ 15, 14, 13 }) })
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return Tag
