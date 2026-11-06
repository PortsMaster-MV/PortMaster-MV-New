local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local BerryTrees = require("src.core.game3.rse.berry_trees")

local NativesBerry = {}

-- pokeemerald/include/constants/vars.h:280
local VAR_0x8004 = 0x8004
local VAR_0x8005 = 0x8005
local VAR_0x8006 = 0x8006
local VAR_ITEM_ID = 0x800E
local VAR_LAST_TALKED = 0x800F
local VAR_RESULT = 0x800D

local function Objects()
  return package.loaded["src.core.game3.objects"] or require("src.core.game3.objects")
end

-- pokeemerald/src/event_object_movement.c:2425
function NativesBerry.selectedObject(ctx)
  local lid = Rse.specialVar(ctx, VAR_LAST_TALKED)
  local eo = Objects().find(lid)
  if eo and eo.berryTree then return eo end
  return nil
end

function NativesBerry.treeId(ctx)
  local eo = NativesBerry.selectedObject(ctx)
  return eo and eo.berryTree.id or 0, eo
end

local function setString(ctx, i, s)
  if ctx and ctx.stringVars then ctx.stringVars[i] = s end
end

local function sparkling(eo)
  local bt = eo and eo.berryTree
  return bt ~= nil and (bt.func == "sparkle" or bt.func == "sparkle_end")
end
NativesBerry.sparkling = sparkling

-- pokeemerald/src/berry.c:1255
function NativesBerry.getTreeData(ctx)
  local id, eo = NativesBerry.treeId(ctx)
  local tree = BerryTrees.get(nil, id)
  BerryTrees.allowGrowth(id)
  if sparkling(eo) then
    Rse.setSpecialVar(ctx, VAR_0x8004, BerryTrees.STAGE_SPARKLING)
  else
    Rse.setSpecialVar(ctx, VAR_0x8004, tree.stage)
  end
  Rse.setSpecialVar(ctx, VAR_0x8005, BerryTrees.stagesWatered(tree))
  Rse.setSpecialVar(ctx, VAR_0x8006, tree.berryYield)
  setString(ctx, 1, BerryTrees.countString(tree.berry, tree.berryYield))
  return false
end

local function bag()
  local s = Rse.session()
  return s and s.bag
end

-- pokeemerald/src/berry.c:1319
function NativesBerry.playerHasBerries()
  local Bag = require("src.core.game3.bag")
  local ItemsData = require("src.core.game3.items_data")
  local first = BerryTrees.berryToItem(1)
  return #Bag.listPocket(bag(), ItemsData.pocketOf(first)) > 0
end

local function watering(done)
  local P = package.loaded["src.core.game3.player"] or require("src.core.game3.player")
  -- pokeemerald/src/fldeff_misc.c:1248
  P.watering = true
  P.startAction({
    frames = 11 * 16, walk = "normal",
    done = function()
      P.watering = false
      done()
    end,
  })
end
NativesBerry.watering = watering

NativesBerry.BY_NAME = {
  ObjectEventInteractionGetBerryTreeData = function(ctx) return NativesBerry.getTreeData(ctx) end,
  -- pokeemerald/src/berry.c:1278
  ObjectEventInteractionGetBerryName = function(ctx)
    local id = NativesBerry.treeId(ctx)
    setString(ctx, 1, BerryTrees.name(BerryTrees.get(nil, id).berry))
    return false
  end,
  -- pokeemerald/src/berry.c:1284
  ObjectEventInteractionGetBerryCountString = function(ctx)
    local id = NativesBerry.treeId(ctx)
    local tree = BerryTrees.get(nil, id)
    setString(ctx, 1, BerryTrees.countString(tree.berry, tree.berryYield))
    return false
  end,
  -- pokeemerald/src/berry.c:1297
  ObjectEventInteractionPlantBerryTree = function(ctx)
    local id = NativesBerry.treeId(ctx)
    local berry = BerryTrees.itemToBerry(Rse.specialVar(ctx, VAR_ITEM_ID))
    BerryTrees.plant(id, berry, BerryTrees.STAGE_PLANTED, true)
    return NativesBerry.getTreeData(ctx)
  end,
  -- pokeemerald/src/berry.c:1305
  ObjectEventInteractionPickBerryTree = function(ctx)
    local Bag = require("src.core.game3.bag")
    local id = NativesBerry.treeId(ctx)
    local tree = BerryTrees.get(nil, id)
    local ok = Bag.add(bag(), BerryTrees.berryToItem(tree.berry), tree.berryYield)
    Rse.setSpecialVar(ctx, VAR_0x8004, ok and 1 or 0)
    return false
  end,
  -- pokeemerald/src/berry.c:1313
  ObjectEventInteractionRemoveBerryTree = function(ctx)
    local id, eo = NativesBerry.treeId(ctx)
    BerryTrees.remove(id)
    if eo then eo.berryTree.justPicked = true end
    return false
  end,
  -- pokeemerald/src/berry.c:999
  ObjectEventInteractionWaterBerryTree = function(ctx)
    local id = NativesBerry.treeId(ctx)
    Rse.setSpecialVar(ctx, VAR_RESULT, BerryTrees.water(id) and 1 or 0)
    return false
  end,
  PlayerHasBerries = function(ctx)
    local v = NativesBerry.playerHasBerries() and 1 or 0
    Rse.setSpecialVar(ctx, VAR_RESULT, v)
    return false, v
  end,
  -- pokeemerald/src/berry.c:969
  IsEnigmaBerryValid = function(ctx)
    Rse.setSpecialVar(ctx, VAR_RESULT, 0)
    return false, 0
  end,
  -- pokeemerald/src/tv.c:2523
  IncrementDailyPlantedBerries = function()
    Rse.setVar("VAR_DAILY_PLANTED_BERRIES", (Rse.var("VAR_DAILY_PLANTED_BERRIES") + 1) % 0x10000)
    return false
  end,
  -- pokeemerald/src/tv.c:2528
  IncrementDailyPickedBerries = function(ctx)
    Rse.setVar("VAR_DAILY_PICKED_BERRIES",
      (Rse.var("VAR_DAILY_PICKED_BERRIES") + Rse.specialVar(ctx, VAR_0x8006)) % 0x10000)
    return false
  end,
  -- pokeemerald/src/berry.c:1292
  Bag_ChooseBerry = function(ctx, adapters)
    local Natives = require("src.core.game3.scripting.natives")
    Rse.setSpecialVar(ctx, VAR_ITEM_ID, 0)
    local impl = Rse.system("bag", "Bag_ChooseBerry", adapters and adapters.log)
    if not (impl and impl.chooseBerry) then return false end
    return Natives.yieldHost(ctx, adapters, function(done)
      impl.chooseBerry(ctx, function(item)
        Rse.setSpecialVar(ctx, VAR_ITEM_ID, tonumber(item) or 0)
        -- pokeemerald/src/field_screen_effect.c:150
        local Fade = require("src.ui.game3.fade")
        Fade.begin(Fade.MODE.FROM_BLACK, 0, done)
      end)
    end)
  end,
  -- pokeemerald/src/fldeff_misc.c:1285
  DoWateringBerryTreeAnim = function(ctx)
    local finished = false
    watering(function() finished = true end)
    ctx.stateWait = function() return finished end
    return false
  end,
}

Std.legacyHandlers(NativesBerry)

return NativesBerry
