local Mail = require("src.core.game3.mail")
local Bag = require("src.core.game3.bag")
local Items = require("src.core.game3.items_data")
local W = {exportEmpty = true}
local function numeric(item) return Items.toNumericId(item) or tonumber(item) or 0 end

function W.newRecord(session, record)
  record.trainerId = (math.floor(tonumber(session.trainerId) or 0) % 65536)
    + (math.floor(tonumber(session.secretId) or 0) % 65536) * 65536
  record._rsNewMail = true
  record.trainerIdRaw = nil
end

function W.give(session, bag, item, index, source)
  local mon = assert(session.party[index])
  item = numeric(item)
  assert(Mail.isMailItem(item), "RS composer requires stationery")
  local previous, previousMail = numeric(mon.item or mon.heldItem), mon.mail
  source = source or require("src.core.game3.item_use").bagGiveSource(bag)
  if source.remove(item) == false then return nil, "missing_item" end
  if previous ~= 0 and not Bag.add(bag, previous, 1) then
    source.restore(item)
    return nil, "bag_full"
  end
  local id = Mail.giveMailToMon(session, mon, item)
  if id == Mail.MAIL_NONE then
    if previous ~= 0 then Bag.remove(bag, previous, 1) end
    source.restore(item)
    mon.item, mon.heldItem, mon.mail = previous, previous, previousMail
    return nil, "mail_slots_full"
  end
  local record = assert(Mail.slot(session, id))
  W.newRecord(session, record)
  return {session = session, bag = bag, mon = mon, item = item, previous = previous,
    mailId = id, record = record, finished = false}
end

function W.cancel(tx)
  if tx.finished then return false end
  if tx.previous ~= 0 then Bag.remove(tx.bag, tx.previous, 1) end
  Bag.add(tx.bag, tx.item, 1)
  Mail.takeMailFromMon(tx.session, tx.mon)
  tx.mon.mail, tx.mon.item, tx.mon.heldItem = Mail.MAIL_NONE, tx.previous, tx.previous
  tx.finished = true
  return true
end
function W.accept(tx, words)
  if tx.finished then return false end
  assert(type(words) == "table", "native mail requires nine words")
  for i = 1, 9 do
    local value = assert(tonumber(words[i]), "native mail word missing")
    assert(value % 1 == 0 and value >= 0 and value <= 65535, "invalid native mail word")
  end
  for i = 1, 9 do tx.record.words[i] = words[i] end
  tx.finished = true
  return true
end
return W
