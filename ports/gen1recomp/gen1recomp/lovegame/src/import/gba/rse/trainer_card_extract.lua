local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/trainer_card"

-- pokeemerald/src/trainer_card.c:265
M.STAR_PALS = {
  [0] = "gHoennTrainerCardGreen_Pal", "sHoennTrainerCardBronze_Pal", "sHoennTrainerCardCopper_Pal",
  "sHoennTrainerCardSilver_Pal", "sHoennTrainerCardGold_Pal",
}

M.FILES = { "badges.png", "star.png" }
for stars = 0, 4 do
  for _, side in ipairs({ "screen", "front", "back" }) do
    M.FILES[#M.FILES + 1] = string.format("%s_%d.png", side, stars)
    M.FILES[#M.FILES + 1] = string.format("%s_%d_female.png", side, stars)
  end
end

M.REQUIRED = K.required(M.SUB, M.FILES)

local function mapString(entries)
  local out = {}
  for i, e in ipairs(entries) do out[i] = string.char(e % 256, math.floor(e / 256)) end
  return table.concat(out)
end

local function context(rom, cache, opts)
  opts = opts or {}
  local Versions = require("src.import.gba.versions")
  local okV, V = pcall(Versions.forGame, opts.game or rom.id)
  if not okV then V = Versions end
  if type(V.HOENN_CARD) ~= "table" then return K.context(rom, cache, opts, M.SUB), V end
  local map = Versions.HOENN_CARD
  local function row(name) return assert(map[name], "hoenn card: no offset for " .. name) end
  local S = {
    off = function(name) return row(name)[1] end,
    size = function(name) return row(name)[2] end,
  }
  return K.contextWith(rom, cache, opts, M.SUB, S, Versions.active()), Versions
end

local function pics(c, Versions)
  local classes = Versions.HOENN_CARD_PIC_CLASSES
  local base = Versions.FACILITY_CLASS_TO_PIC_INDEX
  return { male = c:u8(base + classes.male), female = c:u8(base + classes.female) }
end

function M.run(rom, cache, opts)
  local c, Versions = context(rom, cache, opts)
  -- pokeemerald/src/trainer_card.c:532
  local gfx = c:lz("gHoennTrainerCard_Gfx")
  local maps = {
    screen = c:lz("gHoennTrainerCardBg_Tilemap"),
    front = c:lz("gHoennTrainerCardFront_Tilemap"),
    back = c:lz("gHoennTrainerCardBack_Tilemap"),
  }
  local layers = {}
  for stars = 0, 4 do
    -- pokeemerald/src/trainer_card.c:1434
    local pal = c:pal(M.STAR_PALS[stars], 48)
    local fem = {}
    for i = 0, 47 do fem[i] = pal[i] end
    c:pal("sHoennTrainerCardFemaleBg_Pal", 16, fem, 16)
    for side, map in pairs(maps) do
      local idx, W, H = K.bakeText(gfx, map, 30, 20, { linear = true, mapWidth = 30 })
      local key = string.format("%s_%d", side, stars)
      layers[key] = c:layer({ key = key, opaque = side == "screen", variants = {
        { name = "", pal = pal }, { name = "female", pal = fem },
      } }, idx, W, H, pal)
    end
  end

  -- pokeemerald/src/trainer_card.c:1507
  local badgeGfx = c:lz("sHoennTrainerCardBadges_Gfx")
  local badgePal = c:pal("sHoennTrainerCardBadges_Pal", 16)
  local entries = {}
  for row = 0, 1 do
    for col = 0, 15 do entries[#entries + 1] = row * 16 + col end
  end
  local bIdx, BW, BH = K.bakeText(badgeGfx, mapString(entries), 16, 2, { linear = true, mapWidth = 16 })
  c:png("badges.png", BW, BH, bIdx, badgePal, true)

  local starPal = c:pal("sTrainerCardStar_Pal", 16)
  local sIdx, SW, SH = K.bakeText(gfx, mapString({ 143 }), 1, 1, { linear = true, mapWidth = 1 })
  c:png("star.png", SW, SH, sIdx, starPal, true)

  return true, c:finish({
    screen = "trainer_card",
    cardType = "emerald",
    layers = layers,
    badges = { png = c:path("badges.png"), w = BW, h = BH },
    star = { png = c:path("star.png"), w = SW, h = SH },
    -- pokeemerald/src/trainer_card.c:287
    picOffset = { 1, 0 },
    pics = pics(c, Versions),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
