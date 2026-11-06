local Kit = require("src.ui.game3.rse.scene_kit")
local CacheBlob = require("src.import.CacheBlob")

local Gfx = {}

Gfx.SUB = "data/generated/gba/rse/pokedex"

local manifest
local gfxBytes, mapCache, orders = {}, {}, nil

local function readCache(path)
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  local data = okC and CacheFs and CacheFs.read and CacheFs.read(path) or nil
  if not data and love and love.filesystem and love.filesystem.getInfo(path) then
    data = CacheBlob.readFs(path)
  end
  return data
end
Gfx.readCache = readCache

function Gfx.manifest()
  if manifest then return manifest end
  manifest = assert(Kit.loadLua(Gfx.SUB .. "/manifest.lua"), "rse pokedex manifest missing from the cache")
  if manifest.assetLayout == "rs" then
    local detail = assert(Kit.loadLua("data/generated/gba/rse/pokedex_detail/manifest.lua"), "native RS pokedex detail pack missing")
    assert(detail.assetLayout == "rs", "native RS pokedex detail pack has the wrong layout")
    for key, value in pairs(detail) do
      if key == "gfx" or key == "maps" or key == "palettes" then
        for name, row in pairs(value) do manifest[key][name] = row end
      elseif key ~= "files" then manifest[key] = value end
    end
  end
  return manifest
end

function Gfx.orders()
  if orders then return orders end
  orders = assert(Kit.loadLua(Gfx.SUB .. "/orders.lua"), "rse pokedex orders missing from the cache")
  return orders
end

function Gfx.reset()
  manifest, orders = nil, nil
  gfxBytes, mapCache = {}, {}
end

function Gfx.bytes(key)
  local hit = gfxBytes[key]
  if hit then return hit end
  local entry = assert(Gfx.manifest().gfx[key], "rse pokedex: no gfx " .. tostring(key))
  hit = assert(readCache(entry.path), "rse pokedex: missing " .. entry.path)
  gfxBytes[key] = hit
  return hit
end

function Gfx.map(key)
  local hit = mapCache[key]
  if not hit then
    local entry = assert(Gfx.manifest().maps[key], "rse pokedex: no tilemap " .. tostring(key))
    local data = assert(readCache(entry.path), "rse pokedex: missing " .. entry.path)
    hit = {}
    for i = 0, #data / 2 - 1 do
      local lo, hi = data:byte(i * 2 + 1, i * 2 + 2)
      hit[i] = lo + hi * 256
    end
    hit.n = #data / 2
    mapCache[key] = hit
  end
  local copy = { n = hit.n }
  for i = 0, hit.n - 1 do copy[i] = hit[i] end
  return copy
end

function Gfx.sine(i)
  return Gfx.manifest().sine[i % 256]
end

function Gfx.rgb8(c)
  c = (tonumber(c) or 0) % 32768
  return math.floor((c % 32) * 255 / 31 + 0.5) / 255,
    math.floor((math.floor(c / 32) % 32) * 255 / 31 + 0.5) / 255,
    math.floor((math.floor(c / 1024) % 32) * 255 / 31 + 0.5) / 255
end

function Gfx.color(c, a)
  local r, g, b = Gfx.rgb8(c)
  return { r, g, b, a or 1 }
end

-- pokeemerald/src/pokedex.c:2147
function Gfx.bgPalette(set)
  local man = Gfx.manifest()
  local pal = {}
  for i = 0, 255 do pal[i] = 0 end
  local src = man.palettes[set or "hoenn"]
  for i = 1, #src - 1 do pal[i] = src[i + 1] end
  local mb = man.palettes.messageBox
  for i = 0, 15 do pal[240 + i] = mb[i + 1] end
  return pal
end

function Gfx.loadPalette(pal, key, dest, first, count)
  local src = Gfx.manifest().palettes[key]
  first = first or 0
  count = count or (#src - first)
  for i = 0, count - 1 do pal[dest + i] = src[first + i + 1] end
  return pal
end

local function newData(w, h)
  local data = love.image.newImageData(w, h)
  local ok, ptr = pcall(function() return data:getFFIPointer() end)
  if ok and ptr then
    local ffi = require("ffi")
    return data, ffi.cast("uint8_t*", ptr)
  end
  return data, nil
end

local function toImage(data)
  local img = love.graphics.newImage(data)
  img:setFilter("nearest", "nearest")
  return img
end

local function rgbTable(pal)
  local t = {}
  for i = 0, 255 do
    local r, g, b = Gfx.rgb8(pal[i] or 0)
    t[i] = { math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5) }
  end
  return t
end

-- pokeemerald/include/gba/io_reg.h:540
function Gfx.renderMap(entries, gfxKey, pal, opts)
  opts = opts or {}
  local width = opts.width or 32
  local rows = opts.rows or math.floor(entries.n / width)
  local gfx = Gfx.bytes(gfxKey)
  local tiles = math.floor(#gfx / 32)
  local tileBase = opts.tileBase or 0
  local W, H = width * 8, rows * 8
  local data, ptr = newData(W, H)
  local rgb = rgbTable(pal)
  for ty = 0, rows - 1 do
    for tx = 0, width - 1 do
      local e = entries[ty * width + tx] or 0
      local tile = e % 1024 - tileBase
      local hf = math.floor(e / 1024) % 2 == 1
      local vf = math.floor(e / 2048) % 2 == 1
      local bank = math.floor(e / 4096) % 16
      if tile >= 0 and tile < tiles then
        for py = 0, 7 do
          local sy = vf and (7 - py) or py
          for px = 0, 7 do
            local sx = hf and (7 - px) or px
            local b = gfx:byte(tile * 32 + sy * 4 + math.floor(sx / 2) + 1) or 0
            local v = (sx % 2 == 0) and (b % 16) or math.floor(b / 16)
            if v ~= 0 then
              local c = rgb[bank * 16 + v]
              local x, y = tx * 8 + px, ty * 8 + py
              if ptr then
                local o = (y * W + x) * 4
                ptr[o], ptr[o + 1], ptr[o + 2], ptr[o + 3] = c[1], c[2], c[3], 255
              else
                data:setPixel(x, y, c[1] / 255, c[2] / 255, c[3] / 255, 1)
              end
            end
          end
        end
      end
    end
  end
  return toImage(data)
end

function Gfx.renderMap8(entries, gfxKey, pal, opts)
  opts = opts or {}
  local width = opts.width or 32
  local rows = opts.rows or math.floor(entries.n / width)
  local gfx = Gfx.bytes(gfxKey)
  local tiles = math.floor(#gfx / 64)
  local W, H = width * 8, rows * 8
  local data, ptr = newData(W, H)
  local rgb = rgbTable(pal)
  for ty = 0, rows - 1 do
    for tx = 0, width - 1 do
      local e = entries[ty * width + tx] or 0
      local tile = e % 1024
      local hf = math.floor(e / 1024) % 2 == 1
      local vf = math.floor(e / 2048) % 2 == 1
      if tile < tiles then
        for py = 0, 7 do
          local sy = vf and (7 - py) or py
          for px = 0, 7 do
            local sx = hf and (7 - px) or px
            local v = gfx:byte(tile * 64 + sy * 8 + sx + 1) or 0
            if v ~= 0 then
              local c = rgb[v]
              local x, y = tx * 8 + px, ty * 8 + py
              if ptr then
                local o = (y * W + x) * 4
                ptr[o], ptr[o + 1], ptr[o + 2], ptr[o + 3] = c[1], c[2], c[3], 255
              else
                data:setPixel(x, y, c[1] / 255, c[2] / 255, c[3] / 255, 1)
              end
            end
          end
        end
      end
    end
  end
  return toImage(data)
end

local spriteCache = {}

-- pokeemerald/include/gba/io_reg.h:512
function Gfx.sprite(gfxKey, tile, w, h, pal16, opts)
  opts = opts or {}
  local key = table.concat({ gfxKey, tile, w, h, table.concat(pal16, ",", 1, 16), opts.fill and 1 or 0 }, "|")
  local hit = spriteCache[key]
  if hit then return hit end
  local gfx = Gfx.bytes(gfxKey)
  local data, ptr = newData(w, h)
  local tw = w / 8
  for ty = 0, h / 8 - 1 do
    for tx = 0, tw - 1 do
      local t = tile + ty * tw + tx
      for py = 0, 7 do
        for px = 0, 7 do
          local b = gfx:byte(t * 32 + py * 4 + math.floor(px / 2) + 1) or 0
          local v = (px % 2 == 0) and (b % 16) or math.floor(b / 16)
          if v ~= 0 or opts.fill then
            local r, g, bl = Gfx.rgb8(pal16[v + 1])
            local x, y = tx * 8 + px, ty * 8 + py
            if ptr then
              local o = (y * w + x) * 4
              ptr[o], ptr[o + 1], ptr[o + 2], ptr[o + 3] = r * 255 + 0.5, g * 255 + 0.5, bl * 255 + 0.5, 255
            else
              data:setPixel(x, y, r, g, bl, 1)
            end
          end
        end
      end
    end
  end
  hit = toImage(data)
  spriteCache[key] = hit
  return hit
end

function Gfx.resetSprites()
  spriteCache = {}
end

return Gfx
