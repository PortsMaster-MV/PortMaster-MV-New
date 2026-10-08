local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")
require("src.core.game3.rse.frontier.pyramid")

local NativesPyramid = {}

local function P() return require("src.core.game3.rse.frontier.pyramid") end
local function natives() return require("src.core.game3.scripting.natives") end

local FUNCS = {}

local function build()
  local Py = P()
  local Fn = Py.FUNC
  FUNCS[Fn.INIT] = function(_, _, s) Py.init(s) end
  FUNCS[Fn.GET_DATA] = function(ctx, _, s) Py.getData(ctx, s) end
  FUNCS[Fn.SET_DATA] = function(ctx, _, s) Py.setData(ctx, s) end
  FUNCS[Fn.SAVE] = function(ctx, adapters, s) return Util.saveFromNative(ctx, adapters, s, Py.save) end
  FUNCS[Fn.SET_PRIZE] = function(_, _, s) Py.setPrize(s) end
  FUNCS[Fn.GIVE_PRIZE] = function(ctx, adapters, s) Py.givePrize(ctx, adapters, s) end
  FUNCS[Fn.SEED_FLOOR] = function(_, _, s) Py.seedFloor(s) end
  FUNCS[Fn.SET_ITEM] = function(ctx, _, s) Py.setItem(ctx, s) end
  FUNCS[Fn.HIDE_ITEM] = function(ctx, _, s) Py.hideItem(ctx, s) end
  -- pokeemerald/src/battle_pyramid.c:1028
  FUNCS[Fn.SET_TRAINERS] = function() end
  FUNCS[Fn.SHOW_HINT_TEXT] = function(ctx, adapters, s) Py.showHint(ctx, adapters, s) end
  FUNCS[Fn.UPDATE_STREAK] = function(_, _, s) Py.updateStreak(s) end
  FUNCS[Fn.CURRENT_LOCATION] = function(ctx, _, s) Util.setResult(ctx, Py.location(s)) end
  FUNCS[Fn.UPDATE_LIGHT] = function(ctx, _, s) Py.updateLight(ctx, s) end
  FUNCS[Fn.CLEAR_HELD_ITEMS] = function(_, _, s) Py.clearHeldItems(s) end
  FUNCS[Fn.SET_FLOOR_PALETTE] = function(_, _, s) Py.setFloorPalette(s) end
  -- pokeemerald/src/battle_pyramid.c:1193
  FUNCS[Fn.START_MENU] = function() end
  FUNCS[Fn.RESTORE_PARTY] = function(_, _, s) Py.restoreParty(s) end
end

local function ensure()
  if next(FUNCS) == nil then build() end
end

NativesPyramid.FUNCS = FUNCS

local function bagScreen()
  return require("src.ui.game3.rse.pyramid_bag")
end

-- pokeemerald/src/party_menu.c:6331
function NativesPyramid.chooseMonHeldItems(ctx, adapters, s)
  local PartyMenu = require("src.ui.game3.party_menu")
  local Choice = require("src.ui.game3.choice")
  local RomText = require("src.core.game3.rom_text")
  local ItemsData = require("src.core.game3.items_data")
  local Py = P()
  local done = false
  natives().awaitState(ctx, function() return done end)
  local function finish()
    PartyMenu.close()
    done = true
  end
  local function open()
    PartyMenu.show(s.party, nil, {
      mode = "choose",
      session = s,
      onSelect = function(slot)
        local mon = type(slot) == "number" and slot >= 1 and slot <= 6 and s.party[slot] or nil
        if not mon then return finish() end
        local item = tonumber(mon.heldItem or mon.item) or 0
        if item == 0 then return end
        Choice.multi({ RomText.plain("gMenuText_Take"), RomText.plain("gMenuText_Toss"), RomText.plain("gText_Cancel2") }, 2,
          function(pick)
            local nick = mon.nickname ~= "" and mon.nickname or mon.name or ""
            if pick == 0 then
              -- pokeemerald/src/party_menu.c:1813
              if Py.bagAdd(s, item, 1) then
                mon.item, mon.heldItem = nil, nil
                PartyMenu.showMessage(RomText.plain("gText_ReceivedItemFromPkmn",
                  { stringVars = { nick, ItemsData.displayName(item) } }), function() end)
              else
                PartyMenu.showMessage(RomText.plain("gText_BagFullCouldNotRemoveItem"), function() end)
              end
            elseif pick == 1 then
              mon.item, mon.heldItem = nil, nil
            end
          end, { left = 20, top = 8 })
      end,
      onClose = function() done = true end,
    })
  end
  open()
  return false
end

NativesPyramid.BY_NAME = {
  -- pokeemerald/src/battle_pyramid.c:835
  CallBattlePyramidFunction = function(ctx, adapters)
    ensure()
    local s = Rse.session()
    local id = Rse.specialVar(ctx, Util.VAR_0x8004)
    local fn = FUNCS[id]
    if not (s and fn) then
      Rse.missing("pyramid", "CallBattlePyramidFunction " .. tostring(id), adapters and adapters.log)
      return false
    end
    return fn(ctx, adapters, s) == true
  end,
  -- pokeemerald/src/party_menu.c:6307
  DoBattlePyramidMonsHaveHeldItem = function(ctx)
    local s = Rse.session()
    local r = s and P().monsHaveHeldItem(s) and 1 or 0
    Util.setResult(ctx, r)
    return false, r
  end,
  -- pokeemerald/src/battle_pyramid_bag.c:1402
  TryStoreHeldItemsInPyramidBag = function(ctx)
    local s = Rse.session()
    if s then P().tryStoreHeldItems(ctx, s) end
    return false
  end,
  -- pokeemerald/src/field_specials.c:3873
  GetBattlePyramidHint = function(ctx)
    local r = P().hint(Rse.specialVar(ctx, Util.VAR_0x8004))
    Util.setResult(ctx, r)
    return false, r
  end,
  -- pokeemerald/src/battle_pyramid_bag.c:393
  ChooseItemsToTossFromPyramidBag = function(ctx)
    local done = false
    natives().awaitState(ctx, function() return done end)
    bagScreen().show({ session = Rse.session(), location = "choose_toss", onClose = function() done = true end })
    return false
  end,
  -- pokeemerald/src/map_name_popup.c:231
  ShowMapNamePopup = function()
    local s = Rse.session()
    if s and Rse.flag("FLAG_HIDE_MAP_NAME_POPUP", s) then return false end
    local Map = package.loaded["src.core.game3.map"]
    local okP, Popup = pcall(require, "src.ui.game3.map_name_popup")
    if okP and Popup and Popup.show and Map and Map._def then Popup.show(Map._def, { force = true }) end
    return false
  end,
  -- pokeemerald/src/party_menu.c:6324
  BattlePyramidChooseMonHeldItems = function(ctx, adapters)
    local s = Rse.session()
    if not s then return false end
    return NativesPyramid.chooseMonHeldItems(ctx, adapters, s)
  end,
}

return NativesPyramid
