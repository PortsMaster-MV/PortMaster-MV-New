return {
  module = "src.ui.game3.frlg_font",
  widths = "data/generated/gba/chrome/fonts/latin_widths.lua",
  smallWidths = "data/generated/gba/chrome/fonts/latin_small_widths.lua",
  dir = "data/generated/gba/chrome/fonts/",
  metrics = "data/generated/gba/chrome/fonts/metrics.lua",
  -- pokeemerald/include/text.h:12
  faces = {
    normal = { sheet = "latin_normal", widths = "latin_widths.lua", fontId = "FONT_NORMAL" },
    small = { sheet = "latin_small", widths = "latin_small_widths.lua", fontId = "FONT_SMALL" },
    short = { sheet = "latin_short", widths = "latin_short_widths.lua", fontId = "FONT_SHORT" },
    narrow = { sheet = "latin_narrow", widths = "latin_narrow_widths.lua", fontId = "FONT_NARROW" },
    small_narrow = { sheet = "latin_small_narrow", widths = "latin_small_narrow_widths.lua", fontId = "FONT_SMALL_NARROW" },
  },
  japanese = {
    normal = { sheet = "japanese_normal", widths = "japanese_widths.lua" },
    small = { sheet = "japanese_small" },
    short = { sheet = "japanese_short", widths = "japanese_short_widths.lua" },
  },
  -- pokeemerald/src/menu.c:212
  palette = { file = "data/generated/gba/chrome/palettes.lua", key = "message_box" },
  npcTextColors = false,
}
