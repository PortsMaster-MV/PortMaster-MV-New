local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "intro/rse/scenery"

local OBJ = "intro_credits_graphics.o:"

-- pokeemerald/src/intro_credits_graphics.c:731
M.LAYERS = {
  { key = "grass", gfx = OBJ .. "sGrass_Gfx", map = OBJ .. "sGrass_Tilemap", bg = 1, priority = 1, bank = 15,
    pals = { { "day", OBJ .. "sGrass_Pal" }, { "sunset", OBJ .. "sGrassSunset_Pal" }, { "night", OBJ .. "sGrassNight_Pal" } } },
  { key = "trees_bg3", gfx = OBJ .. "sTrees_Gfx", map = OBJ .. "sTrees_Tilemap", sb = 0, bg = 3, priority = 3, bank = 0, opaque = true,
    pals = { { "day", OBJ .. "sTrees_Pal" }, { "sunset", OBJ .. "sTreesSunset_Pal" } } },
  { key = "trees_bg2", gfx = OBJ .. "sTrees_Gfx", map = OBJ .. "sTrees_Tilemap", sb = 1, bg = 2, priority = 2, bank = 0,
    pals = { { "day", OBJ .. "sTrees_Pal" }, { "sunset", OBJ .. "sTreesSunset_Pal" } } },
  { key = "clouds_bg3", gfx = OBJ .. "sCloudsBg_Gfx", map = OBJ .. "sCloudsBg_Tilemap", sb = 0, bg = 3, priority = 3, bank = 0, opaque = true,
    pals = { { "day", OBJ .. "sCloudsBg_Pal" }, { "sunset", OBJ .. "sCloudsBgSunset_Pal" } } },
  { key = "clouds_bg2", gfx = OBJ .. "sCloudsBg_Gfx", map = OBJ .. "sCloudsBg_Tilemap", sb = 1, bg = 2, priority = 2, bank = 0,
    pals = { { "day", OBJ .. "sCloudsBg_Pal" }, { "sunset", OBJ .. "sCloudsBgSunset_Pal" } } },
  { key = "houses_bg3", gfx = OBJ .. "sHouses_Gfx", map = OBJ .. "sHouses_Tilemap", sb = 0, bg = 3, priority = 3, bank = 0, opaque = true,
    pals = { { "night", OBJ .. "sHouses_Pal" } } },
  { key = "houses_bg2", gfx = OBJ .. "sHouses_Gfx", map = OBJ .. "sHouses_Tilemap", sb = 1, bg = 2, priority = 2, bank = 0,
    pals = { { "night", OBJ .. "sHouses_Pal" } } },
}

-- pokeemerald/src/intro_credits_graphics.c:1064
M.SCENERY = {
  { key = "moving_clouds", gfx = OBJ .. "sClouds_Gfx", anims = OBJ .. "sAnims_Clouds", meta = OBJ .. "sSpriteMetadata_Clouds",
    pals = { { "day", OBJ .. "sClouds_Pal" }, { "sunset", OBJ .. "sCloudsSunset_Pal" } } },
  { key = "moving_trees", gfx = OBJ .. "sTreesSmall_Gfx", anims = OBJ .. "sAnims_Trees", meta = OBJ .. "sSpriteMetadata_Trees",
    pals = { { "day", OBJ .. "sTreesSmall_Pal" }, { "sunset", OBJ .. "sTreesSunset_Pal" } } },
  { key = "moving_houses", gfx = OBJ .. "sHouseSilhouette_Gfx", anims = OBJ .. "sAnims_HouseSilhouette", meta = OBJ .. "sSpriteMetadata_HouseSilhouette",
    pals = { { "night", OBJ .. "sHouseSilhouette_Pal" } } },
}

-- pokeemerald/src/intro_credits_graphics.c:465
M.SPRITES = {
  { key = "brendan", template = OBJ .. "sSpriteTemplate_Brendan", gfx = "gIntroBrendan_Gfx", pal = "gIntroPlayer_Pal" },
  { key = "may", template = OBJ .. "sSpriteTemplate_May", gfx = "gIntroMay_Gfx", pal = "gIntroPlayer_Pal" },
  { key = "bicycle", template = OBJ .. "sSpriteTemplate_BrendanBicycle", gfx = OBJ .. "sBicycle_Gfx", pal = "gIntroPlayer_Pal" },
  { key = "flygon", template = OBJ .. "sSpriteTemplate_FlygonLatias", gfx = "gIntroFlygon_Gfx", pal = "gIntroFlygon_Pal" },
}

-- pokeemerald/src/intro_credits_graphics.c:639
M.CREDITS = {
  { key = "brendan_credits", gfx = OBJ .. "sBrendanCredits_Gfx", pal = OBJ .. "sBrendanCredits_Pal", w = 64, h = 64 },
  { key = "may_credits", gfx = OBJ .. "sMayCredits_Gfx", pal = OBJ .. "sMayCredits_Pal", w = 64, h = 64 },
  { key = "latios", gfx = OBJ .. "sLatios_Gfx", pal = OBJ .. "sLatios_Pal", w = 64, h = 64 },
  { key = "latias", gfx = OBJ .. "sLatias_Gfx", pal = OBJ .. "sLatias_Pal", w = 64, h = 64 },
}

M.META_STRIDE = 8

M.FILES = {}
for _, l in ipairs(M.LAYERS) do
  for _, p in ipairs(l.pals) do M.FILES[#M.FILES + 1] = l.key .. "_" .. p[1] .. ".png" end
  M.FILES[#M.FILES + 1] = l.key .. "_idx.png"
end
for _, s in ipairs(M.SCENERY) do
  for _, p in ipairs(s.pals) do M.FILES[#M.FILES + 1] = s.key .. "_" .. p[1] .. ".png" end
end
for _, s in ipairs(M.SPRITES) do M.FILES[#M.FILES + 1] = s.key .. ".png" end
for _, s in ipairs(M.CREDITS) do M.FILES[#M.FILES + 1] = s.key .. ".png" end

M.REQUIRED = K.required(M.SUB, M.FILES)

local function bankPal(c, sym, bank)
  local pal = {}
  local n = math.floor(c.S.size(sym) / 2)
  c:pal(sym, n, pal, bank * 16)
  return pal
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local layers, palettes = {}, {}

  for _, l in ipairs(M.LAYERS) do
    local idx, W, H = K.bakeText(c:lz(l.gfx), c:lz(l.map), 32, 32, { mapOffset = (l.sb or 0) * 1024 })
    local variants = {}
    for i, p in ipairs(l.pals) do
      variants[i] = { name = p[1], pal = bankPal(c, p[2], l.bank) }
      palettes[p[2]:gsub("^.*:", "")] = K.palList(variants[i].pal, l.bank * 16, math.floor(c.S.size(p[2]) / 2))
    end
    local e = c:layer({ key = l.key, opaque = l.opaque, indexMap = true, variants = variants }, idx, W, H)
    e.bg, e.priority, e.bank = l.bg, l.priority, l.bank
    layers[l.key] = e
  end

  local scenery = {}
  for _, s in ipairs(M.SCENERY) do
    local anims = c:readAnimTable(c:off(s.anims), c.S.size(s.anims) / 4)
    local metaOff, rows = c:off(s.meta), {}
    for i = 0, c.S.size(s.meta) / M.META_STRIDE - 1 do
      local o = metaOff + i * M.META_STRIDE
      local b0 = c:u8(o)
      local shape, size = math.floor(b0 / 16) % 4, math.floor(b0 / 64) % 4
      local w, h = K.objDims(shape, size)
      rows[#rows + 1] = {
        animNum = b0 % 16, shape = shape, size = size, w = w, h = h,
        x = c:u8(o + 1), y = c:u8(o + 2), subpriority = c:u8(o + 3), xOff = c:u16(o + 4),
      }
    end
    local frames = {}
    for a, anim in ipairs(anims) do
      local dims
      for _, r in ipairs(rows) do
        if r.animNum == a - 1 then dims = r break end
      end
      if dims then
        for _, cmd in ipairs(anim) do
          if cmd.op == "frame" then
            frames[#frames + 1] = { tile = cmd.tile, w = dims.w, h = dims.h, anim = a - 1 }
          end
        end
      end
    end
    local variants = {}
    for i, p in ipairs(s.pals) do
      variants[i] = { name = p[1], pal = c:pal(p[2], 16) }
      palettes[p[2]:gsub("^.*:", "")] = K.palList(variants[i].pal, 0, 16)
    end
    local e = c:atlas(s.key, c:lz(s.gfx), frames, K.variants(variants))
    for i, fr in ipairs(frames) do e.rects[i].anim = fr.anim end
    e.anims = anims
    e.sprites = rows
    scenery[s.key] = e
  end

  local sprites = {}
  for _, s in ipairs(M.SPRITES) do
    local pal = c:pal(s.pal, 16)
    palettes[s.pal] = K.palList(pal, 0, 16)
    sprites[s.key] = c:spriteFrames(s.key, c:lz(s.gfx), c:readTemplate(s.template), pal)
  end

  local credits = {}
  for _, s in ipairs(M.CREDITS) do
    local gfx = c:lz(s.gfx)
    local pal = c:pal(s.pal, 16)
    palettes[s.pal:gsub("^.*:", "")] = K.palList(pal, 0, 16)
    credits[s.key] = c:strip(s.key, gfx, s.w, s.h, math.floor(#gfx / (s.w * s.h / 2)), pal)
  end

  return true, c:finish({
    screen = "intro_credits_scenery",
    layers = layers,
    scenery = scenery,
    sprites = sprites,
    credits = credits,
    palettes = palettes,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
