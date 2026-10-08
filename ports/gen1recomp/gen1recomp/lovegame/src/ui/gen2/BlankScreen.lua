-- ClearBGPalettes (home/tilemap.asm:1), the white hold every full-screen page
-- opens and closes with: _FlyMap (engine/pokegear/pokegear.asm:1979) and
-- ExitAllMenus (home/map.asm:2282).

local Chrome = require("src.ui.gen2.Chrome")

local BlankScreen = {}
BlankScreen.__index = BlankScreen
BlankScreen.isOpaque = true

-- WaitBGMap's `ld c, 4 / call DelayFrames` (home/tilemap.asm:3)
BlankScreen.FRAMES = 4

function BlankScreen.new(game, opts)
  opts = opts or {}
  return setmetatable({
    game = game,
    left = opts.frames or BlankScreen.FRAMES,
    onDone = opts.onDone,
  }, BlankScreen)
end

function BlankScreen:drawsWidescreen() return true end

function BlankScreen:draw()
  local G = love.graphics
  G.setColor(1, 1, 1, 1)
  G.rectangle("fill", 0, 0, Chrome.SCREEN_W * 8, Chrome.SCREEN_H * 8)
end

function BlankScreen:drawWidescreen(winW, winH)
  local G = love.graphics
  Chrome.letterbox(winW, winH, 1, 1, 1)
  local scale = Chrome.fitScale(winW, winH)
  G.push()
  G.translate(Chrome.fitOrigin(winW, winH, scale))
  G.scale(scale, scale)
  self:draw()
  G.pop()
end

function BlankScreen:update()
  self.left = self.left - 1
  if self.left > 0 then return end
  local done = self.onDone
  self.onDone = nil
  if done then done() end
end

return BlankScreen
