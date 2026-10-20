local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = { SUB = "birch" }
M.FILES = { "birch.png", "brendan.png", "may.png", "azurill.png", "bg_idx.png" }
for i = 0, 8 do M.FILES[#M.FILES + 1] = "bg_" .. i .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/main_menu.c:752
  local base = c:pal("main_menu.o:gUnknown_081E764C", 32)
  local gradient = c:pal("main_menu.o:gUnknown_081E795C", 16)
  local variants = {}
  for s = 0, 8 do
    local p = {}; for i = 0, 31 do p[i] = base[i] end
    for i = 0, 7 do p[i + 1] = gradient[s + i] end
    variants[#variants + 1] = { name = tostring(s), pal = p }
  end
  local idx, w, h = K.bakeText(c:lz("gBirchIntroShadowGfx"), c:lz("main_menu.o:gUnknown_081E7834"), 32, 20)
  local bg = c:layer({key = "bg", opaque = true, indexMap = true, variants = variants}, idx, w, h)
  bg.bg, bg.priority, bg.initialState, bg.backdrop = 1, 3, 8, base[0]
  local pics = { birch = c:strip("birch", c:raw("gSpriteImage_839DC14"), 64, 64, 1, c:pal("gBirchPalette", 16)) }
  -- pokeruby/src/main_menu.c:1452
  for id, key in ipairs({"brendan", "may"}) do
    local gfx = c:lzAt(c:ptr(c:off("gTrainerFrontPicTable") + (id - 1) * 8))
    local p = c:palFrom(c:lzAt(c:ptr(c:off("gTrainerFrontPicPaletteTable") + (id - 1) * 8)), 16)
    pics[key] = c:strip(key, gfx, 64, 64, #gfx / 0x800, p)
    pics[key].trainerPic = id - 1
  end
  local sp = require("src.core.game3.constants").of(rom.id):require("species", "SPECIES_AZURILL")
  local gfx = c:lzAt(c:ptr(c:off("gMonFrontPicTable") + sp * 8))
  pics.azurill = c:strip("azurill", gfx, 64, 64, #gfx / 0x800, c:palFrom(c:lzAt(c:ptr(c:off("gMonPaletteTable") + sp * 8)), 16))
  pics.azurill.species = sp
  local names = {male = {}, female = {}}
  -- pokeruby/src/main_menu.c:153
  for key, sym in pairs({male = "gMalePresetNames", female = "gFemalePresetNames"}) do
    for i = 0, c.S.count(sym, 8) - 1 do names[key][i + 1] = A.text(c, c:ptr(c:off(sym) + i * 8)) end
  end
  return A.finish(c, {screen = "birch", layers = {bg = bg}, pics = pics, presetNames = names,
    palettes = {bg = K.palList(base, 0, 32), gradient = K.palList(gradient, 0, 16), gradientSlot = 1, gradientColors = 8},
    mainMenuPalette = K.palList(c:pal("gMainMenuPalette", 16), 0, 16)})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
