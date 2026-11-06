local Rs = {}

function Rs.is(version)
  return version == "ruby" or version == "sapphire"
end

-- pokeruby/src/cable_club.c:558
Rs.wires = {
  battle_single = "BATTLE_SINGLE", battle_double = "BATTLE_DOUBLE", battle_multi = "BATTLE_MULTI",
  trade = "TRADE", record_corner = "RECORD_CORNER", berry_blender = "BERRY_BLENDER",
  contest_cool = "CONTEST_COOL", contest_beauty = "CONTEST_BEAUTY", contest_cute = "CONTEST_CUTE",
  contest_smart = "CONTEST_SMART", contest_tough = "CONTEST_TOUGH",
  mystery_event = "MYSTERY_EVENT",
}
Rs.groups = { [0] = true, [1] = true, [2] = true, [3] = true, [12] = true, [13] = true,
  [15] = true, [16] = true, [17] = true, [18] = true, [19] = true }
Rs.maps = { colosseum2P = "SINGLE_BATTLE_COLOSSEUM", colosseum4P = "DOUBLE_BATTLE_COLOSSEUM",
  tradeCenter = "TRADE_CENTER", recordCorner = "RECORD_CORNER" }
-- pokeruby/src/overworld.c:2726
Rs.playerGfx = { "OBJ_EVENT_GFX_RIVAL_BRENDAN_NORMAL", "OBJ_EVENT_GFX_RIVAL_MAY_NORMAL" }
Rs.songs = { leader = "MUS_VS_GYM_LEADER", trainer = "MUS_VS_TRAINER" }

-- pokeruby/src/trade.c:1996
function Rs.groupRange(group)
  group = tonumber(group)
  if group == 2 or (group and group >= 15 and group <= 19) then return 4, 4 end
  if group == 12 or group == 13 then return 2, 4 end
  return 2, 2
end

function Rs.canTrade(party, monIdx, count)
  local selected = (tonumber(monIdx) or 0) + 1
  for i = 1, tonumber(count) or #party do
    local mon = party[i]
    if i ~= selected and type(mon) == "table" and not (mon.isEgg or mon.egg)
        and (tonumber(mon.hp) or 0) > 0 then return 0 end
  end
  return 1
end

-- pokeruby/src/link.c:280
function Rs.trainerId(session)
  session = type(session) == "table" and session or {}
  local id = math.floor(tonumber(session.trainerId or session.id or session.playerId) or 0)
  if id >= 65536 then return id % 4294967296 end
  return id % 65536 + (math.floor(tonumber(session.secretId) or 0) % 65536) * 65536
end

function Rs.trainerCard(session, version)
  return require("src.ui.game3.rs.trainer_card_policy").generate(session, version)
end

-- pokeruby/src/trade.c:1615
function Rs.giftRibbonBlock(session)
  local out, ribbons = {}, session and session.giftRibbons or {}
  for i = 1, 11 do out[i] = math.floor(tonumber(ribbons[i]) or 0) % 256 end
  return out
end
function Rs.mergeGiftRibbons(session, received)
  if type(session) ~= "table" or type(received) ~= "table" then return end
  local localRibbons = session.giftRibbons
  if type(localRibbons) ~= "table" then localRibbons = {}; session.giftRibbons = localRibbons end
  for i = 1, 11 do
    local own = math.floor(tonumber(localRibbons[i]) or 0) % 256
    local peer = math.floor(tonumber(received[i]) or 0) % 256
    if own == 0 and peer ~= 0 then localRibbons[i] = peer end
  end
end
return Rs
