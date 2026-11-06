local Base = require("src.ui.game3.rse.shop_menu")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local Window = require("src.ui.game3.window")
local TextIR = require("src.core.game3.scripting.text_ir")
local Items = require("src.core.game3.items_data")
local UI = {CAMERA_OFFSET = {x = -3, y = -3}}
UI.WIN = {money = Window.template(1, 1, 12, 2), qty = Window.template(1, 11, 12, 2),
  yesno = Window.template(8, 9, 5, 4)}

local function manifest()
  local man = assert(Kit.manifest("items/shop"), "native RS shop pack missing")
  assert(man.assetLayout == "rs" and man.shopVersion == 2, "native RS shop schema required")
  return man
end
function UI.ir(key)
  local man = manifest()
  local native = assert(man.textAliases[key] or (man.textBytes[key] and key), "native RS shop text policy missing: " .. key)
  return TextIR.decode(assert(man.textBytes[native], "native RS shop text bytes missing: " .. native), {dialect = "rs"})
end
function UI.plain(key, ctx) return TextIR.toPlain(UI.ir(key), ctx or {}) end
function UI.box(key, ctx) return UI.plain(key, ctx) end
local function colors(inactive)
  local pal = manifest().defaultTextPalette
  return {fg = Kit.color555(pal[inactive and 3 or 2]), shadow = Kit.color555(pal[9]), bg = {0, 0, 0, 0}}
end
local function print(text, x, y, width, inactive)
  Font.draw(text, x, y, {font = "native_3", textMode = 2, colors = colors(inactive), maxWidth = width or 240, linePitch = 16})
end
local function frame(left, top, width, height)
  Chrome.stdFrame(left, top, width, height)
end
local function decor(shop) return shop._martType ~= Base.MART_NORMAL end
local function info(shop, id)
  if decor(shop) then return require("src.core.game3.rse.decoration_inventory").info(id) end
  return Items.info(id)
end
local function name(shop, id)
  if decor(shop) then return assert(info(shop, id), "native decoration missing").name end
  return Items.displayName(id)
end
local function price(shop, id)
  local p = tonumber(info(shop, id).price) or 0
  if decor(shop) then return p end
  local Rse = require("src.core.game3.rse.init")
  local active = require("src.core.game3.rse.tv").isPokeNewsActive(shop._session, 1, function(kind)
    return Rse.call("tv", "shouldApplyPokeNews", "ShouldApplyPokeNewsEffect", nil, kind) == true
  end)
  return active and math.floor(p / 2) or p
end

function UI.moneyText(amount, digits)
  local man = manifest()
  local value = math.max(0, math.floor(tonumber(amount) or 0))
  local n = tostring(value)
  local width = value > 999999 and 7 or value > 99999 and 6 or value > 10000 and 5
    or value > 999 and 4 or value > 99 and 3 or value > 9 and 2 or 1
  local function character(byte) return TextIR.toPlain(TextIR.decode({byte, 255}, {dialect = "rs"}), {}) end
  return string.char(252, 20, man.geometry.minimumLetterSpacing)
    .. string.rep(character(man.geometry.space), math.max(0, digits - width)) .. character(man.geometry.currency) .. n
    .. string.char(252, 20, 0)
end
function UI.drawMoneyAmount(_, tpl, amount)
  local text = UI.moneyText(amount, 6)
  local width = Font.measure(text, {font = "native_3", textMode = 2})
  print(text, width >= 56 and (tpl.left + 5) * 8 or (tpl.left + 12) * 8 - width, tpl.top * 8)
end
local function quantityText(amount, digits)
  return string.char(252, 20, 6) .. string.format("%" .. digits .. "d", amount) .. string.char(252, 20, 0)
end
function UI.drawMoneyBox(amount)
  frame(1, 1, 12, 2)
  local man = manifest()
  local bytes = assert(require("src.core.game3.dataset").cache():read("data/generated/gba/items/shop/" .. man.moneyLabel.file))
  if not UI._moneyImage then
    UI._moneyImage = love.graphics.newImage(love.image.newImageData(32, 16, "rgba8", bytes))
    UI._moneyImage:setFilter("nearest", "nearest")
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(UI._moneyImage, 3, 3)
  UI.drawMoneyAmount(nil, UI.WIN.money, amount)
end
local function message(shop)
  if not shop._status then return end
  Chrome.dialogueFrame()
  print(shop._status, 16, 120, 208)
end

function UI.step(shop, down)
  local n, visible = #shop._items + 1, math.min(8, #shop._items + 1)
  if down then
    if shop.row < visible - 1 then shop.row = shop.row + 1
    elseif shop.scroll + visible < n then shop.scroll = shop.scroll + 1
    else return false end
  elseif shop.row > 0 then shop.row = shop.row - 1
  elseif shop.scroll > 0 then shop.scroll = shop.scroll - 1
  else return false end
  return true
end
function UI.canPurchase(shop)
  return math.max(0, math.floor(tonumber(shop._session.money) or 0)) >= shop._totalCost
end
function UI.draw(shop)
  if shop.state == "root" then
    local keys = decor(shop) and {"gText_ShopBuy", "gText_ShopQuit"} or {"gText_ShopBuy", "gText_ShopSell", "gText_ShopQuit"}
    frame(1, 1, 9, #keys * 2)
    for i, key in ipairs(keys) do print(UI.plain(key), 8, 8 + (i - 1) * 16) end
    Cursor.draw(8, 8 + (shop.cursor - 1) * 16, 72)
    message(shop)
    return
  end
  if shop.state == "sell" then return end
  require("src.ui.game3.shop_chrome").drawBg(0, 0)
  UI.drawMoneyBox(shop._session.money)
  local visible = math.min(8, #shop._items + 1)
  for row = 0, visible - 1 do
    local id, y = shop._items[shop.scroll + row + 1], 16 + row * 16
    local inactive = shop.state ~= "list" and row == shop.row
    if id then
      print(name(shop, id), 112, y, 88, inactive)
      local p = price(shop, id)
      if decor(shop) and p == 10000 then
        local art = manifest().price10000
        local img = assert(Kit.image(art.png), "native10000 price image missing")
        local w, h = img:getDimensions()
        local q = love.graphics.newQuad(0, (inactive and art.selected or art.normal) * art.h, art.w, art.h, w, h)
        love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, q, art.x, y)
      else print(UI.moneyText(p, 4), 202, y, nil, inactive) end
    else print(UI.plain("gText_Cancel2"), 112, y) end
  end
  if shop.state == "list" then
    Cursor.draw(112, 16 + shop.row * 16, 120)
    local id = shop._items[shop.scroll + shop.row + 1]
    local description = id and (decor(shop) and info(shop, id).description or Items.description(id)) or UI.plain("gText_QuitShopping")
    print(description, 4, 104, 104)
  end
  if #shop._items >= 8 then
    local Arrow = require("src.ui.game3.rs.scroll_arrow")
    if shop.scroll > 0 then Arrow.draw("up", 172, 12, shop._rsShopFrame or 0) end
    if shop.state == "list" and shop.scroll + 7 < #shop._items then
      Arrow.draw("down", 172, 148, shop._rsShopFrame or 0)
    end
  end
  message(shop)
  if shop.state == "qty" then
    frame(1, 11, 12, 2)
    print(UI.plain("gText_xVar1", {stringVars = {quantityText(shop.qty, 2)}}), 8, 88)
    UI.drawMoneyAmount(nil, UI.WIN.qty, shop._totalCost)
  elseif shop.state == "confirm" then
    frame(8, 9, 5, 4)
    local Text = require("src.core.game3.rom_text")
    for i = 0, 1 do print(Text.at("gMenuYesNoItems", i), 64, 72 + i * 16) end
    Cursor.draw(64, 72 + ((shop.yesCursor or 1) - 1) * 16, 40)
  end
end
UI.alwaysQuantity, UI.doneCancel, UI.questLog = true, false, false
function UI.saleMoney(amount) return math.min(999999, amount) end
function UI.drawSell(sale)
  if sale.state ~= "cant" then UI.drawMoneyBox(sale.session.money) end
  Chrome.dialogueFrame()
  print(sale.text, 16, 120, 208)
  if sale.state == "qty" then
    frame(1, 11, 12, 2)
    local digits = sale:rseBerry() and 3 or 2
    local quantity = quantityText(sale.qty, digits)
    print(UI.plain("gText_xVar1", {stringVars = {quantity}}), 8, 88)
    UI.drawMoneyAmount(nil, UI.WIN.qty, sale:total())
  elseif sale.state == "confirm" then
    frame(8, 8, 5, 4)
    local Text = require("src.core.game3.rom_text")
    for i = 0, 1 do print(Text.at("gMenuYesNoItems", i), 64, 64 + i * 16) end
    Cursor.draw(64, 64 + (sale.yesNo - 1) * 16, 40)
  end
end
function UI.show(shop, opts)
  opts = opts or {}; opts.nativePolicy = UI
  manifest()
  shop._rsShopFrame = 0
  return Base.show(shop, opts)
end
function UI.handleInput(shop, input)
  if shop.state == "list" and not shop._fading then shop._rsShopFrame = (shop._rsShopFrame or 0) + 1 end
  return Base.handleInput(shop, input)
end
function UI.reset() UI._moneyImage = nil end
return UI
