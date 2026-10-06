-- The save editor's look, delegated to the shared high-contrast theme
-- (src/ui/kit/Theme.lua).
--
-- The editor is reachable straight off a launcher save row (Edit), so the two
-- windows have to read as one app.  They used to do that by keeping two
-- copies of the same navy palette in sync by hand; now there is one palette
-- and this file is the adapter.  Everything below is either a re-export or a
-- shim for a primitive the old navy design had and the flat one does not:
--
--   gradRounded  ->  flat fill of the bottom colour (there are no gradients)
--   glow         ->  nothing (there are no glows)
--   dashed       ->  a plain hairline (the dashed path sampled a rounded
--                    outline into a polyline every frame for an empty-state
--                    box, which is a lot of work to say "nothing here")
--
-- Keeping the old signatures means the editor's panels did not have to be
-- rewritten to change theme, and a panel that has not been revisited yet
-- still lands on the new palette instead of drawing navy into a black window.

local Shared = require("src.ui.kit.Theme")

local Theme = {}
-- A 44px touch control needs a visible curve, including solid blue/green
-- actions. Explicit segments avoid the coarse automatic corner polygons.
Theme.CONTROL = { radius = 14, segments = 48 }
function Theme.radius()
  return Theme.CONTROL.radius
end

-- The palette itself, plus the aliases the editor's panels already use.
local PAL = {}
for k, v in pairs(Shared.PAL) do PAL[k] = v end
-- Names the editor uses that the shared palette spells differently.
PAL.cardTint   = PAL.bg
PAL.cardBody   = PAL.bg
PAL.chipTop    = PAL.bg
PAL.chipBot    = PAL.bg
PAL.chipInk    = PAL.text
PAL.bgTop      = PAL.bg
PAL.bgMid      = PAL.bg
PAL.bgBot      = PAL.bg
Theme.PAL = PAL

Theme.col = Shared.col
Theme.clamp = Shared.clamp
Theme.snap = Shared.snap
-- The editor's stroke carries a corner radius as its 5th argument (the
-- shared one takes the colour there).  Route it to the rounded variant so
-- the radius the panels already pass is honoured rather than dropped.
function Theme.stroke(x, y, w, h, r, c, a, lw)
  Shared.strokeRounded(x, y, w, h, c, a, lw, math.min(r or 0, Theme.radius()), Theme.CONTROL.segments)
end
Theme.spaced = Shared.spaced
Theme.spacedWidth = Shared.spacedWidth
Theme.ellipsize = Shared.ellipsize
Theme.ellipsizeLeft = Shared.ellipsizeLeft
Theme.meter = Shared.meter
Theme.versionRail = Shared.versionRail
Theme.fonts = Shared.fonts
function Theme.fillRounded(x, y, w, h, c, a, r)
  Shared.fillRounded(x, y, w, h, c, a, r or Theme.radius(), Theme.CONTROL.segments)
end
function Theme.strokeRounded(x, y, w, h, c, a, lw, r)
  Shared.strokeRounded(x, y, w, h, c, a, lw, r or Theme.radius(), Theme.CONTROL.segments)
end
Theme.emboss = Shared.emboss
Theme.BOLD_OFFSET = Shared.BOLD_OFFSET

-- The editor calls card/row with a trailing radius (and row with an alpha)
-- that the flat theme has no use for; accept and ignore them.
function Theme.card(x, y, w, h, _r)
  Shared.card(x, y, w, h)
end

function Theme.row(x, y, w, h, _r, _alpha)
  Shared.row(x, y, w, h)
end

-- Flat fill of the "bottom" colour: the old gradient's endpoint, so a control
-- that used to fade into it keeps roughly its old weight.
function Theme.gradRounded(x, y, w, h, _r, _cTop, cBot, _aTop, aBot)
  Shared.fill(x, y, w, h, cBot, aBot)
end

-- No glows in this theme.  Kept so call sites do not have to be edited, and
-- so nothing silently starts setting blend modes again.
function Theme.glow() end

-- The empty-state box is a hairline now, not a dashed outline.
function Theme.dashed(x, y, w, h, _r, _dash, _gap)
  Shared.stroke(x, y, w, h, PAL.line, 0.22, 1)
end

function Theme.field(w, h)
  Shared.field(w, h)
end

return Theme
