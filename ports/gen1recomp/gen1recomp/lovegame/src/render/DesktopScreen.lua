-- Cross-platform desktop secondary display.  LOVE owns one window, so a
-- second minimal instance of this same app owns the companion window.  ENet
-- is bundled with LOVE; binding it to loopback keeps frames and input local.

local Platform = require("src.core.Platform")
local HostShell = require("src.core.HostShell")
local okEnet, enet = pcall(require, "enet")

local DesktopScreen = {}
local state = {
  enabled = false, blocked = false, host = nil, peer = nil,
  token = nil, port = nil, touches = {}, retryAt = 0, heartbeatAt = 0,
}

local function now()
  return love and love.timer and love.timer.getTime and love.timer.getTime()
    or os.clock()
end

local function destroy(sendQuit)
  if state.peer and sendQuit then
    pcall(state.peer.send, state.peer, "Q" .. state.token, 1, "reliable")
  end
  if state.peer then pcall(state.peer.disconnect_now, state.peer) end
  if state.host then pcall(state.host.destroy, state.host) end
  state.host, state.peer, state.token, state.port = nil, nil, nil, nil
  state.touches = {}
end

local function token()
  local seed = table.concat({ tostring(os.time()), tostring(now()), tostring({}) }, ":")
  local digest = love.data.hash("sha256", seed)
  return love.data.encode("string", "hex", digest):sub(1, 24)
end

local function start()
  if state.host or state.blocked or now() < state.retryAt then
    return state.host ~= nil
  end
  local base = 49152 + math.floor(now() * 1000) % 12000
  for attempt = 0, 31 do
    local port = 49152 + (base - 49152 + attempt * 37) % 12000
    local ok, host = pcall(enet.host_create,
      ("127.0.0.1:%d"):format(port), 1, 2)
    if ok and host then
      state.host, state.port, state.token = host, port, token()
      local launched = HostShell.spawnSelfDetached({
        ("--display-companion=%d,%s"):format(port, state.token),
      })
      if launched then return true end
      destroy(false)
      break
    end
  end
  state.retryAt = now() + 1
  return false
end

local function service()
  if not state.enabled or state.blocked then return end
  if not state.host and not start() then return end
  while state.host do
    local ok, event = pcall(state.host.service, state.host, 0)
    if not ok then
      destroy(false)
      state.retryAt = now() + 1
      return
    end
    if not event then break end
    if event.type == "receive" then
      local data = event.data or ""
      if data == "H" .. state.token then
        state.peer = event.peer
      elseif event.peer == state.peer
          and data:sub(1, #state.token + 2) == "I" .. state.token .. "\n" then
        state.touches[#state.touches + 1] = data:sub(#state.token + 3)
      elseif event.peer == state.peer and data == "C" .. state.token then
        state.blocked = true
        destroy(false)
        return
      end
    elseif event.type == "disconnect" and event.peer == state.peer then
      destroy(false)
      state.retryAt = now() + 1
      return
    end
  end
  if state.peer and now() >= state.heartbeatAt then
    state.heartbeatAt = now() + 1
    pcall(state.peer.send, state.peer, "P" .. state.token, 1, "unreliable")
  end
end

function DesktopScreen.usable()
  return okEnet and enet ~= nil and Platform.canSpawnProcess()
end

function DesktopScreen.available()
  return DesktopScreen.detected()
end

function DesktopScreen.detected()
  service()
  return state.peer ~= nil
end

function DesktopScreen.push(imageData, w, h, background, preference)
  service()
  if not state.peer or not imageData or not imageData.getString then return false end
  w, h = tonumber(w), tonumber(h)
  if not w or not h or w < 1 or h < 1 or w > 4096 or h > 4096 then return false end
  local ok, raw = pcall(imageData.getString, imageData)
  if not ok or type(raw) ~= "string" or #raw ~= w * h * 4 then return false end
  local packed = love.data.compress("string", "lz4", raw, 1)
  local header = ("F%s\n%d,%d,%u,%s\n"):format(state.token, w, h,
    tonumber(background) or 0, tostring(preference or "auto"):gsub("[^%w_:.-]", ""))
  local sent = pcall(state.peer.send, state.peer, header .. packed, 0, "reliable")
  return sent
end

function DesktopScreen.pollTouch()
  service()
  return table.remove(state.touches, 1)
end

function DesktopScreen.setEnabled(on)
  on = on == true
  if on == state.enabled then
    if on then service() end
    return
  end
  state.enabled = on
  state.blocked = false
  if on then start(); service() else destroy(true) end
end

return DesktopScreen
