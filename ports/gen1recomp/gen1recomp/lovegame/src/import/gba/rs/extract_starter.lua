local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = { SUB = "starter_choose", FILES = { "grass.png", "bag.png", "pokeball.png", "hand.png", "circle.png" } }
M.REQUIRED = K.required(M.SUB, M.FILES)
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- pokeruby/src/starter_choose.c:264
  local p, gfx = c:pal("gBirchBagGrassPal", 32), c:lz("gBirchHelpGfx")
  local layers = {}
  for _, row in ipairs({{"grass", "gBirchGrassTilemap", 2, 3}, {"bag", "gBirchBagTilemap", 3, 1}}) do
    local idx, w, h = K.bakeText(gfx, c:lz(row[2]), 32, 20)
    layers[row[1]] = c:layer({ key = row[1], opaque = row[1] == "grass", indexMap = true }, idx, w, h, p)
    layers[row[1]].bg, layers[row[1]].priority = row[3], row[4]
  end
  local sel, pal = c:lz("gBirchBallarrow_Gfx"), c:pal("gBirchBallarrow_Pal", 16)
  local sprites = { pokeball = c:spriteFrames("pokeball", sel, c:readTemplate("gSpriteTemplate_83F77E4"), pal),
    hand = c:spriteFrames("hand", sel, c:readTemplate("gSpriteTemplate_83F77CC"), pal),
    circle = c:spriteFrames("circle", c:lz("gBirchCircle_Gfx"), c:readTemplate("gSpriteTemplate_83F77FC"), c:pal("gBirchCircle_Pal", 16)) }
  local species, off = {}, c:off("sStarterMons")
  for i = 0, c.S.count("sStarterMons", 2) - 1 do species[i + 1] = c:u16(off + i * 2) end
  return A.finish(c, { screen = "starter_choose", layers = layers, sprites = sprites, species = species,
    pokeballCoords = A.pairs(c, "gStarterChoose_PokeballCoords"), labelCoords = A.pairs(c, "gStarterChoose_LabelCoords"),
    cursorCoords = A.pairs(c, "gUnknown_083F76E4"), palettes = {bg = K.palList(p, 0, 32)},
    affine = { pokemon = A.affine(c, "gSpriteAffineAnim_83F775C"), circle = A.affine(c, "gSpriteAffineAnim_83F7774") } })
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
