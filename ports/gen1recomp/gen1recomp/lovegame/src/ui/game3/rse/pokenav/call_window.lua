local Kit = require("src.ui.game3.rse.scene_kit")
local RomText = require("src.core.game3.rom_text")
local TextIR = require("src.core.game3.scripting.text_ir")

local CallWindow = {}

CallWindow.ID = "rse_match_call_window"

-- pokeemerald/src/match_call.c:1232
CallWindow.LEFT, CallWindow.TOP, CallWindow.WIDTH, CallWindow.HEIGHT = 1, 15, 28, 4

local Host = {}
CallWindow.Host = Host

local function MatchCall() return require("src.core.game3.rse.match_call") end

local function root()
  return require("src.core.game3.cache_paths").CACHE_ROOT
end

local function color(pal, i)
  return Kit.color555(pal and pal[i] or 0)
end

-- pokeemerald/src/match_call.c:1406
local function textColors(man)
  local pal = man.navIcon.pal
  return { fg = color(pal, 10), bg = color(pal, 8), shadow = color(pal, 14) }
end

local function speed(session)
  local ok, Options = pcall(require, "src.core.game3.options")
  return Kit.textSpeedDelay(ok and Options.textSpeed(session) or 1)
end

-- pokeemerald/src/match_call.c:1208
local STATES = { "load", "draw", "ready", "slide_in", "intro", "message", "slide_out", "end" }

function CallWindow.start(opts)
  local Stack = require("src.ui.game3.stack")
  local s = {
    session = opts.session,
    text = opts.text,
    message = opts.message,
    onDone = opts.onDone,
    state = 1,
    offset = 32,
    iconStage = 0,
    iconTimer = 0,
    frames = 0,
  }
  Host._s = s
  Host._step = Kit.stepper()
  Kit.playSe("SE_POKENAV_CALL")
  Stack.push(CallWindow.ID, Host, { hideBelow = false })
  return s
end

function CallWindow.active()
  return Host._s
end

function CallWindow.isOpen()
  return Host._s ~= nil
end

local function finish(s)
  local Stack = require("src.ui.game3.stack")
  if Host._s == s then Host._s = nil end
  Stack.pop(CallWindow.ID)
  if s.onDone then s.onDone() end
end

local function messageIr(s)
  if s.text then return s.text.ir, s.text.ctx end
  local msg = s.message and s.message() or nil
  s.selected = msg
  if not msg then return nil, nil end
  return RomText.translate(RomText.ir(msg.key), msg.ctx, msg.key), msg.ctx
end

-- pokeemerald/src/match_call.c:1220
function CallWindow.frame(s, inp)
  s.frames = s.frames + 1
  local st = STATES[s.state]
  local advance = false
  if st == "load" or st == "draw" then
    advance = true
  elseif st == "ready" then
    local man = MatchCall().manifest()
    s.printer = Kit.printer(TextIR.decode(man.callEllipsis, { dialect = "rse" }), { speed = speed(s.session) })
    advance = true
  elseif st == "slide_in" then
    s.offset = s.offset - 6
    if s.offset <= 0 then
      s.offset = 0
      advance = true
    end
  elseif st == "intro" then
    s.printer:run(inp)
    if not s.printer:isActive() then
      local ir, ctx = messageIr(s)
      s.printer = Kit.printer(ir or {}, { ctx = ctx, speed = speed(s.session) })
      advance = true
    end
  elseif st == "message" then
    if s.printer:isActive() then
      s.printer:run(inp)
    elseif inp.new and (inp.new.a or inp.new.b) then
      s.printer = nil
      Kit.playSe("SE_POKENAV_HANG_UP")
      advance = true
    end
  elseif st == "slide_out" then
    s.offset = s.offset + 6
    if s.offset >= 32 then
      s.offset = 32
      advance = true
    end
  elseif st == "end" then
    finish(s)
    return
  end
  -- pokeemerald/src/match_call.c:1442
  s.iconTimer = s.iconTimer + 1
  if s.iconTimer > 8 then
    s.iconTimer = 0
    s.iconStage = (s.iconStage + 1) % 8
  end
  if advance then s.state = s.state + 1 end
end

-- pokeemerald/src/match_call.c:1384
function CallWindow.draw(s)
  if not s or s.state < 2 then return end
  local man = MatchCall().manifest()
  local x, y, w, h = CallWindow.LEFT, CallWindow.TOP, CallWindow.WIDTH, CallWindow.HEIGHT
  love.graphics.push("all")
  love.graphics.translate(0, math.floor(s.offset))
  local win = Kit.image(root() .. "/rse/match_call/window.png")
  local quads = CallWindow._quads
  if win and not quads then
    quads = {}
    for i = 0, 7 do quads[i] = love.graphics.newQuad(i * 8, 0, 8, 8, win:getDimensions()) end
    CallWindow._quads = quads
  end
  local function tile(n, tx, ty, tw, th)
    if not win then return end
    for yy = 0, th - 1 do
      for xx = 0, tw - 1 do love.graphics.draw(win, quads[n], (tx + xx) * 8, (ty + yy) * 8) end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  tile(0, x - 1, y - 1, 1, 1)
  tile(1, x, y - 1, w, 1)
  tile(2, x + w, y - 1, 1, 1)
  tile(3, x - 1, y, 1, h)
  tile(4, x + w, y, 1, h)
  tile(5, x - 1, y + h, 1, 1)
  tile(6, x, y + h, w, 1)
  tile(7, x + w, y + h, 1, 1)
  local pal = man.navIcon.pal
  love.graphics.setColor(color(pal, 8))
  love.graphics.rectangle("fill", x * 8, y * 8, w * 8, h * 8)
  love.graphics.setColor(1, 1, 1, 1)
  local icon = Kit.image(root() .. "/rse/match_call/nav_icon.png")
  if icon then
    CallWindow._iconQuads = CallWindow._iconQuads or {}
    local q = CallWindow._iconQuads[s.iconStage]
    if not q then
      q = love.graphics.newQuad(0, s.iconStage * 32, 32, 32, icon:getDimensions())
      CallWindow._iconQuads[s.iconStage] = q
    end
    love.graphics.draw(icon, q, x * 8, y * 8)
  end
  if s.printer and STATES[s.state] ~= "slide_out" then
    s.printer:draw(x * 8 + 32, y * 8 + 1, { colors = textColors(man), maxWidth = w * 8 - 32 })
  end
  love.graphics.pop()
end

function CallWindow.reset()
  if Host._s then
    Host._s = nil
    require("src.ui.game3.stack").pop(CallWindow.ID)
  end
  Host._step = nil
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local s = Host._s
  if not (s and Host._step) then return end
  Host._step:run(dt, function(inp)
    if Host._s ~= s then return true end
    CallWindow.frame(s, inp)
    if Host._s ~= s then return true end
    return nil
  end)
end

function Host.draw()
  CallWindow.draw(Host._s)
end

return CallWindow
