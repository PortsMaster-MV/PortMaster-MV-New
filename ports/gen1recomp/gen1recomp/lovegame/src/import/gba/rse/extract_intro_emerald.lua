local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "intro/rse"

local I = "intro.o:"

-- pokeemerald/src/intro.c:1178
M.TEXT_LAYERS = {
  { key = "copyright", gfx = "gIntroCopyright_Gfx", map = "gIntroCopyright_Tilemap", pal = "gIntroCopyright_Pal",
    w = 32, h = 32, bg = 0, priority = 0, opaque = true },
  { key = "scene1_bg0", gfx = I .. "sIntro1Bg_Gfx", map = I .. "sIntro1Bg0_Tilemap", pal = I .. "sIntro1Bg_Pal",
    w = 32, h = 64, bg = 0, priority = 0, vofs = 40 },
  { key = "scene1_bg1", gfx = I .. "sIntro1Bg_Gfx", map = I .. "sIntro1Bg1_Tilemap", pal = I .. "sIntro1Bg_Pal",
    w = 32, h = 64, bg = 1, priority = 1, vofs = 24 },
  { key = "scene1_bg2", gfx = I .. "sIntro1Bg_Gfx", map = I .. "sIntro1Bg2_Tilemap", pal = I .. "sIntro1Bg_Pal",
    w = 32, h = 64, bg = 2, priority = 2, vofs = 80 },
  { key = "scene1_bg3", gfx = I .. "sIntro1Bg_Gfx", map = I .. "sIntro1Bg3_Tilemap", pal = I .. "sIntro1Bg_Pal",
    w = 32, h = 64, bg = 3, priority = 3, vofs = 0, opaque = true },
  -- pokeemerald/src/intro.c:1779
  { key = "scene3_groudon_bg", gfx = "gIntroLegendBg_Gfx", map = "gIntroGroudonBg_Tilemap", pal = "gIntro3Bg_Pal",
    w = 32, h = 32, bg = 1, priority = 1, opaque = true },
  -- pokeemerald/src/intro.c:2057
  { key = "scene3_kyogre_bg", gfx = "gIntroLegendBg_Gfx", map = "gIntroKyogreBg_Tilemap", pal = "gIntro3Bg_Pal",
    w = 32, h = 32, bg = 1, priority = 1, opaque = true },
  -- pokeemerald/src/intro.c:2365
  { key = "scene3_clouds_left", gfx = "gIntroClouds_Gfx", map = "gIntroCloudsLeft_Tilemap", pal = "gIntro3Bg_Pal",
    w = 64, h = 32, bg = 0, priority = 0, hofs = 80 },
  { key = "scene3_clouds_right", gfx = "gIntroClouds_Gfx", map = "gIntroCloudsRight_Tilemap", pal = "gIntro3Bg_Pal",
    w = 64, h = 32, bg = 1, priority = 0, hofs = -80 },
  { key = "scene3_clouds_sun", gfx = "gIntroClouds_Gfx", map = "gIntroCloudsSun_Tilemap", pal = "gIntro3Bg_Pal",
    w = 32, h = 32, bg = 2, priority = 2, opaque = true },
  -- pokeemerald/src/intro.c:2432
  { key = "scene3_rayquaza", gfx = "gIntroRayquaza_Gfx", map = "gIntroRayquaza_Tilemap", pal = "gIntro3Bg_Pal",
    w = 32, h = 32, bg = 2, priority = 2, opaque = true },
  { key = "scene3_rayquaza_clouds", gfx = "gIntroRayquazaClouds_Gfx", map = "gIntroRayquazaClouds_Tilemap", pal = "gIntro3Bg_Pal",
    w = 32, h = 32, bg = 0, priority = 0 },
}

-- pokeemerald/src/intro.c:1724
M.AFFINE_LAYERS = {
  { key = "scene3_pokeball", gfx = I .. "sIntroPokeball_Gfx", map = I .. "sIntroPokeball_Tilemap", pal = I .. "sIntroPokeball_Pal",
    size = 32, bg = 2, priority = 3 },
  { key = "scene3_groudon", gfx = "gIntroGroudon_Gfx", map = "gIntroGroudon_Tilemap", pal = "gIntro3Bg_Pal",
    size = 64, bg = 2, priority = 0, wrap = true },
  { key = "scene3_kyogre", gfx = "gIntroKyogre_Gfx", map = "gIntroKyogre_Tilemap", pal = "gIntro3Bg_Pal",
    size = 64, bg = 2, priority = 0, wrap = true },
}

M.SPRITES = {
  -- pokeemerald/src/intro.c:970
  { key = "water_drop", template = I .. "sSpriteTemplate_WaterDrop", gfx = I .. "sIntroDropsLogo_Gfx", pal = I .. "sIntroDrops_Pal" },
  { key = "gf_letter", template = I .. "sSpriteTemplate_GameFreakLetter", gfx = I .. "sIntroDropsLogo_Gfx", pal = I .. "sIntroLogo_Pal" },
  { key = "gf_logo", template = I .. "sSpriteTemplate_GameFreakLogo", gfx = I .. "sIntroDropsLogo_Gfx", pal = I .. "sIntroLogo_Pal" },
  { key = "flygon_silhouette", template = I .. "sSpriteTemplate_FlygonSilhouette", gfx = "gIntroFlygonSilhouette_Gfx",
    pal = I .. "sIntroFlygonSilhouette_Pal" },
  -- pokeemerald/src/intro.c:210
  { key = "sparkle", template = I .. "sSpriteTemplate_Sparkle", gfx = "gIntroSparkle_Gfx", pal = "gIntroLightning_Pal" },
  -- pokeemerald/src/intro.c:274
  { key = "volbeat", template = I .. "sSpriteTemplate_Volbeat", gfx = "gIntroVolbeat_Gfx", pal = "gIntroVolbeat_Pal" },
  { key = "torchic", template = I .. "sSpriteTemplate_Torchic", gfx = "gIntroTorchic_Gfx", pal = "gIntroTorchic_Pal" },
  { key = "manectric", template = I .. "sSpriteTemplate_Manectric", gfx = "gIntroManectric_Gfx", pal = "gIntroManectric_Pal" },
  -- pokeemerald/src/intro.c:422
  { key = "lightning", template = I .. "sSpriteTemplate_Lightning", gfx = "gIntroLightning_Gfx", pal = "gIntroLightning_Pal" },
  { key = "bubbles", template = I .. "sSpriteTemplate_Bubbles", gfx = "gIntroBubbles_Gfx", pal = "gIntroBubbles_Pal" },
  { key = "rayquaza_orb", template = I .. "sSpriteTemplate_RayquazaOrb", gfx = I .. "sIntroMisc_Gfx", pal = I .. "sIntroRayquzaOrb_Pal" },
}

M.FILES = {}
for _, l in ipairs(M.TEXT_LAYERS) do
  M.FILES[#M.FILES + 1] = l.key .. ".png"
  M.FILES[#M.FILES + 1] = l.key .. "_idx.png"
end
for _, l in ipairs(M.AFFINE_LAYERS) do
  M.FILES[#M.FILES + 1] = l.key .. ".png"
  M.FILES[#M.FILES + 1] = l.key .. "_idx.png"
end
for _, s in ipairs(M.SPRITES) do M.FILES[#M.FILES + 1] = s.key .. ".png" end

M.REQUIRED = K.required(M.SUB, M.FILES)

local function palCount(c, sym)
  return math.floor(c.S.size(sym) / 2)
end

local function s16Rows(c, sym, cols)
  local off, rows = c:off(sym), {}
  for i = 0, c.S.size(sym) / (2 * cols) - 1 do
    local row = {}
    for j = 0, cols - 1 do row[j + 1] = c:s16(off + (i * cols + j) * 2) end
    rows[i + 1] = row
  end
  return rows
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local layers, sprites, palettes = {}, {}, {}

  for _, l in ipairs(M.TEXT_LAYERS) do
    local pal = c:pal(l.pal, palCount(c, l.pal))
    palettes[l.pal:gsub("^.*:", "")] = K.palList(pal, 0, palCount(c, l.pal))
    local idx, W, H = K.bakeText(c:lz(l.gfx), c:lz(l.map), l.w, l.h)
    local e = c:layer({ key = l.key, opaque = l.opaque, indexMap = true }, idx, W, H, pal)
    e.bg, e.priority, e.hofs, e.vofs, e.backdrop = l.bg, l.priority, l.hofs, l.vofs, pal[0]
    layers[l.key] = e
  end

  for _, l in ipairs(M.AFFINE_LAYERS) do
    local pal = c:pal(l.pal, palCount(c, l.pal))
    palettes[l.pal:gsub("^.*:", "")] = K.palList(pal, 0, palCount(c, l.pal))
    local idx, W, H = K.bakeAffine(c:lz(l.gfx), c:lz(l.map), l.size)
    local e = c:layer({ key = l.key, indexMap = true }, idx, W, H, pal)
    e.bg, e.priority, e.affine, e.bpp, e.wrap, e.backdrop = l.bg, l.priority, true, 8, l.wrap, pal[0]
    layers[l.key] = e
  end

  for _, s in ipairs(M.SPRITES) do
    local pal = c:pal(s.pal, 16)
    palettes[s.pal:gsub("^.*:", "")] = K.palList(pal, 0, 16)
    sprites[s.key] = c:spriteFrames(s.key, c:lz(s.gfx), c:readTemplate(s.template), pal)
  end

  -- pokeemerald/src/intro.c:259
  local sparkles = {}
  local so = c:off(I .. "sSparkleCoords")
  for i = 0, c.S.size(I .. "sSparkleCoords") / 2 - 1 do
    local x, y = c:u8(so + i * 2), c:u8(so + i * 2 + 1)
    if x == 0 and y == 0 then break end
    sparkles[#sparkles + 1] = { x, y }
  end

  -- pokeemerald/src/intro.c:880
  local moveSpeed, startDelay = {}, {}
  local mo, dl = c:off(I .. "sGameFreakLettersMoveSpeed"), c:off(I .. "sGameFreakLetterStartDelays")
  for i = 0, c.S.size(I .. "sGameFreakLetterStartDelays") - 1 do
    moveSpeed[i + 1] = c:u16(mo + i * 2)
    startDelay[i + 1] = c:u8(dl + i)
  end

  local fade = c:pal("gIntroGameFreakTextFade_Pal", palCount(c, "gIntroGameFreakTextFade_Pal"))

  return true, c:finish({
    screen = "intro",
    layers = layers,
    sprites = sprites,
    palettes = palettes,
    gameFreakTextFade = K.palList(fade, 0, palCount(c, "gIntroGameFreakTextFade_Pal")),
    tables = {
      sparkleCoords = sparkles,
      gameFreakLetters = s16Rows(c, I .. "sGameFreakLetterData", 2),
      gameFreakLetterMoveSpeed = moveSpeed,
      gameFreakLetterStartDelay = startDelay,
      groudonRocks = s16Rows(c, I .. "sGroudonRockData", 3),
      kyogreBubbles = s16Rows(c, I .. "sKyogreBubbleData", 3),
    },
    -- pokeemerald/src/intro.c:1783
    groudonRocks = { animTag = "ANIM_TAG_ROCKS", template = "gAncientPowerRockSpriteTemplate" },
    scenery = (opts and opts.cacheRoot or "data/generated/gba") .. "/intro/rse/scenery/manifest.lua",
    alphaBlend = (opts and opts.cacheRoot or "data/generated/gba") .. "/title/manifest.lua",
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
