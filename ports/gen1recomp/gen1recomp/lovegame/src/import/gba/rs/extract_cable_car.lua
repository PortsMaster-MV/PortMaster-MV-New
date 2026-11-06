local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "cable_car", FILES = {"bg_tiles.4bpp", "cable_car.png", "door.png", "cable.png", "ash.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function words(bytes)
  assert(#bytes % 2 == 0, "RS cable-car tilemap has an incomplete word")
  local out = {}
  for i = 1, #bytes, 2 do out[#out + 1] = bytes:byte(i) + bytes:byte(i + 1) * 256 end
  return out
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/cable_car.c:127
  local gfx = c:lz("gCableCarBG_Gfx")
  c:write("bg_tiles.4bpp", gfx)
  local bgPal, carPal = c:pal("gCableCarBG_Pal", 64), c:pal("gCableCar_Pal", 16)
  local maps = {
    ground = words(c:lz("cable_car.o:gCableCarMtChimneyTilemap")),
    trees = words(c:lz("cable_car.o:gCableCarTreeTilemap")),
    bgMountains = words(c:lz("cable_car.o:gCableCarMountainTilemap")),
    pylonTop = words(c:raw("cable_car.o:gCableCarPylonHookTilemapEntries")),
    pylonPole = words(c:lz("cable_car.o:gCableCarPylonStemTilemap")),
  }
  local sprites = {
    car = c:strip("cable_car", c:lz("gCableCar_Gfx"), 64, 64, 1, carPal),
    door = c:strip("door", c:lz("gCableCarDoor_Gfx"), 16, 8, 1, carPal),
    cable = c:strip("cable", c:lz("gCableCarCord_Gfx"), 16, 16, 1, carPal),
  }
  -- pokeruby/src/cable_car.c:184
  local template = c:off("cable_car.o:gSpriteTemplate_8401D40")
  for i, key in ipairs({"car", "door", "cable"}) do
    local off = template + (i - 1) * 24
    local oam = c:readOam(c:ptr(off + 4))
    local s = sprites[key]
    s.priority, s.affineMode, s.objMode = oam.priority, oam.affineMode, oam.objMode
    s.tileTag, s.paletteTag = c:u16(off), c:u16(off + 2)
  end
  -- field_weather.c:257
  local fogPal = c:pal("gUnknown_083970E8", 16)
  sprites.ash = c:strip("ash", c:raw("gWeatherAshTiles"), 64, 64, 2, fogPal)
  return A.finish(c, {screen = "cable_car", bgTiles = c:path("bg_tiles.4bpp"),
    bgTileCount = #gfx / 32, tilemaps = maps, sprites = sprites,
    palettes = {bg = K.palList(bgPal, 0, 64), car = K.palList(carPal, 0, 16), fog = K.palList(fogPal, 0, 16)}})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
