local Rse = require("src.core.game3.rse.init")

local CableCarCore = {}

-- pokeemerald/include/constants/vars.h:280
local VAR_0x8004 = 0x8004
-- pokeemerald/include/constants/global.h:113
local FEMALE = 1

-- pokeemerald/src/field_specials.c:927
function CableCarCore.destination(goingDown, sess)
  local name = (goingDown and goingDown ~= 0) and "MAP_ROUTE112_CABLE_CAR_STATION" or "MAP_MT_CHIMNEY_CABLE_CAR_STATION"
  local Constants = require("src.core.game3.constants")
  local C = Constants.of(Constants.versionOf(sess or Rse.session()))
  local e = C:require("map_groups", name)
  return { group = tonumber(e.group), num = tonumber(e.num), warpId = -1, x = 6, y = 4 }
end

-- pokeemerald/src/field_specials.c:927 CableCarWarp
function CableCarCore.setWarp(ctx, adapters)
  local d = CableCarCore.destination(Rse.specialVar(ctx, VAR_0x8004))
  if adapters and adapters.setWarp then
    adapters.setWarp("setwarp", d.group, d.num, d.warpId, d.x, d.y)
  else
    local sess = Rse.session()
    if sess then
      local MapCatalog = require("src.import.gba.map_catalog")
      sess.warpDestination = { map = MapCatalog.mapIdFor(d.group, d.num), mapGroup = d.group, mapNum = d.num,
        warpId = d.warpId, x = d.x, y = d.y }
    end
  end
  return d
end

local function warpTarget(sess)
  local w = sess and sess.warpDestination
  if type(w) == "table" and w.mapGroup then return w end
  return nil
end

-- pokeemerald/src/cable_car.c:236 CableCar
function CableCarCore.start(ctx, adapters, opts)
  opts = opts or {}
  local Natives = require("src.core.game3.scripting.natives")
  local sess = Rse.session()
  local goingDown = Rse.specialVar(ctx, VAR_0x8004) ~= 0
  local finished = false
  CableCarCore.last = { goingDown = goingDown, phase = "fade" }
  Natives.awaitState(ctx, function() return finished end)
  local Fade = require("src.ui.game3.fade")
  local function arrive()
    CableCarCore.last.phase = "done"
    finished = true
  end
  local function warp()
    CableCarCore.last.phase = "warp"
    local w = warpTarget(sess)
    if not (w and adapters and adapters.warp) then
      local msg = "[game3] CableCar: no warp destination (CableCarWarp not run)"
      if adapters and adapters.log then adapters.log(msg) else print(msg) end
      arrive()
      return
    end
    -- pokeemerald/src/cable_car.c:401
    adapters.warp(w.mapGroup, w.mapNum, w.warpId, w.x, w.y, arrive, "seagallop")
  end
  local function scene()
    CableCarCore.last.phase = "scene"
    Fade.clear()
    local open = opts.openScene or function(o) return require("src.ui.game3.rse.cable_car").open(o) end
    CableCarCore.last.screen = open({
      goingDown = goingDown,
      female = (tonumber(sess and sess.gender) or 0) == FEMALE,
      onDone = function()
        Fade.mode, Fade.t, Fade.active = Fade.MODE.TO_BLACK, 16, false
        warp()
      end,
    })
  end
  -- pokeemerald/src/cable_car.c:240
  if opts.skipFade then scene() else Fade.begin(Fade.MODE.TO_BLACK, 1, scene) end
  return false
end

return CableCarCore
