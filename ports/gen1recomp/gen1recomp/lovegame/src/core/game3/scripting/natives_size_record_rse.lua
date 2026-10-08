-- Emerald size-record specials (pokeemerald/src/pokemon_size_record.c).
local Std = require("src.core.game3.scripting.stdscripts")
local SizeRecord = require("src.core.game3.pokemon_size_record")

local Natives = {}

local function session(ctx)
  return SizeRecord.sessionOf(ctx)
end

local function specialVarId(ctx, name)
  return SizeRecord.variable(name, session(ctx))
end

local function formatMetric(size)
  size = tonumber(size) or 0
  return string.format("%d.%d", math.floor(size / 10), size % 10)
end

local function setResult(ctx, value)
  SizeRecord.setVar(session(ctx), ctx, specialVarId(ctx, "VAR_RESULT"), value)
end

local function ids(ctx, speciesName, varName)
  local sess = session(ctx)
  return SizeRecord.species(speciesName, sess), SizeRecord.variable(varName, sess)
end

local function recordInfo(ctx, adapters, species, varId)
  local sess = session(ctx)
  local record = SizeRecord.getVar(sess, ctx, varId)
  local size = SizeRecord.getMonSize(species, record, sess)
  SizeRecord.setStringVar(ctx, adapters, 1, require("src.core.game3.pokemon").name(species))
  local name = sess and (sess.playerName or sess.name) or ""
  local trainer = record == SizeRecord.DEFAULT_MAX_SIZE and require("src.core.game3.rom_text").plain("gText_Marco") or name
  SizeRecord.setStringVar(ctx, adapters, 2, trainer)
  SizeRecord.setStringVar(ctx, adapters, 3, formatMetric(size))
end

local function compare(ctx, adapters, species, varId)
  local sess = session(ctx)
  local slot = SizeRecord.getVar(sess, ctx, specialVarId(ctx, "VAR_RESULT"))
  local party = sess and sess.party or {}
  if slot >= SizeRecord.PARTY_SIZE then
    setResult(ctx, 0)
    return false
  end
  local mon = party[slot + 1]
  if not mon or mon.isEgg or mon.is_egg or tonumber(mon.species or mon.speciesId) ~= species then
    setResult(ctx, 1)
    return false
  end

  local hash = SizeRecord.getMonSizeHash(mon)
  local newSize = SizeRecord.getMonSize(species, hash, sess)
  local oldSize = SizeRecord.getMonSize(species, SizeRecord.getVar(sess, ctx, varId), sess)
  SizeRecord.setStringVar(ctx, adapters, 2, formatMetric(newSize))
  if newSize <= oldSize then
    setResult(ctx, 2)
  else
    SizeRecord.setVar(sess, ctx, varId, hash)
    setResult(ctx, 3)
  end
  return false
end

Natives.BY_NAME = {
  -- pokeemerald/src/pokemon_size_record.c:157
  GetSeedotSizeRecordInfo = function(ctx, adapters)
    local species, var = ids(ctx, "SPECIES_SEEDOT", "VAR_SEEDOT_SIZE_RECORD")
    recordInfo(ctx, adapters, species, var)
    return false
  end,
  -- pokeemerald/src/pokemon_size_record.c:164
  CompareSeedotSize = function(ctx, adapters)
    local species, var = ids(ctx, "SPECIES_SEEDOT", "VAR_SEEDOT_SIZE_RECORD")
    return compare(ctx, adapters, species, var)
  end,
  -- pokeemerald/src/pokemon_size_record.c:176
  GetLotadSizeRecordInfo = function(ctx, adapters)
    local species, var = ids(ctx, "SPECIES_LOTAD", "VAR_LOTAD_SIZE_RECORD")
    recordInfo(ctx, adapters, species, var)
    return false
  end,
  -- pokeemerald/src/pokemon_size_record.c:183
  CompareLotadSize = function(ctx, adapters)
    local species, var = ids(ctx, "SPECIES_LOTAD", "VAR_LOTAD_SIZE_RECORD")
    return compare(ctx, adapters, species, var)
  end,
}

Std.legacyHandlers(Natives)
return Natives
