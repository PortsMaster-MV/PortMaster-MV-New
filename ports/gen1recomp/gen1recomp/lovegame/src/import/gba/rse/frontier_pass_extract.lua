local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/frontier_pass"

-- pokeemerald/src/graphics.c:1518
M.GFX = {
  bg = { "gFrontierPassBg_Gfx", true },
  mapAndCard = { "gFrontierPassMapAndCard_Gfx", true },
  medals = { "gFrontierPassMedals_Gfx", true },
  -- pokeemerald/src/frontier_pass.c:181
  mapScreen = { "frontier_pass.o:sMapScreen_Gfx", true },
  cursor = { "frontier_pass.o:sCursor_Gfx", true },
  heads = { "frontier_pass.o:sHeads_Gfx", true },
  mapCursor = { "frontier_pass.o:sMapCursor_Gfx", true },
}

M.MAPS = {
  bg = { "gFrontierPassBg_Tilemap", true },
  cancel = { "gFrontierPassCancelButton_Tilemap", false },
  cancelHi = { "gFrontierPassCancelButtonHighlighted_Tilemap", false },
  -- pokeemerald/src/frontier_pass.c:185
  mapScreen = { "frontier_pass.o:sMapScreen_Tilemap", true },
  mapAndCard = { "frontier_pass.o:sMapAndCard_ZoomedOut_Tilemap", true },
  record = { "frontier_pass.o:sBattleRecord_Tilemap", true },
  zoom = { "frontier_pass.o:sMapAndCard_Zooming_Tilemap", true },
}

M.FILES = {}
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
for k in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

local function bytesAt(c, off, maxLen)
  local out = {}
  for i = 0, (maxLen or 512) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

local function textIr(c, ptrOff)
  local p = c:ptr(ptrOff)
  if not p then return false end
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.decode(bytesAt(c, p), { dialect = "rse" })
end

-- pokeemerald/src/frontier_pass.c:346
local function areas(c)
  local name = "frontier_pass.o:sPassAreasLayout"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 8 - 1 do
    local b = off + i * 8
    out[i + 1] = { yStart = c:s16(b), yEnd = c:s16(b + 2), xStart = c:s16(b + 4), xEnd = c:s16(b + 6) }
  end
  return out
end

-- pokeemerald/src/frontier_pass.c:556
local function landmarks(c)
  local name = "frontier_pass.o:sMapLandmarks"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 16 - 1 do
    local b = off + i * 16
    out[i + 1] = { name = textIr(c, b), description = textIr(c, b + 4), x = c:s16(b + 8), y = c:s16(b + 10),
      animNum = c:u8(b + 12) }
  end
  return out
end

local function textList(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = textIr(c, off + i * 4) end
  return out
end

local function pal16(c, name)
  return K.palList(c:pal(name, 16, {}, 0), 0, 16)
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local gfx = {}
  for key, spec in pairs(M.GFX) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    c:write(key .. ".gfx", data)
    gfx[key] = { path = c:path(key .. ".gfx"), bytes = #data }
  end
  local maps = {}
  for key, spec in pairs(M.MAPS) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end
  local bgPal = c:pal("gFrontierPassBg_Pal", c.S.size("gFrontierPassBg_Pal") / 2, {}, 0)
  local coords = {}
  local co = c:off("frontier_pass.o:sBgAffineCoords")
  for i = 0, 1 do coords[i + 1] = { c:s16(co + i * 4), c:s16(co + i * 4 + 2) } end
  return true, c:finish({
    screen = "frontier_pass",
    gfx = gfx,
    maps = maps,
    palettes = {
      bg = K.palList(bgPal, 0, #bgPal + 1),
      cursor = pal16(c, "gFrontierPassCursor_Pal"),
      mapCursor = pal16(c, "gFrontierPassMapCursor_Pal"),
      medalsSilver = pal16(c, "gFrontierPassMedalsSilver_Pal"),
      medalsGold = pal16(c, "gFrontierPassMedalsGold_Pal"),
      maleHead = pal16(c, "frontier_pass.o:sMaleHead_Pal"),
      femaleHead = pal16(c, "frontier_pass.o:sFemaleHead_Pal"),
    },
    areas = areas(c),
    landmarks = landmarks(c),
    descriptions = textList(c, "frontier_pass.o:sPassAreaDescriptions"),
    affineCoords = coords,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
