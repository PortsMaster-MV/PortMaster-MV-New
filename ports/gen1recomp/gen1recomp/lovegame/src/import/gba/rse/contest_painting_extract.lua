local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/contest_painting"

M.CATEGORIES = { "cool", "beauty", "cute", "smart", "tough" }

-- pokeemerald/src/contest_painting.c:73
M.FRAMES = {
  cool = { "sPictureFrameTiles_Cool", "sPictureFrameTilemap_Cool" },
  beauty = { "sPictureFrameTiles_Beauty", "sPictureFrameTilemap_Beauty" },
  cute = { "sPictureFrameTiles_Cute", "sPictureFrameTilemap_Cute" },
  smart = { "sPictureFrameTiles_Smart", "sPictureFrameTilemap_Smart" },
  tough = { "sPictureFrameTiles_Tough", "sPictureFrameTilemap_Tough" },
  lobby = { "sPictureFrameTiles_HallLobby", "sPictureFrameTilemap_HallLobby" },
}

M.FILES = { "pointillism.bin" }
for k in pairs(M.FRAMES) do
  M.FILES[#M.FILES + 1] = k .. ".gfx"
  M.FILES[#M.FILES + 1] = k .. ".map"
end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/tools/gbagfx/rl.c:8
function M.rlDecompress(get, off)
  assert(get(off) == 0x30, string.format("contest_painting: no RL header at 0x%X", off))
  local size = get(off + 1) + get(off + 2) * 256 + get(off + 3) * 65536
  local out, n, p = {}, 0, off + 4
  while n < size do
    local flag = get(p)
    p = p + 1
    if flag >= 0x80 then
      local len = flag % 0x80 + 3
      local v = get(p)
      p = p + 1
      for _ = 1, len do
        if n < size then n = n + 1; out[n] = v end
      end
    else
      local len = flag + 1
      for _ = 1, len do
        if n < size then n = n + 1; out[n] = get(p) end
        p = p + 1
      end
    end
  end
  local parts, i = {}, 1
  while i <= n do
    local e = math.min(n, i + 4095)
    parts[#parts + 1] = string.char(unpack(out, i, e))
    i = e + 1
  end
  return table.concat(parts)
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local get = function(i) return rom:get(i) end

  local frames = {}
  for key, spec in pairs(M.FRAMES) do
    local tiles = M.rlDecompress(get, c:off(spec[1]))
    local map = M.rlDecompress(get, c:off(spec[2]))
    c:write(key .. ".gfx", tiles)
    c:write(key .. ".map", map)
    frames[key] = { gfx = c:path(key .. ".gfx"), map = c:path(key .. ".map"), tiles = #tiles / 32, entries = #map / 2 }
  end
  c:write("pointillism.bin", c:raw("image_processing_effects.o:sPointillismPoints"))

  -- pokeemerald/src/contest_painting.c:128
  local captions = {}
  for i, cat in ipairs(M.CATEGORIES) do
    for n = 1, 3 do
      captions[(i - 1) * 3 + n - 1] = "gContestPainting" .. cat:sub(1, 1):upper() .. cat:sub(2) .. n
    end
  end

  return true, c:finish({
    screen = "contest_painting",
    frames = frames,
    pointillism = { path = c:path("pointillism.bin"), count = c.S.size("image_processing_effects.o:sPointillismPoints") / 3 },
    -- pokeemerald/src/contest_painting.c:72
    framePalette = K.palList(c:pal("sPictureFramePalettes", 128), 0, 128),
    captions = captions,
    -- pokeemerald/src/contest_painting.c:95
    rankNames = { [0] = "gContestRankNormal", "gContestRankSuper", "gContestRankHyper", "gContestRankMaster", "gContestLink" },
    hallCaption = "gContestHallPaintingCaption",
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
