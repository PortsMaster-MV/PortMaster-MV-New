local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "naming"

local N = "naming_screen.o:"

-- pokeemerald/src/naming_screen.c:2558
M.SHEETS = {
  { "back_button", "gNamingScreenBackButton_Gfx", 5, 3, N .. "sSpriteTemplate_BackButton" },
  { "ok_button", "gNamingScreenOKButton_Gfx", 5, 3, N .. "sSpriteTemplate_OkButton" },
  { "page_swap_frame", "gNamingScreenPageSwapFrame_Gfx", 5, 4, N .. "sSpriteTemplate_PageSwapFrame" },
  { "page_swap_upper", "gNamingScreenPageSwapUpper_Gfx", 5, 1, N .. "sSpriteTemplate_PageSwapText" },
  { "page_swap_lower", "gNamingScreenPageSwapLower_Gfx", 5, 1, N .. "sSpriteTemplate_PageSwapText" },
  { "page_swap_others", "gNamingScreenPageSwapOthers_Gfx", 5, 1, N .. "sSpriteTemplate_PageSwapText" },
  { "input_arrow", "gNamingScreenInputArrow_Gfx", 1, 1, N .. "sSpriteTemplate_InputArrow" },
  { "underscore", "gNamingScreenUnderscore_Gfx", 1, 1, N .. "sSpriteTemplate_Underscore" },
  { "pc_icon_off", N .. "sPCIconOff_Gfx", 2, 3, N .. "sSpriteTemplate_PCIcon" },
  { "pc_icon_on", N .. "sPCIconOn_Gfx", 2, 3, N .. "sSpriteTemplate_PCIcon" },
}

-- pokeemerald/src/naming_screen.c:1310
M.PAGE_SWAP_BUTTONS = { "upper", "others", "lower" }

M.GLOW = {
  { "page_swap_button_glow", "gNamingScreenPageSwapFrame_Gfx", 5, 4 },
  { "back_button_glow", "gNamingScreenBackButton_Gfx", 5, 3 },
  { "ok_button_glow", "gNamingScreenOKButton_Gfx", 5, 3 },
}
-- pokeemerald/src/naming_screen.c:981
M.GLOW_INDEX = 14

M.KB = { x = 16, y = 72, w = 176, h = 80 }
M.MAPS = {
  { "bg", "gNamingScreenBackground_Tilemap" },
  { "kb_upper", "gNamingScreenKeyboardUpper_Tilemap" },
  { "kb_lower", "gNamingScreenKeyboardLower_Tilemap" },
  { "kb_symbols", "gNamingScreenKeyboardSymbols_Tilemap" },
}

M.FILES = { "bg.png", "kb_upper.png", "kb_lower.png", "kb_symbols.png", "cursor.png", "page_swap_button.png" }
for _, s in ipairs(M.SHEETS) do M.FILES[#M.FILES + 1] = s[1] .. ".png" end
for _, p in ipairs(M.PAGE_SWAP_BUTTONS) do M.FILES[#M.FILES + 1] = "page_swap_button_" .. p .. ".png" end
for _, g in ipairs(M.GLOW) do M.FILES[#M.FILES + 1] = g[1] .. ".png" end

M.REQUIRED = K.required(M.SUB, M.FILES)

local function text(c, off, max)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local bytes = {}
  for i = 0, (max or 64) - 1 do
    local b = c:u8(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toAscii(TextIR.decode(bytes, { dialect = "rse" }))
end

local function char(c, b)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.toAscii(TextIR.decode({ b, 0xFF }, { dialect = "rse" }))
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local out = function(name) return c:path(name) end

  -- pokeemerald/src/naming_screen.c:1883
  local bgPal = c:pal("gNamingScreenMenu_Pal", 96)
  c:pal(N .. "sKeyboard_Pal", 16, bgPal, 10 * 16)

  local tagPal = {}
  local po = c:off(N .. "sSpritePalettes")
  for i = 0, c.S.size(N .. "sSpritePalettes") / 8 - 1 do
    local p = c:ptr(po + i * 8)
    if not p then break end
    tagPal[c:u16(po + i * 8 + 4)] = c:palAt(p, 16)
  end
  local function palFor(template)
    local tag = c:readTemplate(template).paletteTag
    return assert(tagPal[tag], "naming: no sprite palette for tag " .. tag), tag
  end

  local menuGfx = c:lz("gNamingScreenMenu_Gfx")
  local manifest = { version = 3 }
  for _, m in ipairs(M.MAPS) do
    local idx, W = K.bakeText(menuGfx, c:lz(m[2]), 32, 20)
    if m[1] == "bg" then
      c:png("bg.png", 240, 160, K.crop(idx, W, 0, 0, 240, 160), bgPal, false)
    else
      c:png(m[1] .. ".png", M.KB.w, M.KB.h, K.crop(idx, W, M.KB.x, M.KB.y, M.KB.w, M.KB.h), bgPal, true)
    end
    manifest[m[1]] = out(m[1] .. ".png")
  end

  local sheets = {}
  for _, s in ipairs(M.SHEETS) do
    local pal, tag = palFor(s[5])
    sheets[s[1]] = c:strip(s[1], c:raw(s[2]), s[3] * 8, s[4] * 8, 1, pal)
    sheets[s[1]].paletteTag = tag
    manifest[s[1]] = out(s[1] .. ".png")
  end

  -- pokeemerald/src/naming_screen.c:1324
  local buttonGfx = c:raw("gNamingScreenPageSwapButton_Gfx")
  local pageTags = {}
  local pt = c:off(N .. "sPageSwapPalTags")
  for i, name in ipairs(M.PAGE_SWAP_BUTTONS) do
    local tag = c:u16(pt + (i - 1) * 2)
    pageTags[name] = tag
    c:strip("page_swap_button_" .. name, buttonGfx, 32, 16, 1, tagPal[tag])
    manifest["page_swap_button_" .. name] = out("page_swap_button_" .. name .. ".png")
  end
  c:strip("page_swap_button", buttonGfx, 32, 16, 1, tagPal[pageTags.upper])
  manifest.page_swap_button = out("page_swap_button.png")

  local white = {}
  for i = 0, 15 do white[i] = 0 end
  white[M.GLOW_INDEX] = 0x7FFF
  for _, g in ipairs(M.GLOW) do
    local idx = K.bakeSprite(c:raw(g[2]), g[3] * 8, g[4] * 8, 0, 4)
    for i = 1, #idx do
      if idx[i] ~= M.GLOW_INDEX then idx[i] = 0 end
    end
    c:png(g[1] .. ".png", g[3] * 8, g[4] * 8, idx, white, true)
    manifest[g[1]] = out(g[1] .. ".png")
  end

  local cursorPal = palFor(N .. "sSpriteTemplate_Cursor")
  local frames = {}
  for i, sym in ipairs({ "gNamingScreenCursor_Gfx", "gNamingScreenCursorSquished_Gfx", "gNamingScreenCursorFilled_Gfx" }) do
    frames[i] = K.bakeSprite(c:raw(sym), 16, 16, 0, 4)
  end
  local strip = {}
  for y = 0, 15 do
    for f = 1, 3 do
      for x = 0, 15 do strip[#strip + 1] = frames[f][y * 16 + x + 1] end
    end
  end
  c:png("cursor.png", 48, 16, strip, cursorPal, true)
  manifest.cursor = out("cursor.png")

  -- pokeemerald/src/naming_screen.c:280
  local kc, keyboard = c:off(N .. "sKeyboardChars"), {}
  local pages = c.S.size(N .. "sPageColumnCounts")
  local rows = c.S.size(N .. "sKeyboardChars") / pages / 8
  for p = 0, pages - 1 do
    local page = {}
    for r = 0, rows - 1 do
      local row = {}
      for col = 0, 7 do
        local b = c:u8(kc + (p * rows + r) * 8 + col)
        row[col + 1] = { byte = b, char = char(c, b) }
      end
      page[r + 1] = row
    end
    keyboard[p + 1] = page
  end
  local colCounts, colX = {}, {}
  local cc, cx = c:off(N .. "sPageColumnCounts"), c:off(N .. "sPageColumnXPos")
  for p = 0, pages - 1 do
    colCounts[p + 1] = c:u8(cc + p)
    local xs = {}
    for col = 0, 7 do xs[col + 1] = c:u8(cx + p * 8 + col) end
    colX[p + 1] = xs
  end
  local keyText, kt = {}, c:off(N .. "sNamingScreenKeyboardText")
  for p = 0, pages - 1 do
    local page = {}
    for r = 0, rows - 1 do page[r + 1] = text(c, c:ptr(kt + (p * rows + r) * 4), 32) end
    keyText[p + 1] = page
  end
  local textColors, tc = {}, c:off(N .. "sTextColorStruct")
  for p = 0, pages - 1 do
    textColors[p + 1] = { c:u8(tc + p * 3), c:u8(tc + p * 3 + 1), c:u8(tc + p * 3 + 2) }
  end
  local fill, fo = {}, c:off(N .. "sFillValues")
  for p = 0, pages - 1 do fill[p + 1] = c:u8(fo + p) end

  -- pokeemerald/src/naming_screen.c:2131
  local templates, to = {}, c:off(N .. "sNamingScreenTemplates")
  for i = 0, c.S.size(N .. "sNamingScreenTemplates") / 4 - 1 do
    local t = c:ptr(to + i * 4)
    templates[i + 1] = {
      copyExistingString = c:u8(t), maxChars = c:u8(t + 1), iconFunction = c:u8(t + 2),
      addGenderIcon = c:u8(t + 3), initialPage = c:u8(t + 4), title = text(c, c:ptr(t + 8), 64),
    }
  end

  manifest.kb_x, manifest.kb_y, manifest.kb_w, manifest.kb_h = M.KB.x, M.KB.y, M.KB.w, M.KB.h
  manifest.sheets = sheets
  manifest.pageSwapPalTags = pageTags
  manifest.keyboard = {
    chars = keyboard, columnCounts = colCounts, columnX = colX, text = keyText,
    textColors = textColors, fill = fill,
  }
  manifest.templates = templates
  -- pokeemerald/src/naming_screen.c:1425
  manifest.waldaDadIcon = { graphics = "OBJ_EVENT_GFX_MAN_1", x = 56, y = 37, anim = "ANIM_STD_GO_SOUTH" }
  manifest.palettes = {
    menu = K.palList(bgPal, 0, 96),
    keyboard = K.palList(bgPal, 160, 16),
  }
  return true, c:finish(manifest)
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
