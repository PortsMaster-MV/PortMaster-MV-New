local Versions = require("src.import.gba.versions")
local BgBake = require("src.import.gba.bg_bake")
local Lz77 = require("src.import.gba.lz77")
local TextIR = require("src.core.game3.scripting.text_ir")

local M = {}

M.SUB = "credits_rse"
M.FORMAT_VERSION = 1
M.REQUIRED = { "credits_rse/manifest.lua", "credits_rse/the_end.rgba", "credits_rse/grass.rgba" }

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

local function read_string(rom, off)
  local bytes = {}
  for i = 0, 255 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes), {})
end

local function map_bytes(entries)
  local map = {}
  for i = 0, 32 * 32 - 1 do
    local e = entries[i] or 0
    map[i * 2 + 1] = e % 256
    map[i * 2 + 2] = math.floor(e / 256)
  end
  map._len = 32 * 32 * 2
  return map
end

-- pokeemerald/src/credits.c:1253
local function letter_tile(b)
  if b == 0xFF then return 1 end
  local out = (b % 64) + 80
  if math.floor(b / 128) % 2 == 1 then out = out + 2048 end
  if math.floor(b / 64) % 2 == 1 then out = out + 1024 end
  return out
end

-- pokeemerald/src/credits.c:1280
local function the_end_map(rom, C)
  local entries = {}
  for i = 0, 32 * 32 - 1 do entries[i] = 1 end
  local letters = { { C.letterT, 3 }, { C.letterH, 7 }, { C.letterE, 11 }, { C.letterE, 16 }, { C.letterN, 20 }, { C.letterD, 24 } }
  for _, l in ipairs(letters) do
    for y = 0, 4 do
      for x = 0, 2 do
        entries[(7 + y) * 32 + l[2] + x] = letter_tile(rom:get(l[1] + y * 3 + x))
      end
    end
  end
  return map_bytes(entries)
end

-- pokeemerald/include/sprite.h:21
local function anim_table(rom, off, count, tilesPerFrame)
  local rows = {}
  for i = 0, count - 1 do
    local p = rom:ptrOffset(rom:u32(off + i * 4))
    local cmds = {}
    for c = 0, 63 do
      local lo, hi = rom:u16(p + c * 4), rom:u16(p + c * 4 + 2)
      if lo == 0xFFFF then
        cmds[#cmds + 1] = "{ op = \"end\" }"
        break
      elseif lo == 0xFFFE then
        cmds[#cmds + 1] = string.format("{ op = \"jump\", target = %d }", hi % 64)
        break
      else
        cmds[#cmds + 1] = string.format("{ op = \"frame\", frame = %d, duration = %d }", math.floor(lo / tilesPerFrame), hi % 64)
      end
    end
    rows[#rows + 1] = "    { " .. table.concat(cmds, ", ") .. " },"
  end
  return table.concat(rows, "\n")
end

local function opaque(rgba, backdrop)
  local out = {}
  for i = 1, #rgba, 4 do
    if rgba:byte(i + 3) == 0 then out[#out + 1] = backdrop else out[#out + 1] = rgba:sub(i, i + 3) end
  end
  return table.concat(out)
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = (opts.cacheRoot or "data/generated/gba") .. "/" .. M.SUB
  local C = assert(Versions.CREDITS_RSE, "CREDITS_RSE keys missing for this game")
  local function put(name, body) assert(cache:write(root .. "/" .. name, body)) end

  local pages = {}
  for p = 0, C.pageCount - 1 do
    local rows = {}
    for e = 0, C.entriesPerPage - 1 do
      local ptr = rom:ptrOffset(rom:u32(C.pages + (p * C.entriesPerPage + e) * 4))
      local textPtr = rom:ptrOffset(rom:u32(ptr + 4))
      rows[#rows + 1] = string.format("{ isTitle = %s, text = %q }", tostring(rom:get(ptr + 1) ~= 0),
        textPtr and read_string(rom, textPtr) or "")
    end
    pages[#pages + 1] = "    { " .. table.concat(rows, ", ") .. " },"
  end
  local pal = {}
  for i = 0, 31 do pal[#pal + 1] = string.format("0x%04X", rom:u16(C.palette + i * 2)) end

  -- pokeemerald/src/credits.c:1238
  local copyPal = BgBake.loadPalBanks(raw(rom, C.copyrightPal, 32), 1)
  local endGfx = lz(rom, C.theEndGfx)
  local r, g, b = BgBake.bgr555ToRgb8(copyPal[0][0])
  local backdrop = string.char(r, g, b, 255)
  put("the_end.rgba", opaque(BgBake.bakeRegionRgba(endGfx, copyPal, the_end_map(rom, C), W, H, { alpha0 = true }), backdrop))
  local blankEntries = {}
  for i = 0, 32 * 32 - 1 do blankEntries[i] = 1 end
  put("the_end_blank.rgba", opaque(BgBake.bakeRegionRgba(endGfx, copyPal, map_bytes(blankEntries), W, H, { alpha0 = true }), backdrop))

  -- pokeemerald/src/credits.c:547
  local grassGfx = lz(rom, C.grassGfx)
  local grassMap = lz(rom, C.grassMap)
  local grassPal = raw(rom, C.grassPal, 64)
  grassPal[1], grassPal[2] = 0, 0
  local banks = BgBake.loadPalBanks(grassPal, 2)
  put("grass.rgba", opaque(BgBake.bakeRegionRgba(grassGfx, banks, grassMap, W, H, { y0 = 32, alpha0 = true }), "\0\0\0\255"))

  put("manifest.lua", table.concat({
    "return {",
    string.format("  format_version = %d,", M.FORMAT_VERSION),
    string.format("  pageCount = %d,", C.pageCount),
    string.format("  entriesPerPage = %d,", C.entriesPerPage),
    "  palette = { " .. table.concat(pal, ", ") .. " },",
    "  pages = {",
    table.concat(pages, "\n"),
    "  },",
    "  animsPlayer = {",
    anim_table(rom, C.animsPlayer, C.animsPlayerCount, 64),
    "  },",
    "  animsRival = {",
    anim_table(rom, C.animsRival, C.animsRivalCount, 64),
    "  },",
    "  monSpritePos = { " .. (function()
      local out = {}
      for i = 0, C.monSpritePosCount - 1 do
        out[#out + 1] = string.format("{ %d, %d }", rom:get(C.monSpritePos + i * 2), rom:get(C.monSpritePos + i * 2 + 1))
      end
      return table.concat(out, ", ")
    end)() .. " },",
    "  theEnd = \"the_end.rgba\",",
    "  theEndBlank = \"the_end_blank.rgba\",",
    "  grass = \"grass.rgba\",",
    "}",
    "",
  }, "\n"))
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
