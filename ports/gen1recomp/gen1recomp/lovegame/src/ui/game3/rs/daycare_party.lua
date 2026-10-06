local M = {isMenu = true, open = false, cursor = 1}
local Stack = require("src.ui.game3.stack")
local Font = require("src.ui.game3.frlg_font")
local Window = require("src.ui.game3.window")
local RomText = require("src.core.game3.rom_text")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local function party() return require("src.ui.game3.party_menu") end
local function se() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_SELECT) end
local function textOptions() return require("src.ui.game3.rs.party_chrome").textOptions("menu") end
local function prompt(id, width)
  Window.stdFrame(Window.template(1, 17, width, 2))
  Font.draw(assert(require("src.ui.game3.rse.scene_kit").manifest("rse/party").prompts[id + 1]), 8, 136, textOptions())
end
function M.isOpen() return M.open end
function M.popup(slot)
  M.slot, M.cursor = slot, 1
  local mon = M.session.party[slot]
  M.actions = require("src.core.game3.pokemon").isEgg(mon) and {"summary", "exit"} or {"store", "summary", "exit"}
  M.open = true
  Stack.push("rs_daycare_party", M, {drawUnder = true, hideBelow = false})
end
function M.close()
  M.open = false; Stack.pop("rs_daycare_party")
end
function M.reset() M.close(); M.session, M._done = nil, nil end
function M.show(session, done)
  M.session, M._done = session, done
  M._heldSignature, M._repeatCounter = "", 40
  local picked
  party().show(session.party, nil, {session = session, mode = "choose", nativePartyLayout = 0,
    chooseCancelStart = false, choosePromptDraw = function() prompt(15, 22) end,
    onChoose = function(slot) M.popup(slot) end,
    onClose = function()
      M.close(); local cb = M._done; M._done = nil
      if cb then cb(picked or 255) end
    end})
  M._store = function(slot) picked = slot - 1; party().close() end
end
function M.handleInput(input)
  if not M.open then return end
  if not require("src.ui.game3.rs.party_chrome").inputAllowed() then return end
  -- choose_party.c:828
  local repeated = {}
  if input.isDown then
    local held, signature = {}, {}
    for _, key in ipairs({"up", "down", "left", "right", "a", "b", "start", "select", "l", "r"}) do
      if input:isDown(key) then held[key] = true; signature[#signature + 1] = key end
    end
    signature = table.concat(signature, ",")
    if signature ~= "" and signature == M._heldSignature then
      M._repeatCounter = M._repeatCounter - 1
      if M._repeatCounter == 0 then repeated, M._repeatCounter = held, 5 end
    else M._repeatCounter = 40 end
    M._heldSignature = signature
  end
  local up = repeated.up or input:wasPressed("up")
  local down = repeated.down or input:wasPressed("down")
  if up then if M.cursor > 1 then M.cursor = M.cursor - 1; se() end; return end
  if down then if M.cursor < #M.actions then M.cursor = M.cursor + 1; se() end; return end
  if input:wasPressed("b") then se(); M.close(); return end
  if not input:wasPressed("a") then return end
  se()
  local action, slot = M.actions[M.cursor], M.slot
  if action == "store" then M._store(slot)
  elseif action == "exit" then se(); M.close()
  else
    M.close()
    require("src.ui.game3.summary_menu").openMenu(M.session.party, slot, {session = M.session, context = "party",
      onClose = function(index) party().cursor = index; M.popup(index) end})
  end
end
function M.draw()
  if not M.open then return end
  local top = 20 - (#M.actions * 2 + 2)
  prompt(5, 18)
  Window.stdFrame(Window.template(21, top + 1, 8, #M.actions * 2))
  local keys = {store = "OtherText_Store", summary = "OtherText_Summary", exit = "gOtherText_Exit"}
  for i, action in ipairs(M.actions) do Font.draw(RomText.plain(keys[action]), 168, (top + 1) * 8 + (i - 1) * 16, textOptions()) end
  Cursor.draw(168, (top + 1) * 8 + (M.cursor - 1) * 16, 8 * 8)
end
return M
