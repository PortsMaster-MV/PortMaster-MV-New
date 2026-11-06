local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = { SUB = "wallclock", FILES = {} }
for _, l in ipairs({"start", "view"}) do
  M.FILES[#M.FILES + 1] = l .. "_idx.png"
  for _, g in ipairs({"male", "female"}) do M.FILES[#M.FILES + 1] = l .. "_" .. g .. ".png" end
end
for _, s in ipairs({"minute_hand", "hour_hand", "pm", "am"}) do
  for _, g in ipairs({"male", "female"}) do M.FILES[#M.FILES + 1] = s .. "_" .. g .. ".png" end
end
M.REQUIRED = K.required(M.SUB, M.FILES)
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/wallclock.c:583
  local variants, palettes = {}, {}
  for _, row in ipairs({{"male", "gMiscClockMale_Pal"}, {"female", "gMiscClockFemale_Pal"}}) do
    local p = c:pal(row[2], 16); variants[#variants + 1] = {name = row[1], pal = p}; palettes[row[1]] = K.palList(p, 0, 16)
  end
  local layers = {}
  for _, row in ipairs({{"start", "gUnknown_08E954B0"}, {"view", "gUnknown_08E95774"}}) do
    local idx, w, h = K.bakeText(c:lz("gMiscClock_Gfx"), c:lz(row[2]), 32, 20)
    layers[row[1]] = c:layer({key = row[1], opaque = true, indexMap = true, variants = variants}, idx, w, h)
  end
  local sprites = {}
  for _, row in ipairs({{"minute_hand", "gSpriteTemplate_83F7AD8"}, {"hour_hand", "gSpriteTemplate_83F7AF0"},
    {"pm", "gSpriteTemplate_83F7B28"}, {"am", "gSpriteTemplate_83F7B40"}}) do
    sprites[row[1]] = c:spriteFrames(row[1], c:lz("ClockGfx_Misc"), c:readTemplate(row[2]), K.variants(variants))
  end
  return A.finish(c, {screen = "wallclock", layers = layers, sprites = sprites, palettes = palettes, handCoords = A.pairs(c, "sClockHandCoords", true)})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
