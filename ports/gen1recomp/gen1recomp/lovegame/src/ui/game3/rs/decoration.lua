local Base = require("src.ui.game3.rse.decoration")
local Decor = require("src.core.game3.rse.decoration")
local Inv = require("src.core.game3.rse.decoration_inventory")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Text = require("src.core.game3.rom_text")
local IR = require("src.core.game3.scripting.text_ir")
local UI = {}
local Arrow = require("src.ui.game3.rs.scroll_arrow")
local aliases = {
  gText_Decorate = "SecretBaseText_Decorate", gText_PutAway = "SecretBaseText_PutAway",
  gText_Toss2 = "SecretBaseText_Toss", gText_Cancel = "gOtherText_Exit", gText_Exit = "gOtherText_Exit",
  gText_PutOutSelectedDecorItem = "SecretBaseText_PutOutDecor", gText_StoreChosenDecorInPC = "SecretBaseText_StoreChosenDecor",
  gText_ThrowAwayUnwantedDecors = "SecretBaseText_ThrowAwayDecor", gText_GoBackPrevMenu = "gMenuText_GoBackToPrev",
  gText_NoDecorations = "gSecretBaseText_NoDecors", gText_CantPlaceInRoom = "gSecretBaseText_DecorCantPlace",
  gText_InUseAlready = "gSecretBaseText_InUseAlready", gText_NoMoreDecorations = "gSecretBaseText_NoMoreDecor",
  gText_NoMoreDecorations2 = "gSecretBaseText_NoMoreDecor2", gText_PlaceItHere = "gSecretBaseText_PlaceItHere",
  gText_CantBePlacedHere = "gSecretBaseText_CantBePlacedHere", gText_CancelDecorating = "gSecretBaseText_CancelDecorating",
  gText_NoDecorationsInUse = "gSecretBaseText_NoDecorInUse", gText_StopPuttingAwayDecorations = "gSecretBaseText_StopPuttingAwayDecor",
  gText_DecorationReturnedToPC = "gSecretBaseText_DecorReturned", gText_ReturnDecorationToPC = "gSecretBaseText_ReturnDecor",
  gText_NoDecorationHere = "gSecretBaseText_NoDecor", gText_DecorationWillBeDiscarded = "gSecretBaseText_WillBeDiscarded",
  gText_DecorationThrownAway = "gSecretBaseText_DecorThrownAway", gText_CantThrowAwayInUse = "gSecretBaseText_DecorInUse",
  gText_NoRegistry = "gSecretBaseText_NoRegistry", gText_DelRegist = "SecretBaseText_DelRegist",
  gText_OkayToDeleteFromRegistry = "gOtherText_OkayToDeleteFromRegistry", gText_RegisteredDataDeleted = "gOtherText_RegisteredDataDeleted",
  gText_Yes = "OtherText_Yes", gText_No = "OtherText_No",
}
UI.TEXT_ALIASES = {gText_ApostropheSBase = "gOtherText_PlayersBase"}
local cats = {gText_Desk = 0, gText_Chair = 1, gText_Plant = 2, gText_Ornament = 3,
  gText_Mat = 4, gText_Poster = 5, gText_Doll = 6, gText_Cushion = 7}
local function nativeText(key, vars)
  if cats[key] ~= nil then return Inv.categoryName(cats[key]) end
  local native, m = aliases[key] or key, Decor.manifest()
  if m.textBytes and m.textBytes[native] then
    return IR.toPlain(IR.decode(m.textBytes[native], {dialect = "rs"}), {stringVars = vars or {}})
  end
  if m.strings[native] and not vars then return m.strings[native] end
  return Text.plain(native, vars and {stringVars = vars} or nil)
end
local function color(m, disabled)
  if disabled then return Kit.messageColors("std_menu", 2, 16, 9) end
  local p = m.menuPalette
  local function c(i) return type(p[i + 1]) == "number" and Kit.color555(p[i + 1]) or Kit.color8(p[i + 1]) end
  return {fg = c(1), bg = c(15), shadow = c(8)}
end
function UI.draw(d, host)
  local m = Decor.manifest()
  assert(m.assetLayout == "rs", "native RS decoration pack required")
  local Chrome = require("src.ui.game3.chrome")
  local function frame(f) Chrome.stdFrame(f[1] + 1, f[2] + 1, f[3] - f[1] - 1, f[4] - f[2] - 1) end
  local function print(value, x, y, width, disabled, limit)
    Font.draw(tostring(value or ""), x, y, {font = "native_3", linePitch = 16, maxWidth = width or 240,
      colors = color(m, disabled), limitChars = limit})
  end
  local function cursor(x, y, width) require("src.ui.game3.rs.menu_cursor").draw(x, y, width) end
  local s = d._session
  if d.mode then
    if d.mode.kind == "place" then host.drawPlacing() else host.drawPutAway() end
  elseif d.view == "actions" then
    frame(m.geometry.mainFrame)
    for i, a in ipairs(m.actions.main) do print(a.text, 8, 8 + (i - 1) * 16, 72) end
    cursor(8, 8 + d.actionCursor * 16, 72)
  elseif d.view == "categories" then
    frame(m.geometry.categoryFrame)
    for cat = 0, 7 do
      local disabled = d.isPlayerRoom and d.command == 0 and cat ~= 6 and cat ~= 7
      print(Inv.categoryName(cat), 8, 8 + cat * 16, 104, disabled)
      local count = string.format("%2d/%2d", Inv.countInCategory(cat, s), Inv.SIZES[cat])
      print(count, 112 - Font.measure(count, {font = "native_3"}), 8 + cat * 16, 104, disabled)
    end
    print(nativeText("gText_Exit"), 8, 136, 104); cursor(8, 8 + d.catCursor * 16, 104)
  elseif d.view == "items" then
    frame(m.geometry.categoryFrame); frame(m.geometry.categorySummaryFrame); frame(m.geometry.descriptionFrame)
    local inv = Inv.inventories(s)[d.category]
    local n = Inv.countInCategory(d.category, s) + 1
    local disabled = d.isPlayerRoom and d.command == 0 and d.category ~= 6 and d.category ~= 7
    for row = 0, math.min(n, 8) - 1 do
      local idx, y = d.scroll + row + 1, 16 + row * 16
      local info = idx < n and Inv.info(inv[idx])
      print(info and info.name or nativeText("gText_Exit"), 8, y, 104, disabled)
      local marker = d.inBase and d.inBase[idx] and m.inUseRed or d.inRoom and d.inRoom[idx] and m.inUseBlue
      if marker then love.graphics.draw(Kit.image(marker.png), 104, y + 4) end
    end
    cursor(8, 16 + d.row * 16, 104)
    print(Inv.categoryName(d.category), 128, 8, 104)
    local count = string.format("%2d/%2d", Inv.countInCategory(d.category, s), Inv.SIZES[d.category])
    print(count, 232 - Font.measure(count, {font = "native_3"}), 8, 104)
    local info = d.scroll + d.row + 1 < n and Inv.info(inv[d.scroll + d.row + 1])
    print(info and info.description or nativeText("gText_GoBackPrevMenu"), 128, 104, 104)
    if d.scroll > 0 then Arrow.draw("up", 60, 8, d.frames) end
    if d.scroll < n - 8 then Arrow.draw("down", 60, 152, d.frames) end
  elseif d.view == "registry" then
    frame(m.geometry.registryFrame)
    local rows = require("src.core.game3.rse.secret_base").registryEntries(s)
    rows[#rows + 1] = {name = nativeText("gText_Exit")}
    for row = 0, math.min(#rows, 8) - 1 do
      local e = rows[d.regScroll + row + 1]; if e then print(e.name, 144, 16 + row * 16, 88) end
    end
    cursor(144, 16 + d.regRow * 16, 88)
    if d.regScroll > 0 then Arrow.draw("up", 188, 8, d.frames) end
    if d.regScroll < #rows - 8 then Arrow.draw("down", 188, 152, d.frames) end
    if d.state == "registry_actions" then
      frame(m.geometry.registryActionsFrame)
      for i, a in ipairs(m.actions.registry) do print(a.text, 16, 8 + (i - 1) * 16, 80) end
      cursor(16, 8 + d.regAction * 16, 80)
    end
  end
  if d.msg and d.view ~= "items" and d.view ~= "categories" then
    if d.view == "actions" then print(d.msg.text, 16, 120, 208, false, d.msg.shown)
    else Chrome.stdFrame(1, 15, 28, 4); print(d.msg.text, 8, 120, 224, false, d.msg.shown) end
  end
  if d.state == "yesno" then
    Chrome.stdFrame(21, 9, 5, 4)
    print(nativeText("gText_Yes"), 168, 72, 40); print(nativeText("gText_No"), 168, 88, 40)
    cursor(168, 72 + (d.yesCursor - 1) * 16, 40)
  end
end
local function options(opts)
  opts = opts or {}
  opts.text, opts.draw = nativeText, UI.draw
  opts.recordSecretBaseVisit = false
  opts.avatarGfx = function(s, female)
    return require("src.core.game3.constants").active(s):require("event_objects",
      female and "OBJ_EVENT_GFX_MAY_DECORATING" or "OBJ_EVENT_GFX_BRENDAN_DECORATING")
  end
  return opts
end
function UI.open(opts) return Base.open(options(opts)) end
function UI.openPlayerRoom(opts) return Base.openPlayerRoom(options(opts)) end
function UI.openRegistry(opts) return Base.openRegistry(options(opts)) end
function UI.openTrade(ctx, done) return Base.openTrade(ctx, done, options()) end
function UI.isOpen() return Base.isOpen() end
function UI.reset() return Base.reset() end
return UI
