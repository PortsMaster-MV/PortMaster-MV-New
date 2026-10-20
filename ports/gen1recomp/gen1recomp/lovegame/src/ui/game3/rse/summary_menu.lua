local Kit = require("src.ui.game3.rse.scene_kit")
local PalText = require("src.ui.game3.rse.pal_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Pokemon = require("src.core.game3.pokemon")
local ItemsData = require("src.core.game3.items_data")
local SummaryData = require("src.core.game3.summary_data")
local Strings = require("src.core.Strings")

local RseSummary = {}

RseSummary.SUB = "rse/summary"

-- pokeemerald/src/pokemon_summary_screen.c:51
RseSummary.PAGE = { INFO = 0, SKILLS = 1, BATTLE_MOVES = 2, CONTEST_MOVES = 3 }

-- pokeemerald/src/pokemon_summary_screen.c:59
local W = {
  INFO_TITLE = 0, SKILLS_TITLE = 1, BATTLE_TITLE = 2, CONTEST_TITLE = 3,
  PROMPT_CANCEL = 4, PROMPT_INFO = 5, PROMPT_SWITCH = 6,
  TYPE = 9, STATS_LEFT = 10, STATS_RIGHT = 11, EXP = 12, STATUS = 13,
  POWER_ACC = 14, APPEAL_JAM = 15, DEX = 17, NICK = 18, SPECIES = 19,
}

local st = { contest = false }
RseSummary._st = st

local quads = {}

local function manifest()
  return Kit.manifest(RseSummary.SUB)
end

local function se(name)
  pcall(function() require("src.core.game3.audio").playSe(name) end)
end

local function bankPal(m, bank)
  local out = {}
  for i = 1, 16 do out[i] = m.palette[bank * 16 + i] or 0 end
  return out
end

local function textColors(m, id)
  local tc = m.textColors
  return { tc[id * 3 + 1] or 0, tc[id * 3 + 2] or 1, tc[id * 3 + 3] or 2 }
end

local function win(m, idx)
  return m.windows[idx + 1]
end

local function put(m, w, text, x, y, colorId, ctx)
  if not w then return end
  ctx = ctx or {}
  ctx.pal = bankPal(m, w.paletteNum)
  ctx.colors = textColors(m, colorId or 1)
  return PalText.draw(text, w.left * 8 + x, w.top * 8 + y, ctx)
end

local function width(text, ctx)
  return PalText.width(text, ctx)
end

-- pokeemerald/src/string_util.c:163
local function pad(n, digits)
  local str = tostring(n)
  local gap = (digits - #str) * FrlgFont.measure("0")
  if gap <= 0 then return str end
  return string.char(0xFC, 0x11, gap) .. str
end

local function quad(key, x, y, w, h, sw, sh)
  local k = key .. ":" .. x .. ":" .. y .. ":" .. w .. ":" .. h
  local q = quads[k]
  if not q then
    q = love.graphics.newQuad(x, y, w, h, sw, sh)
    quads[k] = q
  end
  return q
end

local function drawLayer(entry, x0, x1)
  local img = entry and Kit.image(entry.png)
  if not img then return end
  love.graphics.setColor(1, 1, 1, 1)
  local sw, sh = img:getDimensions()
  x0, x1 = x0 or 0, x1 or sw
  love.graphics.draw(img, quad(entry.png, x0, 0, x1 - x0, sh, sw, sh), x0, 0)
end

local function drawFrame(entry, frame, x, y)
  local img = entry and Kit.image(entry.png)
  if not img then return end
  local sw, sh = img:getDimensions()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, quad(entry.png, 0, frame * entry.h, entry.w, entry.h, sw, sh), x, y)
end

local function drawTile(m, key, i, x, y)
  local t = m.tiles
  local img = t and Kit.image(t.png)
  if not img then return end
  local idx = t.index[key]
  local sw, sh = img:getDimensions()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, quad(t.png, (idx.start + i) * 8, 0, 8, 8, sw, sh), x, y)
end

local function S()
  return require("src.ui.game3.summary_menu")
end

local function currentMon(Sm)
  local p = Sm._party
  return p and p[Sm._cursor]
end

local function isEgg(mon)
  return mon and Pokemon.isEgg and Pokemon.isEgg(mon) or false
end

-- pokeemerald/src/pokemon_summary_screen.c:3994
function RseSummary.watchMonAnim(Sm)
  local MonAnim = require("src.core.game3.mon_anim")
  st.monWatch = require("src.core.game3.task").spawn(function()
    if not Sm.open then
      st.monWatch, st.monSprite = nil, nil
      return true
    end
    local mon = currentMon(Sm)
    local sprite = st.monSprite
    if mon and (not sprite or sprite.mon ~= mon) then
      local m = manifest()
      local egg = isEgg(mon)
      local flip = not egg and not (m and m.noFlip and m.noFlip[tonumber(Pokemon.speciesOf(mon)) or -1])
      local sp = egg and Pokemon.SPECIES_EGG or tonumber(Pokemon.speciesOf(mon)) or 0
      sprite = MonAnim.newSprite(sp, { affineMode = "off", hFlip = flip })
      sprite.mon, sprite.data[0] = mon, sp
      sprite.callback = function(s)
        s.data[1] = flip and 0 or 1
        MonAnim.summary(s, sp, egg)
      end
      st.monSprite = sprite
    end
    if sprite then MonAnim.step(sprite, true) end
  end)
end

-- pokeemerald/src/pokemon_summary_screen.c:1761
function RseSummary.page(Sm)
  Sm = Sm or S()
  local p = Sm._page
  if p == Sm.PAGE_EGG then return RseSummary.PAGE.INFO, true end
  if p == Sm.PAGE_MOVES or p == Sm.PAGE_MOVES_INFO or Sm._mode == "select_move" then
    return st.contest and RseSummary.PAGE.CONTEST_MOVES or RseSummary.PAGE.BATTLE_MOVES
  end
  return p
end

function RseSummary.detail(Sm)
  Sm = Sm or S()
  return Sm._page == Sm.PAGE_MOVES_INFO or Sm._mode == "select_move"
end

local function filtered(input, blocked)
  return setmetatable({}, { __index = function(_, k)
    if k == "wasPressed" then
      return function(_, key) if blocked[key] then return false end return input:wasPressed(key) end
    elseif k == "isDown" then
      return function(_, key) if blocked[key] or not input.isDown then return false end return input:isDown(key) end
    end
    local v = input[k]
    if type(v) == "function" then return function(_, ...) return v(input, ...) end end
    return v
  end })
end

-- pokeemerald/src/pokemon_summary_screen.c:1532
function RseSummary.handleInput(input, Sm)
  Sm = Sm or S()
  if not input then return Sm.handleInput(input) end
  local lr = false
  pcall(function() lr = require("src.core.game3.options").lrMode(Sm._playerState) end)
  local right = input:wasPressed("right") or (lr and input:wasPressed("r"))
  local left = input:wasPressed("left") or (lr and input:wasPressed("l"))
  local movesPage = Sm._page == Sm.PAGE_MOVES and not (Sm._slide and Sm._slide.active)
  local selecting = Sm._mode == "select_move"
  if (movesPage or selecting) and right and not st.contest then
    st.contest = true
    se("SE_SELECT")
    return
  end
  if (movesPage or selecting) and left and st.contest then
    st.contest = false
    se("SE_SELECT")
    return
  end
  if movesPage and right then return end
  if selecting and (left or right) then return end
  if Sm._page ~= Sm.PAGE_MOVES and Sm._page ~= Sm.PAGE_MOVES_INFO and not selecting then st.contest = false end
  require("src.ui.game3.screens").withTextAliases(Sm._playerState, Sm.handleInput, input)
end

local function moveList(Sm, mon)
  local out = {}
  for i = 1, 4 do
    local e = mon.moves and mon.moves[i]
    local id = type(e) == "table" and (e.id or e.move or e.moveId) or e
    id = tonumber(id)
    if not id and type(e) == "string" then
      local C = require("src.core.game3.constants").of(Sm._playerState or Sm._session)
      id = C and C:id("moves", e)
    end
    if not id and type(e) == "string" and Pokemon.battleMoveId then
      id = Pokemon.battleMoveId(e)
    end
    if id and id > 0 then
      local pp = type(e) == "table" and e.pp or (mon.pp and mon.pp[i])
      local def = Pokemon.battleMove(id)
      local maxPp = tonumber(mon.maxPp and mon.maxPp[i]) or (def and def.pp) or 0
      out[i] = { id = id, pp = tonumber(pp) or maxPp, maxPp = maxPp, def = def }
    end
  end
  if (Sm._mode == "select_move" or Sm._moveToLearn) and Sm._moveToLearn then
    local id = tonumber(Sm._moveToLearn)
    if not id and type(Sm._moveToLearn) == "string" then
      local C = require("src.core.game3.constants").of(Sm._playerState or Sm._session)
      id = C and C:id("moves", Sm._moveToLearn)
    end
    if not id and type(Sm._moveToLearn) == "string" and Pokemon.battleMoveId then
      id = Pokemon.battleMoveId(Sm._moveToLearn)
    end
    local def = id and Pokemon.battleMove(id)
    if id then
      local pp = (def and def.pp) or 5
      out[5] = { id = id, pp = pp, maxPp = pp, def = def }
    end
  end
  return out
end

-- pokeemerald/src/battle_message.c:3047
local function ppState(cur, max)
  if max == cur then return 3 end
  if max <= 2 then return cur > 1 and 3 or 2 - cur end
  if max <= 7 then return cur > 2 and 3 or 2 - cur end
  if cur == 0 then return 2 end
  if cur <= math.floor(max / 4) then return 1 end
  if cur > math.floor(max / 2) then return 3 end
  return 0
end

local function contestMove(id)
  local c = Kit.loadLua("data/generated/gba/pokemon/contest_moves.lua")
  return c and c.moves and c.moves[id], c
end

-- pokeemerald/src/pokemon_summary_screen.c:2338
local function drawPagination(m, page, minPage, maxPage)
  local ids = {}
  for i = 0, 3 do
    local a, b
    if i < minPage then a, b = 0x40, 0x40
    elseif i > maxPage then a, b = 0x4A, 0x4A
    elseif i < page then a, b = 0x46, 0x47
    elseif i == page then
      if i ~= maxPage then a, b = 0x41, 0x42 else a, b = 0x4B, 0x4C end
    elseif i ~= maxPage then a, b = 0x43, 0x44
    else a, b = 0x48, 0x49 end
    ids[#ids + 1] = { a, b }
  end
  for i, pair in ipairs(ids) do
    for j = 1, 2 do
      local t = pair[j]
      local x = (11 + (i - 1) * 2 + (j - 1)) * 8
      drawTile(m, "dots", t - 0x40, x, 0)
      drawTile(m, "dots", t + 0x10 - 0x40, x, 8)
    end
  end
end

local function drawTypeIcon(m, typeId, x, y)
  drawFrame(m.moveTypes, typeId, x, y)
end

local function drawPortrait(m, Sm, mon, egg, detail, page)
  local front = Pokemon.monFrontPic(mon)
  if front and front.image then
    local iw, ih = front.w or 64, front.h or 64
    love.graphics.setColor(1, 1, 1, 1)
    -- pokeemerald/src/pokemon_summary_screen.c:3986
    local flip = not egg and not (m.noFlip and m.noFlip[tonumber(Pokemon.speciesOf(mon)) or -1])
    local MonAnim = require("src.core.game3.mon_anim")
    if MonAnim.enabled() and not st.monWatch then RseSummary.watchMonAnim(Sm) end
    local sprite = st.monSprite
    if sprite and sprite.mon ~= mon then sprite = nil end
    if sprite then
      local pic = MonAnim.framePic(Pokemon.monPicSpecies(mon), sprite.frame, Pokemon.isShiny(mon)) or front
      MonAnim.draw(sprite, pic.image, 40, 64)
    elseif flip then
      love.graphics.draw(front.image, 40 + iw / 2, 64 - ih / 2, 0, -1, 1)
    else
      love.graphics.draw(front.image, 40 - iw / 2, 64 - ih / 2)
    end
  end
  -- pokeemerald/src/pokemon_summary_screen.c:4048
  if m.markings then
    drawFrame(m.markings, (tonumber(mon.markings) or 0) % 16, 60 - 16, 26 - 4)
  end
  local inMoveDetail = (detail == true) and (page ~= nil and page >= 2)
  -- pokeemerald/src/pokemon_summary_screen.c:4074 (hidden in move detail mode)
  if not inMoveDetail then
    local okB, Ui = pcall(require, "src.core.game3.battle.ui")
    if okB and Ui.ballQuad then
      local BallOpen = require("src.core.game3.battle.ball_open")
      local ok2, img, q = pcall(Ui.ballQuad, BallOpen.ballIdForItem(not egg and mon.pokeball or 0), 0)
      if ok2 and img then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, q, 16 - 8, 136 - 8)
      end
    end
  end
  local session = Sm._playerState
  -- pokeemerald/src/pokemon_summary_screen.c:2750
  if egg then
    put(m, win(m, W.NICK), Pokemon.displayName(mon), 0, 1, 1)
    return
  end
  local nat = Sm.dexNumber and Sm.dexNumber(Pokemon.speciesOf(mon), session)
  if nat then
    local shiny = SummaryData.isShiny(mon)
    put(m, win(m, W.DEX), RomText.plain("gText_NumberClear01") .. string.format("%03d", nat), 0, 1, shiny and 7 or 1)
  end
  put(m, win(m, W.NICK), Pokemon.displayName(mon), 0, 1, 1)
  -- pokeemerald/src/pokemon_summary_screen.c:2320 PSS_LABEL_WINDOW_PORTRAIT_SPECIES is cleared in move detail mode
  if not inMoveDetail then
    local sp = win(m, W.SPECIES)
    put(m, sp, RomText.plain("gText_LevelSymbol") .. tostring(tonumber(mon.level) or 1), 24, 17, 1)
    put(m, sp, "/" .. (Pokemon.name(Pokemon.speciesOf(mon)) or ""), 0, 1, 1)
    local g = SummaryData.gender(mon)
    if g == "M" then put(m, sp, "gText_MaleSymbol", 57, 17, 3)
    elseif g == "F" then put(m, sp, "gText_FemaleSymbol", 57, 17, 4) end
  end
end

-- pokeemerald/src/pokemon_summary_screen.c:2838
local function drawTitles(m, page, detail, Sm)
  local titles = { [0] = "gText_PkmnInfo", "gText_PkmnSkills", "gText_BattleMoves", "gText_ContestMoves" }
  put(m, win(m, page), titles[page], 2, 1, 1)
  local prompt
  if page == 0 then prompt = { W.PROMPT_CANCEL, "gText_Cancel2" }
  elseif page >= 2 and not detail then prompt = { W.PROMPT_INFO, "gText_Info" }
  elseif page >= 2 and detail and Sm._mode ~= "select_move" then prompt = { W.PROMPT_SWITCH, "gText_Switch" } end
  if prompt then
    local w = win(m, prompt[1])
    local sx = 62 - width(prompt[2])
    local ix = math.max(0, sx - 16)
    FrlgFont.drawKeypadIcon(0x00, w.left * 8 + ix + 4, w.top * 8 + 2)
    put(m, w, prompt[2], sx, 1, 0)
  end
end

local function pageWin(m, group, idx)
  return m.pageWindows[group][idx + 1]
end

-- pokeemerald/src/pokemon_summary_screen.c:3078
local function drawInfo(m, Sm, mon, egg)
  local session = Sm._playerState or {}
  if egg then
    local ot = pageWin(m, "info", 0)
    put(m, ot, "gText_OTSlash", 0, 1, 1)
    put(m, ot, "gText_FiveMarks", width("gText_OTSlash"), 1, 1)
    local idText = RomText.plain("gText_IDNumber2") .. RomText.plain("gText_FiveMarks")
    put(m, pageWin(m, "info", 1), idText, 56 - width(idText), 1, 1)
    -- pokeemerald/src/pokemon_summary_screen.c:3258
    local f = tonumber(mon.friendship or mon.eggCycles) or 40
    local key = mon.isBadEgg and "gText_EggWillTakeALongTime" or f <= 5 and "gText_EggAboutToHatch"
      or f <= 10 and "gText_EggWillHatchSoon" or f <= 40 and "gText_EggWillTakeSomeTime" or "gText_EggWillTakeALongTime"
    put(m, pageWin(m, "info", 2), key, 0, 1, 0)
    put(m, pageWin(m, "info", 3), "gText_OddEggFoundByCouple", 0, 1, 0)
    return
  end
  put(m, win(m, W.TYPE), "gText_TypeSlash", 0, 1, 0)
  local types = Pokemon.types(Pokemon.speciesOf(mon)) or {}
  local t1, t2 = tonumber(types[1] or types.type1), tonumber(types[2] or types.type2)
  -- pokeemerald/src/pokemon_summary_screen.c:3827
  if t1 then drawTypeIcon(m, t1, 120, 48) end
  if t2 and t2 ~= t1 then drawTypeIcon(m, t2, 160, 48) end
  local ot = pageWin(m, "info", 0)
  put(m, ot, "gText_OTSlash", 0, 1, 1)
  local otName = tostring(mon.otName or mon.ot or "")
  put(m, ot, otName, width("gText_OTSlash"), 1, (tonumber(mon.otGender) or 0) == 0 and 5 or 6)
  local idText = RomText.plain("gText_IDNumber2") .. string.format("%05d", (tonumber(mon.otId) or 0) % 65536)
  put(m, pageWin(m, "info", 1), idText, 56 - width(idText), 1, 1)
  local ability = tonumber(mon.ability or mon.abilityId) or Pokemon.abilityId(Pokemon.speciesOf(mon), mon.personality) or 0
  local aName = Pokemon.abilityName(ability) or ""
  put(m, pageWin(m, "info", 2), aName, 0, 1, 1)
  put(m, pageWin(m, "info", 2), SummaryData.abilityDescription(ability, aName), 0, 17, 0)
  -- pokeemerald/src/pokemon_summary_screen.c:3116
  local natureId = SummaryData.nature(mon)
  local sections = Kit.loadLua("data/generated/gba/region_map/map_sections.lua")
  local sec = tonumber(mon.metLocation)
  local secName = sec and sections and sections.sections and sections.sections[sec] and sections.sections[sec].name
  local metLevel = tonumber(mon.metLevel) or 0
  local own = otName == tostring(session.name or session.playerName or "")
    and ((tonumber(mon.otId) or 0) % 65536) == ((tonumber(session.trainerId) or 0) % 65536)
  local key
  if own then
    if metLevel == 0 then key = secName and "gText_XNatureHatchedAtYZ" or "gText_XNatureHatchedSomewhereAt"
    else key = secName and "gText_XNatureMetAtYZ" or "gText_XNatureMetSomewhereAt" end
  else
    key = secName and "gText_XNatureProbablyMetAt" or "gText_XNatureObtainedInTrade"
  end
  put(m, pageWin(m, "info", 3), key, 0, 1, 0, {
    dynamic = {
      [0] = RomText.ir("sMemoNatureTextColor"), [1] = RomText.ir("sMemoMiscTextColor"),
      [2] = RomText.at("gNatureNamePointers", natureId), [3] = tostring(metLevel == 0 and 5 or metLevel),
      [4] = secName and Strings(secName) or "", [5] = RomText.ir("gText_EmptyString5"),
    },
  })
end

-- pokeemerald/src/pokemon_summary_screen.c:3301
local function drawSkills(m, Sm, mon)
  local item = tonumber(mon.item or mon.heldItem) or 0
  local itemText = item == 0 and RomText.plain("gText_None") or ItemsData.displayName(item)
  put(m, pageWin(m, "skills", 0), itemText, math.floor((72 - width(itemText)) / 2) + 6, 1, 0)
  local ribbons = require("src.core.game3.rse.ribbons").count(mon)
  local ribText = ribbons == 0 and RomText.plain("gText_None")
    or RomText.plain("gText_RibbonsVar1", { stringVars = { string.format("%2d", ribbons) } })
  put(m, pageWin(m, "skills", 1), ribText, math.floor((70 - width(ribText)) / 2) + 6, 1, 0)
  local stats = mon.stats or {}
  local function stat(k, alt) return tonumber(mon[alt] or mon[k] or stats[alt] or stats[k]) or 0 end
  local hp, maxHp = tonumber(mon.hp) or 0, tonumber(mon.maxHp or stats.hp) or 0
  local left = pad(hp, 3) .. "/" .. pad(maxHp, 3) .. "\n" .. pad(stat("atk", "attack"), 7) .. "\n" .. pad(stat("def", "defense"), 7)
  put(m, pageWin(m, "skills", 2), left, 4, 1, 0)
  local right = pad(stat("spa", "spAtk"), 3) .. "\n" .. pad(stat("spd", "spDef"), 3) .. "\n" .. pad(stat("spe", "speed"), 3)
  put(m, pageWin(m, "skills", 3), right, 2, 1, 0)
  local lw = win(m, W.STATS_LEFT)
  for i, key in ipairs({ "gText_HP4", "gText_Attack3", "gText_Defense3" }) do
    put(m, lw, key, 6 + math.floor((42 - width(key)) / 2), 1 + (i - 1) * 16, 1)
  end
  local rw = win(m, W.STATS_RIGHT)
  for i, key in ipairs({ "gText_SpAtk4", "gText_SpDef4", "gText_Speed2" }) do
    put(m, rw, key, 2 + math.floor((36 - width(key)) / 2), 1 + (i - 1) * 16, 1)
  end
  local ew = win(m, W.EXP)
  put(m, ew, "gText_ExpPoints", 6, 1, 1)
  put(m, ew, "gText_NextLv", 6, 17, 1)
  local prog = SummaryData.expProgress(mon, Pokemon.growthRate(Pokemon.speciesOf(mon)))
  local exp = tostring(prog.totalExp)
  local nxt = tostring(prog.level < 100 and prog.expNeeded or 0)
  local xw = pageWin(m, "skills", 4)
  put(m, xw, exp, 42 - width(exp) + 2, 1, 0)
  put(m, xw, nxt, 42 - width(nxt) + 2, 17, 0)
  -- pokeemerald/src/pokemon_summary_screen.c:2651
  local ticks = 0
  if prog.level < 100 and prog.levelTotalExp > 0 then
    ticks = math.floor(prog.expProgress * 64 / prog.levelTotalExp)
    if ticks == 0 and prog.expProgress ~= 0 then ticks = 1 end
  end
  for i = 0, 7 do
    local t = ticks > 7 and 8 or (ticks % 8)
    drawTile(m, "exp", t, (21 + i) * 8, 18 * 8)
    ticks = math.max(0, ticks - 8)
  end
end

local function drawMoveSelector(m, row, endFrame, midFrame)
  local y = 40 + (row - 1) * 16 - 8
  for i = 0, 9 do
    local x = i * 16 + 89 - 8
    if i == 9 then
      local img = Kit.image(m.moveSelect.png)
      if img then
        local sw, sh = img:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, quad(m.moveSelect.png, 0, endFrame * 16, 16, 16, sw, sh), x + 16, y, 0, -1, 1)
      end
    else
      drawFrame(m.moveSelect, i == 0 and endFrame or midFrame, x, y)
    end
  end
end

-- pokeemerald/src/pokemon_summary_screen.c:3527
local function drawMoves(m, Sm, mon, contest, detail)
  local moves = moveList(Sm, mon)
  local nw, pw = pageWin(m, "moves", 0), pageWin(m, "moves", 1)
  local _, cmData = contestMove(0)
  local count = (Sm._mode == "select_move" and moves[5]) and 5 or 4
  for i = 1, count do
    local mv = moves[i]
    local y = (i - 1) * 16 + 1
    if mv then
      put(m, nw, Pokemon.moveName(mv.id) or "", 0, y, 1)
      local text = "{PP}" .. pad(mv.pp, 2) .. "/" .. pad(mv.maxPp, 2)
      local state = ppState(mv.pp, mv.maxPp)
      put(m, pw, text, 44 - width(text), y, state + 9)
      if contest then
        local cm = contestMove(mv.id)
        -- pokeemerald/src/pokemon_summary_screen.c:3860
        drawTypeIcon(m, 18 + (cm and cm.category or 0), 85, 32 + (i - 1) * 16)
      elseif mv.def then
        drawTypeIcon(m, tonumber(mv.def.type) or 0, 85, 32 + (i - 1) * 16)
      end
    else
      put(m, nw, "gText_OneDash", 0, y, 1)
      put(m, pw, "gText_TwoDashes", math.floor((44 - width("gText_TwoDashes")) / 2), y, 12)
    end
  end
  if not detail then return end
  local cur = Sm._moveCursor or 1
  local sel = moves[cur]
  -- pokeemerald/src/pokemon_summary_screen.c:4112
  local swapSlot = Sm._swapSlot
  if (swapSlot ~= nil) ~= st.swapping then
    st.swapping = swapSlot ~= nil
    st.blink = 0
  end
  st.blink = ((st.blink or 0) + 1) % 32
  local visible = st.blink <= 24
  if swapSlot then
    -- pokeemerald/src/pokemon_summary_screen.c:2043
    drawMoveSelector(m, swapSlot, 6, 7)
    if visible then drawMoveSelector(m, cur, 4, 5) end
  elseif visible then
    drawMoveSelector(m, cur, 4, 5)
  end
  if not sel then return end
  local dw = pageWin(m, "moves", 2)
  if contest then
    local cm = contestMove(sel.id)
    local eff = cm and cmData and cmData.effects and cmData.effects[cm.effect]
    local aj = win(m, W.APPEAL_JAM)
    put(m, aj, "gText_Appeal", 0, 1, 1)
    put(m, aj, "gText_Jam", 0, 17, 1)
    if eff then
      -- pokeemerald/src/pokemon_summary_screen.c:2693
      local appeal = eff.appeal ~= 0xFF and math.floor(eff.appeal / 10) or 0
      local jam = eff.jam ~= 0xFF and math.floor(eff.jam / 10) or 0
      for i = 0, 7 do
        local tx, ty = 6 + (i % 4), 15 + math.floor(i / 4)
        drawTile(m, "hearts", i < appeal and 1 or 0, tx * 8, ty * 8)
        drawTile(m, "hearts", i < jam and 3 or 4, tx * 8, (ty + 2) * 8)
      end
      put(m, dw, SummaryData.contestEffectDescription(eff), 6, 1, 0)
    end
  else
    local pa = win(m, W.POWER_ACC)
    put(m, pa, "gText_Power", 0, 1, 1)
    put(m, pa, "gText_Accuracy2", 0, 17, 1)
    local def = sel.def or {}
    local power = (tonumber(def.power) or 0) < 2 and RomText.plain("gText_ThreeDashes") or pad(def.power, 3)
    local acc = (tonumber(def.accuracy) or 0) == 0 and RomText.plain("gText_ThreeDashes") or pad(def.accuracy, 3)
    put(m, pa, power, 53, 1, 0)
    put(m, pa, acc, 53, 17, 0)
    put(m, dw, SummaryData.moveDescription(sel.id, Pokemon.moveName(sel.id)), 6, 1, 0)
  end
end

function RseSummary.draw(Sm)
  Sm = Sm or S()
  if not Sm.open then return end
  local m = manifest()
  if not m then return Sm.draw() end
  local mon = currentMon(Sm)
  if not mon then return end
  local page, egg = RseSummary.page(Sm)
  local detail = RseSummary.detail(Sm)
  local bd = Kit.color555(m.palette[1] or 0)
  love.graphics.setColor(bd)
  love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  local L = m.layers
  drawLayer(egg and L.info_egg or L.info)
  local ailment = not egg and SummaryData.statusAilment(mon) or 0
  if ailment > 0 and m.statusPlate then
    drawFrame({ png = m.statusPlate.png, w = 80, h = 16 }, 0, m.statusPlate.x, m.statusPlate.y)
  end
  if page == 1 then drawLayer(L.skills, 80, 240) end
  if page == 2 then drawLayer(L.battle_moves, detail and 0 or 80, 240) end
  if page == 3 then drawLayer(L.contest_moves, detail and 0 or 80, 240) end
  local minPage, maxPage = 0, egg and 0 or 3
  if Sm._mode == "select_move" then minPage, maxPage = 2, 3 end
  drawPagination(m, page, minPage, maxPage)
  drawTitles(m, page, detail, Sm)
  drawPortrait(m, Sm, mon, egg, detail, page)
  if ailment > 0 and not detail then
    -- pokeemerald/src/pokemon_summary_screen.c:1493
    put(m, win(m, W.STATUS), "gText_Status", 2, 1, 1)
    drawFrame(m.status, ailment - 1, 64 - 16, 152 - 4)
  end
  if page == 0 then drawInfo(m, Sm, mon, egg)
  elseif page == 1 then drawSkills(m, Sm, mon)
  else drawMoves(m, Sm, mon, page == 3, detail) end
end

function RseSummary.reset()
  st.contest = false
  if st.monWatch then require("src.core.game3.task").cancel(st.monWatch.id) end
  st.monWatch, st.monSprite = nil, nil
end

return RseSummary
