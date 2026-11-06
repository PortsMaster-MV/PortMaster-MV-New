-- Whether a Pokémon's level is printed on a screen that would normally
-- print it (RFC 0019).
--
-- Every Gen 1 screen that shows a level does it with the same pokered rule
-- -- home/pokemon.asm:335-345 PrintLevel: the <LV> tile, then the digits
-- left-aligned after it, with a level of 100 writing its third digit back
-- over the tile -- and each screen hand-rolls that rule against its own
-- coordinates. This module does not touch any of that. It answers one
-- question, in one place, so that a mode which wants the number off does
-- not have to know four call sites and a glyph code.
--
-- Default is true, and `Runtime.wantsHook` is checked first, so a build
-- with no mod wrapping the hook prints exactly what it always did and pays
-- nothing for the seam on a per-frame draw path.
--
-- `where` names the surface rather than the widget, because the number
-- means different things on different screens: on the battle HUD an
-- opponent's level is information about them, on the party and status
-- screens your own level is information about you. A mode can hide one and
-- keep the other.

local Runtime = require("src.mods.Runtime")

local LevelDisplay = {}

-- where: "battle.enemy" | "battle.player" | "party" | "summary"
function LevelDisplay.visible(mon, where, game)
  if not Runtime.wantsHook("pokemon.level_visible") then return true end
  return Runtime.call("pokemon.level_visible", function() return true end,
                      mon, { where = where, game = game }) ~= false
end

return LevelDisplay
