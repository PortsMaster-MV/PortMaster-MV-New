local Link = require("src.core.game3.link.init")
local Union = require("src.core.game3.link.union_room")
local LinkBattle = require("src.core.game3.link.battle")
local LinkTrade = require("src.core.game3.link.trade")
local RecordMix = require("src.core.game3.link.record_mix")
local Family = require("src.core.game3.link.family")

local NativesLinkRse = {}
NativesLinkRse._berryBlenderPartnerIds = {}

NativesLinkRse.Link = Link
NativesLinkRse.Union = Union
NativesLinkRse.RecordMix = RecordMix

local function clearBerryBlenderPartnerObjects()
  local VirtualObjects = require("src.core.game3.virtual_objects")
  for _, id in ipairs(NativesLinkRse._berryBlenderPartnerIds) do
    VirtualObjects.remove(id)
  end
  NativesLinkRse._berryBlenderPartnerIds = {}
end

local function specialVarId(name)
  return require("src.core.game3.constants").active(Link.session()):var(name)
end

local function varResult(ctx)
  return require("src.core.game3.scripting.flags").getVar(nil, ctx, specialVarId("VAR_RESULT"))
end

-- pokeemerald/src/field_specials.c:3651-3780
local function linkRetireStatus(ctx, adapters)
  local lk = Link.link
  if not (lk and lk.isOpen and lk:isOpen() and lk.isReady and lk:isReady()) then return false end
  if lk.linkType ~= require("src.link.Game3Link").LINKTYPE.BATTLE_TOWER then return false end
  if type(lk.players) ~= "function" then return false end
  local playersOk, players = pcall(lk.players, lk)
  if not playersOk or type(players) ~= "table" or #players ~= 2 then return false end
  local seat = type(lk.getSeat) == "function" and tonumber(lk:getSeat()) or nil
  if seat ~= 0 and seat ~= 1 then return false end
  local Natives = require("src.core.game3.scripting.natives")
  local Rse = require("src.core.game3.rse.init")
  local Constants = require("src.core.game3.constants").active(Link.session())
  local localChoice = Rse.specialVar(ctx, Constants:var("VAR_0x8004")) == 1 and 1 or 0
  local peerChoice, result
  local phase, sentReady, finished = 0, false, false
  local partnerRetired = false
  Rse.setSpecialVar(ctx, specialVarId("VAR_RESULT"), 0)
  local yielded = Natives.yieldHost(ctx, adapters, function() end)
  if not yielded then return false end
  lk:send({ type = "game3_tower_retire_choice", choice = localChoice })
  ctx.nativePoll = function()
    if finished then return true end
    if not lk:isOpen() then
      finished = true
      return true
    end
    if phase == 0 then
      local msg = lk:take("game3_tower_retire_choice")
      if msg and (msg.choice == 0 or msg.choice == 1) then
        peerChoice = msg.choice
        if seat == 0 then
          Rse.setSpecialVar(ctx, Constants:var("VAR_0x8005"), peerChoice)
          if localChoice == 1 and peerChoice == 1 then result = 1
          elseif localChoice == 0 and peerChoice == 1 then result = 2
          elseif localChoice == 1 and peerChoice == 0 then result = 3
          else result = 0 end
          Rse.setSpecialVar(ctx, specialVarId("VAR_RESULT"), result)
          lk:send({ type = "game3_tower_retire_result", result = result })
          phase = 2
        else
          phase = 1
        end
      end
    elseif phase == 1 then
      local msg = lk:take("game3_tower_retire_result")
      if msg and msg.result and msg.result >= 0 and msg.result <= 3 then
        result = math.floor(msg.result)
        Rse.setSpecialVar(ctx, specialVarId("VAR_RESULT"), result)
        phase = 2
      end
    end
    if phase == 2 then
      partnerRetired = (seat == 0 and result == 2) or (seat == 1 and result == 3)
      if partnerRetired and adapters and (adapters.openMessageAsync or adapters.openMessage) then
        phase = 3
        local RomText = require("src.core.game3.rom_text")
        local text = RomText.plain("gText_YourPartnerHasRetired")
        if adapters.openMessageAsync then
          local messageDone = false
          adapters.openMessageAsync(text, function() messageDone = true end)
          ctx._towerRetireMessageDone = function() return messageDone end
        else
          adapters.openMessage(text)
          phase = 4
        end
      else
        phase = 4
      end
    end
    if phase == 3 then
      if ctx._towerRetireMessageDone and ctx._towerRetireMessageDone() then
        ctx._towerRetireMessageDone = nil
        phase = 4
      end
    end
    if phase == 4 then
      if not sentReady then
        lk:send({ type = "game3_tower_retire_standby" })
        sentReady = true
      end
      if lk:take("game3_tower_retire_standby") then
        finished = true
      end
    end
    return finished
  end
  return true
end

NativesLinkRse.BY_NAME = {
  -- pokeemerald/src/field_specials.c:3640
  BattleTowerReconnectLink = function(ctx, adapters)
    local Game3Link = require("src.link.Game3Link")
    local linkType = Game3Link.LINKTYPE.BATTLE_TOWER
    local live = Link.link
    if live and live.isReady and live:isReady() then return false end
    if not (live and live.isOpen and live:isOpen()) then
      if not Link.beginConnect({ linkType = linkType }) then return false end
    else
      live.linkType = linkType
    end
    local Natives = require("src.core.game3.scripting.natives")
    if not Natives.yieldHost(ctx, adapters, function() end) then return false end
    local ticks, retryAt = 0, 0
    ctx.nativePoll = function()
      ticks = ticks + 1
      local current = Link.link
      if current and current.isReady and current:isReady() then return true end
      if current and current.isOpen and not current:isOpen() then Link.link = nil end
      if not Link.link and ticks >= retryAt then
        retryAt = ticks + 60
        Link.beginConnect({ linkType = linkType })
      end
      -- pokeemerald/src/cable_club.c:1271
      return ticks >= 1800
    end
    return true
  end,
  -- pokeemerald/src/cable_club.c:703
  TryBerryBlenderLinkup = function(ctx, adapters)
    return LinkBattle.createLinkupTask(ctx, adapters, LinkBattle.BERRY_BLENDER)
  end,
  -- pokeemerald/src/cable_club.c:1324
  TrySetBattleTowerLinkType = function()
    local lk = Link.link
    if lk and lk.isOpen and lk:isOpen() then
      lk.linkType = require("src.link.Game3Link").LINKTYPE.BATTLE_TOWER
    end
    return false
  end,
  -- pokeemerald/src/field_specials.c:495
  SpawnLinkPartnerObjectEvent = function(ctx)
    clearBerryBlenderPartnerObjects()
    local lk = Link.link
    if not (lk and lk.isOpen and lk:isOpen() and lk.players) then return false end
    local ok, players = pcall(lk.players, lk)
    if not ok or type(players) ~= "table" then return false end

    local session = Link.session()
    local Constants = require("src.core.game3.constants").active(session)
    local brendan = Constants:require("event_objects", "OBJ_EVENT_GFX_RIVAL_BRENDAN_NORMAL")
    local may = Constants:require("event_objects", "OBJ_EVENT_GFX_RIVAL_MAY_NORMAL")
    local rsBrendan = Constants:require("event_objects", "OBJ_EVENT_GFX_LINK_RS_BRENDAN")
    local rsMay = Constants:require("event_objects", "OBJ_EVENT_GFX_LINK_RS_MAY")
    local Player = require("src.core.game3.player")
    local px, py = tonumber(Player.cellX) or 0, tonumber(Player.cellY) or 0
    local facing = tostring(Player.facing or "down"):lower()
    local facingPos = ({
      right = { 0, px + 1, py },
      up = { 1, px, py - 1 },
      left = { 2, px - 1, py },
      down = { 3, px, py + 1 },
    })[facing] or { 3, px, py + 1 }
    local dirIndex, x, y = (table.unpack or unpack)(facingPos)
    local offsets = { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } }
    local virtualDirection = { [0] = 2, [1] = 3, [2] = 1, [3] = 4 }
    local ownSeat = LinkBattle.multiplayerId()
    local Constants = require("src.core.game3.constants").active(Link.session())
    local count = Link.getVar(ctx, Constants:var("VAR_0x8004"))
    if count < 1 then count = #players end
    local VirtualObjects = require("src.core.game3.virtual_objects")
    for index, player in ipairs(players) do
      local seat = tonumber(player.seat) or (index - 1)
      if index <= count and seat ~= ownSeat then
        local offset = offsets[dirIndex + 1]
        local virtualId = 0x7F00 + seat
        local female = tonumber(player.gender) == 1
        local rubySapphire = player.version == "ruby" or player.version == "sapphire"
        local graphicsId = rubySapphire and (female and rsMay or rsBrendan)
          or (female and may or brendan)
        VirtualObjects.spawn(virtualId, graphicsId, x + offset[1], y + offset[2], 3,
          virtualDirection[dirIndex])
        NativesLinkRse._berryBlenderPartnerIds[#NativesLinkRse._berryBlenderPartnerIds + 1] = virtualId
        dirIndex = (dirIndex + 1) % 4
      end
    end
    return false
  end,
  -- pokeemerald/src/field_specials.c:478
  GetLinkPartnerNames = function(ctx, adapters)
    local lk = Link.link
    local players = {}
    if lk and lk.isOpen and lk:isOpen() and lk.players then
      local ok, rows = pcall(lk.players, lk)
      if ok and type(rows) == "table" then players = rows end
    end
    local ownSeat = LinkBattle.multiplayerId()
    local n = #players > 0 and #players or 1
    local slot = 1
    for _, player in ipairs(players) do
      if not player.isLocal and tonumber(player.seat) ~= ownSeat and slot <= 3 then
        local name = tostring(player.name or "")
        if name ~= "" then
          if adapters and adapters.setStringVar then adapters.setStringVar(slot, name) end
          if ctx and ctx.stringVars then ctx.stringVars[slot] = name end
          slot = slot + 1
        end
      end
    end
    return false, n
  end,
  -- pokeemerald/src/cable_club.c:806
  CableClubSaveGame = function()
    local game = Link.game()
    if game and type(game.saveGame) == "function" then pcall(game.saveGame, game) end
    return false
  end,
  -- pokeemerald/src/start_menu.c:1412
  SaveForBattleTowerLink = function()
    local game = Link.game()
    if game and type(game.saveGame) == "function" then game:saveGame() end
    return false
  end,
  -- pokeemerald/src/field_specials.c:3651
  LinkRetireStatusWithBattleTowerPartner = linkRetireStatus,
  -- pokeemerald/src/field_specials.c:2766
  SetBattleTowerLinkPlayerGfx = function(ctx)
    local lk = Link.link
    if not (lk and lk.isOpen and lk:isOpen() and lk.players) then return false end
    local ok, players = pcall(lk.players, lk)
    if not ok or type(players) ~= "table" then return false end
    local session = Link.session()
    local Constants = require("src.core.game3.constants").active(session)
    local firstVar = Constants:var("VAR_OBJ_GFX_ID_F")
    local male = Constants:require("event_objects", "OBJ_EVENT_GFX_BRENDAN_NORMAL")
    local female = Constants:require("event_objects", "OBJ_EVENT_GFX_RIVAL_MAY_NORMAL")
    for index, player in ipairs(players) do
      if index <= 2 then
        local slot = tonumber(player.seat) or (index - 1)
        if slot <= 1 then
          Link.setVar(ctx, firstVar - slot, tonumber(player.gender) == 1 and female or male)
        end
      end
    end
    return false
  end,
  -- pokeemerald/src/field_control_avatar.c:995
  SetCableClubWarp = function(ctx)
    Link.setCableClubWarp(ctx)
    return false
  end,
  -- pokeemerald/src/field_screen_effect.c:601
  DoCableClubWarp = function(ctx, adapters)
    return Link.doCableClubWarp(ctx, adapters)
  end,
  -- pokeemerald/src/field_screen_effect.c:641
  ReturnFromLinkRoom = function(ctx, adapters)
    Link.returnFromLinkRoom(ctx, adapters)
    return false
  end,
  -- pokeemerald/src/cable_club.c:1023
  CleanupLinkRoomState = function(ctx, adapters)
    Link.cleanupLinkRoomState(ctx, adapters)
    return false
  end,
  -- pokeemerald/src/cable_club.c:1036
  ExitLinkRoom = function(ctx, adapters)
    Link.exitLinkRoom(ctx, adapters)
    return false
  end,
  -- pokeemerald/src/cable_club.c:571
  TryBattleLinkup = function(ctx, adapters)
    return LinkBattle.tryBattleLinkup(ctx, adapters)
  end,
  -- pokeemerald/src/cable_club.c:610
  TryTradeLinkup = function(ctx, adapters)
    return LinkTrade.tryTradeLinkup(ctx, adapters)
  end,
  -- pokeemerald/src/cable_club.c:617
  TryRecordMixLinkup = function(ctx, adapters)
    return LinkBattle.tryRecordMixLinkup(ctx, adapters)
  end,
  -- pokeemerald/src/cable_club.c:625
  ValidateMixingGameLanguage = function(ctx)
    RecordMix.validateMixingGameLanguage(ctx, varResult(ctx))
    return false
  end,
  -- pokeemerald/src/record_mixing.c:166
  RecordMixingPlayerSpotTriggered = function(ctx, adapters)
    return RecordMix.playerSpotTriggered(ctx, adapters)
  end,
  -- pokeemerald/src/cable_club.c:1180
  ColosseumPlayerSpotTriggered = function(ctx, adapters)
    return LinkBattle.enterColosseumPlayerSpot(ctx, adapters)
  end,
  -- pokeemerald/src/cable_club.c:1160
  PlayerEnteredTradeSeat = function(ctx, adapters)
    return LinkTrade.enterTradeSeat(ctx, adapters)
  end,
  -- pokeemerald/src/script_pokemon_util.c:99
  HasEnoughMonsForDoubleBattle = function(ctx)
    return LinkBattle.hasEnoughMonsForDoubleBattle(ctx)
  end,
  -- pokeemerald/src/link.c:400
  CloseLink = function()
    Link.closeLink("close_link")
    return false
  end,
  -- pokeemerald/src/load_save.c:208
  LoadPlayerBag = function()
    Link.loadPlayerBag()
    return false
  end,
  -- pokeemerald/src/link.c:237
  IsWirelessAdapterConnected = function(ctx, adapters)
    return Link.isWirelessAdapterConnected(ctx, adapters)
  end,
  -- pokeemerald/src/union_room.c:375
  TryBecomeLinkLeader = function(ctx, adapters)
    return Union.tryBecomeLinkLeader(ctx, adapters)
  end,
  -- pokeemerald/src/union_room.c:970
  TryJoinLinkGroup = function(ctx, adapters)
    return Union.tryJoinLinkGroup(ctx, adapters)
  end,
  -- pokeemerald/src/union_room.c:2421
  RunUnionRoom = function(ctx, adapters)
    Union.run(ctx, adapters)
    return false, 0
  end,
  -- pokeemerald/src/wireless_communication_status_screen.c:193
  ShowWirelessCommunicationScreen = function(ctx, adapters)
    return Link.showWirelessCommunicationScreen(ctx, adapters)
  end,
  -- pokeemerald/src/union_room.c:3294
  InitUnionRoom = function(ctx)
    Union.init(ctx)
    return false, 0
  end,
  -- pokeemerald/src/union_room.c:3379
  BufferUnionRoomPlayerName = function(ctx, adapters)
    return Union.bufferPlayerName(ctx, adapters)
  end,
  -- pokeemerald/src/union_room.c:4344
  Script_ResetUnionRoomTrade = function()
    Union.resetTrade()
    return false, 0
  end,
  -- pokeemerald/src/cable_club.c:1196
  Script_ShowLinkTrainerCard = function(ctx, adapters)
    return Link.showLinkTrainerCard(ctx, adapters)
  end,
  -- pokeemerald/src/event_object_lock.c:119
  Script_FacePlayer = function(ctx, adapters)
    if adapters and adapters.facePlayer then
      local okF, Flags = pcall(require, "src.core.game3.scripting.flags")
      if okF then adapters.facePlayer(Flags.getVar(nil, ctx, Family.var(nil, "VAR_FACING"))) end
    end
    return false
  end,
  -- pokeemerald/src/event_object_lock.c:124
  Script_ClearHeldMovement = function()
    return false
  end,
  -- pokeemerald/src/mystery_gift.c:156
  ValidateSavedWonderCard = function()
    local sess = Link.session()
    if require("src.core.game3.rse.init").call("eventIslands", "pendingGift", nil, nil, sess) ~= nil then
      return false, 1
    end
    return false, require("src.core.game3.mystery_gift").validateSavedCard(sess) and 1 or 0
  end,
}

-- pokeemerald/include/constants/script_menu.h:92
NativesLinkRse.MULTI_LINK_LEADER = 81

local okM, Multi = pcall(require, "src.core.game3.scripting.multichoice")
if okM and type(Multi) == "table" then
  Multi.OVERRIDES = Multi.OVERRIDES or {}
  local prev = Multi.OVERRIDES[NativesLinkRse.MULTI_LINK_LEADER]
  Multi.OVERRIDES[NativesLinkRse.MULTI_LINK_LEADER] = function(ctx, row, done)
    if Family.of() ~= "rse" then
      if type(prev) == "function" then return prev(ctx, row, done) end
      return false
    end
    return Union.directModes(ctx, row, done)
  end
end

return NativesLinkRse
