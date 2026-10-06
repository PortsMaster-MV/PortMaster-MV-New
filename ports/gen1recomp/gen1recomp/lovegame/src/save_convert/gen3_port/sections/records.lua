local Structs = require("src.save_convert.gen3_port.structs")

local U32 = 4294967296

local R = {}

local function u8(s, o) return s:byte(o + 1) end
local function u16(s, o) local a, b = s:byte(o + 1, o + 2); return a + b * 256 end
local function u32(s, o) local a, b, c, d = s:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + d * 16777216 end
local function num(v, d) return tonumber(v) or d or 0 end

local function slice(w, off, n)
  local t = {}
  for i = 0, n - 1 do t[i + 1] = string.char((w.b[off + i] or 0) % 256) end
  return table.concat(t)
end

local function zero(s)
  return not s:find("[^%z]")
end

function R.wordSum(s, off, words)
  local sum = 0
  for i = 0, words - 1 do sum = (sum + u32(s, off + i * 4)) % U32 end
  return sum
end

local function bits(name, off, shift, width, of, bool)
  return { name = name, off = off, t = "bits", of = of or "u8", shift = shift, width = width, bool = bool }
end

-- pokeemerald/include/global.h:282
R.MON = {
  { name = "species", off = 0, t = "u16" }, { name = "heldItem", off = 2, t = "u16" },
  { name = "moves", off = 4, t = "u16", n = 4 }, { name = "level", off = 12, t = "u8" },
  { name = "ppBonuses", off = 13, t = "u8" }, { name = "hpEV", off = 14, t = "u8" },
  { name = "attackEV", off = 15, t = "u8" }, { name = "defenseEV", off = 16, t = "u8" },
  { name = "speedEV", off = 17, t = "u8" }, { name = "spAttackEV", off = 18, t = "u8" },
  { name = "spDefenseEV", off = 19, t = "u8" }, { name = "otId", off = 20, t = "u32" },
  bits("hpIV", 24, 0, 5, "u32"), bits("attackIV", 24, 5, 5, "u32"), bits("defenseIV", 24, 10, 5, "u32"),
  bits("speedIV", 24, 15, 5, "u32"), bits("spAttackIV", 24, 20, 5, "u32"), bits("spDefenseIV", 24, 25, 5, "u32"),
  bits("abilityNum", 24, 31, 1, "u32"),
  { name = "personality", off = 28, t = "u32" }, { name = "nickname", off = 32, t = "text", len = 11 },
  { name = "friendship", off = 43, t = "u8" },
}
R.MON_SIZE = 44

-- pokeemerald/include/global.h:309
R.TOWER = {
  { name = "lvlMode", off = 0, t = "u8" }, { name = "facilityClass", off = 1, t = "u8" },
  { name = "winStreak", off = 2, t = "u16" }, { name = "name", off = 4, t = "text", len = 8 },
  { name = "trainerId", off = 12, t = "u8", n = 4 }, { name = "greeting", off = 16, t = "u16", n = 6 },
  { name = "speechWon", off = 28, t = "u16", n = 6 }, { name = "speechLost", off = 40, t = "u16", n = 6 },
  { name = "language", off = 228, t = "u8" },
}
R.TOWER_PARTY, R.TOWER_MONS, R.TOWER_SIZE = 52, 4, 236

-- pokeemerald/include/global.h:334
R.EREADER = {
  { name = "unk0", off = 0, t = "u8" }, { name = "facilityClass", off = 1, t = "u8" },
  { name = "winStreak", off = 2, t = "u16" }, { name = "name", off = 4, t = "text", len = 8 },
  { name = "trainerId", off = 12, t = "u8", n = 4 }, { name = "greeting", off = 16, t = "u16", n = 6 },
  { name = "farewellPlayerLost", off = 28, t = "u16", n = 6 }, { name = "farewellPlayerWon", off = 40, t = "u16", n = 6 },
}
R.EREADER_PARTY, R.EREADER_MONS, R.EREADER_SIZE = 52, 3, 188

-- pokeemerald/include/global.h:325
R.INTERVIEW = {
  { name = "playerSpecies", off = 0, t = "u16" }, { name = "opponentSpecies", off = 2, t = "u16" },
  { name = "opponentName", off = 4, t = "text", len = 8, zeroEmpty = true },
  { name = "opponentMonNickname", off = 12, t = "text", len = 11, zeroEmpty = true },
  { name = "opponentLanguage", off = 23, t = "u8" },
}

-- pokeemerald/include/global.h:357
R.RENTAL = {
  { name = "monId", off = 0, t = "u16" }, { name = "personality", off = 4, t = "u32" },
  { name = "ivs", off = 8, t = "u8" }, { name = "abilityNum", off = 9, t = "u8" },
}

-- pokeemerald/include/global.h:349
R.DOME_MON = {
  { name = "moves", off = 0, t = "u16", n = 4 }, { name = "evs", off = 8, t = "u8", n = 6 },
  { name = "nature", off = 14, t = "u8" },
}

-- pokeemerald/include/global.h:244
R.PYRAMID_BAG = {
  { name = "itemId", off = 0, t = "u16", n = 2, m = 10 }, { name = "quantity", off = 40, t = "u8", n = 2, m = 10 },
}

-- pokeemerald/include/global.h:378
R.FRONTIER = {
  { key = "towerPlayer", off = 0, kind = "tower" },
  { key = "towerRecords", off = 236, kind = "towerList", count = 5 },
  { key = "towerInterview", off = 1416, zeroEmpty = true, spec = { { name = "towerInterview", off = 0, t = "struct", size = 24, spec = R.INTERVIEW } } },
  { key = "ereaderTrainer", off = 1440, kind = "ereader" },
  { key = "domeFlags", off = 1724, spec = {
    bits("domeAttemptedSingles50", 0, 0, 1), bits("domeAttemptedSinglesOpen", 0, 1, 1),
    bits("domeHasWonSingles50", 0, 2, 1), bits("domeHasWonSinglesOpen", 0, 3, 1),
    bits("domeAttemptedDoubles50", 0, 4, 1), bits("domeAttemptedDoublesOpen", 0, 5, 1),
    bits("domeHasWonDoubles50", 0, 6, 1), bits("domeHasWonDoublesOpen", 0, 7, 1),
  } },
  { key = "domeLvlMode", off = 1726, spec = { { name = "domeLvlMode", off = 0, t = "u8" } } },
  { key = "domeBattleMode", off = 1727, spec = { { name = "domeBattleMode", off = 0, t = "u8" } } },
  { key = "domeTrainers", off = 1752, kind = "domeTrainers", count = 16 },
  { key = "domeMonIds", off = 1816, spec = { { name = "domeMonIds", off = 0, t = "u16", n = 16, m = 3 } } },
  { key = "pikeFlags", off = 1988, spec = {
    bits("pikeHintedRoomIndex", 0, 0, 3), bits("pikeHintedRoomType", 0, 3, 4), bits("pikeHealingRoomsDisabled", 0, 7, 1),
  } },
  { key = "pikeHeldItemsBackup", off = 1990, spec = { { name = "pikeHeldItemsBackup", off = 0, t = "u16", n = 3 } } },
  { key = "pyramidRandoms", off = 2006, spec = { { name = "pyramidRandoms", off = 0, t = "u16", n = 4 } } },
  { key = "pyramidTrainerFlags", off = 2014, spec = { { name = "pyramidTrainerFlags", off = 0, t = "u8" } } },
  { key = "pyramidBag", off = 2016, spec = { { name = "pyramidBag", off = 0, t = "struct", size = 60, spec = R.PYRAMID_BAG } } },
  { key = "pyramidLightRadius", off = 2076, spec = { { name = "pyramidLightRadius", off = 0, t = "u8" } } },
  { key = "rentalMons", off = 2084, spec = { { name = "rentalMons", off = 0, t = "struct", n = 6, size = 12, spec = R.RENTAL } } },
  { key = "domeWinningMoves", off = 2164, spec = { { name = "domeWinningMoves", off = 0, t = "u16", n = 16 } } },
  { key = "trainerFlags", off = 2196, spec = { { name = "trainerFlags", off = 0, t = "u8" } } },
  { key = "opponentNames", off = 2197, spec = { { name = "opponentNames", off = 0, t = "text", n = 2, len = 8 } } },
  { key = "opponentTrainerIds", off = 2213, spec = { { name = "opponentTrainerIds", off = 0, t = "u8", n = 2, m = 4 } } },
  { key = "unk_EF9", off = 2221, spec = { bits("unk_EF9", 0, 0, 7) } },
  { key = "domePlayerPartyData", off = 2224,
    spec = { { name = "domePlayerPartyData", off = 0, t = "struct", n = 3, size = 16, spec = R.DOME_MON } } },
}

-- pokeemerald/include/global.h:367
R.DOME_TRAINER = { bits("trainerId", 0, 0, 10, "u16"), bits("isEliminated", 0, 10, 1, "u16", true),
  bits("eliminatedAt", 0, 11, 2, "u16") }

-- pokeemerald/include/global.h:533
R.PLAYER_APPRENTICE = 0xB0
-- pokeemerald/include/global.h:463
R.QUESTION = {
  bits("questionId", 0, 0, 2), bits("monId", 0, 2, 2), bits("moveSlot", 0, 4, 2), bits("suggestedChange", 0, 6, 2),
  { name = "data", off = 2, t = "u16" },
}
-- pokeemerald/include/global.h:473
R.PLAYERS_APPRENTICE = {
  { name = "id", off = 0, t = "u8" }, bits("lvlMode", 1, 0, 2), bits("questionsAnswered", 1, 2, 4),
  bits("leadMonId", 1, 6, 2), bits("party", 2, 0, 3), bits("saveId", 2, 3, 2),
  { name = "speciesIds", off = 4, t = "u8", n = 3 },
  { name = "questions", off = 8, t = "struct", n = 9, size = 4, spec = R.QUESTION },
}

-- pokeemerald/include/global.h:534
R.APPRENTICES, R.APPRENTICE_COUNT, R.APPRENTICE_SIZE = 0xDC, 4, 68
-- pokeemerald/include/global.h:257
R.APPRENTICE_MON = {
  { name = "species", off = 0, t = "u16" }, { name = "moves", off = 2, t = "u16", n = 4 }, { name = "item", off = 10, t = "u16" },
}
-- pokeemerald/include/global.h:266
R.APPRENTICE = {
  bits("id", 0, 0, 5), bits("lvlMode", 0, 5, 2), { name = "numQuestions", off = 1, t = "u8" },
  { name = "number", off = 2, t = "u8" },
  { name = "party", off = 4, t = "struct", n = 3, size = 12, spec = R.APPRENTICE_MON },
  { name = "speechWon", off = 40, t = "u16", n = 6 }, { name = "playerId", off = 52, t = "u8", n = 4 },
  { name = "playerName", off = 56, t = "text", len = 7 }, { name = "language", off = 63, t = "u8" },
}

-- pokeemerald/include/global.h:538
R.HALL_1P, R.HALL_1P_SIZE, R.HALL_FACILITIES, R.LVL_MODES, R.HALL_RECORDS = 0x21C, 16, 9, 2, 3
-- pokeemerald/include/global.h:488
R.RANKING_1P = {
  { name = "id", off = 0, t = "u8", n = 4 }, { name = "winStreak", off = 4, t = "u16" },
  { name = "name", off = 6, t = "text", len = 8 }, { name = "language", off = 14, t = "u8" },
}
-- pokeemerald/include/global.h:539
R.HALL_2P, R.HALL_2P_SIZE = 0x57C, 28
-- pokeemerald/include/global.h:497
R.RANKING_2P = {
  { name = "id1", off = 0, t = "u8", n = 4 }, { name = "id2", off = 4, t = "u8", n = 4 },
  { name = "winStreak", off = 8, t = "u16" }, { name = "name1", off = 10, t = "text", len = 8 },
  { name = "name2", off = 18, t = "text", len = 8 }, { name = "language", off = 26, t = "u8" },
}

-- pokeemerald/include/global.h:752
R.WINNER_SIZE, R.MON_NAME, R.MON_NAME_LEN, R.TRAINER_NAME, R.TRAINER_NAME_LEN = 32, 11, 11, 22, 8

local wrapped = setmetatable({}, { __mode = "k" })
local function textCodec(codec)
  local c = wrapped[codec]
  if not c then
    c = setmetatable({
      -- pokeemerald/src/new_game.c:121
      decodeString = function(s, off, len)
        if zero(s:sub(off + 1, off + len)) then return "" end
        return codec.decodeString(s, off, len)
      end,
    }, { __index = codec })
    wrapped[codec] = c
  end
  return c
end

-- pokeemerald/src/string_util.c:75
local function putText(x, w, off, len, v, zeroEmpty)
  v = type(v) == "string" and v or (v == nil and "" or tostring(v))
  local dec = zeroEmpty and textCodec(x.codec) or x.codec
  if dec.decodeString(slice(w, off, len), 0, len) == v then return end
  local enc = x.codec.encodeString(v, len, 0)
  for i = 1, len do
    local c = enc:byte(i)
    w:w8(off + i - 1, c)
    if c == 0xFF then return end
  end
end
R.putText = putText

local function putSpec(x, w, base, spec, t)
  t = type(t) == "table" and t or {}
  for _, f in ipairs(spec) do
    if f.name then
      local v = t[f.name]
      if f.t == "text" then
        if f.n then
          for i = 1, f.n do putText(x, w, base + f.off + (i - 1) * f.len, f.len, type(v) == "table" and v[i] or nil) end
        else
          putText(x, w, base + f.off, f.len, v, f.zeroEmpty)
        end
      elseif f.t == "struct" then
        if f.n then
          for i = 1, f.n do putSpec(x, w, base + f.off + (i - 1) * f.size, f.spec, type(v) == "table" and v[i] or nil) end
        else
          putSpec(x, w, base + f.off, f.spec, v)
        end
      else
        Structs.write(w, base, { f }, t, x.codec)
      end
    end
  end
end

local function readParty(s, off, count, codec)
  local party = {}
  for i = 1, count do
    local o = off + (i - 1) * R.MON_SIZE
    if not zero(s:sub(o + 1, o + R.MON_SIZE)) then party[i] = Structs.read(s, o, R.MON, codec) end
  end
  return party
end

local function putParty(x, w, off, count, party)
  party = type(party) == "table" and party or {}
  for i = 1, count do
    local o, mon = off + (i - 1) * R.MON_SIZE, party[i]
    if type(mon) == "table" then putSpec(x, w, o, R.MON, mon) else w:fill(o, R.MON_SIZE, 0) end
  end
end

local function readSummed(s, off, spec, size, partyOff, mons, codec)
  local words = (size - 4) / 4
  if zero(s:sub(off + 1, off + size - 4)) then return {} end
  local out = Structs.read(s, off, spec, codec)
  out.party = readParty(s, off + partyOff, mons, codec)
  if u32(s, off + size - 4) ~= R.wordSum(s, off, words) then out.checksumValid = false end
  return out
end
R.readSummed = readSummed

local function settleChecksum(w, off, size, valid)
  local body = slice(w, off, size - 4)
  local sum = R.wordSum(body, 0, (size - 4) / 4)
  local stored = u32(slice(w, off + size - 4, 4), 0)
  if valid and stored ~= sum then w:w32(off + size - 4, sum)
  elseif not valid and stored == sum then w:w32(off + size - 4, (sum + 1) % U32) end
end

-- pokeemerald/src/battle_tower.c:2715
local function putSummed(x, w, off, spec, size, partyOff, mons, rec)
  if type(rec) ~= "table" or next(rec) == nil then
    if not zero(slice(w, off, size - 4)) then w:fill(off, size, 0) end
    return
  end
  if x.L.FAMILY == "emerald" and size == R.TOWER_SIZE and rec._recordMixNativeBytes then
    local cross = require("src.core.game3.link.rs_record_cross_bytes")
    if cross.raw(rec._recordMixNativeBytes, size) then
      w:bytes(off, cross.renderTower(x.codec, rec))
      return
    end
  end
  putSpec(x, w, off, spec, rec)
  putParty(x, w, off + partyOff, mons, rec.party)
  if zero(slice(w, off, size - 4)) then
    w:w32(off + size - 4, 0)
  else
    settleChecksum(w, off, size, rec.checksumValid ~= false)
  end
end

local function readDomeTrainers(s, off)
  local list = {}
  for i = 1, 16 do
    local o = off + (i - 1) * 2
    local t = Structs.read(s, o, R.DOME_TRAINER)
    t.forfeited = math.floor(u16(s, o) / 8192) ~= 0
    list[i] = t
  end
  return list
end

local function putDomeTrainers(w, off, list)
  list = type(list) == "table" and list or {}
  for i = 1, 16 do
    local o, t = off + (i - 1) * 2, type(list[i]) == "table" and list[i] or {}
    Structs.write(w, o, R.DOME_TRAINER, t)
    local word = (w.b[o] or 0) + (w.b[o + 1] or 0) * 256
    local cur = math.floor(word / 8192)
    local want = (t.forfeited == true or (type(t.forfeited) == "number" and t.forfeited ~= 0))
    if want ~= (cur ~= 0) then w:w16(o, word % 8192 + (want and 8192 or 0)) end
  end
end

function R.readFrontier(x)
  local s, base, out = x.sb2, x.L.RSE.sb2.frontier, {}
  for _, row in ipairs(R.FRONTIER) do
    local o = base + row.off
    if row.kind == "tower" then
      out[row.key] = readSummed(s, o, R.TOWER, R.TOWER_SIZE, R.TOWER_PARTY, R.TOWER_MONS, x.codec)
    elseif row.kind == "towerList" then
      local list = {}
      for i = 1, row.count do
        list[i] = readSummed(s, o + (i - 1) * R.TOWER_SIZE, R.TOWER, R.TOWER_SIZE, R.TOWER_PARTY, R.TOWER_MONS, x.codec)
      end
      out[row.key] = list
    elseif row.kind == "ereader" then
      out[row.key] = readSummed(s, o, R.EREADER, R.EREADER_SIZE, R.EREADER_PARTY, R.EREADER_MONS, x.codec)
    elseif row.kind == "domeTrainers" then
      out[row.key] = readDomeTrainers(s, o)
    else
      for k, v in pairs(Structs.read(s, o, row.spec, row.zeroEmpty and textCodec(x.codec) or x.codec)) do out[k] = v end
    end
  end
  return out
end

function R.writeFrontier(x, f)
  local w, base = x.w2, x.L.RSE.sb2.frontier
  for _, row in ipairs(R.FRONTIER) do
    local o = base + row.off
    if row.kind == "tower" then
      if f[row.key] ~= nil then putSummed(x, w, o, R.TOWER, R.TOWER_SIZE, R.TOWER_PARTY, R.TOWER_MONS, f[row.key]) end
    elseif row.kind == "towerList" then
      local list = f[row.key]
      if type(list) == "table" then
        for i = 1, row.count do
          putSummed(x, w, o + (i - 1) * R.TOWER_SIZE, R.TOWER, R.TOWER_SIZE, R.TOWER_PARTY, R.TOWER_MONS, list[i])
        end
      end
    elseif row.kind == "ereader" then
      if f[row.key] ~= nil then putSummed(x, w, o, R.EREADER, R.EREADER_SIZE, R.EREADER_PARTY, R.EREADER_MONS, f[row.key]) end
    elseif row.kind == "domeTrainers" then
      if f[row.key] ~= nil then putDomeTrainers(w, o, f[row.key]) end
    else
      for _, field in ipairs(row.spec) do
        if f[field.name] ~= nil then putSpec(x, w, o, { field }, f) end
      end
    end
  end
end

function R.readApprentices(x)
  local s, list = x.sb2, {}
  for i = 1, R.APPRENTICE_COUNT do
    local o = R.APPRENTICES + (i - 1) * R.APPRENTICE_SIZE
    local a = Structs.read(s, o, R.APPRENTICE, x.codec)
    if (a.playerName ~= "" or a.lvlMode ~= 0) and u32(s, o + 64) ~= R.wordSum(s, o, 16) then a.checksumValid = false end
    list[i] = a
  end
  return list
end

-- pokeemerald/src/battle_tower.c:3173
function R.writeApprentices(x, list)
  local w = x.w2
  list = type(list) == "table" and list or {}
  for i = 1, R.APPRENTICE_COUNT do
    local o, a = R.APPRENTICES + (i - 1) * R.APPRENTICE_SIZE, list[i]
    if type(a) == "table" then
      local before = slice(w, o, 64)
      putSpec(x, w, o, R.APPRENTICE, a)
      if tostring(a.playerName or "") ~= "" or num(a.lvlMode) ~= 0 then
        settleChecksum(w, o, R.APPRENTICE_SIZE, a.checksumValid ~= false)
      elseif slice(w, o, 64) ~= before then
        -- pokeemerald/src/apprentice.c:168
        w:w32(o + 64, 0)
      end
    end
  end
end

function R.readHall(x)
  local s, one, two = x.sb2, {}, {}
  for i = 1, R.HALL_FACILITIES do
    one[i] = {}
    for j = 1, R.LVL_MODES do
      one[i][j] = {}
      for k = 1, R.HALL_RECORDS do
        local o = R.HALL_1P + (((i - 1) * R.LVL_MODES + (j - 1)) * R.HALL_RECORDS + (k - 1)) * R.HALL_1P_SIZE
        one[i][j][k] = Structs.read(s, o, R.RANKING_1P, x.codec)
      end
    end
  end
  for j = 1, R.LVL_MODES do
    two[j] = {}
    for k = 1, R.HALL_RECORDS do
      two[j][k] = Structs.read(s, R.HALL_2P + ((j - 1) * R.HALL_RECORDS + (k - 1)) * R.HALL_2P_SIZE, R.RANKING_2P, x.codec)
    end
  end
  return one, two
end

local function at(t, ...)
  for _, k in ipairs({ ... }) do
    if type(t) ~= "table" then return nil end
    t = t[k]
  end
  return t
end

function R.writeHall(x, one, two)
  local w = x.w2
  if one ~= nil then
    for i = 1, R.HALL_FACILITIES do
      for j = 1, R.LVL_MODES do
        for k = 1, R.HALL_RECORDS do
          local o = R.HALL_1P + (((i - 1) * R.LVL_MODES + (j - 1)) * R.HALL_RECORDS + (k - 1)) * R.HALL_1P_SIZE
          putSpec(x, w, o, R.RANKING_1P, at(one, i, j, k))
        end
      end
    end
  end
  if two ~= nil then
    for j = 1, R.LVL_MODES do
      for k = 1, R.HALL_RECORDS do
        putSpec(x, w, R.HALL_2P + ((j - 1) * R.HALL_RECORDS + (k - 1)) * R.HALL_2P_SIZE, R.RANKING_2P, at(two, j, k))
      end
    end
  end
end

local function putNameBytes(x, w, off, len, v)
  if type(v) == "table" and #v > 0 then
    for i = 1, len do w:w8(off + i - 1, num(v[i]) % 256) end
  else
    putText(x, w, off, len, type(v) == "string" and v or "")
  end
end

local function bytesAt(s, off, n)
  local out = {}
  for i = 1, n do out[i] = u8(s, off + i - 1) end
  return out
end

return function(Rse)
  Rse.Records = R
  Rse.defineSection({
    name = "frontierRecords",
    fields = { "frontier" },
    read = function(x) return { frontier = R.readFrontier(x) } end,
    write = function(x, v)
      if type(v.frontier) == "table" then R.writeFrontier(x, v.frontier) end
    end,
  })

  Rse.defineSection({
    name = "apprentices",
    fields = { "playerApprentice", "apprentices" },
    read = function(x)
      return { playerApprentice = Structs.read(x.sb2, R.PLAYER_APPRENTICE, R.PLAYERS_APPRENTICE, x.codec),
        apprentices = R.readApprentices(x) }
    end,
    write = function(x, v)
      if type(v.playerApprentice) == "table" then putSpec(x, x.w2, R.PLAYER_APPRENTICE, R.PLAYERS_APPRENTICE, v.playerApprentice) end
      if type(v.apprentices) == "table" then R.writeApprentices(x, v.apprentices) end
    end,
  })

  Rse.defineSection({
    name = "hallRecords",
    fields = { "hallRecords1P", "hallRecords2P" },
    read = function(x)
      local one, two = R.readHall(x)
      return { hallRecords1P = one, hallRecords2P = two }
    end,
    write = function(x, v) R.writeHall(x, v.hallRecords1P, v.hallRecords2P) end,
  })

  Rse.defineSection({
    name = "contestNames",
    fields = { "contestWinners" },
    read = function(x)
      local o, list = x.L.RSE.sb1, {}
      for i = 0, o.contestWinnerCount - 1 do
        local b = o.contestWinners + i * R.WINNER_SIZE
        list[i + 1] = { monName = bytesAt(x.sb1, b + R.MON_NAME, R.MON_NAME_LEN),
          trainerName = bytesAt(x.sb1, b + R.TRAINER_NAME, R.TRAINER_NAME_LEN) }
      end
      return { contestWinners = list }
    end,
    write = function(x, v)
      local o, list = x.L.RSE.sb1, v.contestWinners
      if type(list) ~= "table" then return end
      for i = 0, o.contestWinnerCount - 1 do
        local b, e = o.contestWinners + i * R.WINNER_SIZE, list[i + 1]
        if type(e) == "table" then
          putNameBytes(x, x.w1, b + R.MON_NAME, R.MON_NAME_LEN, e.monName)
          putNameBytes(x, x.w1, b + R.TRAINER_NAME, R.TRAINER_NAME_LEN, e.trainerName)
        end
      end
    end,
  })
end
