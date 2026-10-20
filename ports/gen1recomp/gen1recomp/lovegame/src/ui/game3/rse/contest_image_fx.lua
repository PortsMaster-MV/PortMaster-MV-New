local bit = require("bit")
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift

local Fx = {}

-- pokeemerald/include/image_processing_effects.h:6
Fx.EFFECT = {
  POINTILLISM = 2, GRAYSCALE_LIGHT = 6, BLUR = 8, OUTLINE_COLORED = 9, INVERT_BLACK_WHITE = 10,
  THICK_BLACK_WHITE = 11, SHIMMER = 13, OUTLINE = 30, INVERT = 31, BLUR_RIGHT = 32, BLUR_DOWN = 33, CHARCOAL = 36,
}
-- pokeemerald/include/image_processing_effects.h:22
Fx.QUANTIZE = { STANDARD = 0, STANDARD_LIMITED_COLORS = 1, PRIMARY_COLORS = 2, GRAYSCALE = 3, GRAYSCALE_SMALL = 4,
  BLACK_WHITE = 5 }

-- pokeemerald/include/constants/rgb.h:12
local ALPHA = 0x8000
local WHITE = 0x7FFF
local BLACK = 0
local MAX_DIMENSION = 64

local function isAlpha(c) return band(c, ALPHA) ~= 0 end
local function R(c) return band(c, 0x1F) end
local function G(c) return band(rshift(c, 5), 0x1F) end
local function B(c) return band(rshift(c, 10), 0x1F) end
local function rgb2(r, g, b) return bor(lshift(b, 10), lshift(g, 5), r) end
local function u8(v) return band(v, 0xFF) end
local function u16(v) return band(v, 0xFFFF) end
local function idiv(a, b) return math.floor(a / b) end

local function each(ctx, fn)
  local px, W = ctx.pixels, ctx.width
  for j = 0, ctx.rowEnd - 1 do
    local row = (ctx.rowStart + j) * W + ctx.columnStart
    for i = 0, ctx.columnEnd - 1 do
      local k = row + i
      local c = px[k]
      if not isAlpha(c) then px[k] = fn(c) end
    end
  end
end

-- pokeemerald/src/image_processing_effects.c:503
local function grayscale(c)
  local gray = rshift(R(c) * 76 + G(c) * 151 + B(c) * 29, 8)
  return rgb2(gray, gray, gray)
end

-- pokeemerald/src/image_processing_effects.c:529
local function colorFromPersonality(p)
  local strength = math.floor(p / 6) % 3
  local kind = p % 6
  local r, g, b = 0, 0, 0
  if kind == 0 then g = 21 - strength; b = g
  elseif kind == 1 then r = 21 - strength; g = r
  elseif kind == 2 then b = 21 - strength; r = b
  elseif kind == 3 then r = 23 - strength
  elseif kind == 4 then b = 23 - strength
  else g = 23 - strength end
  return rgb2(r, g, b)
end

local function personalityColor(c, p)
  if R(c) < 17 and G(c) < 17 and B(c) < 17 then return colorFromPersonality(p) end
  return WHITE
end

local function blackAndWhite(c)
  if R(c) < 17 and G(c) < 17 and B(c) < 17 then return BLACK end
  return WHITE
end

local function blackOutline(a, b)
  if a ~= BLACK then
    if isAlpha(a) then return ALPHA end
    if isAlpha(b) then return BLACK end
    return a
  end
  return BLACK
end

local function invert(c)
  return rgb2(31 - R(c), 31 - G(c), 31 - B(c))
end

-- pokeemerald/src/image_processing_effects.c:620
local function motionBlur(prev, cur)
  if prev == cur then return cur end
  local p = { R(prev), G(prev), B(prev) }
  local q = { R(cur), G(cur), B(cur) }
  if p[1] > 25 and p[2] > 25 and p[3] > 25 then return cur end
  if q[1] > 25 and q[2] > 25 and q[3] > 25 then return cur end
  local d = {}
  for i = 1, 3 do d[i] = math.abs(p[i] - q[i]) end
  local largest
  if d[1] >= d[2] then
    if d[1] >= d[3] then largest = d[1]
    elseif d[2] >= d[3] then largest = d[2]
    else largest = d[3] end
  else
    if d[2] >= d[3] then largest = d[2]
    elseif d[3] >= d[1] then largest = d[3]
    else largest = d[1] end
  end
  local f = 31 - idiv(largest, 2)
  return rgb2(idiv(q[1] * f, 31), idiv(q[2] * f, 31), idiv(q[3] * f, 31))
end

local function blurWith(prev, cur, nxt, half)
  if prev == cur and nxt == cur then return cur end
  local r, g, b = R(cur), G(cur), B(cur)
  local pa = idiv(R(prev) + G(prev) + B(prev), 3)
  local ca = idiv(r + g + b, 3)
  local na = idiv(R(nxt) + G(nxt) + B(nxt), 3)
  if pa == ca and na == ca then return cur end
  local pd, nd = math.abs(pa - ca), math.abs(na - ca)
  local diff = pd >= nd and pd or nd
  local f = half and (31 - idiv(diff, 2)) or (31 - diff)
  return rgb2(idiv(r * f, 31), idiv(g * f, 31), idiv(b * f, 31))
end

-- pokeemerald/src/image_processing_effects.c:124
local function redChannelGrayscale(ctx, delta)
  each(ctx, function(c)
    local g = u8(R(c) + delta)
    if g > 31 then g = 31 end
    return rgb2(g, g, g)
  end)
end

-- pokeemerald/src/image_processing_effects.c:149
local function redChannelGrayscaleHighlight(ctx, highlight)
  each(ctx, function(c)
    local g = R(c)
    if g > 31 - highlight then g = 31 - rshift(highlight, 1) end
    return rgb2(g, g, g)
  end)
end

-- pokeemerald/src/image_processing_effects.c:194
local function blur(ctx)
  local px, W = ctx.pixels, ctx.width
  for i = 0, ctx.columnEnd - 1 do
    local k = ctx.rowStart * W + ctx.columnStart + i
    local prev = px[k]
    local j = 1
    k = k + W
    while j < ctx.rowEnd - 1 do
      if not isAlpha(px[k]) then
        px[k] = blurWith(prev, px[k], px[k + W], true)
        prev = px[k]
      end
      j = j + 1
      k = k + W
    end
  end
end

-- pokeemerald/src/image_processing_effects.c:252
local function blackOutlineFx(ctx)
  local px, W = ctx.pixels, ctx.width
  for j = 0, ctx.rowEnd - 1 do
    local k = (ctx.rowStart + j) * W + ctx.columnStart
    px[k] = blackOutline(px[k], px[k + 1])
    local i = 1
    k = k + 1
    while i < ctx.columnEnd - 1 do
      px[k] = blackOutline(px[k], px[k + 1])
      px[k] = blackOutline(px[k], px[k - 1])
      i = i + 1
      k = k + 1
    end
    px[k] = blackOutline(px[k], px[k - 1])
  end
  for i = 0, ctx.columnEnd - 1 do
    local k = ctx.rowStart * W + ctx.columnStart + i
    px[k] = blackOutline(px[k], px[k + W])
    local j = 1
    k = k + W
    while j < ctx.rowEnd - 1 do
      px[k] = blackOutline(px[k], px[k + W])
      px[k] = blackOutline(px[k], px[k - W])
      j = j + 1
      k = k + W
    end
    px[k] = blackOutline(px[k], px[k - W])
  end
end

-- pokeemerald/src/image_processing_effects.c:304
local function shimmer(ctx)
  local px = ctx.pixels
  local D = MAX_DIMENSION
  for k = 0, D * D - 1 do
    if not isAlpha(px[k]) then px[k] = invert(px[k]) end
  end
  for j = 0, D - 1 do
    for _ = 1, 2 do
      local k = j
      local prev = px[k]
      px[k] = ALPHA
      k = k + D
      for _ = 1, D - 2 do
        if not isAlpha(px[k]) then
          px[k] = blurWith(prev, px[k], px[k + D], false)
          prev = px[k]
        end
        k = k + D
      end
      px[k] = ALPHA
    end
  end
  for k = 0, D * D - 1 do
    if not isAlpha(px[k]) then px[k] = invert(px[k]) end
  end
end

-- pokeemerald/src/image_processing_effects.c:366
local function blurRight(ctx)
  local px, W = ctx.pixels, ctx.width
  for j = 0, ctx.rowEnd - 1 do
    local k = (ctx.rowStart + j) * W + ctx.columnStart
    local prev = px[k]
    k = k + 1
    for _ = 1, ctx.columnEnd - 2 do
      if not isAlpha(px[k]) then
        px[k] = motionBlur(prev, px[k])
        prev = px[k]
      end
      k = k + 1
    end
  end
end

-- pokeemerald/src/image_processing_effects.c:386
local function blurDown(ctx)
  local px, W = ctx.pixels, ctx.width
  for i = 0, ctx.columnEnd - 1 do
    local k = ctx.rowStart * W + ctx.columnStart + i
    local prev = px[k]
    k = k + W
    for _ = 1, ctx.rowEnd - 2 do
      if not isAlpha(px[k]) then
        px[k] = motionBlur(prev, px[k])
        prev = px[k]
      end
      k = k + W
    end
  end
end

-- pokeemerald/src/image_processing_effects.c:413
local function addPointillismPoints(ctx, points, index)
  local px = ctx.pixels
  local base = index * 3
  local bits = points[base + 2]
  local delta0 = band(rshift(bits, 3), 7)
  local colorType = band(rshift(bits, 1), 3)
  local offsetDownLeft = band(bits, 1) ~= 0
  local cols, rows, deltas = { [0] = points[base] }, { [0] = points[base + 1] }, { [0] = delta0 }
  local n = delta0
  local i = 1
  while i < n do
    if not offsetDownLeft then
      cols[i] = u8(cols[0] - i)
      rows[i] = u8(rows[0] + i)
    else
      cols[i] = u8(cols[0] + 1)
      rows[i] = u8(rows[0] - 1)
    end
    if cols[i] >= MAX_DIMENSION or rows[i] >= MAX_DIMENSION then
      n = u16(i - 1)
      deltas[0] = n
      break
    end
    deltas[i] = n - i
    i = i + 1
  end
  for k = 0, n - 1 do
    local at = rows[k] * MAX_DIMENSION + cols[k]
    local c = px[at]
    if not isAlpha(c) then
      local r, g, b = R(c), G(c), B(c)
      local d = deltas[k]
      if colorType <= 1 then
        local m = delta0 % 3
        if m == 0 then r = r >= d and r - d or 0
        elseif m == 1 then g = g >= d and g - d or 0
        else b = b >= d and b - d or 0 end
      else
        r, g, b = math.min(31, r + d), math.min(31, g + d), math.min(31, b + d)
      end
      px[at] = rgb2(r, g, b)
    end
  end
end

-- pokeemerald/src/image_processing_effects.c:58
function Fx.apply(ctx)
  local E = Fx.EFFECT
  local e = ctx.effect
  if e == E.POINTILLISM then
    local points = assert(ctx.pointillism, "contest_image_fx: pointillism table missing")
    for i = 0, ctx.pointillismCount - 1 do addPointillismPoints(ctx, points, i) end
  elseif e == E.BLUR then
    blur(ctx)
  elseif e == E.OUTLINE_COLORED then
    blackOutlineFx(ctx)
    local p = ctx.personality
    each(ctx, function(c) return personalityColor(c, p) end)
  elseif e == E.INVERT_BLACK_WHITE then
    blackOutlineFx(ctx)
    each(ctx, invert)
    each(ctx, blackAndWhite)
    each(ctx, invert)
  elseif e == E.INVERT then
    each(ctx, invert)
  elseif e == E.THICK_BLACK_WHITE then
    blackOutlineFx(ctx)
    blurRight(ctx)
    blurRight(ctx)
    blurDown(ctx)
    each(ctx, blackAndWhite)
  elseif e == E.SHIMMER then
    shimmer(ctx)
  elseif e == E.OUTLINE then
    blackOutlineFx(ctx)
  elseif e == E.BLUR_RIGHT then
    blurRight(ctx)
  elseif e == E.BLUR_DOWN then
    blurDown(ctx)
  elseif e == E.GRAYSCALE_LIGHT then
    each(ctx, grayscale)
    redChannelGrayscale(ctx, 3)
  elseif e == E.CHARCOAL then
    blackOutlineFx(ctx)
    blurRight(ctx)
    blurDown(ctx)
    each(ctx, blackAndWhite)
    blur(ctx)
    blur(ctx)
    redChannelGrayscale(ctx, 2)
    redChannelGrayscaleHighlight(ctx, 4)
  end
end

-- pokeemerald/src/image_processing_effects.c:1063
local function standardPixel(c)
  local r, g, b = R(c), G(c), B(c)
  if band(r, 3) ~= 0 then r = band(r, 0x1C) + 4 end
  if band(g, 3) ~= 0 then g = band(g, 0x1C) + 4 end
  if band(b, 3) ~= 0 then b = band(b, 0x1C) + 4 end
  r = math.max(6, math.min(30, r))
  g = math.max(6, math.min(30, g))
  b = math.max(6, math.min(30, b))
  return rgb2(r, g, b)
end

-- pokeemerald/src/image_processing_effects.c:1209
local function grayscaleSmallPixel(c)
  local avg = band(idiv(R(c) + G(c) + B(c), 3), 0x1E)
  if avg == 0 then return 1 end
  return avg / 2
end

-- pokeemerald/src/image_processing_effects.c:1221
local function grayscalePixel(c)
  return idiv(R(c) + G(c) + B(c), 3) + 1
end

-- pokeemerald/src/image_processing_effects.c:1094
local function primaryPixel(c)
  local r, g, b = R(c), G(c), B(c)
  if r < 12 and g < 11 and b < 11 then return 1 end
  if r > 19 and g > 19 and b > 19 then return 2 end
  if r > 19 then
    if g > 19 then
      if b > 14 then return 2 else return 7 end
    elseif b > 19 then
      if g > 14 then return 2 else return 8 end
    end
  end
  if g > 19 and b > 19 then
    if r > 14 then return 2 else return 9 end
  end
  if r > 19 then
    if g > 11 then
      if b > 11 then
        if g < b then return 8 else return 7 end
      end
      return 10
    elseif b > 11 then
      return 13
    end
    return 4
  end
  if g > 19 then
    if r > 11 then
      if b > 11 then
        if r < b then return 9 else return 7 end
      end
      return 11
    end
    if b > 11 then return 14 end
    return 5
  end
  if b > 19 then
    if r > 11 then
      if g > 11 then
        if r < g then return 9 else return 8 end
      end
    elseif g > 11 then
      return 12
    end
    if b > 11 then return 15 end
    return 6
  end
  return 3
end

-- pokeemerald/src/image_processing_effects.c:815
function Fx.quantize(ctx)
  local Q = Fx.QUANTIZE
  local start = ctx.paletteStart * 16
  local pal = ctx.palette
  local q = ctx.quantizeEffect
  if q == Q.STANDARD or q == Q.STANDARD_LIMITED_COLORS then
    -- pokeemerald/src/image_processing_effects.c:900
    local maxIndex = q == Q.STANDARD_LIMITED_COLORS and 0xDF or 0xFF
    for i = 0, maxIndex - 1 do pal[start + i] = BLACK end
    pal[start + maxIndex] = rgb2(15, 15, 15)
    local px, W = ctx.pixels, ctx.width
    for j = 0, ctx.rowEnd - 1 do
      local row = (ctx.rowStart + j) * W + ctx.columnStart
      for i = 0, ctx.columnEnd - 1 do
        local k = row + i
        if isAlpha(px[k]) then
          px[k] = start
        else
          local color = standardPixel(px[k])
          local cur = 1
          while cur < maxIndex do
            if pal[start + cur] == BLACK then
              pal[start + cur] = color
              px[k] = start + cur
              break
            end
            if pal[start + cur] == color then
              px[k] = start + cur
              break
            end
            cur = cur + 1
          end
          if cur == maxIndex then px[k] = maxIndex end
        end
      end
    end
    return
  end
  local fn
  if q == Q.PRIMARY_COLORS then
    -- pokeemerald/src/image_processing_effects.c:854
    local presets = { [0] = BLACK, rgb2(6, 6, 6), rgb2(29, 29, 29), rgb2(11, 11, 11), rgb2(29, 6, 6), rgb2(6, 29, 6),
      rgb2(6, 6, 29), rgb2(29, 29, 6), rgb2(29, 6, 29), rgb2(6, 29, 29), rgb2(29, 11, 6), rgb2(11, 29, 6),
      rgb2(6, 11, 29), rgb2(29, 6, 11), rgb2(6, 29, 11), rgb2(11, 6, 29) }
    for i = 0, 15 do pal[start + i] = presets[i] end
    fn = primaryPixel
  elseif q == Q.GRAYSCALE then
    -- pokeemerald/src/image_processing_effects.c:891
    pal[start] = BLACK
    for i = 0, 31 do pal[start + i + 1] = rgb2(i, i, i) end
    fn = grayscalePixel
  elseif q == Q.GRAYSCALE_SMALL then
    -- pokeemerald/src/image_processing_effects.c:881
    pal[start], pal[start + 1] = BLACK, BLACK
    for i = 0, 13 do pal[start + i + 2] = rgb2(2 * (i + 2), 2 * (i + 2), 2 * (i + 2)) end
    fn = grayscaleSmallPixel
  elseif q == Q.BLACK_WHITE then
    -- pokeemerald/src/image_processing_effects.c:874
    pal[start], pal[start + 1], pal[start + 2] = BLACK, BLACK, WHITE
    fn = function(c) return blackAndWhite(c) == BLACK and 1 or 2 end
  end
  if not fn then return end
  local px, W = ctx.pixels, ctx.width
  for j = 0, ctx.rowEnd - 1 do
    local row = (ctx.rowStart + j) * W + ctx.columnStart
    for i = 0, ctx.columnEnd - 1 do
      local k = row + i
      if isAlpha(px[k]) then px[k] = start else px[k] = fn(px[k]) + start end
    end
  end
end

function Fx.context(pixels, opts)
  opts = opts or {}
  return {
    pixels = pixels, palette = opts.palette or {}, paletteStart = opts.paletteStart or 0,
    personality = (opts.personality or 0) % 256,
    columnStart = 0, rowStart = 0, columnEnd = 64, rowEnd = 64, width = 64, height = 64,
    effect = opts.effect, quantizeEffect = opts.quantizeEffect,
    pointillism = opts.pointillism, pointillismCount = opts.pointillismCount or 0,
  }
end

Fx.rgb2, Fx.R, Fx.G, Fx.B, Fx.ALPHA = rgb2, R, G, B, ALPHA

return Fx
