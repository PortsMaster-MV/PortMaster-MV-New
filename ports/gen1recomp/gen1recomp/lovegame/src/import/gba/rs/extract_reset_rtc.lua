local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = { SUB = "reset_rtc", FILES = { "arrow.png" } }
M.REQUIRED = K.required(M.SUB, M.FILES)
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local O = "reset_rtc_screen.o:"
  local gfx = c:raw(O .. "gSpriteImage_8376464") .. c:raw(O .. "gSpriteImage_8376484")
  assert(#gfx == 64, "RS RTC cursor uses two8x8 tiles")
  local tpl = c:readTemplate(O .. "gSpriteTemplate_83764E8")
  local sprite = c:spriteFrames("arrow", gfx, tpl, c:pal(O .. "Palette_3764A4", 16))
  return A.finish(c, { screen = "reset_rtc", sprites = { arrow = sprite },
    cursorX = { 53, 86, 107, 128, 155 }, arrowY = { up = 68, down = 92, confirm = 80 } })
end
function M.ready(cache, root)
  return A.ready(M.SUB, cache, root) and cache:exists((root or "data/generated/gba") .. "/reset_rtc/arrow.png")
end
return M
