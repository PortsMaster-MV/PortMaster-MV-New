local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Data = require("src.ui.game3.rs.battle_tower_records_data")
local Board = {visible = false}
local st = {}
local function fieldOwner()
  local Space = package.loaded["src.core.game3.scripting.space"]
  return Space and Space.vm
end
function Board.hide()
  if st.canvas and st.canvas.release then st.canvas:release() end
  Board.visible, st = false, {}
end
function Board.reset() Board.hide() end
function Board.show(session)
  local p = require("src.core.game3.profile").forSession(session)
  assert(p.id == "ruby" or p.id == "sapphire", "native RS records board requires Ruby/Sapphire")
  Board.hide()
  local man = assert(Kit.manifest("rse/battle_tower_records"), "native RS records-board pack missing")
  assert(man.assetLayout == "rs", "native RS records-board layout required")
  st = {session = session, manifest = man, model = Data.model(session, man), owner = fieldOwner(), erased = {}, dirty = true}
  Board.visible = true
  return true
end
function Board.isVisible()
  if Board.visible and st.owner ~= fieldOwner() then Board.hide() end
  return Board.visible
end
function Board.model() return st.model end
function Board.eraseBox(left, top, right, bottom)
  if not Board.isVisible() then return false end
  left, top, right, bottom = tonumber(left) or 0, tonumber(top) or 0, tonumber(right) or 0, tonumber(bottom) or 0
  if left > right then left, right = right, left end
  if top > bottom then top, bottom = bottom, top end
  local f = st.manifest.geometry.frame
  if right < f[1] or bottom < f[2] or left > f[3] or top > f[4] then return false end
  if left <= f[1] and top <= f[2] and right >= f[3] and bottom >= f[4] then Board.hide(); return true end
  st.erased[#st.erased + 1] = {left * 8, top * 8, (right - left + 1) * 8, (bottom - top + 1) * 8}
  st.dirty = true; return true
end
local function contents()
  local man, model = st.manifest, st.model
  local win, g = man.window, man.geometry
  local function color(index) return Kit.color555(man.palette[index + 1]) end
  local colors = {fg = color(win.foregroundColor), bg = color(win.backgroundColor), shadow = color(win.shadowColor)}
  local opts = {font = "native_" .. win.fontNum, colors = colors, letterSpacing = win.spacing}
  local function measure(text) return Font.measure(text, opts) end
  local function text(value, x, y) Font.draw(value, x * 8, y * 8, opts) end
  local f = g.frame
  Chrome.stdFrame(f[1] + 1, f[2] + 1, f[3] - f[1] - 1, f[4] - f[2] - 1)
  local title = g.title
  Font.draw(model.title, title[1] * 8 + Data.centerOffset(title[3], measure(model.title)), title[2] * 8, opts)
  for x = g.divider[1], g.divider[2] do Font.drawGlyph(g.dividerGlyph, x * 8, g.divider[3] * 8, opts) end
  for i, row in ipairs(model.rows) do
    text(row.level, g.levels[i][1], g.levels[i][2])
    text(row.label, g.current[i][1], g.current[i][2])
    text(row.recordLabel, g.record[i][1], g.record[i][2])
    text(Data.streakText(man.strings.streak, row.streak, g.numberWidth, measure), g.streakX, g.current[i][2])
    text(Data.streakText(man.strings.streak, row.record, g.numberWidth, measure), g.streakX, g.record[i][2])
  end
end
function Board.draw()
  if not Board.isVisible() then return end
  if not st.canvas then st.canvas = love.graphics.newCanvas(240, 160); st.canvas:setFilter("nearest", "nearest") end
  if st.dirty then
    love.graphics.push("all")
    love.graphics.setCanvas(st.canvas); love.graphics.origin(); love.graphics.setShader()
    love.graphics.setScissor(0, 0, 240, 160); love.graphics.clear(0, 0, 0, 0)
    contents()
    love.graphics.setBlendMode("replace", "premultiplied")
    love.graphics.setColor(0, 0, 0, 0)
    for _, rect in ipairs(st.erased) do love.graphics.rectangle("fill", unpack(rect)) end
    love.graphics.pop(); st.dirty = false
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(st.canvas, 0, 0)
end
return Board
