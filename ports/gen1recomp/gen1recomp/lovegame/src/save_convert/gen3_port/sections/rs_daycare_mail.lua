local M = {}
local function bytes(s, first, size)
  local out = {}
  for i = 1, size do out[i] = s:byte(first + i) end
  return out
end
local function raw(t, size)
  if type(t) ~= "table" or #t ~= size then return end
  local out = {}
  for i = 1, size do
    local value = tonumber(t[i])
    if not value or value < 0 or value > 255 or value % 1 ~= 0 then return end
    out[i] = string.char(value)
  end
  return table.concat(out)
end
local function u16(s, off) return s:byte(off + 1) + s:byte(off + 2) * 256 end
local function u32(s, off) return u16(s, off) + u16(s, off + 2) * 65536 end

-- pokeruby/include/global.h:556
function M.read(s, codec)
  assert(#s == 56, "native RS daycare mail must be 56 bytes")
  local message = {words = {}, _rsNativeBytes = bytes(s, 0, 36)}
  for i = 1, 9 do message.words[i] = u16(s, (i - 1) * 2) end
  message.playerName = codec.decodeString(s, 18, 8):gsub(" +$", "")
  message.trainerIdRaw = u32(s, 26)
  message.trainerId = message.trainerIdRaw % 65536
  message.species, message.itemId = u16(s, 30), u16(s, 32)
  return {message = message, otName = codec.decodeString(s, 36, 8),
    monName = codec.decodeString(s, 44, 11), _rsNativeBytes = bytes(s, 0, 56)}
end

function M.render(codec, template, mail, writeMail)
  local own = type(mail) == "table" and raw(mail._rsNativeBytes, 56)
  template = own or template or string.rep("\0", 56)
  local w = codec.newBuf(56, template)
  if type(mail) ~= "table" then w:w16(32, 0); return w:str() end
  writeMail(w, 0, mail.message)
  for _, field in ipairs({{"otName", 36, 8}, {"monName", 44, 11}}) do
    local name = tostring(mail[field[1]] or "")
    if codec.decodeString(template, field[2], field[3]) ~= name then
      w:bytes(field[2], codec.encodeString(name, field[3]))
    end
  end
  return w:str()
end
return M
