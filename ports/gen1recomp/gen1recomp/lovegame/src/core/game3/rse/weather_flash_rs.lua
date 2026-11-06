-- pokeruby/src/field_weather_effects.c:290
local M = {_state = nil}

function M.advance(s)
  if s.phase == 0 then s.y, s.delay, s.phase = 0, 0, 1 end
  if s.phase == 1 then
    s.y = math.min(16, s.y + 3)
    if s.y == 16 then s.phase = 2 end
  elseif s.phase == 2 then
    s.delay = s.delay + 1
    if s.delay > 9 then
      s.delay, s.y = 0, s.y - 1
      if s.y <= 0 then s.y, s.phase = 0, 3 end
    end
  elseif s.phase == 3 then
    s.y, s.phase = 0, 4
  elseif s.phase == 4 then
    return true
  end
  return false
end

function M.start(onDone)
  assert(not M._state, "RS weather flash already active")
  local s = {phase = 0, y = 0, delay = 0}
  M._state = s
  s.task = require("src.core.game3.task").spawn(function()
    if M._state ~= s then return true end
    if M.advance(s) then
      M._state = nil
      if onDone then onDone() end
      return true
    end
    return false
  end, {data = s})
  return s
end

function M.isActive() return M._state ~= nil end

function M.reset()
  local s = M._state
  M._state = nil
  if s and s.task then require("src.core.game3.task").cancel(s.task.id) end
  if M._copy and M._copy.release then M._copy:release() end
  if M._shader and M._shader.release then M._shader:release() end
  M._copy, M._shader = nil, nil
end

local SHADER = [[
extern float evY;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
  vec4 field = Texel(texture, uv);
  vec3 rgb5 = floor(field.rgb * 31.0 + 0.5);
  vec3 mixed = rgb5 + floor((vec3(31.0) - rgb5) * evY / 16.0);
  return vec4(mixed / 31.0, field.a);
}
]]

function M.drawField()
  local s = M._state
  if not s or s.y == 0 then return end
  local G = love.graphics
  local canvas = G.getCanvas()
  G.push("all")
  G.origin()
  G.setShader()
  if not canvas then
    G.setColor(1, 1, 1, s.y / 16)
    G.rectangle("fill", 0, 0, 240, 160)
    G.pop()
    return
  end
  local w, h = canvas:getDimensions()
  local copy = M._copy
  if not copy or copy:getWidth() ~= w or copy:getHeight() ~= h then
    if copy and copy.release then copy:release() end
    copy = G.newCanvas(w, h, {dpiscale = canvas.getDPIScale and canvas:getDPIScale() or 1,
      format = canvas.getFormat and canvas:getFormat() or "normal"})
    copy:setFilter("nearest", "nearest")
    M._copy = copy
  end
  G.setCanvas(copy)
  G.clear(0, 0, 0, 0)
  G.setBlendMode("replace", "premultiplied")
  G.setColor(1, 1, 1, 1)
  G.draw(canvas, 0, 0)
  G.setCanvas(canvas)
  M._shader = M._shader or G.newShader(SHADER)
  M._shader:send("evY", s.y)
  G.setShader(M._shader)
  G.draw(copy, 0, 0)
  G.pop()
end

return M
