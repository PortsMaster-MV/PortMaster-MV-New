-- Public runtime checkpoint implementation. Loader exposes bound forwarding
-- methods; mods never receive controller or state-stack internals from here.

local SaveSerializer = require("src.core.SaveSerializer")
local SaveData = require("src.core.SaveData")
local Version = require("src.core.Version")
local BattleState = require("src.battle.BattleState")
local BattleCheckpoint = require("src.core.BattleCheckpoint")
local ModRuntime = require("src.mods.Runtime")
local BattleSafety = require("src.battle.BattleSafety")

local Checkpoint = {}

Checkpoint.FORMAT = 1

local function refusal(kind, reason, message)
  return {
    canCapture = false,
    canRestore = false,
    kind = kind or "unknown",
    reason = reason,
    message = message,
  }
end

local function running(runner)
  return runner and runner.isRunning and runner:isRunning()
end

local function nonempty(value)
  return type(value) == "table" and next(value) ~= nil
end

local function scriptsBusy(ow)
  return running(ow.runner) or nonempty(ow.parallelRunners)
    or nonempty(ow.pendingScripts) or nonempty(ow.parallelQueue)
    or nonempty(ow.scriptMoves)
end

local function inspectBattle(game, battle)
  local allowed, reason, message = BattleSafety.inspect(game, battle)
  if not allowed then return refusal("battle", reason, message) end
  return { canCapture = true, canRestore = true, kind = "battle" }
end

function Checkpoint.inspect(game)
  local save = game and game.save
  if type(save) ~= "table" or type(save.version) ~= "string" then
    return refusal("unknown", "not_in_playthrough",
      "A checkpoint requires an identified active playthrough.")
  end

  local ow = game.overworld
  if type(ow) ~= "table" or type(ow.map) ~= "table"
      or type(ow.map.id) ~= "string" or type(ow.player) ~= "table" then
    return refusal("unknown", "not_overworld",
      "Only a settled overworld can be checkpointed.")
  end
  local top = game.stack and game.stack.top and game.stack:top()
  if getmetatable(top) == BattleState then
    return inspectBattle(game, top)
  end
  if top ~= ow then
    return refusal("overworld", "screen_busy",
      "Close the active menu or screen before creating a checkpoint.")
  end
  local identity = save.meta and save.meta.playthroughId
  if type(identity) ~= "string" or identity == "" then
    identity = SaveData.ensurePlaythroughId(save)
  end
  if type(identity) ~= "string" or identity == "" then
    return refusal("overworld", "not_in_playthrough",
      "The active playthrough could not be identified.")
  end
  if ow.transitioning then
    return refusal("overworld", "transition_busy",
      "Wait for the map transition to finish.")
  end
  if scriptsBusy(ow) then
    return refusal("overworld", "script_busy",
      "Wait for the active or queued script to finish.")
  end

  local animationFields = {
    "engaging", "emote", "teleportOut", "dustAnim", "cutAnim", "fishPose",
    "pikaHop", "healAnim", "flyAnim", "flyArrive", "flyHidden",
  }
  for _, field in ipairs(animationFields) do
    if ow[field] then
      return refusal("overworld", "animation_busy",
        "Wait for the overworld animation to finish.")
    end
  end
  if ow.player.moving or ow.player.targetX ~= nil or ow.player.targetY ~= nil then
    return refusal("overworld", "movement_busy",
      "Wait for movement to settle on a tile.")
  end
  return { canCapture = true, canRestore = true, kind = "overworld" }
end

local function dataCopy(value)
  local ok, encoded = pcall(SaveSerializer.encode, value)
  if not ok then return nil, tostring(encoded) end
  local decoded, err = SaveSerializer.decode(encoded)
  if not decoded then return nil, err end
  return decoded
end

local function captureRng()
  local getState = love and love.math and love.math.getRandomState
  local setState = love and love.math and love.math.setRandomState
  if type(getState) ~= "function" or type(setState) ~= "function" then return nil end
  local ok, state = pcall(getState)
  if ok and type(state) == "string" and state ~= "" then
    return { love = state }
  end
  return nil
end

local function restoreRng(rng)
  if rng == nil then return end -- legacy format-1 overworld checkpoint
  local setState = love and love.math and love.math.setRandomState
  if type(rng) ~= "table" or type(rng.love) ~= "string"
      or type(setState) ~= "function" then
    error("checkpoint RNG restore is unavailable", 0)
  end
  setState(rng.love)
end

function Checkpoint.capture(game)
  local capability = Checkpoint.inspect(game)
  if not capability.canCapture then
    return nil, capability.reason, capability.message
  end

  local progress = {}
  for key, value in pairs(game.save) do
    if key ~= "options" then progress[key] = value end
  end
  progress = dataCopy(progress)
  if not progress then
    return nil, "capture_failed", "Progress contains non-serializable runtime data."
  end

  local ok, err = pcall(game.overworld.captureSave, game.overworld, progress)
  if not ok then
    return nil, "capture_failed", "Could not synchronize overworld progress: "
      .. tostring(err)
  end
  progress, err = dataCopy(progress)
  if not progress then
    return nil, "capture_failed", "Synchronized progress is not data-only: "
      .. tostring(err)
  end

  if capability.kind == "battle" then
    local battle = game.stack:top()
    local runtime, rngOrCode, battleMessage =
      BattleCheckpoint.capture(game, battle, progress, dataCopy)
    if not runtime then return nil, rngOrCode, battleMessage end
    return {
      format = Checkpoint.FORMAT,
      kind = "battle",
      identity = {
        engineVersion = Version.engine,
        gameVersion = game.save.version,
        playthroughId = game.save.meta.playthroughId,
      },
      save = progress,
      runtime = runtime,
      rng = rngOrCode,
    }
  end

  local player = game.overworld.player
  return {
    format = Checkpoint.FORMAT,
    kind = "overworld",
    identity = {
      engineVersion = Version.engine,
      gameVersion = game.save.version,
      playthroughId = game.save.meta.playthroughId,
    },
    save = progress,
    runtime = { overworld = {
      map = game.overworld.map.id,
      x = player.cellX,
      y = player.cellY,
      facing = player.facing,
      surfing = player.surfing and true or false,
    } },
    rng = captureRng(),
  }
end

local FACINGS = { up = true, down = true, left = true, right = true }

local function validate(game, checkpoint, expectedIdentity)
  if type(checkpoint) ~= "table" then
    return nil, "invalid_checkpoint", "Checkpoint root must be a table."
  end
  if checkpoint.format ~= Checkpoint.FORMAT then
    return nil, "unsupported_format", "This checkpoint format is not supported."
  end
  if checkpoint.kind ~= "overworld" and checkpoint.kind ~= "battle" then
    return nil, "unsupported_runtime_kind", "This checkpoint runtime kind is not supported."
  end

  local copy, copyErr = dataCopy(checkpoint)
  if not copy then
    return nil, "invalid_checkpoint", "Checkpoint is not data-only: "
      .. tostring(copyErr)
  end
  local identity = copy.identity
  local current = game and game.save
  local currentId = expectedIdentity and expectedIdentity.playthroughId
    or (current and current.meta and current.meta.playthroughId)
  local currentVersion = expectedIdentity and expectedIdentity.gameVersion
    or (current and current.version)
  if type(identity) ~= "table" or type(identity.engineVersion) ~= "string"
      or type(identity.gameVersion) ~= "string"
      or type(identity.playthroughId) ~= "string" then
    return nil, "invalid_checkpoint", "Checkpoint identity is missing or corrupt."
  end
  if identity.gameVersion ~= currentVersion then
    return nil, "wrong_game", "Checkpoint belongs to another game version."
  end
  if identity.playthroughId ~= currentId then
    return nil, "wrong_playthrough", "Checkpoint belongs to another playthrough."
  end

  local save = copy.save
  local runtime = copy.runtime and copy.runtime.overworld
  if type(save) ~= "table" or type(save.player) ~= "table"
      or type(runtime) ~= "table" then
    return nil, "invalid_checkpoint", "Checkpoint progress or runtime data is missing."
  end
  if save.version ~= identity.gameVersion
      or not save.meta or save.meta.playthroughId ~= identity.playthroughId then
    return nil, "invalid_checkpoint", "Checkpoint progress identity is inconsistent."
  end
  if copy.rng ~= nil and (type(copy.rng) ~= "table"
      or type(copy.rng.love) ~= "string" or copy.rng.love == "") then
    return nil, "invalid_checkpoint", "Checkpoint RNG state is corrupt."
  end
  if type(runtime.map) ~= "string" or type(runtime.x) ~= "number"
      or type(runtime.y) ~= "number" or runtime.x % 1 ~= 0 or runtime.y % 1 ~= 0
      or not FACINGS[runtime.facing] or type(runtime.surfing) ~= "boolean" then
    return nil, "invalid_checkpoint", "Overworld position is missing or corrupt."
  end
  if save.player.map ~= runtime.map or save.player.x ~= runtime.x
      or save.player.y ~= runtime.y or save.player.facing ~= runtime.facing
      or (save.player.surfing and true or false) ~= runtime.surfing then
    return nil, "invalid_checkpoint", "Progress and runtime position disagree."
  end

  local map = game.data and game.data.maps and game.data.maps[runtime.map]
  if type(map) ~= "table" then
    return nil, "invalid_map", "Checkpoint references a map that is unavailable."
  end
  local width, height = tonumber(map.width), tonumber(map.height)
  if not width or not height or runtime.x < 0 or runtime.y < 0
      or runtime.x >= width * 2 or runtime.y >= height * 2 then
    return nil, "invalid_position", "Checkpoint position is outside the map."
  end

  -- A checkpoint is a strict restoration record, not an ordinary CONTINUE
  -- migration. Reuse the canonical save validator on the detached copy, but
  -- reject any quarantine, remap, reclaim, clamp, or content repair it would
  -- perform instead of silently changing the state the caller selected.
  local beforeContent = SaveSerializer.encode(copy.save)
  local validOk, report = pcall(SaveData.validate, copy.save, game.data)
  local afterOk, afterContent = pcall(SaveSerializer.encode, copy.save)
  if not validOk or not afterOk or not SaveData.emptyReport(report)
      or afterContent ~= beforeContent then
    return nil, "invalid_content",
      "Checkpoint references unavailable or invalid game content."
  end
  if copy.kind == "battle" then
    local battleOk, battleCode, battleMessage = BattleCheckpoint.validate(game, copy)
    if not battleOk then return nil, battleCode, battleMessage end
  elseif copy.runtime.battle ~= nil then
    return nil, "invalid_checkpoint",
      "Overworld checkpoint contains unexpected battle state."
  end
  return copy
end

local function apply(game, checkpoint, options)
  local save, err = dataCopy(checkpoint.save)
  if not save then error("checkpoint progress decode failed: " .. tostring(err), 0) end
  local runtime = checkpoint.runtime.overworld
  save.options = options
  save.player.map = runtime.map
  save.player.x = runtime.x
  save.player.y = runtime.y
  save.player.facing = runtime.facing
  save.player.surfing = runtime.surfing
  if type(game.restoreCheckpointSave) ~= "function" then
    error("game has no checkpoint reconstruction path", 0)
  end
  game:restoreCheckpointSave(save)
  if checkpoint.kind == "battle" then
    BattleCheckpoint.restore(game, checkpoint, dataCopy)
  else
    restoreRng(checkpoint.rng)
  end
end

local function equalData(a, b)
  local okA, encodedA = pcall(SaveSerializer.encode, a)
  local okB, encodedB = pcall(SaveSerializer.encode, b)
  return okA and okB and encodedA == encodedB
end

local function normalizeVerificationMetadata(actual, expected)
  if type(actual) == "table" and type(actual.identity) == "table"
      and type(expected) == "table" and type(expected.identity) == "table" then
    -- RFC 0004 treats engineVersion as compatibility metadata, not runtime
    -- state. A fresh recapture stamps the running engine, so normalize only
    -- that metadata before differential verification.
    actual.identity.engineVersion = expected.identity.engineVersion
  end
end

local function firstDifference(a, b, path)
  path = path or "$"
  if type(a) ~= type(b) then return path .. " (type)" end
  if type(a) ~= "table" then
    if a ~= b then return path end
    return nil
  end
  for key, value in pairs(a) do
    if b[key] == nil and value ~= nil then
      return path .. "." .. tostring(key) .. " (missing)"
    end
    local found = firstDifference(value, b[key], path .. "." .. tostring(key))
    if found then return found end
  end
  for key, value in pairs(b) do
    if a[key] == nil and value ~= nil then
      return path .. "." .. tostring(key) .. " (unexpected)"
    end
  end
  return nil
end

local emitRestored

-- Persist the current verified checkpoint as the ordinary progress anchor only
-- when this playthrough has never had one. This is intentionally idempotent:
-- durable checkpoint tools can make a first session resumable without turning
-- every later checkpoint into a hidden normal SAVE. The live runtime must still
-- match the supplied checkpoint, and the ordinary save.write veto/lifecycle
-- remains authoritative through Game:writeSave().
function Checkpoint.ensureNormalSave(game, checkpoint, injectedFs)
  local capability = Checkpoint.inspect(game)
  if not capability.canCapture then
    return false, capability.reason, capability.message
  end
  local validated, code, message = validate(game, checkpoint)
  if not validated then return false, code, message end

  local info, infoCode, infoMessage =
    SaveData.selectedNormalSaveInfo(game.save, injectedFs)
  if not info then return false, infoCode, infoMessage end
  if info.exists then return true, "already_exists" end

  local current, captureCode, captureMessage = Checkpoint.capture(game)
  if not current then return false, captureCode, captureMessage end
  if not equalData(current, validated) then
    return false, "checkpoint_not_current",
      "The active runtime changed after this checkpoint was captured."
  end
  if type(game.writeSave) ~= "function" then
    return false, "save_unavailable",
      "The active runtime cannot persist ordinary progress."
  end
  local ok, saved = pcall(game.writeSave, game)
  if not ok or saved == false then
    return false, "save_failed", "Could not create the first ordinary progress save."
  end
  local verified = SaveData.selectedNormalSaveInfo(game.save, injectedFs)
  if type(verified) ~= "table" or not verified.exists then
    return false, "save_verify_failed",
      "The first ordinary progress save could not be verified."
  end
  return true
end

function Checkpoint.restore(game, checkpoint)
  local capability = Checkpoint.inspect(game)
  if not capability.canRestore then
    return false, capability.reason, capability.message
  end
  local validated, code, message = validate(game, checkpoint)
  if not validated then return false, code, message end

  local rollback, captureCode, captureMessage = Checkpoint.capture(game)
  if not rollback then return false, captureCode, captureMessage end
  local options = game.save.options

  local ok, err = pcall(apply, game, validated, options)
  if ok then
    local restored, verifyCode = Checkpoint.capture(game)
    if restored and validated.rng == nil then restored.rng = nil end
    normalizeVerificationMetadata(restored, validated)
    if restored and equalData(restored, validated) then
      emitRestored(game, validated)
      return true
    end
    err = restored and ("restored state differed at "
      .. tostring(firstDifference(validated, restored) or "canonical encoding"))
      or ("restored state could not be captured: " .. tostring(verifyCode))
  end

  local rolledBack, rollbackErr = pcall(apply, game, rollback, options)
  if not rolledBack then
    return false, "rollback_failed",
      "Checkpoint restore and rollback both failed: " .. tostring(rollbackErr)
  end
  return false, "restore_failed", "Checkpoint restoration failed: " .. tostring(err)
end

emitRestored = function(game, checkpoint)
  if ModRuntime.wants("checkpoint.restored") then
    ModRuntime.emit("checkpoint.restored", {
      game = game,
      kind = checkpoint.kind,
    })
  end
end

local function isTitleSession(game)
  local states = game and game.stack and game.stack.states
  if type(states) ~= "table" then return false end
  for _, state in ipairs(states) do
    if type(state) == "table" and state.screenId == "TitleState" then return true end
  end
  return false
end

local function rebuildTitle(game, savedTitle, rng)
  local save, err = dataCopy(savedTitle)
  if not save then error("title rollback decode failed: " .. tostring(err), 0) end
  game.save = save
  if type(game.adoptSave) == "function" then game:adoptSave(save) end
  restoreRng(rng)
  if not (game.stack and game.stack.top and game.stack.pop and game.stack.push
      and type(game.makeTitleState) == "function") then
    error("title recovery is unavailable", 0)
  end
  while game.stack:top() do game.stack:pop() end
  game.stack:push(game:makeTitleState())
end

-- Reconstruct a validated persistent checkpoint from the title session. This
-- is intentionally separate from restore(): title has no live gameplay state
-- to capture for rollback. Validation happens before any mutation; a failed
-- reconstruction rebuilds a fresh usable title session instead of exposing a
-- half-installed overworld or battle.
function Checkpoint.resume(game, checkpoint)
  if not isTitleSession(game) then
    return false, "not_at_title",
      "Checkpoint resume is available only from the title session."
  end
  local save = game and game.save
  local playthroughId, identityCode, identityMessage =
    SaveData.selectedPlaythroughId(save)
  if type(playthroughId) ~= "string" or playthroughId == "" then
    return false, identityCode, identityMessage
  end
  local expected = { gameVersion = save and save.version, playthroughId = playthroughId }
  local validated, code, message = validate(game, checkpoint, expected)
  if not validated then return false, code, message end

  local titleSave, titleErr = dataCopy(save)
  if not titleSave then
    return false, "title_recovery_unavailable",
      "Could not preserve the title session: " .. tostring(titleErr)
  end
  local titleRng = captureRng()
  local currentOptions = save.options
  local ok, err = pcall(apply, game, validated, currentOptions)
  if ok then
    local restored, verifyCode = Checkpoint.capture(game)
    if restored and validated.rng == nil then restored.rng = nil end
    normalizeVerificationMetadata(restored, validated)
    if restored and equalData(restored, validated) then
      emitRestored(game, validated)
      return true
    end
    err = restored and ("resumed state differed at "
      .. tostring(firstDifference(validated, restored) or "canonical encoding"))
      or ("resumed state could not be captured: " .. tostring(verifyCode))
  end

  local recovered, recoveryErr = pcall(rebuildTitle, game, titleSave, titleRng)
  if not recovered then
    return false, "title_recovery_failed",
      "Checkpoint resume failed and title recovery failed: " .. tostring(recoveryErr)
  end
  return false, "resume_failed", "Checkpoint resume failed: " .. tostring(err)
end

return Checkpoint
