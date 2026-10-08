local Data = require("src.ui.game3.rs.pokenav.condition_data")
local Graph = require("src.ui.game3.rs.pokenav.condition_graph")
local Gfx = require("src.ui.game3.rs.pokenav.gfx")
local Kit = require("src.ui.game3.rse.scene_kit")
local Pokemon = require("src.core.game3.pokemon")
local M = {}; M.__index = M
function M.new(session, rows, index, category)
  local man = Gfx.manifest("pokenav_condition")
  local self = setmetatable({session = session, man = man, searchMode = rows ~= nil, rows = rows or Data.party(session),
    index = index or 1, category = category, graph = Graph.new(man.graph), monX = -80, frames = 0}, M)
  self:load(self.index)
  self.graph:setNewPositions(Graph.centerPositions(), self:positions())
  self.phase, self.busy = "enter", 10
  return self
end
function M:row() return self.rows[self.index] end
function M:load(index)
  self.displayIndex = index
  local row = self.rows[index]
  self.mon = Data.mon(self.session, row)
  local sheen = self.mon and Data.stat(self.mon, "sheen") or 0
  self.sparkles = self.mon and require("src.ui.game3.rs.pokenav.sparkles").new(sheen == 255 and 9 or math.floor(sheen / 29)) or nil
end
function M:positions()
  local mon = Data.mon(self.session, self:row())
  return mon and self.graph:calcPositions(Data.conditions(mon)) or Graph.centerPositions()
end
function M:change(delta)
  local nextIndex = self.searchMode and self.index + delta or (self.index - 1 + delta) % #self.rows + 1
  if nextIndex < 1 or nextIndex > #self.rows or nextIndex == self.index then return end
  local old = self.mon ~= nil
  self.index = nextIndex
  self.graph:setNewPositions(self.graph.curPositions, self:positions())
  self.newValid = Data.mon(self.session, self:row()) ~= nil
  self.phase, self.busy = "switch", 10
  if not old then self:load(nextIndex); self.monX = -80; self.phase = "enter" end
  Kit.playSe("SE_SELECT")
end
function M:frame(inp)
  self.frames = self.frames + 1
  if self.busy > 0 then
    self.graph:tryUpdate()
    if self.phase == "enter" then self.monX = math.min(0, self.monX + 16)
    elseif self.phase == "switch" then
      if self.busy > 5 then self.monX = math.max(-80, self.monX - 16)
      else
        if self.busy == 5 then self:load(self.index) end
        self.monX = self.newValid and math.min(0, self.monX + 16) or -80
      end
    elseif self.phase == "exit" then self.monX = math.max(-80, self.monX - 16) end
    self.busy = self.busy - 1
    if self.busy == 0 then
      if self.phase == "exit" then return "exit" end
      self.phase = "input"
    end
    return
  end
  if self.sparkles then self.sparkles:frame() end
  local n, held = inp.new or {}, inp.held or {}
  if self.markings then
    local input = {wasPressed = function(_, key) return n[key] end}
    local action = require("src.ui.game3.rs.storage_markings").input(self.markings, input)
    if action then Kit.playSe("SE_SELECT") end
    if action == "closed" then self.markings = nil end
    return
  end
  if held.up then self:change(-1); return elseif held.down then self:change(1); return end
  if n.b or (n.a and not self.searchMode and self:row().cancel) then
    self.graph:setNewPositions(self.graph.curPositions, Graph.centerPositions())
    self.phase, self.busy = "exit", 10; Kit.playSe("SE_SELECT")
  elseif n.a and self.searchMode and self.mon then
    self.markings = require("src.ui.game3.rs.storage_markings").open(self.mon); Kit.playSe("SE_SELECT")
  end
end
function M:draw()
  local man, pal = self.man, self.man.palettes.condition
  Gfx.fill(Gfx.color(pal, 0), 0, 0, 240, 160)
  Gfx.draw(man.layers[self.searchMode and "search" or "party"], 0, 0)
  self.graph:draw(Gfx.image(man.layers.graph), 11, 4, Gfx.image(man.layers[self.searchMode and "search" or "party"]))
  Gfx.draw(man.layers.portrait, self.monX, 0)
  local row = self.rows[self.displayIndex]
  if self.mon then
    Data.drawName(self.mon, row, 104, 8, pal, 104)
    if self.searchMode then
      local text = Data.location(self.session, row, man)
      Gfx.text(text, 104 + math.floor((64 - Gfx.measure(text)) / 2), 24, Gfx.colors(pal, 191, 177, 181), "native_3", 64)
      Gfx.text(man.strings.Number .. " " .. self:row().rank, 8, 48, Gfx.colors(pal, 191, 177, 181))
    end
    local pic = Pokemon.monFrontPic(self.mon)
    if pic then love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(pic.image, 6 + self.monX, 72) end
    if self.sparkles and self.busy == 0 then self.sparkles:draw(man, 38 + self.monX, 104) end
  end
  if not self.searchMode then
    local valid = #self.rows - 1
    for i = 0, 5 do
      if i < valid then Gfx.frame(man.sprites.pokeball, self.index == i + 1 and 0 or 1, 218, i * 20)
      else Gfx.draw(man.sprites.empty, 226, 4 + i * 20) end
    end
    Gfx.draw(self.index == #self.rows and man.sprites.cancelSelected or man.sprites.cancelInactive, 206, 120)
  end
  local header = man.headers[self.searchMode and Data.SEARCH_KEYS[self.category + 1] or "party"]
  Gfx.draw(header, 0, 28)
  if self.markings then love.graphics.push(); love.graphics.translate(0, 16); require("src.ui.game3.rs.storage_markings").draw(self.markings); love.graphics.pop() end
end
function M:help() return self.markings and 3 or self.searchMode and 2 or 1 end
return M
