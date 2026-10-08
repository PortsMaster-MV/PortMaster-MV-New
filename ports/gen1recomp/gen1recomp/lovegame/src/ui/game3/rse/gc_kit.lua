local bit = require("bit")
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift

local Machine = require("src.ui.game3.rse.gba_machine")
local Sprites = require("src.core.game3.gba_sprites")
local TileLayer = require("src.ui.game3.rse.tile_layer")

local Kit = {}

Kit.A = Machine.A_BUTTON
Kit.B = Machine.B_BUTTON
Kit.SELECT = Machine.SELECT_BUTTON
Kit.START = Machine.START_BUTTON
Kit.RIGHT = Machine.DPAD_RIGHT
Kit.LEFT = Machine.DPAD_LEFT
Kit.UP = Machine.DPAD_UP
Kit.DOWN = Machine.DPAD_DOWN
Kit.R = Machine.R_BUTTON
Kit.L = Machine.L_BUTTON

local KEY_BITS = {
  a = Machine.A_BUTTON, b = Machine.B_BUTTON, select = Machine.SELECT_BUTTON, start = Machine.START_BUTTON,
  right = Machine.DPAD_RIGHT, left = Machine.DPAD_LEFT, up = Machine.DPAD_UP, down = Machine.DPAD_DOWN,
  r = Machine.R_BUTTON, l = Machine.L_BUTTON,
}

function Kit.s16(v)
  v = band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

function Kit.u8(v) return band(v, 0xFF) end
function Kit.u16(v) return band(v, 0xFFFF) end

function Kit.cdiv(a, b)
  local q = a / b
  if q >= 0 then return math.floor(q) end
  return math.ceil(q)
end

function Kit.cmod(a, b) return math.fmod(a, b) end

function Kit.headless()
  return not (love and love.graphics and love.image)
end

function Kit.newMachine()
  local m = Machine.new()
  m.coordOffsetX, m.coordOffsetY = 0, 0
  return m
end

-- pokeemerald/src/main.c:250
function Kit.readKeys(m, inp)
  local held, new = 0, 0
  inp = inp or {}
  for k, b in pairs(KEY_BITS) do
    if inp.held and inp.held[k] then held = bor(held, b) end
    if inp.new and inp.new[k] then new = bor(new, b) end
  end
  m.heldKeys = bor(held, new)
  m.newKeys = new
end

function Kit.joyNew(m, mask) return band(m.newKeys or 0, mask) ~= 0 end
function Kit.joyHeld(m, mask) return band(m.heldKeys or 0, mask) ~= 0 end

local sheetCache = {}

function Kit.sheet(entry)
  if not entry or not entry.png or Kit.headless() then return nil end
  local hit = sheetCache[entry.png]
  if hit then return hit end
  hit = Machine.sheet({ png = entry.png, w = entry.w, h = entry.h })
  sheetCache[entry.png] = hit
  return hit
end

function Kit.resetCaches()
  sheetCache = {}
end

local function frameSheet(base, frame)
  if not base then return nil end
  base.frameSheets = base.frameSheets or {}
  local fs = base.frameSheets[frame]
  if not fs then
    fs = { image = base.image, w = base.w, h = base.h, frameW = base.frameW, frameH = base.frameH,
      rects = { { x = 0, y = frame * base.frameH } } }
    base.frameSheets[frame] = fs
  end
  return fs
end
Kit.frameSheet = frameSheet

-- pokeemerald/src/sprite.c:502
function Kit.createSprite(m, def, x, y, subpriority)
  local sp = m.ppu.sprites
  local entry = def.entry
  local comp = entry and entry.tables
  local w, h = def.w or (entry and (entry.w0 or entry.w)) or 8, def.h or (entry and (entry.h0 or entry.h)) or 8
  if comp then w, h = def.w or entry.w0 or 8, def.h or entry.h0 or 8 end
  local ok = pcall(Sprites.shapeOf, w, h)
  if not ok then w, h = 8, 8 end
  local template = {
    w = w, h = h, bpp = 4,
    anims = def.anims or (entry and entry.anims) or { { { op = "frame", frame = 0, duration = 1 }, { op = "end" } } },
    affineAnims = def.affineAnims or (entry and entry.affineAnims),
    priority = def.priority or 0, affineMode = def.affineMode or 0, objMode = def.objMode or 0,
    paletteTag = def.paletteTag, callback = def.callback,
  }
  if entry and not comp then template.sheet = Kit.sheet(entry) end
  local id = sp:create(template, x, y, subpriority)
  if id >= Sprites.MAX then return id, nil end
  local s = sp.sprites[id]
  s.comp = comp
  s.subTable = 0
  s.coordOffsetEnabled = def.coordOffset and true or false
  if comp then
    s.compSheets = {}
    for i, t in ipairs(comp) do s.compSheets[i] = Kit.sheet(t) end
  end
  return id, s
end

function Kit.setFrameOverride(s, sheetEntry, frame)
  s.frameEntry = sheetEntry
  s.frameOverride = frame
end

local function sortY(s)
  local y = s.oam.y
  if y >= 160 then y = y - 256 end
  if s.oam.affineMode == 3 and s.oam.size == 3 and (s.oam.shape == 0 or s.oam.shape == 2) then
    if y > 128 then y = y - 256 end
  end
  return y
end

-- pokeemerald/src/sprite.c:325
function Kit.buildOam(m)
  local spr = m.ppu.sprites
  local cx, cy = m.coordOffsetX or 0, m.coordOffsetY or 0
  local pri = {}
  local sp = spr.sprites
  for i = 0, Sprites.MAX - 1 do
    local s = sp[i]
    if s.inUse and not s.invisible then
      local x, y = s.x + s.x2 + s.centerToCornerVecX, s.y + s.y2 + s.centerToCornerVecY
      if s.coordOffsetEnabled then x, y = x + cx, y + cy end
      s.oam.x = band(x, 0x1FF)
      s.oam.y = band(y, 0xFF)
      s._ox, s._oy = x, y
    end
    pri[i] = bor(band(s.subpriority, 0xFF), lshift(s.oam.priority, 8))
  end
  local order = spr.order
  for i = 1, Sprites.MAX - 1 do
    local j = i
    while j > 0 do
      local a, b = order[j - 1], order[j]
      local pa, pb = pri[a], pri[b]
      if pa > pb or (pa == pb and sortY(sp[a]) < sortY(sp[b])) then
        order[j], order[j - 1] = a, b
        j = j - 1
      else
        break
      end
    end
  end
  local out = {}
  for i = 0, Sprites.MAX - 1 do
    local s = sp[order[i]]
    if s.inUse and not s.invisible then
      if #out >= spr.oamLimit then break end
      local mtx = spr.matrices[s.oam.matrixNum % Sprites.MATRIX_COUNT]
      if s.comp then
        local t = s.comp[s.subTable + 1]
        local sheet = s.compSheets[s.subTable + 1]
        local hf, vf = s.oam.hFlip, s.oam.vFlip
        local bx, by = s._ox - s.centerToCornerVecX, s._oy - s.centerToCornerVecY
        local x = hf and (bx - t.ox - t.w) or (bx + t.ox)
        local y = vf and (by - t.oy - t.h) or (by + t.oy)
        out[#out + 1] = {
          sheet = sheet, frame = s.frameOverride or s.frame, w = t.w, h = t.h,
          x = band(x, 0x1FF), y = band(y, 0xFF), affineMode = 0, objMode = s.oam.objMode,
          priority = t.priority or s.oam.priority, paletteNum = s.oam.paletteNum, bpp = 4,
          hFlip = hf, vFlip = vf, matrixNum = 0, a = 256, b = 0, c = 0, d = 256, sprite = s,
        }
      else
        local w, h = Sprites.dims(s.oam.shape, s.oam.size)
        local sheet, frame = s.sheet, s.frame
        if s.frameOverride then
          sheet = frameSheet(Kit.sheet(s.frameEntry), s.frameOverride)
          frame = 0
        end
        out[#out + 1] = {
          sheet = sheet, frame = frame, w = w, h = h,
          x = s.oam.x, y = s.oam.y,
          affineMode = s.oam.affineMode, objMode = s.oam.objMode,
          priority = s.oam.priority, paletteNum = s.oam.paletteNum, bpp = s.oam.bpp,
          hFlip = s.oam.hFlip, vFlip = s.oam.vFlip, matrixNum = s.oam.matrixNum,
          a = mtx.a, b = mtx.b, c = mtx.c, d = mtx.d, sprite = s,
        }
      end
    end
  end
  spr.oamBuffer = out
end

-- pokeemerald/src/sprite.c:618
function Kit.destroySprite(m, s)
  if not s or not s.inUse then return end
  if band(s.oam.affineMode, 1) ~= 0 then
    m.ppu.sprites.matrixBitmap = band(m.ppu.sprites.matrixBitmap, bit.bnot(lshift(1, s.oam.matrixNum)))
  end
  s.comp, s.compSheets, s.frameOverride, s.frameEntry, s.coordOffsetEnabled = nil, nil, nil, nil, nil
  m.ppu.sprites:destroy(s)
end

-- pokeemerald/src/field_effect.c:968
function Kit.multiplyPalette(pal, i, r, g, b)
  local c = pal.unfaded[i]
  local cr, cg, cb = band(c, 31), band(rshift(c, 5), 31), band(rshift(c, 10), 31)
  cr = cr - rshift(cr * r, 4)
  cg = cg - rshift(cg * g, 4)
  cb = cb - rshift(cb * b, 4)
  pal.faded[i] = band(bor(cr, lshift(cg, 5), lshift(cb, 10)), 0xFFFF)
end

-- pokeemerald/src/field_effect.c:947
function Kit.multiplyInvertedPalette(pal, i, r, g, b)
  local c = pal.unfaded[i]
  local cr, cg, cb = band(c, 31), band(rshift(c, 5), 31), band(rshift(c, 10), 31)
  cr = cr + rshift((31 - cr) * r, 4)
  cg = cg + rshift((31 - cg) * g, 4)
  cb = cb + rshift((31 - cb) * b, 4)
  pal.faded[i] = band(bor(cr, lshift(cg, 5), lshift(cb, 10)), 0xFFFF)
end

function Kit.sin(T, index, amp)
  return Kit.s16(math.floor(amp * T.sine[index] / 256))
end

function Kit.cos(T, index, amp)
  return Kit.s16(math.floor(amp * T.sine[index + 64] / 256))
end

-- pokeemerald/src/trig.c:527
function Kit.sin2(T, angle)
  angle = band(angle, 0xFFFF)
  local v = T.sineDeg[angle % 180]
  if math.floor(angle / 180) % 2 == 1 then return -v end
  return v
end

-- pokeemerald/src/trig.c:540
function Kit.cos2(T, angle)
  return Kit.sin2(T, angle + 90)
end

local Layer = {}
Layer.__index = Layer

function Kit.layer(tileBytes, wTiles, hTiles, opts)
  opts = opts or {}
  local self = setmetatable({}, Layer)
  self.tiles = TileLayer.decodeTiles(tileBytes or "")
  self.wt, self.ht = wTiles or 32, hTiles or 32
  self.map = {}
  for i = 0, self.wt * self.ht - 1 do self.map[i] = 0 end
  self.headless = opts.headless or Kit.headless()
  if not self.headless then
    self.data = love.image.newImageData(self.wt * 8, self.ht * 8)
    for i = 0, self.wt * self.ht - 1 do self:_paint(i) end
    self.image = love.graphics.newImage(self.data)
    self.image:setFilter("nearest", "nearest")
    self.layer = { image = self.image, w = self.wt * 8, h = self.ht * 8, bpp = 4 }
  end
  return self
end

function Layer:_paint(cell)
  if self.headless then return end
  local e = self.map[cell]
  local tile = e % 1024
  local hf = math.floor(e / 1024) % 2 == 1
  local vf = math.floor(e / 2048) % 2 == 1
  local bank = math.floor(e / 4096) % 16
  local px = self.tiles[tile]
  local x0, y0 = (cell % self.wt) * 8, math.floor(cell / self.wt) * 8
  local d = self.data
  for y = 0, 7 do
    local sy = vf and (7 - y) or y
    for x = 0, 7 do
      local sx = hf and (7 - x) or x
      local v = px and px[sy * 8 + sx] or 0
      d:setPixel(x0 + x, y0 + y, ((v == 0) and 0 or (bank * 16 + v)) / 255, 0, 0, 1)
    end
  end
  self.dirty = true
end

-- pokeemerald/src/bg.c:1145
function Layer:cellOf(x, y)
  return (y % self.ht) * self.wt + (x % self.wt)
end

function Layer:put(x, y, entry)
  local cell = self:cellOf(x, y)
  entry = band(tonumber(entry) or 0, 0xFFFF)
  if self.map[cell] == entry then return end
  self.map[cell] = entry
  self:_paint(cell)
end

function Layer:get(x, y)
  return self.map[self:cellOf(x, y)]
end

-- pokeemerald/include/gba/io_reg.h:540
function Layer:putIndex(i, entry)
  local sb = math.floor(i / 1024)
  local rem = i % 1024
  self:put(sb * 32 + rem % 32, math.floor(rem / 32), entry)
end

function Layer:flush()
  if self.dirty and self.image then self.image:replacePixels(self.data) end
  self.dirty = false
end

-- pokeemerald/src/sound.c:239
function Kit.fanfareTask(m, frames)
  local tasks = m.tasks
  if m.fanfareTaskId and tasks:get(m.fanfareTaskId).isActive and tasks:get(m.fanfareTaskId).func == m._fanfareFn then
    tasks:get(m.fanfareTaskId).data[0] = frames
    return
  end
  m._fanfareFn = m._fanfareFn or function(id, data)
    if data[0] ~= 0 then
      data[0] = data[0] - 1
    else
      tasks:destroy(id)
    end
  end
  m.fanfareTaskId = tasks:create(m._fanfareFn, 80)
  tasks:get(m.fanfareTaskId).data[0] = frames
end

function Kit.fanfareInactive(m)
  local id = m.fanfareTaskId
  if not id then return true end
  local t = m.tasks:get(id)
  return not (t.isActive and t.func == m._fanfareFn)
end

local Sound = {}
Sound.__index = Sound

function Kit.sound(opts)
  opts = opts or {}
  return setmetatable({ muted = opts.muted, log = {}, version = opts.version }, Sound)
end

local function constants(self)
  local GameVersion = require("src.core.GameVersion")
  return require("src.core.game3.constants").of(self.version or GameVersion.get())
end

function Sound:id(name)
  return constants(self):require("songs", name)
end

function Sound:_audio()
  if self.muted then return nil end
  local ok, Audio = pcall(require, "src.core.game3.audio")
  return ok and Audio or nil
end

function Sound:se(name)
  self.log[#self.log + 1] = name
  local A = self:_audio()
  if A then pcall(A.playSe, self:id(name)) end
end

function Sound:stopSe(name)
  local A = self:_audio()
  if A then pcall(A.stopSe, self:id(name)) end
end

function Sound:sePlaying()
  local A = self:_audio()
  if not A then return false end
  local ok, r = pcall(A.isSePlaying)
  return ok and r == true
end

function Sound:fanfare(name)
  self.log[#self.log + 1] = name
  local A = self:_audio()
  if A then pcall(A.playFanfare, self:id(name)) end
end

function Sound:mapMusic()
  local A = self:_audio()
  if not A then return 0 end
  local ok, r = pcall(A.currentMapMusic)
  return ok and tonumber(r) or 0
end

function Sound:stopMapMusic()
  local A = self:_audio()
  if A then pcall(A.playSong, 0) end
end

function Sound:playMapMusic(nameOrId)
  self.log[#self.log + 1] = tostring(nameOrId)
  local A = self:_audio()
  if not A then return end
  local id = type(nameOrId) == "string" and self:id(nameOrId) or nameOrId
  pcall(A.playSong, id)
end

function Sound:cry(species, pan)
  local A = self:_audio()
  if A then pcall(A.playCry, species, 0, pan) end
end

function Sound:setSePan(pan)
  local A = self:_audio()
  if A and A.setSePan then pcall(A.setSePan, pan) end
end

function Kit.text(key, vars)
  local ok, RomText = pcall(require, "src.core.game3.rom_text")
  if not ok then return key end
  local okP, s = pcall(RomText.plain, key, vars and { stringVars = vars } or nil)
  if okP and type(s) == "string" then return s end
  return key
end

function Kit.drawText(text, x, y, colors, fade)
  local FrlgFont = require("src.ui.game3.frlg_font")
  local c = colors
  if fade and fade > 0 then
    local k = (16 - fade) / 16
    local function sc(t) return t and { (t[1] or 0) * k, (t[2] or 0) * k, (t[3] or 0) * k, t[4] or 1 } or nil end
    c = { fg = sc(colors.fg), bg = sc(colors.bg), shadow = sc(colors.shadow) }
  end
  FrlgFont.draw(text, x, y, { colors = c, maxWidth = 240 })
end

function Kit.measure(text)
  local FrlgFont = require("src.ui.game3.frlg_font")
  return FrlgFont.measure(text) or 0
end

function Kit.linePitch()
  return require("src.ui.game3.rse.scene_kit").linePitch()
end

function Kit.color555(c)
  return { band(c, 31) / 31, band(rshift(c, 5), 31) / 31, band(rshift(c, 10), 31) / 31, 1 }
end

return Kit
