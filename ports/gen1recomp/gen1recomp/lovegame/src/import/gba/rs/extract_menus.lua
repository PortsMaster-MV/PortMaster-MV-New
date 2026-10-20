local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/menus", FILES = {}}
M.REQUIRED = K.required(M.SUB, M.FILES)
local function actions(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 8) - 1 do
    local p = assert(c:ptr(off + i * 8))
    out[i + 1] = {text = A.text(c, p), textOffset = p, callback = c.S.funcAt(c:u32(off + i * 8 + 4))}
  end
  return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local wo, win = c:off("gWindowTemplate_81E71B4"), {}
  for i, name in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}) do win[name] = c:u8(wo + i - 1) end
  local menu, fieldMoves = actions(c, "pokemon_menu.o:sPokemonMenuActions"), {}
  local fo = c:off("pokemon_menu.o:sPokeMenuFieldMoves")
  for i = 0, c.S.count("pokemon_menu.o:sPokeMenuFieldMoves", 2) - 1 do
    local move = c:u16(fo + i * 2)
    if move == 255 then break end
    fieldMoves[#fieldMoves + 1] = move
  end
  local cursorOptions = {}
  for i, a in ipairs(menu) do cursorOptions[i] = a.text end
  local rows = {}
  -- option_menu.c:176
  for i, row in ipairs({{"TextSpeed", {"Slow", "Mid", "Fast"}, {120, 155, 184}},
    {"BattleScene", {"On", "Off"}, {120, 190}}, {"BattleStyle", {"Shift", "Set"}, {120, 190}},
    {"Sound", {"Mono", "Stereo"}, {120, 172}}, {"ButtonMode", {"Normal", "LR", "LA"}, {120, 166, 188}},
    {"Frame", {}, {}}, {"Cancel", {}, {}}}) do
    local choices = {}
    for j, key in ipairs(row[2]) do choices[j] = {text = A.text(c, c:off("gSystemText_" .. key)), x = row[3][j]} end
    rows[i] = {text = A.text(c, c:off("gSystemText_" .. row[1])), x = 32, y = 40 + (i - 1) * 16, choices = choices}
  end
  return A.finish(c, {screen = "menus", option = {title = A.text(c, c:off("gSystemText_OptionMenu")),
    textPalette = K.palList(c:pal("gUnknown_0839F5FC", 32), 0, 32), paletteBase = 128, nativeWindow = win,
    rows = rows, frameCount = 20, selectedStyle = 8, inactiveStyle = 15, titleX = 32, titleY = 8,
    titleFrame = {16, 0, 216, 24}, listFrame = {16, 32, 216, 152}, highlight = {left = 24, right = 215, top = 40, rowHeight = 16},
    frameLabel = A.text(c, c:off("gSystemText_Type")), frameLabelX = 120, frameNumberX = 144, frameY = 120},
    start = {actions = actions(c, "start_menu.o:sStartMenuItems")},
    party = {cursorOptions = cursorOptions, actions = menu, fieldMoves = fieldMoves}})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
