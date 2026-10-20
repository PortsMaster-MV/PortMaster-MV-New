-- pokeemerald/src/move_relearner.c:475 DoMoveRelearnerMain

local Stack = require("src.ui.game3.stack")
local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local Pokemon = require("src.core.game3.pokemon")
local MoveLearn = require("src.core.game3.move_learn")
local LearnMove = require("src.core.game3.battle.learn_move")
local SummaryData = require("src.core.game3.summary_data")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")

local RseRelearner = { isMenu = true }

RseRelearner.SUB = "rse/move_relearner"
RseRelearner.open = false
RseRelearner.state = "list"
RseRelearner.cursor = 1
RseRelearner.scroll = 0
RseRelearner.yesNoCursor = 1
RseRelearner.contest = false
RseRelearner.t = 0

-- pokeemerald/src/menu_specialized.c:108 sMoveRelearnerWindowTemplates
local WIN_DESC = Window.template(1, 1, 16, 12)
local WIN_LIST = Window.template(19, 1, 10, 12)
local WIN_MSG = Window.template(4, 15, 22, 4)
-- pokeemerald/src/menu_specialized.c:159 sMoveRelearnerYesNoMenuTemplate
local WIN_YESNO = Window.template(22, 8, 5, 4)
RseRelearner.WIN = { desc = WIN_DESC, list = WIN_LIST, msg = WIN_MSG, yesno = WIN_YESNO }

-- pokeemerald/src/menu_specialized.c:747
local MAX_SHOWN = 6
local NARROW = { font = "narrow" }

-- pokeemerald/src/move_relearner.c:254
local MODE_ARROWS = { { "left", 27, 16 }, { "right", 117, 16 } }
-- pokeemerald/src/move_relearner.c:269
local LIST_UP, LIST_DOWN = { 192, 8 }, { 192, 104 }

local function se(name)
  local SE = require("src.core.game3.se_ids")
  pcall(function() require("src.core.game3.audio").playSe(SE[name]) end)
end

function RseRelearner.isOpen()
  return RseRelearner.open
end

function RseRelearner.moves()
  return RseRelearner._moves or {}
end

local function total_rows()
  return #RseRelearner.moves() + 1
end

local function shown()
  return math.min(RseRelearner._opts and RseRelearner._opts.maxShown or MAX_SHOWN, total_rows())
end

local function text(key, ctx)
  local opts = RseRelearner._opts
  if opts and opts.text then return opts.text(key, ctx) end
  return RomText.plain(key, ctx)
end

local function clamp_cursor()
  local total = total_rows()
  if RseRelearner.cursor > total then RseRelearner.cursor = total end
  if RseRelearner.cursor < 1 then RseRelearner.cursor = 1 end
  local n = shown()
  if RseRelearner.cursor <= RseRelearner.scroll then RseRelearner.scroll = RseRelearner.cursor - 1 end
  if RseRelearner.cursor > RseRelearner.scroll + n then RseRelearner.scroll = RseRelearner.cursor - n end
  if RseRelearner.scroll > total - n then RseRelearner.scroll = total - n end
  if RseRelearner.scroll < 0 then RseRelearner.scroll = 0 end
end

local function mon_name()
  return Pokemon.displayMonName(RseRelearner._mon)
end

local function selected_move()
  return RseRelearner.moves()[RseRelearner.cursor]
end

local function clean(text)
  text = tostring(text or ""):gsub("\\n", "\n")
  text = text:gsub("\\p$", ""):gsub("\\p", "\n")
  return text
end

-- pokeemerald/src/move_relearner.c:836 ShowTeachMoveText
local function to_list()
  RseRelearner.state = "list"
  RseRelearner.prompt = text("gText_TeachWhichMoveToPkmn", { stringVars = { mon_name() } })
end

local function push_message(text, cb)
  RseRelearner.state = "message"
  RseRelearner.prompt = clean(text)
  RseRelearner._messageCb = cb
end

local function ask_yes_no(text, cb)
  RseRelearner.state = "yesno"
  RseRelearner.prompt = clean(text)
  RseRelearner.yesNoCursor = 1
  RseRelearner._yesNoCb = cb
end

local function party_slot()
  local party = RseRelearner._session and RseRelearner._session.party
  if type(party) == "table" then
    for i = 1, #party do
      if party[i] == RseRelearner._mon then return party, i end
    end
  end
  return { RseRelearner._mon }, 1
end

-- pokeemerald/src/move_relearner.c:661 ShowSelectMovePokemonSummaryScreen
local function open_forget_screen(_labels, cb)
  local okS, SummaryMenu = pcall(require, "src.ui.game3.summary_menu")
  if not (okS and SummaryMenu and SummaryMenu.openMenu) then
    if cb then cb(nil) end
    return
  end
  local party, slot = party_slot()
  local okOpen = pcall(SummaryMenu.openMenu, party, slot, {
    session = RseRelearner._session,
    mode = "select_move",
    moveToLearn = RseRelearner._pendingMoveId,
    onSelectMove = function(slotIdx)
      if cb then cb(slotIdx) end
    end,
  })
  if not okOpen and cb then cb(nil) end
end

function RseRelearner.finish(learned)
  if not RseRelearner.open then return end
  RseRelearner.open = false
  RseRelearner.state = "list"
  RseRelearner._messageCb = nil
  RseRelearner._yesNoCb = nil
  Stack.pop("move_relearner")
  local cb = RseRelearner._onDone
  RseRelearner._onDone = nil
  if cb then cb(learned == true) end
end

-- pokeemerald/src/move_relearner.c:517
local function start_learn(moveId)
  RseRelearner._pendingMoveId = moveId
  if RseRelearner._opts and RseRelearner._opts.startLearn then
    return RseRelearner._opts.startLearn(RseRelearner, moveId, {
      message = push_message, yesNo = ask_yes_no, forget = open_forget_screen, toList = to_list,
    })
  end
  LearnMove.begin({
    mon = RseRelearner._mon,
    moveId = moveId,
    relearner = true,
    displayName = mon_name(),
    pushMsg = push_message,
    askYesNo = ask_yes_no,
    askForget = open_forget_screen,
    onDone = function(learned)
      if learned then
        RseRelearner.finish(true)
      else
        -- pokeemerald/src/move_relearner.c:637
        RseRelearner._moves = MoveLearn.relearnableMoves(RseRelearner._mon)
        clamp_cursor()
        to_list()
      end
    end,
  })
end

function RseRelearner.show(mon, opts)
  opts = opts or {}
  RseRelearner.open = true
  RseRelearner._mon = mon
  RseRelearner._session = opts.session
  RseRelearner._opts = opts
  RseRelearner._onDone = opts.onDone
  RseRelearner._moves = MoveLearn.relearnableMoves(mon)
  RseRelearner._pendingMoveId = nil
  RseRelearner._messageCb = nil
  RseRelearner._yesNoCb = nil
  RseRelearner.cursor = 1
  RseRelearner.scroll = 0
  -- pokeemerald/src/move_relearner.c:406
  RseRelearner.contest = false
  RseRelearner.t = 0
  clamp_cursor()
  to_list()
  Stack.push("move_relearner", RseRelearner, { hideBelow = true, fullscreen = true })
end

-- pokeemerald/src/move_relearner.c:811
function RseRelearner.giveUpPrompt()
  ask_yes_no(text("gText_MoveRelearnerGiveUp", { stringVars = { mon_name() } }), function(yes)
    if yes then
      RseRelearner.finish(false)
    else
      to_list()
    end
  end)
end

-- pokeemerald/src/menu_helpers.c:252 GetLRKeysPressed
local function lr_pressed(input)
  if not (input:wasPressed("l") or input:wasPressed("r")) then return false end
  local ok, lr = pcall(function() return require("src.core.game3.options").lrMode(RseRelearner._session) end)
  return ok and lr == true
end

function RseRelearner.handleInput(input)
  if not RseRelearner.open then return end
  RseRelearner.t = RseRelearner.t + 1

  if RseRelearner.state == "message" then
    if input:wasPressed("a") or input:wasPressed("b") then
      se("SE_SELECT")
      local cb = RseRelearner._messageCb
      RseRelearner._messageCb = nil
      to_list()
      if cb then cb() end
    end
    return
  end

  if RseRelearner.state == "yesno" then
    if input:wasPressed("up") and RseRelearner.yesNoCursor ~= 1 then
      RseRelearner.yesNoCursor = 1
      se("SE_SELECT")
    elseif input:wasPressed("down") and RseRelearner.yesNoCursor ~= 2 then
      RseRelearner.yesNoCursor = 2
      se("SE_SELECT")
    elseif input:wasPressed("a") or input:wasPressed("b") then
      se("SE_SELECT")
      local yes = input:wasPressed("a") and RseRelearner.yesNoCursor == 1
      local cb = RseRelearner._yesNoCb
      RseRelearner._yesNoCb = nil
      to_list()
      if cb then cb(yes) end
    end
    return
  end

  local total = total_rows()
  if input:wasPressed("up") then
    if RseRelearner.cursor > 1 then
      RseRelearner.cursor = RseRelearner.cursor - 1
      clamp_cursor()
      se("SE_SELECT")
    end
  elseif input:wasPressed("down") then
    if RseRelearner.cursor < total then
      RseRelearner.cursor = RseRelearner.cursor + 1
      clamp_cursor()
      se("SE_SELECT")
    end
  elseif input:wasPressed("left") or input:wasPressed("right") or lr_pressed(input) then
    -- pokeemerald/src/move_relearner.c:786
    se("SE_SELECT")
    RseRelearner.contest = not RseRelearner.contest
  elseif input:wasPressed("a") then
    se("SE_SELECT")
    local moveId = selected_move()
    if moveId then
      -- pokeemerald/src/move_relearner.c:819
      ask_yes_no(text("gText_MoveRelearnerTeachMoveConfirm",
        { stringVars = { mon_name(), Pokemon.moveName(moveId) } }), function(yes)
        if yes then
          start_learn(moveId)
        else
          to_list()
        end
      end)
    else
      RseRelearner.giveUpPrompt()
    end
  elseif input:wasPressed("b") then
    se("SE_SELECT")
    RseRelearner.giveUpPrompt()
  end
end

local function manifest()
  return Kit.manifest(RseRelearner.SUB)
end

local function frame(tpl)
  Window.stdFrame(tpl)
  Window.fill(tpl, 1, 1, 1, 1)
end

local function type_name(t)
  local Types = require("src.core.game3.battle.types")
  local id = tonumber(t)
  if not id and type(t) == "string" then id = Types.ID[t:upper()] end
  local ok, name = pcall(Types.name, id or 0)
  return ok and name or ""
end

local function print_at(text, x, y, opts)
  FrlgFont.draw(tostring(text or ""), WIN_DESC.left * 8 + x, WIN_DESC.top * 8 + y, opts)
end

local function right(text, edge, y)
  print_at(text, edge - FrlgFont.measure(text), y)
end

local function center(text, width, y)
  print_at(text, math.floor((width - FrlgFont.measure(text)) / 2), y)
end

local function print_lines(text, x, y, opts)
  local pitch = FrlgFont.linePitch(opts)
  for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
    print_at(line, x, y, opts)
    y = y + pitch
  end
end

-- pokeemerald/src/menu_specialized.c:752 MoveRelearnerLoadBattleMoveDescription
local function draw_battle(moveId)
  center(RomText.plain("gText_MoveRelearnerBattleMoves"), 128, 1)
  local ppLabel = RomText.plain("gText_MoveRelearnerPP")
  print_at(ppLabel, 4, 41)
  right(RomText.plain("gText_MoveRelearnerPower"), 106, 25)
  right(RomText.plain("gText_MoveRelearnerAccuracy"), 106, 41)
  if not moveId then return end
  local row = Pokemon.battleMove(moveId) or {}
  print_at(type_name(row.type), 4, 25)
  print_at(tostring(tonumber(row.pp) or 0), 4 + FrlgFont.measure(ppLabel), 41)
  local power, acc = tonumber(row.power) or 0, tonumber(row.accuracy) or 0
  local dashes = RomText.plain("gText_ThreeDashes")
  print_at(power < 2 and dashes or tostring(power), 106, 25)
  print_at(acc == 0 and dashes or tostring(acc), 106, 41)
  print_lines(SummaryData.moveDescription(moveId, Pokemon.moveName(moveId)), 0, 65, NARROW)
end

local function contest_row(moveId)
  local c = Kit.loadLua("data/generated/gba/pokemon/contest_moves.lua")
  local cm = c and c.moves and c.moves[moveId]
  local eff = cm and c.effects and c.effects[cm.effect]
  return cm, eff, c
end

-- pokeemerald/src/move_relearner.c:919 MoveRelearnerShowHideHearts
local function heart_counts(eff)
  local appeal = eff and eff.appeal or 0
  local jam = eff and eff.jam or 0
  appeal = appeal == 0xFF and 0 or math.floor(appeal / 10)
  jam = jam == 0xFF and 0 or math.floor(jam / 10)
  return appeal, jam
end
RseRelearner.heartCounts = heart_counts

local quads = {}
local function heart_quad(frame, h, sw, sh)
  local q = quads[frame]
  if not q then
    q = love.graphics.newQuad(0, frame * h.h, h.w, h.h, sw, sh)
    quads[frame] = q
  end
  return q
end

local function draw_hearts(eff)
  local m = manifest()
  local h = m and m.hearts
  local img = h and Kit.image(h.png)
  if not img then return end
  local sw, sh = img:getDimensions()
  local appeal, jam = heart_counts(eff)
  love.graphics.setColor(1, 1, 1, 1)
  for i = 0, 7 do
    -- pokeemerald/src/move_relearner.c:856
    local x = (i % 4) * 8 + 104 - h.w / 2
    local ya = math.floor(i / 4) * 8 + 36 - h.h / 2
    local yj = math.floor(i / 4) * 8 + 52 - h.h / 2
    local fa = i < appeal and h.names.appealFull or h.names.appealEmpty
    local fj = i < jam and h.names.jamFull or h.names.jamEmpty
    love.graphics.draw(img, heart_quad(fa, h, sw, sh), x, ya)
    love.graphics.draw(img, heart_quad(fj, h, sw, sh), x, yj)
  end
end

-- pokeemerald/src/menu_specialized.c:814 MoveRelearnerMenuLoadContestMoveDescription
local function draw_contest(moveId)
  center(RomText.plain("gText_MoveRelearnerContestMovesTitle"), 128, 1)
  right(RomText.plain("gText_MoveRelearnerAppeal"), 92, 25)
  right(RomText.plain("gText_MoveRelearnerJam"), 92, 41)
  if not moveId then return end
  local cm, eff, c = contest_row(moveId)
  if cm then
    local category = c.categories and c.categories[cm.category]
    print_at(SummaryData.contestCategoryName(category), 4, 25)
  end
  if eff then print_lines(SummaryData.contestEffectDescription(eff), 0, 65, NARROW) end
  draw_hearts(eff)
end

local function draw_list()
  local moves = RseRelearner.moves()
  local ox, oy = WIN_LIST.left * 8, WIN_LIST.top * 8
  local pitch = Window.optionHeight()
  for i = 1, shown() do
    local idx = RseRelearner.scroll + i
    local y = oy + 1 + (i - 1) * pitch
    -- pokeemerald/src/move_relearner.c:913
    local label = moves[idx] and Pokemon.moveName(moves[idx]) or RomText.plain("gText_Cancel")
    Window.printPx(label, ox + 8, y)
  end
  Window.cursorPx(ox, oy + 1 + (RseRelearner.cursor - RseRelearner.scroll - 1) * pitch)
end

local function draw_arrows()
  local BagChrome = require("src.ui.game3.rse.bag_chrome")
  local t = RseRelearner.t
  for _, a in ipairs(MODE_ARROWS) do BagChrome.drawArrow(a[1], a[2], a[3], t) end
  if RseRelearner.scroll > 0 then BagChrome.drawArrow("up", LIST_UP[1], LIST_UP[2], t) end
  if RseRelearner.scroll < total_rows() - shown() then BagChrome.drawArrow("down", LIST_DOWN[1], LIST_DOWN[2], t) end
end

function RseRelearner.draw()
  if not RseRelearner.open then return end
  if not (love and love.graphics) then return end
  if RseRelearner._opts and RseRelearner._opts.draw then return RseRelearner._opts.draw(RseRelearner) end
  -- pokeemerald/src/move_relearner.c:415
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  -- pokeemerald/src/menu_specialized.c:703 InitMoveRelearnerWindows
  frame(WIN_DESC)
  frame(WIN_LIST)
  frame(WIN_MSG)

  local moveId = selected_move()
  if RseRelearner.contest then draw_contest(moveId) else draw_battle(moveId) end
  draw_list()
  if RseRelearner.state == "list" then draw_arrows() end

  if RseRelearner.prompt then
    local y = WIN_MSG.top * 8 + 1
    for line in (RseRelearner.prompt .. "\n"):gmatch("(.-)\n") do
      Window.printPx(line, WIN_MSG.left * 8, y)
      y = y + FrlgFont.linePitch()
    end
  end

  if RseRelearner.state == "yesno" then
    -- pokeemerald/src/menu_specialized.c:874 MoveRelearnerCreateYesNoMenu
    frame(WIN_YESNO)
    local ox, oy = WIN_YESNO.left * 8, WIN_YESNO.top * 8 + 1
    local pitch = Window.optionHeight()
    Window.printPx(RomText.plain("gText_Yes"), ox + 8, oy)
    Window.printPx(RomText.plain("gText_No"), ox + 8, oy + pitch)
    Window.cursorPx(ox, oy + (RseRelearner.yesNoCursor - 1) * pitch)
  end
end

return RseRelearner
