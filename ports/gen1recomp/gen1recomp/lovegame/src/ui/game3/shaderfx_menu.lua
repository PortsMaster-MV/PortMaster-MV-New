local Window = require("src.ui.game3.window")
local Chrome = require("src.ui.game3.chrome")
local FrlgFont = require("src.ui.game3.frlg_font")
local Strings = require("src.core.Strings")

local ShaderFXMenu = { isMenu = true }

ShaderFXMenu.open = false
ShaderFXMenu.VISIBLE = 7

local WIN_X, WIN_Y, WIN_W, WIN_H = 16, 56, 208, 96
local ROW_Y0 = WIN_Y + 2
local ROW_STEP = 13
local LABEL_X = WIN_X + 16
local CURSOR_X = WIN_X + 8
local RIGHT_X = WIN_X + WIN_W - 18
local LABEL_GAP = 6
local HELP_BG = { 0 / 255, 123 / 255, 197 / 255, 1 }
local HELP_TEXT = { fg = { 1, 1, 1, 1 }, shadow = { 98 / 255, 98 / 255, 98 / 255, 1 }, bg = { 0, 0, 0, 0 } }

local st = { states = {} }
ShaderFXMenu._st = st

function ShaderFXMenu.slotLabel(slot, maxPx)
  local entry = require("src.render.ShaderFX").activeEntry(slot)
  if not entry then return Strings("OFF") end
  local text = (entry.name:gsub("%.slangp$", "")):upper()
  if maxPx and FrlgFont.measure(text) > maxPx then
    local n = #text
    while n > 0 and FrlgFont.measure(text:sub(1, n) .. ".") > maxPx do n = n - 1 end
    text = text:sub(1, n) .. "."
  end
  return text
end

local function top()
  return st.states[#st.states]
end

local function newHost(game)
  local ChoiceBox = require("src.ui.ChoiceBox")
  local host = {
    save = { options = game and game.options or {} },
    writeOptions = function()
      if game and game.writeOptions then game:writeOptions() end
    end,
  }
  host.options = host.save.options
  host.stack = {
    push = function(_, state)
      if getmetatable(state) == ChoiceBox then state.noSound = true end
      st.states[#st.states + 1] = state
    end,
    pop = function()
      st.states[#st.states] = nil
      if #st.states == 0 then ShaderFXMenu.close() end
    end,
    top = function() return top() end,
  }
  return host
end

local function slotRoot(host)
  local ListMenu = require("src.ui.ListMenu")
  local Screens = require("src.ui.Screens")
  local items = {
    { label = Strings("SHADER FX"), slot = "main" },
    { label = Strings("SHADER FX 2"), slot = "secondary" },
  }
  local root = ListMenu.new(host, Strings("SHADER FX"), items, { rows = 7 })
  root.refreshRight = function()
    for _, item in ipairs(items) do item.right = ShaderFXMenu.slotLabel(item.slot, 96) end
  end
  root.onChoose = function(item)
    Screens.push(host, "ShaderFXScreen", item.slot)
  end
  root.refreshRight()
  return root
end

function ShaderFXMenu.show(opts)
  opts = opts or {}
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = opts.game or (Runtime and Runtime._game)
  st.states = {}
  st.view = setmetatable({}, { __mode = "k" })
  st.k = 0
  st.game = game
  st.onClose = opts.onClose
  st.host = newHost(game)
  ShaderFXMenu.open = true
  if opts.slot then
    require("src.ui.Screens").push(st.host, "ShaderFXScreen", opts.slot)
  else
    st.host.stack:push(slotRoot(st.host))
  end
  return ShaderFXMenu
end

function ShaderFXMenu.close()
  if not ShaderFXMenu.open then return end
  ShaderFXMenu.open = false
  st.states = {}
  local cb = st.onClose
  st.onClose = nil
  if cb then cb() end
end

function ShaderFXMenu.isOpen()
  return ShaderFXMenu.open
end

function ShaderFXMenu.handleInput(input)
  if not ShaderFXMenu.open or not input then return end
  local s = top()
  if not s then
    ShaderFXMenu.close()
    return
  end
  st.host.input = input
  st.host.save.options = (st.game and st.game.options) or st.host.save.options
  st.host.options = st.host.save.options
  if s.update then s:update(1 / 60) end
  local now = top()
  if now and now.refreshRight then now.refreshRight() end
end

function ShaderFXMenu.update()
  if ShaderFXMenu.open then st.k = (st.k or 0) + 1 end
end

local fitCache = setmetatable({}, { __mode = "k" })

local function fit(item, text, pixels)
  text = tostring(text or "")
  local c = fitCache[item]
  if c and c.text == text and c.pixels == pixels then return c.out end
  local out = text
  if pixels <= 0 then
    out = ""
  elseif FrlgFont.measure(text) > pixels then
    local n = #text
    while n > 0 and FrlgFont.measure(text:sub(1, n) .. ".") > pixels do n = n - 1 end
    out = text:sub(1, n) .. "."
  end
  fitCache[item] = { text = text, pixels = pixels, out = out }
  return out
end

local function frameType()
  local game = st.game
  local engine = (game and game.options) or {}
  local ok, Options = pcall(require, "src.core.game3.options")
  if ok and Options and Options.block then
    return tonumber(Options.block(engine).frameType) or 0
  end
  return 0
end

local function bob(k, freq)
  local Trig = require("src.core.game3.trig")
  local v = Trig.sin(((k or 0) * freq) % 256) * 2 / 256
  return v < 0 and math.ceil(v) or math.floor(v)
end

local function scrollArrow(dir, x, y)
  local ok, BagChrome = pcall(require, "src.ui.game3.bag_chrome")
  if ok and BagChrome and BagChrome.drawArrow then
    local drew, res = pcall(BagChrome.drawArrow, dir, x, y)
    if drew and res then return end
  end
  FrlgFont.drawGlyph(dir == "up" and FrlgFont.CHAR_UP_ARROW or FrlgFont.CHAR_DOWN_ARROW,
    x + 4, y + 1, { colors = FrlgFont.COLOR.RED })
end

local function listState()
  for i = #st.states, 1, -1 do
    local s = st.states[i]
    if type(s.items) == "table" then return s end
  end
  return nil
end

local function window(list)
  local n = #list.items
  local first = st.view[list] or 1
  local idx = list.index or 1
  local vis = ShaderFXMenu.VISIBLE
  if idx < first then first = idx end
  if idx > first + vis - 1 then first = idx - vis + 1 end
  first = math.max(1, math.min(first, math.max(1, n - vis + 1)))
  st.view[list] = first
  return first, math.min(n, first + vis - 1)
end

local function helpText(list, confirm)
  if confirm then return Strings("A:OK  B:CANCEL") end
  local footer = list and list.footer
  if type(footer) == "string" and footer ~= "" then
    return (footer:gsub("\n", "  "))
  end
  return Strings("A:OK  B:BACK")
end

local MUTED = { fg = FrlgFont.STDPAL[3], shadow = FrlgFont.STDPAL[1], bg = FrlgFont.STDPAL[0] }

local function valueColors()
  return { fg = FrlgFont.STDPAL[5], shadow = FrlgFont.STDPAL[4], bg = FrlgFont.STDPAL[0] }
end

local function drawConfirm(box, list)
  Window.dialogueFrame()
  local prompt = list and list.footer
  if type(prompt) == "string" then
    Window.printPx((prompt:gsub("\n", " ")), 2 * 8, 15 * 8 + 2, { colors = FrlgFont.COLOR.NORMAL })
  end
  local y = 17 * 8 + 2
  Window.printPx(Strings("YES"), 3 * 8 + 8, y, { colors = FrlgFont.COLOR.NORMAL })
  Window.printPx(Strings("NO"), 10 * 8 + 8, y, { colors = FrlgFont.COLOR.NORMAL })
  Window.cursorPx((box.index == 1) and 3 * 8 or 10 * 8, y)
end

function ShaderFXMenu.draw()
  if not ShaderFXMenu.open then return end
  local list = listState()
  local s = top()
  local confirm = s and s ~= list and type(s.items) ~= "table" and s.onChoose ~= nil

  love.graphics.push("all")
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(HELP_BG)
  love.graphics.rectangle("fill", 0, 0, 240, 16)
  love.graphics.setColor(1, 1, 1, 1)
  local help = helpText(list, confirm)
  FrlgFont.draw(help, 0xE4 - FrlgFont.measure(help), 1, { colors = HELP_TEXT })

  Chrome.fixedStdFrame(2, 3, 26, 2)
  Window.userFrame(Window.template(2, 7, 26, 12), frameType())

  if list then
    Window.printPx(fit(list, list.title, 200), 16 + 8, 24 + 1, { colors = FrlgFont.COLOR.NORMAL })
    local first, last = window(list)
    local vcol = valueColors()
    for i = first, last do
      local item = list.items[i]
      local y = ROW_Y0 + (i - first) * ROW_STEP
      local right = item.right and tostring(item.right) or nil
      local rightW = right and FrlgFont.measure(right) or 0
      if right then
        Window.printPx(right, RIGHT_X - rightW, y, { colors = vcol })
      end
      local budget = RIGHT_X - LABEL_X - (right and (rightW + LABEL_GAP) or 0)
      Window.printPx(fit(item, item.label, budget), LABEL_X, y,
        { colors = item.muted and MUTED or FrlgFont.COLOR.NORMAL })
      if i == list.index and not confirm then Window.cursorPx(CURSOR_X, y) end
    end
    local k = st.k or 0
    if first > 1 then scrollArrow("up", 208, WIN_Y + bob(k, 8)) end
    if last < #list.items then scrollArrow("down", 208, WIN_Y + WIN_H - 16 + bob(k, -8)) end
  end
  if confirm then drawConfirm(s, list) end
  love.graphics.pop()
end

return ShaderFXMenu
