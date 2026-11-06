-- Pret-faithful FRLG map palette system (13 BG slots × 16 BGR555).

local Tileset = require("src.import.gba.tileset")
local NativePack = require("src.import.gba.native_pack")

local Palette = {}

Palette.NUM_PALS_IN_PRIMARY = Tileset.NUM_PALS_IN_PRIMARY -- 7
Palette.NUM_PALS_TOTAL = Tileset.NUM_PALS_TOTAL           -- 13

--- Load palettes.bin → BGR555 map (0..15).
function Palette.loadBgr555(blob)
  return NativePack.decodePalettes(blob)
end

--- Load → RGB8 tables { [slot] = { [c] = {r,g,b} } }.
function Palette.load(blob)
  local bgr, err = Palette.loadBgr555(blob)
  if not bgr then return nil, err end
  assert((bgr[0] and bgr[0][0] or -1) == 0, "pret: mapPals[0][0] must be black")
  return NativePack.palsToRgb8(bgr), bgr
end

local bit = require("bit")
local band, bor, bxor, bnot = bit.band, bit.bor, bit.bxor, bit.bnot
local lshift, rshift, rol, tobit = bit.lshift, bit.rshift, bit.rol, bit.tobit

local MD5_K, MD5_S = {}, {
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
}
for i = 0, 63 do
  MD5_K[i + 1] = math.floor(math.abs(math.sin(i + 1)) * 4294967296) % 4294967296
end

local function md5hex(msg)
  local len = #msg
  local padLen = (55 - len) % 64
  msg = msg .. "\128" .. string.rep("\0", padLen)
    .. string.char(
      (len * 8) % 256, math.floor(len * 8 / 256) % 256,
      math.floor(len * 8 / 65536) % 256, math.floor(len * 8 / 16777216) % 256,
      0, 0, 0, 0)
  local a0, b0, c0, d0 = 0x67452301, tobit(0xefcdab89), tobit(0x98badcfe), 0x10325476
  local M = {}
  for off = 1, #msg, 64 do
    for j = 0, 15 do
      local b1, b2, b3, b4 = msg:byte(off + j * 4, off + j * 4 + 3)
      M[j] = bor(b1, lshift(b2, 8), lshift(b3, 16), lshift(b4, 24))
    end
    local A, B, C, D = a0, b0, c0, d0
    for i = 0, 63 do
      local F, g
      if i < 16 then
        F = bor(band(B, C), band(bnot(B), D)); g = i
      elseif i < 32 then
        F = bor(band(D, B), band(bnot(D), C)); g = (5 * i + 1) % 16
      elseif i < 48 then
        F = bxor(B, C, D); g = (3 * i + 5) % 16
      else
        F = bxor(C, bor(B, bnot(D))); g = (7 * i) % 16
      end
      F = tobit(F + A + MD5_K[i + 1] + M[g])
      A = D; D = C; C = B
      B = tobit(B + rol(F, MD5_S[i + 1]))
    end
    a0, b0, c0, d0 = tobit(a0 + A), tobit(b0 + B), tobit(c0 + C), tobit(d0 + D)
  end
  local out = {}
  for _, v in ipairs({ a0, b0, c0, d0 }) do
    for k = 0, 3 do out[#out + 1] = string.format("%02x", band(rshift(v, k * 8), 255)) end
  end
  return table.concat(out)
end

Palette._md5hex = md5hex

--- Stable hash of BGR555 pals (+ optional extraBlob) for RGBA disk cache keys.
function Palette.hash(bgrPals, extraBlob)
  local parts = {}
  for p = 0, Palette.NUM_PALS_TOTAL - 1 do
    local colors = bgrPals[p] or bgrPals[0] or {}
    for c = 0, 15 do
      parts[#parts + 1] = string.format("%04x", (colors[c] or 0) % 65536)
    end
  end
  if extraBlob and type(extraBlob) == "string" then
    parts[#parts + 1] = extraBlob
  end
  local s = table.concat(parts)
  if love and love.data and love.data.hash then
    return (love.data.encode("string", "hex", love.data.hash("md5", s)):sub(1, 16))
  end
  return md5hex(s):sub(1, 16)
end

--- Identity tint hook (weather / time later).
function Palette.tint(rgbPals, _kind)
  return rgbPals
end

return Palette
