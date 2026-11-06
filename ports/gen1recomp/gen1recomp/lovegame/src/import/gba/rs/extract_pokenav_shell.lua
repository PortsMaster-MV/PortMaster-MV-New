local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokenav_shell", FILES = {"header.png", "spin.png", "dots_base.png", "dots_1.png", "dots_2.png", "list_cursor.png", "list_arrows.png"}}
for i = 0, 11 do M.FILES[#M.FILES + 1] = "help_" .. i .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
local fields = {"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor", "backgroundColor", "shadowColor",
  "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}
local function trunc(v) return v >= 0 and math.floor(v) or math.ceil(v) end
-- pokeruby/src/pokenav.c:466
local function gradient(a, b, out, start)
  for channel = 0, 1 do
    local first, last = a[channel + 1], b[channel + 1]
    local r, g, bl = first % 32 * 256, math.floor(first / 32) % 32 * 256, math.floor(first / 1024) % 32 * 256
    local rr, gg, bb = last % 32 * 256, math.floor(last / 32) % 32 * 256, math.floor(last / 1024) % 32 * 256
    local dr, dg, db = trunc((rr - r) / 16), trunc((gg - g) / 16), trunc((bb - bl) / 16)
    for frame = 0, 15 do
      out[start + frame * 2 + channel + 1] = frame == 15 and last or (math.floor(r / 256) + math.floor(g / 256) * 32 + math.floor(bl / 256) * 1024)
      r, g, bl = r + dr, g + dg, bl + db
    end
  end
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokenav_shell", layers = {}, sprites = {}, windows = {}, palettes = {}, help = {}, landmarks = {}}
  local gfx, map = c:lz("gPokenavHoennMapMisc_Gfx"), c:lz("gUnknown_08E99FB0")
  local pal = c:pal("gPokenavHoennMap1_Pal", 16, {}, 16)
  local idx, w, h = K.bakeText(gfx, map, 32, 32)
  man.layers.header = c:layer({key = "header"}, idx, w, h, pal)
  man.palettes.header = K.palList(pal, 16, 16)
  local patch = c:raw("gUnknown_08E9A100")
  local function copy(dst, dx, sx, sy, width)
    for y = 0, 1 do for x = 0, width - 1 do
      local from, to = ((sy + y) * 32 + sx + x) * 2, (y * 17 + dx + x) * 2
      dst[to + 1], dst[to + 2] = patch:sub(from + 1, from + 1), patch:sub(from + 2, from + 2)
    end end
  end
  for mode = 0, 11 do
    local dst = {}; copy(dst, 0, 0, 0, 17)
    if mode == 0 then copy(dst, 0, 17, 0, 10); copy(dst, 10, 0, 6, 7)
    elseif mode == 2 then copy(dst, 0, 10, 2, 10); copy(dst, 10, 0, 6, 7)
    elseif mode == 3 then copy(dst, 0, 0, 4, 10); copy(dst, 10, 0, 6, 7)
    elseif mode == 4 then copy(dst, 0, 20, 2, 10); copy(dst, 10, 0, 6, 7)
    elseif mode == 7 or mode == 8 then copy(dst, 0, mode == 7 and 10 or 20, 4, 10); copy(dst, 7, 0, 6, 7)
    elseif mode == 5 or mode == 9 then copy(dst, 0, 0, 2, 10); copy(dst, 8, 0, 6, 7)
    elseif mode == 10 or mode == 11 then copy(dst, 8, 0, 6, 7) end
    local pixels, pw, ph = K.bakeText(gfx, table.concat(dst), 17, 2, {linear = true, mapWidth = 17})
    man.help[mode] = {png = c:png("help_" .. mode .. ".png", pw, ph, pixels, pal, true), w = pw, h = ph}
  end
  man.sprites.spin = c:spriteFrames("spin", c:lz("gUnknown_083E329C"), c:readTemplate("gSpriteTemplate_83E4850"), c:pal("gPokenavIconPalette", 16))
  local arrows = c:pal("gUnknown_08E9F988", 16)
  man.sprites.listCursor = c:spriteFrames("list_cursor", c:raw("gPokenavArrow_Gfx"), c:readTemplate("gSpriteTemplate_83E45B8"), arrows)
  man.sprites.listArrows = c:spriteFrames("list_arrows", c:raw("gPokenavUpDownArrows_Gfx"), c:readTemplate("gSpriteTemplate_83E45F0"), arrows)
  man.palettes.detailHeading = K.palList(c:pal("Palette_3E42D8", 16), 0, 16)
  for _, row in ipairs({{"message", "gWindowTemplate_81E7224"}, {"list", "gWindowTemplate_81E70D4"}, {"detail", "gWindowTemplate_81E710C"}}) do
    local off, win = c:off(row[2]), {}
    for i, field in ipairs(fields) do win[field] = c:u8(off + i - 1) end
    man.windows[row[1]] = win
  end
  local dots = c:pal("gUnknown_083E003C", 16, {}, 48)
  local di, dw, dh = K.bakeText(c:raw("gUnknown_083E005C"), c:lz("gUnknown_083E007C"), 32, 32)
  local base, masks = {}, {{}, {}}
  for i, value in ipairs(di) do
    base[i] = (value == 49 or value == 50) and 0 or value
    masks[1][i], masks[2][i] = value == 49 and 1 or 0, value == 50 and 1 or 0
  end
  man.layers.dotsBase = c:layer({key = "dots_base"}, base, dw, dh, dots)
  man.layers.dots1 = {png = c:png("dots_1.png", dw, dh, masks[1], {[0] = 0, [1] = 0x7FFF}, true), w = dw, h = dh}
  man.layers.dots2 = {png = c:png("dots_2.png", dw, dh, masks[2], {[0] = 0, [1] = 0x7FFF}, true), w = dw, h = dh}
  man.dotsGradient = {}
  gradient({dots[49], dots[50]}, {dots[51], dots[52]}, man.dotsGradient, 0)
  gradient({dots[51], dots[52]}, {dots[55], dots[56]}, man.dotsGradient, 30)
  man.palettes.dots = K.palList(dots, 48, 16)
  local lo = c:off("landmark.o:gLandmarkLists")
  for i = 0, c.S.count("landmark.o:gLandmarkLists", 8) - 1 do
    local off, entries = lo + i * 8, {}
    local ptr = c:ptr(off + 4)
    if ptr then
      for j = 0, 15 do
        local entry = c:ptr(ptr + j * 4)
        if not entry then break end
        entries[#entries + 1] = {name = A.text(c, assert(c:ptr(entry))), flag = c:u16(entry + 4)}
      end
    end
    man.landmarks[#man.landmarks + 1] = {mapSec = c:u8(off), id = c:u8(off + 1), landmarks = entries}
  end
  man.geometry = {spinCenter = {218, 14}, headerScrollStep = 2, helpTiles = {0, 22, 17, 2}, infoFrame = {13, 3, 29, 17},
    infoName = {14, 4}, cityView = {16, 6}, mapHeaderCenters = {{152, 49}, {216, 49}}}
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
