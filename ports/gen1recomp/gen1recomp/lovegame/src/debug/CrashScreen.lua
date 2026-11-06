-- A small, self-contained crash screen.  No game assets are needed: this can
-- run while the launcher, a mod, or the normal renderer is failing.
local CrashScreen = {}

local PALETTES = {
  red = {
    background = { 0.055, 0.065, 0.085 },
    card = { 0.105, 0.12, 0.15 },
    panel = { 0.075, 0.09, 0.115 },
    accent = { 1, 0.42, 0.43 },
  },
  blue = {
    background = { 0.055, 0.105, 0.17 },
    card = { 0.09, 0.16, 0.245 },
    panel = { 0.065, 0.125, 0.20 },
    accent = { 0.43, 0.76, 1 },
  },
}

local WHITE = { 0.97, 0.98, 1 }
local MUTED = { 0.72, 0.78, 0.85 }
local BORDER = { 0.31, 0.39, 0.48 }

local function color(g, value, alpha)
  g.setColor(value[1], value[2], value[3], alpha or 1)
end

local function textFor(report)
  local owner = report.owner or {}
  local isMod = owner.kind == "mod"
  local source = isMod and ("Mod: " .. tostring(owner.name or owner.id or "Unknown mod"))
    or "Game itself (gen1recomp)"
  if isMod and owner.id and owner.name ~= owner.id then
    source = source .. " (" .. tostring(owner.id) .. ")"
  end

  local advice = isMod
    and "Try disabling this mod, then restart the game."
    or "Restart the game. If this happens again, share the error log."
  if not report.saved then
    advice = "The error log could not be saved. Take a photo of this screen."
  end

  return {
    source = source,
    advice = advice,
    logLabel = report.saved and "ERROR LOG" or "ERROR LOG NOT SAVED",
    logPath = tostring(report.logPath or "Save directory unavailable"),
    footer = report.saved and "Share this file when reporting the problem."
      or "Keep this screen open if you need to note the location.",
  }
end

function CrashScreen.fallbackText(report)
  local copy = textFor(report)
  local sourceLine = report.source or ("Likely source: " .. copy.source)
  if report.owner and report.owner.kind == "engine" then
    sourceLine = "Likely source: " .. copy.source
  end
  return table.concat({
    "The game ran into a problem.",
    sourceLine,
    copy.advice,
    (report.saved and "Error log: " or "Could not save error log: ")
      .. copy.logPath,
  }, "\n\n")
end

local function makeFont(g, size)
  local ok, font = pcall(g.newFont, math.max(10, math.floor(size + 0.5)))
  if ok and font then return font end
  return g.getFont and g.getFont() or nil
end

function CrashScreen.new(report, variant)
  local g = love and love.graphics
  if not g or not g.getDimensions or not g.rectangle or not g.printf then
    return nil
  end
  local w, h = g.getDimensions()
  local scale = math.min(1.4, w / 900, h / 620)
  if scale <= 0 then return nil end
  if love.audio and love.audio.stop then pcall(love.audio.stop) end
  if love.mouse and love.mouse.setVisible then pcall(love.mouse.setVisible, true) end
  if g.setCanvas then pcall(g.setCanvas) end
  if g.reset then pcall(g.reset) end
  if g.origin then pcall(g.origin) end
  local fonts = {
    small = makeFont(g, 13 * scale),
    title = makeFont(g, 31 * scale),
    source = makeFont(g, 22 * scale),
    body = makeFont(g, 16 * scale),
    path = makeFont(g, 14 * scale),
  }
  return {
    report = report,
    copy = textFor(report),
    palette = PALETTES[variant] or PALETTES.red,
    fonts = fonts,
    scale = scale,
    scroll = 0,
    canCopy = report.saved and love.system and love.system.setClipboardText
      and love.keyboard and love.keyboard.isDown and true or false,
  }
end

local function write(g, font, value, x, y, width, ink, align)
  if font and g.setFont then g.setFont(font) end
  color(g, ink)
  g.printf(value, x, y, width, align or "left")
end

local function geometry(screen)
  local g = love.graphics
  local w, h = g.getDimensions()
  local s = screen.scale
  local cardW = math.min(w - 32 * s, 840 * s)
  local cardH = math.min(h - 24 * s, 500 * s)
  local x, y = (w - cardW) / 2, (h - cardH) / 2
  local left, usable = x + 34 * s, cardW - 68 * s
  return {
    w = w, h = h, s = s, x = x, y = y,
    cardW = cardW, cardH = cardH, left = left, usable = usable,
    buttonX = x + cardW - 184 * s,
    buttonY = y + cardH - 65 * s,
    buttonW = 150 * s,
    buttonH = 43 * s,
  }
end

local function clamp(value, low, high)
  return math.max(low, math.min(value, high))
end

local function wrappedLines(font, value, width)
  local lines = {}
  for raw in (tostring(value or "") .. "\n"):gmatch("(.-)\n") do
    local ok, _, wrapped = false, nil, nil
    if font and font.getWrap then
      ok, _, wrapped = pcall(font.getWrap, font, raw, width)
    end
    if ok and type(wrapped) == "table" and #wrapped > 0 then
      for _, line in ipairs(wrapped) do lines[#lines + 1] = line end
    elseif font and font.getWidth then
      local line = ""
      for i = 1, #raw do
        local nextLine = line .. raw:sub(i, i)
        if line ~= "" and font:getWidth(nextLine) > width then
          lines[#lines + 1] = line
          line = raw:sub(i, i)
        else
          line = nextLine
        end
      end
      lines[#lines + 1] = line
    else
      lines[#lines + 1] = raw
    end
  end
  return lines
end

local function point(box, x, y)
  if type(x) ~= "number" or type(y) ~= "number" then return nil, nil end
  -- Some touch hosts send normalized coordinates instead of pixels.
  if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
    return x * box.w, y * box.h
  end
  return x, y
end

function CrashScreen.scroll(screen, amount)
  screen.scroll = clamp((screen.scroll or 0) + amount, 0,
    screen.scrollMax or math.huge)
end

function CrashScreen.scrollTo(screen, endOfLog)
  screen.scroll = endOfLog and (screen.scrollMax or math.huge) or 0
end

function CrashScreen.pointerPressed(screen, id, x, y)
  local area = screen.detailArea
  if not area then return false end
  x, y = point(geometry(screen), x, y)
  if not x or x < area.x or x > area.x + area.w
      or y < area.y or y > area.y + area.h then return false end
  screen.drag = { id = id, y = y }
  if screen.scrollMax and screen.scrollMax > 0
      and x >= area.barX - 6 * screen.scale then
    screen.scroll = clamp(((y - area.y) / area.h) * screen.scrollMax,
      0, screen.scrollMax)
  end
  return true
end

function CrashScreen.pointerMoved(screen, id, x, y)
  if not screen.drag or screen.drag.id ~= id then return false end
  local _, movedY = point(geometry(screen), x, y)
  y = movedY
  if not y then return false end
  CrashScreen.scroll(screen, screen.drag.y - y)
  screen.drag.y = y
  return true
end

function CrashScreen.pointerReleased(screen, id)
  if screen.drag and screen.drag.id == id then screen.drag = nil end
end

function CrashScreen.hitClose(screen, x, y)
  local box = geometry(screen)
  x, y = point(box, x, y)
  if not x then return false end
  return x >= box.buttonX and x <= box.buttonX + box.buttonW
    and y >= box.buttonY and y <= box.buttonY + box.buttonH
end

function CrashScreen.draw(screen)
  local g = love.graphics
  local box = geometry(screen)
  local s, x, y = box.s, box.x, box.y
  local cardW, cardH, left, usable = box.cardW, box.cardH,
    box.left, box.usable
  local palette, copy = screen.palette, screen.copy

  g.origin()
  color(g, palette.background)
  g.clear(palette.background[1], palette.background[2], palette.background[3])
  color(g, { 0, 0, 0 }, 0.22)
  g.rectangle("fill", x + 5 * s, y + 9 * s, cardW, cardH, 14 * s, 14 * s)
  color(g, palette.card)
  g.rectangle("fill", x, y, cardW, cardH, 14 * s, 14 * s)
  color(g, palette.accent)
  g.rectangle("fill", x, y, cardW, 6 * s, 14 * s, 14 * s)

  write(g, screen.fonts.small, "GEN1RECOMP  /  GAME INTERRUPTED",
    left, y + 27 * s, usable, palette.accent)
  write(g, screen.fonts.title, "The game ran into a problem",
    left, y + 57 * s, usable, WHITE)
  color(g, BORDER, 0.55)
  g.rectangle("fill", left, y + 108 * s, usable, 1 * s)

  write(g, screen.fonts.small, "Likely source",
    left, y + 132 * s, usable, MUTED)
  write(g, screen.fonts.source, copy.source,
    left, y + 155 * s, usable, WHITE)
  local sourceLines = wrappedLines(screen.fonts.source, copy.source, usable)
  local sourceLineH = math.max(31 * s,
    ((screen.fonts.source and screen.fonts.source.getHeight
      and screen.fonts.source:getHeight()) or 22 * s) * 1.1)
  local sourceHeight = #sourceLines * sourceLineH
  local adviceY = y + 155 * s + sourceHeight + 10 * s
  write(g, screen.fonts.body, copy.advice,
    left, adviceY, usable, MUTED)

  local adviceLines = wrappedLines(screen.fonts.body, copy.advice, usable)
  local adviceLineH = math.max(20 * s,
    ((screen.fonts.body and screen.fonts.body.getHeight
      and screen.fonts.body:getHeight()) or 16 * s) * 1.2)
  local panelY = math.max(y + 236 * s,
    adviceY + #adviceLines * adviceLineH + 18 * s)
  local panelH = math.max(0, y + cardH - 83 * s - panelY)
  color(g, palette.panel)
  g.rectangle("fill", left, panelY, usable, panelH, 9 * s, 9 * s)
  write(g, screen.fonts.small, copy.logLabel,
    left + 18 * s, panelY + 15 * s, usable - 36 * s, palette.accent)
  write(g, screen.fonts.small, "Scroll for details",
    left + usable - 190 * s, panelY + 15 * s, 172 * s, MUTED, "right")
  write(g, screen.fonts.path, copy.logPath,
    left + 18 * s, panelY + 42 * s, usable - 36 * s, WHITE)

  local pathFont = screen.fonts.path
  local pathLines = wrappedLines(pathFont, copy.logPath, usable - 36 * s)
  local pathLineH = ((pathFont and pathFont.getHeight and pathFont:getHeight())
    or 12 * s) * 1.25
  local detailY = panelY + 42 * s + #pathLines * pathLineH + 7 * s
  local area = {
    x = left + 18 * s, y = detailY,
    w = usable - 36 * s,
    h = math.max(1, panelY + panelH - 8 * s - detailY),
    barX = left + usable - 23 * s,
    textW = usable - 59 * s,
  }
  screen.detailArea = area
  if screen.wrapWidth ~= area.textW then
    screen.detailLines = wrappedLines(screen.fonts.path,
      screen.report.details or "No further details available.", area.textW)
    screen.wrapWidth = area.textW
  end
  local font = screen.fonts.path
  local lineH = ((font and font.getHeight and font:getHeight()) or 12 * s) * 1.25
  screen.lineHeight = lineH
  screen.scrollMax = math.max(0, #screen.detailLines * lineH - area.h)
  screen.scroll = clamp(screen.scroll or 0, 0, screen.scrollMax)
  local clipX, clipY, clipW, clipH
  if g.getScissor then clipX, clipY, clipW, clipH = g.getScissor() end
  if g.setScissor then
    g.setScissor(math.floor(area.x), math.floor(area.y),
      math.ceil(area.textW), math.ceil(area.h))
  end
  local first = math.floor(screen.scroll / lineH) + 1
  local last = math.min(#screen.detailLines,
    math.ceil((screen.scroll + area.h) / lineH) + 1)
  for i = first, last do
    write(g, font, screen.detailLines[i], area.x,
      area.y + (i - 1) * lineH - screen.scroll, area.textW, MUTED)
  end
  if g.setScissor then
    if clipX then g.setScissor(clipX, clipY, clipW, clipH)
    else g.setScissor() end
  end
  if screen.scrollMax > 0 then
    color(g, BORDER, 0.7)
    g.rectangle("fill", area.barX, area.y, 4 * s, area.h, 2 * s, 2 * s)
    local thumbH = math.min(area.h, math.max(15 * s,
      area.h * area.h / (area.h + screen.scrollMax)))
    local thumbY = area.y + (area.h - thumbH)
      * (screen.scroll / screen.scrollMax)
    color(g, palette.accent)
    g.rectangle("fill", area.barX, thumbY, 4 * s, thumbH, 2 * s, 2 * s)
  end
  write(g, screen.fonts.small, copy.footer,
    left, y + cardH - 53 * s, usable - 174 * s, MUTED)
  local controls = "Esc / Start / Back: Close"
  if screen.copied then
    controls = "Log path copied to clipboard."
  elseif screen.canCopy then
    controls = controls .. "  /  Ctrl+C: Copy path"
  end
  write(g, screen.fonts.small, controls,
    left, y + cardH - 30 * s, usable - 174 * s, WHITE)

  color(g, palette.accent)
  g.rectangle("fill", box.buttonX, box.buttonY, box.buttonW, box.buttonH,
    8 * s, 8 * s)
  write(g, screen.fonts.body, "Close game",
    box.buttonX + 15 * s, box.buttonY + 11 * s,
    box.buttonW - 30 * s, palette.background)
end

return CrashScreen
