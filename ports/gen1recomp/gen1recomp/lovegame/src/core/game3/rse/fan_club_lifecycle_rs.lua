local Rse = require("src.core.game3.rse.init")
local F = require("src.core.game3.rse.fan_club_rs")
local bit = rawget(_G, "bit") or require("bit")
local L = {}
local REMOVE = {8, 13, 14, 11, 10, 12, 15, 9}
local NAME_SOURCE = {[10] = {0, 3}, [11] = {0, 1}, [12] = {1, 0}, [13] = {0, 4}, [14] = {1, 5}}
local cached, source
local function packed(s) return Rse.var("VAR_FANCLUB_UNKNOWN_1", s) end
local function put(s, n) Rse.setVar("VAR_FANCLUB_UNKNOWN_1", bit.band(n, 0xFFFF), s) end
local function stamp(s, n) Rse.setVar("VAR_FANCLUB_UNKNOWN_2", math.floor(n) % 65536, s) end
function L.hours(s)
  local t = s.playTime or s.playtime
  return math.floor(tonumber(type(t) == "table" and t.hours or s.playTimeHours or s.hours) or 0) % 65536
end
function L.initialized(s) return bit.band(packed(s), 0x80) ~= 0 end
function L.setInitialized(s) put(s, bit.bor(packed(s), 0x80)) end
function L.isFan(s, member)
  member = math.floor(tonumber(member) or 0) % 65536
  if member >= 32 then return 0 end
  return bit.band(bit.rshift(packed(s), member), 1)
end
function L.newGameReset(s) put(s, 0); stamp(s, 0) end
function L.gameClear(s)
  if L.initialized(s) then return false end
  put(s, bit.bor(packed(s), 0x80, 0x2000, 0x100, 0x400))
  stamp(s, L.hours(s))
  for _, flag in ipairs({"FLAG_HIDE_FANCLUB_OLD_LADY", "FLAG_HIDE_FANCLUB_BOY", "FLAG_HIDE_FANCLUB_LITTLE_BOY", "FLAG_HIDE_FANCLUB_LADY"}) do
    Rse.setFlag(flag, false, s)
  end
  Rse.setVar("VAR_LILYCOVE_FAN_CLUB_STATE", 1, s)
  return true
end
function L.removeFan(s)
  if F.count(s) == 1 then return 0 end
  local value, choice = packed(s), 1
  for i, flag in ipairs(REMOVE) do
    if bit.band(value, bit.lshift(1, flag)) ~= 0 then
      choice = i
      if require("src.core.game3.rng").Random() % 2 ~= 0 then break end
    end
  end
  local mask = bit.lshift(1, REMOVE[choice])
  if bit.band(value, mask) ~= 0 then put(s, bit.bxor(value, mask)) end
  return choice - 1
end
function L.updateMoved(s)
  local hours, i = L.hours(s), 0
  if hours >= 999 then return end
  while true do
    if F.count(s) < 5 then stamp(s, hours); break
    elseif i == 8 then break
    elseif hours - Rse.var("VAR_FANCLUB_UNKNOWN_2", s) < 12 then return end
    L.removeFan(s)
    stamp(s, Rse.var("VAR_FANCLUB_UNKNOWN_2", s) + 12)
    i = i + 1
  end
end
function L.updateAfterLinkHours(s)
  if not L.initialized(s) then return end
  L.updateMoved(s); stamp(s, L.hours(s))
end
function L.onLinkBattleEnd(s, outcome)
  if Rse.var("VAR_LILYCOVE_FAN_CLUB_STATE", s) ~= 2 then return false end
  L.updateAfterLinkHours(s)
  if outcome == 1 then F.gainFan(s) else L.removeFan(s) end
  return true
end
function L.onContestResults(s) return F.activity(s, 2) end
function L.resetCache() cached, source = nil, nil end
local function pack()
  local body = assert(require("src.core.game3.dataset").cache():read("data/generated/gba/rse/fan_club/manifest.lua"), "native RS fan-club text pack missing")
  if source ~= body then
    local fn = assert((loadstring or load)(body, "@rs/fan_club")); if setfenv then setfenv(fn, {}) end
    cached, source = fn(), body
  end
  return cached
end
function L.recordAt(s, slot)
  local rows, native = s.linkBattleRecords or {}, false
  for _, row in pairs(rows) do
    if type(row) == "table" and row.nativeSlot ~= nil then
      native = true; if tonumber(row.nativeSlot) == slot then return row end
    end
  end
  if not native then return rows[slot + 1] end
end
function L.nameBytes(record)
  local raw = record and (record.nameBytes or record.nativeBytes)
  if not raw then return nil end
  local function byte(i) return type(raw) == "string" and raw:byte(i) or raw[i] end
  if byte(1) == 255 then return {} end
  local bytes = {}; for i = 1, 7 do bytes[i] = tonumber(byte(i)) or 255 end; bytes[8] = 255
  if bytes[1] == 252 and bytes[2] == 21 then
    local out, IR = {252, 21}, require("src.core.game3.scripting.text_ir")
    local i = 1
    while i <= 7 and bytes[i] ~= 255 do
      if bytes[i] == 252 then i = i + 2 + (IR.EXT_ARGS[bytes[i + 1]] or 0)
      else out[#out + 1] = bytes[i]; i = i + 1 end
    end
    out[#out + 1], out[#out + 2], out[#out + 3] = 252, 22, 255
    return out
  end
  return bytes
end
local function renderedName(bytes)
  local IR = require("src.core.game3.scripting.text_ir")
  if bytes[1] == 252 and bytes[2] == 21 then
    local reverse = {}
    for char, code in pairs(require("src.ui.game3.frlg_font").JAPANESE_GLYPHS) do reverse[code] = char end
    local out = {string.char(252, 21)}
    for i = 3, #bytes do
      local b = bytes[i]
      if b == 255 or b == 252 then break end
      out[#out + 1] = reverse[b] or IR.CHARMAP[b] or "?"
    end
    out[#out + 1] = string.char(252, 22)
    return table.concat(out)
  end
  local out = {}
  for _, seg in ipairs(IR.decode(bytes, {dialect = "rs"})) do
    if seg.t == "ext" then
      out[#out + 1] = string.char(252, seg.cmd)
      for _, b in ipairs(seg.args or {}) do out[#out + 1] = string.char(b) end
    else out[#out + 1] = IR.toAscii({seg}) end
  end
  return table.concat(out)
end
function L.bufferName(s, member)
  local src = NAME_SOURCE[tonumber(member)] or {0, 0}
  local record = L.recordAt(s, src[1])
  local bytes = L.nameBytes(record)
  if bytes and #bytes > 0 then return renderedName(bytes), bytes end
  if not bytes and record and type(record.name) == "string" and record.name ~= "" then
    return record.name:sub(1, 7)
  end
  return assert(pack().names[src[2]], "RS fan-club fallback name missing")
end
return L
