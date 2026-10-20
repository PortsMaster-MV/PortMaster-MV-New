local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Bake = require("src.import.gba.bg_bake")
local Base = require("src.import.gba.rse.shop_chrome_extract")
local Scoped = require("src.import.gba.rs.scoped_symbols")

local M = {SUB = "items/shop", FILES = {"bg.rgba", "bg_tm.rgba", "money_label.rgba", "menu_tiles.4bpp", "menu_map.bin",
  "price10000.4bpp", "price10000.png"}, shopVersion = 2}
M.REQUIRED = K.required(M.SUB, M.FILES)

M.TEXT_ALIASES = {
  gText_ShopBuy = "MartText_Buy", gText_ShopSell = "MartText_Sell", gText_ShopQuit = "MartText_Quit2",
  gText_HowMayIServeYou = "Text_HowMayIServeYou", gText_QuitShopping = "gOtherText_QuitShopping",
  gText_AnythingElseICanHelp = "gOtherText_AnythingElse", gText_CanIHelpWithAnythingElse = "gOtherText_CanIHelpYou",
  gText_ThrowInPremierBall = "gOtherText_FreePremierBall", gText_HereYouGoThankYou = "gOtherText_HereYouGo",
  gText_NoMoreRoomForThis = "gOtherText_NoRoomFor", gText_ThankYouIllSendItHome = "gOtherText_HereYouGo2",
  gText_ThanksIllSendItHome = "gOtherText_HereYouGo3", gText_SpaceForVar1Full = "gOtherText_SpaceForIsFull",
  gText_YouDontHaveMoney = "gOtherText_NotEnoughMoney", gText_Var1CertainlyHowMany = "gOtherText_HowManyYouWant",
  gText_Var1CertainlyHowMany2 = "gOtherText_HowManyYouWant", gText_Var1AndYouWantedVar2 = "gOtherText_ThatWillBe",
  gText_Var1IsItThatllBeVar2 = "gOtherText_ThatWillBe2", gText_YouWantedVar1ThatllBeVar2 = "gOtherText_ThatWillBe3",
  gText_Cancel2 = "gOtherText_CancelNoTerminator", gText_xVar1 = "gOtherText_xString1",
  gText_CantBuyKeyItem = "gOtherText_CantBuyThat", gText_HowManyToSell = "gOtherText_HowManyToSell",
  gText_ICanPayVar1 = "gOtherText_CanPay", gText_TurnedOverVar1ForVar2 = "gOtherText_SoldItem",
}

local function array(bytes)
  local out = {_len = #bytes}
  for i = 1, #bytes do out[i] = bytes:byte(i) end
  return out
end
local function textBytes(c, symbol)
  local out, off = {}, c:off(symbol)
  for i = 0, 1023 do
    local b = c:u8(off + i); out[#out + 1] = b
    if b == 255 then return out end
  end
  error("native shop text is unterminated: " .. symbol)
end
local function window(c, symbol)
  local out, off = {}, c:off(symbol)
  for i, key in ipairs({"bg", "charbase", "screenbase", "priority", "palette", "foregroundColor", "backgroundColor",
    "shadowColor", "fontNum", "textMode", "spacing", "left", "top", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  return out
end

function M.run(rom, cache, opts)
  local c = Scoped.bind(A.context(rom, cache, opts, M.SUB))
  local gfx, map, pal = c:lz("gBuyMenuFrame_Gfx"), c:lz("gBuyMenuFrame_Tilemap"), c:lz("gMenuMoneyPal")
  assert(#map == 32 * 32 * 2 and #pal == 32, "native shop map/palette dimensions")
  local banks = Bake.loadPalBanks(array(pal), 1)
  local bg = Base.menuBg(array(gfx), banks, array(map))
  c:write("bg.rgba", bg); c:write("bg_tm.rgba", bg)
  c:write("menu_tiles.4bpp", gfx); c:write("menu_map.bin", map)
  local label = c:lz("gMenuMoneyGfx")
  assert(#label == 256, "native32x16 money label")
  c:write("money_label.rgba", Bake.bakeSpriteRgba(array(label), banks[0], 0, 32, 16, false, false))
  local priceGfx, fontPal = c:raw("gDecoration10000_Gfx", 0x200), c:pal("gFontDefaultPalette", 16)
  c:write("price10000.4bpp", priceGfx)
  local frames = {K.bakeSprite(priceGfx, 32, 16, 0, 4), K.bakeSprite(priceGfx, 32, 16, 8, 4)}
  local pricePng = c:png("price10000.png", 32, 32, K.stack(frames, 32, 16), fontPal, true)
  local text, strings = {}, {}
  for _, symbol in pairs(M.TEXT_ALIASES) do
    if not text[symbol] then text[symbol], strings[symbol] = textBytes(c, symbol), A.text(c, c:off(symbol)) end
  end
  return A.finish(c, {
    screen = "shop", format_version = 1, shopVersion = M.shopVersion, width = 240, height = 160,
    bg = "bg.rgba", bgTm = "bg_tm.rgba", moneyLabel = {file = "money_label.rgba", w = 32, h = 16},
    menuTiles = c:path("menu_tiles.4bpp"), menuMap = c:path("menu_map.bin"), menuPalette = K.palList(banks[0], 0, 16),
    price10000 = {png = pricePng, raw = c:path("price10000.4bpp"), w = 32, h = 16, frames = 2,
      normal = 0, selected = 1, paletteBank = 15, x = 200},
    defaultTextPalette = K.palList(fontPal, 0, 16),
    window = window(c, "gWindowTemplate_81E6DFC"), textBytes = text, strings = strings, textAliases = M.TEXT_ALIASES,
    geometry = {rootFrame = {0, 0, 10, 7}, decorRootFrame = {0, 0, 10, 5}, root = {8, 8, 16}, list = {112, 16, 16, 8},
      listNameWidth = 88, price = {202, 16, 16}, description = {4, 104, 104, 48}, moneyFrame = {0, 0, 13, 3}, moneyLabelCenter = {19, 11},
      moneyAmount = {6, 1, 6}, quantity = {8, 88}, checkoutPrice = {6, 11, 6},
      iconPane = false, ownedQuantityLabel = false, currency = 183, space = 0, minimumLetterSpacing = 6},
    textPalette = {foreground = 32767, shadow = 16878},
    frameTileBase = 0x3E0, framePaletteBank = 12,
  })
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  if not cache:read(base .. "manifest.lua"):find("shopVersion = " .. M.shopVersion, 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(base .. file) then return false end end
  return true
end
return M
