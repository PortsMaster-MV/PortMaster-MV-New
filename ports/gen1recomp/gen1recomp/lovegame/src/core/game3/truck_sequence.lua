local Truck = {}

-- pokeemerald/include/constants/map_event_ids.h:267
Truck.LOCALID_BOX_TOP = 1
Truck.LOCALID_BOX_BOTTOM_L = 2
Truck.LOCALID_BOX_BOTTOM_R = 3

-- pokeemerald/include/constants/metatile_labels.h:253
Truck.METATILE = {}
do
  local labels = require("src.core.game3.constants").of("emerald")
  for _, k in ipairs({ "DoorClosedFloor_Bottom", "DoorClosedFloor_Mid", "DoorClosedFloor_Top",
      "ExitLight_Bottom", "ExitLight_Mid", "ExitLight_Top" }) do
    Truck.METATILE[k] = labels:require("metatile_labels", "METATILE_InsideOfTruck_" .. k)
  end
end

-- pokeemerald/src/field_special_scene.c:27
local BOX1_X, BOX1_Y = 3, 3
local BOX2_X, BOX2_Y = 0, -3
local BOX3_X, BOX3_Y = -3, 0

-- pokeemerald/src/field_special_scene.c:45
Truck.HORIZONTAL = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 2, -1, -1, -1, 0 }

-- pokeemerald/src/field_special_scene.c:61
function Truck.cameraBobY(time)
  if time % 120 == 0 then return -1 end
  if time % 10 <= 4 then return 1 end
  return 0
end

-- pokeemerald/src/field_special_scene.c:79
function Truck.boxYMovement(time)
  if (time + 120) % 180 == 0 then return -1 end
  return 0
end

local function defaultHost()
  local H = {}
  function H.setMetatile(x, y, id)
    local Field = require("src.core.game3.field")
    Field.setMetatile(x, y, id, false)
  end
  function H.drawWholeMapView()
    local FieldView = package.loaded["src.core.game3.field_view"]
    if FieldView then FieldView._nativeDirty = true end
  end
  function H.lock(on)
    local Field = require("src.core.game3.field")
    if on then
      Field.lock("truck")
    else
      Field.unlock("truck")
    end
  end
  function H.setCameraPanning(x, y)
    require("src.core.game3.field_view").setCameraPanning(x, y)
  end
  function H.setBoxOffset(localId, x, y)
    local Objects = package.loaded["src.core.game3.objects"]
    local eo = Objects and Objects.find and Objects.find(localId)
    if eo then
      eo.raiseX = x
      eo.raiseY = y
    end
  end
  function H.playSe(name)
    local SE = require("src.core.game3.se_ids")
    local id = SE[name]
    if id == nil then error("truck: unknown SE " .. tostring(name), 2) end
    require("src.core.game3.audio").playSe(id)
  end
  function H.blackout()
    local Fade = require("src.ui.game3.fade")
    Fade.clear()
    Fade.mode = Fade.MODE.TO_BLACK
    Fade.t = 16
  end
  function H.fadeInFromBlack()
    local Fade = require("src.ui.game3.fade")
    Fade.clear()
    Fade.begin(Fade.MODE.FROM_BLACK, 1)
  end
  function H.fadeActive()
    local Fade = package.loaded["src.ui.game3.fade"]
    return Fade ~= nil and Fade.isActive and Fade.isActive() or false
  end
  function H.installPanAhead()
    require("src.core.game3.field_view").setCameraPanning(0, 0)
  end
  return H
end

Truck.defaultHost = defaultHost

local state = { running = false }
Truck._state = state

local function setBoxes(host, camX, y1, y2, y3)
  host.setBoxOffset(Truck.LOCALID_BOX_TOP, BOX1_X - camX, BOX1_Y + y1)
  host.setBoxOffset(Truck.LOCALID_BOX_BOTTOM_L, BOX2_X - camX, BOX2_Y + y2)
  host.setBoxOffset(Truck.LOCALID_BOX_BOTTOM_R, BOX3_X - camX, BOX3_Y + y3)
end

-- pokeemerald/src/field_special_scene.c:89
local function truck1(host, d)
  local y1 = Truck.boxYMovement(d.timer + 30) * 4
  local y2 = Truck.boxYMovement(d.timer) * 2
  local y3 = Truck.boxYMovement(d.timer) * 4
  setBoxes(host, 0, y1, y2, y3)
  d.timer = d.timer + 1
  if d.timer == 30000 then d.timer = 0 end
  host.setCameraPanning(0, Truck.cameraBobY(d.timer))
end

-- pokeemerald/src/field_special_scene.c:116
local function truck2(host, d)
  d.horiz = d.horiz + 1
  d.vert = d.vert + 1
  if d.horiz > 5 then
    d.horiz = 0
    d.step = d.step + 1
  end
  if d.step == #Truck.HORIZONTAL then return true end
  local camX = Truck.HORIZONTAL[d.step + 1]
  if camX == 2 then d.phase = 3 end
  host.setCameraPanning(camX, Truck.cameraBobY(d.vert))
  setBoxes(host, camX, Truck.boxYMovement(d.vert + 30) * 4, Truck.boxYMovement(d.vert) * 2,
    Truck.boxYMovement(d.vert) * 4)
  return false
end

-- pokeemerald/src/field_special_scene.c:59
local function truck3(host, d)
  d.horiz = d.horiz + 1
  if d.horiz > 5 then
    d.horiz = 0
    d.step = d.step + 1
  end
  if d.step == #Truck.HORIZONTAL then return true end
  local camX = Truck.HORIZONTAL[d.step + 1]
  host.setCameraPanning(camX, 0)
  setBoxes(host, camX, 0, 0, 0)
  return false
end

function Truck.new(host)
  return {
    host = host or defaultHost(),
    state = 0,
    timer = 0,
    frames = 0,
    events = {},
    sub1 = nil,
    sub2 = nil,
    done = false,
  }
end

local function event(seq, name)
  seq.events[#seq.events + 1] = { frame = seq.frames, name = name }
  if seq.onEvent then seq.onEvent(name, seq.frames) end
end

-- pokeemerald/src/field_special_scene.c:189
function Truck.step(seq)
  if seq.done then return true end
  seq.frames = seq.frames + 1
  local host = seq.host
  local st = seq.state
  if st == 0 then
    seq.timer = seq.timer + 1
    if seq.timer == 90 then
      seq.timer = 0
      seq.sub1 = { timer = 0 }
      seq.state = 1
      host.playSe("SE_TRUCK_MOVE")
      event(seq, "se_truck_move")
    end
  elseif st == 1 then
    seq.timer = seq.timer + 1
    if seq.timer == 150 then
      host.fadeInFromBlack()
      seq.timer = 0
      seq.state = 2
      event(seq, "fade_in")
    end
  elseif st == 2 then
    seq.timer = seq.timer + 1
    if not host.fadeActive() and seq.timer > 300 then
      seq.timer = 0
      seq.sub1 = nil
      seq.sub2 = { horiz = 0, step = 0, vert = 0, phase = 2 }
      seq.state = 3
      host.playSe("SE_TRUCK_STOP")
      event(seq, "se_truck_stop")
    end
  elseif st == 3 then
    if seq.sub2 == nil then
      host.installPanAhead()
      seq.timer = 0
      seq.state = 4
    end
  elseif st == 4 then
    seq.timer = seq.timer + 1
    if seq.timer == 90 then
      host.playSe("SE_TRUCK_UNLOAD")
      event(seq, "se_truck_unload")
      seq.timer = 0
      seq.state = 5
    end
  elseif st == 5 then
    seq.timer = seq.timer + 1
    if seq.timer == 120 then
      local M = Truck.METATILE
      host.setMetatile(4, 1, M.ExitLight_Top)
      host.setMetatile(4, 2, M.ExitLight_Mid)
      host.setMetatile(4, 3, M.ExitLight_Bottom)
      host.drawWholeMapView()
      host.playSe("SE_TRUCK_DOOR")
      event(seq, "se_truck_door")
      host.lock(false)
      seq.done = true
    end
  end
  if seq.sub1 then truck1(host, seq.sub1) end
  if seq.sub2 then
    local fin
    if seq.sub2.phase == 3 then fin = truck3(host, seq.sub2) else fin = truck2(host, seq.sub2) end
    if fin then seq.sub2 = nil end
  end
  return seq.done
end

-- pokeemerald/src/field_special_scene.c:260
function Truck.execute(host, opts)
  opts = opts or {}
  local seq = Truck.new(host)
  seq.onEvent = opts.onEvent
  local h = seq.host
  local M = Truck.METATILE
  h.setMetatile(4, 1, M.DoorClosedFloor_Top)
  h.setMetatile(4, 2, M.DoorClosedFloor_Mid)
  h.setMetatile(4, 3, M.DoorClosedFloor_Bottom)
  h.drawWholeMapView()
  h.lock(true)
  h.blackout()
  state.running = true
  state.seq = seq
  if opts.spawn ~= false then
    local Task = require("src.core.game3.task")
    state.task = Task.spawn(function()
      if state.seq ~= seq then return true end
      local fin = Truck.step(seq)
      if fin then
        state.running = false
        state.task = nil
        if opts.onDone then opts.onDone(seq) end
      end
      return fin
    end)
  end
  event(seq, "execute")
  return seq
end

function Truck.isRunning()
  return state.running == true
end

-- pokeemerald/src/field_special_scene.c:271
function Truck.endSequence(host)
  if Truck.isRunning() then return false end
  host = host or defaultHost()
  host.setBoxOffset(Truck.LOCALID_BOX_TOP, BOX1_X, BOX1_Y)
  host.setBoxOffset(Truck.LOCALID_BOX_BOTTOM_L, BOX2_X, BOX2_Y)
  host.setBoxOffset(Truck.LOCALID_BOX_BOTTOM_R, BOX3_X, BOX3_Y)
  return true
end

function Truck.reset()
  if state.task then
    require("src.core.game3.task").cancel(state.task.id)
    state.task = nil
  end
  state.running = false
  state.seq = nil
  local Field = package.loaded["src.core.game3.field"]
  if Field and Field.unlock then Field.unlock("truck") end
end

function Truck.registerStepCallback()
  local ok, FM = pcall(require, "src.core.game3.forced_movement")
  if ok and FM and FM.registerStepCallback then
    -- pokeemerald/src/field_tasks.c:66
    FM.registerStepCallback("truck", function()
      Truck.endSequence()
      return false
    end)
    return true
  end
  return false
end

Truck.registerStepCallback()

return Truck
