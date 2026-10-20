local bit = require("bit")

local band, bor, bnot, lshift, rshift = bit.band, bit.bor, bit.bnot, bit.lshift, bit.rshift

local Structs = {}

local SIZE = { u8 = 1, s8 = 1, bool8 = 1, u16 = 2, s16 = 2, u32 = 4, s32 = 4 }
Structs.SIZE = SIZE

local function u8(s, o) return s:byte(o + 1) end
local function u16(s, o) local a, b = s:byte(o + 1, o + 2); return a + b * 256 end
local function u32(s, o) local a, b, c, d = s:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + d * 16777216 end

local function scalar(s, o, t)
  if t == "u8" then return u8(s, o) end
  if t == "bool8" then return u8(s, o) ~= 0 end
  if t == "s8" then local v = u8(s, o); return v >= 128 and v - 256 or v end
  if t == "u16" then return u16(s, o) end
  if t == "s16" then local v = u16(s, o); return v >= 32768 and v - 65536 or v end
  if t == "u32" then return u32(s, o) end
  if t == "s32" then local v = u32(s, o); return v >= 2147483648 and v - 4294967296 or v end
  error("structs: unknown scalar " .. tostring(t))
end

local function put(w, o, t, v)
  if t == "bool8" then
    w:w8(o, (v == true or (type(v) == "number" and v ~= 0)) and 1 or 0)
    return
  end
  v = tonumber(v) or 0
  if t == "u8" or t == "s8" then w:w8(o, v)
  elseif t == "u16" or t == "s16" then w:w16(o, v)
  else w:w32(o, v) end
end

function Structs.fieldSize(f)
  local base
  if f.t == "bits" then base = SIZE[f.of]
  elseif f.t == "text" then base = f.len
  elseif f.t == "struct" then base = f.size
  else base = SIZE[f.t] end
  local n = (f.n or 1) * (f.m or 1)
  return (f.stride or base) * n
end

local readField, writeField

local function eachIndex(f, fn)
  local first = f.zero and 0 or 1
  if f.m then
    for i = 0, f.n - 1 do
      for j = 0, f.m - 1 do fn(first + i, first + j, (i * f.m + j)) end
    end
  else
    for i = 0, f.n - 1 do fn(first + i, nil, i) end
  end
end

local function elementStride(f)
  if f.stride then return f.stride end
  if f.t == "struct" then return f.size end
  if f.t == "text" then return f.len end
  return SIZE[f.t]
end

local function readOne(s, o, f, codec)
  if f.t == "bits" then
    local c = scalar(s, o, f.of)
    local v = band(rshift(c, f.shift), lshift(1, f.width) - 1)
    if f.bool then return v ~= 0 end
    return v
  elseif f.t == "text" then
    return codec.decodeString(s, o, f.len)
  elseif f.t == "struct" then
    return Structs.read(s, o, f.spec, codec)
  end
  return scalar(s, o, f.t)
end

function readField(s, base, f, codec)
  local o = base + f.off
  if not f.n then return readOne(s, o, f, codec) end
  local out, stride = {}, elementStride(f)
  eachIndex(f, function(i, j, k)
    local v = readOne(s, o + k * stride, f, codec)
    if j then
      out[i] = out[i] or {}
      out[i][j] = v
    else
      out[i] = v
    end
  end)
  return out
end

function Structs.read(s, base, spec, codec)
  local out = {}
  for _, f in ipairs(spec) do
    if f.name then out[f.name] = readField(s, base, f, codec) end
  end
  return out
end

local function writeOne(w, o, f, v, codec)
  if f.t == "bits" then
    local cur = 0
    local size = SIZE[f.of]
    for i = 0, size - 1 do cur = cur + (w.b[o + i] or 0) * 256 ^ i end
    local mask = lshift(1, f.width) - 1
    local val
    if f.bool then val = (v == true or (type(v) == "number" and v ~= 0)) and 1 or 0
    else val = band(math.floor(tonumber(v) or 0), mask) end
    local cleared = band(cur, bnot(lshift(mask, f.shift)))
    local out = bor(cleared, lshift(val, f.shift))
    if f.of == "u32" then out = out % 4294967296 end
    put(w, o, f.of, out)
  elseif f.t == "text" then
    w:bytes(o, codec.encodeString(v, f.len, f.pad or 0xFF))
  elseif f.t == "struct" then
    Structs.write(w, o, f.spec, type(v) == "table" and v or {}, codec)
  else
    put(w, o, f.t, v)
  end
end

function writeField(w, base, f, tbl, codec)
  local o = base + f.off
  local v = tbl[f.name]
  if not f.n then return writeOne(w, o, f, v, codec) end
  local stride = elementStride(f)
  local list = type(v) == "table" and v or {}
  eachIndex(f, function(i, j, k)
    local e
    if j then e = type(list[i]) == "table" and list[i][j] or nil else e = list[i] end
    writeOne(w, o + k * stride, f, e, codec)
  end)
end

function Structs.write(w, base, spec, tbl, codec)
  tbl = type(tbl) == "table" and tbl or {}
  for _, f in ipairs(spec) do
    if f.name then writeField(w, base, f, tbl, codec) end
  end
end

return Structs
