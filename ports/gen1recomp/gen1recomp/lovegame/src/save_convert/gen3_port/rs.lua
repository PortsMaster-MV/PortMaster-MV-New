local Rse = require("src.save_convert.gen3_port.rse")
local Structs = require("src.save_convert.gen3_port.structs")
local Records = {}
-- pokeruby/include/pokemon.h:170
Records.MON = {
  { name = "species", off = 0, t = "u16" }, { name = "heldItem", off = 2, t = "u16" },
  { name = "moves", off = 4, t = "u16", n = 4 }, { name = "level", off = 12, t = "u8" },
  { name = "ppBonuses", off = 13, t = "u8" }, { name = "hpEV", off = 14, t = "u8" },
  { name = "attackEV", off = 15, t = "u8" }, { name = "defenseEV", off = 16, t = "u8" },
  { name = "speedEV", off = 17, t = "u8" }, { name = "spAttackEV", off = 18, t = "u8" },
  { name = "spDefenseEV", off = 19, t = "u8" }, { name = "otId", off = 20, t = "u32" },
  { name = "ivWord", off = 24, t = "u32" }, { name = "personality", off = 28, t = "u32" },
  { name = "nickname", off = 32, t = "text", len = 11 }, { name = "friendship", off = 43, t = "u8" },
}
Records.EREADER = {
  { name = "unk0", off = 0, t = "u8" }, { name = "trainerClass", off = 1, t = "u8" },
  { name = "winStreak", off = 2, t = "u16" }, { name = "name", off = 4, t = "text", len = 8 },
  { name = "trainerId", off = 12, t = "u8", n = 4 }, { name = "greeting", off = 16, t = "u16", n = 6 },
  { name = "farewellPlayerLost", off = 28, t = "u16", n = 6 },
  { name = "farewellPlayerWon", off = 40, t = "u16", n = 6 },
}
function Records.wordSum(s, off, n)
  local sum = 0
  for i = 0, n - 1 do
    local a, b, c, d = s:byte(off + i * 4 + 1, off + i * 4 + 4)
    sum = (sum + a + b * 256 + c * 65536 + d * 16777216) % 4294967296
  end
  return sum
end
local Rs = { SECTIONS = {} }

local function u16(s, o) return s:byte(o + 1) + s:byte(o + 2) * 256 end
local function num(v) return tonumber(v) or 0 end
local function add(s)
  Rs.SECTIONS[#Rs.SECTIONS + 1], Rs.SECTIONS[s.name] = s, s
end
local function bytes(s, off, n)
  local out = {}
  for i = 1, n do out[i] = s:byte(off + i) end
  return out
end
local function put(w, off, n, t)
  if type(t) ~= "table" then return end
  for i = 1, n do w:w8(off + i - 1, num(t[i]) % 256) end
end

local function readRecord(s, off, spec, size, codec)
  local r = Structs.read(s, off, spec, codec)
  r.nativeBytes = bytes(s, off, size)
  r.nativeChecksummed = true
  r.checksum = Records.wordSum(s, off + size - 4, 1)
  r.checksumComputed = Records.wordSum(s, off, (size - 4) / 4)
  r.checksumValid = r.checksum == r.checksumComputed
  r.nonzero = false
  for i = 1, size - 4 do if r.nativeBytes[i] ~= 0 then r.nonzero = true; break end end
  return r
end

local function nativeTemplate(r, size)
  local t = r.nativeBytes
  if type(t) ~= "table" or #t ~= size then return nil end
  for i = 1, size do
    if type(t[i]) ~= "number" or t[i] < 0 or t[i] > 255 or t[i] ~= math.floor(t[i]) then return nil end
  end
  return t
end

local function writeChanged(w, off, spec, r, codec)
  local original, changed = Structs.read(w:str(), off, spec, codec), false
  for _, f in ipairs(spec) do
    if f.name and not Rse.same(original[f.name], r[f.name]) then
      if f.t == "struct" then
        if f.n then
          for i = 1, f.n do
            if writeChanged(w, off + f.off + (i - 1) * (f.stride or f.size), f.spec,
                (r[f.name] or {})[i] or {}, codec) then changed = true end
          end
        elseif writeChanged(w, off + f.off, f.spec, r[f.name] or {}, codec) then changed = true end
      else
        Structs.write(w, off, { f }, r, codec)
        changed = true
      end
    end
  end
  return changed
end

local function writeRecord(w, off, r, spec, size, codec)
  if type(r) ~= "table" then return end
  if r.nativeCleared == true then w:fill(off, size, 0); return end
  local template = nativeTemplate(r, size)
  if template then put(w, off, size, template) end
  if writeChanged(w, off, spec, r, codec) then
    w:w32(off + size - 4, Records.wordSum(w:str(), off, (size - 4) / 4))
  end
end

-- pokeruby/include/global.h:668
for _, name in ipairs({ "rtc", "berryTrees", "decorations", "secretBases", "pokeblocks",
    "weather", "matchCall", "tv", "giftRibbons", "berryBlender" }) do
  add(assert(Rse.SECTIONS[name], name))
end
add(require("src.save_convert.gen3_port.sections.rs_link_records").section())
add(require("src.save_convert.gen3_port.sections.rs_tv_shows").section(Rse.same))
add(require("src.save_convert.gen3_port.sections.rs_record_gift").section())

-- pokeruby/include/global.h:233
add({ name = "dewfordTrends", fields = { "dewfordTrends", "unlockedTrendySayings" },
  read = function(x)
    local out = {}
    for i = 1, 5 do
      local off = x.L.RSE.sb1.dewfordTrends + (i - 1) * 8
      local w = u16(x.sb1, off)
      out[i] = { trendiness = w % 128, maxTrendiness = math.floor(w / 128) % 128,
        gainingTrendiness = math.floor(w / 16384) % 2 == 1, rand = u16(x.sb1, off + 2),
        words = { u16(x.sb1, off + 4), u16(x.sb1, off + 6) } }
    end
    return { dewfordTrends = out, unlockedTrendySayings = bytes(x.sb1, 0x2D8C, 4) }
  end,
  write = function(x, v)
    for i = 1, 5 do
      local off = x.L.RSE.sb1.dewfordTrends + (i - 1) * 8
      local t = (v.dewfordTrends or {})[i] or {}
      local w = u16(x.w1:str(), off)
      x.w1:w16(off, num(t.trendiness) % 128 + num(t.maxTrendiness) % 128 * 128
        + (t.gainingTrendiness and 16384 or 0) + math.floor(w / 32768) * 32768)
      x.w1:w16(off + 2, num(t.rand))
      x.w1:w16(off + 4, num((t.words or {})[1]))
      x.w1:w16(off + 6, num((t.words or {})[2]))
    end
    put(x.w1, 0x2D8C, 4, v.unlockedTrendySayings)
  end,
})

-- pokeruby/include/global.h:609
local WINNER = {
  { name = "personality", off = 0, t = "u32" }, { name = "trainerId", off = 4, t = "u32" },
  { name = "species", off = 8, t = "u16" }, { name = "contestCategory", off = 10, t = "u8" },
  { name = "monName", off = 11, t = "u8", n = 11 }, { name = "trainerName", off = 22, t = "u8", n = 8 },
}
add({ name = "contests", fields = { "contestWinners" },
  read = function(x)
    local list = {}
    for i = 1, 13 do
      local off = 0x2DFC + (i - 1) * 32
      list[i] = Structs.read(x.sb1, off, WINNER, x.codec)
      list[i].nativeBytes = bytes(x.sb1, off, 32)
    end
    return { contestWinners = list }
  end,
  write = function(x, v)
    for i = 1, 13 do
      local source = (v.contestWinners or {})[i] or {}
      local winner = {}
      for k, val in pairs(source) do winner[k] = val end
      for key, n in pairs({ monName = 11, trainerName = 8 }) do
        if type(winner[key]) == "string" then winner[key] = bytes(x.codec.encodeString(winner[key], n), 0, n) end
      end
      local off = 0x2DFC + (i - 1) * 32
      local template = nativeTemplate(source, 32)
      if template then put(x.w1, off, 32, template) end
      Structs.write(x.w1, off, WINNER, winner, x.codec)
    end
  end,
})

add(require("src.save_convert.gen3_port.sections.rs_old_man").section(Rse.same))

-- pokeruby/include/global.h:787
local RECORD = {
  { name = "battleTowerLevelType", off = 0, t = "u8" }, { name = "trainerClass", off = 1, t = "u8" },
  { name = "winStreak", off = 2, t = "u16" }, { name = "name", off = 4, t = "text", len = 8 },
  { name = "trainerId", off = 12, t = "u8", n = 4 }, { name = "greeting", off = 16, t = "u16", n = 6 },
  { name = "party", off = 28, t = "struct", spec = Records.MON, size = 44, n = 3 },
}
local EREADER_RECORD = {}
for _, f in ipairs(Records.EREADER) do EREADER_RECORD[#EREADER_RECORD + 1] = f end
EREADER_RECORD[#EREADER_RECORD + 1] = { name = "party", off = 52, t = "struct", spec = Records.MON, size = 44, n = 3 }

function Rs.readTowerRecord(raw, codec, ereader)
  local size, spec = ereader and 188 or 164, ereader and EREADER_RECORD or RECORD
  assert(type(raw) == "string" and #raw == size, "RS Tower record size")
  return readRecord(raw, 0, spec, size, codec)
end
function Rs.renderTowerRecord(codec, template, record, ereader)
  local size, spec = ereader and 188 or 164, ereader and EREADER_RECORD or RECORD
  template = template or string.rep("\0", size)
  assert(type(template) == "string" and #template == size, "RS Tower template size")
  local w = codec.newBuf(size, template)
  writeRecord(w, 0, record, spec, size, codec)
  return w:str()
end
local TOWER = {
  { name = "firstMonSpecies", off = 0x3D8, t = "u16" }, { name = "defeatedBySpecies", off = 0x3DA, t = "u16" },
  { name = "defeatedByTrainerName", off = 0x3DC, t = "text", len = 8 },
  { name = "firstMonNickname", off = 0x3E4, t = "text", len = 10 },
  { name = "battleTowerLevelType", off = 0x4AC, t = "bits", of = "u8", shift = 0, width = 1 },
  { name = "unk_554", off = 0x4AC, t = "bits", of = "u8", shift = 1, width = 1 },
  { name = "battleOutcome", off = 0x4AD, t = "u8" }, { name = "var_4AE", off = 0x4AE, t = "u8", n = 2 },
  { name = "curChallengeBattleNum", off = 0x4B0, t = "u16", n = 2 },
  { name = "curStreakChallengesNum", off = 0x4B4, t = "u16", n = 2 },
  { name = "recordWinStreaks", off = 0x4B8, t = "u16", n = 2 },
  { name = "battleTowerTrainerId", off = 0x4BC, t = "u8" }, { name = "selectedPartyMons", off = 0x4BD, t = "u8", n = 3 },
  { name = "prizeItem", off = 0x4C0, t = "u16" }, { name = "battledTrainerIds", off = 0x4C2, t = "u8", n = 6 },
  { name = "totalBattleTowerWins", off = 0x4C8, t = "u16" }, { name = "bestBattleTowerWinStreak", off = 0x4CA, t = "u16" },
  { name = "currentWinStreaks", off = 0x4CC, t = "u16", n = 2 }, { name = "lastStreakLevelType", off = 0x4D0, t = "u8" },
}
add({ name = "battleTower", fields = { "battleTower" },
  read = function(x)
    local b, list = x.L.RSE.sb2.battleTower, {}
    local t = Structs.read(x.sb2, b, TOWER, x.codec)
    t.playerRecord = readRecord(x.sb2, b, RECORD, 164, x.codec)
    for i = 1, 5 do list[i] = readRecord(x.sb2, b + i * 164, RECORD, 164, x.codec) end
    t.records = list
    t.ereaderTrainer = readRecord(x.sb2, b + 0x3F0, EREADER_RECORD, 188, x.codec)
    return { battleTower = t }
  end,
  write = function(x, v)
    local t = v.battleTower
    if type(t) ~= "table" then return end
    local b = x.L.RSE.sb2.battleTower
    Structs.write(x.w2, b, TOWER, t, x.codec)
    writeRecord(x.w2, b, t.playerRecord, RECORD, 164, x.codec)
    for i = 1, 5 do writeRecord(x.w2, b + i * 164, (t.records or {})[i], RECORD, 164, x.codec) end
    writeRecord(x.w2, b + 0x3F0, t.ereaderTrainer, EREADER_RECORD, 188, x.codec)
  end,
})

-- pokeruby/include/global.h:745
local RAW = { externalEventData = { 0x311B, 20 }, externalEventFlags = { 0x312F, 21 },
  enigmaBerry = { 0x3160, 1328 }, ramScript = { 0x3690, 1004 } }
local rawFields = {}
for k in pairs(RAW) do rawFields[#rawFields + 1] = k .. "NativeBytes" end
add({ name = "nativeBytes", fields = rawFields,
  read = function(x)
    local out = {}
    for k, row in pairs(RAW) do out[k .. "NativeBytes"] = bytes(x.sb1, row[1], row[2]) end
    return out
  end,
  write = function(x, v)
    for k, row in pairs(RAW) do put(x.w1, row[1], row[2], v[k .. "NativeBytes"]) end
  end,
})

function Rs.install(codec)
  Rse.install(codec, Rs.SECTIONS)
  codec.port = Rs
  Rs.finishImport = Rse.finishImport
  return codec
end

return Rs
