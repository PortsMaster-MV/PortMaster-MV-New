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
-- pokeemerald/include/menu_specialized.h:68
Graph.GRAPH = { COOL = 0, BEAUTY = 1, CUTE = 2, SMART = 3, TOUGH = 4 }
Graph.COUNT = 5

local bit = require("bit")

local function shr(v, s)
  return bit.arshift(v, s)
end

-- pokeemerald/src/menu_specialized.c:320
local function shiftRightAdjusted(n, s)
  return shr(n, s) + bit.band(shr(n, s - 1), 1)
end
Graph.shiftRightAdjusted = shiftRightAdjusted

local function cdiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or math.ceil(q)
end

local function u16(v)
  return v % 0x10000
end

local function pos(x, y) return { x = x, y = y } end

-- pokeemerald/src/menu_specialized.c:322
function Graph.new(tables)
  local g = setmetatable({
    lineLength = assert(tables and tables.lineLength, "condition graph needs lineLength"),
    sine = assert(tables and tables.sine, "condition graph needs sine"),
    conditions = {}, savedPositions = {}, newPositions = {}, curPositions = {},
    scanlineRight = {}, scanlineLeft = {}, bottom = 0, needsDraw = false, updateCounter = 0,
  }, Graph)
  for j = 0, Graph.COUNT - 1 do
    for i = 0, Graph.UPDATE_STEPS - 1 do
      g.newPositions[i] = g.newPositions[i] or {}
      g.newPositions[i][j] = pos(0, 0)
    end
    for i = 0, Graph.LOAD_MAX - 1 do
      g.conditions[i] = g.conditions[i] or {}
      g.conditions[i][j] = 0
      g.savedPositions[i] = g.savedPositions[i] or {}
      g.savedPositions[i][j] = pos(Graph.CENTER_X, Graph.CENTER_Y)
    end
    g.curPositions[j] = pos(0, 0)
  end
  for i = 0, Graph.HEIGHT - 1 do
    g.scanlineRight[i] = { [0] = 0, [1] = 0 }
    g.scanlineLeft[i] = { [0] = 0, [1] = 0 }
  end
  return g
end

function Graph:sin(i)
  return self.sine[i + 1] or 0
end

function Graph.centerPositions()
  local out = {}
  for i = 0, Graph.COUNT - 1 do out[i] = pos(Graph.CENTER_X, Graph.CENTER_Y) end
  return out
end

-- pokeemerald/src/menu_specialized.c:668
function Graph:calcPositions(conditions, positions)
  positions = positions or {}
  local len = self.lineLength[(conditions[1] or 0) + 1]
  positions[Graph.GRAPH.COOL] = pos(Graph.CENTER_X, Graph.CENTER_Y - len)
  local sinIdx = 64
  local posIdx = Graph.GRAPH.COOL
  for i = 1, Graph.COUNT - 1 do
    sinIdx = (sinIdx + 51) % 256
    posIdx = posIdx - 1
    if posIdx < 0 then posIdx = Graph.COUNT - 1 end
    if posIdx == Graph.GRAPH.CUTE then sinIdx = (sinIdx + 1) % 256 end
    len = self.lineLength[(conditions[i + 1] or 0) + 1]
    local x = Graph.CENTER_X + shr(len * self:sin(64 + sinIdx), 8)
    local y = Graph.CENTER_Y - shr(len * self:sin(sinIdx), 8)
    if posIdx <= Graph.GRAPH.CUTE and (len ~= 32 or posIdx ~= Graph.GRAPH.CUTE) then x = x + 1 end
    positions[posIdx] = pos(u16(x), u16(y))
  end
  return positions
end

-- pokeemerald/src/menu_specialized.c:351
function Graph:setNewPositions(old, new)
  for i = 0, Graph.COUNT - 1 do
    for _, k in ipairs({ "x", "y" }) do
      local coord = old[i][k] * 256
      local inc = cdiv((new[i][k] - old[i][k]) * 256, Graph.UPDATE_STEPS)
      local j = 0
      while j < Graph.UPDATE_STEPS - 1 do
        self.newPositions[j][i][k] = u16(shiftRightAdjusted(coord, 8))
        coord = coord + inc
        j = j + 1
      end
      self.newPositions[j][i][k] = new[i][k]
    end
  end
  self.updateCounter = 0
end

-- pokeemerald/src/menu_specialized.c:460
function Graph:update()
  for i = 0, Graph.COUNT - 1 do
    local p = self.newPositions[self.updateCounter][i]
    self.curPositions[i] = pos(p.x, p.y)
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

local function row(lines, y)
  local r = y - Graph.TOP_Y
  local t = lines[r]
  if not t then
    t = { [0] = 0, [1] = 0 }
    lines[r] = t
  end
  return t
end

-- pokeemerald/src/menu_specialized.c:469
function Graph:calcLine(scanline, pos1, pos2, dir, overflow)
  local d = dir and 1 or 0
  local top, bottom, x, x2, height
  local inc = 0
  if pos1.y < pos2.y then
    top, bottom = pos1.y, pos2.y
    x = pos1.x * 1024
    x2 = pos2.x
    height = bottom - top
    if height ~= 0 then inc = cdiv((x2 - pos1.x) * 1024, height) end
  else
    bottom, top = pos1.y, pos2.y
    x = pos2.x * 1024
    x2 = pos1.x
    height = bottom - top
    if height ~= 0 then inc = cdiv((x2 - pos2.x) * 1024, height) end
  end
  height = height + 1
  local lastLines, lastY
  if overflow == nil then
    local y = top
    for _ = 0, height - 1 do
      row(scanline, y)[d] = u16(shiftRightAdjusted(x, 10) + d)
      x = x + inc
      y = y + 1
    end
    lastLines, lastY = scanline, y - 1
  elseif inc > 0 then
    local y = top
    local i = 0
    while i < height do
      if x >= Graph.CENTER_X * 1024 then break end
      row(overflow, y)[d] = u16(shiftRightAdjusted(x, 10) + d)
      x = x + inc
      y = y + 1
      i = i + 1
    end
    self.bottom = top + i
    y = self.bottom
    while i < height do
      row(scanline, y)[d] = u16(shiftRightAdjusted(x, 10) + d)
      x = x + inc
      y = y + 1
      i = i + 1
    end
    lastLines, lastY = scanline, y - 1
  elseif inc < 0 then
    local y = top
    local i = 0
    while i < height do
      local r = row(scanline, y)
      r[d] = u16(shiftRightAdjusted(x, 10) + d)
      if x < Graph.CENTER_X * 1024 then
        r[d] = Graph.CENTER_X
        break
      end
      x = x + inc
      y = y + 1
      i = i + 1
    end
    self.bottom = top + i
    y = self.bottom
    while i < height do
      row(overflow, y)[d] = u16(shiftRightAdjusted(x, 10) + d)
      x = x + inc
      y = y + 1
      i = i + 1
    end
    lastLines, lastY = overflow, y - 1
  else
    self.bottom = top
    row(scanline, top)[1] = pos1.x + 1
    local o = row(overflow, top)
    o[0] = pos2.x
    o[1] = Graph.CENTER_X
    return
  end
  row(lastLines, lastY)[d] = d + x2
end

-- pokeemerald/src/menu_specialized.c:570
function Graph:calcRightHalf()
  local G = Graph.GRAPH
  local c = self.curPositions
  local y
  if c[G.COOL].y < c[G.BEAUTY].y then
    y = c[G.COOL].y
    self:calcLine(self.scanlineRight, c[G.COOL], c[G.BEAUTY], true, nil)
  else
    y = c[G.BEAUTY].y
    self:calcLine(self.scanlineRight, c[G.BEAUTY], c[G.COOL], false, nil)
  end
  self:calcLine(self.scanlineRight, c[G.BEAUTY], c[G.CUTE], true, nil)
  self:calcLine(self.scanlineRight, c[G.CUTE], c[G.SMART], c[G.CUTE].y <= c[G.SMART].y, self.scanlineLeft)
  for i = Graph.TOP_Y, y - 1 do
    local r = row(self.scanlineRight, i)
    r[0], r[1] = 0, 0
  end
  for i = c[G.COOL].y, self.bottom do row(self.scanlineRight, i)[0] = Graph.CENTER_X end
  local bottom = math.max(self.bottom, c[G.CUTE].y)
  for i = bottom + 1, Graph.BOTTOM_Y do
    local r = row(self.scanlineRight, i)
    r[0], r[1] = 0, 0
  end
  for i = Graph.TOP_Y, Graph.BOTTOM_Y do
    local r = row(self.scanlineRight, i)
    if r[0] == 0 and r[1] ~= 0 then r[0] = Graph.CENTER_X end
  end
end

-- pokeemerald/src/menu_specialized.c:620
function Graph:calcLeftHalf()
  local G = Graph.GRAPH
  local c = self.curPositions
  local y
  if c[G.COOL].y < c[G.TOUGH].y then
    y = c[G.COOL].y
    self:calcLine(self.scanlineLeft, c[G.COOL], c[G.TOUGH], false, nil)
  else
    y = c[G.TOUGH].y
    self:calcLine(self.scanlineLeft, c[G.TOUGH], c[G.COOL], true, nil)
  end
  self:calcLine(self.scanlineLeft, c[G.TOUGH], c[G.SMART], false, nil)
  for i = Graph.TOP_Y, y - 1 do
    local r = row(self.scanlineLeft, i)
    r[0], r[1] = 0, 0
  end
  for i = c[G.COOL].y, self.bottom do row(self.scanlineLeft, i)[1] = Graph.CENTER_X end
  local bottom = math.max(self.bottom, c[G.SMART].y + 1)
  for i = bottom, Graph.BOTTOM_Y do
    local r = row(self.scanlineLeft, i)
    r[0], r[1] = 0, 0
  end
  for i = 0, Graph.HEIGHT - 1 do
    local r = self.scanlineLeft[i]
    if r[0] >= r[1] then r[0], r[1] = 0, 0 end
  end
end

-- pokeemerald/src/menu_specialized.c:418
function Graph:calcSpans()
  if not self.needsDraw then return self.spans end
  self:calcRightHalf()
  self:calcLeftHalf()
  local spans = {}
  for i = 0, Graph.HEIGHT - 1 do
    local r, l = self.scanlineRight[i], self.scanlineLeft[i]
    spans[i] = { r[0], r[1], l[0], l[1] }
  end
  self.spans = spans
  self.needsDraw = false
  return spans
end

-- pokeemerald/src/menu_specialized.c:441
function Graph:draw(img, eva, evb)
  local spans = self:calcSpans()
  if not (spans and img) then return end
  eva, evb = eva or 11, evb or 4
  local W, H = img:getDimensions()
  self.quads = self.quads or {}
  local function span(x1, x2, y)
    if x2 <= x1 then return end
    local key = x1 * 65536 + x2 * 256 + y
    local q = self.quads[key]
    if not q then
      q = love.graphics.newQuad(x1, y, x2 - x1, 1, W, H)
      self.quads[key] = q
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(0, 0, 0, 1 - evb / 16)
    love.graphics.rectangle("fill", x1, y, x2 - x1, 1)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, eva / 16)
    love.graphics.draw(img, q, x1, y)
  end
  for i = 0, Graph.HEIGHT - 1 do
    local s = spans[i]
    local y = Graph.TOP_Y + i
    local rx1, rx2, lx1, lx2 = s[1], s[2], s[3], s[4]
    if lx1 < lx2 and rx1 < rx2 and lx2 >= rx1 then
      span(math.min(lx1, rx1), math.max(lx2, rx2), y)
    else
      span(rx1, rx2, y)
      span(lx1, lx2, y)
    end
  end
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
end

-- pokeemerald/src/menu_specialized.c:1083
function Graph.moveMonOnscreen(x)
  x = x + 24
  if x > 0 then x = 0 end
  return x, x ~= 0
end

-- pokeemerald/src/menu_specialized.c:1092
function Graph.moveMonOffscreen(x)
  x = x - 24
  if x < -80 then x = -80 end
  return x, x ~= -80
end

local Sparkles = {}
Sparkles.__index = Sparkles
Graph.Sparkles = Sparkles

-- pokeemerald/src/menu_specialized.c:1283
Sparkles.FRAMES = 7
Sparkles.FRAME_TIME = 5

-- pokeemerald/src/menu_specialized.c:1394
function Sparkles.new(count, coords)
  local s = setmetatable({ count = count, coords = coords, list = {} }, Sparkles)
  for i = 0, count do
    s.list[i] = { id = i, visible = false, delay = i * 16 + 1, anim = 0, state = "sparkle", timer = 0 }
  end
  -- pokeemerald/src/menu_specialized.c:1347
  if count == 9 then
    for i = 0, count do
      s.list[i].state = "wait_all"
      s.list[i].delay = 0
      s.list[i].anim = 0
      s.list[i].visible = true
    end
  end
  return s
end

local function animEnded(sp)
  return sp.anim >= Sparkles.FRAMES * Sparkles.FRAME_TIME
end

function Sparkles:showAll()
  for i = 0, self.count do
    self.list[i].anim = 0
    self.list[i].visible = true
  end
end

function Sparkles:chain()
  for i = 0, self.count do
    local sp = self.list[i]
    sp.delay = sp.id * 16 + 1
    sp.state = "sparkle"
  end
end

-- pokeemerald/src/menu_specialized.c:1447
function Sparkles:update()
  for i = 0, self.count do
    local sp = self.list[i]
    if sp.visible then sp.anim = sp.anim + 1 end
  end
  for i = 0, self.count do
    local sp = self.list[i]
    if sp.state == "sparkle" then
      local proceed = true
      if sp.delay ~= 0 then
        sp.delay = sp.delay - 1
        if sp.delay ~= 0 then
          proceed = false
        else
          sp.anim = 0
          sp.visible = true
        end
      end
      if proceed and sp.visible and animEnded(sp) then
        sp.visible = false
        if sp.id == self.count then
          if sp.id == 9 then
            self:showAll()
            sp.state = "wait_all"
          else
            sp.state = "next_after_delay"
            sp.timer = 0
          end
        else
          sp.state = "dummy"
        end
      end
    elseif sp.state == "wait_all" then
      if animEnded(sp) then
        sp.visible = false
        sp.timer = 0
        sp.state = "next_after_delay"
      end
    elseif sp.state == "next_after_delay" then
      sp.timer = sp.timer + 1
      if sp.timer > 60 then
        sp.timer = 0
        self:chain()
      end
    end
  end
end

function Sparkles:draw(image, frameImages, cx, cy)
  for i = 0, self.count do
    local sp = self.list[i]
    if sp.visible and not animEnded(sp) then
      local f = math.floor(sp.anim / Sparkles.FRAME_TIME)
      local c = self.coords[sp.id + 1] or { 0, 0 }
      local img = frameImages[f]
      if img then love.graphics.draw(img, cx + c[1] - 8, cy + c[2] - 8) end
    end
  end
end

return Graph
