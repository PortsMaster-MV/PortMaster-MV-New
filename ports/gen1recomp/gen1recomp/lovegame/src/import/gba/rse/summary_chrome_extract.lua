local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/summary"

M.PAGES = { "info", "info_egg", "skills", "battle_moves", "contest_moves" }

M.FILES = {
  "info.png", "info_egg.png", "skills.png", "battle_moves.png", "contest_moves.png",
  "move_types.png", "move_select.png", "status.png", "status_plate.png", "tiles.png", "markings.png",
}

-- pokeemerald/src/pokemon_summary_screen.c:2338
M.TILES = {
  { key = "dots", bankFrom = { "info", 11, 0 }, first = 0x40, count = 0x20 },
  -- pokeemerald/src/pokemon_summary_screen.c:2660
  { key = "exp", bank = 2, first = 0x62, count = 9 },
  -- pokeemerald/src/pokemon_summary_screen.c:123
  { key = "hearts", bank = 1, first = 0x39, count = 5 },
}

M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/src/pokemon_summary_screen.c:1321
local TILEMAPS = {
  info = "gSummaryPage_Info_Tilemap",
  info_egg = "gSummaryPage_InfoEgg_Tilemap",
  skills = "gSummaryPage_Skills_Tilemap",
  battle_moves = "gSummaryPage_BattleMoves_Tilemap",
  contest_moves = "gSummaryPage_ContestMoves_Tilemap",
}

local function window(c, off)
  return {
    bg = c:u8(off), left = c:u8(off + 1), top = c:u8(off + 2), width = c:u8(off + 3),
    height = c:u8(off + 4), paletteNum = c:u8(off + 5), baseBlock = c:u16(off + 6),
  }
end

local function windows(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.size(name) / 8 - 1 do
    local w = window(c, off + i * 8)
    if w.bg == 0xFF then break end
    out[#out + 1] = w
  end
  return out
end

local function bytes(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

-- pokeemerald/src/pokemon_summary_screen.c:2405
local function clearStatusPlate(map)
  local out = {}
  for i = 1, #map do out[i] = map:sub(i, i) end
  for row = 18, 19 do
    for col = 0, 9 do
      local o = (row * 32 + col) * 2
      out[o + 1], out[o + 2] = "\1", "\0"
    end
  end
  return table.concat(out)
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local gfx = c:lz("gSummaryScreen_Gfx")
  -- pokeemerald/src/pokemon_summary_screen.c:1353
  local pal = c:pal("gSummaryScreen_Pal", 128, nil, 0, true)
  c:pal("gPPTextPalette", 15, pal, 8 * 16 + 1)
  local layers = {}
  for _, key in ipairs(M.PAGES) do
    local map = c:lz(TILEMAPS[key])
    if key == "info" or key == "info_egg" then map = clearStatusPlate(map) end
    local idx, W, H = K.bakeText(gfx, map, 30, 20)
    layers[key] = c:layer({ key = key }, idx, W, H, pal)
  end
  layers.info.backdrop = pal[0]

  local entries, tileIndex = {}, {}
  -- pokeemerald/src/bg.c:1169
  local function bankAt(key, x, y)
    local map = c:lz(TILEMAPS[key])
    local lo, hi = map:byte((y * 32 + x) * 2 + 1, (y * 32 + x) * 2 + 2)
    return math.floor(((lo or 0) + (hi or 0) * 256) / 4096)
  end
  for _, t in ipairs(M.TILES) do
    if t.bankFrom then t.bank = bankAt(t.bankFrom[1], t.bankFrom[2], t.bankFrom[3]) end
    tileIndex[t.key] = { start = #entries, count = t.count }
    for i = 0, t.count - 1 do
      local e = t.first + i + t.bank * 4096
      entries[#entries + 1] = string.char(e % 256, math.floor(e / 256))
    end
  end
  local tIdx, TW, TH = K.bakeText(gfx, table.concat(entries), #entries, 1, { linear = true, mapWidth = #entries })
  c:png("tiles.png", TW, TH, tIdx, pal, true)

  -- pokeemerald/src/pokemon_summary_screen.c:1359
  local typesPal = c:pal("gMoveTypes_Pal", 48, nil, 0, true)
  local typeGfx = c:lz("gMoveTypes_Gfx")
  local typeCount = math.floor(#typeGfx / (32 * 8))
  local typeFrames, typeIdx = {}, {}
  for i = 0, typeCount - 1 do typeFrames[i + 1] = K.bakeSprite(typeGfx, 32, 16, i * 8, 4) end
  local sheet, SW, SH = K.stack(typeFrames, 32, 16)
  local typePalNum = bytes(c, "sMoveTypeToOamPaletteNum")
  for i = 1, #sheet do typeIdx[i] = sheet[i] end
  local rgbaPal = {}
  for i = 0, 47 do rgbaPal[i] = typesPal[i] end
  local banked = {}
  for f = 0, typeCount - 1 do
    local bank = (typePalNum[f + 1] or 13) - 13
    if bank < 0 or bank > 2 then bank = 0 end
    for i = f * 32 * 16 + 1, (f + 1) * 32 * 16 do
      local v = sheet[i]
      banked[i] = v == 0 and 0 or (bank * 16 + v)
    end
  end
  c:png("move_types.png", SW, SH, banked, rgbaPal, true)

  -- pokeemerald/src/pokemon_summary_screen.c:1363
  local selPal = c:pal("gSummaryMoveSelect_Pal", 16, nil, 0, true)
  local selGfx = c:lz("gSummaryMoveSelect_Gfx")
  local selFrames = {}
  for i = 0, math.floor(#selGfx / (32 * 4)) - 1 do selFrames[i + 1] = K.bakeSprite(selGfx, 16, 16, i * 4, 4) end
  local selSheet, selW, selH = K.stack(selFrames, 16, 16)
  c:png("move_select.png", selW, selH, selSheet, selPal, true)

  -- pokeemerald/src/pokemon_summary_screen.c:369
  local plateMap = string.char(
    4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0x17, 8, 0x17, 8, 0x17, 8, 0x0b, 0,
    4, 8, 4, 8, 4, 8, 4, 8, 4, 8, 4, 8, 0x17, 0, 0x17, 0, 0x17, 0, 0x0b, 8)
  local plateIdx, PW, PH = K.bakeText(gfx, plateMap, 10, 2, { linear = true, mapWidth = 10 })
  c:png("status_plate.png", PW, PH, plateIdx, pal, true)

  -- pokeemerald/src/pokemon_summary_screen.c:1367
  local stPal = c:pal("gStatusPal_Icons", 16, nil, 0, true)
  local stGfx = c:lz("gStatusGfx_Icons")
  local stFrames = {}
  for i = 0, math.floor(#stGfx / (32 * 4)) - 1 do stFrames[i + 1] = K.bakeSprite(stGfx, 32, 8, i * 4, 4) end
  local stSheet, stW, stH = K.stack(stFrames, 32, 8)
  c:png("status.png", stW, stH, stSheet, stPal, true)

  -- pokeemerald/src/mon_markings.c:589
  local markings = c:strip("markings", c:raw("sMonMarkings_Gfx"), 32, 8, 16, c:pal("sMarkings_Pal", 16))

  -- pokeemerald/src/pokemon.c:6585
  local noFlip, so = {}, c:off("gSpeciesInfo")
  for i = 0, c.S.size("gSpeciesInfo") / 28 - 1 do
    if c:u8(so + i * 28 + 25) >= 128 then noFlip[i] = true end
  end

  return true, c:finish({
    screen = "summary",
    markings = markings,
    noFlip = noFlip,
    layers = layers,
    tiles = { png = c:path("tiles.png"), index = tileIndex },
    moveTypes = { png = c:path("move_types.png"), w = 32, h = 16, count = typeCount },
    moveSelect = { png = c:path("move_select.png"), w = 16, h = 16, count = #selFrames },
    statusPlate = { png = c:path("status_plate.png"), x = 0, y = 144 },
    status = { png = c:path("status.png"), w = 32, h = 8, count = #stFrames },
    palette = K.palList(pal, 0, 144),
    windows = windows(c, "sSummaryTemplate"),
    pageWindows = {
      info = windows(c, "sPageInfoTemplate"),
      skills = windows(c, "sPageSkillsTemplate"),
      moves = windows(c, "sPageMovesTemplate"),
    },
    textColors = bytes(c, "pokemon_summary_screen.o:sTextColors"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
