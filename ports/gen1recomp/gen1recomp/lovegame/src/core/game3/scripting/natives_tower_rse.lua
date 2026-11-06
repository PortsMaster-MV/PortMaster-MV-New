local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")

local NativesTowerRse = {}

local function Tower() return require("src.core.game3.rse.frontier.tower") end

local FUNCS = {}

local function T() return Tower().FUNC end

-- pokeemerald/src/battle_tower.c:802
local function build()
  local F = T()
  -- pokeemerald/src/battle_tower.c:906
  FUNCS[F.INIT] = function(_, _, s) Tower().init(s) end
  -- pokeemerald/src/battle_tower.c:924
  FUNCS[F.GET_DATA] = function(ctx, _, s) Tower().getData(ctx, s) end
  -- pokeemerald/src/battle_tower.c:945
  FUNCS[F.SET_DATA] = function(ctx, _, s) Tower().setData(ctx, s) end
  -- pokeemerald/src/battle_tower.c:1051
  FUNCS[F.SET_OPPONENT] = function(_, _, s) Tower().setNextOpponent(s) end
  -- pokeemerald/src/battle_tower.c:969
  FUNCS[F.SET_BATTLE_WON] = function(ctx, _, s) Tower().setBattleWon(ctx, s) end
  -- pokeemerald/src/battle_tower.c:2769
  FUNCS[F.GIVE_RIBBONS] = function(ctx, _, s) Tower().giveRibbons(ctx, s) end
  -- pokeemerald/src/battle_tower.c:2194
  FUNCS[F.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Tower().save) end
  -- pokeemerald/src/battle_tower.c:1936
  FUNCS[F.GET_OPPONENT_INTRO] = function(ctx, adapters, s) Tower().opponentIntro(ctx, adapters, s) end
  -- pokeemerald/src/battle_tower.c:2209
  FUNCS[F.NOP] = function() end
  FUNCS[F.NOP2] = function() end
  -- pokeemerald/src/battle_tower.c:2272
  FUNCS[F.LOAD_PARTNERS] = function(_, _, s) Tower().loadPartners(s) end
  -- pokeemerald/src/battle_tower.c:2461
  FUNCS[F.PARTNER_MSG] = function(ctx, adapters, s) Tower().partnerMessage(ctx, adapters, s) end
  -- pokeemerald/src/battle_tower.c:2570
  FUNCS[F.LOAD_LINK_OPPONENTS] = function(ctx, adapters, s)
    require("src.core.game3.link.tower_link").loadLinkMultiOpponents(ctx, s, adapters)
  end
  -- pokeemerald/src/battle_tower.c:2659
  FUNCS[F.TRY_CLOSE_LINK] = function() end
  -- pokeemerald/src/battle_tower.c:2665
  FUNCS[F.SET_PARTNER_GFX] = function(_, _, s) Tower().setPartnerGfx(s) end
  -- pokeemerald/src/battle_tower.c:2671
  FUNCS[F.SET_INTERVIEW_DATA] = function(_, _, s) Tower().setInterviewData(s) end
end

-- pokeemerald/src/battle_tower.c:901
function NativesTowerRse.call(ctx, adapters)
  if next(FUNCS) == nil then build() end
  local s = Rse.session()
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  local fn = FUNCS[id]
  if not (s and fn) then
    Rse.missing("tower", "CallBattleTowerFunc " .. tostring(id), adapters and adapters.log)
    return false
  end
  return fn(ctx, adapters, s) == true
end

NativesTowerRse.FUNCS = FUNCS

NativesTowerRse.BY_NAME = {
  -- pokeemerald/src/field_specials.c:1279
  GetBattleTowerSinglesStreak = function()
    local sess = Rse.session()
    local stats = sess and sess.gameStats or {}
    return false, tonumber(stats[Util.GAME_STAT_BATTLE_TOWER_SINGLES_STREAK]) or 0
  end,
  -- pokeemerald/src/field_specials.c:1550
  TryInitBattleTowerAwardManObjectEvent = function() return false end,
  -- pokeemerald/src/battle_records.c:315
  ShowLinkBattleRecords = function()
    require("src.ui.game3.rse.frontier_records").showLinkBattle(Rse.session())
    return false
  end,
  -- pokeemerald/src/battle_tower.c:901
  CallBattleTowerFunc = function(ctx, adapters) return NativesTowerRse.call(ctx, adapters) end,
}

require("src.core.game3.link.tower_link")

return NativesTowerRse
