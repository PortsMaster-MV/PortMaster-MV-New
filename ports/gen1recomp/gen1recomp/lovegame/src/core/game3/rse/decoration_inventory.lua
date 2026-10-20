local DecorInv = {}

-- pokeemerald/include/global.h:1027
DecorInv.SIZES = { [0] = 10, [1] = 10, [2] = 10, [3] = 30, [4] = 30, [5] = 10, [6] = 40, [7] = 10 }
-- pokeemerald/include/constants/decorations.h:4
DecorInv.CATEGORY_COUNT = 8
DecorInv.DECOR_NONE = 0
DecorInv.FILE = "data/generated/gba/decorations/decorations.lua"

local data

function DecorInv.data()
  if data then return data end
  local src = assert(require("src.core.game3.dataset").cache():read(DecorInv.FILE), DecorInv.FILE .. " is not in the cache")
  data = assert(load(src, "@" .. DecorInv.FILE, "t", {}))()
  return data
end

function DecorInv.install(pack)
  data = pack
end

function DecorInv.info(decor)
  return DecorInv.data().decorations[tonumber(decor) or -1]
end

function DecorInv.categoryOf(decor)
  local d = DecorInv.info(decor)
  return d and d.category or nil
end

function DecorInv.categoryName(cat)
  return DecorInv.data().categoryNames[cat]
end

local function session_of(sess)
  if sess then return sess end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

-- pokeemerald/src/decoration_inventory.c:10
function DecorInv.inventories(sess)
  sess = session_of(sess)
  if not sess then return nil end
  local inv = sess.decorationInventory
  if type(inv) ~= "table" then
    inv = {}
    sess.decorationInventory = inv
  end
  for cat = 0, DecorInv.CATEGORY_COUNT - 1 do
    local list = inv[cat]
    if type(list) ~= "table" then
      list = {}
      inv[cat] = list
    end
    for i = 1, DecorInv.SIZES[cat] do
      list[i] = tonumber(list[i]) or DecorInv.DECOR_NONE
    end
  end
  return inv
end

-- pokeemerald/src/decoration_inventory.c:36
function DecorInv.clear(sess)
  local inv = DecorInv.inventories(sess)
  for cat = 0, DecorInv.CATEGORY_COUNT - 1 do
    for i = 1, DecorInv.SIZES[cat] do inv[cat][i] = DecorInv.DECOR_NONE end
  end
end

-- pokeemerald/src/decoration_inventory.c:43
function DecorInv.firstEmptySlot(cat, sess)
  local list = DecorInv.inventories(sess)[cat]
  for i = 1, DecorInv.SIZES[cat] do
    if list[i] == DecorInv.DECOR_NONE then return i end
  end
  return nil
end

-- pokeemerald/src/decoration_inventory.c:55
function DecorInv.has(decor, sess)
  decor = tonumber(decor) or 0
  local cat = DecorInv.categoryOf(decor)
  if not cat then return false end
  for _, d in ipairs(DecorInv.inventories(sess)[cat]) do
    if d == decor then return true end
  end
  return false
end

-- pokeemerald/src/decoration_inventory.c:70
function DecorInv.add(decor, sess)
  decor = tonumber(decor) or 0
  if decor == DecorInv.DECOR_NONE then return false end
  local cat = DecorInv.categoryOf(decor)
  local idx = cat and DecorInv.firstEmptySlot(cat, sess)
  if not idx then return false end
  DecorInv.inventories(sess)[cat][idx] = decor
  return true
end

-- pokeemerald/src/decoration_inventory.c:84
function DecorInv.checkSpace(decor, sess)
  decor = tonumber(decor) or 0
  if decor == DecorInv.DECOR_NONE then return false end
  local cat = DecorInv.categoryOf(decor)
  return cat ~= nil and DecorInv.firstEmptySlot(cat, sess) ~= nil
end

-- pokeemerald/src/decoration_inventory.c:117
function DecorInv.condense(cat, sess)
  local list = DecorInv.inventories(sess)[cat]
  local n = DecorInv.SIZES[cat]
  for i = 1, n do
    for j = i + 1, n do
      if list[j] ~= DecorInv.DECOR_NONE and (list[i] == DecorInv.DECOR_NONE or list[i] > list[j]) then
        list[i], list[j] = list[j], list[i]
      end
    end
  end
end

-- pokeemerald/src/decoration_inventory.c:93
function DecorInv.remove(decor, sess)
  decor = tonumber(decor) or 0
  if decor == DecorInv.DECOR_NONE then return 0 end
  local cat = DecorInv.categoryOf(decor)
  if not cat then return 0 end
  local list = DecorInv.inventories(sess)[cat]
  for i = 1, DecorInv.SIZES[cat] do
    if list[i] == decor then
      list[i] = DecorInv.DECOR_NONE
      DecorInv.condense(cat, sess)
      return 1
    end
  end
  return 0
end

-- pokeemerald/src/decoration_inventory.c:136
function DecorInv.countInCategory(cat, sess)
  local n = 0
  for _, d in ipairs(DecorInv.inventories(sess)[cat]) do
    if d ~= DecorInv.DECOR_NONE then n = n + 1 end
  end
  return n
end

-- pokeemerald/src/decoration_inventory.c:151
function DecorInv.count(sess)
  local n = 0
  for cat = 0, DecorInv.CATEGORY_COUNT - 1 do n = n + DecorInv.countInCategory(cat, sess) end
  return n
end

function DecorInv.export(sess)
  local inv = DecorInv.inventories(sess)
  local out = {}
  for cat = 0, DecorInv.CATEGORY_COUNT - 1 do
    out[cat] = {}
    for i = 1, DecorInv.SIZES[cat] do out[cat][i] = inv[cat][i] end
  end
  return out
end

function DecorInv.reset()
  data = nil
end

function DecorInv.checkSpaceResult(decor, sess)
  return DecorInv.checkSpace(decor, sess) and 1 or 0
end

return DecorInv
