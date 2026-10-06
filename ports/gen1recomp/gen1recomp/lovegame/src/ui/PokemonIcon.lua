-- Public read-only Pokemon icon presentation for detached summaries.
-- Resolution and rendering deliberately stay engine-owned: PartyMenu already
-- composes content icon registrations, per-species definitions, asset
-- overrides, and the pokemon.icon hook in one canonical path.

local PartyMenu = require("src.ui.PartyMenu")

local PokemonIcon = {}

local function finite(value)
  return type(value) == "number" and value == value
    and value ~= math.huge and value ~= -math.huge
end

local function integer(value, minimum)
  return finite(value) and value % 1 == 0 and value >= minimum
end

function PokemonIcon.draw(game, summary, x, y, opts)
  opts = type(opts) == "table" and opts or {}
  if type(game) ~= "table" or type(summary) ~= "table"
      or type(summary.species) ~= "string" or summary.species == ""
      or not integer(summary.hp, 0) or not integer(summary.maxHp, 1)
      or summary.hp > summary.maxHp or not finite(x) or not finite(y)
      or (opts.selected ~= nil and type(opts.selected) ~= "boolean")
      or (opts.counter ~= nil and not finite(opts.counter)) then
    return false, "invalid_pokemon_preview",
      "Pokemon icon presentation needs species and valid captured HP values."
  end
  local ok, message = pcall(PartyMenu.drawIcon, game, {
    species = summary.species,
    hp = summary.hp,
    stats = { hp = summary.maxHp },
  }, x, y, opts.selected == true, opts.counter or 0)
  if not ok then
    return false, "pokemon_icon_failed", tostring(message)
  end
  return true
end

return PokemonIcon
