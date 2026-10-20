-- Bake FRLG field→battle transition gfx from ROM → data/generated/gba/pokemon/battle_transition/.
-- Source: pret battle_transition.c INCBINs (uncompressed 4bpp + pals + tilemaps).

local Versions = require("src.import.gba.versions")

local BattleTransitionExtract = {}

BattleTransitionExtract.FORMAT_VERSION = 1
BattleTransitionExtract.CACHE_SUB = "pokemon/battle_transition"
BattleTransitionExtract.REQUIRED = {
  "pokemon/battle_transition/manifest.lua",
  "pokemon/battle_transition/big_pokeball.rgba",
}

local MUGSHOT_KEYS = { "lorelei", "bruno", "agatha", "lance", "blue" }
local GENDER_KEYS = { "male", "female" }

local function default_cache_root()
  local ok, Extract = pcall(require, "src.import.gba.extract_island1")
  if ok and Extract and Extract.CACHE_ROOT then
    return Extract.CACHE_ROOT
  end
  return "data/generated/gba"
end

local function log(msg)
  print("[gba/battle_transition] " .. tostring(msg))
end

local function bgr555_to_rgb8(c)
  c = (tonumber(c) or 0) % 32768
  local r5 = c % 32
  local g5 = math.floor(c / 32) % 32
  local b5 = math.floor(c / 1024) % 32
  return math.floor(r5 * 255 / 31 + 0.5),
    math.floor(g5 * 255 / 31 + 0.5),
    math.floor(b5 * 255 / 31 + 0.5)
end

local function read_raw(rom, off, n)
  local t = {}
  for i = 0, n - 1 do t[i + 1] = rom:get(off + i) end
  return t
end

local function load_pal(rom, off)
  local pal = {}
  for c = 0, 15 do
    pal[c] = rom:u16(off + c * 2)
  end
  return pal
end

local function decode_tile_4bpp(tileBytes, out, baseX, baseY, stride, hflip, vflip)
  for row = 0, 7 do
    local srcRow = vflip and (7 - row) or row
    for bx = 0, 3 do
      local byte = tileBytes[srcRow * 4 + bx + 1] or 0
      local p0 = byte % 16
      local p1 = math.floor(byte / 16) % 16
      local x0 = bx * 2
      local x1 = x0 + 1
      if hflip then
        x0, x1 = 7 - x0, 7 - x1
      end
      out[(baseY + row) * stride + (baseX + x0) + 1] = p0
      out[(baseY + row) * stride + (baseX + x1) + 1] = p1
    end
  end
end

local function byte_len(buf)
  if type(buf) == "string" then return #buf end
  if type(buf) ~= "table" then return 0 end
  return buf._len or #buf
end

local function sheet_indices(gfx, tilesW, tilesH)
  gfx = type(gfx) == "table" and gfx or {}
  local w, h = tilesW * 8, tilesH * 8
  local indices = {}
  for i = 1, w * h do indices[i] = 0 end
  local tileCount = math.floor(byte_len(gfx) / 32)
  for ty = 0, tilesH - 1 do
    for tx = 0, tilesW - 1 do
      local ti = ty * tilesW + tx
      if ti < tileCount then
        local tile = {}
        local base = ti * 32
        for i = 1, 32 do tile[i] = gfx[base + i] or 0 end
        decode_tile_4bpp(tile, indices, tx * 8, ty * 8, w, false, false)
      end
    end
  end
  return indices, w, h
end

local function indices_to_rgba(indices, pal, w, h, opts)
  opts = opts or {}
  local opaque0 = opts.opaque0 == true
  local chunks = {}
  for i = 1, w * h do
    local idx = indices[i] or 0
    if idx == 0 and not opaque0 then
      chunks[i] = string.char(0, 0, 0, 0)
    else
      local r, g, b = bgr555_to_rgb8(pal[idx] or 0)
      chunks[i] = string.char(r, g, b, 255)
    end
  end
  return table.concat(chunks)
end

--- Bake a BG tilemap (cols×rows of u16) using a flat tile sheet + single pal.
local function bake_tilemap_rgba(gfx, pal, mapBytes, cols, rows, opts)
  opts = opts or {}
  local opaque0 = opts.opaque0 == true
  local w, h = cols * 8, rows * 8
  local indices = {}
  for i = 1, w * h do indices[i] = 0 end
  local tileCount = math.floor(#gfx / 32)
  local map = type(mapBytes) == "table" and mapBytes or {}
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      local mi = (row * cols + col) * 2 + 1
      local entry = (map[mi] or 0) + (map[mi + 1] or 0) * 256
      local tileNum = entry % 1024
      local hflip = math.floor(entry / 1024) % 2 == 1
      local vflip = math.floor(entry / 2048) % 2 == 1
      if tileNum < tileCount then
        local tile = {}
        local base = tileNum * 32
        for i = 1, 32 do tile[i] = gfx[base + i] or 0 end
        local tmp = {}
        for i = 1, 64 do tmp[i] = 0 end
        decode_tile_4bpp(tile, tmp, 0, 0, 8, hflip, vflip)
        for ty = 0, 7 do
          for tx = 0, 7 do
            local idx = tmp[ty * 8 + tx + 1] or 0
            indices[(row * 8 + ty) * w + (col * 8 + tx) + 1] = idx
          end
        end
      end
    end
  end
  return indices_to_rgba(indices, pal, w, h, { opaque0 = opaque0 }), w, h
end

local function merge_player_strip(oppPal, playerPal)
  local pal = {}
  for i = 0, 15 do pal[i] = oppPal[i] or 0 end
  -- pret LoadPalette(playerPal, BG_PLTT_ID(15)+10, 6 colors)
  for i = 0, 5 do
    pal[10 + i] = playerPal[i] or 0
  end
  return pal
end

local function bytes_str(arr)
  local parts = {}
  for i = 1, #arr do parts[i] = string.char(arr[i] or 0) end
  return table.concat(parts)
end

local function to_array(buf)
  if type(buf) == "string" then
    local t = {}
    for i = 1, #buf do t[i] = buf:byte(i) end
    return t
  end
  if type(buf) == "table" and buf._ffi and buf._len then
    local t = {}
    for i = 1, buf._len do t[i] = buf._ffi[i - 1] end
    return t
  end
  return buf
end

local function pal_from_bytes(bytes, bank)
  local pal = {}
  local base = (bank or 0) * 32
  for c = 0, 15 do
    pal[c] = (bytes[base + c * 2 + 1] or 0) + (bytes[base + c * 2 + 2] or 0) * 256
  end
  return pal
end

local function map_indices(gfx, mapBytes, cols, rows)
  local w, h = cols * 8, rows * 8
  local indices = {}
  for i = 1, w * h do indices[i] = 0 end
  local tileCount = math.floor(#gfx / 32)
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      local mi = (row * cols + col) * 2 + 1
      local entry = (mapBytes[mi] or 0) + (mapBytes[mi + 1] or 0) * 256
      local tileNum = entry % 1024
      if tileNum < tileCount then
        local tile = {}
        for i = 1, 32 do tile[i] = gfx[tileNum * 32 + i] or 0 end
        decode_tile_4bpp(tile, indices, col * 8, row * 8, w,
          math.floor(entry / 1024) % 2 == 1, math.floor(entry / 2048) % 2 == 1)
      end
    end
  end
  return indices, w, h
end

local function transition_ids(version)
  local ok, Constants = pcall(require, "src.core.game3.constants")
  if not ok then return nil end
  local okC, C = pcall(Constants.of, version)
  if not okC then return nil end
  local byName = C.battle and C.battle.byName or {}
  local names = {}
  for name, id in pairs(byName) do
    local short = name:match("^B_TRANSITION_(.+)$")
    if short and short ~= "COUNT" and not short:match("^GROUP_") then names[#names + 1] = { short, id } end
  end
  table.sort(names, function(a, b)
    if a[2] ~= b[2] then return a[2] < b[2] end
    return a[1] < b[1]
  end)
  local rows = {}
  for _, n in ipairs(names) do rows[#rows + 1] = string.format("%s = %d", n[1], n[2]) end
  return table.concat(rows, ", ")
end

-- pokeemerald/src/battle_transition.c:297
function BattleTransitionExtract.runRse(rom, cache, opts, cfg)
  local cacheRoot = opts.cacheRoot or default_cache_root()
  local root = cacheRoot .. "/" .. BattleTransitionExtract.CACHE_SUB
  local Lz77 = require("src.import.gba.lz77")
  local function get(i) return rom:get(i) end
  local function rawr(r) return read_raw(rom, r.off, r.size) end

  local ballPal = load_pal(rom, cfg.sliding_pokeball_pal.off)
  local bigRgba, bw, bh = bake_tilemap_rgba(rawr(cfg.big_pokeball_gfx), ballPal, rawr(cfg.big_pokeball_tilemap),
    30, 20, { opaque0 = true })
  cache:write(root .. "/big_pokeball.rgba", bigRgba)

  local slideIdx, sw, sh = sheet_indices(rawr(cfg.sliding_pokeball_gfx), 4, 4)
  cache:write(root .. "/sliding_pokeball.rgba", indices_to_rgba(slideIdx, ballPal, sw, sh))

  local gridTiles = math.floor(cfg.grid_square_gfx.size / 32)
  local gridIdx, gw, gh = sheet_indices(rawr(cfg.grid_square_gfx), 1, gridTiles)
  cache:write(root .. "/grid_square.rgba", indices_to_rgba(gridIdx, ballPal, gw, gh, { opaque0 = true }))

  local bannerGfx = rawr(cfg.mugshot_banner_gfx)
  local vsMap = rawr(cfg.vsbar_tilemap)
  local playerPals = { male = load_pal(rom, cfg.mugshot_pals.male), female = load_pal(rom, cfg.mugshot_pals.female) }
  for _, key in ipairs(cfg.mugshot_keys) do
    local oppPal = load_pal(rom, cfg.mugshot_pals[key])
    for _, gender in ipairs(GENDER_KEYS) do
      local pal = merge_player_strip(oppPal, playerPals[gender])
      local rgba = bake_tilemap_rgba(bannerGfx, pal, vsMap, 32, 20, { opaque0 = true })
      cache:write(root .. "/vsbar_" .. key .. "_" .. gender .. ".rgba", rgba)
    end
    local bIdx, bmw, bmh = sheet_indices(bannerGfx, math.floor(#bannerGfx / 32), 1)
    cache:write(root .. "/banner_" .. key .. ".rgba", indices_to_rgba(bIdx, oppPal, bmw, bmh))
  end

  cache:write(root .. "/sliding_pokeball_paint.bin", bytes_str(rawr(cfg.sliding_pokeball_bin)))
  cache:write(root .. "/pokeball.pal", bytes_str(rawr(cfg.sliding_pokeball_pal)))

  local assetLines = {}
  for _, a in ipairs(cfg.assets) do
    local gfx = a.tilesLz and to_array(Lz77.decompress(get, a.tiles)) or rawr(a.tiles)
    local palBytes = rawr(a.pal)
    local indices, w, h
    if a.map then
      local mapBytes = a.mapLz and to_array(Lz77.decompress(get, a.map)) or rawr(a.map)
      local cols = a.mapW or 32
      local rows = math.floor(#mapBytes / 2 / cols)
      indices, w, h = map_indices(gfx, mapBytes, cols, rows)
    else
      local cols = a.sheetW or 8
      indices, w, h = sheet_indices(gfx, cols, math.ceil(math.floor(#gfx / 32) / cols))
    end
    if w == 0 or h == 0 or #gfx == 0 then
      error("battle_transition_extract: asset " .. a.key .. " did not decode")
    end
    local bank = a.previewBank or 0
    cache:write(root .. "/" .. a.key .. ".rgba", indices_to_rgba(indices, pal_from_bytes(palBytes, bank), w, h))
    cache:write(root .. "/" .. a.key .. ".idx", bytes_str(indices))
    cache:write(root .. "/" .. a.key .. ".pal", bytes_str(palBytes))
    local extra = ""
    if a.pal2 then
      cache:write(root .. "/" .. a.key .. "_2.pal", bytes_str(rawr(a.pal2)))
      extra = string.format(', pal2 = "%s_2.pal", pal2Banks = %d', a.key, math.floor(a.pal2.size / 32))
    end
    assetLines[#assetLines + 1] = string.format(
      '    %s = { file = "%s.rgba", idx = "%s.idx", pal = "%s.pal", w = %d, h = %d, palBanks = %d, previewBank = %d, tiles = %d%s },',
      a.key, a.key, a.key, a.key, w, h, math.floor(#palBytes / 32), bank, math.floor(#gfx / 32), extra)
  end

  local picIds, rot, coords = {}, {}, {}
  for i = 0, cfg.mugshot_count - 1 do
    picIds[#picIds + 1] = tostring(rom:get(cfg.mugshot_pic_ids + i))
    local function s16(v) return v >= 32768 and v - 65536 or v end
    rot[#rot + 1] = string.format("{ %d, %d }", s16(rom:u16(cfg.mugshot_rotation_scales + i * 4)),
      s16(rom:u16(cfg.mugshot_rotation_scales + i * 4 + 2)))
    coords[#coords + 1] = string.format("{ %d, %d }", s16(rom:u16(cfg.mugshot_coords + i * 4)),
      s16(rom:u16(cfg.mugshot_coords + i * 4 + 2)))
  end
  local keys = {}
  for _, k in ipairs(cfg.mugshot_keys) do keys[#keys + 1] = string.format("%q", k) end

  local manifest = string.format([[return {
  format = %d,
  layout = "rse",
  bigPokeball = { file = "big_pokeball.rgba", w = %d, h = %d },
  slidingPokeball = { file = "sliding_pokeball.rgba", w = %d, h = %d },
  gridSquare = { file = "grid_square.rgba", w = %d, h = %d, frames = %d, fw = 8, fh = 8 },
  vsbar = { w = 256, h = 160 },
  mugshots = { %s },
  genders = { "male", "female" },
  mugshotTrainerPics = { %s },
  mugshotRotationScales = { %s },
  mugshotCoords = { %s },
  assets = {
%s
  },
  ids = { %s },
}
]], BattleTransitionExtract.FORMAT_VERSION, bw, bh, sw, sh, gw, gh, gridTiles, table.concat(keys, ", "),
    table.concat(picIds, ", "), table.concat(rot, ", "), table.concat(coords, ", "),
    table.concat(assetLines, "\n"), transition_ids(opts.version or require("src.core.GameVersion").get()) or "")
  cache:write(root .. "/manifest.lua", manifest)
  log(string.format("baked rse big=%dx%d slide=%dx%d grid=%dx%d assets=%d -> %s",
    bw, bh, sw, sh, gw, gh, #cfg.assets, root))
  return { root = root, bigW = bw, bigH = bh, slideW = sw, slideH = sh, gridW = gw, gridH = gh }
end

function BattleTransitionExtract.run(rom, cache, opts)
  opts = opts or {}
  local cacheRoot = opts.cacheRoot or default_cache_root()
  local root = cacheRoot .. "/" .. BattleTransitionExtract.CACHE_SUB
  local cfg = Versions.BATTLE_TRANSITION
  if not rom or not cache then return nil, "rom and cache required" end
  if not cfg then return nil, "Versions.BATTLE_TRANSITION missing" end
  if cfg.layout == "rse" then return BattleTransitionExtract.runRse(rom, cache, opts, cfg) end

  local ballPal = load_pal(rom, cfg.sliding_pokeball_pal)
  local bigGfx = read_raw(rom, cfg.big_pokeball_gfx, 1408)
  local bigMap = read_raw(rom, cfg.big_pokeball_tilemap, 1200)
  local bigRgba, bw, bh = bake_tilemap_rgba(bigGfx, ballPal, bigMap, 30, 20, { opaque0 = true })
  cache:write(root .. "/big_pokeball.rgba", bigRgba)

  local slideGfx = read_raw(rom, cfg.sliding_pokeball_gfx, 512)
  local slideIdx, sw, sh = sheet_indices(slideGfx, 4, 4)
  cache:write(root .. "/sliding_pokeball.rgba", indices_to_rgba(slideIdx, ballPal, sw, sh))

  local gridGfx = read_raw(rom, cfg.grid_square_gfx, 480)
  local gridIdx, gw, gh = sheet_indices(gridGfx, 1, 15)
  cache:write(root .. "/grid_square.rgba", indices_to_rgba(gridIdx, ballPal, gw, gh, { opaque0 = true }))

  local bannerGfx = read_raw(rom, cfg.mugshot_banner_gfx, 480)
  local vsMap = read_raw(rom, cfg.vsbar_tilemap, 1280)
  local mugPals = cfg.mugshot_pals
  local playerPals = {
    male = load_pal(rom, mugPals.red),
    female = load_pal(rom, mugPals.green),
  }

  for _, key in ipairs(MUGSHOT_KEYS) do
    local oppPal = load_pal(rom, mugPals[key])
    for _, gender in ipairs(GENDER_KEYS) do
      local pal = merge_player_strip(oppPal, playerPals[gender])
      local rgba, vw, vh = bake_tilemap_rgba(bannerGfx, pal, vsMap, 32, 20, { opaque0 = true })
      cache:write(root .. "/vsbar_" .. key .. "_" .. gender .. ".rgba", rgba)
      -- banner strip alone (useful for debug / partial draws)
      if gender == "male" then
        local bIdx, bmw, bmh = sheet_indices(bannerGfx, 15, 1)
        cache:write(root .. "/banner_" .. key .. ".rgba", indices_to_rgba(bIdx, oppPal, bmw, bmh))
      end
    end
  end

  local function bytes_to_str(arr)
    local parts = {}
    for i = 1, #arr do parts[i] = string.char(arr[i] or 0) end
    return table.concat(parts)
  end
  -- Keep paint tile + raw pals for trail / runtime recolor if needed.
  cache:write(root .. "/sliding_pokeball_paint.bin",
    bytes_to_str(read_raw(rom, cfg.sliding_pokeball_bin, 64)))
  cache:write(root .. "/pokeball.pal",
    bytes_to_str(read_raw(rom, cfg.sliding_pokeball_pal, 32)))

  local manifest = string.format([[return {
  format = %d,
  bigPokeball = { file = "big_pokeball.rgba", w = %d, h = %d },
  slidingPokeball = { file = "sliding_pokeball.rgba", w = %d, h = %d },
  gridSquare = { file = "grid_square.rgba", w = %d, h = %d, frames = 15, fw = 8, fh = 8 },
  vsbar = { w = 256, h = 160 },
  mugshots = { "lorelei", "bruno", "agatha", "lance", "blue" },
  genders = { "male", "female" },
  ids = {
    BLUR = 0, SWIRL = 1, SHUFFLE = 2, BIG_POKEBALL = 3, POKEBALLS_TRAIL = 4,
    CLOCKWISE_WIPE = 5, RIPPLE = 6, WAVE = 7, SLICE = 8, WHITE_BARS_FADE = 9,
    GRID_SQUARES = 10, ANGLED_WIPES = 11, LORELEI = 12, BRUNO = 13, AGATHA = 14,
    LANCE = 15, BLUE = 16, SPIRAL = 17,
  },
}
]], BattleTransitionExtract.FORMAT_VERSION, bw, bh, sw, sh, gw, gh)
  cache:write(root .. "/manifest.lua", manifest)
  log(string.format("baked big=%dx%d slide=%dx%d grid=%dx%d vsbar×%d → %s",
    bw, bh, sw, sh, gw, gh, #MUGSHOT_KEYS * #GENDER_KEYS, root))

  return {
    root = root,
    bigW = bw, bigH = bh,
    slideW = sw, slideH = sh,
    gridW = gw, gridH = gh,
  }
end

function BattleTransitionExtract.ready(cache, cacheRoot)
  local root = (cacheRoot or default_cache_root()) .. "/" .. BattleTransitionExtract.CACHE_SUB
  local function valid_file(rel, minSize)
    minSize = minSize or 1
    if cache then
      if cache.read then
        local data = cache:read(rel)
        return (data and #data >= minSize) or false
      elseif cache.exists then
        return cache:exists(rel) or false
      end
      return false
    end
    local okC, CacheFs = pcall(require, "src.import.CacheFs")
    if okC and CacheFs and CacheFs.readActive then
      local data = CacheFs.readActive(rel)
      if data and #data >= minSize then return true end
    end
    if love and love.filesystem and love.filesystem.read then
      local ok, data = pcall(love.filesystem.read, rel)
      if ok and data and #data >= minSize then return true end
    end
    local f = io.open(rel, "rb")
    if f then
      local data = f:read(minSize)
      f:close()
      if data and #data >= minSize then return true end
    end
    return false
  end

  return valid_file(root .. "/manifest.lua", 20)
    and valid_file(root .. "/big_pokeball.rgba", 64 * 64 * 4)
    and valid_file(root .. "/sliding_pokeball.rgba", 32 * 32 * 4)
end

return BattleTransitionExtract
