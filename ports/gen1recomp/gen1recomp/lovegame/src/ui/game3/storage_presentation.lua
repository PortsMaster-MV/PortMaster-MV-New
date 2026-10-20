local M = {}
local P = {}
P.__index = P

local function copySlots(t, n)
  local out = {}
  for i = 1, n do out[i] = t and t[i] end
  return out
end

function M.capture(ui)
  local s = ui._session or {}
  local storage = s.storage
  local boxes = {}
  for i, b in ipairs(storage and storage.boxes or {}) do
    boxes[i] = {name = b.name, wallpaper = b.wallpaper, mons = copySlots(b.mons, 30)}
  end
  return {mode = ui.mode, cursorSlot = ui.cursorSlot, partyCursor = ui.partyCursor,
    drawerOpen = ui.drawerOpen, holdingMon = ui.holdingMon, holdingSource = ui.holdingSource,
    actionSource = ui._actionSource, actionTarget = ui._actionTarget,
    currentBox = storage and storage.currentBox or 1, boxes = boxes,
    party = copySlots(s.party, 6), subMode = ui.subMode}
end

local function inParty(v)
  return v.mode == "party_drawer" or v.mode == "action_menu" and v.actionSource == "party"
    or v.drawerOpen and v.mode ~= "browse"
end
function M.partyCoords(slot)
  if slot == 1 then return 104, 64 end
  return 152, 16 + (slot - 2) * 24
end
function M.iconCoords(loc, slot)
  if loc == "party" then return M.partyCoords(slot) end
  return 100 + ((slot - 1) % 6) * 24, 44 + math.floor((slot - 1) / 6) * 24
end
function M.cursor(v)
  if inParty(v) then
    local slot = v.partyCursor or 1
    if slot == 1 then return {x = 104, y = 52, party = true} end
    if slot == 7 then return {x = 152, y = 132, party = true} end
    return {x = 152, y = 4 + (slot - 2) * 24, party = true}
  end
  local slot = v.cursorSlot or 1
  if slot == -10 or slot == -20 then
    return {x = slot == -10 and 120 or 208, y = v.holdingMon and 8 or 14, flip = true}
  end
  if slot == 0 then return {x = 162, y = 12, header = true} end
  return {x = 100 + ((slot - 1) % 6) * 24, y = 32 + math.floor((slot - 1) / 6) * 24}
end
function M.hover(v)
  if v.holdingMon then return v.holdingMon end
  if v.mode == "action_menu" and v.actionTarget then return v.actionTarget.mon end
  if inParty(v) then return v.party[v.partyCursor or 1] end
  local b = v.boxes[v.currentBox]
  return b and b.mons[v.cursorSlot]
end
local function changedParty(a, b)
  for i = 1, 6 do if a.party[i] ~= b.party[i] then return true end end
  return false
end
local function findMon(v, mon)
  for i = 1, 6 do if v.party[i] == mon then return "party", nil, i end end
  for bi, b in ipairs(v.boxes) do
    for i = 1, 30 do if b.mons[i] == mon then return "box", bi, i end end
  end
end
local function removedPartyMon(a, b)
  for i = 1, 6 do
    if a.party[i] then
      local found = false
      for j = 1, 6 do if b.party[j] == a.party[i] then found = true end end
      if not found then return a.party[i], i end
    end
  end
end

function M.new(game, manifest)
  return setmetatable({game = game, manifest = manifest, rs = game == "ruby" or game == "sapphire",
    frame = 0, handAge = 0, waveAge = 0, headerAge = 0, queue = {}, mosaic = 0}, P)
end
function P:busy() return self.task ~= nil or #self.queue > 0 end
function P:enqueue(kind, fields)
  fields = fields or {}; fields.kind, fields.frame = kind, 0
  self.queue[#self.queue + 1] = fields
  if not self.task then self.task = table.remove(self.queue, 1) end
end
function P:finish()
  local t = self.task
  self.task = table.remove(self.queue, 1)
  self.handAge, self.headerAge = 0, 0
  if t and t.done then local done = t.done; t.done = nil; done() end
end
function P:settle(v)
  self.view = v
  local mon = M.hover(v)
  if self.portrait ~= mon then self.portrait, self.mosaic = mon, mon and 10 or 0 end
  if self.waveActive ~= (mon ~= nil) then self.waveActive, self.waveAge = mon ~= nil, 0 end
end
function P:open(v)
  self:settle(v)
  self:enqueue("screen", {opening = true, rs = self.rs, phase = "black"})
end
function P:close(done)
  if not self:busy() then self:enqueue("screen", {opening = false, rs = self.rs, phase = "init", done = done}) end
end

local function tickFade(f)
  if f.finishing then
    if f.finishing == 5 then return false end
    f.finishing = f.finishing + 1
    return true
  end
  if not f.obj and f.counter < f.delay then f.counter = f.counter + 1; return true end
  if not f.obj then f.counter, f.bg = 0, f.y else f.objs = f.y end
  f.obj = not f.obj
  if not f.obj then
    if f.y == f.target then f.finishing = 1
    elseif f.target > f.y then f.y = math.min(f.target, f.y + f.deltaY)
    else f.y = math.max(f.target, f.y - f.deltaY) end
  end
  return true
end
local function beginFade(delay, start, target, color, scope)
  local deltaY = 2
  if delay < 0 then deltaY, delay = deltaY - delay, 0 end
  local f = {delay = delay, counter = delay, y = start, target = target,
    bg = start, objs = start, color = color, scope = scope, obj = false, deltaY = deltaY}
  tickFade(f)
  return f
end
function P:summaryOut(done)
  if not self:busy() then self:enqueue("fade", {done = done, direction = "out"}); return true end
  return false
end
function P:summaryReturn(v)
  self:settle(v)
  self:enqueue("fade", {direction = "in", fade = beginFade(self.rs and 0 or -1, 16, 0, "black", "all")})
end

local function initScreen(t, manifest)
  local e = assert(manifest and manifest.pcScreenEffect, "native RS PC screen effect metadata missing")
  assert(e.bar, "native RS PC screen bar missing")
  t.centerY, t.half, t.heightStep = e.centerY, t.opening and e.openingHalfHeight or e.closingHalfHeight, e.heightStep
  t.bars, t.completed, t.effect = {}, 0, e
  local speed = t.opening and e.speed or 20
  local records = t.opening and e.openingBars or e.closingBars
  for i = 1, e.bars do
    local b = assert(records[i], "native RS PC screen bar coordinates missing")
    t.bars[i] = {x = b.x, y = b.y, dx = b.dx < 0 and -speed or speed,
      targetX = b.targetX, visible = t.opening, dead = false, stopped = false}
  end
end
local function animateBars(t)
  local e = t.effect
  for _, b in ipairs(t.bars) do
    if not b.dead and not b.stopped and (t.opening or t.half == 1) then
      b.x = b.x + b.dx
      if t.opening then
        if b.x < e.exitLeft or b.x > e.exitRight then b.dead = true; t.completed = t.completed + 1 end
      else
        if b.x > e.visibleLeft and b.x < e.visibleRight then b.visible = true end
        if b.dx > 0 and b.x >= b.targetX or b.dx < 0 and b.x <= b.targetX then
          b.x, b.stopped = b.targetX, true
          t.completed = t.completed + 1
        end
      end
    end
  end
  if t.opening and t.completed == e.bars then t.phase = "expand" end
end
local function tickScreen(t, manifest)
  if t.opening then
    if t.phase == "black" then t.phase = "init"; t.black = true
    elseif t.phase == "init" then
      initScreen(t, manifest); t.black = false; t.phase = "departInitial"; animateBars(t)
    elseif t.phase == "departInitial" or t.phase == "depart" then
      t.phase = "depart"; animateBars(t)
    elseif t.phase == "expand" then
      t.half = math.min(80, t.half + t.heightStep)
      if t.half == 80 then return true end
    end
  else
    if t.phase == "init" then initScreen(t, manifest); t.phase = "shrink"
    elseif t.phase == "shrink" then
      t.half = t.half - t.heightStep
      if t.half < 2 then t.half = 1; t.phase = "arrive" end
      animateBars(t)
    elseif t.phase == "arrive" then
      if t.completed == t.effect.bars then t.phase = "cleanup"; t.black = true
      else animateBars(t) end
    elseif t.phase == "cleanup" then return true end
  end
  return false
end
function P:travel(a, b)
  local from, to = M.cursor(a), M.cursor(b)
  local dx, dy = to.x - from.x, to.y - from.y
  local wx, wy = 0, 0
  if math.abs(dx) > 128 then wx = dx > 0 and -192 or 192 end
  if math.abs(dy) > 128 then wy = dy > 0 and -192 or 192 end
  return {from = from, to = to, n = (wx ~= 0 or wy ~= 0) and 12 or 6,
    x = from.x * 256, y = from.y * 256,
    vx = (dx + wx) * 256, vy = (dy + wy) * 256}
end
local function trunc(n) return n < 0 and math.ceil(n) or math.floor(n) end
function P:beginCursor(a, b)
  local move = self:travel(a, b)
  move.a, move.b = a, b
  move.vx, move.vy = trunc(move.vx / move.n), trunc(move.vy / move.n)
  self:enqueue("cursor", move)
end
function P:compaction(a, b)
  local icons = {}
  local seen = {}
  for i = 1, 6 do
    local mon = a.party[i]
    if mon then
      for j = 1, 6 do
        if b.party[j] == mon then
          local x, y = M.partyCoords(i)
          local tx, ty = M.partyCoords(j)
          icons[#icons + 1] = {mon = mon, x = x, y = y, tx = tx, ty = ty,
            vx = trunc((tx - x) * 8 / 8), vy = trunc((ty - y) * 8 / 8)}
          seen[mon] = true
        end
      end
    end
  end
  for i = 1, 6 do
    local mon = b.party[i]
    if mon and not seen[mon] then
      local x, y = M.partyCoords(i)
      icons[#icons + 1] = {mon = mon, x = x, y = y, tx = x, ty = y, vx = 0, vy = 0}
    end
  end
  self:enqueue("compact", {a = a, b = b, icons = icons})
end
function P:scroll(a, b)
  local n = #a.boxes
  local distance = (b.currentBox - a.currentBox) % n
  local direction = distance < n / 2 and 1 or -1
  local icons = {}
  local old = a.boxes[a.currentBox]
  for i = 1, 30 do
    if old and old.mons[i] then
      local x, y = M.iconCoords("box", i)
      icons[#icons + 1] = {mon = old.mons[i], slot = i, x = x, y = y, outgoing = true, delay = 1}
    end
  end
  self:enqueue("scroll", {a = a, b = b, direction = direction, speed = -6 * direction,
    remaining = 32, state = 0, column = direction > 0 and 0 or 5,
    columnX = direction > 0 and 100 or 220, incoming = 0, icons = icons})
end

function P:observe(a, b)
  if self:busy() then return end
  if a.currentBox ~= b.currentBox then self:scroll(a, b); return end
  if a.boxes[a.currentBox] and b.boxes[b.currentBox]
    and a.boxes[a.currentBox].wallpaper ~= b.boxes[b.currentBox].wallpaper then
    self:enqueue("wallpaper", {a = a, b = b, phase = 0}); return
  end
  local from, to = M.cursor(a), M.cursor(b)
  if not a.holdingMon and b.holdingMon then
    self:enqueue("grab", {a = a, b = b, mon = b.holdingMon, source = b.holdingSource})
    if changedParty(a, b) then self:compaction(a, b) end
    return
  end
  if a.holdingMon and b.holdingMon and a.holdingMon ~= b.holdingMon then
    self:enqueue("shift", {a = a, b = b, mon = a.holdingMon, target = b.holdingMon})
    return
  end
  if a.holdingMon and not b.holdingMon then
    local loc, bi, slot = findMon(b, a.holdingMon)
    self:enqueue("place", {a = a, b = b, mon = a.holdingMon,
      source = a.holdingSource, dest = {loc = loc, boxId = bi, slot = slot}})
    if changedParty(a, b) then self:compaction(a, b) end
    return
  end
  if changedParty(a, b) then
    local removed, slot = removedPartyMon(a, b)
    if removed then
      self:compaction(a, b)
    else
      local added, index
      for i = 1, 6 do
        local mon = b.party[i]
        local exists = false
        for j = 1, 6 do if a.party[j] == mon then exists = true end end
        if mon and not exists then added, index = mon, i; break end
      end
      if added then
        local loc, bi, si = findMon(a, added)
        if loc == "box" then
          self:enqueue("grab", {a = a, b = a, mon = added, source = {loc = loc, boxId = bi, slot = si}, transfer = true})
          self:enqueue("drawer", {a = a, b = a, opening = true, transfer = added})
          local partyView = {}
          for k, v in pairs(a) do partyView[k] = v end
          partyView.mode, partyView.drawerOpen, partyView.partyCursor = "party_drawer", true, index
          local move = self:travel(a, partyView)
          move.a, move.b, move.mon = a, partyView, added
          move.vx, move.vy = trunc(move.vx / move.n), trunc(move.vy / move.n)
          self:enqueue("cursor", move)
          local placedView = {}
          for k, value in pairs(b) do placedView[k] = value end
          placedView.mode, placedView.drawerOpen, placedView.partyCursor = "party_drawer", true, index
          self:enqueue("place", {a = partyView, b = placedView, mon = added, transfer = true, dest = {loc = "party", slot = index}})
          if not b.drawerOpen then
            self:enqueue("drawer", {a = placedView, b = placedView, opening = false})
            self:beginCursor(placedView, b)
          end
        else self:compaction(a, b) end
      else self:compaction(a, b) end
    end
    return
  end
  if a.drawerOpen ~= b.drawerOpen then
    self:enqueue("drawer", {a = a, b = b, opening = b.drawerOpen})
    if from.x ~= to.x or from.y ~= to.y then self:beginCursor(a, b) end
    return
  end
  if from.x ~= to.x or from.y ~= to.y or from.flip ~= to.flip then self:beginCursor(a, b); return end
  self:settle(b)
end

local function moveCursor(t)
  if t.frame < t.n then t.x, t.y = t.x + t.vx, t.y + t.vy end
  local x, y = math.floor(t.x / 256), math.floor(t.y / 256)
  if x > 256 then x = x - 192 elseif x < 64 then x = 256 - (64 - x) end
  if y > 176 then y = y - 192 elseif y < -16 then y = 176 - (-16 - y) end
  return x, y
end
local function tickScroll(t)
  if t.remaining > 0 then t.remaining = t.remaining - 1 end
  if t.state == 0 then
    t.columnX = t.columnX + t.speed
    if t.columnX < 65 or t.columnX > 251 then
      for _, icon in ipairs(t.icons) do
        if icon.outgoing and (icon.slot - 1) % 6 == t.column then icon.dead = true end
      end
      t.columnX, t.state = t.columnX + 24 * t.direction, 1
    end
  elseif t.state == 1 then
    t.columnX = t.columnX + t.speed
    local b = t.b.boxes[t.b.currentBox]
    for row = 0, 4 do
      local slot = row * 6 + t.column + 1
      local mon = b and b.mons[slot]
      if mon then
        local x, y = M.iconCoords("box", slot)
        t.icons[#t.icons + 1] = {mon = mon, slot = slot, x = x - (t.remaining + 1) * t.speed,
          y = y, targetX = x, remaining = t.remaining}
        t.incoming = t.incoming + 1
      end
    end
    if t.column == (t.direction > 0 and 5 or 0) then t.state = 2
    else t.column, t.state = t.column + t.direction, 0 end
  end
  for _, icon in ipairs(t.icons) do
    if not icon.dead then
      if icon.outgoing then
        if icon.delay > 0 then icon.delay = icon.delay - 1
        elseif icon.x >= 69 and icon.x <= 251 then icon.x = icon.x + t.speed end
      elseif icon.remaining > 0 then
        icon.x, icon.remaining = icon.x + t.speed, icon.remaining - 1
      elseif not icon.finished then
        icon.x, icon.finished = icon.targetX, true
        t.incoming = t.incoming - 1
      end
    end
  end
end
function P:update(v)
  self.frame, self.handAge, self.headerAge, self.waveAge = self.frame + 1, self.handAge + 1, self.headerAge + 1, self.waveAge + 1
  if self.mosaic > 0 then self.mosaic = self.mosaic - 1 end
  local t = self.task
  if not t then self:settle(v); return end
  t.frame = t.frame + 1
  local finished = false
  if t.kind == "cursor" then
    t.cx, t.cy = moveCursor(t)
    finished = t.frame >= t.n
  elseif t.kind == "scroll" then
    tickScroll(t)
    finished = t.frame >= 32 and t.state == 2 and t.incoming == 0
  elseif t.kind == "drawer" then finished = t.frame >= 20
  elseif t.kind == "grab" then finished = t.frame >= 20
  elseif t.kind == "place" then finished = t.frame >= 19
  elseif t.kind == "shift" then finished = t.frame >= 18
  elseif t.kind == "compact" then finished = t.frame >= 9
  elseif t.kind == "screen" then
    finished = t.rs and tickScreen(t, self.manifest) or not t.rs and t.frame >= 12
  elseif t.kind == "fade" then
    if not t.fade then t.fade = beginFade(0, t.direction == "out" and 0 or 16, t.direction == "out" and 16 or 0, "black", "all")
    else finished = not tickFade(t.fade) end
  elseif t.kind == "wallpaper" then
    if t.phase == 0 then t.fade = beginFade(1, 0, 16, "white", "wallpaper"); t.phase = 1
    elseif t.phase == 1 then
      if not tickFade(t.fade) then
        t.phase = 2; t.fade = beginFade(1, 16, 0, "white", "wallpaper")
      end
    elseif t.phase == 2 then if not tickFade(t.fade) then t.phase = 3 end
    else finished = true end
  end
  if finished then
    if t.b then self:settle(t.b) end
    self:finish()
    if not self:busy() then self:settle(v) end
  end
end

function P:drawState(current)
  local t = self.task
  local v = t and (t.a or current) or current
  local out = {view = v, clock = self.frame, handAge = self.handAge, waveAge = self.waveAge,
    headerAge = self.headerAge, mosaic = self.mosaic, cursor = M.cursor(v), overlays = {}, hidden = {}}
  if self:busy() then out.hover = self.portrait else out.hover = M.hover(current) end
  out.holding = v.holdingMon
  if not t then return out end
  local f = t.frame
  if t.kind == "screen" then out.screen = t; return out end
  if t.kind == "fade" then out.fade = t.fade; return out end
  if t.kind == "wallpaper" then
    out.view = t.phase >= 2 and t.b or t.a
    out.fade = t.fade
    return out
  end
  if t.kind == "scroll" then
    out.scroll = t
    out.cursor = M.cursor(t.b)
    local travel = self:travel(t.a, t.b)
    if travel.n == 12 and f < 12 then
      travel.frame, travel.vx, travel.vy = f, trunc(travel.vx / 12), trunc(travel.vy / 12)
      travel.x, travel.y = travel.x + travel.vx * math.min(f, 11), travel.y + travel.vy * math.min(f, 11)
      local x, y = math.floor(travel.x / 256), math.floor(travel.y / 256)
      if x > 256 then x = x - 192 elseif x < 64 then x = 256 - (64 - x) end
      out.cursor.x, out.cursor.y = x, y
    end
  elseif t.kind == "cursor" then
    local party, flip = t.from.party, t.from.flip
    if f >= t.n then party = t.to.party end
    if f >= math.floor(t.n / 2) then flip = t.to.flip end
    out.cursor = {x = t.cx or t.from.x, y = t.cy or t.from.y,
      party = party, flip = flip, header = t.from.header}
    out.drawer = t.b.drawerOpen == true
    if t.mon then out.holding = t.mon; out.hand = "holding"; out.hidden[t.mon] = true; out.drawer = true end
  elseif t.kind == "drawer" then
    out.drawerY = t.opening and (-160 + 8 * f) or (-8 * f)
    out.drawer = true
    if t.transfer then out.holding = t.transfer; out.hand = "holding"; out.hidden[t.transfer] = true end
  elseif t.kind == "compact" then
    out.view, out.drawer = t.b, t.b.drawerOpen
    out.cursor, out.holding = M.cursor(t.b), t.b.holdingMon
    out.partyIcons = {}
    for _, icon in ipairs(t.icons) do
      local step = math.min(f, 8)
      out.partyIcons[#out.partyIcons + 1] = {mon = icon.mon,
        x = f > 8 and icon.tx or math.floor((icon.x * 8 + icon.vx * step) / 8),
        y = f > 8 and icon.ty or math.floor((icon.y * 8 + icon.vy * step) / 8)}
    end
  elseif t.kind == "grab" or t.kind == "place" then
    local grab = t.kind == "grab"
    local contact = grab and 10 or 9
    local lower = grab and math.max(0, f - 1) or f
    local y2 = f < contact and math.min(lower, 8) or math.max(0, 8 - (f - contact))
    out.cursor.y = out.cursor.y + y2
    out.hand = f < contact and (grab and "grab" or "holding") or (grab and "holding" or "grab")
    if grab then
      if f < contact then out.holding = nil else out.holding = t.mon end
    else out.holding = f < contact and t.mon or nil end
    if grab and f >= contact then out.hidden[t.mon] = true end
    if not grab and f >= contact and t.dest.slot then
      local x, y = M.iconCoords(t.dest.loc, t.dest.slot)
      out.overlays[#out.overlays + 1] = {mon = t.mon, x = x, y = y}
    end
    if t.transfer and not grab then out.hidden[t.mon] = true; out.drawer = true end
  elseif t.kind == "shift" then
    out.hidden[t.target], out.hidden[t.mon] = true, true
    out.holding, out.hand = nil, "grab"
    local step = math.max(0, math.min(f - 1, 16))
    local sway = math.floor(math.sin(step * math.pi / 16) * 16)
    local x, y = out.cursor.x, out.cursor.y
    out.overlays = {{mon = t.mon, x = x - sway, y = y + 4 + math.ceil(step / 2)},
      {mon = t.target, x = x + sway, y = y + 12 - math.ceil(step / 2)}}
  end
  return out
end

function M.animFrame(entry, anim, age, fallback)
  local list = entry and entry.anims and entry.anims[anim + 1]
  if not list then list = fallback end
  if not list then return 0 end
  local left, ci, last = math.max(0, age or 0), 1, 0
  local tail = list[#list]
  if tail and tail.op == "jump" and tail.target == 0 then
    local period = 0
    for _, cmd in ipairs(list) do if cmd.op == "frame" then period = period + math.max(1, cmd.duration or 1) end end
    if period > 0 then left = left % period end
  end
  for _ = 1, 4096 do
    local c = list[ci]
    if not c then return last end
    if c.op == "frame" then
      last = c.frame or 0
      local duration = math.max(1, c.duration or 1)
      if left < duration then return last end
      left, ci = left - duration, ci + 1
    elseif c.op == "jump" then ci = (c.target or 0) + 1
    elseif c.op == "end" then return last
    else return last end
  end
  return last
end
M.HAND = {{op = "frame", frame = 0, duration = 30}, {op = "frame", frame = 1, duration = 30}, {op = "jump", target = 0}}
M.WAVES = {
  {{op = "frame", frame = 0, duration = 5}, {op = "end"}},
  {{op = "frame", frame = 1, duration = 8}, {op = "frame", frame = 2, duration = 8}, {op = "frame", frame = 3, duration = 8}, {op = "jump", target = 0}},
  {{op = "frame", frame = 4, duration = 5}, {op = "end"}},
  {{op = "frame", frame = 5, duration = 8}, {op = "frame", frame = 2, duration = 8}, {op = "frame", frame = 6, duration = 8}, {op = "jump", target = 0}},
}
return M
