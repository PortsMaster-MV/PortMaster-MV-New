local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")

local M = {
  STATE = { SLIDE_IN = 0, WAIT = 1, SLIDE_OUT = 2, ERASE = 4 },
  OFFSCREEN_Y = 32,
  SLIDE_SPEED = 2,
}

function M.matches()
  local id = require("src.core.game3.profile").forSession().id
  return id == "ruby" or id == "sapphire"
end

local function constants()
  return require("src.core.game3.constants").of(require("src.core.game3.profile").forSession().id)
end

local function hidden()
  local flag = constants():flag("FLAG_HIDE_MAP_NAME_POPUP")
  local Space = package.loaded["src.core.game3.scripting.space"]
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  if Space and Space.store and Flags and Flags.getFlag then
    return Flags.getFlag(Space.store, nil, flag) == true
  end
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  return session and session.flags and session.flags[flag] == true or false
end

local function printWindow()
  local def = M.def or {}
  local sec = tonumber(def.regionMapSectionId or def.region_map_section_id or def.mapsec) or 0
  local C = constants()
  local name
  if sec == C:id("region_map_sections", "MAPSEC_SECRET_BASE") then
    local sb = require("src.core.game3.rse.init").system("secretBase")
    name = sb and sb.mapName and sb.mapName()
  elseif sec < C:require("region_map_sections", "MAPSEC_NONE") then
    name = require("src.ui.game3.rse.mapsec").name(sec)
  end
  name = name or string.rep(" ", 18)
  local width = Font.measure(name, { font = "normal" }) or 0
  M.window = { sec = sec, name = name, textX = (48 - math.floor(width / 2)) % 256 }
end

function M.show(mapDef)
  if hidden() then return false end
  M.def = mapDef
  if not M.task then
    M.task = { state = 0, yOffset = 32, registerOffset = 32, onscreen = 0, incoming = false }
    printWindow()
  else
    M.task.state = 2
    M.task.incoming = true
  end
  return true
end

function M.dismiss()
  M.task, M.window, M.def = nil, nil, nil
end

function M.frame()
  local t = M.task
  if not t then return end
  if t.state == 0 then
    t.yOffset = t.yOffset - 2
    if t.yOffset <= 0 then t.state, t.onscreen = 1, 0 end
  elseif t.state == 1 then
    t.onscreen = t.onscreen + 1
    if t.onscreen > 120 then t.onscreen, t.state = 0, 2 end
  elseif t.state == 2 then
    t.yOffset = t.yOffset + 2
    if t.yOffset > 31 then
      if t.incoming then
        printWindow()
        t.state, t.incoming = 0, false
      else
        t.state = 4
        return
      end
    end
  elseif t.state == 4 then
    M.dismiss()
    return
  end
  t.registerOffset = t.yOffset
end

function M.update(dt)
  local steps = math.max(1, math.floor((dt or 1 / 60) * 60 + 0.5))
  for _ = 1, steps do
    if not M.task then return end
    M.frame()
  end
end

function M.draw()
  local t, w = M.task, M.window
  if not (t and w) or t.registerOffset >= 32 then return end
  love.graphics.push()
  love.graphics.translate(0, -t.registerOffset)
  Chrome.userFrame(0, 1, 1, 12, 2)
  Font.draw(w.name, 8 + w.textX, 8, { font = "normal", colors = Font.COLOR.NORMAL })
  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

return M
