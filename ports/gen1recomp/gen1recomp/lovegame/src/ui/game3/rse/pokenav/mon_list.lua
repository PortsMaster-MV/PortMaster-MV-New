local Gfx = require("src.ui.game3.rse.pokenav.gfx")

local List = {}
List.__index = List

-- pokeemerald/src/pokenav_ribbons_list.c:679
List.ITEM_X = 13
List.WIDTH = 17
List.TOP = 1
List.MAX_SHOWED = 8

-- pokeemerald/src/pokenav_list.c:944
function List.new(entries, startIndex)
  local self = setmetatable({ entries = entries or {}, top = startIndex or 0, sel = 0, scrollPx = 0, arrowTimer = 0,
    arrowOff = 0, arrowsHidden = false }, List)
  local n, max = #self.entries, List.MAX_SHOWED
  if max >= n then
    self.top = 0
    self.sel = startIndex or 0
  elseif self.top + max > n then
    self.sel = self.top + max - n
    self.top = (startIndex or 0) - self.sel
  end
  return self
end

function List:count() return #self.entries end
function List:selectedIndex() return self.top + self.sel end
function List:selected() return self.entries[self:selectedIndex() + 1] end

-- pokeemerald/src/pokenav_list.c:249
function List:showUp() return self.top ~= 0 end
function List:showDown() return self.top + List.MAX_SHOWED < #self.entries end

-- pokeemerald/src/pokenav_list.c:264
function List:moveWindow(delta)
  if delta < 0 and self.top + delta < 0 then delta = -self.top end
  if delta > 0 then
    local index = self.top + List.MAX_SHOWED
    if index + delta >= #self.entries then delta = #self.entries - index end
  end
  self.top = self.top + delta
  self.scrollPx = delta * 16
end

-- pokeemerald/src/pokenav_list.c:351
function List:cursorUp()
  if self.sel ~= 0 then self.sel = self.sel - 1 return 1 end
  if self:showUp() then self:moveWindow(-1) return 2 end
  return 0
end

-- pokeemerald/src/pokenav_list.c:368
function List:cursorDown()
  if self.top + self.sel >= #self.entries - 1 then return 0 end
  if self.sel < List.MAX_SHOWED - 1 then self.sel = self.sel + 1 return 1 end
  if self:showDown() then self:moveWindow(1) return 2 end
  return 0
end

-- pokeemerald/src/pokenav_list.c:387
function List:pageUp()
  if self:showUp() then
    self:moveWindow(-(self.top >= List.MAX_SHOWED and List.MAX_SHOWED or self.top))
    return 2
  elseif self.sel ~= 0 then
    self.sel = 0
    return 1
  end
  return 0
end

-- pokeemerald/src/pokenav_list.c:409
function List:pageDown()
  local offscreen = math.max(0, #self.entries - List.MAX_SHOWED)
  if self:showDown() then
    local scroll = offscreen - self.top
    if self.top + List.MAX_SHOWED <= offscreen then scroll = List.MAX_SHOWED end
    self:moveWindow(scroll)
    return 2
  end
  local last = (#self.entries >= List.MAX_SHOWED and List.MAX_SHOWED or #self.entries) - 1
  if self.sel >= last then return 0 end
  self.sel = last
  return 1
end

function List:scrolling() return self.scrollPx ~= 0 end

-- pokeemerald/src/pokenav_list.c:301
function List:frame()
  if self.scrollPx > 0 then
    self.scrollPx = math.max(0, self.scrollPx - 16)
  elseif self.scrollPx < 0 then
    self.scrollPx = math.min(0, self.scrollPx + 16)
  end
  -- pokeemerald/src/pokenav_list.c:897
  self.arrowTimer = self.arrowTimer + 1
  if self.arrowTimer > 3 then
    self.arrowTimer = 0
    self.arrowOff = (self.arrowOff + 1) % 8
  end
end

-- pokeemerald/src/pokenav_list.c:211
function List:drawItems(pal, buffer)
  local x0, y0 = List.ITEM_X * 8, List.TOP * 8
  love.graphics.setScissor(x0, y0, List.WIDTH * 8, List.MAX_SHOWED * 16)
  local extra = math.ceil(math.abs(self.scrollPx) / 16)
  for r = -extra, List.MAX_SHOWED - 1 + extra do
    local e = self.entries[self.top + r + 1]
    if e then
      local y = y0 + r * 16 + self.scrollPx
      for _, seg in ipairs(buffer(e) or {}) do
        Gfx.text(seg.text, x0 + 8 + (seg.x or 0), y + 1, seg.colors)
      end
    end
  end
  love.graphics.setScissor()
end

-- pokeemerald/src/pokenav_list.c:839
function List:drawArrows()
  local arrows = Gfx.manifest().sprites.arrows
  local r = arrows.right
  if not self.arrowsHidden then
    Gfx.drawImage(arrows.png, r[1], r[2], r[3], r[4], List.ITEM_X * 8 + 3 - 4, (List.TOP + 1) * 8 - 8 + self.sel * 16)
  end
  local ax = List.ITEM_X * 8 + (List.WIDTH - 1) * 4 - 8
  if self:showDown() and not self.arrowsHidden then
    local d = arrows.down
    Gfx.drawImage(arrows.png, d[1], d[2], d[3], d[4], ax, List.TOP * 8 + List.MAX_SHOWED * 16 - 4 + self.arrowOff)
  end
  if self:showUp() and not self.arrowsHidden then
    local u = arrows.up
    Gfx.drawImage(arrows.png, u[1], u[2], u[3], u[4], ax, List.TOP * 8 - 4 - self.arrowOff)
  end
end

return List
