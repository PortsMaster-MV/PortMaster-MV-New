local Kit = require("src.ui.game3.rse.scene_kit")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")

local Gfx = {}

Gfx.SUB = "rse/pokenav"

-- pokeemerald/include/constants/characters.h:234
Gfx.TEXT = { TRANSPARENT = 0, WHITE = 1, DARK_GRAY = 2, LIGHT_GRAY = 3, RED = 4, LIGHT_RED = 5, GREEN = 6,
  LIGHT_GREEN = 7, BLUE = 8, LIGHT_BLUE = 9, DYNAMIC_1 = 10, DYNAMIC_5 = 14 }

local manifest

local function root()
  return require("src.core.game3.cache_paths").CACHE_ROOT
end

function Gfx.manifest()
  if manifest then return manifest end
  manifest = assert(Kit.loadLua(root() .. "/" .. Gfx.SUB .. "/manifest.lua"), "pokenav manifest missing from the cache")
  return manifest
end

function Gfx.reset()
  manifest = nil
end

function Gfx.image(entry)
  local path = type(entry) == "table" and entry.png or entry
  return Kit.image(path)
end

local quads = {}
function Gfx.quad(img, x, y, w, h)
  local key = tostring(img) .. ":" .. x .. ":" .. y .. ":" .. w .. ":" .. h
  local q = quads[key]
  if not q then
    q = love.graphics.newQuad(x, y, w, h, img:getWidth(), img:getHeight())
    quads[key] = q
  end
  return q
end

Gfx.dim = 0

function Gfx.setDim(y)
  Gfx.dim = math.max(0, math.min(16, tonumber(y) or 0)) / 16
end

function Gfx.tint(alpha)
  local k = 1 - Gfx.dim
  love.graphics.setColor(k, k, k, alpha or 1)
end

function Gfx.drawImage(entry, qx, qy, w, h, x, y, alpha, sx, sy, ox, oy)
  local img = Gfx.image(entry)
  if not img then return end
  Gfx.tint(alpha)
  love.graphics.draw(img, Gfx.quad(img, qx, qy, w, h), x, y, 0, sx or 1, sy or 1, ox or 0, oy or 0)
  love.graphics.setColor(1, 1, 1, 1)
end

function Gfx.drawFrame(entry, frame, x, y, w, h, alpha)
  Gfx.drawImage(entry, 0, frame * h, w, h, math.floor(x), math.floor(y), alpha)
end

function Gfx.color(pal, i)
  local c = Kit.color555(pal and pal[i] or 0)
  local k = 1 - Gfx.dim
  return { c[1] * k, c[2] * k, c[3] * k, 1 }
end

-- pokeemerald/src/menu.c:1917
function Gfx.colors(pal, bg, fg, shadow)
  return { bg = Gfx.color(pal, bg), fg = Gfx.color(pal, fg), shadow = Gfx.color(pal, shadow) }
end

function Gfx.fill(pal, i, x, y, w, h)
  love.graphics.setColor(Gfx.color(pal, i))
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(1, 1, 1, 1)
end

function Gfx.text(s, x, y, colors, font)
  FrlgFont.draw(s, x, y, { colors = colors, font = font })
end

function Gfx.measure(s, font)
  return FrlgFont.measure(s, { font = font }) or 0
end

function Gfx.plain(key, ctx)
  if not key then return "" end
  return RomText.plain(key, ctx)
end

-- pokeemerald/src/pokenav_main_menu.c:333
function Gfx.drawHeader(headerY)
  local man = Gfx.manifest()
  local y = math.floor(headerY)
  Gfx.drawImage(man.layers.header, 0, y, 256, 256 - y, 0, 0)
end

-- pokeemerald/src/pokenav_main_menu.c:574
function Gfx.drawHelpBar(textKey, headerY)
  local man = Gfx.manifest()
  local pal = man.palettes.header
  local y = 22 * 8 - math.floor(headerY)
  Gfx.fill(pal, 4, 8, y, 128, 16)
  Gfx.fill(pal, 5, 8, y, 128, 1)
  if textKey then
    Gfx.text(Gfx.plain(textKey), 8, y + 1, Gfx.colors(pal, Gfx.TEXT.RED, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY))
  end
end

-- pokeemerald/src/pokenav_main_menu.c:580
function Gfx.drawSpin(frame, x, y)
  local man = Gfx.manifest()
  Gfx.drawFrame(man.sprites.spin, frame % 8, x - 16, y - 16, 32, 32)
end

local LeftHeader = {}
LeftHeader.__index = LeftHeader

function Gfx.leftHeader()
  return setmetatable({ key = nil, x = -96, startX = -96, endX = -96, t = 0, dur = 0, y = 0, frame1 = 1, x2 = 64, visible = false }, LeftHeader)
end

-- pokeemerald/src/pokenav_main_menu.c:822
function LeftHeader:move(startX, endX, duration)
  self.x = startX
  self.acc = startX * 16
  self.step = math.floor((endX - startX) * 16 / duration)
  self.dur = duration
  self.endX = endX
  self.moving = true
end

-- pokeemerald/src/pokenav_main_menu.c:756
function LeftHeader:show(key, isMain, onRight, sub)
  self.key = key
  self.frame1 = 1
  self.sub = sub
  self.y = isMain and 0x10 or 0x30
  if sub then
    if onRight then self:move(256, 192, 12) else self:move(-96, 16, 12) end
  else
    if onRight then self:move(256, 160, 12) else self:move(-96, 32, 12) end
  end
end

-- pokeemerald/src/pokenav_main_menu.c:790
function LeftHeader:hide(onRight)
  if self.sub then
    if onRight then self:move(192, 256, 12) else self:move(16, -96, 12) end
  else
    if onRight then self:move(192, 256, 12) else self:move(32, -96, 12) end
  end
end

-- pokeemerald/src/pokenav_main_menu.c:832
function LeftHeader:update()
  if not self.moving then return end
  if self.dur ~= 0 then
    self.dur = self.dur - 1
    self.acc = self.acc + self.step
    self.x = math.floor(self.acc / 16)
    self.visible = not (self.x < -16 or self.x > 256)
  else
    self.x = self.endX
    self.moving = false
  end
end

function LeftHeader:busy()
  return self.moving == true
end

-- pokeemerald/src/pokenav_main_menu.c:631
function LeftHeader:draw()
  if not self.key or not self.visible then return end
  local e = Gfx.manifest().leftHeaders[self.key]
  if not e then return end
  if self.sub then
    Gfx.drawFrame(e, 0, self.x - 16, self.y + 18 - 8, 32, 16)
    Gfx.drawFrame(e, 1, self.x + 32 - 16, self.y + 18 - 8, 32, 16)
    return
  end
  local x2 = (self.key == "hoenn_map") and 56 or 64
  Gfx.drawFrame(e, 0, self.x - 32, self.y - 16, 64, 32)
  Gfx.drawFrame(e, self.frame1 or 1, self.x + x2 - 32, self.y - 16, 64, 32)
end

-- pokeemerald/src/pokenav_main_menu.c:474
function Gfx.lerp555(a, b, n, i)
  if i <= 0 then return a end
  if i >= n then return b end
  local function ch(c, s) return math.floor(c / 2 ^ s) % 32 end
  local out = 0
  for _, s in ipairs({ 0, 5, 10 }) do
    local ca, cb = ch(a, s), ch(b, s)
    local d = math.floor(math.floor(((cb * 256) - (ca * 256)) / n) * i / 256)
    out = out + ((ca + d) % 32) * 2 ^ s
  end
  return out
end

return Gfx
