local T = require("src.core.game3.rse.battle_tower_rs")
local Rse = require("src.core.game3.rse.init")
local N = {BY_NAME = {}}
local B = N.BY_NAME
local function session() return (assert(Rse.session(), "native RS Tower session missing")) end
local function natives() return require("src.core.game3.scripting.natives") end
local function var(ctx, id) return Rse.specialVar(ctx, id) end
local function result(ctx, v) Rse.setSpecialVar(ctx, 0x800D, v); return false, v end
local function stringVar(ctx, adapters, id, text)
  if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[id] = text end
  if adapters and adapters.setStringVar then adapters.setStringVar(id, text) end
end
local function abort(ctx, adapters, message)
  return require("src.core.game3.rse.frontier.util").saveFromNative(ctx, adapters, session(), function() return false, message end)
end

B.sub_8134548 = function() T.init(session()); return false end
B.SetBattleTowerProperty = function(ctx, adapters)
  local op = var(ctx, 0x8004)
  local value = T.property(session(), op, var(ctx, 0x8005), true)
  if value ~= nil then
    if op == 6 then stringVar(ctx, adapters, 1, tostring(value)) end
    return result(ctx, value)
  end
  return false
end
B.BattleTowerUtil = function(ctx)
  local value = T.property(session(), var(ctx, 0x8004), 0, false)
  if value ~= nil then return result(ctx, value) end
  return false
end
B.CheckPartyBattleTowerBanlist = function(ctx, adapters)
  local s, level = session(), var(ctx, 0x800D)
  local fail = T.entryCount(s, level) < 3
  Rse.setSpecialVar(ctx, 0x8004, fail and 1 or 0)
  if not fail then local b = T.state(s); b.battleTowerLevelType = level % 2; return false end
  local Pokemon = require("src.core.game3.pokemon")
  local Dex, data, caught, out = require("src.core.game3.dex"), T.pack(), {}, {}
  for _, sp in ipairs(data.bannedSpecies) do
    if sp ~= 65535 and Dex.isCaught(s.dex, sp) then caught[#caught + 1] = sp end
  end
  for i, sp in ipairs(caught) do
    out[#out + 1] = data.strings[i == #caught and "format3" or "format4"]
    if i % 2 == 0 then out[#out + 1] = data.strings[i == 2 and "format7" or "format6"] end
    out[#out + 1] = Pokemon.name(sp)
  end
  if #caught == 0 then out = {data.strings.format5, data.strings.format8}
  else out[#out + 1] = data.strings[#caught % 2 == 1 and "format6" or "format5"]; out[#out + 1] = data.strings.format9 end
  stringVar(ctx, adapters, 1, table.concat(out)); return false
end
B.ChooseBattleTowerPlayerParty = function(ctx, adapters)
  local s = session(); local b = T.state(s); local finished = false
  if adapters and adapters.closeMessage then adapters.closeMessage() end
  local PartyMenu = require("src.ui.game3.party_menu")
  local Runtime = require("src.core.game3.runtime")
  return natives().yieldHost(ctx, adapters, function(done)
    local function cancel()
      if finished then return end
      finished = true; T.selectOrder(s, {0, 0, 0})
      require("src.core.game3.scripting.natives_frontier_story").loadPlayerParty(s)
      result(ctx, 0); done()
    end
    PartyMenu.show(s.party, nil, {mode = "choose_multi", count = 3, session = s,
      chooseFullMessage = T.pack().strings.full, immediateChooseCancel = true,
      eligible = function(_, mon) return T.eligible(mon, b.battleTowerLevelType) end,
      validateChosen = function(order)
        local code = T.validateParty(s, order, b.battleTowerLevelType)
        return code and T.pack().strings["entry" .. code] or nil
      end,
      onSelect = function(order)
        if not order then cancel(); return end
        finished = true; T.reduceParty(s, order); result(ctx, 1); done()
      end,
      onClose = function()
        if not Runtime.defer(cancel) then
          require("src.core.game3.task").spawn(function() cancel(); return true end)
        end
      end})
  end)
end
B.ReducePlayerPartyToThree = function() T.reduceParty(session()); return false end
B.SetBattleTowerParty = function() T.setParty(session()); return false end
B.ChooseNextBattleTowerTrainer = function(ctx)
  T.chooseTrainer(session())
  return result(ctx, T.eReader(session()) and 0 or 1)
end
local function greeting(ctx, adapters, trainer)
  local words = trainer and trainer.greeting or {}
  stringVar(ctx, adapters, 4, T.message(words))
  return false
end
B.PrintBattleTowerTrainerGreeting = function(ctx, adapters) return greeting(ctx, adapters, T.trainer(session())) end
B.PrintEReaderTrainerGreeting = function(ctx, adapters) return greeting(ctx, adapters, T.eReader(session())) end
B.ValidateEReaderTrainer = function(ctx) return result(ctx, T.eReader(session()) and 0 or 1) end
B.DetermineBattleTowerPrize = function() T.determinePrize(session()); return false end
B.GiveBattleTowerPrize = function(ctx, adapters)
  local s = session(); local ok = T.givePrize(s)
  if ok then stringVar(ctx, adapters, 1, require("src.core.game3.items").displayName(T.state(s).prizeItem)) end
  return result(ctx, ok and 1 or 0)
end
B.AwardBattleTowerRibbons = function(ctx) return result(ctx, T.ribbons(session())) end
B.GetBestBattleTowerStreak = function() return false, tonumber((session().gameStats or {})[32]) or 0 end
B.SaveBattleTowerProgress = function(ctx, adapters)
  local s = session(); local old, oldStats = T.copy(s.battleTower), T.copy(s.gameStats)
  return require("src.core.game3.rse.frontier.util").saveFromNative(ctx, adapters, s, function()
    T.prepareSave(s, var(ctx, 0x8004), ctx.lastBattleOutcome or s.battleOutcome or 0)
    local ok, message = T.persist(s)
    if not ok then s.battleTower, s.gameStats = old, oldStats end
    return ok, message
  end)
end
B.BattleTower_SoftReset = function(ctx, adapters)
  local Runtime = require("src.core.game3.runtime")
  if not Runtime._game then return abort(ctx, adapters, "The saved Battle Tower challenge cannot be resumed.") end
  Runtime._game.softResetRequested = true; return false
end
B.TryEnableBravoTrainerBattleTower = function()
  local s = session(); local b = T.state(s)
  if b.var_4AE[1] == 1 or b.var_4AE[2] == 1 then
    Rse.setVar("VAR_BRAVO_TRAINER_BATTLE_TOWER_ON", 0, s)
    local Objects = require("src.core.game3.objects")
    local object = Objects.find(5)
    if object then
      object.hidden, object.visible = true, false
      if object.def then object.def.hidden = true end
      Objects._tracks[5] = nil
    end
  end
  return false
end
B.TryInitBattleTowerAwardManObjectEvent = function()
  local s = session()
  -- field_specials.c:1875
  if not Rse.flag("FLAG_HIDE_AWARD_MAN_BATTLE_TOWER", s) then require("src.core.game3.objects").addObject(6) end
  return false
end
B.StartSpecialBattle = function(ctx, adapters)
  local s, kind = session(), var(ctx, 0x8004)
  if kind == 1 then return require("src.core.game3.rse.secret_base_battle_rs").start(ctx, adapters, s) end
  if kind ~= 0 and kind ~= 2 then return abort(ctx, adapters, "This Ruby and Sapphire special battle is not implemented.") end
  if kind == 2 and not T.eReader(s) then return abort(ctx, adapters, "The e-Reader Trainer is invalid.") end
  local trainer = assert(T.trainer(s, kind == 2 and 200 or nil), "RS Tower trainer missing")
  local party = T.fillParty(s, kind == 2 and 200 or nil)
  local info = assert(T.pack().classInfo[trainer.trainerClass], "RS Tower facility class missing")
  local lead = party[1]
  local foe = {party = party, trainerName = trainer.name, trainerClass = info.nameId,
    trainerClassName = info.name, trainerPicId = info.pic,
    species = lead.species, level = lead.level, moves = lead.moves, pp = lead.pp}
  local BP = require("src.core.game3.battle.profile")
  local p = BP.get(s)
  local Pokemon = require("src.core.game3.pokemon")
  local playerLevel = 0
  for _, mon in ipairs(s.party or {}) do
    if not Pokemon.isEgg(mon) and Pokemon.speciesOf(mon) and (tonumber(mon.hp) or 0) ~= 0 then playerLevel = tonumber(mon.level) or 0; break end
  end
  local opts = {wild = false, scriptedLoss = true, battleTower = kind == 0 or nil, eReader = kind == 2 or nil,
    -- battle_ai_script_commands.c:337
    aiFlags = T.pack().aiFlags, trainerItems = {0, 0, 0, 0}, trainerName = trainer.name, trainerPicId = info.pic,
    frontierTrainer = {class = info.nameId, className = info.name, name = trainer.name, pic = info.pic},
    song = BP.battleSong(p, {trainerClass = info.nameId}),
    transitionId = require("src.core.game3.battle_transition_ids_rse").pickSpecial("battle_tower", {enemyLevel = lead.level, playerLevel = playerLevel})}
  s.battleOutcome = 0
  return natives().yieldHost(ctx, adapters, function(done)
    opts.done = function(outcome)
      local code = natives().outcome_to_code(outcome)
      ctx.lastBattleOutcome, s.battleOutcome = code, code
      result(ctx, code)
      local battle = package.loaded["src.core.game3.battle"]
      local st = battle and battle.getState and battle.getState()
      local enemy, player = st and st.enemy and st.enemy.mon, st and st.player and st.player.mon
      T.setLastBattle(s, {trainerName = trainer.name, opponentSpecies = enemy and Pokemon.speciesOf(enemy) or lead.species,
        playerSpecies = player and Pokemon.speciesOf(player) or Pokemon.speciesOf(s.party[1]),
        playerNickname = player and Pokemon.displayMonName(player) or Pokemon.displayMonName(s.party[1])})
      if kind == 2 then
        local words = trainer[code == 1 and "farewellPlayerWon" or "farewellPlayerLost"] or {}
        local text = T.message(words)
        stringVar(ctx, adapters, 4, text)
        if adapters and adapters.openMessageAsync then adapters.openMessageAsync(text, done); return end
      end
      done()
    end
    local Runtime = require("src.core.game3.runtime")
    local ok, err = require("src.core.game3.battle_bridge").start(Runtime._mod, Runtime._game, foe, opts)
    if not ok then
      ctx.pc, ctx.stack = nil, {}; if adapters and adapters.log then adapters.log("[game3/rs-tower] battle start failed: " .. tostring(err)) end
      done()
    end
  end)
end
return N
