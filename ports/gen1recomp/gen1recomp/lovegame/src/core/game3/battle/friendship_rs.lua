local Pokemon = require("src.core.game3.pokemon")
local ItemsData = require("src.core.game3.items_data")

local F = {}

local function flag(v)
  return v == true or v == 1
end

-- pokemon_3.c:664
function F.planLeague(mon, ctx)
  ctx = ctx or {}
  if type(mon) ~= "table" then return nil, "empty_mon" end
  local species = Pokemon.speciesOf(mon) or 0
  if species == 0 or species == Pokemon.SPECIES_EGG or flag(mon.isEgg)
      or flag(mon.egg) or flag(mon.isBadEgg) or flag(mon.badEgg) then
    return nil, "empty_or_egg"
  end
  local trainer = ctx.trainerFlag
  if ctx.battleTypeFlags ~= nil then
    trainer = math.floor((tonumber(ctx.battleTypeFlags) or 0) / 8) % 2 == 1
  end
  if trainer == nil then return nil, "missing_trainer_flag" end
  if not flag(trainer) then return nil, "not_trainer" end
  local class = tonumber(ctx.trainerClass)
  if class == nil then return nil, "missing_raw_trainer_class" end
  if class ~= 24 and class ~= 25 and class ~= 32 then return nil, "not_league_class" end

  local item = ItemsData.toNumericId(mon.item or mon.heldItem or 0)
  if item == nil then return nil, "missing_native_item_id" end
  local holdEffect
  if item == 175 then
    holdEffect = tonumber(ctx.battleEnigma0HoldEffect)
    if holdEffect == nil then return nil, "missing_battle_enigma0_hold_effect" end
  elseif item == 0 then
    holdEffect = 0
  else
    local info = ItemsData.info(item)
    holdEffect = info and tonumber(info.holdEffect)
    if holdEffect == nil then return nil, "missing_native_item_hold_effect" end
  end
  local mapSec = tonumber(ctx.mapSec)
  if mapSec == nil then return nil, "missing_native_map_section" end
  local before = Pokemon.friendshipOf(mon)
  local tier = before > 199 and 3 or (before > 99 and 2 or 1)
  local delta = ({3, 2, 1})[tier]
  if holdEffect == 27 then delta = math.floor(150 * delta / 100) end
  local ball = ItemsData.toNumericId(mon.pokeball or mon.ball or 0)
  if ball == nil then return nil, "missing_native_ball_id" end
  local ballBonus = ball == 11 and 1 or 0
  local locationBonus = (tonumber(mon.metLocation) or 0) == mapSec and 1 or 0
  return { event = 3, before = before, holdEffect = holdEffect, delta = delta,
    ballBonus = ballBonus, locationBonus = locationBonus,
    after = math.max(0, math.min(255, before + delta + ballBonus + locationBonus)) }
end

function F.applyLeague(mon, ctx)
  local plan, reason = F.planLeague(mon, ctx)
  if not plan then return false, reason end
  Pokemon.setFriendship(mon, plan.after)
  return true, plan
end

return F
