local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/move_relearner"
M.FILES = { "hearts.png" }
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/src/move_relearner.c:149
M.HEARTS = { "appealEmpty", "appealFull", "jamEmpty", "jamFull" }
-- pokeemerald/src/move_relearner.c:286
local FIRST_HEART_TILE = 8

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  -- pokeemerald/src/move_relearner.c:188
  local tiles = c:raw("move_relearner.o:sUI_Tiles")
  local pal = c:pal("move_relearner.o:sUI_Pal", 16)
  local hearts = c:strip("hearts", tiles, 8, 8, #M.HEARTS, pal, 4, FIRST_HEART_TILE)
  local frames = {}
  for i, name in ipairs(M.HEARTS) do frames[name] = i - 1 end
  hearts.names = frames
  return true, c:finish({
    screen = "move_relearner",
    hearts = hearts,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
