local K = require("src.import.gba.rse.boot_gfx")
local Versions = require("src.import.gba.versions")
local M = { SUB = "intro/rs" }
local I = "intro.o:"

-- pokeruby/src/intro.c:946
M.TEXT_LAYERS = {
  { key = "copyright", gfx = "gIntroCopyright_Gfx", map = "gIntroCopyright_Tilemap", pal = "gIntroCopyright_Pal", raw = 0x500, h = 32 },
  { key = "scene1_bg0", gfx = I .. "gIntro1BGLeavesGfx", map = I .. "gIntro1BG0_Tilemap", pal = I .. "gIntro1BGPals", h = 64 },
  { key = "scene1_bg1", gfx = I .. "gIntro1BGLeavesGfx", map = I .. "gIntro1BG1_Tilemap", pal = I .. "gIntro1BGPals", h = 64 },
  { key = "scene1_bg2", gfx = I .. "gIntro1BGLeavesGfx", map = I .. "gIntro1BG2_Tilemap", pal = I .. "gIntro1BGPals", h = 64 },
  { key = "scene1_bg3", gfx = I .. "gIntro1BGLeavesGfx", map = I .. "gIntro1BG3_Tilemap", pal = I .. "gIntro1BGPals", h = 64 },
  { key = "battle_streaks", gfx = I .. "gIntro3Streaks_Gfx", map = I .. "gIntro3Streaks_Tilemap", pal = I .. "gIntro3Streaks_Pal", h = 32 },
}
-- pokeruby/src/intro.c:133
M.SPRITES = {
  { "water_drop", "gSpriteTemplate_840AE20", "gIntroTiles", "Palette_406340" },
  { "gf_letters", "gSpriteTemplate_840AF94", "gIntroTiles", "Palette_406360" },
  { "gf_small_letters", "gSpriteTemplate_840AFAC", "gIntroTiles", "Palette_406360" },
  { "gf_logo", "gSpriteTemplate_840AFC4", "gIntroTiles", "Palette_406360" },
  { "eon_silhouette", "gSpriteTemplate_840AFF0", "gIntro1EonTiles", "gIntro1EonPalette" },
  { "battle_ball", "gSpriteTemplate_840B084", "gInterfaceGfx_PokeBall", "gInterfacePal_PokeBall", global = true, compressedPal = true },
  { "battle_ball_particle", "gSpriteTemplate_840B0B0", "gIntro3MiscTiles", "gIntro3Misc1Palette" },
  { "battle_dust", "gSpriteTemplate_840B0DC", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "battle_dust_burst", "gSpriteTemplate_840B0F4", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "sharpedo_wave", "gSpriteTemplate_840B124", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "duskull_smoke", "gSpriteTemplate_840B150", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "attack_smoke", "gSpriteTemplate_840B170", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "torchic_fire", "gSpriteTemplate_840B1B0", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "mudkip_water", "gSpriteTemplate_840B1C8", "gIntro3MiscTiles", "gIntro3Misc2Palette" },
  { "battle_blast", "gSpriteTemplate_840B1F4", "gIntro3MiscTiles", "gIntro3Misc1Palette" },
}
-- intro.c:1596
M.MONS = {
  { "sharpedo_front", 331, "front" }, { "duskull_front", 361, "front" },
  { "torchic_front", 280, "front" }, { "mudkip_front", 283, "front" },
  { "torchic_back", 280, "back" }, { "mudkip_back", 283, "back" },
}
M.FILES = { "pokeball.png", "pokeball_idx.png", "water_drop_ripple.png", "trainer_brendan.png", "trainer_may.png" }
for _, name in ipairs({ "battle_floor", "battle_bars" }) do
  M.FILES[#M.FILES + 1] = name .. ".png"; M.FILES[#M.FILES + 1] = name .. "_idx.png"
end
for _, s in ipairs(M.MONS) do M.FILES[#M.FILES + 1] = s[1] .. ".png" end
for _, l in ipairs(M.TEXT_LAYERS) do
  M.FILES[#M.FILES + 1] = l.key .. ".png"; M.FILES[#M.FILES + 1] = l.key .. "_idx.png"
end
for _, s in ipairs(M.SPRITES) do M.FILES[#M.FILES + 1] = s[1] .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)

local function rows(c, sym, columns, bytes)
  local out, off = {}, c:off(sym)
  for i = 0, c.S.size(sym) / (columns * bytes) - 1 do
    local row = {}
    for j = 0, columns - 1 do row[j + 1] = bytes == 1 and c:u8(off + i * columns + j) or c:s16(off + (i * columns + j) * 2) end
    out[#out + 1] = row
  end
  return out
end

function M.run(rom, cache, opts)
  local game = rom.id
  assert(game == "ruby" or game == "sapphire", "RS intro needs a native RS ROM")
  local c = K.contextWith(rom, cache, opts or {}, M.SUB, Versions.SYMS, game)
  local layers, sprites, palettes = {}, {}, {}
  local function pal(sym, compressed)
    if not palettes[sym] then
      local n = compressed and 16 or c.S.size(sym) / 2
      local p = c:pal(sym, n, nil, nil, compressed)
      palettes[sym] = K.palList(p, 0, n)
    end
    local p = {}; for i, color in ipairs(palettes[sym]) do p[i - 1] = color end
    return p
  end
  for _, l in ipairs(M.TEXT_LAYERS) do
    local p = pal(l.pal)
    local map = l.raw and c:raw(l.map, l.raw) or c:lz(l.map)
    local idx, w, h = K.bakeText(c:lz(l.gfx), map, 32, l.h)
    layers[l.key] = c:layer({ key = l.key, indexMap = true }, idx, w, h, p)
  end
  local p = pal(I .. "gIntro3PokeballPal")
  local idx, w, h = K.bakeAffine(c:lz(I .. "gIntro3Pokeball_Gfx"), c:lz(I .. "gIntro3Pokeball_Tilemap"), 32)
  layers.pokeball = c:layer({ key = "pokeball", indexMap = true }, idx, w, h, p)
  layers.pokeball.affine, layers.pokeball.bpp = true, 8
  -- intro.c:1215
  local backdropPal = { [240] = 0x7FFF, [241] = 0x31DF, [242] = 0 }
  for _, key in ipairs({ "battle_floor", "battle_bars" }) do
    local pixels = {}
    for y = 0, 255 do for x = 0, 255 do
      local value = 240
      if y < 160 then value = key == "battle_floor" and 241 or (y < 32 or y >= 128) and 242 or 240 end
      pixels[y * 256 + x + 1] = value
    end end
    layers[key] = c:layer({ key = key, indexMap = true }, pixels, 256, 256, backdropPal)
  end
  for _, s in ipairs(M.SPRITES) do
    local gfx, palette = (s.global and "" or I) .. s[3], (s.global and "" or I) .. s[4]
    local tpl = c:readTemplate(I .. s[2])
    local entry = c:spriteFrames(s[1], c:lz(gfx), tpl, pal(palette, s.compressedPal))
    entry.tileTag, entry.paletteTag, entry.shape, entry.size = tpl.tileTag, tpl.paletteTag, tpl.oam.shape, tpl.oam.size
    sprites[s[1]] = entry
  end
  -- pokeruby/src/intro.c:1816
  sprites.water_drop_ripple = c:strip("water_drop_ripple", c:lz(I .. "gIntroTiles"), 64, 32, 1, pal(I .. "Palette_406340"), 4, 48)
  -- pokeruby/src/intro.c:1614
  local trainerAnims = c:readAnimTable(c:off(I .. "gUnknown_0840B064"), c.S.size(I .. "gUnknown_0840B064") / 4, "intro.o")
  for _, anim in ipairs(trainerAnims) do for _, cmd in ipairs(anim) do if cmd.op == "frame" then cmd.frame = cmd.tile end end end
  for i, name in ipairs({ "brendan", "may" }) do
    local picture = assert(c:ptr(c:off("gTrainerBackPicTable") + (i - 1) * 8))
    local palette = c:palFrom(c:lzAt(assert(c:ptr(c:off("gTrainerBackPicPaletteTable") + (i - 1) * 8))), 16)
    local gfx = c:lzAt(picture)
    assert(#gfx == 0x2000, "RS intro trainer needs four native 64x64 images")
    local entry = c:strip("trainer_" .. name, gfx, 64, 64, 4, palette)
    entry.anims = trainerAnims; sprites["trainer_" .. name] = entry
    palettes["trainer_" .. name] = K.palList(palette, 0, 16)
  end
  local monAnims = c:readAnimTable(c:off("gSpriteAnimTable_81E7C64"), 4)
  for _, anim in ipairs(monAnims) do for _, cmd in ipairs(anim) do if cmd.op == "frame" then cmd.frame = cmd.tile end end end
  for _, spec in ipairs(M.MONS) do
    local name, species, side = spec[1], spec[2], spec[3]
    local tableName = side == "front" and "gMonFrontPicTable" or "gMonBackPicTable"
    local picture = assert(c:ptr(c:off(tableName) + species * 8))
    local gfx = c:lzAt(picture)
    assert(#gfx == 0x800, "RS intro mon needs one native 64x64 image")
    local palette = c:palFrom(c:lzAt(assert(c:ptr(c:off("gMonPaletteTable") + species * 8))), 16)
    local entry = c:strip(name, gfx, 64, 64, 1, palette)
    entry.anims, entry.species, entry.side, entry.priority = monAnims, species, side, 1
    sprites[name] = entry; palettes[name] = K.palList(palette, 0, 16)
  end
  return true, c:finish({ screen = "intro", layout = "rs", build = Versions.BUILD, layers = layers, sprites = sprites, palettes = palettes,
    tables = { gameFreakLetters = rows(c, I .. "gUnknown_0840AF50", 2, 2), gameFreakSmallLetters = rows(c, I .. "gUnknown_0840AF74", 2, 2),
      smokeAngles = rows(c, I .. "gUnknown_0840B168", 1, 1), smokeScales = rows(c, I .. "gUnknown_0840B188", 1, 2) },
    scenery = (opts and opts.cacheRoot or "data/generated/gba") .. "/intro/rs/scenery/manifest.lua" })
end
function M.ready(cache, cacheRoot)
  if not K.ready(M.SUB, cache, cacheRoot) then return false end
  local body = cache:read((cacheRoot or "data/generated/gba") .. "/" .. M.SUB .. "/manifest.lua")
  return type(body) == "string" and body:find('layout = "rs"', 1, true) ~= nil
end
return M
