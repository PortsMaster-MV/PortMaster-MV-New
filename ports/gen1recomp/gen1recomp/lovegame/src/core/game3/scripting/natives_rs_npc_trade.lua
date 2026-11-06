local R = require("src.core.game3.rse.init")
local Selection = require("src.core.game3.rs.party_selection")
local M = { BY_NAME = {} }
local B = M.BY_NAME

local function trade() return require("src.core.game3.scripting.natives_trade") end
local function pokemon() return require("src.core.game3.pokemon") end
local function selected(ctx, variable)
  local sess = R.session()
  return sess and sess.party and sess.party[R.specialVar(ctx, variable or 0x8004) + 1], sess
end
local function stringVar(ctx, adapters, index, value)
  if adapters and adapters.setStringVar then adapters.setStringVar(index, value) end
  if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[index] = value end
end
local function ret(ctx, value)
  R.setSpecialVar(ctx, 0x800D, value)
  return false, value
end

function M.mailTrainerId(otId)
  local value = math.floor(tonumber(otId) or 0) % 4294967296
  return (value % 256) * 16777216 + (math.floor(value / 256) % 256) * 65536
    + (math.floor(value / 65536) % 256) * 256 + math.floor(value / 16777216)
end

function M.createTradeMon(index, level)
  local T = trade()
  local entry = T.entry(index)
  if not entry then return nil end
  local mon = T.createTradeMon(index, level, {fixedPersonality = entry.personality})
  if not mon then return nil end
  mon.abilityNum = entry.abilityNum
  mon.otId = entry.otId % 65536
  mon.otSecretId = math.floor(entry.otId / 65536)
  mon.mail = 255
  if require("src.core.game3.mail").isMailItem(entry.heldItem) then
    local record = T.tradeMail(entry)
    if record then
      record.trainerId = M.mailTrainerId(entry.otId)
      T.setPartnerMail(0, record)
      mon.mail = 0
    end
  end
  return mon
end

B.SelectMonForNPCTrade = function(ctx, adapters)
  return Selection.choose(ctx, adapters, {menuType = Selection.NPC_TRADE})
end
B.GetInGameTradeSpeciesInfo = function(ctx, adapters)
  local entry = trade().entry(R.specialVar(ctx, 0x8004))
  if not entry then return ret(ctx, 0) end
  stringVar(ctx, adapters, 1, pokemon().name(entry.requestedSpecies))
  stringVar(ctx, adapters, 2, pokemon().name(entry.species))
  return ret(ctx, entry.requestedSpecies)
end
B.GetTradeSpecies = function(ctx)
  local mon = selected(ctx, 0x8005)
  return ret(ctx, mon and not pokemon().isEgg(mon) and tonumber(mon.species or mon.speciesId) or 0)
end
B.CreateInGameTradePokemon = function(ctx)
  local T = trade()
  T._offered = M.createTradeMon(R.specialVar(ctx, 0x8004), T.levelOfSlot(R.specialVar(ctx, 0x8005)))
  return false
end
B.DoInGameTradeScene = function(ctx, adapters)
  local T, index, slot = trade(), R.specialVar(ctx, 0x8004), R.specialVar(ctx, 0x8005)
  if not T._offered then T._offered = M.createTradeMon(index, T.levelOfSlot(slot)) end
  require("src.core.game3.scripting.natives").awaitState(ctx, T.sceneTask(ctx, adapters, index, slot))
  return false
end

B.ScrSpecial_CountPokemonMoves = function(ctx)
  local count, mon = 0, selected(ctx)
  for slot = 1, 4 do
    local move = pokemon().moveIdAt(mon, slot)
    if move and move ~= 0 then count = count + 1 end
  end
  return ret(ctx, count)
end
B.ScrSpecial_GetPokemonNicknameAndMoveName = function(ctx, adapters)
  local mon = selected(ctx)
  if not mon then return false end
  stringVar(ctx, adapters, 1, pokemon().displayMonName(mon))
  stringVar(ctx, adapters, 2, pokemon().moveName(pokemon().moveIdAt(mon, R.specialVar(ctx, 0x8005) + 1) or 0))
  return false
end
B.DeleteMonMove = function(ctx)
  require("src.core.game3.move_learn").forgetMove(selected(ctx), R.specialVar(ctx, 0x8005))
  return false
end
B.SelectMove = function(ctx, adapters)
  local mon, sess = selected(ctx)
  if not mon then R.setSpecialVar(ctx, 0x8005, 4); return false end
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    local Fade = require("src.ui.game3.fade")
    if not Fade.isActive() and Fade.mode == Fade.MODE.TO_BLACK and Fade.t >= 16 then Fade.clear() end
    local Message = package.loaded["src.ui.game3.message"]
    if Message and Message.isOpen() then Message.close() end
    require("src.ui.game3.summary_menu").openMenu(sess.party, R.specialVar(ctx, 0x8004) + 1, {
      session = sess, mode = "select_move", forgetMove = true,
      onSelectMove = function(slot)
        R.setSpecialVar(ctx, 0x8005, slot ~= nil and slot or 4)
        done()
      end,
    })
  end)
end

return M
