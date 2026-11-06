-- Immutable metatile/void resolution; no graphics or mutable field state.
local Prepare = {}
local function sample(layout, x, y)
  local dx, dy = x - layout.x0, y - layout.y0
  if dx < 0 or dy < 0 or dx >= layout.w or dy >= layout.h then return nil end
  local p = layout.packed
  if p then
    local ov = p.overrides[y * 1024 + x]
    if ov then return ov.mid end
    if x >= 0 and y >= 0 and x < p.trueWidth and y < p.trueHeight then
      local i = p.off + (y * p.width + x) * 4
      local a, b = p.blob:byte(i, i + 1)
      return a + b * 256
    end
    return p.borderMids[(y % p.borderHeight) * p.borderWidth + x % p.borderWidth + 1] or 0
  end
  local i = (dy * layout.w + dx) * 2 + 1
  local a, b = layout.blob:byte(i, i + 1)
  return a + b * 256
end
local function inside(l, x, y)
  return x >= 0 and y >= 0 and x < l.width and y < l.height
end
local function resolve(s, x, y)
  local root = s.layouts[1]
  if inside(root, x, y) then return sample(root, x, y), root.pair, false end
  local function dir(direction)
    for i = #s.neighbors, 1, -1 do
      local n = s.neighbors[i]
      if n.dir == direction then
        local l = s.layouts[n.layout]
        local nx, ny
        if direction == "north" then nx, ny = x - n.offset, l.height + y
        elseif direction == "south" then nx, ny = x - n.offset, y - root.height
        elseif direction == "west" then nx, ny = l.width + x, y - n.offset
        else nx, ny = x - root.width, y - n.offset end
        if inside(l, nx, ny) then return sample(l, nx, ny), l.pair or root.pair end
      end
    end
  end
  local mid, pair
  if y < 0 then mid, pair = dir("north") elseif y >= root.height then mid, pair = dir("south") end
  if mid ~= nil then return mid, pair, false end
  if x < 0 then mid, pair = dir("west") elseif x >= root.width then mid, pair = dir("east") end
  if mid ~= nil then return mid, pair, false end
  for _, entry in ipairs(s.world) do
    if entry.layout ~= 1 then
      local l = s.layouts[entry.layout]
      local nx, ny = x - entry.ox, y - entry.oy
      if inside(l, nx, ny) then return sample(l, nx, ny), l.pair or root.pair, false end
    end
  end
  return sample(root, x, y), root.pair, true
end
function Prepare.cells(s, cancelled)
  local pairs, ids, rows = {}, {}, {}
  for y = s.y0, s.y0 + s.rows - 1 do
    if cancelled and cancelled() then error("field cell preparation cancelled") end
    local row = {}
    for x = s.x0, s.x0 + s.cols - 1 do
      local mid, pair, void = resolve(s, x, y)
      assert(mid ~= nil, "incomplete field snapshot")
      local skip = void and s.mode == "black"
      if void and s.fill then
        local f = s.fill
        mid = f.mids[(y % f.h) * f.w + x % f.w + 1]
        pair = s.layouts[1].pair
      end
      if not ids[pair] then pairs[#pairs + 1] = pair; ids[pair] = #pairs end
      local id = ids[pair]
      row[#row + 1] = string.char(mid % 256, math.floor(mid / 256), id % 256, math.floor(id / 256),
        (void and 1 or 0) + (skip and 2 or 0))
    end
    rows[#rows + 1] = table.concat(row)
  end
  return { blob = table.concat(rows), pairs = pairs, x0 = s.x0, y0 = s.y0, cols = s.cols, rows = s.rows }
end
function Prepare.cell(plan, x, y)
  local dx, dy = x - plan.x0, y - plan.y0
  if dx < 0 or dy < 0 or dx >= plan.cols or dy >= plan.rows then return nil end
  local i = (dy * plan.cols + dx) * 5 + 1
  local lo, hi, p0, p1, flags = plan.blob:byte(i, i + 4)
  return lo + hi * 256, plan.pairs[p0 + p1 * 256], flags % 2 == 1, flags >= 2
end
return Prepare
