local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Catalog = require("src.import.gba.rs.asset_catalog")
local M = { SUB = "rs/assets", REQUIRED = {"rs/assets/manifest.lua"} }
for _, spec in ipairs(Catalog) do
  local stem = M.SUB .. "/" .. spec.group .. "__" .. spec.symbol:gsub("[^%w_]", "_")
  M.REQUIRED[#M.REQUIRED + 1] = stem .. ".rom"
  if spec.lz then M.REQUIRED[#M.REQUIRED + 1] = stem .. ".bin" end
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local rows, groups = {}, {}
  for _, spec in ipairs(Catalog) do
    local stem = spec.group .. "__" .. spec.symbol:gsub("[^%w_]", "_")
    local raw = c:raw(spec.symbol)
    assert(#raw == c.S.size(spec.symbol), "RS asset source was truncated: " .. spec.symbol)
    local row = { symbol = spec.symbol, source = spec.source, paths = spec.paths, group = spec.group,
      romOffset = c:off(spec.symbol), romBytes = #raw, raw = c:write(stem .. ".rom", raw) }
    if spec.lz then
      local decoded = c:lz(spec.symbol)
      row.bytes, row.data, row.encoding = #decoded, c:write(stem .. ".bin", decoded), "lz77"
    else row.bytes, row.data, row.encoding = #raw, row.raw, "raw" end
    rows[#rows + 1] = row
    groups[spec.group] = (groups[spec.group] or 0) + 1
  end
  return A.finish(c, {screen = "native_content_assets", count = #rows, groups = groups, assets = rows})
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local body = cache:read((root or "data/generated/gba") .. "/" .. M.SUB .. "/manifest.lua")
  local f = load(body, "=rs_assets", "t", {})
  local ok, m = pcall(f or error)
  if not ok or m.count ~= #Catalog then return false end
  for _, rel in ipairs(m.files or {}) do if not cache:exists(rel) then return false end end
  return true
end
return M
