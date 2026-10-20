local Rse = require("src.core.game3.rse.init")
local Story = require("src.core.game3.rse.story_specials")
local Config = require("src.core.game3.profiles.rs.gym")

local Gym = { BY_NAME = {} }
local B = Gym.BY_NAME

local function constants() return require("src.core.game3.constants").active(Rse.session()) end
local function metatileAt(x, y)
  return require("src.core.game3.step_callbacks_rse").metatileAt(x, y) or 0
end
local function setMetatile(x, y, id, impassable)
  require("src.core.game3.field").setMetatile(x, y, id, impassable == true)
end
local function drawWholeMap()
  local View = package.loaded["src.core.game3.field_view"]
  if View then View._nativeDirty = true end
end

-- pokeruby/src/field_specials.c:390
B.MauvilleGymSpecial1 = function(ctx)
  Story.mauvillePressSwitch(Rse.specialVar(ctx, 0x8004), metatileAt, setMetatile, constants(), Config.mauvilleSwitches)
  return false
end
B.MauvilleGymSpecial2 = function()
  Story.mauvilleSetDefaultBarriers(metatileAt, setMetatile, constants())
  return false
end
B.MauvilleGymSpecial3 = function()
  Story.mauvilleDeactivatePuzzle(metatileAt, setMetatile, constants(), Config.mauvilleSwitches)
  return false
end

-- pokeruby/src/field_specials.c:571
B.PetalburgGymSlideOpenDoors = function(ctx)
  local done = false
  require("src.core.game3.audio").playSe(constants():require("songs", "SE_UNLOCK"))
  local step = Story.slideDoorsTask(Rse.specialVar(ctx, 0x8004), setMetatile, constants(), drawWholeMap)
  require("src.core.game3.task").spawn(function()
    if step() then done = true; return true end
    return false
  end)
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  return false
end
B.PetalburgGymOpenDoorsInstantly = function(ctx)
  Story.petalburgSetDoorMetatiles(Rse.specialVar(ctx, 0x8004), Story.slidingDoorMetatile(constants(), 4), setMetatile)
  drawWholeMap()
  return false
end

-- pokeruby/src/rotating_gate.c:963
B.RotatingGate_InitPuzzle = function()
  require("src.core.game3.rotating_gate").initPuzzle()
  return false
end
B.RotatingGate_InitPuzzleAndGraphics = function()
  require("src.core.game3.rotating_gate").initPuzzleAndGraphics()
  return false
end

-- pokeruby/src/field_tasks.c:471
B.SetSootopolisGymCrackedIceMetatiles = function()
  require("src.core.game3.step_callbacks_rse").setSootopolisGymCrackedIceMetatiles()
  return false
end

-- pokeruby/src/field_specials.c:1597
B.SpawnCameraDummy = function()
  local Runtime = package.loaded["src.core.game3.runtime"]
  assert(require("src.core.game3.camera_object").spawn(Runtime and Runtime._game, {
    graphicsId = 7, movementType = 8, facing = "down",
  }), "RS camera dummy did not spawn")
  return false
end
B.RemoveCameraDummy = function()
  local Runtime = package.loaded["src.core.game3.runtime"]
  require("src.core.game3.camera_object").remove(Runtime and Runtime._game)
  return false
end

-- pokeruby/src/berry.c:1042
B.IsEnigmaBerryValid = function()
  local sess = Rse.session()
  local raw = sess and sess.enigmaBerryNativeBytes
  if type(raw) ~= "table" or #raw < 1328 then return false, 0 end
  local function byte(off)
    local value = tonumber(raw[off + 1])
    if not value or value < 0 or value > 255 or value % 1 ~= 0 then return nil end
    return value
  end
  if not byte(20) or byte(20) == 0 or not byte(10) or byte(10) == 0 then return false, 0 end
  local checksum = 0
  for off = 0, 1323 do
    if off < 12 or off >= 20 then
      local value = byte(off)
      if value == nil then return false, 0 end
      checksum = checksum + value
    end
  end
  local expected = 0
  for off = 1324, 1327 do
    local value = byte(off)
    if value == nil then return false, 0 end
    expected = expected + value * 256 ^ (off - 1324)
  end
  return false, checksum == expected and 1 or 0
end

return Gym
