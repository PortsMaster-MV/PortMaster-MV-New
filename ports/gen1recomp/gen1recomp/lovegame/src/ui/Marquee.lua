-- Scrolling for a menu line too long for its box: hold, step one character
-- at a time, hold on the tail, snap back.  Shared by the Gen 1 four-box
-- viewport (src/ui/OptionRows.lua) and the Gen 2 textbox
-- (src/ui/gen2/OptionsMenu.lua) -- different widths, same problem.

local Marquee = {}

Marquee.HOLD = 1.0
Marquee.STEP = 0.25

-- Only ever one row scrolls (the cursor's), so one shared phase keeps that
-- row's label and value stepping together.
local phase = { key = nil, start = 0 }

local function clock()
  local timer = love and love.timer and love.timer.getTime
  return timer and timer() or 0
end

-- Pure, so a test can step it without a clock.
function Marquee.at(text, maxChars, elapsed)
  text = text or ""
  local over = #text - maxChars
  if over <= 0 then return text end
  local span = Marquee.HOLD * 2 + over * Marquee.STEP
  local now = elapsed % span
  local offset
  if now < Marquee.HOLD then
    offset = 0
  elseif now < Marquee.HOLD + over * Marquee.STEP then
    offset = math.floor((now - Marquee.HOLD) / Marquee.STEP)
  else
    offset = over
  end
  return text:sub(offset + 1, offset + maxChars)
end

-- `key` identifies the highlighted row; changing it restarts the cycle.
function Marquee.scroll(text, maxChars, key)
  if not text or #text <= maxChars then return text or "" end
  if phase.key ~= key then phase.key, phase.start = key, clock() end
  return Marquee.at(text, maxChars, clock() - phase.start)
end

function Marquee.clip(text, maxChars)
  return (text or ""):sub(1, maxChars)
end

return Marquee
