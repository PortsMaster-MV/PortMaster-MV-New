local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "rse/battle_tower_records", FILES = {}, REQUIRED = {"rse/battle_tower_records/manifest.lua"}}
local function sourceText(c, symbol)
  local bytes, off = {}, c:off(symbol)
  for i = 0, 1023 do
    local b = c:u8(off + i); bytes[#bytes + 1] = b
    if b == 255 then
      local IR = require("src.core.game3.scripting.text_ir")
      return IR.toSource(IR.decode(bytes, {dialect = "rs"}), nil, {named = true})
    end
  end
  error("RS Tower records text is unterminated: " .. symbol)
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local win, off = {}, c:off("gMenuTextWindowTemplate")
  for i, key in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}) do
    win[key] = c:u8(off + i - 1)
  end
  local strings = {}
  for key, name in pairs({title = "BattleTowerResults", lv50 = "Lv50", lv100 = "Lv100", streak = "WinStreak",
    current = "Current", record = "Record", previous = "Prev"}) do strings[key] = sourceText(c, "gOtherText_" .. name) end
  -- battle_records.c:367
  return A.finish(c, {screen = "battle_tower_records", strings = strings, window = win,
    palette = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16),
    geometry = {frame = {3, 1, 27, 17}, title = {3, 2, 200}, levels = {{5, 6}, {5, 12}},
      current = {{10, 6}, {10, 12}}, record = {{10, 8}, {10, 14}},
      streakX = 17, numberWidth = 24, divider = {5, 25, 10}, dividerGlyph = 0xAE}})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
