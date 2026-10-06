local GameVersion = require("src.core.GameVersion")

local Family = {}

Family.DEFAULT_GAME = "firered"

local bases = {}
local perGame = {}

local function base(layout)
  local b = bases[layout]
  if b then return b end
  local ok, mod = pcall(require, "src.import.gba.families." .. tostring(layout))
  if not ok or type(mod) ~= "table" then
    error("layout family: no descriptor for '" .. tostring(layout) .. "'", 3)
  end
  bases[layout] = mod
  return mod
end

function Family.gameOf(id)
  if id ~= nil and GameVersion.layout(id) then return id end
  return Family.DEFAULT_GAME
end

function Family.of(id)
  local game = Family.gameOf(id)
  local F = perGame[game]
  if F then return F end
  local b = base(GameVersion.layout(game))
  local over = b.games and b.games[game] or nil
  F = setmetatable({ game = game }, {
    __index = function(_, k)
      if over and over[k] ~= nil then return over[k] end
      return b[k]
    end,
  })
  perGame[game] = F
  return F
end

local lastId, lastF = {}, nil

function Family.active()
  local id = GameVersion.get()
  if id == lastId and lastF then return lastF end
  lastF = Family.of(id)
  lastId = id
  return lastF
end

function Family.activeGame()
  return Family.active().game
end

function Family.reset()
  perGame = {}
  lastId, lastF = {}, nil
end

return Family
