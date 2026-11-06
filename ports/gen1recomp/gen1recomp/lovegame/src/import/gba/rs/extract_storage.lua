local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "pokemon/storage", VERSION = 5}
M.WALLPAPERS = {"forest", "city", "desert", "savanna", "crag", "volcano", "snow", "cave",
  "beach", "seafloor", "river", "sky", "polkadot", "pokecenter", "machine", "plain"}
M.FILES = {"header.png", "party_drawer.png", "button_party.png", "button_close.png", "scrolling_bg.png",
  "cursor.png", "cursor_alt.png", "cursor_shadow.png", "box_scroll_arrow.png", "waveform.png", "box_popup_center.png", "box_popup_sides.png", "pc_screen_bar.png"}
for _, wp in ipairs(M.WALLPAPERS) do M.FILES[#M.FILES + 1] = "wallpapers/" .. wp .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function relativeMap(raw, tileBase, paletteBase)
  local out = {}
  for i = 1, #raw, 2 do
    local lo, hi = raw:byte(i, i + 1)
    local e = lo + hi * 256
    local tile, flags, bank = e % 1024, math.floor(e / 1024) % 4, math.floor(e / 4096)
    local v = 0
    if tile >= tileBase and bank >= paletteBase then
      v = tile - tileBase + flags * 1024 + (bank - paletteBase) * 4096
    end
    out[#out + 1] = string.char(v % 256, math.floor(v / 256))
  end
  return table.concat(out)
end
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local manifest = {version = M.VERSION, screen = "storage", layers = {}, sprites = {}, wallpapers = {}, wallpaperOrder = M.WALLPAPERS,
    wallpaperMetadata = {}, textures = {}, palettes = {}, coverage = "native_backgrounds_wallpapers_and_sprites"}
  local bgpal = {}
  for i, name in ipairs({"gPSSMenu2_Pal", "gPSSMenu1_Pal", "gPSSMenu3_Pal", "gPSSMenu4_Pal"}) do
    c:pal(name, 16, bgpal, (i - 1) * 16)
  end
  local function layer(key, gfx, map, w, h, tileBase, bankBase, pal, crop)
    local idx, width, height = K.bakeText(gfx, relativeMap(map, tileBase, bankBase), w, h, {linear = true, mapWidth = 32})
    if crop then idx = K.crop(idx, width, crop[1], crop[2], crop[3], crop[4]); width, height = crop[3], crop[4] end
    local entry = c:layer({key = key}, idx, width, height, pal)
    manifest.layers[key], manifest.textures[key] = entry, key .. ".png"
  end
  -- pokeruby/src/pokemon_storage_system_2.c:1442
  layer("header", c:lz("gPSSMenuHeader_Gfx"), c:lz("gPSSMenuHeader_Tilemap"), 10, 20, 640, 0, bgpal)
  local mg, mm = c:lz("gPSSMenuMisc_Gfx"), c:lz("gPSSMenuMisc_Tilemap")
  layer("party_drawer", mg, mm, 12, 22, 832, 0, bgpal)
  layer("button_party", mg, mm, 12, 22, 832, 0, bgpal, {0, 160, 96, 16})
  layer("button_close", mg, mm, 21, 4, 832, 0, bgpal, {96, 0, 72, 16})
  local sp = c:pal("gPokemonStorageScrollingBGPalette", 8)
  layer("scrolling_bg", c:raw("gPokemonStorageScrollingBGTile"), c:lz("gPokemonStorageScrollingBGTilemap"), 32, 32, 256, 13, sp)
  manifest.palettes.interface = K.palList(bgpal, 0, 64)
  manifest.palettes.scrolling = K.palList(sp, 0, 8)
  manifest.palettes.textColors = K.palList(c:pal("gUnknownPalette_81E6692", 16), 0, 16)
  local wt = c:off("gWallpaperTable")
  assert(c.S.count("gWallpaperTable", 16) == #M.WALLPAPERS, "RS wallpaper count changed")
  for i, name in ipairs(M.WALLPAPERS) do
    local o = wt + (i - 1) * 16
    local g, m, p = assert(c:ptr(o)), assert(c:ptr(o + 8)), assert(c:ptr(o + 12))
    local wp = c:palAt(p, 48)
    local idx, w, h = K.bakeText(c:lzAt(g), c:lzAt(m), 20, 18, {linear = true, mapWidth = 20})
    local file = "wallpapers/" .. name .. ".png"
    c:png(file, w, h, idx, wp, false)
    manifest.wallpapers[name] = file
    manifest.wallpaperMetadata[name] = {w = w, h = h, compressedSize = c:u32(o + 4), palette = K.palList(wp, 0, 48)}
  end
  local hp, ap = c:pal("HandCursorPalette", 16), c:pal("HandCursorAltPalette", 16)
  local function spriteTemplate(name, count)
    if not count then return c:readTemplate(name) end
    local o = c:off(name)
    return {tileTag = c:u16(o), paletteTag = c:u16(o + 2), oam = c:readOam(assert(c:ptr(o + 4))),
      anims = c:readAnimTable(assert(c:ptr(o + 8)), count), callback = c.S.funcAt(c:u32(o + 20))}
  end
  for _, s in ipairs({
    {"cursor", "HandCursorTiles", "gSpriteTemplate_83BBC70", hp, 4},
    {"cursor_alt", "HandCursorTiles", "gSpriteTemplate_83BBC70", ap, 4},
    {"cursor_shadow", "HandCursorShadowTiles", "gSpriteTemplate_83BBC88", hp, 1},
    {"box_scroll_arrow", "PCGfx_Arrow", "gSpriteTemplate_83BB2F0", c:pal("PCPal_Arrow", 16)},
    {"waveform", "WaveformTiles", "gSpriteTemplate_83B6EFC", c:pal("WaveformPalette", 16)},
  }) do
    manifest.sprites[s[1]] = c:spriteFrames(s[1], c:raw(s[2]), spriteTemplate(s[3], s[5]), s[4])
    manifest.textures[s[1]] = s[1] .. ".png"
  end
  -- pokeruby/src/pc_screen_effect.c:14
  local O = "pc_screen_effect.o:"
  local function nativeSource(name)
    local key = O .. name
    local size, off = c.S.size(key), c:off(key)
    assert(c.S.sizeKind(key) == "elf" and size > 0, "RS PC effect requires native ELF size: " .. name)
    local raw, bytes = c:raw(key, size), {}
    assert(#raw == size, "RS PC effect truncated native symbol: " .. name)
    for i = 1, size do bytes[i] = raw:byte(i) end
    return raw, {symbol = key, romOffset = off, size = size, sizeKind = "elf", bytes = bytes}
  end
  local barGfx, gfxSource = nativeSource("gUnknownGfx_083D190C")
  local barPalRaw, palSource = nativeSource("gUnknownPal_083D18EC")
  local _, oamSource = nativeSource("gOamData_83D18D8")
  local _, animTableSource = nativeSource("gSpriteAnimTable_83D18E8")
  local _, animSource = nativeSource("gSpriteAnim_83D18E0")
  assert(palSource.size == 32 and oamSource.size == 8 and animTableSource.size == 4 and animSource.size == 8,
    "RS PC effect native palette/OAM/animation dimensions changed")
  local oam = c:readOam(oamSource.romOffset)
  assert(oam.w == 32 and oam.h == 8 and oam.bpp == 4, "RS PC effect native bar OAM changed")
  local frameBytes = oam.w * oam.h * oam.bpp / 8
  assert(gfxSource.size >= frameBytes, "RS PC effect native sheet cannot supply bar frame")
  assert(c:ptr(animTableSource.romOffset) == animSource.romOffset, "RS PC effect animation pointer changed")
  local anims = c:readAnimTable(animTableSource.romOffset, 1)
  assert(#anims == 1 and #anims[1] == 2 and anims[1][1].op == "frame" and anims[1][1].tile == 0
    and anims[1][1].duration == 5 and anims[1][2].op == "end", "RS PC effect native bar animation changed")
  local barPal = c:palFrom(barPalRaw, 16)
  local bar = c:spriteFrames("pc_screen_bar", barGfx, {oam = oam, anims = anims}, barPal)
  bar.oam, bar.palette = oam, K.palList(barPal, 0, 16)
  bar.frameBytes, bar.tileTag, bar.paletteTag = frameBytes, 14, 0xDAD0
  manifest.sprites.pc_screen_bar, manifest.textures.pc_screen_bar = bar, "pc_screen_bar.png"
  manifest.palettes.pcScreenEffect = bar.palette
  -- _2.c:418
  local openingBars, closingBars = {}, {}
  for i = 0, 7 do
    local target = 32 * i + 8
    openingBars[i + 1] = {x = target, y = 80, dx = i < 4 and -16 or 16}
    closingBars[i + 1] = {x = i < 4 and i * 32 - 112 or i * 32 + 128, y = 80,
      dx = i < 4 and 16 or -16, targetX = target}
  end
  manifest.pcScreenEffect = {bar = bar, bars = 8, centerY = 80, speed = 16, heightStep = 20,
    tileTag = 14, paletteTag = 0xDAD0, openingHalfHeight = 1, closingHalfHeight = 80,
    exitLeft = -8, exitRight = 248, visibleLeft = -16, visibleRight = 256,
    openingBars = openingBars, closingBars = closingBars,
    openingCallback = "sub_80C60CC", closingCallback = "sub_80C6130",
    source = {file = "src/pc_screen_effect.c", caller = "src/pokemon_storage_system_2.c:418-419",
      gfx = gfxSource, palette = palSource, oam = oamSource, animTable = animTableSource, anim = animSource}}
  local pp = c:pal("gBoxSelectionPopupPalette", 16)
  manifest.sprites.box_popup_center = c:strip("box_popup_center", c:raw("gBoxSelectionPopupCenterTiles"), 64, 64, 1, pp)
  manifest.sprites.box_popup_sides = c:atlas("box_popup_sides", c:raw("gBoxSelectionPopupSidesTiles"), {
    {tile = 0, w = 8, h = 32}, {tile = 4, w = 8, h = 16},
    {tile = 6, w = 8, h = 32}, {tile = 10, w = 8, h = 16},
  }, pp)
  manifest.boxPopup = {center = {x = 160, y = 96}, sides = {{x = 124, y = 80, frame = 0},
    {x = 124, y = 112, frame = 1}, {x = 196, y = 80, frame = 2}, {x = 196, y = 112, frame = 3}}}
  manifest.geometry = {headerX = 0, headerY = 0, wallpaperX = 80, wallpaperY = 16, wallpaperW = 160, wallpaperH = 144,
    partyDrawerX = 80, partyDrawerY = 0, closeX = 168, closeY = 0, partyButtonX = 80, partyButtonY = 0,
    boxColumns = 6, boxRows = 5, iconSpacingX = 24, iconSpacingY = 24}
  manifest.menuText = {}
  local tx = c:off("gUnknown_083BBCA0")
  for i = 0, 31 do manifest.menuText[i + 1] = A.text(c, assert(c:ptr(tx + i * 4))) end
  return A.finish(c, manifest)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  local body = cache:read(base .. "manifest.lua")
  if tonumber(body:match("\n%s*version = (%d+),")) ~= M.VERSION or not body:find("pcScreenEffect = {", 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(base .. file) then return false end end
  return true
end
return M
