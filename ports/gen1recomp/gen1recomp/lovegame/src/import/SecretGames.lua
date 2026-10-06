local GameVersion = require("src.core.GameVersion")

local SecretGames = {}

SecretGames.GAMES = { emerald = "secretEmerald" }
SecretGames.TAPS = 20
SecretGames.EMERALD_RELEASE_AT = 1790856000
SecretGames.rev = 0

local unlocked

local function load()
  unlocked = {}
  local okSave, SaveData = pcall(require, "src.core.SaveData")
  local ok, opts = false, nil
  if okSave then ok, opts = pcall(SaveData.loadOptions) end
  for id, key in pairs(SecretGames.GAMES) do
    unlocked[id] = ok and type(opts) == "table" and opts[key] == true
  end
end

function SecretGames.reload()
  unlocked = nil
  SecretGames.rev = SecretGames.rev + 1
end

function SecretGames.visible(id)
  if not SecretGames.GAMES[id] then return true end
  SecretGames.update()
  return unlocked[id] == true
end

function SecretGames.shown(imp, id)
  if type(imp) == "table" and not imp.launcher then return true end
  return SecretGames.visible(id)
end

function SecretGames.anyLocked()
  for id in pairs(SecretGames.GAMES) do
    if not SecretGames.visible(id) then return true end
  end
  return false
end

function SecretGames.order(imp)
  local out = {}
  for _, id in ipairs(GameVersion.ORDER) do
    if SecretGames.shown(imp, id) then out[#out + 1] = id end
  end
  return out
end

function SecretGames.unlock()
  local patch = {}
  for _, key in pairs(SecretGames.GAMES) do patch[key] = true end
  local okSave, SaveData = pcall(require, "src.core.SaveData")
  local saved = okSave and SaveData.saveOptions(patch) ~= nil
  unlocked = {}
  for id in pairs(SecretGames.GAMES) do unlocked[id] = true end
  SecretGames.rev = SecretGames.rev + 1
  return saved
end

function SecretGames.update(now)
  if not unlocked then load() end
  local due = (now or os.time()) >= SecretGames.EMERALD_RELEASE_AT
  local changed = due and unlocked.emerald ~= true
  if changed then SecretGames.unlock() end
  return due, changed
end

return SecretGames
