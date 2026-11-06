local S = require("src.core.game3.battle.anim_port.g1_sprite")
local P = require("src.core.game3.battle.anim_port.g1_pret")
local Rng = require("src.core.game3.rng")
local Context = require("src.core.game3.battle.anim_context")

local C = {}
local templates = setmetatable({}, { __mode = "k" })

local function commands(anims, affine)
  local out = {}
  for index, seq in ipairs(anims or {}) do
    local dst = {}
    out[index - 1] = dst
    for i, cmd in ipairs(seq) do
      if cmd.op == "end" then dst[i] = { e = true }
      elseif cmd.op == "jump" then dst[i] = { jump = cmd.target }
      elseif cmd.op == "loop" then dst[i] = { loop = cmd.count }
      elseif cmd.op == "frame" then
        if affine then
          dst[i] = { xs = cmd.xScale, ys = cmd.yScale, r = cmd.rotation, d = cmd.duration }
        else
          dst[i] = { f = cmd.tile, d = cmd.duration, h = cmd.hFlip, v = cmd.vFlip }
        end
      else error("unsupported native RS sprite command " .. tostring(cmd.op)) end
    end
  end
  return out
end

local function template(s, name, vm)
  local pack = (vm or s._vm) and (vm or s._vm)._pack
  assert(pack and pack.assetLayout == "rs", "native RS callback requires an RS animation pack")
  local row = assert(pack.nativeTemplates and pack.nativeTemplates[name or s.template], "RS native sprite template missing")
  local tpl = templates[row]
  if not tpl then
    local oam, op = assert(row.oam), s._op or {}
    local tag = P.tagIdToName(vm or s._vm, row.tileTag) or op.tag
    local pal = P.tagIdToName(vm or s._vm, row.paletteTag) or op.palTag or tag
    tpl = {
      tag = tag, pal = pal, w = oam.w, h = oam.h,
      affineMode = oam.affineMode, objBlend = oam.objMode == 1, priority = oam.priority,
      anims = commands(row.anims, false), affine = commands(row.affineAnims, true),
    }
    templates[row] = tpl
  end
  return tpl
end
C._template = template

local function bind(init)
  local fn = S.wrap(init)
  return function(s)
    if not s._g1 then s._nativeTemplate = template(s) end
    return fn(s)
  end
end

local function changeArg(s, index, value)
  s._A[index] = value
  if s._vm then s._vm.args[index] = value end
end

-- pokeruby/src/battle/anim/normal.c:863
local function basic(s)
  local A = s._A
  S.startAffineAnim(s, A[3])
  if A[2] == 0 then S.initPosToAttacker(s, true) else S.initPosToTarget(s, true) end
  s._cb = S.runStoredWhenAffineEnds
  S.store(s, S.destroy)
end
C.sub_80E27A0 = bind(basic)

-- pokeruby/src/battle/anim/normal.c:875
C.sub_80E27E8 = bind(function(s)
  basic(s)
  s.data[0] = s._A[4]
  S.store(s, function(sprite)
    local old = sprite.data[0]
    sprite.data[0] = P.s16(old - 1)
    if old <= 0 then S.destroy(sprite) end
  end)
end)

-- pokeruby/src/battle/anim/normal.c:888
C.sub_80E2838 = bind(function(s)
  local contest = Context.isContest(s._vm)
  if P.isOpponent(P.atk(s._vm)) and not contest then changeArg(s, 1, -s._A[1]) end
  basic(s)
end)

-- pokeruby/src/battle/anim/normal.c:896
C.sub_80E2870 = bind(function(s)
  local A = s._A
  if A[1] == -1 then changeArg(s, 1, Rng.Random() % 4) end
  S.startAffineAnim(s, A[1])
  if A[0] == 0 then S.initPosToAttacker(s, false) else S.initPosToTarget(s, false) end
  s.ox = s.ox + Rng.Random() % 48 - 24
  s.oy = s.oy + Rng.Random() % 24 - 12
  S.store(s, S.destroy)
  s._cb = S.runStoredWhenAffineEnds
end)

-- pokeruby/src/battle/anim/normal.c:914
C.sub_80E2908 = bind(function(s)
  local A, vm = s._A, s._vm
  local side = P.sideOf(vm, A[0])
  local mon = P.present(side)
  s.x = P.coord(vm, side, P.X_2) + (mon and mon.ox or 0)
  s.y = P.coord(vm, side, P.Y_PIC_OFFSET_DEFAULT) + (mon and mon.oy or 0)
  s.ox, s.oy = A[1], A[2]
  S.startAffineAnim(s, A[3])
  S.store(s, S.destroy)
  s._cb = S.runStoredWhenAffineEnds
end)

-- pokeruby/src/rom_8077ABC.c:1370
C.sub_80793C4 = bind(function(s)
  local A = s._A
  local respect = A[3] == 0
  if A[2] == 0 then S.initPosToAttacker(s, respect) else S.initPosToTarget(s, respect) end
  s.data[0] = 1
  s._cb = function(sp)
    if sp.animEnded or sp.affineAnimEnded then S.destroy(sp) end
  end
end)

-- pokeruby/src/rom_8077ABC.c:1427
C.sub_80794A8 = bind(function(s)
  local A, vm = s._A, s._vm
  S.initPosToAttacker(s, true)
  if P.isOpponent(P.atk(vm)) then changeArg(s, 2, P.s16(-A[2])) end
  s.data[0] = A[4]
  s.data[2] = P.coord(vm, P.tgt(vm), P.X_2) + A[2]
  s.data[4] = P.coord(vm, P.tgt(vm), P.Y_PIC_OFFSET) + A[3]
  s.data[5] = A[5]
  S.initArc(s)
  s._cb = function(sp) if S.translateHArc(sp) then S.destroy(sp) end end
end)

-- pokeruby/src/rom_8077ABC.c:1446
local function diagonal(s)
  local A, vm = s._A, s._vm
  local respect, slot = A[6] == 0
  if A[5] == 0 then
    S.initPosToAttacker(s, respect)
    slot = P.atk(vm)
  else
    S.initPosToTarget(s, respect)
    slot = P.tgt(vm)
  end
  if P.isOpponent(P.atk(vm)) then changeArg(s, 2, P.s16(-A[2])) end
  S.initPosToTarget(s, respect)
  s.data[0] = A[4]
  s.data[2] = P.coord(vm, slot, P.X_2) + A[2]
  s.data[4] = P.coord(vm, slot, respect and P.Y_PIC_OFFSET or P.Y) + A[3]
  s._cb = S.startLinear
  S.store(s, S.destroy)
end
C.sub_8079534 = bind(diagonal)

-- pokeruby/src/battle/anim/fire_2.c:207
C.sub_80D5210 = bind(function(s)
  changeArg(s, 0, P.s16(-s._A[0]))
  changeArg(s, 2, P.s16(-s._A[2]))
  s._cb = diagonal
end)

local ember = bind(function(s)
  local vm = s._vm
  local atk, tgt = P.atkId(vm), P.tgtId(vm)
  if atk % 2 == tgt % 2 and (atk == 2 or atk == 3) then changeArg(s, 2, P.s16(-s._A[2])) end
  diagonal(s)
end)
-- pokeruby/src/battle/anim/fire_2.c:196
C.EmberFlare = function(s)
  if s._vm and s._vm._pack and s._vm._pack.assetLayout == "rs" then return ember(s) end
  return require("src.core.game3.battle.anim_port.g2_modules").cb.EmberFlare(s)
end

-- pokeruby/src/battle_anim_effects_3.c:3855
C.sub_81300F4 = bind(function(s)
  local A, d, vm = s._A, s.data, s._vm
  local opponent = P.isOpponent(P.atk(vm))
  if opponent then changeArg(s, 0, P.s16(-A[0])) end
  s.x = P.coord(vm, P.atk(vm), P.X) + A[0]
  s.y = P.coord(vm, P.atk(vm), P.Y) + A[1]
  d[0] = 640
  if A[2] == 0 then d[1] = -640
  elseif A[2] == 1 then s._vFlip = true; d[1] = 640
  else S.startAnim(s, 1) end
  if opponent then d[0] = -d[0]; s._hFlip = true end
  s._cb = function(sp)
    local data = sp.data
    data[6], data[7] = P.s16(data[6] + data[0]), P.s16(data[7] + data[1])
    sp.ox, sp.oy = math.floor(data[6] / 256), math.floor(data[7] / 256)
    data[5] = P.s16(data[5] + 1)
    if data[5] == 14 then S.destroy(sp) end
  end
end)

return C
