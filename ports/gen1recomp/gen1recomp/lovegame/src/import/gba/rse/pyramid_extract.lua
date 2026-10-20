local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/pyramid"
M.FILES = { "bag_screen.gfx", "bag_menu.map", "bag_sprite.gfx" }
M.REQUIRED = K.required(M.SUB, M.FILES)

local function bytesAt(c, off, maxLen)
  local out = {}
  for i = 0, (maxLen or 1024) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

local function nameAt(c, off)
  local names = c.S.namesAt(off)
  for _, n in ipairs(names) do
    if not n:find(":", 1, true) then return n end
  end
  return names[1] and (names[1]:gsub("^.-:", "")) or nil
end

local function textRef(c, p)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return { name = nameAt(c, p), key = string.format("g3:%08x", p + 0x08000000),
    ir = TextIR.decode(bytesAt(c, p), { dialect = "rse" }) }
end

local function u8s(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name)) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function u16s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 2 - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

local function pairsU8(c, name, stride)
  stride = stride or 2
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / stride - 1 do out[i + 1] = { c:u8(off + i * stride), c:u8(off + i * stride + 1) } end
  return out
end

local function sizedCount(c, ptr, stride, obj)
  local size = c:sizedAt(ptr, obj)
  assert(size, string.format("pyramid_extract: no sized symbol at 0x%X", ptr))
  return math.floor(size / stride)
end

-- pokeemerald/src/battle_pyramid.c:107
local function floorTemplates(c)
  local name = "sPyramidFloorTemplates"
  local off, out = c:off(name), {}
  local stride = 16
  for i = 0, math.floor(c.S.size(name) / stride) - 1 do
    local e = off + i * stride
    local offs = {}
    for j = 0, 7 do offs[j + 1] = c:u8(e + 5 + j) end
    out[i + 1] = {
      numItems = c:u8(e), numTrainers = c:u8(e + 1), itemPositions = c:u8(e + 2),
      trainerPositions = c:u8(e + 3), runMultiplier = c:u8(e + 4), layoutOffsets = offs,
    }
  end
  return out
end

-- pokeemerald/src/battle_pyramid.c:289
local function pickupItems(c, name, perRound)
  local off, out = c:off(name), {}
  local rounds = c.S.size(name) / (perRound * 2)
  for r = 0, rounds - 1 do
    local row = {}
    for i = 0, perRound - 1 do row[i + 1] = c:u16(off + (r * perRound + i) * 2) end
    out[r + 1] = row
  end
  return out
end

-- pokeemerald/src/battle_pyramid.c:45
local function wildMons(c, name)
  local off, out = c:off(name), {}
  for r = 0, c.S.size(name) / 4 - 1 do
    local p = c:ptr(off + r * 4)
    local n = sizedCount(c, p, 12, "battle_pyramid.o")
    local list = {}
    for i = 0, n - 1 do
      local e = p + i * 12
      list[i + 1] = {
        species = c:u16(e), lvl = c:u8(e + 2), abilityNum = c:u8(e + 3),
        moves = { c:u16(e + 4), c:u16(e + 6), c:u16(e + 8), c:u16(e + 10) },
      }
    end
    out[r + 1] = list
  end
  return out
end

-- pokeemerald/src/battle_pyramid.c:765
local function postBattleTexts(c)
  local off, out = c:off("sPostBattleTexts"), {}
  for g = 0, c.S.size("sPostBattleTexts") / 4 - 1 do
    local groupPtr = c:ptr(off + g * 4)
    local group = {}
    for t = 0, 2 do
      local listPtr = c:ptr(groupPtr + t * 4)
      local n = sizedCount(c, listPtr, 4, "battle_pyramid.o")
      local list = {}
      for i = 0, n - 1 do list[i + 1] = textRef(c, c:ptr(listPtr + i * 4)) end
      group[t + 1] = list
    end
    out[g + 1] = group
  end
  return out
end

local function signed8(v)
  return v >= 128 and v - 256 or v
end

-- pokeemerald/src/battle_pyramid.c:812
local function borderedSquares(c)
  local off, out = c:off("sBorderedSquareIds"), {}
  for i = 0, c.S.size("sBorderedSquareIds") / 4 - 1 do
    local row = {}
    for j = 0, 3 do row[j + 1] = c:u8(off + i * 4 + j) end
    out[i + 1] = row
  end
  return out
end

local function floorPalettes(c)
  local name = "gBattlePyramidFloor_Pal"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 32 - 1 do
    out[i + 1] = K.palList(c:palAt(off + i * 32, 16), 0, 16)
  end
  return out
end

-- pokeemerald/src/start_menu.c:150
local function floorNames(c)
  local off, out = c:off("sPyramidFloorNames"), {}
  for i = 0, c.S.size("sPyramidFloorNames") / 4 - 1 do out[i + 1] = textRef(c, c:ptr(off + i * 4)) end
  return out
end

-- pokeemerald/src/battle_pyramid_bag.c:563
local function bagGfx(c)
  local screen = c:lz("gBagScreen_Gfx")
  c:write("bag_screen.gfx", screen)
  local map = c:lz("gBattlePyramidBagTilemap")
  c:write("bag_menu.map", map)
  local sprite = c:lz("gBattlePyramidBag_Gfx")
  c:write("bag_sprite.gfx", sprite)
  local spritePals = c:palFrom(c:lz("gBattlePyramidBag_Pal"), 32)
  return {
    gfx = {
      screen = { path = c:path("bag_screen.gfx"), bytes = #screen },
      sprite = { path = c:path("bag_sprite.gfx"), bytes = #sprite },
    },
    maps = { menu = { path = c:path("bag_menu.map"), entries = #map / 2 } },
    palettes = {
      interface = K.palList(c:palFrom(c:lz("gBattlePyramidBagInterface_Pal"), 16), 0, 16),
      sprite = { K.palList(spritePals, 0, 16), K.palList(spritePals, 16, 16) },
    },
  }
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local bag = bagGfx(c)
  local bordered = borderedSquares(c)
  for _, row in ipairs(bordered) do
    for j = 1, 4 do row[j] = signed8(row[j]) end
  end
  return true, c:finish({
    screen = "pyramid",
    floorTemplates = floorTemplates(c),
    floorTemplateOptions = pairsU8(c, "sPyramidFloorTemplateOptions"),
    floorTemplateOffsets = u8s(c, "sFloorTemplateOffsets"),
    pickupItems50 = pickupItems(c, "sPickupItemsLvl50", 10),
    pickupItemsOpen = pickupItems(c, "sPickupItemsLvlOpen", 10),
    pickupItemSlots = pairsU8(c, "sPickupItemSlots"),
    pickupItemOffsets = u8s(c, "sPickupItemOffsets"),
    pickupPercentages = u8s(c, "sPickupPercentages"),
    encounterMusic = pairsU8(c, "sTrainerClassEncounterMusic", 4),
    textGroups = pairsU8(c, "sTrainerTextGroups"),
    postBattleTexts = postBattleTexts(c),
    hintTextTypes = u8s(c, "sHintTextTypes"),
    shortStreakRewards = u16s(c, "sShortStreakRewardItems"),
    longStreakRewards = u16s(c, "sLongStreakRewardItems"),
    borderedSquares = bordered,
    wildMons50 = wildMons(c, "sLevel50WildMonPointers"),
    wildMonsOpen = wildMons(c, "sOpenLevelWildMonPointers"),
    floorPalettes = floorPalettes(c),
    floorNames = floorNames(c),
    extraScripts = require("src.import.gba.rse.f4_scripts").closure(c, {
      "BattlePyramid_WarpToNextFloor", "BattlePyramid_Retire", "BattlePyramid_TrainerBattle", "BattlePyramid_FindItemBall",
    }),
    mapHeaders = (function()
      local name = "sBattlePyramid_MapHeaderStrings"
      local off, out = c:off(name), {}
      for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = textRef(c, c:ptr(off + i * 4)) end
      return out
    end)(),
    confirmRetire = textRef(c, c:off("gText_BattlePyramidConfirmRetire")),
    confirmRest = textRef(c, c:off("gText_BattlePyramidConfirmRest")),
    bagReturnTo = (function()
      local name = "gPyramidBagMenu_ReturnToStrings"
      local off, out = c:off(name), {}
      for i = 0, c.S.size(name) / 4 - 1 do out[i + 1] = textRef(c, c:ptr(off + i * 4)) end
      return out
    end)(),
    gfx = bag.gfx,
    maps = bag.maps,
    palettes = bag.palettes,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
