local Std = require("src.core.game3.scripting.stdscripts")

local NativesPuzzlesRse = {}

NativesPuzzlesRse.SOURCES = {
  "src.core.game3.braille_field",
  "src.core.game3.mirage_tower",
  "src.core.game3.faraway_island",
  "src.core.game3.special_scene_rse",
}

NativesPuzzlesRse.BY_NAME = {
  -- pokeemerald/src/field_special_scene.c:377
  LookThroughPorthole = function(ctx, adapters)
    local Natives = require("src.core.game3.scripting.natives")
    return Natives.yieldHost(ctx, adapters, function(done)
      local Runtime = package.loaded["src.core.game3.runtime"] or require("src.core.game3.runtime")
      local session = Runtime.getSession and Runtime.getSession()
      local Rse = require("src.core.game3.rse.init")
      local Constants = require("src.core.game3.constants").active(session)
      local state = Rse.var("VAR_SS_TIDAL_STATE", session)
      local steps = Rse.var("VAR_CRUISE_STEP_COUNT", session)
      local groups = Constants.map_groups.byName
      local dest = require("src.core.game3.special_scene_rse").portholeDestination(state, steps, groups)
      local current = require("src.core.game3.map").current
      local group, num = Rse.mapGroupNum(current, session)
      if not dest or group == nil or num == nil then
        if adapters and adapters.log then adapters.log("LookThroughPorthole: invalid cruise state or current map") end
        done()
        return
      end
      local profile = require("src.core.game3.profile").forSession(session)
      local returnX = tonumber(require("src.core.game3.player").cellX) or 0
      local returnY = tonumber(require("src.core.game3.player").cellY) or 0
      session.dynamicWarp = { map = current, warpId = 0xFF, x = returnX, y = returnY }
      Rse.setFlag("FLAG_SYS_CRUISE_MODE", true, session)
      Rse.setFlag("FLAG_DONT_TRANSITION_MUSIC", true, session)
      Rse.setFlag("FLAG_HIDE_MAP_NAME_POPUP", true, session)
      local mapId = profile.map.enginePrefix .. dest.map:gsub("^MAP_", "")
      local Warp = require("src.core.game3.warp")
      Warp.scripted(Runtime._mod, Runtime._game, "rse_porthole_enter", mapId, dest.x, dest.y, nil, function()
        require("src.core.game3.special_scene_rse").enterPorthole(
          session, state == 2 and "right" or "left", done)
      end)
    end)
  end,
  -- pokeemerald/src/rotating_gate.c:933
  RotatingGate_InitPuzzle = function()
    require("src.core.game3.rotating_gate").initPuzzle()
    return false
  end,
  -- pokeemerald/src/rotating_gate.c:951
  RotatingGate_InitPuzzleAndGraphics = function()
    require("src.core.game3.rotating_gate").initPuzzleAndGraphics()
    return false
  end,
}

for _, name in ipairs(NativesPuzzlesRse.SOURCES) do
  for special, fn in pairs(require(name).BY_NAME or {}) do
    NativesPuzzlesRse.BY_NAME[special] = fn
  end
end

require("src.core.game3.rotating_tile_puzzle")

Std.legacyHandlers(NativesPuzzlesRse)

return NativesPuzzlesRse
