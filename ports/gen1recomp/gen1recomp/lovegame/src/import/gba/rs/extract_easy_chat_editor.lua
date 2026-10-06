local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Contracts = require("src.core.game3.rs.easy_chat_contracts")
local V = require("src.import.gba.versions")
local M = {SUB = "rse/easy_chat_editor", VERSION = 2, FILES = {"interview_frame.png", "indicator.png",
  "frame_blue_base.png", "frame_blue_1.png", "frame_blue_2.png", "frame_blue_3.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function nativeText(c, off)
  local bytes = {}
  for i = 0, 1023 do
    local b = c:u8(off + i); bytes[#bytes + 1] = b
    if b == 255 then return bytes end
  end
  error("native RS Easy Chat word has no EOS")
end
local function messageWords(c)
  local out, tableOff, sizes = {}, c:off("gEasyChatGroupWords"), c:off("gEasyChatGroupSizes")
  for group = 0, c.S.count("gEasyChatGroupWords", 4) - 1 do
    local pointer = assert(c:ptr(tableOff + group * 4))
    for index = 0, c:u8(sizes + group) - 1 do
      local value, bytes = index
      if group == 0 or group == 21 then
        value = c:u16(pointer + index * 2)
        bytes = nativeText(c, V.SPECIES_NAMES + value * V.SPECIES_NAME_LENGTH)
      elseif group == 18 or group == 19 then
        value = c:u16(pointer + index * 2)
        bytes = nativeText(c, V.MOVE_NAMES + value * (V.MOVE_NAME_LENGTH + 1))
      else
        bytes = nativeText(c, pointer)
        pointer = pointer + #bytes
      end
      out[group * 512 + value] = bytes
    end
  end
  return out
end

local function indexedBlueFrame(c)
  local gfx, frames, masks = c:lz("gMenuWordGroupFrame_Gfx"), {}, {{}, {}, {}}
  local count = #gfx / 32
  assert(count % 1 == 0, "native Easy Chat frame tile alignment")
  for tile = 0, count - 1 do
    local px, base, layers = K.bakeSprite(gfx, 8, 8, tile, 4), {}, {{}, {}, {}}
    for i = 1, 64 do
      local index = px[i]
      base[i] = index >= 1 and index <= 3 and 0 or index
      for layer = 1, 3 do layers[layer][i] = index == layer and 1 or 0 end
    end
    frames[#frames + 1] = base
    for layer = 1, 3 do masks[layer][#masks[layer] + 1] = layers[layer] end
  end
  local sourcePal, pal = c:pal("gMenuWordGroupFrame1_Pal", 32), {}
  for index = 0, 15 do pal[index] = sourcePal[index + 16] end
  local idx, w, h = K.stack(frames, 8, 8)
  local out = {bank = 5, count = count, w = w, h = h, indices = {81, 82, 83},
    source = "gMenuWordGroupFrame_Gfx", base = c:png("frame_blue_base.png", w, h, idx, pal, true), masks = {}}
  for layer = 1, 3 do
    idx = K.stack(masks[layer], 8, 8)
    out.masks[layer] = c:png("frame_blue_" .. layer .. ".png", w, h, idx, {[0] = 0, [1] = 32767}, true)
  end
  return out
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "easy_chat_editor", editorVersion = M.VERSION, assets = "rse/easy_chat", types = {}, sprites = {},
    titleFont = 1, titleMeasureFont = 3, titleWidth = 240, titleY = 0,
    footer = {x = 28, y = 96, stride = 56},
    prompt = {x = 32, y = 120, width = 176, linePitch = 16}, texts = {},
    controls = Contracts.CONTROLS, errors = Contracts.ERRORS}
  local prompts, ids, shapes = c:off("gUnknown_083DB6F4"), c:off("gUnknown_083DB7C0"), c:off("gUnknown_083DB6A4")
  for kind = 0, 13 do
    local d, row = Contracts.TYPES[kind], {type = kind, texts = {}}
    local shapeId = c:u8(shapes + kind)
    assert(shapeId == d.shapeId, "native RS EasyChat shape mismatch")
    local s = Contracts.SHAPES[shapeId]
    row.shapeId, row.wordCount, row.columns, row.rows = shapeId, s.count, s.columns, s.rows
    row.frame = {x = s.frame[1], y = s.frame[2], sourceX = s.frame[3], sourceY = s.frame[4], w = s.frame[5], h = s.frame[6]}
    row.wordPens, row.wordCursors = {}, {}
    for i = 0, s.count - 1 do
      local col, r = i % s.columns, math.floor(i / s.columns)
      row.wordPens[i + 1] = {x = s.pen[1] * 8 + col * 88, y = s.pen[2] * 8 + r * 16}
      row.wordCursors[i + 1] = {x = s.cursor[1] * 8 + 4 + col * 88, y = s.cursor[2] * 8 + 8 + r * 16}
    end
    for i, key in ipairs({"edit", "confirm"}) do
      local id = c:u8(ids + kind * 2 + i - 1)
      local first, second = A.text(c, assert(c:ptr(prompts + id * 12))), A.text(c, assert(c:ptr(prompts + id * 12 + 4)))
      row.texts[key] = c:u8(prompts + id * 12 + 8) ~= 0 and {first, second} or {first .. " " .. second}
    end
    row.texts.title = d.header and A.text(c, c:off(d.header)) or false
    row.texts.cancel = A.text(c, c:off(d.cancelPrompt))
    row.cancelWarnings, row.deleteAllowed = d.cancelWarnings, d.deleteAllowed
    if kind == 5 or kind == 7 or kind == 8 or kind == 10 or kind == 11 or kind == 12 then
      local x, y = shapeId == 5 and 36 or 64, shapeId == 5 and 48 or 40
      row.interview = {x = x, y = y, playerX = x - 12, reporterX = x + 12,
        playerGraphics = {male = 100, female = 105}, reporterGraphics = {[0] = 67, [1] = 68},
        playerFacing = "right", reporterFacing = "left"}
    end
    man.types[kind] = row
  end
  for key, name in pairs({delete1 = "gOtherText_TextDeletedConfirmPage1", delete2 = "gOtherText_TextDeletedConfirmPage2",
    discard1 = "gOtherText_EditedTextNoSavePage1", discard2 = "gOtherText_EditedTextNoSavePage2",
    empty = "gOtherText_EnterAPhraseOrWord", unchanged = "gOtherText_TrendyAlready", incomplete = "gOtherText_CombineTwoPhrases",
    noDelete = "gOtherText_TextNoDelete", bardRestore1 = "gOtherText_OnlyOnePhrase", bardRestore2 = "gOtherText_OriginalSongRestored",
    yes = "OtherText_Yes", no = "OtherText_No"}) do man.texts[key] = A.text(c, c:off(name)) end

  man.sprites.interviewFrame = c:spriteFrames("interview_frame", c:lz("gMenuInterviewFrame_Gfx"),
    c:readTemplate("gSpriteTemplate_83DBD48"), c:pal("gMenuInterviewFrame_Pal"))
  man.sprites.indicator = c:spriteFrames("indicator", c:lz("gMenuWordGroupIndicator_Gfx"),
    c:readTemplate("gSpriteTemplate_83DBDE4"), c:pal("gMenuWordGroupIndicator_Pal"))
  man.blueFrame = indexedBlueFrame(c)
  man.messageWords = messageWords(c)
  man.invalidWord = nativeText(c, c:off("gOtherText_ThreeQuestions"))
  return A.finish(c, man)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local body = cache:read((root or "data/generated/gba") .. "/" .. M.SUB .. "/manifest.lua")
  return body:find("editorVersion = " .. M.VERSION, 1, true) ~= nil
end
return M
