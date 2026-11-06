local Pokemon = require("src.core.game3.pokemon")
local M = {}
M.SEARCH_KEYS = {"cool", "beauty", "cute", "smart", "tough"}
M.GRAPH_KEYS = {"cool", "tough", "smart", "cute", "beauty"}
local function valid(mon)
  return type(mon) == "table" and (tonumber(Pokemon.speciesOf(mon)) or 0) ~= 0 and not Pokemon.isEgg(mon)
end
function M.stat(mon, key) return math.floor(tonumber((mon and mon.contest or {})[key]) or 0) % 256 end
function M.conditions(mon)
  local out = {}; for i, key in ipairs(M.GRAPH_KEYS) do out[i] = M.stat(mon, key) end; return out
end
function M.mon(session, row)
  if not row or row.cancel then return nil end
  if row.box == 14 then return (session.party or {})[row.slot + 1] end
  local box = ((session.storage or {}).boxes or {})[row.box + 1]
  return box and (box.mons or {})[row.slot + 1]
end
function M.party(session)
  local out = {}
  for slot, mon in ipairs(session.party or {}) do
    if valid(mon) then out[#out + 1] = {box = 14, slot = slot - 1, rank = #out + 1} end
  end
  out[#out + 1] = {cancel = true, box = 0, slot = 0, rank = 0}
  return out
end
function M.insert(rows, row)
  local lo, hi = 0, #rows
  local mid = lo + math.floor((hi - lo) / 2)
  while hi ~= mid do
    if row.value > rows[mid + 1].value then hi = mid else lo = mid + 1 end
    mid = lo + math.floor((hi - lo) / 2)
  end
  table.insert(rows, mid + 1, row)
end
function M.search(session, id, ribbons)
  local out, key = {}, assert(M.SEARCH_KEYS[id + 1], "native condition category")
  local function add(box, slot, mon)
    if valid(mon) then
      local value = ribbons and require("src.core.game3.profiles.rs.pokenav").ribbonCount(mon) or M.stat(mon, key)
      if not ribbons or value ~= 0 then M.insert(out, {box = box, slot = slot, value = value}) end
    end
  end
  local boxes = ((session or {}).storage or {}).boxes or {}
  for box = 0, 13 do for slot = 0, 29 do add(box, slot, boxes[box + 1] and (boxes[box + 1].mons or {})[slot + 1]) end end
  if ribbons then
    for slot = 0, 5 do add(14, slot, (session.party or {})[slot + 1]) end
  else
    for slot, mon in ipairs(session.party or {}) do
      if (tonumber(Pokemon.speciesOf(mon)) or 0) == 0 then break end
      add(14, slot - 1, mon)
    end
  end
  for i, row in ipairs(out) do row.rank = i > 1 and row.value == out[i - 1].value and out[i - 1].rank or i end
  return out
end
function M.level(mon, boxed)
  if boxed and mon.exp ~= nil then
    local Summary = require("src.core.game3.summary_data")
    local growth, level = Pokemon.growthRate(Pokemon.speciesOf(mon)), 1
    while level <= 100 and Summary.expForLevel(growth, level) <= (tonumber(mon.exp) or 0) do level = level + 1 end
    return math.max(1, level - 1)
  end
  return tonumber(mon.level) or 1
end
function M.gender(mon)
  local sp, name = Pokemon.speciesOf(mon), Pokemon.displayName(mon)
  if (sp == 29 or sp == 32) and name == Pokemon.name(sp) then return "U" end
  return Pokemon.gender(sp, mon.personality)
end
function M.location(session, row, man)
  if row.box == 14 then return man.strings.InParty end
  local box = ((session.storage or {}).boxes or {})[row.box + 1]
  return box and box.name or ""
end
function M.drawName(mon, row, x, y, pal, width, withValue, backgroundIndex)
  local G = require("src.ui.game3.rs.pokenav.gfx")
  local background = backgroundIndex == nil and 191 or backgroundIndex
  local normal = G.colors(pal, background, 177, 181)
  G.text(Pokemon.displayName(mon), x, y, normal, "native_3", 63)
  local gender = M.gender(mon)
  if gender == "M" then G.text("♂", x + 63, y, G.colors(pal, background, 188, 189))
  elseif gender == "F" then G.text("♀", x + 63, y, G.colors(pal, background, 186, 187)) end
  G.text("/", x + 70, y, normal)
  local levelX = x + 70 + G.measure("/") + 1 -- native EXT_CTRL_CODE_CLEAR1
  G.text("{LV}" .. M.level(mon, row.box ~= 14), levelX, y, normal, "native_3", width - (levelX - x))
  if withValue then
    local text = tostring(row.value); G.text(text, x + 128 - G.measure(text), y, normal)
  end
end
return M
