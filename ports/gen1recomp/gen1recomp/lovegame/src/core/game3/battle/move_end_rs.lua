local Policy = {}
local rawNames = {[1]="SLEEP", [2]="POISON", [3]="BURN", [4]="FREEZE",
  [5]="PARALYSIS", [6]="TOXIC", [7]="CONFUSION", [8]="FLINCH"}

function Policy.beginHit(M, descriptor, kind)
  M._rsMultiHit = kind
  M.adapter._syncEffect = nil
  if descriptor then
    descriptor.raw = M.effect == require("src.core.game3.battle.effect_ids").TWINEEDLE and 2 or 0
    descriptor.effect = rawNames[descriptor.raw]
    M._nativeMoveEffect = function(raw, abilityMarker)
      if raw ~= nil then descriptor.raw, descriptor.effect = raw, rawNames[raw] end
      if abilityMarker ~= nil then M._rsStatusAbilityEffect = abilityMarker end
    end
  end
end

function Policy.afterHit(M)
  local Engine = require("src.core.game3.battle.engine")
  Engine.moveEndRageDefrost(M)
  Engine.moveEndEffects(M, {includeFaintedItems = true})
  Engine.moveEndBookkeeping(M)
  M._nativeMoveEffect = nil
end

function Policy.finalEffects(M)
  local Engine = require("src.core.game3.battle.engine")
  if M._rsMultiHit == "tripleKickEnd" then
    return true
  elseif M._rsMultiHit == "multiHitEnd" then
    Engine.moveEndEffects(M, {skipContact = true, includeFaintedItems = true})
    return true
  end
  return false
end

return Policy
