local Kit = require("src.ui.game3.rse.scene_kit")
local K = require("src.import.gba.rse.boot_gfx")
local M = {}
local cached, cachedKey
function M.slotImages()
  local Dataset = require("src.core.game3.dataset")
  local key = tostring(require("src.core.GameVersion").get()) .. ":" .. tostring(Dataset.cacheRootOverride)
  if cached and cachedKey == key then return cached[1], cached[2] end
  local cache = Dataset.cache()
  local gfx = assert(cache:read("data/generated/gba/rs/assets/pokemon_storage__gPSSMenuMisc_Gfx.bin"), "native RS drawer graphics missing")
  local map = assert(cache:read("data/generated/gba/rs/assets/pokemon_storage__gPSSMenuMisc_Tilemap.bin"), "native RS drawer tilemap missing")
  local pal = assert(Kit.manifest("pokemon/storage")).palettes.interface
  local function image(column)
    local rows = {}
    for y = 4, 6 do for x = column, column + 3 do
      local a, b = map:byte((y * 32 + x) * 2 + 1, (y * 32 + x) * 2 + 2)
      local e = a + b * 256
      local relative = e % 1024 - 832 + math.floor(e / 1024) * 1024
      assert(e % 1024 >= 832, "native RS drawer tile base")
      rows[#rows + 1] = string.char(relative % 256, math.floor(relative / 256))
    end end
    local idx = K.bakeText(gfx, table.concat(rows), 4, 3, {linear = true, mapWidth = 4})
    local data = love.image.newImageData(32, 24)
    for y = 0, 23 do for x = 0, 31 do
      local v = idx[y * 32 + x + 1]; local r, g, b = Kit.rgb555(pal[v + 1])
      data:setPixel(x, y, r, g, b, v % 16 == 0 and 0 or 1)
    end end
    local out = love.graphics.newImage(data); out:setFilter("nearest", "nearest"); return out
  end
  cached, cachedKey = {image(12), image(16)}, key
  return cached[1], cached[2]
end
function M.textColors(kind)
  local p = assert(Kit.manifest("pokemon/storage")).palettes.textColors
  local fg, shadow = 2, 1
  if kind == "M" then fg, shadow = 12, 13 elseif kind == "F" then fg, shadow = 10, 11 end
  local function color(index)
    local r, g, b = Kit.rgb555(assert(p[index + 1], "native RS storage text palette missing"))
    return {r, g, b, 1}
  end
  return {fg = color(fg), shadow = color(shadow), bg = {0, 0, 0, 0}}
end
return M
