local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "intro/rse_extra"

local I = "intro.o:"

M.FILES = { "water_drop_ripple.png", "groudon_rocks.png" }
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/include/sprite.h:117
local function readAffineAnim(c, off)
  local cmds = {}
  for i = 0, 63 do
    local base = off + i * 8
    local t = c:s16(base)
    if t == 0x7FFF then
      cmds[#cmds + 1] = { op = "end" }
      break
    elseif t == 0x7FFE then
      cmds[#cmds + 1] = { op = "jump", target = c:s16(base + 2) }
      break
    elseif t == 0x7FFD then
      cmds[#cmds + 1] = { op = "loop", count = c:s16(base + 2) }
    else
      cmds[#cmds + 1] = {
        op = "frame", xScale = t, yScale = c:s16(base + 2),
        rotation = c:u8(base + 4), duration = c:u8(base + 5),
      }
    end
  end
  return cmds
end

local function readAffineTable(c, sym)
  local off, anims = c:off(sym), {}
  for i = 0, c.S.size(sym) / 4 - 1 do
    local p = c:ptr(off + i * 4)
    if p then anims[#anims + 1] = readAffineAnim(c, p) end
  end
  return anims
end

local function tagIndex(names, want)
  for i, n in pairs(names) do
    if n == want then return i end
  end
  error("extract_intro_extra: no battle anim tag " .. want)
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/intro.c:873
  local gfAffine = readAffineTable(c, I .. "sAffineAnims_GameFreak")

  -- pokeemerald/src/intro.c:657
  local bikeOff = c:off(I .. "sAnims_PlayerBicycle")
  local bike = c:readAnimTable(bikeOff, c.S.size(I .. "sAnims_PlayerBicycle") / 4, "intro.o")
  for _, anim in ipairs(bike) do
    for _, cmd in ipairs(anim) do
      if cmd.op == "frame" then cmd.frame = math.floor(cmd.tile / 64) end
    end
  end

  -- pokeemerald/src/intro.c:599
  local dropsPal = c:pal(I .. "sIntroDrops_Pal", 16)
  local ripple = c:strip("water_drop_ripple", c:lz(I .. "sIntroDropsLogo_Gfx"), 64, 32, 1, dropsPal, 4, 48)

  -- pokeemerald/src/intro.c:1783
  local Names = require("src.import.gba.anim_names_" .. c.game)
  local tag = tagIndex(Names.tagNames, "ROCKS")
  local picOff = c:off("gBattleAnimPicTable") + tag * 8
  local palOff = c:off("gBattleAnimPaletteTable") + tag * 8
  local rockGfx = c:lzAt(c:ptr(picOff))
  local rockPal = c:palFrom(c:lzAt(c:ptr(palOff)), 16)
  local rockTpl = c:readTemplate("gAncientPowerRockSpriteTemplate")
  local rocks = c:spriteFrames("groudon_rocks", rockGfx, rockTpl, rockPal)
  rocks.tileTag = c:u16(picOff + 6)

  return true, c:finish({
    screen = "intro_extra",
    gfAffineAnims = gfAffine,
    playerBicycleAnims = bike,
    waterDropRipple = ripple,
    groudonRocks = rocks,
    palettes = { rocks = K.palList(rockPal, 0, 16) },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
