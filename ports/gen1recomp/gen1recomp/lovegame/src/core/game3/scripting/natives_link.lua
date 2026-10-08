local Link = require("src.core.game3.link.init")
local Union = require("src.core.game3.link.union_room")
local LinkBattle = require("src.core.game3.link.battle")
local LinkTrade = require("src.core.game3.link.trade")
local Std = require("src.core.game3.scripting.stdscripts")

local NativesLink = {}

NativesLink.SPECIAL = {
  SetCableClubWarp = 0x01,
  DoCableClubWarp = 0x02,
  ReturnFromLinkRoom = 0x03,
  CleanupLinkRoomState = 0x04,
  ExitLinkRoom = 0x05,
  Script_ShowLinkTrainerCard = 0x2A,
  TryBattleLinkup = 0x1C,
  TryTradeLinkup = 0x1D,
  TryRecordMixLinkup = 0x1E,
  CloseLink = 0x1F,
  EnterColosseumPlayerSpot = 0x20,
  EnterTradeSeat = 0x21,
  StartWiredCableClubTrade = 0x22,
  CableClub_AskSaveTheGame = 0x23,
  HasEnoughMonsForDoubleBattle = 0x3D,
  Field_AskSaveTheGame = 0x5D,
  LoadPlayerBag = 0x14B,
  IsWirelessAdapterConnected = 0x16A,
  TryBecomeLinkLeader = 0x16B,
  TryJoinLinkGroup = 0x16C,
  RunUnionRoom = 0x16D,
  ShowWirelessCommunicationScreen = 0x16E,
  InitUnionRoom = 0x182,
  BufferUnionRoomPlayerName = 0x183,
  Script_ResetUnionRoomTrade = 0x1B3,
}

NativesLink.Link = Link
NativesLink.Union = Union
NativesLink.Battle = LinkBattle
NativesLink.Trade = LinkTrade

for name, id in pairs(NativesLink.SPECIAL) do
  if Std.SPECIAL[name] == nil then Std.SPECIAL[name] = id end
  if Std.SPECIAL_NAME_BY_ID[id] == nil then Std.SPECIAL_NAME_BY_ID[id] = name end
end

NativesLink.BY_NAME = {
  -- pokefirered/src/field_control_avatar.c:1173
  SetCableClubWarp = function(ctx)
    Link.setCableClubWarp(ctx)
    return false
  end,
  -- pokefirered/src/field_fadetransition.c:646
  DoCableClubWarp = function(ctx, adapters)
    return Link.doCableClubWarp(ctx, adapters)
  end,
  -- pokefirered/src/field_fadetransition.c:685
  ReturnFromLinkRoom = function(ctx, adapters)
    Link.returnFromLinkRoom(ctx, adapters)
    return false
  end,
  -- pokefirered/src/cable_club.c:809
  CleanupLinkRoomState = function(ctx, adapters)
    Link.cleanupLinkRoomState(ctx, adapters)
    return false
  end,
  -- pokefirered/src/cable_club.c:821
  ExitLinkRoom = function(ctx, adapters)
    Link.exitLinkRoom(ctx, adapters)
    return false
  end,
  -- pokefirered/src/cable_club.c:493
  TryBattleLinkup = function(ctx, adapters)
    return LinkBattle.tryBattleLinkup(ctx, adapters)
  end,
  -- pokefirered/src/cable_club.c:525
  TryTradeLinkup = function(ctx, adapters)
    return LinkTrade.tryTradeLinkup(ctx, adapters)
  end,
  -- pokefirered/src/cable_club.c:945
  EnterTradeSeat = function(ctx, adapters)
    return LinkTrade.enterTradeSeat(ctx, adapters)
  end,
  -- pokefirered/src/cable_club.c:958
  StartWiredCableClubTrade = function(ctx, adapters)
    return LinkTrade.startWiredCableClubTrade(ctx, adapters)
  end,
  -- pokefirered/src/cable_club.c:532
  TryRecordMixLinkup = function(ctx, adapters)
    return LinkBattle.tryRecordMixLinkup(ctx, adapters)
  end,
  -- pokefirered/src/script_pokemon_util.c:90
  HasEnoughMonsForDoubleBattle = function(ctx)
    return LinkBattle.hasEnoughMonsForDoubleBattle(ctx)
  end,
  -- pokefirered/src/link.c:419
  CloseLink = function()
    Link.closeLink("close_link")
    return false
  end,
  -- pokefirered/src/cable_club.c:964
  EnterColosseumPlayerSpot = function(ctx, adapters)
    return LinkBattle.enterColosseumPlayerSpot(ctx, adapters)
  end,
  -- pokefirered/src/cable_club.c:621
  CableClub_AskSaveTheGame = function(ctx, adapters)
    return Link.askSaveTheGame(ctx, adapters)
  end,
  -- pokefirered/src/start_menu.c:620
  Field_AskSaveTheGame = function(ctx, adapters)
    return Link.askSaveTheGame(ctx, adapters)
  end,
  -- pokefirered/src/load_save.c:208
  LoadPlayerBag = function()
    Link.loadPlayerBag()
    return false
  end,
  -- pokefirered/src/link.c:243
  IsWirelessAdapterConnected = function(ctx, adapters)
    return Link.isWirelessAdapterConnected(ctx, adapters)
  end,
  -- pokefirered/src/union_room.c:382
  TryBecomeLinkLeader = function(ctx, adapters)
    return Union.tryBecomeLinkLeader(ctx, adapters)
  end,
  -- pokefirered/src/union_room.c:1126
  TryJoinLinkGroup = function(ctx, adapters)
    return Union.tryJoinLinkGroup(ctx, adapters)
  end,
  -- pokefirered/src/union_room.c:2579
  RunUnionRoom = function(ctx, adapters)
    Union.run(ctx, adapters)
    return false, 0
  end,
  -- pokefirered/src/wireless_communication_status_screen.c:195
  ShowWirelessCommunicationScreen = function(ctx, adapters)
    return Link.showWirelessCommunicationScreen(ctx, adapters)
  end,
  -- pokefirered/src/union_room.c:3515
  InitUnionRoom = function(ctx)
    Union.init(ctx)
    return false, 0
  end,
  -- pokefirered/src/union_room.c:3606
  BufferUnionRoomPlayerName = function(ctx, adapters)
    return Union.bufferPlayerName(ctx, adapters)
  end,
  -- pokefirered/src/union_room.c:4595
  Script_ResetUnionRoomTrade = function()
    Union.resetTrade()
    return false, 0
  end,
  -- pokefirered/src/cable_club.c:980
  Script_ShowLinkTrainerCard = function(ctx, adapters)
    return Link.showLinkTrainerCard(ctx, adapters)
  end,
  -- pokefirered/src/event_object_lock.c:106, data/scripts/cable_club.inc:699
  Script_FacePlayer = function(ctx, adapters)
    if adapters and adapters.facePlayer then
      local okF, Flags = pcall(require, "src.core.game3.scripting.flags")
      if okF then adapters.facePlayer(Flags.getVar(nil, ctx, 0x800F)) end
    end
    return false
  end,
  -- pokefirered/src/event_object_lock.c:111, data/scripts/cable_club.inc:701
  Script_ClearHeldMovement = function()
    return false
  end,
}
Std.legacyHandlers(NativesLink)

local okM, Multi = pcall(require, "src.core.game3.scripting.multichoice")
if okM and type(Multi) == "table" then
  Multi.OVERRIDES = Multi.OVERRIDES or {}
  -- pokefirered/data/scripts/cable_club.inc:956
  Multi.OVERRIDES[Union.MULTICHOICE_JOIN_OR_LEAD] = Union.directModes
end

-- pokefirered/src/union_room.c:3606 natives_queries sorts after this module, so its
local okQ, Queries = pcall(require, "src.core.game3.scripting.natives_queries")
if okQ and type(Queries) == "table" and type(Queries.BY_NAME) == "table" then
  Queries.BY_NAME.BufferUnionRoomPlayerName = NativesLink.BY_NAME.BufferUnionRoomPlayerName
  Std.legacyHandlers(Queries)
end

return NativesLink
