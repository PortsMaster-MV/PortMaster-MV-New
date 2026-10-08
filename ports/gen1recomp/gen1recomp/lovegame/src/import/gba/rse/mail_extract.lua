local Versions = require("src.import.gba.versions")
local BgBake = require("src.import.gba.bg_bake")
local Lz77 = require("src.import.gba.lz77")

local M = {}

M.SUB = "mail"
M.FORMAT_VERSION = 1
M.REQUIRED = { "mail/manifest.lua" }

local W, H = 240, 160

local function lz(rom, off)
  local out = Lz77.decompress(function(i) return rom:get(i) end, off)
  out._len = Lz77.len(out)
  return out
end

local function ptr(rom, off)
  return assert(rom:ptrOffset(rom:u32(off)), string.format("bad pointer at 0x%X", off))
end

local function palette(rom, off)
  local p = {}
  for i = 0, 15 do p[i] = rom:u16(off + i * 2) end
  return p
end

local function fill_map(tile)
  local map = {}
  for i = 0, 32 * 32 - 1 do
    map[i * 2 + 1] = tile % 256
    map[i * 2 + 2] = math.floor(tile / 256)
  end
  map._len = 32 * 32 * 2
  return map
end

-- pokeemerald/src/mail.c:540
local function bake(gfx, pal, map, bgColors)
  local banks = { [0] = {} }
  for i = 0, 15 do banks[0][i] = pal[i] end
  banks[0][10], banks[0][11] = bgColors[1], bgColors[2]
  local i1, p1 = BgBake.regionIndices(gfx, map, W, H, {})
  local i2, p2 = BgBake.regionIndices(gfx, fill_map(1), W, H, {})
  local chunks = {}
  for i = 1, W * H do
    local c
    if p1[i] >= 0 and i1[i] ~= 0 then
      c = (banks[p1[i]] or banks[0])[i1[i]]
    elseif p2[i] >= 0 and i2[i] ~= 0 then
      c = banks[0][i2[i]]
    else
      c = banks[0][0]
    end
    local r, g, b = BgBake.bgr555ToRgb8(c or 0)
    chunks[i] = string.char(r, g, b, 255)
  end
  return table.concat(chunks)
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = (opts.cacheRoot or "data/generated/gba") .. "/" .. M.SUB
  local C = require("src.core.game3.constants").of(require("src.core.GameVersion").get())
  local bgOff = Versions.MAIL_BG_COLORS
  -- pokeemerald/src/mail.c:112
  local genders = {
    { rom:u16(bgOff), rom:u16(bgOff + 2) },
    { rom:u16(bgOff + 4), rom:u16(bgOff + 6) },
  }
  local lines = { "return {", string.format("  format_version = %d,", M.FORMAT_VERSION),
    string.format("  width = %d,", W), string.format("  height = %d,", H),
    string.format("  firstMailItem = %d,", C:require("items", "ITEM_ORANGE_MAIL")), "  designs = {" }
  for d = 0, Versions.MAIL_GRAPHICS_COUNT - 1 do
    local e = Versions.MAIL_GRAPHICS + d * 20
    local pal = palette(rom, ptr(rom, e))
    local gfx = lz(rom, ptr(rom, e + 4))
    local map = lz(rom, ptr(rom, e + 8))
    local files = {}
    for g = 1, 2 do
      local file = string.format("design_%02d_%d.rgba", d, g - 1)
      assert(cache:write(root .. "/" .. file, bake(gfx, pal, map, genders[g])))
      files[g] = string.format("%q", file)
    end
    lines[#lines + 1] = string.format("    [%d] = { files = { %s }, textColor = 0x%04X, textShadow = 0x%04X },",
      d, table.concat(files, ", "), rom:u16(e + 16), rom:u16(e + 18))
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  layouts = {"
  for d = 0, Versions.MAIL_GRAPHICS_COUNT - 1 do
    local e = Versions.MAIL_LAYOUTS_TALL + d * 12
    local n = rom:get(e)
    local lp = ptr(rom, e + 8)
    local rows = {}
    for i = 0, n - 1 do
      local b = rom:get(lp + i * 4)
      rows[#rows + 1] = string.format("{ words = %d, xOffset = %d, height = %d }",
        b % 4, math.floor(b / 4), rom:get(lp + i * 4 + 1))
    end
    lines[#lines + 1] = string.format(
      "    [%d] = { signatureYPos = %d, signatureWidth = %d, wordsYPos = %d, wordsXPos = %d, lines = { %s } },",
      d, rom:get(e + 1), rom:get(e + 2), rom:get(e + 3), rom:get(e + 4), table.concat(rows, ", "))
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  assert(cache:write(root .. "/manifest.lua", table.concat(lines, "\n")))
  return { root = root }
end

function M.ready(cache, cacheRoot)
  if not (cache and cache.exists) then return false end
  return cache:exists((cacheRoot or "data/generated/gba") .. "/" .. M.REQUIRED[1])
end

return M
