local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Writer = require("src.import.LuaWriter")
local M = {SUB = "decorations", FILES = {"decorations.lua"}, packVersion = 1}
M.REQUIRED = K.required(M.SUB, M.FILES)
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local data = require("src.import.gba.rs.decorations_data").read(c)
  data.layout, data.assetLayout, data.build, data.packVersion = "rs", "rs", require("src.import.gba.versions").BUILD, M.packVersion
  c:write("decorations.lua", Writer.encode(data))
  return A.finish(c, {screen = "decorations", packVersion = M.packVersion, count = data.count,
    inventory = c:path("decorations.lua"), nativeIcons = false})
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  return cache:exists(base .. "decorations.lua") and cache:read(base .. "manifest.lua"):find("packVersion = " .. M.packVersion, 1, true) ~= nil
end
return M
