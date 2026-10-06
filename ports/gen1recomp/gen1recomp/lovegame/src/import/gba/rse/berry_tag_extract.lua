local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/berry_tag"

M.GFX = {
  check = { "gBerryCheck_Gfx", true },
  circle = { "gBerryCheckCircle_Gfx", true },
}

M.MAPS = {
  tag = "gBerryTag_Gfx",
  title = "gBerryTag_Tilemap",
}

M.FILES = { "berries.gfx" }
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
for k in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/src/item_menu_icons.c:590
local PIC_BYTES = 6 * 6 * 32

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  local gfx = {}
  for key, spec in pairs(M.GFX) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    c:write(key .. ".gfx", data)
    gfx[key] = { path = c:path(key .. ".gfx"), bytes = #data }
  end
  local maps = {}
  for key, sym in pairs(M.MAPS) do
    local data = c:lz(sym)
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end

  -- pokeemerald/src/item_menu_icons.c:327
  local T = "item_menu_icons.o:sBerryPicTable"
  local to = c:off(T)
  local pics, pals = {}, {}
  for i = 0, c.S.size(T) / 8 - 1 do
    local tiles = c:lzAt(c:ptr(to + i * 8))
    assert(#tiles >= PIC_BYTES, "berry_tag_extract: short berry pic " .. i)
    pics[#pics + 1] = tiles:sub(1, PIC_BYTES)
    pals[i + 1] = K.palList(c:palFrom(c:lzAt(c:ptr(to + i * 8 + 4)), 16), 0, 16)
  end
  c:write("berries.gfx", table.concat(pics))
  gfx.berries = { path = c:path("berries.gfx"), bytes = #pics * PIC_BYTES }

  -- pokeemerald/src/berry_tag_screen.c:144
  local firmness, fo = {}, c:off("berry_tag_screen.o:sBerryFirmnessStrings")
  for i = 0, c.S.size("berry_tag_screen.o:sBerryFirmnessStrings") / 4 - 1 do
    local ptr = c:ptr(fo + i * 4)
    local name
    for _, n in ipairs(c.S.namesAt(ptr)) do
      if not n:find(":", 1, true) then name = n end
    end
    firmness[i + 1] = assert(name, "berry_tag_extract: unnamed firmness string " .. i)
  end

  return true, c:finish({
    screen = "berry_tag",
    gfx = gfx,
    maps = maps,
    palettes = {
      check = K.palList(c:pal("gBerryCheck_Pal", 96, {}, 0, true), 0, 96),
      -- pokeemerald/src/berry_tag_screen.c:95
      font = K.palList(c:pal("berry_tag_screen.o:sFontPalette", 16), 0, 16),
    },
    berryPals = pals,
    berryCount = #pics,
    picSize = 48,
    firmness = firmness,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
