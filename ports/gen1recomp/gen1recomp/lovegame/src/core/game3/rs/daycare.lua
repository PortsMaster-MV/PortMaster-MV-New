local M = {fixedEggPersonality = true, allowVoltTackle = false}
local U32 = 0x100000000
local function rng() return require("src.core.game3.rng").Random() end
local function model() return require("src.core.game3.daycare") end
local function pokemon() return require("src.core.game3.pokemon") end
local function copy(v)
  if type(v) ~= "table" then return v end
  local out = {}; for k, x in pairs(v) do out[k] = copy(x) end; return out
end
local function otId(mon)
  local id = tonumber(mon and (mon.otId or mon.ot_id)) or 0
  if mon and mon.otSecretId ~= nil then id = id % 65536 + (tonumber(mon.otSecretId) or 0) % 65536 * 65536 end
  return id % U32
end

-- pokeruby/daycare.c:862
function M.compatibility(dc)
  local B, D, P = require("src.core.game3.breeding"), model(), pokemon()
  local species, groups, genders, ids = {}, {}, {}, {}
  for i = 1, 2 do
    local mon = D.mon(dc, i)
    species[i], ids[i] = D.speciesOf(mon), otId(mon)
    groups[i] = B.eggGroups(species[i])
    genders[i] = mon and P.gender(species[i], mon.personality) or "U"
  end
  if groups[1][1] == 15 or groups[2][1] == 15 then return 0 end
  if groups[1][1] == 13 and groups[2][1] == 13 then return 0 end
  if groups[1][1] == 13 or groups[2][1] == 13 then return ids[1] == ids[2] and 20 or 50 end
  if genders[1] == genders[2] or genders[1] == "U" or genders[2] == "U" then return 0 end
  if not B.eggGroupsOverlap(groups[1], groups[2]) then return 0 end
  if species[1] == species[2] then return ids[1] == ids[2] and 50 or 70 end
  return ids[1] == ids[2] and 20 or 50
end

-- daycare.c:363
function M.pendingPersonality() return rng() % 0xFFFE + 1 end
function M.malePendingPersonality() return require("bit").bor(rng(), 0x8000) end
-- daycare.c:714
function M.initialPersonality(_, dc)
  return (tonumber(dc and dc.offspringPersonality) or 0) % 65536 + rng() * 65536
end
function M.initializeEgg(egg)
  egg.nickname, egg.name, egg.language = "EGG", "EGG", 1
end

-- daycare.c:387
function M.inheritIVs(egg, dc)
  local B, D = require("src.core.game3.breeding"), model()
  local available, selected, parents = {0, 1, 2, 3, 4, 5}, {}, {}
  for i = 1, 3 do
    selected[i] = available[rng() % (7 - i) + 1]
    available[selected[i] + 1] = 255
    local temp = copy(available)
    local j = 1
    for k = 1, 6 do if temp[k] ~= 255 then available[j], j = temp[k], j + 1 end end
  end
  for i = 1, 3 do parents[i] = rng() % 2 + 1 end
  egg.ivs = egg.ivs or {}
  for i = 1, 3 do
    local key = B.IV_KEYS[selected[i] + 1]
    local parent = D.mon(dc, parents[i])
    egg.ivs[key] = tonumber(parent and parent.ivs and parent.ivs[key]) or 0
  end
  for i = 1, 3 do selected[i] = selected[i] + 1 end
  return selected, parents
end

-- daycare.c:738
function M.step(session)
  local D, B = model(), require("src.core.game3.breeding")
  local dc, count = D.stateOf(session), 0
  for i = 1, 2 do
    local mon = D.mon(dc, i)
    if D.speciesOf(mon) ~= 0 then dc.steps[i] = ((tonumber(dc.steps[i]) or 0) + 1) % U32; count = count + 1 end
  end
  if (tonumber(dc.offspringPersonality) or 0) % 65536 == 0 and count == 2
    and dc.steps[2] % 256 == 255 and M.compatibility(dc) > math.floor(rng() * 100 / 65535) then
    B.triggerPendingEgg(session, dc)
  end
  dc.stepCounter = ((tonumber(dc.stepCounter) or 0) + 1) % 256
  if dc.stepCounter == 255 then
    for slot = 1, 6 do
      local mon = session.party and session.party[slot]
      if mon and (mon.isEgg == true or mon.egg == true) then
        local cycles = (tonumber(mon.friendship or mon.eggCycles or mon.cycles) or 0) % 256
        if cycles == 0 then return count, slot end
        -- pokeruby/src/pokemon_2.c:705
        if not mon.isBadEgg then
          mon.friendship, mon.happiness, mon.eggCycles = cycles - 1, cycles - 1, cycles - 1
        end
      end
    end
  end
  return count
end

-- egg_hatch.c:217
function M.hatchMon(session, mon)
  local D, P, Party = model(), pokemon(), require("src.core.game3.party")
  local species = D.speciesOf(mon)
  local old = copy(mon)
  local scratch = setmetatable({party = {}, dex = {seen = {}, owned = {}, caught = {}}}, {__index = session})
  local ok, _, fresh = Party.giveMon(scratch, species, 5, P.name(species), {fixedPersonality = old.personality or 0})
  if not ok then return nil end
  fresh.moves = old.cartExtra and old.cartExtra.moveSlots and old.cartExtra.moveSlots.moves or old.moves
  fresh.ivs = old.ivs
  fresh.metGame, fresh.markings, fresh.pokerus = old.metGame, old.markings, old.pokerus
  fresh.language, fresh.friendship, fresh.happiness = 2, 120, 120
  fresh.isEgg, fresh.egg, fresh.metLevel, fresh.pokeball = false, false, 0, 4
  fresh.metLocation = P.currentMapSec and P.currentMapSec(session) or fresh.metLocation
  fresh.pp, fresh.maxPp, fresh.ppBonuses = {}, {}, {0, 0, 0, 0}
  for i = 1, 4 do
    local move = fresh.moves and fresh.moves[i]
    if type(move) == "table" then move = move.id or move.move end
    local pp = (tonumber(move) or 0) ~= 0 and (tonumber(P.movePp(tonumber(move))) or 0) or 0
    fresh.pp[i], fresh.maxPp[i] = pp, pp
  end
  P.applyStats(fresh)
  for k in pairs(mon) do mon[k] = nil end
  for k, v in pairs(fresh) do mon[k] = v end
  session.dex = session.dex or {seen = {}, owned = {}, caught = {}}
  local Dex = require("src.core.game3.dex")
  Dex.setSeen(session.dex, species); Dex.setCaught(session.dex, species)
  return mon
end
return M
