local regions = {}

local WHY = {
  unused = "padding or an unused field the game never reads",
  scratch = "runtime scratch with no engine state behind it, carried from the cart",
  derived = "rebuilt from the model on a map or cell change, or rebuilt by the game on load",
  progress = "per-map script state the engine does not model, carried from the cart",
}

local function R(offset, size, tier, name, extra)
  local r = { offset = offset, size = size, tier = tier, name = name }
  for k, v in pairs(extra or {}) do r[k] = v end
  if r.kind and not r.why then r.why = WHY[r.kind] end
  regions[#regions + 1] = r
  return r
end

local NAME = 11

local function list(prefix, base, cap, structSize, tier)
  R(base, 2 + cap + cap * (structSize + 2 * NAME), tier, prefix)
  R(base, 1, tier, prefix .. ".count")
  R(base + 1, cap + 1, tier, prefix .. ".species")
  local monsAt = base + 2 + cap
  local otAt = monsAt + cap * structSize
  local nickAt = otAt + cap * NAME
  for i = 1, cap do
    R(monsAt + (i - 1) * structSize, structSize, tier, ("%s.mon%d"):format(prefix, i))
    R(otAt + (i - 1) * NAME, NAME, tier, ("%s.ot%d"):format(prefix, i))
    R(nickAt + (i - 1) * NAME, NAME, tier, ("%s.nick%d"):format(prefix, i))
  end
end

-- ram/sram.asm:3
R(0x0000, 0x598, "T2", "spriteBuffers", { kind = "scratch" })
-- ram/sram.asm:9
R(0x0598, 0x12C0, "T1", "hallOfFame", { ids = "G1-08" })
R(0x1858, 0x7A8, "T2", "bank0Unused", { kind = "unused" })
R(0x2000, 0x24, "T1", "identityTag")
R(0x2024, 0x574, "T2", "bank1Unused", { ids = "G1-25", kind = "unused" })
-- ram/sram.asm:16
R(0x2598, NAME, "T1", "playerName", { ids = "G1-22" })
R(0x25A3, 0x789, "T2", "mainData", { kind = "umbrella" })
R(0x25A3, 19, "T1", "dexOwned")
R(0x25B6, 19, "T1", "dexSeen")
R(0x25C9, 42, "T1", "bag", { ids = "G1-13" })
R(0x25F3, 3, "T1", "money")
R(0x25F6, NAME, "T1", "rivalName")
R(0x2601, 1, "T1", "options", { ids = "G1-09" })
R(0x2602, 1, "T1", "badges")
R(0x2603, 1, "T2", "unusedObtainedBadges", { kind = "unused" })
R(0x2604, 1, "T2", "letterPrintingDelayFlags", { kind = "scratch" })
R(0x2605, 2, "T1", "playerId")
R(0x2607, 2, "T2", "mapMusic", { kind = "derived" })
R(0x2609, 1, "T1", "mapPalOffset")
R(0x260A, 1, "T1", "curMap")
R(0x260B, 2, "T2", "viewPointer", { kind = "derived" })
R(0x260D, 1, "T1", "yCoord")
R(0x260E, 1, "T1", "xCoord")
R(0x260F, 2, "T2", "blockCoords", { kind = "derived" })
R(0x2611, 1, "T1", "lastMap")
R(0x2612, 0x1D4, "T2", "mapWindow", { kind = "derived" })
R(0x26DC, 0x40, "T2", "yellowFollowerRuntime", { kind = "scratch" })
R(0x271C, 1, "T1", "pikachuHappiness")
R(0x271D, 1, "T1", "pikachuMood")
R(0x271E, 1, "T2", "pikachuSpawnStateFlags", { kind = "derived" })
R(0x271F, 0x22, "T2", "yellowFollowerFlags", { kind = "scratch" })
R(0x2741, 2, "T1", "surfingMinigameHiScore", { ids = "G1-14" })
R(0x2743, 1, "T2", "surfingMinigameHiScorePad", { kind = "unused" })
R(0x2744, 1, "T2", "printerSettings", { ids = "G1-14", kind = "unused" })
R(0x2745, 3, "T2", "printerScratch", { kind = "scratch" })
R(0x2748, 1, "T1", "pikachuEmotionModifier")
R(0x27E6, 102, "T1", "pcItems", { ids = "G1-13" })
R(0x284C, 1, "T1", "currentBoxNum", { ids = "G1-02 G1-23" })
R(0x284D, 1, "T2", "currentBoxNumHigh", { kind = "unused" })
R(0x284E, 1, "T1", "numHoFTeams", { ids = "G1-08" })
R(0x284F, 1, "T2", "unusedMapVariable", { kind = "unused" })
R(0x2850, 2, "T1", "coins")
R(0x2852, 32, "T1", "toggleableObjectFlags", { ids = "G1-01" })
R(0x2872, 7, "T2", "toggleableObjectFlagsPad", { kind = "unused" })
R(0x2879, 0x23, "T2", "toggleableObjectList", { kind = "derived" })
R(0x289C, 200, "T2", "gameProgressFlags", { ids = "G1-06", kind = "progress" })
R(0x28CB, 1, "T1", "safariGateScript", { ids = "G1-15" })
R(0x2964, 56, "T2", "gameProgressPad", { kind = "unused" })
R(0x299C, 14, "T1", "hiddenItemFlags")
R(0x29AA, 2, "T1", "hiddenCoinFlags", { ids = "G1-15" })
R(0x29AC, 1, "T1", "walkBikeSurfState", { ids = "G1-07" })
R(0x29AD, 10, "T2", "walkBikePad", { kind = "unused" })
R(0x29B7, 2, "T1", "townVisited")
R(0x29B9, 2, "T1", "safariSteps", { ids = "G1-15" })
R(0x29BB, 2, "T1", "fossil")
R(0x29BD, 4, "T2", "fossilScratch", { kind = "scratch" })
R(0x29C1, 1, "T1", "rivalStarter")
R(0x29C2, 1, "T2", "starterPad", { kind = "unused" })
R(0x29C3, 1, "T1", "playerStarter")
R(0x29C4, 1, "T2", "boulderSpriteIndex", { kind = "scratch" })
R(0x29C5, 1, "T1", "lastBlackoutMap", { ids = "G1-07" })
R(0x29C6, 14, "T2", "specialWarpScratch", { kind = "scratch" })
R(0x29D4, 1, "T1", "statusFlags1")
R(0x29D5, 1, "T2", "statusPad1", { kind = "unused" })
R(0x29D6, 1, "T1", "beatGymFlags")
R(0x29D7, 1, "T2", "statusPad2", { kind = "unused" })
R(0x29D8, 2, "T2", "statusFlags2And3", { kind = "scratch" })
R(0x29DA, 1, "T1", "statusFlags4")
R(0x29DB, 1, "T2", "statusPad3", { kind = "unused" })
R(0x29DC, 1, "T2", "statusFlags5", { kind = "scratch" })
R(0x29DD, 1, "T2", "statusPad4", { kind = "unused" })
R(0x29DE, 1, "T1", "statusFlags6")
R(0x29DF, 1, "T2", "statusFlags7", { kind = "scratch" })
R(0x29E0, 1, "T1", "elite4Flags")
R(0x29E1, 1, "T2", "statusPad5", { kind = "unused" })
R(0x29E2, 1, "T2", "movementFlags", { kind = "scratch" })
R(0x29E3, 2, "T1", "inGameTradeFlags", { ids = "G1-04" })
R(0x29E5, 2, "T2", "tradeFlagsPad", { kind = "unused" })
R(0x29E7, 2, "T2", "warpedFrom", { kind = "scratch" })
R(0x29E9, 2, "T2", "warpPad", { kind = "unused" })
R(0x29EB, 2, "T2", "cardKeyDoor", { kind = "scratch" })
R(0x29ED, 2, "T2", "cardKeyPad", { kind = "unused" })
R(0x29EF, 2, "T1", "trashCanIndexes")
R(0x29F1, 2, "T2", "trashCanPad", { kind = "unused" })
R(0x29F3, 320, "T1", "eventFlags", { ids = "G1-05" })
R(0x2B33, 50, "T2", "wildData", { kind = "derived" })
R(0x2B65, 375, "T2", "enemyPartyScratch", { kind = "scratch" })
R(0x2CDC, 8, "T2", "trainerHeaderScratch", { kind = "scratch" })
R(0x2CE4, 1, "T2", "opponentAfterWrongAnswer", { kind = "scratch" })
R(0x2CE5, 1, "T2", "curMapScript", { kind = "progress" })
R(0x2CE6, 7, "T2", "curMapScriptPad", { kind = "unused" })
R(0x2CED, 1, "T1", "playTimeHours")
R(0x2CEE, 1, "T1", "playTimeMaxed", { ids = "G1-11" })
R(0x2CEF, 3, "T1", "playTimeMinSecFrames")
R(0x2CF2, 1, "T2", "safariZoneGameOver", { kind = "scratch" })
R(0x2CF3, 1, "T1", "safariBalls", { ids = "G1-15" })
R(0x2CF4, 0x38, "T1", "dayCare")
R(0x2D2C, 0x200, "T2", "spriteData", { kind = "derived" })
list("party", 0x2F2C, 6, 44, "T1")
list("curBox", 0x30C0, 20, 33, "T1")
R(0x3522, 1, "T2", "tileAnimations", { kind = "derived" })
-- engine/menus/save.asm:240
R(0x3523, 1, "T3", "mainChecksum", { derived = true })
R(0x3524, 0xADC, "T2", "bank1Tail", { kind = "unused" })

for box = 1, 12 do
  local base = box <= 6 and (0x4000 + (box - 1) * 0x462) or (0x6000 + (box - 7) * 0x462)
  list(("box%02d"):format(box), base, 20, 33, "T1")
end
-- ram/sram.asm:41
R(0x5A4C, 1, "T3", "bank2AllBoxesChecksum", { derived = true, ids = "G1-20" })
R(0x5A4D, 6, "T3", "bank2BoxChecksums", { derived = true, ids = "G1-20" })
R(0x5A53, 0x5AD, "T2", "bank2Tail", { kind = "unused" })
-- ram/sram.asm:48
R(0x7A4C, 1, "T3", "bank3AllBoxesChecksum", { derived = true, ids = "G1-20" })
R(0x7A4D, 6, "T3", "bank3BoxChecksums", { derived = true, ids = "G1-20" })
R(0x7A53, 0x5AD, "T2", "bank3Tail", { kind = "unused" })

return {
  generation = 1,
  size = 0x8000,
  layouts = { red = regions, blue = regions, yellow = regions, default = regions },
  regions = regions,
}
