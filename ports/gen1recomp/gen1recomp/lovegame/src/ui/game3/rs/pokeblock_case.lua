local Base = require("src.ui.game3.rse.pokeblock_case")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local Blocks = require("src.core.game3.rse.pokeblock")
local Font = require("src.ui.game3.frlg_font")
local Text = require("src.core.game3.rom_text")
local UI = {}
local Arrow = require("src.ui.game3.rs.scroll_arrow")

local use, toss, cancel = {text = "OtherText_Use", kind = "use_field"},
  {text = "OtherText_Toss", kind = "toss"}, {text = "gOtherText_CancelNoTerminator", kind = "cancel"}
UI.ACTIONS = {
  [Blocks.CASE.FIELD] = {use, toss, cancel},
  [Blocks.CASE.BATTLE] = {{text = "OtherText_Use", kind = "use"}, cancel},
  [Blocks.CASE.FEEDER] = {{text = "OtherText_Use", kind = "use"}, cancel},
}
UI.TEXT_ALIASES = {gText_ThrowAwayVar1 = "gContestStatsText_ThrowAwayPrompt",
  gText_Var1ThrownAway = "gContestStatsText_WasThrownAway"}

local function colors(transparent)
  -- text.c:874
  local c = Kit.messageColors("std_menu", 2, 16, 9)
  return {fg = c.fg, shadow = c.shadow, bg = transparent and {0, 0, 0, 0} or c.bg}
end
local function print(text, x, y, color)
  Font.draw(text, x, y, {font = "native_3", colors = color, maxWidth = 240})
end
local function yesNo()
  -- pokeblock.c:902
  return Kit.yesNo(8, 7)
end
local function drawYesNo(yn)
  if not yn then return end
  require("src.ui.game3.chrome").stdFrame(8, 7, 5, 4)
  for i = 0, 1 do print(Text.at("gMenuYesNoItems", i), 64, 56 + i * 16, colors(false)) end
  require("src.ui.game3.rs.menu_cursor").draw(64, 56 + yn.cursor * 16, 40)
end

-- pokeblock.c:465
local function swap(st, selected, canceled)
  -- pokeblock.c:774
  if canceled or selected >= st.itemsNo - 1 then return end
  local slots = Blocks.slots(st.session)
  slots[st.toSwap + 1], slots[selected + 1] = slots[selected + 1], slots[st.toSwap + 1]
end

local function paintHighlights(st, saved)
  for row = 0, 8 do
    local tile = 0x0005
    if row == saved.row then tile = st.swapping and 0x2005 or 0x1005
    elseif st.swapping and row + saved.scroll == st.toSwap then tile = 0x1005 end
    for y = row * 2 + 1, row * 2 + 2 do
      for x = 15, 28 do
        local id = y * 32 + x
        if st.map[id] ~= tile then st.map[id], st.dirty = tile, true end
      end
    end
  end
end

function UI.draw(st, Case)
  local gfx = Gfx.of("rse/pokeblock")
  local man = gfx:manifest()
  assert(man.assetLayout == "rs", "native RS Pokeblock pack required")
  paintHighlights(st, Case.saved)
  if st.dirty or not st.bg then
    st.bg = gfx:renderMap(st.map, "menu", Gfx.palette(man.palettes.menu, {}, 0), {rows = 20, backdrop = true})
    st.dirty = false
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(st.bg, 0, 0)
  local shake = {-2, -2, 2, 2, 2, 2, -2, -2, -2, -2, 2, 2}
  local rot = 0
  for i = 1, math.min(st.shake or 0, #shake) do rot = rot + shake[i] end
  love.graphics.draw(gfx:sprite("device", 0, 64, 64, man.palettes.device), 56, 64,
    rot * 2 * math.pi / 256, 1, 1, 32, 32)
  local c = colors(true)
  local item = require("src.core.game3.constants").active(st.session):require("items", "ITEM_POKEBLOCK_CASE")
  local title = require("src.core.game3.items_data").displayName(item)
  print(title, 16 + math.floor((72 - Font.measure(title, {font = "native_3"})) / 2), 8, c)
  for i, name in ipairs({"Spicy", "Dry", "Sweet", "Bitter", "Sour"}) do
    print(Text.plain("gContestStatsText_" .. name), i <= 3 and 16 or 64, 104 + ((i - 1) % 3) * 16, c)
  end
  if st.feel then print(string.format("%2d", st.feel), 88, 136, c) end
  for i = 0, st.maxShowed - 1 do
    local id = Case.saved.scroll + i
    if id < st.itemsNo - 1 then
      local block = Blocks.get(st.session, id)
      print(Blocks.name(block), 120, 8 + i * 16, c)
      local level = string.format("%3d", Blocks.highestFlavorLevel(block))
      for j = 1, 3 do print(level:sub(j, j), 214 + (j - 1) * 6, 8 + i * 16, c) end
    else print(Text.plain("gContestStatsText_StowCase"), 120, 8 + i * 16, c) end
  end
  if st.phase == "list" or st.phase == "swap" then
    if Case.saved.scroll > 0 then Arrow.draw("up", 176, 8, st.frame or 0) end
    if Case.saved.scroll < st.itemsNo - st.maxShowed then Arrow.draw("down", 176, 152, st.frame or 0) end
  end
  if st.phase == "actions" then
    local actions = UI.ACTIONS[st.caseId] or UI.ACTIONS[Blocks.CASE.FIELD]
    local y = #actions == 3 and 5 or 7
    require("src.ui.game3.chrome").stdFrame(8, y, 5, #actions * 2)
    for i, action in ipairs(actions) do print(Text.plain(action.text), 64, y * 8 + (i - 1) * 16, colors(false)) end
    require("src.ui.game3.rs.menu_cursor").draw(64, y * 8 + st.actionCursor * 16, 40)
  elseif st.phase == "toss" or st.phase == "toss_yesno" or st.phase == "tossed" then
    require("src.ui.game3.chrome").stdFrame(1, 15, 28, 4)
    if st.printer then st.printer:draw(8, 120, {font = "native_3", colors = colors(false)}) end
    drawYesNo(st.yesNo)
  end
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function UI.show(opts)
  opts = opts or {}
  assert(Gfx.of("rse/pokeblock"):manifest().assetLayout == "rs", "native RS Pokeblock pack required")
  opts.actions, opts.textAliases, opts.makeYesNo, opts.draw = UI.ACTIONS, UI.TEXT_ALIASES, yesNo, UI.draw
  opts.swap = swap
  return Base.show(opts)
end
function UI.reset() return Base.reset() end
function UI.isOpen() return Base.isOpen() end
function UI.selected() return Base.selected() end
return UI
