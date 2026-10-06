local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")
local Pike = require("src.core.game3.rse.frontier.pike")

local NativesPike = {}

local FN = Pike.FUNC
local FUNCS = {}

local function result(ctx, v)
  if v == true then v = 1 elseif v == false then v = 0 end
  Util.setResult(ctx, v)
end

local function awaitState(ctx, poll)
  require("src.core.game3.scripting.natives").awaitState(ctx, poll)
end

-- pokeemerald/src/battle_pike.c:479
FUNCS[FN.SET_ROOM_TYPE] = function(ctx, _, s) Pike.setRoomType(ctx, s) end
FUNCS[FN.GET_DATA] = function(ctx, _, s) Pike.getData(ctx, s) end
FUNCS[FN.SET_DATA] = function(ctx, _, s) Pike.setData(ctx, s) end
FUNCS[FN.IS_FINAL_ROOM] = function(ctx, _, s) result(ctx, Pike.isNextRoomFinal(s)) end
FUNCS[FN.SET_ROOM_OBJECTS] = function(_, _, s) Pike.setupRoomObjects(s) end
FUNCS[FN.GET_ROOM_TYPE] = function(ctx, _, s) result(ctx, Pike.rt(s).roomType) end
FUNCS[FN.SET_IN_WILD_MON_ROOM] = function(_, _, s) Pike.rt(s).inWildMonRoom = true end
FUNCS[FN.CLEAR_IN_WILD_MON_ROOM] = function(_, _, s) Pike.rt(s).inWildMonRoom = false end
FUNCS[FN.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Pike.save) end
FUNCS[FN.DUMMY_1] = function() end
FUNCS[FN.DUMMY_2] = function() end
FUNCS[FN.GET_ROOM_STATUS] = function(ctx, _, s)
  local v = Pike.roomInflictedStatus(s)
  if v ~= nil then result(ctx, v) end
end
FUNCS[FN.GET_ROOM_STATUS_MON] = function(ctx, _, s) result(ctx, Pike.rt(s).statusMon) end
FUNCS[FN.HEAL_ONE_TWO_MONS] = function(ctx, _, s) result(ctx, Pike.healOneOrTwo(s)) end
FUNCS[FN.BUFFER_NPC_MSG] = function(ctx, adapters, s) Pike.npcMessage(ctx, adapters, s) end
-- pokeemerald/src/battle_pike.c:775
FUNCS[FN.STATUS_SCREEN_FLASH] = function(ctx)
  local done = false
  Pike.statusFlash(function() done = true end)
  awaitState(ctx, function() return done end)
end
FUNCS[FN.IS_IN] = function(ctx, _, s) result(ctx, Pike.inBattlePike(s)) end
FUNCS[FN.SET_HINT_ROOM] = function(ctx, _, s) result(ctx, Pike.setHintedRoom(s)) end
FUNCS[FN.GET_HINT_ROOM_ID] = function(ctx, _, s) result(ctx, Pike.frontier(s).pikeHintedRoomIndex) end
FUNCS[FN.GET_ROOM_TYPE_HINT] = function(ctx, _, s) result(ctx, Pike.roomTypeHint(s)) end
FUNCS[FN.CLEAR_TRAINER_IDS] = function(_, _, s) Pike.clearTrainerIds(s) end
FUNCS[FN.GET_TRAINER_INTRO] = function(ctx, adapters, s) Pike.trainerIntro(ctx, adapters, s) end
FUNCS[FN.GET_QUEEN_FIGHT_TYPE] = function(ctx, _, s) result(ctx, Pike.queenFightType(s, 0)) end
FUNCS[FN.HEAL_MONS_BEFORE_QUEEN] = function(ctx, _, s) result(ctx, Pike.healBeforeQueen(ctx, s)) end
FUNCS[FN.SET_HEAL_ROOMS_DISABLED] = function(ctx, _, s)
  Pike.frontier(s).pikeHealingRoomsDisabled = Rse.specialVar(ctx, Util.VAR_0x8005)
end
FUNCS[FN.IS_PARTY_FULL_HEALTH] = function(ctx, _, s) result(ctx, Pike.isPartyFullHealed(s)) end
FUNCS[FN.SAVE_HELD_ITEMS] = function(_, _, s) Pike.saveHeldItems(s) end
FUNCS[FN.RESET_HELD_ITEMS] = function(_, _, s) Pike.restoreHeldItems(s) end
FUNCS[FN.INIT] = function(_, _, s) Pike.init(s) end
NativesPike.FUNCS = FUNCS

-- pokeemerald/src/battle_pike.c:542
function NativesPike.call(ctx, adapters)
  local s = Rse.session()
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  local fn = FUNCS[id]
  if not (s and fn) then
    Rse.missing("pike", "CallBattlePikeFunction " .. tostring(id), adapters and adapters.log)
    return false
  end
  return fn(ctx, adapters, s) == true
end

-- pokeemerald/src/field_specials.c:3832
function NativesPike.closeCurtain()
  local s = Rse.session()
  if not s then return false end
  local P = package.loaded["src.core.game3.player"]
  local px = tonumber(P and P.cellX) or tonumber(s.x) or 0
  local py = tonumber(P and P.cellY) or tonumber(s.y) or 0
  Pike.closeCurtain(s, px, py)
  return false
end

NativesPike.BY_NAME = {
  CallBattlePikeFunction = NativesPike.call,
  CloseBattlePikeCurtain = NativesPike.closeCurtain,
}


return NativesPike
