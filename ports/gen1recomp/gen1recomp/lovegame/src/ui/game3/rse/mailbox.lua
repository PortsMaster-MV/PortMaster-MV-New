local Stack = require("src.ui.game3.stack")
local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Mail = require("src.core.game3.mail")

local Mailbox = { isMenu = true }

Mailbox.open = false

-- pokeemerald/src/menu_specialized.c:43
local WIN = {
  title = Window.template(1, 1, 8, 2),
  list = Window.template(21, 1, 8, 18),
  options = Window.template(1, 1, 11, 8),
}
Mailbox.WIN = WIN
-- pokeemerald/src/menu_specialized.c:278
local MAX_SHOWED, UP_TEXT_Y, ITEM_X = 8, 9, 8

local function se(name)
  local SE = require("src.core.game3.se_ids")
  pcall(function() require("src.core.game3.audio").playSe(SE[name]) end)
end

local function pool()
  return Mail.pool(Mailbox._session) or {}
end

-- pokeemerald/src/player_pc.c:669
local function compact()
  local p = pool()
  for i = Mail.PARTY_SIZE + 1, Mail.MAIL_COUNT - 1 do
    for j = i + 1, Mail.MAIL_COUNT do
      if Mail.isEmpty(p[i]) then p[i], p[j] = p[j], p[i] end
    end
  end
end
Mailbox.compact = compact

local function count()
  local p, n = pool(), 0
  for i = Mail.PARTY_SIZE + 1, Mail.MAIL_COUNT do
    if not Mail.isEmpty(p[i]) then n = n + 1 end
  end
  return n
end
Mailbox.count = count

local function page_items()
  local n = count()
  return n > 7 and 8 or n + 1
end

local function pos()
  return Mailbox.scroll + Mailbox.row
end

local function selected_mail()
  return pool()[Mail.PARTY_SIZE + pos() + 1]
end
Mailbox.selectedMail = selected_mail

local function clamp()
  local total, shown = count() + 1, page_items()
  if Mailbox.scroll ~= 0 and Mailbox.scroll + shown > total then Mailbox.scroll = total - shown end
  if Mailbox.scroll < 0 then Mailbox.scroll = 0 end
  if Mailbox.scroll + Mailbox.row >= total then Mailbox.row = total - 1 - Mailbox.scroll end
  if Mailbox.row < 0 then Mailbox.row = 0 end
end

local function status(key, vars)
  Mailbox._status = key and RomText.plain(key, { stringVars = vars }) or nil
end

function Mailbox.show(opts)
  opts = opts or {}
  Mailbox.open = true
  Mailbox._session = opts.session
  Mailbox._onClose = opts.onClose
  Mailbox.scroll, Mailbox.row = 0, 0
  Mailbox.state = "list"
  Mailbox.optCursor = 1
  compact()
  clamp()
  status(nil)
  Stack.push("rse_mailbox", Mailbox, { hideBelow = false })
end

function Mailbox.isOpen()
  return Mailbox.open
end

function Mailbox.close()
  if not Mailbox.open then return end
  Mailbox.open = false
  Stack.pop("rse_mailbox")
  local cb = Mailbox._onClose
  Mailbox._onClose = nil
  if cb then cb() end
end

function Mailbox.reset()
  Mailbox.open = false
  Mailbox._onClose = nil
  Stack.pop("rse_mailbox")
end

-- pokeemerald/src/list_menu.c:438
local function step(down)
  local n, shown = count() + 1, page_items()
  local row, scroll = Mailbox.row, Mailbox.scroll
  if not down then
    local newRow = shown == 1 and 0 or (shown - (math.floor(shown / 2) + shown % 2) - 1)
    if scroll == 0 then
      if row == 0 then return false end
      Mailbox.row = row - 1
    elseif row > newRow then
      Mailbox.row = row - 1
    else
      Mailbox.row, Mailbox.scroll = newRow, scroll - 1
    end
  else
    local newRow = shown == 1 and 0 or (math.floor(shown / 2) + shown % 2)
    if scroll == n - shown then
      if row >= shown - 1 then return false end
      Mailbox.row = row + 1
    elseif row < newRow then
      Mailbox.row = row + 1
    else
      Mailbox.row, Mailbox.scroll = newRow, scroll + 1
    end
  end
  return true
end

local function back_to_list()
  Mailbox.state = "list"
  status(nil)
  clamp()
end

local function sender(mail)
  return tostring(mail and mail.playerName or "")
end

-- pokeemerald/src/player_pc.c:844
local function read_mail()
  local mail = selected_mail()
  Mailbox.state = "reading"
  local reader = require("src.ui.game3.rs.player_pc_policy").matches(Mailbox._session)
    and "src.ui.game3.rs.mail_reader" or "src.ui.game3.rse.mail"
  require(reader).read(mail, {
    session = Mailbox._session,
    onClose = function() back_to_list() end,
  })
end

-- pokeemerald/src/player_pc.c:895
local function move_to_bag()
  local mail = selected_mail()
  local Bag = require("src.core.game3.bag")
  local bag = Mailbox._session and Mailbox._session.bag
  if not (bag and Bag.canAdd(bag, mail.itemId, 1) and Bag.add(bag, mail.itemId, 1)) then
    status("gText_BagIsFull")
  else
    status("gText_MailToBagMessageErased")
    Mail.clear(mail)
    compact()
    clamp()
  end
  Mailbox.state = "message"
end

-- pokeemerald/src/player_pc.c:923
local function give()
  local party = Mailbox._session and Mailbox._session.party or {}
  if #party == 0 then
    status("gText_NoPokemon")
    Mailbox.state = "message"
    return
  end
  Mailbox.state = "party"
  local mail = selected_mail()
  local ok, PartyMenu = pcall(require, "src.ui.game3.party_menu")
  if not (ok and PartyMenu and PartyMenu.show) then
    back_to_list()
    return
  end
  PartyMenu.show({
    session = Mailbox._session,
    mode = "choose",
    onSelect = function(idx)
      local mon = idx and party[idx]
      if mon and (tonumber(mon.item or mon.heldItem) or 0) == 0 then
        -- pokeemerald/src/party_menu.c:5061
        if Mail.giveMailToMon2(Mailbox._session, mon, Mail.copy(mail)) ~= Mail.MAIL_NONE then
          Mail.clear(mail)
          compact()
        end
      end
      PartyMenu.close()
    end,
    onClose = function()
      if count() == 0 then Mailbox.close() else back_to_list() end
    end,
  })
end

local OPTIONS = { read_mail, function() status("gText_MessageWillBeLost") Mailbox.state = "confirm_msg" end, give,
  function() back_to_list() end }

function Mailbox.handleInput(input)
  if not Mailbox.open or not input then return end
  local st = Mailbox.state
  if st == "list" then
    if input:wasPressed("up") then
      if step(false) then se("SE_SELECT") end
    elseif input:wasPressed("down") then
      if step(true) then se("SE_SELECT") end
    elseif input:wasPressed("a") then
      se("SE_SELECT")
      if pos() >= count() then
        Mailbox.close()
      else
        -- pokeemerald/src/player_pc.c:768
        status("gText_WhatToDoWithVar1sMail", { sender(selected_mail()) })
        Mailbox.optCursor = 1
        Mailbox.state = "options"
      end
    elseif input:wasPressed("b") then
      se("SE_SELECT")
      Mailbox.close()
    end
  elseif st == "options" then
    -- pokeemerald/src/player_pc.c:806
    if input:wasPressed("up") and Mailbox.optCursor > 1 then
      Mailbox.optCursor = Mailbox.optCursor - 1
      se("SE_SELECT")
    elseif input:wasPressed("down") and Mailbox.optCursor < #OPTIONS then
      Mailbox.optCursor = Mailbox.optCursor + 1
      se("SE_SELECT")
    elseif input:wasPressed("a") then
      se("SE_SELECT")
      OPTIONS[Mailbox.optCursor]()
    elseif input:wasPressed("b") then
      se("SE_SELECT")
      back_to_list()
    end
  elseif st == "confirm_msg" then
    if input:wasPressed("a") or input:wasPressed("b") then
      Mailbox.yesCursor = 1
      Mailbox.state = "confirm"
    end
  elseif st == "confirm" then
    -- pokeemerald/src/player_pc.c:877
    if input:wasPressed("up") and Mailbox.yesCursor ~= 1 then
      Mailbox.yesCursor = 1
      se("SE_SELECT")
    elseif input:wasPressed("down") and Mailbox.yesCursor ~= 2 then
      Mailbox.yesCursor = 2
      se("SE_SELECT")
    elseif input:wasPressed("a") then
      se("SE_SELECT")
      if Mailbox.yesCursor == 1 then move_to_bag() else back_to_list() end
    elseif input:wasPressed("b") then
      se("SE_SELECT")
      back_to_list()
    end
  elseif st == "message" then
    if input:wasPressed("a") or input:wasPressed("b") then
      if count() == 0 then
        Mailbox.close()
      else
        back_to_list()
      end
    end
  end
end

local function frame(tpl)
  Window.stdFrame(tpl)
  Window.fill(tpl, 1, 1, 1, 1)
end

local function draw_status()
  if not Mailbox._status then return end
  Window.dialogueFrame()
  local y = 15 * 8 + 1
  for line in Mailbox._status:gmatch("[^\n]+") do
    Window.printPx(line, 16, y)
    y = y + FrlgFont.linePitch()
  end
end

function Mailbox.draw()
  if not Mailbox.open then return end
  local st = Mailbox.state
  if st == "reading" or st == "party" then return end
  if st == "list" then
    local t = WIN.title
    frame(t)
    local title = RomText.plain("gText_Mailbox")
    -- pokeemerald/src/player_pc.c:715
    Window.printPx(title, t.left * 8 + math.floor((0x40 - FrlgFont.measure(title)) / 2), t.top * 8 + 1)
    local l = WIN.list
    frame(l)
    local ox, oy = l.left * 8, l.top * 8
    local pitch = Window.optionHeight()
    local shown = page_items()
    local p = pool()
    for i = 0, shown - 1 do
      local idx = Mailbox.scroll + i
      local y = oy + UP_TEXT_Y + i * pitch
      if idx >= count() then
        Window.printPx(RomText.plain("gText_Cancel2"), ox + ITEM_X, y)
      else
        -- pokeemerald/src/menu_specialized.c:257
        Window.printPx(sender(p[Mail.PARTY_SIZE + idx + 1]), ox + ITEM_X, y)
      end
    end
    Window.cursorPx(ox, oy + UP_TEXT_Y + Mailbox.row * pitch)
    return
  end
  if st == "options" then
    local o = WIN.options
    frame(o)
    local pitch = Window.optionHeight()
    for i = 1, #OPTIONS do
      local y = o.top * 8 + 1 + (i - 1) * pitch
      local rsLabels = {"OtherText_Read", "gOtherText_MoveToBag", "OtherText_Give", "gOtherText_CancelNoTerminator"}
      local key = require("src.ui.game3.rs.player_pc_policy").matches(Mailbox._session) and rsLabels[i]
        or RomText.key("gMailboxMailOptions", i - 1)
      Window.printPx(RomText.plain(key), o.left * 8 + 8, y)
      if i == Mailbox.optCursor then Window.cursorPx(o.left * 8, y) end
    end
  elseif st == "confirm" then
    local yn = Window.template(21, 9, 5, 4)
    frame(yn)
    local pitch = Window.optionHeight()
    Window.printPx(RomText.plain("gText_Yes"), yn.left * 8 + 8, yn.top * 8 + 1)
    Window.printPx(RomText.plain("gText_No"), yn.left * 8 + 8, yn.top * 8 + 1 + pitch)
    Window.cursorPx(yn.left * 8, yn.top * 8 + 1 + (Mailbox.yesCursor - 1) * pitch)
  end
  draw_status()
end

return Mailbox
