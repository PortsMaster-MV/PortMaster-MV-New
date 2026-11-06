local Area = {}

-- pokeemerald/src/pokedex_area_screen.c:36
Area.SCREEN_WIDTH = 32
Area.SCREEN_HEIGHT = 20
Area.GLOW_FULL = 0xFFFF
Area.GLOW_EDGE_R = 1
Area.GLOW_EDGE_L = 2
Area.GLOW_EDGE_B = 4
Area.GLOW_EDGE_T = 8
Area.GLOW_CORNER_TL = 16
Area.GLOW_CORNER_BL = 32
Area.GLOW_CORNER_TR = 64
Area.GLOW_CORNER_BR = 128
Area.GLOW_PALETTE = 10
-- pokeemerald/src/data/pokedex_area_glow.h:20
Area.GLOW_TILE_FULL = 16
Area.MAX_AREA_HIGHLIGHTS = 64
Area.MAX_AREA_MARKERS = 32

local band = require("bit").band
local bor = require("bit").bor
local bnot = require("bit").bnot

local function hasSpecies(info, species, size)
  if not (info and info.slots) then return false end
  for i = 1, math.min(size, #info.slots) do
    if info.slots[i].species == species then return true end
  end
  return false
end

-- pokeemerald/src/pokedex_area_screen.c:378
local function mapHasSpecies(h, species)
  return hasSpecies(h.land, species, 12) or hasSpecies(h.water, species, 5)
    or hasSpecies(h.fishing, species, 12) or hasSpecies(h.rocks or h.rockSmash, species, 5)
end

-- pokeemerald/src/pokedex_area_screen.c:242
function Area.findMapsWithMon(species, ctx)
  local r = { overworld = {}, special = {} }
  local roamer = ctx.roamer
  if roamer and roamer.species == species then
    if roamer.active and roamer.group then
      r.overworld[1] = { group = roamer.group, num = roamer.num, sec = ctx.mapsecOf(roamer.group, roamer.num) }
    end
    return r
  end
  for _, h in ipairs(ctx.hiddenSpecies or {}) do
    if h == species then return r end
  end
  local function setArea(g, n)
    if #r.overworld < Area.MAX_AREA_HIGHLIGHTS then
      r.overworld[#r.overworld + 1] = { group = g, num = n, sec = ctx.correct(ctx.mapsecOf(g, n)) }
    end
  end
  local function setSpecial(g, n)
    if #r.special >= Area.MAX_AREA_MARKERS then return end
    local sec = ctx.mapsecOf(g, n)
    if not sec or sec >= ctx.NONE then return end
    for _, m in ipairs(ctx.movingMapSecs or {}) do
      if m == sec then return end
    end
    for _, lm in ipairs(ctx.landmarks or {}) do
      if lm[1] == ctx.NONE then break end
      if lm[1] == sec and not ctx.flag(lm[2]) then return end
    end
    for _, s in ipairs(r.special) do
      if s == sec then return end
    end
    r.special[#r.special + 1] = sec
  end
  local function add(g, n)
    if g == ctx.groups.towns then
      setArea(g, n)
    elseif g == ctx.groups.dungeons or g == ctx.groups.special then
      setSpecial(g, n)
    end
  end
  for _, f in ipairs(ctx.feebas or {}) do
    if f[1] == species then add(f[2], f[3]) end
  end
  local keys = {}
  for k, h in pairs(ctx.encounters) do
    if type(k) == "string" and k:match("^%d+:%d+$") and type(h) == "table" then keys[#keys + 1] = k end
  end
  table.sort(keys, function(a, b)
    local ag, an = a:match("^(%d+):(%d+)$")
    local bg, bn = b:match("^(%d+):(%d+)$")
    ag, an, bg, bn = tonumber(ag), tonumber(an), tonumber(bg), tonumber(bn)
    if ag ~= bg then return ag < bg end
    return an < bn
  end)
  for _, k in ipairs(keys) do
    local h = ctx.encounters[k]
    local g, n = tonumber(h.mapGroup), tonumber(h.mapNum)
    local headers = { h }
    if h.variants and ctx.mapsecOf(g, n) == ctx.alteringCaveMapSec then
      -- pokeemerald/src/pokedex_area_screen.c:381
      headers = { h.variants[(ctx.alteringCaveId or 0) + 1] or h }
    end
    for _, hh in ipairs(headers) do
      if mapHasSpecies(hh, species) then add(g, n) end
    end
  end
  return r
end

-- pokeemerald/src/pokedex_area_screen.c:419
function Area.buildGlowTilemap(overworld, mapSecAt, mapping)
  local W, H = Area.SCREEN_WIDTH, Area.SCREEN_HEIGHT
  local t = {}
  for i = 0, W * H - 1 do t[i] = 0 end
  for _, a in ipairs(overworld) do
    local j = 0
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        if mapSecAt(x, y) == a.sec then t[j] = Area.GLOW_FULL end
        j = j + 1
      end
    end
  end
  local j = 0
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if t[j] == Area.GLOW_FULL then
        local function mark(o, bitv) if t[o] ~= Area.GLOW_FULL then t[o] = bor(t[o], bitv) end end
        if x ~= 0 then mark(j - 1, Area.GLOW_EDGE_L) end
        if x ~= W - 1 then mark(j + 1, Area.GLOW_EDGE_R) end
        if y ~= 0 then mark(j - W, Area.GLOW_EDGE_T) end
        if y ~= H - 1 then mark(j + W, Area.GLOW_EDGE_B) end
        if x ~= 0 and y ~= 0 then mark(j - W - 1, Area.GLOW_CORNER_TL) end
        if x ~= W - 1 and y ~= 0 then mark(j - W + 1, Area.GLOW_CORNER_TR) end
        if x ~= 0 and y ~= H - 1 then mark(j + W - 1, Area.GLOW_CORNER_BL) end
        if x ~= W - 1 and y ~= H - 1 then mark(j + W + 1, Area.GLOW_CORNER_BR) end
      end
      j = j + 1
    end
  end
  local out = { n = W * H }
  for i = 0, W * H - 1 do
    local v = t[i]
    if v == Area.GLOW_FULL then
      out[i] = Area.GLOW_TILE_FULL + Area.GLOW_PALETTE * 4096
    elseif v ~= 0 then
      if band(v, Area.GLOW_EDGE_L) ~= 0 then v = band(v, bnot(bor(Area.GLOW_CORNER_TL, Area.GLOW_CORNER_BL))) end
      if band(v, Area.GLOW_EDGE_R) ~= 0 then v = band(v, bnot(bor(Area.GLOW_CORNER_TR, Area.GLOW_CORNER_BR))) end
      if band(v, Area.GLOW_EDGE_T) ~= 0 then v = band(v, bnot(bor(Area.GLOW_CORNER_TR, Area.GLOW_CORNER_TL))) end
      if band(v, Area.GLOW_EDGE_B) ~= 0 then v = band(v, bnot(bor(Area.GLOW_CORNER_BR, Area.GLOW_CORNER_BL))) end
      out[i] = (mapping[v + 1] or 0) + Area.GLOW_PALETTE * 4096
    else
      out[i] = 0
    end
  end
  return out
end

-- pokeemerald/src/pokedex_area_screen.c:508
function Area.newGlow(numOverworld, numSpecial)
  return {
    showingMarkers = numSpecial > 0 and numOverworld == 0,
    markerTimer = 0, glowTimer = 0, lo = 0, hi = 64, markerFlashCounter = 1,
    numOverworld = numOverworld, numSpecial = numSpecial,
    eva = 0, evb = 16, markersInvisible = true,
  }
end

-- pokeemerald/src/pokedex_area_screen.c:525
function Area.stepGlow(g, sine)
  if not g.showingMarkers then
    if g.markerTimer == 0 then
      g.glowTimer = g.glowTimer + 1
      if g.glowTimer % 2 == 1 then
        g.lo = (g.lo + 4) % 128
      else
        g.hi = (g.hi + 4) % 128
      end
      g.eva = math.floor(sine(g.lo) / 16)
      g.evb = math.floor(sine(g.hi) / 16)
      g.markerTimer = 0
      if g.glowTimer == 64 then
        g.glowTimer = 0
        if g.numSpecial ~= 0 then g.showingMarkers = true end
      end
    else
      g.markerTimer = g.markerTimer - 1
    end
  else
    g.markerTimer = g.markerTimer + 1
    if g.markerTimer > 12 then
      g.markerTimer = 0
      g.markerFlashCounter = g.markerFlashCounter + 1
      g.markersInvisible = g.markerFlashCounter % 2 == 1
      if g.markerFlashCounter > 4 then
        g.markerFlashCounter = 1
        if g.numOverworld ~= 0 then g.showingMarkers = false end
      end
    end
  end
end

-- pokeemerald/src/pokedex_area_screen.c:707
function Area.markerPositions(special, entry)
  local out = {}
  for _, sec in ipairs(special) do
    local e = entry(sec)
    if e then
      local x = 8 * (e.x + 1) + 4 + 4 * (e.width - 1)
      local y = 8 * e.y + 28 + 4 * (e.height - 1)
      out[#out + 1] = { x = x, y = y, sec = sec }
    end
  end
  return out
end

return Area
