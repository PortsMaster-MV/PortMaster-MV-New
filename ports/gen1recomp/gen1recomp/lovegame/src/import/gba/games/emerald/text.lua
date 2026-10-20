local Placeholders = require("src.import.gba.text_placeholders_extract")

return function(V)
  local S = V.SYMS
  local Text = require("src.import.gba.versions_text_emerald")

  local function offsets(names)
    local out = {}
    for _, name in ipairs(names) do
      if name == "sText_CommunicationStandby" then
        -- pokeemerald/src/data/trade.h:52
        -- pokeemerald/src/berry_blender.c:287
        out[name] = S.off("trade.o:sText_CommunicationStandby")
      else
        out[name] = S.off(name)
      end
    end
    return out
  end

  V.NAMED_TEXTS = offsets(Text.NAMED_TEXTS)
  V.NAMED_TEXTS.sText_CommunicationStandby = S.off("trade.o:sText_CommunicationStandby")
  V.NAMED_BATTLE_TEXTS = offsets(Text.NAMED_BATTLE_TEXTS)

  local tables = {}
  for i, t in ipairs(Text.TEXT_TABLES) do
    tables[i] = {
      name = t.name,
      addr = S.off(t.name),
      count = math.floor(S.size(t.name) / (t.stride * (t.inner or 1))),
      stride = t.stride,
      inner = t.inner,
      battle = t.battle,
      inline = t.inline,
      ids = t.ids,
    }
  end
  V.TEXT_TABLES = tables
  -- pokeemerald/include/constants/battle_string_ids.h:4
  V.BATTLE_STRING_IDS = Text.BATTLE_STRING_IDS

  V.TEXT_PLACEHOLDERS = {}
  for name, sym in pairs(Placeholders.SYMBOLS) do
    V.TEXT_PLACEHOLDERS[name] = S.off(sym)
  end

  -- pokeemerald/src/fonts.c:3
  local fontSyms = {
    small = "gFontSmallLatin", normal = "gFontNormalLatin", short = "gFontShortLatin",
    narrow = "gFontNarrowLatin", small_narrow = "gFontSmallNarrowLatin",
  }
  V.FONT_GLYPH_COUNTS = {}
  V.FONT_WIDTH_SYMBOLS = {}
  for face, stem in pairs(fontSyms) do
    V.FONT_GLYPH_COUNTS[face] = S.count(stem .. "Glyphs", 64)
    V.FONT_WIDTH_SYMBOLS[face] = stem .. "GlyphWidths"
    assert(S.size(stem .. "GlyphWidths") == V.FONT_GLYPH_COUNTS[face], stem .. " widths/glyphs size mismatch")
  end

  -- pokeemerald/src/text_window.c:60
  V.TEXT_WINDOW_FRAMES = S.off("text_window.o:sWindowFrames")
  V.TEXT_WINDOW_FRAME_COUNT = S.count("text_window.o:sWindowFrames", 8)
  V.TEXT_WINDOW_PALETTES = S.off("text_window.o:sTextWindowPalettes")
  V.TEXT_WINDOW_PALETTE_COUNT = S.count("text_window.o:sTextWindowPalettes", 32)
  V.MESSAGE_BOX_GFX = S.off("gMessageBox_Gfx")
  V.MESSAGE_BOX_GFX_BYTES = S.size("gMessageBox_Gfx")
  V.MESSAGE_BOX_PAL = S.off("gMessageBox_Pal")
  V.STD_MENU_PALETTE = S.off("gStandardMenuPalette")
  -- pokeemerald/src/text.c:71
  V.DOWN_ARROW_GFX = S.off("text.o:sDownArrowTiles")
  V.DARK_DOWN_ARROW_GFX = S.off("text.o:sDarkDownArrowTiles")
  V.KEYPAD_ICONS_GFX = S.off("text.o:sKeypadIconTiles")
  V.KEYPAD_ICONS_BYTES = S.size("text.o:sKeypadIconTiles")
  -- pokeemerald/src/braille.c:16
  V.BRAILLE_GFX = S.off("braille.o:sFont_Braille")
  V.BRAILLE_GLYPHS = S.count("braille.o:sFont_Braille", 64)
  -- pokeemerald/src/text.c:237
  V.FONTS_JAPANESE = {
    small = { glyphs = S.off("gFontSmallJapaneseGlyphs"), bytes = S.size("gFontSmallJapaneseGlyphs") },
    normal = { glyphs = S.off("gFontNormalJapaneseGlyphs"), bytes = S.size("gFontNormalJapaneseGlyphs") },
    short = {
      glyphs = S.off("gFontShortJapaneseGlyphs"), bytes = S.size("gFontShortJapaneseGlyphs"),
      widths = S.off("gFontShortJapaneseGlyphWidths"), count = S.size("gFontShortJapaneseGlyphWidths"),
    },
  }
end
