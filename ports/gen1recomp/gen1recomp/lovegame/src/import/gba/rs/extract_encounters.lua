local Base = require("src.import.gba.encounters_extract")
local A = require("src.import.gba.rs.assets")
local V = require("src.import.gba.versions")
local M = {REQUIRED = {"encounters.lua", "wild_extra.lua"}}
function M.run(rom, cache, opts)
  local result = Base.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, "")
  -- pokeruby/src/wild_encounter.c:23
  local m, s = c:off("gWildFeebasRoute119Data"), c:off("gRoute119WaterTileData")
  local sections = {}
  for i = 0, c.S.count("gRoute119WaterTileData", 6) - 1 do
    local b = s + i * 6
    sections[#sections + 1] = {yMin = c:u16(b), yMax = c:u16(b + 2), spotBase = c:u16(b + 4)}
  end
  local root = opts and opts.cacheRoot or "data/generated/gba"
  assert(cache:write(root .. "/wild_extra.lua", require("src.import.LuaWriter").encode({
    assetLayout = "rs", build = V.BUILD, headerSets = {}, alteringCaveHeldItems = {},
    feebas = {mon = {minLevel = c:u8(m), maxLevel = c:u8(m + 1), species = c:u16(m + 2)}, sections = sections}})))
  return result
end
function M.ready(cache, root)
  root = root or "data/generated/gba"
  local s = cache:read(root .. "/wild_extra.lua")
  return Base.ready(cache, root) and s and s:find('assetLayout = "rs"', 1, true) ~= nil
    and s:find('build = "' .. V.BUILD .. '"', 1, true) ~= nil
end
return M
