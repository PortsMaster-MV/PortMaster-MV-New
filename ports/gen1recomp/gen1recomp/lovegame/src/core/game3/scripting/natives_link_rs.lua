local Link = require("src.core.game3.link.init")
local Battle = require("src.core.game3.link.battle")
local Trade = require("src.core.game3.link.trade")
local Entry = require("src.core.game3.rs.link_entry")
local Field = require("src.core.game3.rs.link_field")

local M = {}
M.BY_NAME = {
  -- pokeruby/src/record_mixing.c:47
  RecordMixingPlayerSpotTriggered = function(ctx, adapters)
    return require("src.core.game3.link.record_mix").playerSpotTriggered(ctx, adapters)
  end,
  SetCableClubWarp = function(ctx) Link.setCableClubWarp(ctx); return false end,
  DoCableClubWarp = function(ctx, adapters) return Link.doCableClubWarp(ctx, adapters) end,
  -- pokeruby/src/cable_club.c:558
  sub_808347C = function(ctx, adapters)
    return Entry.run(ctx, adapters, Entry.SERVICES[Link.getVar(ctx, 0x8004)], Battle.tryBattleLinkup)
  end,
  sub_80834E4 = function(ctx, adapters) return Entry.run(ctx, adapters, Entry.SERVICES.trade, Trade.tryTradeLinkup) end,
  -- pokeruby/src/cable_club.c:590
  sub_808350C = function(ctx, adapters)
    Link.setResult(ctx, 0)
    return Entry.run(ctx, adapters, Entry.SERVICES.records, Battle.tryRecordMixLinkup)
  end,
  sub_8083614 = function(ctx, adapters)
    return Entry.run(ctx, adapters, Entry.SERVICES.blender, function(c, a)
      return Battle.createLinkupTask(c, a, Entry.SERVICES.blender)
    end)
  end,
  sub_808363C = function(ctx, adapters)
    local C = require("src.core.game3.constants").active(Link.session())
    local spec = Entry.contest(Link.getVar(ctx, C:var("VAR_CONTEST_CATEGORY")))
    return Entry.run(ctx, adapters, spec, function(c, a) return Battle.createLinkupTask(c, a, spec) end)
  end,
  SpawnBerryBlenderLinkPlayerSprites = Field.spawnBlenderPlayers,
  sub_80C5568 = Field.chooseBattleParty,
  GetNameOfEnigmaBerryInPlayerParty = Field.enigmaInParty,
  BufferEReaderTrainerName = Field.eReaderName,
  SetEReaderTrainerGfxId = Field.eReaderGfx,
  ScriptGetMultiplayerId = Field.multiplayerId,
  sub_8064EAC = Field.faceSelected,
  sub_8064ED4 = Field.clearSelectedMovement,
  LoadPlayerBag = function() Link.loadPlayerBag(); return false end,
  ShowLinkBattleRecords = function() require("src.ui.game3.rs.link_records").show(Link.session()); return false end,
  -- pokeruby/src/cable_club.c:633
  sub_80835D8 = function(ctx)
    if Link.getVar(ctx, Link.VAR_RESULT) == 1 then
      local live = Link.link
      for _, player in ipairs(live and live.players and live:players() or {}) do
        if tonumber(player.language) == 1 then
          Link.setResult(ctx, 7)
          Link.closeLink("rs_record_mixing_japanese_partner")
          break
        end
      end
    end
    return false
  end,
  -- pokeruby/src/cable_club.c:928
  sub_8083B90 = function(ctx, adapters) return Battle.enterColosseumPlayerSpot(ctx, adapters) end,
  -- pokeruby/src/cable_club.c:912
  sub_8083B5C = function(ctx, adapters) return Trade.enterTradeSeat(ctx, adapters) end,
  -- pokeruby/src/cable_club.c:922
  sub_8083B80 = function(ctx, adapters) return Trade.startWiredCableClubTrade(ctx, adapters) end,
  -- pokeruby/src/cable_club.c:743
  sub_8083820 = function()
    local game = Link.game()
    assert(game and type(game.saveGame) == "function", "RS cable save is unavailable")
    assert(game:saveGame() ~= false, "RS cable save failed")
    return false
  end,
  -- pokeruby/src/cable_club.c:808
  sub_80839A4 = function(ctx, adapters) Link.cleanupLinkRoomState(ctx, adapters); return false end,
  sub_80839D0 = function(ctx, adapters) Link.exitLinkRoom(ctx, adapters); return false end,
  sub_80810DC = function(ctx, adapters) Link.returnFromLinkRoom(ctx, adapters); return false end,
  CloseLink = function() Link.closeLink("close_link"); return false end,
  -- pokeruby/src/field_specials.c:302
  GetLinkPartnerNames = function(ctx, adapters)
    local live = Link.link
    local players = live and live.players and live:players() or {}
    local own = live and live.getSeat and live:getSeat() or 0
    local slot = 1
    for _, player in ipairs(players) do
      if tonumber(player.seat) ~= own and not player.isLocal then
        local name = tostring(player.name or "")
        if adapters and adapters.setStringVar then adapters.setStringVar(slot, name) end
        if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[slot] = name end
        slot = slot + 1
      end
    end
    return false, #players
  end,
  -- pokeruby/src/cable_club.c:940
  sub_8083BDC = function(ctx, adapters)
    return Link.showLinkTrainerCard(ctx, adapters)
  end,
}

return M
