local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")

local M = {}

M.FILE = "decorations/decorations.lua"
M.ICONS = "decorations/icons.rgba"
M.REQUIRED = { M.FILE, M.ICONS }

local BgBake = require("src.import.gba.bg_bake")
local Lz77 = require("src.import.gba.lz77")

local function lz(rom, off)
  local out = Lz77.decompress(function(i) return rom:get(i) end, off)
  out._len = Lz77.len(out)
  return out
end

-- pokeemerald/src/decoration.c:2003
function M.icons(rom)
  local D = Versions.DECORATIONS
  local out = {}
  for i = 0, D.count - 1 do
    local e = D.icons + i * 8
    local tp, pp = rom:ptrOffset(rom:u32(e)), rom:ptrOffset(rom:u32(e + 4))
    if tp and pp then
      local tiles = lz(rom, tp)
      local pal = BgBake.loadPalBanks(lz(rom, pp), 1)[0]
      out[#out + 1] = BgBake.bakeSpriteRgba(tiles, pal, 0, 24, 24, false, false)
    else
      out[#out + 1] = string.rep("\0", 24 * 24 * 4)
    end
  end
  return table.concat(out)
end

local function read_string(rom, off, maxLen)
  local bytes = {}
  for i = 0, maxLen - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  if bytes[#bytes] ~= 0xFF then bytes[#bytes + 1] = 0xFF end
  return TextIR.toPlain(TextIR.decode(bytes), {})
end

-- pokeemerald/include/decoration.h:43
function M.extract(rom)
  local D = assert(Versions.DECORATIONS, "DECORATIONS keys missing for this game")
  local out = {}
  for i = 0, D.count - 1 do
    local e = D.table + i * D.stride
    local descOff = rom:ptrOffset(rom:u32(e + 24))
    out[i] = {
      id = rom:get(e),
      name = read_string(rom, e + 1, 16),
      permission = rom:get(e + 17),
      shape = rom:get(e + 18),
      category = rom:get(e + 19),
      price = rom:u16(e + 20),
      description = descOff and read_string(rom, descOff, 256) or "",
    }
  end
  local cats = {}
  for i = 0, D.categoryCount - 1 do
    local p = rom:ptrOffset(rom:u32(D.categoryNames + i * 4))
    cats[i] = p and read_string(rom, p, 32) or ""
  end
  return out, cats
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local list, cats = M.extract(rom)
  local rel = (opts.cacheRoot or "data/generated/gba") .. "/" .. M.FILE
  assert(cache:write(rel, "return " .. serialize({
    format_version = 1,
    count = Versions.DECORATIONS.count,
    decorations = list,
    categoryNames = cats,
    iconSize = 24,
    icons = "icons.rgba",
  }) .. "\n"), "could not write " .. rel)
  assert(cache:write((opts.cacheRoot or "data/generated/gba") .. "/" .. M.ICONS, M.icons(rom)))
  return { ok = true, path = rel }
end

function M.ready(cache, cacheRoot)
  if not (cache and cache.exists) then return false end
  local root = cacheRoot or "data/generated/gba"
  return cache:exists(root .. "/" .. M.FILE) and cache:exists(root .. "/" .. M.ICONS)
end

return M
