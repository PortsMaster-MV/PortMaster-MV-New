local Rse = require("src.core.game3.rse.init")
local MixUtil = require("src.core.game3.rse.record_mix_util")

local DaycareMail = {}

-- pokeemerald/include/constants/global.h:34
DaycareMail.DAYCARE_MON_COUNT = 2
-- pokeemerald/src/record_mixing.c:41
DaycareMail.NUM_SWAP_COMBOS = 3

-- pokeemerald/src/record_mixing.c:152
local SWAP_3P = { { 0, 1 }, { 1, 2 }, { 2, 0 } }
-- pokeemerald/src/record_mixing.c:159
local SWAP_4P = { { 0, 1, 2, 3 }, { 0, 2, 1, 3 }, { 0, 3, 2, 1 } }

local function sessionOf(sess)
  return sess or Rse.session()
end

local function daycare()
  return require("src.core.game3.daycare")
end

local function blankMail()
  return { message = { itemId = 0 }, otName = "", monName = "", gameLanguage = 0, monLanguage = 0 }
end

local function itemOf(mail)
  return tonumber(type(mail) == "table" and type(mail.message) == "table" and mail.message.itemId) or 0
end

local function heldItem(mon)
  return tonumber(mon and (mon.heldItem or mon.item)) or 0
end

-- pokeemerald/src/record_mixing.c:1366
function DaycareMail.mixExport(sess)
  sess = sessionOf(sess)
  local Daycare = daycare()
  local dc = Daycare.stateOf(sess)
  local out = { mail = {}, numDaycareMons = 0, cantHoldItem = {} }
  local stored = dc and dc.mail or {}
  -- pokeemerald/src/daycare.c:122
  for i = 1, DaycareMail.DAYCARE_MON_COUNT do
    local m = stored[i]
    out.mail[i] = type(m) == "table" and MixUtil.deep(m) or blankMail()
    if type(out.mail[i].message) ~= "table" then out.mail[i].message = { itemId = 0 } end
    local mon = dc and Daycare.mon(dc, i)
    if mon and Daycare.speciesOf(mon) ~= 0 then
      out.numDaycareMons = out.numDaycareMons + 1
      out.cantHoldItem[i] = heldItem(mon) ~= 0
    else
      out.cantHoldItem[i] = true
    end
  end
  return out
end

-- pokeemerald/src/record_mixing.c:743
function DaycareMail.randSum(packetOrBytes)
  if type(packetOrBytes) == "number" then return packetOrBytes % 256 end
  if type(packetOrBytes) ~= "table" then return 0 end
  local sum = tonumber(packetOrBytes.tvShowByteSum)
  if sum then return sum % 256 end
  local bytes = packetOrBytes.recordMixTvBytes256 or packetOrBytes
  if #bytes < 256 then return 0 end
  sum = 0
  for i = 1, 256 do sum = sum + MixUtil.num(bytes[i]) end
  return sum % 256
end

local function recordOf(players, i)
  local p = players[i + 1]
  local r = type(p) == "table" and p.daycareMail or nil
  if type(r) ~= "table" then
    r = { mail = { blankMail(), blankMail() }, numDaycareMons = 0, cantHoldItem = { true, true } }
    if type(p) == "table" then p.daycareMail = r end
  end
  r.mail = r.mail or {}
  for j = 1, DaycareMail.DAYCARE_MON_COUNT do
    if type(r.mail[j]) ~= "table" then r.mail[j] = blankMail() end
  end
  r.cantHoldItem = r.cantHoldItem or {}
  return r
end

-- pokeemerald/src/record_mixing.c:724
local function swap(players, idxs, s1, s2)
  local a, b = idxs[s1 + 1], idxs[s2 + 1]
  local ra, rb = recordOf(players, a[1]), recordOf(players, b[1])
  local tmp = ra.mail[a[2] + 1]
  ra.mail[a[2] + 1] = rb.mail[b[2] + 1]
  rb.mail[b[2] + 1] = tmp
end

-- pokeemerald/src/record_mixing.c:760
function DaycareMail.mixImport(players, sess, myIndex, randSum)
  sess = sessionOf(sess)
  players = players or {}
  local Rng = require("src.core.game3.rng")
  local oldSeed = Rng.Random2()
  Rng.SeedRng2(MixUtil.linkTrainerId(players[1]) % 0x10000)
  local count = #players
  local canHold = {}
  for i = 0, count - 1 do
    canHold[i] = { false, false }
    local r = recordOf(players, i)
    local n = MixUtil.num(r.numDaycareMons)
    for j = 1, math.min(n, DaycareMail.DAYCARE_MON_COUNT) do
      local cant = r.cantHoldItem[j]
      if not (cant == true or cant == 1) then canHold[i][j] = true end
    end
  end
  local idxs, numCanHold = {}, 0
  for i = 0, count - 1 do
    local r = recordOf(players, i)
    local c0, c1 = canHold[i][1], canHold[i][2]
    if c0 or c1 then numCanHold = numCanHold + 1 end
    if c0 and not c1 then
      idxs[#idxs + 1] = { i, 0 }
    elseif c1 and not c0 then
      idxs[#idxs + 1] = { i, 1 }
    elseif c0 and c1 then
      local item1, item2 = itemOf(r.mail[1]), itemOf(r.mail[2])
      local slot
      if (item1 == 0 and item2 == 0) or (item1 ~= 0 and item2 ~= 0) then
        slot = Rng.Random2() % 2
      elseif item1 ~= 0 then
        slot = 0
      else
        slot = 1
      end
      idxs[#idxs + 1] = { i, slot }
    end
  end
  local tableId = (tonumber(randSum) or 0) % DaycareMail.NUM_SWAP_COMBOS
  if numCanHold == 2 then
    swap(players, idxs, 0, 1)
  elseif numCanHold == 3 then
    swap(players, idxs, SWAP_3P[tableId + 1][1], SWAP_3P[tableId + 1][2])
  elseif numCanHold == 4 then
    local row = SWAP_4P[tableId + 1]
    swap(players, idxs, row[1], row[2])
    swap(players, idxs, row[3], row[4])
  end
  local mine = recordOf(players, (tonumber(myIndex) or 1) - 1)
  local dc = daycare().stateOf(sess)
  if dc then
    dc.mail = dc.mail or {}
    for j = 1, DaycareMail.DAYCARE_MON_COUNT do
      local m = mine.mail[j]
      dc.mail[j] = itemOf(m) ~= 0 and MixUtil.deep(m) or nil
    end
  end
  Rng.SeedRng(oldSeed)
  return true
end

Rse.register("daycareMail", DaycareMail)

return DaycareMail
