local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokenav_ribbons", FILES = {"bg.png"}}
for i = 0, 31 do M.FILES[#M.FILES + 1] = "small_" .. i .. ".png"; M.FILES[#M.FILES + 1] = "large_" .. i .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function mapWords(raw)
  local out = {}; for i = 1, #raw, 2 do out[#out + 1] = raw:byte(i) + raw:byte(i + 1) * 256 end; return out
end
local function encode(words)
  local out = {}; for _, w in ipairs(words) do out[#out + 1] = string.char(w % 256, math.floor(w / 256)) end; return table.concat(out)
end
local function mirrored(gfx, width, height, tile)
  local half, out = K.bakeSprite(gfx, width, height, tile, 4), K.blank(width * 2, height)
  for y = 0, height - 1 do for x = 0, width - 1 do
    local v = half[y * width + x + 1]
    out[y * width * 2 + x + 1], out[y * width * 2 + width * 2 - x] = v, v
  end end
  return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokenav_ribbons", layers = {}, palettes = {}, icons = {}, descriptions = {}, giftDescriptions = {}, strings = {}}
  local gfx, half, map = c:lz("gPokenavRibbonView_Gfx"), c:lz("gUnknown_083E040C"), c:lz("gUnknown_08E9FBA0")
  assert(#gfx <= 0x200, "native ribbons base tiles fit preceding half-icon region")
  gfx = gfx .. string.rep("\0", 0x200 - #gfx) .. half
  local words = mapWords(map)
  for y = 0, 7 do for x = 0, 17 do words[0x8B + y * 32 + x + 1] = 0x2000 end end
  local pal, base = {}, c:pal("gPokenavRibbonView_Pal", 16)
  for i = 0, 15 do pal[32 + i] = base[i] end
  c:pal("gUnknown_083E03A8", 16, pal, 240)
  c:pal("gUnknown_083E3C60", 80, pal, 48)
  c:pal("gUnknownPalette_81E6692", 16, pal, 176)
  pal[0], pal[191] = base[14], pal[255]
  man.palettes.background = K.palList(pal, 0, 256)
  local idx, w, h = K.bakeText(gfx, encode(words), 30, 20)
  man.layers.bg = c:layer({key = "bg"}, idx, w, h, pal)
  local full, io, po = c:lz("gUnknown_083E3D00"), c:off("gPokenavRibbonsIconGfx"), c:off("gUnknown_083E3C60")
  for i = 0, 31 do
    local tile, bank = c:u16(io + i * 4), c:u16(io + i * 4 + 2)
    assert(tile < 12 and bank < 5, "native ribbon icon descriptor")
    local ip = {}; for j = 0, 15 do ip[j] = c:u16(po + bank * 32 + j * 2) end
    man.icons[i] = {tile = tile, palette = bank, small = c:png("small_" .. i .. ".png", 16, 16, mirrored(half, 8, 16, tile * 2), ip, true),
      large = c:png("large_" .. i .. ".png", 32, 32, mirrored(full, 16, 32, tile * 8), ip, true)}
  end
  for _, row in ipairs({{"gRibbonDescriptions", man.descriptions}, {"gGiftRibbonDescriptions", man.giftDescriptions}}) do
    local off = c:off(row[1])
    for i = 0, c.S.count(row[1], 8) - 1 do row[2][i] = {A.text(c, assert(c:ptr(off + i * 8))), A.text(c, assert(c:ptr(off + i * 8 + 4)))} end
  end
  man.fields = {}
  local fo = c:off("gUnknown_083E499C")
  for i, name in ipairs({"champion", "cool", "beauty", "cute", "smart", "tough", "winning", "victory", "artist", "effort", "marine", "land", "sky", "country", "national", "earth", "world"}) do
    man.fields[i] = {name = name, monData = c:u16(fo + (i - 1) * 2), bits = (i >= 2 and i <= 6) and 3 or 1,
      count = (i >= 2 and i <= 6) and 4 or 1}
  end
  man.giftDescriptionBug = {saveBlock1Offset = 0x30F7, addedRibbonId = true, source = "sub_80F1494"}
  man.strings.Ribbons = A.text(c, c:off("gOtherText_Ribbons"))
  man.geometry = {grid = {88, 32, 9, 16, 16}, portraitCenter = {38, 104}, descriptions = {96, 104, 120, 128},
    position = {8, 40}, name = {104, 8}, cursorScale = {128, 32, 4}}
  local fields = {"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor", "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}
  local wo = c:off("gWindowTemplate_81E70B8"); man.window = {}
  for i, name in ipairs(fields) do man.window[name] = c:u8(wo + i - 1) end
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
