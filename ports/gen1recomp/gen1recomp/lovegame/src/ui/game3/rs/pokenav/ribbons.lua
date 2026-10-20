local Data = require("src.ui.game3.rs.pokenav.condition_data")
local Gfx = require("src.ui.game3.rs.pokenav.gfx")
local Kit = require("src.ui.game3.rse.scene_kit")
local Pokemon = require("src.core.game3.pokemon")
local Bits = require("src.core.game3.rse.ribbons")
local Native = require("src.core.game3.profiles.rs.pokenav")
local M = {}; M.__index = M
function M.new(session, rows, index)
  local self = setmetatable({session = session, rows = rows, index = index, man = Gfx.manifest("pokenav_ribbons"),
    condition = Gfx.manifest("pokenav_condition"), selecting = false, busy = 5, monX = -80}, M)
  self:load(); return self
end
function M:load()
  self.mon = assert(Data.mon(self.session, self.rows[self.index]), "native ribbons mon")
  self.normal, self.gift = {}, {}
  local id = 0
  for _, field in ipairs(self.man.fields) do
    local value = Bits.get(self.mon, field.name)
    local dst = id > 24 and self.gift or self.normal
    for j = 0, value - 1 do dst[#dst + 1] = id + j end
    id = id + field.count
  end
  self.row, self.column = #self.normal > 0 and 0 or 3, 0
  self.rowCounts = {math.min(9, #self.normal), math.min(9, math.max(0, #self.normal - 9)),
    math.min(9, math.max(0, #self.normal - 18)), #self.gift}
end
function M:ribbonId()
  return self.row == 3 and self.gift[self.column + 1] or self.normal[self.row * 9 + self.column + 1]
end
function M:move(r)
  local row, column = self.row, self.column
  local delta = r.up and -1 or r.down and 1 or 0
  if delta ~= 0 then
    local nextRow = row + delta
    while nextRow >= 0 and nextRow <= 3 and self.rowCounts[nextRow + 1] == 0 do nextRow = nextRow + delta end
    if nextRow >= 0 and nextRow <= 3 then row, column = nextRow, math.min(column, self.rowCounts[nextRow + 1] - 1) end
  elseif r.left and column > 0 then column = column - 1
  elseif r.right and column < self.rowCounts[row + 1] - 1 then column = column + 1 end
  if row == self.row and column == self.column then return false end
  self.row, self.column = row, column; self.scale, self.busy = 128, 4; return true
end
function M:frame(inp)
  if self.busy > 0 then
    self.monX = math.min(0, self.monX + 16)
    if self.selecting then self.scale = math.min(256, (self.scale or 128) + 32) end
    self.busy = self.busy - 1; return
  end
  local n, r = inp.new or {}, inp.rep or {}
  if self.selecting then
    if n.b then self.selecting = false; Kit.playSe("SE_SELECT")
    elseif self:move(r) then Kit.playSe("SE_SELECT") end
  else
    if n.b then return "exit" end
    if n.a then self.selecting, self.scale, self.busy = true, 128, 4; Kit.playSe("SE_SELECT"); return end
    local delta = r.up and -1 or r.down and 1 or 0
    if delta ~= 0 and self.index + delta >= 1 and self.index + delta <= #self.rows then
      self.index = self.index + delta; self:load(); self.monX, self.busy = -80, 12; Kit.playSe("SE_SELECT")
    end
  end
end
function M:description()
  local id = self:ribbonId()
  if id == nil then return {} end
  if id < 25 then return assert(self.man.descriptions[id], "native ribbon description") end
  local index, offset, value = Native.giftDescriptionIndex(self.session, id)
  self.missingGiftDescription = nil
  if index == nil then return {} end
  local lines = self.man.giftDescriptions[index]
  if not lines then
    self.missingGiftDescription = {ribbonId = id, saveBlock1Offset = offset, value = value}
    return {}
  end
  return lines
end
function M:draw()
  local pal, win = self.man.palettes.background, self.man.window
  local colors = Gfx.colors(pal, win.backgroundColor == 0 and 0 or win.paletteNum * 16 + win.backgroundColor,
    win.paletteNum * 16 + win.foregroundColor, win.paletteNum * 16 + win.shadowColor)
  Gfx.fill(Gfx.color(pal, 0), 0, 0, 240, 160); Gfx.draw(self.man.layers.bg, 0, 0)
  Gfx.draw(self.condition.layers.portrait_ribbons, self.monX, 0)
  Data.drawName(self.mon, self.rows[self.index], 104, 8, pal, 104, false, 0)
  local pic = Pokemon.monFrontPic(self.mon)
  if pic then love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(pic.image, 6 + self.monX, 72) end
  Gfx.text(self.index .. "/" .. #self.rows, 8, 40, colors)
  for i, id in ipairs(self.normal) do Gfx.draw(self.man.icons[id].small, 88 + (i - 1) % 9 * 16, 32 + math.floor((i - 1) / 9) * 16) end
  for i, id in ipairs(self.gift) do Gfx.draw(self.man.icons[id].small, 88 + (i - 1) * 16, 80) end
  if self.selecting then
    local id, scale = self:ribbonId(), (self.scale or 256) / 256
    if id ~= nil then
      Gfx.draw(self.man.icons[id].large, 96 + self.column * 16 - 16 * scale, 40 + self.row * 16 - 16 * scale,
        nil, nil, nil, nil, nil, scale, scale)
    end
    local lines = self:description()
    for i, text in ipairs(lines) do Gfx.text(text, 96, 104 + (i - 1) * 16, colors, "native_" .. win.fontNum, 128) end
  else Gfx.text(self.man.strings.Ribbons .. " " .. self.rows[self.index].value, 96, 104, colors) end
end
function M:help() return self.selecting and 11 or 5 end
return M
