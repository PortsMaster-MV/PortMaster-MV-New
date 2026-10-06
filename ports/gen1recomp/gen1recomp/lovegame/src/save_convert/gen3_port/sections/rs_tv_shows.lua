local Structs = require("src.save_convert.gen3_port.structs")
local SIZE = 36
local Tv = {}

local function u8(name, off) return { name = name, off = off, t = "u8" } end
local function u16(name, off, n) return { name = name, off = off, t = "u16", n = n } end
local function text(name, off, len) return { name = name, off = off, t = "text", len = len, pad = 0 } end
local function bits(name, off, shift, width) return { name = name, off = off, t = "bits", of = "u8", shift = shift, width = width } end
local function shape(rows)
  local spec = { u8("kind", 0), { name = "active", off = 1, t = "bool8" } }
  local used = {}
  for _, f in ipairs(rows) do
    spec[#spec + 1] = f
    for o = f.off, f.off + Structs.fieldSize(f) - 1 do used[o] = true end
  end
  -- pokeruby/include/global.h:244
  for _, p in ipairs({ { "srcTrainerId3", 28 }, { "srcTrainerId2", 30 }, { "srcTrainerId", 32 }, { "trainerId", 34 } }) do
    if not used[p[2]] and not used[p[2] + 1] then
      spec[#spec + 1], spec[#spec + 2] = u8(p[1] .. "Lo", p[2]), u8(p[1] .. "Hi", p[2] + 1)
    end
  end
  return spec
end

-- pokeruby/include/global.h:258
local KIND = {
  [1] = shape({ u16("species", 2), u16("words", 4, 6), text("playerName", 16, 8), u8("language", 24) }),
  [2] = shape({ u16("species", 2), u16("words", 4, 6), text("playerName", 16, 8), u8("language", 24) }),
  [3] = shape({ u16("species", 2), bits("friendshipHighNybble", 4, 0, 4), bits("questionAsked", 4, 4, 4),
    text("playerName", 5, 8), u8("language", 13), u8("pokemonNameLanguage", 14), text("nickname", 16, 8), u16("words", 28, 2) }),
  [4] = shape({ u16("words", 2, 2), u16("species", 6) }),
  [5] = shape({ u16("species", 2), text("pokemonName", 4, 11), text("trainerName", 15, 11),
    u8("random", 26), u8("random2", 27), u16("randomSpecies", 28), u8("language", 30), u8("pokemonNameLanguage", 31) }),
  [6] = shape({ u16("species", 2), u16("words", 4, 2), text("pokemonNickname", 8, 11),
    bits("contestCategory", 19, 0, 3), bits("contestRank", 19, 3, 2), bits("contestResult", 19, 5, 2),
    u16("move", 20), text("playerName", 22, 8), u8("language", 30), u8("pokemonNameLanguage", 31) }),
  [7] = shape({ text("playerName", 2, 8), u16("species", 10), text("opponentName", 12, 8),
    u16("defeatedSpecies", 20), u16("numFights", 22), u16("words", 24, 1), u8("btLevel", 26),
    u8("interviewResponse", 27), u8("battleOutcome", 28), u8("playerLanguage", 29) }),
  [21] = shape({ u8("language", 2), u8("language2", 3), text("nickname", 4, 11), u8("ball", 15),
    u16("species", 16), u8("nBallsUsed", 18), text("playerName", 19, 8) }),
  [22] = shape({ u8("priceReduced", 2), u8("language", 3), u16("itemIds", 6, 3), u16("itemAmounts", 12, 3),
    u8("shopLocation", 18), text("playerName", 19, 8) }),
  [23] = shape({ u8("language", 2), u16("species", 12), u16("species2", 14), u8("nBallsUsed", 16),
    u8("outcome", 17), u8("location", 18), text("playerName", 19, 8) }),
  [24] = shape({ u8("nBites", 2), u8("nFails", 3), u16("species", 4), u8("language", 6), text("playerName", 19, 8) }),
  [25] = shape({ u16("numPokeCaught", 2), u16("caughtPoke", 4), u16("steps", 6), u16("species", 8),
    u8("location", 10), u8("language", 11), text("playerName", 19, 8) }),
  [41] = shape({ u8("unused1", 2), u8("unused3", 3), u16("moves", 4, 4), u16("species", 12), u16("unused2", 14),
    u8("locationMapNum", 16), u8("locationMapGroup", 17), u8("unused4", 18), u8("probability", 19),
    u8("level", 20), u8("unused5", 21), u16("daysBeforeOutbreak", 22), u8("language", 24) }),
}
local COMMON = shape({ { name = "raw", off = 2, t = "u8", n = 28 } })

local function listBytes(s)
  local out = {}
  for i = 1, #s do out[i] = s:byte(i) end
  return out
end
local function byteString(t)
  if type(t) ~= "table" or #t ~= SIZE then return nil end
  local out = {}
  for i = 1, SIZE do
    local v = tonumber(t[i])
    if not v or v % 1 ~= 0 or v < 0 or v > 255 then return nil end
    out[i] = string.char(v)
  end
  return table.concat(out)
end
local function kindOf(show) return math.floor(tonumber(type(show) == "table" and show.kind) or 0) % 256 end
local function readSlot(s, codec)
  local kind = s:byte(1)
  if kind == 0 and not s:find("[^%z]") then return { kind = 0, active = false } end
  local out = Structs.read(s, 0, KIND[kind] or COMMON, codec)
  out.nativeBytes = listBytes(s)
  if kind == 7 then out.wonTheChallenge = out.battleOutcome == 1 end
  return out
end
local function render(codec, template, show, same)
  local kind = kindOf(show)
  local own = byteString(type(show) == "table" and show.nativeBytes)
  local tmpl = own and own:byte(1) == kind and own or template
  local fresh = tmpl:byte(1) ~= kind or (KIND[kind] ~= nil and not (own and own:byte(1) == kind))
  if kind == 0 and not (own and own:byte(1) == 0) then return string.rep("\0", SIZE) end
  local spec = KIND[kind] or COMMON
  local buf = codec.newBuf(SIZE, fresh and string.rep("\0", SIZE) or tmpl)
  local src = {}
  for k, v in pairs(type(show) == "table" and show or {}) do src[k] = v end
  src.kind = kind
  if kind == 7 then
    local prior = not fresh and readSlot(tmpl, codec)
    if src.battleOutcome == nil or (prior and src.wonTheChallenge ~= prior.wonTheChallenge) then
      src.battleOutcome = src.wonTheChallenge == true and 1 or 2
    end
  end
  if not KIND[kind] then
    buf:w8(0, kind)
    if type(show) == "table" and show.active ~= nil then
      local active = show.active == true or (type(show.active) == "number" and show.active ~= 0)
      if active ~= (tmpl:byte(2) ~= 0) then buf:w8(1, active and 1 or 0) end
    end
    return buf:str()
  end
  Structs.write(buf, 0, spec, src, codec)
  if fresh then return buf:str() end
  local out, keep = buf:str(), {}
  for o = 0, SIZE - 1 do keep[o] = true end
  for _, f in ipairs(spec) do
    if not same(Structs.read(out, 0, { f }, codec), Structs.read(tmpl, 0, { f }, codec)) then
      for o = f.off, f.off + Structs.fieldSize(f) - 1 do keep[o] = false end
    end
  end
  local result = {}
  for o = 0, SIZE - 1 do result[o + 1] = (keep[o] and tmpl or out):sub(o + 1, o + 1) end
  return table.concat(result)
end

function Tv.section(same)
  return {
    name = "tvShows", fields = { "tvShows" },
    read = function(x)
      local list, o = {}, x.L.RSE.sb1.tvShows
      for i = 0, x.L.RSE.sb1.tvShowCount - 1 do
        list[i] = readSlot(x.sb1:sub(o + i * SIZE + 1, o + (i + 1) * SIZE), x.codec)
      end
      return { tvShows = list }
    end,
    write = function(x, v)
      local shows, o = type(v.tvShows) == "table" and v.tvShows or {}, x.L.RSE.sb1.tvShows
      for i = 0, x.L.RSE.sb1.tvShowCount - 1 do
        local at = o + i * SIZE
        local tmpl = x.sb1:sub(at + 1, at + SIZE)
        x.w1:bytes(at, render(x.codec, tmpl, shows[i], same))
      end
    end,
  }
end
Tv.readSlot, Tv.render, Tv.KIND = readSlot, render, KIND
return Tv
