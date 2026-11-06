local Pack = {}

local MAGIC = "PKCI1:"
local MAX_RAW = 0x100000
local MIN_MATCH = 4
local MAX_MATCH = 255 + MIN_MATCH
local MAX_DIST = 65535
local MAX_LITERAL = 0x7FFF

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local ENC, DEC = {}, {}
for i = 1, 64 do
  local c = B64:sub(i, i)
  ENC[i - 1] = c
  DEC[c:byte()] = i - 1
end

local byte, char, sub, concat = string.byte, string.char, string.sub, table.concat

local function compress(s)
  local n = #s
  local out, o = {}, 0
  local lits, nl = {}, 0
  local last = {}
  local function flush()
    local i = 1
    while i <= nl do
      local c = math.min(nl - i + 1, MAX_LITERAL)
      o = o + 1
      if c < 128 then out[o] = char(c) else out[o] = char(128 + math.floor(c / 256), c % 256) end
      o = o + 1
      out[o] = concat(lits, "", i, i + c - 1)
      i = i + c
    end
    nl = 0
    lits = {}
  end
  local i = 1
  while i <= n do
    local bestLen, bestPos = 0, 0
    if i + MIN_MATCH - 1 <= n then
      local a, b, c = byte(s, i, i + 2)
      local h = a * 65536 + b * 256 + c
      local p = last[h]
      last[h] = i
      if p and i - p <= MAX_DIST then
        local len = 0
        while i + len <= n and len < MAX_MATCH and byte(s, p + len) == byte(s, i + len) do len = len + 1 end
        if len >= MIN_MATCH then bestLen, bestPos = len, p end
      end
    end
    if bestLen > 0 then
      flush()
      local d = i - bestPos
      o = o + 1
      out[o] = "\0" .. char(bestLen - MIN_MATCH) .. char(math.floor(d / 256), d % 256)
      for k = i + 1, i + bestLen - 1 do
        if k + 2 <= n then
          local a, b, c = byte(s, k, k + 2)
          last[a * 65536 + b * 256 + c] = k
        end
      end
      i = i + bestLen
    else
      nl = nl + 1
      lits[nl] = sub(s, i, i)
      i = i + 1
    end
  end
  flush()
  return concat(out)
end

local function decompress(s, want)
  local out, n, i, len = {}, 0, 1, #s
  while i <= len do
    local t = byte(s, i)
    i = i + 1
    if t == 0 then
      if i + 2 > len then return nil end
      local l, d = byte(s, i) + MIN_MATCH, byte(s, i + 1) * 256 + byte(s, i + 2)
      i = i + 3
      if d == 0 or d > n or n + l > want then return nil end
      for k = 1, l do out[n + k] = out[n + k - d] end
      n = n + l
    else
      local c = t
      if t >= 128 then
        if i > len then return nil end
        c = (t - 128) * 256 + byte(s, i)
        i = i + 1
      end
      if c == 0 or i + c - 1 > len or n + c > want then return nil end
      for k = 0, c - 1 do out[n + k + 1] = byte(s, i + k) end
      n = n + c
      i = i + c
    end
  end
  if n ~= want then return nil end
  local parts = {}
  for k = 1, n, 4096 do
    parts[#parts + 1] = char(unpack(out, k, math.min(k + 4095, n)))
  end
  return concat(parts)
end

local function b64encode(s)
  local out = {}
  for i = 1, #s, 3 do
    local a, b, c = byte(s, i, i + 2)
    local v = a * 65536 + (b or 0) * 256 + (c or 0)
    local q1, q2 = math.floor(v / 262144), math.floor(v / 4096) % 64
    local q3, q4 = math.floor(v / 64) % 64, v % 64
    out[#out + 1] = ENC[q1] .. ENC[q2] .. (b and ENC[q3] or "=") .. (c and ENC[q4] or "=")
  end
  return concat(out)
end

local function b64decode(s)
  if #s % 4 ~= 0 then return nil end
  local out = {}
  for i = 1, #s, 4 do
    local c1, c2, c3, c4 = byte(s, i, i + 3)
    local p3, p4 = c3 == 61, c4 == 61
    local v1, v2 = DEC[c1], DEC[c2]
    local v3, v4 = p3 and 0 or DEC[c3], p4 and 0 or DEC[c4]
    if not (v1 and v2 and v3 and v4) or (p3 and not p4) or ((p3 or p4) and i + 3 ~= #s) then return nil end
    local v = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
    local piece = char(math.floor(v / 65536), math.floor(v / 256) % 256, v % 256)
    out[#out + 1] = p3 and sub(piece, 1, 1) or p4 and sub(piece, 1, 2) or piece
  end
  return concat(out)
end

function Pack.isPacked(s)
  return type(s) == "string" and sub(s, 1, #MAGIC) == MAGIC
end

function Pack.pack(raw)
  if type(raw) ~= "string" or #raw == 0 or #raw > MAX_RAW then return nil end
  return MAGIC .. #raw .. ":" .. b64encode(compress(raw))
end

function Pack.unpack(s)
  if type(s) ~= "string" then return nil end
  if not Pack.isPacked(s) then return s end
  local want, body = s:match("^" .. MAGIC .. "(%d+):([%w+/=]*)$")
  want = tonumber(want)
  if not want or want < 1 or want > MAX_RAW then return nil end
  local bin = b64decode(body)
  if not bin then return nil end
  return decompress(bin, want)
end

return Pack
