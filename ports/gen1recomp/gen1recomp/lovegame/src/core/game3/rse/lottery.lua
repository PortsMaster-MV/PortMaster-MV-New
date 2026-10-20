local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")

local bit = require("bit")

local Lottery = {}

-- pokeemerald/include/constants/global.h:33
Lottery.PARTY_SIZE = 6

local function u32(v)
  v = v % 4294967296
  if v < 0 then v = v + 4294967296 end
  return v
end

-- pokeemerald/include/random.h:17
local function isoRandomize2(v)
  local Rng = require("src.core.game3.rng")
  return u32(Rng.mulU32(1103515245, v) + 12345)
end
Lottery.isoRandomize2 = isoRandomize2

-- pokeemerald/src/lottery_corner.c:147
function Lottery.setNumber(n, sess)
  n = u32(n)
  Rse.setVar("VAR_POKELOT_RND1", n % 0x10000, sess)
  Rse.setVar("VAR_POKELOT_RND2", math.floor(n / 0x10000) % 0x10000, sess)
end

-- pokeemerald/src/lottery_corner.c:156
function Lottery.getNumber(sess)
  return Rse.var("VAR_POKELOT_RND2", sess) * 0x10000 + Rse.var("VAR_POKELOT_RND1", sess)
end

-- pokeemerald/src/lottery_corner.c:24
function Lottery.reset(sess)
  local rand = Town.random()
  Lottery.setNumber(Town.random() * 0x10000 + rand, sess)
  Rse.setVar("VAR_POKELOT_PRIZE_ITEM", 0, sess)
end

-- pokeemerald/src/lottery_corner.c:32
function Lottery.setRandomNumber(days, sess)
  local v = Town.random()
  local i = (tonumber(days) or 0) % 0x10000
  while true do
    i = (i - 1) % 0x10000
    if i == 0xFFFF then break end
    v = isoRandomize2(v)
  end
  Lottery.setNumber(v, sess)
end

-- pokeemerald/src/lottery_corner.c:122
function Lottery.matchingDigits(winNumber, otId)
  winNumber = (tonumber(winNumber) or 0) % 0x10000
  otId = (tonumber(otId) or 0) % 0x10000
  local n = 0
  for _ = 1, 5 do
    if winNumber % 10 ~= otId % 10 then break end
    winNumber = math.floor(winNumber / 10)
    otId = math.floor(otId / 10)
    n = n + 1
  end
  return n
end

local function speciesOf(mon)
  return tonumber(mon and (mon.species or mon.speciesId)) or 0
end

local function isEgg(mon)
  local Pokemon = require("src.core.game3.pokemon")
  if Pokemon.isEgg then return Pokemon.isEgg(mon) == true end
  return mon.isEgg == true or mon.egg == true
end

local function otIdOf(mon, sess)
  return tonumber(mon.otId or mon.ot_id) or Town.trainerId16(sess)
end

-- pokeemerald/src/lottery_corner.c:48
function Lottery.pickTicket(winNumber, sess)
  sess = Town.session(sess)
  local best, where, slot, found = 0, nil, nil, nil
  local party = sess and sess.party or {}
  for i = 1, Lottery.PARTY_SIZE do
    local mon = party[i]
    if speciesOf(mon) == 0 then break end
    if not isEgg(mon) then
      local n = Lottery.matchingDigits(winNumber, otIdOf(mon, sess))
      if n > best and n > 1 then
        best, where, slot, found = n - 1, "party", i, mon
      end
    end
  end
  local storage = sess and sess.storage
  local Storage = require("src.core.game3.storage")
  for b = 1, Storage.TOTAL_BOXES_COUNT do
    local box = storage and storage.boxes and storage.boxes[b]
    for j = 1, 30 do
      local mon = box and box.mons and box.mons[j]
      if mon and speciesOf(mon) ~= 0 and not isEgg(mon) then
        local n = Lottery.matchingDigits(winNumber, otIdOf(mon, sess))
        if n > best and n > 1 then
          best, where, slot, found = n - 1, "box", j, mon
        end
      end
    end
  end
  if best == 0 then return { tier = 0 } end
  local prizes = Town.data().lotteryPrizes
  return { tier = best, prize = prizes[best], where = where, slot = slot, mon = found }
end

-- pokeemerald/src/field_specials.c:1585
function Lottery.ticketString(n)
  return string.format("%05d", (tonumber(n) or 0) % 100000)
end

-- pokeemerald/src/field_specials.c:1133
Lottery.LAPTOP = { { x = 11, y = 1, normal = "METATILE_Shop_Laptop1_Normal", flash = "METATILE_Shop_Laptop1_Flash" },
  { x = 11, y = 2, normal = "METATILE_Shop_Laptop2_Normal", flash = "METATILE_Shop_Laptop2_Flash" } }

function Lottery.setLaptop(on)
  local C = require("src.core.game3.constants").of("emerald")
  local Field = require("src.core.game3.field")
  for _, t in ipairs(Lottery.LAPTOP) do
    Field.setMetatile(t.x, t.y, C:require("metatile_labels", on and t.flash or t.normal), true)
  end
  local FieldView = package.loaded["src.core.game3.field_view"]
  if FieldView then FieldView._nativeDirty = true end
end

Lottery.effect = nil

-- pokeemerald/src/field_specials.c:1133
function Lottery.effectStep(task)
  if task.timer == 6 then
    task.timer = 0
    Lottery.setLaptop(not task.screenOn)
    task.screenOn = not task.screenOn
    task.flickers = task.flickers + 1
    if task.flickers == 5 then return true end
  end
  task.timer = task.timer + 1
  return false
end

-- pokeemerald/src/field_specials.c:1113
function Lottery.startComputerEffect()
  if Lottery.effect then return end
  local task = { timer = 0, flickers = 0, screenOn = false }
  local Field = require("src.core.game3.field")
  if type(Field.addFrameTask) == "function" then
    Lottery.effect = task
    Field.addFrameTask(function()
      if Lottery.effect ~= task then return true end
      if Lottery.effectStep(task) then
        Lottery.effect = nil
        return true
      end
      return false
    end)
  else
    Lottery.setLaptop(true)
  end
end

-- pokeemerald/src/field_specials.c:1161
function Lottery.endComputerEffect()
  Lottery.effect = nil
  Lottery.setLaptop(false)
end

function Lottery.installTimeHooks()
  local TimeEvents = require("src.core.game3.time_events")
  -- pokeemerald/src/clock.c:54
  TimeEvents.onDay("SetRandomLotteryNumber", function(sess, daysSince)
    if require("src.core.game3.capabilities").gate(sess, "lottery") then
      Lottery.setRandomNumber(daysSince, sess)
    end
  end)
end

local SaveSections = require("src.core.game3.save_sections")
-- pokeemerald/src/new_game.c:194
SaveSections.register("lottery", {
  newGame = function(sess)
    local rand = Town.random()
    local n = Town.random() * 0x10000 + rand
    local Constants = require("src.core.game3.constants")
    local C = Constants.of(Constants.versionOf(sess))
    sess.vars = sess.vars or {}
    sess.vars[C:require("vars", "VAR_POKELOT_RND1")] = n % 0x10000
    sess.vars[C:require("vars", "VAR_POKELOT_RND2")] = math.floor(n / 0x10000) % 0x10000
    sess.vars[C:require("vars", "VAR_POKELOT_PRIZE_ITEM")] = 0
  end,
})

Lottery.installTimeHooks()
Rse.register("lottery", Lottery)

return Lottery
