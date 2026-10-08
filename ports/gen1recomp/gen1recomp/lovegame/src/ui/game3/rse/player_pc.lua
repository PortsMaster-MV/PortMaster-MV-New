local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Storage = require("src.core.game3.storage")

local RsPolicy = require("src.ui.game3.rs.player_pc_policy")
local PlayerPc = {}

-- pokeemerald/src/player_pc.c:195
local TOP_ROWS = {
  item_storage = "gText_ItemStorage",
  mailbox = "gText_Mailbox",
  decoration = "gText_Decoration",
  turn_off = "gText_TurnOff",
}
-- pokeemerald/src/player_pc.c:200
local BEDROOM_ORDER = { "item_storage", "mailbox", "decoration", "turn_off" }
-- pokeemerald/src/player_pc.c:209
local PLAYER_ORDER = { "item_storage", "mailbox", "turn_off" }

-- pokeemerald/src/player_pc.c:215
local STORAGE_ROWS = {
  { id = "withdraw", label = "gText_WithdrawItem" },
  { id = "deposit", label = "gText_DepositItem" },
  { id = "toss", label = "gText_TossItem" },
  { id = "exit", label = "gText_Cancel" },
}

-- pokeemerald/include/constants/global.h:128
local PARTY_SIZE = 6

local function se(name)
  local SE = require("src.core.game3.se_ids")
  pcall(function() require("src.core.game3.audio").playSe(SE[name]) end)
end
PlayerPc.se = se

local function session(pc)
  return pc._session
end

local function script_store(sess)
  local Space = package.loaded["src.core.game3.scripting.space"]
  return (Space and Space.store) or (sess and sess.store) or sess
end

local function flag(sess, name)
  local Flags = require("src.core.game3.scripting.flags")
  local T = Flags.forVersion(require("src.core.game3.profile").forSession(sess).id)
  local id = assert(T.IDS[name], "unknown flag " .. name)
  return Flags.getFlag(script_store(sess), nil, id) == true
end
PlayerPc.flag = flag

local function player_name(sess)
  return sess and (sess.name or sess.playerName) or nil
end

-- pokeemerald/src/script_menu.c:328
function PlayerPc.rootEntries(pc)
  local sess = session(pc)
  local clear = flag(sess, "FLAG_SYS_GAME_CLEAR")
  local lanette = flag(sess, "FLAG_SYS_PC_LANETTE")
  local key = tostring(clear) .. tostring(lanette) .. tostring(player_name(sess))
  if pc._rseRootKey ~= key or not pc._rseRootRows then
    pc._rseRootKey = key
    local rows = {
      { id = "storage", label = RomText.plain(lanette and "gText_LanettesPC" or "gText_SomeonesPC") },
      { id = "player", label = RomText.plain("gText_PlayersPC", { playerName = player_name(sess) }) },
    }
    if clear then rows[#rows + 1] = { id = "hall", label = RomText.plain("gText_HallOfFame") } end
    rows[#rows + 1] = { id = "quit", label = RomText.plain("gText_LogOff") }
    pc._rseRootRows = rows
  end
  return pc._rseRootRows
end

function PlayerPc.topOrder(pc)
  return pc._bedroom and BEDROOM_ORDER or PLAYER_ORDER
end

-- pokeemerald/src/player_pc.c:373
function PlayerPc.enter(pc, opts)
  pc._bedroom = opts and opts.bedroom == true
  pc.mode = "player_pc"
  pc.cursor = 1
  pc._status = RomText.plain("gText_WhatWouldYouLike")
end

local function reshow(pc)
  PlayerPc.enter(pc, { bedroom = pc._bedroom })
end
PlayerPc.reshow = reshow

local function storage_desc(pc, i)
  local name = RsPolicy.matches(session(pc)) and RsPolicy.storageDescriptions or "sItemStorage_OptionDescriptions"
  return RomText.plain(RomText.key(name, i - 1))
end

-- pokeemerald/src/player_pc.c:494
local function open_item_storage(pc, cursor)
  pc.mode = "item_storage"
  pc.cursor = cursor
  pc._status = storage_desc(pc, cursor)
end
PlayerPc.openItemStorage = open_item_storage

local function msg(pc, key, after)
  pc._status = RomText.plain(key)
  pc._rseAfterMsg = after
  pc.mode = "rse_msg"
end

local function mail_in_pc(sess)
  local Mail = require("src.core.game3.mail")
  local pool = Mail.pool(sess) or {}
  local n = 0
  for i = PARTY_SIZE + 1, Mail.MAIL_COUNT do
    if not Mail.isEmpty(pool[i]) then n = n + 1 end
  end
  return n
end
PlayerPc.mailInPc = mail_in_pc

local function turn_off(pc)
  -- pokeemerald/src/player_pc.c:478
  pc.close("turn_off")
end

local function choose_top(pc, id)
  local sess = session(pc)
  if id == "item_storage" then
    -- pokeemerald/src/player_pc.c:451
    open_item_storage(pc, 1)
  elseif id == "mailbox" then
    -- pokeemerald/src/player_pc.c:457
    if mail_in_pc(sess) == 0 then
      msg(pc, "gText_NoMailHere", function() reshow(pc) end)
    else
      pc.mode = "rse_child"
      require("src.ui.game3.rse.mailbox").show({
        session = sess,
        onClose = function() reshow(pc) end,
      })
    end
  elseif id == "decoration" then
    -- pokeemerald/src/player_pc.c:483
    local Rse = require("src.core.game3.rse.init")
    local impl = Rse.system("decorationMenu", "DoPlayerRoomDecorationMenu")
    if impl and impl.open then
      pc.mode = "rse_child"
      impl.open({ session = sess, onClose = function() reshow(pc) end })
    end
  else
    turn_off(pc)
  end
end

local function choose_storage(pc, id)
  local sess = session(pc)
  if id == "withdraw" or id == "toss" then
    -- pokeemerald/src/player_pc.c:569
    if #Storage.ensure(sess).items == 0 then
      msg(pc, "gText_NoItems", function() open_item_storage(pc, 1) end)
      return
    end
    pc.mode = "rse_child"
    local toss = id == "toss"
    require("src.ui.game3.rse.item_storage").show({
      session = sess,
      toss = toss,
      onClose = function() open_item_storage(pc, toss and 3 or 1) end,
    })
  elseif id == "deposit" then
    -- pokeemerald/src/player_pc.c:537
    pc.mode = "rse_child"
    require("src.ui.game3.bag_menu").show(sess and sess.bag, {
      session = sess,
      location = "itempc",
      pocket = "ITEMS",
      onClose = function() open_item_storage(pc, 2) end,
    })
  else
    -- pokeemerald/src/player_pc.c:604
    reshow(pc)
  end
end

local function menu_input(pc, input, count, wrap)
  if input:wasPressed("up") then
    if pc.cursor > 1 then
      pc.cursor = pc.cursor - 1
      se("SE_SELECT")
      return "move"
    elseif wrap then
      pc.cursor = count
      se("SE_SELECT")
      return "move"
    end
  elseif input:wasPressed("down") then
    if pc.cursor < count then
      pc.cursor = pc.cursor + 1
      se("SE_SELECT")
      return "move"
    elseif wrap then
      pc.cursor = 1
      se("SE_SELECT")
      return "move"
    end
  elseif input:wasPressed("a") then
    se("SE_SELECT")
    return "a"
  elseif input:wasPressed("b") then
    se("SE_SELECT")
    return "b"
  end
  return nil
end

function PlayerPc.handles(mode)
  return mode == "player_pc" or mode == "item_storage" or mode == "rse_msg" or mode == "rse_child"
end

function PlayerPc.handleInput(pc, input)
  if pc.mode == "rse_child" then return end
  if pc.mode == "rse_msg" then
    if input:wasPressed("a") or input:wasPressed("b") then
      local after = pc._rseAfterMsg
      pc._rseAfterMsg = nil
      if after then after() end
    end
    return
  end
  if pc.mode == "player_pc" then
    local order = PlayerPc.topOrder(pc)
    -- pokeemerald/src/player_pc.c:419
    local r = menu_input(pc, input, #order, #order > 3)
    if r == "a" then
      choose_top(pc, order[pc.cursor])
    elseif r == "b" then
      turn_off(pc)
    end
    return
  end
  if pc.mode == "item_storage" then
    -- pokeemerald/src/player_pc.c:520
    local r = menu_input(pc, input, #STORAGE_ROWS, true)
    if r == "move" then
      pc._status = storage_desc(pc, pc.cursor)
    elseif r == "a" then
      choose_storage(pc, STORAGE_ROWS[pc.cursor].id)
    elseif r == "b" then
      reshow(pc)
    end
  end
end

local function label_width(labels)
  local w = 0
  for _, l in ipairs(labels) do
    w = math.max(w, FrlgFont.measure(l))
  end
  return w
end

-- pokeemerald/src/menu.c:1560
local function draw_menu(labels, cursor, height)
  local width = math.floor((label_width(labels) + 8 + 7) / 8)
  local tpl = Window.template(1, 1, width, height)
  Window.stdFrame(tpl)
  Window.fill(tpl, 1, 1, 1, 1)
  local pitch = Window.optionHeight()
  for i, l in ipairs(labels) do
    local y = 8 + 1 + (i - 1) * pitch
    if i == cursor then Window.cursorPx(8, y) end
    Window.printPx(l, 16, y)
  end
end

PlayerPc.drawMenu = draw_menu

local function draw_status(pc)
  Window.dialogueFrame()
  if not pc._status then return end
  local lines = {}
  for line in tostring(pc._status):gmatch("[^\r\n]+") do lines[#lines + 1] = line end
  local left, top = 2, 15
  local ui = require("src.core.game3.profile").forSession(pc._session).ui
  local win = ui and ui.frames and ui.frames.dialogueWindow
  if win then left, top = win.left, win.top end
  local pitch = FrlgFont.linePitch()
  for i = 1, math.min(2, #lines) do
    Window.printPx(lines[i], left * 8, top * 8 + 1 + (i - 1) * pitch)
  end
end
PlayerPc.drawStatus = draw_status

function PlayerPc.draw(pc)
  if pc.mode == "rse_child" then return end
  if pc.mode == "player_pc" then
    local labels = {}
    for i, id in ipairs(PlayerPc.topOrder(pc)) do labels[i] = RomText.plain(TOP_ROWS[id]) end
    draw_menu(labels, pc.cursor, #labels * 2)
  elseif pc.mode == "item_storage" then
    local labels = {}
    for i, row in ipairs(STORAGE_ROWS) do labels[i] = RomText.plain(row.id == "exit" and RsPolicy.matches(session(pc)) and "gOtherText_Exit" or row.label) end
    draw_menu(labels, pc.cursor, 8)
  end
  draw_status(pc)
end

return PlayerPc
