-- Game3 Trainer Line of Sight Engine (FRLG authentic).
-- Handles directional raycast vision, elevation & ledge masking, exclamation bubble,
-- walk-up approach tracking, zero-distance skips, and battle script engagement.

local Flags = require("src.core.game3.scripting.flags")
local Ctx = require("src.core.game3.scripting.ctx")
local ModRuntime = require("src.mods.Runtime")

local TrainerSight = {}

local DELTA = {
  up = { 0, -1 },
  down = { 0, 1 },
  left = { -1, 0 },
  right = { 1, 0 },
}

local OPPOSITE_FACING = {
  down = "up",
  up = "down",
  left = "right",
  right = "left",
}

-- pret MetatileBehavior ledge jump bytes (MB_JUMP_*)
local LEDGE_BEHAVIORS = {
  [0x38] = true, -- MB_JUMP_SOUTH
  [0x39] = true, -- MB_JUMP_NORTH
  [0x3A] = true, -- MB_JUMP_WEST
  [0x3B] = true, -- MB_JUMP_EAST
  [0xA0] = true, -- MB_JUMP_EAST_IGNORE_SLOPE
  [0xA1] = true, -- MB_JUMP_WEST_IGNORE_SLOPE
  [0xA2] = true, -- MB_JUMP_NORTH_IGNORE_SLOPE
  [0xA3] = true, -- MB_JUMP_SOUTH_IGNORE_SLOPE
}

local function Player()
  return package.loaded["src.core.game3.player"]
    or require("src.core.game3.player")
end

local function Objects()
  return package.loaded["src.core.game3.objects"]
    or require("src.core.game3.objects")
end

local function Collision()
  return package.loaded["src.core.game3.collision"]
    or require("src.core.game3.collision")
end

local function Field()
  return package.loaded["src.core.game3.field"]
    or require("src.core.game3.field")
end

local function Space()
  return package.loaded["src.core.game3.scripting.space"]
    or require("src.core.game3.scripting.space")
end

local function FieldEffects()
  return package.loaded["src.core.game3.field_effects"]
    or require("src.core.game3.field_effects")
end

--- Extract numeric trainer ID from EventObject def or script bytecode.
function TrainerSight.getTrainerId(eo)
  if not eo then return nil end
  if eo.trainerId then return eo.trainerId end
  if eo.def and eo.def.trainerId then
    eo.trainerId = tonumber(eo.def.trainerId)
    return eo.trainerId
  end
  local scriptKey = eo.scriptKey or (eo.def and eo.def.scriptKey)
  if not scriptKey then return nil end
  local Sp = Space()
  local scripts = Sp and Sp.bundle and Sp.bundle.scripts
  local list = scripts and scripts[scriptKey]
  if type(list) == "table" then
    -- negative cache: this exact script list was already scanned without a
    -- trainerbattle (a script swapped in under the key rescans)
    if eo._trainerIdMiss == list then return nil end
    for _, row in ipairs(list) do
      if row.op == "trainerbattle" or row.op == "dotrainerbattle" then
        local tid = tonumber(row.trainer or row[1])
        if tid then
          eo.trainerId = tid
          eo.trainerBattleType = tonumber(row.type) or 0
          return tid
        end
      end
    end
    eo._trainerIdMiss = list
  end
  return nil
end

-- pokefirered/src/trainer_see.c:97
function TrainerSight.isTrainerType(eo)
  if not eo then return false end
  local tt = tonumber(eo.trainerType or (eo.def and eo.def.trainerType)) or 0
  return tt == 1 or tt == 3
end

--- Check if trainer has already been defeated.
function TrainerSight.isDefeated(eo, store, ctx)
  if not eo then return true end
  local tid = TrainerSight.getTrainerId(eo)
  if tid then
    local fid = Flags.trainerFlagId(tid)
    if Flags.getFlag(store, ctx, fid) then
      return true
    end
  end
  -- Check template defeat flag if present
  local flag = eo.flag or (eo.def and (eo.def.flag or eo.def.flagId))
  if flag and flag ~= 0 and flag ~= 0xFFFF and flag ~= 65535 then
    if Flags.getFlag(store, ctx, flag) then
      return true
    end
  end
  return false
end

function TrainerSight.battleType(eo)
  if not eo then return nil end
  if eo.trainerBattleType == nil then
    local Sp = Space()
    local scriptKey = eo.scriptKey or (eo.def and eo.def.scriptKey)
    local list = scriptKey and Sp and Sp.bundle and Sp.bundle.scripts and Sp.bundle.scripts[scriptKey]
    eo.trainerBattleType = false
    for _, row in ipairs(type(list) == "table" and list or {}) do
      if row.op == "trainerbattle" or row.op == "dotrainerbattle" then
        eo.trainerBattleType = tonumber(row.type) or 0
        break
      end
    end
  end
  return eo.trainerBattleType or nil
end

-- pokefirered/src/trainer_see.c:114
function TrainerSight.blockedByDoubles(eo)
  if TrainerSight.battleType(eo) ~= 4 then return false end
  local Party = require("src.core.game3.party")
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  return Party.monsStateToDoubles(session and session.party) ~= Party.PLAYER_HAS_TWO_USABLE_MONS
end

--- Test if a metatile behavior byte represents a one-way ledge hop.
local function is_ledge_tile(game, cx, cy)
  local Coll = Collision()
  if Coll.isLedge and Coll.isLedge(cx, cy) then
    return true
  end
  local cellByte = Coll.cell and Coll.cell(cx, cy)
  if cellByte and LEDGE_BEHAVIORS[cellByte] then
    return true
  end
  return false
end

local function isRse()
  local O = Objects()
  return O.isRse ~= nil and O.isRse()
end

-- pokeemerald/src/trainer_see.c:301
local SEE_ALL_ORDER = { "down", "up", "left", "right" }

--- Directional line-of-sight raycast verifying elevation, obstacles, ledges, and intermediaries.
-- @return spotted (bool), dist (number)
function TrainerSight.checkLineOfSight(eo, P, game, facingOverride)
  if not eo or not P then return false, 0 end
  if not facingOverride and isRse() and tonumber(eo.trainerType or (eo.def and eo.def.trainerType)) == 3 then
    for _, dir in ipairs(SEE_ALL_ORDER) do
      local spotted, dist = TrainerSight.checkLineOfSight(eo, P, game, dir)
      if spotted then return true, dist, dir end
    end
    return false, 0
  end
  local facing = facingOverride or eo.facing or "down"
  local d = DELTA[facing]
  if not d then return false, 0 end

  -- src/trainer_see.c:151
  local ex = eo.moving and eo.targetX or eo.cellX
  local ey = eo.moving and eo.targetY or eo.cellY
  local px, py = P.cellX, P.cellY
  local dx, dy = d[1], d[2]
  local dist = 0

  if dx ~= 0 then
    if py ~= ey then return false, 0 end
    if (px - ex) * dx <= 0 then return false, 0 end
    dist = math.abs(px - ex)
  elseif dy ~= 0 then
    if px ~= ex then return false, 0 end
    if (py - ey) * dy <= 0 then return false, 0 end
    dist = math.abs(py - ey)
  end

  local sight = tonumber(eo.sight or (eo.def and (eo.def.sight or eo.def.trainerRange))) or 0
  if dist < 1 or dist > sight then
    return false, 0
  end

  local Coll = Collision()
  local Objs = Objects()
  local eoElev = tonumber(eo.currentElevation) or 0
  local mapDef = eo.mapDef or Coll._mapDef

  -- pokefirered/src/trainer_see.c:225
  if Objs.elevationsCompatible and not Objs.elevationsCompatible(eoElev, P.currentElevation) then
    return false, 0
  end
  if Coll.elevationMismatchOn and Coll.elevationMismatchOn(mapDef, eoElev, px, py) then
    return false, 0
  end

  -- Raycast intermediate tiles strictly between trainer and player
  for step = 1, dist - 1 do
    local cx = ex + dx * step
    local cy = ey + dy * step
    local fromX = ex + dx * (step - 1)
    local fromY = ey + dy * (step - 1)

    -- 1. Collision check: must be passable along raycast direction
    if Coll.canEnter and not Coll.canEnter(game, cx, cy, { fromX = fromX, fromY = fromY, dir = facing, elevation = eoElev }) then
      return false, 0
    end
    -- pokefirered/src/trainer_see.c:214
    if Coll.elevationMismatchOn and Coll.elevationMismatchOn(mapDef, eoElev, cx, cy) then
      return false, 0
    end

    -- 2. Ledge masking: line of sight cannot penetrate one-way ledge boundaries
    if is_ledge_tile(game, cx, cy) then
      return false, 0
    end

    -- 3. Intermediary NPCs block vision
    if Objs.blocks and Objs.blocks(cx, cy, eo.localId, eoElev) then
      return false, 0
    end
    local other = Objs.at and Objs.at(cx, cy)
    if other and (not Objs.elevationsCompatible or Objs.elevationsCompatible(eoElev, other.currentElevation)) then
      return false, 0
    end
  end

  -- Check player tile for ledge boundary
  if is_ledge_tile(game, px, py) then
    return false, 0
  end

  return true, dist, facing
end

local function faceMovementType(facing)
  return ({ down = 0x08, up = 0x07, left = 0x09, right = 0x0A })[facing] or 0x08
end

-- pokeemerald/src/trainer_see.c:564
function TrainerSight.revealBuried(eo, done, facing)
  local Objs = Objects()
  local P = Player()
  if facing then
    eo.facing = facing
  elseif P then
    local dx, dy = P.cellX - eo.cellX, P.cellY - eo.cellY
    if math.abs(dx) > math.abs(dy) then eo.facing = dx > 0 and "right" or "left"
    else eo.facing = dy > 0 and "down" or "up" end
  end
  local FxRse = require("src.core.game3.field_effects_rse")
  local shown, puffDone = false, false
  local function finish()
    if not (shown and puffDone) or eo.moving then return false end
    -- pokeemerald/src/trainer_see.c:625
    local mt = faceMovementType(eo.facing)
    Objs.setTrainerMovementType(eo, mt)
    Objs.overrideTemplateMovementType(eo.localId, mt)
    if done then done() end
    return true
  end
  local puff = FxRse.startAshPuff(eo.cellX, eo.cellY, function() puffDone = true end)
  if puff then
    local prev = puff.onStep
    puff.onStep = function(e)
      -- pokeemerald/src/trainer_see.c:593
      if not shown and (e.a.index or 0) >= 2 then
        shown = true
        eo.invisible = false
        eo.buried = nil
        Objs.scriptJump(eo, eo.facing, 0, { type = "high" })
      end
      if prev then return prev(e) end
    end
  else
    shown, puffDone = true, true
    eo.invisible, eo.buried = false, nil
  end
  local Task = require("src.core.game3.task")
  Task.spawn(function() return finish() end)
end

-- pokeemerald/src/trainer_see.c:543
function TrainerSight.revealDisguise(eo, done)
  local d = eo.disguise
  if not d then
    if done then done() end
    return
  end
  local FxRse = require("src.core.game3.field_effects_rse")
  d.a = FxRse.anim(FxRse.animCmds(d.sheet, 2))
  d.revealing = true
  local Task = require("src.core.game3.task")
  Task.spawn(function()
    if eo.disguise and not eo.disguise.done then return false end
    if done then done() end
    return true
  end)
end

-- pokeemerald/src/trainer_see.c:472
function TrainerSight.revealThen(eo, facing, cont)
  if not isRse() then return cont() end
  if eo.buried then return TrainerSight.revealBuried(eo, cont, facing) end
  if eo.disguise then return TrainerSight.revealDisguise(eo, cont) end
  return cont()
end

local EMPTY = {}

local function fieldBlock()
  local Profile = package.loaded["src.core.game3.profile"] or require("src.core.game3.profile")
  local ok, row = pcall(Profile.forSession)
  return ok and row and row.field or EMPTY, ok and row or nil
end

-- pokeemerald/src/battle_setup.c:1440
function TrainerSight.encounterMusic(tid)
  local block, row = fieldBlock()
  local rule = block.encounterMusic
  if not (rule and row) then return nil end
  local okT, Trainers = pcall(require, "src.core.game3.scripting.trainers")
  local t = okT and Trainers and tid and Trainers.get and Trainers.get(tid)
  local code = t and (tonumber(t.encounterMusic) or 0) % 128 or -1
  local C = require("src.core.game3.constants").of(row.id)
  local name = C:name("trainer_classes", code, rule.prefix)
  local song = name and C:song(rule.song .. name:sub(#rule.prefix + 1))
  return song or C:song(rule.default)
end

--- Engage trainer encounter: play '!' exclamation bubble, walk up (or skip if dist == 1), and launch script.
function TrainerSight.engage(game, eo, dist, facing)
  local F = Field()
  local P = Player()
  local Objs = Objects()
  local Sp = Space()
  local Fx = FieldEffects()

  -- 1. Strictly lock overworld state immediately
  F.locked = true
  eo.frozen = true
  eo.scriptBusy = true

  -- 2. Turn trainer to face player directly
  local playerFacing = OPPOSITE_FACING[eo.facing] or "up"

  -- 3. Play encounter music immediately when trainer spots player (pret PlayTrainerEncounterMusic / EventScript_DoTrainerBattleFromApproach)
  local tid = TrainerSight.getTrainerId(eo)
  local okT, Trainers = pcall(require, "src.core.game3.scripting.trainers")
  -- pokefirered/src/trainer_see.c:105
  if ModRuntime.wants("world.trainer_engaged") then
    local info = okT and Trainers and tid and Trainers.info and Trainers.info(tid) or nil
    local Map = package.loaded["src.core.game3.map"]
    ModRuntime.emit("world.trainer_engaged", {
      npc = eo, trainerClass = info and info.class, partyIndex = tid, trainerId = tid,
      mapId = Map and Map.current, sight = { distance = dist, facing = eo.facing },
    })
  end
  local musicId = TrainerSight.encounterMusic(tid)
  if musicId == nil then
    musicId = okT and Trainers and Trainers.getEncounterMusic and Trainers.getEncounterMusic(tid)
  end
  if not musicId then
    musicId = 285 -- MUS_ENCOUNTER_BOY fallback
  end
  local okA, Audio = pcall(require, "src.core.game3.audio")
  if okA and Audio and Audio.playSong then
    Audio.playSong(musicId)
  end

  -- 4. Play exclamation animation and sound effect SE_PIN (21)
  Fx.startExclamation(eo, function()
    local scriptKey = eo.scriptKey or (eo.def and eo.def.scriptKey)

    local function finishEngagement()
      P.facing = playerFacing
      -- pokefirered/src/trainer_see.c:349-351 SetTrainerMovementType, OverrideMovementTypeForObjectEvent, OverrideTemplateCoordsForObjectEvent
      local faceMt = ({ down = 0x08, up = 0x07, left = 0x09, right = 0x0A })[eo.facing] or 0x08
      if Objs.setTrainerMovementType then
        Objs.setTrainerMovementType(eo, faceMt)
      else
        eo.movementType = faceMt
        eo.movement = "STAY"
        eo.range = (eo.facing or "down"):upper()
      end
      if Objs.overrideTemplateMovementType then
        Objs.overrideTemplateMovementType(eo.localId, faceMt)
      end
      eo.homeX = eo.cellX
      eo.homeY = eo.cellY
      if eo.def then
        eo.def.movementType = faceMt
        eo.def.movement = "STAY"
        eo.def.x = eo.cellX
        eo.def.y = eo.cellY
        eo.def.range = (eo.facing or "down"):upper()
      end
      if Objs.rememberPerm and Objs._mapId then
        Objs.rememberPerm(Objs._mapId, eo.localId, {
          x = eo.cellX,
          y = eo.cellY,
          movementType = faceMt,
          facing = eo.facing,
        })
      end
      eo.frozen = false
      eo.scriptBusy = false
      F.locked = false
      if scriptKey then
        local dirs = { down = 1, up = 2, left = 3, right = 4 }
        local facingDir = dirs[P.facing] or 1
        if Sp and Sp.startScript then
          Sp.startScript(scriptKey, eo.localId, facingDir)
        elseif Sp and Sp.runScript then
          local Runtime = package.loaded["src.core.game3.runtime"]
          local mod = Runtime and Runtime._mod
          local g = game or (Runtime and Runtime._game)
          local world = g and (g.overworld or g.world)
          Sp.runScript(mod, scriptKey, g, world, eo.localId)
        end
      end
    end

    -- Walk-up Approach Tracking: walk dist - 1 steps toward player, or skip if adjacent (dist == 1)
    TrainerSight.revealThen(eo, facing, function()
      playerFacing = OPPOSITE_FACING[eo.facing] or playerFacing
      local walkSteps = dist - 1
      if walkSteps <= 0 then
        finishEngagement()
      else
        local actions = {}
        for _ = 1, walkSteps do
          actions[#actions + 1] = { kind = "step", dir = eo.facing }
        end
        Objs.startTrack(eo.localId, actions, function()
          finishEngagement()
        end)
      end
    end)
  end)
end

local function battleRow(eo)
  local Sp = Space()
  local scriptKey = eo.scriptKey or (eo.def and eo.def.scriptKey)
  local list = scriptKey and Sp and Sp.bundle and Sp.bundle.scripts and Sp.bundle.scripts[scriptKey]
  for _, row in ipairs(type(list) == "table" and list or {}) do
    if row.op == "trainerbattle" then return row end
  end
  return nil
end

local function twoTrainerApproach()
  local ok, bp = pcall(function() return require("src.core.game3.battle.profile").get() end)
  return ok and bp and bp.kinds and bp.kinds.twoOpponents == true
end
TrainerSight.twoTrainerApproach = twoTrainerApproach

local function canDouble()
  local Party = require("src.core.game3.party")
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  return Party.monsStateToDoubles(session and session.party) == Party.PLAYER_HAS_TWO_USABLE_MONS
end

local DOUBLE_TYPES = { [4] = true, [6] = true, [7] = true, [8] = true }

local function playEncounterMusic(tid, row)
  -- pokeemerald/src/battle_setup.c:1440
  local mode = tonumber(row and row.type) or 0
  if mode == 1 or mode == 8 then return end
  local musicId = TrainerSight.encounterMusic(tid)
  if musicId == nil then
    local okT, Trainers = pcall(require, "src.core.game3.scripting.trainers")
    musicId = okT and Trainers and Trainers.getEncounterMusic and Trainers.getEncounterMusic(tid)
  end
  local okA, Audio = pcall(require, "src.core.game3.audio")
  if musicId and okA and Audio and Audio.playSong then Audio.playSong(musicId) end
end

-- pokeemerald/src/trainer_see.c:422
local function approach(eo, dist, facing, done)
  local P = Player()
  local Objs = Objects()
  eo.frozen = true
  eo.scriptBusy = true
  FieldEffects().startExclamation(eo, function()
    local function arrive()
      -- pokeemerald/src/trainer_see.c:509
      local faceMt = ({ down = 0x08, up = 0x07, left = 0x09, right = 0x0A })[eo.facing] or 0x08
      if Objs.setTrainerMovementType then Objs.setTrainerMovementType(eo, faceMt) end
      if Objs.overrideTemplateMovementType then Objs.overrideTemplateMovementType(eo.localId, faceMt) end
      eo.homeX, eo.homeY = eo.cellX, eo.cellY
      if eo.def then
        eo.def.movementType = faceMt
        eo.def.movement = "STAY"
        eo.def.x, eo.def.y = eo.cellX, eo.cellY
        eo.def.range = (eo.facing or "down"):upper()
      end
      if Objs.rememberPerm and Objs._mapId then
        Objs.rememberPerm(Objs._mapId, eo.localId, { x = eo.cellX, y = eo.cellY, movementType = faceMt, facing = eo.facing })
      end
      P.facing = OPPOSITE_FACING[eo.facing] or P.facing
      eo.frozen = false
      eo.scriptBusy = false
      done()
    end
    TrainerSight.revealThen(eo, facing, function()
      if dist - 1 <= 0 then return arrive() end
      local actions = {}
      for _ = 1, dist - 1 do actions[#actions + 1] = { kind = "step", dir = eo.facing } end
      Objs.startTrack(eo.localId, actions, arrive)
    end)
  end)
end

local function introSpeech(eo, tid, row, done)
  local Sp = Space()
  local text
  if row and row.introText and Sp and Sp.vm and Sp.vm.getText then
    text = Sp.vm:getText(row.introText)
  end
  if not text then
    local okT, Trainers = pcall(require, "src.core.game3.scripting.trainers")
    text = okT and Trainers.dialogs(tid).intro or ""
  end
  -- pokeemerald/src/battle_setup.c:1378
  require("src.ui.game3.hud").openMessage(nil, text, { done = done })
end

-- pokeemerald/data/scripts/trainer_battle.inc:1
function TrainerSight.engagePair(game, a, b)
  local F = Field()
  local Sp = Space()
  F.locked = true
  a.eo.frozen, b.eo.frozen = true, true

  local okPyr, Pyramid = pcall(require, "src.core.game3.rse.frontier.pyramid")
  local inPyramid = okPyr and Pyramid and Pyramid.inPyramid and Pyramid.inPyramid()

  local tidA, tidB
  local sess = nil
  local D = nil
  local partyA, partyB = {}, {}
  local combinedParty = {}
  local half = 0
  local foeAInfo, foeBInfo = {}, {}
  local nameA, nameB = "", ""
  local defeatTextA, defeatTextB = nil, nil

  if inPyramid then
    local Rse = require("src.core.game3.rse.init")
    sess = Rse.session()
    D = require("src.core.game3.rse.frontier.data")
    local F_FACILITY = D.FACILITY
    tidA = Pyramid.localIdToTrainerId(sess, a.eo.localId)
    tidB = Pyramid.localIdToTrainerId(sess, b.eo.localId)
    sess.frontierOpponentA = tidA
    sess.frontierOpponentB = tidB
    D.fillTrainerParty(sess, tidA, 0, 1, partyA, { facility = F_FACILITY.PYRAMID })
    D.fillTrainerParty(sess, tidB, 0, 1, partyB, { facility = F_FACILITY.PYRAMID })
    for _, m in ipairs(partyA) do combinedParty[#combinedParty + 1] = m end
    half = #combinedParty
    for _, m in ipairs(partyB) do combinedParty[#combinedParty + 1] = m end
    foeAInfo = D.trainerClass(sess, tidA, F_FACILITY.PYRAMID) or {}
    foeBInfo = D.trainerClass(sess, tidB, F_FACILITY.PYRAMID) or {}
    nameA = D.trainerName(sess, tidA, F_FACILITY.PYRAMID) or ""
    nameB = D.trainerName(sess, tidB, F_FACILITY.PYRAMID) or ""
    defeatTextA = Pyramid.speech(sess, tidA, 1)
    defeatTextB = Pyramid.speech(sess, tidB, 1)
  else
    tidA = TrainerSight.getTrainerId(a.eo)
    tidB = TrainerSight.getTrainerId(b.eo)
  end

  local rowA, rowB = battleRow(a.eo), battleRow(b.eo)
  TrainerSight._pair = { a = tidA, b = tidB }

  local function finishBattle(result)
    local store = Sp and Sp.store
    local ctx = Sp and Sp.vm and Sp.vm.ctx
    TrainerSight._pair = nil
    F.locked = false
    a.eo.frozen, b.eo.frozen = false, false
    if inPyramid then
      Pyramid.markBattled(sess, tidA, a.eo.localId)
      Pyramid.markBattled(sess, tidB, b.eo.localId)
      local N = require("src.core.game3.scripting.natives")
      sess.battleOutcome = N.outcome_to_code(result or "win")
      return
    end
    if result == "lose" or result == "whiteout" or result == "blackout" then return end
    -- pokeemerald/src/battle_setup.c:1245
    for _, tid in ipairs({ tidB, tidA }) do
      local fid = Flags.trainerFlagId(tid)
      if store then Flags.setFlag(store, ctx, fid, true) end
      local a2 = Sp and Sp.vm and Sp.vm.adapters
      if a2 and a2.onFlagChanged then a2.onFlagChanged(fid, true) end
    end
    -- pokeemerald/src/battle_setup.c:1313
    TrainerSight.retScriptCount = 2
    TrainerSight.checkTrainerB = false
    local modeB = tonumber(rowB and rowB.type) or 0
    TrainerSight.trainerBRet = rowB and (modeB == 1 or modeB == 2) and rowB.eventScript or nil
    -- pokeemerald/src/battle_setup.c:1412
    for i, pick in ipairs({ { rowA, a.eo }, { rowB, b.eo } }) do
      local row, eo = pick[1], pick[2]
      local mode = tonumber(row and row.type) or 0
      if row and row.eventScript and (mode == 1 or mode == 2) and Sp and Sp.startScript then
        -- pokeemerald/data/scripts/trainer_script.inc:13
        if i == 2 then TrainerSight.retScriptCount = 0 end
        Sp.startScript(row.eventScript, eo.localId)
        return
      end
    end
  end

  local function startBattle()
    local Runtime = package.loaded["src.core.game3.runtime"] or require("src.core.game3.runtime")
    local foe
    local battleOpts
    if inPyramid then
      foe = {
        party = combinedParty,
        trainerId = tidA,
        trainerClass = foeAInfo.class,
        trainerClassName = foeAInfo.className,
        trainerName = nameA,
        trainerPicId = foeAInfo.pic,
      }
      battleOpts = {
        wild = false,
        trainerId = tidA,
        trainerIdB = tidB,
        twoOpponents = true,
        double = true,
        frontierFoeHalf = half,
        pyramid = true,
        frontier = true,
        frontierTrainer = { class = foeAInfo.class, className = foeAInfo.className, name = nameA, pic = foeAInfo.pic },
        frontierTrainerB = { class = foeBInfo.class, className = foeBInfo.className, name = nameB, pic = foeBInfo.pic },
        defeatText = defeatTextA,
        defeatTextB = defeatTextB,
        transitionId = D and D.specialTransition(sess, "B_PYRAMID", combinedParty) or nil,
        done = finishBattle,
      }
    else
      local okT, Trainers = pcall(require, "src.core.game3.scripting.trainers")
      foe = okT and Trainers.foeFromId(tidA)
      local dlgA, dlgB = Trainers.dialogs(tidA) or {}, Trainers.dialogs(tidB) or {}
      local function text(row, key, dlg)
        if row and row[key] and Sp and Sp.vm and Sp.vm.getText then
          local t = Sp.vm:getText(row[key])
          if t then return t end
        end
        return dlg
      end
      battleOpts = {
        wild = false,
        trainerId = tidA,
        trainerIdB = tidB,
        twoOpponents = true,
        double = true,
        defeatText = text(rowA, "defeatText", dlgA.defeat),
        defeatTextB = text(rowB, "defeatText", dlgB.defeat),
        done = finishBattle,
      }
    end
    -- pokeemerald/src/battle_setup.c:1272
    local ok, err = require("src.core.game3.battle_bridge").start(Runtime._mod, game or Runtime._game, foe, battleOpts)
    if not ok then
      print("[game3/trainer_sight] two-trainer battle did not start: " .. tostring(err))
      finishBattle("lose")
    end
  end

  local function showIntroA(onDone)
    if inPyramid then
      local introA = Pyramid.speech(sess, tidA, 0)
      require("src.ui.game3.hud").openMessage(nil, introA, { done = onDone })
    else
      introSpeech(a.eo, tidA, rowA, onDone)
    end
  end

  local function showIntroB(onDone)
    if inPyramid then
      local introB = Pyramid.speech(sess, tidB, 0)
      require("src.ui.game3.hud").openMessage(nil, introB, { done = onDone })
    else
      introSpeech(b.eo, tidB, rowB, onDone)
    end
  end

  if inPyramid then
    local Audio = require("src.core.game3.audio")
    Audio.playSong(Pyramid.encounterMusic(sess, tidA))
  else
    playEncounterMusic(tidA, rowA)
  end

  approach(a.eo, a.dist, a.facing, function()
    showIntroA(function()
      -- pokeemerald/src/trainer_see.c:666
      if inPyramid then
        local Audio = require("src.core.game3.audio")
        Audio.playSong(Pyramid.encounterMusic(sess, tidB))
      else
        playEncounterMusic(tidB, rowB)
      end
      approach(b.eo, b.dist, b.facing, function()
        showIntroB(startBattle)
      end)
    end)
  end)
end

--- Main line of sight check.
-- @param game game instance
-- @param specificTrainer optional specific EventObject to check (e.g. from spinning NPC turn update)
-- @return boolean true if an encounter was triggered
local approachFound = {}

function TrainerSight.check(game, specificTrainer)
  local F = Field()
  if F.locked then return false end

  local P = Player()
  if P.moving then return false end

  local Warp = package.loaded["src.core.game3.warp"]
  if Warp and Warp.isBusy and Warp.isBusy() then return false end

  local Runtime = package.loaded["src.core.game3.runtime"]
  if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return false end

  local Sp = Space()
  if Sp and Sp.vm and Sp.vm.isRunning and Sp.vm:isRunning() then return false end

  local Message = package.loaded["src.ui.game3.message"]
  if Message and Message.isOpen and Message.isOpen() then return false end

  local Battle = package.loaded["src.core.game3.battle"]
  if Battle and Battle.isActive and Battle.isActive() then return false end

  local store = (Sp and Sp.store) or Flags.newStore()
  local ctx = (Sp and Sp.vm and Sp.vm.ctx) or Ctx.new()

  local Objs = Objects()

  if specificTrainer then
    local eo = specificTrainer
    -- src/trainer_see.c:94
    if Objs.find(eo.localId) ~= eo then return false end
    if eo.visible and not eo.hidden and not eo.scriptBusy and not eo.frozen then
      local sight = tonumber(eo.sight or (eo.def and (eo.def.sight or eo.def.trainerRange))) or 0
      if sight > 0 and TrainerSight.isTrainerType(eo)
        and not TrainerSight.isDefeated(eo, store, ctx) then
        local spotted, dist = TrainerSight.checkLineOfSight(eo, P, game)
        if spotted and not TrainerSight.blockedByDoubles(eo) then
          TrainerSight.engage(game, eo, dist)
          return true
        end
      end
    end
    return false
  end

  local order = Objs._order or {}
  if twoTrainerApproach() then
    -- pokeemerald/src/trainer_see.c:191
    local found = approachFound
    for i = #found, 1, -1 do found[i] = nil end
    local doubles = canDouble()
    for _, lid in ipairs(order) do
      local eo = Objs.find(lid)
      if eo and eo ~= P and eo.visible and not eo.hidden and not eo.scriptBusy and not eo.frozen then
        local sight = tonumber(eo.sight or (eo.def and (eo.def.sight or eo.def.trainerRange))) or 0
        if sight > 0 and TrainerSight.isTrainerType(eo) and not TrainerSight.isDefeated(eo, store, ctx) then
          local spotted, dist, facing = TrainerSight.checkLineOfSight(eo, P, game)
          local isDouble = spotted and DOUBLE_TYPES[TrainerSight.battleType(eo) or 0]
          if spotted and not (isDouble and not doubles) then
            found[#found + 1] = { eo = eo, dist = dist, facing = facing }
            if isDouble or #found > 1 or not doubles then break end
          end
        end
      end
    end
    -- pokeemerald/src/trainer_see.c:225
    TrainerSight._approached = found[1] and found[1].eo or nil
    if #found == 1 then
      TrainerSight.engage(game, found[1].eo, found[1].dist, found[1].facing)
      return true
    elseif #found == 2 then
      TrainerSight.engagePair(game, found[1], found[2])
      return true
    end
    return false
  end

  -- Simultaneous Spot Prioritization: iterate candidates in strict ascending localId order
  for _, lid in ipairs(order) do
    local eo = Objs.find(lid)
    if eo and eo ~= P and eo.visible and not eo.hidden and not eo.scriptBusy and not eo.frozen then
      local sight = tonumber(eo.sight or (eo.def and (eo.def.sight or eo.def.trainerRange))) or 0
      if sight > 0 and TrainerSight.isTrainerType(eo)
        and not TrainerSight.isDefeated(eo, store, ctx) then
        local spotted, dist = TrainerSight.checkLineOfSight(eo, P, game)
        if spotted and not TrainerSight.blockedByDoubles(eo) then
          -- Immediately engage and break iterator to suppress any other simultaneous spots
          TrainerSight.engage(game, eo, dist)
          return true
        end
      end
    end
  end

  return false
end

return TrainerSight
