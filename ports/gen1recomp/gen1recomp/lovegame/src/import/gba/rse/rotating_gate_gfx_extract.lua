local Versions = require("src.import.gba.versions")
local G = require("src.import.gba.rse.sprite_gfx")

local RotatingGateGfx = {}

RotatingGateGfx.CACHE_SUB = "rotating_gates"
RotatingGateGfx.FORMAT = 1
RotatingGateGfx.REQUIRED = { "rotating_gates/manifest.lua" }

local function root(opts)
  return ((opts and opts.cacheRoot) or "data/generated/gba") .. "/" .. RotatingGateGfx.CACHE_SUB
end

-- pokeemerald/src/rotating_gate.c:182
local function readPuzzle(rom, spec)
  local out = {}
  for i = 0, spec.count - 1 do
    local b = spec.off + i * 8
    local x, y = rom:u16(b), rom:u16(b + 2)
    if x >= 0x8000 then x = x - 0x10000 end
    if y >= 0x8000 then y = y - 0x10000 end
    out[i + 1] = { x = x, y = y, shape = rom:get(b + 4), orientation = rom:get(b + 5) }
  end
  return out
end

-- pokeemerald/src/rotating_gate.c:819
function RotatingGateGfx.run(rom, cache, opts)
  local V = Versions
  local R = V.ROTATING_GATE
  local S = V.SYMS
  local dir = root(opts)
  local serialize = require("src.import.gba.extract_scripts").serialize_lua

  local byTag = G.objectEventPalettes(rom, V.OW_SPRITE_PALETTES, V.OW_SPRITE_PALETTE_COUNT)
  local templates = {}
  for _, off in ipairs(R.templates) do
    local t = G.readTemplate(rom, S, off)
    templates[#templates + 1] = { symbol = G.symName(S, off), oam = t.oam, tileTag = t.tileTag, anims = t.anims }
  end

  local sheets, baseTag = {}, nil
  local palettes = {}
  for i = 0, R.sheet_count - 1 do
    local b = R.sheets + i * 8
    local data = G.ptr(rom, b)
    if not data then break end
    local size = rom:u16(b + 4)
    local tag = rom:u16(b + 6)
    baseTag = baseTag or tag
    local tpl
    for _, t in ipairs(templates) do
      if t.oam.w * t.oam.h / 2 == size then tpl = t end
    end
    assert(tpl, "rotating gate sheet " .. i .. " matches no sprite template size")
    local fw, fh = tpl.oam.w, tpl.oam.h
    local slot = tpl.oam.paletteNum
    local slotTag = rom:u16(V.OBJ_PALETTE_SLOT_TAGS + slot * 2)
    local palOff = byTag[slotTag]
    local pix = G.decodeTiles(rom, data, fw, fh, {}, 0, fw)
    local shape = tag - baseTag
    local name = "gate_" .. shape
    cache:write(dir .. "/" .. name .. ".idx", G.idxString(pix, fw * fh))
    local entry = {
      shape = shape, tag = tag, symbol = G.symName(S, data), file = name .. ".rgba", idx = name .. ".idx",
      w = fw, h = fh, template = tpl.symbol, paletteSlot = slot, paletteSlotTag = slotTag,
    }
    if palOff then
      local pal = G.readPalette(rom, palOff)
      cache:write(dir .. "/" .. name .. ".rgba", G.rgbaString(pix, fw * fh, pal))
      if not palettes[slot] then
        local colors = {}
        for c = 0, 15 do colors[c + 1] = pal[c] end
        palettes[slot] = { tag = slotTag, symbol = G.symName(S, palOff), colors = colors }
      end
    end
    sheets[#sheets + 1] = entry
  end

  local puzzles = {}
  for k, spec in pairs(R.puzzles) do puzzles[k] = readPuzzle(rom, spec) end
  local tplOut = {}
  for _, t in ipairs(templates) do
    tplOut[#tplOut + 1] = { symbol = t.symbol, w = t.oam.w, h = t.oam.h, priority = t.oam.priority,
      paletteSlot = t.oam.paletteNum, affineMode = t.oam.affineMode }
  end
  cache:write(dir .. "/manifest.lua", "return " .. serialize({
    format = RotatingGateGfx.FORMAT,
    count = #sheets,
    sheets = sheets,
    templates = tplOut,
    palettes = palettes,
    puzzles = puzzles,
  }) .. "\n")
  print(string.format("[rotating_gates] %d gate sheets -> %s", #sheets, dir))
  return { sheets = #sheets }
end

function RotatingGateGfx.ready(cache, cacheRoot)
  local body = cache and cache.read and cache:read(root({ cacheRoot = cacheRoot }) .. "/manifest.lua")
  if type(body) ~= "string" or #body == 0 then return false end
  local ok, m = pcall(load(body, "=rotating_gates", "t", {}) or error)
  return ok and type(m) == "table" and m.format == RotatingGateGfx.FORMAT
    and m.count == Versions.ROTATING_GATE.sheet_count - 1
end

return RotatingGateGfx
