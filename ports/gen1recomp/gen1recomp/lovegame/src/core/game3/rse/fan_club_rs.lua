local Rse = require("src.core.game3.rse.init")
local bit = rawget(_G, "bit") or require("bit")
local F = {}
local GAIN = {2, 1, 2, 1}
local function packed(s) return Rse.var("VAR_FANCLUB_UNKNOWN_1", s) end
local function put(s, n) Rse.setVar("VAR_FANCLUB_UNKNOWN_1", bit.band(n, 0xFFFF), s) end

function F.count(s)
  local value, n = packed(s), 0
  for i = 8, 15 do if bit.band(value, bit.lshift(1, i)) ~= 0 then n = n + 1 end end
  return n
end

function F.gainFan(s)
  local value, choice = packed(s), 8
  for i = 8, 15 do
    if bit.band(value, bit.lshift(1, i)) == 0 then
      choice = i
      if require("src.core.game3.rng").Random() % 2 ~= 0 then break end
    end
  end
  put(s, bit.bor(value, bit.lshift(1, choice)))
  return choice - 8
end

function F.activity(s, activity)
  activity = math.floor(tonumber(activity) or 0) % 256
  local value = packed(s)
  if Rse.var("VAR_LILYCOVE_FAN_CLUB_STATE", s) == 2 then
    local gain = assert(GAIN[activity + 1], "RS fan-club activity outside native caller range")
    if bit.band(value, 0x7F) + gain >= 20 then
      if F.count(s) < 3 then
        F.gainFan(s); put(s, bit.band(packed(s), 0xFF80))
      else put(s, bit.bor(bit.band(value, 0xFF80), 20)) end
    else put(s, value + gain) end
  end
  return bit.band(packed(s), 0x7F)
end
return F
