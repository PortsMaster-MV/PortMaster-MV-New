local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "rse/easy_chat", FILES = {"frame_tiles.png", "blank_word.png", "triangle.png", "outline.png", "arrows.png", "buttons.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function words(bytes)
  local out = {}; for i = 1, #bytes, 2 do out[#out + 1] = bytes:byte(i) + bytes:byte(i + 1) * 256 end
  return out
end
local function window(c, name)
  local out, off = {}, c:off(name)
  for i, key in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor", "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  return out
end
local function styledText(c, off)
  local IR, bytes, out = require("src.core.game3.scripting.text_ir"), {}, {}
  for i = 0, 1023 do local b = c:u8(off + i); bytes[#bytes + 1] = b; if b == 255 then break end end
  for _, seg in ipairs(IR.decode(bytes, {dialect = "rs"})) do
    if seg.t == "ext" then
      out[#out + 1] = string.char(252, seg.cmd)
      for _, b in ipairs(seg.args or {}) do out[#out + 1] = string.char(b) end
    else out[#out + 1] = IR.toAscii({seg}) end
  end
  return table.concat(out)
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local pal = {}; for i = 0, 255 do pal[i] = 0 end
  c:pal("gFontDefaultPalette", 16, pal, 240)
  c:pal("gUnknown_08E9AB40", 16, pal, 0)
  c:pal("gUnknown_083DBDFC", 16, pal, 16)
  c:pal("gUnknown_083DBE40", 16, pal, 32)
  pal[63], pal[49], pal[56] = 32767, 27 + 26 * 32 + 27 * 1024, 28 + 28 * 32 + 28 * 1024
  c:pal("gMenuWordGroupFrame1_Pal", 32, pal, 64)
  local gfx = c:lz("gMenuWordGroupFrame_Gfx")
  local tileCount, frames = #gfx / 32, {}
  assert(tileCount % 1 == 0, "native Easy Chat tile alignment")
  for bank = 4, 5 do
    for tile = 0, tileCount - 1 do
      local px = K.bakeSprite(gfx, 8, 8, tile, 4)
      for i = 1, 64 do if px[i] ~= 0 then px[i] = bank * 16 + px[i] end end
      frames[#frames + 1] = px
    end
  end
  local atlas, aw, ah = K.stack(frames, 8, 8)
  local man = {screen = "easy_chat_mail", width = 240, height = 160, type = 4, variant = 3,
    wordCount = 9, columns = 2, rows = 5, tiles = {count = tileCount, w = aw, h = ah,
      png = c:png("frame_tiles.png", aw, ah, atlas, pal, true)},
    maps = {base = words(c:raw("gUnknown_08E945D0")), shapes = words(c:raw("gUnknown_08E94AD0")), picker = words(c:lz("gUnknown_08E953D0"))},
    palettes = {bg = K.palList(pal, 0, 256), frameBlue = K.palList(c:pal("gMenuWordGroupFrame2_Pal"), 0, 16)},
    windows = {phrase = window(c, "gWindowTemplate_81E6D8C"), picker = window(c, "gWindowTemplate_81E6D54"), prompt = window(c, "gWindowTemplate_81E6DA8")},
    alphabet = {}, alphabetText = {}, alphabetCursorX = {}, alphabeticalWords = {}, letterOffsets = {}, texts = {}, sprites = {}, sine = {}}
  local bg2 = words(c:lz("gUnknown_08E9AB60"))
  assert(#bg2 == 320, "native Easy Chat BG2 map must be32x10")
  for _, entry in ipairs(bg2) do assert(entry == 0x300, "native Easy Chat BG2 tile") end
  assert(c:raw("gUnknown_08E9AB00", 32) == string.rep("\255", 32), "native Easy Chat BG2 solid tile")
  man.backdrop = {height = 80, color = 15, tile = 0x300, map = bg2}
  for i = 0, 255 do man.sine[i + 1] = c:s16(c:off("gSineTable") + i * 2) end
  local letters, cursor = c:off("gUnknown_083DB6B2"), c:off("gUnknown_083DBCC4")
  for row = 0, 3 do
    man.alphabet[row + 1], man.alphabetCursorX[row + 1] = A.text(c, letters + row * 16), {}
    man.alphabetText[row + 1] = styledText(c, c:off("gUnknown_083DBEAC") + row * 32)
    for col = 0, 6 do man.alphabetCursorX[row + 1][col + 1] = c:s8(cursor + row * 7 + col) end
  end
  local offsets, alphabetized = c:off("gEasyChatWordsByLetter"), c:off("gEasyChatWordsAlphabetized")
  for i = 0, 27 do man.letterOffsets[i + 1] = c:u16(offsets + i * 2) end
  for i = 0, man.letterOffsets[28] - 1 do man.alphabeticalWords[i + 1] = c:u16(alphabetized + i * 2) end
  local prompts = c:off("gUnknown_083DB6F4")
  for key, id in pairs({edit = 2, confirm = 10}) do
    man.texts[key] = {A.text(c, assert(c:ptr(prompts + id * 12))), A.text(c, assert(c:ptr(prompts + id * 12 + 4)))}
  end
  for key, name in pairs({delete1 = "gOtherText_TextDeletedConfirmPage1", delete2 = "gOtherText_TextDeletedConfirmPage2", cancel = "gOtherText_StopGivingMail", empty = "gOtherText_EnterAPhraseOrWord", yes = "OtherText_Yes", no = "OtherText_No"}) do man.texts[key] = A.text(c, c:off(name)) end
  local underlineGfx = c:raw("gUnknown_08E9AB00")
  local underlineMap = words(c:raw("gUnknown_083DBE1C"))
  local map = {}; for _, e in ipairs(underlineMap) do
    local tile = e % 1024 - 0x300
    local v = math.floor(e / 1024) * 1024 + tile
    map[#map + 1] = string.char(v % 256, math.floor(v / 256))
  end
  man.blankWord = c:png("blank_word.png", 72, 16, K.bakeText(underlineGfx, table.concat(map), 9, 2, {linear = true}), pal, true)
  local p0, p1 = c:pal("InterviewPalette_0"), c:pal("InterviewPalette_1")
  local tri = c:readTemplate("gSpriteTemplate_83DBBFC")
  man.sprites.triangle = c:spriteFrames("triangle", c:raw("InterviewTriangleCursorTiles"), tri, p0)
  local outline = {oam = c:readOam(c:off("gOamData_83DBC14")), anims = c:readAnimTable(c:off("gSpriteAnimTable_83DBC7C"), 4)}
  man.sprites.outline = c:spriteFrames("outline", c:raw("gInterviewOutlineCursorTiles"), outline, p1, {32, 40, 48})
  local arrow = {oam = c:readOam(c:off("gOamData_83DBCE0")), anims = c:readAnimTable(c:off("gSpriteAnimTable_83DBCF8"), 2)}
  man.sprites.arrows = c:spriteFrames("arrows", c:raw("InterviewArrowTiles"), arrow, p0)
  arrow.oam.w, arrow.oam.h = 32, 8
  arrow.anims = c:readAnimTable(c:off("gSpriteAnimTable_83DBD10"), 2)
  man.sprites.buttons = c:spriteFrames("buttons", c:raw("InterviewButtonTiles"), arrow, p0)
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
