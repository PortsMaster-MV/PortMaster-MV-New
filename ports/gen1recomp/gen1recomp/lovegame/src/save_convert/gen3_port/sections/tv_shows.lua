local Structs = require("src.save_convert.gen3_port.structs")

-- pokeemerald/include/global.tv.h:6
local SIZE = 0x24
-- pokeemerald/include/constants/global.h:95
local NICK = 11
-- pokeemerald/include/constants/global.h:97
local NAME = 8

local function u8(name, off) return { name = name, off = off, t = "u8" } end
local function u16(name, off, n) return { name = name, off = off, t = "u16", n = n } end
local function u32(name, off) return { name = name, off = off, t = "u32" } end
local function b8(name, off) return { name = name, off = off, t = "bool8" } end
local function text(name, off, len) return { name = name, off = off, t = "text", len = len, pad = 0 } end
local function bits(name, off, shift, width) return { name = name, off = off, t = "bits", of = "u8", shift = shift, width = width } end

-- pokeemerald/include/global.tv.h:9
local ID_PAIRS = {
  { "srcTrainerId2Lo", 0x1E, "srcTrainerId2Hi", 0x1F },
  { "srcTrainerIdLo", 0x20, "srcTrainerIdHi", 0x21 },
  { "trainerIdLo", 0x22, "trainerIdHi", 0x23 },
}

local function shape(rows)
  local spec = { u8("kind", 0), b8("active", 1) }
  local used = {}
  for _, f in ipairs(rows) do
    spec[#spec + 1] = f
    for o = f.off, f.off + Structs.fieldSize(f) - 1 do used[o] = true end
  end
  for _, p in ipairs(ID_PAIRS) do
    if not used[p[2]] and not used[p[4]] then
      spec[#spec + 1] = u8(p[1], p[2])
      spec[#spec + 1] = u8(p[3], p[4])
    end
  end
  return spec
end

-- pokeemerald/include/global.tv.h:24
local COMMON = shape({ { name = "raw", off = 0x02, t = "u8", n = 28 } })

-- pokeemerald/include/constants/tv.h:24
local KIND = {
  -- pokeemerald/include/global.tv.h:32
  [1] = shape({ u16("species", 0x02), u16("words", 0x04, 6), text("playerName", 0x10, NAME), u8("language", 0x18) }),
  -- pokeemerald/include/global.tv.h:43
  [2] = shape({ u16("species", 0x02), u16("words", 0x04, 6), text("playerName", 0x10, NAME), u8("language", 0x18) }),
  -- pokeemerald/include/global.tv.h:54
  [3] = shape({ u16("species", 0x02), bits("friendshipHighNybble", 0x04, 0, 4), bits("questionAsked", 0x04, 4, 4),
    text("playerName", 0x05, NAME), u8("language", 0x0D), u8("pokemonNameLanguage", 0x0E),
    text("nickname", 0x10, NAME), u16("words", 0x1C, 2) }),
  -- pokeemerald/include/global.tv.h:70
  [4] = shape({ u16("words", 0x02, 2), u16("species", 0x06) }),
  -- pokeemerald/include/global.tv.h:81
  [5] = shape({ u16("species", 0x02), text("pokemonName", 0x04, NICK), text("trainerName", 0x0F, NAME),
    u8("random", 0x1A), u8("random2", 0x1B), u16("randomSpecies", 0x1C), u8("language", 0x1E),
    u8("pokemonNameLanguage", 0x1F) }),
  -- pokeemerald/include/global.tv.h:96
  [6] = shape({ u16("species", 0x02), u16("words", 0x04, 2), text("pokemonNickname", 0x08, NICK),
    bits("contestCategory", 0x13, 0, 3), bits("contestRank", 0x13, 3, 2), bits("contestResult", 0x13, 5, 2),
    u16("move", 0x14), text("playerName", 0x16, NAME), u8("language", 0x1E), u8("pokemonNameLanguage", 0x1F) }),
  -- pokeemerald/include/global.tv.h:113
  [7] = shape({ text("playerName", 0x02, NAME), u16("species", 0x0A), text("opponentName", 0x0C, NAME),
    u16("defeatedSpecies", 0x14), u16("numFights", 0x16), u16("words", 0x18, 1), u8("btLevel", 0x1A),
    u8("interviewResponse", 0x1B), b8("wonTheChallenge", 0x1C), u8("playerLanguage", 0x1D),
    u8("opponentLanguage", 0x1E) }),
  -- pokeemerald/include/global.tv.h:131
  [8] = shape({ u16("losingSpecies", 0x02), text("losingTrainerName", 0x04, NAME), u8("loserAppealFlag", 0x0C),
    u8("round1Placing", 0x0D), u8("round2Placing", 0x0E), u8("winnerAppealFlag", 0x0F), u16("move", 0x10),
    u16("winningSpecies", 0x12), text("winningTrainerName", 0x14, NAME), u8("category", 0x1C),
    u8("winningTrainerLanguage", 0x1D), u8("losingTrainerLanguage", 0x1E) }),
  -- pokeemerald/include/global.tv.h:150
  [9] = shape({ u8("sheen", 0x02), bits("flavor", 0x03, 0, 3), bits("color", 0x03, 3, 2),
    text("worstBlenderName", 0x04, NAME), text("playerName", 0x0C, NAME), u8("language", 0x14),
    u8("worstBlenderLanguage", 0x15) }),
  -- pokeemerald/include/global.tv.h:164
  [10] = shape({ u16("speciesOpponent", 0x02), text("playerName", 0x04, NAME), text("linkOpponentName", 0x0C, NAME),
    u16("move", 0x14), u16("speciesPlayer", 0x16), u8("battleType", 0x18), u8("language", 0x19),
    u8("linkOpponentLanguage", 0x1A) }),
  -- pokeemerald/include/global.tv.h:179
  [11] = shape({ text("playerName", 0x02, NAME), u8("idLo", 0x0A), u8("idHi", 0x0B), text("idolName", 0x0C, NAME),
    u16("words", 0x14, 1), u8("score", 0x16), u8("language", 0x17), u8("idolNameLanguage", 0x18) }),
  -- pokeemerald/include/global.tv.h:194
  [12] = shape({ text("playerName", 0x02, NAME), u8("contestCategory", 0x0A), text("nickname", 0x0B, NICK),
    u8("pokeblockState", 0x16), u8("language", 0x17), u8("pokemonNameLanguage", 0x18) }),
  -- pokeemerald/include/global.tv.h:207
  [21] = shape({ u8("language", 0x02), u8("language2", 0x03), text("nickname", 0x04, NICK), u8("ball", 0x0F),
    u16("species", 0x10), u8("nBallsUsed", 0x12), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:221
  [22] = shape({ u8("priceReduced", 0x02), u8("language", 0x03), u16("itemIds", 0x06, 3), u16("itemAmounts", 0x0C, 3),
    u8("shopLocation", 0x12), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:235
  [23] = shape({ u8("language", 0x02), u16("species", 0x0C), u16("species2", 0x0E), u8("nBallsUsed", 0x10),
    u8("outcome", 0x11), u8("location", 0x12), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:250
  [24] = shape({ u8("nBites", 0x02), u8("nFails", 0x03), u16("species", 0x04), u8("language", 0x06),
    text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:263
  [25] = shape({ u16("numPokeCaught", 0x02), u16("caughtPoke", 0x04), u16("steps", 0x06), u16("species", 0x08),
    u8("location", 0x0A), u8("language", 0x0B), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:278
  [26] = shape({ u16("dexCount", 0x02), u8("badgeCount", 0x04), u8("nSilverSymbols", 0x05), u8("nGoldSymbols", 0x06),
    u8("location", 0x07), u16("battlePoints", 0x08), u16("mapLayoutId", 0x0A), u8("language", 0x0C),
    text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:295
  [27] = shape({ u16("words", 0x04, 2), u8("gender", 0x08), u8("language", 0x09), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:308
  [28] = shape({ u16("item", 0x02), u8("location", 0x04), u8("language", 0x05), u16("mapLayoutId", 0x06),
    text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:321
  [29] = shape({ b8("won", 0x02), u8("whichGame", 0x03), u16("nCoins", 0x04), u8("language", 0x08),
    text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:335
  [30] = shape({ u16("lastOpponentSpecies", 0x02), u8("location", 0x04), u8("outcome", 0x05), u16("caughtMonBall", 0x06),
    u16("balls", 0x08), u16("poke1Species", 0x0A), u16("lastUsedMove", 0x0C), u8("language", 0x0E),
    text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:352
  [31] = shape({ u8("avgLevel", 0x02), u8("numDecorations", 0x03), { name = "decorations", off = 0x04, t = "u8", n = 4 },
    u16("species", 0x08), u16("move", 0x0A), u8("language", 0x0C), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:367
  [32] = shape({ u16("item", 0x02), u8("whichPrize", 0x04), u8("language", 0x05), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:379
  [33] = shape({ u16("move", 0x02), u16("foeSpecies", 0x04), u16("species", 0x06), u16("otherMoves", 0x08, 3),
    u16("betterMove", 0x0E), u8("nOtherMoves", 0x10), u8("language", 0x11), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:395
  [34] = shape({ u16("words", 0x04, 2), u8("language", 0x08), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:407
  [35] = shape({ u8("nRibbons", 0x02), u8("selectedRibbon", 0x03), text("nickname", 0x04, NICK), u8("language", 0x0F),
    u8("pokemonNameLanguage", 0x10), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:420
  [36] = shape({ u16("winStreak", 0x02), u16("species1", 0x04), u16("species2", 0x06), u16("species3", 0x08),
    u16("species4", 0x0A), u8("language", 0x0C), u8("facilityAndMode", 0x0D), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:436
  [37] = shape({ u16("count", 0x02), u8("actionIdx", 0x04), u8("language", 0x05), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:448
  [38] = shape({ u16("stepsInBase", 0x02), text("baseOwnersName", 0x04, NAME), u32("flags", 0x0C), u16("item", 0x10),
    u8("savedState", 0x12), text("playerName", 0x13, NAME), u8("language", 0x1B), u8("baseOwnersNameLanguage", 0x1C) }),
  -- pokeemerald/include/global.tv.h:463
  [39] = shape({ u8("monsCaught", 0x02), u8("pokeblocksUsed", 0x03), u8("language", 0x04), text("playerName", 0x13, NAME) }),
  -- pokeemerald/include/global.tv.h:475
  [41] = shape({ u8("unused1", 0x02), u8("unused3", 0x03), u16("moves", 0x04, 4), u16("species", 0x0C), u16("unused2", 0x0E),
    u8("locationMapNum", 0x10), u8("locationMapGroup", 0x11), u8("unused4", 0x12), u8("probability", 0x13),
    u8("level", 0x14), u8("unused5", 0x15), u16("daysBeforeOutbreak", 0x16), u8("language", 0x18) }),
}

local function specOf(kind) return KIND[kind] or COMMON end

local function allZero(s)
  for i = 2, SIZE do if s:byte(i) ~= 0 then return false end end
  return true
end

local function readSlot(s, codec)
  local kind = s:byte(1)
  if kind == 0 and allZero(s) then return { kind = 0, active = false } end
  return Structs.read(s, 0, specOf(kind), codec)
end

local function slotAt(x, i)
  local o = x.L.RSE.sb1.tvShows + i * SIZE
  return x.sb1:sub(o + 1, o + SIZE)
end

local function kindOf(show)
  return math.floor(tonumber(type(show) == "table" and show.kind) or 0) % 256
end

local function render(codec, tmpl, show, Rse)
  local kind = kindOf(show)
  local spec = specOf(kind)
  local fresh = tmpl:byte(1) ~= kind
  -- pokeemerald/src/tv.c:3029
  local buf = codec.newBuf(SIZE, fresh and string.rep("\0", SIZE) or tmpl)
  local src = {}
  for k, v in pairs(type(show) == "table" and show or {}) do src[k] = v end
  src.kind = kind
  Structs.write(buf, 0, spec, src, codec)
  local out = buf:str()
  if fresh then return out end
  local keep = {}
  for o = 0, SIZE - 1 do keep[o] = true end
  for _, f in ipairs(spec) do
    if not Rse.same(Structs.read(out, 0, { f }, codec), Structs.read(tmpl, 0, { f }, codec)) then
      for o = f.off, f.off + Structs.fieldSize(f) - 1 do keep[o] = false end
    end
  end
  local bytes = {}
  for o = 0, SIZE - 1 do bytes[o + 1] = keep[o] and tmpl:sub(o + 1, o + 1) or out:sub(o + 1, o + 1) end
  return table.concat(bytes)
end

return function(Rse)
  -- pokeemerald/include/global.h:1036
  Rse.defineSection({
    name = "tvShows",
    fields = { "tvShows" },
    read = function(x)
      local list = {}
      for i = 0, x.L.RSE.sb1.tvShowCount - 1 do list[i] = readSlot(slotAt(x, i), x.codec) end
      return { tvShows = list }
    end,
    write = function(x, v)
      local shows = type(v.tvShows) == "table" and v.tvShows or {}
      local o, count = x.L.RSE.sb1.tvShows, x.L.RSE.sb1.tvShowCount
      local tmpls, reads = {}, {}
      for i = 0, count - 1 do
        tmpls[i] = slotAt(x, i)
        reads[i] = readSlot(tmpls[i], x.codec)
      end
      for i = 0, count - 1 do
        local out = render(x.codec, tmpls[i], shows[i], Rse)
        local got = readSlot(out, x.codec)
        if Rse.same(got, reads[i]) then
          out = tmpls[i]
        elseif got.kind ~= 0 then
          -- pokeemerald/src/tv.c:3039
          for j = 0, count - 1 do
            if Rse.same(got, reads[j]) then
              out = tmpls[j]
              break
            end
          end
        end
        x.w1:bytes(o + i * SIZE, out)
      end
    end,
  })
end
