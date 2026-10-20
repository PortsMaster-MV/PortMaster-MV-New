local Structs = require("src.save_convert.gen3_port.structs")

local function u8(s, o) return s:byte(o + 1) end
local function u16(s, o) local a, b = s:byte(o + 1, o + 2); return a + b * 256 end
local function num(v) return math.floor(tonumber(v) or 0) end

local UNION_SIZE = 0x40
-- pokeemerald/include/global.h:513
local SB2_TRAINER_ID = 0x0A

local function slice(w, off, n)
  local t = {}
  for i = 0, n - 1 do t[i + 1] = string.char(w.b[off + i] or 0) end
  return table.concat(t)
end

local function blank(s, off, n)
  for i = 0, n - 1 do if u8(s, off + i) ~= 0 then return false end end
  return true
end

local function readText(codec, s, off, len)
  if blank(s, off, len) then return "" end
  return codec.decodeString(s, off, len)
end

local function writeText(x, w, off, len, str, memset)
  str = type(str) == "string" and str or ""
  if readText(x.codec, slice(w, off, len), 0, len) == str then return end
  if str == "" then
    w:w8(off, 0xFF)
    return
  end
  local enc = x.codec.encodeString(str, len, memset and 0xFF or 0)
  local n = len
  if not memset then n = enc:find("\255", 1, true) or len end
  w:bytes(off, enc:sub(1, n))
end

local function readOwner(s, off, stride)
  local get = stride == 2 and u16 or u8
  return get(s, off) % 256 + (get(s, off + stride) % 256) * 256
end

local function writeOwner(x, w, off, stride, tid)
  tid = num(tid) % 65536
  if readOwner(slice(w, off, stride * 4), 0, stride) == tid then return end
  local put = stride == 2 and function(o, v) w:w16(o, v) end or function(o, v) w:w8(o, v) end
  put(off, tid % 256)
  put(off + stride, math.floor(tid / 256))
  if tid == u16(x.sb2, SB2_TRAINER_ID) then
    put(off + stride * 2, u8(x.sb2, SB2_TRAINER_ID + 2))
    put(off + stride * 3, u8(x.sb2, SB2_TRAINER_ID + 3))
  end
end

local function prepare(w, base, id, setup)
  local s = slice(w, base, UNION_SIZE)
  if u8(s, 0) ~= id or blank(s, 0, UNION_SIZE) then
    w:fill(base, UNION_SIZE, 0)
    if setup then setup(w, base) end
  end
  w:w8(base, id)
end

local function readVariant(x, s, base, def)
  local out = Structs.read(s, base, def.spec, x.codec)
  for _, t in ipairs(def.text or {}) do
    if t.n then
      out[t.name] = {}
      for i = 1, t.n do out[t.name][i] = readText(x.codec, s, base + t.off + (i - 1) * t.len, t.len) end
    else
      out[t.name] = readText(x.codec, s, base + t.off, t.len)
    end
  end
  if def.owner then out[def.owner.name] = readOwner(s, base + def.owner.off, def.owner.stride) end
  return out
end

local function writeVariant(x, w, base, def, v)
  v = type(v) == "table" and v or {}
  Structs.write(w, base, def.spec, v, x.codec)
  for _, t in ipairs(def.text or {}) do
    if t.n then
      local list = type(v[t.name]) == "table" and v[t.name] or {}
      for i = 1, t.n do writeText(x, w, base + t.off + (i - 1) * t.len, t.len, list[i], t.memset) end
    else
      writeText(x, w, base + t.off, t.len, v[t.name], t.memset)
    end
  end
  if def.owner then writeOwner(x, w, base + def.owner.off, def.owner.stride, v[def.owner.name]) end
end

-- pokeemerald/include/global.h:651
local OLD_MAN = {
  -- pokeemerald/include/global.h:656
  [0] = {
    spec = {
      { name = "songLyrics", off = 0x02, t = "u16", n = 6 },
      { name = "newSongLyrics", off = 0x0E, t = "u16", n = 6 },
      { name = "hasChangedSong", off = 0x29, t = "bool8" },
      { name = "language", off = 0x2A, t = "u8" },
    },
    -- pokeemerald/src/mauville_old_man.c:161
    text = { { name = "playerName", off = 0x1A, len = 8 } },
    owner = { name = "playerTrainerId", off = 0x25, stride = 1 },
  },
  -- pokeemerald/include/global.h:693
  [1] = {
    spec = {
      { name = "taughtWord", off = 0x01, t = "bool8" },
      { name = "language", off = 0x02, t = "u8" },
    },
  },
  -- pokeemerald/include/global.h:700
  [2] = {
    spec = {
      { name = "decorations", off = 0x01, t = "u8", n = 4 },
      { name = "alreadyTraded", off = 0x31, t = "bool8" },
      { name = "language", off = 0x32, t = "u8", n = 4 },
    },
    -- pokeemerald/src/trader.c:205
    text = { { name = "playerNames", off = 0x05, len = 11, n = 4 } },
  },
  -- pokeemerald/include/global.h:670
  [3] = {
    spec = {
      { name = "alreadyRecorded", off = 0x01, t = "bool8" },
      { name = "gameStatIDs", off = 0x04, t = "u8", n = 4 },
      { name = "statValues", off = 0x24, t = "u32", n = 4 },
      { name = "language", off = 0x34, t = "u8", n = 4 },
    },
    -- pokeemerald/src/mauville_old_man.c:1302
    text = { { name = "trainerNames", off = 0x08, len = 7, n = 4, memset = true } },
    -- pokeemerald/src/mauville_old_man.c:1211
    setup = function(w, base) w:fill(base + 0x08, 4, 0xFF) end,
  },
  -- pokeemerald/include/global.h:681
  [4] = {
    spec = {
      { name = "taleCounter", off = 0x01, t = "u8" },
      { name = "questionNum", off = 0x02, t = "u8" },
      { name = "randomWords", off = 0x04, t = "u16", n = 10 },
      { name = "questionList", off = 0x18, t = "u8", n = 8 },
      { name = "language", off = 0x20, t = "u8" },
    },
  },
}

local LADY = {
  -- pokeemerald/include/global.h:797
  [0] = {
    key = "quiz",
    spec = {
      { name = "state", off = 0x01, t = "u8" },
      { name = "question", off = 0x02, t = "u16", n = 9 },
      { name = "correctAnswer", off = 0x14, t = "u16" },
      { name = "playerAnswer", off = 0x16, t = "u16" },
      { name = "prize", off = 0x28, t = "u16" },
      { name = "waitingForChallenger", off = 0x2A, t = "bool8" },
      { name = "questionId", off = 0x2B, t = "u8" },
      { name = "prevQuestionId", off = 0x2C, t = "u8" },
      { name = "language", off = 0x2D, t = "u8" },
    },
    -- pokeemerald/src/lilycove_lady.c:547
    text = { { name = "playerName", off = 0x18, len = 8 } },
    owner = { name = "playerTrainerId", off = 0x20, stride = 2 },
    -- pokeemerald/src/lilycove_lady.c:311
    setup = function(w, base) w:w8(base + 0x18, 0xFF) end,
  },
  -- pokeemerald/include/global.h:813
  [1] = {
    key = "favor",
    spec = {
      { name = "state", off = 0x01, t = "u8" },
      { name = "likedItem", off = 0x02, t = "bool8" },
      { name = "numItemsGiven", off = 0x03, t = "u8" },
      { name = "favorId", off = 0x0C, t = "u8" },
      { name = "itemId", off = 0x0E, t = "u16" },
      { name = "bestItem", off = 0x10, t = "u16" },
      { name = "language", off = 0x12, t = "u8" },
    },
    -- pokeemerald/src/lilycove_lady.c:204
    text = { { name = "playerName", off = 0x04, len = 8, memset = true } },
    -- pokeemerald/src/lilycove_lady.c:144
    setup = function(w, base) w:w8(base + 0x04, 0xFF) end,
  },
  -- pokeemerald/include/global.h:828
  [2] = {
    key = "contest",
    spec = {
      { name = "givenPokeblock", off = 0x01, t = "bool8" },
      { name = "numGoodPokeblocksGiven", off = 0x02, t = "u8" },
      { name = "numOtherPokeblocksGiven", off = 0x03, t = "u8" },
      { name = "maxSheen", off = 0x0C, t = "u8" },
      { name = "category", off = 0x0D, t = "u8" },
      { name = "language", off = 0x0E, t = "u8" },
    },
    -- pokeemerald/src/lilycove_lady.c:627
    text = { { name = "playerName", off = 0x04, len = 8, memset = true } },
    -- pokeemerald/src/lilycove_lady.c:600
    setup = function(w, base) w:w8(base + 0x04, 0xFF) end,
  },
}

-- pokeemerald/include/global.h:865
local HILL = {
  { name = "timer", off = 0x0, t = "u32" },
  { name = "bestTime", off = 0x4, t = "u32" },
  { name = "unk_3D6C", off = 0x8, t = "u8" },
  { name = "receivedPrize", off = 0xA, t = "bits", of = "u16", shift = 0, width = 1 },
  { name = "checkedFinalTime", off = 0xA, t = "bits", of = "u16", shift = 1, width = 1 },
  { name = "spokeToOwner", off = 0xA, t = "bits", of = "u16", shift = 2, width = 1 },
  { name = "hasLost", off = 0xA, t = "bits", of = "u16", shift = 3, width = 1 },
  { name = "maybeECardScanDuringChallenge", off = 0xA, t = "bits", of = "u16", shift = 4, width = 1 },
  { name = "field_3D6E_0f", off = 0xA, t = "bits", of = "u16", shift = 5, width = 1 },
  { name = "mode", off = 0xA, t = "bits", of = "u16", shift = 6, width = 2 },
}
-- pokeemerald/include/global.h:1068
local HILL_TIMES = { { name = "times", off = 0, t = "u32", n = 4 } }

-- pokeemerald/include/global.h:250
local CRUSH = { { name = "speeds", off = 0, t = "u16", n = 4 } }
-- pokeemerald/include/global.h:219
local JUMP = {
  { name = "jumpsInRow", off = 0x0, t = "u16" },
  { name = "excellentsInRow", off = 0x4, t = "u16" },
  { name = "gamesWithMaxPlayers", off = 0x6, t = "u16" },
  { name = "bestJumpScore", off = 0xC, t = "u32" },
}
-- pokeemerald/include/global.h:229
local PICK = {
  { name = "bestScore", off = 0x0, t = "u32" },
  { name = "berriesPicked", off = 0x4, t = "u16" },
  { name = "berriesPickedInRow", off = 0x6, t = "u16" },
}

local MINIGAME = {
  emerald = function(L) return L.RSE.sb2.berryCrush, L.RSE.sb2.pokeJump, L.RSE.sb2.berryPick end,
  -- pokefirered/include/global.h:354
  frlg = function() return 0xAF0, 0xB00, 0xB10 end,
}

local function numbers(t)
  local out = {}
  for k, v in pairs(type(t) == "table" and t or {}) do
    if v == true then out[k] = 1 elseif v == false then out[k] = 0 else out[k] = v end
  end
  return out
end

return function(Rse)
  Rse.defineSection({
    name = "oldMan",
    fields = { "oldMan" },
    read = function(x)
      local base = x.L.RSE.sb1.oldMan
      local id = u8(x.sb1, base)
      local def = OLD_MAN[id]
      local out = def and readVariant(x, x.sb1, base, def) or {}
      out.id = id
      return { oldMan = out }
    end,
    write = function(x, v)
      local m = v.oldMan
      if type(m) ~= "table" or tonumber(m.id) == nil then return end
      local base, id = x.L.RSE.sb1.oldMan, num(m.id) % 256
      local def = OLD_MAN[id]
      prepare(x.w1, base, id, def and def.setup)
      if def then writeVariant(x, x.w1, base, def, m) end
    end,
  })

  Rse.defineSection({
    name = "lilycoveLady",
    fields = { "lilycoveLady" },
    read = function(x)
      local base = x.L.RSE.sb1.lilycoveLady
      local id = u8(x.sb1, base)
      local def = LADY[id]
      local out = { id = id }
      if def then
        out[def.key] = readVariant(x, x.sb1, base, def)
        out[def.key].id = id
      end
      return { lilycoveLady = out }
    end,
    write = function(x, v)
      local l = v.lilycoveLady
      if type(l) ~= "table" or tonumber(l.id) == nil then return end
      local base, id = x.L.RSE.sb1.lilycoveLady, num(l.id) % 256
      local def = LADY[id]
      prepare(x.w1, base, id, def and def.setup)
      if def then writeVariant(x, x.w1, base, def, l[def.key]) end
    end,
  })

  Rse.defineSection({
    name = "trainerHill",
    fields = { "trainerHill", "trainerHillTimes" },
    read = function(x)
      local o = x.L.RSE.sb1
      return { trainerHill = Structs.read(x.sb1, o.trainerHill, HILL, x.codec),
        trainerHillTimes = Structs.read(x.sb1, o.trainerHillTimes, HILL_TIMES, x.codec).times }
    end,
    write = function(x, v)
      local o = x.L.RSE.sb1
      if type(v.trainerHill) == "table" then Structs.write(x.w1, o.trainerHill, HILL, numbers(v.trainerHill), x.codec) end
      if type(v.trainerHillTimes) == "table" then
        Structs.write(x.w1, o.trainerHillTimes, HILL_TIMES, { times = v.trainerHillTimes }, x.codec)
      end
    end,
  })

  Rse.defineSection({
    name = "minigameRecords",
    fields = { "berryCrushPressingSpeeds", "pokemonJumpRecords", "dodrioBerryPickingRecords" },
    read = function(x)
      local crush, jump, pick = MINIGAME[x.L.FAMILY](x.L)
      return {
        berryCrushPressingSpeeds = Structs.read(x.sb2, crush, CRUSH, x.codec).speeds,
        pokemonJumpRecords = Structs.read(x.sb2, jump, JUMP, x.codec),
        dodrioBerryPickingRecords = Structs.read(x.sb2, pick, PICK, x.codec),
      }
    end,
    write = function(x, v)
      local crush, jump, pick = MINIGAME[x.L.FAMILY](x.L)
      if type(v.berryCrushPressingSpeeds) == "table" then
        Structs.write(x.w2, crush, CRUSH, { speeds = v.berryCrushPressingSpeeds }, x.codec)
      end
      if type(v.pokemonJumpRecords) == "table" then Structs.write(x.w2, jump, JUMP, v.pokemonJumpRecords, x.codec) end
      if type(v.dodrioBerryPickingRecords) == "table" then
        Structs.write(x.w2, pick, PICK, v.dodrioBerryPickingRecords, x.codec)
      end
    end,
  }, { emerald = true, frlg = true })
end
