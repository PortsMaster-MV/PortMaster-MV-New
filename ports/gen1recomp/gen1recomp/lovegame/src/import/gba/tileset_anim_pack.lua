-- Extract pret General tileset anim frames and per-mid RGBA banks.
-- FireRed: TilesetAnim_General — water@416, sand@464, flower@508.

local Versions = require("src.import.gba.versions")
local Tileset = require("src.import.gba.tileset")
local Metatile = require("src.import.gba.metatile")
local NativePack = require("src.import.gba.native_pack")

local AnimPack = {}

local FrAnims = require("src.import.gba.tileset_anims_firered")

-- Destination tile ranges (primary tileset ids).
AnimPack.WATER_TILE = FrAnims.TILES.water.tile
AnimPack.WATER_COUNT = FrAnims.TILES.water.count
AnimPack.SAND_TILE = FrAnims.TILES.sand.tile
AnimPack.SAND_COUNT = FrAnims.TILES.sand.count
AnimPack.FLOWER_TILE = FrAnims.TILES.flower.tile
AnimPack.FLOWER_COUNT = FrAnims.TILES.flower.count

local TILE_BYTES = 32

local DEFAULT_FRAMES = FrAnims.DEFAULT_FRAMES

local function pairs_using_general(version)
  local catalog = (version and version.tileset_pairs) or Versions.TILESET_PAIRS
  local tilesets = (version and version.tilesets) or Versions.TILESETS
  local out = {}
  for name, pair in pairs(catalog or {}) do
    local pri = tilesets[pair.primary]
    -- general primary is the animating one
    if pair.primary == "general" or (pri and pri.tiles == Versions.TILESETS.general.tiles) then
      out[#out + 1] = name
    end
  end
  table.sort(out)
  return out
end

local function mid_uses_range(bundle, mid, t0, t1)
  local entries = Tileset.metatileEntries(bundle.primaryMt, bundle.secondaryMt, mid)
  if not entries then return false end
  for i = 1, 8 do
    local tid = (entries[i] or 0) % 1024
    if tid >= t0 and tid < t1 then return true end
  end
  return false
end

local function classify_mid(bundle, mid)
  local water = mid_uses_range(bundle, mid, AnimPack.WATER_TILE, AnimPack.WATER_TILE + AnimPack.WATER_COUNT)
  local sand = mid_uses_range(bundle, mid, AnimPack.SAND_TILE, AnimPack.SAND_TILE + AnimPack.SAND_COUNT)
  local flower = mid_uses_range(bundle, mid, AnimPack.FLOWER_TILE, AnimPack.FLOWER_TILE + AnimPack.FLOWER_COUNT)
  if water then return "water" end
  if sand then return "sand" end
  if flower then return "flower" end
  return nil
end

--- Copy primary tiles raw into a mutable 1-based byte array (tid → 32 bytes).
local function mutable_primary(bundle)
  local tiles = bundle.primaryTiles
  local raw = tiles.raw
  local count = tiles.count or 0
  local bytes = {}
  local nbytes = count * TILE_BYTES
  if type(raw) == "string" then
    for i = 1, math.min(nbytes, #raw) do bytes[i] = raw:byte(i) end
  elseif raw._ffi then
    for i = 0, nbytes - 1 do bytes[i + 1] = raw._ffi[i] or 0 end
  else
    for i = 1, nbytes do bytes[i] = raw[i] or 0 end
  end
  return {
    count = count,
    raw = bytes,
    _mutable = true,
  }
end

local function paste_tiles(dstTiles, startTid, frameBytes)
  local base = startTid * TILE_BYTES
  for i = 1, #frameBytes do
    dstTiles.raw[base + i] = frameBytes:byte(i) or 0
  end
end

local function read_frame(rom, off, nbytes)
  local t = rom:readBytes(off, nbytes)
  local s = {}
  for i = 1, nbytes do s[i] = string.char(t[i] or 0) end
  return table.concat(s)
end

function AnimPack.loadFramesFromRom(rom, version)
  local spec = (version and version.tileset_anim_general) or Versions.TILESET_ANIM_GENERAL or DEFAULT_FRAMES
  local frames = {}
  for name, cfg in pairs(spec) do
    local list = {}
    for i = 0, cfg.count - 1 do
      local off = (cfg == DEFAULT_FRAMES[name] and Versions.address(cfg.base) or cfg.base) + i * cfg.stride
      list[i + 1] = read_frame(rom, off, cfg.bytes)
    end
    frames[name] = list
  end
  return frames
end

local function bake_mid_rgba(bundle, mid, rgbPals)
  -- Animate under-layer atlas (sprites sit above this).
  local idx = Metatile.compositeIndexedUnder(bundle, mid)
  local fake = {
    midCount = 1,
    atlasCols = 1,
    atlasRows = 1,
    midIds = { mid },
    pixels = idx,
  }
  local rgba = NativePack.bakeRgba(fake, rgbPals)
  return rgba
end

--- Write anim frame banks for pairs that use General primary.
-- @param midLists [pair] = sorted mid ids used on that pair's maps
function AnimPack.writeExtract(rom, cache, root, bundles, midLists, version, opts)
  root = root or "data/generated/gba"
  if require("src.import.gba.family").active().name ~= "frlg" then
    return AnimPack.writeRse(rom, cache, root, bundles, midLists, version, opts)
  end
  local frames = AnimPack.loadFramesFromRom(rom, version)
  local generalPairs = pairs_using_general(version)
  local rgbCache = {}

  -- Shared raw anim dumps (for debugging / alternate runtimes).
  local animRoot = root .. "/native/general/anim"
  for name, list in pairs(frames) do
    for i, blob in ipairs(list) do
      cache:write(animRoot .. "/" .. name .. "_" .. (i - 1) .. ".4bpp", blob)
    end
  end

  local globalManifest = { anim_version = Versions.ANIM_VERSION or 1, pairs = {} }

  for _, pairName in ipairs(generalPairs) do
    local bundle = bundles[pairName]
    if bundle then
      local mids = midLists and midLists[pairName] or {}
      local byKind = { water = {}, sand = {}, flower = {} }
      for _, mid in ipairs(mids) do
        local kind = classify_mid(bundle, mid)
        if kind then
          byKind[kind][#byKind[kind] + 1] = mid
        end
      end

      local rgbPals = rgbCache[pairName]
      if not rgbPals then
        rgbPals = NativePack.palsToRgb8(bundle.mapPals)
        rgbCache[pairName] = rgbPals
      end

      local pairDir = root .. "/native/" .. pairName
      local pairManifest = {
        water = { mids = byKind.water, frames = #frames.water },
        sand = { mids = byKind.sand, frames = #frames.sand },
        flower = { mids = byKind.flower, frames = #frames.flower },
      }

      local function write_bank(kind, startTid, frameList)
        local midList = byKind[kind]
        if #midList < 1 then return end
        local chunks = {}
        for _, frameBlob in ipairs(frameList) do
          local baseTiles = mutable_primary(bundle)
          paste_tiles(baseTiles, startTid, frameBlob)
          local work = {
            primaryTiles = baseTiles,
            secondaryTiles = bundle.secondaryTiles,
            mapPals = bundle.mapPals,
            primaryMt = bundle.primaryMt,
            secondaryMt = bundle.secondaryMt,
            primaryAttr = bundle.primaryAttr,
            secondaryAttr = bundle.secondaryAttr,
          }
          for _, mid in ipairs(midList) do
            chunks[#chunks + 1] = bake_mid_rgba(work, mid, rgbPals)
          end
        end
        -- Layout: frame-major: frame0[all mids], frame1[all mids], ...
        -- offset = (frame * #mids + midIndex) * 1024
        cache:write(pairDir .. "/anim_" .. kind .. ".rgba", table.concat(chunks))
      end

      write_bank("water", AnimPack.WATER_TILE, frames.water)
      write_bank("sand", AnimPack.SAND_TILE, frames.sand)
      write_bank("flower", AnimPack.FLOWER_TILE, frames.flower)

      local lines = {
        "return {\n",
        ("  anim_version = %d,\n"):format(Versions.ANIM_VERSION or 1),
        "  water = { frames = " .. tostring(#frames.water) .. ", mids = {",
      }
      for i, mid in ipairs(byKind.water) do
        lines[#lines + 1] = (i > 1 and ", " or "") .. tostring(mid)
      end
      lines[#lines + 1] = "} },\n  sand = { frames = " .. tostring(#frames.sand) .. ", mids = {"
      for i, mid in ipairs(byKind.sand) do
        lines[#lines + 1] = (i > 1 and ", " or "") .. tostring(mid)
      end
      lines[#lines + 1] = "} },\n  flower = { frames = " .. tostring(#frames.flower) .. ", mids = {"
      for i, mid in ipairs(byKind.flower) do
        lines[#lines + 1] = (i > 1 and ", " or "") .. tostring(mid)
      end
      lines[#lines + 1] = "} },\n}\n"
      cache:write(pairDir .. "/anim_manifest.lua", table.concat(lines))
      globalManifest.pairs[pairName] = pairManifest
      print(string.format("[anim] %s water=%d sand=%d flower=%d",
        pairName, #byKind.water, #byKind.sand, #byKind.flower))
    end
  end

  return globalManifest
end

AnimPack.INDEX_FILE = "native/anim_index.lua"

local function lcm(a, b)
  local x, y = a, b
  while y ~= 0 do x, y = y, x % y end
  return math.floor(a / x) * b
end

local function serialize(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then return string.format("%q", v) end
  if t ~= "table" then return tostring(v) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) == "number"
  end)
  local inner = indent .. "  "
  local out = { "{\n" }
  for _, k in ipairs(keys) do
    local key = type(k) == "number" and ("[" .. k .. "]") or ("[" .. string.format("%q", k) .. "]")
    out[#out + 1] = inner .. key .. " = " .. serialize(v[k], inner) .. ",\n"
  end
  out[#out + 1] = indent .. "}"
  return table.concat(out)
end

local function tile_sheet_copy(tiles)
  local raw = tiles.raw
  local count = tiles.count or 0
  local bytes = {}
  local nbytes = count * TILE_BYTES
  if type(raw) == "string" then
    for i = 1, math.min(nbytes, #raw) do bytes[i] = raw:byte(i) end
  elseif raw and raw._ffi then
    for i = 0, nbytes - 1 do bytes[i + 1] = raw._ffi[i] or 0 end
  else
    for i = 1, nbytes do bytes[i] = raw and raw[i] or 0 end
  end
  for i = #bytes + 1, nbytes do bytes[i] = 0 end
  return { count = count, raw = bytes, _mutable = true }
end

local function ptr_table(rom, S, name)
  local off = S.off(name)
  local n = S.count(name, 4)
  local out = {}
  for i = 0, n - 1 do
    out[i + 1] = rom:ptrOffset(rom:u32(off + i * 4)) or false
  end
  return out
end

-- pokeemerald/src/tileset_anims.c:553
local function vram_tile(ptr)
  return math.floor((ptr - 0x06000000) / TILE_BYTES)
end

local function resolve_bank(rom, S, row, counter)
  local bank = {
    name = row.name, counter = counter, period = row.period, phase = row.phase,
    fn = row.fn or "mod", slot = row.slot,
  }
  if row.palette then
    local pals = ptr_table(rom, S, row.palette)
    bank.kind = "palette"
    bank.paletteSlot = row.paletteSlot
    bank.frames = #pals
    bank.palettes = pals
    return bank
  end
  bank.kind = "tiles"
  bank.parts = {}
  local counts, countsA, countsB = {}, {}, {}
  for _, p in ipairs(row.parts or {}) do
    local rp = { tiles = p.tiles, offset = p.offset or 0 }
    rp.frames = ptr_table(rom, S, p.frames)
    if p.framesB then
      rp.framesB = ptr_table(rom, S, p.framesB)
      countsB[#countsB + 1] = #rp.framesB
    end
    if p.dstTable then
      local dests = S.off(p.dstTable)
      rp.dst = vram_tile(rom:u32(dests + (row.slot or 0) * 4))
    else
      rp.dst = p.dst
    end
    counts[#counts + 1] = #rp.frames
    countsA[#countsA + 1] = #rp.frames
    bank.parts[#bank.parts + 1] = rp
  end
  local n
  if bank.fn == "mauville" then
    bank.framesA = math.min(unpack(countsA))
    bank.framesB = math.min(unpack(countsB))
    n = bank.framesA + bank.framesB
  elseif row.count == "min" then
    n = math.min(unpack(counts))
  else
    n = 1
    for _, c in ipairs(counts) do n = lcm(n, c) end
  end
  bank.frames = n
  return bank
end

local function frame_ptr(bank, part, i)
  if bank.fn == "mauville" then
    if i < bank.framesA then return part.frames[i + 1] end
    return part.framesB[i - bank.framesA + 1]
  end
  local n = #part.frames
  return part.frames[((i + part.offset) % n) + 1]
end

local function affected_mids(bundle, mids, tileSet)
  local under, over = {}, {}
  for _, mid in ipairs(mids or {}) do
    local entries = Tileset.metatileEntries(bundle.primaryMt, bundle.secondaryMt, mid)
    if entries then
      local lt = Metatile.layerType(bundle, mid)
      local qUnder, qOver = 0, 0
      for q = 0, 3 do
        local bit = 2 ^ q
        local bottom = tileSet[entries[q + 1] % 1024]
        local top = tileSet[entries[q + 5] % 1024]
        if bottom or (top and lt == Metatile.LAYER_COVERED) then qUnder = qUnder + bit end
        if top and lt ~= Metatile.LAYER_COVERED then qOver = qOver + bit end
      end
      if qUnder > 0 then under[#under + 1] = { mid, qUnder } end
      if qOver > 0 then over[#over + 1] = { mid, qOver } end
    end
  end
  return under, over
end

local function idx_bytes(buf)
  local s = {}
  for p = 1, 256 do s[p] = string.char((buf[p] or 0) % 256) end
  return table.concat(s)
end

local function bake_tile_bank(rom, bundle, bank, midList)
  local Family = require("src.import.gba.family")
  local nPriTiles = Family.active().numPrimaryTiles
  local tileSet = {}
  for _, p in ipairs(bank.parts) do
    for t = p.dst, p.dst + p.tiles - 1 do tileSet[t] = true end
  end
  local under, over = affected_mids(bundle, midList, tileSet)
  if #under == 0 and #over == 0 then return nil end
  local chunksU, chunksO = {}, {}
  for i = 0, bank.frames - 1 do
    local pri, sec = bundle.primaryTiles, bundle.secondaryTiles
    local priCopy, secCopy
    for _, p in ipairs(bank.parts) do
      local src = frame_ptr(bank, p, i)
      if src then
        local sheet, localTid
        if p.dst < nPriTiles then
          priCopy = priCopy or tile_sheet_copy(pri)
          sheet, localTid = priCopy, p.dst
        else
          secCopy = secCopy or tile_sheet_copy(sec)
          sheet, localTid = secCopy, p.dst - nPriTiles
        end
        local blob = rom:readString(src, p.tiles * TILE_BYTES)
        local base = localTid * TILE_BYTES
        for b = 1, #blob do
          if base + b <= #sheet.raw then sheet.raw[base + b] = blob:byte(b) end
        end
      end
    end
    local work = {
      primaryTiles = priCopy or pri,
      secondaryTiles = secCopy or sec,
      mapPals = bundle.mapPals,
      primaryMt = bundle.primaryMt,
      secondaryMt = bundle.secondaryMt,
      primaryAttr = bundle.primaryAttr,
      secondaryAttr = bundle.secondaryAttr,
    }
    for _, row in ipairs(under) do
      chunksU[#chunksU + 1] = idx_bytes(Metatile.compositeIndexedUnder(work, row[1]))
    end
    for _, row in ipairs(over) do
      chunksO[#chunksO + 1] = idx_bytes(Metatile.compositeIndexedOver(work, row[1]))
    end
  end
  return under, over, table.concat(chunksU), table.concat(chunksO)
end

-- pokeemerald/src/tileset_anims.c:574
function AnimPack.writeRse(rom, cache, root, bundles, midLists, version, opts)
  local Family = require("src.import.gba.family")
  local F = Family.active()
  local S = Versions.SYMS or F:syms()
  local dataGame = (F.game == "ruby" or F.game == "sapphire") and "rs" or F.game
  local Data = require("src.import.gba.tileset_anims_" .. dataGame)
  local inits = opts and opts.tilesetInits or {}
  local pairsTbl = (version and version.tileset_pairs) or Versions.TILESET_PAIRS or {}
  local names = {}
  for name in pairs(bundles or {}) do names[#names + 1] = name end
  table.sort(names)
  local index = { anim_version = Versions.ANIM_VERSION or 1, pairs = {} }
  local resolved = {}
  local function banksFor(initName, counter)
    local init = initName and Data.INITS[initName]
    if not init then return {}, nil end
    local key = initName .. ":" .. counter
    if not resolved[key] then
      local list = {}
      for _, row in ipairs(init.anims or {}) do list[#list + 1] = resolve_bank(rom, S, row, counter) end
      resolved[key] = list
    end
    return resolved[key], init
  end
  for _, pairName in ipairs(names) do
    local bundle = bundles[pairName]
    local spec = pairsTbl[pairName]
    if bundle and spec then
      local priBanks, priInit = banksFor(inits[spec.primary], "primary")
      local secBanks, secInit = banksFor(inits[spec.secondary], "secondary")
      local priMax = priInit and priInit.max or 0
      local secMax = secInit and secInit.max or 0
      if secMax == "primary" then secMax = priMax end
      local man = {
        anim_version = index.anim_version,
        family = F.name,
        counters = {
          primary = { init = inits[spec.primary], max = priMax },
          secondary = { init = inits[spec.secondary], max = secMax,
            start = secInit and secInit.start or "zero" },
        },
        banks = {},
      }
      local pairDir = root .. "/native/" .. pairName
      for _, list in ipairs({ priBanks, secBanks }) do
        for _, bank in ipairs(list) do
          local row = {
            name = bank.name, counter = bank.counter, period = bank.period, phase = bank.phase,
            fn = bank.fn, slot = bank.slot, frames = bank.frames, kind = bank.kind,
            framesA = bank.framesA, framesB = bank.framesB,
          }
          if bank.kind == "palette" then
            local parts = {}
            for _, off in ipairs(bank.palettes) do
              parts[#parts + 1] = off and rom:readString(off, 32) or string.rep("\0", 32)
            end
            row.paletteSlot = bank.paletteSlot
            row.file = "anim_" .. bank.name .. ".pal"
            cache:write(pairDir .. "/" .. row.file, table.concat(parts))
            man.banks[#man.banks + 1] = row
          else
            local under, over, blobU, blobO = bake_tile_bank(rom, bundle, bank, midLists and midLists[pairName])
            if under then
              row.mids, row.quads, row.overMids, row.overQuads = {}, {}, {}, {}
              for i, r in ipairs(under) do row.mids[i] = r[1]; row.quads[i] = r[2] end
              for i, r in ipairs(over) do row.overMids[i] = r[1]; row.overQuads[i] = r[2] end
              if #under > 0 then
                row.file = "anim_" .. bank.name .. ".idx"
                cache:write(pairDir .. "/" .. row.file, blobU)
              end
              if #over > 0 then
                row.overFile = "anim_" .. bank.name .. "_over.idx"
                cache:write(pairDir .. "/" .. row.overFile, blobO)
              end
              man.banks[#man.banks + 1] = row
            end
          end
        end
      end
      if #man.banks > 0 then
        cache:write(pairDir .. "/anim_manifest.lua", "return " .. serialize(man) .. "\n")
        local summary = {}
        for _, b in ipairs(man.banks) do summary[#summary + 1] = b.name end
        index.pairs[pairName] = summary
      end
    end
  end
  cache:write(root .. "/" .. AnimPack.INDEX_FILE, "return " .. serialize(index) .. "\n")
  return index
end

function AnimPack.ready(cache, root, pair)
  root = root or "data/generated/gba"
  if not pair then
    if require("src.import.gba.family").active().name ~= "frlg" then
      return cache and cache:exists(root .. "/" .. AnimPack.INDEX_FILE)
    end
    return cache and cache:exists(root .. "/native/general/anim/water_0.4bpp")
  end
  return cache and cache:exists(root .. "/native/" .. pair .. "/anim_manifest.lua")
end

AnimPack.DEFAULT_FRAMES = DEFAULT_FRAMES
AnimPack.pairsUsingGeneral = pairs_using_general
AnimPack.classifyMid = classify_mid

return AnimPack
