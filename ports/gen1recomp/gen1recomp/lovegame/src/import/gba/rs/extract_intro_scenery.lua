local K = require("src.import.gba.rse.boot_gfx")
local Versions = require("src.import.gba.versions")
local M = { SUB = "intro/rs/scenery" }
local C = ""
-- pokeruby/src/intro_credits_graphics.c:313
M.LAYERS = {
  { "grass", "gUnknown_0841225C", "gUnknown_084126DC", 15, { { "day", "gUnknown_084121FC" }, { "sunset", "gUnknown_0841221C" }, { "night", "gUnknown_0841223C" } } },
  { "clouds", "gUnknown_084128D8", "gUnknown_08412EB4", 0, { { "day", "gUnknown_08412818" }, { "sunset", "gUnknown_08412878" } }, halves = true },
  { "trees", "gUnknown_08413340", "gUnknown_084139C8", 0, { { "day", "gUnknown_08413300" }, { "sunset", "gUnknown_08413320" } }, halves = true },
  { "houses", "gUnknown_08413E78", "gUnknown_08414084", 0, { { "night", "gUnknown_08413E38" } }, halves = true },
}
M.SCENERY = {
  { "moving_clouds", "gUnknown_084131C4", "gSpriteAnimTable_8416B84", "gUnknown_08416B94", { { "day", "gUnknown_08413184" }, { "sunset", "gUnknown_084131A4" } } },
  { "moving_trees", "gIntro2TreeTiles", "gSpriteAnimTable_8416C04", "gUnknown_08416C10", { { "day", "gUnknown_08413CCC" }, { "sunset", "gUnknown_08413320" } } },
  { "moving_houses", "gIntro2NightTiles", "gSpriteAnimTable_8416C88", "gUnknown_08416C8C", { { "night", "gUnknown_08414064" } } },
}
M.SPRITES = {
  { "brendan", "gSpriteTemplate_8416CDC", "gIntro2BrendanTiles", "gIntro2BrendanPalette", rider = true },
  { "may", "gSpriteTemplate_8416CF4", "gIntro2MayTiles", "gIntro2MayPalette", rider = true },
  { "bicycle", "gSpriteTemplate_Brendan", "gIntro2BicycleTiles", "gIntro2BrendanPalette" },
  { "latios", "gSpriteTemplate_8416D7C", "gIntro2LatiosTiles", "gIntro2LatiosPalette" },
  { "latias", "gSpriteTemplate_8416D94", "gIntro2LatiasTiles", "gIntro2LatiasPalette" },
}
M.FILES = {}
for _, l in ipairs(M.LAYERS) do
  for half = 0, l.halves and 1 or 0 do
    local key = l[1] .. (l.halves and ("_bg" .. (3 - half)) or "")
    for _, v in ipairs(l[5]) do M.FILES[#M.FILES + 1] = key .. "_" .. v[1] .. ".png" end
    M.FILES[#M.FILES + 1] = key .. "_idx.png"
  end
end
for _, s in ipairs(M.SCENERY) do for _, v in ipairs(s[5]) do M.FILES[#M.FILES + 1] = s[1] .. "_" .. v[1] .. ".png" end end
for _, s in ipairs(M.SPRITES) do M.FILES[#M.FILES + 1] = s[1] .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)

function M.run(rom, cache, opts)
  local game = rom.id
  assert(game == "ruby" or game == "sapphire", "RS scenery needs native RS assets")
  local c = K.contextWith(rom, cache, opts or {}, M.SUB, Versions.SYMS, game)
  local layers, scenery, sprites, palettes = {}, {}, {}, {}
  local function pal(name, bank)
    local n = c.S.size(C .. name) / 2
    local p = c:pal(C .. name, n, nil, (bank or 0) * 16)
    palettes[name] = K.palList(p, (bank or 0) * 16, n)
    return p
  end
  for _, l in ipairs(M.LAYERS) do
    for half = 0, l.halves and 1 or 0 do
      local key = l[1] .. (l.halves and ("_bg" .. (3 - half)) or "")
      local variants = {}; for _, v in ipairs(l[5]) do variants[#variants + 1] = { name = v[1], pal = pal(v[2], l[4]) } end
      local idx, w, h = K.bakeText(c:lz(C .. l[2]), c:lz(C .. l[3]), 32, 32, { mapOffset = half * 1024 })
      layers[key] = c:layer({ key = key, indexMap = true, variants = variants }, idx, w, h)
    end
  end
  -- pokeruby/src/intro_credits_graphics.c:28
  for _, s in ipairs(M.SCENERY) do
    local anims = c:readAnimTable(c:off(C .. s[3]), c.S.size(C .. s[3]) / 4, "intro_credits_graphics.o")
    local rows, off = {}, c:off(C .. s[4])
    for i = 0, c.S.size(C .. s[4]) / 8 - 1 do
      local o = off + i * 8; local b = c:u8(o)
      local shape, size = math.floor(b / 16) % 4, math.floor(b / 64) % 4
      local w, h = K.objDims(shape, size)
      rows[#rows + 1] = { animNum = b % 16, shape = shape, size = size, w = w, h = h,
        x = c:u8(o + 1), y = c:u8(o + 2), subpriority = c:u8(o + 3), xOff = c:u16(o + 4) }
    end
    local frames = {}
    for ai, anim in ipairs(anims) do
      local dims; for _, r in ipairs(rows) do if r.animNum == ai - 1 then dims = r; break end end
      if dims then for _, cmd in ipairs(anim) do if cmd.op == "frame" then
        frames[#frames + 1] = { tile = cmd.tile, w = dims.w, h = dims.h, anim = ai - 1 }
      end end end
    end
    local variants = {}; for _, v in ipairs(s[5]) do variants[#variants + 1] = { name = v[1], pal = pal(v[2]) } end
    local e = c:atlas(s[1], c:lz(C .. s[2]), frames, K.variants(variants))
    for i, fr in ipairs(frames) do e.rects[i].anim = fr.anim end
    e.anims, e.sprites = anims, rows; scenery[s[1]] = e
  end
  for _, s in ipairs(M.SPRITES) do
    local tpl = c:readTemplate(C .. s[2])
    if s.rider then tpl.anims = c:readAnimTable(c:off("intro.o:gUnknown_0840AE80"), 4, "intro.o") end
    local e = c:spriteFrames(s[1], c:lz(C .. s[3]), tpl, pal(s[4]))
    e.tileTag, e.paletteTag, e.shape, e.size = tpl.tileTag, tpl.paletteTag, tpl.oam.shape, tpl.oam.size
    sprites[s[1]] = e
  end
  return true, c:finish({ screen = "intro_credits_scenery", layout = "rs", build = Versions.BUILD,
    layers = layers, scenery = scenery, sprites = sprites, palettes = palettes })
end
function M.ready(cache, cacheRoot)
  if not K.ready(M.SUB, cache, cacheRoot) then return false end
  local body = cache:read((cacheRoot or "data/generated/gba") .. "/" .. M.SUB .. "/manifest.lua")
  return type(body) == "string" and body:find('layout = "rs"', 1, true) ~= nil
end
return M
