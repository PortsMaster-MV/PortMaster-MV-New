local Rse = require("src.core.game3.rse.init")

local Natives = {}

Natives.BY_NAME = {
  -- pokeemerald/src/egg_hatch.c:395
  ScriptHatchMon = function(ctx)
    local session = Rse.session()
    local slot = Rse.specialVar(ctx, require("src.core.game3.constants").active(Rse.session()):var("VAR_0x8004"))
    local mon = session and session.party and session.party[slot + 1]
    if mon then require("src.core.game3.breeding").hatchMon(session, mon) end
    return false
  end,
  -- pokeemerald/src/egg_hatch.c:472
  EggHatch = function(ctx)
    local session = Rse.session()
    local slot = Rse.specialVar(ctx, require("src.core.game3.constants").active(Rse.session()):var("VAR_0x8004"))
    local mon = session and session.party and session.party[slot + 1]
    if not mon or slot < 0 or slot >= 6 then return false end

    local done = false
    require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
    local Audio = require("src.core.game3.audio")
    require("src.ui.game3.egg_hatch").start(mon, {
      session = session,
      slot = slot,
      savedSong = Audio._mapSong,
      onDone = function() done = true end,
    })
    return false
  end,
}

return Natives
