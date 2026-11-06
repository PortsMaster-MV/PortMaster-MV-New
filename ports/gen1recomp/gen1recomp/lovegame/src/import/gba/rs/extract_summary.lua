local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/summary", FILES = {"interface.gfx", "move_types.png", "move_select.png", "status.png", "markings.png",
  "text.png", "buttons.png", "exp.png", "hearts.png"}}
local N = "pokemon_summary_screen.o:"
local maps = {{"common", "gUnknown_08E73508", false, 0xE000}, {"info", "gUnknown_08E74E88", true, 0xE800},
  {"skills", "gStatusScreen_Tilemap", true, 0x4800}, {"battle_moves", "gUnknown_08E73E88", false, 0x5800},
  {"contest_moves", "gUnknown_08E74688", false, 0x6800}}
for _, m in ipairs(maps) do M.FILES[#M.FILES + 1] = m[1] .. ".map"; M.FILES[#M.FILES + 1] = m[1] .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function paletteBank(pal, bank)
  local out = {}; for i = 0, 15 do out[i] = pal[bank * 16 + i] or 0 end; return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "summary", coverage = "native_page_layers_dynamic_tiles_and_sprite_tables", layers = {}, maps = {}, palettes = {}, sprites = {}}
  local gfx, pal = c:lz("gStatusScreen_Gfx"), c:pal("gStatusScreen_Pal", 80, nil, 0, true)
  man.gfx = c:write("interface.gfx", gfx)
  local colors = c:pal("gUnknownPalette_81E6692", 16)
  for _, p in ipairs({{129, 14, 1}, {136, 15, 1}, {143, 14, 1}, {137, 15, 1}, {209, 6, 2}, {211, 10, 2},
    {213, 14, 2}, {215, 6, 2}, {217, 4, 2}, {219, 8, 2}, {221, 2, 1}, {222, 3, 1}, {223, 1, 1}}) do
    for i = 0, p[3] - 1 do pal[p[1] + i] = colors[p[2] + i] end
  end
  c:pal("gFontDefaultPalette", 16, pal, 240); pal[249] = colors[3]
  man.palettes.bg = K.palList(pal, 0, 256)
  man.palettes.portraitBackground = {normal = c:u16(c:off(N .. "sUnknown_083C157C")),
    shiny = c:u16(c:off(N .. "sUnknown_083C157E"))}
  man.noFlip = {}
  local stats = c:off("gBaseStats")
  for species = 0, c.S.count("gBaseStats", 28) - 1 do
    man.noFlip[species] = c:u8(stats + species * 28 + 25) >= 128
  end
  for _, m in ipairs(maps) do
    local map = m[3] and c:lz(m[2]) or c:raw(m[2], 0x800)
    man.maps[m[1]] = {path = c:write(m[1] .. ".map", map), vram = m[4], entries = #map / 2}
    local idx, w, h = K.bakeText(gfx, map, 30, 20)
    man.layers[m[1]] = c:layer({key = m[1], opaque = m[1] == "common"}, idx, w, h, pal)
  end
  man.layers.common.backdrop = pal[0]
  man.nativeBackgrounds = {{id = 0, control = 0x1E08}, {id = 1, control = 0x4801}, {id = 2, control = 0x4A02}, {id = 3, control = 0x5C03}}
  man.pages = {"info", "skills", "battle_moves", "contest_moves"}
  local typeGfx, typePal = c:lz("gMoveTypes_Gfx"), c:pal("gMoveTypes_Pal", 48, nil, nil, true)
  local to, count, frames, banks = c:off(N .. "sMoveTypeToOamPaletteNum"), c.S.size(N .. "sMoveTypeToOamPaletteNum"), {}, {}
  for i = 0, count - 1 do
    local bank = c:u8(to + i) - 13
    assert(bank >= 0 and bank < 3, "native summary type palette bank")
    local px = K.bakeSprite(typeGfx, 32, 16, i * 8, 4)
    for j = 1, #px do if px[j] ~= 0 then px[j] = px[j] + bank * 16 end end
    frames[i + 1], banks[i + 1] = px, bank + 13
  end
  local ti, tw, th = K.stack(frames, 32, 16)
  local tpl = c:readTemplate(N .. "sSpriteTemplate_MoveTypes")
  man.sprites.moveTypes = {png = c:png("move_types.png", tw, th, ti, typePal, true), w = 32, h = 16, frames = count,
    paletteBanks = banks, anims = tpl.anims, priority = tpl.oam.priority, callback = tpl.callback}
  man.palettes.moveTypes = K.palList(typePal, 0, 48)
  man.sprites.moveSelect = c:spriteFrames("move_select", c:lz("gMenuSummaryGfx"), c:readTemplate(N .. "sSpriteTemplate_83C1280"), c:pal("gMenuSummaryPal", 16, nil, nil, true))
  man.sprites.status = c:spriteFrames("status", c:lz("gStatusGfx_Icons"), c:readTemplate(N .. "sSpriteTemplate_StatusCondition"), c:pal("gStatusPal_Icons", 16, nil, nil, true))
  man.sprites.markings = c:strip("markings", c:raw("gUnknown_083E4A14"), 32, 8, 16, c:pal(N .. "sSummaryScreenMonMarkingsPalette", 16))
  man.text = c:strip("text", c:raw(N .. "gSummaryScreenTextTiles", 320), 8, 8, 10, paletteBank(pal, 15))
  man.buttons = c:strip("buttons", c:raw(N .. "sSummaryScreenButtonTiles", 256), 8, 8, 8, paletteBank(pal, 15))
  man.nativeTextTiles, man.nativeButtonTiles = {}, {}
  local textOff, buttonOff = c:off(N .. "gSummaryScreenTextTiles"), c:off(N .. "sSummaryScreenButtonTiles")
  for i = 0, 319 do man.nativeTextTiles[i + 1] = c:u8(textOff + i) end
  for i = 0, 255 do man.nativeButtonTiles[i + 1] = c:u8(buttonOff + i) end
  man.exp = c:strip("exp", gfx, 8, 8, 9, paletteBank(pal, 2), 4, 0x62)
  man.hearts = c:strip("hearts", gfx, 8, 8, 5, paletteBank(pal, 1), 4, 0x39)
  man.textColors, man.headerTexts, man.doubleBattleOrder = {}, {}, {}
  local co = c:off(N .. "sSummaryScreenTextColors")
  for i = 0, c.S.count(N .. "sSummaryScreenTextColors", 4) - 1 do
    local o = co + i * 4; man.textColors[c:u8(o)] = {color = c:u8(o + 1), background = c:u8(o + 2), shadow = c:u8(o + 3)}
  end
  local ho = c:off(N .. "sPageHeaderTexts")
  for i = 0, c.S.count(N .. "sPageHeaderTexts", 4) - 1 do man.headerTexts[i] = A.text(c, assert(c:ptr(ho + i * 4))) end
  local bo = c:off(N .. "sDoubleBattlePartyOrder")
  for i = 0, c.S.size(N .. "sDoubleBattlePartyOrder") - 1 do man.doubleBattleOrder[i + 1] = c:u8(bo + i) end
  local wo, win = c:off("gWindowTemplate_81E6E6C"), {}
  for i, name in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor", "backgroundColor", "shadowColor",
    "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}) do win[name] = c:u8(wo + i - 1) end
  man.nativeWindow = win
  man.geometry = {statusCenter = {64, 152}, typeCenterOffset = {16, 8}, expTiles = {21, 18},
    appealTiles = {6, 15}, jamTiles = {6, 17}, moveNames = {15, 4, 2}, movePp = {26, 4, 2}}
  man.nativeTiles = {textBase = 0x280, buttonBase = 0x28A, expBase = 0x62, expBank = 2,
    appealEmpty = 0x1039, appealFull = 0x103A, jamEmpty = 0x103D, jamFull = 0x103C}
  man.detailRows = {}
  for _, name in ipairs({"gUnknown_08E94510", "gUnknown_08E94550", "gUnknown_08E94590"}) do
    local row, o = {}, c:off(name)
    for i = 0, 19 do row[i + 1] = c:u16(o + i * 2) end
    man.detailRows[#man.detailRows + 1] = row
  end
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
