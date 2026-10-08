local faces = {}
for id = 0, 6 do faces["native_" .. id] = { id = id } end
-- pokeruby/src/text.c:622
faces.normal, faces.small = faces.native_3, faces.native_1
faces.short, faces.narrow, faces.small_narrow = faces.native_0, faces.native_4, faces.native_1

return {
  module = "src.ui.game3.frlg_font",
  faceLoader = "src.ui.game3.rs.font_faces",
  nativeLayout = "rs", faces = faces,
  dir = "data/generated/gba/chrome/fonts/",
  manifest = "data/generated/gba/chrome/native_fonts.lua",
  palette = { file = "data/generated/gba/chrome/font_palette.lua" },
  -- pokeruby/src/text.c:622
  defaultColors = { fg = 1, shadow = 8, bg = 0 },
  npcTextColors = false,
}
