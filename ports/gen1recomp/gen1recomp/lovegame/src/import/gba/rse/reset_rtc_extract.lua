local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "reset_rtc"

local O = "reset_rtc_screen.o:"

M.FILES = { "arrow.png" }
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/reset_rtc_screen.c:179
  local gfx = c:raw(O .. "sArrowDown_Gfx") .. c:raw(O .. "sArrowRight_Gfx")
  local pal = c:pal(O .. "sArrow_Pal", 4)

  -- pokeemerald/src/reset_rtc_screen.c:225
  local tpl = c:readTemplate(O .. "sSpriteTemplate_Arrow")
  local arrow = c:spriteFrames("arrow", gfx, tpl, pal)

  return true, c:finish({
    screen = "reset_rtc",
    sprites = { arrow = arrow },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
