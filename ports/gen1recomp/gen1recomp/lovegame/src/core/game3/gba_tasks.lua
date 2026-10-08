local Tasks = {}
Tasks.__index = Tasks

Tasks.COUNT = 16
local HEAD, TAIL = 0xFE, 0xFF

local function dummy() end

function Tasks.new()
  local self = setmetatable({ t = {} }, Tasks)
  self:reset()
  return self
end

-- pokeemerald/src/task.c:9
function Tasks:reset()
  for i = 0, Tasks.COUNT - 1 do
    local d = {}
    for k = 0, 15 do d[k] = 0 end
    self.t[i] = { id = i, isActive = false, func = dummy, prev = i, next = i + 1, priority = -1, data = d }
  end
  self.t[0].prev = HEAD
  self.t[Tasks.COUNT - 1].next = TAIL
end

local function firstActive(self)
  for i = 0, Tasks.COUNT - 1 do
    local t = self.t[i]
    if t.isActive and t.prev == HEAD then return i end
  end
  return Tasks.COUNT
end

-- pokeemerald/src/task.c:47
local function insert(self, id)
  local tid = firstActive(self)
  local n = self.t[id]
  if tid == Tasks.COUNT then
    n.prev, n.next = HEAD, TAIL
    return
  end
  while true do
    local cur = self.t[tid]
    if n.priority < cur.priority then
      n.prev = cur.prev
      n.next = tid
      if cur.prev ~= HEAD then self.t[cur.prev].next = id end
      cur.prev = id
      return
    end
    if cur.next == TAIL then
      n.prev = tid
      n.next = cur.next
      cur.next = id
      return
    end
    tid = cur.next
  end
end

-- pokeemerald/src/task.c:27
function Tasks:create(func, priority)
  for i = 0, Tasks.COUNT - 1 do
    local t = self.t[i]
    if not t.isActive then
      t.func = func
      t.priority = priority or 0
      insert(self, i)
      for k = 0, 15 do t.data[k] = 0 end
      t.isActive = true
      return i
    end
  end
  return 0
end

-- pokeemerald/src/task.c:84
function Tasks:destroy(id)
  local t = self.t[id]
  if not t.isActive then return end
  t.isActive = false
  if t.prev == HEAD then
    if t.next ~= TAIL then self.t[t.next].prev = HEAD end
  elseif t.next == TAIL then
    self.t[t.prev].next = TAIL
  else
    self.t[t.prev].next = t.next
    self.t[t.next].prev = t.prev
  end
end

-- pokeemerald/src/task.c:110
function Tasks:run(ctx)
  local id = firstActive(self)
  if id == Tasks.COUNT then return end
  repeat
    local t = self.t[id]
    t.func(id, t.data, ctx)
    id = self.t[id].next
  until id == TAIL
end

function Tasks:get(id)
  return self.t[id]
end

function Tasks:setFunc(id, func)
  self.t[id].func = func
end

function Tasks:isActive(func)
  for i = 0, Tasks.COUNT - 1 do
    local t = self.t[i]
    if t.isActive and t.func == func then return true end
  end
  return false
end

return Tasks
