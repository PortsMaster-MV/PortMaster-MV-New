local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/pokeblock"

M.GFX = {
  menu = { "gMenuPokeblock_Gfx", true },
  device = { "gMenuPokeblockDevice_Gfx", true },
  pokeblock = { "gPokeblock_Gfx", true },
  feed_bg = { "gBattleEnvironmentTiles_Building", true },
  graph = { "gUsePokeblockGraph_Gfx", true },
  mon_frame = { "use_pokeblock.o:sMonFrame_Gfx", false },
  condition = { "gUsePokeblockCondition_Gfx", true },
  updown = { "gUsePokeblockUpDown_Gfx", false },
  ball = { "menu_specialized.o:sConditionPokeball_Gfx", false },
  ball_placeholder = { "menu_specialized.o:sConditionPokeballPlaceholder_Gfx", false },
  cancel = { "gPokenavConditionCancel_Gfx", false },
  sparkle = { "menu_specialized.o:sConditionSparkle_Pal", false },
  swap_line = { "gSwapLineGfx", true },
}

M.MAPS = {
  menu = "gMenuPokeblock_Tilemap",
  feed_bg = "gPokeblockFeedBg_Tilemap",
  graph = "gUsePokeblockGraph_Tilemap",
  mon_frame = "use_pokeblock.o:sMonFrame_Tilemap",
  graph_data = "use_pokeblock.o:sGraphData_Tilemap",
}

M.RAW_MAPS = {
  nature_win = "gUsePokeblockNatureWin_Pal",
}

M.PALETTES = {
  menu = { "gMenuPokeblock_Pal", 96, true },
  device = { "gMenuPokeblockDevice_Pal", 16, true },
  feed_bg = { "gBattleEnvironmentPalette_Frontier", 48, true },
  graph = { "gUsePokeblockGraph_Pal", 16 },
  mon_frame = { "use_pokeblock.o:sMonFrame_Pal", 16 },
  graph_data = { "gConditionGraphData_Pal", 16 },
  condition_text = { "gConditionText_Pal", 16 },
  condition = { "gUsePokeblockCondition_Pal", 16 },
  updown = { "gUsePokeblockUpDown_Pal", 16 },
  cancel = { "gPokenavConditionCancel_Pal", 32 },
  sparkle = { "menu_specialized.o:sConditionSparkle_Gfx", 16 },
  swap_line = { "gSwapLinePal", 16, true },
}

M.FILES = {}
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
for k in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
for k in pairs(M.RAW_MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

local function u8s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name)) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function s16s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name) / 2) - 1 do out[i + 1] = c:s16(off + i * 2) end
  return out
end

-- pokeemerald/include/sprite.h:117
local function affineAnim(c, off)
  local cmds = {}
  for i = 0, 63 do
    local o = off + i * 8
    local t = c:s16(o)
    if t == 0x7FFF then
      cmds[#cmds + 1] = { op = "end" }
      break
    elseif t == 0x7FFE then
      cmds[#cmds + 1] = { op = "jump", target = c:u16(o + 2) }
      break
    elseif t == 0x7FFD then
      cmds[#cmds + 1] = { op = "loop", count = c:u16(o + 2) }
    else
      cmds[#cmds + 1] = { op = "frame", xScale = t, yScale = c:s16(o + 2), rotation = c:s8(o + 4), duration = c:u8(o + 5) }
    end
  end
  return cmds
end

local function affineTable(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = affineAnim(c, c:ptr(off + i * 4)) end
  return out
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
  for key, sym in pairs(M.MAPS) do
    local data = c:lz(sym)
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end
  for key, sym in pairs(M.RAW_MAPS) do
    local data = c:raw(sym)
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end
  local palettes = {}
  for key, spec in pairs(M.PALETTES) do
    palettes[key] = K.palList(c:pal(spec[1], spec[2], {}, 0, spec[3]), 0, spec[2])
  end

  -- pokeemerald/src/pokeblock_feed.c:469
  local colors = {}
  local po = c:off("pokeblock_feed.o:sPokeblocksPals")
  for i = 0, c.S.size("pokeblock_feed.o:sPokeblocksPals") / 4 - 1 do
    colors[i + 1] = K.palList(c:palFrom(c:lzAt(c:ptr(po + i * 4)), 16), 0, 16)
  end

  -- pokeemerald/src/pokeblock.c:300
  local favorites, fo = {}, c:off("pokeblock.o:sFavoritePokeblocksTable")
  local fields = { "color", "spicy", "dry", "sweet", "bitter", "sour", "feel" }
  -- pokeemerald/include/constants/berry.h:18
  local stride = c.S.size("pokeblock.o:sFavoritePokeblocksTable") / 5
  for i = 0, 4 do
    local b = {}
    for j, k in ipairs(fields) do b[k] = c:u8(fo + i * stride + j - 1) end
    favorites[i + 1] = b
  end

  -- pokeemerald/src/pokeblock_feed.c:187
  local anims, ao = {}, c:off("pokeblock_feed.o:sMonPokeblockAnims")
  for i = 0, c.S.size("pokeblock_feed.o:sMonPokeblockAnims") / 20 - 1 do
    local row = {}
    for j = 0, 9 do row[j + 1] = c:s16(ao + i * 20 + j * 2) end
    anims[i + 1] = row
  end
  -- pokeemerald/src/pokeblock_feed.c:144
  local natureAnims, no = {}, c:off("pokeblock_feed.o:sNatureToMonPokeblockAnim")
  for i = 0, c.S.size("pokeblock_feed.o:sNatureToMonPokeblockAnim") / 2 - 1 do
    natureAnims[i + 1] = { c:u8(no + i * 2), c:u8(no + i * 2 + 1) }
  end

  -- pokeemerald/src/menu_specialized.c:1317
  local sparkleCoords, so = {}, c:off("menu_specialized.o:sConditionSparkleCoords")
  for i = 0, c.S.size("menu_specialized.o:sConditionSparkleCoords") / 4 - 1 do
    sparkleCoords[i + 1] = { c:s16(so + i * 4), c:s16(so + i * 4 + 2) }
  end
  -- pokeemerald/src/use_pokeblock.c:308
  local upDown, uo = {}, c:off("use_pokeblock.o:sUpDownCoordsOnGraph")
  for i = 0, c.S.size("use_pokeblock.o:sUpDownCoordsOnGraph") / 4 - 1 do
    upDown[i + 1] = { c:s16(uo + i * 4), c:s16(uo + i * 4 + 2) }
  end

  -- pokeemerald/include/pokemon.h:323
  local noFlip, si = {}, c:off("gSpeciesInfo")
  for sp = 0, c.S.size("gSpeciesInfo") / 28 - 1 do
    if c:u8(si + sp * 28 + 25) >= 128 then noFlip[sp] = true end
  end

  return true, c:finish({
    screen = "pokeblock",
    gfx = gfx,
    maps = maps,
    palettes = palettes,
    colors = colors,
    favorites = favorites,
    feedAnims = anims,
    natureAnims = natureAnims,
    -- pokeemerald/src/menu_specialized.c:88
    lineLength = u8s(c, "menu_specialized.o:sConditionToLineLength"),
    -- pokeemerald/src/trig.c:5
    sine = s16s(c, "gSineTable"),
    sparkleCoords = sparkleCoords,
    upDownCoords = upDown,
    -- pokeemerald/src/use_pokeblock.c:190
    conditionToFlavor = u8s(c, "use_pokeblock.o:sConditionToFlavor"),
    noFlip = noFlip,
    -- pokeemerald/src/pokeblock_feed.c:403
    affine = {
      mon = affineTable(c, "pokeblock_feed.o:sAffineAnims_Mon"),
      monNoFlip = affineTable(c, "pokeblock_feed.o:sSpriteAffineAnimTable_MonNoFlip"),
      caseStill = affineTable(c, "pokeblock_feed.o:sAffineAnims_PokeblockCase_Still"),
      caseThrow = affineTable(c, "pokeblock_feed.o:sAffineAnims_PokeblockCase_ThrowFromHorizontal"),
      pokeblock = affineTable(c, "pokeblock_feed.o:sAffineAnims_Pokeblock"),
    },
    -- pokeemerald/src/use_pokeblock.c:1357
    graphTileBase = 160 * 4,
    -- pokeemerald/src/use_pokeblock.c:233
    monFrameTileBase = 0x100,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
