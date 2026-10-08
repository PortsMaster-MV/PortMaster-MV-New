local M = {}
local Util = require("src.core.game3.rse.record_mix_util")
local Rng = require("src.core.game3.rng")
local Daycare = require("src.core.game3.daycare")
local SWAP3 = {{0,1}, {1,2}, {2,0}}
local SWAP4 = {{0,1,2,3}, {0,2,1,3}, {0,3,2,1}}
local function num(v) return tonumber(v) or 0 end
local function blank(s)
  local codec = require("src.save_convert.Gen3Save").forVersion(s.version)
  return require("src.save_convert.gen3_port.sections.rs_daycare_mail").read(string.rep("\0", 56), codec)
end
local function item(m) return num(type(m) == "table" and type(m.message) == "table" and m.message.itemId) % 256 end

-- pokeruby/src/daycare.c:79
function M.prepare(s)
  local dc, out = Daycare.stateOf(s), {mail = {}, numDaycareMons = 0, itemsHeld = {1,1}}
  for i = 1, 2 do
    out.mail[i] = Util.deep((dc.mail or {})[i] or blank(s))
    local mon = Daycare.mon(dc, i)
    if mon and Daycare.speciesOf(mon) ~= 0 then
      out.numDaycareMons = out.numDaycareMons + 1
      out.itemsHeld[i] = num(mon.heldItem or mon.item) ~= 0 and 1 or 0
    end
  end
  return out
end

-- pokeruby/src/record_mixing.c:501
function M.receive(s, players, mine, byteSum)
  local oldSeed = Rng.Random()
  Rng.SeedRng(Util.linkTrainerId(players[1]))
  local eligible = {}
  for i, p in ipairs(players) do
    local r, slots = p.daycareMail, {}
    r.mail, r.itemsHeld = r.mail or {}, r.itemsHeld or {}
    for j = 1, 2 do r.mail[j] = r.mail[j] or blank(s) end
    for j = 1, math.min(2, num(r.numDaycareMons)) do
      if num(r.itemsHeld[j]) == 0 then slots[#slots + 1] = j end
    end
    if #slots == 2 then
      local first, second = item(r.mail[1]), item(r.mail[2])
      if (first == 0) == (second == 0) then slots = {Rng.Random() % 2 + 1}
      else slots = {first ~= 0 and 1 or 2} end
    end
    if #slots ~= 0 then eligible[#eligible + 1] = {i, slots[1]} end
  end
  local function swap(a, b)
    local left, right = eligible[a + 1], eligible[b + 1]
    local l, r = players[left[1]].daycareMail.mail, players[right[1]].daycareMail.mail
    l[left[2]], r[right[2]] = r[right[2]], l[left[2]]
  end
  local row = num(byteSum) % 3 + 1
  if #eligible == 2 then swap(0,1)
  elseif #eligible == 3 then swap(SWAP3[row][1],SWAP3[row][2])
  elseif #eligible == 4 then
    local ids = SWAP4[row]; swap(ids[1],ids[2]); swap(ids[3],ids[4])
  end
  local dc = Daycare.stateOf(s)
  dc.mail = Util.deep(players[mine].daycareMail.mail)
  Rng.SeedRng(oldSeed)
end
return M
