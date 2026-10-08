local CacheBlob = {}

CacheBlob.LEVEL = 6
CacheBlob.DERIVED_LEVEL = 1

local PACKED = { rgba = true, idx = true }

local function extension(rel)
  return type(rel) == "string" and rel:match("%.([^./\\]+)$") or nil
end

function CacheBlob.packs(rel)
  local ext = extension(rel)
  return ext ~= nil and PACKED[ext] == true
end

local loveData
local function loveBackend()
  if loveData ~= nil then return loveData end
  loveData = false
  local L = rawget(_G, "love")
  if L and not (L.data and L.data.compress) then pcall(require, "love.data") end
  if L and L.data and L.data.compress and L.data.decompress then loveData = L.data end
  return loveData
end

local zlib
local function ffiBackend()
  if zlib ~= nil then return zlib end
  zlib = false
  local okF, ffi = pcall(require, "ffi")
  if not okF then return zlib end
  pcall(ffi.cdef, [[
    unsigned long compressBound(unsigned long sourceLen);
    int compress2(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen, int level);
    int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
  ]])
  for _, name in ipairs(ffi.os == "Windows" and { "zlib1", "z" } or { "z", "libz.so.1" }) do
    local okL, lib = pcall(ffi.load, name)
    if okL and lib and pcall(function() return lib.uncompress end) then
      zlib = { ffi = ffi, lib = lib }
      break
    end
  end
  return zlib
end

function CacheBlob.deflate(raw, level)
  level = level or CacheBlob.LEVEL
  local L = loveBackend()
  if L then return L.compress("string", "zlib", raw, level) end
  local Z = assert(ffiBackend(), "CacheBlob: no zlib backend (love.data or libz)")
  local ffi = Z.ffi
  local cap = tonumber(Z.lib.compressBound(#raw))
  local out = ffi.new("uint8_t[?]", cap)
  local len = ffi.new("unsigned long[1]", cap)
  local rc = Z.lib.compress2(out, len, raw, #raw, level)
  assert(rc == 0, "CacheBlob: compress2 failed (" .. tostring(rc) .. ")")
  return ffi.string(out, tonumber(len[0]))
end

function CacheBlob.inflate(z)
  local L = loveBackend()
  if L then return L.decompress("string", "zlib", z) end
  local Z = assert(ffiBackend(), "CacheBlob: no zlib backend (love.data or libz)")
  local ffi = Z.ffi
  local cap = math.max(4096, #z * 16)
  while true do
    local out = ffi.new("uint8_t[?]", cap)
    local len = ffi.new("unsigned long[1]", cap)
    local rc = Z.lib.uncompress(out, len, z, #z)
    if rc == 0 then return ffi.string(out, tonumber(len[0])) end
    assert(rc == -5, "CacheBlob: uncompress failed (" .. tostring(rc) .. ")")
    cap = cap * 4
  end
end

function CacheBlob.encode(rel, bytes)
  if type(bytes) ~= "string" or not CacheBlob.packs(rel) then return bytes end
  return CacheBlob.deflate(bytes, rel:find("/atlas_", 1, true) and CacheBlob.DERIVED_LEVEL or CacheBlob.LEVEL)
end

function CacheBlob.decode(rel, bytes)
  if type(bytes) ~= "string" or not CacheBlob.packs(rel) then return bytes end
  local ok, raw = pcall(CacheBlob.inflate, bytes)
  if not ok then error("cache blob " .. tostring(rel) .. " is not deflated (stale cache, reimport): " .. tostring(raw), 2) end
  return raw
end

function CacheBlob.readFs(rel)
  if not (love and love.filesystem and love.filesystem.read) then return nil end
  local bytes = love.filesystem.read(rel)
  return CacheBlob.decode(rel, bytes)
end

return CacheBlob
