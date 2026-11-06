local Stack = require("src.ui.game3.stack")
local Options = require("src.core.game3.options")
local Profile = require("src.core.game3.profile")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Pal = require("src.core.game3.pal_fade")
local Kit = require("src.ui.game3.rse.scene_kit")
local Rows = require("src.ui.game3.option_rows")
local ShaderFXMenu = require("src.ui.game3.shaderfx_menu")

local Menu = {isMenu = true, open = false, cursor = 1}
local KEYS = {"textSpeed", "battleScene", "battleStyle", "sound", "buttonMode", "frameType"}
local COUNTS = {3, 2, 2, 2, 3, 20}
local NATIVE = #KEYS + 1
Menu.VISIBLE = 7
Menu.EXCLUDE = {eventTickets = true}

local function ctx()
  return {session = Menu._session, game = Menu._game, options = Menu._engine}
end

local function page()
  return Menu._pages and Menu._pages[#Menu._pages]
end

local function topRows()
  local cartRows = {}
  for i, key in ipairs(KEYS) do cartRows[key] = {id = key, native = i} end
  return Rows.withCart(ctx(), cartRows, function(title, members)
    Menu._pages[#Menu._pages + 1] = {title = title, rows = members, index = 1, scroll = 0}
  end, Menu.EXCLUDE)
end

local function rowCount(p)
  return #p.rows + 1
end

local function clampScroll(p)
  local total, vis = rowCount(p), Menu.VISIBLE
  if p.index - 1 < p.scroll then p.scroll = p.index - 1 end
  if p.index > p.scroll + vis then p.scroll = p.index - vis end
  p.scroll = math.max(0, math.min(p.scroll, math.max(0, total - vis)))
end

-- pokeruby/src/option_menu.c:74
function Menu.show(opts)
  opts = opts or {}
  local Runtime = package.loaded["src.core.game3.runtime"]
  Menu._game = opts.game or (Runtime and Runtime._game)
  Menu._session = opts.session or {version = Profile.active().id}
  Menu._engine = Options.engine(opts.session) or (Menu._game and Menu._game.options) or {}
  Menu._block = Options.bind(Menu._session, Menu._engine)
  Menu._pending = {}
  for i, key in ipairs(KEYS) do Menu._pending[key] = tonumber(Menu._block[key]) or 0 end
  local man = assert(Kit.manifest("rse/menus"), "native RS menu manifest missing")
  assert(man.layout == "rs" and type(man.option) == "table", "native RS option menu data missing")
  Menu._data, Menu._onClose = man.option, opts.onClose
  Menu._pages = {}
  Menu._pages[1] = {top = true, rows = topRows(), index = 1, scroll = 0}
  Menu.cursor, Menu.open, Menu._state, Menu._saveQueued, Menu._k = 1, true, "fade_in", nil, 0
  Menu._pal = Pal.new()
  Menu._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  Stack.push("option", Menu, {hideBelow = true, fullscreen = true})
end

function Menu.isOpen() return Menu.open end

function Menu.close()
  if not Menu.open then return end
  ShaderFXMenu.close()
  Menu.open = false
  Menu._pages = nil
  Stack.pop("option")
  local cb = Menu._onClose
  Menu._onClose = nil
  if cb then cb() end
end

local function save()
  for _, key in ipairs(KEYS) do Options.set(Menu._session, key, Menu._pending[key]) end
  if Menu._game and Menu._game.writeOptions then Menu._game:writeOptions() end
  Chrome.setFrameType(Menu._pending.frameType)
  Menu._pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
  Menu._state = "fade_out"
end

function Menu.update()
  if not Menu.open then return end
  ShaderFXMenu.update()
  Menu._k = (Menu._k or 0) + 1
  if Menu._state == "save" then
    if Menu._saveQueued then Menu._saveQueued = nil else save() end
  end
  Menu._pal:updateFade()
  if not Menu._pal:fadeActive() then
    if Menu._state == "fade_in" then Menu._state = "input"
    elseif Menu._state == "fade_out" then Menu.close() end
  end
end

local function pressed(input, key)
  return input and input.wasPressed and input:wasPressed(key)
end

local function persist()
  local g = Menu._game
  if g and g.writeOptions then g:writeOptions() end
end

local function activatePort(row)
  if row.activate then
    pcall(function() require("src.core.game3.audio").playSe("SE_SELECT") end)
    row.activate(ctx())
  elseif row.step and row.step(ctx(), 1) then
    persist()
  end
end

local function stepNative(i, input)
  local key, count = KEYS[i], COUNTS[i]
  local value = Menu._pending[key]
  if count == 2 then
    if pressed(input, "left") or pressed(input, "right") then
      value = 1 - value
      if key == "sound" then
        local Audio = require("src.core.game3.audio")
        if Audio.setCryStereo then Audio.setCryStereo(value) end
      end
    end
  else
    if pressed(input, "right") then value = (value + 1) % count end
    if pressed(input, "left") then value = (value - 1) % count end
  end
  Menu._pending[key] = value
end

function Menu.back()
  if Menu._pages and #Menu._pages > 1 then
    table.remove(Menu._pages)
    return
  end
  Menu._state, Menu._saveQueued = "save", true
end

function Menu.handleInput(input)
  if not Menu.open or Menu._state ~= "input" then return end
  if ShaderFXMenu.isOpen() then return ShaderFXMenu.handleInput(input) end
  local p = page()
  if not p then return end
  local total = rowCount(p)
  local row = p.rows[p.index]
  if pressed(input, "a") then
    if not row then Menu.back()
    elseif not row.native then activatePort(row) end
  elseif pressed(input, "b") then Menu.back()
  elseif pressed(input, "up") then p.index = (p.index - 2) % total + 1
  elseif pressed(input, "down") then p.index = p.index % total + 1
  elseif row and row.native then stepNative(row.native, input)
  elseif row and row.step and (pressed(input, "left") or pressed(input, "right")) then
    if row.step(ctx(), pressed(input, "left") and -1 or 1) then persist() end
  end
  local cur = page()
  if cur then clampScroll(cur) end
  Menu.cursor = Menu._pages and Menu._pages[1].index or 1
end

local function paletteColors(bank)
  local p = Menu._data.textPalette
  if bank == 15 then return Font.COLOR.NORMAL end
  local base = (bank - 8) * 16
  local w = Menu._data.nativeWindow
  return {fg = Kit.color555(p[base + w.foregroundColor + 1]),
    shadow = Kit.color555(p[base + w.shadowColor + 1]), bg = Kit.color555(p[base + w.backgroundColor + 1])}
end

local function drawNative(i, dy)
  local d = Menu._data
  local row = d.rows[i]
  Font.draw(row.text, row.x, row.y + dy, {colors = paletteColors(9)})
  for j, choice in ipairs(row.choices or {}) do
    local bank = Menu._pending[KEYS[i]] == j - 1 and d.selectedStyle or d.inactiveStyle
    Font.draw(choice.text, choice.x, row.y + dy, {colors = paletteColors(bank)})
  end
  if KEYS[i] == "frameType" then
    Font.draw(d.frameLabel, d.frameLabelX, d.frameY + dy, {colors = paletteColors(15)})
    Font.draw(tostring(Menu._pending.frameType + 1), d.frameNumberX, d.frameY + dy, {colors = paletteColors(8)})
  end
end

local function drawPort(row, y)
  local d = Menu._data
  Font.draw(row.label or "?", d.rows[1].x, y, {colors = paletteColors(9)})
  if row.value then
    local ok, text = pcall(row.value, ctx())
    Font.draw(ok and tostring(text) or "----", d.rows[1].choices[1].x, y, {colors = paletteColors(d.selectedStyle)})
  end
end

local function drawContents()
  local d = Menu._data
  local p = page()
  love.graphics.clear(0, 0, 0, 1)
  Chrome.userFrame(Menu._pending.frameType, 3, 1, 24, 2)
  Chrome.userFrame(Menu._pending.frameType, 3, 5, 24, 14)
  Font.draw(p.top and d.title or p.title, d.titleX, d.titleY, {colors = paletteColors(9)})
  clampScroll(p)
  local baseY = d.rows[1].y
  for slot = 1, Menu.VISIBLE do
    local idx = p.scroll + slot
    if idx > rowCount(p) then break end
    local y = baseY + (slot - 1) * 16
    local row = p.rows[idx]
    if row and row.native then
      drawNative(row.native, y - d.rows[row.native].y)
    elseif row then
      drawPort(row, y)
    else
      Font.draw(d.rows[NATIVE].text, d.rows[NATIVE].x, y, {colors = paletteColors(9)})
    end
  end
end

local arrowQuads = {}
local function arrowFrame(frame, x, y)
  local m = Kit.manifest("rse/bag")
  local e = m and m.sprites and m.sprites.arrows_vertical
  local img = e and Kit.image(e.png)
  if not img then return end
  local key = e.png .. ":" .. frame
  if not arrowQuads[key] then
    local iw, ih = img:getDimensions()
    arrowQuads[key] = love.graphics.newQuad(0, frame * e.h, e.w, e.h, iw, ih)
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, arrowQuads[key], x, y, 0, 1, 1, e.w / 2, e.h / 2)
end

local function drawArrows(p)
  if Menu._state ~= "input" or rowCount(p) <= Menu.VISIBLE then return end
  local bob = math.floor(require("src.core.game3.trig").sin((Menu._k or 0) * 8 % 256) * 2 / 256)
  if p.scroll > 0 then arrowFrame(0, 120, 36 + bob) end
  if p.scroll + Menu.VISIBLE < rowCount(p) then arrowFrame(1, 120, 156 - bob) end
end

local SHADER = [[
extern float fadeY;
extern float rowTop;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec4 p = Texel(tex, tc);
  vec3 c = floor(p.rgb * 31.0 + 0.5);
  c += floor(-c * fadeY / 16.0);
  vec2 pos = tc * vec2(240.0,160.0);
  bool title = pos.x >= 17.0 && pos.x < 223.0 && pos.y >= 1.0 && pos.y < 31.0;
  bool row = pos.x >= 24.0 && pos.x < 215.0 && pos.y >= rowTop && pos.y < rowTop + 16.0;
  if (!title && !row) c -= floor(c * 7.0 / 16.0);
  return vec4((c * 8.0 + floor(c / 4.0)) / 255.0, p.a);
}
]]
local canvas, shader
function Menu.draw()
  if not Menu.open then return end
  if ShaderFXMenu.isOpen() then return ShaderFXMenu.draw() end
  canvas = canvas or love.graphics.newCanvas(240, 160)
  canvas:setFilter("nearest", "nearest")
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.origin()
  drawContents()
  love.graphics.pop()
  if shader == nil then
    local ok, s = pcall(love.graphics.newShader, SHADER)
    shader = ok and s or false
  end
  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1, 1)
  if shader then
    shader:send("fadeY", Menu._pal.slots[0].y)
    local p = page()
    shader:send("rowTop", Menu._data.rows[1].y + (p.index - p.scroll - 1) * 16)
    love.graphics.setShader(shader)
    love.graphics.draw(canvas, 0, 0)
  else
    love.graphics.draw(canvas, 0, 0)
    Kit.drawFade(Menu._pal, 0)
  end
  love.graphics.pop()
  love.graphics.push("all")
  drawArrows(page())
  love.graphics.pop()
end

return Menu
