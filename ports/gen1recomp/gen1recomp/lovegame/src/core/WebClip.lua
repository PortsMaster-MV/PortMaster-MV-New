local GameVersion = require("src.core.GameVersion")
local LaunchOptions = require("src.core.LaunchOptions")
local CartStore = require("src.carts.CartStore")

local WebClip = {}

local WEB_CLIP_TITLES = {
  red = "Pokémon Red",
  blue = "Pokémon Blue",
  yellow = "Pokémon Yellow",
  gold = "Pokémon Gold",
  silver = "Pokémon Silver",
  crystal = "Pokémon Crystal",
  firered = "Pokémon FireRed",
  leafgreen = "Pokémon LeafGreen",
  emerald = "Pokémon Emerald",
  ruby = "Pokémon Ruby",
  sapphire = "Pokémon Sapphire",
}

local function cleanLabel(value)
  value = tostring(value or ""):gsub("[\r\n]", " ")
  return value:sub(1, 48)
end

local function fileBytes(path)
  if not (love and love.filesystem and love.filesystem.read) then return nil end
  local ok, bytes = pcall(love.filesystem.read, path)
  return ok and type(bytes) == "string" and bytes ~= "" and bytes or nil
end

function WebClip.spec(version, cartId)
  local info = GameVersion.info(version)
  if not info then return nil end

  local title = WEB_CLIP_TITLES[version] or info.displayName
  local artPath = "assets/labels/" .. tostring(version) .. ".png"
  if cartId then
    local ok, cart = pcall(CartStore.get, cartId)
    if not ok or type(cart) ~= "table" or cart.base ~= version then return nil end
    title = cart.title or cart.id
    local artOk, bytes = pcall(CartStore.labelArt, cartId)
    if not artOk or type(bytes) ~= "string" or bytes == "" then
      bytes = fileBytes(artPath)
    end
    return {
      title = cleanLabel(title),
      url = LaunchOptions.uriFor(version, { cart = cartId }),
      icon = bytes,
      cart = cartId,
    }
  end

  return {
    title = cleanLabel(title),
    url = LaunchOptions.uriFor(version),
    icon = fileBytes(artPath),
  }
end

function WebClip.install(version, cartId)
  if type(love) ~= "table" or type(love.system) ~= "table"
      or type(love.system.installWebClip) ~= "function" then
    return false, "Home Screen entries are only available on iOS"
  end
  local spec = WebClip.spec(version, cartId)
  if not spec or not spec.icon or not spec.url then
    return false, "This game has no artwork to use for its Home Screen entry"
  end
  local ok, installed = pcall(love.system.installWebClip,
    spec.title, spec.url, spec.icon)
  if not ok or installed ~= true then
    return false, "iOS could not open the Home Screen entry installer"
  end
  return true, spec.title
end

return WebClip
