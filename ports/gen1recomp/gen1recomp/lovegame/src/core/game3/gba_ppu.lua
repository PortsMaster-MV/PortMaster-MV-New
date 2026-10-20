local bit = require("bit")
local Palette = require("src.core.game3.gba_palette")
local Sprites = require("src.core.game3.gba_sprites")
local Scanline = require("src.core.game3.scanline_fx")
local IndexedPng = require("src.core.game3.indexed_png")

local band, rshift = bit.band, bit.rshift

local Ppu = {}
Ppu.__index = Ppu

Ppu.W, Ppu.H = 240, 160

Ppu.DISPCNT_MODE_0 = 0
Ppu.DISPCNT_MODE_1 = 1
Ppu.DISPCNT_MODE_2 = 2
Ppu.DISPCNT_HBLANK_FREE = 0x20
Ppu.DISPCNT_OBJ_1D_MAP = 0x40
Ppu.DISPCNT_FORCED_BLANK = 0x80
Ppu.DISPCNT_BG0_ON = 0x100
Ppu.DISPCNT_BG1_ON = 0x200
Ppu.DISPCNT_BG2_ON = 0x400
Ppu.DISPCNT_BG3_ON = 0x800
Ppu.DISPCNT_BG_ALL_ON = 0xF00
Ppu.DISPCNT_OBJ_ON = 0x1000
Ppu.DISPCNT_WIN0_ON = 0x2000
Ppu.DISPCNT_WIN1_ON = 0x4000
Ppu.DISPCNT_OBJWIN_ON = 0x8000

Ppu.BLDCNT_TGT1_BG0 = 0x1
Ppu.BLDCNT_TGT1_BG1 = 0x2
Ppu.BLDCNT_TGT1_BG2 = 0x4
Ppu.BLDCNT_TGT1_BG3 = 0x8
Ppu.BLDCNT_TGT1_OBJ = 0x10
Ppu.BLDCNT_TGT1_BD = 0x20
Ppu.BLDCNT_EFFECT_BLEND = 0x40
Ppu.BLDCNT_EFFECT_LIGHTEN = 0x80
Ppu.BLDCNT_EFFECT_DARKEN = 0xC0
Ppu.BLDCNT_TGT2_BG0 = 0x100
Ppu.BLDCNT_TGT2_BG1 = 0x200
Ppu.BLDCNT_TGT2_BG2 = 0x400
Ppu.BLDCNT_TGT2_BG3 = 0x800
Ppu.BLDCNT_TGT2_OBJ = 0x1000
Ppu.BLDCNT_TGT2_BD = 0x2000
Ppu.BLDCNT_TGT2_ALL = 0x3F00

Ppu.WININ_WIN0_BG_ALL = 0xF
Ppu.WININ_WIN0_OBJ = 0x10
Ppu.WININ_WIN0_CLR = 0x20
Ppu.WININ_WIN0_ALL = 0x3F
Ppu.WININ_WIN1_BG_ALL = 0xF00
Ppu.WININ_WIN1_OBJ = 0x1000
Ppu.WINOUT_WIN01_BG_ALL = 0xF
Ppu.WINOUT_WIN01_OBJ = 0x10
Ppu.WINOUT_WINOBJ_ALL = 0x3F00

function Ppu.blendAlpha(eva, evb)
  return eva + evb * 256
end

function Ppu.winRange(a, b)
  return a * 256 + b
end

local REG_DEFAULTS = {
  DISPCNT = 0, BLDCNT = 0, BLDALPHA = 0, BLDY = 0,
  BG0CNT = 0, BG1CNT = 0, BG2CNT = 0, BG3CNT = 0,
  WIN0H = 0, WIN0V = 0, WIN1H = 0, WIN1V = 0, WININ = 0, WINOUT = 0,
  BG0HOFS = 0, BG0VOFS = 0, BG1HOFS = 0, BG1VOFS = 0,
  BG2HOFS = 0, BG2VOFS = 0, BG3HOFS = 0, BG3VOFS = 0,
  BG2PA = 0x100, BG2PB = 0, BG2PC = 0, BG2PD = 0x100, BG2X = 0, BG2Y = 0,
  BG3PA = 0x100, BG3PB = 0, BG3PC = 0, BG3PD = 0x100, BG3X = 0, BG3Y = 0,
}

function Ppu.new()
  local self = setmetatable({}, Ppu)
  self.palette = Palette.new()
  self.sprites = Sprites.new(self.palette)
  self.scanline = Scanline.new()
  self.regs = {}
  self.bg = {}
  for i = 0, 3 do self.bg[i] = { priority = 0, layer = nil, wrap = false } end
  self:resetRegs()
  return self
end

function Ppu:resetRegs()
  for k, v in pairs(REG_DEFAULTS) do self.regs[k] = v end
end

function Ppu:set(name, value)
  assert(REG_DEFAULTS[name] ~= nil, "gba_ppu: unknown register " .. tostring(name))
  self.regs[name] = value
  local bg = name:match("^BG([0-3])CNT$")
  if bg then self.bg[tonumber(bg)].priority = band(value, 3) end
end

function Ppu:get(name)
  return self.regs[name]
end

function Ppu:setBg(i, priority, layer, wrap)
  local b = self.bg[i]
  b.priority = priority or 0
  b.layer = layer
  b.wrap = wrap and true or false
end

function Ppu:setAffine(i, reg)
  local p = "BG" .. i
  self.regs[p .. "PA"], self.regs[p .. "PB"] = reg.pa, reg.pb
  self.regs[p .. "PC"], self.regs[p .. "PD"] = reg.pc, reg.pd
  self.regs[p .. "X"], self.regs[p .. "Y"] = reg.dx, reg.dy
end

function Ppu:vblank()
  self.palette:transfer()
  self.sprites:loadOam()
  self.scanline:vblank(self.regs)
end

local cacheImages = {}

function Ppu.indexLayer(path, w, h, bpp)
  local key = "L:" .. path
  local hit = cacheImages[key]
  if not hit then
    local img = love.graphics.newImage(path)
    img:setFilter("nearest", "nearest")
    hit = { image = img, w = w or img:getWidth(), h = h or img:getHeight(), bpp = bpp or 4 }
    cacheImages[key] = hit
  end
  return hit
end

function Ppu.indexSheet(path, frameW, frameH, rects)
  local key = "S:" .. path
  local hit = cacheImages[key]
  if not hit then
    local img = IndexedPng.indexImage(path)
    hit = { image = img, w = img:getWidth(), h = img:getHeight(), frameW = frameW, frameH = frameH, rects = rects }
    cacheImages[key] = hit
  end
  return hit
end

function Ppu.clearCache()
  cacheImages = {}
end

local BG_SHADER = [[
extern Image idxTex;
extern vec2 texSize;
extern Image palTex;
extern Image lineTex;
extern float lineMode;
extern vec2 ofs;
extern float affine;
extern vec4 mat;
extern vec2 ref;
extern float wrap;
extern float bpp8;
vec4 effect(vec4 color, Image t, vec2 tc, vec2 sc) {
  float x = floor(sc.x);
  float y = floor(sc.y);
  vec2 p;
  if (affine > 0.5) {
    float tx = floor((ref.x + mat.x * x + mat.y * y) / 256.0);
    float ty = floor((ref.y + mat.z * x + mat.w * y) / 256.0);
    if (wrap > 0.5) {
      tx = mod(tx, texSize.x);
      ty = mod(ty, texSize.y);
    } else if (tx < 0.0 || ty < 0.0 || tx >= texSize.x || ty >= texSize.y) {
      return vec4(0.0);
    }
    p = vec2(tx, ty);
  } else {
    float h = ofs.x;
    float v = ofs.y;
    if (lineMode > 0.5) {
      vec4 lv = Texel(lineTex, vec2((y + 0.5) / 160.0, 0.5));
      float val = floor(lv.r * 255.0 + 0.5) + floor(lv.g * 255.0 + 0.5) * 256.0;
      if (lineMode < 1.5) h = val; else v = val;
    }
    p = vec2(mod(x + h, texSize.x), mod(y + v, texSize.y));
  }
  float idx = floor(Texel(idxTex, (p + 0.5) / texSize).r * 255.0 + 0.5);
  if (bpp8 > 0.5) {
    if (idx < 0.5) return vec4(0.0);
  } else if (mod(idx, 16.0) < 0.5) {
    return vec4(0.0);
  }
  return vec4(Texel(palTex, vec2((idx + 0.5) / 256.0, 0.25)).rgb, 1.0);
}
]]

local OBJ_SHADER = [[
extern Image sheet;
extern vec2 sheetSize;
extern vec2 frameOrigin;
extern vec2 sprSize;
extern vec2 boxPos;
extern vec2 boxSize;
extern float affine;
extern vec4 mat;
extern vec2 flip;
extern float palBase;
extern float bpp8;
extern Image palTex;
extern float tag;
vec4 effect(vec4 color, Image t, vec2 tc, vec2 sc) {
  vec2 l = floor(sc) - boxPos;
  vec2 s;
  if (affine > 0.5) {
    vec2 d = l - floor(boxSize * 0.5);
    s.x = floor((mat.x * d.x + mat.y * d.y) / 256.0) + floor(sprSize.x * 0.5);
    s.y = floor((mat.z * d.x + mat.w * d.y) / 256.0) + floor(sprSize.y * 0.5);
    if (s.x < 0.0 || s.y < 0.0 || s.x >= sprSize.x || s.y >= sprSize.y) discard;
  } else {
    s = l;
    if (flip.x > 0.5) s.x = sprSize.x - 1.0 - s.x;
    if (flip.y > 0.5) s.y = sprSize.y - 1.0 - s.y;
  }
  float idx = floor(Texel(sheet, (frameOrigin + s + 0.5) / sheetSize).r * 255.0 + 0.5);
  if (idx < 0.5) discard;
  float pi = bpp8 > 0.5 ? idx : palBase + idx;
  return vec4(Texel(palTex, vec2((pi + 0.5) / 256.0, 0.75)).rgb, tag);
}
]]

local COMPOSE_SHADER = [[
extern Image bg0;
extern Image bg1;
extern Image bg2;
extern Image bg3;
extern Image obj;
extern Image objWin;
extern Image palTex;
extern vec4 bgOn;
extern vec4 bgPrio;
extern float objOn;
extern vec3 winFlags;
extern vec4 win0;
extern vec4 win1;
extern vec4 winMasks;
extern float bldMode;
extern float t1;
extern float t2;
extern vec3 ev;

float bitOf(float mask, float b) {
  return mod(floor(mask / exp2(b) + 0.001), 2.0);
}

bool inRange(float v, float lo, float hi) {
  return v >= lo && v < hi;
}

vec3 c5(vec4 c) {
  return floor(c.rgb * 31.0 + 0.5);
}

void push(inout float n, inout float id1, inout vec3 col1, inout float semi1, inout float id2, inout vec3 col2, float id, vec3 col, float semi) {
  if (n < 0.5) {
    id1 = id; col1 = col; semi1 = semi; n = 1.0;
  } else if (n < 1.5) {
    id2 = id; col2 = col; n = 2.0;
  }
}

vec4 effect(vec4 color, Image t, vec2 tc, vec2 sc) {
  vec2 uv = sc / vec2(240.0, 160.0);
  float x = floor(sc.x);
  float y = floor(sc.y);
  float mask = 63.0;
  if (winFlags.x > 0.5 || winFlags.y > 0.5 || winFlags.z > 0.5) {
    mask = winMasks.z;
    if (winFlags.x > 0.5 && inRange(x, win0.x, win0.y) && inRange(y, win0.z, win0.w)) {
      mask = winMasks.x;
    } else if (winFlags.y > 0.5 && inRange(x, win1.x, win1.y) && inRange(y, win1.z, win1.w)) {
      mask = winMasks.y;
    } else if (winFlags.z > 0.5 && Texel(objWin, uv).a > 0.5) {
      mask = winMasks.w;
    }
  }
  vec4 s0 = Texel(bg0, uv);
  vec4 s1 = Texel(bg1, uv);
  vec4 s2 = Texel(bg2, uv);
  vec4 s3 = Texel(bg3, uv);
  vec4 so = Texel(obj, uv);
  float ov = floor(so.a * 255.0 + 0.5);
  float objPresent = (objOn > 0.5 && ov >= 16.0 && bitOf(mask, 4.0) > 0.5) ? 1.0 : 0.0;
  float objPrio = floor((ov - 16.0) / 4.0);
  float objSemi = mod(floor((ov - 16.0) / 2.0), 2.0);
  float n = 0.0;
  float id1 = 5.0;
  float id2 = 5.0;
  float semi1 = 0.0;
  vec3 col1 = vec3(0.0);
  vec3 col2 = vec3(0.0);
  for (int p = 0; p < 4; p++) {
    float fp = float(p);
    if (objPresent > 0.5 && objPrio == fp) push(n, id1, col1, semi1, id2, col2, 4.0, c5(so), objSemi);
    if (bgOn.x > 0.5 && bgPrio.x == fp && s0.a > 0.5 && bitOf(mask, 0.0) > 0.5) push(n, id1, col1, semi1, id2, col2, 0.0, c5(s0), 0.0);
    if (bgOn.y > 0.5 && bgPrio.y == fp && s1.a > 0.5 && bitOf(mask, 1.0) > 0.5) push(n, id1, col1, semi1, id2, col2, 1.0, c5(s1), 0.0);
    if (bgOn.z > 0.5 && bgPrio.z == fp && s2.a > 0.5 && bitOf(mask, 2.0) > 0.5) push(n, id1, col1, semi1, id2, col2, 2.0, c5(s2), 0.0);
    if (bgOn.w > 0.5 && bgPrio.w == fp && s3.a > 0.5 && bitOf(mask, 3.0) > 0.5) push(n, id1, col1, semi1, id2, col2, 3.0, c5(s3), 0.0);
  }
  vec3 bd = c5(Texel(palTex, vec2(0.5 / 256.0, 0.25)));
  push(n, id1, col1, semi1, id2, col2, 5.0, bd, 0.0);
  push(n, id1, col1, semi1, id2, col2, 5.0, bd, 0.0);
  vec3 outc = col1;
  if (bitOf(mask, 5.0) > 0.5) {
    bool top1 = bitOf(t1, id1) > 0.5;
    bool bot2 = bitOf(t2, id2) > 0.5;
    if (id1 == 4.0 && semi1 > 0.5 && bot2) {
      outc = min(vec3(31.0), floor((col1 * ev.x + col2 * ev.y) / 16.0));
    } else if (bldMode == 1.0 && top1 && bot2) {
      outc = min(vec3(31.0), floor((col1 * ev.x + col2 * ev.y) / 16.0));
    } else if (bldMode == 2.0 && top1) {
      outc = col1 + floor((31.0 - col1) * ev.z / 16.0);
    } else if (bldMode == 3.0 && top1) {
      outc = col1 - floor(col1 * ev.z / 16.0);
    }
  }
  vec3 o8 = outc * 8.0 + floor(outc / 4.0);
  return vec4(o8 / 255.0, 1.0);
}
]]

local function canvas()
  local c = love.graphics.newCanvas(Ppu.W, Ppu.H, { dpiscale = 1 })
  c:setFilter("nearest", "nearest")
  return c
end

function Ppu:_ensureGpu()
  if self.gpu then return self.gpu end
  local g = {}
  g.bgShader = love.graphics.newShader(BG_SHADER)
  g.objShader = love.graphics.newShader(OBJ_SHADER)
  g.composeShader = love.graphics.newShader(COMPOSE_SHADER)
  g.bg = {}
  for i = 0, 3 do g.bg[i] = canvas() end
  g.obj = canvas()
  g.objWin = canvas()
  g.out = canvas()
  g.palData = love.image.newImageData(256, 2)
  g.palImage = love.graphics.newImage(g.palData)
  g.palImage:setFilter("nearest", "nearest")
  g.lineData = love.image.newImageData(160, 1)
  g.lineImage = love.graphics.newImage(g.lineData)
  g.lineImage:setFilter("nearest", "nearest")
  g.pixel = love.graphics.newImage(love.image.newImageData(1, 1))
  self.gpu = g
  return g
end

local function c5to01(c, shift)
  return band(rshift(c, shift), 31) / 31
end

function Ppu:_uploadPalette(g)
  local pltt, d = self.palette.pltt, g.palData
  for row = 0, 1 do
    for i = 0, 255 do
      local c = pltt[row * 256 + i] or 0
      d:setPixel(i, row, c5to01(c, 0), c5to01(c, 5), c5to01(c, 10), 1)
    end
  end
  g.palImage:replacePixels(d)
end

local LINE_DEST = {
  BG0HOFS = { 0, 1 }, BG0VOFS = { 0, 2 }, BG1HOFS = { 1, 1 }, BG1VOFS = { 1, 2 },
  BG2HOFS = { 2, 1 }, BG2VOFS = { 2, 2 }, BG3HOFS = { 3, 1 }, BG3VOFS = { 3, 2 },
}

function Ppu:_isAffine(i)
  local mode = band(self.regs.DISPCNT, 7)
  if mode == 1 then return i == 2 end
  if mode == 2 then return i >= 2 end
  return false
end

function Ppu:_bgEnabled(i)
  local d = self.regs.DISPCNT
  if band(d, Ppu.DISPCNT_FORCED_BLANK) ~= 0 then return false end
  if band(d, bit.lshift(0x100, i)) == 0 then return false end
  local mode = band(d, 7)
  if mode == 1 and i == 3 then return false end
  if mode == 2 and i < 2 then return false end
  return self.bg[i].layer ~= nil
end

function Ppu:_renderBg(g, i, lines, lineDest)
  local b = self.bg[i]
  local L = b.layer
  local sh = g.bgShader
  love.graphics.setCanvas(g.bg[i])
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader(sh)
  sh:send("idxTex", L.image)
  sh:send("texSize", { L.w, L.h })
  sh:send("palTex", g.palImage)
  sh:send("bpp8", L.bpp == 8 and 1 or 0)
  local r = self.regs
  if self:_isAffine(i) then
    local p = "BG" .. i
    sh:send("affine", 1)
    sh:send("mat", { r[p .. "PA"], r[p .. "PB"], r[p .. "PC"], r[p .. "PD"] })
    sh:send("ref", { r[p .. "X"], r[p .. "Y"] })
    sh:send("wrap", b.wrap and 1 or 0)
    sh:send("lineMode", 0)
    sh:send("ofs", { 0, 0 })
  else
    sh:send("affine", 0)
    sh:send("mat", { 256, 0, 0, 256 })
    sh:send("ref", { 0, 0 })
    sh:send("wrap", 1)
    sh:send("ofs", { band(r["BG" .. i .. "HOFS"], 0x1FF), band(r["BG" .. i .. "VOFS"], 0x1FF) })
    local mode = 0
    if lines and lineDest and lineDest[1] == i then
      mode = lineDest[2]
      local d = g.lineData
      for y = 0, 159 do
        local v = band(lines[y] or 0, 0x1FF)
        d:setPixel(y, 0, band(v, 0xFF) / 255, rshift(v, 8) / 255, 0, 1)
      end
      g.lineImage:replacePixels(d)
    end
    sh:send("lineTex", g.lineImage)
    sh:send("lineMode", mode)
  end
  love.graphics.draw(g.pixel, 0, 0, 0, Ppu.W, Ppu.H)
end

local function objBox(e)
  local bw, bh = e.w, e.h
  if e.affineMode == 3 then bw, bh = bw * 2, bh * 2 end
  local x, y = e.x, e.y
  if x >= 256 then x = x - 512 end
  if y >= 160 then y = y - 256 end
  return x, y, bw, bh
end

function Ppu.objScanlineRanges(list, dispcnt)
  local remaining, ranges = {}, {}
  local budget = band(dispcnt, Ppu.DISPCNT_HBLANK_FREE) ~= 0 and 954 or 1210
  for row = 0, Ppu.H - 1 do remaining[row] = budget end
  for _, e in ipairs(list) do
    local visible = {}
    ranges[e] = visible
    if e.affineMode ~= 2 then
      local x, y, bw, bh = objBox(e)
      if x < Ppu.W and x + bw >= 0 then
        local cycles = band(e.affineMode, 1) ~= 0 and (10 + bw * 2) or bw
        local first
        local stop = math.min(Ppu.H, y + bh)
        for row = math.max(0, y), stop - 1 do
          if remaining[row] > 0 then
            remaining[row] = remaining[row] - cycles
            if not first then first = row end
          elseif first then
            visible[#visible + 1] = { first, row }
            first = nil
          end
        end
        if first then visible[#visible + 1] = { first, stop } end
      end
    end
  end
  return ranges
end

function Ppu:_renderObjs(g, list, target, windowPass, ranges)
  local sh = g.objShader
  love.graphics.setCanvas(target)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setShader(sh)
  love.graphics.setBlendMode("replace", "premultiplied")
  sh:send("palTex", g.palImage)
  for k = #list, 1, -1 do
    local e = list[k]
    local sheet = e.sheet
    local visible = ranges[e]
    if sheet and visible and #visible > 0 then
      local x, y, bw, bh = objBox(e)
      sh:send("sheet", sheet.image)
      sh:send("sheetSize", { sheet.w, sheet.h })
      local rect = sheet.rects and sheet.rects[(e.frame or 0) + 1]
      if rect then
        sh:send("frameOrigin", { rect.x, rect.y })
      else
        sh:send("frameOrigin", { 0, (e.frame or 0) * (sheet.frameH or e.h) })
      end
      sh:send("sprSize", { e.w, e.h })
      sh:send("boxPos", { x, y })
      sh:send("boxSize", { bw, bh })
      local affine = band(e.affineMode, 1) ~= 0
      sh:send("affine", affine and 1 or 0)
      sh:send("mat", { e.a or 256, e.b or 0, e.c or 0, e.d or 256 })
      sh:send("flip", { e.hFlip and 1 or 0, e.vFlip and 1 or 0 })
      sh:send("palBase", (e.paletteNum or 0) * 16)
      sh:send("bpp8", e.bpp == 8 and 1 or 0)
      local tag = windowPass and 1 or (16 + (e.priority or 0) * 4 + (e.objMode == 1 and 2 or 0)) / 255
      sh:send("tag", tag)
      for _, rows in ipairs(visible) do
        love.graphics.setScissor(0, rows[1], Ppu.W, rows[2] - rows[1])
        love.graphics.draw(g.pixel, x, y, 0, bw, bh)
      end
    end
  end
  love.graphics.setScissor()
  love.graphics.setBlendMode("alpha", "alphamultiply")
end

local function window(h, v, maxW, maxH)
  local l, r = rshift(band(h, 0xFFFF), 8), band(h, 0xFF)
  local t, b = rshift(band(v, 0xFFFF), 8), band(v, 0xFF)
  if r > maxW or l > r then r = maxW end
  if b > maxH or t > b then b = maxH end
  return { l, r, t, b }
end

function Ppu:render()
  local g = self:_ensureGpu()
  love.graphics.push("all")
  love.graphics.origin()
  love.graphics.setScissor()
  love.graphics.setColor(1, 1, 1, 1)
  self:_uploadPalette(g)
  local lines, dest = self.scanline:lineValues()
  local lineDest = dest and LINE_DEST[dest] or nil
  local on = {}
  for i = 0, 3 do
    on[i] = self:_bgEnabled(i)
    if on[i] then self:_renderBg(g, i, lines, lineDest) end
  end
  local r = self.regs
  local objOn = band(r.DISPCNT, Ppu.DISPCNT_OBJ_ON) ~= 0 and band(r.DISPCNT, Ppu.DISPCNT_FORCED_BLANK) == 0
  local shown, winList = {}, {}
  local ranges = Ppu.objScanlineRanges(objOn and (self.sprites.oamShown or {}) or {}, r.DISPCNT)
  if objOn then
    for _, e in ipairs(self.sprites.oamShown or {}) do
      if e.objMode == 2 then winList[#winList + 1] = e else shown[#shown + 1] = e end
    end
  end
  self:_renderObjs(g, shown, g.obj, false, ranges)
  local objWinOn = band(r.DISPCNT, Ppu.DISPCNT_OBJWIN_ON) ~= 0 and objOn
  self:_renderObjs(g, objWinOn and winList or {}, g.objWin, true, ranges)
  local sh = g.composeShader
  love.graphics.setCanvas(g.out)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setShader(sh)
  love.graphics.setBlendMode("replace", "premultiplied")
  for i = 0, 3 do sh:send("bg" .. i, g.bg[i]) end
  sh:send("obj", g.obj)
  sh:send("objWin", g.objWin)
  sh:send("palTex", g.palImage)
  sh:send("bgOn", { on[0] and 1 or 0, on[1] and 1 or 0, on[2] and 1 or 0, on[3] and 1 or 0 })
  sh:send("bgPrio", { self.bg[0].priority, self.bg[1].priority, self.bg[2].priority, self.bg[3].priority })
  sh:send("objOn", objOn and 1 or 0)
  sh:send("winFlags", {
    band(r.DISPCNT, Ppu.DISPCNT_WIN0_ON) ~= 0 and 1 or 0,
    band(r.DISPCNT, Ppu.DISPCNT_WIN1_ON) ~= 0 and 1 or 0,
    objWinOn and 1 or 0,
  })
  sh:send("win0", window(r.WIN0H, r.WIN0V, 240, 160))
  sh:send("win1", window(r.WIN1H, r.WIN1V, 240, 160))
  sh:send("winMasks", { band(r.WININ, 0x3F), band(rshift(r.WININ, 8), 0x3F), band(r.WINOUT, 0x3F), band(rshift(r.WINOUT, 8), 0x3F) })
  sh:send("bldMode", band(rshift(r.BLDCNT, 6), 3))
  sh:send("t1", band(r.BLDCNT, 0x3F))
  sh:send("t2", band(rshift(r.BLDCNT, 8), 0x3F))
  sh:send("ev", {
    math.min(16, band(r.BLDALPHA, 0x1F)),
    math.min(16, band(rshift(r.BLDALPHA, 8), 0x1F)),
    math.min(16, band(r.BLDY, 0x1F)),
  })
  love.graphics.draw(g.pixel, 0, 0, 0, Ppu.W, Ppu.H)
  love.graphics.pop()
  return g.out
end

function Ppu:draw(x, y)
  local out = self:render()
  love.graphics.push("all")
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha", "alphamultiply")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(out, x or 0, y or 0)
  love.graphics.pop()
  return out
end

function Ppu:snapshot()
  return self:render():newImageData()
end

return Ppu
