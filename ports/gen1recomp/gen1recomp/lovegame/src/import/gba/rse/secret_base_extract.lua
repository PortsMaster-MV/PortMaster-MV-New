local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "secret_base"

M.FILES = { "put_away_cursor_male.png", "put_away_cursor_female.png", "in_use_red.png", "in_use_blue.png" }

M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/include/decoration.h:18
local SHAPE_CELLS = { [0] = 1, 2, 3, 8, 4, 2, 3, 8, 9, 6 }
M.SHAPE_CELLS = SHAPE_CELLS

local function bytes(c, name)
  local s = c:raw(name)
  local out = {}
  for i = 1, #s do out[i] = s:byte(i) end
  return out
end

local function u16s(c, name)
  local s = c:raw(name)
  local out = {}
  for i = 0, math.floor(#s / 2) - 1 do
    local lo, hi = s:byte(i * 2 + 1, i * 2 + 2)
    out[i] = lo + hi * 256
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/secret_base.c:111
  local entrances = {}
  local raw = bytes(c, "sSecretBaseEntrancePositions")
  for g = 0, math.floor(#raw / 4) - 1 do
    entrances[g] = { mapNum = raw[g * 4 + 1], warpId = raw[g * 4 + 2], x = raw[g * 4 + 3], y = raw[g * 4 + 4] }
  end

  -- pokeemerald/src/secret_base.c:98
  local mt = u16s(c, "sSecretBaseEntranceMetatiles")
  local entranceMetatiles = {}
  for i = 0, math.floor((#mt + 1) / 2) - 1 do
    entranceMetatiles[i + 1] = { closed = mt[i * 2], open = mt[i * 2 + 1] }
  end

  -- pokeemerald/src/secret_base.c:162
  local ownerGfx = bytes(c, "sSecretBaseOwnerGfxIds")

  -- pokeemerald/include/decoration.h:43
  local base = c:off("gDecorations")
  local count = math.floor(c.S.size("gDecorations") / 32)
  local tiles = {}
  for i = 0, count - 1 do
    local e = base + i * 32
    local shape = c:u8(e + 18)
    local p = c:ptr(e + 28)
    local list = {}
    if p then
      for j = 0, (SHAPE_CELLS[shape] or 1) - 1 do list[j + 1] = c:u16(p + j * 2) end
    end
    tiles[i] = list
  end

  -- pokeemerald/src/data/tilesets/metatiles.h:98
  local attrs = u16s(c, "gMetatileAttributes_SecretBaseSecondary")

  -- pokeemerald/src/decoration.c:330
  local movement = {}
  local mv = bytes(c, "sDecorationMovementInfo")
  for s = 0, math.floor(#mv / 4) - 1 do
    movement[s] = { cameraX = mv[s * 4 + 3], cameraY = mv[s * 4 + 4] }
  end

  -- pokeemerald/src/decoration.c:410
  local stand = bytes(c, "sDecorationStandElevations")
  local slide = bytes(c, "sDecorationSlideElevation")

  -- pokeemerald/src/decoration.c:298
  local menuPal = c:pal("sDecorationMenuPalette", 16)

  -- pokeemerald/src/decoration.c:437
  local male = c:pal("sBrendanPalette", 16)
  local female = c:pal("sMayPalette", 16)
  local cursor = c:strip("put_away_cursor", c:raw("sDecorationPuttingAwayCursor"), 16, 16, 1,
    K.variants({ { name = "male", pal = male }, { name = "female", pal = female } }))

  -- pokeemerald/src/menu.c:113
  local icons = bytes(c, "sMenuInfoIcons")
  local stride = math.floor(#icons / 26)
  local info = c:raw("gMenuInfoElements_Gfx")
  -- pokeemerald/include/menu.h:22
  local red = c:strip("in_use_red", info, 8, 8, 1, menuPal, 4, icons[24 * stride + 3])
  local blue = c:strip("in_use_blue", info, 8, 8, 1, menuPal, 4, icons[25 * stride + 3])

  -- pokeemerald/src/menu.c:98
  local yn = bytes(c, "sYesNo_WindowTemplates")

  -- pokeemerald/src/pokemon.c:2057
  local classes = bytes(c, "sSecretBaseFacilityClasses")

  return true, c:finish({
    screen = "secret_base",
    entrances = entrances,
    entranceMetatiles = entranceMetatiles,
    ownerGfx = ownerGfx,
    decorTiles = tiles,
    decorCount = count,
    secondaryAttributes = attrs,
    movement = movement,
    standElevations = stand,
    slideElevations = slide,
    menuPalette = K.palList(menuPal, 0, 16),
    putAwayCursor = cursor,
    inUseRed = red,
    inUseBlue = blue,
    yesNoWindow = { left = yn[2], top = yn[3], width = yn[4], height = yn[5] },
    facilityClasses = classes,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
