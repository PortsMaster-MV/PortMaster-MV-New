-- Type-to-search item picker: the items panel's answer to the species
-- picker (panels/SpeciesPicker.lua), and built to the same shape on purpose.
--
-- Adding an item used to mean an inline catalog card wedged into the Items
-- tab: a search field and a scrolling list competing for height with the bag
-- and PC lists beside it, which on a phone left about three rows visible.
-- Adding a Pokemon was already a full-screen modal with the whole window to
-- work with, and there was no reason for the two to differ.
--
-- Modal is literal.  Kit hit-tests without a z-order, so App.draw raises
-- Kit.blockClicks over the chrome and the panel while this is open and lowers
-- it only for this overlay; nothing underneath can take the same tap.

local Theme = require("Theme")
local Ops = require("Ops")
local PickerChrome = require("PickerChrome")
local PAL = Theme.PAL

local Picker = {}

local FIELD_ID = "item-picker"
local FEEDBACK_SECONDS = 2.5

local function feedback(S, Kit, changed, dest)
  local p = S.itemPicker
  if p then
    p.feedback = {
      text = changed and (dest == "pc" and "Added to PC" or "Added to Bag") or "Item not added",
      good = changed,
      at = love.timer and love.timer.getTime and love.timer.getTime() or Kit.time,
    }
  end
  return changed
end

local function drawFeedback(p, Kit, x, y, w, h)
  local toast = p.feedback
  if not toast then return false end
  local elapsed = math.max(0, Kit.time - toast.at)
  if elapsed >= FEEDBACK_SECONDS then
    p.feedback = nil
    return false
  end
  local alpha = math.min(1, (FEEDBACK_SECONDS - elapsed) / 0.4)
  local s, pad = Kit.scale, 8 * Kit.scale
  local icon = 18 * s
  local tw = math.min(w, Kit.textWidth("small", toast.text) + icon + 3 * pad)
  local color = toast.good and PAL.green or PAL.red
  Theme.fillRounded(x, y, tw, h, PAL.cardBody, 0.98 * alpha)
  Theme.stroke(x, y, tw, h, Theme.radius(), color, 0.8 * alpha, 1)
  Kit.icon(toast.good and "check" or "triangle-alert", x + pad, y + (h - icon) / 2, icon, color, alpha)
  Kit.text("small", toast.text, x + icon + 2 * pad, y + (h - Kit.textHeight("small")) / 2, PAL.text, alpha)
  return true
end

function Picker.results(S)
  local p = S.itemPicker
  local hits = Ops.itemSearch(S, p and p.query or "")
  if p and p.dest == "held" then
    local filtered = {}
    for _, id in ipairs(hits) do
      if Ops.itemHoldable(S, id) then
        filtered[#filtered + 1] = id
      end
    end
    return filtered
  end
  return hits
end

-- Enter commits the top match into whichever destination the picker was
-- opened for, which is the whole point of a search field.
function Picker.commitFirst(S, Kit)
  local hits = Picker.results(S)
  if not hits[1] then
    return Ops.say(S, "No item matches that")
  end
  return Picker.commit(S, Kit, hits[1])
end

-- One funnel for both destinations.  The picker stays OPEN after a commit:
-- stocking a save means adding several items in a row, and reopening the
-- modal per item is the kind of friction the inline card at least did not
-- have.  Escape / Close / tap-outside is the way out.
function Picker.commit(S, Kit, id)
  local p = S.itemPicker
  local dest = (p and p.dest) or "bag"
  if dest == "held" then
    local changed = Ops.setHeldItem(S, S.editingMon, id)
    if changed then
      Ops.closeItemPicker(S, Kit)
    end
    return changed
  end
  if dest == "pc" then
    return feedback(S, Kit, Ops.addToPc(S, id), dest)
  end
  return feedback(S, Kit, Ops.addToBag(S, id), dest)
end

function Picker.draw(S, Kit, width, height)
  local p = S.itemPicker
  if not p then
    return
  end
  local s = Kit.scale

  -- The click that opened the picker is still the frame's click: the panel
  -- dispatches earlier in App.draw than this overlay does, so without
  -- swallowing it the scrim below would read it as a tap outside and shut the
  -- picker in the same frame it went up.
  if p.opened then
    p.opened = nil
    Kit.blockClicks = true
  end

  -- the scrim doubles as the "tap outside to cancel" target; it covers the
  -- full window so unsafe bands (notch / home indicator) stay dimmed too
  Theme.col(PAL.bg, 0.82)
  love.graphics.rectangle("fill", 0, 0, width, height)

  -- Card fills / centres in SafeArea so phones and RGxxx landscapes keep a
  -- usable list (#917 / #715).
  local x, y, w, h, pad = PickerChrome.card(Kit, width, height)
  if Kit.press(0, 0, width, height) and not Kit.hit(x, y, w, h) then
    Ops.closeItemPicker(S, Kit)
    return
  end

  Kit.card(x, y, w, h)
  local cx, cy = x + pad, y + pad
  local inner = w - 2 * pad

  local closeW = PickerChrome.closeSize(Kit)
  local captionH = Kit.textHeight("caption")
  local headH = math.max(captionH, closeW)
  if not drawFeedback(p, Kit, cx, cy, inner - closeW - 10 * s, headH) then
    Kit.caption(cx, cy + (headH - captionH) / 2, "ADD AN ITEM")
  end
  if
    Kit.iconButton(
      x + w - pad - closeW,
      cy + (headH - closeW) / 2,
      closeW,
      closeW,
      "x",
      "Close picker"
    )
  then
    Ops.closeItemPicker(S, Kit)
    return
  end
  cy = cy + headH + 10 * s

  -- Destination toggle.  Which list an item lands in is the only real choice
  -- here, so it is a pair of chips at the top rather than two buttons at the
  -- bottom that each mean "commit, and also pick a destination".
  local half = (inner - 8 * s) / 2
  local destH = math.max(PickerChrome.tapMin(Kit), math.floor(30 * s))
  if p.dest == "held" then
    Kit.text("small", "Choose a held item", cx, cy, PAL.caption)
  else
    if Kit.chip(cx, cy, half, destH, "Bag", p.dest ~= "pc", PAL.green, PAL.steel) then
      p.dest = "bag"
    end
    if Kit.chip(cx + half + 8 * s, cy, half, destH, "PC", p.dest == "pc", PAL.green, PAL.steel) then
      p.dest = "pc"
    end
  end
  cy = cy + destH + 10 * s

  local fieldH = PickerChrome.fieldH(Kit)
  p.query = Kit.textfield(FIELD_ID, cx, cy, inner, fieldH, p.query, "type an item name or id")
  cy = cy + fieldH + 10 * s

  local hits = Picker.results(S)
  local listH, rowH, rowGap, pagerH = PickerChrome.listMetrics(Kit, y, h, pad, cy)
  local perPage = math.max(1, math.floor((listH + rowGap) / (rowH + rowGap)))
  -- wheel / touch drag scroll the modal list too; the shield is already
  -- lowered for this layer, so Kit.scroll works here and only here
  local drawn, shift = Kit.list(p, "offset", cx, cy, inner, listH, #hits, rowH + rowGap)

  if #hits == 0 then
    Kit.emptyBox(cx, cy, inner, listH, "Nothing matches that.")
  else
    Kit.pushClip(cx, cy, inner, listH)
    for i = 1, drawn do
      local id = hits[p.offset + i]
      if not id then
        break
      end
      local ry = cy + (i - 1) * (rowH + rowGap) - shift
      if Kit.row(cx, ry, inner, rowH, false, PAL.green, 9 * s) then
        Picker.commit(S, Kit, id)
      end
      -- how many the save already holds, so a second add is an informed one
      local have = (S.save.inventory and S.save.inventory[id]) or (Ops.pcItems(S) or {})[id]
      local tail = have and ("x%d"):format(have) or ""
      local tailW = Kit.textWidth("tiny", tail)
      Kit.text(
        "monoRow",
        Kit.ellipsize(
          "monoRow",
          (S.data.items[id] and S.data.items[id].name) or id,
          inner - tailW - 30 * s
        ),
        cx + 10 * s,
        ry + (rowH - Kit.textHeight("monoRow")) / 2,
        PAL.text
      )
      if tail ~= "" then
        Kit.textRight(
          "tiny",
          tail,
          cx + inner - 10 * s,
          ry + (rowH - Kit.textHeight("tiny")) / 2,
          PAL.caption
        )
      end
    end
    Kit.popClip()
    Kit.listScrollbar(p, "offset", cx, cy, inner, listH)
  end

  p.offset = Kit.pager(cx, y + h - pad - pagerH, inner, p.offset, #hits, perPage)
end

return Picker
