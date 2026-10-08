local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokenav", FILES = {"message.png", "dots.png", "outline.png", "options_main.png", "options_condition.png",
  "options_search.png", "lh_main_menu.png", "lh_condition.png", "lh_ribbons.png", "lh_trainers_eyes.png", "lh_hoenn_map.png", "blue_light.png"}}
for city = 0, 15 do
  M.FILES[#M.FILES + 1] = string.format("city_%02d_0.png", city)
  if city == 8 or city == 9 or city == 10 or city == 12 or city == 13 or city == 15 then
    M.FILES[#M.FILES + 1] = string.format("city_%02d_1.png", city)
  end
end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function mapRelative(raw, tileBase)
  local out = {}
  for i = 1, #raw, 2 do
    local lo, hi = raw:byte(i, i + 1)
    local e = lo + hi * 256
    if e % 1024 >= tileBase then e = e - tileBase else e = 0 end
    out[#out + 1] = string.char(e % 256, math.floor(e / 256))
  end
  return table.concat(out)
end
local function texts(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 4) - 1 do out[i + 1] = A.text(c, assert(c:ptr(off + i * 4))) end
  return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokenav", coverage = "native_main_menu_headers_options_and_city_maps", layers = {}, sprites = {}, leftHeaders = {}, cityMaps = {},
    menus = {}, palettes = {}, features = {trainersEyes = true, matchCall = false}}
  local function layer(key, gfx, map, base, pal)
    local idx, w, h = K.bakeText(gfx, mapRelative(map, base), 32, 32)
    man.layers[key] = c:layer({key = key}, idx, w, h, pal)
  end
  -- pokenav.c:331
  local msgpal = c:pal("gUnknown_083DFECC", 16, {}, 240)
  local outlinepal = c:pal("gPokenavOutlinePalette", 16, {}, 64)
  local dotpal = c:pal("gUnknown_083E003C", 16, {}, 48)
  layer("message", c:raw("gUnknown_083DFEEC"), c:lz("gUnknown_083DFF8C"), 640, msgpal)
  layer("outline", c:lz("gPokenavOutlineTiles"), c:lz("gPokenavOutlineTilemap"), 1, outlinepal)
  layer("dots", c:raw("gUnknown_083E005C"), c:lz("gUnknown_083E007C"), 0, dotpal)
  man.palettes.message, man.palettes.outline, man.palettes.dots = K.palList(msgpal, 240, 16), K.palList(outlinepal, 64, 16), K.palList(dotpal, 48, 16)
  for _, spec in ipairs({{"main", "gPokenavMenuOptions_Gfx", "gPokenavMenuOptions1_Pal", "gPokenavMenuOptions2_Pal", 5, 42, 20, "gUnknown_083E31B0"},
    {"condition", "gPokenavConditionMenu_Gfx", "gPokenavConditionMenu_Pal", nil, 3, 56, 20, "gUnknown_083E31CC"},
    {"search", "gPokenavConditionSearch_Gfx", "gPokenavCondition6_Pal", "gPokenavCondition7_Pal", 6, 40, 16, "gUnknown_083E31D8"}}) do
    local gfx, pal = c:lz(spec[2]), c:pal(spec[3], 16)
    if spec[4] then c:pal(spec[4], 16, pal, 16) end
    local atlas = K.blank(128, spec[5] * 16)
    for row = 0, spec[5] - 1 do
      for piece = 0, 3 do
        local px = K.bakeSprite(gfx, 32, 16, row * 32 + piece * 8, 4)
        for y = 0, 15 do for x = 0, 31 do
          local v = px[y * 32 + x + 1]
          if v > 0 then atlas[(row * 16 + y) * 128 + piece * 32 + x + 1] = v + ((row > 2 and spec[4]) and 16 or 0) end
        end end
      end
    end
    man.sprites["options_" .. spec[1]] = {png = c:png("options_" .. spec[1] .. ".png", 128, spec[5] * 16, atlas, pal, true), w = 128, h = 16, frames = spec[5]}
    man.menus[spec[1]] = {optionX = 136, top = spec[6], spacing = spec[7], count = spec[5], help = texts(c, spec[8])}
  end
  local hp = c:pal("gPokenavMenuOptions3_Pal", 16)
  for _, h in ipairs({{"main_menu", "gPokenavMainMenu_Gfx"}, {"condition", "gPokenavConditionMenuHeader_Gfx"},
    {"ribbons", "gPokenavRibbonsHeader_Gfx"}, {"trainers_eyes", "gPokenavTrainersEyesHeader_Gfx"}, {"hoenn_map", "gPokenavHoennMapHeader_Gfx"}}) do
    local rects = h[1] == "hoenn_map" and {{tile = 0, w = 64, h = 32}, {tile = 32, w = 64, h = 32}, {tile = 64, w = 64, h = 32}}
      or {{tile = 0, w = 64, h = 32}, {tile = 32, w = 32, h = 32}}
    local pal = h[1] == "trainers_eyes" and c:pal("gPokenavCondition5_Pal", 16) or hp
    man.leftHeaders[h[1]] = c:atlas("lh_" .. h[1], c:lz(h[2]), rects, pal)
  end
  man.sprites.blueLight = c:spriteFrames("blue_light", c:raw("PokenavBlueLightTiles"), c:readTemplate("gSpriteTemplate_83E4484"), c:pal("PokenavBlueLightPalette", 16))
  local cities, zoom = c:off("gPokenavCityMaps"), c:lz("gPokenavHoennMapSquares_Gfx")
  local zp = c:pal("gPokenavHoennMapSquares_Pal", 16, {}, 48)
  for city = 0, 15 do
    for part = 0, 1 do
      local p = c:ptr(cities + city * 8 + part * 4)
      if p then
        local idx, w, h = K.bakeText(zoom, mapRelative(c:lzAt(p), 640), 10, 10, {linear = true, mapWidth = 10})
        local file = string.format("city_%02d_%d.png", city, part)
        man.cityMaps[#man.cityMaps + 1] = {mapSec = city, index = part, png = c:png(file, w, h, idx, zp, false), w = w, h = h}
      end
    end
  end
  man.geometry = {headerCenters = {{32, 49}, {96, 49}}, optionsX = 136, optionW = 128, highlightHeight = 17}
  man.regionMapManifest = "data/generated/gba/rse/region_map/manifest.lua"
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
