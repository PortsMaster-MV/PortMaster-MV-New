local K = require("src.import.gba.rse.boot_gfx")
local Versions = require("src.import.gba.versions")
local M = { SUB = "title" }
M.FILES = { "logo.png", "logo_idx.png", "legendary.png", "legendary_idx.png",
  "backdrop.png", "backdrop_idx.png", "version_banner_left.png", "version_banner_right.png",
  "press_start.png", "logo_shine.png" }
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeruby/src/title_screen.c:519
function M.run(rom, cache, opts)
  opts = opts or {}
  local game = rom.id
  assert(game == "ruby" or game == "sapphire", "RS title extraction needs a native RS ROM")
  local c = K.contextWith(rom, cache, opts, M.SUB, Versions.SYMS, game)
  local bgPal = c:pal("gUnknown_08E9F624", 224)
  c:pal("title_screen.o:sLegendaryMonPalettes", 32, bgPal, 224)
  local logoIdx, lw, lh = K.bakeAffine(c:lz("gUnknown_08E9D8CC"), c:lz("gUnknown_08E9F7E4"), 32)
  local monGfx = c:lz("title_screen.o:sLegendaryMonPixelData")
  local monIdx, mw, mh = K.bakeText(monGfx, c:lz("title_screen.o:sLegendaryMonTilemap"), 32, 32)
  local bgIdx, bw, bh = K.bakeText(monGfx, c:lz("title_screen.o:sBackdropTilemap"), 32, 32)
  local layers = {
    logo = c:layer({ key = "logo", indexMap = true }, logoIdx, lw, lh, bgPal),
    legendary = c:layer({ key = "legendary", indexMap = true }, monIdx, mw, mh, bgPal),
    backdrop = c:layer({ key = "backdrop", indexMap = true }, bgIdx, bw, bh, bgPal),
  }
  layers.logo.bg, layers.logo.priority, layers.logo.affine, layers.logo.bpp = 2, 1, true, 8
  layers.legendary.bg, layers.legendary.priority = 0, 3
  layers.backdrop.bg, layers.backdrop.priority = 1, 2
  local versionPal = c:pal("gUnknown_08E9F624", 224)
  local pressPal = c:pal("gTitleScreenLogoShinePalette", 16)
  local bannerGfx = c:lz("gVersionTiles")
  local sprites = {
    version_banner_left = c:spriteFrames("version_banner_left", bannerGfx,
      c:readTemplate("title_screen.o:sVersionBannerLeftSpriteTemplate"), versionPal),
    version_banner_right = c:spriteFrames("version_banner_right", bannerGfx,
      c:readTemplate("title_screen.o:sVersionBannerRightSpriteTemplate"), versionPal),
    press_start = c:spriteFrames("press_start", c:lz("gTitleScreenPressStart_Gfx"),
      c:readTemplate("title_screen.o:sStartCopyrightBannerSpriteTemplate"), pressPal),
    logo_shine = c:spriteFrames("logo_shine", c:lz("title_screen.o:sLogoShineTiles"),
      c:readTemplate("title_screen.o:sPokemonLogoShineSpriteTemplate"), pressPal),
  }
  local alphaBlend = {}
  local alphaOff = c:off("gUnknown_08393E64")
  for i = 0, c.S.count("gUnknown_08393E64", 2) - 1 do
    local value = c:u16(alphaOff + i * 2)
    alphaBlend[#alphaBlend + 1] = { value % 32, math.floor(value / 256) % 32 }
  end
  return true, c:finish({
    screen = "title", layout = "rs", build = Versions.BUILD, layers = layers, sprites = sprites,
    legendary = game == "sapphire" and "kyogre" or "groudon",
    logoFlashPaletteIndex = game == "sapphire" and 26 or 21,
    alphaBlend = alphaBlend, palettes = {
      bg = K.palList(bgPal, 0, 256), version = K.palList(versionPal, 0, 224),
      pressStart = K.palList(pressPal, 0, 16),
    },
  })
end

function M.ready(cache, cacheRoot)
  if not K.ready(M.SUB, cache, cacheRoot) then return false end
  local body = cache:read((cacheRoot or "data/generated/gba") .. "/title/manifest.lua")
  return type(body) == "string" and body:find('layout = "rs"', 1, true) ~= nil
end
return M
