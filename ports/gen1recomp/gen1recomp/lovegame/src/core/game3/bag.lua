-- game3 bag: pret ItemSlot pockets (AddBagItem / CheckBagHasSpace).
-- Qty ≤ 999. Caps: ITEMS 42, KEY 30, BALLS 13, TMHM 58, BERRIES 43.

local Items = require("src.core.game3.items")
local ItemsData = require("src.core.game3.items_data")

local Bag = {}

local POCKET_KEYS = {
  "ITEMS", "KEY_ITEMS", "POKE_BALLS", "TM_CASE", "BERRY_POUCH",
}

local function empty_pockets()
  local p = {}
  for _, k in ipairs(POCKET_KEYS) do
    p[k] = {}
  end
  return p
end

function Bag.new()
  return {
    pockets = empty_pockets(),
    -- Legacy mirror rebuilt on mutate for old UI / ferry code paths.
    stacks = {},
  }
end

local function slot_id_eq(a, b)
  if a == nil or b == nil then return false end
  local na, nb = ItemsData.toNumericId(a), ItemsData.toNumericId(b)
  if na and nb then return na == nb end
  return ItemsData.bagKey(a) == ItemsData.bagKey(b)
end

local function find_slot(slots, id)
  if not slots then return nil, nil end
  for i, slot in ipairs(slots) do
    if slot_id_eq(slot.id, id) then
      return i, slot
    end
  end
  return nil, nil
end

local function compact(slots)
  local out = {}
  if type(slots) ~= "table" then return out end
  for _, slot in ipairs(slots) do
    if slot.id and (tonumber(slot.qty) or 0) > 0 then
      out[#out + 1] = { id = slot.id, qty = tonumber(slot.qty) or 0 }
    end
  end
  return out
end

local function sort_tm_pocket(slots)
  -- pret SortPocketAndPlaceHMsFirst: HMs first, then TMs, stable-ish by id.
  table.sort(slots, function(a, b)
    local ah, bh = ItemsData.isHm(a.id), ItemsData.isHm(b.id)
    if ah ~= bh then return ah end
    local na = ItemsData.toNumericId(a.id) or 0
    local nb = ItemsData.toNumericId(b.id) or 0
    return na < nb
  end)
end

-- pokeemerald/src/item.c:615
local function sort_by_id(slots)
  for i = 1, #slots - 1 do
    for j = i + 1, #slots do
      local a = ItemsData.toNumericId(slots[i].id) or 0
      local b = ItemsData.toNumericId(slots[j].id) or 0
      if a > b then slots[i], slots[j] = slots[j], slots[i] end
    end
  end
end

local function sort_pocket(pocket, slots)
  local model = ItemsData.BAG_MODEL
  if model.sortHmsFirst[pocket] then
    sort_tm_pocket(slots)
  elseif model.sortById[pocket] then
    sort_by_id(slots)
  end
end

local function grant_key(bag, itemId)
  local keySlots = bag.pockets.KEY_ITEMS
  if not keySlots then return false end
  for _, slot in ipairs(keySlots) do
    if slot_id_eq(slot.id, itemId) then return true end
  end
  local cap = ItemsData.CAPACITY.KEY_ITEMS or 30
  if #keySlots >= cap then return false end
  keySlots[#keySlots + 1] = { id = itemId, qty = 1 }
  return true
end

local function sanitize_pockets(bag)
  if not bag or type(bag.pockets) ~= "table" then return end
  local misplaced = {}
  for _, k in ipairs(POCKET_KEYS) do
    local slots = bag.pockets[k] or {}
    local keep = {}
    for _, slot in ipairs(slots) do
      local correctPocket = ItemsData.pocketOf(slot.id)
      -- pokefirered/src/item.c:92
      if ItemsData.toNumericId(slot.id) ~= 0 then
        if correctPocket ~= k then
          misplaced[#misplaced + 1] = { id = slot.id, qty = tonumber(slot.qty) or 1, target = correctPocket }
        else
          keep[#keep + 1] = slot
        end
      end
    end
    bag.pockets[k] = compact(keep)
  end

  for _, m in ipairs(misplaced) do
    local targetSlots = bag.pockets[m.target] or {}
    local cap = ItemsData.CAPACITY[m.target] or 42
    local _, slot = find_slot(targetSlots, m.id)
    local qty = Items.clampGame3(m.qty)
    if slot then
      slot.qty = Items.clampGame3((tonumber(slot.qty) or 0) + qty)
    elseif qty > 0 and #targetSlots < cap then
      targetSlots[#targetSlots + 1] = { id = m.id, qty = qty }
    end
    bag.pockets[m.target] = compact(targetSlots)
  end

  if bag.pockets.TM_CASE and #bag.pockets.TM_CASE > 0 then
    sort_pocket("TM_CASE", bag.pockets.TM_CASE)
    local c = ItemsData.CONTAINERS.TM_CASE
    if c then grant_key(bag, c.item) end
  end
  if bag.pockets.BERRY_POUCH and #bag.pockets.BERRY_POUCH > 0 then
    sort_pocket("BERRY_POUCH", bag.pockets.BERRY_POUCH)
    local c = ItemsData.CONTAINERS.BERRY_POUCH
    if c then grant_key(bag, c.item) end
  end
end

local function capped(pocket)
  return ItemsData.slotMax(pocket) < Items.GAME3_MAX_QTY
    or ItemsData.BAG_MODEL.splitSlots[pocket] == true
end

local function pocket_total(slots, id)
  local n = 0
  for _, slot in ipairs(slots or {}) do
    if slot_id_eq(slot.id, id) then n = n + (tonumber(slot.qty) or 0) end
  end
  return n
end

-- pokeemerald/src/item.c:174
local function capped_can_add(slots, pocket, id, count)
  local slotCap = ItemsData.slotMax(pocket)
  local split = ItemsData.BAG_MODEL.splitSlots[pocket] == true
  for _, slot in ipairs(slots) do
    if slot_id_eq(slot.id, id) then
      local owned = tonumber(slot.qty) or 0
      if owned + count <= slotCap then return true end
      if not split then return false end
      count = count - (slotCap - owned)
      if count == 0 then break end
    end
  end
  if count > 0 then
    local empty = (ItemsData.CAPACITY[pocket] or 0) - #slots
    for _ = 1, empty do
      if count > slotCap then
        if not split then return false end
        count = count - slotCap
      else
        count = 0
        break
      end
    end
    if count > 0 then return false end
  end
  return true
end

-- pokeemerald/src/item.c:238
local function capped_add(bag, pocket, id, count)
  local slotCap = ItemsData.slotMax(pocket)
  local split = ItemsData.BAG_MODEL.splitSlots[pocket] == true
  local cap = ItemsData.CAPACITY[pocket] or 0
  local slots = {}
  for i, slot in ipairs(bag.pockets[pocket] or {}) do
    slots[i] = { id = slot.id, qty = tonumber(slot.qty) or 0 }
  end
  local left = count
  for _, slot in ipairs(slots) do
    if slot_id_eq(slot.id, id) then
      if slot.qty + left <= slotCap then
        slot.qty = slot.qty + left
        left = 0
        break
      end
      if not split then return false, 0 end
      left = left - (slotCap - slot.qty)
      slot.qty = slotCap
      if left == 0 then break end
    end
  end
  while left > 0 do
    if #slots >= cap then return false, 0 end
    if left > slotCap then
      if not split then return false, 0 end
      slots[#slots + 1] = { id = id, qty = slotCap }
      left = left - slotCap
    else
      slots[#slots + 1] = { id = id, qty = left }
      left = 0
    end
  end
  sort_pocket(pocket, slots)
  bag.pockets[pocket] = slots
  return true, count
end

-- pokeemerald/src/item.c:345
local function capped_remove(bag, pocket, id, count)
  local slots = bag.pockets[pocket] or {}
  if pocket_total(slots, id) < count then return false end
  for _, slot in ipairs(slots) do
    if count == 0 then break end
    if slot_id_eq(slot.id, id) then
      local owned = tonumber(slot.qty) or 0
      if owned >= count then
        slot.qty = owned - count
        count = 0
      else
        count = count - owned
        slot.qty = 0
      end
    end
  end
  bag.pockets[pocket] = compact(slots)
  return true
end

local function rebuild_stacks(bag)
  bag.stacks = {}
  for _, k in ipairs(POCKET_KEYS) do
    for _, slot in ipairs(bag.pockets[k] or {}) do
      local id = slot.id
      local qty = tonumber(slot.qty) or 0
      if id and qty > 0 then
        local key = ItemsData.bagKey(id)
        bag.stacks[key] = (bag.stacks[key] or 0) + qty
        -- Also mirror host string if known
        local num = ItemsData.toNumericId(id)
        if num and Items.FRLG_TO_HOST[num] then
          bag.stacks[Items.FRLG_TO_HOST[num]] = bag.stacks[key]
        end
      end
    end
  end
end

local function ensure(bag)
  if not bag then return nil end
  if type(bag.pockets) ~= "table" then
    Bag.migrate(bag)
  end
  for _, k in ipairs(POCKET_KEYS) do
    bag.pockets[k] = bag.pockets[k] or {}
  end
  sanitize_pockets(bag)
  bag.stacks = bag.stacks or {}
  return bag
end

--- Migrate legacy { stacks } or schema { items=… } into pockets.
function Bag.migrate(bag)
  if not bag then return Bag.new() end
  if type(bag.pockets) == "table" and bag.pockets.ITEMS then
    ensure(bag)
    rebuild_stacks(bag)
    return bag
  end

  local fresh = Bag.new()
  local function absorb(id, qty)
    qty = tonumber(qty) or 0
    if qty > 0 and id ~= nil then
      Bag.add(fresh, id, qty)
    end
  end

  if type(bag.stacks) == "table" then
    for id, qty in pairs(bag.stacks) do
      absorb(id, qty)
    end
  end

  -- Schema newGame shape
  local map = {
    items = "ITEMS",
    keyItems = "KEY_ITEMS",
    pokeballs = "POKE_BALLS",
    berries = "BERRY_POUCH",
    tmsHms = "TM_CASE",
  }
  for field, _ in pairs(map) do
    local list = bag[field]
    if type(list) == "table" then
      for _, entry in ipairs(list) do
        if type(entry) == "table" then
          absorb(entry.id or entry.itemId or entry[1], entry.qty or entry.quantity or entry[2] or 1)
        elseif entry then
          absorb(entry, 1)
        end
      end
      -- also allow map form
      for id, qty in pairs(list) do
        if type(id) ~= "number" or type(qty) ~= "table" then
          if type(qty) == "number" then absorb(id, qty) end
        end
      end
    end
  end

  bag.pockets = fresh.pockets
  bag.stacks = fresh.stacks
  -- Drop legacy pocket table fields from schema shape if present
  return bag
end

function Bag.clear(bag)
  bag = ensure(bag)
  bag.pockets = empty_pockets()
  bag.stacks = {}
end

-- pokeemerald/src/item.c:136
local function pyramidBag(bag)
  local Py = package.loaded["src.core.game3.rse.frontier.pyramid"]
  if not (Py and bag) then return nil end
  local Rt = package.loaded["src.core.game3.runtime"]
  local s = Rt and Rt.getSession and Rt.getSession()
  if s and s.bag == bag and Py.bagActive(s) then return Py, s end
  return nil
end

function Bag.get(bag, id)
  local Py, ps = pyramidBag(bag)
  if Py then return Py.bagCount(ps, id) end
  bag = ensure(bag)
  if not bag or id == nil then return 0 end
  local pocket = ItemsData.pocketOf(id)
  local slots = bag.pockets[pocket] or {}
  if capped(pocket) then
    local total = pocket_total(slots, id)
    if total > 0 then return total end
  end
  local _, slot = find_slot(slots, id)
  if slot then return tonumber(slot.qty) or 0 end
  -- stacks fallback
  return bag.stacks[ItemsData.bagKey(id)]
    or bag.stacks[tostring(id)]
    or 0
end

function Bag.has(bag, id, qty)
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  return Bag.get(bag, id) >= qty
end

function Bag.canAdd(bag, id, qty)
  local Py, ps = pyramidBag(bag)
  if Py then return Py.bagHasSpace(ps, id, qty or 1) end
  bag = ensure(bag)
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  -- pokefirered/src/item.c:92
  if not id or ItemsData.toNumericId(id) == 0 then return false end
  local pocket = ItemsData.pocketOf(id)
  local cap = ItemsData.CAPACITY[pocket] or 42
  local slots = bag.pockets[pocket] or {}
  if capped(pocket) then return capped_can_add(slots, pocket, id, qty) end
  local _, slot = find_slot(slots, id)
  if slot then
    local have = tonumber(slot.qty) or 0
    return (have + qty) <= Items.GAME3_MAX_QTY
  end
  -- Need empty slot; TM Case / Berry Pouch auto-grant may need KEY slot too
  if #slots >= cap then return false end
  local c = ItemsData.CONTAINERS[pocket]
  if c and not Bag.has(bag, c.item, 1) then
    local keySlots = bag.pockets.KEY_ITEMS or {}
    if #keySlots >= (ItemsData.CAPACITY.KEY_ITEMS or 30) and not find_slot(keySlots, c.item) then
      return false
    end
  end
  return true
end


local FLAG_SYS_GOT_BERRY_POUCH = 0x847 -- include/constants/flags.h:1405

local function mark_container(flagName)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local store = type(Space) == "table" and Space.store
  if store then
    local game = require("src.core.game3.profile").active().id
    local id = require("src.core.game3.constants").of(game):require("flags", flagName)
    require("src.core.game3.scripting.flags").setFlag(store, nil, id, true)
  end
end

Bag.FLAG_SYS_GOT_BERRY_POUCH = FLAG_SYS_GOT_BERRY_POUCH

function Bag.add(bag, id, qty)
  local Py, ps = pyramidBag(bag)
  if Py then
    local ok = Py.bagAdd(ps, id, qty or 1)
    return ok, ok and (qty or 1) or 0
  end
  bag = ensure(bag)
  qty = math.max(0, math.floor(tonumber(qty) or 1))
  if qty <= 0 or not id or ItemsData.toNumericId(id) == 0 then return false, 0 end

  -- Prefer numeric FRLG id in slots
  local num = ItemsData.toNumericId(id)
  local storeId = num or id

  if not Bag.canAdd(bag, storeId, qty) then
    return false, 0
  end

  local pocket = ItemsData.pocketOf(storeId)

  local container = ItemsData.CONTAINERS[pocket]
  if container and not Bag.has(bag, container.item, 1) then
    if not grant_key(bag, container.item) then
      return false, 0
    end
  end
  -- src/item.c:242
  for cPocket, c in pairs(ItemsData.CONTAINERS) do
    if c.flag and (pocket == cPocket or num == c.item or storeId == c.item) then
      mark_container(c.flag)
    end
  end

  if capped(pocket) then
    local ok, placed = capped_add(bag, pocket, storeId, qty)
    if ok then rebuild_stacks(bag) end
    return ok, placed
  end

  local slots = bag.pockets[pocket]
  local idx, slot = find_slot(slots, storeId)
  if slot then
    local have = tonumber(slot.qty) or 0
    local nextQty = Items.clampGame3(have + qty)
    local placed = nextQty - have
    slot.qty = nextQty
    rebuild_stacks(bag)
    return placed == qty, placed
  end

  local placed = Items.clampGame3(qty)
  slots[#slots + 1] = { id = storeId, qty = placed }
  sort_pocket(pocket, slots)
  rebuild_stacks(bag)
  return placed == qty, placed
end

-- pokeruby/src/item_menu.c:895
function Bag.removeSlot(bag, pocket, index, qty)
  bag = ensure(bag)
  local slots = bag and bag.pockets and bag.pockets[pocket]
  index = math.floor(tonumber(index) or 0)
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  local slot = slots and slots[index]
  if not slot or (tonumber(slot.qty) or 0) < qty then return false end
  slot.qty = slot.qty - qty
  if slot.qty == 0 then table.remove(slots, index) end
  bag.pockets[pocket] = compact(slots)
  sort_pocket(pocket, bag.pockets[pocket])
  rebuild_stacks(bag)
  return true
end

function Bag.remove(bag, id, qty)
  local Py, ps = pyramidBag(bag)
  if Py then return Py.bagRemove(ps, id, qty or 1) end
  bag = ensure(bag)
  qty = math.max(1, math.floor(tonumber(qty) or 1))
  if not id then return false end
  local num = ItemsData.toNumericId(id)
  local storeId = num or id
  local pocket = ItemsData.pocketOf(storeId)
  if capped(pocket) then
    local ok = capped_remove(bag, pocket, storeId, qty)
    if ok then rebuild_stacks(bag) end
    return ok
  end
  local slots = bag.pockets[pocket]
  local idx, slot = find_slot(slots, storeId)
  if not slot then return false end
  local have = tonumber(slot.qty) or 0
  if have < qty then return false end
  slot.qty = have - qty
  if slot.qty <= 0 then
    table.remove(slots, idx)
  end
  bag.pockets[pocket] = compact(slots)
  sort_pocket(pocket, bag.pockets[pocket])
  rebuild_stacks(bag)
  return true
end


function Bag.set(bag, id, qty)
  qty = Items.clampGame3(qty)
  local have = Bag.get(bag, id)
  if qty <= 0 then
    if have > 0 then Bag.remove(bag, id, have) end
    return 0
  end
  if have > qty then
    Bag.remove(bag, id, have - qty)
  elseif have < qty then
    Bag.add(bag, id, qty - have)
  end
  return Bag.get(bag, id)
end

-- listPocket rows per bag and pocket, rebuilt only when the pocket's
-- (id, qty) slots or the loaded item pack change.  Bag menus call listPocket
-- every frame; each row costs three ItemsData.info lookups.
local rowCache = setmetatable({}, { __mode = "k" })

local function rows_match(entry, slots, byId)
  if entry.byId ~= byId then return false end
  local ids, qtys, n = entry.ids, entry.qtys, entry.n
  for i = 1, n do
    local slot = slots[i]
    if slot == nil or slot.id ~= ids[i] or slot.qty ~= qtys[i] then return false end
  end
  return slots[n + 1] == nil
end

--- Ordered list of { id, qty, name, info } for a pocket (bag UI).
-- The returned rows are shared between calls until the pocket changes, so
-- callers must not modify them.
function Bag.listPocket(bag, pocket)
  bag = ensure(bag)
  pocket = pocket or "ITEMS"
  local slots = bag.pockets[pocket] or {}
  local byId = ItemsData._byId
  local perBag = rowCache[bag]
  local entry = perBag and perBag[pocket]
  if entry and byId and rows_match(entry, slots, byId) then return entry.rows end
  local rows = {}
  for _, slot in ipairs(slots) do
    local qty = tonumber(slot.qty) or 0
    if slot.id and qty > 0 then
      rows[#rows + 1] = {
        id = slot.id,
        qty = qty,
        name = ItemsData.displayName(slot.id),
        info = ItemsData.info(slot.id),
        description = ItemsData.description(slot.id),
      }
    end
  end
  byId = ItemsData._byId
  if byId then
    local n = 0
    local ids, qtys = {}, {}
    for i, slot in ipairs(slots) do
      n = i
      ids[i], qtys[i] = slot.id, slot.qty
    end
    if not perBag then
      perBag = {}
      rowCache[bag] = perBag
    end
    perBag[pocket] = { byId = byId, n = n, ids = ids, qtys = qtys, rows = rows }
  end
  return rows
end

function Bag.mergeFromHost(bag, hostInventory)
  bag = ensure(bag)
  if type(hostInventory) ~= "table" then return end
  for id, qty in pairs(hostInventory) do
    if type(id) == "string" and not id:find("BADGE", 1, true) then
      local n = tonumber(qty) or 0
      if n > 0 then
        local num = ItemsData.toNumericId(id)
        if num or Items.isHostSafe(id) then
          Bag.add(bag, num or id, n)
        end
      end
    end
  end
end

function Bag.restoreSidecar(bag, sidecar)
  bag = ensure(bag)
  if type(sidecar) ~= "table" then return end
  local function absorb(tbl)
    if type(tbl) ~= "table" then return end
    for id, qty in pairs(tbl) do
      local n = tonumber(qty) or 0
      if n > 0 then Bag.add(bag, id, n) end
    end
  end
  absorb(sidecar.quarantine)
  absorb(sidecar.overflow)
  absorb(sidecar.bag)
  if type(sidecar.stacks) == "table" then absorb(sidecar.stacks) end
end

function Bag.splitForHost(bag, hostInventory)
  hostInventory = hostInventory or {}
  local hostWrites, quarantine, overflow = {}, {}, {}
  bag = ensure(bag)
  if not bag then return hostWrites, quarantine, overflow end
  -- Iterate pockets once (avoid double-count from stacks numeric+host mirrors).
  for _, pocket in ipairs(POCKET_KEYS) do
    for _, slot in ipairs(bag.pockets[pocket] or {}) do
      local qty = Items.clampGame3(slot.qty)
      if slot.id and qty > 0 then
        local num = ItemsData.toNumericId(slot.id)
        local hostId = (num and Items.FRLG_TO_HOST[num])
          or (type(slot.id) == "string" and not tonumber(slot.id) and slot.id)
          or nil
        if not hostId then
          local qkey = num and ("FRLG_" .. tostring(num)) or tostring(slot.id)
          quarantine[qkey] = (quarantine[qkey] or 0) + qty
        elseif not Items.isHostSafe(hostId) then
          quarantine[hostId] = (quarantine[hostId] or 0) + qty
        else
          local room = Items.HOST_MAX_QTY
          local placed = math.min(qty, room)
          if placed > 0 then
            hostWrites[hostId] = (hostWrites[hostId] or 0) + placed
          end
          local rem = qty - placed
          if rem > 0 then
            overflow[hostId] = (overflow[hostId] or 0) + rem
          end
        end
      end
    end
  end
  return hostWrites, quarantine, overflow
end

Bag.MAX_COINS = 9999 -- pokefirered/include/constants/coins.h:4

local Coins = {}
Bag.Coins = Coins

Coins.MAX_COINS = Bag.MAX_COINS

-- pokefirered/src/coins.c:11
function Coins.get(session)
  if type(session) ~= "table" then return 0 end
  local n = math.floor(tonumber(session.coins) or 0)
  if n < 0 then return 0 end
  if n > Bag.MAX_COINS then return Bag.MAX_COINS end
  return n
end

-- pokefirered/src/coins.c:16
function Coins.set(session, amount)
  if type(session) ~= "table" then return 0 end
  local n = math.floor(tonumber(amount) or 0)
  if n < 0 then n = 0 end
  if n > Bag.MAX_COINS then n = Bag.MAX_COINS end
  session.coins = n
  return n
end

-- pokefirered/src/coins.c:21
function Coins.add(session, toAdd)
  if type(session) ~= "table" then return false end
  local coins = Coins.get(session)
  if coins >= Bag.MAX_COINS then return false end
  toAdd = math.floor(tonumber(toAdd) or 0)
  if toAdd < 0 then toAdd = 0 end
  local sum = (coins + toAdd) % 65536
  if sum >= coins then
    coins = (sum > Bag.MAX_COINS) and Bag.MAX_COINS or sum
  else
    coins = Bag.MAX_COINS
  end
  Coins.set(session, coins)
  return true
end

-- pokefirered/src/coins.c:41
function Coins.remove(session, toSub)
  if type(session) ~= "table" then return false end
  local coins = Coins.get(session)
  toSub = math.floor(tonumber(toSub) or 0)
  if toSub < 0 then toSub = 0 end
  if coins >= toSub then
    Coins.set(session, coins - toSub)
    return true
  end
  return false
end

function Bag.applyHostWrites(save, hostWrites)
  if not save then return end
  save.inventory = save.inventory or {}
  local BagHost = require("src.inventory.Bag")
  for id, qty in pairs(hostWrites) do
    qty = math.min(Items.HOST_MAX_QTY, math.floor(tonumber(qty) or 0))
    if qty <= 0 then
      if BagHost.remove then
        local have = save.inventory[id] or 0
        if have > 0 then BagHost.remove(save, id, have) end
      else
        save.inventory[id] = nil
      end
    else
      save.inventory[id] = qty
      if BagHost.order then
        local order = BagHost.order(save)
        local found = false
        for _, oid in ipairs(order) do
          if oid == id then found = true break end
        end
        if not found then table.insert(order, id) end
      end
    end
  end
end

return Bag
