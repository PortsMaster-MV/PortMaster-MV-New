local M = {}

function M.enabled(session)
  local id = require("src.core.game3.profile").forSession(session).id
  return id == "firered" or id == "leafgreen"
end

local function release()
  if M._canvas then M._canvas:release(); M._canvas = nil end
end

function M.reset()
  M._task = nil
  release()
end

function M.busy() return M._task ~= nil end

local function battler(st, id)
  if id == 0 then return st.player end
  return st.battlers and st.battlers[id]
end

local function current(t)
  local b = battler(t.st, t.id)
  return b == t.battler and b.mon == t.controllerMon
    and not (t.st.absent and t.st.absent[t.id])
    and t.snapshot(t.st, t.id) ~= nil
end

-- pokefirered/src/battle_controller_player.c:1170
function M.begin(opts)
  M.reset()
  local st = opts and opts.st
  if not st or opts.headless or not M.enabled(st.session) then return false end
  local id = opts.controllerId or 0
  local b = battler(st, id)
  local pos = opts.snapshot and opts.snapshot(st, id)
  if not b or not pos then return false end
  M._task = { st = st, id = id, battler = b, controllerMon = b.mon,
    mon = opts.mon, partyIndex = opts.partyIndex, snapshot = opts.snapshot,
    state = -1, sprites = {}, made = 0, timer = 0 }
  return true
end

local function art()
  local Anim = require("src.core.game3.battle.anim")
  Anim.tableScript("special", "LVL_UP")
  local p = Anim._pack
  local spec = p and p.levelUpVertical
  local tag = spec and p.tags and p.tags[spec.tag]
  if spec and spec.version == 1 and tag and tag.image then return tag.image end
  if not M._warned then
    M._warned = true
    print("[game3/level_up_streaks] native FRLG streak art missing; reimport battle animations")
  end
end

-- pokefirered/src/battle_script_commands.c:5935
local function recipient_sent_out(t)
  for _, id in ipairs(t.st.double and {0, 2} or {0}) do
    local b = battler(t.st, id)
    if b and b.partyIndex == t.partyIndex and b.mon == t.mon then return true end
  end
  return false
end

-- pokefirered/src/pokemon_special_anim_scene.c:1410
local function sprites_tick(t)
  if t.made < 18 then
    if t.timer == 0 then
      t.timer = 1
      t.made = t.made + 1
      local n = t.made
      t.sprites[#t.sprites + 1] = { n = n, x = ((n * 219) % 64) + t.x - 32,
        y = t.y + 32, subpixel = 0, speed = ((1103515245 * n + 24691) % 64) + 32 }
    else
      t.timer = (t.timer + 1) % 2
    end
  elseif #t.sprites == 0 then
    t.spriteDone = true
  end
end

-- pokefirered/src/battle_main.c:1447
local function animate_tick(t)
  -- pokefirered/src/pokemon_special_anim_scene.c:1458
  for i = #t.sprites, 1, -1 do
    local s = t.sprites[i]
    s.visible = true
    s.subpixel = s.subpixel - s.speed
    s.y2 = math.floor(s.subpixel / 16)
    if s.y2 < -64 then table.remove(t.sprites, i) end
  end
end

-- pokefirered/src/battle_controller_player.c:1188
function M.update()
  local t = M._task
  if not t then return true end
  if not current(t) then M.reset(); return true end
  if t.image and not t.spriteDone then animate_tick(t) end
  if t.state == -1 then
    t.state = 0
  elseif t.state == 0 then
    local Ui = package.loaded["src.core.game3.battle.ui"]
    if not (Ui and Ui.dialogPending and Ui.dialogPending()) then t.state = 1 end
  elseif t.state == 1 then
    t.state = 2
  elseif t.state == 2 then
    require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_RS_SHOP)
    if recipient_sent_out(t) then
      local pos = t.snapshot(t.st, t.id)
      t.x, t.y = pos.x, pos.y
      t.image = art()
      t.spriteDone = t.image == nil
    else t.spriteDone = true end
    t.state = 3
  elseif t.state == 3 then
    if t.image and not t.spriteDone then sprites_tick(t) end
    if t.spriteDone then t.state = 4 end
  elseif t.state == 4 then t.state = 5
  elseif t.state == 5 then t.state = 6
  elseif t.state == 6 then t.state = 7
  elseif t.state == 7 then
    local Ui = package.loaded["src.core.game3.battle.ui"]
    if not (Ui and Ui.dialogPending and Ui.dialogPending()) then M.reset(); return true end
  end
  return false
end

-- pokefirered/src/pokemon_special_anim_scene.c:226
function M.draw(st)
  local t = M._task
  if not t or t.st ~= st or not t.image or #t.sprites == 0 then return end
  if not current(t) then M.reset(); return end
  local g = love.graphics
  if not M._canvas then
    M._canvas = g.newCanvas(240, 160)
    M._canvas:setFilter("nearest", "nearest")
  end
  local order = {}
  for _, s in ipairs(t.sprites) do
    if s.visible then order[#order + 1] = s end
  end
  if #order == 0 then return end
  -- pokefirered/src/sprite.c:368
  table.sort(order, function(a, b)
    local ay, by = a.y + a.y2 - 8, b.y + b.y2 - 8
    if ay == by then return a.n > b.n end
    return ay < by
  end)
  local canvas = g.getCanvas()
  g.push("all")
  g.setCanvas(M._canvas)
  g.origin(); g.setScissor(); g.setShader(); g.clear(0, 0, 0, 0)
  g.setBlendMode("alpha", "alphamultiply"); g.setColor(1, 1, 1, 1)
  for _, s in ipairs(order) do g.draw(t.image, s.x, s.y + s.y2, 0, 1, 1, 4, 8) end
  g.setCanvas(canvas)
  g.pop()
  g.push("all")
  g.setShader(); g.setBlendMode("alpha", "alphamultiply")
  g.setColor(0, 0, 0, 10 / 16); g.draw(M._canvas, 0, 0)
  g.setBlendMode("add", "alphamultiply")
  g.setColor(1, 1, 1, 12 / 16); g.draw(M._canvas, 0, 0)
  g.pop()
end

return M
