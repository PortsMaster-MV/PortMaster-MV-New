local Shared = require("src.ui.game3.rs.mail_composer_frames")
local F = {}
function F.initial(man)
  local map = {}; for i = 1, 640 do map[i] = man.maps.base[i] or 0 end
  local r = man.frame
  Shared.copy(map, r.x, r.y, man.maps.shapes, r.sourceX, r.sourceY, r.w, r.h)
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
local function load(t, name)
  local spec = assert(PHASES[name])
  t.rows, t.remaining, t.phase = {}, spec[1], name
  for _, row in ipairs(spec[2]) do
    local r = {}; for i, v in ipairs(row) do r[i] = v end
    t.rows[#t.rows + 1] = r
  end
end
local function work(t, map, man)
  if t.remaining == 0 then return true end
  for _, r in ipairs(t.rows) do
    r[1], r[2], r[3], r[4] = r[1] + r[5], r[2] + r[6], r[3] + r[7], r[4] + r[8]
    r[9], r[10] = r[9] + r[11], r[10] + r[12]
    Shared.copy(map, r[1], r[2], r[13] == "base" and man.maps.base or man.maps.picker,
      r[9], r[10], r[3] - r[1], r[4] - r[2])
  end
  t.remaining = t.remaining - 1
  return false
end
local function controller(t, kind, map, man, events)
  local s = t.inner
  if kind == "groups" then -- sub_80E9EA8
    if s == 0 then load(t, "openSides"); t.inner = 1; s = 1 end
    if s == 1 and work(t, map, man) then load(t, "openRows"); t.inner = 2
    elseif s == 2 and work(t, map, man) then load(t, "openSidebar"); t.inner = 3
    elseif s == 3 and work(t, map, man) then t.inner = 4
    elseif s == 4 then t.inner = 5
    elseif s == 5 then return true end
  elseif kind == "phrase" then -- sub_80E9F50
    if s == 0 or s == 2 or s == 4 then
      load(t, ({[0] = "closeSidebar", [2] = "closeRows", [4] = "closeSides"})[s])
      t.inner, s = s + 1, s + 1
    end
    if (s == 1 or s == 3 or s == 5) and work(t, map, man) then t.inner = s + 1
    elseif s == 6 then return true end
  elseif kind == "closeRows" or kind == "openRows" then -- sub_80E9FD4/sub_80EA014
    if s == 0 then load(t, kind); t.inner = 1 end
    if work(t, map, man) then return true end
  elseif kind == "words" then -- sub_80EA050
    if s == 0 then load(t, "closeSidebar"); t.inner = 1
    elseif s == 1 and work(t, map, man) then load(t, "openWords"); t.inner = 2
    elseif s == 2 then
      events.paletteDelta = 1
      if work(t, map, man) then load(t, "finishWords"); t.inner = 3 end
    elseif s == 3 then
      events.paletteDelta = 1
      if work(t, map, man) then t.inner = 4 end
    elseif s == 4 then return true end
  elseif kind == "back" then -- sub_80EA0E4
    if s == 0 then load(t, "closeWords"); t.inner, s = 1, 1 end
    if s == 1 then
      events.paletteDelta = -1
      if work(t, map, man) then load(t, "restoreWords"); t.inner = 2 end
    elseif s == 2 then
      events.paletteDelta = -1
      if work(t, map, man) then load(t, "openSidebar"); t.inner = 3 end
    elseif s == 3 and work(t, map, man) then t.inner = 4
    elseif s == 4 then return true end
  elseif kind == "chosen" then -- sub_80EA184
    if s == 0 then load(t, "finishPhrase"); t.inner, s = 1, 1 end
    if s == 1 and work(t, map, man) then t.inner = 2
    elseif s == 2 then events.paletteReset = true; return true end
  end
  return false
end

function F.begin(route, alpha)
  assert(({groups = true, phrase = true, toggle = true, words = true, back = true, chosen = true})[route])
  return {route = route, state = 0, inner = 0, alpha = alpha == true, cursorsVisible = route == "words"}
end
function F.step(t, map, man)
  local s, e, done = t.state, {}, false
  local groupAnimation = t.alpha and 3 or 4
  if t.route == "groups" then -- easy_chat_1.c:sub_80E6F68
    if s == 0 then t.state = 1
    elseif controller(t, "groups", map, man, e) then e.indicator = groupAnimation; done = true end
  elseif t.route == "phrase" then -- sub_80E7114
    if s == 0 then e.indicator = 5; t.state = 1
    elseif s == 1 or s == 2 then t.state = s + 1
    elseif s == 3 and controller(t, "phrase", map, man, e) then t.state = 4
    elseif s == 4 then done = true end
  elseif t.route == "toggle" then -- sub_80E718C
    if s == 0 then e.indicator = t.alpha and 2 or 1; t.state = 1
    elseif s == 1 and controller(t, "closeRows", map, man, e) then
      e.toggle = true; t.inner, t.state = 0, 2
    elseif s >= 2 and s <= 7 then t.state = s + 1
    elseif s == 8 and controller(t, "openRows", map, man, e) then done = true end
  elseif t.route == "words" then -- sub_80E7218
    if s < 8 then t.state = s + 1
    elseif s == 8 then e.indicator, e.view = 5, "none"; t.cursorsVisible, t.state = false, 9
    elseif s == 9 and controller(t, "words", map, man, e) then e.view = "words"; t.state = 10
    elseif s == 10 then done = true end
  elseif t.route == "back" then -- sub_80E73D0
    if s < 2 then t.state = s + 1
    elseif s == 2 and controller(t, "back", map, man, e) then e.indicator = groupAnimation; t.state = 3
    elseif s == 3 then t.state = 4
    elseif s == 4 then e.view = "groups"; done = true end
  elseif t.route == "chosen" then -- sub_80E7324 after successful sub_80E7DD0
    if s < 3 then t.state = s + 1
    elseif s == 3 and controller(t, "chosen", map, man, e) then t.state = 4
    elseif s == 4 then done = true end
  end
  return done, e
end
return F
