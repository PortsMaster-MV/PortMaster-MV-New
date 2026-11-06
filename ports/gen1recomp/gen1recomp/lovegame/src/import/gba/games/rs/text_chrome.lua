return function(V)
  local S = V.SYMS
  -- pokeruby/src/text.c:419
  V.RS_FONT_TABLE = S.off("text.o:sFonts")
  V.RS_FONT_COUNT = S.count("text.o:sFonts", 12)
  V.RS_FONT_TYPE1_MAP = { off = S.off("text.o:sFontType1Map"), count = S.count("text.o:sFontType1Map", 2) }
  V.RS_FONT_TYPE3_MAP = { off = S.off("text.o:sFontType3Map"), count = S.count("text.o:sFontType3Map", 2) }
  V.RS_FONT_WIDTHS = {}
  for _, id in ipairs({ 0, 1, 3, 4 }) do
    local name = "text.o:sFont" .. id .. "Widths"
    V.RS_FONT_WIDTHS[id] = { off = S.off(name), count = S.size(name), symbol = name }
  end
  V.RS_FONT_SOURCES = {}
  for _, name in ipairs({
    "text.o:sFont0LatinGlyphs", "text.o:sFont1LatinGlyphs", "text.o:sFont0JapaneseGlyphs",
    "text.o:sFont1JapaneseGlyphs", "text.o:sBrailleGlyphs", "gFont3LatinGlyphs",
    "gFont4LatinGlyphs", "gFont3JapaneseGlyphs", "gFont4JapaneseGlyphs",
  }) do
    V.RS_FONT_SOURCES[S.off(name)] = { bytes = S.size(name), symbol = name }
  end
  -- pokeruby/src/text_window.c:74
  V.TEXT_WINDOW_FRAMES = S.off("text_window.o:sTextWindowFrameGraphics")
  V.TEXT_WINDOW_FRAME_COUNT = S.count("text_window.o:sTextWindowFrameGraphics", 8)
  V.MESSAGE_BOX_GFX = S.off("gDialogueFrame_Gfx")
  V.MESSAGE_BOX_GFX_BYTES = S.size("gDialogueFrame_Gfx")
  V.MESSAGE_BOX_PAL = S.off("gFontDefaultPalette")
  V.DOWN_ARROW_GFX = S.off("text.o:sDownArrowTiles")
  V.DOWN_ARROW_BYTES = S.size("text.o:sDownArrowTiles")
end
