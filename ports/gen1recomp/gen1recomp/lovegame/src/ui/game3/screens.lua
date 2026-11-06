local Stack = require("src.ui.game3.stack")

local Screens = {}

Screens.DEFAULT = {
  start_menu = "src.ui.game3.start_menu",
  bag = "src.ui.game3.bag_menu",
  party = "src.ui.game3.party_menu",
  summary = "src.ui.game3.summary_menu",
  pokedex = "src.ui.game3.pokedex",
  region_map = "src.ui.game3.region_map",
  option = "src.ui.game3.option_menu",
  save = "src.ui.game3.save_menu",
  trainer_card = "src.ui.game3.trainer_card",
  pc = "src.ui.game3.pc_menu",
  shop = "src.ui.game3.shop_menu",
  naming = "src.ui.game3.naming",
  controls = "src.ui.game3.controls_menu",
}

local function uiBlock(session)
  local ok, Profile = pcall(require, "src.core.game3.profile")
  if not ok then return nil end
  local okP, row = pcall(Profile.forSession, session)
  if not okP or type(row) ~= "table" then return nil end
  return type(row.ui) == "table" and row.ui or nil
end

function Screens.path(id, session)
  local ui = uiBlock(session)
  local p = ui and ui.screens and ui.screens[id]
  return p or Screens.DEFAULT[id]
end

function Screens.get(id, session)
  local p = Screens.path(id, session)
  if not p then return nil end
  return require(p)
end

function Screens.redirect(id, self, session)
  local p = Screens.path(id, session)
  if not p or p == Screens.DEFAULT[id] then return nil end
  local mod = require(p)
  if mod == self then return nil end
  return mod
end

function Screens.skin(id, session)
  local ui = uiBlock(session)
  local p = ui and ui.skins and ui.skins[id]
  if not p then return nil end
  return require(p)
end

function Screens.draw(id, mod, session)
  local skin = id and Screens.skin(id, session)
  if skin and skin.draw then return skin.draw(mod) end
  if mod and mod.draw then return mod.draw() end
end

function Screens.handleInput(id, mod, input, session)
  local skin = id and Screens.skin(id, session)
  if skin and skin.handleInput then return skin.handleInput(input, mod) end
  if mod and mod.handleInput then return mod.handleInput(input) end
end

function Screens.withTextAliases(session, fn, ...)
  local ui = uiBlock(session)
  local aliases = ui and ui.textAliases
  if not aliases then return fn(...) end
  local RomText = require("src.core.game3.rom_text")
  local set = {}
  for from, to in pairs(aliases) do
    if RomText.overrides[from] == nil and not RomText.has(from) and RomText.has(to) then
      RomText.overrides[from] = RomText.ir(to)
      set[#set + 1] = from
    end
  end
  local results = { pcall(fn, ...) }
  for _, k in ipairs(set) do RomText.overrides[k] = nil end
  if not results[1] then error(results[2], 0) end
  return unpack(results, 2)
end

function Screens.flags(session)
  local Flags = require("src.core.game3.scripting.flags")
  local ok, t = pcall(Flags.active, session)
  if ok and type(t) == "table" then return t end
  return { IDS = Flags.IDS, VAR_IDS = Flags.VAR_IDS }
end

function Screens.openFlag(id)
  return function() return Stack.has(id) end
end

function Screens.all(session)
  local seen, out = {}, {}
  local function add(p)
    if p and not seen[p] then
      seen[p] = true
      out[#out + 1] = p
    end
  end
  for _, p in pairs(Screens.DEFAULT) do add(p) end
  local ui = uiBlock(session)
  for _, p in pairs(ui and ui.screens or {}) do add(p) end
  for _, p in pairs(ui and ui.skins or {}) do add(p) end
  table.sort(out)
  return out
end

return Screens
