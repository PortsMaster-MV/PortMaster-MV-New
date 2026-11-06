local R = require("src.core.game3.rse.init")
local Learn = require("src.core.game3.move_learn")
local N = {BY_NAME = {}}

-- pokeruby/script_pokemon_util_80F99CC.c:52
N.BY_NAME.SelectMoveTutorMon = function(ctx, adapters)
  local function selected()
    local slot = R.specialVar(ctx, 0x8004)
    if slot >= 6 then R.setSpecialVar(ctx, 0x8004, 0xFF); return end
    R.setSpecialVar(ctx, 0x8005, Learn.countRelearnableMoves(R.session().party[slot + 1]))
  end
  local yielded = require("src.core.game3.scripting.natives").choosePartyMon(ctx, adapters, 7)
  if not yielded then selected(); return false end
  local prior = ctx.nativePoll
  ctx.nativePoll = function()
    if prior and not prior() then return false end
    selected(); return true
  end
  return true
end
-- move_tutor_menu.c:240
N.BY_NAME.DisplayMoveTutorMenu = function(ctx, adapters)
  local s, slot = R.session(), R.specialVar(ctx, 0x8004)
  local mon = s and s.party and s.party[slot + 1]
  if not mon or slot >= 6 then return false end
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    local Message = require("src.ui.game3.message")
    if Message.isOpen() then Message.close() end
    require("src.ui.game3.rs.move_relearner").show(mon, {session = s, onDone = function(learned)
      R.setSpecialVar(ctx, 0x8004, learned and 1 or 0); done()
    end})
  end)
end
return N
