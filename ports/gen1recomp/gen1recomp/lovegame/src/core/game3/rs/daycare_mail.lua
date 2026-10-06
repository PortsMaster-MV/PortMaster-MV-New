local M = {}
local LENGTHS = {1, 2, 2, 2, 4, 2, 2, 1, 2, 1, 1, 3, 2, 2, 2, 1, 3, 2, 2, 2, 2, 1, 1}
local function codec(session) return require("src.save_convert.Gen3Save").forVersion(session.version) end
local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}; for k, v in pairs(t) do out[k] = copy(v) end; return out
end
local function bytes(s) return {s:byte(1, -1)} end
local function raw(a) return string.char(unpack(a)) end
function M.strip(a)
  local out, i = {}, 1
  while i <= #a and a[i] ~= 255 do
    if a[i] == 252 then i = i + 1 + (LENGTHS[(a[i + 1] or 0) + 1] or 0)
    else out[#out + 1], i = a[i], i + 1 end
  end
  return out
end
local function encoded(session, text, n) return bytes(codec(session).encodeString(text or "", n, 255)) end
local function slice(a, first, n)
  local out = {}; for i = 1, n do out[i] = a[first + i - 1] end; return out
end
local function nickname(session, mon)
  local x = mon and mon.cartExtra
  if x and type(x.nicknameBytes) == "table" then return copy(x.nicknameBytes) end
  if x and type(x.nicknameRaw) == "table" then return copy(x.nicknameRaw) end
  return encoded(session, require("src.core.game3.daycare").nickname(mon), 11)
end
local function text(session, a)
  return codec(session).decodeString(raw(a), 0, #a)
end
local function equal(a, b) return raw(M.strip(a)) == raw(M.strip(b)) end

-- daycare.c:117
function M.afterDeposit(session, mon, record, slot, previous)
  if not record then return end
  local D = require("src.core.game3.daycare")
  local dc = D.stateOf(session)
  local mail = dc.mail[slot]
  mail.message = copy(record)
  local template = previous and copy(previous._rsNativeBytes) or {}
  for i = 1, 56 do if template[i] == nil then template[i] = 0 end end
  if record._rsNativeBytes then for i = 1, 36 do template[i] = record._rsNativeBytes[i] end end
  local player = M.strip(encoded(session, session.name or session.playerName, 8))
  while #player < 6 do player[#player + 1], player[#player + 2] = 252, 7 end
  player[#player + 1] = 255
  local nick = nickname(session, mon)
  for i, v in ipairs(player) do template[36 + i] = v; if v == 255 then break end end
  for i, v in ipairs(nick) do template[44 + i] = v; if v == 255 then break end end
  mail._rsNativeBytes = template
  mail.otName = text(session, slice(template, 37, 8))
  mail.monName = text(session, slice(template, 45, 11))
end

-- daycare.c:293
function M.clear(session, mail)
  local t = copy(mail._rsNativeBytes) or {}
  for i = 1, 56 do if t[i] == nil then t[i] = 0 end end
  for i = 1, 26 do t[i] = 255 end
  for i = 27, 34 do t[i] = 0 end
  t[31] = 1
  for i = 37, 55 do t[i] = 0 end
  mail.message = require("src.core.game3.mail").clear(mail.message)
  mail.message.trainerIdRaw = 0
  mail.message._rsNativeBytes = slice(t, 1, 36)
  mail._rsNativeBytes = t
  mail.otName, mail.monName = text(session, slice(t, 37, 8)), text(session, slice(t, 45, 11))
end

-- egg_hatch.c:310
function M.received(session, mon, mail)
  if not (mon and mail and mail.message and (tonumber(mail.message.itemId) or 0) ~= 0) then return false end
  local t = mail._rsNativeBytes
  local player = t and slice(t, 37, 8) or encoded(session, mail.otName, 8)
  local nick = t and slice(t, 45, 11) or encoded(session, mail.monName, 11)
  if equal(nickname(session, mon), nick) and equal(encoded(session, session.name or session.playerName, 8), player) then return false end
  local length = 0
  for _, v in ipairs(player) do if v == 255 then break end; length = length + 1 end
  local sanitized = M.strip(player)
  local name = text(session, sanitized)
  if length < 6 then name = "{JPN}" .. name .. "{ENG}" end
  return true, require("src.core.game3.daycare").nickname(mon), name, text(session, nick)
end
return M
