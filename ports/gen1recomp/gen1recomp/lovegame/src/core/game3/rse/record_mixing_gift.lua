local Rse = require("src.core.game3.rse.init")

local Gift = {}

local function sessionOf(sess)
  return sess or Rse.session()
end

local function blank()
  return { unk0 = 0, quantity = 0, itemId = 0, checksum = 0 }
end

function Gift.state(sess)
  sess = sessionOf(sess)
  if type(sess.recordMixingGift) ~= "table" then sess.recordMixingGift = blank() end
  return sess.recordMixingGift
end

-- pokeemerald/src/mystery_event_script.c:103
function Gift.checksum(g)
  local item = tonumber(g.itemId) or 0
  return (tonumber(g.unk0) or 0) % 256 + (tonumber(g.quantity) or 0) % 256 + item % 256 + math.floor(item / 256) % 256
end

-- pokeemerald/src/mystery_event_script.c:115
local function isValid(g)
  local sum = Gift.checksum(g)
  return (tonumber(g.unk0) or 0) ~= 0 and (tonumber(g.quantity) or 0) ~= 0 and (tonumber(g.itemId) or 0) ~= 0
    and sum ~= 0 and sum == (tonumber(g.checksum) or 0)
end

-- pokeemerald/src/mystery_event_script.c:130
function Gift.clear(sess)
  sess = sessionOf(sess)
  sess.recordMixingGift = blank()
end

-- pokeemerald/src/mystery_event_script.c:135
function Gift.set(unk, quantity, itemId, sess)
  sess = sessionOf(sess)
  if (tonumber(unk) or 0) == 0 or (tonumber(quantity) or 0) == 0 or (tonumber(itemId) or 0) == 0 then
    Gift.clear(sess)
    return
  end
  local g = Gift.state(sess)
  g.unk0, g.quantity, g.itemId = tonumber(unk), tonumber(quantity), tonumber(itemId)
  g.checksum = Gift.checksum(g)
end

-- pokeemerald/src/mystery_event_script.c:150
function Gift.take(sess)
  sess = sessionOf(sess)
  local g = Gift.state(sess)
  if not isValid(g) then
    Gift.clear(sess)
    return 0
  end
  local itemId = tonumber(g.itemId) or 0
  g.quantity = g.quantity - 1
  if g.quantity == 0 then Gift.clear(sess) else g.checksum = Gift.checksum(g) end
  return itemId
end

-- pokeemerald/src/record_mixing.c:246
function Gift.mixExport(sess, multiplayerId)
  if (tonumber(multiplayerId) or 0) ~= 0 then return 0 end
  return Gift.take(sess)
end

local function constant(sess, kind, name)
  local Constants = require("src.core.game3.constants")
  local ok, v = pcall(function() return Constants.of(Constants.versionOf(sess)):require(kind, name) end)
  return ok and v or nil
end

local function pcHas(sess, item)
  local okS, Storage = pcall(require, "src.core.game3.storage")
  local storage = okS and Storage.ensure(sess) or nil
  for _, entry in ipairs(storage and storage.items or {}) do
    if (tostring(entry.id) == tostring(item) or tonumber(entry.id) == item) and (tonumber(entry.qty) or 0) >= 1 then
      return true
    end
  end
  return false
end

-- pokeemerald/src/record_mixing.c:969
function Gift.mixImport(players, sess, myIndex)
  sess = sessionOf(sess)
  players = players or {}
  local multiplayerId = (tonumber(myIndex) or 1) - 1
  local p0 = players[1] or {}
  local item = tonumber(p0.giftItem) or 0
  local ItemsData = require("src.core.game3.items_data")
  if multiplayerId == 0 or item == 0 or ItemsData.pocketOf(item) ~= "KEY_ITEMS" then return nil end
  local Bag = require("src.core.game3.bag")
  sess.bag = sess.bag or Bag.new()
  local got = not Bag.has(sess.bag, item, 1) and not pcHas(sess, item) and Bag.add(sess.bag, item, 1)
  if got then
    pcall(Rse.setVar, "VAR_TEMP_RECORD_MIX_GIFT_ITEM", item, sess)
    if item == constant(sess, "items", "ITEM_EON_TICKET") then
      pcall(Rse.setFlag, "FLAG_ENABLE_SHIP_SOUTHERN_ISLAND", true, sess)
    end
    return { item = item, from = p0.name or "" }
  end
  pcall(Rse.setVar, "VAR_TEMP_RECORD_MIX_GIFT_ITEM", 0, sess)
  return { item = 0 }
end

local SaveSections = require("src.core.game3.save_sections")
-- pokeemerald/include/global.h:1070
SaveSections.register("recordMixingGift", SaveSections.fields({ "recordMixingGift" }, function(sess) Gift.clear(sess) end))

Rse.register("recordMixingGift", Gift)

return Gift
