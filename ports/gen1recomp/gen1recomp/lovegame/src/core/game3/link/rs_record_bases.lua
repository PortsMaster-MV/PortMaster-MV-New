local M = {}
local Util = require("src.core.game3.rse.record_mix_util")
local Rs = require("src.core.game3.link.rs")
local function num(v) return tonumber(v) or 0 end
local function on(v) return v == true or v == 1 end
local function system() return require("src.core.game3.rse.secret_base") end
local function copy(v) return Util.deep(v) end
local function clear(b) system().clearBase(b) end
local function sameId(a, b)
  for i = 1, 4 do if num((a.trainerId or {})[i]) ~= num((b.trainerId or {})[i]) then return false end end
  return true
end
local function samePlayer(a, b, codec)
  return a.gender == b.gender and sameId(a, b)
    and codec.encodeString(a.trainerName or "", 8):sub(1, 7) == codec.encodeString(b.trainerName or "", 8):sub(1, 7)
end

-- pokeruby/src/secret_base.c:680
function M.prepare(s)
  local bases, at = system().bases(s), 0
  local p = system().newBase().party
  bases[1].party = p
  for i = 1, 6 do
    local mon = (s.party or {})[i]
    if mon and num(mon.species) ~= 0 and not (mon.isEgg or mon.egg) then
      at = at + 1
      for j = 1, 4 do
        local move = (mon.moves or {})[j]
        p.moves[(at - 1) * 4 + j] = num(type(move) == "table" and (move.id or move.move) or move)
      end
      p.species[at], p.heldItems[at], p.levels[at], p.personality[at] = num(mon.species), num(mon.heldItem or mon.item), num(mon.level), num(mon.personality)
      local ev, total = mon.ev or mon.evs or mon.EVs or {}, 0
      for _, key in ipairs({"hp", "atk", "def", "spe", "spa", "spd"}) do total = total + num(ev[key]) end
      if total == 0 then for j = 1, 6 do total = total + num(ev[j]) end end
      p.EVs[at] = math.floor(total / 6)
    end
  end
  return copy(bases)
end

local function list(source)
  local out = {}
  for i = 1, 20 do out[i] = copy(source and source[i] or system().newBase()) end
  return out
end
-- pokeruby/src/secret_base.c:1434
local function duplicate(base, others, index, codec)
  for i = 1, 20 do
    local other = others[i]
    if num(other.secretBaseId) ~= 0 and samePlayer(base, other, codec) then
      if index == 0 or num(base.numSecretBasesReceived) > num(other.numSecretBasesReceived) then
        clear(other); return false
      end
      other.toRegister = base.toRegister
      clear(base); return true
    end
  end
  return false
end
-- pokeruby/src/secret_base.c:1290
local function save(saved, base)
  if num(base.secretBaseId) == 0 then return end
  local target
  for i = 1, 20 do if saved[i].secretBaseId == base.secretBaseId then target = i; break end end
  if target then
    if target == 1 or on(saved[target].toRegister) then return end
    if saved[target].registryStatus == 2 and not on(base.toRegister) then return end
  else
    for i = 2, 20 do if num(saved[i].secretBaseId) == 0 then target = i; break end end
    if not target then
      for i = 2, 20 do
        if num(saved[i].registryStatus) == 0 and not on(saved[i].toRegister) then target = i; break end
      end
    end
  end
  if target then saved[target] = copy(base); saved[target].registryStatus = 2 end
end

-- pokeruby/src/secret_base.c:1520
function M.receive(s, players, mine)
  local C = require("src.core.game3.constants").of(s.version)
  if not on(((s.store or s).flags or {})[C:require("flags", "FLAG_RECEIVED_SECRET_POWER")]) then return end
  local saved, others = system().bases(s), {}
  local codec = require("src.save_convert.Gen3Save").forVersion(s.version)
  for k = 1, 3 do
    local p = players[(mine - 1 + k) % 4 + 1]
    others[k] = list(p and p.secretBases)
  end
  local id = Rs.trainerId(s)
  local own = { gender = s.gender or 0, trainerName = s.name or s.playerName,
    trainerId = {id % 256, math.floor(id / 256) % 256, math.floor(id / 65536) % 256, math.floor(id / 16777216) % 256} }
  for k = 1, 3 do
    for i = 1, 20 do
      if num(others[k][i].secretBaseId) ~= 0 and samePlayer(others[k][i], own, codec) then clear(others[k][i]); break end
    end
  end
  for i = 2, 20 do
    local b = saved[i]
    if num(b.secretBaseId) ~= 0 then
      if b.registryStatus == 1 then b.toRegister = 1 end
      if not duplicate(b, others[1], i - 1, codec) and not duplicate(b, others[2], i - 1, codec) then duplicate(b, others[3], i - 1, codec) end
    end
  end
  for i = 1, 20 do
    local b = others[1][i]
    if num(b.secretBaseId) ~= 0 then
      b.battledOwnerToday = 0
      if not duplicate(b, others[2], i - 1, codec) then duplicate(b, others[3], i - 1, codec) end
    end
  end
  for i = 1, 20 do
    local b = others[2][i]
    if num(b.secretBaseId) ~= 0 then b.battledOwnerToday = 0; duplicate(b, others[3], i - 1, codec) end
    if num(others[3][i].secretBaseId) ~= 0 then others[3][i].battledOwnerToday = 0 end
  end
  for k = 1, 3 do save(saved, others[k][1]) end
  for status = 1, 0, -1 do
    for k = 1, 3 do for i = 2, 20 do if others[k][i].registryStatus == status then save(saved, others[k][i]) end end end
  end
  for i = 2, 20 do if on(saved[i].toRegister) then saved[i].registryStatus, saved[i].toRegister = 1, 0 end end
  for i = 2, 19 do
    for j = i + 1, 20 do
      if (saved[i].registryStatus == 0 and saved[j].registryStatus == 1)
          or (saved[i].registryStatus == 2 and saved[j].registryStatus ~= 2) then saved[i], saved[j] = saved[j], saved[i] end
    end
  end
  for i = 2, 20 do if saved[i].registryStatus == 2 then saved[i].registryStatus = 0 end end
  saved[1].numSecretBasesReceived = math.min(65535, num(saved[1].numSecretBasesReceived) + 1)
end
return M
