local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "battle_transition_rse"

M.FILES = {}

M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/src/battle_transition.c:333
local SQUARE_TILESETS = {
  { "filled", "sFrontierSquares_FilledBg_Tileset" },
  { "empty", "sFrontierSquares_EmptyBg_Tileset" },
  { "shrink1", "sFrontierSquares_Shrink1_Tileset" },
  { "shrink2", "sFrontierSquares_Shrink2_Tileset" },
}

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/battle_transition.c:4455
  local blank = {}
  for _, row in ipairs(SQUARE_TILESETS) do
    blank[row[1]] = K.bakeSprite(c:lz(row[2]), 8, 8, 1, 4)
  end

  -- pokeemerald/src/battle_transition_frontier.c:56
  local oam = c:readOam(c:off("sOamData_LogoCircles"))
  local anims = c:readAnimTable(c:off("sAnimTable_LogoCircles"), c.S.size("sAnimTable_LogoCircles") / 4,
    "battle_transition_frontier.o")
  local tilesPerFrame = (oam.w / 8) * (oam.h / 8)
  local frames = {}
  for i, anim in ipairs(anims) do
    local first = anim[1]
    if not (first and first.op == "frame") then error("extract_transition_b3: logo circle anim " .. i .. " has no frame") end
    frames[i] = math.floor(first.tile / tilesPerFrame)
  end

  return true, c:finish({
    screen = "battle_transition_rse",
    squaresBlankTile = blank,
    logoCircles = { w = oam.w, h = oam.h, priority = oam.priority, frames = frames },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
