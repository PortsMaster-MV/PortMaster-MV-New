local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")
local RomText = require("src.core.game3.rom_text")

local NativesFrontier = {}

local VAR_0x8004, VAR_0x8005, VAR_0x8006 = Util.VAR_0x8004, Util.VAR_0x8005, Util.VAR_0x8006
local VAR_RESULT = Util.VAR_RESULT
-- pokeemerald/include/constants/script_menu.h:8
local MULTI_B_PRESSED = 127
-- pokeemerald/include/constants/party_menu.h:58
local PARTY_MENU_TYPE_CHOOSE_HALF = 4
-- pokeemerald/include/constants/script_menu.h:6
local MAX_MULTICHOICE_WIDTH = 28
-- pokeemerald/include/constants/script_menu.h:127
local SSTIDAL = { SLATEPORT = 0, BATTLE_FRONTIER = 1, SOUTHERN_ISLAND = 2, NAVEL_ROCK = 3, BIRTH_ISLAND = 4,
  FARAWAY_ISLAND = 5, EXIT = 6, COUNT = 7 }
-- pokeemerald/src/start_menu.c:71
local SAVE_SUCCESS = 1

local F = D.FACILITY
local M = D.MODE

local function sess() return Rse.session() end
local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end
local function setSpecialVar(ctx, id, v) Rse.setSpecialVar(ctx, id, v) end
local function natives() return require("src.core.game3.scripting.natives") end
local function Tower() return require("src.core.game3.rse.frontier.tower") end
local function Tents() return require("src.core.game3.rse.frontier.tents") end
local function Records() return require("src.ui.game3.rse.frontier_records") end
local function story() return require("src.core.game3.scripting.natives_frontier_story") end

local function log(adapters, msg)
  msg = "[game3] " .. msg
  if adapters and adapters.log then adapters.log(msg) else print(msg) end
end

local FUNCS = {}
local U = Util.FUNC

-- pokeemerald/src/frontier_util.c:793
FUNCS[U.GET_STATUS] = function(_, _, s) Util.getChallengeStatus(s) end
-- pokeemerald/src/frontier_util.c:818
FUNCS[U.GET_DATA] = function(ctx, _, s) Util.getData(ctx, s) end
-- pokeemerald/src/frontier_util.c:852
FUNCS[U.SET_DATA] = function(ctx, _, s) Util.setData(ctx, s) end
-- pokeemerald/src/frontier_util.c:887
FUNCS[U.SET_PARTY_ORDER] = function(ctx, _, s) Util.setSelectedPartyOrder(s, specialVar(ctx, VAR_0x8005)) end
-- pokeemerald/src/frontier_util.c:897
FUNCS[U.SOFT_RESET] = function()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  if game then game.softResetRequested = true end
end
-- pokeemerald/src/frontier_util.c:902
FUNCS[U.SET_TRAINERS] = function() end
-- pokeemerald/src/frontier_util.c:907
FUNCS[U.SAVE_PARTY] = function(_, _, s) story().saveSelectedParty(s) end
-- pokeemerald/src/frontier_util.c:919
FUNCS[U.RESULTS_WINDOW] = function(ctx, _, s)
  local mode = specialVar(ctx, VAR_0x8006)
  if mode >= D.MODE_COUNT then mode = 0 end
  Records().showResults(s, specialVar(ctx, VAR_0x8005), mode)
end
-- pokeemerald/src/frontier_util.c:1530
FUNCS[U.CHECK_AIR_TV_SHOW] = function(_, _, s) Util.checkPutTvShowOnAir(s) end
-- pokeemerald/src/frontier_util.c:1650
FUNCS[U.GET_BRAIN_STATUS] = function(ctx, _, s) Util.setResult(ctx, Util.brainStatus(s)) end
-- pokeemerald/src/frontier_util.c:1839
FUNCS[U.IS_BRAIN] = function(ctx, _, s)
  Util.setResult(ctx, tonumber(s.frontierOpponentA) == D.TRAINER_FRONTIER_BRAIN and 1 or 0)
end
-- pokeemerald/src/frontier_util.c:1853
FUNCS[U.GIVE_BATTLE_POINTS] = function(ctx, adapters, s)
  local points = Util.giveBattlePoints(s, tonumber(s.frontierOpponentA) == D.TRAINER_FRONTIER_BRAIN)
  Util.setStringVar(ctx, adapters, 1, tostring(points))
end
-- pokeemerald/src/frontier_util.c:1912
FUNCS[U.GET_FACILITY_SYMBOLS] = function(ctx, _, s)
  Util.setResult(ctx, Util.symbolCount(s, Rse.var("VAR_FRONTIER_FACILITY", s)))
end
-- pokeemerald/src/frontier_util.c:1918
FUNCS[U.GIVE_FACILITY_SYMBOL] = function(_, _, s) Util.giveSymbol(s, Rse.var("VAR_FRONTIER_FACILITY", s)) end
-- pokeemerald/src/frontier_util.c:1927
FUNCS[U.CHECK_BATTLE_TYPE] = function(ctx, _, s)
  local flags = tonumber(s.lastBattleTypeFlags) or 0
  local bit = rawget(_G, "bit") or require("bit")
  Util.setResult(ctx, bit.band(flags, specialVar(ctx, VAR_0x8005)) ~= 0 and 1 or 0)
end
-- pokeemerald/src/frontier_util.c:2010
FUNCS[U.CHECK_INELIGIBLE] = function(ctx, adapters, s)
  local lvlMode = specialVar(ctx, VAR_RESULT)
  local short, names = Util.checkPartyIneligibility(s, lvlMode)
  setSpecialVar(ctx, VAR_0x8004, short and 1 or 0)
  if short then Util.setStringVar(ctx, adapters, 1, names) end
end
-- pokeemerald/src/frontier_util.c:2106
FUNCS[U.CHECK_VISIT_TRAINER] = function(ctx, _, s)
  local e = Util.frontier(s).ereaderTrainer
  Util.setResult(ctx, (type(e) ~= "table" or next(e) == nil) and 1 or 0)
end
-- pokeemerald/src/frontier_util.c:2111
FUNCS[U.INCREMENT_STREAK] = function(_, _, s) Util.incrementWinStreak(s) end
-- pokeemerald/src/frontier_util.c:2159
FUNCS[U.RESTORE_HELD_ITEMS] = function(_, _, s) Util.restoreHeldItems(s) end
-- pokeemerald/src/frontier_util.c:2173
FUNCS[U.SAVE_BATTLE] = function(ctx, adapters, s)
  local impl = Rse.system("recordedBattle")
  local ok = impl and type(impl.moveToSaveData) == "function" and impl.moveToSaveData(s) or false
  if not impl then Rse.missing("recordedBattle", "MoveRecordedBattleToSaveData", adapters and adapters.log) end
  Util.setResult(ctx, ok and 1 or 0)
  Util.frontier(s).disableRecordBattle = 1
end
-- pokeemerald/src/frontier_util.c:2179
FUNCS[U.BUFFER_TRAINER_NAME] = function(ctx, adapters, s)
  local n = specialVar(ctx, VAR_0x8005) == 0 and 1 or 2
  Util.setStringVar(ctx, adapters, n, D.trainerName(s, tonumber(s.frontierOpponentA) or 0))
end
-- pokeemerald/src/frontier_util.c:2192
FUNCS[U.RESET_SKETCH_MOVES] = function(_, _, s) Util.resetSketchedMoves(s) end
-- pokeemerald/src/frontier_util.c:2557
FUNCS[U.SET_BRAIN_OBJECT] = function(_, _, s)
  local facility = Rse.var("VAR_FRONTIER_FACILITY", s)
  s.frontierOpponentA = D.TRAINER_FRONTIER_BRAIN
  Rse.setVar("VAR_OBJ_GFX_ID_0", D.manifest().brainObjEventGfx[facility + 1][1], s)
end
NativesFrontier.FUNCS = FUNCS

-- pokeemerald/src/frontier_util.c:787
function NativesFrontier.callUtil(ctx, adapters)
  local s = sess()
  local id = specialVar(ctx, VAR_0x8004)
  local fn = FUNCS[id]
  if not (s and fn) then
    Rse.missing("frontierUtil", "CallFrontierUtilFunc " .. tostring(id), adapters and adapters.log)
    return false
  end
  return fn(ctx, adapters, s) == true
end

local SB = {
  TOWER = 0, SECRET_BASE = 1, EREADER = 2, DOME = 3, PALACE = 4, ARENA = 5, FACTORY = 6, PIKE_SINGLE = 7,
  STEVEN = 8, PIKE_DOUBLE = 9, PYRAMID = 10,
}
NativesFrontier.SPECIAL_BATTLE = SB

local KIND = {
  [SB.DOME] = { kind = "dome", system = "dome", group = "B_DOME" },
  [SB.PALACE] = { kind = "palace", system = "palace", group = "B_PALACE" },
  [SB.ARENA] = { kind = "arena", system = "arena", group = "B_ARENA" },
  [SB.FACTORY] = { kind = "factory", system = "factory", group = "B_FACTORY" },
  [SB.PIKE_SINGLE] = { kind = "pike", system = "pike", group = "B_PIKE" },
  [SB.PIKE_DOUBLE] = { kind = "pike", system = "pike", group = "B_PIKE", double = true },
  [SB.PYRAMID] = { kind = "pyramid", system = "pyramid", group = "B_PYRAMID" },
}

-- pokeemerald/src/battle_tower.c:2007
local function facilityBattle(ctx, adapters, s, which)
  local row = KIND[which]
  local impl = Rse.system(row.system)
  if impl and type(impl.doSpecialBattle) == "function" then
    return impl.doSpecialBattle(ctx, adapters, s, which)
  end
  local f = Util.frontier(s)
  local tid = tonumber(s.frontierOpponentA) or 0
  local party = {}
  local mode = Rse.var("VAR_FRONTIER_BATTLE_MODE", s)
  local double = row.double or (mode == M.DOUBLES and (which == SB.DOME or which == SB.PALACE or which == SB.FACTORY))
  if which == SB.FACTORY then
    if f.lvlMode == D.LVL.TENT then
      party = Tents().factoryTentParty(s)
    else
      Rse.missing("factory", "FillFactoryFrontierTrainerParty", adapters and adapters.log)
      return false
    end
  elseif which == SB.DOME then
    if tid ~= D.TRAINER_FRONTIER_BRAIN then
      Rse.missing("dome", "DoSpecialTrainerBattle dome party", adapters and adapters.log)
      return false
    end
    D.fillTrainerParty(s, tid, 0, 2, party)
  elseif which == SB.PIKE_DOUBLE then
    D.fillTrainerParty(s, tid, 0, 1, party)
    D.fillTrainerParty(s, tonumber(s.frontierOpponentB) or 0, 1, 1, party)
  elseif f.lvlMode == D.LVL.TENT then
    D.fillTentTrainerParty(s, tid, 0, D.PARTY_SIZE, party, Rse.var("VAR_FRONTIER_FACILITY", s))
  else
    D.fillTrainerParty(s, tid, 0, D.PARTY_SIZE, party)
  end
  return Tower().startBattle(ctx, adapters, s, row.kind, {
    party = party,
    double = double,
    transitionId = D.specialTransition(s, row.group, party),
  })
end

-- pokeemerald/src/battle_tower.c:2007
function NativesFrontier.doSpecialTrainerBattle(ctx, adapters)
  local s = sess()
  local which = specialVar(ctx, VAR_0x8004)
  if which == SB.STEVEN then return story().doStevenBattle(ctx, adapters) end
  if which == SB.TOWER then return Tower().doTowerBattle(ctx, adapters, s) end
  if KIND[which] then return facilityBattle(ctx, adapters, s, which) end
  local sys = which == SB.SECRET_BASE and "secretBase" or "ereader"
  local impl = Rse.system(sys)
  if impl and type(impl.doSpecialBattle) == "function" then return impl.doSpecialBattle(ctx, adapters, s, which) end
  Rse.missing(sys, "DoSpecialTrainerBattle " .. tostring(which), adapters and adapters.log)
  return false
end

-- pokeemerald/src/script_pokemon_util.c:188
function NativesFrontier.choosePartyForBattleFrontier(ctx, adapters)
  local s = sess()
  local count = specialVar(ctx, VAR_0x8005)
  if count < 1 then count = D.PARTY_SIZE end
  s.selectedOrderFromParty = { 0, 0, 0, 0 }
  local function settle(picked)
    local order = { 0, 0, 0, 0 }
    for i, slot in ipairs(type(picked) == "table" and picked or {}) do
      if i <= D.MAX_PARTY_SIZE then order[i] = tonumber(slot) or 0 end
    end
    s.selectedOrderFromParty = order
    Util.setResult(ctx, order[1] ~= 0 and 1 or 0)
  end
  local okP, PartyMenu = pcall(require, "src.ui.game3.party_menu")
  if not (okP and PartyMenu and PartyMenu.show and s.party and s.party[1]) then
    settle(nil)
    return false
  end
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.clear then Fade.clear() end
  local RomText = require("src.core.game3.rom_text")
  local done = false
  natives().awaitState(ctx, function() return done end)
  local function open(message)
    PartyMenu.show(s.party, nil, {
      mode = "choose_multi",
      count = count,
      minCount = count,
      menuType = PARTY_MENU_TYPE_CHOOSE_HALF,
      session = s,
      eligible = function(_, mon) return Util.entryEligible(s, mon) end,
      validateOrder = function(order) return Util.checkBattleEntries(s, s.party, order, count) end,
      onSelect = function(slot)
        if type(slot) ~= "table" then
          settle(nil)
          done = true
          return
        end
        local key = Util.checkBattleEntries(s, s.party, slot, count)
        if key then
          local Runtime = package.loaded["src.core.game3.runtime"]
          local function reopen() open(key) end
          if not (Runtime and Runtime.defer and Runtime.defer(reopen)) then reopen() end
          return
        end
        settle(slot)
        done = true
      end,
    })
    if message and PartyMenu.showMessage then
      local vars = { tostring(count) }
      PartyMenu.showMessage(RomText.plain(message, { stringVars = vars }), function()
        PartyMenu.mode = "choose_multi"
      end)
    end
  end
  open(nil)
  return false
end

-- pokeemerald/src/script_menu.c:385
function NativesFrontier.ssTidalMultichoice(ctx, adapters)
  local s = sess()
  local Bag = require("src.core.game3.bag")
  local C = D.constants(s)
  local shownMany = specialVar(ctx, VAR_0x8004) ~= 0
  local sel = {}
  if not shownMany then
    sel[#sel + 1] = SSTIDAL.SLATEPORT
    if Rse.flag("FLAG_MET_SCOTT_ON_SS_TIDAL", s) then sel[#sel + 1] = SSTIDAL.BATTLE_FRONTIER end
  end
  local tickets = {
    { "ITEM_EON_TICKET", "FLAG_ENABLE_SHIP_SOUTHERN_ISLAND", "FLAG_SHOWN_EON_TICKET", SSTIDAL.SOUTHERN_ISLAND },
    { "ITEM_MYSTIC_TICKET", "FLAG_ENABLE_SHIP_NAVEL_ROCK", "FLAG_SHOWN_MYSTIC_TICKET", SSTIDAL.NAVEL_ROCK },
    { "ITEM_AURORA_TICKET", "FLAG_ENABLE_SHIP_BIRTH_ISLAND", "FLAG_SHOWN_AURORA_TICKET", SSTIDAL.BIRTH_ISLAND },
    { "ITEM_OLD_SEA_MAP", "FLAG_ENABLE_SHIP_FARAWAY_ISLAND", "FLAG_SHOWN_OLD_SEA_MAP", SSTIDAL.FARAWAY_ISLAND },
  }
  for _, t in ipairs(tickets) do
    if Bag.has(s.bag, C:require("items", t[1]), 1) and Rse.flag(t[2], s) then
      if not shownMany then
        sel[#sel + 1] = t[4]
      elseif not Rse.flag(t[3], s) then
        sel[#sel + 1] = t[4]
        Rse.setFlag(t[3], true, s)
      end
    end
  end
  sel[#sel + 1] = SSTIDAL.EXIT
  NativesFrontier._ssTidal = sel
  Util.setResult(ctx, 0xFF)
  if #sel == SSTIDAL.COUNT then
    setSpecialVar(ctx, VAR_0x8004, require("src.core.game3.scripting.natives_field_rse").SCROLL_MULTI_SS_TIDAL or 0)
  end
  local labels, widest = {}, 0
  local TextIR = require("src.core.game3.scripting.text_ir")
  local FrlgFont = require("src.ui.game3.frlg_font")
  for i, id in ipairs(sel) do
    local ref = D.manifest().ssTidalDestinations[id + 1]
    labels[i] = TextIR.toPlain(RomText.refIr(ref), {})
    local w = FrlgFont.measure(labels[i])
    if w > widest then widest = w end
  end
  local width = math.floor((widest + 9) / 8) + 1
  local Choice = require("src.ui.game3.choice")
  local done = false
  natives().awaitState(ctx, function() return done end)
  -- pokeemerald/src/script_menu.c:510
  Choice.multi(labels, #labels - 1, function(pick)
    Util.setResult(ctx, tonumber(pick) or MULTI_B_PRESSED)
    done = true
  end, { left = MAX_MULTICHOICE_WIDTH - width + 1, top = (6 - #labels) * 2 + 1 })
  return false
end

-- pokeemerald/src/script_menu.c:540
function NativesFrontier.ssTidalSelection(ctx)
  local r = specialVar(ctx, VAR_RESULT)
  if r ~= MULTI_B_PRESSED then
    local sel = NativesFrontier._ssTidal or {}
    Util.setResult(ctx, sel[r + 1] or SSTIDAL.EXIT)
  end
  return false
end

-- pokeemerald/src/start_menu.c:896
function NativesFrontier.saveGame(ctx, adapters)
  local s = sess()
  local okS, SaveMenu = pcall(require, "src.ui.game3.save_menu")
  local Runtime = package.loaded["src.core.game3.runtime"]
  if not (okS and SaveMenu and SaveMenu.show) then
    Util.setResult(ctx, Util.persist() and SAVE_SUCCESS or 0)
    return false
  end
  local done = false
  natives().awaitState(ctx, function() return done end)
  local okM, Message = pcall(require, "src.ui.game3.message")
  if okM and Message.isOpen and Message.isOpen() and Message.close then Message.close() end
  SaveMenu.show({
    session = s,
    game = Runtime and Runtime._game,
    onClose = function()
      Util.setResult(ctx, SaveMenu._phase == "saved" and SAVE_SUCCESS or 0)
      done = true
    end,
  })
  return false
end

-- pokeemerald/src/field_specials.c:2060
function NativesFrontier.maniacMessage(ctx, adapters)
  local s = sess()
  local f = Util.frontier(s)
  local facility = Rse.var("VAR_FRONTIER_MANIAC_FACILITY", s)
  local L50, OPEN = D.LVL.L50, D.LVL.OPEN
  local function best2(t, a)
    local x, y = Util.get2(t, a, L50), Util.get2(t, a, OPEN)
    return x >= y and x or y
  end
  local function best1(t)
    local x, y = Util.get1(t, L50), Util.get1(t, OPEN)
    return x >= y and x or y
  end
  local ws = 0
  if facility <= 3 then ws = best2(f.towerWinStreaks, facility)
  elseif facility == 4 then ws = best2(f.domeWinStreaks, M.SINGLES)
  elseif facility == 5 then ws = best2(f.factoryWinStreaks, M.SINGLES)
  elseif facility == 6 then ws = best2(f.palaceWinStreaks, M.SINGLES)
  elseif facility == 7 then ws = best1(f.arenaWinStreaks)
  elseif facility == 8 then ws = best1(f.pikeWinStreaks)
  elseif facility == 9 then ws = best1(f.pyramidWinStreaks)
  end
  local man = D.manifest()
  local th = man.maniacThresholds
  local i = 0
  while i < 2 and th[facility * 2 + i + 1] < ws do i = i + 1 end
  Util.showFieldMessage(ctx, adapters, man.maniacMessages[facility * 3 + i + 1].ir)
  return false
end

-- pokeemerald/src/field_specials.c:2778
function NativesFrontier.natureGirlMessage(ctx, adapters)
  local s = sess()
  local idx = specialVar(ctx, VAR_0x8004)
  if idx >= 6 then idx = 0 setSpecialVar(ctx, VAR_0x8004, 0) end
  local mon = s.party and s.party[idx + 1]
  local nature = mon and (tonumber(mon.nature) or (tonumber(mon.personality) or 0) % 25) or 0
  Util.showFieldMessage(ctx, adapters, D.manifest().natureGirlMessages[nature + 1].ir)
  return false
end

-- pokeemerald/src/field_specials.c:2824
function NativesFrontier.gamblerLooking(ctx, adapters)
  local s = sess()
  local challenge = Rse.var("VAR_FRONTIER_GAMBLER_CHALLENGE", s)
  Util.showFieldMessage(ctx, adapters, D.manifest().gamblerLookingMessages[challenge + 1].ir)
  Rse.setVar("VAR_FRONTIER_GAMBLER_SET_CHALLENGE", challenge, s)
  return false
end

-- pokeemerald/src/field_specials.c:2847
function NativesFrontier.gamblerGo(ctx, adapters)
  local s = sess()
  local challenge = Rse.var("VAR_FRONTIER_GAMBLER_SET_CHALLENGE", s)
  Util.showFieldMessage(ctx, adapters, D.manifest().gamblerGoMessages[challenge + 1].ir)
  return false
end

-- pokeemerald/src/field_specials.c:2817
function NativesFrontier.updateGambler(sess, days)
  local v = Rse.var("VAR_FRONTIER_GAMBLER_CHALLENGE", sess)
  Rse.setVar("VAR_FRONTIER_GAMBLER_CHALLENGE", (v + days) % #D.manifest().gamblerChallenges, sess)
end

-- pokeemerald/src/clock.c:36
function NativesFrontier.installTimeHooks()
  local ok, TimeEvents = pcall(require, "src.core.game3.time_events")
  if not (ok and TimeEvents and TimeEvents.onDay) then return end
  local perDay = TimeEvents.handlers and TimeEvents.handlers() or {}
  if perDay.UpdateFrontierGambler == nil then
    TimeEvents.onDay("UpdateFrontierGambler", function(s, days)
      if Rse.isRse(s) then NativesFrontier.updateGambler(s, days) end
    end)
  end
end
NativesFrontier.installTimeHooks()

-- pokeemerald/src/script_pokemon_util.c:99
function NativesFrontier.hasEnoughMonsForDouble(ctx)
  local s = sess()
  local Party = require("src.core.game3.party")
  setSpecialVar(ctx, VAR_RESULT, Party.monsStateToDoubles(s.party))
  return false
end

-- pokeemerald/src/script_pokemon_util.c:128
function NativesFrontier.doesPartyHaveEnigmaBerry(ctx)
  local s = sess()
  local enigma = D.constants(s):require("items", "ITEM_ENIGMA_BERRY")
  local has = false
  for _, mon in ipairs(s.party or {}) do
    if tonumber(mon.heldItem or mon.item) == enigma then has = true end
  end
  if has then
    Util.setStringVar(ctx, nil, 1, require("src.core.game3.items_data").displayName(enigma) or "")
  end
  Util.setResult(ctx, has and 1 or 0)
  return false
end

NativesFrontier.BY_NAME = {
  -- pokeemerald/src/frontier_util.c:787
  CallFrontierUtilFunc = function(ctx, adapters) return NativesFrontier.callUtil(ctx, adapters) end,
  -- pokeemerald/src/battle_tower.c:2007
  DoSpecialTrainerBattle = function(ctx, adapters) return NativesFrontier.doSpecialTrainerBattle(ctx, adapters) end,
  -- pokeemerald/src/script_pokemon_util.c:188
  ChoosePartyForBattleFrontier = function(ctx, adapters)
    return NativesFrontier.choosePartyForBattleFrontier(ctx, adapters)
  end,
  -- pokeemerald/src/field_specials.c:2911
  ShowBattlePointsWindow = function()
    Records().showBp(sess())
    return false
  end,
  -- pokeemerald/src/field_specials.c:2902
  UpdateBattlePointsWindow = function()
    Records().updateBp(sess())
    return false
  end,
  -- pokeemerald/src/field_specials.c:2930
  CloseBattlePointsWindow = function()
    Records().hideBp()
    return false
  end,
  -- pokeemerald/src/field_specials.c:2952
  GetFrontierBattlePoints = function(ctx)
    Util.setResult(ctx, tonumber(Util.frontier(sess()).battlePoints) or 0)
    return false, tonumber(Util.frontier(sess()).battlePoints) or 0
  end,
  -- pokeemerald/src/field_specials.c:2944
  GiveFrontierBattlePoints = function(ctx)
    Util.addBattlePoints(sess(), specialVar(ctx, VAR_0x8004))
    return false
  end,
  -- pokeemerald/src/field_specials.c:2936
  TakeFrontierBattlePoints = function(ctx)
    Util.takeBattlePoints(sess(), specialVar(ctx, VAR_0x8004))
    return false
  end,
  -- pokeemerald/src/battle_tower.c:2946
  TryHideBattleTowerReporter = function()
    Tower().tryHideReporter(sess())
    return false
  end,
  -- pokeemerald/src/field_specials.c:2206
  BufferBattleTowerElevatorFloors = function(ctx)
    Tower().elevatorFloors(ctx, sess())
    return false
  end,
  -- pokeemerald/src/field_specials.c:1672
  OffsetCameraForBattle = function()
    require("src.core.game3.field_view").setCameraPanning(8, 0)
    return false
  end,
  -- pokeemerald/src/frontier_util.c:2366
  ShowRankingHallRecordsWindow = function(ctx)
    Records().showRankingHall(sess(), specialVar(ctx, VAR_0x8005), D.LVL.L50)
    return false
  end,
  -- pokeemerald/src/frontier_util.c:2376
  ScrollRankingHallRecordsWindow = function(ctx)
    Records().showRankingHall(sess(), specialVar(ctx, VAR_0x8005), D.LVL.OPEN)
    return false
  end,
  -- pokeemerald/src/battle_records.c:340
  RemoveRecordsWindow = function()
    Records().remove()
    return false
  end,
  -- pokeemerald/src/field_specials.c:2060
  ShowFrontierManiacMessage = function(ctx, adapters) return NativesFrontier.maniacMessage(ctx, adapters) end,
  -- pokeemerald/src/field_specials.c:2778
  ShowNatureGirlMessage = function(ctx, adapters) return NativesFrontier.natureGirlMessage(ctx, adapters) end,
  -- pokeemerald/src/field_specials.c:2824
  ShowFrontierGamblerLookingMessage = function(ctx, adapters) return NativesFrontier.gamblerLooking(ctx, adapters) end,
  -- pokeemerald/src/field_specials.c:2847
  ShowFrontierGamblerGoMessage = function(ctx, adapters) return NativesFrontier.gamblerGo(ctx, adapters) end,
  -- pokeemerald/src/script_pokemon_util.c:99
  HasEnoughMonsForDoubleBattle = function(ctx) return NativesFrontier.hasEnoughMonsForDouble(ctx) end,
  -- pokeemerald/src/script_pokemon_util.c:128
  DoesPartyHaveEnigmaBerry = function(ctx) return NativesFrontier.doesPartyHaveEnigmaBerry(ctx) end,
  -- pokeemerald/src/script_menu.c:385
  ScriptMenu_CreateLilycoveSSTidalMultichoice = function(ctx, adapters)
    return NativesFrontier.ssTidalMultichoice(ctx, adapters)
  end,
  -- pokeemerald/src/script_menu.c:540
  GetLilycoveSSTidalSelection = function(ctx) return NativesFrontier.ssTidalSelection(ctx) end,
  -- pokeemerald/src/start_menu.c:896
  SaveGame = function(ctx, adapters) return NativesFrontier.saveGame(ctx, adapters) end,
}

return NativesFrontier
