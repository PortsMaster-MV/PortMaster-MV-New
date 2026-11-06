local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Shared = require("src.import.gba.rse.roulette_extract")
local M = { SUB = "rse_roulette" }

local SYMBOLS = {
  sGridSelections = "roulette.o:gUnknown_083F8C00",
  sRouletteSlots = "roulette.o:gUnknown_083F8D90",
  sRouletteTables = "roulette.o:gUnknown_083F8DF4",
  sTableMinBets = "roulette.o:gUnknown_083F8DF0",
  sFlashData_Colors = "roulette.o:gUnknown_083F8E34",
  sFlashData_PokeIcons = "roulette.o:gUnknown_083F8E9C",
  sShroomishShadowAlphas = "roulette_gfx.o:gUnknown_083FA61E",
  sFanfares = "sound.o:sFanfares",
  sWheel_Pal = "roulette.o:gUnknown_083F86BC",
  gRouletteMenu_Gfx = "gUnknown_08E8096C",
  sGrid_Tilemap = "roulette.o:gUnknown_083F88BC",
  gRouletteWheel_Gfx = "gRouletteWheelTiles",
  sWheel_Tilemap = "roulette.o:gUnknown_083F8A60",
  ["roulette.o:sSpritePalettes"] = "roulette_gfx.o:gUnknown_083F9E30",
  sSpriteTemplate_Ball = "roulette_gfx.o:gSpriteTemplate_83FA40C",
  sBall_Gfx = "roulette_gfx.o:gUnknown_083F90FC",
  sSpriteTemplate_WheelCenter = "roulette_gfx.o:gSpriteTemplate_83FA434",
  sSpriteTemplates_WheelIcons = "roulette_gfx.o:gSpriteTemplate_83FA0DC",
  sWheelIcons_Gfx = "roulette_gfx.o:RoulettePokeIcons2Tiles",
  gRouletteHeaders_Gfx = "gRouletteHeadersTiles",
  sSpriteTemplates_PokeHeaders = "roulette_gfx.o:gSpriteTemplate_83F9FD4",
  sSpriteTemplates_ColorHeaders = "roulette_gfx.o:gSpriteTemplate_83FA034",
  sSpriteTemplates_GridIcons = "roulette_gfx.o:gSpriteTemplate_83FA07C",
  sGridIcons_Gfx = "roulette_gfx.o:RoulettePokeIconsTiles",
  sSpriteTemplate_Credit = "roulette_gfx.o:gSpriteTemplate_83FA2B0",
  gRouletteCredit_Gfx = "gRouletteCreditTiles",
  sSpriteTemplate_CreditDigit = "roulette_gfx.o:gSpriteTemplate_83FA2C8",
  gRouletteNumbers_Gfx = "gRouletteNumbersTiles",
  sSpriteTemplate_Multiplier = "roulette_gfx.o:gSpriteTemplate_83FA2E0",
  gRouletteMultiplier_Gfx = "gRouletteMultiplierTiles",
  sSpriteTemplate_BallCounter = "roulette_gfx.o:gSpriteTemplate_83FA2F8",
  sBallCounter_Gfx = "roulette_gfx.o:RouletteBallCounterTiles",
  ["roulette.o:sSpriteTemplate_Cursor"] = "roulette_gfx.o:gSpriteTemplate_83FA310",
  ["roulette.o:sCursor_Gfx"] = "roulette_gfx.o:RouletteCursorTiles",
  sShroomishTaillow_Gfx = "roulette_gfx.o:gUnknown_083F92A8",
  sSpriteTemplate_Shroomish = "roulette_gfx.o:gSpriteTemplate_83FA50C",
  sSpriteTemplate_Taillow = "roulette_gfx.o:gSpriteTemplate_83FA524",
  sShadow_Gfx = "roulette_gfx.o:gUnknown_083F9D3C",
  sSpriteTemplate_ShroomishShadow = "roulette_gfx.o:gSpriteTemplate_83FA5C0",
  sSpriteTemplate_TaillowShadow = "roulette_gfx.o:gSpriteTemplate_83FA5F0",
}
M.SYMBOLS = SYMBOLS
M.FILES = { "menu_tiles.4bpp", "wheel_idx.png", "ball.png", "center.png", "wheel_icons.png", "headers.png", "grid_icons.png",
  "credit.png", "credit_digit.png", "multiplier.png", "ball_counter.png", "cursor.png", "shroomish_taillow.png",
  "ball_shadow.png", "mon_shadow.png", "taillow_shadow.png" }
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local native = c.S
  local function key(name) return SYMBOLS[name] or name end
  require("src.import.gba.rs.scoped_symbols").bind(c, SYMBOLS)
  for name, size in pairs({ sGridSelections = 400, sRouletteSlots = 96, sRouletteTables = 64,
    sTableMinBets = 4, sFlashData_Colors = 104, sFlashData_PokeIcons = 24, sShroomishShadowAlphas = 20,
    sSpriteTemplates_WheelIcons = 288, sSpriteTemplates_PokeHeaders = 96, sSpriteTemplates_ColorHeaders = 72,
    sSpriteTemplates_GridIcons = 96 }) do
    assert(c.S.size(name) == size, "RS roulette native table size: " .. key(name))
  end
  local finish = c.finish
  c.finish = function(self, data)
    data.assetLayout, data.layout = "rs", "rs"
    data.build = require("src.import.gba.versions").BUILD
    data.rouletteVersion = 1
    data.text = { instruction = "gUnknown_081C4157", quit = "gUnknown_081C41E3",
      win = "gUnknown_081C41A5", lose = "gUnknown_081C4199", landed = "gUnknown_081C41AE",
      wonCoins = "gUnknown_081C41BD", another = "gUnknown_081C41D2", maxCoins = "gUnknown_081C41F1",
      outOfCoins = "gUnknown_081C4231", minBet = "gUnknown_081C40DF", insufficient = "gUnknown_081C411C",
      specialRate = "gUnknown_081C4139" }
    data.textBytes = {}
    for label, symbol in pairs(data.text) do
      local bytes, off = {}, native.off(symbol)
      for i = 0, 1023 do local b = self:u8(off + i); bytes[#bytes + 1] = b; if b == 255 then break end end
      assert(bytes[#bytes] == 255, "RS roulette unterminated " .. symbol)
      data.textBytes[label] = bytes
    end
    data.window = { font = 3, textMode = 2, fg = 1, bg = 15, shadow = 8, paletteNum = 15 }
    data.geometry = { message = { x = 8, y = 120 }, yesNo = { left = 20, top = 8 }, setupStates = 8 }
    data.loadedPaletteColors = 224
    return finish(self, data)
  end
  return Shared.runContext(c)
end

function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local prefix = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  local body = cache:read(prefix .. "manifest.lua")
  if not body:find("rouletteVersion = 1", 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(prefix .. file) then return false end end
  return true
end
return M
