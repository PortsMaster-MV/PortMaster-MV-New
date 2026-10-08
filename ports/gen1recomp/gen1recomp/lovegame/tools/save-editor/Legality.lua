-- Read-only checks against the active game's data. A clean property report
-- deliberately stays "unchecked" until encounter/event/RNG provenance can
-- be proved. Never call a structurally valid record fully legal.
local Gen = require("Gen")
local Properties = require("Properties")
local MonOps = require("MonOps")
local L = {}
local IV_KEYS = { "hp", "atk", "def", "spe", "spa", "spd" }
local DV_KEYS = { "hp", "attack", "defense", "speed", "special" }
local function integer(v, lo, hi)
  return type(v) == "number" and v == v and v == math.floor(v) and v >= lo and v <= hi
end
L.integer = integer
function L.mon(S, mon)
  local r = { errors = 0, warnings = 0, checks = {}, status = "unchecked" }
  local function add(kind, field, message)
    r.checks[#r.checks + 1] = { kind = kind, field = field, message = message }
    if kind == "error" then
      r.errors = r.errors + 1
    end
    if kind == "warning" then
      r.warnings = r.warnings + 1
    end
  end
  local function range(field, v, lo, hi)
    if not integer(v, lo, hi) then
      add("error", field, field .. " must be a whole number from " .. lo .. " to " .. hi)
    end
  end
  if type(mon) ~= "table" then
    add("error", "record", "Missing Pokemon record")
    r.status = "invalid"
    return r
  end
  for _, key in ipairs({
    "ivs",
    "evs",
    "dvs",
    "statExp",
    "moves",
    "pp",
    "ppBonuses",
    "contest",
    "stats",
  }) do
    if mon[key] ~= nil and type(mon[key]) ~= "table" then
      add("error", key, key .. " must be a property table")
    end
  end
  if r.errors > 0 then
    r.status = "invalid"
    return r
  end
  local g = Gen.ofState(S)
  local species = mon.species or mon.speciesId
  local def = S.data and S.data.pokemon and S.data.pokemon[species]
  if not def then
    add("error", "species", "Species is missing from the active game catalog")
  end
  range("level", mon.level, 1, 100)
  if type(mon.hp) ~= "number" or mon.hp ~= mon.hp or mon.hp ~= math.floor(mon.hp)
    or mon.hp < 0 or mon.hp == math.huge then
    add("error", "current HP", "Current HP must be a nonnegative whole number")
  end
  for _, key in ipairs({ "happiness", "friendship" }) do
    if mon[key] ~= nil then
      range(key, mon[key], 0, 255)
    end
  end
  if mon.ppBonusesPacked ~= nil then
    range("packed PP Ups", mon.ppBonusesPacked, 0, 255)
  end
  local Ops = require("Ops")
  if
    mon.nickname
    and (Ops.nicknameLength(mon.nickname) > 10 or not Ops.nicknameUsable(S, mon.nickname))
  then
    add(
      "error",
      "nickname",
      "Nickname exceeds the game's name limit or uses unsupported characters"
    )
  end
  for _, d in ipairs(Properties.all(S)) do
    local v = Properties.get(mon, d)
    if d.text then
      if Ops.nicknameLength(v) > d.max or not Ops.nicknameUsable(S, v) then
        add("error", d.key, d.label .. " contains an invalid name")
      end
    else
      local parsed, err = Properties.parse(d, v)
      if parsed == nil then
        add("error", d.key, err)
      end
    end
  end
  if g == 3 then
    local total = 0
    for _, k in ipairs(IV_KEYS) do
      range("IV " .. k, mon.ivs and mon.ivs[k], 0, 31)
      local ev = mon.evs and mon.evs[k] or 0
      range("EV " .. k, ev, 0, 255)
      if integer(ev, 0, 255) then
        total = total + ev
      end
    end
    if total > 510 then
      add("error", "evs", "Total EVs exceed 510 (" .. total .. ")")
    end
    local Pokemon = require("src.core.game3.pokemon")
    local pid = mon.personality
    if integer(pid, 0, 4294967295) then
      if mon.nature ~= nil and mon.nature ~= pid % 25 then
        add("error", "nature", "Nature disagrees with PID")
      end
      if mon.gender and mon.gender ~= Pokemon.gender(species, pid) then
        add("error", "gender", "Gender disagrees with the species and PID")
      end
      local pair = Pokemon.abilities(species)
      local slot = mon.abilityNum or (pair[2] and pair[2] ~= 0 and pid % 2 or 0)
      range("ability slot", slot, 0, 1)
      local expected = integer(slot, 0, 1) and pair[slot + 1] or nil
      if expected == 0 or not expected or (mon.ability and mon.ability ~= expected) then
        add("error", "ability", "Ability is unavailable in the selected species slot")
      end
      local bit = require("bit")
      local shiny = bit.bxor(
        tonumber(mon.otId) or 0,
        tonumber(mon.otSecretId) or 0,
        math.floor(pid / 65536),
        pid % 65536
      ) < 8
      if mon.isShiny ~= nil and mon.isShiny ~= shiny then
        add("error", "shiny", "Shiny flag disagrees with PID and trainer IDs")
      end
    end
    if
      integer(mon.metLevel, 0, 100)
      and integer(mon.level, 1, 100)
      and mon.metLevel > mon.level
    then
      add("error", "metLevel", "Met level exceeds current level")
    end
    local ball = mon.pokeball or 4
    if (mon.isEgg or mon.egg) and ball ~= 4 then
      add("error", "pokeball", "Gen 3 eggs must use a Poke Ball")
    end
    if type(mon.ribbons) == "number" then
      range("ribbon word", mon.ribbons, 0, 4294967295)
    end
    local virus = tonumber(mon.pokerus) or 0
    if integer(virus, 0, 255) then
      local strain, days = math.floor(virus / 16), virus % 16
      if days > 4 or (strain == 0 and days > 0) or (strain > 0 and days > strain % 4 + 1) then
        add("error", "pokerus", "Pokerus days are inconsistent with its strain")
      end
    end
    if math.floor(Properties.ribbonWord(mon) / 2 ^ 27) % 16 ~= 0 then
      add("error", "ribbons", "Unused ribbon bits must be zero")
    end
    if mon.modernFatefulEncounter or mon.ribbons or mon.championRibbon then
      add(
        "warning",
        "ribbons",
        "Ribbon and event eligibility require encounter and distribution history"
      )
    end
  else
    for _, k in ipairs(DV_KEYS) do
      range("DV " .. k, mon.dvs and mon.dvs[k], 0, 15)
      range("Stat experience " .. k, mon.statExp and mon.statExp[k] or 0, 0, 65535)
    end
    local d = mon.dvs or {}
    if
      integer(d.attack, 0, 15)
      and integer(d.defense, 0, 15)
      and integer(d.speed, 0, 15)
      and integer(d.special, 0, 15)
    then
      local hp = d.attack % 2 * 8 + d.defense % 2 * 4 + d.speed % 2 * 2 + d.special % 2
      if d.hp ~= hp then
        add("error", "dvs.hp", "HP DV must be derived from the other four DVs")
      end
      if g == 2 then
        local shiny = d.defense == 10
          and d.speed == 10
          and d.special == 10
          and math.floor(d.attack / 2) % 2 == 1
        if mon.shiny ~= nil and mon.shiny ~= shiny then
          add("error", "shiny", "Shininess disagrees with DVs")
        end
        if
          mon.gender ~= nil
          and def
          and mon.gender ~= require("src.battle.gen2.Mon").gender(def, d)
        then
          add("error", "gender", "Gender disagrees with species and DVs")
        end
        if
          species == "UNOWN"
          and mon.unownLetter ~= nil
          and mon.unownLetter ~= require("src.core.gen2.Unown").letterFromDVs(d)
        then
          add("error", "form", "Unown form disagrees with DVs")
        end
      end
    end
  end
  if g == 2 then
    local virus = mon.pokerus or 0
    range("pokerus", virus, 0, 255)
    if integer(virus, 0, 255) then
      local strain, days = math.floor(virus / 16), virus % 16
      if strain > 8 or days > strain % 4 + 1 or (strain == 0 and days > 0) then
        add("error", "pokerus", "Gen 2 Pokerus strain and days are inconsistent")
      end
    end
  end
  if g >= 2 and (mon.egg or mon.isEgg) and mon.level ~= 5 then
    add("error", "level", "An unhatched egg must be level 5 in this generation")
  end
  local statuses = { SLP = true, PSN = true, BRN = true, FRZ = true, PAR = true, TOX = true }
  if type(mon.status) == "number" and g == 3 then
    local allowed = integer(mon.status, 0, 7)
      or mon.status == 8
      or mon.status == 16
      or mon.status == 32
      or mon.status == 64
      or mon.status == 128
    if not allowed then
      add("error", "status", "Status bits contain an invalid combination")
    end
  elseif mon.status ~= nil and not statuses[mon.status] then
    add("error", "status", "Unknown status condition")
  end
  if mon.status == "SLP" then
    range("sleep", mon.sleep or 1, 1, 7)
  end
  local seen, occupied = {}, 0
  for slot = 1, 4 do
    local mv = mon.moves and mon.moves[slot]
    local id = type(mv) == "table" and (mv.moveId or mv.id) or mv
    if id and id ~= 0 then
      occupied = occupied + 1
      local md = S.data and S.data.moves and S.data.moves[id]
      if not md then
        add(
          "error",
          "move" .. slot,
          "Move " .. tostring(id) .. " is missing from this game's catalog"
        )
      end
      if seen[id] then
        add("error", "move" .. slot, "Duplicate move in slot " .. slot)
      end
      seen[id] = true
      local ups = MonOps.getPpUps(mon, slot)
      range("PP Ups " .. slot, ups, 0, 3)
      if type(mv) == "table" and mv.ppUps ~= nil then
        range("stored PP Ups " .. slot, mv.ppUps, 0, 3)
      end
      local base = MonOps.getBasePp(S.data, mon, slot)
      local max = MonOps.calcMaxPp(base, ups, g)
      local pp = type(mv) == "table" and mv.pp or (mon.pp and mon.pp[slot])
      range("PP " .. slot, pp, 0, max)
      if (mon.egg or mon.isEgg) and (ups ~= 0 or pp ~= base) then
        add("error", "move" .. slot, "Egg moves must have base PP and no PP Ups")
      end
      if md and (md.name == "SKETCH" or id == "SKETCH" or id == 166) and ups > 0 then
        add("error", "move" .. slot, "Sketch cannot use PP Ups")
      end
      local found = false
      local learnset = def and def.learnset or {}
      if g == 3 then
        learnset = require("src.core.game3.pokemon").learnset(species)
      end
      for _, e in ipairs(learnset) do
        if
          (e.move or e.id or e[2]) == id
          and (tonumber(e.level or e[1]) or 1) <= (tonumber(mon.level) or 0)
        then
          found = true
        end
      end
      if g == 3 and not found then
        local Pokemon = require("src.core.game3.pokemon")
        for i = 0, 57 do
          if Pokemon.moveFromTmItem(289 + i) == id and Pokemon.canLearnTmIndex(species, i) then
            found = true
            break
          end
        end
      end
      add(
        found and "pass" or "warning",
        "move" .. slot,
        found and ("Slot " .. slot .. ": current species learns this move")
          or ("Slot " .. slot .. ": check breeding, pre-evolution, tutor, event or trade origin")
      )
    else
      if mon.pp and (mon.pp[slot] or 0) ~= 0 then
        add("error", "move" .. slot, "Empty move slot has nonzero PP")
      end
      if MonOps.getPpUps(mon, slot) ~= 0 then
        add("error", "move" .. slot, "Empty move slot has PP Ups")
      end
    end
  end
  if occupied == 0 and not (mon.egg or mon.isEgg) then
    add("error", "moves", "A non-egg Pokemon needs at least one move")
  end
  if mon.moves then
    for slot in pairs(mon.moves) do
      if not integer(slot, 1, 4) then
        add("error", "moves", "Move slots must be numbered 1-4")
      end
    end
  end
  if integer(mon.level, 1, 100) and def then
    local exp = Gen.exp(mon)
    local lower, upper
    if g == 3 then
      local Summary = require("src.core.game3.summary_data")
      local growth = require("src.core.game3.pokemon").growthRate(species)
      lower = Summary.expForLevel(growth, mon.level)
      upper = Summary.expForLevel(growth, math.min(100, mon.level + 1))
    elseif g == 2 then
      local Mon = require("src.battle.gen2.Mon")
      local growth = Mon.growthFor(S.data, def.growthRate)
      lower, upper =
        Mon.experienceForLevel(growth, mon.level),
        Mon.experienceForLevel(growth, math.min(100, mon.level + 1))
    else
      local Growth = require("src.pokemon.Growth")
      lower = Growth.expForLevel(def.growthRate, mon.level, S.data.growth_rates)
      upper = Growth.expForLevel(def.growthRate, math.min(100, mon.level + 1), S.data.growth_rates)
    end
    if
      not integer(exp, lower, 16777215)
      or (mon.level < 100 and exp >= upper)
      or (mon.level == 100 and exp ~= lower)
    then
      add("error", "experience", "Experience does not match the level and growth curve")
    end
  end
  local held = mon.heldItem or mon.item
  if held and held ~= 0 and held ~= "NONE" then
    local item = S.data and S.data.items and S.data.items[held]
    if not item then
      add("error", "heldItem", "Held item is missing from this game's catalog")
    elseif g == 1 then
      add("error", "heldItem", "Gen 1 does not store held items")
    elseif not Ops.itemHoldable(S, held) then
      add("error", "heldItem", "Key items and HMs cannot be held")
    end
  end
  if r.errors == 0 then
    local copy = require("src.mods.Merge").deepCopy(mon)
    local ok = pcall(MonOps.recalc, S.data, copy, g)
    if ok then
      local max = copy.maxHp or (copy.stats and copy.stats.hp)
      if max then
        range("current HP", mon.hp, 0, max)
      end
      for key, value in pairs(copy.stats or {}) do
        if mon.stats and mon.stats[key] ~= nil and mon.stats[key] ~= value then
          add("error", "stats." .. key, "Calculated " .. key .. " stat disagrees with stored stat")
        end
      end
    else
      add("warning", "stats", "Stats could not be checked against the active game data")
    end
  end
  if g == 3 and (mon.isEgg or mon.egg) then
    if (mon.language or 2) ~= 1 then
      add("error", "language", "Gen 3 eggs must use the Japanese language flag")
    end
    for _, v in pairs(mon.contest or {}) do
      if v ~= 0 then
        add("error", "contest", "Eggs cannot have contest conditions")
        break
      end
    end
  end
  add(
    "warning",
    "encounter",
    "Encounter tables, event distributions, transfer history and PID/IV RNG correlation are not fully verified"
  )
  if r.errors > 0 then
    r.status = "invalid"
  end
  return r
end
-- Match validator fields to the controls that edit them. Warnings are not errors.
function L.highlights(report, mon)
  local out =
    { fields = {}, sections = { main = 0, stats = 0, moves = 0, origin = 0, extras = 0, checks = report.errors } }
  local main = {
    species = true,
    nickname = true,
    level = true,
    experience = true,
    ["current-hp"] = true,
    friendship = true,
    status = true,
    nature = true,
    gender = true,
    ability = true,
    shiny = true,
    heldItem = true,
  }
  local function section(id)
    if main[id] then
      return "main"
    end
    if id:match("^iv%-") or id:match("^ev%-") or id:match("^dv%-") or id:match("^se%-") or id == "calculated" then
      return "stats"
    end
    if id:match("^move%d") or id:match("^pp%-") or id:match("^ppup%-") then
      return "moves"
    end
    if id:match("^contest%.") or id:match("^ribbon%.") then
      return "extras"
    end
    return "origin"
  end
  for _, check in ipairs(report.checks) do
    if check.kind == "error" then
      local ids, f = {}, check.field
      local function add(id)
        ids[#ids + 1] = id
      end
      local key = f:match("^IV (.+)$")
        or f:match("^EV (.+)$")
        or f:match("^DV (.+)$")
        or f:match("^Stat experience (.+)$")
      if key then
        add((f:match("^IV ") and "iv-" or f:match("^EV ") and "ev-" or f:match("^DV ") and "dv-" or "se-") .. key)
      elseif f == "evs" or f == "ivs" then
        for _, k in ipairs(IV_KEYS) do
          add((f == "evs" and "ev-" or "iv-") .. k)
        end
      elseif f == "dvs" or f == "statExp" then
        for _, k in ipairs(DV_KEYS) do
          add((f == "dvs" and "dv-" or "se-") .. k)
        end
      elseif f == "moves" or f == "pp" or f == "ppBonuses" or f == "packed PP Ups" then
        for i = 1, 4 do
          add("move" .. i)
          add("pp-" .. i)
          add("ppup-" .. i)
        end
      elseif f:match("^move%d$") then
        local slot = f:match("(%d)$")
        add(f)
        if check.message:find("PP Ups", 1, true) then
          add("ppup-" .. slot)
        end
        if check.message:find("PP", 1, true) and not check.message:find("Empty move slot has PP Ups", 1, true) then
          add("pp-" .. slot)
        end
      elseif f:match("^PP %d$") then
        add("pp-" .. f:match("(%d)$"))
      elseif f:match("PP Ups %d$") then
        add("ppup-" .. f:match("(%d)$"))
      elseif f == "contest" then
        add("contest")
        for _, d in ipairs(Properties.contest) do
          if not mon or type(mon.contest) ~= "table" or (mon.contest[d.child] or 0) ~= 0 then
            add(d.key)
          end
        end
      elseif f == "ribbons" or f == "ribbon word" then
        add("ribbons")
      else
        add(
          ({
            ["current HP"] = "current-hp",
            happiness = "friendship",
            ["ability slot"] = "ability",
            ["dvs.hp"] = "dv-hp",
            sleep = "status",
          })[f]
            or (f:match("^stats") and "calculated")
            or f
        )
      end
      local counted = {}
      for _, id in ipairs(ids) do
        out.fields[id] = out.fields[id] or check.message
        local page = (id == "contest" or id == "ribbons") and "extras" or section(id)
        if not counted[page] then
          out.sections[page] = out.sections[page] + 1
          counted[page] = true
        end
      end
    end
  end
  return out
end
function L.save(S)
  local report = { entries = {}, errors = 0, warnings = 0 }
  local function inspect(mon, label, box, slot)
    local r = L.mon(S, mon)
    report.entries[#report.entries + 1] =
      { mon = mon, label = label, report = r, box = box, slot = slot }
    report.errors, report.warnings = report.errors + r.errors, report.warnings + r.warnings
  end
  for i, mon in ipairs(S.save.party or {}) do
    inspect(mon, "Party " .. i, nil, i)
  end
  for b, box in ipairs(require("Ops").boxes(S)) do
    for i = 1, Gen.boxCapacity(S.save) do
      if box[i] then
        inspect(box[i], "Box " .. b .. " / " .. i, b, i)
      end
    end
  end
  return report
end
return L
