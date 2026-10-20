local R = require("src.core.game3.rse.init")
local D = require("src.core.game3.daycare")
local B = require("src.core.game3.breeding")
local M = {BY_NAME = {}}
local function variable(ctx, id) return R.specialVar(ctx, id) end
local function stringVar(ctx, adapters, i, value)
  if adapters and adapters.setStringVar then adapters.setStringVar(i, value) end
  if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[i] = value end
end
local function native(session)
  session.rsNative = session.rsNative or {}; return session.rsNative
end
local function selected(session) return tonumber(native(session).lastFieldPokeMenuOpened) or 0 end
local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}; for k, v in pairs(t) do out[k] = copy(v) end; return out
end
local function slot(ctx) return variable(ctx, 0x8004) + 1 end
local function state(session)
  local dc = D.stateOf(session)
  if (tonumber(dc.offspringPersonality) or 0) % 65536 ~= 0 then return 1 end
  local n = D.count(dc); return n > 0 and n + 1 or 0
end
M.state = state
-- pokeruby/daycare.c:807
M.BY_NAME.GetDaycareState = function() return false, state(R.session()) end
M.BY_NAME.GetDaycarePokemonCount = function() return false, D.count(D.stateOf(R.session())) end
M.BY_NAME.GetSelectedDaycareMonNickname = function(ctx, adapters)
  local s = R.session(); local mon = s.party and s.party[selected(s) + 1]
  stringVar(ctx, adapters, 1, D.nickname(mon)); return false, D.speciesOf(mon)
end
-- daycare.c:1071
M.BY_NAME.ChooseSendDaycareMon = function(ctx, adapters)
  local s = R.session()
  local Selection = require("src.core.game3.rs.party_selection")
  local function commit(value)
    Selection.commit(ctx, value, {onSelect = function(index) native(s).lastFieldPokeMenuOpened = index end})
  end
  local N = require("src.core.game3.scripting.natives")
  if adapters and adapters.chooseParty then
    return N.yieldHost(ctx, adapters, function(done)
      adapters.chooseParty({menuType = 6, nativePartyLayout = 0, cancelValue = 255,
        nativeModule = "src.ui.game3.rs.daycare_party", daycareActions = {"STORE", "SUMMARY", "EXIT"}, eggsCannotStore = true},
        function(index) commit(index); done() end)
    end)
  end
  return N.yieldHost(ctx, adapters, function(done)
    local Fade = require("src.ui.game3.fade")
    local restore = Fade.mode == Fade.MODE.TO_BLACK and not Fade.isActive() and (tonumber(Fade.t) or 0) >= 16
    if restore then Fade.clear() end
    require("src.ui.game3.rs.daycare_party").show(s, function(index)
      commit(index)
      if restore then Fade.begin(Fade.MODE.FROM_BLACK, 1, function() end) end
      done()
    end)
  end)
end
-- daycare.c:117
M.BY_NAME.StoreSelectedPokemonInDaycare = function()
  local s, Mail = R.session(), require("src.core.game3.mail")
  local index = selected(s) + 1; local mon = s.party and s.party[index]
  if not mon then return false end
  local dc, free = D.stateOf(s)
  for i = 1, 2 do if D.speciesOf(D.mon(dc, i)) == 0 then free = i; break end end
  if not free then return false end
  local record = Mail.monHasMail(mon) and Mail.slot(s, mon.mail) or nil
  record = copy(record)
  local previous = dc.mail and dc.mail[free]
  D.deposit(s, index)
  if record then require("src.core.game3.rs.daycare_mail").afterDeposit(s, mon, record, free, previous)
  else dc.mail[free] = previous end
  return false
end
-- daycare.c:190
M.BY_NAME.TakePokemonFromDaycare = function(ctx, adapters)
  local s = R.session(); local dc, index = D.stateOf(s), slot(ctx)
  local mon = D.mon(dc, index)
  stringVar(ctx, adapters, 1, D.nickname(mon))
  local mail = dc.mail and dc.mail[index]
  local hadMail = mail and mail.message and (tonumber(mail.message.itemId) or 0) ~= 0
  if not mon then return false, 0 end
  local species = D.withdraw(s, mon, dc.steps[index], mail)
  if hadMail then require("src.core.game3.rs.daycare_mail").clear(s, mail) end
  D.setMon(dc, index, nil); dc.steps[index] = 0
  if D.mon(dc, 2) and not D.mon(dc, 1) then
    D.setMon(dc, 1, D.mon(dc, 2)); D.setMon(dc, 2, nil)
    dc.steps[1], dc.steps[2] = dc.steps[2], 0
    dc.mail[1] = copy(dc.mail[2])
    if dc.mail[2] then require("src.core.game3.rs.daycare_mail").clear(s, dc.mail[2]) end
  end
  return false, species
end
M.BY_NAME.GetDaycareCost = function(ctx, adapters)
  local dc, index = D.stateOf(R.session()), slot(ctx)
  local mon = D.mon(dc, index)
  local cost = D.cost(mon, dc.steps[index])
  stringVar(ctx, adapters, 1, D.nickname(mon)); stringVar(ctx, adapters, 2, tostring(cost))
  R.setSpecialVar(ctx, 0x8005, cost); return false
end
M.BY_NAME.GetNumLevelsGainedFromDaycare = function(ctx, adapters)
  local dc, index = D.stateOf(R.session()), slot(ctx); local mon = D.mon(dc, index)
  if not mon then return false, 0 end
  local n = D.levelsGained(mon, dc.steps[index]) % 256
  stringVar(ctx, adapters, 1, D.nickname(mon)); stringVar(ctx, adapters, 2, tostring(n))
  return false, n
end
M.BY_NAME.GetDaycareMonNicknames = function(ctx, adapters)
  local dc = D.stateOf(R.session())
  local a, b = D.mon(dc, 1), D.mon(dc, 2)
  if a then
    stringVar(ctx, adapters, 1, D.nickname(a))
    local name = tostring(a.otName or a.ot or "")
    if tonumber(a.language) == 1 then name = "{JPN}" .. name .. "{ENG}" end
    stringVar(ctx, adapters, 3, name)
  end
  if b then stringVar(ctx, adapters, 2, D.nickname(b)) end
  return false
end
M.BY_NAME.SetDaycareCompatibilityString = function(ctx, adapters)
  local score = require("src.core.game3.rs.daycare").compatibility(D.stateOf(R.session()))
  local names = {[0] = "DaycareText_PlayOther", [20] = "DaycareText_DontLikeOther", [50] = "DaycareText_GetAlong", [70] = "DaycareText_GetAlongVeryWell"}
  stringVar(ctx, adapters, 4, require("src.core.game3.rom_text").plain(names[score] or names[70])); return false
end
M.BY_NAME.ShowDaycareLevelMenu = function(ctx)
  local s, done = R.session(), false
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  require("src.ui.game3.rs.daycare_level_menu").show(D.stateOf(s), function(value)
    native(s).lastFieldPokeMenuOpened = value
    R.setSpecialVar(ctx, 0x800D, value); done = true
  end)
  return false
end
M.BY_NAME.RejectEggFromDayCare = function() B.removeEgg(D.stateOf(R.session())); return false end
M.BY_NAME.GiveEggFromDaycare = function() B.giveEggFromDaycare(R.session()); return false end
M.BY_NAME.DaycareMonReceivedMail = function(ctx, adapters)
  local s = R.session(); local dc, index = D.stateOf(s), slot(ctx)
  local yes, a, b, c = require("src.core.game3.rs.daycare_mail").received(s, D.mon(dc, index), dc.mail and dc.mail[index])
  if yes then for i, value in ipairs({a, b, c}) do stringVar(ctx, adapters, i, value) end end
  return false, yes and 1 or 0
end
M.BY_NAME.ScriptHatchMon = function(ctx, adapters)
  local s = R.session(); local mon = s.party and s.party[slot(ctx)]
  if mon then B.hatchMon(s, mon); stringVar(ctx, adapters, 1, D.nickname(mon)) end
  return false
end
M.BY_NAME.EggHatch = function(ctx)
  local s, index = R.session(), variable(ctx, 0x8004)
  local mon = s and s.party and s.party[index + 1]
  if not mon or index < 0 or index >= 6 then return false end
  local done = false
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  local Audio = require("src.core.game3.audio")
  require("src.ui.game3.rs.egg_hatch").start(mon, {
    session = s, slot = index, savedSong = Audio.currentMapMusic(),
    onSavedSong = function(song) R.setSpecialVar(ctx, 0x8005, song) end,
    onDone = function() done = true end,
  })
  return false
end
return M
