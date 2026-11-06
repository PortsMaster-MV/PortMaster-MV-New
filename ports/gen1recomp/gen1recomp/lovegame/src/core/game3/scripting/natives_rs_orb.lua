local Orb = require("src.core.game3.rse.orb_effect_rs")
local Rse = require("src.core.game3.rse.init")

local RsOrb = { BY_NAME = {} }

RsOrb.BY_NAME.sub_80818A4 = function(ctx)
  local ready = false
  Orb.start(Rse.specialVar(ctx, 0x800D), function() ready = true end)
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return ready end)
  return false
end

-- pokeruby/src/field_screen_effect.c:321
RsOrb.BY_NAME.sub_80818FC = function(ctx)
  local done = false
  Orb.fade(function() done = true end)
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  return false
end

RsOrb.BY_NAME.sub_8081924 = function(ctx)
  local Audio = require("src.core.game3.audio")
  Audio.fadeOutBgm(4)
  local done = false
  require("src.core.game3.task").spawn(function()
    if not Audio.isBgmStopped() then return false end
    done = true
    return true
  end)
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  return false
end

return RsOrb
