-- pokeruby/src/field_message_box.c:26
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local M = {HIDDEN = 0, AUTO_SCROLL = 2}
local state

local LENGTH = {[0] = 0, [1] = 1, [2] = 1, [3] = 1, [4] = 3,
  [5] = 1, [6] = 1, [7] = 0, [8] = 1, [9] = 0,
  [12] = 1, [13] = 0, [15] = 0, [21] = 0, [22] = 0}

function M.prepare(presentation, onPrinted)
  local w = assert(presentation.fieldWindow, "native RS field window required")
  assert(w.template == "gMenuTextWindowTemplate" and w.fontNum == 3 and w.textMode == 2
    and w.left == 2 and w.top == 15 and w.lineLength == 26 and w.autoScroll,
    "native RS auto-scroll window mismatch")
  local bytes, source, i, ended = {}, assert(presentation.nativeBytes), 1, false
  while i <= #source do
    local b = source[i]
    assert(type(b) == "number" and b >= 0 and b <= 255 and b == math.floor(b), "native RS text byte required")
    bytes[#bytes + 1] = b; i = i + 1
    if b == 255 then ended = true; break end
    assert(b ~= 253, "RS field host requires expanded placeholders")
    if b == 252 then
      local code = source[i]
      local length = LENGTH[code]
      assert(length ~= nil, "unsupported native RS field control " .. tostring(code))
      bytes[#bytes + 1] = code; i = i + 1
      for _ = 1, length do
        local value = source[i]
        assert(type(value) == "number" and value >= 0 and value <= 255 and value == math.floor(value), "truncated native RS field control")
        bytes[#bytes + 1] = value; i = i + 1
      end
      if code >= 1 and code <= 4 then
        for p = #bytes - length + 1, #bytes do
          assert(bytes[p] > 0 and bytes[p] < 16, "RS field host requires opaque palette1..15 colors")
        end
      elseif code == 5 then
        assert(bytes[#bytes] == 15, "RS field host supports native palette15 only")
      elseif code == 6 then
        assert(bytes[#bytes] <= 6, "native RS font0..6 required")
      end
    end
  end
  assert(ended, "native RS field text must terminate with EOS")
  return {bytes = bytes, text = presentation.text, onPrinted = onPrinted,
    mode = M.AUTO_SCROLL, task = 0, frameDrawn = false, printer = "begin",
    index = 1, delay = 0, x = 0, y = 0, font = 3, japanese = false,
    fg = 1, bg = 15, shadow = 8, rows = {}}
end

function M.open(prepared)
  if M.mode() ~= M.HIDDEN then return false end
  state = prepared
  return true
end

function M.mode() return state and state.mode or M.HIDDEN end
function M.ownsFrame() return state ~= nil end
function M.isVisible() return state ~= nil and state.frameDrawn end
function M.isPrinting() return state ~= nil and state.mode == M.AUTO_SCROLL end
function M.text() return state and state.text or "" end
function M.close() state = nil end
function M.reset() M.close(); return true end

local function blankRow(s)
  return {{kind = "fill", bg = s.bg}}
end
local function clear(s)
  s.x, s.y = 0, 0
  s.rows = {blankRow(s), blankRow(s)}
end
local function scroll(s)
  s.x = 0
  if s.y == 0 then s.y = 16
  else s.rows[1], s.rows[2] = s.rows[2], blankRow(s) end
end
local function nextByte(s)
  local b = assert(s.bytes[s.index], "native RS printer read past EOS")
  s.index = s.index + 1
  return b
end
local function glyph(s, id)
  local opts = {font = "native_" .. s.font, textMode = 2, japanese = s.japanese}
  local glyphId = s.japanese and Font.JAPANESE_BASE + id or id
  local width = Font.advance(glyphId, opts)
  local row = s.rows[s.y / 16 + 1]
  row[#row + 1] = {kind = "glyph", id = glyphId, x = s.x,
    font = s.font, japanese = s.japanese, fg = s.fg, bg = s.bg, shadow = s.shadow}
  -- pokeruby/include/text.h:46
  s.x = (s.x + width) % 256
end

local function consume(s)
  local b = nextByte(s)
  if b == 255 then s.printer = "end"
  elseif b == 254 then s.printer = "newline"
  elseif b == 250 then s.printer, s.delay = "wait_scroll", 60
  elseif b == 251 then s.printer, s.delay = "wait_clear", 60
  elseif b == 252 then
    local code = nextByte(s)
    if code == 1 then s.fg = nextByte(s)
    elseif code == 2 then s.bg = nextByte(s)
    elseif code == 3 then s.shadow = nextByte(s)
    elseif code == 4 then s.fg, s.bg, s.shadow = nextByte(s), nextByte(s), nextByte(s)
    elseif code == 5 then nextByte(s)
    elseif code == 6 then s.font = nextByte(s)
    elseif code == 7 then s.font = 3
    elseif code == 8 then s.printer, s.delay = "pause", nextByte(s)
    elseif code == 9 then s.printer, s.delay = "wait_button", 60
    elseif code == 12 then glyph(s, nextByte(s))
    elseif code == 15 then clear(s)
    elseif code == 21 then s.japanese = true
    elseif code == 22 then s.japanese = false
    end
  else glyph(s, b) end
  if s.printer == "normal" or s.printer == "begin" then
    s.printer, s.delay = "char_delay", 3
  end
end

-- pokeruby/src/text.c:2398
local function printStep(s)
  if s.printer == "char_delay" or s.printer == "pause" then
    if s.delay > 0 then
      s.delay = s.delay - 1
      if s.delay > 0 then return false end
    end
    s.printer = "normal"
  elseif s.printer == "wait_button" or s.printer == "wait_clear" or s.printer == "wait_scroll" then
    s.delay = s.delay - 1
    if s.delay == 0 then
      if s.printer == "wait_clear" then clear(s)
      elseif s.printer == "wait_scroll" then scroll(s) end
      s.printer = "normal"
    end
    return false
  elseif s.printer == "newline" then
    scroll(s); s.printer = "normal"
    return false
  elseif s.printer == "begin" then clear(s)
  elseif s.printer == "end" then return true end
  consume(s)
  return s.printer == "end"
end

function M.tick()
  local s = state
  if not s or s.mode == M.HIDDEN then return end
  if s.task == 0 then s.task = 1; return end
  if s.task == 1 then s.frameDrawn, s.task = true, 2; return end
  if printStep(s) then
    s.mode = M.HIDDEN
    local done = s.onPrinted
    s.onPrinted = nil
    if done then done() end
  end
end

function M.drawText()
  local s = state
  if not s or not s.frameDrawn then return end
  Font.sync()
  for row = 1, 2 do
    local y = 120 + (row - 1) * 16
    for _, op in ipairs(s.rows[row] or {}) do
      if op.kind == "fill" then
        love.graphics.setColor(assert(Font.STDPAL[op.bg]))
        love.graphics.rectangle("fill", 16, y, 208, 16)
      else
        Font.drawGlyph(op.id, 16 + op.x, y, {font = "native_" .. op.font,
          textMode = 2, japanese = op.japanese,
          colors = {fg = Font.STDPAL[op.fg], bg = Font.STDPAL[op.bg], shadow = Font.STDPAL[op.shadow]}})
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw()
  if not M.isVisible() then return end
  Chrome.dialogueFrame()
  M.drawText()
end

return M
