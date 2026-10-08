local SpecialScene = {}

local function Rse()
  return require("src.core.game3.rse.init")
end

local function FieldView()
  return require("src.core.game3.field_view")
end

SpecialScene._orb = nil
SpecialScene._spot = nil
SpecialScene._porthole = nil

local SSTIDAL = {
  DEPART_SLATEPORT = 2,
  HALFWAY_SLATEPORT = 7,
  EXIT_RIGHT = 9,
  EXIT_LEFT = 10,
  MAX_STEPS = 205,
}
SpecialScene.SS_TIDAL_MAX_STEPS = SSTIDAL.MAX_STEPS

-- pokeemerald/src/field_special_scene.c:281-295
function SpecialScene.portholeDestination(state, steps, mapGroups)
  state, steps = tonumber(state) or 0, math.max(0, tonumber(steps) or 0)
  local map, x
  if state == SSTIDAL.DEPART_SLATEPORT then
    if steps < 60 then map, x = "MAP_ROUTE134", steps + 19
    elseif steps < 140 then map, x = "MAP_ROUTE133", steps - 60
    else map, x = "MAP_ROUTE132", steps - 140 end
  elseif state == SSTIDAL.HALFWAY_SLATEPORT then
    if steps < 66 then map, x = "MAP_ROUTE132", 65 - steps
    elseif steps < 146 then map, x = "MAP_ROUTE133", 145 - steps
    else map, x = "MAP_ROUTE134", 224 - steps end
  else
    return nil
  end
  local entry = mapGroups and mapGroups[map]
  if type(entry) ~= "table" then return nil end
  return { group = tonumber(entry.group), num = tonumber(entry.num), x = x, y = 20, map = map }
end

local function portholeWarp(map, x, y, done)
  local Runtime = package.loaded["src.core.game3.runtime"] or require("src.core.game3.runtime")
  local Warp = require("src.core.game3.warp")
  Warp.scripted(Runtime._mod, Runtime._game, "warp", map, x, y, nil, done)
end

local function finishPorthole(scene)
  if not scene or scene.returning then return end
  local Player = require("src.core.game3.player")
  if Player.moving then
    scene.exitRequested = true
    return
  end
  scene.returning = true
  local R = Rse()
  local exitState = scene.direction == "right" and SSTIDAL.EXIT_RIGHT or SSTIDAL.EXIT_LEFT
  if not scene.exitStateOnCruiseEndOnly or scene.cruiseEnded then
    R.setVar(scene.stateVar or "VAR_SS_TIDAL_STATE", exitState, scene.session)
  end
  R.setFlag("FLAG_DONT_TRANSITION_MUSIC", false, scene.session)
  R.setFlag("FLAG_HIDE_MAP_NAME_POPUP", false, scene.session)
  local VirtualObjects = require("src.core.game3.virtual_objects")
  VirtualObjects.remove(scene.objectId)
  portholeWarp(scene.returnMap, scene.returnX, scene.returnY, function()
    Player.setVisible(true)
    require("src.core.game3.field").holdInput(false)
    SpecialScene._porthole = nil
    if scene.onDone then scene.onDone() end
  end)
end

-- pokeemerald/src/field_special_scene.c:367 FieldCB_ShowPortholeView
function SpecialScene.enterPorthole(session, direction, onDone, opts)
  opts = opts or {}
  local Player = require("src.core.game3.player")
  local Constants = require("src.core.game3.constants").active(session)
  local gfx = Constants:require("event_objects", "OBJ_EVENT_GFX_SS_TIDAL")
  local objectId = 0x7FEF
  local Field = require("src.core.game3.field")
  Field.holdInput(true)
  Player.setVisible(false)
  local VirtualObjects = require("src.core.game3.virtual_objects")
  VirtualObjects.remove(objectId)
  VirtualObjects.spawn(objectId, gfx, Player.cellX, Player.cellY, 3,
    direction == "right" and 2 or 1)
  SpecialScene._porthole = {
    session = session, direction = direction, objectId = objectId, graphicsId = gfx,
    stateVar = opts.stateVar,
    exitStateOnCruiseEndOnly = opts.exitStateOnCruiseEndOnly,
    onDone = onDone, tick = 0, returning = false,
    lastX = Player.cellX, lastY = Player.cellY,
    returnMap = session.dynamicWarp.map,
    returnX = session.dynamicWarp.x, returnY = session.dynamicWarp.y,
  }
end

function SpecialScene.portholeActive()
  return SpecialScene._porthole ~= nil
end

local function stepPorthole(scene)
  if scene.returning then return end
  local Player = require("src.core.game3.player")
  local Objects = require("src.core.game3.virtual_objects")
  local boat = Objects.get(scene.objectId)
  if not boat then
    boat = Objects.spawn(scene.objectId, scene.graphicsId, Player.cellX, Player.cellY, 3,
      scene.direction == "right" and 2 or 1)
  else
    boat.x, boat.y = Player.cellX, Player.cellY
  end
  if Player.isVisible() then Player.setVisible(false) end

  if Player.cellX ~= scene.lastX or Player.cellY ~= scene.lastY then
    scene.lastX, scene.lastY = Player.cellX, Player.cellY
    if SpecialScene.countSSTidalStep(1) then
      scene.cruiseEnded = true
      finishPorthole(scene)
      return
    end
  end

  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local input = game and game.input
  if input and input.wasPressed and input:wasPressed("a") then
    scene.exitRequested = true
  end
  if scene.exitRequested and not Player.moving then
    finishPorthole(scene)
    return
  end
  if not Player.moving then
    Player.scriptStep(scene.direction)
  end
end

-- pokeemerald/src/field_screen_effect.c:819
function SpecialScene.orbSpans(cx, cy, radius, bounds)
  local rows = {}
  local x0, y0, x1, y1 = 0, 0, 240, 160
  if bounds then x0, y0, x1, y1 = bounds[1], bounds[2], bounds[3], bounds[4] end
  local function put(y, l, r)
    if y < y0 or y > y1 then return end
    l = math.max(x0, math.min(x1, l))
    r = math.max(x0, math.min(x1, r))
    rows[y] = { l, r }
  end
  local r, v2, v3 = radius, radius, 0
  while r >= v3 do
    put(cy - v3, cx - r, cx + r)
    put(cy + v3, cx - r, cx + r)
    put(cy - r, cx - v3, cx + v3)
    put(cy + r, cx - v3, cx + v3)
    v2 = v2 - (v3 * 2 - 1)
    v3 = v3 + 1
    if v2 < 0 then
      v2 = v2 + 2 * (r - 1)
      r = r - 1
    end
  end
  return rows
end

-- pokeemerald/src/field_screen_effect.c:1207
function SpecialScene.startOrb(result, onReady)
  local blue, cx = false, 120
  if result == 0 then blue, cx = false, 104
  elseif result == 1 then blue, cx = true, 136
  elseif result == 2 then blue, cx = false, 120
  else blue, cx = true, 120 end
  SpecialScene._orb = {
    blue = blue, cx = cx, cy = 80, radius = 1, flashState = 0, state = 2,
    evA = 12, evB = 7, shakeDir = 0, shakeDelay = 4, onReady = onReady,
  }
  return SpecialScene._orb
end

-- pokeemerald/src/field_screen_effect.c:1236
function SpecialScene.fadeOutOrb(onDone)
  local o = SpecialScene._orb
  if not o then
    if onDone then onDone() end
    return
  end
  o.state = 6
  o.onDone = onDone
end

function SpecialScene.orbActive()
  return SpecialScene._orb ~= nil
end

local function stepOrb(o)
  if o.state == 2 then
    -- pokeemerald/src/field_screen_effect.c:881
    if o.flashState == 0 then
      o.flashState = 1
    else
      o.flashState = 0
      o.radius = o.radius + 1
      if o.radius > 160 then
        o.state = 3
        if o.onReady then
          local cb = o.onReady
          o.onReady = nil
          cb()
        end
      end
    end
  elseif o.state == 3 then
    o.shakeDir, o.shakeDelay, o.state = 0, 4, 4
  elseif o.state == 4 then
    o.shakeDelay = o.shakeDelay - 1
    if o.shakeDelay == 0 then
      o.shakeDelay = 4
      o.shakeDir = 1 - o.shakeDir
      FieldView().setCameraPanning(0, o.shakeDir == 1 and 4 or -4)
    end
  elseif o.state == 6 then
    FieldView().setCameraPanning(0, 0)
    o.shakeDelay, o.state = 8, 7
  elseif o.state == 7 then
    o.shakeDelay = o.shakeDelay - 1
    if o.shakeDelay == 0 then
      o.shakeDelay = 8
      o.shakeDir = 1 - o.shakeDir
      -- pokeemerald/src/field_screen_effect.c:1085
      if o.shakeDir ~= 0 then
        if o.evA > 0 then o.evA = o.evA - 1 end
      elseif o.evB < 16 then
        o.evB = o.evB + 1
      end
      if o.evA == 0 and o.evB == 16 then o.state = 5 end
    end
  elseif o.state == 5 then
    SpecialScene._orb = nil
    if o.onDone then o.onDone() end
  end
end

local function viewBounds()
  local x0, y0, x1, y1 = 0, 0, 240, 160
  local cv = love.graphics.getCanvas and love.graphics.getCanvas()
  if cv and love.graphics.inverseTransformPoint then
    local cw, ch = cv:getDimensions()
    local ax, ay = love.graphics.inverseTransformPoint(0, 0)
    local bx, by = love.graphics.inverseTransformPoint(cw, ch)
    x0, y0 = math.min(0, math.floor(ax)), math.min(0, math.floor(ay))
    x1, y1 = math.max(240, math.ceil(bx)), math.max(160, math.ceil(by))
  end
  return x0, y0, x1, y1
end

local function farthest(cx, cy, x0, y0, x1, y1)
  local dx = math.max(cx - x0, x1 - cx)
  local dy = math.max(cy - y0, y1 - cy)
  return math.sqrt(dx * dx + dy * dy)
end

local function drawOrb(o)
  local x0, y0, x1, y1 = viewBounds()
  local radius = math.min(o.radius, 160)
  local wide = farthest(o.cx, o.cy, x0, y0, x1, y1)
  local base = farthest(o.cx, o.cy, 0, 0, 240, 160)
  if wide > base then radius = math.floor(radius * wide / base + 0.5) end
  local rows = SpecialScene.orbSpans(o.cx, o.cy, radius, { x0, y0, x1, y1 })
  local color = o.blue and { 0, 0, 1 } or { 1, 0, 0 }
  local prevMode, prevAlpha = love.graphics.getBlendMode()
  love.graphics.setBlendMode("multiply", "premultiplied")
  local k = o.evB / 16
  love.graphics.setColor(k, k, k, 1)
  for y = y0, y1 - 1 do
    local r = rows[y]
    if r and r[2] > r[1] then love.graphics.rectangle("fill", r[1], y, r[2] - r[1], 1) end
  end
  love.graphics.setBlendMode("add", "alphamultiply")
  local a = o.evA / 16
  love.graphics.setColor(color[1] * a, color[2] * a, color[3] * a, 1)
  for y = y0, y1 - 1 do
    local r = rows[y]
    if r and r[2] > r[1] then love.graphics.rectangle("fill", r[1], y, r[2] - r[1], 1) end
  end
  love.graphics.setBlendMode(prevMode, prevAlpha)
  love.graphics.setColor(1, 1, 1, 1)
end

-- pokeemerald/src/field_effect.c:3081
function SpecialScene.startRayquazaSpotlight()
  local FxRse = require("src.core.game3.field_effects_rse")
  local P = package.loaded["src.core.game3.player"]
  local ox, oy = P and P.px - 112 or 0, P and P.py - 72 or 0
  local SINE = require("src.core.game3.trig").SINE
  local spot = { state = 0, timer = 0, y2 = 0, velocity = -1, move = 0, counter = 0 }
  local startY = oy - 24
  local e = FxRse.spawn("rayquaza", {
    layer = "front", x = ox + 120, y = startY, stopOnEnd = false, effectName = "FLDEFF_RAYQUAZA_SPOTLIGHT",
    onStep = function(rec)
      spot.timer = spot.timer + 1
      local s = spot.state
      if s == 0 then
        -- pokeemerald/src/field_effect_helpers.c:1528
        if spot.timer > 311 then spot.state, spot.timer = 1, 0 end
      elseif s == 1 then
        rec.y = math.floor(SINE[math.floor(spot.timer / 3) % 256 + 1] / 4) + startY
        if spot.timer == 189 then spot.state, spot.counter, spot.timer = 2, 0, 0 end
      elseif s == 2 then
        if spot.timer == 60 then spot.counter, spot.timer = spot.counter + 1, 0 end
        if spot.counter == 7 then spot.counter, spot.state = 0, 3 end
      elseif s == 3 then
        if spot.y2 == 0 then spot.timer, spot.state = 0, 4 end
        if spot.timer == 5 then
          spot.timer = 0
          spot.y2 = spot.y2 > 0 and spot.y2 - 1 or spot.y2 + 1
        end
      elseif s == 4 then
        if spot.timer == 60 then spot.state, spot.timer, spot.counter = 5, 0, 0 end
      elseif s == 5 then
        spot.state, spot.timer, spot.fig = 6, 0, 0
      elseif s == 6 then
        spot.fig = spot.fig + 1
        if spot.fig >= 4 * 72 then
          spot.timer = 0
          spot.counter = spot.counter + 1
          if spot.counter <= 2 then spot.fig = 0 else spot.counter, spot.state = 0, 7 end
        end
      elseif s == 7 then
        if spot.timer == 30 then spot.state, spot.timer = 8, 0 end
      elseif s == 8 then
        return true
      end
      if spot.state == 1 then
        -- pokeemerald/src/field_effect_helpers.c:1618
        if spot.move % 8 == 0 then spot.y2 = spot.y2 + spot.velocity end
        if spot.move % 16 == 0 then spot.velocity = -spot.velocity end
        spot.move = spot.move + 1
      end
      rec.y2draw = spot.y2
      return false
    end,
  })
  SpecialScene._spot = spot
  return e
end

-- pokeemerald/src/field_specials.c:276
function SpecialScene.setSSTidalFlag()
  Rse().setFlag("FLAG_SYS_CRUISE_MODE", true)
  Rse().setVar("VAR_CRUISE_STEP_COUNT", 0)
end

-- pokeemerald/src/field_specials.c:282
function SpecialScene.resetSSTidalFlag()
  Rse().setFlag("FLAG_SYS_CRUISE_MODE", false)
end

-- pokeemerald/include/constants/field_specials.h:27
SpecialScene.SS_TIDAL_MAX_STEPS = 205

-- pokeemerald/src/field_specials.c:288
function SpecialScene.countSSTidalStep(delta)
  if not Rse().flag("FLAG_SYS_CRUISE_MODE") then return false end
  local v = (Rse().var("VAR_CRUISE_STEP_COUNT") + (tonumber(delta) or 1)) % 0x10000
  Rse().setVar("VAR_CRUISE_STEP_COUNT", v)
  return v >= SpecialScene.SS_TIDAL_MAX_STEPS
end

function SpecialScene.step()
  local o = SpecialScene._orb
  if o then stepOrb(o) end
  if SpecialScene._porthole then stepPorthole(SpecialScene._porthole) end
end

function SpecialScene.drawOverlay()
  local o = SpecialScene._orb
  if o then drawOrb(o) end
end

function SpecialScene.reset()
  SpecialScene._orb = nil
  SpecialScene._spot = nil
  SpecialScene._porthole = nil
end

local VAR_RESULT = 0x800D

SpecialScene.BY_NAME = {
  -- pokeemerald/src/field_screen_effect.c:1207
  DoOrbEffect = function(ctx)
    local ready = false
    SpecialScene.startOrb(Rse().specialVar(ctx, VAR_RESULT), function() ready = true end)
    ctx.stateWait = function() return ready end
    return false
  end,
  -- pokeemerald/src/field_screen_effect.c:1236
  FadeOutOrbEffect = function(ctx)
    local done = false
    SpecialScene.fadeOutOrb(function() done = true end)
    ctx.stateWait = function() return done end
    return false
  end,
  SetSSTidalFlag = function()
    SpecialScene.setSSTidalFlag()
    return false
  end,
  ResetSSTidalFlag = function()
    SpecialScene.resetSSTidalFlag()
    return false
  end,
}

return SpecialScene
