local M = { ID = "rs_contest_party", isMenu = true }
local Stack = require("src.ui.game3.stack")
local Fade = require("src.ui.game3.fade")
local Pal = require("src.core.game3.pal_fade")
local function party() return require("src.ui.game3.party_menu") end

function M.reset()
  local host = M.active
  M.active = nil
  if host then
    host.done = nil
    if party()._onClose == host.onPartyClose then party()._onClose = nil; party().close() end
    Stack.pop(M.ID)
  end
end

function M.show(session, category, rank, done)
  M.reset()
  local host = { session = session, done = done, picked = 255, phase = "field_out",
    isMenu = true, signature = "", repeatCounter = 40 }
  M.active = host
  local function live() return M.active == host end
  local function finish()
    if not live() then return end
    M.active = nil
    local cb = host.done; host.done = nil
    if cb then cb(host.picked) end
  end
  host.onPartyClose = function()
    if not live() then return end
    Stack.pop(M.ID)
    host.phase = "field_in"
    Fade.begin(Fade.MODE.FROM_BLACK, 1, finish)
  end
  local function select(slot)
    host.picked, host.phase = slot or 255, "party_out"
    host.pal = Pal.new()
    host.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_SELECT)
  end
  function host.handleInput(input)
    if not live() or host.phase ~= "select" then return end
    if not require("src.ui.game3.rs.party_chrome").inputAllowed() then return end
    local pressed, held, signature = {}, {}, {}
    local keys = {"up", "down", "left", "right", "a", "b", "start", "select", "l", "r"}
    for _, key in ipairs(keys) do
      if input:wasPressed(key) then pressed[key] = true end
      if input.isDown and input:isDown(key) then held[key] = true; signature[#signature + 1] = key end
    end
    signature = table.concat(signature, ",")
    local repeated = pressed
    if signature ~= "" and signature == host.signature then
      host.repeatCounter = host.repeatCounter - 1
      if host.repeatCounter == 0 then repeated, host.repeatCounter = held, 5 end
    else host.repeatCounter = 40 end
    host.signature = signature
    local count, direction = 0
    for key in pairs(repeated) do count, direction = count + 1, key end
    if count == 1 and (direction == "up" or direction == "down" or direction == "left" or direction == "right") then
      party().handleInput({wasPressed = function(_, key) return key == direction end})
      return
    end
    if pressed.a and not pressed.b then
      select(party().cursor == 7 and 255 or party().cursor - 1)
    elseif pressed.b and not pressed.a then select(255) end
  end
  function host.update(dt)
    if not live() then return end
    party().update(dt)
    if host.phase == "party_out" then
      host.pal:updateFade()
      if not host.pal:fadeActive() then party().close() end
    end
  end
  function host.draw()
    if not live() then return end
    party().draw()
    if host.pal then require("src.ui.game3.rse.scene_kit").drawFade(host.pal) end
  end
  local function open()
    if not live() then return end
    Fade.clear()
    party().show(session.party, nil, { session = session, mode = "choose", nativePartyLayout = 0,
      chooseCancelStart = false,
      minigameEligible = function(_, mon)
        local code = require("src.core.game3.rse.contest_util").eligibility(mon, category, rank)
        return code == 1 or code == 2
      end,
      onClose = host.onPartyClose })
    host.phase = "select"
    Stack.push(M.ID, host, { hideBelow = true, fullscreen = true })
  end
  if not Fade.isActive() and Fade.mode == Fade.MODE.TO_BLACK and (Fade.t or 0) >= 16 then open()
  else Fade.begin(Fade.MODE.TO_BLACK, 1, open) end
  return host
end

return M
