local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/contest", FILES = {}, REQUIRED = {"rse/contest/manifest.lua"}}
local function fixed(c, off, n)
  local t = {}; for i = 0, n - 1 do t[i + 1] = c:u8(off + i) end; return t
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local winners, off = {}, c:off("gDefaultContestWinners")
  for i = 0, c.S.count("gDefaultContestWinners", 32) - 1 do
    local b = off + i * 32
    winners[i] = {personality = c:u32(b), trainerId = c:u32(b + 4), species = c:u16(b + 8),
      contestCategory = c:u8(b + 10), monName = fixed(c, b + 11, 11), trainerName = fixed(c, b + 22, 8)}
  end
  return A.finish(c, {screen = "contest", defaultWinners = winners, coverage = "native_default_winners"})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
