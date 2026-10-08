local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local M = {}
function M.manifest(sub)
  local man = assert(Kit.manifest("rse/" .. sub), "native RS " .. sub .. " manifest missing")
  assert(man.assetLayout == "rs", "native RS PokeNav pack required")
  return man
end
function M.color(palette, index)
  local value = assert(palette[index + 1], "native PokeNav palette index")
  return Kit.color555(value)
end
function M.colors(palette, bg, fg, shadow)
  return {fg = M.color(palette, fg), shadow = M.color(palette, shadow), bg = bg == 0 and {0, 0, 0, 0} or M.color(palette, bg)}
end
function M.text(text, x, y, colors, font, width)
  return Font.draw(text, x, y, {font = font or "native_3", colors = colors, maxWidth = width or 240})
end
function M.measure(text, font) return Font.measure(text, {font = font or "native_3"}) or 0 end
function M.fill(color, x, y, w, h)
  love.graphics.setColor(color); love.graphics.rectangle("fill", x, y, w, h); love.graphics.setColor(1, 1, 1, 1)
end
local quads = {}
local brighten
function M.highlight(amount)
  if not brighten then
    brighten = love.graphics.newShader([[
      extern number coefficient;
      vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 pixel = Texel(tex, tc);
        vec3 rgb = floor(pixel.rgb * 31.0 + 0.5);
        rgb += floor((vec3(31.0) - rgb) * coefficient / 16.0);
        return vec4(rgb / 31.0, pixel.a) * color;
      }
    ]])
  end
  brighten:send("coefficient", amount); love.graphics.setShader(brighten)
end
function M.image(entry) return Kit.image(type(entry) == "table" and entry.png or entry) end
function M.draw(entry, x, y, w, h, qx, qy, color, sx, sy)
  local img = M.image(entry)
  if not img then return false end
  love.graphics.setColor(color or {1, 1, 1, 1})
  if w then
    local key = tostring(img) .. ":" .. (qx or 0) .. ":" .. (qy or 0) .. ":" .. w .. ":" .. h
    local q = quads[key]
    if not q then q = love.graphics.newQuad(qx or 0, qy or 0, w, h, img:getDimensions()); quads[key] = q end
    love.graphics.draw(img, q, math.floor(x), math.floor(y), 0, sx or 1, sy or 1)
  else love.graphics.draw(img, math.floor(x), math.floor(y), 0, sx or 1, sy or 1) end
  love.graphics.setColor(1, 1, 1, 1)
  return true
end
function M.frame(entry, frame, x, y)
  return M.draw(entry, x, y, entry.w, entry.h, 0, frame * entry.h)
end
function M.header(man, key, scroll, zoomed)
  local entry = assert(man.leftHeaders[key], "native PokeNav header")
  if key == "hoenn_map" then
    M.draw(entry, 120, 33 - scroll, 64, 32, 0, 0)
    M.draw(entry, 184, 33 - scroll, 64, 32, 0, zoomed and 64 or 32)
  else
    M.draw(entry, 0, 33 - scroll, 64, 32, 0, 0)
    M.draw(entry, 80, 33 - scroll, 32, 32, 0, 32)
  end
end
function M.shell(shell, frame, scroll, help)
  M.draw(shell.layers.header, 0, -scroll)
  if help ~= nil and scroll ~= 0 then M.draw(shell.help[help], 0, 176 - scroll) end
  if scroll < 32 then
    local s = shell.sprites.spin
    M.frame(s, math.floor(frame / 12) % s.frames, 218 - s.w / 2, 14 - scroll - s.h / 2)
  end
end
return M
