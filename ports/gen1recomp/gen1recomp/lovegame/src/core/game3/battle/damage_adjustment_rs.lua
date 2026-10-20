local E = require("src.core.game3.battle.effect_ids")
local Types = require("src.core.game3.battle.types")
local HeldItems = require("src.core.game3.battle.held_items")
local Policy = {}

-- pokeruby/src/battle_script_commands.c:1749
function Policy.variance(ad, damage)
  local percent = 100 - ad:roll(0, 15)
  if damage ~= 0 then
    damage = math.floor(damage * percent / 100)
    if damage == 0 then damage = 1 end
  end
  return damage
end

function Policy.psywave(ad)
  local value
  repeat value = ad:roll(0, 15) until value <= 10
  return value
end

function Policy.immune(M, info)
  local ad, target = M.adapter, M.target
  local moveType = tonumber(info and info.moveType) or tonumber(M.moveType or M.move.type)
  if ad:abilityOf(target) == "LEVITATE" and moveType == Types.ID.GROUND then return true end
  if info and info.effectiveness == 0 then return true end
  if ad:abilityOf(target) == "WONDER_GUARD" then
    local flags = info and info.typeFlags or {}
    if not flags.super or flags.notVery then return true end
  end
  return false
end

local fixed = {
  [E.DRAGON_RAGE] = true, [E.SONICBOOM] = true, [E.LEVEL_DAMAGE] = true,
  [E.PSYWAVE] = true, [E.COUNTER] = true, [E.MIRROR_COAT] = true,
}

function Policy.hitSite(M)
  if M.effect == E.SUPER_FANG then return "none" end
  if M.effect == E.ENDEAVOR then return "set_unless_immune" end
  if fixed[M.effect] then return "set" end
  if M._rsMultiHit == "multiHitEnd" or M.effect == E.MULTI_HIT
      or M.effect == E.DOUBLE_HIT or M.effect == E.TWINEEDLE or M.effect == E.FURY_CUTTER then
    return "normal_unless_immune"
  end
  return "normal"
end

function Policy.reached(M, info, site)
  if site == "none" then return false end
  if site == "normal_unless_immune" or site == "set_unless_immune" then
    return not Policy.immune(M, info)
  end
  return true
end

-- pokeruby/src/battle_script_commands.c:1770
function Policy.adjust(M, target, damage, site)
  local ad = M.adapter
  if site ~= "set" and site ~= "set_unless_immune" then
    damage = Policy.variance(ad, damage)
  end
  local proc = HeldItems.rollFocusBand(ad, target)
  target.expFocusBanded = nil
  M._rsAdjustmentBands = M._rsAdjustmentBands or {}
  if proc then M._rsAdjustmentBands[target] = true end
  local banded = M._rsAdjustmentBands[target]
  if (target.substituteHP or 0) <= 0 then
    local falseSwipe = site ~= "normal2" and M.effect == E.FALSE_SWIPE
    if (falseSwipe or target.expEnduring or banded) and damage >= ad:hp(target) then
      damage = ad:hp(target) - 1
      if target.expEnduring then return damage, "endured" end
      if banded then return damage, "hung" end
    end
  end
  return damage
end

return Policy
