local bit = require("bit")
local band, rshift = bit.band, bit.rshift
local M = {}

-- pokeruby/src/palette.c:541
function M.install(pal)
  local normal = pal.update
  pal.update = function(self)
    if not self.rsFastFade then return normal(self) end
    if self.pending ~= 0 then return 255 end
    if self:_finishing() then
      if not self.active then self.rsFastFade = nil end
      return self.active and 1 or 0
    end
    local offset = self.objToggle == 0 and 0 or 256
    for i = offset, offset + 255 do
      local a, b = self.unfaded[i], self.faded[i]
      local r = math.min(band(a, 31), band(b, 31) + 2)
      local g = math.min(band(rshift(a, 5), 31), band(rshift(b, 5), 31) + 2)
      local blue = math.min(band(rshift(a, 10), 31), band(rshift(b, 10), 31) + 2)
      self.faded[i] = r + g * 32 + blue * 1024
    end
    self.objToggle = 1 - self.objToggle
    if self.objToggle == 0 then
      self.y = math.max(0, self.y - 2)
      if self.y == 0 then
        for i = 0, 511 do self.faded[i] = self.unfaded[i] end
        self.finishing = true
      end
    end
    self.pending = self.selected
    return 1
  end
end

function M.begin(pal)
  pal:resetFadeControl()
  pal.rsFastFade, pal.active, pal.y, pal.selected = true, true, 31, 0xFFFFFFFF
  for i = 0, 511 do pal.faded[i] = 0 end
  pal:update()
end
return M
