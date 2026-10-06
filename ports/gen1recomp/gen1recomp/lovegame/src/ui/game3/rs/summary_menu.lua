local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Pokemon = require("src.core.game3.pokemon")
local RomText = require("src.core.game3.rom_text")
local SummaryData = require("src.core.game3.summary_data")
local Policy = require("src.ui.game3.rs.summary_policy")
local Pal = require("src.core.game3.pal_fade")
local Audio = require("src.core.game3.audio")
local CacheBlob = require("src.import.CacheBlob")
local S = {isMenu = true, open = false, PAGE = Policy.PAGE, MODE = Policy.MODE, policy = Policy}
local layers, tiles, quads = {}, {}, {}
local function rawMon() return S._party and S._party[S._cursor] end
local function mon() return S._loaded or rawMon() end
local function loadMon()
  S._loaded = nil
  local raw = rawMon()
  if not raw or not (S._opts.context == "box" or S._mode >= 5) then return end
  local copy = {}; for k, v in pairs(raw) do copy[k] = v end
  if copy.exp ~= nil then
    local exp, growth = tonumber(copy.exp) or 0, Pokemon.growthRate(Pokemon.speciesOf(copy))
    local level = 1
    while level <= 100 and SummaryData.expForLevel(growth, level) <= exp do level = level + 1 end
    copy.level = math.max(1, level - 1)
  end
  local stats = Pokemon.calcStats(Pokemon.speciesOf(copy), copy.level, copy.ivs, copy.evs, copy.personality)
  for k, v in pairs(stats) do copy[k] = v end
  copy.hp, copy.status = stats.maxHp, 0
  S._loaded = copy
end
function S.manifest()
  local m = assert(Kit.manifest("rse/summary"), "native RS summary pack missing")
  assert(m.layout == "rs", "native RS summary pack required")
  return m
end
local function sync()
  if S._bridge then S._bridge.open, S._bridge._cursor, S._bridge._page = S.open, S._cursor, S._page end
end
local function cry()
  if mon() and not Pokemon.isEgg(mon()) then Audio.playCry(Pokemon.speciesOf(mon())) end
end
local function linkBusy()
  return type(S._opts.linkBusy) == "function" and S._opts.linkBusy() == true
end
local function pane(amount, selected)
  S._pane = {step = amount, count = amount < 0 and 10 or 0, selected = selected or 0}
  S._detailReady = false
end
local function detailRows(open) S._detailRowsOpen = open end
function S.openMenu(party, index, opts)
  opts = opts or {}
  S._man, S._party, S._opts = S.manifest(), party or {}, opts
  S._cursor = index or 1
  S._playerState = opts.playerState or opts.session
    or require("src.core.game3.runtime").getSession()
  S._mode = Policy.mode(opts)
  S._firstPage, S._lastPage = Policy.bounds(S._mode)
  S._page = math.max(S._firstPage, math.min(S._lastPage, tonumber(opts.page) or S._firstPage))
  S._selected, S._switch, S._tick, S._noticeDelay, S._result = 0, 0, 0, nil, nil
  layers = {}
  S._pageTask, S._reload, S._pane = nil, nil, nil
  S._headerPage, S._bodyReady, S._portraitReady, S._ballReady, S._markingReady = S._page, true, true, true, true
  S._paneCount, S._detailReady, S._detailRowsOpen = 0, false, false
  S._moveToLearn = tonumber(opts.moveToLearn or opts.moveId) or 0
  S._state = (S._mode == 2 or S._mode == 3) and "select" or "normal"
  if S._state == "select" then
    S._paneCount, S._detailReady, S._detailRowsOpen = 10, true, true
    S._selectSetup = 0
  else S._selectSetup = nil end
  S._disableEdit = S._mode == 4
  loadMon()
  S._onClose, S._onSelectMove, S._bridge = opts.onClose, opts.onSelectMove, opts.bridge
  S._pal, S._fade, S.open = Pal.new(), "in", true
  S._hardwareY, S._cryPending = 16, true
  sync()
  Stack.push("summary", S, {hideBelow = true, fullscreen = true})
end
function S.isOpen() return S.open end
function S.close()
  if not S.open then return end
  S.open = false; sync()
  Audio.stopCry()
  Stack.pop("summary")
  local cb, selectCb, result = S._onClose, S._onSelectMove, S._result
  S._onClose, S._onSelectMove, S._result = nil, nil, nil
  if cb then cb(S._cursor) end
  if selectCb then selectCb(result and result < 4 and result + 1 or nil) end
end
function S.reset()
  S._onClose, S._onSelectMove = nil, nil
  S.close()
  S._party, S._bridge, S._pal, S._loaded = nil, nil, nil, nil
  layers, tiles, quads = {}, {}, {}
end
function S.update()
  if not S.open then return end
  S._tick = S._tick + 1
  if S._noticeDelay and S._noticeDelay > 0 then S._noticeDelay = S._noticeDelay - 1 end
  local cryReady = S._cryPending and S._fade ~= "in"
  if S._pane then
    local t = S._pane
    t.count = t.count + t.step
    S._paneCount = math.max(0, math.min(10, t.count))
    if t.step == 0 or t.count < 0 or t.count >= 10 then
      S._detailReady = t.count >= 10
      S._pane = nil
    end
  end
  if S._selectSetup ~= nil then
    if S._selectSetup == 5 then S._selectSetup = nil
    else S._selectSetup = S._selectSetup + 1 end
  end
  if S._pageTask then
    local t = S._pageTask
    local scrollState = t.direction < 0 and 1 or 2
    if t.state == scrollState then
      t.offset = t.offset + t.direction * 32
      if t.offset == (t.direction < 0 and 0 or 256) then t.state = t.state + 1 end
    elseif t.state == scrollState + 1 then
      S._headerPage = S._page
      t.state = t.state + 1
    elseif t.state == scrollState + 2 then
      t.dotsReady = true; t.state = t.state + 1
    elseif t.state == scrollState + 3 then
      S._bodyReady = true; t.state = t.state + 1
    elseif t.state == scrollState + 4 then
      if not linkBusy() then S._pageTask = nil end
    else t.state = t.state + 1 end
  end
  if S._reload then
    local t = S._reload
    if t.state == 0 then Audio.stopCry()
    elseif t.state == 1 then S._portraitReady = false
    elseif t.state == 2 then S._ballReady = false
    elseif t.state == 3 then S._selected = 0
    elseif t.state == 4 then loadMon()
    elseif t.state == 5 then
      t.spriteState = (t.spriteState or 0) + 1
      if t.spriteState < 3 then return end
      S._portraitReady, S._cryPending, cryReady = true, true, true
    elseif t.state == 6 then S._markingReady = true
    elseif t.state == 7 then S._ballReady = true
    elseif t.state == 8 then
      t.textState = (t.textState or 0) + 1
      if t.textState < 2 then return end
      S._bodyReady = true
    elseif not linkBusy() then S._reload = nil end
    if S._reload then t.state = t.state + 1 end
  end
  if S._fade then
    if S._fade == "in" then
      if S._hardwareY == 0 then S._hardwareY, S._fade = nil, nil
      else S._hardwareY = S._hardwareY - 1 end
    else
      S._pal:updateFade()
      if not S._pal:fadeActive() and not linkBusy() then S.close() end
    end
  end
  if cryReady and S.open then S._cryPending = false; cry() end
end
local function exit(result)
  Kit.playSe("SE_SELECT")
  S._result, S._fade = result, "out"
  S._pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
end
local function sound(fail) Kit.playSe(fail and "SE_FAILURE" or "SE_SELECT") end
local function page(delta)
  if S._pane then return false end
  if Pokemon.isEgg(mon()) then return false end
  local nextPage = S._page + delta
  if nextPage < S._firstPage or nextPage > S._lastPage then return false end
  local previous = S._page
  S._page = nextPage
  S._pageTask = {direction = delta, from = previous, offset = delta < 0 and 256 or 0, state = delta < 0 and 0 or 1}
  S._bodyReady = false
  sync(); sound(); return true
end
local function move(delta, swap)
  local key = swap and "_switch" or "_selected"
  local previous = S[key]
  S[key] = Policy.nextMove(mon(), S[key], delta, swap and 3 or 4)
  if S._moveToLearn == 0 then
    if previous == 4 and S[key] ~= 4 then pane(2, S[key])
    elseif previous ~= 4 and S[key] == 4 then pane(-2, S[key]) end
  end
  S._tick = 0; sound()
end
local function lr(input)
  local s = S._playerState or {}
  local options = s.options or s
  local mode = options.buttonMode or options.optionsButtonMode or s.optionsButtonMode
  return tonumber(mode) == 1 and input:wasPressed("l"), tonumber(mode) == 1 and input:wasPressed("r")
end
function S.handleInput(input)
  if not S.open or S._fade or S._pageTask or S._reload or S._selectSetup ~= nil or linkBusy() or not mon() then return end
  local up, down, left, right = input:wasPressed("up"), input:wasPressed("down"), input:wasPressed("left"), input:wasPressed("right")
  local l, r = lr(input); left, right = left or l, right or r
  local a, b = input:wasPressed("a"), input:wasPressed("b")
  if S._state == "notice" then
    if S._noticeDelay > 0 then return end
    if up or down then S._state = "select"; move(up and -1 or 1)
    elseif left or right then if page(left and -1 or 1) then S._state = "select" end
    elseif a or b then S._state = "select" end
  elseif S._state == "swap" then
    if up or down then move(up and -1 or 1, true)
    elseif a or b then
      sound()
      if a then
        Policy.swapMoves(rawMon(), S._selected + 1, S._switch + 1)
        loadMon()
        S._selected = S._switch
      end
      S._state = "detail"
    end
  elseif S._state == "select" or S._state == "detail" then
    if up or down then move(up and -1 or 1)
    elseif S._state == "select" and (left or right) then page(left and -1 or 1)
    elseif a then
      if S._state == "select" then
        if Policy.canForget(mon(), S._selected, S._mode) then exit(S._selected)
        else sound(true); S._state, S._noticeDelay = "notice", 4 end
      elseif S._selected == 4 or S._disableEdit then
        sound(); S._state = "normal"; detailRows(false)
        if S._selected ~= 4 then pane(-2) end
      elseif Policy.multipleMoves(mon()) then sound(); S._switch, S._state = S._selected, "swap"
      else sound(true) end
    elseif b then
      if S._state == "select" then exit(4) else
        sound(); S._state = "normal"; detailRows(false)
        if S._selected ~= 4 then pane(-2) end
      end
    end
  else
    if up or down then
      local i = Policy.nextMon(S._party, S._cursor, up and -1 or 1, S._page, S._opts, S._man)
      if i ~= S._cursor then
        if not S._loaded then local old = mon(); S._loaded = {}; for k,v in pairs(old) do S._loaded[k] = v end end
        S._cursor = i
        S._reload = {state = 0}; S._bodyReady = false
        sync(); sound()
      end
    elseif left or right then page(left and -1 or 1)
    elseif a then
      if S._page == 0 then exit()
      elseif S._page >= 2 then
        S._selected, S._state = 0, "detail"; detailRows(true); pane(2); sound()
      end
    elseif b then exit() end
  end
end
local function rgba(value)
  local r, g, b = Kit.rgb555(value); return {r, g, b, 1}
end
local function colors(id)
  local win = S._man.nativeWindow
  local c = (id == 255) and {color = win.foregroundColor, background = win.backgroundColor, shadow = win.shadowColor}
    or assert(S._man.textColors[id or 13])
  local p = S._man.palettes.bg
  local base = win.paletteNum * 16 + 1
  local background = rgba(p[base + c.background]); if c.background == 0 then background[4] = 0 end
  return {fg = rgba(p[base + c.color]), shadow = rgba(p[base + c.shadow]), bg = background}
end
function S.textOptions(id)
  return {font = "native_" .. S._man.nativeWindow.fontNum, colors = colors(id), linePitch = 16}
end
local function print(value, x, y, color, align, width)
  local opts = S.textOptions(color)
  if align == "right" then x = x - Font.measure(value, opts)
  elseif align == "center" then x = x + math.floor(((width or 0) - Font.measure(value, opts)) / 2) end
  Font.draw(value, x, y, opts)
end
local function text(key, x, y, color, align, width) print(RomText.plain(key), x, y, color, align, width) end
local function frame(entry, index, x, y)
  local image = assert(Kit.image(entry.png), entry.png)
  local key = entry.png .. ":" .. index
  if not quads[key] then quads[key] = love.graphics.newQuad(0, index * entry.h, entry.w, entry.h, image:getDimensions()) end
  love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(image, quads[key], x, y)
end
local function read(path) return assert(CacheBlob.readFs(path), path) end
local function shiny() return not Pokemon.isEgg(mon()) and Pokemon.isShiny(mon()) end
local function nativeImage(key, tile, bank, sourceOverride)
  local palette = S._man.palettes.bg
  local source = sourceOverride or read(S._man.gfx)
  local map, w, h, opaque
  if key then map, w, h = read(S._man.maps[key].path), 256, 160
  else w, h = 8, 8 end
  local data = love.image.newImageData(w, h)
  for y = 0, h - 1 do for x = 0, w - 1 do
    local attr
    if map then
      local tx, ty = math.floor(x / 8), math.floor(y / 8)
      local function word(a,b) local o = (b * 32 + a) * 2 + 1; return map:byte(o) + map:byte(o + 1) * 256 end
      attr = word(tx, ty)
      if key == "battle_moves" or key == "contest_moves" then
        if ty >= 13 and ty <= 19 and tx < 10 then
          local count = S._paneCount or 0
          attr = tx < 10 - count and 0 or word(tx - (10 - count), ty)
        end
        if ty >= 11 and ty <= 13 and tx >= 10 and tx < 30 then
          local open = S._detailRowsOpen
          local row = open and (ty == 13 and 2 or 1) or (ty == 11 and 2 or 3)
          attr = S._man.detailRows[row][tx - 9] + (key == "battle_moves" and 0x3000 or 0x1000)
        end
      end
    else attr = tile + bank * 4096 end
    local px, py = x % 8, y % 8
    if math.floor(attr / 1024) % 2 ~= 0 then px = 7 - px end
    if math.floor(attr / 2048) % 2 ~= 0 then py = 7 - py end
    local byte = source:byte((attr % 1024) * 32 + py * 4 + math.floor(px / 2) + 1) or 0
    local index = math.floor(byte / 16 ^ (px % 2)) % 16
    local palIndex = math.floor(attr / 4096) * 16 + index
    local value = palette[palIndex + 1]
    if palIndex == 2 then value = S._man.palettes.portraitBackground[shiny() and "shiny" or "normal"] end
    local r, g, b = Kit.rgb555(value)
    data:setPixel(x, y, r, g, b, (index == 0 and not opaque) and 0 or 1)
  end end
  local image = love.graphics.newImage(data); image:setFilter("nearest", "nearest"); return image
end
local function layer(key)
  local detail = key == "battle_moves" or key == "contest_moves"
  local id = S._man.build .. key .. tostring(shiny()) .. (detail and ":" .. tostring(S._paneCount) .. ":" .. tostring(S._detailRowsOpen) or "")
  layers[id] = layers[id] or nativeImage(key)
  return layers[id]
end
local function drawLayer(key, x)
  love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(layer(key), x or 0, 0)
end
local function tile(index, bank, x, y)
  local id = S._man.build .. ":" .. index .. ":" .. bank
  tiles[id] = tiles[id] or nativeImage(nil, index, bank)
  love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(tiles[id], x, y)
end
local function pagination()
  local displayed = S._pageTask and not S._pageTask.dotsReady and S._pageTask.from or S._page
  for i = 0, 3 do
    local a, b
    if i < S._firstPage then a, b = 0x40, 0x40 elseif i > S._lastPage then a, b = 0x4A, 0x4A
    elseif i < displayed then a, b = 0x46, 0x47
    elseif i == displayed then if i ~= S._lastPage then a, b = 0x41, 0x42 else a, b = 0x4B, 0x4C end
    elseif i ~= S._lastPage then a, b = 0x43, 0x44 else a, b = 0x48, 0x49 end
    for j, t in ipairs({a, b}) do tile(t, 4, (10 + i * 2 + j) * 8, 0); tile(t + 16, 4, (10 + i * 2 + j) * 8, 8) end
  end
end
local function textTile(index, x, y, bank)
  if bank and bank ~= 15 then
    local source = {}; for _, b in ipairs(S._man.nativeTextTiles) do source[#source + 1] = string.char(b) end
    source = table.concat(source)
    for i = 0, 1 do
      local id = S._man.build .. ":text:" .. index .. ":" .. i .. ":" .. bank
      tiles[id] = tiles[id] or nativeImage(nil, index * 2 + i, bank, source)
      love.graphics.setColor(1,1,1,1); love.graphics.draw(tiles[id], x, y + i * 8)
    end
    return
  end
  local strip = index >= 5 and S._man.buttons or S._man.text
  local offset = (index >= 5 and index - 5 or index) * 2
  frame(strip, offset, x, y); frame(strip, offset + 1, x, y + 8)
end
local function typeIcon(index, x, y)
  index = tonumber(index) or require("src.core.game3.battle.types").ID[index]
  frame(S._man.sprites.moveTypes, assert(index, "native type id"), x, y)
end
local function portrait()
  local m, p = mon(), S._man
  local egg = Pokemon.isEgg(m)
  local pic = Pokemon.monFrontPic(m)
  local flip = not egg and not p.noFlip[tonumber(Pokemon.speciesOf(m))]
  love.graphics.setColor(1, 1, 1, 1)
  if pic and S._portraitReady then love.graphics.draw(pic.image, flip and 72 or 8, 32, 0, flip and -1 or 1, 1) end
  if S._markingReady then frame(p.sprites.markings, (tonumber(m.markings) or 0) % 16, 44, 22) end
  if egg then print(Pokemon.displayName(m), 24, 128); return end
  local dex
  if require("src.core.game3.dex").nationalEnabled(S._playerState) then dex = Pokemon.national(Pokemon.speciesOf(m))
  else
    local hoenn = assert(Kit.loadLua("data/generated/gba/pokemon/hoenn.lua"))
    dex = hoenn.toHoenn[Pokemon.speciesOf(m)]
    if dex and dex > 202 then dex = nil end
  end
  if dex then textTile(2, 8, 16, shiny() and 8 or 15); print(string.format("%03d", dex), 17, 16, shiny() and 8 or 13) end
  print(Pokemon.displayName(m), 8, 96)
  if S._state ~= "normal" or S._pane then return end
  print("/" .. Pokemon.name(Pokemon.speciesOf(m)), 7, 112)
  print("{LV}" .. tostring(m.level or 1), 24, 128)
  local species, gender = Pokemon.speciesOf(m), SummaryData.gender(m)
  if species ~= 29 and species ~= 32 then
    if gender == "M" then text("gOtherText_MaleSymbol2", 56, 128, 11)
    elseif gender == "F" then text("gOtherText_FemaleSymbol2", 56, 128, 12) end
  end
  local status = SummaryData.statusAilment(m)
  if status > 0 then text("gOtherText_Status", 8, 144); frame(p.sprites.status, p.sprites.status.anims[status][1].frame, 48, 148) end
  if (tonumber(m.pokerus) or 0) >= 16 and (tonumber(m.pokerus) or 0) % 16 == 0 then tile(0x2C, 0, 16, 136) end
  local Ui, Balls = require("src.core.game3.battle.ui"), require("src.core.game3.battle.ball_open")
  local img, q = Ui.ballQuad(Balls.ballIdForItem(m.pokeball), 0)
  if img and S._ballReady then love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, q, -2, 128) end
end
local function memo()
  local m, owner = mon(), S._opts.owner or S._playerState
  local location = m.metLocationName
  if not location then
    local entry = require("src.import.gba.map_sections_extract").getInfo(tonumber(m.metLocation) or 0, nil, 0)
    location = entry and (entry.rawName or entry.name)
  end
  local x, y = 88, 112
  for _, run in ipairs(Policy.memo(m, owner, location)) do
    local first = true
    for value in (run.text .. "\n"):gmatch("(.-)\n") do
      if not first then x, y = 88, y + 16 end
      print(value, x, y, run.color)
      x = x + Font.measure(value, {font = "native_" .. S._man.nativeWindow.fontNum})
      first = false
    end
  end
end
local function info()
  local m = mon()
  text("gOtherText_Type2", 88, 48, 255)
  textTile(0, 176, 32)
  textTile(2, 184, 32)
  if Pokemon.isEgg(m) then
    print(RomText.plain("gOtherText_OriginalTrainer") .. RomText.plain("gOtherText_FiveQuestions"), 88, 32)
    text("gOtherText_FiveQuestions", 193, 32)
    typeIcon(9, 120, 48)
    text(Policy.eggHatchKey(m), 88, 72, 255)
  else
    local label = RomText.plain("gOtherText_OriginalTrainer")
    print(label, 88, 32)
    local x = 88 + Font.measure(label, {font = "native_" .. S._man.nativeWindow.fontNum})
    Font.draw(tostring(m.otName or m.originalTrainer or ""), x, 32, {font = "native_" .. S._man.nativeWindow.fontNum,
      colors = colors((m.otGender == 1 or m.otGender == "F") and 10 or 9), japanese = tonumber(m.language) == 1})
    print(string.format("%05d", (tonumber(m.otId) or 0) % 65536), 193, 32)
    local types = Pokemon.types(Pokemon.speciesOf(m)); typeIcon(types[1], 120, 48)
    if types[1] ~= types[2] then typeIcon(types[2], 160, 48) end
    local abilities = Pokemon.abilities(Pokemon.speciesOf(m))
    local flag = tonumber(m.abilityNum or m.altAbility)
    local ability = flag and abilities[flag % 2 + 1] or tonumber(m.ability or m.abilityId) or Pokemon.abilityId(Pokemon.speciesOf(m), m.personality)
    if ability == 0 then ability = abilities[1] end
    local name = Pokemon.abilityName(ability)
    print(name, 88, 72); print(SummaryData.abilityDescription(ability, name), 88, 88, 255)
  end
  memo()
end
local function skills()
  local m, stats = mon(), mon().stats or {}
  local function stat(k, alias) return tonumber(m[k] or m[alias] or stats[k] or stats[alias]) or 0 end
  local id = require("src.core.game3.items_data").toNumericId(m.item or m.heldItem) or 0
  print(id == 0 and RomText.plain("gOtherText_None") or require("src.core.game3.items_data").displayName(id), 88, 32, 255)
  local n = require("src.core.game3.rse.ribbons").count(m)
  print(n == 0 and RomText.plain("gOtherText_None") or RomText.plain("gOtherText_Ribbons00"):gsub("00", string.format("%2d", n)), 168, 32, 255)
  for i, label in ipairs({"HP", "Attack", "Defense"}) do text("gOtherText_" .. label, 88, 40 + i * 16, 13, "center", 42) end
  for i, label in ipairs({"SpAtk", "SpDef", "Speed"}) do text("gOtherText_" .. label, 176, 40 + i * 16, 13, "center", 36) end
  print(tostring(stat("hp", "currentHp")), 150, 56, 255, "right"); print("/", 150, 56, 255)
  print(tostring(stat("maxHp", "maxHP")), 174, 56, 255, "right")
  print(tostring(stat("attack", "atk")), 128, 72, 255, "center", 50)
  print(tostring(stat("defense", "def")), 128, 88, 255, "center", 50)
  print(tostring(stat("spAtk", "spa")), 216, 56, 255, "center", 18)
  print(tostring(stat("spDef", "spd")), 216, 72, 255, "center", 18)
  print(tostring(stat("speed", "spe")), 216, 88, 255, "center", 18)
  local exp = Policy.exp(m)
  text("gOtherText_ExpPoints", 88, 112); text("gOtherText_NextLv", 88, 128)
  print(tostring(exp.totalExp), 232, 112, 255, "right"); print(tostring(exp.expNeeded), 232, 128, 255, "right")
  for i = 0, 7 do frame(S._man.exp, math.max(0, math.min(8, exp.ticks - i * 8)), 168 + i * 8, 144) end
end
local function contest(id)
  local pack = assert(Kit.loadLua("data/generated/gba/pokemon/contest_moves.lua"))
  local move = pack.moves[id]
  return move, move and pack.effects[move.effect]
end
local function moves()
  local m, contestPage, detail = mon(), S._page == 3, S._state ~= "normal"
  for i = 0, detail and 4 or 3 do
    local id = i == 4 and S._moveToLearn or Pokemon.moveIdAt(m, i + 1) or 0
    local y = 32 + i * 16
    if i == 4 and id == 0 then text("gOtherText_CancelNoTerminator", 120, y)
    elseif id == 0 then text("gOtherText_OneDash", 120, y); text("gOtherText_TwoDashes", 208, y, 255)
    else
      local def, c = Pokemon.battleMove(id), contestPage and contest(id)
      typeIcon(contestPage and c.category + 18 or def.type, 87, y)
      print(Pokemon.moveName(id), 120, y, i == 4 and (contestPage and 9 or 10) or 13)
      textTile(1, 192, y)
      local entry = m.moves and m.moves[i + 1]
      local pp = i == 4 and def.pp or type(entry) == "table" and entry.pp or m.pp and m.pp[i + 1] or 0
      local max = i == 4 and def.pp or Policy.maxPP(m, i + 1, id)
      print(tostring(pp), 214, y, 255, "right"); print("/", 214, y, 255); print(tostring(max), 232, y, 255, "right")
    end
  end
  if not detail then return end
  local cursor = S._state == "swap" and S._switch or S._selected
  local id = cursor == 4 and S._moveToLearn or Pokemon.moveIdAt(m, cursor + 1) or 0
  if S._state == "notice" then text("gOtherText_CantForgetHMs", 88, 120, 255)
  elseif id ~= 0 and S._detailReady then
    if contestPage then
      local _, effect = contest(id)
      text("gOtherText_Appeal2", 8, 120); text("gOtherText_Jam2", 8, 136)
      for row, value in ipairs({effect.appeal, effect.jam}) do
        local amount = value == 255 and 0 or math.floor(value / 10)
        for i = 0, 7 do frame(S._man.hearts, row == 1 and (i < amount and 1 or 0) or (i < amount and 3 or 4), 48 + i % 4 * 8, 120 + (row - 1) * 16 + math.floor(i / 4) * 8) end
      end
      print(effect.description, 88, 120, 255)
    else
      local def = Pokemon.battleMove(id)
      text("gOtherText_Power2", 8, 120); text("gOtherText_Accuracy2", 8, 136)
      print(def.power > 1 and tostring(def.power) or RomText.plain("gOtherText_ThreeDashes2"), 77, 120, 255, "right")
      print(def.accuracy > 0 and tostring(def.accuracy) or RomText.plain("gOtherText_ThreeDashes2"), 77, 136, 255, "right")
      print(SummaryData.moveDescription(id, Pokemon.moveName(id)), 88, 120, 255)
    end
  end
  if S._state == "notice" then return end
  local entry = S._man.sprites.moveSelect
  local function outline(slot, variant, blink)
    if blink and S._tick % 32 > 24 then return end
    for i = 0, 9 do
      local anim = i == 0 and 4 or i == 9 and 5 or 6
      frame(entry, entry.anims[anim + variant * 3 + 1][1].frame, 80 + i * 16, 32 + slot * 16)
    end
  end
  outline(S._selected, S._state == "swap" and 1 or 0, S._state ~= "swap")
  if S._state == "swap" then outline(S._switch, 0, true) end
end
function S.draw()
  if not S.open or not mon() then return end
  love.graphics.setColor(rgba(S._man.palettes.bg[1])); love.graphics.rectangle("fill", 0, 0, 240, 160)
  drawLayer(Pokemon.isEgg(mon()) and "info" or "common")
  local task = S._pageTask
  local function pageLayer(page, x) if page > 0 then drawLayer(S._man.pages[page + 1], x) end end
  if task then
    if task.direction < 0 then
      pageLayer(S._page, 0); pageLayer(task.from, 256 - task.offset)
    else
      pageLayer(task.from, 0); pageLayer(S._page, 256 - task.offset)
    end
  else pageLayer(S._page, 0) end
  pagination()
  portrait()
  print(S._man.headerTexts[S._headerPage + 1], 2, 0)
  local action = 0
  if S._state == "normal" then action = S._headerPage == 0 and 7 or S._headerPage >= 2 and 6 or 0
  elseif S._state == "detail" or S._state == "swap" then action = S._disableEdit and 6 or 5 end
  if action > 0 then textTile(5, 184, 0); textTile(6, 192, 0); print(S._man.headerTexts[action], 200, 0) end
  if S._bodyReady then
    if S._page == 0 then info() elseif S._page == 1 then skills() else moves() end
  end
  if S._hardwareY then
    love.graphics.setColor(0,0,0,S._hardwareY / 16); love.graphics.rectangle("fill",0,0,240,160); love.graphics.setColor(1,1,1,1)
  else Kit.drawFade(S._pal) end
end
return S
