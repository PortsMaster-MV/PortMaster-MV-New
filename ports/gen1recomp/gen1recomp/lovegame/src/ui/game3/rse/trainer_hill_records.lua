local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")

local Records = {}

Records.ID = "rse_trainer_hill_records"
Records.open = false
-- pokeemerald/src/battle_records.c:62
Records.WIN = { 2, 1, 26, 18 }
-- pokeemerald/src/trainer_hill.c:591
Records.WIDTH = 0xD0

local st = {}
Records._st = st

local function Hill() return require("src.core.game3.rse.trainer_hill") end

local function se(name)
  pcall(function() require("src.core.game3.audio").playSe(name) end)
end

-- pokeemerald/src/trainer_hill.c:584
function Records.lines(sess)
  local Hl = Hill()
  Hl.state(sess)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local out = {}
  local title = RomText.plain("gText_TimeBoard")
  out[1] = { text = title, x = math.floor((Records.WIDTH - FrlgFont.measure(title)) / 2), y = 2 }
  local y = 18
  local modes = Hl.manifest().modeStrings
  for i = 1, Hl.NUM_MODES do
    out[#out + 1] = { text = TextIR.toPlain(RomText.refIr(modes[i]), {}), x = 0, y = y }
    y = y + 15
    local m, s, f = Hl.timeParts(sess.trainerHillTimes[i])
    local vars = { string.format("%2d", m), string.format("%2d", s), string.format("%02d", f) }
    local t = RomText.plain("gText_TimeCleared") .. RomText.plain("gText_XMinYDotZSec", { stringVars = vars })
    out[#out + 1] = { text = t, x = Records.WIDTH - FrlgFont.measure(t), y = y }
    y = y + 17
  end
  return out
end

-- pokeemerald/src/battle_records.c:465
function Records.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.session = opts.session
  if not st.session then
    local rt = package.loaded["src.core.game3.runtime"]
    st.session = rt and rt.getSession and rt.getSession() or nil
  end
  st.onClose = opts.onClose
  st.lines = Records.lines(st.session)
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.clear then Fade.clear() end
  st.fade, st.fadeDir = 16, -1
  st.phase = "input"
  Records.open = true
  Stack.push(Records.ID, Records, { hideBelow = true, fullscreen = true })
  return true
end

function Records.isOpen() return Records.open end

local function finish()
  Records.open = false
  Stack.pop(Records.ID)
  local cb = st.onClose
  st.onClose = nil
  if cb then cb() end
end

function Records.reset()
  Records.open = false
  Stack.pop(Records.ID)
end

function Records.handleInput(input)
  if not Records.open then return end
  st.input = require("src.ui.game3.rse.pokeblock_case").snapshot(input)
end

function Records.update()
  if not Records.open then return end
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  if st.fadeDir ~= 0 then
    st.fade = st.fade + st.fadeDir
    if st.fade <= 0 then st.fade, st.fadeDir = 0, 0
    elseif st.fade >= 16 then
      st.fade, st.fadeDir = 16, 0
      if st.phase == "closing" then finish() end
    end
    return
  end
  -- pokeemerald/src/battle_records.c:352
  if st.phase == "input" and (inp.new.a or inp.new.b) then
    se("SE_SELECT")
    st.phase = "closing"
    st.fadeDir = 1
  end
end

local function background()
  if st.bg then return st.bg end
  local g = Gfx.of("rse/trainer_hill")
  local m = g:manifest()
  st.bg = g:renderMap(g:map("records"), "records", Gfx.palette(m.palettes.records, {}, 0), { rows = 20, backdrop = true })
  return st.bg
end

function Records.draw()
  if not Records.open then return end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(background(), 0, 0)
  local W = Records.WIN
  for _, l in ipairs(st.lines or {}) do
    FrlgFont.draw(l.text, W[1] * 8 + l.x, W[2] * 8 + l.y, { colors = FrlgFont.COLOR.NORMAL })
  end
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return Records
