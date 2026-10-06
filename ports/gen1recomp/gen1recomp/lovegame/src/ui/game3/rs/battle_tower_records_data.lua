local D = {}
local function clamp(value)
  return math.min(9999, math.floor(tonumber(value) or 0) % 65536)
end
function D.isCurrent(state) return state == 2 or state == 3 or state == 6 end
function D.model(session, manifest)
  local b, rows, strings = session.battleTower or {}, {}, manifest.strings
  for i = 1, 2 do
    rows[i] = {level = strings[i == 1 and "lv50" or "lv100"],
      label = strings[D.isCurrent((b.var_4AE or {})[i]) and "current" or "previous"],
      streak = clamp((b.currentWinStreaks or {})[i]),
      recordLabel = strings.record, record = clamp((b.recordWinStreaks or {})[i])}
  end
  return {title = (strings.title:gsub("{PLAYER}", function() return tostring(session.name or "") end)), rows = rows}
end
function D.centerOffset(width, textWidth)
  return (math.floor(width / 2) - math.floor(textWidth / 2)) % 256
end
function D.numberText(value, width, measure)
  local number = tostring(value)
  local numberWidth = measure(number)
  if width > numberWidth then number = string.char(252, 19, width - numberWidth) .. number end
  return number
end
function D.streakText(format, value, width, measure)
  local number = D.numberText(value, width, measure)
  return (format:gsub("{STR_VAR_1}", function() return number end))
end
return D
