local Link = require("src.core.game3.link.init")
local M = {}
local function C() return require("src.core.game3.constants").active(Link.session()) end
local function text(ctx, adapters, i, value)
  ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[i] = value
  if adapters and adapters.setStringVar then adapters.setStringVar(i, value) end
end
local function nativeName(row)
  if row and type(row.nativeBytes) == "table" and #row.nativeBytes >= 11 then
    local bytes = {}; for i = 5, 11 do bytes[#bytes + 1] = row.nativeBytes[i] end; bytes[#bytes + 1] = 255
    local IR = require("src.core.game3.scripting.text_ir")
    return IR.toAscii(IR.decode(bytes, {dialect = "rs"}))
  end
  return row and row.name or ""
end
-- contest_util.c:467
function M.enigmaInParty(ctx, adapters)
  local P = require("src.core.game3.pokemon")
  local I = require("src.core.game3.items_data")
  for i = 1, 6 do
    local mon = (Link.session().party or {})[i]
    if mon and (P.speciesOf(mon) or 0) ~= 0 and not P.isEgg(mon)
        and I.toNumericId(mon.heldItem or mon.item) == 175 then
      local enigma = require("src.ui.game3.rs.berry_tag_data").enigma(Link.session())
      text(ctx, adapters, 1, enigma and enigma.name or require("src.core.game3.rse.berry_trees").info(43).name)
      Link.setResult(ctx, 1); return false, 1
    end
  end
  Link.setResult(ctx, 0); return false, 0
end
-- field_specials.c:319
function M.spawnBlenderPlayers(ctx)
  local V = require("src.core.game3.virtual_objects")
  for seat = 0, 3 do V.remove(0xF0 - seat) end
  local lk, P = Link.link, require("src.core.game3.player")
  local own = lk and lk.getSeat and lk:getSeat() or 0
  local facing = ({right = {0, 1, 0}, up = {1, 0, -1}, left = {2, -1, 0}, down = {3, 0, 1}})[P.facing or "down"]
  local j, x, y = facing[1], (P.cellX or 0) + facing[2], (P.cellY or 0) + facing[3]
  local offsets, directions = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}, {2, 3, 1, 4}
  local players = lk and lk.players and lk:players() or {}
  local count = Link.getVar(ctx, 0x8004)
  for i, player in ipairs(players) do
    local seat = tonumber(player.seat) or i - 1
    if i <= count and seat ~= own then
      local gfx = C():require("event_objects", tonumber(player.gender) == 1 and "OBJ_EVENT_GFX_RIVAL_MAY_NORMAL" or "OBJ_EVENT_GFX_RIVAL_BRENDAN_NORMAL")
      V.spawn(0xF0 - seat, gfx, x + offsets[j + 1][1], y + offsets[j + 1][2], 0, directions[j + 1]); j = (j + 1) % 4
    end
  end
  return false
end
-- field_specials.c:1625
function M.eReaderName(ctx, adapters)
  local row = (Link.session().battleTower or {}).ereaderTrainer
  text(ctx, adapters, 1, nativeName(row)); return false
end
function M.eReaderGfx()
  local T = require("src.core.game3.rse.battle_tower_rs")
  local row = (Link.session().battleTower or {}).ereaderTrainer or {}
  local info = T.pack().classInfo[tonumber(row.trainerClass) or 0]
  require("src.core.game3.rse.init").setVar("VAR_OBJ_GFX_ID_0", info and info.objGfx or C():require("event_objects", "OBJ_EVENT_GFX_BOY_1"), Link.session())
  return false
end
-- choose_party.c:57
function M.chooseBattleParty(ctx, adapters)
  local s, PartyMenu = Link.session(), require("src.ui.game3.party_menu")
  local P = require("src.core.game3.pokemon")
  s.selectedOrderFromParty = {0, 0, 0}
  if adapters and adapters.closeMessage then adapters.closeMessage() end
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    PartyMenu.show(s.party, nil, {mode = "choose_multi", count = 3, session = s, immediateChooseCancel = true,
      eligible = function(_, mon) return mon and not P.isEgg(mon) and (tonumber(mon.hp) or 0) > 0 end,
      onSelect = function(order)
        PartyMenu._linkRoomChoose = nil
        for i = 1, 3 do s.selectedOrderFromParty[i] = order and order[i] or 0 end
        require("src.core.game3.rse.battle_tower_rs").selectOrder(s, s.selectedOrderFromParty)
        Link.setResult(ctx, s.selectedOrderFromParty[1] == 0 and 0 or 1); done()
      end})
    PartyMenu._linkRoomChoose = true
  end)
end
function M.multiplayerId(ctx)
  local NC = require("src.core.game3.scripting.natives_contest")
  local lk = Link.link
  local id = NC.linkFlags % 2 == 1 and (lk and lk.getSeat and lk:getSeat() or 0) or 4
  Link.setResult(ctx, id); return false, id
end
function M.faceSelected(ctx)
  local eo = require("src.core.game3.objects").find(Link.getVar(ctx, 0x800F))
  if eo then eo.facing = ({[1] = "up", [2] = "down", [3] = "right", [4] = "left"})[Link.getVar(ctx, 0x800C)] or eo.facing end
  return false
end
function M.clearSelectedMovement(ctx)
  local O, id = require("src.core.game3.objects"), Link.getVar(ctx, 0x800F)
  O._tracks[id] = nil
  local eo = O.find(id); if eo then eo.scriptBusy = false end
  return false
end
return M
