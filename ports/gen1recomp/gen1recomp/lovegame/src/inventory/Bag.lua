-- Gen 2 keeps FOUR pockets, not Gen 1's single bag (item_data_constants.asm):
-- Items 20, Balls 12, Key Items 25, TM/HM 57.  A distinct item id occupies one
-- slot of ITS OWN pocket regardless of quantity, and a pocket fills
-- independently -- which is exactly why the cart can hold every TM, every key
-- item AND still pick up an HM.  Modelling all four as one 20-slot list filled
-- the bag with TMs and key items by the Ice Path and refused HM07 WATERFALL.
-- Badges live in the inventory table but are not bag items.  save.bagOrder
-- keeps acquisition order like wBagItems (SELECT can reorder it).

local Bag = {}

-- MAX_ITEMS / MAX_BALLS / MAX_KEY_ITEMS, and the TM/HM pocket holds one of
-- every TM plus the seven HMs (NUM_TMS + NUM_HMS -- ram/wram.asm:2421 is
-- `wTMsHMs:: ds NUM_TMS + NUM_HMS`, 57 bytes).  A `mods` bagSize override
-- replaces the ITEM pocket only, the way the Gen 1 single-bag config did.
local POCKET_CAPACITY = {
  ITEM = 20,
  BALL = 12,
  KEY_ITEM = 25,
  TM_HM = 57,
}
local DEFAULT_CAPACITY = 20

local function isBadge(id)
  if type(id) ~= "string" then return false end
  return id:find("BADGE", 1, true) ~= nil
end

-- Which pocket an id belongs to.  Unknown ids (a stale cache, a mod that did
-- not declare a pocket) fall to ITEM, the Gen 1 behaviour.
local function pocketOf(id, data)
  data = data or require("src.core.Data")
  local def = data and data.items and data.items[id]
  return (def and def.pocket) or "ITEM"
end
Bag.pocketOf = pocketOf

-- `data` is injectable for the save editor and headless mod tests.  Normal
-- gameplay may omit it because the loader merges mods into the Data
-- singleton before any item can be added.  A pocket argument gives that
-- pocket's cap; omitting it keeps the old single-number ITEM answer so
-- existing callers (and the mod bagSize override) are unchanged.
function Bag.capacity(data, pocket)
  data = data or require("src.core.Data")
  if pocket and pocket ~= "ITEM" then
    return POCKET_CAPACITY[pocket] or DEFAULT_CAPACITY
  end
  local configured = data and data.constants and data.constants.bagSize
  if type(configured) == "number" and configured >= 1 then
    return math.floor(configured)
  end
  return POCKET_CAPACITY.ITEM
end

-- exported so item lists that share save.inventory (e.g. the PC deposit
-- menu) can exclude badges the same way the bag does
Bag.isBadge = isBadge

local MAX_STACK = 99

local function splits(id, data)
  if require("src.core.GameVersion").generation() ~= 1 then return false end
  data = data or require("src.core.Data")
  local def = data and data.items and data.items[id]
  return not (def and def.pocket)
end

local function stackList(stacks, id, total)
  local list = stacks and stacks[id]
  if type(list) ~= "table" or #list == 0 or type(total) ~= "number" then return nil end
  local sum = 0
  for i = 1, #list do
    local c = list[i]
    if type(c) ~= "number" or c < 1 or c > MAX_STACK or c % 1 ~= 0 then return nil end
    sum = sum + c
  end
  if sum ~= total then return nil end
  return list
end

-- engine/items/inventory.asm:59
local function slotsFor(id, n, data, stacks)
  if not n or isBadge(id) then return 0 end
  if type(n) ~= "number" then return 1 end
  if n <= 0 then return 0 end
  if not splits(id, data) then return 1 end
  local list = stackList(stacks, id, n)
  if list then return #list end
  if n <= MAX_STACK then return 1 end
  return math.ceil(n / MAX_STACK)
end
Bag.slotsFor = slotsFor

local function derivedCount(total, k, n)
  if type(total) ~= "number" or n <= 1 then return total end
  if k < n then return MAX_STACK end
  return total - MAX_STACK * (n - 1)
end

local function isDerived(counts)
  for k = 1, #counts - 1 do
    if counts[k] ~= MAX_STACK then return false end
  end
  return true
end

local function countsOf(store, id, data, stacks)
  local total = store[id]
  local n = slotsFor(id, total, data, stacks)
  local list = stackList(stacks, id, total)
  local out = {}
  for k = 1, n do out[k] = (list and list[k]) or derivedCount(total, k, n) end
  return out
end

local function setCounts(store, id, counts, stacks)
  local sum = 0
  for i = 1, #counts do sum = sum + counts[i] end
  store[id] = sum > 0 and sum or nil
  if stacks then
    stacks[id] = (#counts > 1 and not isDerived(counts)) and counts or nil
  end
end

local function occurrences(order, id)
  local at = {}
  for i = 1, #order do
    if order[i] == id then at[#at + 1] = i end
  end
  return at
end

local function byIndex(data)
  data = data or require("src.core.Data")
  local items = data and data.items
  local function key(id)
    local def = items and items[id]
    return (def and (def.index or def.itemId)) or math.huge
  end
  return function(a, b)
    local ia, ib = key(a), key(b)
    if ia ~= ib then
      if type(ia) == type(ib) then return ia < ib end
      return tostring(ia) < tostring(ib)
    end
    if type(a) == type(b) then return a < b end
    return tostring(a) < tostring(b)
  end
end

local function normalize(store, order, data, stacks)
  if stacks then
    for id in pairs(stacks) do
      local list = splits(id, data) and stackList(stacks, id, store[id])
      if not list or #list < 2 or isDerived(list) then stacks[id] = nil end
    end
  end
  local seen, w = {}, 0
  for i = 1, #order do
    local id = order[i]
    local k = (seen[id] or 0) + 1
    if k <= slotsFor(id, store[id], data, stacks) then
      seen[id] = k
      w = w + 1
      order[w] = id
    end
  end
  for i = #order, w + 1, -1 do order[i] = nil end
  local missing = {}
  for id, n in pairs(store) do
    for _ = (seen[id] or 0) + 1, slotsFor(id, n, data, stacks) do
      missing[#missing + 1] = id
    end
  end
  if #missing > 1 then table.sort(missing, byIndex(data)) end
  for _, id in ipairs(missing) do order[#order + 1] = id end
  return order
end
Bag.normalize = normalize

local function storeSlots(store, data, keep, stacks)
  local n = 0
  for id, count in pairs(store or {}) do
    if not keep or keep(id) then n = n + slotsFor(id, count, data, stacks) end
  end
  return n
end
Bag.storeSlots = storeSlots

function Bag.stackRows(store, order, data, stacks)
  local rows, seen = {}, {}
  for i, id in ipairs(order) do
    local k = (seen[id] or 0) + 1
    seen[id] = k
    local total = store[id]
    local list = stackList(stacks, id, total)
    rows[#rows + 1] = { id = id, slot = k, index = i,
      count = (list and list[k])
        or derivedCount(total, k, slotsFor(id, total, data, stacks)) }
  end
  return rows
end

function Bag.setRows(store, order, rows, data, stacks)
  local per = {}
  for i = 1, #rows do
    local id = rows[i].id
    order[i] = id
    if splits(id, data) and type(rows[i].count) == "number" then
      local counts = per[id] or {}
      counts[#counts + 1] = rows[i].count
      per[id] = counts
    end
  end
  for i = #order, #rows + 1, -1 do order[i] = nil end
  for id, counts in pairs(per) do setCounts(store, id, counts, stacks) end
end

-- engine/items/inventory.asm:7
function Bag.addTo(store, order, id, qty, data, used, cap, stacks)
  qty = qty or 1
  local old = store[id]
  if type(old) == "number" and old <= 0 then old = nil end
  if isBadge(id) then
    store[id] = (old or 0) + qty
    return true
  end
  if not splits(id, data) then
    if not old and used >= cap then return false end
    if (old or 0) + qty > MAX_STACK then return false end
    store[id] = (old or 0) + qty
    if not old then order[#order + 1] = id end
    return true
  end
  local free = cap - used
  local counts = old and countsOf(store, id, data, stacks) or {}
  local left = qty
  for k = 1, #counts do
    local sum = counts[k] + left
    if sum < MAX_STACK + 1 then
      counts[k] = sum
      left = 0
      break
    end
    -- engine/items/inventory.asm:72
    if free <= 0 then return false end
    counts[k] = MAX_STACK
    left = sum - MAX_STACK
  end
  while left > 0 do
    -- engine/items/inventory.asm:44
    if free <= 0 then return false end
    counts[#counts + 1] = math.min(left, MAX_STACK)
    left = left - MAX_STACK
  end
  local before = #occurrences(order, id)
  setCounts(store, id, counts, stacks)
  for _ = before + 1, #counts do order[#order + 1] = id end
  return true
end

-- engine/items/inventory.asm:100
function Bag.removeFrom(store, order, id, qty, data, slot, stacks)
  qty = qty or 1
  local old = store[id]
  if old ~= nil and type(old) ~= "number" then return end
  if not old or old <= 0 then
    store[id] = nil
    if order then
      for i = #order, 1, -1 do
        if order[i] == id then table.remove(order, i) end
      end
    end
    return
  end
  if isBadge(id) or not splits(id, data) then
    local left = old - qty
    store[id] = left > 0 and left or nil
    if order and not store[id] then
      for i = #order, 1, -1 do
        if order[i] == id then table.remove(order, i) end
      end
    end
    return
  end
  local counts = countsOf(store, id, data, stacks)
  local k = (slot and counts[slot]) and slot or 1
  local take = math.min(qty, counts[k])
  counts[k] = counts[k] - take
  qty = qty - take
  for i = 1, #counts do
    if qty <= 0 then break end
    take = math.min(qty, counts[i])
    counts[i] = counts[i] - take
    qty = qty - take
  end
  if order then
    local at = occurrences(order, id)
    for i = #at, 1, -1 do
      if counts[i] ~= nil and counts[i] <= 0 then table.remove(order, at[i]) end
    end
  end
  local kept = {}
  for i = 1, #counts do
    if counts[i] > 0 then kept[#kept + 1] = counts[i] end
  end
  setCounts(store, id, kept, stacks)
end

-- engine/menus/swap_items.asm:78
function Bag.swapSlots(store, order, first, second, data, stacks)
  if first == second or not order[first] or not order[second] then return false end
  local rows = Bag.stackRows(store, order, data, stacks)
  local a, b = rows[first], rows[second]
  if a.id ~= b.id or type(a.count) ~= "number" or type(b.count) ~= "number"
      or not splits(a.id, data) then
    rows[first], rows[second] = b, a
  else
    -- engine/menus/swap_items.asm:98
    local sum = a.count + b.count
    if sum < MAX_STACK + 1 then
      b.count = sum
      table.remove(rows, first)
    else
      a.count = sum - MAX_STACK
      b.count = MAX_STACK
    end
  end
  Bag.setRows(store, order, rows, data, stacks)
  return true
end

local function stacksOf(save, key)
  local t = save[key]
  if type(t) ~= "table" then t = {} end
  return t
end

local function keepStacks(save, key, t)
  save[key] = next(t) ~= nil and t or nil
end

-- Occupied slots, of one pocket when named or of the whole inventory when not.
function Bag.slots(save, data, pocket)
  if not save or not save.inventory then return 0 end
  return storeSlots(save.inventory, data, pocket and function(id)
    return pocketOf(id, data) == pocket
  end, save.bagStacks)
end

-- Acquisition-ordered id list (wBagItems).  Rebuilt sorted once for
-- saves from before the order existed, then maintained incrementally.
function Bag.order(save, data)
  if not save then return {} end
  save.inventory = save.inventory or {}
  local order = save.bagOrder
  if not order then
    order = {}
    save.bagOrder = order
  end
  -- drop stale ids, append unknown ones (defensive against direct
  -- inventory writes)
  local stacks = stacksOf(save, "bagStacks")
  normalize(save.inventory, order, data, stacks)
  keepStacks(save, "bagStacks", stacks)
  return order
end

function Bag.rows(save, data)
  if not save then return {} end
  local order = Bag.order(save, data)
  return Bag.stackRows(save.inventory, order, data, save.bagStacks)
end

function Bag.swap(save, first, second, data)
  if not save or not save.inventory then return false end
  local order = Bag.order(save, data)
  local stacks = stacksOf(save, "bagStacks")
  local ok = Bag.swapSlots(save.inventory, order, first, second, data, stacks)
  keepStacks(save, "bagStacks", stacks)
  return ok
end

-- ram/wram.asm:1895
function Bag.pcOrder(save, data)
  if not save then return {} end
  save.pcItems = save.pcItems or {}
  local order = type(save.pcOrder) == "table" and save.pcOrder or {}
  save.pcOrder = order
  local stacks = stacksOf(save, "pcStacks")
  normalize(save.pcItems, order, data, stacks)
  keepStacks(save, "pcStacks", stacks)
  return order
end

function Bag.pcRows(save, data)
  if not save then return {} end
  local order = Bag.pcOrder(save, data)
  return Bag.stackRows(save.pcItems, order, data, save.pcStacks)
end

function Bag.pcAdd(save, id, qty, data, cap)
  if not save then return false end
  local order = Bag.pcOrder(save, data)
  local stacks = stacksOf(save, "pcStacks")
  local ok = Bag.addTo(save.pcItems, order, id, qty, data,
    storeSlots(save.pcItems, data, nil, stacks), cap or 50, stacks)
  keepStacks(save, "pcStacks", stacks)
  return ok
end

function Bag.pcRemove(save, id, qty, data, slot)
  if not save or not save.pcItems then return end
  local stacks = stacksOf(save, "pcStacks")
  Bag.removeFrom(save.pcItems, save.pcOrder, id, qty, data, slot, stacks)
  keepStacks(save, "pcStacks", stacks)
end

-- engine/items/switch_items.asm:38 SwitchItemsInBag .below / .above -- the
-- rotate the PACK's SELECT performs, over the rows of ONE pocket.
function Bag.move(save, id, pocket, toIndex, data)
  local order = Bag.order(save, data)
  local slots, ids = {}, {}
  for i = 1, #order do
    if pocketOf(order[i], data) == pocket then
      slots[#slots + 1] = i
      ids[#ids + 1] = order[i]
    end
  end
  local from
  for i = 1, #ids do
    if ids[i] == id then from = i break end
  end
  if not from then return false end
  local to = math.max(1, math.min(math.floor(tonumber(toIndex) or from), #ids))
  if to == from then return false end
  table.insert(ids, to, table.remove(ids, from))
  for i = 1, #slots do order[slots[i]] = ids[i] end
  return true
end

-- engine/items/inventory.asm:59
function Bag.add(save, id, qty, data)
  if not save then return false end
  save.inventory = save.inventory or {}
  local inv = save.inventory
  if isBadge(id) then
    inv[id] = (inv[id] or 0) + (qty or 1)
    return true
  end
  -- Only the item's OWN pocket has to have room -- a full ITEM pocket does not
  -- keep a KEY_ITEM or an HM out, which is the whole point of pockets.
  local pocket = pocketOf(id, data)
  local order = Bag.order(save, data)
  local stacks = stacksOf(save, "bagStacks")
  local ok = Bag.addTo(inv, order, id, qty, data,
    Bag.slots(save, data, pocket), Bag.capacity(data, pocket), stacks)
  keepStacks(save, "bagStacks", stacks)
  return ok
end

-- Remove qty (default 1); clears the slot and its order entry at zero.
-- engine/menus/pc.asm:118
function Bag.remove(save, id, qty, data, slot)
  if not save or not save.inventory then return end
  local stacks = stacksOf(save, "bagStacks")
  Bag.removeFrom(save.inventory, save.bagOrder, id, qty, data, slot, stacks)
  keepStacks(save, "bagStacks", stacks)
end

return Bag
