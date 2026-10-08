local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/rs_tv", FILES = {}, REQUIRED = {"rse/rs_tv/manifest.lua"}}
-- pokeruby/tv.c:89
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  assert(c.S.count("gPokeOutbreakSpeciesList", 12) == 5, "native RS outbreak count")
  local base, rows = c:off("gPokeOutbreakSpeciesList"), {}
  for i = 0, 4 do
    local at = base + i * 12
    rows[i + 1] = {species = c:u16(at), moves = {c:u16(at + 2), c:u16(at + 4), c:u16(at + 6), c:u16(at + 8)},
      level = c:u8(at + 10), location = c:u8(at + 11)}
  end
  return A.finish(c, {screen = "tv", layout = "rs", outbreakSpecies = rows,
    coverage = "native_rs_outbreak_rows", source = "gPokeOutbreakSpeciesList"})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
