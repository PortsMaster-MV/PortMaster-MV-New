local Rse = require("src.core.game3.rse.init")
local S = require("src.core.game3.rse.secret_base_battle_rs")
local N = {BY_NAME = {}}
local function session() return assert(Rse.session(), "native RS secret-base session missing") end
-- secret_base.inc:312
N.BY_NAME.sub_80BCE1C = function() S.prepare(session()); return false end
N.BY_NAME.sub_80BCE90 = function(ctx)
  local owner, battled = S.ownerAndState(session())
  Rse.setSpecialVar(ctx, 0x8004, owner); Rse.setSpecialVar(ctx, 0x800D, battled)
  return false
end
N.BY_NAME.sub_80BCE4C = function(ctx) S.setBattledOwner(session(), Rse.specialVar(ctx, 0x800D)); return false end
N.BY_NAME.sub_810FF60 = function(ctx)
  return false, require("src.core.game3.rse.fan_club_rs").activity(session(), Rse.specialVar(ctx, 0x8004))
end
return N
