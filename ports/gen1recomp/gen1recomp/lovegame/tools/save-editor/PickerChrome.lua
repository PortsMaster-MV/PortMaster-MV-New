-- Shared modal-picker frame for Species / Move / Item pickers.
--
-- Desktop keeps a centred card capped at 520x560 logical px.  Phones and
-- RGxxx handhelds (RG34XXSP 720x480, RG35XX 640x480, Switch 1280x720, tall
-- portrait Androids) need the card to nearly fill SafeArea.rect() so the
-- search field, list, and pager stay usable instead of collapsing under a
-- fixed 32px margin into a short landscape window (#917 / #715).

local SafeArea = require("src.core.SafeArea")

local PickerChrome = {}

-- Match the editor's minimum 44px tap target on short handhelds too.
function PickerChrome.tapMin(Kit)
  return Kit.tapMin()
end

-- Usable card rect inside the platform safe area.
-- Returns x, y, w, h, pad.
function PickerChrome.card(Kit, windowW, windowH)
  local s = (Kit and Kit.scale) or 1
  windowW = math.max(1, tonumber(windowW) or 1)
  windowH = math.max(1, tonumber(windowH) or 1)
  local sox, soy, ssw, ssh = SafeArea.rect()
  sox = math.max(0, tonumber(sox) or 0)
  soy = math.max(0, tonumber(soy) or 0)
  ssw = math.max(1, tonumber(ssw) or windowW)
  ssh = math.max(1, tonumber(ssh) or windowH)

  -- Shrink the gutter on short / narrow safe areas so the card keeps room
  -- for caption + search + at least one list row + pager.
  local gutter = math.floor(16 * s)
  local minSide = math.min(ssw, ssh)
  if minSide < 560 * s then
    gutter = math.max(4, math.floor(minSide * 0.03))
  end

  local maxW = math.floor(520 * s)
  local maxH = math.floor(560 * s)
  local w = math.min(ssw - 2 * gutter, maxW)
  local h = math.min(ssh - 2 * gutter, maxH)
  -- Short landscapes (720x480 class): fill the safe height instead of
  -- leaving letterbox bands inside an already-short rect.
  if ssh <= maxH + 2 * gutter then
    h = ssh - 2 * gutter
  end
  if ssw <= maxW + 2 * gutter then
    w = ssw - 2 * gutter
  end
  w = math.max(1, w)
  h = math.max(1, h)

  local x = sox + (ssw - w) / 2
  local y = soy + (ssh - h) / 2
  local pad = math.max(8, math.floor(math.min(18 * s, w * 0.04, h * 0.04)))
  return x, y, w, h, pad
end

-- List-body metrics once caption / field / optional extra chrome are placed.
-- `contentTop` is the y just below that chrome; returns listH, rowH, rowGap,
-- pagerH sized so taps stay >= tapMin and listH never goes negative.
function PickerChrome.listMetrics(Kit, cardY, cardH, pad, contentTop)
  local s = (Kit and Kit.scale) or 1
  local tap = PickerChrome.tapMin(Kit)
  local pagerH = math.max(tap, math.floor(30 * s))
  local rowH = math.max(tap, math.floor(40 * s))
  local rowGap = math.max(4, math.floor(6 * s))
  local listBottom = cardY + cardH - pad - pagerH - math.max(6, math.floor(10 * s))
  local listH = math.max(0, listBottom - contentTop)
  return listH, rowH, rowGap, pagerH
end

function PickerChrome.fieldH(Kit)
  return math.max(PickerChrome.tapMin(Kit), math.floor(34 * ((Kit and Kit.scale) or 1)))
end

function PickerChrome.closeSize(Kit)
  return math.max(PickerChrome.tapMin(Kit), math.floor(30 * ((Kit and Kit.scale) or 1)))
end

return PickerChrome
