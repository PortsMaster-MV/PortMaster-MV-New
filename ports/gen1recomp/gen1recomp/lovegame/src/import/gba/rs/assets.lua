local K = require("src.import.gba.rse.boot_gfx")
local V = require("src.import.gba.versions")
local M = {}
function M.context(rom, cache, opts, sub)
  assert(rom.id == "ruby" or rom.id == "sapphire", "RS assets require a native Ruby/Sapphire ROM")
  return K.contextWith(rom, cache, opts or {}, sub, V.SYMS, rom.id)
end
function M.finish(c, data)
  data.layout, data.assetLayout, data.build = data.layout or "rs", "rs", V.BUILD
  return true, c:finish(data)
end
function M.ready(sub, cache, root)
  if not K.ready(sub, cache, root) then return false end
  local body = cache:read((root or "data/generated/gba") .. "/" .. sub .. "/manifest.lua")
  return body:find('assetLayout = "rs"', 1, true) ~= nil and body:find('build = "' .. V.BUILD .. '"', 1, true) ~= nil
end
function M.text(c, off)
  local bytes = {}
  for i = 0, 1023 do
    local b = c:u8(off + i); bytes[#bytes + 1] = b
    if b == 255 then
      local IR = require("src.core.game3.scripting.text_ir")
      return IR.toAscii(IR.decode(bytes, { dialect = "rs" }))
    end
  end
  error("RS text is unterminated")
end
function M.pairs(c, name, signed)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 2 - 1 do
    out[i + 1] = signed and {c:s8(off + i * 2), c:s8(off + i * 2 + 1)} or {c:u8(off + i * 2), c:u8(off + i * 2 + 1)}
  end
  return out
end
function M.affine(c, name)
  return M.affineAt(c, c:off(name), c.S.count(name, 8))
end
function M.affineAt(c, off, count)
  local out = {}
  for i = 0, count - 1 do
    local o = off + i * 8
    local x = c:s16(o)
    if x == 0x7FFF then out[#out + 1] = {op = "end"}; break end
    if x == 0x7FFE then out[#out + 1] = {op = "jump", target = c:u16(o + 2)}
    elseif x == 0x7FFD then out[#out + 1] = {op = "loop", count = c:u16(o + 2)}
    else out[#out + 1] = {op = "frame", xScale = x, yScale = c:s16(o + 2), rotation = c:s8(o + 4), duration = c:u8(o + 5)} end
  end
  return out
end
return M
