local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local Pokeblock = require("src.core.game3.rse.pokeblock")

local Case = { isMenu = true }

Case.ID = "rse_pokeblock_case"
Case.open = false

-- pokeemerald/src/pokeblock.c:36
Case.MAX_MENU_ITEMS = 9
local MENU_MIDPOINT = math.floor(Case.MAX_MENU_ITEMS / 2)
-- pokeemerald/src/pokeblock.c:39
local TILE_HIGHLIGHT_NONE, TILE_HIGHLIGHT_BLUE, TILE_HIGHLIGHT_RED = 0x0005, 0x1005, 0x2005

-- pokeemerald/src/pokeblock.c:309
Case.WIN = {
  TITLE = { 2, 1, 9, 2 }, LIST = { 15, 1, 14, 18 },
  SPICY = { 2, 13, 5, 2 }, DRY = { 2, 15, 5, 2 }, SWEET = { 2, 17, 5, 2 },
  BITTER = { 8, 13, 5, 2 }, SOUR = { 8, 15, 5, 2 }, FEEL = { 11, 17, 2, 2 },
  ACTIONS_TALL = { 7, 5, 6, 6 }, ACTIONS = { 7, 7, 6, 4 }, TOSS_MSG = { 2, 15, 27, 4 },
}
-- pokeemerald/src/pokeblock.c:413
Case.TOSS_YESNO = { 21, 9 }

-- pokeemerald/src/pokeblock.c:216
Case.ACTION = {
  USE_ON_FIELD = { text = "gMenuText_Use", kind = "use_field" },
  TOSS = { text = "gMenuText_Toss", kind = "toss" },
  CANCEL = { text = "gText_Cancel2", kind = "cancel" },
  USE_IN_BATTLE = { text = "gMenuText_Use", kind = "use" },
  USE_ON_FEEDER = { text = "gMenuText_Use", kind = "use" },
  GIVE_TO_LADY = { text = "gMenuText_Give2", kind = "use" },
}
-- pokeemerald/src/pokeblock.c:226
Case.ACTIONS = {
  [Pokeblock.CASE.FIELD] = { Case.ACTION.USE_ON_FIELD, Case.ACTION.TOSS, Case.ACTION.CANCEL },
  [Pokeblock.CASE.BATTLE] = { Case.ACTION.USE_IN_BATTLE, Case.ACTION.CANCEL },
  [Pokeblock.CASE.FEEDER] = { Case.ACTION.USE_ON_FEEDER, Case.ACTION.CANCEL },
  [Pokeblock.CASE.GIVE] = { Case.ACTION.GIVE_TO_LADY, Case.ACTION.CANCEL },
}

-- pokeemerald/src/pokeblock.c:133
local saved = { row = 0, scroll = 0 }
Case.saved = saved

function Case.resetScrollPositions()
  saved.row, saved.scroll = 0, 0
end

local st = {}
Case._st = st

local function gfx() return Gfx.of("rse/pokeblock") end

local function se(name)
  pcall(Kit.playSe, name)
end

local function colors()
  local p = Kit.chromePalettes() and Kit.chromePalettes().std_menu
  local function c(i) return p and Kit.color8(p[i]) or { 0, 0, 0, 1 } end
  return { fg = c(2), shadow = c(3), bg = { 0, 0, 0, 0 } }
end

local function menuPalette()
  local m = gfx():manifest()
  return Gfx.palette(m.palettes.menu, {}, 0)
end

-- pokeemerald/src/pokeblock.c:870
local function refreshItems()
  Pokeblock.compact(st.session)
  local n = Pokeblock.count(st.session)
  st.itemsNo = n + 1
  st.maxShowed = math.min(st.itemsNo, Case.MAX_MENU_ITEMS)
end

-- pokeemerald/src/pokeblock.c:890
local function limitScrollAndRow()
  if saved.scroll ~= 0 and saved.scroll + st.maxShowed > st.itemsNo then
    saved.scroll = st.itemsNo - st.maxShowed
  end
  if saved.scroll + saved.row >= st.itemsNo then
    saved.row = (st.itemsNo == 0) and 0 or (st.itemsNo - 1)
  end
end

-- pokeemerald/src/pokeblock.c:907
local function setInitialScroll()
  if saved.row > MENU_MIDPOINT then
    local i = 0
    while i < saved.row - MENU_MIDPOINT and saved.scroll + st.maxShowed ~= st.itemsNo do
      saved.row = saved.row - 1
      saved.scroll = saved.scroll + 1
      i = i + 1
    end
  end
end

local function selectedId()
  local id = saved.scroll + saved.row
  if id >= st.itemsNo - 1 then return nil end
  return id
end

local function setEntry(x, y, e)
  local i = y * 32 + x
  if st.map[i] ~= e then
    st.map[i] = e
    st.dirty = true
  end
end

-- pokeemerald/src/pokeblock.c:812
local function highlight(row, tile)
  for y = row * 2 + 1, row * 2 + 2 do
    for x = 0xF, 0xF + 0xE - 1 do setEntry(x, y, tile) end
  end
end

-- pokeemerald/src/pokeblock.c:762
local function drawInfo(id)
  local block = id and Pokeblock.get(st.session, id)
  for i = 0, Pokeblock.FLAVOR_COUNT - 1 do
    local a, b = 0xF, 0xF
    if block and Pokeblock.data(block, 1 + i) > 0 then
      a, b = i * 4096 + 0x17, i * 4096 + 0x18
    end
    local x, y = math.floor(i / 3) * 6 + 1, (i % 3) * 2 + 13
    setEntry(x, y, a)
    setEntry(x, y + 1, b)
  end
  st.feel = block and Pokeblock.feel(block) or nil
end

local function redrawHighlights()
  for i = 0, Case.MAX_MENU_ITEMS - 1 do highlight(i, TILE_HIGHLIGHT_NONE) end
  if st.swapping then
    for i = 0, Case.MAX_MENU_ITEMS - 1 do
      if i + saved.scroll == st.toSwap then highlight(i, TILE_HIGHLIGHT_RED) end
    end
  else
    highlight(saved.row, TILE_HIGHLIGHT_BLUE)
  end
end

local function startShake()
  st.shake = 0
end

-- pokeemerald/src/pokeblock.c:750
local function cursorMoved(onInit)
  if not onInit then
    se("SE_SELECT")
    startShake()
  end
  if not st.swapping then drawInfo(selectedId()) end
end

-- pokeemerald/src/list_menu.c:694
local function stepCursor(down)
  local shown, total = st.maxShowed, st.itemsNo
  local scroll, row = saved.scroll, saved.row
  local newRow
  if not down then
    newRow = (shown == 1) and 0 or (shown - (math.floor(shown / 2) + shown % 2) - 1)
    if scroll == 0 then
      if row == 0 then return false end
      row = row - 1
    elseif row > newRow then
      row = row - 1
    else
      row = newRow
      scroll = scroll - 1
    end
  else
    newRow = (shown == 1) and 0 or (math.floor(shown / 2) + shown % 2)
    if scroll == total - shown then
      if row >= shown - 1 then return false end
      row = row + 1
    elseif row < newRow then
      row = row + 1
    else
      row = newRow
      scroll = scroll + 1
    end
  end
  saved.scroll, saved.row = scroll, row
  return true
end

local function moveCursor(down, count)
  local moved = false
  for _ = 1, count or 1 do
    if not stepCursor(down) then break end
    moved = true
  end
  return moved
end

local function listInput(inp)
  local oldRow, oldScroll = saved.row, saved.scroll
  local moved = false
  if inp.rep.up then
    moved = moveCursor(false)
  elseif inp.rep.down then
    moved = moveCursor(true)
  elseif inp.rep.left then
    moved = moveCursor(false, st.maxShowed)
  elseif inp.rep.right then
    moved = moveCursor(true, st.maxShowed)
  end
  if moved then cursorMoved(false) end
  if inp.new.a then
    if saved.scroll + saved.row == st.itemsNo - 1 then return "cancel" end
    return "select"
  elseif inp.new.b then
    return "cancel"
  end
  return (oldRow ~= saved.row or oldScroll ~= saved.scroll) and "moved" or nil
end

local function actionsFor(caseId)
  if st.opts and st.opts.actions then return st.opts.actions[caseId] or st.opts.actions[Pokeblock.CASE.FIELD] end
  return Case.ACTIONS[caseId] or Case.ACTIONS[Pokeblock.CASE.FIELD]
end

local function beginClose(result)
  st.phase = "fadeout"
  st.result = result
  st.fadeDir = 1
end

-- pokeemerald/src/pokeblock.c:1141
local function showActions()
  st.phase = "actions"
  st.actionCursor = 0
end

-- pokeemerald/src/pokeblock.c:1293
local function closeActions()
  st.phase = "list"
end

local function textSpeed()
  local ok, Options = pcall(require, "src.core.game3.options")
  return Kit.textSpeedDelay(ok and Options.textSpeed(st.session) or 1)
end

local function startMessage(key, onDone)
  key = st.opts and st.opts.textAliases and st.opts.textAliases[key] or key
  st.printer = Kit.printer(key, { ctx = { stringVars = { st.tossName } }, speed = textSpeed() })
  st.onPrinted = onDone
end

-- pokeemerald/src/pokeblock.c:1200
local function beginToss()
  st.phase = "toss"
  st.tossName = Pokeblock.name(Pokeblock.get(st.session, st.itemId))
  startMessage("gText_ThrowAwayVar1", function()
    st.yesNo = st.opts and st.opts.makeYesNo and st.opts.makeYesNo()
      or Kit.yesNo(Case.TOSS_YESNO[1], Case.TOSS_YESNO[2])
    st.phase = "toss_yesno"
  end)
end

-- pokeemerald/src/pokeblock.c:1248
local function closeToss()
  st.printer = nil
  st.yesNo = nil
  st.phase = "list"
end

-- pokeemerald/src/pokeblock.c:1221
local function finishToss()
  Pokeblock.tryClear(st.session, st.itemId)
  se("SE_SELECT")
  highlight(saved.row, TILE_HIGHLIGHT_NONE)
  refreshItems()
  limitScrollAndRow()
  highlight(saved.row, TILE_HIGHLIGHT_BLUE)
  drawInfo(selectedId())
  closeToss()
end

local function runAction(action)
  if action.kind == "cancel" then
    closeActions()
  elseif action.kind == "toss" then
    beginToss()
  elseif action.kind == "use_field" then
    -- pokeemerald/src/pokeblock.c:1184
    st.useOnField = st.itemId
    beginClose(nil)
  elseif action.kind == "use" then
    local result = st.onUse and st.onUse(st.itemId) or st.itemId
    beginClose(result)
  end
end

local function updateSwap(noSwap)
  local from = saved.scroll + saved.row
  st.swapping = false
  if st.opts and st.opts.swap then
    st.opts.swap(st, from, noSwap)
    redrawHighlights()
    drawInfo(selectedId())
    st.phase = "list"
    return
  end
  -- pokeemerald/src/pokeblock.c:1121
  if not noSwap and st.toSwap ~= from and st.toSwap ~= from - 1 then
    Pokeblock.move(st.session, st.toSwap, from)
  end
  if st.toSwap < from then
    if saved.row > 0 then saved.row = saved.row - 1 elseif saved.scroll > 0 then saved.scroll = saved.scroll - 1 end
  end
  redrawHighlights()
  drawInfo(selectedId())
  st.phase = "list"
end

local function step(inp)
  st.frame = (st.frame or 0) + 1
  if st.shake then
    st.shake = st.shake + 1
    if st.shake > 12 then st.shake = nil end
  end
  if st.fadeDir ~= 0 then
    st.fade = st.fade + st.fadeDir * 2
    if st.fade <= 0 then
      st.fade, st.fadeDir = 0, 0
    elseif st.fade >= 16 then
      st.fade = 16
      st.fadeDir = 0
      Case.finish()
    end
    return
  end
  local phase = st.phase
  if phase == "list" then
    if inp.new.select then
      -- pokeemerald/src/pokeblock.c:1009
      if saved.scroll + saved.row ~= st.itemsNo - 1 then
        se("SE_SELECT")
        st.toSwap = saved.scroll + saved.row
        st.swapping = true
        highlight(saved.row, TILE_HIGHLIGHT_RED)
        st.phase = "swap"
      end
      return
    end
    local oldRow = saved.row
    local r = listInput(inp)
    if oldRow ~= saved.row or r == "moved" then
      highlight(oldRow, TILE_HIGHLIGHT_NONE)
      highlight(saved.row, TILE_HIGHLIGHT_BLUE)
    end
    if r == "cancel" then
      se("SE_SELECT")
      beginClose(nil)
    elseif r == "select" then
      se("SE_SELECT")
      st.itemId = saved.scroll + saved.row
      showActions()
    end
  elseif phase == "swap" then
    if inp.new.select then
      se("SE_SELECT")
      updateSwap(false)
      return
    end
    local r = listInput(inp)
    if r == "moved" then redrawHighlights() end
    if r == "cancel" then
      se("SE_SELECT")
      updateSwap(not inp.new.a)
    elseif r == "select" then
      se("SE_SELECT")
      updateSwap(false)
    end
  elseif phase == "actions" then
    local list = actionsFor(st.caseId)
    -- pokeemerald/src/menu.c:1013
    if inp.new.up and st.actionCursor > 0 then
      se("SE_SELECT")
      st.actionCursor = st.actionCursor - 1
    elseif inp.new.down and st.actionCursor < #list - 1 then
      se("SE_SELECT")
      st.actionCursor = st.actionCursor + 1
    elseif inp.new.a then
      se("SE_SELECT")
      runAction(list[st.actionCursor + 1])
    elseif inp.new.b then
      se("SE_SELECT")
      closeActions()
    end
  elseif phase == "toss" or phase == "tossed" then
    if st.printer and st.printer:isActive() then
      st.printer:run(inp)
      return
    end
    if phase == "toss" then
      local cb = st.onPrinted
      st.onPrinted = nil
      if cb then cb() end
    elseif inp.new.a or inp.new.b then
      finishToss()
    end
  elseif phase == "toss_yesno" then
    local r = st.yesNo:input(inp)
    if r == 0 then
      se("SE_SELECT")
      st.yesNo = nil
      st.phase = "tossed"
      startMessage("gText_Var1ThrownAway", nil)
    elseif r == 1 or r == -1 then
      se("SE_SELECT")
      closeToss()
    end
  end
end

local KEYS = { "a", "b", "select", "start", "up", "down", "left", "right" }

-- pokeemerald/src/main.c:250
local function snapshot(input)
  local new, held = {}, {}
  for _, k in ipairs(KEYS) do
    if input and input.wasPressed and input:wasPressed(k) then new[k] = true end
    if input and input.isDown and input:isDown(k) then held[k] = true end
  end
  local rep = {}
  for k in pairs(new) do rep[k] = true end
  for _, k in ipairs({ "up", "down", "left", "right" }) do
    if held[k] and not new[k] then
      st.repeatCounter = st.repeatCounter or {}
      local n = (st.repeatCounter[k] or 40) - 1
      if n <= 0 then
        rep[k] = true
        n = 5
      end
      st.repeatCounter[k] = n
    elseif new[k] then
      st.repeatCounter = st.repeatCounter or {}
      st.repeatCounter[k] = 40
    end
  end
  return { new = new, held = held, rep = rep }
end
Case.snapshot = snapshot

-- pokeemerald/src/pokeblock.c:446
function Case.show(opts)
  opts = opts or {}
  for k in pairs(st) do st[k] = nil end
  st.opts = opts
  st.session = opts.session or Pokeblock.session()
  st.caseId = opts.caseId or Pokeblock.CASE.FIELD
  st.onUse = opts.onUse
  st.onClose = opts.onClose
  st.map = gfx():map("menu")
  st.dirty = true
  st.phase = "list"
  st.fade = 16
  st.fadeDir = -1
  refreshItems()
  limitScrollAndRow()
  setInitialScroll()
  highlight(saved.row, TILE_HIGHLIGHT_BLUE)
  drawInfo(selectedId())
  local okF, Fade = pcall(require, "src.ui.game3.fade")
  if okF and Fade and Fade.clear then Fade.clear() end
  Case.open = true
  Stack.push(Case.ID, Case, { hideBelow = true, fullscreen = true })
  return true
end

function Case.isOpen()
  return Case.open
end

-- pokeemerald/src/pokeblock.c:978
function Case.finish()
  Case.open = false
  Stack.pop(Case.ID)
  local cb, result, useId, opts = st.onClose, st.result, st.useOnField, st.opts
  if useId ~= nil then
    -- pokeemerald/src/pokeblock.c:1190
    local Use = require("src.ui.game3.screens").get("use_pokeblock", st.session)
      or require("src.ui.game3.rse.use_pokeblock")
    Use.show({
      session = st.session,
      pokeblockId = useId,
      onExit = function() Case.show(opts) end,
    })
    return
  end
  if cb then cb(result) end
end

function Case.reset()
  Case.open = false
  Stack.pop(Case.ID)
end

function Case.handleInput(input)
  if not Case.open then return end
  st.input = snapshot(input)
end

function Case.update()
  if not Case.open then return end
  local inp = st.input or { new = {}, held = {}, rep = {} }
  st.input = nil
  step(inp)
end

local function drawText(text, x, y, opts)
  FrlgFont.draw(text, x, y, { colors = st.colors, font = opts and opts.font })
end

local function winXY(w, dx, dy)
  return w[1] * 8 + (dx or 0), w[2] * 8 + (dy or 0)
end

-- pokeemerald/src/pokeblock.c:737
local function drawList()
  local W = Case.WIN.LIST
  local x0, y0 = winXY(W)
  for i = 0, st.maxShowed - 1 do
    local id = saved.scroll + i
    local y = y0 + 1 + i * 16
    if id < st.itemsNo - 1 then
      local block = Pokeblock.get(st.session, id)
      drawText(Pokeblock.name(block), x0 + 1, y, { font = "narrow" })
      local lv = RomText.plain("gText_LvVar1", { stringVars = { tostring(Pokeblock.highestFlavorLevel(block)) } })
      drawText(lv, x0 + 1 + 0x57, y, { font = "narrow" })
    elseif id == st.itemsNo - 1 then
      drawText(RomText.plain("gText_StowCase"), x0 + 1, y, { font = "narrow" })
    end
  end
  if st.phase == "swap" then
    local m = gfx():manifest()
    local pal = m.palettes.swap_line
    local arrow = gfx():sprite("swap_line", 0, 16, 16, pal)
    local line = gfx():sprite("swap_line", 4, 16, 16, pal)
    -- pokeemerald/src/pokeblock.c:1090
    local cy = 1 + saved.row * 16 + 8
    for i = 0, 6 do
      love.graphics.draw(i == 0 and arrow or line, 128 + i * 16 - 8, cy - 8)
    end
  end
  -- pokeemerald/src/pokeblock.c:923
  if st.phase ~= "actions" and st.phase ~= "toss" and st.phase ~= "toss_yesno" and st.phase ~= "tossed" then
    if saved.scroll > 0 then Kit.scrollArrow("up", 0xB0, 8, st.frame or 0) end
    if saved.scroll < st.itemsNo - st.maxShowed then Kit.scrollArrow("down", 0xB0, 0x98, st.frame or 0) end
  end
end

-- pokeemerald/src/pokeblock.c:945
local SHAKE = { -2, -2, 2, 2, 2, 2, -2, -2, -2, -2, 2, 2 }

local function drawDevice()
  local m = gfx():manifest()
  local img = gfx():sprite("device", 0, 64, 64, m.palettes.device)
  local rot = 0
  if st.shake then
    for i = 1, math.min(st.shake, #SHAKE) do rot = rot + SHAKE[i] end
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, 56, 64, rot * 2 * math.pi / 256, 1, 1, 32, 32)
end

function Case.draw()
  if not Case.open then return end
  if st.opts and st.opts.draw then return st.opts.draw(st, Case) end
  st.colors = st.colors or colors()
  if st.dirty or not st.bg then
    st.bg = gfx():renderMap(st.map, "menu", menuPalette(), { rows = 20, backdrop = true })
    st.dirty = false
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(st.bg, 0, 0)
  drawDevice()
  -- pokeemerald/src/pokeblock.c:698
  local title = st.title
  if not title then
    local C = require("src.core.game3.constants")
    local id = C.of(C.versionOf(st.session)):require("items", "ITEM_POKEBLOCK_CASE")
    title = require("src.core.game3.items_data").displayName(id)
    st.title = title
  end
  local tx, ty = winXY(Case.WIN.TITLE)
  drawText(title, tx + math.floor((0x48 - FrlgFont.measure(title)) / 2), ty + 1)
  for _, k in ipairs({ "SPICY", "DRY", "SWEET", "BITTER", "SOUR" }) do
    local x, y = winXY(Case.WIN[k])
    drawText(RomText.plain("gText_" .. k:sub(1, 1) .. k:sub(2):lower()), x, y + 1)
  end
  if st.feel then
    local x, y = winXY(Case.WIN.FEEL)
    local s = string.format("%2d", st.feel)
    drawText(s, x + 4 + (FrlgFont.measure("00") - FrlgFont.measure(s)), y + 1)
  end
  drawList()
  if st.phase == "actions" then
    local list = actionsFor(st.caseId)
    local W = (#list == 3) and Case.WIN.ACTIONS_TALL or Case.WIN.ACTIONS
    Chrome.stdFrame(W[1], W[2], W[3], W[4])
    local x, y = winXY(W)
    for i, a in ipairs(list) do drawText(RomText.plain(a.text), x + 8, y + 1 + (i - 1) * 16) end
    drawText(RomText.plain("gText_SelectorArrow3"), x, y + 1 + st.actionCursor * 16)
  end
  if st.phase == "toss" or st.phase == "toss_yesno" or st.phase == "tossed" then
    local W = Case.WIN.TOSS_MSG
    Kit.birchDialogueFrame(W[1], W[2], W[3], W[4])
    if st.printer then st.printer:draw(W[1] * 8, W[2] * 8 + 1, { colors = Kit.messageColors() }) end
    if st.yesNo then st.yesNo:draw() end
  end
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function Case.selected()
  return selectedId(), saved.scroll, saved.row
end

return Case
