local M = {}
local function u16(s, off) return s:byte(off + 1) + s:byte(off + 2) * 256 end
local function raw(s, off, n) local t = {}; for i = 1, n do t[i] = s:byte(off + i) end; return t end
function M.section()
  return {name = "linkBattleRecords", fields = {"linkBattleRecords"},
    read = function(x)
      local lr, out = x.L.LINK_BATTLE_RECORDS, {}
      local s = lr.block == "sb1" and x.sb1 or x.sb2
      for i = 0, lr.count - 1 do
        local b = lr.off + i * lr.size
        out[i + 1] = {nativeSlot = i, name = x.codec.decodeString(s, b, 8),
          nameBytes = raw(s, b, 8), nativeBytes = raw(s, b, lr.size), trainerId = u16(s, b + 8),
          wins = u16(s, b + 10), losses = u16(s, b + 12), draws = u16(s, b + 14)}
      end
      return {linkBattleRecords = out}
    end,
    write = function(x, v)
      local lr, rows = x.L.LINK_BATTLE_RECORDS, v.linkBattleRecords or {}
      local w = lr.block == "sb1" and x.w1 or x.w2
      local slots, hasSlots = {}, false
      for _, row in pairs(rows) do
        if type(row) == "table" and row.nativeSlot ~= nil then hasSlots = true; slots[tonumber(row.nativeSlot)] = row end
      end
      for i = 0, lr.count - 1 do
        local b, row = lr.off + i * lr.size, hasSlots and slots[i] or rows[i + 1]
        if hasSlots and not slots[i] then row = nil end
        w:fill(b, lr.size, 0)
        if type(row) ~= "table" then w:w8(b, 255)
        else
          if type(row.nativeBytes) == "table" and #row.nativeBytes == lr.size then
            for j = 1, lr.size do w:w8(b + j - 1, row.nativeBytes[j]) end
          end
          local name = tostring(row.name or "")
          if type(row.nameBytes) == "table" and #row.nameBytes == 8 then
            local bytes = {}; for j = 1, 8 do bytes[j] = string.char(row.nameBytes[j]) end
            local nativeName = table.concat(bytes)
            if x.codec.decodeString(nativeName, 0, 8) == name then w:bytes(b, nativeName)
            else w:bytes(b, x.codec.encodeString(name, 8)) end
          elseif name ~= "" then w:bytes(b, x.codec.encodeString(name, 8))
          else w:w8(b, 255) end
          for j, key in ipairs({"trainerId", "wins", "losses", "draws"}) do w:w16(b + 6 + j * 2, tonumber(row[key]) or 0) end
        end
      end
    end}
end
return M
