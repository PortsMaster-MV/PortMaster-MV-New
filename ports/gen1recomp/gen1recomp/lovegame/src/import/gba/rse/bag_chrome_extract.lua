local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/bag"

M.FILES = {
  "bg.png", "bg_female.png", "indicator.png", "indicator_female.png", "bag_male.png", "bag_female.png",
  "ball.png", "arrows.png", "hm.png", "select.png", "icons.rgba", "menu_info.png",
}

M.REQUIRED = K.required(M.SUB, M.FILES)

local function mapString(entries)
  local out = {}
  for i, e in ipairs(entries) do out[i] = string.char(e % 256, math.floor(e / 256)) end
  return table.concat(out)
end

local function banks(c, name)
  local pal = c:pal(name, 32, nil, 0, true)
  return pal
end

local function withBank(pal, bank)
  local out = {}
  for i = 0, 15 do out[i] = pal[bank * 16 + i] or 0 end
  return out
end

local function tileStrip(gfx, tiles, bank)
  local entries = {}
  for i, t in ipairs(tiles) do entries[i] = t + bank * 4096 end
  return K.bakeText(gfx, mapString(entries), #tiles, 1, { linear = true, mapWidth = #tiles })
end

-- pokeemerald/src/item_icon.c:86
local function itemIcons(c)
  local tableOff = c:off("gItemIconTable")
  local count = c.S.size("gItemIconTable") / 8
  local rows = {}
  local clear = string.rep("\0", 4)
  for i = 0, count - 1 do
    local g = c:ptr(tableOff + i * 8)
    local p = c:ptr(tableOff + i * 8 + 4)
    local px, rgb = nil, {}
    if g and p then
      px = K.bakeSprite(c:lzAt(g), 24, 24, 0, 4)
      local ipal = c:palFrom(c:lzAt(p), 16)
      for k = 1, 15 do
        local r, gg, b = K.rgb8(ipal[k])
        rgb[k] = string.char(r, gg, b, 255)
      end
    end
    local out = {}
    for j = 1, 24 * 24 do
      local v = px and px[j] or 0
      out[j] = v == 0 and clear or rgb[v]
    end
    rows[#rows + 1] = table.concat(out)
  end
  return table.concat(rows), 24, 24 * count, count
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/item_menu.c:808
  local gfx = c:lz("gBagScreen_Gfx")
  local map = c:lz("gBagScreen_GfxTileMap")
  local male = banks(c, "gBagScreenMale_Pal")
  local female = banks(c, "gBagScreenFemale_Pal")
  local bgIdx, W, H = K.bakeText(gfx, map, 30, 20)
  local layers = {}
  layers.bg = c:layer({ key = "bg", opaque = true, variants = {
    { name = "", pal = male }, { name = "female", pal = female },
  } }, bgIdx, W, H, male)
  layers.bg.backdrop = male[0]
  layers.bg.backdropFemale = female[0]

  -- pokeemerald/src/item_menu.c:1407
  local indIdx, IW, IH = tileStrip(gfx, { 0x17, 0x2B }, 1)
  layers.indicator = c:layer({ key = "indicator", opaque = true, variants = {
    { name = "", pal = male }, { name = "female", pal = female },
  } }, indIdx, IW, IH, male)

  -- pokeemerald/src/item_menu_icons.c:130
  local bagPal = c:pal("gBagPalette", 16, nil, 0, true)
  local sprites = {
    male = c:strip("bag_male", c:lz("gBagMaleTiles"), 64, 64, 6, bagPal),
    female = c:strip("bag_female", c:lz("gBagFemaleTiles"), 64, 64, 6, bagPal),
  }
  -- pokeemerald/src/item_menu_icons.c:36
  sprites.ball = c:strip("ball", c:raw("item_menu_icons.o:sRotatingBall_Gfx"), 16, 16, 1,
    c:pal("item_menu_icons.o:sRotatingBall_Pal", 16))
  -- pokeemerald/src/list_menu.c:290
  sprites.arrows = c:strip("arrows", c:lz("list_menu.o:sScrollIndicator_Gfx"), 16, 16, 2,
    c:pal("sRedInterface_Pal", 16))

  -- pokeemerald/src/item_menu.c:968
  local listPal = withBank(male, 1)
  local hm = K.bakeSprite(c:raw("gBagMenuHMIcon_Gfx"), 16, 16, 0, 4)
  c:png("hm.png", 16, 16, hm, listPal, true)
  local sel = K.bakeSprite(c:raw("sRegisteredSelect_Gfx"), 24, 16, 0, 4)
  c:png("select.png", 24, 16, sel, listPal, true)

  local iconBytes, IcW, IcH, iconCount = itemIcons(c)
  c:write("icons.rgba", iconBytes)

  -- pokeemerald/src/menu.c:113
  local infoPal = c:pal("gMenuInfoElements2_Pal", 16)
  c:png("menu_info.png", 128, 128, K.bakeSprite(c:raw("gMenuInfoElements_Gfx"), 128, 128, 0, 4), infoPal, true)
  local infoRows = c:raw("sMenuInfoIcons")
  local infoIcons = {}
  for i = 0, math.floor(#infoRows / 4) - 1 do
    local w, h, lo, hi = infoRows:byte(i * 4 + 1, i * 4 + 4)
    local tile = lo + hi * 256
    infoIcons[i + 1] = { x = (tile % 16) * 8, y = math.floor(tile / 16) * 8, w = w, h = h }
  end

  return true, c:finish({
    screen = "bag",
    layers = layers,
    sprites = sprites,
    icons = { rgba = c:path("icons.rgba"), w = IcW, h = IcH, count = iconCount },
    hm = c:path("hm.png"),
    select = c:path("select.png"),
    menuInfo = { png = c:path("menu_info.png"), w = 128, h = 128, icons = infoIcons, palette = K.palList(infoPal, 0, 16) },
    -- pokeemerald/src/item_menu.c:384
    palettes = {
      male = K.palList(male, 0, 32),
      female = K.palList(female, 0, 32),
      bag = K.palList(bagPal, 0, 16),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
