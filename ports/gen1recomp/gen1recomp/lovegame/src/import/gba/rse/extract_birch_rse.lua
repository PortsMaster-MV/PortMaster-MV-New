local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "birch"

local MM = "main_menu.o:"

-- pokeemerald/src/main_menu.c:2031
M.GRADIENT_STATES = 9
M.GRADIENT_SLOT, M.GRADIENT_COLORS = 1, 8

M.PICS = { "birch", "brendan", "may", "lotad" }

M.FILES = {}
for i = 0, M.GRADIENT_STATES - 1 do M.FILES[#M.FILES + 1] = "bg_" .. i .. ".png" end
M.FILES[#M.FILES + 1] = "bg_idx.png"
for _, k in ipairs(M.PICS) do M.FILES[#M.FILES + 1] = k .. ".png" end

M.REQUIRED = K.required(M.SUB, M.FILES)

local PIC = 0x800

local function trainerPic(c, C, facilityName)
  local facility = C:require("trainer_classes", facilityName)
  local picIndex = c:u8(c:off("gFacilityClassToPicIndex") + facility)
  local sheet = c:off("gTrainerFrontPicTable") + picIndex * 8
  local palRow = c:off("gTrainerFrontPicPaletteTable") + picIndex * 8
  return c:lzAt(c:ptr(sheet)), c:palFrom(c:lzAt(c:ptr(palRow)), 16), picIndex
end

local function monPic(c, C, speciesName)
  local species = C:require("species", speciesName)
  local sheet = c:off("gMonFrontPicTable") + species * 8
  local palRow = c:off("gMonPaletteTable") + species * 8
  return c:lzAt(c:ptr(sheet)), c:palFrom(c:lzAt(c:ptr(palRow)), 16), species
end

local function decodeName(c, ptrOff)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local off = c:ptr(ptrOff)
  local bytes = {}
  for i = 0, 15 do
    local b = c:u8(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toAscii(TextIR.decode(bytes, { dialect = "rse" }))
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local C = require("src.core.game3.constants").of(c.game)

  -- pokeemerald/src/main_menu.c:1278
  local basePal = c:pal(MM .. "sBirchSpeechBgPals", 32)
  local gradient = c:pal(MM .. "sBirchSpeechBgGradientPal", 16)
  local idx, W, H = K.bakeText(c:lz(MM .. "sBirchSpeechShadowGfx"), c:lz(MM .. "sBirchSpeechBgMap"), 32, 20, { linear = true, mapWidth = 32 })
  local variants = {}
  for s = 0, M.GRADIENT_STATES - 1 do
    local pal = {}
    for i = 0, 31 do pal[i] = basePal[i] end
    for i = 0, M.GRADIENT_COLORS - 1 do pal[M.GRADIENT_SLOT + i] = gradient[s + i] or 0 end
    variants[#variants + 1] = { name = tostring(s), pal = pal }
  end
  local bg = c:layer({ key = "bg", opaque = true, indexMap = true, variants = variants }, idx, W, H)
  bg.bg, bg.priority, bg.backdrop = 1, 3, basePal[0]
  bg.initialState = M.GRADIENT_STATES - 1

  local pics = {}
  -- pokeemerald/src/field_effect.c:909
  local birchPal = c:pal("field_effect.o:sNewGameBirch_Pal", 16)
  pics.birch = c:strip("birch", c:raw("field_effect.o:sNewGameBirch_Gfx"), 64, 64, 1, birchPal)
  pics.birch.palette = K.palList(birchPal, 0, 16)

  -- pokeemerald/src/main_menu.c:1895
  for _, t in ipairs({ { "brendan", "FACILITY_CLASS_BRENDAN" }, { "may", "FACILITY_CLASS_MAY" } }) do
    local gfx, pal, picIndex = trainerPic(c, C, t[2])
    pics[t[1]] = c:strip(t[1], gfx, 64, 64, math.floor(#gfx / PIC), pal)
    pics[t[1]].trainerPic = picIndex
    pics[t[1]].palette = K.palList(pal, 0, 16)
  end

  -- pokeemerald/src/main_menu.c:1873
  local lotadGfx, lotadPal, species = monPic(c, C, "SPECIES_LOTAD")
  pics.lotad = c:strip("lotad", lotadGfx, 64, 64, math.floor(#lotadGfx / PIC), lotadPal)
  pics.lotad.species = species
  pics.lotad.palette = K.palList(lotadPal, 0, 16)

  -- pokeemerald/src/main_menu.c:460
  local names = { male = {}, female = {} }
  for key, sym in pairs({ male = MM .. "sMalePresetNames", female = MM .. "sFemalePresetNames" }) do
    local off = c:off(sym)
    for i = 0, c.S.size(sym) / 4 - 1 do names[key][i + 1] = decodeName(c, off + i * 4) end
  end

  return true, c:finish({
    screen = "birch",
    layers = { bg = bg },
    pics = pics,
    presetNames = names,
    palettes = {
      bg = K.palList(basePal, 0, 32),
      gradient = K.palList(gradient, 0, 16),
      gradientSlot = M.GRADIENT_SLOT,
      gradientColors = M.GRADIENT_COLORS,
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
