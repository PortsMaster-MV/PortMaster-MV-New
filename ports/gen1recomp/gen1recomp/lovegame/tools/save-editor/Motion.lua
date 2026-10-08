-- Save-editor navigation uses the launcher's timing, easing and preferences.
local Transition = require("src.ui.kit.Transition")
local Kit = require("Kit")
local Motion = {}

function Motion.reset()
  Transition.clear("tabs")
  Transition.clear("online")
end

function Motion.update()
  Transition.update()
end

function Motion.active()
  return Transition.active("tabs") or Transition.active("online")
end

function Motion.change(S, key, value, dir)
  if S[key] == value or Motion.active() then
    return false
  end
  local layer = key == "tab" and "tabs" or "online"
  local old = S[key]
  local fromScroll = key == "monSection" and S.inspectorScroll or nil
  S[key] = value
  Kit.blur()
  require("Ops").disarm(S)
  Transition.armed = Transition.armed or Transition.now() > 0
  Transition.start(layer, "tab", { from = old, to = value, dir = dir or 1, fromAt = fromScroll })
  S._motionKeys = S._motionKeys or {}
  S._motionKeys[layer] = key
  if key == "monSection" then
    S.inspectorScroll = 0
    S.propertyChoice = nil
  end
  -- A navigation tap must never also activate the newly revealed page.
  Kit.blockClicks = Motion.active() or Kit.blockClicks
  return true
end

function Motion.pages(S, Kit, key, x, y, w, h, draw)
  local layer = key == "tab" and "tabs" or "online"
  local tr = Transition.get(layer)
  if not tr or not S._motionKeys or S._motionKeys[layer] ~= key then
    return draw(S, Kit, x, y, w, h)
  end
  local current, scroll = S[key], S.inspectorScroll
  Kit.pushClip(x, y, w, h)
  local ok, err = xpcall(function()
    local dir = tr.dir >= 0 and 1 or -1
    S[key] = tr.from
    if key == "monSection" then
      S.inspectorScroll = tr.fromAt or 0
    end
    draw(S, Kit, x - dir * tr.p * w, y, w, h)
    S[key], S.inspectorScroll = current, scroll
    draw(S, Kit, x + dir * (1 - tr.p) * w, y, w, h)
  end, debug.traceback)
  S[key] = current
  Kit.popClip()
  if not ok then
    S.inspectorScroll = scroll
    error(err, 0)
  end
end
return Motion
