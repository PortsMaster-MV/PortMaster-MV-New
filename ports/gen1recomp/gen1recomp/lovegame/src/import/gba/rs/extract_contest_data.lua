local A = require("src.import.gba.rs.assets")
local Disasm = require("src.core.game3.rse.contest_ai_disasm")
local M = {SUB = "rse/contest_data", FILES = {}, REQUIRED = {"rse/contest_data/manifest.lua"}}
local BASE = 0x08000000

local function fixed(c, off, n)
  local out = {}; for i = 0, n - 1 do out[i + 1] = c:u8(off + i) end; return out
end
local function textTable(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 4) - 1 do
    local p, bytes = assert(c:ptr(off + i * 4)), {}
    for j = 0, 1023 do
      local v = c:u8(p + j); bytes[#bytes + 1] = v
      if v == 255 then break end
    end
    assert(bytes[#bytes] == 255, "native contest text terminator")
    out[i] = {bytes = bytes}
  end
  return out
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local opponents, filters, off = {}, {}, c:off("gContestOpponents")
  -- pokeruby/include/contest.h:246
  local count = c.S.count("gContestOpponents", 64)
  for i = 0, count - 1 do
    local b = off + i * 64
    local pool = c:u8(b + 28)
    opponents[i] = {species = c:u16(b), nickname = fixed(c, b + 2, 11),
      trainerName = fixed(c, b + 13, 8), trainerGfxId = c:u8(b + 21), aiFlags = c:u32(b + 24),
      whichRank = pool % 4, aiPool = {}, moves = {},
      cool = c:u8(b + 38), beauty = c:u8(b + 39), cute = c:u8(b + 40),
      smart = c:u8(b + 41), tough = c:u8(b + 42), sheen = c:u8(b + 43),
      nativeScratch = fixed(c, b + 44, 12), personality = c:u32(b + 56), otId = c:u32(b + 60)}
    for cat, key in ipairs({"cool", "beauty", "cute", "smart", "tough"}) do
      opponents[i].aiPool[key] = math.floor(pool / 2 ^ (cat + 1)) % 2 == 1
    end
    for j = 0, 3 do opponents[i].moves[j + 1] = c:u16(b + 30 + j * 2) end
    filters[i] = 0
  end
  local combo, excitement = {}, {}
  off = c:off("gComboStarterLookupTable")
  for i = 0, c.S.size("gComboStarterLookupTable") - 1 do combo[i] = c:u8(off + i) end
  off = c:off("gContestExcitementTable")
  for i = 0, 4 do
    excitement[i] = {}; for j = 0, 4 do excitement[i][j] = c:s8(off + i * 5 + j) end
  end
  off = c:off("gContestAIs")
  local entries, roots = {}, {}
  for i = 0, 31 do entries[i] = c:u32(off + i * 4); roots[#roots + 1] = entries[i] end
  local function read(addr) return rom:get(addr - BASE) end
  local walk = Disasm.walk(read, roots, function(a) return a >= BASE and a < BASE + 0x1000000 end)
  local hex = {}
  for addr = walk.lo, walk.hi - 1 do hex[#hex + 1] = string.format("%02x", read(addr)) end
  return A.finish(c, {screen = "contest_data", opponents = opponents, opponentCount = count,
    postgameFilter = filters, comboStarterLookup = combo, excitementTable = excitement,
    ai = {base = walk.lo, size = walk.hi - walk.lo, entries = entries,
      blob = table.concat(hex), instructions = #walk.order},
    appealResultTexts = textTable(c, "gUnknown_083CC188"),
    roundResultTexts = textTable(c, "gContestStandOutStrings"),
    conditionTexts = textTable(c, "gContestCategoryStrings"),
    invalidMoveNames = textTable(c, "sInvalidContestMoveNames")})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
