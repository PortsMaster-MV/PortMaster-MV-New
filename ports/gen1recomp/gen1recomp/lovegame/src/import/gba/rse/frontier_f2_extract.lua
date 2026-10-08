local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/frontier_f2"

-- pokeemerald/src/graphics.c:1545
M.GFX = {
  tree = "gDomeTourneyTree_Gfx",
  treeMap = "gDomeTourneyTree_Tilemap",
  line = "gDomeTourneyLine_Gfx",
  lineDown = "gDomeTourneyLineDown_Tilemap",
  lineUp = "gDomeTourneyLineUp_Tilemap",
  card = "gDomeTourneyInfoCard_Gfx",
  cardMap = "gDomeTourneyInfoCard_Tilemap",
  cardBgMap = "gDomeTourneyInfoCardBg_Tilemap",
  buttons = "gDomeTourneyTreeButtons_Gfx",
  judgment = "gBattleArenaJudgmentSymbolsGfx",
  confetti = "gConfetti_Gfx",
}

M.FILES = {}
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
table.sort(M.FILES)
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

local function textAt(c, off, battle)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.decode(bytesAt(c, off), { dialect = "rse", battle = battle or nil })
end

local function inline(c, name, battle)
  return textAt(c, c:off(name), battle)
end

local function texts(c, name, count, battle)
  local off, out = c:off(name), {}
  count = count or c.S.size(name) / 4
  for i = 0, count - 1 do
    local p = c:ptr(off + i * 4)
    out[i + 1] = p and textAt(c, p, battle) or false
  end
  return out
end

local function u8s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end

local function s8s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:s8(off + i) end
  return out
end

local function u16s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 2 - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

local function rows(c, name, width)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / width - 1 do
    local r = {}
    for j = 0, width - 1 do r[j + 1] = c:u8(off + i * width + j) end
    out[i + 1] = r
  end
  return out
end

local function s8rows(c, name, width)
  local off, out = c:off(name), {}
  for i = 0, math.floor(c.S.size(name) / width) - 1 do
    local r = {}
    for j = 0, width - 1 do r[j + 1] = c:s8(off + i * width + j) end
    out[i + 1] = r
  end
  return out
end

-- pokeemerald/src/battle_main.c:313
local function typeTable(c)
  local off, out = c:off("gTypeEffectiveness"), {}
  local i = 0
  while true do
    local a = c:u8(off + i * 3)
    if a == 0xFF then break end
    out[#out + 1] = { a, c:u8(off + i * 3 + 1), c:u8(off + i * 3 + 2) }
    i = i + 1
  end
  return out
end

-- pokeemerald/include/window.h:18
local function windows(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 8 - 1 do
    local b = off + i * 8
    if c:u8(b) == 0xFF then break end
    out[i + 1] = { bg = c:u8(b), left = c:u8(b + 1), top = c:u8(b + 2), w = c:u8(b + 3), h = c:u8(b + 4),
      pal = c:u8(b + 5), baseBlock = c:u16(b + 6) }
  end
  return out
end

-- pokeemerald/include/bg.h:18
local function bgTemplates(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do
    local v = c:u32(off + i * 4)
    local function bits(lo, n) return math.floor(v / 2 ^ lo) % 2 ^ n end
    out[i + 1] = { bg = bits(0, 2), charBase = bits(2, 2), mapBase = bits(4, 5), screenSize = bits(9, 2),
      paletteMode = bits(11, 1), priority = bits(12, 2), baseTile = bits(14, 10) }
  end
  return out
end

-- pokeemerald/src/battle_message.c:32
local function textInfos(c, name, count)
  count = math.min(count, math.floor(c.S.size(name) / 12))
  local off, out = c:off(name), {}
  for i = 0, count - 1 do
    local b = off + i * 12
    out[i + 1] = { fill = c:u8(b), font = c:u8(b + 1), x = c:s8(b + 2), y = c:u8(b + 3), letterSpacing = c:u8(b + 4),
      lineSpacing = c:u8(b + 5), speed = c:u8(b + 6), fg = c:u8(b + 7), bg = c:u8(b + 8), shadow = c:u8(b + 9) }
  end
  return out
end

-- pokeemerald/src/battle_dome.c:1686
local function lineSections(c)
  local ptrs, counts = c:off("sTourneyTreeLineSections"), c:off("sTourneyTreeLineSectionArrayCounts")
  local out = {}
  for t = 0, 15 do
    local row = {}
    for r = 0, 3 do
      local p = c:ptr(ptrs + (t * 4 + r) * 4)
      local n = c:u8(counts + t * 4 + r)
      local list = {}
      for i = 0, n - 1 do
        local b = p + i * 4
        list[i + 1] = { x = c:u8(b), y = c:u8(b + 1), tile = c:u16(b + 2) }
      end
      row[r + 1] = list
    end
    out[t + 1] = row
  end
  return out
end

-- pokeemerald/src/battle_dome.c:581
local function cursorMap(c)
  local off, out = c:off("sTourneyTreeCursorMovementMap"), {}
  for pos = 0, 31 do
    local r = {}
    for round = 0, 4 do
      local d = {}
      for dir = 0, 3 do d[dir + 1] = c:u8(off + (pos * 5 + round) * 4 + dir) end
      r[round + 1] = d
    end
    out[pos + 1] = r
  end
  return out
end

local function pal(c, name, count)
  local bytes = c:lz(name)
  return K.palList(c:palFrom(bytes, count or #bytes / 2, {}, 0), 0, count or #bytes / 2)
end

local function template(c, name)
  local t = c:readTemplate(name)
  t.callback = nil
  t.images = nil
  return t
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local gfx = {}
  for key, name in pairs(M.GFX) do
    local data = c:lz(name)
    c:write(key .. ".gfx", data)
    gfx[key] = { path = c:path(key .. ".gfx"), bytes = #data }
  end
  local maps = {
    tree = gfx.treeMap, lineDown = gfx.lineDown, lineUp = gfx.lineUp, card = gfx.cardMap, cardBg = gfx.cardBgMap,
  }
  return true, c:finish({
    screen = "frontier_f2",
    gfx = gfx,
    maps = maps,
    palace = {
      earlyPrizes = u16s(c, "sBattlePalaceEarlyPrizes"),
      latePrizes = u16s(c, "sBattlePalaceLatePrizes"),
      moveGroupLikelihood = rows(c, "gBattlePalaceNatureToMoveGroupLikelihood", 4),
      moveTarget = u8s(c, "gBattlePalaceNatureToMoveTarget"),
      flavorTextId = u8s(c, "sBattlePalaceNatureToFlavorTextId"),
      flavorTextTable = u16s(c, "gBattlePalaceFlavorTextTable"),
      inobedientStringIds = u16s(c, "gInobedientStringIds"),
    },
    arena = {
      mindRatings = s8s(c, "sMindRatings"),
      shortPrizes = u16s(c, "sShortStreakPrizeItems"),
      longPrizes = u16s(c, "sLongStreakPrizeItems"),
      refereeStrings = texts(c, "gRefereeStringsTable", nil, true),
      text = {
        mind = inline(c, "gText_Mind", true), skill = inline(c, "gText_Skill", true), body = inline(c, "gText_Body", true),
        judgment = inline(c, "gText_Judgment", true), vs = inline(c, "gText_Vs", true),
        playerMon1Name = inline(c, "gText_PlayerMon1Name", true),
        opponentMon1Name = inline(c, "gText_OpponentMon1Name", true),
      },
      windows = windows(c, "sBattleArenaWindowTemplates"),
      textInfo = textInfos(c, "sTextOnWindowsInfo_Arena", #windows(c, "sBattleArenaWindowTemplates")),
      judgmentPal = pal(c, "gBattleArenaJudgmentSymbolsPalette", 16),
      judgmentOam = c:readOam(c:off("sOam_JudgmentIcon")),
    },
    dome = {
      natureStatTable = s8rows(c, "gNatureStatTable", 5),
      typeEffectiveness = typeTable(c),
      styleMovePoints = rows(c, "sBattleStyleMovePoints", 16),
      styleThresholds = rows(c, "sBattleStyleThresholds", 16),
      cursorMap = cursorMap(c),
      treeTrainerIds = u8s(c, "sTourneyTreeTrainerIds"),
      treeTrainerIds2 = u8s(c, "sTourneyTreeTrainerIds2"),
      idToOpponentId = rows(c, "sIdToOpponentId", 4),
      trainerOpponentIds = u8s(c, "sTourneyTreeTrainerOpponentIds"),
      idToMatchNumber = rows(c, "sIdToMatchNumber", 4),
      lastMatchCardNum = u8s(c, "sLastMatchCardNum"),
      trainerAndRoundToLastMatchCardNum = rows(c, "sTrainerAndRoundToLastMatchCardNum", 4),
      pairedTrainerIds = u8s(c, "sTournamentIdToPairedTrainerIds"),
      competitorRange = rows(c, "sCompetitorRangeByMatch", 3),
      namePositions = rows(c, "sTrainerNamePositions", 2),
      pokeballCoords = rows(c, "sTourneyTreePokeballCoords", 2),
      infoTrainerMonX = u8s(c, "sInfoTrainerMonX"),
      infoTrainerMonY = u8s(c, "sInfoTrainerMonY"),
      speciesNameY = u8s(c, "sSpeciesNameTextYCoords"),
      statTextOffsets = u8s(c, "sStatTextOffsets"),
      leftMonX = u8s(c, "sLeftTrainerMonX"),
      leftMonY = u8s(c, "sLeftTrainerMonY"),
      rightMonX = u8s(c, "sRightTrainerMonX"),
      rightMonY = u8s(c, "sRightTrainerMonY"),
      lineSections = lineSections(c),
      text = {
        potential = texts(c, "sBattleDomePotentialTexts"),
        styles = texts(c, "sBattleDomeOpponentStyleTexts"),
        stats = texts(c, "sBattleDomeOpponentStatsTexts"),
        matchNumbers = texts(c, "sBattleDomeMatchNumberTexts"),
        wins = texts(c, "sBattleDomeWinTexts"),
        rounds = texts(c, "gRoundsStringTable"),
        battleTourney = inline(c, "gText_BattleTourney"),
      },
      treeWindows = windows(c, "sTourneyTreeWindowTemplates"),
      cardWindows = windows(c, "sInfoCardWindowTemplates"),
      treeBgs = bgTemplates(c, "sTourneyTreeBgTemplates"),
      cardBgs = bgTemplates(c, "sInfoCardBgTemplates"),
      sprites = {
        pokeball = template(c, "sTourneyTreePokeballSpriteTemplate"),
        cancel = template(c, "sCancelButtonSpriteTemplate"),
        exit = template(c, "sExitButtonSpriteTemplate"),
        vArrow = template(c, "sVerticalScrollArrowSpriteTemplate"),
        hArrow = template(c, "sHorizontalScrollArrowSpriteTemplate"),
      },
      palettes = {
        tree = pal(c, "gDomeTourneyTree_Pal"),
        buttons = pal(c, "gDomeTourneyTreeButtons_Pal"),
        matchCardBg = pal(c, "gDomeTourneyMatchCardBg_Pal", 16),
        windowText = pal(c, "gBattleWindowTextPalette", 16),
      },
    },
    confetti = {
      pal = pal(c, "gConfetti_Pal", 16),
      anims = c:readAnimTable(c:off("sAnims_Confetti"), c.S.size("sAnims_Confetti") / 4),
      oam = c:readOam(c:off("hall_of_fame.o:sOamData_Confetti")),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
