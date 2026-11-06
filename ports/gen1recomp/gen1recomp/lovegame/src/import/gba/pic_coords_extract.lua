local Versions = require("src.import.gba.versions")

local PicCoordsExtract = {}

PicCoordsExtract.FORMAT_VERSION = 1
PicCoordsExtract.CACHE_FILE = "pokemon/pic_coords.lua"
PicCoordsExtract.REQUIRED = { PicCoordsExtract.CACHE_FILE }

local function need(keys, field, key)
  local v = keys[field]
  if v == nil then v = Versions[key] end
  if v == nil then
    error("pic_coords_extract: Versions." .. key .. " is not set for " .. tostring(Versions.active()))
  end
  return v
end

-- pokeemerald/include/data.h:23
local function coords(rom, base, sp, stride)
  local size = rom:get(base + sp * stride)
  return {
    size = size,
    width = math.floor(size / 16) * 8,
    height = (size % 16) * 8,
    y = rom:get(base + sp * stride + 1),
  }
end

function PicCoordsExtract.extract(rom, keys)
  keys = keys or {}
  local frontBase = need(keys, "front", "MON_FRONT_PIC_COORDS")
  local backBase = need(keys, "back", "MON_BACK_PIC_COORDS")
  local elevBase = need(keys, "elevation", "ENEMY_MON_ELEVATION")
  local count = need(keys, "count", "MON_PIC_COORDS_COUNT")
  local stride = need(keys, "stride", "MON_PIC_COORDS_STRIDE")
  local elevCount = need(keys, "elevationCount", "ENEMY_MON_ELEVATION_COUNT")
  local pack = { count = count, elevationCount = elevCount, front = {}, back = {}, elevation = {} }
  for sp = 0, count - 1 do
    pack.front[sp] = coords(rom, frontBase, sp, stride)
    pack.back[sp] = coords(rom, backBase, sp, stride)
  end
  -- pokeemerald/src/data/pokemon_graphics/enemy_mon_elevation.h:3
  for sp = 0, elevCount - 1 do
    pack.elevation[sp] = rom:get(elevBase + sp)
  end
  return pack
end

function PicCoordsExtract.toLua(pack)
  local lines = {
    "return {",
    string.format("  format = %d,", PicCoordsExtract.FORMAT_VERSION),
    string.format("  count = %d,", pack.count),
    string.format("  elevationCount = %d,", pack.elevationCount),
  }
  for _, side in ipairs({ "front", "back" }) do
    lines[#lines + 1] = "  " .. side .. " = {"
    for sp = 0, pack.count - 1 do
      local c = pack[side][sp]
      lines[#lines + 1] = string.format("    [%d] = { size = %d, width = %d, height = %d, y = %d },",
        sp, c.size, c.width, c.height, c.y)
    end
    lines[#lines + 1] = "  },"
  end
  lines[#lines + 1] = "  elevation = {"
  for sp = 0, pack.elevationCount - 1 do
    lines[#lines + 1] = string.format("    [%d] = %d,", sp, pack.elevation[sp])
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

function PicCoordsExtract.run(rom, cache, opts)
  opts = opts or {}
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. PicCoordsExtract.CACHE_FILE
  local pack = PicCoordsExtract.extract(rom, opts.keys)
  local ok, err = cache:write(rel, PicCoordsExtract.toLua(pack))
  if ok == false then error("pic_coords_extract: could not write " .. rel .. ": " .. tostring(err)) end
  return { path = rel, count = pack.count }
end

function PicCoordsExtract.ready(cache, cacheRoot)
  local rel = (cacheRoot or "data/generated/gba") .. "/" .. PicCoordsExtract.CACHE_FILE
  if not (cache and cache.read) then return false end
  local body = cache:read(rel)
  return type(body) == "string"
    and tonumber(body:match("format = (%d+)")) == PicCoordsExtract.FORMAT_VERSION
end

return PicCoordsExtract
