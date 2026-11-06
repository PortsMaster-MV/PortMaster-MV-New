local Versions = require("src.import.gba.versions")
local G = require("src.import.gba.rse.sprite_gfx")

local FcField = {}

FcField.CACHE_SUB = "field_fc"
FcField.FORMAT = 1
FcField.REQUIRED = { "field_fc/manifest.lua" }

local function root(opts)
  return ((opts and opts.cacheRoot) or "data/generated/gba") .. "/" .. FcField.CACHE_SUB
end

local function rgbList(rom, off)
  local out = {}
  for i = 0, 15 do
    local r, g, b = G.rgb8(rom:u16(off + i * 2))
    out[i + 1] = { r, g, b }
  end
  return out
end

-- pokeemerald/include/global.fieldmap.h:257
local function readInfo(rom, off)
  local flags = rom:get(off + 12)
  local w, h = rom:u16(off + 8), rom:u16(off + 10)
  if w >= 0x8000 then w = w - 0x10000 end
  if h >= 0x8000 then h = h - 0x10000 end
  return {
    paletteTag = rom:u16(off + 2),
    reflectionTag = rom:u16(off + 4),
    width = math.abs(w),
    height = math.abs(h),
    slot = flags % 16,
    shadow = math.floor(flags / 16) % 4,
    noReflectionLoad = math.floor(flags / 128) % 2 == 1,
    tracks = rom:get(off + 13),
  }
end

-- pokeemerald/src/event_object_movement.c:546
local function readPairs(rom, off, size)
  local out = {}
  for i = 0, math.floor(size / 8) - 1 do
    local b = off + i * 8
    local tag = rom:u16(b)
    local data = G.ptr(rom, b + 4)
    if not data then break end
    out[tag] = rom:u16(data)
  end
  return out
end

-- pokeemerald/src/mirage_tower.c:75
local function mirageTower(rom, S, cache, dir)
  local M = Versions.FC_MIRAGE_TOWER
  if not M then return nil end
  local pix = G.decodeTiles(rom, M.crumbles, 16, 16, {}, 0, 16)
  cache:write(dir .. "/mirage_tower_crumbles.idx", G.idxString(pix, 16 * 16))
  local positions = {}
  for i = 0, M.positions_count - 1 do
    local b = M.positions + i * 6
    local function s16(v) return v >= 0x8000 and v - 0x10000 or v end
    positions[i + 1] = { s16(rom:u16(b)), s16(rom:u16(b + 2)), s16(rom:u16(b + 4)) }
  end
  local invisible = {}
  for i = 0, M.metatiles_count - 1 do
    local b = M.metatiles + i * 4
    invisible[i + 1] = { x = rom:get(b), y = rom:get(b + 1), metatile = rom:u16(b + 2) }
  end
  return {
    crumbles = { idx = "mirage_tower_crumbles.idx", w = 16, h = 16 },
    crumblePositions = positions,
    invisibleMetatiles = invisible,
  }
end

-- pokeemerald/src/field_screen_effect.c:53
local function flashRadii(rom)
  local F = Versions.FC_FLASH_RADII
  if not F then return nil end
  local out = {}
  for i = 0, F.count - 1 do out[i] = rom:u16(F.off + i * 2) end
  return out
end

function FcField.run(rom, cache, opts)
  local V = Versions
  local S = V.SYMS
  local R = V.FC_REFLECTION
  local dir = root(opts)
  local serialize = require("src.import.gba.extract_scripts").serialize_lua

  local gfx = {}
  for gid = 0, V.NUM_OBJ_EVENT_GFX - 1 do
    local info = G.ptr(rom, V.OW_GFX_POINTERS + gid * 4)
    if info then gfx[gid] = readInfo(rom, info) end
  end

  local palettes = {}
  for tag, off in pairs(G.objectEventPalettes(rom, V.OW_SPRITE_PALETTES, V.OW_SPRITE_PALETTE_COUNT)) do
    palettes[tag] = rgbList(rom, off)
  end

  local slotTags = {}
  for i = 0, V.OBJ_PALETTE_SLOT_COUNT - 1 do slotTags[i] = rom:u16(V.OBJ_PALETTE_SLOT_TAGS + i * 2) end
  local reflectionMap = {}
  for i = 0, 15 do reflectionMap[i] = rom:get(R.map + i) end

  local manifest = {
    format = FcField.FORMAT,
    family = "rse",
    gfx = gfx,
    palettes = palettes,
    slotTags = slotTags,
    reflectionMap = reflectionMap,
    playerReflections = readPairs(rom, R.player, R.player_size),
    specialReflections = readPairs(rom, R.special, R.special_size),
    palTagNone = R.tag_none,
    mirageTower = mirageTower(rom, S, cache, dir),
    flashRadii = flashRadii(rom),
  }
  cache:write(dir .. "/manifest.lua", "return " .. serialize(manifest))
  return true
end

function FcField.ready(cache, cacheRoot)
  return cache and cache.read and cache:read(root({ cacheRoot = cacheRoot }) .. "/manifest.lua") ~= nil or false
end

return FcField
