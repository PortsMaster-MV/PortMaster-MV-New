local RseTextChrome = {}

RseTextChrome.CACHE_SUB = "chrome"
RseTextChrome.FORMAT_VERSION = 1
RseTextChrome.SHEET_COLS = 16

RseTextChrome.LATIN = { "normal", "small", "short", "narrow", "small_narrow" }

RseTextChrome.WIDTH_FILES = {
  normal = "latin_widths.lua",
  small = "latin_small_widths.lua",
  short = "latin_short_widths.lua",
  narrow = "latin_narrow_widths.lua",
  small_narrow = "latin_small_narrow_widths.lua",
}

local function versions()
  return require("src.import.gba.versions")
end

local ON = "\255\255\255\255"
local OFF = "\0\0\0\0"

local function tile2bpp(rom, off, x, y)
  local byte = rom:get(off + y * 2 + (1 - math.floor(x / 4)))
  return math.floor(byte / (2 ^ ((3 - (x % 4)) * 2))) % 4
end

-- pokeemerald/src/text.c:526
local function glyph_sheet(rom, count, tilesOf)
  local cols = RseTextChrome.SHEET_COLS
  local w = cols * 16
  local h = math.floor((count + cols - 1) / cols) * 16
  local fg, sh = {}, {}
  for i = 1, w * h do
    fg[i] = OFF
    sh[i] = OFF
  end
  for gid = 0, count - 1 do
    local ox = (gid % cols) * 16
    local oy = math.floor(gid / cols) * 16
    for _, t in ipairs(tilesOf(gid)) do
      for y = 0, 7 do
        for x = 0, 7 do
          local v = tile2bpp(rom, t[1], x, y)
          local pi = (oy + t[3] + y) * w + ox + t[2] + x + 1
          if v == 1 then fg[pi] = ON elseif v == 2 then sh[pi] = ON end
        end
      end
    end
  end
  return { fgRgba = table.concat(fg), shRgba = table.concat(sh), width = w, height = h, glyphs = count }
end

local function read_bytes(rom, off, n)
  local out = {}
  for i = 0, n - 1 do out[i] = rom:get(off + i) end
  return out
end

-- pokeemerald/src/text.c:1853
function RseTextChrome.extractLatin(rom, face)
  local V = versions()
  local spec = assert(V.FONTS and V.FONTS[face], "Versions.FONTS." .. tostring(face) .. " is missing")
  local count = assert(V.FONT_GLYPH_COUNTS[face], "Versions.FONT_GLYPH_COUNTS." .. face .. " is missing")
  local base = spec.glyphs
  local sheet = glyph_sheet(rom, count, function(gid)
    local g = base + gid * 64
    return { { g, 0, 0 }, { g + 16, 8, 0 }, { g + 32, 0, 8 }, { g + 48, 8, 8 } }
  end)
  sheet.widths = read_bytes(rom, spec.widths, count)
  return sheet
end

-- pokeemerald/src/text.c:1859
function RseTextChrome.extractJapaneseNormal(rom)
  local spec = versions().FONTS_JAPANESE.normal
  local count = spec.bytes / 0x200 * 16
  local sheet = glyph_sheet(rom, count, function(gid)
    local g = spec.glyphs + 0x200 * math.floor(gid / 16) + 0x10 * (gid % 16)
    return { { g, 0, 0 }, { g + 0x100, 0, 8 } }
  end)
  -- pokeemerald/src/text.c:1887
  local widths = {}
  for gid = 0, count - 1 do widths[gid] = 8 end
  sheet.widths = widths
  return sheet
end

-- pokeemerald/src/text.c:1683
function RseTextChrome.extractJapaneseSmall(rom)
  local spec = versions().FONTS_JAPANESE.small
  local count = spec.bytes / 0x200 * 16
  return glyph_sheet(rom, count, function(gid)
    local g = spec.glyphs + 0x200 * math.floor(gid / 16) + 0x10 * (gid % 16)
    return { { g, 0, 0 }, { g + 0x100, 0, 8 } }
  end)
end

-- pokeemerald/src/text.c:1809
function RseTextChrome.extractJapaneseShort(rom)
  local spec = versions().FONTS_JAPANESE.short
  local count = spec.bytes / 0x200 * 8
  local sheet = glyph_sheet(rom, count, function(gid)
    local g = spec.glyphs + 0x200 * math.floor(gid / 8) + 0x20 * (gid % 8)
    return { { g, 0, 0 }, { g + 0x10, 8, 0 }, { g + 0x100, 0, 8 }, { g + 0x110, 8, 8 } }
  end)
  sheet.widths = read_bytes(rom, spec.widths, spec.count)
  return sheet
end

-- pokeemerald/src/braille.c:198
function RseTextChrome.extractBraille(rom)
  local V = versions()
  local base = V.BRAILLE_GFX
  local sheet = glyph_sheet(rom, V.BRAILLE_GLYPHS, function(gid)
    local g = base + 0x200 * math.floor(gid / 8) + 0x20 * (gid % 8)
    return { { g, 0, 0 }, { g + 0x10, 8, 0 }, { g + 0x100, 0, 8 }, { g + 0x110, 8, 8 } }
  end)
  sheet.cols = RseTextChrome.SHEET_COLS
  sheet.rows = sheet.height / 16
  return sheet
end

local function bgr555(c)
  local function c5(n) return math.floor((n % 32) * 255 / 31 + 0.5) end
  return { c5(c), c5(math.floor(c / 32)), c5(math.floor(c / 1024)) }
end

function RseTextChrome.readPalette(rom, off)
  local pal = {}
  for i = 0, 15 do pal[i] = bgr555(rom:u16(off + i * 2)) end
  return pal
end

function RseTextChrome.decode4bpp(rom, off, tilesW, tilesH, pal)
  local w, h = tilesW * 8, tilesH * 8
  local px = {}
  for ty = 0, tilesH - 1 do
    for tx = 0, tilesW - 1 do
      local t = off + (ty * tilesW + tx) * 32
      for y = 0, 7 do
        for bx = 0, 3 do
          local byte = rom:get(t + y * 4 + bx)
          local row = (ty * 8 + y) * w + tx * 8 + bx * 2 + 1
          for k = 0, 1 do
            local idx = k == 0 and byte % 16 or math.floor(byte / 16)
            local c = pal[idx]
            px[row + k] = (idx == 0 or not c) and OFF or string.char(c[1], c[2], c[3], 255)
          end
        end
      end
    end
  end
  return { rgba = table.concat(px), width = w, height = h }
end

function RseTextChrome.decode4bppIndices(rom, off, tilesW, tilesH)
  local w, h = tilesW * 8, tilesH * 8
  local px = {}
  for ty = 0, tilesH - 1 do
    for tx = 0, tilesW - 1 do
      local t = off + (ty * tilesW + tx) * 32
      for y = 0, 7 do
        for bx = 0, 3 do
          local byte = rom:get(t + y * 4 + bx)
          local row = (ty * 8 + y) * w + tx * 8 + bx * 2 + 1
          px[row] = string.char(byte % 16)
          px[row + 1] = string.char(math.floor(byte / 16))
        end
      end
    end
  end
  return { idx = table.concat(px), width = w, height = h }
end

-- pokeemerald/src/text_window.c:104
function RseTextChrome.extractUserFrame(rom, frameType)
  local V = versions()
  local entry = V.TEXT_WINDOW_FRAMES + frameType * 8
  local tiles = assert(rom:ptrOffset(rom:u32(entry)), "window frame tiles pointer")
  local pal = RseTextChrome.readPalette(rom, assert(rom:ptrOffset(rom:u32(entry + 4)), "window frame pal pointer"))
  local out = RseTextChrome.decode4bpp(rom, tiles, 3, 3, pal)
  out.palette = pal
  return out
end

-- pokeemerald/src/text_window.c:93
function RseTextChrome.extractMessageBox(rom)
  local V = versions()
  local pal = RseTextChrome.readPalette(rom, V.MESSAGE_BOX_PAL)
  local tiles = V.MESSAGE_BOX_GFX_BYTES / 32
  local out = RseTextChrome.decode4bpp(rom, V.MESSAGE_BOX_GFX, tiles / 2, 2, pal)
  out.palette = pal
  out.tiles = tiles
  return out
end

-- pokeemerald/src/text.c:812
function RseTextChrome.extractDownArrow(rom, dark)
  local V = versions()
  local off = dark and V.DARK_DOWN_ARROW_GFX or V.DOWN_ARROW_GFX
  local out = RseTextChrome.decode4bpp(rom, off, 1, 6, RseTextChrome.readPalette(rom, V.MESSAGE_BOX_PAL))
  out.idx = RseTextChrome.decode4bppIndices(rom, off, 1, 6).idx
  return out
end

-- pokeemerald/src/text.c:1613
function RseTextChrome.extractKeypadIcons(rom)
  local V = versions()
  local pal = RseTextChrome.readPalette(rom, V.STD_MENU_PALETTE)
  return RseTextChrome.decode4bpp(rom, V.KEYPAD_ICONS_GFX, 16, V.KEYPAD_ICONS_BYTES / 32 / 16, pal)
end

-- pokeemerald/src/text.c:119
function RseTextChrome.extractFontMetrics(rom)
  local V = versions()
  local S = V.SYMS
  local base = S.off("text.o:sFontInfos")
  local n = S.count("text.o:sFontInfos", 12)
  local names = require("src.core.game3.scripting.text_ir").DIALECTS.rse.FONT_IDS
  local out = {}
  for id = 0, n - 1 do
    local o = base + id * 12
    local b8, b9 = rom:get(o + 8), rom:get(o + 9)
    out[id] = {
      name = names[id],
      maxLetterWidth = rom:get(o + 4),
      maxLetterHeight = rom:get(o + 5),
      letterSpacing = rom:get(o + 6),
      lineSpacing = rom:get(o + 7),
      fgColor = math.floor(b8 / 16),
      bgColor = b9 % 16,
      shadowColor = math.floor(b9 / 16),
    }
  end
  return out
end

local function widths_lua(widths, source)
  local lines = { "-- " .. source, "return {" }
  local maxKey = 0
  for k in pairs(widths) do if k > maxKey then maxKey = k end end
  for i = 0, maxKey do
    lines[#lines + 1] = string.format("  [%d] = %d%s", i, widths[i] or 0, i < maxKey and "," or "")
  end
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

local function pal_lua(pal)
  local parts = {}
  for i = 0, 15 do
    parts[#parts + 1] = string.format("[%d] = { %d, %d, %d }", i, pal[i][1], pal[i][2], pal[i][3])
  end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

local function metrics_lua(m)
  local lines = { "return {" }
  for id = 0, #m do
    local r = m[id]
    lines[#lines + 1] = string.format(
      "  [%d] = { name = %q, maxLetterWidth = %d, maxLetterHeight = %d, letterSpacing = %d, lineSpacing = %d,"
        .. " fgColor = %d, bgColor = %d, shadowColor = %d },",
      id, r.name or "", r.maxLetterWidth, r.maxLetterHeight, r.letterSpacing, r.lineSpacing,
      r.fgColor, r.bgColor, r.shadowColor)
  end
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

local function required()
  local fonts = "chrome/fonts/"
  local list = {}
  for _, face in ipairs(RseTextChrome.LATIN) do
    list[#list + 1] = fonts .. "latin_" .. face .. "_fg.rgba"
    list[#list + 1] = fonts .. "latin_" .. face .. "_shadow.rgba"
    list[#list + 1] = fonts .. RseTextChrome.WIDTH_FILES[face]
  end
  for _, rel in ipairs({
    "japanese_normal_fg.rgba", "japanese_normal_shadow.rgba", "japanese_widths.lua",
    "japanese_small_fg.rgba", "japanese_small_shadow.rgba",
    "japanese_short_fg.rgba", "japanese_short_shadow.rgba", "japanese_short_widths.lua",
    "braille_fg.rgba", "braille_shadow.rgba", "braille.lua",
    "down_arrow.rgba", "down_arrow.idx", "down_arrow_dark.idx", "keypad_icons.rgba", "metrics.lua",
  }) do
    list[#list + 1] = fonts .. rel
  end
  list[#list + 1] = "keypad_icons.rgba"
  list[#list + 1] = "chrome/keypad_icons.rgba"
  list[#list + 1] = "chrome/message_box.rgba"
  list[#list + 1] = "chrome/palettes.lua"
  list[#list + 1] = "chrome/manifest.lua"
  for i = 0, 19 do list[#list + 1] = "chrome/user_frame_" .. i .. ".rgba" end
  return list
end

-- pokeemerald/include/text_window.h:4
RseTextChrome.USER_FRAME_COUNT = 20
RseTextChrome.REQUIRED = required()

function RseTextChrome.run(rom, cache, opts)
  opts = opts or {}
  local V = versions()
  local root = opts.cacheRoot or "data/generated/gba"
  local cDir = root .. "/" .. RseTextChrome.CACHE_SUB
  local fDir = cDir .. "/fonts"
  local function put(rel, data) cache:write(rel, data) end

  local latin = {}
  for _, face in ipairs(RseTextChrome.LATIN) do
    local f = RseTextChrome.extractLatin(rom, face)
    latin[face] = f
    put(fDir .. "/latin_" .. face .. "_fg.rgba", f.fgRgba)
    put(fDir .. "/latin_" .. face .. "_shadow.rgba", f.shRgba)
    put(fDir .. "/" .. RseTextChrome.WIDTH_FILES[face],
      widths_lua(f.widths, V.FONT_WIDTH_SYMBOLS[face]))
  end

  local jn = RseTextChrome.extractJapaneseNormal(rom)
  put(fDir .. "/japanese_normal_fg.rgba", jn.fgRgba)
  put(fDir .. "/japanese_normal_shadow.rgba", jn.shRgba)
  put(fDir .. "/japanese_widths.lua", widths_lua(jn.widths, "GetGlyphWidth_Normal"))
  local js = RseTextChrome.extractJapaneseSmall(rom)
  put(fDir .. "/japanese_small_fg.rgba", js.fgRgba)
  put(fDir .. "/japanese_small_shadow.rgba", js.shRgba)
  local jh = RseTextChrome.extractJapaneseShort(rom)
  put(fDir .. "/japanese_short_fg.rgba", jh.fgRgba)
  put(fDir .. "/japanese_short_shadow.rgba", jh.shRgba)
  put(fDir .. "/japanese_short_widths.lua", widths_lua(jh.widths, "gFontShortJapaneseGlyphWidths"))

  local br = RseTextChrome.extractBraille(rom)
  put(fDir .. "/braille_fg.rgba", br.fgRgba)
  put(fDir .. "/braille_shadow.rgba", br.shRgba)
  put(fDir .. "/braille.lua", string.format(
    "return { glyphCount = %d, cols = %d, rows = %d, glyphW = 16, glyphH = 16, width = %d, height = %d }\n",
    br.glyphs, br.cols, br.rows, br.width, br.height))

  local arrow = RseTextChrome.extractDownArrow(rom, false)
  put(fDir .. "/down_arrow.rgba", arrow.rgba)
  put(fDir .. "/down_arrow.idx", arrow.idx)
  put(fDir .. "/down_arrow_dark.idx", RseTextChrome.extractDownArrow(rom, true).idx)
  local kp = RseTextChrome.extractKeypadIcons(rom)
  put(root .. "/keypad_icons.rgba", kp.rgba)
  put(cDir .. "/keypad_icons.rgba", kp.rgba)
  put(fDir .. "/keypad_icons.rgba", kp.rgba)
  put(fDir .. "/metrics.lua", metrics_lua(RseTextChrome.extractFontMetrics(rom)))

  local box = RseTextChrome.extractMessageBox(rom)
  put(cDir .. "/message_box.rgba", box.rgba)

  local frameCount = V.TEXT_WINDOW_FRAME_COUNT
  assert(frameCount == RseTextChrome.USER_FRAME_COUNT, "sWindowFrames has " .. tostring(frameCount) .. " rows")
  local framePals = {}
  for i = 0, frameCount - 1 do
    local fr = RseTextChrome.extractUserFrame(rom, i)
    put(cDir .. "/user_frame_" .. i .. ".rgba", fr.rgba)
    framePals[i] = fr.palette
  end

  local pals = { "return {" }
  pals[#pals + 1] = "  message_box = " .. pal_lua(box.palette) .. ","
  pals[#pals + 1] = "  std_menu = " .. pal_lua(RseTextChrome.readPalette(rom, V.STD_MENU_PALETTE)) .. ","
  pals[#pals + 1] = "  text_window = {"
  for i = 0, V.TEXT_WINDOW_PALETTE_COUNT - 1 do
    pals[#pals + 1] = string.format("    [%d] = %s,", i,
      pal_lua(RseTextChrome.readPalette(rom, V.TEXT_WINDOW_PALETTES + i * 32)))
  end
  pals[#pals + 1] = "  },"
  pals[#pals + 1] = "  user_frames = {"
  for i = 0, frameCount - 1 do
    pals[#pals + 1] = string.format("    [%d] = %s,", i, pal_lua(framePals[i]))
  end
  pals[#pals + 1] = "  },"
  pals[#pals + 1] = "}"
  put(cDir .. "/palettes.lua", table.concat(pals, "\n") .. "\n")

  local m = { "return {", "  formatVersion = " .. RseTextChrome.FORMAT_VERSION .. ",", "  layout = \"rse\",", "  fonts = {" }
  for _, face in ipairs(RseTextChrome.LATIN) do
    local f = latin[face]
    m[#m + 1] = string.format("    latin_%s = { width = %d, height = %d, glyphs = %d, widths = %q },",
      face, f.width, f.height, f.glyphs, RseTextChrome.WIDTH_FILES[face])
  end
  m[#m + 1] = string.format("    japanese_normal = { width = %d, height = %d, glyphs = %d, glyphW = 8 },",
    jn.width, jn.height, jn.glyphs)
  m[#m + 1] = string.format("    japanese_small = { width = %d, height = %d, glyphs = %d, glyphW = 8 },",
    js.width, js.height, js.glyphs)
  m[#m + 1] = string.format("    japanese_short = { width = %d, height = %d, glyphs = %d },",
    jh.width, jh.height, jh.glyphs)
  m[#m + 1] = string.format("    down_arrow = { width = %d, height = %d, frameH = 16, yOffsets = { 0, 1, 2, 1 } },",
    arrow.width, arrow.height)
  m[#m + 1] = string.format("    keypad_icons = { width = %d, height = %d },", kp.width, kp.height)
  m[#m + 1] = "  },"
  m[#m + 1] = "  frames = {"
  m[#m + 1] = string.format("    message_box = { width = %d, height = %d, tilesW = %d, tilesH = 2 },",
    box.width, box.height, box.tiles / 2)
  m[#m + 1] = string.format("    user = { count = %d, width = 24, height = 24, tilesW = 3, tilesH = 3 },", frameCount)
  m[#m + 1] = "  },"
  m[#m + 1] = "}"
  m[#m + 1] = ""
  put(cDir .. "/manifest.lua", table.concat(m, "\n"))
  return true
end

return RseTextChrome
