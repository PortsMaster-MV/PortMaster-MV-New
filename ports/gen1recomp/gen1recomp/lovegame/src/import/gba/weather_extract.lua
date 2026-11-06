-- Weather graphics and palette extraction (Fog, Rain, default weather palette)
-- pokefirered/src/field_weather.c

local Versions = require("src.import.gba.versions")

local WeatherExtract = {}

WeatherExtract.CACHE_SUB = "weather"
WeatherExtract.FORMAT_VERSION = 1

WeatherExtract.BLOBS = {
  { key = "default_pal", rel = "default.gbapal", offset = 0x3C2CE0, size = 32 },
  { key = "fog_h_gfx", rel = "fog_horizontal.4bpp", offset = 0x3C3540, size = 2048 },
  { key = "rain_gfx", rel = "rain.4bpp", offset = 0x3C55C0, size = 1536 },
}

local function bgr555_to_rgb8(c)
  c = (tonumber(c) or 0) % 32768
  local r5 = c % 32
  local g5 = math.floor(c / 32) % 32
  local b5 = math.floor(c / 1024) % 32
  return math.floor(r5 * 255 / 31 + 0.5),
    math.floor(g5 * 255 / 31 + 0.5),
    math.floor(b5 * 255 / 31 + 0.5)
end

local function bytes_to_array(v)
  if type(v) == "table" then return v end
  local out = {}
  if type(v) == "string" then
    for i = 1, #v do out[i] = v:byte(i) end
  end
  return out
end

local function load_pal(bytes, count)
  bytes = bytes_to_array(bytes)
  local pal = {}
  for i = 0, count - 1 do
    pal[i] = (bytes[i * 2 + 1] or 0) + (bytes[i * 2 + 2] or 0) * 256
  end
  return pal
end

local function decode_tile_4bpp(gfx, base, out)
  for row = 0, 7 do
    for col = 0, 7 do
      local b = gfx[base + row * 4 + math.floor(col / 2) + 1] or 0
      local idx
      if col % 2 == 0 then idx = b % 16 else idx = math.floor(b / 16) end
      out[row * 8 + col + 1] = idx
    end
  end
end

function WeatherExtract.bakeSheet(gfxBytes, palBytes, cols)
  local gfx = bytes_to_array(gfxBytes)
  local pal = load_pal(palBytes, 16)
  local tileCount = math.floor(#gfx / 32)
  cols = math.max(1, cols or 8)
  local rows = math.ceil(tileCount / cols)
  local W, H = cols * 8, rows * 8
  local chunks = {}
  for i = 1, W * H do chunks[i] = "\0\0\0\0" end
  local tmp = {}
  for t = 0, tileCount - 1 do
    decode_tile_4bpp(gfx, t * 32, tmp)
    local ox, oy = (t % cols) * 8, math.floor(t / cols) * 8
    for row = 0, 7 do
      for col = 0, 7 do
        local idx = tmp[row * 8 + col + 1] or 0
        if idx ~= 0 then
          local r, g, b = bgr555_to_rgb8(pal[idx] or 0)
          chunks[(oy + row) * W + ox + col + 1] = string.char(r, g, b, 255)
        end
      end
    end
  end
  return table.concat(chunks), W, H, tileCount
end

function WeatherExtract.readBlobs(rom, cfg)
  cfg = cfg or {}
  local out = {}
  for _, blob in ipairs(WeatherExtract.BLOBS) do
    local off = cfg[blob.key] or Versions.address(blob.offset)
    local bytes = rom:readBytes(off, blob.size)
    local chars = {}
    for i = 1, blob.size do chars[i] = string.char(bytes[i] or 0) end
    out[blob.key] = table.concat(chars)
  end
  return out
end

local function write_cache(cache, rel, data)
  if type(cache) ~= "table" or type(cache.write) ~= "function" then return end
  local ok, res, err = pcall(function() return cache:write(rel, data) end)
  if not ok or res == nil then res, err = cache.write(rel, data) end
  return res
end

local function default_cache_root()
  local ok, Extract = pcall(require, "src.import.gba.extract_island1")
  if ok and Extract and Extract.CACHE_ROOT then return Extract.CACHE_ROOT end
  return "data/generated/gba"
end

WeatherExtract.RSE_FORMAT = 1
WeatherExtract.REQUIRED = {
  "weather/manifest.lua",
  "weather/fog_horizontal.rgba",
  "weather/rain.rgba",
  "weather/drought_colors.bin",
}

function WeatherExtract.runRse(rom, cache, root)
  local G = require("src.import.gba.rse.sprite_gfx")
  local W = Versions.WEATHER_GFX
  local S = Versions.SYMS
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local pals, palFiles = {}, {}
  for key, off in pairs(W.palettes) do
    pals[key] = G.readPalette(rom, off)
    local file = key == "fog" and "default.gbapal" or (key .. ".gbapal")
    write_cache(cache, root .. "/" .. file, G.palBytes(pals[key]))
    palFiles[key] = { file = file, symbol = G.symName(S, off), colors = {} }
    for i = 0, 15 do palFiles[key].colors[i + 1] = pals[key][i] end
  end
  local out = {
    format = WeatherExtract.RSE_FORMAT,
    family = "rse",
    palettes = palFiles,
    blobs = {},
  }
  for _, blob in ipairs(W.blobs) do
    local t = G.readTemplate(rom, S, blob.template)
    local fw = t.oam.w
    local tiles = blob.size / 32
    local cols = fw / 8
    local rows = math.ceil(tiles / cols)
    local w, h = fw, rows * 8
    local tile, sheet = {}, {}
    for i = 1, w * h do sheet[i] = 0 end
    for i = 0, tiles - 1 do
      G.decodeTiles(rom, blob.tiles + i * 32, 8, 8, tile, 0, 8)
      local tx, ty = (i % cols) * 8, math.floor(i / cols) * 8
      for y = 0, 7 do
        for x = 0, 7 do
          sheet[(ty + y) * w + tx + x + 1] = tile[y * 8 + x + 1]
        end
      end
    end
    write_cache(cache, root .. "/" .. blob.file .. ".4bpp", rom:readString(blob.tiles, blob.size))
    write_cache(cache, root .. "/" .. blob.file .. ".idx", G.idxString(sheet, w * h))
    write_cache(cache, root .. "/" .. blob.file .. ".rgba", G.rgbaString(sheet, w * h, pals[blob.pal]))
    out.blobs[blob.key] = {
      file = blob.file .. ".rgba",
      idx = blob.file .. ".idx",
      raw = blob.file .. ".4bpp",
      symbol = G.symName(S, blob.tiles),
      w = w,
      h = h,
      tiles = tiles,
      frame_w = t.oam.w,
      frame_h = t.oam.h,
      palette = blob.pal,
      paletteTag = t.paletteTag,
    }
  end
  out.fog_h = { file = out.blobs.fog_h.file, w = out.blobs.fog_h.w, h = out.blobs.fog_h.h }
  out.rain = { file = out.blobs.rain.file, w = out.blobs.rain.w, h = out.blobs.rain.h }
  local types = {}
  for i = 0, W.color_map_types_size - 1 do types[i + 1] = rom:get(W.color_map_types + i) end
  out.color_map_types = types
  local drought, tableCount
  if W.drought_compressed then
    -- pokeruby/src/field_weather.c:999
    local Lz = require("src.import.gba.lz77")
    local previous, parts = {}, {}
    for t, off in ipairs(W.drought_compressed) do
      local data = Lz.decompress(function(i) return rom:get(i) end, off)
      assert(Lz.len(data) == 0x2000, "RS drought palette has an invalid decompressed size")
      local row, bytes = {}, {}
      for i = 0, 0xFFF do
        local delta = data[i * 2 + 1] + data[i * 2 + 2] * 256
        local value = t == 1 and (i == 0 and 0x421 or (delta + row[i - 1]) % 65536)
          or (delta + previous[i]) % 65536
        row[i] = value
        bytes[i + 1] = string.char(value % 256, math.floor(value / 256))
      end
      previous = row
      parts[t] = table.concat(bytes)
    end
    drought, tableCount = table.concat(parts), #parts
  else
    drought, tableCount = rom:readString(W.drought_colors, W.drought_colors_size), W.drought_colors_size / 0x2000
  end
  write_cache(cache, root .. "/drought_colors.bin", drought)
  out.drought = { file = "drought_colors.bin", tables = tableCount, entries = 0x1000 }
  out.cycles = {}
  for name, c in pairs(W.cycles) do
    local list = {}
    for i = 0, c.count - 1 do list[i + 1] = rom:get(c.off + i) end
    out.cycles[name] = list
  end
  write_cache(cache, root .. "/manifest.lua", "return " .. serialize(out) .. "\n")
  return { format = WeatherExtract.RSE_FORMAT, blobs = #W.blobs }
end

function WeatherExtract.ready(cache, cacheRoot)
  local root = (cacheRoot or default_cache_root()) .. "/" .. WeatherExtract.CACHE_SUB
  if not (cache and cache.read) then return false end
  if Versions.FAMILY == "rse" then
    local body = cache:read(root .. "/manifest.lua")
    if type(body) ~= "string" or #body == 0 then return false end
    local ok, m = pcall(load(body, "=weather", "t", {}) or error)
    return ok and type(m) == "table" and m.family == "rse" and m.format == WeatherExtract.RSE_FORMAT
  end
  local fog = cache:read(root .. "/fog_horizontal.rgba")
  return type(fog) == "string" and #fog == 64 * 64 * 4
end

function WeatherExtract.run(rom, cache, opts)
  opts = opts or {}
  local root = (opts.cacheRoot or default_cache_root()) .. "/" .. WeatherExtract.CACHE_SUB
  if Versions.FAMILY == "rse" then return WeatherExtract.runRse(rom, cache, root) end
  local cfg = opts.offsets or {}
  local blobs = WeatherExtract.readBlobs(rom, cfg)

  for _, blob in ipairs(WeatherExtract.BLOBS) do
    write_cache(cache, root .. "/" .. blob.rel, blobs[blob.key])
  end

  local fogRgba, fogW, fogH = WeatherExtract.bakeSheet(blobs.fog_h_gfx, blobs.default_pal, 8)
  write_cache(cache, root .. "/fog_horizontal.rgba", fogRgba)

  local rainRgba, rainW, rainH = WeatherExtract.bakeSheet(blobs.rain_gfx, blobs.default_pal, 2)
  write_cache(cache, root .. "/rain.rgba", rainRgba)

  write_cache(cache, root .. "/manifest.lua", string.format([[
return {
  format = %d,
  fog_h = { file = "fog_horizontal.rgba", w = %d, h = %d },
  rain = { file = "rain.rgba", w = %d, h = %d },
}
]], WeatherExtract.FORMAT_VERSION, fogW, fogH, rainW, rainH))

  return { format = WeatherExtract.FORMAT_VERSION }
end

return WeatherExtract
