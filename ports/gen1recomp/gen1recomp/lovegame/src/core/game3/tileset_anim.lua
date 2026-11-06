-- Pret General tileset animations (water / sand edge / flower) for native FieldView.

local Extract = require("src.import.gba.extract_island1")
local Versions = require("src.import.gba.versions")

local TilesetAnim = {}
local EMPTY = {}

TilesetAnim._cache = nil
TilesetAnim._pairs = {}
TilesetAnim._visible = {}
TilesetAnim.counter = 0
TilesetAnim.counterMax = 640
TilesetAnim._waterFrame = 0
TilesetAnim._sandFrame = 0
TilesetAnim._flowerFrame = 0
TilesetAnim._enabled = true

local MID_RGBA = 16 * 16 * 4 -- 1024

local nativeMod
local function NativeTileset()
  nativeMod = nativeMod or require("src.core.game3.tileset_native")
  return nativeMod
end

local function log(msg)
  print("[game3/anim] " .. tostring(msg))
end

function TilesetAnim.install(cache)
  TilesetAnim._cache = cache
  TilesetAnim.invalidate()
end

function TilesetAnim.invalidate()
  TilesetAnim._manifests = nil
  TilesetAnim._pairs = {}
  TilesetAnim._visible = {}
  TilesetAnim.counter = 0
  TilesetAnim._waterFrame = 0
  TilesetAnim._sandFrame = 0
  TilesetAnim._flowerFrame = 0
  TilesetAnim._rse = nil
end

local function native_root()
  return (Extract.CACHE_ROOT or "data/generated/gba") .. "/native/"
end

local function read_manifest(cache, pair)
  local memo = TilesetAnim._manifests
  if not memo then
    memo = {}
    TilesetAnim._manifests = memo
  end
  local hit = memo[pair]
  if hit ~= nil then return hit or nil end
  local src = cache:read(native_root() .. pair .. "/anim_manifest.lua")
  local chunk = src and load(src, "@anim_manifest.lua", "t", {})
  local man = chunk and chunk() or nil
  memo[pair] = man or false
  return man
end

local function rse_luts(cache, pair)
  local blob = cache:read(native_root() .. pair .. "/palettes.bin")
  local rgb = blob and require("src.core.game3.palette").load(blob)
  if not rgb then return nil end
  local under, over = {}, {}
  for byte = 0, 255 do
    local pal = rgb[math.floor(byte / 16) % 16] or rgb[0]
    local c = pal and pal[byte % 16] or { 0, 0, 0 }
    under[byte] = string.char(c[1] or 0, c[2] or 0, c[3] or 0, 255)
    over[byte] = byte == 0 and string.char(0, 0, 0, 0) or under[byte]
  end
  return under, over
end

local function rse_bank(cache, pair, row)
  local bank = { row = row, frame = nil }
  if row.kind == "palette" then
    local blob = row.file and cache:read(native_root() .. pair .. "/" .. row.file)
    if not blob then return nil end
    bank.palettes = {}
    for f = 0, math.floor(#blob / 32) - 1 do
      local list = {}
      for c = 0, 15 do
        local o = f * 32 + c * 2 + 1
        list[c + 1] = blob:byte(o) + blob:byte(o + 1) * 256
      end
      bank.palettes[f] = list
    end
    return bank
  end
  bank.under = row.file and #(row.mids or {}) > 0 and cache:read(native_root() .. pair .. "/" .. row.file) or nil
  bank.over = row.overFile and #(row.overMids or {}) > 0
    and cache:read(native_root() .. pair .. "/" .. row.overFile) or nil
  bank.pieces = {}
  return bank
end

local function rse_entry(cache, pair, atlas, man)
  local under, over = rse_luts(cache, pair)
  if not under then return false end
  local entry = { rse = true, atlas = atlas, man = man, lut = under, lutOver = over, banks = {} }
  for i, row in ipairs(man.banks or {}) do
    entry.banks[i] = rse_bank(cache, pair, row) or false
  end
  return entry
end

-- pokeemerald/src/tileset_anims.c:991
function TilesetAnim.rseFrame(row, timer)
  local t = math.floor(timer / row.period)
  local frames = row.frames or 1
  if frames < 1 then return nil end
  if row.fn == "slot" then
    return ((t - (row.slot or 0)) % 65536) % frames
  elseif row.fn == "mauville" then
    local d = (t - (row.slot or 0)) % 65536
    local a, b = row.framesA or frames, row.framesB or 1
    if d < a then return d end
    return a + d % b
  end
  return t % frames
end

local function rse_piece(entry, bank, blob, lut, frame, k, nMids, over)
  local keys
  if over then keys = bank.overKeys else keys = bank.underKeys end
  if not keys then
    keys = {}
    if over then bank.overKeys = keys else bank.underKeys = keys end
  end
  local fk = keys[frame]
  if not fk then
    fk = {}
    keys[frame] = fk
  end
  local key = fk[k]
  if not key then
    key = (over and "o" or "u") .. frame * 4096 + k
    fk[k] = key
  end
  local piece = bank.pieces[key]
  if piece ~= nil then return piece end
  local base = (frame * nMids + (k - 1)) * 256
  if #blob < base + 256 then
    bank.pieces[key] = false
    return false
  end
  local px = {}
  for i = 1, 256 do px[i] = lut[blob:byte(base + i)] end
  local ok, data = pcall(love.image.newImageData, 16, 16, "rgba8", table.concat(px))
  piece = ok and data or false
  bank.pieces[key] = piece
  return piece
end

local QUAD_XY = { [0] = { 0, 0 }, { 8, 0 }, { 0, 8 }, { 8, 8 } }

local function rse_paste(entry, bank, blob, mids, quads, frame, imageData, lut, over)
  if not (blob and imageData and love and love.image) then return false end
  local ts = entry.atlas
  local cols = ts.cols or 16
  local n = #mids
  local changed = false
  for k, mid in ipairs(mids) do
    local slot = ts.midToSlot[mid]
    if slot then
      local piece = rse_piece(entry, bank, blob, lut, frame, k, n, over)
      if piece then
        local ax, ay = (slot % cols) * 16, math.floor(slot / cols) * 16
        local mask = quads and quads[k] or 15
        NativeTileset().markDirty(ts, over, slot)
        if mask == 15 then
          imageData:paste(piece, ax, ay, 0, 0, 16, 16)
        else
          for q = 0, 3 do
            if math.floor(mask / 2 ^ q) % 2 == 1 then
              local o = QUAD_XY[q]
              imageData:paste(piece, ax + o[1], ay + o[2], o[1], o[2], 8, 8)
            end
          end
        end
        changed = true
      end
    end
  end
  return changed
end

-- pokeemerald/src/tileset_anims.c:1168
local function rse_apply(entry, bank, frame, dirty)
  if bank.frame == frame then return end
  bank.frame = frame
  local row, ts = bank.row, entry.atlas
  if row.kind == "palette" then
    local pal = bank.palettes[frame]
    if pal then
      require("src.core.game3.tileset_native").setSlotPalette(ts, row.paletteSlot, pal)
    end
    return
  end
  if rse_paste(entry, bank, bank.under, row.mids or EMPTY, row.quads, frame, ts.imageData, entry.lut, false) then
    dirty.under = true
  end
  if rse_paste(entry, bank, bank.over, row.overMids or EMPTY, row.overQuads, frame, ts.overImageData, entry.lutOver, true) then
    dirty.over = true
  end
end

local function rse_counters(man)
  local c = man and man.counters or {}
  return c.primary or {}, c.secondary or {}
end

-- pokeemerald/src/tileset_anims.c:574
function TilesetAnim.enterMap(pair, seamless)
  local cache = TilesetAnim._cache
  if not cache or not pair then return false end
  local man = read_manifest(cache, pair)
  if not man or man.family ~= "rse" then return false end
  local st = TilesetAnim._rse or {}
  TilesetAnim._rse = st
  local p, s = rse_counters(man)
  if not seamless then
    st.primary = 0
    st.primaryMax = tonumber(p.max) or 0
  end
  st.primary = st.primary or 0
  st.primaryMax = st.primaryMax or 0
  -- pokeemerald/src/tileset_anims.c:609
  st.secondary = (s.start == "primary") and st.primary or 0
  st.secondaryMax = tonumber(s.max) or 0
  if s.max == "primary" then st.secondaryMax = st.primaryMax end
  st.pair = pair
  return true
end

local rseDirty = {}

-- pokeemerald/src/tileset_anims.c:586
function TilesetAnim.stepRse()
  local st = TilesetAnim._rse
  if not st then return end
  st.primary = st.primary + 1
  if st.primary >= st.primaryMax then st.primary = 0 end
  st.secondary = st.secondary + 1
  if st.secondary >= st.secondaryMax then st.secondary = 0 end
  for pair in pairs(TilesetAnim._visible) do
    local entry = TilesetAnim._pairs[pair]
    if entry and entry.rse then
      local dirty = rseDirty
      dirty.under, dirty.over = nil, nil
      for _, bank in ipairs(entry.banks) do
        if bank then
          local row = bank.row
          local timer = (row.counter == "secondary") and st.secondary or st.primary
          if row.period and row.period > 0 and timer % row.period == (row.phase or 0) then
            local frame = TilesetAnim.rseFrame(row, timer)
            if frame then rse_apply(entry, bank, frame, dirty) end
          end
        end
      end
      local ts = entry.atlas
      if dirty.under or dirty.over then
        NativeTileset().flush(ts, dirty.under, dirty.over)
      end
    end
  end
end

local function load_bank(cache, pair, kind, info)
  if not info or not info.mids or #info.mids < 1 then return nil end
  local rgba = cache:read(
    (Extract.CACHE_ROOT or "data/generated/gba") .. "/native/" .. pair .. "/anim_" .. kind .. ".rgba")
  if not rgba then return nil end
  local nMids = #info.mids
  local nFrames = info.frames or 0
  local need = nMids * nFrames * MID_RGBA
  if #rgba < need then
    log("short anim bank " .. kind .. " for " .. pair)
    return nil
  end
  local midIndex = {}
  for i, mid in ipairs(info.mids) do
    midIndex[mid] = i - 1 -- 0-based
  end
  return {
    mids = info.mids,
    frames = nFrames,
    rgba = rgba,
    midIndex = midIndex,
  }
end

local get_frame_piece

local function prewarm(pair, entry)
  local Warm = require("src.core.game3.warm")
  Warm.add("anim:" .. pair, function()
    if TilesetAnim._pairs[pair] ~= entry then return end
    NativeTileset().ensureAlt(entry.atlas)
    if entry.rse then
      for _, bank in ipairs(entry.banks) do
        local row = bank and bank.row
        if row and row.kind == "palette" then
          if row.paletteSlot then NativeTileset().prepareSlot(entry.atlas, tonumber(row.paletteSlot) or 0) end
        elseif row then
          local frames = tonumber(row.frames) or 0
          for frame = 0, frames - 1 do
            local n, on = #(row.mids or EMPTY), #(row.overMids or EMPTY)
            for k = 1, n do
              if bank.under then rse_piece(entry, bank, bank.under, entry.lut, frame, k, n, false) end
              if k % 4 == 0 then Warm.yield() end
            end
            for k = 1, on do
              if bank.over then rse_piece(entry, bank, bank.over, entry.lutOver, frame, k, on, true) end
              if k % 4 == 0 then Warm.yield() end
            end
            Warm.yield()
          end
        end
      end
    else
      for _, bank in pairs(entry.banks) do
        local nMids = #bank.mids
        for frame = 0, bank.frames - 1 do
          for mi = 1, nMids do
            get_frame_piece(bank, frame, mi, (frame * nMids + (mi - 1)) * MID_RGBA)
            if mi % 8 == 0 then Warm.yield() end
          end
          Warm.yield()
        end
      end
    end
  end, 3)
end

-- pokefirered/src/tileset_anims.c:223
function TilesetAnim.bindPair(pair, atlas, prepared)
  if not Versions.NATIVE_RENDER or Versions.TILESET_ANIM == false then
    return false
  end
  local cache = prepared and { read = function(_, rel) return prepared[rel] end } or TilesetAnim._cache
  if not cache or not pair or not atlas then return false end
  local entry = TilesetAnim._pairs[pair]
  if entry == false then return false end
  if not entry then
    local man = read_manifest(cache, pair)
    if not man then
      TilesetAnim._pairs[pair] = false
      return false
    end
    if man.family == "rse" then
      entry = rse_entry(cache, pair, atlas, man)
      TilesetAnim._pairs[pair] = entry
      if not entry then return false end
      prewarm(pair, entry)
      if not TilesetAnim._rse then TilesetAnim.enterMap(pair, false) end
      TilesetAnim._visible[pair] = true
      return true
    end
    entry = { atlas = atlas, frames = {}, banks = {
      water = load_bank(cache, pair, "water", man.water),
      sand = load_bank(cache, pair, "sand", man.sand),
      flower = load_bank(cache, pair, "flower", man.flower),
    } }
    TilesetAnim._pairs[pair] = entry
    prewarm(pair, entry)
  end
  TilesetAnim._visible[pair] = true
  if entry.rse then return true end
  local dirty = false
  if TilesetAnim._applyKind(entry, "water", TilesetAnim._waterFrame, true) then dirty = true end
  if TilesetAnim._applyKind(entry, "sand", TilesetAnim._sandFrame, true) then dirty = true end
  if TilesetAnim._applyKind(entry, "flower", TilesetAnim._flowerFrame, true) then dirty = true end
  -- Initial/catch-up preparation uploads once after all CPU patches. This
  -- also keeps a warming pair's final step within one texture submission.
  if dirty then NativeTileset().flush(atlas, true, false) end
  return true
end

function TilesetAnim.setVisiblePairs(visible)
  local set = TilesetAnim._visible
  for pair in pairs(set) do
    if not visible[pair] then set[pair] = nil end
  end
  for pair in pairs(visible) do
    if not set[pair] then
      set[pair] = true
      -- a General atlas coming back into view catches up before it is drawn
      local entry = TilesetAnim._pairs[pair]
      if entry and not entry.rse then
        TilesetAnim._applyKind(entry, "water", TilesetAnim._waterFrame)
        TilesetAnim._applyKind(entry, "sand", TilesetAnim._sandFrame)
        TilesetAnim._applyKind(entry, "flower", TilesetAnim._flowerFrame)
      end
    end
  end
end

function get_frame_piece(bank, frame, mi, srcOff)
  if not (love and love.image and love.image.newImageData) then return nil end
  local pieces = bank.pieces
  if not pieces then
    pieces = {}
    bank.pieces = pieces
  end
  local pKey = frame * 1000 + mi
  local piece = pieces[pKey]
  if piece then return piece end
  local ok, imgData = pcall(love.image.newImageData, 16, 16, "rgba8",
    bank.rgba:sub(srcOff + 1, srcOff + MID_RGBA))
  if ok and imgData then
    pieces[pKey] = imgData
    return imgData
  end
  return nil
end

function TilesetAnim._applyKind(entry, kind, frame, deferUpload)
  local bank = entry.banks[kind]
  if not bank or bank.frames < 1 then return end
  frame = frame % bank.frames
  if entry.frames[kind] == frame then return end
  local ts = entry.atlas
  if not ts or not ts.imageData then return end
  entry.frames[kind] = frame

  local nMids = #bank.mids
  local cols = ts.cols or 16
  local image = ts.image
  local partial = image ~= nil and image.replacePixels ~= nil
  for mi, mid in ipairs(bank.mids) do
    local slot = ts.midToSlot[mid]
    if slot then
      local srcOff = (frame * nMids + (mi - 1)) * MID_RGBA
      local ax = (slot % cols) * 16
      local ay = math.floor(slot / cols) * 16
      local piece = get_frame_piece(bank, frame, mi, srcOff)
      NativeTileset().markDirty(ts, false, slot)
      local pasted = false
      if piece and ts.imageData.paste then
        ts.imageData:paste(piece, ax, ay)
        pasted = true
      end
      if not pasted then
        local frameRgba = bank.rgba:sub(srcOff + 1, srcOff + MID_RGBA)
        local i = 1
        for y = 0, 15 do
          for x = 0, 15 do
            local r = (frameRgba:byte(i) or 0) / 255
            local g = (frameRgba:byte(i + 1) or 0) / 255
            local b = (frameRgba:byte(i + 2) or 0) / 255
            local a = (frameRgba:byte(i + 3) or 255) / 255
            ts.imageData:setPixel(ax + x, ay + y, r, g, b, a)
            i = i + 4
          end
        end
      end
    end
  end
  if deferUpload then return true end
  if partial then
    NativeTileset().flush(ts, true, false)
  elseif ts.image and love and love.graphics then
    ts.image = love.graphics.newImage(ts.imageData)
    if ts.image.setFilter then ts.image:setFilter("nearest", "nearest") end
    ts.quads = {}
    local FieldView = package.loaded["src.core.game3.field_view"]
    if FieldView then
      FieldView._nativeBatch = nil
      FieldView._nativeBatches = nil
      FieldView._nativeDirty = true
    end
  end
end

--- Pret TilesetAnim_General schedule (UpdateTilesetAnimations increments first).
function TilesetAnim.step()
  if not TilesetAnim._enabled or not Versions.NATIVE_RENDER
      or Versions.TILESET_ANIM == false then return end
  if TilesetAnim._rse then return TilesetAnim.stepRse() end
  TilesetAnim.counter = TilesetAnim.counter + 1
  if TilesetAnim.counter >= TilesetAnim.counterMax then
    TilesetAnim.counter = 0
  end
  local timer = TilesetAnim.counter

  if timer % 8 == 0 then
    local frame = math.floor(timer / 8) % 8
    if frame ~= TilesetAnim._sandFrame then
      TilesetAnim._sandFrame = frame
    end
  end
  if timer % 16 == 1 then
    local frame = math.floor(timer / 16) % 8
    if frame ~= TilesetAnim._waterFrame then
      TilesetAnim._waterFrame = frame
    end
  end
  if timer % 16 == 2 then
    local frame = math.floor(timer / 16) % 5
    if frame ~= TilesetAnim._flowerFrame then
      TilesetAnim._flowerFrame = frame
    end
  end
  for pair in pairs(TilesetAnim._visible) do
    local entry = TilesetAnim._pairs[pair]
    if entry then
      TilesetAnim._applyKind(entry, "sand", TilesetAnim._sandFrame)
      TilesetAnim._applyKind(entry, "water", TilesetAnim._waterFrame)
      TilesetAnim._applyKind(entry, "flower", TilesetAnim._flowerFrame)
    end
  end
end

return TilesetAnim
