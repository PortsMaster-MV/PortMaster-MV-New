local Chrome = {}
local Shared = require("src.import.gba.rse.text_chrome_extract")
local ON, OFF = "\255\255\255\255", "\0\0\0\0"
Chrome.FORMAT_VERSION = 2

local function versions() return require("src.import.gba.versions") end

-- pokeruby/src/text.c:2676
function Chrome.glyphPointers(rom, spec, glyph, V)
  V = V or versions()
  local upper, lower
  if spec.type == 0 then
    upper = spec.glyphs + glyph * spec.glyphSize
    lower = upper + spec.lowerTileOffset
  elseif spec.type == 1 or spec.type == 3 then
    local map = spec.type == 1 and V.RS_FONT_TYPE1_MAP or V.RS_FONT_TYPE3_MAP
    if glyph >= map.count then return nil end
    upper = spec.glyphs + rom:get(map.off + 2 * glyph) * spec.glyphSize
    lower = spec.glyphs + rom:get(map.off + 2 * glyph + 1) * spec.glyphSize
  elseif spec.type == 2 then
    upper = spec.glyphs + 212 * spec.glyphSize
    lower = spec.glyphs + glyph * spec.glyphSize
  elseif spec.type == 4 then
    upper = spec.glyphs + (glyph - glyph % 16) * spec.glyphSize + glyph % 16 * spec.glyphSize / 2
    lower = upper + spec.lowerTileOffset
  else
    error("unknown native RS font type " .. tostring(spec.type))
  end
  local tileBytes = spec.bpp == 1 and 8 or 32
  local finish = spec.glyphs + spec.bytes
  if upper < spec.glyphs or lower < spec.glyphs or upper + tileBytes > finish or lower + tileBytes > finish then return nil end
  return upper, lower
end

-- pokeruby/src/text.c:3410
function Chrome.glyphWidth(rom, spec, glyph, V)
  V = V or versions()
  if spec.language == "japanese" or spec.id == 6 then return 8 end
  local key = ({ [0] = 0, [1] = 1, [2] = 1, [3] = 3, [4] = 4, [5] = 4 })[spec.id]
  local widths = assert(V.RS_FONT_WIDTHS[key], "missing native RS font widths")
  local idx = glyph
  if spec.id == 1 or spec.id == 2 or spec.id == 4 or spec.id == 5 then
    if glyph >= V.RS_FONT_TYPE1_MAP.count then return nil end
    idx = rom:get(V.RS_FONT_TYPE1_MAP.off + glyph * 2 + 1)
  end
  if idx >= widths.count then return nil end
  return rom:get(widths.off + idx)
end

function Chrome.fontSpec(rom, id, language, V)
  V = V or versions()
  assert(V.RS_FONT_COUNT == 14, "native RS font table must have two sets of seven fonts")
  assert(id >= 0 and id <= 6 and (language == "latin" or language == "japanese"), "invalid RS font")
  local off = V.RS_FONT_TABLE + ((language == "latin" and 7 or 0) + id) * 12
  local glyphs = assert(rom:ptrOffset(rom:u32(off + 4)), "native RS glyph pointer")
  local source = assert(V.RS_FONT_SOURCES[glyphs], "RS font pointer is not a native glyph symbol")
  local spec = {
    id = id, language = language, type = rom:u32(off), glyphs = glyphs,
    glyphSize = rom:u16(off + 8), lowerTileOffset = rom:u16(off + 10),
    bytes = source.bytes, symbol = source.symbol, bpp = (id < 3 or id == 6) and 1 or 4,
  }
  local count = 0
  while count < 512 and Chrome.glyphPointers(rom, spec, count, V) and Chrome.glyphWidth(rom, spec, count, V) ~= nil do
    count = count + 1
  end
  assert(count > 0 and count < 512, "RS glyph domain must be bounded by native assets")
  spec.glyphsCount = count
  return spec
end

-- pokeruby/src/text.c:2729
function Chrome.pixel(rom, tile, bpp, x, y, textMode)
  if bpp == 1 then
    local bit = textMode ~= nil and textMode ~= 1 and 7 - x or x
    return math.floor(rom:get(tile + y) / 2 ^ bit) % 2 * 15
  end
  local byte = rom:get(tile + y * 4 + math.floor(x / 2))
  return x % 2 == 0 and byte % 16 or math.floor(byte / 16)
end

function Chrome.extractFont(rom, id, language, V, textMode)
  V = V or versions()
  local spec = Chrome.fontSpec(rom, id, language, V)
  local w, h = 256, math.ceil(spec.glyphsCount / 16) * 16
  local idx, fg, sh, widths = {}, {}, {}, {}
  for i = 1, w * h do idx[i], fg[i], sh[i] = "\0", OFF, OFF end
  for glyph = 0, spec.glyphsCount - 1 do
    local upper, lower = Chrome.glyphPointers(rom, spec, glyph, V)
    local ox, oy = glyph % 16 * 16, math.floor(glyph / 16) * 16
    widths[glyph] = Chrome.glyphWidth(rom, spec, glyph, V)
    for y = 0, 15 do
      for x = 0, 7 do
        local p = (oy + y) * w + ox + x + 1
        local value = Chrome.pixel(rom, y < 8 and upper or lower, spec.bpp, x, y % 8, textMode)
        if textMode ~= nil and textMode ~= 1 and spec.bpp == 1 then
          local drawWidth = widths[glyph] == 3 and 4 or widths[glyph]
          if x >= drawWidth then value = 0 end
        end
        idx[p] = string.char(value)
        if value == 15 then fg[p] = ON elseif value == 14 then sh[p] = ON end
      end
    end
  end
  return { spec = spec, width = w, height = h, idx = table.concat(idx),
    fgRgba = table.concat(fg), shRgba = table.concat(sh), widths = widths }
end

-- pokeruby/src/string_util.c:408
Chrome.BRAILLE_CELLS = 0x40
function Chrome.extractBraille(rom, V)
  V = V or versions()
  -- pokeruby/src/text.c:622
  local face = Chrome.extractFont(rom, 6, "latin", V, 2)
  assert(face.spec.glyphsCount >= Chrome.BRAILLE_CELLS * 2, "RS braille font must hold both cell halves")
  local cols = 16
  local w, h = cols * 16, Chrome.BRAILLE_CELLS / cols * 16
  local fg = {}
  for i = 1, w * h do fg[i] = OFF end
  for code = 0, Chrome.BRAILLE_CELLS - 1 do
    local ox, oy = code % cols * 16, math.floor(code / cols) * 16
    for half, glyph in ipairs({ code, code + Chrome.BRAILLE_CELLS }) do
      local gx, gy = glyph % 16 * 16, math.floor(glyph / 16) * 16
      for y = 0, 15 do
        for x = 0, 7 do
          if face.idx:byte((gy + y) * face.width + gx + x + 1) == 15 then
            fg[(oy + y) * w + ox + (half - 1) * 8 + x + 1] = ON
          end
        end
      end
    end
  end
  return { fgRgba = table.concat(fg), width = w, height = h, cols = cols, rows = h / 16,
    glyphs = Chrome.BRAILLE_CELLS, symbol = face.spec.symbol }
end

local function widthsLua(widths, count)
  local lines = { "return {" }
  for i = 0, count - 1 do lines[#lines + 1] = string.format("  [%d] = %d,", i, widths[i]) end
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n") .. "\n"
end

Chrome.REQUIRED = { "chrome/native_fonts.lua", "chrome/font_palette.lua", "chrome/message_box.rgba",
  "chrome/fonts/down_arrow.idx", "chrome/fonts/down_arrow.rgba", "chrome/rs_frames.lua",
  "chrome/fonts/braille_fg.rgba", "chrome/fonts/braille.lua" }
for _, language in ipairs({ "latin", "japanese" }) do
  for id = 0, 6 do
    local stem = "chrome/fonts/rs_" .. language .. "_" .. id
    for _, suffix in ipairs({ ".idx", "_fg.rgba", "_shadow.rgba", "_widths.lua" }) do
      Chrome.REQUIRED[#Chrome.REQUIRED + 1] = stem .. suffix
    end
    if id < 3 or id == 6 then
      for _, suffix in ipairs({ ".idx", "_fg.rgba", "_shadow.rgba" }) do
        Chrome.REQUIRED[#Chrome.REQUIRED + 1] = stem .. "_variable" .. suffix
      end
    end
  end
end
for id = 0, 19 do Chrome.REQUIRED[#Chrome.REQUIRED + 1] = "chrome/user_frame_" .. id .. ".rgba" end

function Chrome.run(rom, cache, opts)
  local V = versions()
  local root = (opts or {}).cacheRoot or "data/generated/gba"
  local function put(rel, data) assert(cache:write(root .. "/" .. rel, data) ~= false, "RS text chrome write failed") end
  local manifest = { "return { formatVersion = " .. Chrome.FORMAT_VERSION .. ", layout = 'rs', fonts = {" }
  for _, language in ipairs({ "latin", "japanese" }) do
    for id = 0, 6 do
      local face = Chrome.extractFont(rom, id, language, V)
      local name = "rs_" .. language .. "_" .. id
      local stem = "chrome/fonts/" .. name
      put(stem .. ".idx", face.idx)
      put(stem .. "_fg.rgba", face.fgRgba)
      put(stem .. "_shadow.rgba", face.shRgba)
      put(stem .. "_widths.lua", widthsLua(face.widths, face.spec.glyphsCount))
      local variableStem
      if face.spec.bpp == 1 then
        variableStem = name .. "_variable"
        local variable = Chrome.extractFont(rom, id, language, V, 2)
        put(stem .. "_variable.idx", variable.idx)
        put(stem .. "_variable_fg.rgba", variable.fgRgba)
        put(stem .. "_variable_shadow.rgba", variable.shRgba)
      end
      manifest[#manifest + 1] = string.format(
        "  %s = { id = %d, language = %q, source = %q, width = %d, height = %d, glyphs = %d, glyphW = 8, glyphH = 16, bpp = %d, type = %d, paletteIndices = true, variableStem = %s },",
        name, id, language, face.spec.symbol, face.width, face.height, face.spec.glyphsCount, face.spec.bpp, face.spec.type,
        variableStem and string.format("%q", variableStem) or "nil")
    end
  end
  manifest[#manifest + 1] = "} }"
  put("chrome/native_fonts.lua", table.concat(manifest, "\n") .. "\n")
  local braille = Chrome.extractBraille(rom, V)
  put("chrome/fonts/braille_fg.rgba", braille.fgRgba)
  -- pokeruby/src/text.c:2046
  put("chrome/fonts/braille.lua", string.format(
    "return { layout = 'rs', source = %q, glyphCount = %d, cols = %d, rows = %d, glyphW = 16, glyphH = 16, width = %d, height = %d, linePitch = 32, shadow = false }\n",
    braille.symbol, braille.glyphs, braille.cols, braille.rows, braille.width, braille.height))
  local pal = Shared.readPalette(rom, V.MESSAGE_BOX_PAL)
  local pals = { "return {" }
  for i = 0, 15 do pals[#pals + 1] = string.format("  [%d] = { %d, %d, %d },", i, pal[i][1], pal[i][2], pal[i][3]) end
  pals[#pals + 1] = "}"
  put("chrome/font_palette.lua", table.concat(pals, "\n") .. "\n")
  local box = Shared.extractMessageBox(rom)
  put("chrome/message_box.rgba", box.rgba)
  assert(V.DOWN_ARROW_BYTES == 256, "RS down arrow must be four 8x16 frames")
  local arrow = Shared.decode4bpp(rom, V.DOWN_ARROW_GFX, 1, 8, pal)
  put("chrome/fonts/down_arrow.rgba", arrow.rgba)
  put("chrome/fonts/down_arrow.idx", Shared.decode4bppIndices(rom, V.DOWN_ARROW_GFX, 1, 8).idx)
  assert(V.TEXT_WINDOW_FRAME_COUNT == 20, "RS user frame count")
  for id = 0, 19 do put("chrome/user_frame_" .. id .. ".rgba", Shared.extractUserFrame(rom, id).rgba) end
  put("chrome/rs_frames.lua", string.format(
    "return { layout = 'rs', userCount = 20, dialogue = { width = %d, height = %d, tiles = %d }, downArrow = { width = 8, height = 64, frameH = 16, frames = 4, delay = 6 } }\n",
    box.width, box.height, box.tiles))
  return true
end

return Chrome
