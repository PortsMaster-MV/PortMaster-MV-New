local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "rse/trendy_phrase", FILES = {}}
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local shape = c:u8(c:off("gUnknown_083DB6A4") + 9)
  assert(shape == 3, "native RS type9 shape must be3")
  local man = {screen = "easy_chat_trendy_phrase", type = 9, shape = shape,
    wordCount = 2, columns = 2, rows = 1, assets = "rse/easy_chat",
    frame = {x = 3, y = 2, sourceX = 0, sourceY = 32, w = 24, h = 4},
    wordPens = {{x = 48, y = 24}, {x = 136, y = 24}},
    wordCursors = {{x = 44, y = 32}, {x = 132, y = 32}},
    footer = {x = 28, y = 96, stride = 56}, titleFont = 1, titleWidth = 240,
    prompt = {x = 32, y = 120, width = 176, linePitch = 16}, texts = {}}
  local ids = c:off("gUnknown_083DB7C0") + 9 * 2
  local prompts = c:off("gUnknown_083DB6F4")
  for i, key in ipairs({"edit", "confirm"}) do
    local id = c:u8(ids + i - 1)
    man.texts[key] = {A.text(c, assert(c:ptr(prompts + id * 12))),
      A.text(c, assert(c:ptr(prompts + id * 12 + 4)))}
  end
  for key, name in pairs({title = "gOtherText_WhatsHipHappening", cancel = "gOtherText_QuitGivingInfo",
    delete1 = "gOtherText_TextDeletedConfirmPage1", delete2 = "gOtherText_TextDeletedConfirmPage2",
    empty = "gOtherText_EnterAPhraseOrWord", unchanged = "gOtherText_TrendyAlready",
    incomplete = "gOtherText_CombineTwoPhrases", yes = "OtherText_Yes", no = "OtherText_No"}) do
    man.texts[key] = A.text(c, c:off(name))
  end
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
