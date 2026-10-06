local Ribbons = {}

-- pokeemerald/include/pokemon.h:150
Ribbons.FIELDS = {
  { name = "cool", shift = 0, bits = 3 },
  { name = "beauty", shift = 3, bits = 3 },
  { name = "cute", shift = 6, bits = 3 },
  { name = "smart", shift = 9, bits = 3 },
  { name = "tough", shift = 12, bits = 3 },
  { name = "champion", shift = 15, bits = 1 },
  { name = "winning", shift = 16, bits = 1 },
  { name = "victory", shift = 17, bits = 1 },
  { name = "artist", shift = 18, bits = 1 },
  { name = "effort", shift = 19, bits = 1 },
  { name = "marine", shift = 20, bits = 1 },
  { name = "land", shift = 21, bits = 1 },
  { name = "sky", shift = 22, bits = 1 },
  { name = "country", shift = 23, bits = 1 },
  { name = "national", shift = 24, bits = 1 },
  { name = "earth", shift = 25, bits = 1 },
  { name = "world", shift = 26, bits = 1 },
  { name = "unused", shift = 27, bits = 4 },
  { name = "fateful", shift = 31, bits = 1 },
}
local FIELD = {}
for _, f in ipairs(Ribbons.FIELDS) do FIELD[f.name] = f end
Ribbons.FIELD = FIELD

-- pokeemerald/src/pokemon.c:4023
Ribbons.COUNTED = { "cool", "beauty", "cute", "smart", "tough", "champion", "winning", "victory", "artist", "effort",
  "marine", "land", "sky", "country", "national", "earth", "world" }
-- pokeemerald/src/pokemon.c:4046
Ribbons.PACKED = { "champion", "cool", "beauty", "cute", "smart", "tough", "winning", "victory", "artist", "effort",
  "marine", "land", "sky", "country", "national", "earth", "world" }

-- pokeemerald/include/constants/pokemon.h:97
Ribbons.ID = {
  CHAMPION = 0, COOL_NORMAL = 1, BEAUTY_NORMAL = 5, CUTE_NORMAL = 9, SMART_NORMAL = 13, TOUGH_NORMAL = 17,
  WINNING = 21, VICTORY = 22, ARTIST = 23, EFFORT = 24, MARINE = 25, LAND = 26, SKY = 27, COUNTRY = 28,
  NATIONAL = 29, EARTH = 30, WORLD = 31,
}
Ribbons.FIRST_GIFT_RIBBON = 25
Ribbons.LAST_GIFT_RIBBON = 31
Ribbons.NUM_GIFT_RIBBONS = 7
-- pokeemerald/include/constants/pokemon.h:143
Ribbons.MAX_GIFT_RIBBON = 64
-- pokeemerald/include/constants/global.h:64
Ribbons.GIFT_RIBBONS_COUNT = 11
-- pokeemerald/include/constants/tv.h:84
Ribbons.NUM_CUTIES_RIBBONS = 4
-- pokeemerald/include/constants/contest.h:18
Ribbons.CONTEST_RANK_MASTER = 3
-- pokeemerald/include/constants/global.h:86
Ribbons.CONTEST_CATEGORIES = { [0] = "cool", "beauty", "cute", "smart", "tough" }

-- pokeemerald/src/give_gift_ribbon_to_party.c:7
Ribbons.GIFT_FIELDS = { "marine", "land", "sky", "country", "national", "earth", "world" }

local P32 = 4294967296

local function getBits(w, shift, bits)
  return math.floor(w / 2 ^ shift) % (2 ^ bits)
end

local function setBits(w, shift, bits, v)
  local old = getBits(w, shift, bits)
  v = math.floor(tonumber(v) or 0) % (2 ^ bits)
  return w + (v - old) * 2 ^ shift
end

local function legacyValue(v)
  if v == true then return 1 end
  if v == false or v == nil then return 0 end
  return math.floor(tonumber(v) or 0)
end

function Ribbons.word(mon)
  if type(mon) ~= "table" then return 0 end
  local r = mon.ribbons
  local w = 0
  if type(r) == "number" then
    w = math.floor(r) % P32
  elseif type(r) == "table" then
    for _, f in ipairs(Ribbons.FIELDS) do
      if r[f.name] ~= nil then w = setBits(w, f.shift, f.bits, legacyValue(r[f.name])) end
    end
  end
  if mon.championRibbon == true then w = setBits(w, FIELD.champion.shift, 1, 1) end
  return w
end

function Ribbons.normalize(mon)
  if type(mon) ~= "table" then return 0 end
  local w = Ribbons.word(mon)
  mon.ribbons = w
  if mon.championRibbon ~= nil or getBits(w, FIELD.champion.shift, 1) == 1 then
    mon.championRibbon = getBits(w, FIELD.champion.shift, 1) == 1
  end
  return w
end

function Ribbons.get(mon, name)
  local f = assert(FIELD[name], "unknown ribbon field " .. tostring(name))
  return getBits(Ribbons.word(mon), f.shift, f.bits)
end

function Ribbons.set(mon, name, value)
  local f = assert(FIELD[name], "unknown ribbon field " .. tostring(name))
  local w = setBits(Ribbons.word(mon), f.shift, f.bits, value)
  mon.ribbons = w
  if name == "champion" or mon.championRibbon ~= nil then
    mon.championRibbon = getBits(w, FIELD.champion.shift, 1) == 1
  end
  return w
end

local function Pokemon()
  return require("src.core.game3.pokemon")
end

local function hasSpeciesNotEgg(mon)
  if type(mon) ~= "table" then return false end
  local P = Pokemon()
  if P.isEgg(mon) or mon.isBadEgg then return false end
  return (tonumber(P.speciesOf(mon)) or 0) ~= 0
end
Ribbons.hasSpeciesNotEgg = hasSpeciesNotEgg

-- pokeemerald/src/pokemon.c:4023
function Ribbons.count(mon)
  if not hasSpeciesNotEgg(mon) then return 0 end
  local w, n = Ribbons.word(mon), 0
  for _, name in ipairs(Ribbons.COUNTED) do
    local f = FIELD[name]
    n = n + getBits(w, f.shift, f.bits)
  end
  return n
end

-- pokeemerald/src/pokemon.c:4046
function Ribbons.packed(mon)
  if not hasSpeciesNotEgg(mon) then return 0 end
  local w, out, shift = Ribbons.word(mon), 0, 0
  for _, name in ipairs(Ribbons.PACKED) do
    local f = FIELD[name]
    out = out + getBits(w, f.shift, f.bits) * 2 ^ shift
    shift = shift + f.bits
  end
  return out
end

-- pokeemerald/src/pokenav_ribbons_summary.c:440
function Ribbons.monRibbonIds(mon, ribbonData)
  local flags = Ribbons.packed(mon)
  local normal, gift = {}, {}
  for _, d in ipairs(ribbonData) do
    local n = flags % (2 ^ d.numBits)
    local dst = d.isGift and gift or normal
    for j = 0, n - 1 do dst[#dst + 1] = d.ribbonId + j end
    flags = math.floor(flags / 2 ^ d.numBits)
  end
  return normal, gift
end

local function storage(session)
  local s = session and session.storage
  return type(s) == "table" and type(s.boxes) == "table" and s.boxes or nil
end

function Ribbons.boxMon(session, boxId, slot)
  local boxes = storage(session)
  local box = boxes and boxes[boxId]
  return box and type(box.mons) == "table" and box.mons[slot] or nil
end

-- pokeemerald/src/pokenav.c:388
function Ribbons.forEachMon(session, fn)
  for i, mon in ipairs(session and session.party or {}) do
    if hasSpeciesNotEgg(mon) and fn(mon, nil, i) then return true end
  end
  local boxes = storage(session)
  if boxes then
    for b = 1, #boxes do
      local box = boxes[b]
      if type(box) == "table" and type(box.mons) == "table" then
        for slot = 1, 30 do
          local mon = box.mons[slot]
          if hasSpeciesNotEgg(mon) and fn(mon, b, slot) then return true end
        end
      end
    end
  end
  return false
end

function Ribbons.anyMonHasRibbon(session)
  return Ribbons.forEachMon(session, function(mon) return Ribbons.count(mon) ~= 0 end)
end

-- pokeemerald/src/contest_util.c:2003
function Ribbons.giveContestRibbon(mon, category, rank)
  local name = type(category) == "string" and category or Ribbons.CONTEST_CATEGORIES[tonumber(category) or -1]
  if not (name and FIELD[name]) then return false end
  local have = Ribbons.get(mon, name)
  rank = tonumber(rank) or 0
  if have <= rank and have <= Ribbons.CONTEST_RANK_MASTER then
    Ribbons.set(mon, name, have + 1)
    return true
  end
  return false
end

-- pokeemerald/src/contest_util.c:1972
function Ribbons.hasContestRibbonAbove(mon, category, rank)
  local name = type(category) == "string" and category or Ribbons.CONTEST_CATEGORIES[tonumber(category) or -1]
  return name ~= nil and FIELD[name] ~= nil and Ribbons.get(mon, name) > (tonumber(rank) or 0)
end

function Ribbons.giftRibbons(session)
  local g = session and session.giftRibbons
  if type(g) ~= "table" then
    g = {}
    for i = 1, Ribbons.GIFT_RIBBONS_COUNT do g[i] = 0 end
    if session then session.giftRibbons = g end
  end
  return g
end

-- pokeemerald/src/give_gift_ribbon_to_party.c:14
function Ribbons.giveGiftRibbonToParty(session, index, ribbonId, setFlag)
  index, ribbonId = tonumber(index) or -1, tonumber(ribbonId) or -1
  if index < 0 or index >= Ribbons.GIFT_RIBBONS_COUNT or ribbonId > Ribbons.MAX_GIFT_RIBBON then return false end
  Ribbons.giftRibbons(session)[index + 1] = ribbonId
  local field = Ribbons.GIFT_FIELDS[index + 1]
  local got = false
  for _, mon in ipairs(session and session.party or {}) do
    if hasSpeciesNotEgg(mon) then
      if field then Ribbons.set(mon, field, 1) end
      got = true
    end
  end
  if got and setFlag then setFlag("FLAG_SYS_RIBBON_GET") end
  return got
end

-- pokeemerald/src/pokenav_ribbons_summary.c:817
function Ribbons.giftRibbonAt(session, ribbonId)
  local slot = (tonumber(ribbonId) or 0) - Ribbons.FIRST_GIFT_RIBBON
  local v = Ribbons.giftRibbons(session)[slot + 1]
  return tonumber(v) or 0
end

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  -- pokeemerald/include/global.h:1061
  SaveSections.register("giftRibbons", SaveSections.fields({ "giftRibbons" }, function(session)
    local g = {}
    for i = 1, Ribbons.GIFT_RIBBONS_COUNT do g[i] = 0 end
    session.giftRibbons = g
  end))
end

return Ribbons
