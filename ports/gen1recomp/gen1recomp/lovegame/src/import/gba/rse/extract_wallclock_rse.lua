local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "wallclock"

local W = "wallclock.o:"

M.GENDERS = { { "male", "gWallClockMale_Pal" }, { "female", "gWallClockFemale_Pal" } }
M.LAYERS = { { "start", "gWallClockStart_Tilemap" }, { "view", "gWallClockView_Tilemap" } }
-- pokeemerald/src/wallclock.c:183
M.SPRITES = {
  { "minute_hand", W .. "sSpriteTemplate_MinuteHand" },
  { "hour_hand", W .. "sSpriteTemplate_HourHand" },
  { "pm", W .. "sSpriteTemplate_PM" },
  { "am", W .. "sSpriteTemplate_AM" },
}

M.FILES = {}
for _, l in ipairs(M.LAYERS) do
  for _, g in ipairs(M.GENDERS) do M.FILES[#M.FILES + 1] = l[1] .. "_" .. g[1] .. ".png" end
  M.FILES[#M.FILES + 1] = l[1] .. "_idx.png"
end
for _, s in ipairs(M.SPRITES) do
  for _, g in ipairs(M.GENDERS) do M.FILES[#M.FILES + 1] = s[1] .. "_" .. g[1] .. ".png" end
end

M.REQUIRED = K.required(M.SUB, M.FILES)

local function windows(c, sym)
  local off, out = c:off(sym), {}
  for i = 0, c.S.size(sym) / 8 - 1 do
    local o = off + i * 8
    if c:u8(o) == 0xFF then break end
    out[#out + 1] = {
      bg = c:u8(o), tilemapLeft = c:u8(o + 1), tilemapTop = c:u8(o + 2), width = c:u8(o + 3),
      height = c:u8(o + 4), paletteNum = c:u8(o + 5), baseBlock = c:u16(o + 6),
    }
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  local genderPals, variants, palettes = {}, {}, {}
  for i, g in ipairs(M.GENDERS) do
    genderPals[i] = c:pal(g[2], 16)
    variants[i] = { name = g[1], pal = genderPals[i] }
    palettes[g[1]] = K.palList(genderPals[i], 0, 16)
  end

  -- pokeemerald/src/wallclock.c:647
  local gfx = c:lz("gWallClock_Gfx")
  local layers = {}
  for _, l in ipairs(M.LAYERS) do
    local idx, LW, LH = K.bakeText(gfx, c:lz(l[2]), 32, 20)
    local e = c:layer({ key = l[1], opaque = true, indexMap = true, variants = variants }, idx, LW, LH)
    e.bg, e.priority = 3, 2
    layers[l[1]] = e
  end

  -- pokeemerald/src/wallclock.c:667
  local handGfx = c:lz(W .. "sHand_Gfx")
  local sprites = {}
  for _, s in ipairs(M.SPRITES) do
    sprites[s[1]] = c:spriteFrames(s[1], handGfx, c:readTemplate(s[2]), K.variants(variants))
  end

  -- pokeemerald/src/wallclock.c:257
  local coords, co = {}, c:off(W .. "sClockHandCoords")
  for i = 0, c.S.size(W .. "sClockHandCoords") / 2 - 1 do
    coords[i + 1] = { c:s8(co + i * 2), c:s8(co + i * 2 + 1) }
  end

  palettes.textPrompt = K.palList(c:pal(W .. "sTextPrompt_Pal", 4), 0, 4)

  return true, c:finish({
    screen = "wallclock",
    layers = layers,
    sprites = sprites,
    palettes = palettes,
    handCoords = coords,
    windows = windows(c, W .. "sWindowTemplates"),
    confirmWindow = windows(c, W .. "sWindowTemplate_ConfirmYesNo")[1],
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
