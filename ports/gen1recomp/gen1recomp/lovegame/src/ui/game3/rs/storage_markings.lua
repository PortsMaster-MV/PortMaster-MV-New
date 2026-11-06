local Kit = require("src.ui.game3.rse.scene_kit")
local Window = require("src.ui.game3.window")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local M = {}
local cached, cacheOwner
local function textures()
  local Dataset = require("src.core.game3.dataset")
  local cache = Dataset.cache()
  local owner = tostring(require("src.core.GameVersion").get()) .. ":" .. tostring(Dataset.cacheRootOverride)
  if cached and cacheOwner == owner then return cached end
  assert(cache and cache.read, "native RS markings cache missing")
  local gfx = assert(cache:read("data/generated/gba/rs/assets/pokenav__gPokenavConditionMenuMisc_Gfx.rom"), "native RS marking tiles missing")
  local raw = assert(cache:read("data/generated/gba/rs/assets/unknown__gUnknown_08E966B8.rom"), "native RS marking palette missing")
  local K = require("src.import.gba.rse.boot_gfx")
  local pal = {}; for i = 0, 15 do local a, b = raw:byte(i * 2 + 1, i * 2 + 2); pal[i] = a + b * 256 end
  local function image(w, h, tile)
    local idx, data = K.bakeSprite(gfx, w, h, tile, 4), love.image.newImageData(w, h)
    for y = 0, h - 1 do for x = 0, w - 1 do
      local v = idx[y * w + x + 1]; local r, g, b = Kit.rgb555(pal[v]); data:setPixel(x, y, r, g, b, v == 0 and 0 or 1)
    end end
    local img = love.graphics.newImage(data); img:setFilter("nearest", "nearest"); return img
  end
  cached, cacheOwner = {icons = {}, text = image(64, 32, 9), color = pal[15]}, owner
  for i = 0, 7 do cached.icons[i] = image(8, 8, i) end
  return cached
end
function M.open(mon) return {mon = mon, original = (tonumber(mon.markings) or 0) % 16, value = (tonumber(mon.markings) or 0) % 16, cursor = 0} end
function M.input(state, input)
  if input:wasPressed("up") then state.cursor = (state.cursor - 1) % 6; return "moved" end
  if input:wasPressed("down") then state.cursor = (state.cursor + 1) % 6; return "moved" end
  if input:wasPressed("b") then return "closed" end
  if input:wasPressed("a") then
    if state.cursor == 4 then state.mon.markings = state.value; return "closed" end
    if state.cursor == 5 then return "closed" end
    local bit = 2 ^ state.cursor
    state.value = state.value + (state.value % (bit * 2) >= bit and -bit or bit)
    return "moved"
  end
end
-- pokeruby/src/pokemon_storage_system_2.c:1105
function M.draw(state)
  local t = textures()
  Window.userFrame(Window.template(23, 3, 6, 12))
  love.graphics.setColor(1, 1, 1, 1)
  for i = 0, 3 do local on = state.value % (2 ^ (i + 1)) >= 2 ^ i
    love.graphics.draw(t.icons[i * 2 + (on and 1 or 0)], 204, 28 + i * 16)
  end
  love.graphics.draw(t.text, 192, 88)
  local cursor = assert(Kit.manifest("rse/common_ui")).menuCursor
  local r, g, b = Kit.rgb555(t.color); love.graphics.setColor(r, g, b, 1)
  local segments = Cursor.segments(48)
  for i = #segments, 1, -1 do local s = segments[i]
    love.graphics.draw(assert(Kit.image(cursor[s.part].mask)), 184 + s.x, 24 + state.cursor * 16)
  end
  love.graphics.setColor(1, 1, 1, 1)
end
return M
