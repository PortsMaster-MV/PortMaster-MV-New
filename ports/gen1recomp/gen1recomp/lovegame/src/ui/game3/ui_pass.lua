local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local Stack = require("src.ui.game3.stack")

local UiPass = {}

local function setRgb(r, g, b, a)
  love.graphics.setColor(r, g, b, a or 1)
end

local gfxDrawWarned = {}
local function tryDraw(mod)
  if mod and mod.draw then
    local ok, err = pcall(mod.draw)
    if not ok and not gfxDrawWarned[tostring(mod)] then
      gfxDrawWarned[tostring(mod)] = true
      print("[game3/gfx] mod draw failed: " .. tostring(err))
    end
  end
end

function UiPass.drawUi()
  local Message = lazyReq("src.ui.game3.message")
  local Choice = lazyReq("src.ui.game3.choice")
  local StartMenu = lazyReq("src.ui.game3.start_menu")
  local BagMenu = lazyReq("src.ui.game3.bag_menu")
  local RegionMap = lazyReq("src.ui.game3.region_map")
  local PartyMenu = lazyReq("src.ui.game3.party_menu")
  local Pokedex = lazyReq("src.ui.game3.pokedex")
  local OptionMenu = lazyReq("src.ui.game3.option_menu")
  local SaveMenu = lazyReq("src.ui.game3.save_menu")
  local TrainerCard = lazyReq("src.ui.game3.trainer_card")
  local PcMenu = lazyReq("src.ui.game3.pc_menu")
  local MoneyBox = lazyReq("src.ui.game3.money_box")
  local CoinsBox = lazyReq("src.ui.game3.coins_box")
  local ElevatorWindow = lazyReq("src.ui.game3.elevator_window")

  local Screens = lazyReq("src.ui.game3.screens")
  local order = Stack.drawOrder()
  if #order > 0 then
    for _, layer in ipairs(order) do
      local skin = Screens.skin(layer.id)
      if skin and skin.draw then
        tryDraw({ draw = function() skin.draw(layer.mod) end })
      else
        tryDraw(layer.mod)
      end
    end
  else
    if StartMenu.isOpen() then tryDraw(StartMenu) end
    if BagMenu.isOpen() then tryDraw(BagMenu) end
    if RegionMap.isOpen() then tryDraw(RegionMap) end
    if PartyMenu.isOpen() then tryDraw(PartyMenu) end
    if Pokedex.isOpen() then tryDraw(Pokedex) end
    if OptionMenu.isOpen() then tryDraw(OptionMenu) end
    if SaveMenu.isOpen() then tryDraw(SaveMenu) end
    if TrainerCard.isOpen() then tryDraw(TrainerCard) end
    if PcMenu.isOpen() then tryDraw(PcMenu) end
  end

  if MoneyBox.isVisible and MoneyBox.isVisible() then
    local ShopMenu = package.loaded["src.ui.game3.shop_menu"]
    if not (ShopMenu and ShopMenu.isOpen and ShopMenu.isOpen()) then
      tryDraw(MoneyBox)
    end
  end

  -- pokefirered/src/coins.c:79
  if CoinsBox.isVisible and CoinsBox.isVisible() then
    tryDraw(CoinsBox)
  end

  -- pokefirered/src/berry_powder.c:113
  local BerryPowderBox = lazyReq("src.ui.game3.berry_powder_box")
  if BerryPowderBox.isVisible() then
    tryDraw(BerryPowderBox)
  end

  -- pokefirered/src/field_specials.c:1094
  if ElevatorWindow.isVisible and ElevatorWindow.isVisible() then
    tryDraw(ElevatorWindow)
  end

  -- pokefirered/src/map_name_popup.c
  local okPrev, MapPreviewScreen = pcall(lazyReq, "src.ui.game3.map_preview_screen")
  local previewActive = okPrev and MapPreviewScreen and MapPreviewScreen.isActive
    and MapPreviewScreen.isActive()
  if previewActive then
    local top = Stack.top()
    local suppress = top and top.hideBelow
    if not suppress and not Message.isOpen() then
      tryDraw(MapPreviewScreen)
    else
      previewActive = false
    end
  end

  local okPop, MapNamePopup = pcall(lazyReq, "src.ui.game3.map_name_popup")
  if okPop and MapNamePopup and MapNamePopup.isActive and MapNamePopup.isActive()
      and not previewActive then
    local top = Stack.top()
    local suppress = top and top.hideBelow
    if not suppress and not Message.isOpen() then
      tryDraw(MapNamePopup)
    end
  end

  local okPic, MonPic = pcall(lazyReq, "src.ui.game3.mon_pic")
  if okPic and MonPic and MonPic.active then
    tryDraw(MonPic)
  end

  local top = Stack.top()
  local suppressOverworldDialog = top and top.hideBelow

  local MuseumPic = lazyReq("src.ui.game3.museum_fossil_pic")
  if MuseumPic.isActive() and not suppressOverworldDialog
      and not Stack.fullscreen() and not Stack.has("box_storage") and not Stack.has("pc_menu") then
    tryDraw(MuseumPic)
  end

  local towerRecords = package.loaded["src.ui.game3.rs.battle_tower_records"]
  if towerRecords and towerRecords.isVisible() and not suppressOverworldDialog then tryDraw(towerRecords) end
  local linkRecords = package.loaded["src.ui.game3.rs.link_records"]
  if linkRecords and linkRecords.isVisible() and not suppressOverworldDialog then tryDraw(linkRecords) end

  if Message.isOpen() and not suppressOverworldDialog and not Stack.has("box_storage") and not Stack.has("pc_menu") then
    Message.draw()
  end

  if Choice.active and Choice.options and not suppressOverworldDialog then
    tryDraw(Choice)
  end

  local okN, Naming = pcall(lazyReq, "src.ui.game3.naming")
  if okN and Naming.isOpen and Naming.isOpen() then
    tryDraw(Naming)
  end

  local okTr, BattleTransition = pcall(lazyReq, "src.core.game3.battle_transition")
  if okTr and BattleTransition and BattleTransition.draw then
    BattleTransition.draw()
  end

  local okSea, SeagallopUi = pcall(lazyReq, "src.ui.game3.seagallop")
  if okSea and SeagallopUi and SeagallopUi.isActive and SeagallopUi.isActive() then
    tryDraw(SeagallopUi)
  end

  -- pokefirered/src/overworld.c:1833
  local okW, WirelessIcon = pcall(lazyReq, "src.ui.game3.wireless_icon")
  if okW and WirelessIcon.drawField then tryDraw({ draw = WirelessIcon.drawField }) end

  local okF, Fade = pcall(lazyReq, "src.ui.game3.fade")
  local okN, Naming = pcall(lazyReq, "src.ui.game3.naming")
  local isNamingOpen = okN and Naming.isOpen and Naming.isOpen()
  local okR, RegionMap = pcall(lazyReq, "src.ui.game3.region_map")
  local isRegionMapOpen = okR and RegionMap.isOpen and RegionMap.isOpen()
  local okEC, EasyChat = pcall(lazyReq, "src.ui.game3.easy_chat")
  local isEasyChatOpen = okEC and EasyChat.isOpen and EasyChat.isOpen()
  local isFullscreen = Stack.fullscreen() or Stack.has("bag") or BagMenu.isOpen()
  if isFullscreen or isNamingOpen or isRegionMapOpen or isEasyChatOpen then
    local okRen, Renderer = pcall(lazyReq, "src.render.Renderer")
    if okRen and Renderer then Renderer.screenVeil = nil end
  elseif okF and Fade.draw then
    Fade.draw()
  end

  setRgb(1, 1, 1, 1)
end


return UiPass
