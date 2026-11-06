local A = require("src.import.gba.rs.assets")
local V = require("src.import.gba.versions")
local Base = require("src.import.gba.battle_transition_extract")
local M = {REQUIRED = Base.REQUIRED}
function M.run(rom, cache, opts)
  local result = Base.run(rom, cache, opts)
  local path = (opts and opts.cacheRoot or "data/generated/gba") .. "/pokemon/battle_transition/manifest.lua"
  local chunk = assert(load(assert(cache:read(path)), "=rs_transition", "t", {}))
  local data = chunk()
  data.assetLayout, data.build, data.gameLayout = "rs", V.BUILD, "rs"
  assert(cache:write(path, require("src.import.LuaWriter").encode(data)))
  return result
end
function M.ready(cache, root)
  return Base.ready(cache, root) and A.ready("pokemon/battle_transition", cache, root)
end
return M
