local Versions = require("src.import.gba.versions")
local BgBake = require("src.import.gba.bg_bake")
local Lz77 = require("src.import.gba.lz77")

local M = {}

M.CACHE_SUB = "items/shop"
M.FORMAT_VERSION = 1
M.REQUIRED = { "items/shop/manifest.lua", "items/shop/bg.rgba", "items/shop/bg_tm.rgba", "items/shop/money_label.rgba" }

local W, H = 240, 160

local function lz(rom, off)
  local out = Lz77.decompress(function(i) return rom:get(i) end, off)
  out._len = Lz77.len(out)
  return out
end

-- pokeemerald/src/shop.c:753
local function menu_bg(gfx, banks, map)
  local keep = {}
  local n = math.floor(BgBake.byteLen(map) / 2)
  for i = 0, n - 1 do
    local e = (map[i * 2 + 1] or 0) + (map[i * 2 + 2] or 0) * 256
    keep[i] = e ~= 0
  end
  local indices, pals = BgBake.regionIndices(gfx, map, W, H, {})
  local chunks = {}
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local i = y * W + x + 1
      local cell = math.floor(y / 8) * 32 + math.floor(x / 8)
      if keep[cell] and pals[i] >= 0 and indices[i] ~= 0 then
        local r, g, b = BgBake.bgr555ToRgb8((banks[0] or {})[indices[i]] or 0)
        chunks[i] = string.char(r, g, b, 255)
      else
        chunks[i] = "\0\0\0\0"
      end
    end
  end
  return table.concat(chunks)
end

M.menuBg = menu_bg

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = (opts.cacheRoot or "data/generated/gba") .. "/" .. M.CACHE_SUB
  local S = assert(Versions.SHOP_MENU, "SHOP_MENU keys missing for this game")
  local gfx = lz(rom, S.gfx)
  local banks = BgBake.loadPalBanks(lz(rom, S.pal), 1)
  local map = lz(rom, S.tilemap)
  local bg = menu_bg(gfx, banks, map)
  assert(cache:write(root .. "/bg.rgba", bg))
  assert(cache:write(root .. "/bg_tm.rgba", bg))
  local label = lz(rom, S.moneyLabel)
  assert(cache:write(root .. "/money_label.rgba", BgBake.bakeSpriteRgba(label, banks[0], 0, 32, 16, false, false)))
  assert(cache:write(root .. "/manifest.lua", string.format([[
return {
  format_version = %d,
  width = %d,
  height = %d,
  bg = "bg.rgba",
  bgTm = "bg_tm.rgba",
  moneyLabel = { file = "money_label.rgba", w = 32, h = 16 },
  layout = "rse",
}
]], M.FORMAT_VERSION, W, H)))
  return { root = root }
end

function M.ready(cache, cacheRoot)
  if not (cache and cache.exists) then return false end
  local root = cacheRoot or "data/generated/gba"
  for _, rel in ipairs(M.REQUIRED) do
    if not cache:exists(root .. "/" .. rel) then return false end
  end
  return true
end

return M
