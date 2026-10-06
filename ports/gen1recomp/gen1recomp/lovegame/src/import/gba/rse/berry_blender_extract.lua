local K = require("src.import.gba.rse.boot_gfx")
local TextIR = require("src.core.game3.scripting.text_ir")

local M = {}

M.SUB = "rse/berry_blender"

local BB = "berry_blender.o:"

-- pokeemerald/charmap.txt:52
local POKEBLOCK_GLYPHS = { 0x55, 0x56, 0x57, 0x58, 0x59 }
local POKEBLOCK_TEXT = "POKéBLOCK"

local function decodePart(bytes)
  if #bytes == 0 then return "" end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = TextIR.dialectOf("emerald") }), {})
end

local function decode(bytes)
  local parts, cur, i = {}, {}, 1
  while i <= #bytes do
    local run = true
    for k = 1, #POKEBLOCK_GLYPHS do
      if bytes[i + k - 1] ~= POKEBLOCK_GLYPHS[k] then run = false break end
    end
    if run then
      parts[#parts + 1] = decodePart(cur) .. POKEBLOCK_TEXT
      cur = {}
      i = i + #POKEBLOCK_GLYPHS
    else
      cur[#cur + 1] = bytes[i]
      i = i + 1
    end
  end
  parts[#parts + 1] = decodePart(cur)
  return table.concat(parts)
end

local function bytesAt(c, off)
  local bytes = {}
  for i = 0, 511 do
    local b = c:u8(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return bytes
end

local function stringAt(c, off)
  return decode(bytesAt(c, off))
end

local function irAt(c, off)
  return TextIR.decode(bytesAt(c, off), { dialect = TextIR.dialectOf("emerald") })
end

local function u8s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name)) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function s8s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name)) - 1 do out[i + 1] = c:s8(off + i) end
  return out
end

local function u16s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name) / 2) - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

local function s16s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name) / 2) - 1 do out[i + 1] = c:s16(off + i * 2) end
  return out
end

local function rows(list, width)
  local out = {}
  for i = 0, #list / width - 1 do
    local r = {}
    for j = 1, width do r[j] = list[i * width + j] end
    out[i + 1] = r
  end
  return out
end

-- pokeemerald/include/window.h:20
local function windowAt(c, off)
  return {
    bg = c:u8(off), left = c:u8(off + 1), top = c:u8(off + 2), width = c:u8(off + 3),
    height = c:u8(off + 4), paletteNum = c:u8(off + 5), baseBlock = c:u16(off + 6),
  }
end

-- pokeemerald/include/sprite.h:48
local function readAnim(c, off)
  local cmds = {}
  for i = 0, 63 do
    local at = off + i * 4
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
  return cmds
end

local function readAnimTable(c, off, count)
  local out = {}
  for i = 0, count - 1 do
    local p = c:ptr(off + i * 4)
    if p then out[#out + 1] = readAnim(c, p) end
  end
  return out
end

-- pokeemerald/include/sprite.h:117
local function readAffineAnim(c, off)
  local cmds = {}
  for i = 0, 63 do
    local base = off + i * 8
    local t = c:s16(base)
    if t == 0x7FFF then
      cmds[#cmds + 1] = { op = "end" }
      break
    elseif t == 0x7FFE then
      cmds[#cmds + 1] = { op = "jump", target = c:s16(base + 2) }
      break
    elseif t == 0x7FFD then
      cmds[#cmds + 1] = { op = "loop", count = c:s16(base + 2) }
    else
      cmds[#cmds + 1] = { op = "frame", xScale = t, yScale = c:s16(base + 2), rotation = c:u8(base + 4),
        duration = c:u8(base + 5) }
    end
  end
  return cmds
end

-- pokeemerald/include/sprite.h:179
local function template(c, name, animCount)
  local off = c:off(name)
  local oamOff = c:ptr(off + 4)
  local oam = c:readOam(oamOff)
  local tpl = {
    tileTag = c:u16(off), paletteTag = c:u16(off + 2), oam = oam,
    anims = readAnimTable(c, c:ptr(off + 8), animCount),
  }
  local aff = c:ptr(off + 16)
  if aff and oam.affineMode % 2 == 1 then tpl.affOff = aff end
  return tpl
end

local function sheet(c, key, gfx, tpl)
  local w, h = tpl.oam.w, tpl.oam.h
  local offsets, seen = {}, {}
  for _, a in ipairs(tpl.anims) do
    for _, cmd in ipairs(a) do
      if cmd.op == "frame" and not seen[cmd.tile] then
        seen[cmd.tile] = true
        offsets[#offsets + 1] = cmd.tile
      end
    end
  end
  table.sort(offsets)
  local frames, frameOf = {}, {}
  for i, t in ipairs(offsets) do
    frames[i] = K.bakeSprite(gfx, w, h, t, 4)
    frameOf[t] = i - 1
  end
  local idx = K.stack(frames, w, h)
  local png = c:png(key .. ".png", w, h * #frames, idx, {}, true)
  local anims = {}
  for i, a in ipairs(tpl.anims) do
    local list = {}
    for j, cmd in ipairs(a) do
      local row = {}
      for k, v in pairs(cmd) do row[k] = v end
      if cmd.op == "frame" then row.frame = frameOf[cmd.tile] end
      list[j] = row
    end
    anims[i] = list
  end
  return {
    png = png, w = w, h = h, frames = #frames, anims = anims,
    priority = tpl.oam.priority, affineMode = tpl.oam.affineMode, objMode = tpl.oam.objMode,
    paletteTag = tpl.paletteTag,
  }
end

M.SPRITES = {
  arrow = { "sSpriteTemplate_PlayerArrow", "gBerryBlenderPlayerArrow_Gfx", 12 },
  score = { "sSpriteTemplate_ScoreSymbols", "gBerryBlenderScoreSymbols_Gfx", 4 },
  particles = { "sSpriteTemplate_Particles", "gBerryBlenderParticles_Gfx", 5 },
  countdown = { "sSpriteTemplate_CountdownNumbers", "gBerryBlenderCountdownNumbers_Gfx", 3 },
  start = { "sSpriteTemplate_Start", "gBerryBlenderStart_Gfx", 1 },
}

M.TEXTS = {
  berryBlenderStart = "sText_BerryBlenderStart",
  newParagraph = "sText_NewParagraph",
  wasMade = "sText_WasMade",
  pressAToStart = "sText_PressAToStart",
  pleaseWaitAWhile = "sText_PleaseWaitAWhile",
  communicationStandby = "sText_CommunicationStandby",
  wouldLikeToBlendAnotherBerry = "sText_WouldLikeToBlendAnotherBerry",
  runOutOfBerriesForBlending = "sText_RunOutOfBerriesForBlending",
  yourPokeblockCaseIsFull = "sText_YourPokeblockCaseIsFull",
  hasNoBerriesToPut = "sText_HasNoBerriesToPut",
  apostropheSPokeblockCaseIsFull = "sText_ApostropheSPokeblockCaseIsFull",
  blendingResults = "sText_BlendingResults",
  berryUsed = "sText_BerryUsed",
  spaceBerry = "sText_SpaceBerry",
  time = "sText_Time",
  min = "sText_Min",
  sec = "sText_Sec",
  maximumSpeed = "sText_MaximumSpeed",
  rpm = "sText_RPM",
  dot = "sText_Dot",
  ranking = "sText_Ranking",
  theLevelIs = "sText_TheLevelIs",
  theFeelIs = "sText_TheFeelIs",
  dot2 = "sText_Dot2",
}

M.GLOBAL_TEXTS = {
  blenderMaxSpeedRecord = "gText_BlenderMaxSpeedRecord",
  players234 = "gText_234Players",
  space = "gText_Space",
  yesNo = "gText_YesNo",
}

M.FILES = { "center_idx.png", "outer.4bpp", "berries.png" }
for k in pairs(M.SPRITES) do M.FILES[#M.FILES + 1] = k .. ".png" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local S = c.S

  -- pokeemerald/src/berry_blender.c:966
  local centerGfx = c:lz("gBerryBlenderCenter_Gfx")
  local centerMap = c:raw(BB .. "sBlenderCenter_Tilemap")
  local cIdx, cw, ch = K.bakeAffine(centerGfx, centerMap, 32)
  local center = { index = c:gray("center_idx.png", cw, ch, cIdx), w = cw, h = ch, bpp = 8 }
  -- pokeemerald/src/berry_blender.c:969
  local centerPal = K.palList(c:palAt(c:off(BB .. "sBlenderCenter_Pal"), 128), 0, 128)

  -- pokeemerald/src/berry_blender.c:977
  c:write("outer.4bpp", c:lz("gBerryBlenderOuter_Gfx"))
  local om = c:lz("gBerryBlenderOuter_Tilemap")
  local outerMap = {}
  for i = 0, #om / 2 - 1 do
    local lo, hi = om:byte(i * 2 + 1, i * 2 + 2)
    outerMap[i + 1] = lo + hi * 256
  end
  local outerPal = K.palList(c:pal(BB .. "sBlenderOuter_Pal", 16), 0, 16)

  local sprites = {}
  for key, spec in pairs(M.SPRITES) do
    local tpl = template(c, BB .. spec[1], spec[3])
    sprites[key] = sheet(c, key, c:raw(spec[2]), tpl)
  end

  -- pokeemerald/src/item_menu_icons.c:327
  local berries, berryPals = {}, {}
  local bt = c:off("sBerryPicTable")
  local count = S.size("sBerryPicTable") / 8
  for i = 0, count - 1 do
    local tiles = c:lzAt(c:ptr(bt + i * 8))
    local pic = K.bakeSprite(tiles, 48, 48, 0, 4)
    local frame = K.blank(64, 64)
    -- pokeemerald/src/item_menu_icons.c:590
    for y = 0, 47 do
      for x = 0, 47 do frame[(y + 8) * 64 + x + 8 + 1] = pic[y * 48 + x + 1] end
    end
    berries[i + 1] = frame
    berryPals[i + 1] = K.palList(c:palFrom(c:lzAt(c:ptr(bt + i * 8 + 4)), 16), 0, 16)
  end
  local berryIdx = K.stack(berries, 64, 64)
  local berryTpl = template(c, "sBerryPicRotatingSpriteTemplate", 1)
  local berryAffine = {}
  local ao = c:off("sBerryPicRotatingAnimCmds")
  for i = 0, S.size("sBerryPicRotatingAnimCmds") / 4 - 1 do
    berryAffine[i + 1] = readAffineAnim(c, c:ptr(ao + i * 4))
  end
  local berrySprite = {
    png = c:png("berries.png", 64, 64 * count, berryIdx, {}, true), w = 64, h = 64, frames = count,
    anims = { { { op = "frame", frame = 0, duration = 0 }, { op = "end" } } },
    affineAnims = berryAffine, priority = berryTpl.oam.priority, affineMode = berryTpl.oam.affineMode,
    objMode = berryTpl.oam.objMode, paletteTag = berryTpl.paletteTag,
  }

  local texts, irs = {}, {}
  for key, name in pairs(M.TEXTS) do
    texts[key] = stringAt(c, c:off(BB .. name))
    irs[key] = irAt(c, c:off(BB .. name))
  end
  for key, name in pairs(M.GLOBAL_TEXTS) do
    texts[key] = stringAt(c, c:off(name))
    irs[key] = irAt(c, c:off(name))
  end
  local names = {}
  local no = c:off(BB .. "sBlenderOpponentsNames")
  for i = 0, S.size(BB .. "sBlenderOpponentsNames") / 4 - 1 do names[i + 1] = stringAt(c, c:ptr(no + i * 4)) end

  local windows = {}
  local wo = c:off(BB .. "sWindowTemplates")
  for i = 0, S.size(BB .. "sWindowTemplates") / 8 - 2 do windows[i + 1] = windowAt(c, wo + i * 8) end

  local tables = {
    playerArrowQuadrant = rows(s8s(c, BB .. "sPlayerArrowQuadrant"), 2),
    playerArrowPos = rows(u8s(c, BB .. "sPlayerArrowPos"), 2),
    playerIdMap = rows(u8s(c, BB .. "sPlayerIdMap"), 4),
    arrowStartPos = u16s(c, BB .. "sArrowStartPos"),
    arrowStartPosIds = u8s(c, BB .. "sArrowStartPosIds"),
    arrowHitRangeStart = u8s(c, BB .. "sArrowHitRangeStart"),
    berrySpriteData = rows(s16s(c, BB .. "sBerrySpriteData"), 5),
    opponentBerrySets = rows(u8s(c, BB .. "sOpponentBerrySets"), 3),
    berryMasterBerries = u8s(c, BB .. "sBerryMasterBerries"),
    numPlayersToSpeedDivisor = u8s(c, BB .. "sNumPlayersToSpeedDivisor"),
    blackPokeblockFlavorFlags = u8s(c, BB .. "sBlackPokeblockFlavorFlags"),
    -- pokeemerald/src/trig.c:5
    sine = s16s(c, "gSineTable"),
  }

  return true, c:finish({
    screen = "berry_blender",
    center = center,
    outerTiles = c:path("outer.4bpp"),
    outerMap = outerMap,
    palettes = {
      center = centerPal,
      outer = outerPal,
      sprites = {
        { tag = sprites.arrow.paletteTag, colors = K.palList(c:pal("gBerryBlenderArrowPalette", 16), 0, 16) },
        { tag = sprites.score.paletteTag, colors = K.palList(c:pal("gBerryBlenderMiscPalette", 16), 0, 16) },
      },
      berries = berryPals,
    },
    sprites = sprites,
    berry = berrySprite,
    texts = texts,
    irs = irs,
    opponentNames = names,
    windows = windows,
    yesNoWindow = windowAt(c, c:off(BB .. "sYesNoWindowTemplate_ContinuePlaying")),
    recordWindow = windowAt(c, c:off(BB .. "sBlenderRecordWindowTemplate")),
    tables = tables,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
