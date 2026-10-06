local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Shared = require("src.import.gba.rse.slot_machine_extract")

local M = { SUB = "rse_slot_machine" }

local function slot(name) return "slot_machine.o:" .. name end

local function array(c, name, count, kind)
  local off = c:off(name)
  local stride = kind == "u8" and 1 or 2
  assert(c.S.size(name) == count * stride, "RS slots: unexpected table size " .. name)
  local out = {}
  for i = 0, count - 1 do out[i] = c[kind](c, off + i * stride) end
  return out
end

local function grid(c, name, rows, cols, kind)
  local values = array(c, name, rows * cols, kind)
  local out = {}
  for r = 0, rows - 1 do
    out[r] = {}
    for col = 0, cols - 1 do out[r][col] = values[r * cols + col] end
  end
  return out
end

local function palette(c, off, count)
  return K.palList(c:palAt(off, count), 0, count)
end

local function map(c, name, count)
  local native, out = array(c, name, count, "u16"), {}
  for i = 0, count - 1 do out[i + 1] = native[i] end
  return out
end

-- pokeruby/src/slot_machine.c:4685
local DIGITAL = {
  [0] = { 0x0000 }, [1] = { 0x0600 }, [2] = { 0x0800 },
  [3] = { 0x0C00 }, [4] = { 0x1000 },
  [5] = { 0x1C00, 0x1E00, 0x1E00 }, [6] = { 0x2000 },
  [7] = { 0x2280, 0x2300, 0x2380, 0x2400, 0x2480 },
  [8] = { 0x2600, 0x2A80 }, [9] = { 0x2F00, 0x3080 },
  [10] = { 0x0A00 }, [11] = { 0x0A00 }, [12] = { 0x0A00 }, [13] = { 0x0A00 },
  [14] = { 0x1400 }, [15] = { 0x1400 }, [16] = { 0x1400 }, [17] = { 0x1400 }, [18] = { 0x1400 },
  [19] = { 0x1600 }, [20] = { 0x1600 }, [21] = { 0x1600 },
  [22] = { 0x1900 }, [23] = { 0x1900 }, [24] = { 0x1900 },
}

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/slot_machine.c:4131
  local tables = {
    reelSymbols = grid(c, slot("sReelSymbols"), 3, 21, "u8"),
    reelTimeSymbols = array(c, slot("gUnknown_083ECCF1"), 6, "u8"),
    initialReelPositions = grid(c, slot("gUnknown_083ECCF8"), 3, 2, "s16"),
    specialDrawOdds = grid(c, slot("gUnknown_083ECD04"), 6, 3, "u8"),
    biasProbSpecial = grid(c, slot("gUnknown_083ECD16"), 3, 6, "u8"),
    biasProbRegular = grid(c, slot("gUnknown_083ECD28"), 5, 6, "u8"),
    reelTimeProbNormal = grid(c, slot("gUnknown_083ECD46"), 6, 17, "u8"),
    reelTimeProbLucky = grid(c, slot("gUnknown_083ECDAC"), 6, 17, "u8"),
    reelTimeExplodeProb = array(c, slot("gUnknown_083ECE12"), 5, "u16"),
    reelTimeSpeedProb = grid(c, slot("gUnknown_083ECE1C"), 5, 2, "u16"),
    quarterSpeedBoost = array(c, slot("gUnknown_083ECE30"), 5, "u16"),
    biasSymbols = array(c, slot("gUnknown_083ECE3A"), 8, "u8"),
    biasesSpecial = array(c, slot("gUnknown_083ECE42"), 3, "u16"),
    biasesRegular = array(c, slot("gUnknown_083ECE48"), 5, "u16"),
    symbolToMatch = array(c, slot("sSym2Match"), 7, "u8"),
    matchFlags = array(c, slot("sSlotMatchFlags"), 9, "u16"),
    payouts = array(c, slot("sSlotPayouts"), 9, "u16"),
    reelButtonOffsets = array(c, slot("gUnknown_083ECBAC"), 3, "s16"),
    pikaPowerTiles = grid(c, slot("gUnknown_083ECBC4"), 3, 2, "u16"),
    digitalCoords = grid(c, slot("gUnknown_083ECE7E"), 35, 2, "s16"),
    matchLinePalOffsets = array(c, slot("gUnknown_083EDD30"), 5, "u8"),
    betToMatchLineIds = grid(c, slot("gUnknown_083EDD35"), 3, 2, "u8"),
    matchLinesPerBet = array(c, slot("gUnknown_083EDD3B"), 3, "u8"),
    sine = array(c, "gSineTable", c.S.size("gSineTable") / 2, "s16"),
    sineDeg = array(c, "gSineDegreeTable", c.S.size("gSineDegreeTable") / 2, "s16"),
    reelStopShocks = { [0] = 2, 4, 4, 4, 8 },
    reelTimePikachuAnimIds = { [0] = 1, 1, 2, 2 },
    reelTimeBoltDelays = { [0] = 64, 48, 24, 8 },
    pikachuAuraFlashDelays = { [0] = 10, 8, 6, 4 },
    digitalScenes = {}, fanfares = {},
  }
  local sceneName = slot("gUnknown_083ED048")
  assert(c.S.size(sceneName) == 7 * 4, "RS slots: unexpected digital scene count")
  for i = 0, 6 do
    local p = assert(c:ptr(c:off(sceneName) + i * 4), "RS slots: missing digital scene")
    local list, terminated = {}, false
    for j = 0, 15 do
      local off = p + j * 4
      local id = c:u8(off)
      if id == 255 then terminated = true; break end
      list[#list + 1] = { tpl = id, info = c:u8(off + 1), id = c:s16(off + 2) }
    end
    assert(terminated, "RS slots: unterminated digital scene")
    tables.digitalScenes[i] = list
  end
  local fanName = "sound.o:sFanfares"
  local fanOff = c:off(fanName)
  for i = 0, c.S.size(fanName) / 4 - 1 do
    tables.fanfares[c:u16(fanOff + i * 4)] = c:u16(fanOff + i * 4 + 2)
  end

  -- pokeruby/src/slot_machine.c:5482
  local palettes = {
    menu = palette(c, c:off("gUnknown_08E95A18"), 80),
    unk = palette(c, c:off(slot("gPalette_83EDE24")), 16),
    menuRow1 = palette(c, assert(c:ptr(c:off(slot("gUnknown_083EDDAC")))), 16),
    litMatchLine = {}, darkMatchLine = {}, flashingLights = {},
    pokeballShining = {}, sprites = {},
  }
  for i = 0, 4 do
    palettes.litMatchLine[i] = c:u16(assert(c:ptr(c:off(slot("gUnknown_083EDD08")) + i * 4)))
    palettes.darkMatchLine[i] = c:u16(assert(c:ptr(c:off(slot("gUnknown_083EDD1C")) + i * 4)))
  end
  for i = 0, 2 do palettes.flashingLights[i] = palette(c, assert(c:ptr(c:off(slot("gUnknown_083EDDA0")) + i * 4)), 16) end
  for i = 0, 3 do palettes.pokeballShining[i] = palette(c, assert(c:ptr(c:off(slot("gUnknown_083EDE10")) + i * 4)), 16) end
  local spritePals = slot("gSlotMachineSpritePalettes")
  assert(c.S.size(spritePals) == 9 * 8, "RS slots: unexpected sprite palette count")
  for i = 0, 7 do
    local off = c:off(spritePals) + i * 8
    palettes.sprites[i + 1] = { tag = c:u16(off + 4), colors = palette(c, assert(c:ptr(off)), 16) }
  end
  assert(not c:ptr(c:off(spritePals) + 8 * 8), "RS slots: missing sprite palette terminator")

  -- slot_machine.c:4067
  local menuGfx = c:lz("gSlotMachine_Gfx")
  assert(#menuGfx >= 233 * 32, "RS slots: short menu graphics")
  c:write("menu_tiles.4bpp", menuGfx:sub(1, 233 * 32))
  local tilemaps = {
    menu = map(c, "gUnknown_08E95AB8", 640),
    infoBox = map(c, "gUnknown_08E95FB8", 640),
    reelTimeWindow = map(c, slot("sReelTimeWindowTilemap"), 220),
  }
  local sprites = {}
  local function one(key, name, w, h)
    return Shared.plain(c, key, c:raw(name), w, h, { 0 })
  end
  local function composed(key, gfx, base, name)
    return Shared.composed(c, key, gfx, base, { Shared.subspriteTable(c, c:off(slot(name))) })
  end
  local function anims(name) return Shared.templateAnims(c, slot(name)) end
  local symbols, digits = {}, {}
  for i = 1, 7 do symbols[i] = K.bakeSprite(c:raw("gSlotMachineReelSymbol" .. i .. "Tiles"), 32, 32, 0, 4) end
  for i = 0, 9 do digits[i + 1] = K.bakeSprite(c:raw("gSlotMachineNumber" .. i .. "Tiles"), 8, 16, 0, 4) end
  sprites.reelSymbols = Shared.sheet(c, "reel_symbols", symbols, 32, 32)
  sprites.numbers = Shared.sheet(c, "numbers", digits, 8, 16)
  local bgOff = assert(c:ptr(c:off(slot("gUnknown_083EDCE4"))))
  local bgGfx = string.rep(rom:readString(bgOff, 32), 64)
  sprites.reelBackground = composed("reel_background", bgGfx, { 0 }, "gSubspriteTables_83ED704")

  local rt = c:lz(slot("sReelTimeGfx"))
  sprites.reelTimePikachu = Shared.plain(c, "reel_time_pikachu", rt, 64, 64, { 0, 64, 128, 192, 256 })
  sprites.reelTimePikachu.anims = anims("gSpriteTemplate_83ED45C")
  sprites.reelTimeAntennae = composed("reel_time_antennae", rt, { 0x2800 / 32 }, "gSubspriteTables_83ED73C")
  sprites.reelTimeMachine = composed("reel_time_machine", rt, { 0x2B00 / 32 }, "gSubspriteTables_83ED75C")
  sprites.brokenReelTimeMachine = composed("broken_reel_time_machine", rt, { 0x3000 / 32 }, "gSubspriteTables_83ED78C")
  local rtNumbers = {}
  for i, name in ipairs({ "gSpriteImage_8E988E8", "gSpriteImage_8E98968", "gSpriteImage_8E989E8", "gSpriteImage_8E98A68", "gSpriteImage_8E98AE8", "gSpriteImage_8E98B68" }) do
    rtNumbers[i] = K.bakeSprite(c:raw(name), 16, 16, 0, 4)
  end
  sprites.reelTimeNumbers = Shared.sheet(c, "reel_time_numbers", rtNumbers, 16, 16)
  sprites.reelTimeNumbers.anims = anims("gSpriteTemplate_83ED4BC")
  sprites.reelTimeShadow = composed("reel_time_shadow", c:raw("gSpriteImage_8E991E8"), { 0 }, "gSubspriteTables_83ED7B4")
  sprites.reelTimeNumberGap = composed("reel_time_number_gap", c:raw("gSpriteImage_8E99808"), { 0 }, "gSubspriteTables_83ED7D4")
  local bolts = { K.bakeSprite(c:raw("gSpriteImage_8E98BE8"), 16, 32, 0, 4), K.bakeSprite(c:raw("gSpriteImage_8E98CE8"), 16, 32, 0, 4) }
  sprites.reelTimeBolt = Shared.sheet(c, "reel_time_bolt", bolts, 16, 32, { anims = anims("gSpriteTemplate_83ED504") })
  sprites.reelTimePikaAura = one("reel_time_pika_aura", "gSpriteImage_8E993E8", 32, 64)
  local explosions = { K.bakeSprite(c:raw("gSpriteImage_8E98DE8"), 32, 32, 0, 4), K.bakeSprite(c:raw("gSpriteImage_8E98FE8"), 32, 32, 0, 4) }
  sprites.reelTimeExplosion = Shared.sheet(c, "reel_time_explosion", explosions, 32, 32, { anims = anims("gSpriteTemplate_83ED534") })
  sprites.reelTimeDuck = one("reel_time_duck", "gSpriteImage_8E98848", 8, 8)
  sprites.reelTimeSmoke = one("reel_time_smoke", "gSpriteImage_8E98868", 16, 16)
  sprites.reelTimeSmoke.affineAnims = Shared.affineTable(c, c:off(slot("gSpriteAffineAnimTable_83ED3BC")), 1)
  sprites.pikaPowerBolt = one("pika_power_bolt", "gSpriteImage_8E98828", 8, 8)
  sprites.pikaPowerBolt.affineAnims = Shared.affineTable(c, c:off(slot("gSpriteAffineAnimTable_83ED410")), 1)

  -- pokeruby/src/slot_machine.c:5397
  local display = c:lz("gSlotMachineReelTimeLights_Gfx")
  local tplName, subName = slot("gUnknown_083EDB5C"), slot("gUnknown_083EDBC4")
  assert(c.S.size(tplName) == 26 * 4 and c.S.size(subName) == 26 * 4, "RS slots: unexpected digital pointer table")
  sprites.digital = {}
  for i = 0, 24 do
    local tp = assert(c:ptr(c:off(tplName) + i * 4))
    local sp = c:ptr(c:off(subName) + i * 4)
    local oam = c:readOam(assert(c:ptr(tp + 4)))
    local commands = c:readAnimTable(assert(c:ptr(tp + 8)), nil, "slot_machine.o")
    for _, animation in ipairs(commands) do
      for _, command in ipairs(animation) do if command.op == "frame" then command.frame = command.tile end end
    end
    local tiles = {}
    for j, byteOffset in ipairs(DIGITAL[i]) do tiles[j] = byteOffset / 32 end
    local entry
    if sp then
      local subs = { Shared.subspriteTable(c, sp) }
      if i == 6 then subs[2] = Shared.subspriteTable(c, sp + 8) end
      entry = Shared.composed(c, "digital_" .. i, display, tiles, subs)
    else
      entry = Shared.plain(c, "digital_" .. i, display, oam.w, oam.h, tiles)
    end
    entry.anims, entry.w0, entry.h0 = commands, oam.w, oam.h
    sprites.digital[i] = entry
  end
  local fieldIds = {
    seeds = array(c, "gUnknown_083F83E0", 12, "u8"),
    normal = array(c, "gUnknown_083F83EC", 12, "u8"),
    serviceDay = array(c, "gUnknown_083F83F8", 12, "u8"),
  }
  return A.finish(c, {
    screen = "slot_machine", slotVersion = 3,
    fieldIds = fieldIds, menuTiles = c:path("menu_tiles.4bpp"),
    tables = tables, palettes = palettes, tilemaps = tilemaps, sprites = sprites,
  })
end

M.FILES = {
  "menu_tiles.4bpp", "reel_symbols.png", "numbers.png", "reel_background_0.png",
  "reel_time_pikachu.png", "reel_time_antennae_0.png", "reel_time_machine_0.png",
  "broken_reel_time_machine_0.png", "reel_time_numbers.png", "reel_time_shadow_0.png",
  "reel_time_number_gap_0.png", "reel_time_bolt.png", "reel_time_pika_aura.png",
  "reel_time_explosion.png", "reel_time_duck.png", "reel_time_smoke.png", "pika_power_bolt.png",
}
for i = 0, 24 do
  M.FILES[#M.FILES + 1] = "digital_" .. i .. ((i == 4 or i == 5 or i == 7) and ".png" or "_0.png")
  if i == 6 then M.FILES[#M.FILES + 1] = "digital_6_1.png" end
end
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local prefix = (root or "data/generated/gba") .. "/"
  local body = cache:read(prefix .. M.SUB .. "/manifest.lua")
  if not body:find("slotVersion = 3", 1, true) then return false end
  for _, path in ipairs(M.REQUIRED) do
    if not cache:exists(prefix .. path) then return false end
  end
  return true
end

return M
