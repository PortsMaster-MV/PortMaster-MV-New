local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local IR = require("src.core.game3.scripting.text_ir")
local M = {SUB = "rse/diploma", FILES = {"hoenn.png", "national.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function textIR(c, name)
  local o, bytes = c:off(name), {}
  for i = 0, 1023 do
    local b = c:u8(o + i)
    bytes[#bytes + 1] = b
    if b == 255 then return IR.decode(bytes, {dialect = "rs"}), bytes end
  end
  error("RS diploma text is unterminated: " .. name)
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/diploma.c:22
  local gfx, map = c:lz("diploma.o:gDiplomaTiles"), c:lz("diploma.o:gDiplomaTilemap")
  assert(#map == 4096 and #gfx % 32 == 0, "invalid native RS diploma BG")
  local pal = c:pal("diploma.o:gDiplomaPalettes", 32)
  local pixels, w = K.bakeText(gfx, map, 64, 32)
  local man = {screen = "diploma", width = 240, height = 160, layers = {},
    bgPalette = K.palList(pal, 0, 32), textPalette = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16),
    bg = {number = 3, priority = 3, charBase = 0, screenBase = 6, width = 512, height = 256},
    printX = 48, printY = 16, linePitch = 16}
  for _, row in ipairs({{"hoenn", 0}, {"national", 256}}) do
    local idx = {}
    for y = 0, 159 do
      for x = 0, 239 do idx[#idx + 1] = pixels[y * w + row[2] + x + 1] end
    end
    man.layers[row[1]] = {png = c:png(row[1] .. ".png", 240, 160, idx, pal, false), xOffset = row[2]}
  end
  local o, bytes = c:off("gMenuTextWindowTemplate"), {}
  for i = 0, 27 do bytes[i + 1] = c:u8(o + i) end
  man.window = {nativeBytes = bytes, paletteNum = bytes[5], foreground = bytes[6],
    background = bytes[7], shadow = bytes[8], font = bytes[9], textMode = bytes[10], spacing = bytes[11]}
  man.text, man.textBytes = textIR(c, "gOtherText_DiplomaCertificationGameFreak")
  man.hoenn = A.text(c, c:off("gOtherText_HoennDex"))
  man.national = A.text(c, c:off("gOtherText_NationalDex"))
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
