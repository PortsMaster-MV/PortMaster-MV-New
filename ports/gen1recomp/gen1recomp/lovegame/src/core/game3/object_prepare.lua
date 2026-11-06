-- CPU-only object construction shared with the field preparation worker.
local GfxIds = require("src.core.game3.scripting.gfx_ids")
local MovementTypes = require("src.core.game3.movement_types")
local Prepare = {}
local CELL, WALK_FRAMES, MOVEMENT_TYPE_INVISIBLE = 16, 16, 0x4C
local function facingFromDef(def)
  local r = tostring(def.facing or def.range or "DOWN"):lower()
  return (r == "up" or r == "down" or r == "left" or r == "right") and r or "down"
end
local inPlace
local function hostSpec(mt, rx, ry, enabled)
  local spec = GfxIds.hostMovement(mt, rx, ry)
  if not inPlace then
    inPlace = {}
    for _, kind in ipairs({
      { "firered", "MOVEMENT_TYPE_WALK_IN_PLACE_", 16, false },
      { "firered", "MOVEMENT_TYPE_WALK_IN_PLACE_FAST_", 8, false },
      { "firered", "MOVEMENT_TYPE_JOG_IN_PLACE_", 4, false },
      { "emerald", "MOVEMENT_TYPE_WALK_SLOWLY_IN_PLACE_", 32, true },
    }) do
      for suffix, dir in pairs({ DOWN = "down", UP = "up", LEFT = "left", RIGHT = "right" }) do
        local id = MovementTypes.canonOf(kind[1], kind[2] .. suffix)
        if id then inPlace[id] = { dir = dir, frames = kind[3], always = kind[4] } end
      end
    end
  end
  local ip = inPlace[mt]
  if ip and (ip.always or enabled) then
    spec.movement, spec.face, spec.range, spec.frames = "IN_PLACE", ip.dir, ip.dir:upper(), ip.frames
  end
  return spec
end

local MT_BERRY_TREE = 0x0C
-- pokeemerald/include/constants/event_object_movement.h:61
local MT_TREE_DISGUISE = 0x39
local MT_MOUNTAIN_DISGUISE = 0x3A
local MT_BURIED = 0x3F

-- pokeemerald/src/event_object_movement.c:1153
local COPY_TYPES = {
  [0x35] = { init = "up" }, [0x36] = { init = "down" }, [0x37] = { init = "left" }, [0x38] = { init = "right" },
  [0x3B] = { init = "up", grass = true }, [0x3C] = { init = "down", grass = true },
  [0x3D] = { init = "left", grass = true }, [0x3E] = { init = "right", grass = true },
}
function Prepare.initRseKind(eo)
  local mt = tonumber(eo.movementType) or 0
  eo.rseKind = nil
  local copy = COPY_TYPES[mt]
  if copy then
    eo.rseKind = "copy"
    eo.copy = { init = copy.init, grass = copy.grass }
  else
    eo.copy = nil
  end
  if mt == MT_BERRY_TREE then
    eo.rseKind = "berry_tree"
    eo.invisible = true
    eo.berryTree = eo.berryTree or { id = tonumber(eo.def and (eo.def.berryTreeId or eo.def.trainerRange)) or 0 }
  else
    eo.berryTree = nil
  end
  if mt == MT_TREE_DISGUISE or mt == MT_MOUNTAIN_DISGUISE then
    eo.rseKind = "disguise"
    -- pokeemerald/src/event_object_movement.c:4354
    local sheet = mt == MT_TREE_DISGUISE and "tree_disguise" or "mountain_disguise"
    if not (eo.disguise and eo.disguise.sheet == sheet) then eo.disguise = { sheet = sheet } end
  else
    eo.disguise = nil
  end
  if mt == MT_BURIED then
    -- pokeemerald/src/event_object_movement.c:4390
    eo.rseKind = "buried"
    eo.buried = true
    eo.invisible = true
  elseif eo.buried then
    eo.buried = nil
    eo.invisible = false
  end
end


function Prepare.instance(def, ctx)
  local lid = tonumber(def.localId or def.index) or 0
  local x, y = tonumber(def.x) or 0, tonumber(def.y) or 0
  local rawMt = ctx.rawMt
  if rawMt == nil and def.movementType ~= nil then
    local ok, value = pcall(MovementTypes.canon, ctx.version, def.movementType)
    rawMt = ok and value or tonumber(def.movementType)
  end
  local mt = rawMt or 0
  local spec = ctx.spec
  if not spec then
    if rawMt then spec = hostSpec(rawMt, def.rangeX, def.rangeY, ctx.inPlace)
    else
      local r = def.radius or { x = 1, y = 1 }
      spec = { movement = def.movement or "STAY", range = def.range or "DOWN", rangeX = r.x, rangeY = r.y, radius = r }
    end
  end
  local facing = (def.facing and facingFromDef(def)) or (rawMt and spec.face) or facingFromDef(def)
  local resolvedGfx = ctx.graphicsId or def.graphicsId or def.graphics
  local sprite = def.sprite or (resolvedGfx and GfxIds.spriteFor(resolvedGfx))
  local elev = ctx.elevation or 0
  local mg, mn = ctx.group, ctx.num
  local eo = {
    localId = lid,
    originLocalId = tonumber(def.originLocalId or def.localId or def.index) or lid,
    originMapId = def.originMapId or def.mapId or ctx.mapId,
    originMapGroup = tonumber(def.originMapGroup or def.mapGroup) or mg,
    originMapNum = tonumber(def.originMapNum or def.mapNum) or mn,
    def = def,
    cellX = x,
    cellY = y,
    px = x * CELL,
    py = y * CELL,
    homeX = x,
    homeY = y,
    facing = facing,
    sprite = sprite or "SPRITE_YOUNGSTER",
    graphicsId = resolvedGfx,
    elevation = elev,
    currentElevation = tonumber(def.elevation) or 0,
    movementType = mt,
    movement = spec.movement,
    range = spec.range,
    radius = spec.radius or { x = spec.rangeX, y = spec.rangeY },
    rangeX = spec.rangeX,
    rangeY = spec.rangeY,
    spec = spec,
    seqIndex = 0,
    sight = tonumber(def.sight or def.trainerRange) or 0,
    trainerType = tonumber(def.trainerType) or 0,
    scriptKey = def.scriptKey,
    flag = def.flag,
    visible = ctx.visible ~= false,
    hidden = ctx.visible == false,
    -- src/event_object_movement.c:1569
    invisible = mt == MOVEMENT_TYPE_INVISIBLE,
    frozen = false,
    passable = def.passable and true or false,
    moving = false,
    progress = 0,
    stepFrames = WALK_FRAMES,
    targetX = x,
    targetY = y,
    stepFlip = false,
    animClock = 0,
    scriptBusy = false,
  }
  if ctx.rse then Prepare.initRseKind(eo) end
  return eo
end

function Prepare.objects(snapshot, cancelled)
  local out = {}
  for i, def in ipairs(snapshot.defs) do
    if cancelled and cancelled() then error("object preparation cancelled") end
    out[i] = Prepare.instance(def, snapshot)
  end
  return out
end

-- Snapshot only serializable values; custom functions/metatables keep demand loading.
function Prepare.freeze(value)
  local visiting, count = {}, 0
  local function copy(v, depth)
    if type(v) ~= "table" then
      if type(v) == "function" or type(v) == "userdata" or type(v) == "thread" then error("custom object definition") end
      return v
    end
    if depth > 16 or visiting[v] or getmetatable(v) then error("custom object definition") end
    visiting[v] = true
    local out = {}
    for k, item in pairs(v) do
      count = count + 1
      if count > 32768 then error("large object definition") end
      out[copy(k, depth + 1)] = copy(item, depth + 1)
    end
    visiting[v] = nil
    return out
  end
  local ok, result = pcall(copy, value, 0)
  return ok and result or nil
end
function Prepare.matches(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not Prepare.matches(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
return Prepare
