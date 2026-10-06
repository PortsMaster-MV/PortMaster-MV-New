local Text = require("src.core.game3.rom_text")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Kit = require("src.ui.game3.rse.scene_kit")
local M = {visible = false}
function M.reset() M.visible, M.session, M.owner = false, nil, nil end
function M.show(session)
  M.session, M.visible = session, true
  local Space = package.loaded["src.core.game3.scripting.space"]
  M.owner = Space and Space.vm
end
function M.eraseBox(l, t, r, b)
  if l <= 1 and t <= 0 and r >= 28 and b >= 18 then M.reset() end
end
function M.draw()
  if not M.visible then return end
  local Space = package.loaded["src.core.game3.scripting.space"]
  if M.owner ~= (Space and Space.vm) then M.reset(); return end
  local man = assert(Kit.manifest("rse/battle_tower_records"), "native RS window palette missing")
  local w = man.window
  local function color(i) return Kit.color555(man.palette[i + 1]) end
  local opts = {font = "native_" .. w.fontNum, letterSpacing = w.spacing,
    colors = {fg = color(w.foregroundColor), bg = color(w.backgroundColor), shadow = color(w.shadowColor)}}
  local function draw(value, x, y) Font.draw(value, x * 8, y * 8, opts) end
  local function num(v) return string.format("%4d", math.min(9999, math.max(0, tonumber(v) or 0))) end
  Chrome.stdFrame(2, 1, 26, 17)
  local title = Text.plain("gOtherText_BattleResults")
  Font.draw(title, math.floor((240 - Font.measure(title, opts)) / 2), 8, opts)
  local stats = M.session.gameStats or {}
  draw(Text.plain("gOtherText_WinRecord", {stringVars = {num(stats[23]), num(stats[24]), num(stats[25])}}), 3, 3)
  draw(Text.plain("gOtherText_WinLoseDraw"), 12, 6)
  local slots = {}
  for i, row in pairs(M.session.linkBattleRecords or {}) do slots[(tonumber(row.nativeSlot) or i - 1) + 1] = row end
  for i = 1, 5 do
    local row, y = slots[i] or {}, 6 + i * 2
    local empty = (tonumber(row.wins) or 0) + (tonumber(row.losses) or 0) + (tonumber(row.draws) or 0) == 0
    draw(empty and Text.plain("gOtherText_SevenDashes") or row.name or "", 3, y)
    for j, key in ipairs({"wins", "losses", "draws"}) do draw(empty and Text.plain("gOtherText_FourDashes") or num(row[key]), 5 + j * 6, y) end
  end
end
return M
