local Copy = require("src.mods.Merge").deepCopy
local Gen = require("Gen")
local M = require("MonOps")
local P = require("Properties")
local Limits = require("ValueLimits")
local A = {}
local function clamp(v, lo, hi)
	v = tonumber(v)
	if not v or v ~= v or v == math.huge or v == -math.huge then
		v = lo
	end
	return math.max(lo, math.min(hi, math.floor(v)))
end
local function replace(mon, staged)
	for k in pairs(mon) do
		mon[k] = nil
	end
	for k, v in pairs(staged) do
		mon[k] = v
	end
end
local function cleanName(S, name, max)
	local nameClean = require("Ops").nicknameSanitize(S, tostring(name or ""))
	local chars = {}
	for ch in nameClean:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		if #chars < max then
			chars[#chars + 1] = ch
		end
	end
	return table.concat(chars)
end
function A.repair(S, original)
	local Ops, L = require("Ops"), require("Legality")
	if type(original) ~= "table" or not Ops.speciesUsable(S, original.species or original.speciesId) then
		return nil, "Choose a known species first"
	end
	local mon, g = Copy(original), Gen.ofState(S)
	local tables = g == 3 and { "ivs", "evs", "moves", "pp", "ppBonuses", "contest", "stats" }
		or { "dvs", "statExp", "moves", "pp", "ppBonuses", "stats" }
	for _, key in ipairs(tables) do
		if type(mon[key]) ~= "table" then
			mon[key] = {}
		end
	end
	mon.level = clamp(mon.level, 1, 100)
	mon.nickname = cleanName(S, mon.nickname, 10)
	for _, d in ipairs(P.all(S)) do
		local v = P.get(mon, d)
		if d.text then
			v = cleanName(S, v, d.max)
		elseif d.toggle then
			v = v == true or v == 1
		else
			v = clamp(v, d.lo, d.hi)
			if d.values and P.parse(d, v) == nil then
				v = d.default or d.choices[1][1]
			end
		end
		P.write(mon, d, v)
	end
	if mon.happiness ~= nil then
		mon.happiness = clamp(mon.happiness, 0, 255)
	end
	if mon.friendship ~= nil then
		mon.friendship = clamp(mon.friendship, 0, 255)
	end
	if g == 3 then
		local remaining = 510
		for _, k in ipairs(Limits.EV_KEYS) do
			mon.ivs[k] = clamp(mon.ivs[k], 0, 31)
			mon.evs[k] = clamp(mon.evs[k], 0, math.min(255, remaining))
			remaining = remaining - mon.evs[k]
		end
		local Pokemon = require("src.core.game3.pokemon")
		local pair = Pokemon.abilities(mon.species or mon.speciesId)
		mon.abilityNum = pair[2] and pair[2] ~= 0 and mon.personality % 2 or 0
		mon.ability, mon.abilityId, mon.isShiny = pair[mon.abilityNum + 1], pair[mon.abilityNum + 1], nil
		mon.metLevel = math.min(mon.metLevel or 0, mon.level)
		if mon.egg or mon.isEgg then
			mon.level, mon.metLevel, mon.language, mon.pokeball = 5, 0, 1, 4
			for _, d in ipairs(P.contest) do
				P.write(mon, d, 0)
			end
		end
		local bit = require("bit")
		local word = P.get(mon, { ribbon = true, shift = 0, width = 32 })
		word = bit.band(clamp(word, 0, 4294967295), 0x87FFFFFF)
		mon.ribbons = word < 0 and word + 4294967296 or word
	else
		for _, k in ipairs({ "attack", "defense", "speed", "special" }) do
			mon.dvs[k] = clamp(mon.dvs[k], 0, 15)
		end
		M.syncHpDv(mon.dvs)
		for _, k in ipairs({ "hp", "attack", "defense", "speed", "special" }) do
			mon.statExp[k] = clamp(mon.statExp[k], 0, 65535)
		end
		if g == 2 then
			M.setDv(S.data, mon, "attack", mon.dvs.attack, g)
		end
	end
	local strain = math.floor(clamp(mon.pokerus, 0, 255) / 16)
	if g == 2 then
		strain = math.min(8, strain)
	end
	local days = strain == 0 and 0 or math.min(clamp(mon.pokerus, 0, 255) % 16, strain % 4 + 1)
	if mon.pokerus ~= nil then
		mon.pokerus = strain * 16 + days
	end
	local held = mon.heldItem or mon.item
	if held and held ~= 0 and held ~= "NONE" and (g == 1 or not Ops.itemHoldable(S, held)) then
		mon.heldItem, mon.item = nil, nil
	end
	local status = { SLP = true, PSN = true, BRN = true, FRZ = true, PAR = true, TOX = g ~= 1 }
	if type(mon.status) == "number" then
		local allowed = { [0] = true, [8] = true, [16] = true, [32] = true, [64] = true, [128] = true }
		if not allowed[mon.status] and not (mon.status >= 1 and mon.status <= 7) then
			mon.status = nil
		end
	elseif not status[mon.status] then
		mon.status = nil
	end
	mon.sleep = mon.status == "SLP" and clamp(mon.sleep, 1, 7) or nil
	local seen, moves = {}, {}
	for slot = 1, 4 do
		local mv = mon.moves[slot]
		local id = type(mv) == "table" and (mv.moveId or mv.id) or mv
		if id and id ~= 0 and Ops.moveUsable(S, id) and not seen[id] then
			moves[slot], seen[id] = mv, true
		end
	end
	mon.moves = moves
	mon.ppBonusesPacked = clamp(mon.ppBonusesPacked, 0, 255)
	if next(moves) == nil and not (mon.egg or mon.isEgg) then
		local temp = { data = S.data, save = S.save, version = S.version }
		Ops.resetMoves(temp, mon)
	end
	for slot = 1, 4 do
		local mv = mon.moves[slot]
		if mv then
			local ups = clamp(M.getPpUps(mon, slot), 0, 3)
			if mon.egg or mon.isEgg or M.getBasePp(S.data, mon, slot) == 1 then
				ups = 0
			end
			M.setPpUps(S.data, mon, slot, ups, g)
			M.setPp(S.data, mon, slot, clamp(type(mv) == "table" and mv.pp or mon.pp[slot], 0, 255), g)
		else
			M.clearMove(mon, slot)
			mon.pp[slot] = 0
			M.setPpUps(S.data, mon, slot, 0, g)
		end
	end
	local lo = Limits.expAt(S, mon, mon.level)
	local hi = mon.level == 100 and lo or Limits.expAt(S, mon, mon.level + 1) - 1
	local exp = clamp(Gen.exp(mon), lo, hi)
	if g == 2 then
		mon.experience = exp
	else
		mon.exp = exp
	end
	if mon.exp ~= nil then
		mon.exp = exp
	end
	if mon.experience ~= nil then
		mon.experience = exp
	end
	M.recalc(S.data, mon, g)
	mon.hp = clamp(mon.hp, 0, mon.maxHp or mon.stats.hp)
	local report = L.mon(S, mon)
	if report.errors > 0 then
		for _, check in ipairs(report.checks) do
			if check.kind == "error" then
				return nil, check.message
			end
		end
	end
	return mon
end
function A.fixMon(S, mon)
	local Ops, L = require("Ops"), require("Legality")
	if L.mon(S, mon).errors == 0 then
		return Ops.say(S, "No property errors to fix")
	end
	local staged, err = A.repair(S, mon)
	if not staged then
		return Ops.say(S, err)
	end
	replace(mon, staged)
	return Ops.mark(S, "Fixed property errors. Check origin warnings separately.")
end
function A.fixAll(S)
	local fixed, left = 0, 0
	for _, entry in ipairs(require("Legality").save(S).entries) do
		if entry.report.errors > 0 then
			local staged = A.repair(S, entry.mon)
			if staged then
				replace(entry.mon, staged)
				fixed = fixed + 1
			else
				left = left + 1
			end
		end
	end
	local msg = "Fixed " .. fixed .. " Pokémon"
	if left > 0 then
		msg = msg .. "; " .. left .. " need a manual choice"
	end
	if fixed == 0 then
		return require("Ops").say(S, left > 0 and msg or "No property errors to fix")
	end
	return require("Ops").mark(S, msg .. ". Origin warnings stay for review.")
end
function A.maxMon(S, mon)
	local Ops, g = require("Ops"), Gen.ofState(S)
	local staged, err = A.repair(S, mon)
	if not staged then
		return Ops.say(S, err)
	end
	if staged.egg or staged.isEgg then
		return Ops.say(S, "Hatch the egg before maxing it out")
	end
	M.setLevel(S.data, staged, 100, g)
	M.setHappiness(S.data, staged, 255, g)
	if g == 3 then
		M.maxIvs(S.data, staged, g)
		-- Keep the existing spread; spend unused points on the strongest stats.
		local stats = staged.stats or {}
		local map = {
			hp = "hp",
			atk = "attack",
			def = "defense",
			spa = "specialAttack",
			spd = "specialDefense",
			spe = "speed",
		}
		local keys = Copy(Limits.EV_KEYS)
		table.sort(keys, function(a, b)
			local av, bv = stats[map[a]] or 0, stats[map[b]] or 0
			return av ~= bv and av > bv or av == bv and a < b
		end)
		for _, k in ipairs(keys) do
			M.setEv(S.data, staged, k, math.max(staged.evs[k] or 0, 252), g)
		end
	else
		for _, k in ipairs({ "attack", "defense", "speed", "special" }) do
			M.setDv(S.data, staged, k, 15, g)
		end
		for _, k in ipairs({ "hp", "attack", "defense", "speed", "special" }) do
			staged.statExp[k] = 65535
		end
	end
	M.maxAllPpUps(S.data, staged, g)
	M.recalc(S.data, staged, g)
	staged.hp, staged.status = staged.maxHp or staged.stats.hp, nil
	staged.sleep, staged.toxicCounter = nil, nil
	local result = require("Legality").mon(S, staged)
	if result.errors > 0 then
		for _, check in ipairs(result.checks) do
			if check.kind == "error" then
				return Ops.say(S, "Max refused: " .. check.message)
			end
		end
	end
	replace(mon, staged)
	return Ops.mark(S, "Maxed level, stats, friendship and PP; fully healed")
end
-- pokefirered/src/wild_encounter.c:49 sUnownLetterSlots, by chamber.
local UNOWN_LETTERS = {
	MAPSEC_MONEAN_CHAMBER = { 0, 27 },
	MAPSEC_LIPTOO_CHAMBER = { 2, 3, 7, 20, 14 },
	MAPSEC_WEEPTH_CHAMBER = { 13, 18, 8, 4 },
	MAPSEC_DILFORD_CHAMBER = { 15, 11, 9, 17, 16 },
	MAPSEC_SCUFIB_CHAMBER = { 24, 19, 6, 5, 10 },
	MAPSEC_RIXY_CHAMBER = { 21, 22, 23, 12, 1 },
	MAPSEC_VIAPOIS_CHAMBER = { 25, 26 },
}
local function random(lo, hi)
	return math.random(lo, hi)
end
function A.encounters(S)
	if S._randomEncounters then
		return S._randomEncounters
	end
	local candidates, g = {}, Gen.ofState(S)
	local tables = S.data.gen2Encounters or S.data.encounters or {}
	if g == 2 and (tables.grass or tables.water) then
		tables = { grass = tables.grass, water = tables.water }
	end
	if g == 3 then
		local E = require("src.core.game3.encounters")
		E.ensureLoaded()
		tables = {}
		for map in pairs(S.data.maps or {}) do
			if type(map) == "string" then
				tables[map] = E.tableFor(map)
			end
		end
	end
	local function walk(t, map, time)
		if type(t) ~= "table" then
			return
		end
		local sp = t.species or t.pokemon
		local lo = tonumber(t.minLevel or t.level)
		local hi = tonumber(t.maxLevel or t.level)
		if sp and lo and hi and require("Ops").speciesUsable(S, sp) then
			local def = map and S.data.maps and S.data.maps[map]
			local location = def and tonumber(g == 3 and def.regionMapSectionId or def.landmark)
			if (g ~= 3 and not Gen.hasCaughtData(S.save, S.version)) or location then
				candidates[#candidates + 1] =
					{ species = sp, lo = lo, hi = hi, map = map, location = location, time = time }
			end
		else
			for key, v in pairs(t) do
				local nextMap = type(key) == "string" and S.data.maps and S.data.maps[key] and key or map
				local nextTime = ({ MORN = 1, DAY = 2, NITE = 3 })[key] or time
				walk(v, nextMap, nextTime)
			end
		end
	end
	walk(tables)
	S._randomEncounters = candidates
	return candidates
end
function A.randomize(S, mon)
	local Ops, g = require("Ops"), Gen.ofState(S)
	local candidates = A.encounters(S)
	if #candidates == 0 then
		return Ops.say(S, "This game's encounter data is unavailable")
	end
	local row = candidates[random(1, #candidates)]
	local staged = M.create(S.data, row.species, random(row.lo, row.hi), g)
	staged.ot = S.save.player and S.save.player.name or S.save.name or "RED"
	staged.otName = staged.ot
	staged.otId = S.save.player and S.save.player.id or S.save.trainerId or 0
	if g == 3 then
		-- Independent stream: editing never advances the running game's RNG.
		local R = require("src.core.game3.rng")
		local seed = random(0, 65535) + random(0, 65535) * 65536
		local function next16()
			seed = (R.mulU32(seed, 1103515245) + 24691) % 4294967296
			return math.floor(seed / 65536)
		end
		local v = Gen.versionOf(S.save, S.version)
		local isRse = require("src.core.GameVersion").layout(v) == "rse"
		local constants = require("src.core.game3.constants").of(v)
		local sections = constants.region_map_sections.byName
		local safari = row.location == sections.MAPSEC_SAFARI_ZONE or row.location == sections.MAPSEC_KANTO_SAFARI_ZONE
		if safari then
			staged.pokeball = 5
		end
		if tonumber(staged.species) == constants:id("species", "SPECIES_UNOWN") and not isRse then
			local letters = UNOWN_LETTERS[constants:name("region_map_sections", row.location, "MAPSEC_")]
			if not letters then
				return Ops.say(S, "No verified Unown form for this location")
			end
			local letter = letters[random(1, #letters)]
			-- Unown uses high-half first; normal Random32 uses low-half first.
			repeat
				local high, low = next16(), next16()
				staged.personality = low + high * 65536
			until require("src.core.game3.pokemon").unownLetter(staged.personality) == letter
		else
			-- GenerateWildMon -> CreateMonWithNature -> CreateBoxMon. Preserve
			-- the native nature rejection loop and its following two IV draws.
			if isRse and safari then
				next16()
			end
			local nature = next16() % 25
			repeat
				local low, high = next16(), next16()
				staged.personality = low + high * 65536
			until staged.personality % 25 == nature
		end
		local iv1, iv2 = next16(), next16()
		staged.ivs = {
			hp = iv1 % 32,
			atk = math.floor(iv1 / 32) % 32,
			def = math.floor(iv1 / 1024) % 32,
			spe = iv2 % 32,
			spa = math.floor(iv2 / 32) % 32,
			spd = math.floor(iv2 / 1024) % 32,
		}
		staged.abilityNum = nil
		staged.otSecretId = S.save.secretId or 0
		staged.otGender = S.save.gender or 0
		staged.language, staged.metLocation, staged.metLevel = 2, row.location, staged.level
		staged.metGame = require("src.core.GameVersion").gameCode(Gen.versionOf(S.save, S.version))
	elseif g == 2 and Gen.hasCaughtData(S.save, S.version) then
		staged.caughtLevel = math.min(63, staged.level)
		staged.caughtLocation, staged.caughtTime = row.location, row.time or 2
		staged.caughtByGender = Gen.playerGender(S.save) == "female" and "girl" or "boy"
	end
	M.recalc(S.data, staged, g)
	staged.hp = staged.maxHp or staged.stats.hp
	local report = require("Legality").mon(S, staged)
	if report.errors > 0 then
		return Ops.say(S, "Randomization refused: generated values failed checks")
	end
	replace(mon, staged)
	return Ops.mark(S, "Randomized " .. Ops.monName(S, mon) .. " from this game's wild encounters")
end
return A
