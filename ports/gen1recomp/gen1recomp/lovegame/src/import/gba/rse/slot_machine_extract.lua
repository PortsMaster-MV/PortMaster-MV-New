local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse_slot_machine"

local function affineAnim(c, off)
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
      cmds[#cmds + 1] = { op = "frame", xScale = t, yScale = c:s16(base + 2), rotation = c:u8(base + 4), duration = c:u8(base + 5) }
    end
  end
  return cmds
end
M.affineAnim = affineAnim

function M.affineTable(c, off, count)
  local out = {}
  for i = 0, count - 1 do
    local p = c:ptr(off + i * 4)
    if p then out[#out + 1] = affineAnim(c, p) end
  end
  return out
end

-- pokeemerald/include/sprite.h:159
function M.subspriteTable(c, off)
  local n = c:u8(off)
  local list = c:ptr(off + 4)
  local out = {}
  for i = 0, n - 1 do
    local b = list + i * 4
    local attr = c:u16(b + 2)
    local shape, size = attr % 4, math.floor(attr / 4) % 4
    local w, h = K.objDims(shape, size)
    out[#out + 1] = {
      x = c:s8(b), y = c:s8(b + 1), w = w, h = h,
      tileOffset = math.floor(attr / 16) % 1024, priority = math.floor(attr / 16384) % 4,
    }
  end
  return out
end

local function place(dst, W, src, w, h, x0, y0)
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local v = src[y * w + x + 1]
      if v ~= 0 then dst[(y0 + y) * W + x0 + x + 1] = v end
    end
  end
end

function M.composite(gfx, baseTile, pieces)
  local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(pieces) do
    if p.x < minX then minX = p.x end
    if p.y < minY then minY = p.y end
    if p.x + p.w > maxX then maxX = p.x + p.w end
    if p.y + p.h > maxY then maxY = p.y + p.h end
  end
  local W, H = maxX - minX, maxY - minY
  local out = K.blank(W, H)
  for _, p in ipairs(pieces) do
    place(out, W, K.bakeSprite(gfx, p.w, p.h, baseTile + p.tileOffset, 4), p.w, p.h, p.x - minX, p.y - minY)
  end
  return out, W, H, minX, minY
end

function M.sheet(c, key, frames, w, h, extra)
  local idx = K.stack(frames, w, h)
  local entry = { png = c:png(key .. ".png", w, h * #frames, idx, {}, true), w = w, h = h, frames = #frames }
  for k, v in pairs(extra or {}) do entry[k] = v end
  return entry
end

function M.plain(c, key, gfx, w, h, tiles)
  local frames = {}
  for i, t in ipairs(tiles) do frames[i] = K.bakeSprite(gfx, w, h, t, 4) end
  return M.sheet(c, key, frames, w, h)
end

function M.composed(c, key, gfx, baseTiles, tables)
  local out = { tables = {} }
  for ti, pieces in ipairs(tables) do
    local frames, W, H, ox, oy = {}, nil, nil, nil, nil
    for i, bt in ipairs(baseTiles) do
      frames[i], W, H, ox, oy = M.composite(gfx, bt, pieces)
    end
    out.tables[ti] = M.sheet(c, key .. "_" .. (ti - 1), frames, W, H, { ox = ox, oy = oy, priority = pieces[1].priority })
  end
  return out
end

-- pokeemerald/src/sound.c:37
function M.fanfares(c)
  local out = {}
  local off = c:off("sFanfares")
  for i = 0, c.S.size("sFanfares") / 4 - 1 do
    out[c:u16(off + i * 4)] = c:u16(off + i * 4 + 2)
  end
  return out
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

local function s16s(c, off, n)
  local t = {}
  for i = 0, n - 1 do t[i] = c:s16(off + i * 2) end
  return t
end

local function grid(c, fn, off, rows, cols, stride)
  local t = {}
  for r = 0, rows - 1 do t[r] = fn(c, off + r * cols * stride, cols) end
  return t
end

local function palAt(c, off, n)
  return K.palList(c:palAt(off, n), 0, n)
end

local function templateAnims(c, name)
  local tpl = c:readTemplate(name)
  local anims = {}
  for i, a in ipairs(tpl.anims) do
    local list = {}
    for j, cmd in ipairs(a) do
      local row = {}
      for k, v in pairs(cmd) do row[k] = v end
      if cmd.op == "frame" then row.frame = cmd.tile end
      list[j] = row
    end
    anims[i] = list
  end
  return anims, tpl
end
M.templateAnims = templateAnims

-- pokeemerald/src/slot_machine.c:436
local DIG = {
  [0] = { base = 0x0, frames = 1, size = 0x600 },
  [1] = { base = 0x600, frames = 1, size = 0x200 },
  [2] = { base = 0x800, frames = 1, size = 0x200 },
  [3] = { base = 0xC00, frames = 1, size = 0x300 },
  [4] = { base = 0x1000, frames = 1, size = 0x400 },
  [5] = { base = 0x1C00, frames = 2, size = 0x200 },
  [6] = { base = 0x2000, frames = 1, size = 640 },
  [7] = { base = 0x2280, frames = 5, size = 0x80 },
  [8] = { list = { 0x2600, 10880 }, size = 0x480 },
  [9] = { list = { 0x2F00, 0x3080 }, size = 0x180 },
  [10] = { base = 0xA00, frames = 1 }, [11] = { base = 0xA00, frames = 1 },
  [12] = { base = 0xA00, frames = 1 }, [13] = { base = 0xA00, frames = 1 },
  [14] = { base = 0x1400, frames = 1 }, [15] = { base = 0x1400, frames = 1 },
  [16] = { base = 0x1400, frames = 1 }, [17] = { base = 0x1400, frames = 1 },
  [18] = { base = 0x1400, frames = 1 },
  [19] = { base = 0x1600, frames = 1 }, [20] = { base = 0x1600, frames = 1 }, [21] = { base = 0x1600, frames = 1 },
  [22] = { base = 0x1900, frames = 1 }, [23] = { base = 0x1900, frames = 1 }, [24] = { base = 0x1900, frames = 1 },
}

local function baseTiles(d)
  local out = {}
  if d.list then
    for i, b in ipairs(d.list) do out[i] = b / 32 end
  else
    for f = 0, d.frames - 1 do out[f + 1] = (d.base + f * (d.size or 0)) / 32 end
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local S = c.S

  -- pokeemerald/src/slot_machine.c:5225
  local tables = {
    reelSymbols = grid(c, u8s, c:off("sReelSymbols"), 3, 21, 1),
    reelTimeSymbols = u8s(c, c:off("sReelTimeSymbols"), 6),
    initialReelPositions = grid(c, s16s, c:off("sInitialReelPositions"), 3, 2, 2),
    specialDrawOdds = grid(c, u8s, c:off("sSpecialDrawOdds"), 6, 3, 1),
    biasProbSpecial = grid(c, u8s, c:off("sBiasProbabilities_Special"), 3, 6, 1),
    biasProbRegular = grid(c, u8s, c:off("sBiasProbabilities_Regular"), 5, 6, 1),
    reelTimeProbNormal = grid(c, u8s, c:off("sReelTimeProbabilities_NormalGame"), 6, 17, 1),
    reelTimeProbLucky = grid(c, u8s, c:off("sReelTimeProbabilities_LuckyGame"), 6, 17, 1),
    reelTimeExplodeProb = u16s(c, c:off("sReelTimeExplodeProbability"), 5),
    reelTimeSpeedProb = grid(c, u16s, c:off("sReelTimeSpeed_Probabilities"), 5, 2, 2),
    quarterSpeedBoost = u16s(c, c:off("sQuarterSpeed_ProbabilityBoost"), 5),
    biasSymbols = u8s(c, c:off("sBiasSymbols"), 8),
    biasesSpecial = u16s(c, c:off("sBiasesSpecial"), 3),
    biasesRegular = u16s(c, c:off("sBiasesRegular"), 5),
    symbolToMatch = u8s(c, c:off("sSymbolToMatch"), 7),
    matchFlags = u16s(c, c:off("sSlotMatchFlags"), 9),
    payouts = u16s(c, c:off("sSlotPayouts"), 9),
    reelStopShocks = u16s(c, c:off("sReelStopShocks"), 5),
    reelButtonOffsets = s16s(c, c:off("sReelButtonOffsets"), 3),
    pikaPowerTiles = grid(c, u16s, c:off("sPikaPowerTileTable"), 3, 2, 2),
    reelTimePikachuAnimIds = u8s(c, c:off("sReelTimePikachuAnimIds"), 4),
    reelTimeBoltDelays = s16s(c, c:off("sReelTimeBoltDelays"), 4),
    pikachuAuraFlashDelays = s16s(c, c:off("sPikachuAuraFlashDelays"), 4),
    digitalCoords = grid(c, s16s, c:off("sDigitalDisplay_SpriteCoords"), S.size("sDigitalDisplay_SpriteCoords") / 4, 2, 2),
    matchLinePalOffsets = u8s(c, c:off("sMatchLinePalOffsets"), 5),
    betToMatchLineIds = grid(c, u8s, c:off("sBetToMatchLineIds"), 3, 2, 1),
    matchLinesPerBet = u8s(c, c:off("sMatchLinesPerBet"), 3),
    -- pokeemerald/src/trig.c:5
    sine = s16s(c, c:off("gSineTable"), S.size("gSineTable") / 2),
    sineDeg = s16s(c, c:off("gSineDegreeTable"), S.size("gSineDegreeTable") / 2),
  }

  local scenes = {}
  local scOff = c:off("sDigitalDisplayScenes")
  for i = 0, S.size("sDigitalDisplayScenes") / 4 - 1 do
    local p = c:ptr(scOff + i * 4)
    local list = {}
    for j = 0, 15 do
      local tplId = c:u8(p + j * 4)
      if tplId == 255 then break end
      list[#list + 1] = { tpl = tplId, info = c:u8(p + j * 4 + 1), id = c:s16(p + j * 4 + 2) }
    end
    scenes[i] = list
  end
  tables.digitalScenes = scenes
  tables.fanfares = M.fanfares(c)

  local lit, dark = {}, {}
  for i = 0, 4 do
    lit[i] = c:u16(c:ptr(c:off("sLitMatchLinePalTable") + i * 4))
    dark[i] = c:u16(c:ptr(c:off("sDarkMatchLinePalTable") + i * 4))
  end

  local palettes = {
    menu = K.palList(c:pal("gSlotMachineMenu_Pal", 80), 0, 80),
    unk = palAt(c, c:off("sUnkPalette"), 16),
    menuRow1 = palAt(c, c:ptr(c:off("sSlotMachineMenu_Pal")), 16),
    litMatchLine = lit,
    darkMatchLine = dark,
    flashingLights = {},
    pokeballShining = {},
    sprites = {},
  }
  for i = 0, 2 do palettes.flashingLights[i] = palAt(c, c:ptr(c:off("sFlashingLightsPalTable") + i * 4), 16) end
  for i = 0, 3 do palettes.pokeballShining[i] = palAt(c, c:ptr(c:off("sPokeballShiningPalTable") + i * 4), 16) end
  local spOff = c:off("sSlotMachineSpritePalettes")
  for i = 0, 15 do
    local p = c:ptr(spOff + i * 8)
    if not p then break end
    palettes.sprites[#palettes.sprites + 1] = { tag = c:u16(spOff + i * 8 + 4), colors = palAt(c, p, 16) }
  end

  -- pokeemerald/src/slot_machine.c:5060
  local menuGfx = c:lz("gSlotMachineMenu_Gfx")
  c:write("menu_tiles.4bpp", menuGfx)
  local function u16map(bytes)
    local t = {}
    for i = 0, math.floor(#bytes / 2) - 1 do
      local lo, hi = bytes:byte(i * 2 + 1, i * 2 + 2)
      t[i + 1] = lo + hi * 256
    end
    return t
  end
  local tilemaps = {
    menu = u16map(c:raw("gSlotMachineMenu_Tilemap")),
    infoBox = u16map(c:raw("gSlotMachineInfoBox_Tilemap")),
    reelTimeWindow = u16map(c:raw("sReelTimeWindow_Tilemap")),
  }

  local sprites = {}
  local function one(key, name, w, h, count)
    local gfx = c:raw(name)
    local t = {}
    for i = 0, (count or 1) - 1 do t[i + 1] = i * (w * h / 64) end
    return M.plain(c, key, gfx, w, h, t)
  end

  local symbols = {}
  for i = 1, 7 do symbols[i] = K.bakeSprite(c:raw("gSlotMachineReelSymbol" .. i .. "Tiles"), 32, 32, 0, 4) end
  sprites.reelSymbols = M.sheet(c, "reel_symbols", symbols, 32, 32)
  local digits = {}
  for i = 0, 9 do digits[i + 1] = K.bakeSprite(c:raw("gSlotMachineNumber" .. i .. "Tiles"), 8, 16, 0, 4) end
  sprites.numbers = M.sheet(c, "numbers", digits, 8, 16)

  -- pokeemerald/src/slot_machine.c:5041
  local bgTile = c:raw("gSlotMachineReelBackground_Tilemap")
  local bgGfx = string.rep(bgTile, 64)
  sprites.reelBackground = M.composed(c, "reel_background", bgGfx, { 0 },
    { M.subspriteTable(c, c:off("sSubspriteTable_ReelBackground")) })

  -- pokeemerald/src/slot_machine.c:5017
  local rt = c:lz("sReelTimeGfx")
  sprites.reelTimePikachu = M.plain(c, "reel_time_pikachu", rt, 64, 64, { 0, 64, 128, 192, 256 })
  sprites.reelTimePikachu.anims = templateAnims(c, "sSpriteTemplate_ReelTimePikachu")
  sprites.reelTimeAntennae = M.composed(c, "reel_time_antennae", rt, { 0x2800 / 32 },
    { M.subspriteTable(c, c:off("sSubspriteTable_ReelTimeMachineAntennae")) })
  sprites.reelTimeMachine = M.composed(c, "reel_time_machine", rt, { 0x2B00 / 32 },
    { M.subspriteTable(c, c:off("sSubspriteTable_ReelTimeMachine")) })
  sprites.brokenReelTimeMachine = M.composed(c, "broken_reel_time_machine", rt, { 0x3000 / 32 },
    { M.subspriteTable(c, c:off("sSubspriteTable_BrokenReelTimeMachine")) })

  local rtNums = {}
  for i = 0, 5 do rtNums[i + 1] = K.bakeSprite(c:raw("gSlotMachineReelTimeNumber" .. i), 16, 16, 0, 4) end
  sprites.reelTimeNumbers = M.sheet(c, "reel_time_numbers", rtNums, 16, 16)
  sprites.reelTimeNumbers.anims = templateAnims(c, "sSpriteTemplate_ReelTimeNumbers")
  sprites.reelTimeShadow = M.composed(c, "reel_time_shadow", c:raw("gSlotMachineReelTimeShadow"), { 0 },
    { M.subspriteTable(c, c:off("sSubspriteTable_ReelTimeShadow")) })
  sprites.reelTimeNumberGap = M.composed(c, "reel_time_number_gap", c:raw("gSlotMachineReelTimeNumberGap_Gfx"), { 0 },
    { M.subspriteTable(c, c:off("sSubspriteTable_ReelTimeNumberGap")) })
  local bolts = { K.bakeSprite(c:raw("gSlotMachineReelTimeBolt0"), 16, 32, 0, 4), K.bakeSprite(c:raw("gSlotMachineReelTimeBolt1"), 16, 32, 0, 4) }
  sprites.reelTimeBolt = M.sheet(c, "reel_time_bolt", bolts, 16, 32, { anims = templateAnims(c, "sSpriteTemplate_ReelTimeBolt") })
  sprites.reelTimePikaAura = one("reel_time_pika_aura", "gSlotMachineReelTimePikaAura", 32, 64)
  local expl = { K.bakeSprite(c:raw("gSlotMachineReelTimeExplosion0"), 32, 32, 0, 4), K.bakeSprite(c:raw("gSlotMachineReelTimeExplosion1"), 32, 32, 0, 4) }
  sprites.reelTimeExplosion = M.sheet(c, "reel_time_explosion", expl, 32, 32, { anims = templateAnims(c, "sSpriteTemplate_ReelTimeExplosion") })
  sprites.reelTimeDuck = one("reel_time_duck", "gSlotMachineReelTimeDuck", 8, 8)
  sprites.reelTimeSmoke = one("reel_time_smoke", "gSlotMachineReelTimeSmoke", 16, 16)
  sprites.reelTimeSmoke.affineAnims = M.affineTable(c, c:off("sAffineAnims_ReelTimeSmoke"), 1)
  sprites.pikaPowerBolt = one("pika_power_bolt", "gSlotMachinePikaPowerBolt", 8, 8)
  sprites.pikaPowerBolt.affineAnims = M.affineTable(c, c:off("sAffineAnims_PikaPowerBolt"), 1)

  -- pokeemerald/src/slot_machine.c:5017
  local dd = c:lz("gSlotMachineDigitalDisplay_Gfx")
  local tplOff, subOff = c:off("sSpriteTemplates_DigitalDisplay"), c:off("sSubspriteTables_DigitalDisplay")
  local digital = {}
  for i = 0, 24 do
    local tp = c:ptr(tplOff + i * 4)
    local sp = c:ptr(subOff + i * 4)
    local oam = c:readOam(c:ptr(tp + 4))
    local anims = {}
    local ap = c:ptr(tp + 8)
    local names = S.namesAt(ap)
    for _, n in ipairs(names) do
      local ok, size = pcall(S.size, n)
      if not ok then ok, size = pcall(S.size, "slot_machine.o:" .. n) end
      if ok and size then anims = c:readAnimTable(ap, size / 4) break end
    end
    for _, a in ipairs(anims) do
      for _, cmd in ipairs(a) do if cmd.op == "frame" then cmd.frame = cmd.tile end end
    end
    local d = DIG[i]
    local bt = baseTiles(d)
    local entry
    if sp then
      local subs, t = {}, 0
      while true do
        local n = c:u8(sp + t * 8)
        local p = c:ptr(sp + t * 8 + 4)
        if n == 0 or not p then break end
        subs[#subs + 1] = M.subspriteTable(c, sp + t * 8)
        t = t + 1
        if i ~= 6 or t >= 2 then break end
      end
      entry = M.composed(c, "digital_" .. i, dd, bt, subs)
    else
      entry = M.plain(c, "digital_" .. i, dd, oam.w, oam.h, bt)
    end
    entry.anims = anims
    entry.w0, entry.h0 = oam.w, oam.h
    digital[i] = entry
  end
  sprites.digital = digital

  -- pokeemerald/src/field_specials.c:1289
  local fieldIds = {
    seeds = u8s(c, c:off("sSlotMachineRandomSeeds.204"), 12),
    normal = u8s(c, c:off("sSlotMachineIds.205"), 12),
    serviceDay = u8s(c, c:off("sSlotMachineServiceDayIds.206"), 12),
  }

  local manifest = {
    screen = "slot_machine",
    fieldIds = fieldIds,
    menuTiles = c:path("menu_tiles.4bpp"),
    tables = tables,
    palettes = palettes,
    tilemaps = tilemaps,
    sprites = sprites,
  }
  return true, c:finish(manifest)
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

M.REQUIRED = K.required(M.SUB, { "menu_tiles.4bpp", "reel_symbols.png", "numbers.png", "digital_0_0.png" })

return M
