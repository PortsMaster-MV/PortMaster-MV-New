local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "title"

M.LAYERS = { "logo", "rayquaza", "clouds" }
M.SPRITES = { "version_banner_left", "version_banner_right", "press_start", "logo_shine" }

M.FILES = {}
for _, k in ipairs(M.LAYERS) do
  M.FILES[#M.FILES + 1] = k .. ".png"
  M.FILES[#M.FILES + 1] = k .. "_idx.png"
end
M.FILES[#M.FILES + 1] = "rayquaza_marking.png"
for _, k in ipairs(M.SPRITES) do M.FILES[#M.FILES + 1] = k .. ".png" end

M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/src/title_screen.c:867
M.MARKING_BANK, M.MARKING_INDEX = 14, 15

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/title_screen.c:601
  local bgPal = c:pal("gTitleScreenBgPalettes")

  -- pokeemerald/src/title_screen.c:599
  local logoIdx, lw, lh = K.bakeAffine(c:lz("gTitleScreenPokemonLogoGfx"), c:lz("gTitleScreenPokemonLogoTilemap"), 32)
  local layers = {}
  layers.logo = c:layer({ key = "logo", indexMap = true }, logoIdx, lw, lh, bgPal)
  layers.logo.bg, layers.logo.priority, layers.logo.affine, layers.logo.bpp = 2, 1, true, 8

  -- pokeemerald/src/title_screen.c:603
  local rayIdx, rw, rh = K.bakeText(c:lz("title_screen.o:sTitleScreenRayquazaGfx"), c:lz("title_screen.o:sTitleScreenRayquazaTilemap"), 32, 32)
  layers.rayquaza = c:layer({ key = "rayquaza", opaque = true, indexMap = true }, rayIdx, rw, rh, bgPal)
  layers.rayquaza.bg, layers.rayquaza.priority = 0, 3
  local markIndex = M.MARKING_BANK * 16 + M.MARKING_INDEX
  layers.rayquaza.marking = c:mask("rayquaza_marking.png", rw, rh, rayIdx, { [markIndex] = true })
  layers.rayquaza.markingIndex = markIndex

  -- pokeemerald/src/title_screen.c:606
  local cloudIdx, cw, ch = K.bakeText(c:lz("title_screen.o:sTitleScreenCloudsGfx"), c:lz("gTitleScreenCloudsTilemap"), 32, 32)
  layers.clouds = c:layer({ key = "clouds", indexMap = true }, cloudIdx, cw, ch, bgPal)
  layers.clouds.bg, layers.clouds.priority = 1, 2

  -- pokeemerald/src/title_screen.c:613
  local versionPal = c:pal("gTitleScreenEmeraldVersionPal")
  local pressPal = c:pal("gTitleScreenPressStartPal")
  local objPal = {}
  for i = 0, 15 do objPal[i] = versionPal[i] end
  for i = 0, 15 do objPal[144 + i] = pressPal[i] end

  local bannerGfx = c:lz("gTitleScreenEmeraldVersionGfx")
  local sprites = {}
  sprites.version_banner_left = c:spriteFrames("version_banner_left", bannerGfx,
    c:readTemplate("title_screen.o:sVersionBannerLeftSpriteTemplate"), objPal)
  sprites.version_banner_right = c:spriteFrames("version_banner_right", bannerGfx,
    c:readTemplate("title_screen.o:sVersionBannerRightSpriteTemplate"), objPal)
  sprites.press_start = c:spriteFrames("press_start", c:lz("gTitleScreenPressStartGfx"),
    c:readTemplate("title_screen.o:sStartCopyrightBannerSpriteTemplate"), pressPal)
  sprites.logo_shine = c:spriteFrames("logo_shine", c:lz("title_screen.o:sTitleScreenLogoShineGfx"),
    c:readTemplate("title_screen.o:sPokemonLogoShineSpriteTemplate"), pressPal)

  -- pokeemerald/src/title_screen.c:72
  local blendOff = c:off("gTitleScreenAlphaBlend")
  local alphaBlend = {}
  for i = 0, c.S.size("gTitleScreenAlphaBlend") / 2 - 1 do
    local v = c:u16(blendOff + i * 2)
    alphaBlend[i + 1] = { v % 32, math.floor(v / 256) % 32 }
  end

  return true, c:finish({
    screen = "title",
    layers = layers,
    sprites = sprites,
    backdrop = bgPal[0],
    palettes = {
      bg = K.palList(bgPal, 0, 240),
      version = K.palList(versionPal, 0, 16),
      pressStart = K.palList(pressPal, 0, 16),
      -- pokeemerald/src/main_menu.c:577
      mainMenuBg = K.palList(c:pal("main_menu.o:sMainMenuBgPal"), 0, 16),
      mainMenuText = K.palList(c:pal("main_menu.o:sMainMenuTextPal"), 0, 16),
    },
    alphaBlend = alphaBlend,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
