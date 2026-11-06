-- One property schema for forms, writes and validation. Storage ranges alone
-- do not prove an encounter or event distribution was obtainable.
local Gen = require("Gen")
local P = {}
local function field(key, label, lo, hi, extra)
  local d = extra or {}
  d.key, d.label, d.lo, d.hi = key, label, lo, hi
  return d
end
local COMMON = {
  field("otName", "Original trainer", nil, nil, { text = true, max = 7, alias = "ot" }),
  field("otId", "Trainer ID", 0, 65535),
}
local G3 = {
  field("otSecretId", "Secret ID", 0, 65535),
  field("personality", "Personality (PID)", 0, 4294967295),
  field("otGender", "OT gender", 0, 1, { choices = { { 0, "Male" }, { 1, "Female" } } }),
  field(
    "language",
    "Language",
    1,
    7,
    {
      values = { 1, 2, 3, 4, 5, 7 },
      default = 2,
      choices = {
        { 1, "Japanese" },
        { 2, "English" },
        { 3, "French" },
        { 4, "Italian" },
        { 5, "German" },
        { 7, "Spanish" },
      },
    }
  ),
  field("metLevel", "Found at level", 0, 100),
  field("metLocation", "Found at", 0, 255),
  field(
    "metGame",
    "Origin game",
    0,
    15,
    {
      values = { 0, 1, 2, 3, 4, 5, 15 },
      choices = {
        { 0, "Unknown" },
        { 1, "Sapphire" },
        { 2, "Ruby" },
        { 3, "Emerald" },
        { 4, "FireRed" },
        { 5, "LeafGreen" },
        { 15, "Colosseum/XD" },
      },
    }
  ),
  field(
    "pokeball",
    "Ball",
    1,
    12,
    {
      default = 4,
      choices = {
        { 1, "Master" },
        { 2, "Ultra" },
        { 3, "Great" },
        { 4, "Poke Ball" },
        { 5, "Safari" },
        { 6, "Net" },
        { 7, "Dive" },
        { 8, "Nest" },
        { 9, "Repeat" },
        { 10, "Timer" },
        { 11, "Luxury" },
        { 12, "Premier" },
      },
    }
  ),
  field("pokerus", "Pokérus", 0, 255),
  field("markings", "Markings", 0, 15),
  field("isEgg", "Egg", nil, nil, { toggle = true, alias = "egg" }),
  field("modernFatefulEncounter", "Fateful encounter", nil, nil, { toggle = true }),
}
P.contest = {}
for _, key in ipairs({ "cool", "beauty", "cute", "smart", "tough", "sheen" }) do
  P.contest[#P.contest + 1] =
    field("contest." .. key, key:upper(), 0, 255, { parent = "contest", child = key })
end
P.ribbons = {}
for i, key in ipairs({ "Cool", "Beauty", "Cute", "Smart", "Tough" }) do
  P.ribbons[#P.ribbons + 1] =
    field("ribbon." .. key, key .. " contest rank (0-4)", 0, 4, { shift = (i - 1) * 3, width = 3 })
end
for i, key in ipairs({
  "Champion",
  "Winning",
  "Victory",
  "Artist",
  "Effort",
  "Marine",
  "Land",
  "Sky",
  "Country",
  "National",
  "Earth",
  "World",
}) do
  P.ribbons[#P.ribbons + 1] =
    field("ribbon." .. key, key .. " ribbon", 0, 1, { shift = 14 + i, width = 1, toggle = true })
end
function P.identity(S)
  local out = {}
  for _, d in ipairs(COMMON) do
    out[#out + 1] = d
  end
  if Gen.ofState(S) == 3 then
    for _, d in ipairs(G3) do
      out[#out + 1] = d
    end
  elseif Gen.ofState(S) == 2 then
    out[#out + 1] = field("pokerus", "Pokérus", 0, 255)
    out[#out + 1] = field("isEgg", "Egg", nil, nil, { toggle = true, alias = "egg" })
    if Gen.hasCaughtData(S.save, S.version) then
      out[#out + 1] = field("caughtLevel", "Caught level", 0, 63)
      out[#out + 1] = field("caughtLocation", "Found at", 0, 127)
      out[#out + 1] =
        field("caughtTime", "Time found", 0, 3)
    end
  end
  return out
end
function P.all(S)
  local out = P.identity(S)
  if Gen.ofState(S) == 3 then
    for _, list in ipairs({ P.contest, P.ribbons }) do
      for _, d in ipairs(list) do
        out[#out + 1] = d
      end
    end
  end
  return out
end
function P.find(S, key)
  for _, d in ipairs(P.all(S)) do
    if d.key == key then
      return d
    end
  end
end
function P.ribbonWord(mon)
  if type(mon.ribbons) == "table" then
    return require("src.core.game3.rse.ribbons").word(mon)
  end
  return tonumber(mon.ribbons) or 0
end
function P.get(mon, d)
  if d.shift then
    if d.key == "ribbon.Champion" and mon.championRibbon ~= nil then
      return mon.championRibbon and 1 or 0
    end
    return math.floor(P.ribbonWord(mon) / 2 ^ d.shift) % 2 ^ d.width
  end
  if d.parent then
    return (mon[d.parent] and mon[d.parent][d.child]) or 0
  end
  local v = mon[d.key]
  if d.key == "modernFatefulEncounter" and v == nil then
    return math.floor(P.ribbonWord(mon) / 2 ^ 31) % 2 == 1
  end
  if v == nil and d.alias then
    v = mon[d.alias]
  end
  if v == nil then
    if d.toggle then
      return false
    end
    v = d.default or (d.text and "") or 0
  end
  return v
end
function P.parse(d, value)
  if d.toggle then
    if value == true or value == 1 then
      return true
    end
    if value == false or value == 0 then
      return false
    end
    return nil, "Choose on or off"
  end
  if d.text then
    return tostring(value or "")
  end
  local n = tonumber(value)
  if not n or n ~= n or n ~= math.floor(n) or n < d.lo or n > d.hi then
    return nil, ("%s must be a whole number from %d to %d"):format(d.label, d.lo, d.hi)
  end
  if d.values then
    local found = false
    for _, v in ipairs(d.values) do
      if v == n then
        found = true
      end
    end
    if not found then
      return nil, "Choose a supported value for " .. d.label
    end
  end
  return n
end
-- Only Ops calls this after validation.
function P.write(mon, d, value)
  if d.shift then
    local word = P.ribbonWord(mon)
    local old = math.floor(word / 2 ^ d.shift) % 2 ^ d.width
    local n = value == true and 1 or value == false and 0 or value
    mon.ribbons = word + (n - old) * 2 ^ d.shift
    if d.key == "ribbon.Champion" then
      mon.championRibbon = n == 1
    end
  elseif d.parent then
    mon[d.parent] = mon[d.parent] or {}
    mon[d.parent][d.child] = value
  else
    mon[d.key] = value
    if d.key == "modernFatefulEncounter" then
      require("src.core.game3.rse.ribbons").set(mon, "fateful", value and 1 or 0)
    end
    if d.alias then
      mon[d.alias] = value
    end
  end
end
return P
