local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/factory"

local O = "battle_factory_screen.o:"

-- pokeemerald/src/battle_factory_screen.c:261
M.GFX = {
  menu = { "gFrontierFactoryMenu_Gfx", false },
  monPicBg = { O .. "sMonPicBg_Gfx", false },
  monPicBgAnim = { O .. "sMonPicBgAnim_Gfx", false },
  arrow = { O .. "sArrow_Gfx", false },
  menuHighlightLeft = { O .. "sMenuHighlightLeft_Gfx", false },
  menuHighlightRight = { O .. "sMenuHighlightRight_Gfx", false },
  actionBoxLeft = { O .. "sActionBoxLeft_Gfx", false },
  actionBoxRight = { O .. "sActionBoxRight_Gfx", false },
  actionHighlightLeft = { O .. "sActionHighlightLeft_Gfx", false },
  actionHighlightMiddle = { O .. "sActionHighlightMiddle_Gfx", false },
  actionHighlightRight = { O .. "sActionHighlightRight_Gfx", false },
  -- pokeemerald/src/battle_factory_screen.c:289
  ball = { "gPokeballSelection_Gfx", true },
}

M.MAPS = {
  menu = "gFrontierFactoryMenu_Tilemap",
  monPicBg = O .. "sMonPicBg_Tilemap",
}

M.FILES = {}
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
for k in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

local function u8s(c, name, count)
  local off, out = c:off(name), {}
  for i = 0, (count or c.S.size(name)) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function moveList(c, off)
  local out = {}
  for i = 0, 255 do
    local m = c:u16(off + i * 2)
    if m == 0 then break end
    out[#out + 1] = m
  end
  return out
end

-- pokeemerald/src/battle_factory.c:113
local function moveStyles(c)
  local name = "sMoveStyles"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = moveList(c, c:ptr(off + i * 4)) end
  return out
end

-- pokeemerald/src/battle_factory.c:157
local function fixedIvTable(c)
  local name = "sFixedIVTable"
  local off, out = c:off(name), {}
  local rows = c.S.size(name) / 2
  -- pokeemerald/src/battle_factory.c:750
  for i = 0, rows do out[i + 1] = { c:u8(off + i * 2), c:u8(off + i * 2 + 1) } end
  return out
end

-- pokeemerald/src/battle_factory.c:169
local function rentalRanges(c)
  local name = "sInitialRentalMonRanges"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = { c:u16(off + i * 4), c:u16(off + i * 4 + 2) } end
  return out
end

-- pokeemerald/src/battle_factory.c:145
local function winStreakFlags(c)
  local name = "battle_factory.o:sWinStreakFlags"
  local off, out = c:off(name), {}
  for mode = 0, c.S.size(name) / 8 - 1 do
    out[mode + 1] = { c:u32(off + mode * 8), c:u32(off + mode * 8 + 4) }
  end
  return out
end

local function pal(c, name, count)
  return K.palList(c:pal(name, count, {}, 0), 0, count)
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local gfx = {}
  for key, spec in pairs(M.GFX) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    c:write(key .. ".gfx", data)
    gfx[key] = { path = c:path(key .. ".gfx"), bytes = #data }
  end
  local maps = {}
  for key, name in pairs(M.MAPS) do
    local data = c:raw(name)
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end
  return true, c:finish({
    screen = "factory",
    gfx = gfx,
    maps = maps,
    palettes = {
      menu = pal(c, "gFrontierFactoryMenu_Pal", c.S.size("gFrontierFactoryMenu_Pal") / 2),
      text = pal(c, O .. "sSelectText_Pal", c.S.size(O .. "sSelectText_Pal") / 2),
      ballGray = pal(c, O .. "sPokeballGray_Pal", 16),
      ballSelected = pal(c, O .. "sPokeballSelected_Pal", 16),
      interface = pal(c, O .. "sInterface_Pal", 16),
      monPicBg = pal(c, O .. "sMonPicBg_Pal", 16),
    },
    requiredMoveCounts = u8s(c, "sRequiredMoveCounts"),
    moveStyles = moveStyles(c),
    fixedIvTable = fixedIvTable(c),
    rentalRanges = rentalRanges(c),
    winStreakFlags = winStreakFlags(c),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
