local MonAnim = require("src.core.game3.mon_anim")

local MonAnimBattle = {}

MonAnimBattle._active = {}

function MonAnimBattle.enabled()
  return MonAnim.enabled()
end

local function Anim() return require("src.core.game3.battle.anim") end
local function State() return require("src.core.game3.battle.state") end

local function present(key)
  local A = Anim()
  local p = A.present(key)
  if not p and type(key) == "number" and key < 2 then p = A.present(State().sideOf(key)) end
  return p
end

local function battlerOf(st, key)
  if not st then
    local Battle = package.loaded["src.core.game3.battle"]
    st = Battle and Battle._st
  end
  if not st then return nil end
  if type(key) == "number" then return State().battler(st, key) end
  return st[key]
end

local function speciesOf(b)
  if not b then return nil end
  return tonumber(b.species or (b.mon and (b.mon.species or b.mon.speciesId)))
end

local function sceneOn()
  local okO, Options = pcall(require, "src.core.game3.options")
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  if okO and session and Options.battleScene then return Options.battleScene(session) ~= false end
  return true
end

function MonAnimBattle.apply(p, sprite)
  if not (p and sprite) then return end
  local t = MonAnim.transform(sprite)
  p.ox, p.oy = t.x2, t.y2
  p.sx, p.sy, p.rotation = t.sx, t.sy, t.rotation
  p.invisible = t.invisible or nil
  p.monFrame = t.frame
  if (sprite.blendCoeff or 0) > 0 then
    local r, g, b, k = MonAnim.blendRgb(sprite)
    p.blendCoeff, p.blendColor = k, { r, g, b }
  else
    p.blendCoeff, p.blendColor = nil, nil
  end
end

-- pokeemerald/src/battle_main.c:2702
function MonAnimBattle.start(key, kind, opts)
  opts = opts or {}
  local b = battlerOf(opts.st, key)
  local species = speciesOf(b)
  local p = present(key)
  if not (species and p and MonAnim.enabled()) then return nil end
  local id = type(key) == "number" and key or ((key == "player") and 0 or 1)
  local sprite = MonAnim.newSprite(species)
  sprite.data[0], sprite.data[2] = id, species
  local noAnims = not sceneOn()
  if kind == "back" then
    local nature = math.floor(tonumber(b.mon and b.mon.personality) or 0) % 25
    sprite.callback = function(s) MonAnim.battleBack(s, species, nature, { noAnimations = noAnims }) end
  else
    local noCry = opts.noCry and true or false
    sprite.callback = function(s)
      -- pokeemerald/src/battle_main.c:2843
      if noCry and not noAnims and MonAnim.hasTwoFramesAnimation(species) then MonAnim.startSpriteAnim(s, 1) end
      MonAnim.battleFront(s, species, noCry, 1, {
        noAnimations = noAnims,
        cry = function(sp, pan)
          pcall(function() require("src.core.game3.audio").playCry(sp, opts.cryMode or 0, pan) end)
        end,
      })
    end
  end
  local prev = MonAnimBattle._active[p]
  if prev then MonAnim.stop(prev) end
  MonAnimBattle._active[p] = sprite
  MonAnim.run(sprite, {
    onStep = function(s) if MonAnimBattle._active[p] == s then MonAnimBattle.apply(p, s) end end,
    onDone = function(s)
      if MonAnimBattle._active[p] == s then
        MonAnimBattle.apply(p, s)
        MonAnimBattle._active[p] = nil
      end
    end,
  })
  return sprite
end

function MonAnimBattle.busy(keys)
  for _, key in ipairs(keys or {}) do
    local p = present(key)
    local s = p and MonAnimBattle._active[p]
    if s and MonAnim.busy(s) then return true end
  end
  return false
end

function MonAnimBattle.reset()
  for p, s in pairs(MonAnimBattle._active) do MonAnim.stop(s) end
  MonAnimBattle._active = {}
end

local function keysOf(d, default)
  return d.ids or { d.id ~= nil and d.id or d.side or default }
end

function MonAnimBattle.introSteps(steps, wild)
  if not MonAnim.enabled() then return steps end
  local out = {}
  local function add(kind, data) out[#out + 1] = { kind = kind, data = data or {} } end
  for _, step in ipairs(steps) do
    local d = step.data or {}
    if wild and step.kind == "cry" and not d.release and (d.side or "enemy") == "enemy" then
      out.pendingWildFront = keysOf(d, "enemy")
    else
      out[#out + 1] = step
    end
    if step.kind == "undarken" and out.pendingWildFront then
      -- pokeemerald/src/battle_main.c:2698
      add("mon_anim", { kind = "front", ids = out.pendingWildFront })
      out.pendingWildFront = nil
    elseif step.kind == "opponent_sendout" then
      -- pokeemerald/src/battle_main.c:2837
      add("mon_anim", { kind = "front", ids = keysOf(d, "enemy"), noCry = true })
      out.waitFront = keysOf(d, "enemy")
    elseif step.kind == "player_throw" then
      -- pokeemerald/src/battle_main.c:2987
      add("mon_anim", { kind = "back", ids = keysOf(d, "player") })
      out.waitBack = keysOf(d, "player")
    elseif step.kind == "healthbox" then
      -- pokeemerald/src/battle_controller_opponent.c:353
      local side = d.side or "enemy"
      local wait = (side == "player") and out.waitBack or out.waitFront
      if wait then
        add("mon_anim_wait", { ids = wait })
        if side == "player" then out.waitBack = nil else out.waitFront = nil end
      end
    end
  end
  out.pendingWildFront, out.waitFront, out.waitBack = nil, nil, nil
  return out
end

local function stepKey(d, side)
  if d.id ~= nil then return d.id end
  return d.side or side
end

function MonAnimBattle.switchSteps(steps)
  if not (steps and MonAnim.enabled()) or steps.monAnim then return steps end
  local out = { monAnim = true }
  local wait = {}
  for _, step in ipairs(steps) do
    local d = step.data or {}
    if step.kind == "healthbox" then
      local key = stepKey(d, "enemy")
      if wait[key] then
        -- pokeemerald/src/battle_controller_opponent.c:482
        out[#out + 1] = { kind = "mon_anim_wait", data = { ids = { wait[key] } } }
        wait[key] = nil
      end
    end
    out[#out + 1] = step
    if step.kind == "sendout_enemy" then
      local key = stepKey(d, "enemy")
      -- pokeemerald/src/battle_main.c:2837
      out[#out + 1] = { kind = "mon_anim", data = { kind = "front", ids = { key }, noCry = true } }
      wait[key] = key
    elseif step.kind == "sendout_player" then
      local key = stepKey(d, "player")
      -- pokeemerald/src/battle_main.c:2987
      out[#out + 1] = { kind = "mon_anim", data = { kind = "back", ids = { key } } }
      wait[key] = key
    end
  end
  return out
end

return MonAnimBattle
