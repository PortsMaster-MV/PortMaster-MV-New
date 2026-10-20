local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")

local Records = {}

Records.STACK_ID = "frontier_records"
Records.BP_ID = "frontier_bp"

Records._window = nil
Records._bp = nil

local function D() return require("src.core.game3.rse.frontier.trainers") end
local function U() return require("src.core.game3.rse.frontier.util") end

local function plainIr(ir, vars)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.toPlain(ir, { stringVars = vars or {} })
end

local function text(key, vars)
  local rt = package.loaded["src.core.game3.runtime"]
  local sess = rt and rt.getSession and rt.getSession()
  return RomText.plain(key, { stringVars = vars or {}, playerName = sess and sess.name })
end

local function width(s)
  local best, w = 0, 0
  for line in (tostring(s) .. "\n"):gmatch("([^\n]*)\n") do
    w = FrlgFont.measure(line)
    if w > best then best = w end
  end
  return best
end

-- pokeemerald/src/string_util.c:163
local function num4(n)
  return string.format("%4d", math.max(0, math.min(9999, math.floor(tonumber(n) or 0))))
end

local function streak(n)
  n = tonumber(n) or 0
  if n > D().MAX_STREAK then n = D().MAX_STREAK end
  return n
end

Records._layers = {}

local function drawField()
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.isActive and Fade.isActive() and (tonumber(Fade.t) or 0) >= 16 then return end
  if Records._layers[Records.BP_ID] then Records.drawWindow(Records._layers[Records.BP_ID]) end
  if Records._layers[Records.STACK_ID] then Records.drawWindow(Records._layers[Records.STACK_ID]) end
end
Records.drawField = drawField

local function install()
  local UiPass = require("src.ui.game3.ui_pass")
  if UiPass._frontierRecords then return end
  local orig = UiPass.drawUi
  UiPass.drawUi = function(...)
    local r = { orig(...) }
    local ok, err = pcall(drawField)
    if not ok then print("[game3/frontier_records] draw failed: " .. tostring(err)) end
    return (table.unpack or unpack)(r)
  end
  UiPass._frontierRecords = true
end

local function push(id, win)
  install()
  Records._layers[id] = win
end

local function pop(id)
  Records._layers[id] = nil
end

function Records.showWindow(win)
  Records._window = win
  push(Records.STACK_ID, win)
  return win
end

function Records.drawWindow(win)
  if not win then return end
  Window.stdFrame(Window.template(win.left, win.top, win.width, win.height))
  local ox, oy = win.left * 8, win.top * 8
  for _, p in ipairs(win.prints) do
    FrlgFont.draw(p.s, ox + p.x, oy + p.y, { colors = FrlgFont.COLOR.NORMAL })
  end
end

local function newWindow(tpl)
  return { left = tpl[1], top = tpl[2], width = tpl[3], height = tpl[4], prints = {} }
end

local function put(win, s, x, y)
  win.prints[#win.prints + 1] = { s = tostring(s or ""), x = x, y = y }
end

-- pokeemerald/src/frontier_util.c:634
local RESULTS_TPL = { 1, 1, 28, 18 }
-- pokeemerald/src/frontier_util.c:645
local LINK_CONTEST_TPL = { 2, 2, 26, 15 }
-- pokeemerald/src/frontier_util.c:656
local HALL_TPL = { 2, 1, 26, 17 }

-- pokeemerald/src/frontier_util.c:960
local function printAligned(win, s, y)
  local x = math.floor((240 - 16 - width(s)) / 2)
  put(win, s, x, y * 8 + 1)
end

-- pokeemerald/src/frontier_util.c:967
local function printHyphens(win, y)
  put(win, string.rep("-", 36), 4, y * 8 + 1)
end

local function isActive(sess, flag)
  return U().isWinStreakActive(sess, flag)
end

local function prevOrCurrent(sess, flag)
  return RomText.plain(isActive(sess, flag) and "gText_Current" or "gText_Prev")
end

local function numText(key, n)
  return text(key, { num4(n) })
end

local SK = nil
local function streakFlags()
  if SK then return SK end
  local S = U().STREAK
  SK = {
    tower = { { S.TOWER_SINGLES_50, S.TOWER_SINGLES_OPEN }, { S.TOWER_DOUBLES_50, S.TOWER_DOUBLES_OPEN },
      { S.TOWER_MULTIS_50, S.TOWER_MULTIS_OPEN }, { S.TOWER_LINK_MULTIS_50, S.TOWER_LINK_MULTIS_OPEN } },
    dome = { { S.DOME_SINGLES_50, S.DOME_SINGLES_OPEN }, { S.DOME_DOUBLES_50, S.DOME_DOUBLES_OPEN } },
    palace = { { S.PALACE_SINGLES_50, S.PALACE_SINGLES_OPEN }, { S.PALACE_DOUBLES_50, S.PALACE_DOUBLES_OPEN } },
    factory = { { S.FACTORY_SINGLES_50, S.FACTORY_SINGLES_OPEN }, { S.FACTORY_DOUBLES_50, S.FACTORY_DOUBLES_OPEN } },
    arena = { S.ARENA_50, S.ARENA_OPEN },
    pike = { S.PIKE_50, S.PIKE_OPEN },
    pyramid = { S.PYRAMID_50, S.PYRAMID_OPEN },
  }
  return SK
end

-- pokeemerald/src/frontier_util.c:1045
local function towerWindow(sess, mode)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  local titles = { "gText_SingleBattleRoomResults", "gText_DoubleBattleRoomResults",
    "gText_MultiBattleRoomResults", "gText_LinkMultiBattleRoomResults" }
  printAligned(win, text(titles[mode + 1]), 2)
  put(win, text("gText_Lv502"), 16, 49)
  put(win, text("gText_OpenLv"), 16, 97)
  printHyphens(win, 10)
  local flags = streakFlags().tower[mode + 1]
  for lvl = 0, 1 do
    local y = lvl == 0 and 49 or 97
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 72, y)
    put(win, numText("gText_WinStreak", streak(U().get2(f.towerWinStreaks, mode, lvl))), 132, y)
    put(win, text("gText_Record"), 72, y + 16)
    put(win, numText("gText_WinStreak", streak(U().get2(f.towerRecordWinStreaks, mode, lvl))), 132, y + 16)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1116
local function domeWindow(sess, mode)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  printAligned(win, text(mode == 0 and "gText_SingleBattleTourneyResults" or "gText_DoubleBattleTourneyResults"), 0)
  put(win, text("gText_Lv502"), 8, 33)
  put(win, text("gText_OpenLv"), 8, 97)
  printHyphens(win, 10)
  local flags = streakFlags().dome[mode + 1]
  for lvl = 0, 1 do
    local y = lvl == 0 and 33 or 97
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 64, y)
    put(win, numText("gText_ClearStreak", streak(U().get2(f.domeWinStreaks, mode, lvl))), 121, y)
    put(win, text("gText_Record"), 64, y + 16)
    put(win, numText("gText_ClearStreak", U().get2(f.domeRecordWinStreaks, mode, lvl)), 121, y + 16)
    put(win, text("gText_Total"), 64, y + 32)
    put(win, numText("gText_Championships", U().get2(f.domeTotalChampionships, mode, lvl)), 112, y + 32)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1192
local function palaceWindow(sess, mode)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  printAligned(win, text(mode == 0 and "gText_SingleBattleHallResults" or "gText_DoubleBattleHallResults"), 2)
  put(win, text("gText_Lv502"), 16, 49)
  put(win, text("gText_OpenLv"), 16, 97)
  printHyphens(win, 10)
  local flags = streakFlags().palace[mode + 1]
  for lvl = 0, 1 do
    local y = lvl == 0 and 49 or 97
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 72, y)
    put(win, numText("gText_WinStreak", streak(U().get2(f.palaceWinStreaks, mode, lvl))), 131, y)
    put(win, text("gText_Record"), 72, y + 16)
    put(win, numText("gText_WinStreak", streak(U().get2(f.palaceRecordWinStreaks, mode, lvl))), 131, y + 16)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1248
local function pikeWindow(sess)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  printAligned(win, text("gText_BattleChoiceResults"), 0)
  put(win, text("gText_Lv502"), 8, 33)
  put(win, text("gText_OpenLv"), 8, 97)
  printHyphens(win, 10)
  local flags = streakFlags().pike
  for lvl = 0, 1 do
    local y = lvl == 0 and 33 or 97
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 64, y)
    put(win, numText("gText_RoomsCleared", streak(U().get1(f.pikeWinStreaks, lvl))), 114, y)
    put(win, text("gText_Record"), 64, y + 16)
    put(win, numText("gText_RoomsCleared", U().get1(f.pikeRecordStreaks, lvl)), 114, y + 16)
    put(win, text("gText_Total"), 64, y + 32)
    put(win, numText("gText_TimesCleared", U().get1(f.pikeTotalStreaks, lvl)), 114, y + 32)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1310
local function arenaWindow(sess)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  printHyphens(win, 10)
  printAligned(win, text("gText_SetKOTourneyResults"), 2)
  put(win, text("gText_Lv502"), 16, 49)
  put(win, text("gText_OpenLv"), 16, 97)
  local flags = streakFlags().arena
  for lvl = 0, 1 do
    local y = lvl == 0 and 49 or 97
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 72, y)
    put(win, numText("gText_KOsInARow", streak(U().get1(f.arenaWinStreaks, lvl))), 126, y)
    put(win, text("gText_Record"), 72, y + 16)
    put(win, numText("gText_KOsInARow", streak(U().get1(f.arenaRecordStreaks, lvl))), 126, y + 16)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1396
local function factoryWindow(sess, mode)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  printAligned(win, text(mode == 0 and "gText_BattleSwapSingleResults" or "gText_BattleSwapDoubleResults"), 0)
  put(win, text("gText_Lv502"), 8, 33)
  put(win, text("gText_RentalSwap"), 152, 33)
  put(win, text("gText_OpenLv"), 8, 97)
  printHyphens(win, 10)
  local flags = streakFlags().factory[mode + 1]
  for lvl = 0, 1 do
    local y = lvl == 0 and 49 or 113
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 8, y)
    put(win, numText("gText_WinStreak", streak(U().get2(f.factoryWinStreaks, mode, lvl))), 64, y)
    put(win, numText("gText_TimesVar1", streak(U().get2(f.factoryRentsCount, mode, lvl))), 158, y)
    put(win, text("gText_Record"), 8, y + 16)
    put(win, numText("gText_WinStreak", streak(U().get2(f.factoryRecordWinStreaks, mode, lvl))), 64, y + 16)
    put(win, numText("gText_TimesVar1", U().get2(f.factoryRecordRentsCount, mode, lvl)), 158, y + 16)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1461
local function pyramidWindow(sess)
  local f = U().frontier(sess)
  local win = newWindow(RESULTS_TPL)
  printAligned(win, text("gText_BattleQuestResults"), 2)
  put(win, text("gText_Lv502"), 8, 49)
  put(win, text("gText_OpenLv"), 8, 97)
  printHyphens(win, 10)
  local flags = streakFlags().pyramid
  for lvl = 0, 1 do
    local y = lvl == 0 and 49 or 97
    put(win, prevOrCurrent(sess, flags[lvl + 1]), 64, y)
    put(win, numText("gText_FloorsCleared", streak(U().get1(f.pyramidWinStreaks, lvl))), 111, y)
    put(win, text("gText_Record"), 64, y + 16)
    put(win, numText("gText_FloorsCleared", streak(U().get1(f.pyramidRecordStreaks, lvl))), 111, y + 16)
  end
  return win
end

-- pokeemerald/src/frontier_util.c:1480
local function linkContestWindow(sess)
  local win = newWindow(LINK_CONTEST_TPL)
  local title = text("gText_LinkContestResults")
  put(win, title, math.floor((208 - width(title)) / 2), 1)
  local places = { "gText_1st", "gText_2nd", "gText_3rd", "gText_4th" }
  for i, k in ipairs(places) do
    local s = text(k)
    put(win, s, (38 - width(s)) + 50 + (i - 1) * 38, 25)
  end
  local cats = { "gText_Cool", "gText_Beauty", "gText_Cute", "gText_Smart", "gText_Tough" }
  for i, k in ipairs(cats) do put(win, text(k), 6, 41 + (i - 1) * 16) end
  local results = sess.contestLinkResults or {}
  for i = 1, 5 do
    for j = 1, 4 do
      local row = results[i]
      put(win, num4(row and row[j] or 0), (j - 1) * 38 + 64, (i - 1) * 16 + 41)
    end
  end
  return win
end

-- pokeemerald/src/frontier_util.c:919
function Records.buildResults(sess, facility, mode)
  local F = D().FACILITY
  if mode >= D().MODE_COUNT then mode = 0 end
  if facility == F.TOWER then return towerWindow(sess, mode) end
  if facility == F.DOME then return domeWindow(sess, mode) end
  if facility == F.PALACE then return palaceWindow(sess, mode) end
  if facility == F.PIKE then return pikeWindow(sess) end
  if facility == F.FACTORY then return factoryWindow(sess, mode) end
  if facility == F.ARENA then return arenaWindow(sess) end
  if facility == F.PYRAMID then return pyramidWindow(sess) end
  if facility == U().FACILITY_LINK_CONTEST then return linkContestWindow(sess) end
  return nil
end

function Records.showResults(sess, facility, mode)
  local win = Records.buildResults(sess, facility, mode)
  if not win then return false end
  Records._window = win
  push(Records.STACK_ID, win)
  return true
end

-- pokeemerald/src/frontier_util.c:2338
function Records.buildRankingHall(sess, hallId, lvlMode)
  local win = newWindow(HALL_TPL)
  local man = D().manifest()
  local pair = man.recordsChallengeTexts[hallId + 1]
  local facilityName = plainIr(RomText.refIr(pair[1]))
  put(win, plainIr(RomText.refIr(pair[2]), { facilityName }), 0, 1)
  local lvl = plainIr(RomText.refIr(man.levelModeText[lvlMode + 1]))
  put(win, lvl, (240 - 32) - width(lvl), 1)
  local rows = U().rankingHall(sess, hallId, lvlMode)
  local recordText = RomText.refIr(man.hallFacilityToRecordsText[hallId + 1])
  local link = hallId == U().RANKING_HALL.TOWER_LINK
  for i, r in ipairs(rows) do
    local pos = i - 1
    local y = 8 * (4 + 5 * pos) + 1
    put(win, plainIr(man.rankDots[i]), 8, y)
    local ws = tonumber(r.winStreak) or 0
    if ws ~= 0 then
      if link then
        put(win, r.name1 or "", 3 * 8, 8 * (4 + 5 * pos - 1) + 1)
        put(win, r.name2 or "", 5 * 8, 8 * (4 + 5 * pos + 1) + 1)
      else
        put(win, r.name or "", 3 * 8, y)
      end
      local s = plainIr(recordText, { "", num4(streak(ws)) })
      put(win, s, 200 - width(plainIr(recordText, { "", "" })), y)
    end
  end
  return win
end

function Records.showRankingHall(sess, hallId, lvlMode)
  local win = Records.buildRankingHall(sess, hallId, lvlMode or 0)
  Records._window = win
  push(Records.STACK_ID, win)
  return true
end

-- pokeemerald/src/battle_records.c:340
-- pokeemerald/src/battle_records.c:76
local LINK_BATTLE_TPL = { 2, 1, 26, 17 }

-- pokeemerald/src/battle_records.c:315
function Records.buildLinkBattle(sess)
  local win = newWindow(LINK_BATTLE_TPL)
  local title = text("gText_PlayersBattleResults")
  put(win, title, math.floor((208 - width(title)) / 2), 1)
  -- pokeemerald/src/battle_records.c:272
  local gs = type(sess) == "table" and type(sess.gameStats) == "table" and sess.gameStats or {}
  local function stat(id) return string.format("%d", math.max(0, math.min(9999, math.floor(tonumber(gs[id]) or 0)))) end
  local total = text("gText_TotalRecordWLD", { stat(23), stat(24), stat(25) })
  put(win, total, math.floor((0xD0 - width(total)) / 2), 0x11)
  -- pokeemerald/src/battle_records.c:328
  local x = 0
  for _, seg in ipairs(RomText.ir("gText_WinLoseDraw")) do
    if seg.t == "text" then
      put(win, require("src.core.Strings")(seg.s), x, 41)
    elseif seg.t == "ext" and seg.cmd == 0x13 then
      x = seg.args[1]
    end
  end
  local stored = type(sess) == "table" and type(sess.linkBattleRecords) == "table" and sess.linkBattleRecords or {}
  for i = 1, 5 do
    local e = type(stored[i]) == "table" and stored[i] or {}
    local w, l, d = tonumber(e.wins) or 0, tonumber(e.losses) or 0, tonumber(e.draws) or 0
    local y = (7 + (i - 1) * 2) * 8 + 1
    -- pokeemerald/src/battle_records.c:286
    if w == 0 and l == 0 and d == 0 then
      local dashes = text("sText_DashesNoScore")
      put(win, text("sText_DashesNoPlayer"), 8, y)
      put(win, dashes, 80, y)
      put(win, dashes, 128, y)
      put(win, dashes, 176, y)
    else
      put(win, tostring(e.name or ""), 8, y)
      put(win, num4(w), 80, y)
      put(win, num4(l), 128, y)
      put(win, num4(d), 176, y)
    end
  end
  return win
end

function Records.showLinkBattle(sess)
  return Records.showWindow(Records.buildLinkBattle(sess))
end

function Records.remove()
  Records._window = nil
  pop(Records.STACK_ID)
end

function Records.eraseBox(left, top, right, bottom)
  local win = Records._window
  if win and left <= win.left - 1 and top <= win.top - 1
      and right >= win.left + win.width and bottom >= win.top + win.height then
    Records.remove()
  end
end

function Records.isOpen()
  return Records._window ~= nil
end

-- pokeemerald/src/field_specials.c:2911
local BP_TPL = { 1, 1, 6, 2 }

-- pokeemerald/src/field_specials.c:2902
function Records.buildBp(sess)
  local win = newWindow(BP_TPL)
  local f = U().frontier(sess)
  local s = num4(f.battlePoints) .. text("gText_BP")
  put(win, s, 48 - width(s), 1)
  return win
end

function Records.showBp(sess)
  Records._bp = Records.buildBp(sess)
  push(Records.BP_ID, Records._bp)
end

function Records.updateBp(sess)
  if not Records._bp then return end
  local fresh = Records.buildBp(sess)
  Records._bp.prints = fresh.prints
end

-- pokeemerald/src/field_specials.c:2930
function Records.hideBp()
  Records._bp = nil
  pop(Records.BP_ID)
end

function Records.reset()
  Records.remove()
  Records.hideBp()
end

return Records
