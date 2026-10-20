local M = {}

-- pret/pokegold engine/overworld/overworld.asm:102,254; pokecrystal:120,170
function M.read(rom, symbols, constants, edition)
  local outdoor, sprites = symbols.OutdoorSprites, symbols.OverworldSprites
  if not outdoor or not sprites then return nil end
  local crystal = edition == "crystal"
  local data = { version = 1, edition = edition, rows = {}, outdoorGroups = {},
    capacity = crystal and 32 or 12, maxOutdoorSprites = crystal and 23 or 11 }
  for id = 1, assert(constants.numOverworldSprites) do
    local at = sprites[2] + (id - 1) * 6
    data.rows[id] = { length = rom:byte(sprites[1], at + 2) / 16,
      type = rom:byte(sprites[1], at + 4), palette = rom:byte(sprites[1], at + 5) }
  end
  local groups = 0
  for _, map in ipairs(constants.mapGroups or {}) do groups = math.max(groups, map.group or 0) end
  for group = 1, groups do
    local pointer = rom:word(outdoor[1], outdoor[2] + (group - 1) * 2)
    data.outdoorGroups[group] = rom:bytes(outdoor[1], pointer, data.maxOutdoorSprites)
  end
  return data
end

return M
