-- Fly destination picker: visited towns, landing at the real fly-warp
-- spots from data/maps/special_warps.asm.

local ListMenu = require("src.ui.ListMenu")
local Map = require("src.world.Map")
local Strings = require("src.core.Strings")

local FlyMenu = { isMenu = true }

function FlyMenu.new(game)
  local items = {}
  local visited = game.save.visited or {}
  local seen = {}
  for _, mapId in ipairs(game.data.field.flyOrder or {}) do
    -- towns only (dungeon escape spots share the table), each listed once.
    -- Map.isFlyTown is the BuildFlyLocationsList gate: map ids 0..10, so
    -- INDIGO_PLATEAU cycles like any town (#203) while the ROUTE_4/ROUTE_10
    -- Pokemon Centers, fly warps but not towns, stay out (#788).
    local def = game.data.maps[mapId]
    if visited[mapId] and def and not seen[mapId] and Map.isFlyTown(def) then
      seen[mapId] = true
      table.insert(items, {
        value = mapId,
        label = Strings(mapId:gsub("_", " ")),
      })
    end
  end
  local menu = ListMenu.new(game, Strings.source("FLY TO?"), items, {
    onChoose = function(item, list)
      list:close()
      game.overworld:flyTo(item.value)
    end,
  })
  menu.isMenu = true
  return menu
end

return FlyMenu
