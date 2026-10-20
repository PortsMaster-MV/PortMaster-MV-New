local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")

local ContestMovesExtract = {}

ContestMovesExtract.FORMAT_VERSION = 1
ContestMovesExtract.CACHE_FILE = "pokemon/contest_moves.lua"
ContestMovesExtract.REQUIRED = { ContestMovesExtract.CACHE_FILE }

local function text_at(rom, ptr, maxLen)
  local off = rom:ptrOffset(ptr)
  if not off then return nil end
  local bytes = {}
  for i = 0, (maxLen or 256) - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = TextIR.dialectOf() }), {})
end

function ContestMovesExtract.available()
  return Versions.CONTEST_MOVES ~= nil
end

-- pokeemerald/include/contest_effect.h:4, pokeemerald/src/data/contest_moves.h:1
function ContestMovesExtract.extract(rom)
  local moves = {}
  for id = 0, Versions.CONTEST_MOVES_COUNT - 1 do
    local off = Versions.CONTEST_MOVES + id * Versions.CONTEST_MOVE_STRIDE
    local combo = {}
    for i = 0, 3 do combo[i + 1] = rom:get(off + 3 + i) end
    moves[id] = {
      effect = rom:get(off),
      category = rom:get(off + 1) % 8,
      comboStarterId = rom:get(off + 2),
      comboMoves = combo,
    }
  end
  local effects = {}
  for id = 0, Versions.CONTEST_EFFECTS_COUNT - 1 do
    local off = Versions.CONTEST_EFFECTS + id * Versions.CONTEST_EFFECT_STRIDE
    local desc
    if id < Versions.CONTEST_EFFECT_DESCRIPTION_COUNT then
      desc = text_at(rom, rom:u32(Versions.CONTEST_EFFECT_DESCRIPTIONS + id * 4))
    end
    effects[id] = {
      effectType = rom:get(off),
      appeal = rom:get(off + 1),
      jam = rom:get(off + 2),
      description = desc or "",
    }
  end
  local categories = {}
  for id = 0, Versions.CONTEST_CATEGORY_COUNT - 1 do
    categories[id] = text_at(rom, rom:u32(Versions.CONTEST_CATEGORY_NAMES + id * 4), 16) or ""
  end
  return {
    version = ContestMovesExtract.FORMAT_VERSION,
    count = Versions.CONTEST_MOVES_COUNT,
    moves = moves,
    effects = effects,
    categories = categories,
  }
end

function ContestMovesExtract.run(rom, cache, opts)
  opts = opts or {}
  if not ContestMovesExtract.available() then return { skipped = true } end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local pack = ContestMovesExtract.extract(rom)
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. ContestMovesExtract.CACHE_FILE
  cache:write(rel, "return " .. serialize(pack) .. "\n")
  return { path = rel, count = pack.count }
end

function ContestMovesExtract.ready(cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. ContestMovesExtract.CACHE_FILE
  return (cache and cache.exists and cache:exists(rel)) and true or false
end

return ContestMovesExtract
