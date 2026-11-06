local Audio = require("src.core.game3.audio")
local SE = require("src.core.game3.se_ids")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Pal = require("src.core.game3.pal_fade")
local CacheBlob = require("src.import.CacheBlob")

local Kit = {}

Kit.GBA_HZ = 16777216 / 280896
Kit.KEYS = { "a", "b", "start", "select", "up", "down", "left", "right", "l", "r" }

local images = {}
local manifests = {}

function Kit.image(path)
  if not path then return nil end
  local hit = images[path]
  if hit ~= nil then return hit or nil end
  local img = false
  if love and love.filesystem and love.graphics and love.filesystem.getInfo(path) then
    local ok, loaded = pcall(love.graphics.newImage, path)
    if ok and loaded then
      loaded:setFilter("nearest", "nearest")
      img = loaded
    end
  end
  images[path] = img
  return img or nil
end

function Kit.maskedLayer(path, idxPath)
  local key = path .. "#mask0"
  local hit = images[key]
  if hit ~= nil then return hit or nil end
  local img = false
  if love and love.image and love.filesystem and love.filesystem.getInfo(path) and love.filesystem.getInfo(idxPath) then
    local okA, data = pcall(love.image.newImageData, path)
    local okB, idx = pcall(love.image.newImageData, idxPath)
    if okA and okB and data:getWidth() == idx:getWidth() and data:getHeight() == idx:getHeight() then
      data:mapPixel(function(x, y, r, g, b, a)
        local v = idx:getPixel(x, y)
        if v == 0 then return r, g, b, 0 end
        return r, g, b, a
      end)
      img = love.graphics.newImage(data)
      img:setFilter("nearest", "nearest")
    end
  end
  images[key] = img
  return img or nil
end

function Kit.rgbaImage(path, w, h)
  local key = path .. "#rgba"
  local hit = images[key]
  if hit ~= nil then return hit or nil end
  local img = false
  local data
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  if okC and CacheFs and CacheFs.read then data = CacheFs.read(path) end
  if (not data) and love and love.filesystem and love.filesystem.getInfo(path) then
    data = CacheBlob.readFs(path)
  end
  if type(data) == "string" and #data == w * h * 4 and love and love.image then
    local ok, id = pcall(love.image.newImageData, w, h, "rgba8", data)
    if ok and id then
      img = love.graphics.newImage(id)
      img:setFilter("nearest", "nearest")
    end
  end
  images[key] = img
  return img or nil
end

function Kit.loadLua(path)
  local hit = manifests[path]
  if hit ~= nil then return hit or nil end
  local t = false
  if love and love.filesystem and love.filesystem.getInfo(path) then
    local ok, chunk = pcall(love.filesystem.load, path)
    if ok and type(chunk) == "function" then
      local ok2, v = pcall(chunk)
      if ok2 and type(v) == "table" then t = v end
    end
  end
  manifests[path] = t
  return t or nil
end

function Kit.manifest(sub)
  return Kit.loadLua("data/generated/gba/" .. sub .. "/manifest.lua")
end

function Kit.resetCaches()
  images, manifests = {}, {}
end

function Kit.rgb555(c)
  c = tonumber(c) or 0
  local r = c % 32
  local g = math.floor(c / 32) % 32
  local b = math.floor(c / 1024) % 32
  return r / 31, g / 31, b / 31
end

function Kit.color555(c, a)
  local r, g, b = Kit.rgb555(c)
  return { r, g, b, a or 1 }
end

function Kit.color8(t, a)
  if type(t) ~= "table" then return { 0, 0, 0, a or 1 } end
  return { (t[1] or 0) / 255, (t[2] or 0) / 255, (t[3] or 0) / 255, a or 1 }
end

function Kit.chromePalettes()
  return Kit.loadLua("data/generated/gba/chrome/palettes.lua")
end

function Kit.fontMetrics(id)
  local m = Kit.loadLua("data/generated/gba/chrome/fonts/metrics.lua")
  return m and m[id or 1] or nil
end

function Kit.linePitch()
  local m = Kit.fontMetrics(1)
  if m then return (m.maxLetterHeight or 16) + (m.lineSpacing or 0) end
  return FrlgFont.LINE_PITCH
end

-- pokeemerald/src/menu.c:77
local TEXT_SPEED_DELAYS = { [0] = 8, 4, 1 }
-- pokeemerald/src/text.c:76
local SCROLL_SPEEDS = { [0] = 1, 2, 4 }

function Kit.textSpeedDelay(option)
  return TEXT_SPEED_DELAYS[tonumber(option) or 1] or 4
end

function Kit.scrollSpeed(option)
  return SCROLL_SPEEDS[tonumber(option) or 1] or 2
end

function Kit.messageColors(palName, fg, bg, shadow)
  local pals = Kit.chromePalettes()
  local pal = pals and pals[palName or "message_box"]
  if not pal then return FrlgFont.COLOR.NORMAL end
  return {
    fg = Kit.color8(pal[fg or 2]),
    bg = Kit.color8(pal[bg or 1]),
    shadow = Kit.color8(pal[shadow or 3]),
  }
end

function Kit.isBootState(v)
  return type(v) == "table" and v.phase ~= nil and type(v.custom) == "table"
end

function Kit.loadRawSave()
  local ok, SaveData = pcall(require, "src.core.SaveData")
  if not (ok and SaveData and SaveData.load) then return nil end
  local okL, raw = pcall(SaveData.load)
  if okL and type(raw) == "table" and raw.engine == "game3" then return raw end
  return nil
end

local arrowArt

-- pokeemerald/src/list_menu.c:1052
function Kit.scrollArrow(dir, cx, cy, t)
  local RseBag = require("src.ui.game3.rse.bag_chrome")
  if RseBag.ARROWS[dir] and RseBag.ready() then return RseBag.drawArrow(dir, cx, cy, t) end
  return Kit.glyphArrow(dir, cx, cy, t)
end

function Kit.glyphArrow(dir, cx, cy, t)
  if arrowArt == nil then
    local ok = pcall(function() require("src.ui.game3.list_menu").loadArrows() end)
    arrowArt = ok
  end
  if arrowArt then
    require("src.ui.game3.list_menu").drawArrow(dir, cx, cy, t)
    return
  end
  local glyph = dir == "up" and FrlgFont.CHAR_UP_ARROW or dir == "down" and FrlgFont.CHAR_DOWN_ARROW
    or FrlgFont.CHAR_RIGHT_ARROW
  local bob = math.floor((t or 0) / 8) % 2
  local dy = dir == "up" and -bob or dir == "down" and bob or 0
  local dx = dir == "right" and bob or 0
  FrlgFont.drawGlyph(glyph, cx - 4 + dx, cy - 8 + dy, { colors = FrlgFont.COLOR.RED })
end

function Kit.song(name)
  local id = require("src.core.game3.song_ids")[name]
  if id == nil then error("scene_kit: unknown song " .. tostring(name), 2) end
  return id
end

function Kit.playSe(name)
  local id = SE[name]
  if id == nil then error("scene_kit: unknown SE " .. tostring(name), 2) end
  Audio.playSe(id)
end


local Stepper = {}
Stepper.__index = Stepper

function Kit.stepper(hz)
  return setmetatable({ accum = 0, pending = {}, hz = hz or Kit.GBA_HZ, frames = 0 }, Stepper)
end

function Stepper:collect(input)
  if input and input.wasPressed then
    for _, k in ipairs(Kit.KEYS) do
      if input:wasPressed(k) then self.pending[k] = true end
    end
  end
  local held = {}
  if input and input.isDown then
    for _, k in ipairs(Kit.KEYS) do
      if input:isDown(k) then held[k] = true end
    end
  end
  self.held = held
end

-- pokeemerald/src/main.c:250
function Stepper:_repeat(pressed)
  local held = self.held or {}
  local sig = {}
  for _, k in ipairs(Kit.KEYS) do if held[k] then sig[#sig + 1] = k end end
  sig = table.concat(sig, ",")
  local rep = {}
  for k in pairs(pressed) do rep[k] = true end
  if sig ~= "" and sig == self.heldSig then
    self.repeatCounter = (self.repeatCounter or 40) - 1
    if self.repeatCounter == 0 then
      for k in pairs(held) do rep[k] = true end
      self.repeatCounter = 5
    end
  else
    self.repeatCounter = 40
  end
  self.heldSig = sig
  return rep
end

function Stepper:run(dt, fn)
  self.accum = self.accum + (dt or 1 / 60)
  local step = 1 / self.hz
  local out
  while self.accum >= step do
    self.accum = self.accum - step
    local pressed = self.pending
    self.pending = {}
    self.frames = self.frames + 1
    out = fn({ new = pressed, held = self.held or {}, rep = self:_repeat(pressed) })
    if out ~= nil then
      self.accum = 0
      return out
    end
  end
  return nil
end

-- pokeemerald/src/text.c:16

local Printer = {}
Printer.__index = Printer

local function utf8Chars(s, out)
  for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    out[#out + 1] = { t = "c", s = ch }
  end
end

local EXT_PAUSE = 0x08
local EXT_PAUSE_UNTIL_PRESS = 0x09

local function tokenize(ir, ctx)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local toks = {}
  for _, seg in ipairs(ir or {}) do
    local t = seg.t
    if t == "eos" then break
    elseif t == "nl" then toks[#toks + 1] = { t = "nl" }
    elseif t == "para" then toks[#toks + 1] = { t = "para" }
    elseif t == "scroll" then toks[#toks + 1] = { t = "scroll" }
    elseif t == "ext" then
      if seg.cmd == EXT_PAUSE then
        toks[#toks + 1] = { t = "pause", n = seg.args and seg.args[1] or 0 }
      elseif seg.cmd == EXT_PAUSE_UNTIL_PRESS then
        toks[#toks + 1] = { t = "wait" }
      end
    else
      local s = TextIR.expandSeg(seg, ctx)
      if s and s ~= "" then
        if s:sub(1, 1) == "{" and s:sub(-1) == "}" then
          toks[#toks + 1] = { t = "c", s = s }
        else
          utf8Chars(s, toks)
        end
      end
    end
  end
  return toks
end

Kit.tokenize = tokenize

function Kit.printer(source, opts)
  opts = opts or {}
  local ir = source
  if type(source) == "string" then
    ir = RomText.translate(RomText.ir(source), opts.ctx or {}, source)
  end
  local p = setmetatable({
    toks = tokenize(ir, opts.ctx or {}),
    pos = 1,
    lines = { "" },
    active = true,
    state = "char",
    delay = 0,
    spedUp = false,
    canSpeedUp = opts.canSpeedUp ~= false,
    speed = 0,
    onPause = opts.onPause,
    scrollOption = opts.textSpeedOption or 1,
    scrollY = 0,
    arrowIdx = 0,
    arrowDelay = 0,
    pitch = opts.linePitch or Kit.linePitch(),
    paused = 0,
    lastCmd = nil,
  }, Printer)
  local speed = tonumber(opts.speed) or 4
  if speed == 0 then
    p.speed = 0
    for _ = 1, 4096 do
      if not p.active then break end
      p:render({ new = {}, held = {} })
    end
  else
    p.speed = speed - 1
  end
  return p
end

function Printer:_char(tok)
  local l = self.lines
  l[#l] = l[#l] .. tok.s
end

function Printer:render(inp)
  local st = self.state
  if st == "char" then
    local held = inp.held and (inp.held.a or inp.held.b)
    if held and self.spedUp then self.delay = 0 end
    if self.delay > 0 and self.speed > 0 then
      self.delay = self.delay - 1
      if self.canSpeedUp and inp.new and (inp.new.a or inp.new.b) then
        self.spedUp = true
        self.delay = 0
      end
      return "update"
    end
    self.delay = self.speed
    local tok = self.toks[self.pos]
    self.pos = self.pos + 1
    if tok == nil then
      self.active = false
      return "finish"
    end
    self.lastCmd = tok.t
    if tok.t == "nl" then
      self.lines[#self.lines + 1] = ""
      return "repeat"
    elseif tok.t == "pause" then
      self.paused = tok.n
      self.state = "pause"
      return "repeat"
    elseif tok.t == "wait" then
      self.state = "wait"
      return "update"
    elseif tok.t == "para" then
      self.state = "clear"
      self.arrowIdx, self.arrowDelay = 0, 0
      return "update"
    elseif tok.t == "scroll" then
      self.state = "scroll_start"
      self.arrowIdx, self.arrowDelay = 0, 0
      return "update"
    end
    self:_char(tok)
    return "print"
  elseif st == "pause" then
    if self.onPause then self.onPause(self) end
    if self.paused ~= 0 then
      self.paused = self.paused - 1
    else
      self.state = "char"
    end
    return "update"
  elseif st == "wait" then
    if inp.new and (inp.new.a or inp.new.b) then
      Kit.playSe("SE_SELECT")
      self.state = "char"
    end
    return "update"
  elseif st == "clear" or st == "scroll_start" then
    if self.arrowDelay ~= 0 then
      self.arrowDelay = self.arrowDelay - 1
    else
      self.arrowFrame = self.arrowIdx % 4
      self.arrowDelay = 8
      self.arrowIdx = self.arrowIdx + 1
    end
    if inp.new and (inp.new.a or inp.new.b) then
      Kit.playSe("SE_SELECT")
      self.arrowFrame = nil
      if st == "clear" then
        self.lines = { "" }
        self.state = "char"
      else
        self.scrollLeft = self.pitch
        self.state = "scroll"
      end
    end
    return "update"
  elseif st == "scroll" then
    if self.scrollLeft > 0 then
      local sp = Kit.scrollSpeed(self.scrollOption)
      if self.scrollLeft < sp then sp = self.scrollLeft end
      self.scrollLeft = self.scrollLeft - sp
      self.scrollY = self.scrollY + sp
      if self.scrollY >= self.pitch then
        self.scrollY = 0
        table.remove(self.lines, 1)
        self.lines[#self.lines + 1] = ""
      end
    else
      self.state = "char"
      if #self.lines > 0 and self.lines[#self.lines] ~= "" then self.lines[#self.lines + 1] = "" end
    end
    return "update"
  end
  return "finish"
end

function Printer:run(inp)
  if not self.active then return end
  for _ = 1, 256 do
    local r = self:render(inp)
    if r ~= "repeat" then return r end
  end
end

function Printer:isActive()
  return self.active
end

local arrowQuads = {}

function Printer:draw(x, y, opts)
  opts = opts or {}
  local colors = opts.colors or Kit.messageColors()
  local cx, cy = x, y
  local clip = opts.clip
  local sx, sy, sw, sh
  if clip then
    sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.intersectScissor(clip[1], clip[2], clip[3], clip[4])
  end
  for i, line in ipairs(self.lines) do
    local ly = y + (i - 1) * self.pitch - self.scrollY
    if line ~= "" then
      local _, endX = FrlgFont.draw(line, x, ly, { colors = colors, maxWidth = opts.maxWidth or 240, linePitch = self.pitch })
      cx = endX or (x + FrlgFont.measure(line))
    else
      cx = x
    end
    cy = ly
  end
  if clip then
    if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
  end
  if self.arrowFrame then
    local img = Kit.rgbaImage("data/generated/gba/chrome/fonts/down_arrow.rgba", 8, 48)
    if img then
      -- pokeemerald/src/text.c:75
      local off = ({ [0] = 0, 1, 2, 1 })[self.arrowFrame] or 0
      local q = arrowQuads[off]
      if not q then
        q = love.graphics.newQuad(0, off, 8, 16, img:getDimensions())
        arrowQuads[off] = q
      end
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, q, cx, cy)
    else
      Chrome.promptArrow(cx, cy, self.arrowFrame)
    end
  end
end


local msgQuads

local function messageBoxAtlas()
  local img = Kit.rgbaImage("data/generated/gba/chrome/message_box.rgba", 56, 16)
  if img and not msgQuads then
    msgQuads = {}
    for i = 0, 13 do
      msgQuads[i] = love.graphics.newQuad((i % 7) * 8, math.floor(i / 7) * 8, 8, 8, 56, 16)
    end
  end
  return img
end

-- pokeemerald/src/main_menu.c:2275
function Kit.birchDialogueFrame(tx, ty, tw, th)
  local img = messageBoxAtlas()
  local colors = Kit.messageColors()
  love.graphics.setColor(colors.bg)
  love.graphics.rectangle("fill", (tx - 1) * 8, ty * 8, (tw + 1) * 8, th * 8)
  love.graphics.setColor(1, 1, 1, 1)
  if not img then return end
  local function tile(n, cx, cy, w, h, vflip)
    for yy = 0, h - 1 do
      for xx = 0, w - 1 do
        local px, py = (cx + xx) * 8, (cy + yy) * 8
        if vflip then
          love.graphics.draw(img, msgQuads[n], px, py + 8, 0, 1, -1)
        else
          love.graphics.draw(img, msgQuads[n], px, py)
        end
      end
    end
  end
  tile(1, tx - 2, ty - 1, 1, 1)
  tile(3, tx - 1, ty - 1, 1, 1)
  tile(4, tx, ty - 1, tw, 1)
  tile(5, tx + tw - 1, ty - 1, 1, 1)
  tile(6, tx + tw, ty - 1, 1, 1)
  tile(7, tx - 2, ty, 1, th)
  tile(9, tx - 1, ty, tw + 1, th)
  tile(10, tx + tw, ty, 1, th)
  tile(1, tx - 2, ty + th, 1, 1, true)
  tile(3, tx - 1, ty + th, 1, 1, true)
  tile(4, tx, ty + th, tw - 1, 1, true)
  tile(5, tx + tw - 1, ty + th, 1, 1, true)
  tile(6, tx + tw, ty + th, 1, 1, true)
end

function Kit.userFrame(tx, ty, tw, th, frameType, fill)
  Chrome.userFrame(frameType or 0, tx, ty, tw, th)
  if fill then
    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", tx * 8, ty * 8, tw * 8, th * 8)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

-- pokeemerald/src/menu.c:1623

local YesNo = {}
YesNo.__index = YesNo

function Kit.yesNo(tx, ty, opts)
  opts = opts or {}
  return setmetatable({
    tx = tx, ty = ty, cursor = opts.initial or 0,
    frameType = opts.frameType or 0,
  }, YesNo)
end

-- pokeemerald/src/menu.c:1211
function YesNo:input(inp)
  local n = inp.new or {}
  if n.a then return self.cursor end
  if n.b then return -1 end
  if n.up and self.cursor > 0 then
    Kit.playSe("SE_SELECT")
    self.cursor = self.cursor - 1
  elseif n.down and self.cursor < 1 then
    Kit.playSe("SE_SELECT")
    self.cursor = self.cursor + 1
  end
  return nil
end

function YesNo:draw()
  local colors = Kit.messageColors("std_menu")
  Kit.userFrame(self.tx, self.ty, 5, 4, self.frameType, colors.bg)
  local text = RomText.plain("gText_YesNo")
  local x, y = self.tx * 8 + 8, self.ty * 8 + 1
  local row = 0
  for line in (text .. "\n"):gmatch("(.-)\n") do
    FrlgFont.draw(line, x, y + row * 16, { colors = colors })
    row = row + 1
  end
  FrlgFont.draw(RomText.plain("gText_SelectorArrow3"), self.tx * 8, y + self.cursor * 16, { colors = colors })
end

-- pokeemerald/src/palette.c:156

function Kit.fade()
  return Pal.new()
end

function Kit.fadeY(pal, slot)
  local s = pal.slots[slot or 0]
  return s and s.y or 0, s and s.color or Pal.BLACK
end

function Kit.drawFade(pal, slot, w, h)
  local y, c = Kit.fadeY(pal, slot)
  if y <= 0 then return end
  love.graphics.setColor(c[1] / 31, c[2] / 31, c[3] / 31, y / 16)
  love.graphics.rectangle("fill", 0, 0, w or 240, h or 160)
  love.graphics.setColor(1, 1, 1, 1)
end

local tintShader

function Kit.tintShader()
  if tintShader == nil then
    tintShader = false
    if love and love.graphics and love.graphics.newShader then
      local ok, sh = pcall(love.graphics.newShader, [[
        extern vec3 target;
        extern number amount;
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
          vec4 p = Texel(tex, tc) * color;
          return vec4(mix(p.rgb, target, amount), p.a);
        }
      ]])
      if ok then tintShader = sh end
    end
  end
  return tintShader or nil
end

function Kit.drawTinted(img, quad, x, y, amount, target, alpha, sx, sy, ox, oy)
  local sh = amount and amount > 0 and Kit.tintShader() or nil
  if sh then
    sh:send("target", target or { 1, 1, 1 })
    sh:send("amount", amount)
    love.graphics.setShader(sh)
  end
  love.graphics.setColor(1, 1, 1, alpha or 1)
  if quad then
    love.graphics.draw(img, quad, x, y, 0, sx or 1, sy or 1, ox or 0, oy or 0)
  else
    love.graphics.draw(img, x, y, 0, sx or 1, sy or 1, ox or 0, oy or 0)
  end
  if sh then love.graphics.setShader() end
  love.graphics.setColor(1, 1, 1, 1)
end

return Kit
