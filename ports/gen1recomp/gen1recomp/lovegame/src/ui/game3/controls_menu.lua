local Stack = require("src.ui.game3.stack")
local Window = require("src.ui.game3.window")
local Chrome = require("src.ui.game3.chrome")
local FrlgFont = require("src.ui.game3.frlg_font")
local Strings = require("src.core.Strings")
local BindingsMenu = require("src.ui.BindingsMenu")
local ChoiceBox = require("src.ui.ChoiceBox")

local Controls = { isMenu = true }

Controls.ID = "controls"
Controls.open = false

local VISIBLE = 7
local WIN_X, WIN_Y, WIN_W, WIN_H = 16, 56, 208, 96
local ROW_Y0 = WIN_Y + 2
local ROW_STEP = 13
local ROW_H = 14
local LABEL_X = WIN_X + 8
local VALUE_X = WIN_X + 0x82
local HELP_BG = { 0 / 255, 123 / 255, 197 / 255, 1 }

local function optionsTable(game, given)
  if game and type(game.options) == "table" then return game.options end
  if type(given) == "table" then return given end
  return {}
end

function Controls.show(opts)
  opts = opts or {}
  local game = opts.game
  if not game then return end
  if Controls.open and Stack.has(Controls.ID) then return end
  local options = optionsTable(game, opts.options)
  local proxy = setmetatable({
    save = { options = options },
    input = game.input,
    data = false,
    writeOptions = function()
      if game.writeOptions then game:writeOptions() end
    end,
    stack = {
      pop = function() Controls.close() end,
      top = function() return Controls._bm end,
      push = function(_, state)
        if getmetatable(state) == ChoiceBox then
          Controls._confirm = { index = state.index, onChoose = state.onChoose }
        end
      end,
    },
  }, { __index = game })
  local bm = BindingsMenu.new(proxy, { buttons = BindingsMenu.GEN3_BUTTONS })
  bm.rows = VISIBLE
  Controls._bm = bm
  Controls._game = game
  Controls._confirm = nil
  Controls._onClose = opts.onClose
  Controls._arrowK = 0
  Controls.open = true
  Stack.push(Controls.ID, Controls, { hideBelow = true, fullscreen = true })
end

function Controls.close()
  if not Controls.open then return end
  Controls.open = false
  local bm = Controls._bm
  if bm and bm.capture then bm:endCapture() end
  Controls._confirm = nil
  Stack.pop(Controls.ID)
  local cb = Controls._onClose
  Controls._onClose = nil
  if cb then cb() end
end

function Controls.handleInput(input)
  local bm = Controls._bm
  if not bm or not input then return end
  bm.game.input = input
  local c = Controls._confirm
  if c then
    if input:wasPressed("up") or input:wasPressed("down") then
      c.index = 3 - c.index
    elseif input:wasPressed("a") or input:wasPressed("b") then
      Controls._confirm = nil
      c.onChoose(input:wasPressed("a") and c.index == 1)
    end
    return
  end
  if bm.capture then
    local pending = input.captureEvents
    if (not pending or #pending == 0) and input:wasPressed("b") then
      bm:endCapture()
      return
    end
  end
  bm:update(1 / 60)
end

function Controls.update()
  if Controls.open then
    Controls._arrowK = (Controls._arrowK or 0) + 1
  end
end

local function helpText(bm)
  if Controls._confirm then return "{DPAD_UPDOWN}PICK {A_BUTTON}OK {B_BUTTON}BACK" end
  if bm.capture then return "PRESS A BUTTON" end
  return "{A_BUTTON}SET {SELECT_BUTTON}CLEAR {START_BUTTON}RESET {B_BUTTON}BACK"
end

local function drawHelpBar(bm)
  love.graphics.setColor(HELP_BG)
  love.graphics.rectangle("fill", 0, 0, 240, 16)
  love.graphics.setColor(1, 1, 1, 1)
  local PokedexChrome = require("src.ui.game3.pokedex_chrome")
  PokedexChrome.drawControlInfo(Strings(helpText(bm)), 0xE4, 0)
end

local function valueColors()
  FrlgFont.sync()
  return FrlgFont.COLOR.OPTION_VALUE
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

local function frameType()
  local game = Controls._game
  local engine = (game and game.options) or {}
  local ok, Options = pcall(require, "src.core.game3.options")
  if ok and Options and Options.block then
    return tonumber(Options.block(engine).frameType) or 0
  end
  return 0
end

local function clampScroll(bm)
  local n = #bm.items
  if bm.index - bm.scroll > VISIBLE then bm.scroll = bm.index - VISIBLE end
  if bm.index - bm.scroll < 1 then bm.scroll = bm.index - 1 end
  bm.scroll = math.max(0, math.min(bm.scroll, math.max(0, n - VISIBLE)))
end

local function drawCapture()
  Chrome.stdFrame(5, 9, 20, 6)
  local x, y = 5 * 8 + 4, 9 * 8 + 2
  Window.printPx(Strings("PRESS A BUTTON"), x, y, { colors = FrlgFont.COLOR.NORMAL })
  Window.printPx(Strings("RELEASE TO SET"), x, y + 15, { colors = FrlgFont.COLOR.NORMAL })
  Window.printPx(Strings("ESC/2ND CANCELS"), x, y + 30, { colors = FrlgFont.COLOR.NORMAL })
end

local function drawConfirm(c)
  Chrome.stdFrame(19, 10, 6, 4)
  local x, y = 19 * 8 + 8, 10 * 8 + 2
  Window.printPx(Strings("YES"), x, y, { colors = FrlgFont.COLOR.NORMAL })
  Window.printPx(Strings("NO"), x, y + 15, { colors = FrlgFont.COLOR.NORMAL })
  Window.cursorPx(19 * 8, c.index == 1 and y or y + 15)
end

function Controls.draw()
  if not Controls.open then return end
  local bm = Controls._bm
  if not bm then return end

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  drawHelpBar(bm)

  Chrome.fixedStdFrame(2, 3, 26, 2)
  local title = Controls._confirm and bm.footer or Strings("CONTROLS")
  Window.printPx(title, 16 + 8, 24 + 1, { colors = FrlgFont.COLOR.NORMAL })

  Window.userFrame(Window.template(2, 7, 26, 12), frameType())

  clampScroll(bm)
  local vcol = valueColors()
  for slot = 1, VISIBLE do
    local idx = bm.scroll + slot
    local item = bm.items[idx]
    if not item then break end
    local y = ROW_Y0 + (slot - 1) * ROW_STEP
    Window.printPx(item.label or "?", LABEL_X, y, { colors = FrlgFont.COLOR.NORMAL })
    Window.printPx(item.right or "", VALUE_X, y, { colors = vcol })
  end

  local selTop = ROW_Y0 + (bm.index - bm.scroll - 1) * ROW_STEP
  local selBot = selTop + ROW_H
  love.graphics.setColor(0, 0, 0, 2 / 16)
  if selTop > WIN_Y then
    love.graphics.rectangle("fill", WIN_X, WIN_Y, WIN_W, selTop - WIN_Y)
  end
  if selBot < WIN_Y + WIN_H then
    love.graphics.rectangle("fill", WIN_X, selBot, WIN_W, WIN_Y + WIN_H - selBot)
  end
  love.graphics.setColor(1, 1, 1, 1)

  local k = Controls._arrowK or 0
  if bm.scroll > 0 then
    scrollArrow("up", 208, WIN_Y + bob(k, 8))
  end
  if bm.scroll + VISIBLE < #bm.items then
    scrollArrow("down", 208, WIN_Y + WIN_H - 16 + bob(k, -8))
  end

  if bm.capture then drawCapture() end
  if Controls._confirm then drawConfirm(Controls._confirm) end
end

return Controls
