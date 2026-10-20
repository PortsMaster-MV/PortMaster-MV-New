local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/fan_club", FILES = {}, REQUIRED = {"rse/fan_club/manifest.lua"}}
function M.run(rom, cache, opts)
  local c, names = A.context(rom, cache, opts, M.SUB), {}
  for index, name in pairs({[0] = "Wallace", [1] = "Steven", [3] = "Winona", [4] = "Phoebe", [5] = "Glacia"}) do
    names[index] = A.text(c, c:off("gOtherText_" .. name))
  end
  return A.finish(c, {names = names})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
