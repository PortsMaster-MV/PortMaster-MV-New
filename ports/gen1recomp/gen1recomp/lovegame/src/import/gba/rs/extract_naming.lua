local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local IR = require("src.core.game3.scripting.text_ir")
local M = {SUB = "naming"}
local N = "naming_screen.o:"
-- pokeruby/src/naming_screen.c:2087
local sheets = {
  {"back_button", "gNamingScreenBackButtonTiles", 40, 24, "gSpriteTemplate_83CE610"},
  {"ok_button", "gNamingScreenOKButtonTiles", 40, 24, "gSpriteTemplate_83CE628"},
  {"page_swap_frame", "gNamingScreenChangeKeyboardBoxTiles", 40, 32, "gSpriteTemplate_83CE5C8"},
  {"page_swap_lower", "gNamingScreenLowerTextTiles", 24, 8, "gSpriteTemplate_83CE5F8"},
  {"page_swap_upper", "gNamingScreenUpperTextTiles", 24, 8, "gSpriteTemplate_83CE5F8"},
  {"page_swap_others", "gNamingScreenOthersTextTiles", 24, 8, "gSpriteTemplate_83CE5F8"},
  {"input_arrow", "gNamingScreenRightPointingTriangleTiles", 8, 8, "gSpriteTemplate_83CE658"},
  {"underscore", "gNamingScreenUnderscoreTiles", 8, 8, "gSpriteTemplate_83CE670"},
  {"pc_icon_off", "gSpriteImage_83CE094", 16, 24, "gSpriteTemplate_83CE688"},
  {"pc_icon_on", "gSpriteImage_83CE154", 16, 24, "gSpriteTemplate_83CE688"},
}
M.FILES = {"bg.png", "kb_upper.png", "kb_lower.png", "kb_symbols.png", "cursor.png", "cursor_base.png", "cursor_glow.png", "page_swap_button.png"}
for _, s in ipairs(sheets) do M.FILES[#M.FILES + 1] = s[1] .. ".png" end
for _, p in ipairs({"upper", "lower", "others"}) do M.FILES[#M.FILES + 1] = "page_swap_button_" .. p .. ".png" end
for _, g in ipairs({"page_swap_button", "back_button", "ok_button"}) do M.FILES[#M.FILES + 1] = g .. "_glow.png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function character(b)
  return IR.toAscii(IR.decode({b, 255}, {dialect = "rs"}))
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local pal = c:pal("gNamingScreenPalettes", 96)
  local tagPal, po = {}, c:off("gUnknown_083CE708")
  for i = 0, c.S.count("gUnknown_083CE708", 8) - 1 do
    local ptr = c:ptr(po + i * 8)
    if not ptr then break end
    tagPal[c:u16(po + i * 8 + 4)] = c:palAt(ptr, 16)
  end
  local manifest = {version = 3, screen = "naming", sheets = {}, spriteTemplates = {}}
  local gfx = c:raw("gNamingScreenMenu_Gfx", 0x800)
  for _, map in ipairs({{"bg", "gUnknown_08E86258", 32}, {"kb_upper", "gUnknown_083CEBF8", 30},
    {"kb_lower", "gUnknown_083CE748", 30}, {"kb_symbols", "gUnknown_083CF0A8", 30}}) do
    local idx, w = K.bakeText(gfx, c:raw(map[2]), 30, 20, {linear = true, mapWidth = map[3]})
    if map[1] == "bg" then
      manifest.bg = c:png("bg.png", 240, 160, idx, pal, false)
    else
      manifest[map[1]] = c:png(map[1] .. ".png", 176, 80, K.crop(idx, w, 16, 72, 176, 80), pal, true)
    end
  end
  for _, s in ipairs(sheets) do
    local tpl = c:readTemplate(s[5])
    local sp = assert(tagPal[tpl.paletteTag], "RS naming palette absent")
    local sheet = c:strip(s[1], c:raw(s[2]), s[3], s[4], 1, sp)
    sheet.paletteTag, sheet.tileTag = tpl.paletteTag, tpl.tileTag
    manifest.sheets[s[1]], manifest[s[1]], manifest.spriteTemplates[s[1]] = sheet, sheet.png, tpl
  end
  local pt, tt = c:off(N .. "gUnknown_083CE2C4"), c:off(N .. "gUnknown_083CE2CA")
  manifest.pageSwapPalTags, manifest.pageSwapTextTags = {}, {}
  for i, p in ipairs({"lower", "others", "upper"}) do
    local tag = c:u16(pt + (i - 1) * 2)
    manifest.pageSwapPalTags[p] = tag
    manifest.pageSwapTextTags[i] = c:u16(tt + (i - 1) * 2)
    local sh = c:strip("page_swap_button_" .. p, c:raw("gNamingScreenChangeKeyboardButtonTiles"), 32, 16, 1, tagPal[tag])
    manifest["page_swap_button_" .. p] = sh.png
  end
  manifest.page_swap_button = c:strip("page_swap_button", c:raw("gNamingScreenChangeKeyboardButtonTiles"), 32, 16, 1, tagPal[1]).png
  manifest.glow = {}
  for _, g in ipairs({{"page_swap_button", "gNamingScreenChangeKeyboardBoxTiles", 40, 32, 14},
    {"back_button", "gNamingScreenBackButtonTiles", 40, 24, 12}, {"ok_button", "gNamingScreenOKButtonTiles", 40, 24, 14}}) do
    local key = g[1] .. "_glow"
    manifest[key] = c:mask(key .. ".png", g[3], g[4], K.bakeSprite(c:raw(g[2]), g[3], g[4], 0, 4), {[g[5]] = true})
    manifest.glow[g[1]] = {paletteIndex = g[5], stepFrames = 2, amplitude = 16}
  end
  local strip = {}
  local frames = {}
  for i, n in ipairs({"gNamingScreenCursorTiles", "gNamingScreenActiveCursorSmallTiles", "gNamingScreenActiveCursorBigTiles"}) do
    frames[i] = K.bakeSprite(c:raw(n), 16, 16, 0, 4)
  end
  for y = 0, 15 do for f = 1, 3 do for x = 0, 15 do strip[#strip + 1] = frames[f][y * 16 + x + 1] end end end
  manifest.cursor = c:png("cursor.png", 48, 16, strip, tagPal[5], true)
  local base = {}
  for i, v in ipairs(strip) do base[i] = v == 1 and 0 or v end
  manifest.cursor_base = c:png("cursor_base.png", 48, 16, base, tagPal[5], true)
  manifest.cursor_glow = c:mask("cursor_glow.png", 48, 16, strip, {[1] = true})
  manifest.spriteTemplates.cursor = c:readTemplate("gSpriteTemplate_83CE640")
  local kc, kp = c:off(N .. "sKeyboardCharacters"), c:off(N .. "sKeyboardSymbolPositions")
  local kb = {chars = {}, columnCounts = {8, 8, 6}, columnX = {}, text = {}, bytes = {}, symbolPositions = {},
    pageOrder = {"UPPER", "LOWER", "OTHERS"}, buttonColumn = 8, textX = 24, textY = 72, rowHeight = 16,
    cursorOriginX = 27, cursorOriginY = 80}
  for p = 0, 2 do
    local chars, xs, positions, texts, raw = {}, {}, {}, {}, {}
    for col = 0, 8 do
      local pos = c:u8(kp + p * 9 + col)
      positions[col + 1] = pos
      if col < kb.columnCounts[p + 1] then xs[col + 1] = pos * 8 + 24 end
    end
    for row = 0, 3 do
      local off, bytes, cells = kc + (p * 4 + row) * 20, {}, {}
      for b = 0, 19 do bytes[b + 1] = c:u8(off + b) end
      raw[row + 1], texts[row + 1] = bytes, A.text(c, off)
      for col = 1, kb.columnCounts[p + 1] do
        local b = bytes[positions[col] + 1]
        cells[col] = {byte = b, char = character(b)}
      end
      chars[row + 1] = cells
    end
    kb.chars[p + 1], kb.columnX[p + 1], kb.symbolPositions[p + 1], kb.text[p + 1], kb.bytes[p + 1] = chars, xs, positions, texts, raw
  end
  local templates, to = {}, c:off(N .. "sNamingScreenTemplates")
  for i = 0, c.S.count(N .. "sNamingScreenTemplates", 4) - 1 do
    local t = assert(c:ptr(to + i * 4))
    templates[i + 1] = {copyExistingString = c:u8(t), maxChars = c:u8(t + 1), iconFunction = c:u8(t + 2),
      addGenderIcon = c:u8(t + 3), initialPage = c:u8(t + 4), title = A.text(c, assert(c:ptr(t + 8)))}
  end
  manifest.keyboard, manifest.templates = kb, templates
  manifest.kb_x, manifest.kb_y, manifest.kb_w, manifest.kb_h = 16, 72, 176, 80
  manifest.geometry = {pageFrameX = 184, pageFrameY = 64, pageButtonX = 188, pageButtonY = 67,
    pageTextX = 192, pageTextY = 72, backX = 184, backY = 96, okX = 184, okY = 120,
    titleX = 72, titleY = 16, inputY = 32, inputArrowY = 40, underscoreY = 44}
  manifest.palettes = {menu = K.palList(pal, 0, 64), sprites = {}}
  for tag, sp in pairs(tagPal) do manifest.palettes.sprites[tag] = K.palList(sp, 0, 16) end
  return A.finish(c, manifest)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
