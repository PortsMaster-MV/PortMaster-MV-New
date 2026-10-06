local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local IR = require("src.core.game3.scripting.text_ir")
local Pal = require("src.core.game3.pal_fade")
local Fx = require("src.core.game3.gba_fx")
local D = {ID = "rs_diploma", isMenu = true, open = false, _phase = "idle"}

function D.manifest()
  local m = assert(Kit.manifest("rse/diploma"), "native RS diploma pack missing")
  assert(m.layout == "rs", "native RS diploma pack required")
  return m
end

-- diploma.c:138
function D.content(man, session, national)
  man = man or D.manifest()
  local ctx = {dialect = "rs", playerName = tostring(session and (session.name or session.playerName) or ""),
    stringVars = {national and man.national or man.hoenn}}
  local win = man.window
  local penX, penY, fg, bg, shadow, font = 0, 0, win.foreground, win.background, win.shadow, win.font
  local out = {}
  for _, seg in ipairs(man.text) do
    if seg.t == "eos" then break
    elseif seg.t == "nl" then penX, penY = 0, penY + man.linePitch
    elseif seg.t == "ext" then
      local cmd, arg = seg.cmd, seg.args and seg.args[1]
      if cmd == 1 then fg = arg
      elseif cmd == 2 then bg = arg
      elseif cmd == 3 then shadow = arg
      elseif cmd == 4 then fg, bg, shadow = seg.args[1], seg.args[2], seg.args[3]
      elseif cmd == 6 then font = arg
      elseif cmd == 7 then font = win.font
      elseif cmd == 0x11 then penX = penX + arg
      elseif cmd == 0x12 then penX = arg
      elseif cmd == 0x13 then penX = math.max(penX, arg)
      else error("unsupported native RS diploma control " .. tostring(cmd)) end
    else
      local value = IR.expandSeg(seg, ctx)
      if value and value ~= "" then
        local options = {font = "native_" .. font, letterSpacing = win.spacing, linePitch = man.linePitch}
        out[#out + 1] = {text = value, x = man.printX + penX, y = man.printY + penY,
          foreground = fg, background = bg, shadow = shadow, font = font}
        penX = penX + Font.measure(value, options)
      end
    end
  end
  return out
end

local function color(value, slot, transparent)
  if transparent then return {0, 0, 0, 0} end
  local out = {}
  for i = 1, 3 do
    local ch = math.floor(value / 2 ^ ((i - 1) * 5)) % 32
    ch = ch + math.floor((slot.color[i] - ch) * slot.y / 16)
    out[i] = (ch * 8 + math.floor(ch / 4)) / 255
  end
  out[4] = 1
  return out
end
function D.textOptions(row)
  local w, pal = D._man.window, D._man.textPalette
  local slot = D._pal.slots[w.paletteNum]
  return {font = "native_" .. row.font, letterSpacing = w.spacing, linePitch = D._man.linePitch,
    colors = {fg = color(pal[row.foreground + 1], slot), shadow = color(pal[row.shadow + 1], slot),
      bg = color(pal[row.background + 1], slot, row.background == 0)}}
end

function D.show(opts)
  opts = opts or {}
  local rt = package.loaded["src.core.game3.runtime"]
  local session = opts.session or (rt and rt.getSession and rt.getSession())
  D._man = D.manifest()
  D._national = require("src.core.game3.profiles.rs.pokedex").completedNational(session)
  D._image = assert(Kit.image(D._man.layers[D._national and "national" or "hoenn"].png), "native RS diploma image missing")
  D._content = D.content(D._man, session, D._national)
  D._onDone, D.open, D._phase = opts.onDone, true, "in"
  D._pal, D._stepper = Pal.new(), Kit.stepper()
  D._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  Stack.push(D.ID, D, {hideBelow = true, fullscreen = true})
  return true
end
function D.isOpen() return D.open end
function D.isNational() return D._national end
function D.phase() return D._phase end
local function finish()
  D.open, D._phase = false, "idle"
  Stack.pop(D.ID)
  local cb = D._onDone
  D._onDone = nil
  -- diploma.c:123
  local space = package.loaded["src.core.game3.scripting.space"]
  if space and space.returnToField then space.returnToField() end
  if cb then cb() end
end
function D.reset()
  D._onDone = nil
  if D.open then Stack.pop(D.ID) end
  D.open, D._phase = false, "idle"
  D._man, D._image, D._content, D._pal, D._stepper = nil, nil, nil, nil, nil
end
function D.handleInput(input)
  if D.open then D._stepper:collect(input) end
end
function D.update(dt)
  if not D.open then return end
  D._stepper:run(dt, function(input)
    if D._phase == "in" then
      if not D._pal:fadeActive() then D._phase = "wait" end
    elseif D._phase == "wait" then
      if input.new.a or input.new.b then
        D._pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
        D._phase = "out"
      end
    elseif D._phase == "out" and not D._pal:fadeActive() then finish(); return true end
    D._pal:updateFade()
  end)
end
function D.draw()
  if not D.open then return end
  love.graphics.setColor(1, 1, 1, 1)
  Fx.draw(function() love.graphics.draw(D._image, 0, 0) end, D._pal:fx(0))
  for _, row in ipairs(D._content) do Font.draw(row.text, row.x, row.y, D.textOptions(row)) end
end
return D
