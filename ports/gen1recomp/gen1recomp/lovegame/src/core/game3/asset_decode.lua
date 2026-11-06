-- CPU-only preparation shared by the render thread and the asset worker.
local Pack = require("src.import.gba.native_pack")
local Palette = require("src.core.game3.palette")
local OwExtract = require("src.import.gba.ow_extract")
local CacheBlob = require("src.import.CacheBlob")
local D = {}

function D.imageData(rgba, w, h)
  if not (love and love.image) then return nil, "love.image unavailable" end
  local ok, data = pcall(love.image.newImageData, w, h, "rgba8", rgba)
  if ok then return data end
  data = love.image.newImageData(w, h)
  local i = 1
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      data:setPixel(x, y, (rgba:byte(i) or 0) / 255, (rgba:byte(i + 1) or 0) / 255,
        (rgba:byte(i + 2) or 0) / 255, (rgba:byte(i + 3) or 0) / 255)
      i = i + 4
    end
  end
  return data
end

function D.pair(cache, root, pair)
  local path = root .. "/" .. pair
  local blob, pals = cache:read(path .. "/mids.idx"), cache:read(path .. "/palettes.bin")
  if not blob or not pals then return nil, "missing native blobs for " .. pair end
  local idx, err = Pack.decodeIdx(blob)
  if not idx then return nil, err end
  local rgb, bgr = Palette.load(pals)
  if not rgb then return nil, bgr end
  local overBlob = cache:read(path .. "/mids_over.idx")
  local out = { pair = pair, cols = idx.atlasCols, rows = idx.atlasRows, midCount = idx.midCount,
    idxBlob = blob, bgr = bgr, midToSlot = {}, layers = {} }
  for i, mid in ipairs(idx.midIds) do out.midToSlot[mid] = i - 1 end
  local function layer(key, dataKey, indexed, source, tag, transparent)
    local hash = Palette.hash(bgr, source)
    local rel = path .. "/atlas_" .. tag .. "_" .. hash .. ".rgba"
    local w, h = indexed.atlasCols * 16, indexed.atlasRows * 16
    local rgba = cache:read(rel)
    if not rgba or #rgba ~= w * h * 4 then
      rgba = Pack.bakeRgba(indexed, rgb, { transparentZero = transparent, cancelled = cache.cancelled })
      if not rgba then return nil, "asset preparation cancelled" end
      if cache.write then pcall(cache.write, cache, rel, rgba) end
    end
    local data, why = D.imageData(rgba, w, h)
    if not data then return nil, why end
    out.layers[#out.layers + 1] = { imageKey = key, dataKey = dataKey, data = data, bytes = w * h * 4 }
    return true
  end
  local ok, why = layer("image", "imageData", idx, blob, overBlob and "u" or "flat", false)
  if not ok then return nil, why end
  local over = overBlob and Pack.decodeIdx(overBlob)
  if over then
    ok, why = layer("overImage", "overImageData", over, overBlob, "o", true)
    if not ok then return nil, why end
    out.overBlob, out.layered = overBlob, true
  end
  if overBlob then
    local midBlob = cache:read(path .. "/mids_mid.idx")
    local mid = midBlob and Pack.decodeIdx(midBlob)
    if mid then
      ok, why = layer("midImage", "midImageData", mid, midBlob, "m", true)
      if not ok then return nil, why end
    end
  end
  out.animFiles = {}
  local manifestRel = path .. "/anim_manifest.lua"
  local manifestBlob = cache:read(manifestRel)
  out.animFiles[manifestRel] = manifestBlob
  local chunk = manifestBlob and load(manifestBlob, "@anim_manifest.lua", "t", {})
  local man = chunk and chunk()
  if man then
    local function read(file)
      if file then out.animFiles[path .. "/" .. file] = cache:read(path .. "/" .. file) end
    end
    out.animFiles[path .. "/palettes.bin"] = pals
    for _, row in ipairs(man.banks or {}) do read(row.file); read(row.overFile) end
    for _, kind in ipairs({ "water", "sand", "flower" }) do
      if man[kind] then read("anim_" .. kind .. ".rgba") end
    end
  end
  return out
end

function D.sprite(cache, root, gid)
  local metaBlob, rgba = cache:read(root .. "/" .. gid .. ".meta"), cache:read(root .. "/" .. gid .. ".rgba")
  local meta = metaBlob and OwExtract.decodeMeta(metaBlob)
  if not meta or not rgba then return nil, "missing OW sheet " .. tostring(gid) end
  local w, h, n = meta.width, meta.height, meta.frameCount
  if w < 1 or h < 1 or n < 1 or w > 256 or h > 256 or n > 512 then return nil, "bad OW dimensions" end
  local bytes = w * h * n * 4
  if #rgba ~= bytes then
    if #rgba < w * h * 4 then return nil, "truncated OW sheet" end
    rgba = rgba:sub(1, bytes) .. string.rep("\0", math.max(0, bytes - #rgba))
  end
  local data, err = D.imageData(rgba, w, h * n)
  if not data then return nil, err end
  meta.imageData, meta.bytes = data, bytes
  return meta
end

-- Snapshots never consult a later GameVersion, cache prefix, or mod mount.
function D.cache(spec, cancelSignal)
  local cache = { cancelled = cancelSignal and function() return cancelSignal:getCount() > 0 end or nil }
  local function checkCancel()
    if cache.cancelled and cache.cancelled() then error("asset preparation cancelled") end
  end
  local function path(rel) return (spec.prefix or "") .. rel end
  function cache:read(rel)
    checkCancel()
    if spec.directory then
      local f = io.open(spec.directory .. "/" .. path(rel), "rb")
      if not f then return nil end
      local bytes = f:read("*a"); f:close(); return CacheBlob.decode(rel, bytes)
    end
    return CacheBlob.readFs(path(rel))
  end
  function cache:write(rel, bytes)
    checkCancel()
    bytes = CacheBlob.encode(rel, bytes)
    -- No directory creation or mounting in a worker; derived caches are optional.
    if spec.directory then
      local f = io.open(spec.directory .. "/" .. path(rel), "wb")
      if not f then return false end
      f:write(bytes); f:close(); return true
    end
    return love.filesystem.write(path(rel), bytes)
  end
  return cache
end

return D
