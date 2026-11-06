local bit = require("bit")

local IndexedPng = {}

local function be32(s, i)
  local a, b, c, d = s:byte(i, i + 3)
  return ((a * 256 + b) * 256 + c) * 256 + d
end

local function paeth(a, b, c)
  local p = a + b - c
  local pa, pb, pc = math.abs(p - a), math.abs(p - b), math.abs(p - c)
  if pa <= pb and pa <= pc then return a end
  if pb <= pc then return b end
  return c
end

function IndexedPng.decode(bytes, inflate)
  assert(type(bytes) == "string" and bytes:sub(1, 8) == "\137PNG\r\n\26\n", "indexed_png: not a PNG")
  local pos, w, h, depth, ctype = 9, nil, nil, nil, nil
  local idat, plte, trns = {}, nil, nil
  while pos <= #bytes do
    local len = be32(bytes, pos)
    local kind = bytes:sub(pos + 4, pos + 7)
    local body = bytes:sub(pos + 8, pos + 7 + len)
    if kind == "IHDR" then
      w, h = be32(body, 1), be32(body, 5)
      depth, ctype = body:byte(9), body:byte(10)
    elseif kind == "PLTE" then
      plte = body
    elseif kind == "tRNS" then
      trns = body
    elseif kind == "IDAT" then
      idat[#idat + 1] = body
    elseif kind == "IEND" then
      break
    end
    pos = pos + 12 + len
  end
  assert(w and depth == 8 and (ctype == 3 or ctype == 0), "indexed_png: need 8-bit indexed or gray")
  local raw = inflate(table.concat(idat))
  local out = {}
  local prev = {}
  for x = 1, w do prev[x] = 0 end
  local p = 1
  for y = 0, h - 1 do
    local filter = raw:byte(p)
    p = p + 1
    local row = { raw:byte(p, p + w - 1) }
    p = p + w
    if filter == 1 then
      for x = 2, w do row[x] = bit.band(row[x] + row[x - 1], 0xFF) end
    elseif filter == 2 then
      for x = 1, w do row[x] = bit.band(row[x] + prev[x], 0xFF) end
    elseif filter == 3 then
      for x = 1, w do
        local left = x > 1 and row[x - 1] or 0
        row[x] = bit.band(row[x] + math.floor((left + prev[x]) / 2), 0xFF)
      end
    elseif filter == 4 then
      for x = 1, w do
        local left = x > 1 and row[x - 1] or 0
        local upLeft = x > 1 and prev[x - 1] or 0
        row[x] = bit.band(row[x] + paeth(left, prev[x], upLeft), 0xFF)
      end
    end
    for x = 1, w do out[y * w + x] = row[x] end
    prev = row
  end
  return { w = w, h = h, index = out, plte = plte, trns = trns }
end

function IndexedPng.loveInflate(data)
  return love.data.decompress("string", "zlib", data)
end

function IndexedPng.load(path)
  local bytes = assert(love.filesystem.read(path), "indexed_png: cannot read " .. tostring(path))
  return IndexedPng.decode(bytes, IndexedPng.loveInflate)
end

function IndexedPng.indexImageData(decoded)
  local w, h, idx = decoded.w, decoded.h, decoded.index
  local quads = {}
  for i = 0, 255 do quads[i] = string.char(i, i, i, 255) end
  local rows = {}
  for y = 0, h - 1 do
    local parts = {}
    local base = y * w
    for x = 1, w do parts[x] = quads[idx[base + x]] end
    rows[y + 1] = table.concat(parts)
  end
  return love.image.newImageData(w, h, "rgba8", table.concat(rows))
end

function IndexedPng.indexImage(path)
  local img = love.graphics.newImage(IndexedPng.indexImageData(IndexedPng.load(path)))
  img:setFilter("nearest", "nearest")
  return img
end

return IndexedPng
