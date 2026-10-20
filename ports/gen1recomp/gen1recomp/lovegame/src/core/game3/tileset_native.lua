-- Per-pair native FRLG mid atlas (indexed → RGBA) for game3 FieldView.
-- Layered packs: mids.idx = under sprites (BG3/BG1), mids_over.idx = over (BG2).

local Extract = require("src.import.gba.extract_island1")
local NativePack = require("src.import.gba.native_pack")
local Stream = require("src.core.game3.asset_stream")
local Versions = require("src.import.gba.versions")

local NativeTileset = {}

NativeTileset._pairs = {} -- [pair] = { image, overImage?, quads, overQuads, ... }
NativeTileset._cache = nil
NativeTileset._logged = {}
NativeTileset._ready = {}

local makeStream
local function nativeRoot() return Extract.NATIVE_ROOT or (Extract.CACHE_ROOT .. "/native") end
local function resetStream()
  if NativeTileset._stream then NativeTileset._stream:cancel() end
  NativeTileset._stream = NativeTileset._cache and makeStream() or nil
end

local function log(msg)
  print("[game3/native] " .. tostring(msg))
end

function NativeTileset.install(cache, _bundle)
  NativeTileset._cache = cache
  NativeTileset._pairs = {}
  NativeTileset._logged = {}
  NativeTileset._ready = {}
  resetStream()
  local okA, TilesetAnim = pcall(require, "src.core.game3.tileset_anim")
  if okA and TilesetAnim and TilesetAnim.install then
    TilesetAnim.install(cache)
  end
end

function NativeTileset.invalidate()
  NativeTileset._pairs = {}
  NativeTileset._logged = {}
  NativeTileset._ready = {}
  resetStream()
  local okA, TilesetAnim = pcall(require, "src.core.game3.tileset_anim")
  if okA and TilesetAnim and TilesetAnim.invalidate then
    TilesetAnim.invalidate()
  end
end

function NativeTileset.ready(pair)
  if not Versions.NATIVE_RENDER then return false end
  if not pair then return false end
  if NativeTileset._pairs[pair] or NativeTileset._ready[pair] then return true end
  local cache = NativeTileset._cache
  if not cache then return false end
  local ok = cache:exists(nativeRoot() .. "/" .. pair .. "/mids.idx")
    and cache:exists(nativeRoot() .. "/" .. pair .. "/palettes.bin")
  if ok then NativeTileset._ready[pair] = true end
  return ok
end

local animMod
local function tilesetAnim()
  if animMod == nil then
    local okA, TilesetAnim = pcall(require, "src.core.game3.tileset_anim")
    animMod = okA and TilesetAnim or false
  end
  return animMod or nil
end

local function bind_anim(pair, atlas, prepared)
  local TilesetAnim = tilesetAnim()
  if TilesetAnim and TilesetAnim.bindPair then
    TilesetAnim.bindPair(pair, atlas, prepared)
  end
end

local function uploadPair(data)
  local ts = { pair = data.pair, midToSlot = data.midToSlot, cols = data.cols, rows = data.rows,
    midCount = data.midCount, layered = data.layered or false, idxBlob = data.idxBlob,
    overBlob = data.overBlob, bgr = data.bgr, quads = {}, overQuads = {}, slotPix = {}, preparedAnim = data.animFiles }
  for _, layer in ipairs(data.layers) do
    local image = love.graphics.newImage(layer.data)
    image:setFilter("nearest", "nearest")
    ts[layer.imageKey], ts[layer.dataKey] = image, layer.data
    coroutine.yield("texture")
  end
  return ts
end
makeStream = function()
  return Stream.new("pair", NativeTileset._cache, nativeRoot(), uploadPair, function(pair, ts)
    NativeTileset._pairs[pair] = ts
    bind_anim(pair, ts, ts.preparedAnim)
    ts.preparedAnim = nil
    if not NativeTileset._logged[pair] then
      log(string.format("atlas ready pair=%s mids=%d %dx%d layered=%s", pair,
        ts.midCount, ts.cols * 16, ts.rows * 16, tostring(ts.layered)))
      NativeTileset._logged[pair] = true
    end
  end)
end

function NativeTileset.prefetch(pair, priority)
  if type(pair) == "string" and not NativeTileset._pairs[pair] and NativeTileset._stream then
    NativeTileset._stream:prefetch(pair, priority)
  end
end

function NativeTileset.get(pair)
  if not pair then return nil end
  local cached = NativeTileset._pairs[pair]
  if cached then bind_anim(pair, cached); return cached end
  local stream = NativeTileset._stream
  if not stream then return nil end
  local ts, err = stream:get(pair)
  if not ts and not NativeTileset._logged[pair] then
    log("load failed " .. tostring(pair) .. ": " .. tostring(err))
    NativeTileset._logged[pair] = true
  end
  return ts
end

function NativeTileset.slotFor(pairOrTs, mid)
  local ts = type(pairOrTs) == "table" and pairOrTs or NativeTileset.get(pairOrTs)
  if not ts then return 0 end
  return ts.midToSlot[mid] or ts.midToSlot[0] or 0
end

function NativeTileset.hasMid(pairOrTs, mid)
  local ts = type(pairOrTs) == "table" and pairOrTs or NativeTileset.get(pairOrTs)
  return not not (ts and ts.midToSlot and ts.midToSlot[mid] ~= nil)
end

function NativeTileset.quad(pairOrTs, slot)
  local ts = type(pairOrTs) == "table" and pairOrTs or NativeTileset.get(pairOrTs)
  if not ts or not ts.image then return nil end
  slot = tonumber(slot) or 0
  local q = ts.quads[slot]
  if q then return q end
  local cols = ts.cols
  local sx = (slot % cols) * 16
  local sy = math.floor(slot / cols) * 16
  q = love.graphics.newQuad(sx, sy, 16, 16, ts.image:getDimensions())
  ts.quads[slot] = q
  return q
end

function NativeTileset.overQuad(pairOrTs, slot)
  local ts = type(pairOrTs) == "table" and pairOrTs or NativeTileset.get(pairOrTs)
  if not ts or not ts.overImage then return nil end
  slot = tonumber(slot) or 0
  local q = ts.overQuads[slot]
  if q then return q end
  local cols = ts.cols
  local sx = (slot % cols) * 16
  local sy = math.floor(slot / cols) * 16
  q = love.graphics.newQuad(sx, sy, 16, 16, ts.overImage:getDimensions())
  ts.overQuads[slot] = q
  return q
end

local function scan_slot(blob, cols, slot, skipZero)
  local out = {}
  if type(blob) ~= "string" or #blob < 12 then return out end
  local midCount = blob:byte(7) + blob:byte(8) * 256
  local base = 13 + midCount * 2
  local lo, hi = slot * 16, slot * 16 + 15
  local n = 0
  local cells = {}
  out.cells = cells
  local warm = package.loaded["src.core.game3.warm"]
  for i = 0, midCount * 256 - 1 do
    local b = blob:byte(base + i)
    if warm and i % 16384 == 16383 then warm.yield() end
    if b and b >= lo and b <= hi and not (skipZero and b == 0) then
      local mid = math.floor(i / 256)
      local within = i % 256
      cells[mid] = true
      n = n + 1
      out[n] = {
        (mid % cols) * 16 + within % 16,
        math.floor(mid / cols) * 16 + math.floor(within / 16),
        b - lo,
      }
    end
  end
  return out
end

local function retarget(old, new)
  local FieldView = package.loaded["src.core.game3.field_view"]
  if not FieldView then return end
  local function each(store)
    if not store then return end
    for _, b in pairs(store) do
      if b.getTexture and b:getTexture() == old then b:setTexture(new) end
    end
  end
  each(FieldView._nativeBatches)
  each(FieldView._nativeOverBatches)
  local from = FieldView._voidFrom
  if from then
    each(from.under)
    each(from.over)
  end
end

local scratch
local function cellData(data, x, y)
  if not scratch then scratch = love.image.newImageData(16, 16) end
  scratch:paste(data, 0, 0, x, y, 16, 16)
  return scratch
end

local function merge(pend, slots, full)
  if full or not slots then
    pend.full, pend.slots = true, nil
  elseif not pend.full then
    pend.slots = pend.slots or {}
    for slot in pairs(slots) do pend.slots[slot] = true end
  end
end

local function apply(ts, image, data, pend)
  if pend.full then
    image:replacePixels(data)
  elseif pend.slots then
    local cols = ts.cols or 16
    for slot in pairs(pend.slots) do
      local x, y = (slot % cols) * 16, math.floor(slot / cols) * 16
      image:replacePixels(cellData(data, x, y), 1, 1, x, y)
    end
  end
  pend.full, pend.slots = false, nil
end

local function flip(ts, imgKey, dataKey, altKey, slots)
  local img, data = ts[imgKey], ts[dataKey]
  if not (img and data and img.replacePixels) then return end
  ts._pend = ts._pend or setmetatable({}, { __mode = "k" })
  local pend = ts._pend
  local alt = ts[altKey]
  local full = not slots or not next(slots)
  if alt and alt.replacePixels then
    pend[alt] = pend[alt] or {}
    merge(pend[alt], slots, full)
    apply(ts, alt, data, pend[alt])
  elseif love and love.graphics and love.graphics.newImage then
    alt = love.graphics.newImage(data)
    if alt.setFilter then alt:setFilter("nearest", "nearest") end
    pend[alt] = {}
  else
    img:replacePixels(data)
    return
  end
  pend[img] = pend[img] or {}
  merge(pend[img], slots, full)
  ts[imgKey], ts[altKey] = alt, img
  retarget(img, alt)
end

function NativeTileset.markDirty(ts, over, slot)
  local key = over and "_dirtyOver" or "_dirtyUnder"
  local set = ts[key]
  if not set then set = {}; ts[key] = set end
  set[slot] = true
end

function NativeTileset.flush(ts, under, over)
  local du, dov = ts._dirtyUnder, ts._dirtyOver
  ts._dirtyUnder, ts._dirtyOver = nil, nil
  if under then flip(ts, "image", "imageData", "imageAlt", du) end
  if over then flip(ts, "overImage", "overImageData", "overImageAlt", dov) end
end

function NativeTileset.ensureAlt(ts)
  for _, k in ipairs({ { "image", "imageData", "imageAlt" }, { "overImage", "overImageData", "overImageAlt" } }) do
    local img, data = ts[k[1]], ts[k[2]]
    if img and data and not ts[k[3]] and love and love.graphics and love.graphics.newImage then
      local alt = love.graphics.newImage(data)
      if alt.setFilter then alt:setFilter("nearest", "nearest") end
      ts[k[3]] = alt
    end
  end
end

local function paint(ts, over, imageData, list, colors)
  if not (imageData and #list > 0) then return false end
  for i = 1, #list do
    local p = list[i]
    local c = colors[p[3]]
    imageData:setPixel(p[1], p[2], c[1] / 255, c[2] / 255, c[3] / 255, 1)
  end
  for slot in pairs(list.cells or {}) do NativeTileset.markDirty(ts, over, slot) end
  return true
end

-- pokefirered/src/palette.c:88
function NativeTileset.prepareSlot(ts, slot)
  local pix = ts.slotPix[slot]
  if not pix then
    pix = {
      under = scan_slot(ts.idxBlob, ts.cols, slot, false),
      over = ts.overImageData and scan_slot(ts.overBlob, ts.cols, slot, true) or {},
    }
    ts.slotPix[slot] = pix
  end
  return pix
end

function NativeTileset.setSlotPalette(pairOrTs, slot, bgr16)
  local ts = type(pairOrTs) == "table" and pairOrTs or NativeTileset.get(pairOrTs)
  if not (ts and ts.imageData and type(bgr16) == "table") then return false end
  slot = tonumber(slot) or 0
  local pix = NativeTileset.prepareSlot(ts, slot)
  local src = {}
  for c = 0, 15 do src[c] = bgr16[c + 1] or 0 end
  local colors = NativePack.palsToRgb8({ [0] = src })[0]
  NativeTileset.flush(ts, paint(ts, false, ts.imageData, pix.under, colors),
    paint(ts, true, ts.overImageData, pix.over, colors))
  ts.patchedSlots = ts.patchedSlots or {}
  ts.patchedSlots[slot] = true
  return true
end

function NativeTileset.resetSlotPalette(pairOrTs, slot)
  local ts = type(pairOrTs) == "table" and pairOrTs or NativeTileset._pairs[pairOrTs]
  if not (ts and ts.patchedSlots and ts.patchedSlots[slot]) then return false end
  local base = ts.bgr and ts.bgr[slot]
  if not base then return false end
  local list = {}
  for c = 0, 15 do list[c + 1] = base[c] or 0 end
  NativeTileset.setSlotPalette(ts, slot, list)
  ts.patchedSlots[slot] = nil
  return true
end

return NativeTileset
