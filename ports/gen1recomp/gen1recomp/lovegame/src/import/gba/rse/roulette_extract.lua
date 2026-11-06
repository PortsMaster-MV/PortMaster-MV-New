local K = require("src.import.gba.rse.boot_gfx")
local Slot = require("src.import.gba.rse.slot_machine_extract")

local M = {}

M.SUB = "rse_roulette"

local function f32(u)
  local sign = (u >= 0x80000000) and -1 or 1
  local exp = math.floor(u / 0x800000) % 256
  local mant = u % 0x800000
  if exp == 0 then return sign * mant * 2 ^ -149 end
  return sign * (1 + mant / 0x800000) * 2 ^ (exp - 127)
end
M.f32 = f32

local function readAnimAt(c, off)
  local cmds = {}
  for i = 0, 63 do
    local at = off + i * 4
    if i > 0 and #c.S.namesAt(at) > 0 then break end
    local lo, hi = c:u16(at), c:u16(at + 2)
    if lo == 0xFFFF then
      cmds[#cmds + 1] = { op = "end" }
      break
    elseif lo == 0xFFFE then
      cmds[#cmds + 1] = { op = "jump", target = hi % 64 }
      break
    elseif lo == 0xFFFD then
      cmds[#cmds + 1] = { op = "loop", count = hi % 64 }
    else
      cmds[#cmds + 1] = { op = "frame", tile = lo, duration = hi % 64,
        hFlip = math.floor(hi / 64) % 2 == 1 or nil, vFlip = math.floor(hi / 128) % 2 == 1 or nil }
    end
  end
  if cmds[#cmds].op == "frame" then cmds[#cmds + 1] = { op = "end" } end
  return cmds
end

local function readAnimTableAt(c, off)
  local anims = {}
  for i = 0, 15 do
    local at = off + i * 4
    if i > 0 and #c.S.namesAt(at) > 0 then break end
    local p = c:ptr(at)
    if not p then break end
    anims[#anims + 1] = readAnimAt(c, p)
  end
  return anims
end

-- pokeemerald/include/sprite.h:179
local function templateAt(c, off)
  local oamOff = c:ptr(off + 4)
  local oam = c:readOam(oamOff)
  oam.y = c:u8(oamOff)
  local affOff = c:ptr(off + 16)
  return {
    tileTag = c:u16(off), paletteTag = c:u16(off + 2), oam = oam,
    anims = readAnimTableAt(c, c:ptr(off + 8)),
    affOff = affOff,
  }
end

local function frameSheet(c, key, gfx, tpls, extraOffsets)
  local w, h = tpls[1].oam.w, tpls[1].oam.h
  local offsets, seen = {}, {}
  local function add(t) if not seen[t] then seen[t] = true; offsets[#offsets + 1] = t end end
  for _, tpl in ipairs(tpls) do
    for _, a in ipairs(tpl.anims) do
      for _, cmd in ipairs(a) do if cmd.op == "frame" then add(cmd.tile) end end
    end
  end
  for _, t in ipairs(extraOffsets or {}) do add(t) end
  if #offsets == 0 then add(0) end
  table.sort(offsets)
  local frames, frameOf = {}, {}
  for i, t in ipairs(offsets) do
    frames[i] = K.bakeSprite(gfx, w, h, t, 4)
    frameOf[t] = i - 1
  end
  local entry = Slot.sheet(c, key, frames, w, h)
  entry.frameOf = frameOf
  return entry
end

local function remap(tpl, sheet)
  local anims = {}
  for i, a in ipairs(tpl.anims) do
    local list = {}
    for j, cmd in ipairs(a) do
      local row = {}
      for k, v in pairs(cmd) do row[k] = v end
      if cmd.op == "frame" then row.frame = sheet.frameOf[cmd.tile] end
      list[j] = row
    end
    anims[i] = list
  end
  return {
    anims = anims, w = tpl.oam.w, h = tpl.oam.h, priority = tpl.oam.priority, affineMode = tpl.oam.affineMode,
    objMode = tpl.oam.objMode, subpriority = tpl.oam.y, paletteTag = tpl.paletteTag, sheet = sheet.png,
  }
end

local function u8s(c, off, n)
  local t = {}
  for i = 0, n - 1 do t[i] = c:u8(off + i) end
  return t
end

local function u16s(c, off, n)
  local t = {}
  for i = 0, n - 1 do t[i] = c:u16(off + i * 2) end
  return t
end

-- pokeemerald/include/palette_util.h:39
local function flashSettings(c, off, n)
  local out = {}
  for i = 0, n - 1 do
    local b = off + i * 8
    local bits = c:u8(b + 7)
    local cycles = bits % 32
    if cycles >= 16 then cycles = cycles - 32 end
    local dir = math.floor(bits / 128) % 2
    out[i] = {
      color = c:u16(b), paletteOffset = c:u16(b + 2), numColors = c:u8(b + 4), delay = c:u8(b + 5),
      numFadeCycles = cycles, colorDeltaDir = dir == 1 and -1 or 0,
    }
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  return M.runContext(c)
end

function M.runContext(c)
  local S = c.S

  -- pokeemerald/src/roulette.c:471
  local grid = {}
  local gOff = c:off("sGridSelections")
  for i = 0, S.size("sGridSelections") / 20 - 1 do
    local b = gOff + i * 20
    grid[i] = {
      spriteIdOffset = c:u8(b), baseMultiplier = c:u8(b + 1) % 16, x = c:u8(b + 3), y = c:u8(b + 4),
      tilemapOffset = c:u8(b + 6), flag = c:u32(b + 8), inSelectionFlags = c:u32(b + 12), flashFlags = c:u16(b + 16),
    }
  end
  local slots = {}
  local sOff = c:off("sRouletteSlots")
  for i = 0, S.size("sRouletteSlots") / 8 - 1 do
    slots[i] = { gridSquare = c:u8(sOff + i * 8 + 2), flag = c:u32(sOff + i * 8 + 4) }
  end
  -- pokeemerald/src/roulette.c:812
  local rtables = {}
  local rOff = c:off("sRouletteTables")
  for i = 0, S.size("sRouletteTables") / 32 - 1 do
    local b = rOff + i * 32
    rtables[i] = {
      minBet = c:u8(b), randDistanceHigh = c:u8(b + 1), randDistanceLow = c:u8(b + 2), wheelSpeed = c:u8(b + 3),
      wheelDelay = c:u8(b + 4),
      shroomish = { startAngle = c:u16(b + 8), dropAngle = c:u16(b + 10), fallSlowdown = c:u16(b + 12) },
      taillow = { baseDropDelay = c:u16(b + 16), rightStartAngle = c:u16(b + 18), leftStartAngle = c:u16(b + 20) },
      ballSpeed = c:u16(b + 24), baseTravelDist = c:u16(b + 26), var1C = f32(c:u32(b + 28)),
    }
  end
  local tables = {
    grid = grid,
    slots = slots,
    rouletteTables = rtables,
    minBets = u8s(c, c:off("sTableMinBets"), S.size("sTableMinBets")),
    flashColors = flashSettings(c, c:off("sFlashData_Colors"), S.size("sFlashData_Colors") / 8),
    flashPokeIcons = flashSettings(c, c:off("sFlashData_PokeIcons"), S.size("sFlashData_PokeIcons") / 8),
    shroomishShadowAlphas = u16s(c, c:off("sShroomishShadowAlphas"), S.size("sShroomishShadowAlphas") / 2),
    fanfares = Slot.fanfares(c),
    -- pokeemerald/src/trig.c:5
    sine = (function()
      local t = {}
      for i = 0, S.size("gSineTable") / 2 - 1 do t[i] = c:s16(c:off("gSineTable") + i * 2) end
      return t
    end)(),
    sineDeg = (function()
      local t = {}
      for i = 0, S.size("gSineDegreeTable") / 2 - 1 do t[i] = c:s16(c:off("gSineDegreeTable") + i * 2) end
      return t
    end)(),
  }

  -- pokeemerald/src/roulette.c:1170
  local wheelPal = K.palList(c:pal("sWheel_Pal", 256), 0, 256)
  local menuGfx = c:lz("gRouletteMenu_Gfx")
  c:write("menu_tiles.4bpp", menuGfx)
  local gridMap = c:lz("sGrid_Tilemap")
  local gridTilemap = {}
  for i = 0, math.floor(#gridMap / 2) - 1 do
    local lo, hi = gridMap:byte(i * 2 + 1, i * 2 + 2)
    gridTilemap[i] = lo + hi * 256
  end
  local wheelGfx = c:lz("gRouletteWheel_Gfx")
  local wheelMap = c:lz("sWheel_Tilemap")
  local wIdx, ww, wh = K.bakeAffine(wheelGfx, wheelMap, math.floor(math.sqrt(#wheelMap) + 0.5))
  local wheel = { index = c:gray("wheel_idx.png", ww, wh, wIdx), w = ww, h = wh, bpp = 8 }

  local palettes = { wheel = wheelPal, sprites = {} }
  local spOff = c:off("roulette.o:sSpritePalettes")
  for i = 0, 31 do
    local p = c:ptr(spOff + i * 8)
    if not p then break end
    palettes.sprites[#palettes.sprites + 1] = { tag = c:u16(spOff + i * 8 + 4), colors = K.palList(c:palAt(p, 16), 0, 16) }
  end

  local function tpl(name) return templateAt(c, c:off(name)) end
  local function tplArr(name, n)
    local out = {}
    for i = 0, n - 1 do out[i + 1] = templateAt(c, c:off(name) + i * 24) end
    return out
  end

  local sprites = {}
  local ball = tpl("sSpriteTemplate_Ball")
  local ballSheet = frameSheet(c, "ball", c:lz("sBall_Gfx"), { ball })
  sprites.ball = remap(ball, ballSheet)

  local center = tpl("sSpriteTemplate_WheelCenter")
  sprites.center = remap(center, frameSheet(c, "center", c:lz("gRouletteCenter_Gfx"), { center }))

  local icons = tplArr("sSpriteTemplates_WheelIcons", 12)
  local iconSheet = frameSheet(c, "wheel_icons", c:lz("sWheelIcons_Gfx"), icons)
  sprites.wheelIcons = {}
  for i, t in ipairs(icons) do sprites.wheelIcons[i - 1] = remap(t, iconSheet) end

  local headersGfx = c:lz("gRouletteHeaders_Gfx")
  local pokeHeaders, colorHeaders = tplArr("sSpriteTemplates_PokeHeaders", 4), tplArr("sSpriteTemplates_ColorHeaders", 3)
  local all = {}
  for _, t in ipairs(pokeHeaders) do all[#all + 1] = t end
  for _, t in ipairs(colorHeaders) do all[#all + 1] = t end
  local headerSheet = frameSheet(c, "headers", headersGfx, all)
  sprites.pokeHeaders, sprites.colorHeaders = {}, {}
  for i, t in ipairs(pokeHeaders) do sprites.pokeHeaders[i - 1] = remap(t, headerSheet) end
  for i, t in ipairs(colorHeaders) do sprites.colorHeaders[i - 1] = remap(t, headerSheet) end

  local gridIcons = tplArr("sSpriteTemplates_GridIcons", 4)
  local gridIconSheet = frameSheet(c, "grid_icons", c:lz("sGridIcons_Gfx"), gridIcons)
  sprites.gridIcons = {}
  for i, t in ipairs(gridIcons) do sprites.gridIcons[i - 1] = remap(t, gridIconSheet) end

  local credit = tpl("sSpriteTemplate_Credit")
  sprites.credit = remap(credit, frameSheet(c, "credit", c:lz("gRouletteCredit_Gfx"), { credit }))
  local digit = tpl("sSpriteTemplate_CreditDigit")
  sprites.creditDigit = remap(digit, frameSheet(c, "credit_digit", c:lz("gRouletteNumbers_Gfx"), { digit }))
  local mult = tpl("sSpriteTemplate_Multiplier")
  sprites.multiplier = remap(mult, frameSheet(c, "multiplier", c:lz("gRouletteMultiplier_Gfx"), { mult }))
  local counter = tpl("sSpriteTemplate_BallCounter")
  sprites.ballCounter = remap(counter, frameSheet(c, "ball_counter", c:lz("sBallCounter_Gfx"), { counter }))
  local cursor = tpl("roulette.o:sSpriteTemplate_Cursor")
  sprites.cursor = remap(cursor, frameSheet(c, "cursor", c:lz("roulette.o:sCursor_Gfx"), { cursor }))

  local st = c:lz("sShroomishTaillow_Gfx")
  local shroomish, taillow = tpl("sSpriteTemplate_Shroomish"), tpl("sSpriteTemplate_Taillow")
  local stSheet = frameSheet(c, "shroomish_taillow", st, { shroomish, taillow })
  sprites.shroomish = remap(shroomish, stSheet)
  sprites.taillow = remap(taillow, stSheet)

  local shadowGfx = c:lz("sShadow_Gfx")
  local shadows = tplArr("sSpriteTemplate_ShroomishShadow", 2)
  local taillowShadow = tpl("sSpriteTemplate_TaillowShadow")
  sprites.ballShadow = remap(shadows[1], frameSheet(c, "ball_shadow", shadowGfx, { shadows[1] }))
  sprites.monShadow = remap(shadows[2], frameSheet(c, "mon_shadow", shadowGfx, { shadows[2] }))
  sprites.taillowShadow = remap(taillowShadow, frameSheet(c, "taillow_shadow", shadowGfx, { taillowShadow }))
  sprites.taillowShadow.affineAnims = Slot.affineTable(c, taillowShadow.affOff, 1)

  local manifest = {
    screen = "roulette",
    menuTiles = c:path("menu_tiles.4bpp"),
    gridTilemap = gridTilemap,
    wheel = wheel,
    tables = tables,
    palettes = palettes,
    sprites = sprites,
  }
  return true, c:finish(manifest)
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

M.REQUIRED = K.required(M.SUB, { "menu_tiles.4bpp", "wheel_idx.png", "ball.png", "wheel_icons.png", "headers.png" })

return M
