local Data = require("src.ui.game3.rs.pokenav.data")
local Gfx = require("src.ui.game3.rs.pokenav.gfx")
local Kit = require("src.ui.game3.rse.scene_kit")
local M = {}
M.__index = M
local function trunc(v) return v >= 0 and math.floor(v) or math.ceil(v) end
function M.new(session, game, man)
  local pos, err = Data.playerPosition(man, session, game)
  if not pos then return nil, err end
  local zoomed = session.regionMapZoom == true
  local self = setmetatable({session = session, man = man, x = pos.x, y = pos.y, playerX = pos.x, playerY = pos.y, cave = pos.cave,
    zoomed = zoomed, scrollX = zoomed and pos.x * 8 - 52 or 0, scrollY = zoomed and pos.y * 8 - 68 or 0,
    scale = zoomed and 128 or 256, centerX = zoomed and 56 or 0, centerY = zoomed and 72 or 0,
    cursorX = pos.x * 8 + 4, cursorY = pos.y * 8 + 4, moveFrames = 0, infoScroll = zoomed and 0 or 96, frames = 0}, M)
  self:setSection(pos.mapSec)
  return self
end
function M:setSection(id)
  self.section = id or Data.mapSecAt(self.man, self.x, self.y)
  self.kind = Data.mapSecType(self.man, self.session, self.section)
  self.name = Data.sectionName(self.man, self.section)
  self.pos = Data.positionWithin(self.man, self.section, self.x, self.y)
end
function M:frame(inp)
  self.frames = self.frames + 1
  if self.zoomFrame then self:updateZoom(); return end
  if self.moveFrames > 0 then
    if self.zoomed then self.scrollX, self.scrollY = self.scrollX + self.dx, self.scrollY + self.dy
    else self.cursorX, self.cursorY = self.cursorX + 2 * self.dx, self.cursorY + 2 * self.dy end
    self.moveFrames = self.moveFrames - 1
    if self.moveFrames == 0 then
      if self.zoomed then self.x, self.y = math.floor((self.scrollX + 44) / 8) + 1, math.floor((self.scrollY + 52) / 8) + 2
      else self.x, self.y = self.x + self.dx, self.y + self.dy end
      self:setSection()
    end
    return
  end
  local n, held = inp.new or {}, inp.held or {}
  if n.b then return "exit" end
  if n.a then Kit.playSe("SE_SELECT"); self:startZoom(); return end
  local dx, dy = 0, 0
  if self.zoomed then
    if held.up and self.scrollY > -52 then dy = -1 end
    if held.down and self.scrollY < 60 then dy = 1 end
    if held.left and self.scrollX > -44 then dx = -1 end
    if held.right and self.scrollX < 172 then dx = 1 end
  else
    if held.up and self.y > 2 then dy = -1 end
    if held.down and self.y < 16 then dy = 1 end
    if held.left and self.x > 1 then dx = -1 end
    if held.right and self.x < 28 then dx = 1 end
  end
  if dx ~= 0 or dy ~= 0 then self.dx, self.dy, self.moveFrames = dx, dy, self.zoomed and 8 or 4 end
end
function M:startZoom()
  self.zoomFrame, self.centerX, self.centerY = 0, 56, 72
  self.accX, self.accY = self.scrollX * 256, self.scrollY * 256
  self.targetX, self.targetY = self.zoomed and 0 or self.x * 8 - 52, self.zoomed and 0 or self.y * 8 - 68
  self.stepX, self.stepY = trunc((self.targetX * 256 - self.accX) / 16), trunc((self.targetY * 256 - self.accY) / 16)
  self.scaleAcc, self.scaleStep = self.scale * 256, self.zoomed and 0x800 or -0x800
end
function M:updateZoom()
  self.zoomFrame = self.zoomFrame + 1
  self.accX, self.accY = self.accX + self.stepX, self.accY + self.stepY
  self.scrollX, self.scrollY = math.floor(self.accX / 256), math.floor(self.accY / 256)
  self.scaleAcc = self.scaleAcc + self.scaleStep
  self.scale = math.floor(self.scaleAcc / 256)
  self.infoScroll = self.zoomed and math.min(96, self.infoScroll + 8) or math.max(0, self.infoScroll - 8)
  if self.zoomFrame == 16 then
    self.zoomed = not self.zoomed
    self.scrollX, self.scrollY, self.scale = self.targetX, self.targetY, self.zoomed and 128 or 256
    self.cursorX, self.cursorY = self.x * 8 + 4, self.y * 8 + 4
    self.zoomFrame = nil
  end
end
function M:close() self.session.regionMapZoom = self.zoomed end
function M:draw(native, shell)
  local factor = 256 / self.scale
  local x0 = self.centerX - (self.scrollX + self.centerX) * factor
  local y0 = self.centerY - (self.scrollY + self.centerY) * factor
  local img = Gfx.image(self.man.map)
  if img then
    local span = 512 * factor
    for ty = -1, 1 do for tx = -1, 1 do
      local x, y = math.floor(x0 + tx * span), math.floor(y0 + ty * span)
      if x < 240 and y < 160 and x + span > 0 and y + span > 0 then love.graphics.draw(img, x, y, 0, factor, factor) end
    end end
  end
  if not self.zoomFrame then
    if not self.cave or math.floor(self.frames / 17) % 2 == 0 then
      local who = (self.session.playerGender == "girl" or self.session.playerGender == "female" or self.session.playerGender == 1)
        and self.man.icons.may or self.man.icons.brendan
      local x, y = self.playerX * 8 + 4, self.playerY * 8 + 4
      if self.zoomed then x, y = self.playerX * 16 - 48 - self.scrollX * 2, self.playerY * 16 - 66 - self.scrollY * 2 end
      Gfx.draw(who, x - 8, y - 8)
    end
    if self.zoomed then Gfx.frame(self.man.cursors.large, ({0, 1, 2, 1})[math.floor(self.frames / 10) % 4 + 1], 32, 48)
    else Gfx.frame(self.man.cursors.small, math.floor(self.frames / 20) % 2, self.cursorX - 8, self.cursorY - 8) end
  end
  if self.infoScroll < 96 then
    love.graphics.push("all"); love.graphics.translate(0, self.infoScroll)
    require("src.ui.game3.chrome").stdFrame(14, 4, 15, 13)
    local Font = require("src.ui.game3.frlg_font"); Font.face()
    local colors = {fg = Font.STDPAL[1], bg = Font.STDPAL[15], shadow = Font.STDPAL[8]}
    if self.kind ~= 0 then Gfx.text(self.name, 112, 32, colors, "native_3", 120) end
    if self.kind == 2 then
      for _, row in ipairs(native.cityMaps) do
        if row.mapSec == self.section and row.index == self.pos then Gfx.draw(row, 128, 48); break end
      end
    elseif self.kind == 1 or self.kind == 4 then
      for i, name in ipairs(Data.landmarks(shell, self.session, self.section, self.pos, self.man.mapsecs.NONE)) do
        if i > 4 then break end
        Gfx.text(name, 112, 32 + i * 16, colors, "native_3", 120)
      end
    end
    love.graphics.pop()
  end
end
return M
