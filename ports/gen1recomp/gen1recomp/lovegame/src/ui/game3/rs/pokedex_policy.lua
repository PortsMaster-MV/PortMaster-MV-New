local M = {SCREEN = {PAGE = 0, AREA = 1, CRY = 2, SIZE = 3}}
-- pokeruby/src/pokedex.c:2588
function M.interfaceSprites(s, page)
  local out = {}
  local function add(row) out[#out + 1] = row end
  add({kind = "arrow", tile = 1, w = 16, h = 8, x = 184, y = 4, prio = 0, down = false, data2 = 0})
  add({kind = "arrow", tile = 1, w = 16, h = 8, x = 184, y = 156, prio = 0, down = true, vflip = true, data2 = 0})
  add({kind = "scrollbar", tile = 3, w = 8, h = 8, x = 234, y = 20, prio = 1})
  for _, r in ipairs({{32, 16, 138}, {128, 48, 138}, {96, 16, 158}, {64, 48, 158}}) do
    add({kind = "text", tile = r[1], w = 64, h = 32, x = r[2], y = r[3], prio = 0})
  end
  for _, n in ipairs({0, 128}) do add({kind = "ball", tile = 16, w = 32, h = 32, x = 0, y = 80, prio = 1, data1 = n, objwin = true}) end
  if page == 0 then
    for _, r in ipairs({{160, 40, s.seenCount}, {192, 72, s.ownCount}}) do
      add({kind = "seen", tile = r[1], w = 64, h = 32, x = 32, y = r[2], prio = 0})
      local count, leading = r[3], true
      for i, divisor in ipairs({100, 10, 1}) do
        local digit = math.floor(count / divisor) % 10
        if digit ~= 0 then leading = false end
        add({kind = "seen", tile = 224 + digit * 2, w = 8, h = 16, x = 28 + (i - 1) * 6, y = r[2] + 8,
          prio = 0, invisible = i < 3 and leading})
      end
    end
  end
  add({kind = "cursor", tile = 4, w = 8, h = 16, x = 140, y = page == 0 and 96 or 80, prio = 0, invisible = true, data2 = 0})
  return out
end
function M.weightText(weight)
  local lbs = math.floor(weight * 100000 / 4536)
  if lbs % 10 >= 5 then lbs = lbs + 10 end
  local out, output = {}, false
  for _, divisor in ipairs({100000, 10000, 1000}) do
    local d = math.floor(lbs / divisor)
    lbs = lbs % divisor
    if d == 0 and not output then out[#out + 1] = "  "
    else output = true; out[#out + 1] = tostring(d) end
  end
  out[#out + 1] = tostring(math.floor(lbs / 100)) .. "." .. tostring(math.floor(lbs % 100 / 10)) .. " lbs."
  return table.concat(out)
end
function M.lr(session, input)
  local opts = session and session.options or {}
  return tonumber(opts.buttonMode or opts.optionsButtonMode or session and session.optionsButtonMode) == 1
    and (input.l or input.r)
end
function M.areaRegion(man, session)
  local Data = require("src.ui.game3.rs.pokenav.data")
  local pos = Data.playerPosition(man, session)
  return pos and {x = pos.x * 8 + 4, y = pos.y * 8 + 4 - 8, blink = pos.cave} or nil
end
return M
