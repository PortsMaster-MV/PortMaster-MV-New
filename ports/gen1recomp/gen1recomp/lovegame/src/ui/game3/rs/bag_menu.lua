local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local Text = require("src.core.game3.rom_text")
local Items = require("src.core.game3.items_data")
local Inventory = require("src.core.game3.bag")
local Data = require("src.ui.game3.rs.bag_menu_data")
local M = { MAX_SHOWN = 8 }
local positions = setmetatable({}, { __mode = "k" })
local quads = {}

local function play() Kit.playSe("SE_SELECT") end
local function manifest()
  local m = assert(Kit.manifest("rse/bag"), "native RS bag assets missing")
  assert(m.layout == "rs", "native RS bag layout required")
  return m
end
local function text(key, vars) return Text.plain(key, {stringVars = vars or {}}) end
local function mail(row)
  return row and require("src.core.game3.mail").isMailItem(Items.toNumericId(row.id) or row.id)
end
local function linkActive()
  local Link = package.loaded["src.core.game3.link"]
  return Link and Link.link ~= nil and Link.inLinkRoom and Link.inLinkRoom() == true or false
end
local function holdAllowed(row, Bag)
  local s = Bag._session or {}
  local C = require("src.core.game3.constants").of(s.version)
  -- pokeruby/src/menu_helpers.c:257
  local id = row and Items.toNumericId(row.id)
  if id ~= C:require("items", "ITEM_ENIGMA_BERRY") then return true end
  local Map = package.loaded["src.core.game3.map"]
  local d = Map and Map.currentDef and Map.currentDef()
  local pair = C:map("MAP_TRADE_CENTER")
  return not (d and pair and d.group == pair.group and d.num == pair.num)
end

function M.grid(Bag, row)
  if Bag._battle then
    local info = row and (row.info or Items.info(row.id))
    local usable = info and (tonumber(info.battleUsage) or 0) ~= 0
    return {cells = usable and {"USE", "CANCEL"} or {"CANCEL"}, rows = usable and 2 or 1, cols = 1, left = 7}
  end
  if Bag._location == "blender" then
    return {cells = {"CHECK_TAG", "CONFIRM", false, "CANCEL"}, rows = 2, cols = 2, initial = 2}
  end
  if linkActive() or Bag._location == "party" then
    local canHold = Bag.currentPocket() ~= "KEY_ITEMS" and holdAllowed(row, Bag)
    return {cells = canHold and {"GIVE", "CANCEL"} or {"CANCEL"}, rows = canHold and 2 or 1, cols = 1}
  end
  local cells = Data.GRIDS[Bag.currentPocket()] or Data.GRIDS.ITEMS
  return {cells = cells, rows = #cells / 2, cols = 2}
end

function M.actionsForPocket(_, row, Bag)
  local out = {}
  for _, a in ipairs(M.grid(Bag, row).cells) do if a then out[#out + 1] = a end end
  return out
end

function M.canGive(row)
  return row ~= nil and (tonumber((row.info or Items.info(row.id)).importance) or 0) == 0
end

local function savePos(Bag)
  Bag._rsBag.pos[Bag.pocketIdx] = {cursor = Bag.cursor, scroll = Bag.scroll}
end

local function clamp(Bag)
  local n = #Bag.list() + (Bag._location == "blender" and 0 or 1)
  n = math.max(1, n)
  Bag.cursor = math.max(1, math.min(n, Bag.cursor))
  Bag.scroll = math.max(0, math.min(Bag.scroll or 0, math.max(0, n - 8)))
  if Bag.cursor <= Bag.scroll then Bag.scroll = Bag.cursor - 1 end
  if Bag.cursor > Bag.scroll + 8 then Bag.scroll = Bag.cursor - 8 end
  return n
end

function M.onShow(Bag)
  if Bag._location == "berry_tree" or Bag._location == "blender" then Bag.pocketIdx = 4 end
  local key = Bag._session or Bag._bag
  local pos = positions[key] or {}
  positions[key] = pos
  Bag._rsBag = {pos = pos, frame = 0, gridPos = 1, lastMode = "list"}
  local old = pos[Bag.pocketIdx]
  if old then Bag.cursor, Bag.scroll = old.cursor, old.scroll end
  Bag._open = {k = 0, curtain = false}
  clamp(Bag)
end

local function ensure(Bag)
  if not Bag._rsBag then M.onShow(Bag) end
  return Bag._rsBag
end

function M.beforeAction(Bag, action, row)
  if not row then return false end
  local st = ensure(Bag)
  if action == "SET" then
    local old = Items.toNumericId(Bag._session and Bag._session.registeredItem)
    local id = Items.toNumericId(row.id)
    if Bag._session then Bag._session.registeredItem = old == id and 0 or id end
    Bag.mode = "list"
    return true
  elseif action == "TOSS" then
    Bag.tossQty, Bag.mode = 1, "toss"
    st.toss = {index = Bag.cursor, id = row.id, name = row.name, qty = row.qty}
    return true
  elseif action == "GIVE" then
    if linkActive() and mail(row) then
      Bag.showMessage(text("gOtherText_CantWriteMail"))
      return true
    elseif not holdAllowed(row, Bag) then
      Bag.showMessage(text("gOtherText_CantBeHeldHere", {row.name}))
      return true
    end
  elseif action == "USE" and not Bag._battle then
    local info = row.info or Items.info(row.id)
    if tonumber(info.fieldUseFunc) == 0 then return true end
  end
  return false
end

local function filtered(input, blocked)
  return setmetatable({}, {__index = function(_, key)
    local value = input[key]
    if key == "wasPressed" or key == "isDown" then
      return function(_, button)
        if blocked[button] or type(value) ~= "function" then return false end
        return value(input, button)
      end
    end
    if type(value) == "function" then return function(_, ...) return value(input, ...) end end
    return value
  end})
end

local function delegate(Bag, input)
  local added = {}
  for from, to in pairs(Data.TEXT_ALIASES) do
    if Text.overrides[from] == nil and not Text.has(from) and Text.has(to) then
      Text.overrides[from] = Text.ir(to)
      added[#added + 1] = from
    end
  end
  local ok, err = pcall(Bag.handleInput, input)
  for _, key in ipairs(added) do Text.overrides[key] = nil end
  if not ok then error(err, 0) end
end

local function repeatKey(st, input)
  local key
  for _, k in ipairs({"up", "down", "left", "right"}) do
    if input:wasPressed(k) then st.held, st.heldFrames = k, 0 return k end
    if not key and input.isDown and input:isDown(k) then key = k end
  end
  if key ~= st.held then st.held, st.heldFrames = key, 0 return nil end
  if key then
    st.heldFrames = st.heldFrames + 1
    -- pokeruby/src/main.c:210
    if st.heldFrames >= 40 and (st.heldFrames - 40) % 5 == 0 then return key end
  end
end

local function switchPocket(Bag, dir)
  local st = ensure(Bag)
  savePos(Bag)
  local previous = Bag.pocketIdx
  Bag.pocketIdx = (Bag.pocketIdx - 1 + dir) % 5 + 1
  local pos = st.pos[Bag.pocketIdx]
  Bag.cursor, Bag.scroll = pos and pos.cursor or 1, pos and pos.scroll or 0
  Bag._switch = {k = 0, dir = dir, previous = previous}
  st.ball, st.bagDrop = {k = 0, dir = dir}, 0
  clamp(Bag)
  play()
end

local function syncGrid(Bag)
  local st = ensure(Bag)
  if st.lastMode ~= "action" and Bag.mode == "action" then
    local g = M.grid(Bag, Bag.list()[Bag.cursor])
    st.gridPos = g.initial or 1
  end
  st.lastMode = Bag.mode
  if Bag.mode ~= "action" then return end
  local g = M.grid(Bag, Bag.list()[Bag.cursor])
  local index = 0
  for i, a in ipairs(g.cells) do
    if a then index = index + 1 end
    if i == st.gridPos then Bag.actionCursor = index break end
  end
end

local function tossInput(Bag, input, key)
  local st, mode = ensure(Bag), Bag.mode
  local selected = st.toss
  if not selected then return false end
  if mode == "toss" then
    local q, max = Bag.tossQty, selected.qty
    if key == "up" then q = q == max and 1 or q + 1
    elseif key == "down" then q = q == 1 and max or q - 1
    elseif key == "right" then q = math.min(max, q + 10)
    elseif key == "left" then q = math.max(1, q - 10)
    elseif input:wasPressed("a") then Bag.mode, Bag.yesNoCursor = "toss_confirm", 1 play()
    elseif input:wasPressed("b") then Bag.mode, st.toss = "list", nil play() end
    if q ~= Bag.tossQty then Bag.tossQty = q play() end
    return true
  elseif mode == "toss_confirm" then
    if key == "up" and Bag.yesNoCursor == 2 then Bag.yesNoCursor = 1 play()
    elseif key == "down" and Bag.yesNoCursor == 1 then Bag.yesNoCursor = 2 play()
    elseif input:wasPressed("a") and Bag.yesNoCursor == 1 then
      play()
      if Inventory.removeSlot(Bag._bag, Bag.currentPocket(), selected.index, Bag.tossQty) then
        if Bag._session and Items.toNumericId(Bag._session.registeredItem) == Items.toNumericId(selected.id)
            and selected.qty == Bag.tossQty then Bag._session.registeredItem = 0 end
        Bag.mode = "toss_done"
        clamp(Bag)
      else Bag.mode, st.toss = "list", nil end
    elseif input:wasPressed("a") or input:wasPressed("b") then Bag.mode, st.toss = "list", nil play() end
    return true
  elseif mode == "toss_done" then
    if input:wasPressed("a") or input:wasPressed("b") then Bag.mode, st.toss = "list", nil play() end
    return true
  end
  return false
end

local function commitDeposit(Bag)
  local st = ensure(Bag)
  local row = st.deposit
  if (tonumber(row.info.importance) or 0) == 2 then
    Bag.showMessage(text("gOtherText_CantStoreSomeoneItem"))
  elseif require("src.core.game3.storage").addPcItem(Bag._session, row.id, Bag.tossQty) then
    assert(Inventory.removeSlot(Bag._bag, Bag.currentPocket(), row.index, Bag.tossQty))
    if Bag._session and row.qty == Bag.tossQty
        and Items.toNumericId(Bag._session.registeredItem) == Items.toNumericId(row.id) then
      Bag._session.registeredItem = 0
    end
    Bag._depositText = text("gOtherText_DepositedItems", {row.name, tostring(Bag.tossQty)})
    Bag.mode = "deposit_done"
    clamp(Bag)
  else Bag.showMessage(text("gOtherText_NoRoomForItems")) end
end

local function depositInput(Bag, input, key)
  local st = ensure(Bag)
  if not st.deposit then return false end
  if Bag.mode == "deposit" then
    local q, max = Bag.tossQty, st.deposit.qty
    if key == "up" then q = q == max and 1 or q + 1
    elseif key == "down" then q = q == 1 and max or q - 1
    elseif key == "right" then q = math.min(max, q + 10)
    elseif key == "left" then q = math.max(1, q - 10)
    elseif input:wasPressed("a") then play() commitDeposit(Bag)
    elseif input:wasPressed("b") then Bag.mode, st.deposit = "list", nil play() end
    if q ~= Bag.tossQty then Bag.tossQty = q play() end
    return true
  elseif Bag.mode == "deposit_done" then
    if input:wasPressed("a") or input:wasPressed("b") then
      Bag.mode, st.deposit, Bag._depositText = "list", nil, nil
      play()
    end
    return true
  end
  return false
end

function M.handleInput(input, Bag)
  Bag = Bag or require("src.ui.game3.bag_menu")
  if not Bag.open or not input then return end
  local st = ensure(Bag)
  st.frame = st.frame + 1
  if st.ball then st.ball.k = st.ball.k + 1 if st.ball.k >= 32 then st.ball = nil end end
  if st.bagDrop then st.bagDrop = st.bagDrop + 1 if st.bagDrop >= 10 then st.bagDrop = nil end end
  if Bag._exit then
    local ex = Bag._exit
    ex.k = ex.k + 1
    if ex.k >= 16 then Bag._exit = nil if ex.cb then ex.cb() end end
    return
  elseif Bag._open then
    Bag._open.k = Bag._open.k + 1
    if Bag._open.k >= 16 then Bag._open = nil end
    return
  end
  local key = repeatKey(st, input)
  if Bag._switch then
    local lr = require("src.core.game3.options").lrMode(Bag._session)
    if input:wasPressed("left") or (lr and input:wasPressed("l")) then switchPocket(Bag, -1)
    elseif input:wasPressed("right") or (lr and input:wasPressed("r")) then switchPocket(Bag, 1)
    else Bag._switch.k = Bag._switch.k + 1 if Bag._switch.k >= 16 then Bag._switch = nil end end
    return
  end
  if tossInput(Bag, input, key) then savePos(Bag) return end
  if depositInput(Bag, input, key) then savePos(Bag) return end
  syncGrid(Bag)
  local blocked = {up = true, down = true, left = true, right = true, l = true, r = true, select = true}
  if Bag.mode == "list" then
    local n = clamp(Bag)
    if key == "up" or key == "down" then
      local nextCursor = math.max(1, math.min(n, Bag.cursor + (key == "down" and 1 or -1)))
      if nextCursor ~= Bag.cursor then Bag.cursor = nextCursor clamp(Bag) play() st.shake = st.frame end
      savePos(Bag)
      return
    end
    if st.swap then
      if input:wasPressed("b") or (input:wasPressed("a") and Bag.cursor > #Bag.list()) then st.swap = nil play()
      elseif input:wasPressed("a") or input:wasPressed("select") then
        local slots = Bag._bag.pockets[Bag.currentPocket()]
        if slots[Bag.cursor] then slots[st.swap], slots[Bag.cursor] = slots[Bag.cursor], slots[st.swap] end
        st.swap = nil play()
      end
      return
    end
    local location = Bag._location
    if location ~= "berry_tree" and location ~= "blender" then
      local lr = require("src.core.game3.options").lrMode(Bag._session)
      if input:wasPressed("left") or (lr and input:wasPressed("l")) then switchPocket(Bag, -1) return
      elseif input:wasPressed("right") or (lr and input:wasPressed("r")) then switchPocket(Bag, 1) return end
    end
    if input:wasPressed("select") and (location == nil or Bag._battle)
        and Bag.currentPocket() ~= "TM_CASE" and Bag.currentPocket() ~= "BERRY_POUCH"
        and Bag.cursor <= #Bag.list() then st.swap = Bag.cursor play() return end
    if location == "blender" and input:wasPressed("b") then return end
    if input:wasPressed("a") then
      local row = Bag.list()[Bag.cursor]
      if row and location == "party" then
        play()
        if linkActive() and mail(row) then Bag.showMessage(text("gOtherText_CantWriteMail")) return
        elseif not holdAllowed(row, Bag) then Bag.showMessage(text("gOtherText_CantBeHeldHere", {row.name})) return
        elseif not M.canGive(row) then Bag.showMessage(text("gOtherText_CantBeHeld", {row.name})) return end
        if require("src.ui.game3.rs.bag_menu_give").begin(Bag, row) then return end
      elseif row and location == "itempc" then
        play()
        st.deposit = {index = Bag.cursor, id = row.id, name = row.name, qty = row.qty, info = row.info or Items.info(row.id)}
        Bag.tossQty = 1
        if Bag.currentPocket() == "KEY_ITEMS" then commitDeposit(Bag) else Bag.mode = "deposit" end
        return
      end
    end
  elseif Bag.mode == "action" then
    local g = M.grid(Bag, Bag.list()[Bag.cursor])
    local p, target = st.gridPos
    local row = (p - 1) % g.rows
    if key == "up" and row > 0 then target = p - 1
    elseif key == "down" and row < g.rows - 1 then target = p + 1
    elseif key == "left" and p > g.rows then target = p - g.rows
    elseif key == "right" and g.cols == 2 and p <= g.rows then target = p + g.rows end
    if target and g.cells[target] then st.gridPos = target syncGrid(Bag) play() end
  else blocked = {} end
  delegate(Bag, filtered(input, blocked))
  if Bag.open then syncGrid(Bag) clamp(Bag) savePos(Bag) end
end

local function imageFrame(entry, frame, x, y, rotation)
  if not entry then return end
  local img = Kit.image(entry.png)
  if not img then return end
  local iw, ih = img:getDimensions()
  local key = entry.png .. ":" .. frame
  local q = quads[key]
  if not q then q = love.graphics.newQuad(0, frame * entry.h, entry.w, entry.h, iw, ih) quads[key] = q end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, q, x, y, rotation or 0, 1, 1, entry.w / 2, entry.h / 2)
end
local function image(path, x, y)
  local img = path and Kit.image(path)
  if img then love.graphics.setColor(1, 1, 1, 1) love.graphics.draw(img, x, y) end
end
local function drawText(str, x, y, colors, width)
  Font.draw(str, x, y, {font = "normal", colors = colors, maxWidth = width or 120, linePitch = 16})
end
local function frame(left, top, width, height) Chrome.stdFrame(left + 1, top + 1, width - 1, height - 1) end

function M.draw(Bag)
  Bag = Bag or require("src.ui.game3.bag_menu")
  if not Bag.open then return end
  local m, st = manifest(), ensure(Bag)
  local fem = Bag._session and (Bag._session.gender == "female" or Bag._session.gender == 1 or Bag._session.playerGender == 1)
  Font.sync()
  local colors = {fg = Font.STDPAL[1], bg = {0, 0, 0, 0}, shadow = Font.STDPAL[8]}
  image(fem and m.layers.bg.variants.female or m.layers.bg.png, 0, 0)
  local entry = fem and m.sprites.female or m.sprites.male
  local anim = entry.anims[Bag.pocketIdx + 1]
  local bagFrame = anim and anim[1] and anim[1].frame or 0
  local drop = st.bagDrop and (-4 + math.min(4, math.floor(st.bagDrop / 2))) or 0
  if st.bagDrop then bagFrame = 0 end
  local shake = st.shake and st.frame - st.shake
  local rotation = 0
  if shake and shake < 12 then
    local degrees = ({-2, -4, -2, 0, 2, 4, 2, 0, -2, -4, -2, 0})[shake + 1]
    rotation = -degrees * math.pi / 128
  end
  imageFrame(entry, bagFrame, 58, 40 + drop, rotation)
  imageFrame(m.sprites.ball, 0, 16, 88, st.ball and -st.ball.dir * st.ball.k * math.pi / 16 or 0)
  local labels = m.labels[Bag.pocketIdx]
  image(fem and labels.female or labels.male, 32, 80)
  if m.indicators then
    for p = 1, 5 do image(p == Bag.pocketIdx and m.indicators.selected or m.indicators.idle, 32 + p * 8, 72) end
  end
  local rows = Bag.list()
  local scroll = Bag.scroll
  local bottom = math.min(#rows + (Bag._location == "blender" and 0 or 1), scroll + 8)
  local Pokemon = require("src.core.game3.pokemon")
  for i = scroll + 1, bottom do
    local row, y = rows[i], 16 + (i - scroll - 1) * 16
    local rowColors = colors
    if i == st.swap or (Bag.mode ~= "list" and i == Bag.cursor) then
      rowColors = {fg = Font.STDPAL[2], bg = colors.bg, shadow = colors.shadow}
    end
    if not row then drawText(text("gOtherText_CloseBag"), 112, y, rowColors)
    else
      local pocket = Bag.currentPocket()
      if pocket == "TM_CASE" or pocket == "BERRY_POUCH" then
        local hm = pocket == "TM_CASE" and Items.isHm(row.id)
        image(hm and m.hm or m.number, 112, y)
        local number = pocket == "TM_CASE" and Items.tmNumber(row.id) or Items.berryNumber(row.id)
        drawText(hm and tostring(number) or string.format("%02d", number or 0), 129, y, rowColors)
        local move = pocket == "TM_CASE" and Pokemon.moveFromTmItem(row.id)
        drawText(move and Pokemon.moveName(move) or row.name, 136, y, rowColors, hm and 96 or 78)
        if not hm then drawText("×" .. tostring(row.qty), 232 - Font.measure("×" .. tostring(row.qty), {font = "normal"}), y, rowColors) end
      elseif pocket == "KEY_ITEMS" then
        drawText(row.name, 112, y, rowColors, 96)
        if Bag._session and Items.toNumericId(Bag._session.registeredItem) == Items.toNumericId(row.id) then image(m.select, 208, y) end
      else
        drawText(row.name, 112, y, rowColors, 102)
        drawText("×" .. tostring(row.qty), 232 - Font.measure("×" .. tostring(row.qty), {font = "normal"}), y, rowColors)
      end
    end
  end
  if Bag.mode == "list" and not Bag._switch then
    if m.listCursor then
      image(m.listCursor.png, 112 + (m.listCursor.offsetX or 0), 16 + (Bag.cursor - scroll - 1) * 16 + (m.listCursor.offsetY or 0))
    end
    local bob = require("src.core.game3.trig").sin(st.frame * 8 % 256) * 2 / 256
    if scroll > 0 then imageFrame(m.sprites.arrows_vertical, 0, 172, 12 + math.floor(bob)) end
    if bottom < #rows + (Bag._location == "blender" and 0 or 1) then imageFrame(m.sprites.arrows_vertical, 1, 172, 148 - math.floor(bob)) end
    if Bag._location ~= "berry_tree" and Bag._location ~= "blender" and not st.swap then
      imageFrame(m.sprites.arrows_horizontal, 0, 28 + math.floor(bob), 88)
      imageFrame(m.sprites.arrows_horizontal, 1, 100 - math.floor(bob), 88)
    end
  end
  local selected = rows[Bag.cursor]
  local desc
  if st.swap then desc = text("gOtherText_SwitchWhichItem")
  elseif Bag.mode == "action" then desc = text("gOtherText_WhatWillYouDo2")
  elseif Bag.mode == "toss" then desc = text("gOtherText_HowManyToToss")
  elseif Bag.mode == "toss_confirm" then desc = text("gOtherText_OkayToThrowAwayPrompt", {st.toss.name, tostring(Bag.tossQty)})
  elseif Bag.mode == "toss_done" then desc = text("gOtherText_ThrewAwayItem", {st.toss.name, tostring(Bag.tossQty)})
  elseif Bag.mode == "deposit" then desc = text("gOtherText_HowManyToDeposit")
  elseif Bag.mode == "deposit_done" then desc = Bag._depositText
  else desc = selected and selected.description end
  if desc then drawText(desc, 4, 104, colors, 104)
  elseif not selected then
    drawText(text("gOtherText_ReturnTo"), 4, 104, colors, 104)
    drawText(text(Data.RETURN_TEXT[Bag._battle and "battle" or Bag._location or "field"] or Data.RETURN_TEXT.field), 4, 120, colors, 104)
  end
  if Bag.mode == "action" then
    local g = M.grid(Bag, selected)
    local top = g.cols == 1 and (g.rows == 1 and 9 or 7) or (g.rows == 3 and 5 or 7)
    local left = g.left or (g.cols == 1 and 6 or 0)
    frame(left, top, 13 - left, 5 + (g.rows - 2) * 2)
    for i, action in ipairs(g.cells) do
      if action then
        local col, row = math.floor((i - 1) / g.rows), (i - 1) % g.rows
        local x, y = (left + 1 + col * 6) * 8, (top + 1 + row * 2) * 8
      local label = action
        if i == 1 and action == "USE" then
          local Player = package.loaded["src.core.game3.player"]
          local kind = selected and Items.fieldUseKind(selected.id)
          if kind == "bike" and Player and Player.biking then label = "WALK" elseif mail(selected) then label = "CHECK" end
        end
        drawText(text(Data.ACTION_TEXT[label]), x, y, Font.COLOR.NORMAL, 48)
        if i == st.gridPos then Cursor.draw(x, y, 8) end
      end
    end
  elseif Bag.mode == "toss" or Bag.mode == "deposit" then
    local berry = Bag.currentPocket() == "BERRY_POUCH"
    frame(berry and 6 or 7, 9, berry and 7 or 6, 3)
    drawText("×" .. string.format(berry and "%03d" or "%02d", Bag.tossQty), (berry and 8 or 9) * 8, 80, Font.COLOR.NORMAL, 40)
  elseif Bag.mode == "toss_confirm" then
    frame(7, 7, 6, 5)
    drawText(text("OtherText_Yes"), 64, 64, Font.COLOR.NORMAL)
    drawText(text("OtherText_No"), 64, 80, Font.COLOR.NORMAL)
    Cursor.draw(64, Bag.yesNoCursor == 2 and 80 or 64, 40)
  end
  if Bag.mode == "message" and Bag.messageText then
    Chrome.dialogueFrame()
    drawText(Bag.messageText, 16, 120, Font.COLOR.NORMAL, 208)
  end
  if Bag.mode == "sell" and Bag._sell then Bag._sell:draw() end
  local fade = Bag._open and math.max(0, 16 - Bag._open.k) or Bag._exit and math.min(16, Bag._exit.k) or 0
  if fade > 0 then love.graphics.setColor(0, 0, 0, fade / 16) love.graphics.rectangle("fill", 0, 0, 240, 160) end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.reset()
  positions, quads = setmetatable({}, {__mode = "k"}), {}
  local Bag = package.loaded["src.ui.game3.bag_menu"]
  if Bag then Bag._rsBag = nil end
  Kit.resetCaches()
end

return M
