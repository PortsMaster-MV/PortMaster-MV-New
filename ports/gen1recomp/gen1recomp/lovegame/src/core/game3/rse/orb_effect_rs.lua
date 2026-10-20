-- pokeruby/src/field_screen_effect.c:24
local Orb = { _state = nil }

local function tasks() return require("src.core.game3.task") end
local function view() return require("src.core.game3.field_view") end

function Orb.spans(cx, cy, radius, rows)
  rows = rows or {}
  local function put(y, left, right)
    if y < 0 or y > 160 then return end
    rows[y] = { math.max(0, math.min(255, left)), math.max(0, math.min(255, right)) }
  end
  local r, v2, v3 = radius, radius, 0
  while r >= v3 do
    put(cy - v3, cx - r, cx + r)
    put(cy + v3, cx - r, cx + r)
    put(cy - r, cx - v3, cx + v3)
    put(cy + r, cx - v3, cx + v3)
    v2 = v2 - (v3 * 2 - 1)
    v3 = v3 + 1
    if v2 < 0 then v2, r = v2 + 2 * (r - 1), r - 1 end
  end
  return rows
end

function Orb.blendColor(background, blue, evA, evB)
  local color = blue and { 0, 0, 31 } or { 31, 0, 0 }
  local out = {}
  for i = 1, 3 do
    out[i] = math.min(31, math.floor((color[i] * evA + background[i] * evB) / 16))
  end
  return out
end

function Orb.advanceFlash(o)
  local f = o.flash
  if f.phase == 2 then f.done = true; return true end
  Orb.spans(o.cx, o.cy, f.radius, o.rows)
  o.radius = f.radius
  if f.phase == 0 then
    f.phase = 1
  else
    f.phase, f.radius = 0, f.radius + 2
    if f.radius > 160 then f.phase = 2 end
  end
  return false
end

function Orb.advance(o)
  if o.phase == 0 then
    o.evA, o.evB = 12, 7
    Orb.spans(o.cx, o.cy, 1, o.rows)
    o.phase = 1
  elseif o.phase == 1 then
    o.visible, o.phase = true, 2
    o.flash = { phase = 0, radius = 1, done = false }
    o.flashTask = tasks().spawn(function()
      if Orb._state ~= o then return true end
      return Orb.advanceFlash(o)
    end, { data = o.flash })
  elseif o.phase == 2 then
    if o.flash.done then
      o.phase = 3
      local cb = o.onReady
      o.onReady = nil
      if cb then cb() end
    end
  elseif o.phase == 3 then
    view().setCameraPanning(0, 0)
    o.shakeDir, o.delay, o.phase = 0, 4, 4
    o.ownsPan = true
  elseif o.phase == 4 then
    o.delay = o.delay - 1
    if o.delay == 0 then
      o.delay, o.shakeDir = 4, 1 - o.shakeDir
      view().setCameraPanning(0, o.shakeDir == 1 and 4 or -4)
    end
  elseif o.phase == 6 then
    view().setCameraPanning(0, 0)
    o.ownsPan, o.delay, o.phase = true, 8, 7
  elseif o.phase == 7 then
    o.delay = o.delay - 1
    if o.delay == 0 then
      o.delay, o.shakeDir = 8, 1 - o.shakeDir
      if o.shakeDir == 1 then o.evA = math.max(0, o.evA - 1)
      else o.evB = math.min(16, o.evB + 1) end
      if o.evA == 0 and o.evB == 16 then o.phase = 5 end
    end
  elseif o.phase == 5 then
    Orb._state = nil
    local cb = o.onDone
    o.onDone = nil
    if cb then cb() end
    return true
  end
  return false
end

function Orb.start(result, onReady)
  assert(not Orb._state, "RS orb task already active")
  result = tonumber(result) or 0
  local o = {
    phase = 0, blue = result ~= 0 and result ~= 2,
    cx = (result == 0 or result == 1) and 104 or 120, cy = 80,
    radius = 1, rows = {}, shakeDir = 0, onReady = onReady,
  }
  Orb._state = o
  o.task = tasks().spawn(function()
    if Orb._state ~= o then return true end
    return Orb.advance(o)
  end, { data = o })
  return o
end

function Orb.fade(onDone)
  local o = assert(Orb._state, "RS FadeOutOrbEffect requires its active orb task")
  o.phase, o.onDone = 6, onDone
  return o
end

function Orb.isActive() return Orb._state ~= nil end

function Orb.reset()
  local o = Orb._state
  Orb._state = nil
  if o then
    if o.task then tasks().cancel(o.task.id) end
    if o.flashTask then tasks().cancel(o.flashTask.id) end
    if o.ownsPan then view().setCameraPanning(0, 0) end
  end
  if Orb._canvas and Orb._canvas.release then Orb._canvas:release() end
  if Orb._shader and Orb._shader.release then Orb._shader:release() end
  Orb._canvas, Orb._shader = nil, nil
end

local BLEND_SHADER = [[
extern Image fieldImage;
extern vec2 fieldSize;
extern vec3 orbColor;
extern float evA;
extern float evB;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
  vec4 field = Texel(fieldImage, screen / fieldSize);
  vec3 rgb5 = floor(field.rgb * 31.0 + 0.5);
  vec3 mixed = min(vec3(31.0), floor((orbColor * evA + rgb5 * evB) / 16.0));
  return vec4(mixed / 31.0, field.a);
}
]]

local function drawRows(o, graphics)
  for y = 0, 159 do
    local row = o.rows[y]
    if row and row[2] > row[1] then
      graphics.rectangle("fill", row[1], y, row[2] - row[1], 1)
    end
  end
end

function Orb.drawOverlay()
  local o = Orb._state
  if not (o and o.visible) then return end
  local G = love.graphics
  local current = G.getCanvas()
  if not current then
    G.push("all")
    G.setShader()
    G.setBlendMode("multiply", "premultiplied")
    G.setColor(o.evB / 16, o.evB / 16, o.evB / 16, 1)
    drawRows(o, G)
    G.setBlendMode("add", "alphamultiply")
    G.setColor(o.blue and 0 or o.evA / 16, 0, o.blue and o.evA / 16 or 0, 1)
    drawRows(o, G)
    G.pop()
    return
  end
  local w, h = current:getDimensions()
  local copy = Orb._canvas
  if not copy or copy:getWidth() ~= w or copy:getHeight() ~= h then
    if copy and copy.release then copy:release() end
    copy = G.newCanvas(w, h, { dpiscale = current.getDPIScale and current:getDPIScale() or 1,
      format = current.getFormat and current:getFormat() or "normal" })
    copy:setFilter("nearest", "nearest")
    Orb._canvas = copy
  end
  Orb._shader = Orb._shader or G.newShader(BLEND_SHADER)
  local shader = Orb._shader
  G.push("all")
  G.origin()
  G.setShader()
  G.setCanvas(copy)
  G.clear(0, 0, 0, 0)
  G.setBlendMode("replace", "premultiplied")
  G.setColor(1, 1, 1, 1)
  G.draw(current, 0, 0)
  G.pop()
  shader:send("fieldImage", copy)
  shader:send("fieldSize", { w, h })
  shader:send("orbColor", o.blue and { 0, 0, 31 } or { 31, 0, 0 })
  shader:send("evA", o.evA)
  shader:send("evB", o.evB)
  G.push("all")
  G.setShader(shader)
  G.setBlendMode("replace", "premultiplied")
  G.setColor(1, 1, 1, 1)
  drawRows(o, G)
  G.pop()
end

return Orb
