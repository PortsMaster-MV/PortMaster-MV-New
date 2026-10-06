local M = {}; M.__index = M
function M.new(count)
  local self = setmetatable({count = count, slots = {}}, M)
  for i = 0, count do self.slots[i] = {delay = i * 16 + 1, age = 0, visible = count == 9, state = count == 9 and "all" or "chain"} end
  return self
end
function M:chain()
  for i = 0, self.count do local s = self.slots[i]; s.delay, s.state = i * 16 + 1, "chain" end
end
function M:showAll()
  for i = 0, self.count do local s = self.slots[i]; s.visible, s.age = true, 0 end
end
function M:frame()
  for i = 0, self.count do
    local s = self.slots[i]
    if s.visible then s.age = s.age + 1 end
    if s.state == "chain" then
      if s.delay > 0 then s.delay = s.delay - 1; if s.delay == 0 then s.visible, s.age = true, 0 end end
      if s.visible and s.age >= 35 then
        s.visible = false
        if i == self.count then
          if i == 9 then self:showAll(); s.state = "all" else s.state, s.wait = "wait", 0 end
        else s.state = "idle" end
      end
    elseif s.state == "all" and s.age >= 35 then s.state, s.wait = "wait", 0
    elseif s.state == "wait" then
      s.wait = s.wait + 1
      if s.wait > 60 then self:chain() end
    end
  end
end
function M:draw(man, x, y)
  local Gfx = require("src.ui.game3.rs.pokenav.gfx")
  for i = 0, self.count do local s = self.slots[i]
    if s.visible and s.age < 35 then
      local coord = assert(man.sparkleCoords[i + 1])
      Gfx.frame(man.sprites.sparkles, math.floor(s.age / 5), x + coord[1] - 8, y + coord[2] - 8)
    end
  end
end
return M
