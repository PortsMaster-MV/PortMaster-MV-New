local Base = require("src.ui.game3.rse.move_relearner")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Pokemon = require("src.core.game3.pokemon")
local IR = require("src.core.game3.scripting.text_ir")
local bit = require("bit")
local UI = {}
local keys = {gText_TeachWhichMoveToPkmn = "gOtherText_TeachWhichMove",
  gText_MoveRelearnerGiveUp = "gOtherText_GiveUpTeachingMove",
  gText_MoveRelearnerTeachMoveConfirm = "gOtherText_TeachSpecificMove"}
local function manifest()
  local m = Kit.manifest(Base.SUB)
  assert(m.assetLayout == "rs", "native RS move tutor pack required")
  return m
end
local function text(key, ctx)
  local m, native = manifest(), keys[key] or key
  return IR.toPlain(IR.decode(assert(m.textBytes[native], "native tutor text " .. native), {dialect = "rs"}), ctx or {})
end
local function pages(key, vars)
  local out = {}
  local value = IR.toAscii(IR.decode(assert(manifest().textBytes[key]), {dialect = "rs"}), {stringVars = vars})
  for page in (value .. "\\p"):gmatch("(.-)\\p") do if page ~= "" then out[#out + 1] = page end end
  return out
end
local function sequence(api, list, after)
  local function nextPage(i)
    if i > #list then return after() end
    api.message(list[i], function() nextPage(i + 1) end)
  end
  nextPage(1)
end
local function startLearn(st, move, api)
  local mon = st._mon
  local vars = {Pokemon.displayMonName(mon), Pokemon.moveName(move)}
  local function fanfare() require("src.core.game3.audio").playFanfare("MUS_LEVEL_UP") end
  local function success()
    fanfare()
    sequence(api, pages("gOtherText_PokeLearnedMove", vars), function() Base.finish(true) end)
  end
  if Pokemon.moveSlotCount(mon) < 4 then
    if Pokemon.teachMove(mon, move) then success() else api.toList() end
    return
  end
  local deletePrompt, stopPrompt, chooseForget
  stopPrompt = function()
    api.yesNo(text("gOtherText_StopLearningMove", {stringVars = vars}), function(stop)
      if stop then api.toList() else deletePrompt() end
    end)
  end
  chooseForget = function()
    sequence(api, pages("gOtherText_WhichMoveToForget", vars), function()
      api.forget(nil, function(slot)
        if slot == nil or slot < 0 or slot >= 4 then return stopPrompt() end
        local old = Pokemon.moveIdAt(mon, slot + 1)
        local forgotten = Pokemon.replaceMove(mon, slot + 1, move)
        if not forgotten then return chooseForget() end
        if type(mon.ppBonusesPacked) == "number" then
          mon.ppBonusesPacked = bit.band(mon.ppBonusesPacked, bit.bnot(bit.lshift(3, slot * 2)))
        end
        for _, name in ipairs({"ppBonuses", "ppBonus", "ppUp"}) do
          if type(mon[name]) == "table" then mon[name][slot + 1] = 0 end
        end
        vars[3] = Pokemon.moveName(old)
        sequence(api, pages("gOtherText_ForgotMove123", vars), function()
          fanfare()
          sequence(api, pages("gOtherText_ForgotOrDidNotLearnMove", vars), function() Base.finish(true) end)
        end)
      end)
    end)
  end
  deletePrompt = function()
    local p = pages("gOtherText_DeleteOlderMove", vars)
    local question = table.remove(p)
    sequence(api, p, function() api.yesNo(question, function(yes) if yes then chooseForget() else stopPrompt() end end) end)
  end
  deletePrompt()
end

local function colors(m)
  local w = m.windows.text
  return {font = "native_" .. w.fontNum, linePitch = 16, maxWidth = 240,
    colors = Kit.messageColors("std_menu", w.foregroundColor + 1, w.backgroundColor + 1, w.shadowColor + 1)}
end
local function arrow(a, frame, x, y)
  local img = Kit.image(a.png)
  local sw, sh = img:getDimensions()
  local q = love.graphics.newQuad(0, frame * a.h, a.w, a.h, sw, sh)
  love.graphics.draw(img, q, x - a.w / 2, y - a.h / 2)
end
function UI.draw(st)
  local m, Chrome = manifest(), require("src.ui.game3.chrome")
  local opts = colors(m)
  local function print(value, x, y) Font.draw(tostring(value or ""), x, y, opts) end
  local function bounded(value, x, y, width)
    local narrow = {}; for k, v in pairs(opts) do narrow[k] = v end
    narrow.maxWidth = width
    Font.draw(tostring(value or ""), x, y, narrow)
  end
  local function aligned(value, x, y, width)
    value = tostring(value or ""); print(value, x + width - Font.measure(value, opts), y)
  end
  love.graphics.setColor(0, 0, 0, 1); love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  for _, f in ipairs(m.frames) do Chrome.stdFrame(f[1] + 1, f[2] + 1, f[3] - f[1] - 1, f[4] - f[2] - 1) end
  for _, h in ipairs(m.headers[st.contest and "contest" or "battle"]) do aligned(h.text, h.x * 8, h.y * 8, 64) end
  local moves = st.moves()
  local contest = Kit.loadLua("data/generated/gba/pokemon/contest_moves.lua")
  local typeNames = assert(Kit.loadLua("data/generated/gba/pokemon/type_names.lua"), "native RS type names missing")
  for row = 1, 3 do
    local id = moves[st.scroll + row]
    local y = 8 + (row - 1) * 16
    if id then
      local data = Pokemon.battleMove(id)
      local category = contest.moves[id].category
      local kind = st.contest and contest.categories[category] or assert(typeNames[tonumber(data.type)], "native RS move type missing")
      print(kind, 88, y); print(Pokemon.moveName(id), 127, y)
      print("PP/", 202, y); aligned(data.pp, 202, y, 30)
    elseif st.scroll + row == #moves + 1 then print(text("gOtherText_Exit"), 88, y) end
  end
  require("src.ui.game3.rs.menu_cursor").draw(88, 8 + (st.cursor - st.scroll - 1) * 16, 144)
  local id = moves[st.cursor]
  if id then
    if st.contest then
      local row = contest.moves[id]
      local eff = contest.effects[row.effect]
      bounded(eff.description, 88, 72, 144)
      local h = m.hearts
      local img = Kit.image(h.png); local sw, sh = img:getDimensions()
      for j, value in ipairs({eff.appeal, eff.jam}) do
        local count = math.floor(value / 10); if count == 255 then count = 0 end
        for i = 0, 7 do
          local frame = j == 1 and (i < count and h.names.appealFull or h.names.appealEmpty)
            or (i < count and h.names.jamFull or h.names.jamEmpty)
          love.graphics.draw(img, love.graphics.newQuad(0, frame * h.h, h.w, h.h, sw, sh),
            28 + i % 4 * 8 - h.w / 2, (j == 1 and 52 or 92) + math.floor(i / 4) * 8 - h.h / 2)
        end
      end
    else
      local data = Pokemon.battleMove(id)
      aligned(data.power < 2 and text("gOtherText_ThreeDashes2") or data.power, 24, 48, 32)
      aligned(data.accuracy == 0 and text("gOtherText_ThreeDashes2") or data.accuracy, 24, 88, 32)
      bounded(require("src.core.game3.summary_data").moveDescription(id, Pokemon.moveName(id)), 88, 72, 144)
    end
  end
  if st.prompt then
    bounded(st.prompt, 24, 120, 192)
  end
  if st.state == "yesno" then
    Chrome.stdFrame(22, 8, 5, 4)
    local Text = require("src.core.game3.rom_text")
    print(Text.plain("OtherText_Yes"), 176, 64); print(Text.plain("OtherText_No"), 176, 80)
    require("src.ui.game3.rs.menu_cursor").draw(176, 64 + (st.yesNoCursor - 1) * 16, 40)
  elseif st.state == "list" then
    local function sin(phase, amplitude)
      return math.floor(require("src.core.game3.trig").sin(phase) * amplitude / 256)
    end
    local phase = st.t * 10 % 256
    arrow(m.arrows.horizontal, 0, 8 - sin(phase, 3), 16)
    arrow(m.arrows.horizontal, 1, 72 + sin(phase, 3), 16)
    if st.scroll > 0 then arrow(m.arrows.vertical, 1, 160, 4 - sin(phase, 1)) end
    if st.scroll < #moves + 1 - 3 then arrow(m.arrows.vertical, 0, 160, 60 + sin(phase, 1)) end
  end
end
function UI.show(mon, opts)
  manifest(); opts = opts or {}
  opts.maxShown, opts.text, opts.draw, opts.startLearn = 3, text, UI.draw, startLearn
  return Base.show(mon, opts)
end
function UI.isOpen() return Base.isOpen() end
function UI.reset()
  Base.open, Base.state = false, "list"
  Base._onDone, Base._messageCb, Base._yesNoCb = nil, nil, nil
  require("src.ui.game3.stack").pop("move_relearner")
end
return UI
