-- Immediate-mode widget kit for the save editor, drawn in the launcher's
-- visual language (see Theme.lua and SaveEditor.dc.html).
--
-- Call Kit.beginFrame(mx, my, clicked, wheel) once per love.draw() before any
-- widget and Kit.endFrame() after the last one; widgets read the frame's mouse
-- state to decide hover / click, and endFrame retires the text-input queue so a
-- keystroke is never applied twice.  The wheel notches accumulated since the
-- last frame arrive the same way and are retired the same way: an unclaimed
-- notch dies with the frame rather than scrolling something later (#595).
--
-- Clip-aware hit testing fences scrolled content. Every action uses a
-- 44px minimum target, with layouts reflowing at narrow widths.

local Theme = require("Theme")
local PAL = Theme.PAL
local Button = require("src.ui.kit.Button")
local Icons = require("src.ui.kit.Icons")

local Kit = {}
Kit.mouseX, Kit.mouseY = 0, 0
Kit.mouseClicked = false -- left button pressed this frame
Kit.wheelY = 0 -- wheel notches queued since the last frame (#595)
Kit.focus = nil -- id of the text field receiving keystrokes
Kit.time = 0
Kit.fonts = {}
Kit.scale = 1

function Kit.tapMin()
  return math.max(44, math.floor(38 * (Kit.scale or 1)))
end

local G = love and love.graphics or nil
local edits = {} -- queued textinput / backspace since the last frame
local kbField = nil -- id of the field the OS soft keyboard is raised for

-- Mobile LOVE only delivers love.textinput while setTextInput(true) is
-- active, and that call is what raises the Android/iOS soft keyboard; the
-- rect keeps the focused field visible above it.  Desktop has text input on
-- by default and the launcher hosting this editor depends on that -- the
-- launcher's own fields (slot rename #205, mod index prompt, find search)
-- follow the same rule since #578: arm on open, lower only on mobile -- so
-- neither side ever turns desktop text input off, since setTextInput is
-- global SDL state, not per-widget (#529).
local function mobile()
  local osName = love and love.system and love.system.getOS and love.system.getOS()
  return osName == "Android" or osName == "iOS"
end

local function syncSoftKeyboard(id, x, y, w, h)
  if not (love and love.keyboard and love.keyboard.setTextInput) then
    return
  end
  if id then
    if kbField ~= id then
      kbField = id
      love.keyboard.setTextInput(true, math.floor(x), math.floor(y), math.ceil(w), math.ceil(h))
    end
  elseif kbField then
    kbField = nil
    if mobile() then
      love.keyboard.setTextInput(false)
    end
  end
end

local function canPrintf()
  return G and type(G.printf) == "function"
end

function Kit.beginFrame(mx, my, clicked, wheel)
  Kit.mouseX, Kit.mouseY = mx, my
  Kit.mouseClicked = clicked
  Kit._fieldHit = false
  Kit._focusDrawn = false
  Kit.wheelY = wheel or 0
  -- Mouse taps dispatch on release, so dragging never activates a row.
  -- The real touch stream supplies its own precise drag deltas. SDL
  -- synthesized mouse holds are suppressed until the finger is up.
  local down = false
  if love and love.mouse and love.mouse.isDown then
    down = love.mouse.isDown(1) and true or false
  end
  if Kit.ignoreMouseDown then
    if not down then
      Kit.ignoreMouseDown = nil
    end
    down = false
  end
  Kit.mouseDown = down
  if Kit.touchDown == true then
    Kit.mouseDown = true
  end
  if Kit.mouseDown and not Kit.touchDown then
    local d = Kit._pointerDrag
    if not d then
      Kit._pointerDrag = { x = mx, y = my, lastY = my, startY = my, moved = false }
    else
      if math.abs(my - d.startY) + math.abs(mx - d.x) > 10 then
        d.moved = true
      end
      if d.moved then
        Kit.dragAdd(d.lastY - my)
      end
      d.lastY = my
    end
    if clicked then
      Kit._tapPending = true
    end
    Kit.mouseClicked = false
  elseif Kit._pointerDrag then
    local d = Kit._pointerDrag
    if Kit._tapPending and not d.moved then
      Kit.mouseClicked = true
    end
    Kit._pointerDrag, Kit._tapPending = nil, nil
  end
  if not Kit.mouseDown then
    Kit._drag = nil
  end
  Kit.resetClip()
  if love and love.timer and love.timer.getTime then
    Kit.time = love.timer.getTime()
  end
end

-- Retire this frame's keystrokes.  Anything typed while no field had focus is
-- dropped here rather than replayed into the next field that gets clicked.
-- A wheel notch no list claimed retires with them, for the same reason.
function Kit.endFrame()
  if (Kit.mouseClicked and not Kit._fieldHit) or (Kit.focus and not Kit._focusDrawn) then
    Kit.blur()
  end
  for i = #edits, 1, -1 do
    edits[i] = nil
  end
  Kit.wheelY = 0
  Kit._dragDelta = 0
  if not Kit.touchDown then
    Kit._touchDrag = nil
  end
end

-- Desktop windows keep a stable reading size instead of inflating controls
-- with the monitor. Mobile and console layouts use the launcher touch scale.
function Kit.layout(width, height)
  local osName = love and love.system and love.system.getOS and love.system.getOS()
  Kit.desktop = (osName == "OS X" or osName == "Windows" or osName == "Linux")
    and width >= 960 and height >= 540 and width > height
  local s = Kit.desktop and Theme.clamp(height / 768, 1, 1.15)
    or Theme.clamp(math.min(width / 640, height / 768), 0.9, 1.6) * 1.3
  local key = ("%dx%d:%s"):format(width, height, tostring(Kit.desktop))
  if Kit._fontKey ~= key then
    Kit._fontKey = key
    Kit.fonts = Theme.fonts(s)
  end
  Kit.scale = s
  return s
end

-- ------------------------------------------------------------ input plumbing
-- App forwards love.textinput / love.keypressed here so Kit.textfield can be a
-- real editable field.  Events arrive before draw, so they queue and the
-- focused field drains them while it renders.
function Kit.textinput(text)
  if not Kit.focus then
    return false
  end
  edits[#edits + 1] = { id = Kit.focus, text = text }
  return true
end

-- Returns true when the key was consumed by the focused field, so App can
-- leave its own shortcuts alone while the user is typing.
function Kit.keypressed(key)
  if not Kit.focus then
    return false
  end
  if key == "backspace" then
    edits[#edits + 1] = { id = Kit.focus, text = "\b" }
    return true
  elseif key == "return" or key == "kpenter" or key == "escape" then
    edits[#edits + 1] = { id = Kit.focus, text = key == "escape" and "\27" or "\r" }
    return true
  end
  -- other keys (arrows, shortcuts) fall through to App while a field is hot
  return false
end

-- Used by immediate Enter commits so typing delivered before the next draw
-- is included exactly once.
function Kit.flushText(id, value, sanitize)
  value = tostring(value or "")
  for _, edit in ipairs(edits) do
    if edit.id == id then
      local e = edit.text
      if e == "\b" then
        local at = #value
        while at > 1 and value:byte(at) >= 128 and value:byte(at) < 192 do
          at = at - 1
        end
        value = value:sub(1, at - 1)
      elseif e ~= "\r" and e ~= "\27" then
        value = value .. e
      end
    end
  end
  for i = #edits, 1, -1 do
    if edits[i].id == id then
      table.remove(edits, i)
    end
  end
  return sanitize and sanitize(value) or value
end

function Kit.blur()
  Kit.focus = nil
  syncSoftKeyboard(nil) -- the soft keyboard follows focus down too (#529)
end

-- ------------------------------------------------------------- hit testing
-- A widget inside a scrolled clip region can sit at coordinates outside the
-- visible rect (#715: stacked panels scroll in pixels), so the active clip
-- bounds the hit: what the user cannot see cannot take the tap.
function Kit.hit(x, y, w, h)
  local c = Kit._clipRect
  if
    c
    and not (
      Kit.mouseX >= c.x
      and Kit.mouseX <= c.x + c.w
      and Kit.mouseY >= c.y
      and Kit.mouseY <= c.y + c.h
    )
  then
    return false
  end
  return Kit.mouseX >= x and Kit.mouseX <= x + w and Kit.mouseY >= y and Kit.mouseY <= y + h
end

-- ------------------------------------------------------------ layout audit
-- #715 reflow tests: when a test sets Kit.audit to a table, every control
-- that could take a click this frame appends its rect (plus the clip that
-- bounds it), so a window-size sweep can assert that no two controls
-- overlap and none escapes the window.  Shielded widgets are skipped: under
-- a modal they cannot take the tap, and the modal legitimately covers them.
Kit.audit = nil

local function audit(class, x, y, w, h, label)
  local a = Kit.audit
  if not a or Kit.blockClicks then
    return
  end
  local c = Kit._clipRect
  a[#a + 1] = {
    class = class,
    x = x,
    y = y,
    w = w,
    h = h,
    label = tostring(label or ""),
    clip = c and { x = c.x, y = c.y, w = c.w, h = c.h } or nil,
  }
end

function Kit.hover(x, y, w, h)
  return Kit.hit(x, y, w, h)
end

-- Kit hit-tests without a z-order, so an overlay cannot just be drawn last:
-- every widget underneath it would still take the same click.  A modal raises
-- this shield over the layers it covers (App.draw does it around the chrome
-- and the panel while the species picker is up) and lowers it for its own
-- layer (#541).
Kit.blockClicks = false

function Kit.press(x, y, w, h)
  if Kit.blockClicks then
    return false
  end
  return Kit.mouseClicked and Kit.hit(x, y, w, h)
end

-- ------------------------------------------------------------------- text
local function font(name)
  return Kit.fonts[name] or Kit.fonts.small
end

function Kit.text(name, str, x, y, c, a)
  if not G then
    return 0
  end
  local f = font(name)
  if not f then
    return 0
  end
  G.setFont(f)
  Theme.col(c or PAL.text, a or 1)
  G.print(tostring(str), x, y)
  return f:getWidth(tostring(str))
end

function Kit.textRight(name, str, x2, y, c, a)
  local f = font(name)
  if not f then
    return
  end
  Kit.text(name, str, x2 - f:getWidth(tostring(str)), y, c, a)
end

function Kit.textCenter(name, str, x, y, w, c, a)
  if not G then
    return
  end
  local f = font(name)
  if not f then
    return
  end
  G.setFont(f)
  Theme.col(c or PAL.text, a or 1)
  if canPrintf() then
    G.printf(tostring(str), x, y, w, "center")
  else
    G.print(tostring(str), x + (w - f:getWidth(tostring(str))) / 2, y)
  end
end

function Kit.textBold(name, str, x, y, c, a)
  Kit.text(name, str, x, y, c, a)
  return Kit.text(name, str, x + (Theme.BOLD_OFFSET or 1), y, c, a)
end

function Kit.textCenterBold(name, str, x, y, w, c, a)
  Kit.textCenter(name, str, x, y, w, c, a)
  Kit.textCenter(name, str, x + (Theme.BOLD_OFFSET or 1), y, w, c, a)
end

function Kit.textHeight(name)
  local f = font(name)
  return f and f:getHeight() or 12
end

function Kit.textWidth(name, str)
  local f = font(name)
  return f and f:getWidth(tostring(str)) or 0
end

function Kit.ellipsize(name, str, maxW)
  return Theme.ellipsize(font(name), str, maxW)
end

-- 12px / 2px-tracked uppercase section caption -- the design's one and only
-- section header.  Returns the caption's height so callers can stack below.
function Kit.caption(x, y, str, c)
  if not G then
    return Kit.textHeight("caption")
  end
  local f = font("caption")
  if not f then
    return 12
  end
  G.setFont(f)
  Theme.col(c or PAL.caption, 1)
  Theme.spaced(f, str, x, y, 2 * Kit.scale)
  return f:getHeight()
end

function Kit.captionWidth(str)
  return Theme.spacedWidth(font("caption"), str, 2 * Kit.scale)
end

-- --------------------------------------------------------------- surfaces
function Kit.card(x, y, w, h, r)
  Theme.card(x, y, w, h, r or 16 * Kit.scale)
end

-- A list row.  `selected` rings it in the accent colour (green for "this is
-- the thing you are editing", blue for "this is the thing you are browsing")
-- instead of filling it, so sprites and HP colours stay readable.  Returns
-- true when the row was clicked this frame.
function Kit.row(x, y, w, h, selected, accent, r)
  r = r or 12 * Kit.scale
  audit("row", x, y, w, h, "row")
  if not G then
    return Kit.press(x, y, w, h)
  end
  accent = accent or PAL.green
  if selected then
    Theme.glow(x, y, w, h, r, accent, 0.45)
  end
  Theme.row(x, y, w, h, r, 0.6)
  if selected then
    Theme.stroke(x, y, w, h, r, accent, 0.85, 1.5 * Kit.scale)
  end
  return Kit.press(x, y, w, h)
end

function Kit.meter(x, y, w, h, pct, c)
  Theme.meter(x, y, w, h, pct, c)
end

-- Dashed empty-state box with a centred hint.
function Kit.emptyBox(x, y, w, h, message)
  if not G then
    return
  end
  Theme.col(PAL.cardBorder, 0.4)
  if G.setLineWidth then
    G.setLineWidth(math.max(1, 1 * Kit.scale))
  end
  Theme.dashed(x, y, w, h, 12 * Kit.scale, 7 * Kit.scale, 5 * Kit.scale)
  if G.setLineWidth then
    G.setLineWidth(1)
  end
  local f = font("button")
  if not f then
    return
  end
  Kit.textCenter(
    "button",
    message,
    x + 12 * Kit.scale,
    y + h / 2 - f:getHeight() / 2,
    w - 24 * Kit.scale,
    PAL.muted
  )
end

-- --------------------------------------------------------------- buttons
-- The launcher and editor share one painter; input ownership stays local.
Kit.KINDS = Button.KINDS
local ACTION_ICONS = {
  Save = "save",
  Saved = "save",
  Undo = "undo-2",
  Redo = "redo-2",
  More = "ellipsis",
  Less = "x",
  Reload = "rotate-ccw",
  Open = "folder",
  ["Open..."] = "folder",
  Close = "x",
  ["Discard?"] = "trash",
  Set = "check",
  Add = "plus",
  ["Add item"] = "plus",
  ["Add mon"] = "plus",
  Remove = "trash",
  Release = "trash",
  ["Confirm?"] = "check",
  Drop = "trash",
  Inspect = "pencil",
  Edit = "pencil",
  Withdraw = "download",
  Take = "download",
  Free = "trash",
  ["Sure?"] = "check",
  ["Deposit selected"] = "upload",
  Deposit = "upload",
  Tools = "sliders-horizontal",
  ["Change species"] = "pencil",
  ["Clear nickname"] = "x",
  ["Full heal"] = "heart",
  ["Clone to a box"] = "copy",
  ["Reset to learnset"] = "rotate-ccw",
  ["Max all PP"] = "chevrons-up",
  ["Max all (31)"] = "chevrons-up",
  ["Clear EVs"] = "x",
  Clear = "x",
  ["Max all"] = "chevrons-up",
  ["Sort A-Z"] = "arrow-up-down",
  ["Sort count"] = "arrow-up-down",
  ["Sort #"] = "list-filter",
  ["Clear all"] = "trash",
  ["Wipe dex"] = "trash",
  ["See all"] = "eye",
  ["Own all"] = "check",
  ["Own party + boxes"] = "check",
  Player = "map-pin",
  ["Set here"] = "map-pin",
  Prev = "chevron-left",
  Next = "chevron-right",
}
local ERROR_FILL = { 58, 31, 37 }
local function errorFace(opts)
  if not opts or not opts.invalid then return opts or {} end
  local copy = {}
  for key, value in pairs(opts) do copy[key] = value end
  copy.face, copy.fill, copy.ink, copy.stroke = "invert", ERROR_FILL, PAL.red, PAL.red
  copy.trailingIcon, copy.ring = copy.trailingIcon or "triangle-alert", false
  return copy
end
function Kit.buttonWidth(label, opts, h)
  opts = errorFace(opts)
  h = h or Kit.controlH()
  if opts.iconOnly then
    return h
  end
  local name = opts.font or "button"
  local width = Kit.textWidth(name, label) + 20 * Kit.scale + (Theme.BOLD_OFFSET or 1)
  if (opts.icon or ACTION_ICONS[label]) and not opts.iconStack then
    width = width + math.floor(h * 0.42) + math.floor(7 * Kit.scale)
  end
  if opts.trailingIcon then
    width = width + h * 0.65
  end
  return math.max(Kit.tapMin(), math.ceil(width))
end

function Kit.buttonHeight(label, w, opts)
  local h = Kit.controlH()
  local height = Button.labelLayout(Kit, w, h, label, errorFace(opts)).height + 4 * Kit.scale
  return math.max(h, math.ceil(height))
end

function Kit.button(x, y, w, h, label, opts)
  -- Retired panels still pass scaled radii and raised-key options. Keep the
  -- editor's controls flat, with a visibly rounded touch-control shape, even
  -- when a selected state or an old call site supplies those options.
  local faceOpts = {}
  for key, value in pairs(opts or {}) do
    faceOpts[key] = value
  end
  opts = errorFace(faceOpts)
  opts.radius = Theme.radius()
  opts.segments = Theme.CONTROL.segments
  opts.emboss = false
  opts.fullLabel = true
  if opts.face == "tab" then
    opts.face = "selection"
  end
  opts.icon = opts.icon or ACTION_ICONS[label]
  audit("control", x, y, w, h, label)
  local hot = opts.enabled ~= false and Kit.hover(x, y, w, h)
  local shown = label
  if opts.iconOnly then
    shown = ""
  elseif label and label ~= "" then
    opts.labelLayout = Button.labelLayout(Kit, w, h, label, opts)
  end
  Button.draw(Kit, x, y, w, h, shown, opts, hot, false)
  if opts.invalid then
    Theme.stroke(x, y, w, h, Theme.radius(), PAL.red, 0.95, 2 * Kit.scale)
  end
  return opts.enabled ~= false and Kit.press(x, y, w, h) or false
end

function Kit.iconButton(x, y, w, h, icon, label, opts)
  local faceOpts = {}
  for key, value in pairs(opts or {}) do
    faceOpts[key] = value
  end
  faceOpts.icon, faceOpts.iconOnly = icon, true
  return Kit.button(x, y, w, h, label, faceOpts)
end

function Kit.icon(name, x, y, size, color, alpha)
  Icons.draw(name, x, y, size, color or PAL.text, alpha)
end

local STEPPER_ICONS = {
  minus = "minus",
  plus = "plus",
  previous = "chevron-left",
  next = "chevron-right",
  up = "arrow-up",
  down = "arrow-down",
}

function Kit.stepper(x, y, w, h, action, opts)
  opts = opts or {}
  opts.kind = opts.kind or "ghost"
  opts.font = opts.font or "small"
  return Kit.iconButton(x, y, w, h, STEPPER_ICONS[action] or action, action, opts)
end

local TAB_ICONS = {
  Party = "users",
  Boxes = "grid-2x2",
  Items = "backpack",
  Events = "flag",
  Map = "map-pin",
  Dex = "book-open",
  ["Pokédex"] = "book-open",
  Trainer = "user-round",
  Checks = "shield-check",
  Main = "pencil",
  Stats = "sliders-horizontal",
  Moves = "list-filter",
  Origin = "map-pin",
  Extras = "award",
  Bag = "backpack",
  PC = "package",
  Wallet = "wallet",
  Badges = "award",
  Flags = "flag",
  ["Story flags"] = "flag",
  Trainers = "users",
  ["Items taken"] = "package",
  ["Object toggles"] = "eye",
  ["System & Badges"] = "award",
  Variables = "sliders-horizontal",
  Deposit = "upload",
  Maps = "map-pin",
  View = "eye",
  Spawn = "map-pin",
}
function Kit.navigationIcon(label)
  return TAB_ICONS[label]
end

function Kit.chip(x, y, w, h, label, on, _onColor, _offColor)
  return Kit.button(x, y, w, h, label, {
    face = "tab",
    font = "small",
    active = on,
    icon = TAB_ICONS[label],
    iconStack = TAB_ICONS[label] ~= nil,
  })
end

-- Checkbox row: a 20px box plus a mono label, the Events grid's unit.
-- Returns (newChecked, changed) so callers can write true/nil on a flip.
function Kit.checkbox(x, y, w, h, checked, label, labelColor)
  local clicked = Kit.row(x, y, w, h, false, nil, 9 * Kit.scale)
  local box = 20 * Kit.scale
  local bx, by = x + 12 * Kit.scale, y + (h - box) / 2
  if G then
    local radius = math.min(Theme.radius(), box / 3)
    Theme.fillRounded(bx, by, box, box, PAL.surface, 1, radius)
    Theme.strokeRounded(
      bx,
      by,
      box,
      box,
      checked and PAL.blue or PAL.line,
      checked and 1 or 0.65,
      checked and 2 or 1,
      radius
    )
    if checked then
      local size = box * 0.75
      Icons.draw("check", bx + (box - size) / 2, by + (box - size) / 2, size, PAL.blue)
    end
    local lx = bx + box + 12 * Kit.scale
    Kit.text(
      "mono",
      Kit.ellipsize("mono", label, x + w - lx - 10 * Kit.scale),
      lx,
      y + (h - Kit.textHeight("mono")) / 2,
      labelColor or (checked and PAL.text or PAL.muted)
    )
  end
  if clicked then
    return not checked, true
  end
  return checked, false
end

-- --------------------------------------------------------------- text field
-- A real editable field.  The Events filter used to edge-detect love.keyboard
-- state because Kit had no input widget; this replaces that hack, and App
-- routes love.textinput / love.keypressed in through Kit.textinput /
-- Kit.keypressed.  Returns the (possibly edited) value; the caller stores it.
--
-- `opts.sanitize(value)` (optional) is a post-filter run on the merged text
-- right after this frame's edits and BEFORE it draws, so a keystroke or paste
-- the filter rejects never even flashes on screen.  It gets the whole value
-- because a paste arrives as one textinput chunk alongside existing text.
function Kit.textfield(id, x, y, w, h, value, placeholder, opts)
  audit("control", x, y, w, h, id)
  value = tostring(value or "")
  if Kit.press(x, y, w, h) then
    Kit.focus = id
    Kit._fieldHit = true
  end
  local focused = (Kit.focus == id)
  local clip = Kit._clipRect
  if
    focused
    and clip
    and (y + h <= clip.y or y >= clip.y + clip.h or x + w <= clip.x or x >= clip.x + clip.w)
  then
    Kit.blur()
    focused = false
  end
  if focused then
    Kit._focusDrawn = true
    -- raise (or hand off) the soft keyboard while this field owns focus (#529)
    syncSoftKeyboard(id, x, y, w, h)
    for _, edit in ipairs(edits) do
      if edit.id == id then
        local e = edit.text
        if e == "\b" then
          local i = #value
          while i > 1 and value:byte(i) >= 128 and value:byte(i) < 192 do
            i = i - 1
          end
          value = value:sub(1, i - 1)
        elseif e == "\r" then
          if opts and opts.onSubmit then
            opts.onSubmit(value)
          end
          Kit.blur() -- commit/cancel also lowers the soft keyboard (#529)
          focused = false
        elseif e == "\27" then
          Kit.blur()
          focused = false
        else
          value = value .. e
        end
      end
    end
    if opts and opts.sanitize then
      value = opts.sanitize(value)
    end
  end
  if G then
    local r = Theme.radius()
    local invalid = opts and opts.invalid
    Theme.fillRounded(x, y, w, h, invalid and ERROR_FILL or PAL.rowBg, 0.7, r)
    Theme.stroke(
      x,
      y,
      w,
      h,
      r,
      invalid and PAL.red or focused and PAL.blue or PAL.cardBorder,
      invalid and 0.95 or focused and 0.8 or 0.3,
      invalid and 2 * Kit.scale or focused and 1.5 * Kit.scale or 1
    )
    local pad = 10 * Kit.scale
    local ty = y + (h - Kit.textHeight("mono")) / 2
    if value == "" and not focused then
      Kit.text("mono", placeholder or "", x + pad, ty, PAL.faint)
    else
      local shown = Theme.ellipsizeLeft(font("mono"), value, w - 2 * pad)
      local tw = Kit.text("mono", shown, x + pad, ty, invalid and PAL.red or PAL.heading)
      -- caret: blinks only while focused, parked at the end of the text
      if focused and (Kit.time % 1) < 0.55 then
        Theme.col(PAL.blue, 1)
        G.rectangle("fill", x + pad + tw + 2, ty, math.max(1, Kit.scale), Kit.textHeight("mono"))
      end
    end
  end
  return value
end

-- Forms reserve height before drawing; all editor panels use the same floor.
function Kit.controlH(base)
  return math.max(Kit.tapMin(), (base or 38) * Kit.scale)
end

function Kit.textWrapped(name, str, x, y, w, c)
  local f = font(name)
  if not f or w <= 0 then
    return 0
  end
  local lines
  if f.getWrap then
    local _
    _, lines = f:getWrap(tostring(str), w)
  else
    lines = {}
    local line = ""
    for word in tostring(str):gmatch("%S+") do
      local nextLine = line == "" and word or (line .. " " .. word)
      if line ~= "" and f:getWidth(nextLine) > w then
        lines[#lines + 1] = line
        line = word
      else
        line = nextLine
      end
    end
    if line ~= "" then
      lines[#lines + 1] = line
    end
  end
  for i, line in ipairs(lines) do
    Kit.text(name, line, x, y + (i - 1) * f:getHeight(), c)
  end
  return #lines * f:getHeight()
end

-- ------------------------------------------------------------------ pager
-- Prev / Next / "1-12 of 151".  Drawn even when there is a single page, so a
-- list is never silently truncated (rule 5 of the design spec).  Returns the
-- new offset.
function Kit.pager(x, y, w, offset, total, perPage)
  local h = Kit.controlH()
  local bw = math.max(Kit.tapMin(), math.min(74 * Kit.scale, (w - 10 * Kit.scale) / 2))
  local maxOffset = math.max(0, total - perPage)
  offset = Theme.clamp(offset or 0, 0, maxOffset)
  if
    Kit.button(
      x,
      y,
      bw,
      h,
      "Prev",
      { kind = "accent", font = "small", enabled = offset > 0, radius = 8 * Kit.scale }
    )
  then
    offset = math.max(0, offset - perPage)
  end
  if
    Kit.button(
      x + bw + 10 * Kit.scale,
      y,
      bw,
      h,
      "Next",
      { kind = "accent", font = "small", enabled = offset < maxOffset, radius = 8 * Kit.scale }
    )
  then
    offset = math.min(maxOffset, offset + perPage)
  end
  local shown = math.min(perPage, math.max(0, total - offset))
  local label = ("%d-%d of %d"):format(total > 0 and offset + 1 or 0, offset + shown, total)
  -- the counter clips to the width the caller granted: a panel parking a
  -- button on the pager line passes a reduced w and the text yields instead
  -- of running underneath it (#715)
  local labelX = x + 2 * bw + 20 * Kit.scale
  Kit.text(
    "mono",
    Kit.ellipsize("mono", label, math.max(0, x + w - labelX)),
    labelX,
    y + (h - Kit.textHeight("mono")) / 2,
    PAL.caption
  )
  return offset, h
end

-- ----------------------------------------------------------------- scroll
-- Mouse wheel over a list body (#595): same offset contract as Kit.pager, so
-- a list can carry both and stay on one page counter.  Three rules, all of
-- them consequences of Kit having no z-order:
--   * only the list the pointer is inside takes the notch,
--   * the notch is consumed, so two stacked lists cannot both eat it,
--   * Kit.blockClicks shields it exactly as it shields Kit.press, or the
--     panel under an open species picker would scroll through the modal.
local SCROLL_ROWS = 3

-- `step` is optional and exists for grids: a 4-column dex page must move in
-- multiples of 4 or the columns shear.  Lists leave it nil and keep the old
-- behaviour bit for bit (wheel notch = 3 rows, drag = 1 row per row height).
function Kit.scroll(x, y, w, h, offset, total, perPage, step)
  local maxOffset = math.max(0, (total or 0) - (perPage or 0))
  offset = Theme.clamp(offset or 0, 0, maxOffset)
  if Kit.blockClicks then
    return offset
  end

  -- Touch drag (#715): a phone has no wheel and the pagers are small
  -- targets, so a held pointer dragging vertically over the list body
  -- scrolls it.  The drag is keyed to the rect it started in and follows the
  -- pointer even once it leaves, like every native scroll view; the press
  -- frame itself still dispatches as a click, which is the pre-existing
  -- press-on-down contract, so a tap keeps selecting rows.
  local dragStep = math.max(1, step or 1)
  if Kit.mouseDown and maxOffset > 0 and h > 0 and (perPage or 0) > 0 then
    local key = math.floor(x) .. ":" .. math.floor(y)
    local d = Kit._drag
    if not d and Kit.hit(x, y, w, h) then
      Kit._drag = { key = key, startY = Kit.mouseY, base = offset }
    elseif d and d.key == key then
      local visRows = math.max(1, math.floor(perPage / dragStep))
      local rowPx = math.max(1, h / visRows)
      local moved = math.floor((d.startY - Kit.mouseY) / rowPx + 0.5) * dragStep
      offset = Theme.clamp(d.base + moved, 0, maxOffset)
    end
  end

  if (Kit.wheelY or 0) == 0 then
    return offset
  end
  if not Kit.hit(x, y, w, h) then
    return offset
  end
  -- LOVE reports wheel-up as positive y; up moves the window toward the top
  -- of the list, which is a smaller offset.
  local rows = step or math.max(1, math.min(SCROLL_ROWS, perPage or SCROLL_ROWS))
  local notch = (Kit.wheelY > 0) and -rows or rows
  Kit.wheelY = 0
  return Theme.clamp(offset + notch, 0, maxOffset)
end

-- Pixel-unit sibling of Kit.scroll for a whole stacked card column (#715
-- reflow): `offset` is a pixel offset into `contentH` pixels of laid-out
-- content shown through an `h`-pixel viewport.  Same three rules as
-- Kit.scroll (pointer-inside only, notch consumed, shielded by
-- Kit.blockClicks), same drag contract (a tap still dispatches as a click).
-- Call it AFTER the content so any inner Kit.scroll list gets first claim on
-- a wheel notch or drag that lands over it.
function Kit.scrollPixels(x, y, w, h, offset, contentH)
  local maxOffset = math.max(0, (contentH or 0) - math.max(0, h))
  offset = Theme.clamp(offset or 0, 0, maxOffset)
  if Kit.blockClicks then
    return offset
  end

  local d = Kit._pointerDrag or Kit._touchDrag
  if
    d
    and maxOffset > 0
    and h > 0
    and Kit._dragDelta ~= 0
    and d.x >= x
    and d.x <= x + w
    and d.startY >= y
    and d.startY <= y + h
  then
    offset = Theme.clamp(offset + (Kit._dragDelta or 0), 0, maxOffset)
    Kit._dragDelta = 0
  end

  if (Kit.wheelY or 0) == 0 then
    return offset
  end
  if not Kit.hit(x, y, w, h) then
    return offset
  end
  local notch = 48 * Kit.scale
  local delta = -Kit.wheelY * notch
  Kit.wheelY = 0
  return Theme.clamp(offset + delta, 0, maxOffset)
end

function Kit.dragAdd(delta)
  Kit._dragDelta = (Kit._dragDelta or 0) + delta
end

-- Lists keep the old row offset for keyboard/pager callers, but draw from a
-- pixel offset so a finger moves the content by exactly the distance travelled.
function Kit.list(S, key, x, y, w, h, total, stride, cols)
  cols = cols or 1
  S._listState = S._listState or {}
  local st = S._listState[key] or { pixels = (S[key] or 0) / cols * stride }
  S._listState[key] = st
  if st.first ~= nil and S[key] ~= st.first then
    st.pixels = (S[key] or 0) / cols * stride
  end
  if st.stride and (st.stride ~= stride or st.cols ~= cols) then
    st.pixels = (S[key] or 0) / cols * stride
  end
  st.stride, st.cols = stride, cols
  local content = math.max(0, math.ceil(total / cols) * stride)
  st.pixels = Kit.scrollPixels(x, y, w, h, st.pixels, content)
  local firstRow = math.floor(st.pixels / stride)
  local shift = st.pixels - firstRow * stride
  S[key], st.first = firstRow * cols, firstRow * cols
  st.content, st.view = content, h
  return math.min(total - S[key], math.ceil((h + shift) / stride) * cols), shift
end

function Kit.listScrollbar(S, key, x, y, w, h)
  local st = S._listState and S._listState[key]
  if st then
    Kit.scrollbar(x, y, w, h, st.pixels, st.content, st.view)
  end
end

-- Thin scrollbar in the card's right padding, clear of control faces and
-- their corner arcs. Pure indicator (the drag above and the
-- pager are the controls): on a phone the old layout looked "stuck" because
-- nothing said the list continued past the fold (#715).
function Kit.scrollbar(x, y, w, h, offset, total, perPage)
  if not G then
    return
  end
  total, perPage = total or 0, perPage or 0
  if total <= perPage or h <= 0 or perPage <= 0 then
    return
  end
  local bw = 3 * Kit.scale
  local bx = x + w + 4 * Kit.scale
  audit("scrollbar", bx, y, bw, h, "scrollbar")
  Theme.col(PAL.cardBorder, 0.22)
  G.rectangle("fill", bx, y, bw, h, bw / 2, bw / 2)
  local maxOffset = total - perPage
  local th = math.max(18 * Kit.scale, h * perPage / total)
  local ty = y + (h - th) * (Theme.clamp(offset or 0, 0, maxOffset) / maxOffset)
  Theme.col(PAL.blue, 0.55)
  G.rectangle("fill", bx, ty, bw, th, bw / 2, bw / 2)
end

-- Clip drawing to a rect (list bodies, scrolled cards).  A stack since #715:
-- a stacked panel scrolls its whole column inside one clip and the lists
-- inside it push their own, so pushes nest by intersecting with the rect
-- above and a pop restores that rect rather than clearing the scissor.  The
-- tracked rect also bounds Kit.hit, so a widget scrolled out of view is
-- inert instead of taking taps aimed at whatever is drawn where it left.
-- Under the headless stub the scissor is a no-op but the rect tracking (and
-- so the hit fencing) still runs.
local clipStack = {}

local function applyClip(rect)
  Kit._clipRect = rect
  if not (G and G.setScissor) then
    return
  end
  if not rect then
    G.setScissor()
  elseif rect.w <= 0 or rect.h <= 0 then
    -- A compact mobile viewport can leave a panel with no room for a list.
    -- LÖVE rejects negative scissor dimensions, so treat an exhausted clip
    -- region as empty instead of passing invalid geometry through to it.
    G.setScissor(0, 0, 0, 0)
  else
    G.setScissor(math.floor(rect.x), math.floor(rect.y), math.ceil(rect.w), math.ceil(rect.h))
  end
end

function Kit.pushClip(x, y, w, h)
  local prev = clipStack[#clipStack]
  local x2, y2 = x + math.max(0, w), y + math.max(0, h)
  if prev then
    x, y = math.max(x, prev.x), math.max(y, prev.y)
    x2 = math.min(x2, prev.x + prev.w)
    y2 = math.min(y2, prev.y + prev.h)
  end
  local rect = { x = x, y = y, w = math.max(0, x2 - x), h = math.max(0, y2 - y) }
  clipStack[#clipStack + 1] = rect
  applyClip(rect)
end

function Kit.popClip()
  clipStack[#clipStack] = nil
  applyClip(clipStack[#clipStack])
end

-- A pcall-ed draw that raised mid-clip must not leak the stack into later
-- frames (every hit test would stay fenced to the dead rect), so the frame
-- boundary clears it.
function Kit.resetClip()
  for i = #clipStack, 1, -1 do
    clipStack[i] = nil
  end
  applyClip(nil)
end

return Kit
