local M = {}
local Native = require("src.save_convert.gen3_port.sections.rs_tv_shows")
local Util = require("src.core.game3.rse.record_mix_util")
local Codec = require("src.save_convert.Gen3Save")

local function codec(s) return Codec.forVersion(s.version) end
local function num(v) return tonumber(v) or 0 end
local function on(v) return v == true or (type(v) == "number" and v ~= 0) end
local function zero() return string.rep("\0", 36) end
local function put(raw, offset, value)
  return raw:sub(1, offset) .. string.char(value % 256) .. raw:sub(offset + 2)
end
local function u16(raw, offset) return raw:byte(offset + 1) + raw:byte(offset + 2) * 256 end
local function encode(c, show)
  return Native.render(c, zero(), show or { kind = 0 }, function(a, b)
    return require("src.save_convert.gen3_port.rse").same(a, b)
  end)
end
local function list(c, shows)
  local out = {}
  for i = 0, 24 do out[i] = encode(c, shows and shows[i]) end
  return out
end
local function decode(c, rows)
  local out = {}
  for i = 0, 24 do out[i] = Native.readSlot(rows[i], c) end
  return out
end
local function flag(s, key)
  local C = require("src.core.game3.constants").of(s.version)
  return on(((s.store or s).flags or {})[C:require("flags", key)])
end

-- pokeruby/src/record_mixing.c:65
function M.prepare(s)
  local c, rows = codec(s), list(codec(s), s.tvShows)
  for i = 0, 4 do
    local kind = rows[i]:byte(1)
    if kind >= 1 and kind <= 20 then rows[i] = put(rows[i], 1, 0) end
  end
  s.tvShows = decode(c, rows)
  local sum, prefix = 0, table.concat(rows, "", 0, 24):sub(1, 256)
  for i = 1, 256 do sum = sum + prefix:byte(i) end
  return Util.deep(s.tvShows), Util.deep(s.pokeNews or {}), sum % 256
end

local function empty(rows)
  for i = 5, 23 do if rows[i]:byte(1) == 0 then return i end end
end
local function inactive(rows)
  for i = 0, 23 do
    local kind, active = rows[i]:byte(1, 2)
    if active == 0 and kind >= 1 and kind <= 60 then return i end
  end
end
local function compact(rows, first, last)
  local nextSlot = first
  for i = first, last do
    if rows[i]:byte(1) ~= 0 then
      if nextSlot ~= i then rows[nextSlot], rows[i] = rows[i], zero() end
      nextSlot = nextSlot + 1
    end
  end
end
-- pokeruby/src/tv.c:2303
local function transfer(raw, recipient)
  local kind = raw:byte(1)
  recipient = recipient % 65536
  if u16(raw, 34) == recipient or (kind > 20 and kind <= 40 and u16(raw, 32) == recipient) then return end
  if kind > 20 and kind <= 40 then
    raw = put(put(raw, 32, raw:byte(31)), 33, raw:byte(32))
    raw = put(put(raw, 30, recipient), 31, math.floor(recipient / 256))
  else
    raw = put(put(raw, 34, raw:byte(33)), 35, raw:byte(34))
    raw = put(put(raw, 32, recipient), 33, math.floor(recipient / 256))
    if kind > 40 then raw = put(put(raw, 22, 1), 23, 0) end
  end
  return put(raw, 1, 1)
end
local SPECIES = { [1] = {2}, [3] = {2}, [4] = {6}, [5] = {2,28},
  [6] = {2}, [7] = {10,20}, [21] = {16}, [23] = {12,14}, [24] = {4}, [25] = {8,4} }
local NO_SPECIES = { [0] = true, [2] = true, [22] = true, [41] = true }

-- pokeruby/src/tv.c:2199
function M.receiveShows(s, players, mine)
  local c, rows = codec(s), {}
  for i, p in ipairs(players) do rows[i] = list(c, i == mine and s.tvShows or p.tvShows) end
  while true do
    local without = 0
    for i = 1, #players do
      local slot = inactive(rows[i])
      if slot == nil then without = without + 1 else
        for k = 1, #players - 1 do
          local dest = (i + k - 1) % #players + 1
          local target = empty(rows[dest])
          local mixed = target and transfer(rows[i][slot], Util.linkTrainerId(players[dest]))
          if mixed then rows[dest][target] = mixed; break end
        end
        rows[i][slot] = zero()
      end
    end
    if without == #players then break end
  end
  local own = rows[mine]
  compact(own, 0, 4); compact(own, 5, 23)
  local empties = 0
  for i = 5, 23 do if own[i]:byte(1) == 0 then empties = empties + 1 end end
  for i = 5, 5 + (5 - empties) - 1 do own[i] = zero() end
  compact(own, 0, 4); compact(own, 5, 23)
  local Dex, clear = require("src.core.game3.dex"), flag(s, "FLAG_SYS_GAME_CLEAR")
  for i = 0, 23 do
    local kind, valid = own[i]:byte(1), true
    if SPECIES[kind] then
      for _, offset in ipairs(SPECIES[kind]) do
        if not Dex.isSeen(s.dex or {}, u16(own[i], offset)) then valid = false end
      end
    elseif not NO_SPECIES[kind] then valid = false end
    if not clear and (kind == 7 or kind == 41) then valid = false end
    if not valid then own[i] = put(own[i], 1, 0) end
  end
  s.tvShows = decode(c, own)
end

-- pokeruby/src/tv.c:2491
function M.receiveNews(s, players, mine)
  local lists = {}
  for i, p in ipairs(players) do
    lists[i] = i == mine and (s.pokeNews or {}) or Util.deep(p.pokeNews or {})
    for j = 0, 15 do lists[i][j] = lists[i][j] or {kind = 0, state = 0, dayCountdown = 0} end
  end
  for slot = 0, 15 do
    for i = 1, #players do
      local src = lists[i][slot]
      if num(src.kind) ~= 0 then
        for k = 1, #players - 1 do
          local dst, target, duplicate = lists[(i + k - 1) % #players + 1], nil, false
          for j = 0, 15 do
            if target == nil and num(dst[j].kind) == 0 then target = j end
            if num(dst[j].kind) == num(src.kind) then duplicate = true end
          end
          if target and not duplicate then dst[target] = {kind = src.kind, state = 1, dayCountdown = src.dayCountdown} end
        end
      end
    end
  end
  local out, nextSlot, clear = {}, 0, flag(s, "FLAG_SYS_GAME_CLEAR")
  for i = 0, 15 do
    local news = lists[mine][i]
    if num(news.kind) >= 1 and num(news.kind) <= 3 then
      out[nextSlot] = Util.deep(news)
      if not clear then out[nextSlot].state = 0 end
      nextSlot = nextSlot + 1
    end
  end
  for i = nextSlot, 15 do out[i] = {kind = 0, state = 0, dayCountdown = 0} end
  s.pokeNews = out
end
return M
