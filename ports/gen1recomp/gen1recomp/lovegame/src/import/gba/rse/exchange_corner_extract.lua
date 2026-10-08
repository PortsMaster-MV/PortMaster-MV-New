local Versions = require("src.import.gba.versions")
local M = {}

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = (opts.cacheRoot or "data/generated/gba") .. "/frontier_exchange_corner"
  local data = assert(Versions.FRONTIER_EXCHANGE_CORNER, "Exchange Corner symbols unavailable")
  for name, entry in pairs(data) do
    local bytes = {}
    for i = 0, entry.count * 2 - 1 do bytes[#bytes + 1] = string.char(rom:get(entry.off + i)) end
    assert(cache:write(root .. "/" .. name .. ".bin", table.concat(bytes)))
  end
  assert(cache:write(root .. "/manifest.lua", "return { format_version = 1, game = 'emerald' }\n"))
  return { root = root }
end

return M
