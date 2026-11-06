local Rse = require("src.core.game3.rse.init")
local N = {BY_NAME = {}}
local B = N.BY_NAME

-- pokeruby/data/specials.inc:157
B.PutZigzagoonInPlayerParty = function()
  require("src.core.game3.rse.story_specials_rs").putWallyZigzagoon()
  return false
end
B.ScrSpecial_StartWallyTutorialBattle = function(ctx, adapters)
  return require("src.core.game3.rse.story_specials_rs").startWallyTutorial(ctx, adapters)
end

-- pokeruby/src/field_specials.c:714
B.CableCarWarp = function(ctx, adapters)
  require("src.core.game3.rse.cable_car").setWarp(ctx, adapters)
  return false
end
-- pokeruby/src/cable_car.c:274
B.CableCar = function(ctx, adapters)
  return require("src.core.game3.rse.cable_car").start(ctx, adapters, {
    openScene = function(opts)
      opts.requireAssetLayout = "rs"
      opts.playerGfxNames = {[0] = "OBJ_EVENT_GFX_RIVAL_BRENDAN_NORMAL", "OBJ_EVENT_GFX_RIVAL_MAY_NORMAL"}
      opts.hikerGfxNames = {[0] = "OBJ_EVENT_GFX_HIKER", "OBJ_EVENT_GFX_CAMPER", "OBJ_EVENT_GFX_PICNICKER", "OBJ_EVENT_GFX_POOCHYENA"}
      return require("src.ui.game3.rse.cable_car").open(opts)
    end,
  })
end

-- field_specials.c:226
B.SetSSTidalFlag = function()
  Rse.setFlag("FLAG_SYS_CRUISE_MODE", true)
  Rse.setVar("VAR_CRUISE_STEP_COUNT", 0)
  return false
end
B.ResetSSTidalFlag = function() Rse.setFlag("FLAG_SYS_CRUISE_MODE", false); return false end

-- field_specials.c:1012
B.SetDepartmentStoreFloorVar = function()
  local s = Rse.session()
  local C = require("src.core.game3.constants").active(s)
  local warp = s and s.dynamicWarp or {}
  local num = tonumber(warp.mapNum or warp.num)
  if not num and warp.map then local _, n = Rse.mapGroupNum(warp.map, s); num = n end
  local floor = 0
  for i, name in ipairs({"MAP_LILYCOVE_CITY_DEPARTMENT_STORE_1F", "MAP_LILYCOVE_CITY_DEPARTMENT_STORE_2F",
    "MAP_LILYCOVE_CITY_DEPARTMENT_STORE_3F", "MAP_LILYCOVE_CITY_DEPARTMENT_STORE_4F",
    "MAP_LILYCOVE_CITY_DEPARTMENT_STORE_5F", "MAP_LILYCOVE_CITY_DEPARTMENT_STORE_ROOFTOP"}) do
    if num == C:require("map_groups", name).num then floor = i == 6 and 15 or i - 1; break end
  end
  Rse.setVar("VAR_DEPT_STORE_FLOOR", floor, s)
  return false
end

-- field_specials.c:1358
local function trick(ctx, on)
  Rse.setSpecialVar(ctx, 0x8004, 0x259)
  require("src.core.game3.scripting.flags").setFlag(Rse.store(), ctx, 0x259, on)
  return false
end
B.SetTrickHouseEndRoomFlag = function(ctx) return trick(ctx, true) end
B.ResetTrickHouseEndRoomFlag = function(ctx) return trick(ctx, false) end

-- field_specials.c:1419
B.IsGrassTypeInParty = function(ctx)
  local s = Rse.session()
  local C = require("src.core.game3.constants").active(s)
  -- pokeruby/include/constants/pokemon.h:113
  local grass, egg = 0x0C, C:require("species", "SPECIES_EGG")
  local value = 0
  for i = 1, 6 do
    local mon = s and s.party and s.party[i]
    local species = tonumber(mon and (mon.species or mon.speciesId)) or 0
    if species ~= 0 and species ~= egg and not (mon.isEgg or mon.egg) then
      local types = require("src.core.game3.pokemon").types(species)
      if types[1] == grass or types[2] == grass then value = 1; break end
    end
  end
  Rse.setSpecialVar(ctx, 0x800D, value)
  return false
end
return N
