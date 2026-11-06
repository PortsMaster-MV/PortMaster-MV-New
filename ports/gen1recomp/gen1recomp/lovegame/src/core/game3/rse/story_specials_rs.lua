local Rse = require("src.core.game3.rse.init")

local Story = {}

local function natives() return require("src.core.game3.scripting.natives") end
local function runtime() return package.loaded["src.core.game3.runtime"] end

local function scratchSession(session, otId)
  local scratch = { party = {}, dex = { seen = {}, owned = {}, caught = {} } }
  if otId then
    scratch.trainerId = otId % 0x10000
    scratch.secretId = math.floor(otId / 0x10000)
  end
  return setmetatable(scratch, { __index = session })
end

-- pokeruby/src/field_specials.c:1738
function Story.putWallyZigzagoon(session)
  session = session or assert(Rse.session(), "RS Wally loaner needs session")
  local Pokemon = require("src.core.game3.pokemon")
  local C = require("src.core.game3.constants").active(session)
  local species = C:require("species", "SPECIES_ZIGZAGOON")
  local ok, _, mon = require("src.core.game3.party").giveMon(scratchSession(session), species, 7)
  assert(ok and mon, "RS Wally loaner creation failed")
  mon.abilityNum = 1
  mon.ability = Pokemon.abilities(species)[2] or 0
  mon.abilityId = mon.ability
  -- pokemon_2.c:779
  mon.moves = { C:require("moves", "MOVE_TACKLE"), 0, 0, 0 }
  for i = 1, 4 do
    mon.pp[i], mon.maxPp[i] = mon.pp[i] or 0, mon.maxPp[i] or 0
  end
  mon.mail, mon.language = 255, 2
  session.party = session.party or {}
  session.party[1] = mon
  return mon
end

-- pokeruby/src/pokemon_1.c:1518
function Story.createWallyRalts(session)
  session = session or assert(Rse.session(), "RS Wally tutorial needs session")
  local Pokemon = require("src.core.game3.pokemon")
  local C = require("src.core.game3.constants").active(session)
  local species = C:require("species", "SPECIES_RALTS")
  assert(Pokemon.speciesMeta(species), "RS Wally Ralts species metadata missing")
  local Rng = require("src.core.game3.rng")
  local otId, personality
  repeat
    otId = Rng.Random32()
    personality = Rng.Random32()
  until Pokemon.gender(species, personality) == "M"
  local ok, _, mon = require("src.core.game3.party").giveMon(scratchSession(session, otId), species, 5, nil,
    { fixedPersonality = personality })
  assert(ok and mon, "RS Wally Ralts creation failed")
  mon.item, mon.heldItem, mon.mail, mon.language = 0, 0, 255, 2
  return mon
end

-- pokeruby/src/battle_setup.c:560
function Story.startWallyTutorial(ctx, adapters)
  local session = assert(Rse.session(), "RS Wally tutorial needs session")
  local foe = Story.createWallyRalts(session)
  local C = require("src.core.game3.constants").active(session)
  local rt = assert(runtime(), "RS Wally tutorial needs runtime")
  return natives().yieldHost(ctx, adapters, function(done)
    local ok, err = require("src.core.game3.battle_bridge").start(rt._mod, rt._game, foe, {
      wild = true, tutorialKind = "wally",
      transitionId = C:require("battle", "B_TRANSITION_SLICE"),
      done = function(result)
        ctx.lastBattleOutcome = natives().outcome_to_code(result or "win")
        done()
        local Space = package.loaded["src.core.game3.scripting.space"]
        if Space and Space.vm then Space.vm:tick() end
      end,
    })
    assert(ok, "RS Wally tutorial battle did not start: " .. tostring(err))
  end)
end

-- pokeruby/src/time_events.c:94
function Story.waitWeather(ctx)
  local engine = assert(require("src.core.game3.weather").rseEngine(), "RS weather engine missing")
  local finished = false
  require("src.core.game3.task").spawn(function()
    if not engine.isWeatherChangeComplete() then return false end
    finished = true
    return true
  end)
  natives().awaitState(ctx, function() return finished end)
  return false
end

-- pokeruby/src/braille_puzzles.c:221
function Story.sealedChamberShake(ctx, long)
  local View = require("src.core.game3.field_view")
  local delay, shakes, pan = 0, 0, long and 2 or 3
  local total, finished = long and 50 or 2, false
  require("src.core.game3.task").spawn(function()
    delay = delay + 1
    if delay == 5 then
      delay, shakes, pan = 0, shakes + 1, -pan
      View.setCameraPanning(0, pan)
      if shakes == total then
        View.setCameraPanning(0, 0)
        finished = true
        return true
      end
    end
    return false
  end)
  natives().awaitState(ctx, function() return finished end)
  return false
end

-- pokeruby/src/braille_puzzles.c:206
function Story.brailleButtonPressed(input, buttonMode)
  if not (input and input.wasPressed) then return false end
  for _, key in ipairs({ "a", "b", "start", "select", "up", "down", "left", "right" }) do
    if input:wasPressed(key) then return true end
  end
  if (buttonMode == 1 or buttonMode == 2) and input:wasPressed("l") then return true end
  return buttonMode == 1 and input:wasPressed("r") == true
end

local function unfreeze(ctx, adapters)
  for lid, snap in pairs(ctx.lockSnapshots or {}) do
    if adapters and adapters.unfreezeLocal then adapters.unfreezeLocal(lid, snap) end
  end
  ctx.lockSnapshots = {}
  ctx.frozen = false
end

local function eraseBraille(ctx, adapters)
  if adapters and adapters.closeMessage then adapters.closeMessage() end
  require("src.ui.game3.braille").hide()
  ctx.messageOpen = false
end

-- pokeruby/src/braille_puzzles.c:147
function Story.brailleWait(ctx, adapters)
  if Rse.flag("FLAG_SYS_BRAILLE_WAIT") then return false end
  local Space = require("src.core.game3.scripting.space")
  local vm = assert(Space.vm and Space.vm.ctx == ctx and Space.vm, "RS braille wait needs the active script VM")
  local openKey = assert(Space.scriptKey("S_OpenRegiceChamber"), "native S_OpenRegiceChamber script missing")
  local state = { phase = 0, timer = 0 }
  require("src.core.game3.task").spawn(function()
    local rt = runtime()
    local input = rt and rt._game and rt._game.input
    local mode = tonumber(require("src.core.game3.options").ensure(Rse.session()).buttonMode) or 0
    local pressed = Story.brailleButtonPressed(input, mode)
    if state.phase == 0 then
      state.timer, state.phase = 7200, 1
    elseif state.phase == 1 then
      if pressed then
        eraseBraille(ctx, adapters)
        local C = require("src.core.game3.constants").active(Rse.session())
        require("src.core.game3.audio").playSe(C:require("songs", "SE_SELECT"))
        state.phase = 2
      else
        state.timer = state.timer - 1
        if state.timer == 0 then
          eraseBraille(ctx, adapters)
          state.phase, state.timer = 3, 30
        end
      end
    elseif state.phase == 2 then
      if not pressed then
        state.timer = state.timer - 1
        if state.timer == 0 then state.phase = 4 end
      else
        unfreeze(ctx, adapters)
        ctx.lockKind = nil
        vm:halt()
        state.phase = 5
      end
    elseif state.phase == 5 then
      require("src.core.game3.field").unlock()
      return true
    elseif state.phase == 3 then
      state.timer = state.timer - 1
      if state.timer == 0 then state.phase = 4 end
    elseif state.phase == 4 then
      unfreeze(ctx, adapters)
      ctx.stateWait, ctx.nativePoll = nil, nil
      assert(vm:start(openKey), "RS Regice chamber continuation did not start")
      return true
    end
    return false
  end, { data = state })
  natives().awaitState(ctx, function() return false end)
  return false
end

-- pokeruby/src/field_control_avatar.c:692
-- field_fadetransition.c:405
function Story.fallWarp(ctx)
  local rt = assert(runtime(), "RS fall warp needs runtime")
  local game = assert(rt._game, "RS fall warp needs game")
  local Player = require("src.core.game3.player")
  local Collision = require("src.core.game3.collision")
  local x, y = tonumber(Player.cellX) or 0, tonumber(Player.cellY) or 0
  local event = Collision.warpAt(x, y)
  local destMap, destX, destY
  if event then
    destMap, destX, destY = Collision.resolveWarpDestination(game, event)
  else
    local dest = Rse.session() and Rse.session().warpDestination
    if dest and dest.map then
      if (tonumber(dest.warpId) or -1) < 0 then
        destMap, destX, destY = dest.map, dest.x, dest.y
      else
        destMap, destX, destY = Collision.resolveWarpDestination(game, {
          destMap = dest.map, destWarp = dest.warpId + 1,
          mapGroup = dest.mapGroup, mapNum = dest.mapNum,
        })
      end
    end
  end
  assert(destMap, "RS fall warp destination missing")
  local Warp = require("src.core.game3.warp")
  assert(Warp.startFall(rt._mod, game, destMap, destX, destY, x, y, { prologue = false }),
    "RS fall warp did not start")
  ctx.warpPending = true
  require("src.core.game3.task").spawn(function()
    if Warp.isBusy() then return false end
    ctx.warpPending = false
    return true
  end)
  return false
end

return Story
