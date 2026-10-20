local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/contest_gfx"

M.GFX = {
  interface = { "gContestInterfaceGfx", true },
  audience = { "gContestAudienceGfx", true },
  applause_meter = { "gContestApplauseMeterGfx", false },
  next_turn_numbers = { "gContestNextTurnNumbersGfx", false },
  next_turn_random = { "gContestNextTurnRandomGfx", false },
  slider_heart = { "gContestSliderHeart_Gfx", false },
  next_turn = { "gContestNextTurnGfx", true },
  applause = { "gContestApplauseGfx", true },
  judge = { "gContestJudgeGfx", true },
  judge_symbols = { "gContestJudgeSymbolsGfx", true },
  results = { "gContestResults_Gfx", true },
  results_text_window = { "contest_util.o:sResultsTextWindow_Gfx", false },
  confetti = { "gConfetti_Gfx", true },
}

M.MAPS = {
  audience = { "gContestAudienceTilemap", true },
  interface = { "gContestInterfaceTilemap", true },
  curtain = { "gContestCurtainTilemap", true },
  results_bg = { "gContestResults_Bg_Tilemap", true },
  results_interface = { "gContestResults_Interface_Tilemap", true },
  results_banner = { "gContestResults_WinnerBanner_Tilemap", true },
  title_link = { "gContestResultsTitle_Link_Tilemap", false },
  title_normal = { "gContestResultsTitle_Normal_Tilemap", false },
  title_super = { "gContestResultsTitle_Super_Tilemap", false },
  title_hyper = { "gContestResultsTitle_Hyper_Tilemap", false },
  title_master = { "gContestResultsTitle_Master_Tilemap", false },
  title_cool = { "gContestResultsTitle_Cool_Tilemap", false },
  title_beauty = { "gContestResultsTitle_Beauty_Tilemap", false },
  title_cute = { "gContestResultsTitle_Cute_Tilemap", false },
  title_smart = { "gContestResultsTitle_Smart_Tilemap", false },
  title_tough = { "gContestResultsTitle_Tough_Tilemap", false },
  title = { "gContestResultsTitle_Tilemap", false },
}

M.PALETTES = {
  interface_audience = { "gContestInterfaceAudiencePalette", 256, true },
  text = { "contest.o:sText_Pal", 16, false },
  contest = { "gContestPal", 16, false },
  judge = { "gContest2Pal", 16, true },
  judge_symbols = { "gContestJudgeSymbolsPal", 16, true },
  results = { "gContestResults_Pal", 256, true },
  results_text_window = { "contest_util.o:sResultsTextWindow_Pal", 16, false },
  confetti = { "gConfetti_Pal", 16, true },
  misc_blank = { "contest_util.o:sMiscBlank_Pal", 16, false },
}

M.FILES = {}
for k in pairs(M.GFX) do M.FILES[#M.FILES + 1] = k .. ".gfx" end
for k in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = k .. ".map" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)

local function u8s(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do out[i] = c:u8(off + i) end
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
  for i = 0, c.S.size(name) / 4 - 1 do out[i] = affineAnim(c, c:ptr(off + i * 4)) end
  return out
end

-- pokeemerald/include/window.h:27
local function windowTemplates(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 8 - 1 do
    local b = off + i * 8
    if c:u8(b) == 0xFF then break end
    out[i] = { bg = c:u8(b), left = c:u8(b + 1), top = c:u8(b + 2), width = c:u8(b + 3), height = c:u8(b + 4),
      paletteNum = c:u8(b + 5), baseBlock = c:u16(b + 6) }
  end
  return out
end

-- pokeemerald/include/bg.h:42
local function bgTemplates(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 4 - 1 do
    local w = c:u32(off + i * 4)
    out[i] = { bg = w % 4, charBase = math.floor(w / 4) % 4, mapBase = math.floor(w / 16) % 32,
      screenSize = math.floor(w / 512) % 4, paletteMode = math.floor(w / 2048) % 2,
      priority = math.floor(w / 4096) % 4, baseTile = math.floor(w / 16384) % 1024 }
  end
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
  for key, spec in pairs(M.MAPS) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1])
    c:write(key .. ".map", data)
    maps[key] = { path = c:path(key .. ".map"), entries = #data / 2 }
  end
  local palettes = {}
  for key, spec in pairs(M.PALETTES) do
    palettes[key] = K.palList(c:pal(spec[1], spec[2], {}, 0, spec[3]), 0, spec[2])
  end

  return true, c:finish({
    screen = "contest",
    gfx = gfx,
    maps = maps,
    palettes = palettes,
    -- pokeemerald/src/contest.c:368
    sliderHeartY = u8s(c, "contest.o:sSliderHeartYPositions"),
    -- pokeemerald/src/contest.c:374
    nextTurnY = u8s(c, "contest.o:sNextTurnSpriteYPositions"),
    affine = {
      -- pokeemerald/src/contest.c:423
      sliderHeart = affineTable(c, "contest.o:sAffineAnims_SliderHeart"),
      -- pokeemerald/src/contest.c:911
      boxBlink = affineTable(c, "contest.o:sAffineAnims_ContestantsTurnBlinkEffect"),
    },
    -- pokeemerald/src/contest.c:691
    bgTemplates = bgTemplates(c, "contest.o:sContestBgTemplates"),
    windows = windowTemplates(c, "contest.o:sContestWindowTemplates"),
    -- pokeemerald/src/contest_util.c:282
    resultsBgTemplates = bgTemplates(c, "contest_util.o:sBgTemplates"),
    resultsWindows = windowTemplates(c, "contest_util.o:sWindowTemplates"),
    -- pokeemerald/src/trig.c:5
    sine = (function()
      local off, t = c:off("gSineTable"), {}
      for i = 0, c.S.size("gSineTable") / 2 - 1 do t[i] = c:s16(off + i * 2) end
      return t
    end)(),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
