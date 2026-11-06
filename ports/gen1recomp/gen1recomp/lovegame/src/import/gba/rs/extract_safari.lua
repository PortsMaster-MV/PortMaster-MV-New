local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Base = require("src.import.gba.rse.safari_rse_extract")
local Writer = require("src.import.LuaWriter")
local Versions = require("src.import.gba.versions")

local M = {SUB = "safari", FILES = {"rse_tables.lua"}, safariVersion = 1}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function config(c)
  local function tableOffset(symbol, bytes)
    assert(c.S.size(symbol) >= bytes, "native Safari table extent: " .. symbol)
    return c:off(symbol)
  end
  return {
    pkblToEscape = tableOffset("gUnknown_081FA70C", 15), pkblToEscapeSize = 15,
    goNearCatch = tableOffset("gUnknown_081FA71B", 4), goNearCatchSize = 4,
    goNearEscape = tableOffset("gUnknown_081FA71F", 4), goNearEscapeSize = 4,
    -- pokeruby/src/pokeblock.c:94
    -- pokemon_3.c:1245
    flavorCompat = tableOffset("gPokeblockFlavorCompatibilityTable", 125), flavorCompatSize = 125,
  }
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local data = Base.extract(rom, config(c))
  data.layout, data.assetLayout, data.build = "rs", "rs", Versions.BUILD
  data.safariVersion = M.safariVersion
  c:write("rse_tables.lua", Writer.encode(data))
  return A.finish(c, {
    screen = "safari", safariVersion = M.safariVersion,
    tables = c:path("rse_tables.lua"),
    dimensions = {pokeblockRows = 5, pokeblockColumns = 3, goNear = 4, natures = 25, flavors = 5},
    sources = {pokeblock = "gUnknown_081FA70C", goNearCatch = "gUnknown_081FA71B",
      goNearEscape = "gUnknown_081FA71F", flavorCompatibility = "gPokeblockFlavorCompatibilityTable"},
  })
end

function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  local body = cache:read(base .. "manifest.lua")
  return body:find("safariVersion = " .. M.safariVersion, 1, true) ~= nil
    and cache:exists(base .. "rse_tables.lua")
end

return M
