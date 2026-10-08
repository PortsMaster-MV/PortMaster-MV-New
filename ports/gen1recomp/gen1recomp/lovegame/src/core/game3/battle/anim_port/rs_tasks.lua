local P = require("src.core.game3.battle.anim_port.g1_pret")
local S = require("src.core.game3.battle.anim_port.g1_sprite")
local K = require("src.core.game3.battle.anim_port.g1_task_base")
local Pal = require("src.core.game3.battle.anim_pal")

return function()
  local T = {}
  local shared = require("src.core.game3.battle.anim_port.g1_tasks")
  -- pokeruby/src/battle/anim/normal.c:465
  T.sub_80E1F8C = shared.BlendColorCycle
  T.sub_80E2DD8 = shared.TraceMonBlended

  -- pokeruby/src/battle/anim/flying.c:390
  T.sub_80DA09C = K.wrap(function(t, vm)
    t.data[0], t.data[1] = t._A[1], t._A[0]
    t._rsGustTag = P.tagIdToName(vm, 0x2719)
    t._fn = function(task)
      local d, old = task.data, task.data[10]
      d[10] = P.s16(old + 1)
      if old == d[1] then
        d[10] = 0
        local f = task._rsGustTag and Pal.writeFaded(task._rsGustTag)
        if f then
          local last = f[8]
          for i = 7, 1, -1 do f[i + 1] = f[i] end
          f[1] = last
        end
      end
      d[0] = P.s16(d[0] - 1)
      if d[0] == 0 then K.destroy(task) end
    end
  end)

  -- pokeruby/src/battle_anim_mon_movement.c:930
  T.sub_80A8EFC = K.wrap(function(t, vm)
    local A, d = t._A, t.data
    t._rsSide = K.battlerSide(vm, A[2])
    if not K.mon(t._rsSide) then K.destroy(t); return end
    if P.isOpponent(t._rsSide) then
      A[1] = P.s16(-A[1])
      if vm then vm.args[1] = A[1] end
    end
    d[2] = A[0]
    d[3] = A[3] == 1 and P.s16(A[0] * A[1]) or 0
    d[4], d[6], d[7] = A[1], A[3], 1
    d[3], d[4] = P.s16(-d[3]), P.s16(-d[4])
    t._fn = function(task)
      local data = task.data
      data[3] = P.s16(data[3] + data[4])
      S.setMonRotScale(task._rsSide, 256, 256, data[3])
      S.monYOffsetFromRotation(task._rsSide)
      data[1] = P.s16(data[1] + 1)
      if data[1] >= data[2] then
        if data[6] == 1 then
          S.resetMonRotScale(task._rsSide)
          K.destroy(task)
        elseif data[6] == 2 then
          data[1], data[4], data[6] = 0, P.s16(-data[4]), 1
        else K.destroy(task) end
      end
    end
  end)
  return T
end
