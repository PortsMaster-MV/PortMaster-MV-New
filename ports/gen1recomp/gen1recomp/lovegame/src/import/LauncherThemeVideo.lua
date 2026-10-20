-- Quiet, black-keyed video layer behind the launcher UI.
local LauncherThemeVideo = {}
LauncherThemeVideo.__index = LauncherThemeVideo

local VIDEO_PATH = "assets/launcher/current_theme_vid.ogv"

function LauncherThemeVideo.new()
  local self = setmetatable({}, LauncherThemeVideo)
  local ok, err = pcall(function()
    self.video = love.graphics.newVideo(VIDEO_PATH, { audio = false })
    self.video:setFilter("linear", "linear")
    local width, height = self.video:getDimensions()
    self.canvas = love.graphics.newCanvas(width, height)
    self.canvas:setFilter("linear", "linear")
    self.shader = love.graphics.newShader([[
      vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
        vec4 pixel = Texel(texture, uv);
        float brightness = max(pixel.r, max(pixel.g, pixel.b));
        float coverage = smoothstep(0.012, 0.10, brightness);
        float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
        vec3 muted = mix(vec3(gray), pixel.rgb, 0.12);
        return vec4(muted, pixel.a * coverage * 0.12) * color;
      }
    ]])
    self.video:play()
  end)
  if not ok then
    self:release()
    print("[launcher theme video] unavailable: " .. tostring(err))
    return nil
  end
  return self
end

function LauncherThemeVideo:update()
  -- LÖVE's Theora stream does not expose a reliable loop flag on every target.
  -- Rewind after each pass so this stays portable across desktop and mobile.
  if self.video and not self.video:isPlaying() then
    self.video:rewind()
    self.video:play()
  end
end

function LauncherThemeVideo:draw()
  local g = love.graphics
  local width, height = g.getDimensions()
  local vw, vh = self.video:getDimensions()

  g.push("all")
  g.origin()
  g.setScissor()
  g.setShader()
  g.setBlendMode("alpha", "alphamultiply")

  -- LÖVE Video exposes YUV planes; convert through RGB before black-keying.
  local target = g.getCanvas()
  g.setCanvas(self.canvas)
  g.clear(0, 0, 0, 0)
  g.setColor(1, 1, 1, 1)
  g.draw(self.video, 0, 0)
  g.setCanvas(target)

  local scale = math.max(width / vw, height / vh)
  g.setShader(self.shader)
  g.draw(self.canvas, (width - vw * scale) / 2,
    (height - vh * scale) / 2, 0, scale, scale)
  g.pop()
end

function LauncherThemeVideo:release()
  if self.video then self.video:pause() end
  for _, key in ipairs({ "video", "canvas", "shader" }) do
    local resource = self[key]
    if resource then resource:release(); self[key] = nil end
  end
end

return LauncherThemeVideo
