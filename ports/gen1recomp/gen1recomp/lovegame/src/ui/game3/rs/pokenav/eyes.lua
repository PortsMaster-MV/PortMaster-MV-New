local Data = require("src.ui.game3.rs.pokenav.data")
local Gfx = require("src.ui.game3.rs.pokenav.gfx")
local Kit = require("src.ui.game3.rse.scene_kit")
local Trainers = require("src.core.game3.scripting.trainers")
local M = {}
M.__index = M
function M.new(session, game, man, region)
  return setmetatable({session = session, man = man, region = region, entries = Data.trainersEyes(session, game, man),
    index = 1, top = 1, detail = false, frames = 0, portraitX = -72, busy = 0}, M)
end
function M:frame(inp)
  self.frames = self.frames + 1
  if self.detail and self.portraitX < 0 then self.portraitX = math.min(0, self.portraitX + 8) end
  if self.busy > 0 then self.busy = self.busy - 1; return end
  local n, r = inp.new or {}, inp.rep or {}
  if n.b then
    Kit.playSe("SE_SELECT")
    if self.detail then self.detail = false; self.busy = 14 else return "exit" end
    return
  end
  if self.detail then
    local held = inp.held or {}
    local delta = held.up and -1 or held.down and 1 or 0
    if delta ~= 0 and self.index + delta >= 1 and self.index + delta <= #self.entries then
      self.index = self.index + delta; self.portraitX, self.busy = -72, 19; self:keepVisible(); Kit.playSe("SE_SELECT")
    end
  elseif n.a then
    self.detail, self.portraitX, self.busy = true, -72, 14; Kit.playSe("SE_SELECT")
  else
    local old = self.index
    if r.up and old > 1 then self.index = old - 1
    elseif r.down and old < #self.entries then self.index = old + 1
    elseif r.left and self.top > 1 then
      local delta = math.min(8, self.top - 1); self.top, self.index = self.top - delta, self.index - delta
    elseif r.right and self.top + 7 < #self.entries then
      local delta = math.min(8, #self.entries - self.top - 7); self.top, self.index = self.top + delta, self.index + delta
    end
    if old ~= self.index then self:keepVisible(); self.busy = 4; Kit.playSe("SE_SELECT") end
  end
end
function M:keepVisible()
  if self.index < self.top then self.top = self.index elseif self.index > self.top + 7 then self.top = self.index - 7 end
end
function M:draw(native, shell)
  local man, row = self.man, self.entries[self.index]
  local pal = man.palettes.eyes
  local backdrop = Gfx.color(pal, 0)
  Gfx.fill(backdrop, 0, 0, 240, 160)
  Gfx.draw(man.layers.eyes, 0, 8); Gfx.draw(man.layers.eyes, 0, -248)
  if math.floor(self.frames / 9) % 2 == 1 then
    Gfx.fill({0, 0, 0, 6 / 16}, 232, 8, 8, self.detail and 16 or 128)
  end
  if not row then return end
  local text = Gfx.colors(pal, 191, 177, 181)
  local left = Gfx.colors(pal, 0, 241, 248)
  local name = Data.sectionName(self.region, row.regionMapSectionId)
  Gfx.text(name, math.floor((88 - Gfx.measure(name)) / 2), 40, left, "native_3", 88)
  if self.detail then
    local info = assert(Trainers.get(row.opponentId), "native Trainer's Eyes trainer record missing")
    local heading = Gfx.colors(shell.palettes.detailHeading, 1, 15, 14)
    Gfx.text(info.className, 97, 8, heading, "native_3", 75)
    Gfx.text(info.name, 172, 8, heading, "native_3", 68)
    local lines = assert(man.descriptions[row.descriptionId], "native Trainer's Eyes description missing")
    local descriptions = {man.strings.Strategy, lines[1], man.strings.TrainersPokemon, lines[2], man.strings.SelfIntroduction, lines[3], lines[4]}
    -- strings.c:818
    local sectionHeading = Gfx.colors(pal, 95, 81, 85)
    Gfx.fill(Gfx.color(pal, 191), 96, 24, 144, 112)
    for i, line in ipairs(descriptions) do
      local colors = (i == 1 or i == 3 or i == 5) and sectionHeading or text
      Gfx.text(line, 97, 8 + i * 16, colors, "native_3", 136)
    end
    local pic = require("src.core.game3.trainer_pic").front(info.pic)
    if pic then love.graphics.draw(pic.image, 8 + self.portraitX, 72) end
    Gfx.draw(man.markers[row.rematchNo ~= 0 and "rematch" or "no_rematch"], 232, 8)
  else
    local labels = {{man.strings.NumberRegistered, 72}, {tostring(#self.entries), 88}, {man.strings.NumberBattles, 104},
      {tostring(math.min(99999, tonumber((self.session.gameStats or {})[9]) or 0)), 120}}
    for _, label in ipairs(labels) do Gfx.text(label[1], 80 - Gfx.measure(label[1]), label[2], left) end
    for i = 0, 7 do
      local entry = self.entries[self.top + i]
      if entry then
        local info = assert(Trainers.get(entry.opponentId), "native Trainer's Eyes trainer record missing")
        Gfx.text(info.className, 97, 8 + i * 16, text, "native_3", 75)
        Gfx.text(info.name, 172, 8 + i * 16, text, "native_3", 53)
        Gfx.draw(man.markers[entry.rematchNo ~= 0 and "rematch" or "no_rematch"], 232, 8 + i * 16)
      end
    end
    Gfx.draw(shell.sprites.listCursor, 91, 8 + (self.index - self.top) * 16)
    if #self.entries > 8 then
      local phase = math.floor(self.frames / 5) % 5
      local bob = phase < 4 and phase + 1 or 0
      if self.top > 1 then Gfx.frame(shell.sprites.listArrows, 0, 160, 4 - bob) end
      if self.top + 7 < #self.entries then Gfx.frame(shell.sprites.listArrows, 1, 160, 132 + bob) end
    end
  end
end
return M
