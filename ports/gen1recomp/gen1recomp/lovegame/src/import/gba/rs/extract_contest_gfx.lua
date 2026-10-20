local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "rse/rs_contest_gfx"}
M.GFX = {
  interface = {"gContestMiscGfx", true}, audience = {"gContestAudienceGfx", true},
  applause_meter = {"gContestApplauseMeterGfx"}, next_turn_numbers = {"gContestNextTurnNumbersGfx"},
  next_turn_random = {"gContestNextTurnRandomGfx"}, slider_heart = {"gTiles_8D1975C"},
  next_turn = {"gContestNextTurnGfx", true}, applause = {"gContestApplauseGfx", true},
  judge = {"gContestJudgeGfx", true}, judge_symbols = {"gContestJudgeSymbolsGfx", true},
  results = {"gUnknown_08D1977C", true}, confetti = {"gContestConfetti_Gfx", true},
}
M.MAPS = {
  audience = {"gContestBgmap", true}, interface = {"gContestGfx", true},
  curtain = {"gUnknown_08D17C3C", true}, results_bg = {"gUnknown_08D1A490", true},
  results_interface = {"gUnknown_08D1A364", true}, results_banner = {"gUnknown_08D1A250", true},
  title_sheet = {"gUnknown_08E964B8"},
}
M.TEXTS = {
  gText_AppealNumWhichMoveWillBePlayed = "gText_Contest_WhichMoveWillBePlayed",
  gText_AppealNumButItCantParticipate = "gText_Contest_ButItCantParticipate",
  gText_MonWasTooNervousToMove = "ContestString_TooNervous",
  gText_MonCantAppealNextTurn = "ContestString_CantAppealNextTurn",
  gText_AppealComboWentOverWell = "ContestString_WentOverWell",
  gText_AppealComboWentOverVeryWell = "ContestString_WentOverVeryWell",
  gText_AppealComboWentOverExcellently = "ContestString_AppealComboExcellently",
  gText_JudgeLookedAtMonExpectantly = "ContestString_JudgeExpectantly2",
  gText_RepeatedAppeal = "ContestString_DissapointedRepeat",
  gText_MonsXDidntGoOverWell = "ContestString_DidntGoWell",
  gText_MonsXWentOverGreat = "ContestString_WentOverGreat",
  gText_MonsXGotTheCrowdGoing = "ContestString_GotCrowdGoing",
  gText_CrowdContinuesToWatchMon = "ContestString_CrowdWatches",
  gText_MonsMoveIsIgnored = "ContestString_Ignored2",
  gText_AnnouncingResults = "gContestText_AnnounceResults",
  gText_PreliminaryResults = "gContestText_PreliminaryResults",
  gText_Round2Results = "gContestText_Round2Results",
  gText_ContestantsMonWon = "gContestText_PokeWon",
  gText_LinkStandby = "gOtherText_LinkStandby",
  gText_LinkStandby4 = "gOtherText_LinkStandby",
  gText_CommunicationStandby = "gOtherText_LinkStandby",
}
M.FILES = {"results_text_window.gfx"}
for key in pairs(M.GFX) do M.FILES[#M.FILES + 1] = key .. ".gfx" end
for key in pairs(M.MAPS) do M.FILES[#M.FILES + 1] = key .. ".map" end
table.sort(M.FILES)
M.REQUIRED = K.required(M.SUB, M.FILES)
local function raw(c, spec) return spec[2] and c:lz(spec[1]) or c:raw(spec[1]) end
local function text(c, name)
  local off, out = c:off(name), {}
  for i = 0, 1023 do local v = c:u8(off + i); out[#out + 1] = v; if v == 255 then return out end end
  error("native contest text unterminated: " .. name)
end
local function window(c, name)
  local off, out = c:off(name), {}
  for i, key in ipairs({"bg", "charBase", "mapBase", "priority", "paletteNum", "fg", "background", "shadow",
    "font", "textMode", "spacing", "left", "top", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  out.tileData, out.tilemap = c:u32(off + 16), c:u32(off + 20)
  return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local gfx, maps, palettes, texts = {}, {}, {}, {}
  for key, spec in pairs(M.GFX) do
    local data = raw(c, spec); c:write(key .. ".gfx", data)
    gfx[key] = {path = c:path(key .. ".gfx"), bytes = #data}
  end
  for key, spec in pairs(M.MAPS) do
    local data = raw(c, spec); c:write(key .. ".map", data)
    maps[key] = {path = c:path(key .. ".map"), entries = #data / 2}
  end
  -- contest_link_util.c:130
  local frame = {}
  for _, symbol in ipairs({"gUnknown_083D1624", "gUnknown_083D1644", "gUnknown_083D1664", "gUnknown_083D1684",
    "gUnknown_083D16A4", "gUnknown_083D16C4", "gUnknown_083D16E4", "gUnknown_083D1704"}) do
    local bytes = c:raw(symbol); assert(#bytes == 32, "native result frame tile")
    frame[#frame + 1] = bytes
  end
  c:write("results_text_window.gfx", table.concat(frame))
  gfx.results_text_window = {path = c:path("results_text_window.gfx"), bytes = 256}
  for key, spec in pairs({interface_audience = {"gContestPalette", 256, true}, text = {"gFontDefaultPalette", 16},
    contest = {"gContestPal", 16}, judge = {"gContest2Pal", 16, true},
    judge_symbols = {"gContest3Pal", 16, true}, results = {"gUnknown_08D1A618", 256, true},
    results_text_window = {"gFontDefaultPalette", 16}, misc_blank = {"gMiscBlank_Pal", 16},
    confetti = {"gContestConfetti_Pal", 16, true}}) do
    palettes[key] = K.palList(c:pal(spec[1], spec[2], {}, 0, spec[3]), 0, spec[2])
  end
  for alias, symbol in pairs(M.TEXTS) do texts[alias] = text(c, symbol) end
  for _, symbol in ipairs({"gText_AllOutOfAppealTime", "gText_MonAppealedWithMove", "gText_MonWasWatchingOthers",
    "gText_OtherPokemonMadeMoves", "gText_Slash", "gText_Contest_Shyness", "gText_Contest_Anxiety",
    "gText_Contest_Laziness", "gText_Contest_Hesitancy", "gText_Contest_Fear"}) do texts[symbol] = text(c, symbol) end
  local slider, nextY, sine = {}, {}, {}
  local off = c:off("sSliderHeartYPositions")
  for i = 0, 3 do slider[i] = c:u8(off + i) end
  off = c:off("gUnknown_083CA33C")
  for i = 0, 3 do nextY[i] = c:u8(off + i) end
  off = c:off("gSineTable")
  for i = 0, c.S.count("gSineTable", 2) - 1 do sine[i] = c:s16(off + i * 2) end
  local windows = {}
  for i = 0, 3 do windows[i] = {left = 0, top = i * 5, width = 30, height = 2} end
  windows[4] = {left = 1, top = 15, width = 28, height = 4}
  for i = 0, 3 do windows[5 + i] = {left = 0, top = 31 + i * 2, width = 10, height = 2} end
  windows[9] = {left = 16, top = 31, width = 2, height = 2}
  windows[10] = {left = 11, top = 35, width = 18, height = 4}
  return A.finish(c, {screen = "contest_gfx", gfx = gfx, maps = maps, palettes = palettes, texts = texts,
    sliderHeartY = slider, nextTurnY = nextY, sine = sine, windows = windows,
    nativeWindows = {stage = window(c, "gWindowTemplate_81E6FD8"), general = window(c, "gWindowTemplate_81E6FF4"),
      results = window(c, "gWindowTemplate_81E6FA0")},
    affine = {sliderHeart = {[0] = A.affine(c, "gSpriteAffineAnim_83CA360"), A.affine(c, "gSpriteAffineAnim_83CA370"),
      A.affine(c, "gSpriteAffineAnim_83CA388")},
      boxBlink = {[0] = A.affine(c, "gSpriteAffineAnim_83CC4FC"), A.affine(c, "gSpriteAffineAnim_83CC50C")}},
    stageBgControl = {0x9800, 0x9E09, 0x9C00, 0x3A03}, resultsBgControl = {0x3E00, 0x1803, 0x1C03, 0x3A03}})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
