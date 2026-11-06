local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local Pokeblock = require("src.core.game3.rse.pokeblock")

local NativesPokeblock = {}

-- pokeemerald/include/constants/vars.h:280
local VAR_0x8004 = 0x8004
local VAR_RESULT = 0x800D
local VAR_ITEM_ID = 0x800E

-- pokeemerald/src/berry_powder.c:14
local MAX_BERRY_POWDER = 99999

local function setString(ctx, i, s)
  if ctx and ctx.stringVars then ctx.stringVars[i] = s end
end

local function u16(v)
  return (tonumber(v) or 0) % 0x10000
end

local function session()
  return Rse.session()
end

-- pokeemerald/src/field_specials.c:1531
local function leadMon(sess)
  local party = sess and sess.party or {}
  local C = require("src.core.game3.constants").of(require("src.core.game3.constants").versionOf(sess))
  local egg = C:require("species", "SPECIES_EGG")
  for _, mon in ipairs(party) do
    local sp = tonumber(mon.species) or 0
    if not (mon.isEgg or mon.egg == true) and sp ~= egg and sp ~= 0 then return mon end
  end
  return party[1]
end
NativesPokeblock.leadMon = leadMon

local function powder(sess)
  local n = math.floor(tonumber(sess and sess.berryPowder) or 0)
  if n < 0 then n = 0 end
  return n
end

local function powderBox()
  return require("src.ui.game3.berry_powder_box")
end

-- pokeemerald/src/pokeblock.c:1274
function NativesPokeblock.openOnFeeder(ctx, adapters)
  local Natives = require("src.core.game3.scripting.natives")
  local sess = session()
  return Natives.yieldHost(ctx, adapters, function(done)
    Pokeblock.openCase(sess, {
      caseId = Pokeblock.CASE.FEEDER,
      onUse = function(id)
        Pokeblock.activateFeeder(sess, id)
        setString(ctx, 1, Pokeblock.name(Pokeblock.get(sess, id)))
        Rse.setSpecialVar(ctx, VAR_RESULT, id)
        Pokeblock.tryClear(sess, id)
        Rse.setSpecialVar(ctx, VAR_ITEM_ID, 0)
        return id
      end,
      onClose = function(result)
        if result == nil then
          -- pokeemerald/src/pokeblock.c:1041
          Rse.setSpecialVar(ctx, VAR_RESULT, 0xFFFF)
          Rse.setSpecialVar(ctx, VAR_ITEM_ID, 0)
        end
        -- pokeemerald/src/pokeblock.c:985
        local Fade = require("src.ui.game3.fade")
        Fade.begin(Fade.MODE.FROM_BLACK, 0, done)
      end,
    })
  end)
end

NativesPokeblock.BY_NAME = {
  -- pokeemerald/src/pokeblock.c:1346
  GetFirstFreePokeblockSlot = function(ctx)
    return false, u16(Pokeblock.firstFreeSlot(session()))
  end,
  -- pokeemerald/src/field_specials.c:1269
  GetPokeblockNameByMonNature = function(ctx)
    local mon = leadMon(session())
    local name = mon and Pokeblock.favoriteName(Pokeblock.natureOf(mon)) or nil
    if name then setString(ctx, 1, name) end
    return false, name and 1 or 0
  end,
  -- pokeemerald/src/safari_zone.c:131
  GetPokeblockFeederInFront = function(ctx)
    local i, name = Pokeblock.feederInFront(session())
    if i ~= -1 then setString(ctx, 1, name) end
    Rse.setSpecialVar(ctx, VAR_RESULT, u16(i))
    return false
  end,
  -- pokeemerald/src/pokeblock.c:483
  OpenPokeblockCaseOnFeeder = function(ctx, adapters)
    return NativesPokeblock.openOnFeeder(ctx, adapters)
  end,
  -- pokeemerald/src/berry_powder.c:223
  DisplayBerryPowderVendorMenu = function()
    powderBox().show(powder(session()))
    return false
  end,
  -- pokeemerald/src/berry_powder.c:234
  RemoveBerryPowderVendorMenu = function()
    powderBox().hide()
    return false
  end,
  -- pokeemerald/src/berry_powder.c:217
  PrintPlayerBerryPowderAmount = function()
    powderBox().update(powder(session()))
    return false
  end,
  -- pokeemerald/src/berry_powder.c:153
  HasEnoughBerryPowder = function(ctx)
    return false, (powder(session()) >= Rse.specialVar(ctx, VAR_0x8004)) and 1 or 0
  end,
  -- pokeemerald/src/berry_powder.c:188
  TakeBerryPowder = function(ctx)
    local sess = session()
    local cost = Rse.specialVar(ctx, VAR_0x8004)
    local have = powder(sess)
    local v = 0
    if sess and have >= cost then
      sess.berryPowder = math.min(have - cost, MAX_BERRY_POWDER)
      v = 1
    end
    return false, v
  end,
}

Std.legacyHandlers(NativesPokeblock)

return NativesPokeblock
