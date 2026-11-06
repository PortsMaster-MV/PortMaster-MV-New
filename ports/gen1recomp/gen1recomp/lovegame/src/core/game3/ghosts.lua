local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local Ghosts = {}

Ghosts._pools = {}

local function Map()
  return package.loaded["src.core.game3.map"] or lazyReq("src.core.game3.map")
end

local function Objects()
  return package.loaded["src.core.game3.objects"] or lazyReq("src.core.game3.objects")
end

local permsLoaded, permsMod
local function permissions()
  if not permsLoaded then
    local ok, P = pcall(lazyReq, "src.world.gen2.Permissions")
    permsMod = ok and P or nil
    permsLoaded = true
  end
  return permsMod
end

local function defsFor(mapId, def)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local ev = Space and Space.bundle and Space.bundle.events
    and Space.bundle.events[mapId]
  local defs = ev and (ev.objects or ev.objectEvents)
  if type(defs) ~= "table" then defs = def and def.objects end
  return type(defs) == "table" and defs or nil
end

local function contextFor(entry, pool)
  local layout = entry.def and entry.def.midLayout
  local P = permissions()
  return {
    ox = entry.ox or 0,
    oy = entry.oy or 0,
    canEnter = function(tx, ty, fromX, fromY, dir)
      if not layout then return false end
      if tx < 0 or ty < 0 or tx >= (layout.width or 0) or ty >= (layout.height or 0) then
        return false
      end
      -- pokefirered/src/event_object_movement.c:4889
      if dir and entry.def then
        local C = lazyReq("src.core.game3.collision")
        if C.directionallyImpassableOn
            and C.directionallyImpassableOn(entry.def, fromX, fromY, tx, ty, dir) then
          return false
        end
      end
      local coll = layout:collAt(tx, ty)
      if P and P.isWalkable then return P.isWalkable(coll) end
      return coll ~= 0x07 and coll ~= 0xff and coll ~= 0x29
    end,
    blocks = function(tx, ty, exceptId)
      for _, lid in ipairs(pool.order or {}) do
        local eo = pool.byId[lid]
        if eo and lid ~= exceptId and eo.visible and not eo.hidden and not eo.passable then
          if eo.cellX == tx and eo.cellY == ty then return true end
          if eo.moving and eo.targetX == tx and eo.targetY == ty then return true end
        end
      end
      return Objects().playerBlocks(tx + (entry.ox or 0), ty + (entry.oy or 0))
    end,
  }
end

Ghosts._contextFor = contextFor

local ctxCache = setmetatable({}, { __mode = "k" })

local EMPTY = {}
local syncPlaced = {}

-- True when the last rebuild still describes Map.world and the pool table:
-- same world list, a pool for every placed map and no extra pools.
local function syncCurrent(world)
  if Ghosts._syncWorld ~= world or Ghosts._syncPools ~= Ghosts._pools then return false end
  local n = 0
  for _, entry in ipairs(world) do
    if not Ghosts._pools[entry.id] then return false end
    n = n + 1
  end
  for id in pairs(Ghosts._pools) do
    if not syncPlaced[id] and id ~= Ghosts._held then return false end
    n = n - 1
  end
  return n == 0 or (Ghosts._held ~= nil and n == -1)
end

Ghosts.FADE_WINDOW = 3

function Ghosts.openFadeWindow()
  Ghosts._fadeWindow = Ghosts.FADE_WINDOW
end

function Ghosts.visibleIds(mapId)
  local pool = Ghosts._pools[mapId]
  if not pool then return nil end
  local seen = {}
  for _, eo in ipairs(Objects().poolForDraw(pool)) do seen[eo.localId] = true end
  return seen
end

local function markFade(pool, entry)
  local P = package.loaded["src.core.game3.player"]
  local px, py = P and tonumber(P.cellX), P and tonumber(P.cellY)
  if not (px and py) then return end
  for _, eo in pairs(pool.byId) do
    local x, y = (eo.cellX or 0) + (entry.ox or 0), (eo.cellY or 0) + (entry.oy or 0)
    if eo.visible and not eo.hidden and not eo.invisible
        and x >= px - 9 and x <= px + 10 and y >= py - 7 and y <= py + 9 then
      eo.fadeIn = 0
    end
  end
end

local function prepareOffscreen(M, entry)
  local Obj = Objects()
  local Stream = package.loaded["src.core.game3.asset_stream"]
  if not (love and love.thread and love.thread.newThread) or (Stream and Stream.workerFailed) then return false end
  if not (M.warmRect and M.warmNear and Obj.prefetchMap and Obj.preparationReady) then return false end
  local x0, y0, x1, y1 = M.warmRect(0)
  -- Visible actors and collision queries retain immediate authoritative
  -- adoption. Offscreen pools can wait for immutable worker preparation.
  if not x0 or M.warmNear(entry, x0, y0, x1, y1) then return false end
  x0, y0, x1, y1 = M.warmRect()
  if not M.warmNear(entry, x0, y0, x1, y1) then return true end
  if not Obj.prefetchMap(entry.id, entry.def, 1) then return false end
  return not Obj.preparationReady(entry.id, entry.def)
end

function Ghosts.sync()
  local M = Map()
  local world = M.world or EMPTY
  if not syncCurrent(world) then
    local placed = syncPlaced
    for id in pairs(placed) do placed[id] = nil end
    for _, entry in ipairs(world) do
      placed[entry.id] = true
      if not Ghosts._pools[entry.id] and not prepareOffscreen(M, entry) then
        local defs = defsFor(entry.id, entry.def)
        if defs then
          local pool = Objects().spawnFromDefs(defs, entry.def, entry.id)
          Ghosts._pools[entry.id] = pool
          if (Ghosts._fadeWindow or 0) > 0 then markFade(pool, entry) end
        end
      end
    end
    for id in pairs(Ghosts._pools) do
      if not placed[id] and id ~= Ghosts._held then
        Ghosts._pools[id] = nil
      end
    end
    Ghosts._syncWorld, Ghosts._syncPools = world, Ghosts._pools
  end
  local placed = syncPlaced
  if Ghosts._held and not placed[Ghosts._held] then
    Ghosts._heldGrace = (Ghosts._heldGrace or 0) + 1
    if Ghosts._heldGrace > 2 then
      Ghosts._pools[Ghosts._held] = nil
      Ghosts._held = nil
      Ghosts._heldGrace = nil
    end
  else
    Ghosts._heldGrace = nil
  end
end

-- Neighbour NPCs only step while their map is near the camera (one screen of
-- margin past the view); farther pools hold still (pret only runs object
-- events spawned around the camera, TrySpawnObjectEvents).  Raise
-- TICK_MARGIN_SCREENS (math.huge = tick every pool) to widen it.
Ghosts.TICK_MARGIN_SCREENS = 1

local function tickRect()
  local P = package.loaded["src.core.game3.player"]
  local px, py = P and tonumber(P.cellX), P and tonumber(P.cellY)
  if not (px and py) then return nil end
  local FieldView = package.loaded["src.core.game3.field_view"]
  local Display = package.loaded["src.core.game3.display"]
  local vw = (FieldView and FieldView._viewW) or (Display and Display.W) or 240
  local vh = (FieldView and FieldView._viewH) or (Display and Display.H) or 160
  local cols, rows = math.ceil(vw / 16), math.ceil(vh / 16)
  local mx = math.ceil(cols / 2) + 1 + cols * Ghosts.TICK_MARGIN_SCREENS
  local my = math.ceil(rows / 2) + 1 + rows * Ghosts.TICK_MARGIN_SCREENS
  -- cull rect in current-map cells
  return px - mx, py - my, px + mx, py + my
end

local function nearView(entry, x0, y0, x1, y1)
  if not x0 then return true end
  local layout = entry.def and entry.def.midLayout
  local w = layout and layout.width
  local h = layout and layout.height
  if not (w and h) then return true end
  local ox, oy = entry.ox or 0, entry.oy or 0
  return ox + w > x0 and ox <= x1 and oy + h > y0 and oy <= y1
end

function Ghosts.update(game)
  if (Ghosts._fadeWindow or 0) > 0 then Ghosts._fadeWindow = Ghosts._fadeWindow - 1 end
  local M = Map()
  local Obj = Objects()
  local x0, y0, x1, y1 = tickRect()
  for _, entry in ipairs(M.world or EMPTY) do
    local pool = Ghosts._pools[entry.id]
    if pool and nearView(entry, x0, y0, x1, y1) then
      local c = ctxCache[entry]
      if not c or c.pool ~= pool or c.def ~= entry.def or c.layout ~= (entry.def and entry.def.midLayout) or c.ox ~= entry.ox or c.oy ~= entry.oy then
        c = { pool = pool, def = entry.def, layout = entry.def and entry.def.midLayout, ox = entry.ox, oy = entry.oy, ctx = contextFor(entry, pool) }
        ctxCache[entry] = c
      end
      Obj.tickPool(pool, game, c.ctx)
    end
  end
end

function Ghosts.forDraw(mapId)
  local pool = Ghosts._pools[mapId]
  if not pool then return nil end
  return Objects().poolForDraw(pool)
end

-- pokefirered/src/event_object_movement.c:4899
function Ghosts.blocksOn(mapId, def, tx, ty)
  local pool = Ghosts._pools[mapId]
  if not pool then
    local defs = defsFor(mapId, def)
    if not defs then return false end
    pool = Objects().spawnFromDefs(defs, def, mapId)
    Ghosts._pools[mapId] = pool
  end
  for _, lid in ipairs(pool.order or {}) do
    local eo = pool.byId[lid]
    if eo and eo.visible and not eo.hidden and not eo.passable then
      if eo.cellX == tx and eo.cellY == ty then return true end
      if eo.moving and eo.targetX == tx and eo.targetY == ty then return true end
    end
  end
  return false
end

function Ghosts.capture(mapId)
  if not mapId then return end
  local snap = Objects().snapshotPool()
  if snap.mapId ~= mapId then return end
  local pool = { byId = {}, order = {}, bounds = snap.bounds }
  for _, lid in ipairs(snap.order or {}) do
    local eo = snap.byId[lid]
    if eo and eo.foreignMap == nil then
      pool.byId[lid] = eo
      pool.order[#pool.order + 1] = lid
      eo.scriptBusy = false
      eo.frozen = false
    end
  end
  Ghosts._pools[mapId] = pool
  Ghosts._held = mapId
  Ghosts._heldGrace = nil
end

function Ghosts.adopt(mapId)
  if not mapId then return end
  local pool = Ghosts._pools[mapId]
  if not pool then return end
  Objects().adoptPool(pool)
  Ghosts._pools[mapId] = nil
  if Ghosts._held == mapId then Ghosts._held = nil end
end

function Ghosts.clear()
  Ghosts._pools = {}
  Ghosts._held = nil
  Ghosts._heldGrace = nil
end

return Ghosts
