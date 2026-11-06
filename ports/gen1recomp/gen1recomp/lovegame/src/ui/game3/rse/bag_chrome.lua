local Kit = require("src.ui.game3.rse.scene_kit")

local BagChrome = {}

BagChrome.SUB = "rse/bag"

-- pokeemerald/src/list_menu.c:102
BagChrome.ARROWS = {
  left = { frame = 0, flipX = false, flipY = false, bounce = { bounceDir = 0, multiplier = 2, frequency = 8 } },
  right = { frame = 0, flipX = true, flipY = false, bounce = { bounceDir = 0, multiplier = 2, frequency = -8 } },
  up = { frame = 1, flipX = false, flipY = false, bounce = { bounceDir = 1, multiplier = 2, frequency = 8 } },
  down = { frame = 1, flipX = false, flipY = true, bounce = { bounceDir = 1, multiplier = 2, frequency = -8 } },
}

local quads = {}

function BagChrome.manifest()
  return Kit.manifest(BagChrome.SUB)
end

function BagChrome.ready()
  return BagChrome.manifest() ~= nil
end

function BagChrome.image(path)
  return Kit.image(path)
end

local function quad(key, x, y, w, h, sw, sh)
  local k = key .. ":" .. x .. ":" .. y .. ":" .. w .. ":" .. h
  local q = quads[k]
  if not q then
    q = love.graphics.newQuad(x, y, w, h, sw, sh)
    quads[k] = q
  end
  return q
end

function BagChrome.drawFrame(entry, frame, x, y, opts)
  if not entry then return end
  opts = opts or {}
  local path = entry.png
  if opts.variant and entry.variants and entry.variants[opts.variant] then path = entry.variants[opts.variant] end
  local img = Kit.image(path)
  if not img then return end
  local sw, sh = img:getDimensions()
  local q = quad(path, 0, (frame or 0) * entry.h, entry.w, entry.h, sw, sh)
  local sx, sy = opts.flipX and -1 or 1, opts.flipY and -1 or 1
  local ox, oy = entry.w / 2, entry.h / 2
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, q, x + ox, y + oy, opts.rotation or 0, sx, sy, ox, oy)
end

function BagChrome.drawArrow(dir, cx, cy, t)
  local m = BagChrome.manifest()
  local spec = BagChrome.ARROWS[dir]
  if not (m and spec) then return end
  local dx, dy = require("src.ui.game3.list_menu").bounce(spec.bounce, t)
  local e = m.sprites.arrows
  BagChrome.drawFrame(e, spec.frame, cx - e.w / 2 + dx, cy - e.h / 2 + dy, { flipX = spec.flipX, flipY = spec.flipY })
end

function BagChrome.drawItemIcon(index, x, y, rotation, ox, oy)
  local m = BagChrome.manifest()
  local icons = m and m.icons
  if not icons then return end
  local img = Kit.rgbaImage(icons.rgba, icons.w, icons.h)
  if not img then return end
  local n = tonumber(index) or 0
  if n < 0 or n >= icons.count then n = icons.count - 1 end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, quad(icons.rgba, 0, n * 24, 24, 24, icons.w, icons.h), x, y, rotation or 0, 1, 1, ox or 0, oy or 0)
end

BagChrome.MENU_INFO = { TYPE = 19, POWER = 20, ACCURACY = 21, PP = 22 }

-- pokeemerald/src/menu.c:2098
function BagChrome.drawMenuInfoIcon(iconId, x, y)
  local m = BagChrome.manifest()
  local info = m and m.menuInfo
  local r = info and info.icons[iconId + 1]
  local img = r and Kit.image(info.png)
  if not img then return false end
  local sw, sh = img:getDimensions()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, quad(info.png, r.x, r.y, r.w, r.h, sw, sh), x, y)
  return true
end

function BagChrome.returnIconIndex()
  local m = BagChrome.manifest()
  return m and m.icons and (m.icons.count - 1) or 0
end

function BagChrome.color(pal, index)
  return Kit.color555(pal and pal[index + 1] or 0)
end

return BagChrome
