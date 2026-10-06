local Versions = require("src.import.gba.versions")
local G = require("src.import.gba.rse.sprite_gfx")

local BerryTreeGfx = {}

BerryTreeGfx.CACHE_SUB = "berry_trees"
BerryTreeGfx.FORMAT = 1
BerryTreeGfx.REQUIRED = { "berry_trees/manifest.lua" }

local PIC_PREFIX = "sPicTable_"
local FRAME_W = 16

local function root(opts)
  return ((opts and opts.cacheRoot) or "data/generated/gba") .. "/" .. BerryTreeGfx.CACHE_SUB
end

local function slotPalettes(rom, V)
  local byTag = G.objectEventPalettes(rom, V.OW_SPRITE_PALETTES, V.OW_SPRITE_PALETTE_COUNT)
  local slots = {}
  for i = 0, V.OBJ_PALETTE_SLOT_COUNT - 1 do
    local tag = rom:u16(V.OBJ_PALETTE_SLOT_TAGS + i * 2)
    slots[i] = { tag = tag, off = byTag[tag] }
  end
  return slots
end

-- pokeemerald/src/event_object_movement.c:1890
function BerryTreeGfx.run(rom, cache, opts)
  local V = Versions
  local B = V.BERRY_TREE_GFX
  local S = V.SYMS
  local dir = root(opts)
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local slots = slotPalettes(rom, V)
  local palettes = {}
  local trees = {}
  local animCache = {}
  local written, rgbaFiles = {}, {}

  local function animsFor(gfxId)
    if animCache[gfxId] then return animCache[gfxId] end
    local info = G.ptr(rom, V.OW_GFX_POINTERS + gfxId * 4)
    local anims = {}
    if info then
      local a = G.ptr(rom, info + 24)
      if a then anims = G.readAnimTable(rom, S, a, B.stages) end
    end
    animCache[gfxId] = anims
    return anims
  end

  for i = 0, B.count - 1 do
    local picTable = G.ptr(rom, B.pics + i * 4)
    local slotTable = G.ptr(rom, B.palette_slots + i * 4)
    local gfxTable = G.ptr(rom, B.gfx_ids + i * 4)
    if picTable and slotTable and gfxTable then
      local symbol = G.symName(S, picTable, PIC_PREFIX) or string.format("berry_tree_%d", i + 1)
      local name = G.snake(symbol:gsub("^" .. PIC_PREFIX, ""):gsub("BerryTree$", ""))
      local size = G.symSize(S, picTable)
      local nFrames = size and math.floor(size / 8) or 0
      local frames, y = {}, 0
      local pix = {}
      for f = 0, nFrames - 1 do
        local data = G.ptr(rom, picTable + f * 8)
        local bytes = rom:u16(picTable + f * 8 + 4)
        if not data then break end
        local fh = bytes * 2 / FRAME_W
        G.decodeTiles(rom, data, FRAME_W, fh, pix, y, FRAME_W)
        frames[#frames + 1] = { y = y, w = FRAME_W, h = fh, pic = G.symName(S, data) }
        y = y + fh
      end
      local stages = {}
      local frameSlot = {}
      for s = 0, B.stages - 1 do
        local slot = rom:get(slotTable + s)
        local gfxId = rom:get(gfxTable + s)
        local anim = animsFor(gfxId)[s + 1] or {}
        local seq = {}
        for _, c in ipairs(anim) do
          if c[1] == "frame" then
            seq[#seq + 1] = { frame = c[2], duration = c[3] }
            if frameSlot[c[2]] == nil then frameSlot[c[2]] = slot end
          end
        end
        stages[s + 1] = { paletteSlot = slot, gfxId = gfxId, anim = seq }
        if not palettes[slot] and slots[slot] and slots[slot].off then
          local p = G.readPalette(rom, slots[slot].off)
          local colors = {}
          for c = 0, 15 do colors[c + 1] = p[c] end
          palettes[slot] = { tag = slots[slot].tag, symbol = G.symName(S, slots[slot].off), colors = colors, raw = p }
        end
      end
      local n = FRAME_W * y
      for k = 1, n do pix[k] = pix[k] or 0 end
      local fresh = not written[name]
      written[name] = true
      if fresh then cache:write(dir .. "/" .. name .. ".idx", G.idxString(pix, n)) end
      local rgba, sig = {}, {}
      for f, fr in ipairs(frames) do
        local slot = frameSlot[f - 1] or stages[#stages].paletteSlot
        local pal = palettes[slot] and palettes[slot].raw or {}
        local part = {}
        for k = 1, FRAME_W * fr.h do part[k] = pix[fr.y * FRAME_W + k] end
        rgba[f] = G.rgbaString(part, FRAME_W * fr.h, pal)
        fr.paletteSlot = slot
        sig[f] = slot
      end
      sig = table.concat(sig, "")
      rgbaFiles[name] = rgbaFiles[name] or {}
      local file = rgbaFiles[name][sig]
      if not file then
        local nth = 0
        for _ in pairs(rgbaFiles[name]) do nth = nth + 1 end
        file = nth == 0 and (name .. ".rgba") or string.format("%s_%d.rgba", name, nth + 1)
        rgbaFiles[name][sig] = file
        cache:write(dir .. "/" .. file, table.concat(rgba))
      end
      trees[i + 1] = {
        berry = i + 1,
        sheet = name,
        symbol = symbol,
        file = file,
        idx = name .. ".idx",
        width = FRAME_W,
        height = y,
        frames = frames,
        stages = stages,
      }
    end
  end

  local palOut = {}
  for slot, p in pairs(palettes) do
    palOut[slot] = { tag = p.tag, symbol = p.symbol, colors = p.colors }
  end
  cache:write(dir .. "/manifest.lua", "return " .. serialize({
    format = BerryTreeGfx.FORMAT,
    count = #trees,
    trees = trees,
    palettes = palOut,
  }) .. "\n")
  print(string.format("[berry_trees] %d trees -> %s", #trees, dir))
  return { trees = #trees }
end

function BerryTreeGfx.ready(cache, cacheRoot)
  local body = cache and cache.read and cache:read(root({ cacheRoot = cacheRoot }) .. "/manifest.lua")
  if type(body) ~= "string" or #body == 0 then return false end
  local ok, m = pcall(load(body, "=berry_trees", "t", {}) or error)
  return ok and type(m) == "table" and m.format == BerryTreeGfx.FORMAT and m.count == Versions.BERRY_TREE_GFX.count
end

return BerryTreeGfx
