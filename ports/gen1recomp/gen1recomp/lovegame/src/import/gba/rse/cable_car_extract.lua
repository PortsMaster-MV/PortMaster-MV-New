local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "cable_car"

M.FILES = { "bg_tiles.4bpp", "cable_car.png", "door.png", "cable.png", "ash.png" }

M.REQUIRED = K.required(M.SUB, M.FILES)

local function u16List(bytes)
  local out = {}
  for i = 0, math.floor(#bytes / 2) - 1 do
    local lo, hi = bytes:byte(i * 2 + 1, i * 2 + 2)
    out[i + 1] = lo + hi * 256
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/cable_car.c:292
  local bgTiles = c:lz("gCableCarBg_Gfx")
  c:write("bg_tiles.4bpp", bgTiles)
  -- pokeemerald/src/cable_car.c:298
  local bgPal = c:pal("gCableCarBg_Pal", 64)

  -- pokeemerald/src/cable_car.c:134
  local tilemaps = {
    ground = u16List(c:lz("cable_car.o:sGround_Tilemap")),
    trees = u16List(c:lz("cable_car.o:sTrees_Tilemap")),
    bgMountains = u16List(c:lz("cable_car.o:sBgMountains_Tilemap")),
    pylonTop = u16List(c:raw("cable_car.o:sPylonTop_Tilemap")),
    pylonPole = u16List(c:lz("cable_car.o:sPylonPole_Tilemap")),
  }

  -- pokeemerald/src/cable_car.c:140
  local carPal = c:pal("gCableCar_Pal", 16)
  local sprites = {
    car = c:strip("cable_car", c:lz("gCableCar_Gfx"), 64, 64, 1, carPal),
    door = c:strip("door", c:lz("gCableCarDoor_Gfx"), 16, 8, 1, carPal),
    cable = c:strip("cable", c:lz("gCableCarCable_Gfx"), 16, 16, 1, carPal),
  }

  -- pokeemerald/src/cable_car.c:194
  local tplOff = c:off("sSpriteTemplates_CableCar")
  for key, off in pairs({ car = tplOff, door = tplOff + 24, cable = c:off("sSpriteTemplate_Cable") }) do
    local oam = c:readOam(c:ptr(off + 4))
    sprites[key].priority, sprites[key].affineMode, sprites[key].objMode = oam.priority, oam.affineMode, oam.objMode
    sprites[key].paletteTag = c:u16(off + 2)
  end

  -- pokeemerald/src/field_weather.c:152
  local fogPal = c:pal("gFogPalette", 16)
  -- pokeemerald/src/field_weather_effect.c:28
  sprites.ash = c:strip("ash", c:raw("gWeatherAshTiles"), 64, 64, 2, fogPal)

  return true, c:finish({
    screen = "cable_car",
    bgTiles = c:path("bg_tiles.4bpp"),
    bgTileCount = math.floor(#bgTiles / 32),
    tilemaps = tilemaps,
    sprites = sprites,
    palettes = {
      bg = K.palList(bgPal, 0, 64),
      car = K.palList(carPal, 0, 16),
      fog = K.palList(fogPal, 0, 16),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
