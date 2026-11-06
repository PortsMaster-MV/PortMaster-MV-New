local List = {}

-- pokeemerald/include/pokedex.h:9
List.DEX_MODE_HOENN = 0
List.DEX_MODE_NATIONAL = 1
List.NONE = 0xFFFF

-- pokeemerald/src/pokedex.c:73
List.ORDER_NUMERICAL = 0
List.ORDER_ALPHABETICAL = 1
List.ORDER_HEAVIEST = 2
List.ORDER_LIGHTEST = 3
List.ORDER_TALLEST = 4
List.ORDER_SMALLEST = 5

local function hoennCount(ctx)
  return #ctx.orders.numerical_hoenn
end
List.hoennCount = hoennCount

local function nationalCount(ctx)
  return ctx.nationalCount or #ctx.orders.numerical_national
end

-- pokeemerald/src/pokedex.c:4343
function List.counts(ctx)
  local hs, ho, ns, no = 0, 0, 0, 0
  for _, nat in ipairs(ctx.orders.numerical_hoenn) do
    if ctx.seen(nat) then hs = hs + 1 end
    if ctx.owned(nat) then ho = ho + 1 end
  end
  for nat = 1, nationalCount(ctx) do
    if ctx.seen(nat) then ns = ns + 1 end
    if ctx.owned(nat) then no = no + 1 end
  end
  return { hoennSeen = hs, hoennOwned = ho, nationalSeen = ns, nationalOwned = no }
end

local function inRange(ctx, nat, dexCount)
  local h = ctx.hoennNumber(nat)
  return h ~= nil and h <= dexCount
end

-- pokeemerald/src/pokedex.c:2177
function List.create(ctx, dexMode, order)
  local items, count = {}, 0
  local isHoenn = true
  local dexCount = hoennCount(ctx)
  if dexMode == List.DEX_MODE_NATIONAL and ctx.nationalEnabled then
    isHoenn = false
    dexCount = nationalCount(ctx)
  end
  local function push(nat, seen, owned)
    items[count] = { dexNum = nat, seen = seen, owned = owned }
    count = count + 1
  end
  if order == List.ORDER_NUMERICAL then
    if isHoenn then
      local listCount = 0
      for i, nat in ipairs(ctx.orders.numerical_hoenn) do
        local seen = ctx.seen(nat)
        items[i - 1] = { dexNum = nat, seen = seen, owned = ctx.owned(nat) }
        if seen then listCount = i end
      end
      count = listCount
    else
      local started, listCount = false, 0
      for nat = 1, dexCount do
        if ctx.seen(nat) then started = true end
        if started then
          local seen = ctx.seen(nat)
          items[count] = { dexNum = nat, seen = seen, owned = ctx.owned(nat) }
          count = count + 1
          if seen then listCount = count end
        end
      end
      count = listCount
    end
  elseif order == List.ORDER_ALPHABETICAL then
    for _, nat in ipairs(ctx.orders.atoz) do
      if inRange(ctx, nat, dexCount) and ctx.seen(nat) then push(nat, true, ctx.owned(nat)) end
    end
  else
    local src = (order == List.ORDER_HEAVIEST or order == List.ORDER_LIGHTEST) and ctx.orders.lightest or ctx.orders.smallest
    local reverse = order == List.ORDER_HEAVIEST or order == List.ORDER_TALLEST
    local n = #src
    for k = 1, n do
      local nat = src[reverse and (n - k + 1) or k]
      if inRange(ctx, nat, dexCount) and ctx.owned(nat) then push(nat, true, true) end
    end
  end
  for i = count, nationalCount(ctx) - 1 do items[i] = nil end
  return { items = items, count = count }
end

function List.item(list, i)
  return list.items[i] or { dexNum = List.NONE, seen = false, owned = false }
end

-- pokeemerald/src/pokedex.c:4680
function List.search(ctx, dexMode, order, abcGroup, bodyColor, type1, type2, letterRanges)
  local list = List.create(ctx, dexMode, order)
  local out = {}
  for i = 0, nationalCount(ctx) - 1 do
    local it = list.items[i]
    if it and it.seen then out[#out + 1] = it end
  end
  local function filter(pred)
    local kept = {}
    for _, it in ipairs(out) do
      if pred(it) then kept[#kept + 1] = it end
    end
    out = kept
  end
  if abcGroup ~= 0xFF then
    local r = letterRanges[abcGroup]
    filter(function(it)
      local first = ctx.firstChar(it.dexNum)
      return (first >= r[1] and first < r[1] + r[2]) or (first >= r[3] and first < r[3] + r[4])
    end)
  end
  if bodyColor ~= 0xFF then
    filter(function(it) return ctx.bodyColor(it.dexNum) == bodyColor end)
  end
  if type1 ~= ctx.TYPE_NONE or type2 ~= ctx.TYPE_NONE then
    if type1 == ctx.TYPE_NONE then
      type1, type2 = type2, ctx.TYPE_NONE
    end
    filter(function(it)
      if not it.owned then return false end
      local t = ctx.types(it.dexNum)
      if type2 == ctx.TYPE_NONE then return t[1] == type1 or t[2] == type1 end
      return (t[1] == type1 and t[2] == type2) or (t[1] == type2 and t[2] == type1)
    end)
  end
  local items = {}
  for i, it in ipairs(out) do items[i - 1] = it end
  return { items = items, count = #out }
end

return List
