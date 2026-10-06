local L = require("Legality")
local PAL = require("Theme").PAL
local M = {}
local Touch = require("TouchEditor")
local Motion = require("Motion")
function M.draw(S, Kit, x, y, w, h)
  Kit.card(x, y, w, h)
  local pad, gap, row = 14 * Kit.scale, 10 * Kit.scale, Kit.controlH()
  local cx, inner = x + pad, w - 2 * pad
  if S._checksRevision ~= S.revision or S._checksSave ~= S.save then
    S.checkReport = L.save(S)
    S._checksRevision, S._checksSave = S.revision, S.save
  end
  local r = S.checkReport
  local message = ("%d Pokémon · %d errors. Origin checks still need review."):format(
    #r.entries,
    r.errors
  )
  local head = Kit.textWrapped(
    "small",
    message,
    cx,
    y + pad,
    inner,
    r.errors > 0 and PAL.red or PAL.yellow
  ) + gap
  local actionH = Touch.action(
    S,
    Kit,
    "Fix all errors",
    "Fixes invalid values, stats and PP across your party and boxes. Anything needing a manual choice stays for review.",
    function()
      require("Ops").fixAllErrors(S)
    end,
    cx,
    y + pad + head,
    inner,
    "good"
  )
  head = head + actionH + gap
  local top = y + pad + head
  local bodyH = math.max(0, h - 2 * pad - head)
  S.checkScroll =
    Kit.scrollPixels(cx, top, inner, bodyH, S.checkScroll or 0, #r.entries * (row + gap))
  Kit.pushClip(cx, top, inner, bodyH)
  for i, e in ipairs(r.entries) do
    local mon = e.mon
    local label = e.label
      .. " / "
      .. require("Ops").monName(S, mon)
      .. " / "
      .. e.report.errors
      .. " errors"
    if
      Kit.button(
        cx,
        top + (i - 1) * (row + gap) - S.checkScroll,
        inner,
        row,
        label,
        { kind = e.report.errors > 0 and "danger" or "warn", font = "small" }
      )
    then
      Motion.change(S, "tab", "party", -1)
      S.editingMon, S.monSection, S.mobileInspector = mon, "checks", true
      S.inspectorScroll = 0
      Kit.blur()
    end
  end
  Kit.popClip()
end
return M
