local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/pokenav"
M.FILES = {
  "header.png", "message.png", "device.png", "dots.png", "dots_purple.png", "options.png", "blue_light.png",
  "spin.png", "mc_ui.png", "mc_cursor.png", "arrows.png", "pokeball.png", "pokeball_lit.png",
  "cursor_large.png", "city_maps.png", "zoom_text.png",
  "lh_main_menu.png", "lh_condition.png", "lh_ribbons.png", "lh_match_call.png", "lh_hoenn_map.png",
  "lh_party.png", "lh_search.png", "lh_cool.png", "lh_beauty.png", "lh_cute.png", "lh_smart.png", "lh_tough.png",
}
M.REQUIRED = K.required(M.SUB, M.FILES)

local MCG = "pokenav_match_call_gfx.o:"

local function nameAt(c, ptr)
  if not ptr then return nil end
  for _, n in ipairs(c.S.namesAt(ptr)) do
    if not n:find(":", 1, true) then return n end
  end
  local n = c.S.namesAt(ptr)[1]
  return n and (n:gsub("^.-:", "")) or nil
end

local function bankPal(c, name, bank, count)
  return c:pal(name, count or 16, {}, bank * 16)
end

local function rebase(map, base)
  local out = {}
  for i = 0, #map / 2 - 1 do
    local lo, hi = map:byte(i * 2 + 1, i * 2 + 2)
    local e = lo + hi * 256
    local tile = e % 1024
    if tile >= base then e = e - base end
    out[#out + 1] = string.char(e % 256, math.floor(e / 256))
  end
  return table.concat(out)
end

local function palList(p, base, n)
  local out = {}
  for i = 0, (n or 16) - 1 do out[i] = p[(base or 0) + i] or 0 end
  return out
end

local function sprite1d(gfx, w, h, tile)
  return K.bakeSprite(gfx, w, h, tile, 4)
end

local function frames(gfx, w, h, tiles)
  local list = {}
  for i, t in ipairs(tiles) do list[i] = sprite1d(gfx, w, h, t) end
  return K.stack(list, w, h)
end

-- pokeemerald/src/pokenav_main_menu.c:133
local LEFT_HEADERS = {
  { key = "main_menu", gfx = "gPokenavLeftHeaderMainMenu_Gfx", tag = 3, w = 64, h = 32, n = 2 },
  { key = "condition", gfx = "gPokenavLeftHeaderCondition_Gfx", tag = 1, w = 64, h = 32, n = 2 },
  { key = "ribbons", gfx = "gPokenavLeftHeaderRibbons_Gfx", tag = 2, w = 64, h = 32, n = 2 },
  { key = "match_call", gfx = "gPokenavLeftHeaderMatchCall_Gfx", tag = 4, w = 64, h = 32, n = 2 },
  { key = "hoenn_map", gfx = "gPokenavLeftHeaderHoennMap_Gfx", tag = 0, w = 64, h = 32, n = 3 },
  { key = "party", gfx = "gPokenavLeftHeaderParty_Gfx", tag = 1, w = 32, h = 16, n = 2 },
  { key = "search", gfx = "gPokenavLeftHeaderSearch_Gfx", tag = 1, w = 32, h = 16, n = 2 },
  { key = "cool", gfx = "gPokenavLeftHeaderCool_Gfx", tag = 4, w = 32, h = 16, n = 2 },
  { key = "beauty", gfx = "gPokenavLeftHeaderBeauty_Gfx", tag = 1, w = 32, h = 16, n = 2 },
  { key = "cute", gfx = "gPokenavLeftHeaderCute_Gfx", tag = 2, w = 32, h = 16, n = 2 },
  { key = "smart", gfx = "gPokenavLeftHeaderSmart_Gfx", tag = 0, w = 32, h = 16, n = 2 },
  { key = "tough", gfx = "gPokenavLeftHeaderTough_Gfx", tag = 0, w = 32, h = 16, n = 2 },
}

-- pokeemerald/src/pokenav_menu_handler_gfx.c:197
local function optionLabels(c)
  local off = c:off("sPokenavMenuOptionLabelGfx")
  local menus, labels, byTile = {}, {}, {}
  for m = 0, c.S.size("sPokenavMenuOptionLabelGfx") / 28 - 1 do
    local b = off + m * 28
    local row = { yStart = c:u16(b), deltaY = c:u16(b + 2), items = {} }
    for i = 0, 5 do
      local p = c:ptr(b + 4 + i * 4)
      if p then
        local tile, pal = c:u16(p), c:u16(p + 2)
        local key = tile .. ":" .. pal
        if not byTile[key] then
          labels[#labels + 1] = { tile = tile, pal = pal, name = nameAt(c, p) }
          byTile[key] = #labels
        end
        row.items[i + 1] = byTile[key]
      end
    end
    menus[m] = row
  end
  return menus, labels
end

-- pokeemerald/src/landmark.c:339
local function landmarks(c)
  local off, out = c:off("sLandmarkLists"), {}
  for i = 0, c.S.size("sLandmarkLists") / 8 - 1 do
    local b = off + i * 8
    local sec = c:u8(b)
    local row = { mapSec = sec, id = c:u8(b + 1), landmarks = {} }
    local lp = c:ptr(b + 4)
    if lp then
      for j = 0, 15 do
        local p = c:ptr(lp + j * 4)
        if not p then break end
        row.landmarks[#row.landmarks + 1] = { name = nameAt(c, c:ptr(p)), flag = c:u16(p + 4) }
      end
    end
    out[#out + 1] = row
  end
  return out
end

local function ptrNames(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i] = nameAt(c, c:ptr(off + i * 4)) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/pokenav_main_menu.c:333
  local headerPal = bankPal(c, "gPokenavHeader_Pal", 0)
  c:png("header.png", 256, 256, K.bakeText(c:lz("gPokenavHeader_Gfx"), c:lz("gPokenavHeader_Tilemap"), 32, 32), headerPal, true)

  -- pokeemerald/src/pokenav_menu_handler_gfx.c:448
  local msgPal = bankPal(c, "gPokenavMessageBox_Pal", 1)
  c:png("message.png", 256, 160, K.bakeText(c:lz("gPokenavMessageBox_Gfx"), c:lz("gPokenavMessageBox_Tilemap"), 32, 20,
    { linear = true, mapWidth = 32 }), msgPal, true)
  local devPal = bankPal(c, "sPokenavDeviceBgPal", 2)
  c:png("device.png", 256, 160, K.bakeText(c:lz("sPokenavDeviceBgTiles"), c:lz("sPokenavDeviceBgTilemap"), 32, 20,
    { linear = true, mapWidth = 32 }), devPal, true)
  local dotsPal = bankPal(c, "sPokenavBgDotsPal", 3)
  local dotsIdx = K.bakeText(c:lz("sPokenavBgDotsTiles"), c:lz("sPokenavBgDotsTilemap"), 32, 20, { linear = true, mapWidth = 32 })
  c:png("dots.png", 256, 160, dotsIdx, dotsPal, false)
  -- pokeemerald/src/pokenav_menu_handler_gfx.c:1273
  local purple = {}
  for k, v in pairs(dotsPal) do purple[k] = v end
  purple[48 + 1], purple[48 + 2] = dotsPal[48 + 7], dotsPal[48 + 8]
  c:png("dots_purple.png", 256, 160, dotsIdx, purple, false)

  -- pokeemerald/src/pokenav_menu_handler_gfx.c:204
  local menus, labels = optionLabels(c)
  local optGfx = c:lz("gPokenavOptions_Gfx")
  local optPals = c:pal("gPokenavOptions_Pal", 80)
  local atlas = K.blank(128, 16 * #labels)
  for i, lab in ipairs(labels) do
    for j = 0, 3 do
      local px = sprite1d(optGfx, 32, 16, lab.tile + 8 * j)
      for y = 0, 15 do
        for x = 0, 31 do
          local v = px[y * 32 + x + 1]
          if v ~= 0 then atlas[((i - 1) * 16 + y) * 128 + j * 32 + x + 1] = lab.pal * 16 + v end
        end
      end
    end
  end
  c:png("options.png", 128, 16 * #labels, atlas, optPals, true)
  c:png("blue_light.png", 32, 16, sprite1d(c:lz("sMatchCallBlueLightTiles"), 32, 16, 0), c:pal("sMatchCallBlueLightPal", 16), true)

  -- pokeemerald/src/pokenav_main_menu.c:213
  local spin = frames(c:lz("sSpinningPokenav_Gfx"), 32, 32, { 0, 16, 32, 48, 64, 80, 96, 112 })
  c:png("spin.png", 32, 256, spin, c:pal("sSpinningPokenav_Pal", 16), true)

  local lhPal = c:pal("gPokenavLeftHeader_Pal", 80)
  local leftHeaders = {}
  for _, h in ipairs(LEFT_HEADERS) do
    local gfx = c:lz(h.gfx)
    local per = (h.w / 8) * (h.h / 8)
    local tiles = {}
    for i = 0, h.n - 1 do tiles[i + 1] = i * per end
    local idx = frames(gfx, h.w, h.h, tiles)
    c:png("lh_" .. h.key .. ".png", h.w, h.h * h.n, idx, palList(lhPal, h.tag * 16), true)
    leftHeaders[h.key] = { png = c:path("lh_" .. h.key .. ".png"), w = h.w, h = h.h, frames = h.n }
  end

  -- pokeemerald/src/pokenav_match_call_gfx.c:323
  local uiPal = bankPal(c, MCG .. "sMatchCallUI_Pal", 2)
  c:png("mc_ui.png", 256, 160, K.bakeText(c:lz(MCG .. "sMatchCallUI_Gfx"), rebase(c:lz(MCG .. "sMatchCallUI_Tilemap"), 0x80),
    32, 20, { linear = true, mapWidth = 32 }), uiPal, true)
  c:png("mc_cursor.png", 8, 16, sprite1d(c:lz(MCG .. "sOptionsCursor_Gfx"), 8, 16, 0), c:pal(MCG .. "sOptionsCursor_Pal", 16), true)
  local arrowGfx = c:lz("sListArrow_Gfx")
  local arrows = K.blank(16, 32)
  local right = sprite1d(arrowGfx, 8, 16, 0)
  for y = 0, 15 do for x = 0, 7 do arrows[y * 16 + x + 1] = right[y * 8 + x + 1] end end
  for k, t in ipairs({ 2, 4 }) do
    local a = sprite1d(arrowGfx, 16, 8, t)
    for y = 0, 7 do for x = 0, 15 do arrows[(8 + k * 8 + y) * 16 + x + 1] = a[y * 16 + x + 1] end end
  end
  c:png("arrows.png", 16, 32, arrows, c:pal("sListArrow_Pal", 16), true)
  local ballPals = c:pal(MCG .. "sPokeball_Pal", 32)
  local ball = sprite1d(c:lz(MCG .. "sPokeball_Gfx"), 8, 16, 0)
  c:png("pokeball.png", 8, 16, ball, palList(ballPals, 0), true)
  c:png("pokeball_lit.png", 8, 16, ball, palList(ballPals, 16), true)

  -- pokeemerald/src/region_map.c:1375
  local curLarge = frames(c:lz("sRegionMapCursorLargeGfxLZ"), 32, 32, { 0, 16, 32 })
  c:png("cursor_large.png", 32, 96, curLarge, c:pal("sRegionMapCursorPal", 16), true)

  -- pokeemerald/src/pokenav_region_map.c:637
  local zoomTiles = c:lz("sRegionMapCityZoomTiles_Gfx")
  local zoomPal = c:pal("gRegionMapCityZoomTiles_Pal", 16, {}, 48)
  local cityOff = c:off("sPokenavCityMaps")
  local cityCount = c.S.size("sPokenavCityMaps") / 8
  local cities, cityIdx = {}, K.blank(80, 80 * cityCount)
  for i = 0, cityCount - 1 do
    local b = cityOff + i * 8
    local tm = c:lzAt(assert(c:ptr(b + 4), "pokenav: city map tilemap"))
    local idx = K.bakeText(zoomTiles, tm, 10, 10, { linear = true, mapWidth = 10 })
    for y = 0, 79 do
      for x = 0, 79 do cityIdx[(i * 80 + y) * 80 + x + 1] = idx[y * 80 + x + 1] end
    end
    cities[i + 1] = { mapSec = c:u16(b), index = c:u16(b + 2) }
  end
  c:png("city_maps.png", 80, 80 * cityCount, cityIdx, zoomPal, false)
  c:png("zoom_text.png", 512, 8, sprite1d(c:lz("gRegionMapCityZoomText_Gfx"), 512, 8, 0), palList(zoomPal, 48), true)

  return true, c:finish({
    screen = "pokenav",
    layers = {
      header = { png = c:path("header.png"), w = 256, h = 256 },
      message = { png = c:path("message.png"), w = 256, h = 160 },
      device = { png = c:path("device.png"), w = 256, h = 160 },
      dots = { png = c:path("dots.png"), purple = c:path("dots_purple.png"), w = 256, h = 160 },
      matchCall = { png = c:path("mc_ui.png"), w = 256, h = 160 },
    },
    sprites = {
      options = { png = c:path("options.png"), w = 128, h = 16 },
      blueLight = { png = c:path("blue_light.png"), w = 32, h = 16 },
      spin = { png = c:path("spin.png"), w = 32, h = 32, frames = 8 },
      mcCursor = { png = c:path("mc_cursor.png"), w = 8, h = 16 },
      arrows = { png = c:path("arrows.png"), right = { 0, 0, 8, 16 }, down = { 0, 16, 16, 8 }, up = { 0, 24, 16, 8 } },
      pokeball = { png = c:path("pokeball.png"), lit = c:path("pokeball_lit.png"), w = 8, h = 16 },
      cursorLarge = { png = c:path("cursor_large.png"), w = 32, h = 32, frames = 3 },
      cityMaps = { png = c:path("city_maps.png"), w = 80, h = 80 },
      zoomText = { png = c:path("zoom_text.png"), w = 512, h = 8 },
    },
    leftHeaders = leftHeaders,
    palettes = {
      header = palList(headerPal, 0),
      message = palList(msgPal, 16),
      matchCallUi = palList(uiPal, 32),
      callWindow = palList(c:pal(MCG .. "sCallWindow_Pal", 16), 0),
      listWindow = palList(c:pal(MCG .. "sListWindow_Pal", 16), 0),
      infoWindow = palList(c:pal("sMapSecInfoWindow_Pal", 16), 0),
      zoomTiles = palList(zoomPal, 48),
    },
    menus = menus,
    labels = labels,
    cityMaps = cities,
    landmarks = landmarks(c),
    helpBarTexts = ptrNames(c, "sHelpBarTexts"),
    pageDescriptions = ptrNames(c, "sPageDescriptions"),
    optionTexts = ptrNames(c, MCG .. "sMatchCallOptionTexts"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
