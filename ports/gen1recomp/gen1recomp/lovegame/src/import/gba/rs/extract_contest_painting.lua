local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Base = require("src.import.gba.rse.contest_painting_extract")
local Scoped = require("src.import.gba.rs.scoped_symbols")

local M = {SUB = Base.SUB, FILES = {}, paintingVersion = 1}
for _, file in ipairs(Base.FILES) do M.FILES[#M.FILES + 1] = file end
M.REQUIRED = K.required(M.SUB, M.FILES)

local function nativeText(c, off)
  local key
  for _, name in ipairs(c.S.namesAt(off)) do
    if not name:find(":", 1, true) then key = name; break end
  end
  assert(key, "native painting text has no unique symbol")
  local bytes = {}
  for i = 0, 1023 do
    local b = c:u8(off + i); bytes[#bytes + 1] = b
    if b == 255 then return {key = key, bytes = bytes, text = A.text(c, off)} end
  end
  error("native painting text is unterminated: " .. key)
end
local function window(c, name)
  local out, off = {}, c:off(name)
  for i, key in ipairs({"bg", "charbase", "screenbase", "priority", "palette", "foregroundColor", "backgroundColor",
    "shadowColor", "fontNum", "textMode", "spacing", "left", "top", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  return out
end

function M.run(rom, cache, opts)
  local c = Scoped.bind(A.context(rom, cache, opts, M.SUB))
  local get = function(i) return rom:get(i) end
  local man = {screen = "contest_painting", paintingVersion = M.paintingVersion, frames = {},
    captions = {}, captionParts = {}, rankNames = {}, textBytes = {}, strings = {}, captionPolicy = "rs_parts"}
  -- pokeruby/contest_painting.c:40
  local categories = {"cool", "beauty", "cute", "smart", "tough", "lobby"}
  for i, key in ipairs(categories) do
    local n = i - 1
    local tiles = Base.rlDecompress(get, c:off("gPictureFrameTiles_" .. n))
    local map = Base.rlDecompress(get, c:off("gPictureFrameTilemap_" .. n))
    assert(#tiles % 32 == 0 and #map % 64 == 0 and #map >= 32 * 20 * 2, "native painting frame dimensions")
    c:write(key .. ".gfx", tiles); c:write(key .. ".map", map)
    man.frames[key] = {gfx = c:path(key .. ".gfx"), map = c:path(key .. ".map"), tiles = #tiles / 32, entries = #map / 2}
  end
  local points = "image_processing_effects.o:sPointillismPoints"
  local bytes = c:raw(points)
  assert(#bytes % 3 == 0, "native pointillism records")
  c:write("pointillism.bin", bytes)
  man.pointillism = {path = c:path("pointillism.bin"), count = #bytes / 3}
  man.framePalette = K.palList(c:pal("contest_painting.o:gPictureFramePalettes", 128), 0, 128)
  local function remember(row)
    man.textBytes[row.key], man.strings[row.key] = row.bytes, row.text
    return row.key
  end
  local ranks = c:off("sContestRankNames")
  assert(c.S.size("sContestRankNames") == 20, "native five painting category names")
  for i = 0, 4 do man.rankNames[i] = remember(nativeText(c, assert(c:ptr(ranks + i * 4)))) end
  local captions = c:off("sMuseumCaptions")
  assert(c.S.size("sMuseumCaptions") == 15 * 8, "native fifteen caption pairs")
  for i = 0, 14 do
    local prefix = remember(nativeText(c, assert(c:ptr(captions + i * 8))))
    local suffix = remember(nativeText(c, assert(c:ptr(captions + i * 8 + 4))))
    man.captions[i] = prefix
    man.captionParts[i] = {prefix = prefix, suffix = suffix}
  end
  man.hallCaption = remember(nativeText(c, c:off("gContestText_ContestWinner")))
  man.hallPossessive = remember(nativeText(c, c:off("gOtherText_Unknown1")))
  man.window = window(c, "gWindowTemplate_ContestPainting")
  man.textPalette = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16)
  man.captionLayout = {hall = {x = 49, y = 112}, museum = {x = 25, y = 112},
    hallLatinControl = {252, 22}, nicknameBytes = 10, museumStart = 8, artistHidden = true}
  man.geometry = {picture = {88, 24, 64, 64}, artistCrop = {6, 2, 18, 10}, artistFill = 0x1015,
    mosaicStart = 30, mosaicDivisor = 2, bg0 = {priority = 2, charbase = 0, screenbase = 12},
    bg1 = {priority = 1, charbase = 1, screenbase = 10}}
  return A.finish(c, man)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  if not cache:read(base .. "manifest.lua"):find("paintingVersion = " .. M.paintingVersion, 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(base .. file) then return false end end
  return true
end
return M
