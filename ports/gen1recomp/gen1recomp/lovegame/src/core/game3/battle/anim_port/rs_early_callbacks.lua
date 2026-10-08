local bit = require("bit")
local S = require("src.core.game3.battle.anim_port.g1_sprite")
local P = require("src.core.game3.battle.anim_port.g1_pret")
local Coords = require("src.core.game3.battle.anim_coords")
local Trig = require("src.core.game3.trig")
local Rng = require("src.core.game3.rng")
local RS = require("src.core.game3.battle.anim_port.rs_callbacks")
local Context = require("src.core.game3.battle.anim_context")

return function(existing)
  local C = {}
  local function bind(init)
    local fn = S.wrap(init)
    return function(s)
      if not s._g1 then s._nativeTemplate = RS._template(s) end
      return fn(s)
    end
  end
  local function arg(s, index, value)
    value = P.s16(value)
    s._A[index] = value
    if s._vm then s._vm.args[index] = value end
  end
  local function gate(name, init)
    local native, previous = bind(init), existing[name]
    C[name] = function(s)
      if s._vm and s._vm._pack and s._vm._pack.assetLayout == "rs" then return native(s) end
      return previous(s)
    end
  end
  local contest = Context.isContest

  -- pokeruby/src/battle/anim/normal.c:938
  C.sub_80E29C0 = bind(function(s)
    S.startAffineAnim(s, s._A[3])
    if s._A[2] == 0 then S.initPosToAttacker(s, true) else S.initPosToTarget(s, true) end
    s._cb = function(sp)
      sp.visible = not sp.visible
      local old = sp.data[0]
      sp.data[0] = P.s16(old + 1)
      if old > 12 then S.destroy(sp) end
    end
  end)

  -- pokeruby/src/battle/anim/water.c:225
  C.sub_80D37FC = bind(function(s)
    S.initPosToTarget(s, true)
    s.data[0], s.data[2], s.data[4] = s._A[4], P.s16(s.x + s._A[2]), P.s16(s.y + s._A[4])
    s._cb = S.startLinear
    S.store(s, S.destroy)
  end)

  -- pokeruby/src/battle/anim/orbs.c:268
  C.sub_80CA9A8 = bind(function(s)
    S.initPosToTarget(s, true)
    s.data[0] = s._A[3]
    s.data[2] = P.coord(s._vm, P.atk(s._vm), P.X_2)
    s.data[4] = P.coord(s._vm, P.atk(s._vm), P.Y_PIC_OFFSET)
    s.data[5] = s._A[2]
    S.initArc(s)
    s._cb = function(sp) if S.translateHArc(sp) then S.destroy(sp) end end
  end)

  -- pokeruby/src/battle_anim_effects_3.c:1472
  C.sub_812C80C = bind(function(s)
    S.setToAttackerCoords(s)
    S.setInitialXOffset(s, s._A[0])
    s.y = P.s16(s.y + s._A[1])
    s._cb = S.runStoredWhenAnimEnds
    S.store(s, S.destroy)
  end)

  -- pokeruby/src/battle/anim/brace.c:42
  C.sub_80CDF0C = bind(function(s)
    local side = s._A[0] == 0 and P.atk(s._vm) or P.tgt(s._vm)
    s.x = P.s16(P.coord(s._vm, side, P.X) + s._A[1])
    s.y = P.s16(P.coord(s._vm, side, P.Y) + s._A[2])
    s.data[1] = s._A[3]
    s._cb = function(sp)
      sp.data[0] = P.s16(sp.data[0] + 1)
      if sp.data[0] > sp.data[1] then sp.data[0] = 0; sp.y = P.s16(sp.y - 1) end
      sp.y = P.s16(sp.y - sp.data[0])
      if sp.animEnded then S.destroy(sp) end
    end
  end)

  -- pokeruby/src/battle/anim/flying.c:372
  C.sub_80DA034 = bind(function(s)
    S.initPosToTarget(s, false)
    s.y = P.s16(s.y + 20)
    s.data[1] = 191
    s._cb = function(sp)
      local d = sp.data
      sp.ox, sp.oy = P.Sin(d[1], 32), P.Cos(d[1], 8)
      d[1], d[0] = bit.band(d[1] + 5, 255), P.s16(d[0] + 1)
      if d[0] == 71 then S.destroy(sp) end
    end
    s._cb(s)
  end)

  -- pokeruby/src/battle/anim/fight.c:490
  C.sub_80D90F4 = bind(function(s)
    local A, vm = s._A, s._vm
    local side = A[0] == 0 and P.atk(vm) or P.tgt(vm)
    local id = A[0] == 0 and P.atkId(vm) or P.tgtId(vm)
    if A[2] < 0 then arg(s, 2, Rng.Random() % 5) end
    S.startAnim(s, A[2])
    local xMod = P.cdiv(P.attr(vm, side, P.ATTR_WIDTH), 2)
    local yMod = P.cdiv(P.attr(vm, side, P.ATTR_HEIGHT), 4)
    local x, y = Rng.Random() % xMod, Rng.Random() % yMod
    if bit.band(Rng.Random(), 1) ~= 0 then x = -x end
    if bit.band(Rng.Random(), 1) ~= 0 then y = -y end
    if id % 2 == 0 then y = y - 16 end
    s.x = P.s16(P.coord(vm, side, P.X_2) + x)
    s.y = P.s16(P.coord(vm, side, P.Y_PIC_OFFSET) + y)
    s.data[0] = A[1]
    s._rsHitChild = S.create(vm, "gBasicHitSplatSpriteTemplate", s.x, s.y, s.subpriority + 1)
    if s._rsHitChild then S.startAffineAnim(s._rsHitChild, 0) end
    s._cb = function(sp)
      if sp.data[0] == 0 then
        if sp._rsHitChild then S.destroy(sp._rsHitChild) end
        S.destroy(sp)
      else sp.data[0] = P.s16(sp.data[0] - 1) end
    end
  end)

  -- pokeruby/src/battle/anim/bug.c:369
  gate("TranslateStinger", function(s)
    local A, vm = s._A, s._vm
    local atk, tgt = P.atkId(vm), P.tgtId(vm)
    if contest(vm) then arg(s, 2, -A[2])
    elseif atk % 2 == 1 then
      arg(s, 2, -A[2]); arg(s, 1, -A[1]); arg(s, 3, -A[3])
    end
    if not contest(vm) and atk % 2 == tgt % 2 and tgt < 2 then
      arg(s, 2, -A[2]); arg(s, 0, -A[0])
    end
    S.initPosToAttacker(s, true)
    local x = P.s16(P.coord(vm, P.tgt(vm), P.X_2) + A[2])
    local y = P.s16(P.coord(vm, P.tgt(vm), P.Y_PIC_OFFSET) + A[3])
    local rot = P.u16(-Trig.arcTan2(P.s16(x - s.x), P.s16(y - s.y)) + 0xC000)
    S.trySetRotScale(s, false, 256, 256, rot)
    s.data[0], s.data[2], s.data[4] = A[4], x, y
    s._cb = S.startLinear
    S.store(s, S.destroy)
  end)

  -- pokeruby/src/battle/anim/ground.c:216
  gate("DirtScatter", function(s)
    S.initPosToAttacker(s, true)
    local x, y = Rng.Random() % 32, Rng.Random() % 32
    if x > 16 then x = 16 - x end
    if y > 16 then y = 16 - y end
    s.data[0] = s._A[2]
    s.data[2] = P.coord(s._vm, P.tgt(s._vm), P.X_2) % 256 + x
    s.data[4] = P.coord(s._vm, P.tgt(s._vm), P.Y_PIC_OFFSET) % 256 + y
    s._cb = S.startLinear
    S.store(s, S.DestroySpriteAndMatrix)
  end)

  -- pokeruby/src/battle/anim/poison.c:297
  gate("BubbleEffect", function(s)
    local A, vm = s._A, s._vm
    if A[2] == 0 then S.initPosToTarget(s, true)
    else
      local target = P.tgtId(vm)
      local partner = Coords.isDouble() and not contest(vm) and Coords.partner(target) or target
      s.x = P.cdiv(P.coord(vm, target, P.X_2) + P.coord(vm, partner, P.X_2), 2)
      s.y = P.cdiv(P.coord(vm, target, P.Y_PIC_OFFSET) + P.coord(vm, partner, P.Y_PIC_OFFSET), 2)
      if P.isOpponent(P.atk(vm)) then arg(s, 0, -A[0]) end
      s.x, s.y = P.s16(s.x + A[0]), P.s16(s.y + A[1])
    end
    s._cb = function(sp)
      sp.data[0] = bit.band(sp.data[0] + 11, 255)
      sp.ox = P.Sin(sp.data[0], 4)
      sp.data[1] = P.s16(sp.data[1] + 48)
      sp.oy = -bit.arshift(sp.data[1], 8)
      if sp.affineAnimEnded then S.destroy(sp) end
    end
  end)
  return C
end
