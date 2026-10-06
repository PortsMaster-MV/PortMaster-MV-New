local Faces = {}

local function read(path)
  local Cache = require("src.import.CacheFs")
  return Cache.readActive(path)
end

-- pokeruby/src/text.c:2676
function Faces.load(spec, name, language, loadImage, loadTable, palette, textMode)
  local id = assert(spec.faces[name], "unknown RS font face").id
  local stem = "rs_" .. language .. "_" .. id
  local manifest = assert(loadTable(spec.manifest), "RS native font manifest missing")
  local info = assert(manifest.fonts[stem], "RS native font manifest lacks " .. stem)
  assert(manifest.layout == "rs" and info.id == id and info.language == language, "RS native font identity")
  local dir = spec.dir
  local widths = assert(loadTable(dir .. stem .. "_widths.lua"), "RS native font widths missing")
  local monospace = textMode == 1
  if info.bpp == 1 and not monospace then
    stem = assert(info.variableStem, "RS variable-width font missing; re-import selected ROM")
  end
  local fg, _, fgData = loadImage({ { path = dir .. stem .. "_fg.rgba", w = info.width, h = info.height } })
  local sh, _, shData = loadImage({ { path = dir .. stem .. "_shadow.rgba", w = info.width, h = info.height } })
  local indices = read(dir .. stem .. ".idx")
  assert(fg and sh and widths and indices and #indices == info.width * info.height, "RS font assets missing for " .. stem)
  local fixed, present = {}, false
  for p = 1, #indices do
    local value = indices:byte(p)
    if value > 0 and value < 14 then
      local c = assert(palette[value], "RS embedded font color missing")
      fixed[p] = string.char(math.floor(c[1] * 255 + .5), math.floor(c[2] * 255 + .5), math.floor(c[3] * 255 + .5), 255)
      present = true
    else
      fixed[p] = "\0\0\0\0"
    end
  end
  local fixedImage
  if present then
    fixedImage = love.graphics.newImage(love.image.newImageData(info.width, info.height, "rgba8", table.concat(fixed)))
    fixedImage:setFilter("nearest", "nearest")
  end
  local quads, boundaryQuads = {}, {}
  for glyph = 0, info.glyphs - 1 do
    local width = assert(widths[glyph], "native RS glyph width missing")
    local drawWidth = monospace and 8 or (info.bpp == 1 and width == 3 and 4 or width)
    quads[glyph] = love.graphics.newQuad(glyph % 16 * 16, math.floor(glyph / 16) * 16, math.min(drawWidth, 8), 16, info.width, info.height)
    if not monospace and info.bpp == 1 and width == 3 then
      boundaryQuads[glyph] = love.graphics.newQuad(glyph % 16 * 16, math.floor(glyph / 16) * 16, 3, 16, info.width, info.height)
    end
    if monospace then widths[glyph] = 8 end
  end
  return {
    name = name, language = language, nativeIndexed = true,
    fg = fg, sh = sh, fixed = fixedImage, quads = quads, boundaryQuads = boundaryQuads, widths = widths,
    height = 16, pitch = 16, letterSpacing = 0, glyphs = info.glyphs,
    fgData = fgData, shData = shData,
  }
end

return Faces
