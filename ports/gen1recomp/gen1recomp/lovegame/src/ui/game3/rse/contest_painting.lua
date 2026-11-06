local bit = require("bit")
local band, rshift = bit.band, bit.rshift

local Fx = require("src.ui.game3.rse.contest_image_fx")

local Painting = {}

Painting.ID = "rse_contest_painting"
Painting.SUB = "data/generated/gba/rse/contest_painting"
Painting.MUSEUM_CONTEST_WINNERS_START = 8
Painting.NUM_PAINTING_CAPTIONS = 3
-- pokeemerald/src/contest_painting.c:513
Painting.MON_X, Painting.MON_Y = 88, 24
-- pokeemerald/src/contest_painting.c:117
Painting.WINDOW = { left = 2, top = 14, width = 26, height = 4 }

local CATEGORY_KEYS = { [0] = "cool", "beauty", "cute", "smart", "tough" }

local function readCache(path)
  return require("src.ui.game3.rse.contest_vram").readCache(path)
end

local manifestCache

function Painting.manifest()
  if manifestCache then return manifestCache end
  local src = assert(readCache(Painting.SUB .. "/manifest.lua"), "contest painting manifest is not in the cache")
  local chunk = assert(load(src, "@contest_painting/manifest.lua", "t", {}))
  manifestCache = chunk()
  return manifestCache
end

function Painting.resetCache()
  manifestCache = nil
end

local function bytesToU16(s)
  local out = {}
  for i = 0, #s / 2 - 1 do
    local lo, hi = s:byte(i * 2 + 1, i * 2 + 2)
    out[i] = lo + hi * 256
  end
  return out
end

local function bytesToU8(s)
  local out = {}
  for i = 1, #s do out[i - 1] = s:byte(i) end
  return out
end

-- pokeemerald/src/contest_painting.c:523
function Painting.imageEffect(saveIdx, winner)
  local cat
  if saveIdx < Painting.MUSEUM_CONTEST_WINNERS_START then
    cat = winner.contestCategory
  else
    cat = math.floor(winner.contestCategory / Painting.NUM_PAINTING_CAPTIONS)
  end
  local E = Fx.EFFECT
  if cat == 0 then return E.OUTLINE_COLORED end
  if cat == 1 then return E.SHIMMER end
  if cat == 2 then return E.POINTILLISM end
  if cat == 3 then return E.CHARCOAL end
  if cat == 4 then return E.GRAYSCALE_LIGHT end
  return cat
end

-- pokeemerald/src/contest_painting.c:364
function Painting.monPixels(winner)
  local Pokemon = require("src.core.game3.pokemon")
  local CachePaths = require("src.core.game3.cache_paths")
  local species = tonumber(winner.species) or 0
  local p = (tonumber(winner.personality) or 0) % 4294967296
  local tid = tonumber(winner.trainerId) or 0
  local shiny = Pokemon.isShiny({ personality = p, otId = tid % 65536, otSecretId = math.floor(tid / 65536) % 65536 })
  local kind = shiny and "front_shiny" or "front"
  local rgba
  if species == Pokemon.SPECIES_SPINDA then
    -- pokeemerald/src/pokemon.c:5802
    rgba = Pokemon.spindaRgba(p, shiny)
  end
  if not rgba then
    rgba = readCache((CachePaths.CACHE_ROOT or "data/generated/gba") .. "/pokemon/" .. kind .. "/"
      .. Pokemon.picSpecies(species, p) .. ".rgba")
  end
  local px = {}
  for i = 0, 64 * 64 - 1 do
    local r, g, b, a = 0, 0, 0, 0
    if rgba then r, g, b, a = rgba:byte(i * 4 + 1, i * 4 + 4) end
    if (a or 0) == 0 then
      px[i] = Fx.ALPHA
    else
      px[i] = Fx.rgb2(math.floor(r * 31 / 255 + 0.5), math.floor(g * 31 / 255 + 0.5), math.floor(b * 31 / 255 + 0.5))
    end
  end
  return px
end

-- pokeemerald/src/contest_painting.c:555
function Painting.processMon(winner, saveIdx, man)
  man = man or Painting.manifest()
  local effect = Painting.imageEffect(saveIdx, winner)
  local E = Fx.EFFECT
  local q = (effect == E.CHARCOAL or effect == E.GRAYSCALE_LIGHT) and Fx.QUANTIZE.GRAYSCALE
    or Fx.QUANTIZE.STANDARD_LIMITED_COLORS
  local pixels = Painting.monPixels(winner)
  local points
  if effect == E.POINTILLISM then points = bytesToU8(assert(readCache(man.pointillism.path))) end
  local ctx = Fx.context(pixels, {
    effect = effect, quantizeEffect = q, personality = (tonumber(winner.personality) or 0) % 256,
    pointillism = points, pointillismCount = man.pointillism.count,
  })
  Fx.apply(ctx)
  Fx.quantize(ctx)
  return { indices = ctx.pixels, palette = ctx.palette, effect = effect }
end

-- pokeemerald/src/contest_painting.c:419
function Painting.frameMap(saveIdx, winner, isForArtist, man)
  man = man or Painting.manifest()
  local key
  if isForArtist then
    key = CATEGORY_KEYS[math.floor(winner.contestCategory / Painting.NUM_PAINTING_CAPTIONS)]
  elseif saveIdx < Painting.MUSEUM_CONTEST_WINNERS_START then
    key = "lobby"
  else
    key = CATEGORY_KEYS[math.floor(winner.contestCategory / Painting.NUM_PAINTING_CAPTIONS)]
  end
  local entry = man.frames[key or "cool"]
  local src = bytesToU16(assert(readCache(entry.map)))
  local map = src
  if isForArtist then
    map = {}
    for i = 0, 32 * 32 - 1 do map[i] = 0 end
    for y = 0, 19 do
      for x = 0, 31 do map[y * 32 + x] = 0x1015 end
    end
    for y = 0, 9 do
      for x = 0, 17 do map[(y + 2) * 32 + x + 6] = src[(y + 2) * 32 + x + 6] end
    end
    for x = 0, 15 do map[2 * 32 + x + 7] = src[2 * 32 + 7] end
  end
  return map, entry.gfx, key
end

local function Stage() return require("src.ui.game3.rse.contest") end

local function nameOf(v)
  if type(v) == "string" then return v end
  if type(v) == "table" then return require("src.core.game3.rse.contest_util").decode(v) end
  return ""
end

-- pokeemerald/src/contest_painting.c:281
function Painting.caption(saveIdx, winner, isForArtist, man)
  if isForArtist then return nil end
  man = man or Painting.manifest()
  local S = Stage()
  if saveIdx < Painting.MUSEUM_CONTEST_WINNERS_START then
    local s1 = S.plain("sContestNames[" .. (winner.contestCategory or 0) .. "]") .. " " ..
      S.plain(man.rankNames[winner.contestRank or 0] or man.rankNames[0])
    return S.plain(man.hallCaption, { s1, nameOf(winner.trainerName), nameOf(winner.monName) })
  end
  local key = man.captions[winner.contestCategory or 0] or man.captions[0]
  return S.plain(key, { nameOf(winner.monName) })
end

function Painting.build(opts)
  local man = Painting.manifest()
  local winner = assert(opts.winner, "contest painting needs a winner")
  local saveIdx = tonumber(opts.saveIdx) or 0
  local map, gfxPath, key = Painting.frameMap(saveIdx, winner, opts.isForArtist, man)
  local caption
  if opts.nativePolicy then caption = opts.nativePolicy.caption(saveIdx, winner, opts.isForArtist, man)
  else caption = Painting.caption(saveIdx, winner, opts.isForArtist, man) end
  return {
    winner = winner, saveIdx = saveIdx, isForArtist = opts.isForArtist and true or false,
    map = map, gfx = assert(readCache(gfxPath)), frameKey = key,
    mon = Painting.processMon(winner, saveIdx, man),
    caption = caption,
    nativePolicy = opts.nativePolicy,
    framePalette = man.framePalette,
  }
end

local function rgb8(c)
  c = (tonumber(c) or 0) % 32768
  return math.floor((c % 32) * 255 / 31 + 0.5), math.floor((math.floor(c / 32) % 32) * 255 / 31 + 0.5),
    math.floor((math.floor(c / 1024) % 32) * 255 / 31 + 0.5)
end

local function newData(w, h)
  local data = love.image.newImageData(w, h)
  local ok, ptr = pcall(function() return data:getFFIPointer() end)
  if ok and ptr then return data, require("ffi").cast("uint8_t*", ptr) end
  return data, nil
end

local function put(data, ptr, W, x, y, r, g, b)
  if ptr then
    local o = (y * W + x) * 4
    ptr[o], ptr[o + 1], ptr[o + 2], ptr[o + 3] = r, g, b, 255
  else
    data:setPixel(x, y, r / 255, g / 255, b / 255, 1)
  end
end

local function toImage(data)
  local img = love.graphics.newImage(data)
  img:setFilter("nearest", "nearest")
  return img
end

-- pokeemerald/src/contest_painting.c:419
function Painting.renderFrame(st)
  local data, ptr = newData(256, 256)
  local gfx, pal = st.gfx, st.framePalette
  local tiles = math.floor(#gfx / 32)
  for ty = 0, 31 do
    for tx = 0, 31 do
      local e = st.map[ty * 32 + tx] or 0
      local tile = e % 1024
      local hf = math.floor(e / 1024) % 2 == 1
      local vf = math.floor(e / 2048) % 2 == 1
      local bank = math.floor(e / 4096) % 16
      for py = 0, 7 do
        local sy = vf and (7 - py) or py
        for px = 0, 7 do
          local sx = hf and (7 - px) or px
          local v = 0
          if tile < tiles then
            local byte = gfx:byte(tile * 32 + sy * 4 + math.floor(sx / 2) + 1) or 0
            v = (sx % 2 == 0) and (byte % 16) or math.floor(byte / 16)
          end
          if v ~= 0 then
            local r, g, b = rgb8(pal[bank * 16 + v + 1] or 0)
            put(data, ptr, 256, tx * 8 + px, ty * 8 + py, r, g, b)
          end
        end
      end
    end
  end
  return toImage(data)
end

-- pokeemerald/src/image_processing_effects.c:766
function Painting.renderMon(st)
  local data = love.image.newImageData(64, 64)
  local idx, pal = st.mon.indices, st.mon.palette
  for i = 0, 64 * 64 - 1 do
    local v = idx[i] or 0
    if v ~= 0 then
      local r, g, b = rgb8(pal[v] or 0)
      data:setPixel(i % 64, math.floor(i / 64), r / 255, g / 255, b / 255, 1)
    end
  end
  return toImage(data)
end

local MOSAIC_SHADER = [[
extern number size;
extern vec2 dims;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec2 p = floor(tc * dims);
  p = p - mod(p, size);
  return Texel(tex, (p + 0.5) / dims) * color;
}
]]

local st
Painting._st = function() return st end

function Painting.isOpen()
  return st ~= nil
end

local function finish()
  local done = st and st.onDone
  st = nil
  require("src.ui.game3.stack").pop(Painting.ID)
  if done then done() end
end

-- pokeemerald/src/contest_painting.c:173
function Painting.open(opts)
  opts = opts or {}
  local built = Painting.build(opts)
  st = built
  st.onDone = opts.onDone
  -- pokeemerald/src/contest_painting.c:337
  st.fadeCounter = 30
  st.holdState = 0
  st.fade = 32
  st.fadeDir = -2
  st.frames = 0
  st.headless = opts.headless or not (love and love.graphics and love.image)
  if st.headless then
    st.autoClose = opts.autoClose ~= false
    if st.autoClose then
      local s = st
      finish()
      return s
    end
    return st
  end
  st.frameImage = Painting.renderFrame(st)
  st.monImage = Painting.renderMon(st)
  require("src.ui.game3.stack").push(Painting.ID, Painting, { hideBelow = true, fullscreen = true })
  return st
end

local Kit
local function kit() Kit = Kit or require("src.ui.game3.rse.scene_kit"); return Kit end

function Painting.handleInput(input)
  if not st then return end
  st.step = st.step or kit().stepper()
  st.step:collect(input)
end

-- pokeemerald/src/contest_painting.c:237
local function frame(inp)
  st.frames = st.frames + 1
  if st.fadeDir ~= 0 then
    st.fade = st.fade + st.fadeDir
    if st.fade <= 0 then st.fade, st.fadeDir = 0, 0 end
    if st.fade >= 32 then st.fade, st.fadeDir = 32, 0 end
  end
  local fading = st.fadeDir ~= 0
  if st.holdState == 0 then
    if not fading then st.holdState = 1 end
    if st.fadeCounter > 0 then st.fadeCounter = st.fadeCounter - 1 end
  elseif st.holdState == 1 then
    local n = inp.new or {}
    if n.a or n.b then
      st.holdState = 2
      st.fadeDir = 2
    end
    st.fadeCounter = 0
  elseif st.holdState == 2 then
    if not fading then return true end
    if st.fadeCounter < 30 then st.fadeCounter = st.fadeCounter + 1 end
  end
  return nil
end

function Painting.update(dt)
  if not st then return end
  st.step = st.step or kit().stepper()
  local done = st.step:run(dt, frame)
  if done then finish() end
end

function Painting.draw()
  if not st or st.headless then return end
  local lg = love.graphics
  st.canvas = st.canvas or lg.newCanvas(240, 160)
  st.canvas:setFilter("nearest", "nearest")
  lg.push("all")
  lg.setCanvas(st.canvas)
  lg.clear(0, 0, 0, 1)
  lg.setColor(1, 1, 1, 1)
  lg.draw(st.frameImage, 0, 0)
  lg.draw(st.monImage, Painting.MON_X, Painting.MON_Y)
  if st.caption then
    if st.nativePolicy then st.nativePolicy.drawCaption(st, Painting.manifest())
    else
      local FrlgFont = require("src.ui.game3.frlg_font")
      local W = Painting.WINDOW
      local colors = kit().messageColors()
      local w = FrlgFont.measure(st.caption)
      local x = W.left * 8 + math.floor((W.width * 8 - w) / 2)
      FrlgFont.draw(st.caption, x, W.top * 8 + 1, { colors = colors })
    end
  end
  lg.setCanvas()
  lg.pop()
  -- pokeemerald/src/contest_painting.c:342
  local mosaic = math.floor(st.fadeCounter / 2)
  lg.setColor(1, 1, 1, 1)
  if mosaic > 0 then
    st.shader = st.shader or lg.newShader(MOSAIC_SHADER)
    st.shader:send("size", mosaic + 1)
    st.shader:send("dims", { 240, 160 })
    lg.setShader(st.shader)
  end
  lg.draw(st.canvas, 0, 0)
  lg.setShader()
  if st.fade > 0 then
    lg.setColor(0, 0, 0, st.fade / 32)
    lg.rectangle("fill", 0, 0, 240, 160)
    lg.setColor(1, 1, 1, 1)
  end
end

function Painting.close()
  if st then finish() end
end

function Painting.reset()
  if st then
    st = nil
    require("src.ui.game3.stack").pop(Painting.ID)
  end
end

return Painting
