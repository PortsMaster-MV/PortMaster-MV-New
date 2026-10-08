-- Non-dismissable loading overlays.
--
-- The rule this module enforces: ANY operation that can make the UI wait --
-- a network fetch, a ROM extraction, a mod install, an update check -- puts
-- something obvious on screen for its whole duration.  The old launcher
-- failed this twice over: slow work ran synchronously on the main thread, so
-- the window simply stopped responding (the Find Mods tab could hang for
-- minutes with no indication it was doing anything at all), and the few
-- operations that did report progress did so as a small line of text.
--
-- Two presentations:
--   Loader.overlay(...)  a modal scrim + panel, for work the user must wait
--                        on before doing anything else.  It BLOCKS input
--                        (Kit.blockClicks) and offers no dismiss control --
--                        that is deliberate, so a half-finished install can
--                        never be clicked around.  Cancellable work passes
--                        an onCancel and gets exactly one Cancel button.
--   Loader.inline(...)   a spinner + label sized to a control, for work that
--                        only blocks part of the UI (a row's update check).
--
-- Callers drive both from a state table; nothing here owns state or time, so
-- the same overlay renders identically in a screenshot test.

local Kit = require("src.ui.kit.Kit")
local Theme = require("src.ui.kit.Theme")
local PAL = Theme.PAL

local Loader = {}

-- Scrim alpha.  Not opaque: the user keeps the context of what they were
-- doing, which is most of why a modal beats a blank screen.
local SCRIM_A = 0.82

-- spec = {
--   title    = "Fetching mod index",      -- required, the verb in progress
--   detail   = "index.json from ...",     -- optional second line
--   progress = 0..1 or nil,               -- nil = indeterminate (spinner)
--   count    = "3 of 12",                 -- optional right-aligned counter
--   onCancel = function() end,            -- optional; adds a Cancel button
--   cancelLabel = "Cancel",
-- }
-- Returns true when the cancel button was activated this frame.
function Loader.overlay(m, spec)
  if not spec then return false end
  local G = love and love.graphics
  local W, H = m.W, m.H

  -- The scrim covers the whole window, not just the app column: a modal that
  -- leaves the letterboxed margins live is a modal you can click around.
  if G then
    Theme.fill(0, 0, W, H, PAL.bg, SCRIM_A)
  end
  -- Everything drawn BEFORE this call is now shielded; the panel below
  -- lowers the shield for its own controls.
  Kit.blockClicks = true

  local pw = math.floor(math.min(m.w - 2 * m.pad, 460 * m.s))
  local ph = math.floor((spec.onCancel and 210 or 160) * m.s)
  local px = math.floor((W - pw) / 2)
  local py = math.floor((H - ph) / 2)

  Kit.card(px, py, pw, ph, true)

  local pad = math.floor(18 * m.s)
  local cx = px + pw / 2

  -- Spinner (indeterminate) or a progress bar (determinate).  Never both.
  local y = py + pad
  if spec.progress then
    Kit.textCenter("button", spec.title, px + pad, y, pw - 2 * pad, PAL.heading)
    y = y + Kit.textHeight("button") + math.floor(14 * m.s)
    Kit.progress(px + pad, y, pw - 2 * pad, math.floor(10 * m.s), spec.progress)
    y = y + math.floor(10 * m.s) + math.floor(10 * m.s)
    local pct = ("%d%%"):format(math.floor(spec.progress * 100 + 0.5))
    Kit.textCenter("small", pct, px + pad, y, pw - 2 * pad, PAL.detail)
    y = y + Kit.textHeight("small") + math.floor(6 * m.s)
  else
    local r = math.floor(16 * m.s)
    Kit.spinner(cx, y + r, r)
    y = y + 2 * r + math.floor(14 * m.s)
    Kit.textCenter("button", spec.title, px + pad, y, pw - 2 * pad, PAL.heading)
    y = y + Kit.textHeight("button") + math.floor(6 * m.s)
  end

  if spec.detail and spec.detail ~= "" then
    Kit.textCenter("small",
      Kit.ellipsize("small", spec.detail, pw - 2 * pad),
      px + pad, y, pw - 2 * pad, PAL.muted)
    y = y + Kit.textHeight("small") + math.floor(4 * m.s)
  end
  if spec.count and spec.count ~= "" then
    Kit.textCenter("micro", spec.count, px + pad, y, pw - 2 * pad, PAL.faint)
  end

  local cancelled = false
  if spec.onCancel then
    -- The one control a blocking overlay may have.  It lives inside the
    -- panel, so it is the only thing on screen that can take a click.
    Kit.blockClicks = false
    local bw = math.floor(math.min(pw - 2 * pad, 160 * m.s))
    local bh = m.btnH
    if Kit.button(px + (pw - bw) / 2, py + ph - pad - bh, bw, bh,
        spec.cancelLabel or "Cancel",
        { kind = "ghost", id = "loader:cancel" }) then
      cancelled = true
    end
    Kit.blockClicks = true
  end
  return cancelled
end

-- A spinner plus label occupying a control-sized rect.  Used in place of the
-- button that started the work, so the row does not reflow while it runs.
function Loader.inline(x, y, w, h, label)
  local r = math.floor(math.min(h, 20 * Kit.scale) / 2)
  local cx = x + r + 4
  Kit.spinner(cx, y + h / 2, r)
  if label then
    local lx = cx + r + 8
    Kit.text("small", Kit.ellipsize("small", label, math.max(0, x + w - lx)),
      lx, y + (h - Kit.textHeight("small")) / 2, PAL.muted)
  end
end

-- A tiny spinner sized to sit inside a text run (a mod row checking for
-- updates).  Returns the width it consumed.
function Loader.dot(x, y, size)
  local r = size / 2
  Kit.spinner(x + r, y + r, r)
  return size
end

return Loader
