local Graph = {}
Graph.__index = Graph

-- pokeemerald/include/menu_specialized.h:49
Graph.TOP_Y = 56
Graph.BOTTOM_Y = 121
Graph.HEIGHT = Graph.BOTTOM_Y - Graph.TOP_Y + 1
Graph.CENTER_X = 155
Graph.CENTER_Y = math.floor((Graph.BOTTOM_Y + Graph.TOP_Y) / 2) + 3
Graph.UPDATE_STEPS = 10
Graph.LOAD_MAX = 4
Graph.MAX_SPARKLES = 10
-- pokeemerald/include/menu_specialized.h:59
Graph.CONDITION = { COOL = 0, TOUGH = 1, SMART = 2, CUTE = 3, BEAUTY = 4 }
-- pokeemerald/include/menu_specialized.h:68
Graph.GRAPH = { COOL = 0, BEAUTY = 1, CUTE = 2, SMART = 3, TOUGH = 4 }
Graph.CONDITION_KEYS = { [0] = "cool", "tough", "smart", "cute", "beauty" }
-- pokeemerald/include/constants/pokemon.h:197
Graph.MAX_SHEEN = 255

local TOP, BOTTOM, CX, CY = Graph.TOP_Y, Graph.BOTTOM_Y, Graph.CENTER_X, Graph.CENTER_Y
local G = Graph.GRAPH

local function tdiv(a, b)
  local q = a / b
  if q >= 0 then return math.floor(q) end
  return math.ceil(q)
end

local function asr(n, s)
  return math.floor(n / 2 ^ s)
end

-- pokeemerald/src/menu_specialized.c:320
local function adj(n, s)
  return asr(n, s) + asr(n, s - 1) % 2
end

local function center()
  local out = {}
  for i = 0, 4 do out[i] = { x = CX, y = CY } end
  return out
end
Graph.empty = center

-- pokeemerald/src/menu_specialized.c:322
function Graph.new(man)
  local g = setmetatable({ man = man, conditions = {}, saved = {}, newPositions = {}, cur = {}, right = {}, left = {},
    bottom = 0, updateCounter = 0, needsDraw = false }, Graph)
  for i = 0, Graph.LOAD_MAX - 1 do
    g.conditions[i] = { [0] = 0, 0, 0, 0, 0 }
    g.saved[i] = center()
  end
  for i = 0, Graph.UPDATE_STEPS - 1 do
    g.newPositions[i] = {}
    for j = 0, 4 do g.newPositions[i][j] = { x = 0, y = 0 } end
  end
  for j = 0, 4 do g.cur[j] = { x = 0, y = 0 } end
  for i = 0, Graph.HEIGHT * 2 - 1 do g.right[i], g.left[i] = 0, 0 end
  return g
end

-- pokeemerald/include/menu_specialized.h:47
function Graph.numSparkles(sheen)
  sheen = math.floor(tonumber(sheen) or 0)
  if sheen ~= Graph.MAX_SHEEN then
    return math.floor(sheen / (math.floor(Graph.MAX_SHEEN / (Graph.MAX_SPARKLES - 1)) + 1))
  end
  return Graph.MAX_SPARKLES - 1
end

-- pokeemerald/src/menu_specialized.c:668
function Graph.calcPositions(man, conditions)
  local line, sine = man.lineLength, man.sine
  local pos = {}
  local len = line[conditions[0]] or 0
  pos[G.COOL] = { x = CX, y = CY - len }
  local sinIdx, posIdx = 64, G.COOL
  for i = 1, 4 do
    sinIdx = (sinIdx + 51) % 256
    posIdx = posIdx - 1
    if posIdx < 0 then posIdx = 4 end
    if posIdx == G.CUTE then sinIdx = (sinIdx + 1) % 256 end
    len = line[conditions[i]] or 0
    local p = { x = CX + asr(len * sine[64 + sinIdx], 8), y = CY - asr(len * sine[sinIdx], 8) }
    if posIdx <= G.CUTE and (len ~= 32 or posIdx ~= G.CUTE) then p.x = p.x + 1 end
    pos[posIdx] = p
  end
  return pos
end

-- pokeemerald/src/menu_specialized.c:351
function Graph:setNewPositions(old, new)
  for i = 0, 4 do
    for _, k in ipairs({ "x", "y" }) do
      local coord = old[i][k] * 256
      local inc = tdiv((new[i][k] - old[i][k]) * 256, Graph.UPDATE_STEPS)
      for j = 0, Graph.UPDATE_STEPS - 2 do
        self.newPositions[j][i][k] = adj(coord, 8)
        coord = coord + inc
      end
      self.newPositions[Graph.UPDATE_STEPS - 1][i][k] = new[i][k]
    end
  end
  self.updateCounter = 0
end

-- pokeemerald/src/menu_specialized.c:460
function Graph:update()
  for i = 0, 4 do
    local p = self.newPositions[self.updateCounter][i]
    self.cur[i] = { x = p.x, y = p.y }
  end
  self.needsDraw = true
end

-- pokeemerald/src/menu_specialized.c:380
function Graph:tryUpdate()
  if self.updateCounter < Graph.UPDATE_STEPS then
    self:update()
    self.updateCounter = self.updateCounter + 1
    return self.updateCounter ~= Graph.UPDATE_STEPS
  end
  return false
end

-- pokeemerald/src/menu_specialized.c:469
function Graph:calcLine(scan, p1, p2, dir, over)
  local top, bottom, x, x2, height
  local inc = 0
  if p1.y < p2.y then
    top, bottom, x, x2 = p1.y, p2.y, p1.x * 1024, p2.x
    height = bottom - top
    if height ~= 0 then inc = tdiv((x2 - p1.x) * 1024, height) end
  else
    bottom, top, x, x2 = p1.y, p2.y, p2.x * 1024, p1.x
    height = bottom - top
    if height ~= 0 then inc = tdiv((x2 - p2.x) * 1024, height) end
  end
  height = height + 1
  local ptr, row
  if over == nil then
    local r = top - TOP
    for _ = 0, height - 1 do
      scan[r * 2 + dir] = adj(x, 10) + dir
      x = x + inc
      r = r + 1
    end
    ptr, row = scan, r - 1
  elseif inc > 0 then
    local r, i = top - TOP, 0
    while i < height do
      if x >= CX * 1024 then break end
      over[r * 2 + dir] = adj(x, 10) + dir
      x = x + inc
      r, i = r + 1, i + 1
    end
    self.bottom = top + i
    r = self.bottom - TOP
    while i < height do
      scan[r * 2 + dir] = adj(x, 10) + dir
      x = x + inc
      r, i = r + 1, i + 1
    end
    ptr, row = scan, r - 1
  elseif inc < 0 then
    local r, i = top - TOP, 0
    while i < height do
      scan[r * 2 + dir] = adj(x, 10) + dir
      if x < CX * 1024 then
        scan[r * 2 + dir] = CX
        break
      end
      x = x + inc
      r, i = r + 1, i + 1
    end
    self.bottom = top + i
    r = self.bottom - TOP
    while i < height do
      over[r * 2 + dir] = adj(x, 10) + dir
      x = x + inc
      r, i = r + 1, i + 1
    end
    ptr, row = over, r - 1
  else
    self.bottom = top
    local r = top - TOP
    scan[r * 2 + 1] = p1.x + 1
    over[r * 2 + 0] = p2.x
    over[r * 2 + 1] = CX
    return
  end
  ptr[row * 2 + dir] = dir + x2
end

-- pokeemerald/src/menu_specialized.c:570
function Graph:calcRightHalf()
  local c, R = self.cur, self.right
  local y
  if c[G.COOL].y < c[G.BEAUTY].y then
    y = c[G.COOL].y
    self:calcLine(R, c[G.COOL], c[G.BEAUTY], 1, nil)
  else
    y = c[G.BEAUTY].y
    self:calcLine(R, c[G.BEAUTY], c[G.COOL], 0, nil)
  end
  self:calcLine(R, c[G.BEAUTY], c[G.CUTE], 1, nil)
  local i = (c[G.CUTE].y <= c[G.SMART].y) and 1 or 0
  self:calcLine(R, c[G.CUTE], c[G.SMART], i, self.left)
  for yy = TOP, y - 1 do R[(yy - TOP) * 2], R[(yy - TOP) * 2 + 1] = 0, 0 end
  for yy = c[G.COOL].y, self.bottom do R[(yy - TOP) * 2] = CX end
  local b = math.max(self.bottom, c[G.CUTE].y)
  for yy = b + 1, BOTTOM do R[(yy - TOP) * 2], R[(yy - TOP) * 2 + 1] = 0, 0 end
  for yy = TOP, BOTTOM do
    local r = (yy - TOP) * 2
    if R[r] == 0 and R[r + 1] ~= 0 then R[r] = CX end
  end
end

-- pokeemerald/src/menu_specialized.c:620
function Graph:calcLeftHalf()
  local c, L = self.cur, self.left
  local y
  if c[G.COOL].y < c[G.TOUGH].y then
    y = c[G.COOL].y
    self:calcLine(L, c[G.COOL], c[G.TOUGH], 0, nil)
  else
    y = c[G.TOUGH].y
    self:calcLine(L, c[G.TOUGH], c[G.COOL], 1, nil)
  end
  self:calcLine(L, c[G.TOUGH], c[G.SMART], 0, nil)
  for yy = TOP, y - 1 do L[(yy - TOP) * 2], L[(yy - TOP) * 2 + 1] = 0, 0 end
  for yy = c[G.COOL].y, self.bottom do L[(yy - TOP) * 2 + 1] = CX end
  local b = math.max(self.bottom, c[G.SMART].y + 1)
  for yy = b, BOTTOM do L[(yy - TOP) * 2], L[(yy - TOP) * 2 + 1] = 0, 0 end
  for i = 0, Graph.HEIGHT - 1 do
    if L[i * 2] >= L[i * 2 + 1] then L[i * 2], L[i * 2 + 1] = 0, 0 end
  end
end

-- pokeemerald/src/menu_specialized.c:418
function Graph:draw()
  if not self.needsDraw then return end
  self:calcRightHalf()
  self:calcLeftHalf()
  self.lines = {}
  for i = 0, Graph.HEIGHT - 1 do
    self.lines[i] = { self.right[i * 2], self.right[i * 2 + 1], self.left[i * 2], self.left[i * 2 + 1] }
  end
  self.needsDraw = false
end

local function span(a, b)
  a, b = a % 256, b % 256
  if a > 240 then a = 240 end
  if b > 240 then b = 240 end
  if a <= b then return { { a, b } } end
  return { { a, 240 }, { 0, b } }
end

-- pokeemerald/src/menu_specialized.c:441
function Graph:spans(line)
  if line < TOP or line >= BOTTOM or not self.lines then return nil end
  local row = self.lines[line - TOP + 1]
  if not row then return nil end
  local out = {}
  for _, s in ipairs(span(row[1], row[2])) do out[#out + 1] = s end
  for _, s in ipairs(span(row[3], row[4])) do out[#out + 1] = s end
  return out
end

function Graph:mask()
  local out = {}
  for y = TOP, BOTTOM - 1 do
    local row = {}
    for _, s in ipairs(self:spans(y) or {}) do
      for x = s[1], s[2] - 1 do row[x] = true end
    end
    out[y] = row
  end
  return out
end

function Graph:drawFill(drawImage)
  if not self.lines then return end
  for y = TOP, BOTTOM - 1 do
    for _, s in ipairs(self:spans(y) or {}) do
      if s[2] > s[1] then drawImage(s[1], y, s[2] - s[1], 1) end
    end
  end
end

-- pokeemerald/src/menu_specialized.c:1083
function Graph.monOnscreen(x)
  x = x + 24
  if x > 0 then x = 0 end
  return x, x ~= 0
end

-- pokeemerald/src/menu_specialized.c:1092
function Graph.monOffscreen(x)
  x = x - 24
  if x < -80 then x = -80 end
  return x, x ~= -80
end

-- pokeemerald/src/menu_specialized.c:1101
function Graph:updateMonEnter(x)
  local graphUpdating = self:tryUpdate()
  local nx, monUpdating = Graph.monOnscreen(x)
  return nx, graphUpdating or monUpdating
end

-- pokeemerald/src/menu_specialized.c:1109
function Graph:updateMonExit(x)
  local graphUpdating = self:tryUpdate()
  local nx, monUpdating = Graph.monOffscreen(x)
  return nx, graphUpdating or monUpdating
end

local Sparkles = {}
Sparkles.__index = Sparkles
Graph.Sparkles = Sparkles

-- pokeemerald/src/menu_specialized.c:1283
local ANIM_FRAMES = 7
local ANIM_DELAY = 5

-- pokeemerald/src/menu_specialized.c:1394
function Graph.sparkles(man, count)
  local s = setmetatable({ man = man, list = {} }, Sparkles)
  count = math.floor(tonumber(count) or 0)
  for i = 0, count do
    s.list[i + 1] = { id = i, invisible = true, delay = 0, numExtra = count, curId = i, anim = 0, animTimer = 0,
      animEnded = false, cb = "sparkle" }
  end
  local n = #s.list
  for i = 1, n do s.list[i].next = s.list[i % n + 1] end
  -- pokeemerald/src/menu_specialized.c:1347
  for i, sp in ipairs(s.list) do
    sp.delay = (i - 1) * 16 + 1
    if count ~= Graph.MAX_SPARKLES - 1 then
      sp.cb = "sparkle"
    else
      s:showAll(sp)
      sp.cb = "wait_all"
      sp.invisible = false
    end
  end
  return s
end

local function seek(sp)
  sp.anim, sp.animTimer, sp.animEnded = 0, 0, false
end

-- pokeemerald/src/menu_specialized.c:1484
function Sparkles:showAll(sp)
  local id = sp.next
  for _ = 0, sp.numExtra do
    seek(id)
    id.invisible = false
    id = id.next
  end
end

-- pokeemerald/src/menu_specialized.c:1374
function Sparkles:setNext(sp)
  local id = sp.next
  for _ = 0, sp.numExtra do
    id.delay = id.id * 16 + 1
    id.cb = "sparkle"
    id = id.next
  end
end

local function animate(sp)
  if sp.animEnded then return end
  sp.animTimer = sp.animTimer + 1
  if sp.animTimer >= ANIM_DELAY then
    sp.animTimer = 0
    if sp.anim + 1 >= ANIM_FRAMES then
      sp.animEnded = true
    else
      sp.anim = sp.anim + 1
    end
  end
end

-- pokeemerald/src/menu_specialized.c:1447
function Sparkles:frame(monX, monY)
  for _, sp in ipairs(self.list) do
    local cb = sp.cb
    if cb == "sparkle" then
      local go = true
      if sp.delay ~= 0 then
        sp.delay = sp.delay - 1
        if sp.delay ~= 0 then go = false else seek(sp) sp.invisible = false end
      end
      if go then
        sp.x, sp.y = self:position(sp, monX, monY)
        if sp.animEnded then
          sp.invisible = true
          if sp.curId == sp.numExtra then
            if sp.curId == Graph.MAX_SPARKLES - 1 then
              self:showAll(sp)
              sp.cb = "wait_all"
            else
              sp.cb = "next_delay"
              sp.delay = 0
            end
          else
            sp.cb = nil
          end
        end
      end
    elseif cb == "wait_all" then
      -- pokeemerald/src/menu_specialized.c:1262
      sp.x, sp.y = self:position(sp, monX, monY)
      if sp.animEnded then
        sp.delay = 0
        sp.cb = "next_delay"
      end
    elseif cb == "next_delay" then
      -- pokeemerald/src/menu_specialized.c:1253
      sp.delay = sp.delay + 1
      if sp.delay > 60 then
        sp.delay = 0
        self:setNext(sp)
      end
    end
  end
  for _, sp in ipairs(self.list) do
    if not sp.invisible then animate(sp) end
  end
end

-- pokeemerald/src/menu_specialized.c:1331
function Sparkles:position(sp, monX, monY)
  local c = self.man.sparkleCoords[sp.id]
  return monX + c[1], monY + c[2]
end

function Sparkles:draw(drawFrame)
  for _, sp in ipairs(self.list) do
    if not sp.invisible and sp.x then drawFrame(sp.anim, sp.x - 8, sp.y - 8) end
  end
end

return Graph
