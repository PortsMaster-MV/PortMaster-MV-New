local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Cursor = require("src.ui.game3.rs.menu_cursor")
local Pal = require("src.core.game3.pal_fade")
local Fx = require("src.core.game3.gba_fx")
local Easy = require("src.core.game3.easy_chat_text")
local Policy = require("src.ui.game3.rs.easy_chat_editor_policy")
local Frames = require("src.ui.game3.rs.easy_chat_editor_frames")
local C = {isMenu = true, open = false}
local quads = {}
local function se() Kit.playSe("SE_SELECT") end
local function pressed(input, key) return input and input.wasPressed and input:wasPressed(key) end
local function copyWords(words)
  local out = {}; for i = 1, C._man.wordCount do out[i] = tonumber(words and words[i]) or Policy.EMPTY end; return out
end

function C.manifest(kind)
  local meta = assert(Kit.manifest("rse/easy_chat_editor"), "native RS EasyChat editor metadata missing")
  assert(meta.layout == "rs" and meta.editorVersion == 2 and meta.types[kind], "native RS indexed editor metadata required")
  local assets = assert(Kit.manifest(meta.assets), "native RS Easy Chat assets missing")
  assert(assets.layout == "rs", "native RS Easy Chat assets required")
  local m = {}; for k, v in pairs(assets) do m[k] = v end
  for k, v in pairs(meta) do m[k] = v end
  for k, v in pairs(meta.types[kind]) do if k ~= "texts" then m[k] = v end end
  m.texts, m.sprites = {}, {}
  for k, v in pairs(meta.texts) do m.texts[k] = v end
  for k, v in pairs(meta.types[kind].texts) do m.texts[k] = v end
  for k, v in pairs(assets.sprites) do m.sprites[k] = v end
  for k, v in pairs(meta.sprites) do m.sprites[k] = v end
  return m
end
function C.show(opts)
  opts = opts or {}
  assert(opts.token and opts.type ~= 9, "native RS editor requires its save contract; type9 uses its separate host")
  C._man, C._session, C._opts = C.manifest(opts.type), assert(opts.session), opts
  C._before, C.words = copyWords(opts.words), copyWords(opts.words)
  C.groups = Policy.groups(C._session, opts.gates)
  C._onClose, C._accepted, C._tick = opts.onDone, false, 0
  C.row, C.col, C._selected, C._view = 0, 0, 1, "phrase"
  C._group, C._word, C._list = {row = 0, col = 0, top = 0, sidebar = false, alpha = false}, nil, nil
  C._map, C._transition, C._scroll = Frames.initial(C._man), nil, nil
  C._confirm, C._triangleTick, C._outlineTick = nil, 0, 0
  C._heldSignature, C._repeatCounter, C._repeated = "", 40, {}
  C._indicator = {animation = 0, index = 1, timer = 0, tile = 96, beginning = true}
  C._blueRamp, C._blueIndex = Policy.blueRamp(C._man.palettes.frameBlue), nil
  if C._man.interview then
    local Ow = require("src.core.game3.ow_sprites")
    local g = C._session.gender
    C._playerGraphics = (g == 1 or g == "female" or g == "F") and C._man.interview.playerGraphics.female or C._man.interview.playerGraphics.male
    C._reporterGraphics = C._man.interview.reporterGraphics[opts.variant] or C._man.interview.reporterGraphics[0]
    Ow.prefetch(C._playerGraphics, 0); Ow.prefetch(C._reporterGraphics, 0)
  else C._playerGraphics, C._reporterGraphics = nil, nil end
  C._pal, C._setup, C._state, C.open = Pal.new(), 0, "setup", true
  C._pal:blend(Pal.ALL, 16, Pal.BLACK)
  Stack.push("rs_easy_chat_editor", C, {hideBelow = true, fullscreen = true})
end
function C.isOpen() return C.open end
function C.close()
  if not C.open then return end
  C.open = false
  Stack.pop("rs_easy_chat_editor")
  local cb = C._onClose; C._onClose = nil
  if cb then cb(C._accepted, copyWords(C.words)) end
end
function C.reset()
  C._onClose = nil; C.close()
  C._session, C._man, C._map, C._transition, C._scroll = nil, nil, nil, nil, nil
  C._blueRamp, C._blueIndex = nil, nil
  quads = {}
end

local function indicator(animation)
  local command = C._man.sprites.indicator.anims[animation + 1][1]
  C._indicator = {animation = animation, index = 1, timer = 0, tile = command.tile, beginning = true}
end
local function transition(route, cb)
  C._transition = Frames.begin(route, C._group.alpha)
  C._transition.cb = cb
  if route ~= "words" then C._triangleTick, C._outlineTick = 0, 0 end
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
    C._view = "groups"
  end)
end
local function animateIndicator()
  local a, commands = C._indicator, C._man.sprites.indicator.anims[C._indicator.animation + 1]
  if a.beginning then
    a.beginning, a.timer = false, math.max(0, commands[1].duration - 1)
  elseif a.timer > 0 then a.timer = a.timer - 1
  elseif not a.ended then
    local command = commands[a.index + 1]
    if command and command.op == "frame" then
      a.index, a.tile, a.timer = a.index + 1, command.tile, math.max(0, command.duration - 1)
    else a.ended = true end
  end
end
function C.update()
  if not C.open then return end
  C._tick = C._tick + 1
  C._triangleTick, C._outlineTick = C._triangleTick + 1, C._outlineTick + 1
  if C._state == "setup" then
    if C._setup == 7 then C._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK) end
    if C._setup == 8 then
      if C._opts.onOpened then C._opts.onOpened() end
      C._state = "fade_in"
    else C._setup = C._setup + 1 end
    return
  end
  if C._state == "fade_in" or C._state == "fade_out" then
    C._pal:updateFade()
    if not C._pal:fadeActive() then
      if C._state == "fade_out" then C.close() else C._state = "input" end
    end
    if C.open then animateIndicator() end
    return
  end
  if C._transition then
    local t = C._transition
    local done, events = Frames.step(t, C._map, C._man)
    if events.indicator then indicator(events.indicator) end
    if events.toggle then
      C._group = {row = 0, col = 0, top = 0, sidebar = false, alpha = not C._group.alpha}
      C._view = "groups"
    end
    if events.view then C._view = events.view end
    if events.paletteDelta then
      C._blueIndex = (C._blueIndex or 0) + events.paletteDelta
      assert(C._blueRamp[C._blueIndex], "native Easy Chat blue ramp index out of range")
    elseif events.paletteReset then C._blueIndex = 0 end
    if done then
      C._transition = nil; C._triangleTick, C._outlineTick = 0, 0
      if t.cb then t.cb() end
    end
  elseif C._scroll then
    local t = C._scroll
    t.offset = t.offset + t.speed
    if math.abs(t.offset) >= math.abs(t.distance) then C._scroll = nil end
  end
  animateIndicator()
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
    if t.kind == "bardRestore" then
      if a then se(); C.words = t.restored; phrase() end
      return
    end
    if t.kind == "empty" or t.kind == "unchanged" or t.kind == "incomplete" or t.kind == "noDelete" then
      if a or b then se(); phrase() end; return
    end
    key = pressed(input, "up") and "up" or (pressed(input, "down") and "down" or nil)
    if not a and not b and (key == "up" or key == "down") then
      local nextCursor = math.max(0, math.min(1, t.cursor + (key == "up" and -1 or 1)))
      if nextCursor ~= t.cursor then t.cursor = nextCursor; se() end
    end
    if b or (a and t.cursor == 1) then
      se()
      if t.kind == "save" and C._opts.declineSave then
        local restored, warning = C._opts.declineSave(C.words)
        if warning then C._confirm = {kind = "bardRestore", restored = restored}; return end
      end
      phrase()
    elseif a then
      se()
      if t.kind == "delete" then for i = 1, C._man.wordCount do C.words[i] = Policy.EMPTY end; phrase()
      elseif t.kind == "cancel" and C._man.cancelWarnings == 2 then ask("discard")
      elseif t.kind == "cancel" or t.kind == "discard" then exit(false)
      else exit(Policy.valid(C._opts.token, C.words)) end
    end
    return
  end
  if C._view == "phrase" then
    key = pressed(input, "start") and "start" or key
    if key then
      local row, col = Policy.mainMove(C.row, C.col, key, C._man)
      if row ~= C.row or col ~= C.col then C.row, C.col, C._triangleTick = row, col, 0; se() end
    end
    if a then
      se()
      if C.row == C._man.rows then
        if C.col == 0 then ask(C._man.deleteAllowed and "delete" or "noDelete")
        elseif C.col == 1 then ask("cancel")
        else
          local valid, reason = Policy.valid(C._opts.token, C.words)
          if C._opts.validate then valid, reason = C._opts.validate(C.words) end
          ask(valid and "save" or reason == "cancelPrompt" and "cancel" or reason)
        end
      else
        C._selected = C.row * C._man.columns + C.col + 1
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
        elseif g.row == 2 then
          if C._opts.type ~= 6 then C.words[C._selected] = Policy.EMPTY end
        else C._view = "none"; transition("phrase", phrase) end
      else
        local list
        if g.alpha then
          local ch = C._man.alphabet[g.row + 1]:sub(g.col + 1, g.col + 1)
          local letter = ch == " " and 0 or ch:byte() - 64
          list = Policy.alphabetWords(letter, C._man, C._session, C._opts.gates)
        else list = assert(C.groups[g.row * 2 + g.col + 1]).words end
        if #list > 0 then
          se(); C._list, C._word = list, {row = 0, col = 0, top = 0}
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
      C._view = "none"; transition("chosen", function()
        phrase()
        if C._opts.type == 6 and require("src.core.game3.rs.easy_chat_contracts").changed(C._opts.token, C.words) ~= 0 then ask("save") end
      end)
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
  return {font = "native_" .. w.fontNum, textMode = w.textMode, letterSpacing = w.spacing, linePitch = 16,
    colors = {fg = color(p[bank * 16 + w.foregroundColor + 1], bank),
      shadow = color(p[bank * 16 + w.shadowColor + 1], bank), bg = color(p[bank * 16 + w.backgroundColor + 1], bank)}}
end
local function text(value, x, y, kind) Font.draw(value, x, y, C.textOptions(kind)) end
local function tile(e, x, y)
  local bank, tileId = math.floor(e / 4096), e % 1024
  if bank ~= 4 and bank ~= 5 then return end
  local atlas, index = C._man.tiles, (bank - 4) * C._man.tiles.count + tileId
  assert(tileId < atlas.count, "native Easy Chat frame tile out of range")
  local hf, vf = math.floor(e / 1024) % 2 == 1, math.floor(e / 2048) % 2 == 1
  if bank == 5 then
    local blue = assert(C._man.blueFrame, "native RS editor indexed blue frame missing")
    assert(blue.count == atlas.count, "native Easy Chat blue/base tile count mismatch")
    local qkey = "blue" .. tileId
    if not quads[qkey] then quads[qkey] = love.graphics.newQuad(0, tileId * 8, 8, 8, blue.w, blue.h) end
    local function draw(image) love.graphics.draw(image, quads[qkey], x + (hf and 8 or 0), y + (vf and 8 or 0), 0, hf and -1 or 1, vf and -1 or 1) end
    love.graphics.setColor(1, 1, 1, 1)
    Fx.draw(function() draw(assert(Kit.image(blue.base))) end, C._pal:fx(bank))
    for layer = 1, 3 do
      local value = C._blueIndex ~= nil and C._blueRamp[C._blueIndex][layer] or C._man.palettes.bg[blue.indices[layer] + 1]
      love.graphics.setColor(color(value, bank))
      draw(assert(Kit.image(blue.masks[layer])))
    end
    love.graphics.setColor(1, 1, 1, 1)
    return
  end
  local img, key = assert(Kit.image(atlas.png)), "tile" .. index
  if not quads[key] then quads[key] = love.graphics.newQuad(0, index * 8, 8, 8, atlas.w, atlas.h) end
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
    for row = 0, C._man.rows - 1 do
      local line = {}
      for col = 0, C._man.columns - 1 do
        local i = row * C._man.columns + col + 1
        if i <= C._man.wordCount and C.words[i] ~= Policy.EMPTY then line[#line + 1] = Easy.rawWord(C.words[i]) .. " " end
      end
      local pen = C._man.wordPens[row * C._man.columns + 1]
      if pen then text(table.concat(line), pen.x, pen.y, "phrase") end
    end
    return
  end
  for i = 1, C._man.wordCount do
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
  if (C._transition and not C._transition.cursorsVisible) or C._scroll then return end
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
local function nativeSprites()
  local p = C._man.interview
  if p then
    sprite(C._man.sprites.interviewFrame, 0, p.x, p.y, 19)
    local Ow = require("src.core.game3.ow_sprites")
    for _, data in ipairs({{C._playerGraphics, p.playerX, p.playerFacing}, {C._reporterGraphics, p.reporterX, p.reporterFacing}}) do
      local spr = Ow.getDraw(data[1])
      if spr then
        Fx.draw(function() Ow.draw(data[1], data[2] - 8, p.y + spr.height / 2 - 16, 0, 0, data[3], 0, false) end, C._pal:fx(16))
      end
    end
  end
  sprite(C._man.sprites.indicator, C._indicator.tile, 224, 88, 18)
end
local function prompt()
  if C._view ~= "phrase" then return end
  local t, labels, lines = C._confirm, C._man.texts
  if not t then lines = labels.edit
  elseif t.kind == "save" then lines = labels.confirm
  elseif t.kind == "cancel" then lines = {labels.cancel}
  elseif t.kind == "discard" then lines = {labels.discard1, labels.discard2}
  elseif t.kind == "bardRestore" then lines = {labels.bardRestore1, labels.bardRestore2}
  elseif t.kind == "delete" then lines = {labels.delete1, labels.delete2}
  else lines = {assert(labels[t.kind], "native RS EasyChat validation text missing")} end
  Fx.draw(function() Chrome.stdFrame(4, 15, 22, 4) end, C._pal:fx(15))
  for i, value in ipairs(lines) do
    local opts = C.textOptions("prompt")
    Font.draw(Font.wrap(value, 176, opts), 32, 120 + (i - 1) * 16, opts)
  end
  if t and (t.kind == "save" or t.kind == "cancel" or t.kind == "discard" or t.kind == "delete") then
    Fx.draw(function() Chrome.stdFrame(24, 9, 5, 4) end, C._pal:fx(15))
    text(labels.yes, 192, 72, "prompt"); text(labels.no, 192, 88, "prompt")
    Cursor.draw(192, 72 + t.cursor * 16, 40, C._pal:fx(16))
  elseif not t and not C._transition then
    if C.row == C._man.rows then triangle(C._man.footer.x + C.col * C._man.footer.stride, C._man.footer.y)
    else local p = C._man.wordCursors[C.row * C._man.columns + C.col + 1]; triangle(p.x, p.y) end
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
  if C._man.texts.title then
    local titleOpts = C.textOptions("phrase"); titleOpts.font = "native_" .. C._man.titleFont
    local titleWidth = Font.measure(C._man.texts.title, C.textOptions("phrase"))
    Font.draw(C._man.texts.title, math.max(0, math.floor((C._man.titleWidth - titleWidth) / 2)), C._man.titleY, titleOpts)
  end
  phraseWords(); pickerText()
  for y = 0, 19 do for x = 0, 29 do tile(C._map[y * 32 + x + 1], x * 8, y * 8) end end
  nativeSprites(); pickerSprites(); prompt()
  love.graphics.pop()
end
return C
