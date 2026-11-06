local Write = require("src.core.game3.profiles.rs.mail_write")
local Mail = require("src.core.game3.mail")
local Items = require("src.core.game3.items_data")
local Text = require("src.core.game3.rom_text")
local Pokemon = require("src.core.game3.pokemon")
local M = {}
local function text(key, vars) return Text.box(key, {stringVars = vars or {}, maxWidth = 216}) end

function M.begin(ui, item, previous, prompt, source)
  item = Items.toNumericId(item) or tonumber(item)
  if not Mail.isMailItem(item) then return false end
  local session, bag, index = ui._session, ui._bag, ui.cursor
  local fromBagSelection = ui.mode == "give"
  local function done()
    if fromBagSelection then ui.close() else ui.mode = "list" end
  end
  local function write()
    local tx, reason = Write.give(session, bag, item, index, source)
    if not tx then
      if reason == "bag_full" then ui.showMessage(text("gOtherText_BagFullCannotRemoveItem"), done)
      else done() end
      return
    end
    local function open()
      ui.mode = "mail_write"
      require("src.ui.game3.rs.mail_composer").write(tx.record, {session = session, onClose = function(accepted, words)
        if not accepted then Write.cancel(tx); done(); return end
        Write.accept(tx, words)
        ui.showMessage(text("gOtherText_WasGivenToHold", {Pokemon.displayMonName(tx.mon), Items.displayName(item)}), done)
      end})
    end
    if tx.previous ~= 0 then
      ui.showMessage(text("gOtherText_ReceivedTheThingFrom", {Pokemon.displayMonName(tx.mon), Items.displayName(tx.previous)}), open)
    else open() end
  end
  if previous and previous ~= 0 then
    ui.showMessage(prompt, function() ui.showYesNo(prompt, function(yes) if yes then write() else done() end end) end)
  else write() end
  return true
end
return M
