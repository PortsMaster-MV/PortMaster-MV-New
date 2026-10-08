local Versions = require("src.import.gba.versions")
local BgBake = require("src.import.gba.bg_bake")
local Lz77 = require("src.import.gba.lz77")

local M = {}

M.FORMAT_VERSION = 1
M.SUB = "hall_of_fame"
M.REQUIRED = {
  "hall_of_fame/manifest.lua",
  "hall_of_fame/bands.rgba",
  "hall_of_fame/stripes.rgba",
  "hall_of_fame/confetti.rgba",
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

local function fill_map(rows)
  local map = {}
  for i = 1, 32 * 32 * 2 do map[i] = 0 end
  for _, r in ipairs(rows) do
    for y = r.y, r.y + r.h - 1 do
      for x = 0, 31 do map[(y * 32 + x) * 2 + 1] = r.tile end
    end
  end
  map._len = 32 * 32 * 2
  return map
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = (opts.cacheRoot or "data/generated/gba") .. "/" .. M.SUB
  local Hf = assert(Versions.HALL_OF_FAME, "HALL_OF_FAME keys missing for this game")
  local function put(name, body) assert(cache:write(root .. "/" .. name, body)) end
  local gfx = lz(rom, Hf.gfx)
  local banks = BgBake.loadPalBanks(raw(rom, Hf.pal, 32), 1)
  -- pokeemerald/src/hall_of_fame.c:1290
  put("bands.rgba", BgBake.bakeRegionRgba(gfx, banks, fill_map({
    { y = 0, h = 2, tile = 1 },
    { y = 3, h = 11, tile = 0 },
    { y = 14, h = 6, tile = 1 },
  }), W, H, { alpha0 = true }))
  put("stripes.rgba", BgBake.bakeRegionRgba(gfx, banks, fill_map({ { y = 0, h = 32, tile = 2 } }), W, H, {}))
  -- pokeemerald/src/hall_of_fame.c:151
  local sheet = lz(rom, Hf.confetti_sheet)
  assert(BgBake.byteLen(sheet) == Hf.confetti_frames * 32, "confetti sheet size mismatch")
  local pal = BgBake.loadPalBanks(lz(rom, Hf.confetti_pal), 1)[0]
  local frames = {}
  for f = 0, Hf.confetti_frames - 1 do
    frames[#frames + 1] = BgBake.bakeSpriteRgba(sheet, pal, f, 8, 8, false, false)
  end
  put("confetti.rgba", table.concat(frames))
  put("manifest.lua", string.format([[
return {
  format_version = %d,
  width = %d,
  height = %d,
  confetti = { w = 8, h = 8, frames = %d },
}
]], M.FORMAT_VERSION, W, H, Hf.confetti_frames))
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
