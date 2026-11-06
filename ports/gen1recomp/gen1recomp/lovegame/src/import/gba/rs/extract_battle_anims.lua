local A = require("src.import.gba.rs.assets")
local V = require("src.import.gba.versions")
local Names = require("src.import.gba.rs.anim_names")
local Base = require("src.import.gba.battle_anim_extract")
local M = {REQUIRED = Base.REQUIRED}
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, "pokemon/battle_anims")
  local templates = {}
  for name in pairs(Names.templates) do
    local off = c:off(name)
    local row = c:readTemplate(name)
    local affine, tableOff = {}, c:ptr(off + 16)
    local tableSize = tableOff and c:sizedAt(tableOff, c.S.obj(name))
    if tableOff then
      assert(tableSize and tableSize % 4 == 0, "RS affine table has no exact symbol span: " .. name)
      for i = 0, tableSize / 4 - 1 do
        local p = assert(c:ptr(tableOff + i * 4))
        local size = assert(c:sizedAt(p, c.S.obj(name)), "RS affine command span: " .. name)
        affine[i + 1] = A.affineAt(c, p, size / 8)
      end
    end
    row.affineAnims, row.romOffset = affine, off
    row.images = nil
    templates[name] = row
  end
  local result = Base.run(rom, cache, opts)
  local path = c:path("pack.lua")
  local data = assert(load(assert(cache:read(path)), "=rs_battle_anims", "t", {}))()
  data.assetLayout, data.build, data.nativeTemplates = "rs", V.BUILD, templates
  assert(cache:write(path, require("src.import.LuaWriter").encode(data)))
  return result
end
function M.ready(cache, root)
  if not Base.ready(cache, root) then return false end
  local s = cache:read((root or "data/generated/gba") .. "/pokemon/battle_anims/pack.lua")
  return s and s:find('assetLayout = "rs"', 1, true) ~= nil and s:find('build = "' .. V.BUILD .. '"', 1, true) ~= nil
end
return M
