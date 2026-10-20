local Rng = require("src.core.game3.rng")

local M = {}

function M.bind(E, H)
local R = {}
local Encounters = setmetatable({}, {
  __index = function(_, k)
    local v = R[k]
    if v ~= nil then return v end
    return E[k]
  end,
  __newindex = function(_, k, v)
    if type(v) == "function" then R[k] = v else E[k] = v end
  end,
})
local normalize_area = H.normalize_area
local table_for = H.table_for
local area_for = H.area_for
local pick_slot = H.pick_slot
local level_of = H.level_of
local bike_active = H.bike_active
local repel_active = H.repel_active
local wild_level_allowed_by_repel = H.wild_level_allowed_by_repel
local LAND_WEIGHTS = H.LAND_WEIGHTS
local WATER_WEIGHTS = H.WATER_WEIGHTS

local MAX_ENCOUNTER_RATE = 1600 -- pret wild_encounter.c (FireRed)

-- Ids the encounter-rate modifiers below key off (pret constants/abilities.h,
-- constants/items.h, constants/flags.h).
local ABILITY_STENCH = 1
local ABILITY_ILLUMINATE = 35
local ITEM_CLEANSE_TAG = 190
local FLAG_SYS_WHITE_FLUTE_ACTIVE = 0x803
local FLAG_SYS_BLACK_FLUTE_ACTIVE = 0x804

-- pret GetMapBaseEncounterCooldown returns 0xFF when the map has no encounter
-- data for that tile type, which aborts the check instead of granting a grace
-- period (the roll would fail anyway).
local COOLDOWN_NONE = 0xFF
local COOLDOWN_BASE_LEAK = 5 -- pret: encRate = 5 * 256
local COOLDOWN_SCALE = 256 -- pret keeps minSteps/encRate scaled so the modifiers stay fractional

-- pret AddToWildEncounterRateBuff banks into a u16 field, so it wraps there.
local RATE_BUFF_MOD = 65536
--- pret DoWildEncounterRateDiceRoll: WildEncounterRandom() % 1600 < rate.
local function rate_dice_roll(rate)
  return (Rng.WildEncounterRandom() % MAX_ENCOUNTER_RATE) < rate
end

-- ---------------------------------------------------------------------------
-- Wild encounter grace period (pret wild_encounter.c).
--
-- FireRed is the only generation with a step cooldown between wild battles:
-- HandleWildEncounterCooldown refuses the roll for a map-dependent number of
-- steps after the last encounter, then lets a small percentage per step
-- through so the wait is soft rather than a hard floor.
-- ---------------------------------------------------------------------------

--- pret GetMapBaseEncounterCooldown: how many steps after a battle are immune,
--- derived from the area's own encounter rate. Rates at 80+ get no grace period
--- at all; below that the wait grows as the rate drops.
function Encounters.mapBaseCooldown(terrain, rate)
  if terrain == "grass" or terrain == "cave" or terrain == "tall_grass" then terrain = "land" end
  if terrain ~= "land" and terrain ~= "water" then return COOLDOWN_NONE end
  if rate == nil then return COOLDOWN_NONE end
  rate = tonumber(rate) or 0
  if rate >= 80 then return 0 end
  if rate < 10 then return 8 end
  return 8 - math.floor(rate / 10)
end

--- pret GetLeadMonIndex: the lead party slot, eggs excluded.
local function lead_mon()
  local ok, Runtime = pcall(require, "src.core.game3.runtime")
  local session = ok and Runtime and Runtime.getSession and Runtime.getSession()
  local party = session and session.party
  if type(party) ~= "table" then return nil end
  for i = 1, #party do
    local mon = party[i]
    if type(mon) == "table" and not mon.isEgg and not mon.egg then return mon end
  end
  return nil
end

--- pret GetFluteEncounterRateModType: 1 = White Flute, 2 = Black Flute.
local function flute_mod_type()
  local okS, Space = pcall(require, "src.core.game3.scripting.space")
  if not okS or not Space or not Space.store then return 0 end
  local okF, Flags = pcall(require, "src.core.game3.scripting.flags")
  if not okF or not Flags or not Flags.getFlag then return 0 end
  if Flags.getFlag(Space.store, nil, FLAG_SYS_WHITE_FLUTE_ACTIVE) then return 1 end
  if Flags.getFlag(Space.store, nil, FLAG_SYS_BLACK_FLUTE_ACTIVE) then return 2 end
  return 0
end

--- pret IsLeadMonHoldingCleanseTag.
local function lead_holds_cleanse_tag()
  local mon = lead_mon()
  if not mon then return false end
  return (tonumber(mon.item or mon.heldItem) or 0) == ITEM_CLEANSE_TAG
end

--- pret GetAbilityEncounterRateModType: Stench 1 (rarer), Illuminate 2 (commoner).
local function ability_mod_type()
  local mon = lead_mon()
  if not mon then return 0 end
  local ability = tonumber(mon.abilityId or mon.ability) or 0
  if ability == ABILITY_STENCH then return 1 end
  if ability == ABILITY_ILLUMINATE then return 2 end
  return 0
end

--- The fully modified (minSteps, leak) pair pret computes inside
--- HandleWildEncounterCooldown. nil means "no encounter data here".
function Encounters.cooldownMinSteps(terrain, rate)
  local minSteps = Encounters.mapBaseCooldown(terrain, rate)
  if minSteps == COOLDOWN_NONE then return nil end

  minSteps = minSteps * COOLDOWN_SCALE
  local leak = COOLDOWN_BASE_LEAK * COOLDOWN_SCALE
  local flute = flute_mod_type()
  if flute == 1 then
    minSteps = minSteps - math.floor(minSteps / 2)
    leak = leak + math.floor(leak / 2)
  elseif flute == 2 then
    minSteps = minSteps * 2
    leak = math.floor(leak / 2)
  end
  if lead_holds_cleanse_tag() then
    minSteps = minSteps + math.floor(minSteps / 3)
    leak = leak - math.floor(leak / 3)
  end
  local ability = ability_mod_type()
  if ability == 1 then
    minSteps = minSteps * 2
    leak = math.floor(leak / 2)
  elseif ability == 2 then
    minSteps = math.floor(minSteps / 2)
    leak = leak * 2
  end
  return math.floor(minSteps / COOLDOWN_SCALE), math.floor(leak / COOLDOWN_SCALE)
end

--- pret HandleWildEncounterCooldown. TRUE means this step may roll for an
--- encounter. Runs on every step onto an encounter tile -- including the steps
--- the dice roll would have denied, which is what advances the counter.
function Encounters.handleCooldown(terrain, rate)
  local minSteps, leak = Encounters.cooldownMinSteps(terrain, rate)
  if minSteps == nil then return false end

  if Encounters._stepsSinceLastEncounter >= minSteps then return true end
  Encounters._stepsSinceLastEncounter = Encounters._stepsSinceLastEncounter + 1
  return (Rng.Random() % 100) < leak
end

--- pret ResetEncounterRateModifiers, reached from RestartWildEncounterImmunitySteps
--- on map load (overworld.c) and on battle start (battle_setup.c). Resetting when
--- the battle starts is what re-arms the grace period, including for wild battles
--- nothing stepped into (scripts, fishing).
function Encounters.resetRateModifiers()
  Encounters._stepsSinceLastEncounter = 0
  Encounters._encounterRateBuff = 0
end

--- pret AddToWildEncounterRateBuff: bank a failed roll's rate so the next
--- attempt is likelier. A Repel zeroes the bank instead of growing it.
local function add_to_rate_buff(rate)
  if repel_active() then
    Encounters._encounterRateBuff = 0
    return
  end
  Encounters._encounterRateBuff =
    (Encounters._encounterRateBuff + (tonumber(rate) or 0)) % RATE_BUFF_MOD
end

--- pret DoWildEncounterRateTest, without the roll: the threshold in 1/1600ths
--- that the dice roll compares against. Every encounter-rate modifier applies
--- here as well as in the cooldown -- bike, banked buff, flute, Cleanse Tag,
--- then ability, in pret's order.
function Encounters.encounterRate(rate, opts)
  local r = (tonumber(rate) or 0) * 16
  if bike_active() then r = math.floor(r * 80 / 100) end
  r = r + math.floor(Encounters._encounterRateBuff * 16 / 200)
  local flute = flute_mod_type()
  if flute == 1 then
    r = r + math.floor(r / 2)
  elseif flute == 2 then
    r = math.floor(r / 2)
  end
  if lead_holds_cleanse_tag() then r = math.floor(r * 2 / 3) end
  if not (opts and opts.ignoreAbility) then
    local ability = ability_mod_type()
    if ability == 1 then
      r = math.floor(r / 2)
    elseif ability == 2 then
      r = r * 2
    end
  end
  if r > MAX_ENCOUNTER_RATE then r = MAX_ENCOUNTER_RATE end
  return r
end

local function rate_test(rate)
  return rate_dice_roll(Encounters.encounterRate(rate))
end

local function roll_area(mapId, areaKey, weights, enterFromOther, fallbackRate)
  local t = table_for(mapId)
  local area = normalize_area(t and t[areaKey], fallbackRate)
  if not area or #area.slots == 0 then return nil end

  -- pret DoGlobalWildEncounterDiceRoll: (Random() % 100) >= 60 → deny.
  -- This returns before the rate test, so it does not bank into the buff.
  if enterFromOther and (Rng.Random() % 100) >= 60 then
    return nil
  end
  if not rate_test(area.rate) then
    add_to_rate_buff(area.rate)
    return nil
  end

  -- pokefirered/src/wild_encounter.c:645 TryStartRoamerEncounter
  local okR, Roamer = pcall(require, "src.core.game3.roamer")
  if okR and Roamer and Roamer.tryEncounter then
    local okRt, Runtime = pcall(require, "src.core.game3.runtime")
    local session = okRt and Runtime and Runtime.getSession and Runtime.getSession()
    local roamerEnc = Roamer.tryEncounter(session, mapId, areaKey)
    if roamerEnc then
      return roamerEnc
    end
  end

  local entry = pick_slot(area.slots, weights)
  if type(entry) ~= "table" then
    -- pret banks here too: the rate test passed but TryGenerateWildMon found
    -- no allowed mon (repel level check, empty slot).
    add_to_rate_buff(area.rate)
    return nil
  end
  -- pokefirered/src/wild_encounter.c:286
  local level = level_of(entry)
  if not wild_level_allowed_by_repel(level) then
    add_to_rate_buff(area.rate)
    return nil
  end
  return {
    species = entry.species or entry[1],
    level = level,
    item = entry.item,
  }
end

function Encounters.rollLand(mapId, rate, enterFromOther)
  Encounters.ensureLoaded()
  return roll_area(mapId, "land", LAND_WEIGHTS, enterFromOther, rate)
    or roll_area(mapId, "grass", LAND_WEIGHTS, enterFromOther, rate)
end

function Encounters.rollWater(mapId, enterFromOther)
  Encounters.ensureLoaded()
  return roll_area(mapId, "water", WATER_WEIGHTS, enterFromOther, 15)
end

-- pokefirered/src/wild_encounter.c:464
function Encounters.rollSweetScent(mapId, terrain)
  Encounters.ensureLoaded()
  local water = terrain == "water"
  local t = table_for(mapId)
  local area = water and normalize_area(t and t.water, 15)
    or normalize_area(t and (t.land or t.grass), nil)
  local okR, Roamer = pcall(require, "src.core.game3.roamer")
  if okR and Roamer and Roamer.tryEncounter then
    local okRt, Runtime = pcall(require, "src.core.game3.runtime")
    local session = okRt and Runtime and Runtime.getSession and Runtime.getSession()
    local roamerEnc = Roamer.tryEncounter(session, mapId, water and "water" or "land")
    if roamerEnc then return roamerEnc end
  end
  if not area or #area.slots == 0 then return nil end
  local entry = pick_slot(area.slots, water and WATER_WEIGHTS or LAND_WEIGHTS)
  if type(entry) ~= "table" then return nil end
  return { species = entry.species or entry[1], level = level_of(entry), item = entry.item }
end

--- pokefirered/src/wild_encounter.c:446
function Encounters.rollRocks(mapId)
  Encounters.ensureLoaded()
  local t = table_for(mapId)
  local area = normalize_area(t and t.rocks, 20)
  if not area or #area.slots == 0 then return nil end
  if not rate_dice_roll(Encounters.encounterRate(area.rate, { ignoreAbility = true })) then
    return nil
  end
  -- pokefirered/src/wild_encounter.c:269
  local entry = pick_slot(area.slots, WATER_WEIGHTS)
  if type(entry) ~= "table" then return nil end
  local level = level_of(entry)
  if not wild_level_allowed_by_repel(level) then return nil end
  Encounters.resetRateModifiers()
  return {
    species = entry.species or entry[1],
    level = level,
    item = entry.item,
  }
end

-- pokefirered/include/constants/items.h:457
local ROD_OLD, ROD_GOOD, ROD_SUPER = 0, 1, 2

local ROD_KINDS = {
  [0] = ROD_OLD, [1] = ROD_GOOD, [2] = ROD_SUPER,
  [262] = ROD_OLD, [263] = ROD_GOOD, [264] = ROD_SUPER,
  old = ROD_OLD, good = ROD_GOOD, super = ROD_SUPER,
  OLD_ROD = ROD_OLD, GOOD_ROD = ROD_GOOD, SUPER_ROD = ROD_SUPER,
  ITEM_OLD_ROD = ROD_OLD, ITEM_GOOD_ROD = ROD_GOOD, ITEM_SUPER_ROD = ROD_SUPER,
}

-- pokefirered/src/data/wild_encounters.h:31
local FISHING_TOTAL = 100
local FISHING_WINDOWS = {
  [ROD_OLD] = { { 70, 1 }, { 100, 2 } },
  [ROD_GOOD] = { { 60, 3 }, { 80, 4 }, { 100, 5 } },
  [ROD_SUPER] = { { 40, 6 }, { 80, 7 }, { 95, 8 }, { 99, 9 }, { 100, 10 } },
}

--- pokefirered/src/wild_encounter.c:117
local function choose_fishing_index(rod)
  local windows = FISHING_WINDOWS[rod] or FISHING_WINDOWS[ROD_OLD]
  local rand = Rng.Random() % FISHING_TOTAL
  for i = 1, #windows do
    if rand < windows[i][1] then return windows[i][2] end
  end
  return 1
end

--- pokefirered/src/wild_encounter.c:509
function Encounters.hasFishingMons(mapId)
  Encounters.ensureLoaded()
  local t = table_for(mapId)
  local area = normalize_area(t and t.fishing, 0)
  return area ~= nil and #area.slots > 0
end

--- pokefirered/src/wild_encounter.c:519
function Encounters.rollFishing(mapId, rodKind)
  Encounters.ensureLoaded()
  local t = table_for(mapId)
  local area = normalize_area(t and t.fishing, 0)
  if not area or #area.slots == 0 then return nil end
  local rod = ROD_KINDS[rodKind]
  if rod == nil then rod = ROD_OLD end
  local idx = choose_fishing_index(rod)
  if idx > #area.slots then idx = #area.slots end
  local entry = area.slots[idx]
  if type(entry) ~= "table" then return nil end
  Encounters.resetRateModifiers()
  return {
    species = entry.species or entry[1],
    level = level_of(entry),
    item = entry.item,
  }
end

local function vanilla_step(mapId, terrain, opts)
  Encounters.ensureLoaded()
  opts = opts or {}
  local enterFromOther = opts.enterFromOther
  if enterFromOther == nil then
    enterFromOther = not Encounters._prevGrass
  end
  -- pret TryStandardWildEncounter consults the cooldown before the rate test.
  local area = area_for(mapId, terrain)
  if not Encounters.handleCooldown(terrain, area and area.rate) then return nil end
  local enc
  if terrain == "water" then
    enc = Encounters.rollWater(mapId, enterFromOther)
  else
    enc = Encounters.rollLand(mapId, nil, enterFromOther)
  end
  -- pret sets stepsSinceLastEncounter = 0 once an encounter actually starts.
  if enc then Encounters.resetRateModifiers() end
  return enc
end

R.step = vanilla_step
return R
end

return M
