-- FRLG battle transition chrome (ROM-baked under pokemon/battle_transition/).

local Extract = require("src.import.gba.extract_island1")
local BattleTransitionExtract = require("src.import.gba.battle_transition_extract")

local BattleTransitionChrome = {}

BattleTransitionChrome._cache = nil
BattleTransitionChrome._manifest = nil
BattleTransitionChrome._bigPokeball = nil
BattleTransitionChrome._slidingPokeball = nil
BattleTransitionChrome._gridSquare = nil
BattleTransitionChrome._gridQuads = {}
BattleTransitionChrome._gridFrames = {}
BattleTransitionChrome._vsbars = {}
BattleTransitionChrome._banners = {}
BattleTransitionChrome._logged = false

local MUGSHOT_KEYS = { "lorelei", "bruno", "agatha", "lance", "blue" }
local GENDER_KEYS = { "male", "female" }

local function cache_root()
  return Extract.CACHE_ROOT or "data/generated/gba"
end

local function transition_root()
  return cache_root() .. "/" .. BattleTransitionExtract.CACHE_SUB
end

local function log(msg)
  if BattleTransitionChrome._logged then return end
  BattleTransitionChrome._logged = true
  print("[game3/battle_transition_chrome] " .. tostring(msg))
end

local function resolve_cache(cache)
  if cache and cache.read then return cache end
  local okD, Dataset = pcall(require, "src.core.game3.dataset")
  if okD and Dataset and Dataset.cache then
    return Dataset.cache()
  end
  return {
    read = function(_, rel)
      local ok, CacheFs = pcall(require, "src.import.CacheFs")
      if ok and CacheFs and CacheFs.readActive then
        return CacheFs.readActive(rel)
      end
      return nil
    end,
  }
end

local function read_bytes(rel)
  local cache = BattleTransitionChrome._cache
  if cache and cache.read then
    local d = cache:read(rel)
    if type(d) == "string" and #d > 0 then return d end
  end
  local okD, Dataset = pcall(require, "src.core.game3.dataset")
  if okD and Dataset and Dataset.cache then
    local d = Dataset.cache():read(rel)
    if type(d) == "string" and #d > 0 then return d end
  end
  return nil
end

local function load_lua(rel)
  local src = read_bytes(rel)
  if not src then return nil end
  local chunk = load(src, "@" .. rel, "t", {})
  if not chunk then return nil end
  local ok, t = pcall(chunk)
  if ok then return t end
  return nil
end

local function rgba_to_data(rgba, w, h, keyed)
  if not (love and love.image and love.graphics) then return nil end
  if not rgba or #rgba < w * h * 4 then return nil end
  local ok, imageData = pcall(love.image.newImageData, w, h, "rgba8", rgba)
  if not ok or not imageData then return nil end
  if keyed then
    local kr, kg, kb = imageData:getPixel(0, 0)
    imageData:mapPixel(function(_, _, r, g, b, a)
      if r == kr and g == kg and b == kb then return r, g, b, 0 end
      return r, g, b, a
    end)
  end
  return imageData
end

local function data_to_image(imageData, wrap)
  if not imageData then return nil end
  local image = love.graphics.newImage(imageData)
  if image.setFilter then image:setFilter("nearest", "nearest") end
  if wrap and image.setWrap then pcall(image.setWrap, image, "repeat", "repeat") end
  return image
end

local function rgba_to_image(rgba, w, h, keyed, wrap)
  return data_to_image(rgba_to_data(rgba, w, h, keyed), wrap)
end

function BattleTransitionChrome.install(cache)
  BattleTransitionChrome._cache = resolve_cache(cache)
  BattleTransitionChrome._manifest = nil
  BattleTransitionChrome._bigPokeball = nil
  BattleTransitionChrome._slidingPokeball = nil
  BattleTransitionChrome._gridSquare = nil
  BattleTransitionChrome._gridQuads = {}
  BattleTransitionChrome._gridFrames = {}
  BattleTransitionChrome._vsbars = {}
  BattleTransitionChrome._banners = {}
  BattleTransitionChrome._logged = false
  BattleTransitionChrome._rseManifest = nil

  local root = transition_root()
  BattleTransitionChrome._manifest = load_lua(root .. "/manifest.lua")

  local bp = read_bytes(root .. "/big_pokeball.rgba")
  local sp = read_bytes(root .. "/sliding_pokeball.rgba")
  local gs = read_bytes(root .. "/grid_square.rgba")

  BattleTransitionChrome._bigPokeball = rgba_to_image(bp, 240, 160, true)
  BattleTransitionChrome._slidingPokeball = rgba_to_image(sp, 32, 32)
  local gridData = rgba_to_data(gs, 8, 120, true)
  BattleTransitionChrome._gridSquare = data_to_image(gridData)
  if gridData and love.image.newImageData then
    for frame = 0, 14 do
      local fd = love.image.newImageData(8, 8)
      fd:paste(gridData, 0, 0, 0, frame * 8, 8, 8)
      BattleTransitionChrome._gridFrames[frame] = data_to_image(fd, true)
    end
  end

  if BattleTransitionChrome._gridSquare and love and love.graphics and love.graphics.newQuad then
    for frame = 0, 14 do
      BattleTransitionChrome._gridQuads[frame + 1] = love.graphics.newQuad(
        0, frame * 8, 8, 8, 8, 120
      )
    end
  end

  local manifest = BattleTransitionChrome._manifest or {}
  BattleTransitionChrome._assets = {}
  BattleTransitionChrome._assetImages = {}
  for _, key in ipairs(manifest.mugshots or MUGSHOT_KEYS) do
    for _, gender in ipairs(manifest.genders or GENDER_KEYS) do
      local vsKey = key .. "_" .. gender
      local vsRgba = read_bytes(root .. "/vsbar_" .. vsKey .. ".rgba")
      if vsRgba then
        BattleTransitionChrome._vsbars[vsKey] = rgba_to_image(vsRgba, 256, 160, true, true)
      end
    end
    local bRgba = read_bytes(root .. "/banner_" .. key .. ".rgba")
    if bRgba then
      BattleTransitionChrome._banners[key] = rgba_to_image(bRgba, 120, 8)
    end
  end

  if not BattleTransitionChrome._bigPokeball then
    log("transition chrome missing — re-run --pokemon extract")
  end
end

function BattleTransitionChrome.manifest()
  BattleTransitionChrome.ensureInstalled()
  return BattleTransitionChrome._manifest or {}
end

function BattleTransitionChrome.assetInfo(key)
  local info = (BattleTransitionChrome.manifest().assets or {})[key]
  if not info then error("battle transition chrome: no asset '" .. tostring(key) .. "' in the manifest") end
  return info
end

local function asset_data(key)
  BattleTransitionChrome.ensureInstalled()
  local hit = BattleTransitionChrome._assets[key]
  if hit then return hit end
  local info = BattleTransitionChrome.assetInfo(key)
  local root = transition_root()
  hit = {
    info = info,
    idx = read_bytes(root .. "/" .. info.idx),
    pal = read_bytes(root .. "/" .. info.pal),
    pal2 = info.pal2 and read_bytes(root .. "/" .. info.pal2) or nil,
  }
  if not (hit.idx and hit.pal) then error("battle transition chrome: asset '" .. key .. "' missing from the cache") end
  BattleTransitionChrome._assets[key] = hit
  return hit
end

function BattleTransitionChrome.assetPalette(key, which, bank)
  local a = asset_data(key)
  local bytes = (which == 2) and a.pal2 or a.pal
  if not bytes then error("battle transition chrome: asset '" .. key .. "' has no palette " .. tostring(which)) end
  bank = tonumber(bank) or 0
  local banks = math.floor(#bytes / 32)
  if bank < 0 or bank >= banks then return nil end
  return bytes:sub(bank * 32 + 1, bank * 32 + 32)
end

function BattleTransitionChrome.assetBanks(key, which)
  local a = asset_data(key)
  local bytes = (which == 2) and a.pal2 or a.pal
  return bytes and math.floor(#bytes / 32) or 0
end

local function bgr555(bytes, i)
  local lo, hi = bytes:byte(i * 2 + 1, i * 2 + 2)
  local v = (lo or 0) + (hi or 0) * 256
  local function c5(x) return math.floor(x * 255 / 31 + 0.5) end
  return c5(v % 32), c5(math.floor(v / 32) % 32), c5(math.floor(v / 1024) % 32)
end

function BattleTransitionChrome.assetImage(key, palBytes)
  local a = asset_data(key)
  palBytes = palBytes or BattleTransitionChrome.assetPalette(key, 1, a.info.previewBank or 0)
  local cacheKey = key .. ":" .. palBytes
  local img = BattleTransitionChrome._assetImages[cacheKey]
  if img ~= nil then return img or nil end
  if not (love and love.image and love.graphics) then return nil end
  local w, h = a.info.w, a.info.h
  local lut = {}
  for i = 0, 15 do lut[i] = { bgr555(palBytes, i) } end
  local data = love.image.newImageData(w, h)
  local idx = a.idx
  data:mapPixel(function(x, y)
    local c = (idx:byte(y * w + x + 1) or 0) % 16
    if c == 0 then return 0, 0, 0, 0 end
    local rgb = lut[c]
    return rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1
  end)
  img = love.graphics.newImage(data)
  img:setFilter("nearest", "nearest")
  pcall(img.setWrap, img, "repeat", "repeat")
  BattleTransitionChrome._assetImages[cacheKey] = img
  return img
end

BattleTransitionChrome.RSE_SUB = "battle_transition_rse"

function BattleTransitionChrome.rseManifest()
  BattleTransitionChrome.ensureInstalled()
  local m = BattleTransitionChrome._rseManifest
  if m then return m end
  local rel = cache_root() .. "/" .. BattleTransitionChrome.RSE_SUB .. "/manifest.lua"
  m = load_lua(rel)
  if not m then error("battle transition chrome: " .. rel .. " missing from the cache") end
  BattleTransitionChrome._rseManifest = m
  return m
end

function BattleTransitionChrome.indexedImage(cacheKey, idx, w, h, palBytes)
  BattleTransitionChrome.ensureInstalled()
  local key = cacheKey .. ":" .. palBytes
  local img = BattleTransitionChrome._assetImages[key]
  if img ~= nil then return img or nil end
  if not (love and love.image and love.graphics) then return nil end
  local lut = {}
  for i = 0, 15 do lut[i] = { bgr555(palBytes, i) } end
  local data = love.image.newImageData(w, h)
  data:mapPixel(function(x, y)
    local c = (idx[y * w + x + 1] or 0) % 16
    if c == 0 then return 0, 0, 0, 0 end
    local rgb = lut[c]
    return rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1
  end)
  img = love.graphics.newImage(data)
  img:setFilter("nearest", "nearest")
  BattleTransitionChrome._assetImages[key] = img
  return img
end

function BattleTransitionChrome.ensureInstalled()
  if not BattleTransitionChrome._cache then
    BattleTransitionChrome.install()
  end
end

function BattleTransitionChrome.ready()
  BattleTransitionChrome.ensureInstalled()
  return BattleTransitionChrome._bigPokeball ~= nil
end

function BattleTransitionChrome.bigPokeball()
  BattleTransitionChrome.ensureInstalled()
  return BattleTransitionChrome._bigPokeball
end

function BattleTransitionChrome.slidingPokeball()
  BattleTransitionChrome.ensureInstalled()
  return BattleTransitionChrome._slidingPokeball
end

function BattleTransitionChrome.gridSquare()
  BattleTransitionChrome.ensureInstalled()
  return BattleTransitionChrome._gridSquare, BattleTransitionChrome._gridQuads
end

function BattleTransitionChrome.gridFrame(stage)
  BattleTransitionChrome.ensureInstalled()
  return BattleTransitionChrome._gridFrames[stage]
end

function BattleTransitionChrome.vsbar(mugshotKey, genderKey)
  BattleTransitionChrome.ensureInstalled()
  genderKey = (genderKey == "female" or genderKey == 1) and "female" or "male"
  local key = tostring(mugshotKey or "lorelei"):lower() .. "_" .. genderKey
  return BattleTransitionChrome._vsbars[key]
end

function BattleTransitionChrome.banner(mugshotKey)
  BattleTransitionChrome.ensureInstalled()
  local key = tostring(mugshotKey or "lorelei"):lower()
  return BattleTransitionChrome._banners[key]
end

return BattleTransitionChrome
