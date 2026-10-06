-- Extract FRLG overworld object graphics (4bpp pics + OBJ pals) from ROM.
-- Pret: gObjectEventGraphicsInfoPointers + sObjectEventSpritePalettes.

local Versions = require("src.import.gba.versions")
local Lz77 = require("src.import.gba.lz77")
local ExtractMapEvents = require("src.import.gba.extract_map_events")

local OwExtract = {}

OwExtract.MAGIC = "SVOW"
OwExtract.FORMAT_VERSION = 4

OwExtract.REQUIRED = { "ow/manifest.lua", "ow/palette_manifest.lua" }

local function u8(n)
  return string.char((tonumber(n) or 0) % 256)
end

local function u16le(n)
  n = (tonumber(n) or 0) % 65536
  return string.char(n % 256, math.floor(n / 256) % 256)
end

local function read_u16(s, i)
  return s:byte(i) + s:byte(i + 1) * 256
end

local function gba_off(ptr)
  return Versions.gbaToFile(ptr)
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

--- Load paletteTag → 16 BGR555 colors from sObjectEventSpritePalettes.
function OwExtract.loadPaletteTable(rom, version)
  version = version or {}
  local tableOff = version.ow_sprite_palettes or Versions.OW_SPRITE_PALETTES
  local palsByTag = {}
  for i = 0, 63 do
    local off = tableOff + i * 8
    local dataPtr = rom:u32(off)
    local tag = rom:u16(off + 4)
    if dataPtr == 0 then break end
    local dataOff = gba_off(dataPtr)
    if dataOff and tag ~= 0 then
      local colors = {}
      for c = 0, 15 do
        colors[c] = rom:u16(dataOff + c * 2)
      end
      palsByTag[tag] = colors
    end
  end
  return palsByTag
end

local PALETTE_TAG_NONE = 0xFFFF

local function read_paired_palette_sets(rom, offset, version)
  local sets = {}
  for i = 0, 63 do
    local row = offset + i * version.paired_palette_stride
    local tag = rom:u16(row)
    local dataPtr = rom:u32(row + 4)
    if dataPtr == 0 then break end
    local dataOff = gba_off(dataPtr)
    if not dataOff then return nil end
    local paletteTags = {}
    for reflectionType = 0, version.paired_palette_count - 1 do
      paletteTags[reflectionType] = rom:u16(dataOff + reflectionType * 2)
    end
    sets[tag] = paletteTags
  end
  return sets
end

function OwExtract.loadReflectionMappings(rom, version)
  version = version or Versions.OW_REFLECTION
  if not version then return nil end
  local slotMap, paletteTagSets = {}, {}
  for slot = 0, version.palette_map_count - 1 do
    slotMap[slot] = rom:get(version.palette_map + slot)
  end
  for set = 0, version.palette_set_count - 1 do
    local ptr = gba_off(rom:u32(version.palette_tag_sets + set * 4))
    if not ptr then return nil end
    local tags = {}
    for slot = 0, version.palette_tag_slot_count - 1 do
      tags[slot] = rom:u16(ptr + slot * 2)
    end
    paletteTagSets[set] = tags
  end
  local mappings = {
    slotMap = slotMap,
    paletteTagSets = paletteTagSets,
    playerSets = read_paired_palette_sets(rom, version.player_palette_sets, version),
    specialSets = read_paired_palette_sets(rom, version.special_palette_sets, version),
  }
  if not mappings.playerSets or not mappings.specialSets then return nil end
  return mappings
end

function OwExtract.reflectionPaletteTag(info, mappings)
  if not (info and mappings) then return nil end
  local paired = mappings.playerSets[info.paletteTag]
    or mappings.specialSets[info.paletteTag]
  if paired then return paired[0] end
  local reflectionSlot = mappings.slotMap[info.paletteSlot]
  local defaultTags = mappings.paletteTagSets[0]
  return defaultTags and defaultTags[reflectionSlot] or nil
end

local function read_graphics_info(rom, infoOff)
  local tileTag = rom:u16(infoOff)
  local paletteTag = rom:u16(infoOff + 2)
  local reflectionPaletteTag = rom:u16(infoOff + 4)
  local size = rom:u16(infoOff + 6)
  local width = rom:u16(infoOff + 8)
  if width >= 0x8000 then width = width - 0x10000 end
  local height = rom:u16(infoOff + 10)
  if height >= 0x8000 then height = height - 0x10000 end
  local flags = rom:get(infoOff + 12)
  local tracks = rom:get(infoOff + 13)
  local imagesPtr = rom:u32(infoOff + 0x1C)
  local animsPtr = rom:u32(infoOff + 0x18)
  local subspriteTablesPtr = rom:u32(infoOff + 0x14)
  return {
    tileTag = tileTag,
    paletteTag = paletteTag,
    reflectionPaletteTag = reflectionPaletteTag,
    size = size,
    width = math.abs(width),
    height = math.abs(height),
    paletteSlot = flags % 16,
    shadowSize = math.floor(flags / 16) % 4,
    inanimate = math.floor(flags / 64) % 2 == 1,
    tracks = tracks,
    imagesPtr = imagesPtr,
    animsPtr = animsPtr,
    subspriteTablesPtr = subspriteTablesPtr,
  }
end

-- src/sprite.c:246
local OAM_DIMS = {
  [0] = { { 8, 8 }, { 16, 16 }, { 32, 32 }, { 64, 64 } },
  [1] = { { 16, 8 }, { 32, 8 }, { 32, 16 }, { 64, 32 } },
  [2] = { { 8, 16 }, { 8, 32 }, { 16, 32 }, { 32, 64 } },
}

local function signed(v, bits)
  local half = 2 ^ (bits - 1)
  if v >= half then return v - 2 * half end
  return v
end

-- src/sprite.c:1669
local function read_subsprite_layout(rom, tablesPtr, width, height)
  local tableOff = tablesPtr ~= 0 and gba_off(tablesPtr)
  if not tableOff then return nil end
  local count = rom:get(tableOff)
  local subsOff = gba_off(rom:u32(tableOff + 4))
  if not subsOff or count < 1 or count > 64 then return nil end
  local game = Versions.GAME
  -- pokeruby/include/sprite.h:153
  local wide = game == "ruby" or game == "sapphire"
  local stride = wide and 8 or 4
  local subs = {}
  local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
  for i = 0, count - 1 do
    local off = subsOff + i * stride
    local x, y, bits
    if wide then
      x, y, bits = signed(rom:u16(off), 16), signed(rom:u16(off + 2), 16), rom:u16(off + 4)
    else
      x, y, bits = signed(rom:get(off), 8), signed(rom:get(off + 1), 8), rom:u16(off + 2)
    end
    local dims = OAM_DIMS[bits % 4]
    dims = dims and dims[math.floor(bits / 4) % 4 + 1]
    if not dims then return nil end
    subs[#subs + 1] = { x = x, y = y, w = dims[1], h = dims[2], tile = math.floor(bits / 16) % 1024 }
    minX, minY = math.min(minX, x), math.min(minY, y)
    maxX, maxY = math.max(maxX, x + dims[1]), math.max(maxY, y + dims[2])
  end
  if maxX - minX ~= width or maxY - minY ~= height then return nil end
  for _, sub in ipairs(subs) do
    sub.x, sub.y = sub.x - minX, sub.y - minY
  end
  return {
    subs = subs,
    offX = minX + math.floor(width / 2),
    offY = minY + math.floor(height / 2),
  }
end

local MAX_PIC_FRAMES = 32
local picStartsCache = setmetatable({}, { __mode = "k" })

local function pic_table_starts(rom, pointers, num)
  local byRom = picStartsCache[rom]
  if not byRom then byRom = {}; picStartsCache[rom] = byRom end
  local key = pointers .. ":" .. num
  if byRom[key] then return byRom[key] end
  local starts, infos = {}, {}
  local function add(infoOff)
    if infos[infoOff] then return false end
    if infoOff + 0x24 > rom.size or rom:u16(infoOff) ~= 0xFFFF then return false end
    local animsOff = gba_off(rom:u32(infoOff + 0x18))
    local imagesOff = gba_off(rom:u32(infoOff + 0x1C))
    if not animsOff or not imagesOff then return false end
    infos[infoOff] = true
    starts[imagesOff] = true
    return true
  end
  for g = 0, num - 1 do
    local infoOff = gba_off(rom:u32(pointers + g * 4))
    if infoOff then add(infoOff) end
  end
  local known = {}
  for off in pairs(infos) do known[#known + 1] = off end
  for _, off in ipairs(known) do
    local nextOff = off + 0x24
    while add(nextOff) do nextOff = nextOff + 0x24 end
  end
  byRom[key] = starts
  return starts
end

-- pokefirered/src/data/object_events/object_event_pic_tables.h
local function pic_table_len(rom, imagesOff, frameBytes, starts)
  local n = 0
  while n < MAX_PIC_FRAMES do
    local off = imagesOff + n * 8
    if n > 0 and starts[off] then break end
    if off + 8 > rom.size then break end
    if not gba_off(rom:u32(off)) or rom:u16(off + 4) ~= frameBytes then break end
    n = n + 1
  end
  return n
end

local function sym_frame_count(imagesOff)
  local S = Versions.SYMS
  if not S or not imagesOff then return nil end
  for _, n in ipairs(S.namesAt(imagesOff)) do
    if n:find("PicTable", 1, true) then
      local ok, size = pcall(S.size, n)
      if ok and size and size > 0 and size % 8 == 0 then return size / 8 end
    end
  end
  return nil
end

--- Decode one 4bpp sprite frame (tile order: L→R, T→B 8×8) → indexed [w*h].
local function decode_frame_4bpp(raw, width, height, layout)
  local pixels = {}
  local tilesX = math.floor(width / 8)
  local tilesY = math.floor(height / 8)
  local function nybble(byteIndex, high)
    local b
    if type(raw) == "string" then
      b = raw:byte(byteIndex + 1) or 0
    elseif raw._ffi then
      b = raw._ffi[byteIndex] or 0
    else
      b = raw[byteIndex + 1] or 0
    end
    if high then return math.floor(b / 16) % 16 end
    return b % 16
  end
  local function tileAt(tx, ty)
    if not layout then return ty * tilesX + tx end
    local px, py = tx * 8, ty * 8
    for _, sub in ipairs(layout.subs) do
      if px >= sub.x and px < sub.x + sub.w and py >= sub.y and py < sub.y + sub.h then
        return sub.tile + ((py - sub.y) / 8) * (sub.w / 8) + (px - sub.x) / 8
      end
    end
    return nil
  end
  for ty = 0, tilesY - 1 do
    for tx = 0, tilesX - 1 do
      local tileIndex = tileAt(tx, ty)
      local tileOff = (tileIndex or 0) * 32
      for y = 0, 7 do
        for x = 0, 7 do
          local byteIndex = tileOff + y * 4 + math.floor(x / 2)
          local idx = tileIndex and nybble(byteIndex, x % 2 == 1) or 0
          local px = tx * 8 + x
          local py = ty * 8 + y
          pixels[py * width + px + 1] = idx
        end
      end
    end
  end
  return pixels
end

local function load_frame_bytes(rom, dataPtr, nbytes)
  local off = gba_off(dataPtr)
  if not off then return nil end
  -- Uncompressed OW pics are the common case; try raw first.
  local raw = rom:readBytes(off, nbytes)
  if type(raw) == "table" then
    local s = {}
    for i = 1, nbytes do s[i] = string.char(raw[i] or 0) end
    return table.concat(s)
  end
  if type(raw) == "string" and #raw >= nbytes then
    return raw:sub(1, nbytes)
  end
  -- LZ fallback
  local ok, dec = pcall(Lz77.decompress, function(i) return rom:get(i) end, off)
  if ok and dec then
    if type(dec) == "string" then return dec:sub(1, nbytes) end
    local s = {}
    local n = math.min(nbytes, dec._len or #dec)
    for i = 1, n do
      s[i] = string.char((dec._ffi and dec._ffi[i - 1]) or dec[i] or 0)
    end
    return table.concat(s)
  end
  return nil
end

--- Extract one graphicsId → { w, h, frameCount, frames (indexed), palette (BGR555) }.
function OwExtract.extractOne(rom, graphicsId, palsByTag, version, reflectionMappings)
  version = version or {}
  local pointers = version.ow_gfx_pointers or Versions.OW_GFX_POINTERS
  local num = version.num_obj_event_gfx or Versions.NUM_OBJ_EVENT_GFX
  graphicsId = tonumber(graphicsId) or 0
  if graphicsId < 0 or graphicsId >= num then
    return nil, "graphicsId out of range"
  end
  local infoPtr = rom:u32(pointers + graphicsId * 4)
  local infoOff = gba_off(infoPtr)
  if not infoOff then return nil, "bad info ptr" end
  local info = read_graphics_info(rom, infoOff)
  local w, h = info.width, info.height
  if w < 8 or h < 8 or w > 128 or h > 128 then
    return nil, "bad dimensions"
  end
  local imagesOff0 = gba_off(info.imagesPtr)
  local rawBytes = math.floor(w * h / 2)
  local exactFrames = sym_frame_count(imagesOff0)
  local frameCount = exactFrames
  if not frameCount then
    local starts = pic_table_starts(rom, pointers, num)
    frameCount = imagesOff0 and pic_table_len(rom, imagesOff0, rawBytes, starts) or 0
  end
  if frameCount < 1 then frameCount = 1 end

  -- For Town Map (OBJ_EVENT_GFX_TOWN_MAP = 93) or 16x16 inanimate objects with 32x16 OAM allocation:
  -- The sprite is a 16x16 tile image on the left; adjust width to 16 for proper 1:1 tile grid alignment.
  if info.inanimate and w == 32 and h == 16 then
    w = 16
  end

  local imagesOff = gba_off(info.imagesPtr)
  if not imagesOff then return nil, "bad images ptr" end
  local layout = read_subsprite_layout(rom, info.subspriteTablesPtr, w, h)

  local expected = math.floor(w * h / 2)
  local frames = {}
  for i = 0, frameCount - 1 do
    local dataPtr = rom:u32(imagesOff + i * 8)
    local frameSize = rom:u16(imagesOff + i * 8 + 4)
    local foreign = exactFrames and frameSize ~= rawBytes
    if frameSize < 1 then frameSize = expected end
    if frameSize > expected * 4 then frameSize = expected end
    local bytes = not foreign and load_frame_bytes(rom, dataPtr, math.max(frameSize, expected))
    if not bytes or #bytes < expected then
      -- pad / blank
      frames[i + 1] = {}
      for p = 1, w * h do frames[i + 1][p] = 0 end
    else
      frames[i + 1] = decode_frame_4bpp(bytes, w, h, layout)
    end
  end

  local pal = palsByTag and palsByTag[info.paletteTag]
  if not pal then
    pal = {}
    for c = 0, 15 do pal[c] = 0 end
  end
  local rawReflectPal = palsByTag and palsByTag[info.reflectionPaletteTag] or nil
  local reflectTag = rawReflectPal and OwExtract.reflectionPaletteTag(info, reflectionMappings) or nil
  local reflectPal = reflectTag and palsByTag and palsByTag[reflectTag] or nil

  return {
    graphicsId = graphicsId,
    width = w,
    height = h,
    frameCount = frameCount,
    frames = frames,
    paletteTag = info.paletteTag,
    palette = pal,
    reflectionPaletteTag = info.reflectionPaletteTag,
    paletteSlot = info.paletteSlot,
    reflectionPaletteMappedTag = reflectTag,
    reflectionPalette = rawReflectPal,
    mappedReflectionPalette = reflectPal,
    inanimate = info.inanimate,
    drawOffX = layout and layout.offX or 0,
    drawOffY = layout and layout.offY or 0,
  }
end

--- Bake frames stacked vertically → RGBA8 string + meta.
function OwExtract.bakeRgba(sprite)
  local w, h = sprite.width, sprite.height
  local n = sprite.frameCount
  local pal = sprite.palette
  local rgb = {}
  for c = 0, 15 do
    local r, g, b = bgr555_to_rgb8(pal[c] or 0)
    rgb[c] = { r, g, b }
  end
  local chunks = {}
  for fi = 1, n do
    local frame = sprite.frames[fi]
    for py = 0, h - 1 do
      local line = {}
      for px = 0, w - 1 do
        local idx = frame[py * w + px + 1] or 0
        if idx == 0 then
          line[px + 1] = string.char(0, 0, 0, 0)
        else
          local c = rgb[idx] or rgb[0]
          line[px + 1] = string.char(c[1], c[2], c[3], 255)
        end
      end
      chunks[#chunks + 1] = table.concat(line)
    end
  end
  return table.concat(chunks), w, h * n
end

function OwExtract.encodeMeta(sprite)
  local out = {
    OwExtract.MAGIC,
    u8(OwExtract.FORMAT_VERSION),
    u8(sprite.inanimate and 1 or 0),
    u16le(sprite.graphicsId),
    u16le(sprite.width),
    u16le(sprite.height),
    u16le(sprite.frameCount),
    u16le(sprite.paletteTag or 0),
    u16le(sprite.reflectionPaletteTag or PALETTE_TAG_NONE),
    u8(sprite.paletteSlot or 0xFF),
    u16le(sprite.reflectionPaletteMappedTag or PALETTE_TAG_NONE),
    u8((sprite.reflectionPalette and 1 or 0) + (sprite.mappedReflectionPalette and 2 or 0)),
  }
  for c = 0, 15 do out[#out + 1] = u16le(sprite.palette and sprite.palette[c] or 0) end
  for c = 0, 15 do out[#out + 1] = u16le(sprite.reflectionPalette and sprite.reflectionPalette[c] or 0) end
  for c = 0, 15 do out[#out + 1] = u16le(sprite.mappedReflectionPalette and sprite.mappedReflectionPalette[c] or 0) end
  out[#out + 1] = u8(sprite.drawOffX or 0)
  out[#out + 1] = u8(sprite.drawOffY or 0)
  return table.concat(out)
end

function OwExtract.decodeMeta(blob)
  if type(blob) ~= "string" or #blob < 12 or blob:sub(1, 4) ~= OwExtract.MAGIC then
    return nil, "bad ow meta"
  end
  local meta = {
    formatVersion = blob:byte(5),
    inanimate = blob:byte(6) == 1,
    graphicsId = read_u16(blob, 7),
    width = read_u16(blob, 9),
    height = read_u16(blob, 11),
    frameCount = read_u16(blob, 13),
    paletteTag = read_u16(blob, 15),
  }
  if meta.formatVersion >= 2 and #blob >= 118 then
    meta.reflectionPaletteTag = read_u16(blob, 17)
    meta.paletteSlot = blob:byte(19)
    meta.reflectionPaletteMappedTag = read_u16(blob, 20)
    local flags = blob:byte(22)
    meta.palette = {}
    meta.reflectionPalette = {}
    meta.mappedReflectionPalette = {}
    local off = 23
    for c = 0, 15 do meta.palette[c] = read_u16(blob, off); off = off + 2 end
    for c = 0, 15 do meta.reflectionPalette[c] = read_u16(blob, off); off = off + 2 end
    for c = 0, 15 do meta.mappedReflectionPalette[c] = read_u16(blob, off); off = off + 2 end
    if flags % 2 == 0 then meta.reflectionPalette = nil end
    if math.floor(flags / 2) % 2 == 0 then meta.mappedReflectionPalette = nil end
    if meta.reflectionPaletteTag == PALETTE_TAG_NONE then meta.reflectionPaletteTag = nil end
    if meta.reflectionPaletteMappedTag == PALETTE_TAG_NONE then meta.reflectionPaletteMappedTag = nil end
  end
  meta.drawOffX, meta.drawOffY = 0, 0
  if meta.formatVersion >= 4 and #blob >= 120 then
    local function s8(v) return v >= 128 and v - 256 or v end
    meta.drawOffX, meta.drawOffY = s8(blob:byte(119)), s8(blob:byte(120))
  end
  return meta
end

--- Collect every OBJ_EVENT_GFX id (0 .. NUM-1).
function OwExtract.collectAllIds(version)
  version = version or {}
  local num = version.num_obj_event_gfx or Versions.NUM_OBJ_EVENT_GFX or 152
  local list = {}
  for g = 0, num - 1 do
    list[#list + 1] = g
  end
  return list
end

--- Collect graphicsIds used on Island 1 (+ player Red/Green).
function OwExtract.collectIsland1Ids(rom, version)
  local ids = { [0] = true, [7] = true } -- player
  local ok, events = pcall(ExtractMapEvents.extractIsland1, rom, version)
  if ok and events then
    local byMap = events
    for _, ev in pairs(type(byMap) == "table" and byMap or {}) do
      if type(ev) == "table" and ev.objects then
        for _, obj in ipairs(ev.objects) do
          local g = tonumber(obj.graphicsId or obj.graphics)
          if g then ids[g] = true end
        end
      end
    end
  end
  for _, g in ipairs({
    16, 19, 22, 24, 30, 32, 35, 39, 40, 43, 44, 45, 46, 54, 56, 57,
    62, 64, 65, 69, 73, 89, 92, 96, 108,
  }) do
    ids[g] = true
  end
  local list = {}
  for g in pairs(ids) do list[#list + 1] = g end
  table.sort(list)
  return list
end

-- pokeemerald/src/field_player_avatar.c:234
function OwExtract.readAvatars(rom, spec)
  spec = spec or Versions.PLAYER_AVATAR_GFX
  if not spec then return nil end
  local genders = spec.genders
  local function pair(off)
    if not off then return nil end
    return { male = rom:get(off), female = rom:get(off + 1) }
  end
  local function states(off, n)
    local out = {}
    for s = 0, n - 1 do
      out[s + 1] = pair(off + s * genders)
      out[s + 1].state = spec.stateNames[s + 1] or tostring(s)
    end
    return out
  end
  local flags = { male = {}, female = {} }
  for g, key in ipairs({ "male", "female" }) do
    local base = spec.state_flags + (g - 1) * spec.state_flag_count * 2
    for i = 0, spec.state_flag_count - 1 do
      flags[key][i + 1] = { gfx = rom:get(base + i * 2), flag = rom:get(base + i * 2 + 1) }
    end
  end
  return {
    player = states(spec.player, spec.player_states),
    rival = states(spec.rival, spec.rival_states),
    linkFrlg = pair(spec.link_frlg),
    linkRs = pair(spec.link_rs),
    stateFlags = flags,
  }
end

local function avatar_lines(av)
  local out = { "  avatars = {\n" }
  for _, key in ipairs({ "player", "rival" }) do
    out[#out + 1] = ("    %s = {\n"):format(key)
    for _, r in ipairs(av[key]) do
      out[#out + 1] = ("      { state = %q, male = %d, female = %d },\n"):format(r.state, r.male, r.female)
    end
    out[#out + 1] = "    },\n"
  end
  for _, key in ipairs({ "linkFrlg", "linkRs" }) do
    if av[key] then
    out[#out + 1] = ("    %s = { male = %d, female = %d },\n"):format(key, av[key].male, av[key].female)
    end
  end
  out[#out + 1] = "    stateFlags = {\n"
  for _, g in ipairs({ "male", "female" }) do
    out[#out + 1] = ("      %s = {\n"):format(g)
    for _, r in ipairs(av.stateFlags[g]) do
      out[#out + 1] = ("        { gfx = %d, flag = %d },\n"):format(r.gfx, r.flag)
    end
    out[#out + 1] = "      },\n"
  end
  out[#out + 1] = "    },\n  },\n"
  return table.concat(out)
end

--- Write ow/* sheets. opts.all=true extracts every OBJ_EVENT_GFX (firered default).
function OwExtract.writeExtract(rom, cache, root, version, opts)
  root = root or "data/generated/gba"
  opts = opts or {}
  local owRoot = root .. "/ow"
  version = version or Versions.lookup(rom.md5) or {}
  local palsByTag = OwExtract.loadPaletteTable(rom, version)
  local reflectionMappings = OwExtract.loadReflectionMappings(rom, version.ow_reflection)
  local extractAll = opts.all
  if extractAll == nil then
    -- Standalone firered cache wants the full table; Island-1 demake can pass all=false.
    extractAll = (root:find("data/generated/gba", 1, true) ~= nil) or opts.firered == true
  end
  local ids = extractAll and OwExtract.collectAllIds(version)
    or OwExtract.collectIsland1Ids(rom, version)
  local manifest = {
    ow_version = Versions.OW_VERSION or 1,
    sprites = {},
  }
  local okCount = 0
  for _, gid in ipairs(ids) do
    local spr, err = OwExtract.extractOne(rom, gid, palsByTag, version, reflectionMappings)
    if spr then
      local rgba, aw, ah = OwExtract.bakeRgba(spr)
      local meta = OwExtract.encodeMeta(spr)
      cache:write(owRoot .. "/" .. gid .. ".meta", meta)
      cache:write(owRoot .. "/" .. gid .. ".rgba", rgba)
      manifest.sprites[gid] = {
        width = spr.width,
        height = spr.height,
        frameCount = spr.frameCount,
        paletteTag = spr.paletteTag,
        inanimate = spr.inanimate,
        atlasW = aw,
        atlasH = ah,
      }
      okCount = okCount + 1
    else
      print("[ow] skip gfx " .. tostring(gid) .. ": " .. tostring(err))
    end
  end
  local lines = {
    "return {\n",
    ("  ow_version = %d,\n"):format(manifest.ow_version),
    ("  count = %d,\n"):format(okCount),
    ("  total = %d,\n"):format(#ids),
    "  sprites = {\n",
  }
  for _, gid in ipairs(ids) do
    local s = manifest.sprites[gid]
    if s then
      lines[#lines + 1] = ("    [%d] = { width = %d, height = %d, frameCount = %d, paletteTag = %d, inanimate = %s, atlasW = %d, atlasH = %d },\n"):format(
        gid, s.width, s.height, s.frameCount, s.paletteTag,
        s.inanimate and "true" or "false", s.atlasW, s.atlasH)
    end
  end
  lines[#lines + 1] = "  },\n"
  local avatars = OwExtract.readAvatars(rom)
  if avatars then
    manifest.avatars = avatars
    lines[#lines + 1] = avatar_lines(avatars)
  end
  lines[#lines + 1] = "}\n"
  cache:write(owRoot .. "/manifest.lua", table.concat(lines))
  local paletteLines = {
    "return {\n",
    "  format_version = 1,\n",
    ("  meta_format_version = %d,\n"):format(OwExtract.FORMAT_VERSION),
    ("  count = %d,\n"):format(okCount),
    "  sprites = {\n",
  }
  for _, gid in ipairs(ids) do
    if manifest.sprites[gid] then
      paletteLines[#paletteLines + 1] = ("    [%d] = %d,\n"):format(gid, OwExtract.FORMAT_VERSION)
    end
  end
  paletteLines[#paletteLines + 1] = "  },\n}\n"
  cache:write(owRoot .. "/palette_manifest.lua", table.concat(paletteLines))
  print(string.format("[ow] extracted %d / %d object graphics → %s", okCount, #ids, owRoot))
  manifest.count = okCount
  manifest.total = #ids
  return manifest
end

function OwExtract.run(rom, cache, opts)
  opts = opts or {}
  local manifest = OwExtract.writeExtract(rom, cache, opts.cacheRoot, opts.version, { all = opts.all ~= false })
  if opts.strict ~= false and manifest.count ~= manifest.total then
    error(string.format("ow: extracted %d of %d object graphics", manifest.count, manifest.total), 0)
  end
  return { count = manifest.count, total = manifest.total, avatars = manifest.avatars ~= nil }
end

function OwExtract.ready(cache, root)
  root = root or "data/generated/gba"
  local manifest = cache and cache:read(root .. "/ow/manifest.lua")
  if type(manifest) ~= "string"
      or tonumber(manifest:match("ow_version%s*=%s*(%d+)")) ~= Versions.OW_VERSION then
    return false
  end
  if Versions.active() ~= "firered" and Versions.active() ~= "leafgreen" then return true end
  local paletteManifest = cache:read(root .. "/ow/palette_manifest.lua")
  if type(paletteManifest) ~= "string"
      or tonumber(paletteManifest:match("meta_format_version%s*=%s*(%d+)")) ~= OwExtract.FORMAT_VERSION then
    return false
  end
  local expected = tonumber(manifest:match("count%s*=%s*(%d+)"))
  local total = tonumber(manifest:match("total%s*=%s*(%d+)"))
  if not expected or expected < 1 or expected ~= total
      or tonumber(paletteManifest:match("count%s*=%s*(%d+)")) ~= expected then
    return false
  end
  local seen, count = {}, 0
  for gidText, formatText in paletteManifest:gmatch("%[%s*(%d+)%s*%]%s*=%s*(%d+)%s*,") do
    local gid, formatVersion = tonumber(gidText), tonumber(formatText)
    if formatVersion ~= OwExtract.FORMAT_VERSION or seen[gid]
        or not manifest:find("[" .. gid .. "] = {", 1, true) then
      return false
    end
    local blob = cache:read(root .. "/ow/" .. gid .. ".meta")
    local meta = OwExtract.decodeMeta(blob)
    if type(blob) ~= "string" or #blob < 118 or not meta
        or meta.formatVersion ~= OwExtract.FORMAT_VERSION or meta.graphicsId ~= gid then
      return false
    end
    seen[gid] = true
    count = count + 1
  end
  return count == expected
end

return OwExtract
