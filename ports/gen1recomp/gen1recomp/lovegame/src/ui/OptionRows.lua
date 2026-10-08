-- The four-box options viewport, extracted from OptionsMenu so the mod
-- manager's per-mod options auto-UI renders schemas in the same idiom.
-- Rows are descriptors:
--   { id, label, value = fn(game) -> string,
--     step = fn(game, dir) -> changed, activate = fn(game) }
-- step handles Left/Right/A cyclers; activate is the A-press action for
-- rows that open something instead (MODS, CANCEL stays the caller's).

local Font = require("src.render.Font")
local Marquee = require("src.ui.Marquee")
local Theme = require("src.ui.Theme")

local OptionRows = {}

OptionRows.VISIBLE = 4 -- option boxes on screen at once (4 tiles each)

-- Font.drawBox(0, y, 20, 4) spends column 19 on the frame, so a line drawn
-- to the 160px screen edge prints over its own border.
local CONTENT_RIGHT = 152
local function fits(x) return math.floor((CONTENT_RIGHT - x) / 8) end

-- keep the cursor's box inside the viewport; the fixed bottom row shows
-- the tail of the list
function OptionRows.clampScroll(index, scroll, total, bottomRow)
  if bottomRow and index >= bottomRow then
    return math.max(0, total - OptionRows.VISIBLE)
  elseif index <= scroll then
    return index - 1
  elseif index > scroll + OptionRows.VISIBLE then
    return index - OptionRows.VISIBLE
  end
  return scroll
end

-- one bordered box per row, label line + value line, with the fixed
-- bottom line below (BACK in the options menu, the manager's footer)
function OptionRows.draw(game, rows, index, scroll, bottomLabel, bottomRow)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, 160, 144)
  for slot = 1, OptionRows.VISIBLE do
    local i = scroll + slot
    local row = rows[i]
    if not row then break end
    Font.drawBox(0, (slot - 1) * 4, 20, 4)
    love.graphics.setColor(0, 0, 0, 1)
    local label = row.label or ""
    local value = row.value and row.value(game) or ""
    if i == index then
      local key = tostring(row.id or row.label) .. "\0" .. tostring(value)
      label = Marquee.scroll(label, fits(16), key)
      value = Marquee.scroll(value, fits(24), key)
    else
      label = Marquee.clip(label, fits(16))
      value = Marquee.clip(value, fits(24))
    end
    Font.draw(label, 16, ((slot - 1) * 4 + 1) * 8)
    Font.draw(value, 24, ((slot - 1) * 4 + 2) * 8)
    if i == index then
      Font.drawCode(Theme.cursor, 8, ((slot - 1) * 4 + 1) * 8)
    end
  end
  if scroll + OptionRows.VISIBLE < #rows then
    Font.drawCode(Theme.moreArrow, 144, 128)
  end
  if bottomLabel then
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(bottomLabel, 16, 136)
    if bottomRow and index == bottomRow then
      Font.drawCode(Theme.cursor, 8, 136)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return OptionRows
