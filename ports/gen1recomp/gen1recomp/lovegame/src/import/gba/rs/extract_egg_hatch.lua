local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "rse/rs_egg_hatch"}
M.FILES = {"textbox.gfx", "textbox.map", "shadow.gfx", "shadow.map", "egg.gfx", "shard.gfx"}
M.REQUIRED = K.required(M.SUB, M.FILES)

local function window(c, name)
  local out, off = {}, c:off(name)
  for i, key in ipairs({"bg", "charBase", "mapBase", "priority", "paletteNum", "fg", "background", "shadow",
    "font", "textMode", "spacing", "left", "top", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  return out
end
local function text(c, name)
  local out, off = {}, c:off(name)
  for i = 0, 1023 do
    local byte = c:u8(off + i); out[#out + 1] = byte
    if byte == 255 then return out end
  end
  error("native RS hatch text unterminated: " .. name)
end
local function template(c, name)
  local t = c:readTemplate("egg_hatch.o:" .. name)
  local tilesPerFrame = t.oam.w * t.oam.h / 64
  for _, anim in ipairs(t.anims) do
    for _, cmd in ipairs(anim) do if cmd.op == "frame" then cmd.frame = cmd.tile / tilesPerFrame end end
  end
  return t
end

-- pokeruby/src/egg_hatch.c:397
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local gfx, maps = {}, {}
  for key, spec in pairs({textbox = {"gBattleTextboxTiles", true},
    shadow = {"gUnknown_0820CA98", false, 0x1300},
    egg = {"egg_hatch.o:sEggHatchTiles", false, 2048},
    shard = {"egg_hatch.o:sEggShardTiles", false, 128}}) do
    local data = spec[2] and c:lz(spec[1]) or c:raw(spec[1], spec[3])
    c:write(key .. ".gfx", data); gfx[key] = {path = c:path(key .. ".gfx"), bytes = #data}
  end
  for key, spec in pairs({textbox = {"gBattleTextboxTilemap", 0x500}, shadow = {"gUnknown_0820F798", 0x1000}}) do
    local data = c:raw(spec[1], spec[2]); c:write(key .. ".map", data)
    maps[key] = {path = c:path(key .. ".map"), entries = #data / 2}
  end
  local velocities, off = {}, c:off("egg_hatch.o:sEggShardVelocities")
  for i = 0, c.S.count("egg_hatch.o:sEggShardVelocities", 4) - 1 do
    velocities[i] = {c:s16(off + i * 4), c:s16(off + i * 4 + 2)}
  end
  local frontY, sine = {}, {}
  off = c:off("gMonFrontPicCoords")
  for i = 0, c.S.count("gMonFrontPicCoords", 4) - 1 do frontY[i] = c:u8(off + i * 4 + 1) end
  off = c:off("gSineTable")
  for i = 0, c.S.count("gSineTable", 2) - 1 do sine[i] = c:s16(off + i * 2) end
  local textSpeedDelays, framePalettes = {}, {}
  off = c:off("text.o:sTextSpeedDelays")
  for i = 0, 2 do textSpeedDelays[i] = c:u8(off + i) end
  for i = 0, 19 do
    framePalettes[i] = K.palList(c:pal("gTextWindowFrame" .. (i + 1) .. "_Pal", 16), 0, 16)
  end
  local front = c:off("gSpriteTemplate_8208288") + 24 -- selector1, opponent/front template
  local fanfareFrames
  off = c:off("sound.o:sFanfares")
  for i = 0, c.S.count("sound.o:sFanfares", 4) - 1 do
    if c:u16(off + i * 4) == 371 then fanfareFrames = c:u16(off + i * 4 + 2) end
  end
  return A.finish(c, {screen = "egg_hatch", gfx = gfx, maps = maps, sine = sine,
    palettes = {textbox = K.palList(c:pal("gBattleTextboxPalette", 16, {}, 0, true), 0, 16),
      shadow = K.palList(c:pal("gUnknown_0820C9F8", 80), 0, 80),
      egg = K.palList(c:pal("egg_hatch.o:sEggPalette", 16), 0, 16),
      text = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16)},
    windows = {text = window(c, "gWindowTemplate_81E6F84"), menu = window(c, "gMenuTextWindowTemplate")},
    textSpeedDelays = textSpeedDelays, framePalettes = framePalettes,
    templates = {egg = template(c, "sSpriteTemplate_820A3C8"), shard = template(c, "sSpriteTemplate_820A418"),
      frontOam = c:readOam(assert(c:ptr(front + 4)))},
    frontAffine = {A.affineAt(c, c:off("gSpriteAffineAnim_81E7AA0"), 2),
      A.affineAt(c, c:off("gSpriteAffineAnim_81E7AC0"), 3)},
    frontY = frontY, shardVelocities = velocities,
    texts = {hatched = text(c, "gOtherText_HatchedFromEgg"), nickname = text(c, "gOtherText_NickHatchPrompt"),
      yes = text(c, "OtherText_Yes"), no = text(c, "OtherText_No")},
    bgControl = {[0] = 0x1F08, 0x0501, 0x4C06}, displayControl = 0x1740,
    songs = {intro = 376, evolution = 377, hatched = 371}, fanfareFrames = assert(fanfareFrames),
    geometry = {egg = {120, 75}, front = {120, 70}, shard = {120, 60}, text = {24, 120},
      yesNoFrame = {22, 8, 27, 13}, yesNoOrigin = {23, 9}, yesNoWidth = 4},
    coverage = "native_hatch_scene_assets_templates_and_metadata"})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
