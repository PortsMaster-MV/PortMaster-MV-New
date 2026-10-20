-- Warp / door / fade sequencing helpers for game3 field.

local ModRuntime = require("src.mods.Runtime")
local FieldModules = require("src.core.game3.field_modules")

local Warp = {}

Warp._pending = nil
Warp._busy = false

function Warp.isBusy()
  return Warp._busy == true
end

local function sameDestination(map, x, y) return map, x, y end

local function mapTypeOf(game, mapId)
  local def = game and game.data and game.data.maps and game.data.maps[mapId]
  if not def then
    local okD, Dataset = pcall(require, "src.core.game3.dataset")
    def = okD and Dataset and Dataset.map and Dataset.map(mapId)
  end
  return def and def.mapType
end

-- pokefirered/src/overworld.c:639 UpdateEscapeWarp
local function updateEscapeWarp(game, fromMap, destMap, srcX, srcY)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  if not session then return false end
  local curMap = fromMap or session.map
  if type(curMap) ~= "string" then return false end
  local FieldMoves = require("src.core.game3.field_moves")
  if not FieldMoves.isOutdoors(mapTypeOf(game, curMap)) then return false end
  if FieldMoves.isOutdoors(mapTypeOf(game, destMap)) then return false end
  local esc = require("src.core.game3.profile").forSession(session).map
  esc = esc and esc.escapeWarp
  if not esc then
    local okC, MapCatalog = pcall(require, "src.import.gba.map_catalog")
    local forest = okC and MapCatalog and MapCatalog.pretToEngine
      and MapCatalog.pretToEngine("ViridianForest")
    if curMap == (forest or "FR_VIRIDIAN_FOREST") then return false end
  end
  local x, y = tonumber(srcX), tonumber(srcY)
  if not (x and y) then return false end
  local Player = package.loaded["src.core.game3.player"]
  local delta = (Player and Player.facing ~= "down") and 1 or 0
  -- pokeemerald/src/overworld.c:682
  if esc then delta = esc.delta end
  -- pokefirered/src/overworld.c:651 SetEscapeWarp
  session.escapeWarp = { map = curMap, warpId = 255, x = x, y = y + delta }
  return true
end

local function announce(game, destMap, destX, destY, kind, srcX, srcY)
  local Map = package.loaded["src.core.game3.map"]
  local fromMap = Map and Map.current
  local warp = { kind = kind, map = destMap, x = destX, y = destY }
  if ModRuntime.wantsHook("warp.destination") then
    local m, nx, ny = ModRuntime.call("warp.destination", sameDestination, destMap, destX, destY,
      { warp = warp, lastMap = fromMap, data = game and game.data })
    if m then
      destMap, destX, destY = m, tonumber(nx) or destX, tonumber(ny) or destY
    end
  end
  if ModRuntime.wants("player.warped") then
    ModRuntime.emit("player.warped", { fromMap = fromMap, toMap = destMap,
      x = destX, y = destY, warp = warp })
  end
  -- pokefirered/src/field_control_avatar.c:982 SetupWarp
  updateEscapeWarp(game, fromMap, destMap, srcX, srcY)
  local Collision = package.loaded["src.core.game3.collision"]
  if Collision and Collision.noteDynamicWarpEntry then
    Collision.noteDynamicWarpEntry(game, destMap, destX, destY, srcX, srcY)
  end
  return destMap, destX, destY
end

--- WarpFadeOutScreen / WarpFadeInScreen (pokefirered/src/field_fadetransition.c:95
--- and :54). Every warp-out in pret routes through WarpFadeOutScreen, so the
--- colour rule is shared: a changed map section whose destination owns a cave
--- preview screen forces black, otherwise MapTransitionIsEnter decides, which is
--- true only when a warp drops the player into a MAP_TYPE_UNDERGROUND map from
--- somewhere above ground (fldeff_flash.c sTransitionTypes). The fade-in mirrors
--- it with MapTransitionIsExit, true only when leaving MAP_TYPE_UNDERGROUND.
--- Fade is passed in because warp.lua loads src.ui.game3.fade lazily per sequence.
local MAP_TYPE_UNDERGROUND = 4

local function sectionAndType(game, mapId)
  local def = game and game.data and game.data.maps and game.data.maps[mapId]
  if not def then return nil, 0 end
  return tonumber(def.regionMapSectionId), tonumber(def.mapType) or 0
end

local function warpFadeModes(Fade, game, destMap)
  local MODE = (Fade and Fade.MODE) or {}
  local toBlack, toWhite = MODE.TO_BLACK or 1, MODE.TO_WHITE or 3
  local fromBlack, fromWhite = MODE.FROM_BLACK or 0, MODE.FROM_WHITE or 2
  local Map = package.loaded["src.core.game3.map"]
  local fromSec, fromType = sectionAndType(game, Map and Map.current)
  local toSec, toType = sectionAndType(game, destMap)
  if fromSec and toSec and fromSec ~= toSec and FieldModules.enabled("mapPreview") then
    local ok, MapPreviewScreen = pcall(require, "src.ui.game3.map_preview_screen")
    if ok and MapPreviewScreen and MapPreviewScreen.has then
      local okT, MapPreviewExtract = pcall(require, "src.import.gba.map_preview_extract")
      if okT and MapPreviewExtract and MapPreviewScreen.has(toSec, MapPreviewExtract.TYPE_CAVE) then
        return toBlack, fromBlack
      end
    end
  end
  local enter = fromType ~= toType and toType == MAP_TYPE_UNDERGROUND
  local exit = fromType ~= toType and fromType == MAP_TYPE_UNDERGROUND
  return (enter and toWhite or toBlack), (exit and fromWhite or fromBlack)
end
Warp.fadeModes = warpFadeModes

-- src/fldeff_flash.c:237
function Warp.mapTransition(game, destMap, load)
  local function cont()
    load()
    -- src/map_preview_screen.c:439
    local MapPreviewScreen = package.loaded["src.ui.game3.map_preview_screen"]
    local Field = package.loaded["src.core.game3.field"]
    if MapPreviewScreen and MapPreviewScreen.isForestActive() and Field and Field.lock then
      Field.lock()
    end
  end
  local Map = package.loaded["src.core.game3.map"]
  local fromSec, fromType = sectionAndType(game, Map and Map.current)
  local toSec, toType = sectionAndType(game, destMap)
  local Fade = require("src.ui.game3.fade")
  local preview = FieldModules.enabled("mapPreview")
  local MapPreviewScreen = preview and require("src.ui.game3.map_preview_screen")
  local MapPreviewExtract = preview and require("src.import.gba.map_preview_extract")
  if preview and fromSec and toSec and fromSec ~= toSec
      and MapPreviewScreen.has(toSec, MapPreviewExtract.TYPE_CAVE)
      and MapPreviewScreen.runCave(toSec, cont) then
    Fade.clear()
    return
  end
  -- src/fldeff_flash.c:41
  if fromType ~= toType and fromType ~= 0 and toType ~= 0
      and (toType == MAP_TYPE_UNDERGROUND or fromType == MAP_TYPE_UNDERGROUND) then
    Fade.clear()
    require("src.ui.game3.cave_transition").start(
      toType == MAP_TYPE_UNDERGROUND and "enter" or "exit", cont)
    return
  end
  cont()
end

-- src/field_fadetransition.c:451
local function releaseField(Field)
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return end
  local MapPreviewScreen = package.loaded["src.ui.game3.map_preview_screen"]
  if MapPreviewScreen and MapPreviewScreen.isForestActive and MapPreviewScreen.isForestActive() then
    return
  end
  if Field and Field.unlock then Field.unlock() end
end
Warp.releaseField = releaseField

local function isRse()
  local ok, row = pcall(function() return require("src.core.game3.profile").forSession(nil) end)
  return ok and type(row) == "table" and row.family == "rse"
end

-- pokeruby/src/field_fadetransition.c:376
-- pokeemerald/src/field_screen_effect.c:483
local function ordinaryFadeOut(Fade, game, destMap, destX, destY, toMode, playDeparture, done)
  if not isRse() then
    if playDeparture then playDeparture() end
    Fade.begin(toMode, 1, done)
    return
  end
  local Audio = require("src.core.game3.audio")
  if Audio.tryFadeOutOldMapMusic then Audio.tryFadeOutOldMapMusic(destMap, destX, destY) end
  local faded = false
  Fade.begin(toMode, 1, function() faded = true end)
  local E = require("src.core.game3.weather").rseEngine()
  if E then E.playRainStoppingSoundEffect() end
  if playDeparture then playDeparture() end
  require("src.core.game3.task").spawn(function()
    if not faded or Audio._fadeOut then return false end
    done()
    return true
  end)
end

--- Complete door entrance sequence (walking UP into a building)
function Warp.startDoorEntrance(mod, game, destMap, destX, destY, doorX, doorY)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "door", doorX, doorY)
  Warp._busy = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end

  local Doors = require("src.core.game3.doors")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local curMap = (game and game.currentMap) or destMap
  local sound = Doors.getSoundForWarp(curMap, doorX, doorY, destMap, true)
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  -- Step 1: Animate door open (Frame 0 -> 1 -> 2)
  Doors.open(curMap, doorX, doorY, { sound = sound, destMap = destMap }, function()
    -- Step 2: Door is fully open. Walk player 1 step UP into the doorway.
    Player.forceStep("up", function()
      -- Step 3: Player arrived at (doorX, doorY). Immediately hide player sprite!
      Player.setVisible(false)

      -- Step 4: Short beat, then door animates closed (Frame 2 -> 1 -> 0)
      Doors.closeAfterDelay(curMap, doorX, doorY, 8, { sound = sound, playSound = false }, function()
        -- Step 5: Screen fades to black
        ordinaryFadeOut(Fade, game, destMap, destX, destY, toMode, nil, function() Warp.mapTransition(game, destMap, function()
          -- Step 6: Inside black, load the indoor map
          local Map = require("src.core.game3.map")
          Map.load(mod, game, destMap, {
            x = destX,
            y = destY,
            facing = "up",
            depth1Connections = true,
          })
          Player.setVisible(true)
          Doors.reset()

          -- Step 7: Fade screen back in from black inside the building
          Fade.begin(fromMode, 1, function()
            Warp._busy = false
            releaseField(Field)
          end)
        end) end)
      end)
    end)
  end)
  return true
end

local warpExitArrival

--- Complete door exit sequence (walking DOWN off exit mat out to town)
function Warp.startDoorExit(mod, game, destMap, destX, destY, exitX, exitY)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "exit_door", exitX, exitY)
  Warp._busy = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end

  local Doors = require("src.core.game3.doors")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  ordinaryFadeOut(Fade, game, destMap, destX, destY, toMode, function()
    if Audio and Audio.playSe then pcall(function() Audio.playSe(Doors.SOUND_EXIT) end) end
  end, function() Warp.mapTransition(game, destMap, function()
    local Map = require("src.core.game3.map")
    Map.load(mod, game, destMap, {
      x = destX,
      y = destY,
      facing = "down",
      depth1Connections = true,
    })
    Player.setVisible(true)
    Doors.reset()
    -- pokefirered/src/field_fadetransition.c:242
    warpExitArrival(game, destMap, destX, destY, fromMode, function()
      Warp._busy = false
      releaseField(Field)
    end)
  end) end)
  return true
end

--- Complete escalator warp sequence (PokéCenter 2F, Celadon Dept Store)
function Warp.isEscalatorActive()
  return Warp._isEscalatorActive and true or false
end

function Warp.startEscalator(mod, game, destMap, destX, destY, dir, approachDir, escX, escY)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "escalator", escX, escY)
  Warp._busy = true
  Warp._isEscalatorActive = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end

  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  local Map = require("src.core.game3.map")
  local Task = require("src.core.game3.task")
  local SpecialAnim = require("src.core.game3.special_field_anim")

  local goingUp = (dir ~= "down")
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  -- GBA pret trig offsets for escalator (field_effect.c)
  local function getOffsets(amp, isGoingUp, isLanding)
    local x = -amp
    local y = 0
    if isGoingUp then
      if not isLanding then
        -- Going UP departing (1F): moves left & UP into ceiling (0 -> -8)
        y = -math.floor(amp * 8 / 16)
      else
        -- Going UP arriving (2F): starts below floor (+8) and glides right & UP into floor (+8 -> 0)
        y = math.floor(amp * 8 / 16)
      end
    else
      if not isLanding then
        -- Going DOWN departing (2F): moves left & DOWN into lower floor (0 -> +8)
        y = math.floor(amp * 8 / 16)
      else
        -- Going DOWN arriving (1F): starts above floor (-8) and glides right & DOWN into floor (-8 -> 0)
        y = -math.floor(amp * 8 / 16)
      end
    end
    return x, y
  end

  local function doWarpIn()
    -- Destination map loaded at (destX, destY)
    Player.facing = "right"
    Player.setVisible(true)

    -- Initial position: 16px to the left on destination escalator
    local initX, initY = getOffsets(16, goingUp, true)
    Player.spriteXOffset = initX
    Player.spriteYOffset = initY

    local destLayout = Map._def and Map._def.midLayout
    SpecialAnim.startEscalator(destLayout, destX, destY, goingUp)

    Fade.begin(fromMode, 1, function() end)

    Task.spawn(function(t)
      -- 16 amp steps over 32 frames (every 2 frames advances 1 amp)
      local amp = math.max(0, 16 - math.floor(t.frames / 2))
      local xOff, yOff = getOffsets(amp, goingUp, true)
      Player.spriteXOffset = xOff
      Player.spriteYOffset = yOff

      if amp <= 0 then
        Player.spriteXOffset = 0
        Player.spriteYOffset = 0
        SpecialAnim.stopEscalator()

        -- In FRLG: Player takes 1 normal walk step EAST (DIR_EAST) off the escalator
        Player.forceStep("right", function()
          Warp._busy = false
          Warp._isEscalatorActive = false
          releaseField(Field)
        end)
        return true
      end
      return false
    end)
  end

  local function doRideAndTransition()
    if Audio and Audio.playSe then
      pcall(function() Audio.playSe(SE.SE_ESCALATOR or 73) end)
    end

    -- Keep current facing while riding out
    Player.facing = approachDir or "left"

    local curLayout = Map._def and Map._def.midLayout
    SpecialAnim.startEscalator(curLayout, Player.cellX, Player.cellY, goingUp)

    local fadeStarted = false
    local fadeDone = false

    Task.spawn(function(t)
      -- 16 amp steps over 32 frames (every 2 frames advances 1 amp)
      local amp = math.min(16, math.floor(t.frames / 2))
      local xOff, yOff = getOffsets(amp, goingUp, false)
      Player.spriteXOffset = xOff
      Player.spriteYOffset = yOff

      -- In FRLG: when task->data[2] > 3 (after ~8 frames), begin fade out
      if t.frames >= 8 and not fadeStarted then
        fadeStarted = true
        Fade.begin(toMode, 1, function()
          fadeDone = true
        end)
      end

      if amp >= 16 and fadeDone then
        SpecialAnim.stopEscalator()
        Player.spriteXOffset = 0
        Player.spriteYOffset = 0

        Warp.mapTransition(game, destMap, function()
          Map.load(mod, game, destMap, {
            x = destX,
            y = destY,
            facing = "right",
            depth1Connections = true,
          })

          doWarpIn()
        end)
        return true
      end
      return false
    end)
  end

  -- If player is standing adjacent to the escalator, step onto it first
  if approachDir and (Player.cellX ~= escX or Player.cellY ~= escY) then
    Player.forceStep(approachDir, function()
      doRideAndTransition()
    end)
  else
    doRideAndTransition()
  end

  return true
end

-- pokefirered/src/field_fadetransition.c:922
local function exitStairsArrival(game, destX, destY, fromMode, finish)
  local Collision = require("src.core.game3.collision")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Task = require("src.core.game3.task")
  local destBeh = Collision.behavior(destX, destY)
  local facing = Collision.stairArrivalFacing(destBeh)
  if facing then
    Player.facing = facing
    Player.syncSavePosition(game)
  end
  local speedX, speedY = Collision.stairSpeeds(destBeh)
  local offX, offY = speedX * 16, speedY * 16
  local timer = 16
  speedX, speedY = -speedX, -speedY
  Player.walkInPlace = true
  Player.walkInPlaceFast = true
  Player.spriteXOffset = math.floor(offX / 32)
  Player.spriteYOffset = math.floor(offY / 32)

  Fade.begin(fromMode, 1, function() end)

  Task.spawn(function()
    if timer > 0 then
      offX = offX + speedX
      offY = offY + speedY
      Player.spriteXOffset = math.floor(offX / 32)
      Player.spriteYOffset = math.floor(offY / 32)
      timer = timer - 1
      return false
    end
    Player.spriteXOffset = 0
    Player.spriteYOffset = 0
    Player.walkInPlace = false
    Player.walkInPlaceFast = false
    finish()
    return true
  end)
end

-- pokefirered/src/field_fadetransition.c:794
function Warp.startStairWarp(mod, game, destMap, destX, destY, behavior)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "stairs")
  Warp._busy = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end

  local Collision = require("src.core.game3.collision")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  local Map = require("src.core.game3.map")
  local Task = require("src.core.game3.task")
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  local function finish()
    Warp._busy = false
    releaseField(Field)
  end

  local function exitStairs()
    exitStairsArrival(game, destX, destY, fromMode, finish)
  end

  local speedX, speedY = Collision.stairSpeeds(behavior)
  local offX, offY, timer = 0, 0, 0
  local fadeStarted, fadeDone = false, false

  if Audio and Audio.playSe then
    pcall(function() Audio.playSe(SE.SE_EXIT or 9) end)
  end
  Player.walkInPlace = true
  Player.walkInPlaceFast = false

  -- pokefirered/src/field_fadetransition.c:846
  Task.spawn(function()
    if speedY > 0 or timer > 6 then offY = offY + speedY end
    offX = offX + speedX
    timer = timer + 1
    Player.spriteXOffset = math.floor(offX / 32)
    Player.spriteYOffset = math.floor(offY / 32)

    if timer >= 12 and not fadeStarted then
      fadeStarted = true
      Fade.begin(toMode, 1, function() fadeDone = true end)
    end

    if fadeDone then
      Player.spriteXOffset = 0
      Player.spriteYOffset = 0
      Player.walkInPlace = false
      Warp.mapTransition(game, destMap, function()
        Map.load(mod, game, destMap, {
          x = destX,
          y = destY,
          facing = Player.facing,
          depth1Connections = true,
        })
        Player.setVisible(true)
        exitStairs()
      end)
      return true
    end
    return false
  end)

  return true
end

--- Complete teleport spin sequence (Silph Co, Sabrina's Gym warp pads)
function Warp.startTeleport(mod, game, destMap, destX, destY, srcX, srcY)
  if Warp._busy then return false end
  if Warp.rseStepWarp then
    local special = Warp.rseStepWarp(mod, game, destMap, destX, destY, srcX, srcY)
    if special ~= nil then return special end
  end
  destMap, destX, destY = announce(game, destMap, destX, destY, "teleport", srcX, srcY)
  Warp._busy = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end

  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")

  if Audio and Audio.playSe then
    pcall(function() Audio.playSe(SE.SE_WARP_IN or 39) end)
  end

  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  Fade.begin(toMode, 1, function() Warp.mapTransition(game, destMap, function()
    local Map = require("src.core.game3.map")
    Map.load(mod, game, destMap, {
      x = destX,
      y = destY,
      facing = "down",
      depth1Connections = true,
    })
    Player.setVisible(true)

    if Audio and Audio.playSe then
      pcall(function() Audio.playSe(SE.SE_WARP_OUT or 40) end)
    end

    Fade.begin(fromMode, 1, function()
      Warp._busy = false
      releaseField(Field)
    end)
  end) end)
  return true
end

-- pokefirered/src/field_effect.c:2134 sSpinDirections
local SPIN_NEXT = { down = "left", up = "right", left = "up", right = "down" }

-- pokefirered/src/field_effect.c:2143 SpinObjectEvent
local function spinStep(Player, s)
  if s.delay ~= 0 then
    s.delay = s.delay - 1
    if s.delay ~= 0 then return Player.facing end
  end
  Player.facing = SPIN_NEXT[Player.facing] or "down"
  if s.turns < 12 then s.turns = s.turns + 1 end
  s.delay = bit.rshift(12, s.turns)
  return Player.facing
end

-- pokefirered/src/field_effect.c:2086 StartEscapeRopeFieldEffect
function Warp.startEscapeRope(game, destMap, destX, destY, load)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "escape_rope")
  Warp._busy = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end

  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  local Task = require("src.core.game3.task")
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  local function warpIn()
    local spin = { delay = 0, turns = 0 }
    local timer, offY, moving, spinEnded = 0, -88, true, false
    local originalDir = Player.facing
    local dir = originalDir
    Player.spriteYOffset = offY
    -- pokefirered/src/field_effect.c:2290 EscapeRopeWarpInEffect_Init
    Audio.playSe(SE.SE_WARP_OUT)
    Task.spawn(function()
      -- pokefirered/src/field_effect.c:2223 WarpInObjectEventDownwards
      if moving then
        offY = offY + 4
        if offY >= 0 then
          offY = 0
          moving = false
          Audio.playSe(SE.SE_CLICK)
        end
        Player.spriteYOffset = offY
      end
      Player.setVisible(true)
      if timer < 8 then
        timer = timer + 1
      elseif not spinEnded then
        timer = timer + 1
        dir = spinStep(Player, spin)
        if timer >= 50 and dir == originalDir then spinEnded = true end
      end
      if not moving and dir == originalDir then
        Player.spriteYOffset = 0
        Warp._busy = false
        releaseField(Field)
        return true
      end
      return false
    end)
  end

  -- pokefirered/src/field_effect.c:2106 EscapeRopeWarpOutEffect_Spin
  local spin = { delay = 0, turns = 0 }
  local timer, offY, offscreen, faded = 0, 0, false, false
  Task.spawn(function()
    spinStep(Player, spin)
    if timer < 60 then
      timer = timer + 1
      if timer == 20 then Audio.playSe(SE.SE_WARP_IN) end
    elseif not offscreen then
      -- pokefirered/src/field_effect.c:2158 WarpOutObjectEventUpwards
      offY = offY - 8
      Player.spriteYOffset = offY
      if offY <= -88 then
        offscreen = true
        Fade.begin(toMode, 1, function() faded = true end)
      end
    end
    if not faded then return false end
    Player.spriteYOffset = 0
    Warp.mapTransition(game, destMap, function()
      load(destMap, destX, destY)
      -- pokefirered/src/field_effect.c:2269 FieldCallback_EscapeRopeExit
      Player.setVisible(false)
      Fade.begin(fromMode, 1, warpIn)
    end)
    return true
  end)
  return true
end

-- pokefirered/src/overworld.c:898 MetatileBehavior_IsSurfableInSeafoamIslands
local function seafoamSurfLanding(destMap, x, y)
  local up = string.upper(tostring(destMap or ""))
  if not (up:find("SEAFOAM_ISLANDS_B3F") or up:find("SEAFOAM_ISLANDS_B4F")) then
    return false
  end
  local Collision = require("src.core.game3.collision")
  return Collision.isSurfable ~= nil
    and Collision.isSurfable(Collision.behavior(x, y)) == true
end

-- pokefirered/src/field_effect.c:1285
local function seafoamSurfArrival(Player)
  local Flags = require("src.core.game3.scripting.flags")
  local Space = require("src.core.game3.scripting.space")
  Flags.setVar(Space.store, nil, "VAR_TEMP_1", 1)
  Player.surfing = true
end

-- pokefirered/src/field_effect.c:1200
local FALL_START_Y = -112

--- Complete fall hole sequence (Mt. Moon, Seafoam drop holes)
-- pokefirered/data/scripts/hole.inc:23 EventScript_DoFallWarp
function Warp.startFall(mod, game, destMap, destX, destY, srcX, srcY, opts)
  if Warp._busy then return false end
  opts = opts or {}
  destMap, destX, destY = announce(game, destMap, destX, destY, "fall", srcX, srcY)
  Warp._busy = true

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end
  -- pokefirered/src/field_effect.c:1155 FieldCB_FallWarpExit
  if Field then Field._fallWarp = true end

  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  local Task = require("src.core.game3.task")

  local toMode, fromMode = warpFadeModes(Fade, game, destMap)

  local function playSe(id)
    if Audio and Audio.playSe then
      pcall(function() Audio.playSe(id) end)
    end
  end

  local function finish()
    Warp._busy = false
    -- pokefirered/src/field_effect.c:1274 FallWarpEffect_7
    if Field then Field._fallWarp = false end
    releaseField(Field)
  end

  -- pokefirered/src/field_effect.c:1215 FallWarpEffect_4
  local function dropIn()
    local y2 = FALL_START_Y
    local speed, travelled = 1, 0
    Player.facing = "down"
    Player.spriteYOffset = y2
    Player.setVisible(true)
    playSe(SE.SE_FALL or 37)
    Task.spawn(function()
      y2 = y2 + speed
      if speed < 8 then
        travelled = travelled + speed
        if travelled % 16 ~= 0 then speed = speed * 2 end
      end
      if y2 >= 0 then
        Player.spriteYOffset = 0
        playSe(SE.SE_M_STRENGTH or 207)
        -- pokefirered/src/field_effect.c:1249 FallWarpEffect_5
        require("src.core.game3.field_effects").startLandingShake(finish)
        if seafoamSurfLanding(destMap, destX, destY) then
          seafoamSurfArrival(Player)
        end
        Player.syncSavePosition(game)
        return true
      end
      Player.spriteYOffset = y2
      return false
    end)
  end

  -- pokefirered/data/scripts/hole.inc:24
  -- pokefirered/src/scrcmd.c:773
  local prologue = opts.prologue ~= false
  Task.spawn(function(t)
    if prologue and t.frames == 20 then
      Player.setVisible(false)
      playSe(SE.SE_FALL or 37)
    end
    if prologue and t.frames < 80 then return false end
    Fade.begin(toMode, 1, function() Warp.mapTransition(game, destMap, function()
      local Map = require("src.core.game3.map")
      Map.load(mod, game, destMap, {
        x = destX,
        y = destY,
        facing = "down",
        depth1Connections = true,
      })
      Player.setVisible(false)
      Player.spriteYOffset = FALL_START_Y
      Fade.begin(fromMode, 1, function()
        dropIn()
      end)
    end) end)
    return true
  end)
  return true
end

local PLAYER_SCREEN_Y = 72

-- pokefirered/src/field_player_avatar.c:2143
local function teleportRotate(Player, s)
  if s.rot < 8 then
    s.rot = s.rot + 1
    if s.rot < 8 then return Player.facing end
  end
  Player.facing = SPIN_NEXT[Player.facing] or "down"
  s.rot = 0
  return Player.facing
end

-- pokefirered/src/field_player_avatar.c:2030
local function teleportWarpOutAnim(Player, onDone)
  local Task = require("src.core.game3.task")
  local s = { rot = 0 }
  local deltaY, ydef = 1, PLAYER_SCREEN_Y * 16
  Task.spawn(function()
    teleportRotate(Player, s)
    ydef = ydef - deltaY
    deltaY = deltaY + 3
    local y = math.floor(ydef / 16)
    Player.spriteYOffset = y - PLAYER_SCREEN_Y
    if y < -32 then
      onDone()
      return true
    end
    return false
  end)
end

-- pokefirered/src/field_player_avatar.c:2082
local function teleportWarpInAnim(Player, finalFacing, onDone)
  local Task = require("src.core.game3.task")
  local s = { rot = 0 }
  local state, landing = 1, 0
  local deltaY, ydef = 116, -32 * 16
  Player.facing = SPIN_NEXT[finalFacing] or "left"
  Player.spriteYOffset = math.floor(ydef / 16) - PLAYER_SCREEN_Y
  Player.setVisible(true)
  Task.spawn(function()
    if state == 1 then
      teleportRotate(Player, s)
      ydef = ydef + deltaY
      deltaY = math.max(4, deltaY - 3)
      local y = math.floor(ydef / 16)
      if y >= PLAYER_SCREEN_Y then
        Player.spriteYOffset = 0
        state = 2
      else
        Player.spriteYOffset = y - PLAYER_SCREEN_Y
      end
    elseif state == 2 then
      teleportRotate(Player, s)
      landing = landing + 1
      if landing > 8 then state = 3 end
    elseif teleportRotate(Player, s) == finalFacing then
      onDone()
      return true
    end
    return false
  end)
end

local function mapMusicOf(game, mapId)
  local def = game and game.data and game.data.maps and game.data.maps[mapId]
  local music = def and def.music
  if not music then
    local Audio = package.loaded["src.core.game3.audio"]
    local idx = Audio and Audio._pack and Audio._pack.index and Audio._pack.index.mapSongs
    music = idx and idx[mapId]
  end
  return tonumber(music)
end

-- pokefirered/src/overworld.c:1112
local function tryFadeOutOldMapMusic(game, destMap, destX, destY)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local Flags = require("src.core.game3.scripting.flags")
  if Space and Flags.getFlag(Space.store, nil, "FLAG_DONT_TRANSITION_MUSIC") then return 0 end
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local rseFrames = Audio.tryFadeOutOldMapMusic and Audio.tryFadeOutOldMapMusic(destMap, destX, destY)
  if rseFrames then return rseFrames end
  -- pokefirered/src/sound.c:124
  local cur = not Audio._fadeOut and Audio._currentSong and tonumber(Audio._currentSong.id) or 0
  if mapMusicOf(game, destMap) == cur then return 0 end
  -- pokefirered/src/overworld.c:1103
  local mt = tonumber(mapTypeOf(game, destMap)) or 0
  local speed = (mt == 8 or mt == 9) and 2 or 4
  if not (Audio and Audio.fadeOutBgm) then return 0 end
  Audio.fadeOutBgm(speed)
  return 16 * speed
end

-- pokefirered/src/field_fadetransition.c:242
function warpExitArrival(game, destMap, x, y, fromMode, finish)
  local Collision = require("src.core.game3.collision")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Task = require("src.core.game3.task")
  local beh = Collision.behavior(x, y)
  if Collision.isWarpDoor(beh) then
    -- pokefirered/src/field_fadetransition.c:335
    local Doors = require("src.core.game3.doors")
    Player.facing = "down"
    Player.setVisible(false)
    Fade.begin(fromMode, 4, function() end)
    local t, stepT, stepDone, closed = 0, nil, false, false
    Task.spawn(function()
      t = t + 1
      if t == 25 then
        Doors.open(destMap, x, y, { playSound = not isRse() }, function()
          Player.setVisible(true)
          stepT = 0
          if not Player.forceStep("down", function() stepDone = true end) then stepDone = true end
        end)
      end
      if stepT then
        stepT = stepT + 1
        -- pokefirered/src/field_fadetransition.c:363
        if stepT == 14 then
          Doors.close(destMap, x, y, { playSound = false }, function() closed = true end)
        end
      end
      if closed and stepDone and not Fade.isActive() then
        finish()
        return true
      end
      return false
    end)
    return
  end
  if Collision.isNonAnimDoor(beh) then
    -- pokefirered/src/field_fadetransition.c:405
    Player.setVisible(false)
    Fade.begin(fromMode, 1, function()
      Player.setVisible(true)
      if not Player.forceStep(Player.facing, finish) then finish() end
    end)
    return
  end
  if Collision.stairArrivalFacing(beh) then
    exitStairsArrival(game, x, y, fromMode, finish)
    return
  end
  -- pokefirered/src/field_fadetransition.c:441
  Fade.begin(fromMode, 1, finish)
end

-- pokefirered/src/scrcmd.c:719
local SCRIPTED_KINDS = {
  -- pokefirered/src/field_fadetransition.c:535
  warp = { se = "SE_EXIT", music = true, fadeOut = true },
  -- pokefirered/src/field_fadetransition.c:546
  warpsilent = { music = true, fadeOut = true },
  -- pokefirered/src/field_fadetransition.c:564
  warpdoor = { door = true, music = true, fadeOut = true },
  -- pokefirered/src/field_fadetransition.c:609
  warpteleport = { spinOut = true, music = true, fadeOut = true, spinIn = true },
  -- pokefirered/src/field_fadetransition.c:571
  warpspinenter = { spinIn = true },
  -- pokefirered/src/seagallop.c:316
  seagallop = { fadeOut = true },
  -- pokeemerald/src/field_screen_effect.c:549 DoTeleportTileWarp
  rse_teleport_tile = { se = "SE_WARP_IN", music = true, fadeOut = true, spinIn = true },
  -- pokeemerald/src/field_screen_effect.c:559 DoMossdeepGymWarp
  rse_mossdeep_gym = { se = "SE_WARP_IN", music = true, fadeOut = true, arriveSe = "SE_WARP_OUT" },
  -- pokeemerald/src/field_screen_effect.c:1064 DoSpinExitWarp
  rse_spin_exit = { spinOut = true, music = true, fadeOut = true },
  -- pokeemerald/src/field_screen_effect.c:571 DoPortholeWarp
  rse_porthole_enter = { fadeOut = true, hidePlayer = true },
  -- pokeemerald/src/scrcmd.c:823
  warpmossdeepgym = { se = "SE_WARP_IN", music = true, fadeOut = true, arriveSe = "SE_WARP_OUT" },
  -- pokeemerald/src/field_screen_effect.c:505 DoWhiteFadeWarp
  warpwhitefade = { music = true, fadeOut = true, white = true },
}
Warp.SCRIPTED_KINDS = SCRIPTED_KINDS

function Warp.scripted(mod, game, kind, destMap, destX, destY, facing, onDone)
  local spec = SCRIPTED_KINDS[kind or "warp"] or SCRIPTED_KINDS.warp
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  local Doors = require("src.core.game3.doors")
  local Task = require("src.core.game3.task")
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)
  if spec.white then toMode, fromMode = Fade.MODE.TO_WHITE, Fade.MODE.FROM_WHITE end
  -- pokefirered/src/field_player_avatar.c:2017
  local savedFacing = Player.facing or "down"
  Warp._busy = true

  local function playSe(id)
    if id and Audio and Audio.playSe then pcall(function() Audio.playSe(id) end) end
  end

  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")

  local function finish()
    Warp._busy = false
    Field._fieldCallback = false
    if onDone then onDone() end
  end

  local function arrive()
    -- pokefirered/src/field_fadetransition.c:542
    Field._fieldCallback = true
    Warp.mapTransition(game, destMap, function()
      -- pokefirered/src/overworld.c:2144
      Player.setVisible(true)
      Player.spriteYOffset = 0
      local Map = require("src.core.game3.map")
      local arrivalFacing = facing or savedFacing
      if not spec.spinIn then
        -- pokefirered/src/scrcmd.c:729
        arrivalFacing = require("src.core.game3.collision").destArrivalFacing(game, destMap, destX, destY, "down")
      end
      Map.load(mod, game, destMap, {
        x = destX,
        y = destY,
        facing = arrivalFacing,
        depth1Connections = true,
      })
      if spec.hidePlayer then Player.setVisible(false) end
      Doors.reset()
      -- pokeemerald/src/field_screen_effect.c:307
      if spec.arriveSe then playSe(SE[spec.arriveSe]) end
      if spec.spinIn then
        -- pokefirered/src/field_fadetransition.c:307
        local faded, landed = false, false
        Fade.begin(fromMode, 1, function() faded = true end)
        playSe(SE.SE_WARP_OUT)
        teleportWarpInAnim(Player, savedFacing, function() landed = true end)
        Task.spawn(function()
          if not (faded and landed) then return false end
          finish()
          return true
        end)
        return
      end
      warpExitArrival(game, destMap, destX, destY, fromMode, finish)
    end)
  end

  -- pokefirered/src/field_fadetransition.c:690
  local function fadeOut()
    local musicFrames = spec.music and tryFadeOutOldMapMusic(game, destMap, destX, destY) or 0
    local covered = not Fade.isActive() and (tonumber(Fade.t) or 0) >= 16
    local faded = covered or not spec.fadeOut
    if not faded then
      Fade.begin(toMode, 1, function() faded = true end)
    end
    if isRse() and (kind == nil or kind == "warp" or kind == "warpsilent" or kind == "warpdoor") then
      local E = require("src.core.game3.weather").rseEngine()
      if E then E.playRainStoppingSoundEffect() end
    end
    if spec.se then playSe(SE[spec.se]) end
    Task.spawn(function(t)
      if not faded then return false end
      if isRse() then
        if Audio._fadeOut then return false end
      elseif t.frames < musicFrames and Audio._fadeOut then
        return false
      end
      arrive()
      return true
    end)
  end

  if spec.door then
    -- pokefirered/src/field_fadetransition.c:743
    local Map = package.loaded["src.core.game3.map"]
    local curMap = Map and Map.current
    local px, py = tonumber(Player.cellX) or 0, tonumber(Player.cellY) or 0
    Doors.open(curMap, px, py - 1, { destMap = destMap }, function()
      local function closeDoor()
        Player.setVisible(false)
        Doors.close(curMap, px, py - 1, { playSound = false }, fadeOut)
      end
      if not Player.forceStep("up", closeDoor) then closeDoor() end
    end)
  elseif spec.spinOut then
    -- pokefirered/src/field_fadetransition.c:712
    playSe(SE.SE_WARP_IN)
    teleportWarpOutAnim(Player, fadeOut)
  elseif spec.fadeOut then
    fadeOut()
  else
    arrive()
  end
  return true
end

local function mbIs(beh, name)
  local id = require("src.core.game3.mb").id(name)
  return beh ~= nil and id ~= nil and beh == id
end

local function stepWarpScripted(mod, game, kind, destMap, destX, destY, srcX, srcY)
  destMap, destX, destY = announce(game, destMap, destX, destY, kind, srcX, srcY)
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end
  return Warp.scripted(mod, game, kind, destMap, destX, destY, nil, function()
    releaseField(Field)
  end)
end

local function ashEffect(name, cx, cy)
  local FieldEffects = require("src.core.game3.field_effects")
  local fn = FieldEffects[name]
  if type(fn) == "function" then pcall(fn, cx, cy) end
end

local function camPan(y)
  local FieldView = package.loaded["src.core.game3.field_view"]
  if FieldView and FieldView.setCameraPanning then FieldView.setCameraPanning(0, y) end
end

-- pokeemerald/src/field_effect.c:2143 StartLavaridgeGym1FWarp
function Warp.startLavaridge1F(mod, game, destMap, destX, destY, srcX, srcY)
  if Warp._busy then return false end
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Task = require("src.core.game3.task")
  local Audio = require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  Field.lock()
  if Field.holdInput then Field.holdInput(true) end
  local t = { state = "puffs", count = 0, wait = 0, puff = 0 }
  Task.spawn(function()
    Field.lock()
    if t.state == "puffs" then
      if t.wait > 0 then
        t.wait = t.wait - 1
        if t.wait == 0 then
          Player.walkInPlace = false
          Player.walkInPlaceFast = false
        end
        return false
      end
      -- pokeemerald/src/field_effect.c:2163
      if t.count > 3 then
        ashEffect("startAshPuff", Player.cellX, Player.cellY)
        t.state = "disappear"
        return false
      end
      t.count = t.count + 1
      Player.walkInPlace = true
      Player.walkInPlaceFast = true
      t.wait = 4
      Audio.playSe(SE.SE_LAVARIDGE_FALL_WARP)
      return false
    end
    t.puff = t.puff + 1
    -- pokeemerald/src/field_effect.c:2186
    if t.state == "disappear" and t.puff >= 12 then
      Player.setVisible(false)
      t.state = "fade"
    end
    -- pokeemerald/src/field_effect.c:2196
    if t.state == "fade" and t.puff >= 30 then
      if Field.holdInput then Field.holdInput(false) end
      Warp.startFall(mod, game, destMap, destX, destY, srcX, srcY, { prologue = false })
      return true
    end
    return false
  end)
  return true
end

-- pokeemerald/src/field_effect.c:1948 StartLavaridgeGymB1FWarp
function Warp.startLavaridgeB1F(mod, game, destMap, destX, destY, srcX, srcY)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "lavaridge_b1f", srcX, srcY)
  Warp._busy = true
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Task = require("src.core.game3.task")
  local Audio = require("src.core.game3.audio")
  local SE = require("src.core.game3.se_ids")
  local Fade = require("src.ui.game3.fade")
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)
  Field.lock()
  local d = { state = "shake", d1 = 1, d2 = 0, d3 = 1, d4 = 0, y2 = 0 }
  -- pokeemerald/src/field_effect.c:2062
  local function exitEffect()
    Player.setVisible(false)
    local e = { state = "wait", t = 0 }
    Fade.begin(fromMode, 1, function() e.state = "puff" end)
    Task.spawn(function()
      Field.lock()
      if e.state == "wait" then return false end
      if e.state == "puff" then
        ashEffect("startAshPuff", Player.cellX, Player.cellY)
        e.state = "popping"
        return false
      end
      if e.state == "popping" then
        e.t = e.t + 1
        -- pokeemerald/src/field_effect.c:2100
        if e.t >= 12 then
          Player.setVisible(true)
          Audio.playSe(SE.SE_M_DIG)
          Player.scriptJump("right", 1)
          e.state = "jump"
        end
        return false
      end
      if Player.moving or Player.jumping then return false end
      Warp._busy = false
      releaseField(Field)
      return true
    end)
  end
  Task.spawn(function()
    Field.lock()
    if d.state == "shake" then
      -- pokeemerald/src/field_effect.c:1970
      camPan(d.d1)
      d.d1 = -d.d1
      d.d2 = d.d2 + 1
      if d.d2 > 7 then
        d.d2 = 0
        d.state = "launch"
      end
      return false
    elseif d.state == "launch" then
      -- pokeemerald/src/field_effect.c:1983
      Player.spriteYOffset = 0
      d.d3 = 1
      ashEffect("startAshLaunch", Player.cellX, Player.cellY)
      Audio.playSe(SE.SE_M_EXPLOSION)
      d.state = "rise"
    end
    if d.state == "rise" then
      -- pokeemerald/src/field_effect.c:1997
      camPan(d.d1)
      d.d1 = -d.d1
      d.d2 = d.d2 + 1
      if d.d2 <= 17 then
        if d.d2 % 2 == 0 and d.d1 <= 3 then d.d1 = d.d1 * 2 end
      elseif math.floor(d.d2 / 4) % 2 == 0 and d.d1 > 0 then
        d.d1 = math.floor(d.d1 / 2)
      end
      if d.d2 > 6 then
        if d.y2 > -88 then
          d.y2 = d.y2 - d.d3
          if d.d3 <= 7 then d.d3 = d.d3 + 1 end
        else
          d.d4 = 1
        end
      end
      Player.spriteYOffset = d.y2
      if d.d1 == 0 and d.d4 ~= 0 then
        camPan(0)
        d.state = "fade"
        local musicFrames = tryFadeOutOldMapMusic(game, destMap, destX, destY)
        d.music = musicFrames
        d.faded = false
        Fade.begin(toMode, 1, function() d.faded = true end)
        d.t = 0
      end
      return false
    end
    if d.state == "fade" then
      d.t = d.t + 1
      if not d.faded or (d.t < (d.music or 0) and Audio._fadeOut) then return false end
      Player.spriteYOffset = 0
      Warp.mapTransition(game, destMap, function()
        require("src.core.game3.map").load(mod, game, destMap, {
          x = destX, y = destY, facing = Player.facing, depth1Connections = true,
        })
        Field.lock()
        exitEffect()
      end)
      return true
    end
    return false
  end)
  return true
end

-- pokeemerald/src/field_screen_effect.c:495 DoDiveWarp
function Warp.startDive(mod, game, destMap, destX, destY)
  if Warp._busy then return false end
  destMap, destX, destY = announce(game, destMap, destX, destY, "dive")
  Warp._busy = true
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local Fade = require("src.ui.game3.fade")
  local Task = require("src.core.game3.task")
  local Audio = require("src.core.game3.audio")
  Field.lock()
  local facing = Player.facing
  local toMode, fromMode = warpFadeModes(Fade, game, destMap)
  local musicFrames = tryFadeOutOldMapMusic(game, destMap, destX, destY)
  local E = require("src.core.game3.weather").rseEngine()
  if E then E.playRainStoppingSoundEffect() end
  local faded = false
  Fade.begin(toMode, 1, function() faded = true end)
  Task.spawn(function(t)
    if not faded then return false end
    if t.frames < musicFrames and Audio._fadeOut then return false end
    Warp.mapTransition(game, destMap, function()
      require("src.core.game3.map").load(mod, game, destMap, {
        x = destX, y = destY, facing = facing, depth1Connections = true,
      })
      Player.setVisible(true)
      -- pokeemerald/src/overworld.c:929 GetAdjustedInitialDirection
      Player.facing = facing
      require("src.core.game3.dive").syncAvatar()
      warpExitArrival(game, destMap, destX, destY, fromMode, function()
        Warp._busy = false
        releaseField(Field)
      end)
    end)
    return true
  end)
  return true
end

-- pokeemerald/src/field_control_avatar.c:702 TryStartWarpEventScript
local function rseStepWarp(mod, game, mapId, x, y, srcX, srcY)
  if not (srcX and srcY) or not isRse() then return nil end
  local Collision = require("src.core.game3.collision")
  local beh = Collision.behavior(srcX, srcY)
  if beh == nil then return nil end
  if mbIs(beh, "LAVARIDGE_GYM_B1F_WARP") then
    return Warp.startLavaridgeB1F(mod, game, mapId, x, y, srcX, srcY)
  end
  if mbIs(beh, "LAVARIDGE_GYM_1F_WARP") then
    return Warp.startLavaridge1F(mod, game, mapId, x, y, srcX, srcY)
  end
  if mbIs(beh, "AQUA_HIDEOUT_WARP") then
    return stepWarpScripted(mod, game, "rse_teleport_tile", mapId, x, y, srcX, srcY)
  end
  if mbIs(beh, "BRIDGE_OVER_OCEAN") then
    return stepWarpScripted(mod, game, "rse_spin_exit", mapId, x, y, srcX, srcY)
  end
  -- pokeemerald/data/scripts/cave_hole.inc:23 EventScript_FallDownHoleMtPyre
  if mbIs(beh, "MT_PYRE_HOLE") then
    return Warp.startFall(mod, game, mapId, x, y, srcX, srcY)
  end
  if mbIs(beh, "MOSSDEEP_GYM_WARP") then
    return stepWarpScripted(mod, game, "rse_mossdeep_gym", mapId, x, y, srcX, srcY)
  end
  return nil
end
Warp.rseStepWarp = rseStepWarp

function Warp.request(mod, game, mapId, x, y, facing, opts)
  opts = opts or {}
  if Warp._busy then return nil, "warp busy" end
  if not (opts.door or opts.exitDoor or opts.escalator or opts.teleport or opts.fall) then
    local special = rseStepWarp(mod, game, mapId, x, y, opts.doorX, opts.doorY)
    if special ~= nil then return special end
  end

  if opts.door then
    return Warp.startDoorEntrance(mod, game, mapId, x, y, opts.doorX or x, opts.doorY or y)
  end
  if opts.exitDoor then
    return Warp.startDoorExit(mod, game, mapId, x, y, opts.doorX or x, opts.doorY or y)
  end
  if opts.escalator then
    return Warp.startEscalator(mod, game, mapId, x, y, opts.escalatorDir or "up", opts.approachDir, opts.escX, opts.escY)
  end
  if opts.teleport then
    return Warp.startTeleport(mod, game, mapId, x, y)
  end
  if opts.fall then
    return Warp.startFall(mod, game, mapId, x, y)
  end
  mapId, x, y = announce(game, mapId, x, y, "warp", opts.doorX, opts.doorY)

  Warp._pending = {
    mapId = mapId,
    x = x,
    y = y,
    facing = facing or "down",
    fade = opts.fade ~= false,
  }

  local Doors = require("src.core.game3.doors")
  local Player = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  local curMap = (game and game.currentMap) or mapId
  local sound = opts.se or Doors.getSoundForWarp(curMap, x, y, mapId, false)

  local function doLoad()
    local Map = require("src.core.game3.map")
    local result = Map.load(mod, game, mapId, {
      x = x,
      y = y,
      facing = facing or "down",
      depth1Connections = true,
    })
    Warp._pending = nil
    if Player and Player.setVisible then
      Player.setVisible(true)
    end
    Doors.reset()
    return result
  end

  if opts.fade == false then
    if opts.se ~= false then
      local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
      if Audio and Audio.playSe then pcall(function() Audio.playSe(sound) end) end
    end
    return doLoad()
  end

  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if not (okF and Fade and Fade.begin) then
    if opts.se ~= false then
      local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
      if Audio and Audio.playSe then pcall(function() Audio.playSe(sound) end) end
    end
    return doLoad()
  end

  Warp._busy = true
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  if Field and Field.lock then Field.lock() end
  local toMode, fromMode = warpFadeModes(Fade, game, mapId)

  ordinaryFadeOut(Fade, game, mapId, x, y, toMode, function()
    if opts.se ~= false then
      local Audio = package.loaded["src.core.game3.audio"] or require("src.core.game3.audio")
      if Audio and Audio.playSe then pcall(function() Audio.playSe(sound) end) end
    end
  end, function() Warp.mapTransition(game, mapId, function()
    doLoad()
    if Player and Player.setVisible then
      Player.setVisible(true)
    end
    Doors.reset()
    warpExitArrival(game, mapId, x, y, fromMode, function()
      Warp._busy = false
      releaseField(Field)
    end)
  end) end)

  return true
end

function Warp.clear()
  Warp._pending = nil
  Warp._busy = false
  Warp._isEscalatorActive = false
  local MapPreviewScreen = package.loaded["src.ui.game3.map_preview_screen"]
  if MapPreviewScreen then
    MapPreviewScreen._onDone = nil
    MapPreviewScreen.dismiss()
    MapPreviewScreen._cave = nil
  end
  local CaveTransition = package.loaded["src.ui.game3.cave_transition"]
  if CaveTransition then CaveTransition.clear() end
  local Player = package.loaded["src.core.game3.player"]
  if Player and Player.setVisible then
    Player.walkInPlace = false
    Player.walkInPlaceFast = false
    Player.spriteXOffset = 0
    Player.spriteYOffset = 0
    Player.setVisible(true)
  end
end

return Warp
