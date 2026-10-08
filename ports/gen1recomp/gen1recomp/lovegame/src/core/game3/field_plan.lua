-- Prepare current/near seam cell windows ahead of drawing. Snapshot sampling
-- preserves custom layouts; worker results never contain graphics objects.
local Cells = require("src.core.game3.field_cell_prepare")
local Connections = require("src.core.game3.connections")
local Plan = {}
local records, task = {}, nil
local MARGIN = 4
local function stamp(layout, def)
  local borders = {}
  for i, mid in pairs(layout.borderMids or {}) do borders[i] = mid end
  return { layout = layout, def = def, defPair = def.pair, revision = layout._revision or 0, cells = layout.cells, overrides = layout.overrides,
    width = layout.width, height = layout.height, trueWidth = layout.trueWidth, trueHeight = layout.trueHeight,
    borderWidth = layout.borderWidth, borderHeight = layout.borderHeight, borders = borders,
    pair = layout.pair, midAt = layout.midAt }
end
local function valid(record, mode)
  if record.mode ~= mode then return false end
  if record.voidRevision ~= (require("src.core.game3.void_fill")._revision or 0) then return false end
  for _, s in ipairs(record.stamps) do
    local l = s.layout
    if s.def.midLayout ~= l or s.def.pair ~= s.defPair or (l._revision or 0) ~= s.revision or l.cells ~= s.cells or l.overrides ~= s.overrides
        or l.width ~= s.width or l.height ~= s.height or l.pair ~= s.pair or l.midAt ~= s.midAt then return false end
    if l.trueWidth ~= s.trueWidth or l.trueHeight ~= s.trueHeight or l.borderWidth ~= s.borderWidth
        or l.borderHeight ~= s.borderHeight then return false end
    local current = l.borderMids or {}
    for i, mid in pairs(s.borders) do if current[i] ~= mid then return false end end
    for i, mid in pairs(current) do if s.borders[i] ~= mid then return false end end
  end
  return true
end
local function graphValid(record, Map)
  if #record.world ~= #(Map.world or {}) or #record.neighbors ~= #(Map.neighborList or {}) then
    Plan._graphMiss = string.format("counts:%d/%d,%d/%d", #record.world, #(Map.world or {}), #record.neighbors, #(Map.neighborList or {})); return false
  end
  for i, entry in ipairs(Map.world or {}) do
    local old = record.world[i]
    if old.id ~= entry.id or old.def ~= entry.def or old.ox ~= entry.ox or old.oy ~= entry.oy then
      Plan._graphMiss = string.format("world:%s/%s,%s/%s,%s/%s", old.id, entry.id, old.ox, entry.ox, old.oy, entry.oy); return false
    end
  end
  for i, n in ipairs(Map.neighborList or {}) do
    local old = record.neighbors[i]
    if old.dir ~= n.dir or old.offset ~= n.offset or old.def ~= n.def then
      Plan._graphMiss = string.format("neighbor:%s/%s,%s/%s", old.dir, n.dir, old.offset, n.offset); return false
    end
  end
  return true
end
local function contains(s, x, y, w, h)
  return x >= s.x0 and y >= s.y0 and x + w <= s.x0 + s.cols and y + h <= s.y0 + s.rows
end
function Plan.invalidate()
  if task then task:cancel() end
  task, records = nil, {}
end
local function snapshot(game, id, x, y, cols, rows, mode, Native, reachW, reachH)
  local Map = require("src.core.game3.map")
  local maps = game.data.maps
  local def = maps[id]
  local root = def and def.midLayout
  if not root then return nil end
  -- Map.load changes current before the next draw refreshes Map.world. Do not
  -- replace a forecast with the previous root's graph during that interval.
  local world = id == Map._worldRoot and Map.world or Map.computeWorld(maps, id, Map.WORLD_HOPS, reachW, reachH)
  local s = { x0 = x - MARGIN, y0 = y - MARGIN, cols = cols + MARGIN * 2, rows = rows + MARGIN * 2,
    mode = mode, layouts = {}, neighbors = {}, world = {} }
  local stamps, added, neighborDefs = {}, {}, {}
  local function add(d, ox, oy, primary)
    local l = d and d.midLayout
    if not l then return nil end
    local positions = added[l] or {}; added[l] = positions
    local pair = l.pair or d.pair or root.pair or def.pair
    local key = tostring(ox) .. ":" .. tostring(oy) .. ":" .. tostring(pair)
    if positions[key] then return positions[key] end
    local x0, y0 = s.x0 - ox, s.y0 - oy
    local x1, y1 = x0 + s.cols - 1, y0 + s.rows - 1
    if not primary then
      x0, y0 = math.max(0, x0), math.max(0, y0)
      x1, y1 = math.min(l.width - 1, x1), math.min(l.height - 1, y1)
    end
    local w, h = math.max(0, x1 - x0 + 1), math.max(0, y1 - y0 + 1)
    local packed = l.workerPacked and l:workerPacked()
    local lines = {}
    for cy = y0, (packed and y0 - 1 or y0 + h - 1) do
      local bytes = {}
      for cx = x0, x0 + w - 1 do
        local mid = l:midAt(cx, cy)
        if type(mid) ~= "number" or mid < 0 or mid > 65535 then return nil end
        bytes[#bytes + 1] = string.char(mid % 256, math.floor(mid / 256))
      end
      lines[#lines + 1] = table.concat(bytes)
    end
    local n = #s.layouts + 1
    s.layouts[n] = { x0 = x0, y0 = y0, w = w, h = h, width = l.width, height = l.height,
      pair = pair, blob = table.concat(lines), packed = packed }
    stamps[n] = stamp(l, d); positions[key] = n
    return n
  end
  if not add(def, 0, 0, true) then return nil end
  local neighbors = id == Map.current and Map.neighborList or Connections.each(def)
  for _, n in ipairs(neighbors or {}) do
    local d = n.def or maps[n.map]
    local l = d and d.midLayout
    if d then neighborDefs[#neighborDefs + 1] = { dir = n.dir, offset = n.offset, def = d } end
    if l then
      local ox, oy = 0, 0
      if n.dir == "north" then ox, oy = n.offset, -l.height
      elseif n.dir == "south" then ox, oy = n.offset, root.height
      elseif n.dir == "west" then ox, oy = -l.width, n.offset
      else ox, oy = root.width, n.offset end
      local index = add(d, ox, oy)
      if index then s.neighbors[#s.neighbors + 1] = { dir = n.dir, offset = n.offset, layout = index } end
    end
  end
  for _, entry in ipairs(world or {}) do
    local index = add(entry.def, entry.ox, entry.oy, entry.id == id)
    if index then s.world[#s.world + 1] = { layout = index, ox = entry.ox, oy = entry.oy } end
  end
  local Void = require("src.core.game3.void_fill")
  if mode ~= "map" and mode ~= "black" and Void.primaryFor(s.layouts[1].pair) == Void.PRIMARY then
    -- hasMid(pair) demand-loads the atlas. Forecasting must not bypass the
    -- shared main-thread upload budget while the pair is still warming.
    local atlas = Native._pairs and Native._pairs[s.layouts[1].pair]
    if not atlas then return nil end
    local b = Void.borderFor(mode)
    local available = b ~= nil
    for _, mid in ipairs(b and b.mids or {}) do if not Native.hasMid(atlas, mid) then available = false end end
    if available then s.fill = { w = b.w, h = b.h, mids = {} }; for i, mid in ipairs(b.mids) do s.fill.mids[i] = mid end end
  end
  local worldDefs = {}
  for i, e in ipairs(world or {}) do worldDefs[i] = { id = e.id, def = e.def, ox = e.ox, oy = e.oy } end
  return s, stamps, worldDefs, neighborDefs
end
function Plan.prefetch(game)
  if not (love and love.thread and love.thread.newThread and game and game.data and game.data.maps) then return end
  local Stream = require("src.core.game3.asset_stream")
  if Stream.workerFailed then return end
  if not task then task = Stream.newTask("cells", function(id, data, err)
    local r = records[id]; if r then r.data, r.error = data, err end
    if err then print("[game3/field-plan] " .. tostring(id) .. ": " .. tostring(err)) end
  end) end
  local Map = require("src.core.game3.map")
  local View = package.loaded["src.core.game3.field_view"]
  local Player = package.loaded["src.core.game3.player"]
  local Native = package.loaded["src.core.game3.tileset_native"]
  if not (View and Player and Native and Map.current) then return end
  local vw, vh = View._viewW or 240, View._viewH or 160
  local cols, rows = math.ceil(vw / 16) + 3, math.ceil(vh / 16) + 3
  local cx = math.floor(((Player.px or 0) + 8 - vw / 2 + (View.cameraPanX or 0)) / 16) - 1
  local cy = math.floor(((Player.py or 0) + 8 - vh / 2 + (View.cameraPanY or 0)) / 16) - 1
  local mode = require("src.core.game3.void_fill").normalize(require("src.core.game3.void_fill").mode)
  local candidates = { { id = Map.current, ox = 0, oy = 0, distance = -1 } }
  local x0, y0, x1, y1 = Map.warmRect()
  for _, entry in ipairs(Map.world or {}) do
    if entry.id ~= Map.current and Map.warmNear(entry, x0, y0, x1, y1) then
      local l = entry.def and entry.def.midLayout
      if l then
        local dx = math.max(entry.ox - Player.cellX, Player.cellX - (entry.ox + l.width), 0)
        local dy = math.max(entry.oy - Player.cellY, Player.cellY - (entry.oy + l.height), 0)
        candidates[#candidates + 1] = { id = entry.id, ox = entry.ox, oy = entry.oy, distance = dx + dy }
      end
    end
  end
  table.sort(candidates, function(a, b) return a.distance < b.distance end)
  local wanted = {}
  for i = 1, math.min(3, #candidates) do
    local e = candidates[i]
    wanted[e.id] = true
    local x, y = cx - e.ox, cy - e.oy
    local record = records[e.id]
    if not (record and valid(record, mode) and (e.id ~= Map._worldRoot or graphValid(record, Map))
        and contains(record.snapshot, x - 1, y - 1, cols + 2, rows + 2)
        and (record.data or record.error or task.pending[e.id])) then
      local keep = {}; for id in pairs(records) do if id ~= e.id then keep[id] = true end end
      task:retain(keep)
      local s, stamps, worldDefs, neighborDefs = snapshot(game, e.id, x, y, cols, rows, mode, Native, math.ceil(vw / 16), math.ceil(vh / 16))
      if s then
        records[e.id] = { def = game.data.maps[e.id], mode = mode, snapshot = s, stamps = stamps,
          world = worldDefs, neighbors = neighborDefs, voidRevision = require("src.core.game3.void_fill")._revision or 0 }
        task:submit(e.id, s, i == 1 and 0 or 1)
      else records[e.id] = nil end
    end
  end
  task:retain(wanted)
  for id in pairs(records) do if not wanted[id] then records[id] = nil end end
  Stream.poll()
end
function Plan.get(def, x, y, cols, rows, mode)
  local Stream = package.loaded["src.core.game3.asset_stream"]
  if Stream then Stream.poll() end
  local Map = require("src.core.game3.map")
  local id = Map.current
  local r = records[id]
  Plan._lastMiss = not r and "not_queued" or r.def ~= def and "map_identity"
    or r.error and "worker_error" or not r.data and "pending" or not valid(r, mode) and "layout_revision"
    or not graphValid(r, Map) and "connections" or not contains(r.data, x, y, cols, rows) and "window" or nil
  if not Plan._lastMiss then return r.data end
end
Plan.cell = Cells.cell
return Plan
