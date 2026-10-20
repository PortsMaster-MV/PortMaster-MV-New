local P = require("src.core.game3.battle.anim_port.g1_pret")
local K = require("src.core.game3.battle.anim_port.g1_task_base")
local Coords = require("src.core.game3.battle.anim_coords")
local Context = require("src.core.game3.battle.anim_context")

local function partySpecies(st, id)
  local battler = Coords.battler(st, id)
  local party = st and (id % 2 == 0 and st.playerParty or st.foeParty)
  local mon = party and battler and party[battler.partyIndex]
  return tonumber(mon and (mon.species or mon.speciesId)) or 0
end

return function()
  return {
    -- pokeruby/src/battle/anim/sfx.c:142
    sub_812B18C = K.wrap(function(t, vm)
      local A, species = t._A, 0
      local isContest = Context.isContest(vm)
      -- battle_anim.c:2527
      local pan = isContest and 63 or (P.atkId(vm) % 2 == 0 and -64 or 63)
      if isContest then
        if A[0] == 0 then species = tonumber(P.species(vm, P.atk(vm))) or 0
        else K.destroy(t) end
      else
        local id
        if A[0] == 0 then id = P.atkId(vm)
        elseif A[0] == 1 then id = P.tgtId(vm)
        elseif A[0] == 2 then id = Coords.partner(P.atkId(vm))
        else id = Coords.partner(P.tgtId(vm)) end
        if (A[0] == 1 or A[0] == 3) and not P.spriteVisible(id) then
          K.destroy(t)
          return
        end
        species = partySpecies(K.battleState(), id)
      end
      if species ~= 0 then
        local mode = A[1] == 255 and 0 or A[1] % 256
        require("src.core.game3.audio").playCry(species, { mode = mode, pan = pan, volume = 125 })
      end
      K.destroy(t)
    end),
  }
end
