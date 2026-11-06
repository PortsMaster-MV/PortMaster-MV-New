local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Items = require("src.core.game3.items_data")
local Pal = require("src.core.game3.pal_fade")
local Fx = require("src.core.game3.gba_fx")
local Data = require("src.ui.game3.rs.berry_tag_data")
local Tag = {ID = "rs_berry_tag", isMenu = true, open = false}
local st = {}
Tag._st = st

local function manifest()
  local man = assert(Kit.manifest("rse/berry_tag"), "native RS berry-tag assets missing")
  assert(man.assetLayout == "rs", "native RS berry-tag layout required")
  return man
end
local function play() Kit.playSe("SE_SELECT") end
local function itemAt(pos) return st.list and st.list[pos + 1] end
local function berryId(item)
  local id = assert(Items.toNumericId(item), "native RS berry tag requires an item ID")
  assert(id >= st.man.firstItem and id <= st.man.lastItem, "item is outside native RS berry pocket")
  return id - st.man.firstItem + 1
end

function Tag.berryInfo(id)
  local m = st.man or manifest()
  id = math.floor(tonumber(id) or 0) % 256
  if id == 43 then
    local e = st.enigma or Data.enigma(st.session)
    if e then return e end
  end
  if id == 0 or id > 43 then id = 1 end
  return assert(m.berries[id], "native RS berry record missing")
end
Tag.sizeParts = Data.sizeParts
function Tag.sizeText(size) return Data.sizeText(st.man or manifest(), size) end

local function loadBerry(id)
  st.berryId, st.info = id, Tag.berryInfo(id)
  st.text = {number = string.format("%02d", id), name = st.info.name,
    size = Tag.sizeText(st.info.size), firm = st.info.firmness == 0 and st.man.strings.unknown
      or assert(st.man.firmness[st.info.firmness], "invalid native RS berry firmness"),
    description1 = st.info.description1, description2 = st.info.description2}
  st.sprite = {berry = id, circles = {st.info.spicy ~= 0, st.info.dry ~= 0, st.info.sweet ~= 0,
    st.info.bitter ~= 0, st.info.sour ~= 0}}
  st.textDirty = true
end

local function change(dir)
  local nextPos = st.pos + dir
  if not itemAt(nextPos) or nextPos < 0 or nextPos >= #st.list then return end
  play()
  st.dir, st.step, st.phase = dir, 0, "scroll"
end

local KEYS = {"a", "b", "select", "start", "right", "left", "up", "down", "r", "l"}
function Tag.handleInput(input)
  if not Tag.open then return end
  local held, new, repeated = 0, {}, 0
  for i, key in ipairs(KEYS) do
    if input.isDown and input:isDown(key) then held = held + 2 ^ (i - 1) end
    new[key] = input:wasPressed(key)
    if new[key] then repeated = repeated + 2 ^ (i - 1) end
  end
  if held ~= 0 and held == st.held then
    st.repeatCounter = st.repeatCounter - 1
    if st.repeatCounter == 0 then repeated, st.repeatCounter = held, 5 end
  else st.repeatCounter = 40 end
  st.held = held
  st.input = {new = new, dpad = math.floor(repeated / 16) % 16}
end

function Tag.show(opts)
  opts = opts or {}
  Tag.reset()
  for key in pairs(st) do st[key] = nil end
  st.man, st.session = manifest(), opts.session
  if not st.session then
    local rt = package.loaded["src.core.game3.runtime"]
    st.session = rt and rt.getSession and rt.getSession()
  end
  st.list = opts.list or {opts.item or (st.man.firstItem + assert(opts.berryId, "berry tag requires an item") - 1)}
  st.pos = opts.pos or 0
  assert(st.pos >= 0 and st.pos < #st.list, "native RS berry-tag cursor outside pocket")
  st.onMove, st.onClose, st.returnLayer = opts.onMove, opts.onClose, Stack.top()
  st.enigma = Data.enigma(st.session)
  loadBerry(opts.berryId or berryId(itemAt(st.pos)))
  st.drawSprite, st.scrollY, st.spriteY, st.step = st.sprite, 0, 0, 0
  st.phase, st.held, st.repeatCounter = "input", 0, 40
  st.pal = Pal.new()
  st.pal:blend(Pal.ALL, 16, Pal.BLACK)
  st.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  Tag.open = true
  Stack.push(Tag.ID, Tag, {hideBelow = true, fullscreen = true})
  return true
end

function Tag.isOpen() return Tag.open end
function Tag.current() return st.berryId, st.pos end
function Tag.finish()
  if not Tag.open then return end
  Tag.open = false
  Stack.pop(Tag.ID)
  local cb = st.onClose
  st.onClose = nil
  local bag = st.returnLayer and st.returnLayer.mod
  if bag and bag == package.loaded["src.ui.game3.bag_menu"] and bag.open then
    bag._open, bag._exit = {k = 0, curtain = false}, nil
  end
  if cb then cb(st.pos) end
end
function Tag.reset()
  Tag.open = false
  Stack.pop(Tag.ID)
  for key in pairs(st) do st[key] = nil end
end

function Tag.update()
  if not Tag.open then return end
  st.drawSprite, st.spriteY = st.sprite, st.scrollY
  local inp = st.input or {new = {}, dpad = 0}
  st.input = nil
  if st.phase == "closing" then
    if not st.pal:fadeActive() then Tag.finish() return end
  elseif st.phase == "scroll" then
    st.step = st.step + 1
    st.scrollY = (st.scrollY + st.dir * st.man.geometry.scrollSpeed) % 256
    if st.step == st.man.geometry.replacementStep then
      st.pos = st.pos + st.dir
      loadBerry(berryId(itemAt(st.pos)))
      if st.onMove then st.onMove(st.dir, st.pos) end
    end
    if st.scrollY == 0 then st.phase = "input" end
  elseif not st.pal:fadeActive() then
    if inp.dpad == 4 then change(-1) end
    if inp.dpad == 8 then change(1) end
    if inp.new.a or inp.new.b then
      play()
      st.phase = "closing"
      st.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    end
  end
  st.pal:updateFade()
end

local function image(path) return assert(Kit.image(path), "native RS berry-tag image missing: " .. tostring(path)) end
local function wrapped(img, x, y)
  for _, off in ipairs({0, 256, -256}) do love.graphics.draw(img, x, y + off) end
end
local function enigmaImage()
  if st.enigmaImage then return st.enigmaImage end
  local e = st.enigma
  local data = love.image.newImageData(64, 64)
  for y = 0, 47 do for x = 0, 47 do
    local tile = math.floor(y / 8) * 6 + math.floor(x / 8)
    local b = e.pic:byte(tile * 32 + y % 8 * 4 + math.floor(x % 8 / 2) + 1)
    local value = x % 2 == 0 and b % 16 or math.floor(b / 16)
    if value ~= 0 then
      local r, g, blue = Kit.rgb555(e.palette[value + 1])
      data:setPixel(x + 8, y + 8, r, g, blue, 1)
    end
  end end
  st.enigmaImage = love.graphics.newImage(data)
  st.enigmaImage:setFilter("nearest", "nearest")
  return st.enigmaImage
end
local function fontColors()
  local win, pal = st.man.window, st.man.palettes.font
  local function color(i)
    if i == 0 then return {0, 0, 0, 0} end
    local r, g, b = Kit.rgb555(pal[i + 1])
    return {r, g, b, 1}
  end
  return {fg = color(win.foregroundColor), bg = color(win.backgroundColor), shadow = color(win.shadowColor)}
end
local function textLayer()
  if not st.textCanvas then
    st.textCanvas = love.graphics.newCanvas(256, 256)
    st.textCanvas:setFilter("nearest", "nearest")
  end
  if st.textDirty then
    local m, g, colors = st.man, st.man.geometry, fontColors()
    love.graphics.push("all")
    love.graphics.setCanvas(st.textCanvas)
    love.graphics.origin()
    love.graphics.setScissor(0, 0, 240, 160)
    love.graphics.setShader()
    love.graphics.clear(0, 0, 0, 0)
    local function text(str, at)
      Font.draw(str, at[1], at[2], {font = "native_" .. m.window.fontNum, colors = colors, linePitch = 16})
    end
    text(st.text.number, g.number); text(st.text.name, g.name)
    text(m.strings.size, g.sizeLabel); text(st.text.size, g.sizeValue)
    text(m.strings.firm, g.firmLabel); text(st.text.firm, g.firmValue)
    text(st.text.description1, g.description1); text(st.text.description2, g.description2)
    love.graphics.pop()
    st.textDirty = false
  end
  return st.textCanvas
end
function Tag.draw()
  if not Tag.open then return end
  local m, g = st.man, st.man.geometry
  local female = st.session and (st.session.gender == 1 or st.session.gender == "female" or st.session.playerGender == 1)
  love.graphics.setColor(1, 1, 1, 1)
  Fx.withClip({x = 0, y = 0, w = 240, h = 160}, function()
    Fx.draw(function()
      love.graphics.draw(image(m.layers[female and "female" or "male"].png), 0, 0)
      wrapped(image(m.layers.body.png), 0, -st.scrollY)
    end, st.pal:fx(0))
    local fontMap = textLayer()
    Fx.draw(function() wrapped(fontMap, 0, -st.scrollY) end, st.pal:fx(m.window.paletteNum))
    Fx.draw(function()
      local pic = st.drawSprite.berry == 43 and st.enigma and enigmaImage() or image(m.berries[st.drawSprite.berry].png)
      local function berry() wrapped(pic, g.berry[1] - 32, g.berry[2] - 32 - st.spriteY) end
      local function circles()
        local circle = image(m.circle.png)
        for i, x in ipairs(g.circles) do
          if st.drawSprite.circles[i] then wrapped(circle, x - m.circle.w / 2, g.circleY - m.circle.h / 2 - st.spriteY) end
        end
      end
      local function oamY(y) y = (y - st.spriteY) % 256; return y >= 160 and y - 256 or y end
      if oamY(g.berry[2] - 32) > oamY(g.circleY - m.circle.h / 2) then circles(); berry()
      else berry(); circles() end
    end, st.pal:fx(16))
    Fx.draw(function() love.graphics.draw(image(m.layers.title.png), 0, 0) end, st.pal:fx(0))
  end)
  love.graphics.setColor(1, 1, 1, 1)
end
return Tag
