-- FRLG Pokémon Storage System & PC Chrome helper.
-- Direct 1:1 rendering from ROM-extracted assets (pokefirered / FRLG).
-- Zero procedural approximations; loads pre-extracted textures from CacheFS.

local FrlgFont = require("src.ui.game3.frlg_font")
local Pokemon = require("src.core.game3.pokemon")
local ItemsData = require("src.core.game3.items_data")
local Strings = require("src.core.Strings")
local Presentation = require("src.ui.game3.storage_presentation")
local CacheBlob = require("src.import.CacheBlob")

local PcChrome = {}

-- Cached texture images (loaded on demand / ensure)
PcChrome._initialized = false
PcChrome._cursorImg = nil
PcChrome._shadowImg = nil
PcChrome._arrowImg = nil
PcChrome._bgImg = nil
PcChrome._frameImg = nil
PcChrome._buttonPartyImg = nil
PcChrome._buttonCloseImg = nil
PcChrome._partyDrawerBgImg = nil
PcChrome._partySlotFilledImg = nil
PcChrome._partySlotEmptyImg = nil
PcChrome._waveformImg = nil
PcChrome._wallpapers = {}

PcChrome.WALLPAPER_NAMES = {
  [1]  = "forest",
  [2]  = "city",
  [3]  = "desert",
  [4]  = "savanna",
  [5]  = "crag",
  [6]  = "volcano",
  [7]  = "snow",
  [8]  = "cave",
  [9]  = "beach",
  [10] = "seafloor",
  [11] = "river",
  [12] = "sky",
  [13] = "stars",
  [14] = "pokecenter",
  [15] = "tiles",
  [16] = "simple",
}

local function read_bytes(rel)
  local okD, Dataset = pcall(require, "src.core.game3.dataset")
  if okD and Dataset and Dataset.mountExtractRoots then
    Dataset.mountExtractRoots()
  end
  if okD and Dataset and Dataset.cache then
    local cacheObj = Dataset.cache()
    if cacheObj and cacheObj.read then
      local d = cacheObj:read(rel)
      if type(d) == "string" and #d > 0 then return d end
    end
  end
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  if okC and CacheFs and CacheFs.readActive then
    local d = CacheFs.readActive(rel)
    if type(d) == "string" and #d > 0 then return d end
  end
  if love and love.filesystem and love.filesystem.read then
    local ok, d = pcall(CacheBlob.readFs, rel)
    if ok and type(d) == "string" and #d > 0 then return d end
  end
  local f = io.open(rel, "rb")
  if f then
    local d = CacheBlob.decode(rel, f:read("*a"))
    f:close()
    if type(d) == "string" and #d > 0 then return d end
  end
  return nil
end

local function load_texture(name)
  local candidates = {
    "pokemon/storage/" .. name,
    "data/generated/gba/pokemon/storage/" .. name,
  }
  local okA, Assets = pcall(require, "src.render.Assets")
  for _, path in ipairs(candidates) do
    if okA and Assets and Assets.image then
      local ok, img = pcall(Assets.image, path)
      if ok and img then
        if img.setFilter then img:setFilter("nearest", "nearest") end
        return img
      end
    end
    local bytes = read_bytes(path)
    if bytes and #bytes > 0 and love and love.image and love.graphics and love.filesystem then
      local ok, img = pcall(function()
        local fd = love.filesystem.newFileData(bytes, name)
        local id = love.image.newImageData(fd)
        local image = love.graphics.newImage(id)
        if image.setFilter then image:setFilter("nearest", "nearest") end
        return image
      end)
      if ok and img then return img end
    end
    if love and love.graphics and love.graphics.newImage then
      local ok, img = pcall(love.graphics.newImage, path)
      if ok and img then
        if img.setFilter then img:setFilter("nearest", "nearest") end
        return img
      end
    end
  end
  return nil
end

local function load_manifest()
  local src = read_bytes("data/generated/gba/pokemon/storage/manifest.lua")
  local chunk = src and load(src, "@storage/manifest.lua", "t", {})
  local ok, t = pcall(chunk or function() return nil end)
  return ok and type(t) == "table" and t or nil
end

local function active_game()
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  return ok and GameVersion.get and GameVersion.get() or nil
end

function PcChrome.ensure()
  local game = active_game()
  if PcChrome._initialized and PcChrome._game == game then return end
  PcChrome._initialized = true
  PcChrome._game = game
  PcChrome._wallpapers = {}
  PcChrome._friends = nil
  PcChrome._manifest = load_manifest()
  PcChrome._pcScreenBarImg = nil

  PcChrome._cursorImg = load_texture("cursor.png")
  PcChrome._shadowImg = load_texture("cursor_shadow.png")
  PcChrome._arrowImg = load_texture("box_scroll_arrow.png")
  PcChrome._bgImg = load_texture("scrolling_bg.png")
  local rs = game == "ruby" or game == "sapphire"
  if rs then
    local e = PcChrome._manifest and PcChrome._manifest.pcScreenEffect
    if e and e.bar then PcChrome._pcScreenBarImg = load_texture(e.bar.png or e.bar.file) end
  end
  PcChrome._frameImg = load_texture(rs and "header.png" or "interface_frame.png")
  PcChrome._buttonPartyImg = load_texture("button_party.png")
  PcChrome._buttonCloseImg = load_texture("button_close.png")
  PcChrome._partyDrawerBgImg = load_texture(rs and "party_drawer.png" or "party_drawer_bg.png")
  PcChrome._partySlotFilledImg = load_texture("party_slot_filled.png")
  PcChrome._partySlotEmptyImg = load_texture("party_slot_empty.png")
  if rs then
    PcChrome._partySlotFilledImg, PcChrome._partySlotEmptyImg = require("src.ui.game3.rs.storage_visuals").slotImages()
  end
  PcChrome._waveformImg = load_texture("waveform.png")
  PcChrome._waveformQuads = nil

  for id, name in ipairs(PcChrome.wallpaperNames()) do
    PcChrome._wallpapers[id] = load_texture("wallpapers/" .. name .. ".png")
  end
end

function PcChrome.presentationManifest()
  PcChrome.ensure()
  return PcChrome._manifest, PcChrome._game
end

local effectShaderSource = [[
  extern number mode;
  extern number centerY;
  extern number halfHeight;
  extern number barLayer;
  extern number fadeY;
  extern number fadeWhite;
  extern vec2 spriteSize;
  extern number blockSize;
  vec4 effect(vec4 color, Image image, vec2 tc, vec2 sc) {
    if (blockSize > 1.0) {
      vec2 p = floor(tc * spriteSize);
      tc = (floor(p / blockSize) * blockSize + vec2(0.5)) / spriteSize;
    }
    vec4 pixel = Texel(image, tc) * color;
    // HBlank writes following VCOUNT n affect visible scanline n+1.
    float row = floor(sc.y) - 1.0;
    if (mode == 1.0) pixel.rgb = vec3(0.0);
    else if (mode == 2.0) pixel.rgb = vec3(1.0);
    else if (mode == 3.0) {
      if (row != centerY) pixel.rgb = vec3(0.0);
      else if (barLayer == 0.0) pixel.rgb = vec3(1.0);
    } else if (mode == 4.0 && !(row > centerY-halfHeight && row < centerY+halfHeight)) pixel.rgb = vec3(0.0);
    if (fadeY > 0.0) {
      vec3 nativeColor = floor(pixel.rgb * 31.0 + vec3(0.5));
      pixel.rgb = (nativeColor + floor((vec3(fadeWhite * 31.0)-nativeColor) * fadeY / 16.0)) / 31.0;
    }
    return pixel;
  }
]]
function PcChrome.effectLayer(layer, draw, mosaic)
  local effect = PcChrome._effect
  if not effect then return draw() end
  local s, f = effect.screen, effect.fade
  local mode = 0
  if s then
    if s.black or s.phase == "black" or s.opening and s.phase == "init" then mode = 1
    elseif s.phase == "departInitial" then mode = 2 -- initial BLDCNT=191, BLDY=16
    elseif s.phase == "depart" or s.phase == "arrive" then mode = 3
    elseif s.phase == "expand" or s.phase == "shrink" then mode = 4 end
  end
  local isObj = layer == "obj" or layer == "title" or layer == "bar"
  local selected = f and (f.scope == "all" or layer == "wallpaper" or layer == "title")
  local values = {mode = mode, centerY = s and s.centerY or 80, halfHeight = s and s.half or 80,
    barLayer = layer == "bar" and 1 or 0, fadeY = selected and (isObj and f.objs or f.bg) or 0,
    fadeWhite = f and f.color == "white" and 1 or 0,
    spriteSize = mosaic and mosaic.size or {1, 1}, blockSize = mosaic and mosaic.block or 1}
  if not PcChrome._effectShader then PcChrome._effectShader = love.graphics.newShader(effectShaderSource) end
  local shader = PcChrome._effectShader
  local previous = PcChrome._effectValues
  PcChrome._effectValues = values
  for name, value in pairs(values) do shader:send(name, value) end
  love.graphics.push("all")
  love.graphics.setShader(shader)
  local ok, err = pcall(draw)
  love.graphics.pop()
  PcChrome._effectValues = previous
  if previous then for name, value in pairs(previous) do shader:send(name, value) end end
  if not ok then error(err, 0) end
end
function PcChrome.effectFrame(effect, draw)
  if not (effect and (effect.screen and effect.screen.rs or effect.fade)) then return draw() end
  local previous = PcChrome._effect
  PcChrome._effect = effect
  love.graphics.push("all")
  local ok, err = pcall(function() PcChrome.effectLayer("bg", draw) end)
  love.graphics.pop()
  PcChrome._effect = previous
  if not ok then error(err, 0) end
end
function PcChrome.drawScreenBars(screen)
  if not (screen and screen.rs and screen.bars) then return end
  PcChrome.ensure()
  local img = assert(PcChrome._pcScreenBarImg, "native RS PC screen bar texture missing")
  local e = screen.effect.bar
  local q = love.graphics.newQuad(0, 0, e.w, e.h, img:getDimensions())
  PcChrome.effectLayer("bar", function()
    love.graphics.setColor(1, 1, 1, 1)
    for _, b in ipairs(screen.bars) do
      if b.visible and not b.dead then love.graphics.draw(img, q, b.x - e.w / 2, b.y - e.h / 2) end
    end
  end)
end

function PcChrome.clip(x, y, w, h, draw)
  local sx, sy, sw, sh = love.graphics.getScissor()
  if sx then
    local right, bottom = math.min(x + w, sx + sw), math.min(y + h, sy + sh)
    x, y = math.max(x, sx), math.max(y, sy)
    w, h = math.max(0, right - x), math.max(0, bottom - y)
  end
  love.graphics.setScissor(x, y, w, h)
  draw()
  if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
end

function PcChrome.wallpaperNames()
  local m = PcChrome._manifest
  if m and type(m.wallpaperOrder) == "table" then return m.wallpaperOrder end
  return PcChrome.WALLPAPER_NAMES
end

function PcChrome.hasFriends()
  PcChrome.ensure()
  return PcChrome._manifest ~= nil and PcChrome._manifest.friends ~= nil
end

-- pokeemerald/src/pokemon_storage_system.c:9661
PcChrome.WALDA_DEFAULT = { colors = { 0x7B35, 0x6186 }, iconId = 0, patternId = 0 }

local function bgr(c)
  c = tonumber(c) or 0
  return (c % 32) / 31, (math.floor(c / 32) % 32) / 31, (math.floor(c / 1024) % 32) / 31
end

-- pokeemerald/src/pokemon_storage_system.c:5388
function PcChrome.friendsWallpaper(walda)
  PcChrome.ensure()
  local m = PcChrome._manifest
  if not (m and m.friends) then return nil end
  walda = walda or PcChrome.WALDA_DEFAULT
  local colors = walda.colors or PcChrome.WALDA_DEFAULT.colors
  local key = string.format("%d:%d:%d:%d", tonumber(walda.patternId) or 0, tonumber(walda.iconId) or 0,
    tonumber(colors[1]) or 0, tonumber(colors[2]) or 0)
  if PcChrome._friends and PcChrome._friends.key == key then return PcChrome._friends.image end
  local parent = m.friends:match("^(.*)/[^/]+$")
  if not parent then return nil end
  local dir = "data/generated/gba/pokemon/storage/" .. parent .. "/"
  local src = read_bytes("data/generated/gba/pokemon/storage/" .. m.friends)
  local fm = src and load(src, "@friends", "t", {})()
  if not fm then return nil end
  local pat = fm.patterns[tonumber(walda.patternId) or 0] or fm.patterns[0]
  if not pat then return nil end
  local tiles = read_bytes(dir .. pat.tiles) or ""
  local iconName = fm.icons[tonumber(walda.iconId) or 0] or fm.icons[0]
  if not iconName then return nil end
  local icon = read_bytes(dir .. iconName) or ""
  local off = fm.iconTileOffset
  tiles = tiles:sub(1, off) .. icon .. tiles:sub(off + #icon + 1)
  local map = read_bytes(dir .. pat.map) or ""
  local pal = {}
  for i = 0, 31 do pal[i] = pat.palette[i + 1] end
  pal[1], pal[2], pal[17], pal[18] = colors[1], colors[2], colors[1], colors[2]
  local W, H = fm.width * 8, fm.height * 8
  local img = love.image.newImageData(W, H)
  for ty = 0, fm.height - 1 do
    for tx = 0, fm.width - 1 do
      local mi = (ty * fm.width + tx) * 2 + 1
      local e = (map:byte(mi) or 0) + (map:byte(mi + 1) or 0) * 256
      local tile = e % 1024
      local hf, vf = math.floor(e / 1024) % 2 == 1, math.floor(e / 2048) % 2 == 1
      local bank = (math.floor(e / 4096) % 16) - 1
      if bank < 0 then bank = 0 end
      for y = 0, 7 do
        for x = 0, 7 do
          local sx, sy = hf and 7 - x or x, vf and 7 - y or y
          local b = tiles:byte(tile * 32 + sy * 4 + math.floor(sx / 2) + 1) or 0
          local idx = sx % 2 == 0 and b % 16 or math.floor(b / 16)
          if idx ~= 0 then
            local r, g, bb = bgr(pal[bank * 16 + idx])
            img:setPixel(tx * 8 + x, ty * 8 + y, r, g, bb, 1)
          end
        end
      end
    end
  end
  local image = love.graphics.newImage(img)
  image:setFilter("nearest", "nearest")
  PcChrome._friends = { key = key, image = image }
  return image
end

--- Draw authentic tiled scrolling background (BG3).
function PcChrome.drawBackground(frame)
  PcChrome.ensure()
  love.graphics.setColor(1, 1, 1, 1)
  if PcChrome._bgImg then
    local bw, bh = PcChrome._bgImg:getDimensions()
    local offset = math.floor((frame or 0) / 2)
    for bx = -(offset % bw), 240, bw do
      for by = -((-offset) % bh), 160, bh do
        love.graphics.draw(PcChrome._bgImg, bx, by)
      end
    end
  else
    love.graphics.setColor(248/255, 216/255, 208/255, 1)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

--- Draw animated waveforms beside PKMN DATA header
local function waveform_quad(img, frameIdx)
  local quads = PcChrome._waveformQuads
  if not quads then quads = {}; PcChrome._waveformQuads = quads end
  local q = quads[frameIdx + 1]
  if not q then
    local iw, ih = img:getDimensions()
    q = love.graphics.newQuad(0, frameIdx * 8, 16, 8, iw, ih)
    quads[frameIdx + 1] = q
  end
  return q
end

function PcChrome.drawWaveforms(active, frame)
  PcChrome.ensure()
  if not PcChrome._waveformImg then return end

  -- Left waveform: center (8, 9) -> top-left (0, 5)
  -- Right waveform: center (71, 9) -> top-left (63, 5)
  local entry = PcChrome._manifest and PcChrome._manifest.sprites and PcChrome._manifest.sprites.waveform
  local la, ra = active and 1 or 0, active and 3 or 2
  local leftFrameIdx = Presentation.animFrame(entry, la, frame, Presentation.WAVES[la + 1])
  local rightFrameIdx = Presentation.animFrame(entry, ra, frame, Presentation.WAVES[ra + 1])

  local leftQuad = waveform_quad(PcChrome._waveformImg, leftFrameIdx)
  local rightQuad = waveform_quad(PcChrome._waveformImg, rightFrameIdx)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(PcChrome._waveformImg, leftQuad, 0, 5)
  love.graphics.draw(PcChrome._waveformImg, rightQuad, 63, 5)
end

--- Draw the 160×144 ROM wallpaper (BG2) at (80, 16).
function PcChrome.drawWallpaper(wallpaperId, walda, offsetX)
  PcChrome.ensure()
  local count = #PcChrome.wallpaperNames()
  local wpImg
  if tonumber(wallpaperId) == count + 1 and PcChrome.hasFriends() then
    wpImg = PcChrome.friendsWallpaper(walda)
  else
    wallpaperId = math.max(1, math.min(count, tonumber(wallpaperId) or 1))
    wpImg = PcChrome._wallpapers[wallpaperId] or PcChrome._wallpapers[1]
  end
  if wpImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(wpImg, 80 + (offsetX or 0), 16)
  end
end

--- Draw the ROM interface frame (BG1) at (0, 0).
function PcChrome.drawInterfaceFrame()
  PcChrome.ensure()
  if PcChrome._frameImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(PcChrome._frameImg, 0, 0)
  end
end

--- Draw Left TV Monitor & Lower stats card contents.
function PcChrome.drawLeftDataPanel(hoveredMon, frame, mosaic)
  PcChrome.ensure()

  -- Draw Waveforms (animated if hovering mon, idle flatline if not)
  PcChrome.drawWaveforms(hoveredMon ~= nil, frame)

  if not hoveredMon then return end

  -- 1. Front Sprite in TV Screen (X: 10..73, Y: 19..80, W: 64, H: 61)
  -- pokefirered/src/pokemon_storage_system_data.c:1034, :1057 MON_DATA_SPECIES_OR_EGG
  local sp = Pokemon.speciesOrEgg(hoveredMon)
  local sprite = Pokemon.monFrontPic(hoveredMon)
  if sprite and sprite.image then
    love.graphics.setColor(1, 1, 1, 1)
    local sw, sh = sprite.image:getDimensions()
    local rs = PcChrome._game == "ruby" or PcChrome._game == "sapphire"
    local scale = rs and 1 or math.min(54 / sw, 54 / sh)
    local sx = rs and (40 - sw / 2) or (10 + math.floor((64 - sw * scale) / 2))
    local sy = rs and (48 - sh / 2) or (19 + math.floor((61 - sh * scale) / 2))
    local previousShader = love.graphics.getShader()
    if not PcChrome._effect and mosaic and mosaic > 0 then
      if not PcChrome._mosaicShader then PcChrome._mosaicShader = love.graphics.newShader([[
        extern vec2 spriteSize;
        extern number blockSize;
        vec4 effect(vec4 color, Image image, vec2 tc, vec2 sc) {
          vec2 p = floor(tc * spriteSize);
          vec2 samplePixel = floor(p / blockSize) * blockSize;
          return Texel(image, (samplePixel + vec2(0.5)) / spriteSize) * color;
        }
      ]]) end
      PcChrome._mosaicShader:send("spriteSize", {sw, sh})
      PcChrome._mosaicShader:send("blockSize", mosaic + 1)
      love.graphics.setShader(PcChrome._mosaicShader)
    end
    if PcChrome._effect then
      PcChrome.effectLayer("obj", function() love.graphics.draw(sprite.image, sx, sy, 0, scale, scale) end,
        {size = {sw, sh}, block = (mosaic or 0) + 1})
    else love.graphics.draw(sprite.image, sx, sy, 0, scale, scale) end
    love.graphics.setShader(previousShader)
  end

  -- 2. Lower Stats Card Text & Info (X: 0..80, Y: 88..160)
  -- Matches pret FRLG PrintDisplayMonInfo (Window 0: left=0, top=11 / Y=88)
  local isEgg = Pokemon.isEgg(hoveredMon)
  local spName = (not isEgg and sp and Pokemon.name(sp)) or "----"
  local nick = hoveredMon.nickname
  if not nick or nick == "" then
    nick = (hoveredMon.name and hoveredMon.name ~= "" and hoveredMon.name) or spName
  end
  if not nick or nick == "" then
    nick = spName
  end
  local lvl = hoveredMon.level or 5
  local gender = hoveredMon.gender or (hoveredMon.personality and ((hoveredMon.personality % 256 < 127) and "F" or "M"))
  if PcChrome._game == "ruby" or PcChrome._game == "sapphire" then
    local Visuals = require("src.ui.game3.rs.storage_visuals")
    local colors = Visuals.textColors()
    FrlgFont.draw(FrlgFont.truncate(nick, 10), 8, 88, {colors = colors, maxWidth = 72})
    if not isEgg then
      FrlgFont.draw("/" .. spName, 7, 104, {colors = colors, maxWidth = 73})
      FrlgFont.drawGlyph(0x34, 16, 120, {colors = colors})
      local level = tostring(lvl)
      FrlgFont.draw(level, 50 - FrlgFont.measure(level), 120, {colors = colors})
      gender = Pokemon.gender(Pokemon.speciesOf(hoveredMon), hoveredMon.personality)
      local C = require("src.core.game3.constants").of(PcChrome._game)
      if sp == C:require("species", "SPECIES_NIDORAN_M") or sp == C:require("species", "SPECIES_NIDORAN_F") then gender = "U" end
      if gender == "M" or gender == "F" then FrlgFont.draw(gender == "M" and "♂" or "♀", 58, 120, {colors = Visuals.textColors(gender)}) end
      local held = hoveredMon.heldItem or hoveredMon.item
      if held and held > 0 then FrlgFont.draw(ItemsData.displayName(held), 8, 128, {font = "native_4", colors = colors, maxWidth = 72}) end
    end
    love.graphics.setColor(1, 1, 1, 1)
    return
  end
  -- pokefirered/src/pokemon_storage_system_data.c:1091: an egg shows only
  -- gText_EggNickname; the species, gender/level and item lines stay blank.
  if isEgg and PcChrome._game ~= "ruby" and PcChrome._game ~= "sapphire" then
    nick = require("src.core.game3.rom_text").plain("gText_EggNickname")
  end

  -- Line 1: Nickname or Species Name (FONT_NORMAL, Y: 88)
  FrlgFont.draw(FrlgFont.truncate(nick, 10), 6, 88, {
    small = false,
    colors = FrlgFont.COLOR.WHITE
  })

  if not isEgg then
    -- Line 2: /Species Name (FONT_NORMAL, Y: 102)
    FrlgFont.draw("/" .. FrlgFont.truncate(spName, 10), 6, 102, {
      small = false,
      colors = FrlgFont.COLOR.WHITE
    })

    -- Line 3: Gender & Level (FONT_NORMAL, Y: 116)
    -- src/pokemon_storage_system_data.c:1148
    if gender == "M" or gender == "male" then
      FrlgFont.draw("♂", 6, 116, { small = false, colors = FrlgFont.COLOR.MALE })
      FrlgFont.draw("{LV_2}" .. tostring(lvl), 18, 116, { small = false, colors = FrlgFont.COLOR.WHITE })
    elseif gender == "F" or gender == "female" then
      FrlgFont.draw("♀", 6, 116, { small = false, colors = FrlgFont.COLOR.FEMALE })
      FrlgFont.draw("{LV_2}" .. tostring(lvl), 18, 116, { small = false, colors = FrlgFont.COLOR.WHITE })
    else
      FrlgFont.draw("{LV_2}" .. tostring(lvl), 6, 116, { small = false, colors = FrlgFont.COLOR.WHITE })
    end

    -- Line 4: Held Item Name (if holding an item) (FONT_SMALL, Y: 132)
    local held = hoveredMon.heldItem or hoveredMon.item
    if held and held > 0 then
      local heldName = ItemsData.displayName(held)
      if heldName and heldName ~= "" and heldName ~= "NONE" then
        FrlgFont.draw(FrlgFont.truncate(heldName, 10), 6, 132, {
          small = true,
          colors = FrlgFont.COLOR.WHITE
        })
      end
    end
  end

  -- Line 5: 4 Markings ● ■ ▲ ♥ (pret markingComboSprite centered at X: 40, Y: 148)
  local marks = hoveredMon.markings or 0
  local markSyms = { "●", "■", "▲", "♥" }
  for m = 1, 4 do
    local bitMask = math.pow(2, m - 1)
    local hasMark = (type(marks) == "number") and ((marks % (bitMask * 2)) >= bitMask)
    local mx = 23 + (m - 1) * 9
    if hasMark then
      FrlgFont.draw(markSyms[m], mx, 146, {
        small = true,
        colors = { fg = { 1, 1, 1, 1 }, shadow = { 40/255, 48/255, 60/255, 1 } }
      })
    else
      FrlgFont.draw(markSyms[m], mx, 146, {
        small = true,
        colors = { fg = { 72/255, 80/255, 96/255, 0.7 }, shadow = { 40/255, 44/255, 56/255, 0.5 } }
      })
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

--- Draw Top Right Buttons: PARTY POKéMON (X: 80, Y: 0) and CLOSE BOX (X: 168, Y: 0).
function PcChrome.drawTopButtons(activeButton)
  PcChrome.ensure()
  love.graphics.setColor(1, 1, 1, 1)

  if PcChrome._buttonPartyImg then
    love.graphics.draw(PcChrome._buttonPartyImg, 80, 0)
  end

  if PcChrome._buttonCloseImg then
    love.graphics.draw(PcChrome._buttonCloseImg, 168, 0)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

--- Draw Box Title Banner: Left Arrow (88, 22), Box Name Text (centered at X: 160, Y: 20), Right Arrow (224, 22).
function PcChrome.drawBoxHeader(boxName, boxNum, isHovered, opts)
  PcChrome.ensure()
  opts = opts or {}
  local dx = opts.offsetX or 0
  local bounce = isHovered and (math.floor((opts.age or 0) / 4) % 6) or 0

  -- Left Arrow ◀ (X: 88, Y: 22, Frame 0: quad 0, 0, 8, 16)
  if PcChrome._arrowImg and not opts.noArrows then
    local leftQuad = love.graphics.newQuad(0, 0, 8, 16, PcChrome._arrowImg:getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    local x = opts.leftArrow or (88 - bounce)
    if x >= 69 and x <= 243 then love.graphics.draw(PcChrome._arrowImg, leftQuad, x, 20) end
  end

  -- Box Name Text (drawn centered on the ROM wallpaper's capsule)
  -- Default names are stored in English ("BOX 3", see Storage.new); show those
  -- translated and leave the names the player typed alone.
  local num = tonumber(boxNum) or 1
  local nameStr = (boxName == nil or boxName == string.format("BOX %d", num))
    and Strings("BOX %d", num)
    or tostring(boxName)
  local nw = FrlgFont.measure(nameStr)
  local tx = math.floor(160 - nw / 2) + dx
  if not opts.noTitle then PcChrome.effectLayer("title", function()
    FrlgFont.draw(nameStr, tx, 20, {colors = FrlgFont.COLOR.WHITE})
  end) end

  -- Right Arrow ▶ (X: 224, Y: 22, Frame 1: quad 0, 16, 8, 16)
  if PcChrome._arrowImg and not opts.noArrows then
    local rightQuad = love.graphics.newQuad(0, 16, 8, 16, PcChrome._arrowImg:getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    local x = opts.rightArrow or (224 + bounce)
    if x >= 69 and x <= 243 then love.graphics.draw(PcChrome._arrowImg, rightQuad, x, 20) end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

--- Return authentic GBA hand cursor coordinates for party drawer slots (1..6 for mons, 7 for CANCEL).
function PcChrome.getPartyCursorCoords(partyCursor)
  partyCursor = partyCursor or 1
  if partyCursor == 1 then
    return 104, 52
  elseif partyCursor >= 2 and partyCursor <= 6 then
    return 152, (partyCursor - 2) * 24 + 4
  else -- CANCEL button (7)
    return 152, 132
  end
end

--- Draw the authentic Party Drawer overlay (96x160 panel, slot backgrounds, and Pokémon icons).
function PcChrome.drawPartyDrawer(party, partyCursor, hoverFrame, holdingSource, opts)
  PcChrome.ensure()
  opts = opts or {}
  local dy = opts.y or 0
  local function visible(mon) return mon and not (opts.hidden and opts.hidden[mon]) end
  love.graphics.setColor(1, 1, 1, 1)

  -- 1. Base drawer background at (80, 0)
  if PcChrome._partyDrawerBgImg then
    love.graphics.draw(PcChrome._partyDrawerBgImg, 80, dy)
  end

  -- 2. Party Slots 2..6 (X: 136, Y: 8 + (p - 2) * 24)
  party = party or {}
  for p = 2, 6 do
    local isPickedUp = (holdingSource and holdingSource.loc == "party" and holdingSource.slot == p)
    local pMon = (not isPickedUp) and visible(party[p]) and party[p]
    local sx = 136
    local sy = 8 + (p - 2) * 24
    if pMon then
      if PcChrome._partySlotFilledImg then
        love.graphics.draw(PcChrome._partySlotFilledImg, sx, sy + dy)
      end
    else
      if PcChrome._partySlotEmptyImg then
        love.graphics.draw(PcChrome._partySlotEmptyImg, sx, sy + dy)
      end
    end
  end

  -- 3. Party Pokémon Animated Mini-Icons
  -- Slot 1 (Lead): pret Center (104, 64) -> Top-Left (88, 48)
  local isLeadPickedUp = (holdingSource and holdingSource.loc == "party" and holdingSource.slot == 1)
  local leadMon = (not isLeadPickedUp) and visible(party[1]) and party[1]
  if leadMon and not opts.partyIcons then
    local icon = Pokemon.monIcon(leadMon)
    if icon and icon.image then
      local isHovered = (partyCursor == 1)
      local bounce = (isHovered and (hoverFrame % 2 == 1)) and -2 or 0
      local f = (isHovered and (hoverFrame % 2 == 1)) and 1 or 0
      local q = icon.quads and (icon.quads[f] or icon.quads[0])
      if q then
        PcChrome.effectLayer("obj", function() love.graphics.draw(icon.image, q, 88, 48 + bounce + dy) end)
      else
        PcChrome.effectLayer("obj", function() love.graphics.draw(icon.image, 88, 48 + bounce + dy) end)
      end
    end
  end

  -- Slots 2..6: pret Center (152, 16 + (p - 2) * 24) -> Top-Left (136, (p - 2) * 24)
  for p = 2, 6 do
    local isPickedUp = (holdingSource and holdingSource.loc == "party" and holdingSource.slot == p)
    local pMon = (not isPickedUp) and visible(party[p]) and party[p]
    if pMon and not opts.partyIcons then
      local icon = Pokemon.monIcon(pMon)
      if icon and icon.image then
        local isHovered = (partyCursor == p)
        local bounce = (isHovered and (hoverFrame % 2 == 1)) and -2 or 0
        local f = (isHovered and (hoverFrame % 2 == 1)) and 1 or 0
        local q = icon.quads and (icon.quads[f] or icon.quads[0])
        local iy = (p - 2) * 24
        if q then
          PcChrome.effectLayer("obj", function() love.graphics.draw(icon.image, q, 136, iy + bounce + dy) end)
        else
          PcChrome.effectLayer("obj", function() love.graphics.draw(icon.image, 136, iy + bounce + dy) end)
        end
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

--- Draw Hand Cursor with authentic GBA positioning, optional drop shadow, and vertical flip.
function PcChrome.drawHandCursor(x, y, state, showShadow, vFlip, age)
  PcChrome.ensure()
  state = state or "idle"

  -- 1. Draw Oval Drop Shadow (GBA 16x16 sprite centered at x, y + 20)
  -- Only visible when hovering over an empty box slot
  if showShadow and PcChrome._shadowImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(PcChrome._shadowImg, x - 8, y + 12)
  end

  -- 2. Draw Hand Cursor Sprite (GBA 32x32 sprite centered at x, y)
  if PcChrome._cursorImg then
    local entry = PcChrome._manifest and PcChrome._manifest.sprites and PcChrome._manifest.sprites.cursor
    local anim = state == "grab" and 2 or state == "holding" and 3 or state == "moving" and 1 or 0
    local fallback = anim == 0 and Presentation.HAND or {{op = "frame", frame = anim == 1 and 0 or anim, duration = 5}, {op = "end"}}
    local quadY = 32 * Presentation.animFrame(entry, anim, age, fallback)
    local quad = love.graphics.newQuad(0, quadY, 32, 32, PcChrome._cursorImg:getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    local sy = vFlip and -1 or 1
    love.graphics.draw(PcChrome._cursorImg, quad, x, y, 0, 1, sy, 16, 16)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local unpackArgs = table.unpack or unpack
for name, layer in pairs({drawWallpaper = "wallpaper", drawWaveforms = "obj", drawHandCursor = "obj", drawBoxHeader = "obj"}) do
  local original, nativeLayer = PcChrome[name], layer
  PcChrome[name] = function(...)
    if not PcChrome._effect then return original(...) end
    local args, n = {...}, select("#", ...)
    return PcChrome.effectLayer(nativeLayer, function() return original(unpackArgs(args, 1, n)) end)
  end
end

return PcChrome
