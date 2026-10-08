local Rse = require("src.core.game3.rse.init")

local Rs = { BY_NAME = {} }
local B = Rs.BY_NAME
local RESULT = 0x800D

local function natives() return require("src.core.game3.scripting.natives") end
local function constants()
  return require("src.core.game3.constants").active(Rse.session())
end
local function party() local s = Rse.session(); return s and s.party or {} end
local function species(mon) return tonumber(mon and (mon.species or mon.speciesId)) or 0 end
local function egg(mon)
  return mon ~= nil and (mon.isEgg or mon.egg or species(mon) == constants():require("species", "SPECIES_EGG"))
end
local function species2(mon) return egg(mon) and constants():require("species", "SPECIES_EGG") or species(mon) end
local function selected(ctx) return party()[Rse.specialVar(ctx, 0x8004) + 1] end
local function result(ctx, value) Rse.setSpecialVar(ctx, RESULT, value); return false, value end
local function ret(value) return false, value end
local function bool(value) return false, value and 1 or 0 end
-- pokeruby/src/field_specials.c:1630
B.GetSlotMachineId = function(ctx)
  local sess = assert(Rse.session(), "RS slots need a session")
  local man = require("src.core.game3.rse.slot_machine").loadTables()
  assert(man.assetLayout == "rs", "native RS slot-machine pack required")
  local Tv = require("src.core.game3.rse.tv")
  local active = Tv.isPokeNewsActive(sess, 2, function(kind)
    return Tv.shouldApplyPokeNews(kind, sess)
  end)
  local value = require("src.core.game3.scripting.natives_game_corner_rse").getSlotMachineId(ctx,
    {session = sess, fieldIds = man.fieldIds, serviceDay = active})
  return result(ctx, value)
end
local function stringVar(ctx, adapters, index, value)
  if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[index] = value end
  if adapters and adapters.setStringVar then adapters.setStringVar(index, value) end
end
local function nickname(mon)
  return require("src.core.game3.pokemon").displayMonName(mon)
end
local function delegate(module, name, core)
  return function(ctx, adapters)
    local m = require("src.core.game3.scripting." .. module)
    return assert((core and m.CORE or m.BY_NAME)[name], "missing RS delegate " .. name)(ctx, adapters)
  end
end

-- pokeruby/src/contest_util.c:380
B.ScrSpecial_HealPlayerParty = function()
  require("src.core.game3.party").healAll(party())
  for _, mon in ipairs(party()) do
    mon.statusNum, mon.statusAilment, mon.sleepTurns, mon.fainted = 0, nil, nil, false
  end
  return false
end

-- pokeruby/src/battle_setup.c:865
B.ScrSpecial_ChooseStarter = function(ctx, adapters)
  local sess = Rse.session()
  local Choose = require("src.ui.game3.rse.starter_choose")
  local Options = require("src.core.game3.options")
  local frame = Options.ensure(sess).frameType
  return natives().yieldHost(ctx, adapters, function(done)
    require("src.ui.game3.fade").clear()
    Choose.open({ frameType = frame, onDone = function(selection)
      local names = { [0] = "SPECIES_TREECKO", "SPECIES_TORCHIC", "SPECIES_MUDKIP" }
      local name = assert(names[selection], "invalid RS starter selection")
      Rse.setSpecialVar(ctx, RESULT, selection)
      Rse.setVar("VAR_STARTER_MON", selection, sess)
      require("src.core.game3.party").giveMonToPlayer(sess, constants():require("species", name), 5)
      local Runtime = package.loaded["src.core.game3.runtime"]
      local handle, err = require("src.core.game3.battle_bridge").startFirstBattle(
        Runtime and Runtime._mod, Runtime and Runtime._game, { done = function(outcome)
          if ctx then ctx.lastBattleOutcome = natives().outcome_to_code(outcome) end
          done()
        end })
      assert(handle, "RS first battle did not start: " .. tostring(err))
    end })
  end)
end

-- pokeruby/src/field_specials.c:709
B.GetBattleOutcome = function(ctx) return ret(tonumber(ctx and ctx.lastBattleOutcome) or 0) end
B.ScrSpecial_GetTrainerBattleMode = function(ctx) return ret(tonumber(ctx and ctx.trainerBattleMode) or 0) end
local function trainerId(ctx)
  local id = tonumber(ctx and ctx.trainerBattleOpponentA) or 0
  if id ~= 0 then return id end
  local Objects = require("src.core.game3.objects")
  local eo = Objects.find(Rse.specialVar(ctx, 0x800F))
  return eo and tonumber(require("src.core.game3.trainer_sight").getTrainerId(eo)) or 0
end
-- pokeruby/src/battle_setup.c:1071
B.GetTrainerFlag = function(ctx)
  local Flags = require("src.core.game3.scripting.flags")
  return bool(Flags.getFlag(Rse.store(), ctx, Flags.trainerFlagId(trainerId(ctx))))
end
local function trainerSpeech(ctx, adapters, key, intro)
  local text = require("src.core.game3.scripting.trainers").dialogs(trainerId(ctx))[key]
  if type(text) == "table" then text = require("src.core.game3.scripting.text_ir").toPlain(text, {}) end
  if not text or text == "" then return false end
  if intro and ctx then ctx.trainerIntroShown = true end
  if not (adapters and adapters.openMessageAsync) then return false end
  return natives().yieldHost(ctx, adapters, function(done) adapters.openMessageAsync(text, done) end)
end
-- pokeruby/src/battle_setup.c:1155
B.ShowTrainerIntroSpeech = function(ctx, adapters) return trainerSpeech(ctx, adapters, "intro", true) end
B.ScrSpecial_ShowTrainerNonBattlingSpeech = function(ctx, adapters) return trainerSpeech(ctx, adapters, "notEnough") end
-- pokeruby/src/battle_setup.c:1181
B.PlayTrainerEncounterMusic = function(ctx)
  local mode = tonumber(ctx and ctx.trainerBattleMode) or 0
  if mode ~= 1 and mode ~= 8 then
    local song = require("src.core.game3.trainer_sight").encounterMusic(trainerId(ctx))
    if song then require("src.core.game3.audio").playSong(song) end
  end
  return false
end
-- pokeruby/src/battle_setup.c:1059
B.SetUpTrainerMovement = function(ctx)
  local Objects = require("src.core.game3.objects")
  local eo = Objects.find(Rse.specialVar(ctx, 0x800F))
  local mt = ({ up = 7, down = 8, left = 9, right = 10 })[eo and eo.facing]
  if mt then Objects.setTrainerMovementType(eo, mt) end
  return false
end
-- pokeruby/src/trainer_see.c:452
B.EndTrainerApproach = function(ctx)
  local Objects = require("src.core.game3.objects")
  local lid = Rse.specialVar(ctx, 0x800F)
  natives().awaitState(ctx, function()
    local track = Objects._tracks and Objects._tracks[lid]
    return track == nil or track.done == true
  end)
  return false
end

-- pokeruby/src/field_specials.c:675
B.StorePlayerCoordsInVars = function(ctx)
  local P = require("src.core.game3.player")
  Rse.setSpecialVar(ctx, 0x8004, tonumber(P.cellX) or 0)
  Rse.setSpecialVar(ctx, 0x8005, tonumber(P.cellY) or 0)
  return false
end
B.GetPlayerTrainerIdOnesDigit = function()
  local sess = Rse.session()
  return ret(((tonumber(sess and sess.trainerId) or 0) % 65536) % 10)
end
B.GetPlayerBigGuyGirlString = function(ctx, adapters)
  local sess = Rse.session()
  stringVar(ctx, adapters, 1, Rse.text((tonumber(sess and sess.gender) or 0) == 0 and "gOtherText_BigGuy" or "gOtherText_BigGirl"))
  return false
end
B.GetRivalSonDaughterString = function(ctx, adapters)
  local sess = Rse.session()
  stringVar(ctx, adapters, 1, Rse.text((tonumber(sess and sess.gender) or 0) == 0 and "gOtherText_Daughter" or "gOtherText_Son"))
  return false
end
B.SetHiddenItemFlag = function(ctx)
  require("src.core.game3.scripting.flags").setFlag(Rse.store(), ctx, Rse.specialVar(ctx, 0x8004), true)
  return false
end
B.InitBirchState = function() Rse.setVar("VAR_BIRCH_STATE", 0); return false end

-- pokeruby/src/field_specials.c:1752
B.IsStarterInParty = function()
  local names = { [0] = "SPECIES_TREECKO", "SPECIES_TORCHIC", "SPECIES_MUDKIP" }
  local want = constants():require("species", names[Rse.var("VAR_STARTER_MON")] or names[0])
  for _, mon in ipairs(party()) do if species2(mon) == want then return bool(true) end end
  return bool(false)
end
B.ScriptGetPartyMonSpecies = function(ctx) return ret(species2(selected(ctx))) end
B.IsSelectedMonEgg = function(ctx) return result(ctx, egg(selected(ctx)) and 1 or 0) end
B.CalculatePlayerPartyCount = function()
  local n, mons = 0, party()
  while n < 6 and species(mons[n + 1]) ~= 0 do n = n + 1 end
  return ret(n)
end
-- pokeruby/src/pokemon_storage_system.c:106
B.GetNumValidDaycarePartyMons = function()
  local n = 0
  for _, mon in ipairs(party()) do if species(mon) ~= 0 and not egg(mon) then n = n + 1 end end
  return ret(n)
end
B.CountAlivePartyMonsExceptSelectedOne = function(ctx)
  local n, skip = 0, Rse.specialVar(ctx, 0x8004) + 1
  for i, mon in ipairs(party()) do
    if i ~= skip and species(mon) ~= 0 and not egg(mon) and (tonumber(mon.hp) or 0) > 0 then n = n + 1 end
  end
  return ret(n)
end
-- pokeruby/src/field_specials.c:741
B.GetLeadMonFriendshipScore = function()
  local lead
  for _, mon in ipairs(party()) do if species(mon) ~= 0 and not egg(mon) then lead = mon; break end end
  local f = lead and require("src.core.game3.pokemon").friendshipOf(lead) or 0
  return ret(f == 255 and 6 or f >= 200 and 5 or f >= 150 and 4 or f >= 100 and 3 or f >= 50 and 2 or f > 0 and 1 or 0)
end
-- pokeruby/src/tv.c:2081
B.TV_CopyNicknameToStringVar1AndEnsureTerminated = function(ctx, adapters)
  stringVar(ctx, adapters, 1, nickname(selected(ctx)))
  return false
end
B.TV_CheckMonOTIDEqualsPlayerID = function(ctx)
  local sess, mon = Rse.session(), selected(ctx)
  local id = tonumber(sess and sess.trainerId) or 0
  local fullId = (id % 65536) + (tonumber(sess and sess.secretId) or math.floor(id / 65536)) * 65536
  local otId = tonumber(mon and mon.otId) or 0
  local fullOtId = (otId % 65536) + (tonumber(mon and mon.otSecretId) or math.floor(otId / 65536)) * 65536
  return result(ctx, fullOtId == fullId and 0 or 1)
end
B.MonOTNameMatchesPlayer = function(ctx, adapters)
  local sess, mon = Rse.session(), selected(ctx)
  local name = tostring(mon and (mon.otName or mon.ot) or "")
  stringVar(ctx, adapters, 1, name)
  return bool(name ~= tostring(sess and (sess.name or sess.playerName) or ""))
end
-- pokeruby/src/money.c:321
B.HasEnoughMoneyFor = function(ctx) return bool((tonumber((Rse.session() or {}).money) or 0) >= Rse.specialVar(ctx, 0x8005)) end
B.PayMoneyFor = function(ctx)
  local sess = Rse.session()
  if sess then sess.money = math.max(0, (tonumber(sess.money) or 0) - Rse.specialVar(ctx, 0x8005)) end
  return false
end

-- pokeruby/src/field_poison.c:66
B.ExecuteWhiteOut = function(ctx, adapters)
  local Pokemon = require("src.core.game3.pokemon")
  local mons, index = party(), 1
  return natives().yieldHost(ctx, adapters, function(done)
    local nextMon
    nextMon = function()
      while index <= 6 do
        local mon = mons[index]; index = index + 1
        local status = tostring(mon and mon.status or ""):upper()
        local num = tonumber(mon and mon.statusNum) or 0
        local poison = status == "PSN" or status == "POISON" or status == "TOX" or status == "TOXIC" or num % 16 >= 8 or num % 256 >= 128
        if species(mon) ~= 0 and not egg(mon) and (tonumber(mon.hp) or 0) == 0 and poison then
          Pokemon.adjustFriendship(mon, Pokemon.FRIENDSHIP_EVENT_FAINT_OUTSIDE_BATTLE, { mapSec = Pokemon.currentMapSec(Rse.session()) })
          mon.status, mon.statusNum = nil, 0
          stringVar(ctx, adapters, 1, nickname(mon))
          if adapters and adapters.openMessageAsync then
            adapters.openMessageAsync(require("src.core.game3.rom_text").box("fieldPoisonText_PokemonFainted", { stringVars = { nickname(mon) } }), nextMon)
            return
          end
        end
      end
      local fainted = true
      for _, mon in ipairs(mons) do if species(mon) ~= 0 and not egg(mon) and (tonumber(mon.hp) or 0) > 0 then fainted = false; break end end
      Rse.setSpecialVar(ctx, RESULT, fainted and 1 or 0)
      done()
    end
    nextMon()
  end)
end

-- pokeruby/src/field_specials.c:1795
B.ShakeCamera = function(ctx)
  local h, v = Rse.specialVar(ctx, 0x8005), Rse.specialVar(ctx, 0x8004)
  if h >= 32768 then h = h - 65536 end
  if v >= 32768 then v = v - 65536 end
  local View = package.loaded["src.core.game3.field_view"]
  local frame, shakes, finished = 0, 8, false
  require("src.core.game3.task").spawn(function()
    frame = frame + 1
    if frame == 5 then
      frame, shakes, h, v = 0, shakes - 1, -h, -v
      if View then View.cameraPanX, View.cameraPanY = h, v end
      if shakes == 0 then
        if View then View.cameraPanX, View.cameraPanY = 0, 0 end
        finished = true
        return true
      end
    end
    return false
  end)
  natives().awaitState(ctx, function() return finished end)
  return false
end
B.DrawWholeMapView = function()
  local View = package.loaded["src.core.game3.field_view"]
  if View then View._nativeDirty = true end
  return false
end
B.Overworld_PlaySpecialMapMusic = function()
  local Audio = require("src.core.game3.audio")
  local song = Audio.specialMapSong()
  if song ~= nil and song ~= Audio.currentMapMusic() then Audio.playSong(song) end
  return false
end
B.WaitWeather = function(ctx)
  return require("src.core.game3.rse.story_specials_rs").waitWeather(ctx)
end
B.DoFallWarp = function(ctx) return require("src.core.game3.rse.story_specials_rs").fallWarp(ctx) end
B.DoSealedChamberShakingEffect1 = function(ctx) return require("src.core.game3.rse.story_specials_rs").sealedChamberShake(ctx, true) end
B.DoSealedChamberShakingEffect2 = function(ctx) return require("src.core.game3.rse.story_specials_rs").sealedChamberShake(ctx, false) end
B.DoBrailleWait = function(ctx, adapters) return require("src.core.game3.rse.story_specials_rs").brailleWait(ctx, adapters) end
-- pokeruby/src/braille_puzzles.c:58
B.CheckRelicanthWailord = function()
  local mons, n = party(), 0
  local C = constants()
  if species2(mons[1]) ~= C:require("species", "SPECIES_RELICANTH") then return bool(false) end
  for i = 1, 6 do
    if species(mons[i]) == 0 then break end
    n = i
  end
  return bool(n > 0 and species2(mons[n]) == C:require("species", "SPECIES_WAILORD"))
end

-- pokeruby/src/field_specials.c:1715
B.TryUpdateRusturfTunnelState = function()
  local sess = Rse.session()
  local profile = Rse.profile(sess)
  if Rse.flag("FLAG_RUSTURF_TUNNEL_OPENED") or not sess or sess.map ~= profile.map.enginePrefix .. "RUSTURF_TUNNEL" then return bool(false) end
  if Rse.flag("FLAG_HIDE_RUSTURF_TUNNEL_ROCK_1") then Rse.setVar("VAR_RUSTURF_TUNNEL_STATE", 4); return bool(true) end
  if Rse.flag("FLAG_HIDE_RUSTURF_TUNNEL_ROCK_2") then Rse.setVar("VAR_RUSTURF_TUNNEL_STATE", 5); return bool(true) end
  return bool(false)
end
B.FoundBlackGlasses = function() return bool(Rse.flag("FLAG_HIDDEN_ITEM_BLACK_GLASSES")) end
B.IsPokerusInParty = function() return bool(require("src.core.game3.pokemon").checkPartyPokerus(party(), 0x3F) ~= 0) end

-- pokeruby/src/lottery_corner.c:48
B.RetrieveLotteryNumber = function(ctx)
  Rse.setSpecialVar(ctx, RESULT, Rse.var("VAR_LOTTERY_RND_L"))
  return false
end
B.BufferLottoTicketNumber = function(ctx, adapters)
  stringVar(ctx, adapters, 1, require("src.core.game3.rse.lottery").ticketString(Rse.specialVar(ctx, RESULT)))
  return false
end
B.PickLotteryCornerTicket = function(ctx, adapters)
  local Lottery = require("src.core.game3.rse.lottery")
  local Pokemon = require("src.core.game3.pokemon")
  local sess, best, found, where = Rse.session(), 0, nil, nil
  local winning = Rse.specialVar(ctx, RESULT)
  local function consider(mon, place)
    if species(mon) == 0 or Pokemon.isEgg(mon) then return end
    local matches = Lottery.matchingDigits(winning, tonumber(mon.otId or mon.ot_id) or 0)
    if matches > best and matches > 1 then best, found, where = matches - 1, mon, place end
  end
  for i = 1, 6 do
    local mon = party()[i]
    if species(mon) == 0 then break end
    consider(mon, 0)
  end
  local boxes = sess and sess.storage and sess.storage.boxes or {}
  for i = 1, 14 do
    local mons = boxes[i] and boxes[i].mons or {}
    for j = 1, 30 do consider(mons[j], 1) end
  end
  Rse.setSpecialVar(ctx, 0x8004, best)
  if best ~= 0 then
    local prizes = { "ITEM_PP_UP", "ITEM_EXP_SHARE", "ITEM_MAX_REVIVE", "ITEM_MASTER_BALL" }
    Rse.setSpecialVar(ctx, 0x8005, constants():require("items", prizes[best]))
    Rse.setSpecialVar(ctx, 0x8006, where)
    stringVar(ctx, adapters, 1, nickname(found))
  end
  return false
end

local function fieldMetatile(x, y, name, delta)
  require("src.core.game3.field").setMetatile(x, y,
    constants():require("metatile_labels", name) + (delta or 0), true)
end
local function activeTask(marker)
  for _, task in ipairs(require("src.core.game3.task")._list) do
    if task.data.rsSpecial == marker then return true end
  end
  return false
end
local function lotteryLaptop(on)
  local suffix = on and "Flash" or "Normal"
  fieldMetatile(11, 1, "METATILE_Shop_Laptop1_" .. suffix)
  fieldMetatile(11, 2, "METATILE_Shop_Laptop2_" .. suffix)
  B.DrawWholeMapView()
end
-- pokeruby/src/field_specials.c:924
B.DoLotteryCornerComputerEffect = function()
  if activeTask("lottery") then return false end
  local timer, flickers, on = 0, 0, false
  require("src.core.game3.task").spawn(function()
    if timer == 6 then
      timer, on, flickers = 0, not on, flickers + 1
      lotteryLaptop(on)
      if flickers == 5 then return true end
    end
    timer = timer + 1
    return false
  end, { data = { rsSpecial = "lottery" } })
  return false
end
B.EndLotteryCornerComputerEffect = function() lotteryLaptop(false); return false end

-- pokeruby/src/field_specials.c:1099
B.DisplayCurrentElevatorFloor = function(ctx, adapters)
  local label = require("src.core.game3.rom_text").at("gUnknown_083F8380", Rse.specialVar(ctx, 0x8005))
  if adapters and adapters.elevatorWindow then adapters.elevatorWindow(label) end
  return false
end
-- field_specials.c:1221
B.ShakeScreenInElevator = function(ctx)
  local Task = require("src.core.game3.task")
  if not activeTask("elevator_lights") then
    local timer, cycles, on = 0, 0, false
    Task.spawn(function()
      if timer == 8 then
        timer, cycles = 0, cycles + 1
        for y, row in ipairs({ "Top", "Mid", "Bottom" }) do
          for x = 0, 3 do
            local col = x == 0 and 0 or x == 3 and 2 or 1
            fieldMetatile(x, y - 1, "METATILE_BattleTower_Elevator_" .. row .. col, on and 0 or 3)
          end
        end
        B.DrawWholeMapView()
        on = not on
        if cycles == 8 then return true end
      end
      timer = timer + 1
      return false
    end, { data = { rsSpecial = "elevator_lights" } })
  end
  require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_ELEVATOR)
  local timer, pans, pan, finished = 0, 0, 1, false
  Task.spawn(function()
    timer = timer + 1
    if timer == 3 then
      timer, pans, pan = 0, pans + 1, -pan
      local View = package.loaded["src.core.game3.field_view"]
      if View then View.cameraPanX, View.cameraPanY = 0, pan end
      if pans == 23 then
        require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_DING_DONG)
        if View then View.cameraPanY = 0 end
        finished = true
        return true
      end
    end
    return false
  end)
  natives().awaitState(ctx, function() return finished end)
  return false
end

-- pokeruby/src/item.c:409
B.SwapRegisteredBike = function()
  local sess = Rse.session()
  if not sess then return false end
  local Items = require("src.core.game3.items_data")
  local item = Items.toNumericId(sess.registeredItem) or tonumber(sess.registeredItem)
  local mach, acro = constants():require("items", "ITEM_MACH_BIKE"), constants():require("items", "ITEM_ACRO_BIKE")
  if item == mach then sess.registeredItem = acro elseif item == acro then sess.registeredItem = mach end
  return false
end
local function lastWarpOutdoors()
  local sess = Rse.session()
  local last = sess and sess.lastUsedWarp
  local kind = last and tonumber(last.mapType)
  if kind == nil and last and last.map then
    local Runtime = package.loaded["src.core.game3.runtime"]
    local game = Runtime and Runtime._game
    local def = game and game.data and game.data.maps and game.data.maps[last.map]
    kind = def and tonumber(def.mapType)
  end
  return ({ [1] = true, [2] = true, [3] = true, [5] = true, [6] = true })[kind] == true
end
-- pokeruby/src/time_events.c:42
B.IsMirageIslandPresent = function()
  local rnd = Rse.var("VAR_MIRAGE_RND_H")
  for _, mon in ipairs(party()) do if species(mon) ~= 0 and (tonumber(mon.personality) or 0) % 65536 == rnd then return bool(true) end end
  return bool(false)
end
B.UpdateShoalTideFlag = function()
  if lastWarpOutdoors() then
    local hour = require("src.core.game3.rtc").calcLocalTime(Rse.session()).hours
    local high = hour < 3 or (hour >= 9 and hour < 15) or hour >= 21
    Rse.setFlag("FLAG_SYS_SHOAL_TIDE", high)
  end
  return false
end
-- pokeruby/src/field_specials.c:1841
local function setRouteWeather(name)
  if not lastWarpOutdoors() then
    local id = constants():require("weather", name)
    require("src.core.game3.weather").setSaved(id, Rse.session())
  end
  return false
end
B.SetRoute119Weather = function() return setRouteWeather("WEATHER_ROUTE119_CYCLE") end
B.SetRoute123Weather = function() return setRouteWeather("WEATHER_ROUTE123_CYCLE") end
-- pokeruby/src/field_specials.c:731
local function localDays() return require("src.core.game3.rtc").calcLocalTime(Rse.session()).days end
B.GetWeekCount = function() return ret(math.min(9999, math.floor(localDays() / 7))) end
B.SetPacifidlogTMReceivedDay = function()
  local days = localDays()
  Rse.setVar("VAR_PACIFIDLOG_TM_RECEIVED_DAY", days)
  return ret(days)
end
B.GetDaysUntilPacifidlogTMAvailable = function()
  local days = localDays()
  local delta = days - Rse.var("VAR_PACIFIDLOG_TM_RECEIVED_DAY")
  return ret(delta >= 7 and 0 or days < 0 and 8 or 7 - delta)
end
-- pokeruby/src/post_battle_event_funcs.c:13
B.GameClear = function()
  local sess = assert(Rse.session(), "RS GameClear needs a session")
  B.ScrSpecial_HealPlayerParty()
  local hasRecords = Rse.flag("FLAG_SYS_GAME_CLEAR")
  Rse.setFlag("FLAG_SYS_GAME_CLEAR", true)
  local Bit = require("bit")
  sess.gameStats = sess.gameStats or {}
  if (tonumber(sess.gameStats[1]) or 0) == 0 then
    local pt = sess.playtime or sess.playTime or {}
    sess.gameStats[1] = Bit.bor(Bit.lshift(tonumber(pt.hours) or 0, 16), Bit.lshift(tonumber(pt.minutes) or 0, 8), tonumber(pt.seconds) or 0)
  end
  sess.specialSaveWarpFlags = 1
  local male = (tonumber(sess.gender) or 0) == 0
  local heal = constants():require("heal_locations", male and "HEAL_LOCATION_LITTLEROOT_TOWN_BRENDANS_HOUSE_2F" or "HEAL_LOCATION_LITTLEROOT_TOWN_MAYS_HOUSE_2F")
  local loc = require("src.core.game3.heal_locations").get(heal)
  if loc then sess.continueGameWarp = { map = loc.map, x = loc.x, y = loc.y } end
  local Ribbons, gave = require("src.core.game3.rse.ribbons"), false
  for _, mon in ipairs(party()) do
    if species(mon) ~= 0 and not egg(mon) and Ribbons.get(mon, "champion") == 0 then Ribbons.set(mon, "champion", 1); gave = true end
  end
  if gave then
    sess.gameStats[42] = math.min(0xFFFFFF, (tonumber(sess.gameStats[42]) or 0) + 1)
    Rse.setFlag("FLAG_SYS_RIBBON_GET", true)
  end
  require("src.ui.game3.fade").clear()
  require("src.ui.game3.hall_of_fame").start({ session = sess, warp = false, credits = true, hasRecords = hasRecords, onDone = function()
    local Runtime = package.loaded["src.core.game3.runtime"]
    if Runtime and Runtime._game then Runtime._game.softResetRequested = true end
  end })
  return false
end
B.DoSoftReset = function()
  local Runtime = package.loaded["src.core.game3.runtime"]
  if Runtime and Runtime._game then Runtime._game.softResetRequested = true end
  return false
end
-- pokeruby/src/start_menu.c:616
B.SaveGame = function(ctx)
  local Menu = require("src.ui.game3.save_menu")
  local Runtime = package.loaded["src.core.game3.runtime"]
  local Message = require("src.ui.game3.message")
  if Message.isOpen() then Message.closeStay() end
  local finished = false
  natives().awaitState(ctx, function() return finished end)
  Menu.show({ session = Rse.session(), game = Runtime and Runtime._game, onClose = function()
    Rse.setSpecialVar(ctx, RESULT, Menu._phase == "saved" and 1 or 0)
    finished = true
  end })
  return false
end
-- pokeruby/src/clock.c:76
local function openClock(ctx, adapters, mode)
  local sess = Rse.session()
  return natives().yieldHost(ctx, adapters, function(done)
    local Fade = require("src.ui.game3.fade")
    Fade.clear()
    require("src.ui.game3.rse.wall_clock").open({
      mode = mode, gender = Rse.specialVar(ctx, 0x8004), session = sess,
      frameType = require("src.core.game3.options").ensure(sess).frameType,
      onDone = function(value)
        if mode == "set" and value and value.confirmed then require("src.core.game3.time_events").init(sess) end
        Fade.clear()
        Fade.begin(Fade.MODE.FROM_BLACK, 1)
        done()
      end,
    })
  end)
end
B.StartWallClock = function(ctx, adapters) return openClock(ctx, adapters, "set") end
B.ScrSpecial_ViewWallClock = function(ctx, adapters) return openClock(ctx, adapters, "view") end
local aliases = {
  natives = { ShowPokemonStorageSystem = "ShowPokemonStorageSystemPC", HasEnoughMonsForDoubleBattle = "HasEnoughMonsForDoubleBattle" },
  natives_frontier_story = {
    SavePlayerParty = "SavePlayerParty", LoadPlayerParty = "LoadPlayerParty", PutZigzagoonInPlayerParty = "LoadWallyZigzagoon",
    ScrSpecial_StartWallyTutorialBattle = "StartWallyTutorialBattle", ScrSpecial_StartRayquazaBattle = "BattleSetup_StartLegendaryBattle",
    ScrSpecial_StartRegiBattle = "StartRegiBattle", ScrSpecial_StartGroudonKyogreBattle = "StartGroudonKyogreBattle",
    ScrSpecial_StartSouthernIslandBattle = "BattleSetup_StartLatiBattle", InitRoamer = "InitRoamer",
    EnterSafariMode = "EnterSafariMode", ExitSafariMode = "ExitSafariMode", sp0C8_whiteout_maybe = "SetCB2WhiteOut",
  },
  natives_pc_rse = { BedroomPC = "BedroomPC", ScriptMenu_CreatePCMultichoice = "ScriptMenu_CreatePCMultichoice",
    DoPCTurnOnEffect = "DoPCTurnOnEffect", DoPCTurnOffEffect = "DoPCTurnOffEffect", AccessHallOfFamePC = "AccessHallOfFamePC" },
  natives_events = { ShowFieldMessageStringVar4 = "ShowFieldMessageStringVar4", ScrSpecial_RockSmashWildEncounter = "RockSmashWildEncounter" },
  natives_queries = { GetPlayerFacingDirection = "GetPlayerFacingDirection", CheckFreePokemonStorageSpace = "IsThereRoomInAnyBoxForMorePokemon" },
  natives_region_map_rse = { FieldShowRegionMap = "FieldShowRegionMap" },
  natives_berry = { ObjectEventInteractionGetBerryTreeData = "ObjectEventInteractionGetBerryTreeData", Berry_FadeAndGoToBerryBagMenu = "Bag_ChooseBerry",
    ObjectEventInteractionPlantBerryTree = "ObjectEventInteractionPlantBerryTree", ObjectEventInteractionPickBerryTree = "ObjectEventInteractionPickBerryTree",
    ObjectEventInteractionRemoveBerryTree = "ObjectEventInteractionRemoveBerryTree", ObjectEventInteractionWaterBerryTree = "ObjectEventInteractionWaterBerryTree",
    PlayerHasBerries = "PlayerHasBerries", DoWateringBerryTreeAnim = "DoWateringBerryTreeAnim" },
}
for module, names in pairs(aliases) do
  for name, target in pairs(names) do B[name] = delegate(module, target, module == "natives") end
end

if not Rse._systems.decorations then
  Rse.register("decorations", require("src.core.game3.rse.decoration_inventory"))
end

-- pokeruby/src/berry.c:1418
B.ObjectEventInteractionGetBerryTreeData = function(ctx, adapters)
  local NB = require("src.core.game3.scripting.natives_berry")
  local BT = require("src.core.game3.rse.berry_trees")
  local id, eo = NB.treeId(ctx)
  local tree = BT.get(nil, id)
  BT.allowGrowth(id)
  Rse.setSpecialVar(ctx, 0x8004, NB.sparkling(eo) and BT.STAGE_SPARKLING or tree.stage)
  Rse.setSpecialVar(ctx, 0x8005, BT.stagesWatered(tree))
  Rse.setSpecialVar(ctx, 0x8006, tree.berryYield)
  stringVar(ctx, adapters, 1, BT.name(tree.berry))
  return false
end

-- pokeruby/src/berry.c:1451
B.ObjectEventInteractionPlantBerryTree = function(ctx, adapters)
  local NB = require("src.core.game3.scripting.natives_berry")
  local BT = require("src.core.game3.rse.berry_trees")
  BT.plant(NB.treeId(ctx), BT.itemToBerry(Rse.specialVar(ctx, 0x800E)), BT.STAGE_PLANTED, true)
  return B.ObjectEventInteractionGetBerryTreeData(ctx, adapters)
end

return Rs
