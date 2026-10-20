local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "starter_choose"

local SC = "starter_choose.o:"

M.FILES = { "grass.png", "bag.png", "pokeball.png", "hand.png", "circle.png" }

M.REQUIRED = K.required(M.SUB, M.FILES)

local function window(c, off)
  return {
    bg = c:u8(off), tilemapLeft = c:u8(off + 1), tilemapTop = c:u8(off + 2), width = c:u8(off + 3),
    height = c:u8(off + 4), paletteNum = c:u8(off + 5), baseBlock = c:u16(off + 6),
  }
end

local function coords(c, sym)
  local off, out = c:off(SC .. sym), {}
  for i = 0, c.S.size(SC .. sym) / 2 - 1 do
    out[i + 1] = { c:u8(off + i * 2), c:u8(off + i * 2 + 1) }
  end
  return out
end

-- pokeemerald/include/sprite.h:106
local function affineAnim(c, sym)
  local off, out = c:off(SC .. sym), {}
  for i = 0, c.S.size(SC .. sym) / 8 - 1 do
    local o = off + i * 8
    local x = c:s16(o)
    if x == 0x7FFF then
      out[#out + 1] = { op = "end" }
      break
    end
    out[#out + 1] = { op = "frame", xScale = x, yScale = c:s16(o + 2), rotation = c:s8(o + 4), duration = c:u8(o + 5) }
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/starter_choose.c:400
  local bgPal = c:pal("gBirchBagGrass_Pal", c.S.size("gBirchBagGrass_Pal") / 2)
  local gfx = c:lz("gBirchBagGrass_Gfx")
  local layers = {}
  local grassIdx, GW, GH = K.bakeText(gfx, c:lz("gBirchGrassTilemap"), 32, 20)
  layers.grass = c:layer({ key = "grass", opaque = true }, grassIdx, GW, GH, bgPal)
  layers.grass.bg, layers.grass.priority, layers.grass.backdrop = 2, 3, bgPal[0]
  local bagIdx, BW, BH = K.bakeText(gfx, c:lz("gBirchBagTilemap"), 32, 20)
  layers.bag = c:layer({ key = "bag", opaque = false }, bagIdx, BW, BH, bgPal)
  layers.bag.bg, layers.bag.priority = 3, 1

  -- pokeemerald/src/starter_choose.c:420
  local selGfx = c:lz("gPokeballSelection_Gfx")
  local selPal = c:pal(SC .. "sPokeballSelection_Pal", 16)
  local circlePal = c:pal(SC .. "sStarterCircle_Pal", 16)
  local sprites = {
    pokeball = c:spriteFrames("pokeball", selGfx, c:readTemplate(SC .. "sSpriteTemplate_Pokeball"), selPal),
    hand = c:spriteFrames("hand", selGfx, c:readTemplate(SC .. "sSpriteTemplate_Hand"), selPal),
    circle = c:spriteFrames("circle", c:lz(SC .. "sStarterCircle_Gfx"), c:readTemplate(SC .. "sSpriteTemplate_StarterCircle"), circlePal),
  }

  -- pokeemerald/src/starter_choose.c:113
  local species, so = {}, c:off(SC .. "sStarterMon")
  for i = 0, c.S.size(SC .. "sStarterMon") / 2 - 1 do species[i + 1] = c:u16(so + i * 2) end

  local tc, tco = {}, c:off(SC .. "sTextColors")
  for i = 0, c.S.size(SC .. "sTextColors") - 1 do tc[i + 1] = c:u8(tco + i) end

  return true, c:finish({
    screen = "starter_choose",
    layers = layers,
    sprites = sprites,
    species = species,
    pokeballCoords = coords(c, "sPokeballCoords"),
    cursorCoords = coords(c, "sCursorCoords"),
    labelCoords = coords(c, "sStarterLabelCoords"),
    windows = {
      message = window(c, c:off(SC .. "sWindowTemplates")),
      confirm = window(c, c:off(SC .. "sWindowTemplate_ConfirmStarter")),
      label = window(c, c:off(SC .. "sWindowTemplate_StarterLabel")),
    },
    affine = {
      pokemon = affineAnim(c, "sAffineAnim_StarterPokemon"),
      circle = affineAnim(c, "sAffineAnim_StarterCircle"),
    },
    textColors = tc,
    palettes = {
      bg = K.palList(bgPal, 0, #bgPal + 1),
      selection = K.palList(selPal, 0, 16),
      circle = K.palList(circlePal, 0, 16),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
