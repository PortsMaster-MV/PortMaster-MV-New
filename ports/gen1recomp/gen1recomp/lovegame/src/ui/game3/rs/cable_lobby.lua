local Stack = require("src.ui.game3.stack")
local Window = require("src.ui.game3.window")
local Font = require("src.ui.game3.frlg_font")
local Text = require("src.core.game3.rom_text")
local Strings = require("src.core.Strings")
local M = {ID = "rs_cable_lobby", open = false}
function M.isOpen() return M.open end
function M.show(opts)
  M.opts, M.cursor, M.open = opts, 1, true
  Stack.push(M.ID, M, {hideBelow = false, drawUnder = true})
end
function M.close() if M.open then M.open = false; Stack.pop(M.ID) end end
function M.reset() M.close(); M.opts = nil end
function M.rows() return M.opts.rows and M.opts.rows() or {} end
function M.handleInput(input)
  if not M.open or not M.opts then return end
  local Link = require("src.core.game3.link.init")
  local function pressed(key)
    if input and input.new then return input.new[key] end
    if input and input.wasPressed then return input:wasPressed(key) end
    return not input and Link.inputPressed(key)
  end
  local rows = M.rows()
  M.cursor = math.max(1, math.min(M.cursor, math.max(1, #rows)))
  if pressed("b") then return M.opts.cancel() end
  if pressed("up") then M.cursor = math.max(1, M.cursor - 1) end
  if pressed("down") then M.cursor = math.min(#rows, M.cursor + 1) end
  if pressed("a") or pressed("start") then
    local row = rows[M.cursor]
    if row and not row.disabled then M.opts.select(row) end
  end
end
function M.update(value)
  if not M.open or not M.opts then return end
  if M.opts.tick then M.opts.tick() end
  if type(value) == "table" then M.handleInput(value) end
end
function M.draw()
  if not M.open then return end
  Window.stdFrame(Window.template(1, 1, 28, 18))
  local rows, opts = M.rows(), {font = "native_3"}
  Font.draw(Text.plain("gOtherText_LinkStandby"), 16, 16, opts)
  local title = M.opts.title and M.opts.title() or ""
  Font.draw(title, 16, 40, opts)
  for i, row in ipairs(rows) do
    if i <= 6 then
      Font.draw((i == M.cursor and "> " or "  ") .. row.label, 16, 64 + (i - 1) * 16, opts)
    end
  end
  Font.draw(Strings("B: CANCEL"), 16, 144, opts)
end
return M
