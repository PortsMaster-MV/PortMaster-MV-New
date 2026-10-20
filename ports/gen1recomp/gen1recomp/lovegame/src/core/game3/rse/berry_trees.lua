local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local BerryTrees = {}

-- pokeemerald/include/constants/berry.h:130
BerryTrees.COUNT = 128
-- pokeemerald/include/constants/berry.h:20
BerryTrees.STAGE_NO_BERRY = 0
BerryTrees.STAGE_PLANTED = 1
BerryTrees.STAGE_SPROUTED = 2
BerryTrees.STAGE_TALLER = 3
BerryTrees.STAGE_FLOWERING = 4
BerryTrees.STAGE_BERRIES = 5
BerryTrees.STAGE_SPARKLING = 255
-- pokeemerald/include/constants/berry.h:33
BerryTrees.NUM_WATER_STAGES = 4

local pack

function BerryTrees.berries()
  if pack == nil then
    local src = lazyReq("src.core.game3.dataset").cache():read("data/generated/gba/berries/berries.lua")
    local chunk = src and load(src, "@berries.lua", "t", {})
    local ok, t = false, nil
    if chunk then ok, t = pcall(chunk) end
    pack = ok and type(t) == "table" and t.berries or false
  end
  return pack or nil
end

function BerryTrees.reset()
  pack = nil
end

local function berryCount(list)
  local n = 0
  for k in pairs(list or {}) do if k + 1 > n then n = k + 1 end end
  return n
end

-- pokeemerald/src/berry.c:980
function BerryTrees.info(berry, session)
  if tonumber(berry) == 43 then
    local installed = require("src.core.game3.rs.enigma").info(session)
    if installed then return installed end
  end
  local list = assert(BerryTrees.berries(), "berry trees: data/generated/gba/berries/berries.lua missing from the cache")
  berry = tonumber(berry) or 0
  if berry == 0 or berry > berryCount(list) then berry = 1 end
  return list[berry - 1]
end

local function blank()
  return {
    berry = 0, stage = 0, stopGrowth = false, minutesUntilNextStage = 0, berryYield = 0,
    regrowthCount = 0, watered1 = false, watered2 = false, watered3 = false, watered4 = false,
  }
end
BerryTrees.blank = blank

local function defaultSession(session)
  return lazyReq("src.core.game3.rse.init").session() or session
end

BerryTrees._pending = nil

-- pokeemerald/include/global.h:1023
function BerryTrees.state(session)
  session = session or {}
  if type(session.berryTrees) ~= "table" then session.berryTrees = {} end
  local pending = BerryTrees._pending
  if pending and session.party ~= nil then
    BerryTrees._pending = nil
    for _, p in ipairs(pending) do BerryTrees.plant(p[1], p[2], p[3], p[4], session) end
  end
  return session.berryTrees
end

-- pokeemerald/src/berry.c:994
function BerryTrees.get(session, id)
  local trees = BerryTrees.state(defaultSession(session))
  id = tonumber(id) or 0
  if type(trees[id]) ~= "table" then trees[id] = blank() end
  return trees[id]
end

function BerryTrees.peek(session, id)
  session = defaultSession(session)
  if BerryTrees._pending and session then BerryTrees.state(session) end
  local trees = session and type(session.berryTrees) == "table" and session.berryTrees
  local t = trees and trees[tonumber(id) or 0]
  return type(t) == "table" and t or nil
end

-- pokeemerald/src/berry.c:1187
function BerryTrees.stagesWatered(tree)
  local n = 0
  for i = 1, 4 do if tree["watered" .. i] then n = n + 1 end end
  return n
end

-- pokeemerald/src/berry.c:1210
function BerryTrees.yieldInternal(max, min, water, random)
  if water == 0 then return min end
  local randMin = (max - min) * (water - 1)
  local randMax = (max - min) * water
  local r = randMin + (tonumber(random()) or 0) % (randMax - randMin + 1)
  local extra
  if r % BerryTrees.NUM_WATER_STAGES >= BerryTrees.NUM_WATER_STAGES / 2 then
    extra = math.floor(r / BerryTrees.NUM_WATER_STAGES) + 1
  else
    extra = math.floor(r / BerryTrees.NUM_WATER_STAGES)
  end
  return extra + min
end

-- pokeemerald/src/berry.c:1236
function BerryTrees.calcYield(tree, random, session)
  local b = BerryTrees.info(tree.berry, session)
  return BerryTrees.yieldInternal(tonumber(b.maxYield) or 0, tonumber(b.minYield) or 0,
    BerryTrees.stagesWatered(tree), random or lazyReq("src.core.game3.rng").Random)
end

-- pokeemerald/src/berry.c:1250
function BerryTrees.stageDuration(berry, session)
  return (tonumber(BerryTrees.info(berry, session).stageDuration) or 0) * 60
end

-- pokeemerald/src/berry.c:1116
function BerryTrees.plant(id, berry, stage, allowGrowth, session, random)
  session = defaultSession(session)
  if session == nil then
    BerryTrees._pending = BerryTrees._pending or {}
    table.insert(BerryTrees._pending, { id, berry, stage, allowGrowth })
    return true
  end
  random = random or lazyReq("src.core.game3.rng").Random
  local trees = BerryTrees.state(session)
  local tree = blank()
  trees[tonumber(id) or 0] = tree
  tree.berry = tonumber(berry) or 0
  tree.minutesUntilNextStage = BerryTrees.stageDuration(tree.berry, session)
  tree.stage = tonumber(stage) or 0
  if tree.stage == BerryTrees.STAGE_BERRIES then
    tree.berryYield = BerryTrees.calcYield(tree, random, session)
    tree.minutesUntilNextStage = tree.minutesUntilNextStage * 4
  end
  if not allowGrowth then tree.stopGrowth = true end
  BerryTrees.installTimeHook()
  return true
end

-- pokeemerald/src/berry.c:1136
function BerryTrees.remove(id, session)
  BerryTrees.state(defaultSession(session))[tonumber(id) or 0] = blank()
end

-- pokeemerald/src/berry.c:1141
function BerryTrees.clear(session)
  local trees = BerryTrees.state(defaultSession(session))
  for i = 0, BerryTrees.COUNT - 1 do trees[i] = blank() end
end

-- pokeemerald/src/berry.c:1048
function BerryTrees.grow(tree, random, session)
  if tree.stopGrowth then return false end
  local s = tree.stage
  if s == BerryTrees.STAGE_NO_BERRY then return false end
  if s == BerryTrees.STAGE_FLOWERING then
    tree.berryYield = BerryTrees.calcYield(tree, random, session)
    tree.stage = s + 1
  elseif s == BerryTrees.STAGE_PLANTED or s == BerryTrees.STAGE_SPROUTED or s == BerryTrees.STAGE_TALLER then
    tree.stage = s + 1
  elseif s == BerryTrees.STAGE_BERRIES then
    tree.watered1, tree.watered2, tree.watered3, tree.watered4 = false, false, false, false
    tree.berryYield = 0
    tree.stage = BerryTrees.STAGE_SPROUTED
    tree.regrowthCount = (tonumber(tree.regrowthCount) or 0) + 1
    if tree.regrowthCount == 10 then
      for k, v in pairs(blank()) do tree[k] = v end
    end
  end
  return true
end

-- pokeemerald/src/berry.c:1078
function BerryTrees.timeUpdate(session, minutes, random)
  session = defaultSession(session)
  local trees = BerryTrees.state(session)
  minutes = tonumber(minutes) or 0
  for i = 0, BerryTrees.COUNT - 1 do
    local tree = trees[i]
    if type(tree) == "table" and (tonumber(tree.berry) or 0) ~= 0 and (tonumber(tree.stage) or 0) ~= 0
        and not tree.stopGrowth then
      if minutes >= BerryTrees.stageDuration(tree.berry, session) * 71 then
        trees[i] = blank()
      else
        local time = minutes
        while time ~= 0 do
          if tree.minutesUntilNextStage > time then
            tree.minutesUntilNextStage = tree.minutesUntilNextStage - time
            break
          end
          time = time - tree.minutesUntilNextStage
          tree.minutesUntilNextStage = BerryTrees.stageDuration(tree.berry, session)
          if not BerryTrees.grow(tree, random, session) then break end
          if tree.stage == BerryTrees.STAGE_BERRIES then
            tree.minutesUntilNextStage = tree.minutesUntilNextStage * 4
          end
        end
      end
    end
  end
end

-- pokeemerald/src/clock.c:70
function BerryTrees.installTimeHook()
  local ok, TimeEvents = pcall(lazyReq, "src.core.game3.time_events")
  if not (ok and TimeEvents and TimeEvents.handlers) then return false end
  local _, perMinute = TimeEvents.handlers()
  if perMinute and perMinute.BerryTreeTimeUpdate == nil then
    TimeEvents.onMinute("BerryTreeTimeUpdate", function(session, minutes)
      BerryTrees.timeUpdate(session, minutes)
    end)
  end
  return true
end

-- pokeemerald/src/berry.c:999
function BerryTrees.water(id, session)
  local tree = BerryTrees.get(session, id)
  local s = tree.stage
  if s == BerryTrees.STAGE_PLANTED then tree.watered1 = true
  elseif s == BerryTrees.STAGE_SPROUTED then tree.watered2 = true
  elseif s == BerryTrees.STAGE_TALLER then tree.watered3 = true
  elseif s == BerryTrees.STAGE_FLOWERING then tree.watered4 = true
  else return false end
  return true
end

-- pokeemerald/src/berry.c:1182
function BerryTrees.allowGrowth(id, session)
  BerryTrees.get(session, id).stopGrowth = false
end

local function items(session)
  local Constants = lazyReq("src.core.game3.constants")
  local C = Constants.of(Constants.versionOf(defaultSession(session)))
  return C:require("items", "ITEM_CHERI_BERRY"), C:require("items", "ITEM_ENIGMA_BERRY")
end

-- pokeemerald/src/berry.c:1151
function BerryTrees.itemToBerry(item, session)
  local first, last = items(session)
  item = tonumber(item) or 0
  if item < first or item > last then return 1 end
  return item - first + 1
end

-- pokeemerald/src/berry.c:1161
function BerryTrees.berryToItem(berry, session)
  local first, last = items(session)
  berry = tonumber(berry) or 0
  local item = berry - 1
  if item < 0 or item > last - first then return first end
  return berry + first - 1
end

-- pokeemerald/src/berry.c:1171
function BerryTrees.name(berry)
  return tostring(BerryTrees.info(berry).name or "")
end

-- pokeemerald/src/item.c:102
function BerryTrees.countString(berry, count)
  local RomText = lazyReq("src.core.game3.rom_text")
  local word = (tonumber(count) or 0) < 2 and RomText.plain("gText_Berry") or RomText.plain("gText_Berries")
  return BerryTrees.name(berry) .. " " .. tostring(word)
end

-- pokeemerald/src/berry.c:1326
function BerryTrees.setSeen(objects, px, py, session)
  for _, eo in ipairs(objects or {}) do
    local bt = eo.berryTree
    if bt and eo.cellX and math.abs(eo.cellX - px) <= 7 and eo.cellY - py >= -4 and eo.cellY - py <= 4 then
      local tree = BerryTrees.peek(session, bt.id)
      if tree then tree.stopGrowth = false end
    end
  end
end

return BerryTrees
