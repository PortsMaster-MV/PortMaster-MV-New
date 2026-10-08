-- FRLG field UI chrome (pret graphics/text_window).
-- Dialogue uses menu_message tiles (WindowFunc_DrawDialogueFrame).
-- Menus use std 9-slice (WindowFunc_DrawStdFrameWithCustomTileAndPalette).
-- Assets: sevii/gba/chrome/*_rgba.png (pret PNGs + stdpal_* baked).

local Display = require("src.core.game3.display")

local Chrome = {}

Chrome.DLG_LEFT = 2
Chrome.DLG_TOP = 15
Chrome.DLG_W = 26
Chrome.DLG_H = 4

local T = Display.TILE -- 8

Chrome._dlg = nil -- { image, quads[0..17] }
Chrome._std = nil -- { image, quads[0..8] }
Chrome._sign = nil
Chrome._arrow = nil -- { image, quads[], frameW, frameH, count }
Chrome._logged = false

local PATHS = {
  dlg = {
    { path = "chrome/menu_message_rgba.rgba", w = 48, h = 24 },
    { path = "data/generated/gba/chrome/menu_message_rgba.rgba", w = 48, h = 24 },
  },
  std = {
    { path = "chrome/std_rgba.rgba", w = 24, h = 24 },
    { path = "data/generated/gba/chrome/std_rgba.rgba", w = 24, h = 24 },
  },
  sign = {
    { path = "chrome/signpost_rgba.rgba", w = 40, h = 32 },
    { path = "data/generated/gba/chrome/signpost_rgba.rgba", w = 40, h = 32 },
  },
  textCursor = {
    { path = "chrome/fonts/text_cursor.rgba", w = 16, h = 16 },
    { path = "data/generated/gba/chrome/fonts/text_cursor.rgba", w = 16, h = 16 },
  },
  arrow = {
    { path = "chrome/fonts/down_arrows_fg.rgba", w = 128, h = 16 },
    { path = "data/generated/gba/chrome/fonts/down_arrows_fg.rgba", w = 128, h = 16 },
  },
}

local function log(msg)
  print("[game3/chrome] " .. tostring(msg))
end

local function loadImage(candidates)
  local okC, CacheFs = pcall(require, "src.import.CacheFs")
  for _, item in ipairs(candidates) do
    local path = type(item) == "table" and item.path or item
    local w = type(item) == "table" and item.w or 48
    local h = type(item) == "table" and item.h or 24
    if okC and CacheFs and CacheFs.read then
      local data = CacheFs.read(path)
      if data and type(data) == "string" and #data > 0 then
        if #data == w * h * 4 and love and love.image and love.graphics then
          local okId, id = pcall(love.image.newImageData, w, h, "rgba8", data)
          if okId and id then
            local img = love.graphics.newImage(id)
            if img and img.setFilter then img:setFilter("nearest", "nearest") end
            return img, path
          end
        elseif love and love.filesystem and love.image and love.graphics then
          local okFd, fd = pcall(love.filesystem.newFileData, data, path)
          if okFd and fd then
            local okId, id = pcall(love.image.newImageData, fd)
            if okId and id then
              local img = love.graphics.newImage(id)
              if img and img.setFilter then img:setFilter("nearest", "nearest") end
              return img, path
            end
          end
        end
      end
    end
    if love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
      local ok, img = pcall(love.graphics.newImage, path)
      if ok and img then
        if img.setFilter then img:setFilter("nearest", "nearest") end
        return img, path
      end
    end
  end
  return nil, nil
end

Chrome._syncVersion = nil
Chrome._frames = nil
Chrome._specKey = nil

local function resolveFrames()
  local Profile = package.loaded["src.core.game3.profile"]
  if not Profile then
    local ok, P = pcall(require, "src.core.game3.profile")
    if not ok then return nil, nil end
    Profile = P
  end
  local ok, row = pcall(Profile.forSession)
  local ui = ok and type(row) == "table" and row.ui or nil
  if type(ui) == "table" and type(ui.frames) == "table" then return ui.frames, row.id end
  return nil, nil
end

local function frames()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.session
  local GV = package.loaded["src.core.GameVersion"]
  local v = (type(session) == "table" and session.version) or (GV and GV.current) or ""
  if v == Chrome._syncVersion then return Chrome._frames end
  Chrome._syncVersion = v
  local spec, id = resolveFrames()
  local key = spec and id or "frlg"
  if Chrome._specKey ~= key then
    if Chrome._specKey ~= nil then Chrome.invalidate() end
    Chrome._specKey = key
  end
  Chrome._frames = spec
  return spec
end

Chrome.frames = frames

local function manifest(spec)
  if Chrome._manifest == nil then
    local okC, CacheFs = pcall(require, "src.import.CacheFs")
    local t = okC and spec.manifest and CacheFs.loadActive(spec.manifest) or nil
    Chrome._manifest = type(t) == "table" and t or false
  end
  return Chrome._manifest or nil
end

function Chrome.dialogueWindow()
  local spec = frames()
  local w = spec and spec.dialogueWindow
  if w then return w.left, w.top, w.width, w.height end
  return Chrome.DLG_LEFT, Chrome.DLG_TOP, Chrome.DLG_W, Chrome.DLG_H
end

-- pokefirered/src/text_window_graphics.c:58
function Chrome.userFrameCount()
  local spec = frames()
  return spec and spec.userCount or 10
end

function Chrome.arrowSpec()
  local spec = frames()
  local a = spec and spec.arrow
  if not a then return nil end
  if Chrome._arrowSpec then return Chrome._arrowSpec end
  local m = manifest(spec)
  local info = m and m.fonts and m.fonts[a.manifestKey]
  if spec.nativeLayout == "rs" then info = m and m.downArrow end
  if type(info) ~= "table" then
    error("Chrome: chrome/manifest.lua has no fonts." .. tostring(a.manifestKey), 0)
  end
  Chrome._arrowSpec = {
    path = a.path, w = info.width, h = info.height, frameH = info.frameH,
    yOffsets = info.yOffsets or { 0, 16, 32, 48 }, delay = a.delay, period = a.period, lastPage = a.lastPage,
  }
  return Chrome._arrowSpec
end

local function makeQuads(img, cols, rows)
  local quads = {}
  local iw, ih = img:getDimensions()
  local i = 0
  for ty = 0, rows - 1 do
    for tx = 0, cols - 1 do
      quads[i] = love.graphics.newQuad(tx * 8, ty * 8, 8, 8, iw, ih)
      i = i + 1
    end
  end
  return quads
end

local function ensureDlg()
  if Chrome._dlg then return Chrome._dlg end
  local spec = frames()
  local d = spec and spec.dialogue
  if d then
    local m = manifest(spec)
    local info = m and m.frames and m.frames[d.manifestKey]
    if spec.nativeLayout == "rs" then info = m and m.dialogue end
    if type(info) ~= "table" then
      error("Chrome: chrome/manifest.lua has no frames." .. tostring(d.manifestKey), 0)
    end
    local img, path = loadImage({ { path = d.path, w = info.width, h = info.height } })
    if not img then error("Chrome: " .. tostring(d.path) .. " is not in the cache", 0) end
    Chrome._dlg = { image = img, quads = makeQuads(img, info.tilesW or info.width / 8, info.tilesH or info.height / 8), path = path, layout = d.layout }
    return Chrome._dlg
  end
  local img, path = loadImage(PATHS.dlg)
  if not img then
    if not Chrome._logged then
      log("menu_message atlas missing — dialogue frame fallback")
      Chrome._logged = true
    end
    return nil
  end
  Chrome._dlg = { image = img, quads = makeQuads(img, 6, 3), path = path }
  log("dialogue chrome ready " .. tostring(path))
  return Chrome._dlg
end

local function ensureStd()
  if Chrome._std then return Chrome._std end
  local img, path = loadImage(PATHS.std)
  if not img then return nil end
  Chrome._std = { image = img, quads = makeQuads(img, 3, 3), path = path }
  return Chrome._std
end

local function blitTile(atlas, tile, px, py, vflip)
  local q = atlas.quads[tile]
  if not q then return end
  if vflip then
    love.graphics.draw(atlas.image, q, px, py + 8, 0, 1, -1)
  else
    love.graphics.draw(atlas.image, q, px, py)
  end
end

local function fillRect(px, py, pw, ph, r, g, b, a)
  love.graphics.setColor(r, g, b, a or 1)
  love.graphics.rectangle("fill", px, py, pw, ph)
  love.graphics.setColor(1, 1, 1, 1)
end

--- pret WindowFunc_DrawDialogueFrame for the standard field textbox.
-- Content window: (2,15) 26×4. Outer chrome occupies rows 14–19, cols 0–29.
-- pokeemerald/src/menu.c:319
local function drawMessageBox(atlas, L, Top, W, H)
  love.graphics.setColor(1, 1, 1, 1)
  local function cell(tile, tx, ty, vflip)
    blitTile(atlas, tile, tx * T, ty * T, vflip)
  end
  local function fill(tile, tx, ty, w, h, vflip)
    for y = ty, ty + h - 1 do
      for x = tx, tx + w - 1 do cell(tile, x, y, vflip) end
    end
  end
  fill(1, L - 2, Top - 1, 1, 1)
  fill(3, L - 1, Top - 1, 1, 1)
  fill(4, L, Top - 1, W - 1, 1)
  fill(5, L + W - 1, Top - 1, 1, 1)
  fill(6, L + W, Top - 1, 1, 1)
  fill(7, L - 2, Top, 1, H)
  fill(9, L - 1, Top, 1, H)
  fill(10, L + W, Top, 1, H)
  fill(1, L - 2, Top + H, 1, 1, true)
  fill(3, L - 1, Top + H, 1, 1, true)
  fill(4, L, Top + H, W - 1, 1, true)
  fill(5, L + W - 1, Top + H, 1, 1, true)
  fill(6, L + W, Top + H, 1, 1, true)
  local c = Chrome.windowFillColor()
  fillRect(L * T, Top * T, W * T, H * T, c[1], c[2], c[3], 1)
end

function Chrome.windowFillColor()
  local okF, FrlgFont = pcall(require, "src.ui.game3.frlg_font")
  if okF and FrlgFont.face then FrlgFont.face() end
  local spec = frames()
  local c = okF and FrlgFont.STDPAL and FrlgFont.STDPAL[spec and spec.fillColor or 1]
  if type(c) == "table" then return c end
  return { 1, 1, 1, 1 }
end

function Chrome.dialogueFrame()
  local L, Top, W, H = Chrome.DLG_LEFT, Chrome.DLG_TOP, Chrome.DLG_W, Chrome.DLG_H
  local atlas = ensureDlg()
  if atlas and atlas.layout == "rs_dialogue" then
    -- pokeruby/src/text_window.c:92
    local rows = {
      {1,3,4,4,5,6,9}, {11,9,9,9,9,0x040B,9}, {7,9,9,9,9,10,9},
      {0x080B,9,9,9,9,0x0C0B,9}, {0x0801,0x0803,0x0804,0x0804,0x0805,0x0806,9},
    }
    love.graphics.setColor(1,1,1,1)
    for y = 0, 5 do for x = 0, 31 do
      local row = y >= 4 and y - 4 + 3 or y > 1 and 2 or y
      local col = x >= 28 and x - 28 + 4 or x > 2 and 3 or x
      local entry = (rows[row + 1] or {})[col + 1] or 9
      local tile, sx, sy = entry % 1024, math.floor(entry / 1024) % 2 == 1 and -1 or 1, math.floor(entry / 2048) % 2 == 1 and -1 or 1
      love.graphics.draw(atlas.image, atlas.quads[tile], x * T + (sx < 0 and T or 0), (14+y) * T + (sy < 0 and T or 0), 0, sx, sy)
    end end
    return
  end
  if atlas and atlas.layout == "message_box" then
    L, Top, W, H = Chrome.dialogueWindow()
    return drawMessageBox(atlas, L, Top, W, H)
  end
  if not atlas then
    -- Soft fallback if assets missing (should not happen in-repo).
    fillRect(0, 14 * T, 30 * T, 6 * T, 0.19, 0.32, 0.80, 1)
    fillRect(2, 14 * T + 2, 30 * T - 4, 6 * T - 4, 1, 1, 1, 1)
    return
  end

  love.graphics.setColor(1, 1, 1, 1)
  local function cell(tile, tx, ty, vflip)
    blitTile(atlas, tile, tx * T, ty * T, vflip)
  end
  local function row(tile, tx, ty, count, vflip)
    for i = 0, count - 1 do
      cell(tile, tx + i, ty, vflip)
    end
  end

  -- Top edge (T-1)
  cell(0, L - 2, Top - 1)
  cell(1, L - 1, Top - 1)
  row(2, L, Top - 1, W)
  cell(3, L + W, Top - 1)
  cell(4, L + W + 1, Top - 1)
  -- Sides row T+0
  cell(5, L - 2, Top)
  cell(6, L - 1, Top)
  cell(8, L + W, Top)
  cell(9, L + W + 1, Top)
  -- Sides row T+1
  cell(10, L - 2, Top + 1)
  cell(11, L - 1, Top + 1)
  cell(12, L + W, Top + 1)
  cell(13, L + W + 1, Top + 1)
  -- Sides row T+2 (V-flip of T+1)
  cell(10, L - 2, Top + 2, true)
  cell(11, L - 1, Top + 2, true)
  cell(12, L + W, Top + 2, true)
  cell(13, L + W + 1, Top + 2, true)
  -- Sides row T+3 (V-flip of T+0)
  cell(5, L - 2, Top + 3, true)
  cell(6, L - 1, Top + 3, true)
  cell(8, L + W, Top + 3, true)
  cell(9, L + W + 1, Top + 3, true)
  -- Bottom edge (T+4 = V-flip of top)
  cell(0, L - 2, Top + 4, true)
  cell(1, L - 1, Top + 4, true)
  row(2, L, Top + 4, W, true)
  cell(3, L + W, Top + 4, true)
  cell(4, L + W + 1, Top + 4, true)

  -- Interior: PIXEL_FILL(1) white paper (stdpal_0 index 1).
  fillRect(L * T, Top * T, W * T, H * T, 1, 1, 1, 1)
end

local function ensureSign()
  if Chrome._sign then return Chrome._sign end
  local img, path = loadImage(PATHS.sign)
  if not img then return nil end
  -- signpost atlas is 6×3 like menu_message (pret text_window/signpost.png).
  Chrome._sign = { image = img, quads = makeQuads(img, 6, 3), path = path }
  return Chrome._sign
end

local function ensureArrow()
  if Chrome._arrow then return Chrome._arrow end
  local img, path = loadImage(PATHS.arrow)
  if not img then return nil end
  local iw, ih = img:getDimensions()
  -- pret down_arrows: 8 frames in a row (typically 8×8 each).
  local count = 8
  local fw = math.floor(iw / count)
  if fw < 1 then fw = iw end
  local fh = ih
  local quads = {}
  for i = 0, count - 1 do
    quads[i] = love.graphics.newQuad(i * fw, 0, fw, fh, iw, ih)
  end
  Chrome._arrow = { image = img, quads = quads, frameW = fw, frameH = fh, count = count, path = path }
  return Chrome._arrow
end

--- pret WindowFunc_DrawSignpostFrame — same geometry as dialogue, signpost tiles.
function Chrome.signFrame()
  local spec = frames()
  if spec and spec.sign == false then return Chrome.dialogueFrame() end
  local L, Top, W, H = Chrome.DLG_LEFT, Chrome.DLG_TOP, Chrome.DLG_W, Chrome.DLG_H
  local atlas = ensureSign()
  if not atlas then
    -- Fall back to dialogue chrome if signpost missing.
    return Chrome.dialogueFrame()
  end

  love.graphics.setColor(1, 1, 1, 1)
  local function cell(tile, tx, ty, vflip)
    blitTile(atlas, tile, tx * T, ty * T, vflip)
  end
  local function row(tile, tx, ty, count, vflip)
    for i = 0, count - 1 do
      cell(tile, tx + i, ty, vflip)
    end
  end

  cell(0, L - 2, Top - 1)
  cell(1, L - 1, Top - 1)
  row(2, L, Top - 1, W)
  cell(3, L + W, Top - 1)
  cell(4, L + W + 1, Top - 1)
  cell(5, L - 2, Top)
  cell(6, L - 1, Top)
  cell(8, L + W, Top)
  cell(9, L + W + 1, Top)
  cell(10, L - 2, Top + 1)
  cell(11, L - 1, Top + 1)
  cell(12, L + W, Top + 1)
  cell(13, L + W + 1, Top + 1)
  cell(10, L - 2, Top + 2, true)
  cell(11, L - 1, Top + 2, true)
  cell(12, L + W, Top + 2, true)
  cell(13, L + W + 1, Top + 2, true)
  cell(5, L - 2, Top + 3, true)
  cell(6, L - 1, Top + 3, true)
  cell(8, L + W, Top + 3, true)
  cell(9, L + W + 1, Top + 3, true)
  cell(0, L - 2, Top + 4, true)
  cell(1, L - 1, Top + 4, true)
  row(2, L, Top + 4, W, true)
  cell(3, L + W, Top + 4, true)
  cell(4, L + W + 1, Top + 4, true)

  -- Sign interior is parchment / light tan (stdpal_1-ish).
  fillRect(L * T, Top * T, W * T, H * T, 0.97, 0.94, 0.82, 1)
end

-- pokefirered/src/text.c:1313
function Chrome.textCursorImage()
  if Chrome._textCursor == nil then
    Chrome._textCursor = loadImage(PATHS.textCursor) or false
  end
  return Chrome._textCursor or nil
end

--- Bounce prompt arrow (pret down_arrows). px,py = top-left of glyph.
-- pokeemerald/src/text.c:819
local function drawRseArrow(a, px, py, frame)
  if Chrome._rseArrow == nil then
    Chrome._rseArrow = loadImage({ { path = a.path, w = a.w, h = a.h } }) or false
    if not Chrome._rseArrow then error("Chrome: " .. tostring(a.path) .. " is not in the cache", 0) end
  end
  local img = Chrome._rseArrow
  local offs = a.yOffsets
  local off = offs[(math.floor(tonumber(frame) or 0) % #offs) + 1]
  Chrome._rseArrowQuads = Chrome._rseArrowQuads or {}
  local q = Chrome._rseArrowQuads[off]
  if not q then
    local iw, ih = img:getDimensions()
    q = love.graphics.newQuad(0, off, a.w, a.frameH, iw, ih)
    Chrome._rseArrowQuads[off] = q
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, q, px, py)
end

function Chrome.promptArrow(px, py, frame)
  local rse = Chrome.arrowSpec()
  if rse then return drawRseArrow(rse, px, py, frame) end
  local atlas = ensureArrow()
  if not atlas then
    love.graphics.setColor(230 / 255, 8 / 255, 8 / 255, 1)
    love.graphics.polygon("fill",
      px, py + 2,
      px + 8, py + 2,
      px + 4, py + 7)
    love.graphics.setColor(1, 1, 1, 1)
    return
  end
  frame = tonumber(frame) or 0
  frame = frame % atlas.count
  local q = atlas.quads[frame]
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(atlas.image, q, px, py)
end

Chrome._user = {}

local function ensureUser(frameType)
  local n = tonumber(frameType) or 0
  if n < 0 or n >= Chrome.userFrameCount() or n ~= math.floor(n) then n = 0 end -- pokefirered/src/text_window_graphics.c:58
  local cached = Chrome._user[n]
  if cached ~= nil then return cached or nil end
  local spec = frames()
  local img, path
  if spec and spec.user then
    img, path = loadImage({ { path = string.format(spec.user, n), w = 24, h = 24 } })
    if not img then error("Chrome: " .. string.format(spec.user, n) .. " is not in the cache", 0) end
  else
    local rel = "chrome/user_frame_" .. n .. ".rgba"
    img, path = loadImage({
      { path = rel, w = 24, h = 24 },
      { path = "data/generated/gba/" .. rel, w = 24, h = 24 },
    })
  end
  Chrome._user[n] = img and { image = img, quads = makeQuads(img, 3, 3), path = path } or false
  return Chrome._user[n] or nil
end

local drawNineSlice

function Chrome.userFrame(frameType, tx, ty, tw, th)
  local atlas = ensureUser(frameType)
  if not atlas then return Chrome.stdFrame(tx, ty, tw, th) end
  drawNineSlice(atlas, tx, ty, tw, th)
end

Chrome._frameType = 0

function Chrome.setFrameType(n)
  n = tonumber(n) or 0
  if n < 0 then n = 0 end
  if n ~= Chrome._frameType then
    Chrome._frameType = n
    if Chrome.invalidate then Chrome.invalidate() end
  end
  return Chrome._frameType
end

--- pret std 9-slice around content (tx,ty,tw,th) in tiles.
function Chrome.stdFrame(tx, ty, tw, th)
  local ft = Chrome._frameType or 0
  local user = ensureUser(ft)
  if user then return drawNineSlice(user, tx, ty, tw, th) end
  local atlas = ensureStd()
  if atlas then return drawNineSlice(atlas, tx, ty, tw, th) end
  fillRect(tx * T - 8, ty * T - 8, (tw + 2) * T, (th + 2) * T, 98 / 255, 115 / 255, 123 / 255, 1)
  fillRect(tx * T - 6, ty * T - 6, (tw + 2) * T - 4, (th + 2) * T - 4, 205 / 255, 213 / 255, 213 / 255, 1)
  fillRect(tx * T, ty * T, tw * T, th * T, 1, 1, 1, 1)
end

-- src/text_window.c:35
function Chrome.fixedStdFrame(tx, ty, tw, th)
  local spec = frames()
  if spec and spec.std == "user" then return Chrome.stdFrame(tx, ty, tw, th) end
  local atlas = ensureStd()
  if atlas then return drawNineSlice(atlas, tx, ty, tw, th) end
  fillRect(tx * T - 8, ty * T - 8, (tw + 2) * T, (th + 2) * T, 98 / 255, 115 / 255, 123 / 255, 1)
  fillRect(tx * T - 6, ty * T - 6, (tw + 2) * T - 4, (th + 2) * T - 4, 205 / 255, 213 / 255, 213 / 255, 1)
  fillRect(tx * T, ty * T, tw * T, th * T, 1, 1, 1, 1)
end

drawNineSlice = function(atlas, tx, ty, tw, th)
  love.graphics.setColor(1, 1, 1, 1)
  local L, Top, W, H = tx, ty, tw, th
  local function cell(tile, cx, cy)
    blitTile(atlas, tile, cx * T, cy * T, false)
  end
  local function hspan(tile, cx, cy, n)
    for i = 0, n - 1 do cell(tile, cx + i, cy) end
  end
  local function vspan(tile, cx, cy, n)
    for i = 0, n - 1 do cell(tile, cx, cy + i) end
  end

  fillRect(L * T, Top * T, W * T, H * T, 1, 1, 1, 1)

  cell(0, L - 1, Top - 1)
  hspan(1, L, Top - 1, W)
  cell(2, L + W, Top - 1)
  vspan(3, L - 1, Top, H)
  vspan(5, L + W, Top, H)
  cell(6, L - 1, Top + H)
  hspan(7, L, Top + H, W)
  cell(8, L + W, Top + H)
end

--- pret MapNamePopupCreateWindow 9-slice banner at pixel coordinates (px, py).
-- Content size is (widthTiles * 8) wide by 16 high.
-- Outer border spans: x in [px, px + (widthTiles + 2)*8], y in [py, py + 24].
function Chrome.mapPopupFrame(px, py, widthTiles)
  widthTiles = tonumber(widthTiles) or 14
  local contentW = widthTiles * 8
  local atlas = ensureStd()

  if atlas then
    love.graphics.setColor(1, 1, 1, 1)
    local function cell(tile, cx, cy, vflip)
      blitTile(atlas, tile, cx, cy, vflip)
    end
    local function hspan(tile, cx, cy, n, vflip)
      for i = 0, n - 1 do cell(tile, cx + i * 8, cy, vflip) end
    end

    -- 1. Content background: pure white PIXEL_FILL(1)
    fillRect(px + 8, py + 4, contentW, 16, 1, 1, 1, 1)

    -- 2. Top edge (row 0, y = py) — mirrored from bottom edge (tiles 6, 7, 8 vflipped)
    cell(6, px, py, true)
    hspan(7, px + 8, py, widthTiles, true)
    cell(8, px + 8 + contentW, py, true)

    -- 3. Left & Right borders (height = 1 tile / 8px middle row, y = py + 8)
    cell(3, px, py + 8)
    cell(5, px + 8 + contentW, py + 8)

    -- 4. Bottom edge (row 2, y = py + 16)
    cell(6, px, py + 16, false)
    hspan(7, px + 8, py + 16, widthTiles, false)
    cell(8, px + 8 + contentW, py + 16, false)
    return
  end

  -- Fallback if atlas missing
  fillRect(px, py, contentW + 16, 24, 98 / 255, 115 / 255, 123 / 255, 1)
  fillRect(px + 2, py + 2, contentW + 12, 20, 205 / 255, 213 / 255, 213 / 255, 1)
  fillRect(px + 8, py + 4, contentW, 16, 1, 1, 1, 1)
end

function Chrome.invalidate()
  Chrome._dlg = nil
  Chrome._std = nil
  Chrome._sign = nil
  Chrome._arrow = nil
  Chrome._textCursor = nil
  Chrome._user = {}
  Chrome._rseArrow = nil
  Chrome._rseArrowQuads = nil
  Chrome._arrowSpec = nil
  Chrome._manifest = nil
  Chrome._logged = false
end

return Chrome
