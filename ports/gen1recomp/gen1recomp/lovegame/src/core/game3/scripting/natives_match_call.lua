local NativesMatchCall = {}

local VAR_0x8004 = 0x8004
-- pokeemerald/include/constants/script_menu.h:8
local MULTI_B_PRESSED = 127

local function session()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function varId(name, sess)
  return require("src.core.game3.constants").active(sess or session()):var(name)
end

local function MatchCall()
  return require("src.core.game3.rse.match_call")
end

local function Rematch()
  return require("src.core.game3.rse.rematch")
end

local function Flags()
  return require("src.core.game3.scripting.flags")
end

local function specialVar(ctx, id)
  local v = tonumber(Flags().getVar(nil, ctx, id)) or 0
  if v == 0 and ctx and type(ctx.getVar) == "function" then v = tonumber(ctx:getVar(id)) or 0 end
  return v
end

local function setResult(ctx, v)
  local id = varId("VAR_RESULT")
  Flags().setVar(nil, ctx, id, v)
  if ctx and type(ctx.setVar) == "function" then ctx:setVar(id, v) end
end

local function shared(name, fn)
  return function(ctx, adapters, ...)
    local sess = session()
    if not MatchCall().enabled(sess) then
      local core = require("src.core.game3.scripting.natives").CORE[name]
      if core then return core(ctx, adapters, ...) end
      return false
    end
    return fn(ctx, adapters, sess, ...)
  end
end

NativesMatchCall.BY_NAME = {
  -- pokeemerald/src/battle_setup.c:1839
  ShouldTryRematchBattle = shared("ShouldTryRematchBattle", function(ctx, _, sess)
    setResult(ctx, Rematch().shouldTryRematchBattle(sess, ctx.trainerBattleOpponentA or 0) and 1 or 0)
    return false
  end),
  -- pokeemerald/src/battle_setup.c:1847
  IsTrainerReadyForRematch = shared("IsTrainerReadyForRematch", function(ctx, _, sess)
    setResult(ctx, Rematch().isTrainerReadyForRematch(sess, ctx.trainerBattleOpponentA or 0) and 1 or 0)
    return false
  end),
  -- pokeemerald/src/battle_setup.c:1370
  BattleSetup_StartRematchBattle = shared("BattleSetup_StartRematchBattle", function(ctx, adapters, sess)
    -- ShowTrainerIntroSpeech already rendered the rematch intro (pokeemerald/data/scripts/trainer_battle.inc:55).
    if ctx then ctx.trainerIntroShown = nil end
    local trainerId = tonumber(ctx and ctx.trainerBattleOpponentA) or 0
    if trainerId <= 0 or not (adapters and adapters.startTrainerBattle) then return false end
    local Trainers = require("src.core.game3.scripting.trainers")
    local foe = Trainers.foeFromId(trainerId)
    if not foe then foe = { trainerId = trainerId } end
    local battleType = tonumber(ctx and ctx.trainerBattleMode) or 0
    local double = battleType == 4 or battleType == 6 or battleType == 7 or battleType == 8
    local Natives = require("src.core.game3.scripting.natives")
    return Natives.yieldHost(ctx, adapters, function(done)
      adapters.startTrainerBattle(foe, function(result)
        if result ~= "lose" and result ~= "whiteout" and result ~= "blackout" then
          -- pokeemerald/src/battle_setup.c:1351 CB2_EndRematchBattle
          Rematch().onRematchBattleWon(sess, trainerId)
        end
        done()
      end, { trainerId = trainerId, double = double })
    end)
  end),
  -- pokeemerald/src/field_specials.c:3618
  IsTrainerRegistered = function(ctx)
    local sess = session()
    local R = Rematch()
    local idx = R.firstBattleTableId(specialVar(ctx, VAR_0x8004))
    setResult(ctx, (idx >= 0 and R.flag(sess, R.registeredFlagId(sess, idx))) and 1 or 0)
    return false
  end,
  -- pokeemerald/src/battle_setup.c:1235
  GetTrainerFlag = function(ctx)
    local sess = session()
    local localId = specialVar(ctx, varId("VAR_LAST_TALKED"))
    local Pyramid = require("src.core.game3.rse.frontier.pyramid")
    if Pyramid.inPyramid(sess) then
      return false, Pyramid.trainerFlag(sess, localId) and 1 or 0
    end
    local Hill = require("src.core.game3.rse.trainer_hill")
    if Hill.inChallenge(sess) then
      return false, Hill.trainerFlag(sess, localId) and 1 or 0
    end
    local trainerId = tonumber(ctx and ctx.trainerBattleOpponentA) or 0
    local Flags = Flags()
    local id = Flags.trainerFlagId(trainerId)
    return false, Flags.getFlag(sess, ctx, id) and 1 or 0
  end,
  -- pokeemerald/src/pokenav_match_call_data.c:1156
  SetMatchCallRegisteredFlag = function(ctx)
    MatchCall().setRegisteredFlag(session(), specialVar(ctx, VAR_0x8004))
    return false
  end,
  -- pokeemerald/src/script_menu.c:673
  ScriptMenu_CreateStartMenuForPokenavTutorial = function(ctx, adapters)
    local Natives = require("src.core.game3.scripting.natives")
    local sess = session()
    setResult(ctx, 0xFF)
    return Natives.yieldHost(ctx, adapters, function(done)
      local StartMenu = require("src.ui.game3.start_menu")
      local Runtime = package.loaded["src.core.game3.runtime"]
      local game = (sess and sess.game) or (Runtime and Runtime._game)
      StartMenu.show({
        session = sess,
        game = game,
        tutorial = true,
        onTutorialSelect = function(sel)
          setResult(ctx, (sel == nil or sel < 0) and MULTI_B_PRESSED or sel)
          done()
        end,
      })
    end)
  end,
  -- pokeemerald/src/pokenav.c:333
  OpenPokenavForTutorial = function(ctx, adapters)
    local Natives = require("src.core.game3.scripting.natives")
    local sess = session()
    return Natives.yieldHost(ctx, adapters, function(done)
      require("src.ui.game3.rse.pokenav.init").show({ session = sess, tutorial = true, onClose = done })
    end)
  end,
}

pcall(require, "src.core.game3.rse.match_call")

return NativesMatchCall
