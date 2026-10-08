local M = {}
local function num(v) return tonumber(v) or 0 end
local function u16(s, off) return s:byte(off + 1) + s:byte(off + 2) * 256 end
local function bytes(s, off, size)
  local out = {}
  for i = 1, size do out[i] = s:byte(off + i) end
  return out
end
-- pokeruby/include/global.h:595
function M.section()
  return { name = "recordMixingGift", fields = {"recordMixingGift"},
    read = function(x)
      local off = x.L.RSE.sb1.recordMixingGift
      return {recordMixingGift = {checksum = u16(x.sb1, off) + u16(x.sb1, off + 2) * 65536,
        unk0 = x.sb1:byte(off + 5), quantity = x.sb1:byte(off + 6), itemId = u16(x.sb1, off + 6),
        filler4 = bytes(x.sb1, off + 8, 8), nativeBytes = bytes(x.sb1, off, 16)}}
    end,
    write = function(x, v)
      local off, g = x.L.RSE.sb1.recordMixingGift, v.recordMixingGift
      if type(g) ~= "table" then return end
      if type(g.nativeBytes) == "table" and #g.nativeBytes == 16 then
        for i = 1, 16 do x.w1:w8(off + i - 1, num(g.nativeBytes[i])) end
      end
      x.w1:w32(off, num(g.checksum)); x.w1:w8(off + 4, num(g.unk0))
      x.w1:w8(off + 5, num(g.quantity)); x.w1:w16(off + 6, num(g.itemId))
      if type(g.filler4) == "table" then
        for i = 1, 8 do x.w1:w8(off + 7 + i, num(g.filler4[i])) end
      end
    end,
  }
end
return M
