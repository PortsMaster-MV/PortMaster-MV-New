-- Extract FRLG field-effect graphics directly from ROM.
-- Tall grass, Cut grass leaves, Rock smash rubble, Surf blob, Fly bird, Ripples.

local Versions = require("src.import.gba.versions")

local FieldEffectExtract = {}

FieldEffectExtract.FORMAT_VERSION = 2

local function log(msg)
  print("[gba/field_effects] " .. tostring(msg))
end

local function bgr555_to_rgb8(c)
  c = (tonumber(c) or 0) % 32768
  local r5 = c % 32
  local g5 = math.floor(c / 32) % 32
  local b5 = math.floor(c / 1024) % 32
  return math.floor(r5 * 255 / 31 + 0.5),
    math.floor(g5 * 255 / 31 + 0.5),
    math.floor(b5 * 255 / 31 + 0.5)
end

--- Decode one frame (4bpp tiles in row-major layout).
local function decode_frame(rom, off, fw, fh)
  local tw = math.floor(fw / 8)
  local th = math.floor(fh / 8)
  local pixels = {}
  for i = 1, fw * fh do pixels[i] = 0 end
  for ty = 0, th - 1 do
    for tx = 0, tw - 1 do
      local tileIdx = ty * tw + tx
      local tileOff = off + tileIdx * 32
      local ox, oy = tx * 8, ty * 8
      for y = 0, 7 do
        for x = 0, 7 do
          local byteIndex = tileOff + y * 4 + math.floor(x / 2)
          local b = rom:get(byteIndex)
          local idx = (x % 2 == 1) and math.floor(b / 16) % 16 or (b % 16)
          pixels[(oy + y) * fw + (ox + x) + 1] = idx
        end
      end
    end
  end
  return pixels
end

local function load_palette(rom, palOff)
  local rgb = {}
  for i = 0, 15 do
    local c = rom:u16(palOff + i * 2)
    local r, g, b = bgr555_to_rgb8(c)
    rgb[i] = { r, g, b }
  end
  return rgb
end

local function bake_rgba(rom, picOff, palOff, fw, fh, frames)
  local frameBytes = math.floor(fw / 8) * math.floor(fh / 8) * 32
  local w = fw
  local h = fh * frames
  local rgb = load_palette(rom, palOff)
  local bytes = {}
  for f = 0, frames - 1 do
    local pix = decode_frame(rom, picOff + f * frameBytes, fw, fh)
    for i = 1, fw * fh do
      local idx = pix[i] or 0
      local a = (idx == 0) and 0 or 255
      local c = rgb[idx] or { 0, 0, 0 }
      bytes[#bytes + 1] = string.char(c[1], c[2], c[3], a)
    end
  end
  return table.concat(bytes), w, h
end

-- pokefirered/src/field_effect.c:949
local function bake_indexed(rom, picOff, fw, fh, frames)
  local frameBytes = math.floor(fw / 8) * math.floor(fh / 8) * 32
  local bytes = {}
  for f = 0, frames - 1 do
    local pix = decode_frame(rom, picOff + f * frameBytes, fw, fh)
    for i = 1, fw * fh do
      bytes[#bytes + 1] = string.char(pix[i] or 0)
    end
  end
  return table.concat(bytes)
end

local function bake_pal(rom, palOff)
  local rgb = load_palette(rom, palOff)
  local bytes = {}
  for i = 0, 15 do
    local c = rgb[i] or { 0, 0, 0 }
    bytes[#bytes + 1] = string.char(c[1], c[2], c[3])
  end
  return table.concat(bytes)
end

-- pokefirered/src/field_effect.c:2738
local function bake_streaks(rom, spec)
  local cols, rows = 32, 10
  local w, h = cols * 8, rows * 8
  local rgb = load_palette(rom, spec.pal)
  local tiles = {}
  for t = 0, (spec.tiles or 16) - 1 do
    tiles[t] = decode_frame(rom, spec.gfx + t * 32, 8, 8)
  end
  local out = {}
  for i = 1, w * h do out[i] = "\0\0\0\0" end
  for r = 0, rows - 1 do
    for c = 0, cols - 1 do
      local e = rom:u16(spec.tilemap + (r * cols + c) * 2)
      local tile = tiles[e % 1024]
      local hflip = math.floor(e / 1024) % 2 == 1
      local vflip = math.floor(e / 2048) % 2 == 1
      if tile then
        for y = 0, 7 do
          for x = 0, 7 do
            local sx = hflip and (7 - x) or x
            local sy = vflip and (7 - y) or y
            local idx = tile[sy * 8 + sx + 1] or 0
            if idx ~= 0 then
              local col = rgb[idx]
              out[(r * 8 + y) * w + c * 8 + x + 1] = string.char(col[1], col[2], col[3], 255)
            end
          end
        end
      end
    end
  end
  return table.concat(out), w, h
end

function FieldEffectExtract.writeExtract(rom, cache, root, version)
  root = root or "data/generated/gba"
  version = version or {}
  if not rom or not cache then return nil, "rom and cache required" end

  local effects = Versions.FIELD_EFFECTS or {}
  local rel = root .. "/field_effects"
  local results = {}

  for name, spec in pairs(effects) do
    local picOff = spec.pic
    local palOff = spec.pal
    if picOff and palOff then
      local fw = spec.w or 16
      local fh = spec.h or 16
      local frames = spec.frames or 1
      local rgba, w, h = bake_rgba(rom, picOff, palOff, fw, fh, frames)
      cache:write(rel .. "/" .. name .. ".rgba", rgba)
      if spec.indexed then
        cache:write(rel .. "/" .. name .. ".idx", bake_indexed(rom, picOff, fw, fh, frames))
        cache:write(rel .. "/" .. name .. ".pal", bake_pal(rom, palOff))
      end
      cache:write(rel .. "/" .. name .. ".meta", string.format(
        "return { w = %d, h = %d, frames = %d, fw = %d, fh = %d, indexed = %s, format = %d }\n",
        w, h, frames, fw, fh, spec.indexed and "true" or "false",
        FieldEffectExtract.FORMAT_VERSION))
      log(string.format("%s %dx%d (%d frames, %dx%d) → %s", name, w, h, frames, fw, fh, rel))
      results[name] = { path = rel .. "/" .. name .. ".rgba", w = w, h = h, frames = frames }
    end
  end

  for kind, spec in pairs(Versions.FIELD_MOVE_STREAKS or {}) do
    local name = "field_move_streaks_" .. kind
    local rgba, w, h = bake_streaks(rom, spec)
    cache:write(rel .. "/" .. name .. ".rgba", rgba)
    cache:write(rel .. "/" .. name .. ".meta", string.format(
      "return { w = %d, h = %d, frames = 1, fw = %d, fh = %d, indexed = false, format = %d }\n",
      w, h, w, h, FieldEffectExtract.FORMAT_VERSION))
    log(string.format("%s %dx%d → %s", name, w, h, rel))
    results[name] = { path = rel .. "/" .. name .. ".rgba", w = w, h = h, frames = 1 }
  end

  return results
end

FieldEffectExtract.RSE_FORMAT = 1
FieldEffectExtract.REQUIRED = {
  "field_effects/objects.lua",
  "field_effects/tall_grass.rgba",
  "field_effects/surf_blob.rgba",
  "field_effects/field_move_streaks_outdoors.rgba",
}

local TEMPLATE_PREFIX = "gFieldEffectObjectTemplate_"

-- pokeemerald/src/field_effect_helpers.c:1009
local PALETTE_SLOT_OVERRIDE = {
  surf_blob = 0,
  -- pokeemerald/src/field_effect_helpers.c:1299
  sparkle = 5,
  -- pokeemerald/src/field_effect_helpers.c:1315
  tree_disguise = 4,
  -- pokeemerald/src/field_effect_helpers.c:1320
  mountain_disguise = 3,
  -- pokeemerald/src/field_effect_helpers.c:1325
  sand_disguise_placeholder = 2,
  -- pokeemerald/src/field_effect.c:3088
  rayquaza = 4,
  -- pokeemerald/src/field_effect.c:3123
  bird = 0,
  -- pokeemerald/src/trainer_see.c:725
  heart_icon = 2,
}

local function rseRoot(opts)
  return ((opts and opts.cacheRoot) or "data/generated/gba") .. "/field_effects"
end

local function rsePalettes(rom, V)
  local G = require("src.import.gba.rse.sprite_gfx")
  local F = V.FIELD_EFFECT_OBJECTS
  local byTag = G.fieldEffectScriptPalettes(rom, F.scripts, F.script_count)
  for tag, data in pairs(G.objectEventPalettes(rom, V.OW_SPRITE_PALETTES, V.OW_SPRITE_PALETTE_COUNT)) do
    if byTag[tag] == nil then byTag[tag] = data end
  end
  local slots = {}
  for i = 0, V.OBJ_PALETTE_SLOT_COUNT - 1 do
    slots[i] = rom:u16(V.OBJ_PALETTE_SLOT_TAGS + i * 2)
  end
  return byTag, slots
end

local function rseObject(rom, S, G, cache, root, name, off, byTag, slots, symbol, palStruct, frame)
  local t = G.readTemplate(rom, S, off)
  local fw, fh = t.oam.w, t.oam.h
  if frame then fw, fh = frame[1], frame[2] end
  local entry = {
    name = name,
    symbol = symbol,
    tileTag = t.tileTag,
    paletteTag = t.paletteTag,
    oamPalette = t.oam.paletteNum,
    priority = t.oam.priority,
    affine = t.affine,
    anims = t.anims,
    fw = fw,
    fh = fh,
    frames = #t.images,
  }
  local slot = PALETTE_SLOT_OVERRIDE[name]
  local palOff
  if palStruct then
    palOff = G.ptr(rom, palStruct)
  elseif slot ~= nil then
    entry.paletteSlot = slot
    entry.paletteSlotTag = slots[slot]
    palOff = slots[slot] and byTag[slots[slot]]
  elseif t.paletteTag ~= 0xFFFF then
    palOff = byTag[t.paletteTag]
  else
    slot = t.oam.paletteNum
    entry.paletteSlot = slot
    entry.paletteSlotTag = slots[slot]
    palOff = slots[slot] and byTag[slots[slot]]
  end
  if palOff then
    entry.palette = G.symName(S, palOff)
    entry.paletteOffset = palOff
  end
  if #t.images == 0 then return entry end

  local frameBytes = fw * fh / 2
  entry.pic = G.symName(S, t.images[1].off)
  entry.frameOffsets = {}
  for i, img in ipairs(t.images) do entry.frameOffsets[i] = img.off - t.images[1].off end
  local pix = {}
  for i, img in ipairs(t.images) do
    local h = fh
    if img.size ~= frameBytes and img.size > 0 then h = math.floor(img.size * 2 / fw) end
    G.decodeTiles(rom, img.off, fw, math.min(h, fh), pix, (i - 1) * fh, fw)
  end
  local w, h = fw, fh * #t.images
  local n = w * h
  for i = 1, n do pix[i] = pix[i] or 0 end
  cache:write(root .. "/" .. name .. ".idx", G.idxString(pix, n))
  entry.file = name .. ".idx"
  entry.w, entry.h = w, h
  if palOff then
    local pal = G.readPalette(rom, palOff)
    cache:write(root .. "/" .. name .. ".rgba", G.rgbaString(pix, n, pal))
    local rgb = {}
    for i = 0, 15 do
      local r, g, b = G.rgb8(pal[i])
      rgb[#rgb + 1] = string.char(r, g, b)
    end
    cache:write(root .. "/" .. name .. ".pal", table.concat(rgb))
    entry.rgba = name .. ".rgba"
    entry.colors = {}
    for i = 0, 15 do entry.colors[i + 1] = pal[i] end
  end
  cache:write(root .. "/" .. name .. ".meta", string.format(
    "return { w = %d, h = %d, frames = %d, fw = %d, fh = %d, indexed = true, format = %d }\n",
    w, h, #t.images, fw, fh, FieldEffectExtract.FORMAT_VERSION))
  return entry
end

function FieldEffectExtract.runRse(rom, cache, opts)
  local V = Versions
  local G = require("src.import.gba.rse.sprite_gfx")
  local S = V.SYMS
  local F = V.FIELD_EFFECT_OBJECTS
  local root = rseRoot(opts)
  local byTag, slots = rsePalettes(rom, V)
  local objects, extras = {}, {}
  for i = 0, F.count - 1 do
    local off = G.ptr(rom, F.templates + i * 4)
    if off then
      local prefix = F.template_prefix or TEMPLATE_PREFIX
      local symbol = G.symName(S, off, prefix) or G.symName(S, off)
      local name = G.snake((symbol or ("object_" .. i)):gsub("^" .. prefix, ""))
      name = F.names and F.names[i] or name
      local e = rseObject(rom, S, G, cache, root, name, off, byTag, slots, symbol)
      e.index = i
      objects[#objects + 1] = e
    end
  end
  for _, x in ipairs(F.extras or {}) do
    extras[#extras + 1] = rseObject(rom, S, G, cache, root, x.name, x.template, byTag, slots,
      G.symName(S, x.template), x.palette, x.frame)
  end
  local streaks = {}
  for kind, spec in pairs(V.FIELD_MOVE_STREAKS or {}) do
    local name = "field_move_streaks_" .. kind
    local rgba, w, h = bake_streaks(rom, spec)
    cache:write(root .. "/" .. name .. ".rgba", rgba)
    cache:write(root .. "/" .. name .. ".meta", string.format(
      "return { w = %d, h = %d, frames = 1, fw = %d, fh = %d, indexed = false, format = %d }\n",
      w, h, w, h, FieldEffectExtract.FORMAT_VERSION))
    streaks[kind] = { file = name .. ".rgba", w = w, h = h }
  end
  local spot = F.spotlight
  if spot then
    cache:write(root .. "/spotlight.4bpp", rom:readString(spot.gfx, spot.gfx_size))
    cache:write(root .. "/spotlight.gbapal", G.palBytes(G.readPalette(rom, spot.pal)))
  end
  local tags = {}
  for tag, off in pairs(byTag) do tags[tag] = G.symName(S, off) or string.format("0x%X", off) end
  local slotTags = {}
  for i = 0, #slots do slotTags[i + 1] = slots[i] end
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  cache:write(root .. "/objects.lua", "return " .. serialize({
    format = FieldEffectExtract.RSE_FORMAT,
    family = "rse",
    count = #objects,
    objects = objects,
    extras = extras,
    streaks = streaks,
    spotlight = spot and { gfx = "spotlight.4bpp", pal = "spotlight.gbapal", tiles = spot.gfx_size / 32 } or nil,
    paletteTags = tags,
    paletteSlotTags = slotTags,
    aliases = { fly_bird = "bird", pokemoncenter_monitor = "pokecenter_monitor",
      deoxys_rock_fragments = "deoxys_rock_fragment" },
  }) .. "\n")
  log(string.format("rse: %d objects, %d extras -> %s", #objects, #extras, root))
  return { objects = #objects, extras = #extras }
end

function FieldEffectExtract.run(rom, cache, opts)
  if Versions.FAMILY ~= "rse" then
    return FieldEffectExtract.writeExtract(rom, cache, opts and opts.cacheRoot)
  end
  return FieldEffectExtract.runRse(rom, cache, opts)
end

function FieldEffectExtract.ready(cache, cacheRoot)
  if Versions.FAMILY ~= "rse" then return false end
  local body = cache and cache.read and cache:read(rseRoot({ cacheRoot = cacheRoot }) .. "/objects.lua")
  if type(body) ~= "string" or #body == 0 then return false end
  local chunk = load(body, "=objects", "t", {})
  local ok, m = pcall(chunk or error)
  if not (ok and type(m) == "table" and m.format == FieldEffectExtract.RSE_FORMAT
    and m.count == Versions.FIELD_EFFECT_OBJECTS.count) then return false end
  for _, file in ipairs(Versions.FIELD_EFFECT_OBJECTS.requiredFiles or {}) do
    local data = cache:read(rseRoot({cacheRoot = cacheRoot}) .. "/" .. file)
    if type(data) ~= "string" or #data == 0 then return false end
  end
  return true
end

return FieldEffectExtract
