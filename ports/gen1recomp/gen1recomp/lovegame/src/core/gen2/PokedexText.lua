-- Projects a mod's `pokemon` registry dexEntry onto the #DEX screen's own
-- data table.
--
-- data.gen2Pokedex.entries[species] (data/generated/pokedex.lua,
-- RomExtractorGen2:extractPokedex) is what src/ui/gen2/PokedexMenu.lua
-- actually reads for the KIND label and the two description pages
-- (entry.kind, entry.text, entry.text2) -- a table loaded straight from
-- disk in Game2:load, BEFORE mods:load runs, and never routed through a
-- registry.  The `pokemon` registry's own merge target is the separate
-- data.pokemon table (src/mods/Schemas.lua, R.pokemon: `target = "pokemon"`),
-- which mod.content.pokemon:patch(id, { dexEntry = { kind = ..., text = ...,
-- text2 = ... } }) already reaches -- so a translation mod's #DEX text was
-- silently invisible in-game despite validating against the registry.
--
-- This is the missing link: called once after the merge (src/core/Game2.lua),
-- the same way ItemEffects.applyHeldItems projects held_items onto
-- data.gen2HeldItems.  height/weight/dex stay untouched -- game state, not
-- text a translation carries.
local PokedexText = {}

function PokedexText.apply(data)
  local dex = data and data.gen2Pokedex
  local pokemon = data and data.pokemon
  if not (dex and dex.entries and pokemon) then return 0 end
  local count = 0
  for species, entry in pairs(dex.entries) do
    local def = pokemon[species]
    local override = def and def.dexEntry
    if override and (override.kind or override.text or override.text2) then
      if override.kind then entry.kind = override.kind end
      if override.text then entry.text = override.text end
      if override.text2 then entry.text2 = override.text2 end
      count = count + 1
    end
  end
  return count
end

return PokedexText
