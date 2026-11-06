local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local Pal = require("src.core.game3.pal_fade")
local Fx = require("src.core.game3.gba_fx")
local Easy = require("src.core.game3.easy_chat_text")
local Policy = require("src.ui.game3.rs.trendy_phrase_policy")
local Frames = require("src.ui.game3.rs.trendy_phrase_frames")
local C = {isMenu = true, open = false}
local quads = {}
local function se() Kit.playSe("SE_SELECT") end
local function pressed(input, key) return input and input.wasPressed and input:wasPressed(key) end
local function copyWords(words)
  local out = {}; for i = 1, 2 do out[i] = tonumber(words and words[i]) or Policy.EMPTY end; return out
end

function C.manifest()
  local meta = assert(Kit.manifest("rse/trendy_phrase"), "native RS trendy phrase metadata missing")
  assert(meta.layout == "rs" and meta.type == 9 and meta.wordCount == 2, "native RS type9 required")
  local assets = assert(Kit.manifest(meta.assets), "native RS Easy Chat assets missing")
  assert(assets.layout == "rs", "native RS Easy Chat assets required")
  local m = {}; for k, v in pairs(assets) do m[k] = v end
  for k, v in pairs(meta) do m[k] = v end
  return m
end
function C.show(opts)
  opts = opts or {}
  C._man, C._session, C._opts = C.manifest(), assert(opts.session), opts
  C._before, C.words = copyWords(opts.words), copyWords(opts.words)
  C.groups = Policy.groups(C._session, opts.gates)
  C._onClose, C._accepted, C._tick = opts.onDone, false, 0
  C.row, C.col, C._selected, C._view = 0, 0, 1, "phrase"
  C._group, C._word, C._list = {row = 0, col = 0, top = 0, sidebar = false, alpha = false}, nil, nil
  C._map, C._transition, C._scroll = Frames.initial(C._man), nil, nil
  C._confirm, C._triangleTick, C._outlineTick = nil, 0, 0
  C._heldSignature, C._repeatCounter, C._repeated = "", 40, {}
  C._pal, C._setup, C._state, C.open = Pal.new(), 0, "setup", true
  C._pal:blend(Pal.ALL, 16, Pal.BLACK)
  Stack.push("rs_trendy_phrase", C, {hideBelow = true, fullscreen = true})
end
function C.isOpen() return C.open end
function C.close()
  if not C.open then return end
  C.open = false
  Stack.pop("rs_trendy_phrase")
  local cb = C._onClose; C._onClose = nil
  if cb then cb(C._accepted, copyWords(C.words)) end
end
function C.reset()
  C._onClose = nil; C.close()
  C._session, C._man, C._map, C._transition, C._scroll = nil, nil, nil, nil, nil
  quads = {}
end

local function transition(route, cb)
  C._transition = Frames.begin(route)
  C._transition.cb = cb
  C._triangleTick, C._outlineTick = 0, 0
end
local function phrase()
  C._view, C._confirm = "phrase", nil
  C._triangleTick = 0
end
local function exit(accepted)
  if accepted and C._opts.commit then accepted = C._opts.commit(copyWords(C.words)) end
  if not accepted and C._opts.cancel then C._opts.cancel() end
  C._accepted = accepted == true
  C._state = "fade_out"
  C._pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
end
local function ask(kind)
  C._confirm = {kind = kind, cursor = kind == "save" and 0 or 1}
  C._view = "phrase"
end
local function toggle()
  C._view = "none"
  transition("toggle", function()
    C._group = {row = 0, col = 0, top = 0, sidebar = false, alpha = not C._group.alpha}
    C._view = "groups"
  end)
end
function C.update()
  if not C.open then return end
  C._tick = C._tick + 1
  C._triangleTick, C._outlineTick = C._triangleTick + 1, C._outlineTick + 1
  if C._state == "setup" then
    if C._setup == 7 then C._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK) end
    if C._setup == 8 then
      require("src.core.game3.rse.init").setFlag("FLAG_SYS_CHAT_USED", true, C._session)
      C._state = "fade_in"
    else C._setup = C._setup + 1 end
    return
  end
  if C._state == "fade_in" or C._state == "fade_out" then
    C._pal:updateFade()
    if not C._pal:fadeActive() then
      if C._state == "fade_out" then C.close() else C._state = "input" end
    end
    return
  end
  if C._transition then
    local t = C._transition
    if Frames.step(t, C._map, C._man) then C._transition = nil; if t.cb then t.cb() end end
  elseif C._scroll then
    local t = C._scroll
    t.offset = t.offset + t.speed
    if math.abs(t.offset) >= math.abs(t.distance) then C._scroll = nil end
  end
end

local function navKey(input, extras)
  for _, key in ipairs(extras or {"up", "down", "left", "right"}) do
    local repeating = key == "up" or key == "down" or key == "left" or key == "right"
    if pressed(input, key) or (repeating and C._repeated[key]) then return key end
  end
end
local function readRepeats(input)
  C._repeated = {}
  if not input or not input.isDown then return end
  local held, signature = {}, {}
  for _, key in ipairs({"up", "down", "left", "right", "a", "b", "start", "select", "l", "r"}) do
    if input:isDown(key) then held[key] = true; signature[#signature + 1] = key end
  end
  signature = table.concat(signature, ",")
  if signature ~= "" and signature == C._heldSignature then
    C._repeatCounter = C._repeatCounter - 1
    if C._repeatCounter == 0 then C._repeated, C._repeatCounter = held, 5 end
  else C._repeatCounter = 40 end
  C._heldSignature = signature
end
local function beginScroll(delta, key, view)
  if delta == 0 then return end
  C._scroll = {distance = delta * 16, offset = 0,
    speed = (delta < 0 and -1 or 1) * ((key == "start" or key == "select") and 4 or 2), view = view}
end
function C.handleInput(input)
  if C.open then readRepeats(input) end
  if not C.open or C._state ~= "input" or C._transition or C._scroll then return end
  local a, b, key = pressed(input, "a"), pressed(input, "b"), navKey(input)
  if C._confirm then
    local t = C._confirm
    if t.kind == "empty" or t.kind == "unchanged" or t.kind == "incomplete" then
      if a or b then se(); phrase() end; return
    end
    key = pressed(input, "up") and "up" or (pressed(input, "down") and "down" or nil)
    if not a and not b and (key == "up" or key == "down") then
      local nextCursor = math.max(0, math.min(1, t.cursor + (key == "up" and -1 or 1)))
      if nextCursor ~= t.cursor then t.cursor = nextCursor; se() end
    end
    if b or (a and t.cursor == 1) then se(); phrase()
    elseif a then
      se()
      if t.kind == "delete" then for i = 1, 2 do C.words[i] = Policy.EMPTY end; phrase()
      elseif t.kind == "cancel" then exit(false)
      else exit(Policy.valid(C._before, C.words)) end
    end
    return
  end
  if C._view == "phrase" then
    key = pressed(input, "start") and "start" or key
    if key then
      local row, col = Policy.mainMove(C.row, C.col, key)
      if row ~= C.row or col ~= C.col then C.row, C.col, C._triangleTick = row, col, 0; se() end
    end
    if a then
      se()
      if C.row == 1 then
        if C.col == 0 then ask("delete")
        elseif C.col == 1 then ask("cancel")
        else
          local valid, reason = Policy.valid(C._before, C.words)
          if C._opts.validate then valid, reason = C._opts.validate(C.words) end
          ask(valid and "save" or reason)
        end
      else
        C._selected = C.row * 2 + C.col + 1
        local alpha = C._group.alpha
        C._group = {row = 0, col = 0, top = 0, sidebar = false, alpha = alpha}
        C._view = "groups"
        transition("groups")
      end
    elseif b then ask("cancel") end
  elseif C._view == "groups" then
    if key then
      local moved, delta = Policy.groupMove(C._group, key, #C.groups)
      if moved then se(); C._outlineTick = 0; beginScroll(delta, key, "groups") end
    end
    local g = C._group
    if a then
      if g.sidebar then
        se()
        if g.row == 1 then toggle()
        elseif g.row == 2 then C.words[C._selected] = Policy.EMPTY
        else C._view = "none"; transition("phrase", phrase) end
      else
        local list
        if g.alpha then
          local ch = C._man.alphabet[g.row + 1]:sub(g.col + 1, g.col + 1)
          local letter = ch == " " and 0 or ch:byte() - 64
          list = Policy.alphabetWords(letter, C._man, C._session, C._opts.gates)
        else list = assert(C.groups[g.row * 2 + g.col + 1]).words end
        if #list > 0 then
          se(); C._list, C._word, C._view = list, {row = 0, col = 0, top = 0}, "none"
          transition("words", function() C._view = "words" end)
        end
      end
    elseif b then C._view = "none"; transition("phrase", phrase)
    elseif pressed(input, "select") then se(); toggle() end
  elseif C._view == "words" then
    key = navKey(input, {"up", "down", "left", "right", "start", "select"})
    if key then
      local moved, delta = Policy.wordMove(C._word, key, #C._list)
      if moved then se(); C._triangleTick = 0; beginScroll(delta, key, "words") end
    end
    if a then
      se(); local w = C._word
      C.words[C._selected] = assert(C._list[w.row * 2 + w.col + 1]).id
      C._view = "none"; transition("chosen", phrase)
    elseif b then C._view = "none"; transition("back", function() C._view = "groups" end) end
  end
end

local function color(value, bank)
  local s, result = C._pal.slots[bank], {}
  for i = 1, 3 do
    local v = math.floor(value / 2 ^ ((i - 1) * 5)) % 32
    v = v + math.floor(((s.color[i] or 0) - v) * s.y / 16)
    result[i] = (v * 8 + math.floor(v / 4)) / 255
  end
  result[4] = 1; return result
end
function C.textOptions(kind)
  local w = assert(C._man.windows[kind or "phrase"])
  local p, bank = C._man.palettes.bg, w.paletteNum
  return {font = "native_" .. w.fontNum, letterSpacing = w.spacing, linePitch = 16,
    colors = {fg = color(p[bank * 16 + w.foregroundColor + 1], bank),
      shadow = color(p[bank * 16 + w.shadowColor + 1], bank), bg = color(p[bank * 16 + w.backgroundColor + 1], bank)}}
end
local function text(value, x, y, kind) Font.draw(value, x, y, C.textOptions(kind)) end
local function tile(e, x, y)
  local bank, tileId = math.floor(e / 4096), e % 1024
  if bank ~= 4 and bank ~= 5 then return end
  local atlas, index = C._man.tiles, (bank - 4) * C._man.tiles.count + tileId
  assert(tileId < atlas.count, "native Easy Chat frame tile out of range")
  local img, key = assert(Kit.image(atlas.png)), "tile" .. index
  if not quads[key] then quads[key] = love.graphics.newQuad(0, index * 8, 8, 8, atlas.w, atlas.h) end
  local hf, vf = math.floor(e / 1024) % 2 == 1, math.floor(e / 2048) % 2 == 1
  love.graphics.setColor(1, 1, 1, 1)
  Fx.draw(function() love.graphics.draw(img, quads[key], x + (hf and 8 or 0), y + (vf and 8 or 0), 0, hf and -1 or 1, vf and -1 or 1) end, C._pal:fx(bank))
end
local function sprite(entry, tileId, x, y, bank, flip, blend)
  local index = 0
  for i, t in ipairs(entry.tiles) do if t == tileId then index = i - 1; break end end
  local img, key = assert(Kit.image(entry.png)), entry.png .. index
  if not quads[key] then quads[key] = love.graphics.newQuad(0, index * entry.h, entry.w, entry.h, img:getDimensions()) end
  love.graphics.setColor(1, 1, 1, 1)
  Fx.draw(function() love.graphics.draw(img, quads[key], x - entry.w / 2, y - entry.h / 2 + (flip and entry.h or 0), 0, 1, flip and -1 or 1) end, C._pal:fx(bank), blend)
end
local function triangle(x, y)
  local dx = -6 + math.floor(C._triangleTick / 3) % 7
  sprite(C._man.sprites.triangle, 0, x + dx, y, 16)
end
local function phraseWords()
  if C._confirm and C._confirm.kind == "save" then
    text(Easy.rawWord(C.words[1]) .. " " .. Easy.rawWord(C.words[2]) .. " ", 48, 24, "phrase")
    return
  end
  for i = 1, 2 do
    local x, y = C._man.wordPens[i].x, C._man.wordPens[i].y
    if C.words[i] == Policy.EMPTY then
      local image = assert(Kit.image(C._man.blankWord))
      love.graphics.setColor(1, 1, 1, 1)
      Fx.draw(function() love.graphics.draw(image, x, y) end, C._pal:fx(0))
    else text(Easy.rawWord(C.words[i]), x, y, "phrase") end
  end
end
local function pickerText()
  local view = C._view
  if view ~= "groups" and view ~= "words" then return end
  local state = view == "groups" and C._group or C._word
  local scroll = C._scroll
  local offset = scroll and (scroll.distance - scroll.offset) or 0
  love.graphics.setScissor(0, 88, 240, 64)
  if view == "groups" and state.alpha then
    for row = 0, 3 do
      local value = C._man.alphabetText[row + 1]
      text(value, 16, 88 + row * 16, "picker")
    end
  else
    local count = view == "groups" and #C.groups or #C._list
    for row = math.max(0, state.top - 4), math.min(math.ceil(count / 2) - 1, state.top + 7) do
      for col = 0, 1 do
        local word = (view == "groups" and C.groups or C._list)[row * 2 + col + 1]
        if word then
          local x = (view == "groups" and 16 or 48) + col * 88
          text(view == "groups" and word.name or word.text, x, 88 + (row - state.top) * 16 + offset, "picker")
        end
      end
    end
  end
  love.graphics.setScissor()
end
local function pickerSprites()
  local s, view = C._group, C._view
  local art = C._man.sprites
  if C._transition or C._scroll then return end
  if view == "groups" then
    local x, y, kind
    if s.sidebar then x, y, kind = 216, s.row * 16 + 96, 1
    elseif not s.alpha then x, y, kind = s.col * 88 + 32, (s.row - s.top) * 16 + 96, 0
    elseif s.row == 0 and s.col == 6 then x, y, kind = 151, 96, 2
    else x, y, kind = C._man.alphabetCursorX[s.row + 1][s.col + 1] * 8 + 31, s.row * 16 + 96, 3 end
    local phase = math.max(0, C._outlineTick - 1) * 5 % 256
    local sine = math.floor(C._man.sine[phase + 1] / 32)
    local blend = {eva = 8, evb = 8}
    if C._outlineTick % 2 == 1 then blend.eva = 8 + sine
    else blend.evb = 8 - sine end
    local previous = math.max(0, C._outlineTick - 2) * 5 % 256
    local oldSine = math.floor(C._man.sine[previous + 1] / 32)
    if C._outlineTick > 1 then
      if C._outlineTick % 2 == 1 then blend.evb = 8 - oldSine else blend.eva = 8 + oldSine end
    end
    if kind == 0 then
      sprite(art.outline, 48, x + 64, y, 17, nil, blend); sprite(art.outline, 32, x + 32, y, 17, nil, blend); sprite(art.outline, 0, x, y, 17, nil, blend)
    elseif kind == 2 then sprite(art.outline, 48, x + 21, y, 17, nil, blend); sprite(art.outline, 0, x, y, 17, nil, blend)
    else sprite(art.outline, kind == 1 and 8 or 24, x, y, 17, nil, blend) end
    if not s.alpha then
      if s.top > 0 then sprite(art.arrows, 0, 100, 84, 16) end
      if s.top < math.ceil(#C.groups / 2) - 4 then sprite(art.arrows, 0, 100, 156, 16, true) end
    end
  elseif view == "words" then
    local w = C._word
    triangle(w.col * 88 + 44, (w.row - w.top) * 16 + 96)
    if w.top > 0 then sprite(art.arrows, 4, 120, 84, 16) end
    if w.top < math.ceil(#C._list / 2) - 4 then sprite(art.arrows, 4, 120, 156, 16, true) end
    sprite(art.buttons, 0, 142, 88, 16); sprite(art.buttons, 4, 182, 88, 16)
  end
end
local function prompt()
  if C._view ~= "phrase" then return end
  local t, labels, lines = C._confirm, C._man.texts
  if not t then lines = labels.edit
  elseif t.kind == "save" then lines = labels.confirm
  elseif t.kind == "cancel" then lines = {labels.cancel}
  elseif t.kind == "delete" then lines = {labels.delete1, labels.delete2}
  else lines = {assert(labels[t.kind], "native RS trend validation text missing")} end
  Fx.draw(function() Chrome.stdFrame(4, 15, 22, 4) end, C._pal:fx(15))
  for i, value in ipairs(lines) do
    local opts = C.textOptions("prompt")
    Font.draw(Font.wrap(value, 176, opts), 32, 120 + (i - 1) * 16, opts)
  end
  if t and (t.kind == "save" or t.kind == "cancel" or t.kind == "delete") then
    Fx.draw(function() Chrome.stdFrame(24, 9, 5, 4) end, C._pal:fx(15))
    text(labels.yes, 192, 72, "prompt"); text(labels.no, 192, 88, "prompt")
    Cursor.draw(192, 72 + t.cursor * 16, 40, C._pal:fx(16))
  elseif not t and not C._transition then
    if C.row == 1 then triangle(C._man.footer.x + C.col * C._man.footer.stride, C._man.footer.y)
    else local p = C._man.wordCursors[C.col + 1]; triangle(p.x, p.y) end
  end
end
function C.draw()
  if not C.open then return end
  love.graphics.push("all")
  if C._state == "setup" then love.graphics.clear(0, 0, 0, 1); love.graphics.pop(); return end
  local backdrop = color(C._man.palettes.bg[1], 0)
  love.graphics.clear(unpack(backdrop))
  local bg2 = assert(C._man.backdrop, "native Easy Chat BG2 metadata missing")
  love.graphics.setColor(color(C._man.palettes.bg[bg2.color + 1], 0))
  love.graphics.rectangle("fill", 0, 0, 240, bg2.height)
  local titleOpts = C.textOptions("phrase"); titleOpts.font = "native_" .. C._man.titleFont
  local titleWidth = Font.measure(C._man.texts.title, C.textOptions("phrase"))
  Font.draw(C._man.texts.title, math.max(0, math.floor((C._man.titleWidth - titleWidth) / 2)), 0, titleOpts)
  phraseWords(); pickerText()
  for y = 0, 19 do for x = 0, 29 do tile(C._map[y * 32 + x + 1], x * 8, y * 8) end end
  pickerSprites(); prompt()
  love.graphics.pop()
end
return C
