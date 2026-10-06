local M = {}
local Util = require("src.core.game3.rse.record_mix_util")
local Rs = require("src.core.game3.link.rs")
local Bases = require("src.core.game3.link.rs_record_bases")
local Tv = require("src.core.game3.link.rs_record_tv")
local Mail = require("src.core.game3.link.rs_record_daycare")
local function num(v) return tonumber(v) or 0 end
local function deep(v) return Util.deep(v) end
local function constant(s, kind, key) return require("src.core.game3.constants").of(s.version):require(kind, key) end
local function storeOf(s)
  local Space, Runtime = package.loaded["src.core.game3.scripting.space"], package.loaded["src.core.game3.runtime"]
  if Space and Space.store and Runtime and Runtime.getSession and Runtime.getSession() == s then return Space.store end
  return s.store or s
end
local function var(s, key, value)
  local store = storeOf(s)
  store.vars = store.vars or {}; store.vars[constant(s, "vars", key)] = value
end
local function flag(s, key)
  local store = storeOf(s)
  store.flags = store.flags or {}; store.flags[constant(s, "flags", key)] = true
end
local function partner(players, mine) return players[Util.shuffle(players)[mine]] end

-- pokeruby/src/mystery_event_script.c:156
local function prepareGift(s, playerId)
  if playerId ~= 0 then return 0 end
  local g = s.recordMixingGift or {}
  local function checksum()
    local sum = num(g.unk0) % 256 + num(g.quantity) % 256 + num(g.itemId) % 256 + math.floor(num(g.itemId) / 256) % 256
    for i = 1, 8 do sum = sum + num((g.filler4 or {})[i]) % 256 end
    return sum
  end
  local function clear()
    local zero = {unk0 = 0, quantity = 0, itemId = 0, checksum = 0, filler4 = {}, nativeBytes = {}}
    for i = 1, 8 do zero.filler4[i] = 0 end
    for i = 1, 16 do zero.nativeBytes[i] = 0 end
    s.recordMixingGift = zero
  end
  if num(g.unk0) == 0 or num(g.quantity) == 0 or num(g.itemId) == 0
      or checksum() == 0 or checksum() ~= num(g.checksum) then
    clear(); return 0
  end
  local item = num(g.itemId)
  g.quantity = g.quantity - 1
  if g.quantity == 0 then clear()
  else g.checksum = checksum() end
  return item
end

-- pokeruby/src/record_mixing.c:622
local function receiveGift(s, leader, mine)
  local item = num(leader.giftItem)
  if mine == 1 or item == 0 then return end
  local Bag, Items = require("src.core.game3.bag"), require("src.core.game3.items_data")
  s.bag = s.bag or Bag.new()
  local canReceive = true
  if Items.pocketOf(item) == "KEY_ITEMS" then
    canReceive = not Bag.has(s.bag, item, 1)
    local storage = require("src.core.game3.storage").ensure(s)
    for _, entry in ipairs(storage.items or {}) do
      if num(entry.id) == item and num(entry.qty) >= 1 then canReceive = false end
    end
  end
  local got = canReceive and Bag.add(s.bag, item, 1)
  var(s, "VAR_TEMP_1", got and item or 0)
  if got and item == constant(s, "items", "ITEM_EON_TICKET") then flag(s, "FLAG_SYS_HAS_EON_TICKET") end
  return {item = got and item or 0, from = leader.name or ""}
end

-- pokeruby/src/battle_tower.c:562
local function receiveTower(s, record)
  local tower = s.battleTower or {}; s.battleTower = tower
  tower.records = tower.records or {}
  local function rawName4(r)
    if type(r.nativeBytes) == "table" and #r.nativeBytes == 164 then return r.nativeBytes[9] end
    if r.name == nil then return 0 end
    local codec = require("src.save_convert.Gen3Save").forVersion(s.version)
    return codec.encodeString(r.name or "", 8):byte(5)
  end
  for i = 1, 5 do
    local old, same = tower.records[i] or {}, true
    for j = 1, 4 do if num((old.trainerId or {})[j]) ~= num((record.trainerId or {})[j]) then same = false; break end end
    if same and rawName4(old) == rawName4(record) then tower.records[i] = deep(record); return i end
  end
  for i = 1, 5 do
    if num((tower.records[i] or {}).winStreak) == 0 then tower.records[i] = deep(record); return i end
  end
  local lowest, slots = num(tower.records[1].winStreak), {1}
  for i = 2, 5 do
    local streak = num(tower.records[i].winStreak)
    if streak < lowest then lowest, slots = streak, {i}
    elseif streak == lowest then slots[#slots + 1] = i end
  end
  local index = slots[require("src.core.game3.rng").Random() % #slots + 1]
  tower.records[index] = deep(record)
  return index
end

-- pokeruby/src/record_mixing.c:52
function M.packet(s, playerId)
  assert(Rs.is(s.version), "RS record mixer requires a native RS session")
  local bases = Bases.prepare(s)
  local shows, news, sum = Tv.prepare(s)
  local codec = require("src.save_convert.Gen3Save").forVersion(s.version)
  local NativeOldMan = require("src.save_convert.gen3_port.sections.rs_old_man")
  local old = NativeOldMan.read(NativeOldMan.render(codec, string.rep("\0", 64),
    require("src.core.game3.rse.old_man").state(s), require("src.save_convert.gen3_port.rse").same), codec)
  local record = (s.battleTower or {}).playerRecord
  if type(record) ~= "table" or next(record) == nil then
    record = codec.port.readTowerRecord(string.rep("\0", 164), codec)
  else
    record = codec.port.readTowerRecord(codec.port.renderTowerRecord(codec, nil, record), codec)
  end
  return {
    version = s.version, name = s.name or s.playerName, trainerId = Rs.trainerId(s) % 65536,
    linkTrainerId = Rs.trainerId(s), language = 2,
    secretBases = bases, tvShows = shows, pokeNews = news, oldMan = old,
    dewfordTrends = require("src.core.game3.rse.dewford_trend").mixExport(s), daycareMail = Mail.prepare(s),
    battleTowerRecord = record,
    giftItem = prepareGift(s, num(playerId)), tvShowByteSum = sum,
  }
end

-- pokeruby/src/record_mixing.c:85
function M.receive(s, packets, mine)
  if not Rs.is(s.version) or #packets < 2 or #packets > 4 or mine < 1 or mine > #packets then
    return {unsupportedReason = "rs_record_mixing_invalid_players"}
  end
  for _, p in ipairs(packets) do
    if not Rs.is(p.version) then return {unsupportedReason = "rs_record_mixing_cross_family_not_implemented"} end
    if type(p.daycareMail) ~= "table" or type(p.battleTowerRecord) ~= "table"
        or type(p.oldMan) ~= "table" or type(p.dewfordTrends) ~= "table" then
      return {unsupportedReason = "rs_record_mixing_invalid_packet"}
    end
  end
  local players, sum = deep(packets), num(packets[1].tvShowByteSum)
  Bases.receive(s, players, mine)
  Tv.receiveShows(s, players, mine)
  Tv.receiveNews(s, players, mine)
  players[mine].oldMan = deep(s.oldMan)
  s.oldMan = deep(partner(players, mine).oldMan)
  require("src.core.game3.rse.old_man").resetFlag(s)
  var(s, "VAR_OBJ_GFX_ID_0", constant(s, "event_objects", "OBJ_EVENT_GFX_BARD") + s.oldMan.id)
  local trends = {}
  for i, p in ipairs(players) do trends[i] = p.dewfordTrends end
  require("src.core.game3.rse.dewford_trend").mixImport(trends, s)
  Mail.receive(s, players, mine, sum)
  local towerSlot = receiveTower(s, partner(players, mine).battleTowerRecord)
  return {secretBases = true, tvShows = true, pokeNews = true, oldMan = true,
    dewfordTrends = true, daycareMail = true, battleTower = true, towerSlot = towerSlot,
    giftItem = true, gift = receiveGift(s, players[1], mine)}
end
M.receiveTower = receiveTower
return M
