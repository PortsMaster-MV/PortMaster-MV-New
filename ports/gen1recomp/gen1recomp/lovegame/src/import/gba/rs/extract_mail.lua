local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/mail", FILES = {}}
for design = 0, 11 do for gender = 0, 1 do
  M.FILES[#M.FILES + 1] = string.format("design_%02d_%d.png", design, gender)
end end
M.REQUIRED = K.required(M.SUB, M.FILES)

local function layout(c, off)
  local bits, lines = c:u8(off + 3), {}
  local ptr = assert(c:ptr(off + 4))
  for i = 0, c:u8(off) - 1 do
    local b = c:u8(ptr + i * 4)
    lines[i + 1] = {yOffset = b % 4, words = math.floor(b / 4) % 4, xOffset = math.floor(b / 16)}
  end
  return {signatureY = c:u8(off + 1), signatureX = c:u8(off + 2),
    wordsY = bits % 16, wordsX = math.floor(bits / 16), lines = lines}
end

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local count = c.S.count("gMailGraphicsTable", 20)
  assert(count == 12, "native RS mail graphics count")
  local go, colors = c:off("gMailGraphicsTable"), c:off("gUnknown_083E562C")
  local tall, short = c:off("gUnknown_083E57A4"), c:off("gUnknown_083E5730")
  local man = {screen = "mail", width = 240, height = 160, firstMailItem = 121,
    layoutMode = 1, designs = {}, layouts = {short = {}, tall = {}},
    from = A.text(c, c:off("gOtherText_From")), nativeWindow = {},
    icon = {maxMailSpecies = 411, unown = 201, unownB = 413, unownMailBase = 30000,
      unownForms = 28, egg = 412, fallback = 260, positions = {[6] = {96, 128}, [9] = {40, 128}},
      oam = c:readOam(c:off("pokemon_icon.o:sMonIconOamData")),
      anims = c:readAnimTable(c:off("pokemon_icon.o:sMonIconAnims"), 5),
      frame = 0, paused = true, callback = "SpriteCallbackDummy", manifest = "pokemon/manifest.lua"}}
  local wo = c:off("gWindowTemplate_81E6DFC")
  for i, key in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}) do
    man.nativeWindow[key] = c:u8(wo + i - 1)
  end
  for design = 0, count - 1 do
    local off = go + design * 20
    local original = c:palAt(assert(c:ptr(off)), 16)
    local gfx, map = c:lzAt(assert(c:ptr(off + 4))), c:lzAt(assert(c:ptr(off + 8)))
    local front = K.bakeText(gfx, map, 30, 20)
    local back = K.bakeText(gfx, string.rep(string.char(1, 0), 32 * 32), 30, 20)
    local idx = {}; for i = 1, 240 * 160 do idx[i] = front[i] ~= 0 and front[i] or back[i] end
    local row = {files = {}, palettes = {}, textColor = c:u16(off + 16), textShadow = c:u16(off + 18),
      tilesSize = c:u16(off + 12), unused = c:u16(off + 14),
      source = {palette = c:ptr(off), tiles = c:ptr(off + 4), tileMap = c:ptr(off + 8)}}
    for gender = 0, 1 do
      local pal = {}; for i = 0, 15 do pal[i] = original[i] end
      pal[10], pal[11] = c:u16(colors + gender * 4), c:u16(colors + gender * 4 + 2)
      row.files[gender + 1] = c:png(string.format("design_%02d_%d.png", design, gender), 240, 160, idx, pal, false)
      row.palettes[gender + 1] = K.palList(pal, 0, 16)
    end
    man.designs[design], man.layouts.tall[design], man.layouts.short[design] = row, layout(c, tall + design * 8), layout(c, short + design * 8)
  end
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
