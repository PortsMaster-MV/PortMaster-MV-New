
local Palette = {}

local pack = nil

function Palette.packs()
  if pack == nil then
    local ok, data = pcall(require, "data.gb_palettes")
    pack = ok and data or false
  end
  return pack or {}
end


local MONO_STEPS = { 1.00, 0.72, 0.38, 0.12 }

Palette.MONO_COLOURS = {
  { "GREEN",     0x9b, 0xbc, 0x0f },   -- DMG
  { "LIME",      0xa8, 0xd8, 0x38 },
  { "OLIVE",     0xa6, 0xac, 0x84 },   -- Pocket
  { "AMBER",     0xff, 0xb0, 0x00 },   -- plasma terminal
  { "ORANGE",    0xff, 0x80, 0x30 },
  { "RED",       0xff, 0x50, 0x50 },
  { "ROSE",      0xff, 0x90, 0xb0 },
  { "MAGENTA",   0xf0, 0x60, 0xd0 },
  { "PURPLE",    0xb0, 0x70, 0xf0 },
  { "INDIGO",    0x80, 0x80, 0xf0 },
  { "BLUE",      0x50, 0xa0, 0xff },
  { "CYAN",      0x40, 0xe0, 0xe0 },   -- VFD
  { "TEAL",      0x40, 0xc0, 0xa0 },
  { "MINT",      0x90, 0xe0, 0xb0 },
  { "SAND",      0xe0, 0xc8, 0x90 },
  { "BROWN",     0xc0, 0x90, 0x50 },
  { "WHITE",     0xff, 0xff, 0xff },   -- plain DMG greys
  { "SILVER",    0xd0, 0xd8, 0xe0 },
}

local function monoRamp(r, g, b)
  local out = {}
  for i = 1, 4 do
    local f = MONO_STEPS[i]
    out[i] = { math.floor(r * f + 0.5),
               math.floor(g * f + 0.5),
               math.floor(b * f + 0.5) }
  end
  return out
end

Palette.monoRamp = monoRamp                      -- named for the suite


function Palette.packId(group, name)
  return "p:" .. group .. "/" .. name
end

function Palette.monoId(r, g, b)
  return ("m:%02x%02x%02x"):format(r, g, b)
end

local function unhex(text)
  if type(text) ~= "string" or #text ~= 24 then return nil end
  local out = {}
  for i = 1, 4 do
    local at = (i - 1) * 6
    local r = tonumber(text:sub(at + 1, at + 2), 16)
    local g = tonumber(text:sub(at + 3, at + 4), 16)
    local b = tonumber(text:sub(at + 5, at + 6), 16)
    if not (r and g and b) then return nil end
    out[i] = { r, g, b }
  end
  return out
end

Palette.unhex = unhex                            -- named for the suite

local RAMP_INDEX = 2

local GREY_CHROMA = 12
local HUE_ARC = 50

Palette.GREY_CHROMA = GREY_CHROMA                -- named for the suite
Palette.HUE_ARC = HUE_ARC

local function hueChroma(c)
  local r, g, b = c[1] or 0, c[2] or 0, c[3] or 0
  local mx = math.max(r, g, b)
  local mn = math.min(r, g, b)
  local chroma = mx - mn
  if chroma <= 0 then return 0, 0 end
  local h
  if mx == r then h = ((g - b) / chroma) % 6
  elseif mx == g then h = (b - r) / chroma + 2
  else h = (r - g) / chroma + 4 end
  return h * 60, chroma
end

Palette.hueChroma = hueChroma                    -- named for the suite

local function hueArc(hues)
  local best = 360
  for i = 1, #hues do
    local widest = 0
    for j = 1, #hues do
      local d = (hues[j] - hues[i]) % 360
      if d > widest then widest = d end
    end
    if widest < best then best = widest end
  end
  return best
end

Palette.hueArc = hueArc                          -- named for the suite

function Palette.categoryOf(ramp)
  if type(ramp) ~= "table" or not ramp[4] then return nil end
  local hues = {}
  for i = 1, 4 do
    local h, chroma = hueChroma(ramp[i])
    if chroma > GREY_CHROMA then hues[#hues + 1] = h end
  end
  if #hues == 0 then return "grey" end
  return hueArc(hues) <= HUE_ARC and "single" or "full"
end

Palette.CATEGORIES = {
  { key = "full",   label = "FULL COLOUR" },
  { key = "single", label = "SINGLE COLOUR" },
  { key = "grey",   label = "GREYSCALE" },
}

local byId, buckets = nil, nil

local function buildIndex()
  byId, buckets = {}, {}
  for _, category in ipairs(Palette.CATEGORIES) do buckets[category.key] = {} end
  for _, p in ipairs(Palette.packs()) do
    for _, entry in ipairs(p.palettes or {}) do
      local name = entry[1]
      if type(name) == "string" then
        local id = Palette.packId(p.name, name)
        byId[id] = entry
        local raw = unhex(entry[RAMP_INDEX] or entry[2])
        local bucket = raw and buckets[Palette.categoryOf(raw) or ""] or nil
        if bucket then
          bucket[#bucket + 1] = { name = name, pack = p.name, id = id }
        end
      end
    end
  end
end

local function ensureIndex()
  if not byId then buildIndex() end
end

function Palette.categories()
  ensureIndex()
  local out = {}
  for i, category in ipairs(Palette.CATEGORIES) do
    out[i] = { key = category.key, name = category.label,
               palettes = buckets[category.key] or {} }
  end
  return out
end

function Palette.category(key)
  ensureIndex()
  if not buckets[key] then return nil end
  for _, category in ipairs(Palette.CATEGORIES) do
    if category.key == key then
      return { key = key, name = category.label, palettes = buckets[key] }
    end
  end
  return nil
end

function Palette.locate(id)
  if type(id) ~= "string" or id == "" then return nil end
  ensureIndex()
  for _, category in ipairs(Palette.CATEGORIES) do
    for i, item in ipairs(buckets[category.key] or {}) do
      if item.id == id then return category.key, i end
    end
  end
  return nil
end

local function findPack(group, name)
  ensureIndex()
  return byId[Palette.packId(group, name)]
end

Palette.findPack = findPack                      -- named for the suite

function Palette.label(id)
  if type(id) ~= "string" or id == "" then return nil end
  local hex = id:match("^m:(%x+)$")
  if hex then
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    for _, c in ipairs(Palette.MONO_COLOURS) do
      if c[2] == r and c[3] == g and c[4] == b then return c[1] end
    end
    return "MONO"
  end
  local name = id:match("^p:.*/([^/]+)$")
  return name or id
end

local cacheId, cacheRamp = nil, nil

function Palette.ramp(id)
  if type(id) ~= "string" or id == "" then return nil end
  if id == cacheId then return cacheRamp end

  local out = nil
  local hex = id:match("^m:(%x+)$")
  if hex and #hex == 6 then
    out = monoRamp(tonumber(hex:sub(1, 2), 16) or 0,
                   tonumber(hex:sub(3, 4), 16) or 0,
                   tonumber(hex:sub(5, 6), 16) or 0)
  else
    local group, name = id:match("^p:(.*)/([^/]+)$")
    if group then
      local entry = findPack(group, name)
      local ramp = entry and unhex(entry[RAMP_INDEX] or entry[2])
      if ramp then
        out = { ramp[4], ramp[3], ramp[2], ramp[1] }
      end
    end
  end

  cacheId, cacheRamp = id, out
  return out
end

function Palette.invalidate()
  cacheId, cacheRamp = nil, nil
  byId, buckets = nil, nil
end

function Palette.swatch(id)
  local ramp = Palette.ramp(id)
  if not ramp then return nil end
  return { ramp[4], ramp[3], ramp[2], ramp[1] }
end

return Palette
