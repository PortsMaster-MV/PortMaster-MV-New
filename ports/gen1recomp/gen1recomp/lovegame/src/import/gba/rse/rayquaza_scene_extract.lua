local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rayquaza_scene"

M.LAYERS = {
  "clouds1", "clouds2", "clouds3", "tf_bg", "tf_rayquaza", "de_light", "de_bg", "de_bg_top",
  "ch_orbs", "ch_rayquaza", "ch_streaks", "ch_bg", "ca_light", "ca_bg", "ca_ring",
}

M.SPRITES = {
  { "dfp_groudon", "sSpriteTemplate_DuoFightPre_Groudon", "gRaySceneDuoFight_Groudon_Gfx", "duo_groudon" },
  { "dfp_groudon_shoulder", "sSpriteTemplate_DuoFightPre_GroudonShoulder", "gRaySceneDuoFight_GroudonShoulder_Gfx", "duo_groudon" },
  { "dfp_groudon_claw", "sSpriteTemplate_DuoFightPre_GroudonClaw", "gRaySceneDuoFight_GroudonClaw_Gfx", "duo_groudon" },
  { "dfp_kyogre", "sSpriteTemplate_DuoFightPre_Kyogre", "gRaySceneDuoFight_Kyogre_Gfx", "duo_kyogre" },
  { "dfp_kyogre_pectoral", "sSpriteTemplate_DuoFightPre_KyogrePectoralFin", "gRaySceneDuoFight_KyogrePectoralFin_Gfx", "duo_kyogre" },
  { "dfp_kyogre_dorsal", "sSpriteTemplate_DuoFightPre_KyogreDorsalFin", "gRaySceneDuoFight_KyogreDorsalFin_Gfx", "duo_kyogre" },
  { "df_groudon", "sSpriteTemplate_DuoFight_Groudon", "gRaySceneDuoFight_Groudon_Gfx", "duo_groudon" },
  { "df_groudon_shoulder", "sSpriteTemplate_DuoFight_GroudonShoulder", "gRaySceneDuoFight_GroudonShoulder_Gfx", "duo_groudon" },
  { "df_groudon_claw", "sSpriteTemplate_DuoFight_GroudonClaw", "gRaySceneDuoFight_GroudonClaw_Gfx", "duo_groudon" },
  { "df_kyogre", "sSpriteTemplate_DuoFight_Kyogre", "gRaySceneDuoFight_Kyogre_Gfx", "duo_kyogre" },
  { "df_kyogre_pectoral", "sSpriteTemplate_DuoFight_KyogrePectoralFin", "gRaySceneDuoFight_KyogrePectoralFin_Gfx", "duo_kyogre" },
  { "df_kyogre_dorsal", "sSpriteTemplate_DuoFight_KyogreDorsalFin", "gRaySceneDuoFight_KyogreDorsalFin_Gfx", "duo_kyogre" },
  { "tf_smoke", "sSpriteTemplate_TakesFlight_Smoke", "gRaySceneTakesFlight_Smoke_Gfx", "tf_smoke" },
  { "de_rayquaza", "sSpriteTemplate_Descends_Rayquaza", "gRaySceneDescends_Rayquaza_Gfx", "tf_rayquaza" },
  { "de_rayquaza_tail", "sSpriteTemplate_Descends_RayquazaTail", "gRaySceneDescends_RayquazaTail_Gfx", "tf_rayquaza" },
  { "ca_groudon", "sSpriteTemplate_ChasesAway_Groudon", "gRaySceneChasesAway_Groudon_Gfx", "ca_groudon" },
  { "ca_groudon_tail", "sSpriteTemplate_ChasesAway_GroudonTail", "gRaySceneChasesAway_GroudonTail_Gfx", "ca_groudon" },
  { "ca_kyogre", "sSpriteTemplate_ChasesAway_Kyogre", "gRaySceneChasesAway_Kyogre_Gfx", "ca_kyogre" },
  { "ca_rayquaza", "sSpriteTemplate_ChasesAway_Rayquaza", "gRaySceneChasesAway_Rayquaza_Gfx", "ca_rayquaza" },
  { "ca_rayquaza_tail", "sSpriteTemplate_ChasesAway_RayquazaTail", "gRaySceneChasesAway_RayquazaTail_Gfx", "ca_rayquaza" },
  { "ca_splash", "sSpriteTemplate_ChasesAway_KyogreSplash", "gRaySceneChasesAway_KyogreSplash_Gfx", "ca_splash" },
}

-- pokeemerald/src/rayquaza_scene.c:1587
M.PALETTES = {
  duo_clouds = { "gRaySceneDuoFight_Clouds_Pal", 32 },
  duo_groudon = { "gRaySceneDuoFight_Groudon_Pal", 16 },
  duo_kyogre = { "gRaySceneDuoFight_Kyogre_Pal", 16 },
  tf_rayquaza = { "gRaySceneTakesFlight_Rayquaza_Pal", 32 },
  tf_smoke = { "gRaySceneTakesFlight_Smoke_Pal", 16 },
  de_bg = { "gRaySceneDescends_Bg_Pal", 32 },
  ch_bg = { "gRaySceneCharges_Bg_Pal", 64 },
  ca_bg = { "gRaySceneChasesAway_Bg_Pal", 48 },
  ca_groudon = { "gRaySceneChasesAway_Groudon_Pal", 16 },
  ca_kyogre = { "gRaySceneChasesAway_Kyogre_Pal", 16 },
  ca_rayquaza = { "gRaySceneChasesAway_Rayquaza_Pal", 16 },
  ca_splash = { "gRaySceneChasesAway_KyogreSplash_Pal", 16 },
}

M.FILES = {}
for _, k in ipairs(M.LAYERS) do M.FILES[#M.FILES + 1] = k .. "_idx.png" end
for _, s in ipairs(M.SPRITES) do M.FILES[#M.FILES + 1] = s[1] .. ".png" end

M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/include/sprite.h:117
local function readAffineAnim(c, off)
  local cmds = {}
  for i = 0, 63 do
    local base = off + i * 8
    local t = c:s16(base)
    if t == 0x7FFF then
      cmds[#cmds + 1] = { op = "end" }
      break
    elseif t == 0x7FFE then
      cmds[#cmds + 1] = { op = "jump", target = c:s16(base + 2) }
      break
    elseif t == 0x7FFD then
      cmds[#cmds + 1] = { op = "loop", count = c:s16(base + 2) }
    else
      cmds[#cmds + 1] = {
        op = "frame", xScale = t, yScale = c:s16(base + 2),
        rotation = c:u8(base + 4), duration = c:u8(base + 5),
      }
    end
  end
  return cmds
end

local function readAffineTable(c, sym)
  local off, anims = c:off(sym), {}
  for i = 0, c.S.size(sym) / 4 - 1 do
    local p = c:ptr(off + i * 4)
    if p then anims[#anims + 1] = readAffineAnim(c, p) end
  end
  return anims
end

local function textLayer(c, key, gfx, map)
  local idx, w, h = K.bakeText(gfx, map, 32, 32)
  return { index = c:gray(key .. "_idx.png", w, h, idx), w = w, h = h, bpp = 4 }
end

local function affineLayer(c, key, gfx, map)
  local size = math.floor(math.sqrt(#map) + 0.5)
  local idx, w, h = K.bakeAffine(gfx, map, size)
  return { index = c:gray(key .. "_idx.png", w, h, idx), w = w, h = h, bpp = 8 }
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  local palettes, palTables = {}, {}
  for key, row in pairs(M.PALETTES) do
    local p = c:pal(row[1], row[2], nil, nil, true)
    palTables[key] = p
    palettes[key] = K.palList(p, 0, row[2])
  end

  local layers = {}
  -- pokeemerald/src/rayquaza_scene.c:1587
  local clouds = c:lz("gRaySceneDuoFight_Clouds_Gfx")
  layers.clouds1 = textLayer(c, "clouds1", clouds, c:lz("gRaySceneDuoFight_Clouds1_Tilemap"))
  layers.clouds2 = textLayer(c, "clouds2", clouds, c:lz("gRaySceneDuoFight_Clouds2_Tilemap"))
  layers.clouds3 = textLayer(c, "clouds3", clouds, c:lz("gRaySceneDuoFight_Clouds3_Tilemap"))
  -- pokeemerald/src/rayquaza_scene.c:2025
  layers.tf_bg = textLayer(c, "tf_bg", c:lz("gRaySceneTakesFlight_Bg_Gfx"), c:lz("gRaySceneTakesFlight_Bg_Tilemap"))
  layers.tf_rayquaza = affineLayer(c, "tf_rayquaza", c:lz("gRaySceneTakesFlight_Rayquaza_Gfx"),
    c:lz("gRaySceneTakesFlight_Rayquaza_Tilemap"))
  -- pokeemerald/src/rayquaza_scene.c:2229
  local deBgMap = c:lz("gRaySceneDescends_Bg_Tilemap")
  layers.de_light = textLayer(c, "de_light", c:lz("gRaySceneDescends_Light_Gfx"), c:lz("gRaySceneDescends_Light_Tilemap"))
  local deBgGfx = c:lz("gRaySceneDescends_Bg_Gfx")
  layers.de_bg = textLayer(c, "de_bg", deBgGfx, deBgMap)
  local top = deBgMap:sub(1, 0x100) .. string.rep("\0", 0x340) .. deBgMap:sub(0x100 + 0x340 + 1)
  layers.de_bg_top = textLayer(c, "de_bg_top", deBgGfx, top)
  -- pokeemerald/src/rayquaza_scene.c:2479
  local streaks = c:lz("gRaySceneCharges_Streaks_Gfx")
  layers.ch_orbs = textLayer(c, "ch_orbs", streaks, c:lz("gRaySceneCharges_Orbs_Tilemap"))
  layers.ch_rayquaza = textLayer(c, "ch_rayquaza", c:lz("gRaySceneCharges_Rayquaza_Gfx"),
    c:lz("gRaySceneCharges_Rayquaza_Tilemap"))
  layers.ch_streaks = textLayer(c, "ch_streaks", streaks, c:lz("gRaySceneCharges_Streaks_Tilemap"))
  layers.ch_bg = textLayer(c, "ch_bg", c:lz("gRaySceneCharges_Bg_Gfx"), c:lz("gRaySceneCharges_Bg_Tilemap"))
  -- pokeemerald/src/rayquaza_scene.c:2665
  local light = c:lz("gRaySceneChasesAway_Light_Gfx")
  layers.ca_light = textLayer(c, "ca_light", light, c:lz("gRaySceneChasesAway_Light_Tilemap"))
  layers.ca_bg = textLayer(c, "ca_bg", light, c:lz("gRaySceneChasesAway_Bg_Tilemap"))
  layers.ca_ring = affineLayer(c, "ca_ring", c:lz("gRaySceneChasesAway_Ring_Gfx"), c:lz("gRaySceneChasesAway_Ring_Tilemap"))

  local sprites = {}
  for _, row in ipairs(M.SPRITES) do
    local tpl = c:readTemplate(row[2])
    local e = c:spriteFrames(row[1], c:lz(row[3]), tpl, palTables[row[4]])
    e.paletteTag = tpl.paletteTag
    e.tileTag = tpl.tileTag
    sprites[row[1]] = e
  end
  -- pokeemerald/src/rayquaza_scene.c:822
  sprites.tf_smoke.affineAnims = readAffineTable(c, "sAffineAnims_TakesFlight_Smoke")

  -- pokeemerald/src/rayquaza_scene.c:848
  local smoke, off = {}, c:off("sTakesFlight_SmokeCoords")
  for i = 0, c.S.size("sTakesFlight_SmokeCoords") / 2 - 1 do
    smoke[i + 1] = { c:s8(off + i * 2), c:s8(off + i * 2 + 1) }
  end

  return true, c:finish({
    screen = "rayquaza_scene",
    layers = layers,
    sprites = sprites,
    palettes = palettes,
    smokeCoords = smoke,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
