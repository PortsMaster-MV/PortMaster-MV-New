local WarpArrow = {}

local CELL = 16
local ANIM_INDEX = { down = 1, up = 2, left = 3, right = 4 }
local DELTA = { down = { 0, 1 }, up = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 } }

-- pokefirered/src/data/field_effects/field_effect_objects.h:241
local FRLG_ANIMS = {
  { { 2, 32 }, { 3, 32 } },
  { { 0, 32 }, { 1, 32 } },
  { { 4, 32 }, { 5, 32 } },
  { { 6, 32 }, { 7, 32 } },
}

WarpArrow._state = { visible = false }

local function FE()
  return package.loaded["src.core.game3.field_effects"] or require("src.core.game3.field_effects")
end

local function Collision()
  return package.loaded["src.core.game3.collision"]
end

local function sequence(idx)
  local fe = FE()
  if not fe.manifest() then return FRLG_ANIMS[idx] end
  local o = fe.manifestObject("arrow")
  local out = {}
  for _, c in ipairs(o and o.anims and o.anims[idx] or {}) do
    if c[1] == "frame" then out[#out + 1] = { tonumber(c[2]) or 0, math.max(1, tonumber(c[3]) or 1) } end
  end
  return #out > 0 and out or nil
end

function WarpArrow.hide()
  WarpArrow._state.visible = false
end

-- pokeemerald/src/field_effect_helpers.c:193
function WarpArrow.show(dir, cx, cy)
  local s = WarpArrow._state
  if s.visible and s.cx == cx and s.cy == cy then return end
  s.visible, s.cx, s.cy = true, cx, cy
  s.seq = sequence(ANIM_INDEX[dir])
  s.step, s.timer = 1, 0
end

-- pokeemerald/src/field_player_avatar.c:1445
function WarpArrow.update(P)
  local C = Collision()
  if not (C and C.behavior and C.arrowWarpDir) then return WarpArrow.hide() end
  local cx, cy = P.cellX, P.cellY
  if P.moving then cx, cy = P.targetX, P.targetY end
  local dir = P.facingLocked and P.moveDir or P.facing
  local arrowDir = C.arrowWarpDir(C.behavior(cx, cy))
  local d = DELTA[dir]
  if arrowDir == nil or arrowDir ~= dir or not d then return WarpArrow.hide() end
  WarpArrow.show(dir, cx + d[1], cy + d[2])
end

function WarpArrow.step()
  local s = WarpArrow._state
  if not (s.visible and s.seq) then return end
  s.timer = s.timer + 1
  if s.timer >= s.seq[s.step][2] then
    s.timer = 0
    s.step = s.step % #s.seq + 1
  end
end

function WarpArrow.draw(camX, camY)
  local s = WarpArrow._state
  if not (s.visible and s.seq) then return end
  local sheet = FE().loadSheet("arrow", 16, 16, 8)
  local q = sheet and sheet.quads[s.seq[s.step][1]]
  if not q then return end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(sheet.image, q, s.cx * CELL - camX, s.cy * CELL - camY)
end

return WarpArrow
