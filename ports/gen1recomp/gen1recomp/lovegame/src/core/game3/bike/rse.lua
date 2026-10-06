local Collision = require("src.core.game3.collision")

local Rse = {}

local DELTA = {
  up = { 0, -1 },
  down = { 0, 1 },
  left = { -1, 0 },
  right = { 1, 0 },
}
local OPPOSITE = { up = "down", down = "up", left = "right", right = "left" }
-- pokeemerald/include/constants/global.h:138
local DIR_ID = { down = 1, up = 2, left = 3, right = 4 }
local DIR_NAME = { [1] = "down", [2] = "up", [3] = "left", [4] = "right" }
Rse.DIR_ID = DIR_ID

-- pokeemerald/include/global.fieldmap.h:310
local C = {
  NONE = 0, OUTSIDE_RANGE = 1, IMPASSABLE = 2, ELEVATION_MISMATCH = 3, OBJECT_EVENT = 4,
  STOP_SURFING = 5, LEDGE_JUMP = 6, PUSHED_BOULDER = 7, ROTATING_GATE = 8, WHEELIE_HOP = 9,
  ISOLATED_VERTICAL_RAIL = 10, ISOLATED_HORIZONTAL_RAIL = 11, VERTICAL_RAIL = 12, HORIZONTAL_RAIL = 13,
}
Rse.COLLISION = C

-- pokeemerald/include/global.fieldmap.h:329
local NOT_MOVING, TURN_DIRECTION, MOVING = 0, 1, 2
Rse.RUNNING = { NOT_MOVING = NOT_MOVING, TURN_DIRECTION = TURN_DIRECTION, MOVING = MOVING }

-- pokeemerald/include/bike.h:18
local SPEED = { STANDING = 0, NORMAL = 1, FAST = 2, FASTER = 3, FASTEST = 4 }
Rse.SPEED = SPEED

-- pokeemerald/include/bike.h:36
local ACRO = {
  NORMAL = 0, TURNING = 1, WHEELIE_STANDING = 2, BUNNY_HOP = 3, WHEELIE_MOVING = 4, SIDE_JUMP = 5, TURN_JUMP = 6,
}
Rse.ACRO = ACRO

-- pokeemerald/src/event_object_movement.c:8292 sStepTimes
local FRAMES_NORMAL, FRAMES_FAST_1, FRAMES_FAST_2, FRAMES_FASTER = 16, 8, 6, 4
Rse.FRAMES = { NORMAL = FRAMES_NORMAL, FAST_1 = FRAMES_FAST_1, FAST_2 = FRAMES_FAST_2, FASTER = FRAMES_FASTER }

-- pokeemerald/src/bike.c:111 sMachBikeSpeeds
Rse.MACH_SPEEDS = { [0] = SPEED.NORMAL, [1] = SPEED.FAST, [2] = SPEED.FASTEST }
-- pokeemerald/src/bike.c:75 sMachBikeSpeedCallbacks
Rse.MACH_STEP_FRAMES = { [0] = FRAMES_NORMAL, [1] = FRAMES_FAST_1, [2] = FRAMES_FASTER }

-- pokeemerald/include/gba/io_reg.h:699
local A_BUTTON, B_BUTTON, SELECT_BUTTON, START_BUTTON = 1, 2, 4, 8

-- pokeemerald/src/bike.c:114 sAcroBikeJumpTimerList
local JUMP_TIMER = 4

-- pokeemerald/src/event_object_movement.c:5734
local IN_PLACE_SLOW, IN_PLACE_NORMAL, IN_PLACE_FAST = 32, 16, 8
-- pokeemerald/src/event_object_movement.c:8464
local JUMP_FRAMES_NORMAL, JUMP_FRAMES_FAR = 16, 32
-- pokeemerald/src/data/object_events/object_event_anims.h:416
local WHEELIE_ANIM_FRAMES = 8

local S = {
  acroState = ACRO.NORMAL,
  newDirBackup = nil,
  frameCounter = 0,
  speed = SPEED.STANDING,
  running = NOT_MOVING,
  dirHistory = 0,
  abHistory = 0,
  dirTimers = { 0, 0, 0, 0, 0, 0, 0, 0 },
  abTimers = { 0, 0, 0, 0, 0, 0, 0, 0 },
  cyclingChallenge = false,
  collisions = 0,
  cyclingTimer = 0,
}
Rse.state = S

local function player()
  return package.loaded["src.core.game3.player"] or require("src.core.game3.player")
end

local function playSe(name)
  pcall(function()
    local SE = require("src.core.game3.se_ids")
    local id = SE[name]
    if id then require("src.core.game3.audio").playSe(id) end
  end)
end

-- pokeemerald/src/bike.c:992 BikeClearState
function Rse.clearState(dirHistory, abHistory)
  S.acroState = ACRO.NORMAL
  S.newDirBackup = nil
  S.frameCounter = 0
  S.speed = SPEED.STANDING
  S.dirHistory = dirHistory or 0
  S.abHistory = abHistory or 0
  for i = 1, 8 do
    S.dirTimers[i] = 0
    S.abTimers[i] = 0
  end
end

-- pokeemerald/src/bike.c:1010 Bike_UpdateBikeCounterSpeed
function Rse.updateCounterSpeed(counter)
  S.frameCounter = counter
  S.speed = counter + math.floor(counter / 2)
end

-- pokeemerald/src/bike.c:1016 Bike_SetBikeStill
local function setBikeStill()
  S.frameCounter = 0
  S.speed = SPEED.STANDING
end

-- pokeemerald/src/bike.c:1022 GetPlayerSpeed
function Rse.playerSpeed()
  local P = player()
  if P.biking and P.bikeType == "mach" then return Rse.MACH_SPEEDS[S.frameCounter] or SPEED.NORMAL end
  if P.biking and P.bikeType == "acro" then return SPEED.FASTER end
  if P.surfing or P.running then return SPEED.FAST end
  return SPEED.NORMAL
end

local function movementDir()
  local P = player()
  if P.facingLocked and P.moveDir then return P.moveDir end
  return P.facing
end

local function currentBehavior()
  local P = player()
  return Collision.behavior(P.cellX, P.cellY)
end

-- pokeemerald/src/bike.c:901 IsRunningDisallowedByMetatile
function Rse.runningDisallowedByMetatile(beh)
  if beh == nil then return false end
  local P = player()
  local MB = require("src.core.game3.mb")
  if beh == MB.id("NO_RUNNING") or beh == MB.id("LONG_GRASS") or beh == MB.id("HOT_SPRINGS")
      or Collision.isPacifidlogLog(beh) then
    return true
  end
  return Collision.isFortreeBridge(beh) and (tonumber(P.elevation) or 0) % 2 == 0
end

-- pokeemerald/src/field_player_avatar.c:774 CheckAcroBikeCollision
function Rse.acroCollision(beh)
  if beh == nil then return C.NONE end
  if Collision.isBumpySlope(beh) then return C.WHEELIE_HOP end
  if Collision.isIsolatedVerticalRail(beh) then return C.ISOLATED_VERTICAL_RAIL end
  if Collision.isIsolatedHorizontalRail(beh) then return C.ISOLATED_HORIZONTAL_RAIL end
  if Collision.isVerticalRail(beh) then return C.VERTICAL_RAIL end
  if Collision.isHorizontalRail(beh) then return C.HORIZONTAL_RAIL end
  return C.NONE
end

-- pokeemerald/src/bike.c:916 CanBikeFaceDirOnMetatile
function Rse.canFaceDir(dir, beh)
  if dir == "left" or dir == "right" then
    return not (Collision.isIsolatedVerticalRail(beh) or Collision.isVerticalRail(beh))
  end
  return not (Collision.isIsolatedHorizontalRail(beh) or Collision.isHorizontalRail(beh))
end

-- pokeemerald/src/bike.c:935 WillPlayerCollideWithCollision
local function willCollide(col, dir)
  if dir == "up" or dir == "down" then
    if col == C.ISOLATED_VERTICAL_RAIL or col == C.VERTICAL_RAIL then return false end
  elseif col == C.ISOLATED_HORIZONTAL_RAIL or col == C.HORIZONTAL_RAIL then
    return false
  end
  return true
end

-- pokeemerald/src/bike.c:910 Bike_TryAdvanceCyclingRoadCollisions
local function tryAdvanceCyclingRoadCollisions()
  if S.cyclingChallenge and S.collisions < 100 then S.collisions = S.collisions + 1 end
end

-- pokeemerald/src/field_player_avatar.c:693 CheckForObjectEventCollision
local function objectEventCollision(game, x, y, dir, beh)
  local P = player()
  if Collision.ledgeLanding(game, P.cellX, P.cellY, dir) then return C.LEDGE_JUMP end
  if not Collision.inBounds(x, y) then return C.NONE end
  -- pokeemerald/src/event_object_movement.c:4663
  if Collision.isWarpDoor(beh) then return C.IMPASSABLE end
  local ok, why = Collision.canEnter(game, x, y, {
    fromX = P.cellX, fromY = P.cellY, dir = dir, surfing = P.surfing, elevation = P.currentElevation,
  })
  local col = C.NONE
  if not ok then
    if why == "entity" then
      col = C.OBJECT_EVENT
    elseif why == "elevation" then
      col = C.ELEVATION_MISMATCH
    else
      col = C.IMPASSABLE
    end
  end
  if col == C.NONE then
    local gate = Collision.rotatingGateCollision
    if gate and gate(game, dir, x, y) then return C.ROTATING_GATE end
    col = Rse.acroCollision(beh)
  end
  return col
end

-- pokeemerald/src/bike.c:877 GetBikeCollisionAt
function Rse.collision(game, dir)
  local P = player()
  local d = DELTA[dir]
  if not d then return C.IMPASSABLE end
  local x, y = P.cellX + d[1], P.cellY + d[2]
  local beh = Collision.behavior(x, y)
  local col = objectEventCollision(game, x, y, dir, beh)
  if col > C.OBJECT_EVENT then return col end
  if col == C.NONE and Rse.runningDisallowedByMetatile(beh) then col = C.IMPASSABLE end
  if col ~= C.NONE then tryAdvanceCyclingRoadCollisions() end
  return col
end

local function stepTo(game, dir, frames, opts)
  local P = player()
  local d = DELTA[dir]
  local tx, ty = P.cellX + d[1], P.cellY + d[2]
  if opts and opts.jump == "high" then tx, ty = P.cellX + d[1] * 2, P.cellY + d[2] * 2 end
  if not Collision.inBounds(P.cellX + d[1], P.cellY + d[2]) then
    if Collision.tryConnection(game, P.cellX, P.cellY, dir, true) then
      P.moveDir = dir
      P.stepFrames = frames
      P.running = false
      P.acroAnim = opts and opts.acroAnim or nil
      return true
    end
    return false
  end
  return P.bikeStep(tx, ty, dir, frames, opts)
end

local function faceDir(dir)
  local P = player()
  if not P.facingLocked then P.facing = dir end
  P.moveDir = dir
end

-- pokeemerald/src/field_player_avatar.c:1022 PlayerFaceDirection
local function playerFaceDirection(dir)
  faceDir(dir)
  player().acroAnim = nil
end

-- pokeemerald/src/field_player_avatar.c:1027 PlayerTurnInPlace
local function playerTurnInPlace(dir)
  faceDir(dir)
  player().startAction({ frames = IN_PLACE_FAST, walk = "fast" })
end

-- pokeemerald/src/field_player_avatar.c:1115 PlayCollisionSoundIfNotFacingWarp
local function playCollisionSoundIfNotFacingWarp(dir)
  local P = player()
  if Collision.arrowWarpDir(currentBehavior()) == dir then return end
  if dir == "up" and Collision.isWarpDoor(Collision.behavior(P.cellX, P.cellY - 1)) then return end
  playSe("SE_WALL_HIT")
end

-- pokeemerald/src/field_player_avatar.c:1000 PlayerOnBikeCollide
local function playerOnBikeCollide(dir)
  playCollisionSoundIfNotFacingWarp(dir)
  faceDir(dir)
  player().startAction({ frames = IN_PLACE_NORMAL, walk = "normal" })
end

-- pokeemerald/src/field_player_avatar.c:1032 PlayerJumpLedge
local function playerJumpLedge(game, dir)
  playSe("SE_LEDGE")
  faceDir(dir)
  return stepTo(game, dir, JUMP_FRAMES_FAR, { jump = "high" })
end

local function isCollisionBlocking(col)
  return col > C.NONE and col < C.VERTICAL_RAIL
end

-- pokeemerald/src/bike.c:218 MachBikeTransition_TrySpeedUp
local function machCollide(game, dir, col)
  if col == C.LEDGE_JUMP then
    playerJumpLedge(game, dir)
    return
  end
  setBikeStill()
  if col < C.STOP_SURFING or col > C.ROTATING_GATE then playerOnBikeCollide(dir) end
end

local function machAdvance(game, dir)
  local frames = Rse.MACH_STEP_FRAMES[S.frameCounter] or FRAMES_NORMAL
  faceDir(dir)
  if not stepTo(game, dir, frames) then
    setBikeStill()
    playerOnBikeCollide(dir)
    return false
  end
  return true
end

-- pokeemerald/src/bike.c:180 MachBikeTransition_FaceDirection
local function machFaceDirection(dir)
  playerFaceDirection(dir)
  setBikeStill()
end

-- pokeemerald/src/bike.c:186 MachBikeTransition_TurnDirection
local function machTurnDirection(dir)
  local P = player()
  if Rse.canFaceDir(dir, currentBehavior()) then
    playerTurnInPlace(dir)
    setBikeStill()
  else
    machFaceDirection(P.facing)
  end
end

local machTrySlowDown

-- pokeemerald/src/bike.c:201 MachBikeTransition_TrySpeedUp
local function machTrySpeedUp(game, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then
    if S.speed ~= SPEED.STANDING then
      machTrySlowDown(game, movementDir())
    else
      machFaceDirection(movementDir())
    end
    return
  end
  local col = Rse.collision(game, dir)
  if isCollisionBlocking(col) then
    machCollide(game, dir, col)
    return
  end
  if machAdvance(game, dir) then
    S.speed = S.frameCounter + math.floor(S.frameCounter / 2)
    if S.frameCounter < 2 then S.frameCounter = S.frameCounter + 1 end
  end
end

-- pokeemerald/src/bike.c:245 MachBikeTransition_TrySlowDown
machTrySlowDown = function(game, dir)
  if S.speed ~= SPEED.STANDING then
    S.speed = S.speed - 1
    S.frameCounter = S.speed
  end
  local col = Rse.collision(game, dir)
  if isCollisionBlocking(col) then
    machCollide(game, dir, col)
    return
  end
  machAdvance(game, dir)
end

-- pokeemerald/src/bike.c:141 GetMachBikeTransition
function Rse.machTransition(dirInput)
  local direction = movementDir()
  if dirInput == nil then
    if S.speed == SPEED.STANDING then
      S.running = NOT_MOVING
      return "face", direction
    end
    S.running = MOVING
    return "slowDown", direction
  end
  if dirInput ~= direction and S.running ~= MOVING then
    if S.speed ~= SPEED.STANDING then
      S.running = MOVING
      return "slowDown", direction
    end
    S.running = TURN_DIRECTION
    return "turn", dirInput
  end
  S.running = MOVING
  return "speedUp", dirInput
end

-- pokeemerald/src/bike.c:135 MovePlayerOnMachBike
local function movePlayerOnMachBike(game, dirInput)
  local trans, dir = Rse.machTransition(dirInput)
  if trans == "face" then
    machFaceDirection(dir)
  elseif trans == "turn" then
    machTurnDirection(dir)
  elseif trans == "speedUp" then
    machTrySpeedUp(game, dir)
  else
    machTrySlowDown(game, dir)
  end
  return trans, dir
end

local function heldButtons(input)
  local held = 0
  if input and input.isDown then
    if input:isDown("a") then held = held + A_BUTTON end
    if input:isDown("b") then held = held + B_BUTTON end
    if input:isDown("select") then held = held + SELECT_BUTTON end
    if input:isDown("start") then held = held + START_BUTTON end
  end
  return held
end

-- pokeemerald/src/bike.c:853 Bike_DPadToDirection
function Rse.dpad(input)
  if not (input and input.isDown) then return nil end
  if input:isDown("up") then return "up" end
  if input:isDown("down") then return "down" end
  if input:isDown("left") then return "left" end
  if input:isDown("right") then return "right" end
  return nil
end

local function shiftHistory(hist, timers, value)
  for i = 8, 2, -1 do timers[i] = timers[i - 1] end
  timers[1] = 1
  return (hist % 0x10000000) * 16 + value
end

-- pokeemerald/src/bike.c:767 AcroBike_TryHistoryUpdate
function Rse.historyUpdate(input)
  local Field = package.loaded["src.core.game3.field"]
  if Field and Field.locked then return end
  local dir = DIR_ID[Rse.dpad(input)] or 0
  if dir == S.dirHistory % 16 then
    if S.dirTimers[1] < 0xFF then S.dirTimers[1] = S.dirTimers[1] + 1 end
  else
    S.dirHistory = shiftHistory(S.dirHistory, S.dirTimers, dir)
    S.speed = SPEED.STANDING
  end
  local buttons = heldButtons(input)
  if buttons == S.abHistory % 16 then
    if S.abTimers[1] < 0xFF then S.abTimers[1] = S.abTimers[1] + 1 end
  else
    S.abHistory = shiftHistory(S.abHistory, S.abTimers, buttons)
    S.speed = SPEED.STANDING
  end
end

-- pokeemerald/src/bike.c:813 AcroBike_GetJumpDirection
function Rse.jumpDirection()
  if S.abHistory % 16 ~= B_BUTTON then return nil end
  local dir = DIR_NAME[S.dirHistory % 16]
  if not dir then return nil end
  -- pokeemerald/src/bike.c:796 HasPlayerInputTakenLongerThanList
  if S.dirTimers[1] > JUMP_TIMER or S.abTimers[1] > JUMP_TIMER then return nil end
  return dir
end

local function isBumpy()
  return Collision.isBumpySlope(currentBehavior())
end

local acroInput

-- pokeemerald/src/bike.c:286 AcroBikeHandleInputNormal
local function acroInputNormal(newDir, held)
  local direction = movementDir()
  S.frameCounter = 0
  if newDir == nil then
    S.running = NOT_MOVING
    if held.bNew then
      S.acroState = ACRO.WHEELIE_STANDING
      return "normalToWheelie", direction
    end
    return "face", direction
  end
  if newDir == direction and held.b and S.speed == SPEED.STANDING then
    S.speed = S.speed + 1
    S.acroState = ACRO.WHEELIE_MOVING
    return "wheelieRisingMoving", newDir
  end
  if newDir ~= direction and S.running ~= MOVING then
    S.acroState = ACRO.TURNING
    S.newDirBackup = newDir
    S.running = NOT_MOVING
    return acroInput(newDir, held)
  end
  S.running = MOVING
  return "moving", newDir
end

-- pokeemerald/src/bike.c:326 AcroBikeHandleInputTurning
local function acroInputTurning(_, _)
  local newDir = S.newDirBackup
  S.frameCounter = S.frameCounter + 1
  if S.frameCounter > 6 then
    S.running = TURN_DIRECTION
    S.acroState = ACRO.NORMAL
    setBikeStill()
    return "turnDirection", newDir
  end
  local direction = movementDir()
  if newDir == Rse.jumpDirection() then
    setBikeStill()
    S.speed = SPEED.NORMAL
    if newDir == OPPOSITE[direction] then
      S.acroState = ACRO.TURN_JUMP
      return "turnJump", newDir
    end
    S.running = MOVING
    S.acroState = ACRO.SIDE_JUMP
    return "sideJump", newDir
  end
  return "face", direction
end

-- pokeemerald/src/bike.c:365 AcroBikeHandleInputWheelieStanding
local function acroInputWheelieStanding(newDir, held)
  local direction = movementDir()
  S.running = NOT_MOVING
  if held.b then
    S.frameCounter = S.frameCounter + 1
  else
    S.frameCounter = 0
    if not isBumpy() then
      S.acroState = ACRO.NORMAL
      setBikeStill()
      return "wheelieToNormal", direction
    end
  end
  if S.frameCounter >= 40 then
    S.acroState = ACRO.BUNNY_HOP
    setBikeStill()
    return "wheelieHoppingStanding", direction
  end
  if newDir == direction then
    S.running = MOVING
    S.acroState = ACRO.WHEELIE_MOVING
    setBikeStill()
    return "wheelieMoving", newDir
  end
  if newDir == nil then return "wheelieIdle", direction end
  S.running = TURN_DIRECTION
  return "wheelieIdle", newDir
end

-- pokeemerald/src/bike.c:414 AcroBikeHandleInputBunnyHop
local function acroInputBunnyHop(newDir, held)
  local direction = movementDir()
  if not held.b then
    setBikeStill()
    if isBumpy() then
      S.acroState = ACRO.WHEELIE_STANDING
      return acroInput(newDir, held)
    end
    S.running = NOT_MOVING
    S.acroState = ACRO.NORMAL
    return "wheelieToNormal", direction
  end
  if newDir == nil then
    S.running = NOT_MOVING
    return "wheelieHoppingStanding", direction
  end
  if newDir ~= direction and S.running ~= MOVING then
    S.running = TURN_DIRECTION
    return "wheelieHoppingStanding", newDir
  end
  S.running = MOVING
  return "wheelieHoppingMoving", newDir
end

-- pokeemerald/src/bike.c:461 AcroBikeHandleInputWheelieMoving
local function acroInputWheelieMoving(newDir, held)
  local P = player()
  local direction = P.facing
  if not held.b then
    setBikeStill()
    if not isBumpy() then
      S.acroState = ACRO.NORMAL
      if newDir == nil then
        S.running = NOT_MOVING
        return "wheelieToNormal", direction
      end
      if newDir ~= direction and S.running ~= MOVING then
        S.running = NOT_MOVING
        return "wheelieToNormal", newDir
      end
      S.running = MOVING
      return "wheelieLoweringMoving", newDir
    end
    S.acroState = ACRO.WHEELIE_STANDING
    return acroInput(newDir, held)
  end
  if newDir == nil then
    S.acroState = ACRO.WHEELIE_STANDING
    S.running = NOT_MOVING
    setBikeStill()
    return "wheelieIdle", direction
  end
  if direction ~= newDir and S.running ~= MOVING then
    S.running = NOT_MOVING
    return "wheelieIdle", newDir
  end
  S.running = MOVING
  return "wheelieMoving", newDir
end

-- pokeemerald/src/bike.c:516 AcroBikeHandleInputSidewaysJump
local function acroInputSidewaysJump(newDir, held)
  local P = player()
  P.facingLocked = false
  P.moveDir = P.facing
  S.acroState = ACRO.NORMAL
  return acroInput(newDir, held)
end

-- pokeemerald/src/bike.c:526 AcroBikeHandleInputTurnJump
local function acroInputTurnJump(newDir, held)
  S.acroState = ACRO.NORMAL
  return acroInput(newDir, held)
end

-- pokeemerald/src/bike.c:99 sAcroBikeInputHandlers
local ACRO_INPUT = {
  [ACRO.NORMAL] = acroInputNormal,
  [ACRO.TURNING] = acroInputTurning,
  [ACRO.WHEELIE_STANDING] = acroInputWheelieStanding,
  [ACRO.BUNNY_HOP] = acroInputBunnyHop,
  [ACRO.WHEELIE_MOVING] = acroInputWheelieMoving,
  [ACRO.SIDE_JUMP] = acroInputSidewaysJump,
  [ACRO.TURN_JUMP] = acroInputTurnJump,
}

-- pokeemerald/src/bike.c:281 CheckMovementInputAcroBike
acroInput = function(newDir, held)
  return ACRO_INPUT[S.acroState](newDir, held)
end
Rse.acroInput = function(newDir, held) return acroInput(newDir, held) end

-- pokeemerald/src/field_player_avatar.c:1049 PlayerIdleWheelie
local function playerIdleWheelie(dir)
  faceDir(dir)
  player().acroAnim = { kind = "pedal", clock = 0, paused = true }
end

-- pokeemerald/src/field_player_avatar.c:1055 PlayerStartWheelie
local function playerStartWheelie(dir)
  faceDir(dir)
  player().startAction({ frames = WHEELIE_ANIM_FRAMES, acroAnim = { kind = "back", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1061 PlayerEndWheelie
local function playerEndWheelie(dir)
  faceDir(dir)
  local P = player()
  P.startAction({
    frames = WHEELIE_ANIM_FRAMES,
    acroAnim = { kind = "standBack", clock = 0 },
    done = function() P.acroAnim = nil end,
  })
end

-- pokeemerald/src/field_player_avatar.c:1067 PlayerStandingHoppingWheelie
local function playerStandingHoppingWheelie(dir)
  playSe("SE_BIKE_HOP")
  faceDir(dir)
  player().startAction({ frames = JUMP_FRAMES_NORMAL, jump = "low", acroAnim = { kind = "back", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1074 PlayerMovingHoppingWheelie
local function playerMovingHoppingWheelie(game, dir)
  playSe("SE_BIKE_HOP")
  faceDir(dir)
  stepTo(game, dir, JUMP_FRAMES_NORMAL, { jump = "low", acroAnim = { kind = "back", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1081 PlayerLedgeHoppingWheelie
local function playerLedgeHoppingWheelie(game, dir)
  playSe("SE_BIKE_HOP")
  faceDir(dir)
  stepTo(game, dir, JUMP_FRAMES_FAR, { jump = "high", acroAnim = { kind = "back", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1088 PlayerAcroTurnJump
local function playerAcroTurnJump(dir)
  playSe("SE_BIKE_HOP")
  local P = player()
  faceDir(OPPOSITE[dir])
  P.startAction({
    frames = JUMP_FRAMES_NORMAL, jump = "normal", turnTo = dir,
    done = function() faceDir(dir) end,
  })
end

-- pokeemerald/src/field_player_avatar.c:1094 PlayerWheelieInPlace
local function playerWheelieInPlace(dir)
  playSe("SE_WALL_HIT")
  faceDir(dir)
  player().startAction({ frames = IN_PLACE_FAST, acroAnim = { kind = "pedal", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1100 PlayerPopWheelieWhileMoving
local function playerPopWheelieWhileMoving(game, dir)
  faceDir(dir)
  stepTo(game, dir, FRAMES_FAST_1, { acroAnim = { kind = "back", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1105 PlayerWheelieMove
local function playerWheelieMove(game, dir)
  faceDir(dir)
  stepTo(game, dir, FRAMES_FAST_1, { acroAnim = { kind = "pedal", clock = 0 } })
end

-- pokeemerald/src/field_player_avatar.c:1110 PlayerEndWheelieWhileMoving
local function playerEndWheelieWhileMoving(game, dir)
  faceDir(dir)
  stepTo(game, dir, FRAMES_FAST_1, { acroAnim = { kind = "standBack", clock = 0 } })
end

local ACRO_TRANS = {}

-- pokeemerald/src/bike.c:532 AcroBikeTransition_FaceDirection
ACRO_TRANS.face = function(_, dir) playerFaceDirection(dir) end

-- pokeemerald/src/bike.c:537 AcroBikeTransition_TurnDirection
ACRO_TRANS.turnDirection = function(_, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then dir = movementDir() end
  playerFaceDirection(dir)
end

-- pokeemerald/src/bike.c:546 AcroBikeTransition_Moving
ACRO_TRANS.moving = function(game, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then
    playerFaceDirection(movementDir())
    return
  end
  local col = Rse.collision(game, dir)
  if isCollisionBlocking(col) then
    if col == C.LEDGE_JUMP then
      playerJumpLedge(game, dir)
    elseif col < C.STOP_SURFING or col > C.ROTATING_GATE then
      playerOnBikeCollide(dir)
    end
    return
  end
  faceDir(dir)
  if not stepTo(game, dir, FRAMES_FAST_2) then playerOnBikeCollide(dir) end
end

-- pokeemerald/src/bike.c:572 AcroBikeTransition_NormalToWheelie
ACRO_TRANS.normalToWheelie = function(_, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then dir = movementDir() end
  playerStartWheelie(dir)
end

-- pokeemerald/src/bike.c:581 AcroBikeTransition_WheelieToNormal
ACRO_TRANS.wheelieToNormal = function(_, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then dir = movementDir() end
  playerEndWheelie(dir)
end

-- pokeemerald/src/bike.c:590 AcroBikeTransition_WheelieIdle
ACRO_TRANS.wheelieIdle = function(_, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then dir = movementDir() end
  playerIdleWheelie(dir)
end

-- pokeemerald/src/bike.c:599 AcroBikeTransition_WheelieHoppingStanding
ACRO_TRANS.wheelieHoppingStanding = function(_, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then dir = movementDir() end
  playerStandingHoppingWheelie(dir)
end

-- pokeemerald/src/bike.c:608 AcroBikeTransition_WheelieHoppingMoving
ACRO_TRANS.wheelieHoppingMoving = function(game, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then
    ACRO_TRANS.wheelieHoppingStanding(game, movementDir())
    return
  end
  local col = Rse.collision(game, dir)
  if col ~= C.NONE and col ~= C.WHEELIE_HOP then
    if col == C.LEDGE_JUMP then
      playerLedgeHoppingWheelie(game, dir)
      return
    end
    if col >= C.STOP_SURFING and col <= C.ROTATING_GATE then return end
    if col < C.VERTICAL_RAIL then
      ACRO_TRANS.wheelieHoppingStanding(game, dir)
      return
    end
  end
  playerMovingHoppingWheelie(game, dir)
end

-- pokeemerald/src/bike.c:639 AcroBikeTransition_SideJump
ACRO_TRANS.sideJump = function(game, dir)
  local col = Rse.collision(game, dir)
  if col ~= C.NONE then
    if col == C.PUSHED_BOULDER then return end
    if col < C.ISOLATED_VERTICAL_RAIL or not willCollide(col, dir) then
      ACRO_TRANS.turnDirection(game, dir)
      return
    end
  end
  local P = player()
  playSe("SE_BIKE_HOP")
  P.facingLocked = true
  stepTo(game, dir, JUMP_FRAMES_NORMAL, { jump = "normal" })
end

-- pokeemerald/src/bike.c:666 AcroBikeTransition_TurnJump
ACRO_TRANS.turnJump = function(_, dir) playerAcroTurnJump(dir) end

-- pokeemerald/src/bike.c:671 AcroBikeTransition_WheelieMoving
ACRO_TRANS.wheelieMoving = function(game, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then
    playerIdleWheelie(movementDir())
    return
  end
  local col = Rse.collision(game, dir)
  if isCollisionBlocking(col) then
    if col == C.LEDGE_JUMP then
      playerLedgeHoppingWheelie(game, dir)
    elseif col == C.WHEELIE_HOP then
      playerIdleWheelie(dir)
    elseif col < C.STOP_SURFING then
      if isBumpy() then playerIdleWheelie(dir) else playerWheelieInPlace(dir) end
    end
    return
  end
  playerWheelieMove(game, dir)
  S.running = MOVING
end

-- pokeemerald/src/bike.c:705 AcroBikeTransition_WheelieRisingMoving
ACRO_TRANS.wheelieRisingMoving = function(game, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then
    playerStartWheelie(movementDir())
    return
  end
  local col = Rse.collision(game, dir)
  if isCollisionBlocking(col) then
    if col == C.LEDGE_JUMP then
      playerLedgeHoppingWheelie(game, dir)
    elseif col == C.WHEELIE_HOP then
      playerIdleWheelie(dir)
    elseif col < C.STOP_SURFING then
      if isBumpy() then playerIdleWheelie(dir) else playerWheelieInPlace(dir) end
    end
    return
  end
  playerPopWheelieWhileMoving(game, dir)
  S.running = MOVING
end

-- pokeemerald/src/bike.c:739 AcroBikeTransition_WheelieLoweringMoving
ACRO_TRANS.wheelieLoweringMoving = function(game, dir)
  if not Rse.canFaceDir(dir, currentBehavior()) then
    playerEndWheelie(movementDir())
    return
  end
  local col = Rse.collision(game, dir)
  if isCollisionBlocking(col) then
    if col == C.LEDGE_JUMP then
      playerJumpLedge(game, dir)
    elseif col < C.STOP_SURFING or col > C.ROTATING_GATE then
      playerEndWheelie(dir)
    end
    return
  end
  playerEndWheelieWhileMoving(game, dir)
end
Rse.ACRO_TRANS = ACRO_TRANS

-- pokeemerald/src/bike.c:276 MovePlayerOnAcroBike
local function movePlayerOnAcroBike(game, dirInput, input)
  local held = {
    b = input and input.isDown and input:isDown("b") or false,
    bNew = input and input.wasPressed and input:wasPressed("b") or false,
  }
  local trans, dir = acroInput(dirInput, held)
  local fn = ACRO_TRANS[trans]
  if fn then fn(game, dir) end
  return trans, dir
end

-- pokeemerald/src/event_object_lock.c:37 StopPlayerAvatar
function Rse.stop()
  local P = player()
  if P.biking then
    Rse.handleBumpySlopeJump()
    Rse.updateCounterSpeed(0)
  end
end

-- pokeemerald/src/bike.c:1039 Bike_HandleBumpySlopeJump
function Rse.handleBumpySlopeJump()
  local P = player()
  if not (P.biking and P.bikeType == "acro") then return end
  if Collision.isBumpySlope(currentBehavior()) then
    S.acroState = ACRO.WHEELIE_STANDING
    -- pokeemerald/src/field_player_avatar.c:1432 PlayerUseAcroBikeOnBumpySlope
    faceDir(movementDir())
    P.acroAnim = { kind = "back", clock = 4 }
  end
end

local function fieldLocked()
  local P = player()
  if P.boulderPush or (P.fieldMoveAnim and P.fieldMoveAnim > 0) then return true end
  local Field = package.loaded["src.core.game3.field"]
  if Field and Field.locked then return true end
  local Fade = package.loaded["src.ui.game3.fade"]
  if Fade and Fade.lockInput then return true end
  local Warp = package.loaded["src.core.game3.warp"]
  if Warp and Warp.isBusy and Warp.isBusy() then return true end
  local Runtime = package.loaded["src.core.game3.runtime"]
  if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return true end
  local StepEvents = package.loaded["src.core.game3.step_events"]
  if StepEvents and StepEvents.busy and StepEvents.busy() then return true end
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return true end
  return false
end

Rse._locked = false

-- pokeemerald/src/field_player_avatar.c:332 PlayerStep
function Rse.update(game, input)
  local P = player()
  if P.bikeType ~= "mach" and P.bikeType ~= "acro" then
    local Runtime = package.loaded["src.core.game3.runtime"]
    local session = Runtime and Runtime.getSession and Runtime.getSession()
    P.bikeType = session and session.bikeType or "mach"
  end
  if fieldLocked() then
    if not Rse._locked then
      Rse._locked = true
      Rse.stop()
    end
    return
  end
  Rse._locked = false
  local okTs, TrainerSight = pcall(require, "src.core.game3.trainer_sight")
  if okTs and TrainerSight and TrainerSight.check and TrainerSight.check(game) then return end
  -- pokeemerald/src/field_player_avatar.c:407 TryDoMetatileBehaviorForcedMovement
  if Collision.isMuddySlope(currentBehavior()) then
    local ForcedMovement = require("src.core.game3.forced_movement")
    if ForcedMovement.tryDoMetatileBehaviorForcedMovement(game, currentBehavior()) then return end
  end
  local dir = Rse.dpad(input)
  -- pokeemerald/src/field_control_avatar.c:177
  if dir and dir == P.facing and P.fieldTriggers then
    local trig = P.fieldTriggers(game, dir)
    if trig then return trig end
  end
  if P.bikeType == "mach" then return movePlayerOnMachBike(game, dir) end
  return movePlayerOnAcroBike(game, dir, input)
end

-- pokeemerald/src/bike.c:974 GetOnOffBike
function Rse.getOnOff(kind, session)
  local P = player()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local live = Runtime and Runtime.getSession and Runtime.getSession()
  local game = Runtime and Runtime.getGame and Runtime.getGame()
  local Audio = require("src.core.game3.audio")
  local function mirror(biking, bikeType)
    for _, s in ipairs({ session or false, live or false }) do
      if s then
        s.biking = biking
        s.bikeType = bikeType
      end
    end
    if game and game.save then
      game.save.biking = biking
      if game.save.position then game.save.position.biking = biking end
    end
  end
  if P.biking then
    P.biking = false
    P.bikeType = nil
    P.acroAnim = nil
    P.facingLocked = false
    mirror(false, nil)
    -- pokeemerald/src/bike.c:981
    Audio.bikeMusic(false)
    return false
  end
  P.biking = true
  P.bikeType = kind == "acro" and "acro" or "mach"
  P.moveDir = P.facing
  P.facingLocked = false
  Rse.clearState(0, 0)
  mirror(true, P.bikeType)
  if P.bikeType == "acro" then Rse.handleBumpySlopeJump() end
  -- pokeemerald/src/bike.c:987
  local Song = require("src.core.game3.song_ids")
  local song = Song.forVersion(Song.current or "emerald").MUS_CYCLING
  if song then
    Audio.setSavedSong(song)
    Audio.changeMusicTo(song)
  end
  return true
end

-- pokeemerald/src/bike.c:950 IsBikingDisallowedByPlayer
function Rse.bikingDisallowedByPlayer()
  local P = player()
  if P.surfing or P.underwater then return true end
  local x, y = P.cellX, P.cellY
  if P.moving then x, y = P.targetX, P.targetY end
  return Rse.runningDisallowedByMetatile(Collision.behavior(x, y))
end

-- pokeemerald/src/bike.c:965 IsPlayerNotUsingAcroBikeOnBumpySlope
function Rse.notUsingAcroOnBumpySlope()
  local P = player()
  return not (P.biking and P.bikeType == "acro" and isBumpy())
end

-- pokeemerald/src/item_use.c:200 ItemUseOutOfBattle_Bike
function Rse.onRail()
  local P = player()
  local beh = Collision.behavior(P.cellX, P.cellY)
  return Collision.isVerticalRail(beh) or Collision.isHorizontalRail(beh)
    or Collision.isIsolatedVerticalRail(beh) or Collision.isIsolatedHorizontalRail(beh)
end

local function vblank()
  local Runtime = package.loaded["src.core.game3.runtime"]
  return tonumber(Runtime and Runtime._vblankCounter) or 0
end

-- pokeemerald/src/field_specials.c:161 Special_BeginCyclingRoadChallenge
function Rse.beginCyclingRoadChallenge()
  S.cyclingChallenge = true
  S.collisions = 0
  S.cyclingTimer = vblank()
end

-- pokeemerald/src/field_specials.c:154 ResetCyclingRoadChallengeData
function Rse.resetCyclingRoadChallenge()
  S.cyclingChallenge = false
  S.collisions = 0
  S.cyclingTimer = 0
end

-- pokeemerald/src/field_specials.c:229 FinishCyclingRoadChallenge
function Rse.finishCyclingRoadChallenge()
  return vblank() - S.cyclingTimer, S.collisions
end

return Rse
