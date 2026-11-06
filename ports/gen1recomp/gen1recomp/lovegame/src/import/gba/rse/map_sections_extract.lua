local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")
local GameVersion = require("src.core.GameVersion")
local Constants = require("src.core.game3.constants")
local G = require("src.import.gba.rse.sprite_gfx")

local M = {}

M.FORMAT_VERSION = 1
M.SECTIONS_REL = "region_map/map_sections.lua"
M.POPUP_SUB = "chrome/map_popup"
M.POPUP_W = 80
M.POPUP_H = 24
M.NAME_MAX = 32

-- pokeemerald/src/map_name_popup.c:21
M.THEMES = { "wood", "marble", "stone", "brick", "underwater", "stone2" }

M.REQUIRED = { M.SECTIONS_REL, M.POPUP_SUB .. "/manifest.lua" }
for _, theme in ipairs(M.THEMES) do
  for _, suffix in ipairs({ "", "_outline" }) do
    M.REQUIRED[#M.REQUIRED + 1] = M.POPUP_SUB .. "/" .. theme .. suffix .. ".rgba"
    M.REQUIRED[#M.REQUIRED + 1] = M.POPUP_SUB .. "/" .. theme .. suffix .. ".idx"
  end
end

local function rom_off(ptr)
  if ptr >= 0x08000000 and ptr < 0x0A000000 then return ptr - 0x08000000 end
  return nil
end

local function read_name(rom, off)
  local bytes = {}
  for i = 0, M.NAME_MAX - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = TextIR.dialectOf() }), {})
end

local function section_id(sec)
  local C = Constants.of(GameVersion.get())
  if not C.region_map_sections then return nil end
  return C:name("region_map_sections", sec, "MAPSEC_")
end

-- pokeemerald/src/map_name_popup.c:409
function M.themeIndex(sec, kantoStart, kantoCount)
  if sec >= kantoStart then
    if sec > kantoStart + kantoCount - 1 then
      return sec - kantoCount
    end
    return 0
  end
  return sec
end

-- pokeemerald/src/data/region_map/region_map_entries.h:207
function M.readSections(rom)
  local base = Versions.REGION_MAP_ENTRIES
  local count = Versions.REGION_MAP_ENTRY_COUNT
  local themeBase = Versions.MAPSEC_THEME_IDS
  local themeCount = Versions.MAPSEC_THEME_COUNT
  local kStart, kCount = Versions.KANTO_MAPSEC_START, Versions.KANTO_MAPSEC_COUNT
  local sections = {}
  for sec = 0, count - 1 do
    local o = base + sec * 8
    local nameOff = rom_off(rom:u32(o + 4))
    local ti = M.themeIndex(sec, kStart, kCount)
    local themeId = ti < themeCount and rom:get(themeBase + ti) or nil
    sections[sec] = {
      id = section_id(sec),
      name = nameOff and read_name(rom, nameOff) or "",
      theme = themeId and M.THEMES[themeId + 1] or nil,
      themeId = themeId,
      x = rom:get(o), y = rom:get(o + 1),
      width = rom:get(o + 2), height = rom:get(o + 3),
    }
  end
  return sections
end

local function fmt_section(sec, s)
  local parts = {}
  if s.id then parts[#parts + 1] = ("id = %q"):format(s.id) end
  parts[#parts + 1] = ("name = %q"):format(s.name)
  if s.theme then
    parts[#parts + 1] = ("theme = %q"):format(s.theme)
    parts[#parts + 1] = ("themeId = %d"):format(s.themeId)
  end
  parts[#parts + 1] = ("x = %d, y = %d, width = %d, height = %d"):format(s.x, s.y, s.width, s.height)
  return ("    [%d] = { %s },"):format(sec, table.concat(parts, ", "))
end

function M.formatSections(sections, count)
  local lines = {
    "-- Generated map sections (gRegionMapEntries, sMapSectionToThemeId).",
    "return {",
    ("  format_version = %d,"):format(M.FORMAT_VERSION),
    ("  count = %d,"):format(count),
    ("  KANTO_MAPSEC_START = %d,"):format(Versions.KANTO_MAPSEC_START),
    ("  KANTO_MAPSEC_COUNT = %d,"):format(Versions.KANTO_MAPSEC_COUNT),
    "  themes = { \"" .. table.concat(M.THEMES, "\", \"") .. "\" },",
    "  sections = {",
  }
  for sec = 0, count - 1 do lines[#lines + 1] = fmt_section(sec, sections[sec]) end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

local function pal_list(pal)
  local t = {}
  for i = 0, 15 do t[#t + 1] = tostring(pal[i]) end
  return "{ " .. table.concat(t, ", ") .. " }"
end

-- pokeemerald/src/map_name_popup.c:403
function M.writePopup(rom, cache, root)
  local P = Versions.MAP_POPUP
  local W, H = M.POPUP_W, M.POPUP_H
  local n = W * H
  assert(P.frameBytes == n / 2, "map popup frame size mismatch")
  local dir = root .. "/" .. M.POPUP_SUB
  local pals = {}
  for t = 0, P.themeCount - 1 do
    local name = M.THEMES[t + 1]
    local pal = G.readPalette(rom, P.palettes + t * 32)
    pals[name] = pal
    for _, layer in ipairs({ { "", P.frames }, { "_outline", P.outlines } }) do
      local pix = G.decodeTiles(rom, layer[2] + t * P.frameBytes, W, H, {})
      cache:write(dir .. "/" .. name .. layer[1] .. ".idx", G.idxString(pix, n))
      cache:write(dir .. "/" .. name .. layer[1] .. ".rgba", G.rgbaString(pix, n, pal))
    end
  end
  local lines = {
    "return {",
    ("  format_version = %d,"):format(M.FORMAT_VERSION),
    ("  width = %d,"):format(W),
    ("  height = %d,"):format(H),
    "  themes = { \"" .. table.concat(M.THEMES, "\", \"") .. "\" },",
    "  palettes = {",
  }
  for _, name in ipairs(M.THEMES) do
    lines[#lines + 1] = ("    %s = %s,"):format(name, pal_list(pals[name]))
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  underwaterPalette = " .. pal_list(G.readPalette(rom, P.underwaterPalette)) .. ","
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  cache:write(dir .. "/manifest.lua", table.concat(lines, "\n"))
  return P.themeCount
end

function M.ready(cache, cacheRoot)
  if not (cache and cache.exists) then return false end
  for _, rel in ipairs(M.REQUIRED) do
    if not cache:exists(cacheRoot .. "/" .. rel) then return false end
  end
  return true
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local sections = M.readSections(rom)
  local count = Versions.REGION_MAP_ENTRY_COUNT
  cache:write(root .. "/" .. M.SECTIONS_REL, M.formatSections(sections, count))
  local themes = M.writePopup(rom, cache, root)
  return { sections = count, themes = themes }
end

function M.load(src)
  local chunk = assert(load(src, "@map_sections.lua", "t", {}))
  return chunk()
end

function M.themeOf(pack, sec)
  local s = pack.sections[sec]
  if s and s.theme then return s.theme end
  local ti = M.themeIndex(sec, pack.KANTO_MAPSEC_START, pack.KANTO_MAPSEC_COUNT)
  local row = pack.sections[ti]
  return row and row.theme or nil
end

return M
