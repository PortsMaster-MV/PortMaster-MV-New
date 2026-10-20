local Versions = require("src.import.gba.versions")
local BgBake = require("src.import.gba.bg_bake")
local Lz77 = require("src.import.gba.lz77")

local M = {}

M.SUB = "diploma"
M.REQUIRED = {
  "diploma/manifest.lua",
  "diploma/emerald_hoenn.rgba",
  "diploma/emerald_national.rgba",
}

local W, H = 240, 160

local function lz(rom, off)
  local out = Lz77.decompress(function(i) return rom:get(i) end, off)
  out._len = Lz77.len(out)
  return out
end

local function raw(rom, off, len)
  local out = {}
  for i = 1, len do out[i] = rom:get(off + i - 1) end
  out._len = len
  return out
end

-- pokeemerald/src/diploma.c:59-85 configures the diploma's 64x32 text BG.
-- pokeemerald/src/diploma.c:47-48 supplies its compressed tilemap and tiles;
-- pokeemerald/src/diploma.c:59-85 selects 64x32 BG storage with hardware screenblocks.
-- pokeemerald/src/diploma.c:47-48 data is linearized to logical rows before baking.
local function linearize64x32(map)
  local out = {}
  for y = 0, 31 do
    for x = 0, 63 do
      local block = math.floor(x / 32)
      local src = (block * 32 * 32 + y * 32 + (x % 32)) * 2 + 1
      local dst = (y * 64 + x) * 2 + 1
      out[dst], out[dst + 1] = map[src] or 0, map[src + 1] or 0
    end
  end
  out._len = 4096
  return out
end

local function opaqueBackdrop(rgba, color)
  local r, g, b = BgBake.bgr555ToRgb8(color or 0)
  local backdrop = string.char(r, g, b, 255)
  local pixels = {}
  for i = 1, W * H do
    local at = (i - 1) * 4 + 1
    pixels[i] = rgba:byte(at + 3) == 0 and backdrop or rgba:sub(at, at + 3)
  end
  return table.concat(pixels)
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local D = assert(Versions.DIPLOMA, "DIPLOMA keys missing for this game")
  local tiles = lz(rom, D.gfx)
  local tilemap = linearize64x32(lz(rom, D.tilemap))
  local banks = BgBake.loadPalBanks(raw(rom, D.palettes, D.paletteSize), 2)
  assert(BgBake.byteLen(tilemap) == 4096, "Emerald diploma tilemap is not 64x32")
  assert(BgBake.byteLen(tiles) % 32 == 0, "Emerald diploma tiles are not 4bpp")

  local function render(name, x0)
    local rgba = BgBake.bakeRegionRgba(tiles, banks, tilemap, W, H, {
      mapW = 64,
      x0 = x0,
    })
    assert(cache:write(root .. "/" .. M.SUB .. "/" .. name .. ".rgba",
      opaqueBackdrop(rgba, banks[0] and banks[0][0])))
  end

  render("emerald_hoenn", 0)
  -- pokeemerald/src/diploma.c:132 shifts BG1 by DISPLAY_WIDTH + 16 pixels.
  render("emerald_national", W + 16)
  assert(cache:write(root .. "/" .. M.SUB .. "/manifest.lua", string.format([[
return { format_version = 1, width = %d, height = %d, game = "emerald" }
]], W, H)))
  return { root = root .. "/" .. M.SUB }
end

function M.ready(cache, cacheRoot)
  local root = cacheRoot or "data/generated/gba"
  if not (cache and cache.exists) then return false end
  for _, rel in ipairs(M.REQUIRED) do
    if not cache:exists(root .. "/" .. rel) then return false end
  end
  return true
end

return M
