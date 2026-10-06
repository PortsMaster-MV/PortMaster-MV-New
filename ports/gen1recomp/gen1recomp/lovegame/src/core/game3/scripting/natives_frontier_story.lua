local Rse = require("src.core.game3.rse.init")

local Story = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_RESULT = 0x800D

-- pokeemerald/include/constants/global.h:34
local MULTI_PARTY_SIZE = 3
local MAX_FRONTIER_PARTY_SIZE = 4
-- pokeemerald/include/constants/party_menu.h:58
local PARTY_MENU_TYPE_CHOOSE_HALF = 4

local function natives()
  return require("src.core.game3.scripting.natives")
end

local function bp(sess)
  return require("src.core.game3.battle.profile").get(sess or Rse.session())
end

local function consts(sess)
  local Constants = require("src.core.game3.constants")
  return Constants.of(Constants.versionOf(sess or Rse.session()))
end

local function log(adapters, msg)
  msg = "[game3] " .. msg
  if adapters and adapters.log then adapters.log(msg) else print(msg) end
end

local function deep_copy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = deep_copy(x) end
  return out
end

local function tick_vm()
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.vm then Space.vm:tick() end
end

local function frontier(sess)
  sess.frontier = sess.frontier or {}
  sess.frontier.selectedPartyMons = sess.frontier.selectedPartyMons or { 0, 0, 0, 0 }
  return sess.frontier
end

local function selected_order(sess)
  sess.selectedOrderFromParty = sess.selectedOrderFromParty or { 0, 0, 0, 0 }
  return sess.selectedOrderFromParty
end

-- pokeemerald/src/load_save.c:160
function Story.savePlayerParty(sess)
  sess = sess or Rse.session()
  if not sess then return nil end
  local saved = {}
  for i, mon in ipairs(sess.party or {}) do saved[i] = deep_copy(mon) end
  sess.savedPlayerParty = saved
  return saved
end

-- pokeemerald/src/load_save.c:170
function Story.loadPlayerParty(sess)
  sess = sess or Rse.session()
  local saved = sess and sess.savedPlayerParty
  if type(saved) ~= "table" then return nil end
  local party = {}
  for i, mon in ipairs(saved) do party[i] = deep_copy(mon) end
  sess.party = party
  return party
end

-- pokeemerald/src/party_menu.c:5587
local function entry_eligible(mon)
  return type(mon) == "table" and not (mon.isEgg or mon.egg) and (tonumber(mon.hp) or 0) ~= 0
    and (tonumber(mon.species or mon.speciesId) or 0) ~= 0
end

function Story.setSelectedOrder(sess, picks)
  local order = selected_order(sess)
  for i = 1, MAX_FRONTIER_PARTY_SIZE do order[i] = 0 end
  local n = 0
  local list = type(picks) == "table" and picks or (type(picks) == "number" and { picks + 1 }) or {}
  for _, slot in ipairs(list) do
    slot = math.floor(tonumber(slot) or 0)
    local dup = false
    for i = 1, n do if order[i] == slot then dup = true end end
    if n < MULTI_PARTY_SIZE and not dup and entry_eligible(sess.party and sess.party[slot]) then
      n = n + 1
      order[n] = slot
    end
  end
  return order
end

-- pokeemerald/src/script_pokemon_util.c:209
function Story.reducePartyToSelected(sess)
  local order = selected_order(sess)
  local party = {}
  for i = 1, MAX_FRONTIER_PARTY_SIZE do
    local slot = order[i]
    if slot and slot ~= 0 and sess.party[slot] then party[#party + 1] = sess.party[slot] end
  end
  sess.party = party
  return party
end

-- pokeemerald/src/frontier_util.c:907
function Story.saveSelectedParty(sess)
  local saved = sess.savedPlayerParty
  if type(saved) ~= "table" then return end
  local sel = frontier(sess).selectedPartyMons
  for i = 1, MAX_FRONTIER_PARTY_SIZE do
    local slot = tonumber(sel[i]) or 0
    if slot >= 1 and slot <= 6 and sess.party[i] then saved[slot] = deep_copy(sess.party[i]) end
  end
end

-- pokeemerald/src/battle_tower.c:2969
function Story.stevenParty(sess)
  local Prize = require("src.core.game3.battle.prize")
  local Party = require("src.core.game3.party")
  local Pokemon = require("src.core.game3.pokemon")
  local Trainers = require("src.core.game3.scripting.trainers")
  local cfg = bp(sess).steven
  local C = consts(sess)
  local steven = Trainers.info(C:require("trainers", cfg.partner)) or {}
  local rows = Prize.rseData().stevenMons
  local out = {}
  local STAT = { "hp", "atk", "def", "spe", "spa", "spd" }
  for i, row in ipairs(rows) do
    local tmp = { party = {}, name = steven.name, trainerId = cfg.otId }
    local _, _, mon = Party.giveMon(tmp, row.species, row.level)
    -- pokeemerald/src/battle_tower.c:2985
    mon.personality = i - 1
    mon.nature = Pokemon.natureId and Pokemon.natureId(mon.personality) or ((i - 1) % 25)
    mon.gender = Pokemon.gender and Pokemon.gender(row.species, mon.personality) or mon.gender
    mon.ability = Pokemon.abilityId and Pokemon.abilityId(row.species, mon.personality) or mon.ability
    mon.abilityId = mon.ability
    local ivs, evs = {}, {}
    for s, key in ipairs(STAT) do
      ivs[key] = row.fixedIV
      evs[key] = row.evs[s] or 0
    end
    mon.ivs, mon.evs = ivs, evs
    local moves, pp, maxPp = {}, {}, {}
    for m, mv in ipairs(row.moves) do
      moves[m] = mv.id
      maxPp[m] = Pokemon.movePp and Pokemon.movePp(mv.id) or 5
      pp[m] = maxPp[m]
    end
    mon.moves, mon.pp, mon.maxPp = moves, pp, maxPp
    mon.otName, mon.ot, mon.otId, mon.otGender = steven.name, steven.name, cfg.otId, 0
    mon.otSecretId = nil
    Pokemon.applyStats(mon)
    mon.hp = mon.maxHp
    mon.stevenPartner = true
    out[i] = mon
  end
  return out
end

local function start_battle(ctx, adapters, foe, opts, onResult)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local BattleBridge = require("src.core.game3.battle_bridge")
  return natives().yieldHost(ctx, adapters, function(done)
    opts.done = function(result)
      if onResult then onResult(result) end
      done()
      tick_vm()
    end
    local startFn = opts.wild and BattleBridge.startWild or BattleBridge.start
    local ok, err = startFn(Runtime and Runtime._mod, Runtime and Runtime._game, foe, opts)
    if not ok then
      log(adapters, "special battle did not start (" .. tostring(err) .. ")")
      if onResult then onResult(nil) end
      done()
    end
  end)
end

local function set_outcome(ctx, result)
  local code = natives().outcome_to_code(result or "win")
  if ctx then ctx.lastBattleOutcome = code end
  return code
end

-- pokeemerald/src/battle_setup.c:513
function Story.legendaryOpts(sess, species)
  local p = bp(sess)
  local C = consts(sess)
  local name = C:name("species", species, "SPECIES_")
  local row = p.legendary and (p.legendary[name] or p.legendary[p.legendary.default])
  if not row then error("battle profile has no legendary row for " .. tostring(name)) end
  local o = {
    wild = true, legendary = true,
    transitionId = C:require("battle", row.transition),
    song = require("src.core.game3.battle.profile").song(p, row.song),
  }
  if row.kind then o[row.kind] = true end
  return o
end

-- pokeemerald/src/battle_setup.c:569
function Story.regiOpts(sess, species)
  local p = bp(sess)
  local C = consts(sess)
  local name = C:name("species", species, "SPECIES_")
  return {
    wild = true, legendary = true, regi = true,
    transitionId = C:require("battle", p.regi[name] or p.regi.default),
    song = require("src.core.game3.battle.profile").song(p, p.regi.song),
  }
end

local function wild_special(ctx, adapters, buildOpts)
  local Enc = require("src.core.game3.encounters")
  local foe = Enc.takePendingWild()
  if not foe then
    log(adapters, "legendary special with no setwildbattle mon")
    return false
  end
  local sess = Rse.session()
  local opts = buildOpts(sess, tonumber(foe.species))
  foe.legendary = true
  return start_battle(ctx, adapters, foe, opts, function(result)
    set_outcome(ctx, result)
  end)
end

-- pokeemerald/src/field_specials.c:1423
function Story.wallyZigzagoon(sess)
  local Party = require("src.core.game3.party")
  local Pokemon = require("src.core.game3.pokemon")
  local C = consts(sess)
  local tmp = { party = {}, name = sess.name, trainerId = sess.trainerId, secretId = sess.secretId, gender = sess.gender }
  local species = C:require("species", "SPECIES_ZIGZAGOON")
  local _, _, mon = Party.giveMon(tmp, species, 7)
  -- pokeemerald/src/field_specials.c:1428
  mon.abilityNum = 1
  local pair = Pokemon.abilities and Pokemon.abilities(species) or {}
  mon.ability = pair[2] or 0
  mon.abilityId = mon.ability
  local tackle = C:require("moves", "MOVE_TACKLE")
  mon.moves = { tackle }
  mon.maxPp = { Pokemon.movePp and Pokemon.movePp(tackle) or 35 }
  mon.pp = { mon.maxPp[1] }
  sess.party = sess.party or {}
  sess.party[1] = mon
  return mon
end

-- pokeemerald/src/battle_tower.c:2122
function Story.doStevenBattle(ctx, adapters)
  local sess = Rse.session()
  local p = bp(sess)
  local C = consts(sess)
  local Trainers = require("src.core.game3.scripting.trainers")
  local half = #(sess.party or {})
  -- pokeemerald/src/battle_tower.c:2124
  for _, mon in ipairs(Story.stevenParty(sess)) do sess.party[#sess.party + 1] = mon end
  local tidA = C:require("trainers", p.steven.opponentA)
  local tidB = C:require("trainers", p.steven.opponentB)
  local foe = Trainers.foeFromId(tidA)
  return start_battle(ctx, adapters, foe, {
    wild = false,
    trainerId = tidA,
    twoOpponents = true,
    trainerIdB = tidB,
    partner = true,
    playerHalf = half,
    partnerTrainerId = C:require("trainers", p.steven.partner),
    partnerBackPic = "steven",
    -- pokeemerald/src/battle_ai_script_commands.c:290
    trainerItems = { 0, 0, 0, 0 },
    scriptedLoss = true,
    transitionId = C:require("battle", p.steven.transition),
  }, function(result)
    local code = set_outcome(ctx, result)
    -- pokeemerald/src/battle_main.c:5228
    Rse.setSpecialVar(ctx, VAR_RESULT, code)
  end)
end

Story.BY_NAME = {
  -- pokeemerald/src/load_save.c:160
  SavePlayerParty = function()
    Story.savePlayerParty()
    return false
  end,
  -- pokeemerald/src/load_save.c:170
  LoadPlayerParty = function()
    Story.loadPlayerParty()
    return false
  end,
  -- pokeemerald/src/field_specials.c:1423
  LoadWallyZigzagoon = function()
    local sess = Rse.session()
    if sess then Story.wallyZigzagoon(sess) end
    return false
  end,
  -- pokeemerald/src/battle_setup.c:480
  StartWallyTutorialBattle = function(ctx, adapters)
    local sess = Rse.session()
    local C = consts(sess)
    local foe = { species = C:require("species", "SPECIES_RALTS"), level = 5, gender = "M" }
    return start_battle(ctx, adapters, foe, {
      wild = true,
      tutorialKind = "wally",
      transitionId = C:require("battle", "B_TRANSITION_SLICE"),
    }, function(result) set_outcome(ctx, result) end)
  end,
  -- pokeemerald/src/battle_setup.c:513
  BattleSetup_StartLegendaryBattle = function(ctx, adapters)
    return wild_special(ctx, adapters, Story.legendaryOpts)
  end,
  -- pokeemerald/src/battle_setup.c:569
  StartRegiBattle = function(ctx, adapters)
    return wild_special(ctx, adapters, Story.regiOpts)
  end,
  -- pokeemerald/src/battle_setup.c:552
  StartGroudonKyogreBattle = function(ctx, adapters)
    return wild_special(ctx, adapters, function(sess)
      local p = bp(sess)
      return {
        wild = true, legendary = true, kyogreGroudon = true,
        transitionId = consts(sess):require("battle", p.kyogreGroudon.transition),
        song = require("src.core.game3.battle.profile").song(p, p.kyogreGroudon.song),
      }
    end)
  end,
  -- pokeemerald/src/battle_setup.c:501
  BattleSetup_StartLatiBattle = function(ctx, adapters)
    return wild_special(ctx, adapters, function()
      return { wild = true, legendary = true }
    end)
  end,
  -- pokeemerald/src/roamer.c:108
  InitRoamer = function(ctx)
    local sess = Rse.session()
    if sess then require("src.core.game3.roamer").initRse(sess, Rse.specialVar(ctx, VAR_0x8004) ~= 0) end
    return false
  end,
  -- pokeemerald/src/safari_zone.c:55
  EnterSafariMode = function()
    require("src.core.game3.safari").enter(Rse.session())
    return false
  end,
  -- pokeemerald/src/safari_zone.c:66
  ExitSafariMode = function()
    require("src.core.game3.safari").exit(Rse.session())
    return false
  end,
  -- pokeemerald/src/script_pokemon_util.c:166
  ChooseHalfPartyForBattle = function(ctx, adapters)
    local sess = Rse.session()
    Story.setSelectedOrder(sess, nil)
    local picked
    local function settle()
      local order = Story.setSelectedOrder(sess, picked)
      -- pokeemerald/src/script_pokemon_util.c:173
      Rse.setSpecialVar(ctx, VAR_RESULT, (order[1] ~= 0) and 1 or 0)
    end
    if not (adapters and adapters.chooseParty) then
      settle()
      return false
    end
    local okF, Fade = pcall(require, "src.ui.game3.fade")
    if okF and Fade and Fade.clear then Fade.clear() end
    local yielded = natives().yieldHost(ctx, adapters, function(done)
      adapters.chooseParty({
        menuType = PARTY_MENU_TYPE_CHOOSE_HALF,
        mode = "choose_multi",
        count = MULTI_PARTY_SIZE,
        -- pokeemerald/src/party_menu.c:5714
        min = 1,
      }, function(chosen)
        picked = chosen
        done()
      end)
    end)
    if not yielded then
      settle()
      return false
    end
    local prev = ctx.nativePoll
    ctx.nativePoll = function()
      if prev and not prev() then return false end
      settle()
      return true
    end
    return true
  end,
  -- pokeemerald/src/script_pokemon_util.c:209
  ReducePlayerPartyToSelectedMons = function()
    local sess = Rse.session()
    if sess then Story.reducePartyToSelected(sess) end
    return false
  end,
  -- pokeemerald/src/frontier_util.c:787
  CallFrontierUtilFunc = function(ctx, adapters)
    return require("src.core.game3.scripting.natives_frontier").callUtil(ctx, adapters)
  end,
  -- pokeemerald/src/battle_tower.c:2007
  DoSpecialTrainerBattle = function(ctx, adapters)
    return require("src.core.game3.scripting.natives_frontier").doSpecialTrainerBattle(ctx, adapters)
  end,
  -- pokeemerald/src/post_battle_event_funcs.c:88
  SetCB2WhiteOut = function()
    local sess = Rse.session()
    local Runtime = package.loaded["src.core.game3.runtime"]
    local game = Runtime and Runtime._game
    local BattleBridge = require("src.core.game3.battle_bridge")
    -- pokeemerald/src/overworld.c:361
    BattleBridge.applyWhiteoutMoneyLoss(sess, game and game.save)
    require("src.core.game3.field").respawnAtHeal()
    return false
  end,
}

local FRLG_OWNER = {
  InitRoamer = "natives_events", EnterSafariMode = "natives_events", ExitSafariMode = "natives_events",
  StartGroudonKyogreBattle = "natives", StartRegiBattle = "natives",
}

for name, fn in pairs(Story.BY_NAME) do
  Story.BY_NAME[name] = function(ctx, adapters)
    if Rse.isRse() then return fn(ctx, adapters) end
    local owner = FRLG_OWNER[name]
    local mod = owner and require("src.core.game3.scripting." .. owner)
    local other = mod and ((mod.BY_NAME and mod.BY_NAME[name]) or (mod.CORE and mod.CORE[name]))
    if other then return other(ctx, adapters) end
    return false
  end
end

return Story
