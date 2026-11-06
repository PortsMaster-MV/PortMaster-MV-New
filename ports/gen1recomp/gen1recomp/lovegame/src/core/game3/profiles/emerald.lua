local BLOCKS = {
  "map", "species", "badges", "capabilities", "nativeModules", "coreSpecials", "extractors",
  "font", "battle", "ui", "boot", "audio", "clock", "field", "save", "rse", "dex", "dexArea",
  "bag", "trainers", "heal", "regionMap", "text", "saveRules", "optionsBlock", "weather",
}

local row = {
  id = "emerald",
  label = "Emerald",
  family = "rse",
  generation = 3,
  engine = "game3",
}

local PACKAGE = "src.core.game3.profiles.emerald."

for _, name in ipairs(BLOCKS) do
  local module = PACKAGE .. name
  local ok, block = pcall(require, module)
  if ok then
    row[name] = block
  elseif not tostring(block):find("module '" .. module .. "' not found", 1, true) then
    error(block, 0)
  end
end

return row
