local F = {}

function F.copy(map, x, y, source, sx, sy, w, h)
  for row = 0, h - 1 do for col = 0, w - 1 do
    local dx, dy = x + col, y + row
    if dx >= 0 and dx < 32 and dy >= 0 and dy < 20 then
      map[dy * 32 + dx + 1] = assert(source[(sy + row) * 32 + sx + col + 1], "native Easy Chat source map extent")
    end
  end end
end
function F.initial(man)
  local map = {}; for i = 1, 640 do map[i] = man.maps.base[i] or 0 end
  F.copy(map, 2, 0, man.maps.shapes, 0, 0, 26, 10)
  return map
end

local PHASES = {
  openSides = {6, {
    {13,14,13,15,-2,0,0,0, 0,0,0,0}, {12,14,12,15,0,0,2,0, 30,0,-2,0},
    {13,15,13,16,-2,0,0,0, 0,9,0,0}, {12,15,12,16,0,0,2,0, 30,9,-2,0}}},
  openRows = {4, {
    {1,14,13,15,0,-1,0,0, 0,0,0,0}, {12,14,24,15,0,-1,0,0, 18,0,0,0},
    {1,15,13,16,0,0,0,1, 0,9,0,-1}, {12,15,24,16,0,0,0,1, 18,9,0,-1}}},
  openSidebar = {5, {{24,12,25,20,0,0,1,0, 5,10,-1,0}}},
  closeSidebar = {6, {
    {24,12,30,20,0,0,-1,0, 0,10,1,0}, {30,12,31,20,-1,0,0,0, 30,12,-1,0,"base"}}},
  closeRows = {4, {
    {1,10,13,15,0,1,0,0, 0,0,0,0}, {12,10,24,15,0,1,0,0, 18,0,0,0},
    {1,15,13,20,0,0,0,-1, 0,5,0,1}, {12,15,24,20,0,0,0,-1, 18,5,0,1},
    {1,10,24,10,0,0,0,1, 1,10,0,0,"base"}, {1,20,24,20,0,-1,0,0, 1,20,0,-1,"base"}}},
  closeSides = {6, {
    {1,14,13,15,2,0,0,0, 0,0,0,0}, {12,14,24,15,0,0,-2,0, 18,0,2,0},
    {1,15,13,16,2,0,0,0, 0,9,0,0}, {12,15,24,16,0,0,-2,0, 18,9,2,0},
    {1,14,1,16,0,0,2,0, 1,14,0,0,"base"}, {24,14,24,16,-2,0,0,0, 24,14,-2,0,"base"}}},
  openWords = {2, {
    {20,10,25,20,0,0,1,0, 25,0,-1,0}, {0,10,1,20,0,0,1,0, 0,10,0,0,"base"},
    {1,10,4,20,1,0,0,0, 0,0,0,0}}},
  finishWords = {1, {{3,10,4,20,0,0,0,0, 0,0,0,0}, {0,10,2,20,0,0,0,0, 0,10,0,0,"base"}}},
  closeWords = {2, {
    {0,10,2,20,0,0,-1,0, 0,10,0,0,"base"}, {3,10,5,20,-1,0,0,0, 0,0,0,0},
    {26,10,30,20,-1,0,0,0, 26,10,-1,0,"base"}, {25,10,26,20,-1,0,-1,0, 29,0,0,0}}},
  restoreWords = {1, {{24,10,30,20,0,0,0,0, 24,10,0,0,"base"}, {23,10,24,20,0,0,-1,0, 29,0,0,0}}},
  finishPhrase = {5, {
    {0,10,30,15,0,1,0,0, 0,0,0,0}, {0,15,30,20,0,0,0,-1, 0,5,0,1},
    {0,10,30,10,0,0,0,1, 0,10,0,0,"base"}, {0,20,30,20,0,-1,0,0, 0,20,0,-1,"base"}}},
}
F.ROUTES = {groups = {"openSides", "openRows", "openSidebar"}, phrase = {"closeSidebar", "closeRows", "closeSides"},
  words = {"closeSidebar", "openWords", "finishWords"}, back = {"closeWords", "restoreWords", "openSidebar"},
  chosen = {"finishPhrase"}, toggle = {"closeRows", "openRows"}}

function F.begin(route)
  return {route = assert(F.ROUTES[route]), phase = 0, remaining = 0, rows = nil}
end
function F.step(task, map, man)
  if task.remaining == 0 then
    task.phase = task.phase + 1
    local name = task.route[task.phase]
    if not name then return true end
    local spec = PHASES[name]
    task.rows, task.remaining = {}, spec[1]
    for _, row in ipairs(spec[2]) do local copy = {}; for i, v in ipairs(row) do copy[i] = v end; task.rows[#task.rows + 1] = copy end
  end
  for _, r in ipairs(task.rows) do
    r[1], r[2], r[3], r[4] = r[1] + r[5], r[2] + r[6], r[3] + r[7], r[4] + r[8]
    r[9], r[10] = r[9] + r[11], r[10] + r[12]
    F.copy(map, r[1], r[2], r[13] == "base" and man.maps.base or man.maps.picker, r[9], r[10], r[3] - r[1], r[4] - r[2])
  end
  task.remaining = task.remaining - 1
  return false
end
return F
