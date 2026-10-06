local RotatingGate = {}

local CELL = 16

-- pokeemerald/src/rotating_gate.c:160
local ARM_NORTH, ARM_EAST, ARM_SOUTH, ARM_WEST = 0, 1, 2, 3
local ROTATE_NONE, ROTATE_ANTICLOCKWISE, ROTATE_CLOCKWISE = 0, 1, 2
RotatingGate.ROTATE_ANTICLOCKWISE, RotatingGate.ROTATE_CLOCKWISE = ROTATE_ANTICLOCKWISE, ROTATE_CLOCKWISE

local function rot(dir, arm, long) return { dir = dir, arm = arm, long = long } end
local function cw(arm, long) return rot(ROTATE_CLOCKWISE, arm, long) end
local function acw(arm, long) return rot(ROTATE_ANTICLOCKWISE, arm, long) end
local N = false

-- pokeemerald/src/rotating_gate.c:494
RotatingGate.ROTATION_INFO = {
  up = {
    N, N, N, N,
    cw(ARM_WEST, 1), cw(ARM_WEST, 0), acw(ARM_EAST, 0), acw(ARM_EAST, 1),
    N, N, N, N,
    N, N, N, N,
  },
  down = {
    N, N, N, N,
    N, N, N, N,
    acw(ARM_WEST, 1), acw(ARM_WEST, 0), cw(ARM_EAST, 0), cw(ARM_EAST, 1),
    N, N, N, N,
  },
  left = {
    N, acw(ARM_NORTH, 1), N, N,
    N, acw(ARM_NORTH, 0), N, N,
    N, cw(ARM_SOUTH, 0), N, N,
    N, cw(ARM_SOUTH, 1), N, N,
  },
  right = {
    N, N, cw(ARM_NORTH, 1), N,
    N, N, cw(ARM_NORTH, 0), N,
    N, N, acw(ARM_SOUTH, 0), N,
    N, N, acw(ARM_SOUTH, 1), N,
  },
}

-- pokeemerald/src/rotating_gate.c:528
RotatingGate.ARM_POS_CW = {
  { 0, -1 }, { 1, -2 }, { 0, 0 }, { 1, 0 }, { -1, 0 }, { -1, 1 }, { -1, -1 }, { -2, -1 },
}
RotatingGate.ARM_POS_ACW = {
  { -1, -1 }, { -1, -2 }, { 0, -1 }, { 1, -1 }, { 0, 0 }, { 0, 1 }, { -1, 0 }, { -2, 0 },
}

-- pokeemerald/src/rotating_gate.c:538
RotatingGate.ARM_LAYOUT = {
  [0] = { 1, 0, 1, 0, 0, 0, 0, 0 },
  { 1, 1, 1, 0, 0, 0, 0, 0 },
  { 1, 0, 1, 1, 0, 0, 0, 0 },
  { 1, 1, 1, 1, 0, 0, 0, 0 },
  { 1, 0, 1, 0, 1, 0, 0, 0 },
  { 1, 1, 1, 0, 1, 0, 0, 0 },
  { 1, 0, 1, 1, 1, 0, 0, 0 },
  { 1, 0, 1, 0, 1, 1, 0, 0 },
  { 1, 1, 1, 1, 1, 0, 0, 0 },
  { 1, 1, 1, 0, 1, 1, 0, 0 },
  { 1, 0, 1, 1, 1, 1, 0, 0 },
  { 1, 1, 1, 1, 1, 1, 0, 0 },
}

-- pokeemerald/src/rotating_gate.c:625
RotatingGate.PUZZLE_MAPS = {
  EM_FORTREE_CITY_GYM = "fortree",
  EM_ROUTE110_TRICK_HOUSE_PUZZLE6 = "trick_house",
  -- pokeruby/src/rotating_gate.c:623
  RU_FORTREE_CITY_GYM = "fortree",
  RU_ROUTE110_TRICK_HOUSE_PUZZLE6 = "trick_house",
  SA_FORTREE_CITY_GYM = "fortree",
  SA_ROUTE110_TRICK_HOUSE_PUZZLE6 = "trick_house",
}

RotatingGate._p = nil
RotatingGate._manifest = nil
RotatingGate._images = {}

local function session()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function mapId()
  local s = session()
  return s and s.map
end

function RotatingGate.manifest()
  local m = RotatingGate._manifest
  if m ~= nil then return m or nil end
  local src = require("src.core.game3.dataset").cache():read("data/generated/gba/rotating_gates/manifest.lua")
  local chunk = src and load(src, "@rotating_gates/manifest.lua", "t", {})
  local ok, t = false, nil
  if chunk then ok, t = pcall(chunk) end
  RotatingGate._manifest = ok and type(t) == "table" and t or false
  return RotatingGate._manifest or nil
end

-- pokeemerald/src/rotating_gate.c:625
function RotatingGate.puzzleType(id)
  return RotatingGate.PUZZLE_MAPS[id or mapId() or ""]
end

local store = {}

function RotatingGate.setStore(getVar, setVar)
  store.get, store.set = getVar, setVar
end

local function varGet(id)
  if store.get then return store.get(id) end
  local Flags = require("src.core.game3.scripting.flags")
  local Space = package.loaded["src.core.game3.scripting.space"]
  return tonumber(Flags.getVar(Space and Space.store, nil, id)) or 0
end

local function varSet(id, v)
  if store.set then return store.set(id, v) end
  local Flags = require("src.core.game3.scripting.flags")
  local Space = package.loaded["src.core.game3.scripting.space"]
  Flags.setVar(Space and Space.store, nil, id, v)
end

local function varTemp0()
  local Constants = require("src.core.game3.constants")
  local ok, id = pcall(function()
    return Constants.of(Constants.versionOf(session())):require("vars", "VAR_TEMP_0")
  end)
  return ok and id or 0x4000
end

-- pokeemerald/src/rotating_gate.c:651
function RotatingGate.getOrientation(i)
  local v = varGet(varTemp0() + math.floor(i / 2))
  if i % 2 == 0 then return v % 256 end
  return math.floor(v / 256) % 256
end

function RotatingGate.setOrientation(i, o)
  local id = varTemp0() + math.floor(i / 2)
  local v = varGet(id)
  if i % 2 == 0 then
    v = math.floor(v / 256) * 256 + (o % 256)
  else
    v = (o % 256) * 256 + v % 256
  end
  varSet(id, v)
end

-- pokeemerald/src/rotating_gate.c:680
function RotatingGate.loadConfig(kind)
  local m = RotatingGate.manifest()
  local gates = m and m.puzzles and m.puzzles[kind]
  if not gates then return nil end
  RotatingGate._p = { kind = kind, map = mapId(), gates = gates, anims = {} }
  return RotatingGate._p
end

-- pokeemerald/src/rotating_gate.c:933
function RotatingGate.initPuzzle()
  local kind = RotatingGate.puzzleType()
  if not kind then return false end
  local p = RotatingGate.loadConfig(kind)
  if not p then return false end
  for i, g in ipairs(p.gates) do RotatingGate.setOrientation(i - 1, g.orientation) end
  return true
end

-- pokeemerald/src/rotating_gate.c:951
function RotatingGate.initPuzzleAndGraphics()
  local kind = RotatingGate.puzzleType()
  if not kind then return false end
  return RotatingGate.loadConfig(kind) ~= nil
end

function RotatingGate.active()
  local p = RotatingGate._p
  if not p then return false end
  if p.map ~= mapId() then
    RotatingGate._p = nil
    return false
  end
  return true
end

function RotatingGate.reset()
  RotatingGate._p = nil
  RotatingGate._images = {}
  RotatingGate._manifest = nil
end

local function collisionAt(x, y)
  local Collision = package.loaded["src.core.game3.collision"] or require("src.core.game3.collision")
  if Collision.inBounds and not Collision.inBounds(x, y) then return true end
  return not Collision.isWalkable(x, y)
end
RotatingGate.collisionAt = collisionAt

-- pokeemerald/src/rotating_gate.c:850
function RotatingGate.canRotate(i, direction, blocked)
  local p = RotatingGate._p
  local g = p.gates[i + 1]
  local arms = direction == ROTATE_ANTICLOCKWISE and RotatingGate.ARM_POS_ACW or RotatingGate.ARM_POS_CW
  if direction ~= ROTATE_ANTICLOCKWISE and direction ~= ROTATE_CLOCKWISE then return false end
  local orientation = RotatingGate.getOrientation(i)
  local layout = RotatingGate.ARM_LAYOUT[g.shape]
  blocked = blocked or collisionAt
  for arm = ARM_NORTH, ARM_WEST do
    for j = 0, 1 do
      local idx = 2 * ((orientation + arm) % 4) + j
      if layout[2 * arm + j + 1] == 1 then
        local off = arms[idx + 1]
        if blocked(g.x + off[1], g.y + off[2]) then return false end
      end
    end
  end
  return true
end

-- pokeemerald/src/rotating_gate.c:895
function RotatingGate.hasArm(i, arm, long)
  local g = RotatingGate._p.gates[i + 1]
  local armOrientation = (arm - RotatingGate.getOrientation(i) + 4) % 4
  return RotatingGate.ARM_LAYOUT[g.shape][armOrientation * 2 + long + 1] == 1
end

-- pokeemerald/src/rotating_gate.c:661
function RotatingGate.rotate(i, direction)
  local o = RotatingGate.getOrientation(i)
  if direction == ROTATE_ANTICLOCKWISE then
    o = o == 0 and 3 or o - 1
  else
    o = (o + 1) % 4
  end
  RotatingGate.setOrientation(i, o)
end

local function playerFast()
  -- pokeruby/src/rotating_gate.c:789
  return require("src.core.game3.bike.rse").playerSpeed() ~= 1
end

-- pokeemerald/src/rotating_gate.c:762
local function startAnim(i, direction)
  local p = RotatingGate._p
  local from = RotatingGate.getOrientation(i)
  p.anims[i] = { from = from, dir = direction, t = 0, frames = playerFast() and 8 or 16 }
  local SE = require("src.core.game3.se_ids")
  local ok, Audio = pcall(require, "src.core.game3.audio")
  if ok and Audio and Audio.playSe and SE.SE_ROTATING_GATE then Audio.playSe(SE.SE_ROTATING_GATE) end
end

-- pokeemerald/src/rotating_gate.c:961
function RotatingGate.checkCollision(direction, x, y, noAnimation, blocked, quiet)
  if not RotatingGate.active() then return false end
  local p = RotatingGate._p
  local info = RotatingGate.ROTATION_INFO[direction]
  if not info then return false end
  for i, g in ipairs(p.gates) do
    local gi = i - 1
    if g.x - 2 <= x and x <= g.x + 1 and g.y - 2 <= y and y <= g.y + 1 then
      local cx, cy = x - g.x + 2, y - g.y + 2
      local r = info[cy * 4 + cx + 1]
      if r and RotatingGate.hasArm(gi, r.arm, r.long) then
        if RotatingGate.canRotate(gi, r.dir, blocked) then
          if not noAnimation then
            if not quiet then startAnim(gi, r.dir) end
            RotatingGate.rotate(gi, r.dir)
            return false
          end
        else
          return true
        end
      end
    end
  end
  return false
end

function RotatingGate.step()
  local p = RotatingGate._p
  if not p then return end
  for i, a in pairs(p.anims) do
    a.t = a.t + 1
    if a.t >= a.frames then p.anims[i] = nil end
  end
end

-- pokeemerald/src/rotating_gate.c:305
function RotatingGate.angle(i)
  local p = RotatingGate._p
  local a = p and p.anims[i]
  local o = RotatingGate.getOrientation(i)
  if not a then return o * 64 end
  local from = a.from * 64
  local delta = (a.dir == ROTATE_CLOCKWISE and 64 or -64) * math.min(a.t, a.frames) / a.frames
  return from + delta
end

local function image(sheet)
  local img = RotatingGate._images[sheet.file]
  if img ~= nil then return img or nil end
  local rgba = require("src.core.game3.dataset").cache():read("data/generated/gba/rotating_gates/" .. sheet.file)
  if not (rgba and love and love.image and #rgba == sheet.w * sheet.h * 4) then
    RotatingGate._images[sheet.file] = false
    return nil
  end
  img = love.graphics.newImage(love.image.newImageData(sheet.w, sheet.h, "rgba8", rgba))
  if img.setFilter then img:setFilter("nearest", "nearest") end
  RotatingGate._images[sheet.file] = img
  return img
end

local function sheetFor(shape)
  local m = RotatingGate.manifest()
  for _, s in ipairs(m and m.sheets or {}) do
    if s.shape == shape then return s end
  end
  return nil
end

-- pokeemerald/src/rotating_gate.c:728
function RotatingGate.collectActors(actors)
  if not RotatingGate.active() then return end
  for i, g in ipairs(RotatingGate._p.gates) do
    local sheet = sheetFor(g.shape)
    local img = sheet and image(sheet)
    if img then
      local ang = RotatingGate.angle(i - 1)
      local cx, cy = g.x * CELL, g.y * CELL
      actors[#actors + 1] = {
        kind = "rotating_gate", elevation = 3, sortY = cy - CELL, x = cx, y = cy, i = 96000 + i,
        draw = function(_, camX, camY)
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(img, cx - camX, cy - camY, ang * 2 * math.pi / 256, 1, 1, sheet.w / 2, sheet.h / 2)
        end,
      }
    end
  end
end

return RotatingGate
