local Data = require("src.ui.game3.rs.pokenav.condition_data")
local Gfx = require("src.ui.game3.rs.pokenav.gfx")
local Kit = require("src.ui.game3.rse.scene_kit")
local M = {}; M.__index = M
function M.new(session, category, rows, index, ribbons)
  local self = setmetatable({session = session, category = category or 0, rows = rows or Data.search(session, category or 0, ribbons),
    index = index or 1, top = 1, frames = 0, busy = 0, ribbons = ribbons, man = Gfx.manifest("pokenav_condition")}, M)
  if index and #self.rows > 8 then self.top = math.min(index, #self.rows - 7) end
  return self
end
function M:frame(inp)
  self.frames = self.frames + 1
  if self.busy > 0 then self.busy = self.busy - 1; return end
  local n, r = inp.new or {}, inp.rep or {}
  if n.b then return "exit" end
  if n.a and #self.rows > 0 then return self.ribbons and "ribbon" or "graph" end
  local old = self.index
  if r.up and self.index > 1 then self.index = self.index - 1
  elseif r.down and self.index < #self.rows then self.index = self.index + 1
  elseif r.left and self.top > 1 then local delta = math.min(8, self.top - 1); self.index, self.top = self.index - delta, self.top - delta
  elseif r.right and self.top + 7 < #self.rows then local delta = math.min(8, #self.rows - self.top - 7); self.index, self.top = self.index + delta, self.top + delta end
  if old ~= self.index then
    if self.index < self.top then self.top = self.index elseif self.index > self.top + 7 then self.top = self.index - 7 end
    self.busy = 4; Kit.playSe("SE_SELECT")
  end
end
function M:draw(native, shell)
  local key = self.ribbons and "ribbons_list" or "search_list"
  local pal = self.man.palettes[key]
  Gfx.fill(Gfx.color(pal, 0), 0, 0, 240, 160)
  Gfx.draw(self.man.layers[key], 0, 8); Gfx.draw(self.man.layers[key], 0, -248)
  local colors = Gfx.colors(pal, 191, 177, 181)
  for i = 0, 7 do
    local row = self.rows[self.top + i]
    local mon = Data.mon(self.session, row)
    if mon then Data.drawName(mon, row, 104, 8 + 16 * i, pal, 136, self.ribbons) end
  end
  if #self.rows > 0 then
    local row = self.rows[self.index]
    local label = self.ribbons and (self.index .. "/" .. #self.rows) or (self.man.strings.Number .. " " .. row.rank)
    Gfx.text(label, 8, 48, colors)
    Gfx.draw(shell.sprites.listCursor, 91, 8 + 16 * (self.index - self.top))
  end
  local phase = math.floor(self.frames / 5) % 5
  local bob = phase < 4 and phase + 1 or 0
  if self.top > 1 then Gfx.frame(shell.sprites.listArrows, 0, 160, 4 - bob) end
  if self.top + 7 < #self.rows then Gfx.frame(shell.sprites.listArrows, 1, 160, 132 + bob) end
  if not self.ribbons then Gfx.draw(self.man.headers[Data.SEARCH_KEYS[self.category + 1]], 0, 28) end
end
function M:help() return self.ribbons and 5 or 4 end
return M
