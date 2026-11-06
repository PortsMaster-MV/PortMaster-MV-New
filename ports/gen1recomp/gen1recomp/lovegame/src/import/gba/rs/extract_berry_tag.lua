local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local IR = require("src.core.game3.scripting.text_ir")
local M = {SUB = "rse/berry_tag", FILES = {"body.png", "title.png", "bg_male.png", "bg_female.png", "circle.png"}}
for i = 1, 43 do M.FILES[#M.FILES + 1] = "berry_" .. i .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local function text(off)
    local bytes = {}
    for i = 0, 1023 do
      local b = c:u8(off + i); bytes[#bytes + 1] = b
      if b == 255 then
        return IR.toAscii(IR.decode(bytes, {dialect = "rs"}),
          {stringVars = {"{STR_VAR_1}", "{STR_VAR_2}", "{STR_VAR_3}"}})
      end
    end
    error("native RS berry-tag text is unterminated")
  end
  local gfx, pal = c:lz("gBerryCheck_Gfx"), c:pal("gBerryCheck_Pal", 96, nil, nil, true)
  local man = {screen = "berry_tag", layers = {}, berries = {}, strings = {}, firmness = {},
    firstItem = 133, lastItem = 175, count = 43, palettes = {check = K.palList(pal, 0, 96),
      font = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16)}}
  for _, layer in ipairs({{"body", "gUnknown_08E788E4"}, {"title", "gUnknown_08E78A84"}}) do
    local idx, w, h = K.bakeText(gfx, c:lz(layer[2]), 32, 32)
    man.layers[layer[1]] = c:layer({key = layer[1]}, idx, w, h, pal)
  end
  for _, gender in ipairs({{"male", 0x4042}, {"female", 0x5042}}) do
    local words = string.rep(string.char(gender[2] % 256, math.floor(gender[2] / 256)), 1024)
    local idx, w, h = K.bakeText(gfx, words, 32, 32)
    man.layers[gender[1]] = c:layer({key = "bg_" .. gender[1], opaque = true}, idx, w, h, pal)
  end
  local circle = c:readTemplate("item_menu.o:gSpriteTemplate_83C1F98")
  man.circle = c:spriteFrames("circle", c:lz("gBerryCheckCircle_Gfx"), circle, pal)
  local wt, window = c:off("gWindowTemplate_81E6E18"), {}
  for i, key in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing"}) do window[key] = c:u8(wt + i - 1) end
  man.window = window
  for _, row in ipairs({{"size", "gOtherText_Size"}, {"firm", "gOtherText_Firm"},
    {"unknown", "gOtherText_ThreeQuestions2"}, {"sizeValue", "gContestStatsText_Unknown1"}}) do
    man.strings[row[1]] = text(c:off(row[2]))
  end
  local firm = c:off("gUnknown_0841192C")
  for i = 1, 5 do man.firmness[i] = A.text(c, assert(c:ptr(firm + (i - 1) * 4))) end
  local pictures, records = c:off("item_menu.o:sBerryGraphicsTable"), c:off("gBerries")
  assert(c.S.count("item_menu.o:sBerryGraphicsTable", 8) == 43, "native RS berry picture count differs")
  for i = 1, 43 do
    local at = pictures + (i - 1) * 8
    local data = c:lzAt(assert(c:ptr(at)))
    local bp = c:palFrom(c:lzAt(assert(c:ptr(at + 4))), 16)
    local tiles = {string.rep("\0", 256)}
    for row = 0, 5 do tiles[#tiles + 1] = string.rep("\0", 32) .. data:sub(row * 192 + 1, (row + 1) * 192) .. string.rep("\0", 32) end
    tiles[#tiles + 1] = string.rep("\0", 256)
    local idx = K.bakeSprite(table.concat(tiles), 64, 64, 0, 4)
    local o = records + (i - 1) * 28
    man.berries[i] = {png = c:png("berry_" .. i .. ".png", 64, 64, idx, bp, true), w = 64, h = 64,
      name = A.text(c, o), firmness = c:u8(o + 7), size = c:u16(o + 8),
      description1 = A.text(c, assert(c:ptr(o + 12))), description2 = A.text(c, assert(c:ptr(o + 16))),
      spicy = c:u8(o + 21), dry = c:u8(o + 22), sweet = c:u8(o + 23), bitter = c:u8(o + 24), sour = c:u8(o + 25)}
  end
  man.geometry = {berry = {56, 64}, circles = {48, 88, 128, 168, 208}, circleY = 99,
    number = {96, 32}, name = {112, 32}, sizeLabel = {88, 56}, sizeValue = {128, 56},
    firmLabel = {88, 72}, firmValue = {128, 72}, description1 = {32, 112}, description2 = {32, 128},
    scrollSpeed = 16, replacementStep = 9, scrollSteps = 16}
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
