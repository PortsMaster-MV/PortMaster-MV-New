-- pokeruby/src/battle_records.c:40
local M = {}
local COUNTER = {[1] = "wins", [2] = "losses", [3] = "draws"}
local STAT = {[1] = {23, "linkBattleWins"}, [2] = {24, "linkBattleLosses"}, [3] = {25, "linkBattleDraws"}}
-- pokeruby/src/text.c:439
local EXT_LENGTH = {[0]=1, 2,2,2,4,2,2,1,2,1,1,3,2,2,2,1,3,2,2,2,2,1,1}
local function u16(v) return math.floor(tonumber(v) or 0) % 65536 end
local function byte(raw, i, default)
  local n = type(raw) == "string" and raw:byte(i) or type(raw) == "table" and raw[i]
  return n ~= nil and math.floor(tonumber(n) or 0) % 256 or default
end
local function codec() return require("src.save_convert.Gen3Save").forVersion("ruby") end
local function bytes(raw, count, default)
  local out = {}; for i = 1, count do out[i] = byte(raw, i, default) end; return out
end
local function stringOf(raw)
  local out = {}; for i = 1, #raw do out[i] = string.char(raw[i]) end; return table.concat(out)
end
local function encode(name)
  return bytes(codec().encodeString(tostring(name or ""), 8), 8, 0)
end
local function empty()
  local raw = {}; for i = 1, 16 do raw[i] = 0 end; raw[1] = 255
  return {name = "", nameBytes = bytes(raw, 8, 0), nativeBytes = raw, trainerId = 0, wins = 0, losses = 0, draws = 0}
end
local function nameBytes(row)
  if row.nameBytes or row.nativeBytes then return bytes(row.nameBytes or row.nativeBytes, 8, 0) end
  return encode(row.name)
end
local function total(row) return u16(row.wins) + u16(row.losses) + u16(row.draws) end
function M.sort(rows)
  for i = 5, 2, -1 do
    for j = i - 1, 1, -1 do
      if total(rows[i]) > total(rows[j]) then rows[i], rows[j] = rows[j], rows[i] end
    end
  end
  for i = 1, 5 do rows[i].nativeSlot = i - 1 end
end
-- text.c:3776
function M.compare(a, b)
  local i, j, result = 1, 1, 0
  local function skip(raw, at)
    while byte(raw, at, 255) == 252 do
      at = at + 1
      at = at + (EXT_LENGTH[byte(raw, at, 255)] or 0)
    end
    return at
  end
  while true do
    i, j = skip(a, i), skip(b, j)
    local x, y = byte(a, i, 255), byte(b, j, 255)
    if x > y then return x == 255 and -1 or 1 end
    if x < y then result = y == 255 and 1 or -1 end
    if x == 255 then return result end
    i, j = i + 1, j + 1
  end
end
local function normalize(s)
  local old, rows, hasSlots = s.linkBattleRecords or {}, {}, false
  for _, row in pairs(old) do
    if type(row) == "table" and row.nativeSlot ~= nil then hasSlots = true end
  end
  if hasSlots then
    for _, row in pairs(old) do
      local slot = type(row) == "table" and tonumber(row.nativeSlot)
      if slot and slot >= 0 and slot < 5 and slot == math.floor(slot) then rows[slot + 1] = row end
    end
  else
    for i = 1, 5 do if type(old[i]) == "table" then rows[i] = old[i] end end
  end
  for i = 1, 5 do rows[i] = rows[i] or empty(); rows[i].nativeSlot = i - 1 end
  s.linkBattleRecords = rows
  return rows
end
local function refreshRaw(row)
  local raw = bytes(row.nativeBytes, 16, 0)
  row.nameBytes = nameBytes(row)
  for i = 1, 8 do raw[i] = row.nameBytes[i] end
  for i, key in ipairs({"trainerId", "wins", "losses", "draws"}) do
    local n = u16(row[key]); row[key] = n
    local at = 7 + i * 2
    raw[at], raw[at + 1] = n % 256, math.floor(n / 256)
  end
  row.nativeBytes = raw
  row.name = codec().decodeString(stringOf(row.nameBytes), 0, 8)
end
function M.update(s, name, trainerId, outcome, peer)
  if type(s) ~= "table" then return nil end
  local stat = STAT[outcome]
  if stat then
    s.gameStats = s.gameStats or {}
    local n = tonumber(s.gameStats[stat[1]]) or tonumber(s.gameStats[stat[2]]) or 0
    s.gameStats[stat[2]] = nil
    s.gameStats[stat[1]] = n < 9999 and n + 1 or n
  end
  local rows = normalize(s)
  M.sort(rows)
  local incoming = peer and (peer.nameBytes or peer.nativeNameBytes)
  if incoming then incoming = bytes(incoming, math.max(8, #incoming), 255)
  else incoming = encode(name); incoming[8] = 255 end
  local tid, found = u16(trainerId)
  for i = 1, 5 do
    local check = nameBytes(rows[i]); check[8] = 255
    if u16(rows[i].trainerId) == tid and M.compare(check, incoming) == 0 then found = rows[i]; break end
  end
  if not found then
    found = empty(); rows[5] = found
    local dst = found.nameBytes
    if tonumber(peer and peer.language) == 1 then
      dst[1], dst[2] = 252, 21
      for i = 1, 5 do dst[i + 2] = byte(incoming, i, 255) end
    else
      for i = 1, 7 do dst[i] = byte(incoming, i, 255) end
    end
    found.trainerId = tid
  end
  local key = COUNTER[outcome]
  if key then found[key] = math.min(9999, (u16(found[key]) + 1) % 65536) end
  M.sort(rows)
  for i = 1, 5 do refreshRaw(rows[i]) end
  return found
end
return M
