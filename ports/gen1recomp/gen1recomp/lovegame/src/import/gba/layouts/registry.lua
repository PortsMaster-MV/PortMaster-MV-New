local GameVersion = require("src.core.GameVersion")

local Layouts = {}

local cache = {}

local function tryLoad(name)
  if type(name) ~= "string" or name == "" then return nil end
  local modName = "src.import.gba.layouts." .. name
  local ok, mod = pcall(require, modName)
  if ok and type(mod) == "table" then return mod end
  if not ok and not tostring(mod):find("module '" .. modName .. "' not found", 1, true) then
    error(mod, 0)
  end
  return nil
end

function Layouts.of(game)
  if cache[game] then return cache[game] end
  local info = GameVersion.VERSIONS[game]
  if not info or (info.generation or 1) ~= 3 then
    error("layouts: not a gen 3 version id: " .. tostring(game), 2)
  end
  local layout = tryLoad(game) or tryLoad(GameVersion.layout(game))
  if not layout then
    error("layouts: no struct layout for " .. tostring(game), 2)
  end
  cache[game] = layout
  return layout
end

function Layouts.active()
  return Layouts.of(require("src.import.gba.versions").active())
end

function Layouts.pockets(layout)
  local Constants = require("src.core.game3.constants")
  local enum = Constants.of(layout.constantsGame).items.pockets or {}
  local out = {}
  for name, id in pairs(enum) do
    local short = name:match("^POCKET_(.+)$")
    if short and short ~= "NONE" and id > 0 then out[id] = short end
  end
  return out
end

return Layouts
