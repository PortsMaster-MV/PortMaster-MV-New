local bit = require("bit")
local Rng = require("src.core.game3.rng")

local M = {}

-- pokeemerald/src/wild_encounter.c:27
local MAX_ENCOUNTER_RATE = 2880
-- pokeemerald/src/field_control_avatar.c:670
local IMMUNITY_STEPS = 4
-- pokeemerald/include/constants/pokemon.h:14
local TYPE_STEEL = 8
-- pokeemerald/include/constants/pokemon.h:19
local TYPE_ELECTRIC = 13
-- pokeemerald/include/constants/wild_encounter.h:24
local NUM_LAND_MONS_ENCOUNTER_SLOTS = 12
-- pokeemerald/src/wild_encounter.c:29
local NUM_FEEBAS_SPOTS = 6
-- pokeemerald/src/wild_encounter.c:36
local NUM_FISHING_SPOTS = 131 + 167 + 149
-- pokeemerald/include/constants/pokemon.h:72
local NUM_NATURES = 25
-- pokeemerald/include/constants/pokemon.h:169
local MON_MALE, MON_FEMALE, MON_GENDERLESS = 0x00, 0xFE, 0xFF

-- pokeemerald/src/metatile_behavior.c:5
local TILE_FLAG_HAS_ENCOUNTERS = 1
local TILE_FLAG_SURFABLE = 2

-- pokeemerald/src/metatile_behavior.c:773
local BRIDGE_OVER_WATER = {
  "BRIDGE_OVER_OCEAN", "BRIDGE_OVER_POND_LOW", "BRIDGE_OVER_POND_MED", "BRIDGE_OVER_POND_HIGH",
  "BRIDGE_OVER_POND_HIGH_EDGE_1", "BRIDGE_OVER_POND_HIGH_EDGE_2", "UNUSED_BRIDGE",
  "BIKE_BRIDGE_OVER_BARRIER",
}

-- pokeemerald/src/wild_encounter.c:230
local FISHING_WINDOWS = {
  [0] = { { 70, 0 }, { 100, 1 } },
  [1] = { { 60, 2 }, { 80, 3 }, { 100, 4 } },
  [2] = { { 40, 5 }, { 80, 6 }, { 95, 7 }, { 99, 8 }, { 100, 9 } },
}

local ROD_KINDS = {
  [0] = 0, [1] = 1, [2] = 2,
  [262] = 0, [263] = 1, [264] = 2,
  old = 0, good = 1, super = 2,
  OLD_ROD = 0, GOOD_ROD = 1, SUPER_ROD = 2,
  ITEM_OLD_ROD = 0, ITEM_GOOD_ROD = 1, ITEM_SUPER_ROD = 2,
}

function M.bind(E, H, policy)
  local R = { everyStep = true }
  local rs = policy and policy.nativeRS == true

  local function C() return H.constants() end

  local function session()
    local ok, Runtime = pcall(require, "src.core.game3.runtime")
    return ok and Runtime and Runtime.getSession and Runtime.getSession() or nil
  end

  local function store()
    local Space = package.loaded["src.core.game3.scripting.space"]
    return (Space and Space.store) or session()
  end

  local function flag(name)
    local s = store()
    if not s then return false end
    return require("src.core.game3.scripting.flags").getFlag(s, nil, C():require("flags", name)) == true
  end

  local function lead()
    local s = session()
    local party = s and s.party
    return type(party) == "table" and party[1] or nil
  end

  local function is_egg(mon)
    return type(mon) == "table" and (mon.isEgg == true or mon.egg == true)
  end

  local function ability_of(mon)
    if type(mon) ~= "table" then return 0 end
    local a = tonumber(mon.abilityId or mon.ability)
    if a then return a end
    local Pokemon = require("src.core.game3.pokemon")
    return tonumber(Pokemon.abilityId(mon.species or mon.speciesId, mon.personality)) or 0
  end

  local function lead_ability()
    local mon = lead()
    if is_egg(mon) then return nil end
    return ability_of(mon)
  end

  local function ability(name) return C():require("abilities", name) end

  -- pokeemerald/src/wild_encounter.c:268
  local function choose_level(entry)
    local lo = tonumber(entry.minLevel or entry.level) or 1
    local hi = tonumber(entry.maxLevel or entry.level) or lo
    if hi < lo then lo, hi = hi, lo end
    local rand = Rng.Random() % (hi - lo + 1)
    local ab = not rs and lead_ability()
    if ab and (ab == ability("ABILITY_HUSTLE") or ab == ability("ABILITY_VITAL_SPIRIT")
        or ab == ability("ABILITY_PRESSURE")) then
      if Rng.Random() % 2 == 0 then return hi end
      if rand ~= 0 then rand = rand - 1 end
    end
    return lo + rand
  end
  R.chooseLevel = choose_level

  -- pokeemerald/src/wild_encounter.c:182
  local function choose_land()
    return H.pick_slot_index(H.LAND_WEIGHTS)
  end

  -- pokeemerald/src/wild_encounter.c:213
  local function choose_water_rock()
    return H.pick_slot_index(H.WATER_WEIGHTS)
  end

  -- pokeemerald/src/wild_encounter.c:915
  local function index_by_type(slots, typeId, numMon)
    local Pokemon = require("src.core.game3.pokemon")
    local valid = {}
    for i = 1, numMon do
      local e = slots[i]
      local sp = type(e) == "table" and tonumber(e.species or e[1]) or nil
      if sp then
        local t = Pokemon.types(sp)
        if t[1] == typeId or t[2] == typeId then valid[#valid + 1] = i end
      end
    end
    if #valid == 0 or #valid == numMon then return nil end
    return valid[(Rng.Random() % #valid) + 1]
  end

  -- pokeemerald/src/wild_encounter.c:938
  local function ability_index(slots, typeId, abilityName)
    if rs then return nil end
    local ab = lead_ability()
    if not ab or ab ~= ability(abilityName) then return nil end
    if Rng.Random() % 2 ~= 0 then return nil end
    return index_by_type(slots, typeId, NUM_LAND_MONS_ENCOUNTER_SLOTS)
  end

  -- pokeemerald/src/wild_encounter.c:897
  local function ability_allows(level)
    if rs then return true end
    local mon = lead()
    if is_egg(mon) then return true end
    local ab = ability_of(mon)
    if ab == ability("ABILITY_KEEN_EYE") or ab == ability("ABILITY_INTIMIDATE") then
      local own = tonumber(mon and mon.level) or 0
      if own > 5 and level <= own - 5 and Rng.Random() % 2 == 0 then return false end
    end
    return true
  end

  -- pokeemerald/src/wild_encounter.c:335
  local function pick_nature()
    local s = session()
    if flag("FLAG_SYS_SAFARI_MODE") and Rng.Random() % 100 < 80 then
      local Pokeblock = require("src.core.game3.rse.pokeblock")
      local pb = s and Pokeblock.activeFeederBlock(s)
      if pb then
        local natures = {}
        for i = 0, NUM_NATURES - 1 do natures[i] = i end
        for i = 0, NUM_NATURES - 2 do
          for j = i + 1, NUM_NATURES - 1 do
            if bit.band(Rng.Random(), 1) ~= 0 then natures[i], natures[j] = natures[j], natures[i] end
          end
        end
        for i = 0, NUM_NATURES - 1 do
          if Pokeblock.gain(natures[i], pb) > 0 then return natures[i] end
        end
      end
    end
    local mon = lead()
    if not rs and not is_egg(mon) and ability_of(mon) == ability("ABILITY_SYNCHRONIZE") and Rng.Random() % 2 == 0 then
      return (tonumber(mon and mon.personality) or 0) % NUM_NATURES
    end
    return Rng.Random() % NUM_NATURES
  end

  local function gender_of(species, personality)
    local Pokemon = require("src.core.game3.pokemon")
    local meta = Pokemon.speciesMeta(species)
    local ratio = meta and tonumber(meta.genderRatio)
    if ratio == MON_MALE or ratio == nil then return MON_MALE end
    if ratio == MON_FEMALE or ratio == MON_GENDERLESS then return ratio end
    if ratio > personality % 256 then return MON_FEMALE end
    return MON_MALE
  end

  -- pokeemerald/src/wild_encounter.c:379
  local function create_wild(species, level)
    local Pokemon = require("src.core.game3.pokemon")
    local meta = Pokemon.speciesMeta(species)
    local ratio = meta and tonumber(meta.genderRatio)
    local cuteCharm = not rs and not (ratio == MON_MALE or ratio == MON_FEMALE or ratio == MON_GENDERLESS)
    local mon = lead()
    if cuteCharm and not is_egg(mon) and ability_of(mon) == ability("ABILITY_CUTE_CHARM")
        and Rng.Random() % 3 ~= 0 then
      local g = gender_of(tonumber(mon.species or mon.speciesId) or 0, tonumber(mon.personality) or 0)
      local want = (g == MON_FEMALE) and MON_MALE or MON_FEMALE
      local nature = pick_nature()
      local p
      -- pokeemerald/src/pokemon.c:2337
      repeat
        p = Rng.Random32()
      until p % NUM_NATURES == nature and gender_of(species, p) == want
      return { species = species, level = level, personality = p }
    end
    local nature = pick_nature()
    local p
    -- pokeemerald/src/pokemon.c:2309
    repeat
      p = Rng.Random32()
    until p % NUM_NATURES == nature
    local enc = { species = species, level = level, personality = p }
    if rs then
      -- pokeruby/src/pokemon_1.c:1445
      local iv1, iv2 = Rng.Random(), Rng.Random()
      enc.ivs = {
        hp = iv1 % 32, atk = math.floor(iv1 / 32) % 32, def = math.floor(iv1 / 1024) % 32,
        spe = iv2 % 32, spa = math.floor(iv2 / 32) % 32, spd = math.floor(iv2 / 1024) % 32,
      }
    end
    return enc
  end
  R.createWild = create_wild

  -- pokeemerald/src/wild_encounter.c:422
  local function try_generate(area, kind, checkRepel, checkKeenEye)
    local slots = area.slots
    local idx
    if kind == "land" then
      idx = ability_index(slots, TYPE_STEEL, "ABILITY_MAGNET_PULL")
        or ability_index(slots, TYPE_ELECTRIC, "ABILITY_STATIC")
        or choose_land()
    elseif kind == "water" then
      idx = ability_index(slots, TYPE_ELECTRIC, "ABILITY_STATIC") or choose_water_rock()
    else
      idx = choose_water_rock()
    end
    local entry = slots[idx]
    if type(entry) ~= "table" then return nil end
    local level = choose_level(entry)
    if checkRepel and not H.wild_level_allowed_by_repel(level) then return nil end
    if checkKeenEye and not ability_allows(level) then return nil end
    return create_wild(tonumber(entry.species or entry[1]), level)
  end
  R.tryGenerate = try_generate

  -- pokeemerald/src/wild_encounter.c:502
  function R.encounterRate(rate, opts)
    local r = (tonumber(rate) or 0) * 16
    if H.bike_active() then r = math.floor(r * 80 / 100) end
    -- pokeemerald/src/wild_encounter.c:955
    if flag("FLAG_SYS_ENC_UP_ITEM") then
      r = r + math.floor(r / 2)
    elseif flag("FLAG_SYS_ENC_DOWN_ITEM") then
      r = math.floor(r / 2)
    end
    -- pokeemerald/src/wild_encounter.c:963
    local mon = lead()
    if type(mon) == "table" and (tonumber(mon.item or mon.heldItem) or 0) == C():require("items", "ITEM_CLEANSE_TAG") then
      r = math.floor(r * 2 / 3)
    end
    if not (opts and opts.ignoreAbility) and not is_egg(mon) then
      local ab = ability_of(mon)
      if not rs and ab == ability("ABILITY_STENCH") and opts and opts.pyramidFloor then
        r = math.floor(r * 3 / 4)
      elseif ab == ability("ABILITY_STENCH") then
        r = math.floor(r / 2)
      elseif ab == ability("ABILITY_ILLUMINATE") then
        r = r * 2
      elseif not rs and ab == ability("ABILITY_WHITE_SMOKE") then
        r = math.floor(r / 2)
      elseif not rs and ab == ability("ABILITY_ARENA_TRAP") then
        r = r * 2
      elseif not rs and ab == ability("ABILITY_SAND_VEIL") then
        local Weather = package.loaded["src.core.game3.weather"]
        local w = Weather and Weather.get and Weather.get()
        if w == C():require("weather", "WEATHER_SANDSTORM") then r = math.floor(r / 2) end
      end
    end
    if r > MAX_ENCOUNTER_RATE then r = MAX_ENCOUNTER_RATE end
    return r
  end

  -- pokeemerald/src/wild_encounter.c:493
  local function wild_check(rate, ignoreAbility)
    local r = R.encounterRate(rate, { ignoreAbility = ignoreAbility })
    return Rng.Random() % MAX_ENCOUNTER_RATE < r
  end

  -- pokeemerald/src/wild_encounter.c:533
  local function allow_new_metatile()
    return Rng.Random() % 100 < 60
  end

  local function current_map_is(mapId, const)
    local MapIds = require("src.core.game3.map_ids")
    return mapId ~= nil and mapId == MapIds.forConst(const, H.constants().game)
  end

  -- pokeemerald/src/wild_encounter.c:541
  local function sootopolis_blocks(mapId)
    if rs then return false end
    if not current_map_is(mapId, "MAP_SOOTOPOLIS_CITY") then return false end
    return flag("FLAG_LEGENDARIES_IN_SOOTOPOLIS")
  end

  local function tile_bits(behavior)
    local Coll = package.loaded["src.core.game3.scripting.collision_rse"]
    local bits = Coll and Coll._tileBits
    if not bits or behavior == nil then return nil end
    return tonumber(bits[behavior]) or 0
  end

  local function is_bridge_over_water(behavior)
    local MB = require("src.core.game3.mb")
    if rs then
      -- pokeruby/src/metatile_behavior.c:874
      local raw = MB.translator(C().game).raw(behavior)
      return raw ~= nil and raw >= 0x70 and raw <= 0x73
    end
    for _, name in ipairs(BRIDGE_OVER_WATER) do
      if behavior == MB.id(name) then return true end
    end
    return false
  end

  -- pokeemerald/src/metatile_behavior.c:819
  local function classify(behavior, terrain)
    local bits = tile_bits(behavior)
    local Player = package.loaded["src.core.game3.player"]
    local surfing = Player and Player.surfing == true
    if bits == nil then
      if terrain == "land" or terrain == "water" then return terrain end
      return nil
    end
    local enc = bit.band(bits, TILE_FLAG_HAS_ENCOUNTERS) ~= 0
    local surf = bit.band(bits, TILE_FLAG_SURFABLE) ~= 0
    if enc and not surf then return "land" end
    if (enc and surf) or (surfing and is_bridge_over_water(behavior)) then return "water" end
    return nil
  end
  R.classify = classify

  -- pokeemerald/src/wild_encounter.c:481
  local function outbreak_test(mapId)
    local s = session()
    local o = s and s.outbreak
    if type(o) ~= "table" or (tonumber(o.species) or 0) == 0 then return nil end
    if o.map ~= mapId then return nil end
    if Rng.Random() % 100 < (tonumber(o.probability) or 0) then return o end
    return nil
  end

  -- pokeemerald/src/wild_encounter.c:467
  local function outbreak_mon(o, checkRepel)
    if checkRepel and not H.wild_level_allowed_by_repel(tonumber(o.level) or 0) then return nil end
    local enc = create_wild(tonumber(o.species), tonumber(o.level) or 1)
    if type(o.moves) == "table" then
      enc.moves = {}
      for i = 1, 4 do enc.moves[i] = o.moves[i] end
    end
    return enc
  end

  local function roamer_encounter(mapId, areaKey)
    local s = session()
    if not (s and type(s.roamer) == "table" and s.roamer.active) then return nil end
    local okR, Roamer = pcall(require, "src.core.game3.roamer")
    if not (okR and Roamer and Roamer.tryEncounter) then return nil end
    local enc = Roamer.tryEncounter(s, mapId, areaKey)
    if enc and not H.wild_level_allowed_by_repel(tonumber(enc.level) or 0) then return false end
    return enc
  end

  local function land_area(t)
    return H.normalize_area(t and t.land) or H.normalize_area(t and t.grass)
  end

  -- pokeemerald/src/wild_encounter.c:552
  local function facilityEncounter(mod, map, mapId, cur, prev)
    local F = package.loaded[mod]
    if not (F and mapId == F[map]) then return false end
    local Rse = require("src.core.game3.rse.init")
    local sess = Rse.session()
    local enc = sess and F.standardWildEncounter(sess, cur, prev)
    if enc then
      E._immunitySteps = 0
      F.startWildBattle(sess, enc)
    end
    return true
  end

  function R.standard(mapId, cur, prev, terrain)
    -- pokeemerald/src/wild_encounter.c:578
    if not rs and facilityEncounter("src.core.game3.rse.frontier.pyramid", "FLOOR_MAP", mapId, cur, prev) then return nil end
    -- pokeemerald/src/wild_encounter.c:563
    if not rs and facilityEncounter("src.core.game3.rse.frontier.pike", "WILD_ROOM", mapId, cur, prev) then return nil end
    E.ensureLoaded()
    local t = H.table_for(mapId)
    if not t then return nil end
    local kind = classify(cur, terrain)
    if kind == "land" then
      local area = land_area(t)
      if not area or #area.slots == 0 then return nil end
      if prev ~= cur and not allow_new_metatile() then return nil end
      if not wild_check(area.rate, false) then return nil end
      local roamer = roamer_encounter(mapId, "land")
      if roamer ~= nil then return roamer or nil end
      local o = outbreak_test(mapId)
      if o then
        local enc = outbreak_mon(o, true)
        if enc then return enc end
      end
      return try_generate(area, "land", true, true)
    elseif kind == "water" then
      if sootopolis_blocks(mapId) then return nil end
      local area = H.normalize_area(t.water, 15)
      if not area or #area.slots == 0 then return nil end
      if prev ~= cur and not allow_new_metatile() then return nil end
      if not wild_check(area.rate, false) then return nil end
      local roamer = roamer_encounter(mapId, "water")
      if roamer ~= nil then return roamer or nil end
      return try_generate(area, "water", true, true)
    end
    return nil
  end

  -- pokeemerald/src/field_control_avatar.c:668
  function R.step(mapId, terrain, opts)
    opts = opts or {}
    local cur = opts.behavior
    if E._immunitySteps < IMMUNITY_STEPS then
      E._immunitySteps = E._immunitySteps + 1
      E._rsePrevBehavior = cur
      return nil
    end
    local enc = R.standard(mapId, cur, E._rsePrevBehavior, opts.terrain or terrain)
    if enc then E._immunitySteps = 0 end
    E._rsePrevBehavior = cur
    return enc
  end

  -- pokeemerald/src/field_control_avatar.c:662
  function R.resetRateModifiers()
    E._immunitySteps = 0
  end

  function R.rollLand(mapId)
    E.ensureLoaded()
    local area = land_area(H.table_for(mapId))
    if not area or #area.slots == 0 then return nil end
    if not wild_check(area.rate, false) then return nil end
    return try_generate(area, "land", true, true)
  end

  function R.rollWater(mapId)
    E.ensureLoaded()
    local t = H.table_for(mapId)
    local area = H.normalize_area(t and t.water, 15)
    if not area or #area.slots == 0 then return nil end
    if not wild_check(area.rate, false) then return nil end
    return try_generate(area, "water", true, true)
  end

  -- pokeemerald/src/wild_encounter.c:704
  function R.sweetScentFacility(mapId)
    if rs then return nil end
    for _, f in ipairs({
      { "src.core.game3.rse.frontier.pike", "WILD_ROOM" },
      { "src.core.game3.rse.frontier.pyramid", "FLOOR_MAP" },
    }) do
      local F = package.loaded[f[1]]
      if F and mapId == F[f[2]] then
        local sess = require("src.core.game3.rse.init").session()
        return sess ~= nil and F.sweetScentWildEncounter(sess) == true
      end
    end
    return nil
  end

  -- pokeemerald/src/wild_encounter.c:697
  function R.rollSweetScent(mapId, terrain)
    E.ensureLoaded()
    local t = H.table_for(mapId)
    local water = terrain == "water"
    local area
    if water then
      if sootopolis_blocks(mapId) then return nil end
      area = H.normalize_area(t and t.water, 15)
    else
      area = land_area(t)
    end
    if not area or #area.slots == 0 then return nil end
    local s = session()
    if s and type(s.roamer) == "table" and s.roamer.active then
      local okR, Roamer = pcall(require, "src.core.game3.roamer")
      local enc = okR and Roamer and Roamer.tryEncounter and Roamer.tryEncounter(s, mapId, water and "water" or "land")
      if enc then return enc end
    end
    if not water then
      local o = outbreak_test(mapId)
      local enc = o and outbreak_mon(o, false)
      if enc then return enc end
    end
    return try_generate(area, water and "water" or "land", false, false)
  end

  -- pokeemerald/src/wild_encounter.c:668
  function R.rollRocks(mapId)
    E.ensureLoaded()
    local t = H.table_for(mapId)
    local area = H.normalize_area(t and t.rocks, 20)
    if not area or #area.slots == 0 then return nil end
    if not wild_check(area.rate, true) then return nil end
    return try_generate(area, "rocks", true, true)
  end

  -- pokeemerald/src/wild_encounter.c:770
  function R.hasFishingMons(mapId)
    E.ensureLoaded()
    local t = H.table_for(mapId)
    local area = H.normalize_area(t and t.fishing, 0)
    return area ~= nil and #area.slots > 0
  end

  local extra
  local function wild_extra()
    if extra then return extra end
    extra = assert(E.loadCacheFile("wild_extra.lua"), "wild_extra.lua is not in the cache")
    return extra
  end
  R.wildExtra = wild_extra

  local function feebas_random(state)
    state.v = (Rng.mulU32(1103515245, state.v) + 12345) % 4294967296
    return math.floor(state.v / 65536)
  end

  -- pokeemerald/src/wild_encounter.c:90
  local function feebas_spot_id(tx, ty, sec, behaviorAt, width)
    local MB = require("src.core.game3.mb")
    local waterfall = MB.id("WATERFALL")
    local spot = sec.spotBase
    for y = sec.yMin, sec.yMax do
      for x = 0, width - 1 do
        local b = behaviorAt(x, y)
        local bits = tile_bits(b) or 0
        if bit.band(bits, TILE_FLAG_SURFABLE) ~= 0 and b ~= waterfall then
          spot = spot + 1
          if tx == x and ty == y then return spot end
        end
      end
    end
    return spot + 1
  end

  -- pokeemerald/src/wild_encounter.c:113
  function R.checkFeebas(mapId, opts)
    if not current_map_is(mapId, "MAP_ROUTE119") then return false end
    opts = opts or {}
    local x, y = tonumber(opts.x), tonumber(opts.y)
    local sections = wild_extra().feebas.sections
    local section = 0
    for i = 1, 3 do
      local sec = sections[i]
      if y and y >= sec.yMin and y <= sec.yMax then section = i - 1 end
    end
    if Rng.Random() % 100 > 49 then return false end
    local s = session()
    local trend = s and type(s.dewfordTrends) == "table" and s.dewfordTrends[1]
    local state = { v = tonumber(trend and trend.rand) or 0 }
    local spots = {}
    local i = 0
    while i ~= NUM_FEEBAS_SPOTS do
      local v = feebas_random(state) % NUM_FISHING_SPOTS
      if v == 0 then v = NUM_FISHING_SPOTS end
      spots[i + 1] = v
      if v < 1 or v >= 4 then i = i + 1 end
    end
    local Coll = package.loaded["src.core.game3.collision"]
    local behaviorAt = opts.behaviorAt or (Coll and Coll.behavior)
    local layout = Coll and Coll._mapDef and Coll._mapDef.midLayout
    local width = tonumber(opts.mapWidth) or (layout and layout.width) or 0
    if not (behaviorAt and x and y) then return false end
    local id = feebas_spot_id(x, y, sections[section + 1], behaviorAt, width)
    for k = 1, NUM_FEEBAS_SPOTS do
      if id == spots[k] then return true end
    end
    return false
  end

  -- pokeemerald/src/wild_encounter.c:780
  function R.rollFishing(mapId, rodKind, opts)
    E.ensureLoaded()
    if R.checkFeebas(mapId, opts) then
      local mon = wild_extra().feebas.mon
      return create_wild(tonumber(mon.species), choose_level(mon))
    end
    local t = H.table_for(mapId)
    local area = H.normalize_area(t and t.fishing, 0)
    if not area or #area.slots == 0 then return nil end
    local rod = ROD_KINDS[rodKind] or 0
    local rand = Rng.Random() % 100
    local idx = 0
    for _, w in ipairs(FISHING_WINDOWS[rod]) do
      if rand < w[1] then
        idx = w[2]
        break
      end
    end
    local entry = area.slots[idx + 1]
    if type(entry) ~= "table" then return nil end
    return create_wild(tonumber(entry.species or entry[1]), choose_level(entry))
  end

  -- pokeemerald/src/pokemon.c:6678
  function R.wildHeldItem(species, opts)
    opts = opts or {}
    local Pokemon = require("src.core.game3.pokemon")
    local rnd = Rng.Random() % 100
    local noItem, notRare = 45, 95
    local mon = lead()
    if not rs and not is_egg(mon) and ability_of(mon) == ability("ABILITY_COMPOUND_EYES") then
      noItem, notRare = 20, 80
    end
    local meta = Pokemon.speciesMeta(species) or {}
    local common, rare = tonumber(meta.itemCommon) or 0, tonumber(meta.itemRare) or 0
    if not rs and opts.alteringCave then
      local rows = wild_extra().alteringCaveHeldItems
      -- pokeemerald/src/pokemon.c:6669
      local id = 0
      for i = 1, #rows do
        if tonumber(rows[i].species) == tonumber(species) then
          id = i - 1
          break
        end
      end
      if id ~= 0 then
        if rnd < notRare then return nil end
        return rows[id + 1].item
      end
      if rnd < noItem then return nil end
      if rnd < notRare then return common end
      return rare
    end
    if common == rare and common ~= 0 then return common end
    if rnd < noItem then return nil end
    if rnd < notRare then return common end
    return rare
  end

  return R
end

return M
