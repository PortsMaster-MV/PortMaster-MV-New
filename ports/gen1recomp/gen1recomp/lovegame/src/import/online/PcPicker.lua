local Kit = require("src.ui.kit.Kit")
local Theme = require("src.ui.kit.Theme")
local Strings = require("src.core.Strings")
local Ui = require("src.import.online.Ui")

local PAL = Theme.PAL

local PcPicker = {}

local function LV() return require("src.import.LauncherView") end
local function OP() return require("src.import.OnlinePanel") end
local function Sprites() return require("src.online.OnlineSprites") end

function PcPicker.draw(imp, m)
  local OnlinePanel = OP()
  local pc = OnlinePanel.pcPicker(imp)
  if not pc then return false end
  local pad = math.floor(18 * m.s)
  local gap = math.floor(8 * m.s)
  local tiny = math.floor(4 * m.s)
  local w = math.floor(520 * m.s)
  local btnH = math.max(m.btnH, Kit.tapMin())
  local rowH = math.max(m.rowH, Kit.tapMin())
  local rows = OnlinePanel.pcRows(imp)
  local perPage = 6
  local h = math.floor(math.min(m.H - 2 * m.pad,
    pad + Kit.textHeight("button") + gap + Kit.textHeight("small") + tiny
      + btnH + gap + perPage * (rowH + tiny) + gap + btnH + pad))
  local px, py, pw, ph = LV().modalPanel(m, w, h)
  local innerW = pw - 2 * pad
  local cy = py + pad

  Kit.textBold("button", Strings("From the PC"), px + pad, cy, PAL.heading)
  cy = cy + Kit.textHeight("button") + gap

  cy = cy + Ui.label(Strings("Search"), px + pad, cy) + tiny
  Ui.field(imp, px + pad, cy, innerW, btnH, OnlinePanel.PC_FIELD, pc.query,
    Strings("Name, species or box"),
    imp._onlineFocus == OnlinePanel.PC_FIELD,
    function(text) OnlinePanel.pcQuery(imp, text) end)
  cy = cy + btnH + gap

  local listBottom = py + ph - pad - btnH - gap
  local fits = math.max(1, math.floor((listBottom - cy) / (rowH + tiny)))
  if #rows == 0 then
    Kit.emptyBox(px + pad, cy, innerW, rowH * 2,
      Strings("Nothing in the PC matches that."))
  else
    imp._pages = imp._pages or {}
    local pageKey = "online-pc"
    local first, last, pageNow = Kit.pageBounds(imp._pages[pageKey] or 1,
      #rows, fits)
    imp._pages[pageKey] = pageNow
    local sprites = Sprites()
    local iconSize = math.max(16, math.floor(rowH * 0.62))
    for i = first, last do
      local row = rows[i]
      local ref = row.ref
      local ink = LV().rowHit(imp, px + pad, cy, innerW, rowH,
        row.order ~= nil, "online-pc-" .. row.key, function()
          OnlinePanel.pcPick(imp, row)
        end)
      local tx = px + pad + math.floor(10 * m.s)
      local sprite = sprites.get(row.version, row.mon)
      if sprite and sprites.drawIcon(sprite, tx, cy + (rowH - iconSize) / 2,
          iconSize) then
        tx = tx + iconSize + math.floor(6 * m.s)
      end
      if row.order then
        Kit.textBold("small", ("%d."):format(row.order), tx,
          cy + (rowH - Kit.textHeight("small")) / 2, ink or PAL.heading)
        tx = tx + math.floor(20 * m.s)
      end
      local textW = innerW - (tx - px - pad) - math.floor(10 * m.s)
      Kit.text("small", Kit.ellipsize("small", row.label, textW), tx,
        cy + math.floor(5 * m.s), ink or PAL.text)
      Kit.text("micro", Kit.ellipsize("micro",
        tostring(row.source or ""), textW), tx,
        cy + rowH - Kit.textHeight("micro") - math.floor(5 * m.s), PAL.muted)
      cy = cy + rowH + tiny
      if ref == nil then break end
    end
  end

  local by = math.floor(py + ph - pad - btnH)
  LV().btn(imp, px + pad, by, innerW, btnH, OnlinePanel.PC_CLOSE,
    Strings("Done"), { kind = "primary", font = "small",
      action = function() OnlinePanel.pcClose(imp) end })
  return true
end

return PcPicker
