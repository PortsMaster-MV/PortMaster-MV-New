local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")

local BerriesExtract = {}

BerriesExtract.FORMAT_VERSION = 1
BerriesExtract.CACHE_FILE = "berries/berries.lua"
BerriesExtract.REQUIRED = { BerriesExtract.CACHE_FILE }

-- pokeemerald/charmap.txt:52
local POKEBLOCK_GLYPHS = { 0x55, 0x56, 0x57, 0x58, 0x59 }
local POKEBLOCK_TEXT = "POKéBLOCK"

local function decode_part(bytes)
  if #bytes == 0 then return "" end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = TextIR.dialectOf() }), {})
end

local function decode(bytes)
  local parts, cur, i = {}, {}, 1
  while i <= #bytes do
    local run = true
    for k = 1, #POKEBLOCK_GLYPHS do
      if bytes[i + k - 1] ~= POKEBLOCK_GLYPHS[k] then run = false break end
    end
    if run then
      parts[#parts + 1] = decode_part(cur) .. POKEBLOCK_TEXT
      cur = {}
      i = i + #POKEBLOCK_GLYPHS
    else
      cur[#cur + 1] = bytes[i]
      i = i + 1
    end
  end
  parts[#parts + 1] = decode_part(cur)
  return table.concat(parts)
end

local function name_at(rom, off, len)
  local bytes = {}
  for i = 0, len - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return decode(bytes)
end

local function text_at(rom, ptr, maxLen)
  local off = rom:ptrOffset(ptr)
  if not off then return nil end
  return name_at(rom, off, maxLen or 256)
end

function BerriesExtract.available()
  return Versions.BERRIES ~= nil
end

-- pokeemerald/include/global.berry.h:7, pokeemerald/src/berry.c:115
function BerriesExtract.extract(rom)
  local berries = {}
  for id = 0, Versions.BERRY_COUNT - 1 do
    local off = Versions.BERRIES + id * Versions.BERRY_STRIDE
    berries[id] = {
      name = name_at(rom, off, 7),
      firmness = rom:get(off + 7),
      size = rom:u16(off + 8),
      maxYield = rom:get(off + 10),
      minYield = rom:get(off + 11),
      description1 = text_at(rom, rom:u32(off + 12)) or "",
      description2 = text_at(rom, rom:u32(off + 16)) or "",
      stageDuration = rom:get(off + 20),
      spicy = rom:get(off + 21),
      dry = rom:get(off + 22),
      sweet = rom:get(off + 23),
      bitter = rom:get(off + 24),
      sour = rom:get(off + 25),
      smoothness = rom:get(off + 26),
    }
  end
  local pokeblockNames
  if Versions.POKEBLOCK_NAMES then
    pokeblockNames = {}
    -- pokeemerald/src/pokeblock.c:197
    for id = 0, Versions.POKEBLOCK_NAME_COUNT - 1 do
      pokeblockNames[id] = text_at(rom, rom:u32(Versions.POKEBLOCK_NAMES + id * 4), 32) or ""
    end
  end
  return {
    version = BerriesExtract.FORMAT_VERSION,
    count = Versions.BERRY_COUNT,
    berries = berries,
    pokeblockNames = pokeblockNames,
  }
end

function BerriesExtract.run(rom, cache, opts)
  opts = opts or {}
  if not BerriesExtract.available() then return { skipped = true } end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local pack = BerriesExtract.extract(rom)
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. BerriesExtract.CACHE_FILE
  cache:write(rel, "return " .. serialize(pack) .. "\n")
  return { path = rel, count = pack.count }
end

function BerriesExtract.ready(cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. BerriesExtract.CACHE_FILE
  return (cache and cache.exists and cache:exists(rel)) and true or false
end

return BerriesExtract
