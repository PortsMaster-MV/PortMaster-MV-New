-- pokemon_menu.c:454
local Bag = require("src.core.game3.bag")
local Items = require("src.core.game3.items_data")
local Text = require("src.core.game3.rom_text")
local Pokemon = require("src.core.game3.pokemon")
local M = {}

local function message(key, vars)
  return Text.box(key, {stringVars = vars or {}, maxWidth = 216})
end

function M.begin(menu, row)
  local Party = require("src.ui.game3.party_menu")
  local session, bag, index = menu._session, menu._bag, Party.cursor
  local mon = session and session.party and session.party[index]
  if not Party.open or not mon then return false end
  local id = Items.toNumericId(row.id)
  if require("src.core.game3.mail").isMailItem(id) then
    local kind, previous, prompt = require("src.core.game3.item_use").checkGive(session, id, index)
    menu._exit = {k = 0, curtain = false, cb = function()
      menu.close()
      Party.cursor = index
      if kind == "give" or kind == "switch" then
        require("src.ui.game3.rs.mail_give").begin(Party, id, previous, prompt)
      else Party.showMessage(prompt, function() Party.mode = "list" end) end
    end}
    return true
  end
  local kind, prev, prompt = require("src.core.game3.item_use").checkGive(session, id, index)
  local function done() Party.mode = "list" end
  local function show(key, vars) Party.showMessage(message(key, vars), done) end
  local function update()
    mon.item, mon.heldItem = id, id
  end
  local function give()
    if kind == "mail" or kind == "cant_hold" or kind == "noparty" then
      Party.showMessage(prompt, done)
    elseif kind == "switch" then
      Party.showMessage(prompt, function()
        Party.showYesNo(prompt, function(yes)
          if not yes then done() return end
          if not Bag.remove(bag, id, 1) then done() return end
          if Bag.add(bag, prev, 1) then
            update()
            show("gOtherText_TakenAndReplaced", {Items.displayName(id), Items.displayName(prev)})
          else
            Bag.add(bag, id, 1)
            show("gOtherText_BagFullCannotRemoveItem")
          end
        end)
      end)
    elseif kind == "give" then
      if not Bag.remove(bag, id, 1) then done() return end
      update()
      show("gOtherText_WasGivenToHold", {Pokemon.displayMonName(mon), Items.displayName(id)})
    end
  end
  menu._exit = {k = 0, curtain = false, cb = function()
    menu.close()
    Party.cursor = index
    give()
  end}
  return true
end

return M
