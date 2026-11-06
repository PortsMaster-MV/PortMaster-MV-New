-- Launcher-style navigation: one dropdown opens a modal list over the page.
-- The overlay owns clicks, scrolling and dismissal until an option is chosen.
local Theme = require("Theme")
local SafeArea = require("src.core.SafeArea")
local Motion = require("Motion")
local Kit = require("Kit")
local PAL = Theme.PAL
local Chooser = {}

local function id(option)
  return option.id or option[1]
end

local function label(option)
  local text = option.label or option[2]
  return (option.errors or 0) > 0 and (text .. " (" .. option.errors .. ")") or text
end

function Chooser.close(S)
  S.navPopup = nil
  Kit.blur()
  Kit._drag = nil
  Kit.mouseClicked, Kit.wheelY = false, 0
end

function Chooser.open(S, key, title, options, after)
  if Motion.active() then
    return false
  end
  local index = 1
  for i, option in ipairs(options) do
    if id(option) == S[key] then
      index = i
    end
  end
  Kit.blur()
  Kit._drag = nil
  S.navPopup = {
    key = key,
    title = title,
    options = options,
    index = index,
    scroll = 0,
    reveal = true,
    opened = true,
    after = after,
  }
  Kit.blockClicks = true
  return true
end

function Chooser.navigation(S, kit, key, title, options, x, y, w, h, after)
  local current = options[1]
  for _, option in ipairs(options) do
    if id(option) == S[key] then
      current = option
    end
  end
  local text = label(current)
  local icon = current.icon or kit.navigationIcon(text)
  -- Compact toolbars keep a readable current label beside the dropdown icon.
  if w < 160 * kit.scale then
    icon = nil
  end
  if
    kit.button(x, y, w, h, text, {
      id = "navigate-" .. key,
      invalid = (current.errors or 0) > 0,
      face = "invert",
      font = "small",
      icon = icon,
      align = "left",
      trailingIcon = S.navPopup and S.navPopup.key == key and "chevron-up" or "chevron-down",
    })
  then
    return Chooser.open(S, key, title, options, after)
  end
  return false
end

function Chooser.actions(S, kit, key, title, options, x, y, w, h)
  if
    kit.button(x, y, w, h, title, {
      id = "navigate-" .. key,
      face = "invert",
      font = "small",
      icon = "sliders-horizontal",
      trailingIcon = "chevron-down",
    })
  then
    if Chooser.open(S, key, title, options) then
      S.navPopup.mode = "actions"
      return true
    end
  end
  return false
end

local function active(S, popup, option)
  if popup.mode == "actions" then
    return option.active == true
  end
  return S[popup.key] == id(option)
end

local function choose(S, index)
  local popup = S.navPopup
  if not popup then
    return
  end
  local option = popup.options[index]
  if not option then
    return
  end
  if popup.mode == "actions" then
    Chooser.close(S)
    option.fn(S)
    return
  end
  local value, previous = id(option), S[popup.key]
  local oldIndex = 1
  for i, entry in ipairs(popup.options) do
    if id(entry) == previous then
      oldIndex = i
    end
  end
  Chooser.close(S)
  if Motion.change(S, popup.key, value, index >= oldIndex and 1 or -1) and popup.after then
    popup.after(value, index)
  end
end

function Chooser.keypressed(S, key)
  local popup = S.navPopup
  if not popup then
    return false
  end
  if key == "escape" then
    Chooser.close(S)
  elseif key == "return" or key == "kpenter" then
    choose(S, popup.index)
  elseif key == "up" or key == "down" or key == "home" or key == "end" then
    if key == "home" then
      popup.index = 1
    elseif key == "end" then
      popup.index = #popup.options
    else
      popup.index = (popup.index - 1 + (key == "up" and -1 or 1)) % #popup.options + 1
    end
    popup.reveal = true
    popup.keyboard = true
  end
  return true
end

function Chooser.draw(S, kit, width, height)
  local popup = S.navPopup
  if not popup then
    return
  end
  kit.resetClip()
  kit.blockClicks = popup.opened == true
  popup.opened = nil
  local s, row, gap = kit.scale, math.ceil(kit.controlH()), math.floor(8 * kit.scale)
  local ox, oy, sw, sh = SafeArea.rect()
  local gutter, pad = math.max(8, math.floor(12 * s)), math.floor(14 * s)
  local w = math.floor(math.min(360 * s, sw - 2 * gutter))
  local listH = #popup.options * (row + gap) - gap
  local h = math.min(sh - 2 * gutter, 2 * pad + row + gap + listH)
  local x, y = math.floor(ox + (sw - w) / 2), math.floor(oy + (sh - h) / 2)
  popup.rect = { x = x, y = y, w = w, h = h }
  Theme.col(PAL.bg, 0.72)
  love.graphics.rectangle("fill", 0, 0, width, height)
  if kit.press(0, 0, width, height) and not kit.hit(x, y, w, h) then
    Chooser.close(S)
    return
  end
  kit.card(x, y, w, h)
  local cx, cy, inner = x + pad, y + pad, w - 2 * pad
  kit.text(
    "button",
    kit.ellipsize("button", popup.title, inner - row - gap),
    cx,
    cy + (row - kit.textHeight("button")) / 2,
    PAL.heading
  )
  if kit.iconButton(cx + inner - row, cy, row, row, "x", "Close chooser") then
    Chooser.close(S)
    return
  end
  cy = cy + row + gap
  local bodyH = math.max(0, h - 2 * pad - row - gap)
  local extent = math.max(0, listH - bodyH)
  if popup.reveal then
    local top = (popup.index - 1) * (row + gap)
    popup.scroll = Theme.clamp(math.max(top + row - bodyH, math.min(popup.scroll, top)), 0, extent)
    popup.reveal = nil
  end
  popup.scroll = kit.scrollPixels(cx, cy, inner, bodyH, popup.scroll, listH)
  local contentW = inner - (extent > 0 and 8 * s or 0)
  kit.pushClip(cx, cy, inner, bodyH)
  for i, option in ipairs(popup.options) do
    local text = label(option)
    if
      kit.button(cx, cy + (i - 1) * (row + gap) - popup.scroll, contentW, row, text, {
        face = "selection",
        invalid = (option.errors or 0) > 0,
        active = active(S, popup, option),
        font = "small",
        align = "left",
        icon = option.icon or kit.navigationIcon(text),
        trailingIcon = active(S, popup, option) and "check" or nil,
        ring = popup.keyboard and popup.index == i or nil,
      })
    then
      kit.popClip()
      choose(S, i)
      return
    end
  end
  kit.popClip()
  kit.scrollbar(cx, cy, inner, bodyH, popup.scroll, listH, bodyH)
end

return Chooser
