local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/bag", FILES = {"bg.png", "bg_female.png", "bag_male.png", "bag_female.png", "ball.png", "select.png",
  "arrows_vertical.png", "arrows_horizontal.png", "hm.png", "number.png", "indicator_0.png", "indicator_1.png", "list_cursor.png"}}
for i = 0, 4 do for _, g in ipairs({"male", "female"}) do M.FILES[#M.FILES + 1] = "label_" .. i .. "_" .. g .. ".png" end end
M.REQUIRED = K.required(M.SUB, M.FILES)
local N, H = "item_menu.o:", "menu_helpers.o:"
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "bag", layers = {}, sprites = {}, labels = {}, palettes = {}, actions = {}, pockets = {}, itemIcons = false}
  local gfx, map = c:lz("gBagScreen_Gfx"), c:raw("gBagScreen_Tilemap")
  local male, female = c:pal("gBagScreenMale_Pal", 32, nil, nil, true), c:pal("gBagScreenFemale_Pal", 32, nil, nil, true)
  local idx, w, h = K.bakeText(gfx, map, 30, 20)
  man.layers.bg = c:layer({key = "bg", opaque = true, variants = {{name = "", pal = male}, {name = "female", pal = female}}}, idx, w, h, male)
  man.layers.bg.backdrop, man.layers.bg.backdropFemale = male[0], female[0]
  man.palettes.male, man.palettes.female = K.palList(male, 0, 32), K.palList(female, 0, 32)
  local lm = c:raw("gBagScreenLabels_Tilemap")
  for pocket = 0, 4 do
    local li, lw, lh = K.bakeText(gfx, lm, 8, 2, {linear = true, mapWidth = 32, mapOffset = (pocket + 1) * 64})
    man.labels[pocket + 1] = {}
    for _, p in ipairs({{"male", male}, {"female", female}}) do
      man.labels[pocket + 1][p[1]] = c:png("label_" .. pocket .. "_" .. p[1] .. ".png", lw, lh, li, p[2], false)
    end
  end
  local bp = c:pal("gBagPalette", 16, nil, nil, true)
  for _, g in ipairs({{"male", "gBagMaleTiles"}, {"female", "gBagFemaleTiles"}}) do
    local tpl = c:readTemplate(N .. "sBagSpriteTemplate")
    man.sprites[g[1]] = c:spriteFrames("bag_" .. g[1], c:lz(g[2]), tpl, bp)
    man.sprites[g[1]].affineAnims = {A.affine(c, N .. "sBagSpriteAffineAnimSeq")}
  end
  man.sprites.ball = c:strip("ball", c:raw(N .. "gSpriteImage_BagSpinner"), 16, 16, 1, c:pal(N .. "gPalette_83C170C", 16))
  man.sprites.ball.affineAnims = {A.affine(c, N .. "gSpriteAffineAnim_83C1D00"), A.affine(c, N .. "gSpriteAffineAnim_83C1D10")}
  local selectMap = string.char(0x5A, 0, 0x5B, 0, 0x5C, 0, 0x6A, 0, 0x6B, 0, 0x6C, 0)
  local si = K.bakeText(gfx, selectMap, 3, 2, {linear = true, mapWidth = 3})
  man.select = c:png("select.png", 24, 16, si, male, true)
  man.glyphs, man.indicators = {}, {}
  for _, g in ipairs({{"hm", {0x105D, 0x105E, 0x106D, 0x106E}, 2, 2},
    {"number", {0x0059, 0x0069}, 1, 2}, {"indicator_0", {0x107C}, 1, 1}, {"indicator_1", {0x107D}, 1, 1}}) do
    local words = {}; for _, word in ipairs(g[2]) do words[#words + 1] = string.char(word % 256, math.floor(word / 256)) end
    local pixels, gw, gh = K.bakeText(gfx, table.concat(words), g[3], g[4], {linear = true, mapWidth = g[3]})
    local rec = {png = c:png(g[1] .. ".png", gw, gh, pixels, male, true), w = gw, h = gh, words = g[2], paletteBank = math.floor(g[2][1] / 4096)}
    if g[1]:find("indicator", 1, true) then man.indicators[tonumber(g[1]:sub(-1))] = rec else man.glyphs[g[1]] = rec end
  end
  man.indicatorGeometry = {x = 40, y = 72, spacing = 8, pockets = 5}
  man.hm, man.number = man.glyphs.hm.png, man.glyphs.number.png
  man.indicators.idle, man.indicators.selected = man.indicators[0].png, man.indicators[1].png
  local tableOff = c:off("gSubspriteTables_842F6C0") + 15 * 8
  local count, parts, tiles = c:u8(tableOff), {}, c:raw("OutlineCursorTiles_12")
  local sub = assert(c:ptr(tableOff + 4))
  local minX, minY, maxX, maxY = 256, 256, -256, -256
  for i = 0, count - 1 do
    local off, bits = sub + i * 8, c:u16(sub + i * 8 + 4)
    local w, h = K.objDims(bits % 4, math.floor(bits / 4) % 4)
    local part = {x = c:s16(off), y = c:s16(off + 2), w = w, h = h, tile = math.floor(bits / 16) % 1024}
    parts[#parts + 1] = part
    minX, minY, maxX, maxY = math.min(minX, part.x), math.min(minY, part.y), math.max(maxX, part.x + w), math.max(maxY, part.y + h)
  end
  local cw, ch = maxX - minX, maxY - minY
  local pixels = K.blank(cw, ch)
  for i = #parts, 1, -1 do
    local part = parts[i]; local idx = K.bakeSprite(tiles, part.w, part.h, part.tile, 4)
    for y = 0, part.h - 1 do for x = 0, part.w - 1 do
      local value = idx[y * part.w + x + 1]
      if value ~= 0 then pixels[(part.y - minY + y) * cw + part.x - minX + x + 1] = value end
    end end
  end
  man.listCursor = {png = c:png("list_cursor.png", cw, ch, pixels, {[12] = 0x2D9F}, true), w = cw, h = ch,
    offsetX = minX, offsetY = minY, x = 112, top = 16, spacing = 16,
    native = "CreateBlendedOutlineCursor", color = 0x2D9F, paletteIndex = 12, subsprites = parts}
  local ap = c:pal(H .. "Palette_3E5948", 16)
  for _, a in ipairs({{"vertical", "gSpriteImage_83E5808", "gSpriteImage_83E5848", "gSpriteTemplate_83E59D0"},
    {"horizontal", "gSpriteImage_83E5888", "gSpriteImage_83E58C8", "gSpriteTemplate_83E59E8"}}) do
    local tpl = c:readTemplate(H .. a[4])
    local sh = c:strip("arrows_" .. a[1], c:raw(H .. a[2]) .. c:raw(H .. a[3]), tpl.oam.w, tpl.oam.h, 2, ap)
    sh.anims, sh.callback = tpl.anims, tpl.callback
    man.sprites["arrows_" .. a[1]] = sh
  end
  local ao = c:off(N .. "sItemPopupMenuActions")
  for i = 0, c.S.count(N .. "sItemPopupMenuActions", 8) - 1 do
    local o = ao + i * 8
    man.actions[i + 1] = {text = A.text(c, assert(c:ptr(o))), callback = c.S.funcAt(c:u32(o + 4))}
  end
  local po, choices = c:off("gBagPockets"), c:off(N .. "sItemPopupMenuChoicesTable")
  for i = 0, 4 do
    local acts = {}
    for j = 0, 5 do acts[j + 1] = c:u8(choices + i * 6 + j) end
    man.pockets[i + 1] = {capacity = c:u8(po + i * 8 + 4), actions = acts}
  end
  man.geometry = {bagCenter = {58, 40}, ballCenter = {16, 88}, pocketLabel = {32, 80},
    listX = 112, listY = 16, listRows = 8, listSpacing = 16, descriptionX = 4, descriptionY = 104,
    arrows = {{172, 12}, {172, 148}, {28, 88}, {100, 88}}, selectX = 208, selectY = 16}
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
