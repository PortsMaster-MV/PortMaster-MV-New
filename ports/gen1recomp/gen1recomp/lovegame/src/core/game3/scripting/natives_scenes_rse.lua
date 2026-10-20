local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")

local ScenesRse = {}

-- pokeemerald/include/constants/vars.h:280
local VAR_0x8004 = 0x8004

-- pokeemerald/src/field_specials.c:3785 Script_DoRayquazaScene
function ScenesRse.doRayquazaScene(ctx, adapters, opts)
  opts = opts or {}
  local Natives = require("src.core.game3.scripting.natives")
  local finished = false
  Natives.awaitState(ctx, function() return finished end)
  local fightOnly = Rse.specialVar(ctx, VAR_0x8004) == 0
  local open = opts.open or function(o) return require("src.ui.game3.rse.rayquaza_scene").open(o) end
  local Fade = require("src.ui.game3.fade")
  Fade.clear()
  ScenesRse.last = { fightOnly = fightOnly }
  ScenesRse.last.screen = open({
    -- pokeemerald/src/field_specials.c:3789
    animId = fightOnly and 0 or 1,
    endEarly = fightOnly,
    onDone = function()
      ScenesRse.last.done = true
      Fade.mode, Fade.t, Fade.active = Fade.MODE.TO_BLACK, 16, false
      Fade.begin(Fade.MODE.FROM_BLACK, 1)
      -- pokeemerald/src/overworld.c:1684
      pcall(function() require("src.core.game3.audio").mapLoadMusic({}) end)
      finished = true
    end,
  })
  return false
end

ScenesRse.BY_NAME = {
  -- pokeemerald/src/field_specials.c:3785
  Script_DoRayquazaScene = function(ctx, adapters)
    return ScenesRse.doRayquazaScene(ctx, adapters)
  end,
  -- pokeemerald/src/main.c:141
  -- pokeemerald/src/main.c:428
  DoSoftReset = function()
    local Runtime = package.loaded["src.core.game3.runtime"]
    local game = Runtime and Runtime._game
    if game then game.softResetRequested = true end
    return false
  end,
}
Std.legacyHandlers(ScenesRse)

return ScenesRse
